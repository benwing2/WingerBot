local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local mn = require("Module:mn-common")

local lang = require(languages_module).getByCode("su")

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|mn-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		include_sc = true,
		force_cat = force_cat,
		augment_params = function(data)
			data.params.sun = true
		end,
		augment_headdata = function(data)
			local headdata = data.headdata
			local sc = headdata.sc
			if headdata.var == nil then
				headdata.var = sc:getCode() ~= "Latn"
			end
			local suns = headdata:parse_inflection("sun")
			if not suns[1] and sc:getCode() == "Latn" then
				suns[1] = {term = require("Module:su-Latn-Sund-translit").tr(headdata.pagename)}
			end
			headdata:insert_inflection(suns, "Sundanese spelling")
		end,
	}
end

pos_functions["nouns"] = {
	params = {
		pl = true,
		dec = {set = {"r", "n", "g", "m"}},
	},
	func = function(data, args)
		data:parse_and_insert_inflection("pl", "definite plural")
		if args.dec then
			local declension
			if args.dec == "r" then
				declension = "regular declension"
			elseif args.dec == "n" then
				declension = "hidden-n declension"
			elseif args.dec == "g" then
				declension = "hidden-g declension"
			elseif args.dec == "m" then
				declension = "mixed declension"
			else
				error(("Internal error: Unrecognized declension value: dec=%s"):format(args.dec))
			end
			data:insert_category(declension .. " PLPOS")
			data:insert_fixed_inflection(declension)
		end
	end,
}
pos_functions["proper nouns"] = pos_functions["nouns"]

local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("su")

local insert = table.insert

-----------------------
-- Utility functions --
-----------------------

local function otherscript(inflections, args)
	local title = mw.title.getCurrentTitle()
	local sc = lang:findBestScript(title.subpageText)

	local tr = args.tr
	if sc:getCode() == "Latn" then
		local inflection = {label = "Sundanese script"}

		insert(inflection, {term = tr})
		insert(inflections, inflection)
	end
end

-- The main entry point.
function export.show(frame)

	local PAGENAME = mw.loadData("Module:headword/data").pagename

	local poscat = frame.args[1] or error(
		"Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local params = {
		head = {list = true},
		tr = true,
	}

	if pos_functions[poscat] then
		for key, val in pairs(pos_functions[poscat].params) do
			params[key] = val
		end
	end

	local args = require("Module:parameters").process(frame:getParent().args, params)

	-- Gather parameters
	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = {},
		translits = {},
		inflections = {},
	}

	otherscript(data.inflections, args)

	if pos_functions[poscat] then pos_functions[poscat].func(data, args) end

	return require("Module:headword").full_headword(data)
end

pos_functions["verbs"] = {
	params = {
		[1] = { list = true },
		active = { list = true },
		passive = { list = true },
	},
	func = function(data, args)
		local base = data.pagename

		if args[1] and args[1][1] == "+" then
			-- Default generation for both
			local active_form = "nga" .. base
			local passive_form = "di" .. base

			-- Count vowels
			local vowel_count = 0
			for _ in mw.ustring.gmatch(base, "[aiueo]") do
				vowel_count = vowel_count + 1
				if vowel_count > 1 then break end
			end

			if vowel_count == 1 then
				active_form = "nge" .. base
			else
				local first_two = mw.ustring.sub(base, 1, 2)
				local first = mw.ustring.sub(base, 1, 1)

				if first_two == "sy" then
					active_form = "nga-"	.. base
				elseif first_two == "pl" then
					active_form = "nga"	.. base
				elseif first_two == "pr" then
					active_form = "nga"	.. base
				elseif first_two == "tr" then
					active_form = "nga"	.. base
				elseif first_two == "kl" then
					active_form = "nga"	.. base
				elseif first_two == "kr" then
					active_form = "nga"	.. base
				elseif first_two == "kh" then
					active_form = "nga" .. base
				elseif first == "k" then
					active_form = "ng" .. mw.ustring.sub(base, 2)
				elseif first == "t" then
					active_form = "n"	.. mw.ustring.sub(base, 2)
				elseif first == "s" then
					active_form = "ny" .. mw.ustring.sub(base, 2)
				elseif first == "c" then
					active_form = "ny" .. mw.ustring.sub(base, 2)
				elseif first == "p" then
					active_form = "m"	.. mw.ustring.sub(base, 2)
				elseif first:match("[aiueo]") then
					active_form = "ng" .. base
				end
			end

			args.active = { active_form }
			args.passive = { passive_form }

		else
			-- If only active is specified, still generate passive
			if args.active and args.active[1] and (not args.passive or not args.passive[1]) then
				args.passive = { "di" .. base }
			end
		end

		-- Emit inflections
		if args.active and args.active[1] then
			args.active.label = "active"
			table.insert(data.inflections, args.active)
		end
		if args.passive and args.passive[1] then
			args.passive.label = "passive"
			table.insert(data.inflections, args.passive)
		end
	end,
}

pos_functions["nouns"] = {
	params = {
		[1] = {list = "def"},
	},
	func = function(data, args)
		data:parse_and_insert_inflection("def", "definite")
	end
}

return export
