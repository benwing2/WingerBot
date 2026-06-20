local export = {}

local lang = require("Module:languages").getByCode("is")

local parse_utilities_module = "Module:parse utilities"
local pron_utilities_module = "Module:pron utilities"
local table_module = "Module:table"
local m_string_utilities = require("Module:string utilities")

local ugsub = m_string_utilities.gsub
local usub = m_string_utilities.sub
local umatch = m_string_utilities.match
local pattern_escape = m_string_utilities.pattern_escape
local replacement_escape = m_string_utilities.replacement_escape
local toNFC = mw.ustring.toNFC
local toNFD = mw.ustring.toNFD
local u = m_string_utilities.char
local codepoint = mw.ustring.codepoint
local split = m_string_utilities.split
local concat = table.concat
local insert = table.insert
local dump = mw.dumpObject


local function split_on_comma(term)
	if term:find(",%s") or term:find("\\") then
		return require(parse_utilities_module).split_on_comma(term)
	else
		return split(term, ",")
	end
end

-- Convert a string of characters to a list. This does not handle ranges.
local function explode_to_list(s)
	local chars = {}
	for cp in mw.ustring.gcodepoint(s) do
		insert(chars, u(cp))
	end
	return chars
end


-- Convert a string of characters to a set. This handles hyphen-delimited ranges, as in Lua patterns.
local function explode_to_set(s)
	local charset = {}
	local first_of_range = nil
	local next_is_end_of_range = false
	for cp in mw.ustring.gcodepoint(s) do
		local ch = u(cp)
		if ch == "-" then
			if not first_of_range then
				error("Internal error: Encountered hyphen without preceding start character")
			end
			next_is_end_of_range = true
		elseif next_is_end_of_range then
			for c = first_of_range + 1, cp do
				charset[u(c)] = true
				next_is_end_of_range = false
			end
		else
			first_of_range = cp
			charset[ch] = true
		end
	end
	if next_is_end_of_range then
		error("Internal error: Encountered hyphen without following end character")
	end
	return charset
end

-- Single-character vowels in Icelandic orthography
local Vall_orth = "aáæeéiíoóöuúyý"

-- Orthographic consonant letters
local Call_orth = "bdðfghjklmnprstvxþ"

-- Transparent cluster exception: ptks + vjr → vowel remains long despite 2-consonant cluster
-- (e.g. pr in tepra, kr in dekra, tv in upgötva, sr in hausra, pj in vepja, tj in letja);
-- also in written <dr>, <br> etc. in loanwords, e.g. adrenalín, Abraham
local ptks = {["p"] = true, ["t"] = true, ["k"] = true, ["s"] = true, ["b"] = true, ["d"] = true}
local vjr  = {["v"] = true, ["j"] = true, ["r"] = true}

local BREVE = u(0x0306)

local function pua(n) return u(0xE000 + n) end

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

local kPAL, gPAL        = pua(30), pua(31) -- Palatalization markers: k/g immediately before a J-set segment

-- Suprasegmental tokens
local Solc              = pua(50)          -- optional long after a consonant

local Cfirst, Clast     = pua(0), pua(99)

-- Obligatory copies of all consonants; they are separate so they aren't affected by most rules
local OC = {}
-- Map from obligatory PUA characters to regular PUA chars
local OC_to_C = {}

local Soblc              = pua(150)          -- obligatory long after a consonant

for phone, pua_char in pairs(C) do
	local obl_pua_char = u(100 + codepoint(pua_char))
	OC[phone] = obl_pua_char
	OC_to_C[obl_pua_char] = pua_char
end

local OCfirst, OClast     = pua(100), pua(199)

-- Vowel tokens
local Va, Vai, Vau      = pua(200), pua(201), pua(202)        -- a ai au
local Ve, Vje           = pua(203), pua(204)                 -- ɛ jɛ
local Vi, Vii           = pua(205), pua(206)                 -- ɪ i
local Vo, Vou           = pua(207), pua(208)                 -- ɔ ou
local Vu, Vuu           = pua(209), pua(210)                 -- ʏ u
local Voe, Voei         = pua(211), pua(212)                 -- œ œi
local Vei, Voi, Vui     = pua(213), pua(214), pua(215)        -- ei ɔi ʏi
local Vai_gi            = pua(216)                          -- ai (from a before -gi; NOT in J-set)

local Vfirst, Vlast     = pua(200), pua(299)

local decompose_breve_map = {
	["ă"] = "a" .. BREVE,
	["ĕ"] = "e" .. BREVE,
	["ĭ"] = "i" .. BREVE,
	["ŏ"] = "o" .. BREVE,
	["ŭ"] = "u" .. BREVE,
}


local aspirate_stop_map = {[C.p] = C.ph, [C.t] = C.th, [C.c] = C.ch, [C.k] = C.kh}
local unaspirated_stops_pua = C.p .. C.t .. C.c .. C.k
local devoice_resonant_map = {[C.m] = C.hm, [C.n] = C.hn, [C.nj] = C.hnj, [C.ng] = C.hng, [C.l] = C.hl, [C.r] = C.hr}
local voice_resonant_map = {[C.hm] = C.m, [C.hn] = C.n, [C.hnj] = C.nj, [C.hng] = C.ng, [C.hl] = C.l, [C.hr] = C.r}
local orth_to_asp_pua_map = {b = C.p, d = C.t, g = C.k, [gPAL] = C.c, p = C.ph, t = C.th, k = C.kh, [kPAL] = C.ch,
							 l = C.hl, m = C.hm, n = C.hn, r = C.hr, j = C.hj}
local orth_to_unasp_pua_map = {b = C.p, d = C.t, g = C.k, [gPAL] = C.c, p = C.p, t = C.t, k = C.k, [kPAL] = C.c,
							   l = C.l, m = C.m, n = C.n, r = C.r, j = C.j,
							   f = C.f, h = C.h, s = C.s, ["þ"] = C.th2, v = C.v, ["ð"] = C.dh}

local bracketed_phone_map = {
	f = OC.f,
	s = OC.s,
	x = OC.x,
	kh = OC.kh,
	k = OC.k,
	th = OC.th,
	t = OC.t,
	ph = OC.ph,
	p = OC.p,
	ch = OC.ch,
	c = OC.c,
	[":"] = Soblc,
}

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
	[Soblc] = "ː",
	[kPAL] = "c", [gPAL] = "j",  -- fallback only; normally resolved before detok
}

-- Character-class fragments (contents of a [ .. .] set)
local Call_pua = Cfirst .. "-" .. Clast
-- allow explicit use of certain IPA consonants in respelling; ŋ and ɲ don't trigger diphthongization
local Call = Call_pua .. Call_orth .. "ŋɲçɣ"
local OCall = OCfirst .. "-" .. OClast
local COCall = Call .. OCall
-- We need to include obligatory PUA characters to handle bracketed characters, which we map directly to PUA characters
-- before vowel length determination.
local consonant_set = explode_to_set(COCall)
local Vall_pua = Vfirst .. "-" .. Vlast
local Vall = Vall_pua .. Vall_orth
local vowel_set = explode_to_set(Vall)
local Vfront = concat {Vi, Vii, Ve, Vje, Vai, Vei}  -- J vowels (front unrounded + æ + ei/ey)
local J = Vfront .. "j"                                     -- J-set incl. orthographic j
local Vauou = concat {Vau, Vou, Vuu}                -- á ó ú (for silent g)
local Vtense = concat {Vau, Vou, Vuu, Vii, Vai, Voei, Vei}  -- á í/ý ó ú æ au ei/ey (nn → tn)
-- Aspirated stop or voiceless fricative or approximant; triggers devoicing e.g. of preceding /r/;
-- C.h should not be present
local Cvoiceless_pua = concat {C.ph, C.th, C.ch, C.kh, kPAL, C.s, C.f, C.th2, C.x,
							   C.hj, C.hn, C.hnj, C.hng, C.hm, C.hl, C.hr}
-- "Voiceless" obligatory PUA characters should still trigger devoicing. No equivalent of kPAL,
-- which is generated secondarily..
local OCvoiceless_pua = concat {OC.ph, OC.th, OC.ch, OC.kh, OC.s, OC.f, OC.th2, OC.x,
							   OC.hj, OC.hn, OC.hnj, OC.hng, OC.hm, OC.hl, OC.hr}
-- We have to assume that at the point Cvoiceless is used, clusters like hj have been to PUA characters.
local Cvoiceless_orth = "ptksfþ"
local Cvoiceless = Cvoiceless_pua .. Cvoiceless_orth .. "ç"
local COCvoiceless = Cvoiceless .. OCvoiceless_pua

-- This maps each "variation" (e.g. "formal", "allegro"), to an object with properties `class` (the class that groups
-- the variations, e.g. "formality" for "formal", "speed" for "allegro"), `priority` (for sorting the variations,
-- derived from the order in which they are listed in the `variation_classes` table) and `display` (how to display the
-- variation, defaulting to the variation text itself).
local variation_to_properties = {}


-- Given a table `levels` in the form of a set listing the levels (variations) for a given pronunciation in a given
-- class, sort the levels according to their priority and display them. Most commonly there is only one level, but
-- there may be more than one in some cases, particularly if a given class has more than two possible levels.
local function display_levels(levels)
	local level_list = {}
	for level, _ in pairs(levels) do
		insert(level_list, level)
	end
	table.sort(level_list, function(a, b)
		return variation_to_properties[a].priority < variation_to_properties[b].priority
	end)
	for i, level in ipairs(level_list) do
		level_list[i] = variation_to_properties[level].display
	end
	return mw.text.listToText(level_list, nil, " or ")
end
	
	
local variation_classes = {
	formality = {
		priority = 1,
		levels = {
			{level = "formal"},
			{level = "informal"},
		},
		generate_note = display_levels,
	},
	speed = {
		priority = 2,
		levels = {
			{level = "careful"},
			{level = "natural"},
			{level = "allegro", display = "fast/allegro"},
		},
		generate_note = function(levels)
			return display_levels(levels) .. " pronunciation"
		end,
	},
	currency = {
		priority = 3,
		levels = {
			{level = "modern"},
			{level = "older"},
		},
		generate_note = display_levels,
	},
}


-- Populate `variation_to_properties`.
for class, props in pairs(variation_classes) do
	for i, level in ipairs(props.levels) do
		variation_to_properties[level.level] = {
			class = class,
			priority = i,
			display = level.display or level.level,
		}
	end
end


local function levels_by_class_to_qualifiers(levels_by_class)
	local seen_classes = {}
	for class, _ in pairs(levels_by_class) do
		insert(seen_classes, class)
	end
	table.sort(seen_classes)
	local qualifiers = {}
	for _, class in ipairs(seen_classes) do
		insert(qualifiers, variation_classes[class].generate_note(levels_by_class[class]))
	end
	if qualifiers[1] then
		return qualifiers
	else
		return nil
	end
end


local function separate_variations_into_classes_and_levels(variations)
	local levels_by_class = {}
	for _, variation in ipairs(variations) do
		local varprops = variation_to_properties[variation]
		if not varprops then
			error(("Unrecognized variation %s in rule"):format(variation))
		end
		local class = varprops.class
		if not levels_by_class[class] then
			levels_by_class[class] = {}
		end
		levels_by_class[class][variation] = true
	end

	return levels_by_class
end


local function intersect_each_class(existing_class_levels, new_class_levels)
	local retval = {}
	for class, _ in pairs(variation_classes) do
		local existing_levels_by_class = existing_class_levels[class]
		local new_levels_by_class = new_class_levels[class]
		local intersection
		if not existing_levels_by_class then
			intersection = new_levels_by_class
		elseif not new_levels_by_class then
			intersection = existing_levels_by_class
		else
			intersection = {}
			for existing_var, _ in pairs(existing_levels_by_class) do
				if new_levels_by_class[existing_var] then
					intersection[existing_var] = true
				end
			end
			if not next(intersection) then
				return false -- no intersection, reject this pronunciation
			end
		end
		retval[class] = intersection
	end
	return retval
end


local function union_each_class(existing_class_levels, new_class_levels)
	local retval = {}
	for class, _ in pairs(variation_classes) do
		local existing_levels_by_class = existing_class_levels[class]
		local new_levels_by_class = new_class_levels[class]
		local union
		if not existing_levels_by_class or not new_levels_by_class then
			union = nil
		else
			union = {}
			for existing_var, _ in pairs(existing_levels_by_class) do
				union[existing_var] = true
			end
			for new_var, _ in pairs(new_levels_by_class) do
				union[new_var] = true
			end
			if require(table_module).size(union) == #variation_classes[class].levels then
				-- the union includes all possible elements
				union = nil
			end
		end
		retval[class] = union
	end
	return retval
end


local function insert_pron_or_merge(existing_prons, newpron)
	local found_existing = false
	for i = 1, #existing_prons do
		if existing_prons[i].output == newpron.output then
			existing_prons[i].levels_by_class = union_each_class(existing_prons[i].levels_by_class, newpron.levels_by_class)
			found_existing = true
			break
		end
	end
	if not found_existing then
		insert(existing_prons, newpron)
	end
end


-- Apply an ordered list of {pattern, replacement} substitutions.
local function apply(w, rules)
	local outw = w
	for _, rule in ipairs(rules) do
		if type(rule) ~= "table" then
			error("Expected rule to be a table but saw " .. dump(rule))
		end
		if type(rule[2]) == "string" or type(rule[2]) == "function" or type(rule[2]) == "table" and not rule[2][1] then
			-- a simple rule; apply to each output
			if #outw == 1 then
				outw[1].output = ugsub(outw[1].output, rule[1], rule[2])
			else
				local newoutw = {}
				for i = 1, #outw do
					local newpron = {
						output = ugsub(outw[i].output, rule[1], rule[2]),
						levels_by_class = outw[i].levels_by_class,
					}
					insert_pron_or_merge(newoutw, newpron)
				end
				outw = newoutw
			end
		else
			-- multiple possibilities
			local newoutw = {}
			for i = 1, #outw do
				for j = 1, #rule[2] do
					-- Determine whether the given possibility is applicable. We separate the variations listed for
					-- each possibility into the corresponding classes and levels. If no level is specified for a given
					-- class, the possibility is assumed to apply to all levels for that class. We take the intersection
					-- of the levels of the possibility with the existing levels of the pronunciation we will be
					-- applying the possibility to, and reject that possibility if the intersection is empty.
					local rulespec = rule[2][j]
					local new_levels_by_class
					if not rulespec.var then
						new_levels_by_class = outw[i].levels_by_class
					else
						local vars = rulespec.var
						if type(vars) == "string" then
							vars = {vars}
						end
						local this_levels_by_class = separate_variations_into_classes_and_levels(vars)
						new_levels_by_class = intersect_each_class(outw[i].levels_by_class, this_levels_by_class)
					end
					if new_levels_by_class ~= false then
						local newpron = {
							output = ugsub(outw[i].output, rule[1], rulespec.replace),
							levels_by_class = new_levels_by_class,
						}
						insert_pron_or_merge(newoutw, newpron)
					end
				end
			end
			outw = newoutw
		end
	end
	return outw
end


local function concatenate_horizontally(part1_pronuns, part2_pronuns, concatfun)
	local retval = {}
	for _, pronun1 in ipairs(part1_pronuns) do
		for _, pronun2 in ipairs(part2_pronuns) do
			local new_levels_by_class = intersect_each_class(pronun1.levels_by_class, pronun2.levels_by_class)
			if new_levels_by_class ~= false then
				insert(retval, {
					output = concatfun(pronun1.output, pronun2.output),
					levels_by_class = new_levels_by_class,
				})
			end
		end
	end
	return retval
end


-- Mark vowel length on the first (stressed) vowel nucleus.
-- Icelandic phonemic vowel length is only contrastive in stressed syllables,
-- which is always the first syllable in non-compound words.
--
-- Long if: 0 or 1 consonant follows (before next vowel or component end).
-- Short if: 2+ consonants follow (cluster or geminate), unless the cluster is
--   one of the transparent clusters ptksbd + vjr (e.g. pr, kr, tv, tj, kv, br, dr).
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
				local long = false
				local j = i + nlen  -- index of first character after the nucleus
				if chars[j] == BREVE then
					nlen = nlen + 1
				else
					-- Count orthographic consonant letters following the nucleus
					local count = 0
					local c1, c2 = nil, nil
					local k = j
					while k <= n and (consonant_set[chars[k]] or chars[k] == "_" or chars[k] == "+") do
						local cc = chars[k]
						if cc ~= "_" and cc ~= "+" then
							if count == 0 then c1 = cc end
							if count == 1 then c2 = cc end
							count = count + (cc == "x" and 2 or 1)  -- x = /ks/ = 2 consonants
						end
						k = k + 1
					end
	
					-- -gi-/-j- special case: vowel (other than <í>/<ý>) is always short (and diphthongized) before <gi> and <j>
					local before_gi = c1 == "j" or c1 == "g" and chars[j + 1] == "i" -- it's ok if j > n, we just get nil
	
					-- At this point, j is the index of the first character after the stressed vowel
					-- nucleus, and k is the index of the first character after any consonant cluster
					-- following the vowel nucleus. Either may be > n (the number of characters in the
					-- component).
					if next_component and k > n then
						-- Non-final component, single-syllable component.
						if count == 0 then
							long = true -- component ends in a vowel
						elseif count == 1 and ptks[c1] then
							long = true -- ends in a single orthographic <p>, <t>, <k>, <s>, <b> or <d>
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
						if before_gi and nucleus ~= "í" and nucleus ~= "ý" then
							long = false
						elseif count <= 1 then
							long = true
						elseif count == 2 and ptks[c1] and c2 and vjr[c2] then
							long = true  -- transparent cluster: stays long
						else
							long = false
						end
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

-- Syllabify a word composed of phones (not letters) by adding a period (.) between each syllable. Respect periods that
-- may already be present, added in the respelling.
local function syllabify(word)
	-- Assume any unknown character is a consonant. "Vowels" are only those in the Vall range as well as any following
	-- ː, possibly in parens. The algorithm for placing the syllable divider is that it goes to the left of a rightmost
	-- ptks+vjr cluster, otherwise to the left of the rightmost consonant.
	local clusters = split(word, "([" .. Vall .. "][ː()]*)")
	for i = 3, #clusters - 2, 2 do
		local cluster = clusters[i]
		if not cluster:find("%.") then -- check for the case where the user put an explicit syllable boundary
			-- Note that we're operating on phones here, not letters, so kj will have already been converted to C.c,
			-- but that is fine because it gets treated as a single phone.
			cluster = ugsub(cluster, "^(.-)(%(?[" .. C.p .. C.t .. C.k .. C.s .. "]%)?%(?[" .. C.v .. C.j .. C.r .. "]%)?)$", "%1.%2")
		end
		if not cluster:find("%.") then
			-- ptks+vjr not found
			cluster = ugsub(cluster, "^(.-)(%(?.%)?)$", "%1.%2")
		end
		if not cluster:find("%.") then
			-- no characters probably
			cluster = "." .. cluster
		end
		clusters[i] = cluster
	end
	return concat(clusters)
end

-- If a syllable begins with optional consonant gemination, i.e. (ː), convert it to the preceding consonant.
-- This is used when adding a secondary stress to the syllable as the best possible way of handling this.
local function resolve_optional_consonant_gemination(syllable, prev_syllable)
	if syllable:find("^" .. Solc) then
		local last_cons = umatch(prev_syllable, "(.)%)?$")
		if not last_cons then
			mw.log(("WARNING: Solc (optional consonant gemination) not preceded by consonant: syllable=%s, prev_syllable=%s"):format(
				syllable, prev_syllable
			))
		else
			syllable = last_cons .. umatch(syllable, "^" .. Solc .. "(.*)$")
		end
	end
	return syllable
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

-- This function converts `w` (an object describing the pronunciation(s) of a word) from respellings to IPA
-- pronunciations. In general, `w` is a list of pronunciations, each of which is an object with an `output` field
-- (a string) containing the pronunciation, and a `levels_by_class` field describing the associated register, speed,
-- etc. of this pronunciation, structured as a table mapping class names (e.g. "formality", "speed") to sets of
-- levels that apply for this class (e.g. a set containing "natural" and "allegro" for the class "speed"). On input,
-- there is only a single pronunciation with `levels_by_class` an empty table, with the pronunciation being the
-- input respelling with some transformations already applied; notably, ## is added to the beginning and end of the
-- word, hyphens marking component boundaries have been converted to #, and length marks have been added after long
-- vowels per determine_vowel_length(). On output, there may be multiple pronunciations, where the `output` field
-- of each pronunciation is in IPA and the `levels_by_class` table is filled in (if a particular class is missing in the
-- `levels_by_class` table, it means that all possible levels apply). `dialect` specifies the dialect to generate the
-- pronunciation of, and can be either "north", "northeast", "south" or nil for the standard dialect.
-- `disable_internal_stresses` is used by bots that convert raw IPA to respelling and causes stresses in the middle of a
-- component of 3 or more syllables to be omitted.
local function convert(w, dialect, disable_internal_stresses)
	local orig_respelling = w[1].output -- for debugging purposes

	------------------------------------------------------------------
	-- Step 3.1: vowels → tokens
	------------------------------------------------------------------
	w = apply(w, {
		-- A1: digraphs (longest first)
		{"au", Voei}, {"ei", Vei}, {"ey", Vei},
		-- A2: monophthong diphthongized + shortened before -gi, -gj
		{"([" .. lax_vowels .. "])(g[ij])", function(v, gij)
			return (lax_back_vowel_front_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. gij
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
	-- Step 3.2: component-initial stops and h (anchored on #)
	------------------------------------------------------------------
	if dialect == "south" then
		w = apply(w, {{"#hv", "#" .. C.x}})             -- hv-pronunciation: [x]
	else
		w = apply(w, {{"#hv", "#" .. C.kh .. C.v}})        -- standard: [kʰv]
	end
	w = apply(w, {
		{"#h" .. Vje, "#" .. C.hj .. Ve},               -- hé → ç ɛ
		{"#h([jlnr])", function(lnr) return "#" .. orth_to_asp_pua_map[lnr] end}, -- initial hj/hl/hn/hr -> aspirated sonorant
		{"#h", "#" .. C.h},                                -- initial h + vowel
		{"#gj", "#" .. C.c},                               -- gj → c (j absorbed)
		{"#kj", "#" .. C.ch},                              -- kj → cʰ (j absorbed)
		{"#g([" .. J .. "])", "#" .. C.c .. "%1"},         -- g + J → c
		{"#k([" .. J .. "])", "#" .. C.ch .. "%1"},        -- k + J → cʰ
		-- map remaining initial stops to PUA equivalents
		{"#([ptkbdg])", function(stop) return "#" .. orth_to_asp_pua_map[stop] end},
	})

	------------------------------------------------------------------
	-- Step 3.3: consonant clusters (longest / most specific first)
	------------------------------------------------------------------
	w = apply(w, {
		-- (a) Special handling of geminates before other consonants and kj/gj
		-- kkj, ggj, llC where C is not s/t/d are special; all other cases of C₁ːC₂ reduce to C₁C₂
		{"kkj", C.h .. kPAL},
		{"kk([" .. J .. "])", C.h .. kPAL .. "%1"},  -- blekkja, þekkja
		{"ggj", gPAL .. Solc},
		{"gg([" .. J .. "])", gPAL .. Solc .. "%1"}, -- byggja
		{"kj", kPAL},
		{"k([" .. J .. "])", kPAL .. "%1"},
		{"gj", gPAL},
		{"g([" .. J .. "])", gPAL .. "%1"},
		{"ll([std])", "l%1"},
		{"ll([+" .. Call .. "])", C.t .. C.hl .. "%1"},
		-- other cases of geminates before a consonant simplify; not yet across a component boundary
		-- because of -tt, -ánn, etc.
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
		{"rsks", { -- þorsks
			{replace = C.hr .. C.s, var = {"natural", "careful"}},
			{replace = C.s .. C.k .. C.s, var = {"natural", "careful"}},
			{replace = C.s .. "ː", var = "allegro"},
		}},
		{"rskt",  "(" .. C.hr .. ")" .. C.s .. C.t}, -- gerskt
		-- r?sts needs to precede r[fkp]?st because the latter affects rst, which is part of rsts
		{"rsts", { -- fyrsts
			{replace = C.s .. "ː", var = "allegro"},
			{replace = C.s .. C.t .. C.s, var = {"careful", "natural"}},
		}},	
		{"r[fkp]?st", "(" .. C.hr .. ")" .. C.s .. C.t}, -- horfst; styrkst; skerpst; berst

		-- (d) 3 consonant clusters
		-- (d.1) beginning with <f>
		{"fld", "(" .. C.v .. ")" .. C.l .. C.t}, -- efldi
		{"flt", C.hl .. C.t}, -- teflt
		{"fnd", C.m .. C.t}, -- hefndi; not a mistake, fn mutually assimilates to m
		{"fns", { -- hrafns
			{replace = C.p .. C.hn .. C.s, var = "careful"},
			{replace = C.f .. C.s, var = {"natural", "allegro"}},
		}},
		{"fnt", C.hm .. C.t}, -- jafnt; not a mistake, fn mutually assimilates to m, which is aspirated by the preaspiration of t
		{"fts", C.f .. "(" .. C.t .. ")" .. C.s}, -- lofts
		-- (d.2) beginning with <g> or <k>
		{"gld", C.l .. C.t}, -- sigldi
		{"glt", C.hl .. C.t}, -- siglt
		{"gnd", C.ng .. C.t}, -- rigndi
		{"gns", { -- gagns
			{replace = C.k .. C.hn .. C.s, var = "careful"},
			{replace = C.x .. C.s, var = {"natural", "allegro"}},
		}},
		{"[gk]nt", C.hng .. C.t}, -- hrygnt; sýknt
		{"[gk]ts", C.x .. "(" .. C.t .. ")" .. C.s}, -- gjögts; svekkts
		-- (d.3) beginning with <l>
		{"lds", C.l .. "(" .. C.t .. ")" .. C.s}, -- þvælds
		{"l[fg]d", C.l .. C.t}, -- hvolfdi, fylgdi
		{"lfr", C.l .. "(" .. C.v .. ")" .. C.r}, -- ýlfra
		{"lfs", C.l .. "(" .. C.f .. ")" .. C.s}, -- úlfs
		{"l[fk]t", C.hl .. C.t}, -- tólfti, velktur
		{"lgn", C.l .. C.n}, -- volgna
		{"l([kp])s", { -- fólks; hvolps
			{replace = C.l .. C.s, var = {"natural", "allegro"}},
			{replace = function(kp) return C.hl .. orth_to_unasp_pua_map[kp] .. C.s end, var = "careful"},
		}},
		{"lts", C.hl .. "(" .. C.t .. ")" .. C.s}, -- gyllts
		-- (d.4) beginning with <m>
		{"mbd", C.m .. C.t}, -- rembdist
		{"mbs", C.m .. C.s}, -- lambs
		{"mbt", C.hm .. C.t}, -- kembt
		{"mds", C.m .. "(" .. C.t .. ")" .. C.s}, -- límds
		{"mps", { -- svamps
			{replace = C.hm .. C.p .. C.s, var = "careful"},
			{replace = C.m .. C.s, var = {"natural", "allegro"}},
		}},
		-- (d.5) beginning with <n>
		{"nds", C.n .. "(" .. C.t .. ")" .. C.s}, -- sands
		{"ngd", C.ng .. C.t}, -- hringdi
		{"ngl", C.ng .. C.l}, -- England
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
		{"s([kpt])s", { -- fisks, rasps, prests
			{replace = C.s .. "ː", var = {"natural", "allegro"}},
			{replace = function(kpt) return C.s .. orth_to_unasp_pua_map[kpt] .. C.s end, var = "careful"},
		}},	
		{"skt", C.s .. C.t}, -- frist
		{"stk", C.s .. C.k},
		{"st" .. kPAL, C.s .. C.c}, -- systkin
		-- sts in 4-char section above (due to optional r in rsts)
		-- (d.9) beginning with <t>
		{"tns", C.s .. "ː"}, -- vatns

		-- (3) 2 consonant clusters
		{"ðk", C.th2 .. C.k},                         -- ð devoiced before k → θ
		-- nasal + velar/palatal stop (place + voicing by following segment)
		{"n" .. kPAL, C.hnj .. C.c},                  -- voiceless palatal: banki, þenkja
		{"nk", C.hng .. C.k},                         -- voiceless velar: banka
		{"n" .. gPAL, C.nj .. C.c},                   -- voiced palatal: angi, syngja
		{"ng", C.ng .. C.k},                          -- voiced velar: hanga, langur
		{"lr", C.l .. C.t .. C.r},                    -- elri
		-- geminates and preaspiration; maintain the [kpt] because we may need to convert p -> f later,
		-- as in uppfræða
		{"([" .. Vall .. "])([kpt])%2", "%1" .. C.h .. "%2"}, -- drekka, stoppa, fletta
		-- nn → tn after a tense vowel / diphthong, else n
		{"([" .. Vtense .. "])(ː?)nn", "%1%2" .. C.t .. C.n},
		{"ll", C.t .. C.l},
		-- rr is special and is a long trill (and not devoiced) even word-finally or before a consonant,
		-- e.g. barr, barri, barrtré, kyrrstæður
		{"rr", C.r .. "ː"},
		-- no gemination before consonant across component boundary, as in innbú, rassvasi;
		-- this should go as early as possible, directly after any special handling of written geminates.
		{"([" .. Call .. "])%1#([" .. Call .. "])", "%1#%2"},
		-- hagga, etc.
		{"([bdgfhsþðmnr])%1", function(c) return orth_to_unasp_pua_map[c] .. Solc end},
		-- preaspiration: p/t/k + l/n
		{"([" .. Vall .. "])([kpt])([ln])", function(v, kpt, ln) return v .. C.h .. orth_to_unasp_pua_map[kpt] .. orth_to_unasp_pua_map[ln] end},
		{"kt", C.x .. C.t}, -- rakti → x t
		{"pt", C.f .. C.t}, -- æpti → f t
	})

	------------------------------------------------------------------
	-- Step 3.4a: stops and fricatives across component boundaries
	------------------------------------------------------------------
	w = apply(w, {
		-- kaupfélag, kaupfar, upp fyrir, uppfræða; kaupsýsla, kauptíð, kauptrygging
		{"(ː?)(" .. C.h.. "?p)(#[fs" .. C.th .. "])", {
			{replace = "%1%2%3", var = "formal"},
			{replace = C.f .. "%3", var = "informal"}, -- preceding length shortens and hp -> f
		}},
		-- kaupmaður, kaupmennska, Kaupmannahöfn
		{"(ː?)(p#m)", {			
			{replace = "%1%2"},
			{replace = C.h .. "%2"},
		}},
		-- <d> may drop before <s> across component boundaries
		{"(d)(#s)", "(%1)%2"},
	})

	------------------------------------------------------------------
	-- Step 3.4b: f realizations
	-- should precede devoicing of r before voiceless sounds because
	-- f may get voiced
	------------------------------------------------------------------
	w = apply(w, {
 		-- <f> preceding labial across component boundary; rafmagn
		{"(f#)(m)", {
			{replace = "%1%2", var = "formal"},
			{replace = "%2#%2", var = "informal"},
		}},
 		-- <f> preceding labial across component boundary; afbera, afbragð, ofboðslegur;
		-- use OC.p to prevent [p] from getting deleted across component boundary before another [p]
		{"(f#)(" .. C.p .. ")", {
			{replace = "%1%2", var = "formal"},
			{replace = OC.p .. "#%2", var = "informal"},
		}},
		-- <f> preceding <p> across component boundary; no discussion or examples given, guess that it's similar to -f#b-
		{"(f#)([" .. C.ph .. "])", {
			{replace = "%1%2", var = "formal"},
			{replace = C.p .. "#%2", var = "informal"},
		}},
 		-- [f] preceding [f] and [s] across component boundary; affall, afferma, offita, afskekktur, afstaða, ofsjónir
		{"f(#[fs])", C.f .. "%1"},
		-- Before voiceless fricatives and approximants other than [s], and before aspirated stops, modern [v], older [f]:
		-- afhlúpa, afhrak, afkimi, afkoma, aftaka, raftækni, Riftún, ofhleðsla, ofhvörf, etc.
		{"f(#[" .. COCvoiceless .. "])", {
			{replace = C.v .. "%1", var = "modern"},
			{replace = C.f .. "%1", var = "older"},
		}},
		{"#f", "#" .. C.f},                          -- initial f; should precede handling of -fl-
		{"f([ln])", C.p .. "%1"},                    -- efla, hafna → p
		{"f([st])", C.f .. "%1"},                    -- ofsi, aftur → f
		{"([" .. Vauou .. "]ː?)f([" .. Vall .. "])", "%1(v)%2"},      -- optionally silent after á/ó/ú
		{"f", C.v},                                  -- sofa → v
	})

	----------------------------------------------------------------------
	-- Step 3.4c: devoicing of liquids/nasals before a voiceless consonant
	-- and epenthetic t in [rs][ln]
	----------------------------------------------------------------------
	w = apply(w, {
		-- r becomes voiceless before any aspirated stop or voiceless fricative/approximant,
		-- including across component boundaries
		{"r(#?" .. "[" .. COCvoiceless .. "])", C.hr .. "%1"},
		-- l/m becomes voiceless before an aspirated stop
		{"([lm])([kpt" .. kPAL .. "])", function(lm, kpt) return orth_to_asp_pua_map[lm] .. kpt end},
		-- l becomes voiceless across a component boundary before hl- (jökulhlaup; FIXME: there may be other cases like this)
		{"l(#" .. C.hl .. ")", C.hl .. "%1"},
		{"nt", C.hn .. C.t},                          -- vanta
		-- epenthetic [t] in rl, rn, sl, sn
		{"([rs])([ln])", function(rs, ln) return orth_to_unasp_pua_map[rs] .. C.t .. orth_to_unasp_pua_map[ln] end},
	})

	--------------------------------------------------------------------------
	-- Step 3.4d: dialectal "harðmæli" (intervocalic voiceless stops aspirate)
	--------------------------------------------------------------------------

	if dialect == "north" or dialect == "northeast" then
		-- harðmæli: aspirate non-initial unaspirated stops between a vowel and a
		-- following sonorant (vowel / j / r / v). The optional ː is the length mark.
		w = apply(w, {{"([" .. Vall .. "]ː?)([ptk" .. kPAL .. "])([" .. Vall .. C.v .. "jr])",
			function(v1, stop, son2) return v1 .. orth_to_asp_pua_map[stop] .. son2 end
		}})
	end
	
	------------------------------------------------------------------
	-- Step 3.4e: g and k realizations
	------------------------------------------------------------------
	w = apply(w, {
		-- g
		-- optionally silent after á/ó/ú before a vowel
		{"([" .. Vauou .. "]ː?)g([" .. Vall .. "])", "%1(" .. C.gh .. ")%2"},
		-- optionally silent after á/ó/ú component-finally; needs to lengthen when dropped; lágnætti, skóglendi, drjúgvirkur
		-- note that if before voiceless, the rule below will generate optional [x]
		{"([" .. Vauou .. "])g#", {
			{replace = "%1g#"},
			{replace = "%1ː#"},
		}},
		{"gt", C.x .. "t"},                                        -- sagt: g → x (t kept)
		{"g([ðr])", C.gh .. "%1"},                                 -- sigra, sagði → ɣ
		{"([" .. Vall .. "]ː?)g([" .. Vall .. "])", "%1" .. C.gh .. "%2"},-- saga → ɣ (intervocalic)
		{"([" .. Vall .. "]ː?)g#([" .. COCvoiceless .. "])", {
			{replace = "%1" .. C.x .. "#%2"},
			{replace = "%1" .. C.gh .. "#%2"},
		}},
		{"([" .. Vall .. "]ː?)g#", "%1" .. C.gh .. "#"},             -- lag → ɣ (final after a vowel)
		{"([" .. Vall .. "]ː?)" .. gPAL .. "([" .. Vall .. "])", "%1" .. C.j .. "%2"}, -- hagi → j
		{gPAL, C.c},                                             -- elsewhere palatal g → c
		{"g", C.k},                                              -- elsewhere velar g → k
		-- k
		{kPAL, C.c},                                             -- ríki → c
		{"k", C.k},                                              -- baka → k
	})

	------------------------------------------------------------------
	-- Step 3.4f: remaining single consonants
	------------------------------------------------------------------
	w = apply(w, {
		{"x", C.k .. C.s},                            -- x → ks
		{"([bdptmnlrðþvsjk])", orth_to_unasp_pua_map},
		-- component-final stop + [n]/[l] devoice the sonorant: vopn [vɔhpn̥], magn [makn̥], einn [eitn̥], stjákl [stjauhkl̥]
		{"([" .. unaspirated_stops_pua .. "])([" .. C.n .. C.l .. "])#",
			function(stop, nl) return stop .. devoice_resonant_map[nl] .. "#" end
		},
	})

	--------------------------------------------------------------------------------
	-- Step 3.4g: stop consonants and <s> across component boundaries
	--------------------------------------------------------------------------------
	w = apply(w, {
		-- same-place stop consonants drop across component boundaries
		{"[" .. C.k .. C.kh .. "](#[" .. C.k .. C.kh .. C.c .. C.ch .. "])", "%1"},
		{"[" .. C.p .. C.ph .. "](#[" .. C.p .. C.ph .. "])", "%1"},
		{"[" .. C.t .. C.th .. "](#[" .. C.t .. C.th .. "])", "%1"},
		{C.s .. "(#" .. C.s .. ")", "%1"},
	})

	----------------------------------------------------------------------------------------
	-- Step 3.4h: Northeast Iceland dialect adjustments in resonant + stop (and ðk) clusters
	----------------------------------------------------------------------------------------
	if dialect == "northeast" then
		-- voiced pronunciation: a nasal voices before a stop, and the stop aspirates
		local voiceless_nasals_pua = C.hm .. C.hn .. C.hnj .. C.hng
		w = apply(w, {{"([" .. voiceless_nasals_pua .. "])([" .. unaspirated_stops_pua .. "])",
			function(nv, stop) return voice_resonant_map[nv] .. aspirate_stop_map[stop] end
		}})
		-- l voices (and stop aspirates) before labial/velar stops, but stays
		-- voiceless before t (per doc: piltur, elta keep [l̥t])
		w = apply(w, {{C.hl .. "([" .. C.p .. C.k .. C.c .. "])",
			function(stop) return C.l .. aspirate_stop_map[stop] end
		}})
		-- ð voiced (and following k aspirated) in -ðk-: maðkur [maðkʰʏr]
		w = apply(w, {{C.th2 .. C.k, C.dh .. C.kh}})
	end

	------------------------------------------------------------------
	-- Steps 4–5: detokenize and clean up
	------------------------------------------------------------------
 	-- convert obligatory PUA characters to regular ones before detokenizing
	w = apply(w, {
		{".", OC_to_C},
	})

	-- shorten following vowel directly after a geminate consonant (usually across a component boundary);
	-- FIXME: not clear if this is real due to prevalent typos in Kristján Árnason's book and not being
	-- explicitly discussed, but it's consistent in the book
	w = apply(w, {
		-- across a component boundary; usualy case
		{"ː?([" .. Call .. "])(#%1[" .. Vall .. "])ː", "%1%2"},
		-- geminate precedes the component boundary; can happen with explicit written [:],
		-- as in [[prestsekkja]] written <pres[:]-ekkja>
		{"ː?([" .. Call .. "]ː#[" .. Vall .. "])ː", "%1"},
		-- eliminate _ and + markers before syllabification
		{"[_+]", ""},
	})

	-- determine secondary stresses and mark other component boundaries with .
	for _, word in ipairs(w) do
		local components = split(word.output, "(#+)")
		local syllables_since_stress
		for i = 3, #components - 2, 2 do
			if not syllables_since_stress then
				components[i - 1] = "ˈ"
				syllables_since_stress = 0
			elseif syllables_since_stress >= 2 then
				components[i - 1] = "ˌ"
				syllables_since_stress = 0
			end
			local syllabified_word = syllabify(components[i])
			local syllables = split(syllabified_word, "%.")
			-- We may need to give secondary stress to syllables within a component if the component has more than
			-- two syllables. We need to give alternating stresses and can stress the final syllable only in the
			-- last component of the word.
			if #syllables >= 3 then
				if i > 3 then
					components[i - 1] = "ˌ"
				end
				local first_secstress_syllable = 3
				local last_secstress_syllable = i == #components - 2 and #syllables or #syllables - 1
				if first_secstress_syllable <= last_secstress_syllable then
					for j = first_secstress_syllable, last_secstress_syllable, 2 do
						if not disable_internal_stresses then
							syllables[j] = resolve_optional_consonant_gemination(syllables[j], syllables[j - 1])
							syllables[j] = "ˌ" .. syllables[j]
						end
						syllables_since_stress = #syllables - j + 1
					end
				else
					syllables_since_stress = #syllables
				end
			else
				if syllables_since_stress > 0 then
					components[i - 1] = "."
				end
				syllables_since_stress = syllables_since_stress + #syllables
			end
			-- Concatenate, including any added secondary stress marks but removing dots marking other syllable
			-- boundaries.
			components[i] = concat(syllables)
		end
		components[#components - 1] = "" -- erase word-final ##
		word.output = concat(components)
	end

	w = apply(w, {
		-- convert regular PUA characters to IPA
		{".", detok},
	})
	return w
end


local function toIPA_word(word, dialect, disable_internal_stresses)
	word = word:gsub("%[(.-)%]", bracketed_phone_map)
	word = ugsub(word, "[ăĕĭŏŭ]", decompose_breve_map)
	word = word:gsub("([ln])%1:", "%1" .. Solc)
	-- Handle epenthetic [j] in hiatus after a high front vowel or glide
	word = word:gsub("(e[iy])([aiu])", "%1j%2")
	word = ugsub(word, "([íýæ])([aiu])", "%1j%2")
	local components = split(word, "[-‿]")
	for i, component in ipairs(components) do
		component = mw.ustring.lower(component)
		components[i] = determine_vowel_length(i, component, components[i + 1])
	end
	word = "##" .. concat(components, "#") .. "##"
	return convert({{output = word, levels_by_class = {}}}, dialect, disable_internal_stresses)
end


-- Given a single substitution spec, `to`, figure out the corresponding value of `from` used in a complete
-- substitution spec. `pagename` is the name of the page, either the actual one or taken from the `pagename` param.
-- `whole_word`, if set, indicates that the match must be to a whole word (it was preceded by ~).
local function convert_single_substitution_to_original(to, pagename, whole_word)
	-- Replace specially-handled characters with a class matching the character and possible replacements.
	local escaped_from = to
	escaped_from = escaped_from:gsub("[._:+]", "")
	escaped_from = pattern_escape(escaped_from)
	-- This is tricky, because we already passed `escaped_from` through pattern_escape() causing a hyphen or paren
	-- to get a % sign before it, and have to double up the percent signs to match and replace a literal %.
	escaped_from = escaped_from:gsub("%%([-()])", "%%%1?")
	-- Tie sign (‿) should match against space or hyphen in the original.
	escaped_from = escaped_from:gsub("‿", "[ %%-]")
	-- ŋ and ɲ match n in original.
	escaped_from = escaped_from:gsub("ŋ", "n")
	escaped_from = escaped_from:gsub("ɲ", "n")
	-- Letters with breve match the corresponding letters without breve.
	escaped_from = toNFC((toNFD(escaped_from):gsub(BREVE, "")))
	escaped_from = "(" .. escaped_from .. ")"
	if whole_word then
		escaped_from = "%f[%a]" .. escaped_from .. "%f[%A]"
	end
	local match = umatch(pagename, escaped_from)
	if match then
		if match == to then
			error(("Single substitution spec '%s' found in pagename '%s', replacement would have no effect"):
				format(to, pagename))
		end
		return match
	end
	error(("Single substitution spec '%s' couldn't be matched to pagename '%s'"):format(to, pagename))
end


local function apply_substitution_spec(respelling, pagename)
	local orig_respelling = respelling
	local subs = split_on_comma(respelling:match("^%[(.*)%]$"))
	respelling = pagename

	local function parse_err(txt)
		error(("%s: original substitution spec %s, pagename '%s'"):format(txt, orig_respelling, pagename))
	end

	for _, sub in ipairs(subs) do
		local from, escaped_from, to, escaped_to, whole_word
		if sub:find("^~") then
			-- whole-word match
			sub = sub:match("^~(.*)$")
			whole_word = true
		end
		if sub:find(":.") then
			from, to = sub:match("^(.-):(.+)$")
		else
			to = sub
			from = convert_single_substitution_to_original(to, pagename, whole_word)
		end
		if from then
			escaped_from = pattern_escape(from)
			if whole_word then
				escaped_from = "%f[%a]" .. escaped_from .. "%f[%A]"
			end
			escaped_to = replacement_escape(to)
			local subbed_respelling, nsubs = ugsub(respelling, escaped_from, escaped_to)
			if nsubs == 0 then
				parse_err(("Substitution spec %s -> %s didn't match processed pagename '%s'"):format(
					from, to, respelling))
			elseif nsubs > 1 then
				parse_err(("Substitution spec %s -> %s matched multiple substrings in processed pagename '%s', add " ..
					"more context"):format(from, to, respelling))
			else
				respelling = subbed_respelling
			end
		end
	end

	return respelling
end


local function handle_substitution_specs(text, pagename)
	if text == "+" then
		return pagename
	elseif text:find("^%[.*%]$") then
		-- Check that there is a single bracketed expression; otherwise it's vaguely possible that there are
		-- two [C] literals, one at the beginning and one at the end.
		local put = require(parse_utilities_module)
		local segments = put.parse_balanced_segment_run(text, "[", "]")
		if #segments > 3 then
			return text
		end
		return apply_substitution_spec(segments[2], pagename)
	else
		return text
	end
end


function export.toIPA(text, dialect, pagename, disable_internal_stresses)
	local orig_respelling_spec = text
	pagename = pagename or mw.loadData("Module:headword/data").pagename
	text = handle_substitution_specs(text, pagename)
	local words = split(text, "%s+")
	local all_word_pronuns = {{output = "", levels_by_class = {}}}
	for _, word in ipairs(words) do
		local this_word_pronuns = toIPA_word(word, dialect, disable_internal_stresses)
		local function concatenate(word1, word2)
			if word1 == "" then
				return word2
			else
				return word1 .. " " .. word2
			end
		end
		all_word_pronuns = concatenate_horizontally(all_word_pronuns, this_word_pronuns, concatenate)
	end
	for i, pronun in ipairs(all_word_pronuns) do
		local sortkey_parts = {}
		local classes_and_priorities = {}
		for class, classprops in pairs(variation_classes) do
			insert(classes_and_priorities, {class, classprops.priority})
		end
		-- sort classes and levels by priority
		table.sort(classes_and_priorities, function(a, b) return a[2] < b[2] end)
		for _, class_and_priority in ipairs(classes_and_priorities) do
			local class, _ = unpack(class_and_priority)
			local class_levels = pronun.levels_by_class[class]
			if not class_levels then
				insert(sortkey_parts, ("%03d"):format(#variation_classes[class].levels + 1))
			else
				local level_priorities = {}
				for level, _ in pairs(class_levels) do
					insert(level_priorities, ("%03d"):format(variation_to_properties[level].priority))
				end
				table.sort(level_priorities)
				insert(sortkey_parts, concat(level_priorities))
			end
		end
		pronun.sortkey = concat(sortkey_parts)
	end
	table.sort(all_word_pronuns, function(a, b) return a.sortkey < b.sortkey end)
	for i, pronun in ipairs(all_word_pronuns) do
		all_word_pronuns[i] = {
			pron = pronun.output,
			qq = levels_by_class_to_qualifiers(pronun.levels_by_class),
		}
	end
	return {
		orig_respelling = orig_respelling_spec,
		respelling = text,
		pagename = pagename,
		pronuns = all_word_pronuns,
	}
end	

local function ine(arg)
	return arg ~= "" and arg or nil
end

function export.toIPA_bot(frame)
	local respelling, dialect, pagename, disable_internal_stresses = ine(frame.args[1]), ine(frame.args[2]), ine(frame.args[3]), ine(frame.args[4])
	local data = export.toIPA(respelling, dialect, pagename, disable_internal_stresses)
	return require("Module:JSON").toJSON(data)
end

function export.toIPA_bot_multiple(frame)
	-- First argument should always be given.
	local respellings, dialect, pagename, disable_internal_stresses = frame.args[1], ine(frame.args[2]), ine(frame.args[3]), ine(frame.args[4])
	respellings = split(respellings, "!!")
	local all_data = {}
	for _, respelling in ipairs(respellings) do
		insert(all_data, export.toIPA(respelling, dialect, pagename, disable_internal_stresses))
	end
	return require("Module:JSON").toJSON(all_data)
end

local function respelling_to_IPA(data)
	local pronuns = export.toIPA(data.respelling, nil, data.pagename).pronuns
	for _, pronun in ipairs(pronuns) do
		pronun.pron = "[" .. pronun.pron .. "]"
	end
	return pronuns
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
