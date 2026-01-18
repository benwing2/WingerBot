local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")
local lang = require("Module:languages").getByCode("nl")
local langname = lang:getCanonicalName()

local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
-- local romut_module = "Module:romance utilities"
local nl_common_module = "Module:nl-common"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_string_utilities = require_when_needed("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}

local insert = table.insert

local function track(page)
	require("Module:debug").track("nl-headword/" .. page)
	return true
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local poscat = frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local params = {
		["head"] = list_param,
		["id"] = true,
		-- ["splithyph"] = boolean_param,
		["nolinkhead"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = true, -- for testing
	}

	if pos_functions[poscat] then
		for key, val in pairs(pos_functions[poscat].params) do
			params[key] = val
		end
	end

	local parargs = frame:getParent().args
	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local user_specified_heads = args.head
	local heads = user_specified_heads
	if args.nolinkhead then
		if not heads[1] then
			heads = {pagename}
		end
	else
		--local romut = require(romut_module)
		--local auto_linked_head = romut.add_links_to_multiword_term(pagename, args.splithyph, no_split_apostrophe_words)
		--if not heads[1] then
		--	heads = {auto_linked_head}
		--else
			for i, head in ipairs(heads) do
				--if head:find("^~") then
				--	head = romut.apply_link_modifiers(auto_linked_head, usub(head, 2))
				--	heads[i] = head
				--end
				if head == auto_linked_head then
					track("redundant-head")
				end
			end
		--end
	end

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = heads,
		user_specified_heads = user_specified_heads,
		no_redundant_head_cat = not user_specified_heads[1],
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		force_cat_output = force_cat,
	}

	local is_suffix = false
	if pagename:find("^%-") and poscat ~= "suffix forms" then
		is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = require(en_utilities_module).singularize(poscat)
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data, is_suffix)
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require("Module:headword").full_headword(data)
end

----------------------------------------------- Utilities --------------------------------------------

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

local function parse_term_list_with_modifiers(data, paramname, list)
	return m_headword_utilities.parse_term_list_with_modifiers {
		paramname = paramname,
		forms = list,
		splitchar = ",",
		include_mods = {"g"},
		frob = function(term)
			return frob_term_with_hash(term, data.pagename)
		end,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- `plpos` is the plural part of speech, used in [[Category:LANGNAME PLPOS with red links in their headword lines]].
-- `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel, check_missing, plppos)
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
		check_missing = check_missing,
		lang = lang,
		plpos = plpos,
	}
end

-- Insert the parsed inflections in `infls` (as parsed by `parse_inflection`) into `data.inflections`, with label
-- `label` and optional accelerator spec `accel`.
local function insert_inflection(data, terms, label, accel, check_missing, plpos)
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel and {form = accel} or nil,
		check_missing = check_missing,
		lang = lang,
		plpos = plpos,
	}
end


----------------------------------------------- Adjectives, Adverbs --------------------------------------------

-- Display additional inflection information for an adjective
pos_functions["adjectives"] = {
	params = {
		inv = boolean_param,
		pred = boolean_param,
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
	},
	func = function(args, data)
		local pagename = data.pagename
		local mode

		if args.inv then
			mode = "inv"
			insert(data.inflections, {label = glossary_link("invariable")})
			insert(data.categories, "Dutch indeclinable adjectives")
		elseif args.pred then
			mode = "pred"
			insert(data.inflections, {label = "used only [[predicative]]ly"})
			insert(data.categories, "Dutch predicative-only adjectives")
		end

		if args[1][1] == "-" then
			insert(data.inflections, {label = "not " .. glossary_link("comparable")})
		else
			-- Gather parameters
			local comparatives = parse_term_list_with_modifiers(data, {"1", "comp"}, args[1])
			local superlatives = parse_term_list_with_modifiers(data, {"2", "sup"}, args[2])

			-- Generate forms if none were given
			if not comparatives[1] then
				if mode == "inv" or mode == "pred" then
					comparatives = {{term = "peri"}}
				else
					comparatives = {{term = require("Module:nl-adjectives").make_comparative(pagename)}}
				end
			end

			if not superlatives[1] then
				if mode == "inv" or mode == "pred" then
					superlatives = {{term = "peri"}}
				else
					-- Add preferred periphrastic superlative, if necessary
					if
						pagename:find("[iï]de$") or pagename:find("[^eio]e$") or
						pagename:find("s$") or pagename:find("sch$") or pagename:find("x$") or
						pagename:find("sd$") or pagename:find("st$") or pagename:find("sk$") then
						superlatives = {{term = "peri"}}
					end

					insert(superlatives, {term = require("Module:nl-adjectives").make_superlative(pagename)})
				end
			end

			-- Replace "peri" with phrase
			for _, val in ipairs(comparatives) do
				if val.term == "peri" then val.term = "[[meer]] " .. pagename end
			end

			for _, val in ipairs(superlatives) do
				if val.term == "peri" then val.term = "[[meest]] " .. pagename end
			end

			insert_inflection(data, comparatives, "<<comparative>>")
			insert_inflection(data, superlatives, "<<superlative>>")
		end
	end
}

-- Display additional inflection information for an adverb
pos_functions["adverbs"] = {
	params = {
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
		},
	func = function(args, data)
		local pagename = data.pagename

		if args[1][1] then
			-- Gather parameters
			local comparatives = parse_term_list_with_modifiers(data, {"1", "comp"}, args[1])
			local superlatives = parse_term_list_with_modifiers(data, {"2", "sup"}, args[2])

			if not superlatives[1] then
				superlatives = {{term = pagename .. "st"}}
			end

			insert_inflection(data, comparatives, "<<comparative>>")
			insert_inflection(data, superlatives, "<<superlative>>")
		end
	end
}


----------------------------------------------- Nouns --------------------------------------------

local allowed_genders = m_table.listToSet { "c", "p", "m", "f", "n", "?" }

-- Display information for a noun's gender
-- This is separate so that it can also be used for proper nouns
local function noun_gender(args, data)
	-- Validate genders.
	local saw_f, saw_m, saw_f_without_m, saw_m_without_f, saw_p, saw_non_p
	for _, gspec in ipairs(args[1]) do
		local g = gspec.spec
		if not allowed_genders[g] then
			error("Unrecognized " .. langname .. " gender: " .. g)
		end
		if g == "f" then
			saw_f = true
			if not saw_m then
				saw_f_without_m = true
			end
		end
		if g == "m" then
			saw_m = true
			if not saw_f then
				saw_m_without_f = true
			end
		end
		if g == "p" then
			saw_p = true
		elseif g ~= "?" then
			saw_non_p = true
		end
	end
	data.genders = args[1]

	-- Most nouns that are listed as f+m should really have only f.
	if saw_f_without_m and saw_m then
		insert(data.categories, langname .. " nouns with f+m gender")
	end
	-- Some of these nouns may be like m+f nouns but some are legitimately either masculine or feminine.
	if saw_m_without_f and saw_f then
		insert(data.categories, langname .. " nouns with m+f gender")
	end

	return saw_p, saw_non_p
end

local function generate_plurals(pagename)
	local m_common = require(nl_common_module)
	local generated = {}

	generated["-s"] = pagename .. "s"
	generated["-'s"] = pagename .. "'s"

	local stem_FF = m_common.add_e(pagename, false, false)
	local stem_TF = m_common.add_e(pagename, true, false)
	local stem_FT = m_common.add_e(pagename, false, true)

	generated["-es"] = stem_FF .. "s"
	generated["-@es"] = stem_TF .. "s"
	generated["-:es"] = stem_FT .. "s"

	generated["-en"] = stem_FF .. "n"
	generated["-@en"] = stem_TF .. "n"
	generated["-:en"] = stem_FT .. "n"

	generated["-eren"] = m_common.add_e(pagename .. (pagename:find("n$") and "d" or ""), false, false) .. "ren"
	generated["-:eren"] = stem_FT .. "ren"

	if pagename:find("f$") then
		local stem = pagename:gsub("f$", "v")
		local stem_FF = m_common.add_e(stem, false, false)
		local stem_TF = m_common.add_e(stem, true, false)
		local stem_FT = m_common.add_e(stem, false, true)

		generated["-ves"] = stem_FF .. "s"
		generated["-@ves"] = stem_TF .. "s"
		generated["-:ves"] = stem_FT .. "s"

		generated["-ven"] = stem_FF .. "n"
		generated["-@ven"] = stem_TF .. "n"
		generated["-:ven"] = stem_FT .. "n"

		generated["-veren"] = stem_FF .. "ren"
		generated["-:veren"] = stem_FT .. "ren"
	elseif pagename:find("s$") then
		local stem = pagename:gsub("s$", "z")
		local stem_FF = m_common.add_e(stem, false, false)
		local stem_TF = m_common.add_e(stem, true, false)
		local stem_FT = m_common.add_e(stem, false, true)

		generated["-zes"] = stem_FF .. "s"
		generated["-@zes"] = stem_TF .. "s"
		generated["-:zes"] = stem_FT .. "s"

		generated["-zen"] = stem_FF .. "n"
		generated["-@zen"] = stem_TF .. "n"
		generated["-:zen"] = stem_FT .. "n"

		generated["-zeren"] = stem_FF .. "ren"
		generated["-:zeren"] = stem_FT .. "ren"
	elseif pagename:find("heid$") then
		generated["-heden"] = pagename:gsub("heid$", "heden")
	end

	return generated
end

local function generate_diminutive(pagename, dim)
	local m_common = require(nl_common_module)
	if dim == "+" then
		dim = m_common.default_dim(pagename)
	elseif dim == "++" then
		dim = m_common.default_dim(pagename, "final multisyllable stress")
	elseif dim == "++/+" then
		dim = m_common.default_dim(pagename, false, "modifier final multisyllable stress")
	elseif dim == "++/++" then
		dim = m_common.default_dim(pagename, "final multisyllable stress", "modifier final multisyllable stress")
	elseif dim == "+first" then
		dim = m_common.default_dim(pagename, false, false, "first only")
	elseif dim == "++first" then
		dim = m_common.default_dim(pagename, "final multisyllable stress", false, "first only")
	elseif dim:sub(1, 1) == "-" then
		dim = pagename .. dim:sub(2)
	end
	return dim
end

pos_functions["proper nouns"] = {
	params = {
		[1] = {list = "g", type = "genders", flatten = true, default = "?", disallow_holes = true},
		[2] = {list = "pl", disallow_holes = true},
		adj = list_param,
		mdem = list_param,
		fdem = list_param,
		},
	func = function(args, data)
		local saw_p, saw_non_p = noun_gender(args, data)

		local plurals = parse_term_list_with_modifiers(data, {"2", "pl"}, args[2])
		local adjectives = parse_term_list_with_modifiers(data, "adj", args["adj"])
		local mdems = parse_term_list_with_modifiers(data, "mdem", args["mdem"])
		local fdems = parse_term_list_with_modifiers(data, "fdem", args["fdem"])
		local nm = #mdems
		local nf = #fdems
		local demonyms = {label = "demonym"}

		-- plural for certain words like [[Amerika]]
		insert_inflection(data, plurals, "plural", "p")

		--adjective for toponyms
		insert_inflection(data, adjectives, "adjective")

		--demonyms for toponyms
		if nm + nf > 0 then
			for i, m in ipairs(mdems) do
				if not m.genders then
					m.genders = {"m"}
				end
				demonyms[i] = m
			end
			for i, f in ipairs(fdems) do
				if not f.genders then
					f.genders = {"f"}
				end
				demonyms[i + nm] = f
			end
			insert(data.inflections, demonyms)
		end
	end
}

local function process_plurals(data, plurals, plural_only)
	local pagename = data.pagename

	if plural_only then
		if plurals[1] then
			error("Can't specify plurals of plurale tantum noun")
		end
		insert(data.inflections, {label = glossary_link("plural only")})
	elseif plurals[1] and plurals[1].term == "-" then
		insert(data.inflections, {label = glossary_link("uncountable")})
		insert(data.categories, langname .. " uncountable nouns")
	else
		local generated = generate_plurals(pagename)

		-- Process the plural forms
		for i, pobj in ipairs(plurals) do
			local p = pobj.term
			-- Is this a shortcut form?
			if p:sub(1,1) == "-" then
				if not generated[p] then
					error("The shortcut plural " .. p .. " could not be generated.")
				end

				if p:sub(-2) == "es" then
					insert(data.categories, "Dutch nouns with plural in -es")
				elseif p:sub(-1) == "s" then
					insert(data.categories, "Dutch nouns with plural in -s")
				elseif p:sub(-4) == "eren" then
					insert(data.categories, "Dutch nouns with plural in -eren")
				else
					insert(data.categories, "Dutch nouns with plural in -en")
				end

				if p:sub(2,2) == ":" then
					insert(data.categories, "Dutch nouns with lengthened vowel in the plural")
				end

				p = generated[p]
			-- Not a shortcut form, but the plural form specified directly.
			else
				for _, g in pairs(generated) do
					if g == p then
						track("plural-matches-generated-form")
						break
					end
				end

				if not pagename:find("[ -]") then
					if p == pagename then
						insert(data.categories, "Dutch indeclinable nouns")
					elseif
						p == pagename .. "den" or p == pagename:gsub("ee$", "eden") or
						p == pagename .. "des" or p == pagename:gsub("ee$", "edes") then
						insert(data.categories, "Dutch nouns with plural in -den")
					elseif p == pagename:gsub("([ao])$", "%1%1ien") or p == pagename:gsub("oe$", "oeien") then
						insert(data.categories, "Dutch nouns with glide vowel in plural")
					elseif p == pagename:gsub("y$", "ies") then
						insert(data.categories, "Dutch nouns with English plurals")
					elseif
						p == pagename:gsub("a$", "ae") or
						p == pagename:gsub("[ei]x$", "ices") or
						p == pagename:gsub("is$", "es") or
						p == pagename:gsub("men$", "mina") or
						p == pagename:gsub("ns$", "ntia") or
						p == pagename:gsub("o$", "ones") or
						p == pagename:gsub("o$", "onen") or
						p == pagename:gsub("s$", "tes") or
						p == pagename:gsub("us$", "era") or
						p == mw.ustring.gsub(pagename, "[uü]s$", "i") or
						p == mw.ustring.gsub(pagename, "[uü]m$", "a") or
						p == pagename:gsub("x$", "ges") then
						insert(data.categories, "Dutch nouns with Latin plurals")
					elseif
						p == pagename:gsub("os$", "oi") or
						p == pagename:gsub("on$", "a") or
						p == pagename:gsub("a$", "ata") then
						insert(data.categories, "Dutch nouns with Greek plurals")
					else
						insert(data.categories, "Dutch irregular nouns")
					end
				end
			end

			pobj.term = p
		end

		-- Add the plural forms
		m_headword_utilities.insert_inflection {
			headdata = data,
			terms = plurals,
			label = "plural",
			accel = {form = "p"},
			check_missing = true,
			lang = lang,
			plpos = "nouns",
			request = true,
		}
	end
end

local function do_noun_ancillary_inflections(data, args)
	local function parse_and_insert_noun_inflection(field, label, accel)
		parse_and_insert_inflection(data, args, field, label, accel)
	end

	parse_and_insert_noun_inflection("f", "feminine")
	parse_and_insert_noun_inflection("m", "masculine")
end

-- Display additional inflection information for a noun
pos_functions["nouns"] = {
	params = {
		[1] = {list = "g", type = "genders", flatten = true, default = "?", disallow_holes = true},
		[2] = {list = "pl", disallow_holes = true},
		[3] = {list = "dim", disallow_holes = true},

		["f"] = list_param,
		["m"] = list_param,
	},
	func = function(args, data)
		local pagename = data.pagename

		local saw_p, saw_non_p = noun_gender(args, data)
		local plurals = parse_term_list_with_modifiers(data, {"2", "pl"}, args[2])
		local diminutives = parse_term_list_with_modifiers(data, {"3", "dim"}, args[3])

		process_plurals(data, plurals, saw_p and not saw_non_p)

		if diminutives[1] and diminutives[1].term == "-" then
			-- do nothing
		else
			-- Process the diminutive forms
			for _, dimobj in ipairs(diminutives) do
				dimobj.term = generate_diminutive(pagename, dimobj.term)
				if not dimobj.genders then
					dimobj.genders = {"n"}
				end
			end
		end

			-- Add the diminutive forms
		m_headword_utilities.insert_inflection {
			headdata = data,
			terms = diminutives,
			label = "<<diminutive>>",
			accel = {form = "diminutive"},
			request = true,
		}

		do_noun_ancillary_inflections(data, args)
	end
}

-- Display additional inflection information for a diminutive noun
pos_functions["diminutive nouns"] = {
	params = {
		[1] = {list = "pl", disallow_holes = true},
	},
	func = function(args, data)
		local plurals = parse_term_list_with_modifiers(data, {"1", "pl"}, args[1])
		if plurals[1] and plurals[1].term == "p" then
			if m_headword_utilities.termobj_has_qualifiers_or_labels(plurals[1]) then
				error("Can't specify qualifiers or labels with 'p' for plural-only diminutive noun")
			elseif plurals[2] then
				error("Can't specify plurals of plurale tantum noun")
			end
			data.genders = {"p"}
			process_plurals(data, {}, "plural only")
		else
			data.genders = {"n"}
			if not plurals[1] then
				plurals = {{term = "-s"}}
			end
			process_plurals(data, plurals)
		end
	end
}

-- Display additional inflection information for diminutiva tantum nouns ({{nl-noun-dim-tant}}).
pos_functions["diminutiva tantum nouns"] = {
	params = {
		[1] = {list = "pl", disallow_holes = true},
		["f"] = {list = true},
		["m"] = {list = true},
	},
	func = function(args, data)
		data.pos_category = "nouns"
		insert(data.categories, "Dutch diminutiva tantum")
		data.genders = {"n"}
		local plurals = parse_term_list_with_modifiers(data, {"1", "pl"}, args[1])
		if not plurals[1] then
			plurals = {{term = "-s"}}
		end
		process_plurals(data, plurals)
		do_noun_ancillary_inflections(data, args)
	end
}

pos_functions["past participles"] = {
	params = {
		[1] = {},
	},
	func = function(args, data)
		if args[1] == "-" then
			insert(data.inflections, {label = "not used adjectivally"})
			insert(data.categories, "Dutch non-adjectival past participles")
		end
	end
}


----------------------------------------------- Verbs --------------------------------------------

pos_functions["verbs"] = {
	params = {
		[1] = {},
		},
	func = function(args, data)
		if args[1] == "-" then
			insert(data.inflections, {label = "not inflected"})
			insert(data.categories, "Dutch uninflected verbs")
		end
	end
}

return export
