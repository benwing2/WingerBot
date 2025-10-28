local m_params = require("Module:parameters")

local concat = table.concat
local full_link = require("Module:links").full_link
local insert = table.insert

local export = {}

local function track(page)
	require("Module:debug/track")("interproject/" .. page)
end


local function process_links(linkdata, prefix, name, wmlang, sc)
	prefix = prefix .. ":" .. (wmlang:getCode() == "en" and "" or wmlang:getCode() .. ":")
	
	local links = {}
	local iplinks = {}
	
	local lang = wmlang:getWiktionaryLanguage()
	local ipalt = name .. " " .. (wmlang:getCode() == "en" and "" or "<sup>" .. wmlang:getCode() .. "</sup>")
	
	for _, link in ipairs(linkdata) do
		link.lang = lang
		link.sc = sc
		link.track_sc = true
		link.no_nonstandard_sc_cat = true
		link.tr = "-"
		if link.fragment ~= nil then
			link.alt = (link.alt or link.term) .. ' § ' .. link.fragment
		end
		link.term = prefix .. link.term
		if link.alt == link.term then
			link.alt = nil
		end
		insert(iplinks, "<span class=\"interProject\">[[" .. mw.ustring.gsub(link.term, "'''?", "") .. "|" .. ipalt .. "]]</span>")
		insert(links, full_link(link, "bold"))
	end
	
	return links, iplinks
end


function export.wikipedia_box(frame)
	local plain_param = {}
	local params = {
		[1] = plain_param,
		[2] = plain_param,
		
		["cat"] = plain_param,
		["category"] = {alias_of = "cat"},
		["i"] = {type = "boolean"},
		["lang"] = {type = "Wikimedia language", fallback = true, default = "en"},
		["mul"] = plain_param,
		["mullabel"] = plain_param,
		["mulcat"] = plain_param,
		["mulcatlabel"] = plain_param,
		["portal"] = plain_param,
		["sc"] = {type = "script"},
		["section"] = plain_param
	}
	
	local args = m_params.process(frame:getParent().args, params)
	
	if args.mul or args.mullabel or args.mulcat or args.mulcatlabel then
		track("wikipedia-box-mul")
	end
	
	local wmlang = args["lang"]
	local sc = args["sc"]

	local linkdata = {}
	
	if args["cat"] then
		insert(linkdata, {term = "Category:" .. args["cat"], alt = args[1] or args["cat"]})
	elseif args["portal"] then
		insert(linkdata, {term = "Portal:" .. args["portal"], alt = args[1] or args["portal"]})
	else
		insert(linkdata, {term = args[1] or mw.loadData("Module:headword/data").pagename, 
								alt = args[2],
								fragment = args["section"]})
	end
	
	if args["mul"] or args["mulcat"] then
		if args["mulcat"] then
			insert(linkdata, {term = "Category:" .. args["mulcat"], alt = args["mulcatlabel"] or args["mulcat"]})
		else
			insert(linkdata, {term = args["mul"], alt = args["mullabel"]})
		end
	end
	
	local links, iplinks = process_links(linkdata, "w", "Wikipedia", wmlang, sc)
	
	if frame.args["slim"] then
		return
			"<div class=\"interproject-box sister-wikipedia sister-project noprint floatright\">" ..
			"<div style=\"float: left;\">[[File:Wikipedia-logo.png|14px|none| ]]</div>" ..
			"<div style=\"margin-left: 15px;\">" ..
			" &nbsp;" ..
			concat(links, " and ") ..
			" on " ..
			(wmlang:getCode() == "en" and "" or wmlang:getCanonicalName() .. "&nbsp;") ..
			"Wikipedia" ..
			"</div>" ..
			"</div>" .. frame:extensionTag("templatestyles", "", {src="Module:interproject/style.css"})
	else
		local linktype
		
		if args["cat"] then
			linktype = "a category"
		elseif args["mul"] then
			linktype = "articles"
		elseif args["mulcat"] then
			linktype = "categories"
		elseif args["portal"] then
			linktype = "a portal"
		else
			linktype = "an article"
		end
		
		return
			"<div class=\"interproject-box sister-wikipedia sister-project noprint floatright\">" ..
			"<div style=\"float: left;\" class=\"interproject-box-logo\">[[File:Wikipedia-logo-v2.svg|x40px|none|link=|alt=]]</div>" ..
			"<div style=\"margin-left: 60px;\">" ..
			wmlang:getCanonicalName() .. " [[Wikipedia]] has " .. linktype .. " on:" ..
			"<div style=\"margin-left: 10px;\">" .. concat(links, " and ") .. "</div>" ..
			"</div>" ..
			concat(iplinks) .. ((args[1] == mw.loadData("Module:headword/data").pagename and not args[2]) and "[[Category:wikipedia with redundant first parameter]]" or "") ..
			"</div>" .. frame:extensionTag("templatestyles", "", {src="Module:interproject/style.css"})
	end
end


function export.projectlink(frame, compat)
	local plain_param = {}
	local required = {required = true}
	local boolean = {type = "boolean"}
	local iparams = {
		["prefix"] = required,
		["name"] = required,
		["image"] = required,
		["requirelang"] = boolean,
		["compat"] = boolean,
	}

	local iargs = m_params.process(frame.args, iparams)
	
	compat = compat or iargs.compat
	local lang_required = iargs.requirelang or false

	local lang_param = compat and "lang" or 1
	local term_param = compat and 1 or 2
	local alt_param = compat and 2 or 3

	local params = {
		[lang_param] = {type = "Wikimedia language", method = "fallback", required = lang_required, default = "en"},
		[term_param] = plain_param,
		[alt_param] = plain_param,
		
		["i"] = boolean,
		["nodot"] = plain_param,
		["sc"] = {type = "script"},
		["section"] = plain_param
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
