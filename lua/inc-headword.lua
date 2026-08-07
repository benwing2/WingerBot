local export = {}
local pos_functions = {}

--[==[ intro:
This module provides support for modern Indic-language headword templates. It currently supports Hindi, Punjabi, Urdu,
Palula and Kohistani Shina. Eventually it will support other Indic languages, such as Marathi, Gujarati, Bengali,
Assamese, etc. Ancient Indic languages such as Sanskrit, Pali and Prakrit are handled by separate modules because they
have their own morphological complexities (esp. Sanskrit), which have no equivalent in the modern languages.
]==]

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_links = require("Module:links")
local m_table = require("Module:table")

local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local parse_interface_module = "Module:parse interface"
local scripts_module = "Module:scripts"
local ur_hi_convert_module = "Module:ur-hi-convert"
local pa_Arab_Guru_module = "Module:pa-Arab-Guru"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local boolean_param = {type = "boolean"}
local list_param = {list = true, disallow_holes = true}
local gender_param = {type = "genders"}
local gender_param_with_default = {type = "genders", default = "?"}

local list_to_set = m_table.listToSet
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local insert = table.insert
local concat = table.concat


local misc_pos_with_gender = list_to_set {
	"numerals",
	"suffixes",
	"adjective forms",
	"noun forms",
	"proper noun forms",
	"pronoun forms",
	"determiner forms",
	"verb forms",
	"postposition forms",
}

local function generate_hindis_from_urdu_heads(headobjs)
	local hindis = {}
	for _, headobj in ipairs(headobjs) do
		local hindiobj = m_table.shallowCopy(headobj)
		hindiobj.term = require(ur_hi_convert_module).tr(m_links.remove_links(headobj.term))
		hindiobj.tr = nil
		insert(hindis, hindiobj)
	end
	return hindis
end

local function generate_gur_from_shah_heads(headobjs)
	local gurus = {}
	for _, headobj in ipairs(headobjs) do
		local guruobj = m_table.shallowCopy(headobj)
		guruobj.term = require(pa_Arab_Guru_module).tr(m_links.remove_links(headobj.term))
		guruobj.tr = nil
		insert(gurus, guruobj)
	end
	return gurus
end

local langs_supported = {
	["hi"] = {
		other_langs_scripts = {
			{"ur", "ur", "ur-Arab", "Urdu"},
		},
	},
	["pa"] = {
		other_langs_scripts = {
			{"gur", "pa", "Guru", "Gurmukhi", generate_gur_from_shah_heads},
			{"sha", "pa", "pa-Arab", "Shahmukhi"},
		},
		sccat = true,
	},
	["ur"] = {
		other_langs_scripts = {
			{"hi", "hi", "Deva", "Hindi", generate_hindis_from_urdu_heads},
		},
		enable_auto_translit = true,
	},
	["phl"] = {
		other_langs_scripts = {
			{"pa",  "phl", "Arab", "Perso-Arabic"},
			{"lat", "phl", "Latn", "Latin"},
		},
		sccat = true,
	},
	["plk"] = {
		other_langs_scripts = {
			{"pa",  "plk", "Arab", "Perso-Arabic"},
			{"lat", "plk", "Latn", "Latin"},
		},
		sccat = true,
	}
}


----------------------------------------------- Utilities --------------------------------------------

local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(page)
	require("Module:debug").track("inc-headword/" .. page)
	return true
end

local function validate_genders(data, genders)
	data.genders = genders
	if not genders then
		return
	end
	for _, gspec in ipairs(genders) do
		local g = gspec.spec
		if g == "m" or g == "f" or
			g == "m-p" or g == "f-p" or
			g == "mf" or g == "mf-p" or
			g == "mfbysense" or g == "mfbysense-p" or
			g == "mfequiv" or g == "mfequiv-p" or
			g == "?" then
		else
			error("Invalid gender: " .. g)
		end
	end
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(_data, args, field, is_head, no_include_tr, is_single_param)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	if is_single_param then
		local retval
		if args[argfield] then
			retval = m_headword_utilities.parse_term_with_modifiers {
				val = args[argfield],
				paramname = field,
				splitchar = ",",
				is_head = is_head,
				include_mods = not no_include_tr and {"tr"} or nil,
			}
		end
		return retval or {}
	else
		return m_headword_utilities.parse_term_list_with_modifiers {
			forms = args[argfield],
			paramname = field,
			splitchar = ",",
			is_head = is_head,
			include_mods = not no_include_tr and {"tr"} or nil,
		}
	end
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form, or nil. `enable_auto_translit` is set if requested by the language.
local function parse_and_insert_inflection(data, args, field, label, accel_form)
	local terms = parse_inflection(data, args, field)
	local accel_obj
	if accel_form then
		local lemmas = {}
		local lemma_translits = {}
		for i, headobj in ipairs(data.heads) do
			lemmas[i] = headobj.term
			lemma_translits[i] = headobj.tr
		end
		accel_obj = {
			lemma = lemmas,
			lemma_translit = lemma_translits,
			form = accel_form,
		}
	end

	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel_obj,
		enable_auto_translit = data.langprops.enable_auto_translit,
	}
end

--[==[
Main entry point. Takes two params:
; {{para|lang|req=1}}
: The language code of the language of the headword template.
; {{para|1}}
: The part of speech, pluralized; omit for {{cd|*-head}} templates such as {{tl|hi-head}}, {{tl|pa-head}} and {{tl|ur-head}}.
]==]
function export.show(frame)
	local iparams = {
		[1] = true,
		["lang"] = {required = true},
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	local parargs = frame:getParent().args
	local poscat = iargs[1]
	local langcode = iargs.lang
	if not langs_supported[langcode] then
		local langcodes_supported = {}
		for lang, _ in pairs(langs_supported) do
			insert(langcodes_supported, lang)
		end
		error("This module currently only works for lang=" .. concat(langcodes_supported, "/"))
	end
	local lang = require(languages_module).getByCode(langcode, true)
	local langname = lang:getCanonicalName()
	local pos_in_1 = not poscat
	if pos_in_1 then
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:" .. langcode .. "-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and (misc_pos_with_gender[poscat] and "head_with_gender" or "head") or poscat

	local langprops = langs_supported[langcode]

	local params = {
		["head"] = true,
		["head2"] = {replaced_by = false, instead = "use comma-separated |head="},
		["tr"] = true,
		["tr2"] = {replaced_by = false, instead = "use comma-separated |tr= or <tr:...> inline modifier on head"},
		["id"] = true,
		["sort"] = true,
		["nolink"] = boolean_param,
		["nolinkhead"] = {type = "boolean", alias_of = "nolink"},
		["suffix"] = boolean_param,
		["nosuffix"] = boolean_param,
		["splithyphen"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = true, -- for testing
	}

	if pos_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	for _, other_lang_script in ipairs(langprops.other_langs_scripts) do
		local param, _, _, _ = unpack(other_lang_script)
		params[param] = true
		params[param .. "1"] = {replaced_by = false, instead = "use comma-separated items (with no space after the comma) in |" .. param .. "="}
		params[param .. "2"] = {replaced_by = false, instead = "use comma-separated items (with no space after the comma) in |" .. param .. "="}
	end

	if pos_functions[indexing_poscat] then
		for key, val in pairs(pos_functions[indexing_poscat].params) do
			params[key] = val
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local data = {
		lang = lang,
		langname = langname,
		langprops = langprops,
		pos_category = poscat,
		categories = {},
		genders = {},
		inflections = {},
		pagename = pagename,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		-- We use our own splitting algorithm so the redundant head cat will be inaccurate.
		no_redundant_head_cat = true,
		sccat = langprops.sccat,
	}

	local trs = args.tr and split_on_comma(args.tr) or {}
	local num_trs = #trs
	local heads = args.head and parse_inflection(data, args, "head", "is_head", nil, "is_single_param") or {}
	local user_specified_heads = heads
	local num_heads = #heads
	if num_heads > 0 and num_trs > 0 and num_heads ~= num_trs then
		error(("%s head%s specified explicitly but %s translit%s; they must match; use '+' to stand for the default head (the pagename) or no manual translit"):format(
			num_heads, num_heads > 1 and "s" or "", num_trs, num_trs > 1 and "s" or ""))
	end
	-- Be careful here not to overwrite user_specified_heads if it's empty so we can later check user_specified_heads
	-- to see if the user provided any heads.
	if num_heads == 0 and num_trs > 0 then
		heads = {}
		for i = 1, num_trs do
			heads[i] = {term = "+"}
		end
	end
	if not heads[1] then
		heads = {{term = "+"}}
	end
	for i, headobj in ipairs(heads) do
		if headobj.term == "+" then
			headobj.term = args.nolink and pagename or m_headword_utilities.add_links_to_multiword_term(pagename,
				{split_hyphen_when_space = args.splithyphen})
		end
		if headobj.tr and trs[i] then
			if headobj.tr ~= trs[i] then
				error(("Saw two different translits '%s' and '%s' for head #%s '%s'"):format(
					headobj.tr, trs[i], i, headobj.term))
			end
		else
			headobj.tr = headobj.tr or trs[i]
		end
		if headobj.tr == "+" then
			headobj.tr = nil
		end
	end
	data.heads = heads

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
		pos_functions[indexing_poscat].func(args, data)
	end

	for _, other_lang_script in ipairs(langprops.other_langs_scripts) do
		local param, other_langcode, other_sccode, lang_script_label, generate_from_heads = unpack(other_lang_script)
		local terms = parse_inflection(data, args, param, nil, "no_include_tr", "is_single_param") or {}
		if not terms[1] and generate_from_heads then
			terms = generate_from_heads(user_specified_heads)
		end
		if terms[1] then
			local other_lang = require(languages_module).getByCode(other_langcode, true)
			local other_sc = require(scripts_module).getByCode(other_sccode, true)
			for _, termobj in ipairs(terms) do
				termobj.lang = other_lang
				termobj.sc = other_sc
			end
			m_headword_utilities.insert_inflection {
				headdata = data,
				terms = terms,
				label = lang_script_label .. " spelling",
				-- Don't set `enable_auto_translit` here, e.g. for Urdu.
			}
		end
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

pos_functions.adjectives = {
	params = {
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
		["f"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		if args["ind"] then
			insert(data.inflections, {label = glossary_link("indeclinable")})
			insert(data.categories, data.langname .. " indeclinable adjectives")
		end
		parse_and_insert_inflection(data, args, {1, "comp"}, "<<comparative>>")
		parse_and_insert_inflection(data, args, {2, "sup"}, "<<superlative>>")
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

pos_functions.ordinals = {
	params = {
		["f"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		data.pos_category = "adjectives"
		insert(data.categories, data.langname .. " numerals")
		if args["ind"] then
			insert(data.inflections, {label = glossary_link("indeclinable")})
			insert(data.categories, data.langname .. " indeclinable numerals")
		end
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

pos_functions.cardinals = {
	params = {
		[1] = gender_param,
		["g"] = {replaced_by = 1},
		["sym"] = list_param,
	},
	func = function(args, data)
		data.pos_category = "numerals"
		validate_genders(data, args[1])
		parse_and_insert_inflection(data, args, "sym", "native script symbol")
	end,
}

local function nouns(plpos)
	return {
		params = {
			[1] = gender_param_with_default,
			["g"] = {replaced_by = 1},
			["pl"] = list_param,
			["f"] = list_param,
			["m"] = list_param,
			["ind"] = boolean_param,
		},
		func = function(args, data)
			validate_genders(data, args[1])
			if args["ind"] then
				if args["pl"][1] then
					error("Can't specify both ind= and pl=")
				end
				insert(data.inflections, {label = glossary_link("indeclinable")})
				insert(data.categories, data.langname .. " indeclinable " .. plpos)
			else
				parse_and_insert_inflection(data, args, "pl", "formal plural", "formal|p")
			end
			parse_and_insert_inflection(data, args, "m", "male equivalent", "m")
			parse_and_insert_inflection(data, args, "f", "female equivalent", "f")
			if args["m"][1] or args["f"][1] then
				insert(data.categories, data.langname .. " " .. plpos .. " with other-gender equivalents")
			end
		end,
	}
end

pos_functions.nouns = nouns("nouns")
pos_functions["proper nouns"] = nouns("proper nouns")

pos_functions.pronouns = {
	params = {
		[1] = gender_param,
		["g"] = {replaced_by = 1},
	},
	func = function(args, data)
		validate_genders(data, args[1])
	end,
}

pos_functions.verbs = {
	params = {
		[1] = true,
	},
	func = function(args, data)
		if args[1] then
			local label
			if args[1] == "t" then
				label = "transitive"
				insert(data.categories, data.langname .. " transitive verbs")
			elseif args[1] == "i" then
				label = "intransitive"
				insert(data.categories, data.langname .. " intransitive verbs")
			elseif args[1] == "d" then
				label = "ditransitive"
				insert(data.categories, data.langname .. " ditransitive verbs")
			elseif args[1] == "it" or args[1] == "ti" or args[1] == "a" then
				label = "ambitransitive"
				insert(data.categories, data.langname .. " ambitransitive verbs")
				insert(data.categories, data.langname .. " transitive verbs")
				insert(data.categories, data.langname .. " intransitive verbs")
			elseif args[1] == "tp" then -- only in Palula
				label = "transitive"
				insert(data.categories, data.langname .. " transitive verbs")
				insert(data.categories, data.langname .. " passive verbs")
				insert(data.inflections, {label = glossary_link("passive")})
			else
				error("Unrecognized param 1=" .. args[1] .. ": Should be 'i' = intransitive, 't' = transitive, 'd' = ditransitive or 'it'/'ti'/'a' = ambitransitive")
			end
			insert(data.inflections, {label = glossary_link(label)})
		end

		if data.pagename:find(" ") then
			local base_verb = m_links.remove_links(data.pagename):gsub("^.* ", "")
			insert(data.categories, data.langname .. " compound verbs formed with " .. base_verb)
		end
	end,
}

pos_functions.head_with_gender = {
	params = {
		[2] = gender_param,
	},
	func = function(args, data)
		validate_genders(data, args[2])
	end,
}

local pos_prelude = {
	["head"] =
"This template should be used to generate the headword line for LANG terms whose part of speech does not have an associated specialized template. The current specialized templates are " ..
"{{tl|CODE-noun}}, {{tl|CODE-proper noun}}, {{tl|CODE-pron}} (pronouns), {{tl|CODE-verb}}, {{tl|CODE-adj}} (adjectives), {{tl|CODE-adv}} (adverbs), {{tl|CODE-num-card}} (cardinal numbers/numerals) and "..
"{{tl|CODE-num-ord}} (ordinal numbers/numerals). All others should use {{tl|CODE-head}}.",
}

local noun_addl_params = [=[
;{{para|pl}}
: Formal or irregular plural(s). Intended particularly for Arabic and Persian-origin plurals. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|f}}
: Female equivalent(s), for a noun referring to a male person or animal. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|m}}
: Male equivalent(s), for a noun referring to a female person or animal. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|ind|1}}
: Specify that the noun is indeclinable.
]=]

local pos_addl_params = {
	["nouns"] = noun_addl_params,
	["proper nouns"] = noun_addl_params,
	["verbs"] = [=[
;{{para|1}}
: Verb type. One of {{cd|t}} (transitive), {{cd|i}} (intransitive), {{cd|d}} (ditransitive) or {{cd|it}}/{{cd|ti}}/{{cd|a}} (ambitransitive).
]=],
	["adjectives"] = [=[
;{{para|1}}
: Comparative form(s). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|2}}
: Superlative form(s). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|ind|1}}
: Specify that the adjective is indeclinable.
;{{para|f}}
: Feminine form(s) of an adjective with irregular feminine forms.
]=],
	["cardinals"] = [=[
;{{para|sym}}
: Native script symbol(s) for this numeral. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=],
	["ordinals"] = [=[
;{{para|ind|1}}
: Specify that the ordinal is indeclinable.
;{{para|f}}
: Feminine form(s) of an ordinal adjective with irregular feminine forms.
]=],
	["head"] = [=[
;{{para|1|req=1}}
: Part of speech. Can be singular or plural and can be abbreviated (e.g. {{cd|n}} for noun; {{cd|nounf}} or {{cd|nf}} for noun form; {{cd|interj}} or {{cd|intj}} for interjection; {{cd|pcl}} for particle; {{cd|phr}} for phrase; etc.). The recognized abbreviations are listed in [[Template:head#Part of speech]] and are the same abbreviations that can be specified in the part-of-speech parameter to {{tl|head}}.
;{{para|2}}
: Gender(s). Specifying a gender is always optional and is only allowed for certain parts of speech where it makes sense to specify a gender (currently this includes numerals, suffixes, adjective forms, noun forms, proper noun forms, pronoun forms, determiner forms, verb forms and postposition forms). Possible values are {{cd|m}}, {{cd|f}}, {{cd|m-p}}, {{cd|f-p}}, {{cd|mf}} (can be either masculine or feminine), {{cd|mf-p}} (plural-only, can be either masculine or feminine), {{cd|mfbysense}} (can be either masculine or feminine, depending on the natural gender of the person or animal being referred to), {{cd|mfbysense-p}} (plural-only, can be either masculine or feminine, depending on the natural gender of the person or animal being referred to). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=],
}

local pos_has_gender = {
	["nouns"] = true,
	["proper nouns"] = true,
	["pronouns"] = true,
	["cardinals"] = true,
}

--[==[
Documentation generation function, used to populate the documentation describing all parameters of all headword-line templates. Supports the following parameters:
; {{para|lang|req=1}}
: The language code of the language of the headword template being documented.
; {{para|pos|req=1}}
: The plural part of speech of the headword template being documented. Use {{cd|head}} for {{tl|hi-head}}/{{tl|pa-head}}/{{tl|ur-head}}/etc.
]==]
function export.doctext(frame)
	local iparams = {
		["lang"] = {required = true, type = "language"},
		["pos"] = {required = true},
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)
	local langcode = iargs.lang:getCode()
	if not langs_supported[langcode] then
		local langcodes_supported = {}
		for lang, _ in pairs(langs_supported) do
			insert(langcodes_supported, lang)
		end
		error("This module currently only works for lang=" .. concat(langcodes_supported, "/"))
	end

	local other_lang_script_equivs = langcode == "hi" and [=[
;{{para|ur}}
: Urdu equivalent(s). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=] or langcode == "ur" and [=[
;{{para|hi}}
: Hindi equivalent(s). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=] or langcode == "pa" and [=[
;{{para|gur}}
: Gurmukhi equivalent(s) of a Shahmukhi term. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|sha}}
: Shahmukhi equivalent(s) of a Gurmukhi term. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=] or (langcode == "phl" or langcode == "plk") and [=[
;{{para|pa}}
: Perso-Arabic spelling(s) of the term. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
;{{para|lat}}
: Latin spelling(s) of the term. Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=] or ""

	local prelude = (pos_prelude[iargs.pos] or "This template should be used to generate the headword line for LANG POS.")
		:gsub("LANG", iargs.lang:getCanonicalName())
		:gsub("CODE", iargs.lang:getCode())
		:gsub("POS", iargs.pos)

	local g_text = [=[
;{{para|1}}
: Gender(s). Possible values are {{cd|m}}, {{cd|f}}, {{cd|m-p}}, {{cd|f-p}}, {{cd|mf}} (can be either masculine or feminine), {{cd|mf-p}} (plural-only, can be either masculine or feminine), {{cd|mfbysense}} (can be either masculine or feminine, depending on the natural gender of the person or animal being referred to), {{cd|mfbysense-p}} (plural-only, can be either masculine or feminine, depending on the natural gender of the person or animal being referred to). Separate multiple items with a comma (not followed by a space). Per-item inline modifiers are supported.
]=]

	local includeg = pos_has_gender[iargs.pos]
	local addl_params = pos_addl_params[iargs.pos] or ""

	local text = prelude .. [=[

==Parameters==
The following parameters are supported:
]=] .. (includeg and g_text or "") .. addl_params .. [=[
;{{para|head}}
: Explicitly specified headword(s), for ]=] .. (langcode == "pa" and "adding vowel diacritics to Shahmukhi terms or " or langcode == "ur" and "adding vowel diacritics or " or "") ..
	"introducing links in multiword expressions. Separate multiple items with a comma (not followed by a space). " ..
	"Per-item inline modifiers are supported. Use {{cd|+}} to request the default linking algorithm (equivalent to omitting the value if there's only one value). " ..
	"Note that by default each word of a multiword lemma is linked" .. (langcode == "ur" and "." or ", so you only need to use this " ..
	(langcode == "pa" and "for Gurmukhi terms " or "") ..
	"when the default links don't suffice (e.g. the multiword expression consists of non-lemma forms, which need to be linked to their lemmas).") .. "\n" .. [=[
;{{para|tr}}
: Manual transliteration(s), in case the automatic transliteration is incorrect. Separate multiple items with a comma (not followed by a space), ]=] ..
	[=[and use {{cd|+}} to stand for the default automatic translation (equivalent to omitting the value if there's only one value). ]=] ..
	[=[If {{para|head}} is used, there should be the same number of transliterations as head values, or an error will occur.
]=] .. other_lang_script_equivs .. [=[
;{{para|nolink|1}}, {{para|nolinkhead|1}}
: Don't link the individual words in a multiword expression.
;{{para|suffix|1}}
: Specify that the term is a suffix. Not needed if the term begins with a hyphen.
;{{para|nosuffix|1}}
: Specify that a term beginning with a hyphen is not a suffix.
;{{para|id}}
: Sense ID, for linking to this particular headword when there is more than one. See {{tl|senseid}} for more information.
; {{para|splithyph|1}}
: Indicate that automatic splitting and linking of words should split on hyphens in multiword expressions with spaces in them. Normally splitting on hyphens only occurs in terms without spaces.
; {{para|pagename}}
: Override the page name used to compute default values of various sorts. Useful when testing, for documentation pages, etc.
; {{para|sort}}
: Sort key. Rarely needs to be specified, as it is normally automatically generated.
; {{para|json|1}}
: Output the headword data in JSON form instead of the normal output. For use by bots.
]=]

	local after_params_text =[=[

==Inline modifiers==
All params above that allow for multiple comma-separated values (except for {{para|tr}}) support ''inline modifiers'', e.g. {{para|pl|रायज़,फ़राइज़<l:rare>}} to attach a label ''rare'' to the second plural. The following modifiers are recognized:
* {{cd|tr}}: manual translit; cannot be specified for genders as it doesn't make sense to do so
* {{cd|q}}: qualifier, e.g. {{cd|<q:in the plural>}} or {{cd|<q:when referring to a card game>}}; this appears *BEFORE* the term, parenthesized and italicized
* {{cd|qq}}: qualifier, e.g. {{cd|<qq:in the plural>}} or {{cd|<qq:when referring to a card game>}}; this appears *AFTER* the term, parenthesized and italicized
* {{cd|l}}: comma-separated list of labels, e.g. {{cd|<l:rare>}} or {{cd|<l:dated,or,literary>}}; this appears *BEFORE* the term, parenthesized and italicized
* {{cd|ll}}: comma-separated list of labels, e.g. {{cd|<ll:rare>}} or {{cd|<ll:dated,or,literary>}}; this appears *AFTER* the term, parenthesized and italicized
* {{cd|ref}}: one or more references, in the format documented in [[Module:references]] and {{tl|IPA}}
* {{cd|id}}: sense ID; see {{temp|senseid}}; cannot be specified for headwords or genders as it doesn't make sense to do so

==Suffix handling==
If the term begins with a hyphen ({{cd|-}}), it is assumed to be a suffix rather than a base form, and is categorized into [[:Category:LANG suffixes]] and [[:Category:LANG POS-forming suffixes]] rather than [[:Category:LANG POSs]] (e.g. [[:Category:LANG noun-forming suffixes]] rather than [[:Category:LANG nouns]]). This can be overridden using {{para|nosuffix|1}}.
]=]

	after_params_text = after_params_text:gsub("LANG", iargs.lang:getCanonicalName())

	text = text .. after_params_text
	-- Remove final newline so template code can add a newline after invocation
	text = text:gsub("\n$", "")
	return mw.getCurrentFrame():preprocess(text)
end

return export
