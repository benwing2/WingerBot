local raw_categories = {}
local raw_handlers = {}

-- A list of Unicode blocks to which the characters of the script or scripts belong is created by this module
-- and displayed in script category pages.
local blocks_submodule = "Module:category tree/scripts/blocks"
local en_utilities_module = "Module:en-utilities"
local scripts_module = "Module:scripts"
local string_utilities_module = "Module:string utilities"

local m_str_utils = require(string_utilities_module)

local add_indefinite_article = require(en_utilities_module).add_indefinite_article
local get_script_by_category_name = require(scripts_module).getByCategoryName
local pattern_escape = m_str_utils.pattern_escape

-----------------------------------------------------------------------------
--                                                                         --
--                               SCRIPT LABELS                             --
--                                                                         --
-----------------------------------------------------------------------------


--[=[
The following values are recognized for each script label:

'description'
  A plain English description for the label. Special template substitutions are recognized; see below.
'umbrella_parents'
  A table listing one or more parent categories of the umbrella category 'LABELS by script' for this label.
  The format is as for regular raw categories (see [[Module:category tree/data/documentation]]).
'umbrella_breadcrumb'
  The breadcrumb to use in the umbrella category 'LABELS by script'. Defaults to "by script".
'catfix'
  Same as the 'catfix' parameter for regular raw categories (see [[Module:category tree/data/documentation]]).
  This specifies a language code to use to ensure that pages in the category are displayed in the right font and linked
  appropriately. If this is set, the 'catfix_sc' parameter will effectively be set with the script code in question.

Special template-like parameters can be used inside the 'description' field (as well as in the 'root_description', 'root_topright' and
'root_additional' variable values initialized below). These are replaced by the equivalent text.

{{{code}}}: Script code.
{{{codes}}}: A comma-separated list of all the alias codes for this script (e.g. mnc-Mong, sjo-Mong, xwo-Mong for Mongolian).
{{{codesplural}}}: The value "s" if {{{codes}}} lists more than one code, otherwise an empty string.
{{{scname}}}: The name of the script that the category belongs to.
{{{sccat}}}: The name of the script's main category, which adds "script" to the capitalized regular name.
{{{scdisp}}}: The display form of the script, which adds "script" to the regular name.
{{{scprosename}}}: Same as {{{scdisp}}} for Morse code and flag semaphore, otherwise adds "the" before {{{scdisp}}}.
{{{Wikipedia}}}: The Wikipedia article for the script (if it is present in the language's data file), or else {{{sccat}}}.
]=]

local script_labels = {}

script_labels["characters"] = {
	description = function(sc)
		if sc:getCode() == "None" then
			return "All characters whose script cannot be determined."
		else
			return "All characters from {{{scprosename}}}, and their possible variations, such as versions with diacritics and combinations recognized as single characters in any language."
		end
	end,
	additional = function(sc)
		if sc:getCode() == "None" then
			return "This also includes terms where such characters are listed. For example, {{m|mul|㋍}} (a CJK character called ''SQUARE ERG'' and consisting of the word [[erg]] inside of a square) is listed on the [[erg]] page, leading to this page getting categorized into this category."
		else
			return nil
		end
	end,
	umbrella_parents = {"Fundamental"},
	umbrella_breadcrumb = "Characters by script",
	catfix = "mul",
}

script_labels["appendices"] = {
	description = "Appendices about {{{scprosename}}}.",
	umbrella_parents = {"Category:Appendices"},
}

script_labels["languages"] = {
	description = function(sc)
		if sc:getCode() == "None" then
			return "Languages whose script or scripts have not yet been specified in Wiktionary (and may not exist)."
		else
			return "Languages that use {{{scprosename}}}."
		end
	end,
	umbrella_parents = {"All languages"},
}

script_labels["templates"] = {
	description = "Templates with predefined contents for {{{scprosename}}}.",
	umbrella_parents = {"Templates"},
}

script_labels["modules"] = {
	description = "Modules that implement functionality for {{{scprosename}}}.",
	umbrella_parents = {"Modules"},
}

script_labels["data modules"] = {
	description = "Modules that contain data related to {{{scprosename}}}.",
	umbrella_parents = {"Data modules"},
}



-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["All scripts"] = {
	description = "This category contains the categories for every script (writing system) on Wiktionary.",
	additional = "See [[Wiktionary:List of scripts]] for a full list.",
	parents = {"Fundamental"},
}

-- Types of writing systems listed in [[Module:writing systems/data]].
raw_categories["Scripts by type"] = {
	description = "Scripts classified by how they represent words.",
	parents = {{ name = "All scripts", sort = " " }},
	breadcrumb = "by type",
}

raw_categories["Abjads"] = {
	description = "Scripts whose basic symbols represent consonants. Some of these are impure abjads, which have letters for some vowels.",
	parents = {"Scripts by type"},
}

raw_categories["Abugidas"] = {
	description = "Scripts whose symbols represent consonant and vowel combinations. Symbols representing the same consonant combined with different vowels are for the most part similar in form.",
	parents = {"Scripts by type"},
}

raw_categories["Alphabetic writing systems"] = {
	description = "Scripts whose symbols represent individual speech sounds.",
	parents = {"Scripts by type"},
}

raw_categories["Logographic writing systems"] = {
	description = "Scripts whose symbols represent individual words.",
	parents = {"Scripts by type"},
}

raw_categories["Pictographic writing systems"] = {
	description = "Scripts whose symbols represent individual words by using symbols that resemble the physical objects to which those words refer.",
	parents = {"Scripts by type"},
}

raw_categories["Semisyllabaries"] = {
	description = "Scripts which are a combination of an alphabet and a syllbary.",
	parents = {"Scripts by type"},
}

raw_categories["Syllabaries"] = {
	description = "Scripts whose symbols represent consonant and vowel combinations. Symbols representing the same consonant combined with different vowels are for the most part different in form.",
	parents = {"Scripts by type"},
}

for script_label, obj in pairs(script_labels) do
	raw_categories[mw.getContentLanguage():ucfirst(script_label) .. " by script"] = {
		description = "Categories with " .. script_label .. " of various specific scripts.",
		breadcrumb = obj.umbrella_breadcrumb or "by script",
		parents = obj.umbrella_parents,
	}
end



-----------------------------------------------------------------------------
--                                                                         --
--                                RAW HANDLERS                             --
--                                                                         --
-----------------------------------------------------------------------------



-- Intro text for "root" categories such as [[Category:Arabic script]]. Template substitutions are as described above.
local root_topright = [=[<div style="clear: right; border: solid var(--border-color-base,#aaa) 1px; margin: 1 1 1 1; background: var(--wikt-palette-paleblue,#f9f9f9); width: 250px; padding: 5px; text-align: left; float: right">
<div style="text-align: center; margin-bottom: 10px; margin-top: 5px">'''{{{scdisp}}}'''</div>

{| style="font-size: 90%; background: var(--wikt-palette-paleblue,#f9f9f9)"
| style="vertical-align: middle; height: 35px;" | [[File:Wikipedia-logo.png|35px|none|Wikipedia]] || ''Wikipedia article about {{{scprosename}}}''
|-
| colspan="2" style="padding-left: 50px; border-bottom: 1px solid var(--border-color-base,#aaa);" | '''[[w:{{{Wikipedia}}}|{{{Wikipedia}}}]]'''
|-
| style="vertical-align: middle; height: 35px;" | [[File:Crystal kfind.png|35px|none|Considerations]] || {{{scdisp}}} considerations
|-
| colspan="2" style="padding-left: 50px; border-bottom: 1px solid var(--border-color-base,#aaa);" | '''[[Wiktionary:About {{{scdisp}}}]]'''
|-
| style="vertical-align: middle; height: 35px;" | [[File:Book notice.png|35px|none|Information]] || {{{scdisp}}} information
|-
| colspan="2" style="padding-left: 50px; border-bottom: 1px solid var(--border-color-base,#aaa);" | '''[[Appendix:{{{sccat}}}]]'''
|-
| style="vertical-align: Middle; height: 35px;" | [[File:Abc box.svg|35px|none|Code]] || {{{scdisp}}} code
|-
| colspan="2" style="padding-left: 50px; border-bottom: 1px solid var(--border-color-base,#aaa);" | '''{{{code}}}'''
|}
</div>]=]

-- Short description for "root" categories such as [[Category:Arabic script]]. Template substitutions are as described above.
local root_description = "This is the main category of '''{{{scprosename}}}'''."

-- Additional description text for "root" categories such as [[Category:Arabic script]]. Template substitutions are as described above.
local root_additional = [=[Information about {{{scprosename}}} may be available at [[Appendix:{{{sccat}}}]].

In various places at Wiktionary, {{{scprosename}}} is represented by the [[Wiktionary:Scripts|code{{{codesplural}}}]] {{{codes}}}.]=]


-- Replace template notation {{{}}} with variables.
local function substitute_template_refs(text, sc)
	local displayForm = sc:getDisplayForm()
	local scname = sc:getCanonicalName()
	local codes = {}

	if type(text) == "function" then
		text = text(sc)
	end

	if not text then
		return nil
	end

	for code, data in pairs(mw.loadData("Module:scripts/data")) do
		if data[1] == scname then
			table.insert(codes, "'''" .. code .. "'''")
		end
	end

	if codes[2] then
		table.sort(
			codes,
			-- Four-letter codes have length 10, because they are bolded: '''Latn'''.
			function(code1, code2)
				if #code1 == 10 then
					if #code2 == 10 then
						return code1 < code2
					else
						return true
					end
				else
					if #code2 == 10 then
						return false -- four-letter codes before other codes
					else
						return code1 < code2
					end
				end
			end)
	end
	
	local content = {
		code = sc:getCode(),
		codesplural = codes[2] and "s" or "",
		codes = table.concat(codes, ", "),
		scname = scname,
		sccat = sc:getCategoryName(),
		scdisp = displayForm,
		scprosename = (displayForm:find("code") or displayForm:find("semaphore")) and displayForm or "the " .. displayForm,
		Wikipedia = sc:getWikipediaArticle(),
	}
	
	text = string.gsub(
		text,
		"{{{([^}]+)}}}",
		function (parameter)
			return content[parameter] or error("No value for script category parameter '" .. parameter .. "'.")
		end)
	
	return text
end


local function get_root_additional(additional, sc)
	local ret = { additional }
	
	local systems = sc:getSystems()
	for _, system in ipairs(systems) do
		table.insert(ret, "\n\nThe {{{scname}}} script is ")
		table.insert(ret, add_indefinite_article(system:getDisplayForm("singular")))
		table.insert(ret, ".")
	end
	
	local blocks = require(blocks_submodule).print_blocks_by_canonical_name(sc:getCanonicalName())
	
	if blocks then
		table.insert(ret, "\n")
		table.insert(ret, blocks)
	end

	return substitute_template_refs(table.concat(ret), sc)
end


-- Handler for 'SCRIPT script' e.g. [[Category:Arabic script]] as well as [[Category:Morse code]] and
-- [[Category:Flag semaphore]].
table.insert(raw_handlers, function(data)
	local sc = get_script_by_category_name(data.category)
	if not sc then
		return nil
	end
	
	-- Compute parents.
	local parents = {}
	local systems = sc:getSystems()
	for _, system in ipairs(systems) do
		table.insert(parents, system:getCategoryName())
	end
	table.insert(parents, "All scripts")

	-- Compute (extra) children.
	local children = {}
	for script_label in pairs(script_labels) do
		table.insert(children, data.category .. " " .. script_label)
	end

	return {
		canonical_name = sc:getCategoryName(),
		topright = substitute_template_refs(root_topright, sc),
		description = substitute_template_refs(root_description, sc),
		additional = get_root_additional(root_additional, sc),
		parents = parents,
		breadcrumb = sc:getCanonicalName(),
		extra_children = children,
		can_be_empty = true,
	}
end)


-- Handler for 'SCRIPT script LABELS' e.g. [[Category:Arabic script templates]] as well as [[Category:Morse code LABELS]] and
-- [[Category:Flag semaphore LABELS]].
table.insert(raw_handlers, function(data)
	local sc, scname, label
	for lab in pairs(script_labels) do
		scname, label = data.category:match("^(.+) (" .. pattern_escape(lab) .. ")$")
		sc = get_script_by_category_name(scname)
		if sc then
			break
		end
	end
	if not sc then
		return nil
	end
	
	local label_obj = script_labels[label]

	-- Compute parents.
	local parents = {
		{name = scname, sort = label},
		-- umbrella category
		mw.getContentLanguage():ucfirst(label) .. " by script",
	}

	return {
		canonical_name = sc:getCategoryName() .. " " .. label,
		description = substitute_template_refs(label_obj.description, sc),
		additional = substitute_template_refs(label_obj.additional, sc),
		parents = parents,
		breadcrumb = label,
		catfix = label_obj.catfix,
		catfix_sc = label_obj.catfix and sc:getCode(),
	}
end)


return {RAW_CATEGORIES = raw_categories, RAW_HANDLERS = raw_handlers}
