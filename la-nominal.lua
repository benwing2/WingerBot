local export = {}


--[=[

Authorship: Ben Wing <benwing2>, with many ideas and a little code coming from
the old [[Module:la-decl-multi]] by KC Kenny Lau.

]=]

-- TODO:
-- (DONE) Eliminate specification of noteindex from la-adj/data
-- (DONE?) Finish autodetection of adjectives
-- (DONE) Remove old noun code
-- (DONE) Implement <.sufn>
-- (DONE) Look into adj voc=false
-- (DONE) Handle loc in adjectives
-- Error on bad subtypes
-- Make sure Google Books link still works.
-- (DONE) Make sure .sufn triggers insertion of 'with m optionally -> n in compounds' in title.
-- (DONE) Make sure title returned to la-adj lowercases the first letter even with a custom title.

--[=[

TERMINOLOGY:

-- "slot" = A particular case/number combination (for nouns) or
	 case/number/gender combination (for adjectives). Example slot names are
	 "abl_sg" (for noun) or "acc_pl_f" (for adjectives). Each slot is filled
	 with zero or more forms.

-- "form" = The declined Latin form representing the value of a given slot.
	 For example, rēge is a form, representing the value of the abl_sg slot of
	 the lemma rēx.

-- "lemma" = The dictionary form of a given Latin term. For nouns, it's
	 generally the nominative singular, but will be the nominative plural of
	 plurale tantum nouns (e.g. [[castra]]), and may occasionally be another
	 form (e.g. the genitive singular) if the nominative singular is missing.
	 For adjectives, it's generally the masculine nominative singular, but
	 will be the masculine nominative plural of plurale tantum adjectives
	 (e.g. [[dēnī]]).

-- "plurale tantum" (plural "pluralia tantum") = A noun or adjective that
	 exists only in the plural. Examples are castra "army camp", faucēs "throat",
	 and dēnī "ten each" (used for counting pluralia tantum nouns).

-- "singulare tantum" (plural "singularia tantum") = A noun or adjective that
	 exists only in the singular. Examples are geōlogia "geology" (and in
	 general most non-count nouns) and the adjective ūnus "one".

]=]

local lang = require("Module:languages").getByCode("la")
local m_links = require("Module:links")
local m_utilities = require("Module:utilities")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")
local m_para = require("Module:parameters")

local current_title = mw.title.getCurrentTitle()
local NAMESPACE = current_title.nsText
local PAGENAME = current_title.text

local m_noun_decl = require("Module:la-noun/data")
local m_noun_table = require("Module:la-noun/table")
local m_adj_decl = require("Module:la-adj/data")
local m_adj_table = require("Module:la-adj/table")
local m_la_utilities = require("Module:la-utilities")

local rsplit = mw.text.split
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rgmatch = mw.ustring.gmatch
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local uupper = mw.ustring.upper

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local ligatures = {
	['Ae'] = 'Æ',
	['ae'] = 'æ',
	['Oe'] = 'Œ',
	['oe'] = 'œ',
}

local cases = {
	"nom", "gen", "dat", "acc", "abl", "voc", "loc"
}

local nums = {
	"sg", "pl"
}

local genders = {
	"m", "f", "n"
}

local irreg_noun_to_decl = {
	["bōs"] = "3",
	["cherub"] = "irreg",
	["deus"] = "2",
	["Deus"] = "2",
	["domus"] = "4,2",
	["Iēsus"] = "4",
	["Jēsus"] = "4",
	["Iēsūs"] = "4",
	["Jēsūs"] = "4",
	["iūgerum"] = "2,3",
	["jūgerum"] = "2,3",
	["sūs"] = "3",
	["ēthos"] = "3",
	["Athōs"] = "2",
	["lexis"] = "3",
	["vēnum"] = "4,2",
	["vīs"] = "3",
}

local irreg_adj_to_decl = {
	["duo"] = "irreg+",
	["ambō"] = "irreg+",
	["mīlle"] = "3-1+",
	["plūs"] = "3-1+",
	["is"] = "1&2+",
	["īdem"] = "1&2+",
	["ille"] = "1&2+",
	["ipse"] = "1&2+",
	["iste"] = "1&2+",
	["quis"] = "irreg+",
	["quī"] = "irreg+",
	["quisquis"] = "irreg+",
}

local declension_to_english = {
	["1"] = "first",
	["2"] = "second",
	["3"] = "third",
	["4"] = "fourth",
	["5"] = "fifth",
}

local number_to_english = {
	"one", "two", "three", "four", "five"
}
local linked_prefixes = {
	"", "linked_"
}

-- List of adjective slots for which we generate linked variants. Include
-- feminine and neuter variants because they will be needed if the adjective
-- is part of a multiword feminine or neuter noun.
local potential_adj_lemma_slots = {
	"nom_sg_m",
	"nom_pl_m",
	"nom_sg_f",
	"nom_pl_f",
	"nom_sg_n",
	"nom_pl_n"
}

local linked_to_non_linked_adj_slots = {}
for _, slot in ipairs(potential_adj_lemma_slots) do
	linked_to_non_linked_adj_slots["linked_" .. slot] = slot
end

local potential_noun_lemma_slots = {
	"nom_sg",
	"nom_pl"
}

local linked_to_non_linked_noun_slots = {}
for _, slot in ipairs(potential_noun_lemma_slots) do
	linked_to_non_linked_noun_slots["linked_" .. slot] = slot
end

-- Iterate over all the "slots" associated with a noun declension, where a slot
-- is a particular case/number combination. If overridable_only, don't include the
-- "linked_" variants (linked_nom_sg, linked_nom_pl), which aren't overridable.
local function iter_noun_slots(overridable_only)
	local case = 1
	local num = 1
	local linked_variant = 0
	local function iter()
		linked_variant = linked_variant + 1
		local max_linked_variant = overridable_only and 1 or cases[case] == "nom" and 2 or 1
		if linked_variant > max_linked_variant then
			linked_variant = 1
			num = num + 1
			if num > #nums then
				num = 1
				case = case + 1
				if case > #cases then
					return nil
				end
			end
		end
		return linked_prefixes[linked_variant] .. cases[case] .. "_" .. nums[num]
	end
	return iter
end

-- Iterate over all the "slots" associated with an adjective declension, where a slot
-- is a particular case/number/gender combination. If overridable_only, don't include the
-- "linked_" variants (linked_nom_sg_m, linked_nom_pl_m, etc.), which aren't overridable.
local function iter_adj_slots(overridable_only)
	local case = 1
	local num = 1
	local gen = 1
	local linked_variant = 0
	local function iter()
		linked_variant = linked_variant + 1
		local max_linked_variant = overridable_only and 1 or cases[case] == "nom" and genders[gen] == "m" and 2 or 1
		if linked_variant > max_linked_variant then
			linked_variant = 1
			gen = gen + 1
			if gen > #genders then
				gen = 1
				num = num + 1
				if num > #nums then
					num = 1
					case = case + 1
					if case > #cases then
						return nil
					end
				end
			end
		end
		return linked_prefixes[linked_variant] .. cases[case] .. "_" .. nums[num] .. "_" .. genders[gen]
	end
	return iter
end

-- Iterate over all the "slots" associated with a noun or adjective declension (depending on
-- the value of IS_ADJ), where a slot is a particular case/number combination (in the case of
-- nouns) or case/number/gender combination (in the case of adjectives). If OVERRIDABLE_ONLY
-- is specified, only include overridable slots (not including linked_ variants).
local function iter_slots(is_adj, overridable_only)
	if is_adj then
		return iter_adj_slots(overridable_only)
	else
		return iter_noun_slots(overridable_only)
	end
end

local function concat_forms_in_slot(forms)
	if forms and forms ~= "" and forms ~= "—" and #forms > 0 then
		local new_vals = {}
		for _, v in ipairs(forms) do
			table.insert(new_vals, rsub(v, "|", "<!>"))
		end
		return table.concat(new_vals, ",")
	else
		return nil
	end
end

local function glossary_link(anchor, text)
	text = text or anchor
	return "[[Appendix:Glossary#" .. anchor .. "|" .. text .. "]]"
end

local function track(page)
	require("Module:debug").track("la-nominal/" .. page)
	return true
end

local function set_union(sets)
	local union = {}
	for _, set in ipairs(sets) do
		for key, _ in pairs(set) do
			union[key] = true
		end
	end
	return union
end

local function set_difference(set1, set2)
	local diff = {}
	for key, _ in pairs(set1) do
		if not set2[key] then
			diff[key] = true
		end
	end
	return diff
end

local function process_noun_forms_and_overrides(data, args)
	local redlink = false

	-- Process overrides and canonicalize forms.
	for slot in iter_noun_slots() do
		local val = nil
		if args[slot] then
			val = args[slot]
			data.user_specified[slot] = true
		else
			-- Overridding nom_sg etc. should override linked_nom_sg so that
			-- the correct value gets displayed in the headword, which uses
			-- linked_nom_sg.
			local non_linked_equiv_slot = linked_to_non_linked_noun_slots[slot]
			if non_linked_equiv_slot and args[non_linked_equiv_slot] then
				val = args[non_linked_equiv_slot]
				data.user_specified[slot] = true
			else
				val = data.forms[slot]
			end
		end
		if val then
			if type(val) == "string" then
				val = mw.text.split(val, "/")
			end
			if (data.num == "pl" and slot:find("sg")) or (data.num == "sg" and slot:find("pl")) then
				data.forms[slot] = ""
			elseif val[1] == "" or val[1] == "-" or val[1] == "—" then
				data.forms[slot] = "—"
			else
				data.forms[slot] = val
			end
		end
	end

	-- Compute the lemma for accelerators. Do this after processing
	-- overrides in case we overrode the lemma form(s).
	local accel_lemma
	if data.num and data.num ~= "" then
		accel_lemma = data.forms["nom_" .. data.num]
	else
		accel_lemma = data.forms["nom_sg"]
	end
	if type(accel_lemma) == "table" then
		accel_lemma = accel_lemma[1]
	end

	-- Set the accelerators, and determine if there are red links.
	for slot in iter_noun_slots() do
		local val = data.forms[slot]
		if val and val ~= "" and val ~= "—" and #val > 0 then
			for i, form in ipairs(val) do
				local accel_form = slot
				accel_form = accel_form:gsub("_([sp])[gl]$", "|%1")

				data.accel[slot] = {form = accel_form, lemma = accel_lemma}
				if not redlink and NAMESPACE == '' then
					local title = lang:makeEntryName(form)
					local t = mw.title.new(title)
					if t and not t.exists then
						table.insert(data.categories, "Latin " .. data.pos .. " with red links in their inflection tables")
						redlink = true
					end
				end
			end
		end
	end
end

local function process_adj_forms_and_overrides(data, args)
	local redlink = false

	-- Process overrides and canonicalize forms.
	for slot in iter_adj_slots() do
		-- If noneut=1 passed, clear out all neuter forms.
		if data.noneut and slot:find("_n") then
			data.forms[slot] = nil
		end
		-- If nomf=1 passed, clear out all masculine and feminine forms.
		if data.nomf and (slot:find("_m") or slot:find("_f")) then
			data.forms[slot] = nil
		end
		local val = nil
		if args[slot] then
			val = args[slot]
			data.user_specified[slot] = true
		else
			-- Overridding nom_sg_m etc. should override linked_nom_sg_m so that
			-- the correct value gets displayed in the headword, which uses
			-- linked_nom_sg_m.
			local non_linked_equiv_slot = linked_to_non_linked_adj_slots[slot]
			if non_linked_equiv_slot and args[non_linked_equiv_slot] then
				val = args[non_linked_equiv_slot]
				data.user_specified[slot] = true
			else
				val = data.forms[slot]
			end
		end
		if val then
			if type(val) == "string" then
				val = mw.text.split(val, "/")
			end
			if (data.num == "pl" and slot:find("sg")) or (data.num == "sg" and slot:find("pl")) then
				data.forms[slot] = ""
			elseif val[1] == "" or val[1] == "-" or val[1] == "—" then
				data.forms[slot] = "—"
			else
				data.forms[slot] = val
			end
		end
	end

	-- Compute the lemma for accelerators. Do this after processing
	-- overrides in case we overrode the lemma form(s).
	local accel_lemma, accel_lemma_f
	if data.num and data.num ~= "" then
		accel_lemma = data.forms["nom_" .. data.num .. "_m"]
		accel_lemma_f = data.forms["nom_" .. data.num .. "_f"]
	else
		accel_lemma = data.forms["nom_sg_m"]
		accel_lemma_f = data.forms["nom_sg_f"]
	end
	if type(accel_lemma) == "table" then
		accel_lemma = accel_lemma[1]
	end
	if type(accel_lemma_f) == "table" then
		accel_lemma_f = accel_lemma_f[1]
	end

	-- Set the accelerators, and determine if there are red links.
	for slot in iter_adj_slots() do
		local val = data.forms[slot]
		if val and val ~= "" and val ~= "—" and #val > 0 then
			for i, form in ipairs(val) do
				local accel_form = slot
				accel_form = accel_form:gsub("_([sp])[gl]_", "|%1|")

				if data.noneut then
					-- If noneut=1, we're being asked to do a noun like
					-- Aquītānus or Rōmānus that has masculine and feminine
					-- variants, not an adjective. In that case, make the
					-- accelerators correspond to nominal case/number forms
					-- without the gender, and use the feminine as the
					-- lemma for feminine forms.
					if slot:find("_f") then
						data.accel[slot] = {form = accel_form:gsub("|f$", ""), lemma = accel_lemma_f}
					else
						data.accel[slot] = {form = accel_form:gsub("|m$", ""), lemma = accel_lemma}
					end
				else
					if not data.forms.nom_sg_n and not data.forms.nom_pl_n then
						-- use multipart tags if called for
						accel_form = accel_form:gsub("|m$", "|m//f//n")
					elseif not data.forms.nom_sg_f and not data.forms.nom_pl_f then
						accel_form = accel_form:gsub("|m$", "|m//f")
					end

					-- use the order nom|m|s, which is more standard than nom|s|m
					accel_form = accel_form:gsub("|(.-)|(.-)$", "|%2|%1")

					data.accel[slot] = {form = accel_form, lemma = accel_lemma}
				end
				if not redlink and NAMESPACE == '' then
					local title = lang:makeEntryName(form)
					local t = mw.title.new(title)
					if t and not t.exists then
						table.insert(data.categories, "Latin " .. data.pos .. " with red links in their inflection tables")
						redlink = true
					end
				end
			end
		end
	end

	-- See if the masculine and feminine/neuter are the same across all slots.
	-- If so, blank out the feminine/neuter so we use a table that combines
	-- masculine and feminine, or masculine/feminine/neuter.
	for _, gender in ipairs({"f", "n"}) do
		local other_is_masc = true
		for _, case in ipairs(cases) do
			for _, num in ipairs(nums) do
				if not m_table.deepEquals(data.forms[case .. "_" .. num .. "_" .. gender],
						data.forms[case .. "_" .. num .. "_m"]) then
					other_is_masc = false
					break
				end
			end
			if not other_is_masc then
				break
			end
		end

		if other_is_masc then
			for _, case in ipairs(cases) do
				for _, num in ipairs(nums) do
					data.forms[case .. "_" .. num .. "_" .. gender] = nil
				end
			end
		end
	end
end

-- Convert data.forms[slot] for all slots into displayable text. This is
-- an older function, still currently used for nouns but not for adjectives.
-- For adjectives, the adjective table module has special code to combine
-- adjacent slots, and needs the original forms plus other text that will
-- go into the displayable text for the slot; this is handled below by
-- partial_show_forms() and finish_show_form().
local function show_forms(data, is_adj)
	local noteindex = 1
	local notes = {}
	local seen_notes = {}
	for slot in iter_slots(is_adj) do
		local val = data.forms[slot]
		if val and val ~= "" and val ~= "—" then
			for i, form in ipairs(val) do
				local link = m_links.full_link({lang = lang, term = form, accel = data.accel[slot]})
				local this_notes = data.notes[slot .. i]
				if this_notes and not data.user_specified[slot] then
					if type(this_notes) == "string" then
						this_notes = {this_notes}
					end
					local link_indices = {}
					for _, this_note in ipairs(this_notes) do
						local this_noteindex = seen_notes[this_note]
						if not this_noteindex then
							-- Generate a footnote index.
							this_noteindex = noteindex
							noteindex = noteindex + 1
							table.insert(notes, '<sup style="color: red">' .. this_noteindex .. '</sup>' .. this_note)
							seen_notes[this_note] = this_noteindex
						end
						m_table.insertIfNot(link_indices, this_noteindex)
					end
					val[i] = link .. '<sup style="color: red">' .. table.concat(link_indices, ",") .. '</sup>'
				else
					val[i] = link
				end
			end
			-- FIXME, do we want this difference?
			data.forms[slot] = table.concat(val, is_adj and ", " or "<br />")
		end
	end
	for _, footnote in ipairs(data.footnotes) do
		table.insert(notes, footnote)
	end
	data.footnotes = table.concat(notes, "<br />")
end

-- Generate the display form for a set of slots with identical content. We
-- verify that the slots are actually identical, and throw an assertion error
-- if not. The display form is as in show_forms() but combines together all the
-- accelerator forms for all the slots.
local function finish_show_form(data, slots, is_adj)
	assert(#slots > 0)
	local slot1 = slots[1]
	local forms = data.forms[slot1]
	local notetext = data.notetext[slot1]
	for _, slot in ipairs(slots) do
		if not m_table.deepEquals(data.forms[slot], forms) then
			error("data.forms[" .. slot1 .. "] = " .. (concat_forms_in_slot(forms) or "nil") ..
				", but data.forms[" .. slot .. "] = " .. (concat_forms_in_slot(data.forms[slot]) or "nil"))
		end
		assert(m_table.deepEquals(data.notetext[slot], notetext))
	end
	if not forms then
		return "—"
	else
		local accel_forms = {}
		local accel_lemma = data.accel[slot1].lemma
		for _, slot in ipairs(slots) do
			assert(data.accel[slot].lemma == accel_lemma)
			table.insert(accel_forms, data.accel[slot].form)
		end
		local combined_accel_form = table.concat(accel_forms, "|;|")
		local accel = {form = combined_accel_form, lemma = accel_lemma}
		local formtext = {}
		for i, form in ipairs(forms) do
			table.insert(formtext, m_links.full_link({lang = lang, term = form, accel = accel}) .. notetext[i])
		end
		-- FIXME, do we want this difference?
		return table.concat(formtext, is_adj and ", " or "<br />")
	end
end

-- Used by the adjective table module. This does some of the work of
-- show_forms(); in particular, it converts all empty forms of any format
-- (nil, "", "—") to nil and, if the forms aren't empty, generates the footnote
-- text associated with each form.
local function partial_show_forms(data, is_adj)
	local noteindex = 1
	local notes = {}
	local seen_notes = {}
	data.notetext = {}
	-- Store this function in DATA so that it can be called from the adjective
	-- table module without needing to require this module, which will (or
	-- could) lead to recursive module requiring.
	data.finish_show_form = finish_show_form
	for slot in iter_slots(is_adj) do
		local val = data.forms[slot]
		if not val or val == "" or val == "—" then
			data.forms[slot] = nil
		else
			local notetext = {}
			for i, form in ipairs(val) do
				local this_notes = data.notes[slot .. i]
				if this_notes and not data.user_specified[slot] then
					if type(this_notes) == "string" then
						this_notes = {this_notes}
					end
					local link_indices = {}
					for _, this_note in ipairs(this_notes) do
						local this_noteindex = seen_notes[this_note]
						if not this_noteindex then
							-- Generate a footnote index.
							this_noteindex = noteindex
							noteindex = noteindex + 1
							table.insert(notes, '<sup style="color: red">' .. this_noteindex .. '</sup>' .. this_note)
							seen_notes[this_note] = this_noteindex
						end
						m_table.insertIfNot(link_indices, this_noteindex)
					end
					table.insert(notetext, '<sup style="color: red">' .. table.concat(link_indices, ",") .. '</sup>')
				else
					table.insert(notetext, "")
				end
			end
			data.notetext[slot] = notetext
		end
	end
	for _, footnote in ipairs(data.footnotes) do
		table.insert(notes, footnote)
	end
	data.footnotes = table.concat(notes, "<br />")
end

local function make_noun_table(data)
	if data.num == "sg" then
		return m_noun_table.make_table_sg(data)
	elseif data.num == "pl" then
		return m_noun_table.make_table_pl(data)
	else
		return m_noun_table.make_table(data)
	end
end

local function concat_forms(data, is_adj, include_props)
	local ins_text = {}
	for slot in iter_slots(is_adj) do
		local formtext = concat_forms_in_slot(data.forms[slot])
		if formtext then
			table.insert(ins_text, slot .. "=" .. formtext)
		end
	end
	if include_props then
		if data.gender then
			table.insert(ins_text, "g=" .. mw.ustring.lower(data.gender))
		end
		local num = data.num
		if not num or num == "" then
			num = "both"
		end
		table.insert(ins_text, "num=" .. num)
	end
	return table.concat(ins_text, "|")
end

-- Given an ending (or possibly a full regex matching the entire lemma, if
-- a regex group is present), return the base minus the ending, or nil if
-- the ending doesn't match.
local function extract_base(lemma, ending)
	if ending:find("%(") then
		return rmatch(lemma, ending)
	else
		return rmatch(lemma, "^(.*)" .. ending .. "$")
	end
end

-- Given ENDINGS_AND_SUBTYPES (a list of pairs of endings with associated
-- subtypes, where each pair consists of a single ending spec and a list of
-- subtypes), check each ending in turn against LEMMA. If it matches, return
-- the pair BASE, STEM2, SUBTYPES where BASE is the remainder of LEMMA minus
-- the ending, STEM2 is as passed in, and SUBTYPES is the subtypes associated
-- with the ending. But don't return SUBTYPES if any of the subtypes in the
-- list is specifically canceled in SPECIFIED_SUBTYPES (a set, i.e. a table
-- where the keys are strings and the value is always true); instead, consider
-- the next ending in turn. If no endings match, throw an error if DECLTYPE is
-- non-nil, mentioning the DECLTYPE (the user-specified declension); but if
-- DECLTYPE is nil, just return nil, nil, nil.
--
-- The ending spec in ENDINGS_AND_SUBTYPES is one of the following:
--
-- 1. A simple string, e.g. "tūdō", specifying an ending.
-- 2. A regex that should match the entire lemma (it should be anchored at
--    the beginning with ^ and at the end with $), and contains a single
--    capturing group to match the base.
-- 3. A pair {SIMPLE_STRING_OR_REGEX, STEM2_ENDING} where
--    SIMPLE_STRING_OR_REGEX is one of the previous two possibilities and
--    STEM2_ENDING is a string specifying the corresponding ending that must
--    be present in STEM2. If this form is used, the combination of
--    base + STEM2_ENDING must exactly match STEM2 in order for this entry
--    to be considered a match. An example is {"is", ""}, which will match
--    lemma == "follis", stem2 == "foll", but not lemma == "lapis",
--    stem2 == "lapid".
local function get_noun_subtype_by_ending(lemma, stem2, decltype, specified_subtypes,
		endings_and_subtypes)
	for _, ending_and_subtypes in ipairs(endings_and_subtypes) do
		local ending = ending_and_subtypes[1]
		local subtypes = ending_and_subtypes[2]
		not_this_subtype = false
		if specified_subtypes.pl and not m_table.contains(subtypes, "pl") then
			-- We now require that plurale tantum terms specify a plural-form lemma.
			-- The autodetected subtypes will include 'pl' for such lemmas; if not,
			-- we fail this entry.
			not_this_subtype = true
		else
			for _, subtype in ipairs(subtypes) do
				-- A subtype is directly canceled by specifying -SUBTYPE.
				-- In addition, M or F as a subtype is canceled by N, and
				-- vice-versa, but M doesn't cancel F or vice-versa; instead,
				-- we simply ignore the conflicting gender specification when
				-- constructing the combination of specified and inferred subtypes.
				-- The reason for this is that neuters have distinct declensions
				-- from masculines and feminines, but masculines and feminines have
				-- the same declension, and various nouns in Latin that are
				-- normally masculine are exceptionally feminine and vice-versa
				-- (nauta, agricola, fraxinus, malus "apple tree", manus, rēs,
				-- etc.).
				--
				-- In addition, sg as a subtype is canceled by pl and vice-versa.
				-- It's also possible to specify both, which will override sg but
				-- not cancel it (in the sense that it won't prevent the relevant
				-- rule from matching). For example, there's a rule specifying that
				-- lemmas beginning with a capital letter and ending in -ius take
				-- the ius.voci.sg subtypes.  Specifying such a lemma with the
				-- subtype both will result in the ius.voci.both subtypes, whereas
				-- specifying such a lemma with the subtype pl will cause this rule
				-- not to match, and it will fall through to a less specific rule
				-- that returns just the ius subtype, which will be combined with
				-- the explicitly specified pl subtype to produce ius.pl.
				if specified_subtypes["-" .. subtype] or
					subtype == "N" and (specified_subtypes.M or specified_subtypes.F) or
					(subtype == "M" or subtype == "F") and specified_subtypes.N or
					subtype == "sg" and specified_subtypes.pl or
					subtype == "pl" and specified_subtypes.sg then
					not_this_subtype = true
					break
				end
			end
		end
		if not not_this_subtype then
			if type(ending) == "table" then
				local lemma_ending = ending[1]
				local stem2_ending = ending[2]
				local base = extract_base(lemma, lemma_ending)
				if base and base .. stem2_ending == stem2 then
					return base, stem2, subtypes
				end
			else
				local base = extract_base(lemma, ending)
				if base then
					return base, stem2, subtypes
				end
			end
		end
	end
	if decltype then
		error("Unrecognized ending for declension-" .. decltype .. " noun: " .. lemma)
	end
	return nil, nil, nil
end

-- Autodetect the subtype of a noun given all the information specified by the
-- user: lemma, stem2, declension type and specified subtypes. Three values are
-- returned: the lemma base (i.e. the stem of the lemma, as required by the
-- declension functions), the new stem2 and the autodetected subtypes. Note
-- that this will not detect a given subtype if the explicitly specified
-- subtypes are incompatible (i.e. if -SUBTYPE is specified for any subtype
-- that would be returned; or if M or F is specified when N would be returned,
-- and vice-versa; or if pl is specified when sg would be returned, and
-- vice-versa).
--
-- NOTE: This function has intimate knowledge of the way that the declension
-- functions handle subtypes, particularly for the third declension.
local function detect_noun_subtype(lemma, stem2, typ, subtypes)
	local base, ending

	if typ == "1" then
		return get_noun_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"ām", {"F", "am"}},
			{"ās", {"M", "Greek", "Ma"}},
			{"ēs", {"M", "Greek", "Me"}},
			{"ē", {"F", "Greek"}},
			{"ae", {"F", "pl"}},
			{"a", {"F"}},
		})
	elseif typ == "2" then
		local detected_subtypes
		lemma, stem2, detected_subtypes = get_noun_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"^(.*r)$", {"M", "er"}},
			{"^(.*v)os$", {"M", "vos"}},
			{"^(.*v)om$", {"N", "vom"}},
			-- If the lemma ends in -os and the user said N or -M, then the
			-- following won't apply, and the second (neuter) -os will applly.
			{"os", {"M", "Greek"}},
			{"os", {"N", "Greek", "us"}},
			{"on", {"N", "Greek"}},
			-- -ius beginning with a capital letter is assumed a proper name,
			-- and takes the voci subtype (vocative in -ī) along with the ius
			-- subtype and sg-only. Other nouns in -ius just take the ius
			-- subtype. Explicitly specify "sg" so that if .pl is given,
			-- this rule won't apply.
			{"^([A-ZĀĒĪŌŪȲĂĔĬŎŬ].*)ius$", {"M", "ius", "voci", "sg"}},
			{"ius", {"M", "ius"}},
			{"ium", {"N", "ium"}},
			-- If the lemma ends in -us and the user said N or -M, then the
			-- following won't apply, and the second (neuter) -us will applly.
			{"us", {"M"}},
			{"us", {"N", "us"}},
			{"um", {"N"}},
			{"iī", {"M", "ius", "pl"}},
			{"ia", {"N", "ium", "pl"}},
			-- If the lemma ends in -ī and the user said N or -M, then the
			-- following won't apply, and the second (neuter) -ī will applly.
			{"ī", {"M", "pl"}},
			{"ī", {"N", "us", "pl"}},
			{"a", {"N", "pl"}},
		})
		stem2 = stem2 or lemma
		return lemma, stem2, detected_subtypes
	elseif typ == "3" then
		if subtypes.pl then
			if subtypes.Greek then
				base = rmatch(lemma, "^(.*)erēs$")
				if base then
					return base .. "ēr", base .. "er", {"er"}
				end
				base = rmatch(lemma, "^(.*)ontēs$")
				if base then
					return base .. "ōn", base .. "ont", {"on"}
				end
				base = rmatch(lemma, "^(.*)es$")
				if base then
					return "foo", stem2 or base, {}
				end
				error("Unrecognized ending for declension-3 plural Greek noun: " .. lemma)
			end
			base = rmatch(lemma, "^(.*)ia$")
			if base then
				return "foo", stem2 or base, {"N", "I", "pure"}
			end
			base = rmatch(lemma, "^(.*)a$")
			if base then
				return "foo", stem2 or base, {"N"}
			end
			base = rmatch(lemma, "^(.*)ēs$")
			if base then
				return "foo", stem2 or base, {}
			end
			error("Unrecognized ending for declension-3 plural noun: " .. lemma)
		end

		stem2 = stem2 or m_la_utilities.make_stem2(lemma)
		local detected_subtypes
		if subtypes.Greek then
			base, _, detected_subtypes = get_noun_subtype_by_ending(lemma, stem2, nil, subtypes, {
				{{"is", ""}, {"I"}},
				{"ēr", {"er"}},
				{"ōn", {"on"}},
			})
			if base then
				return lemma, stem2, detected_subtypes
			end
			return lemma, stem2, {}
		end

		if not subtypes.N then
			base, _, detected_subtypes = get_noun_subtype_by_ending(lemma, stem2, nil, subtypes, {
				{{"^([A-ZĀĒĪŌŪȲĂĔĬŎŬ].*pol)is$", ""}, {"F", "polis", "sg", "loc"}},
				{{"tūdō", "tūdin"}, {"F"}},
				{{"tās", "tāt"}, {"F"}},
				{{"tūs", "tūt"}, {"F"}},
				{{"tiō", "tiōn"}, {"F"}},
				{{"siō", "siōn"}, {"F"}},
				{{"xiō", "xiōn"}, {"F"}},
				{{"gō", "gin"}, {"F"}},
				{{"or", "ōr"}, {"M"}},
				{{"trīx", "trīc"}, {"F"}},
				{{"trix", "trīc"}, {"F"}},
				{{"is", ""}, {"I"}},
				{{"^([a-zāēīōūȳăĕĭŏŭ].*)ēs$", ""}, {"I"}},
			})
			if base then
				return lemma, stem2, detected_subtypes
			end
		end

		base, _, detected_subtypes = get_noun_subtype_by_ending(lemma, stem2, nil, subtypes, {
			{{"us", "or"}, {"N"}},
			{{"us", "er"}, {"N"}},
			{{"ma", "mat"}, {"N"}},
			{{"men", "min"}, {"N"}},
			{{"^([A-ZĀĒĪŌŪȲĂĔĬŎŬ].*)e$", ""}, {"N", "sg"}},
			{{"e", ""}, {"N", "I", "pure"}},
			{{"al", "āl"}, {"N", "I", "pure"}},
			{{"ar", "ār"}, {"N", "I", "pure"}},
		})
		if base then
			return lemma, stem2, detected_subtypes
		end
		return lemma, stem2, {}
	elseif typ == "4" then
		if subtypes.echo or subtypes.argo or subtypes.Callisto then
			base = rmatch(lemma, "^(.*)ō$")
			if not base then
				error("Declension-4 noun of subtype .echo, .argo or .Callisto should end in -ō: " .. lemma)
			end
			if subtypes.Callisto then
				return base, nil, {"F", "sg"}
			else
				return base, nil, {"F"}
			end
		end
		return get_noun_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"us", {"M"}},
			{"ū", {"N"}},
			{"ūs", {"M", "pl"}},
			{"ua", {"N", "pl"}},
		})
	elseif typ == "5" then
		return get_noun_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"iēs", {"F", "i"}},
			{"iēs", {"F", "i", "pl"}},
			{"ēs", {"F"}},
			{"ēs", {"F", "pl"}},
		})
	elseif typ == "irreg" and lemma == "domus" then
		-- [[domus]] auto-sets data.loc = true, but we need to know this
		-- before declining the noun so we can propagate it to other segments.
		return lemma, nil, {"loc"}
	elseif typ == "indecl" or typ == "irreg" and (
		lemma == "Deus" or lemma == "Iēsus" or lemma == "Jēsus" or
		lemma == "Athōs" or lemma == "vēnum"
	) then
		-- Indeclinable nouns, and certain irregular nouns, set data.num = "sg",
		-- but we need to know this before declining the noun so we can
		-- propagate it to other segments.
		return lemma, nil, {"sg"}
	else
		return lemma, nil, {}
	end
end

function export.detect_noun_subtype(frame)
	local params = {
		[1] = {required = true},
		[2] = {},
		[3] = {},
		[4] = {},
	}
	local args = m_para.process(frame.args, params)
	local specified_subtypes = {}
	if args[4] then
		for _, subtype in ipairs(rsplit(args[4], ".")) do
			specified_subtypes[subtype] = true
		end
	end
	local base, stem2, subtypes = detect_noun_subtype(args[1], args[2], args[3], specified_subtypes)
	return base .. "|" .. (stem2 or "") .. "|" .. table.concat(subtypes, ".")
end

-- Given ENDINGS_AND_SUBTYPES (a list of four-tuples of ENDING, RETTYPE,
-- SUBTYPES, PROCESS_RETVAL), check each ENDING in turn against LEMMA and
-- STEM2. If it matches, return a four-tuple BASE, STEM2, RETTYPE, NEW_SUBTYPES
-- where BASE is normally the remainder of LEMMA minus the ending, STEM2 is
-- as passed in, RETTYPE is as passed in, and NEW_SUBTYPES is the same as
-- SUBTYPES minus any subtypes beginning with a hyphen. If no endings match,
-- throw an error if DECLTYPPE is non-nil, mentioning the DECLTYPE
-- (user-specified declension); but if DECLTYPE is nil, just return the tuple
-- nil, nil, nil, nil.
--
-- In order for a given entry to match, ENDING must match and also the subtypes
-- in SUBTYPES (a list) must not be incompatible with the passed-in
-- user-specified subtypes SPECIFIED_SUBTYPES (a set, i.e. a table where the
-- keys are strings and the value is always true). "Incompatible" means that
-- a given SUBTYPE is specified in either one and -SUBTYPE in the other, or
-- that "pl" is found in SPECIFIED_SUBTYPES and not in SUBTYPES.
--
-- The ending spec in ENDINGS_AND_SUBTYPES is one of the following:
--
-- 1. A simple string, e.g. "tūdō", specifying an ending.
-- 2. A regex that should match the entire lemma (it should be anchored at
--    the beginning with ^ and at the end with $), and contains a single
--    capturing group to match the base.
-- 3. A pair {SIMPLE_STRING_OR_REGEX, STEM2_ENDING} where
--    SIMPLE_STRING_OR_REGEX is one of the previous two possibilities and
--    STEM2_ENDING is a string specifying the corresponding ending that must
--    be present in STEM2. If this form is used, the combination of
--    base + STEM2_ENDING must exactly match STEM2 in order for this entry
--    to be considered a match. An example is {"is", ""}, which will match
--    lemma == "follis", stem2 == "foll", but not lemma == "lapis",
--    stem2 == "lapid".
--
-- If PROCESS_STEM2 is given and the returned STEM2 would be nil, call
-- process_stem2(BASE) to get the STEM2 to return.
local function get_adj_type_and_subtype_by_ending(lemma, stem2, decltype,
		specified_subtypes, endings_and_subtypes, process_stem2)
	for _, ending_and_subtypes in ipairs(endings_and_subtypes) do
		local ending = ending_and_subtypes[1]
		local rettype = ending_and_subtypes[2]
		local subtypes = ending_and_subtypes[3]
		local process_retval = ending_and_subtypes[4]
		not_this_subtype = false
		if specified_subtypes.pl and not m_table.contains(subtypes, "pl") then
			-- We now require that plurale tantum terms specify a plural-form lemma.
			-- The autodetected subtypes will include 'pl' for such lemmas; if not,
			-- we fail this entry.
			not_this_subtype = true
		else
			for _, subtype in ipairs(subtypes) do
				-- A subtype is directly canceled by specifying -SUBTYPE.
				if specified_subtypes["-" .. subtype] then
					not_this_subtype = true
					break
				end
				-- A subtype is canceled if the user specified SUBTYPE and
				-- -SUBTYPE is given in the to-be-returned subtypes.
				local must_not_be_present = rmatch(subtype, "^%-(.*)$")
				if must_not_be_present and specified_subtypes[must_not_be_present] then
					not_this_subtype = true
					break
				end
			end
		end
		if not not_this_subtype then
			local base
			if type(ending) == "table" then
				local lemma_ending = ending[1]
				local stem2_ending = ending[2]
				base = extract_base(lemma, lemma_ending)
				if base and base .. stem2_ending ~= stem2 then
					base = nil
				end
			else
				base = extract_base(lemma, ending)
			end
			if base then
				-- Remove subtypes of the form -SUBTYPE from the subtypes
				-- to be returned.
				local new_subtypes = {}
				for _, subtype in ipairs(subtypes) do
					if not rfind(subtype, "^%-") then
						table.insert(new_subtypes, subtype)
					end
				end
				if process_retval then
					base, stem2 = process_retval(base, stem2)
				end
				if process_stem2 then
					stem2 = stem2 or process_stem2(base)
				end
				return base, stem2, rettype, new_subtypes
			end
		end
	end
	if not decltype then
		return nil, nil, nil, nil
	elseif decltype == "" then
		error("Unrecognized ending for adjective: " .. lemma)
	else
		error("Unrecognized ending for declension-" .. decltype .. " adjective: " .. lemma)
	end
end

-- Autodetect the type and subtype of an adjective given all the information
-- specified by the user: lemma, stem2, declension type and specified subtypes.
-- Four values are returned: the lemma base (i.e. the stem of the lemma, as
-- required by the declension functions), the value of stem2 to pass to the
-- declension function, the declension type and the autodetected subtypes.
-- Note that this will not detect a given subtype if -SUBTYPE is specified for
-- any subtype that would be returned, or if SUBTYPE is specified and -SUBTYPE
-- is among the subtypes that would be returned (such subtypes are filtered out
-- of the returned subtypes).
local function detect_adj_type_and_subtype(lemma, stem2, typ, subtypes)
	if not rfind(typ, "^[0123]") and not rfind(typ, "^irreg") then
		subtypes = mw.clone(subtypes)
		subtypes[typ] = true
		typ = ""
	end

	local function base_as_stem2(base, stem2)
		return "foo", base
	end

	local function constant_base(baseval)
		return function(base, stem2)
			return baseval, nil
		end
	end

	local function decl12_stem2(base)
		return base
	end
	
	local function decl3_stem2(base)
		return m_la_utilities.make_stem2(base)
	end
		
	local decl12_entries = {
		{"us", "1&2", {}},
		{"a", "1&2", {}},
		{"um", "1&2", {}},
		{"ī", "1&2", {"pl"}},
		{"ae", "1&2", {"pl"}},
		{"a", "1&2", {"pl"}},
		-- Nearly all -os adjectives are greekA
		{"os", "1&2", {"greekA", "-greekE"}},
		{"os", "1&2", {"greekE", "-greekA"}},
		{"ē", "1&2", {"greekE", "-greekA"}},
		{"on", "1&2", {"greekA", "-greekE"}},
		{"on", "1&2", {"greekE", "-greekA"}},
		{"^(.*er)$", "1&2", {"er"}},
		{"^(.*ur)$", "1&2", {"er"}},
		{"^(h)ic$", "1&2", {"ic"}},
	}

	local decl3_entries = {
		{"^(.*er)$", "3-3", {}},
		{"is", "3-2", {}},
		{"e", "3-2", {}},
		{"^(.*[ij])or$", "3-C", {}},
		{"^(min)or$", "3-C", {}},
		-- Detect -ēs as 3-1 without auto-inferring .pl if .pl
		-- not specified. If we don't do this, the later entry for
		-- -ēs will auto-infer .pl whenever -ēs is specified (which
		-- won't work for adjectives like quadripēs, volucripēs).
		-- Essentially, for declension-3 adjectives, we require that
		-- .pl is given if the lemma is plural.
		--
		-- Most 3-1 adjectives are i-stem (e.g. audāx) so we require -I
		-- to be given with non-i-stem adjectives. The first entry below
		-- will apply when -I isn't given, the second when it is given.
		{"^(.*ēs)$", "3-1", {"I"}},
		{"^(.*ēs)$", "3-1", {"par"}},
		{"^(.*[ij])ōrēs$", "3-C", {"pl"}},
		{"^(min)ōrēs$", "3-C", {"pl"}},
		-- If .pl with -ēs, we don't know if the adjective is 3-1, 3-2
		-- or 3-3. Since 3-2 is probably the most common, we infer it
		-- (as well as the fact that these adjectives *are* in a sense
		-- 3-2 since they have a distinct neuter in -(i)a. Note that
		-- we have two entries here; the first one will apply unless
		-- -I is given, and will infer an i-stem adjective; the second
		-- one will apply otherwise (and infer a non-i-stem 3-1 adjective).
		{"ēs", "3-2", {"pl", "I"}},
		{"ēs", "3-1", {"pl", "par"}, base_as_stem2},
		-- Same for neuters.
		{"ia", "3-2", {"pl", "I"}},
		{"a", "3-1", {"pl", "par"}, base_as_stem2},
		-- As above for -ēs but for miscellaneous singulars.
		{"", "3-1", {"I"}},
		{"", "3-1", {"par"}},
	}

	if typ == "" then
		local base, new_stem2, rettype, new_subtypes =
			get_adj_type_and_subtype_by_ending(lemma, stem2, nil, subtypes,
				decl12_entries, decl12_stem2)
		if base then
			return base, new_stem2, rettype, new_subtypes
		else
			return get_adj_type_and_subtype_by_ending(lemma, stem2, typ,
				subtypes, decl3_entries, decl3_stem2)
		end
	elseif typ == "0" then
		return lemma, nil, "0", {}
	elseif typ == "3" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes,
			decl3_entries, decl3_stem2)
	elseif typ == "1&2" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes,
			decl12_entries, decl12_stem2)
	elseif typ == "1-1" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"a", "1-1", {}},
			{"ae", "1-1", {"pl"}},
		})
	elseif typ == "2-2" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"us", "2-2", {}},
			{"um", "2-2", {}},
			{"ī", "2-2", {"pl"}},
			{"a", "2-2", {"pl"}},
			{"os", "2-2", {"greek"}},
			{"on", "2-2", {"greek"}},
			{"oe", "2-2", {"greek", "pl"}},
		})
	elseif typ == "3-1" then
		-- This will cancel out the I if -I is specified in subtypes, and the
		-- resulting lack of I will get converted to "par".
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			-- Detect -ēs as 3-1 without auto-inferring .pl if .pl
			-- not specified. If we don't do this, the later entry for
			-- -ēs will auto-infer .pl whenever -ēs is specified.
			-- Essentially, for declension-3 adjectives, we require that
			-- .pl is given if the lemma is plural.
			-- We have two entries here; the first one will apply unless
			-- -I is given, and will infer an i-stem adjective; the second
			-- one will apply otherwise.
			{"^(.*ēs)$", "3-1", {"I"}},
			{"^(.*ēs)$", "3-1", {"par"}},
			{"ēs", "3-1", {"pl", "I"}, base_as_stem2},
			{"ēs", "3-1", {"pl", "par"}, base_as_stem2},
			{"ia", "3-1", {"pl", "I"}, base_as_stem2},
			{"a", "3-1", {"pl", "par"}, base_as_stem2},
			{"", "3-1", {"I"}},
			{"", "3-1", {"par"}},
		}, decl3_stem2)
	elseif typ == "3-2" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"is", "3-2", {}},
			{"e", "3-2", {}},
			-- Detect -ēs as 3-2 without auto-inferring .pl if .pl
			-- not specified. If we don't do this, the later entry for
			-- -ēs will auto-infer .pl whenever -ēs is specified (which
			-- won't work for adjectives like isoscelēs). Essentially,
			-- for declension-3 adjectives, we require that .pl is given
			-- if the lemma is plural.
			{"ēs", "3-2", {}},
			{"ēs", "3-2", {"pl"}},
			{"ia", "3-2", {"pl"}},
		}, decl3_stem2)
	elseif typ == "3-C" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"^(.*[ij])or$", "3-C", {}},
			{"^(min)or$", "3-C", {}},
			{"^(.*[ij])ōrēs$", "3-C", {"pl"}},
			{"^(min)ōrēs$", "3-C", {"pl"}},
		}, decl3_stem2)
	elseif typ == "irreg" then
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"^(duo)$", typ, {"pl"}},
			{"^(ambō)$", typ, {"pl"}},
			{"^(mīll?ia)$", typ, {"N", "pl"}, constant_base("mīlle")},
			-- match ea
			{"^(ea)$", typ, {}, constant_base("is")},
			-- match id
			{"^(id)$", typ, {}, constant_base("is")},
			-- match plural eī, iī
			{"^([ei]ī)$", typ, {"pl"}, constant_base("is")},
			-- match plural ea, eae
			{"^(eae?)$", typ, {"pl"}, constant_base("is")},
			-- match eadem
			{"^(eadem)$", typ, {}, constant_base("īdem")},
			-- match īdem, idem
			{"^([īi]dem)$", typ, {}, constant_base("īdem")},
			-- match plural īdem
			{"^(īdem)$", typ, {"pl"}},
			-- match plural eadem, eaedem
			{"^(eae?dem)$", typ, {"pl"}, constant_base("īdem")},
			-- match illa, ipsa, ista; it doesn't matter if we overmatch because
			-- we'll get an error as we use the stem itself in the returned base
			{"^(i[lps][lst])a$", typ, {}, function(base, stem2) return base .. "e", nil end},
			-- match illud, istud; as above, it doesn't matter if we overmatch
			{"^(i[ls][lt])ud$", typ, {}, function(base, stem2) return base .. "e", nil end},
			-- match ipsum
			{"^(ipsum)$", typ, {}, constant_base("ipse")},
			-- match plural illī, ipsī, istī; as above, it doesn't matter if we
			-- overmatch
			{"^(i[lps][lst])ī$", typ, {"pl"}, function(base, stem2) return base .. "e", nil end},
			-- match plural illa, illae, ipsa, ipsae, ista, istae; as above, it
			-- doesn't matter if we overmatch
			{"^(i[lps][lst])ae?$", typ, {"pl"}, function(base, stem2) return base .. "e", nil end},
			-- Detect quī as non-plural unless .pl specified.
			{"^(quī)$", typ, {}},
			-- Otherwise detect quī as plural.
			{"^(quī)$", typ, {"pl"}},
			-- Same for quae.
			{"^(quae)$", typ, {}, constant_base("quī")},
			{"^(quae)$", typ, {"pl"}, constant_base("quī")},
			{"^(quid)$", typ, {}, constant_base("quis")},
			{"^(quod)$", typ, {}, constant_base("quī")},
			{"^(qui[cd]quid)$", typ, {}, constant_base("quisquis")},
			{"^(quīquī)$", typ, {"pl"}, constant_base("quisquis")},
			{"^(quaequae)$", typ, {"pl"}, constant_base("quisquis")},
			-- match all remaining lemmas in lemma form
			{"", typ, {}},
		})
	else -- 3-3 or 3-P
		return get_adj_type_and_subtype_by_ending(lemma, stem2, typ, subtypes, {
			{"ēs", typ, {"pl"}, base_as_stem2},
			{"ia", typ, {"pl"}, base_as_stem2},
			{"", typ, {}},
		}, decl3_stem2)
	end
end

-- Parse a segment (e.g. "lūna<1>", "aegis/aegid<3.Greek>", "bōs<irreg.F>",
-- bonus<+>", or "[[vetus]]/veter<3+.-I>"), consisting of a lemma (or optionally
-- a lemma/stem) and declension+subtypes, where a + in the declension indicates
-- an adjective. Brackets can be present to indicate links, for use in
-- {{la-noun}} and {{la-adj}}. The return value is a table, e.g.:
-- {
--   decl = "1",
--   headword_decl = "1",
--   is_adj = false,
--   orig_lemma = "lūna",
--   lemma = "lūna",
--   stem2 = nil,
--   gender = "F",
--   types = {["F"] = true},
--   args = {"lūn"}
-- }
--
-- or
--
-- {
--   decl = "3",
--   headword_decl = "3",
--   is_adj = false,
--   orig_lemma = "aegis",
--   lemma = "aegis",
--   stem2 = "aegid",
--   gender = nil,
--   types = {["Greek"] = true},
--   args = {"aegis", "aegid"}
-- }
--
-- or
--
-- {
--   decl = "irreg",
--   headword_decl = "irreg/3",
--   is_adj = false,
--   orig_lemma = "bōs",
--   lemma = "bōs",
--   stem2 = nil,
--   gender = "F",
--   types = {["F"] = true},
--   args = {"bōs"}
-- }
-- or
--
-- {
--   decl = "1&2",
--   headword_decl = "1&2+",
--   is_adj = true,
--   orig_lemma = "bonus",
--   lemma = "bonus",
--   stem2 = nil,
--   gender = nil,
--   types = {},
--   args = {"bon"}
-- }
--
-- or
--
-- {
--   decl = "3-1",
--   headword_decl = "3-1+",
--   is_adj = true,
--   orig_lemma = "[[vetus]]",
--   lemma = "vetus",
--   stem2 = "veter",
--   gender = nil,
--   types = {},
--   args = {"vetus", "veter"}
-- }
local function parse_segment(segment)
	local stem_part, spec_part = rmatch(segment, "^(.*)<(.-)>$")
	local stems = rsplit(stem_part, "/", true)
	local specs = rsplit(spec_part, ".", true)

	local types = {}
	local num = nil
	local loc = false

	local args = {}

	local decl
	for j, spec in ipairs(specs) do
		if j == 1 then
			decl = spec
		else
			local begins_with_hyphen
			begins_with_hyphen, spec = rmatch(spec, "^(%-?)(.-)$")
			spec = begins_with_hyphen .. spec:gsub("%-", "_")
			types[spec] = true
		end
	end

	local orig_lemma = stems[1]
	if not orig_lemma or orig_lemma == "" then
		orig_lemma = current_title.subpageText
	end
	local lemma = m_links.remove_links(orig_lemma)
	local stem2 = stems[2]
	if stem2 == "" then
		stem2 = nil
	end
	if #stems > 2 then
		error("Too many stems, at most 2 should be given: " .. stem_part)
	end

	local base, detected_subtypes
	local is_adj = false
	local gender = nil

	if rfind(decl, "%+") then
		decl = decl:gsub("%+", "")
		base, stem2, decl, detected_subtypes = detect_adj_type_and_subtype(
			lemma, stem2, decl, types
		)
		is_adj = true

		headword_decl = irreg_adj_to_decl[lemma] and "irreg/" .. irreg_adj_to_decl[lemma] or decl .. "+"

		for _, subtype in ipairs(detected_subtypes) do
			if types["-" .. subtype] then
				-- if a "cancel subtype" spec is given, remove the cancel spec
				-- and don't apply the subtype
				types["-" .. subtype] = nil
			else
				types[subtype] = true
			end
		end
	else
		base, stem2, detected_subtypes = detect_noun_subtype(lemma, stem2, decl, types)

		headword_decl = irreg_noun_to_decl[lemma] and "irreg/" .. irreg_noun_to_decl[lemma] or decl

		for _, subtype in ipairs(detected_subtypes) do
			if types["-" .. subtype] then
				-- if a "cancel subtype" spec is given, remove the cancel spec
				-- and don't apply the subtype
				types["-" .. subtype] = nil
			elseif (subtype == "M" or subtype == "F" or subtype == "N") and
					(types.M or types.F or types.N) then
				-- if gender already specified, don't create conflicting gender spec
			elseif (subtype == "sg" or subtype == "pl" or subtype == "both") and
					(types.sg or types.pl or types.both) then
				-- if number restriction already specified, don't create conflicting
				-- number restriction spec
			else
				types[subtype] = true
			end
		end

		if not types.pl and not types.both and rfind(lemma, "^[A-ZĀĒĪŌŪȲĂĔĬŎŬ]") then
			types.sg = true
		end
	end

	if types.loc then
		loc = true
		types.loc = nil
	end

	if types.M then
		gender = "M"
	elseif types.F then
		gender = "F"
	elseif types.N then
		gender = "N"
	end

	if types.pl then
		num = "pl"
		types.pl = nil
	elseif types.sg then
		num = "sg"
		types.sg = nil
	end

	args[1] = base
	args[2] = stem2

	return {
		decl = decl,
		headword_decl = headword_decl,
		is_adj = is_adj,
		gender = gender,
		orig_lemma = orig_lemma,
		lemma = lemma,
		stem2 = stem2,
		types = types,
		num = num,
		loc = loc,
		args = args,
	}
end

-- Parse a segment run (i.e. a string with zero or more segments [see
-- parse_segment] and optional surrounding text, e.g. "foenum<2>-graecum<2>"
-- or "[[pars]]/part<3.abl-e-occ-i> [[oratio|ōrātiōnis]]"). The segment run
-- currently cannot contain any alternants (e.g. "((epulum<2.sg>,epulae<1>))").
-- The return value is a table of the following form:
-- {
--   segments = PARSED_SEGMENTS (a list of parsed segments),
--   loc = LOC (a boolean indicating whether any of the individual segments
--     has a locative),
--   num = NUM (the first specified value for a number restriction, or nil if
--     no number restrictions),
--   gender = GENDER (the first specified or inferred gender, or nil if none),
--   is_adj = IS_ADJ (true if all segments are adjective segments, false if
--     there's at least one noun segment, nil if only raw-text segments),
--   propses = PROPSES (list of per-word properties, where each element is an
--     object {
--       decl = DECL (declension),
--       headword_decl = HEADWORD_DECL (declension to be displayed in headword),
--       types = TYPES (set describing the subtypes of a given word),
--     }
-- }
-- Each element in PARSED_SEGMENTS is as returned by parse_segment() but will
-- have an additional .orig_prefix field indicating the text before the segment
-- (including bracketed links) and corresponding .prefix field indicating the text
-- with bracketed links resolved. If there is trailing text, the last element will
-- have only .orig_prefix and .prefix fields containing that trailing text.
local function parse_segment_run(segment_run)
	local loc = nil
	local num = nil
	local is_adj = nil
	-- If the segment run begins with a hyphen, include the hyphen in the
	-- set of allowed characters for a declined segment. This way, e.g. the
	-- suffix [[-cen]] can be declared as {{la-ndecl|-cen/-cin<3>}} rather than
	-- {{la-ndecl|-cen/cin<3>}}, which is less intuitive.
	local is_suffix = rfind(segment_run, "^%-")
	local segments = {}
	local propses = {}
	-- We want to not break up a bracketed link followed by <> even if it has a space or
	-- hyphen in it. So we do an outer capturing split to find the bracketed links followed
	-- by <>, then do inner capturing splits on all the remaining text to find the other
	-- declined terms.
	local bracketed_segments = m_string_utilities.capturing_split(segment_run, "(%[%[[^%[%]]-%]%]<.->)")
	for i, bracketed_segment in ipairs(bracketed_segments) do
		if i % 2 == 0 then
			table.insert(segments, bracketed_segment)
		else
			for _, subsegment in ipairs(m_string_utilities.capturing_split(
				bracketed_segment, is_suffix and "([^<> ,]+<.->)" or "([^<> ,%-]+<.->)"
			)) do
				table.insert(segments, subsegment)
			end
		end
	end
	local parsed_segments = {}
	local gender = nil
	for i = 2, (#segments - 1), 2 do
		local parsed_segment = parse_segment(segments[i])
		-- Overall locative is true if any segments call for locative.
		loc = loc or parsed_segment.loc
		-- The first specified value for num is used becomes the overall value.
		num = num or parsed_segment.num
		if is_adj == nil then
			is_adj = parsed_segment.is_adj
		else
			is_adj = is_adj and parsed_segment.is_adj
		end
		gender = gender or parsed_segment.gender
		parsed_segment.orig_prefix = segments[i - 1]
		parsed_segment.prefix = m_links.remove_links(segments[i - 1])
		table.insert(parsed_segments, parsed_segment)
		local props = {
			decl = parsed_segment.decl,
			headword_decl = parsed_segment.headword_decl,
			types = parsed_segment.types,
		}
		table.insert(propses, props)
	end
	if segments[#segments] ~= "" then
		table.insert(parsed_segments, {
			orig_prefix = segments[#segments],
			prefix = m_links.remove_links(segments[#segments]),
		})
	end
	return {
		segments = parsed_segments,
		loc = loc,
		num = num,
		is_adj = is_adj,
		gender = gender,
		propses = propses,
	}
end

-- Parse an alternant, e.g. "((epulum<2.sg>,epulae<1>))",
-- "((Serapis<3>,Serapis/Serapid<3>))" or
-- "((rēs<5>pūblica<1>,rēspūblica<1>))". The return value is a table of the form
-- {
--   alternants = PARSED_ALTERNANTS (a list of segment runs, each of which is a
--     list of parsed segments as returned by parse_segment_run()),
--   loc = LOC (a boolean indicating whether any of the individual segment runs
--     has a locative),
--   num = NUM (the overall number restriction, one of "sg", "pl" or "both"),
--   gender = GENDER (the first specified or inferred gender, or nil if none),
--   is_adj = IS_ADJ (true if all non-constant alternants are adjectives, false
--     if all nouns, nil if only constant alternants; conflicting alternants
--     cause an error),
--   propses = PROPSES (list of lists of per-word property objecs),
-- }
local function parse_alternant(alternant)
	local parsed_alternants = {}
	local alternant_spec = rmatch(alternant, "^%(%((.*)%)%)$")
	local alternants = rsplit(alternant_spec, ",")
	local loc = false
	local num = nil
	local gender = nil
	local is_adj = nil
	local propses = {}
	for i, alternant in ipairs(alternants) do
		local parsed_run = parse_segment_run(alternant)
		table.insert(parsed_alternants, parsed_run)
		loc = loc or parsed_run.loc
		-- First time through, set the overall num to the num of the first run,
		-- even if nil. After that, if we ever see a run with a different value
		-- of num, set the overall num to "both". That way, if all alternants
		-- don't specify a num, we get an unspecified num, but if some do and
		-- some don't, we get both, because an unspecified num defaults to
		-- both.
		if i == 1 then
			num = parsed_run.num
		elseif num ~= parsed_run.num then
			-- FIXME, this needs to be rethought to allow for
			-- adjective alternants.
			num = "both"
		end
		gender = gender or parsed_run.gender
		if is_adj == nil then
			is_adj = parsed_run.is_adj
		elseif parsed_run.is_adj ~= nil and parsed_run.is_adj ~= is_adj then
			error("Saw both noun and adjective alternants; not allowed")
		end
		table.insert(propses, parsed_run.propses)
	end
	return {
		alternants = parsed_alternants,
		loc = loc,
		num = num,
		gender = gender,
		is_adj = is_adj,
		propses = propses,
	}
end

-- Parse a segment run (see parse_segment_run()). Unlike for
-- parse_segment_run(), this can contain alternants such as
-- "((epulum<2.sg>,epulae<1>))" or "((Serapis<3.sg>,Serapis/Serapid<3.sg>))"
-- embedded in it to indicate words composed of multiple declensions.
-- The return value is a table of the following form:
-- {
--   segments = PARSED_SEGMENTS (a list of parsed segments),
--   loc = LOC (a boolean indicating whether any of the individual segments has
--     a locative),
--   num = NUM (the first specified value for a number restriction, or nil if
--     no number restrictions),
--   gender = GENDER (the first specified or inferred gender, or nil if none),
--   is_adj = IS_ADJ (true if all segments are adjective segments, false if
--     there's at least one noun segment, nil if only raw-text segments),
--   propses = PROPSES (list of either per-word property objects or lists of
--		lists of such objects),
-- }.
-- Each element in PARSED_SEGMENTS is one of three types:
--
-- 1. A regular segment, as returned by parse_segment() but with additional
--    .prefix and .orig_prefix fields indicating the text before the segment, as per
--    the return value of parse_segment_run().
-- 2. A raw-text segment, i.e. a table with only .prefix and .orig_prefix fields
--    containing the raw text.
-- 3. An alternating segment, as returned by parse_alternant().
-- Note that each alternant is a segment run rather than a single parsed
-- segment to allow for alternants like "((rēs<5>pūblica<1>,rēspūblica<1>))".
-- The parsed segment runs in PARSED_SEGMENT_RUNS are tables as returned by
-- parse_segment_run() (of the same form as the overall return value of
-- parse_segment_run_allowing_alternants()).
local function parse_segment_run_allowing_alternants(segment_run)
	if rfind(segment_run, " ") then
		track("has-space")
	end
	if rfind(segment_run, "%(%(") then
		track("has-alternant")
	end
	local alternating_segments = m_string_utilities.capturing_split(segment_run, "(%(%(.-%)%))")
	local parsed_segments = {} 
	local loc = false
	local num = nil
	local gender = nil
	local is_adj = nil
	local propses = {}
	for i = 1, #alternating_segments do
		local alternating_segment = alternating_segments[i]
		if alternating_segment ~= "" then
			local this_is_adj
			if i % 2 == 1 then
				local parsed_run = parse_segment_run(alternating_segment)
				for _, parsed_segment in ipairs(parsed_run.segments) do
					table.insert(parsed_segments, parsed_segment)
				end
				loc = loc or parsed_run.loc
				num = num or parsed_run.num
				gender = gender or parsed_run.gender
				this_is_adj = parsed_run.is_adj
				for _, props in ipairs(parsed_run.propses) do
					table.insert(propses, props)
				end
			else
				local parsed_alternating_segment = parse_alternant(alternating_segment)
				table.insert(parsed_segments, parsed_alternating_segment)
				loc = loc or parsed_alternating_segment.loc
				num = num or parsed_alternating_segment.num
				gender = gender or parsed_alternating_segment.gender
				this_is_adj = parsed_alternating_segment.is_adj
				table.insert(propses, parsed_alternating_segment.propses)
			end
			if is_adj == nil then
				is_adj = this_is_adj
			elseif this_is_adj ~= nil then
				is_adj = is_adj and this_is_adj
			end
		end
	end

	if #parsed_segments > 1 then
		track("multiple-segments")
	end
	
	return {
		segments = parsed_segments,
		loc = loc,
		num = num,
		gender = gender,
		is_adj = is_adj,
		propses = propses,
	}
end

-- Combine each form in FORMS (a list of forms associated with a slot) with each
-- form in NEW_FORMS (either a single string for a single form, or a list of
-- forms) by concatenating EXISTING_FORM .. PREFIX .. NEW_FORM. Also combine
-- NOTES (a table specifying the footnotes associated with each existing form,
-- i.e. a map from form indices to lists of footnotes) with NEW_NOTES (new
-- footnotes associated with the new forms, in the same format as NOTES). Return
-- a pair NEW_FORMS, NEW_NOTES where either or both of FORMS and NOTES (but not
-- the sublists in NOTES) may be destructively modified to generate the return
-- values.
local function append_form(forms, notes, new_forms, new_notes, prefix)
	new_forms = new_forms or ""
	notes = notes or {}
	new_notes = new_notes or {}
	prefix = prefix or ""
	if type(new_forms) == "table" and #new_forms == 1 then
		new_forms = new_forms[1]
	end
	if type(new_forms) == "string" then
		-- If there's only one new form, destructively modify the existing
		-- forms and notes for this new form and its footnotes.
		for i = 1, #forms do
			forms[i] = forms[i] .. prefix .. new_forms
			if new_notes[1] then
				if not notes[i] then
					notes[i] = new_notes[1]
				else
					local combined_notes = m_table.deepcopy(notes[i])
					for _, note in ipairs(new_notes[1]) do
						table.insert(combined_notes, note)
					end
					notes[i] = combined_notes
				end
			end
		end
		return forms, notes
	else
		-- If there are multiple new forms, we need to loop over all
		-- combinations of new and old forms. In that case, use new tables
		-- for the combined forms and notes.
		local ret_forms = {}
		local ret_notes = {}
		for i=1, #forms do
			for j=1, #new_forms do
				table.insert(ret_forms, forms[i] .. prefix .. new_forms[j])
				if new_notes[j] then
					if not notes[i] then
						-- We are constructing a linearized matrix of size
						-- NI x NJ where J is in the inner loop. If I and J
						-- are zero-based, the linear index of (I, J) is
						-- I * NJ + J. However, we are one-based, so the
						-- same formula won't work. Instead, we effectively
						-- need to convert to zero-based indices, compute
						-- the zero-based linear index, and then convert it
						-- back to a one-based index, i.e.
						--
						-- (I - 1) * NJ + (J - 1) + 1
						--
						-- i.e. (I - 1) * NJ + J.
						ret_notes[(i - 1) * #new_forms + j] = new_notes[j]
					else
						local combined_notes = m_table.deepcopy(notes[i])
						for _, note in ipairs(new_notes[j]) do
							table.insert(combined_notes, note)
						end
						ret_notes[(i - 1) * #new_forms + j] = combined_notes
					end
				end
			end
		end
		return ret_forms, ret_notes
	end
end

-- Destructively modify any forms in FORMS (a map from a slot to a form or a
-- list of forms) by converting sequences of ae, oe, Ae or Oe to the
-- appropriate ligatures.
local function apply_ligatures(forms, is_adj)
	for slot in iter_slots(is_adj) do
		if type(forms[slot]) == "string" then
			forms[slot] = forms[slot]:gsub("[AaOo]e", ligatures)
		elseif type(forms[slot]) == "table" then
			for i = 1, #forms[slot] do
				forms[slot][i] = forms[slot][i]:gsub("[AaOo]e", ligatures)
			end
		end
	end
end

-- Modify any forms in FORMS (a map from a slot to a form or a list of forms) by
-- converting final m to optional n or m.
local function apply_sufn(forms, is_adj)
	for slot in iter_slots(is_adj) do
		if type(forms[slot]) == "string" then
			if forms[slot]:find("m$") then
				forms[slot] = {forms[slot]:gsub("m$", "n"), forms[slot]}
			end
		elseif type(forms[slot]) == "table" then
			-- See if any final m's.
			local final_m
			for i = 1, #forms[slot] do
				if forms[slot][i]:find("m$") then
					final_m = true
					break
				end
			end
			if final_m then
				local newval = {}
				for i = 1, #forms[slot] do
					if forms[slot][i]:find("m$") then
						local val = forms[slot][i]:gsub("m$", "n") -- discard second retval
						table.insert(newval, val)
					end
					table.insert(newval, forms[slot][i])
				end
			end
		end
	end
end

-- If NUM == "sg", copy the singular forms to the plural ones; vice-versa if
-- NUM == "pl". This should allow for the equivalent of plural
-- "alpha and omega" formed from two singular nouns, and for the equivalent of
-- plural "St. Vincent and the Grenadines" formed from a singular noun and a
-- plural noun. (These two examples actually occur in Russian, at least.)
local function propagate_number_restrictions(forms, num, is_adj)
	if num == "sg" or num == "pl" then
		for slot in iter_slots(is_adj) do
			if rfind(slot, num) then
				local other_num_slot = num == "sg" and slot:gsub("sg", "pl") or slot:gsub("pl", "sg")
				forms[other_num_slot] = type(forms[slot]) == "table" and m_table.deepcopy(forms[slot]) or forms[slot]
			end
		end
	end
end

local function join_sentences(sentences, joiner)
	-- Lowercase the first letter of all but the first sentence, and remove the
	-- final period from all but the last sentence. Then join together with the
	-- joiner (e.g. " and " or " or ").
	-- FIXME: Should we join three or more as e.g. "foo, bar and baz"?
	local sentences_to_join = {}
	for i, sentence in ipairs(sentences) do
		if i < #sentences then
			sentence = rsub(sentence, "%.$", "")
		end
		if i > 1 then
			sentence = m_string_utilities.lcfirst(sentence)
		end
		table.insert(sentences_to_join, sentence)
	end
	return table.concat(sentences_to_join, joiner)
end

-- Construct the declension of a parsed segment run of the form returned by
-- parse_segment_run() or parse_segment_run_allowing_alternants(). Return value
-- is a table
-- {
--   forms = FORMS (keyed by slot, list of forms for that slot),
--   notes = NOTES (keyed by slot, map from form indices to lists of footnotes),
--   title = TITLE (list of titles for each segment in the run),
--   categories = CATEGORIES (combined categories for all segments),
--   voc = BOOLEAN (false if any adjective in the run has no vocative),
-- }
local function decline_segment_run(parsed_run, pos, is_adj)
	local declensions = {
		-- For each possible slot (e.g. "abl_sg"), list of possible forms.
		forms = {},
		-- Keyed by slot (e.g. "abl_sg"). Value is a table indicating the footnotes
		-- corresponding to the forms for that slot. Each such table maps indices
		-- (the index of the corresponding form) to a list of one or more
		-- footnotes.
		notes = {},
		title = {},
		subtitleses = {},
		orig_titles = {},
		categories = {},
		footnotes = {},
		-- FIXME, do we really need to special-case this? Maybe the nonexistent vocative
		-- form will automatically propagate up through the other forms.
		voc = true,
		-- May be set true if declining a 1-1 adjective
		loc = false,
		noneut = false,
		nomf = false,
	}

	for slot in iter_slots(is_adj) do
		declensions.forms[slot] = {""}
	end

	for _, seg in ipairs(parsed_run.segments) do
		if seg.decl then -- not an alternant, not a constant segment
			seg.loc = parsed_run.loc
			seg.num = seg.num or parsed_run.num
			seg.gender = seg.gender or parsed_run.gender

			local data

			local potential_lemma_slots

			if seg.is_adj then
				if not m_adj_decl[seg.decl] then
					error("Unrecognized declension '" .. seg.decl .. "'")
				end

				potential_lemma_slots = potential_adj_lemma_slots

				data = {
					subtitles = {},
					num = seg.num or "",
					gender = seg.gender,
					voc = true,
					loc = seg.loc,
					noneut = false,
					nomf = false,
					pos = is_adj and pos or "adjectives",
					forms = {},
					types = seg.types,
					categories = {},
					notes = {},
				}
				m_adj_decl[seg.decl](data, seg.args)
				if not data.voc then
					declensions.voc = false
				end
				if data.loc then
					declensions.loc = true
				end
				if data.noneut then
					declensions.noneut = true
				end
				if data.nomf then
					declensions.nomf = true
				end
				-- Construct title out of "original title" and subtitles.
				if data.types.sufn then
					table.insert(data.subtitles, {"with", " ''m'' optionally → ''n'' in compounds"})
				elseif data.types.not_sufn then
					table.insert(data.subtitles, {"without", " ''m'' optionally → ''n'' in compounds"})
				end
				-- Record original title and subtitles for use in alternant title-constructing code.
				table.insert(declensions.orig_titles, data.title)
				if #data.subtitles > 0 then
					local subtitles = {}
					for _, subtitle in ipairs(data.subtitles) do
						if type(subtitle) == "table" then
							-- Occurs e.g. with ''idem'', ''quīdam''
							table.insert(subtitles, table.concat(subtitle))
						else
							table.insert(subtitles, subtitle)
						end
					end
					data.title = data.title .. " (" .. table.concat(subtitles, ", ") .. ")"
				end
				table.insert(declensions.subtitleses, data.subtitles)
			else
				if not m_noun_decl[seg.decl] then
					error("Unrecognized declension '" .. seg.decl .. "'")
				end

				potential_lemma_slots = potential_noun_lemma_slots

				data = {
					subtitles = {},
					num = seg.num or "",
					loc = seg.loc,
					pos = pos,
					forms = {},
					types = seg.types,
					categories = {},
					notes = {},
				}

				m_noun_decl[seg.decl](data, seg.args)

				-- Construct title out of "original title" and subtitles.
				if not data.title then
					local apparent_decl = rmatch(seg.headword_decl, "^irreg/(.*)$")
					if apparent_decl then
						if #data.subtitles == 0 then
							table.insert(data.subtitles, glossary_link("irregular"))
						end
					else
						apparent_decl = seg.headword_decl
					end
					if declension_to_english[apparent_decl] then
						local english = declension_to_english[apparent_decl]
						data.title = "[[Appendix:Latin " .. english .. " declension|" .. english .. "-declension]]"
					elseif apparent_decl == "irreg" then
						data.title = glossary_link("irregular")
					elseif apparent_decl == "indecl" or apparent_decl == "0" then
						data.title = glossary_link("indeclinable")
					else
						error("Internal error! Don't recognize noun declension " .. apparent_decl)
					end
					data.title = data.title .. " noun"
				end
				if data.types.sufn then
					table.insert(data.subtitles, {"with", " ''m'' optionally → ''n'' in compounds"})
				elseif data.types.not_sufn then
					table.insert(data.subtitles, {"without", " ''m'' optionally → ''n'' in compounds"})
				end
				-- Record original title and subtitles for use in alternant title-constructing code.
				table.insert(declensions.orig_titles, data.title)
				if #data.subtitles > 0 then
					local subtitles = {}
					for _, subtitle in ipairs(data.subtitles) do
						if type(subtitle) == "table" then
							-- Occurs e.g. with 1st-declension ''-ābus'' ending where
							-- we want a common prefix to be extracted out if possible
							-- in the alternant title-generating code.
							table.insert(subtitles, table.concat(subtitle))
						else
							table.insert(subtitles, subtitle)
						end
					end
					data.title = data.title .. " (" .. table.concat(subtitles, ", ") .. ")"
				end
				table.insert(declensions.subtitleses, data.subtitles)
			end

			-- Generate linked variants of slots that may be the lemma.
			-- If the form is the same as the lemma (with links removed),
			-- substitute the original lemma (with links included).
			for _, slot in ipairs(potential_lemma_slots) do
				local forms = data.forms[slot]
				if forms then
					local linked_forms = {}
					if type(forms) ~= "table" then
						forms = {forms}
					end
					for _, form in ipairs(forms) do
						if form == seg.lemma then
							table.insert(linked_forms, seg.orig_lemma)
						else
							table.insert(linked_forms, form)
						end
					end
					data.forms["linked_" .. slot] = linked_forms
				end
			end

			if seg.types.lig then
				apply_ligatures(data.forms, is_adj)
			end

			if seg.types.sufn then
				apply_sufn(data.forms, is_adj)
			end

			propagate_number_restrictions(data.forms, seg.num, is_adj)

			for slot in iter_slots(is_adj) do
				-- 1. Select the forms to append to the existing ones.

				local new_forms
				if is_adj then
					if not seg.is_adj then
						error("Can't decline noun '" .. seg.lemma .. "' when overall term is an adjective")
					end
					new_forms = data.forms[slot]
					if not new_forms and slot:find("_[fn]$") then
						new_forms = data.forms[slot:gsub("_[fn]$", "_m")]
					end
				elseif seg.is_adj then
					if not seg.gender then
						error("Declining modifying adjective " .. seg.lemma .. " but don't know gender of associated noun")
					end
					-- Select the appropriately gendered equivalent of the case/number
					-- combination. Some adjectives won't have feminine or neuter
					-- variants, though (e.g. 3-1 and 3-2 adjectives don't have a
					-- distinct feminine), so in that case select the masculine.
					new_forms = data.forms[slot .. "_" .. mw.ustring.lower(seg.gender)]
						or data.forms[slot .. "_m"]
				else
					new_forms = data.forms[slot]
				end

				-- 2. Extract the new footnotes in the format we require, which is
				-- different from the format passed in by the declension functions.

				local new_notes = {}

				if type(new_forms) == "string" and data.notes[slot .. "1"] then
					new_notes[1] = {data.notes[slot .. "1"]}
				elseif new_forms then
					for j = 1, #new_forms do
						if data.notes[slot .. j] then
							new_notes[j] = {data.notes[slot .. j]}
						end
					end
				end

				-- 3. Append new forms and footnotes to the existing ones.

				declensions.forms[slot], declensions.notes[slot] = append_form(
					declensions.forms[slot], declensions.notes[slot], new_forms,
					new_notes, slot:find("linked") and seg.orig_prefix or seg.prefix)
			end

			if not seg.types.nocat and (is_adj or not seg.is_adj) then
				for _, cat in ipairs(data.categories) do
					m_table.insertIfNot(declensions.categories, cat)
				end
			end

			if data.footnote then
				table.insert(declensions.footnotes, data.footnote)
			end

			if seg.prefix ~= "" and seg.prefix ~= "-" and seg.prefix ~= " " then
				table.insert(declensions.title, glossary_link("indeclinable") .. " portion")
			end
			table.insert(declensions.title, data.title)
		elseif seg.alternants then
			local seg_declensions = nil
			local seg_titles = {}
			local seg_subtitleses = {}
			local seg_stems_seen = {}
			local seg_categories = {}
			local seg_footnotes = {}
			-- If all alternants have exactly one non-constant segment and all are
			-- of the same declension, we use special code that displays the
			-- differences in the subtitles. Otherwise we use more general code
			-- that displays the full title and subtitles of each segment,
			-- separating segment combined titles by "and" and the segment-run
			-- combined titles by "or".
			local title_the_hard_way = false
			local alternant_decl = nil
			local alternant_decl_title = nil
			for _, this_parsed_run in ipairs(seg.alternants) do
				local num_non_constant_segments = 0
				for _, segment in ipairs(this_parsed_run.segments) do
					if segment.decl then
						if not alternant_decl then
							alternant_decl = segment.decl
						elseif alternant_decl ~= segment.decl then
							title_the_hard_way = true
							num_non_constant_segments = 500
							break
						end
						num_non_constant_segments = num_non_constant_segments + 1
					end
				end
				if num_non_constant_segments ~= 1 then
					title_the_hard_way = true
					break
				end
			end
			if not title_the_hard_way then
				-- If using the special-purpose code, find the subtypes that are
				-- not present in a given alternant but are present in at least
				-- one other, and record "negative" variants of these subtypes
				-- so that the declension-construction code can record subtitles
				-- for these negative variants (so we can construct text like
				-- "i-stem or imparisyllabic non-i-stem").
				local subtypeses = {}
				for _, this_parsed_run in ipairs(seg.alternants) do
					for _, segment in ipairs(this_parsed_run.segments) do
						if segment.decl then
							table.insert(subtypeses, segment.types)
							m_table.insertIfNot(seg_stems_seen, segment.stem2)
						end
					end
				end
				local union = set_union(subtypeses)
				for _, this_parsed_run in ipairs(seg.alternants) do
					for _, segment in ipairs(this_parsed_run.segments) do
						if segment.decl then
							local neg_subtypes = set_difference(union, segment.types)
							for neg_subtype, _ in pairs(neg_subtypes) do
								segment.types["not_" .. neg_subtype] = true
							end
						end
					end
				end
			end

			for _, this_parsed_run in ipairs(seg.alternants) do
				this_parsed_run.loc = seg.loc
				this_parsed_run.num = this_parsed_run.num or seg.num
				this_parsed_run.gender = this_parsed_run.gender or seg.gender
				local this_declensions = decline_segment_run(this_parsed_run, pos, is_adj)
				if not this_declensions.voc then
					declensions.voc = false
				end
				if this_declensions.noneut then
					declensions.noneut = true
				end
				if this_declensions.nomf then
					declensions.nomf = true
				end
				-- If there's a number restriction on the segment run, blank
				-- out the forms outside the restriction. This allows us to
				-- e.g. construct heteroclites that decline one way in the
				-- singular and a different way in the plural.
				if this_parsed_run.num == "sg" or this_parsed_run.num == "pl" then
					for slot in iter_slots(is_adj) do
						if this_parsed_run.num == "sg" and rfind(slot, "pl") or
							this_parsed_run.num == "pl" and rfind(slot, "sg") then
							this_declensions.forms[slot] = {}
							this_declensions.notes[slot] = nil
						end
					end
				end
				if not seg_declensions then
					seg_declensions = this_declensions
				else
					for slot in iter_slots(is_adj) do
						-- For a given slot, combine the existing and new forms.
						-- We do this by checking to see whether a new form is
						-- already present and not adding it if so; in the
						-- process, we keep a map from indices in the new forms
						-- to indices in the combined forms, for use in
						-- combining footnotes below.
						local curforms = seg_declensions.forms[slot] or {}
						local newforms = this_declensions.forms[slot] or {}
						local newform_index_to_new_index = {}
						for newj, form in ipairs(newforms) do
							local did_break = false
							for j = 1, #curforms do
								if curforms[j] == form then
									newform_index_to_new_index[newj] = j
									did_break = true
									break
								end
							end
							if not did_break then
								table.insert(curforms, form)
								newform_index_to_new_index[newj] = #curforms
							end
						end
						seg_declensions.forms[slot] = curforms
						-- Now combine the footnotes. Keep in mind that
						-- each form may have its own set of footnotes, and
						-- in some cases we didn't add a form from the new
						-- list of forms because it already occurred in the
						-- existing list of forms; in that case, we combine
						-- footnotes from the two sources.
						local curnotes = seg_declensions.notes[slot]
						local newnotes = this_declensions.notes[slot]
						if newnotes then
							if not curnotes then
								curnotes = {}
							end
							for index, notes in pairs(newnotes) do
								local combined_index = newform_index_to_new_index[index]
								if not curnotes[combined_index] then
									curnotes[combined_index] = notes
								else
									local combined = mw.clone(curnotes[combined_index])
									for _, note in ipairs(newnotes) do
										m_table.insertIfNot(combined, newnotes)
									end
									curnotes[combined_index] = combined
								end
							end
						end
					end
				end
				for _, cat in ipairs(this_declensions.categories) do
					m_table.insertIfNot(seg_categories, cat)
				end
				for _, footnote in ipairs(this_declensions.footnotes) do
					m_table.insertIfNot(seg_footnotes, footnote)
				end
				m_table.insertIfNot(seg_titles, this_declensions.title)
				for _, subtitles in ipairs(this_declensions.subtitleses) do
					table.insert(seg_subtitleses, subtitles)
				end
				if not alternant_decl_title then
					alternant_decl_title = this_declensions.orig_titles[1]
				end
			end

			-- If overall run is singular, copy singular to plural, and
			-- vice-versa. See propagate_number_restrictions() for rationale;
			-- also, this should eliminate cases of empty forms, which will
			-- cause the overall set of forms for that slot to be empty.
			propagate_number_restrictions(seg_declensions.forms, parsed_run.num,
				is_adj)

			for slot in iter_slots(is_adj) do
				declensions.forms[slot], declensions.notes[slot] = append_form(
					declensions.forms[slot], declensions.notes[slot],
					seg_declensions.forms[slot], seg_declensions.notes[slot], nil)
			end

			if is_adj or not seg.is_adj then
				for _, cat in ipairs(seg_categories) do
					m_table.insertIfNot(declensions.categories, cat)
				end
			end
			for _, footnote in ipairs(seg_footnotes) do
				m_table.insertIfNot(declensions.footnotes, footnote)
			end

			local title_to_insert
			if title_the_hard_way then
				title_to_insert = join_sentences(seg_titles, " or ")
			else
				-- Special-purpose title-generation code, for the common
				-- situation where each alternant has single-segment runs and
				-- all segments belong to the same declension.
				--
				-- 1. Find the initial subtitles common to all segments.
				local first_subtitles = seg_subtitleses[1]
				local num_common_subtitles = #first_subtitles
				for i = 2, #seg_subtitleses do
					local this_subtitles = seg_subtitleses[i]
					for j = 1, num_common_subtitles do
						if not m_table.deepEquals(first_subtitles[j], this_subtitles[j]) then
							num_common_subtitles = j - 1
							break
						end
					end
				end
				-- 2. Construct the portion of the text based on the common subtitles.
				local common_subtitles = {}
				for i = 1, num_common_subtitles do
					if type(first_subtitles[i]) == "table" then
						table.insert(common_subtitles, table.concat(first_subtitles[i]))
					else
						table.insert(common_subtitles, first_subtitles[i])
					end
				end
				local common_subtitle_portion = table.concat(common_subtitles, ", ")
				local non_common_subtitle_portion
				-- 3. Special-case the situation where there's one non-common
				--    subtitle in each segment and a common prefix or suffix to
				--    all of them.
				local common_prefix, common_suffix
				for i = 1, #seg_subtitleses do
					local this_subtitles = seg_subtitleses[i]
					if #this_subtitles ~= num_common_subtitles + 1 or
						type(this_subtitles[num_common_subtitles + 1]) ~= "table" or
						#this_subtitles[num_common_subtitles + 1] ~= 2 then
						break
					end
					if i == 1 then
						common_prefix = this_subtitles[num_common_subtitles + 1][1]
						common_suffix = this_subtitles[num_common_subtitles + 1][2]
					else
						local this_prefix = this_subtitles[num_common_subtitles + 1][1]
						local this_suffix = this_subtitles[num_common_subtitles + 1][2]
						if this_prefix ~= common_prefix then
							common_prefix = nil
						end
						if this_suffix ~= common_suffix then
							common_suffix = nil
						end
						if not common_prefix and not common_suffix then
							break
						end
					end
				end
				if common_prefix or common_suffix then
					if common_prefix and common_suffix then
						error("Something is wrong, first non-common subtitle is actually common to all segments")
					end
					if common_prefix then
						local non_common_parts = {}
						for i = 1, #seg_subtitleses do
							table.insert(non_common_parts, seg_subtitleses[i][num_common_subtitles + 1][2])
						end
						non_common_subtitle_portion = common_prefix .. table.concat(non_common_parts, " or ")
					else
						local non_common_parts = {}
						for i = 1, #seg_subtitleses do
							table.insert(non_common_parts, seg_subtitleses[i][num_common_subtitles + 1][1])
						end
						non_common_subtitle_portion = table.concat(non_common_parts, " or ") .. common_suffix
					end
				else
					-- 4. Join the subtitles that differ from segment to segment.
					--    Record whether there are any such differing subtitles.
					--    If some segments have differing subtitles and others don't,
					--    we use the text "otherwise" for the segments without
					--    differing subtitles.
					local saw_non_common_subtitles = false
					local non_common_subtitles = {}
					for i = 1, #seg_subtitleses do
						local this_subtitles = seg_subtitleses[i]
						local this_non_common_subtitles = {}
						for j = num_common_subtitles + 1, #this_subtitles do
							if type(this_subtitles[j]) == "table" then
								table.insert(this_non_common_subtitles, table.concat(this_subtitles[j]))
							else
								table.insert(this_non_common_subtitles, this_subtitles[j])
							end
						end
						if #this_non_common_subtitles > 0 then
							table.insert(non_common_subtitles, table.concat(this_non_common_subtitles, ", "))
							saw_non_common_subtitles = true
						else
							table.insert(non_common_subtitles, "otherwise")
						end
					end
					non_common_subtitle_portion =
						saw_non_common_subtitles and table.concat(non_common_subtitles, " or ") or ""
				end
				-- 5. Combine the common and non-common subtitle portions.
				local subtitle_portions = {}
				if common_subtitle_portion ~= "" then
					table.insert(subtitle_portions, common_subtitle_portion)
				end
				if non_common_subtitle_portion ~= "" then
					table.insert(subtitle_portions, non_common_subtitle_portion)
				end
				if #seg_stems_seen > 1 then
					table.insert(subtitle_portions,
						(number_to_english[#seg_stems_seen] or "" .. #seg_stems_seen) .. " different stems"
					)
				end
				local subtitle_portion =  table.concat(subtitle_portions, "; ")
				if subtitle_portion ~= "" then
					title_to_insert = alternant_decl_title .. " (" .. subtitle_portion .. ")"
				else
					title_to_insert = alternant_decl_title
				end
			end
			-- Don't insert blank title (happens e.g. with "((ali))quis<irreg+>").
			if title_to_insert ~= "" then
				table.insert(declensions.title, title_to_insert)
			end
		else
			for slot in iter_slots(is_adj) do
				declensions.forms[slot], declensions.notes[slot] = append_form(
					declensions.forms[slot], declensions.notes[slot],
					slot:find("linked") and seg.orig_prefix or seg.prefix)
			end
			table.insert(declensions.title, glossary_link("indeclinable") .. " portion")
		end
	end

	-- First title is uppercase, remainder have an indefinite article, joined
	-- using "with".
	local titles = {}
	for i, title in ipairs(declensions.title) do
		if i == 1 then
			table.insert(titles, m_string_utilities.ucfirst(title))
		else
			table.insert(titles, m_string_utilities.add_indefinite_article(title))
		end
	end
	declensions.title = table.concat(titles, " with ")

	return declensions
end

local function construct_title(args_title, declensions_title, from_headword, parsed_run)
	if args_title then
		declensions_title = rsub(args_title, "<1>", "[[Appendix:Latin first declension|first declension]]")
		declensions_title = rsub(declensions_title, "<1&2>", "[[Appendix:Latin first declension|first]]/[[Appendix:Latin second declension|second declension]]")
		declensions_title = rsub(declensions_title, "<2>", "[[Appendix:Latin second declension|second declension]]")
		declensions_title = rsub(declensions_title, "<3>", "[[Appendix:Latin third declension|third declension]]")
		declensions_title = rsub(declensions_title, "<4>", "[[Appendix:Latin fourth declension|fourth declension]]")
		declensions_title = rsub(declensions_title, "<5>", "[[Appendix:Latin fifth declension|fifth declension]]")
		if from_headword then
			declensions_title = m_string_utilities.lcfirst(rsub(declensions_title, "%.$", ""))
		else
			declensions_title = m_string_utilities.ucfirst(declensions_title)
		end
	else
		local post_text_parts = {}
		if parsed_run.loc then
			table.insert(post_text_parts, ", with locative")
		end
		if not apparent_decl == "indecl" then
			if parsed_run.num == "sg" then
				table.insert(post_text_parts, ", singular only")
			elseif parsed_run.num == "pl" then
				table.insert(post_text_parts, ", plural only")
			end
		end
		
		local post_text = table.concat(post_text_parts)	
		if from_headword then
			declensions_title = m_string_utilities.lcfirst(declensions_title) .. post_text
		else
			declensions_title = m_string_utilities.ucfirst(declensions_title) .. post_text .. "."
		end
	end

	return declensions_title
end

function export.do_generate_noun_forms(parent_args, pos, from_headword, def, support_num_type)
	local params = {
		[1] = {required = true, default = def or "aqua<1>"},
		footnote = {},
		title = {},
		num = {},
	}
	for slot in iter_noun_slots() do
		params[slot] = {}
	end
	if from_headword then
		params.lemma = {list = true}
		params.id = {}
		params.pos = {default = pos}
		params.cat = {list = true}
		params.indecl = {type = "boolean"}
		params.m = {list = true}
		params.f = {list = true}
		params.g = {list = true}
	end
	if support_num_type then
		params["type"] = {}
	end

	local args = m_para.process(parent_args, params)

	if args.title then
		track("overriding-title")
	end
	pos = args.pos or pos -- args.pos only set when from_headword
	
	local parsed_run = parse_segment_run_allowing_alternants(args[1])
	parsed_run.loc = parsed_run.loc or not not (args.loc_sg or args.loc_pl)
	parsed_run.num = args.num or parsed_run.num

	local declensions = decline_segment_run(parsed_run, pos, false)

	if not parsed_run.loc then
		declensions.forms.loc_sg = nil
		declensions.forms.loc_pl = nil
	end

	declensions.title = construct_title(args.title, declensions.title, false, parsed_run)

	local all_data = {
		title = declensions.title,
		footnotes = {},
		num = parsed_run.num or "",
		gender = parsed_run.gender,
		propses = parsed_run.propses,
		forms = declensions.forms,
		categories = declensions.categories,
		notes = {},
		user_specified = {},
		accel = {},
		overriding_lemma = args.lemma,
		id = args.id,
		pos = pos,
		cat = args.cat,
		indecl = args.indecl,
		m = args.m,
		f = args.f,
		overriding_genders = args.g,
		num_type = args["type"],
	}

	if args.footnote then
		m_table.insertIfNot(all_data.footnotes, args.footnote)
	end
	for _, footnote in ipairs(declensions.footnotes) do
		m_table.insertIfNot(all_data.footnotes, footnote)
	end
		
	for slot in iter_noun_slots() do
		if declensions.notes[slot] then
			for index, notes in pairs(declensions.notes[slot]) do
				all_data.notes[slot .. index] = notes
			end
		end
	end

	process_noun_forms_and_overrides(all_data, args)

	return all_data
end

function export.do_generate_adj_forms(parent_args, pos, from_headword, def, support_num_type)
	local params = {
		[1] = {required = true, default = def or "bonus"},
		footnote = {},
		title = {},
		num = {},
		noneut = {type = "boolean"},
		nomf = {type = "boolean"},
	}
	for slot in iter_adj_slots() do
		params[slot] = {}
	end
	if from_headword then
		params.lemma = {list = true}
		params.comp = {list = true}
		params.sup = {list = true}
		params.adv = {list = true}
		params.id = {}
		params.pos = {default = pos}
		params.cat = {list = true}
		params.indecl = {type = "boolean"}
	end
	if support_num_type then
		params["type"] = {}
	end

	local args = m_para.process(parent_args, params)

	if args.title then
		track("overriding-title")
	end
	pos = args.pos or pos -- args.pos only set when from_headword
	
	local segment_run = args[1]
	if not rfind(segment_run, "[<(]") then
		-- If the segment run doesn't have any explicit declension specs or alternants,
		-- add a default declension spec of <+> to it (or <0+> for indeclinable
		-- adjectives). This allows the majority of adjectives to just specify
		-- the lemma.
		segment_run = segment_run .. (args.indecl and "<0+>" or "<+>")
	end
	local parsed_run = parse_segment_run_allowing_alternants(segment_run)
	parsed_run.loc = parsed_run.loc or not not (
		args.loc_sg_m or args.loc_sg_f or args.loc_sg_n or args.loc_pl_m or args.loc_pl_f or args.loc_pl_n
	)
	parsed_run.num = args.num or parsed_run.num

	local overriding_voc = not not (
		args.voc_sg_m or args.voc_sg_f or args.voc_sg_n or args.voc_pl_m or args.voc_pl_f or args.voc_pl_n
	)
	local declensions = decline_segment_run(parsed_run, pos, true)

	if not parsed_run.loc then
		declensions.forms.loc_sg_m = nil
		declensions.forms.loc_sg_f = nil
		declensions.forms.loc_sg_n = nil
		declensions.forms.loc_pl_m = nil
		declensions.forms.loc_pl_f = nil
		declensions.forms.loc_pl_n = nil
	end

	-- declensions.voc is false if any component has no vocative (e.g. quī); in
	-- that case, if the user didn't supply any vocative overrides, wipe out
	-- any partially-generated vocatives
	if not overriding_voc and not declensions.voc then
		declensions.forms.voc_sg_m = nil
		declensions.forms.voc_sg_f = nil
		declensions.forms.voc_sg_n = nil
		declensions.forms.voc_pl_m = nil
		declensions.forms.voc_pl_f = nil
		declensions.forms.voc_pl_n = nil
	end

	declensions.title = construct_title(args.title, declensions.title, from_headword, parsed_run)

	local all_data = {
		title = declensions.title,
		footnotes = {},
		num = parsed_run.num or "",
		propses = parsed_run.propses,
		forms = declensions.forms,
		categories = declensions.categories,
		notes = {},
		user_specified = {},
		accel = {},
		voc = declensions.voc,
		loc = declensions.loc,
		noneut = args.noneut or declensions.noneut,
		nomf = args.nomf or declensions.nomf,
		overriding_lemma = args.lemma,
		comp = args.comp,
		sup = args.sup,
		adv = args.adv,
		id = args.id,
		pos = pos,
		cat = args.cat,
		indecl = args.indecl,
		num_type = args["type"],
	}

	if args.footnote then
		m_table.insertIfNot(all_data.footnotes, args.footnote)
	end
	for _, footnote in ipairs(declensions.footnotes) do
		m_table.insertIfNot(all_data.footnotes, footnote)
	end

	for slot in iter_adj_slots() do
		if declensions.notes[slot] then
			for index, notes in pairs(declensions.notes[slot]) do
				all_data.notes[slot .. index] = notes
			end
		end
	end

	process_adj_forms_and_overrides(all_data, args)

	return all_data
end

function export.show_noun(frame)
	local parent_args = frame:getParent().args
	local data = export.do_generate_noun_forms(parent_args, "nouns")

	show_forms(data, false)

	return make_noun_table(data)
end

function export.show_adj(frame)
	local parent_args = frame:getParent().args
	local data = export.do_generate_adj_forms(parent_args, "adjectives")

	partial_show_forms(data, true)

	return m_adj_table.make_table(data, data.noneut, data.nomf)
end

function export.generate_noun_forms(frame)
	local include_props = frame.args["include_props"]
	local parent_args = frame:getParent().args
	local data = export.do_generate_noun_forms(parent_args, "nouns")

	return concat_forms(data, false, include_props)
end

function export.generate_adj_forms(frame)
	local include_props = frame.args["include_props"]
	local parent_args = frame:getParent().args
	local data = export.do_generate_adj_forms(parent_args, "adjectives")

	return concat_forms(data, true, include_props)
end

return export
