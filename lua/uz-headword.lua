local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"

local lang = require(languages_module).getByCode("uz")

local insert = table.insert

local u = mw.ustring.char
local ZWNJ = u(0x200C)

local function join_arabic(term, ending)
	if term:find("ه$") then
		return term .. ZWNJ .. ending
	else
		return term .. ending
	end
end

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
			local headdata = data.headdata
			if headdata.var == nil then
				headdata.var = headdata.sc:getCode() ~= "Latn"
			end
		end,
	}
end

local function insert_indeclinable(infls)
	insert(infls, {"indecl", type = "boolean", fixed_label = "<<indeclinable>>", cat = "indeclinable {plpos}"})
end

local function no_auto_cats_if_default(data, vals)
	-- For now, only add 'countable nouns' and 'uncountable nouns' when the plural is explicitly given rather than
	-- defaulted, and likewise for 'comparable adjectives' and 'uncomparable adjectives' when the comparative is
	-- explicitly given. When we've reviewed all the nouns to make sure they're appropriately specifying pl=-
	-- (and likewise comp=- for adjectives), we can remove these restrictions.
	local no_auto_cats = true
	for _, val in ipairs(vals) do
		if val.origin ~= "default" then
			no_auto_cats = false
			break
		end
	end
	return {
		no_auto_cats = no_auto_cats
	}
end

local function insert_comp_sup(infls, with_default)
	insert(infls, {
		"comp", label = "<<comparative>>",
		default = function(data)
			if with_default then
				return "+"
			end
		end,
		resolve_special = function(termdata)
			local head = termdata.head
			local tr = termdata.tr
			local sccode = termdata.sc:getCode()
			if sccode == "Latn" then
				return {term = head .. "roq"}
			elseif sccode == "Cyrl" then
				return {term = head .. "роқ", tr = tr and tr .. "roq" or nil}
			elseif sccode == "Arab" then
				return {term = join_arabic(head, "راق"), tr = tr and tr .. "roq" or nil}
			elseif termdata.infl.origin ~= "default" then
				error(("Unable to resolve comp=+ with script code '%s'"):format(sccode))
			end
		end,
		insert_inflection_props = no_auto_cats_if_default,
	})
	insert(infls, {
		"sup", label = "<<superlative>>",
		default = function(data)
			-- If a comparative other than '-' was given, include a default superlative.
			local comp_insert_spec = data.process_props.insert_specs.comp
			if comp_insert_spec and comp_insert_spec.exists ~= "no" then
				return {term = "+"}
			end
		end,
		resolve_special = function(termdata)
			local head = termdata.head
			local tr = termdata.tr
			local sccode = termdata.sc:getCode()
			if sccode == "Latn" then
				return {term = "[[eng]] " .. head}
			elseif sccode == "Cyrl" then
				return {term = "[[энг]] " .. head, tr = tr and "eng " .. tr}
			elseif sccode:find("Arab$") then
				return {term = "[[اېنْگ]] " .. head, tr = tr and "eng " .. tr}
			elseif termdata.infl.origin ~= "default" then
				error(("Unable to resolve sup=+ with script code '%s'"):format(sccode))
			end
		end,
		resolve_special_props = {
			with_links = true,
		},
	})
end

local function adjectives(plpos)
	local infls = {}
	insert_indeclinable(infls)
	if plpos == "adjectives" then
		insert_comp_sup(infls, true)
	end
	insert(infls, {"intens", label = "intensive"})
	return {
		infls = infls,
	}
end

pos_functions["adjectives"] = adjectives("adjectives")
pos_functions["determiners"] = adjectives("determiners")

pos_functions["adverbs"] = (function()
	local infls = {}
	insert_comp_sup(infls, false)
	return {
		infls = infls,
	}
end)()

pos_functions["nouns"] = (function()
	local infls = {}
	insert_indeclinable(infls)
	insert(infls, {
		"pltant", type = "boolean",
		process_after_parse = function(data, val)
			if val then
				data.genders = {"p"}
			end
		end,
		doc = "Specify that the noun is ''[[plurale tantum]]'' (plural-only).",
	})
	insert(infls, {
		"pl", label = "plural",
		default = function(data)
			local args = data.process_props.args
			if data.orig_poscat == "nouns" and not args.indecl and not args.pltant then -- not numerals or proper nouns
				return "+"
			end
		end,
		resolve_special = function(termdata)
			local head = termdata.head
			local tr = termdata.tr
			local sccode = termdata.sc:getCode()
			if sccode == "Latn" then
				return {term = head .. "lar"}
			elseif sccode == "Cyrl" then
				return {term = head .. "лар", tr = tr and tr .. "lar" or nil}
			elseif sccode == "Arab" then
				return {term = join_arabic(head, "لَر"), tr = tr and tr .. "lar" or nil}
			elseif termdata.infl.origin ~= "default" then
				error(("Unable to resolve pl=+ with script code '%s'"):format(sccode))
			end
		end,
		validate = function(data, vals)
			local args = data.process_props.args
			if args.indecl or args.pltant then
				error("Can't specify plurals when indecl=1 or pltant=1")
			end
		end,
		insert_inflection_props = no_auto_cats_if_default,
	})
	return {
		infls = infls,
	}
end)()

pos_functions["proper nouns"] = pos_functions["nouns"]
pos_functions["numerals"] = pos_functions["nouns"]

return export
