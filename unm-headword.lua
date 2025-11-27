local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local langcode = "unm"
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

local insert = table.insert

local boolean_param = {type = "boolean"}

local legal_verb_classes = {
	["vii"] = {"inanimate intransitive", "VII (<<inanimate>>-subject <<intransitive>>)"},
	["vai"] = {"animate intransitive", "VAI (<<animate>>-subject <<intransitive>>)"},
	["vti"] = {"transitive inanimate", "VTI (<<transitive>> <<inanimate>>-object)"},
	["vta"] = {"transitive animate", "VTA (<<transitive>> <<animate>>-object)"},
}

local function track(page)
	require("Module:debug/track")("unm-headword/" .. page)
	return true
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(args, field, is_head)
	local argfield = field
	local argpref = field
	if type(argfield) == "table" then
		argpref = argfield[2]
		argfield = argfield[1]
	end
	local include_mods
	if is_head then
		include_mods = {}
	else
		include_mods = {"t"}
	end
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
end

local function insert_inflection(data, terms, label, accel, no_label, usually_no_label)
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
local function parse_and_insert_inflection(data, args, field, label, accel, no_label, usually_no_label)
	local terms = parse_inflection(args, field, is_head)
	insert_inflection(data, terms, label, accel, no_label, usually_no_label)
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

	local indexing_poscat = actual_poscat and "head" or poscat

	local params = {
		head = {template_default = def or "palia"},
		id = true,
		json = boolean_param,
		sort = true,
		nolink = boolean_param,
		nolinkhead = {alias_of = "nolink"},
		suffix = boolean_param,
		nosuffix = boolean_param,
		altform = boolean_param,
		pagename = true, -- for testing
	}
	if actual_poscat then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	local pos_data = pos_functions[indexing_poscat]
	local pos_func, pos_not_suffix
	if pos_data then
		local pos_params = pos_data.params
		if type(posparams) == "function" then
			posparams = posparams(lang)
		end
		if pos_params then
			for key, val in pairs(pos_params) do
				params[key] = val
			end
		end
		pos_func = pos_data.func
		pos_not_suffix = pos_data.not_suffix
	end

    local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData(headword_data_module).pagename

	local user_specified_heads = parse_inflection(args, "head", "is_head")
	local heads = user_specified_heads
	local autohead
	if args.nolink then
		autohead = pagename
	else
		autohead = m_headword_utilities.add_links_to_multiword_term(pagename, {})
	end

	if not heads[1] then
		heads = {{term = autohead}}
	else
		for _, headobj in ipairs(heads) do
			local head = headobj.term
			--if head:find("^~") then
			--	head = apply_link_modifiers(autohead, head:sub(2))
			--	headobj.term = head
			if head:find("^[!?]$") then
				-- If explicit head= just consists of ! or ?, add it to the end of the default head.
				headobj.term = autohead .. head
			end
			if head == autohead then
				track("redundant-head")
			end
		end
	end

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
		altform = args.altform,
		heads = heads,
	}

	if args.suffix or not args.nosuffix and pagename:find("^%-") and not pagename:find("^%-%-") and
		poscat ~= "suffix forms" and (not pos_not_suffix or not pos_not_suffix(args, data)) then
		data.is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = require(en_utilities_module).singularize(actual_poscat or poscat)
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_func then
		pos_func(args, data)
	end

    if args.json then
        return require("Module:JSON").toJSON(data)
    end
	
	return require(headword_module).full_headword(data)
end

local function validate_genders(genders)
	for _, gspec in ipairs(genders) do
		local g = gspec.spec
		if g ~= "an" and g ~= "in" and g ~= "an-p" and g ~= "in-p" and g ~= "?" then
			error("Unrecognized gender: '" .. g .. "'")
		end
	end
end

pos_functions["nouns"] = {
	params = {
		g = {type = "genders", default = "?"},
		pl = true, -- plural
		adj = true, -- adjectival
		dim = true, -- diminutive
		obv = true, -- obviative
		loc = true, -- locative
		locpl = true, -- locative plural
		absent = true, -- absentative
		absentpl = true, -- absentative plural
		poss = true, -- possessive
		poss3s = true, -- third-singular possessive (FIXME: same as preceding?)
		poss1s = true, -- first-singular possessive
		gen = true, -- genitive (FIXME: same as possessive or adjectival?)
		pej = true, -- pejorative
		voc = true, -- vocative
		objurg = true, -- objurgative (FIXME: what is this?)
		root = boolean_param, -- if specified, categorizes into noun roots and noun finals (?) and not noun suffixes, and displays "noun root, final"
	},
	func = function(args, data)
		data.genders = args.g
		validate_genders(data.genders)

		if args.root then
			m_headword_utilities.insert_fixed_inflection {
				headdata = data,
				label = "noun root, final",
			}
			insert(data.categories, langname .. " " .. "noun roots")
			insert(data.categories, langname .. " " .. "noun finals")
		end

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> in the label is linked to the glossary. `accel` is the accelerator form, or nil. `no_label`
		-- overrides the text generated when '-' is given as the only value. `usually_no_label` overrides the text
		-- generated when '-' is given as a value followed by some other value.
		local function handle_infl(field, label, accel, no_label, usually_no_label)
			parse_and_insert_inflection(data, args, field, label, accel, no_label, usually_no_label)
		end

		handle_infl("pl", "plural")
		handle_infl("adj", "adjectival")
		handle_infl("dim", "diminutive")
		handle_infl("obv", "obviative")
		handle_infl("loc", "locative")
		handle_infl("locpl", "locative plural")
		handle_infl("absent", "absentative")
		handle_infl("absentpl", "absentative plural")
		handle_infl("poss", "possessive")
		handle_infl("poss3s", "third-singular possessive") -- FIXME, same as preceding?
		handle_infl("poss1s", "first-singular possessive")
		handle_infl("gen", "genitive") -- FIXME, same as possessive or adjectival?
		handle_infl("pej", "pejorative")
		handle_infl("voc", "vocative")
		handle_infl("objurg", "objurgative") -- FIXME, what is this?
	end,
	not_suffix = function(args, data)
		return args.root
	end,
}

pos_functions["proper nouns"] = pos_functions["nouns"]
pos_functions["pronouns"] = pos_functions["nouns"]

pos_functions["verbs"] = {
	params = {
		[1] = {default = "?"},
		indic3p = true, -- third plural indicative
		plcoll = true, -- present indicative plural collective
		conj3s = true, -- third singular conjunct
		subj3s = true, -- third singular subjunctive
		redup3s = true, -- third singular with reduplication
		absent = true, -- third singular present indicative absentative
		intj = true, -- interjective singular
		part = true, -- participle
		partpl = true, -- participle plural
		fut = true, -- future
		past = true, -- future
		impv = true, -- imperative
		neg = true, -- negative
		pass = true, -- passive
		freq = true, -- frequentative
		-- Do the following four even make sense for verbs? Are they mistakes for noun properties?
		dim = true, -- diminutive
		pej = true, -- pejorative
		adj = true, -- adjectival
		loc = true, -- locative
		initch = true, -- initial change
		initredup = true, -- initial reduplication
		initchredup = true, -- initial change and reduplication
		anim = true, -- animate equivalent
		inan = true, -- inanimate equivalent
		root = boolean_param, -- if specified, categorizes into verb roots and verb finals (?) and not verb suffixes, and displays "verb root, final"
	},
	func = function(args, data)
		if args.root then
			m_headword_utilities.insert_fixed_inflection {
				headdata = data,
				label = "verb root, final",
			}
			insert(data.categories, langname .. " " .. "verb roots")
			insert(data.categories, langname .. " " .. "verb finals")
		end

		local classes = parse_inflection(args, 1)
		for _, class in ipairs(classes) do
			
			if class.term == "?" then
				m_headword_utilities.insert_fixed_inflection {
					headdata = data,
					originating_term = class,
					label = "unknown <<animacy>> and <<transitivity>>",
				}
			else
				if not legal_verb_classes[class.term] then
					local legal_classes = {}
					for k, _ in pairs(legal_verb_classes) do
						insert(legal_classes, k)
					end
					table.sort(legal_classes)
					error(("Unrecognized verb class '%s', should be one of %s"):format(class.term,
						mw.text.list(legal_classes, nil,  " or ")))
				end
				insert(data.categories, langname .. " " .. legal_verb_classes[class.term][1] .. " verbs")
				-- WARNING, the following destructively modifies 'class'
				m_headword_utilities.insert_fixed_inflection {
					headdata = data,
					originating_term = class,
					label = legal_verb_classes[class.term][2],
				}
			end
		end

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
		-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
		-- given; <<..>> in the label is linked to the glossary. `accel` is the accelerator form, or nil. `no_label`
		-- overrides the text generated when '-' is given as the only value. `usually_no_label` overrides the text
		-- generated when '-' is given as a value followed by some other value.
		local function handle_infl(field, label, accel, no_label, usually_no_label)
			parse_and_insert_inflection(data, args, field, label, accel, no_label, usually_no_label)
		end

		handle_infl("indic3p", "third plural indicative")
		handle_infl("plcoll", "present indicative plural collective")
		handle_infl("conj3s", "third singular conjunct")
		handle_infl("subj3s", "third singular subjunctive")
		handle_infl("redup3s", "third singular with reduplication")
		handle_infl("absent", "third singular present indicative absentative")
		handle_infl("intj", "interjective singular")
		handle_infl("part", "participle")
		handle_infl("partpl", "participle plural")
		handle_infl("fut", "future")
		handle_infl("past", "past")
		handle_infl("impv", "imperative")
		handle_infl("neg", "negative")
		handle_infl("pass", "passive")
		handle_infl("freq", "frequentative")
		handle_infl("dim", "diminutive")
		handle_infl("pej", "pejorative")
		handle_infl("adj", "adjectival")
		handle_infl("loc", "locative")
		handle_infl("initch", "initial change")
		handle_infl("initredup", "initial reduplication")
		handle_infl("initchredup", "initial change and reduplication")
		handle_infl("anim", "animate equivalent")
		handle_infl("inan", "inanimate equivalent")
	end,
	not_suffix = function(args, data)
		return args.root
	end,
}

return export
