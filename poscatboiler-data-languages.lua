local new_title = mw.title.new
local ucfirst = require("Module:string utilities").ucfirst
local split = require("Module:string utilities").split

local raw_categories = {}
local raw_handlers = {}

local m_languages = require("Module:languages")
local m_sc_getByCode = require("Module:scripts").getByCode
local m_table = require("Module:table")
local parse_utilities_module = "Module:parse utilities"

local concat = table.concat
local insert = table.insert
local reverse_ipairs = m_table.reverseIpairs
local serial_comma_join = m_table.serialCommaJoin
local size = m_table.size
local sorted_pairs = m_table.sortedPairs
local to_json = require("Module:JSON").toJSON

local Hang = m_sc_getByCode("Hang")
local Hani = m_sc_getByCode("Hani")
local Hira = m_sc_getByCode("Hira")
local Hrkt = m_sc_getByCode("Hrkt")
local Kana = m_sc_getByCode("Kana")

local function track(page)
	-- [[Special:WhatLinksHere/Wiktionary:Tracking/poscatboiler/languages/PAGE]]
	return require("Module:debug/track")("poscatboiler/languages/" .. page)
end

-- This handles language categories of the form e.g. [[:Category:French language]] and
-- [[:Category:British Sign Language]]; categories like [[:Category:Languages of Indonesia]]; categories like
-- [[:Category:English-based creole or pidgin languages]]; and categories like
-- [[:Category:English-based constructed languages]].


-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["All languages"] = {
	topright = "{{commonscat|Languages}}\n[[File:Languages world map-transparent background.svg|thumb|right|250px|Rough world map of language families]]",
	description = "This category contains the categories for every language on Wiktionary.",
	additional = "Not all languages that Wiktionary recognises may have a category here yet. There are many that have " ..
	"not yet received any attention from editors, mainly because not all Wiktionary users know about every single " ..
	"language. See [[Wiktionary:List of languages]] for a full list.",
	parents = {
		"Fundamental",
	},
}

raw_categories["All extinct languages"] = {
	description = "This category contains the categories for every [[extinct language]] on Wiktionary.",
	additional = "Do not confuse this category with [[:Category:Extinct languages]], which is an umbrella category for the names of extinct languages in specific other languages (e.g. {{m+|de|Langobardisch}} for the ancient [[Lombardic]] language).",
	parents = {
		"All languages",
	},
}

raw_categories["Languages by country"] = {
	topright = "{{commonscat|Languages by continent}}",
	description = "Categories that group languages by country.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"All languages",
	},
}

raw_categories["Language isolates"] = {
	topright = "{{wikipedia|Language isolate}}\n{{commonscat|Language isolates}}",
	description = "Languages with no known relatives.",
	parents = {
		{name = "Languages by family", sort = "*Isolates"},
		{name = "All language families", sort = "Isolates"},
	},
}


-----------------------------------------------------------------------------
--                                                                         --
--                                RAW HANDLERS                             --
--                                                                         --
-----------------------------------------------------------------------------


-- Given a category (without the "Category:" prefix), look up the page defining the category, find the call to
-- {{auto cat}} (if any), and return a table of its arguments. If the category page doesn't exist or doesn't have
-- an {{auto cat}} invocation, return nil.
--
-- FIXME: Duplicated in [[Module:category tree/poscatboiler/data/lects]].
local function scrape_category_for_auto_cat_args(cat)
	local cat_page = mw.title.new("Category:" .. cat)
	if cat_page then
		local contents = cat_page:getContent()
		if contents then
			local frame = mw.getCurrentFrame()
			for template in require("Module:template parser").find_templates(contents) do
				-- The template parser automatically handles redirects and canonicalizes them, so uses of {{autocat}}
				-- will also be found.
				if template:get_name() == "auto cat" then
					return template:get_arguments()
				end
			end
		end
	end
	return nil
end


local function link_location(location)
	local location_no_the = location:match("^the (.*)$")
	local bare_location = location_no_the or location
	local location_link
	local bare_location_parts = split(bare_location, ", ")
	for i, part in ipairs(bare_location_parts) do
		bare_location_parts[i] = ("[[%s]]"):format(part)
	end
	location_link = concat(bare_location_parts, ", ")
	if location_no_the then
		location_link = "the " .. location_link
	end
	return location_link
end


local function linkbox(lang, setwiki, setwikt, setsister, entryname)
	local wiktionarylinks = {}
	
	local canonicalName = lang:getCanonicalName()
	local wikimediaLanguages = lang:getWikimediaLanguages()
	local wikipediaArticle = setwiki or lang:getWikipediaArticle()
	setsister = setsister and ucfirst(setsister) or nil
	
	if setwikt then
		track("setwikt")
		if setwikt == "-" then
			track("setwikt/hyphen")
		end
	end
	
	if setwikt ~= "-" and wikimediaLanguages and wikimediaLanguages[1] then
		for _, wikimedialang in ipairs(wikimediaLanguages) do
			local check = new_title(wikimedialang:getCode() .. ":")
			if check and check.isExternal then
				insert(wiktionarylinks,
					(wikimedialang:getCanonicalName() ~= canonicalName and "(''" .. wikimedialang:getCanonicalName() .. "'') " or "") ..
					"'''[[:" .. wikimedialang:getCode() .. ":|" .. wikimedialang:getCode() .. ".wiktionary.org]]'''")
			end
		end
		
		wiktionarylinks = concat(wiktionarylinks, "<br/>")
	end
	
	local wikt_plural = wikimediaLanguages[2] and "s" or ""
	
	if #wiktionarylinks == 0 then
		wiktionarylinks = "''None.''"
	end
	
	if setsister then
		track("setsister")
		if setsister == "-" then
			track("setsister/hyphen")
		else
			setsister = "Category:" .. setsister
		end
	else
		setsister = lang:getCommonsCategory() or "-"
	end
	
	return concat{
[=[<div class="wikitable" style="float: right; clear: right; margin: 0 0 0.5em 1em; width: 300px; padding: 5px;">
<div style="text-align: center; margin-bottom: 10px; margin-top: 5px">''']=], canonicalName, [=[ language links'''</div>

{| style="font-size: 90%"
|-
| style="vertical-align: top; height: 35px; border-bottom: 1px solid lightgray;" | [[File:Wikipedia-logo.png|35px|none|Wikipedia]]
| style="border-bottom: 1px solid lightgray;" | '''English Wikipedia''' has an article on:
<div style="padding: 5px 10px">]=], (setwiki == "-" and "''None.''" or "'''[[w:" .. wikipediaArticle .. "|" .. wikipediaArticle .. "]]'''"), [=[</div>

|-
| style="vertical-align: top; height: 35px; border-bottom: 1px solid lightgray;" | [[File:Wikimedia-logo.svg|35px|none|Wikimedia Commons]]
| style="border-bottom: 1px solid lightgray;" | '''Wikimedia Commons''' has links to ]=], canonicalName, [=[-related content in sister projects:
<div style="padding: 5px 10px">]=], (setsister == "-" and "''None.''" or "'''[[commons:" .. setsister .. "|" .. setsister .. "]]'''"), [=[</div>

|-
| style="vertical-align: top; height: 35px; width: 40px; border-bottom: 1px solid lightgray;" | [[File:Wiktionary-logo-v2.svg|35px|none|Wiktionary]]
|style="border-bottom: 1px solid lightgray;" | '''Wiktionary edition''']=], wikt_plural, [=[ written in ]=], canonicalName, [=[:
<div style="padding: 5px 10px">]=], wiktionarylinks, [=[</div>

|-
| style="vertical-align: top; height: 35px; border-bottom: 1px solid lightgray;" | [[File:Open book nae 02.svg|35px|none|Entry]]
| style="border-bottom: 1px solid lightgray;" | '''Wiktionary entry''' for the language's English name:
<div style="padding: 5px 10px">''']=], require("Module:links").full_link({lang = m_languages.getByCode("en"), term = entryname or canonicalName}), [=['''</div>

|-
| style="vertical-align: top; height: 35px;" | [[File:Crystal kfind.png|35px|none|Considerations]]
|| '''Wiktionary resources''' for editors contributing to ]=], canonicalName, [=[ entries:
<div style="padding: 5px 0">
* '''[[Wiktionary:About ]=], canonicalName, [=[]]'''
* '''[[:Category:]=], canonicalName, [=[ reference templates|Reference templates]] ({{PAGESINCAT:]=], canonicalName, [=[ reference templates}})'''
* '''[[Appendix:]=], canonicalName, [=[ bibliography|Bibliography]]'''
|}
</div>]=]
}
end

local function edit_link(title, text)
	return '<span class="plainlinks">['
		.. tostring(mw.uri.fullUrl(title, { action = "edit" }))
		.. ' ' .. text .. ']</span>'
end

-- Should perhaps use wiki syntax.
local function infobox(lang)
	local ret = {}
	
	insert(ret, '<table class="wikitable language-category-info"')
	
	local raw_data = lang:getData("extra")
	if raw_data then
		local replacements = {
			[1] = "canonical-name",
			[2] = "wikidata-item",
			[3] = "family",
			[4] = "scripts",
		}
		local function replacer(letter1, letter2)
			return letter1:lower() .. "-" .. letter2:lower()
		end
		-- For each key in the language data modules, returns a descriptive
		-- kebab-case version (containing ASCII lowercase words separated
		-- by hyphens).
		local function kebab_case(key)
			key = replacements[key] or key
			key = key:gsub("(%l)(%u)", replacer):gsub("(%l)_(%l)", replacer)
			return key
		end
		local compress = {compress = true}
		local function html_attribute_encode(str)
			str = to_json(str, compress)
				:gsub('"', "&quot;")
				-- & in attributes is automatically escaped.
				-- :gsub("&", "&amp;")
				:gsub("<", "&lt;")
				:gsub(">", "&gt;")
			return str
		end
		insert(ret, ' data-code="' .. lang:getCode() .. '"')
		for k, v in sorted_pairs(raw_data) do
			insert(ret, " data-" .. kebab_case(k)
			.. '="'
			.. html_attribute_encode(v)
			.. '"')
		end
	end
	insert(ret, '>\n')
	insert(ret, '<tr class="language-category-data">\n<th colspan="2">'
		.. edit_link(lang:getDataModuleName(), "Edit language data")
		.. "</th>\n</tr>\n")
	insert(ret, "<tr>\n<th>Canonical name</th><td>" .. lang:getCanonicalName() .. "</td>\n</tr>\n")

	local otherNames = lang:getOtherNames()
	if otherNames then
		local names = {}
		
		for _, name in ipairs(otherNames) do
			insert(names, "<li>" .. name .. "</li>")
		end
		
		if #names > 0 then
			insert(ret, "<tr>\n<th>Other names</th><td><ul>" .. concat(names, "\n") .. "</ul></td>\n</tr>\n")
		end
	end
	
	local aliases = lang:getAliases()
	if aliases then
		local names = {}
		
		for _, name in ipairs(aliases) do
			insert(names, "<li>" .. name .. "</li>")
		end
		
		if #names > 0 then
			insert(ret, "<tr>\n<th>Aliases</th><td><ul>" .. concat(names, "\n") .. "</ul></td>\n</tr>\n")
		end
	end

	local varieties = lang:getVarieties()
	if varieties then
		local names = {}
		
		for _, name in ipairs(varieties) do
			if type(name) == "string" then
				insert(names, "<li>" .. name .. "</li>")
			else
				assert(type(name) == "table")
				local first_var
				local subvars = {}
				for i, var in ipairs(name) do
					if i == 1 then
						first_var = var
					else
						insert(subvars, "<li>" .. var .. "</li>")
					end
				end
				if #subvars > 0 then
					insert(names, "<li><dl><dt>" .. first_var .. "</dt>\n<dd><ul>" .. concat(subvars, "\n") .. "</ul></dd></dl></li>")
				elseif first_var then
					insert(names, "<li>" .. first_var .. "</li>")
				end
			end
		end
		
		if #names > 0 then
			insert(ret, "<tr>\n<th>Varieties</th><td><ul>" .. concat(names, "\n") .. "</ul></td>\n</tr>\n")
		end
	end

	insert(ret, "<tr>\n<th>[[Wiktionary:Languages|Language code]]</th><td><code>" .. lang:getCode() .. "</code></td>\n</tr>\n")
	insert(ret, "<tr>\n<th>[[Wiktionary:Families|Language family]]</th>\n")
	
	local fam = lang:getFamily()
	local famCode = fam and fam:getCode()
	
	if not fam then
		insert(ret, "<td>unclassified</td>")
	elseif famCode == "qfa-iso" then
		insert(ret, "<td>[[:Category:Language isolates|language isolate]]</td>")
	elseif famCode == "qfa-mix" then
		insert(ret, "<td>[[:Category:Mixed languages|mixed language]]</td>")
	elseif famCode == "sgn" then
		insert(ret, "<td>[[:Category:Sign languages|sign language]]</td>")
	elseif famCode == "crp" then
		insert(ret, "<td>[[:Category:Creole or pidgin languages|creole or pidgin]]</td>")
	elseif famCode == "art" then
		insert(ret, "<td>[[:Category:Constructed languages|constructed language]]</td>")
	else
		insert(ret, "<td>" .. fam:makeCategoryLink() .. "</td>")
	end
	
	insert(ret, "\n</tr>\n<tr>\n<th>Ancestors</th>\n<td>")
	
	local ancestors = lang:getAncestors()
	if ancestors[2] then
		local ancestorList = {}
		for i, anc in ipairs(ancestors) do
			ancestorList[i] = "<li>" .. anc:makeCategoryLink() .. "</li>"
		end
		insert(ret, "<ul>\n" .. concat(ancestorList, "\n") .. "</ul>")
	else
		local ancestorChain = lang:getAncestorChainOld()
		if ancestorChain[1] then
			local chain = {}
			for _, anc in reverse_ipairs(ancestorChain) do
				insert(chain, "<li>" .. anc:makeCategoryLink() .. "</li>")
			end
			insert(ret, "<ul>\n" .. concat(chain, "\n<ul>\n") .. ("</ul>"):rep(#chain))
		else
			insert(ret, "unknown")
		end
	end
	
	insert(ret, "</td>\n</tr>\n")
	
	local scripts = lang:getScripts()
	
	if scripts[1] then
		local script_text = {}
		
		local function makeScriptLine(sc)
			local code = sc:getCode()
			local url = tostring(mw.uri.fullUrl('Special:Search', {
				search = 'contentmodel:css insource:"' .. code
					.. '" insource:/\\.' .. code .. '/',
				ns8 = '1'
			}))
			return sc:makeCategoryLink()
				.. ' (<span class="plainlinks" title="Search for stylesheets referencing this script">[' .. url .. ' <code>' .. code .. '</code>]</span>)'
		end
		
		local function add_Hrkt(text)
			insert(text, "<li>" .. makeScriptLine(Hrkt))
			insert(text, "<ul>")
			insert(text, "<li>" .. makeScriptLine(Hira) .. "</li>")
			insert(text, "<li>" .. makeScriptLine(Kana) .. "</li>")
			insert(text, "</ul>")
			insert(text, "</li>")
		end
		
		for _, sc in ipairs(scripts) do
			local text = {}
			local code = sc:getCode()
			
			if code == "Hrkt" then
				add_Hrkt(text)
			else
				insert(text, "<li>" .. makeScriptLine(sc))
				if code == "Jpan" then
					insert(text, "<ul>")
					insert(text, "<li>" .. makeScriptLine(Hani) .. "</li>")
					add_Hrkt(text)
					insert(text, "</ul>")
				elseif code == "Kore" then
					insert(text, "<ul>")
					insert(text, "<li>" .. makeScriptLine(Hang) .. "</li>")
					insert(text, "<li>" .. makeScriptLine(Hani) .. "</li>")
					insert(text, "</ul>")
				end
				insert(text, "</li>")
			end
			
			insert(script_text, concat(text, "\n"))
		end
		
		insert(ret, "<tr>\n<th>[[Wiktionary:Scripts|Scripts]]</th>\n<td><ul>\n" .. concat(script_text, "\n") .. "</ul></td>\n</tr>\n")
	else
		insert(ret, "<tr>\n<th>[[Wiktionary:Scripts|Scripts]]</th>\n<td>not specified</td>\n</tr>\n")
	end
	
	local function add_module_info(raw_data, heading)
		if raw_data then
			local scripts = lang:getScriptCodes()
			local module_info, add = {}, false
			if type(raw_data) == "string" then
				insert(module_info,
					("[[Module:%s]]"):format(raw_data))
				add = true
			else
				local raw_data_type = type(raw_data)
				if raw_data_type == "table" and size(scripts) == 1 and type(raw_data[scripts[1]]) == "string" then
					insert(module_info,
						("[[Module:%s]]"):format(raw_data[scripts[1]]))
					add = true
				elseif raw_data_type == "table" then
					insert(module_info, "<ul>")
					for script, data in sorted_pairs(raw_data) do
						if type(data) == "string" and m_sc_getByCode(script) then
							insert(module_info, ("<li><code>%s</code>: [[Module:%s]]</li>"):format(script, data))
						end
					end
					insert(module_info, "</ul>")
					add = size(module_info) > 2
				end
			end
			
			if add then
				insert(ret, [=[
<tr>
<th>]=] .. heading .. [=[</th>
<td>]=] .. concat(module_info) .. [=[</td>
</tr>
]=])
			end
		end
	end
	
	add_module_info(raw_data.generate_forms, "Form-generating<br>module")
	add_module_info(raw_data.translit, "[[Wiktionary:Transliteration and romanization|Transliteration<br>module]]")
	add_module_info(raw_data.display_text, "Display text<br>module")
	add_module_info(raw_data.entry_name, "Entry name<br>module")
	add_module_info(raw_data.sort_key, "[[sortkey|Sortkey]]<br>module")
	
	local wikidataItem = lang:getWikidataItem()
	if lang:getWikidataItem() and mw.wikibase then
		local URL = mw.wikibase.getEntityUrl(wikidataItem)
		local link
		if URL then
			link = '[' .. URL .. ' ' .. wikidataItem .. ']'
		else
			link = '<span class="error">Invalid Wikidata item: <code>' .. wikidataItem .. '</code></span>'
		end
		insert(ret, "<tr><th>Wikidata</th><td>" .. link .. "</td></tr>")
	end
	
	insert(ret, "</table>")
	
	return concat(ret)
end

local function NavFrame(content, title)
	return '<div class="NavFrame"><div class="NavHead">'
		.. (title or '{{{title}}}') .. '</div>'
		.. '<div class="NavContent" style="text-align: left;">'
		.. content
		.. '</div></div>'
end


local function get_description_topright_additional(lang, locations, extinct, setwiki, setwikt, setsister, entryname)
	local nameWithLanguage = lang:getCategoryName("nocap")
	if lang:getCode() == "und" then
		local description =
			"This is the main category of the '''" .. nameWithLanguage .. "''', represented in Wiktionary by the [[Wiktionary:Languages|code]] '''" .. lang:getCode() .. "'''. " ..
			"This language contains terms in historical writing, whose meaning has not yet been determined by scholars."
		return description, nil, nil
	end
	
	local canonicalName = lang:getCanonicalName()
	
	local topright = linkbox(lang, setwiki, setwikt, setsister, entryname)

	local the_prefix
	if canonicalName:find(" Language$") then
		the_prefix = ""
	else
		the_prefix = "the "
	end
	local description = "This is the main category of " .. the_prefix .. "'''" .. nameWithLanguage .. "'''."

	local location_links = {}
	local prep
	local saw_embedded_comma = false
	for _, location in ipairs(locations) do
		local this_prep
		if location == "the world" then
			this_prep = "across"
			insert(location_links, location)
		elseif location ~= "UNKNOWN" then
			this_prep = "in"
			if location:find(",") then
				saw_embedded_comma = true
			end
			insert(location_links, link_location(location))
		end
		if this_prep then
			if prep and this_prep ~= prep then
				error("Can't handle location 'the world' along with another location (clashing prepositions)")
			end
			prep = this_prep
		end
	end
	local location_desc
	if #location_links > 0 then
		local location_link_text
		if saw_embedded_comma and #location_links >= 3 then
			location_link_text = mw.text.listToText(location_links, "; ", "; and ")
		else
			location_link_text = serial_comma_join(location_links)
		end
		location_desc = ("It is %s %s %s.\n\n"):format(
			extinct and "an [[extinct language]] that was formerly spoken" or "spoken", prep, location_link_text)
	elseif extinct then
		location_desc = "It is an [[extinct language]].\n\n"
	else
		location_desc = ""
	end

	local add = location_desc .. "Information about " .. canonicalName .. ":\n\n" .. infobox(lang)
	
	if lang:hasType("reconstructed") then
		add = add .. "\n\n" ..
			ucfirst(canonicalName) .. " is a reconstructed language. Its words and roots are not directly attested in any written works, but have been reconstructed through the ''comparative method'', " ..
			"which finds regular similarities between languages that cannot be explained by coincidence or word-borrowing, and extrapolates ancient forms from these similarities.\n\n" ..
			"According to our [[Wiktionary:Criteria for inclusion|criteria for inclusion]], terms in " .. canonicalName ..
			" should '''not''' be present in entries in the main namespace, but may be added to the Reconstruction: namespace."
	elseif lang:hasType("appendix-constructed") then
		add = add .. "\n\n" ..
			ucfirst(canonicalName) .. " is a constructed language that is only in sporadic use. " ..
			"According to our [[Wiktionary:Criteria for inclusion|criteria for inclusion]], terms in " .. canonicalName ..
			" should '''not''' be present in entries in the main namespace, but may be added to the Appendix: namespace. " ..
			"All terms in this language may be available at [[Appendix:" .. ucfirst(canonicalName) .. "]]."
	end
	
	local about = new_title("Wiktionary:About " .. canonicalName)
	
	if about.exists then
		add = add .. "\n\n" ..
			"Please see '''[[Wiktionary:About " .. canonicalName .. "]]''' for information and special considerations for creating " .. nameWithLanguage .. " entries."
	end
	
	local ok, tree_of_descendants = pcall(
		require("Module:family tree").print_children,
		lang:getCode(), {
			protolanguage_under_family = true,
			must_have_descendants = true
		})
	
	if ok then
		if tree_of_descendants then
			add = add .. NavFrame(
				tree_of_descendants,
				"Family tree")
		else
			add = add .. "\n\n" .. ucfirst(lang:getCanonicalName())
				.. " has no descendants or varieties listed in Wiktionary's language data modules."
		end
	else
		mw.log("error while generating tree: " .. tostring(tree_of_descendants))
	end

	return description, topright, add
end


local function get_parents(lang, locations, extinct)
	local canonicalName = lang:getCanonicalName()
	
	local sortkey = {sort_base = canonicalName, lang = "en"}
	local ret = {{name = "All languages", sort = sortkey}}
	
	local fam = lang:getFamily()
	local famCode = fam and fam:getCode()
	
	-- FIXME: Some of the following categories should be added to this module.
	if not fam then
		insert(ret, {name = "Category:Unclassified languages", sort = sortkey})
	elseif famCode == "qfa-iso" then
		insert(ret, {name = "Category:Language isolates", sort = sortkey})
	elseif famCode == "qfa-mix" then
		insert(ret, {name = "Category:Mixed languages", sort = sortkey})
	elseif famCode == "sgn" then
		insert(ret, {name = "Category:All sign languages", sort = sortkey})
	elseif famCode == "crp" then
		insert(ret, {name = "Category:Creole or pidgin languages", sort = sortkey})
		for _, anc in ipairs(lang:getAncestors()) do
			-- Avoid Haitian Creole being categorised in [[:Category:Haitian Creole-based creole or pidgin languages]], as one of its ancestors is an etymology-only variety of it.
			-- Use that ancestor's ancestors instead.
			if anc:getFullCode() == lang:getCode() then
				for _, anc_extra in ipairs(anc:getAncestors()) do
					insert(ret, {name = "Category:" .. ucfirst(anc_extra:getFullName()) .. "-based creole or pidgin languages", sort = sortkey})
				end
			else
				insert(ret, {name = "Category:" .. ucfirst(anc:getFullName()) .. "-based creole or pidgin languages", sort = sortkey})
			end
		end
	elseif famCode == "art" then
		if lang:hasType("appendix-constructed") then
			insert(ret, {name = "Category:Appendix-only constructed languages", sort = sortkey})
		else
			insert(ret, {name = "Category:Constructed languages", sort = sortkey})
		end
		for _, anc in ipairs(lang:getAncestors()) do
			if anc:getFullCode() == lang:getCode() then
				for _, anc_extra in ipairs(anc:getAncestors()) do
					insert(ret, {name = "Category:" .. ucfirst(anc_extra:getFullName()) .. "-based constructed languages", sort = sortkey})
				end
			else
				insert(ret, {name = "Category:" .. ucfirst(anc:getFullName()) .. "-based constructed languages", sort = sortkey})
			end
		end
	else
		insert(ret, {name = "Category:" .. fam:getCategoryName(), sort = sortkey})
		if lang:hasType("reconstructed") then
			insert(ret, {
				name = "Category:Reconstructed languages",
				sort = {sort_base = canonicalName:gsub("^Proto%-", ""), lang = "en"}
			})
		end
	end
	
	local function add_sc_cat(sc)
		insert(ret, {name = "Category:" .. sc:getCategoryName() .. " languages", sort = sortkey})
	end
	
	local function add_Hrkt()
		add_sc_cat(Hrkt)
		add_sc_cat(Hira)
		add_sc_cat(Kana)
	end
	
	for _, sc in ipairs(lang:getScripts()) do
		if sc:getCode() == "Hrkt" then
			add_Hrkt()
		else
			add_sc_cat(sc)
			if sc:getCode() == "Jpan" then
				add_sc_cat(Hani)
				add_Hrkt()
			elseif sc:getCode() == "Kore" then
				add_sc_cat(Hang)
				add_sc_cat(Hani)
			end
		end
	end
	
	if lang:hasTranslit() then
		insert(ret, {name = "Category:Languages with automatic transliteration", sort = sortkey})
	end

	local function insert_location_language_cat(location)
		local cat = "Languages of " .. location
		insert(ret, {name = "Category:" .. cat, sort = sortkey})
		local auto_cat_args = scrape_category_for_auto_cat_args(cat)
		local location_parent = auto_cat_args and auto_cat_args.parent
		if location_parent then
			local split_parents = require(parse_utilities_module).split_on_comma(location_parent)
			for _, parent in ipairs(split_parents) do
				parent = parent:match("^(.-):.*$") or parent
				insert_location_language_cat(parent)
			end
		end
	end

	local saw_location = false
	for _, location in ipairs(locations) do
		if location ~= "UNKNOWN" then
			saw_location = true
			insert_location_language_cat(location)
		end
	end

	if extinct then
		insert(ret, {name = "Category:All extinct languages", sort = sortkey})
	end

	if not saw_location then
		insert(ret, {name = "Category:Languages not sorted into a location category", sort = sortkey})
	end

	return ret
end


local function get_children()
	local ret = {}

	-- FIXME: We should work on the children mechanism so it isn't necessary to manually specify these.
	for _, label in ipairs({"appendices", "entry maintenance", "lemmas", "names", "phrases", "rhymes", "symbols", "templates", "terms by etymology", "terms by usage"}) do
		insert(ret, {name = label, is_label = true})
	end

	insert(ret, {name = "terms derived from {{{langname}}}", is_label = true, lang = false})
	insert(ret, {module = "topic cat", args = {code = "{{{langcode}}}", label = "all topics"}, sort = "all topics"})
	insert(ret, {name = "Varieties of {{{langname}}}"})
	insert(ret, {name = "Requests concerning {{{langname}}}"})
	insert(ret, {name = "Category:Rhymes:{{{langname}}}", description = "Lists of {{{langname}}} words by their rhymes."})
	insert(ret, {name = "Category:User {{{langcode}}}", description = "Wiktionary users categorized by fluency levels in {{{langdisp}}}."})
	return ret
end


-- Handle language categories of the form e.g. [[:Category:French language]] and
-- [[:Category:British Sign Language]].
insert(raw_handlers, function(data)
	local category = data.category
	if not (category:match("[Ll]anguage$") or category:match("[Ll]ect$")) then
		return nil
	end
	local lang = m_languages.getByCanonicalName(category)
	if not lang then
		local langname = category:match("^(.*) language$")
		if langname then
			lang = m_languages.getByCanonicalName(langname)
		end
		if not lang then
			return nil
		end
	end
	local args = require("Module:parameters").process(data.args, {
		[1] = {list = true},
		["setwiki"] = true,
		["setwikt"] = true,
		["setsister"] = true,
		["entryname"] = true,
		["extinct"] = {type = "boolean"},
	})
	-- If called from inside, don't require any arguments, as they can't be known
	-- in general and aren't needed just to generate the first parent (used for
	-- breadcrumbs).
	if #args[1] == 0 and not data.called_from_inside then
		-- At least one location must be specified unless the language is constructed (e.g. Esperanto) or reconstructed (e.g. Proto-Indo-European).
		local fam = lang:getFamily()
		if not (lang:hasType("reconstructed") or (fam and fam:getCode() == "art")) then
			error("At least one location (param 1=) must be specified for language '" .. lang:getCanonicalName() .. "' (code '" .. lang:getCode() .. "'). " ..
				"Use the value UNKNOWN if the language's location is truly unknown.")
		end
	end
	local description, topright, additional = "", "", ""
	-- If called from inside the category tree system, it's called when generating
	-- parents or children, and we don't need to generate the description or additional
	-- text (which is very expensive in terms of memory because it calls [[Module:family tree]],
	-- which calls [[Module:languages/data/all]]).
	if not data.called_from_inside then
		description, topright, additional = get_description_topright_additional(
			lang, args[1], args.extinct, args.setwiki, args.setwikt, args.setsister, args.entryname
		)
	end
	return {
		canonical_name = lang:getCategoryName(),
		description = description,
		lang = lang:getCode(),
		topright = topright,
		additional = additional,
		breadcrumb = lang:getCanonicalName(),
		parents = get_parents(lang, args[1], args.extinct),
		extra_children = get_children(lang),
		umbrella = false,
		can_be_empty = true,
	}, true
end)


-- Handle categories such as [[:Category:Languages of Indonesia]].
insert(raw_handlers, function(data)
	local location = data.category:match("^Languages of (.*)$")
	if location then
		local args = require("Module:parameters").process(data.args, {
			["flagfile"] = true,
			["commonscat"] = true,
			["wp"] = true,
			["basename"] = true,
			["parent"] = true,
			["locationcat"] = true,
			["locationlink"] = true,
		})
		local topright
		local basename = args.basename or location:gsub(", .*", "")
		if args.flagfile ~= "-" then
			local flagfile_arg = args.flagfile or ("Flag of %s.svg"):format(basename)
			local files = require(parse_utilities_module).split_on_comma(flagfile_arg)
			local topright_parts = {}
			for _, file in ipairs(files) do
				local flagfile = "File:" .. file
				local flagfile_page = new_title(flagfile)
				if flagfile_page and flagfile_page.file.exists then
					insert(topright_parts, ("[[%s|right|100px|border]]"):format(flagfile))
				elseif args.flagfile then
					error(("Explicit flagfile '%s' doesn't exist"):format(flagfile))
				end
			end
			topright = concat(topright_parts)
		end

		if args.wp then
			local wp = require("Module:yesno")(args.wp, "+")
			if wp == "+" or wp == true then
				wp = data.category
			end
			if wp then
				local wp_topright = ("{{wikipedia|%s}}"):format(wp)
				if topright then
					topright = topright .. wp_topright
				else
					topright = wp_topright
				end
			end
		end

		if args.commonscat then
			local commonscat = require("Module:yesno")(args.commonscat, "+")
			if commonscat == "+" or commonscat == true then
				commonscat = data.category
			end
			if commonscat then
				local commons_topright = ("{{commonscat|%s}}"):format(commonscat)
				if topright then
					topright = topright .. commons_topright
				else
					topright = commons_topright
				end
			end
		end

		local bare_location = location:match("^the (.*)$") or location
		local location_link = args.locationlink or link_location(location)
		local bare_basename = basename:match("^the (.*)$") or basename

		local parents = {}
		if args.parent then
			local explicit_parents = require(parse_utilities_module).split_on_comma(args.parent)
			for i, parent in ipairs(explicit_parents) do
				local actual_parent, sort_key = parent:match("^(.-):(.*)$")
				if actual_parent then
					parent = actual_parent
					sort_key = sort_key:gsub("%+", bare_location)
				else
					sort_key = " " .. bare_location
				end
				insert(parents, {name = "Languages of " .. parent, sort = sort_key})
			end
		else
			insert(parents, {name = "Languages by country", sort = {sort_base = bare_location, lang = "en"}})
		end
		if args.locationcat then
			local explicit_location_cats = require(parse_utilities_module).split_on_comma(args.locationcat)
			for i, locationcat in ipairs(explicit_location_cats) do
				insert(parents, {name = "Category:" .. locationcat, sort = " Languages"})
			end
		else
			local location_cat = ("Category:%s"):format(bare_location)
			local location_page = new_title(location_cat)
			if location_page and location_page.exists then
				insert(parents, {name = location_cat, sort = "Languages"})
			end
		end
		local description = ("Categories for languages of %s (including sublects)."):format(location_link)

		return {
			topright = topright,
			description = description,
			parents = parents,
			breadcrumb = bare_basename,
			additional = "{{{umbrella_msg}}}",
		}, true
	end
end)


-- Handle categories such as [[:Category:English-based creole or pidgin languages]].
insert(raw_handlers, function(data)
	local langname = data.category:match("(.*)%-based creole or pidgin languages$")
	if langname then
		local lang = m_languages.getByCanonicalName(langname)
		if lang then
			return {
				lang = lang:getCode(),
				description = "Languages which developed as a [[creole]] or [[pidgin]] from " .. lang:makeCategoryLink() .. ".",
				parents = {{name = "Creole or pidgin languages", sort = {sort_base = "*" .. langname, lang = "en"}}},
				breadcrumb = lang:getCanonicalName() .. "-based",
			}
		end
	end
end)


-- Handle categories such as [[:Category:English-based constructed languages]].
insert(raw_handlers, function(data)
	local langname = data.category:match("(.*)%-based constructed languages$")
	if langname then
		local lang = m_languages.getByCanonicalName(langname)
		if lang then
			return {
				lang = lang:getCode(),
				description = "Constructed languages which are based on " .. lang:makeCategoryLink() .. ".",
				parents = {{name = "Constructed languages", sort = {sort_base = "*" .. langname, lang = "en"}}},
				breadcrumb = lang:getCanonicalName() .. "-based",
			}
		end
	end
end)


return {RAW_CATEGORIES = raw_categories, RAW_HANDLERS = raw_handlers}
