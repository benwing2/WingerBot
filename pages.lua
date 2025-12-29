local export = {}

local string_utilities_module = "Module:string utilities"

local concat = table.concat
local find = string.find
local format = string.format
local getmetatable = getmetatable
local get_current_section -- defined below
local get_namespace_shortcut -- defined below
local get_pagetype -- defined below
local gsub = string.gsub
local insert = table.insert
local is_internal_title -- defined below
local is_title -- defined below
local lower = string.lower
local match = string.match
local new_title = mw.title.new
local require = require
local sub = string.sub
local title_equals = mw.title.equals
local tonumber = tonumber
local type = type
local ufind = mw.ustring.find
local unstrip_nowiki = mw.text.unstripNoWiki

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
local function decode_entities(...)
	decode_entities = require(string_utilities_module).decode_entities
	return decode_entities(...)
end

local function ulower(...)
	ulower = require(string_utilities_module).lower
	return ulower(...)
end

local function trim(...)
	trim = require(string_utilities_module).trim
	return trim(...)
end

--[==[
Loaders for objects, which load data (or some other object) into some variable, which can then be accessed as "foo or get_foo()", where the function get_foo sets the object to "foo" and then returns it. This ensures they are only loaded when needed, and avoids the need to check for the existence of the object each time, since once "foo" has been set, "get_foo" will not be called again.]==]
local current_frame
local function get_current_frame()
	current_frame, get_current_frame = mw.getCurrentFrame(), nil
	return current_frame
end

local parent_frame
local function get_parent_frame()
	parent_frame, get_parent_frame = (current_frame or get_current_frame()):getParent(), nil
	return parent_frame
end

local namespace_shortcuts
local function get_namespace_shortcuts()
	namespace_shortcuts, get_namespace_shortcuts = {
		[4] = "WT",
		[10] = "T",
		[14] = "CAT",
		[100] = "AP",
		[110] = "WS",
		[118] = "RC",
		[828] = "MOD",
	}, nil
	return namespace_shortcuts
end

do
	local transcluded
	--[==[
	Returns {true} if the current {{tl|#invoke:}} is being transcluded, or {false} if not. If the current {{tl|#invoke:}} is part of a template, for instance, this template will therefore return {true}.
	
	Note that if a template containing an {{tl|#invoke:}} is used on its own page (e.g. to display a demonstration), this function is still able to detect that this is transclusion. This is an improvement over the other method for detecting transclusion, which is to check the parent frame title against the current page title, which fails to detect transclusion in that instance.]==]
	function export.is_transcluded()
		if transcluded == nil then
			transcluded = (parent_frame or get_parent_frame()) and parent_frame:preprocess("<includeonly>1</includeonly>") == "1" or false
		end
		return transcluded
	end
end

do
	local preview
	--[==[
	Returns {true} if the page is currently being viewed in preview, or {false} if not.]==]
	function export.is_preview()
		if preview == nil then
			preview = (current_frame or get_current_frame()):preprocess("{{REVISIONID}}") == ""
		end
		return preview
	end
end

--[==[
Returns {true} if the input is a title object, or {false} if not. This therefore '''includes''' external title objects (i.e. those for pages on other wikis), such as [[w:Example]], unlike `is_internal_title` below.]==]
function export.is_title(val)
	if not (val and type(val) == "table") then
		return false
	end
	local mt = getmetatable(val)
	-- There's no foolproof method for checking for a title object, but the
	-- __eq metamethod should be mw.title.equals unless the object has been
	-- seriously messed around with.
	return mt and
		type(mt) == "table" and
		getmetatable(mt) == nil and
		mt.__eq == title_equals and
		true or false
end
is_title = export.is_title

--[==[
Returns {true} if the input is an internal title object, or {false} if not. An internal title object is a title object for a page on this wiki, such as [[example]]. This therefore '''excludes''' external title objects (i.e. those for pages on other wikis), such as [[w:Example]], unlike `is_title` above.]==]
function export.is_internal_title(title)
	-- Note: Mainspace titles starting with "#" should be invalid, but a bug in mw.title.new and mw.title.makeTitle means a title object is returned that has the empty string for prefixedText, so they need to be filtered out.
	return is_title(title) and #title.prefixedText > 0 and #title.interwiki == 0
end
is_internal_title = export.is_internal_title

--[==[
Returns {true} if the input string is a valid link target, or {false} if not. This therefore '''includes''' link targets to other wikis, such as [[w:Example]], unlike `is_valid_page_name` below.]==]
function export.is_valid_link_target(target)
	local target_type = type(target)
	if target_type == "string" then
		return is_title(new_title(target))
	end
	error(format("bad argument #1 to 'is_valid_link_target' (string expected, got %s)", target_type), 2)
end

--[==[
Returns {true} if the input string is a valid page name on this wiki, or {false} if not. This therefore '''excludes''' page names on other wikis, such as [[w:Example]], unlike `is_valid_link_target` above.]==]
function export.is_valid_page_name(name)
	local name_type = type(name)
	if name_type == "string" then
		return is_internal_title(new_title(name))
	end
	error(format("bad argument #1 to 'is_valid_page_name' (string expected, got %s)", name_type), 2)
end

--[==[
Given a title object, returns a full link target which will always unambiguously link to it.

For instance, the input {"foo"} (for the page [[foo]]) returns {":foo"}, as a leading colon always refers to mainspace, even when other namespaces might be assumed (e.g. when transcluding using `{{ }}` syntax).

If `shortcut` is set, then the returned target will use the namespace shortcut, if any; for example, the title for `Template:foo` would return {"T:foo"} instead of {"Template:foo"}.]==]
function export.get_link_target(title, shortcut)
	if not is_title(title) then
		error(format("bad argument #1 to 'is_valid_link_target' (title object expected, got %s)", type(title)))
	elseif title.interwiki ~= "" then
		return title.fullText
	elseif shortcut then
		local fragment = title.fragment
		if fragment == "" then
			return get_namespace_shortcut(title) .. ":" .. title.text
		end
		return get_namespace_shortcut(title) .. ":" .. title.text .. "#" .. fragment
	elseif title.namespace == 0 then
		return ":" .. title.fullText
	end
	return title.fullText
end

do
	local function find_sandbox(text)
		return find(text, "^User:.") or find(lower(text), "sandbox", 1, true)
	end
	
	local function get_transclusion_subtypes(title, main_type, documentation, page_suffix)
		local text, subtypes = title.text, {main_type}
		-- Any template/module with "sandbox" in the title. These are impossible
		-- to screen for more accurately, as there's no consistent pattern. Also
		-- any user sandboxes in the form (e.g.) "Template:User:...".
		local sandbox = find_sandbox(text)
		if sandbox then
			insert(subtypes, "sandbox")
		end
		-- Any template/module testcases (which can be labelled and/or followed
		-- by further subpages).
		local testcase = find(text, "./[Tt]estcases?%f[%L]")
		if testcase then
			-- Order "testcase" and "sandbox" based on where the patterns occur
			-- in the title.
			local n = sandbox and sandbox < testcase and 3 or 2
			insert(subtypes, n, "testcase")
		end
		-- Any template/module documentation pages.
		if documentation then
			insert(subtypes, "documentation")
		end
		local final = subtypes[#subtypes]
		if not (final == main_type and not page_suffix or final == "sandbox") then
			insert(subtypes, "page")
		end
		return concat(subtypes, " ")
	end
	
	local function get_snippet_subtypes(title, main_type, documentation)
		local ns = title.namespace
		return get_transclusion_subtypes(title, (
			ns == 2 and "user " or
			ns == 8 and match(title.text, "^Gadget-.") and "gadget " or
			""
		) .. main_type, documentation)
	end
	
	--[==[
	Returns the page type of the input title object in a format which can be used in running text.]==]
	function export.get_pagetype(title)
		if not is_internal_title(title) then
			error(mw.dumpObject(title.fullText) .. " is not a valid page name.")
		end
		-- If possibly a documentation page, get the base title and set the
		-- `documentation` flag.
		local content_model, text, documentation = title.contentModel
		if content_model == "wikitext" then
			text = title.text
			if title.isSubpage and title.subpageText == "documentation" then
				local base_title = title.basePageTitle
				if base_title then
					title, content_model, text, documentation = base_title, base_title.contentModel, base_title.text, true
				end
			end
		end
		-- Content models have overriding priority, as they can appear in
		-- nonstandard places due to page content model changes.
		if content_model == "css" or content_model == "sanitized-css" then
			return get_snippet_subtypes(title, "stylesheet", documentation)
		elseif content_model == "javascript" then
			return get_snippet_subtypes(title, "script", documentation)
		elseif content_model == "json" then
			return get_snippet_subtypes(title, "JSON data", documentation)
		elseif content_model == "MassMessageListContent" then
			return get_snippet_subtypes(title, "mass message delivery list", documentation)
		-- Modules.
		elseif content_model == "Scribunto" then
			return get_transclusion_subtypes(title, "module", documentation, false)
		elseif content_model == "text" then
			return "page" -- ???
		-- Otherwise, the content model is "wikitext", so check namespaces.
		elseif title.isTalkPage then
			return "talk page"
		end
		local ns = title.namespace
		-- Main namespace.
		if ns == 0 then
			return "entry"
		-- Wiktionary:
		elseif ns == 4 then
			return find_sandbox(title.text) and "sandbox" or "project page"
		-- Template:
		elseif ns == 10 then
			return get_transclusion_subtypes(title, "template", documentation, false)
		end
		-- Convert the namespace to lowercase, unless it contains a capital
		-- letter after the initial letter (e.g. MediaWiki, TimedText). Also
		-- normalize any underscores.
		local ns_text = gsub(title.nsText, "_", " ")
		if ufind(ns_text, "^%U*$", 2) then
			ns_text = ulower(ns_text)
		end
		-- User:
		if ns == 2 then
			return ns_text .. " " .. (title.isSubpage and "subpage" or "page")
		-- Category: and Appendix:
		elseif ns == 14 or ns == 100 then
			return ns_text
		-- Thesaurus: and Reconstruction:
		elseif ns == 110 or ns == 118 then
			return ns_text .. " entry"
		end
		return ns_text .. " page"
	end
	get_pagetype = export.get_pagetype
end

--[==[
Returns {true} if the input title object is for a content page, or {false} if not. A content page is a page that is considered part of the dictionary itself, and excludes pages for discussion, administration, maintenance etc.]==]
function export.is_content_page(title)
	if not is_internal_title(title) then
		error(mw.dumpObject(title.fullText) .. " is not a valid page name.")
	end
	local ns = title.namespace
	-- (main), Appendix, Thesaurus, Citations, Reconstruction.
	return (ns == 0 or ns == 100 or ns == 110 or ns == 114 or ns == 118) and
		title.contentModel == "wikitext"
end

--[==[
Returns {true} if the input title object is for a documentation page, or {false} if not.]==]
function export.is_documentation(title)
	return match(get_pagetype(title), "%f[%w]documentation%f[%W]") and true or false
end

--[==[
Returns {true} if the input title object is for a sandbox, or {false} if not.

By default, sandbox documentation pages are excluded, but this can be overridden with the `include_documentation` parameter.]==]
function export.is_sandbox(title, include_documentation)
	local pagetype = get_pagetype(title)
	return match(pagetype, "%f[%w]sandbox%f[%W]") and (
		include_documentation or
		not match(pagetype, "%f[%w]documentation%f[%W]")
	) and true or false
end

--[==[
Returns {true} if the input title object is for a testcase page, or {false} if not.

By default, testcase documentation pages are excluded, but this can be overridden with the `include_documentation` parameter.]==]
function export.is_testcase_page(title, include_documentation)
	local pagetype = get_pagetype(title)
	return match(pagetype, "%f[%w]testcase%f[%W]") and (
		include_documentation or
		not match(pagetype, "%f[%w]documentation%f[%W]")
	) and true or false
end

--[==[
Returns the namespace shortcut for the input title object, or else the namespace text. For example, a `Template:` title returns {"T"}, a `Module:` title returns {"MOD"}, and a `User:` title returns {"User"}.]==]
function export.get_namespace_shortcut(title)
	return (namespace_shortcuts or get_namespace_shortcuts())[title.namespace] or title.nsText
end
get_namespace_shortcut = export.get_namespace_shortcut

do
	local function check_level(lvl)
		if type(lvl) ~= "number" then
			error("Heading levels must be numbers.")
		elseif lvl < 1 or lvl > 6 or lvl % 1 ~= 0 then
			error("Heading levels must be integers between 1 and 6.")
		end
		return lvl
	end

	--[==[
	A helper function which iterates over the headings in `text`, which should be the content of a page or (main) section.

	Each iteration returns three values: `sec` (the section title), `lvl` (the section level) and `loc` (the index of the section in the given text, from the first equals sign). The section title will be automatically trimmed, and any HTML entities will be resolved.
	The optional parameter `a` (which should be an integer between 1 and 6) can be used to ensure that only headings of the specified level are iterated over. If `b` is also given, then they are treated as a range.
	The optional parameters `a` and `b` can be used to specify a range, so that only headings with levels in that range are returned.]==]
	local function find_headings(text, a, b)
		a = a and check_level(a) or nil
		b = b and check_level(b) or a or nil
		local start, loc, lvl, sec = 1

		return function()
			repeat
				loc, lvl, sec, start = match(text, "()%f[^%z\n](==?=?=?=?=?)([^\n]+)%2[\t ]*%f[%z\n]()", start)
				lvl = lvl and #lvl
			until not (sec and a) or (lvl >= a and lvl <= b)
			return sec and trim(decode_entities(sec)) or nil, lvl, loc
		end
	end

	local function _get_section(content, name, level)
		if not (content and name) then
			return nil
		elseif find(name, "\n", 1, true) then
			error("Heading name cannot contain a newline.")
		end
		level = level and check_level(level) or nil
		name = trim(decode_entities(name))
		local start
		for sec, lvl, loc in find_headings(content, level and 1 or nil, level) do
			if start and lvl <= level then
				return sub(content, start, loc - 1)
			elseif not start and (not level or lvl == level) and sec == name then
				start, level = loc, lvl
			end
		end
		return start and sub(content, start)
	end

	--[==[
	A helper function to return the content of a page section.

	`content` is raw wikitext, `name` is the requested section, and `level` is an optional parameter that specifies
	the required section heading level. If `level` is not supplied, then the first section called `name` is returned.
	`name` can either be a string or table of section names. If a table, each name represents a section that has the
	next as a subsection. For example, { {"Spanish", "Noun"}} will return the first matching section called "Noun"
	under a section called "Spanish". These do not have to be at adjacent levels ("Noun" might be L4, while "Spanish"
	is L2). If `level` is given, it refers to the last name in the table (i.e. the name of the section to be returned).

	The returned section includes all of its subsections. If no matching section is found, return {nil}.]==]
	function export.get_section(content, names, level)
		if type(names) ~= "table" then
			return _get_section(content, names, level)
		end
		local i = 1
		local name = names[i]
		if not name then
			error("Must specify at least 1 section.")
		end
		while true do
			local nxt_i = i + 1
			local nxt = names[nxt_i]
			if nxt == nil then
				return _get_section(content, name, level)
			end
			content = _get_section(content, name)
			if content == nil then
				return nil
			elseif i == 6 then
				error("Not possible specify more than 6 sections: headings only go up to level 6.")
			end
			i = nxt_i
			name = names[i]
		end
		return content
	end
end

--[==[
Convert a physical pagename (or the current pagename, if {nil} is passed in) to its logical equivalent, but only if
the physical pagename refers to one of the splits of a mammoth page such as [[a]]. Otherwise this simply returns the
subpage (the part after the last slash in namespace other than the main one, otherwise the same as passed in), unless
`include_base` is specified, in which case the return value will be the whole pagename minus the namespace, including
the base (the part before the final slash).

FIXME: This should be augmented with logic to handle unsupported titles, which is currently in process_page() in
[[Module:headword/page]], so that it is a general physical-to-logical conversion function.

Examples:
* {physical_to_logical_pagename_if_mammoth("a")} → {"a"}
* {physical_to_logical_pagename_if_mammoth("a/languages A to L")} → {"a"} (since [[a]] is marked as a mammoth page in [[Module:links/data]])
* {physical_to_logical_pagename_if_mammoth("50/50")} → {"50/50"} (since [[50/50]] is in the main namespace)
* {physical_to_logical_pagename_if_mammoth("Appendix:Lojban/a")} → "a"
* {physical_to_logical_pagename_if_mammoth("Appendix:Lojban/a", true)} → "Lojban/a"
* {physical_to_logical_pagename_if_mammoth("Reconstruction:Proto-Slavic/a")} → "a"
* {physical_to_logical_pagename_if_mammoth("Reconstruction:Proto-Slavic/a", true)} → "Proto-Slavic/a"
* {physical_to_logical_pagename_if_mammoth("User:Example/sandbox/foo")} → "foo"
* {physical_to_logical_pagename_if_mammoth("User:Example/sandbox/foo", true)} → "Example/sandbox/foo"
]==]
function export.physical_to_logical_pagename_if_mammoth(title, include_base)
	if title == nil then
		title = mw.title.getCurrentTitle()
	elseif not is_title(title) then
		title = mw.title.new(title)
	end

	if title.nsText == "" then
		-- Formerly we checked for the specific known subpages of a given mammoth split page, e.g. we would convert
		-- [[a/languages M to Z]] to [[a]] assuming that [[a/languages M to Z]] was one of the splits, but not
		-- [[a/languages N to Z]]. To simplify this, we just convert anything with the right mammoth split page format
		-- on the assumption that it's unlikely we will ever have a legitimate non-mammoth-split pagename of this sort.
		local pagename = title.text
		local mammoth_root_page = pagename:match("^(.*)/languages [A-Z] to [A-Z]$")
		if mammoth_root_page then
			pagename = mammoth_root_page
		end
		return pagename
	elseif include_base then
		return title.text
	else
		return title.subpageText
	end
end

--[==[
Obsolete name for `physical_to_logical_pagename_if_mammoth`. FIXME: Replace all uses and remove.
]==]
function export.safe_page_name(title)
	return export.physical_to_logical_pagename_if_mammoth(title)
end

do
	local current_section
	--[==[
	A function which returns the number of the page section which contains the current {#invoke}.]==]
	function export.get_current_section()
		if current_section ~= nil then
			return current_section
		end
		local extension_tag = (current_frame or get_current_frame()).extensionTag
		-- We determine the section via the heading strip marker count, since they're numbered sequentially, but the only way to do this is to generate a fake heading via frame:preprocess(). The native parser assigns each heading a unique marker, but frame:preprocess() will return copies of older markers if the heading is identical to one further up the page, so the fake heading has to be unique to the page. The best way to do this is to feed it a heading containing a nowiki marker (which we will need later), since those are always unique.
		local nowiki_marker = extension_tag(current_frame, "nowiki")
		-- Note: heading strip markers have a different syntax to the ones used for tags.
		local h = tonumber(match(
			current_frame:preprocess("=" .. nowiki_marker .. "="),
			"\127'\"`UNIQ%-%-h%-(%d+)%-%-QINU`\"'\127"
		))
		-- For some reason, [[Special:ExpandTemplates]] doesn't generate a heading strip marker, so if that happens we simply abort early.
		if not h then
			return 0
		end
		-- The only way to get the section number is to increment the heading count, so we store the offset in nowiki strip markers which can be retrieved by procedurally unstripping nowiki markers, counting backwards until we find a match.
		local n, offset = tonumber(match(
			nowiki_marker,
			"\127'\"`UNIQ%-%-nowiki%-([%dA-F]+)%-QINU`\"'\127"
		), 16)
		while not offset and n > 0 do
			n = n - 1
			offset = match(
				unstrip_nowiki(format("\127'\"`UNIQ--nowiki-%08X-QINU`\"'\127", n)),
				"^HEADING\1(%d+)" -- Prefix "HEADING\1" prevents collisions.
			)
		end
		offset = offset and (offset + 1) or 0
		extension_tag(current_frame, "nowiki", "HEADING\1" .. offset)
		current_section = h - offset
		return current_section
	end
	get_current_section = export.get_current_section
end

do
	local L2_sections, current_L2
	
	local function get_L2_sections()
		L2_sections, get_L2_sections = mw.loadData("Module:headword/data").page.L2_sections, nil
		return L2_sections
	end
	
	--[==[
	A function which returns the name of the L2 language section which contains the current {#invoke}.]==]
	function export.get_current_L2()
		if current_L2 ~= nil then
			return current_L2 or nil -- Return nil if current_L2 is false (i.e. there's no L2).
		end
		local section = get_current_section()
		while section > 0 do
			local L2 = (L2_sections or get_L2_sections())[section]
			if L2 then
				current_L2 = L2
				return L2
			end
			section = section - 1
		end
		current_L2 = false
		return nil
	end
end

return export
