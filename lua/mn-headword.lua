local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local lang = require("Module:languages").getByCode("mn")
local mn = require("Module:mn-common")
local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_data_module = "Module:headword/data"
local parameters_module = "Module:parameters"

local boolean_param = {type = "boolean"}

local insert = table.insert
local split = mw.text.split

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(page)
	require("Module:debug/track")("mn-headword/" .. page)
	return true
end

local function inscat(categories, cat)
	insert(categories, lang:getCanonicalName() .. " " .. cat)
end

function export.show(frame)
	local iparams = {
		[1] = true,
	}

	local iargs = require(parameters_module).process(frame.args, iparams)

	local parargs = frame:getParent().args
	local poscat = iargs[1]
	local pos_in_1 = not poscat
	if pos_in_1 then
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:mn-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and "head" or poscat
	local other_script_index = pos_in_1 and 2 or 1

	local params = {
		head = {list = true},
		sc = {type = "script"},
		cat = {list = true},
		[other_script_index] = {list = true},
		id = true,
		sort = true,
		nolink = boolean_param,
		nolinkhead = {type = "boolean", alias_of = "nolink"},
		suffix = boolean_param,
		nosuffix = boolean_param,
		addlpos = true,
		var = boolean_param,
		pagename = true,
		json = boolean_param,
	}

	if pos_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	if pos_functions[indexing_poscat] then
		for key, val in pairs(pos_functions[indexing_poscat].params) do
			params[key] = val
		end
	end

	local args = require("Module:parameters").process(parargs, params)

	local pagename = args.pagename or mw.loadData(headword_data_module).pagename
	local namespace = mw.loadData(headword_data_module).page.namespace

	local sc = args.sc or lang:findBestScript(pagename)

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		inflections = {},
		pagename = pagename,
		sc = sc,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
	}

	local heads = args.head
	if not heads[1] then
		heads[1] = {"+"}
	end
	for i, head in ipairs(heads) do
		if head == "+" then
			head = args.nolink and pagename or nil
			if head and namespace == "Reconstruction" then
				head = "*" .. head
			end
		end
		heads[i] = head
	end
	data.heads = heads
	data.var = args.var

	if args.cat then
		for _, cat in ipairs(args.cat) do
			inscat(data.categories, cat)
		end
	end
	if not pagename:find("^%-") and not pagename:find(" ") and sc:getCode() == "Cyrl" then
		inscat(data.categories, #mn.syllables(pagename) .. "-syllable words")
	end

	if args[other_script_index][1] then
		local other_sc

		local scripts = {
			m = "Mong",
			c = "Cyrl",
			Mong = "Mong",
			Cyrl = "Cyrl",
		}
		if scripts[args[other_script_index][1]] then
			other_sc = require("Module:scripts").getByCode(scripts[args[other_script_index][1]])
			table.remove(args[other_script_index], 1)
			track("script-param")
		else
			other_sc = lang:findBestScript(args[other_script_index][1])
		end

		if sc and sc:getCode() == other_sc:getCode() then
			error("The headword and the alternative spelling should be in different scripts.")
		end

		if args[other_script_index][1] then
			local spelling = {label = other_sc:getCanonicalName(lang) .. " spelling", sc = other_sc,
				enable_auto_translit = true}

			for i, arg in ipairs(args[other_script_index]) do
				insert(spelling, arg)
			end

			insert(data.inflections, spelling)
		end
	end

	data.is_suffix = false
	if args.suffix or (
		not args.nosuffix and pagename:find("^%-") and poscat ~= "suffixes" and poscat ~= "suffix forms"
	) then
		data.is_suffix = true
		local function handle_suffix_pos(pos, is_first)
			local form_type = pos:match("^(.*) forms$")
			local actual_poscat
			if form_type then
				actual_poscat = "suffix forms"
				inscat(data.categories, ("%s suffix forms"):format(form_type))
				insert(data.inflections, {label = form_type .. " suffix form"})
			else
				actual_poscat = "suffixes"
				local singular_pos = require(en_utilities_module).singularize(pos)
				inscat(data.categories, ("%s-forming suffixes"):format(singular_pos))
				insert(data.inflections, {label = singular_pos .. "-forming suffix"})
			end
			if is_first then
				data.pos_category = actual_poscat
			elseif data.pos_category ~= actual_poscat then
				error(("Cannot mix suffixes and suffix forms using addlpos=; '%s' is a %s while overall POS '%s' is a %s; use separate POS headers for the two"):
					format(pos, actual_poscat, poscat, data.pos_category))
			end
		end
		handle_suffix_pos(poscat, true)
		if args.addlpos then
			for _, addlpos in ipairs(split(args.addlpos, "%s*,%s*")) do
				addlpos = require(headword_module).canonicalize_pos(addlpos)
				handle_suffix_pos(addlpos, false)
			end
		end
	end

	if pos_functions[indexing_poscat] then
		pos_functions[indexing_poscat].func(data, args)
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

local function insert_inflection(data, terms, label)
	if terms[1] then
		terms.label = label
		insert(data.inflections, terms)
	end
end

pos_functions["nouns"] = {
	params = {
		pl = {list = true},
		dec = true,
	},
	func = function(data, args)
		insert_inflection(data, args.pl, "definite plural")

		if args.dec then
			local declension
			if args.dec == "r" then
				declension = "regular declension"
			elseif args.dec == "n" then
				declension = "hidden-n declension"
			elseif args.dec == "g" then
				declension = "hidden-g declension"
			elseif args.dec == "m" then
				declension = "mixed declension"
			else
				error(("Unrecognized declension value: dec=%s"):format(args.dec))
			end
			inscat(data.categories, declension .. " nouns")
			insert(data.inflections, {label = declension})
		end
	end,
}
pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["verbs"] = {
	params = {
		caus = {list = true},
		pass = {list = true},
	},
	func = function(data, args)
		insert_inflection(data, args.caus, "causative")
		insert_inflection(data, args.pass, "passive")
	end
}

return export
