-- TODO:
	-- ietf_subtag field used with a 2/3-letter langauge/family code except qaa-qtz, or a 4-letter script code.
	-- Check against files containing up-to-date ISO data, to cross-check validity.
local export = {}

local mw = mw
local require = require
local string = string

local Array = require("Module:array")
local m_en_utilities = require("Module:en-utilities")
local m_etym_languages_canonical_names = require("Module:etymology languages/canonical names")
local m_etym_languages_codes = require("Module:etymology languages/code to canonical name")
local m_etym_languages_data = require("Module:etymology languages/data")
local m_families = require("Module:families")
local m_families_canonical_names = require("Module:families/canonical names")
local m_families_codes = require("Module:families/code to canonical name")
local m_families_data = require("Module:families/data")
local m_languages = require("Module:languages")
local m_languages_canonical_names = require("Module:languages/canonical names")
local m_languages_codes = require("Module:languages/code to canonical name")
local m_languages_data_all = require("Module:languages/data/all")
local m_load = require("Module:load")
local m_scripts = require("Module:scripts")
local m_scripts_canonical_names = require("Module:scripts/canonical names")
local m_scripts_codes = require("Module:scripts/code to canonical name")
local m_scripts_data = require("Module:scripts/data")
local m_str_utils = require("Module:string utilities")
local m_table = require("Module:table")

local add_indefinite_article = m_en_utilities.add_indefinite_article
local codepoint = m_str_utils.codepoint
local concat = table.concat
local dump = mw.dumpObject
local format = string.format
local gcodepoint = m_str_utils.gcodepoint
local get_data_module_name = m_languages.getDataModuleName
local get_family_by_code = m_families.getByCode
local get_family_by_canonical_name = m_families.getByCanonicalName
local get_indefinite_article = m_en_utilities.get_indefinite_article
local get_language_by_code = m_languages.getByCode
local get_language_by_canonical_name = m_languages.getByCanonicalName
local get_script_by_code = m_scripts.getByCode
local get_script_by_canonical_name = m_scripts.getByCanonicalName
local gmatch = string.gmatch
local gsub = string.gsub
local insert = table.insert
local ipairs = ipairs
local is_callable = require("Module:fun").is_callable
local is_positive_integer = require("Module:math").is_positive_integer
local is_known_language_tag = mw.language.isKnownLanguageTag
local isutf8 = mw.ustring.isutf8
local json_decode = mw.text.jsonDecode
local language_link = require("Module:links").language_link
local list_to_set = m_table.listToSet
local list_to_text = mw.text.listToText
local load_data = m_load.load_data
local log = mw.log
local main_loader = package.loaders[2]
local make_family = m_families.makeObject
local make_lang = m_languages.makeObject
local make_script = m_scripts.makeObject
local match = string.match
local new_title = mw.title.new
local next = next
local pairs = pairs
local pcall = pcall
local remove_comments = require("Module:string/removeComments")
local safe_require = m_load.safe_require
local sorted_pairs = m_table.sortedPairs
local split = m_str_utils.split
local sub = string.sub
local table_len = m_table.length
local tag_text = require("Module:script utilities").tag_text
local type = type
local umatch = m_str_utils.match
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local aliases = require("Module:languages/data").aliases
local messages

local function discrepancy(modname, ...)
	local success, result = pcall(function(...)
		messages[modname]:insert(format(...))
	end, ...)
	if not success then
		log(result, ...)
	end
end

local messages_mt = {}

function messages_mt:__index(k)
	local val = Array()
	self[k] = val
	return val
end

local all_codes = {}

local language_names = {}
local etym_language_names = {}
local family_names = {}
local script_names = {}

local nonempty_families = {}
local allowed_empty_families = {tbq = true}
local nonempty_scripts = {}
	
local function link(obj, code_first)
	return type(obj) == "string" and obj or
		code_first and format("<code>%s</code> (%s)", obj:getCode(), obj:makeCategoryLink()) or
		format("%s (<code>%s</code>)", obj:makeCategoryLink(), obj:getCode())
end

local function check_data_keys(...)
	local valid_keys = Array(...):toSet()
	
	return function (modname, obj, data)
		local invalid_keys
		for k in pairs(data) do
			if not valid_keys[k] then
				if not invalid_keys then
					invalid_keys = Array(k)
				else
					invalid_keys:insert(k)
				end
			end
		end
		if invalid_keys == nil then
			return
		end
		local plural = #invalid_keys ~= 1
		discrepancy(modname,
			"The data key%s %s for %s %s invalid.",
			plural and "s" or "",
			invalid_keys:map(function(key)
				return "<code>" .. key .. "</code>"
			end):concat(", "),
			link(obj),
			plural and "are" or "is"
		)
	end
end

-- Modification of isArray in [[Module:table]].
-- This assumes all keys are either integers or non-numbers.
-- If there are fractional numbers, the results might be incorrect.
-- For instance, find_gap{"a", "b", [0.5] = true} evaluates to 3, but there
-- isn't a gap at 3 in the sense of there being an integer key greater than 3.
local function find_gap(t, can_contain_non_number_keys)
	local i = 0
	for k in pairs(t) do
		if not (can_contain_non_number_keys and type(k) ~= "number") then
			i = i + 1
			if t[i] == nil then
				return i
			end
		end
	end
end

local function check_true_or_string_or_nil(modname, obj, data, key)
	local field = data[key]
	if not (field == nil or field == true or type(field) == "string") then
		discrepancy(modname,
			"%s has %s <code>%s</code> value that is not <code>nil</code>, <code>true</code> or a string: <code>%s</code>",
			link(obj), get_indefinite_article(key), key, dump(data[key])
		)
	end
end

local function check_array(modname, obj, data, array_name, parent_array_name, can_contain_non_number_keys)
	local parent_table = data
	if parent_array_name then
		parent_table = assert(data[parent_array_name], parent_array_name)
		parent_array_name = "the <code>" .. parent_array_name .. "</code> field in "
	else
		parent_array_name = ""
	end
	local array_type = type(parent_table[array_name])
	if array_type == "table" then
		local gap = find_gap(parent_table[array_name], can_contain_non_number_keys)
		if gap then
			discrepancy(modname,
				"The <code>%s</code> array in %sthe data table for %s has a gap at index %d.",
				array_name,
				parent_array_name,
				link(obj),
				gap
			)
		else
			return true
		end
	else
		discrepancy(modname,
			"The <code>%s</code> field in %sthe data table for %s should be an array (table) but is %s.",
			array_name,
			parent_array_name,
			link(obj),
			array_type == "nil" and "nil" or "a " .. array_type
		)
	end
end

local function check_no_alias_codes(modname, mod_data)
	local lookup, discrepancies = {}, {}
	for k, v in pairs(mod_data) do
		local check = lookup[v]
		if check then
			discrepancies[check] = discrepancies[check] or {"<code>" .. check .. "</code>"}
			insert(discrepancies[check], "<code>" .. k .. "</code>")
		else
			lookup[v] = k
		end
	end
	for _, v in pairs(discrepancies) do
		discrepancy(modname,
			"The codes %s are currently alias codes. Only one code should be used in the data.",
			list_to_text(v, ", ", " and ")
		)
	end
end

local function check_wikidata_item(modname, obj, data, key)
	local data_item = data[key]
	if data_item == nil or is_positive_integer(data_item) then
		return
	end
	discrepancy(modname,
		"%s has a Wikidata item ID that is not a positive integer: <code>%s</code>",
		link(obj), dump(data_item)
	)
end

local function check_name_field(modname, obj, data, canonical_name, data_key, allow_nested, allow_canonical_name_in_table)
	local array = data[data_key]
	if not array then
		return
	end
	check_array(modname, obj, data, data_key, nil, true)

	local names = {}
	local function check_other_name(other_name)
		if not allow_canonical_name_in_table and other_name == canonical_name then
			discrepancy(modname,
				"%s has its canonical name (<code>%s</code>) repeated in the table of <code>%s</code>.",
				link(obj), dump(canonical_name), data_key
			)
		end
		if names[other_name] then
			discrepancy(modname,
				"The name %s is found twice or more in the list of <code>%s</code> for %s.",
				other_name, data_key, link(obj)
			)
		end
		names[other_name] = true
	end

	for _, other_name in ipairs(array) do
		if type(other_name) == "table" then
			if not allow_nested then
				discrepancy(modname,
					"A nested table is found in the list of <code>%s</code> for %s, but isn't allowed.",
					data_key, link(obj)
				)
			else
				for _, on in ipairs(other_name) do
					check_other_name(on)
				end
			end
		else
			check_other_name(other_name)
		end
	end
end

local function check_other_names_aliases_varieties(modname, obj, data, canonical_name)
	if data.other_names then
		check_name_field(modname, obj, data, canonical_name, "other_names")
	end
	if data.aliases then
		check_name_field(modname, obj, data, canonical_name, "aliases")
	end
	if data.varieties then
		-- Sometimes a variety legitimately has the same name as the language as a whole, so allow that.
		check_name_field(modname, obj, data, canonical_name, "varieties", "allow_nested", "allow_canonical_name_in_table")
	end
end

local function validate_pattern(pattern, modname, obj, standard_chars)
	if type(pattern) ~= "string" then
		return discrepancy(modname,
			"\"%s\", the %spattern for %s, is not a string.",
			pattern, standard_chars and "standard character " or "", link(obj)
		)
	elseif not isutf8(pattern) then
		return discrepancy(modname,
			"%s specifies a pattern for for %scharacter detection which is not valid UTF-8: <code>%s</code>",
			link(obj), standard_chars and "standard " or "", dump(pattern)
		)
	end
	local ranges
	for lower, higher in gmatch(pattern, "(.[\128-\191]*)%-%%?(.[\128-\191]*)") do
		if codepoint(lower) >= codepoint(higher) then
			ranges = ranges or Array()
			insert(ranges, { lower, higher })
		end
	end
	if ranges and ranges[1] then
		local plural = #ranges ~= 1 and "s" or ""
		discrepancy(modname,
			"%s specifies an invalid pattern " ..
			"for %scharacter detection: <code>%s</code>. The first codepoint%s " ..
			"in the range%s %s %s must be less than or equal to the second.",
			link(obj), standard_chars and "standard " or "", dump(pattern), plural, plural,
			ranges:map(function(range)
				return format(range[1] .. "-" .. range[2] .. " (U+%X, U+%X)", codepoint(range[1]), codepoint(range[2]))
			end):concat(", "),
			#ranges ~= 1 and "are" or "is"
		)
	end
	local success, result = pcall(umatch, "", "[" .. pattern .. "]")
	if not success then
		discrepancy(modname,
			"%s specifies an invalid pattern for %scharacter detection: <code>%s</code> (%s)",
			link(obj), standard_chars and "standard " or "", dump(pattern), result
		)
	end
end

local remove_exceptions_addition = 0xF0000
local maximum_code_point = 0x10FFFF
local remove_exceptions_maximum_code_point = maximum_code_point - remove_exceptions_addition

-- TODO: check modules exist.
-- TODO: validate script codes and check inner tables.
local function check_replacement_data(modname, obj, data, key, func_name)
	local replacements = data[key]
	if replacements == nil then
		return
	end
	local replacements_type = type(replacements)
	if replacements_type == "string" then
		local mod = main_loader("Module:" .. replacements)
		if not mod then
			discrepancy(modname,
				"The <code>%s</code> field in the data table for %s specifies the module [[Module:%s]], which does not exist.",
				key, link(obj), replacements
			)
		else
			mod = mod()
			if not (type(mod) == "table" and is_callable(mod[func_name])) then
				discrepancy(modname,
					"The <code>%s</code> field in the data table for %s specifies the module [[Module:%s]], which exists, but does not contain the expected function <code>%s()</code>.",
					key, link(obj), replacements, func_name
				)
			end
		end
		return
	elseif replacements_type ~= "table" then
		discrepancy(modname,
			"The <code>%s</code> field in the data table for %s must be a string or table, not a %s.",
			key, link(obj), replacements_type
		)
		return
	end
	
	local from, to = replacements.from, replacements.to
	if (from ~= nil) ~= (to ~= nil) then
		discrepancy(modname,
			"The <code>from</code> and <code>to</code> arrays in the <code>%s</code> table for %s are not both defined or both undefined.",
			key, link(obj)
		)
	elseif from then
		for _, k in ipairs {"from", "to"} do
			check_array(modname, obj, data, k, key)
		end
	end
	
	local remove_diacritics = replacements.remove_diacritics
	if not (remove_diacritics == nil or type(remove_diacritics) == "string") then
		discrepancy(modname,
			"The <code>remove_diacritics</code> field in the <code>%s</code> table for %s table must be a string.",
			key, link(obj)
		)
	end
	
	local remove_exceptions = replacements.remove_exceptions
	if remove_exceptions then
		if check_array(modname, obj, data, "remove_exceptions", key) then
			for sequence_i, sequence in ipairs(remove_exceptions) do
				local code_point_i = 0
				for code_point in gcodepoint(sequence) do
					code_point_i = code_point_i + 1
					if code_point > remove_exceptions_maximum_code_point then
						discrepancy(modname,
							"Code point #%d (0x%04X) in field #%d of the <code>remove_exceptions</code> array for %s is over U+%04X.",
							code_point_i, code_point, sequence_i, link(obj), remove_exceptions_maximum_code_point
						)
					end
					
				end
			end
		end
	end
	
	if from and to and table_len(to) > table_len(from) then
		discrepancy(modname,
			"The <code>from</code> array in the <code>%s</code> table for %s must be shorter or the same length as the <code>to</code> array.",
			key, link(obj)
		)
	end
end

local function check_replacements_data(modname, obj, data)
	for _, replacement_spec in ipairs{
		{"translit", "tr"},
		{"display_text", "makeDisplayText"},
		{"strip_diacritics", "stripDiacritics"},
		{"sort_key", "makeSortKey"},
	} do
		check_replacement_data(modname, obj, data, unpack(replacement_spec))
	end
end

local function has_ancestor(lang, code)
	for _, anc in ipairs(lang:getAncestors()) do
		if code == anc:getCode() or has_ancestor(anc, code) then
			return true
		end
	end
end

local function get_default_ancestors(lang)
	if lang:hasType("language", "etymology-only") then
		local parent = lang:getParent()
		if not has_ancestor(parent, lang:getCode()) then
			return parent:getAncestorCodes()
		end
	end
	local fam_code, def_anc = lang:getFamilyCode()
	while fam_code and fam_code ~= "qfa-not" do
		local fam = m_families_data[fam_code]
		def_anc = fam.protoLanguage or
			m_languages_data_all[fam_code .. "-pro"] and fam_code .. "-pro" or
			m_etym_languages_data[fam_code .. "-pro"] and fam_code .. "-pro"
		if def_anc and def_anc ~= lang:getCode() then
			return {def_anc}
		end
		fam_code = fam[3]
	end
end

local function iterate_ancestor(obj, modname, anc_code)
	local anc = get_language_by_code(anc_code, nil, true)
	if not anc then
		discrepancy(modname,
			"%s lists the invalid language code <code>%s</code> as its ancestor.",
			link(obj), dump(anc_code)
		)
		return
	end
	local anc_fam = anc:getFamily()
	if not anc_fam then
		discrepancy(modname,
			"%s has no family.",
			link(anc)
		)
		return
	end
	local anc_fam_code = anc_fam:getCode()
	local def_ancs = get_default_ancestors(obj)
	if def_ancs then
		for _, def_anc in ipairs(def_ancs) do
			def_anc = get_language_by_code(def_anc, nil, true)
			if def_anc and (
				anc_code == def_anc:getCode() or
				has_ancestor(def_anc, anc_code) or
				def_anc:hasParent(anc_code) and not has_ancestor(anc, def_anc:getCode())
			) then
				discrepancy(modname,
					"%s has the ancestor %s listed in its ancestor field, which is redundant, since it is determined to be ancestral automatically.",
					link(obj), link(anc)
				)
			end
		end
	end
	if not obj:inFamily(anc_fam_code) then
		discrepancy(modname,
			"%s has %s set as an ancestor, but is not in the %s.",
			link(obj), link(anc), link(anc_fam)
		)
	end
	local fam, proto = obj
	repeat
		fam = fam:getFamily()
		proto = fam and fam:getProtoLanguage()
	until proto or not fam or fam:getCode() == "qfa-not"
	if proto and not (
		proto:getCode() == anc:getCode() or
		proto:hasAncestor(anc:getCode()) or
		anc:hasAncestor(proto:getCode())
	) then
		local fam = obj:getFamily()
		discrepancy(modname,
			"%s is in the %s and has %s set as an ancestor, but it is not possible to form an ancestral chain between them.",
			link(obj), link(fam), link(anc)
		)
	end
end

local function check_ancestors(modname, obj, data)
	local ancestors = data.ancestors
	if ancestors == nil then
		return
	end
	local ancestors_type = type(ancestors)
	if ancestors_type == "string" then
		ancestors = split(ancestors, ",", true, true)
	elseif ancestors_type ~= "table" then
		discrepancy(modname,
			"The <code>ancestors</code> field in the data table for %s must be a string or table, not a %s.",
			link(obj), ancestors_type
		)
	end
	for _, anc in ipairs(ancestors) do
		iterate_ancestor(obj, modname, anc)
	end
end

local function check_wikimedia_codes(modname, obj, data)
	local wikimedia_codes = data.wikimedia_codes
	if wikimedia_codes == nil then
		return
	end
	local wikimedia_codes_type = type(wikimedia_codes)
	if wikimedia_codes_type == "string" then
		wikimedia_codes = split(wikimedia_codes, ",", true, true)
	elseif wikimedia_codes_type ~= "table" then
		discrepancy(modname,
			"The <code>wikimedia_codes</code> field in the data table for %s must be a string or table, not a %s.",
			link(obj), wikimedia_codes_type
		)
	end
	for _, code in ipairs(wikimedia_codes) do
		if not is_known_language_tag(code) then
			discrepancy(modname,
				"%s lists the invalid Wikimedia code <code>%s</code> in the <code>wikimedia_codes</code> field.",
				link(obj), dump(code)
			)
		end
	end
end
	
local function check_code_to_name_and_name_to_code_maps(
		source_module_type,
		source_module_description,
		code_to_module_map, name_to_code_map,
		code_to_name_modname, code_to_name_module,
		name_to_code_modname, name_to_code_module
)
	
	local function check_code_and_name(modname, code, canonical_name)
		-- Check the code is in code_to_module_map and that it didn't originate from the wrong data module.
		local check_mod = code_to_module_map[code] or code_to_module_map[aliases[code]]
		if not (check_mod and match(check_mod, "^" .. source_module_type .. "/data")) then
			if not name_to_code_map[canonical_name] then
				discrepancy(modname,
					"The code <code>%s</code> and the canonical name %s should be removed; they are not found in %s.",
					code, canonical_name, source_module_description
				)
			else
				discrepancy(modname,
					"<code>%s</code>, the code for the canonical name %s, is wrong; it should be <code>%s</code>.",
					code, canonical_name, name_to_code_map[canonical_name]
				)
			end
		elseif not name_to_code_map[canonical_name] then
			local data_table = require("Module:" .. code_to_module_map[code])[code]
			discrepancy(modname,
				"%s, the canonical name for the code <code>%s</code>, is wrong; it should be %s.",
				canonical_name, code, data_table[1]
			)
		end
	end

	for code, canonical_name in pairs(code_to_name_module) do
		check_code_and_name(code_to_name_modname, code, canonical_name)
	end
	
	for canonical_name, code in pairs(name_to_code_module) do
		check_code_and_name(name_to_code_modname, code, canonical_name)
	end
end

local function check_extraneous_extra_data(
		data_modname, data_module, extra_data_modname, extra_data_module)
	for code, _ in pairs(extra_data_module) do
		if not data_module[code] then
			discrepancy(extra_data_modname,
				"The code <code>%s</code> is not found in [[Module:%s]], and should be removed from [[Module:%s]].",
				code, data_modname, extra_data_modname
			)
		end
	end
end

-- TODO: add collision check between the canonical names "X" and "X [Ll]anguage".
local function check_languages(frame)
	local check_language_data_keys = check_data_keys(
		1, 2, 3, 4, -- canonical name, Wikidata item, family, scripts
		"display_text", "generate_forms", "strip_diacritics", "sort_key",
		"other_names", "aliases", "varieties", "ietf_subtag",
		"type", "ancestors", "pseudo_families",
		"wikimedia_codes", "wikipedia_article", "standard_chars",
		"translit", "override_translit", "link_tr",
		"dotted_dotless_i"
	)
	
	local function check_language(modname, code, data, extra_modname, extra_data)
		local obj, code_modname, canonical_name = make_lang(code, data, true), get_data_module_name(code), data[1]
		-- FIXME: this module should use the prefixed module name throughout.
		code_modname = code_modname:gsub("^Module:", "")
		
		if code_modname ~= modname then
			if code_modname == "languages/data/2" then
				discrepancy(modname,
					"%s is a two-letter code, so should be moved to [[Module:%s]].",
					link(obj), code_modname
				)
			elseif code_modname == "languages/data/exceptional" then
				discrepancy(modname,
					"%s is an exceptional code, as it does not consist of two or three lowercase letters, so should be moved to [[Module:%s]].",
					link(obj), code_modname
				)
			else
				discrepancy(modname,
					"%s is a three-letter code beginning with '%s', so should be moved to [[Module:%s]].",
					link(obj), sub(code, 1, 1), code_modname
				)
			end
		end
		
		check_language_data_keys(modname, obj, data)
		
		if all_codes[code] then
			discrepancy(modname,
				"The code <code>%s</code> is not unique; it is also defined in [[Module:%s]].",
				code, all_codes[code]
			)
		else
			if not m_languages_codes[code] then
				discrepancy("languages/code to canonical name",
					"The code %s is missing.",
					link(obj, true)
				)
			end
			all_codes[code] = modname
		end
		
		-- TODO: these checks should be consolidated with the proto-language checks in the family data,
		-- since bad settings there affect the warnings here (e.g. xxx-pro assigned to yyy when xxx also
		-- doesn't not exist - a warning that xxx has "no family" would be misleading).
		if sub(code, -4) == "-pro" then
			local fam_code = sub(code, 1, -5)
			local fam = get_language_by_code(fam_code, nil, true, true)
			if not fam then
				discrepancy(modname,
					"'''Proto-language with no family''': %s should be the proto-language of <code>%s</code>, which doesn't exist.",
					link(obj), dump(fam_code)
				)
			elseif not fam:hasType("family") then
				discrepancy(modname,
					"'''Proto-language with no family''': %s should be the proto-language of <code>%s</code>, but %s is not a family.",
					link(obj), dump(fam_code), link(fam)
				)
			else
				-- Reinstate this as low-priority once message priorities have been implemented.
--				local expected_name = "Proto-" .. fam:getCanonicalName()
--				if canonical_name ~= expected_name then
--					discrepancy(modname,
--						"%s does not have the expected name \"%s\", even though it is the proto-language of the %s.",
--						link(obj), expected_name, link(fam)
--					)
--				end
			end
		end
		
		if not canonical_name then
			discrepancy(modname,
				"The code <code>%s</code> has no canonical name specified.",
				code
			)
		elseif language_names[canonical_name] then
			local canonical_lang = get_language_by_canonical_name(canonical_name)
			if not canonical_lang then
				discrepancy(modname,
					"%s has a canonical name that cannot be looked up.",
					link(obj)
				)
			elseif data.main_code ~= canonical_lang:getCode() then
				discrepancy(modname,
					"%s has a canonical name that is not unique; it is also used by the code <code>%s</code>.",
					link(obj), language_names[canonical_name]
				)
			end
		else
			if not m_languages_canonical_names[canonical_name] then
				discrepancy("languages/canonical names",
					"The canonical name %s is missing.",
					link(obj)
				)
			end
			language_names[canonical_name] = code
		end
		
		check_wikidata_item(modname, obj, data, 2)

		if extra_data then
			check_other_names_aliases_varieties(modname, obj, extra_data, canonical_name)
		end
		
		local lang_type = data.type
		if lang_type and not (lang_type == "regular" or lang_type == "reconstructed" or lang_type == "appendix-constructed") then
			discrepancy(modname,
				"%s is of the invalid type <code>%s</code>.",
				link(obj), lang_type
			)
		end
		
		if data.aliases then
			discrepancy(modname,
				"%s has an <code>aliases</code> key in [[Module:%s]]. This must be moved to [[Module:%s]].",
				link(obj), modname, extra_modname
			)
		end
		
		if data.varieties then
			discrepancy(modname,
				"%s has the <code>varieties</code> key in [[Module:%s]]. This must be moved to [[Module:%s]].",
				link(obj), modname, extra_modname
			)
		end
		
		if data.other_names then
			discrepancy(modname,
				"%s has the <code>other_names</code> key in [[Module:%s]]. This must be moved to [[Module:%s]].",
				link(obj), modname, extra_modname
			)
		end
		
		if not extra_data then
			discrepancy(extra_modname,
				"%s has data in [[Module:%s]], but does not have corresponding data in [[Module:%s]].",
				link(obj), modname, extra_modname
			)
		--[[elseif extra_data.other_names then
			discrepancy(extra_modname,
				"%s has <code>other_names</code> key, but these should be changed to either <code>aliases</code> or <code>varieties</code>.",
				link(obj)
			)]]
		end
		
		local sc = data[4]
		if sc then
			if type(sc) == "string" then
				sc = split(sc, "%s*,%s*", true)
			end
			if type(sc) == "table" then
				if not sc[1] then
					discrepancy(modname,
						"%s has no scripts listed.",
						link(obj)
					)
				else
					for _, sccode in ipairs(sc) do
						local cur_sc = m_scripts_data[sccode]
						if not (cur_sc or sccode == "All" or sccode == "Hants") then
							discrepancy(modname,
								"%s lists the invalid script code <code>%s</code>.",
								link(obj), dump(sccode)
							)
						--[[elseif not cur_sc.characters then
							discrepancy(modname,
								"%s lists the %s, which does not have any characters.",
								link(obj), link(get_script_by_code(sccode))
							)]]
						end
			
						nonempty_scripts[sccode] = true
					end
				end
			else
				discrepancy(modname,
					"The %s field for %s must be a table or string.",
					4, link(obj)
				)
			end
		end
		
		if data.ancestors then
			check_ancestors(modname, obj, data)
		end
		
		if data.wikimedia_codes then
			check_wikimedia_codes(modname, obj, data)
		end
		
		if data[3] then
			local family = data[3]
			if not m_families_data[family] then
				discrepancy(modname,
					"%s has the invalid family code <code>%s</code>.",
					link(obj), dump(family)
				)
			end
			nonempty_families[family] = true
		end
		
		check_replacements_data(modname, obj, data)

		if data.standard_chars then
			if type(data.standard_chars) == "table" then
				local sccodes = {}
				for _, sccode in ipairs(sc) do
					sccodes[sccode] = true
				end
				for sccode in pairs(data.standard_chars) do
					if not (sccodes[sccode] or sccode == 1) then
						discrepancy(modname,
							"The field %s in the <code>standard_chars</code> table for %s does not match any script for that language.",
							sccode, link(obj)
						)
					end
				end
			elseif data.standard_chars and type(data.standard_chars) ~= "string" then
				discrepancy(modname,
					"The <code>standard_chars</code> field in the data table for %s must be a string or table.",
					link(obj)
				)
			end
		end
		
		check_true_or_string_or_nil(modname, obj, data, "override_translit")
		check_true_or_string_or_nil(modname, obj, data, "link_tr")

		-- This doesn't apply any more since scripts can be script-wide translit methods.		
		-- if data.override_translit and not data.translit then
		-- 	discrepancy(modname,
		-- 		"%s has the <code>override_translit</code> field set, but no transliteration module",
		-- 		link(obj)
		-- 	)
		-- end
	end
	
	local function check_module(modname)
		local mod_data = load_data("Module:" .. modname)
		local extra_modname = modname .. "/extra"
		local extra_mod_data = load_data("Module:" .. extra_modname)
		for code, data in pairs(mod_data) do
			check_language(modname, code, data, extra_modname, extra_mod_data[code])
		end
		check_no_alias_codes(modname, mod_data)
		check_no_alias_codes(extra_modname, extra_mod_data)
		check_extraneous_extra_data(modname, mod_data, extra_modname, extra_mod_data)
	end
	
	-- Check two-letter codes
	check_module(
		"languages/data/2"
	)
	
	-- Check three-letter codes
	for i = 0x61, 0x7A do -- a to z
		check_module(
			format("languages/data/3/%c", i)
		)
	end
	
	-- Check exceptional codes
	check_module(
		"languages/data/exceptional"
	)
	
	-- These checks must be done while all_codes only contains language codes:
	-- that is, after language data modules have been processed, but before
	-- etymology languages, families, and scripts have.
	check_code_to_name_and_name_to_code_maps(
		"languages",
		"a submodule of [[Module:languages]]",
		all_codes, language_names,
		"languages/code to canonical name", m_languages_codes,
		"languages/canonical names", m_languages_canonical_names
	)
	
	-- Check [[Template:langname-lite]]
	local modname = "Template:langname-lite"
	for code, name in gmatch(remove_comments(new_title(modname):getContent()), "\n\t*|#*([^\n]+)=([^\n]*)") do
		if #code > 1 and code ~= "default" then
			for _, code in pairs(split(code, "|", true)) do
				local lang = get_language_by_code(code, nil, true, true)
				if match(name, "etymcode") then
					local nonEtym_name = frame:preprocess(name)
					local nonEtym_real_name = lang:getFullName()
					if nonEtym_name ~= nonEtym_real_name then
						discrepancy(modname,
							"Code: <code>%s</code>. Saw name: %s. Expected name: %s.",
							code, nonEtym_name, nonEtym_real_name
						)
					end
					name = frame:preprocess(gsub(name, "{{{allow etym|}}}", "1"))
				elseif match(name, "familycode") then
					name = match(name, "familycode|(.-)|")
				else
					name = name
				end
				if not lang then
					discrepancy(modname,
						"Code: <code>%s</code>. Saw name: %s. Language not present in data.",
						code, name
					)
				else
					local real_name = lang:getCanonicalName()
					if name ~= real_name then
						discrepancy(modname,
							"Code: <code>%s</code>. Saw name: %s. Expected name: %s.",
							code, name, real_name
						)
					end
				end
			end
		end
	end
end

local function check_etym_languages()
	local modname = "etymology languages/data"
	
	local check_etymology_language_data_keys = check_data_keys(
		1, 2, 3, 4, -- canonical name, Wikidata item, family, scripts
		"parent", "display_text", "generate_forms", "strip_diacritics", "sort_key",
		"other_names", "aliases", "varieties", "ietf_subtag",
		"type", "main_code", "ancestors", "pseudo_families",
		"wikimedia_codes", "wikipedia_article", "standard_chars",
		"translit", "override_translit", "link_tr",
		"dotted_dotless_i"
	)
	
	local checked = {}
	for code, data in pairs(m_etym_languages_data) do
		local obj, canonical_name, parent = make_lang(code, data, true), data[1], data.parent
		
		check_etymology_language_data_keys(modname, obj, data)
		
		if all_codes[code] then
			discrepancy(modname,
				"The code <code>%s</code> is not unique; it is also defined in [[Module:%s]].",
				code, all_codes[code]
			)
		else
			if not m_etym_languages_codes[code] then
				discrepancy("etymology languages/code to canonical name",
					"The code %s is missing.",
					link(obj, true)
				)
			end
			all_codes[code] = modname
		end
		
		if not canonical_name then
			discrepancy(modname,
				"The code <code>%s</code> has no canonical name specified.",
				code
			)
		elseif language_names[canonical_name] then
			local canonical_lang = get_language_by_canonical_name(canonical_name, nil, true)
			if not canonical_lang then
				discrepancy(modname,
					"%s has a canonical name that cannot be looked up.",
					link(obj)
				)
			elseif data.main_code ~= canonical_lang:getCode() then
				discrepancy(modname,
					"%s has a canonical name that is not unique; it is also used by the code <code>%s</code>.",
					link(obj), language_names[canonical_name]
				)
			end
		else
			if not m_etym_languages_canonical_names[canonical_name] then
				discrepancy("etymology languages/canonical names",
					"The canonical name %s is missing.",
					link(obj)
				)
			end
			etym_language_names[canonical_name] = code
		end
		
		check_other_names_aliases_varieties(modname, obj, data, canonical_name)
		
		if parent then
			if type(parent) ~= "string" then
				discrepancy(modname,
					"%s has a parent code that is %s rather than a string.",
					link(obj), parent == nil and "nil" or "a " .. type(parent)
				)
			elseif not (m_languages_data_all[parent] or m_etym_languages_data[parent]) then
				discrepancy(modname,
					"%s has the invalid parent code <code>%s</code>%s.",
					link(obj), dump(parent), m_families_data[parent] and " (a family code)" or ""
				)
			end
			nonempty_families[parent] = true
		else
			discrepancy(modname,
				"%s has no parent code.",
				link(obj)
			)
		end
		
		if data.ancestors then
			check_ancestors(modname, obj, data)
		end
		
		if data.wikimedia_codes then
			check_wikimedia_codes(modname, obj, data)
		end
		
		if data[3] then
			local family = data[3]
			if not m_families_data[family] then
				discrepancy(modname,
					"%s has the invalid family code <code>%s</code>.",
					link(obj), dump(family))
			end
			nonempty_families[family] = true
		end
		
		check_replacements_data(modname, obj, data)
		
		check_wikidata_item(modname, obj, data, 2)
		
		local stack = {}
		while data do
			if checked[code] then
				break	
			elseif stack[code] then
				local parent = data.parent
				discrepancy(modname,
					"%s has a cyclic parental relationship to %s",
					link(make_lang(code, data, true)),
					link(get_language_by_code(parent, nil, true))
				)
				break
			end
			stack[code] = true
			code = data.parent
			data = m_etym_languages_data[code]
		end
		
		for code in pairs(stack) do
			checked[code] = true	
		end
	end
	
	check_no_alias_codes(modname, m_etym_languages_data)
	
	check_code_to_name_and_name_to_code_maps(
		"etymology languages",
		"[[Module:etymology languages/data]]",
		all_codes, etym_language_names,
		"etymology languages/code to canonical name", m_etym_languages_codes,
		"etymology languages/canonical names", m_etym_languages_canonical_names)
end

-- TODO: add collision check between the canonical names "X" and "X [Ll]anguages".
local function check_families()
	local modname = "families/data"
	
	local check_family_data_keys = check_data_keys(
		1, 2, 3, -- canonical name, Wikidata item, (parent) family
		"type", "ietf_subtag",
		"protoLanguage", "other_names", "aliases", "varieties", "pseudo_families", "categoryName"
	)
	
	local checked, double_check_if_empty = {["qfa-not"] = true}, {}
	for code, data in pairs(m_families_data) do
		local obj, canonical_name, family, protolang = make_family(code, data), data[1], data[3], data.protoLanguage
		
		check_family_data_keys(modname, obj, data)
		
		if all_codes[code] then
			discrepancy(modname,
				"The code <code>%s</code> is not unique; it is also defined in [[Module:%s]].",
				code, all_codes[code]
			)
		else
			if not m_families_codes[code] then
				discrepancy("families/code to canonical name",
					"The code %s is missing.",
					link(obj, true)
				)
			end
			all_codes[code] = modname
		end
		
		if not canonical_name then
			discrepancy(modname,
				"The code <code>%s</code> has no canonical name specified.",
				code
			)
		elseif family_names[canonical_name] then
			local canonical_family = get_family_by_canonical_name(canonical_name)
			if not canonical_family then
				discrepancy(modname,
					"%s has a canonical name that cannot be looked up.",
					link(obj)
				)
			elseif data.main_code ~= canonical_family:getCode() then
				discrepancy(modname,
					"%s has a canonical name that is not unique; it is also used by the code <code>%s</code>.",
					link(obj), family_names[canonical_name]
				)
			end
		else
			if not m_families_canonical_names[canonical_name] then
				discrepancy("families/canonical names",
					"The canonical name %s is missing.",
					link(obj)
				)
			end
			family_names[canonical_name] = code
		end
		
		check_other_names_aliases_varieties(modname, obj, data, canonical_name)
		
		if family then
			if family == code and code ~= "qfa-not" then
				discrepancy(modname,
					"%s has itself as its family.",
					link(obj)
				)
			elseif not m_families_data[family] then
				discrepancy(modname,
					"%s has the invalid parent family code <code>%s</code>.",
					link(obj), dump(family)
				)
			end
			nonempty_families[family] = true
		end
		
		if protolang then
			local protolang_obj = get_language_by_code(protolang, nil, true)
			if not protolang_obj then
				discrepancy(modname,
					"%s has the invalid proto-language code <code>%s</code>.",
					link(obj), dump(protolang)
				)
			elseif protolang == code .. "-pro" then
				discrepancy(modname,
					"%s has %s listed as its proto-language, which is redundant, since it is determined to be the proto-language automatically.",
					link(obj), link(protolang_obj)
				)
			elseif sub(protolang, -4) == "-pro" then
				discrepancy(modname,
					"%s has %s listed as its proto-language, which is supposed to be the proto-language for the family <code>%s</code>.", link(obj), link(protolang_obj), sub(protolang, 1, -5)
				)
			end
		end
		
		check_wikidata_item(modname, obj, data, 2)
		
		-- Could be a false-positive if a child family occurs on a later
		-- iteration, so set aside any that fail for a second check. This avoids
		-- having to iterate through the whole list of families once
		-- nonempty_families has been fully populated.
		if not (nonempty_families[code] or allowed_empty_families[code]) then
			double_check_if_empty[code] = obj
		end
		
		local stack = {}
		while data do
			if checked[code] then
				break	
			elseif stack[code] then
				local parent = data[3]
				discrepancy(modname,
					"%s has a cyclic familial relationship to %s",
					link(make_family(code, data)),
					link(get_family_by_code(parent))
				)
				break
			end
			stack[code] = true
			code = data[3]
			data = m_families_data[code]
		end
		
		for code in pairs(stack) do
			checked[code] = true	
		end
	end
	
	-- Any languages set aside as candidates for having no children are checked
	-- again, now that nonempty_families is definitely complete.
	for code, obj in next, double_check_if_empty do
		if not (nonempty_families[code] or allowed_empty_families[code]) then
			discrepancy(modname,
				"%s has no child families or languages.",
				link(obj)
			)
		end
	end
	
	check_no_alias_codes(modname, m_families_data)
	
	check_code_to_name_and_name_to_code_maps(
		"families",
		"[[Module:families/data]]",
		all_codes, family_names,
		"families/code to canonical name", m_families_codes,
		"families/canonical names", m_families_canonical_names)
end

-- TODO: add collision check between the canonical names "X" and "X [Ss]cript".
local function check_scripts()
	local modname = "scripts/data"
	
	local check_script_data_keys = check_data_keys(
		1, 2, 3, -- canonical name, Wikidata item, writing systems
		"other_names", "aliases", "varieties", "parent", "ietf_subtag", "type",
		"wikipedia_article", "ranges", "characters", "spaces", "capitalized", "translit", "direction",
		"character_category", "normalizationFixes", "sort_by_scraping",
		"display_text", "sort_key", "strip_diacritics"
	)
	
	-- Just to satisfy requirements of check_code_to_name_and_name_to_code_maps.
	local script_code_to_module_map = {}
	
	for code, data in pairs(m_scripts_data) do
		local obj, canonical_name = make_script(code, data), data[1]
		
		if not m_scripts_codes[code] and #code == 4 then
			discrepancy("scripts/code to canonical name",
				"The code %s is missing",
				link(obj, true)
			)
		end
		
		check_script_data_keys(modname, obj, data)
		
		if not canonical_name then
			discrepancy(modname,
				"The code <code>%s</code> has no canonical name specified.",
				code
			)
		elseif script_names[canonical_name] then
			local canonical_script = get_script_by_canonical_name(canonical_name)
			if not canonical_script then
				discrepancy(modname,
					"%s has a canonical name that cannot be looked up.",
					link(obj)
				)
			--[[elseif data.main_code ~= canonical_script:getCode() then
				discrepancy(modname,
					"%s has a canonical name that is not unique; it is also used by the code <code>%s</code>.",
					link(obj), script_names[canonical_name]
				)]]
			end
		else
			if not m_scripts_canonical_names[canonical_name] and #code == 4 then
				discrepancy("scripts/canonical names",
					"The canonical name %s is missing.",
					link(obj)
				)
			end
			script_names[canonical_name] = code
		end
		
		check_other_names_aliases_varieties(modname, obj, data, canonical_name)
		
		if not nonempty_scripts[code] then
			discrepancy(modname,
				"%s is not used by any language%s.",
				link(obj), data.characters and ""
					or " and has no characters listed for auto-detection")
		
		--[[elseif not data.characters then
			discrepancy(modname,
				"%s has no characters listed for auto-detection.",
				link(obj)
			)--]]
		end

		if data.characters then
			validate_pattern(data.characters, modname, obj, false)
		end
		
		check_wikidata_item(modname, obj, data, 2)
		
		script_code_to_module_map[code] = modname
	end
	
	check_no_alias_codes(modname, m_scripts_data)
	
	check_code_to_name_and_name_to_code_maps(
		"scripts",
		"a submodule of [[Module:scripts]]",
		script_code_to_module_map, script_names,
		"scripts/code to canonical name", m_scripts_codes,
		"scripts/canonical names", m_scripts_canonical_names)
end

-- FIXME: this is quite messy.
local function check_wikidata_languages()
	local data = json_decode(new_title("Module:languages/data/wikidata.json"):getContent())
	
	local seen = {{}, {}, {}, [5] = {}}
	for _, item in ipairs(data) do
		local id = item.id
		for k, v in pairs(item) do
			if k ~= "id" then
				local _seen = seen[k]
				for _, code in ipairs(v) do
					local _code = code[1]
					local _type = type(_seen[_code])
					if _type == "table" then
						insert(_seen[_code], id)
					elseif _type == "string" then
						_seen[_code] = {_seen[_code], id}
					else
						_seen[_code] = id
					end
				end
			end
		end
	end
	
	local modname = "languages/data/wikidata.json"
	for k, v in pairs(seen) do
		for code, ids in pairs(v) do
			if type(ids) == "table" then
				local t = {}
				for i, id in ipairs(ids) do
					t[i] = format("<code>[[d:%s|%s]]</code>", id, id)
				end
				discrepancy(modname,
					"<code>%s</code> is set as an ISO 639-%d code on multiple items: %s.",
					code, k, list_to_text(t)
				)
				
			end
		end
	end
end

local function check_labels()
	local check_label_data_keys = check_data_keys(
		"display", "Wikipedia", "glossary",
		"plain_categories", "topical_categories", "pos_categories", "regional_categories", "sense_categories",
		"omit_preComma", "omit_postComma", "omit_preSpace",
		"deprecated", "track"
	)
	
	local function check_label(modname, code, data)
		local _type = type(data)
		if _type == "table" then
			check_label_data_keys(modname, code, data)
		elseif _type ~= "string" then
			discrepancy(modname,
				"The data for the label <code>%s</code> is %s %s; only tables and strings are allowed.",
				code, add_indefinite_article(_type)
			)
		end
	end
	
	for _, module in ipairs{"", "/regional", "/topical"} do
		local modname = "Module:labels/data" .. module
		module = require(modname)
		for label, data in pairs(module) do
			check_label(modname, label, data)
		end
	end
	
	for code in pairs(m_languages_codes) do
		local modname = "Module:labels/data/lang/" .. code
		local module = safe_require(modname)
		if module then
			for label, data in pairs(module) do
				check_label(modname, label, data)
			end
		end
	end
end

local function check_zh_trad_simp()
	local m_ts = require("Module:zh/data/ts")
	local m_st = require("Module:zh/data/st")
	local ruby = require("Module:ja-ruby").ruby_auto
	local lang = get_language_by_code("zh")
	local Hant = get_script_by_code("Hant")
	local Hans = get_script_by_code("Hans")
	
	local data = {[0] = m_st, m_ts}
	local mod = {[0] = "st", "ts"}
	local var = {[0] = "Simp.", "Trad."}
	local sc = {[0] = Hans, Hant}
	
	local function find_stable_loop(chars, other, j)
		local display = ruby({["markup"] = "[" .. other .. "](" .. var[(j+1)%2] .. ")"})
		display = language_link{term = other, alt = display, lang = lang, sc = sc[(j+1)%2], tr = "-"}
		insert(chars, display)
		if data[(j+1)%2][other] == other then
			insert(chars, other)
			return chars, 1
		elseif not data[(j+1)%2][other] then
			insert(chars, "not found")
			return chars, 2
		elseif data[j%2][data[(j+1)%2][other]] ~= other then
			return find_stable_loop(chars, data[(j+1)%2][other], j + 1)
		else
			local display = ruby({["markup"] = "[" .. data[(j+1)%2][other] .. "](" .. var[j%2] .. ")"})
			display = language_link{term = data[(j+1)%2][other], alt = display, lang = lang, sc = sc[j%2], tr = "-"}
			insert(chars, display .. " (")
			display = ruby({["markup"] = "[" .. data[j%2][data[(j+1)%2][other]] .. "](" .. var[(j+1)%2] .. ")"})
			display = language_link{term = data[j%2][data[(j+1)%2][other]], alt = display, lang = lang, sc = sc[(j+1)%2], tr = "-"}
			insert(chars, display .. " etc.)")
			return chars, 3
		end
		
		return chars
	end
	
	for i = 0, 1, 1 do
		for ch, other_ch in pairs(data[i]) do
			if data[(i+1)%2][other_ch] ~= ch then
				local chars, issue = {}
				local display = ruby({["markup"] = "[" .. ch .. "](" .. var[i] .. ")"})
				display = language_link{term = ch, alt = display, lang = lang, sc = sc[i], tr = "-"}
				insert(chars, display)
				chars, issue = find_stable_loop(chars, other_ch, i)
				if issue == 1 or issue == 2 then
					local sc_this, mod_this, j = {}
					if match(chars[#chars-1], var[(i+1)%2]) then
						j = 1
					else
						j = 0
					end
					mod_this = mod[(i+j)%2]
					sc_this = {[0] = sc[(i+j)%2], sc[(i+j+1)%2]}
					for k, ch in ipairs(chars) do
						chars[k] = tag_text(ch, lang, sc_this[k%2], "term")
					end
					local modname = "zh/data/" .. mod_this
					if issue == 1 then
						discrepancy(modname,
							"character references itself: %s",
							concat(chars, " → ")
						)
					elseif issue == 2 then
						discrepancy(modname,
							"missing character: %s",
							concat(chars, " → ")
						)
					end
				elseif issue == 3 then
					for j, ch in ipairs(chars) do
						chars[j] = tag_text(ch, lang, sc[(i+j)%2], "term")
					end
					discrepancy("zh/data/" .. mod[i],
						"possible mismatched character: %s",
						concat(chars, " → ")
					)
				end
			end
		end
	end
end

local function check_serialization(modname)
	local serializers = {
		["Hani-sortkey/data/serialized"] = "Hani-sortkey/serializer",
	}
	
	if not serializers[modname] then
		return nil
	end
	
	local serializer = serializers[modname]
	local current_data = require("Module:" .. serializer).main(true)
	local stored_data = require("Module:" .. modname)
	if current_data ~= stored_data then
		discrepancy(modname,
			"<strong><u>Important!</u> Serialized data is out of sync. Use [[Module:%s]] to update it. If you have made any changes to the underlying data, the serialized data <u>must</u> be updated before these changes will take effect.</strong>",
			serializer
		)
	end
end

local find_code = require("Module:memoize")(function(message)
	return match(message, "<code>([^<]+)</code>")
end)

local function compare_messages(message1, message2)
	local code1, code2 = find_code(message1), find_code(message2)
	if code1 and code2 then
		return code1 < code2
	else
		return message1 < message2
	end
end

-- Warning: cannot be called twice in the same module invocation because
-- some module-global variables are not reset between calls.
local function do_checks(frame, modules)
	messages = setmetatable({}, messages_mt)
	
	if modules["zh/data/ts"] or modules["zh/data/st"] then
		check_zh_trad_simp()
	end
	check_languages(frame)
	check_etym_languages()

	-- families and scripts must be checked AFTER languages; languages checks fill out
	-- the nonempty_families and nonempty_scripts tables, used for testing if a family/script
	-- is ever used in the data
	check_families()
	check_scripts()
	
	check_wikidata_languages()
	
	if modules["labels/data"] then
		check_labels()
	end
	
	for module in pairs(modules) do
		check_serialization(module)
	end
	
	setmetatable(messages, nil)
	
	for _, msglist in pairs(messages) do
		msglist:sort(compare_messages)
	end
	
	local ret = messages
	messages = nil
	return ret
end

local function format_message(modname, msglist)
	local header; if match(modname, "^Module:") or match(modname, "^Template:") then
		header = "===[[" .. modname .. "]]==="
	else
		header = "===[[Module:" .. modname .. "]]==="
	end
	return header .. msglist:map(function(msg)
		return "\n* " .. msg
	end):concat()
end

function export.check_modules_t(frame)
	local args = frame.args
	
	local modules = list_to_set(args)
	local ret = Array()
	local messages = do_checks(frame, modules)
	
	for _, module in ipairs(args) do
		local msglist = messages[module]
		if msglist then
			ret:insert(format_message(module, msglist))
		end
	end
	return ret:concat("\n")
end

function export.perform(frame)
	local messages = do_checks(frame, {})
	
	-- Format the messages
	local ret = Array()
	for modname, msglist in sorted_pairs(messages) do
		ret:insert(format_message(modname, msglist))
	end
	
	-- Are there any messages?
	-- TODO: check how many messages there are.
	if false then --if i == 1 then
		return "<b class=\"success\">Glory to Arstotzka.</b>"
	else
		ret:insert(1, "<b class=\"warning\">Discrepancies detected:</b>")
		return ret:concat("\n")
	end
end

return export
