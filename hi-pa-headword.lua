-- Common code between [[Module:hi-headword]] and [[Module:pa-headword]].

local export = {}
local m_links = require("Module:links")

export.pos_functions = {}

local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsplit = mw.text.split

local function glossary_link(anchor, text)
	text = text or anchor
	return "[[Appendix:Glossary#" .. anchor .. "|" .. text .. "]]"
end

local function process_genders(data, genders)
	for _, g in ipairs(genders) do
		if g == "m" or g == "f" or g == "m-p" or g == "f-p" or g == "mf" or g == "mf-p" or g == "mfbysense" or g == "mfbysense-p" or g == "?" then
			table.insert(data.genders, g)
		else
			error("Invalid gender: " .. (g or "(nil)"))
		end
	end
end

export.pos_functions.adjectives = {
	params = {
		["comparative"] = {},
		["superlative"] = {},
		[1] = {alias_of = "comparative"},
		[2] = {alias_of = "superlative"},
		["f"] = {list = true},
		["m"] = {list = true},
		["ind"] = {type = "boolean"},
	},
	func = function(args, data)
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable adjectives")
		end
		if args["comparative"] then
			table.insert(data.inflections, {label = "comparative", args["comparative"]})
		end
		if args["superlative"] then
			table.insert(data.inflections, {label = "superlative", args["superlative"]})
		end
		if #args["m"] > 0 then
			args["m"].label = "masculine"
			table.insert(data.inflections, args["m"])
		end
		if #args["f"] > 0 then
			args["f"].label = "feminine"
			table.insert(data.inflections, args["f"])
		end
	end,
}

export.pos_functions.ordinals = {
	params = {
		["f"] = {list = true},
		["m"] = {list = true},
		["ind"] = {type = "boolean"},
	},
	func = function(args, data)
		data.pos_category = "adjectives"
		table.insert(data.categories, data.langname .. " numerals")
		if args["ind"] then
			table.insert(data.inflections, {label = glossary_link("indeclinable")})
			table.insert(data.categories, data.langname .. " indeclinable numerals")
		end
		if #args["m"] > 0 then
			args["m"].label = "masculine"
			table.insert(data.inflections, args["m"])
		end
		if #args["f"] > 0 then
			args["f"].label = "feminine"
			table.insert(data.inflections, args["f"])
		end
	end,
}

export.pos_functions.cardinals = {
	params = {
		["g"] = {list = true},
		["sym"] = {list = true},
	},
	func = function(args, data)
		data.pos_category = "numerals"
		process_genders(data, args["g"])
		if #args["sym"] > 0 then
			args["sym"].label = "native script symbol"
			table.insert(data.inflections, args["sym"])
		end
	end,
}

local function nouns(plpos)
	return {
		params = {
			["g"] = {list = true, default = "?"},
			["pl"] = {list = true},
			["f"] = {list = true},
			["m"] = {list = true},
			["ind"] = {type = "boolean"},
		},
		func = function(args, data)
			process_genders(data, args["g"])
			if args["ind"] then
				if #args["pl"] > 0 then
					error("Can't specify both ind= and pl=")
				end
				table.insert(data.inflections, {label = glossary_link("indeclinable")})
				table.insert(data.categories, data.langname .. " indeclinable " .. plpos)
			elseif #args["pl"] > 0 then
				args["pl"].label = "plural"
				table.insert(data.inflections, args["pl"])
			end
			if #args["m"] > 0 then
				args["m"].label = "masculine"
				table.insert(data.inflections, args["m"])
			end
			if #args["f"] > 0 then
				args["f"].label = "feminine"
				table.insert(data.inflections, args["f"])
			end
			if #args["m"] > 0 or #args["f"] > 0 then
				table.insert(data.categories, data.langname .. " " .. plpos .. " with other-gender equivalents")
			end
		end,
	}
end

export.pos_functions.nouns = nouns("nouns")
export.pos_functions["proper nouns"] = nouns("proper nouns")

export.pos_functions.pronouns = {
	params = {
		["g"] = {list = true},
	},
	func = function(args, data)
		process_genders(data, args["g"])
	end,
}

export.pos_functions.verbs = {
	params = {
		[1] = {},
		["g"] = {list = true},
	},
	func = function(args, data)
		data.genders = args["g"]

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
			["g"] = {list = true},
		},
		func = function(args, data)
			data.genders = args["g"]
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
