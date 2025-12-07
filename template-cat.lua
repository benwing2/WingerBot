-- Author: Benwing

local export = {}

local require_when_needed = require("Module:utilities/require when needed")
local is_callable = require_when_needed("Module:fun", "is_callable")
local format_categories = require_when_needed("Module:utilities", "format_categories")
local parse_interface_module = require("Module:parse interface")
local m_string_utilities = require("Module:string utilities")
local und_lang = require("Module:languages").getByCode("und", true)

local ugsub = m_string_utilities.gsub
local ufind = m_string_utilities.find
local split = m_string_utilities.split

local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack -- Lua 5.2 compatibility


-- This table detects the category type of the template given its name. When this is invoked, the language code has
-- already been removed from the beginning, and anything starting with a slash has been truncated. The entries are
-- processed in order and are two-element lists of Lua patterns (anchored on both sides; beware of hyphens, which need
-- to be %-escaped) and the category type to use. The category types themselves are mapped to categories in
-- category_type_to_category.
local detect_category_type_list = {
	-- order is important here

	-- nouns, proper nouns, pronouns
	-- (1) unambiguous decl/infl templates
	{"decl%-.*proper.*", "noun inflection-table"},
	{"infl%-.*proper.*", "noun inflection-table"},
	{"decl%-.*pron.*", "pronoun inflection-table"},
	{"infl%-.*pron.*", "pronoun inflection-table"},
	{"decl%-noun.*", "noun inflection-table"},
	{"infl%-noun.*", "noun inflection-table"},
	-- (2) nouns
	{"noun", "headword-line"},
	{"noun[ -]form", "headword-line"},
	{"noun[ -]pl", "headword-line"},
	{"noun[ -]plonly", "headword-line"},
	-- Some languages, e.g. Urdu, have inflection templates called e.g. [[Template:ur-noun-f-ī]]. They should be called
	-- [[Template:ur-decl-noun-f-ī]] but we can autodetect them if we exclude the likely cases that are not declension
	-- templates.
	{"noun%-.*", "noun inflection-table"},
	{"ndecl", "noun inflection-table"},
	-- (3) proper nouns
	{"proper[ -]?noun", "headword-line"},
	{"proper[ -]?noun[ -]form", "headword-line"},
	{"proper[ -]?noun[ -]pl", "headword-line"},
	{"proper[ -]?noun[ -]plonly", "headword-line"},
	{"pnoun", "headword-line"},
	{"pnoun[ -]form", "headword-line"},
	{"pnoun[ -]pl", "headword-line"},
	{"pnoun[ -]plonly", "headword-line"},
	{"propn", "headword-line"},
	{"propn[ -]form", "headword-line"},
	{"propn[ -]pl", "headword-line"},
	{"propn[ -]plonly", "headword-line"},
	-- See above for inflection templates without 'decl' or 'infl' in them.
	{"proper[ -]?noun%-.*", "noun inflection-table"},
	{"pnoun%-.*", "noun inflection-table"},
	{"propn%-.*", "noun inflection-table"},
	-- (4) pronouns
	{"pron", "headword-line"},
	{"pronoun", "headword-line"},
	{"pron[ -]form", "headword-line"},
	{"pronoun[ -]form", "headword-line"},
	-- adjectives
	{"decl%-adj.*", "adjective inflection-table"},
	{"infl%-adj.*", "adjective inflection-table"},
	{"adj", "headword-line"},
	{"adjective", "headword-line"},
	{"adj[ -]form", "headword-line"},
	{"adjective[ -]form", "headword-line"},
	{"adj[ -]comp", "headword-line"},
	{"adjective[ -]comp", "headword-line"},
	{"adj[ -]sup", "headword-line"},
	{"adjective[ -]sup", "headword-line"},
	-- Some languages, e.g. Urdu and Lithuanian, have inflection templates called e.g. [[Template:ur-adj-1]] and
	-- [[Template:lt-adj-is]]. They should be called [[Template:ur-decl-adj-1]] and [[Template:lt-decl-adj-is]] but we
	-- can autodetect them if we exclude the likely cases that are not declension templates.
	{"adj%-.*", "adjective inflection-table"},
	{"adecl", "adjective inflection-table"},
	-- verbs; need to avoid including conjunctions
	{"verb", "headword-line"},
	{"conj", "verb inflection-table"},
	{"conj[0-9 -].*", "verb inflection-table"},
	{"conjug.*", "verb inflection-table"},
	{"infl%-verb.*", "verb inflection-table"},

	-- pronominal boxes
	{".*personal pronouns", "personal pronouns"},
	{".*demonstrative.*", "demonstratives"},
	{".*interrogative.*", "interrogatives"},
	{".*possessives", "possessives"},
	{".*possessive .*", "possessives"},
	{".*relative .*", "relatives"},
	{".*articles", "articles"},

	-- TOC tables
	{".*TOC", "TOC"},

	-- numerals
	{".*cardinals", "cardinals"},
	{".*ordinals", "ordinals"},
}

-- This table indicates how to convert template category types to categories. It consists of a list of pairs, where the
-- first element is the category type and the second element is a key-value table containing the following keys:
-- * `aliases`: Optional list of aliases for the category type, which can be used when explicitly specifying the type,
--   e.g. {{tcat|hw}} instead of {{tcat|headword-line}}.
-- * `cats`: List of categories to add the template to. Each entry either specifies a ''raw'' category (if the category
--   name begins with "Category:") or a ''label'' category (for other strings, where e.g. if the label is
--   "noun inflection-table", the category name is "LANG noun inflection-table templates"). An entry is either a string,
--   directly specifying the category name, or a key-value table with keys `name` (the category name) and `sort` (how to
--   generate the sort base). By default, the sort base for raw categories is a comma-separated list of the language
--   names (not codes) associated with the template, or the full template name if there are no languages, and the sort
--   base for label categories is the template name minus the initial language code. If this isn't correct, the `sort`
--   field specifies how to compute the sort base. It is either a function of two arguments, the template name and
--   language object, which should return the sort base; or a table of specs telling how to compute the sort base. In
--   the case of a function, the template name passed in is the full name for raw categories, but the name minus any
--   language code prefix in the case of label categories; and for raw categories, a list of all associated language
--   objects is passed in, or {nil} if none, while for label categories, a single language object is passed in.
--   (Label categories can only exist if there are associated languages.) In the case where `sort` is a table of specs,
--   it is a list where each element is a two-element list of a Lua pattern anchored on both sides and the corresponding
--   pattern replacement string. The specs are processed in order.
local category_type_to_category = {
	{"noun inflection-table", {
		aliases = {"nouninfl", "noundecl", "ndecl"},
		cats = {{name = "noun inflection-table", sort = {
			{"infl%-(.*)", "%1"},
			{"decl%-(.*)", "%1"},
			{"noun%-(.*)", "%1"},
			{"noun", "*"},
			{"ndecl", "*"},
			{"proper[ -]?noun%-(.*)", "%1"},
			{"propn%-(.*)", "%1"},
			{"pnoun%-(.*)", "%1"},
		}}},
	}},
	{"pronoun inflection-table", {
		aliases = {"proninfl", "prondecl"},
		cats = {{name = "pronoun inflection-table", sort = {
			{"infl%-(.*)", "%1"},
			{"decl%-(.*)", "%1"},
			{"pronoun%-(.*)", "%1"},
			{"pron%-(.*)", "%1"},
			{"pronoun", "*"},
			{"prondecl", "*"},
		}}},
	}},
	{"adjective inflection-table", {
		aliases = {"adjinfl", "adjdecl", "adecl"},
		cats = {{name = "adjective inflection-table", sort = {
			{"infl%-(.*)", "%1"},
			{"decl%-(.*)", "%1"},
			{"adj%-(.*)", "%1"},
			{"adjective%-(.*)", "%1"},
			{"adj", "*"},
			{"adjective", "*"},
			{"adecl", "*"},
		}}},
	}},
	{"verb inflection-table", {
		aliases = {"verbinfl", "conj"},
		cats = {{name = "verb inflection-table", sort = {
			{"infl%-(.*)", "%1"},
			{"verb%-(.*)", "%1"},
			{"conj%-(.*)", "%1"},
			{"conj", "*"},
		}}},
	}},
	{"headword-line", {
		aliases = {"hw", "headword"},
		cats = {"headword-line"},
	}},
	{"personal pronouns", {
		aliases = {"perspron"},
		cats = {"navigation", "Category:Personal pronoun boxes"},
	}},
	{"demonstratives", {
		cats = {"navigation", "Category:Demonstrative boxes"},
	}},
	{"interrogatives", {
		cats = {"navigation", "Category:Interrogative boxes"},
	}},
	{"possessives", {
		cats = {"navigation", "Category:Possessive pronoun and determiner boxes"},
	}},
	{"relatives", {
		cats = {"navigation", "Category:Relative pronoun and determiner boxes"},
	}},
	{"articles", {
		cats = {"navigation", "Category:Article boxes"},
	}},
	{"navigation", {
		-- miscellaneous navigation box templates like {{eu-aux verbs}}, {{pt-forms of address}}
		aliases = {"nav"},
		cats = {"navigation"},
	}},
	{"TOC", {
		cats = {{name = "navigation", sort = {
			{"categoryTOC", "TOC"},
		}}, "Category:TOC templates"},
	}},
	{"cardinals", {
		cats = {"navigation", "Category:Number boxes"},
	}},
	{"ordinals", {
		cats = {"navigation", "Category:Number boxes"},
	}},
}

local category_type_to_category_map = {}

for _, category_type_to_category_spec in ipairs(category_type_to_category) do
	local category_type, props = unpack(category_type_to_category_spec)
	category_type_to_category_map[category_type] = props
	if props.aliases then
		for _, alias in ipairs(props.aliases) do
			category_type_to_category_map[alias] = props
		end
	end
end

-- Split an argument on comma, but not comma followed by whitespace.
local function split_on_comma(val)
	if val:find(",") then
		-- Don't optimize more than this because there can be commas backslashed, inside of links or followed by
		-- whitespace that don't cause splitting.
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end

local function get_lang_or_script(code)
	return code == "-" and code or
		require("Module:languages").getByCode(code, nil, "allow etym") or
		require("Module:languages").getByCode(code .. "-pro", nil, "allow etym") or
		require("Module:scripts").getByCode(code)
end

local function obj_code(obj)
	if obj == "-" then
		return obj
	end
	return obj:getCode()
end

local function infer_lang_or_script_code(name)
	local hyphen_parts = split(name, "%-")
	for i = #hyphen_parts - 1, 1, -1 do
		local code = concat(hyphen_parts, "-", 1, i)
		local obj = get_lang_or_script(code)
		if obj then
			local rest = concat(hyphen_parts, "-", i + 1)
			return obj, rest
		end
	end
	return nil, nil
end

local function process_sortbase_specs(sortbase, specs)
	for _, spec in ipairs(specs) do
		local from, to = unpack(spec)
		sortbase = ugsub(sortbase, from, to)
	end
	return sortbase
end

local function template_name_minus_langcode_to_category_type(name)
	for _, type_spec in ipairs(detect_category_type_list) do
		local pattern, intended_type = unpack(type_spec)
		if ufind(name, "^" .. pattern .. "$") then
			return intended_type
		end
	end
	return nil
end

local function compute_categories_for_template(full_template_name, template_name_minus_langcode, category_type,
	langs_or_scripts)
	if not category_type_to_category_map[category_type] then
		error("Unrecognized template category type: " .. category_type)
	end
	local props = category_type_to_category_map[category_type]
	if not props.cats then
		error("Internal error: No categories given for category type: " .. category_type)
	end
	local categories = {}
	for _, catspec in ipairs(props.cats) do
		if type(catspec) == "string" then
			catspec = {name = catspec}
		end
		local rawcat = catspec.name:match("^Category:(.*)")
		if rawcat then
			local sortbase
			if not catspec.sort then
				if langs_or_scripts then
					local langnames = {}
					for _, lang_or_sc in ipairs(langs_or_scripts) do
						insert(langnames, lang_or_sc:getCanonicalName()) -- FIXME: or lang:getFullName()?
					end
					sortbase = concat(langnames, ",")
				else
					sortbase = full_template_name
				end
			elseif is_callable(catspec.sort) then
				sortbase = catspec.sort(full_template_name, langs_or_scripts)
			else
				sortbase = process_sortbase_specs(full_template_name, catspec.sort)
			end
			insert(categories, {cat = rawcat, lang = und_lang, sort_base = sortbase})
		elseif langs_or_scripts then
			for _, lang_or_sc in ipairs(langs_or_scripts) do
				local sortbase
				if not catspec.sort then
					sortbase = template_name_minus_langcode
				elseif is_callable(catspec.sort) then
					sortbase = catspec.sort(template_name_minus_langcode, lang_or_sc)
				else
					sortbase = process_sortbase_specs(template_name_minus_langcode, catspec.sort)
				end
				if lang_or_sc:hasType("script") then
					insert(categories, {
						cat = ("%s templates"):format(lang_or_sc:getCategoryName()), lang = und_lang, sc = lang_or_sc,
						sort_base = sortbase,
					})
				else
					insert(categories, {
						cat = ("%s %s templates"):format(lang_or_sc:getFullName(), catspec.name), lang = lang_or_sc,
						sort_base = sortbase,
					})
				end
			end
		end
	end
	if not categories[1] then
		error(("No categories generated for template [[Template:%s]] with category type '%s'"):format(
			full_template_name, category_type))
	end

	return categories
end

--[==[
Main entry point.
]==]
function export.categorize(frame)
	local params = {
		[1] = {}, -- comma-separated list of category types; by default, inferred from template name
		lang = {}, -- comma-separated list of languages; by default, inferred from template name
		["pagename"] = {}, -- for testing
		["json"] = {type = "boolean"}, -- for testing
	}

	local parent_args = frame:getParent().args
	args = require("Module:parameters").process(parent_args, params)
	local category_specs = {}

	local function insert_cat(cat, sort_key)
		for _, existing_cat in ipairs(category_specs) do
			if existing_cat.cat == cat then
				return
			end
		end
		insert(category_specs, {cat = cat, sort_key = sort_key})
	end

	local pagename = args.pagename
	if not pagename then
		title = mw.title.getCurrentTitle()
		pagename = title.fullText
	end

	if pagename:find("/documentation$") or pagename:find("/documentation/") then
		return ""
	end

	if pagename:find("^Template:User:") then
		insert_cat("User sandbox templates", (pagename:gsub("^Template:User:", "")))
	elseif pagename:find("^User:") then
		insert_cat("User sandbox templates", (pagename:gsub("^User:", "")))
	else
		if not pagename:find("^Template:") then
			error(("This template should only be used in the Template namespace, not on page '%s'"):format(pagename))
		end
		local full_template_name = pagename:gsub("^Template:", "")
		local rootpage = full_template_name:gsub("/.*", "")
		if pagename:find("/sandbox") then
			insert_cat("Sandbox templates", full_template_name)
		elseif pagename:find("^sandbox/") then
			insert_cat("Sandbox templates", full_template_name:gsub("^sandbox/", ""))
		else
			local template_objs
			if args.lang == "-" then
				template_objs = false
			elseif args.lang then
				template_objs = {}
				for _, code in ipairs(split(args.lang, ",")) do
					-- We need to have an indicator of families because we allow bare family codes to stand for proto-languages.
					if code:find("^fam:") then
						code = code:gsub("^fam:", "")
						local family = require("Module:families").getByCode(code) or
							error(("Unrecognized family code '%s' in [[Module:template cat]]"):format(code))
						local descendants = family:getDescendantCodes()
						for _, desc in ipairs(descendants) do
							local obj = get_lang_or_script(desc)
							if obj then
								-- make sure we skip families without proto-languages
								insert(template_objs, obj)
							end
						end
					else
						local obj = get_lang_or_script(code)
						if not obj then
							error(("Unrecognized language or script code '%s'"):format(code))
						end
						insert(template_objs, obj)
					end
				end
			end

			local cattypes
			if args[1] then
				cattypes = split_on_comma(args[1])
			end

			local inferred_obj, inferred_rest = infer_lang_or_script_code(rootpage)
			if template_objs == nil or not cattypes then
				if not inferred_obj then
					error(("Unable to infer language or script from template root page '%s' for template '%s'; specify lang/script and type explicitly"):format(
					rootpage, pagename))
				end
				if template_objs == nil then
					template_objs = {inferred_obj}
				end
				if not cattypes then
					local inferred_type = template_name_minus_langcode_to_category_type(inferred_rest)
					if not inferred_type then
						error(("Unable to infer template category type from template remainder (after stripping langcode) '%s' for template '%s'; specify type explicitly"):format(
							inferred_rest, pagename))
					end
					cattypes = {inferred_type}
				end
			end

			for _, cattype in ipairs(cattypes) do
				local cats = compute_categories_for_template(full_template_name, inferred_rest, cattype, template_objs)
				for _, cat in ipairs(cats) do
					insert(category_specs, cat)
				end
			end
		end
	end

	if args.json then
		return require("Module:JSON").toJSON(category_specs)
	else
		-- We are returning categories for templates or user-space pages, so we need to force the output.
		return format_categories(category_specs, nil, nil, nil, "force_output")
	end
end

--[==[Table used in the documentation to {{tl|template cat}}.]==]
function export.pattern_to_category_type_table()
	local parts = {}
	local function ins(text)
		insert(parts, text)
	end
	ins('{|class="wikitable"')
	ins("! Pattern !! Inferred category type")
	for _, detect_spec in ipairs(detect_category_type_list) do
		local pattern, category_type = unpack(detect_spec)
		ins("|-")
		ins(("| <code>%s</code> || <code>%s</code>"):format(pattern, category_type))
	end
	ins("|}")
	return concat(parts, "\n")
end

--[==[Table used in the documentation to {{tl|template cat}}.]==]
function export.category_type_to_category_table()
	local parts = {}
	local function ins(text)
		insert(parts, text)
	end
	local category_types = {}
	local category_type_to_aliases = {}

	for _, category_type_to_category_spec in ipairs(category_type_to_category) do
		local category_type, props = unpack(category_type_to_category_spec)
		insert(category_types, category_type)
		category_type_to_aliases[category_type] = {}
		if props.aliases then
			for _, alias in ipairs(props.aliases) do
				insert(category_type_to_aliases[category_type], alias)
			end
			table.sort(category_type_to_aliases[category_type])
		end
	end
	table.sort(category_types)

	local function get_category_type_categories(category_type)
		local cats = {}
		for _, catspec in ipairs(category_type_to_category_map[category_type].cats) do
			if type(catspec) == "string" then
				catspec = {name = catspec}
			end
			local cat = catspec.name
			if cat:find("^Category:") then
				insert(cats, ("<code>%s</code>"):format((cat:gsub("^Category:", ""))))
			else
				insert(cats, ("<code><var>LANG</var> %s templates</code>"):format(cat))
			end
		end
		return concat(cats, ", ")
	end

	ins('{|class="wikitable"')
	ins("! Category type !! Canonical category type !! Categories")
	for _, category_type in ipairs(category_types) do
		ins("|-")
		ins(("| <code>'''%s'''</code> || ''(same)'' || <code>%s</code>"):format(
			category_type, get_category_type_categories(category_type)))
		for _, alias in ipairs(category_type_to_aliases[category_type]) do
			ins("|-")
			ins(("| <code>%s</code> || <code>'''%s'''</code> || <code>%s</code>"):format(
				alias, category_type, get_category_type_categories(category_type)))
		end
	end
	ins("|}")
	return concat(parts, "\n")
end

return export
