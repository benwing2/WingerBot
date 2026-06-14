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
local ptks = {["p"] = true, ["t"] = true, ["k"] = true, ["s"] = true}
local vjr  = {["v"] = true, ["j"] = true, ["r"] = true}

-- Mark vowel length on the first (stressed) vowel nucleus.
-- Icelandic phonemic vowel length is only contrastive in stressed syllables,
-- which is always the first syllable in non-compound words.
--
-- Long if: 0 or 1 consonant follows (before next vowel or component end).
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
					-- Non-final component, single-syllable component.
					if count == 0 then
						long = true -- component ends in a vowel
					elseif count == 1 and ptks[c1] then
						long = true -- ends in a single orthographic <p>, <t>, <k> or <s>
					elseif count == 1 then
						local first_next = usub(next_component, 1, 1)
						local second_next = usub(next_component, 2, 2)
						if vowel_set[first_next] or first_next == "h" and vowel_set[second_next] and second_next ~= "é" then
							long = true -- next component begins with a vowel or h + vowel (but not hé-, which is phonemically /hjɛ-/)
						else
							long = false
						end
					else
						long = false
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

-- Consonant PUA tokens; store in a table to avoid errors with too many upvalues
local C = {
	p = pua(0),  -- p
	ph = pua(1),  -- pʰ
	t = pua(2),  -- t
	th = pua(3),  -- tʰ
	c = pua(4),  -- c
	ch = pua(5),  -- cʰ
	k = pua(6),  -- k
	kh = pua(7),  -- kʰ
	v = pua(8), -- v
	f = pua(9), -- f
	dh = pua(10), -- ð
	th2 = pua(11), -- θ
	s = pua(12), -- s
	j = pua(13), -- j(approx)
	hj = pua(14), -- ç
	gh = pua(15), -- ɣ
	x = pua(16), -- x
	h = pua(17), -- h
	m = pua(18), -- m 
	hm = pua(19), -- m̥
	n = pua(20), -- n
	hn = pua(21), -- n̥
	nj = pua(22), -- ɲ
	hnj = pua(23), -- ɲ̊
	ng = pua(24), -- ŋ
	hng = pua(25), -- ŋ̊
	l = pua(26), -- l
	hl = pua(27), -- l̥
	r = pua(28), -- r
	hr = pua(29), -- r̥
}

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

local aspirate_stop_map = {[C.p] = C.ph, [C.t] = C.th, [C.c] = C.ch, [C.k] = C.kh}
local deaspirate_stop_map = {[C.h] = C.p, [C.th] = C.t, [C.ch] = C.c, [C.kh] = C.k}
local unaspirated_stops_pua = C.p .. C.t .. C.c .. C.k
local aspirated_stops_pua = C.ph .. C.th .. C.ch .. C.kh
local devoice_resonant_map = {[C.m] = C.hm, [C.n] = C.hn, [C.nj] = C.hnj, [C.ng] = C.hng, [C.l] = C.hl, [C.r] = C.hr}
local voice_resonant_map = {[C.hm] = C.m, [C.hn] = C.n, [C.hnj] = C.nj, [C.hng] = C.ng, [C.hl] = C.l, [C.hr] = C.r}
local orth_to_asp_pua_map = {b = C.p, d = C.t, g = C.k, gPAL = C.c, p = C.ph, t = C.th, k = C.kh, kPAL = C.ch,
							 l = C.hl, m = C.hm, n = C.hn, r = C.hr, j = C.hj}
local orth_to_unasp_pua_map = {b = C.p, d = C.t, g = C.k, gPAL = C.c, p = C.p, t = C.t, k = C.k, kPAL = C.c,
							   l = C.l, m = C.m, n = C.n, r = C.r, j = C.j,
							   f = C.f, h = C.h, s = C.s, ["þ"] = C.th2, v = C.v, ["ð"] = C.dh}

-- Diphthongization of lax vowels occurs before -gi- and before velar and palatal nasals.
-- Lax front vowels always diphthongize towards i, whereas lax back and central vowels diphthongize
-- towards i before -gi- and towards u before velar/palatal nasals. Here, written <u> counts as a
-- "back" vowel even though it has been fronted.
local lax_front_vowel_diphthongize_map = {["ö"] = Voei, e = Vei, i = Vii, y = Vii}
local lax_back_vowel_front_diphthongize_map = {a = Vai_gi, o = Voi, u = Vui}
local lax_back_vowel_back_diphthongize_map = {a = Vau, o = Vou, u = Vuu}
local lax_vowels = "aeioöuy"

-- Detokenization map → final IPA
local detok = {
	[C.p] = "p", [C.ph] = "pʰ", [C.t] = "t", [C.th] = "tʰ",
	[C.c] = "c", [C.ch] = "cʰ", [C.k] = "k", [C.kh] = "kʰ",
	[C.v] = "v", [C.f] = "f", [C.dh] = "ð", [C.th2] = "θ",
	[C.s] = "s", [C.j] = "j", [C.hj] = "ç", [C.gh] = "ɣ", [C.x] = "x", [C.h] = "h",
	[C.m] = "m", [C.hm] = "m̥", [C.n] = "n", [C.hn] = "n̥",
	[C.nj] = "ɲ", [C.hnj] = "ɲ̊", [C.ng] = "ŋ", [C.hng] = "ŋ̊",
	[C.l] = "l", [C.hl] = "l̥", [C.r] = "r", [C.hr] = "r̥",
	[Va] = "a", [Vai] = "ai", [Vau] = "au", [Ve] = "ɛ", [Vje] = "jɛ",
	[Vi] = "ɪ", [Vii] = "i", [Vo] = "ɔ", [Vou] = "ou", [Vu] = "ʏ", [Vuu] = "u",
	[Voe] = "œ", [Voei] = "œi", [Vei] = "ei", [Voi] = "ɔi", [Vui] = "ʏi",
	[Vai_gi] = "ai",
	[Solc] = "(ː)",
	[kPAL] = "c", [gPAL] = "j",  -- fallback only; normally resolved before detok
}

-- Character-class fragments (contents of a [ .. .] set)
local Call_pua = Cfirst .. "-" .. Clast
local Call = Call_pua .. Call_orth
local Vall_pua = Vfirst .. "-" .. Vlast
local Vall = Vall_pua .. Vall_orth
local Vfront = concat {Vi, Vii, Ve, Vje, Vai, Vei}  -- J vowels (front unrounded + æ + ei/ey)
local J = Vfront .. "j"                                     -- J-set incl. orthographic j
local Vauou = concat {Vau, Vou, Vuu}                -- á ó ú (for silent g)
local Vtense = concat {Vau, Vou, Vuu, Vii, Vai, Voei, Vei}  -- á í/ý ó ú æ au ei/ey (nn → tn)
local Cstop = concat {C.p, C.ph, C.t, C.th, C.c, C.ch, C.k, C.kh}
-- Aspirated stop or voiceless fricative or approximant; triggers devoicing e.g. of preceding /r/
local Cvoiceless_pua = concat {C.ph, C.th, C.ch, C.kh, kPAL, C.s, C.f, C.th2, C.x,
							   C.hj, C.hn, C.hnj, C.hng, C.hm, C.hl, C.hr}
 -- We have to assume that at the point Cvoiceless is used, clusters like hj have been to PUA characters.
local Cvoiceless_orth = "ptksfþ"
local Cvoiceless = Cvoiceless_pua .. Cvoiceless_orth

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
		{"([" .. lax_vowels .. "])(gi)", function(v, gi)
			return (lax_back_vowel_front_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. gi
		end},
		-- A3: monophthong diphthongized before ng / nk; this must precede all consonant assimilations because
		-- even if the [ŋ] ends up disappearing or transforming to [n] (e.g. in <punktur> pʰun̥tʏr, with tensed vowel
		-- despite the [ŋ] disappearing), or an [ŋ] appears that wasn't originally present (e.g. in <hrygnt> [r̥ɪŋ̊t],
		-- with lax vowel despite secondary [ŋ]), we need to preserve the vowel quality.
		{"([" .. lax_vowels .. "])(n[gk])", function(v, ngk)
			return (lax_back_vowel_back_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. ngk 
		end},
		-- A4: plain vowels (the length marker ː stays in place after the token)
		{"á", Vau}, {"ó", Vou}, {"ú", Vuu}, {"æ", Vai}, {"é", Vje},
		{"a", Va}, {"e", Ve}, {"í", Vii}, {"i", Vi},
		{"o", Vo}, {"u", Vu}, {"ý", Vii}, {"y", Vi}, {"ö", Voe},
	})

	------------------------------------------------------------------
	-- Phase B0: component-initial consonants (anchored on #)
	------------------------------------------------------------------
	if dialect == "south" then
		w = ugsub(w, "#hv", "#" .. C.x)             -- hv-pronunciation: [x]
	else
		w = ugsub(w, "#hv", "#" .. C.kh .. C.v)        -- standard: [kʰv]
	end
	w = apply(w, {
		{"#h" .. Vje, "#" .. C.hj .. Ve},               -- hé → ç ɛ
		{"#h([jlnr])", function(lnr) return "#" .. orth_to_asp_pua_map[lnr] end}, -- initial hj/hl/hn/hr -> aspirated sonorant
		{"#([hf])", function(hf) return "#" .. orth_to_unasp_pua_map[hf] end}, -- initial h/f -> PUA equivalent
		{"#gj", "#" .. C.c}, {"#kj", "#" .. C.ch},      -- gj → c, kj → cʰ (j absorbed)
		{"#g([" .. J .. "])", "#" .. C.c .. "%1"},         -- g + J → c
		{"#k([" .. J .. "])", "#" .. C.ch .. "%1"},        -- k + J → cʰ
		-- map remaining initial stops to PUA equivalents
		{"#([ptkbdg])", function(stop) return "#" .. orth_to_asp_pua_map[stop] end},
	})

	------------------------------------------------------------------
	-- Phase B0a: mark remaining single k / g for palatalization
	-- must precede phase B1 because we handle some clusters with kPAL
	------------------------------------------------------------------

	------------------------------------------------------------------
	-- Phase B1: consonant clusters (longest / most specific first)
	------------------------------------------------------------------
	w = apply(w, {
		-- (a) Special handling of geminates before other consonants
		-- kkj, ggj, llC where C is not s/t/d are special; all other cases of C₁ːC₂ reduce to C₁C₂
		{"kkj", C.h .. C.c}, {"kk([" .. J .. "])", C.h .. C.c .. "%1"},  -- blekkja, þekkja
		{"ggj", C.c .. Solc}, {"gg([" .. J .. "])", C.c .. Solc .. "%1"}, -- byggja
		{"k([" .. J .. "])", kPAL .. "%1"},
		{"g([" .. J .. "])", gPAL .. "%1"},
		{"ll([std])", "l%1"},
		{"ll([" .. Call .. "])", C.t .. C.hl .. "%1"},
		-- snöggt, keppti, vaffla, etc.; not across component boundaries because e.g. eitthvað should have /ht/ from
		-- <tt> but Solc should be removed in such a case; innbú "household goods" should not have gemination
		{"([" .. Call .. "])%1([" .. Call .. "])", "%1%2"},

		-- (b) 5 consonant clusters; FIXME: these are guesses based on the respective 4-consonant outputs in Eiríkur,
		--     since no clusters with 5 consonants are specifically given.
		{"rnskt", "(" .. C.r .. ")" .. C.n .. C.s .. C.t}, -- bernskt
		{"rnsks", "(" .. C.r .. ")" .. C.n .. C.s .. "(" .. C.k .. C.s .. ")"}, -- bernsks
		
		-- (c) 4 consonant clusters; things like -rrst and -ggnd count as 3 letters and -ggnst as 4 letters because
		--     we already reduced geminate consonants next to other consonants. Do 4-consonant clusters before
		--     3-consonant ones.
		-- (c.1) 4-consonant clusters beginning with <g>
		{"gnst", C.ng .. C.s .. C.t}, -- skyggnst
		-- (c.2) 4-consonant clusters beginning with <l>
		{"([ln])sks", function(ln) return orth_to_unasp_pua_map[ln] .. C.s .. "(" .. C.k .. C.s .. ")" end}, -- falsks; fransks
		{"([ln])skt", function(ln) return orth_to_unasp_pua_map[ln] .. C.s .. C.t end}, -- pólskt; finnskt
		-- (c.3) 4-consonant clusters beginning with <n>
		{"ngds", C.ng .. "(" .. C.t .. ")" .. C.s}, -- strengds
		-- nsks above under lsks
		-- nskt above under lskt
		-- (c.4) 4-consonant clusters beginning with <r>
		{"r[kp]ts", C.hr .. "(" .. C.t .. ")" .. C.s}, -- styrkts; skerpts
		{"rnsk", "(" .. C.r .. ")" .. C.n .. C.s .. C.k}, -- bernska
		{"rsks", C.s .. C.k .. C.s}, -- þorsks; FIXME: should output three pronuns, with [r̥s], [sks] and [sː]
		{"rskt",  "(" .. C.hr .. ")" .. C.s .. C.t}, -- gerskt
		-- r?sts needs to precede r[fkp]?st because the latter affects rst, which is part of rsts
		{"r?sts", C.s .. C.t .. C.s}, -- fyrsts; prests; FIXME: should output two pronuns, one with [sː] and the other with [sts]
		{"r[fkp]?st", "(" .. C.hr .. ")" .. C.s .. C.t}, -- horfst; styrkst; skerpst; berst

		-- (d) 3 consonant clusters
		-- (d.1) beginning with <f>
		{"fld", "(" .. C.v .. ")" .. C.l .. C.t}, -- efldi
		{"flt", C.hl .. C.t}, -- teflt
		{"fnd", C.m .. C.t}, -- hefndi; not a mistake, fn mutually assimilates to m
		{"fns", C.p .. C.hn .. C.s}, -- hrafns; FIXME, should output two pronuns, one with [fs] and the other with [pn̥s]
		{"fnt", C.hm .. C.t}, -- jafnt; not a mistake, fn mutually assimilates to m, which is aspirated by the preaspiration of t
		{"fts", C.f .. "(" .. C.t .. ")" .. C.s}, -- lofts
		-- (d.2) beginning with <g> or <k>
		{"gld", C.l .. C.t}, -- sigldi
		{"glt", C.hl .. C.t}, -- siglt
		{"gnd", C.ng .. C.t}, -- rigndi
		{"gns", C.k .. C.hn .. C.s}, -- gagns; FIXME, should output two pronuns, one with [xs] and the other with [kn̥s]
		{"[gk]nt", C.hng .. C.t}, -- hrygnt; sýknt
		{"[gk]ts", C.x .. "(" .. C.t .. ")" .. C.s}, -- gjögts; svekkts
		-- (d.3) beginning with <l>
		{"lds", C.l .. "(" .. C.t .. ")" .. C.s}, -- þvælds
		{"l[fg]d", C.l .. C.t}, -- hvolfdi, fylgdi
		{"lfr", C.l .. "(" .. C.v .. ")" .. C.r}, -- ýlfra
		{"lfs", C.l .. "(" .. C.f .. ")" .. C.s}, -- úlfs
		{"l[fk]t", C.hl .. C.t}, -- tólfti, velktur
		{"lgn", C.l .. C.n}, -- volgna
		{"lks", C.hl .. C.k .. C.s}, -- fólks; FIXME, should output two pronuns, one with [ls] and the other with [l̥ks]
		{"lps", C.hl .. C.p .. C.s}, -- hvolps; FIXME, should output two pronuns, one with [ls] and the other with [l̥ps]
		{"lts", C.hl .. "(" .. C.t .. ")" .. C.s}, -- gyllts
		-- (d.4) beginning with <m>
		{"mbd", C.m .. C.t}, -- rembdist
		{"mbs", C.m .. C.s}, -- lambs
		{"mbt", C.hm .. C.t}, -- kembt
		{"mds", C.m .. "(" .. C.t .. ")" .. C.s}, -- límds
		{"mps", C.hm .. C.p .. C.s}, -- svamps; FIXME, should output two pronuns, one with [ms] and the other with [m̥ps]
		-- (d.5) beginning with <n>
		{"nds", C.n .. "(" .. C.t .. ")" .. C.s}, -- sands
		{"ngd", C.ng .. C.t}, -- hringdi
		{"ngn", "(" .. C.ng .. ")" .. C.n}, -- lungna
		{"ngs", C.ng .. C.s}, -- hangs
		{"ngt", C.hng .. C.t}, -- tengt
		{"nks", C.hng .. "(" .. C.k .. ")" .. C.s}, -- dynks
		{"nkt", C.hn .. C.t}, -- punktur
		-- (d.6) beginning with <p>
		{"pts", C.f .. "(" .. C.t .. ")" .. C.s}, -- teppts
		-- (d.7) beginning with <r>
		-- NOTE: of the following six clusters, Eiríkur lists pronuunciations for 5, omitting <rgl>. By analogy, it
		-- should be pronounced [rtl], and I assume this. -rgl- seems to occur only in 4-5 verbs:
		-- * <sargla> "to clatter, to rattle, to make a scraping sound" (literary)
		-- * <svargla> "[ditto]" (rare)
		-- * <snörgla> "to wheeze, to snort, to rattle in the throat" (archaic)
		-- * <gúrgla> "to gargle" (archaic)
		-- * <gurgla> "[ditto]" (Google says this is the modern replacement for <gúrgla> but it appears to be wrong
		--                       and in fact <gurgla> is obsolete, not even in BÍN)
		-- Google says <rgl> is pronounced [r̥kl] but this is clearly wrong; the unvoiced [r̥] in particular would
		-- definitely not be expected before <g>.
		{"r[ðfg]l", C.r .. C.t .. C.l}, -- sperðlar; hvarfla; sargla~svargla/gúrgla~gurgla/snörgla
		{"r[ðfg]n", C.r .. C.t .. C.n}, -- harðna; horfnir; morgna
		{"r[fg]ð", C.r .. C.dh}, -- horfði; mergð
		-- rfl above
		-- rfn above
		{"rfs", C.r .. "(" .. C.f .. ")" .. C.s}, -- orfs
		-- rfst in 4-char section above
		{"r[fgkp]t", C.hr .. C.t}, -- horft; margt; myrkt; skyrpti
		-- rgð above
		-- rgn above
		{"rgs", C.r .. "(" .. C.k .. ")" .. C.s}, -- dvergs
		-- rgt above
		{"r([kpt])s", function(kpt) return C.hr .. "(" .. orth_to_unasp_pua_map[kpt] .. ")" .. C.s end}, -- sterks; þorps; svarts
		-- rkst in 4-char section above
		-- rkt above
		-- rkts in 4-char section above
		{"rls", "((" .. C.r .. ")" .. C.t .. ")" .. C.l .. C.s}, -- karls
		{"rm([ds])", function(ds) return "(" .. C.r .. ")" .. C.m .. orth_to_unasp_pua_map[ds] end}, -- þyrmdi, harms
		{"rmt", "(" .. C.hr .. ")" .. C.hm .. C.t}, -- hermt
		{"rnd", "(" .. C.r .. ")" .. C.n .. C.t}, -- fyrndur
		{"rns", C.hr .. C.s}, -- barns
		-- rnsk in 4-char section above
		{"rnt", C.hn .. C.t}, -- hyrnt
		-- rps above under rks
		-- rpst in 4-char section above
		-- rpt above
		-- rpts in 4-char section above
		{"rsk", "(" .. C.hr .. ")" .. C.s .. C.k}, -- norskur
		{"rs" .. kPAL, "(" .. C.hr .. ")" .. C.s .. C.c}, -- fjarski
		-- rsks in 4-char section above
		-- rskt in 4-char section above
		{"rs([ln])", function(ln) return "(" .. C.hr .. ")" .. C.s .. C.t .. orth_to_unasp_pua_map[ln] end}, -- sparsla; versna
		-- rst in 4-char section above (due to optional consonant after r)
		-- rsts in 4-char section above
		-- rts above under rks
		-- (d.8) beginning with <s>
		{"sks", C.s .. C.k .. C.s}, -- fisks; FIXME: should output two pronuns, one with [sː] and the other with [sks]
		{"skt", C.s .. C.t}, -- frist
		{"sps", C.s .. C.p .. C.s}, -- rasps; FIXME: should output two pronuns, one with [sː] and the other with [sps]
		{"stk", C.s .. C.k},
		{"st" .. kPAL, C.s .. C.c}, -- systkin
		-- sts in 4-char section above (due to optional r in rsts)
		-- (d.9) beginning with <t>
		{"tns", C.s .. "ː"},

		-- (3) 2 consonant clusters
		{"ðk", C.th2 .. C.k},                         -- ð devoiced before k → θ
		-- nasal + velar/palatal stop (place + voicing by following segment)
		{"nk([" .. J .. "])", C.hnj .. C.c .. "%1"},        -- voiceless palatal: banki
		{"nk", C.hng .. C.k},                         -- voiceless velar: banka
		{"ng([" .. J .. "])", C.nj .. C.c .. "%1"},         -- voiced palatal: angi
		{"ng", C.ng .. C.k},                          -- voiced velar: hanga, langur
		-- geminates and preaspiration
		{"([kpt])%1", function(kpt) return C.h .. orth_to_unasp_pua_map[kpt] end}, -- drekka, stoppa, fletta
		-- nn → tn after a tense vowel / diphthong, else n
		{"([" .. Vtense .. "])(ː?)nn", "%1%2" .. C.t .. C.n},
		-- hagga, etc.
		{"([bdgfhsþðmnr])%1", function(c) return orth_to_unasp_pua_map[c] .. Solc end},
		{"ll", C.t .. C.l},
		-- preaspiration: p/t/k + l/n
		{"([kpt])([ln])", function(kpt, ln) return C.h .. orth_to_unasp_pua_map[kpt] .. orth_to_unasp_pua_map[ln] end},
		{"kt", C.x .. "t"}, -- rakti → x t
		{"pt", C.f .. C.t}, -- æpti → f t
		-- no gemination before consonant across syllable boundary, as in innbú;
		-- this must go as early as possible so that words like kyrrstæður respelled <kyrr-stæður> have
		-- devoiced <r>
		{Solc .. "#([" .. Call .. "])", "#%1"}, -- innbú should not have (ː)
	})

	------------------------------------------------------------------
	-- Phase B3a: devoicing of liquids/nasals before a stop
	-- (the following stop letter is kept for its own conversion)
	------------------------------------------------------------------
	w = apply(w, {
		-- r becomes voiceless before any aspirated stop or voiceless fricative/approximant,
		-- including across component boundaries
		{"r(#?" .. "[" .. Cvoiceless .. "])", C.hr .. "%1"},
		-- l/m becomes voiceless before an aspirated stop
		{"([lm])([kpt" .. kPAL .. "])", function(lm, kpt) return orth_to_asp_pua_map[lm] .. kpt end},
		{"nt", C.hn .. C.t},                          -- vanta
	})

	-- Phase B3a2: epenthetic [t] in rl, rn, sl, sn
	w = apply(w, {
		{"([rs])([ln])", function(rs, ln) return orth_to_unasp_pua_map[rs] .. C.t .. orth_to_unasp_pua_map[ln] end}
	})

	------------------------------------------------------------------
	-- Phase B3b: g and k realizations
	------------------------------------------------------------------
	w = apply(w, {
		-- g
		{"([" .. Vauou .. "])(ː?)g([" .. Vall .. "])", "%1%2%3"},      -- silent after á/ó/ú
		{"gt", C.x .. "t"},                                        -- sagt: g → x (t kept)
		{"g([ðr])", C.gh .. "%1"},                                 -- sigra, sagði → ɣ
		{"([" .. Vall .. "])(ː?)g([" .. Vall .. "])", "%1%2" .. C.gh .. "%3"},-- saga → ɣ (intervocalic)
		{"([" .. Vall .. "])(ː?)g#", "%1%2" .. C.gh .. "#"},             -- lag → ɣ (final after a vowel)
		{gPAL .. "j", C.j},                                        -- gj → j (lægja)
		{"([" .. Vall .. "])(ː?)" .. gPAL .. "([" .. Vall .. "])", "%1%2" .. C.j .. "%3"}, -- hagi → j
		{gPAL, C.c},                                             -- elsewhere palatal g → c
		{"g", C.k},                                              -- elsewhere velar g → k
		-- k
		{kPAL .. "j", C.c},                                        -- kj → c (rekja)
		{kPAL, C.c},                                             -- ríki → c
		{"k", C.k},                                              -- baka → k
	})

	------------------------------------------------------------------
	-- Phase B3c: f realizations
	------------------------------------------------------------------
	w = apply(w, {
		{"f([ln])", C.p .. "%1"},                    -- efla, hafna → p
		{"f([st])", C.f .. "%1"},                    -- ofsi, aftur → f
		{"f", C.v},                                -- sofa → v
	})

	------------------------------------------------------------------
	-- Phase B3d: remaining single consonants
	------------------------------------------------------------------
	w = apply(w, {
		{"x", C.k .. C.s},                            -- x → ks
		{"([bdptmnlrðþvsjk])", orth_to_unasp_pua_map},
	})

	-- component-final stop + [n]/[l] devoice the sonorant: vopn [vɔhpn̥], magn [makn̥], einn [eitn̥], stjákl [stjauhkl̥]
	w = ugsub(w, "([" .. unaspirated_stops_pua .. "])([" .. C.n .. C.l .. "])#",
			function(stop, nl) return stop .. devoice_resonant_map[nl] .. "#" end
	)

	------------------------------------------------------------------
	-- Phase B3e: same-place stop consonants drop across component boundaries
	------------------------------------------------------------------
	w = apply(w, {
		{"[" .. C.k .. C.kh .. "]#([" .. C.k .. C.kh .. C.c .. C.ch .. "])", "#%1"},
		{"[" .. C.p .. C.ph .. "]#([" .. C.p .. C.ph .. "])", "#%1"},
		{"[" .. C.t .. C.th .. "]#([" .. C.t .. C.th .. "])", "#%1"},
		{C.s .. "#" .. C.s, "#" .. C.s},
	})

	------------------------------------------------------------------
	-- Dialect adjustments (best-effort; standard is the default)
	------------------------------------------------------------------
	if dialect == "north" or dialect == "northeast" then
		-- harðmæli: aspirate non-initial unaspirated stops between a vowel and a
		-- following sonorant (vowel / j / r / v). The optional ː is the length mark.
		w = ugsub(w, "([" .. Vall .. "]ː?)([" .. unaspirated_stops_pua .. "])([" .. Vall .. C.j .. C.r .. C.v .. "])",
			function(v1, stop, son2) return v1 .. aspirate_stop_map[stop] .. son2 end
		)
	end
	if dialect == "northeast" then
		-- voiced pronunciation: a nasal voices before a stop, and the stop aspirates
		local voiceless_nasals_pua = C.hm .. C.hn .. C.hnj .. C.hng
		w = ugsub(w, "([" .. voiceless_nasals_pua .. "])([" .. unaspirated_stops_pua .. "])",
			function(nv, stop) return voice_resonant_map[nv] .. aspirate_stop_map[stop] end
		)
		-- l voices (and stop aspirates) before labial/velar stops, but stays
		-- voiceless before t (per doc: piltur, elta keep [l̥t])
		w = ugsub(w, C.hl .. "([" .. C.p .. C.k .. C.c .. "])",
			function(stop) return C.l .. aspirate_stop_map[stop] end
		)
		-- ð voiced (and following k aspirated) in -ðk-: maðkur [maðkʰʏr]
		w = ugsub(w, C.th2 .. C.k, C.dh .. C.kh)
	end

	------------------------------------------------------------------
	-- Steps 4–5: detokenize and clean up
	------------------------------------------------------------------
	w = ugsub(w, ".", detok)
	-- First component gets primary stress, others get secondary
	w = w:gsub("^##", "ˈ"):gsub("##$", ""):gsub("#", "ˌ")
	return w
end

local function toIPA_word(word, dialect)
	local components = split(word, "[-‿]")
	for i, component in ipairs(components) do
		component = mw.ustring.lower(component)
		components[i] = determine_vowel_length(i, component, components[i + 1])
	end
	word = "##" .. concat(components, "#") .. "##"
	return convert(word, dialect)
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
