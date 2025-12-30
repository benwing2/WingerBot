local export = {}

local force_cat = false

local require_when_needed = require("Module:utilities/require when needed")

local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local JSON_module = "Module:JSON"
local parameters_module = "Module:parameters"

local m_string_utilities = require("Module:string utilities")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local uupper = m_string_utilities.upper
local ulower = m_string_utilities.lower
local insert = table.insert

--[==[
Implementation of the letter headword template for a given language (e.g. {{tl|en-letter}}, {{tl|it-letter}} or {{tl|sh-letter}}).
Supports the following invocation parameters:
; {{para|lang}}
: The language code of the language of the headword template. Omit for language-agnostic {{tl|letter}}.
; {{para|sc}}
: Specify the default script code. Rarely needs to be given.
; {{para|g}}
: Specify the default gender(s) of the letter. Multiple comma-separated values are allowed, along with qualifier, label and reference
  inline modifiers. See [[Module:gender and number]] for more information, including the allowed values. The default(s) can be overridden
  using the {{para|g}} template parameter.
; {{para|pl_ending}}, {{para|pl_ending2}}, ...
: Specify the default ending(s) of the plural form(s) of the letter. Use the value {{cd|_}} to indicate a null ending. The default(s) can be overridden
  using the {{para|pl}}, {{para|pl2}}, ... template parameters.
; {{para|allow_tr|1}}
: Specify that the template allows the {{para|tr}} parameter to be given for specifying transliteration.
]==]
function export.show(frame)
	local list_param = {list = true, disallow_holes = true}
	local boolean_param = {type = "boolean"}
	local iargs = require(parameters_module).process(frame.args, {
		lang = {type = "language", template_default = "und"},
		sc = {type = "script"},
		g = {type = "genders"},
		pl_ending = list_param,
		allow_tr = boolean_param,
	})
	local parent_args = frame:getParent().args
	local params = {
		g = {type = "genders"},
		sc = {type = "script"},
		type = true,
		upper = list_param,
		lower = list_param,
		mixed = list_param,
		pl = list_param,
		nopl = boolean_param,
		id = true,
		sort = true,
		pagename = true,
	}
	if not iargs.lang then
		params[1] = {type = "language", required = true, template_default = "und"}
	end
	if iargs.g and iargs.g[1] then
		params.nog = boolean_param
	end
	if iargs.allow_tr or not iargs.lang then
		params.tr = list_param
	end
	local args = require(parameters_module).process(parent_args, params)
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename
	if args.type then
		if args.type ~= "upper" and args.type ~= "lower" and args.type ~= "mixed" and args.type ~= "nocase" then
			error(("Unrecognized value for type '%s'; should be one of 'upper', 'lower', 'mixed' or 'nocase'"):format(
				args.type))
		end
	end
	local lang = args[1] or iargs.lang
	local sc = args.sc or iargs.sc or lang:findBestScript(pagename)
	
	local data = {
		lang = lang,
		sc = sc,
		pos_category = "letters",
		categories = {},
		pagename = pagename,
		inflections = {},
		id = args.id,
		sort_key = args.sort,
		translits = args.tr,
		force_cat_output = force_cat,
		genders = not args.nog and (args.g and args.g[1] and args.g or iargs.g) or nil,
		categories = {},
	}
	if sc:getCode() ~= "None" then
		insert(data.categories, sc:getCategoryName() .. " characters")
	end
	local uppage = uupper(pagename)
	local lopage = ulower(pagename)
	local function resolve_plus(values, default, label)
		local saw_plus = false
		for _, value in ipairs(values) do
			if value == "+" then
				saw_plus = true
				break
			end
		end
		if saw_plus then
			local resolved_values = {}
			for _, value in ipairs(values) do
				if value == "+" then
					if type(default) == "table" then
						for _, defval in ipairs(default) do
							insert(resolved_values, defval)
						end
					elseif type(default) == "string" then
						insert(resolved_values, default)
					else
						error(("Saw '+' for label '%s' but no default available"):format(label))
					end
				else
					insert(resolved_values, value)
				end
			end
			values = resolved_values
		end
		return values
	end
		
	local function insert_inflection(explicit, default, label)
		local values
		if explicit[1] then
			values = resolve_plus(explicit, default, label)
		elseif type(default) == "table" then
			values = default
		elseif type(default) == "string" then
			values = {default}
		else
			return
		end
		values.label = label
		insert(data.inflections, values)
	end
	local typ = args.type
	if not typ then
		if uppage == lopage then
			typ = "nocase"
		elseif data.pagename == uppage then
			typ = "upper"
		elseif data.pagename == lopage then
			typ = "lower"
		else
			typ = "mixed"
		end
	end
			
	if typ == "nocase" then
		if args.upper[1] or args.lower[1] or args.mixed[1] then
			error("Can't specify upper=, lower= or mixed= when letter has no case")
		end
		insert(data.inflections, {label = "no case"})
	elseif typ == "upper" then
		if args.upper[1] then
			error("Already uppercase; can't specify upper=")
		end
		insert(data.inflections, {label = "[[Appendix:Capital letter|upper case]]"})
		insert_inflection(args.lower, lopage, "lower case")
		insert_inflection(args.mixed, nil, "mixed case")
	elseif typ == "lower" then
		if args.lower[1] then
			error("Already lowercase; can't specify lower=")
		end
		insert(data.inflections, {label = "lower case"})
		insert_inflection(args.upper, uppage, "upper case")
		insert_inflection(args.mixed, nil, "mixed case")
	else
		if args.mixed[1] then
			error("Already mixed-case; can't specify mixed=")
		end
		insert(data.inflections, {label = "mixed case"})
		insert_inflection(args.upper, uppage, "upper case")
		insert_inflection(args.lower, lopage, "lower case")
	end
	if args.nopl then
		insert(data.inflections, {label = "no plural"})
	elseif args.pl[1] or iargs.pl_ending[1] then
		local default_pls
		if iargs.pl_ending[1] then
			default_pls = {}
			for _, pl_ending in ipairs(iargs.pl_ending) do
				if pl_ending == "_" then
					insert(default_pls, pagename)
				else
					insert(default_pls, pagename .. pl_ending)
				end
			end
		end
		local pls = args.pl
		if not pls[1] then
			pls = {"+"}
		end
		pls = resolve_plus(pls, default_pls, "plural")
		if not pls[2] and pls[1] == pagename then
			insert(data.inflections, {label = glossary_link("invariable")})
		else
			insert_inflection(pls, default_pls, "plural")
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
: Explicitly specify the case of the letter: {{cd|upper}}, {{cd|lower}}, {{cd|mixed}} (for combinations of two or more characters treated as ]=] ..
	[=[a distinct letter where the letter has separate uppercase and lowercase forms, such as Vietnamese {{m|es|Ch}}) or {{cd|nocase}} ]=] ..
	[=[(for letters without case). This rarely needs to be given as it is autodetected.
;{{para|upper}}, {{para|upper2}}, ...
: Explicitly specify the uppercase equivalent(s) of a lowercase or mixed-case letter. Cannot be specified for already-uppercase or caseless letters. ]=] ..
	[=[This rarely needs to be given as it is normally auto-generated by uppercasing the pagename.
;{{para|lower}}, {{para|lower2}}, ...
: Explicitly specify the lowercase equivalent(s) of an uppercase or mixed-case letter. Cannot be specified for already-lowercase or caseless letters. ]=] ..
	[=[This rarely needs to be given as it is normally auto-generated by lowercasing the pagename.
;{{para|mixed}}, {{para|mixed2}}, ...
: Explicitly specify the mixed-case equivalent(s) of an uppercase or lowercase letter. Cannot be specified for already mixed-case or caseless letters.
;{{para|pl}}, {{para|pl2}}, ...
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
