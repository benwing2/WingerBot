local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local rfind = mw.ustring.find

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")
local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_string_utilities = require_when_needed("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local list_param = {list = true, disallow_holes = true}

-- Table of all valid genders by language, mapping user-specified gender specs to canonicalized versions.
local valid_gender_specs = {}

local valid_genders_with_animacy = {"mfbysense", "mf", "m"}
local valid_genders_without_animacy = {"f", "n", "?"}
local valid_two_way_animacies = {"an", "in"}
local valid_three_way_animacies = {"pr", "anml", "in"}
local valid_number_suffixes = {"", "-p"}

for _, lang in ipairs { "cs", "sk", "zlw-ocs", "zlw-osk" } do
	valid_gender_specs[lang] = {}
	local dest = valid_gender_specs[lang]
	-- The following is correct; Old Czech has three-way animacy.
	local animacy_src = lang == "cs" and valid_two_way_animacies or valid_three_way_animacies
	for _, gender in ipairs(valid_genders_without_animacy) do
		for _, number in ipairs(valid_number_suffixes) do
			local spec = gender .. number
			dest[spec] = spec
		end
	end
	for _, gender in ipairs(valid_genders_with_animacy) do
		for _, number in ipairs(valid_number_suffixes) do
			for _, animacy in ipairs(animacy_src) do
				local spec = gender .. "-" .. animacy .. number
				dest[spec] = spec
			end
		end
	end
end

-- Table of all valid aspects.
local valid_aspects = m_table.listToSet {
	"impf", "pf", "both", "biasp", "?",
}

local allowed_sk_decl_patterns = m_table.listToSet {
	"chlap", "dievča", "dub", "gazdiná", "hrdina", "kosť", "mesto", "srdce", "stroj", "ulica", "vysvedčenie", "žena",
	-- In use but not in the Appendix
	"dlaň", "idea", "kuli", "pani",
}

local function track(track_id)
	require("Module:debug/track")("cs-sk-headword/" .. track_id)
	return true
end

local function replace_hash_with_lemma(term, lemma)
	-- If there is a % sign in the lemma, we have to replace it with %% so it doesn't get interpreted as a capture
	-- replace expression.
	lemma = m_string_utilities.replacement_escape(lemma)
	return (term:gsub("#", lemma)) -- discard second retval
end

local function frob_term_with_hash(term, lemma)
	if term:find("#") then
		term = replace_hash_with_lemma(term, lemma)
	end
	return term
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- sections enclosed in <<...>> are linked to the glossary. `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel, frob)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		splitchar = ",",
		label = label,
		accel = accel and {form = accel} or nil,
		frob = function(term)
			term = frob_term_with_hash(term, data.pagename)
			if frob then
				term = frob(term)
			end
			return term
		end,
	}
end

-- Parse and return an inflection not requiring additional processing. The raw arguments come from `args[field]`, which
-- is parsed for inline modifiers.
local function parse_inflection(data, paramname, forms)
	return m_headword_utilities.parse_term_list_with_modifiers {
		paramname = paramname,
		forms = forms,
		splitchar = ",",
		frob = function(term)
			return frob_term_with_hash(term, data.pagename)
		end,
	}
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local iparams = {
		[1] = {required = true},
		["lang"] = {required = true},
		["def"] = {},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1]
	local langcode = iargs.lang
	if langcode ~= "cs" and langcode ~= "sk" and langcode ~= "zlw-ocs" and langcode ~= "zlw-osk" then
		error("This module currently only works for lang=cs, lang=sk, lang=zlw-ocs and lang=zlw-osk")
	end
	local lang = require("Module:languages").getByCode(langcode, true)
	local langname = lang:getCanonicalName()
	local def = iargs.def

	local parargs = frame:getParent().args

	local params = {
		["head"] = list_param,
		["id"] = {},
		["sort"] = {},
		["nolinkhead"] = {type = "boolean"},
		["json"] = {type = "boolean"},
		["pagename"] = {}, -- for testing
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

	local data = {
		lang = lang,
		langname = langname,
		pos_category = poscat,
		categories = {},
		heads = args.head,
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		def = def,
		is_suffix = false,
	}

	if pagename:find("^%-") and poscat ~= "suffix forms" then
		data.is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = require(en_utilities_module).singularize(poscat)
		table.insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		table.insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	-- mw.ustring.toNFD performs decomposition, so letters that decompose
	-- to an ASCII vowel and a diacritic, such as é, are counted as vowels and
	-- do not need to be included in the pattern.
	if not pagename:find("[ %-]") and not rfind(mw.ustring.lower(mw.ustring.toNFD(pagename)), "[aeiouyæœø]") then
		table.insert(data.categories, langname .. " words spelled without vowels")
	end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
	return require("Module:headword").full_headword(data)
end

local function get_noun_params(is_proper)
	return function(lang)
		params = {
			[1] = {type = "genders", required = true, template_default = "?"},
			["g"] = {list = true, disallow_holes = true, replaced_by = false,
				instead = "use multiple comma-separated genders in |1="},
			["g_qual"] = {list = "g\1_qual", allow_holes = true, replaced_by = false,
				instead = "use inline modifiers on the gender(s) in |1="},
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
		if lang:getCode() == "sk" then
			params["decl"] = list_param
		end
		return params
	end
end

local function do_nouns(is_proper, args, data)
	-- Validate and canonicalize genders.
	local specs = valid_gender_specs[data.lang:getCode()]
	for _, gspec in ipairs(args[1]) do
		local g = gspec.spec
		local canon_g = specs[g]
		if canon_g then
			g = canon_g
		elseif g == "m" or g == "m-p" or g == "mf" or g == "mf-p" or g == "mfbysense" or g == "mfbysense-p" then
			error("Invalid gender: '" .. g .. "'; must specify animacy along with masculine gender")
		elseif data.lang:getCode() == "sk" and g:find("%-an") then
			error("Invalid gender: '" .. g .. "'; instead of m-an, use m-pr for people and m-anml for animals")
		else
			error("Unrecognized gender: '" .. g .. "'")
		end
		track("gender-" .. g)
		gspec.spec = g
		table.insert(data.genders, gspec)
	end
	if args.indecl then
		table.insert(data.inflections, {label = glossary_link("indeclinable")})
		table.insert(data.categories, data.langname .. " indeclinable nouns")
	end
	local decls
	if data.lang:getCode() == "sk" then
		-- Validate declension patterns and converto to Appendix links
		decls = parse_inflection(data, "decl", args.decl)
		for _, declobj in ipairs(decls) do
			local decl = declobj.term
			if not allowed_sk_decl_patterns[decl] then
				error("Unrecognized " .. data.langname .. " declension pattern: " .. decl)
			end
			declobj.term = ("[[Appendix:%s declension pattern %s|%s]]"):format(data.langname, decl, decl)
		end
	end

	-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
	-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
	-- given, which is linked to the glossary if preceded by * (which is removed).
	local function handle_infl(field, label)
		parse_and_insert_inflection(data, args, field, label)
	end

	handle_infl("gen", "<<genitive>> <<singular>>")
	handle_infl("pl", "<<nominative>> <<plural>>")
	handle_infl("genpl", "<<genitive>> <<plural>>")
	if decls and decls[1] then
		decls.label = "declension pattern of"
		table.insert(data.inflections, decls)
	end
	handle_infl("m", "male equivalent")
	handle_infl("f", "female equivalent")
	handle_infl("adj", "<<relational adjective|relational adjective>>")
	handle_infl("pos", "<<possessive adjective|possessive adjective>>")
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
		["a"] = {default = "?"},
		["pf"] = list_param,
		["impf"] = list_param,
	},
	func = function(args, data)
		if not valid_aspects[args.a] then
			error("Unrecognized aspect: '" .. args.a .. "'")
		end
		data.genders = args.a == "both" and {"biasp"} or {args.a}

		parse_and_insert_inflection(data, args, "pf", "perfective")
		parse_and_insert_inflection(data, args, "impf", "imperfective")
	end,
}

local function do_comparative_superlative(args, data, plpos)
	if args[1][1] then
		local comp = parse_inflection(data, {1, "comp"}, args[1])
		if comp[1] and comp[1].term == "-" then
			if comp[2] then
				error("Can't specify comparatives along with '-' indicating an uncomparable adjective or adverb")
			end
			m_headword_utilities.insert_fixed_inflection {
				headdata = data,
				label = "not <<comparable>>",
				originating_term = comp[1],
			}
			table.insert(data.categories, data.langname .. " uncomparable " .. plpos)
		else
			local sup = parse_inflection(data, {2, "sup"}, args[2])
			if not sup[1] then
				sup = m_table.deepCopy(comp)
				for _, s in ipairs(sup) do
					-- Old Czech has naj-.
					s.term = (data.lang:getCode() == "cs" and "nej" or "naj") .. s.term
				end
			end
			comp.label = "comparative"
			comp.accel = {form = "comparative"}
			sup.label = "superlative"
			sup.accel = {form = "superlative"}
			table.insert(data.inflections, comp)
			table.insert(data.inflections, sup)
			table.insert(data.categories, data.langname .. " comparable " .. plpos)
		end
	end
end

pos_functions["adjectives"] = {
	params = function(lang)
		local params = {
			[1] = {list = "comp", disallow_holes = true},
			[2] = {list = "sup", disallow_holes = true},
			["adv"] = list_param,
			["indecl"] = {type = "boolean"},
		}
		if lang:getCode() == "zlw-ocs" then
			params.short = list_param
			params.shortcomp = list_param
			params.shortsup = list_param
		end
		return params
	end,
	func = function(args, data)
		if args.indecl then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable adjectives")
		end
		parse_and_insert_inflection(data, args, "short", "short form")
		do_comparative_superlative(args, data, "adjectives")
		parse_and_insert_inflection(data, args, "shortcomp", "short <<comparative>>")
		parse_and_insert_inflection(data, args, "shortsup", "short <<superlative>>")
		parse_and_insert_inflection(data, args, "adv", "adverb")
	end,
}

pos_functions["adverbs"] = {
	params = {
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
	},
	func = function(args, data)
		do_comparative_superlative(args, data, "adverbs")
	end,
}

return export
