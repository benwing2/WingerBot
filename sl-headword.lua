local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local langcode = "sl"
local lang = require("Module:languages").getByCode(langcode, true)
local langname = lang:getCanonicalName()

local require_when_needed = require("Module:utilities/require when needed")
local m_str_utils = require("Module:string utilities")
local m_table = require("Module:table")
local com = require("Module:sl-common")
local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_data_module = "Module:headword/data"
local headword_utilities_module = "Module:headword utilities"
local links_module = "Module:links"
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local u = m_str_utils.char
local rfind = m_str_utils.find
local ulower = m_str_utils.lower
local unfd = mw.ustring.toNFD

local list_param = {list = true, disallow_holes = true}

-- Table of all valid genders, mapping user-specified gender specs to canonicalized versions.
local valid_genders = {
	["m"] = "m-an?",
	["?"] = true,
	["mfbysense-an"] = true,
	["m-an"] = true,
	["m-in"] = true,
	["f"] = true,
	["n"] = true,
	["m-d"] = true,
	["f-d"] = true,
	["n-d"] = true,
	["m-p"] = true,
	["f-p"] = true,
	["n-p"] = true,
}
	
-- Table of all valid aspects.
local valid_aspects = m_table.listToSet {
	"impf", "pf", "both", "biasp", "?",
}

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(track_id, pos)
	local tracking_pages = {}
	table.insert(tracking_pages, "sl-headword/" .. track_id)
	if pos then
		table.insert(tracking_pages, "sl-headword/" .. track_id .. "/" .. pos)
	end
	require("Module:debug/track")(tracking_pages)
	return true
end

local function check_accents_and_tones(term, pos, data)
	if term:find("%[") then
		term = require(links_module).remove_links(term)
	end

	if com.needs_accents(term) then
		table.insert(data.categories, ("Requests for accents in %s %s entries"):format(langname, pos))
	end

	-- Tone check
	local found_tonal = false
	local found_stress = false
	local found_ambiguous = false
	term = ulower(term)
	
	if rfind(term, "[ȃȇȋȏȗȓāēīōūȁȅȉȍȕẹọ" .. u(0x0304) .. "]") then
		found_tonal = true
	end
	
	if rfind(term, "[êô]") then
		found_stress = true
	end
	
	if rfind(term, "[áéíóúŕàèìòù]") then
		found_ambiguous = true
	end
	
	if found_stress then
		track("stress", pos)
	elseif found_ambiguous then
		track("ambiguous", pos)
	elseif found_tonal then
		track("tonal", pos)
	end
end
		
local function make_check_accents_frob(pos, data)
	return function(term)
		check_accents_and_tones(term, pos, data)
		return term
	end
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- sections enclosed in <<...>> are linked to the glossary. `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(pos, data, args, field, label, accel)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		label = label,
		accel = accel and {form = accel} or nil,
		frob = make_check_accents_frob(pos, data),
	}
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local iparams = {
		[1] = {},
		["def"] = {},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1]
	local def = iargs.def

	local parargs = frame:getParent().args
	local headarg
	if poscat then
		headarg = 1
	else
		headarg = 2
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local params = {
		[headarg] = {list = "head", required = true, disallow_holes = true, template_default = def},
		["id"] = true,
		["sort"] = true,
		-- no nolinkhead= because head in 1= is always specified
		["json"] = {type = "boolean"},
		["pagename"] = true, -- for testing
	}
	if headarg == 2 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

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

	local pagename = args.pagename or mw.loadData(headword_data_module).pagename

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = args[headarg],
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		is_suffix = false,
	}

	local singular_poscat = require(en_utilities_module).singularize(poscat)

	if pagename:find("^%-") and poscat ~= "suffix forms" then
		data.is_suffix = true
		data.pos_category = "suffixes"
		table.insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		table.insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	for i, head in ipairs(data.heads) do
		if head == "-" then
			-- For abbreviations and the like.
			track("head-hyphen", singular_poscat)
			data.heads[i] = pagename
		elseif head == "?" then
			track("head-question-mark", singular_poscat)
			table.insert(data.categories, ("Requests for accents in %s %s entries"):format(langname, singular_poscat))
			data.heads[i] = pagename
		else
			check_accents_and_tones(head, singular_poscat, data)
		end
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	-- unfd (mw.ustring.toNFD) performs decomposition, so letters that decompose to an ASCII vowel and a diacritic,
	-- such as é, are counted as vowels and do not need to be included in the pattern.
	if not pagename:find("[ %-]") and not rfind(ulower(unfd(pagename)), "[aeiou]") then
		table.insert(data.categories, langname .. " words without vowels")
	end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
	return require(headword_module).full_headword(data)
end

local function get_noun_params(is_proper)
	return function(lang)
		params = {
			[2] = {alias_of = "g"},
			["g"] = {type = "genders", required = true, template_default = "?"},
			["indecl"] = {type = "boolean"},
			["m"] = list_param,
			["f"] = list_param,
			["adj"] = list_param,
			["pos"] = list_param,
			["dim"] = list_param,
			["aug"] = list_param,
			["pej"] = list_param,
			["dem"] = list_param,
			["fdem"] = list_param,
			["gen"] = list_param,
			["pl"] = list_param,
			["genpl"] = list_param,
		}
		return params
	end
end

local function do_nouns(is_proper, args, data)
	for _, g in ipairs(args.g) do
		local canon_g = valid_genders[g.spec]
		if canon_g then
			track("gender-" .. g.spec)
			if canon_g ~= true then
				g.spec = canon_g
			end
			-- Categorize by gender, in addition to what's done already by [[Module:gender and number]].
			if g.spec == "m-an" then
				table.insert(data.categories, langname .. " masculine animate nouns")
			elseif g.spec == "m-in" then
				table.insert(data.categories, langname .. " masculine inanimate nouns")
			end
		else
			error("Unrecognized gender: '" .. g.spec .. "'")
		end
	end
	data.genders = args.g
	if #data.genders == 0 then
		table.insert(data.genders, "?")
	end
	if args.indecl then
		table.insert(data.inflections, {label = glossary_link("indeclinable")})
		table.insert(data.categories, langname .. " indeclinable nouns")
	end

	-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
	-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
	-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil. `frob` is a
	-- function to apply to the values before storing.
	local function handle_infl(field, label, frob)
		parse_and_insert_inflection("noun", data, args, field, label)
	end

	handle_infl("gen", "<<genitive>> <<singular>>")
	handle_infl("pl", "<<nominative>> <<plural>>")
	handle_infl("genpl", "<<genitive>> <<plural>>")
	handle_infl("m", "male equivalent")
	handle_infl("f", "female equivalent")
	handle_infl("adj", "<<relational adjective>>")
	handle_infl("pos", "<<possessive adjective>>")
	handle_infl("dim", "<<diminutive>>")
	handle_infl("aug", "<<augmentative>>")
	handle_infl("pej", "<<pejorative>>")
	handle_infl("dem", "<<demonym>>")
	handle_infl("fdem", "female <<demonym>>")
end

pos_functions["nouns"] = {
	 params = get_noun_params(false),
	 func = function(args, data)
	 	return do_nouns(false, args, data)
	 end,
}

pos_functions["proper nouns"] = {
	 params = get_noun_params("proper noun"),
	 func = function(args, data)
	 	return do_nouns("proper noun", args, data)
	 end,
}

pos_functions["verbs"] = {
	params = {
		[2] = {default = "?", type = "genders"},
		["pf"] = list_param,
		["impf"] = list_param,
	},
	func = function(args, data)
		for _, a in ipairs(args[2]) do
			if a.spec == "both" then
				a.spec = "biasp"
			end
			if valid_aspects[a.spec] then
				track("aspect-" .. a.spec)
			else
				error("Unrecognized aspect: '" .. a.spec .. "'")
			end
			if a.spec == "impf" and args.impf[1] then
				error("Imperfective verbs cannot have an imperfective equivalent")
			elseif a.spec == "pf" and args.pf[1] then
				error("Perfective verbs cannot have a perfective equivalent")
			end
		end
		data.genders = args[2]

		parse_and_insert_inflection("verb", data, args, "pf", "perfective")
		parse_and_insert_inflection("verb", data, args, "impf", "imperfective")
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
			frob = make_check_accents_frob(pos, data),
		}
		local sups = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = {3, "sup"},
			forms = args[3],
			frob = make_check_accents_frob(pos, data),
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
	params = function(lang)
		local params = {
			[2] = {list = "comp", disallow_holes = true},
			[3] = {list = "sup", disallow_holes = true},
			["adv"] = list_param,
			["indecl"] = {type = "boolean"},
		}
		return params
	end,
	func = function(args, data)
		if args.indecl then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, langname .. " indeclinable adjectives")
		end
		do_comparative_superlative("adjective", data, args)
		parse_and_insert_inflection("adjective", data, args, "adv", "adverb")
	end,
}

pos_functions["adverbs"] = {
	params = {
		[2] = {list = "comp", disallow_holes = true},
		[3] = {list = "sup", disallow_holes = true},
	},
	func = function(args, data)
		do_comparative_superlative("adverb", data, args)
	end,
}

return export
