local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local mn = require("Module:mn-common")

local lang = require(languages_module).getByCode("mn")

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|mn-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		include_sc = true,
		force_cat = force_cat,
		infls = {
			{function(data) return data.generic_pos_template and 2 or 1 end,
				docparam = "{{para|2}} for {{tl|mn-head}}, {{para|1}} otherwise",
				label = function(_data, vals)
					return lang:findBestScript(vals[1].term):getCanonicalName(lang) .. " spelling"
				end,
				doclabel = "other-script spellings",
				process_after_parse = function(data, vals)
					for _, valobj in ipairs(vals) do
						local other_sc = lang:findBestScript(valobj.term)
						if data.sc:getCode() == other_sc:getCode() then
							error(("The headword and alternative spelling %s are both in %s but should be in different scripts"):format(
								valobj.term, data.sc:getCanonicalName(lang)
							))
						end
						valobj.enable_auto_translit = true
					end
					return vals
				end,
				addldoc = "These consist of spellings in Mongolian script if the pagename is Cyrillic, and " ..
					"vice-versa. An error is thrown if the other-script spelling is in the same script as " ..
					"the pagename.",
			}, 
			{cat = function(data)
				if not data.pagename:find("^%-") and not data.pagename:find(" ") and data.sc:getCode() == "Cyrl" then
					-- FIXME, should be done by {{mn-IPA}}
					return #mn.syllables(data.pagename) .. "-syllable words"
				end
			end,
			doc = "If the pagename is not a suffix, does not have a space in it and is in Cyrillic, a category " ..
				"such as {{catlink|Mongolian 3-syllable words}} (depending on the number of syllables in the " ..
				"word) will be added. (FIXME, this should be done by {{tl|mn-IPA}} instead.)",
			},
		},
	}
end

local valid_declensions = {
	r = "regular",
	n = "hidden-n",
	g = "hidden-g",
	m = "mixed",
}

pos_functions["nouns"] = {
	infls = {
		{"dec", doclabel = "declension", validate = valid_declensions,
			fixed_label = function(data, val)
				return valid_declensions[val.term] .. " declension"
			end,
			cat = function(data, val)
				return valid_declensions[val.term] .. " nouns"
			end,
		},
		{"pl", label = "definite plural"},
	},
}
pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["verbs"] = {
	infls = {
		{"caus", label = "causative"},
		{"pass", label = "passive"},
	},
}

return export
