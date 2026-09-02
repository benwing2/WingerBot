local export = {}
local pos_functions = {}

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("tru")
local insert = table.insert

-- The main entry point.
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		enable_auto_translit = true,
	}
end

local valid_genders = {"m", "f", "m-p", "f-p", "p", "?"}
local gender_param = {type = "genders", default = "?"}

local function handle_gender(data, args)
	data:validate_genders(args[1], valid_genders)
	data.genders = args[1]
end

local function handle_plural_paucal(data)
	-- countable/uncountable cats added automatically
	data:parse_and_insert_inflection("pl", "plural")
	data:parse_and_insert_inflection("pauc", "paucal")
end

-- Nouns and numerals have the same params but interpret m/f differently.
local noun_numeral_params = {
	[1] = gender_param,
	pl = true,
	pauc = true,
	f = true,
	m = true,
}

pos_functions["nouns"] = {
	params = noun_numeral_params,
	func = function(data, args)
		handle_gender(data, args)
		handle_plural_paucal(args)
		-- 'nouns with other-gender equivalents' get added automatically
		data:parse_and_insert_inflection("f", "female equivalent")
		data:parse_and_insert_inflection("m", "male equivalent")
	end,
}

pos_functions["numerals"] = {
	params = noun_numeral_params,
	func = function(data, args)
		data:insert_category("cardinal numbers")
		handle_gender(data, args)
		handle_plural_paucal(args)
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("m", "masculine")
	end,
}

pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["pronouns"] = {
	params = {
		[1] = gender_param,
		f = true,
		pl = true,
	},
	func = function(data, args)
		handle_gender(data, args)
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
	end,
}

pos_functions["adjectives"] = {
	params = {
		f = true,
		mpl = true,
		fpl = true,
	},
	func = function(data, args)
		data:parse_and_insert_inflection("f", "feminine singular")
		data:parse_and_insert_inflection("mpl", "masculine plural")
		data:parse_and_insert_inflection("fpl", "feminine plural")
	end
}

return export
