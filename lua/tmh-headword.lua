local list_to_set = require("Module:table").listToSet

local lang = require("Module:languages").getByCode("tmh")

local export = {}
local pos_functions = {}

local dialects = {
	["ght"] = { "Ghat" },
	["thv"] = { "Tamahaq" },
	["taq"] = { "Tamasheq" },
	["ttq"] = { "Tawellemmet" },
	["thz"] = { "Tayert" },
}

local function parse_qualifiers(quals)
	if quals == nil then
		return nil
	end

	local list = mw.text.split(quals, ',%s*')
	local qualifiers = { }

	for _, qual in ipairs(list) do
		if dialects[qual] then
			table.insert(qualifiers, dialects[qual][1])
		else
			table.insert(qualifiers, qual)
		end
	end

	return table.concat(qualifiers, ", ")
end

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

-- version of mw.ustring.gsub() that discards all but the first return value
function rsub(term, foo, bar)
	local retval = mw.ustring.gsub(term, foo, bar)
	return retval
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
	local unused_keys = list_to_set(
			require "Module:table".keysToList(t))
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

	local poscat = frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local args, unused_keys = make_unused_key_tracker(frame:getParent().args)

	-- Gather parameters
	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = {},
		translits = {},
		genders = {},
		inflections = { enable_auto_translit = true }
	}

	local head = args["head"] or PAGENAME or ""
	local translit = ine(args["tr"])
	local i = 1

	while head do
		table.insert(data.heads, head)
		data.translits[#data.heads] = translit
		i = i + 1
		head = ine(args["head" .. i])
		translit = ine(args["tr" .. i])
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	local unused_key_list = require "Module:table".keysToList(unused_keys)
	if #unused_key_list > 0 then
		local unused_key_string = require "Module:array"(unused_key_list):map(
				function(key)
					return "|" .. key .. "=" .. args[key]
				end)                                                     :concat("\n")
		error("Unused arguments: " .. unused_key_string)
	end

	return require("Module:headword").full_headword(data)
end

local function getargs(args, argpref, defgender, position)
	-- Gather parameters
	local forms = {}

	local form

	if ine(args[position]) then
		form = ine(args[position])
	else
		form = ine(args[argpref])
	end

	local translit = ine(args[argpref .. "tr"])
	local gender = ine(args[argpref .. "g"])
	local gender2 = ine(args[argpref .. "g2"])
	local qualifiers = ine(args[argpref .. "qual"])

	local i = 1

	while form do
		local genderlist = (gender or gender2) and { gender, gender2 } or
				defgender and { defgender } or nil

		table.insert(forms,
				{ term = form, tr = translit, gender = genderlist, qualifiers = parse_qualifiers(qualifiers) })

		i = i + 1
		form = ine(args[argpref .. i])
		translit = ine(args[argpref .. i .. "tr"])
		gender = ine(args[argpref .. i .. "g"])
		gender2 = ine(args[argpref .. i .. "g2"])
		qualifiers = ine(args[argpref .. i .. "qual"])
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

local function handle_noun_plural(args, data)
	if args["pl"] == "-" then
		table.insert(data.inflections, {
			label = "usually [[Appendix:Glossary#uncountable|uncountable]]"
		})
		append_cat(data, "uncountable nouns")
	else
		handle_infl(args, data, "pl", "plural")
	end
end

local valid_genders = list_to_set{ "m", "f", "m-p", "f-p", "p" }

local function handle_gender(args, data, default, nonlemma)
	local g = ine(args[1]) or default
	local g2 = ine(args["g2"])

	local function process_gender(gender)
		if not gender then
			table.insert(data.genders, "?")
		elseif valid_genders[gender] then
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
		append_cat(data, "terms with multiple genders")
	end
end

-- Part-of-speech functions

pos_functions["adjectives"] = {
	func = function(args, data)
		handle_all_infl(args, data, "", "")
		handle_all_infl(args, data, "f", "feminine")
		handle_all_infl(args, data, "pl", "masculine plural")
		handle_all_infl(args, data, "fpl", "feminine plural")
	end
}

function handle_noun_infls(args, data, singonly)
	handle_all_infl(args, data, "", "")

	if not singonly then
		handle_noun_plural(args, data)
		handle_all_infl(args, data, "pl", "plural", "nobase")
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

pos_functions["verbs"] = {
	func = function(args, data)
		data.pos_category = "verbs"
		handle_all_infl(args, data, "imperf", "imperfective", nil, 1)
		handle_all_infl(args, data, "perf", "perfective", nil, 2)
	end
}

pos_functions["numerals"] = {
	func = function(args, data)
		append_cat(data, "cardinal numbers")
		handle_gender(args, data)
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
	params = { ["g"] = {} },
	func = function(args, data)
		handle_gender(args, data)
		handle_all_infl(args, data, "sa", "subject affix")
	end
}

return export
