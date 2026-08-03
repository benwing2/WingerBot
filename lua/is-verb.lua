local export = {}

--[=[
Authorship: Ben Wing <benwing2>
]=]

local lang = require("Module:languages").getByCode("is")

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")
local m_links = require("Module:links")
local m_string_utilities = require("Module:string utilities")
local iut = require("Module:inflection utilities")
local put = require("Module:parse utilities")
local m_para = require("Module:parameters")
local com = require("Module:is-common")
local m_inflection_table = require("Module:inflection-table")
local m_is_adjective = require_when_needed("Module:is-adjective")
local en_utilities_module = "Module:en-utilities"

local u = m_string_utilities.char
local usplit = m_string_utilities.split
local ufind = m_string_utilities.find
local umatch = m_string_utilities.match
local ugsub = m_string_utilities.gsub
local ulen = m_string_utilities.len
local usub = m_string_utilities.sub
local uupper = m_string_utilities.upper
local ulower = m_string_utilities.lower

local insert = table.insert
local concat = table.concat
local dump = mw.dumpObject

local force_cat = false -- set to true to make categories appear in non-mainspace pages, for testing

local SUB_ESCAPED_PERIOD = u(0xFFF0)
local SUB_ESCAPED_COMMA = u(0xFFF1)

-- version of ugsub() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = ugsub(term, foo, bar)
	return retval
end


-- version of ugsub() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = ugsub(term, foo, bar)
	return retval, nsubs > 0
end


local function track(track_id)
	require("Module:debug/track")("is-verb/" .. track_id)
	return true
end


-- Issue an error message with any Wikicode escaped so it displays literally. `error_depth` indicates how many error
-- functions are stacked above this function. Non-error-handling code should either pass in an error depth of 0 or omit
-- the parameter and let it be defaulted to 0. Error-handling functions that call another error-handling function
-- (including the built-in error()) should pass `(error_depth or 0) + 1` as the second parameter, defaulting the
-- passed-in error depth to 0 and adding 1 for the error function itself.
local function escaped_error(msg, error_depth)
	error(put.escape_wikicode(msg), (error_depth or 0) + 1)
end

local overridable_stems = {
	"stem",
	"vstem",
	"plstem",
	"plvstem",
	"imutval",
}

local overridable_stem_set = m_table.listToSet(overridable_stems)

local number_code_to_desc = {
	sg = "singular",
	pl = "plural",
	both = "both numbers",
	none = nil,
}

local all_persons_numbers = {
	{"1s", "1|s"},
	{"2s", "2|s"},
	{"3s", "3|s"},
	{"1p", "1|p"},
	{"2p", "2|p"},
	{"3p", "3|p"},
}

local verb_slots = {}

local function add_slot(slot, tag, voice)
	if voice == "mid" then
		slot = "mid_" .. slot
	end
	tag = tag:gsub("VOICE", voice)
	insert(verb_slots, {slot, tag})
end

-- Add slots for a given tense/mood combination.
-- `slot_prefix` is the prefix of the slot, specifying the tense/mood.
-- `tag_suffix` is the set of inflection tags to add after the person/number accelerator tags.
--   It should have `VOICE` in it where the voice is to be substituted.
-- `voice` is "act" or "mid".
local function add_tense_mood_slots(slot_prefix, tag_suffix, voice)
	for _, persnum in ipairs(all_persons_numbers) do
		local persnum_slot, persnum_tag = unpack(persnum)
		add_slot(slot_prefix .. persnum_slot, persnum_tag .. "|" .. tag_suffix, voice)
	end
	add_slot("qform_" .. slot_prefix .. "2s", "2|s|" .. tag_suffix .. "|qform", voice)
	add_slot("qform_" .. slot_prefix .. "2p", "2|p|" .. tag_suffix .. "|qform", voice)
end

for _, voice in ipairs {"act", "mid"} do
	add_tense_mood_slots("pres", "pres|VOICE|ind", voice)
	add_tense_mood_slots("pressub", "pres|VOICE|sub", voice)
	add_tense_mood_slots("past", "past|VOICE|ind", voice)
	add_tense_mood_slots("pastsub", "past|VOICE|sub", voice)
	add_slot("imp2s", "2|s|VOICE|imp", voice)
	add_slot("imp2sj", "2|s|VOICE|joinedimp", voice)
	add_slot("imp2p", "2|p|VOICE|imp", voice)
	add_slot("inf", "VOICE|inf", voice)
	add_slot("inf_linked", "-", voice)
	add_slot("pp", "VOICE|past|part", voice)
	add_slot("sup", "VOICE|sup", voice)
end
-- There used to be a middle present participle but it is now completely obsolete.
add_slot("presp", "pres|part", "act")
-- The past infinitive only occurs for a few verbs and only in the active voice.
add_slot("pastinf", "past|VOICE|inf", "act")

local clipped_imp_2s_footnote = "Mostly found in older literature, biblical texts, or high-register rhetoric."
local suffixed_imp_2p_footnote = "Spoken form; proscribed in writing, where the unappended plural form (optionally followed by the full pronoun) is preferred."

--[=[
Create an empty `base` object for holding the result of parsing and later the generated forms. The object is of the form

{
  -- Original lemma as directly given by the user or taken from the pagename.
  orig_lemma = "ORIGINAL-LEMMA",
  -- Same as `orig_lemma` but with links removed.
  orig_lemma_no_links = "ORIGINAL-LEMMA-NO-LINKS",
  -- Originally the same as `orig_lemma_no_links`, but if the term is a plural-only verb, this will be the corresponding
  -- singular lemma, and if the term is an adjective form, this will be the corresponding lemma (strong nominative
  -- masculine singular form).
  lemma = "LEMMA",
  -- Generated per-slot forms. After calling `inflect_multiword_or_alternant_multiword_spec`, the forms will be filled
  -- in with the format as given below, where the value of each slot is a form object. After calling `show_forms`, the
  -- value of each slot will be a formatted string listing all of the forms of that slot, or "—" if there are none.
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
  -- Specs for control groups as specified by the user. CONTROL_GROUP is as below and CONTROL_SPEC is
  -- {form = "FORM", footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...}, defaulted = BOOLEAN}, where FORM is as specified
  -- by the user (e.g. "uUmut", "-unumut") or set as a default by the code (in which case `defaulted` will be set to
  -- true for control groups "umut" and "unumut"). The control groups are as follows:
  -- * umut (u-mutation);
  -- * imut (i-mutation);
  -- * unumut (reverse u-mutation);
  -- * unimut (reverse i-mutation);
  -- * con (stem contraction before vowel-initial endings);
  -- * defcon (stem contraction before vowel-initial definite clitics when the ending itself is null);
  -- * j (j-infix before vowel-initial endings not beginning with an i);
  -- * v (v-infix before vowel-initial endings).
  CONTROL_GROUP = {
	CONTROL_SPEC, CONTROL_SPEC, ...
  },
  -- Property sets containing computed stems, one per each combination of control group values. Described in more detail
  -- below.
  prop_sets = {
	PROPSET, -- see below
	...,
  },
  -- Per-slot overrides, which override forms generated by the auto-determined or specified declension pattern. SLOT is
  -- the actual name of the slot, normally without the definiteness prefix, such as "dat_s" (NOT the slot name as
  -- specified by the user, which would be just "dat" for "dat_s") and OVERRIDE is of the form
  -- {indef = {FORMOBJ, FORMOBJ, ...}, def = nil or false or {FORMOBJ, FORMOBJ, ...}}, where FORMOBJ is of the form
  -- {form = FORM, footnotes = FOOTNOTES} as in the `forms` table ("-" means to suppress the slot entirely and is
  -- signaled by "--" as the user-specified form value; normally FORM values are endings, but a value preceded by !
  -- means it's a full form rather than an ending; in such forms you can use # to indicate the lemma and ## to indicate
  -- the lemma minus -ur or -r, as with stems); `indef` means the override(s) of the indefinite variant of the slot and
  -- is specified by the user before a slash; `def` means the override(s) of the definite variant of the slot and come
  -- after a slash, and `false` for either means that the user left the value before or after the slash completely
  -- blank, meaning not to override the indefinite or definite forms. Sometimes the slot itself has def_ in it; this
  -- happens when the user preceded the slot spec by 'def', e.g. 'defdat' or 'defgenpl'.
  overrides = {
	SLOT = OVERRIDE,
	SLOT = OVERRIDE,
	...
  },
  -- Overrides for the genitive singular, specified after a comma after the gender. OVERRIDE is in the same format as
  -- above.
  gens = nil or OVERRIDE,
  -- Overrides for the nominative and accusative plural, specified after a comma after the gender. OVERRIDE is in the
  -- same format as above. The actual values given are for the nominative plural, and the accusative plural is derived
  -- automatically from these values.
  pls = nil or OVERRIDE,
  -- "sg", "pl", "both" or "none" (for certain pronouns); may be missing and if so is defaulted
  number = "NUMBER",
  -- "m", "f", "n" or "none" (for certain pronouns); always specified by the user
  gender = "GENDER",
  -- "def", "indef", "bothdef" or "none" (for pronouns); may be missing and if so is defaulted
  definiteness = "DEFINITENESS",
  -- decline like the specified lemma
  decllemma = nil or "DECLLEMMA",
  -- decline like the specified gender
  declgender = nil or "DECLGENDER",
  -- decline like the specified number
  declnumber = nil or "DECLNUMBER",
  -- override the stem; may have # (= lemma) or ## (= lemma minus -ur or -r)
  stem = nil or "STEM",
  -- override the stem used before vowel-initial endings; same format as `stem`
  vstem = nil or "STEM",
  -- override the plural stem; same format as `stem`
  plstem = nil or "STEM",
  -- override the plural stem used before vowel-initial endings; same format as `stem`
  plvstem = nil or "STEM",
  -- decline like an adjective; will be present if the user gave a spec starting with 'adj'
  adjspec = {
	-- User explicitly specified the lemma using a colon + lemma.
	lemma = nil or LEMMA
	-- User gave a one-part or two-part substitution spec such as 'tvöfalt<adj/dur>' or 'ryðfrítt<adj/tt/r>'.
	subspec = nil or {
	  from = nil or FROM,
	  to = TO,
	},
  },
  -- misc Boolean properties:
  -- * "builtin" (for built-in terms such as [[vera]] "to be");
  -- * "conj?" (conjugation is unknown);
  -- * "impers" (verb is impersonal with only third-singular forms);
  -- * "-impers" (verb is not impersonal, used in middle conjugations when the active is impersonal but not the middle);
  -- * "-imp" (verb has no imperative);
  -- * "+imp" (verb does have an imperative, used in middle conjugations);
  -- * "-qform" (verb has no question forms);
  -- * "+qform" (verb does have question forms, used in middle conjugations when the active has no question forms but
                 the middle does);
  -- * "-presp" (verb has no present participle);
  props = {
	PROP = true,
	PROP = true,
	...
  },
  -- Alternant-level footnotes, specified using `.[footnote]`, i.e. a footnote by itself.
  footnotes = nil or {"FOOTNOTE", "FOOTNOTE", ...},
  -- ADDNOTE_SPEC is {slot_specs = {"SPEC", "SPEC", ...}, footnotes = {"FOOTNOTE", "FOOTNOTE", ...}}; SPEC is a Lua
  -- pattern matching slots (anchored on both sides) and FOOTNOTE is a footnote to add to those slots.
  addnote_specs = {
	ADDNOTE_SPEC, ADDNOTE_SPEC, ...
  },
}

There is one PROPSET (property set) for each combination of control specs; in the lower limit, there is a single
property set. There may be more than one property set e.g. if the user specified 'umut,uUmut' or '-j,j' or '-imut,imut'
or some combination of these. The properties in a given property set specify the values themselves of each control
group, as well as stems (derived from the control specs) that are used to construct the various forms and populate the
slots in `forms` with these values. The information found in the property sets cannot be stored in `base` because it
depends on a particular combination of control specs, of which there may be more than one (see above). The
conjugate_verb() function iterates over all property sets and calls the appropriate declension function on each one in
turn, which adds forms to each slot in `base.forms`, automatically deduplicating.

The properties in each property set are:
* Control specs: These are copied from the control specs at the base level. The key is one of the possible control
  groups ("umut", "imut", "con", etc.), but the value is a single form object {form = "FORM", footnotes = nil or
  {"FOOTNOTE", "FOOTNOTE", ...}}. These are set by expand_property_sets().
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
** `imut_nonvstem`: The stem used when the ending is null or starts with a consonant and i-mutation is in effect.
   If i-mutation is in effect, this should always be specified (otherwise an internal error will occur); hence it has
   no default. Note that i-mutation is only in effect when either (a) `imut` or `unimut` was specified; (b) a
   user-specified override is given that begins with a single ^ (indicating i-mutation); or (c) a declension type is
   in effect that contains default endings beginning with a single ^ (examples are `f-long-vowel` for lemmas in -ó
   and `f-long-umlaut-vowel-r`). Note also that this will be present even if `nonvstem` is missing, because there is
   no generic `imut_stem`.
** `vstem`: The stem used when the ending starts with a vowel, unless overridden by a more specific variant. Defaults
   to `stem`. Will be specified when contraction is in effect or the user specified `vstem:...`.
** `umut_vstem`: The stem(s) used when the ending starts with a vowel and u-mutation is in effect. Defaults to
   `vstem`. Note that u-mutation applies to the contracted stem if both u-mutation and contraction are in effect.
   Will only be present when the result of u-mutation is different from the stem to which u-mutation is applied.
   (In this case, it will be present even if `vstem` is missing, because there is no generic `umut_stem`.)
** `imut_vstem`: The stem(s) used when the ending starts with a vowel and i-mutation is in effect. If i-mutation is
   in effect, this should always be specified (otherwise an internal error will occur); hence it has no default. Note
   that i-mutation applies to the contracted stem if both i-mutation and contraction are in effect. See
   `imut_nonvstem` for comments on when this stem will be present.
** `null_defvstem`: The stem(s) used when the ending is null and is followed by a definite ending that begins with a
   vowel, unless overridden by a more specific variant. Defaults to `nonvstem`. This is normally set when `defcon`
   is specified.
** `umut_null_defvstem`: The stem(s) used when the ending is null and is followed by a definite ending that begins
   with a vowel, and u-mutation is in effect. Defaults to `null_defvstem`. This is normally set when `defcon` is
   specified and u-mutation is needed, as in the nom/acc pl of neuter [[mastur]] "mast". Will only be present when
   the result of u-mutation is different from the stem to which u-mutation is applied.
** `pl_stem`: The basic stem used for plural inflections. Only set when `plstem:...` is specified by the user. If
   this is set, the alternative plural-specific stem variants are used, where each of the above stems has a
   plural-specific counterpart, and the identical algorithms and fallbacks are used to determine the correct stem.
** `pl_nonvstem`, `pl_umut_nonvstem`, `pl_imut_nonvstem`, `pl_vstem`, `pl_umut_vstem`, `pl_imut_vstem`,
   `pl_null_defvstem`, `pl_umut_null_defvstem`: Plural-specific counterparts of the above stems. See the comment
   under `pl_stem` for when these are used.
* Other properties:
** `jinfix`: If present, either "" or "j". Inserted between the stem and ending when the ending begins with a vowel
   other than "i". Note that j-infixes don't apply to ending overrides.
** `jinfix_footnotes`: Footnotes to attach to forms where j-infixing is possible (even if it's not present).
** `vinfix`: If present, either "" or "v". Inserted between the stem and ending when the ending begins with a vowel.
   Note that v-infixes don't apply to ending overrides. `jinfix` and `vinfix` cannot both be specified.
** `vinfix_footnotes`: Footnotes to attach to forms where v-infixing is possible (even if it's not present).
** `imut`: If specified (i.e. not nil), either true or false. If specified, there may be associated footnotes in
   `imut_footnotes`. If true, i-mutation and associated footnotes are in effect before endings starting with "i". If
   false, associated footnotes still apply before endings starting with "i". Note that i-mutation is also in effect
   if the ending has ^ prepended, but the associated footnotes don't apply here.
** `imut_footnotes`: See `imut`.
** `unumut`: If specified (i.e. not nil), the type of un-u-mutation requested (either "unumut" or a variant, or the
   negation of the same using "-unumut" or a variant for no un-u-mutation; "unumut" and variants differ in which
   slots any associated footnote are placed). If specified, there may be associated footnotes in `unumut_footnotes`.
   If "unumut" itself, u-mutation is in effect *except* before an ending that starts with an "a" or "i" (unless
   i-mutation is in effect, which takes precedence). If any other variant, the rules are different: when masculine,
   u-mutation is in effect *except* in the gen sg and pl (examples are [[söfnuður]] "congregation" and [[mánuður]]
   "month"); when feminine, u-mutation is in effect except in the nom/acc/gen pl (examples are [[verslun]] "trade,
   business; store, shop" and [[kvörtun]] "complaint"). When u-mutation is *not* in effect, and i-mutation is also
   not in effect, the associated footnotes in `unumut_footnotes` apply. If `unumut` is "-unumut" or a variant, there
   is no un-u-mutation (i.e. there are no special u-mutated stems, and the basic stems, which typically have
   u-mutation built into them, apply throughout), but the associated footnotes in `unumut_footnotes` still apply in
   the same circumstances where they would apply if `unumut` were the non-negated counterpart.
** `unumut_footnotes`: See `unumut`.
** `unimut`: If specified (i.e. not nil), either true or false. If specified, there may be associated footnotes in
   `unimut_footnotes`. If true, i-mutation is in effect *except* in certain case/num combinations that depend on the
   gender. Specifically: (1) for masculine nouns e.g. [[ketill]] "kettle" and proper names [[Egill]] and [[Ketill]],
   i-mutation does not apply in the dat sg and throughout the plural; (2) for feminine nouns e.g. [[kýr]] "cow",
   [[sýr]] "sow (archaic)" and [[ær]] "ewe", i-mutation does not apply in the acc and dat sg and in the dat and gen
   pl. Cf. also feminine pl-only [[hættur]] "bedtime, quitting time" and [[mætur]] "appreciation, liking", which use
   'unimut' to get e.g. dat pl [[háttum]] and gen pl [[hátta]]; but these are handled by synthesizing a singular
   without i-mutation in the lemma. Very similar are neuter pl [[læti]] "behavior, demeanor" and [[ólæti]] "noise,
   racket", with e.g. dat pl [[látum]] and gen pl [[láta]], which are handled in the same way. When i-mutation is
   *not* in effect, the associated footnotes in `unimut_footnotes` apply. If false, the associated footnotes in
   `unimut_footnotes` still apply in the same circumstances where they would apply if `unimut` where true.
** `unimut_footnotes`: See `unimut`.
]=]
local function create_base()
	return {
		forms = {},
		overrides = {},
		props = {},
		addnote_specs = {},
	}
end


local function formobj_list_has_hyphen(formobjs)
	if not formobjs then
		return false
	end
	for _, formobj in ipairs(formobjs) do
		if formobj.form == "-" then
			return true
		end
	end
	return false
end


local function generate_list_of_possibilities_for_err(list)
	local quoted_list = {}
	for _, item in pairs(list) do
		if item == "" then
			item = "<nowiki />"
		end
		insert(quoted_list, "'" .. item .. "'")
	end
	table.sort(quoted_list)
	return mw.text.listToText(quoted_list)
end


local function skip_slot(number, definiteness, slot)
	return number == "sg" and slot:find("_p$") or
		number == "pl" and slot:find("_s$") or
		definiteness == "def" and slot:find("^ind_") or
		(definiteness == "indef" or definiteness == "none") and slot:find("^def_")
end


-- Given a stem (usually as derived from the infinitive), remove any j from the end if it needs to drop before an
-- ending starting with i.
--
-- Note that the opposite function (determining whether to add a j before a or u) isn't needed because verbs in general
-- already contain a j in the infinitive if one needs to be present before a or u. The only verbs not ending in -a in
-- the infinitive are þvo and those in -á, which do not add j before a or u. We do need to add j before u in the past
-- subjunctive plural if the stem ends in k or g, but that is specific to that form so it's special cased in the code
-- handling it. The only situation we'd really need the "opposite function" in question would be if we need to go from
-- a manually-specified stem where the j has been dropped, e.g. the present indicative singular, to a form ending in
-- a or u, but that doesn't happen; the present indicative singular stem isn't used anywhere else.
local function remove_j_before_i(stem)
	-- Verbs in -kja, -gja, -æja, -ýja, -eyja and -auja (the latter of which includes strauja, margstrauja,
	--   bauja and drauja) remove j before i.
	-- speja "" does not remove j before i.
	-- oja "" does not remove j before i.
	-- húja "" does not remove j before i.
	-- No verbs in -aja, -ája, -éja, -ija, -íja, -ója, -uja (other than -auja), -yja (other than -eyja), -öja.
	return umatch(stem, "^(.*[kgæý])j$") or stem:match("^(.*ey)j$") or stem:match("^(.*au)j$") or stem
end


-- Remove final j and v in a stem that is not followed by a vowel, e.g. pres_indic_1s, imp_2s or weak 1-3 past tense
-- with a dental added directly to the stem. We want to truncate any final j; cf. [[hlæja]], pres1s and imp2s hlæ.
-- But v truncates only after k or g; cf. [[slökkva]] "to put out, to extinguish (a light)", imp2s slökk, past tense
-- slökkti, but [[holdgerva]] with past tense holdgervði, [[slæva]] with imperative slæv and past tense slævði.
local function remove_jv_before_non_vowel(stem)
	return stem:match("^(.*)j$") or stem:match("^(.*[gk])v$") or stem
end


-- Add the appropriate dental suffix (ð, d or t) to a consonant cluster, which should be the final cluster of the word.
-- If the word ends in a vowel, the cluster should be an empty string. Returns a list of the possible clusters including
-- the dental suffix (it is done this way since sometimes the cluster assimilates or partly assimilates to the suffix).
-- If there is more than one element in the list, the first element is the most common one and the one that should be
-- the default; but if the first element is "-" (for -rr and -rn), there is no default and users must explicitly specify
-- the past tense. If the past tense is explicitly given, other dental-suffixed forms (past participle, joined
-- imperative) will pick up the appropriate ending from the past tense. A return value of nil means the cluster ending
-- was unknown; an error should be thrown in this case.
local function add_dental_suffix(cluster)
	-- Vowel stems
	if cluster == "" then
		return {"ð"}
	end
	-- þora -> þorði; hafa -> hafði; slæva -> slævði; segja -> sagði;
	-- erfa -> erfði; holdgerva -> holdgervði; byrgja -> byrgði
	if cluster:find("^[rfvg]$") or cluster:find("r[fvg]$") then
		return {cluster .. "ð"}
	end
	if cluster == "rr" then
		-- No default; firra -> firrti (rarely firrði); kerra -> kerrti; sperra -> sperrti; skirrast -> skirrtist or
		-- skirrðist; kyrra -> kyrrði
		return {"-", "rrt", "rrð"}
	end
	if cluster == "rn" then
		-- No default; fyrna -> fyrndi; stirna -> stirndi; girna -> girnti; spyrna -> spyrnti
		return {"-", "rnt", "rnd"}
	end
	if cluster == "ð" or cluster == "dd" or cluster == "d" then
		-- beiða -> beiddi; brydda -> bryddi (or bryddaði); ydda "to sharpen" -> yddi (or proscribed yddaði)
		-- -Vda may not exist (as weak-1/2/3)
		return {"dd"}
	end
	if cluster == "n" or cluster:find("[fvg]n$") or cluster:find("ng$") then
		-- reyna -> reyndi; nefna -> nefndi; rigna -> rigndi; hringja -> hringdi; -vna doesn't exist
		return {cluster .. "d"}
	end
	if cluster:find("[mb]$") then
		-- dimma -> dimmdi; hylma -> hylmdi (rarer hylmaði); verma -> vermdi; kemba -> kembdi; -ba and -bba may not
		-- exist
		return {cluster .. "d"}
	end
	if cluster:find("l[fgv]$") or cluster:find("[fgv]l$") then
		-- skelfa -> skelfdi; skefla -> skefldi; fylgja -> fylgdi; sigla -> sigldi; -lva and -vla may not exist
		return {cluster .. "d"}
	end
	if cluster == "l" then
		-- mæla ("to measure") -> mældi
		-- Only two exceptions: mæla ("to say") -> mælti; stæla ("to harden") -> stælti
		return {"ld", "lt"}
	end
	if cluster:find("[pksx]$") or cluster == "t" then
		-- kaupa -> keypti; mæta -> mætti; reisa -> reisti
		return {cluster .. "t"}
	end
	if cluster:find("t$") then
		-- svelta -> svelti; hitta -> hitti
		return {cluster}
	end
	if cluster:find("rð$") then
		-- girða -> girti
		return {usub(cluster, 1, -2) .. "t"}
	end
	if cluster:find("[ln]d$") then
		-- gelda -> gelti; synda -> synti
		-- Only four exceptions: elda -> eldi (also elti); ýlda -> ýldi (rare, mostly ýldaði); senda -> sendi
		-- (but endasenda -> endasenti); venda -> vendi (regional or obsolete, often venti)
		return {usub(cluster, 1, -2) .. "t", cluster}
	end
	if cluster:find("nn$") or cluster:find("ll$") then
		-- spenna -> spennti; smella -> smellti
		-- Only three exceptions for -nn: brenna -> brenndi; kenna -> kenndi; renna -> renndi
		-- Only six exceptions for -ll: bella -> belldi; fella -> felldi; hrella -> hrelldi; skella -> skelldi (dated,
		--   normative skellti); tolla -> tolldi; vella -> velldi
		return {cluster .. "t", cluster .. "d"}
	end
	return nil
end


--[=[
Basic function to combine stem(s) and other properties with ending(s) and insert the result into the appropriate
slot. `base` is the object describing all the properties of the word being inflected for a single alternant (in case
there are multiple alternants specified using `((...))`). `slot_prefix` is either "ind_" or "def_" and is prefixed to
the slot value in `slot` to get the actual slot to add the resulting forms to. (`slot_prefix` is separated out
because the code below frequently needs to conditionalize on the value of `slot` and should not have to worry about
the definite and indefinite slot variants). `props` is a property set object containing computed stems and other
information (such as whether i-mutation is active) about a particular combination of control specs. See the comment
above create_base() for more information. The information found in `props` cannot be stored in `base` because there may
be more than one set of such properties per `base` (e.g. if the user specified 'umut,uUmut' or '-j,j' or '-imut,imut'
or some combination of these; in such a case, the caller will iterate over all possible combinations, and ultimately
invoke add() multiple times, one per combination). `endings` is the ending or endings added to the appropriate stem
(after any j or v infix) to get the form(s) to add to the slot. Its value can be a single string, a list of strings,
or a list of form objects (i.e. in general list form). `clitics` is the clitic or clitics to add after the endings to
form the actual form value inserted into definite slots; it should be nil for indefinite slots. Its format is the
same as for `endings`. `ending_override`, if true, indicates that the ending(s) supplied in `endings` come from a
user-specified override, and hence j and v infixes should not be added as they are already included in the override
if needed.
]=]
local function add_slotval(base, slot_prefix, slot, props, endings, clitics, ending_override)
	if not endings then
		return
	end
	-- Call skip_slot() based on the declined number and definiteness; if the actual number is different, we correct
	-- this in conjugate_verb() at the end.
	if skip_slot(base.number, base.definiteness, slot) then
		return
	end
	if not clitics then
		clitics = { "" }
	elseif type(clitics) == "string" then
		clitics = { clitics }
	end
	if type(endings) == "string" then
		endings = { endings }
	end
	-- Loop over each ending and clitic.
	for _, endingobj in ipairs(endings) do
		for _, cliticobj in ipairs(clitics) do
			-- Do the following inside of the innermost loop even though it does not depend on the value of `cliticobj`,
			-- because that way we are free to mutate `ending` below.
			local ending, ending_footnotes
			if type(endingobj) == "string" then
				ending = endingobj
			else
				ending = endingobj.form
				ending_footnotes = endingobj.footnotes
			end
			-- Ending of "-" means the user used -- to indicate there should be no form here.
			if ending == "-" then
				return
			end
			local function interr(msg)
				error(("Internal error: For lemma '%s', slot '%s%s', ending '%s', %s: %s"):format(base.lemma, slot_prefix,
					slot, ending, msg, dump(props)))
			end

			local clitic, clitic_footnotes
			if type(cliticobj) == "string" then
				clitic = cliticobj
			else
				clitic = cliticobj.form
				clitic_footnotes = cliticobj.footnotes
			end

			-- Compute whether i-mutation or u-mutation is in effect, and compute the "mutation footnotes", which are
			-- footnotes attached to a mutation-related indicator and which may need to be added even if no mutation is
			-- in effect (specifically when dealing with an ending that would trigger a mutation if in effect). AFAIK
			-- you cannot have both mutations in effect at once, and i-mutation overrides u-mutation if both would be in
			-- effect.

			-- Single ^ at the beginning of an ending indicates that the i-mutated version of the stem should apply, and
			-- double ^^ at the beginning indicates that the u-mutated version should apply.
			local explicit_imut, explicit_umut
			-- % at the end of a definite ending indicates that the following i- of the clitic should drop, as with
			-- neuter [[tré]], [[kné]], [[fé]]. There's no counterpart to force irregular inclusion of an i- that would
			-- normally drop; just include it in the ending (as with acc/dat sg of [[eygló]] "eyeball???" and [[sígó]]
			-- "cig").
			local clitic_i_drops
			ending, explicit_umut = rsubb(ending, "^%^%^", "")
			if not explicit_umut then
				ending, explicit_imut = rsubb(ending, "^%^", "")
			end
			ending, clitic_i_drops = rsubb(ending, "%%$", "")
			local is_vowel_ending = ufind(ending, "^" .. com.vowel_c)
			local is_vowel_clitic = ufind(clitic, "^" .. com.vowel_c)
			local mut_in_effect, mut_not_in_effect, mut_footnotes
			local ending_in_a = not not ending:find("^a")
			local ending_in_i = not not ending:find("^i")
			local ending_in_u = not not ending:find("^u")
			if props.unimut ~= nil and props.unumut ~= nil then
				interr("Cannot have both 'unimut' and 'unumut' in effect at the same time")
			end
			if props.unimut ~= nil and props.imut ~= nil then
				interr("Cannot have both 'unimut' and 'imut' in effect at the same time")
			end
			if props.unumut ~= nil and props.umut ~= nil then
				interr("Cannot have both 'unumut' and 'umut' in effect at the same time")
			end
			if explicit_imut then
				mut_in_effect = "i"
			elseif explicit_umut then
				mut_in_effect = "u"
			else
				if props.unimut ~= nil then
					local is_unimut_slot
					if base.gender == "m" then
						is_unimut_slot = slot == "dat_s" or slot:find("_p")
					elseif base.gender == "f" then
						is_unimut_slot = slot == "acc_s" or slot == "dat_s" or slot == "dat_p" or
							slot == "gen_p"
					else
						interr(
						"'unimut' shouldn't be specified with neuter nouns; don't know what slots would be affected; neuter pluralia tantum nouns using 'unimut' should have synthesized a singular without i-mutation")
					end
					if is_unimut_slot then
						mut_not_in_effect = "i"
						mut_footnotes = props.unimut_footnotes
					elseif props.unimut then
						mut_in_effect = "i"
					end
				elseif props.imut ~= nil then
					if ending_in_i then
						if props.imut then
							mut_in_effect = "i"
							mut_footnotes = props.imut_footnotes
						elseif props.imut == false then
							mut_not_in_effect = "i"
							mut_footnotes = props.imut_footnotes
						end
					end
				end
				if props.unumut ~= nil then
					local is_unumut_slot
					if props.unumut == "unumut" or props.unumut == "-unumut" then
						is_unumut_slot = ending_in_a or ending_in_i
					elseif base.gender == "m" then
						is_unumut_slot = slot == "gen_s" or slot == "gen_p"
					elseif base.gender == "f" then
						is_unumut_slot = slot == "nom_p" or slot == "acc_p" or slot == "gen_p"
					else
						interr(
						"'unumut' and variants shouldn't be specified with neuter nouns; don't know what slots would be affected; neuter pluralia tantum nouns using 'unumut'and variants should have synthesized a singular without u-mutation")
					end
					if not mut_in_effect and not mut_not_in_effect then
						-- Do nothing if mut_in_effect or mut_not_in_effect because i-mut takes precedence over u-mut;
						-- FIXME: I hope this is correct in all cases.
						if is_unumut_slot then
							mut_not_in_effect = "u"
							mut_footnotes = props.unumut_footnotes
						elseif props.unumut then
							mut_in_effect = "u"
						end
					end
				end
				if ending_in_u and not mut_in_effect then
					mut_in_effect = "u"
					-- umut and uUmut footnotes are incorporated into the appropriate umut_* stems
				end
			end

			local ending_was_asterisk = ending == "*"

			-- Now compute the appropriate stem to which the ending and clitic are added. `prefix` is either an empty
			-- string or "pl_" and selects the set of stems to consider when computing the stem in effect. See the
			-- comment above for `pl_stem`.
			local function compute_stem_in_effect(prefix)
				local stem_in_effect

				if mut_in_effect == "i" then
					-- NOTE: It appears that imut and defcon never co-occur; otherwise we'd need to flesh out the set of
					-- stems to include i-mutation versions of defcon stems, similar to what we do for u-mutation.
					if is_vowel_ending then
						if not props[prefix .. "imut_vstem"] then
							interr(("i-mutation in effect and ending begins with a vowel but '.%simut_vstem' not defined")
							:
							format(prefix))
						end
						stem_in_effect = props[prefix .. "imut_vstem"]
					else
						if not props[prefix .. "imut_nonvstem"] then
							interr(("i-mutation in effect and ending does not begin with a vowel but '.%simut_nonvstem' not defined")
							:
							format(prefix))
						end
						stem_in_effect = props[prefix .. "imut_nonvstem"]
					end
				else
					-- Careful with the following logic; it is written carefully and should not be changed without a
					-- thorough understanding of its functioning.
					local has_umut = mut_in_effect == "u"
					-- First, if the ending is null (or "*", which eventually turns into a null ending; see below), and
					-- we have a vowel-initial definite-article clitic, use the special 'defcon' stem if available.
					if (ending == "" or ending == "*") and is_vowel_clitic then
						stem_in_effect = has_umut and props[prefix .. "umut_null_defvstem"] or
							props[prefix .. "null_defvstem"]
					end
					-- If the stem is still unset, then use the vowel or non-vowel stem if available. When u-mutation is
					-- active, we first check for the u-mutated version of the vowel or non-vowel stem before falling
					-- back to the regular vowel or non-vowel stem. Note that an expression like `has_umut and
					-- props[prefix .. "umut_vstem"] or props[prefix .. "vstem"]` here is NOT equivalent to an if-else
					-- or ternary operator expression because if `has_umut` is true and `umut_vstem` is missing, it will
					-- still fall back to `vstem` (which is what we want).
					if not stem_in_effect then
						if is_vowel_ending then
							stem_in_effect = has_umut and props[prefix .. "umut_vstem"] or props[prefix .. "vstem"]
						else
							stem_in_effect = has_umut and props[prefix .. "umut_nonvstem"] or
								props[prefix .. "nonvstem"]
						end
					end
					-- Finally, fall back to the basic stem, which is always defined.
					stem_in_effect = stem_in_effect or props[prefix .. "stem"]
				end

				-- If the ending is "*", it means to use the lemma as the form directly (before adding any definite
				-- clitic) rather than try to construct the form from a stem and ending. We need to do this for the
				-- lemma slot and especially for the nominative singular, because we don't have the nominative singular
				-- ending available and it may vary (e.g. it may be -ur, -l, -n, -a, etc. especially in the masculine).
				-- Not trying to construct the form from stem + ending also avoids complications from the nominative
				-- singular in -ur, which exceptionally does not trigger u-mutation. However, when 'defcon' is active
				-- and we're processing a definite form beginning with a vowel (i.e.  is_vowel_clitic is set), we can't
				-- do this, because the form to which the clitic is added is not the lemma but the contracted version.
				-- As it happens, this works out because in all situations where 'defcon' is active, the nominative
				-- singular has a null ending. (If this weren't the case, we'd have to change all the declension
				-- functions to pass in the nominative singular ending in addition to other endings.) An example where
				-- 'defcon' is active is neuter [[mastur]] "mast" with definite nominative singular [[mastrið]]; here,
				-- using the lemma would incorrectly produce #[[masturið]].

				-- Finally, however, if there is a footnote associated with the computed stem in effect, we need to
				-- preserve it.
				if ending == "*" then
					if not is_vowel_clitic or not props.defcon or props.defcon.form ~= "defcon" then
						local stem_in_effect_footnotes
						if type(stem_in_effect) == "table" then
							stem_in_effect_footnotes = stem_in_effect.footnotes
						end
						stem_in_effect = iut.combine_form_and_footnotes(base.actual_lemma, stem_in_effect_footnotes)
					end
					-- See comment above. When 'defcon' is not in effect, we changed the stem to be the lemma and
					-- want to use a null ending; otherwise, the ending is always null anyway, so it's safe to set
					-- it thus.
					ending = ""
				end

				return stem_in_effect
			end

			local stem_in_effect = props.pl_stem and slot:find("_p$") and compute_stem_in_effect("pl_") or
				compute_stem_in_effect("")

			local infix, infix_footnotes
			-- Compute the infix (j, v or nothing) that goes between the stem and ending.
			if not ending_override and is_vowel_ending then
				if props.vinfix and props.jinfix then
					interr("Can't have specifications for both '.vinfix' and '.jinfix'; should have been caught above")
				end
				if props.vinfix then
					infix = props.vinfix
					infix_footnotes = props.vinfix_footnotes
				elseif props.jinfix and not ending_in_i then
					infix = props.jinfix
					infix_footnotes = props.jinfix_footnotes
				end
			end

			-- If base-level footnotes specified, they go before any stem footnotes, so we need to extract any footnotes
			-- from the stem in effect and insert the base-level footnotes before. In general, we want the footnotes to
			-- be in the order [base.footnotes, stem.footnotes, mut_footnotes, infix_footnotes, ending.footnotes,
			-- clitic.footnotes].
			if base.footnotes then
				local stem_in_effect_footnotes
				if type(stem_in_effect) == "table" then
					stem_in_effect_footnotes = stem_in_effect.footnotes
					stem_in_effect = stem_in_effect.form
				end
				stem_in_effect = iut.combine_form_and_footnotes(stem_in_effect,
					iut.combine_footnotes(base.footnotes, stem_in_effect_footnotes))
			end

			local ending_is_full
			ending, ending_is_full = rsubb(ending, "^!", "")

			local function combine_stem_ending(stem, clitic)
				if stem == "?" then
					return "?"
				end
				local function drop_clitic_i()
					clitic = clitic:gsub("^i", "")
				end
				-- If we're definite-only and using the actual lemma as the stem, the clitic is already incorporated
				-- into the stem.
				if base.definiteness == "def" and ending_was_asterisk then
					return stem
				end
				-- % at the end of a definite ending indicates that the following i- of the clitic should drop; see
				-- above.
				if clitic_i_drops then
					drop_clitic_i()
				end
				local stem_with_infix = ending_is_full and "" or stem .. (infix or "")
				-- Drop final -j- of stem before an ending beginning with a consonant. This happens e.g. in [[kirkja]]
				-- "church" with genitive plural -na, producing [[kirkna]]. It does not happen with a null ending; cf.
				-- neuter [[emj]] "cries, shouting" and [[gremj]] "anger, irritation" (the latter not in BÍN).
				if stem_with_infix:find("j$") and ufind(ending, "^" .. com.cons_c) then
					stem_with_infix = stem_with_infix:gsub("j$", "")
				end
				local stem_with_ending
				-- An initial s- of the ending drops after a cluster of cons + s (including written <x>).
				if ending:find("^s") and (stem_with_infix:find("x$") or ufind(stem_with_infix, com.cons_c .. "s$")) then
					stem_with_ending = stem_with_infix .. ending:gsub("^s", "")
				else
					stem_with_ending = stem_with_infix .. ending
				end
				if clitic == "" then
					return stem_with_ending
				end
				if slot == "dat_p" then
					stem_with_ending = stem_with_ending:gsub("m$", "")
				end
				if clitic:find("^i.*[aiu]") then -- disyllabic clitics in i-
					-- in practice, fem acc_s -ina, dat_s -inni, gen_s -innar
					if ufind(stem_with_ending, com.vowel_c .. "$") then
						drop_clitic_i()
					end
				elseif clitic:find("^i") then -- monosyllabic clitics in i-
					local ending_for_clitic_dropping = ending_was_asterisk and base.lemma_ending or ending
					if ending_for_clitic_dropping:find("[aiu]$") then
						drop_clitic_i()
					end
				end
				return stem_with_ending .. clitic
			end

			local combined_footnotes = iut.combine_footnotes(
				iut.combine_footnotes(mut_footnotes, infix_footnotes),
				iut.combine_footnotes(ending_footnotes, clitic_footnotes)
			)
			local clitic_with_notes = iut.combine_form_and_footnotes(clitic, combined_footnotes)
			if not stem_in_effect then
				interr("stem_in_effect is nil")
			end
			iut.add_forms(base.forms, slot_prefix .. slot, stem_in_effect, clitic_with_notes,
				combine_stem_ending)
		end
	end
end


-- Add the definite and indefinite variants of a slot by combining the appropriate stem in `props` with (optionally) an
-- infix in `props` and the endings in `endings`, tacking on the definite article clitic in the definite slot variant.
-- This calls the underlying function add_slotval() twice, once for indefinite forms and once for definite forms, and is
-- normally called by add_decl() or similar function to add an entire declension. `endings` can be nil (no endings are
-- added), a single string, a list of strings, a list of form objects (i.e. in general list form), or a table containing
-- fields `indef` and `def` (each of which can be any of the previous formats) to add separate sets of endings for the
-- indefinite and definite slot variants. If any of the formats for `endings` is supplied other than the separate
-- indefinite/definite table, the supplied set of endings is used for both indefinite and definite slot variants.
-- `ending_override` and `endings_are_full` are as in add_slotval().
local function add(data, slot, stemobj, ending)
	if not endings then
		return
	end
	local indef_endings, def_endings
	if type(endings) == "table" and (endings.indef or endings.def) then
		indef_endings = endings.indef
		def_endings = endings.def
	else
		indef_endings = endings
		def_endings = endings
	end
	if indef_endings and base.definiteness ~= "def" then
		add_slotval(base, "ind_", slot, props, indef_endings, nil, ending_override, endings_are_full)
	end
	if def_endings and (base.definiteness ~= "indef" and base.definiteness ~= "none") then
		local clitic = clitic_articles[base.gender]
		if not clitic then
			error(("Internal error: Unrecognized value for base.gender: %s"):format(dump(base.gender)))
		end
		clitic = clitic[slot]
		if not clitic then
			error(("Internal error: Unrecognized value for `slot` in add(): %s"):format(dump(slot)))
		end
		add_slotval(base, "def_", slot, props, def_endings, clitic, ending_override, endings_are_full)
	end
end


local function process_one_slot_override(base, slot, spec)
	-- Call skip_slot() based on the declined number and definiteness; if the actual number is different, we correct
	-- this in conjugate_verb() at the end.
	if skip_slot(base.number, base.definiteness, slot) then
		error(("Override specified for invalid slot '%s' due to '%s' number restriction and/or '%s' definiteness restriction")
		:format(
			slot, base.number, base.definiteness))
	end
	local defslot = slot:find("^def_")
	if defslot then
		base.forms[slot] = nil
	else
		if spec.indef ~= false then
			base.forms["ind_" .. slot] = nil
		end
		if spec.def ~= false then
			base.forms["def_" .. slot] = nil
		end
	end
	if defslot then
		local slot_prefix
		-- Don't call add(), like below, because it adds both indefinite and definite variants, including definite
		-- clitics in the latter. Instead, directly call add_slotval(). But we need to separate the slot into slot
		-- prefix "def_" and the remainder because add_slotval() expects slots to be missing the prefix when
		-- checking which stem to use (which may depend on the slot).
		slot_prefix, slot = slot:match("^(def_)(.*)$")
		for _, props in ipairs(base.prop_sets) do
			add_slotval(base, slot_prefix, slot, props, spec.def, nil, "ending override")
		end
	else
		local endings
		if spec.indef ~= nil and spec.def ~= nil then
			-- This could include `false` as the value of either `spec.indef` or `spec.def` to not touch those slots.
			-- Note that specifying something like 'dat/i' is allowed and will only override the definite slot, but
			-- is different from a definite-slot override 'defdatinum' because the latter includes the clitic in it.
			endings = {
				indef = spec.indef,
				def = spec.def,
			}
		elseif not spec.indef then
			error(("Internal error: Unless both `spec.indef` and `spec.def` have non-nil values (i.e. the user included a slash in the override, `spec.indef` must be defined: %s")
			:dump(spec))
		elseif slot == "acc_p" then
			-- As a special case, don't carry over literary acc_p ending -u to the definite.
			local def_endings = {}
			for _, ending in ipairs(spec.indef) do
				-- If the ending is full (begins with !), check the whole thing for -u at the end.
				if not ending.form:find("^%^*u$") and not ending.form:find("^!.*[^Aa]u$") then
					insert(def_endings, ending)
				end
			end
			endings = {
				indef = spec.indef,
				def = def_endings,
			}
		else
			endings = spec.indef
		end
		for _, props in ipairs(base.prop_sets) do
			add(base, slot, props, endings, "ending override")
		end
	end
end


local function process_slot_overrides(base)
	if base.gens then
		process_one_slot_override(base, "gen_s", base.gens)
	end
	if base.pls then
		local spec = base.pls
		process_one_slot_override(base, "nom_p", spec)
		local acc_p_spec = {
			indef = acc_p_from_nom_p(base, spec.indef),
			def = acc_p_from_nom_p(base, spec.def),
		}
		process_one_slot_override(base, "acc_p", acc_p_spec)
	end
	for slot, spec in pairs(base.overrides) do
		process_one_slot_override(base, slot, spec)
	end
end


-- Generate the full declension for the term given the endings for each slot. acc_p, dat_p and gen_p can be omitted and
-- will be defaulted: dat_p defaults to "um", gen_p defaults to "a", and acc_p defaults to the nom_p except for masculines
-- not in -ur, where the -r is dropped. Use `false` as the value of an ending to disable generating any value for that
-- slot.
local function add_personal_tense(data, slot_prefix, stemobj, s1, s2, s3, p1, p2, p3)
	add(data, slot_prefix .. "1s", , "nom_s", props, nom_s)
	add(base, "acc_s", props, acc_s)
	add(base, "dat_s", props, dat_s)
	add(base, "gen_s", props, gen_s)
	if base.number == "pl" then
		-- If this is a plurale tantum noun and we're processing the nominative plural, use the user-specified lemma
		-- rather than generating the plural from the synthesized singular, which may not match the specified lemma.
		-- This is both because we don't set a plural override to specify what the plural should look like and because
		-- of exceptional cases like [[dyr]], which is plural-only and uses 'decllemma:dyrir'.
		nom_p = "*"
	end
	add(base, "nom_p", props, nom_p)
	-- Generate defaults for acc_p, dat_p, gen_p if nil was specified; but be careful not to do so for false, which
	-- means to generate no form.
	if acc_p == nil then
		acc_p = acc_p_from_nom_p(base, nom_p)
	end
	if dat_p == nil then
		dat_p = "um"
	end
	if gen_p == nil then
		gen_p = "a"
	end
	add(base, "acc_p", props, acc_p)
	add(base, "dat_p", props, dat_p)
	add(base, "gen_p", props, gen_p)
end

-- Generate the full declension for the term given the endings for each slot except the nom_s. This is like
-- add_decl_with_nom_sg() but takes the nom sg directly from the lemma instead of trying to reconstruct it from a stem,
-- which is more correct in the vast majority of circumstances. The * below is a signal to the underlying add() function
-- to use the actual lemma (not any stem, and not the value of 'decllemma:' if given) for the nom sg. Note that add() is
-- smart enough to ignore this for the definite nom sg when the 'defcon' indicator is given, because in that case the stem
-- for the def nom sg is contracted compared with the lemma. (Specifically, it uses the correct contracted stem and a null
-- ending; AFAIK all cases of 'defcon' occur with lemmas with a null ending in the nom sg.)
local function add_decl(base, props, acc_s, dat_s, gen_s, nom_p, acc_p, dat_p, gen_p)
	add_decl_with_nom_sg(base, props, "*", acc_s, dat_s, gen_s, nom_p, acc_p, dat_p, gen_p)
end

local function add_sg_decl(base, props, acc_s, dat_s, gen_s)
	add_decl(base, props, acc_s, dat_s, gen_s, false, false, false, false)
end

local function add_pl_only_decl(base, props, acc_p, dat_p, gen_p)
	add_decl(base, props, false, false, false, "*", acc_p, dat_p, gen_p)
end


local function reconstruct_control_spec(control_specs)
	local parts = {}
	local function ins(txt)
		insert(parts, txt)
	end
	for i, spec in ipairs(control_specs) do
		if i > 1 then
			ins(",")
		end
		ins(spec.form)
		if spec.footnotes then
			for _, footnote in ipairs(spec.footnotes) do
				ins(footnote) -- already has brackets around it
			end
		end
	end
	return concat(parts)
end


local function set_builtin_defaults(base)
	if base.gender or base.number or base.definiteness then
		error("Can't specify gender, number or definiteness for built-in terms")
	end

	local function builtin_props()
		-- Return values are GENDER, NUMBER
		if base.lemma == "ég" or base.lemma == "þú" then
			return "none", "sg"
		elseif base.lemma == "við" or base.lemma == "þið" then
			return "none", "pl"
		elseif base.lemma == "hann" then
			return "m", "sg"
		elseif base.lemma == "hún" then
			return "f", "sg"
		elseif base.lemma == "það" then
			return "n", "sg"
		elseif base.lemma == "þeir" then
			return "m", "pl"
		elseif base.lemma == "þær" then
			return "f", "pl"
		elseif base.lemma == "þau" then
			return "n", "pl"
		elseif base.lemma == "sig" then
			return "none", "none"
		else
			error(("Unrecognized pronoun '%s'"):format(base.lemma))
		end
	end

	local gender, number = builtin_props()
	base.gender = gender
	base.actual_gender = gender
	base.number = number
	base.actual_number = number
	base.definiteness = "none"
end


local function determine_builtin_props(base)
	base.prop_sets[1].stem = { form = "" }
	base.decl = "builtin"
end


decls["builtin"] = function(base, props)
	if base.lemma == "ég" then
		add_sg_decl(base, props, "mig", "mér", "mín")
	elseif base.lemma == "þú" then
		add_sg_decl(base, props, "þig", "þér", "þín")
	elseif base.lemma == "hann" then
		add_sg_decl(base, props, "hann", "honum", "hans")
	elseif base.lemma == "hún" then
		add_sg_decl(base, props, "hana", "henni", "hennar")
	elseif base.lemma == "það" then
		add_sg_decl(base, props, "það", "því", "þess")
	elseif base.lemma == "við" then
		add_pl_only_decl(base, props, "okkur", "okkur", "okkar")
	elseif base.lemma == "þið" then
		add_pl_only_decl(base, props, "ykkur", "ykkur", "ykkar")
	elseif base.lemma == "þeir" then
		add_pl_only_decl(base, props, "þá", "þeim", "þeirra")
	elseif base.lemma == "þær" then
		add_pl_only_decl(base, props, "þær", "þeim", "þeirra")
	elseif base.lemma == "þau" then
		add_pl_only_decl(base, props, "þau", "þeim", "þeirra")
	elseif base.lemma == "sig" then
		-- Underlyingly we handle [[sig]]'s slots as singular.
		add_decl_with_nom_sg(base, props, false, "*", "sér", "sín", false, false, false, false)
	else
		error(("Internal error: Unrecognized pronoun lemma '%s'"):format(base.lemma))
	end
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
					insert(lemmas_no_footnotes, { form = lemma.form })
				end
				return lemmas_no_footnotes
			else
				return lemmas
			end
		end
	end
	return {}
end

local function handle_derived_slots_and_overrides(base)
	-- Process slot overrides: First slots specified after the gender, then individual slot overrides specified as
	-- separate indicators.
	process_slot_overrides(base)

	-- Compute linked versions of potential lemma slots, for use in {{is-noun}}. We substitute the original lemma
	-- (before removing links) for forms that are the same as the lemma, if the original lemma has links.
	for _, slot in ipairs(potential_lemma_slots) do
		iut.insert_forms(base.forms, slot .. "_linked", iut.map_forms(base.forms[slot], function(form)
			if form == base.orig_lemma_no_links then
				if base.orig_lemma:find("%[%[") then
					return base.orig_lemma
				elseif not base.is_multiword then
					return form
				elseif not base.props.linkasis and (base.lemma ~= base.orig_lemma_no_links or base.link_lowercase) then
					local lemma_for_linking = base.lemma
					if base.link_lowercase then
						local init, rest = umatch(lemma_for_linking, "^(.)(.*)$")
						lemma_for_linking = ulower(init) .. rest
					end
					return ("[[%s|%s]]"):format(lemma_for_linking, base.orig_lemma_no_links)
				else
					return ("[[%s]]"):format(form)
				end
			else
				return form
			end
		end))
	end
end


-- Process specs given by the user using 'addnote[SLOTSPEC][FOOTNOTE][FOOTNOTE][...]'.
local function process_addnote_specs(base)
	for _, spec in ipairs(base.addnote_specs) do
		for _, slot_spec in ipairs(spec.slot_specs) do
			slot_spec = "^" .. slot_spec .. "$"
			for slot, forms in pairs(base.forms) do
				if ufind(slot, slot_spec) then
					-- To save on memory, side-effect the existing forms.
					for _, form in ipairs(forms) do
						form.footnotes = iut.combine_footnotes(form.footnotes, spec.footnotes)
					end
				end
			end
		end
	end
end


local function is_regular_noun(base)
	return not base.adjspec and not base.props.builtin
end


local function process_declnumber(base)
	base.actual_number = base.number
	if base.declnumber then
		if base.declnumber == "sg" or base.declnumber == "pl" then
			base.number = base.declnumber
		else
			error(("Unrecognized value '%s' for 'declnumber', should be 'sg' or 'pl'"):format(base.declnumber))
		end
	end
end


-- Map `fn` over an override spec (either `gens`, `pls` or one of the overrides in `overrides`). `fn` is passed one
-- item (the form object of the override), which it can mutate if needed. If it ever returns non-nil, mapping stops
-- and that value is returned as the return value of `map_override`; otherwise mapping runs to completion and nil is
-- returned.
local function map_override(override, fn)
	if not override then
		return nil
	end
	local function map_one_list(list)
		if not list then
			return nil
		end
		for _, formobj in ipairs(list) do
			local retval = fn(formobj)
			if retval ~= nil then
				return retval
			end
		end
		return nil
	end
	local retval = map_one_list(override.indef)
	if retval ~= nil then
		return retval
	end
	return map_one_list(override.def)
end

-- Map `fn` over all override specs in `base` (`gens`, `pls` and the overrides in `overrides`). `fn` is passed one
-- item (the form object of the override), which it can mutate if needed. If it ever returns non-nil, mapping stops
-- and that value is returned as the return value of `map_override`; otherwise mapping runs to completion and nil is
-- returned.
local function map_all_overrides(base, fn)
	for slot, override in pairs(base.overrides) do
		local retval = map_override(override, fn)
		if retval ~= nil then
			return retval
		end
	end
	local retval = map_override(base.gens, fn)
	if retval ~= nil then
		return retval
	end
	return map_override(base.pls, fn)
end


-- Like put.split_alternating_runs_and_strip_spaces(), but ensure that backslash-escaped commas and periods are not
-- treated as separators.
local function split_alternating_runs_with_escapes(segments, splitchar, preserve_splitchar)
	for i, segment in ipairs(segments) do
		segment = rsub(segment, "\\,", SUB_ESCAPED_COMMA)
		segments[i] = rsub(segment, "\\%.", SUB_ESCAPED_PERIOD)
	end
	local separated_groups = put.split_alternating_runs_and_strip_spaces(segments, splitchar, preserve_splitchar)
	for _, separated_group in ipairs(separated_groups) do
		for i, segment in ipairs(separated_group) do
			segment = rsub(segment, SUB_ESCAPED_COMMA, ",")
			separated_group[i] = rsub(segment, SUB_ESCAPED_PERIOD, ".")
		end
	end
	return separated_groups
end


local function fetch_footnotes_and_paren_spec(separated_group, parse_err, allow_paren_spec)
	local footnotes
	local paren_spec

	for j = 2, #separated_group - 1, 2 do
		if separated_group[j + 1] ~= "" then
			parse_err("Extraneous text after bracketed footnotes")
		end
		if not footnotes then
			footnotes = {}
		end
		local footnote_or_paren_spec = separated_group[j]
		if footnote_or_paren_spec:find("^%(") then
			if not allow_paren_spec then
				parse_err("Parenthesized specs not allowed")
			end
			if j < #separated_group - 1 then
				parse_err("Parenthesized spec must come last (after any footnotes)")
			else
				paren_spec = footnote_or_paren_spec
			end
		else
			insert(footnotes, separated_group[j])
		end
	end
	return footnotes, paren_spec
end


-- Fetch and parse a slot override, e.g. "ar:s" or "um:m[archaic]/um" or "i:!Þorkatli[archaic]" (where ! indicates that
-- the override is the full form including the stem); that is, everything after the slot name(s). `segments` is the
-- input in the form of a list where the footnotes have been separated out (see `parse_override` below); `spectype` is
-- used in error messages and specifies e.g. "genitive" or "dat+gen slot override"; `allow_blank` indicates that a
-- completely blank override spec is allowed (in that case, nil will be returned); `defslot`, if true, indicates that
-- we're processing a definite slot override, i.e. two slash-separated specs (indefinite and definite) are not allowed
-- and the return overrides will be stored into `def`; and `parse_err` is a function of one argument to throw a parse
-- error. The return value is an object containing fields `indef` and/or `def`, of the format described below in the
-- comment above `parse_override`.
local function fetch_slot_override(segments, spectype, allow_blank, defslot, parse_err)
	if allow_blank and #segments == 1 and segments[1] == "" then
		return nil
	end
	local slash_separated_groups = put.split_alternating_runs_and_strip_spaces(segments, "/")
	if #slash_separated_groups > 2 then
		parse_err(("Can specify at most two slash-separated override groups for %s, but saw %s"):format(
			spectype, #slash_separated_groups))
	end
	if slash_separated_groups[2] and defslot then
		parse_err(("Can't specify two slash-separated override groups for %s; the second override group is for the definite slot variant, but the slot is already definite")
		:format(
			spectype))
	end
	local ret = {}
	for i, slash_separated_group in ipairs(slash_separated_groups) do
		local retfield = defslot and "def" or i == 1 and "indef" or "def"
		if #slash_separated_group == 1 and slash_separated_group[1] == "" then
			ret[retfield] = false
		else
			local colon_separated_groups = put.split_alternating_runs_and_strip_spaces(slash_separated_group, ":")
			local specs = {}
			for _, colon_separated_group in ipairs(colon_separated_groups) do
				local form = colon_separated_group[1]
				if form == "" then
					parse_err(("Use - to indicate an empty ending for %s: '%s'"):format(spectype,
						concat(segments)))
				elseif form == "-" then
					form = ""
				elseif form == "--" then -- missing
					form = "-"
				end
				local new_spec = { form = form, footnotes = fetch_footnotes_and_paren_spec(colon_separated_group, parse_err) }
				for _, existing_spec in ipairs(specs) do
					if existing_spec.form == new_spec.form then
						parse_err("Duplicate " .. spectype .. " spec '" .. concat(colon_separated_group) .. "'")
					end
				end
				insert(specs, new_spec)
			end
			ret[retfield] = specs
		end
	end
	return ret
end


--[=[
Parse a single override spec (e.g. 'dat-:i/-' or 'nompl+accpl^/' or
'defnompl+defaccpl!sumrin[when referring to summers in general]:!sumurin[when referring to a specific number of summers]')
and return two values: the slot(s) the override applies to, and an object describing the override spec. The input is
actually a list where the footnotes have been separated out; for example, given the third example spec above, the input
will be a list {"defnompl+defaccpl!sumrin", "[when referring to summers in general]", ":!sumurin",
  "[when referring to a specific number of summers]", ""}.

The object returned for 'dat-:i[mostly in the context of violent actions]/-' looks like this:

{
  indef = {
	{
	  form = ""
	},
	{
	  form = "i",
	  footnotes = {"[mostly in the context of violent actions]"}
	}
  },
  def = {
	{
	  form = ""
	}
  }
}

The object returned for '!nompl+accpl^/' looks like this:

{
  indef = {
	{
	  form = "^"
	},
  },
  def = false
}

The object returned for 'defnompl+defaccpl!sumrin[when referring to summers in general]:!sumurin[when referring to a specific number of summers]'
looks like this:

{
  def = {
	{
	  form = "!sumrin",
	  footnotes = {"[when referring to summers in general]"}
	},
	{
	  form = "!sumurin",
	  footnotes = {"[when referring to a specific number of summers]"}
	}
  }
}
]=]
local function parse_override(segments, parse_err)
	local part = segments[1]
	local slots = {}
	local defslot
	while true do
		local this_defslot
		if part:find("^def") then
			this_defslot = true
			part = usub(part, 4)
		else
			this_defslot = false
		end
		if defslot == nil then
			defslot = this_defslot
		elseif defslot ~= this_defslot then
			parse_err(("When multiple slot overrides are combined with +, all must be definite or indefinite: '%s'"):
			format(concat(segments)))
		end
		local case = usub(part, 1, 3)
		if case_set[case] then
			-- ok
		else
			parse_err(("Unrecognized case '%s' in override: '%s'"):format(case, concat(segments)))
		end
		part = usub(part, 4)
		local slot = defslot and "def_" or ""
		if part:find("^pl") then
			part = usub(part, 3)
			slot = slot .. case .. "_p"
		else
			slot = slot .. case .. "_s"
		end
		insert(slots, slot)
		if part:find("^%+") then
			part = usub(part, 2)
		else
			break
		end
	end
	segments[1] = part
	local retval = fetch_slot_override(segments, ("%s slot override"):format(concat(slots, "+")), false, defslot,
		parse_err)
	return slots, retval
end


local function fetch_specs(errdesc, separated_group, outer_separated_group, parse_err, parse_paren_spec)
	if not separated_group then
		return nil
	end
	local specs = {}
	
	local function this_parse_err(msg)
		local inner_spec = concat(separated_group)
		local outer_spec = concat(outer_separated_group)
		local specmsg
		if inner_spec == outer_spec then
			specmsg = ("in '%s'"):format(inner_spec)
		else
			specmsg = ("in '%s' in containing spec '%s'"):format(inner_spec, outer_spec)
		end
		parse_err(("%s in %s spec: %s"):format(msg, errdesc, specmsg))
	end

	local colon_separated_groups = split_alternating_runs_with_escapes(separated_group, ":")
	for _, colon_separated_group in ipairs(colon_separated_groups) do
		local form = colon_separated_group[1]
		local footnotes, paren_spec = fetch_footnotes_and_paren_spec(
			errdesc, colon_separated_group, this_parse_err, not not parse_paren_spec)
		if paren_spec then
			paren_spec = parse_paren_spec(paren_spec, this_parse_err)
		end
		insert(specs, {form = form, footnotes = footnotes, paren_spec = paren_spec})
	end
	return specs
end

local function parse_verb_class(delim_separated_group, parse_err)
	return fetch_specs("verb class", delim_separated_group, delim_separated_group, parse_err)
end

local function parse_sg_pl_spec(errdesc, comma_separated_group, delim_separated_group, parse_err, parse_sg_paren_spec,
	parse_pl_paren_spec)
	local pound_separated_groups = split_alternating_runs_with_escapes(comma_separated_group, "#")
	if #pound_separated_groups > 2 then
		parse_err(("At most two pound-separated specs allowed for %s (singular and plural), but saw %s"):format(
			errdesc, #pound_separated_groups
		))
	end
	local sgspecs = fetch_specs(errdesc .. " singular", pound_separated_groups[1], delim_separated_group, parse_err,
		parse_sg_paren_spec)
	local plspecs = fetch_specs(errdesc .. " plural", pound_separated_groups[2], delim_separated_group, parse_err,
		parse_pl_paren_spec)
	return {singular = sgspecs, plural = plspecs}
end

local function parse_tense_spec(errdesc, delim_separated_group, parse_err, parse_sg_indic_paren_spec,
	parse_pl_indic_paren_spec, parse_sg_subj_paren_spec, parse_pl_subj_paren_spec)
	local comma_separated_groups = split_alternating_runs_with_escapes(delim_separated_group, ",")
	if #comma_separated_groups > 2 then
		parse_err(("At most two comma-separated specs allowed for %s tense (indicative and subjunctive), but saw %s"):
			format(errdesc, #comma_separated_groups))
	end
	local indicspecs = parse_sg_pl_spec(errdesc .. " indicative", comma_separated_groups[1], delim_separated_group,
		parse_err, parse_sg_indic_paren_spec, parse_pl_indic_paren_spec)
	local subjspecs = parse_sg_pl_spec(errdesc .. " subjunctive", comma_separated_groups[2], delim_separated_group,
		parse_err, parse_sg_subj_paren_spec, parse_pl_subj_paren_spec)
	return {indicative = indicspecs, subjunctive = subjspecs}
end

local function parse_present_spec(delim_separated_group, parse_err)
	return parse_tense_spec("present", delim_separated_group, parse_err)
end

local function fetch_subjunctive_umlaut_spec(numberdesc, separated_group, delim_separated_group, parse_err)
	return fetch_specs(("past subjunctive %s umlaut"):format(numberdesc), separated_group, delim_separated_group,
		parse_err)
end

local function parse_past_spec(delim_separated_group, parse_err)
	local function make_fetch_subjunctive_umlaut_spec(numberdesc)
		return function(separated_group, parse_err)
			return fetch_subjunctive_umlaut_spec(numberdesc, separated_group, delim_separated_group, parse_err)
		end
	end
	return parse_tense_spec("past", delim_separated_group, parse_err, make_fetch_subjunctive_umlaut_spec("singular"),
		make_fetch_subjunctive_umlaut_spec("plural"))
end

local function parse_past_participle_spec(delim_separated_group, parse_err)
	local comma_separated_groups = split_alternating_runs_with_escapes(delim_separated_group, ",")
	if #comma_separated_groups > 2 then
		parse_err("At most two comma-separated specs allowed for parse-participle/supine spec, but saw " ..
			#comma_separated_groups)
	end
	local function parse_pp_adj_spec(separated_group, parse_err)
		error("Past participle adjective spec parsing not implemented yet")
	end
	local ppspecs = fetch_specs("past participle", comma_separated_groups[1], delim_separated_group, parse_err,
		parse_pp_adj_spec)
	local supspecs = fetch_specs("supine", comma_separated_groups[2], delim_separated_group, parse_err)
	return ppspecs, supspecs
end

local function parse_inside(base, inside, is_scraped_verb, is_middle)
	-- See escaped_error() for `error_depth`.
	local function parse_err(msg, error_depth)
		escaped_error((is_scraped_verb and "Error processing scraped verb spec: " or "") .. msg .. ": <" ..
			inside .. ">", (error_depth or 0) + 1)
	end
	-- See escaped_error() for `error_depth`.
	local function interr(msg, error_depth)
		escaped_error("Internal error: " .. msg .. ": <" .. inside .. ">; base table follows: " .. dump(base),
			(error_depth or 0) + 1)
	end

	local segments = put.parse_multi_delimiter_balanced_segment_run(inside, {{"[", "]"}, {"(", ")"}})
	local dot_separated_groups = split_alternating_runs_with_escapes(segments, "%.")
	for i, dot_separated_group in ipairs(dot_separated_groups) do
		local part = dot_separated_group[1]
		while true do
			if i == 1 and not part:find("^@") and part ~= "builtin" and (not is_middle or part:find("[;/\\]")) then
				local delim_separated_groups = split_alternating_runs_with_escapes(dot_separated_group, "[;/\\]", true)
				local nextspec = nil
				local seen_pres, seen_past, seen_pp = false, false, false
				for j, delim_separated_group in ipairs(delim_separated_groups) do
					-- See escaped_error() for `error_depth`.
					local function this_parse_err(msg, error_depth)
						parse_err(("%s: '%s'"):format(msg, concat(delim_separated_group)), (error_depth or 0) + 1)
					end

					if j == 1 then
						-- Here and in parsing subfunctions below, pass in parse_err() not this_parse_err() because the
						-- function itself includes the appropriate spec in the error message, similar to how
						-- this_parse_err() operates.
						base.class = parse_verb_class(delim_separated_group, parse_err)
					elseif j % 2 == 0 then
						local delim = delim_separated_group[1]
						if delim == ";" then
							if seen_pres then
								this_parse_err("Principal part spec should have only one present-tense spec (indicated with semicolon)")
							end
							seen_pres = true
							nextspec = "pres"
							if seen_past or seen_pp then
								this_parse_err("Present spec (indicated with semicolon) cannot follow past or past-participle spec")
							end
						elseif delim == "\\" then
							if seen_past then
								this_parse_err("Principal part spec should have only one past-tense spec (indicated with backslash)")
							end
							seen_past = true
							nextspec = "past"
							if seen_pp then
								this_parse_err("Past spec (indicated with backslash) cannot follow past-participle spec")
							end
						elseif delim == "/" then
							if seen_pp then
								this_parse_err("Principal part spec should have only one past-participle spec (indicated with slash)")
							end
							seen_pp = true
							nextspec = "pp"
						else
							interr(("Unrecognized delimiter %s at position %s, delim_separated_groups=%s"):format(
								delim, j, dump(delim_separated_groups)
							))
						end
					elseif nextspec == "pres" then
						-- See parse_verb_class call above for why we use parse_err not this_parse_err.
						base.pres = parse_present_spec(delim_separated_group, parse_err)
					elseif nextspec == "past" then
						-- See parse_verb_class call above for why we use parse_err not this_parse_err.
						base.past = parse_past_spec(delim_separated_group, parse_err)
					elseif nextspec == "pp" then
						-- See parse_verb_class call above for why we use parse_err not this_parse_err.
						base.pp, base.supine = parse_past_participle_spec(delim_separated_group, parse_err)
					else
						interr(("Unrecognized `nextspec` value %s at position %s, delim_separated_groups=%s"):format(
							dump(nextspec), j, dump(delim_separated_groups)
						))
					end
				end
				break
			elseif part == "" then
				if not dot_separated_group[2] then
					parse_err("Blank indicator; not allowed without attached footnotes")
				end
				base.footnotes = fetch_footnotes_and_paren_spec(dot_separated_group, parse_err)
				break
			elseif part == "addnote" then
				local spec_and_footnotes = fetch_footnotes_and_paren_spec(dot_separated_group, parse_err)
				if #spec_and_footnotes < 2 then
					parse_err("Spec with 'addnote' should be of the form 'addnote[SLOTSPEC][FOOTNOTE][FOOTNOTE][...]'")
				end
				local slot_spec = table.remove(spec_and_footnotes, 1)
				local slot_spec_inside = umatch(slot_spec, "^%[(.*)%]$")
				if not slot_spec_inside then
					parse_err("Internal error: slot_spec " .. slot_spec .. " should be surrounded with brackets")
				end
				local slot_specs = usplit(slot_spec_inside, ",")
				-- FIXME: Here, [[Module:it-verb]] called strip_spaces(). Generally we don't do this. Should we?
				insert(base.addnote_specs, { slot_specs = slot_specs, footnotes = spec_and_footnotes })
				break
			elseif ulen(part) > 3 and case_set[usub(part, 1, 3)] or (
					ulen(part) > 6 and usub(part, 1, 3) == "def" and case_set[usub(part, 4, 6)]) then
				local slots, override = parse_override(dot_separated_group, parse_err)
				for _, slot in ipairs(slots) do
					if base.overrides[slot] then
						error(("Two overrides specified for slot '%s'"):format(slot))
					else
						base.overrides[slot] = override
					end
				end
				break
			end
			if #dot_separated_group > 1 then
				parse_err(
					("Footnotes only allowed with slot overrides, negatable indicators and by themselves: '%s'"):
					format(concat(dot_separated_group)))
			elseif (part:find("^decllemma%s*:") or part:find("^declgender%s*:") or
					part:find("^declnumber%s*:")) then
				local field, value = part:match("^(decl[a-z]+)%s*:%s*(.+)$")
				if not value then
					parse_err(("Syntax error in decllemma/declgender/declnumber indicator: '%s'"):format(part))
				end
				if base[field] then
					parse_err(("Can't specify '%s:' twice"):format(field))
				end
				base[field] = value
				break
			elseif part:find("^q%s*:") or part:find("header%s*:") then
				local field, value = part:match("^(q)%s*:%s*(.+)$")
				if not value then
					field, value = part:match("^(header)%s*:%s*(.+)$")
				end
				if not value then
					parse_err(("Syntax error in q/header indicator: '%s'"):format(part))
				end
				if base[field] then
					parse_err(("Can't specify '%s:' twice"):format(field))
				end
				base[field] = value
				break
			elseif part:find("^@") then
				-- FIXME: Implement adjective scraping
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
				local scrape_init, scrape_rest = umatch(base.scrape_spec, "^(.)(.*)$")
				local lower_scrape_init = ulower(scrape_init)
				if ulower(scrape_init) ~= scrape_init then
					base.scrape_is_uppercase = true
					base.scrape_spec = lower_scrape_init .. scrape_rest
				end
				break
			elseif part:find(":") then
				local spec, value = part:match("^([a-z]+)%s*:%s*(.+)$")
				if not spec then
					parse_err(("Syntax error in indicator with value, expecting alphabetic slot or stem/lemma " ..
						"override indicator: '%s'"):format(part))
				end
				local stem_set = overridable_stem_set
				if not stem_set[spec] then
					parse_err(("Unrecognized stem override indicator '%s', should be %s"):format(
						part, generate_list_of_possibilities_for_err(overridable_stems)))
				end
				if base[spec] then
					if spec == "stem" then
						parse_err("Can't specify spec for 'stem:' twice (including using 'stem:' along with # or ##)")
					else
						parse_err(("Can't specify '%s:' twice"):format(spec))
					end
				end
				base[spec] = value
				break
			elseif part == "sg" or part == "pl" or part == "both" then
				if base.number then
					if base.number ~= part then
						parse_err("Can't specify '" .. part .. "' along with '" .. base.number .. "'")
					else
						parse_err("Can't specify '" .. part .. "' twice")
					end
				end
				base.number = part
				break
			elseif part == "indef" or part == "def" or part == "bothdef" then
				if base.definiteness then
					if base.definiteness ~= part then
						parse_err(("Can't specify two conflicting definiteness values; saw '%s' (%s) when existing " ..
							"definiteness is %s"):format(part, definiteness_code_to_desc[part],
							definiteness_code_to_desc[base.definiteness]))
					else
						parse_err("Can't specify '" .. part .. "' twice")
					end
				end
				base.definiteness = part
				break
			elseif part == "weak" or part == "iending" or part == "rstem" or part == "já" or
					part == "linkasis" or
				part == "proper" or part == "common" or part == "dem" or part == "builtin" or part == "indecl" or
				part == "decl?" then
				if base.props[part] then
					parse_err("Can't specify '" .. part .. "' twice")
				end
				base.props[part] = true
				break
			elseif part == "~" then
				if base.link_lowercase then
					parse_err("Can't specify '~' twice")
				end
				base.link_lowercase = true
				break
			end
			parse_err("Unrecognized indicator '" .. part .. "'")
		end
	end

	return base
end


-- Set some defaults (e.g. number and definiteness) now, because they (esp. the number) may be needed
-- below when determining how to merge scraped and user-specified properies.
local function set_early_base_defaults(base)
	if is_regular_noun(base) then
		local function check_err(msg)
			error(("Lemma '%s': %s"):format(base.lemma, msg))
		end

		if not base.gender then
			check_err("Internal error: For nouns, gender must be specified")
		end
		base.number = base.number or is_proper_noun(base, base.lemma) and "sg" or base.gender == "m" and
			(base.lemma:find("skapur$") or base.lemma:find("naður$")) and not base.stem and "sg" or "both"
		base.definiteness = base.definiteness or is_proper_noun(base, base.lemma) and "indef" or "bothdef"
		process_declnumber(base)
		base.actual_gender = base.gender
		if base.declgender then
			if not base.declgender:find("^[mfn]$") then
				check_err(("Unrecognized gender '%s' for 'declgender:', should be 'm', 'f' or 'n'"):format(
					base.declgender))
			end
			base.gender = base.declgender
		end
	end
end

local function parse_inside_and_merge(inside, lemma, scrape_chain)
	local function parse_err(msg)
		error(msg .. ": <" .. inside .. ">")
	end

	if #scrape_chain >= 10 then
		local linked_scrape_chain = {}
		for _, element in ipairs(scrape_chain) do
			insert(linked_scrape_chain, "[[" .. element .. "]]")
		end
		parse_err(("Probable infinite loop in scraping; scrape chain is [[%s]] -> %s"):format(lemma,
			concat(linked_scrape_chain, " -> ")))
	end

	local base = create_base()
	base.lemma = lemma
	base.scrape_chain = scrape_chain
	parse_inside(base, inside, #scrape_chain > 0)

	if not base.scrape_spec then
		-- If we're not scraping the declension from another noun, just return the parsed `base`.
		-- But don't set early defaults if we're being scraped because it interferes with overriding the number
		-- and/or definiteness by the noun that is scraping us.
		if #scrape_chain == 0 then
			set_early_base_defaults(base)
		end
		return base
	else
		local retval = com.find_inflection_given_scrape_spec {
			lemma = lemma,
			scrape_spec = base.scrape_spec,
			scrape_is_suffix = base.scrape_is_suffix,
			scrape_is_uppercase = base.scrape_is_uppercase,
			infltemp = "is-ndecl",
			allow_empty_infl = false,
			inflid = base.scrape_id,
			parse_off_ending = com.parse_off_final_nom_ending,
		}
		local prefix, base_noun, declspec, errmsg = retval.prefix, retval.base_lemma, retval.infl, retval.errmsg
		if errmsg then
			base.prefix = prefix
			base.base_noun = base_noun
			base.scrape_error = errmsg
			return base
		end

		-- Parse the inside spec from the scraped noun (merging any sub-scraping specs), and copy over the
		-- user-specified properties on top of it.
		insert(scrape_chain, base_noun)
		local inner_base = parse_inside_and_merge(declspec.infl, base_noun, scrape_chain)
		inner_base.lemma = lemma
		inner_base.prefix = prefix
		inner_base.base_noun = base_noun

		-- Add `prefix` to a full variant of the base noun (e.g. a stem spec or full override). We may need
		-- to adjust the variant to take into account the base noun being a suffix and/or uppercase (e.g. when
		-- we use [[-dómur]] to generate the inflection of [[vísdómur]] or [[Björn]] to generate the inflection
		-- of [[Ásbjörn]]).
		local function add_prefix(form)
			if base.scrape_is_suffix then
				form = form:gsub("^%-", "")
			end
			if base.scrape_is_uppercase then
				local first, rest = umatch(form, "^(.)(.*)$")
				if first then
					form = ulower(first) .. rest
				end
			end
			return prefix .. form
		end

		-- If there's a prefix, add it now to all the full overrides in the scraped noun, as well as 'decllemma'
		-- and all stem overrides.
		if prefix ~= "" then
			map_all_overrides(inner_base, function(formobj)
				-- Not if the override contains # or ##, which expand to the full lemma (possibly minus -r
				-- or -ur).
				if formobj.form:find("^!") and not formobj.form:find("#") then
					formobj.form = "!" .. add_prefix(usub(formobj.form, 2))
				end
			end)
			if inner_base.decllemma then
				inner_base.decllemma = add_prefix(inner_base.decllemma)
			end
			for _, stem in ipairs(overridable_stems) do
				-- Only actual stems, not imutval; and not if the stem contains # or ##, which
				-- expand to the full lemma (possibly minus -r or -ur).
				if inner_base[stem] and stem:find("stem$") and not inner_base[stem]:find("#") then
					inner_base[stem] = add_prefix(inner_base[stem])
				end
			end
		end

		local function copy_properties(plist)
			-- Copy various properties.
			for _, prop in ipairs(plist) do
				if base[prop] ~= nil then
					inner_base[prop] = base[prop]
				end
			end
		end
		copy_properties(control_specs)
		copy_properties(overridable_stems)
		copy_properties { "gens", "pls", "gender", "number", "definiteness", "decllemma", "declgender", "declnumber",
			"q", "header", "link_lowercase" }
		inner_base.footnotes = iut.combine_footnotes(inner_base.footnotes, base.footnotes)
		-- Copy addnote specs.
		for _, prop_list in ipairs { "addnote_specs" } do
			for _, prop in ipairs(base[prop_list]) do
				m_insertIfNot(inner_base[prop_list], prop)
			end
		end
		-- Now copy remaining user-specified specs into the scraped noun `base`.
		for _, prop_table in ipairs { "overrides", "props" } do
			for slot, prop in pairs(base[prop_table]) do
				inner_base[prop_table][slot] = prop
			end
		end
		-- Now determine the defaulted number and definiteness (after copying relevant settings
		-- but before the check just below that relies on `inner_base.number` being set).
		set_early_base_defaults(inner_base)
		-- If user specified 'sg', cancel out any pl overrides, otherwise we'll get an error.
		if inner_base.number == "sg" then
			inner_base.pls = nil
			for slot, _ in pairs(inner_base.overrides) do
				if slot:find("_p$") then
					inner_base.overrides[slot] = nil
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
	local inside = umatch(angle_bracket_spec, "^<(.*)>$")
	assert(inside)
	local orig_lemma = lemma
	local orig_lemma_no_links = m_links.remove_links(lemma)
	lemma = orig_lemma_no_links
	local base = parse_inside_and_merge(inside, lemma, {})
	base.orig_lemma = orig_lemma
	base.orig_lemma_no_links = orig_lemma_no_links
	return base
end


-- Determine if the term has more than one word in it. Normally we just look at the number of words
-- at top level. However, it's possible to have a single alternant at top level with multiple words
-- in one of the arms, e.g. the equivalent of ((rēspūblica<>,rēs<>pūblica<>)). So if there's only one
-- top-level "word" and it's an alternant, check the length of each arm. We also need to check for
-- before-text and post-text if there's only one inflected term.
local function compute_is_multiword(alternant_multiword_spec)
	if #alternant_multiword_spec.alternant_or_word_specs > 1 or alternant_multiword_spec.post_text ~= "" then
		return true
	end
	local alternant_or_word_spec = alternant_multiword_spec.alternant_or_word_specs[1]
	if alternant_or_word_spec.alternants then
		for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
			if #multiword_spec > 1 or multiword_spec.post_text ~= "" or
				multiword_spec[1] and multiword_spec[1].before_text ~= "" then
				return true
			end
		end
	end
	if alternant_or_word_spec.before_text ~= "" then
		return true
	end
	return false
end


local function set_defaults_and_check_bad_indicators(base)
	local function check_err(msg)
		error(("Lemma '%s': %s"):format(base.lemma, msg))
	end
	-- Set default values.
	local regular_noun = is_regular_noun(base)
	if not base.adjspec and base.props.builtin then
		set_builtin_defaults(base)
	end

	if not regular_noun and not base.adjspec then
		for _, control_spec in ipairs(control_specs) do
			if base[control_spec] then
				check_err(("'%s' cannot be specified with pronouns"):format(control_spec))
			end
		end
	end
	if not regular_noun then
		if base.declgender then
			check_err("'declgender' can only be specified with regular nouns")
		end
		return
	end

	-- Check for bad indicator combinations.
	if base.imut and base.unimut then
		check_err("'imut' and 'unimut' specs cannot be specified together")
	end
	if base.umut and base.unumut then
		check_err("'umut' and 'unumut' specs cannot be specified together")
	end
	if base.unimut and base.unumut then
		check_err("'unimut' and 'unumut' specs cannot be specified together")
	end

	if base.declnumber == "pl" and (base.gens or base.pls) then
		check_err("Cannot set genitive or plural specs after the gender in plural-only lemmas")
	end

	if base.plvstem and not base.plstem then
		check_err("When 'plvstem:' given, 'plstem:' must also be given")
	end

	-- Compute whether i-mutation stems are needed.

	-- First check for 'imut' set by user.
	if not base.need_imut then -- might be set by the detected declension
		if base.imut then
			for _, formobj in ipairs(base.imut) do
				if formobj.form == "imut" then
					base.need_imut = true
					break
				end
			end
		end
	end

	-- Then check for 'unimut' set by user.
	if not base.need_imut then
		if base.unimut then
			for _, formobj in ipairs(base.unimut) do
				if formobj.form == "unimut" then
					base.need_imut = true
					break
				end
			end
		end
	end

	-- Then check all overrides for any beginning with a single ^.
	if not base.need_imut then
		map_all_overrides(base, function(formobj)
			if formobj.form:find("^%^") and not formobj.form:find("^%^%^") then
				base.need_imut = true
				return true
			end
		end)
	end

	if base.imutval and not base.need_imut then
		check_err("'imutval:...' specified but 'imut' and 'unimut' not specified and no forms need i-mutation")
	end
end


local function set_all_defaults_and_check_bad_indicators(alternant_multiword_spec)
	-- Used when determining how to link definite-only and plural-only nouns.
	alternant_multiword_spec.is_multiword = compute_is_multiword(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		base.is_multiword = alternant_multiword_spec.is_multiword
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
		if base.props.builtin then
			alternant_multiword_spec.saw_builtin = true
		else
			alternant_multiword_spec.saw_non_builtin = true
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
	end)
end


local function expand_property_sets(base)
	base.prop_sets = { {} }

	-- Construct the prop sets from all combinations of control specs, in case any given spec has more than one
	-- possibility.
	for _, control_spec in ipairs(control_specs) do
		local specvals = base[control_spec]
		-- Handle unspecified control specs.
		if not specvals then
			specvals = { false }
		end
		if #specvals == 1 then
			for _, prop_set in ipairs(base.prop_sets) do
				-- Convert 'false' back to nil
				prop_set[control_spec] = specvals[1] or nil
			end
		else
			local new_prop_sets = {}
			for _, prop_set in ipairs(base.prop_sets) do
				for _, specval in ipairs(specvals) do
					local new_prop_set = m_table.shallowCopy(prop_set)
					new_prop_set[control_spec] = specval
					insert(new_prop_sets, new_prop_set)
				end
			end
			base.prop_sets = new_prop_sets
		end
	end
end


local function determine_default_u_mutation(base)
end

local function not_if_no_pres_indic_sg(data)
	if formobj_list_has_hyphen(data.base.pres.indicative.singular) then
		return nil
	end
	return "+"
end

-- This applies equally for the indicative and subjunctive.
local function apply_umut_to_stem(data, stem, existing_footnotes)
	local values = {}
	for _, umut_spec in ipairs(data.base.default_umut_specs) do
		iut.insert_form(values, {
			form = umut_spec.form:find("^%-") and stem or com.apply_u_mutation(stem, umut_spec.form),
			footnotes = iut.combine_footnotes(existing_footnotes, umut_spec.footnotes),
		})
	end
	return values
end

local function generate_default_pres_1pl(data)
	return apply_umut_to_stem(data, data.base.infstem)
end

-- This applies equally for the indicative and subjunctive.
local function process_explicit_pres_2pl(data, value)
	-- The explicit form given is the pres 1pl. We need to derive the 2pl from it by undoing any u-mutation if
	-- appropriate. This is tricky because we don't want to undo u-mutation in a verb like glöggva where the ö
	-- is part of the stem, so we only do it if the last vowel of the infinitive stem is a.
	local inf_u_mutatable = not not ufind(data.base.infstem, "[Aa]" .. com.cons_c .. "*$")
	return remove_j_before_i(inf_u_mutatable and com.apply_reverse_u_mutation(value, "unumut") or value)
end

-- This applies equally for the indicative and subjunctive.
local function generate_default_pres_2pl(data)
	return {
		form = remove_j_before_i(data.base.infstem),
	}
end

local function not_if_no_past_indic_sg(data)
	if formobj_list_has_hyphen(data.base.past.indicative.singular) then
		return nil
	end
	return "+"
end

local function form_default_dental_suffixed_stem(data, stem)
	stem = remove_jv_before_non_vowel(stem)
	local begin, final_cluster = umatch(stem, "^(.-)(" .. com.cons_c .. "*)$")
	local cluster_with_dental = add_dental_suffix(final_cluster)
	if not cluster_with_dental then
		data.err(("Unrecognized final cluster '%s' in stem '%s'"):format(final_cluster, stem))
	end
	if cluster_with_dental[1] == "-" then
		table.remove(cluster_with_dental, 1)
		for i, cl in ipairs(cluster_with_dental) do
			cluster_with_dental[i] = "'" .. cl .. "'"
		end
		data.err(("Cluster '%s' has no default in stem '%s', specify explicitly; normal dental-suffixed clusters are %s"):format(
			final_cluster, stem, mw.text.listToText(cluster_with_dental)))
	end
	return begin .. cluster_with_dental[1]
end

local function apply_parenthesized_umlaut_spec(data, values_to_insert_into, stemobjs, default_umlaut_spec)
	for _, stemobj in ipairs(stemobjs) do
		local paren_spec = stemobj.paren_spec or {{form = default_umlaut_spec}}
		for _, umlautobj in ipairs(paren_spec) do
			local umform = umlautobj.form
			if umform ~= "^" and umform ~= "-^" and not ufind(umform, "[^Jj]?" .. com.vowel_c .. "$") and
				not umform:find("^[Ee][iIyY]$") and not umform:find("^[Aa][Uu]$") then
				data.err(("Invalid parenthesized subjunctive umlaut spec '%s'; should be ^, -^, a dipthong or a vowel optionally preceded by j"):format(
					umform))
			end
			local substem = umform == "-^" and stemobj.form or com.apply_i_mutation(stemobj.form,
				umform ~= "^" and umform or nil, false, not not stemobj.paren_spec)
			iut.insert_form_into_list(values_to_insert_into, {
				form = substem,
				footnotes = iut.combine_footnotes(stemobj.footnotes, umlautobj.footnotes),
			})
		end
	end
end

local principal_part_stem_conjugations = {
	{"inf", {
		desc = "infinitive",
		...,
	}},
	{"pres_indic_sg", {
		desc = "present indicative singular",
		explicit_part = function(data) return data.base.pres.indicative.singular end,
		process_explicit = function(data, value)
			local ending
			if value:find("a$") then
				value = value:gsub("a$", "")
				ending = "a"
			elseif value:find("i$") and not value:find("ei$") then
				value = value:gsub("i$", "")
				ending = "i"
			else
				ending = ""
			end
			return {
				form = value,
				ending = ending,
			}
		end,
		generate_default = function(data)
			local class = data.verbclass
			if class:find("^s") or class == "w1" then
				local stem = remove_jv_before_non_vowel(data.base.infstem)
				return {
					form = com.apply_i_mutation(stem),
					ending = "",
				}
			elseif class == "w2" or class == "w3" then
				return {
					form = remove_j_before_i(data.base.infstem),
					ending = "i",
				}
			elseif class == "w4" then
				return {
					form = data.base.infstem,
					ending = "a",
				}
			else
				data.interr(("Unrecognized verb class: %s"):format(class))
			end
		end,
		conjugate = function(data, stemobj)
			local s2, s3
			local ending = stemobj.ending
			if ending == "i" or ending == "a" then
				s2 = ending .. "r"
				s3 = s2
			else
				local stem = stemobj.form
				if ufind(stem, com.vowel_c .. "$") then
					s2 = "rð"
					s3 = "r"
				elseif stem:find("r$") then
					s2 = "ð"
					s3 = ""
				elseif stem:find("s$") then
					s2 = "t"
					s3 = ""
				elseif stem:find("x$") or stem:find("ín$") then
					-- Einarsson says all singular endings after -n are null, but that only seems to apply to strong 1
					-- verbs. Strong 3 verbs in -nn have -ur, -ur, as do weak 1 verbs in -nja.
					s2 = ""
					s3 = ""
				else
					s2 = "ur"
					s3 = "ur"
				end
			end
			add_personal_tense(data, "pres", stemobj, ending, s2, s3)
		end,
	}},
	{"pres_indic_1pl", {
		desc = "first-person plural present indicative",
		explicit_part = function(data) return data.base.pres.indicative.plural end,
		process_explicit = function(data, value)
			return value
		end,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = generate_default_pres_1pl,
		conjugate = function(data, stemobj)
			add(data, "pres1p", stemobj, "um")
		end,
	}},
	{"pres_indic_2pl", {
		desc = "second-person plural present indicative",
		explicit_part = function(data) return data.base.pres.indicative.plural end,
		process_explicit = process_explicit_pres_2pl,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = generate_default_pres_2pl,
		conjugate = function(data, stemobj)
			add(data, "pres2p", stemobj, "ið")
		end,
	}},
	{"pres_indic_3pl", {
		desc = "third-person plural present indicative",
		explicit_part = function(data) return nil end,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = function(data)
			return {
				form = data.base.lemma,
			}
		end,
		conjugate = function(data, stemobj)
			add(data, "pres3p", stemobj, "")
		end,
	}},
	{"pres_subj_sg", {
		desc = "present subjunctive singular",
		explicit_part = function(data) return data.base.pres.subjunctive.singular end,
		process_explicit = function(data, value)
			local stem = value:match("^(.*)i$")
			if not stem then
				data.err(("Value for first-person singular '%s' should end in -i"):format(value))
			end
			return stem
		end,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = function(data)
			return {
				form = remove_j_before_i(data.base.infstem),
			}
		end,
		conjugate = function(data, stemobj)
			add_personal_tense(data, "pressub", stemobj, "i", "ir", "i")
		end,
	}},
	{"pres_subj_1pl", {
		desc = "first-person plural present subjunctive",
		explicit_part = function(data) return data.base.pres.subjunctive.plural end,
		process_explicit = function(data, value)
			return value
		end,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = generate_default_pres_1pl,
		conjugate = function(data, stemobj)
			add(data, "pressub1p", stemobj, "um")
		end,
	}},
	{"pres_subj_2pl", {
		desc = "second-person plural present subjunctive",
		explicit_part = function(data) return data.base.pres.subjunctive.plural end,
		process_explicit = process_explicit_pres_2pl,
		default_if_unspecified = not_if_no_pres_indic_sg,
		generate_default = generate_default_pres_2pl,
		conjugate = function(data, stemobj)
			add(data, "pressub2p", stemobj, "ið")
			add(data, "pressub3p", stemobj, "i")
		end,
	}},
	{"past_indic_sg", {
		desc = "past indicative singular",
		explicit_part = function(data) return data.base.past.indicative.singular end,
		process_explicit = function(data, value)
			local stem = value:match("^(.*[^e])i$")
			if stem then
				return {
					form = stem,
					ending = "i",
				}
			else
				return {
					form = value,
					ending = "",
				}
			end
		end,
		generate_default = function(data)
			if data.verbclass:find("^s") then
				data.err("For strong verbs, this principal part must be given explicitly")
			end
			local dental_stem
			if data.verbclass == "w4" then
				dental_stem = data.base.infstem .. "að"
			else
				local past_base_stem
				if data.verbclass == "w1" and data.base.infstem:find("j$") then
					past_base_stem = com.apply_reverse_i_mutation(data.base.infstem, nil, false, false)
				else
					past_base_stem = data.base.infstem
				end
				dental_stem = form_default_dental_suffixed_stem(data, data.base.infstem)
			end
			return {
				form = dental_stem,
			}
		end,
	}},
	{"past_indic_pl", {
		desc = "past indicative plural",
		explicit_part = function(data) return data.base.past.indicative.plural end,
		process_explicit = function(data, value)
			local stem = value:match("^(.*)um$")
			if not stem then
				data.err(("Value for first-person plural '%s' should end in -um"):format(value))
			end
			return stem
		end,
		default_if_unspecified = not_if_no_past_indic_sg,
		generate_default = function(data)
			local values = {}
			-- If the past indicative singular was given as -, `base.stems.past_indic_sg` will be nil, but we should
			-- never encounter this because of `default_if_unspecified`.
			for _, formobj in ipairs(data.base.stems.past_indic_sg) do
				local form = formobj.form
				if formobj.ending == "" then
					data.err(("Cannot generate past indicative plural default from explicit strong singular '%s'; specify the plural explicitly as well"):format(
						form
					))
				end
				local weak_4_stem = form:match("^(.*)að$")
				if weak_4_stem then
					local umut_stems = apply_umut_to_stem(data, weak_4_stem, formobj.footnotes)
					for _, umut_stem in ipairs(umut_stems) do
						umut_stem.form = umut_stem.form .. "uð"
						iut.insert_form_into_list(values, umut_stem)
					end
				else
					iut.insert_forms_into_list(values, apply_umut_to_stem(data, form, formobj.footnotes))
				end
			end
			return values
		end,
	}},
	{"past_subj_sg", {
		desc = "past subjunctive singular",
		explicit_part = function(data) return data.base.past.subjunctive.singular end,
		process_explicit = function(data, value)
			local stem = value:match("^(.*)i$")
			if not stem then
				data.err(("Value for first-person singular '%s' should end in -i"):format(value))
			end
			return stem
		end,
		default_if_unspecified = not_if_no_past_indic_sg,
		generate_default = function(data)
			local values = {}
			if data.verbclass:find("^s") then
				local past_pl_stems = data.base.stems.past_indic_pl
				if not past_pl_stems then
					return nil
				end
				-- Strong verbs use the past indicative plural stem to form the subjunctive singular, always umlauted if
				-- possible. There is no need to undo u-mutation because there aren't any strong verbs with u-mutation
				-- in the past indicative plural. There is also no need to drop a final -j- because no verbs have a -j-
				-- in the past indicative.
				apply_parenthesized_umlaut_spec(data, values, past_pl_stems, "^")
			else
				local past_sg_stems = data.base.stems.past_indic_sg
				if not past_sg_stems then
					return nil
				end
				-- Weak verbs use the past indicative singular to form the subjunctive singular, by default umlauted if
				-- weak 1 and not otherwise (although there are some weak-3 verbs with subjunctive umlaut). This avoids
				-- the need to undo u-mutation in the plural, which does exist for some verbs, and there are several
				-- irregular weak verbs where the singular and plural past indicative use different stems, with the same
				-- irregularity duplicated in the subjunctive singular and plural. An example is frýja, which is weak 4
				-- or weak 1 in the present indicative singular (frýja or frý) and past singular (frýjaði or frýði, the
				-- latter in place of expected *frúði), with past plural only frýjuðum.
				apply_parenthesized_umlaut_spec(data, values, past_sg_stems, data.verbclass == "w1" and "^" or "-^")
			end
			return values
		end,
	}},
	{"past_subj_pl", {
		desc = "past subjunctive plural",
		explicit_part = function(data) return data.base.past.subjunctive.plural end,
		process_explicit = function(data, value)
			local stem = value:match("^(.*)um$")
			if not stem then
				data.err(("Value for first-person plural '%s' should end in -um"):format(value))
			end
			return stem
		end,
		default_if_unspecified = not_if_no_past_indic_sg,
		generate_default = function(data)
			local values = {}
			if data.verbclass:find("^s") then
				local past_pl_stems = data.base.stems.past_indic_pl
				if not past_pl_stems then
					return nil
				end
				-- Strong verbs use the past indicative plural stem to form the subjunctive singular, always umlauted if
				-- possible. There is no need to undo u-mutation because there aren't any strong verbs with u-mutation
				-- in the past indicative plural. There is also no need to drop a final -j- because no verbs have a -j-
				-- in the past indicative.
				apply_parenthesized_umlaut_spec(data, values, past_pl_stems, "^")
			else
				local past_sg_stems = data.base.stems.past_indic_sg
				if not past_sg_stems then
					return nil
				end
				-- Weak verbs use the past indicative singular to form the subjunctive singular, by default umlauted if
				-- weak 1 and not otherwise (although there are some weak-3 verbs with subjunctive umlaut). This avoids
				-- the need to undo u-mutation in the plural, which does exist for some verbs, and there are several
				-- irregular weak verbs where the singular and plural past indicative use different stems, with the same
				-- irregularity duplicated in the subjunctive singular and plural. An example is frýja, which is weak 4
				-- or weak 1 in the present indicative singular (frýja or frý) and past singular (frýjaði or frýði, the
				-- latter in place of expected *frúði), with past plural only frýjuðum.
				apply_parenthesized_umlaut_spec(data, values, past_sg_stems, data.verbclass == "w1" and "^" or "-^")
			end
			return values
		end,
	}},
}


-- Determine the stems and other properties to use for each property set. The list of such properties is given in the
-- comment above create_base(), along with the explanation of what a property set is and why we have multiple such
-- property sets (generally, one per combination of control specs such as 'con,-con' and 'umut,uUmut'). There are
-- currently 9 singular stems and a corresponding 9 plural stems.
local function determine_props(base)
	-- Now determine all the props for each prop set.
	for _, props in ipairs(base.prop_sets) do
		-- Determine the default dative singular for masculine nouns using declension "m".
		determine_default_masc_dat_sg(base, props)

		-- Almost all nouns have dative plural -um, which triggers u-mutation, so we need to compute the u-mutation
		-- stem using "umut" if not specifically given. Set `defaulted` so an error isn't triggered if there's no
		-- special u-mutated form.
		local props_umut = props.umut
		if not props_umut and (not props.unumut or props.unumut.form:find("^%-")) then
			props_umut = { form = "umut", defaulted = true }
		end
		-- First do all the stems, handling overall and plural-specific stems separately.
		for _, prefix in ipairs { "", "pl_" } do
			local base_stem, base_vstem
			if prefix == "" then
				base_stem = base.stem
				base_vstem = base.vstem
			else
				base_stem = base.plstem
				base_vstem = base.plvstem
			end
			-- The plstem is almost never set, so don't do a lot of unnecessary computation.
			if prefix == "pl_" and not base_stem then
				break
			end
			local stem, nonvstem, umut_nonvstem, imut_nonvstem, vstem, umut_vstem, imut_vstem, null_defvstem,
			umut_null_defvstem
			if props.unumut and not props.unumut.form:find("^%-") then
				umut_nonvstem = base_stem
				nonvstem = com.apply_reverse_u_mutation(umut_nonvstem, props.unumut.form, not props.unumut.defaulted)
				stem = nonvstem
				if base.need_imut then
					imut_nonvstem = com.apply_i_mutation(nonvstem, base.imutval)
				end
				if base_vstem then
					error(("Don't currently know how to combine '%svstem:' with 'unumut' specs"):format(
						prefix == "pl_" and "pl" or ""))
				end
				if props.con and props.con.form == "con" then
					umut_vstem = com.apply_contraction(base_stem)
				else
					umut_vstem = base_stem
				end
				vstem = com.apply_reverse_u_mutation(umut_vstem, props.unumut.form, not props.unumut.defaulted)
				if base.need_imut then
					imut_vstem = com.apply_i_mutation(vstem, base.imutval)
				end
				local props_unumut_form = props.unumut.form
				if props.defcon and props.defcon.form == "defcon" then
					umut_null_defvstem = com.apply_contraction(base_stem)
				else
					umut_null_defvstem = base_stem
				end
				null_defvstem = com.apply_reverse_u_mutation(umut_null_defvstem, props_unumut_form,
					not props.unumut.defaulted)
			elseif props.unimut and not props.unimut.form:find("^%-") then
				imut_nonvstem = base_stem
				nonvstem = com.apply_reverse_i_mutation(imut_nonvstem, base.imutval)
				stem = nonvstem
				if props_umut then
					umut_nonvstem = com.apply_u_mutation(nonvstem, props_umut.form, not props_umut.defaulted)
				end
				if base_vstem then
					error(("Don't currently know how to combine '%svstem:' with 'unimut' specs"):format(
						prefix == "pl_" and "pl" or ""))
				end
				if props.con and props.con.form == "con" then
					imut_vstem = com.apply_contraction(base_stem)
				else
					imut_vstem = base_stem
				end
				vstem = com.apply_reverse_i_mutation(imut_vstem, base.imutval)
				if props_umut then
					umut_vstem = com.apply_u_mutation(vstem, props_umut.form, not props_umut.defaulted)
				end
				if props.defcon and props.defcon.form == "defcon" then
					error("Don't currently know how to combine 'defcon' with 'unimut' specs")
				end
				base.need_imut = true
			elseif props_umut then
				stem = base_stem
				nonvstem = stem
				umut_nonvstem = com.apply_u_mutation(nonvstem, props_umut.form, not props_umut.defaulted)
				if base.need_imut then
					imut_nonvstem = com.apply_i_mutation(nonvstem, base.imutval)
				end
				vstem = base_vstem or base_stem
				if props.con and props.con.form == "con" then
					vstem = com.apply_contraction(vstem)
				end
				umut_vstem = com.apply_u_mutation(vstem, props_umut.form, not props_umut.defaulted)
				if base.need_imut then
					imut_vstem = com.apply_i_mutation(vstem, base.imutval)
				end
				if props.defcon and props.defcon.form == "defcon" then
					null_defvstem = com.apply_contraction(base_stem)
				else
					null_defvstem = base_stem
				end
				umut_null_defvstem = com.apply_u_mutation(null_defvstem, props_umut.form, not props_umut.defaulted)
			else
				-- Normally u-mutated forms should always be available, unless 'unumut' is in effect.
				error(("Internal error: Neither 'unumut' or 'umut' specified: %s"):format(dump(props)))
			end

			props[prefix .. "stem"] = stem
			if nonvstem ~= stem then
				props[prefix .. "nonvstem"] = nonvstem
			end
			if umut_nonvstem ~= nonvstem then
				-- For 'con' and 'defcon' below, footnotes can be placed on -con or -defcon so we have to check for
				-- those footnotes as well as checking for the vstem and such being different, so the -con and -defcon
				-- footnotes are still active. However, there's no such thing as -umut, and any time that there's an
				-- explicit umut variant given, umut_nonvstem will be different from nonvstem (otherwise an error will
				-- occur in apply_u_mutation), so we don't need this extra check here.
				if props_umut then
					umut_nonvstem = iut.combine_form_and_footnotes(umut_nonvstem, props_umut.footnotes)
				end
				props[prefix .. "umut_nonvstem"] = umut_nonvstem
			end
			if base.need_imut then
				-- imut footnotes handled specially below
				props[prefix .. "imut_nonvstem"] = imut_nonvstem
			end
			if vstem ~= stem or props.con and props.con.footnotes then
				-- See comment above for why we need to check for props.con.footnotes (basically, to handle footnotes on
				-- -con).
				if props.con then
					vstem = iut.combine_form_and_footnotes(vstem, props.con.footnotes)
				end
				props[prefix .. "vstem"] = vstem
			end
			if umut_vstem ~= vstem or props.con and props.con.footnotes then
				-- See comment above under `umut_nonvstem ~= nonvstem`. There's no -umut so whenever there's a specific
				-- umut variant with footnote, umut_vstem will be different from vstem so we don't need to check for
				-- `or props_umut and props_umut.footnotes` above.
				local footnotes = iut.combine_footnotes(props.con and props.con.footnotes or nil,
					props_umut and props_umut.footnotes or nil)
				umut_vstem = iut.combine_form_and_footnotes(umut_vstem, footnotes)
				props[prefix .. "umut_vstem"] = umut_vstem
			end
			if base.need_imut then
				-- imut footnotes handled specially below
				props[prefix .. "imut_vstem"] = imut_vstem
			end
			if null_defvstem ~= nonvstem or props.defcon and props.defcon.footnotes then
				-- See comment above for why we need to check for props.defcon.footnotes (basically, to handle footnotes
				-- on -defcon).
				if props.defcon then
					null_defvstem = iut.combine_form_and_footnotes(null_defvstem, props.defcon.footnotes)
				end
				props[prefix .. "null_defvstem"] = null_defvstem
			end
			if umut_null_defvstem ~= null_defvstem or props.defcon and props.defcon.footnotes then
				-- Analogous situation to the clause above that checks for `umut_vstem ~= vstem`.
				local footnotes = iut.combine_footnotes(props.defcon and props.defcon.footnotes or nil,
					props_umut and props_umut.footnotes or nil)
				umut_null_defvstem = iut.combine_form_and_footnotes(umut_null_defvstem, footnotes)
				props[prefix .. "umut_null_defvstem"] = umut_null_defvstem
			end
		end

		-- Do the j-infix, v-infix, imut, unimut and unumut properties.
		if props.j then
			props.jinfix = props.j.form == "j" and "j" or ""
			props.jinfix_footnotes = props.j.footnotes
			props.j = nil
		end
		if props.v then
			props.vinfix = props.v.form == "v" and "v" or ""
			props.vinfix_footnotes = props.v.footnotes
			props.v = nil
		end
		if props.imut then
			props.imut_footnotes = props.imut.footnotes
			props.imut = props.imut.form == "imut" and true or false
		end
		if props.unimut then
			props.unimut_footnotes = props.unimut.footnotes
			props.unimut = props.unimut.form == "unimut" and true or false
		end
		if props.unumut then
			props.unumut_footnotes = props.unumut.footnotes
			props.unumut = props.unumut.form
		end
	end
end


local function detect_indicator_spec(base)
	base.prop_sets = { {} }
	if base.adjspec then
		process_declnumber(base)
		synthesize_adj_lemma(base)
	elseif base.props.builtin then
		determine_builtin_props(base)
	else
		-- Replace # and ## in all overridable stems as well as all overrides.
		for _, stemkey in ipairs(overridable_stems) do
			base[stemkey] = com.replace_hashvals(base[stemkey], base.lemma)
		end
		map_all_overrides(base, function(formobj)
			formobj.form = com.replace_hashvals(formobj.form, base.lemma)
		end)
		expand_property_sets(base)
		if base.definiteness == "def" then
			synthesize_indefinite_lemma(base)
		end
		if base.number == "pl" then
			synthesize_singular_lemma(base)
		end
		determine_declension(base)
		determine_props(base)
	end
end


local function detect_all_indicator_specs(alternant_multiword_spec)
	-- Keep track of all genders seen in the singular and plural so we can determine whether to add the term to
	-- [[:Category:Icelandic nouns that change gender in the plural]]. FIXME: Is this needed for Icelandic? It's copied
	-- from Czech.
	alternant_multiword_spec.sg_genders = {}
	alternant_multiword_spec.pl_genders = {}
	iut.map_word_specs(alternant_multiword_spec, function(base)
		detect_indicator_spec(base)
		if base.number ~= "pl" then
			alternant_multiword_spec.sg_genders[base.actual_gender] = true
		end
		if base.number ~= "sg" then
			alternant_multiword_spec.pl_genders[base.actual_gender] = true
		end
	end)
end


local propagate_multiword_properties


local function propagate_alternant_properties(alternant_spec, property, mixed_value, nouns_only)
	local seen_property
	for _, multiword_spec in ipairs(alternant_spec.alternants) do
		propagate_multiword_properties(multiword_spec, property, mixed_value, nouns_only)
		if seen_property == nil then
			seen_property = multiword_spec[property]
		elseif multiword_spec[property] and seen_property ~= multiword_spec[property] then
			seen_property = mixed_value
		end
	end
	alternant_spec[property] = seen_property
end


propagate_multiword_properties = function(multiword_spec, property, mixed_value, nouns_only)
	local seen_property = nil
	local last_seen_nounal_pos = 0
	local word_specs = multiword_spec.alternant_or_word_specs or multiword_spec.word_specs
	for i = 1, #word_specs do
		local is_nounal
		if word_specs[i].alternants then
			propagate_alternant_properties(word_specs[i], property, mixed_value)
			is_nounal = not not word_specs[i][property]
		elseif nouns_only then
			is_nounal = is_regular_noun(word_specs[i])
		else
			is_nounal = not not word_specs[i][property]
		end
		if is_nounal then
			if not word_specs[i][property] then
				error("Internal error: noun-type word spec without " .. property .. " set")
			end
			for j = last_seen_nounal_pos + 1, i - 1 do
				word_specs[j][property] = word_specs[j][property] or word_specs[i][property]
			end
			last_seen_nounal_pos = i
			if seen_property == nil then
				seen_property = word_specs[i][property]
			elseif seen_property ~= word_specs[i][property] then
				seen_property = mixed_value
			end
		end
	end
	if last_seen_nounal_pos > 0 then
		for i = last_seen_nounal_pos + 1, #word_specs do
			word_specs[i][property] = word_specs[i][property] or word_specs[last_seen_nounal_pos][property]
		end
	end
	multiword_spec[property] = seen_property
end


local function propagate_properties_downward(alternant_multiword_spec, property, default_propval)
	local function set_and_fetch(obj, default)
		local retval
		if obj[property] then
			retval = obj[property]
		else
			obj[property] = default
			retval = default
		end
		if not obj["actual_" .. property] then
			obj["actual_" .. property] = retval
		end
		return retval
	end
	local propval1 = set_and_fetch(alternant_multiword_spec, default_propval)
	for _, alternant_or_word_spec in ipairs(alternant_multiword_spec.alternant_or_word_specs) do
		local propval2 = set_and_fetch(alternant_or_word_spec, propval1)
		if alternant_or_word_spec.alternants then
			for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
				local propval3 = set_and_fetch(multiword_spec, propval2)
				for _, word_spec in ipairs(multiword_spec.word_specs) do
					local propval4 = set_and_fetch(word_spec, propval3)
					if propval4 == "mixed" then
						-- FIXME, use clearer error message.
						error("Attempt to assign mixed " .. property .. " to word")
					end
					set_and_fetch(word_spec, propval4)
				end
			end
		else
			if propval2 == "mixed" then
				-- FIXME, use clearer error message.
				error("Attempt to assign mixed " .. property .. " to word")
			end
			set_and_fetch(alternant_or_word_spec, propval2)
		end
	end
end


--[=[
Propagate `property` (one of "gender", "number" or "definiteness") from nouns to adjacent adjectives. We proceed
as follows:
1. We assume the properties in question are already set on all nouns. This should happen in
   set_defaults_and_check_bad_indicators().
2. We first propagate properties upwards and sideways. We recurse downwards from the top. When we encounter a multiword
   spec, we proceed left to right looking for a noun. When we find a noun, we fetch its property (recursing if the noun
   is an alternant), and propagate it to any adjectives to its left, up to the next noun to the left. When we have
   processed the last noun, we also propagate its property value to any adjectives to the right (to handle e.g.
   [[svefninn langi]] "the long sleep", where the adjective [[langi]] should inherit the 'masculine', 'singular' and
   'definite' properties of [[svefninn]]). Finally, we set the property value for the multiword spec itself by combining
   all the non-nil properties of the individual elements. If all non-nil properties have the same value, the result is
   that value, otherwise it is `mixed_value` (which is "mixed" for gender, but "both" for number and "bothdef" for
   definiteness).
3. When we encounter an alternant spec in this process, we recursively process each alternant (which is a multiword
   spec) using the previous step, and combine any non-nil properties we encounter the same way as for multiword specs.
4. The effect of steps 2 and 3 is to set the property of each alternant and multiword spec based on its children or its
   neighbors.
]=]
local function propagate_properties(alternant_multiword_spec, property, default_propval, mixed_value)
	propagate_multiword_properties(alternant_multiword_spec, property, mixed_value, "nouns only")
	propagate_multiword_properties(alternant_multiword_spec, property, mixed_value, false)
	propagate_properties_downward(alternant_multiword_spec, property, default_propval)
end


local function determine_noun_status(alternant_multiword_spec)
	for i, alternant_or_word_spec in ipairs(alternant_multiword_spec.alternant_or_word_specs) do
		if alternant_or_word_spec.alternants then
			local is_noun = false
			for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
				for j, word_spec in ipairs(multiword_spec.word_specs) do
					if is_regular_noun(word_spec) then
						multiword_spec.first_noun = j
						is_noun = true
						break
					end
				end
			end
			if is_noun then
				alternant_multiword_spec.first_noun = i
			end
		elseif is_regular_noun(alternant_or_word_spec) then
			alternant_multiword_spec.first_noun = i
			return
		end
	end
end


-- Set the part of speech based on properties of the individual words.
local function set_pos(alternant_multiword_spec)
	if not alternant_multiword_spec.pos then
		if alternant_multiword_spec.saw_builtin and not alternant_multiword_spec.saw_non_builtin then
			alternant_multiword_spec.pos = "pronoun"
		else
			alternant_multiword_spec.pos = "noun"
		end
	end
end


local function normalize_all_lemmas(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		local lemma = base.orig_lemma_no_links
		base.actual_lemma = lemma
		base.lemma = base.decllemma or lemma
		base.source_template = alternant_multiword_spec.source_template
	end)
end


local function conjugate_verb(base)
	for _, props in ipairs(base.prop_sets) do
		if not decls[base.decl] then
			error("Internal error: Unrecognized declension type '" .. base.decl .. "'")
		end
		decls[base.decl](base, props)
	end
	handle_derived_slots_and_overrides(base)
	local function copy(from_slot, to_slot)
		base.forms["ind_" .. to_slot] = base.forms["ind_" .. from_slot]
		base.forms["def_" .. to_slot] = base.forms["def_" .. from_slot]
	end
	if base.actual_number ~= base.number then
		local source_num = base.number == "sg" and "_s" or "_p"
		local dest_num = base.number == "sg" and "_p" or "_s"
		for _, case in ipairs(cases) do
			copy(case .. source_num, case .. dest_num)
			copy("nom" .. source_num .. "_linked", "nom" .. dest_num .. "_linked")
		end
		if base.actual_number ~= "both" then
			local erase_num = base.actual_number == "sg" and "_p" or "_s"
			for _, case in ipairs(cases) do
				base.forms["ind_" .. case .. erase_num] = nil
				base.forms["def_" .. case .. erase_num] = nil
			end
			base.forms["ind_nom" .. erase_num .. "_linked"] = nil
			base.forms["def_nom" .. erase_num .. "_linked"] = nil
		end
	end
	process_addnote_specs(base)
end


-- Compute the categories to add the noun to, as well as the annotation to display in the
-- declension title bar. We combine the code to do these functions as both categories and
-- title bar contain similar information.
local function compute_categories_and_annotation(alternant_multiword_spec)
	local all_cats = {}
	local plpos = require(en_utilities_module).pluralize(alternant_multiword_spec.pos)
	local function inscat(cattype)
		m_insertIfNot(all_cats, "Icelandic " .. cattype)
	end
	local function inscat_noun(cattype)
		if plpos == "nouns" then
			inscat(cattype)
		end
	end
	if alternant_multiword_spec.saw_indecl and not alternant_multiword_spec.saw_non_indecl then
		inscat("indeclinable " .. plpos)
	end
	if alternant_multiword_spec.saw_unknown_decl and not alternant_multiword_spec.saw_non_unknown_decl then
		inscat(plpos .. " with unknown declension")
	end
	if alternant_multiword_spec.actual_number == "sg" then
		inscat_noun("uncountable nouns")
	elseif alternant_multiword_spec.actual_number == "pl" then
		inscat_noun("pluralia tantum")
	end
	local annparts = {}
	local irregs = {}
	local genderspecs = {}
	local stemspecs = {}
	local scrape_chains = {}
	local function insann(txt, joiner)
		if joiner and annparts[1] then
			insert(annparts, joiner)
		end
		insert(annparts, txt)
	end

	local function do_word_spec(base)
		local actual_gender = gender_code_to_desc[base.actual_gender]
		local declined_gender = gender_code_to_desc[base.gender]
		local gender
		if actual_gender ~= declined_gender then
			gender = ("%s (declined as %s)"):format(actual_gender, declined_gender)
			inscat_noun("nouns with actual gender different from declined gender")
		else
			gender = actual_gender
		end
		if gender then
			m_insertIfNot(genderspecs, gender)
		end
		for _, props in ipairs(base.prop_sets) do
			-- User-specified 'decllemma:' indicates irregular stem.
			if base.decllemma then
				m_insertIfNot(irregs, "irreg-stem")
				inscat_noun("nouns with irregular stem")
			end
			m_insertIfNot(stemspecs, props.stem)
		end
	end
	local key_entry = alternant_multiword_spec.first_noun or 1
	if #alternant_multiword_spec.alternant_or_word_specs >= key_entry then
		local alternant_or_word_spec = alternant_multiword_spec.alternant_or_word_specs[key_entry]
		if alternant_or_word_spec.alternants then
			for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
				key_entry = multiword_spec.first_noun or 1
				if #multiword_spec.word_specs >= key_entry then
					do_word_spec(multiword_spec.word_specs[key_entry])
				end
			end
		else
			do_word_spec(alternant_or_word_spec)
		end
	end
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.scrape_chain[1] then
			local linked_scrape_chain = {}
			for _, element in ipairs(base.scrape_chain) do
				insert(linked_scrape_chain, ("[[%s]]"):format(element))
			end
			m_insertIfNot(scrape_chains, concat(linked_scrape_chain, " -> "))
		end
	end)
	if alternant_multiword_spec.actual_number == "sg" or alternant_multiword_spec.actual_number == "pl" then
		-- not "both" or "none" (for [[sebe]])
		insann(alternant_multiword_spec.actual_number .. "-only", " ")
	end
	if #genderspecs > 0 then
		insann(concat(genderspecs, " // "), " ")
	end
	if #irregs > 0 then
		insann(concat(irregs, " // "), " ")
	end
	if #scrape_chains > 0 then
		insann(("based on %s"):format(m_table.serialCommaJoin(scrape_chains)), ", ")
		inscat(plpos .. " declined using scraped base declensions")
	end

	alternant_multiword_spec.annotation = concat(annparts)
	if #stemspecs > 1 then
		inscat_noun("nouns with multiple stems")
	end
	if alternant_multiword_spec.actual_number == "both" and not m_table.deepEquals(alternant_multiword_spec.sg_genders, alternant_multiword_spec.pl_genders) then
		inscat_noun("nouns that change gender in the plural")
	end
	alternant_multiword_spec.categories = all_cats
end


local function show_forms(alternant_multiword_spec)
	local lemmas = {}
	local max_num_words = 1
	for _, slot in ipairs(potential_lemma_slots) do
		if alternant_multiword_spec.forms[slot] then
			for _, formobj in ipairs(alternant_multiword_spec.forms[slot]) do
				insert(lemmas, formobj)
				local no_affix_form = formobj.form:gsub("^%-", ""):gsub("%-$", "")
				local num_words = #(usplit(no_affix_form, "[ -]+"))
				max_num_words = math.max(max_num_words, num_words)
			end
			break
		end
	end
	alternant_multiword_spec.max_num_words = max_num_words
	local props = {
		lemmas = lemmas,
		slot_list = alternant_multiword_spec.noun_slots,
		lang = lang,
	}
	iut.show_forms(alternant_multiword_spec.forms, props)
end


local function make_table(alternant_multiword_spec)
	local forms = alternant_multiword_spec.forms

	local function template_prelude(palette)
		return m_inflection_table.make_top {
			title = "{title}{annotation}",
			palette = palette,
			tall = "yes",
		}
	end

	local function template_postlude()
		return m_inflection_table.make_bottom {
			notes = "{footnote}",
		}
	end

	local function get_verb_table_spec(voice, include_pastinf)
		local palette = voice == "act" and "blue" or "green"
		local spec = [=[
! colspan=3 | infinitive <<s!nafnháttur>>
| colspan=5 data-accel-col=1 | {VOICEad_inf}
]=] .. (not include_pastinf and "" or [=[
|-
! colspan=3 | past infinitive<br /><<s!nafnháttur>> <<s!þátíð>>
| colspan=5 data-accel-col=6 | {VOICEpastinf}
]=]) .. [=[
|-
! colspan=3 | supine <<s!sagnbót>>
| colspan=5 data-accel-col=1 | {VOICEsup}
]=] .. (voice == "mid" and "" or [=[
|-
! colspan=3 | present participle<br /><<s!lýsingarháttur nútíðar>>
| colspan=5 data-accel-col=7 | {presp}
]=]) .. [=[
|-
| colspan=999 class="separator" |
|-
! colspan=3 class="outer" |
! colspan=2 class="outer" | indicative<br /><<s!framsöguháttur>>
| rowspan=8 class="separator" |
! colspan=3 class="outer" | subjunctive<br /><<s!viðtengingarháttur>>
|-
! colspan=3 |
! present<br /><<s!nútíð>>
! past<br /><<s!þátíð>>
! present<br /><<s!nútíð>>
! past<br /><<s!þátíð>>
|-
! rowspan=4 | singular<br /><<s!eintala>>
! class="secondary" | first
! class="secondary" | <<l!ég>>
| data-accel-col=2 | {VOICEpres1s}
| data-accel-col=3 | {VOICEpast1s}
| data-accel-col=4 | {VOICEpressub1s}
| data-accel-col=5 | {VOICEpastsub1s}
|-
! class="secondary" | second
! class="secondary" | <<l!þú>>
| data-accel-col=2 | {VOICEpres2s}
| data-accel-col=3 | {VOICEpast2s}
| data-accel-col=4 | {VOICEpressub2s}
| data-accel-col=5 | {VOICEpastsub2s}
|-
! class="secondary" | third
! class="secondary" | <<l!hann, hún, það>>
| data-accel-col=2 | {VOICEpres3s}
| data-accel-col=3 | {VOICEpast3s}
| data-accel-col=4 | {VOICEpressub3s}
| data-accel-col=5 | {VOICEpastsub3s}
|-
! colspan=2 class="secondary" | second-person question form<br /><<s!spurnarmynd>>
| data-accel-col=2 | {VOICEqform_pres2s}
| data-accel-col=3 | {VOICEqform_past2s}
| data-accel-col=4 | {VOICEqform_pressub2s}
| data-accel-col=5 | {VOICEqform_pastsub2s}
|-
! rowspan=4 | plural<br /><<s!fleirtala>>
! class="secondary" | first
! class="secondary" | <<l!við>>
| data-accel-col=2 | {VOICEpres1p}
| data-accel-col=3 | {VOICEpast1p}
| data-accel-col=4 | {VOICEpressub1p}
| data-accel-col=5 | {VOICEpastsub1p}
|-
! class="secondary" | second
! class="secondary" | <<l!þið>>
| data-accel-col=2 | {VOICEpres2p}
| data-accel-col=3 | {VOICEpast2p}
| data-accel-col=4 | {VOICEpressub2p}
| data-accel-col=5 | {VOICEpastsub2p}
|-
! class="secondary" | third
! class="secondary" | <<l!þeir, þær, þau>>
| data-accel-col=2 | {VOICEpres3p}
| data-accel-col=3 | {VOICEpast3p}
| data-accel-col=4 | {VOICEpressub3p}
| data-accel-col=5 | {VOICEpastsub3p}
|-
! colspan=2 class="secondary" | second-person question form<br /><<s!spurnarmynd>>
| data-accel-col=2 | {VOICEqform_pres2p}
| data-accel-col=3 | {VOICEqform_past2p}
| data-accel-col=4 | {VOICEqform_pressub2p}
| data-accel-col=5 | {VOICEqform_pastsub2p}
|-
| colspan=5 class="separator" |
| colspan=3 rowspan=5 class="blank-end-row" |
|-
! colspan=3 class="outer" | 
! colspan=2 class="outer" | imperative <<s!boðháttur>>
|-
! rowspan=2 | singular<br /><<s!eintala>>
! rowspan=3 class="secondary" | second
! class="secondary" | clipped<br /><<s!stýfður>>
| colspan=2 data-accel-col=6 | {VOICEimp2s}
|-
! class="secondary" | suffixed<br /><<s!viðskeyttur>>
| colspan=2 data-accel-col=7 | {VOICEimp2ss}
|-
! plural<br /><<s!fleirtala>>
| colspan=2 data-accel-col=6 | {VOICEimp2p}, {VOICEimp2ps}
]=]
		return template_prelude(palette) .. spec:gsub("VOICE", voice == "act" and "" or "mid_") .. template_postlude
	end

	if alternant_multiword_spec.title then
		forms.title = alternant_multiword_spec.title
	else
		forms.title = 'Declension of <i lang="is">' .. forms.lemma .. '</i>'
	end

	-- Active title: {{m|is||{{{1|{{PAGENAME}}}}}}} – active voice <span class="small">({{m|is|germynd}})</span> [blue]
	-- Middle title: {{m|is||{{{1|{{PAGENAME}}}}}}} – middle voice <span class="small">({{m|is|miðmynd}})</span> [teal]
	-- Active past participle title: {{m-self|is|{{{1|{{PAGENAME}}}}}}} — past participle <small>([[lýsingarháttur þátíðar]])</small> [purple]
	-- Middle past participle title: {{m-self|is|{{{1|{{PAGENAME}}}}}}} — middle past participle <small>([[lýsingarháttur þátíðar]] [[af]] [[miðmynd]])</small> [red]
	--  only [[sestur]] and [[lagstur]]
	local annotation = alternant_multiword_spec.annotation
	if annotation == "" then
		forms.annotation = ""
	else
		forms.annotation = " (<span style=\"font-size: smaller;\">" .. annotation .. "</span>)"
	end

	local number, numcode
	if alternant_multiword_spec.actual_number == "sg" then
		number, numcode = "singular", "s"
	elseif alternant_multiword_spec.actual_number == "pl" then
		number, numcode = "plural", "p"
	elseif alternant_multiword_spec.actual_number == "none" then -- used for [[sebe]]
		-- FIXME: Update for Icelandic
		number, numcode = "", "s"
	end

	local definiteness, defcode
	if alternant_multiword_spec.definiteness == "indef" then
		definiteness, defcode = "indefinite", "ind"
	elseif alternant_multiword_spec.definiteness == "def" then
		definiteness, defcode = "definite", "def"
	elseif alternant_multiword_spec.definiteness == "none" then
		definiteness, defcode = "", "ind"
	end

	local table_spec =
		alternant_multiword_spec.actual_number ~= "both" and alternant_multiword_spec.definiteness ~= "bothdef" and
		get_table_spec_one_number_one_def(number, numcode, definiteness, defcode) or
		alternant_multiword_spec.actual_number == "both" and table_spec_both or
		get_table_spec_one_number(number, numcode)
	return m_string_utilities.format(table_spec, forms)
end


local function compute_headword_genders(alternant_multiword_spec)
	local genders = {}
	local number
	if alternant_multiword_spec.actual_number == "pl" then
		number = "-p"
	else
		number = ""
	end
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.actual_gender ~= "none" then
			m_insertIfNot(genders, base.actual_gender .. number)
		end
	end)
	return genders
end


-- Externally callable function to parse and decline a noun given user-specified arguments and the argument spec
-- `argspec` (specified because the user may give multiple such specs). Return value is ALTERNANT_MULTIWORD_SPEC, an
-- object where the declined forms are in `ALTERNANT_MULTIWORD_SPEC.forms` for each slot. If there are no values for a
-- slot, the slot key will be missing. The value for a given slot is a list of objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(args, argspec, source_template)
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
	alternant_multiword_spec.pos = args.pos
	alternant_multiword_spec.args = args
	alternant_multiword_spec.source_template = source_template

	local scrape_errors = {}
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.scrape_error then
			insert(scrape_errors, base.scrape_error)
		end
	end)

	if scrape_errors[1] then
		alternant_multiword_spec.scrape_errors = scrape_errors
	else
		normalize_all_lemmas(alternant_multiword_spec)
		set_all_defaults_and_check_bad_indicators(alternant_multiword_spec)
		-- These need to happen before detect_all_indicator_specs() so that adjectives get their genders and number
		-- set appropriately, which are needed to correctly synthesize the adjective lemma.
		propagate_properties(alternant_multiword_spec, "number", "both", "both")
		-- FIXME, the default value (third param) used to be 'm' with a comment indicating that this applied only to
		-- plural adjectives, where it didn't matter; but in Icelandic, plural adjectives are distinguished for gender.
		-- Make sure 'mixed' works.
		propagate_properties(alternant_multiword_spec, "gender", "mixed", "mixed")
		propagate_properties(alternant_multiword_spec, "definiteness", "bothdef", "bothdef")
		detect_all_indicator_specs(alternant_multiword_spec)
		-- Propagate 'actual_number' after calling detect_all_indicator_specs(), which sets 'actual_number' for
		-- adjectives.
		propagate_properties(alternant_multiword_spec, "actual_number", "both", "both")
		determine_noun_status(alternant_multiword_spec)
		set_pos(alternant_multiword_spec)
		alternant_multiword_spec.noun_slots = get_noun_slots(alternant_multiword_spec)
		local inflect_props = {
			skip_slot = function(slot)
				return skip_slot(alternant_multiword_spec.actual_number, alternant_multiword_spec.definiteness, slot)
			end,
			slot_list = alternant_multiword_spec.noun_slots,
			inflect_word_spec = conjugate_verb,
		}
		iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)
		compute_categories_and_annotation(alternant_multiword_spec)
		alternant_multiword_spec.genders = compute_headword_genders(alternant_multiword_spec)
	end
	if args.json then
		alternant_multiword_spec.args = nil
		return require("Module:JSON").toJSON(alternant_multiword_spec)
	end
	return alternant_multiword_spec
end

-- Entry point for {{is-conj}}. Template-callable function to parse and conjugate a verb given
-- user-specified arguments and generate a displayable table of the declined forms.
function export.show(frame)
	local parent_args = frame:getParent().args
	local params = {
		[1] = { required = true, list = true, default = "akur<m.#>" },
		deriv = { list = true },
		id = {},
		pos = {},
		title = {},
		pagename = {},
		json = { type = "boolean" },
	}
	local args = m_para.process(parent_args, params)
	local alternant_multiword_specs = {}
	for i, argspec in ipairs(args[1]) do
		alternant_multiword_specs[i] = export.do_generate_forms(args, argspec, "is-ndecl")
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
		insert(parts, txt)
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
				insert(errmsgs, '<span style="font-weight: bold; color: var(--wikt-palette-red,#CC2200);">' .. scrape_error .. "</span>")
			end
			-- Surround the messages with a <div> because the table normally does that, and we want to ensure
			-- similar formatting with respect to newlines.
			ins("<div>" .. concat(errmsgs, "<br />") .. "</div>")
			categories = { "Icelandic scraping errors in Template:is-ndecl" }
		else
			ins(make_table(alternant_multiword_spec))
			categories = alternant_multiword_spec.categories
		end
		ins(require("Module:utilities").format_categories(categories, lang, nil, nil, force_cat))
	end
	return concat(parts)
end

return export
