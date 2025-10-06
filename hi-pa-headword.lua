-- Common code between [[Module:hi-headword]] and [[Module:pa-headword]].

local export = {}
local m_links = require("Module:links")

export.pos_functions = {}

local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsplit = mw.text.split

local list_param = {list = true, disallow_holes = true}
local boolean_param = {type = "boolean"}
local gender_param = {type = "genders"}
local gender_param_with_default = {type = "genders", default = "?"}

local function glossary_link(anchor, text)
	text = text or anchor
	return "[[Appendix:Glossary#" .. anchor .. "|" .. text .. "]]"
end

local function validate_genders(data, genders)
	data.genders = genders
	for _, gspec in ipairs(genders) do
		local g = gspec.g
		if g == "m" or g == "f" or g == "m-p" or g == "f-p" or g == "mf" or g == "mf-p" or g == "mfbysense" or g == "mfbysense-p" or g == "?" then
		else
			error("Invalid gender: " .. g)
		end
	end
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(data, args, field, is_head)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	return m_headword_utilities.parse_term_list_with_modifiers {
		forms = args[argfield],
		paramname = field,
		splitchar = ",",
		is_head = is_head,
		include_mods = not is_head and {"tr"} or nil,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel_form)
	local terms = parse_inflection(data, args, field)
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel_form and {form = accel_form} or nil,
	}
end

export.pos_functions.adjectives = {
	params = {
		[1] = {list = "comp", disallow_holes = true},
		[2] = {list = "sup", disallow_holes = true},
		["f"] = list_param,
		["m"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable adjectives")
		end
		parse_and_insert_inflection(data, args, {1, "comp"}, "<<comparative>>")
		parse_and_insert_inflection(data, args, {2, "sup"}, "<<superlative>>")
		parse_and_insert_inflection(data, args, "m", "masculine")
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

export.pos_functions.ordinals = {
	params = {
		["f"] = list_param,
		["m"] = list_param,
		["ind"] = boolean_param,
	},
	func = function(args, data)
		data.pos_category = "adjectives"
		table.insert(data.categories, data.langname .. " numerals")
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable numerals")
		end
		parse_and_insert_inflection(data, args, "m", "masculine")
		parse_and_insert_inflection(data, args, "f", "feminine")
	end,
}

export.pos_functions.cardinals = {
	params = {
		[1] = gender_param,
		["g"] = {alias_of = 1}, -- FIXME, delete
		["g2"] = true, -- FIXME, delete
		["sym"] = list_param,
	},
	func = function(args, data)
		data.pos_category = "numerals"
		validate_genders(data, args[1])
		parse_and_insert_inflection(data, args, "sym", "native script symbol")
	end,
}

local function nouns(plpos)
	return {
		params = {
			[1] = gender_param_with_default,
			["g"] = {alias_of = 1}, -- FIXME, delete
			["g2"] = true, -- FIXME, delete
			["pl"] = list_param,
			["f"] = list_param,
			["m"] = list_param,
			["ind"] = boolean_param,
		},
		func = function(args, data)
			validate_genders(data, args[1])
			if args["ind"] then
				if args["pl"][1] then
					error("Can't specify both ind= and pl=")
				end
				table.insert(data.inflections, {label = glossary_link("indeclinable")})
				table.insert(data.categories, data.langname .. " indeclinable " .. plpos)
			else
				parse_and_insert_inflection(data, args, "pl", "plural")
			end
			parse_and_insert_inflection(data, args, "m", "masculine")
			parse_and_insert_inflection(data, args, "f", "feminine")
			if args["m"][1] or args["f"][1] then
				table.insert(data.categories, data.langname .. " " .. plpos .. " with other-gender equivalents")
			end
		end,
	}
end

export.pos_functions.nouns = nouns("nouns")
export.pos_functions["proper nouns"] = nouns("proper nouns")

export.pos_functions.pronouns = {
	params = {
		[1] = gender_param,
		["g"] = {alias_of = 1}, -- FIXME, delete
		["g2"] = true, -- FIXME, delete
	},
	func = function(args, data)
		validate_genders(data, args[1])
	end,
}

export.pos_functions.verbs = {
	params = {
		[1] = true,
	},
	func = function(args, data)
		if args[1] then
			local label, cat
			if args[1] == "t" then
				label = "transitive"
				table.insert(data.categories, data.langname .. " transitive verbs")
			elseif args[1] == "i" then
				label = "intransitive"
				table.insert(data.categories, data.langname .. " intransitive verbs")
			elseif args[1] == "d" then
				label = "ditransitive"
				table.insert(data.categories, data.langname .. " ditransitive verbs")
			elseif args[1] == "it" or args[1] == "ti" then
				label = "ambitransitive"
				table.insert(data.categories, data.langname .. " transitive verbs")
				table.insert(data.categories, data.langname .. " intransitive verbs")
			else
				error("Unrecognized param 1=" .. args[1] .. ": Should be 'i' = intransitive, 't' = transitive, or 'it'/'ti' = ambitransitive")
			end
			table.insert(data.inflections, {label = glossary_link(label)})
		end

		local head = data.heads[1]
		if head:find(" ") then
			local base_verb = m_links.remove_links(head):gsub("^.* ", "")
			table.insert(data.categories, data.langname .. " compound verbs formed with " .. base_verb)
		end
	end,
}

local function pos_with_gender()
	return {
		params = {
			[1] = gender_param,
			["g"] = {alias_of = 1}, -- FIXME, delete
			["g2"] = true, -- FIXME, delete
		},
		func = function(args, data)
			validate_genders(data, args[1])
		end,
	}
end

export.pos_functions.numerals = pos_with_gender()
export.pos_functions.suffixes = pos_with_gender()
export.pos_functions["adjective forms"] = pos_with_gender()
export.pos_functions["noun forms"] = pos_with_gender()
export.pos_functions["pronoun forms"] = pos_with_gender()
export.pos_functions["determiner forms"] = pos_with_gender()
export.pos_functions["verb forms"] = pos_with_gender()
export.pos_functions["postposition forms"] = pos_with_gender()

return export
