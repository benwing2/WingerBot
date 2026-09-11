local lang = require("Module:languages").getByCode("akk")

local export = {}
local pos_functions = {}

local u = mw.ustring.char

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
	for _, item in ipairs(list) do set[item] = true end
	return set
end

-- version of mw.ustring.gsub() that discards all but the first return value
function rsub(term, foo, bar)
	local retval = mw.ustring.gsub(term, foo, bar)
	return retval
end

local rfind = mw.ustring.find

-- Tracking functions

local trackfn = require("Module:debug").track

function track(page)
	trackfn("akk-headword/" .. page)
	return true
end

local function append_cat(data, pos)
	table.insert(data.categories, lang:getCanonicalName() .. " " .. pos)
end

function remove_links(text)
	text = rsub(text, "%[%[[^|%]]*|", "")
	text = rsub(text, "%[%[", "")
	text = rsub(text, "%]%]", "")
	return text
end

local function make_unused_key_tracker(t)
	local unused_keys = require"Module:table".listToSet(
							require"Module:table".keysToList(t))
	local mt = {
		__index = function(self, key)
			if key ~= nil then unused_keys[key] = nil end
			return t[key]
		end,
		__newindex = function(self, key, value) t[key] = value end
	}
	local proxy_table = setmetatable({}, mt)
	return proxy_table, unused_keys
end

-- The main entry point.
function export.show(frame)

	local PAGENAME = mw.loadData("Module:headword/data").pagename

	local poscat = frame.args[1] or error(
					   "Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local params = {
		[1] = {list = "head", allow_holes = true, default = ""},
		["head"] = {default = ""},
		["tr"] = {list = true, allow_holes = true}
	}

	local args, unused_keys = make_unused_key_tracker(frame:getParent().args)

	-- Gather parameters
	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = {},
		translits = {},
		transcriptions = {},
		genders = {},
		inflections = {}
	}

	local head = args["head"] or PAGENAME or ""
	local translit = ine(args["tr"])
	local transcriptions = ine(args["ts"])
	local i = 1

	while head do
		table.insert(data.heads, head)
		data.translits[#data.heads] = translit
		data.transcriptions[#data.heads] = transcriptions

		i = i + 1
		head = ine(args["head" .. i])
		translit = ine(args["tr" .. i])
		transcriptions = ine(args["ts" .. i])
	end

	if pos_functions[poscat] then pos_functions[poscat].func(args, data) end

	local unused_key_list = require"Module:table".keysToList(unused_keys)
	if #unused_key_list > 0 then
		local unused_key_string = require "Module:array"(unused_key_list):map(
									  function(key)
				return "|" .. key .. "=" .. args[key]
			end):concat("\n")
		error("Unused arguments: " .. unused_key_string)
	end

	return require("Module:headword").full_headword(data)
end

local function getargs(args, argpref, defgender)

	local forms = {}

	form = ine(args[argpref])

	local gender = ine(args[argpref .. "g"])
	local gender2 = ine(args[argpref .. "g2"])
	local i = 1

	while form do
		local genderlist = (gender or gender2) and {gender, gender2} or
							   defgender and {defgender} or nil

		table.insert(forms, {term = form, genders = genderlist})

		i = i + 1
		form = ine(args[argpref .. i])
		gender = ine(args[argpref .. i .. "g"])
		gender2 = ine(args[argpref .. i .. "g2"])
	end

	return forms
end

local function handle_infl(args, data, argpref, label, defgender, position)
	local newinfls = getargs(args, argpref, defgender, position)
	newinfls.label = label

	if #newinfls > 0 then table.insert(data.inflections, newinfls) end
end

local function handle_all_infl(args, data, argpref, label, nobase, position)
	if not nobase and argpref ~= "" then
		handle_infl(args, data, argpref, label, nil, position)
	end
end

local valid_genders = list_to_set({
	"mf", "s", "m", "m-s", "f", "f-s", "m-p", "f-p", "p", "d", "m-d", "f-d"
})

local function is_masc_sg(g)
	return g == "m" or g == "m-s" or g == "m-p" or g == "m-d"
end

local function is_fem_sg(g)
	return g == "f" or g == "f-s" or g == "f-p" or g == "f-d"
end

local function handle_gender(args, data, default, nonlemma)

	local PAGENAME = mw.loadData("Module:headword/data").pagename

	local g = ine(args[1]) or default
	local g2 = ine(args["g2"])

	local function process_gender(g)
		if not g then
			table.insert(data.genders, "?")
		elseif valid_genders[g] then
			table.insert(data.genders, g)
		else
			error("Unrecognized gender: " .. g)
		end
	end

	process_gender(g)
	if g2 then process_gender(g2) end
end

-- Part-of-speech functions

function handle_noun_infls(args, data, singonly)

	handle_all_infl(args, data, "base", "base")
	handle_all_infl(args, data, "cons", "construct state")
	handle_all_infl(args, data, "pron", "pronominal state")
	handle_all_infl(args, data, "abs", "absolute state")

	handle_all_infl(args, data, "", "")

	if not singonly then
		handle_all_infl(args, data, "d", "dual")
		handle_infl(args, data, "pl", "plural")
	end

	handle_all_infl(args, data, "f", "feminine")
	handle_all_infl(args, data, "m", "masculine")
end

pos_functions["nouns"] = {
	func = function(args, data)
		handle_gender(args, data)
		handle_noun_infls(args, data)
	end
}

pos_functions["suffixes"] = {
	func = function(args, data) handle_infl(args, data, "pl", "plural") end
}

pos_functions["adjectives"] = {
	func = function(args, data)
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "mpl", "masculine plural")
		handle_infl(args, data, "fpl", "feminine plural")
		handle_infl(args, data, "pred", "predicative")		
	end
}

local verb_stems = {
	["G"] = true,
	["D"] = true,
	["Š"] = true,
	["N"] = true,
	["Gt"] = true,
	["Dt"] = true,
	["Št"] = true,
	["Nt"] = true,
	["Gtn"] = true,
	["Dtn"] = true,
	["Štn"] = true,
	["Ntn"] = true,
	["ŠD"] = true
}

local function handle_stem(args, data)
	local stem = args[1]
	if ine(stem) then
		if verb_stems[stem] then
			table.insert(data.inflections, {
				label = '[[w:Akkadian_language#Verb_patterns|' .. stem ..
					']]'
			})
			append_cat(data, stem .. "-stem verbs")
		else
			error("Invalid verb stem. Please provide a valid one.")
		end
	elseif stem ~= "-" then
		append_cat(data, "verbs lacking stems")
	end
end

local function handle_class(args, data)
	local class = {args[2], args[3]}
	local label
	if class[1] ~= nil then
		label = '[[w:Akkadian_language#Verb_patterns|' .. class[1] .. ']]'
		append_cat(data, "class " .. class[1] .. " verbs")
	end
	if class[2] ~= nil then
		if label then
			label = label .. " or "
		end
		label = label .. '[[w:Akkadian_language#Verb_patterns|' .. class[2] .. ']]'
		append_cat(data, "class " .. class[2] .. " verbs")
	end
	if label then
		table.insert(data.inflections, { label = label })
	end
end

pos_functions["verbs"] = {
	func = function(args, data)
		handle_stem(args, data)
		handle_class(args, data)
		handle_infl(args, data, "dur", "durative")
		handle_infl(args, data, "perf", "perfect")
		handle_infl(args, data, "pret", "preterite")
		handle_infl(args, data, "imp", "imperative")
		handle_infl(args, data, "partic", "participle")
		handle_infl(args, data, "vadj", "verbal adjective")
	end
}

pos_functions["proper nouns"] = {
	func = function(args, data)
		handle_gender(args, data)
	end
}

return export
