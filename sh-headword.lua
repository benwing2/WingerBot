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
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local links_module = "Module:links"
local parse_interface_module = "Module:parse interface"

local u = m_str_utils.char
local rfind = m_str_utils.find
local ulower = m_str_utils.lower
local unfd = mw.ustring.toNFD
local insert = table.insert

local GR = u(0x0300)
local AC = u(0x0301)
local TILDE = u(0x0303)
local MACRON = u(0x0304)
local DGRAVE = u(0x030F)
local INVBREVE = u(0x0311)

local tonal_accents = GR .. AC .. TILDE .. DGRAVE .. INVBREVE
local vowels = "aeiouаеиоу"
local vowels_that_can_bear_tone = vowels .. "rр"
local V = "[" .. vowels .. "]"

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
	insert(tracking_pages, "sh-headword/" .. track_id)
	if pos then
		insert(tracking_pages, "sh-headword/" .. track_id .. "/" .. pos)
	end
	require("Module:debug/track")(tracking_pages)
	return true
end

local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
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
		splitchar = ",",
	}
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local iparams = {
		[1] = {required = true},
		def = {},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1]
	local def = iargs.def

	local parargs = frame:getParent().args
	local actual_poscat
	if poscat == "head" then
		actual_poscat = ine(parargs[2]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 2=")
		actual_poscat = require(headword_module).canonicalize_pos(actual_poscat)
	end

	local params = {
		[1] = {list = "head", disallow_holes = true, template_default = def or "књи̏га"},
		tr = {list = true, allow_holes = true},
		id = true,
		sort = true,
		-- no nolinkhead= because head in 1= should always be specified
		json = boolean_param,
		pagename = true, -- for testing
	}
	if actual_poscat then
		params[2] = {required = true} -- required but ignored as already processed above
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

	local heads = m_headword_utilities.parse_term_list_with_modifiers {
		forms = args[1],
		paramname = {1, "head"},
		is_head = true,
		include_mods = {"tr"},
		splitchar = ",",
	}

	local data = {
		lang = lang,
		pos_category = actual_poscat or poscat,
		categories = {},
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		is_suffix = false,
		no_redundant_head_cat = not heads[1],
	}

	local sc = lang:findBestScript(pagename)
	
	local other_sc
	
	if sc:getCode() == "Latn" then
		other_sc = "Cyrl"
	elseif sc:getCode() == "Cyrl" then
		other_sc = "Latn"
	end

	if not heads[1] then
		heads = {{term = pagename}}
	end
	local numheads = #heads

	-- Copy translit in trN= to head structure (it can also be specified using inline modifier <tr:...>).
	for i, tr in pairs(args.tr) do
		if type(i) == "number" then
			if i > numheads then
				error(("Specified value for tr%s= but only %s head%s available"):format(
					i, numheads, numheads == 1 and "" or "s"))
			end
			heads[i].tr = tr
		end
	end

	-- If pagename is Latin or Cyrillic, display the other-script transliteration as an inflection. Use manually
	-- specified translit if available, otherwise auto-translit.
	if other_sc then
		other_sc = require("Module:scripts").getByCode(other_sc)
		local inflection = {label = other_sc:getCanonicalName() .. " spelling"}

		if heads[1].tr == "-" then
			inflection.label = "not attested in " .. other_sc:getCanonicalName() .. " spelling"
		else
			for _, head in ipairs(heads) do
				local tr = head.tr
				
				if not tr then
					tr = require("Module:sh-translit").tr(require("Module:links").remove_links(head.term), "sh", sc:getCode())
				end
				
				insert(inflection, {term = tr, sc = other_sc})
			end
		end
		
		insert(data.inflections, inflection)
	end
	-- Now remove the translit from the `heads` structure so it doesn't display in the normal translit slot.
	for i, head in ipairs(heads) do
		if head.tr then
			if not other_sc then
				error(("Translit specified for head #%s when pagename is neither Latin nor Cyrillic"):format(i))
			end
			head.tr = nil
		end
	end
	data.heads = heads

	local singular_poscat = require(en_utilities_module).singularize(actual_poscat or poscat)

	local needs_accents = false
	for _, head in ipairs(heads) do
		-- FIXME, should split by space and check each word
		local lower_nfd_head = ulower(unfd(head.term))
		if rfind(lower_nfd_head, "[" .. vowels_that_can_bear_tone .. "]") and not
			rfind(lower_nfd_head, "[" .. vowels_that_can_bear_tone .. "][" .. tonal_accents .. "]") then
			needs_accents = true
			break
		end
	end
	if needs_accents then
		insert(data.categories, "Requests for accents in " .. langname .. " " .. singular_poscat .. " entries")
	end		

	if pagename:find("^%-") and poscat ~= "suffixes" and poscat ~= "suffix forms" then
		data.is_suffix = true
		data.pos_category = "suffixes"
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	-- unfd (mw.ustring.toNFD) performs decomposition, so letters that decompose to an ASCII vowel and a diacritic,
	-- such as é, are counted as vowels and do not need to be included in the pattern.
	if not pagename:find("[ %-]") and not rfind(ulower(unfd(pagename)), V) then
		insert(data.categories, langname .. " words spelled without vowels")
	end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
	return require(headword_module).full_headword(data)
end

local function get_noun_params(is_proper)
	return {
		[2] = {default = "?", type = "genders"},
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
		voc = list_param,
		loc = list_param,
		pl = list_param,
		nompl = {alias_of = "pl", list = true, disallow_holes = true},
		genpl = list_param,
	}
end

local function validate_genders(data, genders, categorize)
	for _, g in ipairs(genders) do
		local canon_g = valid_genders[g.spec]
		if canon_g then
			track("gender-" .. g.spec)
			if canon_g ~= true then
				g.spec = canon_g
			end
			if categorize then
				-- Categorize by gender, in addition to what's done already by [[Module:gender and number]].
				if g.spec == "m-an" then
					insert(data.categories, langname .. " masculine animate nouns")
				elseif g.spec == "m-in" then
					insert(data.categories, langname .. " masculine inanimate nouns")
				end
			end
		else
			error("Unrecognized gender: '" .. g.spec .. "'")
		end
	end
end

local function do_nouns(is_proper, args, data)
	validate_genders(data, args[2], true)
	data.genders = args[2]
	if args.indecl then
		insert(data.inflections, {label = glossary_link("indeclinable")})
		insert(data.categories, langname .. " indeclinable nouns")
	end

	-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
	-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
	-- given; <<..>> ini the label is linked to the glossary). `accel` is the accelerator form, or nil.
	local function handle_infl(field, label)
		parse_and_insert_inflection("noun", data, args, field, label)
	end

	handle_infl("gen", "<<genitive>> <<singular>>")
	handle_infl("voc", "<<vocative>> <<singular>>")
	handle_infl("loc", "<<locative>> <<singular>>")
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
		pf = list_param,
		impf = list_param,
		pres = list_param,
		pres3s = list_param,
		pres3p = list_param,
		past = list_param,
		pastf = list_param,
		pastn = list_param,
		impft = list_param,
		impft3s = list_param,
		impft3p = list_param,
		aor = list_param,
		aor3s = list_param,
		aor3p = list_param,
		vn = list_param,
		pradvp = list_param,
		padvp = list_param,
		pap = list_param,
		papf = list_param,
		papn = list_param,
		ppp = list_param,
		pppf = list_param,
		pppn = list_param,
	},
	func = function(args, data)
		for _, a in ipairs(args[2]) do
			if a.spec == "both" then
				a.spec = "biasp"
			end
			if a.spec == "pf-impf" or a.spec == "impf-pf" or a.spec == "dual" or a.spec == "ip" then
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
		handle_infl("pres", "first-singular present")
		handle_infl("pres3s", "third-singular present")
		handle_infl("pres3p", "third-plural present")
		handle_infl("impft", "first-singular imperfect")
		handle_infl("impft3s", "third-singular imperfect")
		handle_infl("impft3p", "third-plural imperfect")
		handle_infl("aor", "first-singular aorist")
		handle_infl("aor3s", "third-singular aorist")
		handle_infl("aor3p", "third-plural aorist")
		handle_infl("pap", "masculine singular past active participle")
		handle_infl("papf", "feminine singular past active participle")
		handle_infl("papn", "neuter singular past active participle")
		handle_infl("ppp", "masculine singular past passive participle")
		handle_infl("pppf", "feminine singular past passive participle")
		handle_infl("pppn", "neuter singular past passive participle")
		handle_infl("pradvp", "present adverbial participle")
		handle_infl("padvp", "past adverbial participle")
		handle_infl("vn", "verbal noun")
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
			insert(data.inflections, {label = glossary_link("indeclinable")})
			insert(data.categories, langname .. " indeclinable adjectives")
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

pos_functions["letters"] = {
	params = {
		upper = true,
		lower = true,
	},
	func = function(args, data)
		if args.upper then
			insert(data.inflections, {label = "lower case", nil})
			insert(data.inflections, {label = "upper case", args.upper})
		elseif args.lower then
			insert(data.inflections, {label = "upper case", nil})
			insert(data.inflections, {label = "lower case", args.lower})
		end
	end,
}

-----------------------------------------------------------------------------------------
--                                      Suffix forms                                   --
-----------------------------------------------------------------------------------------

pos_functions["suffix forms"] = {
	params = {
		[2] = {required = true, template_default = "noun"},
		[3] = {type = "genders"},
	},
	func = function(args, data)
		if args[3] then
			validate_genders(data, args[3], false)
			data.genders = args[3]
		end
		local suffix_type = {}
		for _, typ in ipairs(split_on_comma(args[2])) do
			insert(suffix_type, typ .. "-forming suffix")
		end
		insert(data.inflections, {label = "non-lemma form of " .. m_table.serialCommaJoin(suffix_type, {conj = "or"})})
	end,
}

-----------------------------------------------------------------------------------------
--                                Arbitrary part of speech                             --
-----------------------------------------------------------------------------------------

pos_functions["head"] = {
	params = {
		-- [2] is already processed in show()
		[3] = {type = "genders"},
	},
	func = function(args, data)
		if data.is_suffix then
			error("Can't use [[Template:sh-head]] with suffixes")
		end
		if args[3] then
			validate_genders(data, args[3], false)
			data.genders = args[3]
		end
	end,
}

return export
