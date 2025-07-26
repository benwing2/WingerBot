-- This module contains code for Galician headword templates.
-- Templates covered are:
-- * {{gl-noun}}, {{gl-reinteg-noun}}, {{gl-proper noun}};
-- * {{gl-verb}}, {{gl-reinteg-verb}};
-- * {{gl-adj}}, {{gl-reinteg-adj}}, {{gl-adj-comp}}, {{gl-adj-sup}};
-- * {{gl-det}};
-- * {{gl-pron-adj}};
-- * {{gl-contr-adj}};
-- * {{gl-pp}};
-- * {{gl-cardinal}};
-- * {{gl-adv}}.
-- See [[Module:gl-verb]] and [[Module:gl-reinteg-verb]] for Galician conjugation templates.

local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local m_strutils = require("Module:string utilities")
local rfind = m_strutils.find
local rmatch = m_strutils.match
local rsplit = m_strutils.split
local usub = m_strutils.sub
local require_when_needed = require("Module:utilities/require when needed")
local insert = table.insert

local m_table = require("Module:table")
local com_module = "Module:gl-common"
local reinteg_com_module = "Module:gl-reinteg-common"
local en_utilities_module = "Module:en-utilities"
local gl_verb_module = "Module:gl-verb"
local gl_reinteg_verb_module = "Module:gl-reinteg-verb"
local headword_utilities_module = "Module:headword utilities"
local inflection_utilities_module = "Module:inflection utilities"
local romut_module = "Module:romance utilities"

local lang = require("Module:languages").getByCode("gl")
local langname = lang:getCanonicalName()

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

-- When followed by a hyphen in a hyphenated compound, the hyphen will be included with the prefix when linked.
local include_hyphen_prefixes = m_table.listToSet {
	"ab",
	"afro",
	"anarco",
	"anglo",
	"ântero",
	"anti",
	"auto",
	"contra",
	"ex",
	"franco",
	"hiper",
	"infra",
	"inter",
	"intra",
	"macro",
	"micro",
	"neo",
	"pan",
	"pós",
	"pré",
	"pró",
	"proto",
	"sobre",
	"sub",
	"super",
	"vice",
}

-----------------------------------------------------------------------------------------
--                                     Utility functions                               --
-----------------------------------------------------------------------------------------

local function track(page)
	require("Module:debug/track")("gl-headword/" .. page)
	return true
end

local list_param = {list = true, disallow_holes = true}
local boolean_param = {type = "boolean"}

local function make_plural(sg, special)
	local pl = com.make_plural(sg, special)
	if not pl then
		error(("Internal error: Unable to generate default plural of '%s'"):format(sg))
	end
	return pl
end


-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- `plpos` is the plural part of speech, used in [[Category:LANGNAME PLPOS with red links in their headword lines]].
-- `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, plpos, accel, frob)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		label = label,
		accel = accel and {form = accel} or nil,
		frob = frob,
		check_missing = true,
		lang = lang,
		plpos = plpos,
	}
end

local function do_headword(parargs, poscat, is_reinteg)
	local params = {
		["head"] = list_param,
		["id"] = {},
		["splithyph"] = boolean_param,
		["nolinkhead"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = {}, -- for testing
		["reinteg"] = {}, -- processed in show()
	}

	if pos_functions[poscat] then
		for key, val in pairs(pos_functions[poscat].params) do
			params[key] = val
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local user_specified_heads = args.head
	local heads = user_specified_heads
	if args.nolinkhead then
		if #heads == 0 then
			heads = {pagename}
		end
	else
		local romut = require(romut_module)
		local auto_linked_head = romut.add_links_to_multiword_term(pagename, args.splithyph, nil,
			include_hyphen_prefixes)
		if #heads == 0 then
			heads = {auto_linked_head}
		else
			for i, head in ipairs(heads) do
				if head:find("^~") then
					head = romut.apply_link_modifiers(auto_linked_head, usub(head, 2))
					heads[i] = head
				end
			end
		end
	end

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = heads,
		user_specified_heads = user_specified_heads,
		no_redundant_head_cat = #user_specified_heads == 0,
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		force_cat_output = force_cat,
		is_reinteg = is_reinteg,
	}

	local is_suffix = false
	if pagename:find("^%-") and poscat ~= "suffix forms" then
		is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = require(en_utilities_module).singularize(poscat)
		table.insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		table.insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	local tracking_categories = {}

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data, tracking_categories, is_suffix)
	end
	if is_reinteg then
		table.insert(data.inflections, {label = "[[Appendix:Reintegrationism|reintegrationist]] norm"})
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require("Module:headword").full_headword(data)
		.. (#tracking_categories > 0 and require("Module:utilities").format_categories(tracking_categories, lang, nil, nil, force_cat) or "")
end


-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local poscat = frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")
	local is_reinteg = frame.args.reinteg and require("Module:yesno")(frame.args.reinteg, false) or false
	local parargs = frame:getParent().args
	local also_reinteg = parargs.reinteg and require("Module:yesno")(parargs.reinteg, false) or false
	if is_reinteg and also_reinteg then
		error("Can't specify reinteg= when using a reintegrationist-specific template")
	end
	local parts = {}
	if also_reinteg or not is_reinteg then
		table.insert(parts, do_headword(parargs, poscat, false))
	end
	if also_reinteg or is_reinteg then
		table.insert(parts, do_headword(parargs, poscat, true))
	end
	return table.concat(parts, "<br />")
end


local function replace_hash_with_lemma(term, lemma)
	-- If there is a % sign in the lemma, we have to replace it with %% so it doesn't get interpreted as a capture
	-- replace expression.
	lemma = lemma:gsub("%%", "%%%%")
	return (term:gsub("#", lemma))
end


-----------------------------------------------------------------------------------------
--                                          Nouns                                      --
-----------------------------------------------------------------------------------------

local allowed_genders = m_table.listToSet(
    {"m", "f", "mf", "mfbysense", "mfequiv", "gneut", "n", "m-p", "f-p", "mf-p", "mfbysense-p", "mfequiv-p", "gneut-p", "n-p", "?", "?-p"}
)

local function validate_genders(genders)
	for _, g in ipairs(genders) do
		if type(g) == "table" then
			g = g.spec
		end
		if not allowed_genders[g] then
			error("Unrecognized gender: " .. g)
		end
	end
end

local function do_noun(args, data, pos, is_suffix, is_proper)
	local com = require(data.is_reinteg and reinteg_com_module or com_module)
	local is_plurale_tantum = false
	local has_singular = false
	if is_suffix then
		pos = "suffix"
	end
	local plpos = m_en_utilities.pluralize(pos)

	validate_genders(args[1])
	data.genders = args[1]
	local saw_m = false
	local saw_f = false
	local saw_gneut = false
	local gender_for_irreg_ending
	-- Check for specific genders and pluralia tantum.
	for _, g in ipairs(args[1]) do
		if type(g) == "table" then
			g = g.spec
		end
		if g:find("-p$") then
			is_plurale_tantum = true
		else
			has_singular = true
			if g == "m" or g == "mf" or g == "mfbysense" then
				saw_m = true
			end
			if g == "f" or g == "mf" or g == "mfbysense" then
				saw_f = true
			end
			if g == "gneut" then
				saw_gneut = true
			end
		end
	end
	if saw_m and saw_f then
		gender_for_irreg_ending = "mf"
	elseif saw_f then
		gender_for_irreg_ending = "f"
	else
		gender_for_irreg_ending = "m"
	end

	local lemma = data.pagename

	local plurals = {}

	local function insert_noun_inflection(terms, label, accel)
		m_headword_utilities.insert_inflection {
			headdata = data,
			terms = terms,
			label = label,
			accel = accel and {form = accel} or nil,
			check_missing = true,
			lang = lang,
			plpos = plpos,
		}
	end

	if is_plurale_tantum and not has_singular then
		if args[2][1] then
			error("Can't specify plurals of plurale tantum " .. pos)
		end
		insert(data.inflections, {label = glossary_link("plural only")})
	else
		plurals = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = {2, "pl"},
			forms = args[2],
		}
		-- Check for special plural signals
		local mode = nil

		local pl1 = plurals[1]
		if pl1 and #pl1.term == 1 then
			mode = pl1.term
			if mode == "?" or mode == "!" or mode == "-" or mode == "~" then
				pl1.term = nil
				if next(pl1) then
					error(("Can't specify inline modifiers with plural code '%s'"):format(mode))
				end
				table.remove(plurals, 1)  -- Remove the mode parameter
			elseif mode ~= "+" and mode ~= "#" then
				error(("Unexpected plural code '%s'"):format(mode))
			end
		end

		if is_plurale_tantum then
			-- both singular and plural
			insert(data.inflections, {label = "sometimes " .. glossary_link("plural only") .. ", in variation"})
		end
		if mode == "?" then
			-- Plural is unknown
			insert(data.categories, langname .. " " .. plpos .. " with unknown or uncertain plurals")
		elseif mode == "!" then
			-- Plural is not attested
			insert(data.inflections, {label = "plural not attested"})
			insert(data.categories, langname .. " " .. plpos .. " with unattested plurals")
			if plurals[1] then
				error("Can't specify any plurals along with unattested plural code '!'")
			end
		elseif mode == "-" then
			-- Uncountable noun; may occasionally have a plural
			insert(data.categories, langname .. " uncountable " .. plpos)

			-- If plural forms were given explicitly, then show "usually"
			if plurals[1] then
				insert(data.inflections, {label = "usually " .. glossary_link("uncountable")})
				insert(data.categories, langname .. " countable " .. plpos)
			else
				insert(data.inflections, {label = glossary_link("uncountable")})
			end
		else
			-- Countable or mixed countable/uncountable
			if not plurals[1] and not is_proper then
				plurals[1] = {term = "+"}
			end
			if mode == "~" then
				-- Mixed countable/uncountable noun, always has a plural
				insert(data.inflections, {label = glossary_link("countable") .. " and " .. glossary_link("uncountable")})
				insert(data.categories, langname .. " uncountable " .. plpos)
				insert(data.categories, langname .. " countable " .. plpos)
			elseif plurals[1] then
				-- Countable nouns
				insert(data.categories, langname .. " countable " .. plpos)
			else
				-- Uncountable nouns
				insert(data.categories, langname .. " uncountable " .. plpos)
			end
		end

		-- Gather plurals, handling requests for default plurals.
		local has_default_or_hash = false
		for _, pl in ipairs(plurals) do
			if pl.term:find("^%+") or pl.term:find("#") then
				has_default_or_hash = true
				break
			end
		end

		if has_default_or_hash then
			for _, pl in ipairs(plurals) do
				if pl.term == "+" then
					pl.term = make_plural(lemma)
				elseif pl.term:find("^%+") then
					pl.term = require(romut_module).get_special_indicator(pl.term)
					pl.term = make_plural(lemma, pl.term)
				else
					pl.term = replace_hash_with_lemma(pl.term, lemma)
				end
			end
		end

		local pl1 = plurals[1]
		if pl1 and not plurals[2] and pl1.term == lemma then
			insert(data.inflections, {label = glossary_link("invariable"),
				q = pl1.q, qq = pl1.qq, l = pl1.l, ll = pl1.ll, refs = pl1.refs
			})
			insert(data.categories, langname .. " indeclinable " .. plpos)
		else
			insert_noun_inflection(plurals, "plural", "p")
		end

		if plurals[2] then
			insert(data.categories, langname .. " " .. plpos .. " with multiple plurals")
		end
	end

	-- Gather masculines/feminines. For each one, generate the corresponding plural. `field` is the name of the field
	-- containing the masculine or feminine forms (normally "m" or "f"); `inflect` is a function of one or two arguments
	-- to generate the default masculine or feminine from the lemma (the arguments are the lemma and optionally a
	-- "special" flag to indicate how to handle multiword lemmas, and the function is normally make_feminine or
	-- make_masculine from [[Module:pt-common]]); and `default_plurals` is a list into which the corresponding default
	-- plurals of the gathered or generated masculine or feminine forms are stored.
	local function handle_mf(field, inflect, default_plurals)
		local mfs = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = field,
			forms = args[field],
			frob = function(term)
				if term == "+" then
					-- Generate default masculine/feminine.
					term = inflect(lemma)
				else
					term = replace_hash_with_lemma(term, lemma)
				end
				local special = require(romut_module).get_special_indicator(term)
				if special then
					term = inflect(lemma, special)
				end
				return term
			end
		}
		for _, mf in ipairs(mfs) do
			local plobj = m_table.shallowCopy(mf)
			plobj.term = make_plural(mf.term, special)
			-- Add an accelerator for each masculine/feminine plural whose lemma is the corresponding singular, so that
			-- the accelerated entry that is generated has a definition that looks like
			-- # {{plural of|pt|MFSING}}
			plobj.accel = {form = "p", lemma = mf.term}
			insert(default_plurals, plobj)
		end
		return mfs
	end

	local feminine_plurals = {}
	local feminines = handle_mf("f", function(term, special)
		return com.make_feminine(term, "is noun", special) end, feminine_plurals)
	local masculine_plurals = {}
	local masculines = handle_mf("m", com.make_masculine, masculine_plurals)

	local function handle_mf_plural(mfplfield, default_plurals, singulars)
		local mfpl = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = mfplfield,
			forms = args[mfplfield],
		}
		if is_plurale_tantum then
			return mfpl
		end
		local new_mfpls = {}
		local saw_plus
		for i, mfpl in ipairs(mfpl) do
			local accel
			if #mfpl == #singulars then
				-- If same number of overriding masculine/feminine plurals as singulars, assume each plural goes with
				-- the corresponding singular and use each corresponding singular as the lemma in the accelerator. The
				-- generated entry will have
				-- # {{plural of|pt|SINGULAR}}
				-- as the definition.
				accel = {form = "p", lemma = singulars[i].term}
			else
				accel = nil
			end
			if mfpl.term == "+" then
				-- We should never see + twice. If we do, it will lead to problems since we overwrite the values of
				-- default_plurals the first time around.
				if saw_plus then
					error(("Saw + twice when handling %s="):format(mfplfield))
				end
				saw_plus = true
				if not default_plurals[1] then
					-- FIXME: Can this happen? Not in corresponding Spanish code and the old Portuguese code tried to
					-- handle this condition by generating the default plural from the lemma.
					error("Internal error: Something wrong, no generated default m/f plurals at this stage")
				end
				for _, defpl in ipairs(default_plurals) do
					-- defpl is already a table and has an accel field
					m_headword_utilities.combine_termobj_qualifiers_labels(defpl, mfpl)
					insert(new_mfpls, defpl)
				end
			elseif mfpl.term:find("^%+") then
				mfpl.term = require(romut_module).get_special_indicator(mfpl.term)
				for _, mf in ipairs(singulars) do
					local mfplobj = m_table.shallowCopy(mfpl)
					mfplobj.term = make_plural(mf.term, mfpl.term)
					mfplobj.accel = accel
					m_headword_utilities.combine_termobj_qualifiers_labels(mfplobj, mf)
					insert(new_mfpls, mfplobj)
				end
			else
				mfpl.accel = accel
				mfpl.term = replace_hash_with_lemma(mfpl.term, lemma)
				insert(new_mfpls, mfpl)
			end
		end
		return new_mfpls
	end

	if args.fpl[1] then
		-- Override any existing feminine plurals.
		feminine_plurals = handle_mf_plural("fpl", feminine_plurals, feminines)
	end

	if args.mpl[1] then
		-- Override any existing masculine plurals.
		masculine_plurals = handle_mf_plural("mpl", masculine_plurals, masculines)
	end

	local function parse_and_insert_noun_inflection(field, label, accel)
		parse_and_insert_inflection(data, args, field, label, plpos, accel)
	end

	insert_noun_inflection(feminines, "feminine", "f")
	insert_noun_inflection(feminine_plurals, "feminine plural")
	insert_noun_inflection(masculines, "masculine")
	insert_noun_inflection(masculine_plurals, "masculine plural")

	parse_and_insert_noun_inflection("dim", "diminutive")
	parse_and_insert_noun_inflection("aug", "augmentative")
	parse_and_insert_noun_inflection("pej", "pejorative")
	parse_and_insert_noun_inflection("dem", "demonym")
	parse_and_insert_noun_inflection("fdem", "female demonym")

	-- Maybe add category 'Portuguese nouns with irregular gender' (or similar)
	local irreg_gender_lemma = com.rsub(lemma, " .*", "") -- only look at first word
	if (rfind(irreg_gender_lemma, "[^ã]o$") and (gender_for_irreg_ending == "f" or gender_for_irreg_ending == "mf")) or
		(irreg_gender_lemma:find("a$") and (gender_for_irreg_ending == "m" or gender_for_irreg_ending == "mf")) then
		insert(data.categories, langname .. " " .. plpos .. " with irregular gender")
	end
end

local function get_noun_params(is_proper)
	return {
		[1] = {list = "g", disallow_holes = true, required = not is_proper, default = "?", type = "genders",
			flatten = true},
		[2] = {list = "pl", disallow_holes = true},
		["m"] = list_param,
		["f"] = list_param,
		["mpl"] = list_param,
		["fpl"] = list_param,
		["dim"] = list_param, --diminutive(s)
		["aug"] = list_param, --diminutive(s)
		["pej"] = list_param, --pejorative(s)
		["dem"] = list_param, --demonym(s)
		["fdem"] = list_param, --female demonym(s)
	}
end

pos_functions["nouns"] = {
	params = get_noun_params(),
	func = function(args, data, is_suffix)
		do_noun(args, data, "noun", is_suffix)
	end,
}

pos_functions["proper nouns"] = {
	params = get_noun_params("is proper"),
	func = function(args, data, is_suffix)
		do_noun(args, data, "proper noun", is_suffix, "is proper noun")
	end,
}


-----------------------------------------------------------------------------------------
--                                        Pronouns                                     --
-----------------------------------------------------------------------------------------

local function do_pronoun(args, data, pos, is_suffix)
	if is_suffix then
		pos = "suffix"
	end
	local plpos = m_en_utilities.pluralize(pos)

	if not is_suffix then
		data.pos_category = plpos
	end

	local lemma = data.pagename

	validate_genders(args[1])
	data.genders = args[1]

	local function do_inflection(field, label, accel)
		parse_and_insert_inflection(data, args, field, label, plpos, accel)
	end

	do_inflection("m", "masculine")
	do_inflection("f", "feminine")
	do_inflection("sg", "singular")
	do_inflection("pl", "plural")
	do_inflection("mpl", "masculine plural")
	do_inflection("fpl", "feminine plural")
	do_inflection("n", "neuter")
end

local function get_pronoun_params()
	local params = {
		[1] = {list = "g", disallow_holes = true, type = "genders", flatten = true}, --gender(s)
		["m"] = list_param, --masculine form(s)
		["f"] = list_param, --feminine form(s)
		["sg"] = list_param, --singular form(s)
		["pl"] = list_param, --plural form(s)
		["mpl"] = list_param, --masculine plural form(s)
		["fpl"] = list_param, --feminine plural form(s)
		["n"] = list_param, --neuter form(s)
	}
	return params
end

pos_functions["pronouns"] = {
	params = get_pronoun_params(),
	func = function(args, data, is_suffix)
		do_pronoun(args, data, "pronoun", is_suffix)
	end,
}


-----------------------------------------------------------------------------------------
--                                       Adjectives                                    --
-----------------------------------------------------------------------------------------

-- Handle comparatives and superlatives for adjectives and adverbs, including user-specified comparatives and
-- superlatives, default-requested comparatives/superlatives using '+', autogenerated comparatives/superlatives,
-- and hascomp=. Code is the same for adjectives and adverbs.
local function handle_adj_adv_comp(args, data, plpos, is_adv)
	local com = require(data.is_reinteg and reinteg_com_module or com_module)
	local lemma = data.pagename
	local stem

	if is_adv then
		stem = com.rsub(lemma, "mente$", "")
	else
		stem = lemma
	end

	local function insert_inflection(terms, label, accel)
		m_headword_utilities.insert_inflection {
			headdata = data,
			terms = terms,
			label = label,
			accel = accel and {form = accel} or nil,
			check_missing = true,
			lang = lang,
			plpos = plpos,
		}
	end

	local function make_absolute_superlative(special)
		if is_adv then
			return com.make_adverbial_absolute_superlative(stem, special)
		else
			return com.make_absolute_superlative(stem, special)
		end
	end

	-- Maybe autogenerate default comparative/superlative.
	local comp, sup
	if args.comp and args.sup then-- comp= and sup= were given as options to the user
		-- If no comp, but a non-default sup given, then add the default comparative/superlative.
		-- This is useful when an absolute superlative is given.
		comp = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = "comp",
			forms = args.comp,
		}
		sup = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = "sup",
			forms = args.sup,
		}
		local saw_sup_plus = false
		if not comp[1] and sup[1] then
			for _, supval in ipairs(sup) do
				if supval.term == "+" then
					saw_sup_plus = true
				end
			end
			if not saw_sup_plus then
				comp = {{term = "+"}}
				insert(sup, 1, {term = "+"})
			end
		end

		-- If comp=+, use default comparative 'mais ...', and set a default superlative if unspecified.
		local saw_comp_plus = false
		for _, compval in ipairs(comp) do
			if compval.term == "+" then
				saw_comp_plus = true
				compval.term = "[[mais]] [[" .. lemma .. "]]"
			end
		end
		if saw_comp_plus and not sup[1] then
			sup = {{term = "+"}}
		end
		-- If sup=+ (possibly from comp=+), use default superlative 'o mais ...'. Also handle absolute superlatives.
		for _, supval in ipairs(sup) do
			if supval.term == "+" then
				supval.term = "[[o]] [[mais]] [[" .. lemma .. "]]"
			elseif supval.term == "+abs" then
				supval.term = make_absolute_superlative()
			elseif rfind(supval.term, "^%+abs:") then
				local sp = rmatch(supval.term, "^%+abs:(.*)$")
				supval.term = make_absolute_superlative(sp)
			end
		end
	end

	if args.hascomp then
		if args.hascomp == "both" then
			insert(data.inflections, {label = "sometimes " .. glossary_link("comparable")})
			insert(data.categories, langname .. " comparable " .. plpos)
			insert(data.categories, langname .. " uncomparable " .. plpos)
		else
			local hascomp = require("Module:yesno")(args.hascomp)
			if hascomp == true then
				insert(data.inflections, {label = glossary_link("comparable")})
				insert(data.categories, langname .. " comparable " .. plpos)
			elseif hascomp == false then
				insert(data.inflections, {label = "not " .. glossary_link("comparable")})
				insert(data.categories, langname .. " uncomparable " .. plpos)
			else
				error("Unrecognized value for hascomp=: " .. args.hascomp)
			end
		end
	elseif comp and comp[1] or sup and sup[1] then
		insert(data.inflections, {label = glossary_link("comparable")})
		insert(data.categories, langname .. " comparable " .. plpos)
	end

	insert_inflection(comp, "comparative")
	insert_inflection(sup, "superlative")
end

local function do_adjective(args, data, pos, is_suffix, is_superlative)
	local com = require(data.is_reinteg and reinteg_com_module or com_module)
	local feminines = {}
	local masculine_plurals = {}
	local feminine_plurals = {}
	if is_suffix then
		pos = "suffix"
	end
	local plpos = m_en_utilities.pluralize(pos)

	if not is_suffix then
		data.pos_category = plpos
	end

	if args.sp then
		local romut = require(romut_module)
		if not romut.allowed_special_indicators[args.sp] then
			local indicators = {}
			for indic, _ in pairs(romut.allowed_special_indicators) do
				insert(indicators, "'" .. indic .. "'")
			end
			table.sort(indicators)
			error("Special inflection indicator beginning can only be " ..
				mw.text.listToText(indicators) .. ": " .. args.sp)
		end
	end

	local lemma = data.pagename

	local function fetch_inflections(field)
		local retval = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = field,
			forms = args[field],
		}
		if not retval[1] then
			return {{term = "+"}}
		end
		return retval
	end

	local function insert_inflection(terms, label, accel)
		m_headword_utilities.insert_inflection {
			headdata = data,
			terms = terms,
			label = label,
			accel = accel and {form = accel} or nil,
			check_missing = true,
			lang = lang,
			plpos = plpos,
		}
	end

	if args.short then
		insert(data.inflections, {label = "[[Appendix:Galician verbs#Participles|short participle]]"})
	end

	if args.inv then
		-- invariable adjective
		insert(data.inflections, {label = glossary_link("invariable")})
		insert(data.categories, langname .. " indeclinable " .. plpos)
		if args.sp or args.f[1] or args.pl[1] or args.mpl[1] or args.fpl[1] then
			error("Can't specify inflections with an invariable " .. pos)
		end
	elseif args.fonly then
		-- feminine-only
		if args.f[1] then
			error("Can't specify explicit feminines with feminine-only " .. pos)
		end
		if args.pl[1] then
			error("Can't specify explicit plurals with feminine-only " .. pos .. ", use fpl=")
		end
		if args.mpl[1] then
			error("Can't specify explicit masculine plurals with feminine-only " .. pos)
		end
		local argsfpl = fetch_inflections("fpl")
		for _, fpl in ipairs(argsfpl) do
			if fpl.term == "+" then
				fpl.term = make_plural(lemma, args.sp)
			else
				fpl.term = replace_hash_with_lemma(fpl.term, lemma)
			end
			insert(feminine_plurals, fpl)
		end

		insert(data.inflections, {label = "feminine-only"})
		insert_inflection(feminine_plurals, "feminine plural", "f|p")
	else
		-- Gather feminines.
		for _, f in ipairs(fetch_inflections("f")) do
			if f.term == "+" then
				-- Generate default feminine.
				f.term = com.make_feminine(lemma, false, args.sp)
			else
				f.term = replace_hash_with_lemma(f.term, lemma)
			end
			insert(feminines, f)
		end

		local fem_like_lemma = #feminines == 1 and feminines[1].term == lemma and
			not m_headword_utilities.termobj_has_qualifiers_or_labels(feminines[1])
		if fem_like_lemma then
			insert(data.categories, langname .. " epicene " .. plpos)
		end

		local mpl_field = "mpl"
		local fpl_field = "fpl"
		if args.pl[1] then
			if args.mpl[1] or args.fpl[1] then
				error("Can't specify both pl= and mpl=/fpl=")
			end
			mpl_field = "pl"
			fpl_field = "pl"
		end
		local argsmpl = fetch_inflections(mpl_field)
		local argsfpl = fetch_inflections(fpl_field)

		for _, mpl in ipairs(argsmpl) do
			if mpl.term == "+" then
				-- Generate default masculine plural.
				mpl.term = make_plural(lemma, args.sp)
			else
				mpl.term = replace_hash_with_lemma(mpl.term, lemma)
			end
			insert(masculine_plurals, mpl)
		end

		for _, fpl in ipairs(argsfpl) do
			if fpl.term == "+" then
				for _, f in ipairs(feminines) do
					-- Generate default feminine plural; f is a table.
					local fplobj = m_table.shallowCopy(fpl)
					fplobj.term = make_plural(f.term, args.sp)
					m_headword_utilities.combine_termobj_qualifiers_labels(fplobj, f)
					insert(feminine_plurals, fplobj)
				end
			else
				fpl.term = replace_hash_with_lemma(fpl.term, lemma)
				insert(feminine_plurals, fpl)
			end
		end

		local fem_pl_like_masc_pl = masculine_plurals[1] and feminine_plurals[1] and
			m_table.deepEquals(masculine_plurals, feminine_plurals)
		local masc_pl_like_lemma = #masculine_plurals == 1 and masculine_plurals[1].term == lemma and
			not m_headword_utilities.termobj_has_qualifiers_or_labels(masculine_plurals[1])
		if fem_like_lemma and fem_pl_like_masc_pl and masc_pl_like_lemma then
			-- actually invariable
			insert(data.inflections, {label = glossary_link("invariable")})
			insert(data.categories, langname .. " indeclinable " .. plpos)
		else
			-- Make sure there are feminines given and not same as lemma.
			if not fem_like_lemma then
				insert_inflection(feminines, "feminine", "f|s")
			elseif args.gneut then
				data.genders = {"gneut"}
			else
				data.genders = {"mf"}
			end

			if fem_pl_like_masc_pl then
				if args.gneut then
					insert_inflection(masculine_plurals, "plural", "p")
				else
					-- This is how the Spanish module works.
					-- insert_inflection(masculine_plurals, "masculine and feminine plural", "p")
					insert_inflection(masculine_plurals, "plural", "p")
				end
			else
				insert_inflection(masculine_plurals, "masculine plural", "m|p")
				insert_inflection(feminine_plurals, "feminine plural", "f|p")
			end
		end
	end

	local function parse_and_insert_adj_inflection(field, label, accel, frob)
		parse_and_insert_inflection(data, args, field, label, plpos, accel, frob)
	end

	parse_and_insert_adj_inflection("n", "neuter")

	handle_adj_adv_comp(args, data, plpos, false)

	parse_and_insert_adj_inflection("dim", "diminutive", nil, function(term)
		if term == "+" then
			term = com.make_diminutive(lemma)
		elseif term:find("^%+") then
			term = require(romut_module).get_special_indicator(term)
			term = com.make_diminutive(lemma, term)
		end
		return term
	end)
	parse_and_insert_adj_inflection("aug", "augmentative", nil, function(term)
		if term == "+" then
			term = com.make_augmentative(lemma)
		elseif term:find("^%+") then
			term = require(romut_module).get_special_indicator(term)
			term = com.make_augmentative(lemma, term)
		end
		return term
	end)

	if args.irreg and is_superlative then
		insert(data.categories, langname .. " irregular superlative " .. plpos)
	end
end

local function get_adjective_params(adjtype)
	local params = {
		["inv"] = boolean_param, --invariable
		["sp"] = true, -- special indicator: "first", "first-last", etc.
		["f"] = list_param, --feminine form(s)
		["pl"] = list_param, --plural override(s)
		["mpl"] = list_param, --masculine plural override(s)
		["fpl"] = list_param, --feminine plural override(s)
	}
	if adjtype == "base" then
		params["comp"] = list_param --comparative(s)
		params["sup"] = list_param --superlative(s)
		params["dim"] = list_param --diminutive(s)
		params["aug"] = list_param --augmentative(s)
		params["fonly"] = boolean_param -- feminine only
        params["gneut"] = boolean_param -- gender-neutral adjective e.g. [[latine]] (FIXME: do these exist in Portuguese?)
		params["hascomp"] = true -- has comparative
	end
	if adjtype == "part" then
		params["short"] = boolean_param -- short participle
	end
	if adjtype == "sup" then
		params["irreg"] = boolean_param
	end
	if adjtype == "pron" or adjtype == "contr" then
		params["n"] = list_param --neuter form(s)
	end
	return params
end

pos_functions["adjectives"] = {
	params = get_adjective_params("base"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "adjective", is_suffix)
	end,
}

pos_functions["comparative adjectives"] = {
	params = get_adjective_params("comp"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "adjective", is_suffix)
	end,
}

pos_functions["superlative adjectives"] = {
	params = get_adjective_params("sup"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "adjective", is_suffix, "is superlative")
	end,
}

pos_functions["past participles"] = {
	params = get_adjective_params("part"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "participle", is_suffix)
		data.pos_category = "past participles"
	end,
}

pos_functions["determiners"] = {
	params = get_adjective_params("det"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "determiner", is_suffix)
	end,
}

pos_functions["adjective-like pronouns"] = {
	params = get_adjective_params("pron"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "pronoun", is_suffix)
	end,
}

pos_functions["adjective-like contractions"] = {
	params = get_adjective_params("contr"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "contraction", is_suffix)
	end,
}


-----------------------------------------------------------------------------------------
--                                        Adverbs                                      --
-----------------------------------------------------------------------------------------

local function do_adverb(args, data, pos, is_suffix)
	if is_suffix then
		pos = "suffix"
	end
	local plpos = m_en_utilities.pluralize(pos)

	if not is_suffix then
		data.pos_category = plpos
	end

	handle_adj_adv_comp(args, data, plpos, "is adv")
end

local function get_adverb_params(advtype)
	local params = {}
	if advtype == "base" then
		params["comp"] = list_param --comparative(s)
		params["sup"] = list_param --superlative(s)
		params["hascomp"] = true -- has comparative
	end
	return params
end

pos_functions["adverbs"] = {
	params = get_adverb_params("base"),
	func = function(args, data, is_suffix)
		do_adverb(args, data, "adverb", is_suffix)
	end,
}

pos_functions["comparative adverbs"] = {
	params = get_adverb_params("comp"),
	func = function(args, data, is_suffix)
		do_adverb(args, data, "adverb", is_suffix)
	end,
}

pos_functions["superlative adverbs"] = {
	params = get_adverb_params("sup"),
	func = function(args, data, is_suffix)
		do_adverb(args, data, "adverb", is_suffix)
	end,
}


-----------------------------------------------------------------------------------------
--                                         Verbs                                       --
-----------------------------------------------------------------------------------------

pos_functions["verbs"] = {
	params = {
		[1] = {},
		["pres"] = list_param, --present
		["pres_qual"] = {list = "pres\1_qual", allow_holes = true},
		["pres3s"] = list_param, --third-singular present
		["pres3s_qual"] = {list = "pres3s\1_qual", allow_holes = true},
		["pret"] = list_param, --preterite
		["pret_qual"] = {list = "pret\1_qual", allow_holes = true},
		["part"] = list_param, --participle
		["part_qual"] = {list = "part\1_qual", allow_holes = true},
		["short_part"] = list_param, --short participle
		["short_part_qual"] = {list = "short_part\1_qual", allow_holes = true},
		["noautolinktext"] = boolean_param,
		["noautolinkverb"] = boolean_param,
		["attn"] = boolean_param,
	},
	func = function(args, data, tracking_categories)
		local preses, preses_3s, prets, parts, short_parts

		if args.attn then
			table.insert(tracking_categories, "Requests for attention concerning " .. langname)
			return
		end

		local gl_verb = require(data.is_reinteg and gl_reinteg_verb_module or gl_verb_module)
		local alternant_multiword_spec = gl_verb.do_generate_forms(args,
			data.is_reinteg and "gl-reinteg-verb" or "gl-verb", data.heads[1])

		local specforms = alternant_multiword_spec.forms
		local function slot_exists(slot)
			return specforms[slot] and #specforms[slot] > 0
		end

		local function do_finite(slot_tense, label_tense)
			-- Use pres_3s if it exists and pres_1s doesn't exist (e.g. impersonal verbs); similarly for pres_3p (only3p verbs);
			-- but fall back to pres_1s if neither pres_1s nor pres_3s nor pres_3p exist (e.g. [[empedernir]]).
			local has_1s = slot_exists(slot_tense .. "_1s")
			local has_3s = slot_exists(slot_tense .. "_3s")
			local has_3p = slot_exists(slot_tense .. "_3p")
			if has_1s or (not has_3s and not has_3p) then
				return {
					slot = slot_tense .. "_1s",
					label = ("first-person singular %s"):format(label_tense),
				}, true
			elseif has_3s then
				return {
					slot = slot_tense .. "_3s",
					label = ("third-person singular %s"):format(label_tense),
				}, false
			else
				return {
					slot = slot_tense .. "_3p",
					label = ("third-person plural %s"):format(label_tense),
				}, false
			end
		end

		local did_pres_1s
		preses, did_pres_1s = do_finite("pres", "present")
		preses_3s = {
			slot = "pres_3s",
			label = "third-person singular present",
		}
		prets = do_finite("pret", "preterite")
		parts = {
			slot = "pp_ms",
			label = "past participle",
		}
		short_parts = {
			slot = "short_pp_ms",
			label = "short past participle",
		}

		if #args.pres > 0 or #args.pres3s > 0 or #args.pret > 0 or #args.part > 0 or #args.short_part > 0 then
			track("verb-old-multiarg")
		end

		local function strip_brackets(qualifiers)
			if not qualifiers then
				return nil
			end
			local stripped_qualifiers = {}
			for _, qualifier in ipairs(qualifiers) do
				local stripped_qualifier = qualifier:match("^%[(.*)%]$")
				if not stripped_qualifier then
					error("Internal error: Qualifier should be surrounded by brackets at this stage: " .. qualifier)
				end
				table.insert(stripped_qualifiers, stripped_qualifier)
			end
			return stripped_qualifiers
		end

		local function do_verb_form(args, qualifiers, slot_desc, skip_if_empty)
			local forms
			local to_insert

			if #args == 0 then
				forms = specforms[slot_desc.slot]
				if not forms or #forms == 0 then
					if skip_if_empty then
						return
					end
					forms = {{form = "-"}}
				end
			elseif #args == 1 and args[1] == "-" then
				forms = {{form = "-"}}
			else
				forms = {}
				for i, arg in ipairs(args) do
					local qual = qualifiers[i]
					if qual then
						-- FIXME: It's annoying we have to add brackets and strip them out later. The inflection
						-- code adds all footnotes with brackets around them; we should change this.
						qual = {"[" .. qual .. "]"}
					end
					local form = arg
					if not args.noautolinkverb then
						-- [[Module:inflection utilities]] already loaded by [[Module:gl-verb]] or
						-- [[Module:gl-reinteg-verb]]
						form = require(inflection_utilities_module).add_links(form)
					end
					table.insert(forms, {form = form, footnotes = qual})
				end
			end

			if forms[1].form == "-" then
				to_insert = {label = "no " .. slot_desc.label}
			else
				local into_table = {label = slot_desc.label}
				for _, form in ipairs(forms) do
					local qualifiers = strip_brackets(form.footnotes)
					-- Strip redundant brackets surrounding entire form. These may get generated e.g.
					-- if we use the angle bracket notation with a single word.
					local stripped_form = rmatch(form.form, "^%[%[([^%[%]]*)%]%]$") or form.form
					-- The reintegrationist code uses variant codes to track "Portuguese-ending" vs. "Galician-ending"
					-- forms and "less common" forms. Remove them now.
					if data.is_reinteg then
						stripped_form = gl_verb.remove_variant_codes(stripped_form)
					end
					-- Don't include accelerators if brackets remain in form, as the result will be wrong.
					-- FIXME: For now, don't include accelerators. We should use the new {{gl-verb form of}} once implemented.
					-- local this_accel = not stripped_form:find("%[%[") and accel or nil
					local this_accel = nil
					table.insert(into_table, {term = stripped_form, q = qualifiers, accel = this_accel})
				end
				to_insert = into_table
			end

			table.insert(data.inflections, to_insert)
		end

		local skip_pres_if_empty
		if alternant_multiword_spec.no_pres1_and_sub then
			table.insert(data.inflections, {label = "no first-person singular present"})
			table.insert(data.inflections, {label = "no present subjunctive"})
		end
		if alternant_multiword_spec.no_pres_stressed then
			table.insert(data.inflections, {label = "no stressed present indicative or subjunctive"})
			skip_pres_if_empty = true
		end
		if alternant_multiword_spec.only3s then
			table.insert(data.inflections, {label = glossary_link("impersonal")})
		elseif alternant_multiword_spec.only3sp then
			table.insert(data.inflections, {label = "third-person only"})
		elseif alternant_multiword_spec.only3p then
			table.insert(data.inflections, {label = "third-person plural only"})
		end
		local has_vowel_alt
		if alternant_multiword_spec.vowel_alt then
			for _, vowel_alt in ipairs(alternant_multiword_spec.vowel_alt) do
				if vowel_alt ~= "+" and vowel_alt ~= "í" and vowel_alt ~= "ú" then
					has_vowel_alt = true
					break
				end
			end
		end

		do_verb_form(args.pres, args.pres_qual, preses, skip_pres_if_empty)
		-- We want to include both the pres_1s and pres_3s if there is a vowel alternation in the present singular. But we
		-- don't want to redundantly include the pres_3s if we already included it.
		if did_pres_1s and has_vowel_alt then
			do_verb_form(args.pres3s, args.pres3s_qual, preses_3s, skip_pres_if_empty)
		end
		do_verb_form(args.pret, args.pret_qual, prets)
		do_verb_form(args.part, args.part_qual, parts)
		do_verb_form(args.short_part, args.short_part_qual, short_parts, "skip if empty")

		-- Add categories.
		for _, cat in ipairs(alternant_multiword_spec.categories) do
			table.insert(data.categories, cat)
		end

		-- If the user didn't explicitly specify head=, or specified exactly one head (not 2+) and we were able to
		-- incorporate any links in that head into the 1= specification, use the infinitive generated by
		-- [[Module:gl-verb]]/[[Module:gl-reinteg-verb]] in place of the user-specified or auto-generated head. This was
		-- copied from [[Module:it-headword]], where doing this gets accents marked on the verb(s). We don't have
		-- accents marked on the verb but by doing this we do get any footnotes on the infinitive propagated here. Don't
		-- do this if the user gave multiple heads or gave a head with a multiword-linked verbal expression such as
		-- Italian '[[dare esca]] [[al]] [[fuoco]]' (FIXME: give Galician equivalent).
		if #data.user_specified_heads == 0 or (
			#data.user_specified_heads == 1 and alternant_multiword_spec.incorporated_headword_head_into_lemma
		) then
			data.heads = {}
			for _, lemma_obj in ipairs(alternant_multiword_spec.forms.infinitive_linked) do
				local quals, refs = require(inflection_utilities_module).
					convert_footnotes_to_qualifiers_and_references(lemma_obj.footnotes)
				table.insert(data.heads, {term = lemma_obj.form, q = quals, refs = refs})
			end
		end
	end
}

-----------------------------------------------------------------------------------------
--                                    Suffix forms                                     --
-----------------------------------------------------------------------------------------

pos_functions["suffix forms"] = {
	params = {
		[1] = {required = true, list = true, disallow_holes = true},
		["g"] = {list = true, disallow_holes = true, type = "genders", flatten = true},
	},
	func = function(args, data, is_suffix)
		validate_genders(args.g)
		data.genders = args.g
		local suffix_type = {}
		for _, typ in ipairs(args[1]) do
			insert(suffix_type, typ .. "-forming suffix")
		end
		insert(data.inflections, {label = "non-lemma form of " .. m_table.serialCommaJoin(suffix_type, {conj = "or"})})
	end,
}

return export
