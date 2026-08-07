local export = {}

local concat = table.concat
local insert = table.insert

local function Array(...)
	Array = require("Module:array")
	return Array(...)
end

local function full_headword(...)
	full_headword = require("Module:headword").full_headword
	return full_headword(...)
end

local function full_link(...)
	full_link = require("Module:links").full_link
	return full_link(...)
end

local function IAST_TO_SLP(...)
	IAST_TO_SLP = require("Module:sa-utilities/translit/IAST-to-SLP1").tr
	return IAST_TO_SLP(...)
end

local function process_params(...)
	process_params = require("Module:parameters").process
	return process_params(...)
end

local function reverse_tr(...)
	reverse_tr = select(2, require("Module:sa-utilities/translit").retrieve_tr_modules("Deva"))
	return reverse_tr(...)
end

local function show_labels(...)
	show_labels = require("Module:labels").show_labels
	return show_labels(...)
end

local function sparse_ipairs(...)
	sparse_ipairs = require("Module:table/sparseIpairs")
	return sparse_ipairs(...)
end

local function translit(...)
	translit = require("Module:sa-convert").tr
	return translit(...)
end

local lang = require("Module:languages").getByCode("sa")
local langname = lang:getCanonicalName()
local PAGENAME = mw.loadData("Module:headword/data").pagename

local boolean = {type = "boolean"}
local list = {list = true}

local suffix_categories = {
	["adjectives"] = true,
	["adverbs"] = true,
	["nouns"] = true,
	["verbs"] = true,
}

local pos_functions = {}

local function glossary_link(entry, text)
	return ("[[Appendix:Glossary#%s|%s]]"):format(entry, text or entry)
end

function export.alt(frame)
	local args = frame:getParent().args
	local currentScript = lang:findBestScript(PAGENAME)
	local currentScriptCode = currentScript:getCode()
	local availableScripts = lang:getScripts()
	local devaForm = args["Deva"] or currentScriptCode == "Deva" and PAGENAME or error("No Devanagari-script form detected.")
	local scriptCode
	
	local terms, first
	local output = Array('<div class="NavFrame" style="max-width:40em"><div class="NavHead" style="background:var(--wikt-palette-lightblue,#d9ebff);color:inherit">Alternative scripts</div><div class="NavContent" style="text-align:left"><ul>')
	for _,script in ipairs(availableScripts) do
		scriptCode = script:getCode()
		terms = { args[scriptCode], args[scriptCode.."2"], args[scriptCode.."3"] }

		if scriptCode ~= "Deva" then
			local auto = translit(devaForm, scriptCode)
			if #terms == 0 then
				terms[1] = auto
			elseif auto == "" then
				-- Helpless - skip script.
			elseif terms[1] ~= auto then
				mw.addWarning("Expected "..auto.." for "..scriptCode.." but given "..terms[1]);
				output:insert("[[Category:Sanskrit terms with inconsistent transliterations]]")
			end
		end
		if terms[1] ~= "" then
			first = true
			for _,term in ipairs(terms) do
				if term ~= nil and term ~= PAGENAME then
					if first then
						first = false
						output:insert("<li>")
					else
						output:insert(" or ")
					end
					output:insert(full_link({lang = lang, sc = script, term = term, tr = "-"}))
				end
			end
			if not first then
				output:insert(" ")
				output:insert(show_labels{
					labels = { script:getDisplayForm() },
					lang = lang
				} .. "</li>")
			end
		end
	end
	output:insert("</ul></div></div>")

	return output:concat()

end

local function add_root_category(args, data)
	if args[1] then
		insert(data.inflections, {label = "root", args[1]})
		if not args.norootcat then
			insert(data.categories, "Sanskrit terms belonging to the root " .. args[1])
		end
	end
end

-- The main entry point.
function export.show(frame)
	local iparams = {
		[1] = {required = true},
		["def"] = true, -- default value
	}

	local iargs = process_params(frame.args, iparams)
	local poscat = iargs[1]

	local params = {
		[1] = {},
		["head"] = list,
		["tr"] = {list = true, allow_holes = true},
		["sc"] = {type = "script"},
		["id"] = true,
		["sort"] = true,
		["suff"] = boolean,
	}

	if pos_functions[poscat] then
		for k, v in next, pos_functions[poscat].params do
			params[k] = v
		end
	end
	
	local args = process_params(frame:getParent().args, params)
	local heads, tr = args.head, args.tr
	local currentScript = lang:findBestScript(heads[1] or PAGENAME)
	local currentScriptCode = currentScript:getCode()
	if #heads == 0 and mw.title.getCurrentTitle().nsText == "Template" then
		heads = {iargs.def}
	-- reverse tr for the Devanagari form if tr is provided
	-- this is to apply accentuation automatically
	-- TODO: check if the reverse tr *only* changes accentuation
	elseif tr.maxindex > 0 and currentScriptCode == "Deva" then
		for i, tr in sparse_ipairs(tr) do
			if heads[i] == nil then
				heads[i] = reverse_tr(IAST_TO_SLP(tr))
			end
		end
	end

	local data = {
		lang = lang,
		sc = args.sc,
		pos_category = poscat,
		heads = heads,
		translits = tr,
		genders = {},
		inflections = {},
		id = args.id,
		sort_key = args.sort,
		categories = {},
		sccat = true,
	}
	
	if args["suff"] then
		data.pos_category = "suffixes"
		
		if suffix_categories[poscat] then
			local singular_poscat = poscat:gsub("s$", "")
			insert(data.categories, langname .. " " .. singular_poscat .. "-forming suffixes")
		else
			error("No category exists for suffixes forming " .. poscat .. ".")
		end
	end
	
	if pos_functions[poscat] then
		pos_functions[poscat].func(args, data)
	end
	add_root_category(args, data)
	
	return full_headword(data)
end

pos_functions["verbs"] = setmetatable({}, {
	__index = function(t, k)
		local type_to_text = {
			A = {"middle"},
			P = {"active"},
		}

		local mode_to_cat = {
			aorist = "aorist",
			benedictive = "benedictive",
			causative = "causative",
			conditional = false, -- FIXME: What category?
			denominative = "denominative",
			desiderative = "desiderative",
			frequentative = "intensive",
			future = "future",
			imperfect = false, -- FIXME: What category?
			intensive = "intensive",
			nominal = "denominative",
			passive = "passive",
			perfect = "perfect",
			["periphrastic future"] = "future",
			present = "present",
		}

		local function make_param_set(base, aliases)
			local param_set = {}
			for k in next, base do
				param_set[k] = true
			end
			if aliases then
				for k, v in next, aliases do
					param_set[k] = v
				end
			end
			return param_set
		end

		local class_param_set = {}
		for i = 1, 10 do
			class_param_set[i] = true
		end

		local class_param = {type = "number", set = class_param_set}
		local type_param = {set = make_param_set(type_to_text)}
		local mode_param = {set = make_param_set(mode_to_cat)}

		t.params = {
			[2] = class_param,
			[3] = type_param,
			[4] = mode_param,
			[5] = class_param,
			[6] = type_param,
			[7] = mode_param,
			["norootcat"] = boolean,
		}

		t.func = function (args, data)
			local inflections, categories = data.inflections, data.categories

			local function handle_class_type_mode(class, typ, mode, notfirst)
				if not (class or typ or mode) then
					return
				end
				local label = {}
				if class then
					insert(label, ("class %d"):format(class))
					insert(categories, ("%s class %d verbs"):format(langname, class))
				end
				if typ then
					local typ_text = type_to_text[typ]
					insert(label, ('type <abbr title="%s">%s</abbr>'):format(concat(typ_text, " — "), typ))
					for _, desc in ipairs(typ_text) do
						insert(categories, ("%s %s verbs"):format(langname, desc))
					end
				end
				if mode then
					insert(label, mode)
					local cat = mode_to_cat[mode]
					if cat then
						insert(categories, ("%s %s verbs"):format(langname, cat))
					end
				end
				insert(inflections, {label = (notfirst and "or " or "") .. concat(label, ", ")})
			end

			handle_class_type_mode(args[2], args[3], args[4])
			handle_class_type_mode(args[5], args[6], args[7], true)
			data.gloss = "third-singular indicative"
		end

		setmetatable(t, nil)

		return t[k]
	end,
})

local function check_indeclinable(plpos, args, data)
	if args.indecl then
		insert(data.inflections, {label = glossary_link("indeclinable")})
		insert(data.categories, langname .. " indeclinable " .. plpos)
	end
end

local function do_degree(inflections, degree, degree_n, label)
	if degree_n == 0 then
		return
	end
	degree.label = glossary_link(label)
	if degree[1] == "-" then
		degree = {label = "no " .. degree.label}
	else
		degree.accel = {form = label}
	end
	insert(inflections, degree)
end

local function check_degree_derivations(plpos, args, data)
	local comp, sup = args.comp, args.sup
	local comp_n, sup_n = #comp, #sup
	if comp_n == 0 and sup_n == 0 then
		return
	elseif (comp_n == 0 or comp[1] == "-") and (sup_n == 0 or sup[1] == "-") then
		insert(data.inflections, {label = "not " .. glossary_link("comparative", "comparable")})
		insert(data.categories, langname .. " uncomparable " .. plpos)
	else
		local inflections = data.inflections
		do_degree(inflections, comp, comp_n, "comparative")
		do_degree(inflections, sup, sup_n, "superlative")
	end
end

local adj_params = {
	["indecl"] = boolean,
	["comp"] = list, --comparative(s)
	["sup"] = list, --superlative(s)
}

pos_functions["adjectives"] = {
	params = adj_params,
	func = function(args, data)
		check_indeclinable("adjectives", args, data)
		check_degree_derivations("adjectives", args, data)
		data.gloss = "stem"
	end
}

pos_functions["determiners"] = {
	params = adj_params,
	func = function(args, data)
		check_indeclinable("determiners", args, data)
		check_degree_derivations("determiners", args, data)
		data.gloss = "stem"
	end
}

pos_functions["adverbs"] = {
	params = {
		["comp"] = list, --comparative(s)
		["sup"] = list, --superlative(s)
	},
	func = function(args, data)
		check_degree_derivations("adverbs", args, data)
	end
}

pos_functions["participles"] = setmetatable({}, {
	__index = function(t, k)
		t.params = {
			[2] = {set = {
				desiderative = true,
				des = "desiderative",
				desid = "desiderative",
				future = true,
				fut = "future",
				futr = "future",
				gerundive = true,
				gerv = "gerundive",
				past = true,
				present = true,
				pres = "present",
				perfect = true,
				perf = "perfect",
			}},
			[3] = {set = {
				active = true,
				a = "active",
				act = "active",
				actv = "active",
				mediopassive = true,
				mp = "mediopassive",
				mpass = "mediopassive",
				mpasv = "mediopassive",
				mpsv = "mediopassive",
				middle = true,
				mid = "middle",
				midl = "middle",
				passive = true,
				p = "passive",
				pass = "passive",
				pasv = "passive",
			}},
			[4] = {set = {
				causative = true,
				caus = "causative",
				desiderative = true,
				des = "desiderative",
				desid = "desiderative",
				intensive = true,
				int = "intensive",
				inten = "intensive",
				intens = "intensive",
				freq = "intensive",
				frequentative = "intensive",
				frequentive = "intensive",
			}},
		}

		t.func = function (args, data)
			local tense, voice, mood, typ = args[2], args[3], args[4], {}
			if not (tense or voice) then
				return
			elseif tense then
				if tense == "gerundive" then
					tense = "future"
					if voice and voice ~= "passive" then
						error(("gerundive cannot be be in the %s voice."):format(voice))
					end
					voice = "passive"
				end
				insert(data.categories, ("%s %s participles"):format(langname, tense))
				insert(typ, tense)
			end
			if voice then
				insert(data.categories, ("%s %s participles"):format(langname, voice))
				insert(typ, voice)
				if tense then
					insert(data.categories, ("%s %s %s participles"):format(langname, tense, voice))
				end
			end
			if mood then
				insert(typ, mood)
			end
			data.gloss = concat(typ, " ") .. " participle"
		end

		setmetatable(t, nil)

		return t[k]
	end,
})

local function check_genders(...)
	local allowed_genders, numbers = {}, {"s", "d", "p"}
	for _, gen in ipairs{"m", "f", "n", "mf", "mfbysense", "mn", "fm", "fmbysense", "fn", "nm", "nf", "mfn", "mnf", "fmn", "fnm", "nmf", "nfm", "?"} do
		allowed_genders[gen] = true
		for _, num in ipairs(numbers) do
			allowed_genders[gen .. "-" .. num] = true
		end
	end
	
	function check_genders(genders)
		for _, g in ipairs(genders) do
			if not allowed_genders[g] then
				error("Unrecognized gender: " .. g)
			end
		end
	end
	
	return check_genders(...)
end

local function do_nouns(plpos, args, data)
	local genders = args.g
	check_genders(genders)
	if #genders == 0 then
		genders[1] = "?"
	end
	data.genders = genders

	check_indeclinable(plpos, args, data)

	if #args.m > 0 then
		args.m.label = "masculine"
		insert(data.inflections, args.m)
	end

	if #args.f > 0 then
		args.f.label = "feminine"
		insert(data.inflections, args.f)
	end

	if #args.n > 0 then
		args.n.label = "neuter"
		insert(data.inflections, args.n)
	end

	data.gloss = "stem"
end

local noun_params = {
	["indecl"] = boolean,
	["g"] = list, --gender(s)
	["m"] = list, --masculine form(s)
	["f"] = list, --feminine form(s)
	["n"] = list, --neuter form(s)
}

pos_functions["nouns"] = {
	params = noun_params,
	func = function(args, data)
		return do_nouns("nouns", args, data)
	end,
}

pos_functions["proper nouns"] = {
	params = noun_params,
	func = function(args, data)
		return do_nouns("proper nouns", args, data)
	end,
}

pos_functions["numerals"] = {
	params = noun_params,
	func = function(args, data)
		return do_nouns("numerals", args, data)
	end,
}

local pos_with_gender = {
	params = {
		["g"] = list,
	},
	func = function(args, data)
		local genders = args.g
		check_genders(genders)
		data.genders = genders
	end,
}

pos_functions.articles = pos_with_gender
pos_functions.pronouns = pos_with_gender
pos_functions.suffixes = pos_with_gender
pos_functions["adjective forms"] = pos_with_gender
pos_functions["determiner forms"] = pos_with_gender
pos_functions["noun forms"] = pos_with_gender
pos_functions["numeral forms"] = pos_with_gender
pos_functions["participle forms"] = pos_with_gender
pos_functions["proper noun forms"] = pos_with_gender
pos_functions["pronoun forms"] = pos_with_gender

return export
