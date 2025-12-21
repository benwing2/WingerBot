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
local gender_and_number_module = "Module:gender and number"
local languages_module = "Module:languages"
local load_module = "Module:load"
local memoize_module = "Module:memoize"
local pages_module = "Module:pages"
local pron_qualifier_module = "Module:pron qualifier"
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

local NAMESPACE = get_current_title().namespace

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

local function format_qualifiers(...)
	format_qualifiers = require(pron_qualifier_module).format_qualifiers
	return format_qualifiers(...)
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

local function selective_trim(...)
	-- Unconditionally trimmed charset.
	local always_trim =
		"\194\128-\194\159" ..			-- U+0080-009F (C1 control characters)
		"\194\173" ..					-- U+00AD (soft hyphen)
		"\226\128\170-\226\128\174" ..	-- U+202A-202E (directionality formatting characters)
		"\226\129\166-\226\129\169"		-- U+2066-2069 (directionality formatting characters)

	-- Standard trimmed charset.
	local standard_trim = "%s" ..		-- (default whitespace charset)
		"\226\128\139-\226\128\141" ..	-- U+200B-200D (zero-width spaces)
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

--[==[Takes an input and splits on a double slash (taking account of escaping backslashes).]==]
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

--[==[Takes a wikilink and outputs the link target and display text. By default, the link target will be returned as a title object, but if `allow_bad_target` is set it will be returned as a string, and no check will be performed as to whether it is a valid link target.]==]
function export.get_wikilink_parts(text, allow_bad_target)
	-- TODO: replace `allow_bad_target` with `allow_unsupported`, with support for links to unsupported titles, including escape sequences.
	if ( -- Filters out anything but "[[...]]" with no intermediate "[[" or "]]".
		not match(text, "^()%[%[") or -- Faster than sub(text, 1, 2) ~= "[[".
		find(text, "[[", 3, true) or
		find(text, "]]", 3, true) ~= #text - 1
	) then
		return nil, nil
	end
	local pipe, title, display = find(text, "|", 3, true)
	if pipe then
		title, display = sub(text, 3, pipe - 1), sub(text, pipe + 1, -3)
	else
		title = sub(text, 3, -3)
		display = title
	end
	if allow_bad_target then
		return title, display
	end
	title = new_title(title)
	-- No title object means the target is invalid.
	if title == nil then
		return nil, nil
	-- If the link target starts with "#" then mw.title.new returns a broken
	-- title object, so grab the current title and give it the correct fragment.
	elseif title.prefixedText == "" then
		local fragment = title.fragment
		if fragment == "" then -- [[#]] isn't valid
			return nil, nil
		end
		title = get_current_title()
		title.fragment = fragment
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
	fragment = fragment and unescape(fragment, "#")
	return target, fragment
end

--[==[Takes a link target and outputs the actual target and the fragment (if any).]==]
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
	return text
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
		-- If this is an a link to another namespace or an interwiki link, ensure there's an initial colon and then return what we have (so that it works as a conventional link, and doesn't do anything weird like add the term to a category.)
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
	target = lang:makeEntryName(target, sc, reconstructed == 1)

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
		error("The specified language " .. lang:getCanonicalName()
			.. " is unattested, while the given term does not begin with '*' to indicate that it is reconstructed.")
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

-- Make a link from a given link's parts
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
			-- If the alt text is the same as what would have been automatically generated, then the alt parameter is redundant (e.g. {{l|en|foo|foo}}, {{l|en|w:foo|foo}}, but not {{l|en|w:foo|w:foo}}).
			-- If they're different, but the alt text could have been entered as the term parameter without it affecting the target page, then the target parameter is redundant (e.g. {{l|ru|фу|фу́}}).
			-- If `no_alt_ast` is true, use pcall to catch the error which will be thrown if this is a reconstructed lang and the alt text doesn't have *.
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
	if isolated and #link.display > 0 and not umatch(decode_entities(link.display), "%S") then
		link.display = "&#x5D;" .. link.display .. "&#x5B;"
	end

	link.target = link.target:gsub("^(:?)(.*)", function(m1, m2)
		return m1 .. encode_entities(m2, "#%&+/:<=>@[\\]_{|}")
	end)
	
	link.fragment = link.fragment and encode_entities(remove_formatting(link.fragment), "#%&+/:<=>@[\\]_{|}")
	return "[[" .. link.target:gsub("^[^:]", ":%0") .. (link.fragment and "#" .. link.fragment or "") .. "|" .. link.display .. "]]"
end


-- Split a link into its parts
local function parse_link(linktext)
	local link = {target = linktext}

	local target = link.target
	link.target, link.display = target:match("^(..-)|(.+)$")
	if not link.target then
		link.target = target
		link.display = target
	end

	-- There's no point in processing these, as they aren't real links.
	local target_lower = link.target:lower()
	for _, false_positive in ipairs({"category", "cat", "file", "image"}) do
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

local function simple_link(term, fragment, alt, lang, sc, id, cats, no_alt_ast, srwc)
	local plain
	if lang == nil then
		lang, plain = get_lang("und"), true
	end
	
	-- Get the link target and display text. If the term is the empty string, treat the input as a link to the current page.
	if term == "" then
		term = get_current_title().prefixedText
	elseif term then
		local new_term, new_alt = export.get_wikilink_parts(term, true)
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
					if not (srwc and srwc(term, alt)) then
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

--[==[Creates a basic link to the given term. It links to the language section (such as <code>==English==</code>), but it does not add language and script wrappers, so any code that uses this function should call the <code class="n">[[Module:script utilities#tag_text|tag_text]]</code> from [[Module:script utilities]] to add such wrappers itself at some point.
The first argument, <code class="n">data</code>, may contain the following items, a subset of the items used in the <code class="n">data</code> argument of <code class="n">full_link</code>. If any other items are included, they are ignored.
{ {
	term = entry_to_link_to,
	alt = link_text_or_displayed_text,
	lang = language_object,
	id = sense_id,
} }
; <code class="n">term</code>
: Text to turn into a link. This is generally the name of a page. The text can contain wikilinks already embedded in it. These are processed individually just like a single link would be. The <code class="n">alt</code> argument is ignored in this case.
; <code class="n">alt</code> (''optional'')
: The alternative display for the link, if different from the linked page. If this is {{code|lua|nil}}, the <code class="n">text</code> argument is used instead (much like regular wikilinks). If <code class="n">text</code> contains wikilinks in it, this argument is ignored and has no effect. (Links in which the alt is ignored are tracked with the tracking template {{whatlinkshere|tracking=links/alt-ignored}}.)
; <code class="n">lang</code>
: The [[Module:languages#Language objects|language object]] for the term being linked. If this argument is defined, the function will determine the language's canonical name (see [[Template:language data documentation]]), and point the link or links in the <code class="n">term</code> to the language's section of an entry, or to a language-specific senseid if the <code class="n">id</code> argument is defined.
; <code class="n">id</code> (''optional'')
: Sense id string. If this argument is defined, the link will point to a language-specific sense id ({{ll|en|identifier|id=HTML}}) created by the template {{temp|senseid}}. A sense id consists of the language's canonical name, a hyphen (<code>-</code>), and the string that was supplied as the <code class="n">id</code> argument. This is useful when a term has more than one sense in a language. If the <code class="n">term</code> argument contains wikilinks, this argument is ignored. (Links in which the sense id is ignored are tracked with the tracking template {{whatlinkshere|tracking=links/id-ignored}}.)
The second argument is as follows:
; <code class="n">allow_self_link</code>
: If {{code|lua|true}}, the function will also generate links to the current page. The default ({{code|lua|false}}) will not generate a link but generate a bolded "self link" instead.
The following special options are processed for each link (both simple text and with embedded wikilinks):
* The target page name will be processed to generate the correct entry name. This is done by the [[Module:languages#makeEntryName|makeEntryName]] function in [[Module:languages]], using the <code class="n">entry_name</code> replacements in the language's data file (see [[Template:language data documentation]] for more information). This function is generally used to automatically strip dictionary-only diacritics that are not part of the normal written form of a language.
* If the text starts with <code class="n">*</code>, then the term is considered a reconstructed term, and a link to the Reconstruction: namespace will be created. If the text contains embedded wikilinks, then <code class="n">*</code> is automatically applied to each one individually, while preserving the displayed form of each link as it was given. This allows linking to phrases containing multiple reconstructed terms, while only showing the * once at the beginning.
* If the text starts with <code class="n">:</code>, then the link is treated as "raw" and the above steps are skipped. This can be used in rare cases where the page name begins with <code class="n">*</code> or if diacritics should not be stripped. For example:
** {{temp|l|en|*nix}} links to the nonexistent page [[Reconstruction:English/nix]] (<code class="n">*</code> is interpreted as a reconstruction), but {{temp|l|en|:*nix}} links to [[*nix]].
** {{temp|l|sl|Franche-Comté}} links to the nonexistent page [[Franche-Comte]] (<code>é</code> is converted to <code>e</code> by <code class="n">makeEntryName</code>), but {{temp|l|sl|:Franche-Comté}} links to [[Franche-Comté]].]==]
function export.language_link(data)
	if type(data) ~= "table" then
		error("The first argument to the function language_link must be a table. See Module:links/documentation for more information.")
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
		error("The first argument to the function plain_link must be a table. See Module:links/documentation for more information.")
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
		error("The first argument to the function embedded_language_links must be a table. See Module:links/documentation for more information.")
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
	-- FIXME: Double-escape any percent-signs, because we don't want to treat non-linked text as having percent-encoded characters. This is a hack: percent-decoding should come out of [[Module:languages]] and only dealt with in this module, as it's specific to links.
	term = term:gsub("%%", "%%25")
	return (lang:makeDisplayText(term, sc, true))
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
	end

	if type(text) == "string" then
		return tag[1] .. text .. tag[2]
	else
		return ""
	end
end

local pos_tags

--[==[Formats the annotations that are displayed with a link created by {{code|lua|full_link}}. Annotations are the extra bits of information that are displayed following the linked term, and include things such as gender, transliteration, gloss and so on. 
* The first argument is a table possessing some or all of the following keys:
*:; <code class="n">genders</code>
*:: Table containing a list of gender specifications in the style of [[Module:gender and number]].
*:; <code class="n">tr</code>
*:: Transliteration.
*:; <code class="n">gloss</code>
*:: Gloss that translates the term in the link, or gives some other descriptive information.
*:; <code class="n">pos</code>
*:: Part of speech of the linked term. If the given argument matches one of the aliases in `pos_aliases` in [[Module:headword/data]], or consists of a part of speech or alias followed by `f` (for a non-lemma form), expand it appropriately. Otherwise, just show the given text as it is.
*:; <code class="n">ng</code>
*:: Arbitrary non-gloss descriptive text for the link. This should be used in preference to putting descriptive text in `gloss` or `pos`.
*:; <code class="n">lit</code>
*:: Literal meaning of the term, if the usual meaning is figurative or idiomatic.
*:Any of the above values can be omitted from the <code class="n">info</code> argument. If a completely empty table is given (with no annotations at all), then an empty string is returned.
* The second argument is a string. Valid values are listed in [[Module:script utilities/data]] "data.translit" table.]==]
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

	if data.genders and #data.genders > 0 then
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
	if data.tr and data.tr[1] or data.ts and data.ts[1] then
		local kind
		if face == "term" then
			kind = face
		else
			kind = "default"
		end

		if data.tr[1] and data.ts[1] then
			insert(annotations, tag_translit(data.tr[1], data.lang, kind) .. " " .. export.mark(data.ts[1], "ts"))
		elseif data.ts[1] then
			insert(annotations, export.mark(data.ts[1], "ts"))
		else
			insert(annotations, tag_translit(data.tr[1], data.lang, kind))
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

	if #annotations > 0 then
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
	return (param:gsub("[% <>_]", accel_char_map or get_accel_char_map()))
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

local function get_class(lang, tr, accel, nowrap)
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

-- Add any left or right regular or accent qualifiers, labels or references to a formatted term. `data` is the object
-- specifying the term, which should optionally contain:
-- * a language object in `lang`; required if any accent qualifiers or labels are given;
-- * left regular qualifiers in `q` (an array of strings or a single string); an empty array or blank string will be
--   ignored;
-- * right regular qualifiers in `qq` (an array of strings or a single string); an empty array or blank string will be
--   ignored;
-- * left accent qualifiers in `a` (an array of strings); an empty array will be ignored;
-- * right accent qualifiers in `aa` (an array of strings); an empty array will be ignored;
-- * left labels in `l` (an array of strings); an empty array will be ignored;
-- * right labels in `ll` (an array of strings); an empty array will be ignored;
-- * references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
--   (formatted reference text) and optionally `name` and/or `group`.
-- `formatted` is the formatted version of the term itself.
local function add_qualifiers_and_refs_to_term(data, formatted)
	local q = data.q
	if type(q) == "string" then
		q = {q}
	end
	local qq = data.qq
	if type(qq) == "string" then
		qq = {qq}
	end
	if q and q[1] or qq and qq[1] or data.a and data.a[1] or data.aa and data.aa[1] or data.l and data.l[1] or
		data.ll and data.ll[1] or data.refs and data.refs[1] then
		formatted = format_qualifiers{
			lang = data.lang,
			text = formatted,
			q = q,
			qq = qq,
			a = data.a,
			aa = data.aa,
			l = data.l,
			ll = data.ll,
			refs = data.refs,
		}
	end

	return formatted
end


--[==[Creates a full link, with annotations (see <code class="n">[[#format_link_annotations|format_link_annotations]]</code>), in the style of {{temp|l}} or {{temp|m}}.
The first argument, <code class="n">data</code>, must be a table. It contains the various elements that can be supplied as parameters to {{temp|l}} or {{temp|m}}:
{ {
	term = entry_to_link_to,
	alt = link_text_or_displayed_text,
	lang = language_object,
	sc = script_object,
	track_sc = boolean,
	no_nonstandard_sc_cat = boolean,
	fragment = link_fragment,
	id = sense_id,
	genders = { "gender1", "gender2", ... },
	tr = transliteration,
	ts = transcription,
	gloss = gloss,
	pos = part_of_speech_tag,
	ng = non-gloss text,
	lit = literal_translation,
	no_alt_ast = boolean,
	accel = {accelerated_creation_tags},
	interwiki = interwiki,
	pretext = "text_at_beginning" or nil,
	posttext = "text_at_end" or nil,
	q = { "left_qualifier1", "left_qualifier2", ...} or "left_qualifier",
	qq = { "right_qualifier1", "right_qualifier2", ...} or "right_qualifier",
	l = { "left_label1", "left_label2", ...},
	ll = { "right_label1", "right_label2", ...},
	a = { "left_accent_qualifier1", "left_accent_qualifier2", ...},
	aa = { "right_accent_qualifier1", "right_accent_qualifier2", ...},
	refs = { "formatted_ref1", "formatted_ref2", ...} or { {text = "text", name = "name", group = "group"}, ... },
	show_qualifiers = boolean,
} }
Any one of the items in the <code class="n">data</code> table may be {{code|lua|nil}}, but an error will be shown if neither <code class="n">term</code> nor <code class="n">alt</code> nor <code class="n">tr</code> is present.
Thus, calling {{code|lua|2=full_link{ term = term, lang = lang, sc = sc } }}, where <code class="n">term</code> is an entry name, <code class="n">lang</code>  is a [[Module:languages#Language objects|language object]] from [[Module:languages]], and <code class="n">sc</code> is a [[Module:scripts#Script objects|script object]] from [[Module:scripts]], will give a plain link similar to the one produced by the template {{temp|l}}, and calling {{code|lua|2=full_link( { term = term, lang = lang, sc = sc }, "term" )}} will give a link similar to the one produced by the template {{temp|m}}.
The function will:
* Try to determine the script, based on the characters found in the term or alt argument, if the script was not given. If a script is given and <code class="n">track_sc</code> is {{code|lua|true}}, it will check whether the input script is the same as the one which would have been automatically generated and add the category [[:Category:Terms with redundant script codes]] if yes, or [[:Category:Terms with non-redundant manual script codes]] if no. This should be used when the input script object is directly determined by a template's <code class="n">sc=</code> parameter.
* Call <code class="n">[[#language_link|language_link]]</code> on the term or alt forms, to remove diacritics in the page name, process any embedded wikilinks and create links to Reconstruction or Appendix pages when necessary.
* Call <code class="n">[[Module:script utilities#tag_text]]</code> to add the appropriate language and script tags to the term, and to italicize terms written in the Latin script if necessary. Accelerated creation tags, as used by [[WT:ACCEL]], are included.
* Generate a transliteration, based on the alt or term arguments, if the script is not Latin and no transliteration was provided.
* Add the annotations (transliteration, gender, gloss, etc.) after the link.
* If <code class="n">no_alt_ast</code> is specified, then the alt text does not need to contain an asterisk if the language is reconstructed. This should only be used by modules which really need to allow links to reconstructions that don't display asterisks (e.g. number boxes).
* If <code class="n">pretext</code> or <code class="n">posttext</code> is specified, this is text to (respectively) prepend or append to the output, directly before processing qualifiers, labels and references. This can be used to add arbitrary extra text inside of the qualifiers, labels and references.
* If <code class="n">show_qualifiers</code> is specified or the `show_qualifiers` field is set, left and right qualifiers, accent qualifiers, labels and references will be displayed, otherwise they will be ignored. (This is because a fair amount of code stores qualifiers, labels and/or references in these fields and displays them itself, rather than expecting {{code|lua|full_link()}} to display them.)]==]
function export.full_link(data, face, allow_self_link, show_qualifiers)
	if data.cats ~= nil then
		track("cats")
	end
	-- Prevent data from being destructively modified.
	local data = shallow_copy(data)

	if type(data) ~= "table" then
		error("The first argument to the function full_link must be a table. "
			.. "See Module:links/documentation for more information.")
	elseif data.term and data.term:find("\\", nil, true) or data.alt and data.alt:find("\\", nil, true) then
		track("escaped", "full_link")
	end
	
	-- FIXME: this shouldn't be added to `data`, as that means the input table needs to be cloned.
	data.cats = {}
	
	-- Categorize links to "und".
	local lang, cats = data.lang, data.cats
	if cats and lang:getCode() == "und" then
		insert(cats, "Undetermined language links")
	end

	local terms = {true}

	-- Generate multiple forms if applicable.
	for _, param in ipairs{"term", "alt"} do
		if type(data[param]) == "string" and data[param]:find("//", nil, true) then
			data[param] = export.split_on_slashes(data[param])
		elseif type(data[param]) == "string" and not (type(data.term) == "string" and data.term:find("//", nil, true)) then
			data[param] = lang:generateForms(data[param])
		else
			data[param] = {}
		end
	end

	for _, param in ipairs{"sc", "tr", "ts"} do
		data[param] = {data[param]}
	end

	for _, param in ipairs{"term", "alt", "sc", "tr", "ts"} do
		for i in pairs(data[param]) do
			terms[i] = true
		end
	end
	
	-- Create the link
	local output = {}
	local id, no_alt_ast, srwc, accel, nevercalltr = data.id, data.no_alt_ast, data.suppress_redundant_wikilink_cat, data.accel, data.never_call_transliteration_module

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
				srwc
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
			
			link = tag_text(link, lang, data.sc[i], face, get_class(lang, data.tr[i], accel, nowrap))
		else
			--[[	No term to show.
					Is there at least a transliteration we can work from?	]]
			link = request_script(lang, data.sc[i])
			-- No link to show, and no transliteration either. Show a term request (unless it's a substrate, as they rarely take terms).
			if (link == "" or (not data.tr[i]) or data.tr[i] == "-") and lang:getFamilyCode() ~= "qfa-sub" then
				-- If there are multiple terms, break the loop instead.
				if i > 1 then
					remove(output)
					break
				elseif NAMESPACE ~= 10 then -- Template:
					insert(cats, lang:getFullName() .. " term requests")
				end
				link = "<small>[Term?]</small>"
			end
		end
		insert(output, link)
		if i < #terms then insert(output, "<span class=\"Zsym mention\" style=\"font-size:100%;\">&nbsp;/ </span>") end
	end

	-- TODO: Currently only handles the first transliteration, pending consensus on how to handle multiple translits for multiple forms, as this is not always desirable (e.g. traditional/simplified Chinese).
	if data.tr[1] == "" or data.tr[1] == "-" then
		data.tr[1] = nil
	else
		local phonetic_extraction = load_data("Module:links/data").phonetic_extraction
		phonetic_extraction = phonetic_extraction[lang:getCode()] or phonetic_extraction[lang:getFullCode()]

		if phonetic_extraction then
			data.tr[1] = data.tr[1] or require(phonetic_extraction).getTranslit(export.remove_links(data.alt[1] or data.term[1]))

		elseif (data.term[1] or data.alt[1]) and data.sc[1]:isTransliterated() then
			-- Track whenever there is manual translit. The categories below like 'terms with redundant transliterations'
			-- aren't sufficient because they only work with reference to automatic translit and won't operate at all in
			-- languages without any automatic translit, like Persian and Hebrew.
			if data.tr[1] then
				local full_code = lang:getFullCode()
				track("manual-tr", full_code)
			end

			if not nevercalltr then
				-- Try to generate a transliteration.
				local text = data.alt[1] or data.term[1]
				if not lang:link_tr(data.sc[1]) then
					text = export.remove_links(text, true)
				end
	
				local automated_tr, tr_categories
				automated_tr, data.tr_fail, tr_categories = lang:transliterate(text, data.sc[1])
	
				if automated_tr or data.tr_fail then
					local manual_tr = data.tr[1]
	
					if manual_tr then
						if (export.remove_links(manual_tr) == export.remove_links(automated_tr)) and (not data.tr_fail) then
							insert(cats, lang:getFullName() .. " terms with redundant transliterations")
						elseif not data.tr_fail then
							-- Prevents Arabic root categories from flooding the tracking categories.
							if NAMESPACE ~= 14 then -- Category:
								insert(cats, lang:getFullName() .. " terms with non-redundant manual transliterations")
							end
						end
					end
					
					if (not manual_tr) or lang:overrideManualTranslit(data.sc[1]) then
						data.tr[1] = automated_tr
						for _, category in ipairs(tr_categories) do
							insert(cats, category)
						end
					end
				end
			end
		end
	end

	-- Link to the transliteration entry for languages that require this
	if data.tr[1] and lang:link_tr(data.sc[1]) and not (data.tr[1]:match("%[%[(.-)%]%]") or data.tr_fail) then
		data.tr[1] = simple_link(
			data.tr[1],
			nil,
			nil,
			lang,
			get_script("Latn"),
			nil,
			cats,
			no_alt_ast,
			srwc
		)
	elseif data.tr[1] and not (lang:link_tr(data.sc[1]) or data.tr_fail) then
		-- Remove the pseudo-HTML tags added by remove_links.
		data.tr[1] = data.tr[1]:gsub("</?link>", "")
	end
	if data.tr[1] and not umatch(data.tr[1], "[^%s%p]") then data.tr[1] = nil end

	insert(output, export.format_link_annotations(data, face))

	if data.pretext then
		insert(output, 1, data.pretext)
	end
	if data.posttext then
		insert(output, data.posttext)
	end

	local categories = cats[1] and format_categories(cats, lang, "-", nil, nil, data.sc) or ""

	output = concat(output)
	if show_qualifiers or data.show_qualifiers then
		output = add_qualifiers_and_refs_to_term(data, output)
	end
	return output .. categories
end

--[==[Replaces all wikilinks with their displayed text, and removes any categories. This function can be invoked either from a template or from another module.
-- Strips links: deletes category links, the targets of piped links, and any double square brackets involved in links (other than file links, which are untouched). If `tag` is set, then any links removed will be given pseudo-HTML tags, which allow the substitution functions in [[Module:languages]] to properly subdivide the text in order to reduce the chance of substitution failures in modules which scrape pages like [[Module:zh-translit]].
-- FIXME: This is quite hacky. We probably want this to be integrated into [[Module:languages]], but we can't do that until we know that nothing is pushing pipe linked transliterations through it for languages which don't have link_tr set.
* <code><nowiki>[[page|displayed text]]</nowiki></code> &rarr; <code><nowiki>displayed text</nowiki></code>
* <code><nowiki>[[page and displayed text]]</nowiki></code> &rarr; <code><nowiki>page and displayed text</nowiki></code>
* <code><nowiki>[[Category:English lemmas|WORD]]</nowiki></code> &rarr; ''(nothing)'']==]
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
			for _, false_positive in ipairs({"file", "image"}) do
				if c2:lower():match("^" .. false_positive .. ":") then return c1 .. c2 .. c3 end
			end
			-- Remove categories completely.
			for _, false_positive in ipairs({"category", "cat"}) do
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
