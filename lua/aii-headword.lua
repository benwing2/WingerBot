local export = {}
local pos_functions = {}

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("aii")
local insert = table.insert

-- The main entry point.
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		enable_auto_translit = true,
		head_in_1 = true,
	}
end

local valid_genders = {"m", "f", "m-p", "f-p", "p", "?"}
local gender_param_with_default = {type = "genders", default = "?"}
local gender_param_no_default = {type = "genders"}

local function handle_gender(data, args)
	data:validate_genders(args[1], valid_genders)
	data.genders = args[1]
end

pos_functions["nouns"] = {
	params = {
		[1] = gender_param_with_default,
		pl = true,
		pauc = true,
		f = true,
		m = true,
	},
	func = function(data, args)
		handle_gender(data, args)
		-- countable/uncountable cats added automatically
		data:parse_and_insert_inflection("pl", "plural")
		data:parse_and_insert_inflection("pauc", "paucal")
		-- 'nouns with other-gender equivalents' get added automatically
		data:parse_and_insert_inflection("f", "female equivalent")
		data:parse_and_insert_inflection("m", "male equivalent")
	end,
}

pos_functions["numerals"] = {
	params = {
		[1] = gender_param_no_default,
		pl = true,
		pauc = true,
		f = true,
		m = true,
		cons = true,
	},
	func = function(data, args)
		data:insert_category("cardinal numbers")
		handle_gender(data, args)
		data:parse_and_insert_inflection("pl", "plural")
		data:parse_and_insert_inflection("pauc", "paucal")
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("m", "masculine")
		data:parse_and_insert_inflection("cons", "construct")
	end,
}

pos_functions["proper nouns"] = pos_functions["nouns"]

local function do_pronouns_interjections(plpos)
	local params = {
		[1] = plpos == "pronouns" and gender_param_with_default or gender_param_no_default,
		sg = true,
		m = true,
		msg = true,
		f = true,
		fsg = true,
		pl = true,
		mpl = true,
		fpl = true,
	}
	return {
		params = params,
		func = function(data, args)
			handle_gender(data, args)
			data:parse_and_insert_inflection("sg", "singular")
			data:parse_and_insert_inflection("m", "feminine")
			data:parse_and_insert_inflection("msg", "masculine singular")
			data:parse_and_insert_inflection("f", "feminine")
			data:parse_and_insert_inflection("fsg", "feminine singular")
			data:parse_and_insert_inflection("pl", "plural")
			data:parse_and_insert_inflection("mpl", "masculine plural")
			data:parse_and_insert_inflection("fpl", "feminine plural")
		end,
	}
end

pos_functions.pronouns = do_pronouns_interjections("pronouns")
-- Strange, but the old code supported gendered variants of interjections.
pos_functions.interjections = do_pronouns_interjections("interjections")

pos_functions["determiners"] = {
	params = {
		[1] = gender_param_no_default,
		m = true,
		f = true,
		pl = true,
	},
	func = function(data, args)
		handle_gender(data, args)
		data:parse_and_insert_inflection("m", "feminine")
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
	end
}

pos_functions["adjectives"] = {
	params = {
		f = true,
		pl = true,
		mpl = true,
		fpl = true,
	},
	func = function(data, _args)
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
		data:parse_and_insert_inflection("mpl", "masculine plural")
		data:parse_and_insert_inflection("fpl", "feminine plural")
	end
}

-- FIXME: Eliminate this.
pos_functions["suffixes"] = {
	params = {
		[1] = gender_param_no_default,
		f = true,
		pl = true,
	},
	func = function(data, args)
		handle_gender(data, args)
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
	end
}

--- Non-lemma forms

pos_functions["past participles"] = {
	params = {
		f = true,
		pl = true,
	},
	func = function(data, _args)
		data:parse_and_insert_inflection("f", "feminine")
		data:parse_and_insert_inflection("pl", "plural")
	end
}

return export
