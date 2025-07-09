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
local rsplit = mw.text.split
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rgmatch = mw.ustring.gmatch
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local usub = mw.ustring.sub
local uupper = mw.ustring.upper
local ulower = mw.ustring.lower

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


local vowel = "аоөүуыэяёюие"
local vowel_c = "[" .. vowel .. "]"

local jr = "йр"
local voiced_cons_not_jr = "дмлнңбвгжз"
local unvoiced_cons = "кпстфхчцшщ"

letter_classes = {
	-- Subclasses of vowels. These are named after the predominant vowel of the associated suffix.
	a_type_vowel = "аыяюу", -- low or high back vowels
	e_type_vowel = "эие", -- front unrounded vowels
	o_type_vowel = "оё", -- mid back vowels
	oe_type_vowel = "өү", -- front rounded vowels
	y_type_vowel = "аыя", -- back unrounded vowels
	u_type_vowel = "оёюу", -- back rounded vowels

	-- Subclasses of final letters.
	consonant = unvoiced_cons .. voiced_cons_not_jr .. jr,
	vowel = vowel,
	vowel_or_jr = vowel .. jr,
	voiced_cons_not_jr = voiced_cons_not_jr,
	voiced_cons = voiced_cons_not_jr .. jr,
	unvoiced_cons = unvoiced_cons,
}


local output_noun_slots = {
	nom_s = "nom|s",
	gen_s = "gen|s",
	dat_s = "dat|s",
	acc_s = "acc|s",
	loc_s = "loc|s",
	abl_s = "abl|s",
	nom_p = "nom|p",
	gen_p = "gen|p",
	dat_p = "dat|p",
	acc_p = "acc|p",
	loc_p = "loc|p",
	abl_p = "abl|p",
	nom_1s_spos = "nom|1s|spos",
	gen_1s_spos = "gen|1s|spos",
	dat_1s_spos = "dat|1s|spos",
	acc_1s_spos = "acc|1s|spos",
	loc_1s_spos = "loc|1s|spos",
	abl_1s_spos = "abl|1s|spos",
	nom_1s_mpos = "nom|1s|mpos",
	gen_1s_mpos = "gen|1s|mpos",
	dat_1s_mpos = "dat|1s|mpos",
	acc_1s_mpos = "acc|1s|mpos",
	loc_1s_mpos = "loc|1s|mpos",
	abl_1s_mpos = "abl|1s|mpos",
	nom_2s_inform_spos = "nom|2s|inform|spos",
	gen_2s_inform_spos = "gen|2s|inform|spos",
	dat_2s_inform_spos = "dat|2s|inform|spos",
	acc_2s_inform_spos = "acc|2s|inform|spos",
	loc_2s_inform_spos = "loc|2s|inform|spos",
	abl_2s_inform_spos = "abl|2s|inform|spos",
	nom_2s_inform_mpos = "nom|2s|inform|mpos",
	gen_2s_inform_mpos = "gen|2s|inform|mpos",
	dat_2s_inform_mpos = "dat|2s|inform|mpos",
	acc_2s_inform_mpos = "acc|2s|inform|mpos",
	loc_2s_inform_mpos = "loc|2s|inform|mpos",
	abl_2s_inform_mpos = "abl|2s|inform|mpos",
	nom_2s_formal_spos = "nom|2s|formal|spos",
	gen_2s_formal_spos = "gen|2s|formal|spos",
	dat_2s_formal_spos = "dat|2s|formal|spos",
	acc_2s_formal_spos = "acc|2s|formal|spos",
	loc_2s_formal_spos = "loc|2s|formal|spos",
	abl_2s_formal_spos = "abl|2s|formal|spos",
	nom_2s_formal_mpos = "nom|2s|formal|spos",
	gen_2s_formal_mpos = "gen|2s|formal|spos",
	dat_2s_formal_mpos = "dat|2s|formal|spos",
	acc_2s_formal_mpos = "acc|2s|formal|spos",
	loc_2s_formal_mpos = "loc|2s|formal|spos",
	abl_2s_formal_mpos = "abl|2s|formal|spos",
}


local function skip_slot(decl_spec, slot)
	return decl_spec.number == "sg" and rfind(slot, "_p$") or
		decl_spec.number == "pl" and rfind(slot, "_s$")
end


local function decline_noun(decl_spec, lemma)
	local lowercase_lemma = ulower(lemma)
	local last_letter = usub(lowercase_lemma, -1)
	local last_vowel = rsub(lowercase_lemma, "^.*(" .. vowel_c .. ").-$", "%1")

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

	add("nom_p", {
		a_type_vowel = { vowel_or_jr = "лар", voiced_cons_not_jr = "дар", unvoiced_cons = "тар" },
		e_type_vowel = { vowel_or_jr = "лер", voiced_cons_not_jr = "дер", unvoiced_cons = "тер" },
		o_type_vowel = { vowel_or_jr = "лор", voiced_cons_not_jr = "дор", unvoiced_cons = "тор" },
		oe_type_vowel = { vowel_or_jr = "лөр", voiced_cons_not_jr = "дөр", unvoiced_cons = "төр" },
	})
	add("gen_s", {
		y_type_vowel = { vowel = "нын", voiced_cons = "дын", unvoiced_cons = "тын" },
		e_type_vowel = { vowel = "нин", voiced_cons = "дин", unvoiced_cons = "тин" },
		u_type_vowel = { vowel = "нун", voiced_cons = "дун", unvoiced_cons = "тун" },
		oe_type_vowel = { vowel = "нүн", voiced_cons = "дүн", unvoiced_cons = "түн" },
	})
    add("gen_p", {
        a_type_vowel = { vowel_or_jr = "лардын", voiced_cons_not_jr = "дардын", unvoiced_cons = "тардын" },
        e_type_vowel = { vowel_or_jr = "лердин", voiced_cons_not_jr = "дердин", unvoiced_cons = "тердин" },
        o_type_vowel = { vowel_or_jr = "лордун", voiced_cons_not_jr = "дордун", unvoiced_cons = "тордун" },
        oe_type_vowel = { vowel_or_jr = "лөрдүн", voiced_cons_not_jr = "дөрдүн", unvoiced_cons = "төрдүн" },
    })
	add("dat_s", {
		a_type_vowel = { vowel = "га", voiced_cons = "га", unvoiced_cons = "ка" },
		e_type_vowel = { vowel = "ге", voiced_cons = "ге", unvoiced_cons = "ке" },
		o_type_vowel = { vowel = "го", voiced_cons = "го", unvoiced_cons = "ко" },
		oe_type_vowel = { vowel = "гө", voiced_cons = "гө", unvoiced_cons = "кө" },
	})
	add("dat_p", {
		a_type_vowel = { vowel_or_jr = "ларга", voiced_cons_not_jr = "дарга", unvoiced_cons = "тарга" },
		e_type_vowel = { vowel_or_jr = "лерге", voiced_cons_not_jr = "дерге", unvoiced_cons = "терге" },
		o_type_vowel = { vowel_or_jr = "лорго", voiced_cons_not_jr = "дорго", unvoiced_cons = "торго" },
		oe_type_vowel = { vowel_or_jr = "лөргө", voiced_cons_not_jr = "дөргө", unvoiced_cons = "төргө" },
	})
	add("acc_s", {
		y_type_vowel = { vowel = "ны", voiced_cons = "ды", unvoiced_cons = "ты" },
		e_type_vowel = { vowel = "ни", voiced_cons = "ди", unvoiced_cons = "ти" },
		u_type_vowel = { vowel = "ну", voiced_cons = "ду", unvoiced_cons = "ту" },
		oe_type_vowel = { vowel = "нү", voiced_cons = "дү", unvoiced_cons = "тү" },
	})
	add("acc_p", {
		a_type_vowel = { vowel_or_jr = "ларды", voiced_cons_not_jr = "дарды", unvoiced_cons = "тарды" },
		e_type_vowel = { vowel_or_jr = "лерди", voiced_cons_not_jr = "дерди", unvoiced_cons = "терди" },
		o_type_vowel = { vowel_or_jr = "лорду", voiced_cons_not_jr = "дорду", unvoiced_cons = "торду" },
		oe_type_vowel = { vowel_or_jr = "лөрдү", voiced_cons_not_jr = "дөрдү", unvoiced_cons = "төрдү" },
	})
	add("loc_s", {
		a_type_vowel = { vowel = "да", voiced_cons = "да", unvoiced_cons = "та" },
		e_type_vowel = { vowel = "де", voiced_cons = "де", unvoiced_cons = "те" },
		o_type_vowel = { vowel = "до", voiced_cons = "до", unvoiced_cons = "то" },
		oe_type_vowel = { vowel = "дө", voiced_cons = "дө", unvoiced_cons = "тө" },
	})
	add("loc_p", {
		a_type_vowel = { vowel_or_jr = "ларда", voiced_cons_not_jr = "дарда", unvoiced_cons = "тарда" },
		e_type_vowel = { vowel_or_jr = "лерде", voiced_cons_not_jr = "дерде", unvoiced_cons = "терде" },
		o_type_vowel = { vowel_or_jr = "лордо", voiced_cons_not_jr = "дордо", unvoiced_cons = "тордо" },
		oe_type_vowel = { vowel_or_jr = "лөрдө", voiced_cons_not_jr = "дөрдө", unvoiced_cons = "төрдө" },
	})
	add("abl_s", {
		a_type_vowel = { vowel = "дан", voiced_cons = "дан", unvoiced_cons = "тан" },
		e_type_vowel = { vowel = "ден", voiced_cons = "ден", unvoiced_cons = "тен" },
		o_type_vowel = { vowel = "дон", voiced_cons = "дон", unvoiced_cons = "тон" },
		oe_type_vowel = { vowel = "дөн", voiced_cons = "дөн", unvoiced_cons = "төн" },
	})
	add("abl_p", {
		a_type_vowel = { vowel_or_jr = "лардан", voiced_cons_not_jr = "дардан", unvoiced_cons = "тардан" },
		e_type_vowel = { vowel_or_jr = "лерден", voiced_cons_not_jr = "дерден", unvoiced_cons = "терден" },
		o_type_vowel = { vowel_or_jr = "лордон", voiced_cons_not_jr = "дордон", unvoiced_cons = "тордон" },
		oe_type_vowel = { vowel_or_jr = "лөрдөн", voiced_cons_not_jr = "дөрдөн", unvoiced_cons = "төрдөн" },
	})
	add("nom_1s_spos", {
		y_type_vowel = { consonant = "ым", vowel = "м" },
		e_type_vowel = { consonant = "им", vowel = "м" },
		u_type_vowel = { consonant = "ум", vowel = "м" },
		oe_type_vowel = { consonant = "үм", vowel = "м" },
	})
	add("nom_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларым", voiced_cons_not_jr = "дарым", unvoiced_cons = "тарым" },
		e_type_vowel = { vowel_or_jr = "лерим", voiced_cons_not_jr = "дерим", unvoiced_cons = "терим" },
		o_type_vowel = { vowel_or_jr = "лорум", voiced_cons_not_jr = "дорум", unvoiced_cons = "торум" },
		oe_type_vowel = { vowel_or_jr = "лөрүм", voiced_cons_not_jr = "дөрүм", unvoiced_cons = "төрүм" },
	})
	add("gen_1s_spos", {
		y_type_vowel = { consonant = "ымдын", vowel = "мдын" },
		e_type_vowel = { consonant = "имдин", vowel = "мдин" },
		u_type_vowel = { consonant = "умдун", vowel = "мдун" },
		oe_type_vowel = { consonant = "үмдүн", vowel = "мдүн" },
	})
    add("gen_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларымдын", voiced_cons_not_jr = "дарымдын", unvoiced_cons = "тарымдын" },
		e_type_vowel = { vowel_or_jr = "леримдин", voiced_cons_not_jr = "деримдин", unvoiced_cons = "теримдин" },
		o_type_vowel = { vowel_or_jr = "лорумдун", voiced_cons_not_jr = "дорумдун", unvoiced_cons = "торумдун" },
		oe_type_vowel = { vowel_or_jr = "лөрүмдүн", voiced_cons_not_jr = "дөрүмдүн", unvoiced_cons = "төрүмдүн" },
    })
	add("dat_1s_spos", {
		y_type_vowel = { consonant = "ыма", vowel = "ма" },
		e_type_vowel = { consonant = "име", vowel = "ме" },
		u_type_vowel = { consonant = "ума", vowel = "ма" },
		oe_type_vowel = { consonant = "үмө", vowel = "мө" },
	})
	add("dat_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыма", voiced_cons_not_jr = "дарыма", unvoiced_cons = "тарыма" },
		e_type_vowel = { vowel_or_jr = "лериме", voiced_cons_not_jr = "дериме", unvoiced_cons = "териме" },
		o_type_vowel = { vowel_or_jr = "лорума", voiced_cons_not_jr = "дорума", unvoiced_cons = "торума" },
		oe_type_vowel = { vowel_or_jr = "лөрүмө", voiced_cons_not_jr = "дөрүмө", unvoiced_cons = "төрүмө" },
	})
	add("acc_1s_spos", {
		y_type_vowel = { consonant = "ымды", vowel = "мды" },
		e_type_vowel = { consonant = "имди", vowel = "мди" },
		u_type_vowel = { consonant = "умду", vowel = "мду" },
		oe_type_vowel = { consonant = "үмдү", vowel = "мдү" },
	})
	add("acc_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларымды", voiced_cons_not_jr = "дарымды", unvoiced_cons = "тарымды" },
		e_type_vowel = { vowel_or_jr = "леримди", voiced_cons_not_jr = "деримди", unvoiced_cons = "теримди" },
		o_type_vowel = { vowel_or_jr = "лорумду", voiced_cons_not_jr = "дорумду", unvoiced_cons = "торумду" },
		oe_type_vowel = { vowel_or_jr = "лөрүмдү", voiced_cons_not_jr = "дөрүмдү", unvoiced_cons = "төрүмдү" },
	})
	add("loc_1s_spos", {
		y_type_vowel = { consonant = "ымда", vowel = "мда" },
		e_type_vowel = { consonant = "имде", vowel = "мде" },
		u_type_vowel = { consonant = "умда", vowel = "мда" },
		oe_type_vowel = { consonant = "үмдө", vowel = "мдө" },
	})
	add("loc_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларымда", voiced_cons_not_jr = "дарымда", unvoiced_cons = "тарымда" },
		e_type_vowel = { vowel_or_jr = "леримде", voiced_cons_not_jr = "деримде", unvoiced_cons = "теримде" },
		o_type_vowel = { vowel_or_jr = "лорумда", voiced_cons_not_jr = "дорумда", unvoiced_cons = "торумда" },
		oe_type_vowel = { vowel_or_jr = "лөрүмдө", voiced_cons_not_jr = "дөрүмдө", unvoiced_cons = "төрүмдө" },
	})
	add("abl_1s_spos", {
		y_type_vowel = { consonant = "ымдан", vowel = "мдан" },
		e_type_vowel = { consonant = "имден", vowel = "мден" },
		u_type_vowel = { consonant = "умдан", vowel = "мдан" },
		oe_type_vowel = { consonant = "үмдөн", vowel = "мдөн" },
	})
	add("abl_1s_mpos", {
		a_type_vowel = { vowel_or_jr = "ларымдан", voiced_cons_not_jr = "дарымдан", unvoiced_cons = "тарымдан" },
		e_type_vowel = { vowel_or_jr = "леримден", voiced_cons_not_jr = "деримден", unvoiced_cons = "теримден" },
		o_type_vowel = { vowel_or_jr = "лорумдан", voiced_cons_not_jr = "дорумдан", unvoiced_cons = "торумдан" },
		oe_type_vowel = { vowel_or_jr = "лөрүмдөн", voiced_cons_not_jr = "дөрүмдөн", unvoiced_cons = "төрүмдөн" },
	})
	add("nom_2s_inform_spos", {
		y_type_vowel = { consonant = "ың", vowel = "ң" },
		e_type_vowel = { consonant = "иң", vowel = "ң" },
		u_type_vowel = { consonant = "уң", vowel = "ң" },
		oe_type_vowel = { consonant = "үң", vowel = "ң" },
	})
	add("nom_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларың", voiced_cons_not_jr = "дарың", unvoiced_cons = "тарың" },
		e_type_vowel = { vowel_or_jr = "лериң", voiced_cons_not_jr = "дериң", unvoiced_cons = "териң" },
		o_type_vowel = { vowel_or_jr = "лоруң", voiced_cons_not_jr = "доруң", unvoiced_cons = "торуң" },
		oe_type_vowel = { vowel_or_jr = "лөрүң", voiced_cons_not_jr = "дөрүң", unvoiced_cons = "төрүң" },
	})
	add("gen_2s_inform_spos", {
		y_type_vowel = { consonant = "ыңдын", vowel = "ңдын" },
		e_type_vowel = { consonant = "иңдин", vowel = "ңдин" },
		u_type_vowel = { consonant = "уңдун", vowel = "ңдун" },
		oe_type_vowel = { consonant = "үңдүн", vowel = "ңдүн" },
	})
    add("gen_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңдын", voiced_cons_not_jr = "дарыңдын", unvoiced_cons = "тарыңдын" },
		e_type_vowel = { vowel_or_jr = "лериңдин", voiced_cons_not_jr = "дериңдин", unvoiced_cons = "териңдин" },
		o_type_vowel = { vowel_or_jr = "лоруңдун", voiced_cons_not_jr = "доруңдун", unvoiced_cons = "торуңдун" },
		oe_type_vowel = { vowel_or_jr = "лөрүңдүн", voiced_cons_not_jr = "дөрүңдүн", unvoiced_cons = "төрүңдүн" },
    })
	add("dat_2s_inform_spos", {
		y_type_vowel = { consonant = "ыңа", vowel = "ңа" },
		e_type_vowel = { consonant = "иңе", vowel = "ңе" },
		u_type_vowel = { consonant = "уңа", vowel = "ңа" },
		oe_type_vowel = { consonant = "үңө", vowel = "ңө" },
	})
	add("dat_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңа", voiced_cons_not_jr = "дарыңа", unvoiced_cons = "тарыңа" },
		e_type_vowel = { vowel_or_jr = "лериңе", voiced_cons_not_jr = "дериңе", unvoiced_cons = "териңе" },
		o_type_vowel = { vowel_or_jr = "лоруңа", voiced_cons_not_jr = "доруңа", unvoiced_cons = "торуңа" },
		oe_type_vowel = { vowel_or_jr = "лөрүңө", voiced_cons_not_jr = "дөрүңө", unvoiced_cons = "төрүңө" },
	})
	add("acc_2s_inform_spos", {
		y_type_vowel = { consonant = "ыңды", vowel = "ңды" },
		e_type_vowel = { consonant = "иңди", vowel = "ңди" },
		u_type_vowel = { consonant = "уңду", vowel = "ңду" },
		oe_type_vowel = { consonant = "үңдү", vowel = "ңдү" },
	})
	add("acc_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңды", voiced_cons_not_jr = "дарыңды", unvoiced_cons = "тарыңды" },
		e_type_vowel = { vowel_or_jr = "лериңди", voiced_cons_not_jr = "дериңди", unvoiced_cons = "териңди" },
		o_type_vowel = { vowel_or_jr = "лоруңду", voiced_cons_not_jr = "доруңду", unvoiced_cons = "торуңду" },
		oe_type_vowel = { vowel_or_jr = "лөрүңдү", voiced_cons_not_jr = "дөрүңдү", unvoiced_cons = "төрүңдү" },
	})
	add("loc_2s_inform_spos", {
		y_type_vowel = { consonant = "ыңда", vowel = "ңда" },
		e_type_vowel = { consonant = "иңде", vowel = "ңде" },
		u_type_vowel = { consonant = "уңда", vowel = "ңда" },
		oe_type_vowel = { consonant = "үңдө", vowel = "ңдө" },
	})
	add("loc_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңда", voiced_cons_not_jr = "дарыңда", unvoiced_cons = "тарыңда" },
		e_type_vowel = { vowel_or_jr = "лериңде", voiced_cons_not_jr = "дериңде", unvoiced_cons = "териңде" },
		o_type_vowel = { vowel_or_jr = "лоруңда", voiced_cons_not_jr = "доруңда", unvoiced_cons = "торуңда" },
		oe_type_vowel = { vowel_or_jr = "лөрүңдө", voiced_cons_not_jr = "дөрүңдө", unvoiced_cons = "төрүңдө" },
	})
	add("abl_2s_inform_spos", {
		y_type_vowel = { consonant = "ыңдан", vowel = "ңдан" },
		e_type_vowel = { consonant = "иңден", vowel = "ңден" },
		u_type_vowel = { consonant = "уңдан", vowel = "ңдан" },
		oe_type_vowel = { consonant = "үңдөн", vowel = "ңдөн" },
	})
	add("abl_2s_inform_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңдан", voiced_cons_not_jr = "дарыңдан", unvoiced_cons = "тарыңдан" },
		e_type_vowel = { vowel_or_jr = "лериңден", voiced_cons_not_jr = "дериңден", unvoiced_cons = "териңден" },
		o_type_vowel = { vowel_or_jr = "лоруңдан", voiced_cons_not_jr = "доруңдан", unvoiced_cons = "торуңдан" },
		oe_type_vowel = { vowel_or_jr = "лөрүңдөн", voiced_cons_not_jr = "дөрүңдөн", unvoiced_cons = "төрүңдөн" },
	})
	add("nom_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңыз", vowel = "ңыз" },
		e_type_vowel = { consonant = "иңиз", vowel = "ңиз" },
		u_type_vowel = { consonant = "уңуз", vowel = "ңуз" },
		oe_type_vowel = { consonant = "үңүз", vowel = "ңүз" },
	})
	add("nom_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңыз", voiced_cons_not_jr = "дарыңыз", unvoiced_cons = "тарыңыз" },
		e_type_vowel = { vowel_or_jr = "лериңиз", voiced_cons_not_jr = "дериңиз", unvoiced_cons = "териңиз" },
		o_type_vowel = { vowel_or_jr = "лоруңуз", voiced_cons_not_jr = "доруңуз", unvoiced_cons = "торуңуз" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүз", voiced_cons_not_jr = "дөрүңүз", unvoiced_cons = "төрүңүз" },
	})
	add("gen_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңыздын", vowel = "ңыздын" },
		e_type_vowel = { consonant = "иңиздин", vowel = "ңиздин" },
		u_type_vowel = { consonant = "уңуздун", vowel = "ңуздун" },
		oe_type_vowel = { consonant = "үңүздүн", vowel = "ңүздүн" },
	})
    add("gen_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңыздын", voiced_cons_not_jr = "дарыңыздын", unvoiced_cons = "тарыңыздын" },
		e_type_vowel = { vowel_or_jr = "лериңиздин", voiced_cons_not_jr = "дериңиздин", unvoiced_cons = "териңиздин" },
		o_type_vowel = { vowel_or_jr = "лоруңуздун", voiced_cons_not_jr = "доруңуздун", unvoiced_cons = "торуңуздун" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүздүн", voiced_cons_not_jr = "дөрүңүздүн", unvoiced_cons = "төрүңүздүн" },
    })
	add("dat_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңызга", vowel = "ңызга" },
		e_type_vowel = { consonant = "иңизге", vowel = "ңизге" },
		u_type_vowel = { consonant = "уңузга", vowel = "ңузга" },
		oe_type_vowel = { consonant = "үңүзгө", vowel = "ңүзгө" },
	})
	add("dat_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңызга", voiced_cons_not_jr = "дарыңызга", unvoiced_cons = "тарыңызга" },
		e_type_vowel = { vowel_or_jr = "лериңизге", voiced_cons_not_jr = "дериңизге", unvoiced_cons = "териңизге" },
		o_type_vowel = { vowel_or_jr = "лоруңузга", voiced_cons_not_jr = "доруңузга", unvoiced_cons = "торуңузга" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүзгө", voiced_cons_not_jr = "дөрүңүзгө", unvoiced_cons = "төрүңүзгө" },
	})
	add("acc_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңызды", vowel = "ңызды" },
		e_type_vowel = { consonant = "иңизди", vowel = "ңизди" },
		u_type_vowel = { consonant = "уңузду", vowel = "ңузду" },
		oe_type_vowel = { consonant = "үңүздү", vowel = "ңүздү" },
	})
	add("acc_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңызды", voiced_cons_not_jr = "дарыңызды", unvoiced_cons = "тарыңызды" },
		e_type_vowel = { vowel_or_jr = "лериңизди", voiced_cons_not_jr = "дериңизди", unvoiced_cons = "териңизди" },
		o_type_vowel = { vowel_or_jr = "лоруңузду", voiced_cons_not_jr = "доруңузду", unvoiced_cons = "торуңузду" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүздү", voiced_cons_not_jr = "дөрүңүздү", unvoiced_cons = "төрүңүздү" },
	})
	add("loc_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңызда", vowel = "ңызда" },
		e_type_vowel = { consonant = "иңизде", vowel = "ңизде" },
		u_type_vowel = { consonant = "уңузда", vowel = "ңузда" },
		oe_type_vowel = { consonant = "үңүздө", vowel = "ңүздө" },
	})
	add("loc_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңызда", voiced_cons_not_jr = "дарыңызда", unvoiced_cons = "тарыңызда" },
		e_type_vowel = { vowel_or_jr = "лериңизде", voiced_cons_not_jr = "дериңизде", unvoiced_cons = "териңизде" },
		o_type_vowel = { vowel_or_jr = "лоруңузда", voiced_cons_not_jr = "доруңузда", unvoiced_cons = "торуңузда" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүздө", voiced_cons_not_jr = "дөрүңүздө", unvoiced_cons = "төрүңүздө" },
	})
	add("abl_2s_formal_spos", {
		y_type_vowel = { consonant = "ыңыздан", vowel = "ңыздан" },
		e_type_vowel = { consonant = "иңизден", vowel = "ңизден" },
		u_type_vowel = { consonant = "уңуздан", vowel = "ңуздан" },
		oe_type_vowel = { consonant = "үңүздөн", vowel = "ңүздөн" },
	})
	add("abl_2s_formal_mpos", {
		a_type_vowel = { vowel_or_jr = "ларыңыздан", voiced_cons_not_jr = "дарыңыздан", unvoiced_cons = "тарыңыздан" },
		e_type_vowel = { vowel_or_jr = "лериңизден", voiced_cons_not_jr = "дериңизден", unvoiced_cons = "териңизден" },
		o_type_vowel = { vowel_or_jr = "лоруңуздан", voiced_cons_not_jr = "доруңуздан", unvoiced_cons = "торуңуздан" },
		oe_type_vowel = { vowel_or_jr = "лөрүңүздөн", voiced_cons_not_jr = "дөрүңүздөн", unvoiced_cons = "төрүңүздөн" },
	})
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
		slot_table = output_noun_slots,
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
