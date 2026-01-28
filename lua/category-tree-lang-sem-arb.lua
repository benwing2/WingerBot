local labels = {}
local handlers = {}

local m_table = require("Module:table")

local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local rmatch = mw.ustring.match
local u = mw.ustring.char

--[=[
This module handles language-specific categories for all Arabic varieties. The individual variety-specific modules
should do nothing but invoke this module; see [[Module:category tree/lang/ar]] for an example. Most of the code here is
generic, but in a few places we conditionalize on the language code, which is passed into the various functions that add
labels and handlers (e.g. in the noun and adjective nisba endings). If you need to add a module for a new variety, DO
NOT copy the code in this module (even in part), but add appropriate conditional statements as required. It does not
matter if the module adds labels and handlers for categories that don't exist in a given variety (e.g. forms XI through
XV).
]=]

for _, affixtype in ipairs { "affixes", "prefixes", "suffixes", "infixes" } do
	labels["root " .. affixtype] = {
		description = "{{{langname}}} " .. affixtype .. " that incorporate themselves into the root, creating a new root for words to derive from.",
		parents = affixtype == "affixes" and {"affixes"} or {"root affixes", affixtype},
		breadcrumb_and_first_sort_base = affixtype == "affixes" and "root affixes" or affixtype,
	}
end

-----------------------------------------------------------------------------
--                                                                         --
--                           NOUNS AND ADJECTIVES                          --
--                                                                         --
-----------------------------------------------------------------------------


---------------------------------- Noun/adjective labels ---------------------------------

local function make_appendix_link(lang, text, anchor)
	local langcode = lang:getCode()
	-- FIXME! Create variety-specific verb appendices.
	local nominal_appendix = langcode == "mt" and "Appendix:Maltese nominals" or "Appendix:Arabic nominals"
	-- FIXME! No current [[Appendix:Maltese nominals]]. Create it!
	local remove_appendix_links = langcode == "mt"
	anchor = anchor or mw.getContentLanguage():ucfirst(text)
	local retval = ("[[%s#%s|%s]]"):format(nominal_appendix, anchor, text)
	if remove_appendix_links then
		return require("Module:links").remove_links(retval)
	else
		return retval
	end
end

------------------- Noun labels --------------------

labels["nouns by derivation type"] = {
	description = "{{{langname}}} nouns categorized by type of derivation.",
	parents = {{name = "nouns", sort = "derivation type"}},
	breadcrumb = "by derivation type",
}

local noun_types = {
	{"instance nouns", 'nouns having the meaning "an instance of doing X" for some verb', "instance"},
	{"nouns of place", 'nouns having the approximate meaning "the place for doing X" for some verb', "place"},
	{"occupational nouns", "nouns referring to people employed in doing something", "occupational"},
	{"tool nouns", 'nouns having the approximate meaning "tool for doing X" for some verb', "tool"},
}

for _, noun_type_spec in ipairs(noun_types) do
	local label, desc, breadcrumb = unpack(noun_type_spec)
	labels[label] = {
		description = function(data) return "{{{langname}}} " .. make_appendix_link(data.lang, "instance nouns") .. ", i.e. " .. desc .. "." end,
		parents = {"nouns by derivation type"},
		breadcrumb_and_first_sort_base = breadcrumb,
	}
end

local function get_noun_nisba_ending(lang)
	local langcode = lang:getCode()
	return 
		langcode == "ar" and "{{m|" .. langcode .. "|ـِيَّة}}" or
		langcode == "ajp" and "{{m|" .. langcode .. "|ـية|tr=-iyye}}" or
		"{{m|" .. langcode .. "|ـية|tr=-iyya}}"
end

labels["relative nouns (nisba)"] = {
	description = function(data) "{{{langname}}} " .. make_appendix_link(data.lang, "relative (nisba) nouns", "Relative nouns (nisba)") .. ", i.e. abstract nouns formed with the suffix " .. get_noun_nisba_ending(data.lang) .. " and derived from an adjective or other noun (or occasionally other parts of speech)." end,
	parents = {"nouns by derivation type"},
	breadcrumb_and_first_sort_base = "relative (nisba)",
}

local function get_fem_ending_text(lang)
	local langcode = lang:getCode()
	return langcode == "ar" and
		"the feminine endings {{m|ar|ـَة}}&lrm;, {{m|ar||ـَاء}}&lrm;, {{m|ar||ـَا}}&lrm;{{,}} or {{m|ar|ـَى}}" or
		"one of the recognized feminine endings"
end

local function get_module_additional(lang)
	local langcode = lang:getCode()
	-- FIXME: [[Module:sem-arb-headword]] doesn't actually add this.
	return "It is automatically added by [[Module:" .. (langcode == "ar" and "ar" or "sem-arb") .. "-headword]] to lemma entries."
end

labels["feminine terms lacking feminine ending"] = {
	description = function(data) "{{{langname}}} feminine terms that do not end in " .. get_fem_ending_text(data.lang) .. "." end,
	additional = function(data) return get_module_additional(data.lang) end,
	parents = {"nouns", "terms by lexical property", "feminine nouns"},
}

labels["masculine terms with feminine ending"] = {
	description = "{{{langname}}} masculine terms ending in one of " .. fem_ending_text .. ".",
	additional = module_additional,
	parents = {"nouns", "terms by lexical property", "masculine nouns"},
}

labels["terms with fused definite article"] = {
	description = "{{{langname}}} terms with a fused definite article.",
	parents = {"lemmas", "terms by etymology"},
}

labels["terms with rebracketed definite article"] = {
	description = "{{{langname}}} terms where part of the original word was reanalyzed as the definite article and deleted.",
	parents = {"lemmas", "terms by etymology"},
}

------------------- Adjective labels --------------------

labels["adjectives by derivation type"] = {
	description = "{{{langname}}} adjectives categorized by type of derivation.",
	parents = {{name = "adjectives", sort = "derivation type"}},
	breadcrumb = "by derivation type",
}

labels["characteristic adjectives"] = {
	description = "{{{langname}}} " .. make_appendix_link("characteristic adjectives", "Characteristic nouns and adjectives") .. ", i.e. adjectives meaning \"habitually doing X\" for some verb.",
	parents = {{name = "adjectives", sort = "characteristic"}},
	breadcrumb = "characteristic",
}

labels["color/defect adjectives"] = {
	description = "{{{langname}}} " .. make_appendix_link("color/defect adjectives", "Color or defect adjectives") .. ", i.e. adjectives generally referring to colors and physical defects.",
	parents = {{name = "adjectives", sort = "color/defect"}},
	breadcrumb = "color/defect",
}

local adj_nisba_ending =
	langcode == "ar" and "{{m|" .. langcode .. "|ـِيّ}}" or
	"{{m|" .. langcode .. "|ـي|tr=-i}}"

labels["relative adjectives (nisba)"] = {
	description = "{{{langname}}} " .. make_appendix_link("relative (nisba) adjectives", "Relative adjectives (nisba)") .. ", i.e. adjectives formed with the suffix " .. adj_nisba_ending .. " and meaning \"related to X\" for some noun (or occasionally other parts of speech).",
	parents = {{name = "adjectives", sort = "relative (nisba)"}},
	breadcrumb = "relative (nisba)",
}


--------------------------------- Noun/adjective handlers --------------------------------

local function add_noun_adjective_handlers(handlers, lang)
	-- Only fire if the part of speech is one of these.
	local allowed_pos = m_table.listToSet {"noun", "pronoun", "numeral", "adjective", "participle"}
	-- Only fire if one of these words occurs.
	local required_words = {"triptote", "diptote", "singular", "plural", "dual", "paucal", "singulative", "collective"}

	table.insert(handlers, function(data)
		local pos, typ = data.label:match("^([a-z]+)s with (.+)$")
		if not pos or not allowed_pos[pos] then
			return nil
		end
		local spaced_typ = " " .. typ .. " "
		local ok = false
		for _, required_word in ipairs(required_words) do
			if spaced_typ:find(" " .. required_word .. " ") then
				ok = true
				break
			end
		end
		if not ok then
			return nil
		end

		local parents = {}
		if typ:find("unknown") or typ:find("uncertain") then
			table.insert(parents, "entry maintenance")
		end
		table.insert(parents, {name = pos .. "s by inflection type", sort = typ})
		if typ ~= "broken plural" and typ:find("broken plural") then
			table.insert(parents, {name = pos .. "s with broken plural", sort = typ})
		end
		if typ:find("irregular") then
			table.insert(parents, {name = "irregular " .. pos .. "s", sort = typ})
		end

		return {
			description = "{{{langname}}} " .. data.label .. ".",
			breadcrumb = typ,
			parents = parents,
		}
	end)
end



-----------------------------------------------------------------------------
--                                                                         --
--                                   VERBS                                 --
--                                                                         --
-----------------------------------------------------------------------------


--------------------------------- Verb labels --------------------------------

local function add_verb_labels(labels, lang)
	labels["verbs with quadriliteral roots"] = {
		description = "{{{langname}}} verbs built on roots consisting of four radicals (instead of the more common triliteral roots), categorized by form.",
		parents = {{name = "verbs by inflection type", sort = "quadriliteral roots"}},
		breadcrumb = "with quadriliteral roots",
	}

	labels["verbs by conjugation"] = {
		description = "{{{langname}}} verbs categorized by type of weakness displayed in their conjugation (as opposed to weakness determined by form, i.e. by the presence of certain \"weak\" radicals in certain positions).",
		parents = {{name = "verbs by inflection type", sort = "conjugation"}},
		breadcrumb = "by conjugation",
	}

	labels["verbs by type of passive"] = {
		description = "{{{langname}}} verbs categorized by type of passive available.",
		parents = {{name = "verbs", sort = "type of passive"}},
		breadcrumb = "by type of passive",
	}

	labels["verbs with full passive"] = {
		description = "{{{langname}}} verbs with passive forms in all persons and numbers.",
		parents = {{name = "verbs by type of passive", sort = "full passive"}},
		breadcrumb = "full passive",
	}

	labels["verbs with impersonal passive"] = {
		description = "{{{langname}}} verbs with impersonal passive forms only, i.e. only in the third-person masculine singular.",
		parents = {{name = "verbs by type of passive", sort = "impersonal passive"}},
		breadcrumb = "impersonal passive",
	}

	labels["verbs lacking passive forms"] = {
		description = "{{{langname}}} verbs without passive forms.",
		parents = {{name = "verbs by type of passive", sort = "lacking passive forms"}},
		breadcrumb = "lacking passive",
	}

	labels["verbs lacking imperative forms"] = {
		description = "{{{langname}}} verbs without imperative forms.",
		parents = {{name = "defective verbs", sort = "imperative"}},
		breadcrumb = "lacking imperative forms",
	}

	for _, uncertain_slot in ipairs {"verbal noun", "active participle"} do
		labels["verbs with unknown or uncertain " .. uncertain_slot .. "s"] = {
			description = ("{{{langname}}} verbs where the %s is unknown or uncertain."):format(uncertain_slot),
			additional = "For Classical Arabic, this happens with the verbal noun of form-I verbs and the active participle of " ..
			"form-I stative verbs (those whose past vowel is ''i'' or ''u''). For these verbs there is no single consistent pattern " ..
			"for the form in question, and thus it needs to be specified explicitly. If not done so, it shows up as a question mark " ..
			" and the verb is placed in this category.",
			parents = {"entry maintenance"},
			hidden = true,
			can_be_empty = true,
		}
		
		labels["verbs with explicitly unknown " .. uncertain_slot .. "s"] = {
			description = ("{{{langname}}} verbs where the %s is explicitly specified as '?', meaning unknown."):format(uncertain_slot),
			additional = "For Classical Arabic, this happens mostly with the verbal noun of form-I verbs and the active participle of " ..
			"form-I stative verbs (those whose past vowel is ''i'' or ''u''). For these verbs there is no single consistent pattern " ..
			"for the form in question, and thus it needs to be specified explicitly. If it's no possible to determine the correct form " ..
			"from a dictionary and native speakers do not know it (particularly for obsolete terms), an override {{cd|vn:?}} (for " ..
			"verbal nouns) or {{cd|ap:?}} (for active participles) should be given, and the verb will be placed in this category.",
			parents = {"entry maintenance"},
			hidden = true,
			can_be_empty = true,
		}
		
		labels["verbs needing " .. uncertain_slot .. " checked"] = {
			description = ("{{{langname}}} verbs where the %s needs to be verified."):format(uncertain_slot),
			additional = ("This means that the %s was specified with a '?' at the end of it, indicating uncertainty."):format(uncertain_slot),
			parents = {"entry maintenance"},
			hidden = true,
			can_be_empty = true,
		}
	end
		
	labels["verbs needing passive checked"] = {
		description = "{{{langname}}} verbs where the passive needs to be verified.",
		additional = "This means either that the passive indicator was specified with a '?' at the end of it, indicating " ..
		"uncertainty, or that the passive indicator wasn't given and the default has enough exceptions that it's considered " ..
		"uncertain (e.g. full passives for form I and for V).",
		parents = {"entry maintenance"},
		hidden = true,
		can_be_empty = true,
	}

	labels["verbs with defaulted passive"] = {
		description = "{{{langname}}} verbs where the passive wasn't explicitly specified and was set to a default value.",
		parents = {"entry maintenance"},
		hidden = true,
		can_be_empty = true,
	}

	labels["bad invocations of Template:ar-verb form"] = {
		description = "{{{langname}}} invocations of {{tl|ar-verb form}} using auto-conjugation-fetching that couldn't be resolved to any verb forms.",
		parents = {"entry maintenance"},
		hidden = true,
		can_be_empty = true,
	}

	-- Normally only for Maltese, but could be e.g. for Moroccan Arabic as well.
	labels["unadapted loan verbs"] = {
		description = "{{{langname}}} borrowed verbs that are not assimilated to the triliteral or quadriliteral structure of typical {{{langname}}} verbs.",
		parents = {"verbs by inflection type"},
		breadcrumb = "unadapted loan",
	}

	-- Normally only for Maltese, but could be e.g. for Moroccan Arabic as well.
	for _, typ in ipairs { "i-type", "a-type" } do
		labels[typ .. " unadapted loan verbs"] = {
			description = "{{{langname}}} " .. typ .. " borrowed verbs that are not assimilated to the triliteral or quadriliteral structure of typical {{{langname}}} verbs.",
			parents = {"unadapted loan verbs"},
			breadcrumb = {name = typ, nocap = true},
		}
	end
end


--------------------------------- Verb handlers --------------------------------

local function add_verb_handlers(labels, handlers, lang)
	local langcode = lang:getCode()
	-- FIXME! Create variety-specific verb appendices.
	local verb_appendix = langcode == "mt" and "Appendix:Maltese verbs" or "Appendix:Arabic verbs"
	-- FIXME! No current [[Appendix:Maltese verbs]]. Create it!
	local remove_appendix_links = langcode == "mt"

	local W = langcode == "mt" and "{{lang|mt|w}}" or "{{lang|{{{langcode}}}|و}}"
	local Y = langcode == "mt" and "{{lang|mt|j}}" or "{{lang|{{{langcode}}}|ي}}"
	local HAMZA = "{{lang|{{{langcode}}}|ء}}"

	local weakness_english = {
		["assimilated+final-weak"] = "both assimilated and final-weak",
	}

	local weakness_desc = {
		["geminate"] = "This includes verbs where the second and third radicals are identical and the vowel between " ..
			"them is deleted in some parts of the conjugation. Note that not all verbs whose second and third radicals " ..
			"are identical conjugate as geminate; e.g. form-II and form-V verbs do not, and form-III and form-VI verbs " ..
			"do so only optionally.",
		["assimilated"] = "Generally this only includes form-I verbs where the first radical is " .. W .. ", leading to a " ..
			"shortened non-past stem.",
		["hollow"] = "This includes verbs where the second radical is " .. W .. " or " .. Y .. " and appears as a vowel " ..
			"in most parts of the conjugation. This does not include all verbs whose second radical is weak. " ..
			"For example, form-II, -III, -V and -VI verbs with a weak second radical do not conjugate as hollow, " ..
			"and some verbs that would be expected to conjugate as hollow do not, e.g. form-VIII " ..
			"{{m|ar|اِزْدَوَجَ||to be doubled, to appear twice}}, which irregularly conjugates as a sound verb.",
		["final-weak"] = "This includes verbs where the the last radical is " .. W .. " or " .. Y .. ", leading to irregular endings. " ..
			"Note that almost all verbs whose last radical is weak conjugate as final-weak; the only exceptions are a few irregular " ..
			"verbs such as {{m|ar|حَيَّ||to live}}, also written {{m|ar|حَيِيَ}}.",
		["assimilated+final-weak"] = "Generally this only includes form-I verbs where the first radical is " .. W ..
			" and the last radical is " .. W .. " or " .. Y .. ", leading to irregular endings and a shortened non-past stem.",
		["sound"] = "This includes regular verbs without any irregularities caused by weak (" .. W .. " or " .. Y .. ") radicals." ..
			"Note that some verbs with weak radicals nonetheless conjugate as sound.",
	}

	local trilit_form_to_number = {
		["I"] = 1,
		["II"] = 2,
		["III"] = 3,
		["IV"] = 4,
		["V"] = 5,
		["VI"] = 6,
		["VII"] = 7,
		["VIII"] = 8,
		["IX"] = 9,
		["X"] = 10,
		["XI"] = 11,
		["XII"] = 12,
		["XIII"] = 13,
		["XIV"] = 14,
		["XV"] = 15,
	}

	local quadlit_form_to_number = {
		["Iq"] = 1,
		["IIq"] = 2,
		["IIIq"] = 3,
		["IVq"] = 4,
	}

	local function form_to_sort_key(form, with_space)
		if trilit_form_to_number[form] then
			if with_space then
				return (" %02d"):format(trilit_form_to_number[form])
			else
				return "" .. trilit_form_to_number[form]
			end
		elseif quadlit_form_to_number[form] then
			if with_space then
				return (" %02dq"):format(quadlit_form_to_number[form])
			else
				return "" .. quadlit_form_to_number[form]
			end
		else
			return nil
		end
	end

	local function form_link(form)
		local retval = "[[" .. verb_appendix .. "#Form " .. form .. "|form-" .. form .. "]]"
		if remove_appendix_links then
			return require("Module:links").remove_links(retval)
		else
			return retval
		end
	end

	local function weakness_link(weakness)
		local retval
		if weakness == "hamzated" then
			retval = "[[" .. verb_appendix .. "#Hamzated verbs|hamzated]]"
		elseif weakness == "geminate" then
			retval = "[[" .. verb_appendix .. "#Geminate verbs|geminate]]"
		elseif weakness == "sound" then
			retval = "sound"
		else
			retval = "[[" .. verb_appendix .. "#Weak verbs|" .. (weakness_english[weakness] or weakness) .. "]]"
		end
		if remove_appendix_links then
			return require("Module:links").remove_links(retval)
		else
			return retval
		end
	end

	-- Entries for e.g. [[:Category:Arabic final-weak verbs]]. Use entries instead of a handler
	-- so that children show up in [[:Category:Arabic verbs by inflection type]].
	for weakness, desc in pairs(weakness_desc) do
		labels[weakness .. " verbs"] = {
			description = "{{{langname}}} verbs conjugated as " .. weakness_link(weakness) .. ".",
			additional = weakness_desc[weakness],
			parents = {
				{name = "verbs by inflection type", sort = weakness},
			},
			breadcrumb = weakness,
		}
	end

	-- Handler for e.g. [[:Category:Arabic form-VIII verbs]].
	table.insert(handlers, function(data)
		local form = data.label:match("^form%-([IVX]+q?) verbs$")
		if not form then
			return nil
		end
		local form_sort_key = form_to_sort_key(form, "with space")
		if not form_sort_key then
			return nil
		end
		local parents = {
			{name = "verbs by inflection type", sort = form_sort_key},
		}
		if form:find("q$") then
			table.insert(parents, {name = "verbs with quadriliteral roots", sort = form_sort_key})
		end
		return {
			description = "{{{langname}}} " .. form_link(form) .. " verbs.",
			parents = parents,
			breadcrumb = "form " .. form,
		}
	end)

	-- Handler for e.g. [[:Category:Arabic final-weak form-VIII verbs]].
	table.insert(handlers, function(data)
		local weakness, form = data.label:match("^([a-z+-]+) form%-([IVX]+q?) verbs$")
		if not weakness or not weakness_desc[weakness] then
			return nil
		end
		local form_sort_key = form_to_sort_key(form)
		if not form_sort_key then
			return nil
		end
		return {
			description = "{{{langname}}} " .. form_link(form) .. " verbs conjugated as " .. weakness_link(weakness) .. ".",
			additional = weakness_desc[weakness],
			parents = {
				{name = "form-" .. form .. " verbs", sort = weakness},
				{name = weakness .. " verbs", sort = form_sort_key},
			},
			breadcrumb = weakness,
		}
	end)

	labels["reduced verbs"] = {
		description = "{{{langname}}} " .. form_link("I") .. " verbs categorized by the particular vowel (''a'', ''i'' or " ..
			"''u'') occurring as the last vowel of the past and non-past verb stems.",
		parents = {{name = "verbs by inflection type", sort = "reduced"}},
		breadcrumb = "reduced",
	}

	local reduced_verb_desc = {
		V = "These verbs have the form {{m|ar||اِفَّعَّلَ}} instead of normal {{m|ar||تَفَعَّلَ}}, e.g. {{m|ar|اِصَّدَّقَ||to give alms}}, the reduced variant of {{m|ar|تَصَدَّقَ}}. The first radical is always [[coronal]], and the prefix assimilates completely to it. These are normally found only in the Koran.",
		VI = "These verbs have the form {{m|ar||افَّاعَلَ}} instead of normal {{m|ar||تفَاعَلَ}}, e.g. {{m|ar|اِدَّارَأَ||to dispute}}, the reduced variant of {{m|ar|تَدَارَأَ}}. The first radical is always [[coronal]], and the prefix assimilates completely to it. These are normally found only in the Koran.",
		VII = "These verbs have the form {{m|ar||اِمَّعَلَ}} instead of normal {{m|ar||اِنْمَعَلَ}}, e.g. {{m|ar|اِمَّحَى||to be erased, to disappear}}, the reduced variant of {{m|ar|اِنْمَحَى}}. The first always {{m|ar|م}}, and the prefix assimilates completely to it. Unlike other reduced verbs, these are found in common usage today.",
		X = "These verbs have the form {{m|ar||اِسْفَالَ}} instead of normal {{m|ar||اِسْتَفَالَ}}, e.g. {{m|ar|اِسْطَاعَ||to be able}}, the reduced variant of {{m|ar|اِسْتَطَاعَ}}. The first radical is always [[coronal]], and the last part of the prefix is elided before it. These are normally found only in the Koran.",
	}
	-- Handler for e.g. [[:Category:Arabic form-V reduced verbs]].
	table.insert(handlers, function(data)
		local breadcrumb, form = data.label:match("^(form%-([IVX]+q?)) reduced verbs$")
		if not form then
			return nil
		end
		local form_sort_key = form_to_sort_key(form)
		if not form_sort_key then
			return nil
		end
		local desc = reduced_verb_desc[form]
		if not desc then
			return nil
		end
		return {
			description = ("{{{langname}}} %s verbs where the prefix assumes a modified form and partly assimilates to " ..
				"the initial root consonant. " .. desc):format(form_link(form)),
			parents = {
				{name = "reduced verbs", sort = form_sort_key},
				{name = ("form-%s verbs"):format(form), sort = "reduced"},
			},
			breadcrumb = breadcrumb,
		}
	end)

	local weak_radicals = m_table.listToSet(langcode == "mt" and {"w", "j"} or {"و", "ي", "ء"})
	local ordinal_to_cardinal = {
		["first"] = 1,
		["second"] = 2,
		["third"] = 3,
		["fourth"] = 4,
	}

	-- Handler for e.g. [[:Category:Arabic form-IV verbs with و as second radical]].
	table.insert(handlers, function(data)
		local form, breadcrumb, radical, ordinal = rmatch(data.label, "^form%-([IVX]+q?) verbs with ((.) as ([a-z]+) radical)$")
		if not form then
			return nil
		end
		local form_sort_key = form_to_sort_key(form)
		if not form_sort_key then
			return nil
		end
		if not weak_radicals[radical] or not ordinal_to_cardinal[ordinal] then
			return nil
		end
		local cardinal = ordinal_to_cardinal[ordinal]
		return {
			description = "{{{langname}}} " .. form_link(form) .. " verbs having {{lang|{{{langcode}}}|" ..
				radical .. "}} as their " .. ordinal .. " radical.",
			parents = {
				{name = "form-" .. form .. " verbs", sort = radical .. cardinal},
			},
			breadcrumb = breadcrumb,
		}
	end)

	local vowels_to_desc = {
		["a-u"] = "This is the most common pattern and is used mostly for non-stative verbs.",
		["a-i"] = "This is a very common pattern and is used mostly for non-stative verbs.",
		["a-a"] = "This is a common pattern and is a variant of the ''a~u'' and ''a~i'' patterns, used especially when the second or third radical is a guttural ({{lang|{{{langcode}}}|ع}}, {{lang|{{{langcode}}}|ح}}, {{lang|{{{langcode}}}|ه}}, {{lang|{{{langcode}}}|ء}} or sometimes {{lang|{{{langcode}}}|غ}} or {{lang|{{{langcode}}}|خ}}), and used mostly for non-stative verbs.",
		["i-a"] = "This is a common pattern for stative verbs but sometimes is also used for non-stative verbs.",
		["i-i"] = "This is a rare pattern, a variant of the ''i~a'' pattern often found especially when " .. W .. " is the first radical.",
		["u-u"] = "This is a relatively common pattern, used almost exclusively for intransitive stative verbs.",
	}
	local A  = u(0x064E) -- fatḥa
	local U  = u(0x064F) -- ḍamma
	local I  = u(0x0650) -- kasra
	local vowel_to_diacritic = {
		a = A,
		i = I,
		u = U,
	}

	labels["form-I verbs by vowel"] = {
		description = "{{{langname}}} " .. form_link("I") .. " verbs categorized by the particular vowel (''a'', ''i'' or " ..
			"''u'') occurring as the last vowel of the past and non-past verb stems.",
		parents = {{name = "form-I verbs", sort = " "}},
		breadcrumb = "by vowel",
	}

	-- Handler for e.g. [[:Category:Arabic form-I verbs with past vowel a and non-past vowel u]]
	table.insert(handlers, function(data)
		local past_vowel, nonpast_vowel = data.label:match("^form%-I verbs with past vowel ([aiu]) and non%-past vowel ([aiu])$")
		if not past_vowel then
			return nil
		end
		local sort_key = ("%s-%s"):format(past_vowel, nonpast_vowel)
		local desc = vowels_to_desc[sort_key]
		if not desc then
			return nil
		end
		return {
			description = ("{{{langname}}} %s verbs with their past vowel ''%s'' ({{m|{{{langcode}}}||فَع%sلَ}}) and their " ..
				"non-past vowel ''%s'' ({{m|{{{langcode}}}||يَفْع%sلُ}}). In both cases, the vowel in question is the last " ..
				"vowel in the stem, which varies from verb to verb. " .. desc):format(form_link("I"), past_vowel,
				vowel_to_diacritic[past_vowel], nonpast_vowel, vowel_to_diacritic[nonpast_vowel]),
			parents = {{name = "form-I verbs by vowel", sort = sort_key}},
			displaytitle = ("{{{langname}}} form-I verbs with past vowel ''%s'' and non-past vowel ''%s''"):format(
				past_vowel, nonpast_vowel),
			breadcrumb = ("past ''%s'', non-past ''%s''"):format(past_vowel, nonpast_vowel),
		}
	end)
end



-----------------------------------------------------------------------------
--                                                                         --
--                                 WRAPPERS                                --
--                                                                         --
-----------------------------------------------------------------------------

function export.add_labels_and_handlers(labels, handlers, lang)
	-- labels
	add_root_labels(labels, lang)
	add_noun_adjective_labels(labels, lang)
	add_verb_labels(labels, lang)
	-- handlers
	add_noun_adjective_handlers(handlers, lang)
	add_verb_handlers(labels, handlers, lang)
end


return export
