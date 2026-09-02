local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"

local lang = require(languages_module).getByCode("uz")

local boolean_param = {type = "boolean"}

local u = mw.ustring.char
local ZWNJ = u(0x200C)

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|uz-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		include_sc = true,
		force_cat = force_cat,
		augment_headdata = function(data)
			if data.var == nil then
				data.var = data.sc:getCode() ~= "Latn"
			end
		end,
	}
end

local function handle_indeclinable(data, args)
	if args.indecl then
		data.insert_fixed_inflection("<<indeclinable>>")
		data.insert_category("indeclinable PLPOS")
	end
end

local function join_arabic(term, ending)
	if term:find("ه$") then
		return term .. ZWNJ .. ending
	else
		return term .. ending
	end
end

local function handle_comp_sup(data, with_default)
	local comps = data.parse_inflection("comp")
	local user_specified_comps = not not comps[1]
	if not comps[1] and with_default then
		comps[1] = {term = "+"}
	end
	comps = data.resolve_special(comps, {
		include_sc = true,
		handle_special = function(termdata)
			local head = termdata.head
			local tr = termdata.tr
			local sccode = termdata.sc:getCode()
			if sccode == "Latn" then
				return {term = head .. "roq"}
			elseif sccode == "Cyrl" then
				return {term = head .. "роқ", tr = tr and tr .. "roq" or nil}
			elseif sccode == "Arab" then
				return {term = join_arabic(head, "راق"), tr = tr and tr .. "roq" or nil}
			elseif user_specified_comps then
				error(("Unable to resolve comp=+ with script code '%s'"):format(sccode))
			end
		end,
	})
	local insert_spec = data.insert_inflection(comps, "<<comparative>>", {
		-- For now, only add 'comparable adjectives' and 'uncomparable adjectives' when the comparative is explicitly
		-- given. When we've reviewed all the adjectives to make sure they are appropriately specifying comp=- for
		-- uncomparable adjectives, we can remove this restriction.
		no_auto_cats = not user_specified_comps,
	})
	local sups = data.parse_inflection("sup")
	local user_specified_sups = not not sups[1]
	if not sups[1] and (not insert_spec and with_default or insert_spec and insert_spec.exists ~= "no") then
		sups[1] = {term = "+"}
	end
	sups = data.resolve_special(sups, {
		with_links = true,
		include_sc = true,
		handle_special = function(termdata)
			local head = termdata.head
			local tr = termdata.tr
			local sccode = termdata.sc:getCode()
			if sccode == "Latn" then
				return {term = "[[eng]] " .. head}
			elseif sccode == "Cyrl" then
				return {term = "[[энг]] " .. head, tr = tr and "eng " .. tr}
			elseif sccode:find("Arab$") then
				return {term = "[[اېنْگ]] " .. head, tr = tr and "eng " .. tr}
			elseif user_specified_sups then
				error(("Unable to resolve sup=+ with script code '%s'"):format(sccode))
			end
		end,
	})
	data.insert_inflection(sups, "<<superlative>>")
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
		func = function(data, args)
			handle_indeclinable(data, args)
			if plpos == "adjectives" then
				handle_comp_sup(data, true)
			end
			data.parse_and_insert_inflection("intens", "intensive")
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
		func = function(data, args)
			handle_comp_sup(data, false)
		end,
	}
end)()

pos_functions["nouns"] = {
	params = {
		pl = true,
		pltant = boolean_param,
		indecl = boolean_param,
	},
	func = function(data, args)
		handle_indeclinable(data, args)
		if args.pltant then
			data.genders = {"p"}
		end
		if not args.indecl and not args.pltant then
			local pls = data.parse_inflection("pl")
			local user_specified_pls = not not pls[1]
			if not pls[1] and data.orig_poscat == "nouns" then
				pls[1] = {term = "+"}
			end
			pls = data.resolve_special(pls, {
				include_sc = true,
				handle_special = function(termdata)
					local head = termdata.head
					local tr = termdata.tr
					local sccode = termdata.sc:getCode()
					if sccode == "Latn" then
						return {term = head .. "lar"}
					elseif sccode == "Cyrl" then
						return {term = head .. "лар", tr = tr and tr .. "lar" or nil}
					elseif sccode == "Arab" then
						return {term = join_arabic(head, "لَر"), tr = tr and tr .. "lar" or nil}
					elseif user_specified_pls then
						error(("Unable to resolve pl=+ with script code '%s'"):format(sccode))
					end
				end,
			})
			data.insert_inflection(pls, "plural", {
				-- For now, only add 'countable nouns' and 'uncountable nouns' when the plural is explicitly given.
				-- When we've reviewed all the nouns to make sure they are appropriately specifying pl=- for
				-- uncountable nouns, we can remove this restriction.
				no_auto_cats = not user_specified_pls,
			})
		end
	end,
}

pos_functions["proper nouns"] = pos_functions["nouns"]
pos_functions["numerals"] = pos_functions["nouns"]

return export
