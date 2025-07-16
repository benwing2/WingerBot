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
--[==[ not currently used
local round_harmony_table = construct_vowel_harmony_table {
	{ "эеө", "ө" }, -- low front
	{ "аяоё", "о" }, -- low back
	{ "иү", "ү" }, -- high front
	{ "ыую", "у" }, -- high back
}
]==]
local high_round_harmony_table = construct_vowel_harmony_table {
	{ "эеөиү", "ү" }, -- front
	{ "аяоёыую", "у" }, -- back
}
local tenses = {
	{ "pres", "aor|pres" }, -- non-past/aorist
	{ "rec_past", "recent|past" },
	{ "gen_past", "general|past" },
	{ "dist_gen_past", "distant|general|past" },
	{ "indir_past", "indir|past" },
	{ "hab_past", "hab|past" },
	{ "hab_rem_past", "hab|remote|past" },
	{ "unaccomp_past", "unaccomplished|past" },
	{ "uncert_fut", "uncertain|fut" },
	{ "would_cond_1", "''would''|cond|type1" },
	{ "would_cond_2", "''would''|cond|type2" },
	{ "cfact_cond", "counterfactual|cond" },
	{ "imp", "imp" },
--	{ "opt", "opt" },
	{ "if_cond", "''if''|cond" },
}

local person_numbers = { "1s", "2s_inform", "2s_formal", "3s", "1p", "2p_inform", "2p_formal", "3p" }

-- P1: past/conditional
local default_person_number_suffixes_type_1 = {
	["1s"] = "им",
	["2s_inform"] = "иң",
	["2s_formal"] = "иңиз",
	["3s"] = "",
	["1p"] = "ик",
	["2p_inform"] = "иңар",
	["2p_formal"] = "иңиздар",
	["3p"] = "",
}

-- P2: copula
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

-- P3: present
local default_person_number_suffixes_type_3 = {
	["1s"] = {"мин", "м"},
	["2s_inform"] = "сиң",
	["2s_formal"] = "сиз",
	["3s"] = "т",
	["1p"] = "биз",
	["2p_inform"] = "сиңар",
	["2p_formal"] = "сиздар",
	["3p"] = "т",
}

local verb_slots_list = {}

local function make_verb_slots()
	insert(verb_slots_list, { "inf", "inf" })
	insert(verb_slots_list, { "past_part", "past|part" })
	insert(verb_slots_list, { "fut_part", "fut|part" })
	insert(verb_slots_list, { "neg_fut_part", "neg|fut|part" })
	insert(verb_slots_list, { "trans_past_part", "transitory|past|part" })
	insert(verb_slots_list, { "pres_pf_part", "pres|pf|part" })
	insert(verb_slots_list, { "pres_impf_part", "pres|impf|part" })
	insert(verb_slots_list, { "neg_pres_part", "neg|pres|part" })
	for _, tense_accel in ipairs(tenses) do
		for _, pos_neg in ipairs { "", "neg_" } do
			local tense, accel_tense = unpack(tense_accel)
			local pos_neg_accel = pos_neg == "" and "" or "neg|"
			if tense ~= "unaccomp_past" or pos_neg ~= "neg_" then
				for _, person_number in ipairs(person_numbers) do
					local accel_person_number = person_number:gsub("_", "|")
					local slot = pos_neg .. tense .. "_" .. person_number
					local accel = accel_person_number .. "|" .. pos_neg_accel .. accel_tense
					insert(verb_slots_list, { slot, accel })
				end
			end
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
			if rfind(endsyl_vowel, "^[аиу]$") then
				local harmony_table
				if endsyl_vowel == "и" then
					harmony_table = high_harmony_table
				elseif endsyl_vowel == "у" then
					harmony_table = high_round_harmony_table
				else
					harmony_table = low_harmony_table
				end
				if endsyl_init == "" and stem_final_cons_cluster == "" then
					endsyl_vowel = ""
				else
					endsyl_vowel = harmony_table[ulower(stem_last_vowel)]
				end
			end
		end
		if endsyl_init ~= "" then
			local endsyl_init_first, endsyl_init_butfirst = rmatch(endsyl_init, "^(.)(.*)$")
			if endsyl_init_first == "Л" then
				if stem_final_cons_cluster == "" or rfind(stem_final_cons_cluster, "[" .. jr .. "]$") then
					endsyl_init_first = "л"
				else
					endsyl_init_first = "д"
				end
			elseif endsyl_init_first == "Н" then
				if stem_final_cons_cluster == "" then
					endsyl_init_first = "н"
				else
					endsyl_init_first = "д"
				end
			elseif endsyl_init_first == "С" then
				if stem_final_cons_cluster == "" then
					endsyl_init_first = "с"
				else
					endsyl_init_first = ""
				end
			elseif endsyl_init_first == "Й" then
				if stem_final_cons_cluster == "" then
					endsyl_init_first = "й"
				else
					endsyl_init_first = "а"
				end
			elseif endsyl_init_first == "*" then
				if stem_final_cons_cluster == "" then
					endsyl_init_first = ulower(stem_last_vowel)
					if endsyl_init_first == "е" then
						endsyl_init_first = "э"
						stem_last_vowel = stem_last_vowel == "Е" and "Э" or "э"
					end
				else
					error(("Internal error: * in ending %s cannot follow a consonant-final stem %s"):format(
						ending, stem))
				end
			end
			if rfind(stem_final_cons_cluster, "[" .. unvoiced_cons .. "]$") then
				if endsyl_init_first == "д" then
					endsyl_init_first = "т"
				elseif endsyl_init_first == "г" then
					endsyl_init_first = "к"
				elseif endsyl_init_first == "б" then
					endsyl_init_first = "п"
				end
			end
			endsyl_init = endsyl_init_first .. endsyl_init_butfirst
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

	stem = rsub(stem, "[Йй][АаОоУу]", {
		["йа"] = "я",
		["Йа"] = "Я",
		["ЙА"] = "Я",
		["йо"] = "ё",
		["Йо"] = "Ё",
		["ЙО"] = "Ё",
		["йу"] = "ю",
		["Йу"] = "Ю",
		["ЙУ"] = "Ю",
	})

	return stem
end


local function conjugate_verb(conj_spec, lemma)
	local function insert_form(slot, form)
		if skip_slot(conj_spec, slot) then
			return
		end
		iut.insert_form(conj_spec.forms, slot, {form = form})
	end

	local function resolve_ending(stem, ending)
		if type(ending) == "function" then
			return ending(stem)
		else
			return ending
		end
	end

	local function add_stem_ending(stem, ending)
		ending = resolve_ending(stem, ending)
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
			ending = resolve_ending(tense_stem, ending)
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

	local function make_future_part_ending(stem)
		if rfind(stem, "[иы]$") then
			return "р"
		elseif rfind(stem, V .. "$") then
			return "*р"
		else
			return "ар"
		end
	end

	make_tense { -- non-past/aorist
		tense = "pres",
		tense_ending = "Й",
		ending_type = "3",
	}
	make_tense { -- negative non-past/aorist
		tense = "neg_pres",
		tense_ending = "бай",
		ending_type = "3",
	}
	make_tense { -- recent past
		tense = "rec_past",
		tense_ending = "ди",
		ending_type = "1",
	}
	make_tense { -- negative recent past, variant #1
		tense = "neg_rec_past",
		tense_ending = "ган жок",
		ending_type = "2",
	}
	make_tense { -- negative recent past, variant #2
		tense = "neg_rec_past",
		tense_ending = "бади",
		ending_type = "1",
	}
	make_tense { -- remote/general past
		tense = "gen_past",
		tense_ending = "ган",
		ending_type = "2",
		ending_1sg = {"ганмиң", "гам"},
	}
	make_tense { -- negative remote/general past
		tense = "neg_gen_past",
		tense_ending = "ган эмес",
		ending_type = "2",
	}
	make_tense { -- distant remote/general past
		tense = "dist_gen_past",
		tense_ending = "ган эле",
		ending_type = "1",
	}
	make_tense { -- negative distant remote/general past
		tense = "neg_dist_gen_past",
		tense_ending = "ган эмес эле",
		ending_type = "1",
	}
	make_tense { -- indirect/unwitnessed past, variant #1
		tense = "indir_past",
		tense_ending = "иптир",
		ending_type = "2",
	}
	make_tense { -- indirect/unwitnessed past, variant #2
		tense = "indir_past",
		tense_ending = "ип",
		ending_type = "2",
		ending_3sp = {}, -- -тир required, so only one form
	}
	make_tense { -- negative indirect/unwitnessed past, variant #1
		tense = "neg_indir_past",
		tense_ending = "баптир",
		ending_type = "2",
	}
	make_tense { -- negative indirect/unwitnessed past, variant #2
		tense = "neg_indir_past",
		tense_ending = "бап",
		ending_type = "2",
		ending_3sp = {}, -- -тир required, so only one form
	}
	make_tense { -- past habitual
		tense = "hab_past",
		tense_ending = "чу",
		ending_type = "2",
	}
	make_tense { -- negative past habitual
		tense = "neg_hab_past",
		tense_ending = "чу эмес",
		ending_type = "2",
	}
	make_tense { -- remote past habitual
		tense = "hab_rem_past",
		tense_ending = "чу эле",
		ending_type = "1",
	}
	make_tense { -- negative remote past habitual
		tense = "neg_hab_rem_past",
		tense_ending = "чу эле эмес",
		ending_type = "2",
	}
	make_tense { -- past unaccomplished
		tense = "unaccomp_past",
		tense_ending = "Й элек",
		ending_type = "2",
	}
	make_tense { -- uncertain future
		tense = "uncert_fut",
		tense_ending = make_future_part_ending,
		ending_type = "2",
	}
	make_tense { -- negative uncertain future
		tense = "neg_uncert_fut",
		tense_ending = "бас",
		ending_type = "2",
	}
	make_tense { -- "would" conditional 1
		tense = "would_cond_1",
		tense_ending = function(stem)
			return make_future_part_ending(stem) .. " эле"
		end,
		ending_type = "1",
	}
	make_tense { -- negative "would" conditional 1
		tense = "neg_would_cond_1",
		tense_ending = "бас эле",
		ending_type = "1",
	}
	make_tense { -- "would" conditional 2
		tense = "would_cond_2",
		tense_ending = "Йт эле",
		ending_type = "1",
	}
	make_tense { -- negative "would" conditional 2
		tense = "neg_would_cond_2",
		tense_ending = "байт эле",
		ending_type = "1",
	}
	make_tense { -- counterfactual conditional
		tense = "cfact_cond",
		tense_ending = "мак",
		ending_type = "2",
	}
	make_tense { -- negative counterfactual conditional
		tense = "neg_cfact_cond",
		tense_ending = "мак эмес",
		ending_type = "2",
	}
	make_tense { -- imperative/hortative
		tense = "imp",
		tense_ending = "",
		ending_type = "1",
		ending_1s = "айин",
		ending_2s_inform = {"", "гин"},
		ending_2s_formal = "аңиз",
		ending_3sp = "син",
		ending_1p = {"Йлик", "Йли"},
		ending_2p_inform = "гила",
		ending_2p_formal = "аңиздар",
	}
	make_tense { -- negative imperative/hortative
		tense = "neg_imp",
		tense_ending = "",
		ending_type = "1",
		ending_1s = "байин",
		ending_2s_inform = {"ба", "багин"},
		ending_2s_formal = "баңиз",
		ending_3sp = "басин",
		ending_1p = {"байлик", "байли"},
		ending_2p_inform = "багила",
		ending_2p_formal = "баңиздар",
	}
	--[==[
	make_tense {
		tense = "opt",
		tense_ending = "ги",
		ending_type = "1",
		ending_3s = "си",
		ending_2p_inform = "лариң",
		ending_2p_formal = "лариңиз",
		ending_3p = "лари",
		postprocess = function(form)
			return form .. " келет"
		end,
	}]==]
	make_tense { -- "if" conditional
		tense = "if_cond",
		tense_ending = "са",
		ending_type = "1",
	}
	make_tense { -- negative "if" conditional
		tense = "neg_if_cond",
		tense_ending = "баса",
		ending_type = "1",
	}
	local function add_single(slot, ending)
		insert_form(slot, add_stem_ending(conj_spec.stem, ending))
	end

	add_single("inf", function(stem)
		return "!" .. conj_spec.lemma
	end)
	add_single("past_part", "ган")
	add_single("fut_part", make_future_part_ending)
	add_single("neg_fut_part", "бас")
	add_single("trans_past_part", "атир")
	add_single("pres_pf_part", "ип")
	add_single("pres_impf_part", "Й")
	add_single("neg_pres_part", "бай")
end


-- Compute the categories to add the verb to, as well as the annotation to display in the
-- conjugation title bar. We combine the code to do these functions as both categories and
-- title bar contain similar information.
local function compute_categories_and_annotation(conj_spec)
	local cats = {}
	local function insert(cattype)
		m_table.insertIfNot(cats, "Kyrgyz " .. cattype)
	end
	conj_spec.annotation = rfind(conj_spec.stem, V .. "$") and "vowel-final" or "consonant-final"
	conj_spec.categories = cats
end


local function show_forms(conj_spec)
	local lemmas = {}
	if conj_spec.forms.inf then
		for _, inf in ipairs(conj_spec.forms.inf) do
			table.insert(lemmas, inf.form)
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
! rowspan="2" style="min-width:0" | present
! rowspan="2" class="secondary" | aorist
! class="secondary" | positive
| {pres_1s}
| {pres_2s_inform}
| {pres_2s_formal}
| {pres_3s}
| {pres_1p}
| {pres_2p_inform}
| {pres_2p_formal}
| {pres_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_pres_1s}
| {neg_pres_2s_inform}
| {neg_pres_2s_formal}
| {neg_pres_3s}
| {neg_pres_1p}
| {neg_pres_2p_inform}
| {neg_pres_2p_formal}
| {neg_pres_3p}
|- style="border-top: 3px solid black;"
! rowspan="13" style="min-width:0" | past
! rowspan="2" class="secondary" | recent
! class="secondary" | positive
| {rec_past_1s}
| {rec_past_2s_inform}
| {rec_past_2s_formal}
| {rec_past_3s}
| {rec_past_1p}
| {rec_past_2p_inform}
| {rec_past_2p_formal}
| {rec_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_rec_past_1s}
| {neg_rec_past_2s_inform}
| {neg_rec_past_2s_formal}
| {neg_rec_past_3s}
| {neg_rec_past_1p}
| {neg_rec_past_2p_inform}
| {neg_rec_past_2p_formal}
| {neg_rec_past_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | remote/general
! class="secondary" | positive
| {gen_past_1s}
| {gen_past_2s_inform}
| {gen_past_2s_formal}
| {gen_past_3s}
| {gen_past_1p}
| {gen_past_2p_inform}
| {gen_past_2p_formal}
| {gen_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_gen_past_1s}
| {neg_gen_past_2s_inform}
| {neg_gen_past_2s_formal}
| {neg_gen_past_3s}
| {neg_gen_past_1p}
| {neg_gen_past_2p_inform}
| {neg_gen_past_2p_formal}
| {neg_gen_past_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | distant remote/general
! class="secondary" | positive
| {dist_gen_past_1s}
| {dist_gen_past_2s_inform}
| {dist_gen_past_2s_formal}
| {dist_gen_past_3s}
| {dist_gen_past_1p}
| {dist_gen_past_2p_inform}
| {dist_gen_past_2p_formal}
| {dist_gen_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_dist_gen_past_1s}
| {neg_dist_gen_past_2s_inform}
| {neg_dist_gen_past_2s_formal}
| {neg_dist_gen_past_3s}
| {neg_dist_gen_past_1p}
| {neg_dist_gen_past_2p_inform}
| {neg_dist_gen_past_2p_formal}
| {neg_dist_gen_past_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | indirect/unwitnessed
! class="secondary" | positive
| {indir_past_1s}
| {indir_past_2s_inform}
| {indir_past_2s_formal}
| {indir_past_3s}
| {indir_past_1p}
| {indir_past_2p_inform}
| {indir_past_2p_formal}
| {indir_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_indir_past_1s}
| {neg_indir_past_2s_inform}
| {neg_indir_past_2s_formal}
| {neg_indir_past_3s}
| {neg_indir_past_1p}
| {neg_indir_past_2p_inform}
| {neg_indir_past_2p_formal}
| {neg_indir_past_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | habitual
! class="secondary" | positive
| {hab_past_1s}
| {hab_past_2s_inform}
| {hab_past_2s_formal}
| {hab_past_3s}
| {hab_past_1p}
| {hab_past_2p_inform}
| {hab_past_2p_formal}
| {hab_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_hab_past_1s}
| {neg_hab_past_2s_inform}
| {neg_hab_past_2s_formal}
| {neg_hab_past_3s}
| {neg_hab_past_1p}
| {neg_hab_past_2p_inform}
| {neg_hab_past_2p_formal}
| {neg_hab_past_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | remote habitual
! class="secondary" | positive
| {hab_rem_past_1s}
| {hab_rem_past_2s_inform}
| {hab_rem_past_2s_formal}
| {hab_rem_past_3s}
| {hab_rem_past_1p}
| {hab_rem_past_2p_inform}
| {hab_rem_past_2p_formal}
| {hab_rem_past_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_hab_rem_past_1s}
| {neg_hab_rem_past_2s_inform}
| {neg_hab_rem_past_2s_formal}
| {neg_hab_rem_past_3s}
| {neg_hab_rem_past_1p}
| {neg_hab_rem_past_2p_inform}
| {neg_hab_rem_past_2p_formal}
| {neg_hab_rem_past_3p}
|- style="border-top: 2px solid black;"
! class="secondary" | past unaccomplished
! class="secondary" |
| {unaccomp_past_1s}
| {unaccomp_past_2s_inform}
| {unaccomp_past_2s_formal}
| {unaccomp_past_3s}
| {unaccomp_past_1p}
| {unaccomp_past_2p_inform}
| {unaccomp_past_2p_formal}
| {unaccomp_past_3p}
|- style="border-top: 3px solid black;"
! rowspan="2" style="min-width:0" | future
! rowspan="2" class="secondary" | uncertain
! class="secondary" | positive
| {uncert_fut_1s}
| {uncert_fut_2s_inform}
| {uncert_fut_2s_formal}
| {uncert_fut_3s}
| {uncert_fut_1p}
| {uncert_fut_2p_inform}
| {uncert_fut_2p_formal}
| {uncert_fut_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_uncert_fut_1s}
| {neg_uncert_fut_2s_inform}
| {neg_uncert_fut_2s_formal}
| {neg_uncert_fut_3s}
| {neg_uncert_fut_1p}
| {neg_uncert_fut_2p_inform}
| {neg_uncert_fut_2p_formal}
| {neg_uncert_fut_3p}
|- style="border-top: 3px solid black;"
! rowspan="2" style="min-width:0" | imperative/hortative
! rowspan="2" class="secondary" |
! class="secondary" | positive
| {imp_1s}
| {imp_2s_inform}
| {imp_2s_formal}
| {imp_3s}
| {imp_1p}
| {imp_2p_inform}
| {imp_2p_formal}
| {imp_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_imp_1s}
| {neg_imp_2s_inform}
| {neg_imp_2s_formal}
| {neg_imp_3s}
| {neg_imp_1p}
| {neg_imp_2p_inform}
| {neg_imp_2p_formal}
| {neg_imp_3p}
|- style="border-top: 3px solid black;"
! rowspan="8" style="min-width:0" | conditional
! rowspan="2" class="secondary" | ''would'' type 1
! class="secondary" | positive
| {would_cond_1_1s}
| {would_cond_1_2s_inform}
| {would_cond_1_2s_formal}
| {would_cond_1_3s}
| {would_cond_1_1p}
| {would_cond_1_2p_inform}
| {would_cond_1_2p_formal}
| {would_cond_1_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_would_cond_1_1s}
| {neg_would_cond_1_2s_inform}
| {neg_would_cond_1_2s_formal}
| {neg_would_cond_1_3s}
| {neg_would_cond_1_1p}
| {neg_would_cond_1_2p_inform}
| {neg_would_cond_1_2p_formal}
| {neg_would_cond_1_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | ''would'' type 2
! class="secondary" | positive
| {would_cond_2_1s}
| {would_cond_2_2s_inform}
| {would_cond_2_2s_formal}
| {would_cond_2_3s}
| {would_cond_2_1p}
| {would_cond_2_2p_inform}
| {would_cond_2_2p_formal}
| {would_cond_2_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_would_cond_2_1s}
| {neg_would_cond_2_2s_inform}
| {neg_would_cond_2_2s_formal}
| {neg_would_cond_2_3s}
| {neg_would_cond_2_1p}
| {neg_would_cond_2_2p_inform}
| {neg_would_cond_2_2p_formal}
| {neg_would_cond_2_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | counterfactual
! class="secondary" | positive
| {cfact_cond_1s}
| {cfact_cond_2s_inform}
| {cfact_cond_2s_formal}
| {cfact_cond_3s}
| {cfact_cond_1p}
| {cfact_cond_2p_inform}
| {cfact_cond_2p_formal}
| {cfact_cond_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_cfact_cond_1s}
| {neg_cfact_cond_2s_inform}
| {neg_cfact_cond_2s_formal}
| {neg_cfact_cond_3s}
| {neg_cfact_cond_1p}
| {neg_cfact_cond_2p_inform}
| {neg_cfact_cond_2p_formal}
| {neg_cfact_cond_3p}
|- style="border-top: 2px solid black;"
! rowspan="2" class="secondary" | ''if''
! class="secondary" | positive
| {if_cond_1s}
| {if_cond_2s_inform}
| {if_cond_2s_formal}
| {if_cond_3s}
| {if_cond_1p}
| {if_cond_2p_inform}
| {if_cond_2p_formal}
| {if_cond_3p}
|-
! class="secondary" style="background-color: var(--wikt-palette-blue-4);" | negative
| {neg_if_cond_1s}
| {neg_if_cond_2s_inform}
| {neg_if_cond_2s_formal}
| {neg_if_cond_3s}
| {neg_if_cond_1p}
| {neg_if_cond_2p_inform}
| {neg_if_cond_2p_formal}
| {neg_if_cond_3p}
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


local function infinitive_to_stem(inf)
	local stem = rsub(inf, "([үөуо])%1$", "")
	if stem == inf then
		stem = inf:gsub("ёо$", "й")
	end
	if stem == inf then
		stem = inf:gsub("юу$", "й")
	end
	if stem == inf then
		error(("Unable to compute stem from infinitive %s, doesn't end in long rounded vowel"):format(inf))
	end
	return stem
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
		stem = args.stem or infinitive_to_stem(lemma),
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
