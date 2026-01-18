-- Common code between [[Module:hi-headword]] and [[Module:pa-headword]].

local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_links = require("Module:links")
local m_table = require("Module:table")

local list_to_set = m_table.listToSet
local rsplit = mw.text.split
local uupper = mw.ustring.upper
local ulower = mw.ustring.lower
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local parse_interface_module = "Module:parse interface"
local scripts_module = "Module:scripts"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}
local gender_param = {type = "genders"}
local gender_param_with_default = {type = "genders", default = "?"}

local concat = table.concat
local insert = table.insert
local remove = table.remove

local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsplit = mw.text.split
local unpack = unpack or table.unpack -- Lua 5.2 compatibility


local misc_pos_with_gender = list_to_set {
	"numerals",
	"suffixes",
	"adjective forms",
	"noun forms",
	"pronoun forms",
	"determiner forms",
	"verb forms",
	"postposition forms",
}

local langs_supported = {
	["hi"] = {
		other_langs_scripts = {
			{"ur", "ur", "ur-Arab", "Urdu"},
		},
	},
	["pa"] = {
		other_langs_scripts = {
			{"gur", "pa", "Guru", "Gurmukhi"},
			{"sha", "pa", "pa-Arab", "Shahmukhi"},
		},
	},
}


----------------------------------------------- Utilities --------------------------------------------

local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(page)
	require("Module:debug").track("hi-pa-headword/" .. page)
	return true
end

local function validate_genders(data, genders)
	data.genders = genders
	for _, gspec in ipairs(genders) do
		local g = gspec.spec
		if g == "m" or g == "f" or
			g == "m-p" or g == "f-p" or
			g == "mf" or g == "mf-p" or
			g == "mfbysense" or g == "mfbysense-p" or
			g == "mfequiv" or g == "mfequiv-p" or
			g == "?" then
		else
			error("Invalid gender: " .. g)
		end
	end
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(data, args, field, is_head, no_include_tr)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	return m_headword_utilities.parse_term_list_with_modifiers {
		forms = args[argfield],
		paramname = field,
		splitchar = ",",
		is_head = is_head,
		include_mods = not no_include_tr and {"tr"} or nil,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel_form)
	local terms = parse_inflection(data, args, field)
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel_form and {form = accel_form} or nil,
	}
end

function export.show(frame)
	local iparams = {
		[1] = true,
		["lang"] = {required = true},
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	local parargs = frame:getParent().args
	local poscat = iargs[1]
	local langcode = iargs.lang
	if not langs_supported[langcode] then
		local langcodes_supported = {}
		for lang, _ in pairs(langs_supported) do
			table.insert(langcodes_supported, lang)
		end
		error("This module currently only works for lang=" .. table.concat(langcodes_supported, "/"))
	end
	local lang = require(languages_module).getByCode(langcode, true)
	local langname = lang:getCanonicalName()
	local pos_in_1 = not poscat
	if pos_in_1 then
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and (misc_pos_with_gender[poscat] and "head_with_gender" or "head") or poscat

	local langprops = langs_supported[langcode]

	local params = {
		["head"] = true,
		["tr"] = true,
		["id"] = true,
		["sort"] = true,
		["nolink"] = boolean_param,
		["nolinkhead"] = {type = "boolean", alias_of = "nolink"},
		["suffix"] = boolean_param,
		["nosuffix"] = boolean_param,
		["splithyphen"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = true, -- for testing
	}

	if pos_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	for _, other_lang_script in ipairs(langprops.other_langs_scripts) do
		local param, _, _, _ = unpack(other_lang_script)
		params[param] = list_param
	end

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	if pos_functions[indexing_poscat] then
		for key, val in pairs(pos_functions[indexing_poscat].params) do
			params[key] = val
		end
	end

	local parargs = frame:getParent().args
	local args = require("Module:parameters").process(parargs, params)

	local data = {
		lang = lang,
		langname = langname,
		pos_category = poscat,
		categories = {},
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		-- We use our own splitting algorithm so the redundant head cat will be inaccurate.
		no_redundant_head_cat = true,
	}

	local trs = args.tr and split_on_comma(args.tr) or {}
	local num_trs = #trs
	local heads = parse_inflection(data, arg, "head", "is_head")
	local num_heads = #heads
	if num_heads > 0 and num_trs > 0 and num_heads ~= num_trs then
		error(("%s head%s specified explicitly but %s translit%s; they must match; use '+' to stand for the default head (the pagename) or no manual translit"):format(
			num_heads, num_heads > 1 and "s" or "", num_trs, num_trs > 1 and "s" or ""))
	end
	if num_heads == 0 and num_trs > 0 then
		for i = 1, num_trs do
			heads[i] = {term = "+"}
		end
	end
	if not heads[1] then
		heads[1] = {term = "+"}
	end
	for i, headobj in ipairs(heads) do
		if headobj.term == "+" then
			headobj.term = args.nolink and pagename or m_headword_utilities.add_links_to_multiword_term(pagename,
				{split_hyphen_when_space = args.splithyphen})
		end
		if headobj.tr and trs[i] then
			if headobj.tr ~= trs[i] then
				error(("Saw two different translits '%s' and '%s' for head #%s '%s'"):format(
					headobj.tr, trs[i], i, headobj.term))
			end
		else
			headobj.tr = headobj.tr or trs[i]
		end
		if headobj.tr == "+" then
			headobj.tr = nil
		end
	end
	data.heads = heads

	data.is_suffix = false
	if args.suffix or (
		not args.nosuffix and pagename:find("^%-") and poscat ~= "suffixes" and poscat ~= "suffix forms"
	) then
		data.is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = m_en_utilities.singularize(poscat)
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[indexing_poscat] then
		pos_functions[indexing_poscat].func(args, data)
	end

	for _, other_lang_script in ipairs(langprops.other_langs_scripts) do
		local param, other_langcode, other_sccode, lang_script_label = unpack(other_lang_script)
		local terms = parse_inflection(data, args, param, nil, "no_include_tr")
		if terms[1] then
			local other_lang = require(languages_module).getByCode(other_langcode, true)
			local other_sc = require(scripts_module).getByCode(other_sccode, true)
			for _, termobj in ipairs(terms) do
				termobj.lang = other_lang
				termobj.sc = other_sc
			end
			m_headword_utilities.insert_inflection {
				headdata = data,
				terms = terms,
				label = lang_script_label .. " spelling",
			}
		end
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

pos_functions.adjectives = {
	params = {
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
		["f"] = list_param,
		["m"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable adjectives")
		end
		parse_and_insert_inflection(data, args, {1, "comp"}, "<<comparative>>")
		parse_and_insert_inflection(data, args, {2, "sup"}, "<<superlative>>")
		parse_and_insert_inflection(data, args, "m", "masculine")
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

pos_functions.ordinals = {
	params = {
		["f"] = list_param,
		["m"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		data.pos_category = "adjectives"
		table.insert(data.categories, data.langname .. " numerals")
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable numerals")
		end
		parse_and_insert_inflection(data, args, "m", "masculine")
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

pos_functions.cardinals = {
	params = {
		[1] = gender_param,
		["g"] = {alias_of = 1}, -- FIXME, delete
		["g2"] = true, -- FIXME, delete
		["sym"] = list_param,
	},
	func = function(args, data)
		data.pos_category = "numerals"
		validate_genders(data, args[1])
		parse_and_insert_inflection(data, args, "sym", "native script symbol")
	end,
}

local function nouns(plpos)
	return {
		params = {
			[1] = gender_param_with_default,
			["g"] = {alias_of = 1}, -- FIXME, delete
			["g2"] = true, -- FIXME, delete
			["pl"] = list_param,
			["f"] = list_param,
			["m"] = list_param,
			["ind"] = boolean_param,
		},
		func = function(args, data)
			validate_genders(data, args[1])
			if args["ind"] then
				if args["pl"][1] then
					error("Can't specify both ind= and pl=")
				end
				table.insert(data.inflections, {label = glossary_link("indeclinable")})
				table.insert(data.categories, data.langname .. " indeclinable " .. plpos)
			else
				parse_and_insert_inflection(data, args, "pl", "plural")
			end
			parse_and_insert_inflection(data, args, "m", "masculine")
			parse_and_insert_inflection(data, args, "f", "feminine")
			if args["m"][1] or args["f"][1] then
				table.insert(data.categories, data.langname .. " " .. plpos .. " with other-gender equivalents")
			end
		end,
	}
end

pos_functions.nouns = nouns("nouns")
pos_functions["proper nouns"] = nouns("proper nouns")

pos_functions.pronouns = {
	params = {
		[1] = gender_param,
		["g"] = {alias_of = 1}, -- FIXME, delete
		["g2"] = true, -- FIXME, delete
	},
	func = function(args, data)
		validate_genders(data, args[1])
	end,
}

pos_functions.verbs = {
	params = {
		[1] = true,
	},
	func = function(args, data)
		if args[1] then
			local label, cat
			if args[1] == "t" then
				label = "transitive"
				table.insert(data.categories, data.langname .. " transitive verbs")
			elseif args[1] == "i" then
				label = "intransitive"
				table.insert(data.categories, data.langname .. " intransitive verbs")
			elseif args[1] == "d" then
				label = "ditransitive"
				table.insert(data.categories, data.langname .. " ditransitive verbs")
			elseif args[1] == "it" or args[1] == "ti" then
				label = "ambitransitive"
				table.insert(data.categories, data.langname .. " transitive verbs")
				table.insert(data.categories, data.langname .. " intransitive verbs")
			else
				error("Unrecognized param 1=" .. args[1] .. ": Should be 'i' = intransitive, 't' = transitive, or 'it'/'ti' = ambitransitive")
			end
			table.insert(data.inflections, {label = glossary_link(label)})
		end

		local head = data.heads[1]
		if head:find(" ") then
			local base_verb = m_links.remove_links(head):gsub("^.* ", "")
			table.insert(data.categories, data.langname .. " compound verbs formed with " .. base_verb)
		end
	end,
}

pos_functions.head_with_gender = {
	params = {
		[2] = gender_param,
	},
	func = function(args, data)
		validate_genders(data, args[2])
	end,
}

-- FIXME, delete
local pos_with_gender = {
	params = {
		[1] = gender_param,
		["g"] = {alias_of = 1}, -- FIXME, delete
		["g2"] = true, -- FIXME, delete
	},
	func = function(args, data)
		validate_genders(data, args[1])
	end,
}

-- FIXME, delete
for misc_pos, _ in pairs(misc_pos_with_gender) do
	pos_functions[misc_pos] = pos_with_gender
end

return export
