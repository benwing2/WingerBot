local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("ang")

local insert = table.insert
local remove = table.remove

local function get_plaintext(...)
	get_plaintext = require("Module:utilities").get_plaintext
	return get_plaintext(...)
end

local function track(page)
	require("Module:debug").track("ang-headword/" .. page)
	return true
end

local function glossary_link(anchor, text)
	text = text or anchor
	return "[[Appendix:Glossary#" .. anchor .. "|" .. text .. "]]"
end

-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local NAMESPACE = mw.title.getCurrentTitle().nsText
	-- unused
	-- local PAGENAME = mw.loadData("Module:headword/data").pagename

	local iparams = {
		[1] = {required = true},
		["def"] = true,
		["suff_type"] = true,
	}
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local args = frame:getParent().args
	local poscat = iargs[1]
	local def = iargs.def
	local suff_type = iargs.suff_type
	local postype = nil
	if suff_type then
		postype = poscat .. "-" .. suff_type
	else
		postype = poscat
	end

	local data = {
		lang = lang,
		heads = {},
		genders = {},
		inflections = {},
		categories = {},
		no_redundant_head_cat = true, -- we want the headword specified to specify whether it has long vowels
	}

	if poscat == "suffixes" then
		insert(data.categories, "Old English " .. suff_type .. "-forming suffixes")
	end

	if pos_functions[postype] then
		local new_poscat = pos_functions[postype](def, args, data)
		if new_poscat then
			poscat = new_poscat
		end
	end

	data.pos_category = (NAMESPACE == "Reconstruction" and "reconstructed " or "") .. poscat
	
	return require("Module:headword").full_headword(data)
end

local function validate_genders(genders)
	for _, gspec in ipairs(genders) do
		local g = gspec.spec
		if g ~= "m" and g ~= "f" and g ~= "n" and g ~= "m-p" and g ~= "f-p" and g ~= "n-p" and g ~= "?" then
			error("Invalid gender: " .. g)
		end
	end
end

pos_functions["nouns"] = function(def, args, data)
	local params = {
		["head"] = {list = true},
		["id"] = true,
		[1] = {type = "genders", list = "g", flatten = true, disallow_holes = true},
		["g"] = {alias_of = 1, list = false},
		[2] = {list = "pl", disallow_holes = true},
	}

	local args = require("Module:parameters").process(args, params)
	data.heads = args.head
	data.id = args.id
	validate_genders(args[1])
	data.genders = args[1]
	local pl = args[2]
	if pl[1] then
		pl.label = "nominative plural"
		insert(data.inflections, pl)
	end
end

pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["verbs"] = function(def, args, data)
	local params = {
		[1] = {alias_of = "head", list = false},
		["head"] = {list = true},
		["id"] = true,
	}

	local args = require("Module:parameters").process(args, params)
	data.heads = args.head
	data.id = args.id
end

local function adjectives(pos, def, args, data)
	local list = {list = true}
	local params = {
		[1] = {alias_of = "head", list = false},
		["head"] = list,
		["comp"] = list,
		[2] = {alias_of = "comp", list = false},
		["sup"] = list,
		[3] = {alias_of = "sup", list = false},
		["adv"] = list,
		["indecl"] = {type = "boolean"},
		["id"] = true,
	}
	local args = require("Module:parameters").process(args, params)
	data.heads = args.head
	data.id = args.id

	if args.indecl then
		insert(data.inflections, {label = glossary_link("indeclinable")})
	end
	local comp = args.comp
	if #comp > 0 then
		comp.label = "comparative"
		insert(data.inflections, comp)
	end
	local sup = args.sup
	if #sup > 0 then
		sup.label = "superlative"
		insert(data.inflections, sup)
	end
	if #args.adv > 0 then
		args.adv.label = "adverb"
		insert(data.inflections, args.adv)
	end
end

pos_functions["adjectives"] = function(def, args, data)
	return adjectives("adjectives", def, args, data)
end
	
pos_functions["participles"] = function(def, args, data)
	return adjectives("participles", def, args, data)
end

pos_functions["determiners"] = function(def, args, data)
	return adjectives("determiners", def, args, data)
end

pos_functions["pronouns"] = function(def, args, data)
	return adjectives("pronouns", def, args, data)
end

pos_functions["suffixes-adjective"] = function(def, args, data)
	return adjectives("suffixes", def, args, data)
end

pos_functions["numerals-adjective"] = function(def, args, data)
	return adjectives("numerals", def, args, data)
end

pos_functions["adverbs"] = function(def, args, data)
	local list = {list = true}
	local params = {
		[1] = {alias_of = "head", list = false},
		[2] = {alias_of = "comp", list = false},
		[3] = {alias_of = "sup", list = false},
		["head"] = list,
		["comp"] = list,
		["sup"] = list,
		["id"] = true,
	}

	local args = require("Module:parameters").process(args, params)
	data.heads = args.head
	data.id = args.id
	local comp, sup

	if args.comp[1] == "-" then
		comp = "-"
	elseif #args.comp > 0 then
		args.comp.label = glossary_link("comparative")
		comp = args.comp
	end
	if args.comp[1] == "-" or args.sup[1] == "-" then
		sup = "-"
	elseif #args.sup > 0 then
		args.sup.label = glossary_link("superlative")
		sup = args.sup
	end

	if comp == "-" then
		insert(data.inflections, {label = "not " .. glossary_link("comparable")})
		insert(data.categories, "Old English uncomparable adverbs")
	else
		insert(data.inflections, comp)
	end
	if sup == "-" then
		if comp ~= "-" then
			insert(data.inflections, {label = "no " .. glossary_link("superlative")})
		end
	else
		insert(data.inflections, sup)
	end
end

pos_functions["suffixes-adverb"] = pos_functions["adverbs"]

local function get_forms(forms)
	if #forms == 0 then
		return nil
	end
	local i, attested = 1, false
	while true do
		local form = forms[i]
		if form == nil then
			return forms, attested
		elseif form == "-" then
			remove(forms, i)
		else
			if not (attested or get_plaintext(form):sub(1, 1) == "*") then
				attested = true
			end
			i = i + 1
		end
	end
end

local function degree(pos, deg, other_arg, other_label, args, data)
	local boolean = {type = "boolean"}
	local list = {list = true}
	local params = {
		[1] = {alias_of = "head", list = false},
		["head"] = list,
		["positive"] = list,
		[other_arg] = list,
		["indecl"] = boolean,
		["id"] = true,
	}
	local args = require("Module:parameters").process(args, params)
	data.heads = args.head
	data.id = args.id

	if args.indecl then
		insert(data.inflections, {label = glossary_link("indeclinable")})
	end

	local positive, positive_attested = get_forms(args.positive)

	if positive then
		if not positive_attested then
			insert(data.categories, "Old English " .. deg .. "-only " .. pos)
		end
		if #positive > 0 then
			args.positive.label = "positive"
			insert(data.inflections, args.positive)
		else
			insert(data.inflections, {label = "no positive form"})
		end
	end

	local other = get_forms(args[other_arg])
	if other then
		if #other > 0 then
			args[other_arg].label = other_label
			insert(data.inflections, args[other_arg])
		else
			insert(data.inflections, {label = "no " .. other_label .. " form"})
		end
	end

	-- If a lemma, return the primary part of speech ("adjectives" or
	-- "adverbs"), so that the term is categorized in "Old English adjectives"
	-- or "Old English adverbs". Otherwise, return nothing, so that the term
	-- goes in the relevant non-lemma category (e.g. "Old English comparative
	-- adjectives"), and into "Old English non-lemma forms".
	if positive and not positive_attested then
		return pos
	end
end

pos_functions["comparative adjectives"] = function(def, args, data)
	return degree("adjectives", "comparative", "sup", "superlative", args, data)
end

pos_functions["superlative adjectives"] = function(def, args, data)
	return degree("adjectives", "superlative", "comp", "comparative", args, data)
end

pos_functions["comparative adverbs"] = function(def, args, data)
	return degree("adverbs", "comparative", "sup", "superlative", args, data)
end

pos_functions["superlative adverbs"] = function(def, args, data)
	return degree("adverbs", "superlative", "comp", "comparative", args, data)
end

local function non_lemma_forms(def, args, data)
	local params = {
		[1] = {required = true, default = def}, -- headword or cases
		["head"] = {list = true, require_index = true},
		["g"] = {list = true},
		["id"] = true,
	}

	local args = require("Module:parameters").process(args, params)

	local heads = {args[1]}
	for _, head in ipairs(args.head) do
		insert(heads, head)
	end
	data.heads = heads
	data.genders = args.g
	data.id = args.id
end

pos_functions["noun forms"] = non_lemma_forms
pos_functions["proper noun forms"] = non_lemma_forms
pos_functions["pronoun forms"] = non_lemma_forms
pos_functions["verb forms"] = non_lemma_forms
pos_functions["adjective forms"] = non_lemma_forms
pos_functions["participle forms"] = non_lemma_forms
pos_functions["determiner forms"] = non_lemma_forms
pos_functions["numeral forms"] = non_lemma_forms
pos_functions["suffix forms"] = non_lemma_forms

return export
