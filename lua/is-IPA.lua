local export = {}

local pron_utilities_module = "Module:pron utilities"

local lang = require("Module:languages").getByCode("is")

local ugsub = mw.ustring.gsub
local uchar = mw.ustring.char

-- Single-character vowels in Icelandic orthography
local vowel_set = {
	["a"]=true, ["á"]=true, ["e"]=true, ["é"]=true,
	["i"]=true, ["í"]=true, ["o"]=true, ["ó"]=true,
	["u"]=true, ["ú"]=true, ["y"]=true, ["ý"]=true,
	["æ"]=true, ["ö"]=true,
}

-- Orthographic consonant letters
local consonant_set = {
	["b"]=true, ["d"]=true, ["ð"]=true, ["f"]=true, ["g"]=true,
	["h"]=true, ["j"]=true, ["k"]=true, ["l"]=true, ["m"]=true,
	["n"]=true, ["p"]=true, ["r"]=true, ["s"]=true, ["t"]=true,
	["v"]=true, ["x"]=true, ["þ"]=true,
}

-- Transparent cluster exception: ptks + vjr → vowel remains long despite 2-consonant cluster
-- (e.g. pr in tepra, kr in dekra, sv in svífa)
local ptks = {["p"]=true, ["t"]=true, ["k"]=true, ["s"]=true}
local vjr  = {["v"]=true, ["j"]=true, ["r"]=true}

local function get_chars(s)
	local chars = {}
	for cp in mw.ustring.gcodepoint(s) do
		table.insert(chars, uchar(cp))
	end
	return chars
end

-- Step 1: lowercase and prepend word-boundary marker #
local function step1(word)
	return "#" .. mw.ustring.lower(word)
end

-- Step 2: mark vowel length on the first (stressed) vowel nucleus.
-- Icelandic phonemic vowel length is only contrastive in stressed syllables,
-- which is always the first syllable in non-compound words.
--
-- Long if: 0 or 1 consonant follows (before next vowel or word end).
-- Short if: 2+ consonants follow (cluster or geminate), unless the cluster is
--   one of the transparent clusters ptks + vjr (e.g. pr, kr, sv, tj, kv).
-- x counts as 2 consonants (represents /ks/).
-- Always short before the sequence -gi (diphthongization environment).
local function step2(word)
	local chars = get_chars(word)
	local n = #chars
	local result = {}
	local found_vowel = false
	local i = 1

	while i <= n do
		local c = chars[i]

		if found_vowel then
			-- Subsequent (unstressed) vowels: pass through unchanged, no length marking
			table.insert(result, c)
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
				if before_gi then
					long = false
				elseif count <= 1 then
					long = true
				elseif count == 2 and ptks[c1] and c2 and vjr[c2] then
					long = true  -- transparent cluster: stays long
				else
					long = false
				end

				table.insert(result, nucleus)
				if long then
					table.insert(result, "ː")
				end
				i = i + nlen
			else
				table.insert(result, c)
				i = i + 1
			end
		end
	end

	return table.concat(result)
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
local Tp, Tph, Tt, Tth = pua(1), pua(2), pua(3), pua(4)   -- p pʰ t tʰ
local Tc, Tch, Tk, Tkh = pua(5), pua(6), pua(7), pua(8)   -- c cʰ k kʰ
local Tv, Tf           = pua(9), pua(10)                  -- v f
local Tdh, Tth2         = pua(11), pua(12)                 -- ð θ
local Ts, Tj, Tcc       = pua(13), pua(14), pua(15)        -- s j(approx) ç
local Tgh, Tx, Th       = pua(16), pua(17), pua(18)        -- ɣ x h
local Tm, Tmv           = pua(19), pua(20)                 -- m m̥
local Tn, Tnv           = pua(21), pua(22)                 -- n n̥
local Tnj, Tnjv         = pua(23), pua(24)                 -- ɲ ɲ̊
local Tng, Tngv         = pua(25), pua(26)                 -- ŋ ŋ̊
local Tl, Tlv           = pua(27), pua(28)                 -- l l̥
local Tr, Trv           = pua(29), pua(30)                 -- r r̥

-- Vowel tokens
local Va, Vai, Vau      = pua(31), pua(32), pua(33)        -- a ai au
local Ve, Vje           = pua(34), pua(35)                 -- ɛ jɛ
local Vi, Vii           = pua(36), pua(37)                 -- ɪ i
local Vo, Vou           = pua(38), pua(39)                 -- ɔ ou
local Vu, Vuu           = pua(40), pua(41)                 -- ʏ u
local Voe, Voei         = pua(42), pua(43)                 -- œ œi
local Vei, Voi, Vui     = pua(44), pua(45), pua(46)        -- ei ɔi ʏi
local Vai_gi            = pua(47)                          -- ai (from a before -gi; NOT in J-set)

-- Palatalization markers (temporary): k/g immediately before a J-set segment
local kPAL, gPAL        = pua(60), pua(61)

-- Detokenization map → final IPA
local detok = {
	[Tp]="p", [Tph]="pʰ", [Tt]="t", [Tth]="tʰ",
	[Tc]="c", [Tch]="cʰ", [Tk]="k", [Tkh]="kʰ",
	[Tv]="v", [Tf]="f", [Tdh]="ð", [Tth2]="θ",
	[Ts]="s", [Tj]="j", [Tcc]="ç", [Tgh]="ɣ", [Tx]="x", [Th]="h",
	[Tm]="m", [Tmv]="m̥", [Tn]="n", [Tnv]="n̥",
	[Tnj]="ɲ", [Tnjv]="ɲ̊", [Tng]="ŋ", [Tngv]="ŋ̊",
	[Tl]="l", [Tlv]="l̥", [Tr]="r", [Trv]="r̥",
	[Va]="a", [Vai]="ai", [Vau]="au", [Ve]="ɛ", [Vje]="jɛ",
	[Vi]="ɪ", [Vii]="i", [Vo]="ɔ", [Vou]="ou", [Vu]="ʏ", [Vuu]="u",
	[Voe]="œ", [Voei]="œi", [Vei]="ei", [Voi]="ɔi", [Vui]="ʏi",
	[Vai_gi]="ai",
	[kPAL]="c", [gPAL]="j",  -- fallback only; normally resolved before detok
}

-- Character-class fragments (contents of a [...] set)
local Vall = table.concat({Va, Vai, Vau, Ve, Vje, Vi, Vii, Vo, Vou, Vu, Vuu,
	Voe, Voei, Vei, Voi, Vui, Vai_gi})
local Vfront = table.concat({Vi, Vii, Ve, Vje, Vai, Vei})  -- J vowels (front unrounded + æ + ei/ey)
local J = Vfront .. "j"                                     -- J-set incl. orthographic j
local Vauou = table.concat({Vau, Vou, Vuu})                -- á ó ú (for silent g)
local Vstar = table.concat({Vau, Vou, Vuu, Vii, Vai, Voei, Vei})  -- á í/ý ó ú æ au ei/ey (nn → tn)
local PLOS = table.concat({Tp, Tph, Tt, Tth, Tc, Tch, Tk, Tkh})

-- Apply an ordered list of {pattern, replacement} substitutions.
local function apply(w, rules)
	for _, rule in ipairs(rules) do
		w = ugsub(w, rule[1], rule[2])
	end
	return w
end

local function convert(w, dialect)
	------------------------------------------------------------------
	-- Phase A: vowels → tokens
	------------------------------------------------------------------
	w = apply(w, {
		-- A1: digraphs (longest first)
		{"au", Voei}, {"ei", Vei}, {"ey", Vei},
		-- A2: monophthong diphthongized + shortened before -gi
		{"a(gi)", Vai_gi.."%1"}, {"o(gi)", Voi.."%1"}, {"u(gi)", Vui.."%1"},
		{"ö(gi)", Voei.."%1"}, {"e(gi)", Vei.."%1"},
		{"i(gi)", Vii.."%1"}, {"y(gi)", Vii.."%1"},
		-- A3: monophthong diphthongized before ng / nk
		{"a(n[gk])", Vau.."%1"}, {"o(n[gk])", Vou.."%1"}, {"u(n[gk])", Vuu.."%1"},
		{"ö(n[gk])", Voei.."%1"}, {"e(n[gk])", Vei.."%1"},
		{"i(n[gk])", Vii.."%1"}, {"y(n[gk])", Vii.."%1"},
		-- A4: plain vowels (the length marker ː stays in place after the token)
		{"á", Vau}, {"ó", Vou}, {"ú", Vuu}, {"æ", Vai}, {"é", Vje},
		{"a", Va}, {"e", Ve}, {"í", Vii}, {"i", Vi},
		{"o", Vo}, {"u", Vu}, {"ý", Vii}, {"y", Vi}, {"ö", Voe},
	})

	------------------------------------------------------------------
	-- Phase B0: word-initial consonants (anchored on #)
	------------------------------------------------------------------
	if dialect == "south" then
		w = ugsub(w, "#hv", "#"..Tx)             -- hv-pronunciation: [x]
	else
		w = ugsub(w, "#hv", "#"..Tkh..Tv)        -- standard: [kʰv]
	end
	w = apply(w, {
		{"#h"..Vje, "#"..Tcc..Ve},               -- hé → ç ɛ
		{"#hj", "#"..Tcc},                        -- hj → ç (j absorbed)
		{"#hn", "#"..Tnv}, {"#hl", "#"..Tlv}, {"#hr", "#"..Trv},
		{"#h", "#"..Th},
		{"#f", "#"..Tf},                          -- initial f is always [f] (non-initial defaults to [v])
		{"#gj", "#"..Tc}, {"#kj", "#"..Tch},      -- gj → c, kj → cʰ (j absorbed)
		{"#g(["..J.."])", "#"..Tc.."%1"},         -- g + J → c
		{"#k(["..J.."])", "#"..Tch.."%1"},        -- k + J → cʰ
		{"#g", "#"..Tk}, {"#k", "#"..Tkh},        -- g → k, k → kʰ
		{"#p", "#"..Tph}, {"#t", "#"..Tth},       -- p → pʰ, t → tʰ
	})

	------------------------------------------------------------------
	-- Phase B1: consonant clusters (longest / most specific first)
	------------------------------------------------------------------
	w = apply(w, {
		-- 4+ / 3-consonant clusters
		{"rfst", Trv..Ts..Tt},
		{"skt", Ts..Tt},                          -- skt → st (k drops): frískt, finnskt
		{"rkt", Trv..Tt}, {"rpt", Trv..Tt}, {"lkt", Tl..Tt},
		{"ngl", Tng..Tl}, {"ngd", Tng..Tt}, {"ngs", Tng..Ts},
		{"ngn", Tng..Tn}, {"ngt", Tngv..Tt},
		{"nkt", Tnv..Tt},
		{"mbd", Tm..Tt}, {"mbt", Tmv..Tt}, {"mbs", Tm..Ts},
		{"fnd", Tm..Tt}, {"fnt", Tmv..Tt},
		{"fld", Tl..Tt}, {"flt", Tl..Tt},
		{"lfd", Tl..Tt}, {"lft", Tl..Tt},
		{"lgd", Tl..Tt}, {"lgt", Tl..Tt}, {"lgn", Tl..Tn},
		{"rfð", Tr..Tdh}, {"rgð", Tr..Tdh},
		{"rfl", Tr..Tt..Tl}, {"rfn", Tr..Tt..Tn},
		{"rft", Trv..Tt}, {"rgt", Trv..Tt}, {"rgn", Tr..Tt..Tn},
		{"rðl", Tr..Tt..Tl}, {"rðn", Tr..Tt..Tn},
		{"ðk", Tth2..Tk},                         -- ð devoiced before k → θ
		-- nasal + velar/palatal stop (place + voicing by following segment)
		{"nk(["..J.."])", Tnjv..Tc.."%1"},        -- voiceless palatal: banki
		{"nk", Tngv..Tk},                         -- voiceless velar: banka
		{"ng(["..J.."])", Tnj..Tc.."%1"},         -- voiced palatal: angi
		{"ng", Tng..Tk},                          -- voiced velar: hanga, langur
		-- geminates and preaspiration
		{"kkt", Tx.."t"},                         -- slökkti → x t
		{"kkj", Th..Tc}, {"kk(["..J.."])", Th..Tc.."%1"},  -- blekkja, þekkja
		{"kk", Th..Tk},                           -- drekka
		{"ggt", Tx.."t"},                         -- snöggt → x t
		{"ggj", Tc}, {"gg(["..J.."])", Tc.."%1"}, -- byggja
		{"gg", Tk},                               -- hagga
		{"ppt", Tf..Tt}, {"pp", Th..Tp},          -- keppti, stoppa
		{"tt", Th..Tt},                           -- fletta
		{"bb", Tp}, {"dd", Tt}, {"ff", Tf},
		{"ss", Ts}, {"mm", Tm}, {"rr", Tr},
		-- nn → tn after a long vowel / diphthong, else n
		{"(["..Vstar.."])(ː?)nn", "%1%2"..Tt..Tn},
		{"nn", Tn},
		-- ll → tl, except before t/s
		{"llt", Tl..Tt}, {"lls", Tl..Ts}, {"ll", Tt..Tl},
		-- preaspiration: p/t/k + l/n
		{"pl", Th..Tp..Tl}, {"pn", Th..Tp..Tn},
		{"tl", Th..Tt..Tl}, {"tn", Th..Tt..Tn},
		{"kl", Th..Tk..Tl}, {"kn", Th..Tk..Tn},
		{"kt", Tx.."t"}, {"pt", Tf..Tt},          -- rakti → x t, æpti → f t
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
		{"r"..kPAL, Trv..kPAL}, {"r([ptks])", Trv.."%1"},
		{"l"..kPAL, Tlv..kPAL}, {"l([ptk])", Tlv.."%1"},
		{"m"..kPAL, Tmv..kPAL}, {"m([ptk])", Tmv.."%1"},
		{"nt", Tnv..Tt},                          -- vanta
	})

	-- Phase B3a2: epenthetic [t] in rl, rn, sl, sn
	w = apply(w, {
		{"rl", Tr..Tt..Tl}, {"rn", Tr..Tt..Tn},
		{"sl", Ts..Tt..Tl}, {"sn", Ts..Tt..Tn},
	})

	------------------------------------------------------------------
	-- Phase B3b: g and k realizations
	------------------------------------------------------------------
	w = apply(w, {
		-- g
		{"(["..Vauou.."])(ː?)g(["..Vall.."])", "%1%2%3"},      -- silent after á/ó/ú
		{"gt", Tx.."t"},                                        -- sagt: g → x (t kept)
		{"g([ðr])", Tgh.."%1"},                                 -- sigra, sagði → ɣ
		{"(["..Vall.."])(ː?)g(["..Vall.."])", "%1%2"..Tgh.."%3"},-- saga → ɣ (intervocalic)
		{gPAL.."j", Tj},                                        -- gj → j (lægja)
		{"(["..Vall.."])(ː?)"..gPAL.."(["..Vall.."])", "%1%2"..Tj.."%3"}, -- hagi → j
		{gPAL, Tc},                                             -- elsewhere palatal g → c
		{"g", Tk},                                              -- elsewhere velar g → k
		-- k
		{kPAL.."j", Tc},                                        -- kj → c (rekja)
		{kPAL, Tc},                                             -- ríki → c
		{"k", Tk},                                              -- baka → k
	})

	------------------------------------------------------------------
	-- Phase B3c: f realizations
	------------------------------------------------------------------
	w = apply(w, {
		{"f([ln])", Tp.."%1"},                    -- efla, hafna → p
		{"f([st])", Tf.."%1"},                    -- ofsi, aftur → f
		{"f", Tv},                                -- sofa → v
	})

	------------------------------------------------------------------
	-- Phase B3d: remaining single consonants
	------------------------------------------------------------------
	w = apply(w, {
		{"x", Tk..Ts},                            -- x → ks
		{"b", Tp}, {"d", Tt},
		{"p", Tp}, {"t", Tt},
		{"m", Tm}, {"n", Tn}, {"l", Tl}, {"r", Tr},
		{"ð", Tdh}, {"þ", Tth2},
		{"v", Tv}, {"s", Ts}, {"j", Tj}, {"h", Th},
	})

	-- Word-final [tn]/[tl] devoice the sonorant: vatn [vahtn̥], einn [eitn̥]
	w = apply(w, {
		{Tt..Tn.."$", Tt..Tnv},
		{Tt..Tl.."$", Tt..Tlv},
	})

	------------------------------------------------------------------
	-- Dialect adjustments (best-effort; standard is the default)
	------------------------------------------------------------------
	local stop_pairs = {{Tp, Tph}, {Tt, Tth}, {Tc, Tch}, {Tk, Tkh}}
	if dialect == "north" or dialect == "northeast" then
		-- harðmæli: aspirate non-initial unaspirated stops between a vowel and a
		-- following sonorant (vowel / j / r / v). The optional ː is the length mark.
		local after = Vall .. Tj .. Tr .. Tv
		for _, pr in ipairs(stop_pairs) do
			w = ugsub(w, "(["..Vall.."])(ː?)"..pr[1].."(["..after.."])", "%1%2"..pr[2].."%3")
		end
	end
	if dialect == "northeast" then
		-- voiced pronunciation: a nasal voices before a stop, and the stop aspirates
		for _, nv in ipairs({{Tmv, Tm}, {Tnv, Tn}, {Tnjv, Tnj}, {Tngv, Tng}}) do
			for _, sp in ipairs(stop_pairs) do
				w = ugsub(w, nv[1]..sp[1], nv[2]..sp[2])
			end
		end
		-- l voices (and stop aspirates) before labial/velar stops, but stays
		-- voiceless before t (per doc: piltur, elta keep [l̥t])
		for _, sp in ipairs({{Tp, Tph}, {Tk, Tkh}, {Tc, Tch}}) do
			w = ugsub(w, Tlv..sp[1], Tl..sp[2])
		end
		-- ð voiced (and following k aspirated) in -ðk-: maðkur [maðkʰʏr]
		w = ugsub(w, Tth2..Tk, Tdh..Tkh)
	end

	------------------------------------------------------------------
	-- Steps 4–5: detokenize and clean up
	------------------------------------------------------------------
	for token, ipa in pairs(detok) do
		w = ugsub(w, token, ipa)
	end
	w = ugsub(w, "#", "")
	return w
end

function export.toIPA(text, dialect)
	local word = step1(text)       -- Step 1: lowercase + word-boundary marker
	word = step2(word)             -- Step 2: mark first-syllable vowel length
	word = convert(word, dialect)  -- Steps 3–5: phonological rules → IPA
	return "ˈ" .. word
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
