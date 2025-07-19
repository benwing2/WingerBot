local export = {}

local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local lang = require("Module:languages").getByCode("sh")

local function otherscript(inflections, args)
	local title = mw.title.getCurrentTitle()
	local sc = lang:findBestScript(title.subpageText)
	
	local other_sc
	
	if sc:getCode() == "Latn" then
		other_sc = "Cyrl"
	elseif sc:getCode() == "Cyrl" then
		other_sc = "Latn"
	end
	
	other_sc = require("Module:scripts").getByCode(other_sc)
	local inflection = {label = other_sc:getCanonicalName() .. " spelling"}

	local heads = args["head"]
	if #heads == 0 then
		heads = {title.subpageText}
	end
	
	if args["tr"][1] == "-" then
		inflection.label = "not attested in " .. other_sc:getCanonicalName() .. " spelling"
	else
		for i, head in ipairs(heads) do
			local tr = args["tr"][i]
			
			if not tr then
				tr = require("Module:sh-translit").tr(require("Module:links").remove_links(head), "sh", sc:getCode())
			end
			
			table.insert(inflection, {term = tr, sc = other_sc})
		end
	end
	
	table.insert(inflections, inflection)
end

local function glossary_link(entry, text)
	text = text or entry
	return "[[Appendix:Glossary#" .. entry .. "|" .. text .. "]]"
end

function export.basic(frame)
	local params = {
		["head"] = {list = true},
		["tr"] = {list = true, allow_holes = true},
		}
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	
	local data = {lang = lang, pos_category = frame.args[1], categories = {}, heads = args["head"], genders = {}, inflections = {}}
	
	otherscript(data.inflections, args)
	
	return require("Module:headword").full_headword(data)
end


function export.adjective(frame)
	local params = {
		["def"] = {list = true},
		["comp"] = {list = true},
		["adv"] = {list = true},
		["head"] = {list = true},
		["tr"] = {list = true, allow_holes = true},
		["indecl"] = {type = "boolean"}
		}
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	
	local data = {lang = lang, pos_category = "adjectives", categories = {}, heads = args["head"], genders = {}, inflections = {}}
	
	otherscript(data.inflections, args)
	
	-- Add parameters
	local param_list = {
		{"def", "definite"},
		{"comp", "comparative"},
		{"adv", "derived adverb"},
	}
	
	if args["indecl"] then
		table.insert(data.inflections, {label = glossary_link("indeclinable")})
		table.insert(data.categories, lang:getCanonicalName() .. " indeclinable adjectives")
	end
	for _, val in pairs(param_list) do
		local param_name, label = unpack(val)
		local forms = args[param_name]
		if forms[1] then
			forms.label = (param_name == "adv") and label or glossary_link(label)
			table.insert(data.inflections, forms)
		end
	end
	
	return require("Module:headword").full_headword(data)
end


local gender_cats = {
	["m"] = "masculine",
	["f"] = "feminine",
	["n"] = "neuter",
	["m-p"] = "masculine",
	["f-p"] = "feminine",
	["n-p"] = "neuter",
}

function export.letter(frame)
	local params = {
		["upper"] = {},
		["lower"] = {},
		["head"] = {list = true},
		["tr"] = {list = true, allow_holes = true},
		}
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	
	local data = {lang = lang, pos_category = "letters", categories = {}, heads = args["head"], genders = {}, inflections = {}}
	
	if args["upper"] then
		table.insert(data.inflections, {label = "lower case", nil})
		table.insert(data.inflections, {label = "upper case", args["upper"]})
	elseif args["lower"] then
		table.insert(data.inflections, {label = "upper case", nil})
		table.insert(data.inflections, {label = "lower case", args["lower"]})
	end
	
	otherscript(data.inflections, args)
	
	return require("Module:headword").full_headword(data)
end

function noun_and_proper_noun(frame, is_proper)
	local params = {
		["g"] = {list = true, default = "?"},
		["head"] = {list = true},
		["tr"] = {list = true, allow_holes = true},
		["m"] = {list = true},
		["f"] = {list = true},
        ["dim"] = {list = true},
        ["aug"] = {list = true},
        ["adj"] = {list = true},
        ["dem"] = {list = true},
		["fdem"] = {list = true},
		["indecl"] = {type = "boolean"},
		}
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	
	local data = {
		lang = lang,
		pos_category = is_proper and "proper nouns" or "nouns",
		categories = {},
		heads = args["head"],
		genders = args["g"],
		inflections = {}
	}
	
	for i, gender in ipairs(data.genders) do
		if gender_cats[gender] then
			table.insert(data.categories, lang:getCanonicalName() .. " " .. gender_cats[gender] .. " nouns")
		else
			data.genders[i] = "?"
		end
	end
	
	otherscript(data.inflections, args)
	
	-- Add parameters
	local param_list = {
		{"f", "female equivalent"},
		{"m", "male equivalent"},
		{"dim", "diminutive"},
		{"aug", "augmentative"},
		{"adj", "relational adjective"},
		{"dem", "demonym"},
	    {"fdem", "female demonym"},
		}
	
	if args["indecl"] then
		table.insert(data.inflections, {label = glossary_link("indeclinable")})
		table.insert(data.categories, lang:getCanonicalName() .. " indeclinable nouns")
	end
	for _, val in pairs(param_list) do
		local param_name, label = unpack(val)
		local forms = args[param_name]
		if forms[1] then
			forms.label = (param_name == "fdem") and label or glossary_link(label)
			table.insert(data.inflections, forms)
		end
	end
	
	return data
end

function export.noun(frame)
	data = noun_and_proper_noun(frame, false)
	return require("Module:headword").full_headword(data)
end


function export.propernoun(frame)
	data = noun_and_proper_noun(frame, true)
	return require("Module:headword").full_headword(data)
end


function export.verb(frame)
	local params = {
		["a"] = {},
		["head"] = {list = true},
		["tr"] = {list = true, allow_holes = true},
		["pf"] = {list = true},
		["impf"] = {list = true}
		}
	
	local args = require("Module:parameters").process(frame:getParent().args, params)
	
	local data = {lang = lang, pos_category = "verbs", categories = {}, heads = args["head"], genders = {}, inflections = {}}
	
	if args["a"] == "impf" or args["a"] == "pf" then
		table.insert(data.genders, args["a"])
	elseif args["a"] == "impf-pf" or args["a"] == "pf-impf" or args["a"] == "dual" or args["a"] == "ip" then
		table.insert(data.genders, "impf")
		table.insert(data.genders, "pf")
	else
		table.insert(data.genders, "?")
	end
	
	otherscript(data.inflections, args)
	
	--add perfective equivalent
	local pf = args["pf"]
	if #pf > 0 then
		pf.label = "perfective"
		table.insert(data.inflections, pf)
	end
	
	--add imperfective equivalent
	local impf = args["impf"]
	if #impf > 0 then
		impf.label = "imperfective"
		table.insert(data.inflections, impf)
	end
	
	return require("Module:headword").full_headword(data)
end


return export
