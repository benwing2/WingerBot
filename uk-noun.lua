local export = {}


--[=[

Authorship: Ben Wing <benwing2>

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of case/number.
	 Example slot names for nouns are "gen_" (genitive singular) and
	 "voc_p" (vocative plural). Each slot is filled with zero or more forms.

-- "form" = The declined Ukrainian form representing the value of a given slot.

-- "lemma" = The dictionary form of a given Ukrainian term. Generally the nominative
     masculine singular, but may occasionally be another form if the nominative
	 masculine singular is missing.
]=]

local lang = require("Module:languages").getByCode("uk")
local m_table = require("Module:table")
local m_links = require("Module:links")
local m_string_utilities = require("Module:string utilities")
local iut = require("Module:inflection utilities")
local m_para = require("Module:parameters")
local com = require("Module:uk-common")
local m_uk_translit = require("Module:uk-translit")

local current_title = mw.title.getCurrentTitle()
local NAMESPACE = current_title.nsText
local PAGENAME = current_title.text

local u = mw.ustring.char
local rsplit = mw.text.split
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rgmatch = mw.ustring.gmatch
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local usub = mw.ustring.sub
local uupper = mw.ustring.upper
local ulower = mw.ustring.lower

local AC = u(0x0301) -- acute =  ́
local CFLEX = u(0x0302) -- circumflex =  ̂
local DOTUNDER = u(0x0323) -- dotunder =  ̣
local accents = AC .. DOTUNDER
local accents_c = "[" .. accents .. "]"


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


local output_noun_slots = {
	nom_s = "nom|s",
	gen_s = "gen|s",
	dat_s = "dat|s",
	acc_s = "acc|s",
	ins_s = "ins|s",
	loc_s = "loc|s",
	voc_s = "voc|s",
	nom_p = "nom|p",
	gen_p = "gen|p",
	dat_p = "dat|p",
	acc_p = "acc|p",
	ins_p = "ins|p",
	loc_p = "loc|p",
	voc_p = "voc|p",
}


local output_noun_slots_with_linked = m_table.shallowcopy(output_noun_slots)
output_noun_slots_with_linked["nom_s_linked"] = "nom|s"
output_noun_slots_with_linked["nom_p_linked"] = "nom|p"

local input_params_to_slots_both = {
	[1] = "nom_s",
	[2] = "nom_p",
	[3] = "gen_s",
	[4] = "gen_p",
	[5] = "dat_s",
	[6] = "dat_p",
	[7] = "acc_s",
	[8] = "acc_p",
	[9] = "ins_s",
	[10] = "ins_p",
	[11] = "loc_s",
	[12] = "loc_p",
	[13] = "voc_s",
	[14] = "voc_p",
}


local input_params_to_slots_sg = {
	[1] = "nom_s",
	[2] = "gen_s",
	[3] = "dat_s",
	[4] = "acc_s",
	[5] = "ins_s",
	[6] = "loc_s",
	[7] = "voc_s",
}


local input_params_to_slots_pl = {
	[1] = "nom_p",
	[2] = "gen_p",
	[3] = "dat_p",
	[4] = "acc_p",
	[5] = "ins_p",
	[6] = "loc_p",
	[7] = "voc_p",
}


local cases = {
	nom = true,
	gen = true,
	dat = true,
	acc = true,
	ins = true,
	loc = true,
	voc = true,
}


local accented_cases = {
	["nóm"] = "nom",
	["gén"] = "gen",
	["dát"] = "dat",
	["ácc"] = "acc",
	["íns"] = "ins",
	["lóc"] = "loc",
	["vóc"] = "voc",
}


-- Stress patterns indicate where the stress goes for forms of each possible slot.
-- "-" means stem stress, "+" means ending stress. The field "stress" indicates
-- where to put the stem stress if the lemma doesn't include it. It applies primarily
-- to types d and f and variants of them. For example, lemma множина́ (type d) has
-- plural множи́ни (last-syllable stress), but lemma борода́ (type d') has plural
-- бо́роди (first-syllable stress).
local stress_patterns = {}

stress_patterns["a"] = {
	nom_s="-", gen_s="-", dat_s="-", acc_s="-", ins_s="-", loc_s="-", voc_s="-",
	nom_p="-", gen_p="-", dat_p="-",            ins_p="-", loc_p="-", voc_p="-",
	stress = nil,
}

stress_patterns["b"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="+", ins_s="+", loc_s="+", voc_s="+",
	nom_p="+", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="+",
	stress = "last",
}

stress_patterns["b'"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="+", ins_s="-", loc_s="+", voc_s="+",
	nom_p="+", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="+",
	stress = "last",
}

stress_patterns["c"] = {
	nom_s="-", gen_s="-", dat_s="-", acc_s="-", ins_s="-", loc_s="-", voc_s="-",
	nom_p="+", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="+",
	stress = nil,
}

stress_patterns["d"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="+", ins_s="+", loc_s="+", voc_s="+",
	nom_p="-", gen_p="-", dat_p="-",            ins_p="-", loc_p="-", voc_p="-",
	stress = "last",
}

stress_patterns["d'"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="-", ins_s="+", loc_s="+", voc_s="+",
	nom_p="-", gen_p="-", dat_p="-",            ins_p="-", loc_p="-", voc_p="-",
	stress = "first",
}

stress_patterns["e"] = {
	nom_s="-", gen_s="-", dat_s="-", acc_s="-", ins_s="-", loc_s="-", voc_s="-",
	nom_p="-", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="-",
	stress = nil,
}

stress_patterns["f"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="+", ins_s="+", loc_s="+", voc_s="+",
	nom_p="-", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="-",
	stress = "first",
}

stress_patterns["f'"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="-", ins_s="+", loc_s="+", voc_s="+",
	nom_p="-", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="-",
	stress = "first",
}

stress_patterns["f''"] = {
	nom_s="+", gen_s="+", dat_s="+", acc_s="+", ins_s="-", loc_s="+", voc_s="+",
	nom_p="-", gen_p="+", dat_p="+",            ins_p="+", loc_p="+", voc_p="+",
	stress = "first",
}


-- Maybe modify the stem and/or ending in certain special cases:
-- 1. Final -е in vocative singular triggers first palatalization of the stem
--	  (except for hard nouns in -ц, like абзац and палац) and causes accent retraction
--	  (except when base.no_retract_e, i.e. in neuters and soft feminines).
-- 2. Final -і in dative/locative singular triggers second palatalization.
local function apply_special_cases(base, slot, stem, ending)
	if slot == "voc_s" and rfind(ending, "^е" .. accents_c .. "?$") then
		if not base.no_palatalize_c or not rfind(stem, "ц$") then
			stem = com.apply_first_palatalization(stem)
		end
		if ending == "е" and not base.no_retract_e then
			ending = ending .. DOTUNDER
		end
	elseif (slot == "dat_s" or slot == "loc_s") and rfind(ending, "^і" .. accents_c .. "?$") then
		stem = com.apply_second_palatalization(stem)
	end
	return stem, ending
end


local function skip_slot(number, slot)
	return number == "sg" and rfind(slot, "_p$") or
		number == "pl" and rfind(slot, "_s$")
end


local function add(base, slot, stress, endings, footnotes, explicit_stem)
	if not endings then
		return
	end
	if skip_slot(base.number, slot) then
		return
	end
	footnotes = iut.combine_footnotes(iut.combine_footnotes(base.footnotes, stress.footnotes), footnotes)
	if type(endings) == "string" then
		endings = {endings}
	end
	local slot_is_plural = rfind(slot, "_p$")
	local stress_for_slot
	local stress_pattern_set = stress_patterns[stress.stress]
	if not stress_pattern_set then
		error("Internal error: Unrecognized stress pattern " .. stress.stress)
	end
	local stress_for_slot
	if slot == "acc_p" then
		-- This only applies when an override of acc_p is given.
		if base.animacy == "inan" then
			stress_for_slot = stress_pattern_set.nom_p
		elseif base.animacy == "pr" then
			stress_for_slot = stress_pattern_set.gen_p
		elseif stress_pattern_set.nom_p == stress_pattern_set.gen_p then
			stress_for_slot = stress_pattern_set.nom_p
		else
			for _, ending in ipairs(endings) do
				if not rfind(ending, AC) and not rfind(ending, DOTUNDER) then
					error("For animacy 'anml' and stress pattern " .. stress.stress .. ", must explicitly specify stress of override")
				end
			end
			-- All endings have explicit stress, so it doesn't matter.
			stress_for_slot = stress_pattern_set.nom_p
		end
	else
		stress_for_slot = stress_pattern_set[slot]
		if not stress_for_slot then
			error("Internal error: Don't know stress for pattern " .. stress.stress .. ", slot " .. slot)
		end
	end
	for _, ending in ipairs(endings) do
		local stem
		if explicit_stem then
			stem = explicit_stem
		else
			if rfind(ending, "^ь?" .. com.vowel_c) then
				stem = slot_is_plural and stress.pl_vowel_stem or stress.vowel_stem
			else
				stem = slot_is_plural and stress.pl_nonvowel_stem or stress.nonvowel_stem
			end
		end
		stem, ending = apply_special_cases(base, slot, stem, ending)
		if slot == "gen_p" and stress.genpl_reversed then
			-- If end stress is called for, add it to the ending if possible, otherwise
			-- go ahead and stress the last syllable of the stem.
			if stress_for_slot ~= "+" then
				if rfind(ending, com.vowel_c) then
					ending = com.maybe_stress_initial_syllable(ending)
				else
					stem = com.remove_stress(stem)
					stem = com.maybe_stress_final_syllable(stem)
				end
			end
		elseif rfind(ending, DOTUNDER) then
			-- DOTUNDER indicates stem stress in all cases
			ending = rsub(ending, DOTUNDER, "")
		elseif stress_for_slot == "+" then
			ending = com.maybe_stress_initial_syllable(ending)
		end
		if com.is_nonsyllabic(stem) then
			-- If stem is nonsyllabic, the ending must receive stress.
			ending = com.maybe_stress_initial_syllable(ending)
		end
		ending = com.generate_form(ending, footnotes)
		iut.add_forms(base.forms, slot, stem, ending, com.combine_stem_ending)
	end
end


local function process_slot_overrides(base, do_slot)
	for slot, overrides in pairs(base.overrides) do
		if skip_slot(base.number, slot) then
			error("Override specified for invalid slot '" .. slot .. "' due to '" .. base.number .. "' number restriction")
		end
		if do_slot(slot) then
			base.forms[slot] = nil
			local slot_is_plural = rfind(slot, "_p$")
			for _, override in ipairs(overrides) do
				for _, value in ipairs(override.values) do
					local form = value.form
					local combined_notes = iut.combine_footnotes(base.footnotes, value.footnotes)
					if override.full then
						if form:find("~") then
							local stem
							local ending = rsub(form, ".*~+", "")
							if rfind(ending, "^ь?" .. com.vowel_c) then
								stem = slot_is_plural and stress.pl_vowel_stem or stress.vowel_stem
							else
								stem = slot_is_plural and stress.pl_nonvowel_stem or stress.nonvowel_stem
							end
							if com.is_stressed(ending) then
								stem = com.remove_stress(stem)
							end
							form = rsub(value, "~~~", com.apply_second_palatalization(stem))
							form = rsub(value, "~~", com.apply_first_palatalization(stem))
							form = rsub(value, "~", stem)
						end
						if form ~= "" then
							iut.insert_form(base.forms, slot, {form = form, footnotes = combined_notes})
						end
					else
						if override.stemstressed then
							-- Signal not to add a stress to the ending even if the stress pattern
							-- calls for it.
							form = form .. DOTUNDER
						end
						for _, stress in ipairs(base.stresses) do
							add(base, slot, stress, form, combined_notes)
						end
					end
				end
			end
		end
	end
end


local function add_decl(base, stress,
	nom_s, gen_s, dat_s, acc_s, ins_s, loc_s, voc_s,
	nom_p, gen_p, dat_p, ins_p, loc_p, footnotes
)
	add(base, "nom_s", stress, nom_s, footnotes)
	add(base, "gen_s", stress, gen_s, footnotes)
	add(base, "dat_s", stress, dat_s, footnotes)
	add(base, "acc_s", stress, acc_s, footnotes)
	add(base, "ins_s", stress, ins_s, footnotes)
	add(base, "loc_s", stress, loc_s, footnotes)
	add(base, "voc_s", stress, voc_s, footnotes)
	add(base, "nom_p", stress, nom_p, footnotes)
	add(base, "gen_p", stress, gen_p, footnotes)
	add(base, "dat_p", stress, dat_p, footnotes)
	add(base, "ins_p", stress, ins_p, footnotes)
	add(base, "loc_p", stress, loc_p, footnotes)
end


local function handle_derived_slots_and_overrides(base)
	local function is_non_derived_slot(slot)
		return slot ~= "voc_s" and slot ~= "voc_p" and slot ~= "acc_s" and slot ~= "acc_p"
	end

	local function is_derived_slot(slot)
		return not is_non_derived_slot(slot)
	end

	-- Handle overrides for the non-derived slots. Do this before generating the derived
	-- slots so overrides of the source slots (e.g. nom_p) propagate to the derived slots.
	process_slot_overrides(base, is_non_derived_slot)

	-- Generate the remaining slots that are derived from other slots.
	iut.insert_forms(base.forms, "voc_p", base.forms["nom_p"])
	if rfind(base.decl, "%-m$") or base.gender == "M" and base.decl == "adj" then
		iut.insert_forms(base.forms, "acc_s", base.forms[base.animacy == "inan" and "nom_s" or "gen_s"])
	end
	local function tag_with_variant(variant)
		return function(form) return form .. variant end
	end
	local function maybe_tag_with_variant(forms, variant)
		if base.multiword then
			return iut.map_forms(forms, tag_with_variant(variant))
		else
			return forms
		end
	end
	if base.animacy == "inan" then
		iut.insert_forms(base.forms, "acc_p", base.forms["nom_p"])
	elseif base.animacy == "pr" then
		iut.insert_forms(base.forms, "acc_p", base.forms["gen_p"])
	elseif base.animacy == "anml" then
		iut.insert_forms(base.forms, "acc_p", maybe_tag_with_variant(base.forms["nom_p"], com.VAR1))
		iut.insert_forms(base.forms, "acc_p", maybe_tag_with_variant(base.forms["gen_p"], com.VAR2))
	else
		error("Internal error: Unrecognized animacy: " .. (base.animacy or "nil"))
	end
	if base.surname then
		iut.insert_forms(base.forms, "voc_s", base.forms["nom_s"])
	end

	-- Handle overrides for derived slots, to allow them to be overridden.
	process_slot_overrides(base, is_derived_slot)

	-- Compute linked versions of potential lemma slots, for use in {{uk-noun}}.
	-- We substitute the original lemma (before removing links) for forms that
	-- are the same as the lemma, if the original lemma has links.
	for _, slot in ipairs({"nom_s", "nom_p"}) do
		iut.insert_forms(base.forms, slot .. "_linked", iut.map_forms(base.forms[slot], function(form)
			if form == base.orig_lemma_no_links and rfind(base.orig_lemma, "%[%[") then
				return base.orig_lemma
			else
				return form
			end
		end))
	end
end


local decls = {}
local declprops = {}

local function default_genitive_u(base)
	return base.number == "sg" and not rfind(base.lemma, "^" .. com.uppercase_c)
end


decls["hard-m"] = function(base, stress)
	base.no_palatalize_c = true
	local velar = rfind(stress.vowel_stem, com.velar_c .. "$")
	local gen_s = default_genitive_u(base) and "у" or "а" -- may be overridden
	local loc_s =
		-- these conditions seem weird but it's what I observed
		velar and (base.animacy ~= "inan" or stress.reducible) and {"ові", "у"} or
		velar and "у" or
		base.animacy ~= "inan" and {"ові", "і"} or
		base.number == "sg" and {"у", "і"} or
		"і"
	local voc_s =
		-- these conditions also seem weird but it's what I observed
		velar and base.animacy == "anml" and stress.stress == "b" and "е" or
		velar and "у" or
		"е"
	-- handle soft stem ending in vowel (хазя́їн, pl. хазяї́;
	-- зуб "tooth, cog" alt nom pl. зу́б'я, gen pl зу́б'їв)
	local plvowel = com.ends_in_vowel(stress.pl_vowel_stem) or rfind(stress.pl_vowel_stem, "'$")
	local gen_p = base.remove_in and "" or plvowel and "їв" or "ів"
	add_decl(base, stress, "", gen_s, {"ові", "у"}, nil, "ом", loc_s, voc_s)
	if base.plsoft then
		local nom_p = plvowel and "ї" or "і"
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			nom_p, gen_p, "ям", "ями", "ях")
	else
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			"и", gen_p, "ам", "ами", "ах")
	end
end

declprops["hard-m"] = {
	desc = function(base, stress)
		if rfind(stress.vowel_stem, com.velar_c .. "$") then
			return "velar masc-form"
		else
			return "hard masc-form"
		end
	end,
	cat = function(base, stress)
		if rfind(stress.vowel_stem, com.velar_c .. "$") then
			return "velar-stem masculine-form"
		else
			return "hard masculine-form"
		end
	end
}


decls["semisoft-m"] = function(base, stress)
	local gen_s = default_genitive_u(base) and "у" or "а" -- may be overridden
	local loc_s = base.animacy ~= "inan" and {"еві", "у", "і"} or {"у", "і"}
	-- FIXME: Should vocative singular in -у be end-stressed if reducible, parallel
	-- to soft nouns? I don't have any examples of reducible nouns in -ч, ш or щ.
	local voc_s = rfind(stress.vowel_stem, "[рж]$") and "е" or "у̣" -- dot underneath у
	add_decl(base, stress, "", gen_s, {"еві", "у"}, nil, "ем", loc_s, voc_s,
		"і", "ів", "ам", "ами", "ах")
end

declprops["semisoft-m"] = {
	desc = "semisoft masc-form",
	cat = "semisoft masculine-form",
}


decls["soft-m"] = function(base, stress)
	local nom_s = rfind(stress.nonvowel_stem, "р$") and "" or "ь"
	local gen_s = default_genitive_u(base) and "ю" or "я" -- may be overridden
	local loc_s = base.animacy ~= "inan" and {"еві", "ю", "і"} or {"ю", "і"}
	-- More weird conditions: vocative singular in accent b is end-stressed if
	-- reducible or ending in -інь (from Proto-Slavic nouns in -y), stem-stressed
	-- otherwise.
	local voc_s = (stress.reducible or (
		rfind(stress.nonvowel_stem, "і́?н$") and rfind(stress.vowel_stem, "е́?н$")
	)) and "ю" or "ю̣"
	add_decl(base, stress, nom_s, gen_s, {"еві", "ю"}, nil, "ем", loc_s, voc_s,
		"і", "ів", "ям", "ями", "ях")
end

declprops["soft-m"] = {
	desc = "soft masc-form",
	cat = "soft masculine-form",
}


decls["j-m"] = function(base, stress)
	local gen_s = default_genitive_u(base) and "ю" or "я" -- may be overridden
	local loc_s = base.animacy ~= "inan" and {"ю", "єві", "ї"} or {"ю", "ї"}
	-- As with soft nouns, vocative singular in accent b is end-stressed if
	-- reducible, stem-stressed otherwise.
	local voc_s = stress.reducible and "ю" or "ю̣"
	add_decl(base, stress, "й", gen_s, {"ю", "єві"}, nil, "єм", loc_s, voc_s,
		"ї", "їв", "ям", "ями", "ях")
end

declprops["j-m"] = {
	desc = "j-stem masc-form",
	cat = "j-stem masculine-form",
}


decls["o-m"] = function(base, stress)
	local unstressed_lo =
		rfind(stress.vowel_stem, "л$") and stress_patterns[stress.stress].nom_s == "-"
	local velar = rfind(stress.vowel_stem, com.velar_c .. "$")
	local hushing = rfind(stress.vowel_stem, com.hushing_c .. "$")
	local loc_s =
		-- these conditions are partly based on analogy with the neuter;
		-- masculines in -о (not counting proper names):
		-- (1) in -ко: ба́тько "father", дя́дько "uncle", "сонько́" (MF) "sleepyhead",
		--     солове́йко "nightingale"
		-- (2) in -ьо: дя́дьо "uncle", не́ньо "dad";
		-- (3) in -то, -до: та́то "dad";
		-- (4) in vowel + -ло: громи́ло "bully, thug", зубри́ло "rote memorizer, mechanical studier",
		--     чуди́ло "eccentric person, kook, weirdo", бурми́ло "clumsy person, oaf, klutz",
		--     страши́ло/страши́дло "scary monster" (MN), базі́кало "chatterbox, braggart" (MN)
		-- (5) in cons + -ло: міня́йло "moneychanger" (N per sum.in.ua, M per Horokh,
		--     mova.info and Slovnyk), вайло́ "clumsy person, oaf, klutz" (M per Horokh and
		--     Slovnyk's declension table, MF per sum.in.ua, MN per mova.info),
		--     трепло́ "chatterbox, braggart" (N or M per Horokh, N only per other sources)
		-- (6) in -що: леда́що "lazy person, sluggard" (MN)
		-- (7) in -и́сько: хлопчи́сько "boy" (MN), пани́сько "nasty sir", бідачи́сько "wretched man" (MN),
		--     чорти́сько "big devil", діди́сько "large/nasty grandfather?", попи́сько "nasty priest",
		--     парубчи́сько "young man (pej.)", простачи́сько "simpleton?" (all personal);
		--     вовчи́сько "large wolf", коти́сько "large cat", пси́сько "large dog", барани́сько "large ram",
		--     бичи́сько "large bull", кабани́сько "large boar", соми́сько "large catfish", кони́сько "large horse",
		--     etc. (animal); чуби́сько "large forehead", вітри́сько "big wind?", голоси́сько "big voice",
		--     хвости́сько "large tail", кожуши́сько "big fur coat", ножи́сько "big knife?",
		--     тютюни́сько "nasty tobacco", чоботи́сько "large boot" (pl. чоботи́ська),
		--     хліби́сько "large bread/loaf", батожи́сько "?",etc.
		velar and base.animacy ~= "inan" and {"ові", "у"} or
		hushing and base.animacy ~= "inan" and {"еві", "у", "і"} or
		velar and "у" or
		hushing and {"у", "і"} or
		base.animacy ~= "inan" and {"ові", "і"} or
		"і"
	local ins_s = hushing and "ем" or "ом"
	local voc_s =
		velar and base.animacy ~= "inan" and "у" or
		(unstressed_lo or (hushing and base.animacy ~= "inan")) and "е" or
		"о"
	add_decl(base, stress, "о", "а", {"ові", "у"}, nil, ins_s, loc_s, voc_s,
		unstressed_lo and "а" or "и", unstressed_lo and "" or "ів", "ам", "ами", "ах")
end

local function get_stem_type(stress)
	if rfind(stress.vowel_stem, com.velar_c .. "$") then
		return "velar-stem"
	elseif rfind(stress.vowel_stem, com.hushing_c .. "$") then
		return "semisoft"
	else
		return "hard"
	end
end

local function o_m_desc(base, stress, soft)
	local gender
	if base.gender == "M" then
		gender = "masc"
	elseif base.gender == "MF" then
		gender = "masc/fem"
	elseif base.gender == "F" then
		gender = "fem"
	else
		error("Internal error: Bad gender '" .. base.gender .. "' for o-m type")
	end
	return (soft and "soft" or rsub(get_stem_type(stress), "%-stem$", "")) .. " " .. gender .. " in -о"
end

local function o_m_cat(base, stress, soft)
	local stem_type = soft and "soft" or get_stem_type(stress)
	local cats = {}
	if base.gender == "M" or base.gender == "MF" then
		table.insert(cats, stem_type .. " masculine nouns in -о")
		table.insert(cats, stem_type .. " masculine ~ nouns in -о")
	end
	if base.gender == "F" or base.gender == "MF" then
		table.insert(cats, stem_type .. " feminine nouns in -о")
		table.insert(cats, stem_type .. " feminine ~ nouns in -о")
	end
	return cats
end

declprops["o-m"] = {
	desc = o_m_desc,
	cat = o_m_cat,
}


decls["soft-o-m"] = function(base, stress)
	add_decl(base, stress, "ьо", "я", {"еві", "ю"}, nil, "ем", {"еві", "ю", "і"}, "ю",
		"і", "ів", "ям", "ями", "ях")
end

declprops["soft-o-m"] = {
	desc = function(base, stress) return o_m_desc(base, stress, "soft") end,
	cat = function(base, stress) return o_m_cat(base, stress, "soft") end,
}


decls["semisoft-e-m"] = function(base, stress)
	base.no_retract_e = true
	-- Known examples: вовчи́ще "big wolf" (animate), діди́ще "big grandfather",
	-- дружи́ще "old buddy, pal, chap" (animate);
	-- вітри́ще "big wind", доми́ще "big house" (also N per mova.info), кулачи́ще "big fist" (MN),
	-- замчи́ще/за́мчище "large castle; site of former castle" (MN) (inanimate)
	-- The animate values are based only on баби́ще but have parallels in
	-- semisoft masculine nouns.
	local dat_s =
		base.animacy ~= "inan" and {"еві", "у"} or
		 "у"
	local loc_s =
		base.animacy ~= "inan" and {"еві", "у", "і"} or
		 {"у", "і"}
	add_decl(base, stress, "е", "а", dat_s, "е", "ем", loc_s, "е",
		"а", "", "ам", "ами", "ах")
end

declprops["semisoft-e-m"] = {
	desc = "semisoft masc in -е",
	cat = {"semisoft masculine nouns in -е", "semisoft masculine ~ nouns in -е"},
}


decls["hard-f"] = function(base, stress)
	base.no_palatalize_c = true
	-- Vocative singular in stress pattern b is end-stressed; stem-stressed otherwise.
	local voc_sg = stress.stress == "b" and "о" or "о̣"
	add_decl(base, stress, "а", "и", "і", "у", "ою", "і", voc_sg)
	if base.plsoft then
		-- люди́на, дити́на
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			"и", "ей", "ям", "ями", "ях")
	else
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			"и", "", "ам", "ами", "ах")
	end
end

declprops["hard-f"] = {
	desc = "hard fem-form",
	cat = "hard feminine-form",
}


decls["semisoft-f"] = function(base, stress)
	add_decl(base, stress, "а", "і", "і", "у", "ею", "і", "е",
		"і", "", "ам", "ами", "ах")
end

declprops["semisoft-f"] = {
	desc = "semisoft fem-form",
	cat = "semisoft feminine-form",
}


decls["soft-f"] = function(base, stress)
	base.no_retract_e = true
	base.no_palatalize_c = true
	local voc_s = rfind(stress.vowel_stem, "у́с$") and "ю" or -- бабу́ся, мату́ся, ду́ся, Катру́ся, etc.
		"е"
	add_decl(base, stress, "я", "і", "і", "ю", "ею", "і", voc_s,
		"і", rfind(stress.pl_nonvowel_stem, "[сздтлнц]$") and "ь" or "", "ям", "ями", "ях")
end

declprops["soft-f"] = {
	desc = "soft fem-form",
	cat = "soft feminine-form",
}


decls["j-f"] = function(base, stress)
	base.no_retract_e = true
	add_decl(base, stress, "я", "ї", "ї", "ю", "єю", "ї", "є",
		"ї", "й", "ям", "ями", "ях")
end

declprops["j-f"] = {
	desc = "j-stem fem-form",
	cat = "j-stem feminine-form",
}


decls["third-f"] = function(base, stress)
	base.no_retract_e = true
	local nom_sg = rfind(stress.nonvowel_stem, "[сздтлнц]$") and "ь" or ""
	-- All third-decl feminine nouns ending in -Cть appear to have two possible genitive
	-- singulars, at least per the current orthography. Some other third-decl nouns (о́сінь "autumn",
	-- сіль "salt" and кров "blood") behave the same way, but most don't.
	local gen_sg = rfind(stress.vowel_stem, "[^аеєиіїоуюяАЕЄИІЇОУЮЯ́ ]т$") and {"і", "и"} or "і"
	local hushing = rfind(stress.vowel_stem, "[чшжщ]$")
	local plvowel = hushing and "а" or "я"
	add_decl(base, stress, nom_sg, gen_sg, "і", nom_sg, nil, "і", "е",
		"і", "ей", plvowel .. "м", plvowel .. "ми", plvowel .. "х")
	local ins_s_stem = stress.nonvowel_stem
	local pre_stem, final_cons = rmatch(ins_s_stem, "^(.*)([сздтлнцчшжщ])$")
	if pre_stem then
		if rfind(pre_stem, com.vowel_c .. AC .. "?$") then
			-- vowel + doublable cons; double the cons
			ins_s_stem = ins_s_stem .. final_cons
		end
		-- if non-vowel + doublable cons, don't change stem,
		-- e.g. смерть -> ins sg сме́ртю
	else
		ins_s_stem = ins_s_stem .. "'"
	end
	add(base, "ins_s", stress, "ю", nil, ins_s_stem)
end

declprops["third-f"] = {
	desc = "3rd-decl fem-form",
	cat = "third-declension feminine-form",
}


decls["semisoft-e-f"] = function(base, stress)
	-- at least баби́ще (which can also be neuter, with neuter declension)
	base.no_retract_e = true
	add_decl(base, stress, "е", "і", "і", "е", "ею", "і", "е",
		"і", "", "ам", "ами", "ах")
end

declprops["semisoft-e-f"] = {
	desc = "semisoft fem in -е",
	cat = {"semisoft feminine nouns in -е", "semisoft feminine ~ nouns in -е"},
}


decls["hard-n"] = function(base, stress)
	base.no_retract_e = true
	base.no_palatalize_c = true
	local velar = rfind(stress.vowel_stem, com.velar_c .. "$")
	-- Dictionaries disagree on whether neuter animates have -о or -а in the
	-- accusative singular. Both appear possible, with -о maybe more common.
	-- Neuter animates in -е appear to always have -е in the accusative singular.
	local acc_s = base.animacy ~= "inan" and {"о", "а"} or "о"
	-- All neuter animates appear to have dative singular in -ові/-у; several
	-- neuter inanimates do too, but the majority appear to have just -у
	local dat_s = base.animacy ~= "inan" and {"ові", "у"} or "у"
	local loc_s =
		-- these conditions are partly based on analogy with the masculine (including o-m);
		-- neuter animates:
		-- animal: со́нечко "ladybug", риби́сько "big fish", густя́ко "goose (endearing diminutive)",
		--   чу́до "fabulous creature", чудо́висько "monster (animal)";
		-- personal: ча́до "child" (archaic/jocular), ла́до "beloved, darling"
		--   (when referring to a child), дівчи́сько "girl", баби́сько "nasty grandmother",
		--   діти́ська (pl.) "children"
		velar and base.animacy ~= "inan" and {"ові", "у"} or
		velar and "у" or
		base.animacy ~= "inan" and {"ові", "і"} or
		"і"
	local voc_s =
		velar and base.animacy ~= "inan" and "у" or
		"о"
	add_decl(base, stress, "о", "а", dat_s, acc_s, "ом", loc_s, voc_s,
		"а", "", "ам", "ами", "ах")
end

declprops["hard-n"] = {
	desc = function(base, stress)
		if rfind(stress.vowel_stem, com.velar_c .. "$") then
			return "velar neut-form"
		else
			return "hard neut-form"
		end
	end,
	cat = function(base, stress)
		if rfind(stress.vowel_stem, com.velar_c .. "$") then
			return "velar-stem neuter-form"
		else
			return "hard neuter-form"
		end
	end
}


decls["semisoft-n"] = function(base, stress)
	base.no_retract_e = true
	-- The animate values are based only on баби́ще but have parallels in
	-- semisoft masculine nouns. (страхо́вище?)
	local dat_s =
		base.animacy ~= "inan" and {"еві", "у"} or
		 "у"
	local loc_s =
		base.animacy ~= "inan" and {"еві", "у", "і"} or
		 {"у", "і"}
	add_decl(base, stress, "е", "а", dat_s, "е", "ем", loc_s, "е",
		"а", "", "ам", "ами", "ах")
end

declprops["semisoft-n"] = {
	desc = "semisoft neut-form",
	cat = "semisoft neuter-form",
}


decls["soft-n"] = function(base, stress)
	base.no_retract_e = true
	add_decl(base, stress, "е", "я", "ю", "е", "ем", {"ю", "і"}, "е",
		"я", rfind(stress.pl_nonvowel_stem, "[сздтлнц]$") and "ь" or "", "ям", "ями", "ях")
end

declprops["soft-n"] = {
	desc = "soft neut-form",
	cat = "soft neuter-form",
}


decls["j-n"] = function(base, stress)
	base.no_retract_e = true
	add_decl(base, stress, "є", "я", "ю", "є", "єм", {"ю", "ї"}, "є",
		"я", "й", "ям", "ями", "ях")
end

declprops["j-n"] = {
	desc = "j-stem neut-form",
	cat = "j-stem neuter-form",
}


decls["ja-n"] = function(base, stress)
	local loc_sg = rfind(stress.vowel_stem, "['й]$") and "ї" or "і"
	if stress_patterns[stress.stress].loc_sg == "-" then
		loc_sg = {"ю", loc_sg}
	end
	local gen_pl_end_stressed = stress_patterns[stress.stress].gen_pl == "+"
	add_decl(base, stress, "я", "я", "ю", "я", "ям", loc_sg, "я")
	if base.plhard then
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			"а", gen_pl_end_stressed and "ів" or "", "ам", "ами", "ах")
	else
		local gen_pl =
			rfind(stress.pl_vowel_stem, "['й]$") and "їв" or
			gen_pl_end_stressed and "ів" or
			rfind(stress.pl_nonvowel_stem, "[сздтлнц]$") and "ь" or
			""
		add_decl(base, stress, nil, nil, nil, nil, nil, nil, nil,
			"я", gen_pl, "ям", "ями", "ях")
	end
end

declprops["ja-n"] = {
	desc = "neut in -ja",
	cat = {"soft neuter nouns in -я", "soft neuter ~ nouns in -я"},
}


decls["en-n"] = function(base, stress)
	decls["ja-n"](base, stress)
	local n_stem = rsub(stress.vowel_stem, "'$", "ен")
	add(base, "gen_s", stress, "і", nil, n_stem)
	add(base, "dat_s", stress, "і", nil, n_stem)
	add(base, "ins_s", stress, "ем", nil, n_stem)
	add(base, "loc_s", stress, "і", nil, n_stem)
end

declprops["en-n"] = {
	desc = "n-stem neut-form",
	cat = "n-stem neuter-form",
}


decls["t-n"] = function(base, stress)
	-- Most t-stem neuters end in -я́, but there's also лоша́, курча́, двіча́, ...
	local v = rfind(stress.vowel_stem, com.hushing_c .. "$") and "а" or "я"
	add_decl(base, stress, v, v .. "ти", v .. "ті", v, v .. "м", v .. "ті", v,
		v .. "та", v .. "т", v .. "там", v .. "тами", v .. "тах")
end

declprops["t-n"] = {
	desc = "t-stem neut-form",
	cat = "t-stem neuter-form",
}


decls["adj"] = function(base, stress)
	local props = {}
	if base.ialt then
		table.insert(props, base.ialt)
	end
	if base.surname then
		table.insert(props, "surname")
	end
	local propspec = table.concat(props, ".")
	if propspec ~= "" then
		propspec = "<" .. propspec .. ">"
	end
	local adj_alternant_multiword_spec = require("Module:uk-adjective").do_generate_forms({base.lemma .. propspec})
	local function copy(from_slot, to_slot)
		base.forms[to_slot] = adj_alternant_multiword_spec.forms[from_slot]
	end
	if base.number ~= "pl" then
		if base.gender == "M" then
			copy("nom_m", "nom_s")
			copy("gen_m", "gen_s")
			copy("dat_m", "dat_s")
			copy("ins_m", "ins_s")
			copy("loc_m", "loc_s")
			copy("voc_m", "voc_s")
		elseif base.gender == "F" then
			copy("nom_f", "nom_s")
			copy("gen_f", "gen_s")
			copy("dat_f", "dat_s")
			copy("acc_f", "acc_s")
			copy("ins_f", "ins_s")
			copy("loc_f", "loc_s")
			copy("voc_f", "voc_s")
		elseif base.gender == "N" then
			copy("nom_n", "nom_s")
			copy("gen_m", "gen_s")
			copy("dat_m", "dat_s")
			copy("acc_n", "acc_s")
			copy("ins_m", "ins_s")
			copy("loc_m", "loc_s")
			copy("voc_n", "voc_s")
		else
			error("Internal error: Unrecognized gender: " .. base.gender)
		end
		if not base.forms.voc_s then
			iut.insert_forms(base.forms, "voc_s", base.forms["nom_s"])
		end
	end
	if base.number ~= "sg" then
		copy("nom_p", "nom_p")
		copy("gen_p", "gen_p")
		copy("dat_p", "dat_p")
		copy("ins_p", "ins_p")
		copy("loc_p", "loc_p")
	end
end

declprops["adj"] = {
	desc = function(base, stress)
		if base.number == "pl" then
			return "adj"
		elseif base.gender == "M" then
			return "adj masc"
		elseif base.gender == "F" then
			return "adj fem"
		elseif base.gender == "N" then
			return "adj neut"
		else
			error("Internal error: Unrecognized gender: " .. base.gender)
		end
	end,
	cat = function(base, stress)
		local gender
		if base.number == "pl" then
			gender = "plural-only"
		elseif base.gender == "M" then
			gender = "masculine"
		elseif base.gender == "F" then
			gender = "feminine"
		elseif base.gender == "N" then
			gender = "neuter"
		else
			error("Internal error: Unrecognized gender: " .. base.gender)
		end
		local stemtype
		if rfind(base.lemma, "ци́?й$") then
			stemtype = "c-stem"
		elseif rfind(base.lemma, "и́?й$") then
			stemtype = "hard"
		elseif rfind(base.lemma, "і́?й$") then
			stemtype = "soft"
		elseif rfind(base.lemma, "ї́?й$") then
			stemtype = "j-stem"
		elseif base.surname then
			stemtype = "surname"
		else
			stemtype = "possessive"
		end

		return {"adjectival nouns", stemtype .. " " .. gender .. " adjectival ~ nouns"}
	end,
}


local function fetch_footnotes(separated_group)
	local footnotes
	for j = 2, #separated_group - 1, 2 do
		if separated_group[j + 1] ~= "" then
			error("Extraneous text after bracketed footnotes: '" .. table.concat(separated_group) .. "'")
		end
		if not footnotes then
			footnotes = {}
		end
		table.insert(footnotes, separated_group[j])
	end
	return footnotes
end

--[=[
Parse a single override spec (e.g. 'loci:ú' or 'datpl:чо́ботам:чобо́тям[rare]') and return
two values: the slot the override applies to, and an object describing the override spec.
The input is actually a list where the footnotes have been separated out; for example,
given the spec 'inspl:чо́ботами:чобо́тями[rare]:чобітьми́[archaic]', the input will be a list
{"inspl:чо́ботами:чобо́тями", "[rare]", ":чобітьми́", "[archaic]", ""}. The object returned
for 'datpl:чо́ботам:чобо́тям[rare]' looks like this:

{
  full = true,
  values = {
    {
      form = "чо́ботам"
    },
    {
      form = "чобо́тям",
      footnotes = {"[rare]"}
    }
  }
}

The object returned for 'lócji:jú' looks like this:

{
  stemstressed = true,
  values = {
    {
      form = "ї",
    },
    {
      form = "ю́",
    }
  }
}

Note that all forms (full or partial) are reverse-transliterated, and full forms are
normalized by adding an accent to monosyllabic forms.
]=]
local function parse_override(segments)
	local retval = {values = {}}
	local part = segments[1]
	local case = usub(part, 1, 3)
	if cases[case] then
		-- ok
	elseif accented_cases[case] then
		case = accented_cases[case]
		retval.stemstressed = true
	else
		error("Internal error: unrecognized case in override: '" .. table.concat(segments) .. "'")
	end
	local rest = usub(part, 4)
	local slot
	if rfind(rest, "^pl") then
		rest = rsub(rest, "^pl", "")
		slot = case .. "_p"
	else
		slot = case .. "_s"
	end
	if rfind(rest, "^:") then
		retval.full = true
		rest = rsub(rest, "^:", "")
	end
	segments[1] = rest
	local colon_separated_groups = iut.split_alternating_runs(segments, ":")
	for i, colon_separated_group in ipairs(colon_separated_groups) do
		local value = {}
		local form = colon_separated_group[1]
		if form == "" then
			error("Use - to indicate an empty ending for slot '" .. slot .. "': '" .. table.concat(segments .. "'"))
		elseif form == "-" then
			value.form = ""
		else
			value.form = m_uk_translit.reverse_tr(form)
			if retval.full then
				value.form = com.add_monosyllabic_stress(value.form)
				if com.needs_accents(value.form) then
					error("Override '" .. value.form .. "' for slot '" .. slot .. "' missing an accent")
				end
			end
		end
		value.footnotes = fetch_footnotes(colon_separated_group)
		table.insert(retval.values, value)
	end
	return slot, retval
end


--[=[
Parse an indicator spec (text consisting of angle brackets and zero or more
dot-separated indicators within them). Return value is an object of the form

{
  overrides = {
    SLOT = {OVERRIDE, OVERRIDE, ...}, -- as returned by parse_override()
	...
  },
  forms = {}, -- forms for a single spec alternant; see `forms` below
  footnotes = {"FOOTNOTE", "FOOTNOTE", ...}, -- may be missing
  stresses = { -- may be missing
	{
	  stress = "STRESS", -- "a", "b", etc.
	  reducible = TRUE_OR_FALSE,
	  genpl_reversed = TRUE_OR_FALSE,
	  footnotes = {"FOOTNOTE", "FOOTNOTE", ...}, -- may be missing
	  -- The following fields are filled in by determine_stress_and_stems()
	  vowel_stem = "STEM",
	  nonvowel_stem = "STEM",
	  pl_vowel_stem = "STEM",
	  pl_nonvowel_stem = "STEM",
	},
	...
  },
  explicit_gender = "GENDER", -- "M", "F", "N", "MF"; may be missing
  number = "NUMBER", -- "sg", "pl"; may be missing
  animacy = "ANIMACY", -- "inan", "anml", "pr"; may be missing
  ialt = "VOWEL_ALTERNATION", -- "i", "ie", "ijo", "io"; may be missing
  rtype = "RTYPE", -- "soft", "semisoft"; may be missing
  neutertype = "NEUTERTYPE", -- "t", "en"; may be missing
  plsoft = true, -- may be missing
  plhard = true, -- may be missing
  remove_in = true, -- may be missing
  thirddecl = true, -- may be missing
  surname = true, -- may be missing
  adj = true, -- may be missing
  stem = "STEM", -- may be missing
  plstem = "PLSTEM", -- may be missing

  -- The following additional fields are added by other functions:
  orig_lemma = "ORIGINAL-LEMMA", -- as given by the user
  orig_lemma_no_links = "ORIGINAL-LEMMA-NO-LINKS", -- links removed, monosyllabic stress added
  lemma = "LEMMA", -- `orig_lemma_no_links`, converted to singular form if plural
  forms = {
	SLOT = {
	  {
		form = "FORM",
		footnotes = {"FOOTNOTE", "FOOTNOTE", ...} -- may be missing
	  },
	  ...
	},
	...
  },
  decl = "DECL", -- declension, e.g. "hard-m"
  vowel_stem = "VOWEL-STEM", -- derived from vowel-ending lemmas
  nonvowel_stem = "NONVOWEL-STEM", -- derived from non-vowel-ending lemmas
}
]=]
local function parse_indicator_spec(angle_bracket_spec)
	local inside = rmatch(angle_bracket_spec, "^<(.*)>$")
	assert(inside)
	local base = {overrides = {}, forms = {}}
	if inside ~= "" then
		local segments = iut.parse_balanced_segment_run(inside, "[", "]")
		local dot_separated_groups = iut.split_alternating_runs(segments, "%.")
		for i, dot_separated_group in ipairs(dot_separated_groups) do
			local part = dot_separated_group[1]
			local case_prefix = usub(part, 1, 3)
			if cases[case_prefix] or accented_cases[case_prefix] then
				local slot, override = parse_override(dot_separated_group)
				if base.overrides[slot] then
					table.insert(base.overrides[slot], override)
				else
					base.overrides[slot] = {override}
				end
			elseif part == "" then
				if #dot_separated_group == 1 then
					error("Blank indicator: '" .. inside .. "'")
				end
				base.footnotes = fetch_footnotes(dot_separated_group)
			elseif rfind(part, "^[a-f]'*[*#]*$") or rfind(part, "^[a-f]'*[*#]*,") or
				rfind(part, "^[*#]*$") or rfind(part, "^[*#]*,") then
				if base.stresses then
					error("Can't specify stress pattern indicator twice: '" .. inside .. "'")
				end
				local comma_separated_groups = iut.split_alternating_runs(dot_separated_group, ",")
				local patterns = {}
				for i, comma_separated_group in ipairs(comma_separated_groups) do
					local pattern = comma_separated_group[1]
					local pat, reducible = rsubb(pattern, "%*", "")
					local genpl_reversed
					pat, genpl_reversed = rsubb(pat, "#", "")
					if pat == "" then
						pat = nil
					end
					if pat and not stress_patterns[pat] then
						error("Unrecognized stress pattern '" .. pat .. "': '" .. inside .. "'")
					end
					table.insert(patterns, {
						stress = pat, reducible = reducible, genpl_reversed = genpl_reversed,
						footnotes = fetch_footnotes(comma_separated_group)
					})
				end
				base.stresses = patterns
			elseif #dot_separated_group > 1 then
				error("Footnotes only allowed with slot overrides, stress patterns or by themselves: '" .. table.concat(dot_separated_group) .. "'")
			elseif part == "M" or part == "MF" or part == "F" or part == "N" then
				if base.explicit_gender then
					error("Can't specify gender twice: '" .. inside .. "'")
				end
				base.explicit_gender = part
			elseif part == "sg" or part == "pl" then
				if base.number then
					error("Can't specify number twice: '" .. inside .. "'")
				end
				base.number = part
			elseif part == "pr" or part == "anml" or part == "inan" then
				if base.animacy then
					error("Can't specify animacy twice: '" .. inside .. "'")
				end
				base.animacy = part
			elseif part == "i" or part == "io" or part == "ijo" or part == "ie" then
				if base.ialt then
					error("Can't specify і-alternation indicator twice: '" .. inside .. "'")
				end
				base.ialt = part
			elseif part == "soft" or part == "semisoft" then
				if base.rtype then
					error("Can't specify 'р' type ('soft' or 'semisoft') more than once: '" .. inside .. "'")
				end
				base.rtype = part
			elseif part == "t" or part == "en" then
				if base.neutertype then
					error("Can't specify neuter indicator ('t' or 'en') more than once: '" .. inside .. "'")
				end
				base.neutertype = part
			elseif part == "plsoft" then
				if base.plsoft then
					error("Can't specify 'plsoft' twice: '" .. inside .. "'")
				end
				base.plsoft = true
			elseif part == "plhard" then
				if base.plhard then
					error("Can't specify 'plhard' twice: '" .. inside .. "'")
				end
				base.plhard = true
			elseif part == "in" then
				if base.remove_in then
					error("Can't specify 'in' twice: '" .. inside .. "'")
				end
				base.remove_in = true
			elseif part == "3rd" then
				if base.thirddecl then
					error("Can't specify '3rd' twice: '" .. inside .. "'")
				end
				base.thirddecl = true
			elseif part == "surname" then
				if base.surname then
					error("Can't specify 'surname' twice: '" .. inside .. "'")
				end
				base.surname = true
			elseif part == "+" then
				if base.adj then
					error("Can't specify '+' twice: '" .. inside .. "'")
				end
				base.adj = true
			elseif rfind(part, "^stem:") then
				if base.stem then
					error("Can't specify stem twice: '" .. inside .. "'")
				end
				base.stem = rsub(part, "^stem:", "")
			elseif rfind(part, "^plstem:") then
				if base.plstem then
					error("Can't specify plural stem twice: '" .. inside .. "'")
				end
				base.plstem = rsub(part, "^plstem:", "")
			else
				error("Unrecognized indicator '" .. part .. "': '" .. inside .. "'")
			end
		end
	end
	return base
end


local function add_stress_for_pattern(stress, stem)
	local where_stress = stress_patterns[stress.stress].stress
	if where_stress == "last" then
		return com.maybe_stress_final_syllable(stem)
	elseif where_stress == "first" then
		return com.maybe_stress_initial_syllable(stem)
	elseif not com.is_stressed(stem) then
		error("Something wrong: Stress pattern " .. stress.stress .. " but stem '" .. stem .. "' doesn't have stress")
	else
		return stem
	end
end


local function set_defaults_and_check_bad_indicators(base)
	-- Set default values.
	if not base.adj then
		base.number = base.number or "both"
		base.animacy = base.animacy or base.surname and "pr" or
			base.neutertype == "t" and "anml" or
			"inan"
	end
	base.gender = base.explicit_gender

	-- Set some further defaults and check for certain bad indicator/number/gender combinations.
	if base.thirddecl then
		if base.number ~= "pl" then
			error("'3rd' can only be specified along with 'pl'")
		end
		if base.gender and base.gender ~= "F" then
			error("'3rd' can't specified with non-feminine gender indicator '" .. base.gender .. "'")
		end
		base.gender = "F"
	end
	if base.neutertype then
		if base.gender and base.gender ~= "N" then
			error("Neuter-type indicator '" .. base.neutertype .. "' can't specified with non-neuter gender indicator '" .. base.gender .. "'")
		end
		base.gender = "N"
	end
end


local function undo_vowel_alternation(base, stem)
	if base.ialt == "io" then
		local modstem = rsub(stem, "([оО])(́?" .. com.cons_c .. "*)$",
			function(vowel, post)
				if vowel == "о" then
					return "і" .. post
				else
					return "І" .. post
				end
			end
		)
		if modstem == stem then
			error("Indicator 'io' can't be undone because stem '" .. stem .. "' doesn't have о as its last vowel")
		end
		return modstem
	elseif base.ialt == "ijo" then
		local modstem = rsub(stem, "ьо(́?" .. com.cons_c .. "*)$", "і%1")
		if modstem == stem then
			error("Indicator 'ijo' can't be undone because stem '" .. stem .. "' doesn't have ьо as its last vowel")
		end
		return modstem
	elseif base.ialt == "ie" then
		local modstem = rsub(stem, "([еЕєЄ])(́?" .. com.cons_c .. "*)$",
			function(vowel, post)
				local reverse_vowel = {
					["е"] = "і",
					["Е"] = "І",
					["є"] = "ї",
					["Є"] = "Ї",
				}
				return reverse_vowel[vowel] .. post
			end
		)
		if modstem == stem then
			error("Indicator 'ie' can't be undone because stem '" .. stem .. "' doesn't have е or є as its last vowel")
		end
		return modstem
	elseif base.ialt == "i" then
		error("Don't currently know how to undo 'i' vowel alternation")
	else
		return stem
	end
end


-- For a plural-only lemma, synthesize a likely singular lemma. It doesn't have to be
-- theoretically correct as long as it generates all the correct plural forms (which mostly
-- means the nominative and genitive plural as the remainder are either derived or the same
-- for all declensions, modulo soft vs. hard).
local function synthesize_singular_lemma(base)
	local stem, ac
	while true do
		-- Check neuter endings.
		if base.neutertype == "t" then
			stem, ac = rmatch(base.lemma, "^(.*[яа])(́)та$")
			if stem then
				base.lemma = stem .. ac
				break
			end
			error("Unrecognized lemma for 't' indicator: '" .. base.lemma .. "'")
		end
		stem, ac = rmatch(base.lemma, "^(.*" .. com.hushing_c .. ")а(́?)$")
		if stem then
			base.lemma = stem .. "е" .. ac
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*)а(́?)$")
		if stem then
			base.lemma = stem .. "о" .. ac
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*)я(́?)$")
		if stem then
			-- Conceivably it should have the -я ending in the singular but I don't
			-- think it matters.
			base.lemma = stem .. "е" .. ac
			break
		end
		-- Handle masculine/feminine endings.
		stem, ac = rmatch(base.lemma, "^(.*)и(́?)$")
		if stem then
			if not base.gender then
				error("For plural-only lemma in -и, need to specify the gender: '" .. base.lemma .. "'")
			end
			if base.gender == "M" then
				base.lemma = undo_vowel_alternation(base, stem)
			else
				base.lemma = stem .. "а" .. ac
			end
			break
		end
		local vowel
		stem, vowel, ac = rmatch(base.lemma, "^(.*)([ії])(́?)$")
		if stem then
			if not base.gender then
				error("For plural-only lemma in -" .. vowel .. ", need to specify the gender: '" .. base.lemma .. "'")
			end
			if base.gender == "M" then
				if rfind(stem, "[дтсзлнц]$") then
					base.lemma = stem .. "ь"
				elseif rfind(stem, "р$") then
					base.lemma = stem
					if not base.rtype then
						-- add an override to cause the -і/-ї to appear
						table.insert(base.overrides, {values = {{form = vowel}}})
					end
				elseif vowel == "ї" then
					base.lemma = stem .. "й"
				else
					base.lemma = stem
				end
				base.lemma = undo_vowel_alternation(base, base.lemma)
			elseif base.gender == "F" or base.gender == "MF" then
				if base.thirddecl then
					if rfind(stem, "[дтсзлнц]$") then
						base.lemma = stem .. "ь"
					else
						base.lemma = stem
					end
					base.lemma = undo_vowel_alternation(base, base.lemma)
				elseif rfind(stem, com.hushing_c .. "$") then
					base.lemma = stem .. "а" .. ac
				else
					base.lemma = stem .. "я" .. ac
				end
			else
				error("Don't know how to handle neuter plural-only nouns in -" .. vowel .. ": '" .. base.lemma .. "'")
			end
			break
		end
		error("Don't recognize ending of lemma '" .. base.lemma .. "'")
	end

	-- Now set the stress pattern if not given.
	if not base.stresses then
		base.stresses = {{reducible = false, genpl_reversed = false}}
	end
	for _, stress in ipairs(base.stresses) do
		if not stress.stress then
			if ac == AC then
				stress.stress = "b"
			else
				stress.stress = "a"
			end
		end
	end
end


-- For an adjectival lemma, synthesize the masc singular form.
local function synthesize_adj_lemma(base)
	local stem, ac
	local gender, number
	while true do
		-- Masculine
		stem, ac = rmatch(base.lemma, "^(.*)[иії](́?)й$")
		if stem then
			gender = "M"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*[оеєії]́?в)$")
		if stem then
			gender = "M"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*[иії]́?н)$")
		if stem then
			gender = "M"
			break
		end
		-- Feminine
		stem, ac = rmatch(base.lemma, "^(.*)а(́?)$")
		if stem then
			base.lemma = stem .. "и" .. ac .. "й"
			gender = "F"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*ц)я(́?)$")
		if stem then
			base.lemma = stem .. "и" .. ac .. "й"
			gender = "F"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*" .. com.vowel .. AC .. "?)я(́?)$")
		if stem then
			base.lemma = stem .. "ї" .. ac .. "й"
			gender = "F"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*)я(́?)$")
		if stem then
			base.lemma = stem .. "і" .. ac .. "й"
			gender = "F"
			break
		end
		-- Neuter
		stem, ac = rmatch(base.lemma, "^(.*)е(́?)$")
		if stem then
			base.lemma = stem .. "и" .. ac .. "й"
			gender = "N"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*ц)е(́?)$")
		if stem then
			base.lemma = stem .. "и" .. ac .. "й"
			gender = "N"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*" .. com.vowel .. AC .. "?)є(́?)$")
		if stem then
			base.lemma = stem .. "ї" .. ac .. "й"
			gender = "N"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*)є(́?)$")
		if stem then
			base.lemma = stem .. "і" .. ac .. "й"
			gender = "N"
			break
		end
		-- Plural
		stem, ac = rmatch(base.lemma, "^(.*ц)і(́?)$")
		if stem then
			base.lemma = stem .. "и" .. ac .. "й"
			number = "pl"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*" .. com.vowel .. AC .. "?)ї(́?)$")
		if stem then
			base.lemma = stem .. "ї" .. ac .. "й"
			number = "pl"
			break
		end
		stem, ac = rmatch(base.lemma, "^(.*)і(́?)$")
		if stem then
			if base.soft then
				base.lemma = stem .. "і" .. ac .. "й"
			else
				base.lemma = stem .. "и" .. ac .. "й"
			end
			number = "pl"
			break
		end
		error("Don't recognize ending of adjectival lemma '" .. base.lemma .. "'")
	end
	if gender then
		if base.gender and base.gender ~= gender then
			error("Explicit gender '" .. base.gender .. "' disagrees with detected gender '" .. gender .. "'")
		end
		base.gender = gender
	end
	if number then
		if base.number and base.number ~= number then
			error("Explicit number '" .. base.number .. "' disagrees with detected number '" .. number .. "'")
		end
		base.number = number
	end

	-- Now set the stress pattern if not given.
	if not base.stresses then
		base.stresses = {{reducible = false, genpl_reversed = false}}
	end
	for _, stress in ipairs(base.stresses) do
		if not stress.stress then
			if ac == AC then
				stress.stress = "b"
			else
				stress.stress = "a"
			end
		end
		-- Set the stems.
		stress.vowel_stem = stem
		stress.nonvowel_stem = stem
		stress.pl_vowel_stem = stem
		stress.pl_nonvowel_stem = stem
	end
	base.decl = "adj"
end


local function check_indicators_match_lemma(base)
	-- Check for indicators that don't make sense given the context.
	if base.rtype and not rfind(base.lemma, "р$") then
		error("'р' type indicator '" .. base.rtype .. "' can only be specified with a lemma ending in -р")
	end
	if base.remove_in and not rfind(base.lemma, "и́?н$") then
		error("'in' can only be specified with a lemma ending in -ин")
	end
	if base.neutertype then
		if not rfind(base.lemma, "я́?$") and not rfind(base.lemma, com.hushing_c .. "а́?$") then
			error("Neuter-type indicator '" .. base.neutertype .. "' can only be specified with a lemma ending in -я or hushing consonant + -а")
		end
		if base.neutertype == "en" and not rfind(base.lemma, "м'я́?$") then
			error("Neuter-type indicator 'en' can only be specified with a lemma ending in -м'я")
		end
	end
end


-- Determine the declension based on the lemma and whatever gender has been already given,
-- and set the gender to a default if not given. The declension is set in base.decl.
-- In the process, we set either base.vowel_stem (if the lemma ends in a vowel) or
-- base.nonvowel_stem (if the lemma does not end in a vowel), which is used by
-- determine_stress_and_stems().
local function determine_declension_and_gender(base)
	-- Determine declension and set gender
	local stem
	stem = rmatch(base.lemma, "^(.*)ь$")
	if stem then
		if not base.gender then
			if rfind(base.lemma, "[еє]́?ць$") then
				base.gender = "M"
			elseif rfind(base.lemma, "тель$") then
				base.gender = "M"
			elseif rfind(base.lemma, "[ії]сть$") then
				base.gender = "F"
			else
				error("For lemma ending in -ь other than -ець/-єць/-тель/-ість/-їсть, gender M or F must be given")
			end
		end
		if base.gender == "N" or base.gender == "MF" then
			error("For lemma ending in -ь, gender " .. base.gender .. " not allowed")
		elseif base.gender == "M" then
			base.decl = "soft-m"
		else
			base.decl = "third-f"
		end
		base.nonvowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)й$")
	if stem then
		base.decl = "j-m"
		if base.gender and base.gender ~= "M" then
			error("For lemma ending in -й, gender " .. base.gender .. " not allowed")
		end
		base.gender = "M"
		base.nonvowel_stem = stem
		base.stem_for_reduce = base.lemma
		return
	end
	stem = rmatch(base.lemma, "^(.*" .. com.hushing_c .. ")$")
	if stem then
		if base.gender == "N" or base.gender == "MF" then
			error("For lemma ending in a hushing consonant, gender " .. base.gender .. " not allowed")
		elseif base.gender == "F" then
			base.decl = "third-f"
		else
			base.gender = "M"
			base.decl = "semisoft-m"
		end
		base.nonvowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*" .. com.hushing_c .. ")а́?$")
	if stem then
		if base.neutertype == "t" then
			base.decl = "t-n"
		elseif base.gender == "N" then
			error("For lemma ending in a hushing consonant + -а, gender N not allowed unless spec 't' is given")
		else
			base.decl = "semisoft-f"
			base.gender = base.gender or "F"
		end
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)а́?$")
	if stem then
		base.decl = "hard-f"
		if base.gender == "N" then
			error("For lemma ending in -а, gender N not allowed")
		end
		base.gender = base.gender or "F"
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)я́?$")
	if stem then
		if base.neutertype == "en" then
			base.decl = "en-n"
		elseif base.neutertype == "t" then
			base.decl = "t-n"
		elseif base.gender == "N" then
			base.decl = "ja-n"
		elseif not base.gender and (rfind(stem, "'$") or rfind(stem, "(.)%1$")) then
			base.decl = "ja-n"
			base.gender = "N"
		elseif rfind(stem, com.vowel_c .. AC .. "?$") or rfind(stem, "['ьй]$") then
			base.decl = "j-f"
			base.gender = base.gender or "F"
		else
			base.decl = "soft-f"
			base.gender = base.gender or "F"
		end
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)о́?$")
	if stem then
		if base.gender == "M" or base.gender == "F" or base.gender == "MF" then
			if rfind(stem, "ь$") then
				stem = rsub(stem, "ь$", "")
				base.decl = "soft-o-m"
			else
				base.decl = "o-m"
			end
		else
			base.decl = "hard-n"
			base.gender = "N"
		end
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*" .. com.hushing_c .. ")е́?$")
	if stem then
		if base.gender == "M" then
			base.decl = "semisoft-e-m"
		elseif base.gender == "F" then
			base.decl = "semisoft-e-f"
		else
			base.decl = "semisoft-n"
			if base.gender == "MF" then
				error("For lemma ending in -е, gender " .. base.gender .. " not allowed")
			end
			base.gender = base.gender or "N"
		end
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)е́?$")
	if stem then
		base.decl = "soft-n"
		if base.gender == "F" or base.gender == "MF" then
			error("For lemma ending in -е, gender " .. base.gender .. " not allowed")
		end
		base.gender = base.gender or "N"
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*)є́?$")
	if stem then
		base.decl = "j-n"
		if base.gender == "F" or base.gender == "MF" then
			error("For lemma ending in -є, gender " .. base.gender .. " not allowed")
		end
		base.gender = base.gender or "N"
		base.vowel_stem = stem
		return
	end
	stem = rmatch(base.lemma, "^(.*" .. com.cons_c .. ")$")
	if stem then
		if base.gender == "N" or base.gender == "MF" then
			error("For lemma ending in a consonant, gender " .. base.gender .. " not allowed")
		elseif base.gender == "F" then
			base.decl = "third-f"
		elseif base.rtype == "soft" then
			base.decl = "soft-m"
		elseif base.rtype == "semisoft" then
			base.decl = "semisoft-m"
		else
			base.decl = "hard-m"
		end
		base.gender = base.gender or "M"
		base.nonvowel_stem = stem
		return
	end
	error("Unrecognized ending for lemma: '" .. base.lemma .. "'")
end


-- Determine the stress pattern(s) if not explicitly given, as well as the stems
-- to use for each specified stress pattern: vowel and nonvowel stems, for singular
-- and plural. We assume that one of base.vowel_stem or base.nonvowel_stem has been
-- set in determine_declension_and_gender(), depending on whether the lemma ends in
-- a vowel. We construct all the rest given the stress pattern, reducibility, and
-- any explicit stems given. We store the determined stems inside of the stress objects
-- in `base.stresses`, meaning that if the user gave multiple stress patterns, we
-- will compute multiple sets of stems. The reason is that the stems may vary depending
-- on the stress pattern and reducibility. The dependency on reducibility should be
-- obvious but there is also dependency on the stress pattern in that in stress patterns
-- d, d', f and f' the lemma is given in end-stressed form but some other forms need to
-- be stem-stressed. We make the stems stressed on the last syllable for pattern d
-- (множина́ pl. множи́ни) but but on the first syllable for the remaining patterns
-- (голова́ pl. го́лови, сковорода́ pl. ско́вороди, both pattern d').
local function determine_stress_and_stems(base)
	if not base.stresses then
		base.stresses = {{reducible = false, genpl_reversed = false}}
	end
	if base.stem then
		base.stem = com.add_monosyllabic_stress(base.stem)
	end
	if base.plstem then
		base.plstem = com.add_monosyllabic_stress(base.plstem)
	end
	local end_stressed_lemma = rfind(base.lemma, AC .. "$")
	for _, stress in ipairs(base.stresses) do
		local function dereduce(stem)
			local epenthetic_stress = stress_patterns[stress.stress].gen_p == "+"
			if stress.genpl_reversed then
				epenthetic_stress = not epenthetic_stress
			end
			local dereduced_stem = com.dereduce(stem, epenthetic_stress)
			if not dereduced_stem then
				error("Unable to dereduce stem '" .. stem .. "'")
			end
			return dereduced_stem
		end
		if not stress.stress then
			if base.gender ~= "N" and rfind(base.lemma, "[ое]́$") then
				-- masculine or feminine in -о or -е
				stress.stress = "b"
			elseif stress.reducible and rfind(base.lemma, "[еоєі]́" .. com.cons_c .. "ь?$") then
				-- reducible with stress on the reducible vowel
				stress.stress = "b"
			elseif rfind(base.lemma, "[ая]́$") and base.gender == "N" then
				stress.stress = "b"
			elseif end_stressed_lemma then
				stress.stress = "d"
			else
				stress.stress = "a"
			end
		end
		if stress.stress ~= "b" then
			if base.stem and com.needs_accents(base.stem) then
				error("Explicit stem needs an accent with stress pattern " .. stress.stress .. ": '" .. base.stem .. "'")
			end
			if base.plstem and com.needs_accents(base.plstem) then
				error("Explicit plural stem needs an accent with stress pattern " .. stress.stress .. ": '" .. base.plstem .. "'")
			end
		end
		local lemma_is_vowel_stem = not not base.vowel_stem
		if base.vowel_stem then
			if end_stressed_lemma and stress_patterns[stress.stress].nom_s ~= "+" then
				error("Stress pattern " .. stress.stress .. " requires a stem-stressed lemma, not end-stressed: '" .. base.lemma .. "'")
			elseif not end_stressed_lemma and stress_patterns[stress.stress].nom_s == "+" then
				error("Stress pattern " .. stress.stress .. " requires an end-stressed lemma, not stem-stressed: '" .. base.lemma .. "'")
			end
			if base.stem then
				error("Can't specify 'stem:' with lemma ending in a vowel")
			end
			stress.vowel_stem = add_stress_for_pattern(stress, base.vowel_stem)
			if base.gender == "N" and rfind(base.lemma, "(.)%1я́?$") then
				-- значе́ння -> gen pl значе́нь
				stress.nonvowel_stem = rsub(stress.vowel_stem, ".$", "")
			else
				stress.nonvowel_stem = stress.vowel_stem
			end
			-- Apply vowel alternation first in cases like війна́ -> во́єн;
			-- apply_vowel_alternation() will throw an error if the vowel being
			-- modified isn't the last vowel in the stem.
			stress.nonvowel_stem, stress.origvowel = com.apply_vowel_alternation(base.ialt, stress.nonvowel_stem)
			if stress.reducible then
				stress.nonvowel_stem = dereduce(stress.nonvowel_stem)
			end
		else
			stress.nonvowel_stem = add_stress_for_pattern(stress, base.nonvowel_stem)
			if stress.reducible then
				local stem_to_reduce = base.stem_for_reduce or base.nonvowel_stem
				stress.vowel_stem = com.reduce(stem_to_reduce)
				if not stress.vowel_stem then
					error("Unable to reduce stem '" .. stem_to_reduce .. "'")
				end
			else
				stress.vowel_stem = base.nonvowel_stem
			end
			if base.stem and base.stem ~= stress.vowel_stem then
				stress.irregular_stem = true
				stress.vowel_stem = base.stem
			end
			stress.vowel_stem, stress.origvowel = com.apply_vowel_alternation(base.ialt, stress.vowel_stem)
			stress.vowel_stem = add_stress_for_pattern(stress, stress.vowel_stem)
		end
		if base.remove_in then
			stress.pl_vowel_stem = com.maybe_stress_final_syllable(rsub(stress.vowel_stem, "и́?н$", ""))
			stress.pl_nonvowel_stem = stress.pl_vowel_stem
		else
			stress.pl_vowel_stem = stress.vowel_stem
			stress.pl_nonvowel_stem = stress.nonvowel_stem
		end
		if base.plstem then
			local stressed_plstem = add_stress_for_pattern(stress, base.plstem)
			if stressed_plstem ~= stress.pl_vowel_stem then
				stress.irregular_plstem = true
			end
			stress.pl_vowel_stem = stressed_plstem
			if lemma_is_vowel_stem then
				-- If the original lemma ends in a vowel (neuters and most feminines),
				-- apply i/e/o vowel alternations and dereductions to the explicit plural
				-- stem, because they most likely apply in the genitive plural. This is
				-- needed for various words, e.g. ко́лесо (plstem коле́с-, gen pl колі́с,
				-- alternative ins pl колі́сьми, both with е -> і alternation); гра
				-- (plstem ігр-, gen pl і́гор, with dereduction); likewise ре́шето with
				-- special plstem and е -> і alternation and скло with special plstem and
				-- dereduction. But we don't want it in lemmas ending in a consonant,
				-- where the vowel alternations and reductions apply between nom sg and
				-- the remaining forms, not generally in the plural. For example, со́кіл
				-- "falcon" has both і -> о alternation (vowel stem со́кол-) and special
				-- plstem соко́л-, but we can't and don't want to apply an і -> о
				-- alternation to the plstem.
				stress.pl_nonvowel_stem = com.apply_vowel_alternation(base.ialt, stressed_plstem)
				if stress.reducible then
					stress.pl_nonvowel_stem = dereduce(stress.pl_nonvowel_stem)
				end
			else
				stress.pl_nonvowel_stem = stressed_plstem
			end
		end
	end
end


local function detect_indicator_spec(base)
	set_defaults_and_check_bad_indicators(base)
	if base.adj then
		synthesize_adj_lemma(base)
	else
		if base.number == "pl" then
			synthesize_singular_lemma(base)
		end
		check_indicators_match_lemma(base)
		determine_declension_and_gender(base)
		determine_stress_and_stems(base)
	end
end


local function detect_all_indicator_specs(alternant_multiword_spec)
	local is_multiword = #alternant_multiword_spec.alternant_or_word_specs > 1
	iut.map_word_specs(alternant_multiword_spec, function(base)
		detect_indicator_spec(base)
		base.multiword = is_multiword
	end)
end


local propagate_multiword_properties


local function propagate_alternant_properties(alternant_spec, property, mixed_value, nouns_only)
	local seen_property
	for _, multiword_spec in ipairs(alternant_spec.alternants) do
		propagate_multiword_properties(multiword_spec, property, mixed_value, nouns_only)
		if seen_property == nil then
			seen_property = multiword_spec[property]
		elseif multiword_spec[property] and seen_property ~= multiword_spec[property] then
			seen_property = mixed_value
		end
	end
	alternant_spec[property] = seen_property
end


propagate_multiword_properties = function(multiword_spec, property, mixed_value, nouns_only)
	local seen_property = nil
	local last_seen_nounal_pos = 0
	local word_specs = multiword_spec.alternant_or_word_specs or multiword_spec.word_specs
	for i = 1, #word_specs do
		local is_nounal
		if word_specs[i].alternants then
			propagate_alternant_properties(word_specs[i], property, mixed_value)
			is_nounal = not not word_specs[i][property]
		elseif nouns_only then
			is_nounal = not word_specs[i].adj
		else
			is_nounal = not not word_specs[i][property]
		end
		if is_nounal then
			if not word_specs[i][property] then
				error("Internal error: noun-type word spec without " .. property .. " set")
			end
			for j = last_seen_nounal_pos + 1, i - 1 do
				word_specs[j][property] = word_specs[j][property] or word_specs[i][property]
			end
			last_seen_nounal_pos = i
			if seen_property == nil then
				seen_property = word_specs[i][property]
			elseif seen_property ~= word_specs[i][property] then
				seen_property = mixed_value
			end
		end
	end
	if last_seen_nounal_pos > 0 then
		for i = last_seen_nounal_pos + 1, #word_specs do
			word_specs[i][property] = word_specs[i][property] or word_specs[last_seen_nounal_pos][property]
		end
	end
	multiword_spec[property] = seen_property
end


local function propagate_properties_downward(alternant_multiword_spec, property, default_propval)
	local propval1 = alternant_multiword_spec[property] or default_propval
	for _, alternant_or_word_spec in ipairs(alternant_multiword_spec.alternant_or_word_specs) do
		local propval2 = alternant_or_word_spec[property] or propval1
		if alternant_or_word_spec.alternants then
			for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
				local propval3 = multiword_spec[property] or propval2
				for _, word_spec in ipairs(multiword_spec.word_specs) do
					local propval4 = word_spec[property] or propval3
					if propval4 == "mixed" then
						error("Attempt to assign mixed " .. property .. " to word")
					end
					word_spec[property] = propval4
				end
			end
		else
			if propval2 == "mixed" then
				error("Attempt to assign mixed " .. property .. " to word")
			end
			alternant_or_word_spec[property] = propval2
		end
	end
end


--[=[
Propagate `property` (one of "animacy", "gender" or "number") from nouns to adjacent
adjectives. We proceed as follows:
1. We assume the properties in question are already set on all nouns. This should happen
   in set_defaults_and_check_bad_indicators().
2. We first propagate properties upwards and sideways. We recurse downwards from the top.
   When we encounter a multiword spec, we proceed left to right looking for a noun.
   When we find a noun, we fetch its property (recursing if the noun is an alternant),
   and propagate it to any adjectives to its left, up to the next noun to the left.
   When we have processed the last noun, we also propagate its property value to any
   adjectives to the right (to handle e.g. [[лунь польовий]] "hen harrier", where the
   adjective польовий should inherit the 'animal' animacy of лунь). Finally, we set
   the property value for the multiword spec itself by combining all the non-nil
   properties of the individual elements. If all non-nil properties have the same value,
   the result is that value, otherwise it is `mixed_value` (which is "mixed" for animacy
   and gender, but "both" for number).
3. When we encounter an alternant spec in this process, we recursively process each
   alternant (which is a multiword spec) using the previous step, and combine any
   non-nil properties we encounter the same way as for multiword specs.
4. The effect of steps 2 and 3 is to set the property of each alternant and multiword
   spec based on its children or its neighbors.
]=]
local function propagate_properties(alternant_multiword_spec, property, default_propval, mixed_value)
	propagate_multiword_properties(alternant_multiword_spec, property, mixed_value, "nouns only")
	propagate_multiword_properties(alternant_multiword_spec, property, mixed_value, false)
	propagate_properties_downward(alternant_multiword_spec, property, default_propval)
end


local function determine_noun_status(alternant_multiword_spec)
	for i, alternant_or_word_spec in ipairs(alternant_multiword_spec.alternant_or_word_specs) do
		if alternant_or_word_spec.alternants then
			local is_noun = false
			for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
				for j, word_spec in ipairs(multiword_spec.word_specs) do
					if not word_spec.adj then
						multiword_spec.first_noun = j
						is_noun = true
						break
					end
				end
			end
			if is_noun then
				alternant_multiword_spec.first_noun = i
			end
		elseif not alternant_or_word_spec.adj then
			alternant_multiword_spec.first_noun = i
			return
		end
	end
end


-- Check that multisyllabic lemmas have stress, and add stress to monosyllabic
-- lemmas if needed.
local function normalize_all_lemmas(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		base.orig_lemma = base.lemma
		base.orig_lemma_no_links = com.add_monosyllabic_stress(m_links.remove_links(base.lemma))
		base.lemma = base.orig_lemma_no_links
		if not rfind(base.lemma, AC) then
			error("Multisyllabic lemma '" .. base.orig_lemma .. "' needs an accent")
		end
	end)
end


local function decline_noun(base)
	for _, stress in ipairs(base.stresses) do
		if not decls[base.decl] then
			error("Internal error: Unrecognized declension type '" .. base.decl .. "'")
		end
		decls[base.decl](base, stress)
	end
	handle_derived_slots_and_overrides(base)
end


local function get_variants(form)
	return
		form:find(com.VAR1) and "var1" or
		form:find(com.VAR2) and "var2" or
		form:find(com.VAR3) and "var3" or
		nil
end


local function process_manual_overrides(forms, args, number, unknown_stress)
	local params_to_slots_map =
		number == "sg" and input_params_to_slots_sg or
		number == "pl" and input_params_to_slots_pl or
		input_params_to_slots_both
	for param, slot in pairs(params_to_slots_map) do
		if args[param] then
			forms[slot] = nil
			if args[param] ~= "-" and args[param] ~= "—" then
				for _, form in ipairs(rsplit(args[param], "%s*,%s*")) do
					if com.is_multi_stressed(form) then
						error("Multi-stressed form '" .. form .. "' in slot '" .. slot .. "' not allowed; use singly-stressed forms separated by commas")
					end
					if not unknown_stress and not rfind(form, "^%-") and com.needs_accents(form) then
						error("Stress required in multisyllabic form '" .. form .. "' in slot '" .. slot .. "'; if stress is truly unknown, use unknown_stress=1")
					end
					iut.insert_form(forms, slot, {form=form})
				end
			end
		end
	end
end


-- Compute the categories to add the noun to, as well as the annotation to display in the
-- declension title bar. We combine the code to do these functions as both categories and
-- title bar contain similar information.
local function compute_categories_and_annotation(alternant_multiword_spec)
	local cats = {}
	local function insert(cattype)
		m_table.insertIfNot(cats, "Ukrainian " .. cattype)
	end
	if alternant_multiword_spec.pos == "noun" then
		if alternant_multiword_spec.number == "sg" then
			insert("uncountable nouns")
		elseif alternant_multiword_spec.number == "pl" then
			insert("pluralia tantum")
		end
	end
	local annotation
	if alternant_multiword_spec.manual then
		alternant_multiword_spec.annotation =
			alternant_multiword_spec.number == "sg" and "sg-only" or
			alternant_multiword_spec.number == "pl" and "pl-only" or
			""
	else
		local annparts = {}
		local animacies = {}
		local decldescs = {}
		local patterns = {}
		local vowelalts = {}
		local irregs = {}
		local stems = {}
		local reducible = nil
		local function do_word_spec(base)
			if base.animacy == "inan" then
				m_table.insertIfNot(animacies, "inan")
			elseif base.animacy == "anml" then
				m_table.insertIfNot(animacies, "animal")
			else
				assert(base.animacy == "pr")
				m_table.insertIfNot(animacies, "pers")
			end
			for _, stress in ipairs(base.stresses) do
				local props = declprops[base.decl]
				local desc = props.desc
				if type(desc) == "function" then
					desc = desc(base, stress)
				end
				m_table.insertIfNot(decldescs, desc)
				local cats = props.cat
				if type(cats) == "function" then
					cats = cats(base, stress)
				end
				if type(cats) == "string" then
					cats = {cats .. " nouns", cats .. " ~ nouns"}
				end
				for _, cat in ipairs(cats) do
					cat = rsub(cat, "~", "accent-" .. stress.stress)
					insert(cat)
				end
				m_table.insertIfNot(patterns, stress.stress)
				insert("nouns with accent pattern " .. stress.stress)
				local vowelalt
				if base.ialt == "ie" then
					vowelalt = "і-е"
				elseif base.ialt == "io" then
					vowelalt = "і-о"
				elseif base.ialt == "ijo" then
					vowelalt = "і-ьо"
				elseif base.ialt == "i" then
					if not stress.origvowel then
						error("Internal error: Original vowel not set along with 'i' code")
					end
					vowelalt = ulower(stress.origvowel) .. "-і"
				end
				if vowelalt then
					m_table.insertIfNot(vowelalts, vowelalt)
					insert("nouns with " .. vowelalt .. " alternation")
				end
				if reducible == nil then
					reducible = stress.reducible
				elseif reducible ~= stress.reducible then
					reducible = "mixed"
				end
				if stress.reducible then
					insert("nouns with reducible stem")
				end
				if stress.irregular_stem then
					m_table.insertIfNot(irregs, "irreg-stem")
					insert("nouns with irregular stem")
				end
				if stress.irregular_plstem then
					m_table.insertIfNot(irregs, "irreg-plstem")
					insert("nouns with irregular plural stem")
				end
				m_table.insertIfNot(stems, stress.vowel_stem)
			end
		end
		local key_entry = alternant_multiword_spec.first_noun or 1
		if #alternant_multiword_spec.alternant_or_word_specs >= key_entry then
			local alternant_or_word_spec = alternant_multiword_spec.alternant_or_word_specs[key_entry]
			if alternant_or_word_spec.alternants then
				for _, multiword_spec in ipairs(alternant_or_word_spec.alternants) do
					key_entry = multiword_spec.first_noun or 1
					if #multiword_spec.word_specs >= key_entry then
						do_word_spec(multiword_spec.word_specs[key_entry])
					end
				end
			else
				do_word_spec(alternant_or_word_spec)
			end
		end
		if #animacies > 0 then
			table.insert(annparts, table.concat(animacies, "/"))
		end
		if alternant_multiword_spec.number ~= "both" then
			table.insert(annparts, alternant_multiword_spec.number == "sg" and "sg-only" or "pl-only")
		end
		if #decldescs == 0 then
			table.insert(annparts, "indecl")
		else
			table.insert(annparts, table.concat(decldescs, " // "))
		end
		if #patterns > 0 then
			table.insert(annparts, "accent-" .. table.concat(patterns, "/"))
		end
		if #vowelalts > 0 then
			table.insert(annparts, table.concat(vowelalts, "/"))
		end
		if reducible == "mixed" then
			table.insert(annparts, "mixed-reduc")
		elseif reducible then
			table.insert(annparts, "reduc")
		end
		if #irregs > 0 then
			table.insert(annparts, table.concat(irregs, " // "))
		end
		alternant_multiword_spec.annotation = table.concat(annparts, " ")
		if #patterns > 1 then
			insert("nouns with multiple accent patterns")
		end
		if #stems > 1 then
			insert("nouns with multiple stems")
		end
	end
	alternant_multiword_spec.categories = cats
end


local function show_forms(alternant_multiword_spec)
	local lemmas = {}
	if alternant_multiword_spec.forms.nom_s then
		for _, nom_s in ipairs(alternant_multiword_spec.forms.nom_s) do
			table.insert(lemmas, com.remove_monosyllabic_stress(nom_s.form))
		end
	elseif alternant_multiword_spec.forms.nom_p then
		for _, nom_p in ipairs(alternant_multiword_spec.forms.nom_p) do
			table.insert(lemmas, com.remove_monosyllabic_stress(nom_p.form))
		end
	end
	local props = {
		lemmas = lemmas,
		slot_table = output_noun_slots_with_linked,
		lang = lang,
		canonicalize = function(form)
			return com.remove_variant_codes(com.remove_monosyllabic_stress(form))
		end,
		include_translit = true,
		-- Explicit additional top-level footnotes only occur with {{uk-ndecl-manual}} and variants.
		footnotes = alternant_multiword_spec.footnotes,
		allow_footnote_symbols = not not alternant_multiword_spec.footnotes,
	}
	iut.show_forms(alternant_multiword_spec.forms, props)
end


local function make_table(alternant_multiword_spec)
	local forms = alternant_multiword_spec.forms

	local table_spec_both = [=[
<div class="NavFrame" style="display: inline-block;min-width: 45em">
<div class="NavHead" style="background:#eff7ff" >{title}{annotation}</div>
<div class="NavContent">
{\op}| style="background:#F9F9F9;text-align:center;min-width:45em" class="inflection-table"
|-
! style="width:33%;background:#d9ebff" |
! style="background:#d9ebff" | singular
! style="background:#d9ebff" | plural
|-
!style="background:#eff7ff"|nominative
| {nom_s}
| {nom_p}
|-
!style="background:#eff7ff"|genitive
| {gen_s}
| {gen_p}
|-
!style="background:#eff7ff"|dative
| {dat_s}
| {dat_p}
|-
!style="background:#eff7ff"|accusative
| {acc_s}
| {acc_p}
|-
!style="background:#eff7ff"|instrumental
| {ins_s}
| {ins_p}
|-
!style="background:#eff7ff"|locative
| {loc_s}
| {loc_p}
|-
!style="background:#eff7ff"|vocative
| {voc_s}
| {voc_p}
|{\cl}{notes_clause}</div></div>]=]

	local table_spec_sg = [=[
<div class="NavFrame" style="width:30em">
<div class="NavHead" style="background:#eff7ff">{title}{annotation}</div>
<div class="NavContent">
{\op}| style="background:#F9F9F9;text-align:center;width:30em" class="inflection-table"
|-
! style="width:33%;background:#d9ebff" |
! style="background:#d9ebff" | singular
|-
!style="background:#eff7ff"|nominative
| {nom_s}
|-
!style="background:#eff7ff"|genitive
| {gen_s}
|-
!style="background:#eff7ff"|dative
| {dat_s}
|-
!style="background:#eff7ff"|accusative
| {acc_s}
|-
!style="background:#eff7ff"|instrumental
| {ins_s}
|-
!style="background:#eff7ff"|locative
| {loc_s}
|-
!style="background:#eff7ff"|vocative
| {voc_s}
|{\cl}{notes_clause}</div></div>]=]

	local table_spec_pl = [=[
<div class="NavFrame" style="width:30em">
<div class="NavHead" style="background:#eff7ff">{title}{annotation}</div>
<div class="NavContent">
{\op}| style="background:#F9F9F9;text-align:center;width:30em" class="inflection-table"
|-
! style="width:33%;background:#d9ebff" |
! style="background:#d9ebff" | plural
|-
!style="background:#eff7ff"|nominative
| {nom_p}
|-
!style="background:#eff7ff"|genitive
| {gen_p}
|-
!style="background:#eff7ff"|dative
| {dat_p}
|-
!style="background:#eff7ff"|accusative
| {acc_p}
|-
!style="background:#eff7ff"|instrumental
| {ins_p}
|-
!style="background:#eff7ff"|locative
| {loc_p}
|-
!style="background:#eff7ff"|vocative
| {voc_p}
|{\cl}{notes_clause}</div></div>]=]

	local notes_template = [===[
<div style="width:100%;text-align:left;background:#d9ebff">
<div style="display:inline-block;text-align:left;padding-left:1em;padding-right:1em">
{footnote}
</div></div>
]===]

	if alternant_multiword_spec.title then
		forms.title = alternant_multiword_spec.title
	else
		forms.title = 'Declension of <i lang="uk" class="Cyrl">' .. forms.lemma .. '</i>'
	end

	local annotation = alternant_multiword_spec.annotation
	if annotation == "" then
		forms.annotation = ""
	else
		forms.annotation = " (<span style=\"font-size: smaller;\">" .. annotation .. "</span>)"
	end

	local table_spec =
		alternant_multiword_spec.number == "sg" and table_spec_sg or
		alternant_multiword_spec.number == "pl" and table_spec_pl or
		table_spec_both
	forms.notes_clause = forms.footnote ~= "" and
		m_string_utilities.format(notes_template, forms) or ""
	return m_string_utilities.format(table_spec, forms)
end


local function compute_headword_genders(alternant_multiword_spec)
	local genders = {}
	local number
	if alternant_multiword_spec.number == "pl" then
		number = "-p"
	else
		number = ""
	end
	iut.map_word_specs(alternant_multiword_spec, function(base)
		local animacy = base.animacy
		if animacy == "inan" then
			animacy = "in"
		end
		if base.gender == "MF" then
			m_table.insertIfNot(genders, "m-" .. animacy .. number)
			m_table.insertIfNot(genders, "f-" .. animacy .. number)
		elseif base.gender == "M" then
			m_table.insertIfNot(genders, "m-" .. animacy .. number)
		elseif base.gender == "F" then
			m_table.insertIfNot(genders, "f-" .. animacy .. number)
		elseif base.gender == "N" then
			m_table.insertIfNot(genders, "n-" .. animacy .. number)
		else
			error("Internal error: Unrecognized gender '" ..
				(base.gender or "nil") .. "'")
		end
	end)
	return genders
end


-- Externally callable function to parse and decline a noun given user-specified arguments.
-- Return value is ALTERNANT_MULTIWORD_SPEC, an object where the declined forms are in
-- `ALTERNANT_MULTIWORD_SPEC.forms` for each slot. If there are no values for a slot, the
-- slot key will be missing. The value for a given slot is a list of objects
-- {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(parent_args, pos, from_headword, def)
	local params = {
		[1] = {required = true, default = "віз<c.io>"},
		footnote = {list = true},
		title = {},
		pos = {default = "noun"},
	}

	if from_headword then
		params["lemma"] = {list = true}
		params["g"] = {list = true}
		params["f"] = {list = true}
		params["m"] = {list = true}
		params["adj"] = {list = true}
		params["dim"] = {list = true}
		params["id"] = {}
	end

	local args = m_para.process(parent_args, params)
	local parse_props = {
		parse_indicator_spec = parse_indicator_spec,
	}
	local alternant_multiword_spec = iut.parse_inflected_text(args[1], parse_props)
	alternant_multiword_spec.title = args.title
	alternant_multiword_spec.pos = args.pos or pos
	alternant_multiword_spec.footnotes = args.footnote
	alternant_multiword_spec.args = args
	normalize_all_lemmas(alternant_multiword_spec)
	detect_all_indicator_specs(alternant_multiword_spec)
	propagate_properties(alternant_multiword_spec, "animacy", "inan", "mixed")
	propagate_properties(alternant_multiword_spec, "number", "both", "both")
	-- The default of "M" should apply only to plural adjectives, where it doesn't matter.
	propagate_properties(alternant_multiword_spec, "gender", "M", "mixed")
	determine_noun_status(alternant_multiword_spec)
	local inflect_props = {
		skip_slot = function(slot)
			return skip_slot(alternant_multiword_spec.number, slot)
		end,
		slot_table = output_noun_slots_with_linked,
		get_variants = get_variants,
		inflect_word_spec = decline_noun,
	}
	iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)
	compute_categories_and_annotation(alternant_multiword_spec)
	alternant_multiword_spec.genders = compute_headword_genders(alternant_multiword_spec)
	return alternant_multiword_spec
end


-- Externally callable function to parse and decline a noun where all forms
-- are given manually. Return value is ALTERNANT_MULTIWORD_SPEC, an object where the declined
-- forms are in `ALTERNANT_MULTIWORD_SPEC.forms` for each slot. If there are no values for a
-- slot, the slot key will be missing. The value for a given slot is a list of
-- objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms_manual(parent_args, number, pos, from_headword, def)
	if number ~= "sg" and number ~= "pl" and number ~= "both" then
		error("Internal error: number (arg 1) must be 'sg', 'pl' or 'both': '" .. number .. "'")
	end

	local params = {
		footnote = {list = true},
		title = {},
		unknown_stress = {type = "boolean"},
		pos = {default = "noun"},
	}
	if number == "both" then
		params[1] = {required = true, default = "жук"}
		params[2] = {required = true, default = "жуки́"}
		params[3] = {required = true, default = "жука́"}
		params[4] = {required = true, default = "жукі́в"}
		params[5] = {required = true, default = "жуко́ві, жуку́"}
		params[6] = {required = true, default = "жука́м"}
		params[7] = {required = true, default = "жука́"}
		params[8] = {required = true, default = "жуки́, жукі́в"}
		params[9] = {required = true, default = "жуко́м"}
		params[10] = {required = true, default = "жука́ми"}
		params[11] = {required = true, default = "жуко́ві, жуку́"}
		params[12] = {required = true, default = "жука́х"}
		params[13] = {required = true, default = "жу́че"}
		params[14] = {required = true, default = "жуки́"}
	elseif number == "sg" then
		params[1] = {required = true, default = "лист"}
		params[2] = {required = true, default = "ли́сту"}
		params[3] = {required = true, default = "ли́сту, ли́стові"}
		params[4] = {required = true, default = "лист"}
		params[5] = {required = true, default = "ли́стом"}
		params[6] = {required = true, default = "ли́сті, ли́сту"}
		params[7] = {required = true, default = "ли́сте"}
	else
		params[1] = {required = true, default = "две́рі"}
		params[2] = {required = true, default = "двере́й"}
		params[3] = {required = true, default = "две́рям"}
		params[4] = {required = true, default = "две́рі"}
		params[5] = {required = true, default = "дверми́, двери́ма"}
		params[6] = {required = true, default = "две́рях"}
		params[7] = {required = true, default = "две́рі"}
	end

	local args = m_para.process(parent_args, params)
	local alternant_multiword_spec = {
		title = args.title,
		footnotes = args.footnote,
		pos = args.pos or pos,
		forms = {},
		number = number,
		manual = true,
	}
	process_manual_overrides(alternant_multiword_spec.forms, args, alternant_multiword_spec.number, args.unknown_stress)
	compute_categories_and_annotation(alternant_multiword_spec)
	return alternant_multiword_spec
end


-- Entry point for {{uk-ndecl}}. Template-callable function to parse and decline a noun given
-- user-specified arguments and generate a displayable table of the declined forms.
function export.show(frame)
	local parent_args = frame:getParent().args
	local alternant_multiword_spec = export.do_generate_forms(parent_args)
	show_forms(alternant_multiword_spec)
	return make_table(alternant_multiword_spec) .. require("Module:utilities").format_categories(alternant_multiword_spec.categories, lang)
end


-- Entry point for {{uk-ndecl-manual}}, {{uk-ndecl-manual-sg}} and {{uk-ndecl-manual-pl}}.
-- Template-callable function to parse and decline a noun given manually-specified inflections
-- and generate a displayable table of the declined forms.
function export.show_manual(frame)
	local iparams = {
		[1] = {required = true},
	}
	local iargs = m_para.process(frame.args, iparams)
	local parent_args = frame:getParent().args
	local alternant_multiword_spec = export.do_generate_forms_manual(parent_args, iargs[1])
	show_forms(alternant_multiword_spec)
	return make_table(alternant_multiword_spec) .. require("Module:utilities").format_categories(alternant_multiword_spec.categories, lang)
end


-- Concatenate all forms of all slots into a single string of the form
-- "SLOT=FORM,FORM,...|SLOT=FORM,FORM,...|...". Embedded pipe symbols (as might occur
-- in embedded links) are converted to <!>. If INCLUDE_PROPS is given, also include
-- additional properties (currently, g= for headword genders). This is for use by bots.
local function concat_forms(alternant_multiword_spec, include_props)
	local ins_text = {}
	for slot, _ in pairs(output_noun_slots_with_linked) do
		local formtext = com.concat_forms_in_slot(alternant_multiword_spec.forms[slot])
		if formtext then
			table.insert(ins_text, slot .. "=" .. formtext)
		end
	end
	if include_props then
		table.insert(ins_text, "g=" .. table.concat(alternant_multiword_spec.genders, ","))
	end
	return table.concat(ins_text, "|")
end


-- Template-callable function to parse and decline a noun given user-specified arguments and return
-- the forms as a string "SLOT=FORM,FORM,...|SLOT=FORM,FORM,...|...". Embedded pipe symbols (as might
-- occur in embedded links) are converted to <!>. If |include_props=1 is given, also include
-- additional properties (currently, none). This is for use by bots.
function export.generate_forms(frame)
	local include_props = frame.args["include_props"]
	local parent_args = frame:getParent().args
	local alternant_multiword_spec = export.do_generate_forms(parent_args)
	return concat_forms(alternant_multiword_spec, include_props)
end


return export
