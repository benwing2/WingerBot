local export = {}

local fun_is_callable_module = "Module:fun/isCallable"
local languages_module = "Module:languages"
local parse_utilities_module = "Module:parse utilities"
local string_pattern_escape_module = "Module:string/patternEscape"
local string_replacement_escape_module = "Module:string/replacementEscape"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

local dump = mw.dumpObject
local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local insert = table.insert
local concat = table.concat

local function escape_wikicode(...)
	escape_wikicode = require(parse_utilities_module).escape_wikicode
	return escape_wikicode(...)
end

local function extend(...)
	extend = require(table_module).extend
	return extend(...)
end

local function get_lang(...)
	get_lang = require(languages_module).getByCode
	return get_lang(...)
end

local function insert_if_not(...)
	insert_if_not = require(table_module).insertIfNot
	return insert_if_not(...)
end

local function is_callable(...)
	is_callable = require(fun_is_callable_module)
	return is_callable(...)
end

local function parse_inline_modifiers(...)
	parse_inline_modifiers = require(parse_utilities_module).parse_inline_modifiers
	return parse_inline_modifiers(...)
end

local function pattern_escape(...)
	pattern_escape = require(string_pattern_escape_module)
	return pattern_escape(...)
end

local function replacement_escape(...)
	replacement_escape = require(string_replacement_escape_module)
	return replacement_escape(...)
end

local function shallow_copy(...)
	shallow_copy = require(table_module).shallowCopy
	return shallow_copy(...)
end

local function split(...)
	split = require(string_utilities_module).split
	return split(...)
end

local function term_contains_top_level_html(...)
	term_contains_top_level_html = require(parse_utilities_module).term_contains_top_level_html
	return term_contains_top_level_html(...)
end

local function ugsub(...)
	ugsub = require(string_utilities_module).gsub
	return ugsub(...)
end

local function umatch(...)
	umatch = require(string_utilities_module).match
	return umatch(...)
end


local param_mods = {
	id = {},
	q = {type = "qualifier"},
	qq = {type = "qualifier"},
	l = {type = "labels"},
	ll = {type = "labels"},
	-- [[Module:headword]] expects part references in `.refs`.
	ref = {item_dest = "refs", type = "references", store = "insert-flattened"},
}

local optional_param_mods = {
	g = {item_dest = "genders", type = "genders"},
	alt = {},
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
  the allowed modifiers.
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
		return {term = term}
	end

	-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude top-level HTML entry with <span ...>,
	-- <sup> or similar in it.
	if (val:find("<", nil, true) or data.splitchar) and not term_contains_top_level_html(val) then
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
* `frob`, `include_mods`, `exclude_mods`, `is_head`, `preserve_splitchar`, `delimiter_key`, `escape_fun`,
  `unescape_fun`, `pre_normalize_modifiers`: As in `parse_term_with_modifiers()`.
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
			parsed.q = {qualifiers[i]}
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
Check if any of a list of parsed terms (as returned by `parse_term_list_with_modifiers()`) are red links (i.e.
nonexistent pages). If so, a category such as [[Category:Spanish nouns with red links in their headword lines]] is added
to `headdata.categories`. `data` is an object with the following fields:
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `terms`: The list of parsed terms. Required.
* `lang`: The language object for the language of the terms. Required.
* `plpos`: The plural part of speech, for the category name. Required.
]==]
function export.check_term_list_missing(data)
	local headdata, terms, lang, plpos = data.headdata, data.terms, data.lang, data.plpos
	for _, term in ipairs(terms) do
		if type(term) == "table" then
			term = term.term
		end
		if term then
			local title = mw.title.new(term)
			if title and not title:getContent() then
				insert(headdata.categories, lang:getFullName() .. " " .. plpos ..
					" with red links in their headword lines")
			end
		end
	end
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


function export.insert_fixed_inflection(data)
	local headdata, origterm, label = data.headdata, data.originating_term, data.label
	if not origterm then
		insert(headdata.inflections, {
			label = export.replace_glossary_links_in_label(label)
		})
	else
		if origterm.id then
			error(("It doesn't make sense to pass in an ID '%s' for label '%s' in conjunction with a term value '%s'"
				):format(origterm.id, label, origterm.term))
		end
		-- Preserve qualifiers, labels, references
		origterm.term = nil
		origterm.label = export.replace_glossary_links_in_label(label)
		insert(headdata.inflections, origterm)
	end
end


--[==[
Insert previously-parsed terms into `headdata.inflections`. `data` is an object with the following fields:
* `headdata`: The headword structure passed to [[Module:headword]]. Required.
* `terms`: The list of parsed terms. If {nil} or omitted, nothing happens.
* `label`: The label that the inflections are given; any parts of the label surrounded in <<...>> are linked to the
glossary. (If the contents of <<...> contain a | in them, they are a two-part link.) Required.
* `accel`: If specified, a full accelerator object to add to the inflections.
* `check_missing`: If specified, check the parsed terms for red links, and if so, add a category such as
  [[Category:Spanish nouns with red links in their headword lines]] to `headdata.categories`. If this is given, so must
  `lang` and `plpos`.
* `lang`: The language object for the language of the terms. Required if `check_missing` is given.
* `plpos`: The plural part of speech, for the category name. Required if `check_missing` is given.
]==]
function export.insert_inflection(data)
	local headdata, terms, label = data.headdata, data.terms, data.label
	if terms and terms[1] then
		if terms[1].term == "-" then
			if terms[2] then
				-- FIXME: We probably want to pass in an error function
				error(("Don't know how to handle '-' as an inflection for label '%s' along with a second value %s"
					):format(label, terms[2].term and ("'%s'"):format(terms[2].term) or "(nil)"))
			end
			export.insert_fixed_inflection {
				headdata = headdata,
				originating_term = terms[1],
				label = "no " .. label,
			}
		else
			if data.check_missing then
				export.check_term_list_missing {
					headdata = headdata,
					terms = terms,
					lang = data.lang,
					plpos = data.plpos,
				}
			end
			terms.label = export.replace_glossary_links_in_label(label)
			if data.accel then
				terms.accel = data.accel
			end
			insert(headdata.inflections, terms)
		end
	elseif data.request then
		insert(headdata.inflections, {
			label = export.replace_glossary_links_in_label(label),
			request = true,
		})
	end
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
* `accel`, `check_missing`, `lang`, `plpos`: As in `insert_inflection()`.
]==]
function export.parse_and_insert_inflection(data)
	local forms = data.forms
	if forms and forms[1] then
		data = shallow_copy(data)
		data.forms = forms
		data.terms = export.parse_term_list_with_modifiers(data)
		export.insert_inflection(data)
	end
end


--[==[
Combine two sets of qualifiers or labels. If either is {nil}, just return the other, and if both are {nil}, return
{nil}.
]==]
function export.combine_qualifiers_or_labels(quals1, quals2)
	if not quals1 and not quals2 then
		return nil
	end
	if not quals1 then
		return quals2
	end
	if not quals2 then
		return quals1
	end
	local combined = shallow_copy(quals1)
	for _, note in ipairs(quals2) do
		insert_if_not(combined, note)
	end
	return combined
end


function export.combine_termobj_qualifiers_labels(destobj, srcobj)
	destobj.q = export.combine_qualifiers_or_labels(destobj.q, srcobj.q)
	destobj.qq = export.combine_qualifiers_or_labels(destobj.qq, srcobj.qq)
	destobj.l = export.combine_qualifiers_or_labels(destobj.l, srcobj.l)
	destobj.ll = export.combine_qualifiers_or_labels(destobj.ll, srcobj.ll)
	destobj.refs = export.combine_qualifiers_or_labels(destobj.refs, srcobj.refs)
	if destobj.id and srcobj.id and destobj.id ~= srcobj.id then
		-- FIXME: We probably want to pass in an error function
		error(("Can't specify two different ID's %s and %s when combining objects"):format(srcobj.id, destobj.id))
	end
	destobj.id = destobj.id or srcobj.id
	return destobj
end


function export.termobj_has_qualifiers_or_labels(obj)
	return obj.q and obj.q[1] or obj.qq and obj.qq[1] or obj.l and obj.l[1] or obj.ll and obj.ll[1] or
		obj.refs and obj.refs[1]
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
function export.apply_link_modifiers(linked_term, modifier_spec)
	local split_modspecs = split(modifier_spec, "%s*;%s*")
	for j, modspec in ipairs(split_modspecs) do
		local subterm, dest, otherlang
		local begin_from, begin_to, rest, end_from, end_to = modspec:match("^%[(.-):(.*)%]([^:]*)%[(.-):(.*)%]$")
		if begin_from then
			subterm = begin_from .. rest .. end_from
			dest = begin_to .. rest .. end_to
		end
		if not subterm then
			rest, end_from, end_to = modspec:match("^([^:]*)%[(.-):(.*)%]$")
			if rest then
				subterm = rest .. end_from
				dest = rest .. end_to
			end
		end
		if not subterm then
			begin_from, begin_to, rest = modspec:match("^%[(.-):(.*)%]([^:]*)$")
			if begin_from then
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
					otherlang = get_lang(otherlang, true, "allow etym")
					dest = langdest
				end
			end
		end
		if not subterm then
			error(("Single modifier spec %s should be of the form SUBTERM:DEST where SUBTERM is one or more words in a multiword "
					.. "term and DEST is the destination to link the subterm to (possibly prefixed by a language code); or of "
					.. "the form BEGIN[FROM:TO], which is equivalent to BEGINFROM:BEGINTO; or similarly [FROM:TO]END, which is "
					.. "equivalent to FROMEND:TOEND"):
				format(modspec))
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
			local subterm_re = "%[%[" .. escaped_subterm:gsub("(%%?[ '%-])", "%%]*%1%%[*") .. "%]%]"
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
			if expanded_dest:find("[", nil, true) then
				-- Use the destination directly if it has brackets in it (e.g. to put brackets around parts of a word).
				subterm_replacement = expanded_dest
			elseif expanded_dest == subterm then
				subterm_replacement = "[[" .. subterm .. "]]"
			else
				subterm_replacement = "[[" .. expanded_dest .. "|" .. subterm .. "]]"
			end

			local replaced_linked_term = ugsub(linked_term, subterm_re, replacement_escape(subterm_replacement))
			if replaced_linked_term == linked_term then
				error(("Subterm '%s' could not be located in %slinked expression %s, or replacement same as subterm"):format(
					subterm, j > 1 and "intermediate " or "", escape_wikicode(linked_term)))
			else
				linked_term = replaced_linked_term
			end
		end
	end

	return linked_term
end


return export
