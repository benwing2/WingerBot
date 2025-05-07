local raw_handlers = {}


--[=[
This module implements the topic category subsystem. It is currently implemented with a single raw handler that
handlers both language-specific and umbrella topic categories. The topmost category [[:Category:All topics]] is special
and potentially could be handled as a separate raw category, but currently it's handled as part of the raw handler.
]=]

local functions_module = "Module:fun"
local labels_utilities_module = "Module:labels/utilities"
local languages_module = "Module:languages"
local patterns_module = "Module:patterns"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

local topic_data_module = "Module:User:Benwing2/category tree/topic/data"
local topic_utilities_module = "Module:category tree/topic/utilities"
local thesaurus_data_module = "Module:User:Benwing2/category tree/topic/thesaurus"

local m_patterns = require(patterns_module)

local concat = table.concat
local insert = table.insert
local dump = mw.dumpObject
local is_callable = require(functions_module).is_callable
local pattern_escape = m_patterns.pattern_escape
local replacement_escape = m_patterns.replacement_escape
local split = require(string_utilities_module).split

local type_data = {
	["related-to"] = {
		desc = "terms related to",
		additional = "'''NOTE''': This is a \"related-to\" category. It should contain terms directly related to " ..
		"{{{topic}}}. Please do not include terms that merely have a tangential connection to {{{topic}}}. " ..
		"Be aware that terms for types or instances of this topic often go in a separate category.",
	},
	set = {
		desc = "terms for types or instances of",
		additional = "'''NOTE''': This is a set category. It should contain terms for {{{topic}}}, not merely " ..
		"terms related to {{{topic}}}. It may contain more general terms (e.g. types of {{{topic}}}) or more " ..
		"specific terms (e.g. names of specific {{{topic}}}), although there may be related categories "..
		"specifically for these types of terms.",
	},
	name = {
		desc = "names of specific",
		additional = "'''NOTE''': This is a name category. It should contain names of specific {{{topic}}}, not " ..
		"merely terms related to {{{topic}}}, and should also not contain general terms for types of {{{topic}}}.",
	},
	type = {
		desc = "terms for types of",
		additional = "'''NOTE''': This is a type category. It should contain terms for types of {{{topic}}}, not " ..
		"merely terms related to {{{topic}}}, and should also not contain names of specific {{{topic}}}.",
	},
	grouping = {
		desc = "categories concerning more specific variants of",
		additional = "'''NOTE''': This is a grouping category. It should not directly contain any terms, but " ..
		"only subcategories. If there are any terms directly in this category, please move them to a subcategory.",
	},
	toplevel = {
		desc = "UNUSED", -- all categories of this type hardcode their description
		additional = "'''NOTE''': This is a top-level list category. It should not directly contain any terms, but " ..
		"only a {{{topic}}}.",
	},
}


local function invalid_type(types)
	local valid_types = {}
	for typ, _ in pairs(type_data) do
		insert(valid_types, ("'%s'"):format(typ))
	end
	error(("Invalid type '%s', should be one or more of %s, comma-separated")
		:format(types, mw.text.listToText(valid_types)))
end


local function split_types(types)
	types = types or "related-to"
	local splitvals = split(types, "%s*,%s*")
	for i, typ in ipairs(splitvals) do
		-- FIXME: Temporary
		if typ == "topic" then
			typ = "related-to"
		end
		if not type_data[typ] then
			invalid_type(types)
		end
		splitvals[i] = typ
	end
	return splitvals
end


local function gsub_escaping_replacement(str, from, to)
	return (str:gsub(pattern_escape(from), replacement_escape(to)))
end


function ucfirst(txt)
	local italics, raw_txt = txt:match("^('*)(.-)$")
	return italics .. mw.getContentLanguage():ucfirst(raw_txt)
end


function lcfirst(txt)
	local italics, raw_txt = txt:match("^('*)(.-)$")
	return italics .. mw.getContentLanguage():lcfirst(raw_txt)
end


local function convert_spec_to_string(data, desc)
	if not desc then
		return desc
	end
	local desc_type = type(desc)
	if desc_type == "string" then
		return desc
	elseif desc_type == "number" then
		return tostring(desc)
	elseif not is_callable(desc) then
		error("Internal error: `desc` must be a string, number, function, callable table or nil; received a " ..
			desc_type)
	end
	desc = desc {
		lang = data.lang,
		sc = data.sc,
		label = data.label,
		category = data.category,
		topic_data = data.topdata,
	}
	if not desc then
		return desc
	end
	desc_type = type(desc)
	if desc_type == "string" then
		return desc
	end
	error("Internal error: the value returned by `desc` must be a string or nil; received a " .. desc_type)
end


local function get_and_cache(data, obj, key)
	local val = convert_spec_to_string(data, obj[key])
	obj[key] = val
	return val
end


local function process_default(desc)
	local stripped_desc = desc
	local no_singularize, wikify, add_the
	while true do
		local new_stripped_desc = stripped_desc:match("^(.+) no singularize$")
		if new_stripped_desc then
			no_singularize = true
		end
		if not new_stripped_desc then
			new_stripped_desc = stripped_desc:match("^(.+) wikify$")
			if new_stripped_desc then
				wikify = true
			end
		end
		if not new_stripped_desc then
			new_stripped_desc = stripped_desc:match("^(.+) with the$")
			if new_stripped_desc then
				add_the = true
			end
		end
		if new_stripped_desc then
			stripped_desc = new_stripped_desc
		else
			break
		end
	end
	if stripped_desc == "default" then
		return true, no_singularize, wikify, add_the
	else
		return false
	end
end


local function format_desc(data, desc)
	local desc_parts = {}
	local types = split_types(data.topdata.type)
	for _, typ in ipairs(types) do
		insert(desc_parts, type_data[typ].desc .. " " .. desc)
	end
	return "{{{langname}}} " .. require(table_module).serialCommaJoin(desc_parts) .. "."
end


local substitute_template_specs

local function format_displaytitle(data, include_lang_prefix, upcase)
	local topdata, lang, label = data.topdata, data.lang, data.label
	local displaytitle = substitute_template_specs(data, topdata.displaytitle)
	if not displaytitle then
		return nil
	end
	if upcase then
		displaytitle = ucfirst(displaytitle)
	end
	if include_lang_prefix and lang then
		displaytitle = ("%s:%s"):format(lang:getCode(), displaytitle)
	end

	return displaytitle
end


local function get_breadcrumb(data)
	local topdata, lang, label = data.topdata, data.lang, data.label
	local ret

	if lang then
		ret = topdata.breadcrumb or format_displaytitle(data, false, "upcase")
	else
		ret = topdata.umbrella and topdata.umbrella.breadcrumb or
			topdata.breadcrumb or format_displaytitle(data, false, "upcase")
	end
	if not ret then
		ret = label
	end

	if type(ret) == "string" or type(ret) == "number" then
		ret = {name = ret}
	end

	local name = substitute_template_specs(data, ret.name)
	local nocap = ret.nocap

	return {name = name, nocap = nocap}
end


local function make_category_name(lang, label)
	if lang then
		return lang:getCode() .. ":" .. ucfirst(label)
	else
		return ucfirst(label)
	end
end


local function replace_special_descriptions(data, desc)
	if not desc then
		return desc
	end

	if desc:find("^=") then
		desc = desc:gsub("^=", "")
		return format_desc(data, desc)
	end

	local is_default, no_singularize, wikify, add_the = process_default(desc)
	if is_default then
		local linked_label = require(topic_utilities_module).link_label(data.label, no_singularize, wikify)
		if add_the then
			linked_label = "the " .. linked_label
		end
		return format_desc(data, linked_label)
	else
		return desc
	end
end


local function get_displaytitle_or_label(data)
	return format_displaytitle(data, false) or data.label
end


local function process_default_add_the(data, topic)
	local is_default, _, _, add_the = process_default(topic)
	if is_default then
		topic = get_displaytitle_or_label(data)
		if add_the then
			topic = "the " .. topic
		end
	end
	return topic, is_default
end


substitute_template_specs = function(data, desc)
	desc = convert_spec_to_string(data, desc)
	if not desc then
		return nil
	end
	
	local topdata, lang, label = data.topdata, data.lang, data.label
	if desc:find("{{{umbrella_msg}}}") then
		local catname = ucfirst(label)
		desc = gsub_escaping_replacement(desc, "{{{umbrella_msg}}}",
			"This category contains no dictionary entries, only other categories. The subcategories are of two " ..
			"sorts:\n\n* Subcategories named like \"aa:" .. catname ..
			"\" (with a prefixed language code) are categories of terms in specific languages. " ..
			"You may be interested especially in [[:Category:en:" .. catname .. "]], for English terms.\n" ..
			"* Subcategories of this one named without the prefixed language code are further categories just like " ..
			"this one, but devoted to finer topics."
		)
	end
	if desc:find("{{{topic}}}") then
		-- Compute the value for {{{topic}}}. If the user specified `topic`, use it. (If we're an umbrella category,
		-- allow a separate value for `umbrella.topic`, falling back to `topic`.) Otherwise, see if the description
		-- was specified as 'default' or a variant; if so, parse it to determine whether to add "the" to the label.
		-- Otherwise, just use the label directly.
		local topic = not lang and topdata.umbrella and topdata.umbrella.topic or topdata.topic
		if topic then
			topic = process_default_add_the(data, topic)
		else
			local desc
			if not lang then
				desc = topdata.umbrella and get_and_cache(data, topdata.umbrella, "description") or
					get_and_cache(data, topdata, "umbrella_description")
			end
			desc = desc or get_and_cache(data, topdata, "description")
			local defaulted_desc, is_default = process_default_add_the(data, desc)
			if is_default then
				topic = defaulted_desc
			else
				topic = get_displaytitle_or_label(data)
			end
		end

		desc = gsub_escaping_replacement(desc, "{{{topic}}}", topic)
	end
	
	return desc
end


local function process_box(data, def_topright_parts, val, pattern)
	if not val then
		return
	end
	local defval = ucfirst(data.label)
	if type(val) ~= "table" then
		val = {val}
	end
	for _, v in ipairs(val) do
		if v == true then
			insert(def_topright_parts, pattern:format(defval))
		else
			insert(def_topright_parts, pattern:format(v))
		end
	end
end


local function get_topright(data)
	local topdata, lang = data.topdata, data.lang
	local def_topright_parts = {}
	process_box(data, def_topright_parts, topdata.wp, "{{wikipedia|%s}}")
	process_box(data, def_topright_parts, topdata.wpcat, "{{wikipedia|category=%s}}")
	process_box(data, def_topright_parts, topdata.commonscat, "{{commonscat|%s}}")

	local def_topright
	if #def_topright_parts > 0 then
		def_topright = concat(def_topright_parts, "\n")
	end

	if lang then
		return substitute_template_specs(data, topdata.topright or def_topright)
	else
		return topdata.umbrella and substitute_template_specs(data, topdata.umbrella.topright) or
			substitute_template_specs(data, def_topright)
	end
end


local function remove_lang_params(desc)
	desc = desc:gsub("^{{{langname}}} ", "")
	desc = desc:gsub("{{{langcode}}}:", "")
	desc = desc:gsub("^{{{langcode}}} ", "")
	desc = desc:gsub("^{{{langcat}}} ", "")
	return desc
end


local function get_additional_msg(data)
	local types = split_types(data.topdata.type)
	if #types > 1 then
		local parts = {"'''NOTE''': This is a mixed category. It may contain terms of any of the following category types:"}
		for i, typ in ipairs(types) do
			insert(parts, ("* %s {{{topic}}}%s"):format(type_data[typ].desc, i == #types and "." or ";"))
		end
		insert(parts, "'''WARNING''': Such categories are strongly dispreferred and should be split into separate per-type categories.")
		return concat(parts, "\n")
	elseif label == "all topics" then
		return "'''NOTE''': This is the topmost topic category for {{{langname}}}. It should not directly contain " ..
		"any terms, but only lists of topic categories organized by type."
	else
		return type_data[types[1]].additional
	end
end


local function get_labels_categorizing(data)
	local m_labels_utilities = require(labels_utilities_module)
	return m_labels_utilities.format_labels_categorizing(
		m_labels_utilities.find_labels_for_category(data.label, "topic", data.lang), nil, data.lang)
end


-- Return the description along with the text following and preceding the description. The description and additional
-- (i.e. following) text are returned in the form of closures so the work of calculating the text (which can be
-- expensive, especially in the case of the additional text, where get_labels_categorizing() scans the entire set of
-- labels for any that categorize into this category) is not done when not needed, e.g. in higher levels of the
-- breadcrumb chain, where only the breadcrumb and parents (in fact, really just the first parent) are actually needed.
local function get_description_additional_preceding(data)
	local topdata, lang, label = data.topdata, data.lang, data.label
	local desc, additional, preceding

	-- This is kind of hacky, but it works for now.
	local function postprocess_thesaurus(txt)
		if not txt then
			return nil
		end
		if not data.thesaurus_data then
			return txt
		end
		txt = txt:gsub(" terms([ .,])", " thesaurus entries%1")
		txt = txt:gsub("Category:", "Category:Thesaurus:")
		return txt
	end

	if lang then
		desc = function()
			return postprocess_thesaurus(substitute_template_specs(data,
				replace_special_descriptions(data, get_and_cache(data, topdata, "description"))))
		end
		preceding = topdata.preceding
		additional = function()
			local additional_parts = {}
			if topdata.additional then
				insert(additional_parts, topdata.additional)
			end
			if not data.thesaurus_data then
				insert(additional_parts, get_additional_msg(data))
				local labels_msg = get_labels_categorizing(data)
				if labels_msg then
					insert(additional_parts, labels_msg)
				end
			end
			return postprocess_thesaurus(substitute_template_specs(data, concat(additional_parts, "\n\n")))
		end
	else
		if label == "all topics" then
			desc = "This is the topmost topic category for all languages."
			additional = "It contains no dictionary entries, only other categories. The subcategories are of two " ..
				"sorts:\n\n" ..
				"* Subcategories listed at the beginning, without a prefixed language code, are grouping " ..
				"categories similar to this category, but are devoted to general subject areas. Under them are " ..
				"finer-grained subject areas.\n" ..
				"* Subcategories named like \"aa:All topics\" (with a prefixed language code) are top-level " ..
				"categories like this one, but for specific languages. You may be interested especially in " ..
				"[[:Category:en:All topics]], for English terms.\n" ..
				"Note that categories under this tree categorize terms semantically rather than grammatically. " ..
				"Grammatical categories (such as all French verbs, or all English irregular plural forms) " ..
				"have a different naming structure, with the language name spelled out, such as " ..
				"[[:Category:French verbs]] or [[:Category:English irregular plurals]]."
			return desc, additional
		end

		-- Assume that if the description field contains a function, the function will return non-nil, so we don't
		-- have to call the function at this point (in case it is heavyweight).
		local has_umbrella_desc = topdata.umbrella and topdata.umbrella.description or topdata.umbrella_description

		desc = function()
			local desc = topdata.umbrella and get_and_cache(data, topdata.umbrella, "description") or
				get_and_cache(data, topdata, "umbrella_description")
			if not desc then
				 desc = get_and_cache(data, topdata, "description")
				 if desc then
					desc = replace_special_descriptions(data, desc)
					desc = remove_lang_params(desc)
					desc = desc:gsub("%.$", "")
					desc = "This category concerns the topic: " .. desc .. "."
				 end
			end
			if not desc then
				desc = "Categories concerning " .. label .. " in various specific languages."
			end
			return postprocess_thesaurus(substitute_template_specs(data, desc))
		end

		preceding = topdata.umbrella and topdata.umbrella.preceding or not has_umbrella_desc and topdata.preceding
		if preceding then
			preceding = remove_lang_params(preceding)
		end

		additional = function()
			local additional_parts = {}
			local topdata_additional = topdata.umbrella and topdata.umbrella.additional or
				not has_umbrella_desc and topdata.additional
			if topdata_additional then
				insert(additional_parts, remove_lang_params(topdata_additional))
			end
			insert(additional_parts, "{{{umbrella_msg}}}")
			if not data.thesaurus_data then
				insert(additional_parts, get_additional_msg(data))
				local labels_msg = get_labels_categorizing(data)
				if labels_msg then
					insert(additional_parts, labels_msg)
				end
			end
			return postprocess_thesaurus(substitute_template_specs(data, concat(additional_parts, "\n\n")))
		end
	end

	preceding = substitute_template_specs(data, preceding)
	return desc, additional, preceding
end


local function normalize_sort_key(data, sort)
	local lang, label = data.lang, data.label
	if not sort then
		-- When defaulting sort key to label, strip 'The ' (e.g. in 'The Matrix', 'The Hunger Games')
		-- and 'A ' (e.g. in 'A Song of Ice and Fire', 'A Christmas Carol') from label.
		local stripped_sort = label:match("^[Tt]he (.*)$")
		if stripped_sort then
			sort = stripped_sort
		end
		if not stripped_sort then
			stripped_sort = label:match("^[Aa] (.*)$")
			if stripped_sort then
				sort = stripped_sort
			end
		end
		if not stripped_sort then
			sort = label
		end
	end

	sort = substitute_template_specs(data, sort)

	if not lang then
		sort = " " .. sort
	end

	return sort
end


local function get_topic_parents(data)
	local topdata, lang, label = data.topdata, data.lang, data.label
	local parents = topdata.parents

	if not lang and label == "all topics" then
		return {{ name = "Category:Fundamental", sort = "topics" }}
	end

	if not parents or #parents == 0 then
		return nil
	end

	local ret = {}

	for _, parent in ipairs(parents) do
		parent = mw.clone(parent)

		if type(parent) ~= "table" then
			parent = {name = parent}
		end

		parent.sort = normalize_sort_key(data, parent.sort)

		if type(parent.name) ~= "string" then
			error(("Internal error: parent.name is not a string: parent = %s"):format(dump(parent)))
		end
		if parent.name:find("^Category:") or parent.nontopic then
			-- leave as-is
			parent.nontopic = nil
		else
			parent.name = make_category_name(lang, parent.name)
		end
		parent.name = substitute_template_specs(data, parent.name)
		
		insert(ret, parent)
	end

	local function make_list_of_type_parent(typ)
		return {
			name = make_category_name(lang, ("list of %s categories"):format(typ)),
			sort = (not lang and " " or "") .. label,
		}
	end

	if topdata.type ~= "toplevel" then
		local types = split_types(topdata.type)
		for _, typ in ipairs(types) do
			insert(ret, make_list_of_type_parent(typ))
		end
		if #types > 1 then
			insert(ret, make_list_of_type_parent("mixed"))
		end
	end

	-- Add umbrella category.
	if lang then
		insert(ret, {
			name = make_category_name(nil, label),
			sort = lang:getCanonicalName(),
		})
	end

	return ret
end


local function get_thesaurus_parents(data)
	local topdata, lang, label = data.topdata, data.lang, data.label
	local parent_substitutions = data.thesaurus_data.parent_substitutions
	local parents = topdata.parents

	if not parents or #parents == 0 then
		return nil
	end

	local ret = {}

	for _, parent in ipairs(parents) do
		-- Process parent categories as follows:
		-- 1. skip non-topic cats and meta-categories that start with "List of"
		-- 2. map "en:All topics" to "English thesaurus entries" (and same for other languages), but map "All topics" itself to the root "Thesaurus" category
		-- 3. check if this parent is to be substituted, if so, substitute it
		-- 4. prepend "Thesaurus:" to all other category names
		parent = mw.clone(parent)

		if type(parent) ~= "table" then
			parent = {name = parent}
		end

		parent.sort = normalize_sort_key(data, parent.sort)

		if type(parent.name) ~= "string" then
			error(("Internal error: parent.name is not a string: parent = %s"):format(dump(parent)))
		end
		if parent.name:find("^Category:") or parent.nontopic then
			-- skip
		elseif parent.name == "all topics" or parent_substitutions[parent.name] == "all topics" then
			if not lang then
				insert(ret, {
					name = "Thesaurus",
					sort = label,
				})
			else
				insert(ret, {
					name = "thesaurus entries",
					sort = parent.sort,
					lang = lang:getCode(),
					is_label = true,
				})
			end
		else
			parent.name = "Thesaurus:" .. make_category_name(lang, parent_substitutions[parent.name] or parent.name)
			parent.name = substitute_template_specs(data, parent.name)
			insert(ret, parent)
		end
	end

	-- Add the non-thesaurus version of this category as a parent, unless it is a thesaurus-only category.
	if not topdata.thesaurusonly then
		insert(ret, { name = make_category_name(lang, label), sort = " " })
	end

	-- Add umbrella category.
	if lang then
		insert(ret, {
			name = "Thesaurus:" .. make_category_name(nil, label),
			sort = lang:getCanonicalName(),
		})
	end

	return ret
end


local function generate_spec(category, lang, upcase_label, thesaurus_data)
	local label_data = require(topic_data_module)
	local label

	-- Convert label to lowercase if possible
	local lowercase_label = mw.getContentLanguage():lcfirst(upcase_label)

	-- Check if the label exists
	local labels = label_data["LABELS"]

	if labels[lowercase_label] then
		label = lowercase_label
	else
		label = upcase_label
	end

	local topdata = labels[label]

	-- Go through handlers
	if not topdata then
		for _, handler in ipairs(label_data["HANDLERS"]) do
			topdata = handler.handler(label)
			if topdata then
				topdata.module = handler.module
				break
			end
		end
	end

	if not topdata then
		return nil
	end

	local data = {
		category = category,
		lang = lang,
		label = label,
		topdata = topdata,
		thesaurus_data = thesaurus_data,
	}

	local description, additional, preceding = get_description_additional_preceding(data)
	local parents
	if thesaurus_data then
		parents = get_thesaurus_parents(data)
	else
		parents = get_topic_parents(data)
	end

	return {
		lang = lang and lang:getCode() or nil,
		description = description,
		additional = additional,
		preceding = preceding,
		parents = parents,
		breadcrumb = get_breadcrumb(data),
		displaytitle = format_displaytitle(data, "include lang prefix", "upcase"),
		topright = get_topright(data),
		module = topdata.module,
		can_be_empty = not lang,
		hidden = false,
	}
end


-- Handler for `Thesaurus:...` categories.
table.insert(raw_handlers, function(data)
	local code, upcase_label = data.category:match("^Thesaurus:(%l[%a-]*%a):(.+)$")
	local lang
	if code then
		lang = require(languages_module).getByCode(code)
		if not lang then
			mw.log(("Category '%s' looks like a language-specific thesaurus category but unable to match language prefix"):
				format(data.category))
			return nil
		end
	else
		upcase_label = data.category:match("^Thesaurus:(.+)$")
	end

	if upcase_label then
		local thesaurus_data = require(thesaurus_data_module)
		-- substituted category names are not allowed
		if thesaurus_data.parent_substitutions[lcfirst(upcase_label)] then
			error(("Category is not allowed as a Thesaurus category: %s (see the list of parent substitutions at " ..
				"[[Module:category tree/topic/thesaurus]])"):format(data.category))
		end
		return generate_spec(lang, upcase_label, thesaurus_data)
	end
end)


-- Handler for regular topic categories.
table.insert(raw_handlers, function(data)
	local code, upcase_label = data.category:match("^(%l[%a-]*%a):(.+)$")
	local lang
	if code then
		lang = require(languages_module).getByCode(code)
		if not lang then
			mw.log(("Category '%s' looks like a language-specific topic category but unable to match language prefix"):
				format(data.category))
			return nil
		end
	else
		upcase_label = data.category
	end

	return generate_spec(lang, upcase_label)
end)


-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Thesaurus"] = {
	description = "Category for entries of the Wiktionary thesaurus, located in a separate namespace.",
	additional = [=[
There are '''three ways to browse''' the thesaurus:
* Look under '''[[:Category:Thesaurus entries by language]]''' to get started.
* Use the search box below.
* Browse the thesaurus by topic using the links under "Subcategories" below.

The main project page is [[Wiktionary:Thesaurus]].

{{ws header|<nowiki/>|link=}}]=],
	parents = {
		"Category:Fundamental",
		"Category:Wiktionary projects",
	},
}

return {RAW_CATEGORIES = raw_categories, RAW_HANDLERS = raw_handlers}
