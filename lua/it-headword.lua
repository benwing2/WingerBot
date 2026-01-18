-- This module contains code for Italian headword templates.
-- Templates covered are:
-- * {{it-noun}}, {{it-proper noun}};
-- * {{it-verb}};
-- * {{it-adj}}, {{it-adj-comp}}, {{it-adj-sup}};
-- * {{it-det}};
-- * {{it-art}};
-- * {{it-pron-adj}};
-- * {{it-pp}};
-- * {{it-presp}};
-- * {{it-card-noun}}, {{it-card-adj}}, {{it-card-inv}};
-- * {{it-adv}};
-- * {{it-pos}};
-- * {{it-suffix form}}.
-- See [[Module:it-verb]] for Italian conjugation templates.

local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local m_strutils = require("Module:string utilities")
local usub = m_strutils.sub
local require_when_needed = require("Module:utilities/require when needed")
local insert = table.insert

local m_table = require("Module:table")
local com = require("Module:it-common")
local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local inflection_utilities_module = "Module:inflection utilities"
local it_verb_module = "Module:it-verb"
local parse_interface_module = "Module:parse interface"
local romut_module = "Module:romance utilities"
local lang = require("Module:languages").getByCode("it")
local langname = lang:getCanonicalName()

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local no_split_apostrophe_words = {
	["c'è"] = true,
	["c'era"] = true,
	["c'erano"] = true,
}

-----------------------------------------------------------------------------------------
--                                     Utility functions                               --
-----------------------------------------------------------------------------------------

local function track(page)
	require("Module:debug/track")("it-headword/" .. page)
	return true
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

local function replace_hash_with_lemma(term, lemma)
	-- If there is a % sign in the lemma, we have to replace it with %% so it doesn't get interpreted as a capture
	-- replace expression.
	lemma = lemma:gsub("%%", "%%%%")
	return (term:gsub("#", lemma))
end

local list_param = {list = true, disallow_holes = true}
local boolean_param = {type = "boolean"}

-----------------------------------------------------------------------------------------
--                                     Main entry point                                --
-----------------------------------------------------------------------------------------

function export.show(frame)
	local poscat = frame.args[1]
		or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local parargs = frame:getParent().args

	local params = {
		["head"] = list_param,
		["id"] = true,
		["sort"] = true,
		["apoc"] = boolean_param,
		["splithyph"] = boolean_param,
		["nolinkhead"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = true, -- for testing
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
		local auto_linked_head = romut.add_links_to_multiword_term(pagename, args.splithyph,
			no_split_apostrophe_words)
		if #heads == 0 then
			heads = {auto_linked_head}
		else
			for i, head in ipairs(heads) do
				if head:find("^~") then
					head = romut.apply_link_modifiers(auto_linked_head, usub(head, 2))
					heads[i] = head
				end
				if head == auto_linked_head then
					track("redundant-head")
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
		sort_key = args.sort,
		force_cat_output = force_cat,
	}

	local is_suffix = false
	if pagename:find("^%-") and poscat ~= "suffix forms" then
		is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = m_en_utilities.singularize(poscat)
		insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data, is_suffix)
	end

	if args.apoc then
		-- Apocopated form of a term; do this after calling pos_functions[], because the function might modify
		-- data.pos_category.
		local pos = data.pos_category
		if not pos:find(" forms") then
			-- Apocopated forms are non-lemma forms.
			local singular_poscat = m_en_utilities.singularize(pos)
			data.pos_category = singular_poscat .. " forms"
		end
		-- If this is a suffix, insert label 'apocopated' after 'FOO-forming suffix', otherwise insert at the beginning.
		insert(data.inflections, is_suffix and 2 or 1, {label = glossary_link("apocopated")})
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

local deriv_params = {
	{"dim", glossary_link("diminutive")},
	{"aug", glossary_link("augmentative")},
	{"pej", glossary_link("pejorative")},
	{"derog", glossary_link("derogatory")},
	{"end", glossary_link("endearing")},
	{"dim_aug", glossary_link("diminutive") .. "-" .. glossary_link("augmentative")},
	{"dim_pej", glossary_link("diminutive") .. "-" .. glossary_link("pejorative")},
	{"dim_derog", glossary_link("diminutive") .. "-" .. glossary_link("derogatory")},
	{"dim_end", glossary_link("diminutive") .. "-" .. glossary_link("endearing")},
	{"aug_pej", glossary_link("augmentative") .. "-" .. glossary_link("pejorative")},
	{"aug_derog", glossary_link("augmentative") .. "-" .. glossary_link("derogatory")},
	{"aug_end", glossary_link("augmentative") .. "-" .. glossary_link("endearing")},
	{"end_derog", glossary_link("endearing") .. "-" .. glossary_link("derogatory")},
}


local function insert_deriv_params(params)
	for _, deriv_param in ipairs(deriv_params) do
		local param, desc = unpack(deriv_param)
		params[param] = list_param
	end
end


local param_mods = {
	t = {
		-- We need to store the <t:...> inline modifier into the "gloss" key of the parsed part, because that is what
		-- [[Module:links]] expects.
		item_dest = "gloss",
	},
	gloss = {},
	-- no 'tr' or 'ts', doesn't make sense for Italian
	g = {
		-- We need to store the <g:...> inline modifier into the "genders" key of the parsed part, because that is what
		-- [[Module:links]] expects.
		item_dest = "genders",
		sublist = true,
	},
	id = {},
	alt = {},
	q = {type = "qualifier"},
	qq = {type = "qualifier"},
	lit = {},
	pos = {},
	-- no 'sc', doesn't make sense for Italian
}


local function parse_term_with_modifiers(paramname, val)
	local function generate_obj(term)
		local decomp = com.decompose(term)
		local lemma = com.remove_non_final_accents(decomp)
		if lemma ~= decomp then
			term = com.compose("[[" .. lemma .. "|" .. decomp .. "]]")
		end
		return {term = term}
	end

	local retval = require(parse_interface_module).parse_inline_modifiers(val, {
			paramname = paramname,
			param_mods = param_mods,
			generate_obj = generate_obj,
			splitchar = "[/;,]",
			preserve_splitchar = true,
		})

	for _, obj in ipairs(retval) do
		if obj.delimiter == ";" then
			obj.separator = "; "
		elseif obj.delimiter == "/" then
			obj.separator = "/"
		-- default to nil for comma
		end
	end
	return retval
end


local function insert_deriv_inflections(data, args, plpos)
	for _, deriv_param in ipairs(deriv_params) do
		local param, desc = unpack(deriv_param)
		if #args[param] > 0 then
			local inflection = {label = desc}
			for i, term in ipairs(args[param]) do
				local parsed_terms = parse_term_with_modifiers(param, term)
				for _, parsed_term in ipairs(parsed_terms) do
					insert(inflection, parsed_term)
				end
			end
			-- These will typically be missing for now so it doesn't help to do this.
			-- check_all_missing(inflection, plpos, data.categories)
			insert(data.inflections, inflection)
		end
	end
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
	local gender_for_default_plural
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
		end
	end
	if saw_m and saw_f then
		gender_for_default_plural = "mf"
	elseif saw_f then
		gender_for_default_plural = "f"
	else
		gender_for_default_plural = "m"
	end

	local lemma = data.pagename

	local function inscat(cat)
		insert(data.categories, langname .. " " .. cat)
	end
	local function inslabel(label)
		insert(data.inflections, {label = label})
	end

	local function insert_noun_inflection(terms, label, accel, no_inv)
		for _, term in ipairs(terms) do
			term.term_for_further_inflection = term
			if not no_inv and term.term == lemma then
				term.term = nil
				term.label = glossary_link("invariable")
			end
		end
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

	-- Plural
	local plurals = {}
	-- Fetch explicit masculine and feminine plurals here because we may change them below when processing plurals.
	local mpls = m_headword_utilities.parse_term_list_with_modifiers {
		paramname = "mpl",
		forms = args.mpl,
	}
	local fpls = m_headword_utilities.parse_term_list_with_modifiers {
		paramname = "fpl",
		forms = args.fpl,
	}

	if is_plurale_tantum and not has_singular then
		if args[2][1] then
			error("Can't specify plurals of plurale tantum " .. pos)
		end
		insert(data.inflections, {label = glossary_link("plural only")})
	elseif args.apoc then
		-- apocopated noun
		if args[2][1] then
			error("Can't specify plurals of apocopated " .. pos)
		end
	else
		-- Fetch plurals and associated qualifiers, labels and genders.
		plurals = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = {2, "pl"},
			forms = args[2],
			include_mods = {"g"},
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
			-- If no plurals, use the default plural unless mpl= or fpl= explicitly given.
			if not plurals[1] and not mpls[1] and not fpls[1] and not is_proper then
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

		-- Process plurals, handling requests for default plurals.
		local has_default_or_hash = false
		for _, pl in ipairs(plurals) do
			if pl.term:find("^%+") or pl.term:find("#") or pl.term == "cap*" or pl.term == "cap*+" then
				has_default_or_hash = true
				break
			end
		end
		if has_default_or_hash then
			local newpls = {}

			local function insert_pl(pl, defpl)
				pl.term = defpl
				insert(newpls, pl)
			end
			local function make_gendered_plural(pl, special)
				if gender_for_default_plural == "mf" then
					local default_mpl = com.make_plural(lemma, "m", special)
					local default_fpl = com.make_plural(lemma, "f", special)
					if default_mpl then
						if default_mpl == default_fpl then
							insert_pl(pl, default_mpl)
						else
							if args.mpl[1] or args.fpl[1] then
								error("Can't specify gendered plural spec '" .. (special or "+") ..
									"' along with gender=" .. gender_for_default_plural ..
									" and also specify mpl= or fpl=")
							end
							mpls = {m_table.shallowCopy(pl)}
							mpls[1].term = default_mpl
							fpls = {pl}
							fpls[1].term = default_fpl
						end
					end
				else
					local defpl = com.make_plural(lemma, gender_for_default_plural, special)
					if defpl then
						insert_pl(pl, defpl)
					end
				end
			end

			for _, pl in ipairs(plurals) do
				if pl.term == "cap*" or pl.term == "cap*+" then
					make_gendered_plural(pl, pl.term)
				elseif pl.term == "+" then
					make_gendered_plural(pl)
				elseif pl.term:find("^%+") then
					local special = require(romut_module).get_special_indicator(pl.term)
					make_gendered_plural(pl, special)
				else
					insert_pl(pl, replace_hash_with_lemma(pl.term, lemma))
				end
			end

			plurals = newpls
		end

		if plurals[2] then
			inscat(plpos .. " with multiple plurals")
		end

		-- If the first or only plural is the same as the singular, replace it with 'invariable', or 'usually
		-- invariable' if there is more than one plural.
		local pl1 = plurals[1]
		if pl1 and pl1.term == lemma then
			if plurals[2] then
				insert(data.inflections, {label = "usually " .. glossary_link("invariable"),
					q = pl1.q, qq = pl1.qq, l = pl1.l, ll = pl1.ll, refs = pl1.refs
				})
				table.remove(plurals, 1)
			else
				insert(data.inflections, {label = glossary_link("invariable"),
					q = pl1.q, qq = pl1.qq, l = pl1.l, ll = pl1.ll, refs = pl1.refs
				})
			end
			inscat("indeclinable " .. plpos)
		end
		if plurals[1] then
			-- Check for gender-changing plurals.
			for _, pl in ipairs(plurals) do
				if pl.genders then
					for _, g in ipairs(pl.genders) do
						if type(g) ~= "table" then
							g = {spec = g}
						end
						if g.spec == "m" and not saw_m or g.spec == "f" and not saw_f then
							inscat(plpos .. " that change gender in the plural")
						end
					end
				end
			end
			-- We already took care of invariable plurals above
			insert_noun_inflection(plurals, "plural", "p", "noinv")
		end
	end

	-- Gather masculines/feminines. For each one, generate the corresponding plural. `field` is the name of the field
	-- containing the masculine or feminine forms (normally "m" or "f"); `inflect` is a function of one or two arguments
	-- to generate the default masculine or feminine from the lemma (the arguments are the lemma and optionally a
	-- "special" flag to indicate how to handle multiword lemmas, and the function is normally make_feminine or
	-- make_masculine from [[Module:it-common]]); and `default_plurals` is a list into which the corresponding default
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
			plobj.term = com.make_plural(mf.term, field, special)
			if plobj.term then
				-- Add an accelerator for each masculine/feminine plural whose lemma is the corresponding singular, so that
				-- the accelerated entry that is generated has a definition that looks like
				-- # {{plural of|it|MFSING}}
				plobj.accel = {form = "p", lemma = mf.term}
				insert(default_plurals, plobj)
			end
		end
		return mfs
	end

	local feminine_plurals = {}
	local feminines = handle_mf("f", com.make_feminine, feminine_plurals)
	local masculine_plurals = {}
	local masculines = handle_mf("m", com.make_masculine, masculine_plurals)

	local function handle_mf_plural(mfplfield, mfpls, gender, default_plurals, singulars)
		if is_plurale_tantum then
			return mfpls, true
		end
		local new_mfpls = {}
		local saw_plus
		local noinv
		for i, mfpl in ipairs(mfpls) do
			local accel
			if #mfpls == #singulars then
				-- If same number of overriding masculine/feminine plurals as singulars, assume each plural goes with
				-- the corresponding singular and use each corresponding singular as the lemma in the accelerator. The
				-- generated entry will have
				-- # {{plural of|it|SINGULAR}}
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
					local defpl = com.make_plural(lemma, gender)
					if not defpl then
						error("Unable to generate default plural of '" .. lemma .. "'")
					end
					default_plurals = {{term = defpl}}
				end
				for _, defpl in ipairs(default_plurals) do
					-- defpl is already a table and has an accel field
					m_headword_utilities.combine_termobj_qualifiers_labels(defpl, mfpl)
					insert(new_mfpls, defpl)
				end
				-- don't use "invariable" because the plural is not with respect to the lemma but with respect to the
				-- masc/fem singular
				noinv = true

				if #singulars > 0 then
					for _, mf in ipairs(singulars) do
						-- mf is a table
						local default_mfpl = com.make_plural(mf.term_for_further_inflection, gender, mfpl)
						if default_mfpl then
							-- don't use "invariable" because the plural is not with respect to the lemma but
							-- with respect to the masc/fem singular
							insert_infl(default_mfpl, accel, mf.qualifiers, "no inv")
						end
					end
				else
				end

			elseif mfpl.term == "cap*" or mfpl.term == "cap*+" or mfpl.term:find("^%+") then
				if mfpl.term:find("^%+") then
					mfpl.term = require(romut_module).get_special_indicator(mfpl.term)
				end
				if singulars[1] then
					for _, mf in ipairs(singulars) do
						local mfplobj = m_table.shallowCopy(mfpl)
						mfplobj.term = com.make_plural(mf.term_for_further_inflection, gender, mfpl.term)
						if mfplobj.term then
							mfplobj.accel = accel
							m_headword_utilities.combine_termobj_qualifiers_labels(mfplobj, mf)
							insert(new_mfpls, mfplobj)
						end
						-- don't use "invariable" because the plural is not with respect to the lemma but with respect
						-- to the masc/fem singular
						noinv = true
						-- FIXME: Should we throw an error if no plural could be generated?
					end
				else
					-- FIXME: This clause didn't exist in the corresponding code in [[Module:pt-headword]]. Is it
					-- correct?
					mfpl.term = com.make_plural(lemma, gender, mfpl.term)
					if mfpl.term then
						insert(new_mfpls, mfpl)
					end
				end
			else
				mfpl.accel = accel
				mfpl.term = replace_hash_with_lemma(mfpl.term, lemma)
				insert(new_mfpls, mfpl)
				-- don't use "invariable" if masc/fem singular present because the plural is not with respect to
				-- the lemma but with respect to the masc/fem singular
				noinv = noinv or #singulars > 0
			end
		end
		return new_mfpls, noinv
	end

	local mpl_noinv, fpl_noinv
	-- Not fpls[1] because if the user didn't specify any explicit mpl= or fpl= but the lemma gender is mf or mfbysense
	-- and has separate masculine and feminine plural forms (e.g. any term in -ista), we don't want to reprocess those
	-- auto-generated forms.
	if args.fpl[1] then
		-- Override any existing feminine plurals.
		feminine_plurals, fpl_noinv = handle_mf_plural("fpl", fpls, "f", feminine_plurals, feminines)
	else
		feminine_plurals, fpl_noinv = fpls, false
	end

	if args.mpl[1] then
		-- Override any existing masculine plurals.
		masculine_plurals, mpl_noinv = handle_mf_plural("mpl", mpls, "m", masculine_plurals, masculines)
	else
		masculine_plurals, mpl_noinv = mpls, false
	end

	local function parse_and_insert_noun_inflection(field, label, accel)
		parse_and_insert_inflection(data, args, field, label, plpos, accel)
	end

	local function redundant_plural(pl)
		for _, p in ipairs(plurals) do
			if p.term_for_further_inflection == pl.term_for_further_inflection then
				return true
			end
		end
		return false
	end

	for _, mpl in ipairs(masculine_plurals) do
		if redundant_plural(mpl) then
			track("noun-redundant-mpl")
		end
	end

	for _, fpl in ipairs(feminine_plurals) do
		if redundant_plural(fpl) then
			track("noun-redundant-fpl")
		end
	end

	insert_noun_inflection(masculines, "masculine")
	insert_noun_inflection(masculine_plurals, "masculine plural", nil, mpl_noinv)
	insert_noun_inflection(feminines, "feminine", "f")
	insert_noun_inflection(feminine_plurals, "feminine plural", nil, fpl_noinv)

	parse_and_insert_noun_inflection("dem", "demonym")
	parse_and_insert_noun_inflection("fdem", "female demonym")

	insert_deriv_inflections(data, args, plpos)

	-- Maybe add category 'Italian nouns with irregular gender' (or similar)
	local irreg_gender_lemma = lemma:gsub(" .*", "") -- only look at first word
	if (irreg_gender_lemma:find("o$") and (gender_for_default_plural == "f" or gender_for_default_plural == "mf"
		or gender_for_default_plural == "mfbysense")) or
		(irreg_gender_lemma:find("a$") and (gender_for_default_plural == "m" or gender_for_default_plural == "mf"
		or gender_for_default_plural == "mfbysense")) then
		inscat(plpos .. " with irregular gender")
	end
end

local function get_noun_params(nountype)
	local params = {
		[1] = {list = "g", disallow_holes = true, required = nountype ~= "proper", default = "?", type = "genders",
			flatten = true},
		[2] = {list = "pl", disallow_holes = true},
		["pl_g"] = {list = "pl\1_g", allow_holes = true},
		["m"] = list_param,
		["f"] = list_param,
		["mpl"] = list_param,
		["fpl"] = list_param,
		["dem"] = list_param, --demonym(s)
		["fdem"] = list_param, --female demonym(s)
	}
	insert_deriv_params(params)
	return params
end

pos_functions["nouns"] = {
	params = get_noun_params("base"),
	func = function(args, data, is_suffix)
		do_noun(args, data, "noun", is_suffix)
	end,
}

pos_functions["proper nouns"] = {
	params = get_noun_params("proper"),
	func = function(args, data, is_suffix)
		do_noun(args, data, "proper noun", is_suffix, "is proper noun")
	end,
}

pos_functions["cardinal nouns"] = {
	params = get_noun_params("base"),
	func = function(args, data, is_suffix)
		do_noun(args, data, "numeral")
		data.pos_category = "numerals"
		insert(data.categories, 1, langname .. " cardinal numbers")
	end,
}


-----------------------------------------------------------------------------------------
--                                       Adjectives                                    --
-----------------------------------------------------------------------------------------

local function do_adjective(args, data, pos, is_suffix, is_superlative)
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

	if args.inv then
		-- invariable adjective
		insert(data.inflections, {label = glossary_link("invariable")})
		insert(data.categories, langname .. " indeclinable " .. plpos)
	end
	if args.noforms then
		-- [[bello]] and any others too complicated to describe in headword
		insert(data.inflections, {label = "see below for inflection"})
	end
	if args.inv or args.apoc or args.noforms then
		if args.sp or args.f[1] or args.pl[1] or args.mpl[1] or args.fpl[1] then
			error("Can't specify inflections with an invariable or apocopated adjective or with noforms=")
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
				local defpl = com.make_plural(lemma, "f", args.sp)
				if not defpl then
					error("Unable to generate default plural of '" .. lemma .. "'")
				end
				fpl.term = defpl
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
				f.term = com.make_feminine(lemma, args.sp)
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
				local defpl = com.make_plural(lemma, "m", args.sp)
				if not defpl then
					error("Unable to generate default plural of '" .. lemma .. "'")
				end
				mpl.term = defpl
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
					local defpl = com.make_plural(f.term, "f", args.sp)
					if not defpl then
						error("Unable to generate default plural of '" .. f.term .. "'")
					end
					fplobj.term = defpl
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
	parse_and_insert_adj_inflection("comp", "comparative")
	parse_and_insert_adj_inflection("sup", "superlative")

	insert_deriv_inflections(data, args, plpos)

	if args.irreg and is_superlative then
		insert(data.categories, langname .. " irregular superlative " .. plpos)
	end
end

local function get_adjective_params(adjtype)
	local params = {
		["inv"] = boolean_param, --invariable
		["noforms"] = boolean_param, --too complicated to list forms except in a table
		["sp"] = true, -- special indicator: "first", "first-last", etc.
		["f"] = list_param, --feminine form(s)
		["pl"] = list_param, --plural override(s)
		["fpl"] = list_param, --feminine plural override(s)
		["mpl"] = list_param, --masculine plural override(s)
	}
	if adjtype == "base" or adjtype == "part" or adjtype == "det" then
		params["comp"] = list_param --comparative(s)
		params["sup"] = list_param --superlative(s)
		params["fonly"] = boolean_param -- feminine only
	end
	if adjtype == "sup" then
		params["irreg"] = boolean_param
	end
	insert_deriv_params(params)
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

pos_functions["cardinal adjectives"] = {
	params = get_adjective_params("card"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "numeral", is_suffix)
		insert(data.categories, 1, langname .. " cardinal numbers")
	end,
}

pos_functions["past participles"] = {
	params = get_adjective_params("part"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "participle", is_suffix)
		data.pos_category = "past participles"
	end,
}

pos_functions["present participles"] = {
	params = get_adjective_params("part"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "participle", is_suffix)
		data.pos_category = "present participles"
	end,
}

pos_functions["determiners"] = {
	params = get_adjective_params("det"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "determiner", is_suffix)
	end,
}

pos_functions["articles"] = {
	params = get_adjective_params("det"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "article", is_suffix)
	end,
}

pos_functions["adjective-like pronouns"] = {
	params = get_adjective_params("pron"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "pronoun", is_suffix)
	end,
}

pos_functions["cardinal invariable"] = {
	params = {},
	func = function(args, data)
		data.pos_category = "numerals"
		insert(data.categories, langname .. " cardinal numbers")
		insert(data.categories, langname .. " indeclinable numerals")
		insert(data.inflections, {label = glossary_link("invariable")})
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

	local function parse_and_insert_adv_inflection(field, label, accel, frob)
		parse_and_insert_inflection(data, args, field, label, plpos, accel, frob)
	end

	parse_and_insert_adv_inflection("comp", "comparative")
	parse_and_insert_adv_inflection("sup", "superlative")
end

local function get_adverb_params(advtype)
	local params = {}
	if advtype == "base" then
		params["comp"] = list_param --comparative(s)
		params["sup"] = list_param --superlative(s)
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
		["noautolinktext"] = boolean_param,
		["noautolinkverb"] = boolean_param,
	},
	func = function(args, data)
		if args[1] then
			local preses, prets, parts
			local def_forms

			local alternant_multiword_spec = require(it_verb_module).do_generate_forms(args, "from headword", data.heads[1])

			local function do_verb_form(slot, label, rowslot, rowlabel)
				local forms = alternant_multiword_spec.forms[slot]
				local retval
				if alternant_multiword_spec.rowprops.all_defective[rowslot] then
					if not alternant_multiword_spec.rowprops.defective[rowslot] then
						-- No forms, but none expected; don't display anything
						return
					end
					retval = {label = "no " .. rowlabel}
				elseif not forms then
					retval = {label = "no " .. label}
				elseif alternant_multiword_spec.rowprops.all_unknown[rowslot] then
					retval = {label = "unknown " .. rowlabel}
				elseif forms[1].form == "?" then
					retval = {label = "unknown " .. label}
				else
					-- Disable accelerators for now because we don't want the added accents going into the headwords.
					-- FIXME: We now have support in [[Module:accel]] to specify the target explicitly; we can use this
					-- so we can add the accelerators back with a param to avoid the accents.
					local accel_form = nil -- all_verb_slots[slot]
					retval = {label = label, accel = accel_form and {form = accel_form} or nil}
					local prev_footnotes = nil
					-- If the footnotes for this form are the same as the footnotes for the preceding form or
					-- contain the preceding footnotes, replace the footnotes that are the same with "ditto".
					-- This avoids repetition on pages like [[succedere]] where the form ''succedétti'' has a long
					-- footnote which gets repeated in the traditional form ''succedètti'' (which also has the
					-- footnote "[traditional]").
					for _, form in ipairs(forms) do
						local quals, refs = require(inflection_utilities_module).
							convert_footnotes_to_qualifiers_and_references(form.footnotes)
						local quals_with_ditto = quals
						if quals and prev_footnotes then
							local quals_contains_previous = true
							for _, qual in ipairs(prev_footnotes) do
								if not m_table.contains(quals, qual) then
									quals_contains_previous = false
									break
								end
							end
							if quals_contains_previous then
								local inserted_ditto = false
								quals_with_ditto = {}
								for _, qual in ipairs(quals) do
									if m_table.contains(prev_footnotes, qual) then
										if not inserted_ditto then
											insert(quals_with_ditto, "ditto")
											inserted_ditto = true
										end
									else
										insert(quals_with_ditto, qual)
									end
								end
							end
						end
						prev_footnotes = quals
						insert(retval, {term = form.form, q = quals_with_ditto, refs = refs})
					end
				end

				insert(data.inflections, retval)
			end

			if alternant_multiword_spec.props.is_pronominal then
				insert(data.inflections, {label = glossary_link("pronominal")})
			end
			if alternant_multiword_spec.props.impers then
				insert(data.inflections, {label = glossary_link("impersonal")})
			end
			if alternant_multiword_spec.props.thirdonly then
				insert(data.inflections, {label = "third-person only"})
			end

			local thirdonly = alternant_multiword_spec.props.impers or alternant_multiword_spec.props.thirdonly
			local sing_label = thirdonly and "third-person singular" or "first-person singular"
			for _, rowspec in ipairs {
				{"pres", "present", true},
				{"phis", "past historic", true},
				{"pp", "past participle", true},
				{"imperf", "imperfect"},
				{"fut", "future"},
				{"sub", "subjunctive"},
				{"impsub", "imperfect subjunctive"},
			} do
				local rowslot, desc, always_show = unpack(rowspec)
				local slot = rowslot .. (thirdonly and "3s" or "1s")
				local must_show = alternant_multiword_spec.is_irreg[slot]
				if always_show then
					must_show = true
				elseif rowslot == "imperf" and alternant_multiword_spec.props.has_explicit_stem_spec then
					-- If there is an explicit stem spec, make sure it gets displayed; the imperfect is a good way of
					-- showing this.
					must_show = true
				elseif not alternant_multiword_spec.forms[slot] then
					-- If the principal part is unexpectedly missing, make sure we show this.
					must_show = true
				elseif alternant_multiword_spec.forms[slot][1].form == "?" then
					-- If the principal part is unknown, make sure we show this.
					must_show = true
				end
				if must_show then
					if rowslot == "pp" then
						do_verb_form(rowslot, desc, rowslot, desc)
					else
						do_verb_form(slot, sing_label .. " " .. desc, rowslot, desc)
					end
				end
			end
			-- Also do the imperative, but not for third-only verbs, which are always missing the imperative.
			if not thirdonly and (alternant_multiword_spec.is_irreg.imp2s
				or not alternant_multiword_spec.forms.imp2s) then
				do_verb_form("imp2s", "second-person singular imperative", "imp", "imperative")
			end
			-- If there is a past participle but no auxiliary (e.g. [[malfare]]), explicitly add "no auxiliary". In
			-- cases where there's no past participle and no auxiliary (e.g. [[irrompere]]), we don't do this as we
			-- already get "no past participle" displayed. Don't display an auxiliary in any case if the lemma
			-- consists entirely of reflexive verbs (for which the auxiliary is always [[essere]]).
			if alternant_multiword_spec.props.is_non_reflexive and (
				alternant_multiword_spec.forms.aux or alternant_multiword_spec.forms.pp
			) then
				do_verb_form("aux", "auxiliary", "aux", "auxiliary")
			end

			-- Add categories.
			for _, cat in ipairs(alternant_multiword_spec.categories) do
				insert(data.categories, cat)
			end

			-- If the user didn't explicitly specify head=, or specified exactly one head (not 2+) and we were able to
			-- incorporate any links in that head into the 1= specification, use the infinitive generated by
			-- [[Module:it-verb]] it in place of the user-specified or auto-generated head so that we get accents marked
			-- on the verb(s). Don't do this if the user gave multiple heads or gave a head with a multiword-linked
			-- verbal expression such as '[[dare esca]] [[al]] [[fuoco]]'.
			if #data.user_specified_heads == 0 or (
				#data.user_specified_heads == 1 and alternant_multiword_spec.incorporated_headword_head_into_lemma
			) then
				data.heads = {}
				for _, lemma_obj in ipairs(alternant_multiword_spec.forms.inf) do
					local quals, refs = require(inflection_utilities_module).
						convert_footnotes_to_qualifiers_and_references(lemma_obj.footnotes)
					insert(data.heads, {term = lemma_obj.form, q = quals, refs = refs})
				end
			end
		end
	end
}


-----------------------------------------------------------------------------------------
--                                      Suffix forms                                   --
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

-----------------------------------------------------------------------------------------
--                                Arbitrary parts of speech                            --
-----------------------------------------------------------------------------------------

pos_functions["arbitrary part of speech"] = {
	params = {
		[1] = {required = true},
		["g"] = {list = true, disallow_holes = true, type = "genders", flatten = true},
	},
	func = function(args, data, is_suffix)
		if is_suffix then
			error("Can't use [[Template:it-pos]] with suffixes")
		end
		validate_genders(args.g)
		data.genders = args.g
		local plpos = m_en_utilities.pluralize(args[1])
		data.pos_category = plpos
	end,
}

return export
