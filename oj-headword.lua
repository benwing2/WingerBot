local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local langcode = "oj"
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

local rfind = m_str_utils.find
local ulower = m_str_utils.lower
local insert = table.insert

local list_param = {list = true, disallow_holes = true}
local boolean_param = {type = "boolean"}

local legal_verb_class = {
	["vii"] = {"inanimate intransitive verbs", {["+"] = "", p = "inherently plural"}},
	["vai"] = {"animate intransitive verbs", {
		["+"] = "", ["2"] = "pseudo-VAI", o = "optional object", p = "inherently plural"}
	},
	["vti"] = {"transitive inanimate verbs", {
		["+"] = "{{m|oj||-am}} stem", ["2"] = "{{m|oj||-oo}} stem", ["3"] = "{{m|oj||-i}} stem",
		["4"] = "{{m|oj||-aam}} stem"}
	},
	["vta"] = {"transitive animate verbs", {["+"] = "", i = "inverse only"}},
}

local m_scripts = require("Module:scripts")
local Latn = m_scripts.getByCode("Latn")
local Cans = m_scripts.getByCode("Cans")

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(data, args, field, is_head)
	local argfield = field
	local argpref = field
	if type(argfield) == "table" then
		argpref = argfield[2]
		argfield = argfield[1]
	end
	local include_mods
	if is_head then
		include_mods = {{"oth", true}}
	else
		include_mods = {{"oth", true}, "g"}
	end
	if is_head then
		local retval
		if args[argfield] then
			retval = m_headword_utilities.parse_term_with_modifiers {
				val = args[argfield],
				paramname = field,
				splitchar = ",",
				is_head = is_head,
				include_mods = include_mods,
			}
		end
		return retval or {}
	else
		return m_headword_utilities.parse_term_list_with_modifiers {
			forms = args[argfield],
			paramname = field,
			splitchar = ",",
			is_head = is_head,
			include_mods = include_mods,
		}
	end
end

local function insert_inflection(data, terms, label, accel, defgender, track_field, no_label, usually_no_label)
	local track_pos = m_en_utilities.singularize(data.pos_category)

	for _, termobj in ipairs(terms) do
		-- If the user supplied a construct state or informal form for the term with a value of "+", substitute the
		-- default value for the term. If the user supplied a value of "--", they want no value displayed. Otherwise,
		-- if the user didn't supply any value, we check to see if the default construct state or informal form is
		-- different from the lemma and display it if so; this applies particularly to terms in '-in' and '-an', where
		-- the default construct state or informal form is almost always correct.
		local field = has_construct_state(data) and "cons" or "inf"
		if not termobj[field] then
			local defcons, defconstr = default_construct_state_or_informal(termobj.term, termobj.tr)
			if termobj.term ~= defcons or termobj.tr ~= defconstr then
				-- We don't want to copy qualifiers, labels, etc. from the term object because we're a subinflection of
				-- the term object.
				termobj[field] = {{term = defcons, tr = defconstr}}
			end
		elseif termobj[field][1].term == "--" then
			if termobj[field][2] then
				error("Can't specify more than one value for <" .. field .. ":...> if first value is '--', meaning \"don't insert anything\"")
			end
			termobj[field] = nil
		else
			for i, consobj in ipairs(termobj[field]) do
				if consobj.term == "+" then
					if consobj.tr then
						error("Can't specify translit for default value '+'")
					end
					consobj.term, consobj.tr = default_construct_state_or_informal(termobj.term, termobj.tr)
				elseif consobj.term == "~" then
					if consobj.tr then
						error("Can't specify translit for term-requesting value '~'")
					end
					consobj.term, consobj.tr = termobj.term, termobj.tr
				end
			end
		end

		if defgender and not termobj.genders then
			termobj.genders = {{spec = defgender}}
		end

		local function insert_nested_inflection(field, label)
			if termobj[field] then
				m_headword_utilities.insert_inflection {
					headdata = data,
					inflobj = termobj,
					terms = termobj[field],
					label = label
				}
			end
		end

		insert_nested_inflection("oth", 
		for _, spec in ipairs(has_construct_state(data) and noun_inflections or adjective_inflections) do
			insert_nested_inflection(spec.field, spec.label)
		end

		track_form(track_field, termobj.term, termobj.tr, track_pos)
	end

	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel and {form = accel} or nil,
		no_label = no_label,
		usually_no_label = usually_no_label,
	}
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
		actual_poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		actual_poscat = require(headword_module).canonicalize_pos(actual_poscat)
	end

	local params = {
		head = {list = true, disallow_holes = true, template_default = def or "gaazhagens"},
		tr = {list = true, allow_holes = true},
		id = true,
		sort = true,
		-- no nolinkhead= because head in 1= should always be specified
		altform = boolean_param,
		json = boolean_param,
		pagename = true, -- for testing
	}
	if actual_poscat then
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

	local heads = m_headword_utilities.parse_term_list_with_modifiers {
		forms = args.head,
		paramname = "head",
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
		altform = args.altform,
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

pos_functions["nouns"] = {
	params = {
		g = {type = "gender", default = "?"},
		pl = list_param, -- plural
		obv = list_param, -- obviative
		loc = list_param, -- locative
		locdist = list_param, -- locative distributive
		dim = list_param, -- diminutive
		pej = list_param, -- pejorative
		dimpej = list_param, -- diminutive pejorative
		pejpl = list_param, -- pejorative plural
		contemp = list_param, -- contemptive
		stem = list_param, -- stem
		final = list_param, -- final
		finalpl = list_param, -- final plural
		pret = list_param, -- preterit
		oblposs = boolean_param, -- obligatorily possessed; should categorize as 'dependent inanimate nouns' or 'dependent animate nouns' and turn off suffix handling
	},
	func = function(args, data)
		local script_code = args[1]
		local translit = args[2]
		script = Latn
		if script_code == "c" then script = Cans end
		
		if translit ~= nil then
			if script_code == "c" then table.insert(data.inflections, {label = "Latin spelling", sc=Latn, translit})
			else table.insert(data.inflections, {label = "Canadian syllabics spelling", sc=Cans, translit})
			end
		end
		
		local gender = args["g"]
		local plural = args["pl"]
		local plother = args["plother"]
		local obv = args["obv"]
		local loc = args["loc"]
		local dim = args["dim"]
		local pej = args["pej"]
		
		if gender == "an" then table.insert(data.genders, "an")
		elseif gender == "in" then table.insert(data.genders, "in")
		else end
		
		if plural ~= nil then
			if gender == "an" then table.insert(data.inflections, {label = "plural", sc=script, accel = {form = "p"}, plural}) 
			elseif gender == "in" then table.insert(data.inflections, {label = "plural", sc=script, accel = {form = "p//obv"}, plural}) 
			else table.insert(data.inflections, {label = "plural", plural}) end
		end
		
		if plother ~= nil then
			if script_code == "Cans" then table.insert(data.inflections, {label = "plural Latin spelling", sc=Latn, plother})
			else table.insert(data.inflections, {label = "plural Canadian syllabics spelling", sc=Cans, plother})
			end
		end
		
		if obv ~= nil then
			if gender == "an" then table.insert(data.inflections, {label = "obviative", sc=script, accel = {form = "obv"}, obv}) 
			elseif gender == "in" then table.insert(data.inflections, {label = "obviative", sc=script, accel = {form = "p//obv"}, obv}) 
			else table.insert(data.inflections, {label = "obviative", plural})  end
		end
		
			-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
			-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
			-- given; <<..>> in the label is linked to the glossary. `accel` is the accelerator form, or nil.
			local function handle_infl(field, label, accel)
				parse_and_insert_inflection("noun", data, args, field, label, accel)
			end

			handle_infl("loc", "locative", "loc")
			handle_infl("dim", "diminutive", "dim")
			handle_infl("pej", "pejorative", "pej")
	end
}

pos_functions["verbs"] = {
	params = {
		[1] = {default = "?"},
		conj = list_param, -- conjunct form
		chconj = list_param, -- changed conjunct form
		chconjstem = list_param, -- changed conjunct stem
		redup = list_param, -- reduplicated form
		stem = list_param, -- stem
		aug = list_param, -- augmented form
		["3s3indep"] = list_param, -- 3s-3' independent form
		["2s3impv"] = list_param, -- 2s-3 imperative form
		part = list_param, -- participle
	},
	func = function(args, data)
		local class_subclass = args[1]
		if class_subclass == "?" then
			insert(data.inflections, {label = "unknown animacy and transitivity"})
		else
			local class, subclass = class_subclass:match("^(v[a-z][a-z])(.?)$")
			if not class then
				error(("Invalid value for verb class '%s', should be 'vii', 'vai', 'vti' or 'vta' possibly with an extra character indicating a subclass"):format(class_subclass))
			end
		end
		if class == "vta" then
			table.insert(data.inflections, {label = "animate transitive", nil})
			table.insert(data.categories, "Ojibwe verb transitive animate (vta)")
		elseif class == "vti" then
			table.insert(data.inflections, {label = "inanimate transitive", nil})
			table.insert(data.categories, "Ojibwe verb transitive inanimate (vti)")
		elseif class == "vai" then
			table.insert(data.inflections, {label = "animate intransitive", nil})
			table.insert(data.categories, "Ojibwe verb animate intransitive (vai)")
		elseif class == "vii" then
			table.insert(data.inflections, {label = "inanimate intransitive", nil})
			table.insert(data.categories, "Ojibwe verb inanimate intransitive (vii)")
		elseif class == "vai2" then
			table.insert(data.inflections, {label = "animate intransitive class 2", nil})
			table.insert(data.categories, "Ojibwe verb animate intransitive class 2 (vai2)")
		else
			error("invalid verb class")
		end

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> in the label is linked to the glossary. `accel` is the accelerator form, or nil.
		local function handle_infl(field, label, accel)
			parse_and_insert_inflection("verb", data, args, field, label, accel)
		end
		handle_infl("conj", "conjunct form")
		handle_infl("chconj", "changed conjunct form")
		handle_infl("redup", "reduplicated form")
		handle_infl("stem", "stem")
		handle_infl("aug", "augmented form")
		handle_infl("3s3indep", "3s-3' independent form")
		handle_infl("2s3impv", "2s-3 imperative form")
		handle_infl("part", "participle")
	end
}

return export
