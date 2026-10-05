local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local ufind = mw.ustring.find
local ulower = mw.ustring.lower
local unfd = mw.ustring.toNFD

local m_table = require("Module:table")
local m_headword_utilities = require("Module:headword utilities")

local insert = table.insert
local shallow_copy = m_table.shallowCopy
local extend = m_table.extend

-- Table of all valid genders by language.
local valid_gender_specs = {}

local valid_genders_with_animacy = {"mfbysense", "mfequiv", "mf", "m"}
local valid_genders_without_animacy = {"f", "n", "?"}
local valid_two_way_animacies = {"an", "in"}
local valid_three_way_animacies = {"pr", "anml", "in"}
local valid_number_suffixes = {"", "-p"}

local valid_langs = { "cs", "sk", "zlw-ocs", "zlw-osk" }
for _, lang in ipairs(valid_langs) do
	valid_gender_specs[lang] = {}
	local dest = valid_gender_specs[lang]
	-- The following is correct; Old Czech has three-way animacy.
	local animacy_src = lang == "cs" and valid_two_way_animacies or valid_three_way_animacies
	for _, gender in ipairs(valid_genders_without_animacy) do
		for _, number in ipairs(valid_number_suffixes) do
			dest[gender .. number] = true
		end
	end
	for _, gender in ipairs(valid_genders_with_animacy) do
		for _, number in ipairs(valid_number_suffixes) do
			for _, animacy in ipairs(animacy_src) do
				dest[gender .. "-" .. animacy .. number] = true
			end
		end
	end
end

-- Table of all valid aspects, mapping 'both' to 'biasp'.
local valid_aspects = {}
for _, aspect in {"impf", "pf", "biasp", "?"} do
	valid_aspects[aspect] = aspect
end
valid_aspects.both = "biasp"

local allowed_sk_decl_patterns = {
	"chlap", "dievča", "dub", "gazdiná", "hrdina", "kosť", "mesto", "srdce", "stroj", "ulica", "vysvedčenie", "žena",
	-- In use but not in the Appendix
	"dlaň", "idea", "kuli", "pani",
}

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|gsw-head}}.
; {{para|lang}}
: The language, required.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return m_headword_utilities.process_headword {
		lang = "invocation", -- must be passed in
		validate_lang = {"cs", "sk", "zlw-ocs", "zlw-osk"},
		frame = frame,
		pos_functions = pos_functions,
		force_cat = force_cat,
		augment_headdata = function(headdata)
			local pagename = headdata.pagename
			-- mw.ustring.toNFD performs decomposition, so letters that decompose
			-- to an ASCII vowel and a diacritic, such as é, are counted as vowels and
			-- do not need to be included in the pattern.
			if not pagename:find("[ %-]") and not ufind(ulower(unfd(pagename)), "[aeiouyæœø]") then
				headdata:insert_category("words spelled without vowels")
			end
		end,
	}
end

local function make_allowed_gender_string(valid_set)
	local valid_list = {}
	for valid_item, _ in pairs(valid_set) do
		insert(valid_list, valid_item)
	end
	table.sort(valid_list)
	return mw.text.listToText(valid_list)
end

-- We write our own gender-validation code to catch common errors and output custom messages for them.
local function validate_gender(data, vals)
	local langcode = data.lang:getCode()
	local specs = valid_gender_specs[langcode]
	for _, gspec in ipairs(vals) do
		local g = gspec.spec
		if specs[g] then
			-- do nothing
		elseif m_table.contains(valid_genders_without_animacy, g) or
			g:find("-p$") and m_table.contains(valid_genders_without_animacy, (g:gsub("-p$", ""))) then
			error("Invalid gender: '" .. g .. "'; must specify animacy along with masculine gender; expected one of " ..
				make_allowed_gender_string(specs))
		elseif langcode == "sk" and g:find("%-an") then
			error("Invalid gender: '" .. g .. "'; instead of m-an, use m-pr for people and m-anml for animals; " ..
				"expected one of " .. make_allowed_gender_string(specs))
		else
			error("Unrecognized gender: '" .. g .. "'; expected one of " .. make_allowed_gender_string(specs))
		end
	end
end

local function make_noun_infls(data)
	local langcode = data.lang:getCode()
	local infls = {
		{1, type = "gender", validate = validate_gender, default = "?"},
		{"indecl", fixed_label = "<<indeclinable>>", cat = "indeclinable {plpos}"},
		{"gen", label = "<<genitive>> <<singular>>"},
		{"pl", label =  "<<nominative>> <<plural>>"},
		{"genpl", label = "<<genitive>> <<plural>>"},
	}
	if data.lang:getCode() == "sk" then
		insert(infls,
			{"decl", label = "declension pattern of", validate = allowed_sk_decl_patterns,
				process_terms = function(processed)
					local linked_terms = {}
					for _, termobj in ipairs(processed.terms) do
						termobj = shallow_copy(termobj)
						termobj.term = ("[[Appendix:%s declension pattern %s|%s]]"):format(
							data.process_props.langname, termobj.term, termobj.term)
						insert(linked_terms, termobj)
					end
					processed.terms = linked_terms
				end,
			}
		)
	end
	extend(infls, {
		{"m", label = "male equivalent"},
		{"f", label = "female equivalent"},
		{"adj", label = "<<relational adjective|relational adjective>>"},
		{"pos", label = "<<possessive adjective|possessive adjective>>"},
		{"dim", label = "<<diminutive>>"},
		{"aug", label = "<<augmentative>>"},
		{"pej", label = "<<pejorative>>"},
		{"dem", label = "<<demonym>>"},
		{"fdem", label = "female <<demonym>>"},
	})
	return infls
end

pos_functions["nouns"] = {
	infls = make_noun_infls,
}

pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["verbs"] = {
	{"a", type = "genders", validate_and_canonicalize = valid_aspects, default = "?"},
	{"pf", label = "perfective"},
	{"impf", label = "imperfective"},
}

local function insert_comparative_superlative(infls, short)
	local shortpref = short and "short" or ""
	local short_label_pref = short and "short " or ""
	insert(infls, {shortpref .. "comp", label = short_label_pref .. "<<comparative>>"})
	insert(infls,
		{shortpref .. "sup", label = short_label_pref .. "<<superlative>>",
			default = function(data)
				local compspec = data.process_props.insert_specs[shortpref .. "comp"]
				if compspec and compspec.numterms > 0 then
					return "+"
				end
			end,
			resolve_special = function(termobj)
				local compspec = data.process_props.insert_specs[shortpref .. "comp"]
				if not compspec or compspec.numterms == 0 then
					error("Default superlative requested but no comparative terms available")
				end
				local default_sups = {}
				local langcode = termobj.headdata.lang:getCode()
				for _, compobj in ipairs(compspec.terms) do
					local supobj = shallow_copy(compobj)
					-- Old Czech has naj-.
					supobj.term = (langcode == "cs" and "nej" or "naj") .. supobj.term
					insert(default_sups, supobj)
				end
				return default_sups
			end,
		}
	)
end

local function make_adjective_infls(data)
	local langcode = data.lang:getCode()
	local infls = {
		{"indecl", fixed_label = "<<indeclinable>>", cat = "indeclinable adjectives"},
	}
	if langcode == "zlw-ocs" then
		insert(infls, {"short", label = "short form"})
	end
	insert_comparative_superlative(infls)
	if langcode == "zlw-ocs" then
		insert_comparative_superlative(infls, "short")
	end
	insert(infls, {"adv", label = "adverb"})
	return infls
end

pos_functions["adjectives"] = {
	infls = make_adjective_infls,
}

local adverb_infls = {}
insert_comparative_superlative(adverb_infls)

pos_functions["adverbs"] = {
	infls = adverb_infls
}

return export
