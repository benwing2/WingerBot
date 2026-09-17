local export = {}

--[=[
	[[Unsupported titles]], pages with high memory usage,
	extraction modules and part-of-speech names are listed
	at [[Module:links/data]].

	Other modules used:
		[[Module:script utilities]]
		[[Module:scripts]]
		[[Module:languages]] and its submodules
		[[Module:gender and number]]
		[[Module:debug/track]]
]=]

local anchors_module = "Module:anchors"
local debug_track_module = "Module:debug/track"
local decorations_module = "Module:decorations"
local form_of_module = "Module:form of"
local gender_and_number_module = "Module:gender and number"
local languages_module = "Module:languages"
local load_module = "Module:load"
local memoize_module = "Module:memoize"
local pages_module = "Module:pages"
local scripts_module = "Module:scripts"
local script_utilities_module = "Module:script utilities"
local string_encode_entities_module = "Module:string/encode entities"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local utilities_module = "Module:utilities"

local concat = table.concat
local find = string.find
local get_current_title = mw.title.getCurrentTitle
local insert = table.insert
local ipairs = ipairs
local match = string.match
local new_title = mw.title.new
local pairs = pairs
local remove = table.remove
local sub = string.sub
local toNFC = mw.ustring.toNFC
local tostring = tostring
local type = type
local unstrip = mw.text.unstrip

local NAMESPACE = get_current_title().nsText

local function anchor_encode(...)
	anchor_encode = require(memoize_module)(mw.uri.anchorEncode, true)
	return anchor_encode(...)
end

local function debug_track(...)
	debug_track = require(debug_track_module)
	return debug_track(...)
end

local function decode_entities(...)
	decode_entities = require(string_utilities_module).decode_entities
	return decode_entities(...)
end

local function decode_uri(...)
	decode_uri = require(string_utilities_module).decode_uri
	return decode_uri(...)
end

-- Can't yet replace, as the [[Module:string utilities]] version no longer has automatic double-encoding prevention, which requires changes here to account for.
local function encode_entities(...)
	encode_entities = require(string_encode_entities_module)
	return encode_entities(...)
end

local function extend(...)
	extend = require(table_module).extend
	return extend(...)
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

local function format_decorations(...)
	format_decorations = require(decorations_module).format_decorations
	return format_decorations(...)
end

local function get_current_L2(...)
	get_current_L2 = require(pages_module).get_current_L2
	return get_current_L2(...)
end

local function get_lang(...)
	get_lang = require(languages_module).getByCode
	return get_lang(...)
end

local function get_script(...)
	get_script = require(scripts_module).getByCode
	return get_script(...)
end

local function language_anchor(...)
	language_anchor = require(anchors_module).language_anchor
	return language_anchor(...)
end

local function load_data(...)
	load_data = require(load_module).load_data
	return load_data(...)
end

local function request_script(...)
	request_script = require(script_utilities_module).request_script
	return request_script(...)
end

local function shallow_copy(...)
	shallow_copy = require(table_module).shallowCopy
	return shallow_copy(...)
end

local function split(...)
	split = require(string_utilities_module).split
	return split(...)
end

local function tag_text(...)
	tag_text = require(script_utilities_module).tag_text
	return tag_text(...)
end

local function tag_translit(...)
	tag_translit = require(script_utilities_module).tag_translit
	return tag_translit(...)
end

local function trim(...)
	trim = require(string_utilities_module).trim
	return trim(...)
end

local function u(...)
	u = require(string_utilities_module).char
	return u(...)
end

local function ulower(...)
	ulower = require(string_utilities_module).lower
	return ulower(...)
end

local function umatch(...)
	umatch = require(string_utilities_module).match
	return umatch(...)
end

local m_headword_data
local function get_headword_data()
	m_headword_data = load_data("Module:headword/data")
	return m_headword_data
end

local function track(page, code)
	local tracking_page = "links/" .. page
	debug_track(tracking_page)
	if code then
		debug_track(tracking_page .. "/" .. code)
	end
end

local function field_non_empty(list, field)
	if not list then
		return nil
	end
	if type(list) ~= "table" then
		error(("Internal error: Wrong type for `termobj.%s`=%s, should be %s\"table\""):format(
			field, mw.dumpObject(list), field == "q" or field == "qq" and "\"string\" or " or ""))
	end
	return list[1]
end

--[=[
Add any "decorations" (left or right regular or accent qualifiers, labels or references) to an item. `text` is the
item's text (to which to add the decorations) and `itemobj` is the object specifying the item's decorations, which
should optionally contain:
* left regular qualifiers in `q` (an array of strings or a single string); an empty array will be ignored;
* right regular qualifiers in `qq` (an array of strings or a single string); an empty array will be ignored;
* left accent qualifiers in `a` (an array of strings); an empty array will be ignored;
* right accent qualifiers in `aa` (an array of strings); an empty array will be ignored;
* left labels in `l` (an array of strings); an empty array will be ignored;
* right labels in `ll` (an array of strings); an empty array will be ignored;
* references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
  (formatted reference text) and optionally `name` and/or `group`; an empty array will be ignored.
`lang` is a language object and is required if any accent qualifiers or labels are given.
]=]
local function add_text_decorations(text, itemobj, lang)
	local q = itemobj.q
	if type(q) == "string" then
		q = { q }
	end
	local qq = itemobj.qq
	if type(qq) == "string" then
		qq = { qq }
	end
	if field_non_empty(q, "q") or field_non_empty(qq, "qq") or field_non_empty(itemobj.a, "a") or
		field_non_empty(itemobj.aa, "aa") or field_non_empty(itemobj.l, "l") or field_non_empty(itemobj.ll, "ll") or
		field_non_empty(itemobj.refs, "refs") then
		text = format_decorations {
			lang = lang,
			text = text,
			q = q,
			qq = qq,
			a = itemobj.a,
			aa = itemobj.aa,
			l = itemobj.l,
			ll = itemobj.ll,
			refs = itemobj.refs,
		}
	end

	return text
end


local function selective_trim(...)
	-- Unconditionally trimmed charset.
	local always_trim =
		"\194\128-\194\159" ..   -- U+0080-009F (C1 control characters)
		"\194\173" ..            -- U+00AD (soft hyphen)
		"\226\128\170-\226\128\174" .. -- U+202A-202E (directionality formatting characters)
		"\226\129\166-\226\129\169" -- U+2066-2069 (directionality formatting characters)

	-- Standard trimmed charset.
	local standard_trim = "%s" .. -- (default whitespace charset)
		"\226\128\139-\226\128\141" .. -- U+200B-200D (zero-width spaces)
		always_trim

	-- If there are non-whitespace characters, trim all characters in `standard_trim`.
	-- Otherwise, only trim the characters in `always_trim`.
	selective_trim = function(text)
		if text == "" then
			return text
		end
		local trimmed = trim(text, standard_trim)
		if trimmed ~= "" then
			return trimmed
		end
		return trim(text, always_trim)
	end

	return selective_trim(...)
end

local function escape(text, str)
	local rep
	repeat
		text, rep = text:gsub("\\\\(\\*" .. str .. ")", "\5%1")
	until rep == 0
	return (text:gsub("\\" .. str, "\6"))
end

local function unescape(text, str)
	return (text
		:gsub("\5", "\\")
		:gsub("\6", str))
end

-- Remove bold, italics, soft hyphens, strip markers and HTML tags.
local function remove_formatting(str)
	str = str
		:gsub("('*)'''(.-'*)'''", "%1%2")
		:gsub("('*)''(.-'*)''", "%1%2")
		:gsub("­", "")
	return (unstrip(str)
		:gsub("<[^<>]+>", ""))
end

--[==[
Split `text` on double slashes (taking account of escaping backslashes). Return a list of split items.
]==]
function export.split_on_slashes(text)
	if text:find("\\", nil, true) then
		track("escaped", "split_on_slashes")
	end
	text = split(escape(text, "//"), "//", true) or {}
	for i, v in ipairs(text) do
		text[i] = unescape(v, "//")
		if v == "" then
			text[i] = false
		end
	end
	return text
end

--[==[
If `text` is a wikilink (i.e. in the form `<nowiki>[[foo]]</nowiki>` or `<nowiki>[[foo|bar]]</nowiki>`), return the link
target and display text. If the wikilink is single-part, the display text will be the same as the link target. If the
text is not in wikilink form, return {nil} for both link target and display text.
]==]
function export.get_wikilink_parts(text)
	-- TODO: replace `allow_bad_target` with `allow_unsupported`, with support for links to unsupported titles, including escape sequences.
	if (                        -- Filters out anything but "[[...]]" with no intermediate "[[" or "]]".
			not match(text, "^()%[%[") or -- Faster than sub(text, 1, 2) ~= "[[".
			find(text, "[[", 3, true) or
			find(text, "]]", 3, true) ~= #text - 1
		) then
		return nil, nil
	end
	local pipe = find(text, "|", 3, true)
	local title, display
	if pipe then
		title, display = sub(text, 3, pipe - 1), sub(text, pipe + 1, -3)
	else
		title = sub(text, 3, -3)
		display = title
	end
	return title, display
end

-- Does the work of export.get_fragment, but can be called directly to avoid unnecessary checks for embedded links.
local function get_fragment(text)
	text = escape(text, "#")
	-- Replace numeric character references with the corresponding character (&#39; → '),
	-- as they contain #, which causes the numeric character reference to be
	-- misparsed (wa'a → wa&#39;a → pagename wa&, fragment 39;a).
	text = decode_entities(text)
	local target, fragment = text:match("^(.-)#(.+)$")
	target = target or text
	target = unescape(target, "#")
	fragment = fragment and unescape(fragment, "#") or nil
	return target, fragment
end

--[==[
Given a link target possibly containing a fragment (i.e. a pound sign and following anchor), return two values, the
actual target (minus the fragment) and the fragment, or {nil} if there is no fragment.
]==]
function export.get_fragment(text)
	if text:find("\\", nil, true) then
		track("escaped", "get_fragment")
	end
	-- If there are no embedded links, process input.
	local open = find(text, "[[", nil, true)
	if not open then
		return get_fragment(text)
	end
	local close = find(text, "]]", open + 2, true)
	if not close then
		return get_fragment(text)
		-- If there is one, but it's redundant (i.e. encloses everything with no pipe), remove and process.
	elseif open == 1 and close == #text - 1 and not find(text, "|", 3, true) then
		return get_fragment(sub(text, 3, -3))
	end
	-- Otherwise, return the input.
	return text, nil
end

--[==[
Given a link target as passed to `full_link()`, get the actual page that the target refers to. This removes
bold, italics, strip markets and HTML; calls `makeEntryName()` for the language in question; converts targets
beginning with `*` to the Reconstruction namespace; and converts appendix-constructed languages to the Appendix
namespace. Returns up to three values:
# the actual page to link to, or {nil} to not link to anything;
# how the target should be displayed as, if the user didn't explicitly specify any display text; generally the
  same as the original target, but minus any anti-asterisk !!;
# the value `true` if the target had a backslash-escaped * in it (FIXME: explain this more clearly).

FIXME: This should not be calling deprecated `makeEntryName()` and should always return the same number of values.
]==]
function export.get_link_page_with_auto_display(target, lang, sc, plain)
	local orig_target = target

	if not target then
		return nil
	elseif target:find("\\", nil, true) then
		track("escaped", "get_link_page")
	end

	target = remove_formatting(target)

	if target:sub(1, 1) == ":" then
		track("initial colon")
		-- FIXME, the auto_display (second return value) should probably remove the colon
		return target:sub(2), orig_target
	end

	local prefix = target:match("^(.-):")
	-- Convert any escaped colons
	target = target:gsub("\\:", ":")
	if prefix then
		-- If this is an a link to another namespace or an interwiki link, ensure there's an initial colon and then
		-- return what we have (so that it works as a conventional link, and doesn't do anything weird like add the term
		-- to a category.)
		prefix = ulower(trim(prefix))
		if prefix ~= "" and (
				load_data("Module:data/namespaces")[prefix] or
				load_data("Module:data/interwikis")[prefix]
			) then
			return target, orig_target
		end
	end

	-- Check if the term is reconstructed and remove any asterisk. Also check for anti-asterisk (!!).
	-- Otherwise, handle the escapes.
	local reconstructed, escaped, anti_asterisk
	if not plain then
		target, reconstructed = target:gsub("^%*(.)", "%1")
		if reconstructed == 0 then
			target, anti_asterisk = target:gsub("^!!(.)", "%1")
			if anti_asterisk == 1 then
				-- Remove !! from original. FIXME! We do it this way because the call to remove_formatting() above
				-- may cause non-initial !! to be interpreted as anti-asterisks. We should surely move the
				-- remove_formatting() call later.
				orig_target = orig_target:gsub("^!!", "")
			end
		end
	end
	target, escaped = target:gsub("^(\\-)\\%*", "%1*")

	if not (sc and sc:getCode() ~= "None") then
		sc = lang:findBestScript(target)
	end

	-- Remove carets if they are used to capitalize parts of transliterations (unless they have been escaped).
	if (not sc:hasCapitalization()) and sc:isTransliterated() and target:match("%^") then
		target = escape(target, "^")
			:gsub("%^", "")
		target = unescape(target, "^")
	end

	-- Get the entry name for the language.
	target = lang:makeEntryName(target, sc, reconstructed == 1 or lang:hasType("appendix-constructed"))

	-- If the link contains unexpanded template parameters, then don't create a link.
	if target:match("{{{.-}}}") then
		-- FIXME: Should we return the original target as the default display value (second return value)?
		return nil
	end

	-- Link to appendix for reconstructed terms and terms in appendix-only languages. Plain links interpret *
	-- literally, however.
	if reconstructed == 1 then
		if lang:getFullCode() == "und" then
			-- Return the original target as default display value. If we don't do this, we wrongly get
			-- [Term?] displayed instead.
			return nil, orig_target
		end
		target = "Reconstruction:" .. lang:getFullName() .. "/" .. target
		-- Reconstructed languages and substrates require an initial *.
	elseif anti_asterisk ~= 1 and (lang:hasType("reconstructed") or lang:getFamilyCode() == "qfa-sub") then
		error(("The specified language %s is unattested, while the term '%s' does not begin with '*' to indicate that it is reconstructed.")
		:
		format(lang:getCanonicalName(), orig_target))
	elseif lang:hasType("appendix-constructed") then
		target = "Appendix:" .. lang:getFullName() .. "/" .. target
	else
		target = target
	end

	return target, orig_target, escaped > 0
end

function export.get_link_page(target, lang, sc, plain)
	local target, auto_display, escaped = export.get_link_page_with_auto_display(target, lang, sc, plain)
	return target, escaped
end

-- Make a link from a given link's parts.
local function make_link(link, lang, sc, id, isolated, cats, no_alt_ast, plain)
	-- Convert percent encoding to plaintext.
	link.target = link.target and decode_uri(link.target, "PATH")
	link.fragment = link.fragment and decode_uri(link.fragment, "PATH")

	-- Find fragments (if one isn't already set).
	-- Prevents {{l|en|word#Etymology 2|word}} from linking to [[word#Etymology 2#English]].
	-- # can be escaped as \#.
	if link.target and link.fragment == nil then
		link.target, link.fragment = get_fragment(link.target)
	end

	-- Process the target
	local auto_display, escaped
	link.target, auto_display, escaped = export.get_link_page_with_auto_display(link.target, lang, sc, plain)

	-- Create a default display form.
	-- If the target is "" then it's a link like [[#English]], which refers to the current page.
	if auto_display == "" then
		auto_display = (m_headword_data or get_headword_data()).pagename
	end

	-- If the display is the target and the reconstruction * has been escaped, remove the escaping backslash.
	if escaped then
		auto_display = auto_display:gsub("\\([^\\]*%*)", "%1", 1)
	end

	-- Process the display form.
	if link.display then
		local orig_display = link.display
		link.display = lang:makeDisplayText(link.display, sc, true)
		if cats then
			auto_display = lang:makeDisplayText(auto_display, sc)
			-- If the alt text is the same as what would have been automatically generated, then the alt parameter is
			-- redundant (e.g. {{l|en|foo|foo}}, {{l|en|w:foo|foo}}, but not {{l|en|w:foo|w:foo}}). If they're
			-- different, but the alt text could have been entered as the term parameter without it affecting the target
			-- page, then the target parameter is redundant (e.g. {{l|ru|фу|фу́}}). If `no_alt_ast` is true, use pcall
			-- to catch the error which will be thrown if this is a reconstructed lang and the alt text doesn't have *.
			if link.display == auto_display then
				insert(cats, lang:getFullName() .. " links with redundant alt parameters")
			else
				local ok, check
				if no_alt_ast then
					ok, check = pcall(export.get_link_page, orig_display, lang, sc, plain)
				else
					ok = true
					check = export.get_link_page(orig_display, lang, sc, plain)
				end
				if ok and link.target == check then
					insert(cats, lang:getFullName() .. " links with redundant target parameters")
				end
			end
		end
	else
		link.display = lang:makeDisplayText(auto_display, sc)
	end

	if not link.target then
		return link.display
	end

	-- If the target is the same as the current page, there is no sense id
	-- and either the language code is "und" or the current L2 is the current
	-- language then return a "self-link" like the software does.
	if link.target == get_current_title().prefixedText then
		local fragment, current_L2 = link.fragment, get_current_L2()
		if (
				fragment and fragment == current_L2 or
				not (id or fragment) and (lang:getFullCode() == "und" or lang:getFullName() == current_L2)
			) then
			return tostring(mw.html.create("strong")
				:addClass("selflink")
				:wikitext(link.display))
		end
	end

	-- Add fragment. Do not add a section link to "Undetermined", as such sections do not exist and are invalid.
	-- TabbedLanguages handles links without a section by linking to the "last visited" section, but adding
	-- "Undetermined" would break that feature. For localized prefixes that make syntax error, please use the
	-- format: ["xyz"] = true.
	local prefix = link.target:match("^:*([^:]+):")
	prefix = prefix and ulower(prefix)

	if prefix ~= "category" and not (prefix and load_data("Module:data/interwikis")[prefix]) then
		if (link.fragment or link.target:sub(-1) == "#") and not plain then
			track("fragment", lang:getFullCode())
			if cats then
				insert(cats, lang:getFullName() .. " links with manual fragments")
			end
		end

		if not link.fragment then
			if id then
				link.fragment = lang:getFullCode() == "und" and anchor_encode(id) or language_anchor(lang, id)
			elseif lang:getFullCode() ~= "und" and not (link.target:match("^Appendix:") or link.target:match("^Reconstruction:")) then
				link.fragment = anchor_encode(lang:getFullName())
			end
		end
	end

	-- Put inward-facing square brackets around a link to isolated spacing character(s).
	if isolated and link.display[1] and not umatch(decode_entities(link.display), "%S") then
		link.display = "&#x5D;" .. link.display .. "&#x5B;"
	end

	link.target = link.target:gsub("^(:?)(.*)", function(m1, m2)
		return m1 .. encode_entities(m2, "#%&+/:<=>@[\\]_{|}")
	end)

	link.fragment = link.fragment and encode_entities(remove_formatting(link.fragment), "#%&+/:<=>@[\\]_{|}")
	return "[[" ..
	link.target:gsub("^[^:]", ":%0") .. (link.fragment and "#" .. link.fragment or "") .. "|" .. link.display .. "]]"
end


-- Split a link into its parts.
local function parse_link(linktext)
	local link = { target = linktext }

	local target = link.target
	link.target, link.display = target:match("^(..-)|(.+)$")
	if not link.target then
		link.target = target
		link.display = target
	end

	-- There's no point in processing these, as they aren't real links.
	local target_lower = link.target:lower()
	for _, false_positive in ipairs({ "category", "cat", "file", "image" }) do
		if target_lower:match("^" .. false_positive .. ":") then
			return nil
		end
	end

	link.display = decode_entities(link.display)
	link.target, link.fragment = get_fragment(link.target)

	-- So that make_link does not look for a fragment again.
	if not link.fragment then
		link.fragment = false
	end

	return link
end

local function check_params_ignored_when_embedded(alt, lang, id, cats)
	if alt then
		track("alt-ignored")
		if cats then
			insert(cats, lang:getFullName() .. " links with ignored alt parameters")
		end
	end
	if id then
		track("id-ignored")
		if cats then
			insert(cats, lang:getFullName() .. " links with ignored id parameters")
		end
	end
end

-- Find embedded links and ensure they link to the correct section.
local function process_embedded_links(text, alt, lang, sc, id, cats, no_alt_ast, plain)
	-- Process the non-linked text.
	text = lang:makeDisplayText(text, sc, true)

	-- If the text begins with * and another character, then act as if each link begins with *. However, don't do this if the * is contained within a link at the start. E.g. `|*[[foo]]` would set all_reconstructed to true, while `|[[*foo]]` would not.
	local all_reconstructed = false
	if not plain then
		-- anchor_encode removes links etc.
		if anchor_encode(text):sub(1, 1) == "*" then
			all_reconstructed = true
		end
		-- Otherwise, handle any escapes.
		text = text:gsub("^(\\-)\\%*", "%1*")
	end

	check_params_ignored_when_embedded(alt, lang, id, cats)

	local function process_link(space1, linktext, space2)
		local capture = "[[" .. linktext .. "]]"
		local link = parse_link(linktext)

		-- Return unprocessed false positives untouched (e.g. categories).
		if not link then
			return capture
		end

		if all_reconstructed then
			if link.target:find("^!!") then
				-- Check for anti-asterisk !! at the beginning of a target, indicating that a reconstructed term
				-- wants a part of the term to link to a non-reconstructed term, e.g. Old English
				-- {{ang-noun|m|head=*[[!!Crist|Cristes]] [[!!mæsseǣfen]]}}.
				link.target = link.target:sub(3)
				-- Also remove !! from the display, which may have been copied from the target (as in mæsseǣfen in
				-- the example above).
				link.display = link.display:gsub("^!!", "")
			elseif not link.target:match("^%*") then
				link.target = "*" .. link.target
			end
		end

		linktext = make_link(link, lang, sc, id, false, nil, no_alt_ast, plain)
			:gsub("^%[%[", "\3")
			:gsub("%]%]$", "\4")

		return space1 .. linktext .. space2
	end

	-- Use chars 1 and 2 as temporary substitutions, so that we can use charsets. These are converted to chars 3 and 4 by process_link, which means we can convert any remaining chars 1 and 2 back to square brackets (i.e. those not part of a link).
	text = text
		:gsub("%[%[", "\1")
		:gsub("%]%]", "\2")
	-- If the script uses ^ to capitalize transliterations, make sure that any carets preceding links are on the inside, so that they get processed with the following text.
	if (
			text:find("^", nil, true) and
			not sc:hasCapitalization() and
			sc:isTransliterated()
		) then
		text = escape(text, "^")
			:gsub("%^\1", "\1%^")
		text = unescape(text, "^")
	end
	text = text:gsub("\1(%s*)([^\1\2]-)(%s*)\2", process_link)

	-- Remove the extra * at the beginning of a language link if it's immediately followed by a link whose display begins with * too.
	if all_reconstructed then
		text = text:gsub("^%*\3([^|\1-\4]+)|%*", "\3%1|*")
	end

	return (text
		:gsub("[\1\3]", "[[")
		:gsub("[\2\4]", "]]")
	)
end

local function simple_link(term, fragment, alt, lang, sc, id, cats, no_alt_ast, suppress_redundant_wikilink_cat)
	local plain
	if lang == nil then
		lang, plain = get_lang("und"), true
	end

	-- Get the link target and display text. If the term is the empty string, treat the input as a link to the current page.
	if term == "" then
		term = get_current_title().prefixedText
	elseif term then
		local new_term, new_alt = export.get_wikilink_parts(term)
		if new_term then
			check_params_ignored_when_embedded(alt, lang, id, cats)
			-- [[|foo]] links are treated as plaintext "[[|foo]]".
			-- FIXME: Pipes should be handled via a proper escape sequence, as they can occur in unsupported titles.
			if new_term == "" then
				term, alt = nil, term
			else
				local title = new_title(new_term)
				if title then
					local ns = title.namespace
					-- File: and Category: links should be returned as-is.
					if ns == 6 or ns == 14 then
						return term
					end
				end
				term, alt = new_term, new_alt
				if cats then
					if not (suppress_redundant_wikilink_cat and suppress_redundant_wikilink_cat(term, alt)) then
						insert(cats, lang:getFullName() .. " links with redundant wikilinks")
					end
				end
			end
		end
	end
	if alt then
		alt = selective_trim(alt)
		if alt == "" then
			alt = nil
		end
	end
	-- If there's nothing to process, return nil.
	if not (term or alt) then
		return nil
	end

	-- If there is no script, get one.
	if not sc then
		sc = lang:findBestScript(alt or term)
	end

	-- Embedded wikilinks need to be processed individually.
	if term then
		local open = find(term, "[[", nil, true)
		if open and find(term, "]]", open + 2, true) then
			return process_embedded_links(term, alt, lang, sc, id, cats, no_alt_ast, plain)
		end
		term = selective_trim(term)
	end

	-- If not, make a link using the parameters.
	return make_link({
		target = term,
		display = alt,
		fragment = fragment
	}, lang, sc, id, true, cats, no_alt_ast, plain)
end

--[==[
Create a basic link to the given term. It links to the language section (such as `==English==`), but it does not add
language and script wrappers, so any code that uses this function should call `[[Module:script utilities#tag_text]]`
to add such wrappers itself at some point. The first argument, `data`, may contain the following items, a subset of the
items used in the `data` argument of `##full_link`. If any other items are included, they are ignored.
{ {
	term = "entry_to_link_to",
	alt = "link_text_or_displayed_text",
	lang = language_object,
	sc = script_object,
	fragment = "link_fragment",
	id = "sense_id",
	no_alt_ast = boolean,
	suppress_redundant_wikilink_cat = function(term, alt) -> boolean,
	cats = nil or {}, -- NOTE: If given, will be side-effected to return categories to add the page to.
} }
Specifically:
* `term`: Term to turn into a link. This is generally the name of a page, possibly with extra diacritics added (e.g.
  length marks in Latin or Old English terms, accents in Russian terms, vowel diacritics in Arabic terms, etc.), which
  are stripped to determine the actual pagename. The term can contain wikilinks already embedded in it. These are
  processed individually just like a single link would be. The `alt` argument is ignored in this case.
* `alt`: The alternative display for the link, if different from the linked page. If this is {nil}, the `term` argument
  is used instead (much like regular wikilinks). If `term` contains wikilinks in it, this argument is ignored and has no
  effect. (Links in which the alt is ignored are tracked with the tracking template
  {{whatlinkshere|tracking=links/alt-ignored}}.)
* `lang` ('''required'''): The [[Module:languages#Language objects|language object]] for the term being linked. The link
  or links in `term` will normally have their fragment set to point to the canonical name (see
  {{tl|language data documentation}}) of `lang` (or, if it is an etymology-only language, to the canonical name of its
  L2 parent). (However, if `id` is defined, the fragment will point to a language-specific sense ID corresponding to
  this field, which in turn will be overridden by `fragment` if specified.)
* `sc`: The [[Module:scripts#Script objects|script object]] for the term being linked. This rarely needs to be specified
  because it is autodetected based on `term` or `alt`, and the detection is usually correct. It is used to determine
  how to convert the term into a pagename, possibly by stripping certain diacritics from the term's text.
* `fragment`: If specified, overrides the fragment in the generated link (i.e. the portion after `#`, which determines
  where on the page to go to when the link is clicked). If not specified, the fragment is generated from `id` (if given)
  or otherwise from `lang`.
* `id`: Sense ID string. If this argument is defined, the link will point to a language-specific sense ID
  ({{ll|en|identifier|id=HTML}}) created by the template {{temp|senseid}}. The fragment for a sense ID consists of the
  language's canonical name, a hyphen (`-`), and the string that was supplied as the `id` argument. This is useful when
  a term has more than one sense in a language. If the `term` argument contains wikilinks, this argument is ignored.
  (Links in which the sense ID is ignored are tracked with the tracking template
  {{whatlinkshere|tracking=links/id-ignored}}.)
* `no_alt_ast`: This is the same as `no_alt_ast` in `##full_link()`. See that function for more information.
* `suppress_redundant_wikilink_cat`: This is the same as `suppress_redundant_wikilink_cat` in `##full_link()`. See
  that function for more information.
* `cats`: This should be either {nil} or an empty list. In the latter case, tracking categories will be added to the
  list when appropriate. The caller can choose to add the page to those categories (as is done by ##full_link()`).

The following special options are processed for each link (both simple terms and with embedded wikilinks):
* The target page name will be processed by stripping certain diacritics (as mentioned above) and converting the
  resulting ''logical'' pagename to a ''physical'' pagename (which will be different from the logical pagename in the
  case of pages with unsupported characters in them and certain overly large pages, such as [[a]], that are split into
  parts).
* If the term starts with `*`, then it is considered a reconstructed term, and a link to the `Reconstruction:` namespace
  will be created. If the text contains embedded wikilinks, then `*` is automatically applied to each one individually,
  while preserving the displayed form of each link as it was given. This allows linking to phrases containing multiple
  reconstructed terms, while only showing the `*` once at the beginning.
* If the text starts with `:`, then the link is treated as "raw" and the above steps are skipped. This can be used in
  rare cases where the page name begins with `*` or if diacritics should not be stripped. For example:
** {{tl|l|en|*nix}} links to the nonexistent page [[Reconstruction:English/nix]] (`*` is interpreted as a
   reconstruction), but {{tl|l|en|:*nix}} links to [[*nix]].
** {{tl|l|sl|Franche-Comté}} links to the nonexistent page [[Franche-Comte]] (`é` is converted to `e` by the
   diacritic-stripping process), but {{tl|l|sl|:Franche-Comté}} links to [[Franche-Comté]].
]==]
function export.language_link(data)
	if type(data) ~= "table" then
		error(
		"The first argument to the function language_link must be a table. See [[Module:links/documentation]] for more information.")
	elseif data.term and data.term:find("\\", nil, true) or data.alt and data.alt:find("\\", nil, true) then
		track("escaped", "language_link")
	end

	-- Categorize links to "und".
	local lang, cats = data.lang, data.cats
	if cats and lang:getCode() == "und" then
		insert(cats, "Undetermined language links")
	end

	return simple_link(
		data.term,
		data.fragment,
		data.alt,
		lang,
		data.sc,
		data.id,
		cats,
		data.no_alt_ast,
		data.suppress_redundant_wikilink_cat
	)
end

function export.plain_link(data)
	if type(data) ~= "table" then
		error(
		"The first argument to the function plain_link must be a table. See Module:links/documentation for more information.")
	elseif data.term and data.term:find("\\", nil, true) or data.alt and data.alt:find("\\", nil, true) then
		track("escaped", "plain_link")
	end

	return simple_link(
		data.term,
		data.fragment,
		data.alt,
		nil,
		data.sc,
		data.id,
		data.cats,
		data.no_alt_ast,
		data.suppress_redundant_wikilink_cat
	)
end

--[==[Replace any links with links to the correct section, but don't link the whole text if no embedded links are found. Returns the display text form.]==]
function export.embedded_language_links(data)
	if type(data) ~= "table" then
		error(
		"The first argument to the function embedded_language_links must be a table. See Module:links/documentation for more information.")
	elseif data.term and data.term:find("\\", nil, true) or data.alt and data.alt:find("\\", nil, true) then
		track("escaped", "embedded_language_links")
	end

	local term, lang, sc = data.term, data.lang, data.sc

	-- If we don't have a script, get one.
	if not sc then
		sc = lang:findBestScript(term)
	end

	-- Do we have embedded wikilinks? If so, they need to be processed individually.
	local open = find(term, "[[", nil, true)
	if open and find(term, "]]", open + 2, true) then
		return process_embedded_links(term, data.alt, lang, sc, data.id, data.cats, data.no_alt_ast)
	end

	-- If not, return the display text.
	term = selective_trim(term)
	-- FIXME: Double-escape any percent-signs, because we don't want to treat non-linked text as having percent-encoded
	-- characters. This is a hack: percent-decoding should come out of [[Module:languages]] and only dealt with in this
	-- module, as it's specific to links.
	term = term:gsub("%%", "%%25")
	return lang:makeDisplayText(term, sc, true)
end

function export.mark(text, item_type, face, lang)
	local tag = { "", "" }

	if item_type == "gloss" then
		tag = { '<span class="mention-gloss-double-quote">“</span><span class="mention-gloss">',
			'</span><span class="mention-gloss-double-quote">”</span>' }
		if type(text) == "string" and text:match("^''[^'].*''$") then
			-- Temporary tracking for mention glosses that are entirely italicized or bolded, which is probably
			-- wrong. (Note that this will also find bolded mention glosses since they use triple apostrophes.)
			track("italicized-mention-gloss", lang and lang:getFullCode() or nil)
		end
	elseif item_type == "tr" then
		if face == "term" then
			tag = { '<span lang="' .. lang:getFullCode() .. '" class="tr mention-tr Latn">',
				'</span>' }
		else
			tag = { '<span lang="' .. lang:getFullCode() .. '" class="tr Latn">', '</span>' }
		end
	elseif item_type == "ts" then
		-- \226\129\160 = word joiner (zero-width non-breaking space) U+2060
		tag = { '<span class="ts mention-ts Latn">/\226\129\160', '\226\129\160/</span>' }
	elseif item_type == "pos" then
		tag = { '<span class="ann-pos">', '</span>' }
	elseif item_type == "non-gloss" then
		tag = { '<span class="ann-non-gloss">', '</span>' }
	elseif item_type == "annotations" then
		tag = { '<span class="mention-gloss-paren annotation-paren">(</span>',
			'<span class="mention-gloss-paren annotation-paren">)</span>' }
	elseif item_type == "infl" then
		tag = { '<span class="ann-infl">', '</span>' }
	end

	if type(text) == "string" then
		return tag[1] .. text .. tag[2]
	else
		return ""
	end
end

--[=[
Implementation of `format_transliteration` and `format_transcription`. The implementation is identical except that the
field containing the transliteration or transcription may vary and is specified in `field`, and the way a given
transliteration or transcription is tagged may vary and is controlled by `tag_fn`, which is passed three parameters:
`text` (the transliteration or transcription), `lang` (the language passed in) and `face` (the face passed in).
On input, `item` is the transliteration or transcription or list of such objects; `field` is either {"tr"} or {"ts"};
`tag_fn` is a function of three parameters to tag the item, as described above; `lang` is the language object of the
term whose transliteration or transcription is specified; and `face` is a string indicating how to display the item
(generally only the strings {"term"} and {"default"} are recognized).
]=]
local function format_transliteration_or_transcription(item, field, tag_fn, lang, item_face)
	if type(item) == "string" then
		return tag_fn(item, lang, item_face)
	end
	local formatted_items = {}
	for _, itemobj in ipairs(item) do
		local tagged_item = tag_fn(itemobj[field], lang, item_face)
		tagged_item = add_text_decorations(tagged_item, item, lang)
		insert(formatted_items, tagged_item)
	end

	if formatted_items[2] then
		-- FIXME: This should be customizable.
		return concat(formatted_items, " <i>or</i> ")
	else
		return formatted_items[1]
	end
end

--[==[
Format a transliteration string or list of transliteration objects. `tr` contains the transliteration(s), which for
forward compatibility reasons can only be either a single transliteration string or a list of transliteration objects
(each of which has a `tr` field holding the transliteration and optional fields `q`, `qq`, `l`, `ll` and/or `refs`).
This correctly handles multiple transliterations as well as decorations (qualifiers, labels or references) attached to
transliterations.
]==]
function export.format_transliteration(tr, lang, face)
	return format_transliteration_or_transcription(tr, "tr", tag_translit, lang, face)
end

local function tag_transcription(ts, _lang, _face)
	return export.mark(ts, "ts")
end

--[==[
Format a transcription string or list of transcription objects. `ts` contains the transcription(s), which for forward
compatibility reasons can only be either a single transcription string or a list of transcription objects (each of which
has a `ts` field holding the transcription and optional decoration fields `q`, `qq`, `l`, `ll` and/or `refs`). This
correctly handles multiple transcriptions as well as decorations (qualifiers, labels or references) attached to
transcriptions.
]==]
function export.format_transcription(ts, lang, face)
	return format_transliteration_or_transcription(ts, "ts", tag_transcription, lang, face)
end

local pos_tags

--[==[
Format the annotations that are displayed with a link created by `full_link()`. Annotations are the extra bits of
information that are displayed following the linked term, and include things such as gender, transliteration, gloss,
etc. The first argument is a table with some or all of the following keys (all are optional):
* `interwiki`: An interwiki link. This is used for links in translation tables to the corresponding term in another
	Wiktionary. If specified, it should be a fully formatted link and is inserted as-is at the beginning of the output.
	See the `interwiki()` function in [[Module:translations]].
* `genders`: Table containing a list of gender specifications in the style of [[Module:gender and number]]. If
	specified, these are formatted using `format_genders()` in [[Module:gender and number]] and the result inserted at
	the beginning of the output, following any interwiki link and (in all cases) directly after a no-break space.
* `tr`: Transliteration or transliterations. Currently, this is always a one-item list. It is a list because of
	potential support for per-alternant transliterations due to the multiple alternants (separated by `//`) that can be
	specified in `term` or `alt`. The item in the list can be either a string or a list of transliteration objects (see
	`format_transliteration()`).
* `ts`: Transcription or transcriptions. Like `tr`, this is currently always a one-item list, with the item being either
	a single string or a list of transcription objects, as described in `format_transcription()`.
* `gloss`: Gloss that translates the term in the link.
* `pos`: Part of speech of the linked term. If the given argument matches one of the aliases in `pos_aliases` in
	[[Module:headword/data]], or consists of a part of speech or alias followed by `f` (for a non-lemma form), expand it
	appropriately. Otherwise, just show the given text as it is.
* `infl`: A list of tags, each a string. Multiple tag sets may be encoded in this list by separating them with an
	element consisting of a semicolon. If there are multiple tag sets, they are formatted individually and separated
	by a semicolon + space.
* `ng`: Arbitrary non-gloss descriptive text for the link. This should be used in preference to putting descriptive text
	in `gloss` or `pos`.
* `lit`: Literal meaning of the term, if the usual meaning is figurative or idiomatic.
* `postprocess_annotations`: A function to postprocess the annotations, after they have been formatted (see below).
The `interwiki` and `genders` properties are formatted specially, and `postprocess_annotations` is a callback function
rather than an item to display; all others are formatted (each in their own way), separated by commas and placed inside
of parentheses (except that if both transliteration and transcription are present, they are separated by a space). The
order of the annotations is `tr`+`ts`, `gloss`, `pos`, `infl`, `ng` and `lit`. The `postprocess_annotations` function,
if supplied, is passed a single object, a table with two keys `data` (the `data` object passed into
`format_link_annotations()`) and `annotations` (the formatted annotations, prior to being concatenated). It should
side-effect the `annotations` list, e.g. by inserting more annotations. (It is used to handle nested inflections in
[[Module:headword]]. FIXME: It should probably be generalized so that it can return the final formatted string, to allow
for e.g. changing the way the annotations are formatted.)
* The second argument is a string controlling the "face" that the terms are displayed in. Currently it only affects
transliteration and transcription and only when the value {"term"} is passed in, in which case those annotations are
displayed italicized.
]==]
function export.format_link_annotations(data, face)
	local output = {}

	-- Interwiki link
	if data.interwiki then
		insert(output, data.interwiki)
	end

	-- Genders
	if type(data.genders) ~= "table" then
		data.genders = { data.genders }
	end

	if data.genders and data.genders[1] then
		local genders, gender_cats = format_genders(data.genders, data.lang)
		insert(output, "&nbsp;" .. genders)
		if gender_cats then
			local cats = data.cats
			if cats then
				extend(cats, gender_cats)
			end
		end
	end

	local annotations = {}

	-- Transliteration and transcription
	local tr = data.tr and data.tr[1] or nil
	local ts = data.ts and data.ts[1] or nil
	if tr or ts then
		local item_face
		if face == "term" then
			item_face = face
		else
			item_face = "default"
		end

		local formatted_tr = tr and export.format_transliteration(tr, data.lang, item_face) or nil
		local formatted_ts = ts and export.format_transcription(ts, data.lang, item_face) or nil
		if formatted_tr and formatted_ts then
			insert(annotations, formatted_tr .. " " .. formatted_ts)
		else
			insert(annotations, formatted_tr or formatted_ts)
		end
	end

	-- Gloss/translation
	if data.gloss then
		insert(annotations, export.mark(data.gloss, "gloss"))
	end

	-- Part of speech
	if data.pos then
		-- debug category for pos= containing transcriptions
		if data.pos:match("/[^><]-/") then
			data.pos = data.pos .. "[[Category:links likely containing transcriptions in pos]]"
		end

		-- Canonicalize part of speech aliases as well as non-lemma aliases like 'nf' or 'nounf' for "noun form".
		pos_tags = pos_tags or (m_headword_data or get_headword_data()).pos_aliases
		local pos = pos_tags[data.pos]
		if not pos and data.pos:find("f$") then
			local pos_form = data.pos:sub(1, -2)
			-- We only expand something ending in 'f' if the result is a recognized non-lemma POS.
			pos_form = (pos_tags[pos_form] or pos_form) .. " form"
			if (m_headword_data or get_headword_data()).nonlemmas[pos_form .. "s"] then
				pos = pos_form
			end
		end
		insert(annotations, export.mark(pos or data.pos, "pos"))
	end

	-- Inflection data
	if data.infl then
		local m_form_of = require(form_of_module)
		-- Split tag sets manually, since tagged_inflections creates a numbered list, and we do not want that.
		local infl_outputs = {}
		local tag_sets = m_form_of.split_tag_set(data.infl)
		for _, tag_set in ipairs(tag_sets) do
			table.insert(infl_outputs,
				m_form_of.tagged_inflections({ tags = tag_set, lang = data.lang, nocat = true, nolink = true, nowrap = true }))
		end
		insert(annotations, export.mark(table.concat(infl_outputs, "; "), "infl"))
	end

	-- Non-gloss text
	if data.ng then
		insert(annotations, export.mark(data.ng, "non-gloss"))
	end

	-- Literal/sum-of-parts meaning
	if data.lit then
		insert(annotations, "literally " .. export.mark(data.lit, "gloss"))
	end

	-- Provide a hook to insert additional annotations such as nested inflections.
	if data.postprocess_annotations then
		data.postprocess_annotations {
			data = data,
			annotations = annotations
		}
	end

	if annotations[1] then
		insert(output, " " .. export.mark(concat(annotations, ", "), "annotations"))
	end

	return concat(output)
end

-- Encode certain characters to avoid various delimiter-related issues at various stages. We need to encode < and >
-- because they end up forming part of CSS class names inside of <span ...> and will interfere with finding the end
-- of the HTML tag. I first tried converting them to URL encoding, i.e. %3C and %3E; they then appear in the URL as
-- %253C and %253E, which get mapped back to %3C and %3E when passed to [[Module:accel]]. But mapping them to &lt;
-- and &gt; somehow works magically without any further work; they appear in the URL as < and >, and get passed to
-- [[Module:accel]] as < and >. I have no idea who along the chain of calls is doing the encoding and decoding. If
-- someone knows, please modify this comment appropriately!
local accel_char_map
local function get_accel_char_map()
	accel_char_map = {
		["%"] = ".",
		[" "] = "_",
		["_"] = u(0xFFF0),
		["<"] = "&lt;",
		[">"] = "&gt;",
	}
	return accel_char_map
end

local function encode_accel_param_chars(param)
	return (param:gsub("[%% <>_]", accel_char_map or get_accel_char_map()))
end

local function encode_accel_param(prefix, param)
	if not param then
		return ""
	end
	if type(param) == "table" then
		local filled_params = {}
		-- There may be gaps in the sequence, especially for translit params.
		local maxindex = 0
		for k in pairs(param) do
			if type(k) == "number" and k > maxindex then
				maxindex = k
			end
		end
		for i = 1, maxindex do
			filled_params[i] = param[i] or ""
		end
		-- [[Module:accel]] splits these up again.
		param = concat(filled_params, "*~!")
	end
	-- This is decoded again by [[WT:ACCEL]].
	return prefix .. encode_accel_param_chars(param)
end

local function insert_if_not_blank(list, item)
	if item == "" then
		return
	end
	insert(list, item)
end

local function get_css_classes(lang, tr, accel, nowrap)
	if not accel and not nowrap then
		return ""
	end
	local classes = {}
	if accel then
		insert(classes, "form-of lang-" .. lang:getFullCode())
		local form = accel.form
		if form then
			insert(classes, encode_accel_param_chars(form) .. "-form-of")
		end
		insert_if_not_blank(classes, encode_accel_param("gender-", accel.gender))
		insert_if_not_blank(classes, encode_accel_param("pos-", accel.pos))
		insert_if_not_blank(classes, encode_accel_param("transliteration-", accel.translit or (tr ~= "-" and tr or nil)))
		insert_if_not_blank(classes, encode_accel_param("target-", accel.target))
		insert_if_not_blank(classes, encode_accel_param("origin-", accel.lemma))
		insert_if_not_blank(classes, encode_accel_param("origin_transliteration-", accel.lemma_translit))
		if accel.no_store then
			insert(classes, "form-of-nostore")
		end
	end
	if nowrap then
		insert(classes, nowrap)
	end
	return concat(classes, " ")
end

--[==[
Creates a full link, with annotations (see `##format_link_annotations`), in the style of {{tl|l}} or {{tl|m}}.
The first argument, `data`, must be a table. It contains the various elements that can be supplied as parameters to
{{tl|l}} or {{tl|m}}:
{ {
	-- Basic link-related fields
	term = "entry_to_link_to",
	alt = "link_text_or_displayed_text",
	lang = language_object,
	sc = script_object,
	fragment = "link_fragment",
	id = "sense_id",
	accel = {accelerated_creation_tags},

	-- Link annotation fields
	interwiki = "interwiki_link",
	genders = {"gender1", "gender2", ...} or {{spec = "gender1", q = {"left qualifier", ...}, qq = {"right qualifier"}, ...}, ...},
	tr = "transliteration" or "-" or {{tr = "transliteration", q = {"left_qualifier", ...}, qq = {"right_qualifier", ...}, ..., genders = {gender_spec, ...}}, ...},
	ts = "transcription" or {{ts = "transliteration", q = {"left_qualifier", ...}, qq = {"right_qualifier", ...}, ..., genders = {gender_spec, ...}}, ...},
	gloss = "gloss",
	pos = "part_of_speech_tag",
	infl = {"infl1_tag1", "infl1_tag2", ..., ";", "infl2_tag1", "infl2_tag2", ...},
	ng = "non-gloss text",
	lit = "literal_translation",
	postprocess_annotations = function({data = full_link_data, annotations = {"annotation1", "annotation2", ...}}) -> nil,

	-- Other transliteration-related fields
	respect_link_tr = boolean,
	never_call_transliteration_module = boolean,
	suppress_tr = boolean,

	-- Decoration fields
	q = { "left_qualifier1", "left_qualifier2", ...} or "left_qualifier",
	qq = { "right_qualifier1", "right_qualifier2", ...} or "right_qualifier",
	l = { "left_label1", "left_label2", ...},
	ll = { "right_label1", "right_label2", ...},
	a = { "left_accent_qualifier1", "left_accent_qualifier2", ...},
	aa = { "right_accent_qualifier1", "right_accent_qualifier2", ...},
	refs = { "formatted_ref1", "formatted_ref2", ...} or { {text = "text", name = "name", group = "group"}, ... },
	pretext = "text_at_beginning",
	posttext = "text_at_end",
	show_decorations = boolean,
	show_qualifiers = boolean,

	-- Fields controlling tracking categories
	track_sc = boolean,
	no_nonstandard_sc_cat = boolean,
	suppress_redundant_wikilink_cat = function(term, alt) -> boolean,

	-- Miscellaneous fields
	no_alt_ast = boolean,
	no_generate_alternants = boolean,
} }
Any one of the items in the `data` table (except for `lang`) may be {nil}. If none of `term`, `alt` and `tr` is present,
a term request will be shown. Thus, calling {full_link{ term = term, lang = lang, sc = sc }}, where `term` is the page
to link to (which may have diacritics that will be stripped and/or embedded bracketed links) and `lang` is a
[[Module:languages#Language objects|language object]] from [[Module:languages]], will give a plain link similar to the
one produced by the template {{tl|l}}, and calling {full_link( { term = term, lang = lang, sc = sc }, "term" )} will
give a link similar to the one produced by the template {{tl|m}}.

The function will:
* Try to determine the script, based on the characters found in the `term` or `alt` argument, if the script was not
  given. If a script is given and `track_sc` is {true}, it will check whether the input script is the same as the one
  which would have been automatically generated and add the category ```lang`` terms with redundant script codes` if
  yes, or ```lang`` terms with non-redundant manual script codes` if no. This should be used when the input script
  object is directly determined by a template's `sc` parameter.
* Call `simple_link()` on the `term` or `alt` forms, to remove diacritics in the page name, process any embedded
  wikilinks and create links to Reconstruction or Appendix pages when necessary. (`simple_link()` is almost exactly the
  same as `##language_link()`; the latter is a simple wrapper around the former that adds a bit of extra tracking.)
* Call `[[Module:script utilities#tag_text]]` to add the appropriate language and script tags to the term and
  italicize terms written in the Latin script if necessary. Accelerated creation tags, as used by [[WT:ACCEL]], are
  included.
* Generate a transliteration, based on the `alt` or `term` arguments, if the script is not Latin, no transliteration was
  provided in `tr` and the combination of the term's language and script support automatic transliteration. The
  transliteration itself will be linked if both `.respect_link_tr` is specified and the language of the term has the
  `link_tr` property set for the script of the term; but not otherwise.
* Add the annotations (transliteration, gender, gloss, etc.) after the link.
* If `no_alt_ast` is specified, then the `alt` text does not need to contain an asterisk if the language is
  reconstructed. This should only be used by modules which really need to allow links to reconstructions that don't
  display asterisks (e.g. number boxes).
* If `suppress_redundant_wikilink_cat` is specified, it should be a function that indicates whether to suppress the
  generation of the ```lang`` links with redundant wikilinks` tracking category. It is passed two arguments, the `term`
  and `alt` parameters. Normally, this tracking category is added whenever the `term` argument consists entirely of a
  one-part or two-part embedded link, which is considered "redundant" in that the link can be rewritten into separate
  `term` and `alt` arguments without any embedded links. For certain wrapping templates, however, otherwise "redundant"
  embedded links are necessary to prevent interpretation of certain characters as delimiters. For example, {{tl|col}}
  and related templates use `~` as a separator, as well as `,` when not followed by a space. In these templates,
  embedded links are required to correctly link to terms containing those delimiters, such as [[Micros~1]] and
  [[1,6-Cleves acid]], but will incorrectly trigger the addition of the tracking category unless the appropriate
  `suppress_redundant_wikilink_cat` function is given.
* If `pretext` or `posttext` is specified, this is text to (respectively) prepend or append to the output, directly
  before processing qualifiers, labels and references. This can be used to add arbitrary extra text inside of the
  qualifiers, labels and references.
* If `show_decorations` is specified, then decorations specified in `data` (i.e. left and right qualifiers, accent
  qualifiers, labels and references) will be displayed, otherwise they will be ignored. (This is because a fair amount
  of code stores decorations in these fields and displays them itself, rather than expecting {full_link()} to display
  them.) '''NOTE:''' `data.show_qualifiers` and the `show_qualifiers` fourth argument both have the same effect as
  `data.show_decorations`. Both are deprecated (and will be removed eventually).
* ]==]
function export.full_link(data, face, allow_self_link, show_qualifiers)
	if type(data) ~= "table" then
		error("The first argument to the function full_link must be a table. "
			.. "See Module:links/documentation for more information.")
	elseif data.term and data.term:find("\\", nil, true) or data.alt and data.alt:find("\\", nil, true) then
		track("escaped", "full_link")
	end
	if show_qualifiers then
		-- FIXME: Convert to error once we've removed all uses, then eventually remove the error code
		track("full_link show_qualifiers param")
		track("full_link show_qualifiers")
	end
	if data.show_qualifiers then
		-- FIXME: Convert to error once we've removed all uses, then eventually remove the error code
		track("full_link show_qualifiers data")
		track("full_link show_qualifiers")
	end
	if data.no_generate_forms then
		-- FIXME: Eventually remove the error code. Added 2026-09-14, remove after 2026-10-14 or so.
		error("Set no_generate_alternants instead of no_generate_forms")
	end

	-- Prevent data from being destructively modified.
	data = shallow_copy(data)

	data.show_decorations = data.show_decorations or data.show_qualifiers or show_qualifiers

	data.cats = {}

	-- Categorize links to "und".
	local lang, cats = data.lang, data.cats
	if cats and lang:getCode() == "und" then
		insert(cats, "Undetermined language links")
	end

	local terms = { true }

	-- Generate multiple alternants if applicable.
	for _, param in ipairs { "term", "alt" } do
		if type(data[param]) == "string" and data[param]:find("//", nil, true) then
			data[param] = export.split_on_slashes(data[param])
		elseif type(data[param]) == "string" and not (type(data.term) == "string" and data.term:find("//", nil, true)) then
			if not data.no_generate_alternants then
				data[param] = lang:generateAlternants(data[param])
			else
				data[param] = { data[param] }
			end
		else
			data[param] = {}
		end
	end

	for _, param in ipairs { "sc", "tr", "ts" } do
		data[param] = { data[param] }
	end

	for _, param in ipairs { "term", "alt", "sc", "tr", "ts" } do
		for i in pairs(data[param]) do
			terms[i] = true
		end
	end

	-- Create the link
	local outparts = {}
	local id, no_alt_ast, suppress_redundant_wikilink_cat, accel, never_call_transliteration_module =
		data.id, data.no_alt_ast, data.suppress_redundant_wikilink_cat, data.accel,
		data.never_call_transliteration_module
	local link_tr = data.respect_link_tr and lang:link_tr(data.sc[1])

	for i in ipairs(terms) do
		local link
		-- Is there any text to show?
		if (data.term[i] or data.alt[i]) then
			-- Try to detect the script if it was not provided
			local display_term = data.alt[i] or data.term[i]
			local best = lang:findBestScript(display_term)
			-- no_nonstandard_sc_cat is intended for use in [[Module:interproject]]
			if (
					not data.no_nonstandard_sc_cat and
					best:getCode() == "None" and
					find_best_script_without_lang(display_term):getCode() ~= "None"
				) then
				insert(cats, lang:getFullName() .. " terms in nonstandard scripts")
			end
			if not data.sc[i] then
				data.sc[i] = best
				-- Track uses of sc parameter.
			elseif data.track_sc then
				if data.sc[i]:getCode() == best:getCode() then
					insert(cats, lang:getFullName() .. " terms with redundant script codes")
				else
					insert(cats, lang:getFullName() .. " terms with non-redundant manual script codes")
				end
			end

			-- If using a discouraged character sequence, add to maintenance category
			if data.sc[i]:hasNormalizationFixes() == true then
				if (data.term[i] and data.sc[i]:fixDiscouragedSequences(toNFC(data.term[i])) ~= toNFC(data.term[i])) or (data.alt[i] and data.sc[i]:fixDiscouragedSequences(toNFC(data.alt[i])) ~= toNFC(data.alt[i])) then
					insert(cats, "Pages using discouraged character sequences")
				end
			end

			link = simple_link(
				data.term[i],
				data.fragment,
				data.alt[i],
				lang,
				data.sc[i],
				id,
				cats,
				no_alt_ast,
				suppress_redundant_wikilink_cat
			)
		end
		-- simple_link can return nil, so check if a link has been generated.
		if link then
			-- Add "nowrap" class to prefixes in order to prevent wrapping after the hyphen
			local nowrap
			local display_term = data.alt[i] or data.term[i]
			if display_term and (display_term:find("^%-") or display_term:find("^־")) then -- Hebrew maqqef -- FIXME, use hyphens from [[Module:affix]]
				nowrap = "nowrap"
			end

			link = tag_text(link, lang, data.sc[i], face, get_css_classes(lang, data.tr[i], accel, nowrap))
		else
			--[[	No term to show.
					Is there at least a transliteration we can work from?	]]
			link = request_script(lang, data.sc[i])
			-- No link to show, and no transliteration either. Show a term request (unless it's a substrate, as they rarely take terms).
			if (link == "" or (not data.tr[i]) or data.tr[i] == "-") and lang:getFamilyCode() ~= "qfa-sub" then
				-- If there are multiple terms, break the loop instead.
				if i > 1 then
					remove(outparts)
					break
				elseif NAMESPACE ~= "Template" then
					insert(cats, lang:getFullName() .. " term requests")
				end
				link = "<small>[Term?]</small>"
			end
		end
		insert(outparts, link)
		if i < #terms then insert(outparts, "<span class=\"Zsym mention\" style=\"font-size:100%;\">&nbsp;/ </span>") end
	end

	-- When suppress_tr is true, do not show or generate any transliteration
	if data.suppress_tr then
		data.tr[1] = nil
	else
		-- TODO: Currently only handles the first transliteration, pending consensus on how to handle multiple translits for multiple forms, as this is not always desirable (e.g. traditional/simplified Chinese).
		if data.tr[1] == "" or data.tr[1] == "-" then
			data.tr[1] = nil
		else
			local phonetic_extraction = load_data("Module:links/data").phonetic_extraction
			phonetic_extraction = phonetic_extraction[lang:getCode()] or phonetic_extraction[lang:getFullCode()]

			if phonetic_extraction then
				data.tr[1] = data.tr[1] or
				require(phonetic_extraction).getTranslit(export.remove_links(data.alt[1] or data.term[1]))
			elseif (data.term[1] or data.alt[1]) and data.sc[1]:isTransliterated() then
				-- Track whenever there is manual translit. The categories below like 'terms with redundant transliterations'
				-- aren't sufficient because they only work with reference to automatic translit and won't operate at all in
				-- languages without any automatic translit, like Persian and Hebrew.
				if data.tr[1] then
					local full_code = lang:getFullCode()
					track("manual-tr", full_code)
				end

				if not never_call_transliteration_module then
					-- Try to generate a transliteration.
					local text = data.alt[1] or data.term[1]
					if not link_tr then
						text = export.remove_links(text, true)
					end

					local automated_tr = lang:transliterate(text, data.sc[1])

					if automated_tr then
						local manual_tr = data.tr[1]

						if manual_tr then
							if export.remove_links(manual_tr) == export.remove_links(automated_tr) then
								insert(cats, lang:getFullName() .. " terms with redundant transliterations")
							else
								-- Prevents Arabic root categories from flooding the tracking categories.
								if NAMESPACE ~= "Category" then
									insert(cats,
										lang:getFullName() .. " terms with non-redundant manual transliterations")
								end
							end
						end

						if not manual_tr or lang:overrideManualTranslit(data.sc[1]) then
							data.tr[1] = automated_tr
						end
					end
				end
			end
		end
	end

	-- Link to the transliteration entry for languages that require this
	if data.tr[1] and link_tr and not data.tr[1]:match("%[%[(.-)%]%]") then
		data.tr[1] = simple_link(
			data.tr[1],
			nil,
			nil,
			lang,
			get_script("Latn"),
			nil,
			cats,
			no_alt_ast,
			suppress_redundant_wikilink_cat
		)
	elseif data.tr[1] and not link_tr then
		-- Remove the pseudo-HTML tags added by remove_links.
		data.tr[1] = data.tr[1]:gsub("</?link>", "")
	end
	if data.tr[1] and not umatch(data.tr[1], "[^%s%p]") then data.tr[1] = nil end

	insert(outparts, export.format_link_annotations(data, face))

	if data.pretext then
		insert(outparts, 1, data.pretext)
	end
	if data.posttext then
		insert(outparts, data.posttext)
	end

	local categories = cats[1] and format_categories(cats, lang, "-", nil, nil, data.sc) or ""

	local output = concat(outparts)
	if data.show_decorations then
		output = add_text_decorations(output, data, lang)
	end
	return output .. categories
end

--[==[
Strip links by replacing all wikilinks with their displayed text, and remove any categories. This function can be
invoked either from a template or from another module. Specifically, this function deletes category links, the targets
of piped links, and any double square brackets involved in links (other than file links, which are untouched). If `tag`
is set, then any links removed will be given pseudo-HTML tags, which allow the substitution functions in
[[Module:languages]] to properly subdivide the text in order to reduce the chance of substitution failures in modules
 which scrape pages like [[Module:zh-translit]]. (FIXME: This is quite hacky. We probably want this to be integrated
into [[Module:languages]], but we can't do that until we know that nothing is pushing pipe linked transliterations
through it for languages which don't have link_tr set.)
* `<nowiki>[[page|displayed text]]</nowiki>` &rarr; `displayed text`
* `<nowiki>[[page and displayed text]]</nowiki>` &rarr; `page and displayed text`
* `<nowiki>[[Category:English lemmas|WORD]]</nowiki>` &rarr; ''(nothing)''
]==]
function export.remove_links(text, tag)
	if type(text) == "table" then
		text = text.args[1]
	end

	if not text or text == "" then
		return ""
	end

	text = text
		:gsub("%[%[", "\1")
		:gsub("%]%]", "\2")

	-- Parse internal links for the display text.
	text = text:gsub("(\1)([^\1\2]-)(\2)",
		function(c1, c2, c3)
			-- Don't remove files.
			for _, false_positive in ipairs({ "file", "image" }) do
				if c2:lower():match("^" .. false_positive .. ":") then return c1 .. c2 .. c3 end
			end
			-- Remove categories completely.
			for _, false_positive in ipairs({ "category", "cat" }) do
				if c2:lower():match("^" .. false_positive .. ":") then return "" end
			end
			-- In piped links, remove all text before the pipe, unless it's the final character (i.e. the pipe trick), in which case just remove the pipe.
			c2 = c2:match("^[^|]*|(.+)") or c2:match("([^|]+)|$") or c2
			if tag then
				return "<link>" .. c2 .. "</link>"
			else
				return c2
			end
		end)

	text = text
		:gsub("\1", "[[")
		:gsub("\2", "]]")

	return text
end

function export.section_link(link)
	if type(link) ~= "string" then
		error("The first argument to section_link was a " .. type(link) .. ", but it should be a string.")
	elseif link:find("\\", nil, true) then
		track("escaped", "section_link")
	end

	local target, section = get_fragment((link:gsub("_", " ")))

	if not section then
		error("No \"#\" delineating a section name")
	end

	return simple_link(
		target,
		section,
		target .. " §&nbsp;" .. section
	)
end

return export
