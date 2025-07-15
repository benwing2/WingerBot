local export = {}

--[=[

Authorship: Ben Wing <benwing2>

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of case/number.
	 Example slot names for verbs are "gen_s" (genitive singular) and
	 "abl_2s_inform_mpos" (ablative 2nd-singular informal multiple-possession).
	 Each slot is filled with zero or more forms.

-- "form" = The conjugated Kyrgyz form representing the value of a given slot.

-- "lemma" = The dictionary form of a given Kyrgyz term. Generally the nominative
     masculine singular, but may occasionally be another form if the nominative
	 masculine singular is missing.
]=]

local lang = require("Module:languages").getByCode("ky")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")
local m_script_utilities = require("Module:script utilities")
local iut = require("Module:inflection utilities")
local m_para = require("Module:parameters")

local current_title = mw.title.getCurrentTitle()

local u = require("Module:string/char")
local rsplit = m_string_utilities.split
local rfind = m_string_utilities.find
local rmatch = m_string_utilities.match
local rgmatch = m_string_utilities.gmatch
local rsubn = m_string_utilities.gsub
local ulen = m_string_utilities.len
local usub = m_string_utilities.sub
local uupper = m_string_utilities.upper
local ulower = m_string_utilities.lower
local insert = table.insert
local dump = mw.dumpObject

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

local lower_vowel = "аоөүуыэяёюие"
local upper_vowel = uupper(lower_vowel)
local vowel = lower_vowel .. upper_vowel
local V = "[" .. vowel .. "]"
local C = "[^" .. vowel .. "]"

local lower_jr = "йр"
local upper_jr = uupper(lower_jr)
local jr = lower_jr .. upper_jr
local lower_voiced_cons_not_jr = "дмлнңбвгжз"
local upper_voiced_cons_not_jr = uupper(lower_voiced_cons_not_jr)
local voiced_cons_not_jr = lower_voiced_cons_not_jr .. upper_voiced_cons_not_jr
local lower_unvoiced_cons = "кпстфхчцшщ"
local upper_unvoiced_cons = uupper(lower_unvoiced_cons)
local unvoiced_cons = lower_unvoiced_cons .. upper_unvoiced_cons

local function construct_vowel_harmony_table(spec)
	local tab = {}
	for _, triggers_result in ipairs(spec) do
		local triggers, result = unpack(triggers_result)
		for trigger in rgmatch(triggers, ".") do
			tab[trigger] = result
		end
	end
	return tab
end

local high_harmony_table = construct_vowel_harmony_table {
	{ "эие", "и" }, -- front unrounded
	{ "аыя", "ы" }, -- back unrounded
	{ "өү", "ү" }, -- front rounded
	{ "оёюу", "у" }, -- back rounded
}
local low_harmony_table = construct_vowel_harmony_table {
	{ "эие", "е" }, -- front unrounded
	{ "аыяюу", "а" }, -- back unrounded
	{ "өү", "ө" }, -- front rounded
	{ "оё", "о" }, -- back rounded
}
local round_harmony_table = construct_vowel_harmony_table {
	{ "эие", "и" }, -- front unrounded
	{ "аыя", "ы" }, -- back unrounded
	{ "өү", "ү" }, -- front rounded
	{ "оёюу", "у" }, -- back rounded
}

local tenses = {
	{ "spast", "spast" },
	{ "dist_dir_past", "distant|dir|past" },
	{ "dist_indir_past", "distant|indir|past" },
	{ "hab_past", "hab|past" },
	{ "pres", "aor|pres" },
	{ "presum_fut", "presumptive|fut" },
	{ "intent_fut", "intentive|fut" },
	{ "imp", "imp" },
	{ "opt", "opt" },
	{ "cond", "cond" },
}

local person_numbers = { "1s", "2s_inform", "2s_formal", "3s", "1p", "2p_inform", "2p_formal", "3p" }

local default_person_number_suffixes_type_1 = {
	["1s"] = "им",
	["2s_inform"] = "иң",
	["2s_formal"] = "иңиз",
	["3s"] = "",
	["1p"] = "к",
	["2p_inform"] = "иңар",
	["2p_formal"] = "иңиздар",
	["3p"] = "",
}

local default_person_number_suffixes_type_2 = {
	["1s"] = "мин",
	["2s_inform"] = "сиң",
	["2s_formal"] = "сиз",
	["3s"] = "",
	["1p"] = "биз",
	["2p_inform"] = "сиңар",
	["2p_formal"] = "сиздар",
	["3p"] = "",
}

local verb_slots_list = {}

local function make_verb_slots()
	insert(verb_slots_list, { "inf", "inf" })
	insert(verb_slots_list, { "past_part", "past|part" })
	insert(verb_slots_list, { "fut_part", "fut|part" })
	insert(verb_slots_list, { "trans_past_part", "transitory|past|part" })
	for _, tense_accel in ipairs(tenses) do
		for _, person_number in ipairs(person_numbers) do
			local tense, accel_tense = unpack(tense_accel)
			local accel_person_number = person_number:gsub("_", "|")
			local slot = tense .. "_" .. person_number
			local accel = accel_person_number .. "|" .. accel_tense
			insert(verb_slots_list, { slot, accel })
		end
	end
end

make_verb_slots()


local function skip_slot(conj_spec, slot)
	return false
end


local function combine_stem_ending(stem, ending)
	if ending == "" then
		return stem
	end

	local split_suffix = rsplit(ending, "(" .. V  .. ")")
	local suffix_syls = {}
	for i, sufpart in ipairs(split_suffix) do
		if i == #split_suffix and suffix_syls[1] or i % 2 == 0 then
			suffix_syls[#suffix_syls] = suffix_syls[#suffix_syls] .. sufpart
		else
			insert(suffix_syls, sufpart)
		end
	end

	for _, endsyl in ipairs(suffix_syls) do
		local stem_init, stem_last_vowel, stem_final_cons_cluster = rmatch(stem, "^(.*)(" .. V .. ")(.-)$")
		if not stem_last_vowel then
			error(("Lemma or stem '%s' has no vowel, not sure how to implement vowel harmony"):format(stem))
		end
		local first_endsyl_letter = usub(endsyl, 1)
		local endsyl_init, endsyl_vowel, endsyl_final = rmatch(endsyl, "^(.-)(" .. V .. ")(.*)$")
		if not endsyl_init then
			endsyl_init = endsyl
			endsyl_vowel = ""
			endsyl_final = ""
		else
			if endsyl_vowel ~= "и" and endsyl_vowel ~= "а" then
				error(("Internal error: All endsyl vowels should be high и or low а, but saw %s"):format(endsyl))
			end
			local harmony_table
			if endsyl_vowel == "и" then
				harmony_table = high_harmony_table
			else
				harmony_table = low_harmony_table
			end
			if endsyl_init == "" and stem_final_cons_cluster == "" then
				endsyl_vowel = ""
			else
				endsyl_vowel = harmony_table[ulower(stem_last_vowel)]
			end
		end
		if endsyl_init == "Л" then
			if stem_final_cons_cluster == "" or rfind(stem_final_cons_cluster, "[" .. jr .. "]$") then
				endsyl_init = "л"
			else
				endsyl_init = "д"
			end
		elseif endsyl_init == "Н" then
			if stem_final_cons_cluster == "" then
				endsyl_init = "н"
			else
				endsyl_init = "д"
			end
		elseif endsyl_init == "С" then
			if stem_final_cons_cluster == "" then
				endsyl_init = "с"
			else
				endsyl_init = ""
			end
		end
		if rfind(stem_final_cons_cluster, "[" .. unvoiced_cons .. "]$") then
			if endsyl_init == "д" then
				endsyl_init = "т"
			elseif endsyl_init == "г" then
				endsyl_init = "к"
			end
		end
		if endsyl_init == "" then
			stem_final_cons_cluster = rsub(stem_final_cons_cluster, "[пПкК]$", {
				["п"] = "б",
				["П"] = "Б",
				["к"] = "г",
				["К"] = "Г",
			})
		end
		stem = stem_init .. stem_last_vowel .. stem_final_cons_cluster .. endsyl_init .. endsyl_vowel .. endsyl_final
	end

	return stem
end


local function conjugate_verb(conj_spec, lemma)
	local function insert_form(slot, form)
		if skip_slot(conj_spec, slot) then
			return
		end
		iut.insert_form(conj_spec.forms, slot, {form = form})
	end

	local function resolve_ending(ending)
		if type(ending) == "function" then
			return ending(conj_spec.stem)
		else
			return ending
		end
	end

	local function add_stem_ending(stem, ending)
		ending = resolve_ending(ending)
		local full_ending = ending:match("^!(.*)$")
		if full_ending then
			return full_ending
		end
		return combine_stem_ending(stem, ending)
	end

	local function add_stem_final_ending(spec, stem, ending)
		local form = add_stem_ending(stem, ending)
		if spec.postprocess then
			form = spec.postprocess(form)
		end
		return form
	end

	local function make_tense(spec)
		for _, person_number in ipairs(person_numbers) do
			local stem_with_infix = person_number == "3p" and not spec.ending_3p and
				add_stem_ending(conj_spec.stem, "иш") or conj_spec.stem
			local tense_stem = add_stem_ending(stem_with_infix, spec.tense_ending)
			local ending = (person_number == "3s" or person_number == "3p") and spec.ending_3sp or
				spec["ending_" .. person_number]
			if not ending then
				local default_endings = spec.ending_type == "1" and default_person_number_suffixes_type_1 or
					default_person_number_suffixes_type_2
				ending = default_endings[person_number]
			end
			ending = resolve_ending(ending)
			local slot = spec.tense .. "_" .. person_number
			if type(ending) == "table" then
				for _, e in ipairs(ending) do
					insert_form(slot, add_stem_final_ending(spec, tense_stem, e))
				end
			else
				insert_form(slot, add_stem_final_ending(spec, tense_stem, ending))
			end
		end
	end

	make_tense {
		tense = "spast",
		tense_ending = "ди",
		ending_type = "1",
	}
	make_tense {
		tense = "dist_dir_past",
		tense_ending = "ган",
		ending_type = "2",
	}
	make_tense {
		tense = "dist_indir_past",
		tense_ending = "ип",
		ending_type = "2",
		ending_3sp = "тир"
	}
	make_tense {
		tense = "hab_past",
		tense_ending = "чи",
		ending_type = "2",
	}
	make_tense {
		tense = "pres",
		tense_ending = function(stem)
			if rfind(stem, V .. "$") then
				return "й"
			else
				return "а" -- will voice final к or п
			end
		end,
		ending_type = "2",
		ending_1s = "м",
		ending_3sp = "т",
	}
	make_tense {
		tense = "presum_fut",
		tense_ending = "ар",
		ending_type = "2",
	}
	make_tense {
		tense = "intent_fut",
		tense_ending = "мак",
		ending_type = "2",
	}
	make_tense {
		tense = "imp",
		tense_ending = "",
		ending_type = "1",
		ending_1s = "айин",
		ending_2s_inform = {"", "гин"},
		ending_3sp = "син",
		ending_1p = "айлик",
		ending_2p_inform = "гила",
	}
	make_tense {
		tense = "opt",
		tense_ending = "ги",
		ending_type = "1",
		ending_3s = "си",
		ending_2p_inform = "лариң",
		ending_2p_formal = "лариңиз",
		ending_3p = "лари",
		postprocess = function(form)
			return "[[" .. form .. "]] [[келет]]"
		end,
	}
	make_tense {
		tense = "cond",
		tense_ending = "са",
		ending_type = "1",
		ending_3p = "",
	}
	local function add_single(slot, ending)
		insert_form(slot, add_stem_ending(conj_spec.stem, ending))
	end

	add_single("inf", function(stem)
		return "!" .. conj_spec.lemma
	end)
	add_single("past_part", "ган")
	add_single("fut_part", "ар")
	add_single("trans_past_part", "атир")
end


-- Compute the categories to add the verb to, as well as the annotation to display in the
-- conjugation title bar. We combine the code to do these functions as both categories and
-- title bar contain similar information.
local function compute_categories_and_annotation(conj_spec)
	local cats = {}
	local function insert(cattype)
		m_table.insertIfNot(cats, "Kyrgyz " .. cattype)
	end
	if conj_spec.number == "sg" then
		insert("uncountable verbs")
	elseif conj_spec.number == "pl" then
		insert("pluralia tantum")
	end
	conj_spec.annotation =
		conj_spec.number == "sg" and "sg-only" or
		conj_spec.number == "pl" and "pl-only" or
		""
	conj_spec.categories = cats
end


local function show_forms(conj_spec)
	local lemmas = {}
	if conj_spec.forms.nom_s then
		for _, nom_s in ipairs(conj_spec.forms.nom_s) do
			table.insert(lemmas, nom_s.form)
		end
	elseif conj_spec.forms.nom_p then
		for _, nom_p in ipairs(conj_spec.forms.nom_p) do
			table.insert(lemmas, nom_p.form)
		end
	end
	local props = {
		lemmas = lemmas,
		slot_list = verb_slots_list,
		lang = lang,
		include_translit = true,
	}
	iut.show_forms(conj_spec.forms, props)
end


local function make_table(conj_spec)
	local forms = conj_spec.forms

	local header = mw.getCurrentFrame():expandTemplate{
		title = "inflection-table-top",
		args = {
			title = "{title}{annotation}",
			palette = "blue",
			tall = "yes",
			class = "wide tr-alongside", -- hack to suppress excess space below each term
			category = "conjugation",
		}
	}

	local table_spec = [=[
! colspan="3" | infinitive
| colspan="2" | {inf}
| colspan="999" rowspan="4" class="blank-end-row" |
|-
! rowspan="3" style="min-width:0" | participle
! colspan="2" | past
| colspan="2" | {past_part}
|-
! colspan="2" | future
| colspan="2" | {fut_part}
|-
! colspan="2" | transitory past
| colspan="2" | {trans_past_part}
|-
| class="separator" colspan="999" |
|-
! colspan="3" class="outer" |
! colspan="4" class="outer" | singular
! colspan="4" class="outer" | plural
|-
! colspan="3" rowspan="2" |
! rowspan="2" | 1<sup>st</sup> person
! colspan="2" | 2<sup>nd</sup> person
! rowspan="2" | 3<sup>rd</sup> person
! rowspan="2" | 1<sup>st</sup> person
! colspan="2" | 2<sup>nd</sup> person
! rowspan="2" | 3<sup>rd</sup> person
|-
! informal
! formal
! informal
! formal
|-
! colspan="3" |
! {men}
! {sen}
! {siz}
! {al}
! {biz}
! {siler}
! {sizder}
! {alar}
|-
! rowspan="4" style="min-width:0" | past
! colspan="2" class="secondary" | simple
| {spast_1s}
| {spast_2s_inform}
| {spast_2s_formal}
| {spast_3s}
| {spast_1p}
| {spast_2p_inform}
| {spast_2p_formal}
| {spast_3p}
|-
! rowspan="2" class="secondary" | distant
! class="secondary" | direct
| {dist_dir_past_1s}
| {dist_dir_past_2s_inform}
| {dist_dir_past_2s_formal}
| {dist_dir_past_3s}
| {dist_dir_past_1p}
| {dist_dir_past_2p_inform}
| {dist_dir_past_2p_formal}
| {dist_dir_past_3p}
|-
! class="secondary" | indirect
| {dist_indir_past_1s}
| {dist_indir_past_2s_inform}
| {dist_indir_past_2s_formal}
| {dist_indir_past_3s}
| {dist_indir_past_1p}
| {dist_indir_past_2p_inform}
| {dist_indir_past_2p_formal}
| {dist_indir_past_3p}
|-
! colspan="2" class="secondary" | habitual
| {hab_past_1s}
| {hab_past_2s_inform}
| {hab_past_2s_formal}
| {hab_past_3s}
| {hab_past_1p}
| {hab_past_2p_inform}
| {hab_past_2p_formal}
| {hab_past_3p}
|-
! style="min-width:0" | present
! colspan="2" class="secondary" | aorist
| {pres_1s}
| {pres_2s_inform}
| {pres_2s_formal}
| {pres_3s}
| {pres_1p}
| {pres_2p_inform}
| {pres_2p_formal}
| {pres_3p}
|-
! rowspan="2" style="min-width:0" | future
! colspan="2" class="secondary" | presumptive
| {presum_fut_1s}
| {presum_fut_2s_inform}
| {presum_fut_2s_formal}
| {presum_fut_3s}
| {presum_fut_1p}
| {presum_fut_2p_inform}
| {presum_fut_2p_formal}
| {presum_fut_3p}
|-
! colspan="2" class="secondary" | intentional
| {intent_fut_1s}
| {intent_fut_2s_inform}
| {intent_fut_2s_formal}
| {intent_fut_3s}
| {intent_fut_1p}
| {intent_fut_2p_inform}
| {intent_fut_2p_formal}
| {intent_fut_3p}
|-
! colspan="3" | imperative/hortative
| {imp_1s}
| {imp_2s_inform}
| {imp_2s_formal}
| {imp_3s}
| {imp_1p}
| {imp_2p_inform}
| {imp_2p_formal}
| {imp_3p}
|-
! colspan="3" | optative
| {opt_1s}
| {opt_2s_inform}
| {opt_2s_formal}
| {opt_3s}
| {opt_1p}
| {opt_2p_inform}
| {opt_2p_formal}
| {opt_3p}
|-
! colspan="3" | conditional
| {cond_1s}
| {cond_2s_inform}
| {cond_2s_formal}
| {cond_3s}
| {cond_1p}
| {cond_2p_inform}
| {cond_2p_formal}
| {cond_3p}
]=]

	local footer = mw.getCurrentFrame():expandTemplate{ title = "inflection-table-bottom" }

	if conj_spec.title then
		forms.title = conj_spec.title
	else
		forms.title = 'Conjugation of <i lang="ky" class="Cyrl">' .. forms.lemma .. '</i>'
	end

	local function make_text_smaller(text)
		return "(<span style=\"font-size: smaller;\">" .. text .. "</span>)"
	end

	local annotation = conj_spec.annotation
	if annotation == "" then
		forms.annotation = ""
	else
		forms.annotation = " " .. make_text_smaller(annotation)
	end

	local function tag_text(text)
		return make_text_smaller(m_script_utilities.tag_text(text, lang))
	end

	-- grammatical terms used in the table
	forms.men = tag_text("мен")
	forms.sen = tag_text("сен")
	forms.siz = tag_text("сиз")
	forms.al = tag_text("ал")
	forms.biz = tag_text("биз")
	forms.siler = tag_text("силер")
	forms.sizder = tag_text("сиздер")
	forms.alar = tag_text("алар")

	return m_string_utilities.format(header .. table_spec .. footer, forms)
end


-- Externally callable function to parse and conjine a verb where all forms
-- are given manually. Return value is WORD_SPEC, an object where the conjugated
-- forms are in `WORD_SPEC.forms` for each slot. If there are no values for a
-- slot, the slot key will be missing. The value for a given slot is a list of
-- objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(parent_args)
	local params = {
		stem = true, -- specify the stem if it ends in a vowel
		title = true,
		pagename = true,
	}

	local args = m_para.process(parent_args, params)
	local pagename = args.pagename or mw.loadData("Module:headword/data").pagename
	local lemma = pagename
	local conj_spec = {
		lemma = lemma,
		stem = args.stem or rsub(lemma, "[үөуо]+$", ""),
		title = args.title,
		forms = {},
		number = number,
	}
	conjugate_verb(conj_spec, lemma)
	compute_categories_and_annotation(conj_spec)
	return conj_spec
end


-- Entry point for {{ky-conj}}.
function export.show(frame)
	local parent_args = frame:getParent().args
	local conj_spec = export.do_generate_forms(parent_args)
	show_forms(conj_spec)
	return make_table(conj_spec) .. require("Module:utilities").format_categories(conj_spec.categories, lang)
end

return export
