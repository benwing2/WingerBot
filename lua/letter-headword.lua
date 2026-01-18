local export = {}

local force_cat = false

local require_when_needed = require("Module:utilities/require when needed")

local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local JSON_module = "Module:JSON"
local languages_module = "Module:languages"
local parameters_module = "Module:parameters"
local scripts_module = "Module:scripts"
local table_module = "Module:table"

local m_string_utilities = require("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local deep_equals = require_when_needed(table_module, "deepEquals")
local shallow_copy = require_when_needed(table_module, "shallowCopy")

local uupper = m_string_utilities.upper
local ucfirst = m_string_utilities.ucfirst
local ulower = m_string_utilities.lower
local ulen = m_string_utilities.len
local insert = table.insert

local per_language_defaults = {
	de = {g = "n"},
	en = {pl_ending = "s,'s"},
	it = {g = "f,m", pl_ending = "_"},
	pt = {g = "m"},
}

local function ine(val)
	if not val then
		return val
	end
	val = mw.text.trim(val)
	if val == "" then return nil else return val end
end

local function add_initial_colon_to_term(term)
	if term ~= "-" and term ~= "+" and not term:find("^:") then
		-- Make sure we link to the specified term even if it has a diacritic that would normally be stripped off.
		term = ":" .. term
	end
	return term
end

local function resolve_plus(termobjs, default, paramname)
	local saw_plus = false
	for _, termobj in ipairs(termobjs) do
		if termobj.term == "+" then
			saw_plus = true
			break
		end
	end
	if not saw_plus then
		return termobjs
	end
	if not default then
		error(("Saw '+' for param '%s' but no default available"):format(paramname))
	end
	if type(default) == "string" then
		for _, termobj in ipairs(termobjs) do
			if termobj.term == "+" then
				termobj.term = default
			end
		end
		return termobjs
	end
	if type(default) ~= "table" then
		error("Internal error: `default` should be nil, string or list of strings")
	end

	local resolved_termobjs = {}
	for _, termobj in ipairs(termobjs) do
		if termobj.term == "+" then
			for _, defval in ipairs(default) do
				defval = shallow_copy(defval)
				require(headword_utilities_module).combine_termobj_qualifiers_labels(defval, termobj)
				insert(resolved_termobjs, defval)
			end
		else
			insert(resolved_termobjs, termobj)
		end
	end
	return resolved_termobjs
end

local function parse_equivalent(value, default, paramname, no_prefix_colon)
	if not value then
		return nil
	end
	local termobjs
	if value == "+" then
		-- optimization to avoid loading [[Module:headword utilities]]
		if not default then
			error(("Saw '+' for param '%s' but no default available"):format(paramname))
		end
		if type(default) == "string" then
			termobjs = {{term = default}}
		else
			if type(default) ~= "table" then
				error("Internal error: `default` should be nil, string or list of term objects")
			end
			termobjs = default
		end
	elseif value:find("[,<]") then
		termobjs = require(headword_utilities_module).parse_term_with_modifiers {
			val = value,
			paramname = paramname,
			splitchar = ",",
			include_mods = {"tr", "ts", "t", "sc"},
		}
	else
		termobjs = {{ term = value }}
	end
	termobjs = resolve_plus(termobjs, default, paramname)
	for _, termobj in ipairs(termobjs) do
		if not no_prefix_colon then
			termobj.term = add_initial_colon_to_term(termobj.term)
		end
		termobj.tr = "-"
	end
	return termobjs
end

--[==[
Implementation of the letter headword template for a given language (e.g. {{tl|en-letter}}, {{tl|it-letter}} or
{{tl|sh-letter}}). Supports the following invocation parameters:
; {{para|pos}}
: The plural part of speech to use; defaults to {{cd|letters}}. Other possibilities are e.g. {{cd|numeral symbols}} for
numeral symbols (letters used for list items).
; {{para|lang}}
: The language code of the language of the headword template. Omit for language-agnostic {{tl|letter}}.
; {{para|sc}}
: Specify the default script code. Rarely needs to be given.
; {{para|g}}
: Specify the default gender(s) of the letter. Multiple comma-separated values are allowed, along with qualifier, label
  and reference inline modifiers. See [[Module:gender and number]] for more information, including the allowed values.
  The default(s) can be overridden using the {{para|g}} template parameter.
; {{para|pl_ending}} ...
: Specify the default ending(s) of the plural form(s) of the letter. Multiple items should be comma-separated, and
  qualifier, label, reference, transliteration and gloss inline modifiers are allowed. Use the value {{cd|_}} to
  indicate a null ending. The default(s) can be overridden using the {{para|pl}} template parameter.
; {{para|allow_tr|1}}
: Specify that the template allows the {{para|tr}} parameter to be given for specifying transliteration.
]==]
function export.show(frame)
	local list_param = {list = true, disallow_holes = true}
	local boolean_param = {type = "boolean"}
	local frame_args = frame.args
	local parent_args = frame:getParent().args

	-- Extract language and any per-language defaults. If they exist, clone the frame args and set the defaults into the
	-- frame args before parsing. If there is no language specified at either the invocation or template level, we'll
	-- get an error later.
	local lang = ine(frame_args.lang) or ine(parent_args[1])
	if lang and per_language_defaults[lang] then
		local cloned_frame_args = {}
		for k, v in pairs(frame_args) do
			cloned_frame_args[k] = v
		end
		local defaults = per_language_defaults[lang]
		for k, v in pairs(defaults) do
			if cloned_frame_args[k] == nil then
				cloned_frame_args[k] = v
			end
		end
		frame_args = cloned_frame_args
	end

	local iargs = require(parameters_module).process(frame_args, {
		pos = {default = "letters"},
		lang = {type = "language", template_default = "und"},
		sc = {type = "script"},
		g = {type = "genders"},
		pl_ending = true,
		allow_tr = boolean_param,
	})
	local allowed_types = {"upper", "lower", "mixed", "allcaps", "nocase"}
	local params = {
		g = {type = "genders"},
		sc = {type = "script"},
		type = {set = allowed_types},
		head = list_param,
		upper = true,
		lower = true,
		mixed = true,
		allcaps = true,
		pl = true,
		nopl = boolean_param,
		id = true,
		sort = true,
		pagename = true,
		modern = true,
	}
	local langparam, otherparam
	if not iargs.lang then
		langparam = 1
		otherparam = 2
		params[langparam] = {type = "language", required = true, template_default = "und"}
	else
		otherparam = 1
	end
	params[otherparam] = list_param
	if iargs.g and iargs.g[1] then
		params.nog = boolean_param
	end
	if iargs.allow_tr or not iargs.lang then
		params.tr = list_param
	end
	if not iargs.lang then
		params.ts = list_param
	end
	local args = require(parameters_module).process(parent_args, params)
	local others = {}

	for i, otherspec in ipairs(args[otherparam]) do
		local lang_sc, rest = otherspec:match("^([a-zA-Z0-9-]+):([^ ].*)$")
		if not lang_sc then
			error(("Expected other-lang or other-script param %s=%s to begin with a language code or script code followed by a colon and no space"):format(i + otherparam - 1, otherspec))
		end
		local obj = require(scripts_module).getByCode(lang_sc)
		local objtype
		if obj then
			objtype = "script"
		else
			obj = require(languages_module).getByCode(lang_sc, nil, "allow etym")
			if obj then
				objtype = "language"
			else
				error(("Unrecognized language or script '%s' in %s=%s"):format(lang_sc, i + otherparam - 1, otherspec))
			end
		end
		insert(others, {
			obj = obj,
			objtype = objtype,
			value = rest,
		})
	end

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename
	if args.type then
		if args.type ~= "upper" and args.type ~= "lower" and args.type ~= "mixed" and args.type ~= "nocase" then
			error(("Unrecognized value for type '%s'; should be one of 'upper', 'lower', 'mixed' or 'nocase'"):format(
				args.type))
		end
	end
	local lang = langparam and args[langparam] or iargs.lang
	local sc = args.sc or iargs.sc or lang:findBestScript(pagename)
	
	local data = {
		lang = lang,
		sc = sc,
		pos_category = iargs.pos,
		categories = {},
		pagename = pagename,
		inflections = {},
		id = args.id,
		sort_key = args.sort,
		heads = args.head,
		translits = args.tr,
		transcriptions = args.ts,
		force_cat_output = force_cat,
		genders = not args.nog and (args.g and args.g[1] and args.g or iargs.g) or nil,
		categories = {},
		-- Disable "terms with redundant script codes" and "terms with non-redundant manual script codes"
		-- categories. We always specify the script and the categories simply aren't useful in this case; having
		-- them just clutters the categories with letter entries.
		no_script_code_cat = true,
	}
	-- All letters can also be used as nouns ("There are two f's in that word").
	insert(data.categories, lang:getFullName() .. " nouns")
	if sc:getCode() ~= "None" then
		insert(data.categories, sc:getCategoryName() .. " characters")
	end
	local uppage = uupper(pagename)
	local lopage = ulower(pagename)
	local ucfirstpage = ucfirst(lopage)

	local function insert_inflection(termobjs, label)
		if not termobjs or not termobjs[1] then
			return
		end
		if termobjs[1].term == "-" then
			require(headword_utilities_module).insert_inflection {
				headdata = data,
				terms = termobjs,
				label = label,
			}
		else
			termobjs.label = label
			insert(data.inflections, termobjs)
		end
	end

	local typ = args.type
	if not typ then
		if uppage == lopage then
			typ = "nocase"
		elseif data.pagename == ucfirstpage then
			typ = "upper"
		elseif data.pagename == uppage then
			typ = "allcaps"
		elseif data.pagename == lopage then
			typ = "lower"
		else
			typ = "mixed"
		end
	end

	if typ == "nocase" then
		if args.upper or args.lower or args.mixed or args.allcaps then
			error("Can't specify upper=, lower=, mixed= or allcaps= when letter has no case")
		end
		insert(data.inflections, {label = "no case"})
	else
		local upper = parse_equivalent(args.upper or "+", ucfirstpage, "upper")
		local lower = parse_equivalent(args.lower or "+", lopage, "lower")
		local allcaps = parse_equivalent(args.allcaps or ulen(pagename) == 1 and args.upper or "+", uppage, "allcaps")
		local mixed = parse_equivalent(args.mixed, nil, "mixed")
		local pagenameobj = {{term = ":" .. pagename, tr = "-"}}
		if typ == "upper" then
			if args.upper then
				error("Already uppercase; can't specify upper=")
			end
			insert(data.inflections, {label = "[[Appendix:Capital letter|upper case]]"})
			insert_inflection(lower, "lower case")
			if not deep_equals(pagenameobj, allcaps) then
				insert_inflection(allcaps, "[[Appendix:Capital letter|all caps]]")
			end
			insert_inflection(mixed, "mixed case")
		elseif typ == "lower" then
			if args.lower then
				error("Already lowercase; can't specify lower=")
			end
			insert(data.inflections, {label = "lower case"})
			if deep_equals(upper, allcaps) then
				if ulen(pagename) == 1 then
					insert_inflection(upper, "[[Appendix:Capital letter|upper case]]")
				else
					insert_inflection(upper, "[[Appendix:Capital letter|upper case]] and all caps")
				end
			else
				insert_inflection(upper, "[[Appendix:Capital letter|upper case]]")
				insert_inflection(allcaps, "[[Appendix:Capital letter|all caps]]")
			end
			insert_inflection(mixed, "mixed case")
		elseif typ == "allcaps" then
			if args.allcaps then
				error("Already all-caps; can't specify allcaps=")
			end
			insert(data.inflections, {label = "[[Appendix:Capital letter|all caps]]"})
			if not deep_equals(pagenameobj, upper) then
				insert_inflection(upper, "[[Appendix:Capital letter|upper]]")
			end
			insert_inflection(lower, "lower case")
			insert_inflection(mixed, "mixed case")
		else
			if args.mixed then
				error("Already mixed-case; can't specify mixed=")
			end
			insert(data.inflections, {label = "mixed case"})
			insert_inflection(lower, "lower case")
			if deep_equals(upper, allcaps) then
				insert_inflection(upper, "[[Appendix:Capital letter|upper case]] and all caps")
			else
				insert_inflection(upper, "[[Appendix:Capital letter|upper case]]")
				insert_inflection(allcaps, "[[Appendix:Capital letter|all caps]]")
			end
		end
	end
	if args.nopl then
		insert(data.inflections, {label = "no plural"})
	elseif args.pl or iargs.pl_ending then
		local default_pls
		if iargs.pl_ending then
			default_pls = parse_equivalent(iargs.pl_ending, nil, "pl_ending", "no_prefix_colon")
			for _, pl_ending in ipairs(default_pls) do
				if pl_ending.term == "_" then
					pl_ending.term = pagename
				else
					pl_ending.term = pagename .. pl_ending.term
				end
			end
		end
		local pls = parse_equivalent(args.pl or "+", default_pls, "pl")
		if not pls[2] and pls[1].term == ":" .. pagename then
			require(headword_utilities_module).insert_fixed_inflection {
				headdata = data,
				originating_term = pls[1],
				label = glossary_link("invariable"),
			}
		else
			insert_inflection(pls, "plural")
		end
	end

	if args.modern then
		local termobjs = parse_equivalent(args.modern, nil, "modern")
		insert_inflection(termobjs, "modern equivalent")
	end
		
	if others[1] then
		for _, other in ipairs(others) do
			local termobjs = parse_equivalent(other.value, nil, other.obj:getCode())
			for _, termobj in ipairs(termobjs) do
				if other.objtype == "language" then
					termobj.lang = other.obj
				else
					termobj.sc = other.obj
				end
			end
			insert_inflection(termobjs, other.obj:getCanonicalName() .. " equivalent")
		end
	end

    if args.json then
        return require(JSON_module).toJSON(data)
    end
	return require(headword_module).full_headword(data)
end

--[==[
Documentation generation function, used to populate the documentation describing all parameters of {{tl|letter}} and language-specific variants such as {{tl|en-letter}}. Supports the following invocation parameters:
; {{para|lang}}
: The language code of the language of the headword template being documented. Omit for language-agnostic {{tl|letter}}.
; {{para|default_pl|1}}
: Specify that the template provides default plural(s) of the letter.
; {{para|default_g|1}}
: Specify that the template provides default gender(s) of the letter.
; {{para|allow_tr|1}}
: Specify that the template allows the {{para|tr}} parameter to be given for specifying transliteration.
]==]
function export.doctext(frame)
	local boolean_param = {type = "boolean"}
	local iparams = {
		lang = {type = "language"},
		default_pl = boolean_param,
		default_g = boolean_param,
		allow_tr = boolean_param,
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	local prelude
	if iargs.lang then
		prelude = ("This template should be used to generate the headword line for %s letters. '''Most of the time, no parameters are needed.'''"):format(
			iargs.lang:getCanonicalName())
	else
		prelude = "This template should be used to generate the headword line for letters in a specified language. '''Most of the time, only the language code needs to be specified.'''"
	end

	local text = prelude .. [=[

==Parameters==
The following parameters are supported:
]=] .. (iargs.lang and "" or [=[
;{{para|1|req=1}}
: Language code (see {{slink|WT:Languages#Language codes}}) for the language of the letter.]=] .. "\n") .. [=[
;{{para|type}}
: Explicitly specify the case of the letter: {{cd|upper}}, {{cd|lower}}, {{cd|allcaps}} (for all-capital-letter ]=] ..
[=[combinations of two or more characters whose normal uppercase version has only the first character ]=] ..
[=[capitalized, {{cd|mixed}} (for the rare case of a mixture of uppercase and lowercase letters in a digraph ]=] ..
[=[that is not the uppercase form) or {{cd|nocase}} (for letters without case). This usually does not need to be ]=] ..
[=[given, as it is autodetected; but some lowercase or uppercase characters need it because Unicode does not ]=] ..
[=[correctly register the character as having case.
;{{para|upper}}
: Explicitly specify the uppercase equivalent(s) of a lowercase or mixed-case letter. Cannot be specified for
  already-uppercase or caseless letters. ]=] ..
	[=[This rarely needs to be given as it is normally auto-generated by uppercasing the pagename.
;{{para|lower}}
: Explicitly specify the lowercase equivalent(s) of an uppercase or mixed-case letter. Cannot be specified for already-lowercase or caseless letters. ]=] ..
	[=[This rarely needs to be given as it is normally auto-generated by lowercasing the pagename.
;{{para|mixed}}
: Explicitly specify the mixed-case equivalent(s) of an uppercase or lowercase letter. Cannot be specified for already mixed-case or caseless letters.
;{{para|pl}}
: Explicitly specify the plural(s) of the letter.]=] .. (iargs.default_pl and " This overrides the default value(s) provided by the template " ..
	"and normally does not need to be given as letter plurals are largely the same for all letters. A value of {{cd|+}} explicitly requests " ..
	"the default value(s)." or "") .. "\n" .. [=[
;{{para|nopl|1}}
: Specify that the letter does not have a plural form.
;{{para|g}}
: Explicitly specify the gender(s) of the letter. Multiple comma-separated values are allowed, along with qualifier, label and reference ]=] ..
	[=[inline modifiers. See [[Module:gender and number]] for more information, including the allowed values.]=] ..
	(iargs.default_g and " This overrides the default value(s) provided by the template " ..
	"and normally does not need to be given as letter genders are largely the same for all letters." or "") .. "\n" .. (iargs.default_g and [=[
;{{para|nog|1}}
: Cancel out the default gender(s) of the letter specified by the template without supplying any gender. No gender will be shown.
]=] or "") .. [=[
;{{para|sc}}
: Specify an explicit value for the script of the letter. Rarely necessary as the script is autodetected.
;{{para|id}}
: Specify a sense ID (see {{tl|senseid}}) for linking to this particular sense/part of speech of the term using the {{para|id}} parameter ]=] ..
	[=[of {{tl|l}}, {{tl|m}} and the like. Useful when the entry also has meanings other than as a letter.]=] .. "\n" ..
	((iargs.allow_tr or not iargs.lang) and [=[
;{{para|tr}}, {{para|tr2}}, ...
: Specify transliteration(s) of the letter, for letters not in the Latin script. Not usually necessary, as most languages have automatic ]=] ..
	[=[transliteration, which is usually correct.]=] .. "\n" or "") .. [=[
;{{para|pagename}}
:Override the pagename, for use on documentation or test pages.
;{{para|sort}}
: Sort key. Rarely needs to be specified, as it is normally automatically generated.
;{{para|json|1}}
: Output the headword data in JSON form instead of the normal output. For testing purposes.
]=]
	-- Remove final newline so template code can add a newline after invocation
	text = text:gsub("\n$", "")
	return mw.getCurrentFrame():preprocess(text)
end

return export
