local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local lang = require("Module:languages").getByCode("ar")

-- The main entry point.
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = "iparam-or-1", -- language comes from lang= in iparams or (if not given) 1= in template params
		frame = frame,
		pos_functions = pos_functions,
		force_cat = force_cat,
		include_tr = true,
		enable_auto_translit = true,
		numbered_head = true,
	}
end

local valid_genders = {"m", "f", "m-p", "f-p", "p", "m-d", "f-d", "d", "?"}

local verb_forms = {
	"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX",
	"X", "XI", "Iq", "IIq", "def", "irreg",
}

pos_functions["head"] = (function()
	local infls
	infls.nouns = {
		{2, type = "genders", validate = valid_genders, default = "?"},
		{"cons", label = "construct state"},
		{"d", label = "dual"},
		-- countable/uncountable cats added automatically
		{"pl", label = "plural"},
		{"pauc", label = "paucal"},
		-- 'nouns with other-gender equivalents' gets added automatically
		{"f", label = "female equivalent"},
		{"m", label = "male equivalent"},
		{"dim", label = "diminutive"},
	}
	infls["proper nouns"] = infls
	local function not_invariable_adj(data, vals)
		if data.process_props.args.inv then
			error(("Not allowed to specify |%s= along with |inv=1"):format(data.process_props.current_param))
		end
	end
	infls.adjectives = {
		{"inv", type = "boolean", fixed_label = "invariable"},
		{"f", label = "feminine", validate = not_invariable_adj},
		{"pl", label = "plural", validate = not_invariable_adj},
		{"cpl", label = "common plural", validate = not_invariable_adj},
		{"mpl", label = "masculine plural", validate = not_invariable_adj},
		{"fpl", label = "feminine plural", validate = not_invariable_adj},
		{"dim", label = "diminutive"},
		{"el", label = "elative"},
		{"der", validate = {"active", "passive"}, cat = "terms derived from {val} participles"},
	}
	infls.numerals = {
		{2, type = "genders", validate = valid_genders},
		{"cons", label = "construct state"},
		{"d", label = "dual"},
		{"pl", label = "plural"},
		{"pauc", label = "paucal"},
		{"f", label = "feminine"},
		{"m", label = "masculine"},
		{cat = "cardinal numbers"},
	}
	local function do_collective_singulative(this_type, this_gender, other_type, other_param, other_gender)
		infls[this_type .. " nouns"] = {
			pos_category = "nouns",
			{fixed_label = ("<<%s>>"):format(this_type), cat = this_type .. " nouns"},
			{2, type = "genders", validate = valid_genders, default = this_gender},
			{other_param, label = ("<<%s>>"):format(other_type), include_mods = {"g"},
				process_after_parse = function(data, vals)
					for _, valobj in ipairs(vals) do
						if valobj.genders == nil then
							valobj.genders = {{spec = other_gender}}
						end
					end
				end,
			},
			{"cons", label = "construct state"},
			{"d", label = "dual"},
			{"pauc", label = "paucal"},
			{"pl", label = "plural"},
			{"dim", label = "diminutive"},
		}
	end
	do_collective_singulative("collective", "m", "singulative", "sing", "f")
	do_collective_singulative("singulative", "f", "collective", "coll", "m")
	infls["verbal nouns"] = {
		{2, type = "genders", validate = valid_genders, default = "?"},
		{"inst", label = "instance noun"},
	}
	infls["noun forms"] = {
		{2, type = "genders", validate = valid_genders}
	}
	infls["proper noun forms"] = infls["noun forms"]
	infls["pronoun forms"] = infls["noun forms"]
	infls["adjective forms"] = infls["noun forms"]
	infls["determiner forms"] = infls["noun forms"]
	infls["numeral forms"] = infls["noun forms"]

	local function make_verb_form_label(data, val)
		local form = val.term
		if form == "irreg" then
			return "irregular"
		elseif form == "def" then
			return "defective"
		else
			return ("[[Appendix:Arabic verbs#Form %s|form %s]]"):format(form, form)
		end
	end

	infls["verb forms"] = {
		{2, fixed_label = make_verb_form_label},
	}
	infls.prepositions = {
		{2, type = "genders", validate = valid_genders},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	}
	infls.determiners = {
		{2, type = "genders", validate = valid_genders},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	}
	infls.adverbs = {
		{"obl", label = "oblique form"},
	}
	infls.suffixes = { -- FIXME: Eliminate.
		{2, type = "genders", validate = valid_genders},
		{"f", label = "feminine"},
		{"pl", label = "plural"},
	}

	return {
		infls = infls,
	}
end)

local function handle_gender(args, data, default, nonlemma, optional)
	local g = ine(args["g"]) or default
	local g2 = ine(args["g2"])

	local function process_gender(gender)
		if not gender and not optional then
			table.insert(data.genders, "?")
		elseif not gender and optional then
			-- do nothing
		elseif valid_genders[g] then
			table.insert(data.genders, gender)
		else
			error("Unrecognized gender: " .. gender)
		end
	end

	process_gender(g)
	if g2 then
		process_gender(g2)
	end
end

-- Part-of-speech functions

function handle_noun_infls(args, data, singonly)
	handle_all_infl(args, data, "", "")

	if not singonly then
		handle_all_infl(args, data, "d", "dual")
		handle_noun_plural(args, data)
		handle_all_infl(args, data, "pl", "plural", "nobase")
		handle_all_infl(args, data, "pauc", "paucal", "nobase")
	end

	handle_all_infl(args, data, "f", "feminine")
	handle_all_infl(args, data, "m", "masculine")

	if not singonly then
		handle_all_infl(args, data, "dim", "diminutive")
	end
end

pos_functions["pronouns"] = {
	params = {
		["g"] = {},
		["g2"] = {}
	},
	func = function(args, data)
		handle_gender(args, data, nil, nil, true)
		handle_infl(args, data, "encl", "enclitic form")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "pl", "plural")
	end
}

pos_functions["active participles"] = {
	params = {
		[2] = {}
	},
	func = function(args, data)
		data.pos_category = "participles"
		append_cat(data, "active participles")
		handle_infl(args, data, "", "")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "cpl", "common plural")
		handle_infl(args, data, "pl", "masculine plural")
		handle_infl(args, data, "fpl", "feminine plural")
	end
}

pos_functions["passive participles"] = {
	params = {
		[2] = {}
	},
	func = function(args, data)
		data.pos_category = "participles"
		append_cat(data, "passive participles")
		handle_infl(args, data, "", "")
		handle_infl(args, data, "f", "feminine")
		handle_infl(args, data, "cpl", "common plural")
		handle_infl(args, data, "pl", "masculine plural")
		handle_infl(args, data, "fpl", "feminine plural")
	end
}

local lang_exception = { ["ajp"] = true, ["acy"] = true}

	verbs = {
		infls = function(data)

	}
pos_functions["verbs"] = {
	func = function(args, data)
		data.pos_category = "verbs"
		if ine(args[1]) then
			if verb_forms[args[1]] then
				data.gloss = '<abbr title="Form ' .. args[1] .. '">[[Appendix:Arabic verbs#Form ' .. args[1] .. '|' .. args[1] .. ']]</abbr>'
				append_cat(data, "form-" .. args[1] .. " verbs")
			else
				error("Invalid verb form. Please provide a valid one.")
			end
		elseif mw.title.getCurrentTitle().nsText ~= "Template" or args[1] ~= "-" then
			track("verbs lacking forms")
		end
		if lang_exception[lang:getCode()]  then
			handle_infl(args, data, "pres", "present")
			handle_infl(args, data, "subj", "subjunctive")
		else handle_infl(args, data, "np", "non-past") end
		handle_infl(args, data, "vn", "verbal noun")
		handle_infl(args, data, "ap", "active participle")
		handle_infl(args, data, "pp", "passive participle")
	end
}
}

return export
