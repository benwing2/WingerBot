local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")

local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_string_utilities = require_when_needed("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}

local concat = table.concat
local insert = table.insert
local remove = table.remove

local rfind = mw.ustring.find
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local langs_supported = {
	["pl"] = {
		peri_comp = "bardziej",
		sup = "naj",
		-- participle endings
		act = {"ąc[yae]$"},  -- biegnący
		pass = {"[ntł][yae]$"},  -- otwarty, uwielbiany, legły
		cont_adv = {"ąc$"},
		ant_adv = {"szy$"},
	},
	["csb"] = {
		peri_comp = "barżi",
		sup = "nô",
		-- participle endings
		act = {"ący$"},
		pass = {"[ao]ny$", "ty$", "łi$"},
		cont_adv = {"ōnc$"},
		ant_adv = {"[wł]szë$"},
	},
	["szl"] = {
		peri_comp = "bardzij",
		sup = "noj",
		-- participle endings
		act = {"ōncy$"},
		pass = {"[aō]ny$", "[tł]y$"},
		cont_adv = {"ąc$"},
		ant_adv = false,
	},
	["zlw-opl"] = {
		peri_comp = "barziej",
		sup = false,
		-- participle endings
		act = {"ąc[yae]$"},  -- biegnący
		pass = {"[ntł][yae]$"},  -- otwarty, uwielbiany, legły
		cont_adv = {"ąc$"},
		ant_adv = {"szy$"},
	},
	["pox"] = {
		peri_comp = false,
		sup = false,
		-- participle endings
		act = false,
		pass = false,
		cont_adv = false,
		ant_adv = false,
		has_dual = true,
	},
	["zlw-slv"] = {
		peri_comp = "barżé",
		sup = "no",
		-- participle endings
		act = false,
		pass = false,
		cont_adv = false,
		ant_adv = false,
		has_dual = true,
	},
}

----------------------------------------------- Utilities --------------------------------------------

local function track(page)
	require("Module:debug").track("zlw-lch-headword/" .. page)
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
-- `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		splitchar = ",",
		include_mods = {"g"},
		frob = function(term)
			return frob_term_with_hash(term, data.pagename)
		end,
		label = label,
		accel = accel and {form = accel} or nil,
		-- If we want check_missing support, we need to supply the following:
		-- check_missing = true,
		-- lang = lang,
		-- plpos = plpos,
	}
end

-- Parse and return an inflection not requiring additional processing. The raw arguments come from `args[field]`, which
-- is parsed for inline modifiers.
local function parse_inflection(data, args, field)
	return m_headword_utilities.parse_term_list_with_modifiers {
		paramname = field,
		forms = args[field],
		splitchar = ",",
		include_mods = {"g"},
		frob = function(term)
			return frob_term_with_hash(term, data.pagename)
		end,
	}
end

-- Insert the parsed inflections in `infls` (as parsed by `parse_inflection`) into `data.inflections`, with label
-- `label` and optional accelerator spec `accel`.
local function insert_inflection(data, terms, label, accel)
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel and {form = accel} or nil,
		-- If we want check_missing support, we need to supply the following:
		-- check_missing = true,
		-- lang = lang,
		-- plpos = plpos,
	}
end


----------------------------------------------- Main entry point --------------------------------------------

function export.show(frame)
	local iparams = {
		[1] = {required = true},
		["lang"] = {required = true},
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)
	local poscat = iargs[1]
	langcode = iargs.lang
	if not langs_supported[langcode] then
		local langcodes_supported = {}
		for lang, _ in pairs(langs_supported) do
			insert(langcodes_supported, lang)
		end
		error("This module currently only works for lang=" .. concat(langcodes_supported, "/"))
	end
	local lang = require("Module:languages").getByCode(langcode)
	local langname = lang:getCanonicalName()

	local params = {
		["head"] = {list = true},
		["nolink"] = boolean_param,
		["nolinkhead"] = {type = "boolean", alias_of = "nolink"},
		["suffix"] = boolean_param,
		["nosuffix"] = boolean_param,
		["json"] = boolean_param,
		["abbr"] = {list = true},
		["pagename"] = {}, -- for testing
	}

	if pos_functions[poscat] then
		local posparams = pos_functions[poscat].params
		if type(posparams) == "function" then
			posparams = posparams(langcode)
		end
		for key, val in pairs(posparams) do
			params[key] = val
		end
	end

	local parargs = frame:getParent().args
	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local user_specified_heads = args.head
	local heads = user_specified_heads
	if args.nolink then
		if #heads == 0 then
			heads = {pagename}
		end
	end

	local data = {
		lang = lang,
		langcode = langcode,
		langname = langname,
		pos_category = poscat,
		categories = {},
		heads = heads,
		user_specified_heads = user_specified_heads,
		no_redundant_head_cat = not user_specified_heads[1],
		genders = {},
		inflections = {},
		categories = {},
		pagename = pagename,
		id = args.id,
		force_cat_output = force_cat,
	}

	data.is_suffix = false
	if args.suffix or (
		not args.nosuffix and pagename:find("^%-") and poscat ~= "suffixes" and poscat ~= "suffix forms"
	) then
		data.is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = m_en_utilities.singularize(poscat)
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	parse_and_insert_inflection(data, args, "abbr", "abbreviation")

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require("Module:headword").full_headword(data)
end


----------------------------------------------- Nouns --------------------------------------------

local function get_noun_inflection_specs(langcode)
	local noun_inflection_specs = {
		{"gen", "genitive singular"},
	}
	if langs_supported[langcode].has_dual then
		insert(noun_inflection_specs, {"du", "nominative dual"})
	end
	for _, spec in ipairs {
		{"pl", "nominative plural"},
		{"genpl", "genitive plural"},
		{"f", "female equivalent"},
		{"m", "male equivalent"},
		{"n", "neuter equivalent"},
		{"marr", "traditional married form"},
		{"unmarr", "traditional unmarried form"},
		{"dim", "diminutive"},
		{"pej", "pejorative"},
		{"aug", "augmentative"},
		{"adj", "related adjective"},
		{"poss", "possessive adjective"},
		{"dem", "demonym"},
		{"fdem", "female demonym"},
	} do
		insert(noun_inflection_specs, spec)
	end
	return noun_inflection_specs
end
	
local function get_noun_pos(is_proper)

	return {
		params = function(langcode)
			local params = {
				["indecl"] = boolean_param,
				[1] = {list = "g", disallow_holes = true, type = "genders", flatten = true}, -- gender(s)
			}
			for _, spec in ipairs(get_noun_inflection_specs(langcode)) do
				local param, desc = unpack(spec)
				params[param] = list_param
			end
			params["rel"] = {list = true, alias_of = "adj"}
			return params
		end,
		func = function(args, data)
			-- Compute allowed genders, and map incomplete genders to specs with a "?" in them.
			local genders = {false, "m", "mf", "mfbysense", "f", "n", "g!"}
			local animacies = {false, "in", "anml", "pr", "an!"}
			local numbers = {false, "p", "num!"}
			local allowed_genders = {}
			
			for _, g in ipairs(genders) do
				for _, an in ipairs(animacies) do
					for _, num in ipairs(numbers) do
						local source_gender_parts = {}
						local dest_gender_parts = {}
						local function ins_part(part, partname)
							if part then
								insert(source_gender_parts, part)
								insert(dest_gender_parts, part)
							elseif partname == "g" and num == false or
								partname == "an" and g ~= "f" and g ~= "n" then
								-- allow incomplete gender plurale tantum nouns; also allow incomplete
								-- animacy for fem/neut, where it makes no difference for agreement
								-- purposes; otherwise insert a ? to indicate incomplete gender spec
								insert(dest_gender_parts, "?")
							end
						end
						ins_part(g, "g")
						ins_part(an, "an")
						ins_part(num, "num")
						if #source_gender_parts == 0 then
							allowed_genders["?"] = "?"
						else
							allowed_genders[concat(source_gender_parts, "-")] =
								concat(dest_gender_parts, "-")
						end
						-- "Virile" = masculine personal, allow in the plural and convert appropriately;
						-- "Nonvirile" = anything but masculine personal, allow in the plural;
						-- "Nonpersonal" = anything but personal, i.e. animal or inanimate; allow in the plural.
						allowed_genders["vr-p"] = "m-pr-p"
						allowed_genders["nv-p"] = "nv-p"
						allowed_genders["np-p"] = "np-p"
					end
				end
			end
			
			-- Validate and canonicalize genders.
			for _, g in ipairs(args[1]) do
				if not allowed_genders[g.spec] then
					error("Unrecognized " .. data.langname .. " gender: " .. g.spec)
				else
					g.spec = allowed_genders[g.spec]
				end
			end
			data.genders = args[1]

			if args.indecl then
				insert(data.inflections, {label = glossary_link("indeclinable")})
				insert(data.categories, data.langname .. " indeclinable nouns")
			end

			-- Process all inflections.
			for _, spec in ipairs(get_noun_inflection_specs(data.langcode)) do
				local param, desc = unpack(spec)
				parse_and_insert_inflection(data, args, param, desc)
			end
		end
	}
end

pos_functions["nouns"] = get_noun_pos(false)

pos_functions["proper nouns"] = get_noun_pos(true)


----------------------------------------------- Verbs --------------------------------------------

local function get_verb_pos()
	local verb_inflection_specs = {
		-- order per old [[Module:pl-headword]]
		{"det", "imperfective determinate"},
		{"pf", "perfective"},
		{"impf", "imperfective"},
		{"indet", "indeterminate"},
		{"freq", "frequentative"},
	}
	
	local params = {
		[1] = {default = "?"},
		["def"] = boolean_param,
	}
	for _, spec in ipairs(verb_inflection_specs) do
		local param, desc = unpack(spec)
		params[param] = list_param
	end

	return {
		params = params,
		func = function(args, data)
			local allowed_aspects = require("Module:table").listToSet {
				"pf", "impf", "biasp", "both", "impf-det", "impf-indet", "impf-freq", "?"
			}

			local impf_allowed = true
			local pf_allowed = true
			local indet_allowed = true
			local det_allowed = true
			local freq_allowed = true
			local function insert_label_and_cat(aspect, label)
				-- Preserve qualifiers, labels, references.
				aspect = aspect and m_table.shallowCopy(aspect) or {}
				aspect.term = nil
				aspect.label = label
				insert(data.inflections, aspect)
				insert(data.categories, data.langname .. " " .. label .. " verbs")
			end

			local aspects = m_headword_utilities.parse_term_with_modifiers {
				paramname = 1,
				val = args[1],
				splitchar = ",",
				exclude_mods = {"id"}, -- doesn't make sense for gender specs
			}
			-- Validate and canonicalize aspects.
			for i, aspect in ipairs(aspects) do
				local a = aspect.term
				if not allowed_aspects[a] then
					error("Unrecognized " .. data.langname .. " aspect: " .. a)
				elseif a == "both" then
					a = "biasp"
				elseif a == "impf-det" then
					a = "impf"
					insert_label_and_cat(aspect, "determinate")
					det_allowed = false
				elseif a == "impf-indet" then
					a = "impf"
					insert_label_and_cat(aspect, "indeterminate")
					indet_allowed = false
				elseif a == "impf-freq" then
					a = "impf"
					insert_label_and_cat(aspect, "indeterminate")
					insert_label_and_cat(aspect, "frequentative")
					indet_allowed = false
					freq_allowed = false
				elseif a == "pf" then
					pf_allowed = false
				elseif a == "impf" then
					impf_allowed = false
				end
				aspect.spec = a
				aspect.term = nil
			end
			data.genders = aspects

			if args.def then
				insert_label_and_cat(nil, "defective")
			end

			-- Process all inflections.
			for _, spec in ipairs(verb_inflection_specs) do
				local param, desc = unpack(spec)
				local infls = parse_inflection(data, args, param)
				if infls[1] then
					if param == "pf" and not pf_allowed then
						error("Aspectual-pair perfectives not allowed with perfective-only verb")
					end
					if param == "impf" and not impf_allowed then
						error("Aspectual-pair imperfectives not allowed with imperfective-only verb")
					end
					if param == "det" and not det_allowed then
						error("Aspectual-pair determinates not allowed with imperfective-only determinate verb")
					end
					if param == "indet" and not indet_allowed then
						error("Aspectual-pair indeterminates not allowed with imperfective-only indeterminate or frequentative verb")
					end
					if param == "freq" and not freq_allowed then
						error("Aspectual-pair frequentatives not allowed with imperfective-only frequentative verb")
					end
					insert_inflection(data, infls, desc)
				end
			end
		end
	}
end

pos_functions["verbs"] = get_verb_pos()


----------------------------------------------- Adjectives, Adverbs --------------------------------------------

local function get_adj_adv_pos(pos)
	return {
		params = function(langcode)
			local params = {
				[1] = list_param,
				["dim"] = list_param,
				["sup"] = list_param,
				["nodefsup"] = boolean_param,
			}
			if pos == "adjective" then
				params["adv"] = list_param
				params["indecl"] = boolean_param
			end
			if langcode == "pl" then
				params["mpcomp"] = list_param
				params["mpsup"] = list_param
			end
			return params
		end,
		func = function(args, data)
			local default_sups = {}
			local comps = parse_inflection(data, args, 1)
			if comps[1] then
				lang_data = langs_supported[data.langcode]
				if comps[1].term == "-" then
					if not comps[2] then
						-- Preserve any qualifiers, labels, etc.
						comps[1].label = "not " .. glossary_link("comparable")
						comps[1].term = nil
						insert(data.inflections, comps[1])
						insert(data.categories, data.langname .. " uncomparable " .. data.pos_category)
					else
						-- Preserve any qualifiers, labels, etc.
						comps[1].label = "not generally " .. glossary_link("comparable")
						comps[1].term = nil
						insert(data.inflections, comps[1])
					end
					remove(comps, 1)
				end
				for i, comp in ipairs(comps) do
					if comp.term == "peri" then
						if not lang_data.peri_comp then
							error("Don't know how to form periphrastic comparatives for " .. data.langname)
						end
						comp.term = ("[[%s]] [[%s]]"):format(lang_data.peri_comp, data.pagename)
						if lang_data.sup then
							local default_sup = m_table.shallowCopy(comp)
							default_sup.term = ("[[%s%s]] [[%s]]"):format(lang_data.sup, lang_data.peri_comp,
								data.pagename)
							insert(default_sups, default_sup)
						end
					elseif lang_data.sup then
						local default_sup = m_table.shallowCopy(comp)
						default_sup.term = ("%s%s"):format(lang_data.sup, comp.term)
						insert(default_sups, default_sup)
					end
				end
			end
			insert_inflection(data, comps, "comparative", "comparative")

			local sups = parse_inflection(data, args, "sup")
			if not sups[1] then
				sups = args.nodefsup and {} or {{term = "+"}}
			end
			local combined_sups = {}
			for _, sup in ipairs(sups) do
				if sup.term == "+" then
					for _, def_sup in ipairs(default_sups) do
						def_sup = m_table.shallowCopy(def_sup)
						m_headword_utilities.combine_termobj_qualifiers_labels(def_sup, sup)
						insert(combined_sups, def_sup)
					end
				else
					insert(combined_sups, sup)
				end
			end
			insert_inflection(data, combined_sups, "superlative", "superlative")
			if data.langcode == "pl" then
				parse_and_insert_inflection(data, args, "mpcomp", "Middle Polish comparative")
				parse_and_insert_inflection(data, args, "mpsup", "Middle Polish superlative")
			end
			if pos == "adjective" then
				if args.indecl then
					insert(data.inflections, {label = glossary_link("indeclinable")})
					insert(data.categories, data.langname .. " indeclinable adjectives")
				end
				parse_and_insert_inflection(data, args, "adv", "derived adverb")
			end
			parse_and_insert_inflection(data, args, "dim", "diminutive")
		end,
	}
end

pos_functions["adjectives"] = get_adj_adv_pos("adjective")
pos_functions["adverbs"] = get_adj_adv_pos("adverb")


----------------------------------------------- Participles --------------------------------------------

local function get_part_pos()
	local params = {
		[1] = {},
		["a"] = list_param,
	}

	return {
		params = params,
		func = function(args, data)
			if data.langcode ~= "pl" then
				error("Internal error: Unable to handle languages other than Polish for participles: " .. data.langname)
			end
			-- Compute allowed aspects, and map incomplete aspects to specs with a "?" in them.
			local allowed_aspects = require("Module:table").listToSet {
				"pf", "impf", "biasp", "both", "pf-it", "pf-sem", "impf-it", "impf-dur", "?"
			}
			local allowed_types = require("Module:table").listToSet {
				"pass", "act", "ant-adv", "cont-adv", "?"
			}

			local function insert_label_and_cat(aspect, label, nolink)
				if not nolink then
					label = glossary_link(label)
				end
				-- Preserve qualifiers, labels, references.
				aspect = aspect and m_table.shallowCopy(aspect) or {}
				aspect.term = nil
				aspect.label = label
				insert(data.inflections, aspect)
				insert(data.categories, data.langname .. " " .. label .. " participles")
			end

			local aspects = m_headword_utilities.parse_term_list_with_modifiers {
				paramname = "a",
				forms = args.a,
				splitchar = ",",
				exclude_mods = {"id"}, -- doesn't make sense for gender specs
			}

			-- Validate and canonicalize aspects.
			for i, aspect in ipairs(aspects) do
				local a = aspect.term
				if not allowed_aspects[a] then
					error("Unrecognized " .. data.langname .. " participle aspect: " .. a)
				elseif a == "both" then
					a = "biasp"
				elseif a == "impf-it" then
					a = "impf"
					insert_label_and_cat(aspect, "iterative")
				elseif a == "impf-dur" then
					a = "impf"
					insert_label_and_cat(aspect, "durative")
				elseif a == "pf-it" then
					a = "pf"
					insert_label_and_cat(aspect, "iterative")
				elseif a == "pf-sem" then
					a = "pf"
					insert_label_and_cat(aspect, "semelfactive")
				end
				aspect.spec = a
				aspect.term = nil
			end
			data.genders = aspects

			-- Validate or autodetect participle type.
			local function matches_parttype(typ)
				local endings = langs_supported[data.langcode][typ]
				if not endings then
					return false
				end
				for _, ending in ipairs(endings) do
					if rfind(data.pagename, ending) then
						return true
					end
				end
				return false
			end
			local ptype = args[1]
			if ptype then
				if not allowed_types[ptype] then
					error("Unrecognized " .. data.langname .. " participle type: " .. ptype)
				end
			elseif matches_parttype("act") then -- biegnący
				ptype = "act"			
			elseif matches_parttype("pass") then -- otwarty, uwielbiany, legły
				ptype = "pass"
			elseif matches_parttype("cont_adv") then
				ptype = "cont-adv"
			elseif matches_parttype("ant_adv") then
				ptype = "ant-adv"
			elseif (data.pagename:find("%-participle$") or data.pagename:find("%-part$")) and
				mw.title.getCurrentTitle().nsText == "Template" then
				ptype = "pass"
			else
				error(("Missing %s participle type and can't infer from pagename '%s'"):format(data.langname,
					data.pagename))
			end

			if ptype == "act" then
				insert_label_and_cat(nil, "active adjectival", true)
			elseif ptype == "pass" then
				insert_label_and_cat(nil, "passive adjectival", true)
			elseif ptype == "cont-adv" then
				insert_label_and_cat(nil, "contemporary adverbial", true)
			elseif ptype == "ant-adv" then
				insert_label_and_cat(nil, "anterior adverbial", true)
			end
		end
	}
end

pos_functions["participles"] = get_part_pos()


return export
