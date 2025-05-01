-- Prevent substitution.
if mw.isSubsting() then
	return require("Module:unsubst")
end

local export = {}

local m_str_utils = require("Module:string utilities")
local m_template_parser = require("Module:template parser")
local m_utilities = require("Module:utilities")

local ceil = math.ceil
local class_else_type = m_template_parser.class_else_type
local compare_string = require("Module:relation").compare_string
local concat = table.concat
local deep_copy = require("Module:table").deepCopy
local full_url = mw.uri.fullUrl
local insert = table.insert
local is_callable = require("Module:fun").is_callable
local log10 = math.log10 or require("Module:math").log10
local new_title = mw.title.new
local pages_in_category = mw.site.stats.pagesInCategory
local parse = m_template_parser.parse
local remove_comments = m_str_utils.remove_comments
local sort = table.sort
local split = m_str_utils.split
local trim = m_str_utils.trim
local uupper = m_str_utils.upper
local yesno = require("Module:yesno")

local current_frame = mw.getCurrentFrame()
local current_title = mw.title.getCurrentTitle()
local inFundamental = mw.loadData("Module:category tree/old-data")
local namespace = current_title.namespace

local poscatboiler_subsystem = "poscatboiler"
local topic_subsystem = "topic"
local thesaurus_subsystem = "thesaurus"

local extra_args_error = "Extra arguments to {{((}}auto cat{{))}} are not allowed for this category."

-- Generates a sortkey for a numeral `n`, adding leading zeroes to avoid the "1, 10, 2, 3" sorting problem. `max_n` is the greatest expected value of `n`, and is used to determine how many leading zeroes are needed. If not supplied, it defaults to the number of languages.
function export.numeral_sortkey(n, max_n)
	max_n = max_n or require("Module:list of languages").count()
	return ("#%%0%dd"):format(ceil(log10(max_n + 1))):format(n)
end

function export.split_lang_label(title_text)
	local getByCanonicalName = require("Module:languages").getByCanonicalName
	-- Progressively remove a word from the potential canonical name until it
	-- matches an actual canonical name.
	local words = split(title_text, " ", true)
	for i = #words - 1, 1, -1 do
		local lang = getByCanonicalName(concat(words, " ", 1, i))
		if lang then
			return lang, concat(words, " ", i + 1)
		end
	end
	return nil, title_text
end

local function show_error(text)
	return require("Module:message box").maintenance(
		"red",
		"[[File:Ambox warning pn.svg|50px]]",
		"This category is not defined in Wiktionary's category tree.",
		text
	)
end

-- Show the text that goes at the very top right of the page.
local function show_topright(current)
	return current.getTopright and current:getTopright() or nil
end

local function link_box(content)
	return ("<div class=\"noprint plainlinks\" style=\"float: right; clear: both; margin: 0 0 .5em 1em; background: var(--wikt-palette-paleblue, #f9f9f9); border: 1px var(--border-color-base, #aaaaaa) solid; margin-top: -1px; padding: 5px; font-weight: bold;\">%s</div>"):format(content)
end

local function show_editlink(current)
	return link_box(("[%s Edit category data]"):format(tostring(full_url(current:getDataModule(), "action=edit"))))
end

function show_related_changes()
	local title = current_title.fullText
	return link_box(("[%s <span title=\"Recent edits and other changes to pages in %s\">Recent changes</span>]"):format(
		tostring(full_url("Special:RecentChangesLinked", {
			target = title,
			showlinkedto = 0,
		})),
		title
	))
end

local function show_pagelist(current)
	local namespace = "namespace="
	local info = current:getInfo()
	
	local lang_code = info.code
	if info.label == "citations" or info.label == "citations of undefined terms" then
		namespace = namespace .. "Citations"
	elseif lang_code then
		local lang = require("Module:languages").getByCode(lang_code, true)
		if lang then
			-- Proto-Norse (gmq-pro) is the probably language with a code ending in -pro
			-- that's intended to have mostly non-reconstructed entries.
			if (lang_code:find("%-pro$") and lang_code ~= "gmq-pro") or lang:hasType("reconstructed") then
				namespace = namespace .. "Reconstruction"
			elseif lang:hasType("appendix-constructed") then
				namespace = namespace .. "Appendix"
			end
		end
	elseif info.label:match("templates") then
		namespace = namespace .. "Template"
	elseif info.label:match("modules") then
		namespace = namespace .. "Module"
	elseif info.label:match("^Wiktionary") or info.label:match("^Pages") then
		namespace = ""
	end
	
	return ([=[
{| id="newest-and-oldest-pages" class="wikitable mw-collapsible" style="float: right; clear: both; margin: 0 0 .5em 1em;"
! Newest and oldest pages&nbsp;
|-
| id="recent-additions" style="font-size:0.9em;" | '''Newest pages ordered by last [[mw:Manual:Categorylinks table#cl_timestamp|category link update]]:'''
%s
|-
| id="oldest-pages" style="font-size:0.9em;" | '''Oldest pages ordered by last edit:'''
%s
|}]=]):format(
	current_frame:extensionTag(
		"DynamicPageList",
		([=[
category=%s
%s
count=10
mode=ordered
ordermethod=categoryadd
order=descending]=]
		):format(current_title.text, namespace)
	),
	current_frame:extensionTag(
		"DynamicPageList",
		([=[
category=%s
%s
count=10
mode=ordered
ordermethod=lastedit
order=ascending]=]
		):format(current_title.text, namespace)
	)
)
end

-- Show navigational "breadcrumbs" at the top of the page.
local function show_breadcrumbs(current)
	local steps = {}
	
	-- Start at the current label and move our way up the "chain" from child to parent, until we can't go further.
	while current do
		local category, display_name, nocap
		
		if type(current) == "string" then
			category = current
			display_name = current:gsub("^Category:", "")
		else
			if not current.getCategoryName then
				error("Internal error: Bad format in breadcrumb chain structure, probably a misformatted value for `parents`: " ..
					mw.dumpObject(current))
			end
			category = "Category:" .. current:getCategoryName()
			display_name, nocap = current:getBreadcrumbName()
		end

		if not nocap then
			display_name = mw.getContentLanguage():ucfirst(display_name)
		end
		insert(steps, 1, ("[[:%s|%s]]"):format(category, display_name))
		
		-- Move up the "chain" by one level.
		if type(current) == "string" then
			current = nil
		else
			current = current:getParents()
		end
		
		if current then
			current = current[1].name
		elseif inFundamental[category] then
			current = "Category:Fundamental"
		end	
	end
	
	local templateStyles = require("Module:TemplateStyles")("Module:category tree/styles.css")
	
	local ol = mw.html.create("ol")
	for i, step in ipairs(steps) do
		local li = mw.html.create("li")
		if i ~= 1 then
			local span = mw.html.create("span")
				:attr("aria-hidden", "true")
				:addClass("ts-categoryBreadcrumbs-separator")
				:wikitext(" » ")
			li:node(span)
		end
		li:wikitext(step)
		ol:node(li)
	end
	
	return templateStyles .. tostring(mw.html.create("div")
		:attr("role", "navigation")
		:attr("aria-label", "Breadcrumb")
		:addClass("ts-categoryBreadcrumbs")
		:node(ol))
end

local function show_also(current)
	local also = current._info.also
	if also and #also > 0 then
		return ('<div style="margin-top:-1em;margin-bottom:1.5em">%s</div>'):format(require("Module:also").main(also))
	end
	return nil
end

-- Show a short description text for the category.
local function show_description(current)
	return current.getDescription and current:getDescription() or nil
end

local function show_appendix(current)
	local appendix = current.getAppendix and current:getAppendix()
	return appendix and ("For more information, see [[%s]]."):format(appendix) or nil
end

local function sort_children(child1, child2)
	return compare_string(uupper(child1.sort), uupper(child2.sort))
end

-- Show a list of child categories.
local function show_children(current)
	local children = current.getChildren and current:getChildren() or nil
	if not children then
		return nil
	end
	
	sort(children, sort_children)
	
	local children_list = {}
	
	for _, child in ipairs(children) do
		local child_name, child_pagetitle = child.name
		if type(child_name) == "string" then
			child_pagetitle = child_name
		else
			child_pagetitle = "Category:" .. child_name:getCategoryName()
		end
		
		if new_title(child_pagetitle).exists then
			insert(children_list, ("* [[:%s]]: %s"):format(
				child_pagetitle,
				child.description or
					type(child_name) == "string" and child_name:gsub("^Category:", "") .. "." or
					child_name:getDescription("child")
			))
		end
	end
	
	return concat(children_list, "\n")
end

-- Show a table of contents with links to each letter in the language's script.
local function show_TOC(current)
	local titleText = current_title.text
	
	local inCategoryPages = pages_in_category(titleText, "pages")
	local inCategorySubcats = pages_in_category(titleText, "subcats")

	local TOC_type

	-- Compute type of table of contents required.
	if inCategoryPages > 2500 or inCategorySubcats > 2500 then
		TOC_type = "full"
	elseif inCategoryPages > 200 or inCategorySubcats > 200 then
		TOC_type = "normal"
	else
		-- No (usual) need for a TOC if all pages or subcategories can fit on one page;
		-- but allow this to be overridden by a custom TOC handler.
		TOC_type = "none"
	end

	if current.getTOC then
		local TOC_text = current:getTOC(TOC_type)
		if TOC_text ~= true then
			return TOC_text or nil
		end
	end

	if TOC_type ~= "none" then
		local templatename = current:getTOCTemplateName()

		local TOC_template
		if TOC_type == "full" then
			-- This category is very large, see if there is a "full" version of the TOC.
			local TOC_template_full = new_title(templatename .. "/full")
			
			if TOC_template_full.exists then
				TOC_template = TOC_template_full
			end
		end

		if not TOC_template then
			local TOC_template_normal = new_title(templatename)
			if TOC_template_normal.exists then
				TOC_template = TOC_template_normal
			end
		end

		if TOC_template then
			return current_frame:expandTemplate{title = TOC_template.text, args = {}}
		end
	end

	return nil
end

-- Show the "catfix" that adds language attributes and script classes to the page.
local function show_catfix(current)
	local lang, sc = current:getCatfixInfo()
	return lang and m_utilities.catfix(lang, sc) or nil
end

-- Show the parent categories that the current category should be placed in.
local function show_categories(current, categories)
	local parents = current.getParents and current:getParents() or nil
	if not parents then
		return nil
	end
	
	for _, parent in ipairs(parents) do
		local parent_name = parent.name
		local sortkey = type(parent.sort) == "table" and parent.sort:makeSortKey() or parent.sort
		if type(parent_name) == "string" then
			insert(categories, ("[[%s|%s]]"):format(parent_name, sortkey))
		else
			insert(categories, ("[[Category:%s|%s]]"):format(parent_name:getCategoryName(), sortkey))
		end
	end
	
	-- Also put the category in its corresponding "umbrella" or "by language" category.
	local umbrella = current:getUmbrella()
	
	if umbrella then
		-- FIXME: use a language-neutral sorting function like the Unicode Collation Algorithm.
		local sortkey = current._lang and current._lang:getCanonicalName() or current:getCategoryName()
		sortkey = require("Module:languages").getByCode("en", true):makeSortKey(sortkey)
		if type(umbrella) == "string" then
			insert(categories, ("[[%s|%s]]"):format(umbrella, sortkey))
		else
			insert(categories, ("[[Category:%s|%s]]"):format(umbrella:getCategoryName(), sortkey))
		end
	end
	
	-- Check for various unwanted parser functions, which should be integrated into the category tree data instead.
	-- Note: HTML comments shouldn't be removed from `content` until after this step, as they can affect the result.
	local content = current_title:getContent()
	if not content then
		-- This happens when using [[Special:ExpandTemplates]] to call {{auto cat}} on a nonexistent category page,
		-- which is needed by Benwing's create_wanted_categories.py script.
		return
	end
	local defaultsort, displaytitle, page_has_param
	for node in parse(content):iterate_nodes() do
		local node_class = class_else_type(node)
		if node_class == "template" then
			local name = node:get_name()
			if name == "DEFAULTSORT:" and not defaultsort then
				insert(categories, "[[Category:Pages with DEFAULTSORT conflicts]]")
				defaultsort = true
			elseif name == "DISPLAYTITLE:" and not displaytitle then
				insert(categories,"[[Category:Pages with DISPLAYTITLE conflicts]]")
				displaytitle = true
			end
		elseif node_class == "parameter" and not page_has_param then
			insert(categories,"[[Category:Pages with raw triple-brace template parameters]]")
			page_has_param = true
		end
	end
	
	-- Check for raw category markup, which should also be integrated into the category tree data.
	content = remove_comments(content, "BOTH")
	local head = content:find("[[", 1, true)
	while head do
		local close = content:find("]]", head + 2, true)
		if not close then
			break
		end
		-- Make sure there are no intervening "[[" between head and close.
		local open = content:find("[[", head + 2, true)
		while open and open < close do
			head = open
			open = content:find("[[", head + 2, true)
		end
		local cat = content:sub(head + 2, close - 1)
		local colon = cat:match("^[ _\128-\244]*[Cc][Aa][Tt][EeGgOoRrYy _\128-\244]*():")
		if colon then
			local pipe = cat:find("|", colon + 1, true)
			if pipe ~= #cat then
				local title = new_title(pipe and cat:sub(1, pipe - 1) or cat)
				if title and title.namespace == 14 then
					insert(categories,"[[Category:Categories with categories using raw markup]]")
					break
				end
			end
		end
		head = open
	end
end

local function generate_output(current)
	if current then
		for _, functionName in pairs{
			"getBreadcrumbName",
			"getDataModule",
			"canBeEmpty",
			"getDescription",
			"getParents",
			"getChildren",
			"getUmbrella",
			"getAppendix",
			"getTOCTemplateName",
		} do
			if not is_callable(current[functionName]) then
				require("Module:debug").track{"category tree/missing function", "category tree/missing function/" .. functionName}
			end
		end
	end

	local boxes, display, categories = {}, {}, {}
	
	-- Categories should never show files as a gallery.
	insert(categories, "__NOGALLERY__")
	
	if current_frame:getParent():getTitle() == "Template:auto cat" then
		insert(categories, "[[Category:Categories calling Template:auto cat]]")
	end
	
	-- Check if the category is empty
	local totalPages = pages_in_category(current_title.text, "all")
	local hugeCategory = totalPages > 1000000 -- 1 million
	
	-- Categorize huge categories, as they cause DynamicPageList to time out and make the category inaccessible.
	if hugeCategory then
		insert(categories, "[[Category:Huge categories]]")
	end
	
	-- Are the parameters valid?
	if not current then
		insert(categories, "[[Category:Categories that are not defined in the category tree]]")
		insert(categories, totalPages == 0 and "[[Category:Empty categories]]" or nil)
		insert(display, show_error(
			"Double-check the category name for typos. <br>" ..
			"[[Special:Search/Category: " .. current_title.text:gsub("^.+:", ""):gsub(" ", "~2 ") .. '~2|Search existing categories]] to check if this category should be created under a different name (for example, "Fruits" instead of "Fruit"). <br>' ..
			"To add a new category to Wiktionary's category tree, please consult " .. current_frame:expandTemplate{title = "section link", args = {
				"Help:Category#How_to_create_a_category",
			}} .. "."))
		
		-- Exit here, as all code beyond here relies on current not being nil
		return concat(categories, "") .. concat(display, "\n\n"), true
	end
	
	-- Does the category have the correct name?
	local currentName = current:getCategoryName()
	local correctName = current_title.text == currentName
	if not correctName then
		insert(categories, "[[Category:Categories with incorrect names]]")
		insert(display, show_error(("Based on the data in the category tree, this category should be called '''[[:Category:%s]]'''."):format(currentName)))
	end
	
	-- Add cleanup category for empty categories.
	local canBeEmpty = current:canBeEmpty()
	if canBeEmpty and correctName then
		insert(categories, " __EXPECTUNUSEDCATEGORY__")
	elseif totalPages == 0 then
		insert(categories, "[[Category:Empty categories]]")
	end
	
	if current:isHidden() then
		insert(categories, "__HIDDENCAT__")
	end

	-- Put all the float-right stuff into a <div> that does not clear, so that float-left stuff like the breadcrumbs and
	-- description can go opposite the float-right stuff without vertical space.
	insert(boxes, "<div style=\"float: right;\">")
	insert(boxes, show_topright(current))
	insert(boxes, show_editlink(current))
	insert(boxes, show_related_changes())
	
	-- Show pagelist, unless it's a huge category (since they can't use DynamicPageList - see above).
	if not hugeCategory then
		insert(boxes, show_pagelist(current))
	end
	
	insert(boxes, "</div>")
	
	-- Generate the displayed information
	insert(display, show_breadcrumbs(current))
	insert(display, show_also(current))
	insert(display, show_description(current))
	insert(display, show_appendix(current))
	insert(display, show_children(current))
	insert(display, show_TOC(current))
	insert(display, show_catfix(current))
	insert(display, '<br class="clear-both-in-vector-2022-only">')
	
	show_categories(current, categories)
	
	return concat(boxes, "\n") .. "\n" .. concat(display, "\n\n") .. concat(categories, "")
end

--[==[
List of handler functions that try to match the page name. A handler should return the name of a submodule to
[[Module:category tree]] and an info table which is passed as an argument to the submodule. If a handler does not
recognize the page name, it should return nil. Note that the order of handlers matters!
]==]
local handlers = {}

-- Thesaurus per-language category
insert(handlers, function(title)
	local code, label = title:match("^Thesaurus:(%l[%a-]*%a):(.+)")
	if code then
		return thesaurus_subsystem, {label = label, code = code}
	end
end)

-- Topic per-language category
insert(handlers, function(title)
	local code, label = title:match("^(%l[%a-]*%a):(.+)")
	if code then
		return topic_subsystem, {label = label, code = code}
	end
end)

-- Lect category e.g. for [[:Category:New Zealand English]] or [[:Category:Issime Walser]]
insert(handlers, function(title, args)
	local lect = args.lect or args.dialect
	if lect ~= "" and yesno(lect, true) then -- Same as boolean in [[Module:parameters]].
		return poscatboiler_subsystem, {label = title, args = args, raw = true}
	end
end)

-- poscatboiler per-language label, e.g. [[Category:English non-lemma forms]]
insert(handlers, function(title, args)
	local lang, label = export.split_lang_label(title)
	if not lang then
		return
	end
	local baseLabel, script = label:match("(.+) in (.-) script$")
	if script and baseLabel ~= "terms" then
		local scriptObj = require("Module:scripts").getByCanonicalName(script)
		if scriptObj then
			return poscatboiler_subsystem, {label = baseLabel, code = lang:getCode(), sc = scriptObj:getCode(), args = args}
		end
	end
	return poscatboiler_subsystem, {label = label, code = lang:getCode(), args = args}
end)

-- poscatboiler label umbrella category
insert(handlers, function(title, args)
	local label = title:match("(.+) by language$")
	if label then
		-- The poscatboiler code will appropriately lowercase if needed.
		return poscatboiler_subsystem, {label = label, args = args}
	end
end)

-- Thesaurus umbrella category
insert(handlers, function(title)
	local label = title:match("^Thesaurus:(.+)")
	if label then
		return thesaurus_subsystem, {label = label}
	end
end)

-- Topic umbrella category
insert(handlers, function(title)
	return topic_subsystem, {label = title}
end)

-- poscatboiler raw handlers
insert(handlers, function(title, args)
	return poscatboiler_subsystem, {label = title, args = args, raw = true}
end)

-- poscatboiler umbrella handlers without 'by language'
insert(handlers, function(title, args)
	return poscatboiler_subsystem, {label = title, args = args}
end)

function export.show(frame)
	local args, other_args = require("Module:parameters").process(frame:getParent().args, {
		["also"] = {type = "title", sublist = "comma without whitespace", namespace = 14}
	}, true)
	
	if args.also then
		for k, arg in next, args.also do
			args.also[k] = arg.prefixedText
		end
	end
	
	for k, arg in next, other_args do
		other_args[k] = trim(arg)
	end
	
	if namespace == 10 then -- Template
		return "(This template should be used on pages in the [[Help:Namespaces#Category|Category:]] namespace.)"
	elseif namespace ~= 14 then -- Category
		error("This template/module can only be used on pages in the [[mw:Help:Namespaces#Category|Category:]] namespace.")
	end

	local first_fail_args_handled, first_fail_cattext

	-- Go through each handler in turn. If a handler doesn't recognize the format of the category, it will return nil,
	-- and we will consider the next handler. Otherwise, it returns a template name and arguments to call it with, but
	-- even then, that template might return an error, and we need to consider the next handler. This happens, for
	-- example, with the category "CAT:Mato Grosso, Brazil", where "Mato" is the name of a language, so the poscatboiler
	-- per-language label handler fires and tries to find a label "Grosso, Brazil". This throws an error, and
	-- previously, this blocked fruther handler consideration, but now we check for the error and continue checking
	-- handlers; eventually, the topic umbrella handler will fire and correctly handle the category.
	for _, handler in ipairs(handlers) do
		-- Use a new title object and args table for each handler, to keep them isolated.
		local submodule, info = handler(current_title.text, deep_copy(other_args))
		if submodule then
			info.also = deep_copy(args.also)
			require("Module:debug").track("auto cat/" .. submodule)
			-- `failed` is true if no match was found.
			submodule = require("Module:category tree/" .. submodule)
			local cattext, failed = generate_output(submodule.main(info))
			if failed then
				if not first_fail_cattext then
					first_fail_cattext = cattext
					first_fail_args_handled = info.args and true or false
				end
			elseif not info.args and next(other_args) then
				error(extra_args_error)
			else
				return cattext
			end
		end
	end
	
	-- If there were no matches, throw an error if any arguments were given, or otherwise return the cattext
	-- from the first fail encountered. The final handlers call the boilers unconditionally, so there should
	-- always be something to return.
	if not first_fail_args_handled and next(other_args) then
		error(extra_args_error)
	end
	return first_fail_cattext
end

-- TODO: new test entrypoint.

return export
