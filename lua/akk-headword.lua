local export = {}
local pos_functions = {}

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("akk")

-- The main entry point.
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		include_ts = true,
	}
end

local valid_genders = {"m", "f", "m-d", "f-d", "m-p", "f-p", "?"}

pos_functions["nouns"] = {
	infls = {
		{1, type = "genders", valid_genders = valid_genders, default = "?"},
		{"base", label = "base"},
		{"cons", label = "construct state"},
		{"pron", label = "pronominal state"},
		{"abs", label = "absolute state"},
		{"d", label = "dual"},
		{"pl", label = "plural"},
		{"f", label = "female equivalent"},
		{"m", label = "male equivalent"},
	},
}

pos_functions["adjectives"] = {
	infls = {
		{"f", label = "feminine"},
		{"mpl", label = "masculine plural"},
		{"fpl", label = "feminine plural"},
		{"pred", label = "predicative"},
	},
}

pos_functions["verbs"] = {
	infls = {
		{1, set = {"G", "D", "Š", "N", "Gt", "Dt", "Št", "Nt", "Gtn", "Dtn", "Štn", "Ntn", "ŠD"},
			doclabel = "stem", fixed_label = "[[w:Akkadian language#Verb patterns|{val}]]",
			cat = "{val}-stem verbs",
		},
		{2, doclabel = "class", fixed_label = "[[w:Akkadian language#Verb patterns|{val}]]",
			cat = "class {val} verbs",
		},
		{"dur", label = "durative"},
		{"perf", label = "perfect"},
		{"pret", label = "preterite"},
		{"imp", label = "imperative"},
		{"partic", label = "participle"},
		{"vadj", label = "verbal adjective"},
	},
}

return export
