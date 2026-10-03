local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("gd")

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
: The part of speech, pluralized; omit for {{tl|gd-head}}.
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
		"^(.-)[aeiouAEIOUáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙ]+[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]*$")
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
        {"indecl", type = "boolean", fixed_label = "indeclinable", cat = "indeclinable adjectives"},
		{"gsm", label = "genitive singular masculine"},
		{"gsf", label = "genitive singular feminine"},
		{"pl", label = "plural"},
		{"comp", label = "comparative"},
		{"absn", label = "abstract noun"},
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
		ins(("| <code>%s</code> || [[:Category:Scottish Gaelic %s adverbs]]\n"):format(typ, typ))
	end
	ins("|}")
	return table.concat(output)
end

pos_functions["adverbs"] = {
	infls = {
		{"type", validate = adverb_types, all_fixed_label = "{vals} adverb", cat = "{val} adverbs"},
		{"comp", label = "comparative"},
	}
}

local function generate_noun_pos(is_proper)
	local function make_sing_label(case)
		return is_proper and case or
			function(data)
				return m_headword_utilities.is_plurale_tantum(data.genders) and case or case .. " singular"
			end
	end
    return {
        infls = augment_infls_with_suffix_chop {
            {1, type = "genders", valid_genders = valid_genders, default = "?"},
            {"indecl", type = "boolean", fixed_label = "indeclinable", cat = "indeclinable " .. (is_proper and "proper nouns" or "nouns")},
            {2, label = make_sing_label("genitive"),
				request = function(data)
					return not data.process_props.args.indecl
				end,
			},
            {"dat", label = make_sing_label("dative")},
            {"voc", label = make_sing_label("vocative")},
            {3, label = "nominative plural", label_for_cats_and_modes = "plural",
                request = not is_proper and
                    function(data)
						return not data.process_props.args.indecl and not m_headword_utilities.is_plurale_tantum(data.genders)
					end
                or nil,
            },
            {"genpl", label = "genitive plural"},
			{"dim", label = "diminutive"},
            {"f", label = "female equivalent"},
            {"m", label = "male equivalent"},
        },
    }
end

pos_functions["nouns"] = generate_noun_pos(false)
pos_functions["proper nouns"] = generate_noun_pos(true)

pos_functions["verbs"] = {
	infls = augment_infls_with_suffix_chop {
		{"past", label = "past"},
		{"fut", label = "future"},
		{"vn", label = "verbal noun"},
		{"pp", label = "past participle"},
		{"irreg", type = "boolean", cat = "irregular verbs"},
	},
}

return export
