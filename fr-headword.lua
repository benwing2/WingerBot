local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages
local check_missing = false -- whether to check for missing forms

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")
local lang = require("Module:languages").getByCode("fr")
local langname = lang:getCanonicalName()

local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
local romut_module = "Module:romance utilities"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}

local concat = table.concat
local insert = table.insert
local remove = table.remove
local sort = table.sort

local prepositions = {
	"à ",
	"aux? ",
	"d[eu] ",
	"d['’]",
	"des ",
	"en ",
	"sous ",
	"sur ",
	"avec ",
	"pour ",
	"par ",
	"dans ",
	"contre ",
	"sans ",
	"comme ",
	"jusqu['’]",
	-- We could list others but you get diminishing returns
}

local no_split_apostrophe_words = {
	["c'est"] = true,
	["quelqu'un"] = true,
	["aujourd'hui"] = true,
}

local function track(page)
	require("Module:debug").track("fr-headword/" .. page)
	return true
end

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
		local romut = require(romut_module)
		local auto_linked_head = romut.add_links_to_multiword_term(pagename, args.splithyph, no_split_apostrophe_words)
		if not heads[1] then
			heads = {auto_linked_head}
		else
			for i, head in ipairs(heads) do
				if head:find("^~") then
					head = romut.apply_link_modifiers(auto_linked_head, head:sub(2))
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


-----------------------------------------------------------------------------------------
--                                     Utility functions                               --
-----------------------------------------------------------------------------------------

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
		check_missing = check_missing,
		lang = lang,
		plpos = plpos,
	}
end

local function make_plural(form, special)
	local retval = require(romut_module).handle_multiword(form, special, make_plural, prepositions)
	if retval then
		if #retval > 1 then
			error("Internal error: Got multiple plurals from handle_multiword(): " .. concat(retval))
		end
		return retval[1]
	end

	if form:match("[sxz]$") then
		return form
	elseif form:match("au$") then
		return form .. "x"
	elseif form:match("al$") then
		return form:gsub("al$", "aux")
	end
	return form .. "s"
end

local function make_feminine(form, special)
	local retval = require(romut_module).handle_multiword(form, special, make_feminine, prepositions)
	if retval then
		if #retval > 1 then
			error("Internal error: Got multiple feminines from handle_multiword(): " .. concat(retval))
		end
		return retval[1]
	end

	if form:match("e$") then
		return form
	elseif form:match("en$") then
		return form .. "ne"
	elseif form:match("er$") then
		return form:gsub("er$", "ère")
	elseif form:match("el$") then
		return form .. "le"
	elseif form:match("et$") then
		return form .. "te"
	elseif form:match("on$") then
		return form .. "ne"
	elseif form:match("ieur$") then
		return form .. "e"
	elseif form:match("teur$") then
		return form:gsub("teur$", "trice")
	elseif form:match("eu[rx]$") then
		return form:gsub("eu[rx]$", "euse")
	elseif form:match("if$") then
		return form:gsub("if$", "ive")
	elseif form:match("c$") then
		return form:gsub("c$", "que")
	elseif form:match("eau$") then
		return form:gsub("eau$", "elle")
	else
		return form .. "e"
	end
end

-- For bot use
function export.make_feminine(frame)
	local masc = frame.args[1] or error("Masculine in 1= is required.")
	local special = frame.args[2]
	return make_feminine(masc, special)
end

-- Handle generation of feminine or plural inflections when "+" is encountered. `list` is the existing base forms
-- (strings or form objects) that need to be inflected. `defobj` is the form object whose `term` field is "+"; any
-- qualifiers, labels and/or references from that form object will be combined with those of the base form. `inflfun`
-- is the function to do the inflection, which is passed two arguments, the base form value (a string) and the
-- `special` value specified for handling multiword expressions (or nil if no value specified). Returns the new list
-- of inflected form objects.
local function make_inflection(list, defobj, inflfun, special)
	local newlist = {}
	for _, form in ipairs(list) do
		if type(form) == "string" then
			form = {term = form}
		end
		local infl = inflfun(form.term, special)
		local formobj = m_table.shallowCopy(form)
		formobj.term = infl
		m_headword_utilities.combine_termobj_qualifiers_labels(formobj, defobj)
		insert(newlist, formobj)
	end
	return newlist
end


-----------------------------------------------------------------------------------------
--                                          Nouns                                      --
-----------------------------------------------------------------------------------------

local allowed_genders = m_table.listToSet {
	"m", "f", "mf", "mfbysense", "mfequiv", "gneut", "m-p", "f-p", "mf-p", "mfbysense-p", "mfequiv-p", "gneut-p",
	"?", "?-p",
}

local additional_allowed_pronoun_genders = m_table.listToSet {
	"m-s", "f-s", "mf-s",
	"p", -- mf-p doesn't make sense for e.g. [[iels]]/[[ielles]]
	"n", -- e.g. [[ceci]]/[[cela]]
}

local function validate_genders(genders, is_pronoun)
	for _, g in ipairs(genders) do
		if type(g) == "table" then
			g = g.spec
		end
		if not allowed_genders[g] and (not is_pronoun or not additional_allowed_pronoun_genders[g]) then
			error("Unrecognized gender: " .. g)
		end
	end
end

local function make_qual_replaced_by(replacement)
	return {list = true, allow_holes = true, replaced_by = false,
		instead = ("use an inline modifier on |%s= such as <q:...>, <qq:...>, <l:...> or <ll:...>"):format(replacement)
	}
end

local function make_alias_replaced_by(replacement, reason)
	return {list = true, disallow_holes = true, replaced_by = replacement, reason = reason or
		"for consistency with the corresponding parameter in other Romance-language headword templates"
	}
end

local function get_noun_params(is_proper)
	return {
		[1] = {list = "g", disallow_holes = true, required = not is_proper, default = "?", type = "genders",
			flatten = true}, -- gender(s)
		["g"] = {replaced_by = 1, reason = "for consistency"},
		[2] = list_param, --plural override(s)
		["pqual"] = make_qual_replaced_by("2"),
		["f"] = list_param, --feminine form(s)
		["fqual"] = make_qual_replaced_by("f"),
		["m"] = list_param, --masculine form(s)
		["fqual"] = make_qual_replaced_by("m"),
		["dim"] = list_param, --diminutive(s)
		["dimqual"] = make_qual_replaced_by("dim"),
		["aug"] = list_param, --diminutive(s)
		["pej"] = list_param, --pejorative(s)
		["dem"] = list_param, --demonym(s)
		["fdem"] = list_param, --female demonym(s)
	}
end

local function do_noun(args, data, pos, is_suffix, is_proper)
	local is_plurale_tantum = false
	local has_singular = false
	if pos == "cardinal noun" then
		pos = "numeral"
		data.pos_category = "numerals"
		insert(data.categories, 1, langname .. " cardinal numbers")
	end
	if is_suffix then
		pos = "suffix"
	end

	local plpos = require(en_utilities_module).pluralize(pos)

	validate_genders(args[1])
	data.genders = args[1]
	-- Check for specific genders and pluralia tantum.
	for _, g in ipairs(args[1]) do
		if type(g) == "table" then
			g = g.spec
		end
		if g:find("-p$") then
			is_plurale_tantum = true
		else
			has_singular = true
		end
	end

	local lemma = data.pagename

	-- Plural
	local plurals = {}

	local function insert_noun_inflection(terms, label, accel)
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
			elseif mode ~= "+" and mode ~= "#" and not mode:find("[a-zA-Z]") then
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
		for _, pl in ipairs(plurals) do
			if pl.term == "+" then
				pl.term = make_plural(lemma)
			elseif pl.term:find("^%+") then
				pl.term = require(romut_module).get_special_indicator(pl.term)
				pl.term = make_plural(lemma, pl.term)
			elseif pl.term == "s" or pl.term == "x" then
				-- FIXME, convert to #s or #x
				pl.term = lemma .. pl.term
			else
				pl.term = replace_hash_with_lemma(pl.term, lemma)
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
	-- containing the masculine or feminine forms (normally "m" or "f"); and `inflect` is a function of one or two
	-- arguments to generate the default masculine or feminine from the lemma (the arguments are the lemma and
	-- optionally a "special" flag to indicate how to handle multiword lemmas, and the function is normally
	-- make_feminine or make_masculine [which doesn't exist, FIXME]).
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
				elseif term == "e" and field == "f" then
					-- FIXME: remove this special case
					term = lemma .. "e"
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
		return mfs
	end

	local feminines = handle_mf("f", make_feminine)
	local masculine_plurals = {}
	local masculines = handle_mf("m", nil)

	local function parse_and_insert_noun_inflection(field, label, accel)
		parse_and_insert_inflection(data, args, field, label, plpos, accel)
	end

	insert_noun_inflection(feminines, "feminine", "f")
	insert_noun_inflection(masculines, "masculine")

	parse_and_insert_noun_inflection("dim", "diminutive")
	parse_and_insert_noun_inflection("aug", "augmentative")
	parse_and_insert_noun_inflection("pej", "pejorative")
	parse_and_insert_noun_inflection("dem", "demonym")
	parse_and_insert_noun_inflection("fdem", "female demonym")
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

pos_functions["cardinal nouns"] = {
	params = get_noun_params(),
	func = function(args, data, is_suffix)
		do_noun(args, data, "cardinal noun", is_suffix)
	end,
}

local function get_pronoun_pos(pos)
	return {
		params = {
			[1] = {list = "g", disallow_holes = true, required = true, default = "?", type = "genders",
				flatten = true}, -- gender(s)
			["g"] = {replaced_by = 1, reason = "for consistency"},
			["f"] = list_param,
			["fqual"] = make_qual_replaced_by("f"),
			["m"] = list_param,
			["mqual"] = make_qual_replaced_by("m"),
			["mv"] = list_param,
			["mvqual"] = make_qual_replaced_by("mv"),
			["fpl"] = list_param,
			["fp"] = make_alias_replaced_by("fpl"),
			["fpqual"] = make_qual_replaced_by("fpl"),
			["mpl"] = list_param,
			["mp"] = make_alias_replaced_by("mpl"),
			["mpqual"] = make_qual_replaced_by("mpl"),
			["pl"] = list_param,
			["p"] = make_alias_replaced_by("pl"),
			["pqual"] = make_qual_replaced_by("pl"),
			["type"] = list_param,
		},

		func = function(args, data)
			-- Validate and add genders.
			validate_genders(args[1], "is pronoun")
			data.genders = args[1]

			local plpos = require(en_utilities_module).pluralize(pos)

			local function parse_and_insert_pronoun_inflection(field, label, accel)
				parse_and_insert_inflection(data, args, field, label, plpos, accel)
			end

			-- Parse and insert all inflections.
			parse_and_insert_pronoun_inflection("m", "masculine")
			parse_and_insert_pronoun_inflection("mv", "masculine singular before vowel")
			parse_and_insert_pronoun_inflection("f", "feminine")
			parse_and_insert_pronoun_inflection("mpl", "masculine plural")
			parse_and_insert_pronoun_inflection("fpl", "feminine plural")
			parse_and_insert_pronoun_inflection("pl", "plural")

			-- Categorize by "type"
			for _, ty in ipairs(args.type) do
				local category
				if ty == "indefinite" then
					category = "indefinite"
				elseif ty == "interrogative" then
					category = "interrogative"
				elseif ty == "personal" then
					category = "personal"
				elseif ty == "possessive" then
					category = "possessive"
				elseif ty == "reflexive" then
					category = "reflexive"
				elseif ty == "relative" then
					category = "relative"
				end
				if category then
					if type(category) == "table" then
						for _, cat in ipairs(category) do
							insert(data.categories, langname .. " " .. cat .. " pronouns")
						end
					else
						insert(data.categories, langname .. " " .. category .. " pronouns")
					end
				end
			end
		end
	}
end

pos_functions["pronouns"] = get_pronoun_pos("pronoun")
pos_functions["determiners"] = get_pronoun_pos("determiner")

local function get_misc_pos()
	return {
		params = {
			[1] = {replaced_by = "head", reason = "for consistency with other French headword templates"},
		},

		func = function(args, data)
		end
	}
end

pos_functions["adverbs"] = get_misc_pos()

pos_functions["prepositions"] = get_misc_pos()

pos_functions["phrases"] = get_misc_pos()

pos_functions["prepositional phrases"] = get_misc_pos()

pos_functions["proverbs"] = get_misc_pos()

pos_functions["punctuation marks"] = get_misc_pos()

pos_functions["diacritical marks"] = get_misc_pos()

pos_functions["interjections"] = get_misc_pos()

pos_functions["prefixes"] = get_misc_pos()

pos_functions["abbreviations"] = get_misc_pos()

local function do_adjective(pos)
	return {
		params = {
			[1] = true,
			["inv"] = boolean_param,
			["sp"] = true, -- special indicator: "first", "first-last", etc.
			["onlyg"] = true,
			["m"] = list_param,
			["mqual"] = make_qual_replaced_by("m"),
			["mv"] = list_param,
			["mvqual"] = make_qual_replaced_by("mv"),
			["f"] = list_param,
			["fqual"] = make_qual_replaced_by("f"),
			["mpl"] = list_param,
			["mp"] = make_alias_replaced_by("mpl"),
			["mpqual"] = make_qual_replaced_by("mpl"),
			["fpl"] = list_param,
			["fp"] = make_alias_replaced_by("fpl"),
			["fpqual"] = make_qual_replaced_by("fpl"),
			["pl"] = list_param,
			["p"] = make_alias_replaced_by("pl"),
			["pqual"] = make_qual_replaced_by("pl"),
			["base"] = list_param,
			["current"] = make_alias_replaced_by("base", "because the old name was obscure and did not clarify the purpose of the parameter"),
			["comp"] = list_param,
			["compqual"] = make_qual_replaced_by("comp"),
			["sup"] = list_param,
			["supqual"] = make_qual_replaced_by("sup"),
			["intr"] = boolean_param,
		},

		func = function(args, data)
			if pos == "cardinal adjective" then
				pos = "numeral"
				data.pos_category = "numerals"
				insert(data.categories, 1, langname .. " cardinal numbers")
			end
			
			local plpos = require(en_utilities_module).pluralize(pos)

			if pos ~= "numeral" then
				if args.onlyg == "p" or args.onlyg == "m-p" or args.onlyg == "f-p" then
					insert(data.categories, langname .. " pluralia tantum")
				end
				if args.onlyg == "s" or args.onlyg == "f-s" or args.onlyg == "f-s" then
					insert(data.categories, langname .. " singularia tantum")
				end
				if args.onlyg then
					insert(data.categories, langname .. " defective " .. plpos)
				end
			end

			local lemma = data.pagename

			local function insert_inflection(terms, label, accel)
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

			local function process_inflection(label, arg, accel, get_default, explicit_default_only)
				local orig_infls = m_headword_utilities.parse_term_list_with_modifiers {
					paramname = arg,
					forms = args[arg],
					splitchar = ",",
				}
				if not orig_infls[1] then
					if explicit_default_only or not get_default then
						orig_infls = {}
					else
						orig_infls = {{term = "+"}}
					end
				end
				local infls = {}
				if orig_infls[1] then
					for _, infl in ipairs(orig_infls) do
						if infl.term == "+" then
							local defs
							if get_default then
								defs = get_default(infl)
							else
								error("Can't use '+' with " .. arg .. "=; no default available")
							end
							for _, def in ipairs(defs) do
								insert(infls, def)
							end
						elseif infl.term == "e" or infl.term == "s" or infl.term == "x" then
							-- FIXME: delete this in favor of #e, #s, #x
							infl.term = lemma .. infl.term
							insert(infls, infl)
						else
							infl.term = replace_hash_with_lemma(infl.term, lemma)
							insert(infls, infl)
						end
					end
					insert_inflection(infls, label, accel)
				end
				return infls
			end

			if args.sp and not require(romut_module).allowed_special_indicators[args.sp] then
				local indicators = {}
				for indic, _ in pairs(require(romut_module).allowed_special_indicators) do
					insert(indicators, "'" .. indic .. "'")
				end
				sort(indicators)
				error("Special inflection indicator beginning can only be " ..
					mw.text.listToText(indicators) .. ": " .. args.sp)
			end

			local function get_base()
				return args.base[1] and args.base or {lemma}
			end

			if args.onlyg == "p" then
				insert(data.inflections, {label = "plural only"})
				if args[1] ~= "mf" then
					-- Handle feminine plurals
					process_inflection("feminine plural", "fpl", "f|p")
				end
			elseif args.onlyg == "s" then
				insert(data.inflections, {label = "singular only"})
				if not (args[1] == "mf" or not args.f[1] and lemma:match("e$")) then
					-- Handle feminines
					process_inflection("feminine singular", "f", "f", function(defobj)
						return make_inflection(get_base(), defobj, make_feminine, args.sp)
					end)
				end
			elseif args.onlyg == "m" then
				insert(data.genders, "m")
				insert(data.inflections, {label = "masculine only"})
				-- Handle masculine plurals
				process_inflection("masculine plural", "mpl", "m|p", function(defobj)
					return make_inflection(get_base(), defobj, make_plural, args.sp)
				end)
			elseif args.onlyg == "f" then
				insert(data.genders, "f")
				insert(data.inflections, {label = "feminine only"})
				-- Handle feminine plurals
				process_inflection("feminine plural", "fpl", "f|p", function(defobj)
					return make_inflection(get_base(), defobj, make_plural, args.sp)
				end)
			elseif args.onlyg then
				insert(data.genders, args.onlyg)
				insert(data.inflections, {label = "defective"})
			else
				-- Gather genders
				local gender = args[1]
				-- Default to mf if base form ends in -e and no feminine,
				-- feminine plural or gender specified
				if not gender and not args.f[1] and not args.fpl[1] and lemma:match("e$")
					and not lemma:find(" ", nil, true) then
					gender = "mf"
				end

				if args.intr then
					insert(data.inflections, {label = glossary_link("intransitive")})
					insert(data.inflections, {label = "hence " .. glossary_link("invariable")})
					args.inv = true
				elseif args.inv then
					insert(data.inflections, {label = glossary_link("invariable")})
				end

				-- Handle plurals of mf adjectives
				if not args.inv and gender == "mf" then
					process_inflection("plural", "pl", "p", function(defobj)
						return make_inflection(get_base(), defobj, make_plural, args.sp)
					end)
				end

				if not args.inv and gender ~= "mf" then
					-- Handle masculine form if not same as lemma; e.g. [[sûr de soi]] with m=+, m2=sûr de lui
					process_inflection("masculine singular", "m", "m|s",
						function(defobj)
							defobj = m_table.shallowCopy(defobj)
							defobj.term = lemma
							return {defobj}
						end, "explicit default only")

					-- Handle case of special masculine singular before vowel
					process_inflection("masculine singular before vowel", "mv", "m|s")

					-- Handle feminines
					local feminines = process_inflection("feminine", "f", "f|s", function(defobj)
						return make_inflection(get_base(), defobj, make_feminine, args.sp)
					end)

					-- Handle masculine plurals
					process_inflection("masculine plural", "mpl", "m|p", function(defobj)
						return make_inflection(get_base(), defobj, make_plural, args.sp)
					end)

					-- Handle feminine plurals
					process_inflection("feminine plural", "fpl", "f|p", function(defobj)
						return make_inflection(feminines, defobj, make_plural, args.sp)
					end)
				end
			end

			-- Handle comparatives
			process_inflection("comparative", "comp", "comparative")

			-- Handle superlatives
			process_inflection("superlative", "sup", "superlative")
		end
	}
end

pos_functions["adjectives"] = do_adjective("adjective")
pos_functions["past participles"] = do_adjective("participle")
pos_functions["cardinal adjectives"] = do_adjective("cardinal adjective")

pos_functions["verbs"] = {
	params = {
		["type"] = list_param,
	},

	func = function(args, data)
		local pos = "verbs"
		for _, ty in ipairs(args.type) do
			local category, label
			if ty == "auxiliary" then
				category = "auxiliary"
			elseif ty == "defective" then
				category = "defective"
				label = glossary_link("defective")
			elseif ty == "impersonal" then
				category = "impersonal"
				label = glossary_link("impersonal")
			elseif ty == "modal" then
				category = "modal"
			elseif ty == "reflexive" then
				category = "reflexive"
			elseif ty == "transitive" then
				label = glossary_link("transitive")
				category = "transitive"
			elseif ty == "intransitive" then
				label = glossary_link("intransitive")
				category = "intransitive"
			elseif ty == "ambitransitive" or ty == "ambi" then
				category = {"transitive", "intransitive"}
				label = glossary_link("transitive") .. " and " .. glossary_link("intransitive")
			end
			if category then
				if type(category) == "table" then
					for _, cat in ipairs(category) do
						insert(data.categories, langname .. " " .. cat .. " " .. pos)
					end
				else
					insert(data.categories, langname .. " " .. category .. " " .. pos)
				end
			end
			if label then
				insert(data.inflections, {label = label})
			end
		end
	end
}

pos_functions["cardinal invariable"] = {
	params = {},
	func = function(args, data)
		data.pos_category = "numerals"
		insert(data.categories, langname .. " cardinal numbers")
		insert(data.categories, langname .. " indeclinable numerals")
		insert(data.inflections, {label = glossary_link("invariable")})
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
