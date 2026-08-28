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

local function get_by_code(code)
	return require("Module:languages").getByCode(code, nil, true, true) or require("Module:scripts").getByCode(code)
end

local function get_code_from_title_without_namespace(title_without_namespace)
	local prefix = title_without_namespace:match("^(.+)%-translit%f[/%z]")
	if not prefix then
		error("Base segment of title should end in -translit: " .. title_without_namespace)
	end
	local code = prefix
	local lang_or_family_or_script = get_by_code(code)
	local secondary_script
	if not lang_or_family_or_script then
		-- Accommodate modules with multiple codes in the title.
		-- The first code should be used.
		-- Right now it strips segments from the end until it finds a match:
		-- Module:Deva-Beng-translit -> Deva-Beng -> Deva
		-- Module:pra-Deva-translit -> pra-Deva -> pra
		-- Module:Deva-mnc-Mong-translit -> Deva-mnc-Mong -> Deva-mnc -> Deva
		while true do
			local new_code, secondary_script_code = code:match("^(.+)%-([^%-]+)$")
			if new_code then
				code = new_code
			else
				break
			end
			lang_or_family_or_script = get_by_code(new_code)
			if secondary_script_code then
				secondary_script = get_by_code(secondary_script_code)
			end
			if lang_or_family_or_script then
				break
			end
		end
	end

	return code, lang_or_family_or_script, secondary_script
end

local function documentation_from_code(code, lang_or_family_or_script, secondary_script, explanation, title_without_namespace)
	if not lang_or_family_or_script then
		return "Language code in page name (<code>" .. code .. "</code>) not recognized."
	end

	local category_link = lang_or_family_or_script:makeCategoryLink()
	local secondary_script_category_link = secondary_script:makeCategoryLink(
		lang_or_family_or_script:hasType("language") and lang_or_family_or_script or nil)

	local transliteration_input
	if lang_or_family_or_script:hasType("script") then
		if secondary_script_category_link then
			transliteration_input = "text from the " .. category_link .. " to the " ..
				secondary_script_category_link
		else
			transliteration_input = "text in the " .. category_link
		end
	elseif lang_or_family_or_script:hasType("family") then
		transliteration_input = "text in one of the " .. category_link
		if secondary_script_category_link then
			transliteration_input = transliteration_input .. " in the " .. secondary_script_category_link
		end
	else -- language
		transliteration_input = category_link .. " text"
		if secondary_script_category_link then
			transliteration_input = transliteration_input .. " in the " .. secondary_script_category_link
		end
	end

	local tr_page = "WT:" .. mw.ustring.upper(code) .. " TR"

	return "This module will transliterate " .. transliteration_input
		.. (explanation and " " .. explanation or "")
		.. (mw.title.new(tr_page).exists and " per [[" .. tr_page .. "]]" or "")
		.. ". "
		.. require("Module:documentation").translitModuleLangList({args = { [1] = title_without_namespace:gsub("/documentation$", "") }})
		.. [=[

The module should preferably not be called directly from templates or other modules.
To use it from a template, use <code>{{[[Template:xlit|xlit]]}}</code>.
Within a module, use [[Module:languages#Language:transliterate]].

For testcases, see [[Module:]=] .. title_without_namespace:gsub("/documentation$", "") .. [=[/testcases]].

== Functions ==
; <code>tr(text, lang, sc)</code>
: Transliterates a given piece of <code>text</code> written in the script specified by the code <code>sc</code>, and language specified by the code <code>lang</code>.
: When the transliteration fails, returns <code>nil</code>.]=]
		.. require("Module:module categorization").categorize(fake_frame({
				is_template = "1",
				[1] = title_without_namespace,
			}, {
				[1] = code,
			}))
end

function export.documentation(title_without_namespace, explanation)
	local code, lang_or_family_or_script, secondary_script = get_code_from_title_without_namespace(title_without_namespace)
	return documentation_from_code(code, lang_or_family_or_script, secondary_script, explanation,
		title_without_namespace)
end

function export.documentation_template(frame)
	-- Parameters to {{translit module documentation}}:
	-- |code|description
	-- Ignore code because we get it from the page name.
	local pagename = mw.title.getCurrentTitle().text -- DO NOT replace with mw.loadData("Module:headword/data").pagename as we need the root portion
	local args = frame:getParent().args
	if args[1] and get_code_from_title_without_namespace(pagename) ~= args[1] then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/translit/input different from title]]
		require("Module:debug").track("translit/input different from title")
	end
	if args[1] then
		return documentation_from_code(args[1], get_by_code(args[1]), args.sc and get_by_code(args.sc) or nil, args[2],
			pagename)
	else
		return export.documentation(pagename, args[2])
	end
end

return export
