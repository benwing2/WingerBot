-- Based on [[Module:ar-headword]] by: Benwing, CodeCat
-- Adapted by Fenakhay

local sc = require("Module:scripts").getByCode("Arab")
local lang = require("Module:languages").getByCode("ar")

local export = {}
local pos_functions = {}

-----------------------
-- Utility functions --
-----------------------

-- If Not Empty
local function ine(arg)
	if arg == "" then
		return nil
	else
		return arg
	end
end

local function list_to_set(list)
	local set = {}
	for _, item in ipairs(list) do
		set[item] = true
	end
	return set
end

-- version of mw.ustring.gsub() that discards all but the first return value
function rsub(term, foo, bar)
	local retval = mw.ustring.gsub(term, foo, bar)
	return retval
end

-- Tracking functions

local trackfn = require("Module:debug").track

function track(page)
	trackfn(lang:getCode() .. "-headword/" .. page)
	return true
end

local function append_cat(data, pos)
	table.insert(data.categories, lang:getCanonicalName() .. " " .. pos)
end

local function glossary_link(entry, text)
	text = text or entry
	return "[[Appendix:Glossary#" .. entry .. "|" .. text .. "]]"
end

function remove_links(text)
	text = rsub(text, "%[%[[^|%]]*|", "")
	text = rsub(text, "%[%[", "")
	text = rsub(text, "%]%]", "")
	return text
end

local function make_unused_key_tracker(t)
	local unused_keys = require "Module:table".listToSet(require "Module:table".keysToList(t))
	local mt = {
		__index = function(_, key)
			if key ~= nil then
				unused_keys[key] = nil
			end
			return t[key]
		end,
		__newindex = function(_, key, value)
			t[key] = value
		end
	}
	local proxy_table = setmetatable({}, mt)
	return proxy_table, unused_keys
end

-- The main entry point.
function export.show(frame)
	local PAGENAME = mw.loadData("Module:headword/data").pagename

	local poscat =
		frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local args, unused_keys = make_unused_key_tracker(frame:getParent().args)

	if frame.args["lang"] then
		lang = require("Module:languages").getByCode(frame.args["lang"])
	else
		error("Please specify a language code.")
	end

	-- Gather parameters
	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = {},
		translits = {},
		genders = {},
		inflections = {}
	}

	local saw_head = false
	local head = ine(args["head"])
	if head then
		saw_head = true
	else
		head = PAGENAME
	end
	local translit = ine(args["tr"])
	local i = 1

	while head do
		table.insert(data.heads, head)
		data.translits[#data.heads] = translit

		i = i + 1
		head = ine(args["head" .. i])
		if head then
			saw_head = true
		end
		translit = ine(args["tr" .. i])
	end
	data.no_redundant_head_cat = not saw_head

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	local unused_key_list = require "Module:table".keysToList(unused_keys)
	if #unused_key_list > 0 then
		local unused_key_string =
			require "Module:array"(unused_key_list):map(
			function(key)
				return "|" .. key .. "=" .. args[key]
			end
		):concat("\n")
		error("Unused arguments: " .. unused_key_string)
	end

	return require("Module:headword").full_headword(data)
end

-- Get a list of inflections. See handle_infl() for meaning of ARGS, ARGPREF
-- and DEFGENDER.
local function getargs(args, argpref, defgender)
	-- Gather parameters
	local forms = {}

	if ine(args[position]) then
		form = ine(args[position])
	else
		form = ine(args[argpref])
	end

	local translit = ine(args[argpref .. "tr"])
	local gender = ine(args[argpref .. "g"])
	local gender2 = ine(args[argpref .. "g2"])
	local i = 1

	while form do
		local genderlist = (gender or gender2) and {gender, gender2} or defgender and {defgender} or nil

		table.insert(forms, {term = form, tr = translit, genders = genderlist})

		i = i + 1
		form = ine(args[argpref .. i])
		translit = ine(args[argpref .. i .. "tr"])
		gender = ine(args[argpref .. i .. "g"])
		gender2 = ine(args[argpref .. i .. "g2"])
	end

	return forms
end

local function handle_infl(args, data, argpref, label, defgender, position)
	local newinfls = getargs(args, argpref, defgender, position)
	newinfls.label = label

	if #newinfls > 0 then
		table.insert(data.inflections, newinfls)
	end
end

local function handle_all_infl(args, data, argpref, label, nobase, position)
	if not nobase and argpref ~= "" then
		handle_infl(args, data, argpref, label, nil, position)
	end

	local labelsp = label == "" and "" or label .. " "
	handle_infl(args, data, argpref .. "cons", labelsp .. "construct state")
end

-- Handle the case where pl=-, indicating an uncountable noun.
local function handle_noun_plural(args, data)
	if args["pl"] == "-" then
		table.insert(data.inflections, {label = "usually [[Appendix:Glossary#uncountable|uncountable]]"})
		append_cat(data, "uncountable nouns")
	else
		handle_infl(args, data, "pl", "plural")
		handle_infl(args, data, "pauc", "paucal")
	end
end

local valid_genders =
	list_to_set(
	{
		"s",
		"m",
		"m-s",
		"f",
		"f-s",
		"m-p",
		"f-p",
		"p",
		"d",
		"m-d",
		"f-d",
		"mfbysense",
		"mf"
	}
)

local function handle_gender(args, data, default, nonlemma, optional)
	local g = ine(args["g"]) or default
	local g2 = ine(args["g2"])

	local function process_gender(gender)
		if not gender and not optional then
			table.insert(data.genders, "?")
		elseif not gender and optional then
			-- do nothing
		elseif valid_genders[g] then
			table.insert(data.genders, gender)
		else
			error("Unrecognized gender: " .. gender)
		end
	end

	process_gender(g)
	if g2 then
		process_gender(g2)
	end

	if nonlemma then
		return
	end

	if g and g2 then
		append_cat(data, "nouns with multiple genders")
	end
end

-- Part-of-speech functions

pos_functions["adjectives"] = {
	func = function(args, data)
		if args[1] == "-" then
			local forms = {}
			forms.label = "invariable"
			table.insert(data.inflections, forms)
		else
			handle_all_infl(args, data, "f", "feminine")
			handle_all_infl(args, data, "cpl", "common plural")
			handle_all_infl(args, data, "pl", "masculine plural")
			handle_all_infl(args, data, "fpl", "feminine plural")
			handle_all_infl(args, data, "dim", "diminutive")
			handle_infl(args, data, "el", "elative")
			if ine(args["der"]) then
				if args["der"] == "active" then
					append_cat(data, "terms derived from active participles")
				elseif args["der"] == "passive" then
					append_cat(data, "terms derived from passive participles")
				end
			end
		end
	end
}

function handle_sing_coll_noun_infls(args, data)
	handle_infl(args, data, "", "")
	handle_infl(args, data, "d", "dual")
	handle_infl(args, data, "pauc", "paucal")
	handle_infl(args, data, "pl", "plural")
end

pos_functions["collective nouns"] = {
	func = function(args, data)
		data.pos_category = "nouns"
		append_cat(data, "collective nouns")
		table.insert(data.inflections, {label = glossary_link("collective")})

		handle_gender(args, data, "m")
		-- Handle sing= (the corresponding singulative noun) and singg= (its gender)
		handle_infl(args, data, "sing", "singulative", "f")
		handle_sing_coll_noun_infls(args, data)
	end
}

pos_functions["singulative nouns"] = {
	func = function(args, data)
		data.pos_category = "nouns"
		append_cat(data, "singulative nouns")
		table.insert(data.inflections, {label = glossary_link("singulative")})

		handle_gender(args, data, "f")
		-- Handle coll= (the corresponding collective noun) and collg= (its gender)
		handle_infl(args, data, "coll", "collective", "m")
		handle_sing_coll_noun_infls(args, data)
	end
}

function handle_noun_infls(args, data, singonly)
	handle_all_infl(args, data, "", "")

	if not singonly then
		handle_all_infl(args, data, "d", "dual")
		handle_noun_plural(args, data)
		handle_all_infl(args, data, "pl", "plural", "nobase")
		handle_all_infl(args, data, "pauc", "paucal", "nobase")
	end

	handle_all_infl(args, data, "f", "feminine")
	handle_all_infl(args, data, "m", "masculine")

	if not singonly then
		handle_all_infl(args, data, "dim", "diminutive")
	end
end

pos_functions["nouns"] = {
	func = function(args, data)
		handle_gender(args, data)
		handle_noun_infls(args, data)

		local g = ine(args["g"]) or default
		local g2 = ine(args["g2"])
	end
}

pos_functions["verbal nouns"] = {
	func = function(args, data)
		handle_gender(args, data)
		handle_infl(args, data, "inst", "instance noun")
	end
}

pos_functions["numerals"] = {
	func = function(args, data)
		append_cat(data, "cardinal numbers")
		handle_gender(args, data, nil, nil, true)
		handle_noun_infls(args, data)
	end
}

pos_functions["proper nouns"] = {
	func = function(args, data)
		handle_gender(args, data)
		handle_noun_infls(args, data, "singular only")
	end
}

pos_functions["pronouns"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		handle_gender(args, data, nil, nil, true)
		handle_infl(args, data, "encl", "enclitic form")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "pl", "plural")
	end
}

pos_functions["adjective feminine forms"] = {
	params = {
		["g"] = {},
		["g2"] = {},
		["pl"] = {},
		["islemma"] = {type = boolean}
	},
	func = function(args, data)
		data.pos_category = "adjective feminine forms"
		handle_noun_plural(args, data)
		handle_gender(args, data, "f", "nonlemma")
	end
}

pos_functions["adjective plural forms"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		data.pos_category = "adjective plural forms"
		handle_gender(args, data, "p", "nonlemma")
	end
}

pos_functions["noun forms"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		handle_gender(args, data, nil, "nonlemma")
	end
}

pos_functions["noun dual forms"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		append_cat(data, "noun dual forms")
		handle_gender(args, data, "m-d", "nonlemma")
	end
}

pos_functions["active participles"] = {
	params = {
		[2] = {}
	},
	func = function(args, data)
		data.pos_category = "participles"
		append_cat(data, "active participles")
		handle_infl(args, data, "", "")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "cpl", "common plural")
		handle_infl(args, data, "pl", "masculine plural")
		handle_infl(args, data, "fpl", "feminine plural")
	end
}

pos_functions["passive participles"] = {
	params = {
		[2] = {}
	},
	func = function(args, data)
		data.pos_category = "participles"
		append_cat(data, "passive participles")
		handle_infl(args, data, "", "")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "cpl", "common plural")
		handle_infl(args, data, "pl", "masculine plural")
		handle_infl(args, data, "fpl", "feminine plural")
	end
}

local verb_forms = {
	["I"] = true,
	["II"] = true,
	["III"] = true,
	["IV"] = true,
	["V"] = true,
	["VI"] = true,
	["VII"] = true,
	["VIII"] = true,
	["IX"] = true,
	["X"] = true,
	["XI"] = true,
	["Iq"] = true,
	["IIq"] = true
}

local lang_exception = { ["ajp"] = true, ["acy"] = true}

pos_functions["verbs"] = {
	func = function(args, data)
		data.pos_category = "verbs"
		if ine(args[1]) then
			if verb_forms[args[1]] then
				data.gloss = '<abbr title="Form ' .. args[1] .. '">[[Appendix:Arabic verbs#Form ' .. args[1] .. '|' .. args[1] .. ']]</abbr>'
				append_cat(data, "form-" .. args[1] .. " verbs")
			else
				error("Invalid verb form. Please provide a valid one.")
			end
		elseif mw.title.getCurrentTitle().nsText ~= "Template" or args[1] ~= "-" then
			track("verbs lacking forms")
		end
		if lang_exception[lang:getCode()]  then
			handle_infl(args, data, "pres", "present")
			handle_infl(args, data, "subj", "subjunctive")
		else handle_infl(args, data, "np", "non-past") end
		handle_infl(args, data, "vn", "verbal noun")
		handle_infl(args, data, "ap", "active participle")
		handle_infl(args, data, "pp", "passive participle")
	end
}

local function handle_conj_form(args, data)
	local form = ine(args[1])
	if form then
		if not verb_forms[form] then
			error("Invalid verb conjugation form " .. form)
		end

		table.insert(data.inflections, {label = "[[Appendix:Arabic verbs#Form " .. form .. "|form " .. form .. "]]"})
	end
end

pos_functions["verb forms"] = {
	params = {
		[1] = {}
	},
	func = function(args, data)
		handle_conj_form(args, data)
	end
}

pos_functions["prepositions"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		if ine(args["g"]) or ine(args["g2"]) then
			handle_gender(args, data)
		end
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "pl", "plural")
	end
}

pos_functions["determiners"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		handle_gender(args, data, nil, nil, true)
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "pl", "plural")
	end
}

pos_functions["adverbs"] = {
	func = function(args, data)
		handle_infl(args, data, "obl", "oblique form")
	end
}

pos_functions["suffixes"] = {
	params = {
		["g"] = {}
	},
	func = function(args, data)
		handle_gender(args, data, nil, nil, true)
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "pl", "plural")
	end
}

return export
