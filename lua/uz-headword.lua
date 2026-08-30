local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require_when_needed = require("Module:utilities/require when needed")
local m_table = require("Module:table")

local en_utilities_module = "Module:en-utilities"
local headword_module = "Module:headword"
local headword_data_module = "Module:headword/data"
local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local parse_interface_module = "Module:parse interface"

local m_en_utilities = require_when_needed(en_utilities_module)
local m_headword_utilities = require_when_needed(headword_utilities_module)
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")

local lang = require(languages_module).getByCode("uz")
local langname = lang:getCanonicalName()

local boolean_param = {type = "boolean"}

local split = mw.text.split
local u = mw.ustring.char
local insert = table.insert

local ZWNJ = u(0x200C)

----------------------------------------------- Utilities --------------------------------------------

local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(page)
	require("Module:debug/track")("uz-headword/" .. page)
	return true
end

-- Parse an inflection. The raw arguments come from `args[field]`, which is parsed for inline modifiers. Multiple
-- comma-separated values are allowed.
local function parse_inflection(args, field, is_head)
	local retval
	if args[field] then
		retval = m_headword_utilities.parse_term_with_modifiers {
			val = args[field],
			paramname = field,
			splitchar = ",",
			is_head = is_head,
			include_mods = {"tr"},
		}
	end
	return retval or {}
end

local function insert_inflection(data, terms, label, accel_form)
	local accel_obj
	if accel_form then
		local lemmas = {}
		local lemma_translits = {}
		for i, headobj in ipairs(data.heads) do
			lemmas[i] = headobj.term
			lemma_translits[i] = headobj.tr
		end
		accel_obj = {
			lemma = lemmas,
			lemma_translit = lemma_translits,
			form = accel_form,
		}
	end

	return m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		accel = accel_obj,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. Multiple comma-separated values are allowed. `label` is the
-- label that the inflections are given; sections enclosed in <<...>> are linked to the glossary. `accel_form` is the
-- accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel_form)
	local terms = parse_inflection(args, field)
	return insert_inflection(data, terms, label, accel_form)
end

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{cd|*-head}} templates such as {{tl|hi-head}}, {{tl|pa-head}} and {{tl|ur-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
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
			mw.title.getCurrentTitle().fullText == "Template:uz-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and "head" or poscat

	local params = {
		["head"] = {template_default = iargs.def},
		["head2"] = {replaced_by = false, instead = "use comma-separated |head="},
		["tr"] = true,
		["tr2"] = {replaced_by = false, instead = "use comma-separated |tr= or <tr:...> inline modifier on head"},
		["id"] = true,
		["sc"] = {type = "script"},
		["sort"] = true,
		["nolink"] = boolean_param,
		["nolinkhead"] = {type = "boolean", alias_of = "nolink"},
		["suffix"] = boolean_param,
		["nosuffix"] = boolean_param,
		["addlpos"] = true,
		["var"] = boolean_param,
		["json"] = boolean_param,
		["pagename"] = true, -- for testing
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

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		inflections = {},
		pagename = pagename,
		sc = args.sc,
		id = args.id,
		sort_key = args.sort,
		force_cat_output = force_cat,
		no_redundant_head_cat = true,
	}

	local trs = args.tr and split_on_comma(args.tr) or {}
	local num_trs = #trs
	local heads = args.head and parse_inflection(args, "head", "is_head") or {}
	local num_heads = #heads
	if num_heads > 0 and num_trs > 0 and num_heads ~= num_trs then
		error(("%s head%s specified explicitly but %s translit%s; they must match; use '+' to stand for the default head (the pagename) or no manual translit"):format(
			num_heads, num_heads > 1 and "s" or "", num_trs, num_trs > 1 and "s" or ""))
	end
	-- Be careful here not to overwrite user_specified_heads if it's empty so we can later check user_specified_heads
	-- to see if the user provided any heads.
	if num_heads == 0 and num_trs > 0 then
		heads = {}
		for i = 1, num_trs do
			heads[i] = {term = "+"}
		end
	end
	if not heads[1] then
		heads = {{term = "+"}}
	end
	for i, headobj in ipairs(heads) do
		if headobj.tr and trs[i] then
			if headobj.tr ~= trs[i] then
				error(("Saw two different translits '%s' and '%s' for head #%s"):format(
					headobj.tr, trs[i], i))
			end
		else
			headobj.tr = headobj.tr or trs[i]
		end
		if headobj.tr == "+" then
			headobj.tr = nil
		end
		if headobj.term == "+" then
			headobj.term = args.nolink and pagename or nil
			if headobj.term and namespace == "Reconstruction" then
				headobj.term = "*" .. headobj.term
			end
		end
	end
	data.heads = heads
	local var = args.var
	if var == nil then
		local sc = args.sc
		if not sc then
			local term_for_script_check = heads[1].term and heads[1].term ~= "+" and heads[1].term or pagename
			sc = lang:findBestScript(term_for_script_check)
		end
		var = sc:getCode() ~= "Latn"
	end
	data.var = var

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
				insert(data.categories, ("%s %s suffix forms"):format(langname, form_type))
				insert(data.inflections, {label = form_type .. " suffix form"})
			else
				actual_poscat = "suffixes"
				local singular_pos = m_en_utilities.singularize(pos)
				insert(data.categories, ("%s %s-forming suffixes"):format(langname, singular_pos))
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
		pos_functions[indexing_poscat].func(args, data)
	end

	if args.json then
		return require("Module:JSON").toJSON(data)
	end

	return require(headword_module).full_headword(data)
end

local function handle_indeclinable(plpos, args, data)
	if args.indecl then
		insert(data.inflections, {label = glossary_link("indeclinable")})
		insert(data.categories, langname .. " indeclinable " .. plpos)
	end
end

local function join_arabic(term, ending)
	if term:find("ه$") then
		return term .. ZWNJ .. ending
	else
		return term .. ending
	end
end

-- Generate an inflection that may be specified explicitly or defaulted (which involves looping over the specified or
-- defaulted heads and determining the script of each one, since the formation of the default depends on the script).
-- `data` is the data object passed into the POS handler. `terms` is the list of terms to process. Those where the term
-- itself is not `+` will be returned unchanged, while those where the term is `+` will be handled by generating the
-- appropriate inflections from the headwords using `make_inflection` (which is passed three arguments, `head`, `tr` and
-- `sccode`, i.e. the script code of `head`) and should return two values, term and translit, either of which can be
-- nil. A nil head will be ignored, and otherwise the qualifiers/labels/etc. specified on the `+` term will be combined
-- with the qualifiers/labels/etc. specified on the head. The return value is a list of inflections where no requests
-- for the default inflection remain.
local function generate_inflection(data, terms, with_links, make_inflection)
	local infls = {}
	for _, termobj in ipairs(terms) do
		if termobj.term ~= "+" then
			insert(infls, termobj)
		else
			for _, headobj in ipairs(data.heads) do
				local head = headobj.term or data.pagename
				local head_no_links
				if with_links then
					head = head:find("%[") and head or require(headword_module).add_multiword_links(head, not headobj.term)
					head_no_links = require(links_module).remove_links(head)
				else
					head = require(links_module).remove_links(head)
					head_no_links = head
				end
				local tr = headobj.tr
				local sccode = lang:findBestScript(head_no_links):getCode()
				head, tr = make_inflection(head, tr, sccode)
				if head then
					local inflobj = m_table.shallowCopy(termobj)
					inflobj.term = head
					inflobj.tr = tr
					m_headword_utilities.combine_termobj_qualifiers_labels(inflobj, headobj)
					insert(infls, inflobj)
				end
			end
		end
	end
	return infls
end

local function handle_comp_sup(plpos, args, data, with_default)
	local comps = parse_inflection(args, "comp")
	local user_specified_comps = not not comps[1]
	if not comps[1] and with_default then
		comps[1] = {term = "+"}
	end
	comps = generate_inflection(data, comps, false, function(head, tr, sccode)
		if sccode == "Latn" then
			return head .. "roq", nil
		elseif sccode == "Cyrl" then
			return head .. "роқ", tr and tr .. "roq" or nil
		elseif sccode:find("Arab$") then
			return join_arabic(head, "راق"), tr and tr .. "roq" or nil
		else
			return nil, nil
		end
	end)
	local insert_spec
	if comps[1] then
		insert_spec = insert_inflection(data, comps, "<<comparative>>")
		-- For now, only add 'comparable adjectives' and 'uncomparable adjectives' when the comparative is explicitly
		-- given. When we've reviewed all the adjectives to make sure they are appropriately specifying comp=- for
		-- uncomparable adjectives, we can remove this restriction.
		if user_specified_comps then
			if insert_spec.exists == "no" then
				insert(data.categories, langname .. " uncomparable " .. plpos)
			elseif insert_spec.exists == "usually no" then
				insert(data.categories, langname .. " uncomparable " .. plpos)
				insert(data.categories, langname .. " comparable " .. plpos)
			elseif insert_spec.exists == "yes" then
				insert(data.categories, langname .. " comparable " .. plpos)
			end
		end
	end
	local sups = parse_inflection(args, "sup")
	if not sups[1] and (not insert_spec and with_default or insert_spec and insert_spec.exists ~= "no") then
		sups[1] = {term = "+"}
	end
	if sups[1] then
		sups = generate_inflection(data, sups, true, function(head, tr, sccode)
			if sccode == "Latn" then
				return "[[eng]] " .. head, nil
			elseif sccode == "Cyrl" then
				return "[[энг]] " .. head, tr and "eng " .. tr or nil
			elseif sccode:find("Arab$") then
				return "[[اېنْگ]] " .. head, tr and "eng " .. tr or nil
			else
				return nil, nil
			end
		end)
	end
	if sups[1] then
		insert_inflection(data, sups, "<<superlative>>")
	end
end

local function insert_comp_sup(params)
	params.comp = true
	params.comp2 = {replaced_by = false, instead = "use comma-separated |comp="}
	params.sup = true
	params.sup2 = {replaced_by = false, instead = "use comma-separated |sup="}
end

local function adjectives(plpos)
	local params = {
		indecl = boolean_param,
		intens = true, --intensive form
	}
	if plpos == "adjectives" then
		insert_comp_sup(params)
	end
	return {
		params = params,
		func = function(args, data)
			handle_indeclinable(plpos, args, data)
			if plpos == "adjectives" then
				handle_comp_sup(plpos, args, data, true)
			end
			parse_and_insert_inflection(data, args, "intens", "intensive")
		end,
	}
end

pos_functions["adjectives"] = adjectives("adjectives")
pos_functions["determiners"] = adjectives("determiners")

pos_functions["adverbs"] = (function()
	local params = {}
	insert_comp_sup(params)
	return {
		params = params,
		func = function(args, data)
			handle_comp_sup("adverbs", args, data, false)
		end,
	}
end)()

local function nouns(plpos)
	return {
		params = {
			["pl"] = true,
			["pltant"] = boolean_param,
			["indecl"] = boolean_param,
		},
		func = function(args, data)
			handle_indeclinable(plpos, args, data)
			if args.pltant then
				data.genders = {"p"}
			end
			if not args.indecl and not args.pltant then
				local pls = parse_inflection(args, "pl")
				local user_specified_pls = not not pls[1]
				if not pls[1] and plpos == "nouns" then
					pls[1] = {term = "+"}
				end
				pls = generate_inflection(data, pls, false, function(head, tr, sccode)
					if sccode == "Latn" then
						return head .. "lar", nil
					elseif sccode == "Cyrl" then
						return head .. "лар", tr and tr .. "lar" or nil
					elseif sccode:find("Arab$") then
						return join_arabic(head, "لَر"), tr and tr .. "lar" or nil
					else
						return nil, nil
					end
				end)
				if pls[1] then
					local insert_spec = insert_inflection(data, pls, "plural")
					-- For now, only add 'countable nouns' and 'uncountable nouns' when the plural is explicitly given.
					-- When we've reviewed all the nouns to make sure they are appropriately specifying pl=- for
					-- uncountable nouns, we can remove this restriction.
					if user_specified_pls then
						if insert_spec.exists == "no" then
							insert(data.categories, langname .. " uncountable " .. plpos)
						elseif insert_spec.exists == "usually no" then
							insert(data.categories, langname .. " uncountable " .. plpos)
							insert(data.categories, langname .. " countable " .. plpos)
						elseif insert_spec.exists == "yes" then
							insert(data.categories, langname .. " countable " .. plpos)
						end
					end
				end
			end
		end,
	}
end

pos_functions["nouns"] = nouns("nouns")
pos_functions["proper nouns"] = nouns("proper nouns")
pos_functions["numerals"] = nouns("numerals")

return export
