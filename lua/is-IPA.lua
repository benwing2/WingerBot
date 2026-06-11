local export = {}

local lang = require("Module:languages").getByCode("is")

local pron_utilities_module = "Module:pron utilities"
local m_string_utilities = require("Module:string utilities")

local ugsub = m_string_utilities.gsub
local usub = m_string_utilities.sub
local uchar = m_string_utilities.char
local split = m_string_utilities.split
local concat = table.concat
local insert = table.insert

local function explode_to_list(s)
	local chars = {}
	for cp in mw.ustring.gcodepoint(s) do
		insert(chars, uchar(cp))
	end
	return chars
end

local function explode_to_set(s)
	local charset = {}
	for cp in mw.ustring.gcodepoint(s) do
		charset[uchar(cp)] = true
	end
	return charset
end

-- Single-character vowels in Icelandic orthography
local Vall_orth = "aáæeéiíoóöuúyý"
local vowel_set = explode_to_set(Vall_orth)

-- Orthographic consonant letters
local Call_orth = "bdðfghjklmnprstvxþ"
local consonant_set = explode_to_set(Call_orth)

-- Transparent cluster exception: ptks + vjr → vowel remains long despite 2-consonant cluster
-- (e.g. pr in tepra, kr in dekra, sv in svífa)
local ptks = {["p"]=true, ["t"]=true, ["k"]=true, ["s"]=true}
local vjr  = {["v"]=true, ["j"]=true, ["r"]=true}

-- Mark vowel length on the first (stressed) vowel nucleus.
-- Icelandic phonemic vowel length is only contrastive in stressed syllables,
-- which is always the first syllable in non-compound words.
--
-- Long if: 0 or 1 consonant follows (before next vowel or word end).
-- Short if: 2+ consonants follow (cluster or geminate), unless the cluster is
--   one of the transparent clusters ptks + vjr (e.g. pr, kr, sv, tj, kv).
-- x counts as 2 consonants (represents /ks/).
-- Always short before the sequence -gi (diphthongization environment).
--
-- In a compound, the same rules apply to the last component, but otherwise a
-- stressed syllable in a single-syllable component is lengthened only when either
-- the component ends in a vowel, the next component begins with a vowel or h + vowel,
-- or the component ends in a single written <p>, <t>, <k> or <s>.
local function determine_vowel_length(component_index, component, next_component)
	local chars = explode_to_list(component)
	local n = #chars
	local result = {}
	local found_vowel = false
	local i = 1

	while i <= n do
		local c = chars[i]

		if found_vowel then
			-- Subsequent (unstressed) vowels: pass through unchanged, no length marking
			insert(result, c)
			i = i + 1
		else
			-- Check for vowel digraphs first: au, ei, ey
			local nucleus, nlen
			if i < n then
				local two = c .. chars[i + 1]
				if two == "au" or two == "ei" or two == "ey" then
					nucleus, nlen = two, 2
				end
			end
			if not nucleus and vowel_set[c] then
				nucleus, nlen = c, 1
			end

			if nucleus then
				found_vowel = true
				local j = i + nlen  -- index of first character after the nucleus
				-- Count orthographic consonant letters following the nucleus
				local count = 0
				local c1, c2 = nil, nil
				local k = j
				while k <= n and consonant_set[chars[k]] do
					local cc = chars[k]
					if count == 0 then c1 = cc end
					if count == 1 then c2 = cc end
					count = count + (cc == "x" and 2 or 1)  -- x = /ks/ = 2 consonants
					k = k + 1
				end

				-- -gi special case: vowel is always short (and diphthongized) before [g + i]
				local before_gi = c1 == "g" and j + 1 <= n and chars[j + 1] == "i"

				local long
				-- At this point, j is the index of the first character after the stressed vowel
				-- nucleus, and k is the index of the first character after any consonant cluster
				-- following the vowel nucleus. Either may be > n (the number of characters in the
				-- component).
				if next_component and k > n then
					-- Non-final component, single-syllable word.
					if count == 0 then
						long = true -- component ends in a vowel
					elseif count == 1 and ptks[c1] then
						long = true -- ends in a single orthographic <p>, <t>, <k> or <s>
					else
						local first_next = usub(next_component, 1, 1)
						local second_next = usub(next_component, 2, 2)
						if vowel_set[first_next] or first_next == "h" and vowel_set[second_next] then
							long = true -- next component begins with a vowel or h + vowel
						else
							long = false
						end
					end
				else
					if before_gi then
						long = false
					elseif count <= 1 then
						long = true
					elseif count == 2 and ptks[c1] and c2 and vjr[c2] then
						long = true  -- transparent cluster: stays long
					else
						long = false
					end
				end

				insert(result, nucleus)
				if long then
					insert(result, "ː")
				end
				i = i + nlen
			else
				insert(result, c)
				i = i + 1
			end
		end
	end

	return concat(result)
end

--------------------------------------------------------------------------------
-- Step 3 machinery: phonological rules as ordered pattern substitutions.
--
-- Strategy: First convert every orthographic vowel to a unique private-use-area
-- (PUA) token. This lets the consonant rules reference vowel context (front vs.
-- back, the J-set for palatalization) without character collisions, and means
-- that once a consonant becomes a token it can never be re-matched by a later
-- rule that targets an orthographic letter. At the very end every token is
-- detokenized to its final IPA string (Steps 4–5).
--------------------------------------------------------------------------------

local function pua(n) return uchar(0xE000 + n) end

-- Consonant tokens
local Cp, Cph, Ct, Cth  = pua(0), pua(1), pua(2), pua(3)   -- p pʰ t tʰ
local Cc, Cch, Ck, Ckh  = pua(4), pua(5), pua(6), pua(7)   -- c cʰ k kʰ
local Cv, Cf            = pua(8), pua(9)                   -- v f
local Cdh, Cth2         = pua(10), pua(11)                 -- ð θ
local Cs, Cj, Ccc       = pua(12), pua(13), pua(14)        -- s j(approx) ç
local Cgh, Cx, Ch       = pua(15), pua(16), pua(17)        -- ɣ x h
local Cm, Chm           = pua(18), pua(19)                 -- m m̥
local Cn, Chn           = pua(20), pua(21)                 -- n n̥
local Cnj, Chnj         = pua(22), pua(23)                 -- ɲ ɲ̊
local Cng, Chng         = pua(24), pua(25)                 -- ŋ ŋ̊
local Cl, Chl           = pua(26), pua(27)                 -- l l̥
local Cr, Chr           = pua(28), pua(29)                 -- r r̥

-- Palatalization markers (temporary): k/g immediately before a J-set segment
local kPAL, gPAL        = pua(30), pua(31)

-- Suprasegmental tokens
local Solc              = pua(32)                          -- optional long after a consonant

local Cfirst, Clast     = pua(0), pua(59)

-- Vowel tokens
local Va, Vai, Vau      = pua(60), pua(61), pua(62)        -- a ai au
local Ve, Vje           = pua(63), pua(64)                 -- ɛ jɛ
local Vi, Vii           = pua(65), pua(66)                 -- ɪ i
local Vo, Vou           = pua(67), pua(68)                 -- ɔ ou
local Vu, Vuu           = pua(69), pua(70)                 -- ʏ u
local Voe, Voei         = pua(71), pua(72)                 -- œ œi
local Vei, Voi, Vui     = pua(73), pua(74), pua(75)        -- ei ɔi ʏi
local Vai_gi            = pua(76)                          -- ai (from a before -gi; NOT in J-set)

local Vfirst, Vlast     = pua(60), pua(99)

local aspirate_stop_map = {[Cp]=Cph, [Ct]=Cth, [Cc]=Cch, [Ck]=Ckh}
local deaspirate_stop_map = {[Ch]=Cp, [Cth]=Ct, [Cch]=Cc, [Ckh]=Ck}
local unaspirated_stops_pua = Cp..Ct..Cc..Ck
local aspirated_stops_pua = Cph..Cth..Cch..Ckh
local devoice_resonant_map = {[Cm]=Chm, [Cn]=Chn, [Cnj]=Chnj, [Cng]=Chng, [Cl]=Chl, [Cr]=Chr}
local voice_resonant_map = {[Chm]=Cm, [Chn]=Cn, [Chnj]=Cnj, [Chng]=Cng, [Chl]=Cl, [Chr]=Cr}
local orth_stop_to_pua_map = {b=Cp, d=Ct, g=Ck, p=Cph, t=Cth, k=Ckh}

-- Diphthongization of lax vowels occurs before -gi- and before velar and palatal nasals.
-- Lax front vowels always diphthongize towards i, whereas lax back and central vowels diphthongize
-- towards i before -gi- and towards u before velar/palatal nasals. Here, written <u> counts as a
-- "back" vowel even though it has been fronted.
local lax_front_vowel_diphthongize_map = {["ö"]=Voei, e=Vei, i=Vii, y=Vii}
local lax_back_vowel_front_diphthongize_map = {a=Vai_gi, o=Voi, u=Vui}
local lax_back_vowel_back_diphthongize_map = {a=Vau, o=Vou, u=Vuu}
local lax_vowels = "aeioöuy"

-- Detokenization map → final IPA
local detok = {
	[Cp]="p", [Cph]="pʰ", [Ct]="t", [Cth]="tʰ",
	[Cc]="c", [Cch]="cʰ", [Ck]="k", [Ckh]="kʰ",
	[Cv]="v", [Cf]="f", [Cdh]="ð", [Cth2]="θ",
	[Cs]="s", [Cj]="j", [Ccc]="ç", [Cgh]="ɣ", [Cx]="x", [Ch]="h",
	[Cm]="m", [Chm]="m̥", [Cn]="n", [Chn]="n̥",
	[Cnj]="ɲ", [Chnj]="ɲ̊", [Cng]="ŋ", [Chng]="ŋ̊",
	[Cl]="l", [Chl]="l̥", [Cr]="r", [Chr]="r̥",
	[Va]="a", [Vai]="ai", [Vau]="au", [Ve]="ɛ", [Vje]="jɛ",
	[Vi]="ɪ", [Vii]="i", [Vo]="ɔ", [Vou]="ou", [Vu]="ʏ", [Vuu]="u",
	[Voe]="œ", [Voei]="œi", [Vei]="ei", [Voi]="ɔi", [Vui]="ʏi",
	[Vai_gi]="ai",
	[Solc]="(ː)",
	[kPAL]="c", [gPAL]="j",  -- fallback only; normally resolved before detok
}

-- Character-class fragments (contents of a [...] set)
local Call_pua = Cfirst .. "-" .. Clast
local Call = Call_pua .. Call_orth
local Vall_pua = Vfirst .. "-" .. Vlast
local Vall = Vall_pua .. Vall_orth
local Vfront = concat({Vi, Vii, Ve, Vje, Vai, Vei})  -- J vowels (front unrounded + æ + ei/ey)
local J = Vfront .. "j"                                     -- J-set incl. orthographic j
local Vauou = concat({Vau, Vou, Vuu})                -- á ó ú (for silent g)
local Vstar = concat({Vau, Vou, Vuu, Vii, Vai, Voei, Vei})  -- á í/ý ó ú æ au ei/ey (nn → tn)
local Cstop = concat({Cp, Cph, Ct, Cth, Cc, Cch, Ck, Ckh})

-- Apply an ordered list of {pattern, replacement} substitutions.
local function apply(w, rules)
	for _, rule in ipairs(rules) do
		w = ugsub(w, rule[1], rule[2])
	end
	return w
end

local function convert(w, dialect, detok)
	------------------------------------------------------------------
	-- Phase A: vowels → tokens
	------------------------------------------------------------------
	w = apply(w, {
		-- A1: digraphs (longest first)
		{"au", Voei}, {"ei", Vei}, {"ey", Vei},
		-- A2: monophthong diphthongized + shortened before -gi
		{"(["..lax_vowels.."])(gi)", function(v, gi)
			return (lax_back_vowel_front_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. gi
		end},
		-- A3: monophthong diphthongized before ng / nk
		{"(["..lax_vowels.."])(n[gk])", function(v, ngk)
			return (lax_back_vowel_back_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. ngk 
		end},
		-- A4: plain vowels (the length marker ː stays in place after the token)
		{"á", Vau}, {"ó", Vou}, {"ú", Vuu}, {"æ", Vai}, {"é", Vje},
		{"a", Va}, {"e", Ve}, {"í", Vii}, {"i", Vi},
		{"o", Vo}, {"u", Vu}, {"ý", Vii}, {"y", Vi}, {"ö", Voe},
	})

	------------------------------------------------------------------
	-- Phase B0: word-initial consonants (anchored on #)
	------------------------------------------------------------------
	if dialect == "south" then
		w = ugsub(w, "#hv", "#"..Cx)             -- hv-pronunciation: [x]
	else
		w = ugsub(w, "#hv", "#"..Ckh..Cv)        -- standard: [kʰv]
	end
	w = apply(w, {
		{"#h"..Vje, "#"..Ccc..Ve},               -- hé → ç ɛ
		{"#hj", "#"..Ccc},                        -- hj → ç (j absorbed)
		{"#hn", "#"..Chn}, {"#hl", "#"..Chl}, {"#hr", "#"..Chr},
		{"#h", "#"..Ch},
		{"#f", "#"..Cf},                          -- initial f is always [f] (non-initial defaults to [v])
		{"#gj", "#"..Cc}, {"#kj", "#"..Cch},      -- gj → c, kj → cʰ (j absorbed)
		{"#g(["..J.."])", "#"..Cc.."%1"},         -- g + J → c
		{"#k(["..J.."])", "#"..Cch.."%1"},        -- k + J → cʰ
		-- map remaining initial stops to PUA equivalents
		{"#([ptkbdg])", function(stop) return "#" .. orth_stop_to_pua_map[stop] end},
	})

	------------------------------------------------------------------
	-- Phase B1: consonant clusters (longest / most specific first)
	------------------------------------------------------------------
	w = apply(w, {
		-- kkj, ggj are special; all other cases of C₁ːC₂ reduce to C₁C₂
		{"kkj", Ch..Cc}, {"kk(["..J.."])", Ch..Cc.."%1"},  -- blekkja, þekkja
		{"ggj", Cc..Solc}, {"gg(["..J.."])", Cc..Solc.."%1"}, -- byggja
		{"([" .. Call .. "])%1([" .. Call .. "])", "%1%2"}, -- snöggt, keppti, vaffla, etc.
		-- 4+ / 3-consonant clusters
		{"rfst", Chr..Cs..Ct},
		{"skt", Cs..Ct},                          -- skt → st (k drops): frískt, finnskt
		{"rkt", Chr..Ct}, {"rpt", Chr..Ct}, {"lkt", Cl..Ct},
		{"ngl", Cng..Cl}, {"ngd", Cng..Ct}, {"ngs", Cng..Cs},
		{"ngn", Cng..Cn}, {"ngt", Chng..Ct},
		{"nkt", Chn..Ct},
		{"mbd", Cm..Ct}, {"mbt", Chm..Ct}, {"mbs", Cm..Cs},
		{"fnd", Cm..Ct}, {"fnt", Chm..Ct},
		{"fld", Cl..Ct}, {"flt", Cl..Ct},
		{"lfd", Cl..Ct}, {"lft", Cl..Ct},
		{"lgd", Cl..Ct}, {"lgt", Cl..Ct}, {"lgn", Cl..Cn},
		{"rfð", Cr..Cdh}, {"rgð", Cr..Cdh},
		{"rfl", Cr..Ct..Cl}, {"rfn", Cr..Ct..Cn},
		{"rft", Chr..Ct}, {"rgt", Chr..Ct}, {"rgn", Cr..Ct..Cn},
		{"rðl", Cr..Ct..Cl}, {"rðn", Cr..Ct..Cn},
		{"ðk", Cth2..Ck},                         -- ð devoiced before k → θ
		-- nasal + velar/palatal stop (place + voicing by following segment)
		{"nk(["..J.."])", Chnj..Cc.."%1"},        -- voiceless palatal: banki
		{"nk", Chng..Ck},                         -- voiceless velar: banka
		{"ng(["..J.."])", Cnj..Cc.."%1"},         -- voiced palatal: angi
		{"ng", Cng..Ck},                          -- voiced velar: hanga, langur
		-- geminates and preaspiration
		{"kk", Ch..Ck},                           -- drekka
		{"pp", Ch..Cp},                           -- stoppa
		{"tt", Ch..Ct},                           -- fletta
		{"gg", Ck..Solc},                         -- hagga
		{"bb", Cp..Solc},
		{"dd", Ct..Solc},
		{"ff", Cf..Solc},
		{"ss", Cs..Solc},
		{"mm", Cm..Solc},
		{"rr", Cr..Solc},
		-- nn → tn after a long vowel / diphthong, else n
		{"(["..Vstar.."])(ː?)nn", "%1%2"..Ct..Cn},
		{"nn", Cn..Solc},
		{"ll", Ct..Cl},
		-- preaspiration: p/t/k + l/n
		{"pl", Ch..Cp..Cl}, {"pn", Ch..Cp..Cn},
		{"tl", Ch..Ct..Cl}, {"tn", Ch..Ct..Cn},
		{"kl", Ch..Ck..Cl}, {"kn", Ch..Ck..Cn},
		{"kt", Cx.."t"}, {"pt", Cf..Ct},          -- rakti → x t, æpti → f t
	})

	------------------------------------------------------------------
	-- Phase B2: mark remaining single k / g for palatalization
	------------------------------------------------------------------
	w = apply(w, {
		{"k(["..J.."])", kPAL.."%1"},
		{"g(["..J.."])", gPAL.."%1"},
	})

	------------------------------------------------------------------
	-- Phase B3a: devoicing of liquids/nasals before a stop
	-- (the following stop letter is kept for its own conversion)
	------------------------------------------------------------------
	w = apply(w, {
		{"r"..kPAL, Chr..kPAL}, {"r([ptks])", Chr.."%1"},
		{"l"..kPAL, Chl..kPAL}, {"l([ptk])", Chl.."%1"},
		{"m"..kPAL, Chm..kPAL}, {"m([ptk])", Chm.."%1"},
		{"nt", Chn..Ct},                          -- vanta
	})

	-- Phase B3a2: epenthetic [t] in rl, rn, sl, sn
	w = apply(w, {
		{"rl", Cr..Ct..Cl}, {"rn", Cr..Ct..Cn},
		{"sl", Cs..Ct..Cl}, {"sn", Cs..Ct..Cn},
	})

	------------------------------------------------------------------
	-- Phase B3b: g and k realizations
	------------------------------------------------------------------
	w = apply(w, {
		-- g
		{"(["..Vauou.."])(ː?)g(["..Vall.."])", "%1%2%3"},      -- silent after á/ó/ú
		{"gt", Cx.."t"},                                        -- sagt: g → x (t kept)
		{"g([ðr])", Cgh.."%1"},                                 -- sigra, sagði → ɣ
		{"(["..Vall.."])(ː?)g(["..Vall.."])", "%1%2"..Cgh.."%3"},-- saga → ɣ (intervocalic)
		{"(["..Vall.."])(ː?)g#", "%1%2"..Cgh.."#"},             -- lag → ɣ (final after a vowel)
		{gPAL.."j", Cj},                                        -- gj → j (lægja)
		{"(["..Vall.."])(ː?)"..gPAL.."(["..Vall.."])", "%1%2"..Cj.."%3"}, -- hagi → j
		{gPAL, Cc},                                             -- elsewhere palatal g → c
		{"g", Ck},                                              -- elsewhere velar g → k
		-- k
		{kPAL.."j", Cc},                                        -- kj → c (rekja)
		{kPAL, Cc},                                             -- ríki → c
		{"k", Ck},                                              -- baka → k
	})

	------------------------------------------------------------------
	-- Phase B3c: f realizations
	------------------------------------------------------------------
	w = apply(w, {
		{"f([ln])", Cp.."%1"},                    -- efla, hafna → p
		{"f([st])", Cf.."%1"},                    -- ofsi, aftur → f
		{"f", Cv},                                -- sofa → v
	})

	------------------------------------------------------------------
	-- Phase B3d: remaining single consonants
	------------------------------------------------------------------
	w = apply(w, {
		{"x", Ck..Cs},                            -- x → ks
		{"b", Cp}, {"d", Ct},
		{"p", Cp}, {"t", Ct},
		{"m", Cm}, {"n", Cn}, {"l", Cl}, {"r", Cr},
		{"ð", Cdh}, {"þ", Cth2},
		{"v", Cv}, {"s", Cs}, {"j", Cj}, {"h", Ch},
	})

	-- Word-final stop + [n]/[l] devoice the sonorant: vopn [vɔhpn̥], magn [makn̥], einn [eitn̥], stjákl [stjauhkl̥]
	w = ugsub(w, "(["..unaspirated_stops_pua.."])(["..Cn..Cl.."])#",
			function(stop, nl) return stop .. devoice_resonant_map[nl] .. "#" end
	)

	------------------------------------------------------------------
	-- Dialect adjustments (best-effort; standard is the default)
	------------------------------------------------------------------
	if dialect == "north" or dialect == "northeast" then
		-- harðmæli: aspirate non-initial unaspirated stops between a vowel and a
		-- following sonorant (vowel / j / r / v). The optional ː is the length mark.
		w = ugsub(w, "(["..Vall.."]ː?)(["..unaspirated_stops_pua.."])(["..Vall..Cj..Cr..Cv.."])",
			function(v1, stop, son2) return v1..aspirate_stop_map[stop]..son2 end
		)
	end
	if dialect == "northeast" then
		-- voiced pronunciation: a nasal voices before a stop, and the stop aspirates
		local voiceless_nasals_pua = Chm..Chn..Chnj..Chng
		w = ugsub(w, "(["..voiceless_nasals_pua.."])(["..unaspirated_stops_pua.."])",
			function(nv, stop) return voice_resonant_map[nv]..aspirate_stop_map[stop] end
		)
		-- l voices (and stop aspirates) before labial/velar stops, but stays
		-- voiceless before t (per doc: piltur, elta keep [l̥t])
		w = ugsub(w, Chl.."(["..Cp..Ck..Cc.."])",
			function(stop) return Cl..aspirate_stop_map[stop] end
		)
		-- ð voiced (and following k aspirated) in -ðk-: maðkur [maðkʰʏr]
		w = ugsub(w, Cth2..Ck, Cdh..Ckh)
	end

	------------------------------------------------------------------
	-- Steps 4–5: detokenize and clean up
	------------------------------------------------------------------
	w = ugsub(w, ".", detok)
	w = ugsub(w, "#", "")
	return w
end

local function toIPA_component(component_index, component, next_component, dialect)
	component = mw.ustring.lower(component)
	component = determine_vowel_length(component_index, component, next_component)
	component = "#" .. component .. "#"
	component = convert(component, dialect, detok)
	return (component_index == 1 and "ˈ" or "ˌ") .. component
end

local function toIPA_word(word, dialect)
	local components = split(word, "[-‿]")
	local processed_components = {}
	for i, component in ipairs(components) do
		local processed = toIPA_component(i, component, components[i + 1], dialect)
		insert(processed_components, processed)
	end
	return concat(processed_components)
end

function export.toIPA(text, dialect)
	local words = split(text, "%s+")
	local processed_words = {}
	for i, word in ipairs(words) do
		local processed = toIPA_word(word, dialect)
		insert(processed_words, processed)
	end
	return concat(processed_words, " ")
end	

function export.toIPA_bot(frame)
	local text, dialect = frame.args[1], frame.args[2]
	return export.toIPA(text, dialect)
end

local function respelling_to_IPA(data)
	return "/" .. export.toIPA(data.respelling) .. "/"
end

function export.make(frame)
	local parent_args = frame:getParent().args
	return require(pron_utilities_module).format_prons {
		lang = lang,
		respelling_to_IPA = respelling_to_IPA,
		raw_args = parent_args,
		track_module = "is-IPA",
	}
end

return export
