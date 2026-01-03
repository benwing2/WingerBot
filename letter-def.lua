-- Author: Benwing

local export = {}

local force_cat = false

local require_when_needed = require("Module:utilities/require when needed")

local ConvertNumeric_module = "Module:ConvertNumeric"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local JSON_module = "Module:JSON"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local string_utilities_module = "Module:string utilities"
local utilities_module = "Module:utilities"

local m_links = require(links_module)
local full_link = m_links.full_link
local m_string_utilities = require(string_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local lang_getByCode = require_when_needed(languages_module, "getByCode")
local format_categories = require_when_needed(utilities_module, "format_categories")

local uupper = m_string_utilities.upper
local ulower = m_string_utilities.lower
local insert = table.insert
local concat = table.concat

local function ine(val)
	if val == "" then return nil else return val end
end

local function ordinal_to_word(num)
	-- [[Module:ConvertNumeric]] is taken from Wikipedia and is one of the worst pieces of shit I've ever seen.
	-- For example, spell_number has 13 numbered params.
	return require(ConvertNumeric_module).spell_number(
		num,
		nil, -- numerator
		nil, -- denominator
		nil, -- capitalize
		true, -- use_and; mimics default behavior of {{ordinal to word}}, which includes supposedly British "and"
			  -- before the final number
		nil, -- hyphenate
		true -- ordinal
	)
end

--[==[
Implementation of {{tl|Latn-def}}, {{tl|Cyrl-def}} and the like. Supports the following invocation parameter:
; {{para|sc}}
: Specify the script code. If omitted, taken from the template parameter {{para|sc}}, which must be specified.
]==]
function export.show(frame)
	local list_param = {list = true, disallow_holes = true}
	local boolean_param = {type = "boolean"}
	local output = {}
	local function ins(txt)
		insert(output, txt)
	end
	local iargs = require(parameters_module).process(frame.args, {
		sc = {type = "script"},
	})
	local parent_args = frame:getParent().args
	local deftype = ine(parent_args[2])
	local deftypes = {"diacritic", "letter", "name", "ordinal", "syllable"}
	local params = {
		[1] = {type = "language", required = true, template_default = "und"},
		[2] = {set = deftypes},
		sc = {type = "script", required = not iargs.sc},
		nocap = boolean_param,
		dot = true,
		nodot = boolean_param,
	}
	local function merge_params(extra_params)
		for k, v in pairs(extra_params) do
			params[k] = v
		end
	end
	if deftype == "name" then
		merge_params {
			[3] = {required = true},
			[4] = true,
			onecase = boolean_param, -- FIXME: pointless param
			["alphabet name"] = true,
			t = true,
			trans = {alias_of = "t"},
		}
	elseif deftype == "letter" then
		merge_params {
			[3] = {type = "number"},
			[4] = list_param,
			indef = boolean_param,
			["alphabet name"] = true,
		}
	elseif deftype == "diacritic" then
		merge_params {
			[3] = list_param,
			name = list_param,
			noname = boolean_param,
			nopairs = boolean_param,
			t = {list = true, allow_holes = true},
			trans = {alias_of = "t", list = true, allow_holes = true},
		}
	elseif deftype == "ordinal" then
		merge_params {
			[3] = {required = true},
			[4] = list_param,
		}
	elseif deftype == "syllable" then
		merge_params {
			[3] = {required = true},
			[4] = {required = true},
			[5] = {required = true},
		}
	else
		local possible_deftypes = "'name', 'letter', 'diacritic', 'ordinal' or 'syllable'"
		if deftype then
			error(("Invalid value '%s' for 2=, should be one of %s"):format(deftype, possible_deftypes))
		else
			error(("Missing value for 2=, should be one of %s"):format(possible_deftypes))
		end
	end
	local args = require(parameters_module).process(parent_args, params)
	local lang = args[1]
	local sc = args.sc or iargs.sc
	local scname = sc:getCanonicalName()
	local sccatname = sc:getCategoryName()
	local scdisplay = sc:getDisplayForm()
	local categories = {}
	ins("<span class='use-with-mention'>")
	if deftype == "name" then
		ins(args.nocap and "the" or "The")
		ins((" name of the [[Appendix:%s|%s]] letter "):format(sccatname, (scdisplay:gsub(" ", "-"))))
		ins(full_link({ lang = lang, term = args[3], tr = "-", sc = sc}, "term"))
		if args[4] and not args.onecase then
			ins("/")
			ins(full_link({lang = lang, term = args[4], tr = "-", sc = sc}, "term"))
		end
		local alphabet_name = args["alphabet name"]
		if alphabet_name then
			ins(", in " .. alphabet_name)
		end
		if args.t then
			ins(", called ")
			ins(full_link({lang = lang_getByCode("en", true), term = args.t}, "term"))
			ins(" in English")
		end
		insert(categories, ("%s:%s letter names"):format(lang:getFullCode(), scname))

	elseif deftype == "letter" then
		ins(args.nocap and (args.indef and "a" or "the") or (args.indef and "A" or "The"))
		if args[3] then
			ins(" ")
			ins(ordinal_to_word(args[3]))
		end
		ins(" [[letter]] of the ")
		ins(lang:getCanonicalName())
		ins(" [[alphabet]]")
		local alphabet_name = args["alphabet name"]
		if alphabet_name then
			ins(" (" .. alphabet_name .. ")")
		end
		ins(", ")
		if args[4][1] then
			ins("called ")
			local formatted_names = {}
			for _, name in ipairs(args[4]) do
				insert(formatted_names, full_link({lang = lang, term = name}, "term"))
			end
			ins(mw.text.listToText(formatted_names, nil, " or "))
			ins(" and ")
		end
		ins(("written in the [[Appendix:%s|%s]]"):format(sccatname, sccatname))

	elseif deftype == "diacritic" then
		ins(args.nocap and "a" or "A")
		ins((" [[diacritical mark]] of the [[Appendix:%s|%s]]"):format(sccatname, sccatname))
		if not args.noname and args.name[1] then
			ins(", called ")
			local formatted_names = {}
			for i, name in ipairs(args.name) do
				insert(formatted_names, full_link({lang = lang, term = name, gloss = args.t[i]}, "term"))
			end
			ins(mw.text.listToText(formatted_names, nil, " or "))
		end
		ins(" in ")
		ins(lang:getCanonicalName())
		ins(", and found on ")
		local formatted_letters = {}
		local function format_letter(letter)
			return ("<span class='mention'>%s</span>"):format(full_link {lang = lang, term = letter, sc = sc})
		end
		if args.nopairs then
			for _, letter in ipairs(args[3]) do
				insert(formatted_letters, format_letter(letter))
			end
		elseif #args[3] % 2 == 1 then
			error(("Saw %s letters but need an even number when nopairs= is not given"):format(#args[3]))
		else
			for i = 1, #args[3], 2 do
				insert(formatted_letters, ("%s/%s"):format(format_letter(args[3][i]), format_letter(args[3][i + 1])))
			end
		end
		ins(mw.text.listToText(formatted_letters))

	elseif deftype == "ordinal" then
		ins(args.nocap and "the" or "The")
		ins((" [[ordinal]] number '''[[%s]]''', derived from this letter of the "):format(ordinal_to_word(args[3])))
		ins(lang:getCanonicalName())
		ins( " [[alphabet]], called ")
		local formatted_names = {}
		for _, name in ipairs(args[4]) do
			insert(formatted_names, full_link({lang = lang, term = name}, "term"))
		end
		ins(mw.text.listToText(formatted_names, nil, " or "))
		ins((" and written in the [[Appendix:%s|%s]]"):format(sccatname, sccatname))
		insert(categories, ("%s ordinal numbers"):format(lang:getFullName()))

	elseif deftype == "syllable" then
		ins(args.nocap and "the " or "The ")
		if args[3] ~= "-" then
			ins("[[Appendix:Hiragana script|hiragana]] syllable ")
			ins(full_link({lang = lang, term = args[3], tr = args[5]}, "term"))
			ins(" or the ")
		end
		ins("[[Appendix:Katakana script|katakana]] syllable ")
		ins(full_link({lang = lang, term = args[4], tr = args[5]}, "term"))
		ins(" in [[Hepburn]] romanization")

	else
		error(("Internal error: Unhandled deftype %s"):format(mw.dumpObject(deftype)))
	end
	if args.dot then
		ins(args.dot)
	elseif not args.nodot then
		ins(".")
	end
	ins("</span>")
	if categories[1] then
		ins(format_categories(categories, lang, nil, nil, force_cat))
	end
	return concat(output)
end

return export
