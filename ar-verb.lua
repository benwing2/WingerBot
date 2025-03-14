local export = {}

--[=[

This module implements {{ar-conj}} and provides the underlying conjugation functions for {{ar-verb}}
(whose actual formatting is done in [[Module:ar-headword]]).

Author: User:Benwing, from an early version (2013-2014) by User:Atitarev, User:ZxxZxxZ.

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of tense/mood/person/number/etc.
	 Example slot names for verbs are "past_1s" (past tense first-person singular), "juss_pass_3fp" (non-past jussive
	 passive third-person feminine plural) "ap" (active participle). Each slot is filled with zero or more forms.

-- "form" = The conjugated Arabic form representing the value of a given slot.

-- "lemma" = The dictionary form of a given Arabic term. For Arabic, normally the third person masculine singular past,
	 although other forms may be used if this form is missing (e.g. in passive-only verbs or verbs lacking the past).
]=]

--[=[

FIXME:

1. Finish unimplemented conjugation types. Only IX-final-weak left (extremely rare, possibly only one verb اِعْمَايَ
   (according to Haywood and Nahmad p. 244, who are very specific about the irregular occurrence of alif + yā instead
   of expected اِعْمَيَّ with doubled yā). Not in Hans Wehr. NOTE: Not true about this, cf. form IX اِرْعَوَى "to desist,
   to repent, to see the light". Also note form XII اِخْضَوْضَرَ = form IX اِخْضَرَّ "to be or become green".
   [DONE except for اِعْمَايَ]

2. Implement irregular verbs as special cases and recognize them, e.g.
   -- laysa "to not be"; only exists in the past tense, no non-past, no imperative, no participles, no passive, no
      verbal noun. Irregular alternation las-/lays-. [IMPLEMENTABLE USING OVERRIDES]
   -- istaḥā yastaḥī "be ashamed of" -- this is complex according to Hans Wehr because there are two verbs, regular
      istaḥyā yastaḥyī "to spare (someone)'s life" and irregular istaḥyā yastaḥyī "to be ashamed to face (someone)",
	  which is irregular because it has the alternate irregular form istaḥā yastaḥī which only applies to this meaning.
	  Currently we follow Haywood and Nahmad in saying that both varieties can be spelled istaḥyā/istaḥā/istaḥḥā, but we
	  should instead use a variant= param similar to حَيَّ to distinguish the two possibilities, and maybe not include
	  istaḥḥā.
   -- ʿayya/ʿayiya yaʿayyu/yaʿyā "to not find the right way, be incapable of, stammer, falter, fall ill". This appears
      to be a mixture of a geminate and final-weak verb. Unclear what the whole paradigm looks like. Do the
      consonant-ending parts in the past follow the final-weak paradigm? Is it the same in the non-past? Or can you
      conjugate the non-past fully as either geminate or final-weak?
   -- اِنْمَحَى inmaḥā or يمَّحَى immaḥā "to be effaced, obliterated; to disappear, vanish" has irregular assimilation of inm-
      to imm- as an alternative. inmalasa "to become smooth; to glide; to slip away; to escape" also has immalasa as an
	  alternative. The only other form VII verbs in Hans Wehr beginning with -m- are inmalaḵa "to be pulled out, torn
	  out, wrenched" and inmāʿa "to be melted, to melt, to dissolve", which are not listed with imm- alternatives, but
	  might have them; if so, we should handle this generally. [DONE]
   -- يَرَعَ yaraʕa yariʕu "to be a coward, to be chickenhearted" as an alternative form of يَرِعَ yariʕa yayraʕu (as given in
      Wehr). [IMPLEMENTABLE USING OVERRIDES]
3. Implement individual override parameters for each paradigm part. See Module:fro-verb for an example of how to do this
   generally. Note that {{temp|ar-conj-I}} and other of the older templates already had such individual override params.
   [DONE]

Irregular verbs already implemented:

   -- [ḥayya/ḥayiya yaḥyā "live" -- behaves like a normal final-weak verb
	  (e.g. past first singular ḥayītu) except in the past-tense parts with
	  vowel-initial endings (all the third person except for the third feminine
	  plural). The normal singular and dual endings have -yiya- in them, which
	  compresses to -yya-, with the normal endings the less preferred ones.
	  In masculine third plural, expected ḥayū is replaced by ḥayyū by
	  analogy to the -yy- parts, and the regular form is not given as an
	  alternant in John Mace. Barron's 201 verbs appears to have the regular
	  ḥayū as the part, however. Note also that final -yā appears with tall
	  alif. This appears to be a spelling convention of Arabic, also applying
	  in ḥayyā (form II, "to keep (someone) alive") and 'aḥyā (form IV,
	  "to animate, revive, give birth to, give new life to").] -- implemented
   -- [ittaxadha yattaxidhu "take"] -- implemented
   -- [sa'ala yas'alu "ask" with alternative jussive/imperative yasal/sal] -- implemented
   -- [ra'ā yarā "see"] -- implemented
   -- ['arā yurī "show"] -- implemented
   -- ['akala ya'kulu "eat" with imperative kul] -- implemented
   -- ['axadha ya'xudhu "take" with imperative xudh] -- implemented
   -- ['amara ya'muru "order" with imperative mur] -- implemented

--]=]

local force_cat = false -- set to true for debugging
-- if true, always maintain manual translit during processing, and compare against full translit at the end
local debug_translit = false

local lang = require("Module:languages").getByCode("ar")

local m_links = require("Module:links")
local m_string_utilities = require("Module:string utilities")
local m_table = require("Module:table")
local ar_utilities = require("Module:ar-utilities")
local ar_nominals = require("Module:ar-nominals")
local iut = require("Module:inflection utilities")
local parse_utilities_module = "Module:parse utilities"
local pron_qualifier_module = "Module:pron qualifier"

local rfind = m_string_utilities.find
local rsubn = m_string_utilities.gsub
local rmatch = m_string_utilities.match
local rsplit = m_string_utilities.split
local usub = m_string_utilities.sub
local ulen = m_string_utilities.len
local u = m_string_utilities.char

local dump = mw.dumpObject

-- Within this module, conjugations are the functions that do the actual
-- conjugating by creating the parts of a basic verb.
-- They are defined further down.
local conjugations = {}
-- hamza variants
local HAMZA            = u(0x0621) -- hamza on the line (stand-alone hamza) = ء
local HAMZA_ON_ALIF    = u(0x0623)
local HAMZA_ON_W       = u(0x0624)
local HAMZA_UNDER_ALIF = u(0x0625)
local HAMZA_ON_Y       = u(0x0626)
local HAMZA_ANY        = "[" .. HAMZA .. HAMZA_ON_ALIF .. HAMZA_UNDER_ALIF .. HAMZA_ON_W .. HAMZA_ON_Y .. "]"
local HAMZA_PH         = u(0xFFF0) -- hamza placeholder

local BAD = u(0xFFF1)
local BORDER = u(0xFFF2)

-- diacritics
local A  = u(0x064E) -- fatḥa
local AN = u(0x064B) -- fatḥatān (fatḥa tanwīn)
local U  = u(0x064F) -- ḍamma
local UN = u(0x064C) -- ḍammatān (ḍamma tanwīn)
local I  = u(0x0650) -- kasra
local IN = u(0x064D) -- kasratān (kasra tanwīn)
local SK = u(0x0652) -- sukūn = no vowel
local SH = u(0x0651) -- šadda = gemination of consonants
local DAGGER_ALIF = u(0x0670)
local DIACRITIC_ANY_BUT_SH = "[" .. A .. I .. U .. AN .. IN .. UN .. SK .. DAGGER_ALIF .. "]"
-- Pattern matching short vowels
local AIU = "[" .. A .. I .. U .. "]"
-- Pattern matching short vowels or sukūn
local AIUSK = "[" .. A .. I .. U .. SK .. "]"
-- Pattern matching any diacritics that may be on a consonant
local DIACRITIC = SH .. "?" .. DIACRITIC_ANY_BUT_SH

-- translit_patterns
local vowels = "aeiouāēīōū"
local NV = "[^" .. vowels .. "]"

local dia = {a = A, i = I, u = U}
local undia = {[A] = "a", [I] = "i", [U] = "u", ["-"] = "-"}

-- various letters and signs
local ALIF   = u(0x0627) -- ʾalif = ا
local AMAQ   = u(0x0649) -- ʾalif maqṣūra = ى
local AMAD   = u(0x0622) -- ʾalif madda = آ
local TAM    = u(0x0629) -- tāʾ marbūṭa = ة
local T      = u(0x062A) -- tāʾ = ت
local HYPHEN = u(0x0640)
local N      = u(0x0646) -- nūn = ن
local W      = u(0x0648) -- wāw = و
local Y      = u(0x064A) -- yāʾ = ي
local S      = "س"
local M      = "م"
local LRM    = u(0x200e) -- left-to-right mark

-- common combinations
local AH    = A .. TAM
local AT    = A .. T
local AA    = A .. ALIF
local AAMAQ = A .. AMAQ
local AAH   = AA .. TAM
local AAT   = AA .. T
local II    = I .. Y
local UU    = U .. W
local AY    = A .. Y
local AW    = A .. W
local AYSK  = AY .. SK
local AWSK  = AW .. SK
local NA    = N .. A
local NI    = N .. I
local AAN   = AA .. N
local AANI  = AA .. NI
local AYNI  = AYSK .. NI
local AWNA  = AWSK .. NA
local AYNA  = AYSK .. NA
local AYAAT = AY .. AAT
local UNU   = "[" .. UN .. U .. "]"
local MA    = M .. A
local MU    = M .. U
local TA    = T .. A
local TU    = T .. U
local _I    = ALIF .. I
local _U    = ALIF .. U

local translit_cache = {
	-- hamza variants
	[HAMZA] = "ʔ",
	[HAMZA_ON_ALIF] = "ʔ",
	[HAMZA_ON_W] = "ʔ",
	[HAMZA_UNDER_ALIF] = "ʔ",
	[HAMZA_ON_Y] = "ʔ",
	[HAMZA_PH] = "ʔ",

	-- diacritics
	[A] = "a",
	[AN] = "an",
	[U] = "u",
	[UN] = "un",
	[I] = "i",
	[IN] = "in",
	[SK] = "",
	[SH] = "*", -- handled specially
	[DAGGER_ALIF] = "ā",

	-- various letters and signs
	[""] = "",
	[ALIF] = BAD, -- we should never be transliterating ALIF by itself, as its translit in isolation is ambiguous
	[AMAQ] = BAD,
	[AMAD] = "ʔā",
	[TAM] = "",
	[T] = "t",
	[N] = "n",
	[W] = "w",
	[Y] = "y",
	[S] = "s",
	[M] = "m",
	[LRM] = "",

	-- common combinations
	[AH] = "a",
	[AT] = "at",
	[AA] = "ā",
	[AAMAQ] = "ā",
	[AAH] = "āh",
	[AAT] = "āt",
	[II] = "ī",
	[UU] = "ū",
	[AY] = "ay",
	[AW] = "aw",
	[AYSK] = "ay",
	[AWSK] = "aw",
	[NA] = "na",
	[NI] = "ni",
	[AAN] = "ān",
	[AANI] = "āni",
	[AYNI] = "ayni",
	[AWNA] = "awna",
	[AYNA] = "ayna",
	[AYAAT] = "ayāt",
	[MA] = "ma",
	[MU] = "mu",
	[TA] = "ta",
	[TU] = "tu",
	[_I] = "i",
	[_U] = "u",
}

local function transliterate(text)
	local cached = translit_cache[text]
	if cached then
		if cached == BAD then
			error(("Internal error: Unable to transliterate %s because explicitly marked as BAD"):format(text))
		end
		return cached
	end
	local tr = (lang:transliterate(text))
	if not tr then
		error(("Internal error: Unable to transliterate: %s"):format(text))
	end
	translit_cache[text] = tr
	return tr
end

local all_person_number_list = {
	"1s",
	"2ms",
	"2fs",
	"3ms",
	"3fs",
	"2d",
	"3md",
	"3fd",
	"1p",
	"2mp",
	"2fp",
	"3mp",
	"3fp"
}

local function make_person_number_slot_accel_list(list)
	local slot_accel_list = {}
	return slot_accel_list
end

local imp_person_number_list = {}
for _, pn in ipairs(all_person_number_list) do
	if pn:find("^2") then
		table.insert(imp_person_number_list, pn)
	end
end

local passive_types = m_table.listToSet {
	"pass", -- verb has both active and passive
	"ipass", -- verb is active with impersonal passive
	"nopass", -- verb is active-only
	"onlypass", -- verb is passive-only
	"onlypass-impers", -- verb itself is impersonal, meaning passive-only with impersonal passive
}

local indicator_flags = m_table.listToSet {
	"nopast", "no_nonpast", "noimp",
	"nocat", -- don't categorize or include annotations about this; useful in suppletive parts of verbs
	"reduced", -- verb has assimilation/reduction of initial coronals
	"altgem", -- form X with alternative past geminate forms with final-weak endings
}

export.potential_lemma_slots = {"past_3ms", "past_pass_3ms", "ind_3ms", "ind_pass_3ms", "imp_2ms"}

export.unsettable_slots = {}
for _, potential_lemma_slot in ipairs(export.potential_lemma_slots) do
	table.insert(export.unsettable_slots, potential_lemma_slot .. "_linked")
end
-- We don't set the active participle directly for form I because we don't want stative verbs (with past vowel i or u)
-- to default to فَاعِل. Instead we set the special slot 'ap1' and later copy it to 'ap' for non-stative verbs. The user
-- meanwhile can explicitly request the فَاعِل form for active participles for stative verbs using `ap:+`.
table.insert(export.unsettable_slots, "ap1") -- primary default فَاعِل for form I active participles
table.insert(export.unsettable_slots, "ap2") -- secondary default فَعِيل for form I active participles (stative I)
table.insert(export.unsettable_slots, "ap3") -- secondary default فَعِل for form I active participles (stative II)
table.insert(export.unsettable_slots, "apcd") -- secondary default أَفْعَل for form I active participles (color/defect)
table.insert(export.unsettable_slots, "apan") -- secondary default فَعْلَان for form I active participles (in -ān)
table.insert(export.unsettable_slots, "pp2") -- secondary default فَعِيل for form I passive participles (same as ap2)
table.insert(export.unsettable_slots, "vn2") -- secondary default فِعَال for form III verbal nouns
export.unsettable_slots_set = m_table.listToSet(export.unsettable_slots)

local default_indicator_to_active_participle_slot = {
	["+"] = "ap1",
	["++"] = "ap2",
	["+++"] = "ap3",
	["+cd"] = "apcd",
	["+an"] = "apan",
}

local slots_that_may_be_uncertain = {
	vn = "verbal noun",
	ap = "active participle",
}

-- Initialize all the slots for which we generate forms.
local function add_slots(alternant_multiword_spec)
	alternant_multiword_spec.verb_slots = {
		{"ap", "act|part"},
		{"pp", "pass|part"},
		{"vn", "vnoun"},
	}
	for _, unsettable_slot in ipairs(export.unsettable_slots) do
		table.insert(alternant_multiword_spec.verb_slots, {unsettable_slot, "-"})
	end

	-- Add entries for a slot with person/number variants.
	-- `slot_prefix` is the prefix of the slot, typically specifying the tense/aspect.
	-- `tag_suffix` is a string listing the set of inflection tags to add after the person/number tags.
	-- `person_number_list` is a list of the person/number slot suffixes to add to `slot_prefix`.
	local function add_personal_slot(slot_prefix, tag_suffix, person_number_list)
		for _, persnum in ipairs(person_number_list) do
			local slot = slot_prefix .. "_" .. persnum
			local accel = persnum:gsub("(.)", "%1|") .. tag_suffix
			table.insert(alternant_multiword_spec.verb_slots, {slot, accel})
		end
	end

	local tenses = {
		{"past", "past|%s"},
		{"ind", "non-past|%s|ind"},
		{"sub", "non-past|%s|sub"},
		{"juss", "non-past|%s|juss"},
	}
	for _, slot_accel in ipairs(tenses) do
		local slot, accel = unpack(slot_accel)
		for _, voice in ipairs {"act", "pass"} do
			add_personal_slot(voice == "act" and slot or slot .. "_pass", accel:format(voice),
				all_person_number_list)
		end
	end
	add_personal_slot("imp", "imp", imp_person_number_list)

	alternant_multiword_spec.verb_slots_map = {}
	for _, slot_accel in ipairs(alternant_multiword_spec.verb_slots) do
		local slot, accel = unpack(slot_accel)
		alternant_multiword_spec.verb_slots_map[slot] = accel
	end
end

local overridable_stems = {}

local slot_override_param_mods = {
	footnote = {
		item_dest = "footnotes",
		store = "insert",
	},
	alt = {},
	t = {
		-- [[Module:links]] expects the gloss in "gloss".
		item_dest = "gloss",
	},
	gloss = {},
	g = {
		-- [[Module:links]] expects the genders in "g". `sublist = true` automatically splits on comma (optionally
		-- with surrounding whitespace).
		item_dest = "genders",
		sublist = true,
	},
	pos = {},
	lit = {},
	id = {},
	-- Qualifiers and labels
	q = {
		type = "qualifier",
	},
	qq = {
		type = "qualifier",
	},
	l = {
		type = "labels",
	},
	ll = {
		type = "labels",
	},
}

local function generate_obj(formval, parse_err, prefix, is_slot_override)
	local val, uncertain = formval:match("^(.*)(%?)$")
	val = val or formval
	uncertain = not not uncertain
	local ar, translit = val:match("^(.*)//(.*)$")
	if not ar then
		ar = val
	end
	if ar == "" then
		if uncertain then
			ar = "?"
		else
			error(("Can't specify blank value for override for %s override '%s'"):format(
				is_slot_override and "slot" or "stem", prefix))
		end
	end
	return {form = ar, translit = translit, uncertain = uncertain}
end

local function parse_inline_modifiers(comma_separated_group, parse_err, prefix, is_slot_override)
	local function this_generate_obj(formval, parse_err)
		return generate_obj(formval, parse_err, prefix, is_slot_override)
	end
	return require(parse_utilities_module).parse_inline_modifiers_from_segments {
		group = comma_separated_group,
		props = {
			param_mods = slot_override_param_mods,
			parse_err = parse_err,
			generate_obj = this_generate_obj,
			pre_normalize_modifiers = function(data)
				local modtext = data.modtext
				modtext = modtext:match("^(%[.*%])$")
				if modtext then
					return ("<footnote:%s>"):format(modtext)
				end
				return data.modtext
			end,
		},
	}
end

local function allow_multiple_values_for_override(comma_separated_groups, data, is_slot_override)
	local retvals = {}
	for _, comma_separated_group in ipairs(comma_separated_groups) do
		local retval
		if is_slot_override then
			retval = parse_inline_modifiers(comma_separated_group, data.parse_err)
		else
			retval = generate_obj(comma_separated_group[1], data.parse_err, data.prefix, is_slot_override)
			retval.footnotes = data.fetch_footnotes(comma_separated_group)
		end
		table.insert(retvals, retval)
	end
	for _, form in ipairs(retvals) do
		if form.form == "+" or default_indicator_to_active_participle_slot[form.form] then
			if form.form ~= "+" and default_indicator_to_active_participle_slot[form.form] and not is_slot_override then
				error(("Stem override '%s' cannot use %s to request a secondary default"):format(
					data.prefix, form.form))
			end
			data.base.slot_override_uses_default[data.prefix] = true
		end
	end
	for _, form in ipairs(retvals) do
		if form.form == "-" then
			data.base.slot_explicitly_missing[data.prefix] = true
			break
		end
	end
	if data.base.slot_explicitly_missing[data.prefix] then
		for _, form in ipairs(retvals) do
			if form.form ~= "-" then
				data.parse_err(("For slot or stem '%s', saw both - and a value other than -, which isn't allowed"):
					format(data.prefix))
			end
		end
		return nil
	end
	return retvals
end

local function simple_choice(choices)
	return function(separated_groups, data)
		if #separated_groups > 1 then
			data.parse_err("For spec '" .. data.prefix .. ":', only one value currently allowed")
		end
		if #separated_groups[1] > 1 then
			data.parse_err("For spec '" .. data.prefix .. ":', no footnotes currently allowed")
		end
		local choice = separated_groups[1][1]
		if not m_table.contains(choices, choice) then
			data.parse_err("For spec '" .. data.prefix .. ":', saw value '" .. choice .. "' but expected one of '" ..
				table.concat(choices, ",") .. "'")
		end
		return choice
	end
end

for _, overridable_stem in ipairs {
	"past",
	"past_v",
	"past_c",
	"past_pass",
	"past_pass_v",
	"past_pass_c",
	"nonpast",
	"nonpast_v",
	"nonpast_c",
	"nonpast_pass",
	"nonpast_pass_v",
	"nonpast_pass_c",
	"imp",
	"imp_v",
	"imp_c",
} do
	overridable_stems[overridable_stem] = allow_multiple_values_for_override
end

overridable_stems.past_final_weak_vowel = simple_choice { "ay", "aw", "ī", "ū" }
overridable_stems.past_pass_final_weak_vowel = simple_choice { "ay", "aw", "ī", "ū" }
overridable_stems.nonpast_final_weak_vowel = simple_choice { "ā", "ī", "ū" }
overridable_stems.nonpast_pass_final_weak_vowel = simple_choice { "ā", "ī", "ū" }


-------------------------------------------------------------------------------
--                                Utility functions                          --
-------------------------------------------------------------------------------

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	return (rsubn(term, foo, bar))
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
end

-- Concatenate one or more strings or form objects.
local function q(...)
	local not_all_strings = debug_translit
	local has_manual_translit = debug_translit
	for i = 1, select("#", ...) do
		local argt = select(i, ...)
		if not argt then
			error(("Internal error: Saw nil at index %s: %s"):format(i, dump({...})))
		end
		if type(argt) ~= "string" then
			not_all_strings = true
			if argt.translit then
				has_manual_translit = true
				break
			end
		end
	end

	if not not_all_strings then
		-- just strings, concatenate directly
		return table.concat({...})
	end

	local formvals = {}
	local translit = has_manual_translit and {} or nil
	local footnotes

	for i = 1, select("#", ...) do
		local argt = select(i, ...)
		if type(argt) == "string" then
			formvals[i] = argt
			if has_manual_translit then
				translit[i] = transliterate(argt)
			end
		else
			formvals[i] = argt.form
			if has_manual_translit then
				translit[i] = argt.translit or transliterate(argt.form)
			end
			footnotes = iut.combine_footnotes(footnotes, argt.footnotes)
		end
	end

	-- FIXME: Do we want to support other properties?
	return {
		form = table.concat(formvals),
		translit = has_manual_translit and table.concat(translit) or nil,
		footnotes = footnotes,
	}
end

-- Return the formval associated with `rad` (a radical or past/non-past vowel, either a string or form object).
local function rget(rad)
	if type(rad) == "string" then
		return rad
	elseif type(rad) == "table" then
		return rad.form
	else
		error(("Internal error: Unexpected type for radical or past/non-past vowel: %s"):format(dump(rad)))
	end
end
export.rget = rget -- for use in [[Module:ar-headword]]

-- Return the footnotes associated with `rad` (a radical or past/non-past vowel, either a string or form object).
local function rget_footnotes(rad)
	if type(rad) == "string" then
		return nil
	elseif type(rad) == "table" then
		return rad.footnotes
	else
		error(("Internal error: Unexpected type for radical or past/non-past vowel: %s"):format(dump(rad)))
	end
end

-- Return true if the formval associated with `rad` (a radical or past/non-past vowel, either a string or form object)
-- is `val`.
local function req(rad, val)
	return rget(rad) == val
end

-- Map `vow` (a past/non-past vowel, either a string or form object without translit) by passing the formval through
-- `fn`. Don't call this on radicals because they may have manual translit and it isn't clear how to handle that.
local function map_vowel(vow, fn)
	if type(vow) == "string" then
		return fn(vow)
	elseif type(vow) == "table" then
		return {form = fn(vow.form), footnotes = vow.footnotes}
	else
		error(("Internal error: Unexpected type for past/non-past vowel: %s"):format(dump(vow)))
	end
end

local function get_radicals_3(vowel_spec)
	return vowel_spec.rad1, vowel_spec.rad2, vowel_spec.rad3, vowel_spec.past, vowel_spec.nonpast
end

local function get_radicals_4(vowel_spec)
	return vowel_spec.rad1, vowel_spec.rad2, vowel_spec.rad3, vowel_spec.rad4
end

local function is_final_weak(base, vowel_spec)
	return vowel_spec.weakness == "final-weak" or base.form == "XV"
end

local function link_term(text, face, id)
	return m_links.full_link({lang = lang, term = text, tr = "-", id = id}, face)
end

local function tag_text(text, tag, class)
	return m_links.full_link({lang = lang, alt = text, tr = "-"})
end

local function track(page)
	require("Module:debug/track")("ar-verb/" .. page)
	return true
end

local function track_if_ar_conj(base, page)
	if base.alternant_multiword_spec.source_template == "ar-conj" then
		require("Module:debug/track")("ar-verb/" .. page)
	end
	return true
end

local function reorder_shadda(word)
	-- shadda+short-vowel (including tanwīn vowels, i.e. -an -in -un) gets
	-- replaced with short-vowel+shadda during NFC normalisation, which
	-- MediaWiki does for all Unicode strings; however, it makes various
	-- processes inconvenient, so undo it.
	word = rsub(word, "(" .. DIACRITIC_ANY_BUT_SH .. ")" .. SH, SH .. "%1")
	return word
end

-------------------------------------------------------------------------------
--                        Basic functions to inflect tenses                  --
-------------------------------------------------------------------------------

local function skip_slot(base, slot, allow_overrides)
	if base.slot_explicitly_missing[slot] then
		return true
	end
	if not allow_overrides and base.slot_overrides[slot] and not base.slot_override_uses_default[slot] then
		-- Skip any slots for which there are overrides, except those that request the default value using +, ++, etc.
		return true
	end

	if base.passive == "nopass" and (slot == "pp" or slot:find("_pass")) then
		return true
	elseif base.passive == "onlypass" and slot ~= "pp" and slot ~= "vn" and not slot:find("_pass") then
		return true
	elseif base.passive == "ipass" and slot:find("_pass") and not slot:find("3ms") then
		return true
	elseif base.passive == "onlypass-impers" and slot ~= "pp" and slot ~= "vn" and (not slot:find("_pass") or
		slot:find("_pass") and not slot:find("3ms")) then
		return true
	end

	if base.nopast and slot:find("^past_") then
		return true
	end
	if base.noimp and slot:find("^imp_") then
		return true
	end
	if base.no_nonpast and (slot:find("^ind_") or slot:find("^sub_") or slot:find("^juss")) then
		return true
	end

	return false
end

local function basic_combine_stem_ending(stem, ending)
	return stem .. ending
end

local function basic_combine_stem_ending_tr(stem, ending)
	return stem .. ending
end

-- Concatenate `prefixes`, `stems` and `endings` (any of which may be an abbreviate form list, i.e. strings, form
-- objects or lists of strings or form objects) and store into `slot`. If a user-supplied override exists for the slot,
-- nothing will happen unless `allow_overrides` is provided.
local function add3(base, slot, prefixes, stems, endings, allow_overrides)
	if skip_slot(base, slot, allow_overrides) then
		return
	end

	-- Optimization since the prefixes are almost always single strings.
	if type(prefixes) == "string" then
		local function do_combine_stem_ending(stem, ending)
			return prefixes .. stem .. ending
		end
		local function do_combine_stem_ending_tr(stem, ending)
			return transliterate(prefixes) .. stem .. ending
		end
		iut.add_forms(base.forms, slot, stems, endings, do_combine_stem_ending, transliterate,
			do_combine_stem_ending_tr, base.form_footnotes)
	else
		iut.add_multiple_forms(base.forms, slot, {prefixes, stems, endings}, basic_combine_stem_ending, transliterate,
			basic_combine_stem_ending_tr, base.form_footnotes)
	end
end

-- Insert one or more forms in `form_or_forms` into `slot`. `form_or_forms` is an abbreviated form list (see comment at
-- top of [[Module:inflection utilities]]). If a user-supplied override exists for the slot, nothing will happen unless
-- `allow_overrides` is provided. BEWARE: One form object should never occur in two different slots, or twice in a given
-- slot; if taking a form object from an existing slot, make sure to shallowcopy() it.
local function insert_form_or_forms(base, slot, form_or_forms, allow_overrides, uncertain)
	if not skip_slot(base, slot, allow_overrides) then
		-- Some optimizations of the most common case of inserting a single string.
		if type(form_or_forms) == "string" and not base.form_footnotes then
			form_or_forms = {form = form_or_forms, uncertain = uncertain}
			iut.insert_form(base.forms, slot, form_or_forms)
		else
			local list = iut.convert_to_general_list_form(form_or_forms, base.form_footnotes)
			if uncertain then
				for _, formobj in ipairs(list) do
					formobj.uncertain = true
				end
			end
			iut.insert_forms(base.forms, slot, list)
		end
	end
end

-- Insert `string_or_form` into both the ap2 and pp2 slots, shallowcopying a form object to make sure no form objects
-- occur in two slots.
local function insert_ap2_pp2(base, string_or_form)
	insert_form_or_forms(base, "ap2", string_or_form)
	if type(string_or_form) == "table" then
		string_or_form = m_table.shallowcopy(string_or_form)
	end
	insert_form_or_forms(base, "pp2", string_or_form)
end

-- Convert `stemforms` (a string, a form object, or a list of strings and/or form objects) into "general form" (a list
-- of form objects) and map `fn` over the list of objects. `fn` is passed two arguments (form value and translit) and
-- should likewise return the new form value and translit. Footnotes will be preserved. FIXME: Preserve other metadata.
local function map_general(stemforms, fn)
	return iut.map_forms(iut.convert_to_general_list_form(stemforms), fn)
end

-- Similar to map_general() except that `fn` should return a single value (one or more strings or form objects), instead
-- of two values (form value and translit), and the resulting value(s) from all calls to `fn` will be flattened to
-- construct the overall return value. Footnotes will be preserved. FIXME: Preserve other metadata.
local function flatmap_general(stemforms, fn)
	return iut.flatmap_forms(iut.convert_to_general_list_form(stemforms), fn)
end

-- Given user-supplied stem overrides in `base`, construct any derived stem overrides (e.g. vowel-specific or
-- consonant-specific variants), and truncate initial y-/ي- in any non-past overrides.
local function construct_stems(base)
	local stems = base.stem_overrides
	stems.past_v = stems.past_v or stems.past
	stems.past_c = stems.past_c or stems.past
	stems.past_pass_v = stems.past_pass_v or stems.past_pass
	stems.past_pass_c = stems.past_pass_c or stems.past_pass
	stems.nonpast_v = stems.nonpast_v or stems.nonpast
	stems.nonpast_c = stems.nonpast_c or stems.nonpast
	stems.nonpast_pass_v = stems.nonpast_pass_v or stems.nonpast_pass
	stems.nonpast_pass_c = stems.nonpast_pass_c or stems.nonpast_pass
	stems.imp_v = stems.imp_v or stems.imp
	stems.imp_c = stems.imp_c or stems.imp
	local function truncate_nonpast_initial_cons(stem_type, form, translit)
		if form == "+" then
			return form, translit
		end
		if not form:find("^" .. Y) then
			error(("Form value %s for stem type '%s' should begin with ي"):format(form, stem_type))
		end
		form = form:gsub("^" .. Y, "")
		if translit then
			if not translit:find("^y") then
				error(("Translit value %s for stem type '%s' should begin with y"):format(translit, stem_type))
			end
			translit = translit:gsub("^y", "")
		end
		return form, translit
	end
	for _, nonpast_stem_type in ipairs { "nonpast_v", "nonpast_c", "nonpast_pass_v", "nonpast_pass_c" } do
		if stems[nonpast_stem_type] then
			stems[nonpast_stem_type] = map_general(stems[nonpast_stem_type], function(form, translit)
				return truncate_nonpast_initial_cons(nonpast_stem_type, form, translit)
			end)
		end
	end
end

-- Given user-specified overrides for stem `stemname`, return overrides with occurrences of + replaced by
-- `default_stem`. If no overrides, return `default_stem`, or {} if no default.
local function override_stem_if_needed(base, stemname, default_stem)
	local overrides = base.stem_overrides[stemname]
	if not overrides then
		return default_stem or {}
	end
	return map_general(overrides, function(form, translit)
		if form ~= "+" and default_indicator_to_active_participle_slot[form] then
			error(("Stem overrides cannot use secondary default indicators but saw %s in stem override '%s'"):format(
				form, stemname))
		end
		if form == "+" then
			if translit then
				error(("Cannot supply manual translit along with + for stem override '%s'"):format(stemname))
			end
			if not default_stem then
				error(("Cannot use + for stem override '%s' because no default is available"):format(stemname))
			end
			if type(default_stem) ~= "string" then
				error(("Internal error: Default stem for '%s' is not a string: %s"):format(stemname, dump(default_stem)))
			end
			return default_stem
		end
		return form, translit
	end)
end		

-------------------------------------------------------------------------------
--                      Properties of different verbal forms                 --
-------------------------------------------------------------------------------

local allowed_vforms = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX",
	"X", "XI", "XII", "XIII", "XIV", "XV", "Iq", "IIq", "IIIq", "IVq"}
local allowed_vforms_set = m_table.listToSet(allowed_vforms)
local allowed_vforms_with_weakness = m_table.shallowcopy(allowed_vforms)

-- The user needs to be able to explicitly specify that a form-I verb (specifically one whose initial radical is و) is
-- sound. Cf. wajiʕa yawjaʕu (not #yajaʕu) "to ache, to hurt". In general, i~a and u~u verbs whose initial radical is و
-- seem to not assimilate the first radical; cf. وقح "to be shameless", variously waqaḥa~yaqiḥu, waquḥa~yawquḥu and
-- waqiḥa~yawqaḥu, whereas a~i verbs (wafaḍa~yafiḍu "to rush"), i~i verbs (wafiqa~yafiqu "to be proper, to be suitable")
-- and a~a verbs (waḍaʕa~yaḍaʕu "to set down, to place") do assimilate. But there are naturally exceptions, e.g.
-- waṭiʔa~yaṭaʔu "to tread, to trample"; wasiʕa~yasaʕu "to be spacious; to be well-off"; waṯiʔa~yaṯaʔu "to get bruised,
-- to be sprained". Also beware of waniya~yawnā "to be faint; to languish", which is sound in the first radical and
-- final-weak in the last radical. Nonetheless, the regularity of the patterns mentioned above suggest we should provide
-- them as defaults.

-- Note that there are other cases of unexpectedly sound verbs, e.g. izdawaja~yazdawiju "to be in pairs", layisa~yalyasu
-- "to be valiant, to be brave", ʔaḥwaja~yuḥwiju "to need", istahwana~yastahwinu "to consider easy", sawisa~yaswasu "to
-- be or become moth-eaten or worm-eaten" (vs. sāsa~yasūsu "to govern, to rule" from the same radicals), ʕawira~yaʕwaru
-- "to be one-eyed", istajwaba~yastajwibu "to interrogate", etc. But in these cases there is no need for explicit user
-- specification as the lemma itself specifies the unexpected soundness.
for _, form_with_weakness in ipairs { "I-sound", "I-assimilated", "none-sound", "none-hollow", "none-geminate",
	"none-final-weak" } do
	table.insert(allowed_vforms_with_weakness, form_with_weakness)
end
local allowed_vforms_with_weakness_set = m_table.listToSet(allowed_vforms_with_weakness)

local function vform_supports_final_weak(vform)
	return vform ~= "XI" and vform ~= "XV" and vform ~= "IVq"
end

local function vform_supports_geminate(vform)
	return vform == "I" or vform == "III" or vform == "IV" or vform == "VI" or vform == "VII" or vform == "VIII" or
		vform == "X"
end

local function vform_supports_hollow(vform)
	return vform == "I" or vform == "IV" or vform == "VII" or vform == "VIII" or vform == "X"
end

local function vform_probably_impersonal_passive(vform, weakness, past_vowel, nonpast_vowel)
	return vform == "I" and req(past_vowel, I) or vform == "V" or vform == "VI" or vform == "X" or vform == "IIq"
end

local function vform_probably_full_passive(vform)
	return vform == "II" or vform == "III" or vform == "IV" or vform == "Iq"
end

local function vform_probably_no_passive(vform, weakness, past_vowel, nonpast_vowel)
	return vform == "I" and req(past_vowel, U) or vform == "VII" or vform == "IX" or
	vform == "XI" or vform == "XII" or vform == "XIII" or vform == "XIV" or vform == "XV" or
	vform == "IIIq" or vform == "IVq"
end

-- Active vforms II, III, IV, Iq use non-past prefixes in -u- instead of -a-.
local function prefix_vowel_from_vform(vform)
	if vform == "II" or vform == "III" or vform == "IV" or vform == "Iq" then
		return "u"
	else
		return "a"
	end
end

-- True if the active non-past takes a-vocalization rather than i-vocalization in its last syllable.
local function vform_nonpast_a_vowel(vform)
	return vform == "V" or vform == "VI" or vform == "XV" or vform == "IIq"
end

-- True if the `passive` spec indicates a passive-only verb.
local function is_passive_only(passive)
	return passive == "onlypass" or passive == "onlypass-impers"
end
export.is_passive_only = is_passive_only -- for use in [[Module:ar-headword]]

-------------------------------------------------------------------------------
--                        Properties of specific sounds                      --
-------------------------------------------------------------------------------

-- Is radical wāw (و) or yāʾ (ي)?
local function is_waw_ya(rad)
	return req(rad, W) or req(rad, Y)
end

-- Check that radical is wāw (و) or yāʾ (ي), error if not
local function check_waw_ya(rad)
	if not is_waw_ya(rad) then
		error("Expecting weak radical: '" .. rget(rad) .. "' should be " .. W .. " or " .. Y)
	end
end

-- Form-I verb حيّ or حيي and form-X verb استحيا or استحى
local function hayy_radicals(rad1, rad2, rad3)
	return req(rad1, "ح") and req(rad2, Y) and is_waw_ya(rad3)
end

-- FUCK ME HARD. "Lua error at line 1514: main function has more than 200 local variables".
local function create_conjugations()
	-------------------------------------------------------------------------------
	--              Radicals associated with various irregular verbs             --
	-------------------------------------------------------------------------------

	-- Form-I verb أخذ or form-VIII verb اتخذ
	local function axadh_radicals(rad1, rad2, rad3)
		return req(rad1, HAMZA) and req(rad2, "خ") and req(rad3, "ذ")
	end

	-- Form-I verb whose imperative has a reduced form: أكل and أخذ and أمر. Return "shortonly" if only
	-- short-form imperatives exist (أكل and أخذ) or "shortlong" if long-form imperatives also exist (أمر);
	-- they are used after a clitic like فَ and وَ.
	local function reduced_imperative_verb(rad1, rad2, rad3)
		return axadh_radicals(rad1, rad2, rad3) and "shortonly" or
		req(rad1, HAMZA) and req(rad2, "ك") and req(rad3, "ل") and "shortonly" or
		req(rad1, HAMZA) and req(rad2, "م") and req(rad3, "ر") and "shortlong"
	end

	-- Form-I verb رأى and form-IV verb أرى
	local function raa_radicals(rad1, rad2, rad3)
		return req(rad1, "ر") and req(rad2, HAMZA) and is_waw_ya(rad3)
	end

	-- Form-I verb سأل
	local function saal_radicals(rad1, rad2, rad3)
		return req(rad1, "س") and req(rad2, HAMZA) and req(rad3, "ل")
	end

	-- Form-I verb كان
	local function kaan_radicals(rad1, rad2, rad3)
		return req(rad1, "ك") and req(rad2, W) and req(rad3, N)
	end

	-------------------------------------------------------------------------------
	--                               Sets of past endings                        --
	-------------------------------------------------------------------------------

	-- The 13 endings of the sound/hollow/geminate past tense.
	local past_endings = {
		-- singular
		SK .. TU, SK .. TA, SK .. "تِ", A, A .. "تْ",
		--dual
		SK .. "تُمَا", AA, A .. "تَا",
		-- plural
		SK .. "نَا", SK .. "تُمْ",
		-- shadda + vowel diacritic ends up in the wrong order due to Unicode
		-- bug, so keep them separate to avoid this
		SK .. "تُن" .. SH .. A, UU .. ALIF, SK .. "نَ"
	}

	-- Make endings for final-weak past in -aytu or -awtu. AYAW is AY or AW as appropriate. Note that AA and AW are
	-- global variables.
	local function make_past_endings_ay_aw(ayaw, third_sg_masc)
		return {
		-- singular
		ayaw .. SK .. TU, ayaw ..  SK .. TA, ayaw .. SK .. "تِ",
		third_sg_masc, A .. "تْ",
		--dual
		ayaw .. SK .. "تُمَا", ayaw .. AA, A .. "تَا",
		-- plural
		ayaw .. SK .. "نَا", ayaw .. SK .. "تُمْ",
		-- shadda + vowel diacritic ends up in the wrong order due to Unicode
		-- bug, so keep them separate to avoid this
		ayaw .. SK .. "تُن" .. SH .. A, AW .. SK .. ALIF, ayaw .. SK .. "نَ"
		}
	end

	-- past final-weak -aytu endings
	local past_endings_ay = make_past_endings_ay_aw(AY, AAMAQ)
	-- past final-weak -awtu endings
	local past_endings_aw = make_past_endings_ay_aw(AW, AA)

	-- used for alternative endings for form-X geminate verbs like اِسْتَمَرَّ
	local past_endings_ay_12_person_only = {
		-- singular
		AY .. SK .. TU, AY ..  SK .. TA, AY .. SK .. "تِ",
		{}, {},
		--dual
		AY .. SK .. "تُمَا", {}, {},
		-- plural
		AY .. SK .. "نَا", AY .. SK .. "تُمْ",
		-- shadda + vowel diacritic ends up in the wrong order due to Unicode
		-- bug, so keep them separate to avoid this
		AY .. SK .. "تُن" .. SH .. A, {}, {},
	}

	-- Make endings for final-weak past in -ītu or -ūtu. IIUU is ī or ū as appropriate. Note that AA and UU are global
	-- variables.
	local function make_past_endings_ii_uu(iiuu)
		return {
		-- singular
		iiuu .. TU, iiuu .. TA, iiuu .. "تِ", iiuu .. A, iiuu .. A .. "تْ",
		--dual
		iiuu .. "تُمَا", iiuu .. AA, iiuu .. A .. "تَا",
		-- plural
		iiuu .. "نَا", iiuu .. "تُمْ",
		-- shadda + vowel diacritic ends up in the wrong order due to Unicode
		-- bug, so keep them separate to avoid this
		iiuu .. "تُن" .. SH .. A, UU .. ALIF, iiuu .. "نَ"
		}
	end

	-- past final-weak -ītu endings
	local past_endings_ii = make_past_endings_ii_uu(II)
	-- past final-weak -ūtu endings
	local past_endings_uu = make_past_endings_ii_uu(UU)

	-------------------------------------------------------------------------------
	--                    Sets of non-past prefixes and endings                  --
	-------------------------------------------------------------------------------

	local nonpast_prefix_consonants = {
		-- singular
		HAMZA, T, T, Y, T,
		-- dual
		T, Y, T,
		-- plural
		N, T, T, Y, Y
	}

	-- There are only five distinct endings in all non-past verbs. Make any set of non-past endings given these five
	-- distinct endings.
	local function make_nonpast_endings(null, fem, dual, pl, fempl)
		return {
			-- singular
			null, null, fem, null, null,
			-- dual
			dual, dual, dual,
			-- plural
			null, pl, fempl, pl, fempl
		}
	end

	-- endings for non-past indicative
	local ind_endings = make_nonpast_endings(
		U,
		II .. NA,
		AANI,
		UU .. NA,
		SK .. NA
	)

	-- Make the endings for non-past subjunctive/jussive, given the vowel diacritic used in "null" endings
	-- (1s/2ms/3ms/3fs/1p).
	local function make_sub_juss_endings(dia_null)
		return make_nonpast_endings(
		dia_null,
		II,
		AA,
		UU .. ALIF,
		SK .. NA
		)
	end

	-- endings for non-past subjunctive
	local sub_endings = make_sub_juss_endings(A)

	-- endings for non-past jussive
	local juss_endings = make_sub_juss_endings(SK)

	-- endings for alternative geminate non-past jussive in -a; same as subjunctive
	local juss_endings_alt_a = sub_endings

	-- endings for alternative geminate non-past jussive in -i
	local juss_endings_alt_i = make_sub_juss_endings(I)

	-- Endings for final-weak non-past indicative in -ā. Note that AY, AW and AAMAQ are global variables.
	local ind_endings_aa = make_nonpast_endings(
		AAMAQ,
		AYSK .. NA,
		AY .. AANI,
		AWSK .. NA,
		AYSK .. NA
	)

	-- Make endings for final-weak non-past indicative in -ī or -ū; IIUU is ī or ū as appropriate. Note that II and UU
	-- are global variables.
	local function make_ind_endings_ii_uu(iiuu)
		return make_nonpast_endings(
			iiuu,
			II .. NA,
			iiuu .. AANI,
			UU .. NA,
			iiuu .. NA
		)
	end

	-- endings for final-weak non-past indicative in -ī
	local ind_endings_ii = make_ind_endings_ii_uu(II)

	-- endings for final-weak non-past indicative in -ū
	local ind_endings_uu = make_ind_endings_ii_uu(UU)

	-- Endings for final-weak non-past subjunctive in -ā. Note that AY, AW, ALIF, AAMAQ are global variables.
	local sub_endings_aa = make_nonpast_endings(
		AAMAQ,
		AYSK,
		AY .. AA,
		AWSK .. ALIF,
		AYSK .. NA
	)

	-- Make endings for final-weak non-past subjunctive in -ī or -ū. IIUU is ī or ū as appropriate. Note that AA, II,
	-- UU, ALIF are global variables.
	local function make_sub_endings_ii_uu(iiuu)
		return make_nonpast_endings(
			iiuu .. A,
			II,
			iiuu .. AA,
			UU .. ALIF,
			iiuu .. NA
		)
	end

	-- endings for final-weak non-past subjunctive in -ī
	local sub_endings_ii = make_sub_endings_ii_uu(II)

	-- endings for final-weak non-past subjunctive in -ū
	local sub_endings_uu = make_sub_endings_ii_uu(UU)

	-- endings for final-weak non-past jussive in -ā
	local juss_endings_aa = make_nonpast_endings(
		A,
		AYSK,
		AY .. AA,
		AWSK .. ALIF,
		AYSK .. NA
	)

	-- Make endings for final-weak non-past jussive in -ī or -ū. IU is short i or u, IIUU is long ī or ū as appropriate.
	-- Note that AA, II, UU, ALIF are global variables.
	local function make_juss_endings_ii_uu(iu, iiuu)
		return make_nonpast_endings(
			iu,
			II,
			iiuu .. AA,
			UU .. ALIF,
			iiuu .. NA
		)
	end

	-- endings for final-weak non-past jussive in -ī
	local juss_endings_ii = make_juss_endings_ii_uu(I, II)

	-- endings for final-weak non-past jussive in -ū
	local juss_endings_uu = make_juss_endings_ii_uu(U, UU)

	-------------------------------------------------------------------------------
	--                           Sets of imperative endings                      --
	-------------------------------------------------------------------------------

	-- Extract the second person jussive endings to get corresponding imperative endings.
	local function imperative_endings_from_jussive(endings)
		return {endings[2], endings[3], endings[6], endings[10], endings[11]}
	end

	-- normal imperative endings
	local imp_endings = imperative_endings_from_jussive(juss_endings)
	-- alternative geminate imperative endings in -a
	local imp_endings_alt_a = imperative_endings_from_jussive(juss_endings_alt_a)
	-- alternative geminate imperative endings in -i
	local imp_endings_alt_i = imperative_endings_from_jussive(juss_endings_alt_i)
	-- final-weak imperative endings in -ā
	local imp_endings_aa = imperative_endings_from_jussive(juss_endings_aa)
	-- final-weak imperative endings in -ī
	local imp_endings_ii = imperative_endings_from_jussive(juss_endings_ii)
	-- final-weak imperative endings in -ū
	local imp_endings_uu = imperative_endings_from_jussive(juss_endings_uu)

	-------------------------------------------------------------------------------
	--                        Basic functions to inflect tenses                  --
	-------------------------------------------------------------------------------

	-- Add to `base` the inflections for the tense indicated by `tense` (the prefix in the slot names, e.g. 'past'
	-- or 'juss_pass'), formed by combining the `prefixes`, `stems` and `endings`. Each of `prefixes`, `stems` and
	-- `endings` is either a sequence of 5 (for the imperative) or 13 (for other tenses) abbreviated form lists (each of
	-- which is either a string, a form object, or a list of strings and/or form objects; see
	-- [[Module:inflection utilities]] for more info). Alternatively, any of `prefixes`, `stems` or `endings` can be a
	-- single-element list containing an abbreviated form list, with an additional key `all_same` set to true, or (as a
	-- special case) a single string; in the latter cases, the same value is used for all 5 or 13 slots. If existing
	-- inflections already exist, they will be added to, not overridden. `pnums` is the list of person/number slot name
	-- suffixes, which must match up with the elements in `prefixes`, `stems` and `endings` (i.e. 5 for imperative, 13
	-- otherwise).
	local function inflect_tense_1(base, tense, prefixes, stems, endings, pnums)
		if not prefixes or not stems or not endings then
			return
		end
		local function verify_affixes(affixname, affixes)
			local function interr(msg)
				error(("Internal error: For tense '%s', '%s' %s: %s"):format(tense, affixname, msg, dump(affixes)))
			end
			if type(affixes) == "string" then
				-- do nothing
			elseif type(affixes) ~= "table" then
				interr("is not a table or string")
			elseif affixes.all_same then
				if #affixes ~= 1 then
					interr(("with all_same = true should have length 1 but has length %s"):format(#affixes))
				end
			else
				if #affixes ~= #pnums then
					interr(("should have length %s but has length %s"):format(#pnums, #affixes))
				end
			end
		end

		verify_affixes("prefixes", prefixes)
		verify_affixes("stems", stems)
		verify_affixes("endings", endings)

		local function get_affix(affixes, i)
			if type(affixes) == "string" then
				return affixes
			elseif affixes.all_same then
				return affixes[1]
			else
				return affixes[i]
			end
		end

		for i, pnum in ipairs(pnums) do
			local prefix = get_affix(prefixes, i)
			local stem = get_affix(stems, i)
			local ending = get_affix(endings, i)
			local slot = tense .. "_" .. pnum
			add3(base, slot, prefix, stem, ending)
		end
	end

	-- Add to `base` the inflections for the tense indicated by `tense` (the prefix in the slot names, e.g. 'past'
	-- or 'juss_pass'), formed by combining the `prefixes`, `stems` and `endings`. This is a simple wrapper around
	-- inflect_tense_1() that applies to all tenses other than the imperative; see inflect_tense_1() for more
	-- information about the parameters.
	local function inflect_tense(base, tense, prefixes, stems, endings)
		inflect_tense_1(base, tense, prefixes, stems, endings, all_person_number_list)
	end

	-- Like inflect_tense() but for the imperative, which has only five parts instead of 13 and no prefixes.
	local function inflect_tense_imp(base, stems, endings)
		inflect_tense_1(base, "imp", "", stems, endings, imp_person_number_list)
	end

	-------------------------------------------------------------------------------
	--                      Functions to inflect the past tense                  --
	-------------------------------------------------------------------------------

	-- Generate past verbs using specified vowel and consonant stems; works for sound, assimilated, hollow, and geminate
	-- verbs, active and passive.
	local function past_2stem_conj(base, tense, v_stem, c_stem, footnote_12)
		local passive = tense:find("_pass") and "_pass" or ""
		-- Override stems with user-specified stems if available.
		v_stem = override_stem_if_needed(base, "past" .. passive .. "_v", v_stem)
		local c_stem_12 = c_stem
		if footnote_12 then
			c_stem_12 = iut.combine_form_and_footnotes(c_stem_12, footnote_12)
		end
		c_stem_12 = override_stem_if_needed(base, "past" .. passive .. "_c", c_stem_12)
		local c_stem_3 = override_stem_if_needed(base, "past" .. passive .. "_c", c_stem)
		inflect_tense(base, tense, "", {
			-- singular
			c_stem_12, c_stem_12, c_stem_12, v_stem, v_stem,
			--dual
			c_stem_12, v_stem, v_stem,
			-- plural
			c_stem_12, c_stem_12, c_stem_12, v_stem, c_stem_3
		}, past_endings)
	end

	-- Generate past verbs using single specified stem; works for sound and assimilated verbs, active and passive.
	local function past_1stem_conj(base, tense, stem)
		past_2stem_conj(base, tense, stem, stem)
	end

	-------------------------------------------------------------------------------
	--                     Functions to inflect non-past tenses                  --
	-------------------------------------------------------------------------------

	-- Generate non-past conjugation, with two stems, for vowel-initial and consonant-initial endings, respectively.
	-- Useful for active and passive; for all forms; for all weaknesses (sound, assimilated, hollow, final-weak and
	-- geminate) and for all types of non-past (indicative, subjunctive, jussive) except for the imperative. (There is a
	-- separate wrapper function below for geminate jussives because they have three alternants.) Both stems may be the
	-- same, e.g. for sound verbs.

	-- `prefix_vowel` will be either "a" or "u". `endings` should be an array of 13 items. If `endings` is nil or
	-- omitted, infer the endings from the tense. If `jussive` is true, or `endings` is nil and `tense` indicatives
	-- jussive, use the jussive pattern of vowel/consonant stems (different from the normal ones).
	local function nonpast_2stem_conj(base, tense, prefix_vowel, v_stem, c_stem, endings, jussive)
		local passive = tense:find("_pass") and "_pass" or ""
		-- Override stems with user-specified stems if available.
		v_stem = override_stem_if_needed(base, "nonpast" .. passive .. "_v",
			v_stem and q(dia[prefix_vowel], v_stem) or nil)
		c_stem = override_stem_if_needed(base, "nonpast" .. passive .. "_c",
			c_stem and q(dia[prefix_vowel], c_stem) or nil)
		if not endings then
			if tense:find("^ind") then
				endings = ind_endings
			elseif tense:find("^sub") then
				endings = sub_endings
			elseif tense:find("^juss") then
				jussive = true
				endings = juss_endings
			else
				error("Internal error: Unrecognized tense '" .. tense .."'")
			end
		end
		if not jussive then
			inflect_tense(base, tense, nonpast_prefix_consonants, {
				-- singular
				v_stem, v_stem, v_stem, v_stem, v_stem,
				--dual
				v_stem, v_stem, v_stem,
				-- plural
				v_stem, v_stem, c_stem, v_stem, c_stem
			}, endings)
		else
			inflect_tense(base, tense, nonpast_prefix_consonants, {
				-- singular
				-- 'adlul, tadlul, tadullī, yadlul, tadlul
				c_stem, c_stem, v_stem, c_stem, c_stem,
				--dual
				-- tadullā, yadullā, tadullā
				v_stem, v_stem, v_stem,
				-- plural
				-- nadlul, tadullū, tadlulna, yadullū, yadlulna
				c_stem, v_stem, c_stem, v_stem, c_stem
			}, endings)
		end
	end

	-- Generate non-past conjugation with one stem (no distinct stems for vowel-initial and consonant-initial endings).
	-- See nonpast_2stem_conj().
	local function nonpast_1stem_conj(base, tense, prefix_vowel, stem, endings, jussive)
		nonpast_2stem_conj(base, tense, prefix_vowel, stem, stem, endings, jussive)
	end

	-- Generate active/passive jussive geminative. There are three alternants, two with terminations -a and -i and one
	-- in a null termination with a distinct pattern of vowel/consonant stem usage. See nonpast_2stem_conj() for a
	-- description of the arguments.
	local function jussive_gem_conj(base, tense, prefix_vowel, v_stem, c_stem)
		-- alternative in -a
		nonpast_2stem_conj(base, tense, prefix_vowel, v_stem, c_stem, juss_endings_alt_a)
		-- alternative in -i
		nonpast_2stem_conj(base, tense, prefix_vowel, v_stem, c_stem, juss_endings_alt_i)
		-- alternative in -null; requires different combination of v_stem and
		-- c_stem since the null endings require the c_stem (e.g. "tadlul" here)
		-- whereas the corresponding endings above in -a or -i require the v_stem
		-- (e.g. "tadulla, tadulli" above)
		nonpast_2stem_conj(base, tense, prefix_vowel, v_stem, c_stem, juss_endings, "jussive")
	end

	-------------------------------------------------------------------------------
	--                    Functions to inflect the imperative                    --
	-------------------------------------------------------------------------------

	-- Generate imperative conjugation, with two stems, for vowel-initial and consonant-initial endings, respectively.
	-- Useful for all forms, and for all weaknesses other than final-weak. Note that the two stems may be the same
	-- (specifically for sound and assimilated verbs). If `endings` is nil or omitted, use `imp_endings`. If `alt_gem`
	-- is specified, use the pattern of vowel and consonant stems appropriate for the alternative geminate imperatives
	-- that use a null ending of -a or -i instead of an empty ending.
	local function make_2stem_imperative(base, v_stem, c_stem, endings, alt_gem)
		endings = endings or imp_endings
		-- Override stems with user-specified stems if available.
		v_stem = override_stem_if_needed(base, "imp_v", v_stem)
		c_stem = override_stem_if_needed(base, "imp_c", c_stem)
		if alt_gem then
			inflect_tense_imp(base, {v_stem, v_stem, v_stem, v_stem, c_stem}, endings)
		else
			inflect_tense_imp(base, {c_stem, v_stem, v_stem, v_stem, c_stem}, endings)
		end
	end

	-- Generate imperative parts for sound or assimilated verbs.
	local function make_1stem_imperative(base, stem)
		make_2stem_imperative(base, stem, stem)
	end

	-- Generate imperative parts for geminate verbs form I (also IV, VII, VIII, X).
	local function make_gem_imperative(base, v_stem, c_stem)
		make_2stem_imperative(base, v_stem, c_stem, imp_endings_alt_a, "alt gem")
		make_2stem_imperative(base, v_stem, c_stem, imp_endings_alt_i, "alt gem")
		make_2stem_imperative(base, v_stem, c_stem)
	end

	-------------------------------------------------------------------------------
	--                    Functions to inflect entire verbs                      --
	-------------------------------------------------------------------------------

	-- Generate finite parts of a sound verb (also works for assimilated verbs) from five stems (past and non-past,
	-- active and passive, plus imperative) plus the prefix vowel in the active non-past ("a" or "u").
	local function make_sound_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem,
			prefix_vowel)
		past_1stem_conj(base, "past", past_stem)
		past_1stem_conj(base, "past_pass", past_pass_stem)
		nonpast_1stem_conj(base, "ind", prefix_vowel, nonpast_stem)
		nonpast_1stem_conj(base, "sub", prefix_vowel, nonpast_stem)
		nonpast_1stem_conj(base, "juss", prefix_vowel, nonpast_stem)
		nonpast_1stem_conj(base, "ind_pass", "u", nonpast_pass_stem)
		nonpast_1stem_conj(base, "sub_pass", "u", nonpast_pass_stem)
		nonpast_1stem_conj(base, "juss_pass", "u", nonpast_pass_stem)
		make_1stem_imperative(base, imp_stem)
	end

	local function past_final_weak_endings_from_vowel(vowel)
		if vowel == "ay" then
			return past_endings_ay
		elseif vowel == "aw" then
			return past_endings_aw
		elseif vowel == "ī" then
			return past_endings_ii
		elseif vowel == "ū" then
			return past_endings_uu
		elseif not vowel then
			return nil
		else
			error(("Internal error: Unrecognized past final-weak vowel spec '%s'"):format(vowel))
		end
	end

	local function nonpast_final_weak_endings_from_vowel(vowel)
		if vowel == "ā" then
			return ind_endings_aa, sub_endings_aa, juss_endings_aa, imp_endings_aa
		elseif vowel == "ī" then
			return ind_endings_ii, sub_endings_ii, juss_endings_ii, imp_endings_ii
		elseif vowel == "ū" then
			return ind_endings_uu, sub_endings_uu, juss_endings_uu, imp_endings_uu
		elseif not vowel then
			return nil
		else
			error(("Internal error: Unrecognized non-past final-weak vowel spec '%s'"):format(vowel))
		end
	end

	-- Generate finite parts of a final-weak verb from five stems (past and non-past, active and passive, plus
	-- imperative), the past active ending vowel (ay, aw, ī or ū), the non-past active ending vowel (ā, ī or ū) and the
	-- prefix vowel in the active non-past (a or u).
	local function make_final_weak_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem,
			past_ending_vowel, nonpast_ending_vowel, prefix_vowel)
		past_stem = override_stem_if_needed(base, "past", past_stem)
		past_pass_stem = override_stem_if_needed(base, "past_pass", past_pass_stem)
		-- Don't call override_stem_if_needed() here for non-past stems; it's called in nonpast_2stem_conj().
		imp_stem = override_stem_if_needed(base, "imp", imp_stem)
		-- + not supported for ending vowel overrides
		past_ending_vowel = base.stem_overrides.past_final_weak_vowel or past_ending_vowel
		local past_pass_ending_vowel = base.stem_overrides.past_pass_final_weak_vowel or "ī"
		nonpast_ending_vowel = base.stem_overrides.nonpast_final_weak_vowel or nonpast_ending_vowel
		local nonpast_pass_ending_vowel = base.stem_overrides.nonpast_pass_final_weak_vowel or "ā"
		local past_endings = past_final_weak_endings_from_vowel(past_ending_vowel)
		local past_pass_endings = past_final_weak_endings_from_vowel(past_pass_ending_vowel)
		local ind_endings, sub_endings, juss_endings, imp_endings =
			nonpast_final_weak_endings_from_vowel(nonpast_ending_vowel)
		local ind_pass_endings, sub_pass_endings, juss_pass_endings =
			nonpast_final_weak_endings_from_vowel(nonpast_pass_ending_vowel)

		inflect_tense(base, "past", "", {past_stem, all_same = 1}, past_endings)
		inflect_tense(base, "past_pass", "", {past_pass_stem, all_same = 1}, past_pass_endings)
		nonpast_1stem_conj(base, "ind", prefix_vowel, nonpast_stem, ind_endings)
		nonpast_1stem_conj(base, "sub", prefix_vowel, nonpast_stem, sub_endings)
		nonpast_1stem_conj(base, "juss", prefix_vowel, nonpast_stem, juss_endings)
		nonpast_1stem_conj(base, "ind_pass", "u", nonpast_pass_stem, ind_pass_endings)
		nonpast_1stem_conj(base, "sub_pass", "u", nonpast_pass_stem, sub_pass_endings)
		nonpast_1stem_conj(base, "juss_pass", "u", nonpast_pass_stem, juss_pass_endings)
		inflect_tense_imp(base, {imp_stem, all_same = 1}, imp_endings)
	end

	-- Generate finite parts of an augmented (form II+) final-weak verb from five stems (past and non-past, active and
	-- passive, plus imperative) plus the prefix vowel in the active non-past ("a" or "u") and a flag indicating if it
	-- behaves like a form V/VI verb in taking non-past endings in -ā instead of -ī.
	local function make_augmented_final_weak_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem,
		imp_stem, prefix_vowel, form56)
		make_final_weak_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem, "ay",
			form56 and "ā" or "ī", prefix_vowel)
	end

	-- Generate finite parts of an augmented (form II+) sound or final-weak verb, given:
	-- * `base` (conjugation data structure);
	-- * `vowel_spec` (radicals, weakness);
	-- * `past_stem_base` (active past stem minus last syllable (= -al or -ā));
	-- * `nonpast_stem_base` (non-past stem minus last syllable (= -al/-il or -ā/-ī);
	-- * `past_pass_stem_base` (passive past stem minus last syllable (= -il or -ī));
	-- * `vn` (verbal noun).
	local function make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base,
		past_pass_stem_base, vn)
		insert_form_or_forms(base, "vn", vn)

		local lastrad = base.quadlit and vowel_spec.rad4 or vowel_spec.rad3
		local final_weak = is_final_weak(base, vowel_spec)
		local prefix_vowel = prefix_vowel_from_vform(base.verb_form)
		local form56 = vform_nonpast_a_vowel(base.verb_form)
		local a_base_suffix = final_weak and "" or q(A, lastrad)
		local i_base_suffix = final_weak and "" or q(I, lastrad)

		-- past and non-past stems, active and passive
		local past_stem = q(past_stem_base, a_base_suffix)
		-- In forms 5 and 6, non-past has /a/ as last stem vowel in the non-past
		-- in both active and passive, but /i/ in the active participle and /a/
		-- in the passive participle. Elsewhere, consistent /i/ in active non-past
		-- and participle, consistent /a/ in passive non-past and participle.
		-- Hence, forms 5 and 6 differ only in the non-past active (but not
		-- active participle), so we have to split the finite non-past stem and
		-- active participle stem.
		local nonpast_stem = q(nonpast_stem_base, form56 and a_base_suffix or i_base_suffix)
		local ap_stem = q(nonpast_stem_base, i_base_suffix)
		local past_pass_stem = q(past_pass_stem_base, i_base_suffix)
		local nonpast_pass_stem = q(nonpast_stem_base, a_base_suffix)
		-- imperative stem
		local imp_stem = q(past_stem_base, form56 and a_base_suffix or i_base_suffix)

		-- make parts
		if final_weak then
			make_augmented_final_weak_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem,
				prefix_vowel, form56)
		else
			make_sound_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem, prefix_vowel)
		end

		-- active and passive participle
		if final_weak then
			insert_form_or_forms(base, "ap", q(MU, ap_stem, IN))
			insert_form_or_forms(base, "pp", q(MU, nonpast_pass_stem, AN, AMAQ))
		else
			insert_form_or_forms(base, "ap", q(MU, ap_stem))
			insert_form_or_forms(base, "pp", q(MU, nonpast_pass_stem))
		end
	end

	-- Generate finite parts of a hollow or geminate verb from ten stems (vowel and consonant stems for each of past and
	-- non-past, active and passive, plus imperative) plus the prefix vowel in the active non-past ("a" or "u"), plus a
	-- flag indicating if we are a geminate verb.
	local function make_hollow_geminate_verb(base, geminate, past_v_stem, past_c_stem, past_pass_v_stem,
			past_pass_c_stem, nonpast_v_stem, nonpast_c_stem, nonpast_pass_v_stem, nonpast_pass_c_stem, imp_v_stem,
			imp_c_stem, prefix_vowel, altgem_note)
		past_2stem_conj(base, "past", past_v_stem, past_c_stem, altgem_note)
		past_2stem_conj(base, "past_pass", past_pass_v_stem, past_pass_c_stem)
		nonpast_2stem_conj(base, "ind", prefix_vowel, nonpast_v_stem, nonpast_c_stem)
		nonpast_2stem_conj(base, "sub", prefix_vowel, nonpast_v_stem, nonpast_c_stem)
		nonpast_2stem_conj(base, "ind_pass", "u", nonpast_pass_v_stem, nonpast_pass_c_stem)
		nonpast_2stem_conj(base, "sub_pass", "u", nonpast_pass_v_stem, nonpast_pass_c_stem)
		if geminate then
			jussive_gem_conj(base, "juss", prefix_vowel, nonpast_v_stem, nonpast_c_stem)
			jussive_gem_conj(base, "juss_pass", "u", nonpast_pass_v_stem, nonpast_pass_c_stem)
			make_gem_imperative(base, imp_v_stem, imp_c_stem)
		else
			nonpast_2stem_conj(base, "juss", prefix_vowel, nonpast_v_stem, nonpast_c_stem)
			nonpast_2stem_conj(base, "juss_pass", "u", nonpast_pass_v_stem, nonpast_pass_c_stem)
			make_2stem_imperative(base, imp_v_stem, imp_c_stem)
		end
	end

	-- Generate finite parts of an augmented (form II+) hollow verb, given:
	-- * `base` (conjugation data structure);
	-- * `vowel_spec` (radicals, weakness);
	-- * `past_stem_base` (invariable part of active past stem);
	-- * `nonpast_stem_base` (invariable part of nonpast stem);
	-- * `past_pass_stem_base` (invariable part of passive past stem);
	-- * `vn` (verbal noun).
	local function make_augmented_hollow_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
		insert_form_or_forms(base, "vn", vn)

		local lastrad = base.quadlit and vowel_spec.rad4 or vowel_spec.rad3
		local form410 = base.verb_form == "IV" or base.verb_form == "X"
		local prefix_vowel = prefix_vowel_from_vform(base.verb_form)

		local a_base_suffix_v, a_base_suffix_c
		local i_base_suffix_v, i_base_suffix_c

		a_base_suffix_v = q(AA, lastrad)     -- 'af-āl-a, inf-āl-a
		a_base_suffix_c = q(A, lastrad)      -- 'af-al-tu, inf-al-tu
		i_base_suffix_v = q(II, lastrad)     -- 'uf-īl-a, unf-īl-a
		i_base_suffix_c = q(I, lastrad)      -- 'uf-il-tu, unf-il-tu

		-- past and non-past stems, active and passive, for vowel-initial and
		-- consonant-initial endings
		local past_v_stem = q(past_stem_base, a_base_suffix_v)
		local past_c_stem = q(past_stem_base, a_base_suffix_c)
		-- yu-f-īl-u, ya-staf-īl-u but yanf-āl-u, yaft-āl-u
		local nonpast_v_stem = q(nonpast_stem_base, form410 and i_base_suffix_v or a_base_suffix_v)
		local nonpast_c_stem = q(nonpast_stem_base, form410 and i_base_suffix_c or a_base_suffix_c)
		local past_pass_v_stem = q(past_pass_stem_base, i_base_suffix_v)
		local past_pass_c_stem = q(past_pass_stem_base, i_base_suffix_c)
		local nonpast_pass_v_stem = q(nonpast_stem_base, a_base_suffix_v)
		local nonpast_pass_c_stem = q(nonpast_stem_base, a_base_suffix_c)

		-- imperative stem
		local imp_v_stem = q(past_stem_base, form410 and i_base_suffix_v or a_base_suffix_v)
		local imp_c_stem = q(past_stem_base, form410 and i_base_suffix_c or a_base_suffix_c)

		-- make parts
		make_hollow_geminate_verb(base, false, past_v_stem, past_c_stem, past_pass_v_stem,
			past_pass_c_stem, nonpast_v_stem, nonpast_c_stem, nonpast_pass_v_stem,
			nonpast_pass_c_stem, imp_v_stem, imp_c_stem, prefix_vowel)

		-- active participle
		insert_form_or_forms(base, "ap", q(MU, nonpast_v_stem))
		-- passive participle
		insert_form_or_forms(base, "pp", q(MU, nonpast_pass_v_stem))
	end

	-- Generate finite parts of an augmented (form II+) geminate verb, given:
	-- * `base` (conjugation data structure);
	-- * `vowel_spec` (radicals, weakness);
	-- * `past_stem_base` (invariable part of active past stem; this and the stem bases below will end with a consonant
	--                     for forms IV, X, IVq, and a short vowel for the others);
	-- * `nonpast_stem_base` (invariable part of nonpast stem);
	-- * `past_pass_stem_base` (invariable part of passive past stem);
	-- * `vn` (verbal noun);
	-- * `altgem_note` (footnote to add to active past 1/2-person forms, when alternative forms are supplied [form X]).
	local function make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base,
			past_pass_stem_base, vn, altgem_note)
		insert_form_or_forms(base, "vn", vn)

		local vform = base.verb_form
		local lastrad = base.quadlit and vowel_spec.rad4 or vowel_spec.rad3
		local prefix_vowel = prefix_vowel_from_vform(vform)

		local a_base_suffix_v, a_base_suffix_c
		local i_base_suffix_v, i_base_suffix_c

		if vform == "IV" or vform == "X" or vform == "IVq" then
			a_base_suffix_v = q(A, lastrad, SH)           -- 'af-all
			a_base_suffix_c = q(SK, lastrad, A, lastrad)  -- 'af-lal
			i_base_suffix_v = q(I, lastrad, SH)           -- yuf-ill
			i_base_suffix_c = q(SK, lastrad, I, lastrad)  -- yuf-lil
		else
			a_base_suffix_v = q(lastrad, SH)              -- fā-ll, infa-ll
			a_base_suffix_c = q(lastrad, A, lastrad)      -- fā-lal, infa-lal
			i_base_suffix_v = q(lastrad, SH)              -- yufā-ll, yanfa-ll
			i_base_suffix_c = q(lastrad, I, lastrad)      -- yufā-lil, yanfa-lil
		end

		-- past and non-past stems, active and passive, for vowel-initial and
		-- consonant-initial endings
		local past_v_stem = q(past_stem_base, a_base_suffix_v)
		local past_c_stem = q(past_stem_base, a_base_suffix_c)
		local nonpast_v_stem = q(nonpast_stem_base, vform_nonpast_a_vowel(vform) and a_base_suffix_v or i_base_suffix_v)
		local nonpast_c_stem = q(nonpast_stem_base, vform_nonpast_a_vowel(vform) and a_base_suffix_c or i_base_suffix_c)
		-- NOTE: Formerly had a comment that "vform III and VI passive past do not have contracted parts, only
		-- uncontracted parts, which are added separately by those functions". This is based on Mace
		-- "Arabic Verbs and Essential Grammar" (1999) entry 63 (continued), which shows passive ḥūjija but no ḥūjja;
		-- but that is apparently a mistake, as (1) verb tables in other books do show contracted passive parts for
		-- these forms; (2) there is no mention of such an exception on p. 99, which explains how geminate ("doubled")
		-- verbs work (on the contrary, it says "The contracted and uncontracted pairs (see above) are found all
		-- over Forms III and VI of the doubled verbs").
		local past_pass_v_stem = q(past_pass_stem_base, i_base_suffix_v)
		local past_pass_c_stem = q(past_pass_stem_base, i_base_suffix_c)
		local nonpast_pass_v_stem = q(nonpast_stem_base, a_base_suffix_v)
		local nonpast_pass_c_stem = q(nonpast_stem_base, a_base_suffix_c)

		-- imperative stem
		local imp_v_stem = q(past_stem_base, vform_nonpast_a_vowel(vform) and a_base_suffix_v or i_base_suffix_v)
		local imp_c_stem = q(past_stem_base, vform_nonpast_a_vowel(vform) and a_base_suffix_c or i_base_suffix_c)

		-- make parts
		make_hollow_geminate_verb(base, "geminate", past_v_stem, past_c_stem, past_pass_v_stem,
			past_pass_c_stem, nonpast_v_stem, nonpast_c_stem, nonpast_pass_v_stem,
			nonpast_pass_c_stem, imp_v_stem, imp_c_stem, prefix_vowel, altgem_note)

		-- active participle
		insert_form_or_forms(base, "ap", q(MU, nonpast_v_stem))
		-- passive participle
		insert_form_or_forms(base, "pp", q(MU, nonpast_pass_v_stem))
	end

	-------------------------------------------------------------------------------
	--            Conjugation functions for specific conjugation types           --
	-------------------------------------------------------------------------------

	local function form_i_imp_stem_through_rad1(base, nonpast_vowel, rad1)
		local imp_vowel = map_vowel(nonpast_vowel, function(vow)
			if vow == A or vow == I then
				return I
			elseif vow == U then
				return U
			elseif not skip_slot(base, "imp_2ms") then
				error(("Internal error: Non-past vowel %s isn't a, i, or u, should have been caught earlier"):format(
					dump(nonpast_vowel)))
			else
				-- Passive-only; imperative won't ever be displayed so it doesn't matter.
				return I
			end
		end)

		-- Mace ("Arabic Verbs and Essentials of Grammar" p. 63: [https://archive.org/details/arabicverbsessen00john/page/62/mode/2up])
		-- claims that initial hamza is assimilated/elided into a long vowel in the form-I imperative, but apparently
		-- this isn't corrrect.
		local vowel_on_alif = map_vowel(imp_vowel, function(vow)
			return ALIF .. vow
		end)
		return q(vowel_on_alif, rad1, SK)
	end

	-- Implement form-I sound or assimilated verb. ASSIMILATED is true for assimilated verbs.
	local function make_form_i_sound_assimilated_verb(base, vowel_spec, assimilated)
		local rad1, rad2, rad3, past_vowel, nonpast_vowel = get_radicals_3(vowel_spec)

		-- Verbal nouns (maṣādir) for form I are unpredictable and have to be supplied

		-- past and non-past stems, active and passive
		local past_stem = q(rad1, A, rad2, past_vowel, rad3)
		local nonpast_stem = assimilated and q(rad2, nonpast_vowel, rad3) or
			q(rad1, SK, rad2, nonpast_vowel, rad3)
		local past_pass_stem = q(rad1, U, rad2, I, rad3)
		local nonpast_pass_stem = q(rad1, SK, rad2, A, rad3)

		-- imperative stem
		-- check for irregular verb with reduced imperative (أَخَذَ or أَكَلَ or أَمَرَ)
		local reducedimp = reduced_imperative_verb(rad1, rad2, rad3)
		if reducedimp then
			base.irregular = true
		end
		local imp_stem_suffix = q(rad2, nonpast_vowel, rad3)
		local long_imp_stem_base = form_i_imp_stem_through_rad1(base, nonpast_vowel, rad1)
		local short_imp_stem_base = ""
		local imp_stem = q((assimilated or reducedimp) and "" or long_imp_stem_base, imp_stem_suffix)

		-- make parts
		make_sound_verb(base, past_stem, past_pass_stem, nonpast_stem, nonpast_pass_stem, imp_stem, "a")

		if reducedimp == "shortlong" then
			make_1stem_imperative(base, iut.combine_form_and_footnotes(q(long_imp_stem_base, imp_stem_suffix),
				mw.getCurrentFrame():preprocess("[used especially with a clitic such as {{m|ar|فَ}} or {{m|ar|وَ}}]")))
		end
		
		-- Check for irregular verb سَأَلَ with alternative jussive and imperative.  Calling this after make_sound_verb()
		-- adds additional entries to the paradigm parts.
		if saal_radicals(rad1, rad2, rad3) then
			base.irregular = true
			nonpast_1stem_conj(base, "juss", "a", "سَل")
			nonpast_1stem_conj(base, "juss_pass", "u", "سَل")
			make_1stem_imperative(base, "سَل")
		end

		-- Active participle.
		insert_form_or_forms(base, "ap1", q(rad1, AA, rad2, I, rad3))
		-- Insert alternative active participle (stative type I) فَعِيل. Since not all verbs have this, we require that
		-- verbs that do have it specify it explicitly; a shortcut ++ is provided to make this easier (e.g. <ap:++> to
		-- indicate that the alternative form should be used for the active participle, <ap:+,++> to indicate that both
		-- forms can be used, and <ap:-> to indicate that there is no active participle). The same form is used for
		-- secondary default passive participle.
		insert_ap2_pp2(base, q(rad1, A, rad2, II, rad3))
		-- Active participle, stative type II فَعِل (+++).
		insert_form_or_forms(base, "ap3", q(rad1, A, rad2, I, rad3))
		-- Active participle, color/defect أَفْعَل (+cd).
		insert_form_or_forms(base, "apcd", q(HAMZA, A, rad1, SK, rad2, A, rad3))
		-- Active participle, -ān فَعْلَان (+an).
		insert_form_or_forms(base, "apan", q(rad1, A, rad2, SK, rad3, AAN))
		-- Passive participle.
		insert_form_or_forms(base, "pp", q(MA, rad1, SK, rad2, UU, rad3))
	end

	conjugations["I-sound"] = function(base, vowel_spec)
		make_form_i_sound_assimilated_verb(base, vowel_spec, false)
	end

	conjugations["none-sound"] = function(base, vowel_spec)
		-- All default stems are nil.
		make_sound_verb(base)
	end

	conjugations["none-hollow"] = function(base, vowel_spec)
		-- All default stems are nil.
		make_hollow_geminate_verb(base, false)
	end

	conjugations["none-geminate"] = function(base, vowel_spec)
		-- All default stems are nil.
		make_hollow_geminate_verb(base, "geminate")
	end

	conjugations["none-final-weak"] = function(base, vowel_spec)
		-- All default stems are nil.
		make_final_weak_verb(base)
	end

	conjugations["I-assimilated"] = function(base, vowel_spec)
		make_form_i_sound_assimilated_verb(base, vowel_spec, "assimilated")
	end

	local function make_form_i_hayy_verb(base, vowel_spec)
		-- Verbal nouns (maṣādir) for form I are unpredictable and have to be supplied
		base.irregular = true

		-- past and non-past stems, active and passive, and imperative stem
		local past_c_stem = "حَيِي"
		local past_v_stem_long = past_c_stem
		local past_v_stem_short = "حَيّ"
		local past_pass_c_stem = "حُيِي"
		local past_pass_v_stem_long = past_pass_c_stem
		local past_pass_v_stem_short = "حُيّ"

		local nonpast_stem = "حْي"
		local nonpast_pass_stem = nonpast_stem
		local imp_stem = _I .. nonpast_stem

		-- make parts

		past_2stem_conj(base, "past", {}, past_c_stem)
		past_2stem_conj(base, "past_pass", {}, past_pass_c_stem)
		local variant = vowel_spec.variant or "both"
		if variant == "short" or variant == "both" then
			past_2stem_conj(base, "past", past_v_stem_short, {})
			past_2stem_conj(base, "past_pass", past_pass_v_stem_short, {})
		end
		function inflect_long_variant(tense, long_stem, short_stem)
			inflect_tense_1(base, tense, "",
				{long_stem, long_stem, long_stem, long_stem, short_stem},
				{past_endings[4], past_endings[5], past_endings[7], past_endings[8],
				 past_endings[12]},
				{"3ms", "3fs", "3md", "3fd", "3mp"})
		end
		if variant == "long" or variant == "both" then
			inflect_long_variant("past", past_v_stem_long, past_v_stem_short)
			inflect_long_variant("past_pass", past_pass_v_stem_long, past_pass_v_stem_short)
		end

		nonpast_1stem_conj(base, "ind", "a", nonpast_stem, ind_endings_aa)
		nonpast_1stem_conj(base, "sub", "a", nonpast_stem, sub_endings_aa)
		nonpast_1stem_conj(base, "juss", "a", nonpast_stem, juss_endings_aa)
		nonpast_1stem_conj(base, "ind_pass", "u", nonpast_pass_stem, ind_endings_aa)
		nonpast_1stem_conj(base, "sub_pass", "u", nonpast_pass_stem, sub_endings_aa)
		nonpast_1stem_conj(base, "juss_pass", "u", nonpast_pass_stem, juss_endings_aa)
		inflect_tense_imp(base, {imp_stem, all_same = 1}, imp_endings_aa)

		-- active and passive participles apparently do not exist for this verb
	end

	-- Implement form-I final-weak assimilated+final-weak verb. ASSIMILATED is true for assimilated verbs.
	local function make_form_i_final_weak_verb(base, vowel_spec, assimilated)
		local rad1, rad2, rad3, past_vowel, nonpast_vowel = get_radicals_3(vowel_spec)

		-- حَيَّ or حَيِيَ is weird enough that we handle it as a separate function.
		if hayy_radicals(rad1, rad2, rad3) then
			make_form_i_hayy_verb(base, vowel_spec)
			return
		end

		-- Verbal nouns (maṣādir) for form I are unpredictable and have to be supplied.

		-- Past and non-past stems, active and passive, and imperative stem.
		local past_stem = q(rad1, A, rad2)
		local past_pass_stem = q(rad1, U, rad2)
		local nonpast_stem, nonpast_pass_stem, imp_stem
		if raa_radicals(rad1, rad2, rad3) then
			base.irregular = true
			nonpast_stem = rad1
			nonpast_pass_stem = rad1
			imp_stem = rad1
		else
			nonpast_pass_stem = q(rad1, SK, rad2)
			if assimilated then
				nonpast_stem = rad2
				imp_stem = rad2
			else
				nonpast_stem = nonpast_pass_stem
				imp_stem = q(form_i_imp_stem_through_rad1(base, nonpast_vowel, rad1), rad2)
			end
		end

		-- Make parts.
		local past_ending_vowel =
			req(rad3, Y) and req(past_vowel, A) and "ay" or
			req(rad3, W) and req(past_vowel, A) and "aw" or
			req(past_vowel, I) and "ī" or "ū"
		-- Try to preserve footnotes attached to the third radical and/or past and/or non-past vowels.
		local past_footnotes = iut.combine_footnotes(rget_footnotes(rad3), rget_footnotes(past_vowel))
		local nonpast_ending_vowel = req(nonpast_vowel, A) and "ā" or req(nonpast_vowel, I) and "ī" or "ū"
		local nonpast_footnotes = iut.combine_footnotes(rget_footnotes(rad3), rget_footnotes(nonpast_vowel))
		make_final_weak_verb(base,
			iut.combine_form_and_footnotes(past_stem, past_footnotes),
			iut.combine_form_and_footnotes(past_pass_stem, past_footnotes),
			iut.combine_form_and_footnotes(nonpast_stem, nonpast_footnotes),
			iut.combine_form_and_footnotes(nonpast_pass_stem, nonpast_footnotes),
			iut.combine_form_and_footnotes(imp_stem, nonpast_footnotes),
			past_ending_vowel, nonpast_ending_vowel, "a")

		-- Active participle.
		insert_form_or_forms(base, "ap1", q(rad1, AA, rad2, IN))
		-- Active participle, stative type I فَعِيّ (++). FIXME: Is this correct when rad3 is W?
		insert_ap2_pp2(base, q(rad1, A, rad2, II, SH))
		-- Active participle, stative type II فَعٍ (+++). FIXME: Any examples of this to verify it's correct?
		insert_form_or_forms(base, "ap3", q(rad1, A, rad2, IN))
		-- Active participle, color/defect أَفْعَى (+cd).
		insert_form_or_forms(base, "apcd", q(HAMZA, A, rad1, SK, rad2, AAMAQ))
		-- Active participle, -ān فَعْيَان or فَعْوَان (+an). 
		-- FIXME: Any examples of this for both rad3 = W and y to verify it's correct?
		insert_form_or_forms(base, "apan", q(rad1, A, rad2, SK, rad3, AAN))
		-- Passive participle.
		insert_form_or_forms(base, "pp", q(MA, rad1, SK, rad2, req(rad3, Y) and II or UU, SH))
	end

	conjugations["I-final-weak"] = function(base, vowel_spec)
		make_form_i_final_weak_verb(base, vowel_spec, false)
	end

	conjugations["I-assimilated+final-weak"] = function(base, vowel_spec)
		make_form_i_final_weak_verb(base, vowel_spec, "assimilated")
	end

	conjugations["I-hollow"] = function(base, vowel_spec)
		local rad1, rad2, rad3, past_vowel, nonpast_vowel = get_radicals_3(vowel_spec)
		-- In some sense, hollow vowels i~i and u~u are more "correct" than a~i and a~u, but the latter follow the
		-- pattern of other form-I verbs, so we map i~i to a~i and u~u to a~u in infer_radicals(). Now however we have
		-- to undo this to get the actual past vowel based on the non-past vowel.
		if req(past_vowel, A) then
			past_vowel = map_vowel(past_vowel, function(vow)
				return req(nonpast_vowel, A) and I or rget(nonpast_vowel)
			end)
		end
		local lengthened_nonpast = map_vowel(nonpast_vowel, function(vow)
			return vow == U and UU or vow == I and II or AA
		end)

		-- Verbal nouns (maṣādir) for form I are unpredictable and have to be supplied.

		-- active past stems - vowel (v) and consonant (c)
		local past_v_stem = q(rad1, AA, rad3)
		local past_c_stem = q(rad1, past_vowel, rad3)

		-- active non-past stems - vowel (v) and consonant (c)
		local nonpast_v_stem = q(rad1, lengthened_nonpast, rad3)
		local nonpast_c_stem = q(rad1, nonpast_vowel, rad3)

		-- passive past stems - vowel (v) and consonant (c)
		-- 'ufīla, 'ufiltu
		local past_pass_v_stem = q(rad1, II, rad3)
		local past_pass_c_stem = q(rad1, I, rad3)

		-- passive non-past stems - vowel (v) and consonant (c)
		-- yufāla/yufalna
		-- stem is built differently but conjugation is identical to sound verbs
		local nonpast_pass_v_stem = q(rad1, AA, rad3)
		local nonpast_pass_c_stem = q(rad1, A, rad3)

		-- imperative stem
		local imp_v_stem = nonpast_v_stem
		local imp_c_stem = nonpast_c_stem

		-- make parts
		make_hollow_geminate_verb(base, false, past_v_stem, past_c_stem, past_pass_v_stem,
			past_pass_c_stem, nonpast_v_stem, nonpast_c_stem, nonpast_pass_v_stem,
			nonpast_pass_c_stem, imp_v_stem, imp_c_stem, "a")

		if kaan_radicals(rad1, rad2, rad3) then
			local endings = make_nonpast_endings(U, {}, {}, {}, {})
			inflect_tense(base, "juss", nonpast_prefix_consonants, q(A, rad1), endings)
			base.irregular = true
		end

		-- Active participle.
		insert_form_or_forms(base, "ap1", req(rad3, HAMZA) and q(rad1, AA, HAMZA, IN) or
			q(rad1, AA, HAMZA, I, rad3))
		-- Active participle, stative type I فَيِّد (++). FIXME: Any examples of this to verify it's correct?
		insert_ap2_pp2(base, q(rad1, A, Y, SH, I, rad3))
		-- Active participle, stative type II فَيِد (+++). FIXME: Any examples of this to verify it's correct?
		insert_form_or_forms(base, "ap3", q(rad1, A, Y, I, rad3))
		-- Active participle, color/defect أَفّيَد or أَفّوَد (+cd). FIXME: Any examples of this to verify it's correct?
		insert_form_or_forms(base, "apcd", q(HAMZA, A, rad1, SK, rad2, A, rad3))
		-- Active participle, -ān فَيْدَان  or فَوْدَان (+an). Example: جَاعَ "to be hungry", act part جَوْعَان
		insert_form_or_forms(base, "apan", q(rad1, A, rad2, SK, rad3, AAN))
		-- Passive participle.
		insert_form_or_forms(base, "pp", q(MA, rad1, req(rad2, Y) and II or UU, rad3))
	end

	conjugations["I-geminate"] = function(base, vowel_spec)
		local rad1, rad2, rad3, past_vowel, nonpast_vowel = get_radicals_3(vowel_spec)

		-- Verbal nouns (maṣādir) for form I are unpredictable and have to be supplied.

		-- active past stems - vowel (v) and consonant (c)
		local past_v_stem = q(rad1, A, rad2, SH)
		local past_c_stem = q(rad1, A, rad2, past_vowel, rad2)

		-- active non-past stems - vowel (v) and consonant (c)
		local nonpast_v_stem = q(rad1, nonpast_vowel, rad2, SH)
		local nonpast_c_stem = q(rad1, SK, rad2, nonpast_vowel, rad2)

		-- passive past stems - vowel (v) and consonant (c)
		-- dulla/dulilta
		local past_pass_v_stem = q(rad1, U, rad2, SH)
		local past_pass_c_stem = q(rad1, U, rad2, I, rad2)

		-- passive non-past stems - vowel (v) and consonant (c)
		--yudallu/yudlalna
		-- stem is built differently but conjugation is identical to sound verbs
		local nonpast_pass_v_stem = q(rad1, A, rad2, SH)
		local nonpast_pass_c_stem = q(rad1, SK, rad2, A, rad2)

		-- imperative stem
		local imp_v_stem = q(rad1, nonpast_vowel, rad2, SH)
		local imp_c_stem = q(form_i_imp_stem_through_rad1(base, nonpast_vowel, rad1), rad2, nonpast_vowel, rad2)

		-- make parts
		make_hollow_geminate_verb(base, "geminate", past_v_stem, past_c_stem, past_pass_v_stem,
			past_pass_c_stem, nonpast_v_stem, nonpast_c_stem, nonpast_pass_v_stem,
			nonpast_pass_c_stem, imp_v_stem, imp_c_stem, "a")

		-- Active participle.
		insert_form_or_forms(base, "ap1", q(rad1, AA, rad2, SH))
		-- Active participle, stative type I فَعِيع (++). FIXME: Any examples of this to verify it's correct?
		insert_ap2_pp2(base, q(rad1, A, rad2, II, rad2))
		-- Active participle, stative type II فَعّ (+++). Example: بَرَّ "to be pious", active participle بَرّ
		insert_form_or_forms(base, "ap3", q(rad1, A, rad2, SH))
		-- Active participle, color/defect أَفَعّ (+cd).
		-- Example: لَصَّ "to be thievish, to steal repeatedly", active participle أَلَصّ.
		insert_form_or_forms(base, "apcd", q(HAMZA, A, rad1, A, rad2, SH))
		-- Active participle, -ān فَعَّان (+an). FIXME: Any examples of this to verify it's correct?
		insert_form_or_forms(base, "apan", q(rad1, A, rad2, SH, AAN))
		-- Passive participle.
		insert_form_or_forms(base, "pp", q(MA, rad1, SK, rad2, UU, rad2))
	end

	-- Return the ta- (active, past and non-past) and tu- (passive past) prefixes for a form II/III/V/VI verb.
	-- Form V and VI verbs normally use ta- and tu-, but reduced (base.reduced) verbs use different prefixes. Form II
	-- and III verbs have no prefix.
	local function form_ii_iii_v_vi_ta_tu_prefix(base, rad1)
		local vform = base.verb_form
		if vform == "V" or vform == "VI" then
			if base.reduced then
				-- To simplify the code, we generate two rad1's with a sukūn between them, which is cleaned up in
				-- postprocessing.
				return q(_I, rad1, SK), q(rad1, SK), q(_U, rad1, SK)
			else
				return TA, TA, TU
			end
		else
			return "", "", ""
		end
	end

	-- Make form II or V sound or final-weak verb.
	local function make_form_ii_v_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)
		local vform = base.verb_form
		local ta_past_prefix, ta_nonpast_prefix, tu_past_prefix = form_ii_iii_v_vi_ta_tu_prefix(base, rad1)
		local vn = vform == "V" and
			q(ta_past_prefix, rad1, A, rad2, SH, final_weak and IN or q(U, rad3)) or
			q(TA, rad1, SK, rad2, II, final_weak and AH or rad3)

		-- various stem bases
		local past_stem_base = q(ta_past_prefix, rad1, A, rad2, SH)
		local nonpast_stem_base = q(ta_nonpast_prefix, rad1, A, rad2, SH)
		local past_pass_stem_base = q(tu_past_prefix, rad1, U, rad2, SH)

		-- make parts
		make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
	end

	conjugations["II-sound"] = function(base, vowel_spec)
		make_form_ii_v_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["II-final-weak"] = function(base, vowel_spec)
		make_form_ii_v_sound_final_weak_verb(base, vowel_spec)
	end

	local function make_form_iii_alt_vn(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)
		-- Insert alternative verbal noun فِعَال. Since not all verbs have this, we require that verbs that do have it
		-- specify it explicitly; a shortcut ++ is provided to make this easier (e.g. <vn:+,++> to indicate that
		-- both the normal verbal noun مُفَاعَلَة and secondary verbal noun فِعَال are available).
		insert_form_or_forms(base, "vn2", q(rad1, I, rad2, AA, final_weak and HAMZA or rad3))
	end

	-- Make form III or VI sound or final-weak verb.
	local function make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)
		local vform = base.verb_form
		local ta_past_prefix, ta_nonpast_prefix, tu_past_prefix = form_ii_iii_v_vi_ta_tu_prefix(base, rad1)
		local vn = vform == "VI" and
			q(ta_past_prefix, rad1, AA, rad2, final_weak and IN or q(U, rad3)) or
			q(MU, rad1, AA, rad2, final_weak and AAH or q(A, rad3, AH))

		-- various stem bases
		local past_stem_base = q(ta_past_prefix, rad1, AA, rad2)
		local nonpast_stem_base = q(ta_nonpast_prefix, rad1, AA, rad2)
		local past_pass_stem_base = q(tu_past_prefix, rad1, UU, rad2)

		-- make parts
		make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
		if vform == "III" then
			make_form_iii_alt_vn(base, vowel_spec)
		end
	end

	conjugations["III-sound"] = function(base, vowel_spec)
		make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["III-final-weak"] = function(base, vowel_spec)
		make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
	end

	-- Make form III or VI geminate verb.
	local function make_form_iii_vi_geminate_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vform = base.verb_form
		local ta_past_prefix, ta_nonpast_prefix, tu_past_prefix = form_ii_iii_v_vi_ta_tu_prefix(base, rad1)
		-- Alternative verbal noun فِعَال will be inserted when we add sound parts below.
		local vn = vform == "VI" and q(ta_past_prefix, rad1, AA, rad2, SH) or q(MU, rad1, AA, rad2, SH, AH)

		-- Various stem bases.
		local past_stem_base = q(ta_past_prefix, rad1, AA)
		local nonpast_stem_base = q(ta_nonpast_prefix, rad1, AA)
		local past_pass_stem_base = q(tu_past_prefix, rad1, UU)

		-- Make parts.
		local variant = vowel_spec.variant or "short"
		if variant == "short" or variant == "both" then
			make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
		end

		-- Also add alternative sound (non-compressed) parts. This will lead to some duplicate entries, but they are
		-- removed during addition.
		if variant == "long" or variant == "both" then
			make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
		elseif vform == "III" then
			-- Still need to add the alternative form-III verbal noun.
			make_form_iii_alt_vn(base, vowel_spec)
		end
	end

	conjugations["III-geminate"] = function(base, vowel_spec)
		make_form_iii_vi_geminate_verb(base, vowel_spec)
	end

	-- Make form IV sound or final-weak verb.
	local function make_form_iv_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)

		-- core of stem base, minus stem prefixes
		local stem_core

		-- check for irregular verb أَرَى
		local is_raa = raa_radicals(rad1, rad2, rad3)
		if is_raa then
			base.irregular = true
			stem_core = rad1
		else
			stem_core =	q(rad1, SK, rad2)
		end

		-- verbal noun
		local vn = is_raa and
			q(HAMZA, I, stem_core, AA, HAMZA, AH) or
			q(HAMZA, I, stem_core, AA, final_weak and HAMZA or rad3)

		-- various stem bases
		local past_stem_base = q(HAMZA, A, stem_core)
		local nonpast_stem_base = stem_core
		local past_pass_stem_base = q(HAMZA, U, stem_core)

		-- make parts
		make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
	end

	conjugations["IV-sound"] = function(base, vowel_spec)
		make_form_iv_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IV-final-weak"] = function(base, vowel_spec)
		make_form_iv_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IV-hollow"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		-- verbal noun
		local vn = q(HAMZA, I, rad1, AA, rad3, AH)

		-- various stem bases
		local past_stem_base = q(HAMZA, A, rad1)
		local nonpast_stem_base = rad1
		local past_pass_stem_base = q(HAMZA, U, rad1)

		-- make parts
		make_augmented_hollow_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["IV-geminate"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = q(HAMZA, I, rad1, SK, rad2, AA, rad2)

		-- various stem bases
		local past_stem_base = q(HAMZA, A, rad1)
		local nonpast_stem_base = rad1
		local past_pass_stem_base = q(HAMZA, U, rad1)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["V-sound"] = function(base, vowel_spec)
		make_form_ii_v_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["V-final-weak"] = function(base, vowel_spec)
		make_form_ii_v_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VI-sound"] = function(base, vowel_spec)
		make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VI-final-weak"] = function(base, vowel_spec)
		make_form_iii_vi_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VI-geminate"] = function(base, vowel_spec)
		make_form_iii_vi_geminate_verb(base, vowel_spec)
	end

	-- Make a verbal noun of the general form that applies to forms VII and above. RAD12 is the first consonant cluster
	-- (after initial اِ) and RAD34 is the second consonant cluster. RAD5 is the final consonant.
	local function high_form_verbal_noun(rad12, rad34, rad5)
		return q(_I, rad12, I, rad34, AA, rad5)
	end

	-- Populate a sound or final-weak verb for any of the various high-numbered augmented forms (form VII and up) that
	-- have up to 5 consonants in two clusters in the stem and the same pattern of vowels between.  Some of these
	-- consonants in certain verb parts are w's, which leads to apparent anomalies in certain stems of these parts, but
	-- these anomalies are handled automatically in postprocessing, where we resolve sequences of iwC -> īC, uwC -> ūC,
	-- w + sukūn + w -> w + shadda.

	-- RAD12 is the first consonant cluster (after initial اِ) and RAD34 is the second consonant cluster. RAD5 is the
	-- final consonant.
	local function make_high_form_sound_final_weak_verb(base, vowel_spec, rad12, rad34, rad5)
		local final_weak = is_final_weak(base, vowel_spec)
		local vn = high_form_verbal_noun(rad12, rad34, final_weak and HAMZA or rad5)

		-- various stem bases
		local nonpast_stem_base = q(rad12, A, rad34)
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, rad12, U, rad34)

		-- make parts
		make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
	end

	local function form_vii_nrad1(base, rad1)
		if base.reduced then
			if not req(rad1, M) then
				error(("Internal error: Form VII first radical %s is not م but .reduced specified; should have been caught earlier"):
					format(rget(rad1)))
			end
			return M .. SH
		else
			return q("نْ", rad1)
		end
	end

	-- Make form VII sound or final-weak verb.
	local function make_form_vii_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		make_high_form_sound_final_weak_verb(base, vowel_spec, form_vii_nrad1(base, rad1), rad2, rad3)
	end

	conjugations["VII-sound"] = function(base, vowel_spec)
		make_form_vii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VII-final-weak"] = function(base, vowel_spec)
		make_form_vii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VII-hollow"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local nrad1 = form_vii_nrad1(base, rad1)
		local vn = high_form_verbal_noun(nrad1, Y, rad3)

		-- various stem bases
		local nonpast_stem_base = nrad1
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, nrad1)

		-- make parts
		make_augmented_hollow_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["VII-geminate"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local nrad1 = form_vii_nrad1(base, rad1)
		local vn = high_form_verbal_noun(nrad1, rad2, rad2)

		-- various stem bases
		local nonpast_stem_base = q(nrad1, A)
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, nrad1, U)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	-- Return Form VIII verbal noun.
	local function form_viii_verbal_noun(base, vowel_spec, rad1, rad2, rad3)
		local final_weak = is_final_weak(base, vowel_spec)
		rad3 = final_weak and HAMZA or rad3
		return {high_form_verbal_noun(vowel_spec.form_viii_assim, rad2, rad3)}
	end

	-- Make form VIII sound or final-weak verb.
	local function make_form_viii_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		-- check for irregular verb اِتَّخَذَ
		if axadh_radicals(rad1, rad2, rad3) then
			base.irregular = true
			rad1 = T
		end
		make_high_form_sound_final_weak_verb(base, vowel_spec, vowel_spec.form_viii_assim, rad2, rad3)
	end

	conjugations["VIII-sound"] = function(base, vowel_spec)
		make_form_viii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VIII-final-weak"] = function(base, vowel_spec)
		make_form_viii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["VIII-hollow"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = form_viii_verbal_noun(base, vowel_spec, rad1, Y, rad3)

		-- various stem bases
		local nonpast_stem_base = vowel_spec.form_viii_assim
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, nonpast_stem_base)

		-- make parts
		make_augmented_hollow_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["VIII-geminate"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = form_viii_verbal_noun(base, vowel_spec, rad1, rad2, rad2)

		-- various stem bases
		local nonpast_stem_base = q(vowel_spec.form_viii_assim, A)
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, vowel_spec.form_viii_assim, U)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["IX-sound"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = q(_I, rad1, SK, rad2, I, rad3, AA, rad3)

		-- various stem bases
		local nonpast_stem_base = q(rad1, SK, rad2, A)
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, rad1, SK, rad2, U)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["IX-final-weak"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		make_high_form_sound_final_weak_verb(base, vowel_spec, q(rad1, SK, rad2), rad3, rad3)
	end

	-- Populate a sound or final-weak verb for any of the various high-numbered
	-- augmented forms that have 5 consonants in the stem and the same pattern of
	-- vowels. Some of these consonants in certain verb parts are w's, which leads to
	-- apparent anomalies in certain stems of these parts, but these anomalies
	-- are handled automatically in postprocessing, where we resolve sequences of
	-- iwC -> īC, uwC -> ūC, w + sukūn + w -> w + shadda.
	local function make_high5_form_sound_final_weak_verb(base, vowel_spec, rad1, rad2, rad3, rad4, rad5)
		make_high_form_sound_final_weak_verb(base, vowel_spec, q(rad1, SK, rad2), q(rad3, SK, rad4), rad5)
	end

	-- Make form X sound or final-weak verb.
	local function make_form_x_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		-- check for irregular verb اِسْتَحْيَا (also اِسْتَحَى)
		local is_hayy = hayy_radicals(rad1, rad2, rad3)
		local variant = vowel_spec.variant or "both"
		if not is_hayy or variant == "long" or variant == "both" then
			make_high5_form_sound_final_weak_verb(base, vowel_spec, S, T, rad1, rad2, rad3)
		end
		if is_hayy and (variant == "short" or variant == "both") then
			base.irregular = true
			-- Add alternative entries to the verbal paradigms. Any duplicates are removed during addition.
			make_high_form_sound_final_weak_verb(base, vowel_spec, S .. SK .. T, rad1, rad3)
		end
	end

	conjugations["X-sound"] = function(base, vowel_spec)
		make_form_x_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["X-final-weak"] = function(base, vowel_spec)
		make_form_x_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["X-hollow"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = q(base.reduced and "اِسْ" or "اِسْتِ", rad1, AA, rad3, AH)

		-- various stem bases
		local past_stem_base = q(base.reduced and "اِسْ" or "اِسْتَ", rad1)
		local nonpast_stem_base = q(base.reduced and "سْ" or "سْتَ", rad1)
		local past_pass_stem_base = q(base.reduced and "اُسْ" or "اُسْتُ", rad1)

		-- make parts
		make_augmented_hollow_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	conjugations["X-geminate"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = q("اِسْتِ", rad1, SK, rad2, AA, rad2)

		-- various stem bases
		local past_stem_base = q("اِسْتَ", rad1)
		local nonpast_stem_base = q("سْتَ", rad1)
		local past_pass_stem_base = q("اُسْتُ", rad1)

		-- make parts
		if base.altgem then
			inflect_tense(base, "past", "", {q(past_stem_base, A, rad2, SH), all_same = 1},
				past_endings_ay_12_person_only)
		end
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn,
			base.altgem and "[uncommon]" or nil)
	end

	conjugations["XI-sound"] = function(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local vn = q(_I, rad1, SK, rad2, II, rad3, AA, rad3)

		-- various stem bases
		local nonpast_stem_base = q(rad1, SK, rad2, AA)
		local past_stem_base = q(_I, nonpast_stem_base)
		local past_pass_stem_base = q(_U, rad1, SK, rad2, UU)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	-- Probably no form XI final-weak, since already geminate in form; would behave as XI-sound.

	-- Make form XII sound or final-weak verb.
	local function make_form_xii_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		make_high5_form_sound_final_weak_verb(base, vowel_spec, rad1, rad2, W, rad2, rad3)
	end

	conjugations["XII-sound"] = function(base, vowel_spec)
		make_form_xii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["XII-final-weak"] = function(base, vowel_spec)
		make_form_xii_sound_final_weak_verb(base, vowel_spec)
	end

	-- Make form XIII sound or final-weak verb.
	local function make_form_xiii_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		make_high5_form_sound_final_weak_verb(base, vowel_spec, rad1, rad2, W, W, rad3)
	end

	conjugations["XIII-sound"] = function(base, vowel_spec)
		make_form_xiii_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["XIII-final-weak"] = function(base, vowel_spec)
		make_form_xiii_sound_final_weak_verb(base, vowel_spec)
	end

	-- Make a form XIV or XV sound or final-weak verb. Last radical appears twice (if`anlala / yaf`anlilu) so if it were
	-- w or y you'd get if`anwā / yaf`anwī or if`anyā / yaf`anyī, i.e. unlike for most augmented verbs, the identity of
	-- the radical matters.
	local function make_form_xiv_xv_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3 = get_radicals_3(vowel_spec)
		local lastrad = base.verb_form == "XV" and Y or rad3
		make_high5_form_sound_final_weak_verb(base, vowel_spec, rad1, rad2, N, rad3, lastrad)
	end

	conjugations["XIV-sound"] = function(base, vowel_spec)
		make_form_xiv_xv_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["XIV-final-weak"] = function(base, vowel_spec)
		make_form_xiv_xv_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["XV-sound"] = function(base, vowel_spec)
		make_form_xiv_xv_sound_final_weak_verb(base, vowel_spec)
	end

	-- Probably no form XV final-weak, since already final-weak in form; would behave as XV-sound.

	-- Make form Iq or IIq sound or final-weak verb.
	local function make_form_iq_iiq_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3, rad4 = get_radicals_4(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)
		local vform = base.verb_form
		local vn = vform == "IIq" and
			q(TA, rad1, A, rad2, SK, rad3, (final_weak and IN or q(U, rad4))) or
			q(rad1, A, rad2, SK, rad3, (final_weak and AAH or q(A, rad4, AH)))
		local ta_pref = vform == "IIq" and TA or ""
		local tu_pref = vform == "IIq" and TU or ""

		-- various stem bases
		local past_stem_base = q(ta_pref, rad1, A, rad2, SK, rad3)
		local nonpast_stem_base = past_stem_base
		local past_pass_stem_base = q(tu_pref, rad1, U, rad2, SK, rad3)

		-- make parts
		make_augmented_sound_final_weak_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base,
			vn)
	end

	conjugations["Iq-sound"] = function(base, vowel_spec)
		make_form_iq_iiq_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["Iq-final-weak"] = function(base, vowel_spec)
		make_form_iq_iiq_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IIq-sound"] = function(base, vowel_spec)
		make_form_iq_iiq_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IIq-final-weak"] = function(base, vowel_spec)
		make_form_iq_iiq_sound_final_weak_verb(base, vowel_spec)
	end

	-- Make form IIIq sound or final-weak verb.
	local function make_form_iiiq_sound_final_weak_verb(base, vowel_spec)
		local rad1, rad2, rad3, rad4 = get_radicals_4(vowel_spec)
		make_high5_form_sound_final_weak_verb(base, vowel_spec, rad1, rad2, N, rad3, rad4)
	end

	conjugations["IIIq-sound"] = function(base, vowel_spec)
		make_form_iiiq_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IIIq-final-weak"] = function(base, vowel_spec)
		make_form_iiiq_sound_final_weak_verb(base, vowel_spec)
	end

	conjugations["IVq-sound"] = function(base, vowel_spec)
		local rad1, rad2, rad3, rad4 = get_radicals_4(vowel_spec)
		local vn = q(_I, rad1, SK, rad2, I, rad3, SK, rad4, AA, rad4)

		-- various stem bases
		local past_stem_base = q(_I, rad1, SK, rad2, A, rad3)
		local nonpast_stem_base = q(rad1, SK, rad2, A, rad3)
		local past_pass_stem_base = q(_U, rad1, SK, rad2, U, rad3)

		-- make parts
		make_augmented_geminate_verb(base, vowel_spec, past_stem_base, nonpast_stem_base, past_pass_stem_base, vn)
	end

	-- Probably no form IVq final-weak, since already geminate in form; would behave as IVq-sound.
end

create_conjugations()

-------------------------------------------------------------------------------
--                       Guts of main conjugation function                   --
-------------------------------------------------------------------------------

-- Given form, weakness and radicals, check to make sure the radicals present are allowable for the weakness. Hamzas on
-- alif/wāw/yāʾ seats are never allowed (should always appear as hamza-on-the-line), and various weaknesses have various
-- strictures on allowable consonants.
local function check_radicals(form, weakness, rad1, rad2, rad3, rad4)
	local function hamza_check(index, rad)
		if rad == HAMZA_ON_ALIF or rad == HAMZA_UNDER_ALIF or
			rad == HAMZA_ON_W or rad == HAMZA_ON_Y then
			error("Radical " .. index .. " is " .. rad .. " but should be ء (hamza on the line)")
		end
	end
	local function check_waw_ya(index, rad)
		if not is_waw_ya(rad) then
			error("Radical " .. index .. " is " .. rad .. " but should be و or ي")
		end
	end
	local function check_not_waw_ya(index, rad)
		if is_waw_ya(rad) then
			error("In a sound verb, radical " .. index .. " should not be و or ي")
		end
	end
	hamza_check(rad1)
	hamza_check(rad2)
	hamza_check(rad3)
	hamza_check(rad4)
	if weakness == "assimilated" or weakness == "assimilated+final-weak" then
		if rad1 ~= W then
			error("Radical 1 is " .. rad1 .. " but should be و")
		end
	-- don't check that non-assimilated form I verbs don't have wāw as their
	-- first radical because some form-I verbs exist where a first-radical wāw
	-- behaves as sound, e.g. wajuha yawjuhu "to be distinguished".
	end
	if weakness == "final-weak" or weakness == "assimilated+final-weak" then
		if rad4 then
			check_waw_ya(4, rad4)
		else
			check_waw_ya(3, rad3)
		end
	elseif vform_supports_final_weak(form) then
		-- non-final-weak verbs cannot have weak final radical if there's a corresponding
		-- final-weak verb category. I think this is safe. We may have problems with
		-- ḥayya/ḥayiya yaḥyā if we treat it as a geminate verb.
		if rad4 then
			check_not_waw_ya(4, rad4)
		else
			check_not_waw_ya(3, rad3)
		end
	end
	if weakness == "hollow" then
		check_waw_ya(2, rad2)
	-- don't check that non-hollow verbs in forms that support hollow verbs
	-- don't have wāw or yāʾ as their second radical because some verbs exist
	-- where a middle-radical wāw/yāʾ behaves as sound, e.g. form-VIII izdawaja
	-- "to be in pairs".
	end
	if weakness == "geminate" then
		if rad4 then
			error("Internal error: No geminate quadrilaterals, should not be seen")
		end
		if rad2 ~= rad3 then
			error("Weakness is geminate; radical 3 is " .. rad3 .. " but should be same as radical 2 " .. rad2)
		end
	elseif vform_supports_geminate(form) then
		-- non-geminate verbs cannot have second and third radical same if there's
		-- a corresponding geminate verb category. I think this is safe. We
		-- don't fuss over double wāw or double yāʾ because this could legitimately
		-- be a final-weak verb with middle wāw/yāʾ, treated as sound.
		if rad4 then
			error("Internal error: No quadrilaterals should support geminate verbs")
		end
		if rad2 == rad3 and not is_waw_ya(rad2) then
			error("Weakness is '" .. weakness .. "'; radical 2 and 3 are same at " .. rad2 .. " but should not be; consider making weakness 'geminate'")
		end
	end
end

-- array of substitutions; each element is a 2-entry array FROM, TO; do it
-- this way so the concatenations only get evaluated once
local postprocess_subs = {
	-- reorder short-vowel + shadda -> shadda + short-vowel for easier processing
	{"(" .. AIU .. ")" .. SH, SH .. "%1"},

	----------same letter separated by sukūn should instead use shadda---------
	------------happens e.g. in kun-nā "we were".-----------------
	{"(.)" .. SK .. "%1", "%1" .. SH},

	---------------------------- assimilated verbs ----------------------------
	-- iw, iy -> ī (assimilated verbs)
	{I .. W .. SK, II},
	{I .. Y .. SK, II},
	-- uw, uy -> ū (assimilated verbs)
	{U .. W .. SK, UU},
	{U .. Y .. SK, UU},

    -------------- final -yā uses tall alif not alif maqṣūra ------------------
	{"(" .. Y ..  SH .. "?" .. A .. ")" .. AMAQ, "%1" .. ALIF},

	----------------------- handle hamza assimilation -------------------------
	-- initial hamza + short-vowel + hamza + sukūn -> hamza + long vowel
	{HAMZA .. A .. HAMZA .. SK, HAMZA .. A .. ALIF},
	{HAMZA .. I .. HAMZA .. SK, HAMZA .. I .. Y},
	{HAMZA .. U .. HAMZA .. SK, HAMZA .. U .. W}
}

local postprocess_tr_subs = {
	{"ī([" .. vowels .. "y*])", "iy%1"},
	{"ū([" .. vowels .. "w*])", "uw%1"},
	{"(.)%*", "%1%1"}, -- implement shadda

	---------------------------- assimilated verbs ----------------------------
	-- iw, iy -> ī (assimilated verbs)
	{"iw([^" .. vowels .. "w])", "ī%1"},
	{"iy([^" .. vowels .. "y])", "ī%1"},
	-- uw, uy -> ū (assimilated verbs)
	{"uw([^" .. vowels .. "w])", "ū%1"},
	{"uy([^" .. vowels .. "y])", "ū%1"},

	----------------------- handle hamza assimilation -------------------------
	-- initial hamza + short-vowel + hamza + sukūn -> hamza + long vowel
	{"ʔaʔ(" .. NV .. ")", "ʔā%1"},
	{"ʔiʔ(" .. NV .. ")", "ʔī%1"},
	{"ʔuʔ(" .. NV .. ")", "ʔū%1"},
}

-- Post-process verb parts to eliminate phonological anomalies. Many of the changes, particularly the tricky ones,
-- involve converting hamza to have the proper seat. The rules for this are complicated and are documented on the
-- [[w:Hamza]] Wikipedia page. In some cases there are alternatives allowed, and we handle them below by returning
-- multiple possibilities.
local function postprocess_term(term)
	if term == "?" then
		return "?"
	end
	-- Add BORDER at text boundaries.
	term = BORDER .. term .. BORDER
	-- Do the main post-processing, based on the pattern substitutions in postprocess_subs.
	for _, sub in ipairs(postprocess_subs) do
		term = rsub(term, sub[1], sub[2])
	end
	term = term:gsub(BORDER, "")
	if not rfind(term, HAMZA) then
		return term
	end
	term = term:gsub(HAMZA, HAMZA_PH)
	term = ar_utilities.process_hamza(term)
	if #term == 1 then
		term = term[1]
	end
	return term
end

local function postprocess_translit(translit)
	if translit == "?" then
		return "?"
	end
	-- Add BORDER at text boundaries.
	translit = BORDER .. translit .. BORDER
	-- Do the main post-processing, based on the pattern substitutions in postprocess_tr_subs.
	for _, sub in ipairs(postprocess_tr_subs) do
		translit = rsub(translit, sub[1], sub[2])
	end
	translit = translit:gsub(BORDER, "")
	return translit
end

local function postprocess_forms(base)
	local converted_values = {}
	for slot, forms in pairs(base.forms) do
		local need_dedup = false
		for i, form in ipairs(forms) do
			local term = postprocess_term(form.form)
			local translit = form.translit and postprocess_translit(form.translit) or nil
			if term ~= form.form or translit ~= form.translit then
				need_dedup = true
			end
			converted_values[i] = {term, translit}
		end
		if need_dedup then
			local temp_dedup = {}
			for i = 1, #forms do
				local new_term, new_translit = unpack(converted_values[i])
				if type(new_term) == "table" then
					for _, nt in ipairs(new_term) do
						local new_formobj = {
							form = nt,
							translit = new_translit,
							footnotes = forms[i].footnotes,
						}
						iut.insert_form(temp_dedup, "temp", new_formobj)
					end
				else
					local new_formobj = {
						form = new_term,
						translit = new_translit,
						footnotes = forms[i].footnotes,
					}
					iut.insert_form(temp_dedup, "temp", new_formobj)
				end
			end
			base.forms[slot] = temp_dedup.temp
		end
	end
end

local function process_slot_overrides(base)
	for slot, forms in pairs(base.slot_overrides) do
		local existing_values = base.forms[slot]
		base.forms[slot] = nil
		for _, form in ipairs(forms) do
			-- + in active participle for form I requests slot ap1
			if form.form == "+" and (base.verb_form ~= "I" or slot ~= "ap") then
				if not existing_values then
					error(("Slot '%s' requested the default value but no such value available"):format(slot))
				end
				-- We maintain an invariant that no two slots share a form object (although they may share the footnote
				-- lists inside the form objects). However, there is no need to copy the form objects here because there
				-- is a one-to-one correspondence between slots and slot overrides, i.e. you can't have a default value
				-- go into two slots.
				insert_form_or_forms(base, slot, existing_values, "allow overrides", form.uncertain)
			elseif default_indicator_to_active_participle_slot[form.form] then
				if form.form == "++" then
					if slot ~= "vn" and slot ~= "ap" and slot ~= "pp" then
						error(("Secondary default value request '++' only applicable to verbal nouns and pariciples, but found in slot '%s'"):
						format(slot))
					end
				else
					if slot ~= "ap" then
						error(("Secondary default value request '%s' only applicable to active pariciples, but found in slot '%s'"):
						format(form.form, slot))
					end
				end
				local secondary_default_slot =
					slot == "vn" and "vn2" or slot == "pp" and "pp2" or
					default_indicator_to_active_participle_slot[form.form]
				local existing_values = base.forms[secondary_default_slot]
				if not existing_values then
					error(("Slot '%s' requested a secondary default value using '%s' but no such value available"):
						format(slot, form.form))
				end
				-- See comment above about the lack of need to copy the form objects.
				insert_form_or_forms(base, slot, existing_values, "allow overrides", form.uncertain)
				-- To make sure there aren't shared form objects.
				base.forms[secondary_default_slot] = nil
			else
				insert_form_or_forms(base, slot, form, "allow overrides", form.uncertain)
			end
		end
	end

	-- Now, for non-stative form-I verbs, fill the active participle slot from ap1 unless it should be missing (e.g.
	-- passive-only or user specified 'ap:-').
	if base.verb_form == "I" and not base.forms.ap and base.forms.ap1 and not skip_slot(base, "ap") then
		local saw_non_stative = false
		for _, vowel_spec in ipairs(base.conj_vowels) do
			if req(vowel_spec.past, A) then
				saw_non_stative = true
				break
			end
		end
		if saw_non_stative then
			base.forms.ap = base.forms.ap1
			-- To make sure there aren't shared form objects.
			base.forms.ap1 = nil
		end
	end
end


local function handle_lemma_linked(base)
	-- Compute linked versions of potential lemma slots, for use in {{ar-verb}}. We substitute the original lemma
	-- (before removing links) for forms that are the same as the lemma, if the original lemma has links.
	for _, slot in ipairs(export.potential_lemma_slots) do
		if base.forms[slot] then
			insert_form_or_forms(base, slot .. "_linked", iut.map_forms(base.forms[slot], function(form)
				if form == base.lemma and rfind(base.linked_lemma, "%[%[") then
					return base.linked_lemma
				else
					return form
				end
			end))
		end
	end
end


-- Process specs given by the user using 'addnote[SLOTSPEC][FOOTNOTE][FOOTNOTE][...]'.
local function process_addnote_specs(base)
	for _, spec in ipairs(base.addnote_specs) do
		for _, slot_spec in ipairs(spec.slot_specs) do
			slot_spec = "^" .. slot_spec .. "$"
			for slot, forms in pairs(base.forms) do
				if rfind(slot, slot_spec) then
					-- To save on memory, side-effect the existing forms.
					for _, form in ipairs(forms) do
						form.footnotes = iut.combine_footnotes(form.footnotes, spec.footnotes)
					end
				end
			end
		end
	end
end


local function add_missing_links_to_forms(base)
	-- Any forms without links should get them now. Redundant ones will be stripped later.
	for slot, forms in pairs(base.forms) do
		for _, form in ipairs(forms) do
			if not form.form:find("%[%[") then
				form.form = "[[" .. form.form .. "]]"
			end
		end
	end
end


local function conjugate_verb(base)
	construct_stems(base)
	for _, vowel_spec in ipairs(base.conj_vowels) do
		-- Reconstruct conjugation type from verb form and (possibly inferred) weakness.
		conj_type = base.verb_form .. "-" .. vowel_spec.weakness

		-- Check that the conjugation type is recognized.
		if not conjugations[conj_type] then
			error("Unknown conjugation type '" .. conj_type .. "'")
		end

		-- The way the conjugation functions work is they always add entries to the appropriate parts of the paradigm
		-- (each of which is an array), rather than setting the values. This makes it possible to call more than one
		-- conjugation function and essentially get a paradigm of the "either A or B" kind. Doing this may insert
		-- duplicate entries into a particular paradigm part, but this is not a problem because we check for duplicate
		-- entries when adding them, and don't insert in that case.
		conjugations[conj_type](base, vowel_spec)
	end
	postprocess_forms(base)
	process_slot_overrides(base)
	-- This should happen before add_missing_links_to_forms() so that the comparison `form == base.lemma` in
	-- handle_lemma_linked() works correctly and compares unlinked forms to unlinked forms.
	handle_lemma_linked(base)
	process_addnote_specs(base)
	if not base.alternant_multiword_spec.args.noautolinkverb then
		add_missing_links_to_forms(base)
	end
end


local function parse_indicator_spec(angle_bracket_spec)
	-- Store the original angle bracket spec so we can reconstruct the overall conj spec with the lemma(s) in them.
	local base = {
		angle_bracket_spec = angle_bracket_spec,
		conj_vowels = {},
		root_consonants = {},
		user_stem_overrides = {},
		user_slot_overrides = {},
		slot_explicitly_missing = {},
		slot_uncertain = {},
		slot_override_uses_default = {},
		addnote_specs = {},
	}
	local function parse_err(msg)
		error(msg .. ": " .. angle_bracket_spec)
	end
	local function fetch_footnotes(separated_group)
		local footnotes
		for j = 2, #separated_group - 1, 2 do
			if separated_group[j + 1] ~= "" then
				parse_err("Extraneous text after bracketed footnotes: '" .. table.concat(separated_group) .. "'")
			end
			if not footnotes then
				footnotes = {}
			end
			table.insert(footnotes, separated_group[j])
		end
		return footnotes
	end

	local inside = angle_bracket_spec:match("^<(.*)>$")
	assert(inside)
	local segments = iut.parse_multi_delimiter_balanced_segment_run(inside, {{"[", "]"}, {"<", ">"}})
	local dot_separated_groups = iut.split_alternating_runs_and_strip_spaces(segments, "%.")

	-- The first dot-separated element must specify the verb form, e.g. IV or IIq. If the form is I, it needs to include
	-- the the past and non-past vowels, e.g.  I/a~u for kataba ~ yaktubu. More than one vowel can be given,
	-- comma-separated, and more than one past~non-past pair can be given, slash-separated, e.g. I/a,u~u/i~a for form I
	-- كمل, which can be conjugated as kamala/kamula ~ yakmulu or kamila ~ yakmalu. An individual vowel spec must be one
	-- of a, i or u and in general (a) at least one past~non-past pair most be given, and (b) both past and non-past
	-- vowels must be given even though sometimes the vowel can be determined from the unvocalized form. An exception is
	-- passive-only verbs, where the vowels can't in general be determined (except indirectly in some cases by looking
	-- at an associated non-passive verb); in that case, the vowel~vowel spec can left out.
	local slash_separated_groups = iut.split_alternating_runs_and_strip_spaces(dot_separated_groups[1], "/")
	local form_spec = slash_separated_groups[1]
	base.form_footnotes = fetch_footnotes(form_spec)
	if form_spec[1] == "" then
		parse_err("Missing verb form")
	end
	if not allowed_vforms_with_weakness_set[form_spec[1]] then
		parse_err(("Unrecognized verb form '%s', should be one of %s"):format(
			form_spec[1], m_table.serialCommaJoin(allowed_vforms, {conj = "or", dontTag = true})))
	end
	if form_spec[1]:find("%-") then
		base.verb_form, base.explicit_weakness = form_spec[1]:match("^(.-)%-(.*)$")
	else
		base.verb_form = form_spec[1]
	end

	if #slash_separated_groups > 1 then
		if base.verb_form ~= "I" then
			parse_err(("Past~non-past vowels can only be specified when verb form is I, but saw form '%s'"):format(
				base.verb_form))
		end
		for i = 2, #slash_separated_groups do
			local slash_separated_group = slash_separated_groups[i]
			local tilde_separated_groups = iut.split_alternating_runs_and_strip_spaces(slash_separated_group, "~")
			if #tilde_separated_groups ~= 2 then
				parse_err(("Expected two tilde-separated vowel specs: %s"):format(table.concat(slash_separated_group)))
			end
			local function parse_conj_vowels(tilde_separated_group, vtype)
				local conj_vowel_objects = {}
				local comma_separated_groups = iut.split_alternating_runs_and_strip_spaces(tilde_separated_group, ",")
				for _, comma_separated_group in ipairs(comma_separated_groups) do
					local conj_vowel = comma_separated_group[1]
					if conj_vowel ~= "a" and conj_vowel ~= "i" and conj_vowel ~= "u" then
						parse_err(("Expected %s conjugation vowel '%s' to be one of a, i or u in %s"):format(
							vtype, conj_vowel, table.concat(slash_separated_group)))
					end
					conj_vowel = dia[conj_vowel]
					local conj_vowel_footnotes = fetch_footnotes(comma_separated_group)
					-- Try to use strings when possible as it makes q() significantly more efficient.
					if conj_vowel_footnotes then
						table.insert(conj_vowel_objects, {form = conj_vowel, footnotes = conj_vowel_footnotes})
					else
						table.insert(conj_vowel_objects, conj_vowel)
					end
				end
				return conj_vowel_objects
			end
			local conj_vowel_spec = {
				past = parse_conj_vowels(tilde_separated_groups[1], "past"),
				nonpast = parse_conj_vowels(tilde_separated_groups[2], "non-past"),
			}
			table.insert(base.conj_vowels, conj_vowel_spec)
		end
	end

	for i = 2, #dot_separated_groups do
		local dot_separated_group = dot_separated_groups[i]
		local first_element = dot_separated_group[1]
		if first_element == "addnote" then
			local spec_and_footnotes = fetch_footnotes(dot_separated_group)
			if #spec_and_footnotes < 2 then
				parse_err("Spec with 'addnote' should be of the form 'addnote[SLOTSPEC][FOOTNOTE][FOOTNOTE][...]'")
			end
			local slot_spec = table.remove(spec_and_footnotes, 1)
			local slot_spec_inside = rmatch(slot_spec, "^%[(.*)%]$")
			if not slot_spec_inside then
				parse_err("Internal error: slot_spec " .. slot_spec .. " should be surrounded with brackets")
			end
			local slot_specs = rsplit(slot_spec_inside, ",")
			-- FIXME: Here, [[Module:it-verb]] called strip_spaces(). Generally we don't do this. Should we?
			table.insert(base.addnote_specs, {slot_specs = slot_specs, footnotes = spec_and_footnotes})
		elseif first_element:find("^var:") then
			if #dot_separated_group > 1 then
				parse_err(("Can't attach footnotes to 'var:' spec '%s'"):format(first_element))
			end
			base.variant = first_element:match("^var:(.*)$")
		elseif first_element:find("^I+V?:") then
			local root_cons, root_cons_value = first_element:match("^(I+V?):(.*)$")
			local root_index
			if root_cons == "I" then
				root_index = 1
			elseif root_cons == "II" then
				root_index = 2
			elseif root_cons == "III" then
				root_index = 3
			elseif root_cons == "IV" then
				root_index = 4
				if not base.verb_form:find("q$") then
					parse_err(("Can't specify root consonant IV for non-quadriliteral verb form '%s': %s"):format(
						base.verb_form, first_element))
				end
			end
			local cons, translit = root_cons_value:match("^(.*)//(.*)$")
			if not cons then
				cons = root_cons_value
			end
			local root_footnotes = fetch_footnotes(dot_separated_group)
			if not translit and not root_footnotes then
				base.root_consonants[root_index] = cons
			else
				base.root_consonants[root_index] = {form = cons, translit = translit, footnotes = root_footnotes}
			end
		elseif first_element:find("^[a-z][a-z0-9_]*:") then
			local slot_or_stem, remainder = first_element:match("^(.-):(.*)$")
			dot_separated_group[1] = remainder
			local comma_separated_groups = iut.split_alternating_runs_and_strip_spaces(dot_separated_group, "[,،]")
			if overridable_stems[slot_or_stem] then
				if base.user_stem_overrides[slot_or_stem] then
					parse_err("Overridable stem '" .. slot_or_stem .. "' specified twice")
				end
				base.user_stem_overrides[slot_or_stem] = overridable_stems[slot_or_stem](comma_separated_groups,
					{prefix = slot_or_stem, base = base, parse_err = parse_err, fetch_footnotes = fetch_footnotes})
			else -- assume a form override; we validate further later when the possible slots are available
				if base.user_slot_overrides[slot_or_stem] then
					parse_err("Form override '" .. slot_or_stem .. "' specified twice")
				end
				base.user_slot_overrides[slot_or_stem] = allow_multiple_values_for_override(comma_separated_groups,
					{prefix = slot_or_stem, base = base, parse_err = parse_err, fetch_footnotes = fetch_footnotes},
					"is form override")
			end
		elseif indicator_flags[first_element] then
			if #dot_separated_group > 1 then
				parse_err("No footnotes allowed with '" .. first_element .. "' spec")
			end
			if base[first_element] then
				parse_err("Spec '" .. first_element .. "' specified twice")
			end
			base[first_element] = true
		else
			local passive, uncertain = first_element:match("^(.*)(%?)$")
			passive = passive or first_element
			uncertain = not not uncertain
			if passive_types[passive] then
				if #dot_separated_group > 1 then
					parse_err("No footnotes allowed with '" .. passive .. "' spec")
				end
				if base.passive then
					parse_err("Value for passive type specified twice")
				end
				base.passive = passive
				base.passive_uncertain = uncertain
			else
				parse_err("Unrecognized spec '" .. first_element .. "'")
			end
		end
	end

	return base
end


-- Normalize all lemmas, substituting the pagename for blank lemmas and adding links to multiword lemmas.
local function normalize_all_lemmas(alternant_multiword_spec, head)

	-- (1) Add links to all before and after text. Remember the original text so we can reconstruct the verb spec later.
	if not alternant_multiword_spec.args.noautolinktext then
		iut.add_links_to_before_and_after_text(alternant_multiword_spec, "remember original")
	end

	-- (2) Remove any links from the lemma, but remember the original form so we can use it below in the 'lemma_linked'
	--     form.
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.lemma == "" then
			base.lemma = head
		end

		base.user_specified_lemma = base.lemma

		base.lemma = m_links.remove_links(base.lemma)
		base.user_specified_verb = base.lemma
		base.verb = base.user_specified_verb

		local linked_lemma
		if alternant_multiword_spec.args.noautolinkverb or base.user_specified_lemma:find("%[%[") then
			linked_lemma = base.user_specified_lemma
		else
			-- Add links to the lemma so the user doesn't specifically need to, since we preserve
			-- links in multiword lemmas and include links in non-lemma forms rather than allowing
			-- the entire form to be a link.
			linked_lemma = iut.add_links(base.user_specified_lemma)
		end
		base.linked_lemma = linked_lemma
	end)
end


-- Determine weakness from radicals. Used when root given in place of lemma (e.g. for {{ar-verb forms}}).
local function weakness_from_radicals(form, rad1, rad2, rad3, rad4)
	local weakness = nil
	local quadlit = form:find("q$")
	-- If weakness unspecified, derive from radicals.
	if not quadlit then
		if is_waw_ya(rad3) and rad1 == W and form == "I" then
			weakness = "assimilated+final-weak"
		elseif is_waw_ya(rad3) and vform_supports_final_weak(form) then
			weakness = "final-weak"
		elseif rad2 == rad3 and vform_supports_geminate(form) then
			weakness = "geminate"
		elseif is_waw_ya(rad2) and vform_supports_hollow(form) then
			weakness = "hollow"
		elseif rad1 == W and form == "I" then
			weakness = "assimilated"
		else
			weakness = "sound"
		end
	else
		if is_waw_ya(rad4) then
			weakness = "final-weak"
		else
			weakness = "sound"
		end
	end
	return weakness
end

-- Join the infixed tāʔ (ت) to the first radical in form VIII verbs. This may cause assimilation of the tāʔ to the
-- radical or in some cases the radical to the tāʔ. Used when a root is supplied instead of a lemma (which already has
-- the appropriate assimilation in it).
local function form_viii_join_ta(rad)
	if rad == W or rad == Y or rad == "ت" then return "تّ"
	elseif rad == "د" then return "دّ"
	elseif rad == "ث" then return "ثّ"
	elseif rad == "ذ" then return "ذّ"
	elseif rad == "ز" then return "زْد"
	elseif rad == "ص" then return "صْط"
	elseif rad == "ض" then return "ضْط"
	elseif rad == "ط" then return "طّ"
	elseif rad == "ظ" then return "ظّ"
	else return rad .. SK .. "ت"
	end
end


local function detect_indicator_spec(base)
	base.forms = {}
	base.stem_overrides = {}
	base.slot_overrides = {}

	if not base.conj_vowels[1] then
		-- These may be converted to inferred vowels. If not, we throw an error if form I and not passive-only.
		base.conj_vowels = {{
			past = "-",
			nonpast = "-",
		}}
	else
		-- If multiple vowels specified for a given vowel type (e.g. a,u~u), expand so that each spec in
		local expansion = {}
		for _, spec in ipairs(base.conj_vowels) do
			for _, past in ipairs(spec.past) do
				for _, nonpast in ipairs(spec.nonpast) do
					table.insert(expansion, {past = past, nonpast = nonpast})
				end
			end
		end
		base.conj_vowels = expansion
	end

	local vform = base.verb_form

	-- check for quadriliteral form (Iq, IIq, IIIq, IVq)
	base.quadlit = not not vform:find("q$")

	-- Infer radicals as necessary. We infer a separate set of radicals for each past~non-past vowel combination because
	-- they may be different (particularly with form-I hollow verbs).
	for _, vowel_spec in ipairs(base.conj_vowels) do
		-- NOTE: rad1, rad2, etc. refer to user-specified radicals, which are formobj tables that optionally specify an
		-- explicit manual translit, whereas ir1, ir2, etc. refer to inferred radicals, which are either strings or
		-- lists of possible radicals.
		local rads = base.root_consonants
		local rad1, rad2, rad3, rad4 = rads[1], rads[2], rads[3], rads[4]

		-- Default any unspecified radicals to radicals determined from the headword. The returned radicals may be
		-- lists of possible radicals, where the first radical should be chosen if the user didn't explicitly specify a
		-- radical but all are allowed. If `ambig = true` is set in the table, the radical is considered ambiguous and
		-- categories won't be created for weak radicals.
		local weakness, ir1, ir2, ir3, ir4
		if vform ~= "none" then
			ir1, ir2, ir3 = rmatch(base.lemma, "^([^_])_([^_])_([^_])$")
			if not ir1 then
				ir1, ir2, ir3, ir4 = rmatch(base.lemma, "^([^_])_([^_])_([^_])_([^_])$")
			end
			if ir1 then
				-- root given instead of lemma
				weakness = weakness_from_radicals(vform, ir1, ir2, ir3, ir4)
				if vform == "VIII" then
					vowel_spec.form_viii_assim = form_viii_join_ta(ir1)
				end
			else
				local ret = export.infer_radicals {
					headword = base.lemma,
					vform = vform,
					passive = base.passive,
					past_vowel = vowel_spec.past,
					nonpast_vowel = vowel_spec.nonpast,
					is_reduced = base.reduced,
				}
				weakness, ir1, ir2, ir3, ir4 = ret.weakness, ret.rad1, ret.rad2, ret.rad3, ret.rad4
				vowel_spec.form_viii_assim = ret.form_viii_assim
				vowel_spec.past = ret.past_vowel
				vowel_spec.nonpast = ret.nonpast_vowel
				vowel_spec.variant = base.variant or ret.variant
			end
		end

		-- For most ambiguous radicals, the choice of radical doesn't matter because it doesn't affect the conjugation
		-- one way or another.  For form I hollow verbs, however, it definitely does. In fact, the choice of radical is
		-- critical even beyond the past and non-past vowels because it affects the form of the passive participle.  So,
		-- check for this and signal an error if the radical could not be inferred and is not given explicitly.
		if vform == "I" and type(ir2) == "table" and ir2.need_radical and not rad2 then
			error("Unable to guess middle radical of hollow form I verb; need to specify radical explicitly")
		end

		if vform == "I" and not is_passive_only(base.passive) and (
			rget(vowel_spec.past) == "-" or rget(vowel_spec.nonpast) == "-") then
			error("Form I verb that isn't passive-only or final-weak must have past~non-past vowels specified")
		end

		-- Convert ambiguous radicals.
		local function regularize_inferred_radical(rad)
			if type(rad) == "table" then
				if rad.ambig then
					return {form = rad[1], ambig = true}
				else
					return rad[1]
				end
			else
				return rad
			end
		end

		-- Return the appropriate radical at index `index` (1 through 4), based either on the user-specified radical
		-- `user_radical` or (if unspecified) `inferred_radical`, inferred from the unvocalized lemma. Two values are
		-- returned, the "regularized" version of the radical (where ambiguous inferred radicals are converted to their
		-- most likely actual radical) and the non-regularized version. The returned values are form objects rather than
		-- strings.
		local function fetch_radical(user_radical, inferred_radical, index)
			if not user_radical then
				return regularize_inferred_radical(inferred_radical), inferred_radical
			else
				local rad_formval = rget(user_radical)
				if type(inferred_radical) == "table" then
					local allowed_radical_set = m_table.listToSet(inferred_radical)
					if not allowed_radical_set[rad_formval] then
						error(("For lemma %s, radical %s ambiguously inferred as %s but user radical incompatibly given as %s"):
						format(base.lemma, index,
						m_table.serialCommaJoin(inferred_radical, {conj = "or", dontTag = true}), rad_formval))
					end
				elseif rad_formval ~= inferred_radical then
					error(("For lemma %s, radical %s inferred as %s but user radical incompatibly given as %s"):
					format(base.lemma, index, inferred_radical, rad_formval))
				end
				return user_radical, user_radical
			end
		end

		if vform ~= "none" then
			vowel_spec.rad1, vowel_spec.unreg_rad1 = fetch_radical(rad1, ir1, 1)
			vowel_spec.rad2, vowel_spec.unreg_rad2 = fetch_radical(rad2, ir2, 2)
			vowel_spec.rad3, vowel_spec.unreg_rad3 = fetch_radical(rad3, ir3, 3)
			if base.quadlit then
				vowel_spec.rad4, vowel_spec.unreg_rad4 = fetch_radical(rad4, ir4, 4)
			end
		end

		if vform == "I" then
			-- If explicit weakness given using 'I-sound' or 'I-assimilated', we may need to adjust the inferred weakness.
			if base.explicit_weakness == "sound" then
				if weakness == "assimilated" then
					weakness = "sound"
				elseif weakness == "assimilated+final-weak" then
					-- Verbs like waniya~yawnā "to be faint; to languish" (although the defaults should handle this
					-- correctly)
					weakness = "final-weak"
				else
					error(("Can't specify form 'I-sound' when inferred weakness is '%s' for lemma %s"):format(
						weakness, base.lemma))
				end
			elseif base.explicit_weakness == "assimilated" then
				if weakness == "sound" then
					-- i~a verbs like waṭiʔa~yaṭaʔu "to tread, to trample"; wasiʕa~yasaʕu "to be spacious; to be well-off";
					-- waṯiʔa~yaṯaʔu "to get bruised, to be sprained", which would default to sound.
					weakness = "assimilated"
				elseif weakness == "final-weak" then
					-- For completeness; not clear if any verbs occur where this is needed. (There are plenty of
					-- assimilated+final-weak verbs but the defaults should take care of them.)
					weakness = "assimilated+final-weak"
				else
					error(("Can't specify form 'I-assimilated' when inferred weakness is '%s' for lemma %s"):format(
						weakness, base.lemma))
				end
			elseif base.explicit_weakness then
				error(("Internal error: Unrecognized value '%s' for base.explicit_weakness"):format(base.explicit_weakness))
			end
		elseif vform == "none" then
			weakness = base.explicit_weakness
		elseif base.explicit_weakness then
			error(("Internal error: Explicit weakness should not be specifiable except with forms I and none, but saw explicit weakness '%s' with verb form '%s'"):
				format(base.explicit_weakness, vform))
		end

		vowel_spec.weakness = weakness

		if vform ~= "none" then
			-- Error if radicals are wrong given the weakness. More likely to happen if the weakness is explicitly given
			-- rather than inferred. Will also happen if certain incorrect letters are included as radicals e.g. hamza on
			-- top of various letters, alif maqṣūra, tā' marbūṭa.
			check_radicals(vform, weakness, rget(vowel_spec.rad1), rget(vowel_spec.rad2), rget(vowel_spec.rad3),
				base.quadlit and rget(vowel_spec.rad4) or nil)
		end

		-- Check the variant value.
		local form_iii_vi_geminate = (vform == "III" or vform == "VI") and rget(vowel_spec.rad2) == rget(vowel_spec.rad3) and
			not req(vowel_spec.rad2, Y)
		local hayy_i_x = hayy_radicals(vowel_spec.rad1, vowel_spec.rad2, vowel_spec.rad3) and (vform == "I" or vform == "X")
		if form_iii_vi_geminate or hayy_i_x then
			if vowel_spec.variant and vowel_spec.variant ~= "long" and vowel_spec.variant ~= "short" and vowel_spec.variant ~= "both" then
				error(("For form-III/VI geminate verb or form-I/X verb with ح-ي-ي radicals, saw unrecognized 'var:%s' value; should be 'var:long', 'var:short' or 'var:both'"):format(
					vowel_spec.variant))
			end
		elseif vowel_spec.variant then
			error(("Variant value 'var:%s' not allowed in this context"):format(vowel_spec.variant))
		end
	end

	-- If form I, regroup expanded vowels for display purposes.
	if vform == "I" then
		local group_by_past = {}
		for _, vowel_spec in ipairs(base.conj_vowels) do
			m_table.insertIfNot(group_by_past, {
				past = undia[rget(vowel_spec.past)],
				nonpasts = {undia[rget(vowel_spec.nonpast)]},
			}, {
				key = function(obj) return obj.past end,
				combine = function(obj1, obj2)
					for _, nonpast in ipairs(obj2.nonpasts) do
						m_table.insertIfNot(obj1.nonpasts, nonpast)
					end
				end,
			})
		end
		local group_by_nonpast = {}
		for _, vowel_spec in ipairs(group_by_past) do
			m_table.insertIfNot(group_by_nonpast, {
				pasts = {vowel_spec.past},
				nonpasts = vowel_spec.nonpasts,
			}, {
				key = function(obj) return obj.nonpasts end,
				combine = function(obj1, obj2)
					for _, past in ipairs(obj2.pasts) do
						m_table.insertIfNot(obj1.pasts, past)
					end
				end,
			})
		end
		base.grouped_conj_vowels = group_by_nonpast
	end

	-- Set value of passive. If not specified, default is yes for forms II, III, IV and Iq; no but uncertainly for
	-- forms VII, IX, XI - XV and IIIq - IVq, as well as form I with past vowel u; impersonal but uncertainly for form
	-- V, VI, X and IIq, as well as form I with past vowel i; and yes but uncertainly for the remainder (form I with
	-- past vowel only a and form VIII).
	if not base.passive then
		base.passive_defaulted = true
		-- Temporary tracking for defaulted passives by verb form, weakness and (for form I) past/non-past vowels.
		track_if_ar_conj(base, "passive-defaulted/" .. vform)
		for _, vowel_spec in ipairs(base.conj_vowels) do
			track_if_ar_conj(base, "passive-defaulted/" .. vform.. "/" .. vowel_spec.weakness)
			if vform == "I" then
				local past_nonpast = ("%s~%s"):format(undia[vowel_spec.past], undia[vowel_spec.nonpast])
				track_if_ar_conj(base, "passive-defaulted/I/" .. past_nonpast)
				track_if_ar_conj(base, "passive-defaulted/I/" .. vowel_spec.weakness .. "/" .. past_nonpast)
			end
		end
		if vform_probably_full_passive(vform) then
			base.passive = "pass"
		else
			base.passive_uncertain = true
			for _, vowel_spec in ipairs(base.conj_vowels) do
				if vform_probably_no_passive(vform, vowel_spec.weakness, vowel_spec.past, vowel_spec.nonpast) then
					base.passive = "nopass"
					break
				elseif vform_probably_impersonal_passive(vform, vowel_spec.weakness, vowel_spec.past,
					vowel_spec.nonpast) then
					base.passive = "ipass"
					break
				end
			end
			base.passive = base.passive or "pass"
		end
	end

	-- NOTE: Currently there are no built-in stems or form overrides for Arabic; this code is inherited from
	-- [[Module:ca-verb]], where such things do exist, and is kept for generality in case we decide in the future to
	-- implement such things.

	-- Override built-in verb stems and overrides with user-specified ones.
	for stem, values in pairs(base.user_stem_overrides) do
		base.stem_overrides[stem] = values
	end
	for slot, values in pairs(base.user_slot_overrides) do
		if not base.alternant_multiword_spec.verb_slots_map[slot] then
			error("Unrecognized override slot '" .. slot .. "': " .. base.angle_bracket_spec)
		end
		if export.unsettable_slots_set[slot] then
			error("Slot '" .. slot .. "' cannot be set using an override: " .. base.angle_bracket_spec)
		end
		if skip_slot(base, slot, "allow overrides") then
			error("Override slot '" .. slot ..
				"' would be skipped based on the passive, 'noimp' and/or 'no_nonpast' settings: " ..
				base.angle_bracket_spec)
		end
		base.slot_overrides[slot] = values
	end

	if base.verb_form == "none-final-weak" then
		for _, stem_type in ipairs { "past", "past_pass", "nonpast", "nonpast_pass" } do
			if base.stem_overrides[stem_type .. "_c"] or base.stem_overrides[stem_type .. "_v"] then
				error(("Specify past stem for verb type 'none-final-weak' using '%s:...' not '%s_c:...' or '%s_v:...'"):
					format(stem_type, stem_type, stem_type))
			end
		end
		for _, stem_type in ipairs { "past", "nonpast" } do
			if base.stem_overrides[stem_type] or not base.stem_overrides[stem_type .. "_final_weak_vowel"] then
				error(("For verb type 'none-final-weak', if '%s:...' specified, so must '%s_final_weak_vowel:...'"):
					format(stem_type, stem_type))
			end
		end
	end
end


local function detect_all_indicator_specs(alternant_multiword_spec)
	add_slots(alternant_multiword_spec)
	alternant_multiword_spec.verb_forms = {}
	-- This means at least one individual base had the slot marked as explicitly missing. Another base (e.g. when
	-- there are multiple alternants) might have a value for the slot. In practice, we only respect this when there are
	-- no overall values in the slot and `slot_uncertain` isn't set; in this case, we display "no ..." for the slot
	-- instead of simply not displaying anything for the slot.
	alternant_multiword_spec.slot_explicitly_missing = {}
	-- This means at least one individual base had no values for the slot and the slot marked as explicitly uncertain.
	-- Note that this is different from a value being present but marked as uncertain (e.g. if an override was given
	-- with a ? after it); this causes the form object for the value to have `uncertain = true` set. If there are no
	-- overall values in the slot and `slot_uncertain` is set, we display this in the headword.
	alternant_multiword_spec.slot_uncertain = {}

	iut.map_word_specs(alternant_multiword_spec, function(base)
		-- So arguments, etc. can be accessed. WARNING: Creates circular reference.
		base.alternant_multiword_spec = alternant_multiword_spec
		detect_indicator_spec(base)
		if not base.nocat then
			m_table.insertIfNot(alternant_multiword_spec.verb_forms, base.verb_form)
		end
		if base.passive_uncertain then
			alternant_multiword_spec.passive_uncertain = true
		end
		for slot, _ in pairs(base.slot_explicitly_missing) do
			alternant_multiword_spec.slot_explicitly_missing[slot] = true
		end
	end)
end

local function determine_slot_uncertainty_from_forms(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		-- If no verbal noun and verb form is not 'none' (manually-specified stems) — which currently only happens for
		-- form I — and the verbal noun wasn't explicitly indicated as missing using <vn:->, we assume it's just
		-- unknown/unspecified rather than missing. Same with active participles.
		for uncertain_slot, _ in pairs(slots_that_may_be_uncertain) do
			if not base.forms[uncertain_slot] and vform ~= "none" and not skip_slot(base, uncertain_slot) then
				base.slot_uncertain[uncertain_slot] = true
			end
		end
		-- Propagate slot uncertainty up. Currently only the verbal noun can have this set but we write the code
		-- generally.
		for slot, _ in pairs(base.slot_uncertain) do
			alternant_multiword_spec.slot_uncertain[slot] = true
		end
	end)
	-- If slot is uncertain and has no value, explicitly set its value to "?".
	for uncertain_slot, _ in pairs(slots_that_may_be_uncertain) do
		if not alternant_multiword_spec.forms[uncertain_slot] and
			alternant_multiword_spec.slot_uncertain[uncertain_slot] then
			alternant_multiword_spec.forms[uncertain_slot] = {{form = "?"}}
		end
	end
end

-- Determine certain properties of the verb from the overall forms, such as whether the verb is active-only or
-- passive-only, is impersonal, lacks an imperative, etc.
local function determine_verb_properties_from_forms(alternant_multiword_spec)
	alternant_multiword_spec.has_active = false
	alternant_multiword_spec.has_passive = false
	alternant_multiword_spec.has_non_impers_active = false
	alternant_multiword_spec.has_non_impers_passive = false
	alternant_multiword_spec.has_imp = false
	alternant_multiword_spec.has_past = false
	alternant_multiword_spec.has_nonpast = false
	for slot, _ in pairs(alternant_multiword_spec.forms) do
		if slot == "ap" or slot:find("[123]") and not slot:find("_pass") then
			alternant_multiword_spec.has_active = true
		end
		if slot == "pp" or slot:find("[123]") and slot:find("_pass") then
			alternant_multiword_spec.has_passive = true
		end
		if slot:find("[123]") and not slot:find("pass_[123]") and not slot:find("3ms") then
			alternant_multiword_spec.has_non_impers_active = true
		end
		if slot:find("pass_[123]") and not slot:find("3ms") then
			alternant_multiword_spec.has_non_impers_passive = true
		end
		if slot:find("^imp_") then
			alternant_multiword_spec.has_imp = true
		end
		if slot:find("^past_") then
			alternant_multiword_spec.has_past = true
		end
		if slot:find("^ind_") or slot:find("^sub_") or slot:find("^juss_") then
			alternant_multiword_spec.has_nonpast = true
		end
	end
end


local function add_categories_and_annotation(alternant_multiword_spec, base, multiword_lemma, insert_ann, insert_cat)
	-- Useful e.g. in constructing suppletive verbs out of parts. For a verb like جاء or أتى whose imperative comes
	-- from the unrelated verb تعالى, we don't want the latter verb showing up in categories or annotations.
	if base.nocat then
		return
	end

	local vform = base.verb_form
	if vform ~= "none" then
		insert_ann("form", vform)
		insert_cat("form-" .. vform .. " verbs")
	end
	if base.reduced then
		insert_ann("reduced", "reduced")
		if vform ~= "none" then
			insert_cat("form-" .. vform .. " reduced verbs")
		end
	end
	if base.quadlit then
		insert_cat("verbs with quadriliteral roots")
	end
	if base.passive_defaulted then
		insert_cat("verbs with defaulted passive")
	end

	for _, vowel_spec in ipairs(base.conj_vowels) do
		local rad1, rad2, rad3, rad4 = get_radicals_4(vowel_spec)
		local final_weak = is_final_weak(base, vowel_spec)
		local weakness = vowel_spec.weakness

		-- We have to distinguish weakness by form and weakness by conjugation. Weakness by form merely indicates the
		-- presence of weak letters in certain positions in the radicals. Weakness by conjugation is related to how the
		-- verbs are conjugated. For example, form-II verbs that are "hollow by form" (middle radical is wāw or yāʾ) are
		-- conjugated as sound verbs. Another example: form-I verbs with initial wāw are "assimilated by form" and most
		-- are assimilated by conjugation as well, but a few are sound by conjugation, e.g. wajuha yawjuhu "to be
		-- distinguished" (rather than wajuha yajuhu); similarly for some hollow-by-form verbs in various forms, e.g.
		-- form VIII izdawaja yazdawiju "to be in pairs" (rather than izdāja yazdāju). Categories referring to weakness
		-- always refer to weakness by conjugation; weakness by form is distinguished only by categories such as
		-- [[:Category:Arabic form-III verbs with و as second radical]].
		insert_ann("weakness", weakness)
		if vform ~= "none" then
			insert_cat(("%s form-%s verbs"):format(weakness, vform))
		end

		local function radical_is_ambiguous(rad)
			return type(rad) == "table" and rad.ambig
		end
		local function radical_is_unambiguous_weak(rad)
			return not radical_is_ambiguous(rad) and (is_waw_ya(rad) or req(rad, HAMZA))
		end

		if vform ~= "none" then
			local ur1, ur2, ur3, ur4 =
				vowel_spec.unreg_rad1, vowel_spec.unreg_rad2, vowel_spec.unreg_rad3, vowel_spec.unreg_rad4
			-- Create headword categories based on the radicals. Do the following before
			-- converting the Latin radicals into Arabic ones so we distinguish
			-- between ambiguous and non-ambiguous radicals.
			if radical_is_ambiguous(ur1) or radical_is_ambiguous(ur2) or radical_is_ambiguous(ur3) or
				ur4 and radical_is_ambiguous(ur4) then
				insert_cat("verbs with ambiguous radicals")
			end
			if radical_is_unambiguous_weak(ur1) then
				insert_cat("form-" .. vform ..  " verbs with " .. rget(ur1) .. " as first radical")
			end
			if radical_is_unambiguous_weak(ur2) then
				insert_cat("form-" .. vform ..  " verbs with " .. rget(ur2) .. " as second radical")
			end
			if radical_is_unambiguous_weak(ur3) then
				insert_cat("form-" .. vform ..  " verbs with " .. rget(ur3) .. " as third radical")
			end
			if ur4 and radical_is_unambiguous_weak(ur4) then
				insert_cat("form-" .. vform ..  " verbs with " .. rget(ur4) .. " as fourth radical")
			end
		end
	end

	if vform == "I" and not is_passive_only(base.passive) then
		for _, vowel_spec in ipairs(base.grouped_conj_vowels) do
			insert_ann("vowels",
				("%s ~ %s"):format(table.concat(vowel_spec.pasts, "/"), table.concat(vowel_spec.nonpasts, "/")))
			for _, past in ipairs(vowel_spec.pasts) do
				for _, nonpast in ipairs(vowel_spec.nonpasts) do
					if past == "-" or nonpast == "-" then
						error("Internal error: Saw form I past vowel %s and non-past vowel %s but - in place of vowel should have triggered an error earlier")
					end
					insert_cat(("form-I verbs with past vowel %s and non-past vowel %s"):format(past, nonpast))
				end
			end
		end
	end

	for slot, name in pairs(slots_that_may_be_uncertain) do
		if base.slot_uncertain[slot] then
			-- An unspecified and non-defaulted verbal noun (form I) is considered uncertain rather than explicitly
			-- missing. Use <vn:-> to explicitly indicate the lack of verbal noun. Same for form-I stative active
			-- participles.
			insert_cat(("verbs with unknown or uncertain %ss"):format(name))
		end
	end

	if base.irregular then
		insert_ann("irreg", "irregular")
		insert_cat("irregular verbs")
	end
end


-- Compute the categories to add the verb to, as well as the annotation to display in the conjugation title bar. We
-- combine the code to do these functions as both categories and title bar contain similar information.
local function compute_categories_and_annotation(alternant_multiword_spec)
	alternant_multiword_spec.categories = {}
	local ann = {}
	alternant_multiword_spec.annotation = ann
	ann.form = {}
	ann.weakness = {}
	ann.vowels = {}
	ann.passive = nil
	ann.reduced = {}
	ann.irreg = {}
	ann.defective = {}

	local multiword_lemma = false
    for _, slot in ipairs(export.potential_lemma_slots) do
        if alternant_multiword_spec.forms[slot] then
            for _, formobj in ipairs(alternant_multiword_spec.forms[slot]) do
				if formobj.form:find(" ") then
					multiword_lemma = true
					break
				end
            end 
            break
        end
    end 

	local function insert_ann(anntype, value)
		m_table.insertIfNot(alternant_multiword_spec.annotation[anntype], value)
	end

	local function insert_cat(cat, also_when_multiword)
		-- Don't place multiword terms in categories like 'Arabic form-II verbs' to avoid spamming the categories with
		-- such terms.
		if also_when_multiword or not multiword_lemma then
			m_table.insertIfNot(alternant_multiword_spec.categories, "Arabic " .. cat)
		end
	end

	iut.map_word_specs(alternant_multiword_spec, function(base)
		add_categories_and_annotation(alternant_multiword_spec, base, multiword_lemma, insert_ann, insert_cat)
	end)

	for slot, name in pairs(slots_that_may_be_uncertain) do
		if alternant_multiword_spec.forms[slot] then
			for _, form in ipairs(alternant_multiword_spec.forms[slot]) do
				if form.uncertain then
					if form.form == "?" then
						insert_cat(("verbs with explicitly unknown %ss"):format(name))
					else
						insert_cat(("verbs needing %s checked"):format(name))
					end
					break
				end
			end
		end
	end

	if alternant_multiword_spec.has_active then
		if alternant_multiword_spec.has_passive and alternant_multiword_spec.has_non_impers_passive then
			insert_cat("verbs with full passive")
			ann.passive = "full passive"
		elseif alternant_multiword_spec.has_passive then
			insert_cat("verbs with impersonal passive")
			ann.passive = "impersonal passive"
		else
			insert_cat("verbs lacking passive forms")
			ann.passive = "no passive"
		end
	else
		if alternant_multiword_spec.has_non_impers_passive then
			insert_cat("passive verbs")
			insert_cat("verbs with full passive")
			ann.passive = "passive-only"
		else
			insert_cat("passive verbs")
			insert_cat("impersonal verbs")
			insert_cat("verbs with impersonal passive")
			ann.passive = "impersonal (passive-only)"
		end
	end

	if alternant_multiword_spec.passive_uncertain then
		insert_cat("verbs needing passive checked")
		ann.passive = ann.passive .. ' <abbr title="passive status uncertain">(?)</abbr>'
	end

	if alternant_multiword_spec.has_active and not alternant_multiword_spec.has_imp then
		insert_ann("defective", "no imperative")
		insert_cat("verbs lacking imperative forms")
	end
	if not alternant_multiword_spec.has_past then
		insert_ann("defective", "no past")
		insert_cat("verbs lacking past forms")
	end
	if not alternant_multiword_spec.has_nonpast then
		insert_ann("defective", "no non-past")
		insert_cat("verbs lacking non-past forms")
	end

	local ann_parts = {}
	local function insert_ann_part(part, conj)
		local val = table.concat(ann[part], conj or " or ")
		if val ~= "" and val ~= "regular" then
			table.insert(ann_parts, val)
		end
	end

	insert_ann_part("form")
	insert_ann_part("weakness")
	insert_ann_part("reduced")
	insert_ann_part("vowels")
	if ann.passive then
		table.insert(ann_parts, ann.passive)
	end
	insert_ann_part("irreg")
	insert_ann_part("defective", ", ")
	alternant_multiword_spec.annotation = table.concat(ann_parts, ", ")
end


local function show_forms(alternant_multiword_spec)
    local lemmas = {}
    for _, slot in ipairs(export.potential_lemma_slots) do
        if alternant_multiword_spec.forms[slot] then
            for _, formobj in ipairs(alternant_multiword_spec.forms[slot]) do
                table.insert(lemmas, formobj)
            end 
            break
        end
    end 

	alternant_multiword_spec.lemmas = lemmas -- save for later use in make_table()
	alternant_multiword_spec.vn = alternant_multiword_spec.forms.vn -- save for later use in make_table()

	-- Reconstruct the original verb spec without overrides for verbal nouns and participles, since those specific slots
	-- are ignored by {{ar-verb form}}. Compute this once beforehand; `transform_accel_obj` is called repeatedly on each
	-- form and we don't want to compute this repeatedly.
	local reconstructed_verb_spec = iut.reconstruct_original_spec(alternant_multiword_spec, {
		preprocess_angle_bracket_spec = function(spec)
			spec = spec:match("^<(.*)>$")
			assert(spec)
			local segments = iut.parse_multi_delimiter_balanced_segment_run(spec, {{"[", "]"}, {"<", ">"}})
			local dot_separated_groups = iut.split_alternating_runs_and_strip_spaces(segments, "%.")
			-- Rejoin each dot-separated group into a single string, since we aren't actually going to do any parsing
			-- of bracket-bounded textual runs; then filter out overrides for verbal nouns and participles.
			local filtered_indicators = {}
			for _, dot_separated_group in ipairs(dot_separated_groups) do
				local indicator = table.concat(dot_separated_group)
				-- FIXME: Do we want to filter out any other indicators?
				if not (indicator:find("^vn:") or indicator:find("^[ap]p:")) then
					table.insert(filtered_indicators, indicator)
				end
			end
			return ("<%s>"):format(table.concat(filtered_indicators, "."))
		end,
	})

	-- If we're dealing with a single word, no alternants and a single verb form, use the auto-conjugation-fetching
	-- variant.
	local reconstructed_lemma, inside = reconstructed_verb_spec:match("^([^ <>()]+)(%b<>)$")
	if inside and alternant_multiword_spec.verb_forms[1] and not alternant_multiword_spec.verb_forms[2] then
		reconstructed_verb_spec = ("+%s<%s>"):format(reconstructed_lemma, alternant_multiword_spec.verb_forms[1])
	end

	local function transform_accel_obj(slot, formobj, accel_obj)
		if not accel_obj then
			return accel_obj
		end
		if slot == "ap" or slot == "pp" or slot == "vn" then
			-- FIXME: [[Module:accel]] can't correctly handle more than one verb form for participles and verbal nouns
			accel_obj.form = slot .. "-" .. table.concat(alternant_multiword_spec.verb_forms, ",")
		else
			accel_obj.form = "verb-form-" .. reconstructed_verb_spec
		end
		return accel_obj
	end

	local function generate_link(data)
		local form = data.form
		local term = form.formval_for_link
		local alt = form.alt
		if term == "?" then
			term = nil
			alt = "?"
		end
		local link = m_links.full_link {
			lang = lang, term = term, tr = "-", accel = form.accel_obj,
			alt = alt, gloss = form.gloss, genders = form.genders, pos = form.pos, lit = form.lit, id = form.id,
		} .. iut.get_footnote_text(form.footnotes, data.footnote_obj)
		if form.q and form.q[1] or form.qq and form.qq[1] or form.l and form.l[1] or form.ll and form.ll[1] then
			link = require(pron_qualifier_module).format_qualifiers {
				lang = lang,
				text = link,
				q = form.q,
				qq = form.qq,
				l = form.l,
				ll = form.ll,
			}
		end
		return link
	end

	local props = {
		lang = lang,
		lemmas = lemmas,
		transform_accel_obj = transform_accel_obj,
		generate_link = generate_link,
		slot_list = alternant_multiword_spec.verb_slots,
		include_translit = true,
	}
	iut.show_forms(alternant_multiword_spec.forms, props)
end


-------------------------------------------------------------------------------
--                    Functions to create inflection tables                  --
-------------------------------------------------------------------------------

-- Make the conjugation table. Called from export.show().
local function make_table(alternant_multiword_spec)
	local notes_template = [=[
<div style="width:100%;text-align:left;background:#d9ebff">
<div style="display:inline-block;text-align:left;padding-left:1em;padding-right:1em">
{footnote}
</div></div>
]=]

	local text = [=[
<div class="NavFrame ar-conj">
<div class="NavHead">&nbsp; &nbsp; Conjugation of {title}</div>
<div class="NavContent">

{\op}| class="inflection-table"
|-
! colspan="6" class="nonfinite-header" | verbal noun<br /><<الْمَصْدَر>>
| colspan="7" | {vn}
]=]

	if alternant_multiword_spec.has_active then
		text = text .. [=[
|-
! colspan="6" class="nonfinite-header" | active participle<br /><<اِسْم الْفَاعِل>>
| colspan="7" | {ap}
]=]
	end

	if alternant_multiword_spec.has_passive then
		text = text .. [=[
|-
! colspan="6" class="nonfinite-header" | passive participle<br /><<اِسْم الْمَفْعُول>>
| colspan="7" | {pp}
]=]
	end

	if alternant_multiword_spec.has_active then
		text = text .. [=[
|-
! colspan="12" class="voice-header" | active voice<br /><<الْفِعْل الْمَعْلُوم>>
|-
! colspan="2" class="empty-header" | 
! colspan="3" class="number-header" | singular<br /><<الْمُفْرَد>>
! rowspan="12" class="divider" | 
! colspan="2" class="number-header" | dual<br /><<الْمُثَنَّى>>
! rowspan="12" class="divider" | 
! colspan="3" class="number-header" | plural<br /><<الْجَمْع>>
|-
! colspan="2" class="empty-header" | 
! class="person-header" | 1<sup>st</sup> person<br /><<الْمُتَكَلِّم>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
! class="person-header" | 1<sup>st</sup> person<br /><<الْمُتَكَلِّم>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
|-
! rowspan="2" class="tam-header" | past (perfect) indicative<br /><<الْمَاضِي>>
! class="gender-header" | m
| rowspan="2" | {past_1s}
| {past_2ms}
| {past_3ms}
| rowspan="2" | {past_2d}
| {past_3md}
| rowspan="2" | {past_1p}
| {past_2mp}
| {past_3mp}
|-
! class="gender-header" | f
| {past_2fs}
| {past_3fs}
| {past_3fd}
| {past_2fp}
| {past_3fp}
|-
! rowspan="2" class="tam-header" | non-past (imperfect) indicative<br /><<الْمُضَارِع الْمَرْفُوع>>
! class="gender-header" | m
| rowspan="2" | {ind_1s}
| {ind_2ms}
| {ind_3ms}
| rowspan="2" | {ind_2d}
| {ind_3md}
| rowspan="2" | {ind_1p}
| {ind_2mp}
| {ind_3mp}
|-
! class="gender-header" | f
| {ind_2fs}
| {ind_3fs}
| {ind_3fd}
| {ind_2fp}
| {ind_3fp}
|-
! rowspan="2" class="tam-header" | subjunctive<br /><<الْمُضَارِع الْمَنْصُوب>>
! class="gender-header" | m
| rowspan="2" | {sub_1s}
| {sub_2ms}
| {sub_3ms}
| rowspan="2" | {sub_2d}
| {sub_3md}
| rowspan="2" | {sub_1p}
| {sub_2mp}
| {sub_3mp}
|-
! class="gender-header" | f
| {sub_2fs}
| {sub_3fs}
| {sub_3fd}
| {sub_2fp}
| {sub_3fp}
|-
! rowspan="2" class="tam-header" | jussive<br /><<الْمُضَارِع الْمَجْزُوم>>
! class="gender-header" | m
| rowspan="2" | {juss_1s}
| {juss_2ms}
| {juss_3ms}
| rowspan="2" | {juss_2d}
| {juss_3md}
| rowspan="2" | {juss_1p}
| {juss_2mp}
| {juss_3mp}
|-
! class="gender-header" | f
| {juss_2fs}
| {juss_3fs}
| {juss_3fd}
| {juss_2fp}
| {juss_3fp}
|-
! rowspan="2" class="tam-header" | imperative<br /><<الْأَمْر>>
! class="gender-header" | m
| rowspan="2" | 
| {imp_2ms}
| rowspan="2" | 
| rowspan="2" | {imp_2d}
| rowspan="2" | 
| rowspan="2" | 
| {imp_2mp}
| rowspan="2" | 
|-
! class="gender-header" | f
| {imp_2fs}
| {imp_2fp}
]=]
	end

	if alternant_multiword_spec.has_passive then
		text = text .. [=[
|-
! colspan="12" class="voice-header" | passive voice<br /><<الْفِعْل الْمَجْهُول>>
|-
| colspan="2" class="empty-header" | 
! colspan="3" class="number-header" | singular<br /><<الْمُفْرَد>>
| rowspan="10" class="divider" | 
! colspan="2" class="number-header" | dual<br /><<الْمُثَنَّى>>
| rowspan="10" class="divider" | 
! colspan="3" class="number-header" | plural<br /><<الْجَمْع>>
|-
| colspan="2" class="empty-header" | 
! class="person-header" | 1<sup>st</sup> person<br /><<الْمُتَكَلِّم>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
! class="person-header" | 1<sup>st</sup> person<br /><<الْمُتَكَلِّم>>
! class="person-header" | 2<sup>nd</sup> person<br /><<الْمُخَاطَب>>
! class="person-header" | 3<sup>rd</sup> person<br /><<الْغَائِب>>
|-
! rowspan="2" class="tam-header" | past (perfect) indicative<br /><<الْمَاضِي>>
! class="gender-header" | m
| rowspan="2" | {past_pass_1s}
| {past_pass_2ms}
| {past_pass_3ms}
| rowspan="2" | {past_pass_2d}
| {past_pass_3md}
| rowspan="2" | {past_pass_1p}
| {past_pass_2mp}
| {past_pass_3mp}
|-
! class="gender-header" | f
| {past_pass_2fs}
| {past_pass_3fs}
| {past_pass_3fd}
| {past_pass_2fp}
| {past_pass_3fp}
|-
! rowspan="2" class="tam-header" | non-past (imperfect) indicative<br /><<الْمُضَارِع الْمَرْفُوع>>
! class="gender-header" | m
| rowspan="2" | {ind_pass_1s}
| {ind_pass_2ms}
| {ind_pass_3ms}
| rowspan="2" | {ind_pass_2d}
| {ind_pass_3md}
| rowspan="2" | {ind_pass_1p}
| {ind_pass_2mp}
| {ind_pass_3mp}
|-
! class="gender-header" | f
| {ind_pass_2fs}
| {ind_pass_3fs}
| {ind_pass_3fd}
| {ind_pass_2fp}
| {ind_pass_3fp}
|-
! rowspan="2" class="tam-header" | subjunctive<br /><<الْمُضَارِع الْمَنْصُوب>>
! class="gender-header" | m
| rowspan="2" | {sub_pass_1s}
| {sub_pass_2ms}
| {sub_pass_3ms}
| rowspan="2" | {sub_pass_2d}
| {sub_pass_3md}
| rowspan="2" | {sub_pass_1p}
| {sub_pass_2mp}
| {sub_pass_3mp}
|-
! class="gender-header" | f
| {sub_pass_2fs}
| {sub_pass_3fs}
| {sub_pass_3fd}
| {sub_pass_2fp}
| {sub_pass_3fp}
|-
! rowspan="2" class="tam-header" | jussive<br /><<الْمُضَارِع الْمَجْزُوم>>
! class="gender-header" | m
| rowspan="2" | {juss_pass_1s}
| {juss_pass_2ms}
| {juss_pass_3ms}
| rowspan="2" | {juss_pass_2d}
| {juss_pass_3md}
| rowspan="2" | {juss_pass_1p}
| {juss_pass_2mp}
| {juss_pass_3mp}
|-
! class="gender-header" | f
| {juss_pass_2fs}
| {juss_pass_3fs}
| {juss_pass_3fd}
| {juss_pass_2fp}
| {juss_pass_3fp}
]=]
	end

	text = text .. [=[
|{\cl}{notes_clause}</div></div>]=]

	local forms = alternant_multiword_spec.forms

	if not alternant_multiword_spec.lemmas then
		forms.title = "—"
	else
		local linked_lemmas = {}
		for _, form in ipairs(alternant_multiword_spec.lemmas) do
			table.insert(linked_lemmas, link_term(form.form, "term"))
		end
		forms.title = table.concat(linked_lemmas, ", ")
	end

	local ann_parts = {}
	if alternant_multiword_spec.annotation ~= "" then
		table.insert(ann_parts, alternant_multiword_spec.annotation)
	end
	if alternant_multiword_spec.vn then
		local linked_vns = {}
		for _, form in ipairs(alternant_multiword_spec.vn) do
			table.insert(linked_vns, link_term(form.form, "term"))
		end
		table.insert(ann_parts, (#linked_vns > 1 and "verbal nouns" or "verbal noun") .. " " ..
			table.concat(linked_vns, ", "))
	end
	local annotation = table.concat(ann_parts, ", ")
	if annotation ~= "" then
		forms.title = forms.title .. " (" .. annotation .. ")"
	end

	-- Format the table.
	forms.notes_clause = forms.footnote ~= "" and m_string_utilities.format(notes_template, forms) or ""
	local tagged_table = rsub(text, "<<(.-)>>", tag_text)
	return m_string_utilities.format(tagged_table, forms) ..
		require("Module:TemplateStyles")("Template:ar-conj/style.css")
end

-------------------------------------------------------------------------------
--                              External entry points                        --
-------------------------------------------------------------------------------

-- Append two lists `l1` and `l2`, removing duplicates. If either is {nil}, just return the other.
local function combine_lists(l1, l2)
	-- combine_footnotes() does exactly what we want.
	return iut.combine_footnotes(l1, l2)
end

local function combine_metadata(data)
	local src1 = data.form1
	local src2 = data.form2
	local dest = data.dest_form
	dest.uncertain = src1.uncertain or src2.uncertain
	if src1.genders and src2.genders and not m_table.deepEquals(src1.genders, src2.genders) then
		-- do nothing
	else
		dest.genders = src1.genders or src2.genders
	end
	if src1.pos and src2.pos and src1.pos ~= src2.pos then
		-- do nothing
	else
		dest.pos = src1.pos or src2.pos
	end
	-- Don't copy .alt, .gloss, .lit, .id, which describe a single term and don't extend to multiword terms.
	dest.q = combine_lists(src1.q, src2.q)
	dest.qq = combine_lists(src1.qq, src2.qq)
	dest.l = combine_lists(src1.l, src2.l)
	dest.ll = combine_lists(src1.ll, src2.ll)
end

-- Externally callable function to parse and conjugate a verb given user-specified arguments.
-- Return value is WORD_SPEC, an object where the conjugated forms are in `WORD_SPEC.forms`
-- for each slot. If there are no values for a slot, the slot key will be missing. The value
-- for a given slot is a list of objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(args, source_template, headword_head)
	local PAGENAME = mw.loadData("Module:headword/data").pagename
	local function in_template_space()
		return mw.title.getCurrentTitle().nsText == "Template"
	end

	-- Determine the verb spec we're being asked to generate the conjugation of. This may be taken from the current page
	-- title or the value of |pagename=; but not when called from {{ar-verb form}}, where the page title is a
	-- non-lemma form. Note that the verb spec may omit the lemma; e.g. it may be "<II>". For this reason, we use the
	-- value of `pagename` computed here down below, when calling normalize_all_lemmas().
	local pagename = source_template ~= "ar-verb form" and args.pagename or PAGENAME
	local head = headword_head or pagename
	local arg1 = args[1]

	if not arg1 then
		if (pagename == "ar-conj" or pagename == "ar-verb" or pagename == "ar-verb form") and in_template_space() then
			arg1 = "كتب<I/a~u.pass>"
		else
			arg1 = "<>"
		end
	end

	-- When called from {{ar-verb form}}, determine the non-lemma form whose inflections we're being asked to
	-- determine. This normally comes from the page title or the value of |pagename=.
	local verb_form_of_form
	if source_template == "ar-verb form" then
		verb_form_of_form = args.pagename
		if not verb_form_of_form then
			if PAGENAME == "ar-verb form" and in_template_space() then
				verb_form_of_form = "كتبت"
			else
				verb_form_of_form = PAGENAME
			end
		end
	end

	local incorporated_headword_head_into_lemma = false
	if arg1:find("^<.*>$") then -- missing lemma
		if head:find(" ") then
			-- If multiword lemma, try to add arg spec after the first word.
			-- Try to preserve the brackets in the part after the verb, but don't do it
			-- if there aren't the same number of left and right brackets in the verb
			-- (which means the verb was linked as part of a larger expression).
			local first_word, post = rmatch(head, "^(.-)( .*)$")
			local left_brackets = rsub(first_word, "[^%[]", "")
			local right_brackets = rsub(first_word, "[^%]]", "")
			if #left_brackets == #right_brackets then
				arg1 = iut.remove_redundant_links(first_word) .. arg1 .. post
				incorporated_headword_head_into_lemma = true
			else
				-- Try again using the form without links.
				local linkless_head = m_links.remove_links(head)
				if linkless_head:find(" ") then
					first_word, post = rmatch(linkless_head, "^(.-)( .*)$")
					arg1 = first_word .. arg1 .. post
				else
					error("Unable to incorporate <...> spec into explicit head due to a multiword linked verb or " ..
						"unbalanced brackets; please include <> explicitly: " .. arg1)
				end
			end
		else
			-- Will be incorporated through `head` below in the call to normalize_all_lemmas().
			incorporated_headword_head_into_lemma = true
		end
	end

	local parse_props = {
		parse_indicator_spec = parse_indicator_spec,
		angle_brackets_omittable = true,
		allow_blank_lemma = true,
	}
	local alternant_multiword_spec = iut.parse_inflected_text(arg1, parse_props)
	alternant_multiword_spec.pos = pos or "verbs"
	alternant_multiword_spec.args = args
	alternant_multiword_spec.source_template = source_template
	alternant_multiword_spec.verb_form_of_form = verb_form_of_form
	alternant_multiword_spec.incorporated_headword_head_into_lemma = incorporated_headword_head_into_lemma

	normalize_all_lemmas(alternant_multiword_spec, head)
	detect_all_indicator_specs(alternant_multiword_spec)
	local inflect_props = {
		lang = lang,
		slot_list = alternant_multiword_spec.verb_slots,
		inflect_word_spec = conjugate_verb,
		combine_metadata = combine_metadata,
		-- We add links around the generated verbal forms rather than allow the entire multiword
		-- expression to be a link, so ensure that user-specified links get included as well.
		include_user_specified_links = true,
	}
	iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)
	if debug_translit then
		for slot, forms in pairs(alternant_multiword_spec.forms) do
			for _, form in ipairs(forms) do
				if form.translit then
					local full_form_translit = (lang:transliterate(m_links.remove_links(form.form)))
					if full_form_translit ~= form.translit then
						error(("Internal error: For slot '%s', form '%s' incremental translit '%s' not same as full translit '%s'"):
							format(slot, form.form, form.translit, full_form_translit))
					end
				end
				form.form = iut.remove_redundant_links(form.form)
			end
		end
	end

	-- Remove redundant brackets around entire forms.
	for slot, forms in pairs(alternant_multiword_spec.forms) do
		for _, form in ipairs(forms) do
			form.form = iut.remove_redundant_links(form.form)
		end
	end

	determine_slot_uncertainty_from_forms(alternant_multiword_spec)
	determine_verb_properties_from_forms(alternant_multiword_spec)
	compute_categories_and_annotation(alternant_multiword_spec)
	if args.json and source_template == "ar-conj" then
        -- There is a circular reference in `base.alternant_multiword_spec`, which points back to top level.
        iut.map_word_specs(alternant_multiword_spec, function(base)
            base.alternant_multiword_spec = nil
        end)
		return require("Module:JSON").toJSON(alternant_multiword_spec)
	end
	return alternant_multiword_spec
end


-- Entry point for {{ar-conj}}. Template-callable function to parse and conjugate a verb given
-- user-specified arguments and generate a displayable table of the conjugated forms.
function export.show(frame)
	local parent_args = frame:getParent().args
	local params = {
		[1] = {},
		["noautolinktext"] = {type = "boolean"},
		["noautolinkverb"] = {type = "boolean"},
		["t"] = {}, -- for use by {{ar-verb form}}; otherwise ignored
		["id"] = {}, -- for use by {{ar-verb form}}; otherwise ignored
		["pagename"] = {}, -- for testing/documentation pages
		["json"] = {type = "boolean"}, -- for bot use
	}
	local args = require("Module:parameters").process(parent_args, params)
	local alternant_multiword_spec = export.do_generate_forms(args, "ar-conj")
	if type(alternant_multiword_spec) == "string" then
		-- JSON return value
		return alternant_multiword_spec
	end
	show_forms(alternant_multiword_spec)
	return make_table(alternant_multiword_spec) ..
		require("Module:utilities").format_categories(alternant_multiword_spec.categories, lang, nil, nil, force_cat)
end


function export.verb_forms(frame)
	local parargs = frame:getParent().args
	local params = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		pagename = {},
	}
	for _, form in ipairs(allowed_vforms) do
		-- FIXME: We go up to 5 here. The code supports unlimited variants but it's unlikely we will ever see more than
		-- 2.
		for index = 1, 5 do
			local prefix = index == 1 and form or form .. index
			params[prefix .. "-pv"] = {}
			for _, extn in ipairs { "", "-vn", "-ap", "-pp" } do
				params[prefix .. extn] = {}
				params[prefix .. extn .. "-head"] = {}
				-- FIXME: No -tr?
				params[prefix .. extn .. "-gloss"] = {}
			end
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local i = 1
	local past_vowel_re = "^[aui,]*$"
	local combined_root = nil
	if not args[i] or rfind(args[i], past_vowel_re) then
		combined_root = args.pagename or mw.loadData("Module:headword/data").pagename
		if not rfind(combined_root, "^([^ ]) ([^ ]) ([^ ])$") and not
			rfind(combined_root, "^([^ ]) ([^ ]) ([^ ]) ([^ ])$") then
				error("When inferring roots from page title, need three or four space-separated radicals: " .. combined_root)
		end
	elseif rfind(args[i], " ") then
		combined_root = args[i]
		i = i + 1
	else
		local separate_roots = {}
		while args[i] and not rfind(args[i], past_vowel_re) do
			table.insert(separate_roots, args[i])
			i = i + 1
		end
		combined_root = table.concat(separate_roots, " ")
	end
	local past_vowel = args[i]
	i = i + 1
	if past_vowel and not rfind(past_vowel, past_vowel_re) then
		error("Unrecognized past vowel, should be 'a', 'i', 'u', 'a,u', etc. or empty: " .. past_vowel)
	end

	-- Spaces interfere with parsing as a unit in [[Module:inflection utilities]], so replace with underscore.
	combined_root = combined_root:gsub(" ", "_")
	local split_root = rsplit(combined_root, "_")
	-- Map from verb forms (I, II, etc.) to a table of verb properties,
	-- which has entries e.g. for "verb" (either true to autogenerate the verb
	-- head, or an explicitly specified verb head using e.g. argument "I-head"),
	-- and for "verb-gloss" (which comes from e.g. the argument "I" or "I-gloss"),
	-- and for "vn" and "vn-gloss", "ap" and "ap-gloss", "pp" and "pp-gloss".
	local verb_properties = {}
	for _, form in ipairs(allowed_vforms) do
		local formpropslist = {}
		local derivs = {{"verb", ""}, {"vn", "-vn"}, {"ap", "-ap"}, {"pp", "-pp"}}
		local index = 1
		while true do
			local formprops = {}
			local prefix = index == 1 and form or form .. index
			if prefix == "I" then
				formprops.pv = past_vowel
			end
			if args[prefix .. "-pv"] then
				formprops.pv = args[prefix .. "-pv"]
			end
			for _, deriv in ipairs(derivs) do
				local prop = deriv[1]
				local extn = deriv[2]
				if args[prefix .. extn] == "+" then
					formprops[prop] = true
				elseif args[prefix .. extn] == "-" then
					formprops[prop] = false
				elseif args[prefix .. extn] then
					formprops[prop] = true
					formprops[prop .. "-gloss"] = args[prefix .. extn]
				end
				if args[prefix .. extn .. "-head"] then
					if formprops[prop] == nil then
						formprops[prop] = true
					end
					formprops[prop] = args[prefix .. extn .. "-head"]
				end
				if args[prefix .. extn .. "-gloss"] then
					if formprops[prop] == nil then
						formprops[prop] = true
					end
					formprops[prop .. "-gloss"] = args[prefix .. extn .. "-gloss"]
				end
			end
			if formprops.verb then
				-- If a verb form specified, also turn on vn (unless form I, with
				-- unpredictable vn) and ap, and maybe pp, according to form,
				-- weakness and past vowel. But don't turn these on if there's
				-- an explicit on/off specification for them (e.g. I-pp=-).
				if form ~= "I" and formprops.vn == nil then
					formprops.vn = true
				end
				if formprops.ap == nil then
					formprops.ap = true
				end
				local weakness = weakness_from_radicals(form, split_root[1], split_root[2], split_root[3],
					split_root[4])
				if formprops.pp == nil and not vform_probably_no_passive(form,
						weakness, rsplit(formprops.pv or "", ","), {}) then
					formprops.pp = true
				end
				if formprops.verb == true or formprops.vn == true or formprops.ap == true or formprops.pp == true then
					formprops.need_autogen = true
				end
				table.insert(formpropslist, formprops)
				index = index + 1
			else
				break
			end
		end
		table.insert(verb_properties, {form, formpropslist})
	end

	-- Go through and create the verb form derivations as necessary, when they haven't been explicitly given.
	for _, vplist in ipairs(verb_properties) do
		local vform = vplist[1]
		for _, props in ipairs(vplist[2]) do
			if props.need_autogen then
				local form_with_vowels
				if vform == "I" then
					local pv = props.pv
					if not pv then
						-- Make up likely past vowels based on weakness and actual radical.
						if split_root[3] == W then -- final-weak
							form_with_vowels = "I/a~u"
						elseif split_root[3] == Y then
							form_with_vowels = "I/a~i"
						elseif split_root[2] == W then --hollow
							form_with_vowels = "I/u~u"
						elseif split_root[2] == Y then
							form_with_vowels = "I/i~i"
						else
							-- most common; doesn't matter so much since we're not displaying the non-past
							form_with_vowels = "I/a~u"
						end
					else
						local pvs = rsplit(pv, ",")
						local vowel_sufs = {}
						for _, pv in ipairs(pvs) do
							local vowel_spec
							if pv == "a" then
								-- Make up likely past vowels based on weakness and actual radical.
								if split_root[3] == W then -- final-weak
									vowel_spec = "a~u"
								elseif split_root[3] == Y then
									vowel_spec = "a~i"
								elseif split_root[2] == W then --hollow
									vowel_spec = "a~u"
								elseif split_root[2] == Y then
									vowel_spec = "a~i"
								else
									-- most common; doesn't matter so much since we're not displaying the non-past
									vowel_spec = "a~u"
								end
							elseif pv == "i" then
								-- most common; doesn't matter so much since we're not displaying the non-past
								vowel_spec = "i~a"
							elseif pv == "u" then
								-- most common; doesn't matter so much since we're not displaying the non-past
								vowel_spec = "u~u"
							else
								error(("Internal error: Bad past vowel '%s' in {{ar-verb forms}}"):format(pv))
							end
							table.insert(vowel_sufs, vowel_spec)
						end
						form_with_vowels = "I/" .. table.concat(vowel_sufs, "/")
					end
				else
					form_with_vowels = vform
				end

				local angle_bracket_spec = ("%s<%s.pass>"):format(combined_root, form_with_vowels)

				local alternant_multiword_spec = export.do_generate_forms({angle_bracket_spec}, "ar-verb forms")

				local function format_forms(forms)
					if not forms then
						return "-" -- FIXME: Throw an error?
					end
					local formatted = {}
					for _, form in ipairs(forms) do
						if form.translit then
							table.insert(formatted, ("%s//%s"):format(form.form, form.translit))
						else
							table.insert(formatted, form.form)
						end
					end
					return table.concat(formatted, ",")
				end

				if props.verb == true then
					props.verb = format_forms(alternant_multiword_spec.forms.past_3ms)
				end
				for _, deriv in ipairs({"vn", "ap", "pp"}) do
					if props[deriv] == true then
						props[deriv] = format_forms(alternant_multiword_spec.forms[deriv])
					end
				end
			end
		end
	end

    -- Go through and output the result
	local formtextarr = {}
	for _, vplist in ipairs(verb_properties) do
		local form = vplist[1]
		for _, props in ipairs(vplist[2]) do
			local textarr = {}
			if props.verb then
				local text = "* '''[[Appendix:Arabic verbs#Form " .. form .. "|Form " .. form .. "]]''': "
				local linktext = {}
				local splitheads = rsplit(props.verb, "[,،]")
				for _, head in ipairs(splitheads) do
					table.insert(linktext, m_links.full_link({lang = lang, term = head, gloss = props["verb-gloss"]}))
				end
				text = text .. table.concat(linktext, ", ")
				table.insert(textarr, text)
				for _, derivengl in ipairs({{"vn", "Verbal noun"}, {"ap", "Active participle"}, {"pp", "Passive participle"}}) do
					local deriv = derivengl[1]
					local engl = derivengl[2]
					if props[deriv] then
						local text = "** " .. engl .. ": "
						local linktext = {}
						local splitheads = rsplit(props[deriv], "[,،]")
						for _, head in ipairs(splitheads) do
							local ar, translit = head:match("^(.*)//(.-)$")
							if not ar then
								ar = head
							end
							table.insert(linktext, m_links.full_link {lang = lang, term = ar, tr = translit,
								gloss = props[deriv .. "-gloss"]} )
						end
						text = text .. table.concat(linktext, ", ")
						table.insert(textarr, text)
					end
				end
				table.insert(formtextarr, table.concat(textarr, "\n"))
			end
		end
	end

	return table.concat(formtextarr, "\n")
end


-- Infer radicals from lemma headword (i.e. 3rd masculine singular past) and verb form (I, II, etc.). Throw an error if
-- headword is malformed. A given returned radical may be actually be a list of possible radicals, where the first one
-- should be used if the user didn't explicitly give the radical. If the list contains a field `ambig = true`, the
-- radical is considered ambiguous and should not be categorized. `is_reduced` indicates that the user specified
-- `.reduced` to indicate that the verb form is reduced by assimilation and/or haplology (typically archaic Koranic
-- forms such as اِدَّارَأَ instead of تَدَارَأَ; or اِسْطَاعَ instead of اِسْتِطَاعَ; etc.
function export.infer_radicals(data)
	local headword, vform, passive, past_vowel, nonpast_vowel, is_reduced =
		data.headword, data.vform, data.passive, data.past_vowel, data.nonpast_vowel, data.is_reduced

	past_vowel = past_vowel or "-"
	nonpast_vowel = nonpast_vowel or "-"
	local function verify_vowel(vowel, param)
		if vowel ~= A and vowel ~= I and vowel ~= U and vowel ~= "-" then
			error(("Internal error: Bad value for %s: %s (should be Arabic diacritic vowel or '-')"):format(
				param, vowel))
		end
	end
	verify_vowel(past_vowel, "past_vowel")
	verify_vowel(nonpast_vowel, "nonpast_vowel")

	local ch = {}
	local form_viii_assim, variant
	-- sub out alif-madda for easier processing
	headword = rsub(headword, AMAD, HAMZA .. ALIF)

	local function infer_err(msg, noann)
		local anns = {}
		local nohead, novform
		if noann == "nohead" then
			nohead = true
		elseif noann == "novform" then
			novform = true
		elseif noann == "nohead-vform" then
			nohead = true
			novform = true
		elseif noann then
			error(("Internal error: Unrecognized value for 'noann': %s"):format(dump(noann)))
		end
		if not nohead then
			table.insert(anns, ("headword=%s"):format(data.headword))
		end
		if not novform then
			table.insert(anns, ("verb form=%s"):format(data.vform))
		end
		anns = table.concat(anns, ", ")
		if anns ~= "" then
			anns = ": " .. anns
		end
		error(msg .. anns)
	end
	local len = ulen(headword)
	local expected_length

	-- extract the headword letters into an array
	for i = 1, len do
		table.insert(ch, usub(headword, i, i))
	end

	-- check that the letter at the given index is the given string, or
	-- is one of the members of the given array
	local function check(index, must)
		local letter = ch[index]
		if type(must) == "string" then
			if not letter then
				infer_err("Letter " .. index .. " is nil")
			end
			if letter ~= must then
				infer_err(("For verb form %s, letter %s must be %s, not %s"):format(vform, index, must, letter),
					"novform")
			end
		elseif not m_table.contains(must, letter) then
			infer_err("For verb form " .. vform .. ", radical " .. index ..
				" must be one of " .. table.concat(must, " ") .. ", not " .. letter, "novform")
		end
	end

	-- Check that length of headword is within [min, max]
	local function check_len(min, max)
		if min and len < min then
			infer_err(("Not enough letters for verb form %s, expected at least %s"):format(vform, min), "novform")
		end
		if max and len > max then
			infer_err(("Too many letters for verb form %s, expected at most %s"):format(vform, max), "novform")
		end
	end

	-- If the vowels are i~a or u~u, a form I verb beginning with w- normally keeps the w in the non-past. Otherwise it
	-- loses it (i.e. it is "assimilated").
	local function form_I_w_non_assimilated()
		return req(past_vowel, I) and req(nonpast_vowel, A) or req(past_vowel, U) and req(nonpast_vowel, U)
	end

	-- Convert radicals to canonical form (handle various hamza varieties and check for misplaced alif or alif maqṣūra;
	-- legitimate cases of these letters are handled above).
	local function convert(rad, index)
		if type(rad) == "table" then
			for i, r in ipairs(rad) do
				rad[i] = convert(r, index)
			end
			return rad
		elseif rad == HAMZA_ON_ALIF or rad == HAMZA_UNDER_ALIF or
			rad == HAMZA_ON_W or rad == HAMZA_ON_Y then
			return HAMZA
		elseif rad == AMAQ then
			infer_err("Radical " .. index .. " must not be alif maqṣūra")
		elseif rad == ALIF then
			infer_err("Radical " .. index .. " must not be alif")
		else
			return rad
		end
	end

	local quadlit = vform:find("q$")

	-- find first radical, start of second/third radicals, check for
	-- required letters
	local radstart, rad1, rad2, rad3, rad4
	local weakness
	if vform == "I" or vform == "II" then
		rad1 = ch[1]
		radstart = 2
	elseif vform == "III" then
		rad1 = ch[1]
		check(2, {ALIF, W}) -- W occurs in passive-only verbs
		radstart = 3
	elseif vform == "IV" then
		-- this would be alif-madda but we replaced it with hamza-alif above.
		if ch[1] == HAMZA and ch[2] == ALIF then
			rad1 = HAMZA
		else
			check(1, HAMZA_ON_ALIF)
			rad1 = ch[2]
		end
		radstart = 3
	elseif vform == "V" then
		check(1, is_reduced and ALIF or T)
		rad1 = ch[2]
		radstart = 3
	elseif vform == "VI" then
		check(1, is_reduced and ALIF or T)
		if ch[2] == AMAD then
			rad1 = HAMZA
			radstart = 3
		else
			rad1 = ch[2]
			check(3, {ALIF, W}) -- W occurs in passive-only verbs
			radstart = 4
		end
	elseif vform == "VII" then
		check(1, ALIF)
		if is_reduced then
			check(2, M)
			rad1 = M
			radstart = 3
		else
			check(2, N)
			rad1 = ch[3]
			radstart = 4
		end
	elseif vform == "VIII" then
		check(1, ALIF)
		rad1 = ch[2]
		if rad1 == "د" then
			rad1 = {"د", "ذ"} -- not considered ambiguous since it's usually د
			radstart = 3
			form_viii_assim = "دّ"
		elseif rad1 == "ظ" and ch[3] == "ط" and len >= 5 then
			-- [[اظطلم]], variant of [[اظلم]]
			radstart = 4
			form_viii_assim = "ظْط"
		elseif rad1 == "ذ" and ch[3] == "د" and len >= 5 then
			-- [[اذدكر]], variant of [[اذكر]]
			radstart = 4
			form_viii_assim = "ذْد"
		elseif rad1 == T or rad1 == "ث" or rad1 == "ذ" or rad1 == "ط" or rad1 == "ظ" then
			radstart = 3
			form_viii_assim = rad1 .. SH
		elseif rad1 == "ز" then
			check(3, "د")
			radstart = 4
			form_viii_assim = "زْد"
		elseif rad1 == "ص" or rad1 == "ض"  then
			check(3, "ط")
			radstart = 4
			form_viii_assim = rad1 .. SK .. "ط"
		else
			check(3, T)
			radstart = 4
			rad1 = convert(rad1, 1)
			form_viii_assim = rad1 .. SK .. "ت"
		end
		if rad1 == T then
			-- Radical is ambiguous, might be ت or و or ي but doesn't affect conjugation. Note that there are no
			-- form-VIII verbs with initial radical ي given in Hans Wehr but Lane mentions at least:
			-- - (page 2973) اِتَّأَسَ, with assimilation of the ي to ت, from root ي ء س;
			-- - (page 2975) اِتَّبَسَ non-past يَتَّبِسُ and alternative اِيتَبَسَ non-past يَاتَبِسُ from the root ي ب س;
			-- - (page 2976) اِتَّسَرَ non-past يَتَّسِرُ or alternatively يَأْتَسِرُ with hamza preserved from the root ي س ر.
			-- These alternative forms seem very rare and probably not worth worrying about, but if we want to handle
			-- them, we can do it when the time comes.
			rad1 = {T, W, Y, ambig = true}
			-- اِتَّخَذَ irregularly has hamza as the radical but assimilates like و
			if ch[3] == "خ" and ch[4] == "ذ" then
				rad1[4] = HAMZA
			end
		end
	elseif vform == "IX" then
		check(1, ALIF)
		rad1 = ch[2]
		radstart = 3
	elseif vform == "X" then
		check(1, ALIF)
		check(2, S)
		if is_reduced then
			rad1 = ch[3]
			radstart = 4
		else
			check(3, T)
			rad1 = ch[4]
			radstart = 5
		end
	elseif vform == "Iq" then
		rad1 = ch[1]
		rad2 = ch[2]
		radstart = 3
	elseif vform == "IIq" then
		check(1, T)
		rad1 = ch[2]
		rad2 = ch[3]
		radstart = 4
	elseif vform == "IIIq" then
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		check(4, N)
		radstart = 5
	elseif vform == "IVq" then
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		radstart = 4
	elseif vform == "XI" then
		check_len(5, 5)
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		check(4, ALIF)
		rad3 = ch[5]
		weakness = "sound"
	elseif vform == "XII" then
		check(1, ALIF)
		rad1 = ch[2]
		if ch[3] ~= ch[5] then
			infer_err("For verb form XII, letters 3 and 5 should be the same", "novform")
		end
		check(4, W)
		radstart = 5
	elseif vform == "XIII" then
		check_len(5, 5)
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		check(4, W)
		rad3 = ch[5]
		if rad3 == AMAQ then
			weakness = "final-weak"
		else
			weakness = "sound"
		end
	elseif vform == "XIV" then
		check_len(6, 6)
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		check(4, N)
		rad3 = ch[5]
		if ch[6] == AMAQ then
			check_waw_ya(rad3)
			weakness = "final-weak"
		else
			if ch[5] ~= ch[6] then
				infer_err("For verb form XIV, letters 5 and 6 should be the same", "novform")
			end
			weakness = "sound"
		end
	elseif vform == "XV" then
		check_len(6, 6)
		check(1, ALIF)
		rad1 = ch[2]
		rad2 = ch[3]
		check(4, N)
		rad3 = ch[5]
		if rad3 == Y then
			check(6, ALIF)
		else
			check(6, AMAQ)
		end
		weakness = "sound"
	else
		error("Internal error: Unrecognized verb form " .. vform)
	end

	-- Process the last two radicals. RADSTART is the index of the first of the two. If it's nil then all radicals have
	-- already been processed above, and we don't do anything.
	if radstart then
		-- There must (normally) be one or two letters left.
		if len == radstart then
			if vform == "I" and ch[len] == Y then
				-- short form حَيَّ
				weakness = "final-weak"
				rad2 = Y
				rad3 = Y
				variant = "short"
			elseif vform == "IV" and rad1 == "ر" and ch[len] == AMAQ then
				-- irregular verb أَرَى
				weakness = "final-weak"
				rad2 = HAMZA
				rad3 = Y
			elseif vform == "X" and rad1 == "ح" and ch[len] == AMAQ then
				-- irregular verb اِسْتَحَى
				weakness = "final-weak"
				rad2 = Y
				rad3 = Y
				variant = "short"
			else
				-- If one letter left, then it's a geminate verb. If the letter is alif or alif maqṣūra, it will trigger
				-- an error down the line.
				if vform_supports_geminate(vform) then
					weakness = "geminate"
					rad2 = ch[len]
					rad3 = ch[len]
					if vform == "III" or vform == "VI" then
						variant = "short"
					end
				else
					infer_err("Apparent geminate verb, but geminate verbs not allowed for this verb form")
				end
			end
		elseif quadlit then
			-- Process last two radicals of a quadriliteral verb form.
			rad3 = ch[radstart]
			rad4 = ch[radstart + 1]
			expected_length = radstart + 1
			check_len(expected_length)
			if rad4 == AMAQ or rad4 == ALIF and rad3 == Y or rad4 == Y then
				-- rad4 can be Y in passive-only verbs.
				if vform_supports_final_weak(vform) then
					weakness = "final-weak"
					-- Ambiguous radical; randomly pick wāw as radical (but avoid two wāws in a row); it could be wāw or
					-- yāʾ, but doesn't affect the conjugation.
					rad4 = rad3 == W and {Y, W, ambig = true} or {W, Y, ambig = true}
				else
					infer_err("Last radical is " .. rad4 .. " but verb form " .. vform ..
						" doesn't support final-weak verbs", "novform")
				end
			else
				weakness = "sound"
			end
		else
			-- Process last two radicals of a triliteral verb form.
			rad2 = ch[radstart]
			rad3 = ch[radstart + 1]
			expected_length = radstart + 1
			check_len(expected_length)
			if vform == "I" and (is_waw_ya(rad3) or rad3 == ALIF or rad3 == AMAQ) then
				local inferred_past_vowel, inferred_nonpast_vowel
				-- Check for final-weak form I verb. It can end in tall alif (rad3 = wāw) or alif maqṣūra (rad3 = yāʾ)
				-- or a wāw or yāʾ (with a past vowel of i or u, e.g. nasiya/yansā "forget" or with a passive-only
				-- verb).
				if rad1 == W and not form_I_w_non_assimilated() then
					weakness = "assimilated+final-weak"
				else
					weakness = "final-weak"
				end
				if rad3 == ALIF then
					rad3 = W
					inferred_past_vowel = A
					inferred_nonpast_vowel = U
					if is_passive_only(passive) then
						infer_err("Final-weak form-I passive verbs should end in yāʔ (ي), not tall alif (ا)", "novform")
					end
				elseif rad3 == AMAQ then
					rad3 = Y
					inferred_past_vowel = A
					inferred_nonpast_vowel = I
					if is_passive_only(passive) then
						infer_err("Final-weak form-I passive verbs should end in yāʔ (ي), not alif maqṣūra (ى)",
							"novform")
					end
				elseif rad1 == "ح" and rad2 == Y and rad3 == Y then
					-- Long variant حَيِيَ.
					inferred_past_vowel = I
					inferred_nonpast_vowel = A
					variant = "long"
				else
					if not is_passive_only(passive) then
						-- does a non-passive final-weak verb in -uwa ever happen? (YES: e.g. [[رجو]] "to be slack")
						inferred_past_vowel = rad3 == Y and I or U
						inferred_nonpast_vowel = A
					end
					-- Ambiguous radical; randomly pick wāw as radical (but avoid two wāws); it could be wāw or yāʾ, but
					-- doesn't affect the conjugation.
					rad3 = (rad1 == W or rad2 == W) and {Y, W, ambig = true} or {W, Y, ambig = true} -- ambiguous
				end
				if inferred_past_vowel then
					local raw_past_vowel = rget(past_vowel)
					local raw_nonpast_vowel = rget(nonpast_vowel)
					if raw_past_vowel ~= "-" then
						if raw_past_vowel ~= inferred_past_vowel then
							infer_err(("Final-weak form-I verb inferred past vowel %s, which disagrees with " ..
								"explicitly specified %s"):format(undia[inferred_past_vowel], undia[raw_past_vowel]), "novform")
						else
							-- in case of footnote in past_vowel
							inferred_past_vowel = past_vowel
						end
					end
					if raw_nonpast_vowel ~= "-" and raw_nonpast_vowel ~= A and inferred_nonpast_vowel == U then
						-- if inferred as I or A, the reality can be the reverse; form-I final-weak verbs with a~a and
						-- i~i exist, e.g. سَعَى/يَسْعَى, وَلِيَ/يَلِي. Weird verb [[صها]] (also written [[صهى]]) has non-past
						-- يصهى so we can't throw an error in this situation.
						if raw_nonpast_vowel ~= inferred_nonpast_vowel then
							infer_err(("Final-weak form-I verb inferred non-past vowel %s, which disagrees with " ..
								"explicitly specified %s"):format(undia[inferred_nonpast_vowel], undia[raw_nonpast_vowel]), "novform")
						else
							-- in case of footnote in nonpast_vowel
							inferred_nonpast_vowel = nonpast_vowel
						end
					end
				end
				if not is_passive_only(passive) then
					if rget(past_vowel) == "-" then
						past_vowel = inferred_past_vowel
					end
					if rget(nonpast_vowel) == "-" then
						nonpast_vowel = inferred_nonpast_vowel
					end
				end
			elseif vform == "IX" and is_waw_ya(rad3) and len == radstart + 2 and ch[len] == AMAQ then
				-- Final-weak form IX verbs like اِرْعَوَى "to desist, to repent, to see the light".
				weakness = "final-weak"
				expected_length = radstart + 2
			elseif vform == "X" and rad1 == "ح" and rad2 == Y and rad3 == ALIF then
				-- Long variant اِسْتَحْيَا.
				weakness = "final-weak"
				rad3 = Y
				variant = "long"
			elseif rad3 == AMAQ or rad2 == Y and rad3 == ALIF or rad3 == Y then
				-- rad3 == Y happens in passive-only verbs.
				if vform_supports_final_weak(vform) then
					weakness = "final-weak"
				else
					infer_err("Last radical is " .. rad3 .. " but verb form doesn't support final-weak verbs")
				end
				-- Ambiguous radical; randomly pick wāw as radical (but avoid two wāws); it could be wāw or yāʾ, but
				-- doesn't affect the conjugation.
				rad3 = (rad1 == W or rad2 == W) and {Y, W, ambig = true} or {W, Y, ambig = true}
			elseif rad2 == ALIF then
				if vform_supports_hollow(vform) then
					weakness = "hollow"
					local function set_past_to_a()
						if req(past_vowel, A) then
							-- already set
						elseif req(past_vowel, "-") or req(past_vowel, rget(nonpast_vowel)) then
							past_vowel = A
						else
							infer_err(("Form I hollow verb with nonpast vowel set to '%s' must have past vowel set to 'a' or the same value, not %s"):
								format(undia[rget(nonpast_vowel)], undia[rget(past_vowel)]), "novform")
						end
					end
					if vform == "I" and req(nonpast_vowel, U) then
						rad2 = W
						set_past_to_a()
					elseif vform == "I" and req(nonpast_vowel, I) then
						rad2 = Y
						set_past_to_a()
					else
						if req(nonpast_vowel, A) and not req(past_vowel, I) then
							infer_err(("Form I hollow verb with nonpast vowel set to 'a' must have past vowel set to 'i', not %s"):
								format(undia[rget(past_vowel)]), "novform")
						end
						-- Ambiguous radical; could be wāw or yāʾ; if verb form I, it's critical to get this right, and
						-- the caller checks for this situation and throws an error if non-past vowel is "a" and second
						-- radical isn't explicitly given.
						rad2 = {W, Y, ambig = true, need_radical = true}
					end
				else
					infer_err("Second radical is alif but verb form doesn't support hollow verbs")
				end
			elseif vform == "I" and rad1 == W and not form_I_w_non_assimilated() then
				weakness = "assimilated"
			elseif rad2 == rad3 and (vform == "III" or vform == "VI") then
				weakness = "geminate"
				variant = "long"
			else
				weakness = "sound"
			end
		end
		if expected_length then
			check_len(expected_length, expected_length)
		end
	end

	rad1 = convert(rad1, 1)
	rad2 = convert(rad2, 2)
	rad3 = convert(rad3, 3)
	rad4 = convert(rad4, 4)

	if not weakness then
		error("Internal error: Returned weakness from infer_radicals() is nil")
	end
	return {
		weakness = weakness,
		rad1 = rad1,
		rad2 = rad2,
		rad3 = rad3,
		rad4 = rad4,
		past_vowel = past_vowel,
		nonpast_vowel = nonpast_vowel,
		form_viii_assim = form_viii_assim,
		variant = variant,
	}
end


-- bot interface to infer_radicals()
function export.infer_radicals_json(frame)
	local iparams = {
		headword = {},
		vform = {},
		passive = {},
		past_vowel = {},
		nonpast_vowel = {},
		is_reduced = {type = "boolean"},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	return require("Module:JSON").toJSON(export.infer_radicals(iargs))
end


-- Infer vocalization from participle headword (active or passive), verb form (I, II, etc.) and whether the headword is
-- active or passive. Throw an error if headword is malformed. Returned radicals may contain Latin letters "t", "w" or "y"
-- indicating ambiguous radicals guessed to be tāʾ, wāw or yāʾ respectively.
function export.infer_participle_vocalization(headword, vform, weakness, is_active)
	local chars = {}
	local orig_headword = headword
	-- Sub out alif-madda for easier processing.
	headword = rsub(headword, AMAD, HAMZA .. ALIF)

	local len = ulen(headword)

	-- Extract the headword letters into an array.
	for i = 1, len do
		table.insert(chars, usub(headword, i, i))
	end

	local function form_intro_error_msg()
		return ("For verb form %s %s%s participle %s, "):format(vform, orig_headword ~= headword and "normalized " or
			"", is_active and "active" or "passive", headword)
	end

	local function err(msg)
		error(form_intro_error_msg() .. msg, 1)
	end

	-- Check that length of headword is within [min, max].
	local function check_len(min, max)
		if min and len < min then
			err(("expected at least %s letters but saw %s"):format(min, len))
		elseif max and len > max then
			err(("expected at most %s letters but saw %s"):format(max, len))
		end
	end

	-- Get the character at `ind`, making sure it exists.
	local function c(ind)
		check_len(ind)
		return chars[ind]
	end

	-- Check that the letter at the given index is the given string, or is one of the members of the given array
	local function check(index, must)
		local letter = chars[index]
		local function make_possible_values()
			if type(must) == "string" then
				return must
			else
				return m_table.serialCommaJoin(must, {conj = "or", dontTag = true})
			end
		end
		if not letter then
			err(("expected a letter (specifically %s) at position %s, but participle is too short"):format(
				make_possible_values(), index))
		end
		local matches
		if type(must) == "string" then
			matches = letter == must
		else
			matches = m_table.contains(must, letter)
		end
		if not matches then
			err(("letter %s at index %s must be %s"):format(letter, index, make_possible_values()))
		end
	end

	local function check_weakness(values, allow_missing, invert_condition)
		local function make_possible_weaknesses()
			for i, val in ipairs(values) do
				values[i] = "'" .. val .. "'"
			end
			return m_table.serialCommaJoin(values, {conj = "or", dontTag = true})
		end
		if allow_missing and invert_condition then
			error("Internal error: Can't specify both allow_missing and invert_condition")
		end
		if not weakness then
			if allow_missing or invert_condition then
				return
			else
				err(("weakness is unspecified but must be %s"):format(make_possible_weaknesses()))
			end
		else
			local matches = m_table.contains(values, weakness)
			if invert_condition and matches then
				err(("weakness '%s' must not be %s"):format(weakness, make_possible_weaknesses()))
			elseif not invert_condition and not matches then
				err(("weakness '%s' must be %s"):format(weakness, make_possible_weaknesses()))
			end
		end
	end

	local vocalized

	local function handle_possibly_final_weak(sound_prefix, expected_length)
		check_len(expected_length, expected_length)
		if c(expected_length) == AMAQ then
			-- passive final-weak
			if is_active then
				err("participle in -ِى only allowed for passive participles")
			end
			check_weakness({"final-weak", "assimilated+final-weak"}, "allow missing")
			vocalized = sound_prefix .. AN .. AMAQ
		else
			-- all others behave as if sound
			check_weakness({"final-weak", "assimilated+final-weak"}, nil, "invert condition")
			vocalized = sound_prefix .. (is_active and I or A) .. c(expected_length)
		end
	end

	if not (vform == "I" and is_active) then
		-- all participles except verb form I active begin in م-.
		check(1, M)
	end
	if vform == "I" then
		if is_active then
			check(2, ALIF)
			local sound_prefix = c(1) .. AA .. c(3)
			if len == 3 then
				if c(3) == HAMZA then
					-- Either hollow with hamzated third radical, e.g. [[شاء]] active participle 'شَاءٍ', or final-weak
					-- with hamzated second radical, e.g. [[رأى]] active participle 'رَاءٍ'. Theoretically (?), also
					-- geminate with hamzated second/third radical, but I don't know if any such verbs exist.
					if weakness == "geminate" then
						vocalized = sound_prefix .. SH
					else
						check_weakness({"hollow", "final-weak"}, "allow missing")
						vocalized = sound_prefix .. IN
					end
				else
					check_weakness({"final-weak", "geminate"})
					if weakness == "geminate" then
						vocalized = sound_prefix .. SH
					else
						vocalized = sound_prefix .. IN
					end
				end
			else
				check_len(4, 4)
				-- we will convert back to alif maqṣūra below as needed
				vocalized = sound_prefix .. I .. c(4)
			end
		else
			-- assimilated verbs: regular, e.g. مَوْزُون "weighed"
			-- geminate verbs: regular, e.g. مَبْلُول "moistened"
			-- third-hamzated verbs: مَبْرُوء
			-- hollow verbs: مَقُود "led, driven"; مَزِيد "added, increased"
			-- hollow first-hamzated verbs: مَئِيض "returned, reverted"; مَأْيُوس "despaired" (NOTE: formation is sound);
			--   مَأُود or مَؤُود "bent; depleted"
			-- hollow third-hamzated verbs: مَشِيء "willed, intended", مَضُوء "glittered?"
			-- final-weak: مَلْقِيّ "found, encountered"; مَصْغُوّ "inclined"
			-- hollow + final-weak: مَشْوِيّ "fried, grilled", مَهْوِيّ "loved"
			-- first-hamzated + hollow + final-weak: مَأْوِيّ "received hospitably"
			local sound_prefix = MA .. c(2) .. SK .. c(3)
			if len == 5 then
				-- sound, assimilated or geminate
				check(4, W)
				vocalized = sound_prefix .. UU .. c(5)
			else
				check_len(4, 4)
				if c(4) == W then
					-- final-weak third-wāw
					vocalized = sound_prefix .. U .. W .. SH
				elseif c(4) == Y then
					-- final-weak third-yāʾ
					vocalized = sound_prefix .. I .. Y .. SH
				else
					-- hollow
					check(3, {W, Y})
					if c(3) == W then
						vocalized = MA .. c(2) .. UU .. c(4)
					else
						vocalized = MA .. c(2) .. II .. c(4)
					end
				end
			end
		end
	elseif vform == "II" or vform == "V" or vform == "XII" or vform == "XIII" or vform == "Iq" or vform == "IIq" or
		vform == "IIIq" then
		local sound_prefix, expected_length
		if vform == "II" then
			sound_prefix = MU .. c(2) .. A .. c(3) .. SH
			expected_length = 4
		elseif vform == "V" then
			check(2, T)
			sound_prefix = MU .. T .. A .. c(3) .. A .. c(4) .. SH
			expected_length = 5
		elseif vform == "XII" then
			-- e.g. [[احدودب]] "to be or become convex or humpbacked", مُحْدَوْدِب (active);
			-- [[اثنونى]] "to be bent; to be doubled up", مُثْنَوْنٍ (active)
			check(4, W)
			if c(3) ~= c(5) then
				err(("third letter %s should be the same as the fifth letter %s"):format(c(3), c(5)))
			end
			sound_prefix = MU .. c(2) .. SK .. c(3) .. A .. W .. SK .. c(5)
			expected_length = 6
		elseif vform == "XIII" then
			-- e.g. [[اخروط]] "to get entangled; to extend", مُخْرَوِّط (active), مُخْرَوَّط (passive)
			check(4, W)
			sound_prefix = MU .. c(2) .. SK .. c(3) .. A .. W .. SH
			expected_length = 5
		elseif vform == "Iq" then
			sound_prefix = MU .. c(2) .. A .. c(3) .. SK .. c(4)
			expected_length = 5
		elseif vform == "IIq" then
			check(2, T)
			sound_prefix = MU .. T .. A .. c(3) .. A .. c(4) .. SK .. c(5)
			expected_length = 6
		elseif vform == "IIIq" then
			-- e.g. [[اخرنطم]] "to be proud and angry"
			check(4, T)
			sound_prefix = MU .. c(2) .. SK .. c(3) .. A .. N .. SK .. c(5)
			expected_length = 6
		else
			error("Internal error: Unhandled verb form " .. vform)
		end
		if len == expected_length - 1 then
			-- active final-weak
			if not is_active then
				err(("length-%s participle only allowed for active participles"):format(len))
			end
			check_weakness({"final-weak", "assimilated+final-weak"}, "allow missing")
			vocalized = sound_prefix .. IN
		else
			handle_possibly_final_weak(sound_prefix, expected_length)
		end
	elseif vform == "III" or vform == "VI" then
		local sound_prefix, expected_length
		if vform == "VI" then
			check(2, T)
			check(4, ALIF)
			sound_prefix = MU .. T .. A .. c(3) .. AA .. c(5)
			expected_length = 6
		else
			sound_prefix = MU .. c(2) .. AA .. c(4)
			expected_length = 5
		end
		if len == expected_length - 1 then
			-- active final-weak or active or passive geminate
			if is_active then
				check_weakness({"geminate", "final-weak", "assimilated+final-weak"})
				if weakness == "geminate" then
					vocalized = sound_prefix .. SH
				else
					vocalized = sound_prefix .. IN
				end
			else
				check_weakness({"geminate"}, "allow missing")
				vocalized = sound_prefix .. SH
			end
		else
			handle_possibly_final_weak(sound_prefix, expected_length)
		end
	elseif vform == "IV" or vform == "X" then
		-- form IV:
		-- sound: مُرْسِخ (active, "entrenching"), مُرْسَخ (passive, "entrenched")
		-- first-hamzated (like sound): مُؤْيِس (active, "causing to despair"), مُؤْيَس (passive, "caused to despair")
		-- final-weak: مُكْرٍ (active, "renting out"), مُكْرًى (passive, "rented out")
		-- assimilated: مُورِد (active, "transferring"), مُورَد (passive, "transferred"); same when first-Y, e.g.
		--   أَيْقَنَ "to be certain of": مُوقِن (active), مُوقَن (passive)
		-- assimilated + final-weak: مُورٍ (active, "setting fire, kindling"), مُورًى (passive, "set fire, kindled")
		-- geminate: مُمِدّ (active, "granting, helping"), مُمَدّ (passive, "granted, helped")
		-- hollow: مُزِيل (active, "eliminating"), مُزَال (passive, "eliminated")
		-- hollow + final-weak: مُعْيٍ (active, "tiring"), مُعْيًى (passive, "tired")
		local sound_prefix, expected_length
		if vform == "X" then
			check(2, S)
			check(3, T)
			sound_prefix = MU .. S .. SK .. T .. A .. c(4)
			expected_length = 6
		else
			sound_prefix = MU .. c(2)
			expected_length = 4
		end

		if len == expected_length and c(len - 1) == Y and c(len) ~= AMAQ then
			-- active hollow
			if not is_active then
				err("this shape only allowed for active participles")
			end
			check_weakness({"hollow"}, "allow missing")
			vocalized = sound_prefix .. II .. c(len)
		elseif len == expected_length and c(len - 1) == ALIF then
			-- passive hollow
			if is_active then
				err("this shape only allowed for passive participles")
			end
			check_weakness({"hollow"}, "allow missing")
			vocalized = sound_prefix .. AA .. c(len)
		elseif len == expected_length - 1 then
			-- active final-weak or active or passive geminate
			if is_active then
				check_weakness({"geminate", "final-weak", "assimilated+final-weak"})
				if weakness == "geminate" then
					vocalized = sound_prefix .. I .. c(len) .. SH
				elseif vform == "IV" and c(2) == W then
					-- assimilated final-weak
					vocalized = sound_prefix .. c(len) .. IN
				else
					vocalized = sound_prefix .. SK .. c(len) .. IN
				end
			else
				check_weakness({"geminate"}, "allow missing")
				vocalized = sound_prefix .. A .. c(len) .. SH
			end
		else
			if vform == "IV" and c(2) == W then
				-- assimilated, possibly final-weak
				sound_prefix = sound_prefix .. c(expected_length - 1)
			else
				sound_prefix = sound_prefix .. SK .. c(expected_length - 1)
			end
			handle_possibly_final_weak(sound_prefix, expected_length)
		end
	elseif vform == "VII" or vform == "VIII" then
		-- form VII (passive participles are fairly rare but do exist):
		-- sound: مُنْكَتِب (active "subscribing"), مُنْكَتَب (passive "subscribed")
		-- geminate: مُنْضَمّ (both active "joining, containing" and passive "joined, contained")
		-- final-weak: مُنْطَلٍ (active "fooling (someone)"), مُنْطَلًى (passive "fooled")
		-- final-weak with medial wāw: مُنْطَوٍ (active "involving"), مُنْطَوًى (passive "involved")
		-- hollow: مُنْقَاد (both active "complying with" and passive "complied with")
		--
		-- for form VIII, the same variants exist but things are complicated by assimilations involving the template T.
		-- sound third-hamzated no assimilation: مُبْتَدِئ (active "beginning"), مُبْتَدَأ (passive "begun")
		-- geminate no assimilation: مُبْتَزّ (both active "robbing" and passive "robbed")
		-- final-weak no assimilation: مُبْتَنٍ (active "building"), مُبْتَنًى (passive "built")
		-- final-weak with medial wāw no assimilation: مُحْتَوٍ (active "containing"), مُحْتَوًى (passive "contained")
		-- hollow no assimilation: مُخْتَار (both active "choosing" and passive "chosen")
		--
		-- sound with total assimilation: مُتَّبِع (active "following"), مُتَّبَع (passive "followed")
		-- sound with total assimilation, assimilating wāw: مُتَّعِد (active "threatening"), مُتَّعَد (passive "threatened")
		-- sound with total assimilation, irregularly assimilating hamza: مُتَّخِذ (active "taking"), مُتَّخَذ (passive "taken")
		-- sound with total assimilation (to ḏāl, producing dāl): مُدَّخِر (active "reserving"), مُدَّخَر (passive "reserved")
		-- sound with total assimilation (to ḏāl): مُذَّكِر (active "remembering"), مُذَّكَر (passive "remembered")
		-- sound with total assimilation (to ṭāʔ): مُطَّرِح (active "discarding"), مُطَّرَح (passive "discarded")
		-- sound with total assimilation (to ẓāʔ): مُظَّلِم (active "tolerating"), مُظَّلَم (passive "tolerated")
		-- final-weak with total assimilation, assimilating wāw: مُتَّقٍ (active "guarding against"), مُتَّقًى (passive "guarded against")
		-- final-weak with total assimilation (to ṯāʔ): مُثَّنٍ (active "undulating"), مُثَّنًى (passive "undulated")
		-- final-weak with total assimilation (to dāl): مُدَّعٍ (active "claiming"), مُدَّعًى (passive "claimed")
		-- sound with partial assimilation (to zayn): مُزْدَهِر (active "thriving"), مُزْدَهَر (passive "thrived")
		-- sound with medial wāw with partial assimilation (to zayn): مُزْدَوِج (active "appearing twice")
		-- sound with partial assimilation (to ṣād): مُصْطَبِح (active "illuminating"), مُصْطَبَح (passive, "illuminated")
		-- sound with partial assimilation (to ḍād): مُضْطَرِب (active "to be disturbed"; no passive)
		-- geminate with partial assimilation (to ṣād): مُصْطَبّ (both active "effusing" and passive "effused")
		-- geminate with partial assimilation (to ḍād): مُضْطَرّ (both active "forcing" and passive "forced")
		-- final-weak with partial assimilation (to ṣād): مُصْطَلٍ (active "warming"), مُصْطَلًى (passive "warmed")
		-- hollow with partial assimilation (to zayn): مُزْدَاد (both active "increasing" and passive "increased")
		-- hollow with partial assimilation (to ṣad): مُصْطَاد (both active "hunting" and passive "hunted")
		local sound_prefix, sufind
		if vform == "VII" then
			check(2, N)
			sound_prefix = MU .. N .. SK .. c(3)
			sufind = 4
		else
			local c2 = c(2)
			if c2 == T or c2 == "د" or c2 == "ث" or c2 == "ذ" or c2 == "ط" or c2 == "ظ" then
				-- full assimilation
				sound_prefix = MU .. c2 .. SH
				sufind = 3
			else
				-- partial or no assimilation
				if c2 == "ز" then
					check(3, "د")
				elseif c2 == "ص" or c2 == "ض"  then
					check(3, "ط")
				else
					check(3, T)
				end
				sound_prefix = MU .. c2 .. SK .. c(3)
				sufind = 4
			end
		end
		if c(sufind) == ALIF then
			-- hollow, active or passive
			check_len(sufind + 1, sufind + 1)
			check_weakness({"hollow"}, "allow missing")
			vocalized = sound_prefix .. AA .. c(sufind + 1)
		elseif len == sufind then
			-- active final-weak or active or passive geminate
			if is_active then
				check_weakness({"geminate", "final-weak", "assimilated+final-weak"})
				if weakness == "geminate" then
					vocalized = sound_prefix .. A .. c(len) .. SH
				else
					vocalized = sound_prefix .. A .. c(len) .. IN
				end
			else
				check_weakness({"geminate"}, "allow missing")
				vocalized = sound_prefix .. A .. c(len) .. SH
			end
		else
			sound_prefix = sound_prefix .. A .. c(sufind)
			handle_possibly_final_weak(sound_prefix, sufind + 1)
		end
	elseif vform == "IX" then
		check_len(4, 4)
		vocalized = MU .. c(2) .. SK .. c(3) .. A .. c(4) .. SH
	elseif vform == "IVq" then
		-- e.g. [[اذلعب]] "to scamper away", مُذْلَعِبّ (active), مُذْلَعَبّ (passive);
		-- [[اطمأن]] "to remain quietly; to be certain", مُطْمَئِنّ (active), مُطْمَأَنّ (passive)
		check_len(5, 5)
		local sound_prefix = MU .. c(2) .. SK .. c(3) .. A .. c(4)
		if is_active then
			vocalized = sound_prefix .. I .. c(5) .. SH
		else
			vocalized = sound_prefix .. A .. c(5) .. SH
		end
	elseif vform == "XI" then
		check_len(5, 5)
		check(4, ALIF)
		vocalized = MU .. c(2) .. SK .. c(3) .. AA .. c(5) .. SH
		-- e.g. [[احمار]] "to turn red, to blush", مُحْمَارّ (active)
	elseif vform == "XIV" or vform == "XV" then
		-- FIXME: Implement. No examples in Wiktionary currently; need to look up in a grammar.
		error("Support for verb form " .. vform .. " not implemented yet")
	else
		error("Don't recognize verb form " .. vform)
	end

	vocalized = rsub(vocalized, HAMZA .. AA, AMAD)

	local reconstructed_headword = lang:makeEntryName(vocalized)
	if reconstructed_headword ~= orig_headword then
		error(("Internal error: Vocalized participle %s doesn't match original participle %s"):format(
			vocalized, orig_headword))
	end
	
	return vocalized
end

function export.infer_participle_vocalization_json(frame)
	local iparams = {
		[1] = {required = true},
		[2] = {required = true},
		["weakness"] = {},
		["passive"] = {type = "boolean"}
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	return export.infer_participle_vocalization(iargs[1], iargs[2], iargs.weakness, not iargs.passive)
end

return export
