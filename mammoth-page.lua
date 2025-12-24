local export = {}

local m_links_data = mw.loadData("Module:links/data")
local m_parameters = require("Module:parameters")
local m_template_parser = require("Module:template parser")
local m_utilities = require("Module:utilities")

local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

function export.show_template(frame)
	local parent_args = frame:getParent().args
	local args = m_parameters.process(parent_args, {
		pagename = true
	})
	local this_title
	if args.pagename then
		this_title = mw.title.new(args.pagename)
		if not this_title then
			error(("Bad pagename: '%s'"):format(args.pagename))
		end
	else
		this_title = mw.title.getCurrentTitle()
	end
	
	-- Are we on a subpage?
	local root_mammoth_page_title = this_title
	
	local prefixed_base, subpage = this_title.prefixedText:match("^(.+)/(.-)$")
	if subpage and m_links_data.mammoth_page_subpages[subpage] then
		root_mammoth_page_title = mw.title.new(prefixed_base)
		if not root_mammoth_page_title then
			error(("Internal error: Something wrong, prefixed base '%s' of mammoth page has bad character even though prefixedText '%s' does not seem to"):format(
				prefixed_base, this_title.prefixedText))
		end
	end

	-- Translingual and English are assumed to always be present on the root page
	local toc_links = {
		"[[" .. root_mammoth_page_title.prefixedText .. "#Translingual|Translingual]] •&nbsp;" ..
			"[[" .. root_mammoth_page_title.prefixedText .. "#English|English]]"
	}
	local L2_count = 2

	-- compile a list of L2 headers on each subpage
	for _, subpage_spec in ipairs(m_links_data.mammoth_page_subpage_list) do
		local subpage_name = subpage_spec[1]
		local subpage_title = root_mammoth_page_title:subPageTitle(subpage_name)
		local subpage_content = subpage_title and subpage_title:getContent()
		if subpage_content then
			local subpage_links = {}
			for heading in m_template_parser.find_headings(subpage_content, 2, 2) do
				local name = heading:get_name()
				if name then -- malformed L2 headings (e.g. with newlines in them due to template expansion) don't have names
					local link = "[[" .. root_mammoth_page_title.prefixedText ..
						"/" .. subpage_name .. "#" .. name .. "|" .. name .. "]]"
					insert(subpage_links, link)
					L2_count = L2_count + 1
				end
			end
			insert(toc_links, concat(subpage_links, " •&nbsp;"))
		end
	end

	return frame:extensionTag("templatestyles", nil, {src="Module:minitoc/styles.css"}) ..
	"<div class=\"minitoc mammoth-minitoc\" style=\"border: 1px solid var(--wikt-palette-grey, #9e9e9e); font-size: 95%\">" ..
	"<div class=\"NavHead\" style=\"margin: 2px; min-height: 1.6em; font-weight: bold; background-color: var(--wikt-palette-dullcyan, #eaecf0);\">Languages (" .. L2_count .. ")</div>" ..
	"<div class=\"NavContent\" style=\"text-align: center; border-top: 1px solid var(--wikt-palette-grey, #9e9e9e);\">" .. (toc_links and concat(toc_links, "<hr>") or "") .. "<hr>" ..
	"<div>''The entries for '''" .. root_mammoth_page_title.text .. "''' are spread across multiple pages due to their length.''</div></div></div>" ..
	m_utilities.format_categories("Mammoth pages")
end

return export
