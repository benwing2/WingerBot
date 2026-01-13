-- Author: Benwing

local export = {}

local force_cat = false

local require_when_needed = require("Module:utilities/require when needed")

local ConvertNumeric_module = "Module:ConvertNumeric"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local scripts_module = "Module:scripts"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local utilities_module = "Module:utilities"

local m_links = require(links_module)
local full_link = m_links.full_link
local m_string_utilities = require(string_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local lang_getByCode = require_when_needed(languages_module, "getByCode")
local format_categories = require_when_needed(utilities_module, "format_categories")
local serial_comma_join = require_when_needed(table_module, "serialCommaJoin")

local uupper = m_string_utilities.upper
local ulower = m_string_utilities.lower
local ufind = m_string_utilities.find
local insert = table.insert
local concat = table.concat

local function ine(val)
	if not val then
		return val
	end
	val = mw.text.trim(val)
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

local function add_initial_colon_to_term(term)
	if term ~= "-" and term ~= "+" and not term:find("^:") then
		-- Make sure we link to the specified term even if it has a diacritic that would normally be stripped off.
		term = ":" .. term
	end
	return term
end

local function parse_param(value, paramname)
	if not value then
		return nil
	end
	local termobjs
	if value:find("[,<]") then
		termobjs = require(headword_utilities_module).parse_term_with_modifiers {
			val = value,
			paramname = paramname,
			splitchar = ",",
			include_mods = {"tr", "ts", "t", "sc"},
		}
	else
		termobjs = {{ term = value }}
	end
	return termobjs
end

local function parse_char(value, paramname, no_prefix_colon)
	if not value then
		return nil
	end
	local termobjs = parse_param(value, paramname)
	for _, termobj in ipairs(termobjs) do
		if not no_prefix_colon then
			termobj.term = add_initial_colon_to_term(termobj.term)
		end
	end
	return termobjs
end

local function join_items(items, conj)
	if not items[2] then
		return items[1]
	else
		return serial_comma_join(items, {conj = conj})
	end
end


--[==[
Implementation of {{tl|Latn-def}}, {{tl|Cyrl-def}} and the like. Supports the following invocation parameter:
; {{para|sc}}
: Specify the script code. If omitted, taken from the template parameter {{para|sc}}; if that is omitted, autodetected
  from the pagename and/or character specified in 3=. If neither method is possible, an error is thrown.
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
	if deftype == "ordinal" then
		deftype = "numsym"
	end
	local canontype = deftype
	if canontype == "digraph" or canontype == "trigraph" or canontype == "tetragraph" or canontype == "multigraph" then
		canontype = "letter"
	end
	-- FIXME: convert 'ordinal' to 'numsym'
	local deftypes = {"letter", "digraph", "trigraph", "tetragraph", "multigraph", "numsym", "ordinal", "name", "diacritic", "syllable"}
	local params = {
		[1] = {type = "language", required = true, template_default = "und"},
		[2] = {set = deftypes, required = true},
		sc = {type = "script"},
		nocap = boolean_param,
		dot = true,
		nodot = boolean_param,
		addl = true,
		pagename = true,
	}
	local function merge_params(extra_params)
		for k, v in pairs(extra_params) do
			params[k] = v
		end
	end
	if canontype == "letter" or canontype == "numsym" then
		merge_params {
			[3] = {type = "number"},
			[4] = list_param,
			linklang = boolean_param, -- only used for prec/foll
			alphabet = true,
			alphvar = true,
			t = {list = true, allow_holes = true},
			prec = true,
			foll = true,
			last = boolean_param,
		}
	elseif canontype == "name" then
		merge_params {
			[3] = {required = true},
			[4] = true,
			linklang = boolean_param,
			alphabet = true,
			alphvar = true,
			lit = true,
			eq = true,
		}
	elseif canontype == "diacritic" then
		merge_params {
			[3] = list_param,
			name = list_param,
			alphabet = true,
			alphvar = true,
			nopairs = boolean_param,
			moreexamples = boolean_param,
			t = {list = true, allow_holes = true},
		}
	elseif canontype == "syllable" then
		merge_params {
			[3] = {required = true},
			[4] = {required = true},
			[5] = {required = true},
		}
	else
		-- no need to throw an error here, as it will be thrown by [[Module:parameters]]
	end
	local args = require(parameters_module).process(parent_args, params)
	local lang = args[1]
	local sc = args.sc or iargs.sc

	if not sc then
		if canontype == "letter" or canontype == "numsym" then
			sc = lang:findBestScript(args.pagename or mw.loadData("Module:headword/data").pagename)
		elseif canontype == "diacritic" or canontype == "name" then
			local test_char = args[3]
			if type(test_char) == "table" then
				test_char = test_char[1]
			end
			if not test_char then
				error("No letter is specified in 3= from which the script can be derived; you must specify the script explicitly in sc=")
			end
			sc = lang:findBestScript(test_char)
		else
			sc = require(scripts_module).getByCode("Latn") -- not actually used
		end
	end
	local sccode = sc:getCode()
	local scname = sc:getCanonicalName()
	local sccatname = sc:getCategoryName()
	local scdisplay = sc:getDisplayForm()
	local linked_script = ("[[Appendix:%s|%s]]"):format(sccatname, sccatname)
	local categories = {}
	ins("<span class='use-with-mention'>")
	local function link_to_lang_or_mul(char, paramname, notr)
		local termobjs = parse_char(char, paramname)
		for i, termobj in ipairs(termobjs) do
			-- Either link a character using the language in 1= or using 'mul' (Translingual). We do this to avoid
			-- yellow links from trying to link to a nonexistent character. Basically, if linklang=1, we always link
			-- using the language in 1=; otherwise we try to see if the character is in the language's standardChars,
			-- and if not, link to Translingual. If the standardChars for the language is missing or the character can't
			-- be looked up (e.g. it's a digraph or trigraph), assume it's in the language and link using the language.
			local lang_for_linking
			local char = termobj.term
			if args.linklang then
				lang_for_linking = lang
			elseif #char > 1 then
				-- If the character is a digraph or trigraph, we can't check it against standardChars, which only lists
				-- single Unicode chars.
				lang_for_linking = lang
			else
				local standard_chars = lang:getStandardCharacters(sc)
				if type(standard_chars) ~= "string" or ufind(standard_chars, char) then
					-- No standardChars, or character in standardChars; link using lang.
					lang_for_linking = lang
				else
					lang_for_linking = lang_getByCode("mul", true)
				end
			end
			termobj.lang = lang_for_linking
			termobj.sc = sc
			if notr and not termobj.tr then
				termobj.tr = "-"
			end
			termobjs[i] = full_link(termobj, "term")
		end
		return join_items(termobjs, "or")
	end

	if canontype == "letter" or canontype == "numsym" then
		local indef = not args[3] and not args.last
		local article = indef and "A" or "The"
		if args.nocap then
			article = article:lower()
		end
		ins(article)
		if args[3] then
			ins(" ")
			ins(ordinal_to_word(args[3]))
		end
		if args.last then
			if args[3] then
				ins(" and")
			end
			ins(" last")
		end
		-- If we're Translingual, don't say we're a letter of the "Translingual alphabet" because there is no such
		-- thing; instead, say we're a letter of the given script, and omit the coda that says "written in the Foo
		-- script" because it's redundant.
		local is_mul = lang:getFullCode() == "mul"
		local lang_for_linking = is_mul and lang_getByCode("en", true) or lang
		ins(" ")
		if canontype == "numsym" then
			ins("[[numeral]] [[symbol]]")
		elseif args[3] and deftype ~= "letter" then
			ins("[[letter]] (a [[" .. deftype .. "]])")
		else
			ins("[[" .. deftype .. "]]")
		end
		ins(" of ")
		if args.alphabet then
			ins(args.alphabet)
		elseif is_mul then
			ins("the ")
			if sccode:find("Lat") and (args.pagename or mw.loadData("Module:headword/data").pagename):match("^[a-zA-Z]$") then
				-- Latn, Latf, Latg, pjt-Latn; if in ASCII a-z or A-Z, display as "basic modern Latin alphabet",
				-- otherwise as "Latin script" as all other scripts display for mul.
				ins(("[[%s|%s]]"):format(sccatname, "basic modern Latin alphabet"))
			else
				ins(linked_script)
			end
		else
			ins("the ")
			ins(lang:getCanonicalName())
			ins(" [[alphabet]]")
		end
		if args.alphvar then
			ins(" (" .. args.alphvar .. ")")
		end
		if args[4][1] then
			ins(", called ")
			local formatted_names = {}
			for i, name in ipairs(args[4]) do
				local nameobjs = parse_param(name, i + 3)
				for _, nameobj in ipairs(nameobjs) do
					nameobj.lang = lang_for_linking
					if args.t[i] then
						nameobj.gloss = args.t[i]
					end
					insert(formatted_names, full_link(nameobj, "term"))
				end
			end
			ins(mw.text.listToText(formatted_names, nil, " or "))
			if not is_mul then
				ins(" and ")
			end
		elseif not is_mul then
			ins(", ")
		end
		if not is_mul then
			ins(("written in the %s"):format(linked_script))
		end
		if args.prec then
			ins("; preceded by ")
			ins(link_to_lang_or_mul(args.prec, "prec"))
		end
		if args.foll then
			if args.prec then
				ins(" and ")
			else
				ins("; ")
			end
			ins("followed by ")
			ins(link_to_lang_or_mul(args.foll, "foll"))
		end
		if canontype == "numsym" then
			-- FIXME: Rethink the name of this category.
			insert(categories, ("%s ordinal numbers"):format(lang:getFullName()))
		end

	elseif canontype == "name" then
		ins(args.nocap and "the" or "The")
		ins((" name of the %s letter "):format(linked_script))
		ins(link_to_lang_or_mul(args[3], 3, "notr"))
		if args[4] then
			ins("/")
			ins(link_to_lang_or_mul(args[4], 4, "notr"))
		end
		if args.alphabet then
			ins(", in " .. args.alphabet)
			if args.alphvar then
				ins(" (" .. args.alphvar .. ")")
			end
		elseif args.alphvar then
			ins(", in " .. args.alphvar)
		end
		if args.lit then
			ins(", literally “")
			ins(args.lit)
			ins("”")
		end
		if args.eq then
			ins(", called ")
			ins(full_link({lang = lang_getByCode("en", true), term = args.eq}, "term"))
			ins(" in English")
		end
		insert(categories, ("%s:%s letter names"):format(lang:getFullCode(), scname))

	elseif canontype == "diacritic" then
		ins(args.nocap and "a" or "A")
		ins((" [[diacritical mark]] of the %s"):format(linked_script))
		if args.alphabet then
			ins(" in " .. args.alphabet)
			if args.alphvar then
				ins(" (" .. args.alphvar .. ")")
			end
		elseif args.alphvar then
			ins(" in " .. args.alphvar)
		end
		if args.name[1] then
			ins(", called ")
			local formatted_names = {}
			for i, name in ipairs(args.name) do
				local nameobjs = parse_param(name, "name" .. (i == 1 and "" or i))
				for _, nameobj in ipairs(nameobjs) do
					nameobj.lang = lang
					if args.t[i] then
						nameobj.gloss = args.t[i]
					end
					insert(formatted_names, full_link(nameobj, "term"))
				end
			end
			ins(mw.text.listToText(formatted_names, nil, " or "))
		end
		ins(" in ")
		ins(lang:getCanonicalName())
		if args[3][1] then
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
			if args.moreexamples then
				ins(", among others")
			end
		end

	elseif canontype == "syllable" then
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
		error(("Internal error: Unhandled canontype %s"):format(mw.dumpObject(canontype)))
	end
	local addl = args.addl
	if addl then
		if addl:find("^[;:.]") then
			ins(addl)
		elseif addl:find("^_") then
			ins(" " .. addl:sub(2))
		else
			ins(", " .. addl)
		end
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
