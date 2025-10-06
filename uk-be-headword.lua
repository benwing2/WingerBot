local export = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local lang, langcode, langname
local com
local m_links = require("Module:links")

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")

local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
local inflection_utilities_module = "Module:inflection utilities"
local string_utilities_module = "Module:string utilities"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_inflection_utilities = require_when_needed(inflection_utilities_module)
local m_string_utilities = require_when_needed(string_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}
local list_comp = {list = "comp", disallow_holes = true}
local list_sup = {list = "sup", disallow_holes = true}

local concat = table.concat
local insert = table.insert

local pos_functions = {}

local function track(page)
	require("Module:debug").track(langcode .. "-headword/" .. page)
	return true
end

local function check_if_accent_needed(val, data)
	val = m_links.remove_links(val)
	if com.needs_accents(val) then
		if langcode == "uk" and not data.unknown_stress then
			error("Stress must be supplied using an acute accent: '" .. val .. "' (use unknown_stress=1 if stress is truly unknown)")
		end
		local pos = require(en_utilities_module).singularize(data.pos_category)
		insert(data.categories, "Requests for accents in " .. langname .. " " .. pos .. " entries")
	end
	if com.is_multi_stressed(val) then
		error("Multi-stressed form '" .. val .. "' not allowed")
	end
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(data, args, field, is_head)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	return m_headword_utilities.parse_term_list_with_modifiers {
		forms = args[argfield],
		paramname = field,
		splitchar = ",",
		is_head = is_head,
		include_mods = {"tr"},
		frob = function(term)
			check_if_accent_needed(term, data)
			return term
		end,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel_form)
	local terms = parse_inflection(data, args, field)
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel_form and {form = accel_form} or nil,
	}
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local args = frame:getParent().args
	local PAGENAME = mw.loadData("Module:headword/data").pagename

	local required = {required = true}
	local iparams = {
		[1] = required,
		["lang"] = required,
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)
	local poscat = iargs[1]
	langcode = iargs.lang
	if langcode ~= "uk" and langcode ~= "be" then
		error("This module currently only works for lang=uk and lang=be")
	end
	lang = require("Module:languages").getByCode(langcode)
	langname = langcode == "uk" and "Ukrainian" or "Belarusian"
	com = langcode == "uk" and require("Module:uk-common") or require("Module:be-common")

	local params = {
		[1] = {list = "head", disallow_holes = true},
		["unknown_stress"] = boolean_param,
		["pagename"] = true,
		["id"] = true,
	}

	if pos_functions[poscat] then
		for key, val in pairs(pos_functions[poscat].params) do
			params[key] = val
		end
	end

	local parargs = frame:getParent().args
	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local data = {
		lang = lang,
		no_redundant_head_cat = true,
		pos_category = poscat,
		categories = {},
		genders = {},
		inflections = {},
		id = args.id,
		pagename = pagename,
		unknown_stress = args.unknown_stress,
		frame = frame,
	}

	if not pos_functions[poscat] or not pos_functions[poscat].no_parse_heads or
		not pos_functions[poscat].no_parse_heads(args) then
		data.heads = parse_inflection(data, args, {1, "head"}, "is_head") 
		if not data.heads[1] then
			data.heads = {{term = pagename}}
		end
	end

	if args.unknown_stress then
		insert(data.inflections, {label = "unknown stress"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	return require("Module:headword").full_headword(data) .. (data.extra_text or "")
end


local function make_gloss_text(text)
	return '<span class="mention-gloss-paren">(</span>' ..
		'<span class="mention-gloss">' .. text ..
		'</span><span class="mention-gloss-paren">)</span>'
end


local function noun_no_parse_heads(args)
	return not args[3][1] and not args[4][1] and not args[5][1] and not args[1][2] and
		args[1][1] and args[1][1]:find("<")
end

local function get_noun_pos(is_proper)
	return {
		params = {
			[2] = {list = "g", type = "genders", disallow_holes = true, flatten = true},
			[3] = {list = "gen", disallow_holes = true},
			[4] = {list = "pl", disallow_holes = true},
			[5] = {list = "genpl", disallow_holes = true},
			["lemma"] = list_param,
			["m"] = list_param,
			["f"] = list_param,
			["adj"] = list_param,
			["poss"] = list_param,
			["dim"] = list_param,
			["aug"] = list_param,
			["pej"] = list_param,
			["dem"] = list_param,
			["fdem"] = list_param,
			["unknown_gender"] = boolean_param,
			["unknown_animacy"] = boolean_param,
		},
		-- set this to avoid problems with cases like {{uk-noun|((ґандж<>,ґандж<F>))}},
		-- which will otherwise throw an error
		no_parse_heads = noun_no_parse_heads,
		func = function(args, data)
			-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw
			-- arguments come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the
			-- inflections are given; <<..>> in the label is linked to the glossary).
			local function handle_infl(field, label)
				parse_and_insert_inflection(data, args, field, label)
			end

			-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw
			-- arguments come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the
			-- inflections are given; <<..>> in the label is linked to the glossary).
			local function parse_infl(field, label)
				parse_and_insert_inflection(data, args, field, label)
			end

			local genitives, plurals, genitive_plurals, usuallysg
			if noun_no_parse_heads(args) then
				args[1] = args[1][1]
				local alternant_spec = require("Module:" .. langcode .. "-noun").do_generate_forms(args, nil, true)
				local footnote_obj

				local function convert_formobjs_to_termobjs(formobjs)
					local termobjs = {}
					if formobjs then
						for _, formobj in ipairs(formobjs) do
							local termobj = {
								term = langcode == "uk" and com.remove_monosyllabic_stress(formobj.form) or
									com.remove_monosyllabic_accents(formobj.form)
							}
							if formobj.footnotes then
								-- FIXME, we (or rather, [[Module:inflection utilities]]) should recognize labels like
								-- "rare" and "archaic" and convert them automatically to labels.
								local quals, refs =
									m_inflection_utilities.convert_footnotes_to_qualifiers_and_references(
										formobj.footnotes)
								termobj.q = quals
								termobj.refs = refs
							end
							insert(termobjs, termobj)
						end
					end
					if not termobjs[1] then
						termobjs = {{term = "-"}}
					end
					return termobjs
				end
				if alternant_spec.number == "pl" then
					data.heads = args.lemma[1] and parse_inflection(data, args, "lemma", "is_head") or
						convert_formobjs_to_termobjs(alternant_spec.forms.nom_p_linked)
					genitives = convert_formobjs_to_termobjs(alternant_spec.forms.gen_p)
					plurals = {{term = "-"}}
					genitive_plurals = {{term = "-"}}
				else
					data.heads = args.lemma[1] and parse_inflection(data, args, "lemma", "is_head") or
						convert_formobjs_to_termobjs(alternant_spec.forms.nom_s_linked)
					genitives = convert_formobjs_to_termobjs(alternant_spec.forms.gen_s)
					if alternant_spec.number == "sg" then
						plurals = {{term = "-"}}
						genitive_plurals = {{term = "-"}}
					else
						plurals = convert_formobjs_to_termobjs(alternant_spec.forms.nom_p)
						genitive_plurals = convert_formobjs_to_termobjs(alternant_spec.forms.gen_p)
					end
				end
				if args[2][1] then
					data.genders = args[2]
				else
					local gender_specs = {}
					for _, g in ipairs(alternant_spec.genders) do
						insert(gender_specs, {spec = g})
					end
					data.genders = gender_specs
				end
				
				usuallysg = alternant_spec.usuallysg
			else
				data.genders = args[2]
				if not data.genders[1] then
					if mw.title.getCurrentTitle().nsText ~= "Template" then
						error("Gender must be specified")
					else
						data.genders = {{spec = "m-in"}}
					end
				end

				genitives = parse_inflection(data, args, {3, "gen"})
				plurals = parse_inflection(data, args, {4, "pl"})
				genitive_plurals = parse_inflection(data, args, {5, "genpl"})

				if genitives[1] and genitives[1].term ~= "-" then
					-- don't track for indeclinables, which legitimately use the old-style syntax
					track(langcode .. "-noun-old-style")
				end
			end

			-- Validate the genders.
			local singular_genders = {}
			local plural_genders = {}

			local allowed_genders = {"m", "f", "n", "mf", "mfbysense"}
			if langcode == "be" or args.unknown_gender then
				insert(allowed_genders, "?")
			end
			local allowed_animacies = {"pr", "anml", "in"}
			if langcode == "be" or args.unknown_animacy then
				insert(allowed_animacies, "?")
			end
			
			for _, gender in ipairs(allowed_genders) do
				for _, animacy in ipairs(allowed_animacies) do
					singular_genders[gender .. "-" .. animacy] = true
					plural_genders[gender .. "-" .. animacy .. "-p"] = true
				end
			end
			
			if langcode == "be" then
				singular_genders["?"] = true
				plural_genders["?-p"] = true
			end

			local seen_gender = nil
			local seen_animacy = nil

			for _, gspec in ipairs(data.genders) do
				local g = gspec.spec
				if not singular_genders[g] and not plural_genders[g] then
					if g:match("%-an%-") or g:match("%-an$") then
						error("Invalid animacy 'an'; use 'pr' for people, 'anml' for animals: " .. g)
					end
					error("Unrecognized gender: " .. g .. " (should be e.g. 'm-pr' for masculine personal, 'f-anml-p' for feminine animal plural, or 'n-in' for neuter inanimate)")
				end
			end

			-- Add the genitive forms.
			if genitives[1] and genitives[1].term == "-" then
				insert(data.inflections, {label = glossary_link("indeclinable")})
				insert(data.categories, langname .. " indeclinable nouns")
			else
				genitives.label = "genitive"
				genitives.request = true
				insert(data.inflections, genitives)
			end

			-- Add the plural forms.
			if genitives[1] and genitives[1].term == "-" then
				if plurals[1] or genitive_plurals[1] then
					error("Can't specify nominative or genitive plurals of a plural-only term")
				end
			elseif plural_genders[data.genders[1].spec] then
				insert(data.inflections, {label = glossary_link("plural only")})
			elseif plurals[1] and plurals[1].term == "-" then
				insert(data.inflections, {label = glossary_link("uncountable")})
				insert(data.categories, langname .. " uncountable nouns")
			else
				if usuallysg then
					insert(data.inflections, {label = "usually " .. glossary_link("uncountable")})
					insert(data.categories, langname .. " uncountable nouns")
				end
				plurals.label = "nominative plural"
				plurals.request = true
				insert(data.inflections, plurals)
				if genitive_plurals[1] then
					-- allow the genitive plural to be unsupplied; formerly there
					-- was no genitive plural param
					if genitive_plurals[1].term == "-" then
						-- handle case where there's no genitive plural (e.g. ага́)
						insert(data.inflections, {label = "no genitive plural"})
					else
						genitive_plurals.label = "genitive plural"
						insert(data.inflections, genitive_plurals)
					end
				end
			end

			handle_infl("m", "male equivalent")
			handle_infl("f", "female equivalent")
			handle_infl("adj", "<<relational adjective>>")
			handle_infl("poss", "<<possessive adjective>>")
			handle_infl("dim", "<<diminutive>>")
			handle_infl("aug", "<<augmentative>>")
			handle_infl("pej", "<<pejorative>>")
			handle_infl("dem", "<<demonym>>")
			handle_infl("fdem", "female <<demonym>>")
		end
	}
end

pos_functions["proper nouns"] = get_noun_pos(true)
pos_functions["nouns"] = get_noun_pos(false)

pos_functions["verbs"] = {
	params = {
		[2] = {default = "?"},
		["pf"] = list_param,
		["impf"] = list_param,
	},
	func = function(args, data)
		-- Aspect
		local aspect = args[2]

		if aspect == "both" then
			aspect = "biasp"
		elseif aspect ~= "pf" and aspect ~= "impf" and aspect ~= "biasp" and aspect ~= "?" then
			error("Unrecognized aspect: '" .. aspect .. "'")
		end
		insert(data.genders, aspect)

		if args.pf[1] and aspect == "pf" then
			error("Can't specify perfective counterparts for a perfective verb")
		end
		if args.impf[1] and aspect == "impf" then
			error("Can't specify imperfective counterparts for an imperfective verb")
		end

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw
		-- arguments come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the
		-- inflections are given; <<..>> in the label is linked to the glossary).
		local function handle_infl(field, label)
			parse_and_insert_inflection(data, args, field, label)
		end

		handle_infl("impf", "imperfective")
		handle_infl("pf", "perfective")
	end
}

pos_functions["adjectives"] = {
	params = {
		[2] = list_comp,
		[3] = list_sup,
		["adv"] = list_param,
		["absn"] = list_param,
		["dim"] = list_param,
		["indecl"] = boolean_param,
	},
	func = function(args, data)
		if args.indecl then	
			insert(data.inflections, {label = "indeclinable"})
			insert(data.categories, langname .. " indeclinable adjectives")
		end

		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw
		-- arguments come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the
		-- inflections are given; <<..>> in the label is linked to the glossary).
		local function handle_infl(field, label)
			parse_and_insert_inflection(data, args, field, label)
		end

		handle_infl({2, "comp"}, "comparative")
		handle_infl({3, "sup"}, "superlative")
		handle_infl("adv", "adverb")
		handle_infl("absn", "abstract noun")
		handle_infl("dim", "diminutive")
	end
}

pos_functions["adverbs"] = {
	params = {
		[2] = list_comp,
		[3] = list_sup,
		["dim"] = list_param,
	},
	func = function(args, data)
		-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw
		-- arguments come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the
		-- inflections are given; <<..>> in the label is linked to the glossary).
		local function handle_infl(field, label)
			parse_and_insert_inflection(data, args, field, label)
		end

		handle_infl({2, "comp"}, "comparative")
		handle_infl({3, "sup"}, "superlative")
		handle_infl("dim", "diminutive")
	end
}

return export
