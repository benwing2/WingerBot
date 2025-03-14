local export = {}

-- Named constants for all modules used, to make it easier to swap out sandbox versions.
local debug_track_module = "Module:debug/track"
local en_utilities_module = "Module:en-utilities"
local gender_and_number_module = "Module:gender and number"
local headword_data_module = "Module:headword/data"
local headword_page_module = "Module:headword/page"
local links_module = "Module:links"
local load_module = "Module:load"
local pages_module = "Module:pages"
local palindromes_module = "Module:palindromes"
local pron_qualifier_module = "Module:pron qualifier"
local scripts_module = "Module:scripts"
local scripts_data_module = "Module:scripts/data"
local script_utilities_module = "Module:script utilities"
local script_utilities_data_module = "Module:script utilities/data"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local utilities_module = "Module:utilities"

local concat = table.concat
local insert = table.insert
local ipairs = ipairs
local max = math.max
local new_title = mw.title.new
local pairs = pairs
local require = require
local toNFC = mw.ustring.toNFC
local toNFD = mw.ustring.toNFD
local type = type
local ufind = mw.ustring.find
local ugmatch = mw.ustring.gmatch
local ugsub = mw.ustring.gsub
local umatch = mw.ustring.match

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
	local function debug_track(...)
		debug_track = require(debug_track_module)
		return debug_track(...)
	end

	local function encode_entities(...)
		encode_entities = require(string_utilities_module).encode_entities
		return encode_entities(...)
	end

	local function find_best_script_without_lang(...)
		find_best_script_without_lang = require(scripts_module).findBestScriptWithoutLang
		return find_best_script_without_lang(...)
	end

	local function format_categories(...)
		format_categories = require(utilities_module).format_categories
		return format_categories(...)
	end

	local function format_genders(...)
		format_genders = require(gender_and_number_module).format_genders
		return format_genders(...)
	end

	local function format_pron_qualifiers(...)
		format_pron_qualifiers = require(pron_qualifier_module).format_qualifiers
		return format_pron_qualifiers(...)
	end

	local function full_link(...)
		full_link = require(links_module).full_link
		return full_link(...)
	end

	local function get_current_L2(...)
		get_current_L2 = require(pages_module).get_current_L2
		return get_current_L2(...)
	end

	local function get_link_page(...)
		get_link_page = require(links_module).get_link_page
		return get_link_page(...)
	end

	local function get_script(...)
		get_script = require(scripts_module).getByCode
		return get_script(...)
	end

	local function is_palindrome(...)
		is_palindrome = require(palindromes_module).is_palindrome
		return is_palindrome(...)
	end

	local function language_link(...)
		language_link = require(links_module).language_link
		return language_link(...)
	end

	local function load_data(...)
		load_data = require(load_module).load_data
		return load_data(...)
	end

	local function pattern_escape(...)
		pattern_escape = require(string_utilities_module).pattern_escape
		return pattern_escape(...)
	end

	local function pluralize(...)
		pluralize = require(en_utilities_module).pluralize
		return pluralize(...)
	end

	local function process_page(...)
		process_page = require(headword_page_module).process_page
		return process_page(...)
	end

	local function remove_links(...)
		remove_links = require(links_module).remove_links
		return remove_links(...)
	end

	local function shallow_copy(...)
		shallow_copy = require(table_module).shallowCopy
		return shallow_copy(...)
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

	local function trim(...)
		trim = require(string_utilities_module).trim
		return trim(...)
	end

	local function ulen(...)
		ulen = require(string_utilities_module).len
		return ulen(...)
	end

--[==[
Loaders for objects, which load data (or some other object) into some variable, which can then be accessed as "foo or get_foo()", where the function get_foo sets the object to "foo" and then returns it. This ensures they are only loaded when needed, and avoids the need to check for the existence of the object each time, since once "foo" has been set, "get_foo" will not be called again.]==]
	local m_data
	local function get_data()
		m_data = load_data(headword_data_module)
		return m_data
	end

	local script_data
	local function get_script_data()
		script_data = load_data(scripts_data_module)
		return script_data
	end

	local script_utilities_data
	local function get_script_utilities_data()
		script_utilities_data = load_data(script_utilities_data_module)
		return script_utilities_data
	end

-- If set to true, categories always appear, even in non-mainspace pages
local test_force_categories = false

-- Add a tracking category to track entries with certain (unusually undesirable) properties. `track_id` is an identifier
-- for the particular property being tracked and goes into the tracking page. Specifically, this adds a link in the
-- page text to [[Wiktionary:Tracking/headword/TRACK_ID]], meaning you can find all entries with the `track_id` property
-- by visiting [[Special:WhatLinksHere/Wiktionary:Tracking/headword/TRACK_ID]].
--
-- If `lang` (a language object) is given, an additional tracking page [[Wiktionary:Tracking/headword/TRACK_ID/CODE]] is
-- linked to where CODE is the language code of `lang`, and you can find all entries in the combination of `track_id`
-- and `lang` by visiting [[Special:WhatLinksHere/Wiktionary:Tracking/headword/TRACK_ID/CODE]]. This makes it possible to
-- isolate only the entries with a specific tracking property that are in a given language. Note that if `lang`
-- references at etymology-only language, both that language's code and its full parent's code are tracked.
local function track(track_id, lang)
	local tracking_page = "headword/" .. track_id
	if lang and lang:hasType("etymology-only") then
		debug_track{tracking_page, tracking_page .. "/" .. lang:getCode(),
			tracking_page .. "/" .. lang:getFullCode()}
	elseif lang then
		debug_track{tracking_page, tracking_page .. "/" .. lang:getCode()}
	else
		debug_track(tracking_page)
	end
	return true
end


local function text_in_script(text, script_code)
	local sc = get_script(script_code)
	if not sc then
		error("Internal error: Bad script code " .. script_code)
	end
	local characters = sc.characters

	local out
	if characters then
		text = ugsub(text, "%W", "")
		out = ufind(text, "[" .. characters .. "]")
	end

	if out then
		return true
	else
		return false
	end
end


local spacingPunctuation = "[%s%p]+"
--[[ List of punctuation or spacing characters that are found inside of words.
	 Used to exclude characters from the regex above. ]]
local wordPunc = "-#%%&@־׳״'.·*’་•:᠊"
local notWordPunc = "[^" .. wordPunc .. "]+"


-- Format a term (either a head term or an inflection term) along with any left or right qualifiers, labels, references
-- or customized separator: `part` is the object specifying the term (and `lang` the language of the term), which should
-- optionally contain:
-- * left qualifiers in `q`, an array of strings;
-- * right qualifiers in `qq`, an array of strings;
-- * left labels in `l`, an array of strings;
-- * right labels in `ll`, an array of strings;
-- * references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
--   (formatted reference text) and optionally `name` and/or `group`;
-- * a separator in `separator`, defaulting to " <i>or</i> " if this is not the first term (j > 1), otherwise "".
-- `formatted` is the formatted version of the term itself, and `j` is the index of the term.

local function format_term_with_qualifiers_and_refs(lang, part, formatted, j)
	local function part_non_empty(field)
		local list = part[field]
		if not list then
			return nil
		end
		if type(list) ~= "table" then
			error(("Internal error: Wrong type for `part.%s`=%s, should be \"table\""):format(field, mw.dumpObject(list)))
		end
		return list[1]
	end

	if part_non_empty("q") or part_non_empty("qq") or part_non_empty("l") or
		part_non_empty("ll") or part_non_empty("refs") then
		formatted = format_pron_qualifiers {
			lang = lang,
			text = formatted,
			q = part.q,
			qq = part.qq,
			l = part.l,
			ll = part.ll,
			refs = part.refs,
		}
	end

	local separator = part.separator or j > 1 and " <i>or</i> " -- use "" to request no separator

	if separator then
		formatted = separator .. formatted
	end

	return formatted
end


--[==[Return true if the given head is multiword according to the algorithm used in full_headword().]==]
function export.head_is_multiword(head)
	for possibleWordBreak in ugmatch(head, spacingPunctuation) do
		if umatch(possibleWordBreak, notWordPunc) then
			return true
		end
	end

	return false
end

do
	local function workaround_to_exclude_chars(s)
		return (ugsub(s, notWordPunc, "\2%1\1"))
	end

	--[==[Add links to a multiword head.]==]
	function export.add_multiword_links(head, default)
		head = "\1" .. ugsub(head, spacingPunctuation, workaround_to_exclude_chars) .. "\2"
		if default then
			head = head
				:gsub("(\1[^\2]*)\\([:#][^\2]*\2)", "%1\\\\%2")
				:gsub("(\1[^\2]*)([:#][^\2]*\2)", "%1\\%2")
		end

		--Escape any remaining square brackets to stop them breaking links (e.g. "[citation needed]").
		head = encode_entities(head, "[]", true, true)

		--[=[
		use this when workaround is no longer needed:

		head = "[[" .. ugsub(head, WORDBREAKCHARS, "]]%1[[") .. "]]"

		Remove any empty links, which could have been created above
		at the beginning or end of the string.
		]=]
		return (head
			:gsub("\1\2", "")
			:gsub("[\1\2]", {["\1"] = "[[", ["\2"] = "]]"}))
	end
end


local function non_categorizable(full_raw_pagename)
	return full_raw_pagename:find("^Appendix:Gestures/") or
		-- Unsupported titles with descriptive names.
		(full_raw_pagename:find("^Unsupported titles/") and not full_raw_pagename:find("`"))
end

local function tag_text_and_add_quals_and_refs(data, head, formatted, j)
	-- Add language and script wrapper.
	formatted = tag_text(formatted, data.lang, head.sc, "head", nil, j == 1 and data.id or nil)
	-- Add qualifiers, labels, references and separator.
	return format_term_with_qualifiers_and_refs(data.lang, head, formatted, j)
end

-- Format a headword with transliterations.
local function format_headword(data)
	-- Are there non-empty transliterations?
	local has_translits = false
	local has_manual_translits = false

	------ Format the headwords. ------

	local head_parts = {}
	local unique_head_parts = {}

	local has_multiple_heads = #data.heads > 1

	for j, head in ipairs(data.heads) do
		if head.tr or head.ts then
			has_translits = true
		end
		if head.tr and head.tr_manual or head.ts then
			has_manual_translits = true
		end

		local formatted

		-- Apply processing to the headword, for formatting links and such.
		if head.term:find("[[", nil, true) and head.sc:getCode() ~= "Image" then
			formatted = language_link{term = head.term, lang = data.lang}
		else
			formatted = data.lang:makeDisplayText(head.term, head.sc, true)
		end

		local head_part = tag_text_and_add_quals_and_refs(data, head, formatted, j)
		insert(head_parts, head_part)

		-- If multiple heads, try to determine whether all heads display the same. To do this we need to effectively
		-- rerun the text tagging and addition of qualifiers and references, using 1 for all indices.
		if has_multiple_heads then
			local unique_head_part
			if j == 1 then
				unique_head_part = head_part
			else
				unique_head_part = tag_text_and_add_quals_and_refs(data, head, formatted, 1)
			end
			unique_head_parts[unique_head_part] = true
		end
	end

	local set_size = 0
	if has_multiple_heads then
		for _ in pairs(unique_head_parts) do
			set_size = set_size + 1
		end
	end
	if set_size == 1 then
		head_parts = head_parts[1]
	else
		head_parts = concat(head_parts)
	end

	if has_manual_translits then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/has-manual-translit]]
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/has-manual-translit/LANGCODE]]
		track("has-manual-translit", data.lang)
	end

	------ Format the transliterations and transcriptions. ------

	local translits_formatted

	if has_translits then
		local translit_parts = {}
		for _, head in ipairs(data.heads) do
			if head.tr or head.ts then
				local this_parts = {}
				if head.tr then
					insert(this_parts, tag_translit(head.tr, data.lang:getCode(), "head", nil, head.tr_manual))
					if head.ts then
						insert(this_parts, " ")
					end
				end
				if head.ts then
					insert(this_parts, "/" .. tag_transcription(head.ts, data.lang:getCode(), "head") .. "/")
				end
				insert(translit_parts, concat(this_parts))
			end
		end

		translits_formatted = " (" .. concat(translit_parts, " <i>or</i> ") .. ")"

		local langname = data.lang:getCanonicalName()
		local transliteration_page = new_title(langname .. " transliteration", "Wiktionary")
		local saw_translit_page = false

		if transliteration_page and transliteration_page.exists then
			translits_formatted = " [[Wiktionary:" .. langname .. " transliteration|•]]" .. translits_formatted
			saw_translit_page = true
		end
		-- If data.lang is an etymology-only language and we didn't find a translation page for it, fall back to the
		-- full parent.
		if not saw_translit_page and data.lang:hasType("etymology-only") then
			langname = data.lang:getFullName()
			transliteration_page = new_title(langname .. " transliteration", "Wiktionary")

			if transliteration_page and transliteration_page.exists then
				translits_formatted = " [[Wiktionary:" .. langname .. " transliteration|•]]" .. translits_formatted
			end
		end
	else
		translits_formatted = ""
	end

	------ Paste heads and transliterations/transcriptions. ------

	local lemma_gloss
	if data.gloss then
		lemma_gloss = ' <span class="ib-content qualifier-content">' .. data.gloss .. '</span>'
	else
		lemma_gloss = ""
	end

	return head_parts .. translits_formatted .. lemma_gloss
end


local function format_headword_genders(data)
	local retval = ""
	if data.genders and #data.genders > 0 then
		if data.gloss then
			retval = ","
		end
		local pos_for_cat
		if not data.nogendercat then
			local no_gender_cat = (m_data or get_data()).no_gender_cat
			if not (no_gender_cat[data.lang:getCode()] or no_gender_cat[data.lang:getFullCode()]) then
				pos_for_cat = (m_data or get_data()).pos_for_gender_number_cat[data.pos_category:gsub("^reconstructed ", "")]
			end
		end
		local text, cats = format_genders(data.genders, data.lang, pos_for_cat)
		for _, cat in ipairs(cats) do
			insert(data.categories, cat)
		end
		retval = retval .. "&nbsp;" .. text
	end
	return retval
end


local function format_inflection_parts(data, parts)
	local any_part_translit = false

	for j, part in ipairs(parts) do
		if type(part) ~= "table" then
			part = {term = part}
		end

		local partaccel = part.accel
		local face = part.face or "bold"
		if face ~= "bold" and face ~= "plain" and face ~= "hypothetical" then
			error("The face `" .. face .. "` " .. (
				(script_utilities_data or get_script_utilities_data()).faces[face] and
				"should not be used for non-headword terms on the headword line." or
				"is invalid."
			))
		end

		-- Here the final part 'or data.nolinkinfl' allows to have 'nolinkinfl=true'
		-- right into the 'data' table to disable inflection links of the entire headword
		-- when inflected forms aren't entry-worthy, e.g.: in Vulgar Latin
		local nolinkinfl = part.face == "hypothetical" or (part.nolink and track("nolink") or part.nolinkinfl) or (
			data.nolink and track("nolink") or data.nolinkinfl)

		local formatted
		if part.label then
			-- FIXME: There should be a better way of italicizing a label. As is, this isn't customizable.
			formatted = "<i>" .. part.label .. "</i>"
		else
			-- Convert the term into a full link. Don't show a transliteration here unless enable_auto_translit is
			-- requested, either at the `parts` level (i.e. per inflection) or at the `data.inflections` level (i.e.
			-- specified for all inflections). This is controllable in {{head}} using autotrinfl=1 for all inflections,
			-- or fNautotr=1 for an individual inflection (remember that a single inflection may be associated with
			-- multiple terms). The reason for doing this is to avoid clutter in headword lines by default in languages
			-- where the script is relatively straightforward to read by learners (e.g. Greek, Russian), but allow it
			-- to be enabled in languages with more complex scripts (e.g. Arabic).
			local tr = part.translit or (not (parts.enable_auto_translit or data.inflections.enable_auto_translit) and "-" or nil)
			if tr ~= "-" then
				any_part_translit = true
			end
			formatted = full_link(
				{
					term = not nolinkinfl and part.term or nil,
					alt = part.alt or (nolinkinfl and part.term or nil),
					lang = part.lang or data.lang,
					sc = part.sc or parts.sc or nil,
					gloss = part.gloss,
					pos = part.pos,
					lit = part.lit,
					id = part.id,
					genders = part.genders,
					tr = tr,
					ts = part.transcription,
					accel = partaccel or parts.accel,
				},
				face
				)
		end

		parts[j] = format_term_with_qualifiers_and_refs(part.lang or data.lang, part,
			formatted, j)
	end

	local parts_output

	if #parts > 0 then
		parts_output = (parts.label and " " or "") .. concat(parts)
	elseif parts.request then
		parts_output = " <small>[please provide]</small>"
		insert(data.categories, "Requests for inflections in " .. data.lang:getFullName() .. " entries")
	else
		parts_output = ""
	end

	local parts_label = parts.label and ("<i>" .. parts.label .. "</i>") or ""
	return parts_label .. parts_output, any_part_translit
end


-- Format the inflections following the headword.
local function format_inflections(data)
	local any_part_translit = false
	if data.inflections and #data.inflections > 0 then
		-- Format each inflection individually.
		for key, infl in ipairs(data.inflections) do
			local this_any_part_translit
			data.inflections[key], this_any_part_translit = format_inflection_parts(data, infl)
			if this_any_part_translit then
				any_part_translit = true
			end
		end

		local concat_result = concat(data.inflections, ", ")
		return " (" .. concat_result .. ")"
	else
		return ""
	end
end

--[==[
Returns the plural form of `pos`, a raw part of speech input, which could be singular or
plural. Irregular plural POS are taken into account (e.g. "kanji" pluralizes to
"kanji").
]==]
function export.pluralize_pos(pos)
	-- Make the plural form of the part of speech
	return (m_data or get_data()).irregular_plurals[pos] or
		pos:sub(-1) == "s" and pos or
		pluralize(pos)
end

--[==[
Return "lemma" if the given POS is a lemma, "non-lemma form" if a non-lemma form, or nil
if unknown. The POS passed in must be in its plural form ("nouns", "prefixes", etc.).
If you have a POS in its singular form, call {export.pluralize_pos()} above to pluralize it
in a smart fashion that knows when to add "-s" and when to add "-es", and also takes
into account any irregular plurals.

If `best_guess` is given and the POS is in neither the lemma nor non-lemma list, guess
based on whether it ends in " forms"; otherwise, return nil.
]==]
function export.pos_lemma_or_nonlemma(plpos, best_guess)
	local isLemma = (m_data or get_data()).lemmas
	-- Is it a lemma category?
	if isLemma[plpos] then
		return "lemma"
	end
	local plpos_no_recon = plpos:gsub("^reconstructed ", "")
	if isLemma[plpos_no_recon] then
		return "lemma"
	end
	-- Is it a nonlemma category?
	local isNonLemma = (m_data or get_data()).nonlemmas
	if isNonLemma[plpos] or isNonLemma[plpos_no_recon] then
		return "non-lemma form"
	end
	local plpos_no_mut = plpos:gsub("^mutated ", "")
	if isLemma[plpos_no_mut] or isNonLemma[plpos_no_mut] then
		return "non-lemma form"
	elseif best_guess then
		return plpos:find(" forms$") and "non-lemma form" or "lemma"
	else
		return nil
	end
end

--[==[
Canonicalize a part of speech as specified in 2= in {{tl|head}}. This checks for POS aliases and non-lemma form
aliases ending in 'f', and then pluralizes if the POS term does not have an invariable plural.
]==]
function export.canonicalize_pos(pos)
	-- FIXME: Temporary code to throw an error for alias 'pre' (= preposition) that will go away.
	if pos == "pre" then
		-- Don't throw error on 'pref' as it's an alias for "prefix".
		error("POS 'pre' for 'preposition' no longer allowed as it's too ambiguous; use 'prep'")
	end
	-- Likewise for pro = pronoun.
	if pos == "pro" or pos == "prof" then
		error("POS 'pro' for 'pronoun' no longer allowed as it's too ambiguous; use 'pron'")
	end
	local data = m_data or get_data()
	if data.pos_aliases[pos] then
		pos = data.pos_aliases[pos]
	elseif pos:sub(-1) == "f" then
		pos = pos:sub(1, -2)
		pos = (data.pos_aliases[pos] or pos) .. " forms"
	end
	return export.pluralize_pos(pos)
end

-- Find and return the maximum index in the array `data[element]` (which may have gaps in it), and initialize it to a
-- zero-length array if unspecified. Check to make sure all keys are numeric (other than "maxindex", which is set by
-- [[Module:parameters]] for list parameters), all values are strings, and unless `allow_blank_string` is given,
-- no blank (zero-length) strings are present.
local function init_and_find_maximum_index(data, element, allow_blank_string)
	local maxind = 0
	if not data[element] then
		data[element] = {}
	end
	local typ = type(data[element])
	if typ ~= "table" then
		error(("In full_headword(), `data.%s` must be an array but is a %s"):format(element, typ))
	end
	for k, v in pairs(data[element]) do
		if k ~= "maxindex" then
			if type(k) ~= "number" then
				error(("Unrecognized non-numeric key '%s' in `data.%s`"):format(k, element))
			end
			if k > maxind then
				maxind = k
			end
			if v then
				if type(v) ~= "string" then
					error(("For key '%s' in `data.%s`, value should be a string but is a %s"):format(k, element, type(v)))
				end
				if not allow_blank_string and v == "" then
					error(("For key '%s' in `data.%s`, blank string not allowed; use 'false' for the default"):format(k, element))
				end
			end
		end
	end
	return maxind
end

--[==[
-- Add the page to various maintenance categories for the language and the
-- whole page. These are placed in the headword somewhat arbitrarily, but
-- mainly because headword templates are mandatory for entries (meaning that
-- in theory it provides full coverage).
-- 
-- This is provided as an external entry point so that modules which transclude
-- information from other entries (such as {{tl|ja-see}}) can take advantage
-- of this feature as well, because they are used in place of a conventional
-- headword template.]==]
do
	-- Handle any manual sortkeys that have been specified in raw categories
	-- by tracking if they are the same or different from the automatically-
	-- generated sortkey, so that we can track them in maintenance
	-- categories.
	local function handle_raw_sortkeys(tbl, sortkey, page, lang, lang_cats)
		sortkey = sortkey or lang:makeSortKey(page.pagename)
		-- If there are raw categories with no sortkey, then they will be
		-- sorted based on the default MediaWiki sortkey, so we check against
		-- that.
		if tbl == true then
			if page.raw_defaultsort ~= sortkey then
				insert(lang_cats, lang:getFullName() .. " terms with non-redundant non-automated sortkeys")
			end
			return
		end
		local redundant, different
		for k in pairs(tbl) do
			if k == sortkey then
				redundant = true
			else
				different = true
			end
		end
		if redundant then
			insert(lang_cats, lang:getFullName() .. " terms with redundant sortkeys")
		end
		if different then
			insert(lang_cats, lang:getFullName() .. " terms with non-redundant non-automated sortkeys")
		end
		return sortkey
	end

	function export.maintenance_cats(page, lang, lang_cats, page_cats)
		for _, cat in ipairs(page.cats) do
			insert(page_cats, cat)
		end
		lang = lang:getFull() -- since we are just generating categories
		local canonical = lang:getCanonicalName()
		local tbl, sortkey = page.wikitext_topic_cat[lang:getCode()]
		if tbl then
			sortkey = handle_raw_sortkeys(tbl, sortkey, page, lang, lang_cats)
			insert(lang_cats, canonical .. " entries with topic categories using raw markup")
		end
		tbl = page.wikitext_langname_cat[canonical]
		if tbl then
			handle_raw_sortkeys(tbl, sortkey, page, lang, lang_cats)
			insert(lang_cats, canonical .. " entries with language name categories using raw markup")
		end
		if get_current_L2() ~= canonical then
			insert(lang_cats, canonical .. " entries with incorrect language header")
			-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/incorrect language header]]
			-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/incorrect language header/LANGCODE]]
			track("incorrect language header", lang)
		end
	end
end


--[==[This is the primary external entry point.
{{lua|full_headword(data)}}
This is used by {{temp|head}} and various language-specific headword templates (e.g. {{temp|ru-adj}} for Russian adjectives, {{temp|de-noun}} for German nouns, etc.) to display an entire headword line.
See [[#Further explanations for full_headword()]]
]==]
function export.full_headword(data)
	-- Prevent data from being destructively modified.
	local data = shallow_copy(data)

	------------ 1. Basic checks for old-style (multi-arg) calling convention. ------------

	if data.getCanonicalName then
		error("In full_headword(), the first argument `data` needs to be a Lua object (table) of properties, not a language object")
	end

	if not data.lang or type(data.lang) ~= "table" or not data.lang.getCode then
		error("In full_headword(), the first argument `data` needs to be a Lua object (table) and `data.lang` must be a language object")
	end

	if data.id and type(data.id) ~= "string" then
		error("The id in the data table should be a string.")
	end

	------------ 2. Initialize pagename etc. ------------

	local langcode = data.lang:getCode()
	local full_langcode = data.lang:getFullCode()
	local langname = data.lang:getCanonicalName()
	local full_langname = data.lang:getFullName()

	local raw_pagename, page = data.pagename
	if raw_pagename and raw_pagename ~= (m_data or get_data()).pagename then -- for testing, doc pages, etc.
		page = process_page(raw_pagename)
	else
		page = (m_data or get_data()).page
	end

	-- Check the namespace against the language type.
	local namespace = page.namespace
	if namespace == "" then
		if data.lang:hasType("reconstructed") then
			error("Entries in " .. langname .. " must be placed in the Reconstruction: namespace")
		elseif data.lang:hasType("appendix-constructed") then
			error("Entries in " .. langname .. " must be placed in the Appendix: namespace")
		end
	elseif namespace == "Citations" or namespace == "Thesaurus" then
		error("Headword templates should not be used in the " .. namespace .. ": namespace.")
	end

	------------ 3. Initialize `data.heads` table; if old-style, convert to new-style. ------------

	if type(data.heads) == "table" and type(data.heads[1]) == "table" then
		-- new-style
		if data.translits or data.transcriptions then
			error("In full_headword(), if `data.heads` is new-style (array of head objects), `data.translits` and `data.transcriptions` cannot be given")
		end
	else
		-- convert old-style `heads`, `translits` and `transcriptions` to new-style
		local maxind = max(
			init_and_find_maximum_index(data, "heads"),
			init_and_find_maximum_index(data, "translits", true),
			init_and_find_maximum_index(data, "transcriptions", true)
		)
		for i = 1, maxind do
			data.heads[i] = {
				term = data.heads[i],
				tr = data.translits[i],
				ts = data.transcriptions[i],
			}
		end
	end

	-- Make sure there's at least one head.
	if not data.heads[1] then
		data.heads[1] = {}
	end

	------------ 4. Initialize and validate `data.categories` and `data.whole_page_categories`, and determine `pos_category` if not given, and add basic categories. ------------

	-- EXPERIMENTAL: see [[Wiktionary:Beer parlour/2024/June#Decluttering the altform mess]]
	if data.altform then
		data.noposcat = true
	end

	init_and_find_maximum_index(data, "categories")
	init_and_find_maximum_index(data, "whole_page_categories")
	local pos_category_already_present = false
	if #data.categories > 0 then
		local escaped_langname = pattern_escape(full_langname)
		local matches_lang_pattern = "^" .. escaped_langname .. " "
		for _, cat in ipairs(data.categories) do
			-- Does the category begin with the language name? If not, tag it with a tracking category.
			if not cat:find(matches_lang_pattern) then
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/no lang category]]
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/no lang category/LANGCODE]]
				track("no lang category", data.lang)
			end
		end

		-- If `pos_category` not given, try to infer it from the first specified category. If this doesn't work, we
		-- throw an error below.
		if not data.pos_category and data.categories[1]:find(matches_lang_pattern) then
			data.pos_category = data.categories[1]:gsub(matches_lang_pattern, "")
			-- Optimization to avoid inserting category already present.
			pos_category_already_present = true
		end
	end

	if not data.pos_category then
		error("`data.pos_category` not specified and could not be inferred from the categories given in "
			.. "`data.categories`. Either specify the plural part of speech in `data.pos_category` "
			.. "(e.g. \"proper nouns\") or ensure that the first category in `data.categories` is formed from the "
			.. "language's canonical name plus the plural part of speech (e.g. \"Norwegian Bokmål proper nouns\")."
			)
	end

	-- Insert a category at the beginning for the part of speech unless it's already present or `data.noposcat` given.
	if not pos_category_already_present and not data.noposcat then
		local pos_category = full_langname .. " " .. data.pos_category
		-- FIXME: [[User:Theknightwho]] Why is this special case here? Please add an explanatory comment.
		if pos_category ~= "Translingual Han characters" then
			insert(data.categories, 1, pos_category)
		end
	end

	-- Try to determine whether the part of speech refers to a lemma or a non-lemma form; if we can figure this out,
	-- add an appropriate category.
	local postype = export.pos_lemma_or_nonlemma(data.pos_category)
	if not postype then
		-- We don't know what this category is, so tag it with a tracking category.
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/unrecognized pos]]
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/unrecognized pos/LANGCODE]]
		track("unrecognized pos", data.lang)
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/unrecognized pos/POS]]
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/unrecognized pos/POS/LANGCODE]]
		track("unrecognized pos/pos/" .. data.pos_category, data.lang)
	elseif not data.noposcat then
		insert(data.categories, 1, full_langname .. " " .. postype .. "s")
	end

	-- EXPERIMENTAL: see [[Wiktionary:Beer parlour/2024/June#Decluttering the altform mess]]
	if data.altform then
		insert(data.categories, 1, full_langname .. " alternative forms")
	end

	------------ 5. Create a default headword, and add links to multiword page names. ------------

	-- Determine if term is reconstructed
	local is_reconstructed = namespace == "Reconstruction" or data.lang:hasType("reconstructed")

	-- Create a default headword based on the pagename, which is determined in
	-- advance by the data module so that it only needs to be done once.
	local default_head = page.pagename

	-- Add links to multi-word page names when appropriate
	if not (is_reconstructed or data.nolinkhead) then
		local no_links = (m_data or get_data()).no_multiword_links
		if not (no_links[langcode] or no_links[full_langcode]) and export.head_is_multiword(default_head) then
			default_head = export.add_multiword_links(default_head, true)
		end
	end

	if is_reconstructed then
		default_head = "*" .. default_head
	end

	------------ 6. Fill in missing values in `data.heads`. ------------

	-- True if any script among the headword scripts has spaces in it.
	local any_script_has_spaces = false
	-- True if any term has a redundant head= param.
	local has_redundant_head_param = false

	for _, head in ipairs(data.heads) do

		------ 6a. If missing head, replace with default head.
		if not head.term then
			head.term = default_head
		elseif head.term == default_head then
			has_redundant_head_param = true
		elseif head.term:find("^[!?]$") then
			-- If explicit head= just consists of ! or ?, add it to the end of the default head.
			head.term = default_head .. head.term
		end

		if is_reconstructed then
			local head_term = head.term
			if head_term:find("%[%[") then
				head_term = remove_links(head_term)
			end
			if head_term:sub(1, 1) ~= "*" then
				error("The headword '"  .. head_term .. "' must begin with '*' to indicate that it is reconstructed.")
			end
		end

		------ 6b. Try to detect the script(s) if not provided. If a per-head script is provided, that takes precedence,
		------     otherwise fall back to the overall script if given. If neither given, autodetect the script.

		local auto_sc = data.lang:findBestScript(head.term)
		if (
			auto_sc:getCode() == "None" and
			find_best_script_without_lang(head.term):getCode() ~= "None"
		) then
			insert(data.categories, full_langname .. " terms in nonstandard scripts")
		end
		if not (head.sc or data.sc) then -- No script code given, so use autodetected script.
			head.sc = auto_sc
		else
			if not head.sc then -- Overall script code given.
				head.sc = data.sc
			end
			-- Track uses of sc parameter.
			if head.sc:getCode() == auto_sc:getCode() then
				insert(data.categories, full_langname .. " terms with redundant script codes")
			else
				insert(data.categories, full_langname .. " terms with non-redundant manual script codes")
			end
		end

		-- If using a discouraged character sequence, add to maintenance category.
		if head.sc:hasNormalizationFixes() == true then
			local composed_head = toNFC(head.term)
			if head.sc:fixDiscouragedSequences(composed_head) ~= composed_head then
				insert(data.whole_page_categories, "Pages using discouraged character sequences")
			end
		end

		any_script_has_spaces = any_script_has_spaces or head.sc:hasSpaces()

		------ 6c. Create automatic transliterations for any non-Latin headwords without manual translit given
		------     (provided automatic translit is available, e.g. not in Persian or Hebrew).

		-- Make transliterations
		head.tr_manual = nil


		-- Try to generate a transliteration if necessary
		if head.tr == "-" then
			head.tr = nil
		else
			local notranslit = (m_data or get_data()).notranslit
			if not (notranslit[langcode] or notranslit[full_langcode]) and head.sc:isTransliterated() then
				head.tr_manual = not not head.tr

				local text = head.term
				if not data.lang:link_tr(head.sc) then
					text = remove_links(text)
				end

				local automated_tr, tr_categories
				automated_tr, head.tr_fail, tr_categories = data.lang:transliterate(text, head.sc)

				if automated_tr or head.tr_fail then
					local manual_tr = head.tr

					if manual_tr then
						if (remove_links(manual_tr) == remove_links(automated_tr)) and (not head.tr_fail) then
							insert(data.categories, full_langname .. " terms with redundant transliterations")
						elseif not head.tr_fail then
							insert(data.categories, full_langname .. " terms with non-redundant manual transliterations")
						end
					end

					if not manual_tr then
						head.tr = automated_tr
						for _, category in ipairs(tr_categories) do
							insert(data.categories, category)
						end
					end
				end

				-- There is still no transliteration?
				-- Add the entry to a cleanup category.
				if not head.tr then
					head.tr = "<small>transliteration needed</small>"
					-- FIXME: No current support for 'Request for transliteration of Classical Persian terms' or similar.
					-- Consider adding this support in [[Module:category tree/poscatboiler/data/entry maintenance]].
					insert(data.categories, "Requests for transliteration of " .. full_langname .. " terms")
				else
					-- Otherwise, trim it.
					head.tr = trim(head.tr)
				end
			end
		end

		-- Link to the transliteration entry for languages that require this.
		if head.tr and data.lang:link_tr(head.sc) then
			head.tr = full_link{
				term = head.tr,
				lang = data.lang,
				sc = get_script("Latn"),
				tr = "-"
			}
		end
	end

	------------ 7. Maybe tag the title with the appropriate script code, using the `display_title` mechanism. ------------

	-- Assumes that the scripts in "toBeTagged" will never occur in the Reconstruction namespace.
	-- (FIXME: Don't make assumptions like this, and if you need to do so, throw an error if the assumption is violated.)
	-- Avoid tagging ASCII as Hani even when it is tagged as Hani in the headword, as in [[check]]. The check for ASCII
	-- might need to be expanded to a check for any Latin characters and whitespace or punctuation.
	local display_title
	-- Where there are multiple headwords, use the script for the first. This assumes the first headword is similar to
	-- the pagename, and that headwords that are in different scripts from the pagename aren't first. This seems to be
	-- about the best we can do (alternatively we could potentially do script detection on the pagename).
	local dt_script = data.heads[1].sc
	local dt_script_code = dt_script:getCode()
	local page_non_ascii = namespace == "" and not page.pagename:find("^[%z\1-\127]+$")
	local unsupported_pagename, unsupported = page.full_raw_pagename:gsub("^Unsupported titles/", "")
	if unsupported == 1 and page.unsupported_titles[unsupported_pagename] then
		display_title = 'Unsupported titles/<span class="' .. dt_script_code .. '">' .. page.unsupported_titles[unsupported_pagename] .. '</span>'
	elseif page_non_ascii and (m_data or get_data()).toBeTagged[dt_script_code]
		or (dt_script_code == "Jpan" and (text_in_script(page.pagename, "Hira") or text_in_script(page.pagename, "Kana")))
		or (dt_script_code == "Kore" and text_in_script(page.pagename, "Hang")) then
		display_title = '<span class="' .. dt_script_code .. '">' .. page.full_raw_pagename .. '</span>'
	-- Keep Han entries region-neutral in the display title.
	elseif page_non_ascii and (dt_script_code == "Hant" or dt_script_code == "Hans") then
		display_title = '<span class="Hani">' .. page.full_raw_pagename .. '</span>'
	elseif namespace == "Reconstruction" then
		local matched
		display_title, matched = ugsub(
			page.full_raw_pagename,
			"^(Reconstruction:[^/]+/)(.+)$",
			function(before, term)
				return before .. tag_text(term, data.lang, dt_script)
			end
		)
		if matched == 0 then
			display_title = nil
		end
	end
	-- FIXME: Generalize this.
	-- If the current language uses ur-Arab (for Urdu, etc.), ku-Arab (Central Kurdish) or pa-Arab
	-- (Shahmukhi, for Punjabi) and there's more than one language on the page, don't set the display title
	-- because these three scripts display in Nastaliq and we don't want this for terms that also exist in other
	-- languages that don't display in Nastaliq (e.g. Arabic or Persian) to display in Nastaliq. Because the word
	-- "Urdu" occurs near the end of the alphabet, Urdu fonts tend to override the fonts of other languages.
	-- FIXME: This is checking for more than one language on the page but instead needs to check if there are any
	-- languages using scripts other than the ones just mentioned.
	if (dt_script_code == "ur-Arab" or dt_script_code == "ku-Arab" or dt_script_code == "pa-Arab") and page.L2_list.n > 1 then
		display_title = nil
	end

	if display_title then
		mw.getCurrentFrame():callParserFunction(
			"DISPLAYTITLE",
			display_title
		)
	end

	------------ 8. Insert additional categories. ------------

	if data.force_cat_output then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/force cat output]]
		track("force cat output")
	end

	if has_redundant_head_param then
		if not data.no_redundant_head_cat then
			insert(data.categories, full_langname .. " terms with redundant head parameter")
		end
	end

	-- If the first head is multiword (after removing links), maybe insert into "LANG multiword terms".
	if not data.nomultiwordcat and any_script_has_spaces and postype == "lemma" then
		local no_multiword_cat = (m_data or get_data()).no_multiword_cat
		if not (no_multiword_cat[langcode] or no_multiword_cat[full_langcode]) then
			-- Check for spaces or hyphens, but exclude prefixes and suffixes.
			-- Use the pagename, not the head= value, because the latter may have extra
			-- junk in it, e.g. superscripted text that throws off the algorithm.
			local no_hyphen = (m_data or get_data()).hyphen_not_multiword_sep
			-- Exclude hyphens if the data module states that they should for this language.
			local checkpattern = (no_hyphen[langcode] or no_hyphen[full_langcode]) and ".[%s፡]." or ".[%s%-፡]."
			if umatch(page.pagename, checkpattern) and not non_categorizable(page.full_raw_pagename) then
				insert(data.categories, full_langname .. " multiword terms")
			end
		end
	end

	if data.sccat then
		for _, head in ipairs(data.heads) do
			insert(data.categories, full_langname .. " " .. data.pos_category .. " in " ..
				head.sc:getDisplayForm())
		end
	end

	-- Reconstructed terms often use weird combinations of scripts and realistically aren't spelled so much as notated.
	if namespace ~= "Reconstruction" then
		-- Map from languages to a string containing the characters to ignore when considering whether a term has
		-- multiple written scripts in it. Typically these are Greek or Cyrillic letters used for their phonetic
		-- values.
		local characters_to_ignore = {
			["aaq"] = "α", -- Penobscot
			["acy"] = "δθ", -- Cypriot Arabic
			["anc"] = "γ", -- Ngas
			["aou"] = "χ", -- A'ou
			["awg"] = "β", -- Anguthimri
			["bhp"] = "β", -- Bima
			["byk"] = "θ", -- Biao
			["cdy"] = "θ", -- Chadong
			["clm"] = "χ", -- Klallam
			["col"] = "χ", -- Colombia-Wenatchi
			["coo"] = "χ", -- Comox; FIXME: others? E.g. Greek theta (θ)?
			["ets"] = "θ", -- Yekhee
			["gmw-gts"] = "χ", -- Gottscheerish
			["hur"] = "θ", -- Halkomelem
			["izh"] = "ь", -- Ingrian
			["kic"] = "θ", -- Kickapoo
			["lil"] = "χ", -- Lillooet
			["mhz"] = "β", -- Mor (Austronesian)
			["neg"]=  "ӡ", -- Negidal (normally in Cyrillic)
			["oui"] = "γβ", -- Old Uyghur: FIXME: others? E.g. Greek delta (δ)?
			["pox"] = "χ", -- Polabian
			["rom"] = "Θθ", -- Romani: International Standard; two different thetas???
			["sah"] = "ь", -- Yakut (1929 - 1939 Latin spelling)
			["sjw"] = "θ", -- Shawnee
			["squ"] = "χ", -- Squamish
			["str"] = "χθ", -- Saanich; uses two Greek letters
			["twa"] = "χ", -- Twana
			["yha"] = "θ", -- Baha
			["za"] = "зч", -- Zhuang; 1957-1982 alphabet used two Cyrillic letters (as well as some others like
						   -- ƃ, ƅ, ƨ, ɯ and ɵ that look like Cyrillic or Greek but are actually Latin)
			["zlw-slv"] = "χђћ", -- Slovincian; FIXME: χ is Greek, the other two are Cyrillic, but I'm not sure
								 -- the currect characters are being chosen in the entry names
			["zng"] = "θ", -- Mang
		}
		-- Determine how many real scripts are found in the pagename, where we exclude symbols and such. We exclude
		-- scripts whose `character_category` is false as well as Zmth (mathematical notation symbols), which has a
		-- category of "Mathematical notation symbols". When counting scripts, we need to elide language-specific
		-- variants because e.g. Beng and as-Beng have slightly different characters but we don't want to consider them
		-- two different scripts (e.g. [[এৰ]] has two characters which are detected respectively as Beng and as-Beng).
		local seen_scripts = {}
		local num_seen_scripts = 0
		local num_loops = 0
		local canon_pagename = page.pagename
		local ch_to_ignore = characters_to_ignore[full_langcode]
		if ch_to_ignore then
			canon_pagename = ugsub(canon_pagename, "[" .. ch_to_ignore .. "]", "")
		end
		while true do
			if canon_pagename == "" or num_seen_scripts >= 2 or num_loops >= 10 then
				break
			end
			-- Make sure we don't get into a loop checking the same script over and over again; happens with e.g. [[ᠪᡳ]]
			num_loops = num_loops + 1
			local pagename_script = find_best_script_without_lang(canon_pagename, "None only as last resort")
			local script_chars = pagename_script.characters
			if not script_chars then
				-- we are stuck; this happens with None
				break
			end
			local script_code = pagename_script:getCode()
			local replaced
			canon_pagename, replaced = ugsub(canon_pagename, "[" .. script_chars .. "]", "")
			if (
				replaced and
				script_code ~= "Zmth" and
				(script_data or get_script_data())[script_code] and
				script_data[script_code].character_category ~= false
			) then
				script_code = script_code:gsub("^.-%-", "")
				if not seen_scripts[script_code] then
					seen_scripts[script_code] = true
					num_seen_scripts = num_seen_scripts + 1
				end
			end
		end

		if num_seen_scripts > 1 then
			insert(data.categories, full_langname .. " terms written in multiple scripts")
		end
	end

	-- Categorise for unusual characters. Takes into account combining characters, so that we can categorise for characters with diacritics that aren't encoded as atomic characters (e.g. U̠). These can be in two formats: single combining characters (i.e. character + diacritic(s)) or double combining characters (i.e. character + diacritic(s) + character). Each can have any number of diacritics.
	local standard = data.lang:getStandardCharacters()
	if standard and not non_categorizable(page.full_raw_pagename) then
		local function char_category(char)
			local specials = {
				["#"] = "number sign",
				["("] = "parentheses",
				[")"] = "parentheses",
				["<"] = "angle brackets",
				[">"] = "angle brackets",
				["["] = "square brackets",
				["]"] = "square brackets",
				["_"] = "underscore",
				["{"] = "braces",
				["|"] = "vertical line",
				["}"] = "braces",
				["ß"] = "ẞ",
				["\205\133"] = "", -- this is UTF-8 for U+0345 ( ͅ)
				["\239\191\189"] = "replacement character",
			}
			char = toNFD(char)
				:gsub(".[\128-\191]*", function(m)
					local new_m = specials[m]
					new_m = new_m or m:uupper()
					return new_m
				end)
			return toNFC(char)
		end
		if full_langcode ~= "hi" and full_langcode ~= "lo" then
			local standard_chars_scripts = {}
			for _, head in ipairs(data.heads) do
				standard_chars_scripts[head.sc:getCode()] = true
			end
			-- Iterate over the scripts, in case there is more than one (as they can have different sets of standard characters).
			for code in pairs(standard_chars_scripts) do
				local sc_standard = data.lang:getStandardCharacters(code)
				if sc_standard then
					if page.pagename_len > 1 then
						local explode_standard = {}
						local function explode(char)
							explode_standard[char] = true
							return ""
						end
						local sc_standard = ugsub(sc_standard, page.comb_chars.combined_double, explode)
						sc_standard = ugsub(sc_standard,page.comb_chars.combined_single, explode)
							:gsub(".[\128-\191]*", explode)
						local num_cat_inserted
						for char in pairs(page.explode_pagename) do
							if not explode_standard[char] then
								if char:find("[0-9]") then
									if not num_cat_inserted then
										insert(data.categories, full_langname .. " terms spelled with numbers")
										num_cat_inserted = true
									end
								elseif ufind(char, page.emoji_pattern) then
									insert(data.categories, full_langname .. " terms spelled with emoji")
								else
									local upper = char_category(char)
									if not explode_standard[upper] then
										char = upper
									end
									insert(data.categories, full_langname .. " terms spelled with " .. char)
								end
							end
						end
					end
					-- If a diacritic doesn't appear in any of the standard characters, also categorise for it generally.
					sc_standard = toNFD(sc_standard)
					for diacritic in ugmatch(page.decompose_pagename, page.comb_chars.diacritics_single) do
						if not umatch(sc_standard, diacritic) then
							insert(data.categories, full_langname .. " terms spelled with ◌" .. diacritic)
						end
					end
					for diacritic in ugmatch(page.decompose_pagename, page.comb_chars.diacritics_double) do
						if not umatch(sc_standard, diacritic) then
							insert(data.categories, full_langname .. " terms spelled with ◌" .. diacritic .. "◌")
						end
					end
				end
			end
		-- Ancient Greek, Hindi and Lao handled the old way for now, as their standard chars still need to be converted to the new format (because there are a lot of them).
		elseif ulen(page.pagename) ~= 1 then
			for character in ugmatch(page.pagename, "([^" .. standard .. "])") do
				local upper = char_category(character)
				if not umatch(upper, "[" .. standard .. "]") then
					character = upper
				end
				insert(data.categories, full_langname .. " terms spelled with " .. character)
			end
		end
	end

	if data.heads[1].sc:isSystem("alphabet") then
		local pagename, i = page.pagename:ulower(), 2
		while umatch(pagename, "(%a)" .. ("%1"):rep(i)) do
			i = i + 1
			insert(data.categories, full_langname .. " terms with " .. i .. " consecutive instances of the same letter")
		end
	end

	-- Categorise for palindromes
	if not data.nopalindromecat and namespace ~= "Reconstruction" and ulen(page.pagename) > 2
		-- FIXME: Use of first script here seems hacky. What is the clean way of doing this in the presence of
		-- multiple scripts?
		and is_palindrome(page.pagename, data.lang, data.heads[1].sc) then
		insert(data.categories, full_langname .. " palindromes")
	end

	if namespace == "" and not data.lang:hasType("reconstructed") then
		for _, head in ipairs(data.heads) do
			if page.full_raw_pagename ~= get_link_page(remove_links(head.term), data.lang, head.sc) then
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/pagename spelling mismatch]]
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/headword/pagename spelling mismatch/LANGCODE]]
				track("pagename spelling mismatch", data.lang)
				break
			end
		end
	end

	-- Add to various maintenance categories.
	export.maintenance_cats(page, data.lang, data.categories, data.whole_page_categories)

	------------ 9. Format and return headwords, genders, inflections and categories. ------------

	-- Format and return all the gathered information. This may add more categories (e.g. gender/number categories),
	-- so make sure we do it before evaluating `data.categories`.
	local text = '<span class="headword-line">' ..
		format_headword(data) ..
		format_headword_genders(data) ..
		format_inflections(data) .. '</span>'

	-- Language-specific categories.
	local cats = format_categories(
		data.categories, data.lang, data.sort_key, page.encoded_pagename,
		data.force_cat_output or test_force_categories, data.heads[1].sc
	)
	-- Language-agnostic categories.
	local whole_page_cats = format_categories(
		data.whole_page_categories, nil, "-"
	)
	return text .. cats .. whole_page_cats
end

return export
