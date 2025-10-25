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

local list_to_set = m_table.listToSet
local rfind = m_str_utils.find
local rsubn = m_str_utils.gsub
local u = m_str_utils.char
local rsplit = m_str_utils.split

local insert = table.insert
local concat = table.concat

local lang = require("Module:languages").getByCode("ar")
local langname = lang:getCanonicalName()

local TEMPCOMMA = u(0xFFF0)
local TEMPARCOMMA = u(0xFFF1)

-----------------------
-- Utility functions --
-----------------------

local dump = mw.dumpObject

-- version of mw.ustring.gsub() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
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

-- Construct the default construct state of a term in lemma format. Usually this is the same as the lemma but is
-- different for final-weak nouns ending in -n in their lemma. NOTE: Input must be shadda-reordered for this to work
-- properly.
local function default_construct_state(term, tr)
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

-- Tracking functions

local trackfn = require("Module:debug/track")
local function track(page)
	trackfn("ar-headword/" .. page)
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

local function generate_construct_state_default(data, args)
	local heads = data.heads
	local consobjs = {}
	local different_cons = false
	for _, headobj in ipairs(data.heads) do
		local consterm, constr = default_construct_state(headobj.term, headobj.tr)
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

local nominal_inflections = {
	{field = "cons", label = "<<construct state>>", generate_default = generate_construct_state_default},
	{field = "def", label = "<<definite state>>"},
	{field = "obl", label = "<<oblique>>"},
	{field = "inf", label = "informal"},
}

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
		for _, spec in ipairs(nominal_inflections) do
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
		-- If the user supplied a construct state for the term with a value of "+", substitute the default construct
		-- state of the term. If the user supplied a value of "--", they want no construct state displayed. Otherwise,
		-- if the user didn't supply any construct state, we check to see if the default construct state is different
		-- from the lemma and display it if so; this applies particularly to terms in '-in' and '-an', where the default
		-- construct state is almost always correct.
		if not termobj.cons then
			local defcons, defconstr = default_construct_state(termobj.term, termobj.tr)
			if termobj.term ~= defcons or termobj.tr ~= defconstr then
				-- We don't want to copy qualifiers, labels, etc. from the term object because we're a subinflection of
				-- the term object.
				termobj.cons = {{term = defcons, tr = defconstr}}
			end
		elseif termobj.cons[1].term == "--" then
			if termobj.cons[2] then
				error("Can't specify more than one value for <cons:...> if first value is '--', meaning \"don't insert anything\"")
			end
			termobj.cons = nil
		else
			for i, consobj in ipairs(termobj.cons) do
				if consobj.term == "+" then
					if consobj.tr then
						error("Can't specify translit for default value '+'")
					end
					consobj.term, consobj.tr = default_construct_state(termobj.term, termobj.tr)
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

		for _, spec in ipairs(nominal_inflections) do
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

-- The main entry point.
function export.show(frame)
	local poscat = frame.args[1]
		or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

	local parargs = frame:getParent().args

	local params = {
		["id"] = {},
		["nolinkhead"] = {type = "boolean"},
		["json"] = {type = "boolean"},
		["pagename"] = {}, -- for testing
	}

	local head_is_head = pos_functions[poscat] and pos_functions[poscat].head_is_not_1
	if head_is_head then
		params.head = true
	else
		params[1] = {default = "+"}
	end
	local headfield = head_is_head and "head" or 1
	params.head2 = {replaced_by = false, instead = "use multiple comma-separated values in |" .. headfield .. "="}
	local tr_replaced_by = {replaced_by = false, instead = "use <tr:...> inline modifier on |" .. headfield .. "="}
	params.tr = tr_replaced_by
	params.tr2 = tr_replaced_by

	if pos_functions[poscat] then
		for key, val in pairs(pos_functions[poscat].params) do
			params[key] = val
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = {},
		genders = {},
		inflections = {enable_auto_translit = true},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
	}

	data.heads = parse_inflection(data, args, head_is_head and "head" or 1, "is_head") 
	for _, headobj in ipairs(data.heads) do
		if headobj.term == "+" then
			headobj.term = pagename
		end
	end

	if pos_functions[poscat] then
		pos_functions[poscat].func(data, args)
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
local function handle_infl(data, args, field, label, generate_default, defgender, no_label, usually_no_label)
	local newinfls = parse_inflection(data, args, field, false)
	if not newinfls[1] and generate_default then
		newinfls = {{term = "+"}}
	end
	if generate_default then
		local saw_plus = false
		for _, newinfl in ipairs(newinfls) do
			if newinfl.term == "+" then
				saw_plus = true
				break
			end
		end
		if saw_plus then
			local newnewinfls = {}
			for _, newinfl in ipairs(newinfls) do
				if newinfl.term == "+" then
					if newinfl.tr then
						error("Can't specify translit for default value '+'")
					end
					local definfls = generate_default(data, args)
					for _, definfl in ipairs(definfls) do
						m_headword_utilities.combine_termobj_qualifiers_labels(definfl, newinfl)
						insert(newnewinfls, definfl)
					end
				else
					insert(newnewinfls, newinfl)
				end
			end
			newinfls = newnewinfls
		end
	end
	if newinfls[1] then
		if newinfls[1].term == "--" then
			if newinfls[2] then
				error("Can't specify more than one term if first term is '--', meaning \"don't insert anything\"")
			end
		else
			insert_inflection(data, newinfls, label, nil, defgender, field, no_label, usually_no_label)
		end
	end
end


-- Handle the case where pl=-, indicating an uncountable noun.
local function handle_noun_plural(data, args)
	if args.pl[1] and (args.pl[1] == "-" or args.pl[1]:find("^%-<")) then
		insert(data.categories, langname .. " uncountable nouns")
		if args.pauc and args.pauc[1] then
			error("Can't specify paucals when pl=-")
		end
	end
	handle_infl(data, args, "pl", "plural", nil, nil, "<<uncountable>>", "usually <<uncountable>>")
end

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

local function add_gender_params(params, default)
	params[2] = {type = "genders", default = default or "?"}
	params["g2"] = {replaced_by = false, instead = "use comma-separated values in |g="}
end

-- Handle gender in params 2=, g2=, etc., inserting into `data.genders`. Also, if a lemma, insert categories into
-- `data.categories` if the gender is unexpected for the form of the noun. (Note: If there are multiple genders,
-- [[Module:gender and number]] will automatically insert 'Arabic POS with multiple genders'.)
local function handle_gender(data, args, nonlemma)
	for _, gspec in ipairs(args[2]) do
		if not valid_genders[gspec.spec] then
			error("Unrecognized gender: " .. gspec.spec)
		end
	end

	data.genders = args[2]

	if nonlemma then
		return
	end

	for _, gspec in ipairs(data.genders) do
		local g = gspec.spec
		if is_masc_sg(g) or is_fem_sg(g) then
			local head = args[1][1]
			if head then
				head = rsub(ar.reorder_shadda(remove_links(head)), ar.UNUOPT .. "$", "")
				local ends_with_tam = rfind(head, "^[^ ]*" .. ar.TAM .. "$") or
						rfind(head, "^[^ ]*" .. ar.TAM .. " ")
				if is_masc_sg(g) and ends_with_tam then
					insert(data.categories, langname .. " masculine terms with feminine ending")
				elseif is_fem_sg(g) and not ends_with_tam and
						not rfind(head, "[" .. ar.ALIF .. ar.AMAQ .. "]$") and
						not rfind(head, ar.ALIF .. ar.HAMZA .. "$") then
					insert(data.categories, langname .. " feminine terms lacking feminine ending")
				end
			end
		end
	end
end

-- Part-of-speech functions

local adj_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "f", label = "feminine"},
	{field = "d", label = "masculine dual"},
	{field = "fd", label = "feminine dual"},
	{field = "cpl", label = "common plural"},
	{field = "pl", label = "masculine plural"},
	{field = "fpl", label = "feminine plural"},
}

local function create_infl_list_params(infl_list)
	params = {}
	for _, infl in ipairs(infl_list) do
		if infl.field == "*" then
			for _, spec in ipairs(nominal_inflections) do
				add_infl_params(params, spec.field)
			end
		else
			add_infl_params(params, infl.field)
		end
	end
	return params
end

local function handle_infl_list_args(data, args, infl_list)
	for _, infl in ipairs(infl_list) do
		if infl.handle then
			infl.handle(data, args)
		elseif infl.field == "*" then
			for _, spec in ipairs(nominal_inflections) do
				handle_infl(data, args, spec.field, spec.label, spec.generate_default)
			end
		else
			handle_infl(data, args, infl.field, infl.label, infl.generate_default)
		end
	end
end

pos_functions["adjectives"] = {
	params = (function()
		local params = create_infl_list_params(adj_inflections)
		add_infl_params(params, "el")
		return params
	end)(),
	func = function(data, args)
		handle_infl_list_args(data, args, adj_inflections)
		handle_infl(data, args, "el", "<<elative>>")
	end
}

local function make_default_with_ending(ending, endingtr)
	return function(data, args)
		local heads = data.heads
		if not heads[1] then
			heads = {{term = data.pagename}}
		end
		local forms = {}
		for i = 1, #heads do
			local tr = heads[i].tr
			insert(forms, {term = heads[i].term .. ending, tr = tr and tr .. endingtr or nil})
		end
		return forms
	end
end

local sound_adj_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "f", label = "feminine", generate_default = make_default_with_ending(ar.AH, "a")},
	{field = "d", label = "masculine dual"},
	{field = "fd", label = "feminine dual"},
	{field = "cpl", label = "common plural"},
	{field = "pl", label = "masculine plural", generate_default = make_default_with_ending(ar.UUNA, "ūna")},
	{field = "fpl", label = "feminine plural", generate_default = make_default_with_ending(ar.AAT, "āt")},
}

local function get_sound_adj_params()
	local params = create_infl_list_params(sound_adj_inflections)
	add_infl_params(params, "el")
	return params
end

local function handle_sound_adj_params(data, args)	
	data.pos_category = "adjectives"
	handle_infl_list_args(data, args, sound_adj_inflections)
	handle_infl(data, args, "el", "<<elative>>")
end

pos_functions["sound adjectives"] = {
	params = get_sound_adj_params(),
	func = handle_sound_adj_params,
}

-- Almost identical to sound adjective handling except for the nisba category.
pos_functions["nisba adjectives"] = {
	params = get_sound_adj_params(),
	func = handle_sound_adj_params,
	func = function(data, args)
		insert(data.categories, langname .. " relative adjectives (nisba)")
		handle_sound_adj_params(data, args)
	end
}

local sound_noun_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "pl", label = "plural", generate_default = make_default_with_ending(ar.UUNA, "ūna")},
	{field = "f", label = "feminine", generate_default = make_default_with_ending(ar.AH, "a")},
}

local function get_sound_noun_params()
	local params = create_infl_list_params(sound_noun_inflections)
	add_gender_params(params, "m")
	return params
end

local function handle_sound_noun_params(data, args, is_nisba)
	data.pos_category = "nouns"
	handle_gender(data, args)
	if is_nisba then
		insert(data.categories, langname .. " relative nouns (nisba)")
	end
	handle_infl_list_args(data, args, sound_noun_inflections)
end

pos_functions["sound nouns"] = {
	params = get_sound_noun_params(),
	func = handle_sound_noun_params,
}

-- Almost identical to sound adjective handling except for the nisba category.
pos_functions["nisba nouns"] = {
	params = get_sound_noun_params(),
	func = function(data, args)
		handle_sound_noun_params(data, args, "is_nisba")
	end
}

local sing_coll_noun_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "d", label = "dual"},
	{field = "pl", label = "plural", handle = handle_noun_plural},
	{field = "pauc", label = "<<paucal>>"},
}

local function handle_sing_coll_noun_infls(data, args, otherinfl, otherlabel, othergender)
	handle_gender(data, args)
	-- Handle sing= (corresponding singulative noun) or coll= (corresponding collective noun) and their gender
	handle_infl(data, args, otherinfl, otherlabel, nil, othergender)
	handle_infl_list_args(data, args, sing_coll_noun_inflections)
end

local function get_sing_coll_noun_params(defgender, otherinfl)
	local params = create_infl_list_params(sing_coll_noun_inflections)
	add_gender_params(params, defgender)
	add_infl_params(params, otherinfl)
	return params
end

pos_functions["collective nouns"] = {
	params = get_sing_coll_noun_params("m", "sing"),
	func = function(data, args)
		data.pos_category = "nouns"
		insert(data.categories, langname .. " collective nouns")
		m_headword_utilities.insert_fixed_inflection {
			headdata = data,
			label = "<<collective>>",
		}
		handle_sing_coll_noun_infls(data, args, "sing", "<<singulative>>", "f")
	end
}

pos_functions["singulative nouns"] = {
	params = get_sing_coll_noun_params("f", "coll"),
	func = function(data, args)
		data.pos_category = "nouns"
		insert(data.categories, langname .. " singulative nouns")
		m_headword_utilities.insert_fixed_inflection {
			headdata = data,
			label = "<<singulative>>",
		}
		handle_sing_coll_noun_infls(data, args, "coll", "<<collective>>", "m")
	end
}

local noun_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "d", label = "dual"},
	{field = "pl", label = "plural", handle = handle_noun_plural},
	{field = "pauc", label = "<<paucal>>"},
	{field = "f", label = "feminine"},
	{field = "m", label = "masculine"},
}

local function get_noun_params()
	local params = create_infl_list_params(noun_inflections)
	add_gender_params(params)
	return params
end

local function handle_noun_infls(data, args)
	handle_gender(data, args)
	handle_infl_list_args(data, args, noun_inflections)
end

pos_functions["nouns"] = {
	params = get_noun_params(),
	func = handle_noun_infls,
}

-- FIXME: Do numerals really behave almost as nouns? They vary by masc/fem.
pos_functions["numerals"] = {
	params = get_noun_params(),
	func = function(data, args)
		insert(data.categories, langname .. " cardinal numbers")
		handle_noun_infls(data, args)
	end
}

pos_functions["proper nouns"] = {
	params = get_noun_params(),
	func = handle_noun_infls,
}

local pronoun_inflections = {
	{field = "*"}, -- handle cons, def, obl, inf
	{field = "d", label = "dual"},
	{field = "pl", label = "plural"},
	{field = "f", label = "feminine"},
}

local function get_pronoun_params()
	local params = create_infl_list_params(pronoun_inflections)
	add_gender_params(params)
	return params
end

pos_functions["pronouns"] = {
	params = get_pronoun_params(),
	func = function(data, args)
		handle_gender(data, args)
		handle_infl_list_args(data, args, pronoun_inflections)
	end
}

local function get_gender_only_params(default)
	local params = {}
	add_gender_params(params, default)
	return params
end

pos_functions["noun plural forms"] = {
	params = (function()
		local params = {}
		add_gender_params(params, "p")
		add_infl_params(params, "cons")
		return params
	end)(),
	func = function(data, args)
		data.pos_category = "noun forms"
		handle_gender(data, args, "nonlemma")
		handle_infl(data, args, "cons", "<<construct state>>")
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
	params = get_gender_only_params("m-p"),
	func = function(data, args)
		data.pos_category = "adjective forms"
		handle_gender(data, args, "nonlemma")
	end
}

pos_functions["adjective dual forms"] = {
	params = get_gender_only_params("m-p"),
	func = function(data, args)
		data.pos_category = "adjective forms"
		handle_gender(data, args, "m-d", "nonlemma")
	end
}

pos_functions["noun forms"] = {
	params = get_gender_only_params(),
	func = function(data, args)
		handle_gender(data, args, nil, "nonlemma")
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
	params = {
		[2] = {},
	},
	func = function(data, args)
		handle_conj_form(data, args)
	end
}

local function get_participle_params()
	local params = create_infl_list_params(adj_inflections)
	params[2] = {}
	return params
end

pos_functions["active participles"] = {
	params = get_participle_params(),
	func = function(data, args)
		data.pos_category = "participles"
		insert(data.categories, langname .. " active participles")
		handle_conj_form(data, args)
		handle_infl_list_args(data, args, adj_inflections)
	end
}

pos_functions["passive participles"] = {
	params = get_participle_params(),
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
	params = {
		[1] = {},
		-- Comma-separated lists with possible inline modifiers
		["past"] = {},
		["past1s"] = {},
		["nonpast"] = {},
		["vn"] = {},
		["noautolinktext"] = {type = "boolean"},
		["noautolinkverb"] = {type = "boolean"},
	},
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

return export
