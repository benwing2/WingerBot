local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local langcode = "sh"
local lang = require("Module:languages").getByCode(langcode, true)
local langname = lang:getCanonicalName()

local require_when_needed = require("Module:utilities/require when needed")
local m_str_utils = require("Module:string utilities")
local m_table = require("Module:table")
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
local boolean_param = {type = "boolean"}

-- Table of all valid genders, mapping user-specified gender specs to canonicalized versions.
local valid_genders = {
	["m"] = "m-an?",
	["?"] = true,
	["mfbysense-an"] = true,
	["m-an"] = true,
	["m-in"] = true,
	["f"] = true,
	["n"] = true,
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
	table.insert(tracking_pages, "sh-headword/" .. track_id)
	if pos then
		table.insert(tracking_pages, "sh-headword/" .. track_id .. "/" .. pos)
	end
	require("Module:debug/track")(tracking_pages)
	return true
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
	}
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
-- FIXME: Remove explicit_pos support.
function export.show(frame, explicit_pos)
	local iparams = {
		[1] = {},
		def = {},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1] or explicit_pos
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
		head = {list = true, disallow_holes = true, template_default = def or "књи̏га"},
		[headarg] = {alias_of = "head"},
		-- [headarg] = {list = "head", disallow_holes = true, template_default = def},
		tr = {list = true, allow_holes = true},
		id = true,
		sort = true,
		-- no nolinkhead= because head in 1= should always be specified
		json = boolean_param,
		pagename = true, -- for testing
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

	local sc = lang:findBestScript(pagename)
	
	local other_sc
	
	if sc:getCode() == "Latn" then
		other_sc = "Cyrl"
	elseif sc:getCode() == "Cyrl" then
		other_sc = "Latn"
	end
	
	if other_sc then
		other_sc = require("Module:scripts").getByCode(other_sc)
		local inflection = {label = other_sc:getCanonicalName() .. " spelling"}

		local heads = args["head"]
		if #heads == 0 then
			heads = {pagename}
		end
		
		if args["tr"][1] == "-" then
			inflection.label = "not attested in " .. other_sc:getCanonicalName() .. " spelling"
		else
			for i, head in ipairs(heads) do
				local tr = args["tr"][i]
				
				if not tr then
					tr = require("Module:sh-translit").tr(require("Module:links").remove_links(head), "sh", sc:getCode())
				end
				
				table.insert(inflection, {term = tr, sc = other_sc})
			end
		end
		
		table.insert(inflections, inflection)
	end

	local singular_poscat = require(en_utilities_module).singularize(poscat)

	if pagename:find("^%-") and poscat ~= "suffix forms" then
		data.is_suffix = true
		data.pos_category = "suffixes"
		table.insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		table.insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	-- unfd (mw.ustring.toNFD) performs decomposition, so letters that decompose to an ASCII vowel and a diacritic,
	-- such as é, are counted as vowels and do not need to be included in the pattern.
	if not pagename:find("[ %-]") and not rfind(ulower(unfd(pagename)), "[aeiouаеиоу]") then
		table.insert(data.categories, langname .. " words spelled without vowels")
	end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
	return require(headword_module).full_headword(data)
end

local function get_noun_params(is_proper)
	return {
		[2] = {alias_of = "g"},
		g = {type = "genders", list = true, flatten = true, disallow_holes = true, template_default = "?"},
		indecl = boolean_param,
		m = list_param,
		f = list_param,
		adj = list_param,
		pos = list_param,
		dim = list_param,
		aug = list_param,
		pej = list_param,
		dem = list_param,
		fdem = list_param,
		gen = list_param,
		pl = list_param,
		genpl = list_param,
	}
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
	-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil.
	local function handle_infl(field, label)
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

-- FIXME, rename callers to show()
function export.basic(frame)
	return export.show(frame)
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
		-- FIXME, remove g and a aliases
		g = {alias_of = 2},
		a = {alias_of = 2},
		pf = list_param,
		impf = list_param,
	},
	func = function(args, data)
		for _, a in ipairs(args[2]) do
			if a.spec == "both" then
				a.spec = "biasp"
			end
			if a.spec == "pf-impf" then
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

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil.
		local function handle_infl(field, label)
			parse_and_insert_inflection("verb", data, args, field, label)
		end
		handle_infl("pf", "perfective")
		handle_infl("impf", "imperfective")
	end,
}

pos_functions["adjectives"] = {
	params = {
		def = list_param,
		comp = list_param,
		sup = list_param,
		adv = list_param,
		indecl = boolean_param,
	},
	func = function(args, data)
		if args.indecl then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, langname .. " indeclinable adjectives")
		end
		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil.
		local function handle_infl(field, label)
			parse_and_insert_inflection("adjective", data, args, field, label)
		end
		handle_infl("def", "definite")
		handle_infl("comp", "<<comparative>>")
		handle_infl("sup", "<<superlative>>")
		handle_infl("adv", "derived adverb")
	end,
}

pos_functions["adverbs"] = {
	params = {
		comp = list_param,
		sup = list_param,
	},
	func = function(args, data)
		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil.
		local function handle_infl(field, label)
			parse_and_insert_inflection("adverb", data, args, field, label)
		end
		handle_infl("comp", "<<comparative>>")
		handle_infl("sup", "<<superlative>>")
	end,
}

function export.letter(frame)
	params = {
		["upper"] = true,
		["lower"] = true
	},
	func = function(args, data)
		if args.upper then
			table.insert(data.inflections, {label = "lower case", nil})
			table.insert(data.inflections, {label = "upper case", args.upper})
		elseif args.lower then
			table.insert(data.inflections, {label = "upper case", nil})
			table.insert(data.inflections, {label = "lower case", args.lower})
		end
	end,
end

return export
