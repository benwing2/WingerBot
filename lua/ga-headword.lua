local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("ga")

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local table_module = "Module:table"
local m_headword_utilities = require("Module:headword utilities")

local insert = table.insert
local dump = mw.dumpObject

local umatch = mw.ustring.match

local valid_genders = {
	"m", "f", "m-p", "f-p", "?",
}

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|ga-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return m_headword_utilities.process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		force_cat = force_cat,
	}
end

local function is_special_suffix_chop_shortcut(data, val)
	return not not val.term:find("^%-.")
end

local function handle_special_suffix_chop_shortcut(termobj)
	local suffix = termobj.infl.term:match("^%-(.+)$")
	if not suffix then
		error(("Internal error: Misformed special shortcut '%s' passed in: %s"):format(
			termobj.infl.term, dump(termobj)))
	end
	local pagename = termobj.headdata.pagename
	local chopped_pagename = umatch(pagename,
		"^(.-)[aeiouAEIOUáéíóúÁÉÍÓÚ]+[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]*$")
	if not chopped_pagename then
		error(("Unable to use suffix-chop shortcut because the pagename '%s' doesn't end in a vowel cluster " ..
			"followed by optional consonant cluster"):format(pagename))
	end
	return chopped_pagename .. suffix
end

local function augment_infls_with_suffix_chop(infls)
	for _, infl in ipairs(infls) do
		if not infl.type and infl.label and not infl.is_special and not infl.resolve_special then
			infl.is_special = is_special_suffix_chop_shortcut
			infl.resolve_special = handle_special_suffix_chop_shortcut
		end
	end
	return infls
end

pos_functions["adjectives"] = {
	infls = augment_infls_with_suffix_chop {
		{"gsm", label = "genitive singular masculine"},
		{"gsf", label = "genitive singular feminine"},
		{"pl", label = "plural"},
		{"comp", label = "comparative"},
	}
}

local adverb_types = {
	"demonstrative", "interrogative", "pronominal", "relative",
	"aspect",
	"conjunctive", "sequence",
	"degree",
	"focus",
	"location", "movement", "position",
	"manner",
	"time", "duration", "frequency", "point-in-time",
}

function export.make_adverb_type_table(_frame)
	local sorted_adverb_types = require(table_module).shallowCopy(adverb_types)
	table.sort(sorted_adverb_types)
	local output = {}
	local function ins(txt)
		insert(output, txt)
	end
	ins('{| class="wikitable"\n')
	ins("! Type !! Corresponding category\n")
	for _, typ in ipairs(sorted_adverb_types) do
		ins("|-\n")
		ins(("| <code>%s</code> || [[:Category:Irish %s adverbs]]\n"):format(typ, typ))
	end
	ins("|}")
	return table.concat(output)
end

pos_functions["adverbs"] = {
	infls = {
		{"type", validate = adverb_types, all_fixed_label = "{vals} adverb", cat = "{val} adverbs"},
	}
}

pos_functions["nouns"] = {
	infls = augment_infls_with_suffix_chop {
		{1, type = "genders", valid_genders = valid_genders, default = "?"},
		{2,
			label = function(data)
				return "genitive " .. (m_headword_utilities.is_plurale_tantum(data.genders) and "plural" or "singular") ..
					(data.process_props.args.vngen and " as substantive" or "")
			end,
			request = true,
		},
		{"vngen", label = "genitive as verbal noun"},
		{3, label = "nominative plural", label_for_cats_and_modes = "plural",
			request = function(data) return not m_headword_utilities.is_plurale_tantum(data.genders) end,
		},
		{"f", label = "female equivalent"},
		{"m", label = "male equivalent"},
	}
}

pos_functions["proper nouns"] = {
	infls = augment_infls_with_suffix_chop {
		{1, type = "genders", valid_genders = valid_genders, default = "?"},
		{2, label = "genitive", request = true},
		{3, label = "nominative plural", label_for_cats_and_modes = "plural"},
		{"f", label = "female equivalent"},
		{"m", label = "male equivalent"},
	}
}

pos_functions["verbs"] = {
	infls = augment_infls_with_suffix_chop {
		{"pres", label = "present analytic"},
		{"fut", label = "future analytic"},
		{"vn", label = "verbal noun"},
		{"pp", label = "past participle"},
		{"irreg", type = "boolean", cat = "irregular verbs"},
		{"phrasal", cat = {"phrasal verbs", 'phrasal verbs formed with "{val}"'}},
	},
}

return export
