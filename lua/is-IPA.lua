local export = {}

local lang = require("Module:languages").getByCode("is")

local parse_utilities_module = "Module:parse utilities"
local pron_utilities_module = "Module:pron utilities"
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")

local ugsub = m_string_utilities.gsub
local usub = m_string_utilities.sub
local ufind = m_string_utilities.find
local umatch = m_string_utilities.match
local ulower = m_string_utilities.lower
local pattern_escape = m_string_utilities.pattern_escape
local replacement_escape = m_string_utilities.replacement_escape
local toNFC = mw.ustring.toNFC
local toNFD = mw.ustring.toNFD
local u = m_string_utilities.char
local codepoint = mw.ustring.codepoint
local split = m_string_utilities.split
local concat = table.concat
local insert = table.insert
local listToSet = m_table.listToSet
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
	xw = pua(17), -- xʷ
	h = pua(18), -- h
	m = pua(19), -- m 
	hm = pua(20), -- m̥
	n = pua(21), -- n
	hn = pua(22), -- n̥
	nj = pua(23), -- ɲ
	hnj = pua(24), -- ɲ̊
	ng = pua(25), -- ŋ
	hng = pua(26), -- ŋ̊
	l = pua(27), -- l
	hl = pua(28), -- l̥
	r = pua(29), -- r
	hr = pua(30), -- r̥
}

local kPAL, gPAL        = pua(40), pua(41) -- Palatalization markers: k/g immediately before a J-set segment

-- Suprasegmental tokens
local Solc              = pua(50)          -- optional long after a consonant
local Soblc             = pua(51)          -- obligatory long after a consonant

local Cfirst, Clast     = pua(0), pua(99)

-- Obligatory copies of all consonants; they are separate so they aren't affected by most rules
local OC = {}
-- Map from obligatory PUA characters to regular PUA chars
local OC_to_C = {}

local OSoblc            = pua(151)

for phone, pua_char in pairs(C) do
	local obl_pua_char = u(100 + codepoint(pua_char))
	OC[phone] = obl_pua_char
end
for pua_codepoint = codepoint(Cfirst), codepoint(Clast) do
	local obl_pua_char = u(100 + pua_codepoint)
	OC_to_C[obl_pua_char] = u(pua_codepoint)
end

local OCfirst, OClast     = pua(100), pua(199)

-- Vowel tokens
local Va, Vai, Vau      = pua(200), pua(201), pua(202)       -- a ai au
local Ve                = pua(203)                           -- ɛ; no jɛ because we replaced <é> -> <je> early on
local Vi, Vii           = pua(204), pua(205)                 -- ɪ i
local Vo, Vou           = pua(206), pua(207)                 -- ɔ ou
local Vu, Vuu           = pua(208), pua(209)                 -- ʏ u
local Voe, Voei         = pua(210), pua(211)                 -- œ œi
local Vei, Voi, Vui     = pua(212), pua(213), pua(214)       -- ei ɔi ʏi
local Vai_gi            = pua(215)                           -- ai (from a before -gi; NOT in J-set)

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
local orth_velar_stop_to_palatal_pua_map = {g = C.c, k = C.ch}
local orth_velar_stop_to_special_palatal_pua_map = {g = gPAL, k = kPAL}

local bracketed_phone_map = {
	f = OC.f,
	s = OC.s,
	x = OC.x,
	xw = OC.xw,
	kh = OC.kh,
	k = OC.k,
	th = OC.th,
	t = OC.t,
	ph = OC.ph,
	p = OC.p,
	ch = OC.ch,
	c = OC.c,
	[":"] = OSoblc,
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
	[C.s] = "s", [C.j] = "j", [C.hj] = "ç", [C.gh] = "ɣ", [C.x] = "x", [C.xw] = "xʷ", [C.h] = "h",
	[C.m] = "m", [C.hm] = "m̥", [C.n] = "n", [C.hn] = "n̥",
	[C.nj] = "ɲ", [C.hnj] = "ɲ̊", [C.ng] = "ŋ", [C.hng] = "ŋ̊",
	[C.l] = "l", [C.hl] = "l̥", [C.r] = "r", [C.hr] = "r̥",
	[Va] = "a", [Vai] = "ai", [Vau] = "au", [Ve] = "ɛ",
	[Vi] = "ɪ", [Vii] = "i", [Vo] = "ɔ", [Vou] = "ou", [Vu] = "ʏ", [Vuu] = "u",
	[Voe] = "œ", [Voei] = "œi", [Vei] = "ei", [Voi] = "ɔi", [Vui] = "ʏi",
	[Vai_gi] = "ai",
	-- [Solc] = "(ː)", don't convert Solc yet so we can eliminate it before a consonant in the next word
	[Soblc] = "ː",
	[kPAL] = "c", [gPAL] = "j",  -- fallback only; normally resolved before detok
}

-- Character-class fragments (contents of a [ .. .] set)
local Call_pua = Cfirst .. "-" .. Clast
-- allow explicit use of certain IPA consonants in respelling; ŋ and ɲ don't trigger diphthongization
local Cipa_not_orth = "ŋɲcçɣθ"
local Call = Call_pua .. Call_orth .. Cipa_not_orth
local OCall = OCfirst .. "-" .. OClast
local COCall = Call .. OCall
-- We need to include obligatory PUA characters to handle bracketed characters, which we map directly to PUA characters
-- before vowel length determination.
local consonant_set = explode_to_set(COCall)
local Vall_pua = Vfirst .. "-" .. Vlast
local Vall = Vall_pua .. Vall_orth
local vowel_set = explode_to_set(Vall)
local Vfront = concat {Vi, Vii, Ve, Vai, Vei}  -- J vowels (front unrounded + æ + ei/ey)
local J = Vfront .. "j"                                     -- J-set incl. orthographic j
local Vauou = concat {Vau, Vou, Vuu}                -- á ó ú (for silent g)
local Vtense = concat {Vau, Vou, Vuu, Vii, Vai, Voei, Vei}  -- á í/ý ó ú æ au ei/ey (nn → tn)
-- Aspirated stop or voiceless fricative or approximant; triggers devoicing e.g. of preceding /r/;
-- C.h should not be present
local Cvoiceless_pua = concat {C.ph, C.th, C.ch, C.kh, kPAL, C.s, C.f, C.th2, C.x, C.xw,
							   C.hj, C.hn, C.hnj, C.hng, C.hm, C.hl, C.hr}
-- "Voiceless" obligatory PUA characters should still trigger devoicing. No equivalent of kPAL,
-- which is generated secondarily..
local OCvoiceless_pua = concat {OC.ph, OC.th, OC.ch, OC.kh, OC.s, OC.f, OC.th2, OC.x, OC.xw,
							   OC.hj, OC.hn, OC.hnj, OC.hng, OC.hm, OC.hl, OC.hr}
-- We have to assume that at the point Cvoiceless is used, clusters like hj have been to PUA characters.
local Cvoiceless_orth = "ptksfþ"
local Cvoiceless = Cvoiceless_pua .. Cvoiceless_orth .. "ç"
local COCvoiceless = Cvoiceless .. OCvoiceless_pua

local unstressed_words = listToSet {
	-- monosyllabic prepositions from https://ritmalssafn.arnastofnun.is/leit//ordflokkur/prep
	-- NOTE: many can function as stressed adverbs and will need explicit stress
	-- also, some can function as unrelated words, e.g. á "river", gegn "respectable; worthy", úr "watch"
	"að", "af", "auk", "á", "án", "frá", "gegn", "gegnt", "hjá", "í", "með", "til", "um", "úr", "við",
	-- not included despite being listed as monosyllabic prepositions:
	-- 1. "bak" (mostly an adverb or noun "back")
	-- 2. "bland" (mostly a noun "blend")
	-- 3. "for" (a noun "mud"; a prefix for-, not a preposition)
	-- 4. "fur" (obsolete?)
	-- 5. "inn" (mostly a stressed adverb "in")
	-- 6. "kring" (?)
	-- 7. "mót" ("meeting; mo(u)ld; junction"; only a function word in the expression [[á móti]] "opposite",
	--    [[í móti]] and <mót jólum> "just before Christmas"
	-- 8. "nær" (an adverb "nearer")
	-- 9. "of" (an adverb "too", seemingly stressed)
	-- 10. "per" (?)
	-- 11. "po" (?)
	-- 12. "und" (mostly a noun "wound"; presumably an obsolete preposition "under")
	-- 13. "út" (an adverb "out"; appears as a preposition in "út af", "út að", etc.)
	-- conjunctions
	"alls", "ef", "en", "er", "eð", "eða", "fyrst", "hvert", "hvort",
	"né", "nær", "og", "sem", "uns", "þar", "þá", "þótt",
	-- verbal forms
	-- should we omit the 2nd person forms? should we omit sé which also means "(I) see"?
	"ert", "var", "varst", "sé", "sért",
	-- personal pronouns
	"ég", "mig", "mér", "mín",
	"þú", "þig", "þér", "þín",
	"sig", "sér", "sín",
	"hann", "hans", -- honum
	"hún", -- hana, henni, hennar
	"það", "því", "þess",
	"þeir", "þá", "þær", "þau", "þeim", -- þeirra
	-- other possibilities:
	-- 1. sá "the" (but also stressed "to sow", "(I/he/she/it) saw"), and forms
	-- 2. multistressed forms of the article, e.g þeirra, þeirri
}


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
			if m_table.size(union) == #variation_classes[class].levels then
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


-- Apply an ordered list of {pattern, replacement} substitutions. The pattern is always a string, but it may contain !
-- as a shorthand for a (sub)component boundary; !! as a shorthand for a (sub)component boundary or a primary stress
-- internal to the subcomponent (after which <p>, <t> and <k> are aspirated; <f> voiceless; and <g> a stop); or @ as a
-- shorthand for an explicit secondary stress. Note that, since !, !! and @ may match multiple characters, they should
-- always be contained within groups (i.e. inside of parens), with appropriate group references in the replacement. The
-- replacement can either be a string (for a single output) or a list of multiple possible outputs, each of which is a
-- table containing fields `replace` (the replacement string itself) and `var` (the variant or variants describing the
-- register, formality, etc.; either a string specifying a single variant, or a list of variants).
local function apply(w, rules)
	local outw = w
	for _, rule in ipairs(rules) do
		if type(rule) ~= "table" then
			error("Expected rule to be a table but saw " .. dump(rule))
		end
		local from = rule[1]:gsub("!!", "[#\1-\3]+"):gsub("!", "#[#\1-\3]*"):gsub("@", "[\4]?")
		if type(rule[2]) == "string" or type(rule[2]) == "function" or type(rule[2]) == "table" and not rule[2][1] then
			local to = rule[2]
			-- a simple rule; apply to each output
			if #outw == 1 then
				outw[1].output = ugsub(outw[1].output, from, to)
			else
				local newoutw = {}
				for i = 1, #outw do
					local newpron = {
						output = ugsub(outw[i].output, from, to),
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
							output = ugsub(outw[i].output, from, rulespec.replace),
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


-- Determine the stressed syllable, if any, of each high-level component in the word (high-level components are
-- separated by --). Mark primary stress using \1 = ^A (not the primary stress symbol ˈ so that Lua patterns using it
-- can use the regular, much-faster pattern matching in place of the PHP versions), and convert any explicitly
-- user-specified primary stress using the IPA symbol ˈ to \1. Mark word-initial or high-level-component-initial
-- secondary stress using \2, and convert any initial user-specified secondary-stress using IPA ˌ to \2; this is assumed
-- to apply to the entire component. If the user included explicit non-initial secondary stress using IPA ˌ, convert to
-- \4; this doesn't prevent assignment of component-level stress. The user can explicitly prevent adding
-- component-initial stress either by putting the primary stress mark elsewhere or adding a period (.) at the beginning
-- of any component or subcomponent (which we convert to \3).
-- 
-- With multiple components, if any word has primary stress in it, all remaining components not specifically marked for
-- stress (either using a primary stress anywhere in the word, initial secondary stress or initial period to indicate
-- lack of stress) get marked with initial secondary stress (\2). Otherwise, the first word not specifically marked for
-- stress gets primary stress (\1) and the remainder not specifically marked for stress get secondary stress. If
-- there's only one component (as in most cases), we don't handle it specially here, but we do elsewhere in
-- determine_secondary_stresses(); subcomponent boundaries (marked with single hyphen, i.e. -) can get secondary stress
-- as well as (in some cases) syllables internal to a subcomponent. When there are multiple high-level components,
-- subcomponent boundaries not explicitly marked with a stress indicator always get a period separator, and internal
-- syllables never get marked.
local function mark_stress(word)
	word = word:gsub("ˈ", "\1"):gsub("^ˌ", "\2"):gsub("%-ˌ", "-\2"):gsub("^%.", "\3"):gsub("%-%.", "-\3")
		:gsub("ˌ", "\4")
	local components = split(word, "%-%-")
	local component_has_primary_stress = false
	for i, component in ipairs(components) do
		if component:find("\1") then
			component_has_primary_stress = true
		end
	end
	for i, component in ipairs(components) do
		if i == 1 and unstressed_words[word] then
			component = "\3" .. component
		elseif component:find("\1") or component:find("^[\2\3]") then
			-- Do nothing; either primary stress (anywhere in the component) or secondary stress mark or no-stress mark
			-- at the beginning of the component (it can also be at the beginning of a non-initial subcomponent, which
			-- doesn't negate the need to put stress at the beginning of the component).
		elseif component_has_primary_stress or i > 1 then
			component = "\2" .. component
		else
			component = "\1" .. component
		end
		-- Convert subcomponent (hyphen) boundaries to #.
		-- FIXME: Currently we are treating the tie bar (‿) the same; we should distinguish hyphen and tie bar,
		-- maybe by making the tie bar not be considered a subcomponent boundary for the purposes of assigning
		-- secondary stress.
		components[i] = component:gsub("%-", "#"):gsub("‿", "#")
	end

	-- High-level component boundaries get marked with ##, as do word edges.
	return "##" .. concat(components, "##") .. "##"
end


-- Mark vowel length on vowel nuclei of syllables with primary stress and subcomponent-initial secondary stress.
--
-- Long if: 0 or 1 consonant follows (before next vowel or subcomponent end).
-- Short if: 2+ consonants follow (cluster or geminate), unless the cluster is
--   one of the transparent clusters ptksbd + vjr (e.g. pr, kr, tv, tj, kv, br, dr).
-- x counts as 2 consonants (represents /ks/).
-- Always short before the sequence -gi-/-j-/-gj- (diphthongization environment) except for í and ý, and
-- not in the south and south-rounded dialect.
--
-- In a compound, the same rules apply to the last subcomponent, but otherwise a
-- stressed syllable in a single-syllable subcomponent is lengthened only when either
-- the subcomponent ends in a vowel, the next subcomponent begins with a vowel or h + vowel,
-- or the subcomponent ends in a single written <p>, <t>, <k> or <s>.
local function determine_vowel_length(subcomponent, next_subcomponent, dialect)
	local chars = explode_to_list(subcomponent)
	local n = #chars
	local result = {}
	-- The initial syllable is stressed unless (a) the subcomponent is explicitly marked for no stress or (b) there's
	-- a primary stress anywhere in the subcomponent. In the case of (b), whichever syllable is marked for primary
	-- stress will get stressed (usually the initial syllable).
	local syllable_stressed = not subcomponent:find("^\3") and not subcomponent:find("\1")
	local i = 1

	while i <= n do
		local c = chars[i]

		if c == "\1" then
			-- primary stress (anywhere in the subcomponent) or subcomponent-initial secondary stress
			-- (other secondary stresses are marked with \4)
			syllable_stressed = true
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
				local long = false
				local j = i + nlen  -- index of first character after the nucleus
				if chars[j] == BREVE then
					nlen = nlen + 1
				elseif syllable_stressed then
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
	
					-- -gi-/-gj-/-j- special case: vowel (other than <í>/<ý>) is always short (and diphthongized) before
					-- <gi>, <gj> and <j>, but <í>/<ý> is long (including before -gj-);
					-- it's ok if j > n in chars[j + 1], we just get nil
					local before_gi = c1 == "j" or c1 == "g" and (chars[j + 1] == "i" or chars[j + 1] == "j")
	
					-- At this point, j is the index of the first character after the stressed vowel
					-- nucleus, and k is the index of the first character after any consonant cluster
					-- following the vowel nucleus. Either may be > n (the number of characters in the
					-- subcomponent).
					if next_subcomponent and k > n then
						-- Non-final subcomponent, single-syllable subcomponent.
						if count == 0 then
							long = true -- subcomponent ends in a vowel
						elseif count == 1 and ptks[c1] then
							long = true -- ends in a single orthographic <p>, <t>, <k>, <s>, <b> or <d>
						elseif count == 1 then
							local first_next = usub(next_subcomponent, 1, 1)
							local second_next = usub(next_subcomponent, 2, 2)
							if vowel_set[first_next] or first_next == "h" and vowel_set[second_next] then
								-- next subcomponent begins with a vowel or h + vowel (<hé> doesn't count but has
								-- already been transformed to <hje>)
								long = true
							else
								long = false
							end
						else
							long = false
						end
					else
						if before_gi then
							long = nucleus == "í" or nucleus == "ý" or dialect == "south" or dialect == "south-rounded"
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
				syllable_stressed = false
			else
				insert(result, c)
				i = i + 1
			end
		end
	end

	return concat(result)
end

-- Syllabify a word composed of phones (not letters) by adding a period (.) between each syllable. Respect periods and
-- primary/secondary stress markers that may already be present, added in the respelling or during mark_stress().
local function syllabify(word)
	-- Assume any unknown character is a consonant. "Vowels" are only those in the Vall range as well as any following
	-- ː, possibly in parens. The algorithm for placing the syllable divider is that it goes to the left of a rightmost
	-- ptks+vjr cluster, otherwise to the left of the rightmost consonant.
	local clusters = split(word, "([" .. Vall .. "][ː()]*)")
	for i = 3, #clusters - 2, 2 do
		local cluster = clusters[i]
		if not cluster:find("[.\1-\4]") then
			-- Check for the case where the user put an explicit syllable boundary or primary stress.
			-- Note that we're operating on phones here, not letters, so kj will have already been converted to C.c,
			-- but that is fine because it gets treated as a single phone.
			cluster = ugsub(cluster, "^(.-)(%(?[" .. C.p .. C.t .. C.k .. C.s .. "]%)?%(?[" .. C.v .. C.j .. C.r .. "]%)?)$", "%1.%2")
		end
		if not cluster:find("[.\1-\4]") then
			-- ptks+vjr not found
			cluster = ugsub(cluster, "^(.-)(%(?.%)?)$", "%1.%2")
		end
		if not cluster:find("[.\1-\4]") then
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

-- Determine secondary stresses for a single output of a word. This does not operate when there are multiple
-- high-level components; in that case we use a simpler algorithm.
local function determine_single_output_secondary_stresses(output, disable_internal_stresses)
	local subcomponents = split(output, "#+")
	-- At the beginning of processing a subcomponent, this tells how many syllables were previously processed after the
	-- last stress mark. It will always be at least 1 except for when processing the first component, in which case it
	-- will be nil.
	local syllables_since_stress
	-- Loop over all subcomponents. Since the word begins and ends with ##, the first and last subcomponents are blank.
	for i = 2, #subcomponents - 1 do
		local subcomponent = subcomponents[i]
		local syllabified_subcomponent = syllabify(subcomponent)
		local syllables = split(syllabified_subcomponent, "([.\1-\4])")
		if syllables[1] ~= "" then
			-- Subcomponent doesn't begin with explicit stress; move the first syllable to position 3 to align
			-- this case with the one where the subcomponent does begin with explicit stress.
			insert(syllables, 1, "")
			insert(syllables, 1, "")
		end
		-- Eliminate all dots indicating syllable boundaries.
		for j = 3, #syllables, 2 do
			if syllables[j - 1] == "." then
				syllables[j - 1] = ""
			end
		end
		local num_syllables = (#syllables - 1) / 2 -- actual number of syllables in subcomponent
		if num_syllables < 3 then
			-- One or two actual syllables in subcomponent. We only need to determine whether to put, at subcomponent
			-- beginning, either secondary stress, no stress (.), or nothing at all (if explcit stress is already
			-- present). We will never place internal stress if it isn't already there.
			if syllables[4] and syllables[4] ~= "" then
				-- Two-syllable subcomponent with explicit stress on second syllable.
				if syllables_since_stress and syllables[2] == "" then
					-- A stress can't directly precede another, so give non-initial components a component boundary
					-- marker unless there's an explicit stress already.
					syllables[2] = "."
				end
				-- When we process the next subcomponent, its first syllable will be following a stressed syllable.
				syllables_since_stress = 1
			elseif not syllables_since_stress then
				-- Beginning of word; note that we've already marked primary stress in words that need it. (If there
				-- isn't primary stress, it means the user explicitly either put primary or secondary stress on a later
				-- syllable, put secondary stress on the first syllable, or put a dot (= no stress) on the first
				-- syllable.
				syllables_since_stress = num_syllables
			elseif syllables[2] ~= "" then
				-- subcomponent already has explicit initial stress. Since the subcomponent has at most two syllables, we
				-- don't need to put any non-initial secondary stress.
				syllables_since_stress = num_syllables
			elseif not syllables[4] and i < #subcomponents - 1 and subcomponents[i + 1]:find("^[\1-\3]") then
				-- One-syllable subcomponent with explicit stress at beginning of next subcomponent.
				syllables[2] = "."
				-- It doesn't in fact matter what we put here because the code that processes the next subcomponent will
				-- see the initial stress and reset `syllables_since_stress`.
				syllables_since_stress = syllables_since_stress + 1
			else
				if syllables_since_stress >= 2 then
					-- Preceding stress was two or more syllables before us and there's not a directly following
					-- explicit stress, so we put a secondary stress.
					syllables[2] = "\2"
					syllables_since_stress = num_syllables
				else
					syllables[2] = "."
					syllables_since_stress = syllables_since_stress + num_syllables
				end
			end
		else
			-- Three or more syllables. Unlike with one or two syllable subcomponents, we always place a stress at the
			-- beginning of the subcomponent (unless there is explicit stress on the first or second syllable). We also
			-- place alternating stresses after each stress (i.e. 2, 4, ... syllables after a stressed syllable),
			-- subject to the provisos that we can't stress the final syllable of a subcomponent, nor (more generally)
			-- any syllable where the next syllable has primary or secondary stress. (In fact, the last subcomponent
			-- of the last syllable of a word can be stress if it's not an inflectional syllable, as in [[september]],
			-- [[kabarett]] or [[Aristóteles]], but it's difficult to automatically distinguish them from the more
			-- common case of inflectional final syllables, so we require that such syllables be marked manually.) In
			-- the following, keep in mind that the actual syllables are at odd numbered positions starting with 3.
			-- Position 1 should always be a blank string and even numbered positions are the primary or secondary
			-- stress markers (\1, \2 or \4), no-stress markers (\3) or syllable boundary markers (.) before the actual
			-- syllables. This means we need to divide syllable positions by 2 (after subtracting 1 to account for the
			-- initial blank syllable) to get the actual number of syllables.
			local preceding_syllable_stressed = false
			if not syllables_since_stress then
				syllables_since_stress = 0
			end
			for j = 3, #syllables - 2, 2 do -- skip the last syllable since we can't give it a stress
				if syllables[j - 1] ~= "" then
					-- explicit stress (or no-stress marker) on this syllable
					preceding_syllable_stressed = true
					syllables_since_stress = 1
				elseif preceding_syllable_stressed then
					preceding_syllable_stressed = false
					syllables_since_stress = syllables_since_stress + 1
				elseif syllables[j + 1] ~= "" then
					-- next syllable stressed, can't stress this one
					syllables_since_stress = syllables_since_stress + 1
				else
					if not disable_internal_stresses then
						syllables[j] = resolve_optional_consonant_gemination(syllables[j], syllables[j - 2])
						-- \2 vs. \4 doesn't matter at this point, since we're about to convert both to IPA secondary stress
						syllables[j - 1] = "\2"
					end
					preceding_syllable_stressed = true
					syllables_since_stress = 1
				end
			end
			if syllables[#syllables - 1] ~= "" then
				-- explicit user stress on final syllable
				syllables_since_stress = 1
			else
				syllables_since_stress = syllables_since_stress + 1
			end
			if i > 2 and syllables[2] == "" then
				-- first syllable of non-initial subcomponent and it doesn't have a stress; add . for subcomponent
				-- boundary
				syllables[2] = "."
			end
		end
		-- Concatenate, including any added secondary stress marks but removing dots marking other syllable
		-- boundaries.
		subcomponents[i] = concat(syllables)
	end
	subcomponents[1] = "" -- erase word-initial ##
	subcomponents[#subcomponents] = "" -- erase word-final ##
	return concat(subcomponents)
end

	
-- Determine secondary stresses and mark other (sub)component boundaries with a period (.).
local function determine_secondary_stresses(w, disable_internal_stresses)
	for _, word in ipairs(w) do
		local output = word.output
		if output:find(".##.") then
			-- Word has multiple high-level components. We already marked primary and secondary stress using \1 and \2
			-- in mark_stress(). We simple mark component and subcomponent boundaries with . unless it's already marked
			-- with \1 (primary stress), \2 (secondary stress), \4 (user-specified secondary stress in the middle of
			-- a word; we normally shouldn't see this after a period) or \3 (no stress).
			output = output:sub(3, #output - 2) -- remove initial and final ##
			output = output:gsub("#+", "."):gsub("%.([\1-\4])", "%1")
		else
			output = determine_single_output_secondary_stresses(output, disable_internal_stresses)
		end
		word.output = output:gsub("\1", "ˈ"):gsub("[\2\4]", "ˌ"):gsub("\3", "")
	end
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
-- word, hyphens marking (sub)component boundaries have been converted to #, and length marks have been added after long
-- vowels per determine_vowel_length(). On output, there may be multiple pronunciations, where the `output` field
-- of each pronunciation is in IPA and the `levels_by_class` table is filled in (if a particular class is missing in the
-- `levels_by_class` table, it means that all possible levels apply). `dialect` specifies the dialect to generate the
-- pronunciation of, and can be either "north", "northeast", "south", "south-rounded" or nil for the standard dialect.
-- `disable_internal_stresses` is used by bots that convert raw IPA to respelling and causes stresses in the middle of a
-- (sub)component of 3 or more syllables to be omitted.
local function convert(w, dialect, disable_internal_stresses)
	local orig_respelling = w[1].output -- for debugging purposes

	------------------------------------------------------------------
	-- Step 3.0: some special cases
	------------------------------------------------------------------
	w = apply(w, {
		{"(!)gu(ː?)ð", "%1gvu%2ð"},-- special case for guð-, Guð-
	})

	------------------------------------------------------------------
	-- Step 3.1: vowels → tokens
	------------------------------------------------------------------
	w = apply(w, {
		-- A1: digraphs (longest first)
		{"au", Voei}, {"ei", Vei}, {"ey", Vei},
		-- A2: monophthong diphthongized + shortened before -gi, -gj; won't happen in southern dialects due to lengthening
		{"([" .. lax_vowels .. "])(g[ij])", function(v, gij)
			return (lax_back_vowel_front_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. gij
		end},
		-- A3: monophthong diphthongized before ng / nk; this must precede all consonant assimilations because
		-- even if the [ŋ] ends up disappearing or transforming to [n] (e.g. in <punktur> pʰun̥tʏr, with tensed vowel
		-- despite the [ŋ] disappearing), or an [ŋ] appears that wasn't originally present (e.g. in <hrygnt> [r̥ɪŋ̊t],
		-- with lax vowel despite secondary [ŋ]), we need to preserve the vowel quality.
		{"([" .. lax_vowels .. "])(n+[gk])", function(v, ngk)
			return (lax_back_vowel_back_diphthongize_map[v] or lax_front_vowel_diphthongize_map[v]) .. ngk 
		end},
		-- A4: plain vowels (the length marker ː stays in place after the token)
		{"á", Vau}, {"ó", Vou}, {"ú", Vuu}, {"æ", Vai}, -- <é> was replaced with <je> early on
		{"a", Va}, {"e", Ve}, {"í", Vii}, {"i", Vi},
		{"o", Vo}, {"u", Vu}, {"ý", Vii}, {"y", Vi}, {"ö", Voe},
	})

	------------------------------------------------------------------
	-- Step 3.2: (sub)component-initial stops and h
	-- Anchored on # or \1; (sub)component-initial stops are aspirated and fricatives devoiced even in unstressed
	-- words, as in unstressed <fyrir>, but also after non-initial primary stress as in <atarna>
	------------------------------------------------------------------
	if dialect == "south" then
		w = apply(w, {{"(!!)hv", "%1" .. C.x}})             -- hv-pronunciation: [x]
	elseif dialect == "south-rounded" then
		w = apply(w, {{"(!!)hv", "%1" .. C.xw}})             -- rounded hv-pronunciation: [xʷ]
	else
		w = apply(w, {{"(!!)hv", "%1" .. C.kh .. C.v}})        -- standard: [kʰv]
	end
	w = apply(w, {
		-- initial hj/hl/hn/hr -> aspirated sonorant
		{"(!!)h([jlnr])", function(boundary, jlnr) return boundary .. orth_to_asp_pua_map[jlnr] end},
		{"(!!)h", "%1" .. C.h},                                -- initial h + vowel
		-- gj → c, kj → cʰ (j absorbed)
		{"(!!)([gk])j", function(boundary, gk) return boundary .. orth_velar_stop_to_palatal_pua_map[gk] end},
		-- g + J → c, k + J -> cʰ
		{"(!!)([gk])([" .. J .. "])",
			function(boundary, gk, j_after) return boundary .. orth_velar_stop_to_palatal_pua_map[gk] .. j_after end},
		-- map remaining initial stops to PUA equivalents
		{"(!!)([ptkbdg])", function(boundary, stop) return boundary .. orth_to_asp_pua_map[stop] end},
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
		{"([gk])j", orth_velar_stop_to_special_palatal_pua_map},
		{"([gk])([" .. J .. "])", function(gk, j_after) return orth_velar_stop_to_special_palatal_pua_map[gk] .. j_after end},
		{"ll([std])", "l%1"},
		{"ll([+" .. Call .. "])", C.t .. C.hl .. "%1"},
		-- other cases of geminates before a consonant simplify; not yet across a (sub)component boundary
		-- because of -tt, -ánn, etc.
		{"([" .. Call .. "])%1([" .. Call .. "])", "%1%2"},
		-- also do cases where Solc already is in place to handle e.g. <ll:> and <nn:> before a consonant
		{"([" .. Call .. "])" .. Solc .. "([" .. Call .. "])", "%1%2"},

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
		{"rfð", C.r .. "(" .. C.v .. ")" .. C.dh}, -- horfði; dirð
		{"rgð", C.r .. "(" .. C.k .. ")" .. C.dh}, -- mergð
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
		{"x", "ks"},                            -- x → ks; should precede epenthetic t in <sl>, e.g. <jaxl> -> [jakstl]
		-- epenthetic [t] in rl, rn, sl, sn
		{"([rs])([ln])", function(rs, ln) return orth_to_unasp_pua_map[rs] .. C.t .. orth_to_unasp_pua_map[ln] end},
		{"ðk", C.th2 .. C.k},                         -- ð devoiced before k → θ
		-- nasal + velar/palatal stop (place + voicing by following segment)
		{"n" .. kPAL, C.hnj .. C.c},                  -- voiceless palatal: banki, þenkja
		{"nk", C.hng .. C.k},                         -- voiceless velar: banka
		{"n" .. gPAL, C.nj .. C.c},                   -- voiced palatal: angi, syngja
		{"ng", C.ng .. C.k},                          -- voiced velar: hanga, langur
		-- geminates and preaspiration; maintain the [kpt] because we may need to convert p -> f later,
		-- as in uppfræða
		{"([" .. Vall .. "])([kpt])%2", "%1" .. C.h .. "%2"}, -- drekka, stoppa, fletta
		-- nn → tn after a tense vowel / diphthong, else n
		{"([" .. Vtense .. "])(ː?)nn", "%1%2" .. C.t .. C.n},
		{"ll", C.t .. C.l},
		-- rr is special and is a long trill (and not devoiced) even word-finally or before a consonant,
		-- e.g. barr, barri, barrtré, kyrrstæður
		{"rr", C.r .. "ː"},
		{"ff", C.f .. Solc},
		{"gg", C.k .. Solc},
		-- no gemination before consonant across (sub)component boundary, as in innbú, rassvasi;
		-- this should go as early as possible, directly after any special handling of written geminates.
		{"([" .. Call .. "])%1(![" .. Call .. "])", "%1%2"},
		-- also do cases where Solc already is in place to handle e.g. <ll:> and <nn:> before a consonant
		{"([" .. Call .. "])" .. Solc .. "(![" .. Call .. "])", "%1%2"},
		-- hagga, etc.
		{"([bdgfhsþðmnr])%1", function(c) return orth_to_unasp_pua_map[c] .. Solc end},
		-- preaspiration: p/t/k + l/n
		{"([" .. Vall .. "])([kpt])([ln])", function(v, kpt, ln) return v .. C.h .. orth_to_unasp_pua_map[kpt] .. orth_to_unasp_pua_map[ln] end},
		{"kt", C.x .. C.t}, -- rakti → x t
		{"pt", C.f .. C.t}, -- æpti → f t
	})

	------------------------------------------------------------------
	-- Step 3.4a: stops and fricatives across (sub)component boundaries
	------------------------------------------------------------------
	w = apply(w, {
		-- kaupfélag, kaupfar, upp fyrir, uppfræða; kaupsýsla, kauptíð, kauptrygging
		{"(ː?)(" .. C.h.. "?p)(![fs" .. C.th .. "])", {
			{replace = "%1%2%3", var = "formal"},
			{replace = C.f .. "%3", var = "informal"}, -- preceding length shortens and hp -> f
		}},
		-- kaupmaður, kaupmennska, Kaupmannahöfn
		{"(ː?)(p!m)", {			
			{replace = "%1%2"},
			{replace = C.h .. "%2"},
		}},
		-- <d> in <ld>, <nd> may drop before <s> across (sub)component boundaries
		{"([ln])(d)(!s)", "%1(%2)%3"},
	})

	------------------------------------------------------------------
	-- Step 3.4b: f realizations
	-- should precede devoicing of r before voiceless sounds because
	-- f may get voiced
	------------------------------------------------------------------
	w = apply(w, {
 		-- <f> preceding labial across (sub)component boundary; rafmagn
		{"(f)(!)(m)", {
			{replace = "%1%2%3", var = "formal"},
			{replace = "%3%2%3", var = "informal"},
		}},
 		-- <f> preceding labial across (sub)component boundary; afbera, afbragð, ofboðslegur;
		-- use OC.p to prevent [p] from getting deleted across (sub)component boundary before another [p]
		{"(f)(!" .. C.p .. ")", {
			{replace = "%1%2", var = "formal"},
			{replace = OC.p .. "%2", var = "informal"},
		}},
		-- <f> preceding <p> across (sub)component boundary; no discussion or examples given, guess that it's similar to -f#b-
		{"(f)(!" .. C.ph .. ")", {
			{replace = "%1%2", var = "formal"},
			{replace = C.p .. "%2", var = "informal"},
		}},
 		-- [f] preceding [f] and [s] across (sub)component boundary; affall, afferma, offita, afskekktur, afstaða, ofsjónir
		{"f(![fs])", C.f .. "%1"},
		-- Before voiceless fricatives and approximants other than [s], and before aspirated stops, modern [v], older [f]:
		-- afhlúpa, afhrak, afkimi, afkoma, aftaka, raftækni, Riftún, ofhleðsla, ofhvörf, etc.
		{"f(![" .. COCvoiceless .. "])", {
			{replace = C.v .. "%1", var = "modern"},
			{replace = C.f .. "%1", var = "older"},
		}},
		{"(!)f", "%1" .. C.f},                   -- initial f; should precede handling of -fl-
		{"f(@[ln])", C.p .. "%1"},                    -- efla, hafna → p
		{"f(@[st])", C.f .. "%1"},                    -- ofsi, aftur → f
		{"([" .. Vauou .. "]ː?@)f([" .. Vall .. "])", "%1(v)%2"},      -- optionally silent after á/ó/ú
		{"f", C.v},                                  -- sofa → v
	})

	----------------------------------------------------------------------
	-- Step 3.4c: devoicing of liquids/nasals before a voiceless consonant
	-- and epenthetic t in [rs][ln]
	----------------------------------------------------------------------
	w = apply(w, {
		-- r becomes voiceless before any aspirated stop or voiceless fricative/approximant,
		-- including across (sub)component boundaries
		{"r(!" .. "[" .. COCvoiceless .. "])", C.hr .. "%1"},
		{"r([" .. COCvoiceless .. "])", C.hr .. "%1"},
		{"r(@[" .. COCvoiceless .. "])", C.hr .. "%1"},
		-- l/m becomes voiceless before an aspirated stop
		{"([lm])(@[kpt" .. kPAL .. "])", function(lm, kpt) return orth_to_asp_pua_map[lm] .. kpt end},
		-- l becomes voiceless across a (sub)component boundary before hl- (jökulhlaup; FIXME: there may be other cases like this)
		{"l(!" .. C.hl .. ")", C.hl .. "%1"},
		{"n(@)t", C.hn .. "%1" .. C.t},                          -- vanta
	})

	--------------------------------------------------------------------------
	-- Step 3.4d: dialectal "harðmæli" (intervocalic voiceless stops aspirate)
	--------------------------------------------------------------------------

	if dialect == "north" or dialect == "northeast" then
		-- harðmæli: aspirate non-initial unaspirated stops between a vowel and a
		-- following sonorant (vowel / j / r / v). The optional ː is the length mark.
		w = apply(w, {{"([" .. Vall .. "]ː?@)([ptk" .. kPAL .. "])([" .. Vall .. C.v .. "jr])",
			function(v1, stop, son2) return v1 .. orth_to_asp_pua_map[stop] .. son2 end
		}})
	end
	
	------------------------------------------------------------------
	-- Step 3.4e: g and k realizations
	------------------------------------------------------------------
	w = apply(w, {
		-- g
		-- optionally silent after á/ó/ú before a vowel
		{"([" .. Vauou .. "]ː?@)g([" .. Vall .. "])", "%1(" .. C.gh .. ")%2"},
		-- optionally silent after á/ó/ú (sub)component-finally; needs to lengthen when dropped; lágnætti, skóglendi, drjúgvirkur
		-- note that if before voiceless, the rule below will generate optional [x]
		{"([" .. Vauou .. "])g(!)", {
			{replace = "%1g%2"},
			{replace = "%1ː%2"},
		}},
		{"g(@t)", C.x .. "%1"},                                        -- sagt: g → x (t kept)
		{"g(@[ðr])", C.gh .. "%1"},                                 -- sigra, sagði → ɣ
		{"([" .. Vall .. "]ː?@)g([" .. Vall .. "])", "%1" .. C.gh .. "%2"},-- saga → ɣ (intervocalic)
		{"([" .. Vall .. "]ː?)g(![" .. COCvoiceless .. "])", {
			{replace = "%1" .. C.x .. "%2"},
			{replace = "%1" .. C.gh .. "%2"},
		}},
		{"([" .. Vall .. "]ː?)g(!)", "%1" .. C.gh .. "%2"},           -- lag → ɣ (final after a vowel)
		{"([" .. Vall .. "]ː?@)" .. gPAL .. "([" .. Vall .. "])", "%1" .. C.j .. "%2"}, -- hagi → j
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
		{"([bdptmnlrðþvsjk])", orth_to_unasp_pua_map},
		-- (sub)component-final stop + [n]/[l] devoice the sonorant: vopn [vɔhpn̥], magn [makn̥], einn [eitn̥], stjákl [stjauhkl̥]
		{"([" .. unaspirated_stops_pua .. "])([" .. C.n .. C.l .. "])(!)",
			function(stop, nl, boundary) return stop .. devoice_resonant_map[nl] .. boundary end
		},
	})

	--------------------------------------------------------------------------------
	-- Step 3.4g: stop consonants and <s> across (sub)component boundaries
	--------------------------------------------------------------------------------
	w = apply(w, {
		-- same-place stop consonants drop across (sub)component boundaries
		{"[" .. C.k .. C.kh .. "](![" .. C.k .. C.kh .. C.c .. C.ch .. "])", "%1"},
		{"[" .. C.p .. C.ph .. "](![" .. C.p .. C.ph .. "])", "%1"},
		{"[" .. C.t .. C.th .. "](![" .. C.t .. C.th .. "])", "%1"},
		{C.s .. "(!" .. C.s .. ")", "%1"},
	})

	----------------------------------------------------------------------------------------
	-- Step 3.4h: Northeast Iceland dialect adjustments in resonant + stop (and ðk) clusters
	----------------------------------------------------------------------------------------
	if dialect == "northeast" then
		-- voiced pronunciation: a nasal voices before a stop, and the stop aspirates
		local voiceless_nasals_pua = C.hm .. C.hn .. C.hnj .. C.hng
		w = apply(w, {{"([" .. voiceless_nasals_pua .. "])(@)([" .. unaspirated_stops_pua .. "])",
			function(nv, secstress, stop) return voice_resonant_map[nv] .. secstress .. aspirate_stop_map[stop] end
		}})
		-- l voices (and stop aspirates) before labial/velar stops, but stays
		-- voiceless before t (per doc: piltur, elta keep [l̥t])
		w = apply(w, {{C.hl .. "(@)([" .. C.p .. C.k .. C.c .. "])",
			function(secstress, stop) return C.l ..secstress .. aspirate_stop_map[stop] end
		}})
		-- ð voiced (and following k aspirated) in -ðk-: maðkur [maðkʰʏr]
		w = apply(w, {{C.th2 .. "(@)" .. C.k, C.dh .. "%1" .. C.kh}})
	end

	------------------------------------------------------------------
	-- Steps 4–5: detokenize and clean up
	------------------------------------------------------------------
 	-- convert obligatory PUA characters to regular ones before detokenizing
	w = apply(w, {
		{".", OC_to_C},
	})

	-- shorten following vowel directly after a geminate consonant (usually across a (sub)component boundary);
	-- FIXME: not clear if this is real due to prevalent typos in Kristján Árnason's book and not being
	-- explicitly discussed, but it's consistent in the book
	w = apply(w, {
		-- across a (sub)component boundary; usualy case
		{"ː?([" .. Call .. "])(!%1[" .. Vall .. "])ː", "%1%2"},
		-- geminate precedes the (sub)component boundary; can happen with explicit written [:],
		-- as in [[prestsekkja]] written <pres[:]-ekkja>
		{"ː?([" .. Call .. "]ː![" .. Vall .. "])ː", "%1"},
		-- eliminate _ and + markers before syllabification
		{"[_+]", ""},
	})

	determine_secondary_stresses(w, disable_internal_stresses)
	
	w = apply(w, {
		-- convert regular PUA characters to IPA
		{".", detok},
	})
	return w
end


local function toIPA_word(word, dialect, disable_internal_stresses)
	-- Mark stress before eliminating case distinctions so we don't treat capitalized words like <Á> as unstressed
	word = mark_stress(word)
	word = ulower(word)
	word = word:gsub("%[(.-)%]", bracketed_phone_map)
	word = ugsub(word, "[ăĕĭŏŭ]", decompose_breve_map)
	word = word:gsub("([ln])%1:", "%1" .. Solc)
	word = word:gsub("é", "je") -- this seems to be the easiest way to handle this letter
	-- Handle epenthetic [j] in hiatus after a high front vowel or glide
	word = ugsub(word, "(e[iy][\4]?)([" .. Vall .. "])", "%1j%2")
	word = ugsub(word, "(au[\4]?)([" .. Vall .. "])", "%1j%2")
	word = ugsub(word, "([íýæ][\4]?)([" .. Vall .. "])", "%1j%2")
	local subcomponents = split(word, "(#+)")
	-- Odd-numbered elements are subcomponents and even-numbered are separators, except that the first and last subcomponent
	-- are blank because we have ## at word edges.
	for i = 3, #subcomponents - 2, 2 do
		local subcomponent = subcomponents[i]
		-- If there's no next subcomponent, pass in nil.
		subcomponents[i] = determine_vowel_length(subcomponent, i + 2 < #subcomponents and subcomponents[i + 2] or nil,
			dialect)
	end
	word = concat(subcomponents)
	return convert({{output = word, levels_by_class = {}}}, dialect, disable_internal_stresses)
end


-- Given a single substitution spec, `to`, figure out the corresponding value of `from` used in a complete
-- substitution spec. `pagename` is the name of the page, either the actual one or taken from the `pagename` param.
-- `whole_word`, if set, indicates that the match must be to a whole word (it was preceded by ~).
local function convert_single_substitution_to_original(to, pagename, whole_word)
	-- Replace specially-handled characters with a class matching the character and possible replacements.
	local escaped_from = to
	escaped_from = escaped_from:gsub("ˈ", ""):gsub("ˌ", ""):gsub("[._:+]", "")
	-- [k] and [c] normally stand for written <g> so make the substitution.
	escaped_from = escaped_from:gsub("%[[kc]%]", "g")
	escaped_from = escaped_from:gsub("%[[KC]%]", "G")
	escaped_from = escaped_from:gsub("%[[kc]h%]", "k")
	escaped_from = escaped_from:gsub("%[[KC]h%]", "K")
	escaped_from = pattern_escape(escaped_from)
	-- Single and double hyphen should match against space, hyphen or nothing in the original.
	-- This is tricky, because we already passed `escaped_from` through pattern_escape() causing a hyphen, paren or
	-- bracket to get a % sign before it, and have to double up the percent signs to match and replace a literal %.
	escaped_from = escaped_from:gsub("%%%-%%%-", "[ %%-]?")
	escaped_from = escaped_from:gsub("%%%-", "[ %%-]?")
	
	-- Parens and brackets should match against themselves or nothing in the original.
	escaped_from = escaped_from:gsub("%%([()%[%]])", "%%%1?")
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
	else
		-- convert apostrophe to primary stress and backquote to secondary stress
		text = text:gsub("'", "ˈ"):gsub("`", "ˌ")
		if text:find("^%[.*%]$") then
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
				-- eliminate word-final optional gemination before a next-word-initial consonant
				if ufind(word2, "^ˈ?[" .. Call .. "]") then
					word1 = word1:gsub(Solc .. "$", "")
				end
				return word1 .. " " .. word2
			end
		end
		all_word_pronuns = concatenate_horizontally(all_word_pronuns, this_word_pronuns, concatenate)
	end
	-- We purposely didn't convert Solc to (ː) during detokenization so we could eliminate it in the above
	-- loop. Now convert remaining Solc to (ː).
	for _, all_word_pronun in ipairs(all_word_pronuns) do
		all_word_pronun.output = all_word_pronun.output:gsub(Solc, "(ː)")
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
	local pronuns = export.toIPA(data.respelling, data.args.dialect, data.pagename).pronuns
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
		augment_params = {
			dialect = {},
		},
	}
end

return export
