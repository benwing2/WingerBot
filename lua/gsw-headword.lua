local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("gsw")

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local m_table = require("Module:table")
local headword_utilities_module = "Module:headword utilities"

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

local function insert_indeclinable(infls)
	insert(infls, {"indecl", type = "boolean", fixed_label = "<<indeclinable>>", cat = "indeclinable {plpos}"})
end

local function insert_comp_sup(infls)
	insert(infls, {
		"comp", label = "<<comparative>>", resolve_special = function(termdata)
			return termdata.head .. "er"
		end,
	})
	insert(infls, {
		"sup", label = "<<superlative>>", resolve_special = function(termdata)
			return termdata.head .. "scht"
		end,
		default = function(data)
			-- If a comparative other than '-' was given, include a default superlative.
			local comp_insert_spec = data.process_props.insert_specs.comp
			if comp_insert_spec and comp_insert_spec.exists ~= "no" then
				return {term = "+"}
			end
		end,
	})
end

local function adjectives(plpos)
	local infls = {}
	insert_indeclinable(infls)
	if plpos == "adjectives" then
		insert_comp_sup(infls)
	end
	return {
		infls = infls,
	}
end

pos_functions["adjectives"] = adjectives("adjectives")
pos_functions["determiners"] = adjectives("determiners")

pos_functions["adverbs"] = (function()
	local infls = {}
	insert_comp_sup(infls)
	return {
		infls = infls,
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
	local infls = {
		{1, type = "genders", valid_genders = valid_genders, default = "?"},
	}
	if plpos == "proper nouns" then
		insert(infls,
			{"art", doclabel = "headword article",
			process_after_parse = function(data, vals)
				local heads = {}
				for _, artobj in ipairs(vals) do
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
				-- Don't return anything. The articles don't get inserted as an inflection.
			end,
		})
	end
	insert_indeclinable(infls)
	m_table.extend(infls, {
		{2, label = "plural",
			resolve_special = function(termdata)
				local infl = termdata.infl.term
				if infl == "#" then
					infl = ""
				end
				return termdata.head .. infl
			end,
			is_special = function(data, infl)
				return special_noun_plurals[infl.term]
			end,
			validate = function(data, pls)
				if data.process_props.args.indecl then
					error("Can't specify plurals when indecl=")
				end
			end,
		},
		{"dim", label = "diminutive", include_mods = {"g"},
			resolve_special = function(termdata)
				return termdata.head .. "li"
			end,
			process_after_parse = function(data, dims)
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
				return dims
			end,
		},
		{"f", label = "female equivalent",
			resolve_special = function(termdata)
				return termdata.head .. "in"
			end,
		},
		{"m", label = "male equivalent"},
	})
	return {
		infls = infls,
	}
end

pos_functions["nouns"] = nouns("nouns")
pos_functions["proper nouns"] = nouns("proper nouns")
pos_functions["numerals"] = nouns("numerals")

pos_functions["verbs"] = {
	infls = {
		{"class", doclabel = "verb class", all_fixed_label = "class {vals}"},
		{1, label = "third-person singular simple present"},
		{2, label = "past participle"},
		{"pressub", label = "present subjunctive"},
		{"pastsub", label = "past subjunctive"},
		{"aux", label = "auxiliary"},
	},
}

return export
