local export = {}

local m_languages = require("Module:languages")
local m_demonym = require("Module:demonym")
local parameter_utilities_module = "Module:parameter utilities"
local parse_interface_module = "Module:parse interface"


local function parse_args(args, hack_params)
	local params = {
		[1] = {required = true, default = "und"},
		[2] = {list = true, required = true},
		
		["t"] = {list = true},
		["sort"] = {},
		["nocat"] = {type = "boolean"},
		["nocap"] = {type = "boolean"},
		["nodot"] = {type = "boolean"},
		["notext"] = {type = "boolean"},
	}

	if hack_params then
		hack_params(params)
	end

	args = require("Module:parameters").process(args, params)
	local lang = m_languages.getByCode(args[1], 1)
	return args, lang
end


local function parse_term_with_modifiers(paramname, val)
	local m_parameter_utilities = require(parameter_utilities_module)
    local param_mods = m_parameter_utilities.construct_param_mods {
        {group = {"link", "q", "l", "ref"}},
    }

	local function generate_obj(term, parse_err)
		return m_parameter_utilities.generate_obj_maybe_parsing_lang_prefix {
			term = term,
			paramname = paramname,
			parse_lang_prefix = true,
			parse_err = parse_err,
		}
	end

	return require(parse_interface_module).parse_inline_modifiers(val, {
		paramname = paramname,
		param_mods = param_mods,
		generate_obj = generate_obj,
	})
end


local function get_terms_and_glosses(args)
	for i, term in ipairs(args[2]) do
		args[2][i] = parse_term_with_modifiers(i + 1, term)
	end
	for i, gloss in ipairs(args.t) do
		args.t[i] = parse_term_with_modifiers("t" .. (i == 1 and "" or i), gloss)
	end

	return args[2], args.t
end


function export.demonym_adj(frame)
	local args, lang = parse_args(frame:getParent().args)

	local terms, glosses = get_terms_and_glosses(args)

	return m_demonym.format_demonym_adj {
		lang = lang,
		parts = terms,
		gloss = glosses,
		sort = args.sort,
		nocat = args.nocat,
		nocap = args.nocap,
		nodot = args.nodot,
		notext = args.notext,
	}
end


function export.demonym_noun(frame)
	local function hack_params(params)
		params.g = {}
		params.m = {list = true}
		params.gloss_is_gendered = {type = "boolean"}
	end

	local args, lang = parse_args(frame:getParent().args, hack_params)

	local terms, glosses = get_terms_and_glosses(args)

	for i, m in ipairs(args.m) do
		args.m[i] = parse_term_with_modifiers("m" .. (i == 1 and "" or i), m)
	end

	return m_demonym.format_demonym_noun {
		lang = lang,
		parts = terms,
		gloss = glosses,
		m = args.m,
		g = args.g,
		sort = args.sort,
		nocat = args.nocat,
		nocap = args.nocap,
		nodot = args.nodot,
		notext = args.notext,
		gloss_is_gendered = args.gloss_is_gendered,
	}
end


return export
