local export = {}
local pos_functions = {}

--[==[
Author from 2020 on: mostly Benwing2, with significant contributions from Theknightwho. Based on a prior version by Rua
(by now mostly rewritten), with contributions from Erutuon and others (see history for full attribution).
]==]

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local require = require
local require_when_needed = require("Module:require when needed")

local en_utilities_module = "Module:en-utilities"
local headword_utilities_module = "Module:headword utilities"
local headword_module = "Module:headword"
local inflection_utilities_module = "Module:inflection utilities"
local parse_utilities_module = "Module:parse utilities"
local JSON_module = "Module:JSON"
local labels_module = "Module:labels"
local links_module = "Module:links"
local parameters_module = "Module:parameters"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local utilities_module = "Module:utilities"

local iut = require_when_needed(inflection_utilities_module)
local put = require_when_needed(parse_utilities_module)

local m_headword_utilities = require_when_needed(headword_utilities_module)
local add_links_to_multiword_term = require_when_needed(headword_utilities_module, "add_links_to_multiword_term")
local add_suffix = require_when_needed(en_utilities_module, "add_suffix")
local apply_link_modifiers = require_when_needed(headword_utilities_module, "apply_link_modifiers")
local concat = table.concat
local deepEquals = require_when_needed(table_module, "deepEquals")
local dump = mw.dumpObject
local format_categories = require_when_needed(utilities_module, "format_categories")
local full_headword = require_when_needed(headword_module, "full_headword")
local get_label_info = require_when_needed(labels_module, "get_label_info")
local get_link_page = require_when_needed(links_module, "get_link_page")
local glossary_link = require_when_needed(headword_utilities_module, "glossary_link")
local insert = table.insert
local insertIfNot = require_when_needed(table_module, "insertIfNot")
local ipairs = ipairs
local is_regular_plural = require_when_needed(en_utilities_module, "is_regular_plural")
local list_to_set = require_when_needed(table_module, "listToSet")
local pairs = pairs
local process_params = require_when_needed(parameters_module, "process")
local remove = table.remove
local remove_links = require_when_needed(links_module, "remove_links")
local replacement_escape = require_when_needed(string_utilities_module, "replacement_escape")
local shallowCopy = require_when_needed(table_module, "shallowCopy")
local singularize = require_when_needed(en_utilities_module, "singularize")
local split = require_when_needed(string_utilities_module, "split")
local toJSON = require_when_needed(JSON_module, "toJSON")
local toNFD = mw.ustring.toNFD
local type = type
local ulen = require_when_needed(string_utilities_module, "len")
local ulower = require_when_needed(string_utilities_module, "lower")
local umatch = require_when_needed(string_utilities_module, "match")
local u = require_when_needed(string_utilities_module, "char")
local ugsub = require_when_needed(string_utilities_module, "gsub")

local lang = require("Module:languages").getByCode("en")
local langname = lang:getCanonicalName()

local list_param = {list = true, disallow_holes = true}
local list_allow_holes = {list = true, allow_holes = true}
local boolean_param = {type = "boolean"}

local function ine(val)
	if val == "" then return nil else return val end
end

local function track(page)
	require("Module:debug/track")("en-headword/" .. page)
	return true
end

------------------------------------------- UTILITY FUNCTIONS ------------------------------------------

-- Parse and return an inflection not requiring additional processing. The raw arguments come from `args[field]`, which
-- is parsed for inline modifiers.
local function parse_inflection(args, field, is_head)
	local argfield = field
	if type(argfield) == "table" then
		argfield = argfield[1]
	end
	return m_headword_utilities.parse_term_list_with_modifiers {
		paramname = field,
		forms = args[argfield],
		splitchar = ",",
		is_head = is_head,
	}
end



-- Insert the parsed inflections in `terms` (as parsed by `parse_inflection`) into `data.inflections`, with label
-- `label` and optional accelerator spec `accel`.
local function insert_inflection(data, terms, label, accel, no_label)
	for _, termobj in ipairs(terms) do
		m_headword_utilities.remove_termobj_field_modifiers(termobj)
	end
	m_headword_utilities.insert_inflection {
		headdata = data,
		terms = terms,
		label = label,
		no_label = no_label,
		accel = accel and {form = accel} or nil,
	}
end

-- Insert a fixed label `label` into the inflections for `data`. If `originating_term` is supplied, copy the qualifiers,
-- labels and references from it into the fixed label.
local function insert_fixed_inflection(data, label, originating_term)
	m_headword_utilities.insert_fixed_inflection {
		headdata = data,
		originating_term = originating_term,
		label = label,
	}
end

-- Parse and insert an inflection not requiring additional processing into `data.inflections`. The raw arguments come
-- from `args[field]`, which is parsed for inline modifiers. `label` is the label that the inflections are given;
-- `accel` is the accelerator form, or nil.
local function parse_and_insert_inflection(data, args, field, label, accel)
	m_headword_utilities.parse_and_insert_inflection {
		headdata = data,
		forms = args[field],
		paramname = field,
		splitchar = ",",
		label = label,
		accel = accel and {form = accel} or nil,
		-- If we want check_missing support, we need to supply the following:
		-- check_missing = true,
		-- lang = lang,
		-- plpos = plpos,
	}
end

-- These functions are used directly in the <> format as well as in the utility functions #2 below.

local function compute_double_last_cons_stem(term)
	local last_cons = term:match("([bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ])$")
	if not last_cons then
		error("Verb stem '" .. term .. "' must end in a consonant to use ++")
	end
	return term .. last_cons
end

local function compute_plusplus_s_form(term, default_s_form)
	if term:find("[szx]$") then
		-- regas -> regasses, derez -> derezzes
		return compute_double_last_cons_stem(term) .. "es"
	else
		return default_s_form
	end
end


-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
	local iparams = {
		[1] = true,
	}

	local iargs = require("Module:parameters").process(frame.args, iparams)

	local parargs = frame:getParent().args
	local poscat = iargs[1]
	local pos_in_1 = not poscat
	if pos_in_1 then
		poscat = ine(parargs[1]) or
			mw.title.getCurrentTitle().fullText == "Template:en-head" and "interjection" or
			error("Part of speech must be specified in 1=")
		poscat = require(headword_module).canonicalize_pos(poscat)
	end

	local indexing_poscat = pos_in_1 and "head" or poscat

	local params = {
		["head"] = list_param,
		["id"] = true,
		["json"] = boolean_param,
		["sort"] = true,
		["splithyph"] = boolean_param,
		["nosplithyph"] = boolean_param,
		["hyphspace"] = boolean_param,
		["nolink"] = boolean_param,
		["nolinkhead"] = {type = "boolean_param", alias_of = "nolink"},
		["nosuffix"] = boolean_param,
		["nomultiwordcat"] = boolean_param,
		["abbr"] = list_param,
		["pagename"] = true, -- for testing
	}

	if pos_in_1 then
		params[1] = {required = true} -- required but ignored as already processed above
	end

	local pos_data = pos_functions[indexing_poscat]
	local pos_func
	if pos_data then
		local pos_params = pos_data.params
		if pos_params then
			for key, val in pairs(pos_params) do
				params[key] = val
			end
		end
		pos_func = pos_data.func
	end

	local args = process_params(parargs, params)

	-- Account for unsupported titles, e.g. 'C|N>K' instead of 'Unsupported titles/C through N to K'.
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename

	local user_specified_heads = parse_inflection(args, "head", "is_head")
	local heads = user_specified_heads
	local autohead
	if args.nolink or not pagename:find("[ '%-]") then
		autohead = pagename
	else
		local en_no_split_apostrophe_words = list_to_set {
			"one's",
			"someone's",
			"he's",
			"she's",
			"it's",
		}

		local en_include_hyphen_prefixes = list_to_set {
			-- We don't include things that are also words even though they are often (perhaps mostly) prefixes, e.g.
			-- "be", "counter", "cross", "extra", "half", "mid", "over", "pan", "under".
			"acro",
			"acousto",
			"Afro",
			"agro",
			"anarcho",
			"angio",
			"Anglo",
			"ante",
			"anti",
			"arch",
			"auto",
			"bi",
			"bio",
			"cis",
			"co",
			"cryo",
			"crypto",
			"de",
			"demi",
			"eco",
			"electro",
			"Euro",
			"ex",
			"Greco",
			"hemi",
			"hydro",
			"hyper",
			"hypo",
			"infra",
			"Indo",
			"inter",
			"intra",
			"Judeo",
			"macro",
			"meta",
			"micro",
			"mini",
			"multi",
			"neo",
			"neuro",
			"non",
			"para",
			"peri",
			"post",
			"pre",
			"pro",
			"proto",
			"pseudo",
			"re",
			"semi",
			"sub",
			"super",
			"trans",
			"un",
			"vice",
		}

		local function is_english(term)
			local title = mw.title.new(term)
			if title and title.exists then
				local content = title:getContent()
				if content and content:find("==English==\n") then
					return true
				end
			end
			return false
		end

		local function en_split_hyphen_when_space(word)
			if not word:find("-", nil, true) then
				return nil
			end
			if args.hyphspace then
				return "[[" .. word:gsub("%-+", " ") .. "|" .. word .. "]]"
			end
			if args.nosplithyph then
				return "[[" .. word .. "]]"
			end
			if not args.splithyph then
				local space_word = word:gsub("%-+", " ")
				if is_english(space_word) then
					return "[[" .. space_word .. "|" .. word .. "]]"
				end
				if is_english(word) then
					return "[[" .. word .. "]]"
				end
			end
			return nil
		end

		local function en_split_apostrophe(word)
			local base = word:match("^(.*)'s$")
			if base then
				return "[[" .. base .. "]][[-'s|'s]]"
			end
			-- Only treat final apostrophe as possessive if preceded by something that looks like a plural ending in /z/.
			-- In particular we don't want to do it for words like [[truckin']].
			base = word:match("^(.*[sxz])'$")
			if base then
				if base:find("s$") then
					local sg = singularize(base)
					if is_english(sg) then
						return "[[" .. sg .. "|" .. base .. "]][[-'|']]"
					end
				end
				return "[[" .. base .. "]][[-'|']]"
			end
			return "[[" .. word .. "]]"
		end

		autohead = add_links_to_multiword_term(pagename, {
			split_hyphen_when_space = en_split_hyphen_when_space,
			split_apostrophe = en_split_apostrophe,
			no_split_apostrophe_words = en_no_split_apostrophe_words,
			include_hyphen_prefixes = en_include_hyphen_prefixes,
		})
	end

	if not heads[1] then
		heads = {{term = autohead}}
	else
		for _, headobj in ipairs(heads) do
			local head = headobj.term
			if head:find("^~") then
				head = apply_link_modifiers(autohead, head:sub(2))
				headobj.term = head
			elseif head:find("^[!?]$") then
				-- If explicit head= just consists of ! or ?, add it to the end of the default head.
				headobj.term = autohead .. head
			end
			if head == autohead then
				track("redundant-head")
			end
		end
	end

	local data = {
		lang = lang,
		pos_category = poscat,
		categories = {},
		heads = heads,
		user_specified_heads = user_specified_heads,
		-- We use our own splitting algorithm so the redundant head cat will be inaccurate.
		no_redundant_head_cat = true,
		inflections = {},
		nomultiwordcat = args.nomultiwordcat,
		sort_key = args.sort,
		pagename = pagename,
		id = args.id,
		force_cat_output = force_cat,
	}

	local function inscat(cat)
		insert(data.categories, langname .. " " .. cat)
	end

	local is_suffix = false
	if not args.nosuffix and pagename:find("^%-") and not pagename:find("^%-%-") and poscat ~= "suffix forms" then
		is_suffix = true
		data.pos_category = "suffixes"
		local singular_poscat = singularize(poscat)
		inscat(singular_poscat .. "-forming suffixes")
		insert(data.inflections, {label = singular_poscat .. "-forming suffix"})
	end

	if pos_func then
		pos_func(args, data, is_suffix)
	end

	local extra_categories = {}

	if pagename:find("[Qq]") then
		-- Check for q not followed by u. We want to exclude things like [[13q deletion syndrome]] and [[BFOQ]] that
		-- don't have a lowercase letter on either side, as well as things like [[& seq.]] and [[acq.]] that are
		-- abbreviations for words containing a following u.
		--
		-- Approximate range of combining diacritics; we want to remove them so the checks below for
		-- a lowercase letter next to the q aren't tripped up by diacritics on the letter.
		local u300 = u(0x0300)
		local u36F = u(0x036F)
		local pagename_no_diacritics = ugsub(toNFD(pagename), "[" .. u300 .. "-" .. u36F .. "]", "")
		if pagename_no_diacritics:find("[Qq][a-tv-z]") or pagename_no_diacritics:find("[a-z]q[^u.]") or
			pagename_no_diacritics:find("[a-z]q$") then
			inscat("words containing Q not followed by U")
		end
	end
	-- toNFD performs decomposition, so letters that decompose to an ASCII
	-- vowel and a diacritic, such as é, are counted as vowels and do not do not
	-- need to be included in the pattern.
	if not umatch(ulower(toNFD(pagename)), "[aeiouyæœøəªºαεηιουω]") then
		inscat("words spelled without vowels")
	end
	if pagename:find("yre$") then
		inscat('words ending in "-yre"')
	end
	if not pagename:find(" ") and ulen(pagename) >= 25 then
		insert(extra_categories, "Long " .. langname .. " words")
	end
	if pagename:find("^[^aeiou ]*a[^aeiou ]*e[^aeiou ]*i[^aeiou ]*o[^aeiou ]*u[^aeiou ]*$") then
		inscat("words that use all vowels in alphabetical order")
	end

	parse_and_insert_inflection(data, args, "abbr", "abbreviation")

	if args.json then
		return toJSON(data)
	end

	return full_headword(data)
		.. (extra_categories[1]
			and format_categories(extra_categories, lang, args.sort)
			or "")
end


local function make_default_comparative(word)
	if word == "good" or word == "well" then
		return {"better"}
	elseif word == "bad" or word == "badly" then
		return {"worse"}
	elseif word == "far" then
		return {"further", "farther"}
	else
		return {add_suffix(word, "r")}
	end
end

local function make_default_superlative(word)
	if word == "good" or word == "well" then
		return {"best"}
	elseif word == "bad" or word == "badly" then
		return {"worst"}
	elseif word == "far" then
		return {"furthest", "farthest"}
	else
		return {add_suffix(word, "st.superlative")}
	end
end

-- This function does the common work between adjectives and adverbs.
local function process_comparative_args(data, args, plpos)
	local pagename = data.pagename

	local comps = parse_inflection(args, 1)
	local sups = parse_inflection(args, "sup")

	local outcomps, outsups

	if args.componly then
		if comps[1] then
			error("Can't specify comparatives of comparative-only " .. plpos)
		end
		insert(data.inflections, {label = glossary_link("comparative") .. " form only"})
		insert(data.categories, langname .. " comparative-only " .. plpos)
		-- Set to empty list so we don't get any comparatives output, but process superlatives if specified.
		outcomps = {}
		if not sups[1] then
			-- Set to empty list so we don't get any superlatives output unless explicitly given.
			outsups = {}
		end
	elseif args.suponly then
		if comps[1] or sups[1] then
			error("Can't specify comparatives or superlatives of or superlative-only " .. plpos)
		end
		insert(data.inflections, {label = glossary_link("superlative") .. " form only"})
		insert(data.categories, langname .. " superlative-only " .. plpos)
		return
	end

	-- If the first parameter is ?, then don't show anything, just return.
	if comps[1] and comps[1].term == "?" then
		if comps[2] then
			error("Can't specify additional comparatives along with '?'")
		end
		if sups[1] then
			error("Can't specify superlatives along with '?' for the comparative")
		end
		return
	end
	if comps[1] and comps[1].term == "-" then
		local hyphencomp = remove(comps, 1)  -- Remove the "-" but retain for qualifiers, labels, references
		-- Not (generally) comparable; may occasionally have a comparative
		if comps[1] then
			insert_fixed_inflection(data, "not generally <<comparable>>", hyphencomp)
		elseif not sups[1] then
			insert_fixed_inflection(data, "not <<comparable>>", hyphencomp)
			insert(data.categories, langname .. " uncomparable " .. plpos)
			return
		else
			-- No comparative, but a superlative. insert_inflection() will correctly generate 'no comparative' if we
			-- pass in "-" as the value.
			outcomps = {hyphencomp}
		end
	elseif not comps[1] then
		comps = {{term = "more"}}
	end

	if not outcomps then -- not if we set `outcomps` to "-" above or processed a comparative-only term
		outcomps = {}
		-- Go over each parameter given and create a comparative and superlative form.
		for _, compobj in ipairs(comps) do
			local comp = compobj.term
			if comp == "-" then
				error("Comparative of '-' only allowed as first comparative")
			end
			if comp == "+" then
				comp = "+more"
			elseif comp == "more" and pagename ~= "many" and pagename ~= "much" then
				comp = "+more"
			elseif comp == "further" and pagename ~= "far" then
				comp = "+further"
			elseif comp == "better" and pagename ~= "good" and pagename ~= "well" then
				comp = "+better"
			elseif comp:find("~") then
				comp = comp:gsub("~", replacement_escape(pagename))
			end
			compobj.origterm = comp

			if comp == "+more" then
				comp = "more [[" .. pagename .. "]]"
			elseif comp == "+further" then
				comp = {"further [[" .. pagename .. "]]", "farther [[" .. pagename .. "]]"}
			elseif comp == "+better" then
				comp = "better [[" .. pagename .. "]]"
			elseif comp == "er" then
				-- Add -er.
				comp = add_suffix(pagename, "r")
			elseif comp == "ier" then
				if pagename:sub(-1) ~= "y" then
					error("Can't specify 'ier' comparative unless the term ends with 'y': " .. pagename)
				end
				comp = pagename:gsub("e?y$", "ier")
			elseif comp:find("^%+") then
				local special = m_headword_utilities.get_special_indicator(comp, "noerror")
				if special then
					comp = m_headword_utilities.handle_multiword(pagename, special, make_default_comparative)
				end
			end
			if type(comp) == "table" and not comp[2] then
				comp = comp[1]
			end
			if type(comp) == "table" then
				for i = 1, #comp - 1 do
					local outobj = shallowCopy(compobj)
					outobj.term = comp[i]
					insert(outcomps, outobj)
				end
				compobj.term = comp[#comp]
				insert(outcomps, compobj)
			else
				compobj.term = comp
				insert(outcomps, compobj)
			end
		end
	end

	if sups[1] and sups[1].term == "-" then
		if sups[2] then
			error("Can't specify '-' as superlative followed by further values")
		end
		-- No superlative. insert_inflection() will correctly generate 'no superlative' if we pass in "-" as the value.
		outsups = sups
	else
		if not sups[1] then
			sups = {{term = "+"}}
		end
	end

	-- `outsups` will be set if we set `outsups` to "-" above or processed a comparative-only term without superlatives.
	if not outsups then
		outsups = {}

		local function process_sup(sup, special, supobj, compobj)
			if special then
				sup = m_headword_utilities.handle_multiword(pagename, special, make_default_superlative)
			elseif sup == "-" or sup == "+" then
				error(("Internal error: Superlative value of '%s' should have been handled earlier"):format(sup))
			elseif sup == "+most" then
				sup = "most [[" .. pagename .. "]]"
			elseif sup == "+furthest" then
				sup = {"furthest [[" .. pagename .. "]]", "farthest [[" .. pagename .. "]]"}
			elseif sup == "+best" then
				sup = "best [[" .. pagename .. "]]"
			elseif sup == "est" then
				-- Add -est.
				sup = add_suffix(pagename, "st.superlative")
			elseif sup == "iest" then
				if pagename:sub(-1) ~= "y" then
					error("Can't specify 'iest' superlative unless the term ends with 'y': " .. pagename)
				end
				sup = pagename:gsub("e?y$", "iest")
			end
			if type(sup) == "table" and not sup[2] then
				sup = sup[1]
			end
			if compobj then
				supobj = shallowCopy(supobj)
				supobj = m_headword_utilities.combine_termobj_qualifiers_labels(supobj, compobj)
			end
			if type(sup) == "table" then
				for i = 1, #sup - 1 do
					local outobj = shallowCopy(supobj)
					outobj.term = sup[i]
					insert(outsups, outobj)
				end
				supobj.term = sup[#sup]
				insert(outsups, supobj)
			else
				supobj.term = sup
				insert(outsups, supobj)
			end
		end

		for _, supobj in ipairs(sups) do
			local sup = supobj.term
			if sup == "-" then
				error("Superlative of '-' only allowed as first superlative")
			end
			if sup == "+" then
				if not comps[1] then
					error("Superlative of '+' can't be specified when there are no comparatives")
				end
				for _, compobj in ipairs(comps) do
					local comp = compobj.origterm
					local special
					if comp == "+more" then
						sup = "+most"
					elseif comp == "+further" then
						sup = "+furthest"
					elseif comp == "+better" then
						sup = "+best"
					elseif comp == "er" then
						sup = "est"
					elseif comp == "ier" then
						sup = "iest"
					else
						if comp:find("^%+") then
							special = m_headword_utilities.get_special_indicator(comp, "noerror")
						end
						if not special then
							-- If the full comparative was given, then derive the superlative by replacing -er with
							-- -est.
							if comp:sub(-2) == "er" then
								sup = comp:sub(1, -3) .. "est"
							else
								error(("The superlative cannot be derived automatically from comparative '%s' because it doesn't end in -er"):format(comp))
							end
						end
					end
					process_sup(sup, special, supobj, compobj)
				end
			else
				local special = m_headword_utilities.get_special_indicator(sup, "noerror")
				-- Do some work here rather than in process_sup() so we don't end up double-processing a term with a '~'
				-- in it or a term that happens to be 'most' or similar after substitution of ~ in the comparative.
				if not special then
					if sup == "most" and pagename ~= "many" and pagename ~= "much" then
						sup = "+most"
					elseif sup == "furthest" and pagename ~= "far" then
						sup = "+furthest"
					elseif sup == "best" and pagename ~= "good" and pagename ~= "well" then
						sup = "+best"
					elseif sup:find("~") then
						sup = sup:gsub("~", replacement_escape(pagename))
					end
				end
				process_sup(sup, special, supobj)
			end
		end
	end

	insert_inflection(data, outcomps, "<<comparative>>", "comparative")
	insert_inflection(data, outsups, "<<superlative>>", "superlative")
end


local function make_heads_definite(args, data)
	if args.def == "~" then
		local newheads = {}
		for _, headobj in ipairs(data.heads) do
			local barehead = shallowCopy(headobj)
			insert(newheads, barehead)
			headobj.term = "the " .. headobj.term
			insert(newheads, headobj)
		end
		data.heads = newheads
	else
		for _, headobj in ipairs(data.heads) do
			headobj.term = "the " .. headobj.term
		end
	end
end


pos_functions["adjectives"] = {
	params = {
		[1] = list_param,
		["def"] = true,
		["the"] = {alias_of = "def"},
		["comp_qual"] = {list = "comp\1_qual", allow_holes = true, replaced_by = false,
			instead = "use <l:...> or <q:...> inline modifier on the comparative value",
		},
		["sup"] = list_param,
		["sup_qual"] = {list = "sup\1_qual", allow_holes = true, replaced_by = false,
			 instead = "use <l:...> or <q:...> inline modifier on the superlative value",
		},
		["componly"] = boolean_param,
		["suponly"] = boolean_param,
	},

	func = function(args, data)
		if args.def then
			make_heads_definite(args, data)
		end

		-- Process the comparatives and superlatives.
		process_comparative_args(data, args, "adjectives")
	end,
}

pos_functions["adverbs"] = {
	params = {
		[1] = list_param,
		["comp_qual"] = {list = "comp\1_qual", allow_holes = true, replaced_by = false,
			instead = "use <l:...> or <q:...> inline modifier on the comparative value",
		},
		["sup"] = list_param,
		["sup_qual"] = {list = "sup\1_qual", allow_holes = true, replaced_by = false,
			 instead = "use <l:...> or <q:...> inline modifier on the superlative value",
		},
		["componly"] = boolean_param,
		["suponly"] = boolean_param,
	},

	func = function(args, data)
		-- Process the comparatives and superlatives.
		process_comparative_args(data, args, "adverbs")
	end,
}

pos_functions["conjunctions"] = {
	params = {
		[1] = {alias_of = "head", list = false},
	},
}

pos_functions["interjections"] = pos_functions["conjunctions"]

local function escape(str)
	return (str:gsub("\\([:#])", "\\\\%1")
		:gsub("[:#]", "\\%0"))
end

local function canonicalize_plural(pl, pagename, pos)
	if pl == "+" then
		return escape(add_suffix(pagename, "s.plural", pos))
	elseif pl == "++" then
		return escape(compute_plusplus_s_form(pagename, add_suffix(pagename, "s.plural", pos)))
	elseif pl == "*" then
		return escape(pagename)
	elseif pl == "ies" then
		if pagename:sub(-1) == "y" then
			return escape(pagename:gsub("e?y$", pl))
		end
		error("Can't specify 'ies' plural unless the term ends with 'y'.")
	elseif pl == "s" or pl == "es" or pl == "'s" then
		return escape(pagename .. pl)
	end
end

local function do_nouns(args, data, pos)
	local pagename = data.pagename
	pos = pos or "noun"

	if args.def then
		make_heads_definite(args, data)
	end

	local plurals = parse_inflection(args, 1)

	local function insert_plurale_tantum_inflections(is_plural_only, originating_label)
		if args.sg[1] then
			insert_fixed_inflection(data, "normally plural", originating_label)
			parse_and_insert_inflection(data, args, "sg", "singular")
		elseif is_plural_only then
			insert_fixed_inflection(data, "plural only", originating_label)
		end
		if args.attr[1] then
			parse_and_insert_inflection(data, args, "attr", "attributive")
		end
	end

	local function first_pl_term()
		return plurals[1] and plurals[1].term or nil
	end

	if first_pl_term() == "p" then
		-- plurale tantum
		if plurals[2] then
			error("With plurale tantum noun, can't specify more than one plural")
		end
		data.genders = {"p"} -- this should auto-insert the correct 'pluralia tantum' category
		insert_plurale_tantum_inflections("plural only", plurals[1])
		return
	end

	local function inscat(cat)
		insert(data.categories, langname .. " " .. cat)
	end

	local need_default_plural = pos == "noun"
	if first_pl_term() == "sp" then
		-- construed as singular or plural
		sp = remove(plurals, 1)  -- Remove the "sp" but retain it for its qualifiers, labels, references
		inscat("nouns construed as singular or plural")
		data.genders = {"s", "p"} -- this should auto-insert the correct 'pluralia tantum' category
		insert_plurale_tantum_inflections(nil, sp)
		need_default_plural = false
	elseif first_pl_term() == "-" then
		-- Uncountable noun; may occasionally have a plural
		local hyphpl = remove(plurals, 1)  -- Remove the "-" but retain for qualifiers, labels, references
		inscat("uncountable nouns")

		-- If plural forms were given explicitly, then show "usually"
		if plurals[1] then
			insert_fixed_inflection(data, "usually <<uncountable>>", hyphpl)
		else
			insert_fixed_inflection(data, "<<uncountable>>", hyphpl)
		end
		need_default_plural = false
	elseif first_pl_term() == "#" then
		-- Usually countable (e.g., "grilled cheese")
		local hashpl = remove(plurals, 1)  -- Remove the "#" but retain for qualifiers, labels, references
		insert_fixed_inflection(data, "usually <<countable>>", hashpl)
		inscat("uncountable nouns")
		inscat("countable nouns")
		
		-- If no plural was given, add a default one now
		if not plurals[1] then
			plurals[1] = {term = escape(add_suffix(pagename, "s.plural", pos))}
		end
	elseif first_pl_term() == "~" then
		-- Mixed countable/uncountable noun, always has a plural
		local tildepl = remove(plurals, 1)  -- Remove the "~" but retain for qualifiers, labels, references
		insert_fixed_inflection(data, "<<countable>> and <<uncountable>>", tildepl)
		inscat("uncountable nouns")
		inscat("countable nouns")

		-- If no plural was given, add a default one now
		if not plurals[1] then
			plurals[1] = {term = escape(add_suffix(pagename, "s.plural", pos))}
		end
	end
	-- Plural is unknown
	if first_pl_term() == "?" then
		local questionpl = remove(plurals, 1)  -- Remove the "?" but retain for qualifiers, labels, references
		-- Not desired; see [[Wiktionary:Tea_room/2021/August#"Plural unknown or uncertain"]]
		-- insert_fixed_inflection(data, "plural unknown or uncertain", questionpl)
		inscat("nouns with unknown or uncertain plurals")
		if plurals[1] then
			error("Can't specify explicit plurals along with '?' for unknown/uncertain plural")
		end
		return
	end
	-- Plural is not attested
	if first_pl_term() == "!" then
		local exclampl = remove(plurals, 1)  -- Remove the "!" but retain for qualifiers, labels, references
		insert_fixed_inflection(data, "plural not attested", exclampl)
		inscat("nouns with unattested plurals")
		if plurals[1] then
			error("Can't specify explicit plurals along with '!' for unattested plural")
		end
		return
	end
	-- If no plural was given, maybe add a default one, otherwise (when "-" was given or proper noun) return.
	if not plurals[1] then
		if not need_default_plural then
			inscat("uncountable nouns")
			return
		end
		plurals[1] = {term = escape(add_suffix(pagename, "s.plural", pos))}
	end

	-- There are plural forms to show, so show them.
	inscat("countable nouns")
	local irregular, indeclinable
	for i, pl in ipairs(plurals) do
		local canon_pl = canonicalize_plural(pl.term, pagename, pos)
		if canon_pl then
			pl.term = canon_pl
		end
		local pl_term = get_link_page(pl.term, lang)
		if not (pagename:find(" ") or is_regular_plural(pl_term, pagename)) then
			irregular = true
			if pl_term == pagename then
				indeclinable = true
			end
		end
	end
	if irregular then
		inscat("nouns with irregular plurals")
	end
	if indeclinable then
		inscat("indeclinable nouns")
	end

	insert_inflection(data, plurals, "plural", "p")
end


-- Return the parameters to be used for nouns and proper nouns. Currently the same.
local noun_params = {
	[1] = list_param,
	["def"] = true,
	["the"] = {alias_of = "def"},
	["pl\1qual"] = {list = true, allow_holes = true, replaced_by = false,
		instead = "use <l:...> or <q:...> inline modifier on the plural",
	},
	-- The following four only used for pluralia tantum (1=p)
	["sg"] = list_param,
	["attr"] = list_param,
}


pos_functions["nouns"] = {
	params = noun_params,
	func = do_nouns,
}

pos_functions["proper nouns"] = {
	params = noun_params,
	func = function(args, data)
		return do_nouns(args, data, "proper noun")
	end,
}


local function base_default_verb_forms(verb)
	return escape(add_suffix(verb, "s.verb")), escape(add_suffix(verb, "ing")), escape(add_suffix(verb, "d"))
end


local function default_verb_forms(verb)
	local full_s_form, full_ing_form, full_ed_form = base_default_verb_forms(verb)
	if verb:find(" ") then
		local first, rest = verb:match("^(.-)( .*)$")
		local first_s_form, first_ing_form, first_ed_form = base_default_verb_forms(first)
		return full_s_form, full_ing_form, full_ed_form, first_s_form .. rest, first_ing_form .. rest,
			first_ed_form .. rest, first, rest
	else
		return full_s_form, full_ing_form, full_ed_form, nil, nil, nil, nil, nil
	end
end


local function compute_double_last_cons_stem_of_split_verb(verb, ending)
	local first, rest = verb:match("^(.-)( .*)$")
	if not first then
		error("Verb '" .. verb .. "' must have a space in it to use **")
	end
	local last_cons = first:match("([bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ])$")
	if not last_cons then
		error("First word '" .. first .. "' must end in a consonant to use **")
	end
	return first .. last_cons .. ending .. rest
end

local function check_non_nil_star_form(form, pagename)
	if form == nil then
		error("Verb '" .. pagename .. "' must have a space in it to use *, **, *l, *! or *'")
	end
	return form
end

local function sub_tilde(form, pagename)
	if not form then
		return nil
	end
	if form:find("~") then
		form = form:gsub("~", replacement_escape(pagename))
	end
	return form
end

local deprecated_qual_replaced_by_inline_modifier = {
	list = true, allow_holes = true, replaced_by = false,
	instead = "use an inline modifier <q:...> or <l:...> on the value"
}
pos_functions["verbs"] = {
	params = {
		[1] = {list = "pres_3sg", disallow_holes = true},
		["pres_3sg\1_qual"] = deprecated_qual_replaced_by_inline_modifier,
		[2] = {list = "pres_ptc", disallow_holes = true},
		["pres_ptc\1_qual"] = deprecated_qual_replaced_by_inline_modifier,
		[3] = {list = "past", disallow_holes = true},
		["past\1_qual"] = deprecated_qual_replaced_by_inline_modifier,
		[4] = {list = "past_ptc", allow_holes = true},
		["past_ptc\1_qual"] = deprecated_qual_replaced_by_inline_modifier,
		["noautolinkverb"] = boolean_param,
		["angle_bracket"] = boolean_param,
	},

	func = function(args, data)
		-- Get parameters
		local par1s
		local par2s = parse_inflection(args, {2, "pres_ptc"})
		local par3s = parse_inflection(args, {3, "past"})
		local par4s = parse_inflection(args, {4, "past_ptc"})

		local pres_3sgs, pres_ptcs, pasts, past_ptcs

		local pagename = data.pagename

		------------------------------------------- UTILITY FUNCTIONS #2 ------------------------------------------

		-- These functions are used in both in the separate-parameter format and in the override params such as past_ptc2=. 

		local full_default_s, full_default_ing, full_default_ed, split_default_s, split_default_ing, split_default_ed
		local lemma

		local function set_lemma_and_default_forms(the_lemma)
			lemma = the_lemma
			full_default_s, full_default_ing, full_default_ed, split_default_s, split_default_ing, split_default_ed,
				lemma_first, lemma_rest = default_verb_forms(the_lemma)
		end

		local function canonicalize_s_form(form)
			if form == "+" then
				error("Internal error: Should not see '+' here")
			elseif form == "^" then
				return full_default_s
			elseif form == "*" then
				return check_non_nil_star_form(split_default_s, lemma)
			elseif form == "++" then
				return compute_plusplus_s_form(lemma, full_default_s)
			elseif form == "**" then
				if lemma:find("^[^ ]*[szx] ") then
					return compute_double_last_cons_stem_of_split_verb(lemma, "es")
				else
					return check_non_nil_star_form(split_default_s, lemma)
				end
			elseif form == "+!" then
				return lemma .. "s"
			elseif form == "*!" then
				return check_non_nil_star_form(lemma_first) .. "s" .. lemma_rest
			elseif form == "+'" then
				return lemma .. "'s"
			elseif form == "*'" then
				return check_non_nil_star_form(lemma_first) .. "'s" .. lemma_rest
			elseif form == "+l" then
				if lemma:find("[szx]$") then
					return {{term = full_default_s, l = {"US"}},
							{term = compute_plusplus_s_form(lemma, full_default_s), l = {"UK"}}}
				else
					return compute_plusplus_s_form(lemma, full_default_s)
				end
			elseif form == "*l" then
				if lemma:find("^[^ ]*[szx] ") then
					return {{term = check_non_nil_star_form(split_default_s, lemma), l = {"US"}},
							{term = compute_double_last_cons_stem_of_split_verb(lemma, "es"), l = {"UK"}}}
				else
					return check_non_nil_star_form(split_default_s, lemma)
				end
			else
				return sub_tilde(form, lemma)
			end
		end

		local function canonicalize_ing_form(form)
			if form == "+" then
				error("Internal error: Should not see '+' here")
			elseif form == "^" then
				return full_default_ing
			elseif form == "*" then
				return check_non_nil_star_form(split_default_ing, lemma)
			elseif form == "++" then
				return compute_double_last_cons_stem(lemma) .. "ing"
			elseif form == "**" then
				return compute_double_last_cons_stem_of_split_verb(lemma, "ing")
			elseif form == "+!" then
				return lemma .. "ing"
			elseif form == "*!" then
				return check_non_nil_star_form(lemma_first) .. "ing" .. lemma_rest
			elseif form == "+'" then
				return lemma .. "'ing"
			elseif form == "*'" then
				return check_non_nil_star_form(lemma_first) .. "'ing" .. lemma_rest
			elseif form == "+l" then
				return {{term = full_default_ing, l = {"US"}},
						{term = compute_double_last_cons_stem(lemma) .. "ing", l = {"UK"}}}
			elseif form == "*l" then
				return {{term = check_non_nil_star_form(split_default_ing, lemma), l = {"US"}},
						{term = compute_double_last_cons_stem_of_split_verb(lemma, "ing"), l = {"UK"}}}
			else
				return sub_tilde(form, lemma)
			end
		end

		local function canonicalize_ed_form(form)
			if form == "+" then
				error("Internal error: Should not see '+' here")
			elseif form == "^" then
				return full_default_ed
			elseif form == "*" then
				return check_non_nil_star_form(split_default_ed, lemma)
			elseif form == "++" then
				return compute_double_last_cons_stem(lemma) .. "ed"
			elseif form == "+!" then
				return lemma .. "ed"
			elseif form == "*!" then
				return check_non_nil_star_form(lemma_first) .. "ed" .. lemma_rest
			elseif form == "+'" then
				return {{term = lemma .. "'d"}, {term = lemma .. "'ed"}}
			elseif form == "*'" then
				return {{term = check_non_nil_star_form(lemma_first) .. "'d" .. lemma_rest},
						{term = check_non_nil_star_form(lemma_first) .. "'ed" .. lemma_rest}}
			elseif form == "**" then
				return compute_double_last_cons_stem_of_split_verb(lemma, "ed")
			elseif form == "+l" then
				return {{term = full_default_ed, l = {"US"}},
						{term = compute_double_last_cons_stem(lemma) .. "ed", l = {"UK"}}}
			elseif form == "*l" then
				return {{term = check_non_nil_star_form(split_default_ed, lemma), l = {"US"}},
						{term = compute_double_last_cons_stem_of_split_verb(lemma, "ed"), l = {"UK"}}}
			else
				return sub_tilde(form, lemma)
			end
		end
		
		-- FIXME: options should be "+", "*", "++", "**", "+n", "*n", "++n" and "**n", but not "n"
		local function canonicalize_en_form(form)
			if form == "n" then
				track("n4")
				return add_suffix(lemma, "n")
			end
			return canonicalize_ed_form(form)
		end

		--------------------------------- MAIN PARSING/CONJUGATING CODE --------------------------------

		local is_angle_bracket = args.angle_bracket
		if is_angle_bracket then
			if par2s[1] or par3s[1] or par4s[1] then
				error("Can't specify explicit values for 2=, 3= or 4= along with the angle-bracket format")
			end
		elseif is_angle_bracket == nil and not par2s[1] and not par3s[1] and not par4s[1] and not args[1][2] and
			args[1][1] and args[1][1]:find("<") then
			if put.term_contains_top_level_html(args[1][1]) then
				-- Often, term_contains_top_level_html() returns true on the angle-bracket format, which would
				-- make the pcall() below succeed but leave the angle brackets as-is. Check for this and only do the
				-- pcall() if term_contains_top_level_html() returns false.
				is_angle_bracket = true
			else
				-- If it's ambiguous whether it's an angle-bracket format or separate params with an inline modifier,
				-- try to parse as the latter. If an error occurs, treat as the former.
				local ok
				ok, par1s = pcall(parse_inflection, args, {1, "pres_3sg"})
				if not ok then
					par1s = nil
					is_angle_bracket = true
				end
			end
		end
		if is_angle_bracket then

			-------------------------- ANGLE-BRACKET FORMAT --------------------------

			-- (0) Expand multiword term with angle brackets just on the first word.

			local arg11 = args[1][1]
			if arg11:find("^<.*>$") and pagename:find(" ") then
				local first, rest = pagename:match("^(.-)( .*)$")
				arg11 = first .. arg11 .. rest
			end
			
			-- (1) Parse the indicator specs inside of angle brackets.

			local function parse_indicator_spec(angle_bracket_spec)
				local inside = angle_bracket_spec:match("^<(.*)>$")
				assert(inside)
				local segments = put.parse_balanced_segment_run(inside, "[", "]")
				local comma_separated_groups = put.split_alternating_runs(segments, ",")
				if #comma_separated_groups > 4 then
					error("Too many comma-separated parts in indicator spec, expected at most 4: " ..
						angle_bracket_spec)
				end

				local function fetch_footnotes(separated_group)
					local footnotes
					for j = 2, #separated_group - 1, 2 do
						if separated_group[j + 1] ~= "" then
							error("Extraneous text after bracketed footnotes: '" .. concat(separated_group) .. "'")
						end
						if not footnotes then
							footnotes = {}
						end
						insert(footnotes, separated_group[j])
					end
					return footnotes
				end

				local function fetch_specs(comma_separated_group)
					if not comma_separated_group then
						return {{term = "+"}}
					end
					local specs = {}

					local colon_separated_groups = put.split_alternating_runs(comma_separated_group, ":")
					for _, colon_separated_group in ipairs(colon_separated_groups) do
						local form = colon_separated_group[1]
						if form == "*" or form == "**" or form == "*l" or form == "*!" or form == "*'" then
							error("*, **, *l, *! and *' not allowed inside of indicator specs: " .. angle_bracket_spec)
						end
						if form == "" then
							form = "+"
						end
						local termobj = {
							term = form
						}
						local footnotes = fetch_footnotes(colon_separated_group)
						if footnotes then
							for _, footnote in ipairs(footnotes) do
								m_headword_utilities.add_footnote_to_termobj(termobj, footnote)
							end
						end
						insert(specs, termobj)
					end
					return specs
				end

				local s_specs = fetch_specs(comma_separated_groups[1])
				local ing_specs = fetch_specs(comma_separated_groups[2])
				local ed_specs = fetch_specs(comma_separated_groups[3])
				local en_specs = fetch_specs(comma_separated_groups[4])

				return {
					forms = {},
					s_specs = s_specs,
					ing_specs = ing_specs,
					ed_specs = ed_specs,
					en_specs = en_specs,
				}
			end

			local parse_props = {
				parse_indicator_spec = parse_indicator_spec,
			}
			local alternant_multiword_spec = iut.parse_inflected_text(arg11, parse_props)

			-- (2) Check for user-specified brackets; remove any links from the lemma, but remember the original
			--     form so we can use it below in the 'lemma_linked' form.

			-- Check to see if there are brackets in the pre-text or post-text. If so, use the linked lemma (with the
			-- verb autolinked unless noautolinkverb is given). Otherwise, use the default headword algorithm.
			local function check_bracket(val)
				if val:find("%[%[") then
					alternant_multiword_spec.saw_bracket = true
				end
			end
			for _, alternant_or_word_spec in ipairs(alternant_multiword_spec.alternant_or_word_specs) do
				check_bracket(alternant_or_word_spec.before_text)
				if alternant_or_word_spec.alternants then
					for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
						for _, word_spec in ipairs(multiword_spec.word_specs) do
							check_bracket(word_spec.before_text)
						end
						check_bracket(multiword_spec.post_text)
					end
				end
			end
			check_bracket(alternant_multiword_spec.post_text)

			iut.map_word_specs(alternant_multiword_spec, function(base)
				if base.lemma == "" then
					base.lemma = pagename
				end
				base.orig_lemma = base.lemma
				base.lemma = remove_links(base.lemma)
				if args.noautolinkverb or base.orig_lemma:find("%[%[") then
					base.linked_lemma = base.orig_lemma
				else
					base.linked_lemma = "[[" .. base.orig_lemma .. "]]"
				end
			end)

			-- (3) Conjugate the verbs according to the indicator specs parsed above.

			local all_verb_slots = {
				lemma = "infinitive",
				lemma_linked = "infinitive",
				s_form = "3|s|pres",
				ing_form = "pres|ptcp",
				ed_form = "past",
				en_form = "past|ptcp",
			}
			local function conjugate_verb(base)
				local function process_specs(slot, specs, canon_func, default_values, default_already_formobj)
					local function insert_termobj_into_slot(termobj)
						local formobj = m_headword_utilities.convert_termobj_to_formobj(termobj)
						-- If the form is -, don't insert any forms, which will result in there being no overall forms
						-- (in fact it will be nil). We check for that down below and substitute a single "-" as the
						-- form, which in turn gets turned into special labels like "no present participle".
						if formobj.form == "-" then
							if formobj.footnotes then
								error("Unable to preserve footnotes specified on missing form '-': FIXME: " ..
									dump(formobj.footnotes))
							end
						else
							iut.insert_form(base.forms, slot, formobj)
						end
					end

					local function canonicalize_and_insert(arg)
						local canon_arg = canon_func(arg)
						if type(canon_arg) == "string" then
							arg.term = canon_arg
							insert_termobj_into_slot(arg)
						else
							for _, canon in ipairs(canon_arg) do
								m_headword_utilities.combine_termobj_qualifiers_labels(canon, arg)
								insert_termobj_into_slot(canon)
							end
						end
					end

					for _, arg in ipairs(specs) do
						if arg.term == "+" then
							if default_values then -- will be nil if past tense specified as - and no past ptc given
								for _, val in ipairs(default_values) do
									val = shallowCopy(val)
									if default_already_formobj then
										local argformobj = m_headword_utilities.convert_termobj_to_formobj(arg)
										val.footnotes = iut.combine_footnotes(val.footnotes, argformobj.footnotes)
										iut.insert_form(base.forms, slot, val)
									else
										m_headword_utilities.combine_termobj_qualifiers_labels(val, arg)
										canonicalize_and_insert(val)
									end
								end
							end
						else
							canonicalize_and_insert(arg)
						end
					end
				end

				set_lemma_and_default_forms(base.lemma)

				local all_part_default_specs = {}
				local function process_and_canonicalize_s_form(arg)
					local form = arg.term
					if form == "+" then
						error("Internal error: '+' should have been converted to '^' by now")
					end
					if form == "*" or form == "**" or form == "*l" or form == "*!" or form == "*'" then
						error(("Internal error: '%s' should have already thrown an error"):format(form))
					end
					if form == "^" or form == "++" or form == "+l" or form == "+!" or form == "+'" then
						insert(all_part_default_specs, shallowCopy(arg))
					end
					return canonicalize_s_form(form)
				end

				process_specs("s_form", base.s_specs, process_and_canonicalize_s_form, {{term = "^"}})
				if not all_part_default_specs[1] then
					all_part_default_specs[1] = {term = "^"}
				end
				process_specs("ing_form", base.ing_specs, function(arg) return canonicalize_ing_form(arg.term) end,
					all_part_default_specs)
				process_specs("ed_form", base.ed_specs, function(arg) return canonicalize_ed_form(arg.term) end,
					all_part_default_specs)
				process_specs("en_form", base.en_specs, function(arg) return canonicalize_en_form(arg.term) end,
					base.forms.ed_form, "default already formobj")

				iut.insert_form(base.forms, "lemma", {form = base.lemma})
				-- Add linked version of lemma for use in head=. We write this in a general fashion in case
				-- there are multiple lemma forms (which isn't possible currently at this level, although it's
				-- possible overall using the ((...,...)) notation).
				iut.insert_forms(base.forms, "lemma_linked", iut.map_forms(base.forms.lemma, function(form)
					if form == base.lemma and base.linked_lemma:find("%[%[") then
						return base.linked_lemma
					else
						return form
					end
				end))
			end

			local inflect_props = {
				slot_table = all_verb_slots,
				inflect_word_spec = conjugate_verb,
			}
			iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)

			-- (4) Fetch the forms and put the conjugated lemmas in data.heads if not explicitly given.

			local function fetch_termobjs(slot)
				local forms = alternant_multiword_spec.forms[slot]
				-- See above. This should only occur if the user explicitly used - for a spec.
				if not forms or not forms[1] then
					return {{term = "-"}}
				end
				local termobjs = {}
				for _, formobj in ipairs(forms) do
					insert(termobjs, m_headword_utilities.convert_formobj_to_termobj(formobj))
				end
				return termobjs
			end

			pres_3sgs = fetch_termobjs("s_form")
			pres_ptcs = fetch_termobjs("ing_form")
			pasts = fetch_termobjs("ed_form")
			past_ptcs = fetch_termobjs("en_form")
			-- Use the "linked" form of the lemma as the head if no head= explicitly given and the user specified
			-- brackets in one of the lemmas. Otherwise we use the default headword-linking algorithm.
			if not data.user_specified_heads[1] and alternant_multiword_spec.saw_bracket then
				data.heads = {}
				for _, lemma_obj in ipairs(alternant_multiword_spec.forms.lemma_linked) do
					insert(data.heads, m_headword_utilities.convert_formobj_to_termobj(lemma_obj))
				end
			end
		else
			-------------------------- SEPARATE-PARAM FORMAT --------------------------

			set_lemma_and_default_forms(pagename)

			par1s = par1s or parse_inflection(args, {1, "pres_3sg"})

			pres_3sgs = {}
			pres_ptcs = {}
			pasts = {}
			past_ptcs = {}

			if not par1s[1] then
				par1s = {{term = "+"}}
			end
			if not par2s[1] then
				par2s = {{term = "+"}}
			end
			if not par3s[1] then
				par3s = {{term = "+"}}
			end
			if not par4s[1] then
				par4s = {{term = "+"}}
			end

			local function process_argument(args, dest, canon_func, default_values, default_already_canonicalized)
				local function canonicalize_and_insert(arg)
					local canon_arg = canon_func(arg)
					if type(canon_arg) == "string" then
						arg.term = canon_arg
						m_headword_utilities.insert_termobj_combining_duplicates(dest, arg)
					else
						for _, canon in ipairs(canon_arg) do
							m_headword_utilities.combine_termobj_qualifiers_labels(canon, arg)
							m_headword_utilities.insert_termobj_combining_duplicates(dest, canon)
						end
					end
				end

				for _, arg in ipairs(args) do
					if arg.term == "+" then
						for _, val in ipairs(default_values) do
							val = shallowCopy(val)
							m_headword_utilities.combine_termobj_qualifiers_labels(val, arg)
							if default_already_canonicalized then
								m_headword_utilities.insert_termobj_combining_duplicates(dest, val)
							else
								canonicalize_and_insert(val)
							end
						end
					else
						canonicalize_and_insert(arg)
					end
				end
			end

			local all_part_default_specs = {}
			local function process_and_canonicalize_s_form(arg)
				local form = arg.term
				if form == "+" then
					error("Internal error: '+' should have been converted to '^' by now")
				end
				if form == "^" or form == "++" or form == "+l" or form == "+!" or form == "+'" or
					form == "*" or form == "**" or form == "*l" or form == "*!" or form == "*'" then
					insert(all_part_default_specs, shallowCopy(arg))
				end
				return canonicalize_s_form(form)
			end

			process_argument(par1s, pres_3sgs, process_and_canonicalize_s_form, {{term = "^"}})
			if not all_part_default_specs[1] then
				all_part_default_specs[1] = {term = "^"}
			end

			process_argument(par2s, pres_ptcs, function(arg) return canonicalize_ing_form(arg.term) end,
				all_part_default_specs)
			process_argument(par3s, pasts, function(arg) return canonicalize_ed_form(arg.term) end,
				all_part_default_specs)
			process_argument(par4s, past_ptcs, function(arg) return canonicalize_en_form(arg.term) end,
				pasts, "default already canonicalized")
		end

		------------------------------------------- INSERT INFLECTIONS ------------------------------------------

		insert_inflection(data, pres_3sgs, "third-person singular simple present", "s-verb-form")
		insert_inflection(data, pres_ptcs, "present participle", "ing-form")
		if deepEquals(pasts, past_ptcs) then
			insert_inflection(data, pasts, "simple past and past participle", "ed-form",
				"no simple past or past participle")
		else
			insert_inflection(data, pasts, "simple past", "spast")
			insert_inflection(data, past_ptcs, "past participle", "past|part")
		end

		if pagename:find(" ") then
			-- Check for placeholder "it"
			local words = split(pagename, " ")
			for _, word in ipairs(words) do
				if word == "it" or word == "its" or word == "it's" then
					insert(data.categories, langname .. ' terms with placeholder "it"')
					break
				end
			end

			-- Check for phrasal verbs
			local phrasal_adverbs = list_to_set{
				-- NOTE: This should only contain common phrasal adverbs, not random words like [[low]],
				-- [[adrift]], etc.
				"aback",
				"about",
				"above",
				"across",
				"after",
				"against",
				"ahead",
				"along",
				"apart",
				"around",
				"as",
				"aside",
				"at",
				"away",
				"back",
				"before",
				"behind",
				"below",
				"between",
				"beyond",
				"by",
				"down",
				"for",
				"forth",
				"from",
				"in",
				"into",
				"of",
				"off",
				"on",
				"onto",
				"out",
				"over",
				"past",
				"round",
				"through",
				"to",
				"together",
				"towards",
				"under",
				"up",
				"upon",
				"with",
				"without",
			}
			local allowed_non_adverb_words = list_to_set{
				"it",
				"one",
				"oneself",
				"someone",
			}
			local base = pagename
			local seen_adverbs = {}
			-- Only consider a verb to be phrasal if it consists of a single base verb followed exclusively by either
			-- adverbs from `phrasal_adverbs` or placeholder words from `allowed_non_adverb_words`, where at
			-- least one following word is from `phrasal_adverbs` (hence [[can it]] is not a phrasal verb).
			while true do
				local prev, word = base:match("^(.+) (.-)$")
				if not prev then
					break
				end
				if phrasal_adverbs[word] then
					insert(seen_adverbs, word)
				elseif allowed_non_adverb_words[word] then
					-- do nothing
				else
					break
				end
				base = prev
			end
			if not base:find(" ") and seen_adverbs[1] then
				insert(data.categories, langname .. " phrasal verbs")
				for i = #seen_adverbs, 1, -1 do
					insert(data.categories, langname .. ' phrasal verbs formed with "' .. seen_adverbs[i] ..
						'"')
				end
			end
		end
	end,
}

return export
