-- Author: primarily Benwing2; some work by Fenakhay, Erutuon; early version by Rua

local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local ar_translit = require("Module:ar-translit")
local ar_verb_module = "Module:ar-verb"
local ar_utilities_module = "Module:ar-utilities"
local ar = require(ar_utilities_module)
local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local links_module = "Module:links"
local inflection_utilities_module = "Module:inflection utilities"
local parse_utilities_module = "Module:parse utilities"

local require_when_needed = require("Module:utilities/require when needed")
local remove_links = require_when_needed(links_module, "remove_links")
local m_table = require("Module:table")
local m_str_utils = require("Module:string utilities")

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}

local list_to_set = m_table.listToSet
local rfind = m_str_utils.find
local rmatch = m_str_utils.match
local rsubn = m_str_utils.gsub
local u = m_str_utils.char
local rsplit = m_str_utils.split

local insert = table.insert
local concat = table.concat

local langcode = "ar"
local lang = require("Module:languages").getByCode(langcode)
local langname = lang:getCanonicalName()

local TEMPCOMMA = u(0xFFF0)
local TEMPARCOMMA = u(0xFFF1)

local misc_pos_with_gender = list_to_set {
	"suffixes",
	"adjective forms",
	"noun forms",
	"proper noun forms",
	"pronoun forms",
	"determiner forms",
}

-----------------------------------------------------------------------------------------
--                                   Utility functions                                 --
-----------------------------------------------------------------------------------------

local dump = mw.dumpObject

-- version of mw.ustring.gsub() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local function ine(val)
	if val == "" then return nil else return val end
end

-- Replace comma with a temporary char in comma + whitespace.
local function escape_comma_whitespace(run)
	local escaped = false

	if run:find("\\,") then
		run = run:gsub("\\,", "\\" .. TEMPCOMMA)
		escaped = true
	end
	if run:find("\\،") then
		run = run:gsub("\\،", "\\" .. TEMPARCOMMA)
		escaped = true
	end
	if run:find(",%s") then
		run = run:gsub(",(%s)", TEMPCOMMA .. "%1")
		escaped = true
	end
	if run:find("،%s") then
		run = run:gsub("،(%s)", TEMPARCOMMA .. "%1")
		escaped = true
	end
	return run, escaped
end

-- Undo replacement of comma with a temporary char in comma + whitespace.
local function unescape_comma_whitespace(run)
	return (run:gsub(TEMPCOMMA, ","):gsub(TEMPARCOMMA, "،"))
end

-- Split an argument on comma or Arabic comma, but not either type of comma followed by whitespace.
local function split_on_comma(val)
	if rfind(val, "[,،]%s") or val:find("\\") then
		return export.split_escaping(val, "[,،]", false, escape_comma_whitespace, unescape_comma_whitespace)
	else
		return rsplit(val, "[,،]")
	end
end

local function replace_tr_ending(tr, from, to)
	if not tr then
		return nil
	end
	local pref = tr:match("^(.*)" .. from .. "$")
	if not pref then
		error(("Translit '%s' does not end in -%s, as expected"):format(tr, from))
	end
	return pref .. to
end

-----------------------------------------------------------------------------------------
--                                   Tracking functions                                --
-----------------------------------------------------------------------------------------

local trackfn = require("Module:debug/track")
local function track(page)
	trackfn(langcode .. "-headword/" .. page)
	return true
end

--[==[
Examples of what you can find by looking at what links to the given
pages:

[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized]]
	all unvocalized pages
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/pl]]
	all unvocalized pages where the plural is unvocalized,
	  whether specified using pl=, pl2=, etc.
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/head]]
	all unvocalized pages where the head is unvocalized
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/head/nouns]]
	all nouns excluding proper nouns, collective nouns,
	 singulative nouns where the head is unvocalized
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/head/proper]]
	nouns all proper nouns where the head is unvocalized
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/head/not]]
	proper nouns all words that are not proper nouns
	  where the head is unvocalized
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized/adjectives]]
	all adjectives where any parameter is unvocalized;
	  currently only works for heads,
	  so equivalent to .../unvocalized/head/adjectives
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized-empty-head]]
	all pages with an empty head
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized-manual-translit]]
	all unvocalized pages with manual translit
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized-manual-translit/head/nouns]]
	all nouns where the head is unvocalized but has manual translit
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/unvocalized-no-translit]]
	all unvocalized pages without manual translit
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/i3rab]]
	all pages with any parameter containing i3rab
	  of either -un, -u, -a or -i
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/i3rab-un]]
	all pages with any parameter containing an -un i3rab ending
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/i3rab-un/pl]]
	all pages where a form specified using pl=, pl2=, etc.
	  contains an -un i3rab ending
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/i3rab-u/head]]
	all pages with a head containing an -u i3rab ending
[[Special:WhatLinksHere/Wiktionary:Tracking/ar-headword/i3rab/head/proper]]
	nouns (all proper nouns with a head containing i3rab
	  of either -un, -u, -a or -i)

In general, the format is one of the following:

Wiktionary:Tracking/ar-headword/FIRSTLEVEL
Wiktionary:Tracking/ar-headword/FIRSTLEVEL/ARGNAME
Wiktionary:Tracking/ar-headword/FIRSTLEVEL/POS
Wiktionary:Tracking/ar-headword/FIRSTLEVEL/ARGNAME/POS

FIRSTLEVEL can be one of "unvocalized", "unvocalized-empty-head" or its
opposite "unvocalized-specified", "unvocalized-manual-translit" or its
opposite "unvocalized-no-translit", "i3rab", "i3rab-un", "i3rab-u",
"i3rab-a", or "i3rab-i".

ARGNAME is either "head" or an argument such as "pl", "f", "cons", etc.
This automatically includes arguments specified as head2=, pl3=, etc.

POS is a part of speech, lowercase and singular, e.g. "noun",
"adjective", "proper noun", "collective noun", etc. or
"not proper noun", which includes all parts of speech but proper nouns.
]==]

local function track_form(argname, form, translit, pos)
	form = ar.reorder_shadda(remove_links(form))
	function dotrack(page)
		track(page)
		track(page .. "/" .. argname)
		if pos then
			track(page .. "/" .. pos)
			track(page .. "/" .. argname .. "/" .. pos)
			if pos ~= "proper noun" then
				track(page .. "/not proper noun")
				track(page .. "/" .. argname .. "/not proper noun")
			end
		end
	end
	function track_i3rab(arabic, tr)
		if rfind(form, arabic .. "$") then
			dotrack("i3rab")
			dotrack("i3rab-" .. tr)
		end
	end
	track_i3rab(ar.UN, "un")
	track_i3rab(ar.U, "u")
	track_i3rab(ar.A, "a")
	track_i3rab(ar.I, "i")
	if form == "" or not (lang:transliterate(form)) then
		dotrack("unvocalized")
		if form == "" then
			dotrack("unvocalized-empty-head")
		else
			dotrack("unvocalized-specified")
		end
		if translit then
			dotrack("unvocalized-manual-translit")
		else
			dotrack("unvocalized-no-translit")
		end
	end
end

-----------------------------------------------------------------------------------------
--                              Inflection-parsing functions                           --
-----------------------------------------------------------------------------------------

-- Construct the default construct state or informal form of a term in lemma format. Usually this is the same as the
-- lemma but is different for final-weak nouns and adjectives ending in -n in their lemma. NOTE: Input must be
-- shadda-reordered for this to work properly.
local function default_construct_state_or_informal(term, tr)
	local pref = term:match("^(.*)" .. ar.HAMZA .. ar.IN .."$")
	-- Hamza on the line with -in changes to hamza-on-yā with -ī.
	if pref then
		return pref .. ar.HAMZA_ON_YA .. ar.II, replace_tr_ending(tr, "in", "ī")
	end
	-- Otherwise just change -in to -ī.
	pref = term:match("^(.*)" .. ar.IN .. "$")
	if pref then
		return pref .. ar.II, replace_tr_ending(tr, "in", "ī")
	end
	-- Change -an with alif maqṣūra to -ā with alif maqṣūra.
	pref = term:match("^(.*)" .. ar.AN .. ar.AMAQ .. "$")
	if pref then
		return pref .. ar.AAMAQ, replace_tr_ending(tr, "an", "ā")
	end
	-- Change -an with tall alif (e.g. عَصًا) to -ā with tall alif.
	pref = term:match("^(.*)" .. ar.AN .. ar.ALIF .. "$")
	if pref then
		return pref .. ar.AA, replace_tr_ending(tr, "an", "ā")
	end
	return term, tr
end

local function generate_construct_state_or_informal_default(data, args)
	local heads = data.heads
	local consobjs = {}
	local different_cons = false
	for _, headobj in ipairs(data.heads) do
		local consterm, constr = default_construct_state_or_informal(headobj.term, headobj.tr)
		different_cons = different_cons or consterm ~= headobj.term or constr ~= headobj.tr
		local consobj = m_table.shallowCopy(headobj)
		consobj.term = consterm
		consobj.tr = constr
		insert(consobjs, consobj)
	end
	if different_cons then
		return consobjs
	else
		return {}
	end
end

local noun_field_cons = {
	field = "cons", label = "<<construct state>>", generate_default = generate_construct_state_or_informal_default,
	default_when_not_explicit = function(args, data) return true end,
}
local noun_field_inf = {field = "inf", label = "informal"}
local noun_field_obl = {field = "obl", label = "<<oblique>>"}
local noun_field_def = {field = "def", label = "<<definite>> state"}

local noun_inflections = {
	noun_field_cons,
	noun_field_inf,
	noun_field_obl,
	noun_field_def,
}

local adj_field_inf = {
	field = "inf", label = "informal", generate_default = generate_construct_state_or_informal_default,
	default_when_not_explicit = function(args, data) return true end,
}
local adj_field_obl = noun_field_obl
local adj_field_def = noun_field_def

local adjective_inflections = {
	adj_field_inf,
	adj_field_obl,
	adj_field_def,
}

local function has_construct_state(data)
	return data.pos_category ~= "adjectives"
end

local function parse_nominal_inflection(paramname, val, parse_err)
	return m_headword_utilities.parse_term_with_modifiers {
		val = val,
		paramname = paramname,
		splitchar = ",",
		include_mods = {"tr", "g"},
	}
end

local function make_nominal_inflection_param_mod_spec(paramname)
	return {convert = function(val, parse_err)
		return parse_nominal_inflection(paramname, val, parse_err)
	end}
end

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
		include_mods = {"tr"}
	else
		include_mods = {"tr", "g"}
		for _, spec in ipairs(has_construct_state(data) and noun_inflections or adjective_inflections) do
			insert(include_mods, {spec.field, make_nominal_inflection_param_mod_spec(argpref .. "." .. spec.field)})
		end
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

-----------------------------------------------------------------------------------------
--                                    Main entry point                                 --
-----------------------------------------------------------------------------------------

function export.show(frame)
	local iparams = {
		[1] = true,
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	local parargs = frame:getParent().args
	local poscat = iargs[1]

	local pos_in_1 = not poscat
	if pos_in_1 then
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and (misc_pos_with_gender[poscat] and "head_with_gender" or "head") or poscat

	local params = {
		["suffix"] = boolean_param,
		["nosuffix"] = boolean_param,
		["id"] = true,
		["json"] = boolean_param,
		["pagename"] = {}, -- for testing
	}

	if pos_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	local head_is_head = pos_functions[indexing_poscat] and pos_functions[indexing_poscat].head_is_not_1
	local headfield = head_is_head and "head" or pos_in_1 and 2 or 1
	params[headfield] = head_is_head and true or {default = "+"}
	params.head2 = {replaced_by = false, instead = "use multiple comma-separated values in |" .. headfield .. "="}
	local tr_replaced_by = {replaced_by = false, instead = "use <tr:...> inline modifier on |" .. headfield .. "="}
	params.tr = tr_replaced_by
	params.tr2 = tr_replaced_by

	if pos_functions[indexing_poscat] then
		for key, val in pairs(pos_functions[indexing_poscat].params()) do
			params[key] = val
		end
	end

	local parargs = frame:getParent().args
	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local data = {
		lang = lang,
		pos_category = poscat,
		orig_pos_category = poscat,
		categories = {},
		heads = {},
		genders = {},
		inflections = {enable_auto_translit = true},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		-- We expect a head always so the redundant head cat will be inaccurate.
		no_redundant_head_cat = true,
	}

	data.heads = parse_inflection(data, args, headfield, "is_head") 
	for _, headobj in ipairs(data.heads) do
		if headobj.term == "+" then
			headobj.term = pagename
		end
	end

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

	if pos_functions[indexing_poscat] then
		pos_functions[indexing_poscat].func(data, args)
	end

	-- Do this after calling pos_functions[poscat].func() as it may modify data.heads (as verbs do).
	local irreg_translit = false
	for _, head in ipairs(data.heads) do
		if ar_translit.irregular_translit(head.term, head.tr) then
			irreg_translit = true
			break
		end
	end

	if irreg_translit then
		insert(data.categories, langname .. " terms with irregular pronunciations")
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

-----------------------------------------------------------------------------------------
--                                    Gender handling                                  --
-----------------------------------------------------------------------------------------

local valid_bare_genders = {false, "m", "f", "mf", "mfbysense", "mfequiv"}
local valid_bare_numbers = {false, "d", "p"}
local valid_bare_animacies = {false, "pr", "np"}

local valid_genders = {}
for _, gender in ipairs(valid_bare_genders) do
	for _, number in ipairs(valid_bare_numbers) do
		for _, animacy in ipairs(valid_bare_animacies) do
			local parts = {}
			local function ins_part(part)
				if part then
					insert(parts, part)
				end
			end
			ins_part(gender)
			ins_part(number)
			ins_part(animacy)
			local full_gender = concat(parts, "-")
			valid_genders[full_gender == "" and "?" or full_gender] = true
		end
	end
end

local function is_masc_sg(g)
	return g == "m" or g == "m-pr" or g == "m-np"
end
local function is_fem_sg(g)
	return g == "f" or g == "f-pr" or g == "f-np"
end
local function is_masc_fem_sg(g)
	g = g:gsub("%-pr", ""):gsub("%-np", "")
	return g == "mf" or g == "mfequiv" or g == "mfbysense"
end

local function add_gender_params(params, default)
	params[2] = {type = "genders", default = default or "?"}
	params["g2"] = {replaced_by = false, instead = "use comma-separated values in |g="}
end

-- Handle gender in params 2=, inserting into `data.genders`. Also, if a lemma, insert categories into `data.categories`
-- if the gender is unexpected for the form of the noun. (Note: If there are multiple genders,
-- [[Module:gender and number]] will automatically insert 'Arabic POS with multiple genders'.)
local function handle_gender(data, args, nonlemma, field)
	if not args[field or 2] then
		return
	end
	for _, gspec in ipairs(args[field or 2]) do
		if not valid_genders[gspec.spec] then
			error("Unrecognized gender: " .. gspec.spec)
		end
	end

	data.genders = args[field or 2]

	if nonlemma then
		return
	end

	for _, gspec in ipairs(data.genders) do
		local g = gspec.spec
		if is_masc_sg(g) or is_fem_sg(g) or is_masc_fem_sg(g) then
			local head = data.heads[1]
			if head then
				head = rsub(ar.reorder_shadda(remove_links(head.term)), ar.UNUOPT .. "$", "")
				local ends_with_tam = rfind(head, "^[^ ]*" .. ar.TAM .. "$") or
						rfind(head, "^[^ ]*" .. ar.TAM .. " ")
				if (is_masc_sg(g) or is_masc_fem_sg(g)) and ends_with_tam then
					insert(data.categories, langname .. " masculine terms with feminine ending")
				elseif (is_fem_sg(g) or is_masc_fem_sg(g)) and not ends_with_tam and
						not rfind(head, "[" .. ar.ALIF .. ar.AMAQ .. "]$") and
						not rfind(head, ar.ALIF .. ar.HAMZA .. "$") then
					insert(data.categories, langname .. " feminine terms lacking feminine ending")
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------
--                                   Inflection handlers                               --
-----------------------------------------------------------------------------------------

-- Add list parameters to `params` (a structure as passed to [[Module:parameters]]) for a parameter named `argpref`.
-- If `argpref` is "*", add the nominal inflection parameters for construct state, definite state, etc. Related
-- transliteration and gender parameters are no longer supported in favor of inline modifiers, and error messages are
-- output if these parameters are used.
local function add_infl_params(params, argpref)
	params[argpref] = {list = true, disallow_holes = true}
	params[argpref .. "tr"] = {replaced_by = false, instead = "use <tr:...> inline modifier on |" .. argpref .. "="}
	params[argpref .. "g"] = {replaced_by = false, instead = "use <g:...> inline modifier on |" .. argpref .. "="}
end

--[=[
Fetch a list of inflections from the arguments in `args` based on argument `field` (e.g. "pl"). Label with `label`
(e.g. "plural"), which will appear in the headword. Insert into `data.inflections`, where `data` is the structure
passed to [[Module:headword]]. If `generate_default` is specified, it should be a function of two arguments
(`data`, `args`), which should generate the default value if no values are specified or if "+" is explicitly given.
If `generate_default` isn't specified and the user gave no values, no inflection will be inserted.
]=]
local function handle_infl(data, args, spec)
	local newinfls = parse_inflection(data, args, spec.field, false)
	if not newinfls[1] and spec.default_when_not_explicit and spec.default_when_not_explicit(data, args) then
		newinfls = {{term = "+"}}
	end
	if spec.handle then
		spec.handle(data, args, newinfls)
	end
	local default_specs = spec.allowed_defspecs
	if not default_specs then
		default_specs = spec.generate_default and {["+"] = true} or {}
	end
	local saw_defspec = false
	for _, newinfl in ipairs(newinfls) do
		if default_specs[newinfl.term] or newinfl.term == "~" then
			saw_defspec = true
			break
		end
	end
	if saw_defspec then
		local newnewinfls = {}
		for _, newinfl in ipairs(newinfls) do
			if default_specs[newinfl.term] then
				if newinfl.tr then
					error("Can't specify translit for default value '" .. newinfl.term .. "'")
				end
				local definfls = spec.generate_default(data, args, newinfl.term)
				for _, definfl in ipairs(definfls) do
					m_headword_utilities.combine_termobj_qualifiers_labels(definfl, newinfl)
					insert(newnewinfls, definfl)
				end
			elseif newinfl.term == "~" then
				if newinfl.tr then
					error("Can't specify translit for head-requesting value '~'")
				end
				for _, headobj in ipairs(data.heads) do
					headobj = m_table.shallowCopy(headobj)
					m_headword_utilities.combine_termobj_qualifiers_labels(headobj, newinfl)
					insert(newnewinfls, headobj)
				end
			else
				insert(newnewinfls, newinfl)
			end
		end
		newinfls = newnewinfls
	end
	if newinfls[1] then
		if newinfls[1].term == "--" then
			if newinfls[2] then
				error("Can't specify more than one term if first term is '--', meaning \"don't insert anything\"")
			end
		else
			insert_inflection(data, newinfls, spec.label, nil, spec.defgender, spec.field, spec.no_label,
				spec.usually_no_label)
		end
	end
end

local function add_infl_list_params(params, infl_list)
	for _, infl in ipairs(infl_list) do
		add_infl_params(params, infl.field)
	end
end

local function handle_infl_list_args(data, args, infl_list)
	for _, infl in ipairs(infl_list) do
		handle_infl(data, args, infl)
	end
end

-----------------------------------------------------------------------------------------
--                               Default ending generators                             --
-----------------------------------------------------------------------------------------

local function make_conditional_default(specs)
	return function(data, args)
		local heads = data.heads
		if not heads[1] then
			heads = {{term = data.pagename}}
		end
		local newobjs = {}
		for _, headobj in ipairs(heads) do
			local term = ar.reorder_shadda(headobj.term)
			local tr = headobj.tr
			local matched = false
			for _, spec in ipairs(specs) do
				local from, fromtr, to, totr = unpack(spec)
				if from:find("^%^") then
					pref = rmatch(term, from .. "$")
				else
					pref = rmatch(term, "^(.*)" .. from .. "$")
				end
				if pref then
					term = pref .. to
					tr = replace_tr_ending(tr, fromtr, totr)
					matched = true
					headobj = m_table.shallowCopy(headobj)
					headobj.term = ar.undo_reorder_shadda(term)
					headobj.tr = tr
					insert(newobjs, headobj)
					break
				end
			end
			if not matched then
				error(("Internal error: No matching spec: head=%s"):format(dump(headobj)))
			end
		end
		return newobjs
	end
end

local default_feminine = make_conditional_default {
	{ar.AN .. ar.AMAQ, "an", ar.AAH, "āh"},
	{ar.AN .. ar.ALIF, "an", ar.AAH, "āh"}, -- e.g. مُحْيًا
	{ar.HAMZA .. ar.IN, "in", ar.HAMZA_ON_YA .. ar.IYAH, "iya"},
	{ar.IN, "in", ar.IYAH, "iya"},
	{"", "", ar.AH, "a"},
}

local default_masculine = make_conditional_default {
	-- tall alif substitutes for alif maqṣūra after a yāʔ
	{ar.Y .. ar.AAH, "āh", ar.AN .. ar.ALIF, "an"},
	{ar.AAH, "āh", ar.AN .. ar.AMAQ, "an"},
    -- handle the common case of final-weak feminine active participle with preceding hamza;
    -- the hamza-on-yāʔ always converts back to hamza on the line when preceded by ā (alif) but
    -- may not otherwise, so we just leave it alone in that case
	{ar.ALIF .. ar.HAMZA_ON_YA .. ar.IYAH, "iya", ar.HAMZA .. ar.IN, "in"},
	{ar.IYAH, "iya", ar.IN, "in"},
	{ar.AH, "a", "", ""},
	{"", "", "", ""},
}

local default_masculine_plural = make_conditional_default {
	{ar.AN .. ar.AMAQ, "an", ar.AWN, "awn"},
	{ar.AN .. ar.ALIF, "an", ar.AWN, "awn"}, -- e.g. مُحْيًا
	{ar.HAMZA .. ar.IN, "in", ar.HAMZA_ON_WAW .. ar.UUN, "ūn"},
	{ar.IN, "in", ar.UUN, "ūn"},
	{"", "", ar.UUN, "ūn"},
}

local default_feminine_plural = make_conditional_default {
	-- صَلَاة pl. صَلَوَات and أَدَاة pl. أَدَوَات and similar; but نَوَاة and وَفَاة with a و in them become نَوَيَات and وَفَيَات;
	-- and longer terms like مُبَارَاة and كُمَّثْرَاة invariably form their plural in -يَات.
	{"^([^و]" .. ar.A .. "[^و])" .. ar.AAH, "āh", ar.A .. ar.W .. ar.AAT, "awāt"},
	{ar.AAH, "āh", ar.AYAAT, "ayāt"},
	{ar.AN .. ar.AMAQ, "an", ar.AYAAT, "ayāt"},
	{ar.AN .. ar.ALIF, "an", ar.AYAAT, "ayāt"}, -- e.g. مُحْيًا
	{ar.HAMZA .. ar.IN, "in", ar.HAMZA_ON_YA .. ar.IYAAT, "iyāt"},
	{ar.IN, "in", ar.IYAAT, "iyāt"},
	{ar.AH, "a", ar.AAT, "āt"},
	{"", "", ar.AAT, "āt"},
}

local default_masculine_dual = make_conditional_default {
	{ar.AN .. ar.AMAQ, "an", ar.AYAAN, "ayān"},
	{ar.AN .. ar.ALIF, "an", ar.AYAAN, "ayān"}, -- e.g. مُحْيًا
	{ar.HAMZA .. ar.IN, "in", ar.HAMZA_ON_YA .. ar.IYAAN, "iyān"},
	{ar.IN, "in", ar.IYAAN, "iyān"},
	{"", "", ar.AAN, "ān"},
}

local default_feminine_dual = make_conditional_default {
	{ar.AN .. ar.AMAQ, "an", ar.AATAAN, "ātān"},
	{ar.AN .. ar.ALIF, "an", ar.AATAAN, "ātān"}, -- e.g. مُحْيًا
	{ar.HAMZA .. ar.IN, "in", ar.HAMZA_ON_YA .. ar.IY .. ar.ATAAN, "iyatān"},
	{ar.IN, "in", ar.IY .. ar.ATAAN, "iyatān"},
	{"", "", ar.ATAAN, "atān"},
}

-- Return whether `term` is a nisba noun or adjective, ending in -iyy or -iyyah. `nisba_val` is the value of
-- args.nisba; if non-nil, it overrides any auto-determination based on the shape of the term.
local function term_is_nisba(term, nisba_val)
	if nisba_val ~= nil then
		return nisba_val
	end
	term = ar.reorder_shadda(term) -- necessary to avoid issues with e.g. أُورُوبِّيّ.
	local pref = rmatch(term, ar.IYY .. ar.UN .. "?$")
	if not pref then
		pref = rmatch(term, ar.IYYAH .. ar.UN .. "?$")
	end
	-- Avoid false positives for words like قَوِيّ "strong" and صَبِيّ "boy". There may be other false positives
	-- but this should catch most of them and will avoid very many false negatives.
	return pref and not rfind(pref, "^[^ا]" .. ar.A .. ".$")
end

-----------------------------------------------------------------------------------------
--                                      Adjectives                                     --
-----------------------------------------------------------------------------------------

local function is_defaulting_adjective(data, args)
	return data.orig_pos_category == "defaulting adjectives"
end

local adj_field_elative = {field = "el", label = "<<elative>>"}

local adj_inflections = {
	adj_field_inf,
	adj_field_obl,
	adj_field_def,
	{field = "f", label = "feminine", generate_default = default_feminine,
		default_when_not_explicit = is_defaulting_adjective},
	{field = "d", label = "masculine dual", generate_default = default_masculine_dual},
	{field = "fd", label = "feminine dual", generate_default = default_feminine_dual},
	{field = "cpl", label = "common plural"},
	{field = "pl", label = "masculine plural", generate_default = default_masculine_plural,
		default_when_not_explicit = is_defaulting_adjective},
	{field = "fpl", label = "feminine plural", generate_default = default_feminine_plural,
		default_when_not_explicit = is_defaulting_adjective},
}

local function get_adj_params()
	local params = {}
	add_infl_list_params(params, adj_inflections)
	add_infl_params(params, "el")
	params.nisba = boolean_param
	return params
end

local function handle_adj_args(data, args)
	handle_infl_list_args(data, args, adj_inflections)
	handle_infl(data, args, adj_field_elative)
	for _, headobj in ipairs(data.heads) do
		if term_is_nisba(headobj.term, args.nisba) then
			insert(data.categories, langname .. " relative adjectives (nisba)")
			break
		end
	end
end

pos_functions["adjectives"] = {
	params = get_adj_params,
	func = handle_adj_args,
}

pos_functions["defaulting adjectives"] = {
	params = get_adj_params,
	func = function(data, args)
		data.pos_category = "adjectives"
		handle_adj_args(data, args)
	end,
}

-----------------------------------------------------------------------------------------
--                                      Nouns, etc.                                    --
-----------------------------------------------------------------------------------------

local function get_masc_or_feminine_gender(data, default_type)
	local saw_m, saw_f, saw_mf
	for _, gender in ipairs(data.genders) do
		if is_masc_sg(gender.spec) then
			saw_m = true
		elseif is_fem_sg(gender.spec) then
			saw_f = true
		elseif is_masc_fem_sg(gender.spec) then
			saw_mf = true
		end
	end
	if saw_mf or saw_m and saw_f then
		error("Can't generate default for " .. default_type .. " when gender is both masculine and feminine")
	elseif saw_m then
		return "m"
	elseif saw_f then
		return "f"
	else
		error("Can't generate default for " .. default_type .. " when gender is not specified as " ..
			"masculine or feminine singular")
	end
end

local function is_defaulting_noun(data, args)
	return data.orig_pos_category == "defaulting nouns"
end

local noun_field_dual = {
	field = "d", label = "dual",
	generate_default = function(data, args)
		local gender = get_masc_or_feminine_gender(data, "noun dual")
		if gender == "m" then
			return default_masculine_dual(data, args)
		else
			return default_feminine_dual(data, args)
		end
	end,
}

local noun_field_plural = {
	field = "pl", label = "plural",
	generate_default = function(data, args, defspec)
		local gender = get_masc_or_feminine_gender(data, "noun plural")
		if gender == "m" then
			if defspec == "+f" then
				return default_feminine_plural(data, args)
			else
				return default_masculine_plural(data, args)
			end
		elseif defspec == "+f" then
			error("Can't specify '+f' with feminine gender; just use '+'")
		else
			return default_feminine_plural(data, args)
		end
	end,
	-- Handle the case where pl=-, indicating an uncountable noun.
	handle = function(data, args, terms)
		if terms[1] and terms[1] == "-" then
			insert(data.categories, langname .. " uncountable nouns")
			if args.pauc and args.pauc[1] then
				error("Can't specify paucals when pl=-")
			end
		end
	end,
	allowed_defspecs = {["+"] = true, ["+f"] = true},
	default_when_not_explicit = is_defaulting_noun,
	no_label = "<<uncountable>>",
	usually_no_label = "usually <<uncountable>>",
}

local noun_field_paucal = {
	field = "pauc", label = "<<paucal>>", generate_default = default_feminine_plural,
}

local noun_field_feminine = {
	field = "f", label = "feminine", generate_default = default_feminine,
	default_when_not_explicit = function(data, args)
		if data.orig_pos_category ~= "defaulting nouns" then
			return nil
		end
		local gender = get_masc_or_feminine_gender(data, "defaulting-if-masculine noun feminine")
		return gender == "m"
	end,
}

local noun_field_masculine = {
	field = "m", label = "masculine", generate_default = default_masculine,
	default_when_not_explicit = function(data, args)
		if data.orig_pos_category ~= "defaulting nouns" then
			return nil
		end
		local gender = get_masc_or_feminine_gender(data, "defaulting-if-feminine noun masculine")
		return gender == "f"
	end,
}

local noun_basic_inflections = {
	noun_field_cons,
	noun_field_inf,
	noun_field_obl,
	noun_field_def,
}

local noun_shared_inflections = {
	noun_field_dual,
	noun_field_plural,
}

local noun_extra_inflections = {
	noun_field_paucal,
	noun_field_feminine,
	noun_field_masculine,
}

local function get_noun_params()
	local params = {}
	add_gender_params(params)
	add_infl_list_params(params, noun_basic_inflections)
	add_infl_list_params(params, noun_shared_inflections)
	add_infl_list_params(params, noun_extra_inflections)
	params.nisba = boolean_param
	return params
end

local function handle_noun_args(data, args)
	handle_gender(data, args)
	handle_infl_list_args(data, args, noun_basic_inflections)
	handle_infl_list_args(data, args, noun_shared_inflections)
	handle_infl_list_args(data, args, noun_extra_inflections)
	for _, headobj in ipairs(data.heads) do
		if term_is_nisba(headobj.term, args.nisba) then
			insert(data.categories, langname .. " relative nouns (nisba)")
			break
		end
	end
end

pos_functions["nouns"] = {
	params = get_noun_params,
	func = handle_noun_args,
}

pos_functions["defaulting nouns"] = {
	params = get_noun_params,
	func = function(data, args)
		data.pos_category = "nouns"
		-- FIXME: Temporary hack, remove when nouns converted
		if args[2] and args[2][1].spec == "?" then
			args[2][1].spec = "m"
		end
		handle_noun_args(data, args)
	end,
}

local noun_field_singulative = {field = "sing", label = "<<singulative>>", defgender = "f"}
local noun_field_collective = {field = "coll", label = "<<collective>>", defgender = "m"}

local function handle_sing_coll_noun_infls(data, args, otherinfl, otherlabel, othergender)
	-- Handle sing= (corresponding singulative noun) or coll= (corresponding collective noun) and their gender
	handle_infl(data, args, otherinfl, otherlabel, nil, othergender)
	handle_infl_list_args(data, args, sing_coll_noun_inflections)
end

local function get_singulative_collective_noun_params(defgender, otherinfl)
	local params = {}
	add_gender_params(params, defgender)
	add_infl_list_params(params, noun_basic_inflections)
	add_infl_params(params, otherinfl)
	add_infl_list_params(params, noun_shared_inflections)
	add_infl_params(params, "pauc")
	return params
end

pos_functions["collective nouns"] = {
	params = function() return get_singulative_collective_noun_params("m", "sing") end,
	func = function(data, args)
		data.pos_category = "nouns"
		insert(data.categories, langname .. " collective nouns")
		m_headword_utilities.insert_fixed_inflection {
			headdata = data,
			label = "<<collective>>",
		}
		handle_gender(data, args)
		handle_infl_list_args(data, args, noun_basic_inflections)
		handle_infl(data, args, noun_field_singulative)
		handle_infl_list_args(data, args, noun_shared_inflections)
		handle_infl(data, args, noun_field_paucal)
	end
}

pos_functions["singulative nouns"] = {
	params = function() return get_singulative_collective_noun_params("f", "coll") end,
	func = function(data, args)
		data.pos_category = "nouns"
		insert(data.categories, langname .. " singulative nouns")
		m_headword_utilities.insert_fixed_inflection {
			headdata = data,
			label = "<<singulative>>",
		}
		handle_gender(data, args)
		handle_infl_list_args(data, args, noun_basic_inflections)
		handle_infl(data, args, noun_field_collective)
		handle_infl_list_args(data, args, noun_shared_inflections)
		handle_infl(data, args, noun_field_paucal)
	end
}

-- FIXME: Do numerals really behave almost as nouns? They vary by masc/fem.
pos_functions["numerals"] = {
	params = get_noun_params,
	func = function(data, args)
		insert(data.categories, langname .. " cardinal numbers")
		handle_noun_args(data, args)
	end
}

pos_functions["proper nouns"] = {
	params = get_noun_params,
	func = handle_noun_args,
}

local function get_pronoun_params()
	local params = {}
	add_gender_params(params, defgender)
	add_infl_list_params(params, noun_basic_inflections)
	add_infl_list_params(params, noun_shared_inflections)
	add_infl_params(params, "f")
	return params
end

pos_functions["pronouns"] = {
	params = get_pronoun_params,
	func = function(data, args)
		handle_gender(data, args)
		handle_infl_list_args(data, args, noun_basic_inflections)
		handle_infl_list_args(data, args, noun_shared_inflections)
		handle_infl(data, args, noun_field_feminine)
	end
}

-----------------------------------------------------------------------------------------
--                                    Non-lemma forms                                  --
-----------------------------------------------------------------------------------------

local function get_gender_only_params(default)
	return function()
		local params = {}
		add_gender_params(params, default)
		return params
	end
end

pos_functions["noun plural forms"] = {
	params = function()
		local params = {}
		add_gender_params(params, "p")
		add_infl_params(params, "cons")
		return params
	end,
	func = function(data, args)
		data.pos_category = "noun forms"
		handle_gender(data, args, "nonlemma")
		handle_infl(data, args, {field = "cons", label = "<<construct state>>"})
	end
}

pos_functions["adjective feminine forms"] = {
	params = get_gender_only_params("f"),
	func = function(data, args)
		data.pos_category = "adjective feminine forms"
		handle_gender(data, args, "nonlemma")
	end
}

pos_functions["noun dual forms"] = {
	params = get_gender_only_params("m-d"),
	func = function(data, args)
		data.pos_category = "noun forms"
		handle_gender(data, args, "nonlemma")
	end
}

pos_functions["adjective plural forms"] = {
	params = get_gender_only_params("m-d"),
	func = function(data, args)
		data.pos_category = "adjective forms"
		handle_gender(data, args, "nonlemma")
	end
}

pos_functions["adjective dual forms"] = {
	params = get_gender_only_params("m-d"),
	func = function(data, args)
		data.pos_category = "adjective forms"
		handle_gender(data, args, "nonlemma")
	end
}

pos_functions["noun forms"] = {
	params = get_gender_only_params(),
	func = function(data, args)
		handle_gender(data, args, "nonlemma")
	end
}

local valid_forms = list_to_set(
		{ "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
		  "XIII", "XIV", "XV", "Iq", "IIq", "IIIq", "IVq" })

-- FIXME: Partly duplicated in [[Module:ar-inflections]].
local function handle_conj_form(data, args)
	local form = args[2]
	if form then
		if not valid_forms[form] then
			error("Invalid verb conjugation form " .. form)
		end

		insert(data.inflections, { label = "[[Appendix:Arabic verbs#Form " .. form .. "|form " .. form .. "]]" })
	end
end

pos_functions["verb forms"] = {
	params = function()
		return {
			[2] = {},
		}
	end,
	func = function(data, args)
		handle_conj_form(data, args)
	end
}

local function get_participle_params()
	local params = get_adj_params()
	params[2] = {}
	return params
end

pos_functions["active participles"] = {
	params = get_participle_params,
	func = function(data, args)
		data.pos_category = "participles"
		insert(data.categories, langname .. " active participles")
		handle_conj_form(data, args)
		handle_infl_list_args(data, args, adj_inflections)
	end
}

pos_functions["passive participles"] = {
	params = get_participle_params,
	func = function(data, args)
		data.pos_category = "participles"
		insert(data.categories, langname .. " passive participles")
		handle_conj_form(data, args)
		handle_infl_list_args(data, args, adj_inflections)
	end
}

-----------------------------------------------------------------------------------------
--                                         Verbs                                       --
-----------------------------------------------------------------------------------------

pos_functions["verbs"] = {
	head_is_not_1 = true,
	params = function() return {
		[1] = {},
		-- Comma-separated lists with possible inline modifiers
		["past"] = {},
		["past1s"] = {},
		["nonpast"] = {},
		["vn"] = {},
		["noautolinktext"] = {type = "boolean"},
		["noautolinkverb"] = {type = "boolean"},
	} end,
	func = function(data, args)
		local ar_verb = require(ar_verb_module)
		local alternant_multiword_spec =
			args[1] ~= "-" and ar_verb.do_generate_forms(args, "ar-verb", data.pagename) or nil

		local function do_slot(slots_to_check, override, label, slot_is_headword)
			-- Do this even with an override so we can return the correct filled slot.
			local slot, slotval
			if alternant_multiword_spec then
				for _, potential_slot in ipairs(slots_to_check) do
					slotval = alternant_multiword_spec.forms[potential_slot]
					if slotval then
						slot = potential_slot
						break
					end
				end
			end

			local function get_slot_values()
				local terms = {}
				for _, form in ipairs(slotval) do
					local term = {
						term = form.form,
						id = form.id,
						genders = form.genders,
						pos = form.pos,
						lit = form.lit,
					}
					term.tr = form.translit
					if form.footnotes then
						local quals, refs = require(inflection_utilities_module).
							convert_footnotes_to_qualifiers_and_references(form.footnotes)
						term.q = quals
						term.refs = refs
					end
					insert(terms, term)
				end

				return terms
			end

			if override then
				local override_param_mods = {
					alt = {},
					t = {
						-- [[Module:headword]] expects the gloss in "gloss".
						item_dest = "gloss",
					},
					gloss = {},
					g = {
						-- [[Module:headword]] expects the genders in "genders".
						item_dest = "genders",
						type = "genders",
					},
					pos = {},
					lit = {},
					id = {},
					-- Qualifiers and labels
					q = {
						type = "qualifier",
					},
					qq = {
						type = "qualifier",
					},
					l = {
						type = "labels",
					},
					ll = {
						type = "labels",
					},
					ref = {
						-- [[Module:headword]] expects the references in "refs".
						item_dest = "refs",
						type = "references",
					},
				}

				local function generate_obj(formval, parse_err)
					if formval == "+" then
						return {term = "+", underlying_terms = get_slot_values()}
					end
					local val, uncertain = formval:match("^(.*)(%?)$")
					val = val or formval
					uncertain = not not uncertain
					local ar, translit = val:match("^(.*)//(.*)$")
					if not ar then
						ar = formval
					end
					local retval = {term = ar, uncertain = uncertain}
					retval.tr = translit
				end

				local terms
				if override:find("<") then
					terms = require(parse_utilities_module).parse_inline_modifiers(override, {
						paramname = paramname,
						param_mods = override_param_mods,
						generate_obj = generate_obj,
						splitchar = "[,،]",
						escape_fun = escape_comma_whitespace,
						unescape_fun = unescape_comma_whitespace,
					})
				else
					terms = split_on_comma(override)
					for i, split in ipairs(terms) do
						terms[i] = generate_obj(split)
					end
				end
				-- See if + was supplied and we have to potentially flatten multiple default terms and harmonize
				-- default properties with override properties.
				local saw_underlying_terms = false
				for _, term in ipairs(terms) do
					if term.underlying_terms then
						saw_underlying_terms = true
						break
					end
				end
				if saw_underlying_terms then
					-- Flatten any default terms, copying the corresponding override properties over the default
					-- properties. Non-default terms get inserted directly.
					local flattened = {}
					for _, term in ipairs(terms) do
						if term.underlying_terms then
							for _, underlying in ipairs(term.underlying_terms) do
								for k, v in pairs(term) do
									if k ~= "term" and k ~= "underlying_terms" then
										if k == "uncertain" then
											underlying.uncertain = underlying.uncertain or v
										elseif type(v) ~= "table" or v[1] then
											-- Don't copy empty lists (which are the default) over possibly non-empty
											-- lists.
											underlying[k] = v
										end
									end
								end
								insert(flattened, underlying)
							end
						else
							insert(flattened, term)
						end
					end
					terms = flattened
				end
				if not slot_is_headword then
					terms.label = label
				end
				return terms, slot
			elseif not alternant_multiword_spec then
				return nil, slot
			else
				if not slotval then
					if slot_is_headword then
						-- FIXME, put "uncertain" as qualifier? Does this ever happen?
						return nil, slot
					elseif alternant_multiword_spec.slot_uncertain[slot] then
						return {label = label .. " uncertain"}, slot
					elseif alternant_multiword_spec.slot_explicitly_missing[slot] then
						return {label = "no " .. label}, slot
					else
						-- just say nothing about this slot
						return nil, slot
					end
				end
				local terms = get_slot_values()
				if not slot_is_headword then
					terms.label = label
				end
				return terms, slot
			end
		end

		local gloss_parts = {}
		for _, vform in ipairs(alternant_multiword_spec.verb_forms) do
			insert(gloss_parts, "[[Appendix:Arabic verbs#Form " .. vform .. "|" .. vform .. "]]")
		end
		if gloss_parts[1] then
			data.gloss = concat(gloss_parts, ", ")
		end

		if data.heads[1] and args.past then
			error("Can't specify both head= and past= to {{ar-verb}}; prefer past=")
		end
		
		if not alternant_multiword_spec.has_active then
			insert(data.inflections, {label = "passive-only"})
		end

		-- Do this always so `past_slot` is correctly filled.
		local past, past_slot = do_slot(ar_verb.potential_lemma_slots, args.past, "-", "slot is headword")
		if data.heads[1] then
			-- user specified head=; don't override with past= or slot 'past_3sm' etc.
		else
			if past then
				data.heads = past
			end
		end

		local should_do_past1s = not not args.past1s
		if not should_do_past1s then
			local is_form_I = false
			for _, vform in ipairs(alternant_multiword_spec.verb_forms) do
				if vform == "I" then
					is_form_I = true
					break
				end
			end

			if is_form_I then
				require(inflection_utilities_module).map_word_specs(alternant_multiword_spec, function(base)
					if base.verb_form == "I" then
						for _, vowel_spec in ipairs(base.conj_vowels) do
							-- For form-I geminate verbs, the final vowel of the past is elided in the citation form.
							-- We want to display it for all cases other than active a~u and a~i (the most common
							-- cases).
							if vowel_spec.weakness == "geminate" then
								if ar_verb.is_passive_only(base.passive) then
									should_do_past1s = true
									break
								end
								local past_vowel = ar_verb.rget(vowel_spec.past)
								local nonpast_vowel = ar_verb.rget(vowel_spec.nonpast)
								if not (past_vowel == ar.A and (nonpast_vowel == ar.U or nonpast_vowel == ar.I)) then
									should_do_past1s = true
									break
								end
							end
						end
						-- FIXME, provide way of breaking early from map_word_specs().
					end
				end)
			end
		end

		local past1s
		if should_do_past1s then
			past1s, _ = do_slot({"past_1s", "past_pass_1s"}, args.past1s, "first-person singular past")
			if past1s then
				insert(data.inflections, past1s)
			end
		end

		local nonpast_slots
		if not past_slot or past_slot:find("^past_") then
			nonpast_slots = {"ind_3ms", "ind_pass_3ms", "imp_2ms"}
		else
			nonpast_slots = {}
		end
		local nonpast, _ = do_slot(nonpast_slots, args.nonpast, "non-past")
		if nonpast then
			insert(data.inflections, nonpast)
		end

		local vn, _ = do_slot({"vn"}, args.vn, "verbal noun")
		if vn then
			insert(data.inflections, vn)
		end

		-- FIXME: Should we insert categories? Conjugation also does it and is more likely to be accurate.
		--for _, cat in ipairs(alternant_multiword_spec.categories) do
		--	insert(data.categories, cat)
		--end

		--[=[
		-- FIXME: Review this to see if we need to port it.
		-- If the user didn't explicitly specify head=, or specified exactly one head (not 2+) and we were able to
		-- incorporate any links in that head into the 1= specification, use the infinitive generated by
		-- [[Module:pt-verb]] in place of the user-specified or auto-generated head. This was copied from
		-- [[Module:it-headword]], where doing this gets accents marked on the verb(s). We don't have accents marked on
		-- the verb but by doing this we do get any footnotes on the infinitive propagated here. Don't do this if the
		-- user gave multiple heads or gave a head with a multiword-linked verbal expression such as Italian
		-- '[[dare esca]] [[al]] [[fuoco]]' (FIXME: give Portuguese equivalent).
		if not data.user_specified_heads[1] or (
			not data.user_specified_heads[2] and alternant_multiword_spec.incorporated_headword_head_into_lemma
		) then
			data.heads = {}
			for _, lemma_obj in ipairs(alternant_multiword_spec.forms.infinitive_linked) do
				local quals, refs = require(inflection_utilities_module).
					convert_footnotes_to_qualifiers_and_references(lemma_obj.footnotes)
				insert(data.heads, {term = lemma_obj.form, q = quals, refs = refs})
			end
		end
		]=]
	end
}

-----------------------------------------------------------------------------------------
--                                Generic parts of speech                              --
-----------------------------------------------------------------------------------------

pos_functions.head_with_gender = {
	params = function()
		return {
			[3] = {type = "genders"},
		}
	end,
	func = function(data, args)
		handle_gender(data, args, "nonlemma", 3)
	end,
}

return export
