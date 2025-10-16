--[=[
	This module implements the headword templates {{ru-noun}}, {{ru-adj}}, {{ru-adv}}, {{ru-noun+}}, etc. The main entry
	point is show(), which is meant to be called from one of the above templates. However, {{ru-noun+}} uses the entry
	point noun_plus(). When calling show(), the first parameter of the #invoke call is the part of speech. Other
	parameters are taken from the parent template call.

	The implementations for different types of headwords (different parts of speech) are set in pos_functions[POS] for a
	given POS (part of speech).
]=]--

local export = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local lang = require("Module:languages").getByCode("ru")
local langname = lang:getCanonicalName()

local com = require("Module:ru-common")
local m_links = require("Module:links")
local m_table_tools = require("Module:table tools")

local require_when_needed = require("Module:utilities/require when needed")

local en_utilities_module = "Module:en-utilities"
local json_module = "Module:JSON"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local m_string_utilities = require_when_needed(string_utilities_module)
local m_table = require_when_needed(table_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local shallowCopy = require_when_needed(table_module, "shallowCopy")
local insertIfNot = require_when_needed(table_module, "insertIfNot")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}
local list_comp = {list = "comp", disallow_holes = true}
local list_sup = {list = "sup", disallow_holes = true}

local u = m_string_utilities.char
local rfind = m_string_utilities.find
local rsubn = m_string_utilities.gsub
local rmatch = m_string_utilities.match
local rsplit = m_string_utilities.split

local concat = table.concat
local insert = table.insert
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local IRREGMARKER = "△"
local HYPMARKER = "⟐"
-- Forward references
local do_noun
local AC = u(0x0301) -- acute =  ́

local pos_functions = {}

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
end

local function track(page)
	require("Module:debug/track")("ru-headword/" .. page)
	return true
end

-- Clone args while also assigning nil to empty strings.
local function clone_args(in_args)
	local args = {}
	for pname, param in pairs(in_args) do
		if param == "" then args[pname] = nil
		else args[pname] = param
		end
	end
	return args
end

local function make_qualifier_text(text)
	return require("Module:qualifier").format_qualifier(text)
end

-- Split a list of "RUSSIAN" or "RUSSIAN//TRANSLIT" strings into a list of {RUSSIAN, TRANSLIT} objects.
local function split_list_into_russian_tr(list)
	local splitlist = {}
	for _, item in ipairs(list) do
		insert(splitlist, com.split_russian_tr(item, "dopair"))
	end
	return splitlist
end

local function check_if_head_accent_needed(val_no_links, data)
	if com.needs_accents(val_no_links) then
		if not data.unknown_stress and not data.noacccat then
			error("Stress must be supplied using an acute accent: '" .. val_no_links .. "' (use unknown_stress=1 if stress is unknown and noaccat=1 if a multisyllable word really has no stress, as in ''до́ смерти'')")
		end
		local pos = require(en_utilities_module).singularize(data.pos_category)
		insert(data.categories, "Requests for accents in " .. langname .. " " .. pos .. " entries")
	end
	if com.is_multi_stressed(val_no_links) then
		error("Multi-stressed form '" .. val_no_links .. "' not allowed")
	end
end

local function check_if_accent_needed(val, data)
	local val_no_links = m_remove_links(val)
	if com.needs_accents(val_no_links) then
		local pos = require(en_utilities_module).singularize(data.pos_category)
		insert(data.categories, "Requests for accents in " .. langname .. " " .. pos .. " entries")
	end
	if com.is_multi_stressed(val_no_links) then
		error("Multi-stressed form '" .. val_no_links .. "' not allowed")
	end
end

-- Convert {RUSSIAN, TR} in `form` into an "inflection object" of the form needed for one of the inflection parts in
-- `data` is used to fetch the values of `lemma` and `lemma_translit` in the accelerator object and to add a "Requests
-- for accents" category if the form is missing accents. (FIXME: Consider throwing an error instead.) `pos` is the
-- part of speech of the lemma and is used for naming the "Requests for accents" category. `accel_form` goes in the
-- accelerator object; if nil, no accelerator object is specified. `accel_pos` is the part of speech of the inflection,
-- if different from the lemma, and goes in the accelerator object. `target` is used to populate the `target` and
-- `translit` fields in the accelerator object and is the form used to check for missing accents; in both cases it
-- defaults to `form` if omitted.
local function russian_tr_to_inflection_obj(data, form, pos, accel_form, accel_pos, target)
	local ru, tr
	if type(form) == "string" then
		ru, tr = com.split_russian_tr(form)
	else
		ru, tr = unpack(form)
	end
	local sawhyp_ru, sawhyp_tr
	ru, sawhyp_ru = rsubb(ru, HYPMARKER, "")
	if tr then
		tr, sawhyp_tr = rsubb(tr, HYPMARKER, "")
	end
	local accel
	local target_ru, target_tr
	if target then
		target_ru, target_tr = unpack(target)
	else
		target_ru, target_tr = ru, tr
	end
	if accel_form then
		-- FIXME, consider removing redundant translit
		-- Stuff in data.heads and data.translits gets destructively modified by [[Module:headword]] (YUCK), so clone it.
		accel = {form = accel_form, lemma = m_table.deepCopy(data.heads),
			lemma_translit = m_table.deepCopy(data.translits), pos = accel_pos, target = target_ru, translit = target_tr
		}
	end
	local obj = {term=ru, face=(sawhyp_ru or sawhyp_tr) and "hypothetical" or nil, accel=accel}
	--Uncomment to see the manual translit for each inflected part.
	--local obj = {term=ru, translit=tr, face=(sawhyp_ru or sawhyp_tr) and "hypothetical" or nil, accel=accel}
	if com.needs_accents(m_links.remove_links(target_ru)) then
		insert(data.categories, "Requests for accents in Russian " .. pos .. " entries")
	end
	return obj
end

-- Parse the forms of an inflection. The raw arguments are specified in `forms`, a list of forms which are parsed for
-- inline modifiers. Multiple comma-separated values are allowed.
local function parse_inflection_forms(data, forms, field, is_head)
	return m_headword_utilities.parse_term_list_with_modifiers {
		forms = forms,
		paramname = field,
		splitchar = ",",
		is_head = is_head,
		include_mods = {"tr"},
		frob = function(term)
			if is_head then
				local head_no_links = m_links.remove_links(term)
				check_if_head_accent_needed(head_no_links, data)
				-- Catch errors in arguments where headword doesn't match page title; for the moment, do only with
				-- tracking.
				local head_noaccent = com.remove_accents(head_no_links)
				if head_noaccent ~= data.pagename then
					track("bad-headword")
					--error("Headword " .. term .. " doesn't match pagename " .. data.pagename)
				end
			else
				check_if_accent_needed(term, data)
			end

			return term
		end,
	}
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(data, args, field, is_head)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	return parse_inflection_forms(data, args[argfield], field, is_head)
end

-- Add a full inflection (e.g. genitive singular of nouns, abstract noun of adjectives) to `data.inflections`. `label`
-- is the label of the inflection (e.g. "abstract noun"), which can have <<...>> glossary references. `terms` is a list
-- of term objects. `accel_form` is the accelerator form (e.g. "gen|s" for genitive singular) of the inflection, or nil
-- to add no accelerator. `accel_pos` is the part of speech of the inflection, if different from the lemma.
--
-- This is a wrapper around insert_inflection() in [[Module:headword utilities]], but handles hypothetical markers in
-- the term (which are converted into the `hypothetical` face) as well as the fact that the accelerator spec may differ
-- from term to term if we need to specify a target (i.e. the value of |head= used in {{head}} or similar) that's
-- different from the term itself. This happens in particular in comparative forms, where the term reads e.g.
-- "([[покраснее|по]])[[краснее|красне́е]]" but we want the target to be just красне́е.
local function insert_inflection(data, terms, label, accel_form, accel_pos)
	if not terms[1] then
		return
	end
	for _, termobj in ipairs(terms) do
		local term = termobj.term
		local tr = termobj.tr
		local sawhyp_term, sawhyp_tr
		term, sawhyp_term = rsubb(term, HYPMARKER, "")
		if tr then
			tr, sawhyp_tr = rsubb(tr, HYPMARKER, "")
		end
		local accel
		local target_term = termobj.target_term or term
		-- If the target was given without a translit, don't fall back to the term translit because the target itself
		-- may be different from the term.
		local target_tr = termobj.target_tr or not termobj.target_term and tr or nil
		if accel_form then
			local lemmas = {}
			local lemma_translits = {}
			for i, headobj in ipairs(data.heads) do
				lemmas[i] = headobj.term
				lemma_translits[i] = headobj.tr
			end
			accel = {
				form = accel_form, lemma = lemmas, lemma_translit = lemma_translits, pos = accel_pos,
				target = target_term, translit = target_tr
			}
		end
		termobj.term = term
		-- Currently we don't display translits for inflections, so null out any manual translit. If we want to change
		-- this, we need to set enable_auto_translit on the inflection list or individual inflection term.
		termobj.tr = nil
		termobj.face = (sawhyp_term or sawhyp_tr) and "hypothetical" or nil
		termobj.accel = accel
		if com.needs_accents(m_links.remove_links(target_term)) then
			local pos = require(en_utilities_module).singularize(data.pos_category)
			insert(data.categories, "Requests for accents in " .. langname .. " " .. pos .. " entries")
		end
	end

	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
	}
end

-- Insert a fixed label `label` into the inflections for `data`. If `originating_term` is supplied, copy the qualifiers,
-- labels and references from it into the fixed label.
local function insert_fixed_inflection(data, label, originating_term)
	m_headword_utilities.insert_fixed_inflection {
		headdata = data,
		originating_term = originating_term,
		label = label,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form (or nil), and `accel_pos` if specified overrides the accelerator part of speech. Note that
-- [[Module:headword utilities]] provides a parse_and_insert_inflection() that is usually sufficient, but in our case
-- we do a bunch of additional processing when inserting inflections, so we do the parsing and inserting separately
-- using functions defined above.
local function parse_and_insert_inflection(data, args, field, label, accel_form, accel_pos)
	local terms = parse_inflection(data, args, field)
	insert_inflection(data, terms, label, accel_form, accel_pos)
end

local function get_split_decomposed_heads(data)
	if not data.heads then
		data.split_decomposed_heads = com.split_translit_of_duplicate_termobjs_and_decompose(data.heads)
	end
	return data.split_decomposed_heads
end

-- Zip the lemma heads and corresponding translits into a list of {RUSSIAN, TRANSLIT} objects. In the process, split
-- any combined translits (e.g. "azerbajdžánskij, azɛrbajdžánskij" with corresponding head "азербайджа́нский") into two
-- separate objects.
local function zip_head_and_translit(data)
	return com.split_translit_of_duplicate_forms(com.zip_forms(data.heads, data.translits))
end

local function add_common_all_pos_params(params)
	params["noacccat"] = boolean_param -- don't add missing-accent tracking category
	params["notrcat"] = boolean_param -- don't add 'irregular pronunciations' tracking category
	params["unknown_stress"] = boolean_param -- stress position unknown
	params["pagename"] = true
	params["id"] = true
	return params
end

-- The main entry point.
function export.show(frame)
	local iparams = {
		[1] = {required = true, desc = "part of speech"},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local poscat = iargs[1]

	local params = add_common_all_pos_params {
		[1] = {list = "head", disallow_holes = true},
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
		noacccat = args.noacccat,
	}

	if not pos_functions[poscat] or not pos_functions[poscat].no_parse_heads or
		not pos_functions[poscat].no_parse_heads(args) then
		data.heads = parse_inflection(data, args, {1, "head"}, "is_head") 
		if not data.heads[1] then
			data.heads = {{term = pagename}}
		end
	end

	for _, headobj in ipairs(heads) do
		local tr = headobj.tr
		if tr then
			tr = com.decompose(tr)
			local tr_gen = com.translit_no_links(headobj.term)
			if tr == tr_gen then
				track("redundant-translit")
			elseif not args.notrcat then
				insert(data.categories, langname .. " terms with irregular pronunciations")
			end
		end
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end

	if args.unknown_stress then
		track("unknown-stress")
		if not pos_functions[poscat] or not pos_functions[poscat].no_insert_unknown_stress_label or
			not pos_functions[poscat].no_insert_unknown_stress_label(args) then
			insert(data.inflections, {label = "unknown stress"})
		end
	end

	return require(headword_module).full_headword(data)
end

-- Common params shared by {{ru-noun}} and {{ru-noun+}}.
local function add_common_noun_params(params)
	params["unknown_decl"] = boolean_param -- declension unknown
	params["unknown_pattern"] = boolean_param -- stress pattern (a, b, b', ...) unknown
	params["unknown_gender"] = boolean_param -- gender unknown
	params["unknown_animacy"] = boolean_param -- animacy unknown
	params["f"] = list_param -- feminine equivalent(s)
	params["m"] = list_param -- masculine equivalent(s)
	params["adj"] = list_param -- relational adjective(s)
	params["poss"] = list_param -- possessive adjective(s)
	params["dim"] = list_param -- diminutive(s)
	params["aug"] = list_param -- augmentative(s)
	params["pej"] = list_param -- pejorative(s)
	params["dem"] = list_param -- demonym(s)
	params["fdem"] = list_param -- female demonym(s)
	return params
end

-- Implementation of {{ru-noun+}}. We should redo this implementation along the lines of {{uk-ndecl}}. For example,
-- instead of existing {{ru-noun-table|[[дви́гатель]]|m|_|[[внутренний|вну́треннего]]|+$|_|[[сгорание|сгора́ния]]|$}}, it
-- should look more like {{ru-ndecl|дви́гатель<M> [[внутренний|вну́треннего]] [[сгорание|сгора́ния]]}}.
local function noun_plus(frame)
	local iparams = {
		[1] = {required = true, desc = "part of speech"},
		["old"] = boolean_param,
		["ndef"] = {},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local poscat = iargs[1]

	local params = add_common_noun_params(add_common_all_pos_params {
		["g"] = {list = true, disallow_holes = true, type = "genders", flatten = true}, -- genders
		["notes"] = list_param, -- "footnotes" displayed after headword
	})
	local parargs = frame:getParent().args
	local headword_args, args = require("Module:parameters").process(parargs, params, "return unknown")
	args = clone_args(args)
	-- default value of n=, used in ru-proper noun+ where ndef=sg is set
	args.ndef = args.ndef or iargs.ndef

	local m_noun = require("Module:ru-noun")
	args = m_noun.do_generate_forms(args, iargs.old)

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
		noacccat = args.noacccat,
	}

	-- do explicit genders using g=, g2=, etc.
	data.genders = headword_args.g
	-- if none, do inferred or explicit genders taken from declension;
	-- clone because will get destructively modified by do_noun() (FIXME: is this necessary?)
	if not data.genders[1] then
		data.genders = mw.clone(args.genders)
	end

	local saw_note = false

	-- Given a list of {RU, TR} pairs, where TR may be nil, separate off the footnote symbols from RU and TR; link the
	-- remainder if it's not already linked; remove monosyllabic accents (but not from multiword expressions); and
	-- return the result in termobj format, i.e. {term = RU, tr = TR}.
	local function convert_paired_terms_to_termobjs(paired_list, ishead)
		if not paired_list or not paired_list[1] then
			return {{term = "-"}}
		end
		local termobjs = {}
		for _, x in ipairs(paired_list) do
			local ru, tr = x[1], x[2]
			-- separate_notes() just returns the note, but get_notes() adds
			-- <sup>...</sup>. We want the former for checking whether the
			-- note is nonempty after removing IRREGMARKER (if we use the
			-- latter we'll get <sup></sup> in the case of just IRREGMARKER),
			-- but the latter when generating the inflectional form.
			if not ishead and (rfind(ru, "[%[|%]]") or tr and rfind(tr, "[%[|%]]")) then
				track("form-with-link")
			end
			local ruentry, runotes = m_table_tools.separate_notes(ru)
			local sawhyp
			runotes = rsub(runotes, IRREGMARKER, "") -- remove note of irregularity
			runotes, sawhyp = rsubb(runotes, HYPMARKER, "")
			if runotes ~= "" then
				saw_note = true
			end
			runotes = m_table_tools.superscript_notes(runotes)
			local trentry, trnotes
			if tr then
				trentry, trnotes = m_table_tools.separate_notes(tr)
				trnotes = rsub(trnotes, IRREGMARKER, "") -- remove note of irregularity
				trnotes = m_table_tools.superscript_notes(trnotes)
			end
			ruentry, trentry = com.remove_monosyllabic_accents(ruentry, trentry)
			if sawhyp then
				insert(termobjs,
					{term = ruentry .. runotes .. HYPMARKER, tr = trentry and trentry .. trnotes .. HYPMARKER or nil}
				)
			elseif ishead then
				insert(termobjs,
					{term = ruentry .. runotes, tr = trentry and trentry .. trnotes or nil})
			else
				local ruspan, trspan
				if ruentry == "-" then
					ruspan = "-"
				elseif rfind(ruentry, "[%[|%]]") then
					-- don't add links around a form that's already linked
					ruspan = ruentry .. runotes
				else
					ruspan = "[[" .. ruentry .. "]]" .. runotes
				end
				if trentry then
					trspan = trentry .. trnotes
				end
				insert(termobjs, {term = ruspan, tr = trspan})
			end
		end
		return com.combine_translit_of_duplicate_termobjs(termobjs)
	end

	local argsn = args.n or args.ndef
	local heads, genitives, plurals, genpls
	if argsn == "p" then
		heads = convert_paired_terms_to_termobjs(args.nom_pl_linked, "ishead")
		genitives = convert_paired_terms_to_termobjs(args.gen_pl)
		plurals = {{term = "-"}}
		genpls = {{term = "-"}}
	else
		heads = convert_paired_terms_to_termobjs(args.nom_sg_linked, "ishead")
		genitives = convert_paired_terms_to_termobjs(args.gen_sg)
		plurals = argsn == "s" and {{term = "-"}} or convert_paired_terms_to_termobjs(args.nom_pl)
		genpls = argsn == "s" and {{term = "-"}} or convert_paired_terms_to_termobjs(args.gen_pl)
	end

	data.heads = heads
	if com.any_termobjs_have_translit(data.heads) and not args.notrcat then
		insert(data.categories, langname .. " terms with irregular pronunciations")
	end

	do_noun(data, headword_args, argsn == "s", genitives, plurals, genpls, poscat)

	local notes = headword_args.notes
	local notes_segments = {}
	if saw_note then
		for _, note in ipairs(notes) do
			insert(notes_segments, " " .. make_qualifier_text(note))
		end
	end
	local notes_text = concat(notes_segments, "")

	return require(headword_module).full_headword(data) .. notes_text
end

-- Implementation of {{ru-noun}} and {{ru-proper noun}}.
local function get_noun_pos(pos)
	return {
		params = add_common_noun_params({
			[2] = {list = "g", disallow_holes = true, required = true, default = "?", type = "genders",
				flatten = true}, -- genders
			[3] = {list = "gen", disallow_holes = true}, -- genitive singulars, or - for indeclinable
			[4] = {list = "pl", disallow_holes = true}, -- nominative plurals
			[5] = {list = "genpl", disallow_holes = true}, -- genitive plurals
			["altyo"] = boolean_param, -- called from {{ru-noun-alt-ё}} or variants
			["manual"] = boolean_param, -- allow manual specification of principal parts
		}),
		func = function(args, data)
			data.genders = args[2]
			local genitives = parse_inflection(data, args, {3, "gen"})
			local plurals = parse_inflection(data, args, {4, "pl"})
			local genpls = parse_inflection(data, args, {5, "genpl"})
			if not args.altyo and not args.manual and (not genitives[1] or genitives[1].term ~= "-") and
				mw.title.getCurrentTitle().nsText == "" and
				not args.unknown_decl and not args.unknown_stress and
				not args.unknown_pattern and not args.unknown_gender and
				not args.unknown_animacy then
				error("[[Template:ru-noun]] can now only be used with indeclinable and manually-declined nouns; use [[Template:ru-noun+]] instead")
			end
			do_noun(data, args, pos == "proper nouns", genitives, plurals, genpls, pos)
		end,
		no_insert_unknown_stress_label = function(args)
			return true -- we do it ourselves
		end,
	}
end

pos_functions["proper nouns"] = get_noun_pos("proper nouns")

pos_functions["pronouns"] = get_noun_pos("pronouns")

-- Display additional inflection information for a noun.
pos_functions["nouns"] = get_noun_pos("nouns")

-- Guts of {{ru-noun}} and {{ru-noun+}}.
do_noun = function(data, args, no_plural, genitives, plurals, genpls, pos)
	local recognized_genders = {
		"", -- not allowed when singular; this is needed because some invariant plural-only words have no gender to speak of
		"m",
		"f",
		"n",
		"mf",
		"mfbysense",
	}
	local recognized_animacies = {
		"",
		"?",
		"an",
		"in",
	}
	local recognized_numbers = {
		"",
		"p",
	}

	local function insert_if_not_blank(seq, part)
		if part ~= "" then
			insert(seq, part)
		end
	end

	local singular_genders = {} -- a set
	local plural_genders = {} -- a set

	-- Generate the allowed gender/number/animacy specs.
	for _, number in ipairs(recognized_numbers) do
		for _, gender in ipairs(recognized_genders) do
			for _, animacy in ipairs(recognized_animacies) do
				local set = number == "" and singular_genders or plural_genders
				if gender ~= "" or number == "p" then -- disallow blank gender unless plural
					local gender_number = {}
					insert_if_not_blank(gender_number, gender)
					insert_if_not_blank(gender_number, animacy)
					insert_if_not_blank(gender_number, number)
					local spec = concat(gender_number, "-")
					set[spec] = true
				end
			end
		end
	end

	for _, gspec in ipairs(data.genders) do
		local g = gspec.spec
		if g == "m" then
			g = "m-?"
		elseif g == "m-p" then
			g = "m-?-p"
		elseif g == "f" and plurals[1] ~= "-" and not no_plural then
			g = "f-?"
		elseif g == "f-p" then
			g = "f-?-p"
		elseif g == "p" then
			g = "?-p"
		end

		if not singular_genders[g] and not plural_genders[g] and g ~= "?" and g ~= "?-in" and g ~= "?-an" then
			error("Unrecognized gender: " .. g)
		end

		gspec.spec = g

		-- Categorize by number
		if plural_genders[g] then
			if g == "?-p" or g == "an-p" or g == "in-p" then
				insert(data.categories, langname .. " pluralia tantum with incomplete gender")
			end
		end
	end

	-- Add the genitive forms
	if genitives[1] and genitives[1].term == "-" then
		insert(data.inflections, {label = glossary_link("indeclinable")})
		insert(data.categories, langname .. " indeclinable nouns")
	else
		insert_inflection(data, genitives, "genitive")
	end

	local plural_only = not not plural_genders[data.genders[1].spec]

	-- Add the plural forms.
	if genitives[1] and genitives[1].term == "-" then
		if plurals[1] or genitive_plurals[1] then
			error("Can't specify nominative or genitive plurals of a plural-only term")
		end
	elseif plural_genders[data.genders[1].spec] then
		insert(data.inflections, {label = glossary_link("plural only")})
	elseif plurals[1] and plurals[1].term == "-" then
		if pos ~= "proper nouns" then
			insert(data.inflections, {label = glossary_link("uncountable")})
			insert(data.categories, langname .. " uncountable nouns")
		end
	else
		insert_inflection(data, plurals, "nominative plural")
		insert_inflection(data, genitive_plurals, "genitive plural")
	end

	-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments
	-- come from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are
	-- given; <<..>> in the label is linked to the glossary). `accel_form` is the accelerator form, or nil.
	local function handle_infl(field, label, accel_form)
		parse_and_insert_inflection(data, args, field, label, accel_form)
	end

	-- Add the masculine forms; intentionally no accelerator as the masculine forms are lemmas and need manual handling
	handle_infl("m", "male equivalent")
	-- Add the feminine forms
	handle_infl("f", "female equivalent", "f")
	-- Add the relational adjective forms; intentionally no accelerator, need manual handling
	handle_infl("adj", "<<relational adjective>>")
	-- Add the possessive adjective forms; intentionally no accelerator, need manual handling
	handle_infl("poss", "<<possessive adjective>>")
	-- Add the diminutive forms
	handle_infl("dim", "<<diminutive>>", "diminutive")
	-- Add the augmentative forms
	handle_infl("aug", "<<augmentative>>", "augmentative")
	-- Add the pejorative forms
	handle_infl("pej", "<<pejorative>>", "pejorative")
	-- Add the demonyms
	handle_infl("dem", "<<demonym>>", "demonym")
	-- Add the female demonyms
	handle_infl("fdem", "female <<demonym>>", "female demonym")

	if args.unknown_decl then
		track("unknown-decl")
		insert(data.inflections, {label = "unknown declension"})
	end
	if args.unknown_stress then
		track("unknown-stress")
		insert(data.inflections, {label = "unknown stress"})
	end
	if args.unknown_pattern then
		track("unknown-pattern")
		insert(data.inflections, {label = "unknown accent pattern"})
	end
	if args.unknown_gender then
		track("unknown-gender")
		insert(data.inflections, {label = "unknown gender"})
	end
	if args.unknown_animacy then
		track("unknown-animacy")
		insert(data.inflections, {label = "unknown animacy"})
	end
end

local function generate_informal_comp(compobj)
	local ru, tr = compobj.term, compobj.tr
	if rfind(ru, "е́?е$") then
		ru, tr = com.strip_ending(ru, tr, "е") -- Cyrillic е
		compobj = shallowCopy(compobj)
		compobj.term, compobj.tr = com.concat_russian_tr(ru, tr, "й", nil)
		return compobj
	else
		return nil
	end
end

local function convert_to_po_variant(compobj)
	local ru, tr = compobj.term, compobj.tr
	if rfind(ru, "е$") or rfind(ru, "е́?й$") then
		ru = "[[по" .. ru .. "|(по)]][[" .. ru .. "]]"
		tr = tr and "(po)" .. tr or nil
		compobj.term, compobj.tr = ru, tr
	end
end

local allowed_endings = {
	"ый",
	"ий",
	"о́й",
	--old
	"ій",
	-- last two for adverbs
	"о",
	"о́",
}

local velar_to_translit = {
	["к"] = "k",
	["г"] = "g",
	["х"] = "x"
}

local velar_to_palatal = {
	["к"] = "ч",
	["г"] = "ж",
	["х"] = "ш",
	["k"] = "č",
	["g"] = "ž",
	["x"] = "š"
}

-- Generate the comparative(s) given the positive(s). `positives` is a list of term objects, with the translit already
-- split and decomposed. `compspecobj` is the term object containing the comparative spec (either + or a spec giving an
-- adjectival accent pattern, such as +c'). If + is given, the default is +a unless the positive is ending-stressed, in
-- which case the default is +b. Return value is a list of term objects.
local function generate_comparative(positives, compspecobj)
	local comps = {}
	local compspec = compspecobj.term
	if compspecobj.tr then
		error("Can't specify manual translit with a '+...' comparative spec")
	end
	if not rfind(compspec, "^%+") then
		error("Compspec '" .. compspec .. "' must begin with + in this function")
	end
	if compspec ~= "+" and not rfind(compspec, "^%+[abc]'*$") then
		error("Compspec '" .. compspec .. "' has an illegal format, should be e.g. + or +c''")
	end
	compspec = rsub(compspec, "^%+", "")
	for _, positive in ipairs(positives) do
		local ru, tr = positive.term, positive.tr
		ru = m_links.remove_links(ru)
		local removed_ending = false
		for _, allowed_ending in ipairs(allowed_endings) do
			if rfind(ru, allowed_ending .. "$") then
				if allowed_ending == "о́й" or allowed_ending == "о́" then
					if compspec == "a" then
						error("Short stress pattern a not allowed with ending-stressed adjectives/adverbs")
					elseif compspec == "" then
						compspec = "b"
					end
				end
				ru, tr = com.strip_ending(ru, tr, allowed_ending)
				removed_ending = true
				break
			end
		end
		if not removed_ending then
			error("Russian '" .. ru .. "' doesn't end with expected ending")
		end
		local comp, comptr
		if rfind(ru, "[кгх]$") then
			local stemru, lastruchar = rmatch(ru, "^(.*)(.)$")
			local stemtr, lasttrchar
			if tr then
				stemtr, lasttrchar = rmatch(tr, "^(.*)(.)$")
				if velar_to_translit[lastruchar] ~= lasttrchar then
					error("Translit '" .. tr .. "' doesn't end with transliterated equivalent of last char '" ..
						lastruchar .. "' of Russian '" .. ru .. "'")
				end
			end
			comp, comptr = com.make_ending_stressed(stemru, stemtr)
			comp = comp .. velar_to_palatal[lastruchar] .. "е" -- Cyrillic е
			if comptr then
				comptr = comptr .. velar_to_palatal[lasttrchar] .. "e" -- Latin e
			end
		elseif compspec == "" or compspec == "a" then
			comp = ru .. "ее" -- Cyrillic ее
			if comptr then
				comptr = tr .. "ee" -- Latin ee
			end
		else -- end-stressed comparative, including pattern a'
			comp, comptr = com.make_unstressed_once(ru, tr)
			comp = comp .. "е́е" -- Cyrillic е́е
			if comptr then
				comptr = comptr .. "e" .. AC .. "e" -- Latin decomposed ée
			end
		end
		local compobj = shallowCopy(positive)
		compobj.term = comp
		compobj.tr = comptr
		m_headword_utilities.combine_termobj_qualifiers_labels(compobj, compspecobj)
		insert(comps, compobj)
	end
	return comps
end

-- Meant to be called from a bot
function export.generate_comparative(frame)
	local iparams = {
		[1] = {required = true, desc = "comparative"},
		[2] = {default = "+"},
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local comps = iargs[1]
	local compspec = iargs[2]
	comps = rsplit(comps, ",")
	for i, comp in ipairs(comps) do
		local ru, tr = com.split_russian_tr(comp)
		comps[i] = {term = ru, tr = tr}
	end
	comps = generate_comparative(comps, {term = compspec})
	comps = com.combine_translit_of_duplicate_termobjs_and_recompose(comps)
	return require(json_module).toJSON(comps)
end

-- Handle comparative inflections. If an explicit form is given such as коро́че or красне́е, we add it in a "hacked"
-- format that notes that e.g. покоро́че or покрасне́е is a possible variant. We also generate an informal form in -ей
-- if possible, e.g. красне́й, with по-hacking applied (but no such variant is possible for коро́че). We also handle
-- autogenerating comparatives when specified as + or +b, +c'', etc. (All specifications with an accent pattern are
-- equivalent other than +a.) Finally, we allow and handle periphrastic comparatives noted using "peri".
local function handle_comparatives(data, args)
	local noinf = args.noinf
	local comps = parse_inflection(data, args, {2, "comp"})
	comps = com.split_translit_of_duplicate_termobjs_and_decompose(comps)
	if comps[1] and comps[1].term == "-" then
		local nocomp = table.remove(comps, 1)
		if comps[1] then
			insert_fixed_inflection(data, "not generally <<comparable>>", nocomp)
		else
			insert_fixed_inflection(data, "no <<comparative>>", nocomp)
		end
		track("nocomp")
	end
	if comps[1] then
		local comp_parts = {}

		local function insert_comp(compobj)
			local informal
			if not noinf then
				informal = generate_informal_comp(compobj)
				if informal then
					convert_to_po_variant(informal)
				end
			end
			convert_to_po_variant(compobj)
			m_headword_utilities.insert_termobj_combining_duplicates(comp_parts, compobj)
			if informal then
				m_headword_utilities.insert_termobj_combining_duplicates(comp_parts, informal)
			end
		end

		for _, compobj in ipairs(comps) do
			local term = compobj.term
			if term == "peri" then
				if compobj.tr then
					error("Can't specify manual translit with 'peri' comparative spec")
				end
				for _, positive in ipairs(get_split_decomposed_heads(data)) do
					local pericomp = shallowCopy(positive)
					pericomp.term, pericomp.tr = com.concat_russian_tr("[[бо́лее]] ", nil, pericomp.term, pericomp.tr)
					m_headword_utilities.combine_termobj_qualifiers_labels(pericomp, compobj)
					m_headword_utilities.insert_termobj_combining_duplicates(comp_parts, pericomp)
				end
				track("pericomp")
			elseif rfind(term, "^+") then
				local autocomps = generate_comparative(get_split_decomposed_heads(data), compobj)
				for _, autocomp in ipairs(autocomps) do
					insert_comp(autocomp)
				end
			else
				insert_comp(compobj)
			end
		end

		comp_parts = com.combine_translit_of_duplicate_termobjs_and_recompose(comp_parts)
		for _, compobj in ipairs(compobjs) do
			local ru, tr = compobj.term, compobj.tr
			-- WARNING: This has intimate knowledge of how convert_to_po_variant() works. To avoid this, we could
			-- maintain the un-po-hacked target in each form in comp_parts, but then we'd have to modify
			-- com.combine_translit_of_duplicate_forms() to preserve the extra target info when combining
			-- duplicate forms, or use a map from hacked Russian form to target.
			local un_po_hacked_ru = m_links.remove_links(rsub(ru, "^%[%[.-%]%]", ""))
			local un_po_hacked_tr = tr and rsub(tr, rsub(tr, "^%(po%)", ""), ", %(po%)", ", ") or nil
			compobj.target_term = un_po_hacked_ru
			compobj.target_tr = un_po_hacked_tr
		end
		insert_inflection(data, comp_parts, "<<comparative>>", "comparative")
	end
end

-- Display additional inflection information for an adjective
pos_functions["adjectives"] = {
	 params = {
		["indecl"] = boolean_param, --indeclinable
		["noinf"] = boolean_param, --suppress informal comparatives
		[2] = list_comp, --comparative(s)
		[3] = list_sup, --superlative(s)
		["adv"] = list_param, --corresponding adverb(s)
		["absn"] = list_param, --corresponding abstract noun(s)
		["dim"] = list_param, --corresponding diminutive(s)
		["aug"] = list_param, --corresponding augmentative(s)
		["pej"] = list_param, --corresponding pejorative(s)
	},
	func = function(args, data)

		if args.indecl then
			insert(data.inflections, {label = "indeclinable"})
			insert(data.categories, langname .. " indeclinable adjectives")
		end

		handle_comparatives(data, args)

		local function parse_and_insert_adj_inflection(field, label, accel_form, accel_pos)
			parse_and_insert_inflection(data, args, field, label, accel_form, accel_pos)
		end

		-- Add the superlatives
		if #args[3] > 0 then
			local normalized_sups = {}
			for _, sup in ipairs(args[3]) do
				if sup == "peri" then
					local lemmas = zip_head_and_translit(data)
					for _, lemma in ipairs(lemmas) do
						local ru, tr = unpack(lemma)
						insertIfNot(normalized_sups, com.concat_russian_tr("[[са́мый]] ", nil, ru, tr, "dopair"))
					end
				else
					insertIfNot(normalized_sups, com.split_russian_tr(sup, "dopair"))
				end
			end
			add_adj_forms("superlative", normalized_sups, "superlative")
		end

		-- Add the adverbs
		parse_and_insert_adj_inflection("adv", "adverb")
		-- Add the abstract nouns
		local absn_objs = parse_inflection(data, args, "absn")
		local saw_plus = false
		for _, absnobj in ipairs(absn_objs) do
			if absnobj.term == "+" then
				saw_plus = true
				break
			end
		end
		if saw_plus then
			local normalized_absn_objs = {}
			absn_objs = com.split_translit_of_duplicate_termobjs_and_decompose(absn_objs) 
			for _, absnobj in ipairs(absn_objs) do
				if absnobj.term == "+" then
					if absnobj.tr then
						error("Can't specify manual translit with '+' default abstract noun spec")
					end
					local lemmas = get_split_decomposed_heads(data)
					for _, lemma in ipairs(lemmas) do
						local ru, tr = lemma.term, lemma.tr
						if rfind(ru, "о́?й$") then
							error("Can't form default abstract noun of ending-stressed adjective " .. ru)
						end
						if rfind(ru, "ий$") then
							ru, tr = com.strip_ending(ru, tr, "ий")
						elseif rfind(ru, "ій$") then
							ru, tr = com.strip_ending(ru, tr, "ій")
						else
							ru, tr = com.strip_ending(ru, tr, "ый")
						end
						ru, tr = com.concat_russian_tr(ru, tr, "ость", nil)
						local lemma_absn = shallowCopy(lemma)
						lemma_absn.term, lemma_absn.tr = ru, tr
						m_headword_utilities.combine_termobj_qualifiers_labels(lemma_absn, absnobj)
						m_headword_utilities.insert_termobj_combining_duplicates(normalized_absn_objs, lemma_absn)
					end
				else
					m_headword_utilities.insert_termobj_combining_duplicates(normalized_absn_objs, absnobj)
				end
			end
			normalized_absn_objs = com.combine_translit_of_duplicate_termobjs_and_recompose(normalized_absn_objs)
			insert_inflection(data, normalized_absn_objs, "abstract noun", "abstract noun", "noun")
		end
		-- Add the diminutives
		parse_and_insert_adj_inflection("dim", "<<diminutive>>", "diminutive")
		-- Add the augmentatives
		parse_and_insert_adj_inflection("aug", "<<augmentative>>", "augmentative")
		-- Add the pejoratives
		parse_and_insert_adj_inflection("pej", "<<pejorative>>", "pejorative")
	end
}

-- Display additional inflection information for an adverb
pos_functions["adverbs"] = {
	 params = {
		["noinf"] = boolean_param, --suppress informal comparatives
		[2] = list_comp, --comparative(s)
		-- ["3"] = list_sup, --FIXME: why no superlatives?
		["dim"] = list_param, --corresponding diminutive(s)
		["aug"] = list_param, --corresponding augmentative(s)
		["pej"] = list_param, --corresponding pejorative(s)
	},
	func = function(args, data)
		local comps = args[2]

		handle_comparatives(data, args)

		local function parse_and_insert_adv_inflection(field, label, accel_form)
			parse_and_insert_inflection(data, args, field, label, accel_form)
		end

		-- Add the diminutives
		parse_and_insert_adv_inflection("dim", "<<diminutive>>", "diminutive")
		-- Add the augmentatives
		parse_and_insert_adv_inflection("aug", "<<augmentative>>", "augmentative")
		-- Add the pejoratives
		parse_and_insert_adv_inflection("pej", "<<pejorative>>", "pejorative")
	end
}

-- Display additional inflection information for a verb and verbal combining form
local function get_verb_pos(pos)
	return {
		params = {
			[2] = {required = true, default = "?"}, --aspect
			["impf"] = list_param, -- imperfective(s),
			["pf"] = list_param, -- perfective(s),
			["vn"] = list_param, -- verbal noun(s),
		},
		func = function(args, data)
			local cform = pos == "verbal combining forms"
			if cform then
				insert(data.categories, "Russian verbs")
			end
			-- Aspect
			local aspect = args[2]
			if aspect == "both" then
				insert(data.genders, "biasp")
			elseif aspect == "pf" or aspect == "impf" or aspect == "biasp" or aspect == "?" then
				insert(data.genders, aspect)
			else
				error("Invalid Russian verb aspect '" .. aspect .. "', should be 'pf', 'impf', 'both', 'biasp' or '?'")
			end

			local function add_verb_forms(label, forms, accel_form, accel_pos)
				add_inflection(data, label, forms, "verb", accel_form, accel_pos)
			end

			-- Add the imperfective forms; intentionally no accelerator, need manual handling
			if #args.impf > 0 and aspect == "impf" then
				error("Can't specify imperfective counterparts for an imperfective verb")
			end
			add_verb_forms("imperfective", args.impf)

			-- Add the perfective forms; intentionally no accelerator, need manual handling
			if #args.pf > 0 and aspect == "pf" then
				error("Can't specify perfective counterparts for a perfective verb")
			end
			add_verb_forms("perfective", args.pf)

			-- Add the verbal nouns
			add_verb_forms("verbal noun", args.vn, "verbal noun", "noun")
		end,
	}
end

pos_functions["verbs"] = get_verb_pos("verbs")

pos_functions["verbal combining forms"] = get_verb_pos("verbal combining forms")

return export
