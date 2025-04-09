local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local lang = require("Module:languages").getByCode("id", true)
local langname = lang:getCanonicalName()

local headword_utilities_module = "Module:headword utilities"
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local list_param = {list = true, disallow_holes = true}

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- sections enclosed in <<...>> are linked to the glossary. `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		label = label,
		accel = accel and {form = accel} or nil,
	}
end

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
		["head"] = list_param,
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
			table.insert(data.categories, "Requests for plural forms in " .. langname .. " entries")
		elseif pl1 == "?" then
			table.insert(data.categories, langname .. "nouns with unknown or uncertain plurals")
		
		-- Uncountable and semi-countable
		elseif pl1 == "-" then
			table.insert(data.categories, langname .. "uncountable nouns")
			table.insert(data.inflections, {label = glossary_link("uncountable")})
		elseif pl1 == "0" then
			table.insert(data.categories, langname .. "uncountable nouns")
		elseif pl1 == "u" then
			local pl_countable = {label = "usually " .. glossary_link("uncountable")}
			local pl_plural = {label = "plural"}
			table.insert(data.categories, langname .. "countable nouns")
			table.insert(data.categories, langname .. "uncountable nouns")
			table.insert(pl_plural, make_default_plural(data.pagename))
			table.insert(data.inflections, pl_countable)
			table.insert(data.inflections, pl_plural)
		elseif pl1 == "~" then
			local pl_countable = {label = glossary_link("countable") .. " and " .. glossary_link("uncountable")}
			local pl_plural = {label = "plural"}
			table.insert(data.categories, langname .. "countable nouns")
			table.insert(data.categories, langname .. "uncountable nouns")
			table.insert(pl_plural, make_default_plural(data.pagename))
			table.insert(data.inflections, pl_countable)
			table.insert(data.inflections, pl_plural)
		elseif pl1 == "pt" or pl1 == "p" then
			table.insert(data.categories, langname .. "pluralia tantum")
			table.insert(data.inflections, {label = glossary_link("plurale tantum")})
		elseif pl1 == "st" or pl1 == "s" then
			table.insert(data.categories, langname .. "singularia tantum")
			table.insert(data.inflections, {label = glossary_link("singulare tantum")})
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
		active = list_param,
		passive = list_param,
	},
	func = function(args, data)
		parse_and_insert_inflection(data, args, "active", "active")
		parse_and_insert_inflection(data, args, "passive", "passive")
	end,
}

local function do_comparative_superlative(pos, data, args)
	local plpos = pos .. "s" -- safe because pos is either 'adjective' or 'adverb'
	if args[2][1] == "-" then
		table.insert(data.inflections, {label = "not " .. glossary_link("comparable")})
		table.insert(data.categories, langname .. " uncomparable " .. plpos)
	elseif args[2][1] then
		local comps = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = {2, "comp"},
			forms = args[2],
		}
		local sups = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = {3, "sup"},
			forms = args[3],
		}

		local saw_bolj = false
		for _, comp in ipairs(comps) do
			if comp.term == "bolj" then
				saw_bolj = true
				break
			end
		end

		if saw_bolj then
			local new_comps = {}
			for _, comp in ipairs(comps) do
				if comp.term == "bolj" then
					for _, head in ipairs(data.heads) do
						local new_comp = m_table.deepCopy(comp)
						new_comp.term = "[[bȍlj]] " .. head
						table.insert(new_comps, new_comp)
					end
				else
					table.insert(new_comps, comp)
				end
			end
			comps = new_comps
		end

		if not sups[1] then
			sups = m_table.deepCopy(comps)
			for _, s in ipairs(sups) do
				local term_after_bolj = s.term:match("^%[%[bȍlj%]%] (.*)$")
				if term_after_bolj then
					s.term = "[[nȁjbolj]] " .. term_after_bolj
				else
					s.term = "nȁj" .. s.term
				end
			end
		end

		if comps[1] then
			m_headword_utilities.insert_inflection {
				headdata = data,
				terms = comps,
				label = "comparative"
			}
			m_headword_utilities.insert_inflection {
				headdata = data,
				terms = sups,
				label = "superlative"
			}
			table.insert(data.categories, langname .. " comparable " .. plpos)
		end
	end
end

pos_functions["adjectives"] = {
	params = {
		[2] = {list = "comp", disallow_holes = true},
		[3] = {list = "sup", disallow_holes = true},
		eq = list_param,
	},
	func = function(args, data)
		do_comparative_superlative("adjective", data, args)
	end,
}

pos_functions["adjectives"] = {
	params = {
		active = list_param,
		passive = list_param,
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
