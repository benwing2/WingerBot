--[=[
	This module contains functions to implement quote-* templates.

	Author: Benwing2; conversion into Lua of {{quote-meta/source}} template,
	written by Sgconlaw with some help from Erutuon and Benwing2.

	The main interface is quote_t(). Note that the source display is handled by source(), which reads both the
	arguments passed to it *and* the arguments passed to the parent template, with the former overriding the latter.
]=]

local export = {}

--[=[
FIXME:
1. Dates like `1 march 2025` with the day of the month being 1 and the month lowercased are treated as month-year-only.
   The relevant code checks for a capitalized word; it should probably instead check for the actual month names or
   abbrevs.
]=]
-- Named constants for all modules used, to make it easier to swap out sandbox versions.
local check_isxn_module = "Module:check isxn"
local debug_track_module = "Module:debug/track"
local en_utilities_module = "Module:en-utilities"
local italics_module = "Module:italics"
local labels_module = "Module:labels"
local languages_module = "Module:languages"
local languages_error_module = "Module:languages/error"
local links_module = "Module:links"
local number_utilities_module = "Module:number utilities"
local parameters_module = "Module:parameters"
local parse_utilities_module = "Module:parse utilities"
local qualifier_module = "Module:qualifier"
local roman_numerals_module = "Module:roman numerals"
local scribunto_module = "Module:Scribunto"
local script_utilities_module = "Module:script utilities"
local scripts_module = "Module:scripts"
local string_pattern_escape_module = "Module:string/patternEscape"
local string_replacement_escape_module = "Module:string/replacementEscape"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local template_parser_module = "Module:template parser"
local usex_module = "Module:usex"
local usex_templates_module = "Module:usex/templates"
local utilities_module = "Module:utilities"
local yesno_module = "Module:yesno"

local concat = table.concat
local insert = table.insert
local new_title = mw.title.new
local remove = table.remove
local require = require
local sort = table.sort
local u = mw.ustring.char
local ugsub = mw.ustring.gsub
local umatch = mw.ustring.match
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

-- Use HTML entities here to avoid parsing issues (esp. with brackets)
local SEMICOLON_SPACE = "&#59; "
local SPACE_LBRAC = " &#91;"
local RBRAC = "&#93;"

local TEMP_LT = u(0xFFF1)
local TEMP_GT = u(0xFFF2)
local TEMP_LBRAC = u(0xFFF3)
local TEMP_RBRAC = u(0xFFF4)
local TEMP_SEMICOLON = u(0xFFF5)

local function apply_subst(...)
	apply_subst = require(usex_module).apply_subst
	return apply_subst(...)
end

local function check_isbn(...)
	check_isbn = require(check_isxn_module).check_isbn
	return check_isbn(...)
end

local function check_issn(...)
	check_issn = require(check_isxn_module).check_issn
	return check_issn(...)
end

local function debug_track(...)
	debug_track = require(debug_track_module)
	return debug_track(...)
end

local function decode_entities(...)
	decode_entities = require(string_utilities_module).decode_entities
	return decode_entities(...)
end

local function embedded_language_links(...)
	embedded_language_links = require(links_module).embedded_language_links
	return embedded_language_links(...)
end

local function escape_wikicode(...)
	escape_wikicode = require(parse_utilities_module).escape_wikicode
	return escape_wikicode(...)
end

local function find_best_script_without_lang(...)
	find_best_script_without_lang = require(scripts_module).findBestScriptWithoutLang
	return find_best_script_without_lang(...)
end

local function find_parameters(...)
	find_parameters = require(template_parser_module).find_parameters
	return find_parameters(...)
end

local function format_categories(...)
	format_categories = require(utilities_module).format_categories
	return format_categories(...)
end

local function format_processed_labels(...)
	format_processed_labels = require(labels_module).format_processed_labels
	return format_processed_labels(...)
end

local function format_qualifier(...)
	format_qualifier = require(qualifier_module).format_qualifier
	return format_qualifier(...)
end

local function format_usex(...)
	format_usex = require(usex_module).format_usex
	return format_usex(...)
end

local function get_lang(...)
	get_lang = require(languages_module).getByCode
	return get_lang(...)
end

local function get_number(...)
	get_number = require(number_utilities_module).get_number
	return get_number(...)
end

local function get_script(...)
	get_script = require(scripts_module).getByCode
	return get_script(...)
end

local function gsplit(...)
	gsplit = require(string_utilities_module).gsplit
	return gsplit(...)
end

local function page_should_be_ignored(...)
	page_should_be_ignored = require(usex_templates_module).page_should_be_ignored
	return page_should_be_ignored(...)
end

local function parse_inline_modifiers(...)
	parse_inline_modifiers = require(parse_utilities_module).parse_inline_modifiers
	return parse_inline_modifiers(...)
end

local function parse_inline_modifiers_from_segments(...)
	parse_inline_modifiers_from_segments = require(parse_utilities_module).parse_inline_modifiers_from_segments
	return parse_inline_modifiers_from_segments(...)
end

local function parse_multi_delimiter_balanced_segment_run(...)
	parse_multi_delimiter_balanced_segment_run = require(parse_utilities_module).parse_multi_delimiter_balanced_segment_run
	return parse_multi_delimiter_balanced_segment_run(...)
end

local function parse_term_with_lang(...)
	parse_term_with_lang = require(parse_utilities_module).parse_term_with_lang
	return parse_term_with_lang(...)
end

local function pattern_escape(...)
	pattern_escape = require(string_pattern_escape_module)
	return pattern_escape(...)
end

local function pluralize(...)
	pluralize = require(en_utilities_module).pluralize
	return pluralize(...)
end

local function process_params(...)
	process_params = require(parameters_module).process
	return process_params(...)
end

local function remove_links(...)
	remove_links = require(links_module).remove_links
	return remove_links(...)
end

local function roman_to_arabic(...)
	roman_to_arabic = require(roman_numerals_module).roman_to_arabic
	return roman_to_arabic(...)
end

local function replacement_escape(...)
	replacement_escape = require(string_replacement_escape_module)
	return replacement_escape(...)
end

local function scribunto_parameter_key(...)
	scribunto_parameter_key = require(scribunto_module).scribunto_parameter_key
	return scribunto_parameter_key(...)
end

local function serial_comma_join(...)
	serial_comma_join = require(table_module).serialCommaJoin
	return serial_comma_join(...)
end

local function shallow_copy(...)
	shallow_copy = require(table_module).shallowCopy
	return shallow_copy(...)
end

local function split(...)
	split = require(string_utilities_module).split
	return split(...)
end

local function split_alternating_runs(...)
	split_alternating_runs = require(parse_utilities_module).split_alternating_runs
	return split_alternating_runs(...)
end

local function split_and_process_raw_labels(...)
	split_and_process_raw_labels = require(labels_module).split_and_process_raw_labels
	return split_and_process_raw_labels(...)
end

local function split_on_comma(...)
	split_on_comma = require(parse_utilities_module).split_on_comma
	return split_on_comma(...)
end

local function tag_text(...)
	tag_text = require(script_utilities_module).tag_text
	return tag_text(...)
end

local function tag_transcription(...)
	tag_transcription = require(script_utilities_module).tag_transcription
	return tag_transcription(...)
end

local function tag_translit(...)
	tag_translit = require(script_utilities_module).tag_translit
	return tag_translit(...)
end

local function ulen(...)
	ulen = require(string_utilities_module).len
	return ulen(...)
end

local function unitalicize_brackets(...)
	unitalicize_brackets = require(italics_module).unitalicize_brackets
	return unitalicize_brackets(...)
end

local function upper(...)
	upper = require(string_utilities_module).upper
	return upper(...)
end

local function usub(...)
	usub = require(string_utilities_module).sub
	return usub(...)
end

local function yesno(...)
	yesno = require(yesno_module)
	return yesno(...)
end

local function track(page)
	debug_track("quote/" .. page)
end

local function maintenance_line(text)
	return '<span class="maintenance-line">(' .. text .. ")</span>"
end

local function isbn(text)
	return "[[Special:BookSources/"
		.. text
		.. "|→ISBN]]"
		.. check_isbn(
			text,
			'&nbsp;<span class="error" style="font-size:88%">Invalid&nbsp;ISBN</span>[[Category:Pages with ISBN errors]]'
		)
end

local function issn(text)
	return "[https://www.worldcat.org/issn/"
		.. text
		.. " →ISSN]"
		.. check_issn(
			text,
			'&nbsp;<span class="error" style="font-size:88%">Invalid&nbsp;ISSN</span>[[Category:Pages with ISSN errors]]'
		)
end

local function lccn(text)
	text = text:gsub(" ", "")
	if text:find("-") then
		-- old-style LCCN; reformat per request by [[User:The Editor's Apprentice]]
		local prefix, part1, part2 = text:match("^(.-)(%d+)%-(%d+)$")
		if prefix then
			if ulen(part2) < 6 then
				part2 = ("0"):rep(6 - ulen(part2)) .. part2
			end
			text = prefix .. part1 .. part2
		end
	end
	return "[https://lccn.loc.gov/" .. mw.uri.encode(text) .. " →LCCN]"
end

local function format_date(text)
	return mw.getCurrentFrame():callParserFunction("#formatdate", text, "dmy")
end

-- Parse a raw ll= param (or nil) to individual label info objects and then concatenate them appropriately into a
-- qualifier input, respecting flags like `omit_preComma` and `omit_postSpace` in the label specs.
local function parse_and_format_labels(raw_ll, lang)
	if not raw_ll then
		return nil
	end
	local labels = split_and_process_raw_labels {labels = raw_ll, lang = lang, nocat = true}
	labels = format_processed_labels {labels = labels, lang = lang, no_ib_content = true}
	if labels ~= "" then -- not sure labels can be an empty string but it seems possible in some circumstances
		return {labels}
	end
end

-- Convert a comma-separated list of language codes to a comma-separated list of language names. `fullname` is the
-- name of the parameter from which the list of language codes was fetched.
local function format_langs(langs)
	local names = {}
	for i, lang in ipairs(langs) do
		names[i] = lang:getCanonicalName()
	end
	if #names == 1 then
		return names[1]
	end
	return serial_comma_join(names)
end

local function get_first_lang(langs)
	return langs[1] or get_lang("und")
end

--[=[
Normally we parse off inline modifiers and language code prefixes in various places, e.g. he:מרים<tr:Miryem>. But we
exclude HTML entries with <span ...>, <i ...>, <br/> or similar in it, caused by wrapping an argument in {{l|...}},
{{lang|...}} or similar. Basically, all tags of the sort we parse here should consist of a less-than sign, plus letters,
plus a colon, e.g. <tr:...>, so if we see a tag on the outer level that isn't in this format, we don't try to parse it.
The restriction to the outer level is to allow generated HTML inside of e.g. qualifier modifiers, such as
foo<q:similar to {{m|fr|bar}}> (if we end up supporting such modifiers).

Also exclude things that look like URL's from being parsed as having language code prefixes.
]=]
local function val_should_not_be_parsed_for_annotations(val)
	return val:find("^[^<]*<%l*[^%l:]") or val:find("^%l+://")
end

local param_mods = {
	t = {
		-- <t:...> and <gloss:...> are aliases.
		item_dest = "gloss",
	},
	gloss = {},
	alt = {},
	tr = {},
	ts = {},
	subst = {},
	sc = {type = "script"},
	f = {
		convert = function(arg, parse_err)
			local prefix, val = arg:match("^(.-):([^ ].*)$")
			if not prefix then
				prefix = ""
				val = arg
			end
			local tags, sc_code, sc = prefix:match("^(.*)/(.-)$")
			if sc_code then
				sc = get_script(sc_code) or
					require(languages_error_module)(sc_code, parse_err, "script code", nil, "not real lang")
			else
				tags = prefix
			end
			local quals
			if tags ~= "" then
				quals = split_on_comma(tags)
				for i, qual in ipairs(quals) do
					local obj = get_lang(qual, nil, "allow etym") or get_script(qual)
					quals[i] = obj or qual
				end
			end
			return {
				quals = quals,
				sc = sc,
				val = val,
			}
		end,
		store = "insert",
	},
	q = {},
	qq = {},
}

local function generate_obj_annotated_text(text, parse_err, paramname)
	local obj = {}
	if text:find(":[^ ]") or text:find("%[%[") then
		local display, is_wikipedia_wikisource
		obj.text, obj.lang, obj.link, display, is_wikipedia_wikisource =
			parse_term_with_lang {
				term = text,
				parse_err = parse_err,
				paramname = paramname
			}
		-- HACK: If object is a Wikipedia or Wikisource link, we need to convert it to a two-part link
		-- to avoid the w: or s: prefix showing. We should probably avoid this by calling
		-- language_link() (in [[Module:links]]) in format_annotated_text() instead of the hacky stuff
		-- that we currently do; but we need to test that carefully to make sure it doesn't do things like
		-- munge % signs.
		if is_wikipedia_wikisource and not obj.text:find("%[%[") and not obj.text:find("%]%]") then
			-- Don't directly set .alt, because then if the user specifies <alt:...>, it will cause an error in
			-- parse_inline_modifiers().
			obj.display = display
		end
	else
		obj.text = text
		obj.link = text
	end
	return obj
end

--[=[
Parse a textual property that may be in a foreign language or script and may be annotated with a language prefix and/or
inline modifiers. `val` is the value of the parameter and `fullname` is the name of the parameter from which the value
was retrieved. `explicit_gloss`, if specified and non-nil, overrides any gloss specified using the <t:...> or
<gloss:...> inline modifier.

If `val` is nil, the return value of this function is nil. Otherwise it is parsed for a language prefix (e.g.
'ar:مُؤَلِّف') and inline modifiers (e.g. 'ar:مُؤَلِّف<t:Author>'), and the return value is an object with the following
fields:
  `lang`: The language object corresponding to the language prefix, if specified, or nil if no language prefix is
          given.
  `text`: The text after stripping off any language prefix and inline modifiers.
  `link`: The link part of the text if it consists of a two-part link; otherwise, same as `text`.
  `alt`: Display text specified using the <alt:...> modifier, if given; otherwise, nil.
  `subst`: Substitutions used to generate the transliteration, in the same format as the subst= parameter.
  `sc`: The script object corresponding to the <sc:...> modifier, if given; otherwise nil.
  `tr`: The transliteration corresponding to the <tr:...> modifier, if given; otherwise nil.
  `ts`: The transcription corresponding to the <ts:...> modifier, if given; otherwise nil.
  `gloss`: The gloss/translation corresponding to the `explicit_gloss` parameter (if given and non-nil), otherwise
           the <t:...> or <gloss:...> modifiers if given, otherwise nil.
  `f`: Foreign versions of the text.
  `q`: Left qualifiers.
  `qq`: Right qualifiers.

Note that as a special case, if `val` contains HTML tags at the top level (e.g. '<span class="Arab">...</span>', as
might be generated by specifying {{lang|ar|مُؤَلِّف}}), no language prefix or inline modifiers are parsed, and the return
value has the `noscript` field set to true, which tells format_annotated_text() not to try to identify the script of
the text and CSS-tag the text accordingly, but to leave the text untagged.

This object can be passed to format_annotated_text() to format a string displaying the text (appropriately
script-tagged, unless `noscript` is set, as described above) and modifiers.
]=]
local function parse_annotated_text(val, fullname, explicit_gloss)
	if not val then
		return nil
	end
	-- When checking for inline modifiers, exclude HTML entry with <span ...>, <i ...>, <br/> or similar in it, caused
	-- by wrapping an argument in {{l|...}}, {{lang|...}} or similar. Also exclude URL's from being parsed as having
	-- language code prefixes. See val_should_not_be_parsed_for_annotations() for more information. If we find a
	-- parameter value with top-level HTML in it, add 'noscript = true' to indicate that we should not try to do script
	-- inference and tagging. (Otherwise, e.g. if you specify {{lang|ar|مُؤَلِّف}} as the author, you'll get an extra big
	-- font coming from the fact that {{lang|...}} wraps the Arabic text in CSS that increases the size from the
	-- default, and then we do script detection and again wrap the text in the same CSS, which increases the size even
	-- more.)
	if val_should_not_be_parsed_for_annotations(val) then
		return {text = val, link = val, noscript = true, gloss = explicit_gloss}
	end

	local obj
	if val:find("<") then
		-- Check for inline modifier.
		obj = parse_inline_modifiers(val, {
			paramname = fullname,
			param_mods = param_mods,
			generate_obj = generate_obj_annotated_text,
		})
	else
		obj = generate_obj_annotated_text(val, nil, fullname)
	end

	if explicit_gloss then
		obj.gloss = explicit_gloss
	end

	return obj
end

local html_entity_char_to_replacement = {
	["<"] = TEMP_LT,
	[">"] = TEMP_GT,
	["["] = TEMP_LBRAC,
	["]"] = TEMP_RBRAC,
}

local function html_entity_replacement(entity, code_without_semicolon, hash, xcode, x, code)
	-- Try to decode the entity. If successful, Replace certain special HTML entities (those that are bracket-like)
	-- with single Unicode characters; otherwise, replace the semicolon with a special character so it won't get
	-- interpreted as a delimiter.
	local ch = decode_entities(entity)
	if ch ~= entity then
		return html_entity_char_to_replacement[ch] or code_without_semicolon .. TEMP_SEMICOLON
	end
	-- If the entity doesn't decode, escape it anyway iff it follows a valid format.
	if hash == "" then
		-- Any nonstandard MediaWiki-only entities have now been filtered off, so treat any non-ASCII characters as
		-- invalid.
		return xcode:match("^[^\128-\255]+$") and code_without_semicolon .. TEMP_SEMICOLON or entity
	elseif x == "" then
		return xcode:match("^%d+$") and code_without_semicolon .. TEMP_SEMICOLON or entity
	end
	return code:match("^%x+$") and code_without_semicolon .. TEMP_SEMICOLON or entity
end

local html_entity_replacement_to_char = {
	[TEMP_LT] = "&lt;",
	[TEMP_GT] = "&gt;",
	[TEMP_LBRAC] = "&#91;",
	[TEMP_RBRAC] = "&#93;",
	[TEMP_SEMICOLON] = ";",
}

local function undo_html_entity_replacement(txt)
	-- Pattern covers everything in html_entity_replacement_to_char.
	return (txt:gsub("\239\191[\177-\181]", html_entity_replacement_to_char))
end

-- NOTE: We try hard to optimize this function for the common cases and avoid loading [[Module:parse utilities]]
-- in such cases. The cases we can handle without loading [[Module:parse utilities]] are single values (no
-- semicolons present) without inline modifiers or language prefixes, and multi-entity values (semicolons present)
-- without (a) brackets of any kind (including parens, braces and angle brackets; angle brackets typically indicate
-- inline modifiers and other brackets may protect a semicolon from being interpreted as a delimiter);
-- (b) ampersands (which may indicate HTML entities, which protect a semicolon from being interpreted as a
-- delimiter); and (c) colons not followed by a space (which may indicate a language prefix).
local function generate_obj_multivalued_annotated_text(text, parse_err, paramname, no_undo_html_entity_replacement)
	local obj = generate_obj_annotated_text(text, parse_err, paramname)
	if not no_undo_html_entity_replacement then
		obj.text = undo_html_entity_replacement(obj.text)
		obj.link = undo_html_entity_replacement(obj.link)
	end
	return obj
end

--[=[
Similar to parse_annotated_text() but the parameter value may contain multiple semicolon-separated entities, each with
their own inline modifiers. Some examples:
* mainauthor=Paula Pattengale; Terea Sonsthagen
* author=Katie Brick; J. Cody Nielsen; Greg Jao; Eric Paul Rogers; John A. Monson
* author=Suzanne Brockmann; Patrick G. Lawlor (Patrick Girard); Melanie Ewbank
* author=G Ristori; et al.
* author=Jason Scott; zh:王晰宁<t:Wang Xining>
* editors=zh:包文俊; zh:金心雯
* quotee=zh:張福運<t:Chang Fu-yun>; zh:張景文<t:Chang Ching-wen>

There may be embedded semicolons within brackets, braces or parens that should not be treated as delimiters, e.g.:
* author=Oliver Optic [pseudonym; {{w|William Taylor Adams}}]
* author=author=Shannon Drake (pen name; {{w|Heather Graham Pozzessere}})
* author=James (the Elder;) Humphrys

There may also be HTML entities with semicolons in them:
* author=&#91;{{w|Gilbert Clerke}}&#93;
* 2ndauthor=Martin Biddle &amp; Sally Badham
* author=Peter Christen Asbj&oslash;rnsen

There may be both embedded semicolons and HTML entities with semicolons in them:
* author=&#91;{{w|Voltaire}} [pseudonym; François-Marie Arouet]&#93;

In general we want to treat &#91; like an opening bracket and &#93; like a closing bracket. Beware that they may be
mismatched:
* author=Anonymous &#91;{{w|Karl Maria Kertbeny}}]

Here, `val` is the value of the parameter and `fullname` is the name of the parameter from which the value was
retrieved. `explicit_gloss`, if specified and non-nil, overrides any gloss specified using the <t:...> or <gloss:...>
inline modifier, and `explicit_gloss_fullname` is the name of the parameter from which this value was retrieved. (If
`explicit_gloss` is specified and multiple values were seen, an error results.)

Return value is a list of objects of the same sort as returned by parse_annotated_text().
]=]
local function parse_multivalued_annotated_text(val, fullname, explicit_gloss, explicit_gloss_fullname)
	if not val then
		return nil
	end
	-- NOTE: In the code that follows, we use `entity` most of the time to refer to one of the semicolon-separated
	-- values in the multivalued param. Entities are most commonly people (typically authors, editors, translators or
	-- the like), but may be the names of publishers, locations, or other entities. "Entity" can also refer to HTML
	-- entities; in the places where this occurs, the variable name contains 'html' in it.
	local splitchar, english_delim
	if val:find("^,") then
		splitchar = ","
		english_delim = "comma"
		val = val:gsub("^,", "")
	else
		splitchar = ";"
		english_delim = "semicolon"
	end

	-- Optimization #1: No semicolons/commas or angle brackets (indicating inline modifiers).
	if not val:find("[<" .. splitchar .. "]") then
		if val_should_not_be_parsed_for_annotations(val) then
			return {{text = val, link = val, noscript = true}}
		else
			return {generate_obj_multivalued_annotated_text(val, nil, fullname, "no undo html entity replacement")}
		end
	end

	-- Optimization #2: Semicolons/commas but no angle brackets (indicating inline modifiers), braces, brackets, or
	-- parens (any of which would protect the semicolon/comma from interpretation as a delimiter), and no ampersand
	-- (which might indicate an HTML entity with a terminating semicolon, which should not be interpreted as a
	-- delimiter).
	if not val:find("[<>%[%](){}&]") then
		local entity_objs = {}
		for entity in gsplit(val, "%s*" .. splitchar .. "%s*") do
			if val_should_not_be_parsed_for_annotations(entity) then
				insert(entity_objs, {
					text = entity,
					link = entity,
					noscript = true
				})
			else
				insert(entity_objs, generate_obj_multivalued_annotated_text(entity, nil, fullname, "no undo html entity replacement"))
			end
		end
		return entity_objs
	end

	-- Escape HTML entities, and get rid of directionality markers.
	local amp = val:find("&", nil, true)
	if amp then
		-- The pattern is more permissive than the usual entity pattern, as MediaWiki has some nonstandard entities
		-- that have non-ASCII characters in their codes.
		val = val:gsub("((&(#?)(([xX]?)([%w\128-\255]+)));)", html_entity_replacement)
	end
	-- Pattern covers left-to-right (U+200E) and right-to-left (U+200F).
	val = val:gsub("\226\128[\142\143]", "")

	-- Parse balanced segment runs, treating HTML entities for left and right bracket and left and right angle bracket
	-- as matching literal versions of the same characters.
	local entity_runs = parse_multi_delimiter_balanced_segment_run(
		val,
		{{"[" .. TEMP_LBRAC, "]" .. TEMP_RBRAC}, {"(", ")"}, {"{", "}"}, {"<" .. TEMP_LT, ">" .. TEMP_GT}},
		true
	)
	if type(entity_runs) == "string" then
		local undo_val = undo_html_entity_replacement(val)
		-- Parse error due to unbalanced delimiters. Don't throw an error here; instead, don't attempt to parse off
		-- any annotations, but return the value directly, maybe allowing script tagging (not allowing it if it appears
		-- the text is already script-tagged).
		return {{text = undo_val, link = undo_val, noscript = not not val_should_not_be_parsed_for_annotations(val)}}
	end

	-- Split on semicolon (or comma), possibly surrounded by whitespace.
	local separated_groups = split_alternating_runs(entity_runs, "%s*" .. splitchar .. "%s*")

	-- Process each value.
	local entity_objs = {}
	for _, entity_group in ipairs(separated_groups) do
		-- Rejoin runs that don't involve <...>.
		local j = 2
		while j <= #entity_group do
			if not entity_group[j]:find("^<.*>$") then
				entity_group[j - 1] = entity_group[j - 1] .. entity_group[j] .. entity_group[j + 1]
				remove(entity_group, j)
				remove(entity_group, j)
			else
				j = j + 2
			end
		end

		local oneval = undo_html_entity_replacement(concat(entity_group))
		-- When checking for inline modifiers, exclude HTML entry with <span ...>, <i ...>, <br/> or similar in it,
		-- caused by wrapping an argument in {{l|...}}, {{lang|...}} or similar. Also exclude URL's from being parsed
		-- as having language code prefixes. This works analogously to parse_annotated_text(); see there for more.
		if val_should_not_be_parsed_for_annotations(oneval) then
			insert(entity_objs, {
				text = oneval,
				link = oneval,
				noscript = true
			})
		else
			local obj
			if #entity_group > 1 then
				-- Check for inline modifier.
				obj = parse_inline_modifiers_from_segments({
					group = entity_group,
					arg = oneval,
					props = {
						paramname = fullname,
						param_mods = param_mods,
						generate_obj = generate_obj_multivalued_annotated_text,
					},
				})
			else
				obj = generate_obj_multivalued_annotated_text(entity_group[1], nil, fullname)
			end
			insert(entity_objs, obj)
		end
	end

	if explicit_gloss then
		if #entity_objs > 1 then
			error(
				(
					"Can't specify |%s= along with multiple %s-separated entities in |%s=; use the <t:...> "
					.. "inline modifier attached to the individual entities"
				):format(explicit_gloss_fullname, english_delim, fullname)
			)
		end
		entity_objs[1].gloss = explicit_gloss
	end

	return entity_objs
end

--[=[
Format a text property that may be in a foreign language or script, along with annotations. This is conceptually
similar to the full_link() function in [[Module:links]], but displays the annotations in a different format that is
more appropriate for bibliographic entries. The output looks like this:

TEXT [TRANSLIT /TRANSCRIPTION/, GLOSS]

`textobj` is as returned by parse_annotated_text(). `tag_text_func`, if supplied, is a function of one argument to further
wrap the text after it has been processed and CSS-tagged appropriately, directly before insertion. `tag_gloss_func` is a
similar function for the gloss.
]=]
local function format_annotated_text(textobj, tag_text_func, tag_gloss_func)
	if not textobj then
		return nil
	end
	local text, link = textobj.text, textobj.link
	local subst, tr, ts, f, gloss = textobj.subst, textobj.tr, textobj.ts, textobj.f, textobj.gloss
	-- Retrieve the display text, either specified by the user (.alt) or by parse_annotated_text() (.display) when a
	-- Wikipedia link is given.
	local alt = textobj.alt or textobj.display

	if alt then
		if link:find("%[%[") or link:find("%]%]") then
			local errmsg = ("Can't currently handle embedded links in '%s', with <alt:...> text '%s'"):format(link, alt)
			error(escape_wikicode(errmsg))
		end
		text = ("[[%s|%s]]"):format(link, alt)
	end

	-- See above for `noscript`, meaning HTML was found in the text value, probably generated using {{lang|...}}.
	-- {{lang}} already script-tags the text and processes embedded language links, so we don't want to do it again (in
	-- fact, the code below within the if-clause is similar to what {{lang}} does). In such a case, an explicit language
	-- won't be available and find_best_script_without_lang() may not be accurate, so we can't do automatic transliteration.
	if not textobj.noscript then
		local lang = textobj.lang
		-- As an optimization, don't do script detection on an argument that contains only ASCII.
		local sc = textobj.sc
			or lang and lang:findBestScript(text)
			or not text:find("^[ -~]$") and find_best_script_without_lang(text)
			or nil
		-- As an optimization, don't do any of the following if there's no language, script, translit or transcription,
		-- as will be the case with simple ASCII values.
		if lang or sc or tr or ts then
			if not lang then
				lang = get_lang("und")
			end

			if tr == "-" then
				tr = nil
			elseif not tr and sc and not sc:getCode():find("Lat") then -- Latn, Latf, Latg, pjt-Latn
				-- might return nil
				local text_for_tr = text
				if subst then
					text_for_tr = apply_subst(text_for_tr, subst)
				else
					text_for_tr = remove_links(text)
				end

				tr = (lang:transliterate(text_for_tr, sc))
			end

			if text:find("%[%[") then
				-- FIXME: embedded_language_links() replaces % signs with their URL-encoded equivalents,
				-- which messes up URL's that may be present (e.g. if chapterurl= is given). IMO this
				-- should not happen, and embedded_language_links() should do nothing if no embedded links
				-- are present. To work around this, only call embedded_language_links() when there are
				-- embedded links present.
				text = embedded_language_links({
					term = text,
					lang = lang,
					sc = sc,
				})
			end
			if lang:getCode() ~= "und" or sc and sc:getCode() ~= "Latn" then
				text = tag_text(text, lang, sc)
			end

			if tr then
				-- Should we link to the transliteration of languages with lang:link_tr()? Probably not because `text` is not
				-- likely to be a term that has an entry.
				tr = tag_translit(tr, lang, "usex")
			end
			if ts then
				ts = tag_transcription(ts, lang, "usex")
			end
		end
	end

	text = unitalicize_brackets(text)
	if tag_text_func then
		text = tag_text_func(text)
	end

	local parts = {}

	if textobj.q then
		insert(parts, format_qualifier(textobj.q) .. " ")
	end

	insert(parts, text)

	if tr or ts or f or gloss then
		insert(parts, SPACE_LBRAC)
		local subparts = {}
		if tr or ts then
			local tr_ts
			if ts then
				ts = "/" .. ts .. "/"
			end
			if tr and ts then
				tr_ts = tr .. " " .. ts
			else
				tr_ts = tr or ts
			end
			insert(subparts, tr_ts)
		end
		if f then
			for _, ff in ipairs(f) do
				local sc = ff.sc
				local lang
				if not sc and ff.quals then
					local qual = ff.quals[1]
					if type(qual) == "string" then
						-- do nothing; we'll do script detection farther down
					elseif qual:hasType("script") then
						sc = qual
					else -- language
						sc = qual:findBestScript(ff.val)
						lang = qual
					end
				end
				if not lang then
					lang = get_lang("und")
				end
				sc = sc or find_best_script_without_lang(ff.val)
				local val = embedded_language_links({
					term = ff.val,
					lang = lang,
					sc = sc,
				})
				if lang:getCode() ~= "und" or sc:getCode() ~= "Latn" then
					val = tag_text(val, lang, sc)
				end
				local qual_prefix
				if ff.quals then
					for i, qual in ipairs(ff.quals) do
						if type(qual) ~= "string" and (qual:hasType("script") or qual:hasType("language")) then
							ff.quals[i] = qual:getCanonicalName()
						end
					end
					qual_prefix = concat(ff.quals, "/") .. ": "
				else
					qual_prefix = ""
				end
				insert(subparts, qual_prefix .. val)
			end
		end
		if gloss then
			gloss = '<span class="e-translation">' .. gloss .. "</span>"
			gloss = unitalicize_brackets(gloss)
			if tag_gloss_func then
				gloss = tag_gloss_func(gloss)
			end
			insert(subparts, gloss)
		end
		insert(parts, concat(subparts, ", "))
		insert(parts, RBRAC)
	end

	if textobj.qq then
		insert(parts, " " .. format_qualifier(textobj.qq))
	end

	return concat(parts)
end

--[=[
Format a multivalued text property that may be in a foreign language or script, along with annotations. This is the
multivalued analog to format_annotated_text(), and formats each individual entity using format_annotated_text(),
joining the results with `delimiter`, which defaults to ", ". It `delimiter` is "and" or "or", join the results using
serial_comma_join() with the specified conjunction.

`textobjs` is as returned by parse_multivalued_annotated_text(). `tag_text_func` and `tag_gloss_func` are as in
format_annotated_text().
]=]
local function format_multivalued_annotated_text(textobjs, delimiter, tag_text_func, tag_gloss_func)
	if not textobjs then
		return nil
	end
	if #textobjs == 1 then
		return format_annotated_text(textobjs[1], tag_text_func, tag_gloss_func)
	end
	local parts = {}
	for _, textobj in ipairs(textobjs) do
		insert(parts, format_annotated_text(textobj, tag_text_func, tag_gloss_func))
	end

	-- Change delimiter to semicolon if the items themselves contain commas (e.g., in ", Jr.")
	local use_semicolon = false
	for _, obj in ipairs(textobjs) do
		-- Use remove_links to ignore commas in links
		if obj.text and remove_links(obj.text):find(", ") then
			use_semicolon = true
			break
		end
	end

	local n = #parts
	if n > 0 and parts[n]:match("^'*et al[.']*$") then
		-- Special handling for 'et al.'
		parts[n] = "''et al.''"
		if n == 2 then
			-- author et al.
			return concat(parts, " ")
		else
			-- author 1, author 2, et al.
			return concat(parts, (use_semicolon and "; ") or ", ")
		end
	end
	if delimiter == "and" or delimiter == "or" then
		return serial_comma_join(parts, {conj = delimiter})
	end
	return concat(parts, delimiter or ((use_semicolon and "; ") or ", "))
end

-- Fancy version of ine() (if-not-empty). Converts empty string to nil, but also strips leading/trailing space.
local function ine(arg)
	if not arg then
		return nil
	elseif type(arg) ~= "string" then
		return arg
	end
	arg = mw.text.trim(arg)
	if arg == "" then
		return nil
	end
	return arg
end

local abbrs = {
	["a."] = {anchor = "a.", full = "ante"},
	["c."] = {anchor = "c.", full = "circa"},
	["p."] = {anchor = "p.", full = "post"},
}

-- Process prefixes 'a.' (ante), 'c.' (circa) and 'p.' (post) at the beginning of an arbitrary date or year spec.
-- Returns two values, the formatted version of the prefix and the date spec minus the prefix. If no prefix is found,
-- returns an empty string and the full date.
local function process_ante_circa_post(date)
	local prefix = usub(date, 1, 2)
	local abbr = abbrs[prefix]
	local abbr_prefix = ""

	if abbr then
		abbr_prefix = "''[[Appendix:Glossary#"
			.. abbr.anchor
			.. '|<abbr title="'
			.. abbr.full
			.. '">'
			.. abbr.anchor
			.. "</abbr>]]'' "
		-- Remove lowercase letter, period, and space from beginning of date parameter.
		date = ugsub(date, "^%l%.%s*", "")
	end

	return abbr_prefix, date
end

-- Format the arguments that specify the date of the quotation. These include the following:
-- |date=: The date. If |start_date= is given, this is the end date.
-- |year=, |month=: Year and month of quotation date or end of range, if |date= isn't given.
-- |start_date=: The start date, to specify a range.
-- |start_year=, |start_month=: Year and month of start of range, if |start_date= isn't given.
-- |accessdate=: Date a website was accessed; processed if no other date was given.
-- |nodate=: Indicate that no date is present; otherwise a maintenance line will be displayed if there is no date.
--
-- If `parampref` and/or `paramsuf` are given, this modifies all the date arguments accordingly. For example, if
-- `parampref` == "orig" and `paramsuf` is omitted, the date is specified using |origdate= or |origyear=/|origmonth=,
-- and the start of the range is |origstart_date=, etc. Similarly, if `parampref` is omitted and `paramsuf` is
-- "_published", the date is specified using |date_published= or |year_published=/|month_published=, and the start of
-- the range is |start_date_published=, etc.
--
-- `a` and `get_full_paramname` are functions with the same interpretation as the local functions of the same name in
-- source(). These are used to fetch parameters and get their full names. Note that this may cause all arguments to
-- have an index added to them (|date2=, |year2=, |month2=, etc.).
--
-- `alias_map` is as in source() and is used to map canonical arguments to their aliases when aliases were used.
--
-- If `bold_year` is given, displayed years are boldfaced unless boldface is present in the parameter value.
--
-- If `maintenance_line_no_date` is specified, it should be a string that will be returned if no date is found (i.e.
-- neither |date= nor |year=, or their appropriate equivalents per `parampref` and `paramsuf`, are specified, and
-- neither |nodate= is given to indicate that there is no date, or |accessdate= is given).
--
-- Returns two values: the formatted date and a boolean indicating whether to add a maintenance category
-- [[:Category:Requests for date in LANG entries]]. The first return value will be nil if nothing is to be added
-- (in which case the second return value will always be nil).
local function format_date_args(data)
	local a, get_full_paramname, alias_map, parampref, paramsuf, bold_year, maintenance_line_no_date, year_last =
		data.a, data.get_full_paramname, data.alias_map, data.parampref, data.paramsuf, data.bold_year,
		data.maintenance_line_no_date, data.year_last
	local output = {}

	parampref = parampref or ""
	paramsuf = paramsuf or ""
	local function getp(param)
		return a(parampref .. param .. paramsuf)
	end
	local function pname(param)
		local fullname = get_full_paramname(parampref .. param .. paramsuf)
		return alias_map[fullname] or fullname
	end

	-- Format `timestamp` (a timestamp referencing a date) according to the spec in `code`. `param` is the base name of
	-- the parameter from which the timestamp was fetched, for error messages.
	local function format_date_with_code(code, timestamp, param)
		local language = mw.getContentLanguage()
		local ok, date = pcall(language.formatDate, language, code, timestamp)
		if ok then
			return date
		else
			-- All the formats used in format_date_args() are fine, so the timestamp must be at fault.
			error(
				(
					"Timestamp |%s=%s (possibly canonicalized from its original format) could not be parsed; see the "
					.. "[[mw:Help:Extension:ParserFunctions##time|documentation for the #time parser function]]"
				):format(pname(param), tostring(timestamp))
			)
		end
	end

	-- Try to figure out if the given timestamp has the day of the month explicitly given. We use the following
	-- algorithm:
	-- 1. Format as year-month-day; if the day is not 1, the day was explicitly given, since if only the year/month are
	--    given, the day shows up as 1.
	-- 2. If the day shows up as 1 and there isn't a 1 or 01 in the timestamp, the day wasn't explicitly given.
	-- 3. Otherwise, if there are three separate numbers (e.g. 2022-07-01), or two separate numbers plus a capitalized
	--    letter (taken as an English month, e.g. 2022 July 1), the day was explicitly given, otherwise not.
	--
	-- `param` is the base name of the parameter from which the timestamp was fetched.
	local function date_has_day_specified(timestamp, param)
		local day = format_date_with_code("j", timestamp, param)
		if day ~= "1" then
			return true
		end
		local english_month = timestamp:find("%u")
		local canon_timestamp = mw.text.trim((timestamp:gsub("%D+", " ")))
		local seen_nums = split(canon_timestamp, " ", true)
		local saw_one = false
		for _, num in ipairs(seen_nums) do
			if num == "1" or num == "01" then
				saw_one = true
				break
			end
		end
		if not saw_one then
			return false
		end
		return #seen_nums >= 3 or english_month and #seen_nums >= 2
	end

	-- Format a date with boldfaced year, as e.g. '''2023''' August 3. `explicit_day_given` indicates whether to include
	-- the day; if false, the return value will be e.g. '''2023''' August. `date_param` is the base name of the param
	-- from which the date was fetched, for error messages.
	local function format_bold_date(date, explicit_day_given, date_param)
		local day_month_code = explicit_day_given and "j F" or "F"
		local month_day_code = explicit_day_given and "F j" or "F"
		if year_last then
			if bold_year then
				-- This formats like "3 August '''2023'''" (or "August '''2023'''" if day not explicitly given).
				return format_date_with_code(day_month_code .. " '''Y'''", date, date_param)
			else
				-- This formats like "3 August 2023" (or "August 2023" if day not explicitly given).
				return format_date_with_code(day_month_code .. " Y", date, date_param)
			end
		else
			if bold_year then
				-- This formats like "'''2023''' August 3" (or "'''2023''' August" if day not explicitly given).
				return format_date_with_code("'''Y''' " .. month_day_code, date, date_param)
			else
				-- This formats like "2023 August 3" (or "2023 August" if day not explicitly given).
				return format_date_with_code("Y " .. month_day_code, date, date_param)
			end
		end
	end

	-- The formatDate method of the mw.language object behaves like the {{#time:}} parser function, which doesn't
	-- accept the formats "monthday monthname, year" or "year monthname monthday", but outputs garbage when it receives
	-- them, behavior inherited from PHP. {{#formatdate:}} magic word is more forgiving. Fix dates so that, for
	-- instance, the |date= parameter of {{quote-journal}} (which uses this code) and the |accessdate= parameter (which
	-- uses {{#formatdate:}}) accept similar date formats. See:
	-- * [[mw:Extension:Scribunto/Lua_reference_manual#mw.language:formatDate]]
	-- * [[mw:Help:Extension:ParserFunctions##time]]
	-- * [[mw:Help:Magic_words#Formatting]]
	-- `date` is the date spec from the user, which is assumed to come from a parameter whose base name ends in "date";
	-- `parampref` is the prefix added to "date" to get the parameter name.
	local function fix_date(date, param_pref)
		if tonumber(date) ~= nil then
			error(
				("|%s= should contain a full date (year, month, day of month); use |%s= for year"):format(
					pname(param_pref .. "date"),
					pname(param_pref .. "year")
				)
			)
		elseif date and date:find("%s*%a+,%s*%d+%s*$") then
			error(
				("|%s= should contain a full date (year, month, day of month); use |%s=, |%s= for month and year"):format(
					pname(param_pref .. "date"),
					pname(param_pref .. "month"),
					pname(param_pref .. "year")
				)
			)
		end
		if date then
			-- Commas are replaced with spaces to prevent parsing issues
			local fixed_date = ugsub(date, ", *", " ")
			return (ugsub(ugsub(fixed_date or date, "(%d+ %a+),", "%1"), "^(%d%d%d%d) (%a+ %d%d?)$", "%2 %1"))
		end
	end

	local start_date, date = fix_date(getp("start_date"), "start_"), fix_date(getp("date"), "")
	local year = getp("year")
	local month = getp("month")
	local start_year = getp("start_year")
	local start_month = getp("start_month")

	if date and year then
		error(("Only one of |%s= or |%s= should be specified"):format(pname("date"), pname("year")))
	end
	if date and month then
		error(
			("|%s= should only be specified in conjunction with |%s=, not with |%s="):format(
				pname("month"),
				pname("year"),
				pname("date")
			)
		)
	end
	if start_date and start_year then
		error(("Only one of |%s= or |%s= should be specified"):format(pname("start_date"), pname("start_year")))
	end
	if start_date and start_month then
		error(
			("|%s= should only be specified in conjunction with |%s=, not with |%s="):format(
				pname("start_month"),
				pname("start_year"),
				pname("start_date")
			)
		)
	end
	if (start_date or start_year) and not (date or year) then
		error(
			("|%s= or |%s=/|%s= cannot be specified without specifying |%s= or |%s=/|%s="):format(
				pname("start_date"),
				pname("start_year"),
				pname("start_month"),
				pname("date"),
				pname("year"),
				pname("month")
			)
		)
	end

	local dash = "&nbsp;– "

	local day_explicitly_given = date and date_has_day_specified(date, "date")
	local start_day_explicitly_given = start_date and date_has_day_specified(start_date, "start_date")

	-- Format a date with boldfaced year, as e.g. '''2023''' August 3 (if `explicit_day_given` specified) or
	-- '''2023''' August (if `explicit_day_given` not specified). If no date specified, fall back to formatting based
	-- on the year and (optionally) month params given in `yearobj` and `monthobj`, boldfacing the year if not already.
	-- `date_param` is the base name of the param from which the date was fetched, for error messages.
	local function format_date_or_year_month(date, yearobj, monthobj, explicit_day_given, date_param)
		if date then
			return format_bold_date(date, explicit_day_given, date_param)
		else
			-- Boldface a year spec if it's not already boldface.
			if bold_year and not yearobj.text:find("'''") then
				-- Clone the year object before modifying it because we may use it later to check against the current
				-- year (if we're dealing with start_year).
				yearobj = shallow_copy(yearobj)
				yearobj.text = "'''" .. yearobj.text .. "'''"
				if yearobj.alt then
					yearobj.alt = "'''" .. yearobj.alt .. "'''"
				end
			end
			if year_last then
				return (monthobj and format_annotated_text(monthobj) .. " " or "") .. format_annotated_text(yearobj)
			else
				return format_annotated_text(yearobj) .. (monthobj and " " .. format_annotated_text(monthobj) or "")
			end
		end
	end

	local yearobj = parse_annotated_text(year, pname("year"))
	local monthobj = parse_annotated_text(month, pname("month"))
	local start_yearobj = parse_annotated_text(start_year, pname("start_year"))
	local start_monthobj = parse_annotated_text(start_month, pname("start_month"))

	if start_yearobj then
		local abbr_prefix
		abbr_prefix, start_yearobj.text = process_ante_circa_post(start_yearobj.text)
		start_yearobj.link = select(2, process_ante_circa_post(start_yearobj.link))
		insert(output, abbr_prefix)
	elseif yearobj then
		local abbr_prefix
		abbr_prefix, yearobj.text = process_ante_circa_post(yearobj.text)
		yearobj.link = select(2, process_ante_circa_post(yearobj.link))
		insert(output, abbr_prefix)
	end

	if start_date or start_year then
		local cur_year = yearobj and yearobj.text or format_date_with_code("Y", date, "date")
		local cur_month = monthobj and monthobj.text or date and format_date_with_code("F", date, "date") or nil
		local cur_day = date and day_explicitly_given and format_date_with_code("j", date, "date") or nil
		local beg_year = start_yearobj and start_yearobj.text or format_date_with_code("Y", start_date, "start_date")
		local beg_month = start_monthobj and start_monthobj.text
			or start_date and format_date_with_code("F", start_date, "start_date")
			or nil
		local beg_day = start_date
				and start_day_explicitly_given
				and format_date_with_code("j", start_date, "start_date")
			or nil

		if year_last then
			if beg_day then
				insert(output, beg_day .. " " .. beg_month)
			else
				insert(output, beg_month)
			end
			if beg_year ~= cur_year then
            	insert(output, " " .. beg_year)
            end
		else
			insert(output, format_date_or_year_month(
				start_date,
				start_yearobj,
				start_monthobj,
				start_day_explicitly_given,
				"start_date"
			))
		end

	    if cur_year ~= beg_year then
			-- Different years; insert current date in full.
			if beg_month or cur_month then
				insert(output, dash)
			else
	            insert(output, "–")
	        end
	        insert(output, format_date_or_year_month(date, yearobj, monthobj, day_explicitly_given, "date"))
		elseif cur_month and cur_month ~= beg_month then
			local month_ins = monthobj and format_annotated_text(monthobj) or cur_month
			-- Same year but different months; insert current month and (if available) current day.
			if cur_day then
				insert(output, dash)
				if year_last then
					insert(output, cur_day .. " " .. month_ins)
				else
					insert(output, month_ins .. " " .. cur_day)
				end
			else
				if beg_day then
					insert(output, dash)
				else
					insert(output, "–")
				end
				insert(output, month_ins)
			end
		elseif cur_day and cur_day ~= beg_day then
			-- Same year and month but different days; insert current day.
			insert(output, "–")
			insert(output, cur_day)
		else
			-- Same year, month and day; or same year and month, and day not available; or same year, and month and
			-- day not available. Do nothing. FIXME: Should we throw an error?
		end
		if year_last and beg_year == cur_year then
        	if cur_month then
        		insert(output, " " .. cur_year)
        	else
            	insert(output, " " .. cur_year)
        	end
        end
	elseif date or yearobj then
		insert(output, format_date_or_year_month(date, yearobj, monthobj, day_explicitly_given, "date"))
	elseif not maintenance_line_no_date then
		-- Not main quote date. Return nil, caller will handle.
		return nil, nil
	elseif not getp("nodate") then
		local accessdate = getp("accessdate")
		if accessdate then
			local explicit_day_given = date_has_day_specified(accessdate, "accessdate")
			insert(output, format_bold_date(accessdate, explicit_day_given, "accessdate") .. " (last accessed)")
		else
			if mw.title.getCurrentTitle().namespace ~= 10 then
				return maintenance_line(maintenance_line_no_date), true
			end
			return nil, nil
		end
	end

	return ine(concat(output)), nil
end

local function tag_with_cite(txt)
	return "<cite>" .. txt .. "</cite>"
end

--[==[
Display the source line of the quote, above the actual quote text. This contains the majority of the logic of this
module (formerly contained in {{tl|quote-meta/source}}).
]==]
function export.source(args, alias_map, format_as_cite, other_controls)
	local tracking_categories = {}

	local argslang = args[1] or args.lang
	if not argslang then
		-- For the moment, only trigger an error on mainspace pages and
		-- other pages that are not user pages or pages containing discussions.
		-- These are the same pages that appear in the appropriate tracking
		-- categories. User and discussion pages have not generally been
		-- fixed up to include a language code and so it's more helpful
		-- to use a maintenance line than signal an error.
		local current_title = mw.title.getCurrentTitle()
		if not (current_title.namespace == 10 or page_should_be_ignored(current_title.fullText)) then
			require(languages_error_module)(nil, 1)
		end
	end

	-- Given a canonical param, convert it to the original parameter specified by the user (which may have been an
	-- alias).
	local function alias(param)
		return alias_map[param] or param
	end

	local output = {}
	local sep
	local overrides = other_controls and other_controls.overrides or {}

	-- Add text to the output. The text goes into a list, and we concatenate all the list components together at the
	-- end. To make it easier to handle comma-separated items, we keep track (in `sep`) of the separator (if any) that
	-- needs to be inserted before the next item added. For example, if we're in the "newversion" code (ind ~= ""), and
	-- there's no title and no URL, then the first time we add anything after the title, we don't want to add a
	-- separating comma because the preceding text will say "republished " or "republished as " or "translated as " or
	-- similar. In all- other cases, we do want to add a separating comma. The bare add() function reset the separator
	-- to be nothing, while the add_with_sep() function resets the separator to be the value of `next_sep` (defaulting
	-- to ", "), so the next time around we do add a comma to separate `text` from the preceding piece of text.
	local function add(text)
		if sep then
			insert(output, sep)
		end
		insert(output, text)
		sep = nil
	end
	local function add_with_sep(text, next_sep)
		add(text)
		sep = next_sep or ", "
	end

	-- FIXME: This is all very over-engineered, which makes it slow and memory-inefficient.

	-- Return a function that generates the actual parameter name associated with a base param (e.g. "author", "last").
	-- The actual parameter name may have an index added (an empty string for the first set of params, e.g. author=,
	-- last=, or a numeric index for further sets of params, e.g. author2=, last2=, etc.).
	local function make_get_full_paramname(ind)
		return function(param)
			return param .. ind
		end
	end
	-- Function to fetch the actual parameter name associated with a base param (see make_get_full_paramname() above).
	-- Assigned at various times below by calling make_get_full_paramname(). We do it this way so that we can have
	-- wrapper functions that access params and define them only once.
	local get_full_paramname
	-- Return two values: the value of a parameter given the base param name (which may have a numeric index added),
	-- and the parameter name from which the value was fetched (which may be an alias, i.e. you can't necessarily fetch
	-- the parameter value from args[] given this name). The base parameter can be a list of such base params, which
	-- are checked in turn, or nil, in which case nil is returned.
	local function a_with_name(param)
		if not param then
			return nil
		elseif type(param) ~= "table" then
			local fullname = get_full_paramname(param)
			return args[fullname], alias(fullname)
		end
		for _, par in ipairs(param) do
			local val, fullname = a_with_name(par)
			if val then
				return val, alias(fullname)
			end
		end
		return nil
	end
	-- Fetch the value of a parameter given the base param name (which may have a numeric index added). The base
	-- parameter can be a list of such base params, which are checked in turn, or nil, in which case nil is returned.
	local function a(param)
		return (a_with_name(param))
	end

	-- Identical to a_with_name(param) except that it verifies that no space is present. Should be used for URL's.
	local function aurl_with_name(param)
		local value, fullname = a_with_name(param)
		if value and value:find(" ") and not value:find("%[") then
			error(("URL not allowed to contain a space, but saw |%s=%s"):format(fullname, value))
		end
		return value, fullname
	end
	-- Identical to a(param) except that it verifies that no space is present. Should be used for URL's.
	local function aurl(param)
		return (aurl_with_name(param))
	end

	-- Convenience function to fetch a parameter that may be in a foreign language or text (and may consequently have
	-- a language prefix and/or inline modifiers), parse the annotations and convert the result into a formatted string.
	-- This is the same as parse_and_format_annotated_text() below but also returns the full param name as the second
	-- return value.
	local function parse_and_format_annotated_text_with_name(param, tag_text_func, tag_gloss_func)
		local val, fullname = a_with_name(param)
		local obj = parse_annotated_text(val, fullname)
		return format_annotated_text(obj, tag_text_func, tag_gloss_func), fullname
	end

	-- Convenience function to fetch a parameter that may be in a foreign language or text (and may consequently have
	-- a language prefix and/or inline modifiers), parse the modifiers and convert the result into a formatted string.
	-- This is a wrapper around parse_annotated_text() and format_annotated_text(). `param` is the base parameter name (see
	-- a_with_name()), `tag_text_func` is an optional function to tag the parameter text after all other processing (e.g.
	-- wrap in <cite>...</cite> tags), and `tag_gloss_func` is a similar function for the parameter translation/gloss.
	local function parse_and_format_annotated_text(param, tag_text_func, tag_gloss_func)
		return (parse_and_format_annotated_text_with_name(param, tag_text_func, tag_gloss_func))
	end

	-- Convenience function to fetch a multivalued parameter that may be in a foreign language or text (and may
	-- consequently have a language prefix and/or inline modifiers), parse the modifiers and convert the result into a
	-- formatted string. This is the multivalued analog to parse_and_format_annotated_text_with_name() and returns two
	-- values, the formatted string and the full name of the parameter fetched. `delimiter` is as in
	-- format_multivalued_annotated_text().
	local function parse_and_format_multivalued_annotated_text_with_name(param, delimiter, tag_text_func, tag_gloss_func)
		local val, fullname = a_with_name(param)
		local objs = parse_multivalued_annotated_text(val, fullname)
		local num_objs = objs and #objs or 0
		return format_multivalued_annotated_text(objs, delimiter, tag_text_func, tag_gloss_func), fullname, num_objs
	end

	-- Convenience function to fetch a multivalued parameter that may be in a foreign language or text (and may
	-- consequently have a language prefix and/or inline modifiers), parse the modifiers and convert the result into a
	-- formatted string. This is the multivalued analog to parse_and_format_annotated_text(). `delimiter` is as in
	-- format_multivalued_annotated_text().
	local function parse_and_format_multivalued_annotated_text(param, delimiter, tag_text_func, tag_gloss_func)
		return (parse_and_format_multivalued_annotated_text_with_name(param, delimiter, tag_text_func, tag_gloss_func))
	end

	-- This determines whether to display "Mary Bloggs, transl." (if there's no author preceding) or "translated by
	-- Mary Bloggs" (if there's an author preceding).
	local author_outputted = false

	-- When formatting as a citation, the priority is to display a name and a date before the book/chapter title
	-- this tracks whether or not the author/date has been displayed
	local date_outputted = false
	local formatted_date, formatted_origdate, need_date
	local function add_date(no_paren)
		if not date_outputted then
			if no_paren then
				sep = ", "
			else
				sep = " "
			end
			if formatted_date then
				if no_paren then
					add(formatted_date)
				else
					add("(" .. formatted_date .. ")")
				end
			end
			if formatted_origdate then
				add(SPACE_LBRAC .. formatted_origdate .. RBRAC)
			end
			sep = ", "
			date_outputted = true
		end
	end

	local function is_anonymous(val)
		return val:match("^[Aa]nonymous$") or val:match("^[Aa]non%.?$")
	end

	-- Add a formatted author (whose values may be specified using `author` or, for compatibility purposes, split
	-- among various parameters):
	-- * `author` is the value of the author param (e.g. "author", "author2" or "2ndauthor"), and `author_fullname` is
	--   the full parameter name holding that value;
	-- * `trans_author` is the optional value of the param holding the gloss/translation of the author, and
	--   `trans_author_fullname` is the full parameter name holding that value (or nil for no such parameter);
	-- * `authorlink` is the value of the authorlink param, which holds the Wikipedia link of the author(s) in `author`,
	--    and `authorlink_fullname` is the full parameter name holding that value;
	-- * `trans_authorlink` is the optional value of the param holding the Wikipedia link of the gloss/translation of
	--    the author, and `trans_authorlink_fullname` is the full parameter name holding that value (or nil for no such
	--    parameter);
	-- * `first` is the value of the parameter holding the first name of the author, and `first_fullname` is the full
	--    parameter name holding that value;
	-- * `trans_first` is the value of the corresponding parameter holding the gloss/translation of the first name
	--    (e.g. "trans-first"), and `trans_first_fullname` is the full parameter name holding that value (or nil for
	--    no such parameter);
	-- * `last` is the value of the parameter holding the last name of the author, and `last_fullname` is the full
	--    parameter name holding that value;
	-- * `trans_last` is the value of the corresponding parameter holding the gloss/translation of the last name
	--    (e.g. "trans-last"), and `trans_last_fullname` is the full parameter name holding that value (or nil for
	--    no such parameter).
	-- * `last_first` if set, when parameters `first` and `last` are used, display the author name as "last, first"
	local function add_author(
		author,
		author_fullname,
		trans_author,
		trans_author_fullname,
		authorlink,
		authorlink_fullname,
		trans_authorlink,
		trans_authorlink_fullname,
		first,
		first_fullname,
		trans_first,
		trans_first_fullname,
		last,
		last_fullname,
		trans_last,
		trans_last_fullname,
		last_first
	)
		local function make_author_with_url(txt, txtparam, authorlink, authorlink_param)
			if authorlink then
				if authorlink:find("%[%[") then
					error(("Can't specify links in |%s=%s"):format(authorlink_param, authorlink))
				end
				if txt:find("%[%[") then
					error(("Can't specify links in %s=%s"):format(txtparam, txt))
				end
				return "[[w:" .. authorlink .. "|" .. txt .. "]]"
			else
				return txt
			end
		end

		local num_authorobjs
		if author then
			local authorobjs =
				parse_multivalued_annotated_text(author, author_fullname, trans_author, trans_author_fullname)
			-- parse_multivalued_annotated_text only returns nil when `author` is nil, which it isn't.
			---@cast authorobjs -nil
			num_authorobjs = #authorobjs
			if num_authorobjs == 1 then
				if is_anonymous(authorobjs[1].text) then
					authorobjs[1].text = "anonymous author"
					authorobjs[1].link = "anonymous author"
				end
				if authorlink then
					authorobjs[1].text = make_author_with_url(
						authorobjs[1].text,
						"|" .. author_fullname,
						authorlink,
						"|" .. authorlink_fullname
					)
					authorobjs[1].link = make_author_with_url(
						authorobjs[1].link,
						"|" .. author_fullname,
						authorlink,
						"|" .. authorlink_fullname
					)
				end
				if authorobjs[1].gloss and trans_authorlink then
					authorobjs[1].gloss = make_author_with_url(
						authorobjs[1].gloss,
						("<t:...> in |%s"):format(author_fullname),
						trans_authorlink,
						"|" .. trans_author_fullname
					)
				end
				add(format_multivalued_annotated_text(authorobjs))
			elseif trans_authorlink then
				error(
					(
						"Can't specify |%s= along with multiple semicolon-separated entities in |%s=; use the "
						.. "<t:...> inline modifier attached to the individual entities and put the link directly "
						.. "in the value of the inline modifier"
					):format(trans_authorlink_fullname, author_fullname)
				)
			else
				-- Allow an authorlink with multiple authors, e.g. for use with |author=Max Mills; Harvey Mills
				-- with |authorlink=Max and Harvey. For this we have to generate the entire text and link it
				-- all.
				local formatted_text = format_multivalued_annotated_text(authorobjs)
				if authorlink then
					formatted_text = make_author_with_url(
						formatted_text,
						"|" .. author_fullname,
						authorlink,
						"|" .. authorlink_fullname
					)
				end
				add(formatted_text)
			end
		else
			num_authorobjs = 1
			-- Author separated into first name + last name. We don't currently support non-Latin-script
			-- authors separated this way and probably never will.
			if first then
				if last_first then
					author = last .. ", " .. first
				else
					author = first .. " " .. last
				end
			else
				author = last
			end
			if authorlink then
				local authorparam = first and ("|%s |%s"):format(first_fullname, last_fullname) or "|" .. last_fullname
				author = make_author_with_url(author, authorparam, authorlink, authorlink_fullname)
			end
			local trans_author
			if trans_last then
				if trans_first then
					trans_author = trans_first .. " " .. trans_last
				else
					trans_author = trans_last
				end
				if trans_authorlink then
					local trans_authorparam = trans_first
							and ("|%s |%s"):format(trans_first_fullname, trans_last_fullname)
						or "|" .. trans_last_fullname
					trans_author = make_author_with_url(
						trans_author,
						trans_authorparam,
						trans_authorlink,
						trans_authorlink_fullname
					)
				end
			end
			add(author)
			if trans_author then
				add(SPACE_LBRAC)
				add(trans_author)
				add(RBRAC)
			end
		end

		author_outputted = true

		return num_authorobjs
	end

	local function add_authorlike(
		param,
		prefix_with_preceding_authors,
		suffix_without_preceding_authors,
		suffix_if_multiple,
		anonymous_suffix
	)
		local delimiter = author_outputted and "and" or ", "
		local entities, _, num_entities = parse_and_format_multivalued_annotated_text_with_name(param, delimiter)
		if not entities then
			return
		end
		if is_anonymous(entities) then
			-- If tlr=anonymous or similar given, display as "anonymous translator" or similar. If a specific
			-- anonymous suffix not given, try to derive the anonymous suffix from the non-preceding-author suffix.
			if not anonymous_suffix then
				local cleaned_suffix = suffix_without_preceding_authors
					:gsub("&#32;", " ")
					:gsub("&nbsp;", " ")
					:gsub("&#160;", " ")
					:gsub("&#91;", "[")
					:gsub("&#93;", "]")
				cleaned_suffix = mw.text.trim(cleaned_suffix)
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^, (.*)$")
				end
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^%((.*)%)$")
				end
				if not anonymous_suffix then
					anonymous_suffix = " " .. cleaned_suffix:match("^%[(.*)%]$")
				end
				if not anonymous_suffix then
					anonymous_suffix = suffix_without_preceding_authors
				end
			end
			add_with_sep("anonymous" .. anonymous_suffix)
		elseif prefix_with_preceding_authors and (author_outputted or not suffix_without_preceding_authors) then
			add_with_sep(prefix_with_preceding_authors .. entities)
		elseif suffix_if_multiple and num_entities > 1 then
			add_with_sep(entities .. suffix_if_multiple)
		else
			add_with_sep(entities .. suffix_without_preceding_authors)
		end
		author_outputted = true
	end

	local function add_authorlabel()
		local default_authorlabel = a("default-authorlabel")
		if default_authorlabel and yesno(a("authorlabel"), true) then
			sep = nil
			add_with_sep(" " .. default_authorlabel)
		end
	end

	local function has_new_title_or_author()
		return args["2ndauthor"]
			or args["2ndlast"]
			or args.chapter2
			or args.title2
			or args.tlr2
			or args.edtlr2
			or args.mainauthor2
			or args.editor2
			or args.editors2
			or args.compiler2
			or args.compilers2
			or args.director2
			or args.directors2
	end

	local function has_newversion()
		return args.newversion or args.location2 or has_new_title_or_author()
	end

	-- Handle chapter=, section=, etc. `param` is the base name of the parameter in question, e.g. "chapter" or
	-- "section". If numeric (either Arabic or Roman), add `numeric_prefix`; otherwise, parse as textual (allowing for
	-- language prefixes, inline modifiers, etc.), prefix with `textual_prefix` (if given) and suffix with
	-- `textual_suffix` (if given). Also checks for and handles the following (assuming param == "chapter"):
	-- * chapterurl=: URL of the chapter.
	-- * trans-chapter=: Chapter translation (can be given using an inline modifier <t:...>).
	-- * chapter_number=: Chapter number, when chapter= is also given (otherwise put the chapter number in chapter=).
	-- * chapter_plain=: Plain version of the chapter number; the "chapter " prefix isn't added.
	-- * chapter_series=: Series that the chapter is within (used e.g. for journal articles part of a series).
	-- * chapter_seriesvolume=: Volume of the series (compare seriesvolume=).
	--
	-- Returns nil if no value specified for the main parameter, otherwise the formatted value.
	local function format_chapterlike(param, numeric_prefix, textual_prefix, textual_suffix)
		local chap, chap_fullname = a_with_name(param)
		local chap_num, chap_num_fullname = a_with_name(param .. "_number")
		local chap_plain, chap_plain_fullname = parse_and_format_annotated_text_with_name(param .. "_plain")
		if chap_num and chap_plain then
			error(("Specify only one of |%s= or %s="):format(chap_num_fullname, chap_plain_fullname))
		end
		local chap_series, chap_series_fullname =
			parse_and_format_annotated_text_with_name(param .. "_series", tag_with_cite, tag_with_cite)
		local chap_seriesvolume, chap_seriesvolume_fullname =
			parse_and_format_annotated_text_with_name(param .. "_seriesvolume")
		if chap_series then
			chap_series = ", " .. chap_series
		end
		if chap_seriesvolume then
			if not chap_series then
				error(("Cannot specify |%s= without %s="):format(chap_series_fullname, chap_seriesvolume_fullname))
			end
			chap_series = chap_series .. " (" .. chap_seriesvolume .. ")"
		end

		local chapterurl
		local function make_chapter_with_url(chap)
			if chapterurl then
				return "[" .. chapterurl .. " " .. chap .. "]"
			else
				return chap
			end
		end

		if not chap then
			if chap_num then
				error(
					("Cannot specify |%s= without |%s=; put the numeric value in |%s= directly"):format(
						chap_num_fullname,
						chap_fullname,
						chap_fullname
					)
				)
			end
			if chap_plain then
				chapterurl = aurl(param .. "url")
				return make_chapter_with_url(chap_plain .. (chap_series or ""))
			end
			return nil
		end

		local cleaned_chap = chap:gsub("<sup>[^<>]*</sup>", ""):gsub("[*+#]", "")
		chapterurl = aurl(param .. "url")

		local formatted

		if numeric_prefix and get_number(cleaned_chap) then
			-- Arabic chapter number
			formatted = numeric_prefix .. make_chapter_with_url(chap)
		elseif
			numeric_prefix
			and cleaned_chap:match("^[mdclxviMDCLXVI]+$")
			and roman_to_arabic(cleaned_chap, true)
			and (not overrides[param] or not overrides[param].noroman)
		then
			-- Roman chapter number
			formatted = numeric_prefix .. make_chapter_with_url(upper(chap))
		else
			-- strip leading ! (used to force text-mode for titles that look like Roman numerals like "mil" and "dill")
			if chap:find("^!") then
				chap = chap:gsub("^!", "")
			end

			-- Must be a chapter name
			local chapterobj = parse_annotated_text(chap, chap_fullname, a("trans-" .. param))
			-- parse_annotated_text only returns nil when `chap` is nil, which it isn't.
			---@cast chapterobj -nil
			chapterobj.text = make_chapter_with_url(chapterobj.text)
			chapterobj.link = make_chapter_with_url(chapterobj.link)
			formatted = (textual_prefix or "") .. format_annotated_text(chapterobj) .. (textual_suffix or "")
		end

		if chap_num or chap_plain then
			-- NOTE: Up above we throw an error if both chap_num and chap_plain are specified.
			formatted = formatted .. " (" .. (chap_plain or numeric_prefix .. chap_num) .. ")"
		end
		if chap_series then
			formatted = formatted .. chap_series
		end

		return formatted
	end

	-- This handles everything after displaying the author, starting with the chapter and ending with page, column,
	-- line and then other=. It is currently called twice: Once to handle the main portion of the citation, and once to
	-- handle a "newversion" citation. `ind` is either "" for the main portion or a number (currently only 2) for a
	-- "newversion" citation. In a few places we conditionalize on `ind` to take actions depending on its value.
	local function postauthor(ind, num_authors, format_as_cite)
		get_full_paramname = make_get_full_paramname(ind)

		if author_outputted then
			add_authorlabel()
		end

		local coauthors = parse_and_format_multivalued_annotated_text("coauthors", "and")
		if coauthors then
			local with_prefix = ""
			if author_outputted then
				with_prefix = "with "
				if num_authors == 1 then
					sep = " "
				end
			end
			add_with_sep(with_prefix .. coauthors)
			author_outputted = true
		end

		add_authorlike("quotee", "quoting ", ", quotee", ", quotees")

		if format_as_cite and author_outputted and not date_outputted then
			add_date()
			sep = ", "
		end

		add_authorlike("chapter_tlr", "translated by ", ", transl.", nil, " translator")
		add_authorlike("chapter_edtlr", "edited and translated by ", ", ed. and transl.", nil, " editor and translator")

		local function add_sg_and_pl_authorlike(noun, verbed)
			local sgparam = noun
			local plparam = noun .. "s"
			local sgval, sgval_fullname = a_with_name(sgparam)
			local plval, plval_fullname = a_with_name(plparam)
			if sgval and plval then
				error(("Can't specify both |%s= and |%s="):format(sgval_fullname, plval_fullname))
			end
			if sgval or plval then
				local verbed_by = verbed .. " by "
				local comma_sgnoun = ", " .. noun
				local comma_plnoun = ", " .. noun .. "s"
				add_authorlike(sgparam, verbed_by, comma_sgnoun, comma_plnoun)
				add_authorlike(plparam, verbed_by, comma_plnoun)
			end
		end

		local formatted_entry = format_chapterlike("entry", nil, "“", "”")
		local formatted_chapter = format_chapterlike("chapter", "chapter ", "“", "”")

		local function add_entry()
			if formatted_entry then
				add_with_sep(formatted_entry)
				if not a("notitle") then
					add("in ")
					author_outputted = false
				else
					author_outputted = true
				end
				formatted_entry = nil
			end
		end

		local function add_chapter()
			add_entry()

			if formatted_chapter then
				add_with_sep(formatted_chapter)
				if not a("notitle") then
					add("in ")
					author_outputted = false
				end
				formatted_chapter = nil
			end
		end

		local function add_actor_role(format_as_cite)
			local role = parse_and_format_multivalued_annotated_text("role", "and")
			local actor_val, actor_fullname = a_with_name("actor")
			local actor_objs = parse_multivalued_annotated_text(actor_val, actor_fullname)
			local actor = format_multivalued_annotated_text(actor_objs, "and")

			if format_as_cite then
				if role then
					if actor then
						add_with_sep(actor .. " as ")
					end
					sep = nil
					add_with_sep(role)
				elseif actor then
					add_with_sep(actor .. " (" .. (#actor_objs > 1 and "actors" or "actor") .. ")")
				end
			else
				if role then
					add_with_sep("spoken by " .. role)
					if actor then
						sep = nil
						add_with_sep(" (" .. actor .. ")")
					end
				elseif actor then
					add_with_sep(actor .. " (" .. (#actor_objs > 1 and "actors" or "actor") .. ")")
				end
			end
		end

		if format_as_cite then
			if date_outputted then
				add_chapter()
			end

			local output_len = #output

			local mainauthor = parse_and_format_multivalued_annotated_text("mainauthor")
			if mainauthor then
				add_with_sep(mainauthor)
			end

			-- quote-* templates display "jobbed by name" after the author, controlled by the author_outputted flag
			author_outputted = false

			add_authorlike("tlr", "translated by ", ", transl.", nil, " translator")
			add_authorlike("edtlr", "edited and translated by ", ", ed. and transl.", nil, " editor and translator")
			author_outputted = false

			add_sg_and_pl_authorlike("editor", "edited")
			add_sg_and_pl_authorlike("compiler", "compiled")
			add_sg_and_pl_authorlike("director", "directed")

			add_authorlike("lyricist", nil, " (lyrics)", nil, " lyricist")
			add_authorlike("lyrics-translator", nil, " (translation)", nil, " lyrics translator")
			add_authorlike("composer", nil, " (music)", nil, " composer")
			add_actor_role("format_as_cite")

			-- if the output length has changed, a credit name has been printed
			-- and we can print the date
			if output_len ~= #output then
				author_outputted = true
				add_date()
			end

			add_chapter()
		else
			add_chapter()

			local mainauthor = parse_and_format_multivalued_annotated_text("mainauthor")
			if mainauthor then
				add_with_sep(mainauthor)
				author_outputted = true
			end

			add_authorlike("tlr", "translated by ", ", transl.", nil, " translator")
			add_authorlike("edtlr", "edited and translated by ", ", ed. and transl.", nil, " editor and translator")

			add_sg_and_pl_authorlike("editor", "edited")
			add_sg_and_pl_authorlike("compiler", "compiled")
			add_sg_and_pl_authorlike("director", "directed")

			add_authorlike("lyricist", nil, " (lyrics)", nil, " lyricist")
			add_authorlike("lyrics-translator", nil, " (translation)", nil, " lyrics translator")
			add_authorlike("composer", nil, " (music)", nil, " composer")
		end

		local title, title_fullname = a_with_name("title")
		local need_comma = false
		if title then
			local titleobj = parse_annotated_text(title, title_fullname, a("trans-title"))
			add(format_annotated_text(titleobj, tag_with_cite, tag_with_cite))
			local series = parse_and_format_annotated_text("series")
			if series then
				add(" (" .. series)
				local seriesvolume = parse_and_format_annotated_text("seriesvolume")
				if seriesvolume then
					add(SEMICOLON_SPACE .. seriesvolume)
				end
				add(")")
			end
			need_comma = true
		elseif ind == "" then
			if not a("notitle") then
				add(maintenance_line("Please provide the book title or journal name"))
				need_comma = true
			end
		end

		local archiveurl, archiveurl_fullname = aurl_with_name("archiveurl")
		local url, url_fullname = aurl_with_name("url")
		local urls, urls_fullname = aurl_with_name("urls")
		if url and urls then
			error(("Supply only one of |%s= and |%s="):format(url_fullname, urls_fullname))
		end
		local function verify_title_supplied(_url_name)
			-- There are too many cases of this to throw an error at this time.
			-- if not title then
				-- error(("If |%s= is given, |%s= must also be supplied"):format(_url_name, title_fullname))
			-- end
		end
		if archiveurl or url then
			verify_title_supplied(archiveurl and archiveurl_fullname or url_fullname)
			sep = nil
			add("&lrm;<sup>[" .. (archiveurl or url) .. "]</sup>")
		elseif urls then
			verify_title_supplied(urls_fullname)
			sep = nil
			add("&lrm;<sup>" .. urls .. "</sup>")
		end

		-- display (in Language) if language is provided and is not English and not overriden by termlang or worklang
		if format_as_cite and ind == "" and not (args.termlang or args.worklang) and (args[1] or args.lang) then
			local lang = get_first_lang(args[1] or args.lang)
			if lang then
				local langcode = lang:getCode()
				if not (langcode == "und" or langcode == "en") then
					local langs = format_langs(args[1] or args.lang)
					if langs then
						add(" (in " .. langs .. ")")
					end
				end
			end
		end

		if need_comma then
			sep = ", "
		end

		local edition, edition_fullname = parse_and_format_annotated_text_with_name("edition")
		local edition_plain, edition_plain_fullname = parse_and_format_annotated_text_with_name("edition_plain")
		if edition and edition_plain then
			error(("Supply only one of |%s= and |%s="):format(edition_fullname, edition_plain_fullname))
		end
		if edition then
			add_with_sep(edition .. " edition")
		end
		if edition_plain then
			add_with_sep(edition_plain)
		end

		-- Display a numeric param such as page=, volume=, column=. For each `paramname`, four params are actually
		-- recognized, e.g. for paramname == "page", the params page=, pages=, page_plain= and pageurl= are recognized
		-- and checked (or the same with an index, e.g. page2=, pages2=, page_plain2= and pageurl2= respectively if
		-- ind == "2"). Only one of the first three can be specified; an error results if more than one are given.
		-- If none are given, the return value is nil; otherwise it is a string. The numeric spec is taken directly
		-- from e.g. page_plain= if given; otherwise if e.g. pages= is given, or if page= is given and looks like a
		-- combination of numbers (i.e. it has a hyphen or dash in it, a comma, or the word " and "), it is prefixed
		-- by `singular_desc` + "s" (e.g. "pages "), otherwise it is prefixed by just `singular_desc` (e.g. "page ").
		-- (As a special case, if either e.g. page=unnumbered or pages=unnumbered is given, the numeric spec is
		-- "unnumbered page".) The resulting spec is returned directly unless e.g. pageurl= is given, in which case
		-- it is linked to the specified URL. Note that any of the specs can be foreign text, e.g. foreign numbers
		-- (including with optional inline modifiers), and such text is handled appropriately.
		local function format_numeric_param(paramname, singular_desc)
			local sgval = a_with_name(paramname)
			local sgobj = parse_annotated_text(sgval, paramname)
			local plparamname = paramname .. "s"
			local plval = a_with_name(plparamname)
			local plobj = parse_annotated_text(plval, plparamname)
			local plainval, plain_fullname = parse_and_format_annotated_text_with_name(paramname .. "_plain")

			local numspec
			if not sgval and not plval and not plainval then
				return
			elseif plainval and (sgval or plval) then
				error(("Can't specify " .. plain_fullname .. " with " .. paramname .. " or " .. plparamname))
			elseif sgval and plval then
				-- if both singular and plural, display "page 1 of 1-10"
				numspec = singular_desc .. " " .. sgval .. " of " .. plval
			else
				-- Merge page= and pages= and treat alike because people often mix them up in both directions.
				if plainval then
					numspec = plainval
				else
					-- Because we returned on `not sgval and not plval and not plainval`, one of the three must be
					-- truthy. In this arm, `plainval` is falsy so `sgval` or `plval` (and hence `sgobj` or `plobj`)
					-- must be truthy.
					local val = sgobj and sgobj.text or plobj and plobj.text or
						error("Internal error: one of sgobj or plobj must be true")
					if val == "unnumbered" then
						numspec = "unnumbered " .. singular_desc
					else
						local desc
						if val:find("^!") then
							val = val:gsub("^!", "")
							desc = sgval and singular_desc or pluralize(singular_desc)
						else
							local check_val = val
							if check_val:find("%[") then
								check_val = remove_links(check_val)
								-- convert URL's of the form [URL DISPLAY] to the displayed value
								check_val = check_val:gsub("%[[^ %[%]]* ([^%[%]]*)%]", "%1")
							end
							-- in case of negative page numbers (do they exist?), don't treat as multiple pages
							check_val = check_val:gsub("^%-", "")
							-- replace HTML entity en-dashes and em-dashes with their literal codes
							check_val = check_val:gsub("&ndash;", "–")
							check_val = check_val:gsub("&#8211;", "–")
							check_val = check_val:gsub("&mdash;", "—")
							check_val = check_val:gsub("&#8212;", "—")
							-- Check for en-dash or em-dash, or two numbers (possibly with stuff after like 12a-15b)
							-- separated by a hyphen or by comma a followed by a space (to avoid firing on thousands separators).
							if
								umatch(check_val, "[–—]")
								or check_val:find(" and ")
								or check_val:match("%d+[^ ]* *%- *%d+")
								or check_val:match("%d+[^ ]* *, +%d+")
							then
								desc = pluralize(singular_desc)
							else
								desc = singular_desc
							end
						end
						local obj = sgobj or plobj
						-- See above. One of `sgobj` or `plobj` must be truthy.
						--- @cast obj -nil
						obj.text = val
						if obj.link:find("^!") then
							obj.link = obj.link:gsub("^!", "")
						end
						val = format_annotated_text(obj)
						numspec = desc .. " " .. val
					end
				end
			end
			local url = a(paramname .. "url")
			if url then
				return "[" .. url .. " " .. numspec .. "]"
			else
				return numspec
			end
		end

		local volume = format_numeric_param("volume", a("volume_prefix") or "volume")
		if volume then
			add_with_sep(volume)
		end

		local issue = format_numeric_param("issue", a("issue_prefix") or "number")
		if issue then
			add_with_sep(issue)
		end

		-- number= is an alias for issue= (except in {{quote-av}}, where it is the episode number)
		local number = format_numeric_param("number", a("number_prefix") or "number")
		if number then
			add_with_sep(number)
		end

		local annotations = {}
		local genre = a("genre")
		if genre then
			insert(annotations, genre)
		end
		local format = a("format")
		if format then
			insert(annotations, format)
		end
		local medium = a("medium")
		if medium then
			insert(annotations, medium)
		end

		-- Now handle the display of language annotations like "(in French)" or
		-- "(quotation in Nauruan; overall work in German)".
		local quotelang = args[1] or args.lang
		if not quotelang then
			if ind == "" then
				-- This can only happen for certain non-mainspace pages, e.g. Talk pages; otherwise an error is thrown
				-- above.
				insert(annotations, maintenance_line("Please specify the language of the quote using |1="))
			else
				-- do nothing in newversion= portion
			end
		elseif ind == "" then
			local worklang = a("worklang")
			local termlang = a("termlang")
			worklang = worklang or quotelang
			termlang = termlang or quotelang

			if worklang == quotelang then
				if worklang == termlang then
					-- do nothing
				else
					insert(annotations, "in " .. format_langs(quotelang))
				end
			else
				if quotelang ~= termlang then
					insert(annotations, "quotation in " .. format_langs(quotelang))
				end
				insert(annotations, "overall work in " .. format_langs(worklang))
			end
		else
			local lang2 = a("lang2")
			if lang2 then
				insert(annotations, "in " .. format_langs(lang2))
			end
		end

		if #annotations > 0 then
			sep = nil
			add_with_sep(" (" .. concat(annotations, SEMICOLON_SPACE) .. ")")
		end

		local artist = parse_and_format_multivalued_annotated_text("artist", "and")
		if artist then
			add_with_sep("performed by " .. artist)
		end

		local feat = parse_and_format_multivalued_annotated_text("feat", "and")
		if feat then
			sep = " "
			add_with_sep("ft. " .. feat)
		end

		if not format_as_cite then
			add_actor_role()
		end

		local others = parse_and_format_annotated_text("others")
		if others then
			add_with_sep(others)
		end
		local quoted_in = parse_and_format_annotated_text("quoted_in", tag_with_cite, tag_with_cite)
		if quoted_in then
			add_with_sep("quoted in " .. quoted_in)
			insert(tracking_categories, "Quotations using quoted-in parameter")
		end

		local location = parse_and_format_multivalued_annotated_text("location", "; ")
		local publisher = parse_and_format_multivalued_annotated_text("publisher", "; ")
		if publisher then
			if location then
				add_with_sep(location) -- colon
				sep = "&#58; " -- colon
			end
			add_with_sep(publisher)
		elseif location then
			add_with_sep(location)
		end

		if not date_outputted then
			add_date("no_paren")
		end

		if ind ~= "" and has_newversion() then
			local formatted_new_date = format_date_args {
				a = a,
				get_full_paramname = get_full_paramname,
				alias_map = alias_map,
				parampref = "",
				paramsuf = "",
				maintenance_line_no_date = "Please provide a date or year",
				year_last = true,
			}
			if formatted_new_date then
				add_with_sep(formatted_new_date)
			end
		end

		-- Fetch date_published=/year_published=/month_published= and format appropriately.
		local formatted_date_published = format_date_args {
			a = a,
			get_full_paramname = get_full_paramname,
			alias_map = alias_map,
			parampref = "",
			paramsuf = "_published",
			year_last = true,
		}
		local platform = parse_and_format_multivalued_annotated_text("platform", "and")
		if formatted_date_published then
			add_with_sep("published " .. formatted_date_published .. (platform and " via " .. platform or ""))
		elseif platform then
			add_with_sep("via " .. platform)
		end

		-- From here on out, there should always be a preceding item, so we
		-- can dispense with add_with_sep() and always insert the comma.
		sep = nil

		local function small(txt)
			add(", <small>")
			add(txt)
			add("</small>")
		end

		-- Add an identifier to a book or article database such as DOI, ISBN, JSTOR, etc. `param_or_params`
		-- is a string identifying the base param, or a list of such strings to check in turn. If found, the value
		-- of the parameter is processed using `process` (a function of one argument, defaulting to mw.uri.encode()),
		-- and then the actual URL to insert is generated by preceding with `pretext`, following with `posttext`,
		-- and running the resulting string through small(), which first adds a comma and then the URL in small font.
		local function add_identifier(param_or_params, pretext, posttext, process)
			local val = a(param_or_params)
			if val then
				val = (process or mw.uri.encode)(val)
				small(pretext .. val .. posttext)
			end
		end

		add_identifier("bibcode", "[https://adsabs.harvard.edu/abs/", " →Bibcode]")
		add_identifier("doi", '<span class="neverexpand">[https://doi.org/', " →DOI]</span>")
		add_identifier("isbn", "", "", isbn)
		add_identifier("issn", "", "", issn)
		add_identifier("jstor", "[https://www.jstor.org/stable/", " →JSTOR]")
		add_identifier("lccn", "", "", lccn)
		add_identifier("oclc", "[https://search.worldcat.org/title/", " →OCLC]")
		add_identifier("ol", "[https://openlibrary.org/works/OL", "/ →OL]")
		add_identifier("pmid", "[https://www.ncbi.nlm.nih.gov/pubmed/", " →PMID]")
		add_identifier("pmcid", "[https://www.ncbi.nlm.nih.gov/pmc/articles/", "/ →PMCID]")
		add_identifier("ssrn", "[https://ssrn.com/abstract=", " →SSRN]")
		-- add_identifier("urn", "", "", urn)
		local id = a("id")
		if id then
			small(id)
		end

		archiveurl, archiveurl_fullname = aurl_with_name("archiveurl")
		if archiveurl then
			add(", archived from ")
			local url, url_fullname = aurl_with_name("url")
			if not url then
				-- attempt to infer original URL from archive URL; this works at
				-- least for Wayback Machine (web.archive.org) URL's
				url = archiveurl:match("/(https?:.*)$")
				if not url then
					error(
						("When |%s= is specified, |%s= must also be included"):format(archiveurl_fullname, url_fullname)
					)
				end
			end
			add("[" .. url .. " the original] on ")
			local archivedate, archivedate_fullname = a_with_name("archivedate")
			if archivedate then
				add(format_date(archivedate))
			elseif string.sub(archiveurl, 1, 28) == "https://web.archive.org/web/" then
				-- If the archive is from the Wayback Machine, then it already contains the date
				-- Get the date and format it
				local wayback_date = string.sub(archiveurl, 29, 29 + 7)
				wayback_date = string.sub(wayback_date, 1, 4)
					.. "-"
					.. string.sub(wayback_date, 5, 6)
					.. "-"
					.. string.sub(wayback_date, 7, 8)
				add(format_date(wayback_date))
			elseif string.sub(archiveurl, 1, 21) == "https://megalodon.jp/" then
				local megalodon_date = string.sub(archiveurl, 22, 25)
					.. "-"
					.. string.sub(archiveurl, 27, 28)
					.. "-"
					.. string.sub(archiveurl, 29, 30)
				add(format_date(megalodon_date))
			else
				error(
					("When |%s= is specified, |%s= must also be included"):format(
						archiveurl_fullname,
						archivedate_fullname
					)
				)
			end
		end
		if a("accessdate") then
			--Otherwise do not display here, as already used as a fallback for missing date= or year= earlier.
			if (a("date") or a("nodate") or a("year")) and not a("archivedate") then
				add(", retrieved " .. format_date(a("accessdate")))
			end
		end

		local formatted_section = format_chapterlike("section", "section ")
		if formatted_section then
			add(", ")
			add(formatted_section)
		end

		-- video game stuff
		local system = parse_and_format_annotated_text("system")
		if system then
			add(", " .. system)
		end
		local scene = parse_and_format_annotated_text("scene")
		if scene then
			add(", scene: " .. scene)
		end
		local level = parse_and_format_annotated_text("level")
		if level then
			add(", level/area: " .. level)
		end

		local note = parse_and_format_annotated_text("note")
		if note then
			add(", " .. note)
		end

		local note_plain = parse_and_format_annotated_text("note_plain")
		if note_plain then
			add(" " .. note_plain)
		end

		-- Wrapper around format_numeric_param that inserts the formatted text with optional preceding text.
		local function handle_numeric_param(paramname, singular_desc, pretext)
			local numspec = format_numeric_param(paramname, singular_desc)
			if numspec then
				add((pretext or "") .. numspec)
			end
		end

		handle_numeric_param("page", a("page_prefix") or "page", ", ")
		handle_numeric_param("column", a("column_prefix") or "column", ", ")
		handle_numeric_param("line", a("line_prefix") or "line", ", ")

		local source = parse_and_format_multivalued_annotated_text("source", "and")
		if source then
			add(", sourced from " .. source)
		end

		local original = parse_and_format_annotated_text("original", tag_with_cite, tag_with_cite)
		local by = parse_and_format_multivalued_annotated_text("by", "and")
		local origtype = a("deriv") or "translation"
		if original or by then
			add(", " .. origtype .. " of " .. (original or "original") .. (by and " by " .. by or ""))
		end

		-- Handle origlang=, origworklang=. How we handle them depends on whether the original title or author are explicitly
		-- given.
		local origlang = a("origlang")
		local origworklang = a("origworklang")
		local origlangtext, origworklangtext
		if origlang then
			origlangtext = "in " .. format_langs(origlang)
		end
		if origworklang then
			origworklangtext = "overall work in " .. format_langs(origworklang)
		end
		if origlang or origworklang then
			if original or by then
				local orig_annotations = {}
				if origlangtext then
					insert(orig_annotations, origlangtext)
				end
				if origworklangtext then
					insert(orig_annotations, origworklangtext)
				end
				add(" (" .. concat(orig_annotations, SEMICOLON_SPACE) .. ")")
			else
				add(", " .. origtype .. " of original" .. (origlangtext and " " .. origlangtext or ""))
				if origworklangtext then
					sep = nil
					add(" (" .. origworklangtext .. ")")
				end
			end
		end

		-- FIXME: Does this make sense? What is other=?
		local other = parse_and_format_annotated_text("other")
		if other then
			add(", " .. other)
		end
	end

	local function add_authors(args, last_first)
		-- Find maximum indexed author or last name.
		local maxind = math.max(args.author.maxindex, args.last.maxindex)
		-- Include max index of ancillary params so we get an error message about their use without the primary params.
		local ancillary_params =
			{"trans-author", "authorlink", "trans-authorlink", "first", "trans-first", "trans-last"}
		for _, ancillary in ipairs(ancillary_params) do
			maxind = math.max(maxind, args[ancillary].maxindex)
		end

		local num_authors = 0
		for i = 1, maxind do
			local ind = i == 1 and "" or i
			local author, last = args.author[i], args.last[i]
			if author or last then
				local this_num_authors = add_author(
					author,
					"author" .. ind,
					args["trans-author"][i],
					"trans-author" .. ind,
					args.authorlink[i],
					"authorlink" .. ind,
					args["trans-authorlink"][i],
					"trans-authorlink" .. ind,
					args.first[i],
					"first" .. ind,
					args["trans-first"][i],
					"trans-first" .. ind,
					last,
					"last" .. ind,
					args["trans-last"][i],
					"trans-last" .. ind,
					last_first
				)
				num_authors = num_authors + this_num_authors
				sep = last_first and "; " or ", "
			else
				for _, cant_have in ipairs(ancillary_params) do
					if args[cant_have][i] then
						error(("Can't have |%s%s= without |author%s= or |last%s="):format(cant_have, ind, ind, ind))
					end
				end
			end
		end
		return num_authors
	end

	local function add_newversion()
		-- If there's a "newversion" section, add the new-version text.
		if has_newversion() then
			sep = nil
			--Test for new version of work.
			add(SEMICOLON_SPACE)
			-- newversion= is intended for English text, e.g. "quoted in" or "republished as".
			-- FIXME, explain the 'not args.edition2' here
			local newversion = args.newversion or not args.edition2 and "republished as"
			if newversion then
				-- If no title, author or chapter, chop off "as" and "in" so we don't get e.g.
				-- 'translated as c. 1025'.
				if not has_new_title_or_author() then
					newversion = newversion:gsub(" as$", ""):gsub(" in$", "")
				end
				add(newversion)
			end
			add(" ")
			return ""
		else
			return ", "
		end
	end

	------------------- Now we start outputting text ----------------------

	local need_comma = false

	-- Set this now so a() works just below.
	get_full_paramname = make_get_full_paramname("")

	if args.brackets then
		add("[")
	end

	formatted_date, need_date = format_date_args {
		a = a,
		get_full_paramname = get_full_paramname,
		alias_map = alias_map,
		bold_year = not format_as_cite,
		maintenance_line_no_date = "Can we [[:Category:Requests for date|date]] this quote?",
		year_last = format_as_cite,
	}

	-- Fetch origdate=/origyear=/origmonth= and format appropriately.
	formatted_origdate = format_date_args {
		a = a,
		get_full_paramname = get_full_paramname,
		alias_map = alias_map,
		parampref = "orig",
		year_last = format_as_cite,
	}

	local num_authors
	if format_as_cite then
		num_authors = add_authors(args, "last_first")
		if author_outputted then
			sep = " "
		end

		-- Display all the text that comes after the author, for the main portion.
		postauthor("", num_authors, "format_as_cite")

		author_outputted = false

		sep = add_newversion()

		-- Add the newversion author(s).
		if args["2ndauthor"] or args["2ndlast"] then
			num_authors = add_author(
				args["2ndauthor"],
				"2ndauthor",
				nil,
				nil,
				args["2ndauthorlink"],
				"2ndauthorlink",
				nil,
				nil,
				args["2ndfirst"],
				"2ndfirst",
				nil,
				nil,
				args["2ndlast"],
				"2ndlast",
				nil,
				nil,
				"last_first"
			)
			sep = ", "
		else
			for _, cant_have in ipairs {"2ndauthorlink", "2ndfirst"} do
				if args[cant_have] then
					error(("Can't have |%s= without |2ndauthor= or |2ndlast="):format(cant_have))
				end
			end
		end

		-- Display all the text that comes after the author, for the "newversion" section.
		postauthor(2, num_authors, "format_as_cite")
	else
		if formatted_date then
			need_comma = true
			add(formatted_date)
		end

		if formatted_origdate then
			need_comma = true
			add(SPACE_LBRAC .. formatted_origdate .. RBRAC)
		end

		if need_comma then
			sep = ", "
		end

		date_outputted = true

		num_authors = add_authors(args)

		-- Display all the text that comes after the author, for the main portion.
		postauthor("", num_authors)

		author_outputted = false

		sep = add_newversion()

		-- Add the newversion author(s).
		if args["2ndauthor"] or args["2ndlast"] then
			num_authors = add_author(
				args["2ndauthor"],
				"2ndauthor",
				nil,
				nil,
				args["2ndauthorlink"],
				"2ndauthorlink",
				nil,
				nil,
				args["2ndfirst"],
				"2ndfirst",
				nil,
				nil,
				args["2ndlast"],
				"2ndlast",
				nil,
				nil
			)
			sep = ", "
		else
			for _, cant_have in ipairs {"2ndauthorlink", "2ndfirst"} do
				if args[cant_have] then
					error(("Can't have |%s= without |2ndauthor= or |2ndlast="):format(cant_have))
				end
			end
		end

		-- Display all the text that comes after the author, for the "newversion" section.
		postauthor(2, num_authors)
	end

	if not args.nocolon then
		sep = nil
		add(":")
	elseif args.usenodot and not args.nodot then
		add(".")
	end

	-- Concatenate output portions to form output text.
	local output_text = concat(output)

	-- Remainder of code handles adding categories. We add one or more of the following categories:
	--
	-- 1. [[Category:LANG terms with quotations]], based on the first language code in termlang= or 1=. Added to
	--    mainspace, Reconstruction: and Appendix: pages as well as Citations: pages if the corresponding mainspace
	--    page exists. Not added if nocat= is given. Note that [[Module:usex]] adds the same category using the same
	--    logic, but we do it here too because we may not have a quotation to format. (We add in those circumstances
	--    because typically when there's no quotation to format, it's because it's formatted manually underneath the
	--    citation, or using {{ja-x}}, {{th-x}} or similar.)
	-- 2. [[Category:Requests for date in LANG entries]], based on the first language code in 1=. Added to mainspace,
	--    Reconstruction:, Appendix: and Citations: pages unless nocat= is given.
	-- 3. [[Category:Quotations using nocat parameter]], if nocat= is given. Added to mainspace, Reconstruction:,
	--    Appendix: and Citations: pages.

	local categories = {}
	local termlang = get_first_lang(args.termlang or argslang)

	if args.nocat then
		if format_as_cite then
			insert(tracking_categories, "Citations using nocat parameter")
		else
			insert(tracking_categories, "Quotations using nocat parameter")
		end
	else
		-- don't create language tracking categories for citations
		if not format_as_cite then
			local title
			if args.pagename then -- for testing, doc pages, etc.
				title = mw.title.new(args.pagename)
				if not title then
					error(("Bad value for `args.pagename`: '%s'"):format(args.pagename))
				end
			else
				title = mw.title.getCurrentTitle()
			end
			-- Only add [[Citations:foo]] to [[:Category:LANG terms with quotations]] if [[foo]] exists.
			local ok_to_add_cat
			if title.nsText ~= "Citations" then
				ok_to_add_cat = true
			else
				local mainspace_title = mw.title.new(title.text)
				if mainspace_title and mainspace_title.exists then
					ok_to_add_cat = true
				end
			end
			if ok_to_add_cat then
				insert(categories, termlang:getFullName() .. " terms with quotations")
			end
		end
		if need_date then
			local argslangobj = get_first_lang(argslang)
			insert(categories, "Requests for date in " .. argslangobj:getCanonicalName() .. " entries")
		end
	end

	return output_text .. (
		not termlang and "" or
		(#categories > 0 and format_categories(categories, termlang, args.sort) or "") .. (
			#tracking_categories > 0
				and format_categories(
					tracking_categories,
					termlang,
					args.sort,
					nil,
					not page_should_be_ignored(mw.title.getCurrentTitle().fullText)
				)
			or ""
		)
	)
end

-- Alias specs for type= and type2=. Each spec is `{canon, aliases, with_newversion}` where `canon` is the canonical
-- parameter (with "2" added if type2= is being handled), `aliases` is a comma-separated string of aliases (with "2"
-- added if type2= is being handled, except for numeric params), and `with_newversion` indicates whether we should
-- process this spec if type2= is being handled.
local type_alias_specs = {
    av = {
    	{"author", "writer,writers", true},
    	{"chapter", "episode", true},
    	{"chapterurl", "episodeurl", true},
    	{"trans-chapter", "trans-episode", true},
    	{"chapter_tlr", "episode_tlr,episode_tlrs,episode_translator,episode_translators", true},
    	{"chapter_edtlr", "episode_edtlr,episode_edtlrs,episode_editor_translator,episode_editors_translators", true},
    	{"chapter_series", "episode_series", true},
    	{"chapter_seriesvolume", "episode_seriesvolume", true},
    	{"chapter_number", "episode_number", true},
    	{"chapter_plain", "episode_plain", true},
    	{"volume", "season", true},
    	{"volumes", "seasons", true},
    	{"volume_plain", "season_plain", true},
    	{"volumeurl", "seasonurl", true},
    	{"platform", "network", true},
    },
	book = {
		{"author", "3"},
		{"title", "4"},
		{"url", "5"},
		{"year", "2"},
		{"page", "6"},
		{"text", "7"},
		{"t", "8"},
	},
	journal = {
		{"year", "2"},
		{"author", "3"},
		{"chapter", "title,article,4", true},
		{"chapterurl", "titleurl,articleurl", true},
		{"trans-chapter", "trans-title,trans-article", true},
		{"chapter_tlr", "title_tlr,title_tlrs,title_translator,title_translators,article_tlr,article_tlrs,article_translator,article_translators", true},
		{"chapter_edtlr", "title_edtlr,title_edtlrs,title_editor_translator,title_editors_translators,article_edtlr,article_edtlrs,article_editor_translator,article_editors_translators", true},
		{"chapter_series", "title_series,article_series", true},
		{"chapter_seriesvolume", "title_seriesvolume,article_seriesvolume", true},
		{"chapter_number", "title_number,article_number", true},
		{"chapter_plain", "title_plain,article_plain", true},
		{"title", "journal,magazine,newspaper,work,5", true},
		{"trans-title", "trans-journal,trans-magazine,trans-newspaper,trans-work", true},
		{"tlr", "journal_tlr,journal_tlrs,journal_translator,journal_translators,magazine_tlr,magazine_tlrs,magazine_translator,magazine_translators,newspaper_tlr,newspaper_tlrs,newspaper_translator,newspaper_translators,work_tlr,work_tlrs,work_translator,work_translators", true},
		{"edtlr", "journal_edtlr,journal_edtlrs,journal_editor_translator,journal_editors_translators,magazine_edtlr,magazine_edtlrs,magazine_editor_translator,magazine_editors_translators,newspaper_edtlr,newspaper_edtlrs,newspaper_editor_translator,newspaper_editors_translators,work_edtlr,work_edtlrs,work_editor_translator,work_editors_translators", true},
		{"url", "6,journalurl,magazineurl,newspaperurl,workurl", true},
		{"page", "7"},
		{"source", "newsagency,news_agency", true},
		{"text", "8"},
		{"t", "9"},
	},
}

-- Process interally-handled aliases related to type= or type2=. `args` is a table of arguments; `typ` is the value of
-- type= or type2=; newversion=true if we're dealing with type2=; alias_map is used to keep track of alias mappings
-- seen.
local function process_type_aliases(args, typ, newversion, alias_map)
	local ind = newversion and "2" or ""
	local deprecated = ine(args.lang)
	if not type_alias_specs[typ] then
		local possible_values = {}
		for possible, _ in pairs(type_alias_specs) do
			insert(possible_values, possible)
		end
		sort(possible_values)
		error(
			("Unrecognized value '%s' for type%s=; possible values are %s"):format(
				typ,
				ind,
				concat(possible_values, ",")
			)
		)
	end

	for _, alias_spec in ipairs(type_alias_specs[typ]) do
		local canon, aliases, with_newversion = unpack(alias_spec)
		if with_newversion or not newversion then
			canon = canon .. ind
			aliases = split(aliases, ",", true)
			local saw_alias = nil
			for _, alias in ipairs(aliases) do
				if alias:match("^%d+$") then
					alias = tonumber(alias)
					if deprecated then
						alias = alias - 1
					end
				else
					alias = alias .. ind
				end
				if args[alias] then
					if saw_alias == nil then
						saw_alias = alias
					else
						error(("|%s= and |%s= are aliases; cannot specify a value for both"):format(saw_alias, alias))
					end
				end
			end
			if saw_alias and (not newversion or type(saw_alias) == "string") then
				if args[canon] then
					error(("|%s= is an alias of |%s=; cannot specify a value for both"):format(saw_alias, canon))
				end
				args[canon] = args[saw_alias]
				-- Wipe out the original after copying. This is important in case of a param that has general significance
				-- but has been redefined (e.g. {{quote-av}} redefines number= for the episode number, and
				-- {{quote-journal}} redefines title= for the chapter= (article). It's also important due to unhandled
				-- parameter checking.
				args[saw_alias] = nil
				alias_map[canon] = saw_alias
			end
		end
	end
end

-- Clone and combine frame's and parent's args while also assigning nil to empty strings. Handle aliases and ignores.
local function clone_args(direct_args, parent_args)
	local args = {}

	-- Processing parent args must come first so that direct args override parent args. Note that if a direct arg is
	-- specified but is blank, it will still override the parent arg (with nil).
	for pname, param in pairs(parent_args) do
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/quote/param/PARAM]]
		track("param/" .. pname)
		args[pname] = ine(param)
	end

	-- Process ignores. The value of `ignore` is a comma-separated list of parameter names to ignore (erase). We need to
	-- do this before aliases due to {{quote-song}}, which sets chapter= to the value of title= in the direct params and
	-- sets title= to the value of album= using an alias. If we do the ignores after aliases, we get an error during alias
	-- processing, saying that title= and its alias album= are both present.
	local ignores = ine(direct_args.ignore)
	if ignores then
		for ignore in gsplit(ignores, "%s*,%s*") do
			args[ignore] = nil
		end
	end

	local alias_map = {}
	local other_controls = {}

	-- noroman
	local noroman = ine(direct_args.noroman)
	if noroman then
		other_controls.overrides = other_controls.overrides or {}
		for param in gsplit(noroman, "%s*,%s*") do
			other_controls.overrides[param] = (other_controls.overrides[param] or {})
			other_controls.overrides[param].noroman = true
		end
	end

	-- Process internally-specified aliases using type= or type2=.
	local typ = args.type or direct_args.type
	if typ then
		process_type_aliases(args, typ, false, alias_map)
	end
	local typ2 = args.type2 or direct_args.type2
	if typ2 then
		process_type_aliases(args, typ2, true, alias_map)
	end

	-- Process externally-specified aliases. The value of `alias` is a list of semicolon-separated specs, each of which
	-- is of the form DEST:SOURCE,SOURCE,... where DEST is the canonical name of a parameter and SOURCE refers to an
	-- alias. Whitespace is allowed between all delimiters. The order of aliases may be important. For example, for
	-- {{quote-journal}}, title= contains the article name and is an alias of underlying chapter=, while journal= or
	-- work= contains the journal name and is an alias of underlying title=. As a result, the title -> chapter alias
	-- must be specified before the journal/work -> title alias.
	--
	-- Whenever we copy a value from argument SOURCE to argument DEST, we record an entry for the pair in alias_map, so
	-- that when we would display an error message about DEST, we display SOURCE instead.
	--
	-- Do alias processing (and ignore and error_if processing) before processing direct_args so that e.g. we can set up
	-- an alias of title -> chapter and then set title= to something else in the direct args ({{quote-hansard}} does
	-- this).
	--
	-- FIXME: Delete this once we've converted all alias processing to internal.
	local aliases = ine(direct_args.alias)
	if aliases then
		-- Allow and discard a trailing semicolon, to make managing multiple aliases easier.
		aliases = ugsub(aliases, "%s*;$", "")
		for alias_spec in gsplit(aliases, "%s*;%s*") do
			local alias_spec_parts = split(alias_spec, "%s*:%s*")
			if #alias_spec_parts ~= 2 then
				error(("Alias spec '%s' should have one colon in it"):format(alias_spec))
			end
			local dest, sources = unpack(alias_spec_parts)
			sources = split(sources, "%s*,%s*")
			local saw_source = nil
			for _, source in ipairs(sources) do
				if source:match("^%d+$") then
					source = tonumber(source)
				end
				if args[source] then
					if saw_source == nil then
						saw_source = source
					else
						error(("|%s= and |%s= are aliases; cannot specify a value for both"):format(saw_source, source))
					end
				end
			end
			if saw_source then
				if args[dest] then
					error(("|%s= is an alias of |%s=; cannot specify a value for both"):format(saw_source, dest))
				end
				args[dest] = args[saw_source]
				-- Wipe out the original after copying. This important in case of a param that has general significance
				-- but has been redefined (e.g. {{quote-av}} redefines number= for the episode number, and
				-- {{quote-journal}} redefines title= for the chapter= (article). It's also important due to unhandled
				-- parameter checking.
				args[saw_source] = nil
				alias_map[dest] = saw_source
			end
		end
	end

	-- Process error_if. The value of `error_if` is a comma-separated list of parameter names to throw an error if seen
	-- in parent_args (they are params we overwrite in the direct args).
	local error_ifs = ine(direct_args.error_if)
	if error_ifs then
		for error_if in gsplit(error_ifs, "%s*,%s*") do
			if ine(parent_args[error_if]) then
				error(
					("Cannot specify a value |%s=%s as it would be overwritten or ignored"):format(
						error_if,
						ine(parent_args[error_if])
					)
				)
			end
		end
	end

	for pname, param in pairs(direct_args) do
		-- ignore control params
		if pname ~= "ignore" and pname ~= "alias" and pname ~= "error_if" and pname ~= "noroman" then
			args[pname] = ine(param)
		end
	end

	return args, alias_map, other_controls
end

local function get_args(frame_args, parent_args, require_lang)
	-- FIXME: We are processing arguments twice, once in clone_args() and then again in [[Module:parameters]]. This is
	-- wasteful of memory.

	local cloned_args, alias_map, other_controls = clone_args(frame_args, parent_args)
	local deprecated = ine(parent_args.lang)

	local alias_of_t = {alias_of = "t"}
	local boolean = {type = "boolean"}
	local language_sublist = {type = "language", sublist = true}
	local list_allow_holes = {list = true, allow_holes = true}
	local script = {type = "script"}

	-- First, the "single" params that don't have FOO2 or FOOn versions.
	local params = {
		[deprecated and "lang" or 1] = {required = require_lang, type = "language", sublist = true, default = "und"},
		["lang2"] = language_sublist,
		["newversion"] = true,
		["author"] = list_allow_holes,
		["2ndauthor"] = true,
		["trans-author"] = list_allow_holes,
		["authorlink"] = list_allow_holes,
		["2ndauthorlink"] = true,
		["trans-authorlink"] = list_allow_holes,
		["first"] = list_allow_holes,
		["2ndfirst"] = true,
		["trans-first"] = list_allow_holes,
		["last"] = list_allow_holes,
		["2ndlast"] = true,
		["trans-last"] = list_allow_holes,
		["nocat"] = boolean,
		["nocolon"] = boolean,

		-- quote params
		text = true,
		passage = {alias_of = "text"},
		tr = true,
		transliteration = {alias_of = "tr"},
		ts = true,
		transcription = {alias_of = "ts"},
		norm = true,
		normalization = {alias_of = "norm"},
		normurl = true,
		normalizationurl = {alias_of = "normurl"},
		sc = script,
		normsc = script,
		sort = true,
		subst = true,
		footer = true,
		lit = true,
		liturl = true,
		t = true,
		turl = true,
		translation = alias_of_t,
		translationurl = {alias_of = "turl"},
		gloss = alias_of_t,
		ll = true,
		lb = {alias_of = "ll", deprecated = true},
		brackets = boolean,
		-- original quote params
		origtext = true,
		origtr = true,
		origts = true,
		origurl = true,
		orignorm = true,
		origsc = script,
		orignormsc = script,
		orignormurl = true,
		origsubst = true,
		origll = true,
		origlb = {alias_of = "origll", deprecated = true},

		usenodot = boolean,
		nodot = boolean,
		inline = boolean,

		asquote = boolean,
		ascite = boolean,
	}

	-- Most params have PARAM2 variants for use with `newversion`. FIXME: We should generalize this to
	-- allow PARAMN variants for any N.
	local function add_with_2(param, value)
		params[param] = value
		params[param .. "2"] = value
	end

	local function alias_with_2(alias, canon)
		params[alias] = {alias_of = canon}
		params[alias .. "2"] = {alias_of = canon .. "2"}
	end

	for _, param12 in ipairs {
		"worklang",
		"termlang",
		"origlang",
		"origworklang"
	} do
		add_with_2(param12, language_sublist)
	end

	-- Then the newversion params (which have FOO2 versions).
	for _, param12 in ipairs {
		-- author-like params; author params themselves are either list params (author=, last=, etc.) or single params
		-- (2ndauthor=, 2ndlast=, etc.)
		"coauthors",
		"quotee",
		"tlr",
		"edtlr",
		"editor",
		"editors",
		"mainauthor",
		"compiler",
		"compilers",
		"director",
		"directors",
		"lyricist",
		"lyrics-translator",
		"composer",
		"role",
		"actor",
		"artist",
		"feat",

		-- author control params
		"default-authorlabel",
		"authorlabel",

		-- title
		"title",
		"trans-title",
		"series",
		"seriesvolume",
		"notitle",

		-- entry
		"entry",
		"entryurl",
		"trans-entry",

		-- chapter
		"chapter",
		"chapterurl",
		"chapter_number",
		"chapter_plain",
		"chapter_series",
		"chapter_seriesvolume",
		"trans-chapter",
		"chapter_tlr",
		"chapter_edtlr",

		-- section
		"section",
		"sectionurl",
		"section_number",
		"section_plain",
		"section_series",
		"section_seriesvolume",
		"trans-section",

		-- other video-game params
		"system",
		"scene",
		"level",

		-- URL
		"url",
		"urls",
		"archiveurl",

		-- edition
		"edition",
		"edition_plain",

		-- ID params
		"bibcode",
		"doi",
		"isbn",
		"issn",
		"jstor",
		"lccn",
		"oclc",
		"ol",
		"pmid",
		"pmcid",
		"ssrn",
		"urn",
		"id",

		-- misc date params; most date params handled below
		"archivedate",
		"accessdate",
		"nodate",

		-- numeric params handled below

		-- other params
		"type",
		"genre",
		"format",
		"medium",
		"others",
		"quoted_in",
		"location",
		"publisher",
		"original",
		"by",
		"deriv",
		"note",
		"note_plain",
		"other",
		"source",
		"platform",
	} do
		add_with_2(param12, true)
	end

	-- Then the aliases of newversion params (which have FOO2 versions).
	for _, param12_aliased in ipairs {
		{"role", "roles"},
		{"role", "speaker"},
		{"tlr", "tlrs"},
		{"tlr", "translator"},
		{"tlr", "translators"},
		{"edtlr", "edtlrs"},
		{"edtlr", "editor_translator"},
		{"edtlr", "editors_translators"},
		{"chapter_tlr", "chapter_tlrs"},
		{"chapter_tlr", "chapter_translator"},
		{"chapter_tlr", "chapter_translators"},
		{"chapter_edtlr", "chapter_edtlrs"},
		{"chapter_edtlr", "chapter_editor_translator"},
		{"chapter_edtlr", "chapter_editors_translators"},
		{"doi", "DOI"},
		{"isbn", "ISBN"},
		{"issn", "ISSN"},
		{"jstor", "JSTOR"},
		{"lccn", "LCCN"},
		{"oclc", "OCLC"},
		{"ol", "OL"},
		{"pmid", "PMID"},
		{"pmcid", "PMCID"},
		{"ssrn", "SSRN"},
		{"urn", "URN"},
	} do
		local canon, alias = unpack(param12_aliased)
		alias_with_2(alias, canon)
	end

	-- Then the date params.
	for _, datelike in ipairs {{"", ""}, {"orig", ""}, {"", "_published"}} do
		local pref, suf = unpack(datelike)
		for _, arg in ipairs {"date", "year", "month", "start_date", "start_year", "start_month"} do
			add_with_2(pref .. arg .. suf, true)
		end
	end

	local numeric_param_suffixes = {"", "s", "_plain", "url", "_prefix"}
	-- Then the numeric params.
	for _, numeric in ipairs {"volume", "issue", "number", "line", "page", "column"} do
		for _, suf in ipairs(numeric_param_suffixes) do
			add_with_2(numeric .. suf, true)
		end
	end
	-- And the aliases of numeric params.
	for _, numeric_aliased in ipairs {{"volume", "vol"}} do
		local canon, alias = unpack(numeric_aliased)
		for _, suf in ipairs(numeric_param_suffixes) do
			alias_with_2(alias .. suf, canon .. suf)
		end
	end

	return process_params(cloned_args, params), alias_map, other_controls, deprecated
end

local function get_origtext_params(args)
	local origtext, origtextlang, origsc, orignormsc
	if args.origtext then
		-- Wiktionary language codes have at least two lowercase letters followed possibly by lowercase letters and/or
		-- hyphens (there are more restrictions but this is close enough). Also check for nonstandard Latin etymology
		-- language codes (e.g. VL. or LL.). (There used to be more nonstandard codes but they have all been
		-- eliminated.)
		origtextlang, origtext = args.origtext:match("^(%l%l[%l-]*):([^ ].*)$")
		if not origtextlang then
			-- Special hack for Latin variants, which can have nonstandard etym codes, e.g. VL., LL.
			origtextlang, origtext = args.origtext:match("^(%uL%.):([^ ].*)$")
		end
		if not origtextlang then
			error("origtext= should begin with a language code prefix")
		end
		origtextlang = get_lang(origtextlang, nil, "allow etym") or
			error("origtext= should begin with a language code prefix")
		origsc = args.origsc
		orignormsc = args.orignormsc
	else
		for _, noparam in ipairs {"origtr", "origts", "origsc", "orignorm", "orignormsc", "origsubst", "origll"} do
			if args[noparam] then
				error(("Cannot specify %s= without origtext="):format(noparam))
			end
		end
	end
	return origtext, origtextlang, origsc, orignormsc
end

local function get_quote(args, is_cite)
	local text = args.text
	local gloss = args.t
	local tr = args.tr
	local ts = args.ts
	local norm = args.norm
	local sc = args.sc
	local normsc = args.normsc

	-- Fetch original-text parameters.
	local origtext, origtextlang, origsc, orignormsc = get_origtext_params(args)

	-- If any quote-related args are present, display the actual quote; otherwise, display nothing.
	if text or gloss or tr or ts or norm or args.origtext then
		-- Pass "und" here rather than cause an error; there will be an error on mainspace, Citations, etc. pages
		-- in any case in source() if the language is omitted.
		local lang = get_first_lang(args[1] or args.lang)
		local termlang = args.termlang and get_first_lang(args.termlang) or lang

		local usex_data = {
			lang = lang,
			termlang = termlang,
			usex = text,
			-- We don't supply url here as we handle url= separately.
			sc = sc,
			translation = gloss,
			translationurl = args.turl,
			normalization = norm,
			normsc = normsc,
			normurl = args.normurl,
			transliteration = tr,
			transcription = ts,
			brackets = args.brackets,
			subst = args.subst,
			lit = args.lit,
			liturl = args.liturl,
			footer = args.footer,
			qq = parse_and_format_labels(args.ll, lang),
			quote = "quote-meta",
			orig = origtext,
			origlang = origtextlang,
			origsc = origsc,
			origurl = args.origurl,
			orignorm = args.orignorm,
			orignormsc = orignormsc,
			orignormurl = args.orignormurl,
			origtr = args.origtr,
			origts = args.origts,
			origsubst = args.origsubst,
			origqq = parse_and_format_labels(args.origll, lang),
			noreq = args.noreq,
			nocat = is_cite or args.nocat,
		}

		if args.inline then
			-- don't let usex format the footer, otherwise it gets inlined with the rest of the quoted text
			usex_data.footer = nil
			usex_data.inline = 1

			text = format_usex(usex_data)
			if text then
				text = " “" .. text .. "”"
			else
				text = ""
			end
			if args.footer then
				text = text .. "<dl><dd>" .. args.footer .. "</dd></dl>"
			end
		else
			text = "<dl><dd>" .. format_usex(usex_data) .. "</dd></dl>"
		end
	elseif args.footer then
		text = "<dl><dd>" .. args.footer .. "</dd></dl>"
	end
	return text
end

local function show_quote(frame, args, alias_map, other_controls, deprecated)
	local parts = {}

	insert(parts, '<div class="citation-whole"><span class="cited-source">')
	insert(parts, export.source(args, alias_map, nil, other_controls))
	insert(parts, "</span>")

	insert(parts, get_quote(args))

	insert(parts, "</div>")
	local retval = concat(parts)
	return deprecated and frame:expandTemplate({
			title = "check deprecated lang param usage",
			args = {retval, lang = frame:getParent().args.lang},
		}) or retval
end

--[==[
External interface, meant to be called from a template. Replaces {{tl|quote-meta}} and meant to be the primary
interface for {{tl|quote-*}} templates.
]==]
function export.quote_t(frame)
	local args, alias_map, other_controls, deprecated = get_args(frame.args, frame:getParent().args, "require_lang")
	if args.ascite then
		return export.cite_t(frame)
	end

	return show_quote(frame, args, alias_map, other_controls, deprecated)
end

local function show_cite(args, alias_map, other_controls)
	local parts = {}

	-- don't nag for translations
	if args.text and not args.t then
		args.noreq = 1
	end

	local len_visible = args.text and ulen((args.text:gsub("<[^<>]+>", ""))) or 0
	if len_visible == 0 then
		if not args.t or args.t == "-" then
			args.nocolon = true
		end
	elseif args.inline == nil then
		args.inline = not (
			args.block_text
			or len_visible > 300
			or (args.t and args.t ~= "-" and len_visible < 80)
			or string.match(args.text, "<br>")
		)
	end

	insert(parts, '<span class="citation-whole"><span class="cited-source">')
	insert(parts, export.source(args, alias_map, "format_as_cite", other_controls))
	insert(parts, "</span>")
	insert(parts, get_quote(args, "is_cite"))
	insert(parts, "</span>")

	return concat(parts)
end

--[==[
External interface, meant to be called from a template. Replaces {{tl|cite-meta}} and meant to be the primary
interface for {{tl|cite-*}} templates.
]==]
function export.cite_t(frame)
	local parent_args = {}
	for k, v in pairs(frame:getParent().args) do
		parent_args[k] = v
	end

	-- use "und" as lang if none provided
	if parent_args[1] == nil then
		parent_args[1] = "und"
	end

	local args, alias_map, other_controls, deprecated = get_args(frame.args, parent_args)
	if args.asquote then
		return show_quote(frame, args, alias_map, other_controls, deprecated)
	end

	return show_cite(args, alias_map, other_controls)
end

--[==[
This is a method to call a specified quote or citation template while combining the arguments from the parent template with additional arguments provided directly plus arguments passed by the user. This is useful for dynamically reusing templates with modified or additional parameters.
* The {{para|1}} '''(required)''' the template to overload.
* All other named or numbered parameters will be passed directly to the parent template.
* All user-specified parameters used when calling this template will also be passed through to the parent template and will override any values declared in this template.

====Example 1====

To create a {{tl|R:Cite}} citation formatted equivalent from an existing {{tl|RQ:Quote}} quotation template:
<pre>{{#invoke:quote|overload
    |RQ:Quote
    |ascite=1
}}</pre>

Calling {{tl|R:Cite|page=123}} will display the output of {{tl|RQ:Quote|ascite=1|page=123}}

====Example 2====

To create a {{tl|RQ:Author Work}} "specific work" template from an "all in one" {{tl|RQ:Author}} author template that handles user provided {{para|book}}, {{para|year}}, {{para|chapter}}, and {{para|page}} values:<pre>
{{#invoke:quote|overload
    |RQ:Author
    |book=Storytime
    |year=2010
    |chapter={{{chapter|{{#ifexpr:{{{page|}}}<10 | 1 | 2 }}}}}
}}
</pre>
Calling {{tl|RQ:Author Work|page=20}} would then be the same as calling {{tl|RQ:Author|book=Storytime|year=2010|chapter=2|page=20}}.
]==]
function export.overload(frame)
	local iargs, overloaded_args = process_params(frame.args, {
		[1] = {required = true}
	}, true)

	local parent_args = frame:getParent().args
	for k, v in pairs(parent_args) do
		overloaded_args[k] = v
	end

	return frame:expandTemplate {title = iargs[1], args = overloaded_args}
end

--[==[
This is an interface onto `quote-*` templates such as {{tl|quote-book}} and `cite-*` templates such as {{tl|cite-book}}.
See {{ltl|RQ:Ascham Scholemaster}} for an example. If you write the code the way of this example, it automatically
handles parameters such a {{para|text}}, {{para|passage}}, {{para|footer}}, {{para|brackets}}, {{para|authorlink}} and
several others, and optionally {{para|page}}, {{para|pages}}, {{para|t}}, {{para|tr}}, etc. This means you don't have to
copy them explicitly. In general, any arguments given directly to {{tl|#invoke:quote|call_template}} are passed directly
to the underlying template (usually {{tl|quote-book}}), except for certain ''control parameters'', as detailed below,
and certain other arguments are automatically copied from the outer template (e.g. the call to
{{tl|RQ:Ascham Scholemaster}}) to the implementing template (e.g. {{tl|quote-book}}).

To better understand the workflow of this function, it's important to understand the different sets of parameters
involved. Specifically:
# The parameters specified directly in the {{tl|#invoke:quote|call_template}} call are termed ''direct parameters'' (or
  ''direct arguments''; in general ''parameter'' and ''argument'' are synonymous). These correspond to the `frame.args`
  arguments in Lua.
# The parameters specified in the outer template whose implementation involves invoking `##call_template` are termed the
  ''template parameters'' (or ''parent arguments'', because they correspond to the `frame:getParent().args` arguments in
  Lua).
# The direct and template parameters are combined to form the ''destination parameters'', which are sent to the
  template that implements the quotation or citation (e.g. {{tl|quote-book}} or {{tl|cite-book}}). Conceptually, it is
  exactly as if the Wikicode of the page in question made a direct call to {{tl|quote-book}}, {{tl|cite-book}}, etc.,
  giving the destination parameters as the parameters of that template (and in fact this is effectively how it's
  implemented).
# Among the direct parameters specified in the invocation call, there are two types. The ''control parameters'' are
  those that have a special meaning to the parameter construction process itself. They are intercepted, used in the
  parameter construction process, and not passed on. All remaining parameters are ''pass-through parameters'', which are
  passed directly through to the destination parameters of the implementing template.

The process of constructing the destination parameters involves combining the direct pass-through parameters with the
template parameters to be copied. Only certain template parameters are copied; which ones get copied is controlled by
the control parameters. Any remaining parameters cause an error to be thrown unless the {{para|allowparams}} control
parameter specifically allows them. (These are typically parameters that have a special meaning in constructing the
pass-through parameters, such as a {{para|verse}} parameter for a Bible translation.)

If both a template and direct parameter specify a value for a given destination parameter, the template parameter takes
precedence. Note, however, that blank parameters (both template and direct parameters) are treated as missing, i.e. as
if not given at all, rather than as empty. To cancel out the value of a direct parameter, specify a hyphen (`-`) as its
value in the template.

The control parameters work as follows:
* The following parameters are always copied as-is: {{para|brackets}}, {{para|usenodot}}, {{para|nodot}},
  {{para|ascite}}, {{para|asquote}}, {{para|norm}}~{{para|normalization}}, {{para|normurl}}~{{para|normalizationurl}}
  and {{para|ll}}~{{para|lb}}.
* The {{para|footer}} parameter is automatically copied and surrounded by a call to {{tl|small}}.
* The {{para|template}} control parameter specifies the name of the implementing template to call, defaulting to
  `quote-book`.
* The {{para|textparam}} control parameter controls the copying of the {{para|text}} and {{para|passage}} parameters
  and any synonyms. If not given, {{para|text}} and {{para|passage}} (preferring the former) are passed to the
  {{para|text}} destination parameter. If given, it should be a comma-separated list of parameters that are synonyms for
  {{para|text}}/{{para|passage}}; if neither of these is seen, the specified parameters are copied to the {{para|text}}
  destination parameter (processed from left to right if multiple synonyms are given). Specifying {{para|textparam|-}}
  disables copying of {{para|text}} and {{para|passage}}.
* The {{para|pageparam}} control parameter controls the copying of the {{para|page}} and {{para|pages}} parameters and
  any synonyms. If not given, neither parameter is copied. If given, {{para|page}} and any synonymous parameters
  specified by {{para|pageparam}} (a comma-separated list of parameters) are copied to the {{para|page}} destination
  parameter, and {{para|pages}} is copied to the {{para|pages}} destination parameter. If there are no synonyms for
  {{para|page}}, but the copying behavior is still desired, just specify {{para|pageparam|page}}.
* If the boolean {{para|copyt}} control parameter is true, or if it's unspecified and the language of the quote template
  (from direct argument {{para|1}}) is not English, the following additional translation-related parameters are copied:
  {{para|t}}~{{para|translation}}, {{para|turl}}~{{para|translationurl}}, {{para|lit}} and {{para|liturl}}.
* If the boolean {{para|copytr}} control parameter is true, or if it's unspecified and the text of the quote or cite is
  given and in a script other than Latin, the following transliteration-related parameters are copied:
  {{para|tr}}~{{para|transliteration}} and {{para|subst}}.
* If the boolean {{para|copyts}} control parameter is true, the following transcription-related parameters are
  copied: {{para|ts}}~{{para|transcription}}. Specify this only for languages where {{para|ts}} is used in headwords and
  links (see {{tl|link}}).
* If the boolean {{para|copysc}} control parameter is true, the following script-related parameters are copied:
  {{para|sc}} and {{para|normsc}}. This can be given if the language supports multiple scripts (although note that the
  script is autodetected, which almost always gets it right).
* If the boolean {{para|copyorig}} control parameter is true, the following original-text-related parameters are
  copied: {{para|origtext}}, {{para|origurl}}, {{para|orignorm}}, {{para|orignormurl}} and
  {{para|origll}}~{{para|origlb}}; also {{para|origtr}} and {{para|origsubst}} if {{para|copytr}} is true or the text
  is in a non-Latin script; also {{para|origts}} if {{para|copyts}} is true; and also {{para|origsc}} and
  {{para|orignormsc}} if {{para|copysc}} is true.
* If a value for {{para|author}} is given as a direct parameter, and no value for {{para|authorlink}} is given, and the
  value given for {{para|author}} does not have any links or HTML in it, it is copied to the {{para|authorlink}}
  destination parameter.
* The {{para|copyparams}} control parameter is a comma-separated list of any additional parameters to copy. For example,
  {{para|copyparams|column,volume}} is approximately equivalent to writing
  `<nowiki>|column={{{column|}}}|volume={{{volume|}}}</nowiki>` in the invocation call. Note that you can specify a
  parameter to be copied using {{para|copyparams}} and also specify a direct pass-through value for this parameter. In
  this case, if the user gives a value for that parameter, it is used, otherwise the directly-specified value is used.
  If a parameter value in {{para|copyparams}} contains a `*` in it, it is treated as a wildcard, matching any number of
  characters. For example, {{para|copyparams|chapter*}} will copy `chapter`, `chapters`, `chapter_plain`,
  `chapter_number`, etc., and {{para|copyparams|*sc}} will copy `sc`, `origsc`, `normsc`, etc.
* The {{para|allowparams}} control parameter is a comma-separated list of any additional parameters to allow but not
  copy. This does not need to mention any parameter that is mentioned elsewhere or is copied by any of the mechanisms
  described above. In general you should only use it for parameters that are used to construct direct parameters but not
  themselves copied. An example, from the {{tl|RQ:ang:Aldred Kemble Skeat Lindisfarne}} template:
  * {{para|allowparams|verse,manuscript,book}}
  This is because the template specifies the following among its direct parameters:
  * {{para|chapter_plain|<nowiki>{{#if:{{{verse<includeonly>|</includeonly>}}}|{{{book}}} {{{verse}}} {{#if:{{{manuscript|}}}|({{{manuscript}}})}}}}</nowiki>}}

If you call `##call_template` from Lua code, you should still pass in the invocation frame as the first argument;
use `mw.getCurrentFrame()` if necessary to fetch it. In addition, you can override the direct arguments (which default
to `frame.args`) using the second argument, and override the template (parent) arguments (which default to
`frame:getParent().args`) using the third argument.
]==]
function export.call_template(frame, direct_args, parent_args)
	local parent = frame:getParent()
	parent_args = parent_args or parent.args

	local parameter_sublist = {type = "parameter", sublist = true}
	local boolean_param = {type = "boolean"}
	local iargs, other_direct_args = process_params(direct_args or frame.args, {
		template = true,
		textparam = parameter_sublist,
		pageparam = parameter_sublist,
		copyparams = parameter_sublist,
		propagateparams = {alias_of = "copyparams"},
		allowparams = {sublist = true}, -- Doesn't use type = "parameter", because any that end in :list get processed differently.
		copyt = boolean_param,
		copyorig = boolean_param,
		copysc = boolean_param,
		copytr = boolean_param,
		copyts = boolean_param,
	}, true)

	local function fetch_param(source, params, with_ine)
		for _, param in ipairs(params) do
			local val = source[param]
			if with_ine then
				val = ine(val)
			end
			if val then
				return val
			end
		end
		return nil
	end

	-- Allowed and copied params. The ones listed here directly have special handling.
	local params = {
		["text"] = true,
		["passage"] = true,
		["footer"] = true, -- always copied, but gets special formatting
	}

	local textparam = iargs.textparam or {}
	for _, param in ipairs(textparam) do
		params[param] = true
	end

	local text = ine(parent_args.text) or ine(parent_args.passage)
	if textparam[1] ~= "-" then
		text = text or fetch_param(parent_args, textparam, "with_ine")
		other_direct_args.text = text
	end

	local pageparam = iargs.pageparam or {}
	local pageparam1 = pageparam[1]
	if pageparam1 ~= nil then
		params["page"], params["pages"] = true, true
		for _, param in ipairs(pageparam) do
			params[param] = true
		end
	end

	-- Parameters that can be used during template declaration or included in template calls.
	-- If the template is called with param=- it will set any declared value to nil.
	local params_to_copy = {"brackets", "usenodot", "nodot", "ascite", "asquote",
		"norm", "normalization", "normurl", "normalizationurl", "ll", "lb",
	}
	local langparam
	local langcode = ine(other_direct_args[1])
	if langcode then
		langparam = 1
	end
	if not langcode then
		langparam = true
		langcode = "und"
	end
	langcode = langcode:gsub("%s*,.*", "")
	local lang = get_lang(langcode, langparam, "allow etym")
	local copyt = iargs.copyt
	if copyt == nil and not ine(other_direct_args.t) and not ine(other_direct_args.translation) then
		-- Don't default copyt to true if t= or translation= given in direct args to avoid alias errors.
		copyt = langcode ~= "en"
	end
	if copyt then
		require(table_module).extend(params_to_copy, {"t", "translation", "turl", "translationurl", "lit", "liturl"})
	end
	local copytr = iargs.copytr
	if copytr == nil and text and not ine(other_direct_args.tr) and not ine(other_direct_args.transliteration) then
		-- Don't default copytr to true if tr= or transliteration= given in direct args to avoid alias errors.
		copytr = lang:findBestScript(text):getCode() ~= "Latn"
	end
	if copytr then
		require(table_module).extend(params_to_copy, {"tr", "transliteration", "subst"})
	end
	if iargs.copyts then
		require(table_module).extend(params_to_copy, {"ts", "transcription"})
	end
	if iargs.copysc then
		require(table_module).extend(params_to_copy, {"sc", "normsc"})
	end
	if iargs.copyorig then
		require(table_module).extend(params_to_copy, {"origtext", "origurl", "orignorm", "orignormurl", "origll", "origlb"})
		if copytr then
			require(table_module).extend(params_to_copy, {"origtr", "origsubst"})
		end
		if iargs.copyts then
			require(table_module).extend(params_to_copy, {"origts"})
		end
		if iargs.copysc then
			require(table_module).extend(params_to_copy, {"origsc", "orignormsc"})
		end
	end
	for _, param in ipairs(params_to_copy) do
		params[param] = true
	end

	local function param_pattern_to_lua_pattern(pattern)
		-- Hyphen should match a literal hyphen. `*` should match any number of characters.
		return "^" .. (pattern:gsub("%-", "%%-"):gsub("%*", ".*")) .. "$"
	end

	local allowparams, allow_all = iargs.allowparams, false
	local list
	local allow_patterns = {}
	if allowparams ~= nil then
		for _, allow in ipairs(allowparams) do
			local param = allow:match("^(.*):list$")
			if param then
				if list == nil then
					list = {list = true}
				end
				params[scribunto_parameter_key(param)] = list
			elseif allow == "*" then
				track("no parameter checking")
				allow_all = true
			elseif allow:find("%*") then
				insert(allow_patterns, param_pattern_to_lua_pattern(allow))
			else
				params[scribunto_parameter_key(allow)] = true
			end
		end
	else
		local template_name = parent:getTitle()
		local template_title = new_title(template_name)
		local content = template_title:getContent()
		local seen = {}
		-- Detect all params used by the parent template. param:get_name() takes the
		-- parent frame arg table as an argument so that preprocessing will take
		-- them into account, since it will matter if the name contains another
		-- parameter (e.g. the outer param in "{{{foo{{{bar}}}baz}}}" will change
		-- depending on the value for bar=). `seen` memoizes results based on the
		-- raw parameter text (which is stored as a string in the parameter object),
		-- which avoids unnecessary param:get_name() calls, which are non-trivial.
		for param in find_parameters(content) do
			local raw = param.raw
			if not seen[raw] then
				local allow = param:get_name(parent_args)
				params[scribunto_parameter_key(allow)] = true
				seen[raw] = true
			end
		end
	end

	local copy_patterns = {}
	local copyparams = iargs.copyparams or {}
	for _, param in ipairs(copyparams) do
		if type(param) == "string" and param:find("%*") then
			insert(copy_patterns, param_pattern_to_lua_pattern(param))
		else
			params[param] = true
		end
	end

	local function param_matches_patterns(name, patterns)
		for _, pattern in ipairs(patterns) do
			if type(name) == "string" and name:find(pattern) then
				return true
			end
		end
		return nil
	end

	local allow_params = nil
	if allow_patterns[1] or copy_patterns[1] then
		allow_params = function(name)
			if allow_patterns[1] then
				if param_matches_patterns(name, allow_patterns) then
					return true
				end
			end
			if copy_patterns[1] then
				if param_matches_patterns(name, copy_patterns) then
					return true
				end
			end
			return nil
		end
	end

	local args = process_params(parent_args, params, {
		return_unknown = allow_all,
		allow_params = allow_params,
	})

	if not (pageparam1 == nil or pageparam1 == "-") then
		other_direct_args.page = fetch_param(args, pageparam) or args.page or other_direct_args.page or nil
		other_direct_args.pages = args.pages or other_direct_args.pages or nil
		if other_direct_args.page == "-" then
			other_direct_args.page = nil
		end
		if other_direct_args.pages == "-" then
			other_direct_args.pages = nil
		end
	end
	if args.footer then
		other_direct_args.footer = frame:expandTemplate {title = "small", args = {args.footer}}
	end
	for _, param in ipairs(params_to_copy) do
		if args[param] == "-" then
			other_direct_args[param] = nil
		else
			other_direct_args[param] = args[param] or other_direct_args[param] or nil
		end
	end


	-- authorlink=- can be used to prevent copying of author= to authorlink= but we don't want to copy this to
	-- the actual {{quote-*}} code.
	if other_direct_args.authorlink == "-" then
		other_direct_args.authorlink = nil
	end
	for _, param in ipairs(copyparams) do
		if args[param] then
			other_direct_args[param] = args[param]
		end
	end
	for param, value in pairs(args) do
		if param_matches_patterns(param, copy_patterns) then
			other_direct_args[param] = value
		end
	end

	return frame:expandTemplate {title = iargs.template or "quote-book", args = other_direct_args}
end

--[==[
Older entry point for call_quote_template; FIXME: convert callers.
]==]
function export.call_quote_template(frame)
	track("call_quote_template")
    return export.call_template(frame)
end

local paramdoc_param_replacements = {
	passage = {
		param_with_synonym = "<<synonym>>, {{para|text}}, or {{para|passage}}",
		param_no_synonym = "{{para|text}} or {{para|passage}}",
		text = [=[
* <<params>> – the passage to be quoted.]=],
	},
	page = {
		param_with_synonym = "<<synonym>> or {{para|page}}, or {{para|pages}}",
		param_no_synonym = "{{para|page}} or {{para|pages}}",
		text = [=[
* <<params>> – '''mandatory in some cases''': the page number(s) quoted from. When quoting a range of pages, note the following:
** Separate the first and last pages of the range with an [[en dash]], like this: {{para|pages|10–11}}.
** You must also use {{para|pageref}} to indicate the page to be linked to (usually the page on which the Wiktionary entry appears).
: This parameter must be specified to have the template link to the online version of the work.]=],
	},
	page_with_roman_preface = {
		param_with_synonym = {"inherit", "page"},
		param_no_synonym = {"inherit", "page"},
		text = [=[
* <<params>> – '''mandatory in some cases''': the page number(s) quoted from. If quoting from the preface, specify the page number(s) in lowercase Roman numerals. When quoting a range of pages, note the following:
** Separate the first and last page number of the range with an [[en dash]], like this: {{para|pages|10–11}} or {{para|pages|iii–iv}}.
** You must also use {{para|pageref}} to indicate the page to be linked to (usually the page on which the Wiktionary entry appears).
: This parameter must be specified to have the template link to the online version of the work.]=],
	},
	chapter = {
		param_with_synonym = "<<synonym>> or {{para|chapter}}",
		param_no_synonym = "{{para|chapter}}",
		text = [=[
* <<params>> – the name of the chapter quoted from.]=],
	},
	roman_chapter = {
		param_with_synonym = {"inherit", "chapter"},
		param_no_synonym = {"inherit", "chapter"},
		text = [=[
* <<params>> – the chapter number quoted from in uppercase Roman numerals.]=],
	},
	arabic_chapter = {
		param_with_synonym = {"inherit", "chapter"},
		param_no_synonym = {"inherit", "chapter"},
		text = [=[
* <<params>> – the chapter number quoted from in Arabic numerals.]=],
	},
	trailing_params = {
		text = [=[
* {{para|footer}} – a comment on the passage quoted.
* {{para|brackets}} – use {{para|brackets|on}} to surround a quotation with [[bracket#Noun|brackets]]. This indicates that the quotation either contains a mere mention of a term (for example, “some people find the word '''''manoeuvre''''' hard to spell”) rather than an actual use of it (for example, “we need to '''manoeuvre''' carefully to avoid causing upset”), or does not provide an actual instance of a term but provides information about related terms.]=],
	},
}

function export.paramdoc(frame)
	local parargs = frame:getParent().args
	local args = process_params(parargs, {
		[1] = true,
	})

	local text = args[1]

	local function do_param_with_optional_synonym(param, text_to_sub, paramtext_synonym, paramtext_no_synonym)
		local function sub_param(synonym)
			local subbed_paramtext
			if synonym then
				subbed_paramtext = paramtext_synonym:gsub("<<synonym>>", "{{para|" .. replacement_escape(synonym) .. "}}")
			else
				subbed_paramtext = paramtext_no_synonym
			end
			return frame:preprocess((text_to_sub:gsub("<<params>>", replacement_escape(subbed_paramtext))))
		end
		text = text:gsub("<<" .. pattern_escape(param) .. ">>", function()
			return sub_param()
		end)
		text = text:gsub("<<" .. pattern_escape(param) .. ":(.-)>>", sub_param)
	end

	local function fetch_text(param_to_replace, key)
		local spec = paramdoc_param_replacements[param_to_replace]
		local val = spec[key]
		if type(val) == "string" then
			return val
		end
		if type(val) == "table" and val[1] == "inherit" then
			return fetch_text(val[2], key)
		end
		error(
			"Internal error: Unrecognized value for param '"
				.. param_to_replace
				.. "', key '"
				.. key
				.. "': "
				.. mw.dumpObject(val)
		)
	end

	for param_to_replace, spec in pairs(paramdoc_param_replacements) do
		if not spec.param_no_synonym then
			-- Text to substitute directly.
			text = text:gsub("<<" .. pattern_escape(param_to_replace) .. ">>", function()
				return frame:preprocess(fetch_text(param_to_replace, "text"))
			end)
		else
			do_param_with_optional_synonym(
				param_to_replace,
				fetch_text(param_to_replace, "text"),
				fetch_text(param_to_replace, "param_with_synonym"),
				fetch_text(param_to_replace, "param_no_synonym")
			)
		end
	end

	-- Remove final newline so template code can add a newline after invocation
	text = text:gsub("\n$", "")
	return text
end

return export
