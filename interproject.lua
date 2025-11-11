local export = {}

local m_links = require("Module:links")
local m_params = require("Module:parameters")
local en_utilities_module = "Module:en-utilities"
local parse_interface_module = "Module:parse interface"
local parse_utilities_module = "Module:parse utilities"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local wikimedia_languages_module = "Module:wikimedia languages"

local full_link = m_links.full_link

local concat = table.concat
local insert = table.insert

local boolean_param = {type = "boolean"}

local function track(page)
	require("Module:debug/track")("interproject/" .. page)
end

local disambiguation_data
local function get_disambiguation_format_string(language)
	if not disambiguation_data then
		disambiguation_data = mw.loadData("Module:interproject/data/disambiguation")
	end
	return disambiguation_data[language] or "%s (disambiguation)"
end

-- Split an argument on comma, but not comma followed by whitespace, or backslash + comma, or comma inside of brackets.
local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
    else
		return {val}
	end
end

-- Join one or more items using commas, with "and" between the last two items.
local function join_on_comma(val)
	if val[2] then
		return require(table_module).serialCommaJoin(val)
	else
		return val[1]
	end
end

-- Replace + with the pagename, but replace \+ with +.
local function substitute_plus(val, pagename)
	if not val then
		return val
	end
	if val:find("%+") then
		val = val:gsub("%\\%+", "\1"):gsub("%+", require(string_utilities_module).replacement_escape(pagename)):
			gsub("\1", "+")
	end
	return val
end

local function process_links(linkdata, prefix, name, wmlang, sc)
	local links = {}
	local iplinks = {}

	for _, link in ipairs(linkdata) do
		local this_wmlang = link.wmlang or wmlang
		local this_prefix = prefix .. ":" .. (this_wmlang:getCode() == "en" and "" or this_wmlang:getCode() .. ":")
		local lang = this_wmlang:getWiktionaryLanguage()
		local ipalt = name .. " " .. (this_wmlang:getCode() == "en" and "" or "<sup>" .. this_wmlang:getCode() ..
			"</sup>")

		link.lang = lang
		link.sc = sc
		link.track_sc = true
		link.no_nonstandard_sc_cat = true
		link.tr = "-"
		-- Strip diacritics according to Wiktionary language principles. This isn't done automatically with Wikipedia
		-- links but seems a good idea to do. Prefix the link with a colon to override this. We try to separate the
		-- fragment before doing this to avoid the term getting converted to an unsupported title, and don't do any
		-- diacritic stripping on non-mainspace Wikipedia links (which will also get converted to unsupported titles
		-- if we try to pass them through makeEntryName).
		if link.term:find("^:") then
			link.term = link.term:sub(2)
		elseif not link.term:find(":") then
			local term, fragment = m_links.get_fragment(link.term:gsub("_", " "))
			local entry_name = lang:makeEntryName(term)
			if entry_name ~= term then
				link.alt = link.alt or link.term
				link.term = entry_name .. (fragment and "#" .. fragment or "")
			end
		end
		if link.fragment ~= nil then
			link.alt = (link.alt or link.term) .. " § " .. link.fragment
		end
		if link.alt == link.term then
			link.alt = nil
		end
		link.term = this_prefix .. link.term
		insert(iplinks, "<span class=\"interProject\">[[" .. mw.ustring.gsub(link.term, "'''?", "") .. "|" .. ipalt ..
			"]]</span>")
		insert(links, full_link(link, "bold"))
	end
	
	return links, iplinks
end

local function parse_one_wikipedia_link(val, pagename, default_wmlang, link_prefix)
	local origval = val
	local rest, dab = val:match("^(.*)<(dab!?)>$")
	val = rest or val
	local langcode, rest = val:match("^([a-z][a-z-]+):(.*)$")
	if rest and not rest:find("^ ") then
		val = rest
	else
		langcode = nil
	end
	local wmlang
	if langcode then
		wmlang = require(wikimedia_languages_module).getByCodeWithFallback(langcode)
		if not wmlang then
			error(("Unrecogized Wikimedia or Wiktionary code '%s': %s"):format(langcode,
				-- FIXME, move escape_wikicode() elsewhere
				require(parse_utilities_module).escape_wikicode(origval)))
		end
	else
		wmlang = default_wmlang
	end
	local link, label = val:match("^%[%[(.-)|(.*)%]%]$")
	if not link then
		link = val:match("^%[%[(.*)%]%]$")
	end
	link = link or val
	local rest, fragment = link:match("^(.-)#(.*)$")
	link = rest or link
	if link == "" then
		link = "+"
	end
	link = substitute_plus(link, pagename)
	label = substitute_plus(label, pagename)
	fragment = substitute_plus(fragment, pagename)
	local user_specified_label = not not label
	label = label or link
	if label == "" then
		-- implement pipe trick
		rest = link:match("^(.+) %(.-%)$")
		if rest then
			label = rest
		else
			label = link:gsub(",.*$", "")
		end
	end
	if dab == "dab" or dab == "dab!" then
		link = get_disambiguation_format_string(wmlang:getCode()):format(link)
	end
	if dab == "dab!" then
		label = get_disambiguation_format_string(wmlang:getCode()):format(label)
	end
	if user_specified_label and fragment then
		link = link .. "#" .. fragment
		fragment = nil
	end
	return {wmlang = wmlang, term = link_prefix .. link, alt = label, fragment = fragment}
end

local function parse_wikipedia_links(val, pagename, default_wmlang, link_prefix)
	local raw_links = split_on_comma(val)
	for i, raw_link in ipairs(raw_links) do
		raw_links[i] = parse_one_wikipedia_link(raw_link, pagename, default_wmlang, link_prefix)
		default_wmlang = raw_links[i].wmlang
	end
	return raw_links
end

-- FIXME: From [[Module:zh/templates]] implementation of old {{zh-wp}}; do we want something like this?
--local wp_data = {
--	["zh"] = { "Written Standard Chinese<sup>[[w:Written vernacular Chinese|?]]</sup>", "zh" },
--	["cdo"] = { "Eastern Min", "cdo" },
--	["gan"] = { "Gan", "zh" },
--	["hak"] = { "Hakka", "hak" },
--	["lzh"] = { "Classical", "zh" },
--	["nan"] = { "Southern Min", "nan" },
--	["wuu"] = { "Wu", "zh" },
--	["yue"] = { "Cantonese", "zh" },
--}

local function format_wikipedia_box(frame, linkdata, linktype, slim, sc)
	local wmlangcode, multibox
	for i, linkspec in ipairs(linkdata) do
		if i == 1 then
			wmlangcode = linkspec.wmlang:getCode()
		elseif wmlangcode ~= linkspec.wmlang:getCode() then
			multibox = true
			break
		end
	end

	if slim and not multibox then
		for _, linkspec in ipairs(linkdata) do
			if linktype == "category" then
				linkspec.alt = "Category:" .. linkspec.alt
			elseif linktype == "portal" then
				linkspec.alt = "Portal:" .. linkspec.alt
			end
		end
	end

	if not linkdata[2] then
		linktype = require(en_utilities_module).add_indefinite_article(linktype)
	else
		linktype = require(en_utilities_module).pluralize(linktype)
	end

	local links, iplinks = process_links(linkdata, "w", "Wikipedia", nil, sc)

	local div_prefix = "<div class=\"interproject-box sister-wikipedia sister-project noprint floatright\">"
	local template_extension = frame:extensionTag("templatestyles", "", {src="Module:interproject/style.css"})
	if multibox then
		local result = {
			div_prefix ..
			"<div style=\"float: left;\">[[File:Wikipedia-logo.png|32px|none|link=|alt=]]</div>" ..
			"<div style=\"margin-left: 40px;\">[[Wikipedia]] has " .. linktype .. " on:<ul>"
		}
		for i, linkspec in ipairs(linkdata) do
			local annotation = " <span style=\"font-size:80%\">(" .. linkspec.wmlang:getCanonicalName() .. ")</span>"
			insert(result, "<li>" .. links[i] .. annotation .. "</li>")
		end
		insert(result, "</ul></div></div>" .. template_extension)
		return concat(result)

	elseif slim then
		local wmlang = linkdata[1].wmlang
		return
			div_prefix ..
			"<div style=\"float: left;\">[[File:Wikipedia-logo.png|14px|none| ]]</div>" ..
			"<div style=\"margin-left: 15px;\">" ..
			" &nbsp;" ..
			join_on_comma(links) ..
			" on " ..
			(wmlang:getCode() == "en" and "" or wmlang:getCanonicalName() .. "&nbsp;") ..
			"Wikipedia" ..
			"</div></div>" .. template_extension
	else
		local wmlang = linkdata[1].wmlang
		return
			div_prefix ..
			"<div style=\"float: left;\" class=\"interproject-box-logo\">[[File:Wikipedia-logo-v2.svg|x40px|none|link=|alt=]]</div>" ..
			"<div style=\"margin-left: 60px;\">" ..
			wmlang:getCanonicalName() .. " [[Wikipedia]] has " .. linktype .. " on:" ..
			"<div style=\"margin-left: 10px;\">" .. join_on_comma(links) .. "</div>" ..
			"</div>" .. concat(iplinks) .. "</div>" .. template_extension
	end
end

function export.wikipedia_box(frame)
	local params = {
		[1] = true,
		
		["cat"] = true,
		["category"] = {alias_of = "cat"},
		["i"] = boolean_param,
		["lang"] = {type = "Wikimedia language", fallback = true, default = "en"},
		["portal"] = true,
		["sc"] = {type = "script"},
		["pagename"] = true,

		-- make old parameters throw an explanatory error; FIXME: eventually remove these.
		[2] = {replaced_by = false, instead = "use a piped link in 1=, e.g. {{!((}}foo{{!}}bar{{))!}}"},
		["mul"] = {replaced_by = false, instead = "use comma-separated items in 1="},
		["mullabel"] = {replaced_by = false, instead = "use a piped link in 1=, e.g. {{!((}}foo{{!}}bar{{))!}}"},
		["mulcat"] = {replaced_by = false, instead = "use comma-separated items in cat="},
		["mulcatlabel"] = {replaced_by = false, instead = "use a piped link in cat=, e.g. {{!((}}foo{{!}}bar{{))!}}"},
		["section"] = {replaced_by = false, instead = "use the syntax 'article#Section' in 1="},
	}

	local parargs = frame:getParent().args
	local args = m_params.process(parargs, params)
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename
	local sc = args.sc
	local linkdata, linktype

	if parargs.lang then
		-- Tracking for old use of lang= instead of a language prefix.
		track("old-wp")
	end
	if (args[1] and 1 or 0) + (args.cat and 1 or 0) + (args.portal and 1 or 0) > 1 then
		error("Can't specify more than one of 1=, cat= and portal=")
	end
	local rawval, link_prefix
	if args.cat then
		linktype = "category"
		link_prefix = "Category:"
		rawval = args.cat
	elseif args.portal then
		linktype = "portal"
		link_prefix = "Portal:"
		rawval = args.portal
	else
		linktype = "article"
		link_prefix = ""
		rawval = args[1] or ""
	end
	linkdata = parse_wikipedia_links(rawval, pagename, args.lang, link_prefix)

	return format_wikipedia_box(frame, linkdata, linktype, frame.args.slim, sc)
end


function export.projectlink(frame, compat)
	local required = {required = true}
	local iparams = {
		["prefix"] = required,
		["name"] = required,
		["image"] = required,
		["requirelang"] = boolean_param,
		["compat"] = boolean_param,
	}

	local iargs = m_params.process(frame.args, iparams)
	
	compat = compat or iargs.compat
	local lang_required = iargs.requirelang or false

	local lang_param = compat and "lang" or 1
	local term_param = compat and 1 or 2
	local alt_param = compat and 2 or 3

	local params = {
		[lang_param] = {type = "Wikimedia language", method = "fallback", required = lang_required, default = "en"},
		[term_param] = true,
		[alt_param] = true,
		
		["i"] = boolean_param,
		["nodot"] = true,
		["sc"] = {type = "script"},
		["section"] = true
	}
	
	local args = m_params.process(frame:getParent().args, params)

	local wmlang = args[lang_param]
	local sc = args["sc"]

	local term = args[term_param] or mw.loadData("Module:headword/data").pagename
	local linkdata = {term = term, alt = args[alt_param], fragment = args["section"]}
	
	if args["i"] then
		local prefixed = "''"
		if (iargs["prefix"] == "commons:Category") then
			prefixed = "Category:" .. prefixed
		end
		if linkdata.alt then
			linkdata.alt = prefixed .. linkdata.alt .. "''"
		else
			-- While it is true that the link module automatically removes italics from terms,
			-- linkdata.term is used outside this module too (image link and "interProject" link)
			linkdata.alt = prefixed .. linkdata.term .. "''"
		end
	end
	
	local links, iplinks = process_links({linkdata}, iargs["prefix"], iargs["name"], wmlang, sc)
	
	return
		"[[Image:" .. iargs["image"] .. "|15px|link=" .. iargs["prefix"] .. ":" .. (wmlang:getCode() == "en" and "" or wmlang:getCode() .. ":") .. term .. "]] " ..
		concat(links, " and ") ..
		" on " ..
		(wmlang:getCode() == "en" and "" or "the " .. wmlang:getCanonicalName() .. " ") ..
		" " .. iargs["name"] .. (args["nodot"] and "" or ".") ..
		concat(iplinks)
end

return export
