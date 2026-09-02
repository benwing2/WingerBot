local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("gsw")

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local m_table = require("Module:table")
local headword_utilities_module = "Module:headword utilities"

local boolean_param = {type = "boolean"}

local insert = table.insert

local valid_genders = {
	"m", "f", "n",
	"m-p", "f-p", "n-p", "p",
	"?",
}

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|gsw-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		force_cat = force_cat,
	}
end

local function handle_indeclinable(data, args)
	if args.indecl then
		data:insert_fixed_inflection("<<indeclinable>>")
		data:insert_category("indeclinable PLPOS")
	end
end

local function handle_comp_sup(data)
	local comps = data:parse_inflection("comp")
	comps = data:resolve_special(comps, function(termdata)
		return termdata.head .. "er"
	end)
	local insert_spec = data:insert_inflection(comps, "<<comparative>>")
	local sups = data:parse_inflection("sup")
	if not sups[1] and (insert_spec and insert_spec.exists ~= "no") then
		sups[1] = {term = "+"}
	end
	sups = data:resolve_special(sups, function(termdata)
		return termdata.head .. "scht"
	end)
	data:insert_inflection(data, sups, "<<superlative>>")
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
	}
	if plpos == "adjectives" then
		insert_comp_sup(params)
	end
	return {
		params = params,
		func = function(data, args)
			handle_indeclinable(data, args)
			if plpos == "adjectives" then
				handle_comp_sup(data)
			end
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
		func = function(data, _args)
			handle_comp_sup(data)
		end,
	}
end)()

local special_noun_plurals = m_table.listToSet { "#", "e", "er", "s", "en", "es", "E", "ER", "S", "EN", "ES" }

local lemma_for_articles = {
	der = "de",
	["dä"] = "de",
	["s'"] = "s",
	ds = "s",
	das = "s",
	t = "d",
	["t'"] = "d",
	["d'"] = "d",
	di = "d",
	die = "d",
}

local function nouns(plpos)
	local params = {
		[1] = {type = "genders", default = "?"},
		[2] = true, -- plural
		dim = true, -- diminutive
		m = true, -- male equivalent
		f = true, -- female equivalent
		indecl = boolean_param,
	}
	if plpos == "proper nouns" then
		params.art = true
	end
	return {
		params = params,
		func = function(data, args)
			data:validate_genders(args[1], valid_genders)
			data.genders = args[1]

			if args.art then
				local arts = data:parse_inflection("art")
				local heads = {}
				for _, artobj in ipairs(arts) do
					local art = artobj.term
					local paren_art = art:match("^%((.*)%)$")
					local with_paren = false
					if paren_art then
						with_paren = true
						art = paren_art
					end
					local lemma_art
					if lemma_for_articles[art] then
						lemma_art = ("[[%s|%s]]"):format(lemma_for_articles[art], art)
					else
						lemma_art = ("[[%s]]"):format(art)
					end
					if with_paren then
						lemma_art = "(" .. lemma_art .. ")"
					end
					if not art:find("'$") then
						lemma_art = lemma_art .. " "
					end
					for _, headobj in ipairs(data.heads) do
						headobj = m_table.shallowCopy(headobj)
						headobj.term = headobj.term or data.pagename
						-- If reconstructed, move the * before the article.
						local star, term = headobj.term:match("^(%*?)(.-)$")
						headobj.term = star .. lemma_art .. term
						require(headword_utilities_module).combine_termobj_qualifiers_labels(headobj, artobj)
						insert(heads, headobj)
					end
				end
				data.heads = heads
			end

			handle_indeclinable(data, args)
			if not args.indecl then
				local pls = data:parse_inflection(2)
				pls = data:resolve_special(pls, function(termdata)
					local infl = termdata.infl.term
					if infl == "#" then
						infl = ""
					end
					return termdata.head .. infl
				end, {
					is_special = function(infl)
						return special_noun_plurals[infl.term]
					end,
				})
				data:insert_inflection(pls, "plural")
			end

			local dims = data:parse_inflection("dim", {
				include_mods = {"g"}
			})
			dims = data:resolve_special(dims, function(termdata)
				return termdata.head .. "li"
			end)
			for _, dimobj in ipairs(dims) do
				if not dimobj.genders or not dimobj.genders[1] then
					dimobj.genders = {{
						spec = "n"
					}}
				else
					data:validate_genders(dimobj.genders, valid_genders, {
						gender_type = "diminutive"
					})
				end
			end
			data:insert_inflection(dims, "diminutive")

			local fs = data:parse_inflection("f")
			fs = data:resolve_special(fs, function(termdata)
				return termdata.head .. "in"
			end)
			data:insert_inflection(fs, "female equivalent")

			data:parse_and_insert_inflection("m", "male equivalent")
		end,
	}
end

pos_functions["nouns"] = nouns("nouns")
pos_functions["proper nouns"] = nouns("proper nouns")
pos_functions["numerals"] = nouns("numerals")

pos_functions["verbs"] = {
	params = {
		class = true,
		[1] = true, -- 3s present
		[2] = true, -- past participle
		pressub = true, -- present subjunctive
		pastsub = true, -- past subjunctive
		aux = true, -- auxiliary
	},
	func = function(data, _args)
		-- The class(es) should not be linked.
		local classes = data:parse_inflection("class")
		for _, classobj in ipairs(classes) do
			classobj.alt = classobj.term
			classobj.term = nil
		end
		data:insert_inflection(classes, "class")
		data:parse_and_insert_inflection(1, "third-person singular simple present")
		data:parse_and_insert_inflection(2, "past participle")
		data:parse_and_insert_inflection("pressub", "present subjunctive")
		data:parse_and_insert_inflection("pastsub", "past subjunctive")
		data:parse_and_insert_inflection("aux", "auxiliary")
	end,
}

return export
