local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("id")

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local iparams = {
		[1] = {required = true},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1]

	local parargs = frame:getParent().args

	local params = {
		["head"] = {list = true, disallow_holes = true},
		["id"] = true,
		["sort"] = true,
		["nolinkhead"] = {type = "boolean"},
		["json"] = {type = "boolean"},
		["pagename"] = true, -- for testing
	}

	if pos_functions[poscat] then
		local posparams = pos_functions[poscat].params
		if type(posparams) == "function" then
			posparams = posparams(lang)
		end
		for key, val in pairs(posparams) do
			params[key] = val
		end
	end

    local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.title.getCurrentTitle().text

	local user_specified_heads = args.head
	local heads = user_specified_heads
	if args.nolinkhead then
		if #heads == 0 then
			heads = {pagename}
		end
	end

	for i, head in ipairs(heads) do
		if head == "+" or head == "*" then
			head = nil
		end
		heads[i] = {
			term = head,
			tr = "-",
		}
	end

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = heads,
		user_specified_heads = user_specified_heads,
		no_redundant_head_cat = #user_specified_heads == 0,
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		is_suffix = false,
	}

	if pagename:find("^%-") and poscat ~= "suffix forms" then
		data.is_suffix = true
		data.pos_category = "suffixes"
		table.insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		table.insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

    if pos_functions[poscat] and pos_functions[poscat].func then
        pos_functions[poscat].func(args, data)
    end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
    return require("Module:headword").full_headword(data)
end

-- Function for nouns (common and proper)

local function make_default_plural(pagename)
	-- Auto-detect full reduplication
	if pagename:match("^([a-zA-Z]+)%-%1$") then
		return "[[" .. pagename .. "]]"
	end

	local subwords = mw.text.split(pagename, "%s")
	local firstword = subwords[1]
	subwords[1] = mw.ustring.gsub("[[" .. firstword .. "]]-[[" .. firstword .. "]]", "([a-z]+%-)%1%1", "banyak %1")
	return table.concat(subwords, " ")
end

-- Shortcuts for the plural markings
pos_functions["nouns"] = {
	params = {
		[1] = {list = "pl"},
		["pl"] = {alias_of = 1},
	},
	func = function(args, data)
		-- Main code for noun plurality

		local pl1 = args[1][1]
		-- Unknown or uncertain and requests
		if pl1 == "req" then
			table.insert(data.categories, "Requests for plural forms in Indonesian entries")
		elseif pl1 == "?" then
			table.insert(data.categories, "Indonesian nouns with unknown or uncertain plurals")
		
		-- Uncountable and semi-countable
		elseif pl1 == "-" then
			table.insert(data.categories, "Indonesian uncountable nouns")
			table.insert(data.inflections, {label = "[[Appendix:Glossary#uncountable|uncountable]]"})
		elseif pl1 == "0" then
			table.insert(data.categories, "Indonesian uncountable nouns")
		elseif pl1 == "u" then
			local pl_countable = {label = "usually [[Appendix:Glossary#uncountable|uncountable]]"}
			local pl_plural = {label = "plural"}
			table.insert(data.categories, "Indonesian countable nouns")
			table.insert(data.categories, "Indonesian uncountable nouns")
			table.insert(pl_plural, make_default_plural(data.pagename))
			table.insert(data.inflections, pl_countable)
			table.insert(data.inflections, pl_plural)
		elseif pl1 == "~" then
			local pl_countable = {label = "[[Appendix:Glossary#countable|countable]] and [[Appendix:Glossary#uncountable|uncountable]]"}
			local pl_plural = {label = "plural"}
			table.insert(data.categories, "Indonesian countable nouns")
			table.insert(data.categories, "Indonesian uncountable nouns")
			table.insert(pl_plural, make_default_plural(data.pagename))
			table.insert(data.inflections, pl_countable)
			table.insert(data.inflections, pl_plural)
		elseif pl1 == "pt" or pl1 == "p" then
			table.insert(data.categories, "Indonesian pluralia tantum")
			table.insert(data.inflections, {label = "[[Appendix:Glossary#plurale tantum|plurale tantum]]"})
		elseif pl1 == "st" or pl1 == "s" then
			table.insert(data.categories, "Indonesian singularia tantum")
			table.insert(data.inflections, {label = "[[Appendix:Glossary#singulare tantum|singulare tantum]]"})
		elseif pl1 == "1" then
			error("The parameter |pl=1 is invalid. Please specify the plurality with an existing value.")
		else
			-- Countable
			local pl = {label = "plural"}
			if not pl1 or pl1 == "+" then
				table.insert(pl, make_default_plural(data.pagename))
			elseif pl1 == "a" then
				table.insert(pl, make_default_plural(data.pagename))
				table.insert(pl, "[[para]] " .. data.pagename)
			elseif pl1 == "*" then
				table.insert(pl, data.pagename)
			else
				table.insert(pl, pl1)
			end
			for i = 2, #args[1] do
				table.insert(pl, args[1][i])
			end
			table.insert(data.inflections, pl)
		end
		
		if args[1][2] then -- Only for tracking purpose
			require("Module:debug/track")("id-noun/pl2")
		end
		if args[1][3] then -- Only for tracking purpose
			require("Module:debug/track")("id-noun/pl3")
		end
	end
}

pos_functions["verbs"] = {
	params = {
		active = {list = true},
		passive = {list = true},
	},
	func = function(args, data)
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

return export
