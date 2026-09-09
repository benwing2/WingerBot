local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("tru")

-- The main entry point.
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		force_cat = force_cat,
		include_tr = true,
		enable_auto_translit = true,
		numbered_head = true,
	}
end

local valid_genders = {"m", "f", "m-p", "f-p", "p", "?"}

pos_functions["nouns"] = {
	infls = {
		{2, type = "genders", validate = valid_genders, default = "?"},
		-- countable/uncountable cats added automatically
		{"pl", label = "plural"},
		{"pauc", label = "paucal"},
		-- 'nouns with other-gender equivalents' gets added automatically
		{"f", label = "female equivalent"},
		{"m", label = "male equivalent"},
	},
}

pos_functions["numerals"] = {
	infls = {
		{2, type = "genders", validate = valid_genders},
		{"pl", label = "plural"},
		{"pauc", label = "paucal"},
		{"f", label = "feminine"},
		{"m", label = "masculine"},
		{cat = "cardinal numbers"},
	},
}

pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["pronouns"] = {
	infls = {
		{2, type = "genders", validate = valid_genders},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	},
}

pos_functions["adjectives"] = {
	infls = {
		{"f", label = "feminine"},
		{"mpl", label = "masculine plural"},
		{"fpl", label = "feminine plural"},
	},
}

return export
