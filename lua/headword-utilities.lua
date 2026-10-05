local export = {}

--[==[
FIXME:
1. Implement ? = unknown or uncertain. There should be no label by default but it should be configurable.
   The default category should be "{plpos} with unknown or uncertain plurals" for nouns/proper nouns. It should
   be an error to specify values along with this.
2. Implement ! = unattested. The default label should be "{label} not attested". The default category should be
   "{plpos} with unattested plurals" for nouns/proper nouns. It should be an error to specify values along with
   this.
3. Implement +- = sometimes has a value, e.g. "countable and uncountable" for plurals.
4. Implement ~ standing for the pagename in heads and inflections. [DONE]
5. Implement abbr= for abbreviations. [DONE]
6. Extract from insert_inflection the logic to handle the special mode signals, determine the actual label and
   category and the actual values without inserting them.
7. Support no_label for booleans.
8. Document the various types of parts of speech and implement pos_category per part of speech definition. [DONE]
9. Implement apply_link_modifiers() for head=~...
10. Correctly handle var=both. [DONE]
11. Implement checkredlinks and port simplify_pos to [[Module:headword]].
12. Fix longstanding accelerator bug: if embeddded links in inflection, don't make it green.
]==]
local require_when_needed = require("Module:utilities/require when needed")
local affix_module = "Module:affix"
local debug_track_module = "Module:debug/track"
local decorations_module = "Module:decorations"
local en_utilities_module = "Module:en-utilities"
local fun_is_callable_module = "Module:fun/isCallable"
local headword_module = "Module:headword"
local headword_data_module = "Module:headword/data"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local parse_interface_module = "Module:parse interface"
local parse_utilities_module = "Module:parse utilities"
local string_pattern_escape_module = "Module:string/patternEscape"
local string_replacement_escape_module = "Module:string/replacementEscape"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

local dump = mw.dumpObject
local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local insert = table.insert
local concat = table.concat
local remove = table.remove
local sort = table.sort

local deep_equals = require_when_needed(table_module, "deepEquals")
local extend = require_when_needed(table_module, "extend")
local insert_if_not = require_when_needed(table_module, "insertIfNot")
local list_to_set = require_when_needed(table_module, "listToSet")
local serial_comma_join = require_when_needed(table_module, "serialCommaJoin")
local shallow_copy = require_when_needed(table_module, "shallowCopy")

local split = require_when_needed(string_utilities_module, "split")
local ugsub = require_when_needed(string_utilities_module, "gsub")
local umatch = require_when_needed(string_utilities_module, "match")
local pattern_escape = require_when_needed(string_pattern_escape_module)
local replacement_escape = require_when_needed(string_replacement_escape_module)

local escape_wikicode = require_when_needed(parse_utilities_module, "escape_wikicode")
local parse_inline_modifiers = require_when_needed(parse_utilities_module, "parse_inline_modifiers")
local term_contains_top_level_html = require_when_needed(parse_utilities_module, "term_contains_top_level_html")

local get_lang_by_code = require_when_needed(languages_module, "getByCode")
local is_callable = require_when_needed(fun_is_callable_module)
local format_decorations = require_when_needed(decorations_module, "format_decorations")
local singularize = require_when_needed(en_utilities_module, "singularize")
local canonicalize_pos = require_when_needed(headword_module, "canonicalize_pos")
local pluralize_pos = require_when_needed(headword_module, "pluralize_pos")


local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end

local function ine(val)
	if not val then
		return nil
	end
	val = mw.text.trim(val)
	return val ~= "" and val or nil
end

--[==[ intro:
This module contains utilities for constructing language-specific headword modules.
[fill in]

===About parts of speech===
There are several versions of the part of speech (POS) of a given term:
* The ''primary categorizing POS'' is the basic part of speech to which a term belongs. The primary POS determines
  whether the term is a lemma or non-lemma form, and in its plural form, it is used to categorize the terms (unless it
  is a variant term), along with caetegorizing into a ''lemmas'' or ''non-lemma forms'' category. (Variant terms,
  typically marked by {{para|var|1}}, are categorized into ''variant lemmas'' or ''variant non-lemma forms'' and are not
  categorized into a primary POS category.)
* The ''raw {{tl|head}} POS'' is parameter {{para|2}} to {{tl|head}}. This is used to determine the primary categorizing
  POS by a process of canonicalization, because this parameter may contain abbreviations (e.g. ''a'' or ''adj'' for an
  adjective) and may be (and usually is) given in its singular form.
* The ''template-indicated POS'' is the part of speech indicated by a headword template such as {{tl|nl-noun}} or
  {{tl|mn-head}}. It is either inherent to the template (in a case like {{tl|nl-noun}}), in which case it is specified
  by the template code and should always be in canonical, plural form; or it is specified by the user in the template
  call (in a case like {{tl|mn-head}} or other generic POS template, usually ending in `-head`), in which case it may
  be given in raw form, like for the raw {{tl|head}} POS, and is canonicalized using the same code that canonicalizes
  raw {{tl|head}} parts of speech. The template-indicate POS may not be a valid primary categorizing POS. For example,
  Dutch has a template-indicated POS ''diminutiva tantum nouns'', specified through the template {{tl|nl-dim-tant}}, but
  there is no such primary categorizing POS (that POS would be `nouns`). Similarly, Arabic has a template-indicated POS
  ''collective nouns'', whose primary categorizing POS is also `nouns`. As a result, the template-indicated POS may need
  to be converted to a primary categorizing POS through a ''normalization'' process (which uses a `pos_category` field
  attached to the `pos_functions` structure for the template-indicated POS). Note that the template-indicated POS comes
  in several variants:
*# It may be ''head-raw'', meaning that it uses the literal string `head` in place of the user-specified POS in a
   generic POS template like {{tl|mn-head}}; it may be ''non-head'', meaning that it uses the actual user-specified
   POS in such a case; or it may be ''head-augmented'', meaning that in the case of a generic POS template it is of the
   form e.g. `head.nouns`, contanining both the literal `head` and the user-specified POS.
*# It may be ''suffix-raw'', meaning that it uses the primary categorizing POS `suffixes` in place of the
   template-indicated POS when the term is a suffix, or it may be ''non-suffix'', meaning that it uses the
   template-indicated POS in such a case. The headword for a suffix uses the template corresponding to whatever POS the
   suffix forms, e.g. {{nl-noun}} for Dutch noun-forming suffixes.
*# The ''indexing POS'' is the variant of the template-indicated POS that is used to index into the `pos_functions`
   table. Normally it is head-raw and non-suffix, but it will be head-augmented if the corresponding head-augmented
   entry exists in `pos_functions`.
*# The ''unnormalized categorizing POS'' is the variant of the template-indicated POS that is potentially usable as the
   primary categorizing POS (see above). It is non-head and suffix-raw, i.e. it uses the actual template-specified or
   user-specified form of the template-indicated POS except when the term is a suffix, in which case it has the value
   `suffixes`. In most circumstances this can be used directly as the primary categorizing POS, but in some cases this
   POS is not a valid primary categorizing POS and needs to be normalized to get the actual primary categorizing POS, as
   mentioned above under the description for the template-indicated POS.
* Finally, there is a ''simplified categorizing POS''. This collapses variations of primary categorizing parts of speech
  together for use in red-link and similar categories. For example, the POS `proper nouns` is collapsed into `nouns`,
  and all types of participles are collapsed into `participles`. There are two variants of the simplification process,
  ''lemma-status-preserving'' and ''non-lemma-status-preserving''. The latter is the default and is simpler, in that
  e.g. it means any part of speech ending in `nouns` to `nouns`, even if this causes non-lemma forms to become lemmas,
  as with `diminutive nouns` and `verbal nouns` (which are non-lemma forms) and likewise with `comparative adjectives`
  and `superlative adjectives` (which are again non-lemma forms). The former, ''lemma-status-preserving'', keeps lemmas
  as lemmas and (more important) non-lemmas as non-lemmas by converting e.g. `diminutive nouns` and `verbal nouns` to
  `noun forms` rather than `nouns`. The reason two variants exist in that they have different use cases. The default,
  non-lemma-status-preserving, type is used for tracking categories such as red-link and request categories, where
  completeness is more important than clutter. The lemma-status-preserving variant is used for informative categories
  such as ` ``lang`` masculine nouns`, which should only have lemmas in them to avoid clutter. (For the same reason,
  variant terms specified using {{para|var|1}} aren't normally categorized into informative categories but are placed
  in tracking categories.)

===About properties and data objects===
[fill in]
]==]

--[=[
Add decorations to a term. `termobj` is the object describing the term, which should optionally contain:
* left qualifiers in `q`, an array of strings;
* right qualifiers in `qq`, an array of strings;
* left labels in `l`, an array of strings;
* right labels in `ll`, an array of strings;
* references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
  (formatted reference text) and optionally `name` and/or `group`;
`text` is the text of the term itself, and `lang` is the language object.
]=]
local function add_decorations(text, termobj, lang)
	local function field_non_empty(field)
		local list = termobj[field]
		if not list then
			return nil
		end
		if type(list) ~= "table" then
			error(("Internal error: Wrong type for `termobj.%s`=%s, should be \"table\""):format(
				field, mw.dumpObject(list)))
		end
		return list[1]
	end

	if field_non_empty("q") or field_non_empty("qq") or field_non_empty("l") or field_non_empty("ll") or
		field_non_empty("refs") then
		text = format_decorations {
			lang = lang,
			text = text,
			q = termobj.q,
			qq = termobj.qq,
			l = termobj.l,
			ll = termobj.ll,
			refs = termobj.refs,
		}
	end

	return text
end

local param_mods = {
	alt = {}, -- always allow so e.g. - can be specified as a suffix form
	id = {}, -- disabled when `is_head = true`
	q = {type = "qualifier"},
	qq = {type = "qualifier"},
	l = {type = "labels"},
	ll = {type = "labels"},
	-- [[Module:headword]] expects part references in `.refs`.
	ref = {item_dest = "refs", type = "references", store = "insert-flattened"},
}

local optional_param_mods = {
	g = {item_dest = "genders", type = "genders"},
	lang = {type = "language"},
	sc = {type = "script"},
	t = {item_dest = "gloss"},
	gloss = {},
	pos = {},
	lit = {},
	tr = {},
	ts = {},
	face = {},
	nolinkinfl = {type = "boolean"},
}

local optional_headword_param_mods = {
	sc = {type = "script"},
	tr = {},
	ts = {},
}


--[==[
Parse a single inflection or headword form or list of such forms. In either case, inline modifiers may be attached.
`data` is an object with the following fields:
* `val`: The raw value to parse. Required.
* `paramname`: The name of the parameter from which the value was taken; used in error messages. Required.
* `is_head`: We are parsing a headword parameter (a value which goes into the `heads` field of `data`). This changes
  the allowed modifiers, disabling the `id` modifier and only allowing a subset of optional modifiers.
* `frob`: An optional function of one value to apply to the form after inline modifiers have been removed (i.e. to
  apply to the `.term` field of the returned object).
* `include_mods`: List of extra inline modifiers to include, besides the default ones (see below). Each list item is
  either a string specifying a recognized extra inline modifier (see `optional_param_mods` in the code), or a two-item
  list of modifier name and modifier spec, where the spec should follow the syntax for modifier specs in
  `parse_inline_modifiers` in [[Module:parse utilities]].
* `exclude_mods`: List of default inline modifiers to not include.
* `splitchar`: If specified, the value in `val` can be a list of forms to parse, separated by the value of `splitchar`
  (which is a Lua pattern, as in `parse_inline_modifiers` in [[Module:parse utilities]]). Most commonly, `splitchar` is
  a single comma and the values are comma-separated (in this case, splitting will not happen if a space follows the
  comma).
* `parse_lang_prefix`: If specified, allow a language prefix to precede a form, and if found, store into the `.lang`
  field of the returned object.
* `preserve_splitchar`, `delimiter_key`, `escape_fun`, `unescape_fun`, `pre_normalize_modifiers`: As in
  `parse_inline_modifiers` in [[Module:parse utilities]].
Returns an object suitable for storing as one element of one of the lists in `headdata.inflections`, where `headdata`
is the structure passed to [[Module:headword]]. If `splitchar` is specified, howeve, the return value is a list of such
objects.

The following default inline modifiers are currently recognized:
* `q`: Left qualifier.
* `qq`: Right qualifier.
* `l`: Comma-separated list of left labels. No space should follow the comma.
* `ll`: Comma-separated list of right labels. No space should follow the comma.
* `ref`: Reference or references. See {{tl|IPA}} for the syntax.
* `id`: Sense ID, in case there are multiple senses. See {{tl|l}}.
The following are the recognized additional inline modifiers:
* `g`: Comma-separated list of genders.
* `alt`: Display text.
* `lang`: Language code of language of the form, if different from the language of the headword.
* `sc`: Script code of script of the form. Almost never needed.
* `t`: Gloss for the form.
* `gloss`: Gloss for the form (alias for `t`).
* `pos`: Part of speech of the form.
* `lit`: Literal meaning of the form.
* `tr`: Manual transliteration of the form.
* `ts`: Transcription of the form, for languages where the transliteration differs markedly from the pronunciation.
* `face`: Face to display the form in, e.g. {"hypothetical"} for a hypothetical form (unlinkable and displayed in italics).
* `nolinkinfl`: Make the form unlinkable.
]==]
function export.parse_term_with_modifiers(data)
	local paramname, val, frob = data.paramname, data.val, data.frob

	local function generate_obj(term, parse_err)
		if frob then
			term = frob(term, parse_err)
		end
		if data.parse_lang_prefix and term:find(":") then
			return require(parse_utilities_module).generate_obj_maybe_parsing_lang_prefix {
				term = term,
				paramname = paramname,
				parse_lang_prefix = true,
				parse_err = parse_err,
			}
		else
			return {term = term}
		end
	end

	-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude top-level HTML entry with <span ...>,
	-- <sup> or similar in it.
	if (val:find("<", nil, true) or data.splitchar) and not term_contains_top_level_html(val) and
		-- don't parse inline modifiers if is_head and the value begins with a ~ (link modifier syntax)
		(not data.is_head or not val:find("^~")) then
		local param_mods = param_mods
		if data.is_head then
			param_mods = shallow_copy(param_mods)
			param_mods.id = nil
		end
		if data.include_mods or data.exclude_mods then
			if not data.is_head then
				-- already copied when data.is_head
				param_mods = shallow_copy(param_mods)
			end
			if data.include_mods then
				local optional_mods = data.is_head and optional_headword_param_mods or optional_param_mods
				for _, mod in ipairs(data.include_mods) do
					if type(mod) == "table" then
						if #mod ~= 2 then
							error(("Internal error: Modifier spec %s in `include_mods` should be of length 2"):format(
								dump(mod)))
						end
						local modkey, modvalue = unpack(mod)
						param_mods[modkey] = modvalue
					elseif not optional_mods[mod] then
						error(("Internal error: Unrecognized modifier spec %s in `include_mods`"):format(
							dump(mod)))
					else
						param_mods[mod] = optional_mods[mod]
					end
				end
			end
			if data.exclude_mods then
				for _, mod in ipairs(data.exclude_mods) do
					if not param_mods[mod] then
						error(("Internal error: Modifier spec %s in `exclude_mods` not found among existing modifiers"
							):format(dump(mod)))
					else
						param_mods[mod] = nil
					end
				end
			end
		end

		return parse_inline_modifiers(val, {
			paramname = paramname,
			param_mods = param_mods,
			generate_obj = generate_obj,
			splitchar = data.splitchar,
			preserve_splitchar = data.preserve_splitchar,
			delimiter_key = data.delimiter_key,
			escape_fun = data.escape_fun,
			unescape_fun = data.unescape_fun,
			pre_normalize_modifiers = data.pre_normalize_modifiers,
		})
	else
		local retval = generate_obj(val)
		if data.splitchar then
			retval = {retval}
		end
		return retval
	end
end


--[==[
Parse a list of inflection forms that may have inline modifiers attached. `data` is an object with the following fields:
* `forms`: The list of raw values to parse. Required.
* `paramname`: The name of the first parameter from which the value was taken; used in error messages. If this is a
  two-element list, the first element is the first parameter and the second element is the prefix of the remaining
  parameters. Parameter names that are numbers are handled correctly, as are those with \1 in it marking where the
  parameter index goes. Required.
* `qualifiers`: If specified, a possibly gappy list of left qualifiers to add to the parsed terms (for compatibility
  purposes).
* `splitchar`: As in `parse_term_with_modifiers()`. The resulting per-term lists will be flattened.
* `frob`, `include_mods`, `exclude_mods`, `is_head`, `preserve_splitchar`, `parse_lang_prefix`, `delimiter_key`,
  `escape_fun`, `unescape_fun`, `pre_normalize_modifiers`: As in `parse_term_with_modifiers()`.
Returns a list of objects, suitable for storing as one of the lists in `headdata.inflections` (once a label is added),
where `headdata` is the structure passed to [[Module:headword]].
]==]
function export.parse_term_list_with_modifiers(data)
	local paramname, forms = data.paramname, data.forms
	local qualifiers = data.qualifiers
	local first, restpref
	if type(paramname) == "table" then
		first = paramname[1]
		restpref = paramname[2]
	else
		first = paramname
		restpref = paramname
	end
	local terms = {}
	data = shallow_copy(data)
	for i, val in ipairs(forms) do
		data.paramname = i == 1 and first or type(restpref) == "number" and restpref + i - 1 or
			restpref:find("\1", nil, true) and restpref:gsub("\1", tostring(i)) or restpref .. i
		data.val = val
		local parsed = export.parse_term_with_modifiers(data)
		if qualifiers and qualifiers[i] then
			if data.splitchar then
				for _, term in ipairs(parsed) do
					term.q = {qualifiers[i]}
				end
			else
				parsed.q = {qualifiers[i]}
			end
		end
		if data.splitchar then
			extend(terms, parsed)
		else
			terms[i] = parsed
		end
	end
	return terms
end


--[==[
Construct a link to [[Appendix:Glossary]] for `entry`. If `text` is specified, it is the display text; otherwise,
`entry` is used.
]==]
function export.glossary_link(entry, text)
	text = text or entry
	return "[[Appendix:Glossary#" .. entry .. "|" .. text .. "]]"
end


function export.replace_glossary_links_in_label(label)
	if label:find("<<", nil, true) then
		label = label:gsub("<<(.-)|(.-)>>", export.glossary_link):gsub("<<(.-)>>", export.glossary_link)
	end
	return label
end


-- If a part of speech ends with one of these, either pluralized or followed by ' forms', chop off whatever precedes.
-- Also, if a part of speech is of the form `BASIC_POS FOO forms` e.g. `noun construct forms`, remove the `FOO`
-- portion. Note that "phrase" is *NOT* listed here because 'prepositional phrase' and 'postpositional phrase' are not
-- types of 'phrase' per the definition of these parts of speech in Wiktionary. 
local basic_poses = {
	"adjective",
	"adverb",
	"contraction",
	"proper noun", -- may be converted to noun
	"noun",
	"participle",
	"pronoun",
	"symbol",
	"verb",
}

local function optimized_pattern_escape(pos)
	if pos:find("-", nil, true) then
		return pattern_escape(pos)
	else
		return pos
	end
end

--[==[
Canonicalize and then simplify a qualified part of speech (e.g. ''comparative adjectives'', ''past participles'',
''pronoun possessive forms'') to its unqualified equivalent (e.g. ''adjectives'', ''participles'', ''pronoun forms''').
This is used for categorization, since generally the simplified part of speech is used in categories other than the one
for the part of speech itself. (For example, comparative adjectives are normally categorized as adjectives in categories
such as `Requests for inflections in ``lang`` adjective entries`, and proper nouns are, sometimes at least, categorized
under ` ``lang`` nouns with ...` rather than ` ``lang`` proper nouns with ...`.)

There are two cases where simplification does not happen: phrases and (optionally) proper nouns. In Wiktionary,
''phrase'' really means a clause or similar constituent (or occasionally non-constituent), so `prepositional phrases`
are not types of `phrases` and are not simplified. Proper nouns are simplified to nouns for some categories but left
as-is in other category names; by default, this function simplifies `proper nouns` to `nouns`, but if the parameter
`preserve_proper_nouns` is given, `proper nouns` is left as-is.

If `preserve_lemma_status` is given, the function attempts to return a part of speech that has the same lemma status
(lemma or non-lemma form) as the original part of speech; thus, `comparative adjectives` becomes `adjective forms`
and `diminutive nouns` becomes `noun forms` because both are non-lemma forms. If `preserve_lemma_status` is not given,
the function simply chops off the qualifiers, converting e.g. `comparative adjectives` to `adjectives` even though this
changes the lemma status of the part of speech.

The part of speech can be given singular or plural on input, but is always returned in plural form.
]==]
function export.simplify_pos(pos, preserve_proper_nouns, preserve_lemma_status)
	-- This allows for both singular and plural parts of speech in 'pos'.
	local plpos = canonicalize_pos(pos)
	for _, basic_pos in ipairs(basic_poses) do
		if basic_pos ~= "proper noun" or preserve_proper_nouns then
			if plpos == basic_pos .. " forms" then
				-- So 'proper noun forms' doesn't get converted to 'noun forms' in the next round
				return plpos
			end
			local basic_pos_pattern = optimized_pattern_escape(basic_pos)
			if plpos:find(("^%s .*. forms$"):format(basic_pos_pattern)) then
				return basic_pos .. " forms"
			end
			if plpos:find(("^.* %s forms$"):format(basic_pos_pattern)) then
				return basic_pos .. " forms"
			end
			local pl_basic_pos = pluralize_pos(basic_pos)
			if plpos == pl_basic_pos then
				-- So 'proper nouns' doesn't get converted to 'nouns' in the next round
				return plpos
			end
			local pl_basic_pos_pattern = optimized_pattern_escape(pl_basic_pos)
			if plpos:find(("^.* %s$"):format(pl_basic_pos_pattern)) then
				if preserve_lemma_status then
					local lemma_status = require(headword_module).pos_lemma_or_nonlemma(plpos)
					if lemma_status == "non-lemma form" then
						return basic_pos .. " forms"
					end
				end
				return pl_basic_pos
			end
		end
	end
end

function export.get_pos_variants(pos)
	local retval = {}
	retval.origpos = pos
	retval.plpos = canonicalize_pos(pos)
	retval.sgpos = singularize(retval.plpos)
	retval.simp_plpos = export.simplify_pos(retval.plpos)
	retval.simp_sgpos = singularize(retval.simp_plpos)
	retval.simp_with_propn_plpos = export.simplify_pos(retval.plpos, "preserve_proper_nouns")
	retval.simp_with_propn_sgpos = singularize(retval.simp_with_propn_plpos)
	return retval
end

--[==[
Canonicalize a single term or term-like object or a list of either into a list of term-like objects. `abterms` is the
term or list to canonicalize, and `field` is the name of the field holding the term (defaulting to {"term"}). This
does the minimal work necessary, meaning that the return value may partly or completely share memory with the value
passed in. As a special case, if `abterms` is {nil}, {nil} is returned. If `origin` or `originating_term` are specified,
add fields `origin` and/or `originating_term` containing the specified value(s) to each resulting term-like object (in
this case, the object will be copied a necessary to avoid side-effecting the passed-in objects). `origin` is intended to
be a string indicating where the term originated from (e.g. {"default"} if a default value, {"resolve_special"} if
originating from a shortcut value such as {"+"}) and `originating_term` is the shortcut term itself, if any. (There is
generally no such term for default values.)
]==]
function export.canonicalize_termobj_list(abterms, field, origin, originating_term)
	if abterms == nil then
		return nil
	end
	field = field or "term"
	if type(abterms) == "string" then
		return {{[field] = abterms, origin = origin, originating_term = originating_term}}
	elseif not abterms[1] then
		if origin ~= nil or originating_term ~= nil then
			abterms = shallow_copy(abterms)
			abterms.origin = origin
			abterms.originating_term = originating_term
		end
		return {abterms}
	else
		-- Check if already in full list term and return directly if so (unless `origin_val` is given, in which case we
		-- need to shallow-copy both the list and each term in it).
		local must_convert = false
		for _, term in ipairs(abterms) do
			if type(term) == "string" then
				must_convert = true
				break
			end
		end
		if not must_convert then
			if origin ~= nil or originating_term ~= nil then
				abterms = shallow_copy(abterms)
				for i, abterm in ipairs(abterms) do
					abterms[i] = shallow_copy(abterm)
					abterms[i].origin = origin
					abterms[i].originating_term = originating_term
				end
			end
			return abterms
		end
	end
	local retval = {}
	for _, term in ipairs(abterms) do
		if type(term) == "string" then
			insert(retval, {[field] = term, origin = origin, originating_term = originating_term})
		else
			if origin ~= nil or originating_term ~= nil then
				term = shallow_copy(term)
				term.origin = origin
				term.originating_term = originating_term
			end
			insert(retval, term)
		end
	end
	return retval
end

function export.canonicalize_category_list(abcats)
	-- FIXME: We should allow category objects in `headdata.categories` and not just strings. This seems to require
	-- changes to [[Module:headword]].
	if abcats == nil then
		return nil
	end
	if abcats == false then
		return {}
	end
	if type(abcats) == "string" then
		abcats = {abcats}
	end
	return abcats
end

--[==[
Insert a fixed inflection (a label not associated with any inflection values) into an `inflections` field. The
`inflections` field will be initialized if needed. `data` is an object with the following fields:
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `inflobj`: The object whose `inflections` field the terms are inserted into. Defaults to `headdata`. Only needs
   to be set for nested inflections, which are specified for an inflection object rather than the headword data
   structure as a whole.
* `label`: The label that the inflections are given; any parts of the label surrounded in `<<...>>` are linked to the
   glossary. (If the contents of `<<...>>` contain a `|` in them, they are a two-part link.) Required.
* `originating_term`: The term object from which this label is derived. If specified, decorations will be taken from
   this object.
]==]
function export.insert_fixed_inflection(data)
	local headdata, origterm, label = data.headdata, data.originating_term, data.label
	local inflobj = data.inflobj or headdata
	inflobj.inflections = inflobj.inflections or {}
	if not origterm then
		insert(inflobj.inflections, {
			label = export.replace_glossary_links_in_label(label)
		})
	else
		if origterm.id then
			error(("It doesn't make sense to pass in an ID '%s' for label '%s' in conjunction with a term value '%s'"
				):format(origterm.id, label, origterm.term))
		end
		origterm = shallow_copy(origterm)
		-- Preserve decorations
		origterm.term = nil
		origterm.label = export.replace_glossary_links_in_label(label)
		insert(inflobj.inflections, origterm)
	end
end

local function yes_and_no_cats(props)
	if props.cats and props.no_cats then
		local yes_cats = export.canonicalize_category_list(props.cats)
		local no_cats = export.canonicalize_category_list(props.no_cats)
		local cats = shallow_copy(yes_cats)
		extend(cats, no_cats)
		return cats
	end
end

local function sometimes_or_yes_and_no_cats(props)
	local sometimes_cats = export.canonicalize_category_list(props.sometimes_cats)
	if sometimes_cats then
		return sometimes_cats
	else
		return yes_and_no_cats(props)
	end
end

local function no_value_fallback_label(props)
	if props.fixed_adj_no_label then
		return props.fixed_adj_no_label
	end
	if props.fixed_adj_label then
		return "not " .. props.fixed_adj_label
	end
	return "no " .. (props.label_for_cats_and_modes or props.label)
end

local function with_value_fallback_label(props)
	if props.fixed_adj_label then
		return props.fixed_adj_label
	end
	-- FIXME, should this say 'with a plural/diminutive' etc. or is 'with plural/diminutive' enough?
	return "with " .. (props.label_for_cats_and_modes or props.label)
end

--[=[
Table describing how to handle the "mode" signals at the beginning of an inflection, generally indicating whether the
inflection exists and to what extent. The key is the mode signal itself, and the value is table with the following keys:
* `exists`: The value to return in the `exists` field of the object returned by `process_for_insertion`. This is
  currently used in calling code simply to check for different modes; it is an easier-to-read equivalent of the mode
  signal itself.
* `prefix`: The prefix used to directly specify the label and category/categories associated with the mode in calling
  code. For example, the mode `--+` (which also arises when `-` is used with a following term) has prefix `usually_no_`,
  which means that to directly specify its label, use `usually_no_label` and to directly specify its categories, use
  `usually_no_cats`. If these fields don't exist, the functions in `fallback_label` and `fallback_cats` are used to
  generate the label and categories.
* `fallback_label`: This is a function of one argument, `props` (the properties passed in by the caller), which should
  generate the label if the user didn't directly specify a label (see `prefix` above).
* `fallback_cats`: This is a function of one argument, `props` (the properties passed in by the caller), which should
  generate the categories if the user didn't directly specify them (see `prefix` above).
* `add_default`: If true, the code will attempt to add a default value if the user specifies this mode without giving
  additional terms. This depends on the caller passing in a `mode_default` property (which can be a string, a term
  object, a list of either, or a function generating any of those values). In many cases the `mode_default` property
  may simply have a value such as {"+"}, which is processed later by resolve_special().
* `disallow_additional`: If true, no additional terms are allowed after the mode signal; if present, an error is
  thrown.
]=]
local special_modes = {
	["-"] = {exists = "no", prefix = "no_",
		fallback_label = no_value_fallback_label,
	}, -- converted to "--+" if a term follows
	["--+"] = {exists = "usually no", prefix = "usually_no_", add_default = true,
		fallback_label = function(props)
			if props.no_label then
				return "usually " .. props.no_label
			end
			return "usually " .. no_value_fallback_label(props)
		end,
		fallback_cats = sometimes_or_yes_and_no_cats,
	},
	["+-"] = {exists = "sometimes", prefix = "sometimes_", add_default = true,
		fallback_label = function(props)
			return "sometimes " .. with_value_fallback_label(props)
		end,
		fallback_cats = yes_and_no_cats,
	},
	["++-"] = {exists = "usually", prefix = "usually_", add_default = true,
		fallback_label = function(props)
			return "sometimes " .. with_value_fallback_label(props)
		end,
		fallback_cats = sometimes_or_yes_and_no_cats,
	},
	["!"] = {exists = "unattested", prefix = "unattested_", disallow_additional = true,
		fallback_label = function(props)
			return props.label_for_cats_and_modes .. " unattested"
		end,
		-- No default cats; provided for plurals in inflection_to_cats_and_label.
	},
	["?"] = {exists = "unknown", prefix = "unknown_", disallow_additional = true,
		-- No default label as people have preferred not to see 'plural unknown or uncertain'
		-- written out. No default cats; provided for plurals in inflection_to_cats_and_label.
	},
}

function export.process_for_insertion(data)
	local terms, mode_default, headdata = data.terms, data.mode_default, data.headdata
	local retval = {}

	if terms and terms[1] then
		local mode = terms[1].term
		local modespec = special_modes[mode]
		if modespec then
			terms = shallow_copy(terms)
			retval.mode_term = terms[1]
			remove(terms, 1)
			if mode == "-" and terms[1] then
				mode = "--+"
			end
			if terms[1] and modespec.disallow_additional then
				error(("It doesn't make sense to specify explicit terms along with mode signal %s (%s)"):format(
					mode, modespec.exists))
			elseif not terms[1] and modespec.add_default and mode_default then
				if type(mode_default) == "function" then
					mode_default = mode_default(headdata, retval.mode_term)
				end
				if mode_default then
					terms = export.canonicalize_termobj_list(mode_default, "term", "mode_default", retval.mode_term)
				end
			end
			retval.numterms = #terms
			retval.terms = terms
			retval.mode = mode
			retval.exists = modespec.exists
			retval.prefix = modespec.prefix
		else
			retval.numterms = #terms
			retval.terms = terms
			retval.exists = "yes"
			retval.prefix = ""
		end
	else
		retval.numterms = 0
		retval.terms = {}
		-- retval.exists = nil
		retval.request = data.request
	end
	return retval
end


--[==[
Insert previously-parsed terms into an `inflections` field. The `inflections` field will be initialized if needed.
`data` is an object with the following fields:
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `inflobj`: The object whose `inflections` field the terms are inserted into. Defaults to `headdata`. Only needs
   to be set for nested inflections, which are specified for an inflection object rather than the headword data
   structure as a whole.
* `terms`: The list of parsed terms. If {nil} or omitted, nothing happens unless `request` is set.
* `label`: The label that the inflections are given; any parts of the label surrounded in `<<...>>` are linked to the
   glossary. (If the contents of `<<...>>` contain a `|` in them, they are a two-part link.) Required.
* `fixed_adj_label`: If specified, an adjective used to construct the defaults for the fixed labels specified by
   `no_label`, `usually_no_label` and `sometimes_label`. Examples are "comparable" for a comparative and "countable"
   for a plural.
* `no_label`: If the term is {"-"} and there are no other terms, insert a fixed label with this value. If
   `fixed_adj_label` is given, defaults to {"not "} plus the adjective, else {"no "} plus the label.
* `usually_no_label`: If the term is {"-"} and there are other terms, insert a fixed label with this value. Defaults to
   {"usually "} plus the value of `no_label`.
* `sometimes_label`: If the term is {"+-"}, insert a fixed label with this value. If `fixed_adj_label` is given,
   defaults to {"sometimes "} plus the adjective, else {"sometimes with a(n) "} plus the label.
* `cats`: List of categories to insert when terms are given that are not {"-"}. Each category is a string naming a full
   category to insert (including the appropriate language name prefixed).
* `no_cats`: List of categories to insert when a term is given as {"-"}.
* `usually_no_cats`: List of categories to insert when a term is given as {"-"} and additional terms are specified as
   well (representing, e.g. for the inflection {"plural"}, a term which usually has no plural but does under some
   circumstances). If omitted, both the categories in `cats` and `no_cats` are inserted.
* `sometimes_cats`: List of categories to insert when a term is given as {"+-"} (indicating that the inflection
   sometimes exists and sometimes does not, normally depending on the precise sense involved). If omitted, both the
   categories in `cats` and `no_cats` are inserted (same default as for `usually_no_cats`).
* `accel`: If specified, a full accelerator object to add to the inflections.
* `request`: If specified and no terms are given, insert a label with a request for inflections to be given.
* `enable_auto_translit`: If specified and terms are given, display automatic transliteration of the terms.

The return value indicates whether the inflection exists and how many terms are in it. It is an object with the
following fields:
* `exists`: {"yes"} if one or more terms were specified; {"no"} if the value was given as {"-"}; {"usually no"} if
  the first value was given as {"-"} but additional terms were supplied; otherwise {nil}, indicating that the status
  is unspecified.
* `numterms`: Number of terms in the inflection. Will be 0 unless `exists` has the value {"yes"} or {"usually no"}.
* `terms`: The terms that were inserted. If there are no terms, this is an empty list.
* `request`: True if no terms were specified but a term request was inserted into the inflection (because
  `data.request` was specified). Otherwise {nil}.
]==]
function export.insert_processed_inflection(data)
	local headdata, processed, label = data.headdata, data.processed, data.label
	local inflobj = data.inflobj or headdata
	local accel = data.accel
	if data.accel_form then
		if accel then
			error("Internal error: can't specify both data.accel and data.accel_form")
		end
		if headdata.heads then
			local lemmas = {}
			local lemma_translits = {}
			for i, headobj in ipairs(headdata.heads) do
				lemmas[i] = headobj.term
				if lemmas[i] == "+" then
					error("Internal error: If you use data.accel_form, you should have resolved all occurrences of + in heads appropriately")
				end
				lemma_translits[i] = headobj.tr
			end
			accel = {
				lemma = lemmas,
				lemma_translit = lemma_translits,
				form = data.accel_form,
			}
		else
			accel = {
				form = data.accel_form,
			}
		end
	end

	local function insert_cats(cats)
		for _, cat in ipairs(cats) do
			insert(headdata.categories, cat)
		end
	end

	-- Handle the fixed label (if any) and cats (if any) associated with a mode.
	if processed.mode then
		local modespec = special_modes[processed.mode]
		local mode_prefix = modespec.prefix
		local fixed_label = data[mode_prefix .. "label"]
		if not fixed_label and modespec.fallback_label then
			fixed_label = modespec.fallback_label(data)
		end
		if fixed_label then
			export.insert_fixed_inflection {
				headdata = headdata,
				inflobj = inflobj,
				originating_term = processed.mode_term,
				label = fixed_label,
			}
		end
		local mode_cats = data[mode_prefix .. "cats"]
		if not mode_cats and modespec.fallback_cats then
			mode_cats = modespec.fallback_cats(data)
		end
		mode_cats = export.canonicalize_category_list(mode_cats)
		if mode_cats then
			insert_cats(mode_cats)
		end
	elseif data.cats then
		-- If no mode, no fixed label but there may be categories.
		insert_cats(data.cats)
	end

	local terms = processed.terms
	if terms and terms[1] then
		-- FIXME, if there's a mode we shallow_copy() twice.
		terms = shallow_copy(terms)
		terms.label = export.replace_glossary_links_in_label(label)
		if accel then
			terms.accel = accel
		end
		terms.enable_auto_translit = data.enable_auto_translit
		inflobj.inflections = inflobj.inflections or {}
		insert(inflobj.inflections, terms)
	elseif processed.request then
		inflobj.inflections = inflobj.inflections or {}
		insert(inflobj.inflections, {
			label = export.replace_glossary_links_in_label(label),
			request = true,
		})
	end
end


--[==[
Insert previously-parsed terms into an `inflections` field. The `inflections` field will be initialized if needed.
`data` is an object with the following fields:
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `inflobj`: The object whose `inflections` field the terms are inserted into. Defaults to `headdata`. Only needs
   to be set for nested inflections, which are specified for an inflection object rather than the headword data
   structure as a whole.
* `terms`: The list of parsed terms. If {nil} or omitted, nothing happens unless `request` is set.
* `label`: The label that the inflections are given; any parts of the label surrounded in `<<...>>` are linked to the
   glossary. (If the contents of `<<...>>` contain a `|` in them, they are a two-part link.) Required.
* `fixed_adj_label`: If specified, an adjective used to construct the defaults for the fixed labels specified by
   `no_label`, `usually_no_label` and `sometimes_label`. Examples are "comparable" for a comparative and "countable"
   for a plural.
* `no_label`: If the term is {"-"} and there are no other terms, insert a fixed label with this value. If
   `fixed_adj_label` is given, defaults to {"not "} plus the adjective, else {"no "} plus the label.
* `usually_no_label`: If the term is {"-"} and there are other terms, insert a fixed label with this value. Defaults to
   {"usually "} plus the value of `no_label`.
* `sometimes_label`: If the term is {"+-"}, insert a fixed label with this value. If `fixed_adj_label` is given,
   defaults to {"sometimes "} plus the adjective, else {"sometimes with a(n) "} plus the label.
* `cats`: List of categories to insert when terms are given that are not {"-"}. Each category is a string naming a full
   category to insert (including the appropriate language name prefixed).
* `no_cats`: List of categories to insert when a term is given as {"-"}.
* `usually_no_cats`: List of categories to insert when a term is given as {"-"} and additional terms are specified as
   well (representing, e.g. for the inflection {"plural"}, a term which usually has no plural but does under some
   circumstances). If omitted, both the categories in `cats` and `no_cats` are inserted.
* `sometimes_cats`: List of categories to insert when a term is given as {"+-"} (indicating that the inflection
   sometimes exists and sometimes does not, normally depending on the precise sense involved). If omitted, both the
   categories in `cats` and `no_cats` are inserted (same default as for `usually_no_cats`).
* `accel`: If specified, a full accelerator object to add to the inflections.
* `request`: If specified and no terms are given, insert a label with a request for inflections to be given.
* `enable_auto_translit`: If specified and terms are given, display automatic transliteration of the terms.

The return value indicates whether the inflection exists and how many terms are in it. It is an object with the
following fields:
* `exists`: {"yes"} if one or more terms were specified; {"no"} if the value was given as {"-"}; {"usually no"} if
  the first value was given as {"-"} but additional terms were supplied; otherwise {nil}, indicating that the status
  is unspecified.
* `numterms`: Number of terms in the inflection. Will be 0 unless `exists` has the value {"yes"} or {"usually no"}.
* `terms`: The terms that were inserted. If there are no terms, this is an empty list.
* `request`: True if no terms were specified but a term request was inserted into the inflection (because
  `data.request` was specified). Otherwise {nil}.
]==]
function export.insert_inflection(data)
	local headdata, terms, mode_default = data.headdata, data.terms, data.mode_default
	local processed = export.process_for_insertion {
		headdata = headdata,
		terms = terms,
		mode_default = mode_default,
	}
	data = shallow_copy(data)
	data.processed = processed
	export.insert_processed_inflection(data)
	return processed
end

--[==[
Parse raw arguments from `forms` for inline modifiers, and insert the resulting terms (which should not require
significant additional processing) into `headdata.inflections`. `data` is an object with the following fields:
* `forms`: The list of raw values to parse. If {nil} or omitted, nothing happens.
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `paramname`: As in `parse_term_list_with_modifiers()`. Required.
* `label`: As in `insert_inflection()`. Required.
* `qualifiers`, `frob`, `include_mods`, `exclude_mods`, `is_head`, `splitchar`, `preserve_splitchar`, `delimiter_key`,
  `escape_fun`, `unescape_fun`, `pre_normalize_modifiers`: As in `parse_term_list_with_modifiers()`.
* `accel`: As in `insert_inflection()`.

Return value is as in `insert_inflection()`.
]==]
function export.parse_and_insert_inflection(data)
	local forms = data.forms
	if forms and forms[1] then
		data = shallow_copy(data)
		data.forms = forms
		data.terms = export.parse_term_list_with_modifiers(data)
		return export.insert_inflection(data)
	end
	return {
		numterms = 0
	}
end


--[==[
Combine two sets of decorations. If either is {nil}, just return the other, and if both are {nil}, return {nil}.
]==]
function export.combine_decorations(decs1, decs2)
	if not decs1 and not decs2 then
		return nil
	end
	if not decs1 then
		return decs2
	end
	if not decs2 then
		return decs1
	end
	local combined = shallow_copy(decs1)
	for _, dec in ipairs(decs2) do
		insert_if_not(combined, dec)
	end
	return combined
end

function export.combine_qualifiers_or_labels(...)
	-- FIXME: Added 2026-09-17. Remove after a month.
	error("Use combine_decorations instead")
end

--[==[
Combine the decorations (qualifiers, labels, references) and ID's of two term objects. `destobj` is the "destination
term object" into which the combined properties are written, and `srcobj` is the "source object" into which the
properties are merged. `destobj` is side-effected (but the lists inside of `destobj` are not); if this is undesirable,
make sure to shallow-copy `destobj` first. If both objects have values for a given decoration, the values of `destobj`
come first. If both objects have a value for `id`, the values must match or an error is thrown; otherwise, the resulting
value of `id` comes from whichever one is defined.

'''NOTE:''' This may not be the correct behavior when deduplicating a list of term objects. See
`insert_termobj_combining_duplicates` for a different approach.
]==]
function export.combine_termobj_decorations(destobj, srcobj)
	destobj.q = export.combine_decorations(destobj.q, srcobj.q)
	destobj.qq = export.combine_decorations(destobj.qq, srcobj.qq)
	destobj.l = export.combine_decorations(destobj.l, srcobj.l)
	destobj.ll = export.combine_decorations(destobj.ll, srcobj.ll)
	destobj.refs = export.combine_decorations(destobj.refs, srcobj.refs)
	if destobj.id and srcobj.id and destobj.id ~= srcobj.id then
		-- FIXME: We probably want to pass in an error function
		error(("Can't specify two different ID's %s and %s when combining objects"):format(srcobj.id, destobj.id))
	end
	destobj.id = destobj.id or srcobj.id
	return destobj
end

function export.combine_termobj_qualifiers_labels(...)
	-- FIXME: Added 2026-09-17. Remove after a month.
	error("Use combine_termobj_decorations instead")
end


function export.termobj_has_decorations(obj)
	return obj.q and obj.q[1] or obj.qq and obj.qq[1] or obj.l and obj.l[1] or obj.ll and obj.ll[1] or
		obj.refs and obj.refs[1]
end

function export.termobj_has_qualifiers_or_labels(...)
	-- FIXME: Added 2026-09-17. Remove after a month.
	error("Use termobj_has_decorations instead")
end


local function one_decoration_equal(prop1, prop2)
	local prop1_is_nil = not prop1 or not prop1[1]
	local prop2_is_nil = not prop2 or not prop2[1]
	if prop1_is_nil and prop2_is_nil then
		return true
	end
	if prop1_is_nil or prop2_is_nil then
		return false
	end
	return deep_equals(prop1, prop2)
end

function export.termobj_decorations_equal(obj1, obj2)
	return one_decoration_equal(obj1.q, obj2.q) and
		one_decoration_equal(obj1.qq, obj2.qq) and
		one_decoration_equal(obj1.l, obj2.l) and
		one_decoration_equal(obj1.ll, obj2.ll) and
		one_decoration_equal(obj1.refs, obj2.refs) and
		obj1.id == obj2.id
end

function export.termobj_ancillary_properties_equal(...)
	-- FIXME: Added 2026-09-17. Remove after a month.
	error("Use termobj_decorations_equal instead")
end


function export.convert_termobj_to_formobj(termobj)
	local formobj = {
		form = termobj.term,
		translit = termobj.tr,
	}
	local footnotes
	local function mods_to_footnote(mod_prefix, mod_vals)
		if mod_vals and mod_vals[1] then
			footnotes = footnotes or {}
			for _, val in ipairs(mod_vals) do
				insert(footnotes, "[" .. mod_prefix .. ":" .. val .. "]")
			end
		end
	end
	mods_to_footnote("q", termobj.q)
	mods_to_footnote("qq", termobj.qq)
	mods_to_footnote("l", termobj.l)
	mods_to_footnote("ll", termobj.ll)
	mods_to_footnote("ref", termobj.refs)
	mods_to_footnote("id", termobj.id and {termobj.id} or nil)
	formobj.footnotes = footnotes
	return formobj
end

local recognized_multi_mods = {
	q = "q",
	qq = "qq",
	l = "l",
	ll = "ll",
	ref = "refs",
}
local recognized_single_mods = {
	id = "id",
}

function export.add_footnote_to_termobj(termobj, footnote)
	local stripped_footnote = footnote:match("^%[(.*)%]$")
	if not stripped_footnote then
		error("Internal error: Footnote should be surrounded by brackets at this stage: " .. footnote)
	end
	local prefix, rest = stripped_footnote:match("^([a-z]+):(.+)$")
	local field, is_multi
	if prefix then
		if recognized_multi_mods[prefix] then
			field = recognized_multi_mods[prefix]
			is_multi = true
		elseif recognized_single_mods[prefix] then
			field = recognized_single_mods[prefix]
			is_multi = false
		end
	end
	if not field then
		rest = stripped_footnote
		field = "l"
		is_multi = true
	end
	if is_multi then
		if not termobj[field] then
			termobj[field] = {}
		end
		insert(termobj[field], rest)
	else
		if termobj[field] and termobj[field] ~= rest then
			error(("Can't set two values for '%s': '%s' and '%s'"):format(field, termobj[field], rest))
		end
		termobj[field] = rest
	end
end

function export.convert_formobj_to_termobj(formobj)
	local termobj = {
		term = formobj.form,
		tr = formobj.translit,
	}
	if formobj.footnotes then
		for _, footnote in ipairs(formobj.footnotes) do
			export.add_footnote_to_termobj(termobj, footnote)
		end
	end
	return termobj
end

local function extract_termobj_field_modifiers(fieldval)
	return fieldval:match("^([*+]?)(.*)$")
end

function export.remove_termobj_field_modifiers(termobj)
	local function remove_field_modifiers(field)
		if termobj[field] and termobj[field][1] then
			local any_field_modifiers = false
			for _, val in ipairs(termobj[field]) do
				local field_mods, _ = extract_termobj_field_modifiers(val)
				if field_mods ~= "" then
					any_field_modifiers = true
					break
				end
			end
			local new_field = {}
			if any_field_modifiers then
				for _, val in ipairs(termobj[field]) do
					local _, field_without_mods = extract_termobj_field_modifiers(val)
					insert_if_not(new_field, field_without_mods)
				end
				termobj[field] = new_field
			end
		end
	end

	remove_field_modifiers("q")
	remove_field_modifiers("qq")
	remove_field_modifiers("l")
	remove_field_modifiers("ll")
	remove_field_modifiers("refs")
end

function export.insert_termobj_combining_duplicates(destobjs, termobj)
	for _, destobj in ipairs(destobjs) do
		if destobj.term == termobj.term and destobj.tr == termobj.tr then
			-- Form already present; maybe combine footnotes.
			local function combine_field_values(field)
				if termobj[field] and termobj[field][1] then
					-- Check to see if there are existing values with *; if so, remove them.
					if destobj[field] and destobj[field][1] then
						local any_values_with_asterisk = false
						for _, val in ipairs(destobj[field]) do
							local field_mods, _ = extract_termobj_field_modifiers(val)
							if field_mods:find("%*") then
								any_values_with_asterisk = true
								break
							end
						end
						if any_values_with_asterisk then
							local filtered_values = {}
							for _, val in ipairs(destobj[field]) do
								local field_mods, _ = extract_termobj_field_modifiers(val)
								if not field_mods:find("%*") then
									insert(filtered_values, val)
								end
							end
							if filtered_values[1] then
								destobj[field] = filtered_values
							else
								destobj[field] = nil
							end
						end
					end

					local any_footnotes_with_plus = false
					for _, val in ipairs(termobj[field]) do
						local field_mods, _ = extract_termobj_field_modifiers(val)
						if field_mods:find("%+") then
							any_footnotes_with_plus = true
							break
						end
					end
					if any_footnotes_with_plus then
						if not destobj[field] then
							destobj[field] = {}
						else
							destobj[field] = shallow_copy(destobj[field])
						end
						for _, val in ipairs(termobj[field]) do
							local already_seen = false
							local field_mods, field_without_mods = extract_termobj_field_modifiers(val)
							if field_mods:find("%+") then
								for _, existing_val in ipairs(destobj[field]) do
									local _, existing_field_without_mods =
										extract_termobj_field_modifiers(existing_val)
									if existing_field_without_mods == field_without_mods then
										already_seen = true
										break
									end
								end
								if not already_seen then
									insert(destobj[field], val)
								end
							end
						end
					end
				end
			end

			combine_field_values("q")
			combine_field_values("qq")
			combine_field_values("l")
			combine_field_values("ll")
			combine_field_values("refs")
			if destobj.id and termobj.id and destobj.id ~= termobj.id then
			    -- FIXME: We probably want to pass in an error function
			    error(("Can't specify two different ID's %s and %s when combining objects"):format(termobj.id, destobj.id))
			end
			destobj.id = destobj.id or termobj.id
			return
		end
	end
	insert(destobjs, termobj)
end


export.allowed_special_indicators = {
	["first"] = true,
	["first-second"] = true,
	["first-last"] = true,
	["second"] = true,
	["last"] = true,
	["each"] = true,
	["+"] = true, -- requests the default behavior with preposition handling
}

--[==[
Check for special indicators (values such as {"+first"} or {"+first-last"} that are used in a `pl`, `f`, etc. argument
and indicate how to inflect a multiword term). If `form` is such an indicator, the return value is `form` minus
the initial `+` sign; otherwise, if form begins with a `+` sign, an error is thrown; otherwise the return value is nil.
]==]
function export.get_special_indicator(form, noerror)
	if form:find("^%+") then
		form = form:gsub("^%+", "")
		if not export.allowed_special_indicators[form] then
			if noerror then
				return nil
			end
			local indicators = {}
			for indic, _ in pairs(export.allowed_special_indicators) do
				insert(indicators, "+" .. indic)
			end
			sort(indicators)
			error("Special inflection indicator beginning with '+' can only be " ..
				mw.text.listToText(indicators) .. ": +" .. form)
		end
		return form
	end
	return nil
end

local function add_endings(bases, endings)
	local retval = {}
	if type(bases) ~= "table" then
		bases = {bases}
	end
	if type(endings) ~= "table" then
		endings = {endings}
	end
	for _, base in ipairs(bases) do
		for _, ending in ipairs(endings) do
			insert(retval, base .. ending)
		end
	end
	return retval
end

--[==[
Inflect a possibly multiword or hyphenated term `form` using the function `inflect`, which is a function of one argument
that is called on a single word to inflect and should return either the inflected word or a list of inflected words.
`special` indicates how to inflect the multiword term and should be e.g. {"first"} to inflect only the first word,
{"first-last"} to inflect the first and last words, {"each"} to inflect each word, etc. See `allowed_special_indicators`
above for the possibilities. If `special` is `+`, or is omitted and the term is multiword (i.e. containing a space
character), and `prepositions` is supplied, the function checks for multiword or hyphenated terms containing the
prepositions in `prepositions`, e.g. Italian [[senso di marcia]] or [[medaglia d'oro]] or Portuguese
[[tartaruga-do-mar]]. If such a term is found, only the first word is inflected. Otherwise, the default is
{"first-last"}. `prepositions` is a list of Lua patterns matching prepositions. The patterns will automatically have the
separator character (space or hyphen) added to the left side but not the right side, so they should contain a space
character (which will automatically be converted to the appropriate separator) on the right side unless the preposition
is joined on the right side with an apostrophe. Examples of preposition patterns for Italian are {"di "}, {"sull'"} and
{"d?all[oae] "} (which matches {"dallo "}, {"dalle "}, {"alla "}, etc.).

The return value is always either a list of inflected multiword or hyphenated terms, or nil if `special` is omitted
and `form` is not multiword. (If `special` is specified and `form` is not multiword or hyphenated, an error results.)
]==]
function export.handle_multiword(form, special, inflect, prepositions, sep)
	sep = sep or form:find(" ") and " " or "%-"
	local raw_sep = sep == " " and " " or "-"
	-- Used to add regex version of separator in the replacement portion of ugsub() or :gsub()
	local sep_replacement = sep == " " and " " or "%%-"

	-- Given a Lua pattern, replace space with the appropriate separator.
	local function hack_re(re)
		if sep == " " then
			return re
		end
		return (re:gsub(" ", sep_replacement))
	end

	if special == "first" then
		local first, rest = form:match(hack_re("^(.-)( .*)$"))
		if not first then
			error("Special indicator 'first' can only be used with a multiword term: " .. form)
		end
		return add_endings(inflect(first), rest)
	elseif special == "second" then
		local first, second, rest = form:match(hack_re("^([^ ]+ )([^ ]+)( .*)$"))
		if not first then
			error("Special indicator 'second' can only be used with a term with three or more words: " .. form)
		end
		return add_endings(add_endings({first}, inflect(second)), rest)
	elseif special == "first-second" then
		local first, space, second, rest = form:match(hack_re("^([^ ]+)( )([^ ]+)( .*)$"))
		if not first then
			error("Special indicator 'first-second' can only be used with a term with three or more words: " .. form)
		end
		return add_endings(add_endings(add_endings(inflect(first), space), inflect(second)), rest)
	elseif special == "each" then
		local terms = split(form, sep)
		if #terms < 2 then
			error("Special indicator 'each' can only be used with a multiword term: " .. form)
		end
		for i, term in ipairs(terms) do
			terms[i] = inflect(term)
			if i > 1 then
				terms[i] = add_endings(raw_sep, terms[i])
			end
		end
		local result = ""
		for _, term in ipairs(terms) do
			result = add_endings(result, term)
		end
		return result
	elseif special == "first-last" then
		local first, middle, last = form:match(hack_re("^(.-)( .* )(.-)$"))
		if not first then
			first, middle, last = form:match(hack_re("^(.-)( )(.*)$"))
		end
		if not first then
			error("Special indicator 'first-last' can only be used with a multiword term: " .. form)
		end
		return add_endings(add_endings(inflect(first), middle), inflect(last))
	elseif special == "last" then
		local rest, last = form:match(hack_re("^(.* )(.-)$"))
		if not rest then
			error("Special indicator 'last' can only be used with a multiword term: " .. form)
		end
		return add_endings(rest, inflect(last))
	elseif special and special ~= "+" then
		error("Unrecognized special=" .. special)
	end

	-- Only do default behavior if special indicator '+' explicitly given or separator is space; otherwise we will
	-- break existing behavior with hyphenated words.
	if (special == "+" or sep == " ") and form:find(sep) then
		if prepositions then
			-- check for prepositions in the middle of the word; do it this way so we can handle
			-- more than one word before the preposition (and usually inflect each word)
			for _, prep in ipairs(prepositions) do
				local first, space_prep_rest = umatch(form, hack_re("^(.-)( " .. prep .. ".*)$"))
				if first then
					return add_endings(inflect(first), space_prep_rest)
				end
			end
		end

		-- multiword or hyphenated expressions default to first-last; we need to pass in the separator to avoid
		-- problems with multiword terms containing hyphens in the individual words
		return export.handle_multiword(form, "first-last", inflect, prepositions, sep)
	end

	return nil
end


local function link_hyphen_split_component(word, data)
	if data.link_hyphen_split_component then
		return data.link_hyphen_split_component(word)
	else
		return "[[" .. word .. "]]"
	end
end


-- Default function to split a word on apostrophes. Don't split apostrophes at the beginning or end of a word (e.g.
-- [['ndrangheta]] or [[po']]). Handle multiple apostrophes correctly, e.g. [[l'altr'ieri]] -> [[l']][altr']][[ieri]].
function export.default_split_apostrophe(word, data)
	local apostrophe_parts = split(word, "'", true, true)
	local linked_apostrophe_parts = {}
	local apostrophes_at_beginning = ""
	local i = 1
	-- Apostrophes at beginning get attached to the first word after (which will always exist but may
	-- be blank if the word consists only of apostrophes).
	while i < #apostrophe_parts do -- <, not <=, in case the word consists only of apostrophes
		local apostrophe_part = apostrophe_parts[i]
		i = i + 1
		if apostrophe_part == "" then
			apostrophes_at_beginning = apostrophes_at_beginning .. "'"
		else
			break
		end
	end
	apostrophe_parts[i] = apostrophes_at_beginning .. apostrophe_parts[i]
	-- Now, do the remaining parts. A blank part indicates more than one apostrophe in a row; we join
	-- all of them to the preceding word.
	while i <= #apostrophe_parts do
		local apostrophe_part = apostrophe_parts[i]
		if apostrophe_part == "" then
			linked_apostrophe_parts[#linked_apostrophe_parts] =
				linked_apostrophe_parts[#linked_apostrophe_parts] .. "'"
		elseif i == #apostrophe_parts then
			insert(linked_apostrophe_parts, apostrophe_part)
		else
			insert(linked_apostrophe_parts, apostrophe_part .. "'")
		end
		i = i + 1
	end
	for j, tolink in ipairs(linked_apostrophe_parts) do
		linked_apostrophe_parts[j] = link_hyphen_split_component(tolink, data)
	end
	return concat(linked_apostrophe_parts)
end


--[=[
Auto-add links to a word that should not have spaces but may have hyphens and/or apostrophes. We split off final
punctuation, then split on hyphens if `data.split_hyphen` is given, and also split on apostrophes if
`data.split_apostrophe` is given. We only split on hyphens if they are in the middle of the word, not at the beginning
or end (hyphens at the beginning or end indicate suffixes or prefixes, respectively). `include_hyphen_prefixes`, if
given, is a set of prefixes (not including the final hyphen) where we should include the final hyphen in the prefix.
Hence, e.g. if "anti" is in the set, a Portuguese word like [[anti-herói]] "anti-hero" will be split [[anti-]][[herói]]
(whereas a word like [[código-fonte]] "source code" will be split as [[código]]-[[fonte]]).

If `data.split_apostrophe` is specified, we split on apostrophes unless `data.no_split_apostrophe_words` is given and
the word is in the specified set, such as French [[c'est]] and [[quelqu'un]]. If `data.split_apostrophe` is true, the
default algorithm applies, which splits on all apostrophes except those at the beginning and end of a word (as in
Italian [['ndrangheta]] or [[po']]), and includes the apostrophe in the link to its left (so we auto-split French
[[l'eau]] as [[l']][[eau]] and [[l'altr'ieri]] as [[l']][altr']][[ieri]]). If `data.split_apostrophe` is specified
but not `true`, it should be a function of one argument that does custom apostrophe-splitting. The argument is the word
to split, and the return value should be the split and linked word.
]=]
local function add_single_word_links(space_word, data, term_has_spaces)
	local space_word_no_punct, punct
	local punct_pattern = data.punctuation
	if punct_pattern and is_callable(punct_pattern) then
		space_word_no_punct, punct = punct_pattern(space_word)
	else
		if punct_pattern == nil then
			punct_pattern = "[,;:?!]"
		end
		space_word_no_punct, punct = umatch(space_word, "^(.*)(" .. punct_pattern .. ")$")
	end
	space_word_no_punct = space_word_no_punct or space_word
	punct = punct or ""
	local words
	if space_word_no_punct:sub(1, 1) == "-" or space_word_no_punct:sub(-1) == "-" then
		-- don't split prefixes and suffixes
		words = {space_word_no_punct}
	else
		local splitter
		if term_has_spaces then
			splitter = data.split_hyphen_when_space
		else
			splitter = data.split_hyphen_when_no_space
		end
		if is_callable(splitter) then
			words = splitter(space_word_no_punct)
			if type(words) == "string" then
				return words .. punct
			end
		end
	end
	if not words then
		local split_hyphen
		if term_has_spaces then
			split_hyphen = data.split_hyphen_when_space
		else
			split_hyphen = data.split_hyphen_when_no_space
			if split_hyphen == nil then -- default to true; use `false` to avoid this
				split_hyphen = true
			end
		end
		if split_hyphen then
			words = split(space_word_no_punct, "-", true, true)
		else
			words = {space_word_no_punct}
		end
	end
	local linked_words = {}
	for j, word in ipairs(words) do
		if j < #words and data.include_hyphen_prefixes and data.include_hyphen_prefixes[word] then
			word = "[[" .. word .. "-]]"
		elseif j > 1 and data.include_hyphen_suffixes and data.include_hyphen_suffixes[word] then
			word = "[[-" .. word .. "]]"
		else
			-- Don't split on apostrophes if the word is in `no_split_apostrophe_words`.
			if (not data.no_split_apostrophe_words or not data.no_split_apostrophe_words[word]) and
				data.split_apostrophe and word:find("'", nil, true) then
				if data.split_apostrophe == true then
					word = export.default_split_apostrophe(word, data)
				else -- custom apostrophe splitter/linker
					word = data.split_apostrophe(word)
				end
			elseif word ~= "" then -- avoid -[[]]- (e.g. f--k)
				word = link_hyphen_split_component(word, data)
			end
			if j < #words then
				word = word .. "-"
			end
		end
		insert(linked_words, word)
	end
	return concat(linked_words) .. punct
end

--[=[
Auto-add links to a multiword term. `data` contains fields customizing how to do this. By default we proceed as follows:

(1) If the term already has embedded links in it, they are left unchanged.
(2) Otherwise, if there are spaces present, we split on spaces and link each word separately.
(3) If a given space-separated component ends in punctuation (defaulting to [,;:?!]), it is separated off, the remainder
    of the algorithm run, and the punctuation pasted back on.
(4) If there are hyphens in a given space-separated component, we may link each hyphenated term separately depending
    on the settings in `data`. Normally the hyphens are not included in the linked terms, but this can be overridden
    for specific prefixes and/or suffixes. By default, if there are spaces in the multiword term, we do not link
	hyphenated components (because of cases like "boire du petit-lait" where "petit-lait" should be linked as a whole),
	but do so otherwise (e.g. for "avant-avant-hier"); this can overridden for cases like "croyez-le ou non".
	Cases where only some of the hyphens should be split can always be handled by explicitly specifying the head (e.g.
	"Nord-Pas-de-Calais" given as head=[[Nord]]-[[Pas-de-Calais]]).
(5) If there are apostrophes in a given component, we may link each apostrophe-separated term separately depending
    on the settings in `data`, including the apostrophe in the link to its left (so we split "de l'eau" as
	"[[de]] [[l']][[eau]]").

The settings in `data` are as follows:

`split_hyphen_when_no_space`: Whether to split on hyphens when the term has no spaces. Defaults to true if set to `nil`.
   This can be a function of one argument, to implement a custom splitting algorithm for hyphen-separated terms. If
   this returns [FIXME: FINISH ME ...]


If `data.split_apostrophe` is specified, we split on apostrophes unless `data.no_split_apostrophe_words` is given and
the word is in the specified set, such as French [[c'est]] and [[quelqu'un]]. If `data.split_apostrophe` is true, the
default algorithm applies, which splits on all apostrophes except those at the beginning and end of a word (as in
Italian [['ndrangheta]] or [[po']]), and includes the apostrophe in the link to its left (so we auto-split French
[[l'eau]] as [[l']][[eau]] and [[l'altr'ieri]] as [[l']][altr']][[ieri]]). If `data.split_apostrophe` is specified
but not `true`, it should be a function of one argument that does custom apostrophe-splitting. The argument is the word
to split, and the return value should be the split and linked word.

We don't always split on hyphens because of cases like "boire du petit-lait" where "petit-lait" should be linked as a
whole, but provide the option to do it for cases like "croyez-le ou non". If there's no space, however, then it makes
sense to split on hyphens by `no_split_apostrophe_words` and `include_hyphen_prefixes` allow for special-case handling
of particular words and are as described in the comment above add_single_word_links().
]=]
function export.add_links_to_multiword_term(term, data)
	if term:match("[%[%]]") then
		return term
	end
	local words = split(term, " ", true, true)
	local term_has_spaces = #words > 1
	local linked_words = {}
	for _, word in ipairs(words) do
		insert(linked_words, add_single_word_links(word, data, term_has_spaces))
	end
	local retval = concat(linked_words, " ")
	-- If we ended up with a single link consisting of the entire term,
	-- remove the link.
	return retval:match("^%[%[([^%[%]]*)%]%]$") or retval
end

local function canonicalize_begin_end_spec(spec)
	local from, to = spec:match("^(.-):(.*)$")
	if not from then
		from = spec
		to = ""
	end
	return from, to
end

--[==[
Given a `linked_term` that is the output of add_links_to_multiword_term(), apply modifications as given in
`modifier_spec` to change the link destination of subterms (normally single-word non-lemma forms; sometimes
collections of adjacent words). This is usually used to link non-lemma forms to their corresponding lemma, but can
also be used to replace a span of adjacent separately-linked words to a single multiword lemma. The format of
`modifier_spec` is one or more semicolon-separated subterm specs, where each such spec is of the form
SUBTERM:DEST, where SUBTERM is one or more words in the `linked_term` but without brackets in them, and DEST is the
corresponding link destination to link the subterm to. Any occurrence of ~ in DEST is replaced with SUBTERM.
Alternatively, a single modifier spec can be of the form BEGIN[FROM:TO], which is equivalent to writing
BEGINFROM:BEGINTO (see example below).

For example, given the source phrase [[il bue che dice cornuto all'asino]] "the pot calling the kettle black"
(literally "the ox that calls the donkey horned/cuckolded"), the result of calling add_links_to_multiword_term()
is [[il]] [[bue]] [[che]] [[dice]] [[cornuto]] [[all']][[asino]]. With a modifier_spec of 'dice:dire', the result
is [[il]] [[bue]] [[che]] [[dire|dice]] [[cornuto]] [[all']][[asino]]. Here, based on the modifier spec, the
non-lemma form [[dice]] is replaced with the two-part link [[dire|dice]].

Another example: given the source phrase [[chi semina vento raccoglie tempesta]] "sow the wind, reap the whirlwind"
(literally (he) who sows wind gathers [the] tempest"). The result of calling add_links_to_multiword_term() is
[[chi]] [[semina]] [[vento]] [[raccoglie]] [[tempesta]], and with a modifier_spec of 'semina:~re; raccoglie:~re',
the result is [[chi]] [[seminare|semina]] [[vento]] [[raccogliere|raccoglie]] [[tempesta]]. Here we use the ~
notation to stand for the non-lemma form in the destination link.

A more complex example is [[se non hai altri moccoli puoi andare a letto al buio]], which becomes
[[se]] [[non]] [[hai]] [[altri]] [[moccoli]] [[puoi]] [[andare]] [[a]] [[letto]] [[al]] [[buio]] after calling
add_links_to_multiword_term(). With the following modifier_spec:
'hai:avere; altr[i:o]; moccol[i:o]; puoi: potere; andare a letto:~; al buio:~', the result of applying the spec is
[[se]] [[non]] [[avere|hai]] [[altro|altri]] [[moccolo|moccoli]] [[potere|puoi]] [[andare a letto]] [[al buio]].
Here, we rely on the alternative notation mentioned above for e.g. 'altr[i:o]', which is equivalent to 'altri:altro',
and link multiword subterms using e.g. 'andare a letto:~'. (The code knows how to handle multiword subexpressions
properly, and if the link text and destination are the same, only a single-part link is formed.)
]==]
function export.apply_link_modifiers(linked_term, modifier_spec, lang)
	local split_modspecs = split(modifier_spec, "%s*;%s*")
	for j, modspec in ipairs(split_modspecs) do
		local id
		if modspec:find("<") then
			local rest
			rest, id = modspec:match("^(.*)<id:(.-)>$")
			if rest then
				modspec = rest
			end
		end
		local subterm, dest, otherlang
		local begin_spec, rest, end_spec = modspec:match("^%[(.-)%]([^:]*)%[(.-)%]$")
		if begin_spec then
			local begin_from, begin_to = canonicalize_begin_end_spec(begin_spec)
			local end_from, end_to = canonicalize_begin_end_spec(end_spec)
			subterm = begin_from .. rest .. end_from
			dest = begin_to .. rest .. end_to
		end
		if not subterm then
			rest, end_spec = modspec:match("^([^:]*)%[(.-)%]$")
			if rest then
				local end_from, end_to = canonicalize_begin_end_spec(end_spec)
				subterm = rest .. end_from
				dest = rest .. end_to
			end
		end
		if not subterm then
			begin_spec, rest = modspec:match("^%[(.-)%]([^:]*)$")
			if begin_spec then
				local begin_from, begin_to = canonicalize_begin_end_spec(begin_spec)
				subterm = begin_from .. rest
				dest = begin_to .. rest
			end
		end
		if not subterm then
			subterm, dest = modspec:match("^(.-)%s*:%s*(.*)$")
			if subterm and subterm ~= "^" and subterm ~= "$" then
				local langdest
				-- Parse off an initial language code (e.g. 'en:Higgs', 'la:minūtia' or 'grc:σκατός'). Also handle
				-- Wikipedia prefixes ('w:Abatemarco' or 'w:it:Colle Val d'Elsa').
				otherlang, langdest = dest:match("^([A-Za-z0-9._-]+):([^ ].*)$")
				if otherlang == "w" then
					local foreign_wikipedia, foreign_term = langdest:match("^([A-Za-z0-9._-]+):([^ ].*)$")
					if foreign_wikipedia then
						otherlang = otherlang .. ":" .. foreign_wikipedia
						langdest = foreign_term
					end
					dest = ("%s:%s"):format(otherlang, langdest)
					otherlang = nil
				elseif otherlang then
					otherlang = get_lang_by_code(otherlang, true, "allow etym")
					dest = langdest
				end
			end
		end
		if not subterm then
			if modspec == "?" or modspec == "!" then
				subterm = "$"
				dest = modspec
			elseif modspec == "..." or modspec == "...?" then
				subterm = "$"
				dest = " " .. modspec
			elseif modspec:find("^[A-Z]$") then
				-- X, Y, etc. by themselves are unlinked, to help with snowclones
				subterm = modspec
				dest = "_"
			else
				subterm = modspec
				dest = "~"
			end
		end
		if subterm == "^" then
			linked_term = dest:gsub("_", " ") .. linked_term
		elseif subterm == "$" then
			linked_term = linked_term .. dest:gsub("_", " ")
		else
			if subterm:find("[", nil, true) then
				error(("Subterm '%s' in modifier spec '%s' cannot have brackets in it"):format(
					escape_wikicode(subterm), escape_wikicode(modspec)))
			end
			local escaped_subterm = pattern_escape(subterm)
			local subterm_re = "%[%[" .. escaped_subterm:gsub("(%%?[ ',%-])", "%%]*%1%%[*") .. "%]%]"
			local expanded_dest
			if dest:find("~", nil, true) then
				expanded_dest = dest:gsub("~", replacement_escape(subterm))
			else
				expanded_dest = dest
			end
			if otherlang then
				expanded_dest = expanded_dest .. "#" .. otherlang:getCanonicalName()
			end

			local subterm_replacement
			if expanded_dest == "_" then
				subterm_replacement = subterm
				if id then
					error("Can't supply <id:...> with an unlinked subterm")
				end
				if otherlang then
					error("Can't supply prefixed language with an unlinked subterm")
				end
			elseif id or otherlang then
				if id and expanded_dest:find("[", nil, true) then
					error("Can't supply <id:...> with destination with embedded brackets")
				end
				subterm_replacement = require(links_module).language_link {
					lang = otherlang or lang,
					term = expanded_dest,
					alt = subterm,
					id = id,
				}
			elseif expanded_dest:find("[", nil, true) then
				-- Use the destination directly if it has brackets in it (e.g. to put brackets around parts of a word).
				subterm_replacement = expanded_dest
			elseif expanded_dest == subterm then
				subterm_replacement = "[[" .. subterm .. "]]"
			else
				subterm_replacement = "[[" .. expanded_dest .. "|" .. subterm .. "]]"
			end

			local escaped_subterm_replacement = replacement_escape(subterm_replacement)
			local replaced_linked_term = ugsub(linked_term, subterm_re, escaped_subterm_replacement)
			if replaced_linked_term == linked_term then
				mw.log(("Attempted to replace %s with %s in %s"):format(subterm_re, escaped_subterm_replacement, linked_term))
				error(("Subterm '%s' could not be located in %slinked expression %s, or replacement same as subterm"):format(
					subterm, j > 1 and "intermediate " or "", escape_wikicode(linked_term)))
			else
				linked_term = replaced_linked_term
			end
		end
	end

	return linked_term
end


local inflection_to_cats_and_label = {
	plural = {
		filter_pos = function(posvars)
			-- plurals also occur with determiners, adjectives etc. and we don't want to generate categories like
			-- 'countable determiners', 'countable adjectives', etc. Note that the passed-in `simp_plpos` has
			-- `proper nouns` converted to `nouns`.
			return posvars.simp_plpos == "nouns"
		end,
		cats = {"countable nouns"},
		no_cats = {"uncountable nouns"},
		fixed_adj_label = "<<countable>>",
		fixed_adj_no_label = "<<uncountable>>",
		sometimes_label = "<<countable>> and <<uncountable>>",
		unattested_cats = "nouns with unattested plurals",
		unknown_cats = "nouns with unknown or uncertain plurals",
	},
	comparative = {
		cats = {"comparable {simp_plpos}"},
		no_cats = {"uncomparable {simp_plpos}"},
		fixed_adj_label = "<<comparable>>",
	},
	["female equivalent"] = {
		cats = {"{simplified_plpos} with other-gender equivalents"},
	},
	["male equivalent"] = {
		cats = {"{simplified_plpos} with other-gender equivalents"},
	},
}

--[=[
Validate the items in `items` against the list or set of valid items in `valid_items`. If `field` is given, fetch the
item to check from that-named field of each object in `items`; otherwise use the items in `items` directly. If an error
occurs, `item_type` specifies the type of item to mention in the error message, which will also list the allowed items
(either taken directly from `valid_items` if a list, or from the sorted keys if a set).
]=]
local function validate_items(data)
	local items, field, valid_items, item_type =
		data.items, data.field, data.valid_items, data.item_type
	local valid_set
	if valid_items[1] then
		valid_set = list_to_set(valid_items)
	else
		valid_set = valid_items
	end

	for _, item in ipairs(items) do
		if field then
			item = item[field]
		end
		if not valid_set[item] then
			local valid_list
			if valid_items[1] then
				valid_list = valid_items
			else
				valid_list = {}
				for valid_item, _ in pairs(valid_items) do
					insert(valid_list, valid_item)
				end
				table.sort(valid_list)
			end
			error(("Invalid %s: %s; expected one of %s"):format(item_type, item, mw.text.listToText(valid_list)))
		end
	end
end

function export.validate_genders(data)
	local genders, valid_genders, gender_type, no_augment = data.genders, data.valid_genders, data.gender_type,
		data.no_augment
	if not genders then
		return
	end
	gender_type = gender_type or "headword"
	local valid_gender_set = list_to_set(valid_genders)
	local augmented_gender_set
	if no_augment then
		augmented_gender_set = valid_gender_set
	else
		augmented_gender_set = {}
		for g, _ in pairs(valid_gender_set) do
			augmented_gender_set[g] = true
			if g:find("^m") and not g:find("^mf") and valid_gender_set[g:gsub("^m", "f")] then
				augmented_gender_set[g:gsub("^m", "mf")] = true
				augmented_gender_set[g:gsub("^m", "mfbysense")] = true
				augmented_gender_set[g:gsub("^m", "mfequiv")] = true
			end
		end
	end

	validate_items {
		items = genders,
		field = "spec",
		valid_items = augmented_gender_set,
		item_type = ("%s gender"):format(gender_type),
	}
end

function export.has_plural_gender(genders)
	local saw_p, saw_non_p
	for _, val in ipairs(genders) do
		local g = val.spec
		if g:find("p$") then
			saw_p = true
		elseif g ~= "?" then
			saw_non_p = true
		end
	end
	return saw_p, saw_non_p
end

function export.is_plurale_tantum(genders)
	local saw_p, saw_non_p = export.has_plural_gender(genders)
	return saw_p and not saw_non_p
end

local Headdata = {}

function Headdata:resolve_prop(prop, ...)
	if type(prop) == "function" then
		prop = prop(self, ...)
	end
	return prop
end

function Headdata:get_pos_variants()
	if self.process_props.pos_variants == nil then
		self.process_props.pos_variants = export.get_pos_variants(self.pos_category)
	end
	return self.process_props.pos_variants
end

--[==[
Canonicalize a category. The category string will have the full language name (i.e. the name of the L2 language under
which an entry is inserted, which may a parent language if the language in question is an etymology-only language)
prepended to it, and any occurrences of `{plpos}` in the string replaced with the actual plural part of speech (with
some canonicalization; specifically, `proper nouns` is converted to `nouns` when replacing `{plpos}`). To specify a
full category and not have the language name prepended to it, precede it with {"Category:"}, which will be removed.
]==]
function Headdata:canonicalize_category(category)
	if category:find("{") then
		category = require(string_utilities_module).format(category, self:get_pos_variants())
	end
	if category:find("^Category:") then
		return (category:gsub("^Category:", ""))
	else
		return self.langfullname .. " " .. category
	end
end

--[==[
Canonicalize a list of categories according to the process described in `Headdata:canonicalize_category`. This simply
loops over each category in `categories` and calls `Headdata:canonicalize_category` on each one.
]==]
function Headdata:canonicalize_categories(categories)
	if not categories then
		return categories
	end
	categories = export.canonicalize_category_list(categories)
	local canon_cats = {}
	for _, cat in ipairs(categories) do
		insert(canon_cats, self:canonicalize_category(cat))
	end
	return canon_cats
end

--[==[
Insert a category into the `categories` list in the headword `data` structure. `category` is normally a string naming
the category, which will have the full language name prepended to it and any occurrences of `{plpos}` in the string
replaced with the actual plural part of speech (with some canonicalization; specifically, `proper nouns` is converted to
`nouns` when replacing `{plpos}`). To specify a full category and not have the language name prepended to it, precede it
with {"Category:"}.
]==]
function Headdata:insert_category(category)
	insert(self.categories, self:canonicalize_category(category))
end

--[==[
Validate the genders in `genders` (a list of gender spec objects, as produced by {type = "genders"} in
[[Module:parameters]] and accepted by [[Module:gender and number]]), checking that all specified genders are in the list
given in `valid_genders`. Optional `props` controls how the validation happens. In particular, unless `props.no_augment`
is given, then for any gender beginning with `m`, if a corresponding gender beginning with `f` occurs, analogous genders
beginning with `mf`, `mfbysense` and `mfequiv` are also allowed. For example, if `m-d` (masculine dual) and `f-d`
(feminine dual) both occur, genders `mf-d`, `mfbysense-d` and `mfequiv-d` are also allowed. If a disallowed gender is
given, an error occurs, giving the disallowed gender along with the list of all allowed genders.
]==]
function Headdata:validate_genders(genders, valid_genders, props)
	-- FIXME: This has no dependency on self. Uses should be converted to call export.validate_genders() directly.
	if not genders then
		return
	end
	props = props or {}
	local gender_type, no_augment = props.gender_type, props.no_augment
	export.validate_genders {
		genders = genders,
		valid_genders = valid_genders,
		gender_type = gender_type,
		no_augment = no_augment,
	}
end

--[==[
Parse an inflection specified in `field`, the name of a parameter holding an inflection. If the parameter is numeric,
the field should be given as a number (as with the `params` structure passed to [[Module:parameters]]), not a string
containing the representation of a number. The field can specify multiple comma-separated terms, and each term can have
associated inline modifiers that will be parsed (unless there is top-level HTML in the parameter, i.e. HTML not
contained inside an inline modifier, e.g. as may be generated by using {{tl|l}} or similar template inside a parameter).
This is a wrapper around the top-level `parse_term_with_modifiers()` function. `props` is an optional structure
containing additional properties, including all additional properties documented for the top-level
`parse_term_with_modifiers()` function.

If the parameter in `field` is unspecified, the return value of this function will be an empty list, not {nil}, so it
is always safe to iterate over the return value.

By default, the allowed modifiers are the same as for `parse_term_with_modifiers()`, except that (normally) the
`<tr:...>` modifier will be allowed if `include_tr` was specified in the original call to `process_headword()`; likewise
for the `<ts:...>` modifier if `include_ts` was specified and the `<sc:...>` modifier if `include_sc` was specified. If
If you pass in your own `include_mods` list of additional allowed modifiers, it will (normally) automatically be
augmented with {"tr"}, {"ts"} and/or {"sc"} if `include_tr`, `include_ts` and/or `include_sc` was specified when calling
`process_headword()`. To disable automatic augmentation of these modifiers (whether or not you specify an `include_mods`
property), specify {no_augment_include_mods = true} in `props`.
]==]
function Headdata:parse_inflection(field, props)
	local val = self.process_props.args[field]
	if not val then
		return {}
	end
	props = props and shallow_copy(props) or {}
	local include_mods = props.include_mods
	local calldata = self.process_props.calldata
	if not props.no_augment_include_mods and (calldata.include_tr or calldata.include_ts or calldata.include_sc) then
		include_mods = include_mods and shallow_copy(include_mods) or {}
		if calldata.include_tr then
			insert_if_not(include_mods, "tr")
		end
		if calldata.include_ts then
			insert_if_not(include_mods, "ts")
		end
		if calldata.include_sc then
			insert_if_not(include_mods, "sc")
		end
	end
	props.val = val
	props.paramname = field
	props.splitchar = props.splitchar or ","
	props.include_mods = include_mods
	local orig_frob = props.frob
	local function convert_tilde_to_pagename(term)
		if orig_frob then
			term = orig_frob(term)
		end
		if not term:find("~", nil, true) then
			return term
		end
		term = term:gsub("\\~", "\1"):gsub("~", replacement_escape(self.pagename)):gsub("\1", "~")
		return term
	end
	props.frob = convert_tilde_to_pagename
	return export.parse_term_with_modifiers(props) or {}
end

function Headdata:process_for_insertion(terms, props)
	props = props and shallow_copy(props) or {}
	props.headdata = self
	props.terms = terms
	return export.process_for_insertion(props)
end

--[==[
Insert previously-parsed terms into the `inflections` of the headword `data` structure. This is a wrapper around
the top-level `insert_inflection()` function. `terms` is the list of parsed terms. (If {nil}, nothing happens unless
`request` is set in `props`.) `label` is the the label that the inflections are given; any parts of the label surrounded
in `<<...>>` are linked to the glossary. (If the contents of `<<...>>` contain a `|` in them, they are a two-part link.)
`props` is an optional structure containing additional properties, including all additional properties documented for
the top-level `insert_inflection()` function.

Unless `no_auto_cats` is given in `props`, certain labels automatically trigger the insertion of additional
categories in specific circumstances. This is controlled by the `inflection_to_cats_and_label` structure in
[[Module:headword utilities]]. For example, if the part of speech is {"nouns"} or {"proper nouns"} and the label (after
removing any links and `<<...>>` glossary specs) is {"plural"}, an additional category
<code><var>lang</var> countable nouns</code> will be added if a plural value is given (i.e. the value is not {"-"}). If
the value is {"-"} (which indicates that there is no plural and triggers the insertion of the fixed inflection label
{"no plural"}), <code><var>lang</var> uncountable nouns</code> will be inserted instead, and if both {"-"} and a value
are given (which triggers the insertion of the {"usually no plural"} fixed inflection label), both categories are added.
Similar categories are inserted when a comparative is given (with a label {"comparative"}), and if the label is
{"female equivalent"} or {"male equivalent"} and the value is not {"-"}, a category such as
<code><var>lang</var> nouns with other-gender equivalents</code> is inserted.
]==]
function Headdata:insert_processed_inflection(processed, label, props)
	props = props and shallow_copy(props) or {}
	if not props.no_auto_cats then
		local bare_label = props.label_for_cats_and_modes or label
		if bare_label:find("[[", nil, true) then
			bare_label = require(links_module).remove_links(bare_label)
		end
		if bare_label:find("<<", nil, true) then
			bare_label = bare_label:gsub("<<.-|(.-)>>", "%1"):gsub("<<(.-)>>", "%1")
		end
		local spec = inflection_to_cats_and_label[bare_label]
		if spec and (not spec.filter_pos or spec.filter_pos(self:get_pos_variants())) then
			-- Copy the propererties other than filter_pos into `props`, but don't overwrite any existing values.
			for specprop, specval in pairs(spec) do
				if specprop ~= "filter_pos" and props[specprop] == nil then
					props[specprop] = specval
				end
			end
		end
	end
	-- Now resolve and canonicalize the properties.
	local canon_props = {}
	for prop, val in pairs(props) do
		if prop ~= "no_auto_cats" and (prop == "cats" or prop:find("_cats$")) then
			val = self:canonicalize_categories(self:resolve_prop(val))
		elseif prop:find("_label$") then
			val = self:resolve_prop(val)
		end
		canon_props[prop] = val
	end
	canon_props.headdata = self
	canon_props.processed = processed
	canon_props.label = label
	return export.insert_processed_inflection(canon_props)
end

--[==[
Insert previously-parsed terms into the `inflections` of the headword `data` structure. This is a wrapper around
the top-level `insert_inflection()` function. `terms` is the list of parsed terms. (If {nil}, nothing happens unless
`request` is set in `props`.) `label` is the the label that the inflections are given; any parts of the label surrounded
in `<<...>>` are linked to the glossary. (If the contents of `<<...>>` contain a `|` in them, they are a two-part link.)
`props` is an optional structure containing additional properties, including all additional properties documented for
the top-level `insert_inflection()` function.

Unless `no_auto_cats` is given in `props`, certain labels automatically trigger the insertion of additional
categories in specific circumstances. This is controlled by the `inflection_to_cats_and_label` structure in
[[Module:headword utilities]]. For example, if the part of speech is {"nouns"} or {"proper nouns"} and the label (after
removing any links and `<<...>>` glossary specs) is {"plural"}, an additional category
<code><var>lang</var> countable nouns</code> will be added if a plural value is given (i.e. the value is not {"-"}). If
the value is {"-"} (which indicates that there is no plural and triggers the insertion of the fixed inflection label
{"no plural"}), <code><var>lang</var> uncountable nouns</code> will be inserted instead, and if both {"-"} and a value
are given (which triggers the insertion of the {"usually no plural"} fixed inflection label), both categories are added.
Similar categories are inserted when a comparative is given (with a label {"comparative"}), and if the label is
{"female equivalent"} or {"male equivalent"} and the value is not {"-"}, a category such as
<code><var>lang</var> nouns with other-gender equivalents</code> is inserted.
]==]
function Headdata:insert_inflection(terms, label, props)
	local processed = self:process_for_insertion(terms, props)
	self:insert_processed_inflection(processed, label, props)
	return processed
end

--[==[
Insert a "fixed" inflection (a label without associated values) into the `inflections` table of the headword `data`
structure, labeled according to `label` (which can have glossary links in it specified using `<<...>>`, exactly as for
`:insert_inflection()`). An example label (from {{tl|mn-noun}} in [[Module:mn-headword]]) is {"hidden-g declension"},
specifying that the noun belongs to the hidden-''g'' declension. This is a direct wrapper around the top-level function
`insert_fixed_inflection()`; see that function for more details on optional `props`.
]==]
function Headdata:insert_fixed_inflection(label, props)
	props = props and shallow_copy(props) or {}
	props.headdata = self
	props.label = label
	export.insert_fixed_inflection(props)
end

--[==[
Parse the inflection(s) specified in `field` and insert them into the `inflections` table of the headword `data`
structure, labeled according to `label`. This is equivalent to calling {terms = data:parse_inflection(field, props)}
followed by {return data:insert_inflection(terms, label, props)} and behaves the same as the combination of those two
functions. See their documentation for more details.
]==]
function Headdata:parse_and_insert_inflection(field, label, props)
	local terms = self:parse_inflection(field, props)
	return self:insert_inflection(terms, label, props)
end

--[==[
Generate an inflection that may be specified explicitly or defaulted (which involves looping over the specified or
defaulted heads and determining the script of each one, since the formation of the default depends on the script).
`data` is the data object passed into the POS handler. `terms` is the list of terms to process. Those where the term
itself is not `+` will be returned unchanged, while those where the term is `+` will be handled by generating the
appropriate inflections from the headwords using `make_inflection` (which is passed three arguments, `head`, `tr` and
`sccode`, i.e. the script code of `head`) and should return two values, term and translit, either of which can be
nil. A nil head will be ignored, and otherwise the decorations specified on the `+` term will be combined with the
decorations specified on the head. The return value is a list of inflections where no requests for the default
inflection remain.
]==]
function Headdata:resolve_special(terms, handle_special, props)
	props = props or {}
	local infls = {}
	local is_special = props.is_special or function(_data, infl) return infl.term == "+" end
	for _, termobj in ipairs(terms) do
		if not is_special(self, termobj) then
			insert(infls, termobj)
		else
			for _, headobj in ipairs(self.heads) do
				local head = headobj.term or self.pagename
				local head_no_links
				if props.with_links then
					head = head:find("%[") and head or require(headword_module).add_multiword_links(head, not headobj.term)
					head_no_links = require(links_module).remove_links(head)
				else
					head = require(links_module).remove_links(head)
					head_no_links = head
				end
				local newterms = handle_special {
					headdata = self,
					head = head,
					head_no_links = head_no_links,
					tr = headobj.tr,
					infl = termobj,
					sc = self.lang:findBestScript(head_no_links),
				}
				if newterms then
					newterms = export.canonicalize_termobj_list(newterms, "term", "resolve_special", termobj)
					for _, newterm in ipairs(newterms) do
						if not props.no_combine_handle_special_retval_with_origin then
							export.combine_termobj_decorations(newterm, termobj)
						end
						if not props.no_combine_handle_special_retval_with_head then
							export.combine_termobj_decorations(newterm, headobj)
						end
						insert(infls, newterm)
					end
				end
			end
		end
	end
	return infls
end

--[==[
Add the current page to a tracking page named `Wiktionary:Tracking/``lang``-headword/``page```, where ``lang`` is the
language code of the current language. For example, if the current language is `mak` and `page` is {"redundant-lon"},
the current page will get added to the tracking page `Wiktionary:Tracking/mak-headword/redundant-lon`. All pages added
to that tracking page can be seen by going to [[Special:WhatLinksHere/Wiktionary:Tracking/mak-headword/redundant-lon]].
This is typically used to track issues occurring in user-specified parameters that do not rise to the level of errors
(e.g. redundant parameters, deprecated usages or other dispreferred values).
]==]
function Headdata:track(page)
	return require(debug_track_module)(self.langcode .. "-headword/" .. page)
end

local boolean_param = {type = "boolean"}

--[==[
Process an arbitrary headword in an arbitrary language, handling generic and language-specific arguments and calling
`full_headword()` in [[Module:headword]]. This is intended for use in implementing headword modules (e.g.
[[Module:uz-headword]] for Uzbek, [[Module:mn-headword]] for Uzbek, [[Module:gsw-headword]] for Alemannic German, etc.)
and provides a general implementation of such modules. On input, `data` is an object with the following fields:
* `lang`: The language object of the language being handled. '''Required.''' Use the special value {false} to indicate
  that the language is specified by the user in {{para|1}}.
* `frame`: The frame object passed into the `show()` function of your module, which implements headword-handling for
  all parts of speech in the module, including a generic POS-handling template (e.g. {{tl|uz-head}} or {{tl|mn-head}}),
  which allows arbitrary parts of speech to be handled. '''Required.'''
* `pos_functions`: A table listing, for each part of speech requiring special handling, the extra parameters (if any)
  that the part of speech accepts, along with how to handle them. See the examples below. '''Required.'''
* `validate_lang`: If {lang = true} is specified, this is a function of one argument (a language object, based on the
  language specified in {{para|1}}) that should throw an error if the language object is disallowed. If omitted, all
  languages are allowed.
* `numbered_head`: If true, explicit headwords are specified in a numbered param instead of in {{para|head}}. The param
  used is usually {{para|1}}, but is {{para|2}} for generic POS templates such as {{tl|mn-head}} or for POS-specific
  templates when {lang = true} is specified (e.g. {{tl|arb-noun}}), and is {{para|3}} for generic POS templates when
  {lang = true} is spcified (e.g. {{tl|arb-head}}).
* `include_tr`: If true, allow explicit transliterations to be specified. The transliteration(s) for the headword(s)
  themselves is/are specified in {{para|tr}} or through the {{cd|<tr:...>}} inline modifier on headwords, and
  transliterations of inflections are specified through the {{cd|<tr:...>}} inline modifier. This should generally be
  given when a headword for the language may be in a script other than Latin.
* `include_ts`: If true, allow explicit transcriptions to be specified. The transcription(s) for the headword(s)
  themselves is/are specified in {{para|ts}} or through the {{cd|<ts:...>}} inline modifier on headwords, and
  transcriptions of inflections are specified through the {{cd|<ts:...>}} inline modifier. This should generally only
  be given for certain languages where the spelling is radically different from the pronunciation (e.g. in cuneiform
  languages such as Hittite and Akkadian, and potentially in Tibetan), and represents a pronunciation-based rendering
  (usually not direct IPA).
* `include_sc`: If true, allow an explicit script code to be specified. The overall script code for the headword(s)
  themselves can be specified using {{para|sc}}, and per-headword or per-inflection script codes are specified using the
  {{cd|<sc:...>}} inline modifier. This should generally be given when a language supports multiple scripts.
* `infls`: An inflections structure specifying extra generic parameters that apply to all parts of speech and how to
  handle them. The format is the same as for the `infls` structure in `pos_functions`.
* `augment_params`: A callback function to add extra generic parameters, or modify existing generic parameters in the
  `params` structure; but in general, extra generic parameters should be added through the `infls` structure instead.
  This callback should not be used to add part-of-speech-specific parameters; those are handled through the appropriate
  setting in `pos_functions`. It is passed two single arguments, the `headdata` object and the `params` table to be
  augmented. See below for extra fields stored in the `process_props` structure of the `headdata` object. This function
  is called after initializing the `params` table and processing the overall `infls` structure, but just before adding
  part-of-speech-specific parameters (from `pos_functions`) to `params`. Thus, it can override any generic parameters
  but may itself be overridden by a part-of-speech-specific parameter.
* `augment_headdata`: A callback function to modify the `headdata` object passed to `full_headword()` in
  [[Module:headword]]. This should not be used to for part-of-speech-specific parameter handling; this is handled
  through the appropriate setting in `pos_functions`. It is passed a single argument, the `headdata` object, as for
  `augment_params`; but the `process_props` structure and other fields will be more filled out, as this callback is
  called later. This can be used, for example, to override the value of a generic setting in `headdata` (e.g.
  [[Module:uz-headword]] uses this to mark non-Latin terms as variant forms by setting `headdata.var`, being careful not
  to override a value already set by the user). This function is called after initializing the `headdata` table with all
  information taken from generic parameters and processing generic parameters specified in the overall `infls`
  structure, and just before processing the appropriate part-of-speech-specific `infls` structure in `pos_functions`
  (which in turn is followed by any handler function in `pos_functions`). Thus, it can override any value set during
  generic parameter processing but may itself be overridden by a part-of-speech-specific parameter or handler.
* `force_cat`: If true, add the headword to the appropriate categories even on non-mainspace pages. This can be used for
  testing category handling in sample template calls on userspace test pages or template documentation pages. It should
  not be set in production code.
* `enable_auto_translit`: If true, turn on automatic transliteration of inflections at a global level (i.e. applying to
  all inflections). This has no effect on headwords, which are automatically transliterated by default if in a non-Latin
  script and automatic transliteration is available for the language. You can also set this value for particular
  inflections in the `insert_inflection()` function.

The `headdata` headword data structure has an extra field in it called `process_props` that is specific to the
`process_headword()` function, containing various extra properies. As the operation of `process_headword()` proceeds,
this object gets filled out with more fields. For example, once parameter parsing happens, the resulting values are
available in the `args` field of `process_props`. The following fields are found in `process_props` (note that
`pos_category`, the canonicalized plural part of speech of the headword being processed, is *not* present here; it's
directly on `headdata`):
* `namespace`: The name of the current namespace; an empty string for the mainspace. This references the namespace of
  the actual page and isn't affected by the {{para|pagename}} parameter.
* `indexing_pos`: The canonicalized part of speech of the headword used to index into `pos_functions`. This is the
  same as `poscat` for specific part-of-speech templates such as {{tl|uz-noun}}, but has the value {"head"} for generic
  part-of-speech templates such as {{tl|uz-head}}. (Note that `poscat` is directly available on `headdata`.)
* `generic_pos_template`: True if a generic POS templates like {{tl|uz-head}} or {{tl|mn-head}} was used. (This is
  signaled by omitting the invocation parameter {{para|1}} to `process_headword`.)
* `lang_in_1`: True if the language code is to be fetched from {{para|1}}.
* `pos_param`: The parameter holding the part of speech, if a generic POS tempalte like {{tl|mn-head}} is being
  processed (i.e. `generic_pos_template` is set). In such a case, it will have the value of {1} or {2}, depending on
  whether the language code is being fetched from {{para|1}} (see `lang_in_1`). Otherwise it will be {nil}.
* `head_param`: The parameter holding the explicit headword. If `numbered_head` was specified (as for Mongolian headword
  templates), this has the value {1}, {2} or {3} depending on whether the language code is being fetched from {{para|1}}
  (see `lang_in_1`) and whether a generic POS template like {{tl|mn-head}} is being processed (see
  `generic_pos_template`). Otherwise, it has the value {"head"}. Also see the `lang` and `numbered_head` properties in
  the `data` structure sent to `process_headword()`.
* `is_suffix`: True if the current term is a suffix. This is set when processing the `suffix`, `nosuffix` and `clitic`
  parameters; it is always {false} beforehand (i.e. during `augment_params` and processing of the general `infls`
  structure).
* `insert_specs`: This is a table mapping parameter names to the return value of `Headdata:insert_inflection()`, filled
  out as parameter values are processed. This lets a given parameter processing function in `infls` gain access to the
  result of calling `insert_inflection()` on previous parameters (which indicates the number of items inserted as well
  as whether `-` was specified).

The `pos_functions` table contains an entry for each part of speech needing special handling, where the key is the
canonical plural part of speech (e.g. {"adverbs"} or {"proper nouns"}). The value associated with each key is a table
normally containing a field `infls`, listing the extra part-of-speech-specific inflection and other parameters along
with how to handle them. The specs in `infls` are used in three ways:
# to augment the `params` object passed to the `process()` function in [[Module:parameters]], specifying how to parse
  the appropriate inflectional parameters;
# to specify how to process any inflectional parameters given and insert them into the `headdata` object passed to
  `full_headword()` in [[Module:headword]];
# to generate appropriate documentation for the parameters and other changes made by the headword template (e.g.
  inserting categories).
Alternatively, you can separately control the augmentation of the `params` object and the procesing of the resulting
arguments. This is done by specifying two fields in place of `infls`, named `params` and `func`. `params` is a table
containing extra parameters to add to the overall `params` object passed to the `process()` function in
[[Module:parameters]]. `func` is a function of two arguments, normally called `data` (the headword data structure
`headdata`) and `args` (the processed arguments table). However, this alternative method is not normally recommended
because it leads to duplication between the `params and `func` fields and the documentation, which must be manually
specified.

A simple example, as used to handle pronouns for Turoyo, is

{
local valid_genders = {"m", "f", "m-p", "f-p", "p", "?"}

pos_functions["pronouns"] = {
	infls = {
		{2, type = "genders", validate = valid_genders},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	},
}
}

The equivalent using `params` and `func` is

{
local valid_genders = {"m", "f", "m-p", "f-p", "p", "?"}

pos_functions["pronouns"] = {
	params = {
		[2] = {type = "genders"},
		f = true,
		pl = true,
	},
	func = function(data, args)
		data:validate_genders(args[2], valid_genders)
		data.genders = args[2]
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
	end
}
}

Note how the version with separate `params and `func` is longer and splits information on the parameters between the
two fields. The `params` structure sets extra user-specifiable parameters {{para|2}} for genders (since the headword is
in {{para|1}}) as well a {{para|f}} and {{para|pl}}, and the `func` handler processes those parameters. Note how this is
done by calling methods on the headword `data` structure. Each such parameter can have multiple comma-separated values,
and each value can have inline modifiers attached to it to specify further properties of the value. The `infls` version
ends up making the same method calls, but does it for you instead of you having to do it yourself.

These methods are implemented through a metatable set on the headword `data` structure, which is removed before calling
`full_headword()` in [[Module:headword]]. The methods access extra information related to headword processing (such as
the `args` table) that is stored in the `process_props` field of the headword `data` strucuture. This field is also
removed prior to calling `full_headword()`.

The methods available on the headword `data` structure are as follows. Each one also has its own documentation.
* {parse_inflection(field, props)}: Parse value(s) specified in `field` (a user-specified parameter in the `args` table)
  and return a list of term objects. Optional `props` specifies additional properties controlling the parsing.
* {insert_inflection(terms, label, props)}: Insert the terms in `terms` (a list of term objects as returned by
  `parse_inflection()`) into the `inflections` list in the headword `data` structure, giving the inflection the label as
  specified in `label`. Optional `props` specifies additional properties controlling the parsing.
* {parse_and_insert_inflection(field, label, props)}: A combination of `parse_inflection()` and `insert_inflection()`,
  if no further processing of the parsed values needs to be done before insertion.
* {insert_fixed_inflection(label, props)}: Insert a "fixed" inflection (a label without associated values) into the
  `inflections` table. An example (from {{tl|mn-noun}} in [[Module:mn-headword]]) is {"hidden-g declension"}, specifying
  that the noun belongs to the hidden-''g'' declension.
* {resolve_special(terms, handle_special, props)}: Resolve "special" indicators as specified by the user in an inflection
  parameter. A typical example is {"+"}, requesting a default value. `terms` is the list of parsed term objects and
  `handle_special` is a handler function to process special indicators and convert them to their actual values.
* {validate_genders(genders, valid_genders, props)}: Validate that the user-specified genders in `genders` all belong to
  the list given in `valid_genders`, throwing an error if not.
* {insert_category(category)}: Insert a category into the `categories` list in the headword `data` structure. `category`
  is normally a string naming the category, which will have the language prepended to it and any occurrences of
  `{plpos}` in the string replaced with the actual plural part of speech.
]==]
function export.process_headword(data)
	local data_lang, frame, pos_functions, validate_lang, numbered_head, include_tr, include_ts, include_sc, force_cat,
		enable_auto_translit, checkredlinks, infls, augment_params, augment_headdata =
		data.lang, data.frame, data.pos_functions, data.validate_lang, data.numbered_head, data.include_tr,
		data.include_ts, data.include_sc, data.force_cat, data.enable_auto_translit, data.checkredlinks, data.infls,
		data.augment_params, data.augment_headdata
	local iparams = {
		[1] = true,
		def = true,
	}
	if data_lang == "invocation" or data_lang == "invocation-or-user" then
		iparams.lang = true
	end

	local iargs = require(parameters_module).process(frame.args, iparams)
	local parargs = frame:getParent().args

	local lang
	local function generate_data_lang_error()
		error("Internal error: `data.lang` must be either a language object, \"invocation\" for a " ..
			"language specified in lang= in the invocation arguments, \"user\" for a language specified in 1= in " ..
			"the user template call, or \"invocation-or-user\" for either; saw " .. dump(data.lang))
	end
	if not data_lang then
		generate_data_lang_error()
	end
	local lang_in_1
	if type(data_lang) == "string" then
		if data_lang == "invocation" then
			lang = iargs.lang
			if not lang then
				error("Internal error: lang= must be specified in the invocation arguments")
			end
		elseif data_lang == "invocation-or-user" or data_lang == "user" then
			if data_lang == "invocation-or-user" then
				lang = iargs.lang
			end
			if not lang then
				lang = ine(parargs[1])
				if not lang then
					error("Language code (see [[WT:Language codes]]) must be specified in 1=")
				end
				lang_in_1 = true
			end
		else
			generate_data_lang_error()
		end
		lang = require(languages_module).getByCode(lang, lang_in_1 and 1 or "lang", true)
	elseif type(data_lang) ~= "table" or not data_lang.hasType or not data_lang:hasType("language") then
		generate_data_lang_error()
	else
		lang = data_lang
	end

	local langcode = lang:getCode()
	if validate_lang then
		if type(validate_lang) == "function" then
			validate_lang(langcode)
		else
			validate_items {
				items = {langcode},
				valid_items = validate_lang,
				item_type = "language code"
			}
		end
	end

	local template_indicated_pos = iargs[1]
	local generic_pos_template = not template_indicated_pos
	local pos_param
	if generic_pos_template then
		pos_param = lang_in_1 and 2 or 1
		template_indicated_pos = ine(parargs[pos_param]) or
			mw.title.getCurrentTitle().fullText == ("Template:%s-head"):format(langcode) and "interjection" or
			error(("Part of speech must be specified in %s="):format(pos_param))
		template_indicated_pos = canonicalize_pos(template_indicated_pos)
	end
	local head_param = numbered_head and (generic_pos_template and lang_in_1 and 3 or
		(generic_pos_template or lang_in_1) and 2 or 1) or "head"
	local indexing_pos
	if generic_pos_template then
		indexing_pos = "head." .. template_indicated_pos
		if not pos_functions[indexing_pos] then
			indexing_pos = "head"
		end
	else
		indexing_pos = template_indicated_pos
	end

	local namespace = mw.loadData(headword_data_module).page.namespace

	-- Partly initialize headdata now for use in generic infls callbacks. Will be further initialized later after
	-- processing parameters.
	local headdata = {
		lang = lang,
		langcode = langcode,
		langfullcode = lang:getFullCode(),
		langname = lang:getCanonicalName(),
		langfullname = lang:getFullName(),
		process_props = {
			namespace = namespace,
			calldata = data,
			-- preserve template-indicated POS in case we normalize it or change it to "suffix"
			template_indicated_pos = template_indicated_pos,
			indexing_pos = indexing_pos,
			generic_pos_template = generic_pos_template,
			lang_in_1 = lang_in_1,
			pos_param = pos_param,
			head_param = head_param,
			is_suffix = false,
			insert_specs = {},
		},
		-- We may change this below to "suffix" or normalize it.
		pos_category = template_indicated_pos,
		categories = {},
		inflections = {enable_auto_translit = enable_auto_translit},
		force_cat_output = force_cat,
		no_redundant_head_cat = true,
	}

	setmetatable(headdata, {__index = Headdata})

	local function resolve_prop(...)
		return headdata:resolve_prop(...)
	end

	local params = {
		[head_param] = {template_default = iargs.def},
		head2 = {replaced_by = false, instead = ("use comma-separated |%s="):format(head_param)},
		id = true,
		sort = true,
		cat = true,
		nolink = boolean_param,
		nolinkhead = {type = "boolean", alias_of = "nolink"},
		suffix = boolean_param,
		nosuffix = boolean_param,
		-- If true, this is an inflectional suffix (forming a given person/number/gender/etc. part of the inflection of
		-- a given part of speech, potentially restricted to a given inflectional class). We always treat these as
		-- suffixes, rather than suffix forms, even if they form non-lemma forms (e.g. modern English -s and archaic
		-- -eth form the third-singular present indicative of a verb, i.e. they form a verb form, but they are not
		-- themselves forms of some other suffix, which is what a suffix form is). We also display the label of
		-- inflectional suffixes specially, and add an additional category 'LANG inflectional suffixes'.
		inflsuf = boolean_param,
		clitic = {type = "boolean or string"},
		addlpos = true,
		var = {type = "boolean or string", set = {"both"}},
		abbr = true,
		json = boolean_param,
		pagename = true, -- for testing
	}
	if include_sc then
		params.sc = {type = "script"}
	end
	if include_tr then
		params.tr = true
		params.tr2 = {replaced_by = false, instead = "use comma-separated |tr= or <tr:...> inline modifier on head"}
	end
	if include_ts then
		params.ts = true
		params.ts2 = {replaced_by = false, instead = "use comma-separated |ts= or <ts:...> inline modifier on head"}
	end

	if lang_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end
	if generic_pos_template then
		params[pos_param] = {required = true} -- required but ignored as already processed above
	end

	local function augment_params_from_infls(infls)
		infls = resolve_prop(infls)
		for _, infl in ipairs(infls) do
			local function interr(txt)
				error(("Internal error: %s (coming from infls spec %s)"):format(txt, dump(infl)))
			end
			local param = infl[1]
			if param then
				param = resolve_prop(param)
				if type(param) ~= "string" and type(param) ~= "number" then
					interr(("Parameter name %s must be a string or number"):format(dump(param)))
				end
				-- We handle defaults as well as validation ourselves.
				local typ = resolve_prop(infl.type) or "string"
				if typ ~= "genders" and typ ~= "boolean" and typ ~= "string" then
					-- FIXME: Handle more types.
					interr(('Unrecognized type %s; can only currently handle "genders", "boolean" and "string" (the default)'):format(
						dump(typ)))
				end

				params[param] = {type = typ, required = resolve_prop(infl.required), template_default = resolve_prop(infl.template_default)}
				if typ ~= "boolean" then
					local allow_and_ignore_list_params = resolve_prop(infl.allow_and_ignore_list_params)
					local ignore_param
					if type(allow_and_ignore_list_params) == "string" then
						ignore_param = allow_and_ignore_list_params
					elseif type(param) == "string" then
						ignore_param = param
					end
					if ignore_param then
						local old_list_param = allow_and_ignore_list_params and true or
							{replaced_by = false, instead = ("use comma-separated |%s="):format(param)}
						params[ignore_param .. "2"] = old_list_param
						params[ignore_param .. "3"] = old_list_param
						params[ignore_param .. "4"] = old_list_param
					end
				end
			end
		end
	end

	if infls then
		augment_params_from_infls(infls)
	end

	if augment_params then
		augment_params(headdata, params)
	end

	if pos_functions[indexing_pos] then
		local pos_infls = pos_functions[indexing_pos].infls
		if pos_infls then
			augment_params_from_infls(pos_infls)
		end
		local pos_params = pos_functions[indexing_pos].params
		if pos_params then
			for key, val in pairs(pos_params) do
				params[key] = val
			end
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData(headword_data_module).pagename
	local sc = args.sc or lang:findBestScript(pagename)

	headdata.pagename = pagename
	headdata.process_props.args = args
	headdata.sc = sc
	headdata.id = args.id
	headdata.sort = args.sort
	-- No redundant script cat unless the user explicitly gave sc=
	headdata.no_script_code_cat = not args.sc
	headdata.var = args.var

	local extra_term_mods = {}
	if include_tr then
		insert(extra_term_mods, "tr")
	end
	if include_ts then
		insert(extra_term_mods, "ts")
	end
	if include_sc then
		insert(extra_term_mods, "sc")
	end
	if not extra_term_mods[1] then
		extra_term_mods = nil
	end
	local trs = args.tr and split_on_comma(args.tr) or {}
	local num_trs = #trs
	local tss = args.ts and split_on_comma(args.ts) or {}
	local num_tss = #tss
	local heads = args[head_param] and export.parse_term_with_modifiers {
		val = args[head_param],
		paramname = head_param,
		splitchar = ",",
		is_head = true,
		include_mods = extra_term_mods,
	} or {}
	local num_heads = #heads
	if num_heads > 0 and num_trs > 0 and num_heads ~= num_trs then
		error(("%s head%s specified explicitly but %s translit%s; they must match; use '+' to stand for the default head (the pagename) or default automatic translit and '-' to stand for no translit"):format(
			num_heads, num_heads > 1 and "s" or "", num_trs, num_trs > 1 and "s" or ""))
	end
	if num_heads > 0 and num_tss > 0 and num_heads ~= num_tss then
		error(("%s head%s specified explicitly but %s transcription%s; they must match; use '+' to stand for the default head (the pagename) and '-' to stand for no transcription"):format(
			num_heads, num_heads > 1 and "s" or "", num_tss, num_tss > 1 and "s" or ""))
	end
	if num_trs > 0 and num_tss > 0 and num_trs ~= num_tss then
		error(("%s translit%s specified explicitly but %s transcription%s; they must match; use '+' to stand for default automatic translit and '-' to stand for no translit or transcription"):format(
			num_trs, num_trs > 1 and "s" or "", num_tss, num_tss > 1 and "s" or ""))
	end
	-- Be careful here not to overwrite user_specified_heads if it's empty so we can later check user_specified_heads
	-- to see if the user provided any heads.
	local max_tr_ts = math.max(num_trs, num_tss)
	if num_heads == 0 and max_tr_ts > 0 then
		heads = {}
		for i = 1, max_tr_ts do
			heads[i] = {term = "+"}
		end
	end
	if not heads[1] then
		heads = {{term = "+"}}
	end
	for i, headobj in ipairs(heads) do
		if headobj.tr and trs[i] then
			if headobj.tr ~= trs[i] then
				error(("Saw two different translits '%s' and '%s' for head #%s"):format(
					headobj.tr, trs[i], i))
			end
		else
			headobj.tr = headobj.tr or trs[i]
		end
		if headobj.tr == "+" then
			headobj.tr = nil
		end
		if headobj.ts and tss[i] then
			if headobj.ts ~= tss[i] then
				error(("Saw two different transcriptions '%s' and '%s' for head #%s"):format(
					headobj.ts, tss[i], i))
			end
		else
			headobj.ts = headobj.ts or tss[i]
		end
		if headobj.ts == "-" then
			headobj.ts = nil
		end
		if headobj.term == "+" then
			headobj.term = args.nolink and pagename or nil
			if headobj.term and namespace == "Reconstruction" then
				headobj.term = "*" .. headobj.term
			end
		end
	end
	headdata.heads = heads

	local pos_category = headdata.pos_category
	-- Do this as late as possible in case the caller wants to conditionalize the primary categorizing POS on
	-- arguments or even the presence or absence of explicit heads.
	if pos_functions[indexing_pos] then
		pos_category = resolve_prop(pos_functions[indexing_pos].pos_category) or pos_category
	end
	headdata.process_props.normalized_template_indicated_pos = pos_category
	headdata.pos_category = pos_category
	headdata.process_props.pos_variants = nil -- erase the cache

	local function pagename_is_suffix()
		if sc:getCode() == "Latn" then
			-- shortcut Latin terms to avoid unnecessarily loading [[Module:affix]]
			return pagename:find("^%-") and not pagename:find("%-$")
		else
			local affix_type, _, _, _ = require(affix_module).parse_term_for_affixes(pagename, lang, sc)
			return affix_type == "suffix"
		end
	end

	local clitic_label = args.clitic
	if clitic_label == true then
		clitic_label = "clitic"
	end
	if clitic_label then
		headdata:insert_category("clitics")
		headdata:insert_fixed_inflection(clitic_label)
	elseif args.suffix or (
		not args.nosuffix and pagename_is_suffix() and pos_category ~= "suffixes" and pos_category ~= "suffix forms"
	) then
		headdata.process_props.is_suffix = true
		local function handle_suffix_pos(pos, is_first)
			-- Use the actual POS for the label we insert, but simplify the POS for the category. We need to separately check
			-- each of them to see if they end in 'forms' because e.g. 'comparative adjectives' gets simplified to
			-- 'adjective forms'.
			local form_type = pos:match("^(.*) forms$")
			if form_type then
				if args.inflsuf then
					headdata:insert_fixed_inflection(form_type .. " form inflectional suffix")
				else
					headdata:insert_fixed_inflection(form_type .. " suffix form")
				end
			else
				local singular_pos = require(en_utilities_module).singularize(pos)
				headdata:insert_fixed_inflection(("%s-forming %ssuffix"):format(
					singular_pos, args.inflsuf and "inflectional " or ""))
			end
			local simplified_pos = export.simplify_pos(pos, "preserve_proper_nouns", "preserve_lemma_status")
			local simplified_form_type = simplified_pos:match("^(.*) forms$")
			if simplified_form_type then
				headdata:insert_category(("%s suffix forms"):format(simplified_form_type))
			else
				local singular_simplified_pos = require(en_utilities_module).singularize(simplified_pos)
				headdata:insert_category(("%s-forming suffixes"):format(singular_simplified_pos))
			end
			if args.inflsuf then
				headdata:insert_category("inflectional suffixes")
			end
			local postype
			if args.inflsuf then
				postype = "suffixes"
			end
			if not postype then
				postype = require(headword_module).pos_lemma_or_nonlemma(pos)
			end
			if not postype then
				postype = require(headword_module).pos_lemma_or_nonlemma(simplified_pos)
			end
			if not postype then
				error(("Unrecognized canonicalized part of speech '%s' in addlpos=, cannot determine whether lemma or non-lemma form"):format(
					pos
				))
			end
			local this_pos_category = postype == "lemma" and "suffixes" or "suffix forms"
			if is_first then
				headdata.pos_category = this_pos_category
				headdata.process_props.pos_variants = nil -- erase the cache
			elseif headdata.pos_category ~= this_pos_category then
				local singular_normalized_this_pos_category =
					require(en_utilities_module).singularize(this_pos_category)
				local singular_normalized_overall_pos_category =
					require(en_utilities_module).singularize(headdata.pos_category)
				error(("Cannot mix suffixes and suffix forms using addlpos=; '%s' is of a %s while overall POS " ..
					"'%s' is a %s; use separate POS headers for the two"):format(pos,
					singular_normalized_this_pos_category, pos_category, singular_normalized_overall_pos_category))
			end
		end
		handle_suffix_pos(pos_category, true)
		if args.addlpos then
			for _, addlpos in ipairs(split(args.addlpos, "%s*,%s*")) do
				addlpos = canonicalize_pos(addlpos)
				handle_suffix_pos(addlpos, false)
			end
		end
	end

	if args.cat then
		for _, cat in ipairs(split_on_comma(args.cat)) do
			headdata:insert_category(cat)
		end
	end

	local function augment_headdata_from_infls(infls)
		infls = resolve_prop(infls)
		for _, infl in ipairs(infls) do
			local function interr(txt)
				error(("Internal error: %s (coming from infls spec %s)"):format(txt, dump(infl)))
			end
			local function process_labelobjs(labelobjs, originating_term, handle_labelobj)
				if labelobjs == nil then
					return
				end
				if type(labelobjs) ~= "string" and type(labelobjs) ~= "table" then
					interr(("Wrong type '%s' for label object(s) %s, expected string or table"):format(
						type(labelobjs), dump(labelobjs)
					))
				end
				if type(labelobjs) == "string" or type(labelobjs) == "table" and not labelobjs[1] then
					labelobjs = {labelobjs}
				end
				for _, labelobj in ipairs(labelobjs) do
					local label, termobj
					if type(labelobj) == "string" then
						label = labelobj
						termobj = originating_term
					elseif type(labelobj) ~= "table" then
						interr(("Wrong type '%s' for label object %s, expected string or table"):format(
							type(labelobj), dump(labelobj)
						))
						label = labelobj.term
						if type(label) ~= "string" then
							interr(("Wrong type '%s' for label %s from label object %s, expected string"):format(
								type(label), dump(label), dump(labelobj)
							))
						end
						termobj = labelobj
					end
					handle_labelobj(label, termobj)
				end
			end

			local param = infl[1]
			if param then
				local vals

				-- Fetch the param and make sure it's a string or number.
				param = resolve_prop(param)
				if type(param) ~= "string" and type(param) ~= "number" then
					interr(("Parameter name %s must be a string or number"):format(dump(param)))
				end

				-- Fetch the type and validate.
				local typ = resolve_prop(infl.type)
				if typ == nil then
					typ = "string"
				end
				if typ ~= "genders" and typ ~= "boolean" and typ ~= "string" then
					-- FIXME: Handle more types.
					interr(('Unrecognized type %s; can only currently handle "genders", "boolean" and "string" (the default)'):format(
						dump(typ)))
				end

				-- Fetch the value(s).
				if typ == "genders" or typ == "boolean" then
					vals = args[param]
				elseif typ == "string" then
					local parse_inflection_props = resolve_prop(infl.parse_inflection_props)
					local include_mods = resolve_prop(infl.include_mods)
					local no_augment_include_mods = resolve_prop(infl.no_augment_include_mods)
					if include_mods ~= nil or no_augment_include_mods ~= nil then
						if parse_inflection_props == nil then
							parse_inflection_props = {}
						else
							parse_inflection_props = shallow_copy(parse_inflection_props)
						end
						if include_mods ~= nil then
							parse_inflection_props.include_mods = include_mods
						end
						if no_augment_include_mods ~= nil then
							parse_inflection_props.no_augment_include_mods = no_augment_include_mods
						end
					end
					vals = headdata:parse_inflection(param, parse_inflection_props)
					-- Convert an empty list to nil for consistent checking below.
					if not vals[1] then
						vals = nil
					end
				else
					interr(("Unrecognized type '%s"):format(typ))
				end

				-- If value(s) nil, fetch the default.
				if vals == nil and infl.default ~= nil then
					local default = resolve_prop(infl.default)
					if typ == "genders" then
						vals = export.canonicalize_termobj_list(default, "spec", "default")
					elseif typ == "boolean" then
						vals = default
					elseif typ == "string" then
						vals = export.canonicalize_termobj_list(default, "term", "default")
					else
						interr(("Unrecognized type '%s"):format(typ))
					end
				end

				-- Resolve "special" values (special signals a string values, such as requesting the default with "+").
				if vals ~= nil and infl.resolve_special then
					if typ ~= "string" then
						interr(("Cannot specify resolve_special= for type %s"):format(dump(typ)))
					end
					local resolve_special_props = resolve_prop(infl.resolve_special_props, vals)
					if infl.is_special ~= nil then
						if resolve_special_props == nil then
							resolve_special_props = {}
						else
							resolve_special_props = shallow_copy(resolve_special_props)
						end
						resolve_special_props.is_special = infl.is_special
					end
					vals = headdata:resolve_special(vals, infl.resolve_special, resolve_special_props)
				end

				-- Validate the value(s).
				if vals ~= nil and infl.validate ~= nil then
					if typ == "boolean" then
						interr('Cannot specify validate= when type is "boolean"')
					elseif type(infl.validate) == "function" then
						infl.validate(headdata, vals)
					elseif typ == "genders" then
						headdata:validate_genders(vals, infl.validate)
					elseif typ == "string" then
						validate_items {
							items = vals,
							field = "term",
							valid_items = infl.validate,
							item_type = ("values in |%s="):format(param),
						}
					else
						interr(("Unrecognized type '%s"):format(typ))
					end
				end

				-- Run the process_after_parse handler, if it exists.
				if vals ~= nil and infl.process_after_parse ~= nil then
					local intentionally_nil
					vals, intentionally_nil = infl.process_after_parse(headdata, vals)
					if vals == nil and not intentionally_nil then
						interr("If you return nil from process_after_parse, you must return a second non-nil return " ..
							"value to indicate that the nil return value was intentional")
					end
				end

				-- "Implement" the values, if non-falsy (i.e. we don't want to fire on boolean false or empty list).
				-- If a fixed label is specified, insert it. Then, depending on the type, attach the values to a label
				-- as an inflection, set the `genders` field, or do nothing if boolean (throwing an error if there was
				-- no fixed label).
				local insert_request = resolve_prop(infl.request, vals)
				if vals == true or type(vals) == "table" and vals[1] or insert_request then
					if infl.fixed_label and infl.all_fixed_label then
						interr("Cannot specify both fixed_label= and all_fixed_label=; specify one or the other")
					end
					local function check_fixed_label_references_val(label)
						if type(label) == "table" and label[1] then
							for _, lab in ipairs(label) do
								if check_fixed_label_references_val(lab) then
									return true
								end
							end
							return false
						end
						if type(label) == "table" then
							if not label.term then
								interr(("Fixed label structure %s does not have a value for `.term`"):format(dump(label)))
							end
							label = label.term
						end
						if type(label) ~= "string" then
							interr(("Wrong type for fixed label %s, should be string"):format(type(label)))
						end
						return not not label:find("{val}")
					end
					local fixed_label = infl.fixed_label
					local all_fixed_label = infl.all_fixed_label
					-- If the value being processed is boolean, there's only one value so treat a fixed_label as an
					-- all_fixed_label and output only once; likewise if the caller specified a fixed_label without
					-- {val} in it.
					if fixed_label and (typ == "boolean" or type(fixed_label) ~= "function" and not
						check_fixed_label_references_val(fixed_label)) then
						all_fixed_label = fixed_label
						fixed_label = nil
					end
					local inserted_fixed_label
					if fixed_label then
						if typ == "boolean" then
							interr("Boolean fixed_label values should have been converted to all_fixed_label")
						end
						for _, valobj in ipairs(vals) do
							local labelobjs = resolve_prop(fixed_label, valobj)
							process_labelobjs(labelobjs, valobj, function(label, termobj)
								if label:find("{val}") then
									if typ ~= "string" then
										interr(('Cannot specify {val} in fixed_label %s when type is "%s"'):format(dump(label), typ))
									end
									label = label:gsub("{val}", replacement_escape(valobj.term))
								end
								headdata:insert_fixed_inflection(label, {
									originating_term = termobj
								})
								inserted_fixed_label = true
							end)
						end
					elseif all_fixed_label then
						local labelobjs = resolve_prop(all_fixed_label, vals)
						process_labelobjs(labelobjs, nil, function(label, termobj)
							if label:find("{vals}") then
								if typ ~= "string" then
									interr(('Cannot specify {vals} in all_fixed_label %s when type is "%s"'):format(dump(label), typ))
								end
								local formatted_labels = {}
								for _, valobj in ipairs(vals) do
									insert(formatted_labels, add_decorations(valobj.term, valobj, lang))
								end
								label = label:gsub("{vals}", replacement_escape(serial_comma_join(formatted_labels)))
							end
							headdata:insert_fixed_inflection(label, termobj)
							inserted_fixed_label = true
						end)
					end
					local inserted_vals
					if infl.label ~= nil then
						if typ ~= "string" then
							interr(("label=%s can only be specified for type 'string', not '%s'"):format(
								dump(infl.label), typ
							))
						end
						local label = resolve_prop(infl.label, vals)
						if label ~= nil then
							local insert_inflection_props = resolve_prop(infl.insert_inflection_props, vals)
							local function copy_to_insert_inflection_props(field, val)
								local fieldval = val or resolve_prop(infl[field], vals)
								if fieldval ~= nil then
									if insert_inflection_props == nil then
										insert_inflection_props = {}
									else
										insert_inflection_props = shallow_copy(insert_inflection_props)
									end
									insert_inflection_props[field] = fieldval
								end
							end
							copy_to_insert_inflection_props("label_for_cats_and_modes")
							copy_to_insert_inflection_props("no_auto_cats")
							copy_to_insert_inflection_props("accel")
							copy_to_insert_inflection_props("accel_form")
							if insert_request then
								copy_to_insert_inflection_props("request", insert_request)
							end
							local insert_spec = headdata:insert_inflection(vals, label, insert_inflection_props)
							headdata.process_props.insert_specs[param] = insert_spec
							inserted_vals = true
						end
					end
					if typ == "genders" then
						headdata.genders = vals
					end

					local inserted_cat
					if infl.cat then
						if typ == "boolean" then
							vals = {vals}
						end
						local allcats = {}
						for _, valobj in ipairs(vals) do
							local cats = resolve_prop(infl.cat, valobj)
							if type(cats) == "string" then
								cats = {cats}
							end
							if cats ~= nil then
								for _, cat in ipairs(cats) do
									if cat:find("{val}") then
										cat = cat:gsub("{val}", replacement_escape(valobj.term))
									end
									insert_if_not(allcats, cat)
								end
							end
						end
						for _, cat in ipairs(allcats) do
							headdata:insert_category(cat)
							inserted_cat = true
						end
					end

					if typ == "boolean" then
						if not inserted_fixed_label and not inserted_cat then
							interr(("User set boolean setting for %s= but no fixed label added and no category " ..
								"inserted; if you took action in process_after_parse(), make sure to return " ..
								"`nil, true`"):format(param))
						end
					elseif typ == "string" then
						if not inserted_vals and not inserted_fixed_label and not inserted_cat then
							interr(("User set value(s) %s for %s= but no inflection inserted and no fixed label " ..
								"or category added; if you took action in process_after_parse(), make sure to " ..
								"return `nil, true`"):format(dump(vals), param))
						end
					end
				end
			else -- no param specified
				if infl.label or infl.all_fixed_label then
					interr("Cannot have label= or all_fixed_label= without specifying a param")
				end
				if infl.fixed_label then
					local labelobjs = resolve_prop(infl.fixed_label)
					process_labelobjs(labelobjs, nil, function(label, termobj)
						if label:find("{val}") then
							interr("Cannot specify {val} in a fixed_label= value without specifying a param")
						end
						headdata:insert_fixed_inflection(label, {
							originating_term = termobj
						})
					end)
				end

				if infl.cat then
					local cats = resolve_prop(infl.cat)
					if type(cats) == "string" then
						cats = {cats}
					end
					if cats ~= nil then
						for _, cat in ipairs(cats) do
							if cat:find("{val}") then
								interr("Cannot specify {val} in a cat= value without specifying a param")
							end
							headdata:insert_category(cat)
						end
					end
				end
			end
		end
	end

	if infls then
		augment_headdata_from_infls(infls)
	end

	if augment_headdata then
		augment_headdata(headdata, args)
	end

	if pos_functions[indexing_pos] then
		local pos_infls = pos_functions[indexing_pos].infls
		if pos_infls then
			augment_headdata_from_infls(pos_infls)
		end
		local func = pos_functions[indexing_pos].func
		if func then
			func(headdata, args)
		end
	end

	headdata:parse_and_insert_inflection("abbr", "abbreviation")

	setmetatable(headdata, nil)
	headdata.process_props = nil

	if args.json then
		return require("Module:JSON").toJSON(headdata)
	end

	return require(headword_module).full_headword(headdata)
end


return export
