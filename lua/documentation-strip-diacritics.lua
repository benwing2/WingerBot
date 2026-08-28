local export = {}

local function fake_frame(args, parent_args)
	return {
		args = args,
		getParent = function()
			return {
				args = parent_args,
			}
		end
	}
end

function get_by_code(code)
	return require "Module:languages".getByCode(code, nil, false, true) or require "Module:scripts".getByCode(code)
end

local function get_code_from_title_without_namespace(title_without_namespace)
	local prefix = title_without_namespace:match("^(.+)%-stripdiacritics%f[/%z]")
	if not prefix then
		error("Base segment of title should end in -stripdiacritics: " .. title_without_namespace)
	end
	local code = prefix
	local lang_or_family_or_script = get_by_code(code)
	
	return code, lang_or_family_or_script
end

function export.documentation(title_without_namespace, explanation)
	local code, lang_or_family_or_script = get_code_from_title_without_namespace(title_without_namespace)
	return export.documentation_from_code(code, explanation, title_without_namespace)
end

function export.documentation_from_code(code, explanation, title_without_namespace)
	local lang_or_family_or_script = get_by_code(code)
	
	if not lang_or_family_or_script then
		return "Language code in page name (<code>" .. code .. "</code>) not recognized."
	end
	
	local category_name = lang_or_family_or_script:getCategoryName()
	
	local strip_diacritics_input
	if lang_or_family_or_script:hasType("script") then
		strip_diacritics_input = "text in the [[:Category:" .. category_name .. "|" .. category_name .. "]]"
	elseif lang_or_family_or_script:hasType("family") then
		strip_diacritics_input = "text in one of the [[:Category:" .. category_name .. "|" .. category_name .. "]]"
	else -- language
		strip_diacritics_input = "[[:Category:" .. category_name .. "|" .. category_name .. "]] text"
	end
	
	return "This module will generate diacritic-stripped text for " .. strip_diacritics_input
		.. (explanation and " " .. explanation or "")
		.. ". "
		.. require("Module:documentation").stripDiacriticsModuleLangList({args = { [1] = title_without_namespace:gsub("/documentation$", "") }})
		.. [=[

The module should preferably not be called directly from templates or other modules.
To use it from a template, use <code>{{[[Template:strip diacritics|strip diacritics]]}}</code>.
Within a module, use [[Module:languages#Language:stripDiacritics]].

For testcases, see [[Module:]=] .. title_without_namespace:gsub("/documentation$", "") .. [=[/testcases]].

== Functions ==
; <code>stripDiacritics(text, lang, sc)</code>
: Strips diacritics from a given piece of <code>text</code> written in the script specified by the code <code>sc</code>, and language specified by the code <code>lang</code>.
: When diacritic stripping fails, returns <code>nil</code>.]=]
		.. require("Module:module categorization").categorize(fake_frame({
				is_template = "1",
				[1] = title_without_namespace,
			}, {
				[1] = code,
			}))
end

function export.documentation_template(frame)
	-- Parameters to {{strip diacritics module documentation}}:
	-- |code|description
	-- Ignore code because we get it from the page name.
	local pagename = mw.title.getCurrentTitle().text -- DO NOT replace with mw.loadData("Module:headword/data").pagename as we need the root portion
	local args = frame:getParent().args
	if args[1] and get_code_from_title_without_namespace(pagename) ~= args[1] then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/strip diacritics/input different from title]]
		require("Module:debug").track("strip diacritics/input different from title")
	end
	if args[1] then
		return export.documentation_from_code(args[1], args[2], pagename)
	else
		return export.documentation(pagename, args[2])
	end
end

return export
