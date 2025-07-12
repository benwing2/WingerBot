local export = {}

--[=[

Authorship: Ben Wing <benwing2>

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of case/number.
	 Example slot names for nouns are "gen_" (genitive singular) and
	 "voc_p" (vocative plural). Each slot is filled with zero or more forms.

-- "form" = The declined Kyrgyz form representing the value of a given slot.

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
local NAMESPACE = current_title.nsText
local PAGENAME = current_title.text

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

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end

-- version of rsubn() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
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

local letter_classes = {
	-- Subclasses of vowels. These are named after the predominant vowel of the associated suffix.
	a_type_vowel = "аыяюу", -- low or high back vowels
	e_type_vowel = "эие", -- front unrounded vowels
	o_type_vowel = "оё", -- mid back vowels
	oe_type_vowel = "өү", -- front rounded vowels
	y_type_vowel = "аыя", -- back unrounded vowels
	u_type_vowel = "оёюу", -- back rounded vowels
}

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

local cases = { "nom", "gen", "dat", "acc", "loc", "abl" }
local non_possessed_numbers = { "s", "p" }
local possessed_numbers = { "spos", "mpos" }
local person_number_possession = { "1s", "2s_inform", "2s_formal", "3", "1p", "2p_inform", "2p_formal" }

local person_number_possession_suffixes = {
	["1s"] = "им",
	["2s_inform"] = "иң",
	["2s_formal"] = "иңиз",
	["3"] = "Си",
	["1p"] = "ибиз",
	["2p_inform"] = "иңар",
	["2p_formal"] = "иңиздар",
}

local case_suffixes = {
	["nom"] = "",
	["gen"] = "Нин",
	["dat"] = "га", -- -а after 1s poss and 2s_inform poss, -на after 3 poss
	["acc"] = "Ни",
	["loc"] = "да", -- -нда after 3 poss
	["abl"] = "дан", -- -ндан after 3 poss?
}

local function make_noun_slots()
	for _, case in ipairs(cases) do
		for _, possessed in ipairs { false, true} do
			if possessed then
				for _, person_number in ipairs(person_number_possession) do
					for _, number in ipairs(possessed_numbers) do
						local tag = ("%s_%s_%s"):format(case, person_number, number)
						accel = tag:gsub("_", "|")
						noun_slots[tag] = accel
					end
				end
			else
				for _, number in ipairs(non_possessed_numbers) do
					local tag = ("%s_%s"):format(case, number)
					accel = tag:gsub("_", "|")
					noun_slots[tag] = accel
				end
			end
		end
	end
end

local noun_slots = make_noun_slots()


local function skip_slot(decl_spec, slot)
	return decl_spec.number == "sg" and rfind(slot, "_p$") or
		decl_spec.number == "pl" and rfind(slot, "_s$")
end


local function combine_stem_ending(stem, ending)
	if ending == "" then
		return stem
	end

	local split_suffix = rsplit(ending, "(" .. V  .. ")")
	local suffix_syls = {}
	for i, sufpart in ipairs(split_suffix) do
		if i == #sufpart and suffix_syls[1] or i % 2 == 0 then
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
			error(("Internal error: Ending '%s' has no vowel"):format(endsyl))
		end
		if endsyl_vowel ~= "и" and endsyl_vowel ~= "а" then
			error(("Internal error: All endsyl vowels should be high и or low а, but saw %s"):format(endsyl))
		end
		local harmony_table
		if first_endsyl_vowel == "и" then
			harmony_table = high_harmony_table
		else
			harmony_table = low_harmony_table
		end
		if endsyl_init == "" and stem_final_cons_cluster == "" then
			endsyl_vowel = ""
		else
			endsyl_vowel = harmony_table[ulower(stem_last_vowel)]
		end
		if endsyl_init == "Л" then
			if stem_final_cons_cluster == "" or rfind(stem_final_cons_cluster, "[" .. jr .. "]$") then
				endsyl_init = "л"
			else
				endsyl_init = "д"
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


local function decline_noun(decl_spec, lemma)
	local function make_form(stem, number, possession, case)
		local number_ending, possession_ending, case_ending
		if number == "s" then
			number_ending = ""
		else
			number_ending = "Лар"
		end
		possession_ending = possession and person_number_possession_suffixes[possession] or ""
		case_ending = case_suffixes[case]
		if case == "dat" then
			if possession == "1s" or possession == "2s_inform" then
				case_ending = "а"
			elseif possession == "3" then
				case_ending = "на"
			end
		elseif (case == "loc" or case == "abl") and possession == "3" then
			case_ending == "н" .. case_ending
		end
		return combine_stem_ending(combine_stem_ending(
			combine_stem_ending(stem, number_ending), possession_ending), case_ending)
	end

	local function add(slot, endings)
		if skip_slot(decl_spec, slot) then
			return
		end
		for class, second_endings in pairs(endings) do
			assert(letter_classes[class], "Unrecognized letter class " .. class)
			if rmatch(last_vowel, "[" .. letter_classes[class] .. "]") then
				for class2, ending in pairs(second_endings) do
					assert(letter_classes[class2], "Unrecognized letter class " .. class2)
					if rmatch(last_letter, "[" .. letter_classes[class2] .. "]") then
						iut.insert_form(decl_spec.forms, slot, {form=lemma .. ending})
						return
					end
				end
				error("Last letter '" .. last_letter .. "' of lemma '" .. lemma .. "' doesn't match any known letter class")
			end
		end
		error("Last vowel '" .. last_vowel .. "' of lemma '" .. lemma .. "' doesn't match any known letter class")
	end

	if not skip_slot(decl_spec, "nom_s") then
		iut.insert_form(decl_spec.forms, "nom_s", {form=lemma})
	end

	-- 1. There are two types of stem vowel harmony, based on the last stem vowel: a-e-o-oe (which always occurs when
	--    the first suffix vowel is low а/е/о/ө) vs. y-e-u-oe (which always occurs when the first suffix vowel is high
	--    ы/и/у/ү).
	-- 2. Endings can vary depending on the last sound of the stem in three possible ways:
	--    (a) vowel_or_jr vs. voiced_cons_not_jr vs. unvoiced_cons;
	--    (b) vowel vs. voiced_cons vs. unvoiced_cons;
	--    (c) consonant vs. vowel.
	-- 3. The following consonant suffix variations are found:
	--    (a) Ending variation 2(a) is only associated with the plural suffix -лар, where л after vowel_or_jr becomes д
	--        after voiced_cons_not_jr and т after unvoiced_cons.
	--    (b) Ending variation 2(b) is associated with endings in н- after a vowel, changing to д after a voiced_cons
	--        and т after an unvoiced_cons; or д or г after either vowel or voiced_cons, changing to the corresponding
	--        unvoiced consonant т or к after an unvoiced_cons.
	--    (c) Ending variation 2(c) is only associated with endings beginning with a high-harmonizing suffix vowel
	--        ы/и/у/ү, which disappears after a vowel-final stem.
	-- 4. The following types of vowel suffix variations are found:
	--    (a) low-harmonizing а/е/о/ө;
	--    (b) high-harmonizing ы/и/у/ү;
	--    (c) partial low-harmonizing а/е/а/ө.
	-- Based on this, we use capital letters in suffixes to indicate varying sounds and lowercase letters to indicate
	-- fixed sounds. Specifically:
	-- * Л: л/д/т variation.
	-- * Н: н/д/т variation.
	-- * Г: г/к variation.
	-- * Д: д/т variation.
	-- * О: low-harmonizing а/е/о/ө;
	-- * А: partial low-harmonizing а/е/а/ө;
	-- * У: high-harmonizing ы/и/у/ү.
	-- We automatically determine which letters should be capitalized: the first letter is always capitalized, as are
	-- all vowels. We also automatically determine whether to use a-e-o-oe vowel harmony or y-e-u-oe harmony based on
	-- the first vowel of the suffix.
	--
	-- We can analyze the suffixes further:
	-- 1. nom_s has no ending.
	-- 2. gen_s uses -нин after a vowel, -дин after a consonant with voicing assimilation.
	-- 3. dat_s uses -га with voicing assimilation. This drops to -а after 1s possessive -им, 2s informal possessive
	--    -иң) and changes to -на after 3 possessive -(с)и.
	-- 4. acc_s uses -ни after a vowel, -ди after a consonant with voicing assimilation.
	-- 5. loc_s uses -да with voicing assimilation. This changes to -нда after 3 possessive -(с)и.
	-- 6. abl_s uses -дан with voicing assimilation. FIXME: Does it change to -ндан after 3 possessive?
	-- 7. plural uses -лар after a vowel or й/р, -дар after a consonant with voicing assimilation.
	-- 8. 1s possessive uses -им after a consonant, dropping to -м after a vowel.
	-- 9. 2s informal possessive uses -иң after a consonant, dropping to -ң after a vowel.
	-- 10. 2s formal possessive uses -иңиз after a consonant, dropping to -ңиз after a vowel.
	-- 11. 3s/3p possessive uses -и after a consonant, -си after a vowel.
	-- 12. 1p uses -ибиз after a consonant, dropping to -биз after a vowel.
	-- 13. 2p informal possessive uses -иңар after a consonant, dropping to -ңар after a vowel.
	-- 14. 2p formal possessive uses -иңиздар after a consonant, dropping to -ңиздар after a vowel.
	add("nom_p", "лaр", "aeo", "vowel_or_jr")
	add("gen_s", "нун", "yeu", "vowel")
	add("gen_p", "лардун", "aeo", "vowel_or_jr")
	add("dat_s", "га", "aeo", "vowel")
	add("dat_p", "ларга", "aeo", "vowel_or_jr")
	add("acc_s", "ну", "yeu", "vowel")
	add("acc_p", "ларду", "aeo", "vowel_or_jr")
	add("loc_s", "да", "aeo", "vowel")
	add("loc_p", "ларда", "aeo", "vowel_or_jr")
	add("abl_s", "дан", "aeo", "vowel")
	add("abl_p", "лардан", "aeo", "vowel_or_jr")
	add("nom_1s_spos", "ум", "yeu", "consonant")
	add("nom_1s_mpos", "лорум", "aeo", "vowel_or_jr")
	add("gen_1s_spos", "умдун", "yeu", "consonant")
	add("gen_1s_mpos", "лорумдун", "aeo", "vowel_or_jr")
	add("dat_1s_spos", "ума", "yeu", "consonant")
	add("dat_1s_mpos", "лорума", "aeo", "vowel_or_jr")
	add("acc_1s_spos", "умду", "yeu", "consonant")
	add("acc_1s_mpos", "лорумду", "aeo", "vowel_or_jr")
	add("loc_1s_spos", "умда", "yeu", "consonant")
	add("loc_1s_mpos", "лорумда", "aeo", "vowel_or_jr")
	add("abl_1s_spos", "умдан", "yeu", "consonant")
	add("abl_1s_mpos", "лорумдан", "aeo", "vowel_or_jr")
	add("nom_2s_inform_spos", "уң", "yeu", "consonant")
	add("nom_2s_inform_mpos", "лоруң", "aeo", "vowel_or_jr")
	add("gen_2s_inform_spos", "уңдун", "yeu", "consonant")
    add("gen_2s_inform_mpos", "лоруңдун", "aeo", "vowel_or_jr")
	add("dat_2s_inform_spos", "уңа", "yeu", "consonant")
	add("dat_2s_inform_mpos", "лоруңа", "aeo", "vowel_or_jr")
	add("acc_2s_inform_spos", "уңду", "yeu", "consonant")
	add("acc_2s_inform_mpos", "лоруңду", "aeo", "vowel_or_jr")
	add("loc_2s_inform_spos", "уңда", "yeu", "consonant")
	add("loc_2s_inform_mpos", "лоруңда", "aeo", "vowel_or_jr")
	add("abl_2s_inform_spos", "уңдан", "yeu", "consonant")
	add("abl_2s_inform_mpos", "лоруңдан", "aeo", "vowel_or_jr")
	add("nom_2s_formal_spos", "уңуз", "yeu", "consonant")
	add("nom_2s_formal_mpos", "лоруңуз", "aeo", "vowel_or_jr")
	add("gen_2s_formal_spos", "уңуздун", "yeu",  "consonant")
    add("gen_2s_formal_mpos", "лоруңуздун", "aeo", "vowel_or_jr")
	add("dat_2s_formal_spos", "уңузга", "yeu", "consonant")
	add("dat_2s_formal_mpos", "лоруңузга", "aeo", "vowel_or_jr")
	add("acc_2s_formal_spos", "уңузду", "yeu", "consonant")
	add("acc_2s_formal_mpos", "лоруңузду", "aeo", "vowel_or_jr")
	add("loc_2s_formal_spos", "уңузда", "yeu", "consonant")
	add("loc_2s_formal_mpos", "лоруңузда", "aeo", "vowel_or_jr")
	add("abl_2s_formal_spos", "уңуздан", "yeu", "consonant")
	add("abl_2s_formal_mpos", "лоруңуздан", "aeo", "vowel_or_jr")
end


-- Compute the categories to add the noun to, as well as the annotation to display in the
-- declension title bar. We combine the code to do these functions as both categories and
-- title bar contain similar information.
local function compute_categories_and_annotation(decl_spec)
	local cats = {}
	local function insert(cattype)
		m_table.insertIfNot(cats, "Kyrgyz " .. cattype)
	end
	if decl_spec.number == "sg" then
		insert("uncountable nouns")
	elseif decl_spec.number == "pl" then
		insert("pluralia tantum")
	end
	decl_spec.annotation =
		decl_spec.number == "sg" and "sg-only" or
		decl_spec.number == "pl" and "pl-only" or
		""
	decl_spec.categories = cats
end


local function show_forms(decl_spec)
	local lemmas = {}
	if decl_spec.forms.nom_s then
		for _, nom_s in ipairs(decl_spec.forms.nom_s) do
			table.insert(lemmas, nom_s.form)
		end
	elseif decl_spec.forms.nom_p then
		for _, nom_p in ipairs(decl_spec.forms.nom_p) do
			table.insert(lemmas, nom_p.form)
		end
	end
	local props = {
		lemmas = lemmas,
		slot_table = noun_slots,
		lang = lang,
		include_translit = true,
	}
	iut.show_forms(decl_spec.forms, props)
end


local function make_table(decl_spec)
	local forms = decl_spec.forms

	local header = mw.getCurrentFrame():expandTemplate{
		title = 'inflection-table-top',
		args = {
			title = '{title}{annotation}',
			palette = 'blue',
			tall = 'yes',
			class = 'tr-alongside', -- hack to suppress excess space below each term
		}
	}

	local table_spec_both = [=[
!
! singular<br>{jekelik}
! plural<br>{koeptoegoen}
|-
! nominative {atooch}
| {nom_s}
| {nom_p}
|-
! genitive {ilik}
| {gen_s}
| {gen_p}
|-
! dative {barysh}
| {dat_s}
| {dat_p}
|-
! accusative {tabysh}
| {acc_s}
| {acc_p}
|-
! locative {jatysh}
| {loc_s}
| {loc_p}
|-
! ablative {chygysh}
| {abl_s}
| {abl_p}
|-
| class="separator" colspan="999" |
|-
! class="outer" colspan="3" | possessive forms
|-
! 
! colspan="2" | first-person singular<br>{menin}
|-
! nominative
| {nom_1s_spos}
| {nom_1s_mpos}
|-
! genitive
| {gen_1s_spos}
| {gen_1s_mpos}
|-
! dative
| {dat_1s_spos}
| {dat_1s_mpos}
|-
! accusative
| {acc_1s_spos}
| {acc_1s_mpos}
|-
! locative
| {loc_1s_spos}
| {loc_1s_mpos}
|-
! ablative
| {abl_1s_spos}
| {abl_1s_mpos}
|-
! 
!colspan="2" | second-person singular informal<br>{senin}
|-
! nominative
| {nom_2s_inform_spos}
| {nom_2s_inform_mpos}
|-
! genitive
| {gen_2s_inform_spos}
| {gen_2s_inform_mpos}
|-
! dative
| {dat_2s_inform_spos}
| {dat_2s_inform_mpos}
|-
! accusative
| {acc_2s_inform_spos}
| {acc_2s_inform_mpos}
|-
! locative
| {loc_2s_inform_spos}
| {loc_2s_inform_mpos}
|-
! ablative
| {abl_2s_inform_spos}
| {abl_2s_inform_mpos}
|-
! 
!colspan="2" | second-person singular formal<br>{sizdin}
|-
! nominative
| {nom_2s_formal_spos}
| {nom_2s_formal_mpos}
|-
! genitive
| {gen_2s_formal_spos}
| {gen_2s_formal_mpos}
|-
! dative
| {dat_2s_formal_spos}
| {dat_2s_formal_mpos}
|-
! accusative
| {acc_2s_formal_spos}
| {acc_2s_formal_mpos}
|-
! locative
| {loc_2s_formal_spos}
| {loc_2s_formal_mpos}
|-
! ablative
| {abl_2s_formal_spos}
| {abl_2s_formal_mpos}
]=]

	local table_spec_sg = [=[
!
! singular<br>{jekelik}
|-
! nominative {atooch}
| {nom_s}
|-
! genitive {ilik}
| {gen_s}
|-
! dative {barysh}
| {dat_s}
|-
! accusative {tabysh}
| {acc_s}
|-
! locative {jatysh}
| {loc_s}
|-
! ablative {chygysh}
| {abl_s}
|-
| class="separator" colspan="999" |
|-
! class="outer" colspan="2" | possessive forms
|-
! 
! first-person singular<br>{menin}
|-
! nominative
| {nom_1s_spos}
|-
! genitive
| {gen_1s_spos}
|-
! dative
| {dat_1s_spos}
|-
! accusative
| {acc_1s_spos}
|-
! locative
| {loc_1s_spos}
|-
! ablative
| {abl_1s_spos}
|-
! 
! second-person singular informal<br>{senin}
|-
! nominative
| {nom_2s_inform_spos}
|-
! genitive
| {gen_2s_inform_spos}
|-
! dative
| {dat_2s_inform_spos}
|-
! accusative
| {acc_2s_inform_spos}
|-
! locative
| {loc_2s_inform_spos}
|-
! ablative
| {abl_2s_inform_spos}
|-
! 
! second-person singular formal<br>{sizdin}
|-
! nominative
| {nom_2s_formal_spos}
|-
! genitive
| {gen_2s_formal_spos}
|-
! dative
| {dat_2s_formal_spos}
|-
! accusative
| {acc_2s_formal_spos}
|-
! locative
| {loc_2s_formal_spos}
|-
! ablative
| {abl_2s_formal_spos}
]=]

	local table_spec_pl = [=[
!
! plural<br>{koeptoegoen}
|-
! nominative {atooch}
| {nom_p}
|-
! genitive {ilik}
| {gen_p}
|-
! dative {barysh}
| {dat_p}
|-
! accusative {tabysh}
| {acc_p}
|-
! locative {jatysh}
| {loc_p}
|-
! ablative {chygysh}
| {abl_p}
|-
| class="separator" colspan="999" |
|-
! class="outer" colspan="2" | possessive forms
|-
! 
! first-person singular<br>{menin}
|-
! nominative
| {nom_1s_mpos}
|-
! genitive
| {gen_1s_mpos}
|-
! dative
| {dat_1s_mpos}
|-
! accusative
| {acc_1s_mpos}
|-
! locative
| {loc_1s_mpos}
|-
! ablative
| {abl_1s_mpos}
|-
! 
! second-person singular informal<br>{senin}
|-
! nominative
| {nom_2s_inform_mpos}
|-
! genitive
| {gen_2s_inform_mpos}
|-
! dative
| {dat_2s_inform_mpos}
|-
! accusative
| {acc_2s_inform_mpos}
|-
! locative
| {loc_2s_inform_mpos}
|-
! ablative
| {abl_2s_inform_mpos}
|-
! 
! second-person singular formal<br>{sizdin}
|-
! nominative
| {nom_2s_formal_mpos}
|-
! genitive
| {gen_2s_formal_mpos}
|-
! dative
| {dat_2s_formal_mpos}
|-
! accusative
| {acc_2s_formal_mpos}
|-
! locative
| {loc_2s_formal_mpos}
|-
! ablative
| {abl_2s_formal_mpos}
]=]

	local footer = mw.getCurrentFrame():expandTemplate{ title = 'inflection-table-bottom' }

	if decl_spec.title then
		forms.title = decl_spec.title
	else
		forms.title = 'Declension of <i lang="ky" class="Cyrl">' .. forms.lemma .. '</i>'
	end

	local function make_text_smaller(text)
		return "(<span style=\"font-size: smaller;\">" .. text .. "</span>)"
	end

	local annotation = decl_spec.annotation
	if annotation == "" then
		forms.annotation = ""
	else
		forms.annotation = " " .. make_text_smaller(annotation)
	end

	local function tag_text(text)
		return make_text_smaller(m_script_utilities.tag_text(text, lang))
	end

	-- grammatical terms used in the table
	forms.jekelik = tag_text("жекелик")
	forms.koeptoegoen = tag_text("көптөгөн")
	forms.atooch = tag_text("атооч")
	forms.ilik = tag_text("илик")
	forms.barysh = tag_text("барыш")
	forms.tabysh = tag_text("табыш")
	forms.jatysh = tag_text("жатыш")
	forms.chygysh = tag_text("чыгыш")
	forms.menin = tag_text("менин")
	forms.senin = tag_text("сенин")
	forms.sizdin = tag_text("сиздин")

	local table_spec =
		decl_spec.number == "sg" and table_spec_sg or
		decl_spec.number == "pl" and table_spec_pl or
		table_spec_both
	return m_string_utilities.format(header .. table_spec .. footer, forms)
end


-- Externally callable function to parse and decline a noun where all forms
-- are given manually. Return value is WORD_SPEC, an object where the declined
-- forms are in `WORD_SPEC.forms` for each slot. If there are no values for a
-- slot, the slot key will be missing. The value for a given slot is a list of
-- objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(parent_args, number)
	if number ~= "sg" and number ~= "pl" and number ~= "both" then
		error("Internal error: number (arg 1) must be 'sg', 'pl' or 'both': '" .. number .. "'")
	end

	local params = {
		[1] = {},
		title = {},
	}

	local args = m_para.process(parent_args, params)
	local decl_spec = {
		title = args.title,
		forms = {},
		number = number,
	}
	local lemma = args[1] or PAGENAME
	if number == "pl" then
		local sg_lemma = rmatch(lemma, "(.*)[дтл][аеоө]р$")
		if not sg_lemma then
			error("Plural lemma doesn't end with nominative plural ending (-лар, -дер, -тор, etc.): " .. lemma)
		end
		lemma = sg_lemma
	end
	decline_noun(decl_spec, lemma)
	compute_categories_and_annotation(decl_spec)
	return decl_spec
end


-- Entry point for {{ky-decl-noun}}, {{ky-decl-noun-sg}} and {{ky-decl-noun-pl}}.
function export.show(frame)
	local iparams = {
		[1] = {required = true},
	}
	local iargs = m_para.process(frame.args, iparams)
	local parent_args = frame:getParent().args
	local decl_spec = export.do_generate_forms(parent_args, iargs[1])
	show_forms(decl_spec)
	return make_table(decl_spec) .. require("Module:utilities").format_categories(decl_spec.categories, lang)
end

return export
