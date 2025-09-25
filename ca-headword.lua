local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")
local com = require("Module:ca-common")

local ca_IPA_module = "Module:ca-IPA"
local ca_verb_module = "Module:ca-verb"
local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
local inflection_utilities_module = "Module:inflection utilities"
local parse_utilities_module = "Module:parse utilities"
local romut_module = "Module:romance utilities"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_string_utilities = require_when_needed("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local lang = require("Module:languages").getByCode("ca")
local langname = lang:getCanonicalName()

local list_to_text = mw.text.listToText
local insert = table.insert
local concat = table.concat
local rfind = m_string_utilities.find
local rmatch = m_string_utilities.match
local rsplit = m_string_utilities.split
local usub = m_string_utilities.sub
local rsub = com.rsub

local function track(page)
	require("Module:debug/track")("ca-headword/" .. page)
	return true
end

local list_param = {list = true, disallow_holes = true}
local boolean_param = {type = "boolean"}

-----------------------------------------------------------------------------------------
--                                    Main entry point                                 --
-----------------------------------------------------------------------------------------

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local poscat = frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")
	
	local params = {
		["head"] = list_param,
		["id"] = true,
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
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local user_specified_heads = args.head
	local heads = user_specified_heads
	if args.nolinkhead then
		if #heads == 0 then
			heads = {pagename}
		end
	else
		local romut = require(romut_module)
		local auto_linked_head = romut.add_links_to_multiword_term(pagename, args.splithyph)
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

	local post_note = data.post_note and "; " .. data.post_note or ""
	return require("Module:headword").full_headword(data) .. post_note
end


-----------------------------------------------------------------------------------------
--                                     Utility functions                               --
-----------------------------------------------------------------------------------------

local function glossary_link(entry, text)
	text = text or entry
	return "[[Appendix:Glossary#" .. entry .. "|" .. text .. "]]"
end


local function replace_hash_with_lemma(term, lemma)
	-- If there is a % sign in the lemma, we have to replace it with %% so it doesn't get interpreted as a capture replace
	-- expression.
	lemma = lemma:gsub("%%", "%%%%")
	-- Assign to a variable to discard second return value.
	term = term:gsub("#", lemma)
	return term
end


-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- `plpos` is the plural part of speech, used in [[Category:LANGNAME PLPOS with red links in their headword lines]].
-- `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, plpos, accel)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		splitchar = ",",
		label = label,
		accel = accel and {form = accel} or nil,
		check_missing = true,
		lang = lang,
		plpos = plpos,
	}
end


-- Insert default plurals generated when a given plural had the value of + and default plurals were fetched as a result.
-- `plobj` is the parsed object whose `term` field is "+". `defpls` is the list of default plurals. `dest` is the list
-- into which the plurals are inserted (which inherit their qualifiers and labels from `plobj`).
local function insert_defpls(defpls, plobj, dest)
	if not defpls then
		-- Happens e.g. with [[S.A.]] where the default plural algorithm returns nothing.
		return
	end
	if #defpls == 1 then
		plobj.term = defpls[1]
		insert(dest, plobj)
	else
		for _, defpl in ipairs(defpls) do
			local newplobj = m_table.shallowCopy(plobj)
			newplobj.term = defpl
			insert(dest, newplobj)
		end
	end
end

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
				list_to_text(indicators) .. ": " .. args.sp)
		end
	end

	local lemma = data.pagename

	local function fetch_inflections(field)
		local retval = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = field,
			forms = args[field],
			splitchar = ",",
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

	if args.f[1] == "ind" or args.f[1] == "inv" then
		-- invariable adjective
		insert(data.inflections, {label = glossary_link("invariable")})
		insert(data.categories, langname .. " indeclinable " .. plpos)
		if args.sp or args.f[2] or args.pl[1] or args.mpl[1] or args.fpl[1] then
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
				-- Generate default feminine plural.
				local defpls = com.make_plural(lemma, "f", args.sp)
				if not defpls then
					error("Unable to generate default plural of '" .. lemma .. "'")
				end
				insert_defpls(defpls, fpl, feminine_plurals)
			else
				fpl.term = replace_hash_with_lemma(fpl.term, lemma)
				insert(feminine_plurals, fpl)
			end
		end

		insert(data.inflections, {label = "feminine-only"})
		insert_inflection(feminine_plurals, "feminine plural", "f|p")
	else
		-- Gather feminines.
		for _, f in ipairs(fetch_inflections("f")) do
			if f.term == "mf" then
				f.term = lemma
			elseif f.term == "+" then
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
				local defpls

				-- First, some special hacks based on the feminine singular.
				if not fem_like_lemma and not args.sp and not lemma:find(" ") then
					for _, f in ipairs(feminines) do
						if f.term:find("ssa$") then
							-- If the feminine ends in -ssa, assume that the -ss- is also in the
							-- masculine plural form
							defpls = {rsub(f.term, "a$", "os")}
							break
						elseif f.term == lemma .. "na" then
							defpls = {lemma .. "ns"}
							break
						elseif lemma:find("ig$") and f.term:find("ja$") then
							-- Adjectives in -ig have two masculine plural forms, one derived from
							-- the m.sg. and the other derived from the f.sg.
							defpls = {lemma .. "s", rsub(f.term, "ja$", "jos")}
							break
						end
					end
				end

				defpls = defpls or com.make_plural(lemma, "m", args.sp)
				if not defpls then
					error("Unable to generate default plural of '" .. lemma .. "'")
				end
				insert_defpls(defpls, mpl, masculine_plurals)
			else
				mpl.term = replace_hash_with_lemma(mpl.term, lemma)
				insert(masculine_plurals, mpl)
			end
		end

		for _, fpl in ipairs(argsfpl) do
			if fpl.term == "+" then
				-- First, some special hacks based on the feminine singular.
				if fem_like_lemma and not args.sp and not lemma:find(" ") and lemma:find("[çx]$") then
					-- Adjectives ending in -ç or -x behave as mf-type in the singular, but
					-- regular type in the plural.
					local defpls = com.make_plural(lemma .. "a", "f")
					if not defpls then
						error("Unable to generate default plural of '" .. lemma .. "a'")
					end
					insert_defpls(defpls, fpl, feminine_plurals)
				else
					for _, f in ipairs(feminines) do
						-- Generate default feminine plural; f is a table.
						local defpls = com.make_plural(f.term, "f", args.sp)
						if not defpls then
							error("Unable to generate default plural of '" .. f.term .. "'")
						end
						for _, defpl in ipairs(defpls) do
							local fplobj = m_table.shallowCopy(fpl)
							fplobj.term = defpl
							m_headword_utilities.combine_termobj_qualifiers_labels(fplobj, f)
							insert(feminine_plurals, fplobj)
						end
					end
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
					insert_inflection(masculine_plurals, "masculine and feminine plural", "p")
				end
			else
				insert_inflection(masculine_plurals, "masculine plural", "m|p")
				insert_inflection(feminine_plurals, "feminine plural", "f|p")
			end
		end
	end

	parse_and_insert_inflection(data, args, "comp", "comparative", plpos)
	parse_and_insert_inflection(data, args, "sup", "superlative", plpos)
	parse_and_insert_inflection(data, args, "dim", "diminutive", plpos)
	parse_and_insert_inflection(data, args, "aug", "augmentative", plpos)

	if args.irreg and is_superlative then
		insert(data.categories, langname .. " irregular superlative " .. plpos)
	end
end

local function get_adjective_params(adjtype)
	local params = {
		["sp"] = true, -- special indicator: "first", "first-last", etc.
		["f"] = list_param, --feminine form(s)
		[1] = {alias_of = "f", list = false},
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
		params["hascomp"] = {} -- has comparative
	end
	if adjtype == "sup" then
		params["irreg"] = boolean_param
	end
	return params
end

-- Display additional inflection information for an adjective
pos_functions["adjectives"] = {
	params = get_adjective_params("base"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "adjective", is_suffix)
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

pos_functions["pronouns"] = {
	params = get_adjective_params("pron"),
	func = function(args, data, is_suffix)
		do_adjective(args, data, "pronoun", is_suffix)
	end,
}

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
	local plpos = require(en_utilities_module).pluralize(pos)

	validate_genders(args[1])
	data.genders = args[1]
	local saw_m = false
	local saw_f = false
	local saw_gneut = false
	local gender_for_irreg_ending, gender_for_default_plural
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
	gender_for_default_plural =
		saw_gneut and "gneut" or gender_for_irreg_ending == "mf" and "m" or gender_for_irreg_ending

	local lemma = data.pagename

	-- Plural
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
			splitchar = ",",
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
			local newpls = {}
			for _, pl in ipairs(plurals) do
				if pl.term == "+" then
					local default_pls = com.make_plural(lemma, gender_for_default_plural)
					insert_defpls(default_pls, pl, newpls)
				elseif pl.term:find("^%+") then
					pl.term = require(romut_module).get_special_indicator(pl.term)
					local default_pls = com.make_plural(lemma, gender_for_default_plural, pl.term)
					insert_defpls(default_pls, pl, newpls)
				else
					pl.term = replace_hash_with_lemma(pl.term, lemma)
					insert(newpls, pl)
				end
			end
			plurals = newpls
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
	-- make_masculine from [[Module:ca-common]]); and `default_plurals` is a list into which the corresponding default
	-- plurals of the gathered or generated masculine or feminine forms are stored.
	local function handle_mf(field, inflect, default_plurals)
		local function call_inflect(special)
			if inflect then
				-- Generate default feminine.
				return inflect(lemma, special)
			else
				-- FIXME
				error("Can't generate default masculine currently")
			end
		end

		local mfs = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = field,
			forms = args[field],
			splitchar = ",",
			frob = function(term)
				if term == "+" then
					-- Generate default masculine/feminine.
					term = call_inflect()
				else
					term = replace_hash_with_lemma(term, lemma)
				end
				local special = require(romut_module).get_special_indicator(term)
				if special then
					term = call_inflect(special)
				end
				return term
			end
		}
		for _, mf in ipairs(mfs) do
			local mfpls = com.make_plural(mf.term, gender, special)
			if mfpls then
				for _, mfpl in ipairs(mfpls) do
					local plobj = m_table.shallowCopy(mf)
					plobj.term = mfpl
					-- Add an accelerator for each masculine/feminine plural whose lemma
					-- is the corresponding singular, so that the accelerated entry
					-- that is generated has a definition that looks like
					-- # {{plural of|ca|MFSING}}
					plobj.accel = {form = "p", lemma = mf.term}
					table.insert(default_plurals, plobj)
				end
			end
		end
		return mfs
	end

	local feminine_plurals = {}
	local feminines = handle_mf("f", com.make_feminine, feminine_plurals)
	local masculine_plurals = {}
	local masculines = handle_mf("m", com.make_masculine, masculine_plurals)

	local function handle_mf_plural(mfplfield, default_plurals, singulars)
		local mfpl = m_headword_utilities.parse_term_list_with_modifiers {
			paramname = mfplfield,
			forms = args[mfplfield],
			splitchar = ",",
		}
		local new_mfpls = {}
		local saw_plus
		for i, mfpl in ipairs(mfpl) do
			local accel
			if #mfpl == #singulars then
				-- If same number of overriding masculine/feminine plurals as singulars, assume each plural goes with
				-- the corresponding singular and use each corresponding singular as the lemma in the accelerator. The
				-- generated entry will have
				-- # {{plural of|ca|SINGULAR}}
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
					local default_mfpls = com.make_plural(mf.term, gender, mfpl.term)
					for _, defp in ipairs(default_mfpls) do
						local mfplobj = m_table.shallowCopy(mfpl)
						mfplobj.term = defp
						mfplobj.accel = accel
						m_headword_utilities.combine_termobj_qualifiers_labels(mfplobj, mf)
						insert(new_mfpls, mfplobj)
					end
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

	-- Is this a noun with an unexpected ending (for its gender)?
	-- Only check if the term is one word (there are no spaces in the term).
	local irreg_gender_lemma = rsub(lemma, " .*", "") -- only look at first word
	if (gender_for_irreg_ending == "m" or gender_for_irreg_ending == "mf") and irreg_gender_lemma:find("a$") then
		insert(data.categories, langname .. " masculine " .. plpos .. " ending in -a")
	elseif (gender_for_irreg_ending == "f" or gender_for_irreg_ending == "mf") and not (
		irreg_gender_lemma:find("a$") or irreg_gender_lemma:find("ió$") or irreg_gender_lemma:find("tat$") or
		irreg_gender_lemma:find("tud$") or irreg_gender_lemma:find("[dt]riu$")) then
		insert(data.categories, langname .. " feminine " .. plpos .. " with no feminine ending")
	end
end

local function get_noun_params(is_proper)
	return {
		[1] = {list = "g", disallow_holes = true, required = not is_proper, default = "?", type = "genders",
			flatten = true}, -- gender(s)
		[2] = {list = "pl", disallow_holes = true}, --plural override(s)
		["f"] = list_param, --feminine form(s)
		["m"] = list_param, --masculine form(s)
		["fpl"] = list_param, --feminine plural override(s)
		["mpl"] = list_param, --masculine plural override(s)
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
		do_noun(args, data, "noun", is_suffix, "is proper")
	end,
}

-----------------------------------------------------------------------------------------
--                                         Verbs                                       --
-----------------------------------------------------------------------------------------

pos_functions["verbs"] = {
	params = {
		[1] = true,
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
		["pres_1_sg"] = true, -- accept any ignore old-style param
		["past_part"] = true, -- accept any ignore old-style param
		["root"] = true, -- FIXME: Implement root-stressed vowel quality
	},

	func = function(args, data, tracking_categories, frame)
		local preses, preses_3s, prets, parts, short_parts

		if args.attn then
			insert(tracking_categories, "Requests for attention concerning " .. langname)
			return
		end

		local ca_verb = require(ca_verb_module)
		local alternant_multiword_spec = ca_verb.do_generate_forms(args, "ca-verb", data.heads[1])

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

		if args.pres[1] or args.pres3s[1] or args.pret[1] or args.part[1] or args.short_part[1] then
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
				insert(stripped_qualifiers, stripped_qualifier)
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
						-- [[Module:inflection utilities]] already loaded by [[Module:ca-verb]]
						form = require(inflection_utilities_module).add_links(form)
					end
					insert(forms, {form = form, footnotes = qual})
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
					-- Don't include accelerators if brackets remain in form, as the result will be wrong.
					-- FIXME: For now, don't include accelerators. We should use the new {{ca-verb form of}}.
					-- local this_accel = not stripped_form:find("%[%[") and accel or nil
					local this_accel = nil
					insert(into_table, {term = stripped_form, q = qualifiers, accel = this_accel})
				end
				to_insert = into_table
			end

			insert(data.inflections, to_insert)
		end

		local skip_pres_if_empty
		if alternant_multiword_spec.no_pres1_and_sub then
			insert(data.inflections, {label = "no first-person singular present"})
			insert(data.inflections, {label = "no present subjunctive"})
		end
		if alternant_multiword_spec.no_pres_stressed then
			insert(data.inflections, {label = "no stressed present indicative or subjunctive"})
			skip_pres_if_empty = true
		end
		if alternant_multiword_spec.only3s then
			insert(data.inflections, {label = glossary_link("impersonal")})
		elseif alternant_multiword_spec.only3sp then
			insert(data.inflections, {label = "third-person only"})
		elseif alternant_multiword_spec.only3p then
			insert(data.inflections, {label = "third-person plural only"})
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
			insert(data.categories, cat)
		end

		-- If the user didn't explicitly specify head=, or specified exactly one head (not 2+) and we were able to
		-- incorporate any links in that head into the 1= specification, use the infinitive generated by
		-- [[Module:ca-verb]] in place of the user-specified or auto-generated head. This was copied from
		-- [[Module:it-headword]], where doing this gets accents marked on the verb(s). We don't have accents marked on
		-- the verb but by doing this we do get any footnotes on the infinitive propagated here. Don't do this if the
		-- user gave multiple heads or gave a head with a multiword-linked verbal expression such as Italian
		-- '[[dare esca]] [[al]] [[fuoco]]' (FIXME: give Catalan equivalent).
		if #data.user_specified_heads == 0 or (
			#data.user_specified_heads == 1 and alternant_multiword_spec.incorporated_headword_head_into_lemma
		) then
			data.heads = {}
			for _, lemma_obj in ipairs(alternant_multiword_spec.forms.infinitive_linked) do
				local quals, refs = require(inflection_utilities_module).
					convert_footnotes_to_qualifiers_and_references(lemma_obj.footnotes)
				insert(data.heads, {term = lemma_obj.form, q = quals, refs = refs})
			end
		end

		if args.root then
			local m_ca_IPA = require(ca_IPA_module)

			local parsed_respellings = {}
			local function set_parsed_respelling(dialect, parsed)
				-- Validate the individual root vowel specs.
				for _, termobj in ipairs(parsed.terms) do
					if not rfind(termobj.words[1].term, "^" .. m_ca_IPA.mid_vowel_hint_c .. "$") then
						error(("Root vowel spec '%s' should be one of the vowels %s"):format(
							termobj.words[1].term, m_ca_IPA.mid_vowel_hints))
					end
				end

				if not dialect then
					for _, dial in ipairs(m_ca_IPA.dialects) do
						-- Need to clone as we destructively modify each one later with the pronun.
						parsed_respellings[dial] = m_table.deepCopy(parsed)
					end
				elseif m_ca_IPA.dialect_groups[dialect] then
					for _, dial in ipairs(m_ca_IPA.dialect_groups[dialect]) do
						-- Need to clone as we destructively modify each one later with the pronun.
						parsed_respellings[dial] = m_table.deepCopy(parsed)
					end
				else
					parsed_respellings[dialect] = parsed
				end
			end

			local function check_dialect_or_dialect_group(dialect)
				if not m_table.contains(m_ca_IPA.dialects, dialect) and not
					m_ca_IPA.dialect_groups[dialect] then
					local dialect_list = {}
					for _, dial in ipairs(m_ca_IPA.dialects) do
						insert(dialect_list, "'" .. dial .. "'")
					end
					dialect_list = list_to_text(dialect_list, nil, " or ")
					local dialect_group_list = {}
					for dialect_group, _ in pairs(m_ca_IPA.dialect_groups) do
						insert(dialect_group_list, "'" .. dialect_group .. "'")
					end
					dialect_group_list = list_to_text(dialect_group_list, nil, " or ")
					error(("Unrecognized dialect '%s': Should be a dialect %s or a dialect group %s"):format(
						dialect, dialect_list, dialect_group_list))
				end
			end

			-- Parse the root vowel specs.
			if args.root:find("[<%[]") then
				local put = require(parse_utilities_module)
				-- Parse balanced segment runs involving either [...] (substitution notation) or <...> (inline
				-- modifiers). We do this because we don't want commas or semicolons inside of square or angle brackets
				-- to count as respelling delimiters. However, we need to rejoin square-bracketed segments with nearby
				-- ones after splitting alternating runs on comma and semicolon.
				local segments = put.parse_multi_delimiter_balanced_segment_run(args.root, {{"<", ">"}, {"[", "]"}})

				local semicolon_separated_groups = put.split_alternating_runs(segments, "%s*;%s*")
				for _, group in ipairs(semicolon_separated_groups) do
					local first_element = group[1]
					local dialect
					if first_element:find("^[a-z]+:") then
						-- a dialect-specific spec
						local rest
						dialect, rest = first_element:match("^([a-z]+):(.*)$")
						check_dialect_or_dialect_group(dialect)
						group[1] = rest
					end

					local comma_separated_groups = put.split_alternating_runs_on_comma(group)

					-- Process each value.
					local outer_container = m_ca_IPA.parse_comma_separated_groups(comma_separated_groups, true, args.root,
						"root")
					set_parsed_respelling(dialect, outer_container)
				end
			else
				for _, dialect_spec in ipairs(rsplit(args.root, "%s*;%s*")) do
					local dialect
					if dialect_spec:find("^[a-z]+:") then
						-- a dialect-specific spec
						local rest
						dialect, rest = dialect_spec:match("^([a-z]+):(.*)$")
						check_dialect_or_dialect_group(dialect)
						dialect_spec = rest
					end
					local termobjs = {}
					for _, word in ipairs(rsplit(dialect_spec, ",")) do
						insert(termobjs, {words = {{term = word}}})
					end
					set_parsed_respelling(dialect, {
						terms = termobjs,
					})
				end
			end

			-- Convert each canonicalized respelling to phonemic/phonetic IPA.
			m_ca_IPA.generate_phonemic_phonetic(parsed_respellings)

			-- Group the results.
			local grouped_pronuns = m_ca_IPA.group_pronuns_by_dialect(parsed_respellings)

			-- Format for display.
			for _, grouped_pronun_spec in pairs(grouped_pronuns) do
				local pronunciations = {}

				local function ins(text)
					insert(pronunciations, text)
				end

				-- Loop through each pronunciation. For each one, format the phonetic version "raw".
				for j, pronun in ipairs(grouped_pronun_spec.pronuns) do
					-- Add dialect tags to left accent qualifiers if first one
					local as = pronun.a
					if j == 1 then
						if as then
							as = m_table.deepCopy(as)
						else
							as = {}
						end
						for _, dialect in ipairs(grouped_pronun_spec.dialects) do
							insert(as, m_ca_IPA.dialects_to_names[dialect])
						end
					else
						ins(", ")
					end

					local slash_pron = "/" .. pronun.phonetic:gsub("ˈ", "") .. "/"
					if as or pronun.q or pronun.qq or pronun.aa then
						ins(require("Module:pron qualifier").format_qualifiers {
							lang = lang,
							text = slash_pron,
							q = pronun.q,
							a = as,
							qq = pronun.qq,
							aa = pronun.aa
						})
					else
						ins(slash_pron)
					end
					if pronun.refs then
						-- FIXME: Copied from [[Module:IPA]]. Should be in a module.
						local refs = {}
						if #pronun.refs > 0 then
							for _, refspec in ipairs(pronun.refs) do
								if type(refspec) ~= "table" then
									refspec = {text = refspec}
								end
								local refargs
								if refspec.name or refspec.group then
									refargs = {name = refspec.name, group = refspec.group}
								end
								insert(refs, mw.getCurrentFrame():extensionTag("ref", refspec.text, refargs))
							end
							ins(concat(refs))
						end
					end
				end

				grouped_pronun_spec.formatted = concat(pronunciations)
			end

			-- Concatenate formatted results.
			local formatted = {}
			for _, grouped_pronun_spec in ipairs(grouped_pronuns) do
				insert(formatted, grouped_pronun_spec.formatted)
			end
			data.post_note = "''root stress'': " .. concat(formatted, "; ")
		end
	end
}

-----------------------------------------------------------------------------------------
--                                        Numerals                                     --
-----------------------------------------------------------------------------------------

-- Display additional inflection information for a numeral
pos_functions["numerals"] = {
	params = {
		[1] = true,
		[2] = true,
	},

	func = function(args, data, is_suffix)
		if args[1] then
			insert(data.genders, "m")
			local plpos = "phrases"
			parse_and_insert_inflection(data, args, 1, "feminine", plpos)
			parse_and_insert_inflection(data, args, 2, "noun form", plpos)
		else
			insert(data.genders, "m")
			insert(data.genders, "f")
		end
	end
}

-----------------------------------------------------------------------------------------
--                                       Phrases                                       --
-----------------------------------------------------------------------------------------

pos_functions["phrases"] = {
	params = {
		["g"] = {list = true, disallow_holes = true, type = "genders", flatten = true},
		["m"] = list_param,
		["f"] = list_param,
	},
	func = function(args, data)
		validate_genders(args.g)
		data.genders = args.g
		local plpos = "phrases"
		parse_and_insert_inflection(data, args, "m", "masculine", plpos)
		parse_and_insert_inflection(data, args, "f", "feminine", plpos)
	end,
}

-----------------------------------------------------------------------------------------
--                                    Suffix forms                                     --
-----------------------------------------------------------------------------------------

pos_functions["suffix forms"] = {
	params = {
		[1] = {required = true, list = true, disallow_holes = true},
		["g"] = {list = true, disallow_holes = true, type = "genders", flatten = true},
	},
	func = function(args, data)
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
