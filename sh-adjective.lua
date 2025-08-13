local export = {}


--[=[

Authorship: Ben Wing <benwing2>

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of case/gender/number. Example slot names for adjectives are "indef_gen_f"
	(indefinite genitive feminine singular) and "comp_m_acc_an" (animate accusative masculine singular comparative
	degree). Each slot is filled with zero or more forms.

-- "form" = The declined Serbo-Croatian form representing the value of a given slot.

-- "lemma" = The dictionary form of a given Serbo-Croatian term. Generally the nominative
	masculine singular, but may occasionally be another form if the nominative
	masculine singular is missing.
]=]

local lang = require("Module:languages").getByCode("sh")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local en_utilities_module = "Module:en-utilities"
local iut = require("Module:User:Benwing2/inflection utilities")
local put = require("Module:parse utilities")
local com = require("Module:User:Benwing2/sh-common")
local AC = com.AC
local GR = com.GR
local DOUBLEGR = com.DOUBLEGR
local INVBREVE = com.INVBREVE
local MACRON = com.MACRON

local u = m_string_utilities.char
local rsplit = m_string_utilities.split
local rfind = m_string_utilities.find
local rmatch = m_string_utilities.match
local rgmatch = m_string_utilities.gmatch
local rsubn = m_string_utilities.gsub
local ulen = m_string_utilities.len
local uupper = m_string_utilities.upper

local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local dump = mw.dumpObject
local format = string.format


local force_cat = false -- set to true to make categories appear in non-mainspace pages, for testing

local SUB_ESCAPED_PERIOD = u(0xFFF0)
local SUB_ESCAPED_COMMA = u(0xFFF1)


-- version of rsubn() that discards all but the first return value
local rsub = com.rsub
local usererr = com.usererr
local interr = com.interr


local function track(track_id)
	require("Module:debug/track")("sh-adjective/" .. track_id)
	return true
end


local function make_quoted_list(list)
	local quoted_list = {}
	for _, item in ipairs(list) do
		table.insert(quoted_list, "'" .. item .. "'")
	end
	return mw.text.listToText(quoted_list)
end


local function make_quoted_keys(dict)
	local quoted_list = {}
	for key, _ in pairs(dict) do
		table.insert(quoted_list, "'" .. key .. "'")
	end
	table.sort(quoted_list)
	return mw.text.listToText(quoted_list)
end


local function make_quoted_slot_list(slot_list)
	local quoted_list = {}
	for _, slot_accel in ipairs(slot_list) do
		local slot, accel = unpack(slot_accel)
		table.insert(quoted_list, "'" .. slot .. "'")
	end
	return mw.text.listToText(quoted_list)
end


local potential_lemma_slots = {
	"indef_nom_m",
	"indef_nom_f", -- for feminine-only adjectives
	"indef_nom_mp", -- for plural-only numerals and such
	"def_nom_m", -- for definite-only adjectives
	"def_nom_f", -- for definite-only feminine-only adjectives
	"comp_nom_m", -- for adjectives existing only in comparative and superlative forms
}

local compsup_degrees = {
	{"pos", "Positive"},
	{"comp", "Comparative"},
	{"sup", "Superlative"},
}

-- Export some of these below for use by [[Module:sh-noun]].

export.overridable_stems = {
	"indefstem",
	"defstem",
}

export.overridable_stem_set = m_table.listToSet(export.overridable_stems)

export.control_specs = {
	"*",
	"2tone",
}

export.control_spec_set = m_table.listToSet(export.control_specs)

export.boolean_property_set = m_table.listToSet {
	-- The properties are already decomposed when we check against them.
	"builtin", "def_va" .. GR .. "r", "indef_va" .. INVBREVE .. "r", "indecl", "decl?", "pred",
}

local function slot_to_degfield(slot)
	local degfield = slot:match("^(comp)_")
	if not degfield then
		degfield = slot:match("^(sup)_")
	end
	return degfield or "pos"
end


-- Abbreviations for use in addnote specs and overrides. Key is the abbreviation, value is a Lua pattern matching the
-- slots to select, or a list of such patterns. Patterns are anchored at both ends.
local adjective_slot_abbrs = {
	indef = "indef_.*",
	indef_m = {"indef_.*_m", "indef_.*_m_[ai]n"},
	indef_f = "indef_.*_f",
	indef_n = "indef_.*_n",
	indef_s = {"indef_.*_[mfn]", "indef_.*_m_[ai]n"},
	indef_p = "indef_.*p",
	def = "def_.*",
	def_m = {"def_.*_m", "def_.*_m_[ai]n"},
	def_f = "def_.*_f",
	def_n = "def_.*_n",
	def_s = {"def_.*_[mfn]", "def_.*_m_[ai]n"},
	def_p = "def_.*p",
	comp_m = {"comp_.*_m", "comp_.*_m_[ai]n"},
	comp_f = "comp_.*_f",
	comp_n = "comp_.*_n",
	comp_s = {"comp_.*_[mfn]", "comp_.*_m_[ai]n"},
	comp_p = "comp_.*p",
	sup_m = {"sup_.*_m", "sup_.*_m_[ai]n"},
	sup_f = "sup_.*_f",
	sup_n = "sup_.*_n",
	sup_s = {"sup_.*_[mfn]", "sup_.*_m_[ai]n"},
	sup_p = "sup_.*p",
}

local input_adjective_slots = {
	{"nom_m", "nom|m|s"},
	{"nom_f", "nom|f|s"},
	{"nom_n", "nom|n|s"},
	{"nom_mp", "nom|m|p"},
	{"nom_fp", "nom|f|p"},
	{"nom_np", "nom|n|p"},
	{"gen_m", "gen|m|s"},
	{"gen_f", "gen|f|s"},
	{"gen_n", "gen|n|s"},
	{"gen_p", "gen|p"},
	{"dat_m", "dat|m|s"},
	{"dat_f", "dat|f|s"},
	{"dat_n", "dat|n|s"},
	{"dat_p", "dat|p"},
	{"acc_m_an", "an|acc|m|s"},
	{"acc_m_in", "in|acc|m|s"},
	{"acc_f", "acc|f|s"},
	{"acc_n", "acc|n|s"},
	{"acc_mp", "acc|m|p"},
	{"acc_fp", "acc|f|p"},
	{"acc_np", "acc|n|p"},
	{"voc_m", "voc|m|s"},
	{"voc_f", "voc|f|s"},
	{"voc_n", "voc|n|s"},
	{"voc_mp", "voc|m|p"},
	{"voc_fp", "voc|f|p"},
	{"voc_np", "voc|n|p"},
	{"ins_m", "ins|m|s"},
	{"ins_f", "ins|f|s"},
	{"ins_n", "ins|n|s"},
	{"ins_p", "ins|p"},
	{"loc_m", "loc|m|s"},
	{"loc_f", "loc|f|s"},
	{"loc_n", "loc|n|s"},
	{"loc_p", "loc|p"},
}

local adjective_slot_set = {}
local adjective_slot_list = {}

local adjective_slot_list_by_degree = {}
local adjective_slot_list_linked_slots = {}

local function add_list_slots(degfield, prefix)
	-- Initialize by-degree list, but don't overwrite.
	adjective_slot_list_by_degree[degfield] = adjective_slot_list_by_degree[degfield] or {}
	for _, slot_accel in ipairs(input_adjective_slots) do
		local slot, accel = unpack(slot_accel)
		local accel_suffix = ""
		if prefix == "comp" then
			accel = accel .. "|comd"
		elseif prefix == "sup" then
			accel = accel .. "|supd"
		else
			accel = prefix .. "|" .. accel
		end
		slot = prefix .. "_" .. slot
		slot_accel = {slot, accel}
		table.insert(adjective_slot_list, slot_accel)
		table.insert(adjective_slot_list_by_degree[degfield], slot_accel)
		adjective_slot_set[slot] = true
	end
end

local function add_slots(degfield, prefixes)
	for _, prefix in ipairs(prefixes) do
		add_list_slots(degfield, prefix)
	end
end
add_slots("pos", {"indef", "def"})
add_slots("comp", {"comp"})
add_slots("sup", {"sup"})
for _, potential_lemma_slot in ipairs(potential_lemma_slots) do
	local slot_accel = {potential_lemma_slot .. "_linked", "-"}
	table.insert(adjective_slot_list, slot_accel)
	table.insert(adjective_slot_list_linked_slots, slot_accel)
end


-- Get the appropriate slot list for the given degree, removing the definiteness and/or number from the
-- accelerator form if the definiteness or number are restricted to a single value.
local function get_slot_list(alternant_multiword_spec, degfield)
	local source_list = adjective_slot_list_by_degree[degfield]
	local number = alternant_multiword_spec.number[degfield]
	local definiteness = alternant_multiword_spec.definiteness[degfield]
	if number == "both" and definiteness == "bothdefs" then
		return source_list
	end
	local dest_list = {}
	for _, slot_accel in ipairs(source_list) do
		local slot, accel = unpack(slot_accel)
		if definiteness ~= "bothdefs" and alternant_multiword_spec.pos ~= "adjective" then
			accel = accel:gsub("^indef|", ""):gsub("^def|", "")
		end
		if number ~= "both" then
			accel = accel:gsub("|s$", ""):gsub("|p$", "")
		end
		table.insert(dest_list, {slot, accel})
	end
	return dest_list
end


local function skip_slot(number, definiteness, slot)
	return number == "sg" and slot:find("p$") or
		number == "pl" and not slot:find("p$") or
		definiteness == "indef" and slot:find("^def_") or
		definiteness == "def" and slot:find("^indef_")
end

-- FIXME: Rewrite this comment for Serbo-Croatian.
--[=[
Create an empty `base` object for holding the result of parsing and later the generated forms. The object (including
fields later filled out by other functions) is of the form

{
  -- The original lemma as specified by the user in the declension spec, or taken from the pagename. May have
  -- double-bracket links in it.
  orig_lemma = "ORIGINAL_LEMMA",
  -- Same as `orig_lemma` but with double-bracket links removed and two-part links resolved to the right side.
  orig_lemma_no_links = "ORIGINAL_LEMMA_NO_LINKS",
  -- Per-degree structures (`pos` = positive, `comp` = comparative, `sup` = superlative). Each slot (`pos`, `comp` or
  -- `sup`) maps to a list of degree objects, one for each per-degree lemma. There will only be one positive degree
  -- object (different positive lemmas will be handled as alternants at a higher level), but there may be multiple
  -- comparative and/or superlative degree objects. (Conversely, there may be multiple property sets per positive-degree
  -- object, e.g. if the user specifies 'con,-con', but only one property set per comparative and superlative degree
  -- object.) Multiple degree objects generally happen because the user specifies multiple comparatives or superlatives
  -- (e.g. for [[fagur]], using the spec '#.comp:^ri:^!i.sup:^stur', which specifies comparative lemmas [[fegurri]] and
  -- [[fagri]] and superlative [[fegurstur]]), but occasionally the default superlative operation generates more than
  -- one superlative; e.g. for [[förull]] the spec is 'con,-con.comp:+:~~ari' which explicitly mentions two
  -- comparatives, and '+' itself generates two superlatives because of the 'con,-con' portion of the spec. There will
  -- always be a `pos` slot filled, but if the user didn't explicitly either specify that a comparative is present or
  -- specify no comparative using '-comp', there will be no `comp` slot (likewise for `sup`). If the user specified
  -- '-comp', there will be a `comp` slot mapping to an empty list.
  degrees = {
    pos = {
	  {
		-- The actual lemma, without any links. For the positive degree, same as `base.orig_lemma_no_links`. For the
		-- comparative and superlative degrees, as specified by the user or defaulted.
		actual_lemma = "ACTUAL_LEMMA",
		-- The lemma to use for declension. Will differ from `actual_lemma` if `decllemma:...` is given, in which case
		-- the value of `decllemma` will be here.
		lemma = "LEMMA",
		number = "NUMBER", -- "sg", "pl" or "both"; may be missing and if so is defaulted
		definiteness = "DEFINITENESS", -- "strong", "weak" or "bothdefs"; may be missing and if so is defaulted
		-- computed stem; after parse_indicator_spec(), either nil or a user-specified stem override, which may have
		-- # (= lemma) or ## (= lemma minus -ur or -r) as the value; after determine_positive_declension(), filled in
		-- with the actual stem
		stem = "STEM",
		-- override the stem used before vowel-initial endings; after parse_indicator_spec(), either nil or a
		-- user-specified stem override in the same format as `stem`
		vstem = nil or "STEM",
		-- degree-level footnotes, specified using `LEMMA[footnote]`, where `LEMMA` is the comparative or superlative
		-- lemma, + for the default, or a shortened version using ~, ^ or the like
		footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...},
		-- CONTROL_GROUP is one of "*" or 2tone, and CONTROL_SPEC is {form = "FORM", footnotes = nil or {"FOOTNOTE",
		-- "FOOTNOTE", ...}, defaulted = BOOLEAN}, where FORM is as specified by the
		-- user (e.g. "uUmut", "-pp") or set as a default by the code (in which case `defaulted` will be set to true for
		-- control group "umut"); the control groups are as follows:
		-- * umut (u-mutation);
		-- * con (stem contraction before vowel-initial endings);
		-- * j (j-infix before vowel-initial endings not beginning with an i);
		-- * v (v-infix before vowel-initial endings);
		-- * pp (past-participle-like inflection, with -ð in the nominative/accusative neuter singular instead of -t);
		-- * ppdent (dental infix in past participles before vowel-initial endings);
		CONTROL_GROUP = {
		  CONTROL_SPEC, CONTROL_SPEC, ...
		},
		prop_sets = {
		  PROPSET, -- see below
		  ...,
		},
	  },
	  ...
	},
	comp = { { ... }, { ... }, ... },
	sup = { { ... }, { ... }, ... },
  },
  -- forms for a single spec alternant
  forms = {
	SLOT = {
	  {
		form = "FORM",
		footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...},
	  },
	  ...
	},
	...
  },
  -- SLOT is the actual name of the slot, such as "str_nom_n", and OVERRIDE is a list of form objects, where a
  -- form object is {form = FORM, footnotes = FOOTNOTES} as in the `forms` table ("-" means to suppress the slot
  -- entirely)
  overrides = {
	SLOT = OVERRIDE,
	SLOT = OVERRIDE,
	...
  },
  -- Used to track duplicate slot overrides.
  override_slots_seen = {
	SLOT = true,
	SLOT = true,
	...
  },
  -- Positive specs as given by the user, currently only if the user specifies '-pos'.
  posspec = nil or { {form = "-"} },
  -- Comparative specs as given by the user, consisting of a list of form objects.
  compspec = nil or { {form = "FORM", footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...}}, ...},
  -- misc Boolean properties:
  -- * "builtin" (a built-in term such as a number or determiner);
  -- * "decl?" (unknown declension);
  -- * "indecl" (indeclinable);
  -- * "pred" (predicate-only);
  props = {
	PROP = true,
	PROP = true,
    ...
  },
  decllemma = nil or "DECLLEMMA", -- decline like the specified lemma
  -- alternant-level footnotes, specified using `.[footnote]`, i.e. a footnote by itself; apply to all degrees
  footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...},
  -- ADDNOTE_SPEC is {slot_specs = {"SPEC", "SPEC", ...}, footnotes = {"FOOTNOTE", "FOOTNOTE", ...}}; SPEC is a Lua
  -- pattern matching slots (anchored on both sides) and FOOTNOTE is a footnote to add to those slots
  addnote_specs = {
	ADDNOTE_SPEC, ADDNOTE_SPEC, ...
  },
}

There is one PROPSET (property set) for each combination of control specs; in the lower limit, there is a single
property set. There may be more than one property set e.g. if the user specified 'umut,uUmut' or '-j,j' or some
combination of these. The properties in a given property set specify the values themselves of each control group, as
well as stems (derived from the control specs) that are used to construct the various forms and populate the slots in
`forms` with these values. The information found in the property sets cannot be stored in `base` because it depends on a
particular combination of control specs, of which there may be more than one (see above). The decline_adjective()
function iterates over all property sets and calls the appropriate declension function on each one in turn, which adds
forms to each slot in `base.forms`, automatically deduplicating.

The properties in each property set are:
* Mutation specs: These are copied from the control specs at the degree object level. The key is one of the possible
  control groups ("umut", "con", etc.), but the value is a single form object {form = "FORM", footnotes = nil or
  {"FOOTNOTE", "FOOTNOTE", ...}}. These are set by expand_property_sets() for the positive degree, and by
  process_comp_spec() or derive_sup_from_comp() for the comparative and superlative degrees.
* Stems (each stem is either a string or a form object; stems in general may be missing, i.e. nil, unless otherwise
  specified, and default to more general variants):
** `stem`: The basic stem. Always set. May be overridden by more specific variants.
** `nonvstem`: The stem used when the ending is null or starts with a consonant, unless overridden by a more
   specific variant. Defaults to `stem`. Not currently used, but could be if e.g. a user stem override `nonvstem:...`
   were supported.
** `umut_nonvstem`: The stem used when the ending is null or starts with a consonant and u-mutation is in effect,
   unless overridden by a more specific variant. Defaults to `nonvstem`. Will only be present when the result of
   u-mutation is different from the stem to which u-mutation is applied. (In this case, it will be present even if
   `nonvstem` is missing, because there is no generic `umut_stem`.)
** `vstem`: The stem used when the ending starts with a vowel, unless overridden by a more specific variant. Defaults
   to `stem`. Will be specified when contraction is in effect or the user specified `vstem:...`.
** `umut_vstem`: The stem(s) used when the ending starts with a vowel and u-mutation is in effect. Defaults to
   `vstem`. Note that u-mutation applies to the contracted stem if both u-mutation and contraction are in effect.
   Will only be present when the result of u-mutation is different from the stem to which u-mutation is applied.
   (In this case, it will be present even if `vstem` is missing, because there is no generic `umut_stem`.)
* Other properties:
** `jinfix`: If present, either "" or "j". Inserted between the stem and ending when the ending begins with a vowel
   other than "i". Note that j-infixes don't apply to ending overrides.
** `jinfix_footnotes`: Footnotes to attach to forms where j-infixing is possible (even if it's not present).
** `vinfix`: If present, either "" or "v". Inserted between the stem and ending when the ending begins with a vowel.
   Note that v-infixes don't apply to ending overrides. `jinfix` and `vinfix` cannot both be specified.
** `vinfix_footnotes`: Footnotes to attach to forms where v-infixing is possible (even if it's not present).
** `pp`: If present, either `true` or `false`. Indicates how to assimilate neuter ending -t to a previous final -ð
   after a vowel. If true, the result is -ð, as in past participles; otherwise, the result is -tt.
** `pp_footnotes`: Footnotes to attach to forms where `pp`-influenced assimilation happens.
}
]=]
local function create_base()
	return {
		forms = {},
		overrides = {},
		override_slots_seen = {},
		props = {},
		addnote_specs = {},
		degrees = {},
	}
end


local function combine_stem_ending(stem, ending)
	if stem == "?" then
		return "?"
	else
		return stem .. ending
	end
end


-- Basic function to combine stem(s) and other properties with ending(s) and insert the result into the appropriate
-- slot. `base` is the object describing all the properties of the word being inflected for a single alternant (in case
-- there are multiple alternants specified using `((...))`). `slot` is the slot to add the form(s) to, without the
-- degree prefix ("", "comp_" or "sup_"). (The degree prefix is separated out because the code below sometimes needs to
-- conditionalize on the value of `slot` and should not have to worry about the degree variants.) `degree` is an object
-- describing the particular degree (positive, comparative or superlative) and associated base lemma. `props` is an
-- object containing computed stems and other information (FIXME, what?). The information found in `props` cannot be
-- stored in `degree` because there may be more than one set of such properties per `degree` (e.g. FIXME what?; in such
-- a case, the caller will iterate over all possible combinations, and ultimately invoke add() multiple times, one per
-- combination). `endings` is the ending or endings added to the appropriate stem to get the form(s) to add to the slot.
-- Its value can be a single string, a list of strings, or a list of form objects (i.e. in general list form).
local function add(base, slot, degree, props, endings)
	if not endings then
		return
	end
	-- Call skip_slot() based on the declined number and definiteness.
	if skip_slot(degree.number, degree.definiteness, slot) then
		return
	end
	if type(endings) == "string" then
		endings = {endings}
	end
	local slot_prefix = degree.slot_prefix
	-- Loop over each ending.
	for _, endingobj in ipairs(endings) do
		local ending, ending_footnotes
		if type(endingobj) == "string" then
			ending = endingobj
		else
			ending = endingobj.form
			ending_footnotes = endingobj.footnotes
		end
		-- Ending of "-" means the user used - to indicate there should be no form here.
		if ending == "-" then
			return
		end
		local function interr_add(msg)
			interr("For lemma %s, slot %s, ending %s, %s: %s", degree.lemma, slot_prefix .. slot, ending, msg, base)
		end

		-- Now compute the appropriate stem to which the ending is added.
		local stem_in_effect

		if slot:find("^def_") then
			stem_in_effect = props.def_stem
		elseif slot == "indef_nom_m" or slot == "indef_acc_m_in" then
			stem_in_effect = props.lemma_stem
		elseif slot == "indef_nom_n" or slot == "indef_acc_n" then
			stem_in_effect = props.neut_stem
		else
			stem_in_effect = props.indef_stem
		end

		-- If base-level footnotes or degree-level footnotes specified, they go before any stem footnotes, so we
		-- need to extract any footnotes from the stem in effect and insert the base-level footnotes before. In
		-- general, we want the footnotes to be in the order [base.footnotes, degree.footnotes, stem.footnotes,
		-- mut_footnotes, infix_footnotes, ending.footnotes].
		if base.footnotes or degree.footnotes then
			local stem_in_effect_footnotes
			if type(stem_in_effect) == "table" then
				stem_in_effect_footnotes = stem_in_effect.footnotes
				stem_in_effect = stem_in_effect.form
			end
			stem_in_effect = iut.combine_form_and_footnotes(stem_in_effect,
				iut.combine_footnotes(base.footnotes, iut.combine_footnotes(degree.footnotes,
					stem_in_effect_footnotes)))
		end

		-- FIXME, needs fixing for Serbo-Croatian
		local combined_footnotes = iut.combine_footnotes(iut.combine_footnotes(mut_footnotes, infix_footnotes),
			ending_footnotes)
		local ending_with_notes = iut.combine_form_and_footnotes(ending, combined_footnotes)
		if not stem_in_effect then
			interr_add("stem_in_effect is nil")
		end
		iut.add_forms(base.forms, slot_prefix .. slot, stem_in_effect, ending_with_notes, combine_stem_ending)
	end
end


--[=[
Comments about axes of variation:
1. Some adjectives are definite-only. This seems to apply to all adjectives in -skī, -čkī and the like, but it also
   applies to some other adjectives. Even in otherwise indefinite contexts, the vocative is definite; some authorities
   consider the indefinite vocative missing, while others copy the definite vocative forms (always the same as the
   nominative) to the indefinite.
2. Some adjectives are reducible, meaning that there is a fleeting ''a'' in the indefinite nominative masculine singular
   that isn't in any other forms. Accompanying the deletion of ''a'' is sometimes consonant cluster simplification, such
   as kȍrīstan "useful", which becomes definite kȍrīsnī. There is also occasionally compensatory lengthening of the
   stressed vowel, as in gròzdak "?" -> gróskī, but I don't know how frequent or regular it is; we might just want to
   handle it manually. Note that not all adjectives in -an are reducible, e.g. lȁgan "light (in weight)" is not.
3. Some compound adjectives have more than one stress, e.g. rȁnobrònčanodȍbnī "hand-to-hand combat (relational)".
4. There are hard and soft adjectives. Soft adjectives end in a palatal consonant (FIXME: what are they, and are there
   "both-ways" consonants, maybe like 'r', that can occur either hard or soft?). Soft adjectives have an -e- instead of
   an -o- in the masculine and neuter singular endings (but notably not in the feminine singular endings, which still
   have dat/loc -ōj and ins -ōm); no plural endings have an -o- in them to begin with.
5. Even outside of reducibility, adjectives can have up to three stem variants. An example with all three is gȏl
   "naked" (which appears in the lemma form as gȏ in Bosnia and Serbia, but maintains the -l- in all other forms).
   This adjective has long-falling gȏl in the indefinite lemma form but short-rising gòl- elsewhere in the indefinite,
   and short-falling gȍl- throughout the definite. The comparative is gòlijī. Note also this means that in general, no
   definite forms can be merged with any indefinite forms. The following multi-stem variants exist:
   a. Vukušić's type 18 (sec 509, page 135): e.g. žȗt "yellow": long falling in lemma, indef nom fem sg žúta, indef nom
      neut sg žúto or less commonly žȗto, etc. elsewhere in the indefinite žút-, definite žȗtī etc. Other examples:
	  bijȇl "white" (which appears to be bȅo in Serbia, otherwise with the same accents but with -e- replacing -ije-),
	  blȃg "soft", blijȇd "pale", bȓz "fast", cijȇl "whole" (also cȉo in the lemma form, with other forms the same; cȅo
	  in Serbia, similarly to bȅo), cȓn "black", čȇst "frequent", čvȓst "fixed; strong", drȃg "dear", fȋn "fine",
	  glȗh "deaf" (glȗv in Serbia), glȗp "stupid", gnjȉo "rotten" (gnjil- in other forms), gȓd "ugly (regional)",
	  grȗb "rough; rude", gȗst "dense", hȗd "angry; bad; evil (rare, archaic, regional)", jȃk "strong", krȋv
	  "guilty; wrong; curved", kȓnj "truncated; incomplete; damaged" (soft declension), krȗt "stiff; strict",
	  kȗs "too short; incomplete (rare)", lijȇn "lazy" (lȇnj in Serbia, soft declension), lijȇp "nice, pretty" (lȇp in
	  Serbia), lȗd "crazy", ljȗt "angry; fierce; spicy", mlȃd "young", mlȃk "tepid; irresolute", nȃg "naked",
	  nijȇm "mute; silent (of a film)" (nȇm in Serbia), plȃh "cowardly", plȃv "blue; blonde",
	  prijȇk "urgent; (when definite) direct, shortened (of a road, etc.)" (presumably prȇk in Serbia),
	  pȗst "empty; futile", rȋđ "reddish, red" (soft declension), rȗd "curly; reddish-brown" (two different etymologies
	  but they appear to have merged completely in inflection), sijȇd "gray" (sȇd in Serbia), sȋv "gray",
	  skȗp "expensive", slȃn "salty", slijȇp "blind" (slȇp in Serbia), strȃn "foreign; strange", sȗh "dry; thin" (sȗv in
	  Serbia), sȗr "ash-gray; gloomy (expressive, literary)", svȇt "holy", štȗr "withered; barren",
	  tȗđ "someone else's; foreign" (soft declension), tȗp "blunt; dull; stupid", tȗst "fat", tvȓd "hard, firm",
	  vrȃn "black, raven-colored (expressive)", vrȗć "hot; cordial" (soft declension), žȋv "alive".
   b. Vukušić's type 19 (sec 510, page 136): e.g. zdrȁv "healthy", bȉstar "clear; clean; clever" (stem bistr-).
      Similarly to type 18, the falling changes to rising elsewhere in the indefinite (optionally in the neuter):
	  zdràva, zdràvo or zdrȁvo, genitive zdràva, etc.; definite zdrȁvī etc. Likewise bìstra, bìstro or bȉstro, genitive
	  bìstra etc.; definite bȉstrī etc. Other examples: blȉzak (stem blisk-) "near", bȍdar (stem bodr-)
	  "alert; vigorous", brȉdak (stem britk-) "sharp; prickly", čȉl/čȉo (stem čil-) "strong, vigorous", čȉst
	  "clean; pure", čȉtak (stem čitk-) "legible", dȍbar (stem dobr-) "good", drȍban (stem drobn-) "small, tiny",
	  dȑzak (stem drsk-) "insolent; arrogant", dȕg "long", gȉbak (stem gipk-) "flexible", glȁdak (stem glatk-) "smooth",
	  grȅz "rough; crude", grȉzak (stem grisk-?) "? (obsolete)", gȑk "bitter (expressive, literary)", hȉtar (stem hitr-)
	  "fast, speedy", hrȍm "lame, limping", jȅdak (stem jetk-) "acrid; scathing", kljȁst "lame (in the arm)",
	  krȅpak (stem krepk-) "strong", kȑhak (stem krhk-) "brittle, fragile", krȍtak (stem krotk-) "tame, gentle",
	  kȑt "brittle", lȁk "easy, light", lȍš "bad, wicked; inferior" (soft declension), lȍvak (stem lovk-?)
	  "? (obsolete)", ljȕbak (stem ljupk-) "cute, charming", mȅdan (stem medn-) "honey-sweet", mȅk "soft",
	  mȉo (stem mil-) "dear; kind", mȍćan (stem moćn-) "powerful; influential", mȍdar (stem modr-) "dark blue",
	  mȍkar (stem mokr-) "wet", mȑčan < mȑk (stem mrčn-?) "? (obsolete), mȑk "brown; grim, gloomy (of a person)",
	  mȑkao (stem mrkl-?) "? (obsolete)", mȑzak (stem mrsk-) "hateful", mȑzao/mȑzal (stem mrzl-)
	  "cold (expressive, literary)", nȉzak (stem nisk-) "low; common, vile", nȍv "new; modern", ȍbal/ȍbao (stem obl-)
	  "round, oval", ȍštar (stem oštr-) "sharp; strict", pȉtak (stem pitk-) "potable", pjȁn
	  "drunk (regional, rhetorical [?])", plȍdan (stem plodn-) "fertile; prolific", pȍstan (stem posn-) "lean", pȍtan
	  (stem potn-?) "? (obsolete)", prȁv "straight; right", pȑhak (stem prhk-) "crumbly", prȍst
	  "common; simple; vulgar", pȕn "full", pȕtak (stem putk-?) "? (obsolete)", rȁd "willing" (maybe no definite
	  forms?), rȅzak (stem resk-) "cutting", rȍdan (stem rodn-) "fruitful, fertile", rȍsan (stem rosn-)
	  "dewy; dew (relational)", sȉt "sated, full", sȉtan (stem sitn-) "tiny; trivial", sklȉzak (stem sklisk-)
	  "slippery", slȁb "weak", slȁdak (stem slatk-) "sweet", spȍr "slow, sluggish", stȁr (definite stȃrī) "old",
	  stȑm "steep", strȍg "severe; harsh", svjȅž "fresh" (svȅž in Serbia), šȕt "hornless (of a young animal)",
	  tȁnak (stem tank-) "thin; slender", tmȁst "dark, fuscous", tmȕo (stem tmul-)
	  "dark, gloomy; muffled, hoarse (of a voice)", tȍpao/tȍpal (stem topl-) "warm", trȍm "sluggish, slow",
	  trȕo (stem trul-) "rotten, putrid", ȕzak (stem usk-) "narrow; tight", vȅdar (stem vedr-)
	  "clear (of the sky); cheerful", vȉtak (stem vitk-) "slim, slender", vjȅšt "able, skillful" (vȅšt in Serbia),
	  vlȁžan (stem vlažn-) "humid", vȍzak (stem vosk-?) "? (obsolete)", vrȅo (stem vrel-) "hot, boiling",
	  zrȅo (stem zrel-) "ripe; mature", žȉdak (stem žitk-) "somewhat thin (in consistency); flexible (figurative)",
	  žȕk "bitter (regional), žȕstar (stem žustr-) "frenetic, energetic".
   c. Vukušić's type 20 (sec 511, page 138): e.g. žédan (stem žedn-) "thirsty". Long rising throughout the indefinite,
      long falling throughout the definite: žédan, žédna, žédno, def. žȇdnī. All of these adjectives are disyllabic
	  (or "trisyllabic" in the case of some adjectives with -ije-) with fleeting ''a''. According to Vukušić (sec 512,
	  page 139), many of these, including žédan, have a variant žȇdan in the lemma form and žȇdno in the neuter, but
	  žédn- elsewhere in the indefinite, and žȇdn- in the definite. Galloglach21 says he's never heard this variant, so
	  it must be rare. Other examples: bijésan (stem bijesn-) "furious" (bésan in Serbia), búdan (stem budn-)
	  "awake", dijélan (stem dijeln-?) "? (obsolete)", drijéman (stem drijemn-?) "? (obsolete; from drijȇm "slumber"),
	  dúžan (stem dužn-) "owing, in debt", gládan (stem gladn-) "hungry", górak (stem gork-) "bitter",
	  gŕdan (stem grdn-) "ugly (colloquial); bad, terrible; many, much", háran (stem harn-)
	  "(archaic) virtuous; modest; (expressive) grateful", hládan (stem hladn-) "cold", hrábar (stem hrabr-)
	  "bold, brave", húdan (stem hudn-?) "? (obsolete)", húlan (stem huln-?) "? (obsolete)", jédar (stem jedr-)
	  "strong, big", kádar "capable, able" (claimed indeclinable by HJP and Školski Rječnik), krátak (stem kratk-)
	  "short", krúpan (stem krupn-) "sturdy, bulky; big", kváran (stem kvarn-) "defective, damaged",
	  lástan (stem lasn-?) "capable, able ('sposoban') (obsolete)", máman (stem mamn-?) "? (obsolete)",
	  mástan (stem masn-) "fatty, greasy; boldface", mázan (stem mazn-) "cuddly", míran (stem mirn-)
	  "calm; quiet; still", mláčan (stem mlačn-) "tepid, lukewarm", mráčan (stem mračn-) "dark, gloomy",
	  mísan (stem misn-) "? (obsolete)", mŕtav (stem mrtv-) "dead; lifeless", múdar (stem mudr-) "wise",
	  mútan (stem mutn-) "unclear; blurry; murky", nágao (stem nagl-) "hasty; sudden; fierce", njéžan (stem nježn-)
	  "tender, soft" (néžan in Serbia), óran (stem orn-) "(colloquial) ready; brave", plítak (stem plitk-) "shallow",
	  prášan (stem prašn-) "powdery, dusty", prázan (stem prazn-) "empty; blank; frivolous", prijésan (stem prijesn-)
	  "raw (of food)" (présan in Seria), rávan (stem ravn-) "straight, right; level", rijédak (stem rijetk-)
	  "rare; sparse; watery (of soup)" (rédak in Serbia), rúžan (stem ružn-) "ugly; unpleasant; dishonest; obscene",
	  sjájan (stem sjajn-) "radiant; great, awesome", slástan (stem slasn-) "delicious, tasty", smijéšan (stem smiješn-)
	  "funny" (sméšan in Serbia), snážan (stem snažn-) "strong, powerful", stálan (stem staln-)
	  "permanent; continuous; stable", stídan (stem stidn-) "shy", strášan (stem strašn-) "dire; terrible",
	  svijétao (stem svijetl-) "bright; light (in color)" (svétao in Serbia), šúpalj (stem šuplj-) "hollow"
	  (soft declension), táman (stem tamn-) "dark, dim", téžak (stem tešk-) "heavy; difficult; unpleasant",
	  tijésan (stem tijesn-) "tight; close, intimate; narrow" (tésan in Serbia), trijézan (stem trijezn-) "sober"
	  (trézan in Serbia), túžan (stem tužn-) "sad", vjéran (stem vjern-) "faithful, loyal" (véran in Serbia),
	  vlástan (stem vlasn-) "powerful, with authority", vrijédan (stem vrijedn-) "precious; diligent; worthy" (vrédan in
	  Serbia), zlátan (stem zlatn-) "golden", znójan (stem znojn-) "sweaty", zráčan (stem zračn-)
	  "airy; air (relational)", zvúčan (stem zvučn-)
	  "resonant, loud; well-known; voiced (of a sound); sound (relational)". Only the following have the žȇdan-type
	  variation: bȗdan, dijȇlan, drijȇman, glȃdan, gȏrak, gȓdan, hȃran, hlȃdan, hrȃbar, hȗdan, hȗlan, krȃtak, krȗpan,
	  kvȃran, mȃstan, mlȃčan, mrȃčan, mȓsan, mȗtan, plȋtak, prȃšan, prȃzan, rȃvan, rijȇdak, rȗžan, sjȃjan, slȃstan,
	  snȃžan, stȋdan, strȃšan, tȃman, težak, tijȇsan, tȗžan, zlȃtan, znȏjan, zrȃčan, zvȗčan.
   d. Sec 411 page 103 says that some adjectives can change a short or long falling accent in the definite into a short
      rising accent. Example is krátak, which per (c) would normally have definite krȃtkī but can also have kràtkī. Per
	  Galloglach21 this is regional, maybe characteristic of the Western areas, e.g. Lika, Dalmatia. Such adjectives
	  include brȏjnī -> bròjnī, cvjȅtnī -> cvjètnī, čȇstī -> čèstī, dȕgi -> dùgī, krȃtki -> kràtki, krȗpnī -> krùpnī,
	  lȏvnī -> lòvnī, lȋsnī -> lìsnī, mȅki -> mèkī, mijȇšnī -> mjèšnī (< mijȇh), mȍkrī -> mòkrī, mȑki -> mr̀ki,
	  mȓsnī -> mr̀snī, nȍćnī -> nòćnī, ȍblī -> òblī, ȍčnī -> òčnī, pȇtnī -> pètnī, plȋtkī -> plìtkī, pȍsnī -> pòsnī,
	  rijȇtkī -> rjètkī, rijȇčnī (prema rijéka) -> rjèčnī (prema rijȇč), rȕčnī -> rùčnī, rȗdnī -> rùdnī, svȇtī -> svètī,
	  strȃšnī -> stràšnī, strȏjnī -> stròjnī, tȇškī -> tèškī, tȏvnī -> tòvnī, vȉtkī -> vìtkī, vjȅčnī -> vjèčnī,
	  zvȗčnī -> zvùčnī, žȉtkī -> žìtkī, žȕčnī -> žùčnī; as well as a similar list of non-reducible adjectives:
	  brȁšnenī -> brašnènī, cr̀kvenī -> crkvènī, đȁvoljī -> đavòljī, ìglenī -> iglènī, jȁnjećī -> janjèćī,
	  kàvenī -> kavènī, kòštanī -> koštànī, làđenī -> lađènī, lȅdenī -> ledènī, nòvčanī -> novčànī,
	  ȍdrenī -> odrènī < ȍdar, pàklenī -> paklènī, pȉlećī -> pilèćī, pùščanī -> puščànī, sr̀čanī -> srčànī,
	  svjètovnī -> svjetòvnī, sùnčanī -> sunčànī, ùljanī -> uljànī, vòdenī -> vodènī, zèmljani -> zemljànī,
	  zòbenī -> zobènī, zvjèzdanī -> zvjezdànī, ždrèbećī -> ždrebèćī.
   e. Vukušić's type 21 (sec 513, page 139): three different accent variants; only two examples, gȏl "naked" (gȏ in
      Bosnia and Serbia) and bȏs "barefoot". In the indefinite, these have gȏl, fem gòla neut gòlo or gȍlo, gòl-
	  throughout the rest of the indefinite paradigm, and gȍlī in the definite.
   f. Vukušić's type 22 (sec 514, page 141): zèlen "green; unripe", fem zelèna, neut zelèno, zelèn- throughout the rest
      of the indefinite paradigm, zèlenī in the definite. Other examples are cr̀ven "red; ruddy", dàlek "far, distant",
	  dèbeo (stem debel-) "fat, thick", dùbok "deep", màlen "small", pòšten "honest, sincere", rùmen "rosy, reddish",
	  stùden "cold; frigid", svìlen "silk (relational); silky", šàren "multicolored; diverse", šìrok "wide", vìsok
	  "high, tall", žèstok "severe; pungent".

]=]
local function add_normal_decl(base, degree, props,
	def_nom_m, indef_nom_f, def_nom_f, indef_nom_n, def_nom_n,
	indef_nom_mp, def_nom_mp, indef_nom_fp, def_nom_fp, indef_nom_np, def_nom_np,
	indef_gen_mn, def_gen_mn, gen_f, gen_p,
	indef_dat_mn, def_dat_mn, dat_f, dat_p,
	indef_acc_f, def_acc_f, indef_acc_mp, def_acc_mp,
	ins_mn, ins_f,
	indef_loc_mn, def_loc_mn, loc_f,
	footnote)
	add(base, "indef_nom_m", degree, props, "")
	add(base, "def_nom_m", degree, props, def_nom_m)
	add(base, "indef_nom_f", degree, props, indef_nom_f)
	add(base, "def_nom_f", degree, props, def_nom_f)
	add(base, "indef_nom_n", degree, props, indef_nom_n)
	add(base, "def_nom_n", degree, props, def_nom_n)
	add(base, "indef_nom_mp", degree, props, indef_nom_mp)
	add(base, "def_nom_mp", degree, props, def_nom_mp)
	add(base, "indef_nom_fp", degree, props, indef_nom_fp)
	add(base, "def_nom_fp", degree, props, def_nom_fp)
	add(base, "indef_nom_np", degree, props, indef_nom_np)
	add(base, "def_nom_np", degree, props, def_nom_np)
	add(base, "indef_gen_m", degree, props, indef_gen_mn)
	add(base, "def_gen_m", degree, props, def_gen_mn)
	add(base, "indef_gen_f", degree, props, gen_f)
	add(base, "def_gen_f", degree, props, gen_f)
	add(base, "indef_gen_n", degree, props, indef_gen_mn)
	add(base, "def_gen_n", degree, props, def_gen_mn)
	add(base, "indef_gen_p", degree, props, gen_p)
	add(base, "def_gen_p", degree, props, gen_p)
	add(base, "indef_dat_m", degree, props, indef_dat_mn)
	add(base, "def_dat_m", degree, props, def_dat_mn)
	add(base, "indef_dat_f", degree, props, dat_f)
	add(base, "def_dat_f", degree, props, dat_f)
	add(base, "indef_dat_n", degree, props, indef_dat_mn)
	add(base, "def_dat_n", degree, props, def_dat_mn)
	add(base, "indef_dat_p", degree, props, dat_p)
	add(base, "def_dat_p", degree, props, dat_p)
	add(base, "indef_acc_m_in", degree, props, "")
	add(base, "indef_acc_m_an", degree, props, indef_gen_mn)
	add(base, "def_acc_m_in", degree, props, def_nom_m)
	add(base, "def_acc_m_an", degree, props, def_gen_mn)
	add(base, "indef_acc_f", degree, props, indef_acc_f)
	add(base, "def_acc_f", degree, props, def_acc_f)
	add(base, "indef_acc_n", degree, props, indef_nom_n)
	add(base, "def_acc_n", degree, props, def_nom_n)
	add(base, "indef_acc_mp", degree, props, indef_acc_mp)
	add(base, "def_acc_mp", degree, props, def_acc_mp)
	add(base, "indef_acc_fp", degree, props, indef_nom_fp)
	add(base, "def_acc_fp", degree, props, def_nom_fp)
	add(base, "indef_acc_np", degree, props, indef_nom_np)
	add(base, "def_acc_np", degree, props, def_nom_np)
	add(base, "def_voc_m", degree, props, def_nom_m)
	add(base, "def_voc_f", degree, props, def_nom_f)
	add(base, "def_voc_n", degree, props, def_nom_n)
	add(base, "def_voc_mp", degree, props, def_nom_mp)
	add(base, "def_voc_fp", degree, props, def_nom_fp)
	add(base, "def_voc_np", degree, props, def_nom_np)
	add(base, "indef_ins_m", degree, props, ins_mn)
	add(base, "def_ins_m", degree, props, ins_mn)
	add(base, "indef_ins_f", degree, props, ins_f)
	add(base, "def_ins_f", degree, props, ins_f)
	add(base, "indef_ins_n", degree, props, ins_mn)
	add(base, "def_ins_n", degree, props, ins_mn)
	add(base, "indef_ins_p", degree, props, dat_p)
	add(base, "def_ins_p", degree, props, dat_p)
	add(base, "indef_loc_m", degree, props, indef_loc_mn)
	add(base, "def_loc_m", degree, props, def_loc_mn)
	add(base, "indef_loc_f", degree, props, loc_f)
	add(base, "def_loc_f", degree, props, loc_f)
	add(base, "indef_loc_n", degree, props, indef_loc_mn)
	add(base, "def_loc_n", degree, props, def_loc_mn)
	add(base, "indef_loc_p", degree, props, dat_p)
	add(base, "def_loc_p", degree, props, dat_p)
end

local decls = {}

decls["normal-Latn"] = function(base, degree, props)
	local soft = props.soft
	add_normal_decl(base, degree, props,
		-- nom sg
		     "ī", "a", "ā", soft and "e" or "o", soft and "ē" or "ō",
		-- nom pl
		"i", "ī", "e", "ē", "a", "ā",
		-- gen
		"a", soft and {"ēg", "ēga"} or {"ōg", "ōga"}, "ē", "īh",
		-- dat
		"u", soft and {"ēm", "ēmu"} or {"ōm", "ōmu", {form = "ōme", footnotes = "[not usually in Croatia]"}}, "ōj", {"īm", "īma"},
		-- acc
		"u", "ū",
		-- ins
		"īm", "ōm", "e", "ē",
		-- loc
		"u", {"ōm", "ōmu"}, "ōj"
	)
end

decls["normal-Cyrl"] = function(base, degree, props)
	local soft = props.soft
	add_normal_decl(base, degree, props,
		-- nom sg
		     "ӣ", "а", "а̄", soft and "е" or "о", soft and "е̄" or "о̄",
		-- nom pl
		"и", "ӣ", "е", "е̄", "а", "а̄",
		-- gen
		"а", soft and {"е̄г", "е̄га"} or {"о̄г", "о̄га"}, "е̄", "ӣх",
		-- dat
		"у", soft and {"е̄м", "е̄му"} or {"о̄м", "о̄му", {form = "о̄ме", footnotes = "[not usually in Croatia]"}}, "о̄ј", {"ӣм", "ӣма"},
		-- acc
		"у", "ӯ",
		-- ins
		"ӣм", "о̄м", "е", "е" .. MACRON,
		-- loc
		"у", {"о̄м", "о̄му"}, "о̄ј"
	)
end

decls["builtin"] = function(base, degree, props)
	error("not implemented")
end


-- Return the lemmas for this term. The return value is a list of {form = FORM, footnotes = FOOTNOTES}.
-- If `linked_variant` is given, return the linked variants (with embedded links if specified that way by the user),
-- otherwies return variants with any embedded links removed. If `remove_footnotes` is given, remove any
-- footnotes attached to the lemmas.
function export.get_lemmas(alternant_multiword_spec, linked_variant, remove_footnotes)
	local slots_to_fetch = potential_lemma_slots
	local linked_suf = linked_variant and "_linked" or ""
	for _, slot in ipairs(slots_to_fetch) do
		if alternant_multiword_spec.forms[slot .. linked_suf] then
			local lemmas = alternant_multiword_spec.forms[slot .. linked_suf]
			if remove_footnotes then
				local lemmas_no_footnotes = {}
				for _, lemma in ipairs(lemmas) do
					table.insert(lemmas_no_footnotes, {form = lemma.form})
				end
				return lemmas_no_footnotes
			else
				return lemmas
			end
		end
	end
	return {}
end


local function do_slot_abbreviation(base, abbr, fn)
	local patterns = adjective_slot_abbrs[abbr]
	if not patterns then
		error(("Internal error: Invalid abbreviation '%s' passed into do_slot_abbreviation()"):format(abbr))
	end
	if type(patterns) ~= "table" then
		patterns = {patterns}
	end
	for _, pattern in ipairs(patterns) do
		pattern = "^" .. pattern .. "$"
		for single_slot, forms in pairs(base.forms) do
			if rfind(single_slot, pattern) then
				fn(single_slot)
			end
		end
	end
end


local function process_slot_overrides(base)
	-- Set a single slot. Check to make sure we're not hitting a degree, number or state restriction.
	local function do_slot(slot, spec)
		local degfield = slot_to_degfield(slot)
		if not base.degrees[degfield] or not base.degrees[degfield][1] then
			error(("Override specified for invalid slot '%s' because degree '%s' doesn't exist"):format(slot, degfield))
		end
		for _, degree in ipairs(base.degrees[degfield]) do
			if skip_slot(degree.number, degree.state, slot) then
				error(("Override specified for invalid slot '%s' due to '%s' number restriction and/or '%s' state " ..
					"restriction of degree '%s'"):format(slot, degree.number, degree.state, degfield))
			end
		end
		if spec[1].form ~= "-" then
			-- Make sure distinct slots don't share forms.
			base.forms[slot] = m_table.deepCopy(spec)
		else
			base.forms[slot] = nil
		end
	end

	for slot, spec in pairs(base.overrides) do
		if adjective_slot_abbrs[slot] then
			do_slot_abbreviation(base, slot, function(slot) do_slot(slot, spec) end)
		else
			do_slot(slot, spec)
		end
	end
end


local function handle_derived_slots_and_overrides(base)
	-- Process slot overrides: First slots specified after the gender, then individual slot overrides specified as
	-- separate indicators.
	process_slot_overrides(base)

	-- Compute linked versions of potential lemma slots, for use in {{sh-adj}}.  We substitute the original lemma
	-- (before removing links) for forms that are the same as the lemma, if the original lemma has links.
	for _, slot in ipairs(potential_lemma_slots) do
		iut.insert_forms(base.forms, slot .. "_linked", iut.map_forms(base.forms[slot], function(form)
			if form == base.orig_lemma_no_links and base.orig_lemma:find("%[%[") then
				return base.orig_lemma
			else
				return form
			end
		end))
	end
end


-- Process specs given by the user using 'addnote[SLOTSPEC][FOOTNOTE][FOOTNOTE][...]'.
local function process_addnote_specs(base)
	for _, spec in ipairs(base.addnote_specs) do
		local function do_one(slot_spec)
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
	
		for _, slot_spec in ipairs(spec.slot_specs) do
			slot_spec = adjective_slot_abbrs[slot_spec] or slot_spec
			if type(slot_spec) == "table" then
				for _, ss in ipairs(slot_spec) do
					do_one(ss)
				end
			else
				do_one(slot_spec)
			end
		end
	end
end


-- Map `fn` over all override specs in `override_list`. `fn` is passed two items (the slot and form object of the
-- override), which it can mutate if needed. If it ever returns non-nil, mapping stops and that value is returned
-- as the return value of `map_override`; otherwise mapping runs to completion and nil is returned.
local function map_override(slot, override_list, fn)
	for _, formobj in ipairs(override_list) do
		local retval = fn(slot, formobj)
		if retval ~= nil then
			return retval
		end
	end
	return nil
end


-- Map `fn` over all override specs in `base.overrides` and the positive/comparative/superlative specs. `fn` is passed
-- two items (the slot and form object of the override), which it can mutate if needed. If it ever returns non-nil,
-- mapping stops and that value is returned as the return value of `map_all_overrides`; otherwise mapping runs to
-- completion and nil is returned.
local function map_all_overrides(base, fn)
	for slot, override in pairs(base.overrides) do
		local retval = map_override(slot, override, fn)
		if retval ~= nil then
			return retval
		end
	end
	for _, degspec in ipairs(compsup_degrees) do
		local degfield, desc = unpack(degspec)
		local field = degfield .. "spec"
		if base[field] then
			local retval = map_override(field, base[field], fn)
			if retval ~= nil then
				return retval
			end
		end
	end
	return nil
end


-- Like put.split_alternating_runs_and_strip_spaces(), but ensure that backslash-escaped commas and periods are not
-- treated as separators.
local function split_alternating_runs_with_escapes(segments, splitchar)
	for i, segment in ipairs(segments) do
		segment = rsub(segment, "\\,", SUB_ESCAPED_COMMA)
		segments[i] = rsub(segment, "\\%.", SUB_ESCAPED_PERIOD)
	end
	local separated_groups = put.split_alternating_runs_and_strip_spaces(segments, splitchar)
	for _, separated_group in ipairs(separated_groups) do
		for i, segment in ipairs(separated_group) do
			segment = rsub(segment, SUB_ESCAPED_COMMA, ",")
			separated_group[i] = rsub(segment, SUB_ESCAPED_PERIOD, ".")
		end
	end
	return separated_groups
end


local function fetch_footnotes(separated_group, parse_err)
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


-- Return true if the given spec of one of the degrees (pos/comp/sup) explicitly disabled through -pos, -comp or -sup.
-- Also return true if `also_if_unspecified` given and the spec was left unspecified (this doesn't make sense for
-- 'pos').
local function degree_disabled(spec, also_if_unspecified)
	if not spec then
		return also_if_unspecified
	end
	for _, formval in ipairs(spec) do
		if formval.form == "-" then
			return true
		end
	end
	return false
end


local function parse_slot_override_or_comp_spec(colon_separated_group, segments, specs, spectype, parse_err)
	local form = colon_separated_group[1]
	if form == "" then
		parse_err(("Empty overrides not allowed for %s: '%s'"):format(spectype, table.concat(segments)))
	end
	local new_spec = {form = form, footnotes = fetch_footnotes(colon_separated_group, parse_err)}
	for _, existing_spec in ipairs(specs) do
		if existing_spec.form == new_spec.form then
			parse_err("Duplicate " .. spectype .. " spec '" .. table.concat(colon_separated_group) .. "'")
		end
	end
	table.insert(specs, new_spec)
end


--[=[
Parse a comparative or stem spec (e.g. 'comp^^:+' or 'comp:+:dublji' or 'defstem:stȃr') and return the list of values.
Each value is a form object, i.e. an object containing 'form' and 'footnotes' fields.
]=]
local function parse_comp_or_stem_spec(segments, spectype, parse_err)
	local specs = {}
	local colon_separated_groups = put.split_alternating_runs_and_strip_spaces(segments, ":")
	for i, colon_separated_group in ipairs(colon_separated_groups) do
		if i == 1 then
			if colon_separated_group[2] then
				parse_err(("Footnotes not allowed directly on %s '%s'; put them on the value following the colon"):
					format(spectype, colon_separated_group[1]))
			end
		else
			parse_slot_override_or_comp_spec(colon_separated_group, segments, specs, spectype, parse_err)
		end
	end
	return specs
end


--[=[
Parse a single override (e.g. 'indef_nom_n:stȁro') and return two values: the slot(s) the override applies to, and a
list of override values. Each override value is a form object, i.e. an object containing 'form' and 'footnotes' fields.
]=]
local function parse_override(segments, parse_err)
	local slots = {}
	local specs = {}
	local colon_separated_groups = put.split_alternating_runs_and_strip_spaces(segments, ":")
	for i, colon_separated_group in ipairs(colon_separated_groups) do
		if i == 1 then
			if colon_separated_group[2] then
				parse_err(("Footnotes not allowed directly on slot override '%s'; put them on the value following " ..
					"the colon"):format(colon_separated_group[1]))
			end
			slots = rsplit(colon_separated_group[1], "%+")
			for _, slot in ipairs(slots) do
				if not adjective_slot_set[slot] and not adjective_slot_abbrs[slot] then
					parse_err(("Unrecognized slot '%s' in override; expected slot %s preceded by one of 'indef_'," ..
						"'def_', 'comp_' or 'sup_'; abbreviation %s; or stem %s: %s"):format(
						slot, make_quoted_slot_list(input_adjective_slots), make_quoted_keys(adjective_slot_abbrs),
						make_quoted_list(export.overridable_stems),
						put.escape_wikicode(table.concat(segments))))
				end
			end
		else
			parse_slot_override_or_comp_sup_spec(colon_separated_group, segments, specs, "slot override", parse_err)
		end
	end
	return slots, specs
end


-- Export for use by [[Module:sh-noun]].
function export.parse_for_control_specs(part, parse_control_spec)
	if part:find("^%-?%*") then
		parse_control_spec("*", {"*", "-*"})
	elseif part:find("^%-?[23]tone") then
		parse_control_spec("2tone", {"2tone", "3tone", "-2tone"})
	else
		return false
	end
	return true
end


local function parse_inside(base, inside, is_scraped_adj)
	local function parse_err(msg)
		usererr((is_scraped_adj and "Error processing scraped adjective spec: " or "") .. msg .. ": <" ..
			inside .. ">")
    end

	-- FIXME: We need to investigate more carefully which strings are decomposed and make sure all error messages
	-- recompose the strings.
	inside = com.decompose(inside)
	local base_degree = {}
	local segments = put.parse_balanced_segment_run(inside, "[", "]")
	local dot_separated_groups = split_alternating_runs_with_escapes(segments, "%.")
	for i, dot_separated_group in ipairs(dot_separated_groups) do
		-- Parse a control spec such as "-*,*[rare]" or "2tone[per VRH],-2tone[per Vukušić]". This assumes the control
		-- spec is contained in `dot_separated_group` (already split on brackets) and the result of parsing should go in
		-- `base_degree[dest]`. `allowed_specs` is a list of the allowed control specs in this group, such as
		-- {"*", "-*"}. The result of parsing is a list of structures of the form {
		--   form = "FORM",
		--   footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...},
		-- }.
		local function parse_control_spec(dest, allowed_specs)
			if base_degree[dest] then
				parse_err(("Can't specify '%s'-type control spec twice; second such spec is '%s'"):format(
					dest, table.concat(dot_separated_group)))
			end
			base_degree[dest] = {}
			local comma_separated_groups = split_alternating_runs_with_escapes(dot_separated_group, ",")
			for _, comma_separated_group in ipairs(comma_separated_groups) do
				local specobj = {}
				local spec = comma_separated_group[1]
				if not m_table.contains(allowed_specs, spec) then
					parse_err(("For '%s'-type control spec, saw unrecognized spec '%s'; valid values are %s"):
						format(dest, spec, generate_list_of_possibilities_for_err(allowed_specs)))
				else
					specobj.form = spec
				end
				specobj.footnotes = fetch_footnotes(comma_separated_group, parse_err)
				table.insert(base_degree[dest], specobj)
			end
		end

		local part = dot_separated_group[1]
		if part == "" then
			if not dot_separated_group[2] then
				parse_err("Blank indicator; not allowed without attached footnotes")
			end
			base.footnotes = fetch_footnotes(dot_separated_group, parse_err)
		elseif part == "addnote" then
			local spec_and_footnotes = fetch_footnotes(dot_separated_group, parse_err)
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
		elseif export.parse_for_control_specs(part, parse_control_spec) then
			-- nothing more to do
		elseif part:find("^decllemma%s*:") then -- or part:find("^decldef%s*:") or part:find("^declnumber%s*:") then
			local field, value = part:match("^(decl[a-z]+)%s*:%s*(.+)$")
			if not value then
				parse_err(("Syntax error in decllemma indicator: '%s'"):format(part))
			end
			if #dot_separated_group > 1 then
				parse_err(
					("Footnotes not allowed with '%s:' specs: '%s'"):format(field, table.concat(dot_separated_group)))
			end
			if base[field] then
				parse_err(("Can't specify '%s:' twice"):format(field))
			end
			base[field] = value
		elseif part:find("^q%s*:") or part:find("header%s*:") then
			local field, value = part:match("^(q)%s*:%s*(.+)$")
			if not value then
				field, value = part:match("^(header)%s*:%s*(.+)$")
			end
			if not value then
				parse_err(("Syntax error in q/header indicator: '%s'"):format(part))
			end
			if #dot_separated_group > 1 then
				parse_err(
					("Footnotes not allowed with '%s:' specs: '%s'"):format(field, table.concat(dot_separated_group)))
			end
			if base[field] then
				parse_err(("Can't specify '%s:' twice"):format(field))
			end
			base[field] = value
		elseif part:find("^@") then
			if #dot_separated_group > 1 then
				parse_err(
					("Footnotes not allowed with scrape specs: '%s'"):format(table.concat(dot_separated_group)))
			end
			if base.scrape_spec then
				parse_err("Can't specify scrape directive '@...' twice")
			end
			if part:find(":") then
				base.scrape_is_suffix, base.scrape_spec, base.scrape_id = part:match("^@(%-?)(.-)%s*:%s*(.+)$")
			else
				base.scrape_is_suffix, base.scrape_spec = part:match("^@(%-?)(.-)$")
			end
			-- If we saw a hyphen, set `scrape_is_suffix` to true, otherwise false
			base.scrape_is_suffix = base.scrape_is_suffix == "-"

			if not base.scrape_spec or base.scrape_spec == "" then
				parse_err(("Syntax error in scrape directive '%s"):format(part))
			end
			local scrape_init, scrape_rest = rmatch(base.scrape_spec, "^(.)(.*)$")
			local lower_scrape_init = ulower(scrape_init)
			if ulower(scrape_init) ~= scrape_init then
				base.scrape_is_uppercase = true
				base.scrape_spec = lower_scrape_init .. scrape_rest
			end
		elseif part == "-pos" then
			if dot_separated_group[2] then
				parse_err("Footnotes not allowed with '-pos'")
			end
			if base.posspec then
				parse_err("Can't specify '-pos' twice")
			end
			base.posspec = {{form = "-"}}
		elseif part == "-comp" then
			if dot_separated_group[2] then
				parse_err("Footnotes not allowed with '-comp'")
			end
			if base.compspec then
				parse_err("Can't specify comparative twice twice")
			end
			base.compspec = {{form = "-"}}
		elseif part:find("^comp") and not part:find("^comp_") then
			if part == "comp" then
				part = "comp+"
			end
			if part:find("^comp[+^?]") then
				part = part:gsub("^comp", "comp:")
			end
			dot_separated_group[1] = part
			base.compspec = parse_comp_or_stem_spec(dot_separated_group, "comparative spec", parse_err)
		elseif part:find(":") then
			local spec, value = part:match("^([a-z_+]+)%s*:%s*(.+)$")
			if not spec then
				parse_err(("Syntax error in indicator with value, expecting alphabetic slot, stem/lemma override " ..
					"or comparative/superlative override indicator: '%s'"):format(part))
			end
			if export.overridable_stem_set[spec] then
				if base_degree[spec] then
					parse_err(("Can't specify '%s:' twice"):format(spec))
				end
				base_degree[spec] = parse_comp_or_stem_spec(dot_separated_group, "stem spec", parse_err)
			else
				local slots, override = parse_override(dot_separated_group, parse_err)
				local function check_duplication(slot)
					if base.override_slots_seen[slot] then
						parse_err(("Two overrides specified for slot '%s'"):format(slot))
					else
						base.override_slots_seen[slot] = true
					end
				end
				for _, slot in ipairs(slots) do
					if adjective_slot_abbrs[slot] then
						do_slot_abbreviation(base, slot, check_duplication)
					else
						check_duplication(slot)
					end
					base.overrides[slot] = override
				end
			end
		elseif #dot_separated_group > 1 then
			parse_err(
				("Footnotes only allowed with slot overrides, negatable indicators and by themselves: '%s'"):
					format(table.concat(dot_separated_group)))
		elseif part == "sg" or part == "pl" or part == "both" then
			if base.number then
				if base.number ~= part then
					parse_err("Can't specify '" .. part .. "' along with '" .. base.number .. "'")
				else
					parse_err("Can't specify '" .. part .. "' twice")
				end
			end
			base.number = part
		elseif part == "indef" or part == "def" or part == "bothdefs" then
			if base.definiteness then
				if base.definiteness ~= part then
					parse_err("Can't specify '" .. part .. "' along with '" .. base.definiteness .. "'")
				else
					parse_err("Can't specify '" .. part .. "' twice")
				end
			end
			base.definiteness = part
		elseif export.boolean_property_set[part] then
			if base.props[part] then
				parse_err("Can't specify '" .. part .. "' twice")
			end
			base.props[part] = true
		else
			parse_err("Unrecognized indicator '" .. part .. "'")
		end
	end

	local base_degfield
	if not degree_disabled(base.posspec) then
		base_degfield = "pos"
		base_degree.slot_prefix = ""
	elseif not degree_disabled(base.compspec) then
		base_degfield = "comp"
		base_degree.slot_prefix = "comp_"
	else
		parse_err("Cannot disable both positive and comparative")
	end
	base.base_degfield = base_degfield
	base.base_degree = base_degree
	base.degrees[base_degfield] = {base_degree}
	if base_degfield ~= "pos" then
		-- Indicate that the positive degree is explicitly disabled.
		base.degrees.pos = {}
	else
		--if not base.compspec and not base.props["comp?"] and not base.props.indecl and
		--	not base.props["decl?"] and not base.props.builtin and not base.scrape_spec then
		--	parse_err("Must either specify a comparative, specify '-comp' to indicate no comparative, or " ..
		--		"specify 'comp?' to indicate that the comparative status is unknown")
		--end
	end

	return base
end


-- Set some defaults (e.g. number and definiteness) now, because they (esp. the number) may be needed below when
-- determining how to merge scraped and user-specified properies.
local function set_early_base_defaults(base)
	if not base.props.builtin then
		local basedeg = base.base_degree
		basedeg.number = base.number or "both"
		basedeg.definiteness = base.definiteness or base.base_degfield == "comp" and "def" or "bothdefs"
	end
end

local function parse_inside_and_merge(inside, lemma, scrape_chain)
	local function parse_err(msg)
		usererr(msg .. ": <" .. inside .. ">")
	end

	if #scrape_chain >= 10 then
		local linked_scrape_chain = {}
		for _, element in ipairs(scrape_chain) do
			table.insert(linked_scrape_chain, "[[" .. element .. "]]")
		end
		parse_err(("Probable infinite loop in scraping; scrape chain is [[%s]] -> %s"):format(lemma,
			table.concat(linked_scrape_chain, " -> ")))
	end

	local base = create_base()
	base.scrape_chain = scrape_chain
	parse_inside(base, inside, #scrape_chain > 0)
	local basedeg = base.base_degree
	basedeg.lemma = lemma

	if not base.scrape_spec then
		-- If we're not scraping the declension from another adjective, just return the parsed `base`.
		-- But don't set early defaults if we're being scraped because it interferes with overriding the number
		-- and/or definiteness by the adjective that is scraping us.
		if #scrape_chain == 0 then
			set_early_base_defaults(base)
		end
		return base
	else
		local prefix, base_adj, declspec
		prefix, base_adj, declspec = iut.find_scraped_infl {
			langname = "Serbo-Croatian",
			lemma = lemma,
			scrape_spec = base.scrape_spec,
			scrape_is_suffix = base.scrape_is_suffix,
			scrape_is_uppercase = base.scrape_is_uppercase,
			infltemp = "sh-adecl",
			allow_empty_infl = false,
			inflid = base.scrape_id,
			-- FIXME, implement this for Serbo-Croatian
			parse_off_ending = com.parse_off_final_nom_ending,
		}
		if type(declspec) == "string" then
			base.prefix = prefix
			base.base_adj = base_adj
			base.scrape_error = declspec
			return base
		end

		-- Parse the inside spec from the scraped adjective (merging any sub-scraping specs), and copy over the
		-- user-specified properties on top of it.
		table.insert(scrape_chain, base_adj)
		local inner_base = parse_inside_and_merge(declspec.infl, base_adj, scrape_chain)
		local inner_basedeg = inner_base.base_degree
		inner_basedeg.lemma = lemma
		inner_base.prefix = prefix
		inner_base.base_adj = base_adj

		-- Add `prefix` to a full variant of the base adjective (e.g. a stem spec or override). We may need
		-- to adjust the variant to take into account the base adjective being a suffix and/or uppercase (e.g. when
		-- we use [[-dómur]] to generate the inflection of [[vísdómur]] or [[Björn]] to generate the inflection
		-- of [[Ásbjörn]]).
		local function add_prefix(form)
			if base.scrape_is_suffix then
				form = form:gsub("^%-", "")
			end
			if base.scrape_is_uppercase then
				local first, rest = rmatch(form, "^(.)(.*)$")
				if first then
					form = ulower(first) .. rest
				end
			end
			return prefix .. form
		end

		-- If there's a prefix, add it now to all the overrides in the scraped adjective, as well as 'decllemma'
		-- and all stem overrides.
		if prefix ~= "" then
			-- FIXME, clean up for Serbo-Croatian
			map_all_overrides(inner_base, function(slot, formobj)
				local formval = formobj.form
				-- Not if the override contains # or ##, which expand to the full lemma (possibly minus -r
				-- or -ur); or if the override begins with ~ or ^, indicating the stem or its i-mutated variant;
				-- or if the override is + or - (as may happen with positive/comparative/superlative specs).
				if not formval:find("#") and not formval:find("^[~^]") and formval ~= "+" and formval ~= "-" then
					formobj.form = add_prefix(formval)
				end
			end)
			if inner_base.decllemma then
				inner_base.decllemma = add_prefix(inner_base.decllemma)
			end
			for _, stem in ipairs(export.overridable_stems) do
				-- Only actual stems, not imutval; and not if the stem contains # or ##, which
				-- expand to the full lemma (possibly minus -r or -ur).
				if inner_basedeg[stem] and stem:find("stem$") and not inner_basedeg[stem]:find("#") then
					inner_basedeg[stem] = add_prefix(inner_basedeg[stem])
				end
			end
		end

		local function copy_base_properties(plist)
			for _, prop in ipairs(plist) do
				if base[prop] ~= nil then
					inner_base[prop] = base[prop]
				end
			end
		end
		local function copy_basedeg_properties(plist)
			for _, prop in ipairs(plist) do
				if basedeg[prop] ~= nil then
					inner_basedeg[prop] = basedeg[prop]
				end
			end
		end
		copy_basedeg_properties(export.control_specs)
		copy_basedeg_properties(export.overridable_stems)
		copy_basedeg_properties { "number", "definiteness" }
		copy_base_properties { "decllemma", "q", "header" }
		for _, degspec in ipairs(compsup_degrees) do
			local degfield, desc = unpack(degspec)
			copy_base_properties { degfield .. "spec" }
		end
		inner_base.footnotes = iut.combine_footnotes(inner_base.footnotes, base.footnotes)
		-- Copy addnote specs.
		for _, prop_list in ipairs { "addnote_specs" } do
			for _, prop in ipairs(base[prop_list]) do
				m_table.insertIfNot(inner_base[prop_list], prop)
			end
		end
		-- Now copy remaining user-specified specs into the scraped adjective `base`.
		for _, prop_table in ipairs { "overrides", "props" } do
			for slot, prop in pairs(base[prop_table]) do
				inner_base[prop_table][slot] = prop
			end
		end
		-- Now determine the defaulted number and definiteness (after copying relevant settings
		-- but before the check just below that relies on `inner_base.number` being set).
		set_early_base_defaults(inner_base)
		-- If user specified 'sg', cancel out any pl overrides, otherwise we'll get an error.
		if inner_basedeg.number == "sg" then
			for slot, _ in pairs(inner_base.overrides) do
				if slot:find("p$") then
					inner_base.overrides[slot] = nil
				end
			end
		end
		-- If user specified '-comp' or '-sup', cancel out any comparative/superlative overrides,
		-- otherwise we'll get an error.
		for _, degfield in ipairs { "comp", "sup" } do
			if degree_disabled(base[degfield .. "spec"]) then
				for slot, _ in pairs(inner_base.overrides) do
					if slot:find("^" .. degfield) then
						inner_base.overrides[slot] = nil
					end
				end
			end
		end
			
		return inner_base
	end
end


--[=[
Parse an indicator spec (text consisting of angle brackets and zero or more dot-separated indicators within them).
Return value is an object of the form indicated in the comment above create_base().
]=]
local function parse_indicator_spec(angle_bracket_spec, lemma, pagename)
	if lemma == "" then
		lemma = pagename
	end
	local inside = rmatch(angle_bracket_spec, "^<(.*)>$")
	assert(inside)
	local orig_lemma = lemma
	local orig_lemma_no_links = require(links_module).remove_links(lemma)
	lemma = orig_lemma_no_links
	local base = parse_inside_and_merge(inside, lemma, {})
	base.orig_lemma = orig_lemma
	base.orig_lemma_no_links = orig_lemma_no_links
	return base
end


local function set_defaults_and_check_bad_indicators(base)
	local function check_err(msg)
		error(("Lemma '%s': %s"):format(base.base_degree.lemma, msg))
	end
	-- Set default values.
	if base.props.builtin then
		set_builtin_defaults(base)
		for _, control_spec in ipairs(export.control_specs) do
			if base[control_spec] then
				check_err(("'%s' cannot be specified with built-in terms"):format(control_spec))
			end
		end
		if base.compspec or base.posspec then
			check_err("Comparative indicators cannot be specified with built-in terms")
		end
	end
end


local function set_all_defaults_and_check_bad_indicators(alternant_multiword_spec)
	local is_multiword = #alternant_multiword_spec.alternant_or_word_specs > 1
	iut.map_word_specs(alternant_multiword_spec, function(base)
		set_defaults_and_check_bad_indicators(base)
		for _, global_prop in ipairs { "q", "header" } do
			if base[global_prop] then
				if alternant_multiword_spec[global_prop] == nil then
					alternant_multiword_spec[global_prop] = base[global_prop]
				elseif alternant_multiword_spec[global_prop] ~= base[global_prop] then
					error(("With multiple words or alternants, set '%s' on only one of them or make them all agree"):
						format(global_prop))
				end
			end
		end
		if base.props.pred then
			alternant_multiword_spec.saw_pred = true
		else
			alternant_multiword_spec.saw_non_pred = true
		end
		if base.props.indecl then
			alternant_multiword_spec.saw_indecl = true
		else
			alternant_multiword_spec.saw_non_indecl = true
		end
		if base.props["decl?"] then
			alternant_multiword_spec.saw_unknown_decl = true
		else
			alternant_multiword_spec.saw_non_unknown_decl = true
		end
		if base.compspec then
			for _, compspec in ipairs(base.compspec) do
				if compspec.form == "?" then
					alternant_multiword_spec.saw_unknown_comp = true
					break
				end
			end
		else
			alternant_multiword_spec.saw_non_unknown_comp = true
		end
	end)
end


local function expand_property_sets(degree)
	degree.prop_sets = {{}}

	-- Construct the prop sets from all combinations of control specs, in case any given spec has more than one
	-- possibility.
	for _, control_spec in ipairs(export.control_specs) do
		local specvals = degree[control_spec]
		-- Handle unspecified control specs.
		if not specvals then
			specvals = {false}
		end
		if #specvals == 1 then
			for _, prop_set in ipairs(degree.prop_sets) do
				-- Convert 'false' back to nil
				prop_set[control_spec] = specvals[1] or nil
			end
		else
			local new_prop_sets = {}
			for _, prop_set in ipairs(degree.prop_sets) do
				for _, specval in ipairs(specvals) do
					local new_prop_set = m_table.shallowCopy(prop_set)
					new_prop_set[control_spec] = specval
					table.insert(new_prop_sets, new_prop_set)
				end
			end
			degree.prop_sets = new_prop_sets
		end
	end
end


local function normalize_all_lemmas(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		local lemma = base.orig_lemma_no_links
		local basedeg = base.base_degree
		basedeg.actual_lemma = lemma
		basedeg.lemma = base.decllemma or lemma
		base.source_template = alternant_multiword_spec.source_template
	end)
end


-- Form the comparative given the lemma, definite stem and code specifying how to form the comparative: one of '+' (form
-- by adding -ijī to the definite stem), '^' (form by iotating the definite stem) or '^^' (form by removing -ak/-ek/-ok
-- from the lemma and iotating the rest). Note that we need both the lemma and definite stem because the first two
-- methods build off the definite stem (i.e. the stem formed by removing any fleeting 'a' from the lemma and making any
-- necessary phonological adjustments), while the last method builds directly off the lemma. Cf. [[blizak]] with method
-- '^^' forms comparative blȉžī, whereas the definite stem is blisk- where the voicing of the final root consonant has
-- been lost.
local function form_comparative(lemma, defstem, method)
	local is_cyr = com.is_cyrillic(lemma)
	if method == "^^" then
		local lemma_minus_ak_ek_ok = rmatch(stem, "^(.*)[aeo]k$")
		if not lemma_minus_ak_ek_ok then
			lemma_minus_ak_ek_ok = rmatch(stem, "^(.*)[аео]к$") -- Cyrillic аео
		end
		if not lemma_minus_ak_ek_ok then
			usererr("Can't form comparative using ^^ method because lemma %s doesn't end in -ak, -ek or -ok", lemma)
		end
		defstem = lemma_minus_ak_ek_ok
		method = "^"
	end
	local comp
	if method == "^" then
		-- Don't use ī because we want to maintain the text decomposed.
		comp = com.iotate(defstem) .. (is_cyr and "и" or "i") .. MACRON
	elseif method == "+" then
		comp = defstem .. (is_cyr and "ији" or "iji") .. MACRON
	else
		interr("Unrecognized comparative-forming method %s", method)
	end
	-- Remove the last stress, wherever it is, and replace with comparative stress.
	local origcomp = comp
	local orig_syllables = com.split_syllables(origcomp)
	comp = rsub(comp, "^(.*)" .. com.stress_accent_c, "%1")
	local syllables = com.split_syllables(comp)
	if #syllables < 3 then
		interr("Something wrong with comparative %s; it has %s < 3 components when split into syllables: %s",
			comp, #syllables, syllables)
	end
	local reduce_ije = false
	local rije_syllable = nil
	-- Careful here and below to match and preserve both Latin and Cyrillic, and handle initial uppercase letters.
	-- Essentially what we're doing is this:
	-- (1) If there are two syllables, the first syllable gets short falling; otherwise the third-from-last syllable
	--     gets short rising.
	-- (2) If the syllable receiving the stress is -ije-, it reduces to -je-. We try to avoid false positives by not
	--     reducing syllables that originally had a diacritic of any sort on the i or a short accent on the e.
	-- (3) As a special case of (2), if the syllable receiving the stress is -Crije-, there are two outputs, the first
	--     one -Cre- and the second one -Crje-. Note that this will be wrong is the C is part of a prefix such as
	--     pod-; those need manually specified comparatives.
	-- Finally, remember that when splitting syllables, the last "syllable" is the final consonant cluster and not a
	-- real syllable, so there will be one more split syllable than actual syllables and we have to adjust our counting
	-- appropriately.
	if #syllables == 4 and rfind(syllables[1], "[iIиИ]$") and
		rfind(orig_syllables[2], "[jј][eе][" .. AC .. INVBREVE .. MACRON .. "]?$") then
		reduce_ije = true
		rije_syllable = syllables[2]
		syllables[2] = com.replace_syllable_accent(syllables[2], DOUBLEGR)
	elseif #syllables == 3 then
		syllables[1] = com.replace_syllable_accent(syllables[1], DOUBLEGR)
	else
		if #syllables >= 5 and rfind(syllables[#syllables - 4], "[iIиИ]$") and
			rfind(orig_syllables[#syllables - 3], "[jј][eе][" .. AC .. INVBREVE .. MACRON .. "]?$") then
			reduce_ije = true
			rije_syllable = syllables[#syllables - 4]
		end
		syllables[#syllables - 3] = com.replace_syllable_accent(syllables[#syllables - 3], GR)
	end
	comp = concat(syllables)
	if reduce_ije then
		if rije_syllable and rfind(rije_syllable, com.cons_c .. "[rр][iи]") then
			local version_without_j = rsub(comp, "^(.*[RrРр])[iи][jј]([eе])", "%1%2")
			local version_with_j = rsub(comp, "^(.*[RrРр])([iи])([jј][eе])", "%1%2")
			return {version_without_j, version_with_j}
		else
			return {rsub(comp, "^(.*)[IiИи]([jј][eе])", "%1%2")}
		end
	else
		return {comp}
	end
end


local function form_superlative(complemma)
	local is_cyr = com.is_cyrillic(complemma)
	local syllables = com.split_syllables(complemma)
	if #syllables < 3 then
		interr("Something wrong with comparative %s; it has %s < 3 components when split into syllables: %s",
			complemma, #syllables, syllables)
	end
	local sup_prefix = is_cyr and "на" .. INVBREVE .. "ј" or "na" .. INVBREVE .. "j"
	local maintained_stress = sup_prefix .. complemma
	if #syllables > 3 then
		return {maintained_stress}
	end
	syllables[1] = rsub(syllables[1], stress_accent_c, "")
	local removed_stress = sup_prefix .. concat(syllables)
	-- It appears in short comparatives, the version with only stress on the prefix is more common.
	return {removed_stress, maintained_stress}
end


-- Determine the declension of the positive degree based on the lemma. The declension is set in pos.decl and the stem in
-- pos.stem (which will come from the user if explicitly set, otherwise computed from the lemma).
local function determine_positive_declension(base)
	local stem
	local pos = base.degrees.pos[1]
	if not pos then
		interr("Positive degree doesn't exist: %s", base)
	end
	local defcomp, defsup
	-- Determine declension
	if base.props.builtin then
		interr("This function should not be called with built-in terms: %s", base)
	elseif base.props.indecl then
		pos.decl = "indecl"
	elseif base.props["decl?"] then
		pos.decl = "decl?"
	elseif com.is_cyrillic(pos.lemma) then
		pos.decl = "normal-Cyrl"
	else
		pos.decl = "normal-Latn"
	end
end


-- Insert a comparative degree object, typically based on a user-specified or defaulted spec.
local function insert_degree_object(base, degfield, lemma, footnotes)
	local def_stem
	if lemma == "?" then
		def_stem = "?"
	else
		def_stem = rmatch(lemma, "^(.*)[iи]" .. MACRON .. "$")
		if not def_stem then
			usererr("Explicitly specified comparative '%s' doesn't end in -ī", lemma)
		end
	end
	local degree = {
		lemma = lemma,
		actual_lemma = lemma,
		slot_prefix = degfield .. "_",
		footnotes = footnotes,
		definiteness = "def",
		number = "both",
		prop_sets = {{soft = true, def_stem = {{form = def_stem}}}},
		decl = com.is_cyrillic(lemma) and "normal-Cyrl" or "normal-Latn",
	}
	table.insert(base.degrees[degfield], degree)
end


-- Process the `comp:...` spec given by the user and construct the appropriate property sets, one per generated stem.
-- (There may be more than one stem generated by a given user spec, if the lemma has -rije- in it and/or the user
-- specifies a reducibility spec like '*,-*').
local function process_comp_spec(base, specs)
	local basedeg = base.base_degree
	if base.degrees.comp then
		interr("Attempt to create `degrees.comp` when it already exists: %s", base.degrees)
	end
	base.degrees.comp = {}
	local pos = base.degrees.pos[1]
	for _, spec in ipairs(specs) do
		local forms
		if spec.form == "-" then
			-- Skip "-"; effectively, no forms get inserted, but the fact that `base.degrees.comp` is set indicates
			-- specifically that there is no comparative (vs. an unspecified comparative).
		elseif spec.form == "+" or spec.form == "^" or spec.form == "^^" then
			for _, props in ipairs(pos.prop_sets) do
				for _, def_stem in ipairs(props.def_stem) do
					local comps = form_comparative(pos.lemma, def_stem.form, spec.form)
					for _, comp in ipairs(comps) do
						insert_degree_object(base, "comp", comp,
							iut.combine_footnotes(def_stem.footnotes, spec.footnotes))
					end
				end
			end
		else
			insert_degree_object(base, "comp", spec.form, spec.footnotes)
		end
	end
end


-- Derive the superlative from the comparative. In Serbo-Croatian, this just adds nȃj- to the comparative form,
-- possibly removing the comparative accent.
local function derive_sup_from_comp(base, compspecs)
	if base.degrees.sup then
		interr("Attempt to create `degrees` list for field `sup` when it already exists: %s", base.degrees)
	end
	base.degrees.sup = {}
	for _, compdeg in ipairs(base.degrees.comp) do
		local superlatives
		if compdeg.lemma == "?" then
			superlatives = {"?"}
		else
			superlatives = form_superlative(compdeg.lemma)
		end
		for _, superlative in ipairs(superlatives) do
			insert_degree_object(base, "sup", superlative, compdeg.footnotes)
		end
	end
end


-- Determine the stems and other properties to use for each property set for each `degree` structure. The list of such
-- properties is given in the comment above create_base(), along with the explanation of what a degree structure and
-- property set is and why we have multiple such degree structures (generally, one per base lemma, where there may be
-- multiple such comparative and/or superlative base lemmas) and property sets (generally, one per combination of
-- control specs such as '*,-*').
local function determine_props(base, degree)
	degree.default_reducible = com.determine_default_reducible(degree.lemma)

	local lemma_stem = rmatch(degree.lemma, "^(.*)[iи]" .. MACRON .. "$")
	if lemma_stem then
		if degree.definiteness then
			usererr("Can't specify definiteness for definite-only lemma '%s'", degree.lemma)
		end
		degree.definiteness = "def"
		-- Now determine all the props for each prop set.
		for _, props in ipairs(degree.prop_sets) do
			if props.reducible then
				usererr("Can't specify reducible control spec '*' or '-*' for definite-only lemma '%s'", degree.lemma)
			end
			props.reducible = false
			local def_stem
			if degree.defstem then
				def_stem = degree.defstem
			else
				def_stem = {{form = lemma_stem}}
			end
			props.def_stem = def_stem
		end
		return
	end

	-- Now determine all the props for each prop set.
	for _, props in ipairs(degree.prop_sets) do
		-- Determine reducibility.
		local reducible = degree.default_reducible
		if props.reducible then
			if props.reducible.form == "*" then
				reducible = true
			elseif props.reducible.form == "-*" then
				reducible = false
			else
				interr("Unrecognized value for props.reducible, should be '*' or '-*': %s", props)
			end
			props.reducible_footnotes = props.reducible.footnotes
		end
		props.reducible = reducible

		-- Then do all the stems.
		local normal_lemma = {form = degree.lemma}
		local lemma_stem = {normal_lemma}

		local base_stem = degree.lemma:gsub("o$", "l"):gsub("о$", "л")
		local indef_stem, def_stem, neut_stem
		if props["2tone"] then
			local before, last_accent, after = rmatch(base_stem, "^(.*)(" .. com.stress_accent_c .. ")(.-)$")
			if not before then
				usererr("Lemma '%s' doesn't have any tonal accent in it", degree.lemma)
			end
			-- FIXME: Handle footnotes on 2tone, 3tone, -2tone.
			if props["2tone"].form == "3tone" then
				if last_accent ~= INVBREVE then
					usererr("When '3tone' is specified, lemma '%s' must have a long-falling tone", degree.lemma)
				end
				indef_stem = before .. GR .. after
				def_stem = before .. DOUBLEGR .. after
				neut_stem = {"indef", "def"}
			elseif props["2tone"].form == "2tone" then
				if last_accent == INVBREVE then
					def_stem = base_stem
					indef_stem = before .. AC .. after
					neut_stem = {"indef", "def"}
				elseif last_accent == DOUBLEGR then
					def_stem = base_stem
					indef_stem = before .. GR .. after
					neut_stem = {"indef", "def"}
				elseif last_accent == AC then
					local falling_lemma
					if props.indef_falling_var then
						falling_lemma = {form = before .. INVBREVE .. after, footnotes = {"[rare or regional]"}}
						insert(lemma_stem, falling_lemma)
					end
					indef_stem = base_stem
					if falling_lemma then
						neut_stem = {"indef", falling_lemma}
					else
						neut_stem = {"indef"}
					end
					def_stem = before .. INVBREVE .. after
				elseif last_accent == GR then
					if not rfind(after, com.vowel_c) then
						usererr("When '2tone' is specified, lemma '%s' with short rising accent must have a " ..
							"following syllable to move the tone onto", degree.lemma)
					end
					indef_stem = before .. rsub(after, "^(.-" .. com.vowel_c .. ")", "%1" .. GR)
					neut_stem = {"indef"}
					def_stem = base_stem
				else
					interr("Unrecognized accent %s", last_accent)
				end
			end
		else
			indef_stem = base_stem
			def_stem = base_stem
			neut_stem = {"indef"}
		end

		local function do_reduce(stem)
			local retval = com.reduce(stem)
			if not retval then
				usererr("Unable to reduce (i.e. remove fleeting ''a'' from) stem '%s'", stem)
			end
			return retval
		end
		props.lemma_stem = iut.convert_to_general_list_form(lemma_stem)
		if degree.indefstem then
			indef_stem = degree.indefstem
		else
			indef_stem = iut.convert_to_general_list_form(indef_stem)
			if props.reducible then
				indef_stem = iut.flatmap_forms(indef_stem, do_reduce)
			end
		end
		props.indef_stem = indef_stem
		if degree.defstem then
			def_stem = degree.defstem
		else
			def_stem = iut.convert_to_general_list_form(def_stem)
			if props.reducible then
				def_stem = iut.flatmap_forms(def_stem, do_reduce)
			end
		end
		props.def_stem = def_stem
		for _, ns in ipairs(neut_stem) do
			if ns == "indef" then
				iut.insert_forms(props, "neut_stem", indef_stem)
			elseif ns == "def" then
				iut.insert_forms(props, "neut_stem", def_stem)
			else
				iut.insert_form(props, "neut_stem", ns)
			end
		end
	end
end


local function detect_indicator_spec(alternant_multiword_spec, base)
	local basedeg = base.base_degree

	if base.props.builtin then
		expand_property_sets(basedeg)
		basedeg.stem = ""
		basedeg.decl = "builtin"
	else
		if base.base_degfield == "sup" then
			interr("base_degfield should not be 'sup' in Serbo-Croatian: %s", base)
		end
		expand_property_sets(basedeg)
		if base.base_degfield == "pos" then
			determine_positive_declension(base)
			determine_props(base, basedeg)
			-- Next process the comparative, if specified (or defaulted because a superlative was specified).
			if base.compspec then
				process_comp_spec(base, base.compspec)
				derive_sup_from_comp(base)
			end
		else
			error("FIXME: Write this branch")
		end
	end

	-- Make sure all alternants agree in having a positive, comparative and/or superlative.
	for _, degspec in ipairs(compsup_degrees) do
		local degfield, desc = unpack(degspec)
		local hasprop = "has" .. degfield
		local has_deg = base.degrees[degfield] and (base.degrees[degfield][1] and "has" or "hasnot") or "unspec"
		if alternant_multiword_spec[hasprop] == nil then
			alternant_multiword_spec[hasprop] = has_deg
		elseif alternant_multiword_spec[hasprop] ~= has_deg then
			error(("All alternants must agree in whether they have a %s, but saw one alternant with value '%s' " ..
				"and another with value '%s'"):format(alternant_multiword_spec[hasprop], has_deg))
		end
	end

	-- Make sure all alternants agree in 'number' and 'definiteness' for each degree if specified.
	for _, degspec in ipairs(compsup_degrees) do
		local degfield, desc = unpack(degspec)
		if base.degrees[degfield] then
			for _, degree in ipairs(base.degrees[degfield]) do
				for _, prop in ipairs { "number", "definiteness" } do
					local val = degree[prop] or false
					if alternant_multiword_spec[prop][degfield] == nil then
						alternant_multiword_spec[prop][degfield] = val
					elseif alternant_multiword_spec[prop][degfield] ~= val then
						error(("All %s alternants must agree in the value of '%s', if specified"):format(
							desc, prop))
					end
				end
			end
		end
	end

	-- Make sure all alternants agree in various properties.
	for _, prop in ipairs { "decl?", "indecl", "builtin" } do
		local val = not not base.props[prop]
		if alternant_multiword_spec[prop] == nil then
			alternant_multiword_spec[prop] = val
		elseif alternant_multiword_spec[prop] ~= val then
			error(("If one alternant specifies '%s', all must"):format(prop))
		end
	end
end


local function detect_all_indicator_specs(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		detect_indicator_spec(alternant_multiword_spec, base)
	end)
end


local function decline_adjective(base)
	for degfield, degree_list in pairs(base.degrees) do
		for _, degree in ipairs(degree_list) do
			for _, props in ipairs(degree.prop_sets) do
				if not decls[degree.decl] then
					interr("Unrecognized declension type '%s': %s", degree.decl, degree)
				end
				decls[degree.decl](base, degree, props)
			end
		end
	end
	handle_derived_slots_and_overrides(base)
	process_addnote_specs(base)
end


-- Compute the categories to add the adjective to, as well as the annotation to display in the declension title bar. We
-- combine the code to do these functions as both categories and title bar contain similar information.
local function compute_categories_and_annotation(alternant_multiword_spec)
	local all_cats = {}
	local function inscat(cattype)
		-- Don't insert categories with built-in determiners/pronouns; all are irregular in various ways.
		if not alternant_multiword_spec.builtin then
			m_table.insertIfNot(all_cats, "Serbo-Croatian " .. cattype)
		end
	end
	local plpos = require(en_utilities_module).pluralize(alternant_multiword_spec.pos)
	if alternant_multiword_spec.saw_indecl and not alternant_multiword_spec.saw_non_indecl then
		inscat("indeclinable " .. plpos)
	end
	if alternant_multiword_spec.saw_unknown_decl and not alternant_multiword_spec.saw_non_unknown_decl then
		inscat(plpos .. " with unknown declension")
	end
	local annotation
	local annparts = {}
	local irregs = {}
	local stemspecs = {}
	local scrape_chains = {}
	local iotated_comparison = false
	local function insann(txt, joiner)
		if joiner and annparts[1] then
			table.insert(annparts, joiner)
		end
		table.insert(annparts, txt)
	end

	local function do_word_spec(base)
		-- User-specified 'decllemma:' indicates irregular stem.
		if base.decllemma then
			m_table.insertIfNot(irregs, "irreg-stem")
			if plpos == "adjectives" then
				inscat("adjectives with irregular stem")
			end
		end
		for _, props in ipairs(base.base_degree.prop_sets) do
			m_table.insertIfNot(stemspecs, props.stem)
		end
	end

	iut.map_word_specs(alternant_multiword_spec, function(base)
		do_word_spec(base)
		if base.scrape_chain[1] then
			local linked_scrape_chain = {}
			for _, element in ipairs(base.scrape_chain) do
				table.insert(linked_scrape_chain, ("[[%s]]"):format(element))
			end
			m_table.insertIfNot(scrape_chains, table.concat(linked_scrape_chain, " -> "))
		end
		if alternant_multiword_spec.haspos == "has" and base.compspec then
			for _, formobj in ipairs(base.compspec) do
				if formobj.form:find("^%^") then
					iotated_comparison = true
					break
				end
			end
		end
	end)
	-- NOTE: Fields `haspos`, `hascomp` and `hassup` are set by generic code that iterates over degree fields; look
	-- for `"has" .. degfield`.
	if alternant_multiword_spec.haspos == "has" then
		if alternant_multiword_spec.number.pos == "sg" or alternant_multiword_spec.number.pos == "pl" then
			-- not "both" or "none"
			insann(alternant_multiword_spec.number.pos .. "-only", " ")
		end
		if alternant_multiword_spec.definiteness.pos == "indef" or
			alternant_multiword_spec.definiteness.pos == "def" then
			-- not "bothdefs" or "none"
			insann(alternant_multiword_spec.definiteness.pos .. "-only", " ")
		end
		if plpos == "adjectives" and not alternant_multiword_spec.saw_unknown_comp then
			if alternant_multiword_spec.hascomp == "has" then
				inscat("comparable adjectives")
			elseif alternant_multiword_spec.hascomp == "hasnot" then
				inscat("uncomparable adjectives")
			end
		end
		if alternant_multiword_spec.numcomp > 1 then
			inscat(plpos .. " with multiple comparatives")
		end
	elseif alternant_multiword_spec.hascomp == "has" then
		insann("comparative-only", " ")
		if plpos == "adjectives" then
			inscat("comparative-only adjectives")
		end
	else
		interr("Superlative-only adjectives should not occur in Serbo-Croatian")
	end
	if #irregs > 0 then
		insann(table.concat(irregs, " // "), " ")
	end
	if iotated_comparison then
		insann("iotated-comp", " ")
		inscat(plpos .. " with iotated comparative")
	end
	if #scrape_chains > 0 then
		insann(("based on %s"):format(m_table.serialCommaJoin(scrape_chains)), ", ")
		inscat(plpos .. " declined using scraped base declensions")
	end

	-- FIXME: We should create categories for 2tone/3tone adjectives and reducible adjectives.
	alternant_multiword_spec.annotation = table.concat(annparts)
	if #stemspecs > 1 then
		inscat(plpos .. " with multiple stems")
	end
	if alternant_multiword_spec.saw_unknown_comp then
		inscat(plpos .. " with unknown comparative status")
	end
	alternant_multiword_spec.categories = all_cats
end


local function show_forms(alternant_multiword_spec)
	local lemmas = {}
	for _, slot in ipairs(potential_lemma_slots) do
		if alternant_multiword_spec.forms[slot] then
			for _, formobj in ipairs(alternant_multiword_spec.forms[slot]) do
				table.insert(lemmas, formobj)
			end
			break
		end
	end
	local props = {
		lemmas = lemmas,
		lang = lang,
	}
	for _, degspec in ipairs(compsup_degrees) do
		local degfield, desc = unpack(degspec)
		if alternant_multiword_spec["has" .. degfield] == "has" then
			props.slot_list = get_slot_list(alternant_multiword_spec, degfield)
			iut.show_forms(alternant_multiword_spec.forms, props)
			alternant_multiword_spec["footnote_" .. degfield] = alternant_multiword_spec.forms.footnote
		end
	end
	-- This isn't strictly necessary but ensures that all slots including the *_linked ones get converted to strings.
	props.slot_list = adjective_slot_list_linked_slots
	iut.show_forms(alternant_multiword_spec.forms, props)
end


local function make_table(alternant_multiword_spec)
	local forms = alternant_multiword_spec.forms

	local function template_prelude()
		return mw.getCurrentFrame():expandTemplate{
			title = 'inflection-table-top',
			args = {
				title = '{title}{annotation}',
				palette = 'blue',
				tall = 'yes',
			}
		}
	end

	local function template_postlude()
		return mw.getCurrentFrame():expandTemplate{
			title = 'inflection-table-bottom',
			args = {
				notes = '{footnote}'
			}
		}
	end

	local table_spec_parts = {
		full_sg = [=[
! class="outer" colspan="2"|singular
! class="outer" | masculine
! class="outer" | feminine
! class="outer" | neuter
|-
! colspan="2"|nominative
| {PREF_nom_m}
| {PREF_nom_f}
| {PREF_nom_n}
|-
! colspan="2"|genitive
| {PREF_gen_m}
| {PREF_gen_f}
| {PREF_gen_n}
|-
! colspan="2"|dative
| {PREF_dat_m}
| {PREF_dat_f}
| {PREF_dat_n}
|-
! rowspan="2"|accusative
! class="secondary" | <small>inanimate</small>
| {PREF_acc_m_in}
| rowspan="2"|{PREF_acc_f}
| rowspan="2"|{PREF_acc_n}
|-
! class="secondary" | <small>animate</small>
| {PREF_acc_m_an}
|-
! colspan="2"|vocative
| {PREF_voc_m}
| {PREF_voc_f}
| {PREF_voc_n}
|-
! colspan="2"|locative
| {PREF_loc_m}
| {PREF_loc_f}
| {PREF_loc_n}
|-
! colspan="2"|instrumental
| {PREF_ins_m}
| {PREF_ins_f}
| {PREF_ins_n}
]=],
		sg_pl_sep = [=[
|-
| class="separator" colspan="999" |
|-
]=],
		full_pl = [=[
! class="outer" colspan="2"|plural
! class="outer" | masculine
! class="outer" | feminine
! class="outer" | neuter
|-
! colspan="2"|nominative
| {PREF_nom_mp}
| {PREF_nom_fp}
| {PREF_nom_np}
|-
! colspan="2"|genitive
| colspan="3"|{PREF_gen_p}
|-
! colspan="2"|dative
| colspan="3"|{PREF_dat_p}
|-
! colspan="2"|accusative
| {PREF_acc_mp}
| {PREF_acc_fp}
| {PREF_acc_np}
|-
! colspan="2"|vocative
| {PREF_voc_mp}
| {PREF_voc_fp}
| {PREF_voc_np}
|-
! colspan="2"|locative
| colspan="3"|{PREF_loc_p}
|-
! colspan="2"|instrumental
| colspan="3"|{PREF_ins_p}
]=],
}

	local function construct_table(slot_prefix, inside)
		local parts = {}
		local function ins(txt)
			table.insert(parts, txt)
		end
		ins(template_prelude())
		inside(ins)
		ins(template_postlude())
		return (table.concat(parts):gsub("PREF", slot_prefix))
	end

	local function get_table_spec_one_number(slot_prefix, number)
		return construct_table(slot_prefix, function(ins)
			ins(table_spec_parts["full_" .. number])
		end)
	end

	local function get_table_spec_all_number(slot_prefix)
		return construct_table(slot_prefix, function(ins)
			ins(table_spec_parts.full_sg)
			ins(table_spec_parts.sg_pl_sep)
			ins(table_spec_parts.full_pl)
		end)
	end

	local function get_ital_lemma(lemma, script)
		return ('<i lang="sh" class="%s">%s</i>'):format(script, lemma)
	end

	local annotation = alternant_multiword_spec.annotation
	if annotation == "" then
		forms.annotation = ""
	else
		forms.annotation = " (<span style=\"font-size: smaller;\">" .. annotation .. "</span>)"
	end

	-- Format the per-degree tables.
	local computed_tables = {}
	for _, degspec in ipairs(compsup_degrees) do
		local degfield, desc = unpack(degspec)
		local hasprop = "has" .. degfield
		local function insert_table(slot_prefix, desc)
			local table_spec = alternant_multiword_spec.number[degfield] == "both" and
				get_table_spec_all_number(slot_prefix) or
				get_table_spec_one_number(slot_prefix, alternant_multiword_spec.number[degfield])
			forms.title = ("%s forms of %s"):format(desc, get_ital_lemma(forms.lemma, alternant_multiword_spec.script))
			forms.footnote = alternant_multiword_spec["footnote_" .. degfield]
			computed_table = m_string_utilities.format(table_spec, forms)
			table.insert(computed_tables, computed_table)
		end
		if alternant_multiword_spec[hasprop] == "has" then
			if degfield == "pos" then
				local def = alternant_multiword_spec.definiteness[degfield]
				if def == "bothdefs" or def == "indef" then
					insert_table("indef", "Positive indefinite")
				end
				if def == "bothdefs" or def == "def" then
					insert_table("def", "Positive definite")
				end
			else
				insert_table(degfield, desc)
			end
		end
	end

	-- Paste them together.
	return require("Module:TemplateStyles")("Module:sh-adjective/style.css") .. table.concat(computed_tables)
end

-- Externally callable function to parse and decline an adjective given user-specified arguments and the argument spec
-- `argspec` (specified because the user may give multiple such specs). Return value is ALTERNANT_MULTIWORD_SPEC, an
-- object where the declined forms are in `ALTERNANT_MULTIWORD_SPEC.forms` for each slot. If there are no values for a
-- slot, the slot key will be missing. The value for a given slot is a list of objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(args, argspec, source_template)
	local from_headword = source_template == "sh-adj"
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename
	local parse_props = {
		parse_indicator_spec = function(angle_bracket_spec, lemma)
			return parse_indicator_spec(angle_bracket_spec, lemma, pagename)
		end,
		angle_brackets_omittable = true,
		allow_blank_lemma = true,
	}
	local alternant_multiword_spec = iut.parse_inflected_text(argspec, parse_props)
	alternant_multiword_spec.title = args.title
	alternant_multiword_spec.pos = args.pos or "adjective"
	alternant_multiword_spec.source_template = source_template
	alternant_multiword_spec.number = {}
	alternant_multiword_spec.definiteness = {}
	alternant_multiword_spec.script = com.is_cyrillic(pagename) and "Cyrl" or "Latn"

	local scrape_errors = {}
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.scrape_error then
			table.insert(scrape_errors, base.scrape_error)
		end
	end)

	if scrape_errors[1] then
		alternant_multiword_spec.scrape_errors = scrape_errors
	else
		normalize_all_lemmas(alternant_multiword_spec)
		set_all_defaults_and_check_bad_indicators(alternant_multiword_spec)
		detect_all_indicator_specs(alternant_multiword_spec)
		local inflect_props = {
			skip_slot = function(slot)
				local degfield = slot_to_degfield(slot)
				return skip_slot(alternant_multiword_spec.number[degfield],
					alternant_multiword_spec.definiteness[degfield], slot)
			end,
			slot_list = adjective_slot_list,
			inflect_word_spec = decline_adjective,
		}
		iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)
		local forms = alternant_multiword_spec.forms
		alternant_multiword_spec.numcomp = forms.comp_nom_m and #forms.comp_nom_m or 0
		alternant_multiword_spec.numsup = forms.sup_nom_m and #forms.sup_nom_m or 0
		compute_categories_and_annotation(alternant_multiword_spec)
	end
	if args.json then
		return require("Module:JSON").toJSON(alternant_multiword_spec)
	end
	return alternant_multiword_spec
end


-- Entry point for {{sh-adecl}}. Template-callable function to parse and decline an adjective given
-- user-specified arguments and generate a displayable table of the declined forms.
function export.show(frame)
	local parent_args = frame:getParent().args
	local params = {
		[1] = {required = true, list = true, default = "dȍbar<2tone.comp:bȍljī>"},
		-- deriv = {list = true}, FIXME: what is this used for?
		id = {},
		pos = {},
		title = {},
 		pagename = {},
		json = {type = "boolean"},
	}
	local args = require(parameters_module).process(parent_args, params)
	local alternant_multiword_specs = {}
	for i, argspec in ipairs(args[1]) do
		alternant_multiword_specs[i] = export.do_generate_forms(args, argspec, "sh-adecl")
	end
	if args.json then
		-- JSON return value
		if #args[1] == 1 then
			return alternant_multiword_specs[1]
		else
			return alternant_multiword_specs
		end
	end
	local parts = {}
	local function ins(txt)
		table.insert(parts, txt)
	end
	for _, alternant_multiword_spec in ipairs(alternant_multiword_specs) do
		if not alternant_multiword_spec.scrape_errors then
			show_forms(alternant_multiword_spec)
		end
		if alternant_multiword_spec.header then
			ins(("'''%s:'''\n"):format(alternant_multiword_spec.header))
		end
		if alternant_multiword_spec.q then
			ins(("''%s''\n"):format(alternant_multiword_spec.q))
		end
		local categories
		if alternant_multiword_spec.scrape_errors then
			local errmsgs = {}
			for _, scrape_error in ipairs(alternant_multiword_spec.scrape_errors) do
				table.insert(errmsgs, '<span style="font-weight: bold; color: #CC2200;">' .. scrape_error .. "</span>")
			end
			-- Surround the messages with a <div> because the table normally does that, and we want to ensure
			-- similar formatting with respect to newlines.
			ins("<div>" .. table.concat(errmsgs, "<br />") .. "</div>")
			categories = {"Serbo-Croatian scraping errors in Template:sh-adecl"}
		else
			ins(make_table(alternant_multiword_spec))
			categories = alternant_multiword_spec.categories
		end
		ins(require("Module:utilities").format_categories(categories, lang, nil, nil, force_cat))
	end
	return table.concat(parts)
end


return export
