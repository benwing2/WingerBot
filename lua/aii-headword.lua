local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("aii")

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
		{2, type = "genders", valid_genders = valid_genders, default = "?"},
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
		{cat = "cardinal numbers"},
		{2, type = "genders", valid_genders = valid_genders},
		{"pl", label = "plural"},
		{"f", label = "feminine"},
		{"m", label = "masculine"},
		{"cons", label = "construct"},
	},
}

pos_functions["proper nouns"] = pos_functions["nouns"]

local function do_pronouns_interjections(plpos)
	return {
		infls = {
			{2, type = "genders", valid_genders = valid_genders, default = plpos == "pronouns" and "?" or nil},
			{"sg", label = "singular", comma_desc = "used when the {pos} is plural and the singular is not distinguished for gender"},
			{"m", label = "masculine", comma_desc = "used when the {pos} is feminine singular"},
			{"msg", label = "masculine singular", comma_desc = "used when the {pos} is plural and the singular is distinguished for gender"},
			{"f", label = "feminine", comma_desc = "used when the {pos} is masculine singular"},
			{"fsg", label = "feminine singular", comma_desc = "used when the {pos} is plural and the singular is distinguished for gender"},
			{"pl", label = "plural", comma_desc = "used when the {pos} is singular and the plural is not distinguished for gender"},
			{"mpl", label = "masculine plural", comma_desc = "used when the {pos} is singular (and the plural is distinguished for gender) or the POS is feminine plural"},
			{"fpl", label = "feminine plural", comma_desc = "used when the {pos} is singular (and the plural is distinguished for gender) or the POS is masculine plural"},
			{"pauc", label = "paucal"},
		},
	}
end

pos_functions.pronouns = do_pronouns_interjections("pronouns")
-- Strange, but the old code supported gendered variants of interjections.
pos_functions.interjections = do_pronouns_interjections("interjections")

pos_functions["determiners"] = {
	infls = {
		{2, type = "genders", valid_genders = valid_genders},
		{"m", label = "masculine"},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	},
}

pos_functions["adjectives"] = {
	infls = {
		{"f", label = "feminine"},
		{"pl", label = "plural"},
		{"mpl", label = "masculine plural"},
		{"fpl", label = "feminine plural"},
	},
}

--- Non-lemma forms

pos_functions["past participles"] = {
	infls = {
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	},
}

return export
