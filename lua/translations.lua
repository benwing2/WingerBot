local export = {}

local anchors_module = "Module:anchors"
local debug_track_module = "Module:debug/track"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local string_utilities_module = "Module:string utilities"
local templatestyles_module = "Module:TemplateStyles"
local utilities_module = "Module:utilities"
local wikimedia_languages_module = "Module:wikimedia languages"

local concat = table.concat
local html_create = mw.html.create
local insert = table.insert
local load_data = mw.loadData
local new_title = mw.title.new
local require = require

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
local function decode_uri(...)
	decode_uri = require(string_utilities_module).decode_uri
	return decode_uri(...)
end

local function format_categories(...)
	format_categories = require(utilities_module).format_categories
	return format_categories(...)
end

local function full_link(...)
	full_link = require(links_module).full_link
	return full_link(...)
end

local function get_link_page(...)
	get_link_page = require(links_module).get_link_page
	return get_link_page(...)
end

local function get_wikimedia_lang(...)
	get_wikimedia_lang = require(wikimedia_languages_module).getByCode
	return get_wikimedia_lang(...)
end

local function language_link(...)
	language_link = require(links_module).language_link
	return language_link(...)
end

local function normalize_anchor(...)
	normalize_anchor = require(anchors_module).normalize_anchor
	return normalize_anchor(...)
end

local function plain_link(...)
	plain_link = require(links_module).plain_link
	return plain_link(...)
end

local function process_params(...)
	process_params = require(parameters_module).process
	return process_params(...)
end

local function remove_links(...)
	remove_links = require(links_module).remove_links
	return remove_links(...)
end

local function split_on_slashes(...)
	split_on_slashes = require(links_module).split_on_slashes
	return split_on_slashes(...)
end

local function templatestyles(...)
	templatestyles = require(templatestyles_module)
	return templatestyles(...)
end

local function track(...)
	track = require(debug_track_module)
	return track(...)
end

--[==[
Loaders for objects, which load data (or some other object) into some variable, which can then be accessed as "foo or get_foo()", where the function get_foo sets the object to "foo" and then returns it. This ensures they are only loaded when needed, and avoids the need to check for the existence of the object each time, since once "foo" has been set, "get_foo" will not be called again.]==]
	local en
	local function get_en()
		en, get_en = require(languages_module).getByCode("en"), nil
		return en
	end
	
	local headword_data
	local function get_headword_data()
		headword_data, get_headword_data = load_data("Module:headword/data"), nil
		return headword_data
	end
	
	local parameters_data
	local function get_parameters_data()
		parameters_data, get_parameters_data = load_data("Module:parameters/data"), nil
		return parameters_data
	end
	
	local translations_data
	local function get_translations_data()
		translations_data, get_translations_data = load_data("Module:translations/data"), nil
		return translations_data
	end

local function is_translation_subpage(pagename)
	if (headword_data or get_headword_data()).page.namespace ~= "" then
		return false
	elseif not pagename then
		pagename = (headword_data or get_headword_data()).encoded_pagename
	end
	return pagename:match("./translations$") and true or false
end

local function canonical_pagename()
	local pagename = (headword_data or get_headword_data()).encoded_pagename
	return is_translation_subpage(pagename) and pagename:sub(1, -14) or pagename
end

local function interwiki(terminfo, term, lang, langcode)
	-- No interwiki link if term is empty/missing
	if not term or #term < 1 then
		terminfo.interwiki = false
		return
	end
	
	-- Percent-decode the term.
	term = decode_uri(terminfo.term, "PATH")
	
	-- Don't show an interwiki link if it's an invalid title.
	if not new_title(term) then
		terminfo.interwiki = false
		return
	end
	
	local interwiki_langcode = (translations_data or get_translations_data()).interwiki_langs[langcode]
	local wmlangs = interwiki_langcode and {get_wikimedia_lang(interwiki_langcode)} or lang:getWikimediaLanguages()
	
	-- Don't show the interwiki link if the language is not recognised by Wikimedia.
	if #wmlangs == 0 then
		terminfo.interwiki = false
		return
	end
	
	local sc = terminfo.sc
	
	local target_page = get_link_page(term, lang, sc)
	local split = split_on_slashes(target_page)
	if not split[1] then
		terminfo.interwiki = false
		return
	end
	target_page = split[1]
	
	local wmlangcode = wmlangs[1]:getCode()
	local interwiki_link = language_link{
		lang = lang,
		sc = sc,
		term = wmlangcode .. ":" .. target_page,
		alt = "(" .. wmlangcode .. ")",
		tr = "-"
	}
	
	terminfo.interwiki = tostring(html_create("span")
		:addClass("tpos")
		:wikitext("&nbsp;" .. interwiki_link)
	)
end

function export.show_terminfo(terminfo, check)
	local lang = terminfo.lang
	local langcode, langname = lang:getCode(), lang:getCanonicalName()
	-- Translations must be for mainspace languages.
	if not lang:hasType("regular") then
		error("Translations must be for attested and approved main-namespace languages.")
	else
		local disallowed = (translations_data or get_translations_data()).disallowed
		local err_msg = disallowed[langcode]
		if err_msg then
			error("Translations not allowed in " .. langname .. " (" .. langcode .. "). " .. langname .. " translations should " .. err_msg)
		end
		local fullcode = lang:getFullCode()
		if fullcode ~= langcode then
			err_msg = disallowed[fullcode]
			if err_msg then
				langname = lang:getFullName()
				error("Translations not allowed in " .. langname .. " (" .. fullcode .. "). " .. langname .. " translations should " .. err_msg)
			end
		end
	end

	local term = terminfo.term
	
	-- Check if there is a term. Don't show the interwiki link if there is nothing to link to.
	if not term then
		-- Track entries that don't provide a term.
		-- FIXME: This should be a category.
		track("translations/no term")
		track("translations/no term/" .. langcode)
	end
	if terminfo.interwiki then
		interwiki(terminfo, term, lang, langcode)
	end

	langcode = lang:getFullCode()
	
	if (translations_data or get_translations_data()).need_super[langcode] then
		local tr = terminfo.tr
		if tr ~= nil then
			terminfo.tr = tr:gsub("%d[%d%*%-]*%f[^%d%*]", "<sup>%0</sup>")
		end
	end
	
	local link = full_link(terminfo, "translation")
	local categories = {"Terms with " .. lang:getFullName() .. " translations"}
	
	if check then
		link = tostring(html_create("span")
			:addClass("ttbc")
			:tag("sup")
				:addClass("ttbc")
				:wikitext("(please [[WT:Translations#Translations to be checked|verify]])")
				:done()
			:wikitext(" " .. link)
		)
		insert(categories, "Requests for review of " .. langname .. " translations")
	end
	
	return link .. format_categories(categories, en or get_en(), nil, canonical_pagename())
end

-- Implements {{t}}, {{t+}}, {{t-check}} and {{t+check}}.
function export.show(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["translation"])
	local check = frame.args.check
	return export.show_terminfo({
		lang = args[1],
		sc = args.sc,
		track_sc = true,
		term = args[2],
		alt = args.alt,
		id = args.id,
		genders = args[3],
		tr = args.tr,
		ts = args.ts,
		lit = args.lit,
		interwiki = frame.args.interwiki,
	}, check and check ~= "")
end

local function add_id(div, id)
	return id and div:attr("id", normalize_anchor("Translations-" .. id)) or div
end

-- Implements {{trans-top}} and part of {{trans-top-also}}.
local function top(args, title, id, navhead)
	local column_width = (args["column-width"] == "wide" or args["column-width"] == "narrow") and "-" .. args["column-width"] or ""
	
	local div = html_create("div")
		:addClass("NavFrame")
		:node(navhead)
		:tag("div")
			:addClass("NavContent")
			:tag("table")
				:addClass("translations")
				:attr("role", "presentation")
				:attr("data-gloss", title or "")
				:tag("tr")
					:tag("td")
						:addClass("translations-cell")
						:addClass("multicolumn-list" .. column_width)
						:attr("colspan", "3")
		:allDone()
	div = add_id(div, id)

	local categories = {}

	if not title then
		insert(categories, "Translation table header lacks gloss")
	end

	local pagename = canonical_pagename()
	if is_translation_subpage() then
		insert(categories, "Translation subpages")
	end

	return (tostring(div):gsub("</td></tr></table></div></div>$", "")) ..
		(#categories > 0 and format_categories(categories, en or get_en(), nil, pagename) or "") ..
		-- Category to trigger [[MediaWiki:Gadget-TranslationAdder.js]]; we want this even on
		-- user pages and such.
		format_categories("Entries with translation boxes", nil, nil, nil, true) ..
		templatestyles("Module:translations/styles.css")
end

-- Entry point for {{trans-top}}.
function export.top(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["trans-top"])
	local title = args[1]
	local id = args.id or title
	title = title and remove_links(title)
	return top(args, title, id, html_create("div")
		:addClass("NavHead")
		:css("text-align", "left")
		:wikitext(title or "Translations")
	)
end

-- Entry point for {{checktrans-top}}.
function export.check_top(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["checktrans-top"])
	
	local text = "\n:''The translations below need to be checked and inserted above into the appropriate translation tables. See instructions at " ..
		frame:expandTemplate{
			title = "section link",
			args = {"Wiktionary:Entry layout#Translations"}
		} ..
		".''\n"
	
	local header = html_create("div")
		:addClass("checktrans")
		:wikitext(text)
		
	local subtitle = args[1]
	local title = "Translations to be checked"
	if subtitle then
		title = title .. "&zwnj;: \"" .. subtitle .. "\""
	end
	-- No ID, since these should always accompany proper translation tables, and can't be trusted anyway (i.e. there's no use-case for links).
	return tostring(header) .. "\n" .. top(args, title, nil, html_create("div")
		:addClass("NavHead")
		:css("text-align", "left")
		:wikitext(title or "Translations")
	)
end

-- Implements {{trans-bottom}}.
function export.bottom(frame)
	-- Check nothing is being passed as a parameter.
	process_params(frame:getParent().args, (parameters_data or get_parameters_data())["trans-bottom"])
	return "</table></div></div>"
end

-- Implements {{trans-see}} and part of {{trans-top-also}}.
local function see(args, see_text)
	local navhead = html_create("div")
		:addClass("NavHead")
		:css("text-align", "left")
		:wikitext(args[1] .. " ")
		:tag("span")
			:css("font-weight", "normal")
			:wikitext("— ")
			:tag("i")
				:wikitext(see_text)
		:allDone()
	local terms, id = args[2], args.id
	
	if #terms == 0 then
		terms[1] = args[1]
	end
	
	for i = 1, #terms do
		local term_id = id[i] or id.default
		local data = {
			term = terms[i],
			id = term_id and "Translations-" .. term_id or "Translations",
		}
		terms[i] = plain_link(data)
	end
	
	return navhead:wikitext(concat(terms, ",&lrm; "))
end

-- Entry point for {{trans-see}}.
function export.see(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["trans-see"])
	local div = html_create("div")
		:addClass("pseudo")
		:addClass("NavFrame")
		:node(see(args, "see "))
	return tostring(add_id(div, args.id.default or args[1]))
end

-- Entry point for {{trans-top-also}}.
function export.top_also(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["trans-top-also"])
	local navhead = see(args, "see also ")
	local title = args[1]
	local id = args.id.default or title
	title = remove_links(title)
	return top(args, title, id, navhead)
end

-- Implements {{translation subpage}}.
function export.subpage(frame)
	process_params(frame:getParent().args, (parameters_data or get_parameters_data())["translation subpage"])
	if not is_translation_subpage() then
		error("This template should only be used on translation subpages, which have titles that end with '/translations'.")
	end
	-- "Translation subpages" category is handled by {{trans-top}}.
	return ("''This page contains translations for ''%s''. See the main entry for more information.''"):format(full_link{
		lang = en or get_en(),
		term = canonical_pagename(),
	})
end

-- Implements {{t-needed}}.
function export.needed(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["t-needed"])
	local lang, category = args[1], ""
	local span = html_create("span")
		:addClass("trreq")
		:attr("data-lang", lang:getCode())
		:tag("i")
			:wikitext("please add this translation if you can")
			:done()
		
	if not args.nocat then
		local type, sort = args[2], args.sort
		if type == "quote" then
			category = "Requests for translations of " .. lang:getCanonicalName() .. " quotations"
		elseif type == "usex" then
			category = "Requests for translations of " .. lang:getCanonicalName() .. " usage examples"
		else
			category = "Requests for translations into " .. lang:getCanonicalName()
			lang = en or get_en()
		end
		category = format_categories(category, lang, sort, not sort and canonical_pagename() or nil)
	end
		
	return tostring(span) .. category
end

-- Implements {{no equivalent translation}}.
function export.no_equivalent(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["no equivalent translation"])
	
	local text = "no equivalent term in " .. args[1]:getCanonicalName()
	if not args.noend then
		text = text .. ", but see"
	end
	
	return tostring(html_create("i"):wikitext(text))
end

-- Implements {{no attested translation}}.
function export.no_attested(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["no attested translation"])
	
	local langname = args[1]:getCanonicalName()
	local text = "no [[WT:ATTEST|attested]] term in " .. langname
	local category = ""
	
	if not args.noend then
		text = text .. ", but see"
		local sort = args.sort
		category = format_categories(langname .. " unattested translations", en or get_en(), sort, not sort and canonical_pagename() or nil)
	end
	
	return tostring(html_create("i"):wikitext(text)) .. category
end

-- Implements {{not used}}.
function export.not_used(frame)
	local args = process_params(frame:getParent().args, (parameters_data or get_parameters_data())["not used"])
	return tostring(html_create("i"):wikitext((args[2] or "not used") .. " in " .. args[1]:getCanonicalName()))
end

return export
