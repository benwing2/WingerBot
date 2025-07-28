local export = {}

local lang = require("Module:languages").getByCode("sh")
local m_links = require("Module:links")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")

local u = mw.ustring.char
local rsplit = mw.text.split
local rfind = mw.ustring.find
local rmatch = mw.ustring.match
local rsubn = mw.ustring.gsub
local ulen = mw.ustring.len
local uupper = mw.ustring.upper
local ucfirst = m_string_utilities.ucfirst

local AC = u(0x0301) -- acute =  ́
local GR = u(0x0300) -- grave =  ̀
local CFLEX = u(0x0302) -- circumflex =  ̂
local DOUBLEAC = u(0x030B) -- double acute =  ̋
local DOUBLEGR = u(0x030F) -- double grave =  ̏
local MACRON = u(0x0304) -- macron =  ̄
local CARON = u(0x030C) -- caron  ̌
-- local BREVE = u(0x0306) -- breve  ̆
local INVBREVE = u(0x0311) -- invrese breve  ̑
-- local DIA = u(0x0308) -- diaeresis =  ̈
-- local OGONEK = u(0x0328) -- ogonek  ̨

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

export.TEMP_CH = u(0xFFF0) -- used to substitute ch temporarily in the default-reducible code
export.TEMP_SOFT_LABIAL = u(0xFFF1) -- used to indicate that a labial consonant is soft and needs ě

local lc_vowel = "aeiouyáéíóúýěů"
local uc_vowel = uupper(lc_vowel)
export.vowel = lc_vowel .. uc_vowel
export.vowel_c = "[" .. export.vowel .. "]"
export.non_vowel_c = "[^" .. export.vowel .. "]"
-- Consonants that can never form a syllabic nucleus.
local lc_non_syllabic_cons = "bcdfghjkmnpqstvwxzčňšžďť" .. export.TEMP_CH .. export.TEMP_SOFT_LABIAL
local uc_non_syllabic_cons = uupper(lc_non_syllabic_cons)
export.non_syllabic_cons = lc_non_syllabic_cons .. uc_non_syllabic_cons
export.non_syllabic_cons_c = "[" .. export.non_syllabic_cons .. "]"
local lc_syllabic_cons = "lrř"
local uc_syllabic_cons = uupper(lc_syllabic_cons)
local lc_cons = lc_non_syllabic_cons .. lc_syllabic_cons
local uc_cons = uupper(lc_cons)
export.cons = lc_cons .. uc_cons
export.cons_c = "[" .. export.cons .. "]"
export.lowercase = lc_vowel .. lc_cons
export.lowercase_c = "[" .. export.lowercase .. "]"
export.uppercase = uc_vowel .. uc_cons
export.uppercase_c = "[" .. export.uppercase .. "]"

local lc_velar = "kgh"
local uc_velar = uupper(lc_velar)
export.velar = lc_velar .. uc_velar
export.velar_c = "[" .. export.velar .. "]"

local lc_plain_labial = "mpbfvw"
local lc_labial = lc_plain_labial .. export.TEMP_SOFT_LABIAL
local uc_plain_labial = uupper(lc_plain_labial)
local uc_labial = uupper(lc_labial)
export.plain_labial = lc_plain_labial .. uc_plain_labial
export.labial = lc_labial .. uc_labial
export.labial_c = "[" .. export.labial .. "]"

local lc_voiced_to_unvoiced_lat = {
	["b"] = "p",
	["d"] = "t",
	["dž"] = "č",
	["đ"] = "ć",
	["g"] = "k",
	["z"] = "s",
	["ž"] = "š",
}

local lc_voiced_to_unvoiced_cyr = {
	["б"] = "п",
	["д"] = "т",
	["џ"] = "ч",
	["ђ"] = "ћ",
	["г"] = "к",
	["з"] = "с",
	["ж"] = "ш",
}

local function add_uppercase_mappings(mapping)
	local new_mapping = {}
	for from, to in pairs(mapping) do
		new_mapping[from] = to
		new_mapping[ucfirst(from)] = ucfirst(to)
	end
	return new_mapping
end

export.voiced_to_unvoiced_lat = add_uppercase_mappings(lc_voiced_to_unvoiced_lat)
export.voiced_to_unvoiced_cyr = add_uppercase_mappings(lc_voiced_to_unvoiced_cyr)

local function reverse_mapping(mapping)
	local new_mapping = {}
	for from, to in pairs(mapping) do
		new_mapping[to] = from 
	end
	return new_mapping
end

export.unvoiced_to_voiced_lat = reverse_mapping(export.voiced_to_unvoiced_lat)
export.unvoiced_to_voiced_cyr = reverse_mapping(export.voiced_to_unvoiced_cyr)

local lc_voiced_obstruent_lat = "bdđgzž"
local lc_unvoiced_obstruent_lat = "ptčćksšcfh"
local lc_voiced_obstruent_cyr = "бдџђгзж"
local lc_unvoiced_obstruent_cyr = "птчћксшцфх"

local uc_voiced_obstruent_lat = uupper(lc_voiced_obstruent_lat)
local uc_unvoiced_obstruent_lat = uupper(lc_unvoiced_obstruent_lat)
local uc_voiced_obstruent_cyr = uupper(lc_voiced_obstruent_cyr)
local uc_unvoiced_obstruent_cyr = uupper(lc_unvoiced_obstruent_cyr)

export.voiced_obstruent_lat = lc_voiced_obstruent_lat .. uc_voiced_obstruent_lat
export.unvoiced_obstruent_lat = lc_unvoiced_obstruent_lat .. uc_unvoiced_obstruent_lat
export.voiced_obstruent_cyr = lc_voiced_obstruent_cyr .. uc_voiced_obstruent_cyr
export.unvoiced_obstruent_cyr = lc_unvoiced_obstruent_cyr .. uc_unvoiced_obstruent_cyr

local lc_inherently_soft_lat = "đćžščj" -- c is mostly hard (?), doesn't occur at the end of adjective stems; r is hard
										-- in adjectives, hard or soft when originally soft as in cȁr
local lc_inherently_soft_cyr = "ђћжшџчјљњ" -- ц and р are the same as c and r in Latin

local uc_inherently_soft_lat = uupper(lc_inherently_soft_lat)
local uc_inherently_soft_cyr = uupper(lc_inherently_soft_cyr)

export.inherently_soft_lat = lc_inherently_soft_lat .. uc_inherently_soft_lat
export.inherently_soft_cyr = lc_inherently_soft_cyr .. uc_inherently_soft_cyr

export.inherently_soft_lat_c = "[" .. export.inherently_soft_lat .. "]"
export.inherently_soft_cyr_c = "[" .. export.inherently_soft_cyr .. "]"


local recomposer = {
	-- Cyrillic letters
	-- (none; we don't make use of ё, ӥ, ї, й or their capitalized equivalents, and ѐ and ѝ are the only other accented
	-- Cyrillic characters I know of that decompose, and we want them decomposed)
	-- Latin letters
	["c" .. AC] = "ć",
	["C" .. AC] = "Ć",
	["c" .. CARON] = "č",
	["C" .. CARON] = "Č",
	["s" .. CARON] = "š",
	["S" .. CARON] = "Š",
	["z" .. CARON] = "ž",
	["Z" .. CARON] = "Ž",
	-- These occur in obsolete words
	["e" .. CARON] = "ě",
	["E" .. CARON] = "Ě",
	["o" .. CARON] = "ǒ",
	["O" .. CARON] = "Ǒ",
}

--[==[
Decompose acute, grave, etc. on letters (esp. Latin) into individivual character + combining accent. But recompose
Cyrillic and Latin characters that we want to treat as units and get caught in the crossfire. We also normalize
double acute to double grave and circumflex to inverse breve because some older dictionaries use the former in place of
the latter.
]==]
function export.decompose(text)
	return (rsub(toNFD(text), ".[" .. AC .. CARON .. "]", recomposer):gsub(DOUBLEAC, DOUBLEGR):gsub(CFLEX, INVBREVE))
end

-- Return true if `word` is monosyllabic. Beware of words like [[čtvrtek]], [[plný]] and [[třmen]], which aren't
-- monosyllabic but have only one vowel, and contrariwise words like [[brouk]], which are monosyllabic but have
-- two vowels.
function export.is_monosyllabic(word)
	-- Treat ou as a single vowel.
	word = word:gsub("ou", "ů")
	word = word:gsub("ay$", "aj")
	-- Convert all vowels to 'e'.
	word = rsub(word, export.vowel_c, "e")
	-- All consonants next to a vowel are non-syllabic; convert to 't'.
	word = rsub(word, export.cons_c .. "e", "te")
	word = rsub(word, "e" .. export.cons_c, "et")
	-- Convert all remaining non-syllabic consonants to 't'.
	word = rsub(word, export.non_syllabic_cons_c, "t")
	-- At this point, what remains is 't', 'e', or a syllabic consonant. Count the latter two types.
	word = word:gsub("t", "")
	return ulen(word) <= 1
end


function export.apply_vowel_alternation(alt, stem)
	local modstem, origvowel
	if alt == "quant" or alt == "quant-ě" then
		-- [[sníh]] "snow", gen sg. [[sněhu]]
		-- [[míra]] "snow", gen pl. [[měr]]
		-- [[hůl]] "cane", gen sg. [[hole]]
		-- [[práce]] "work", ins sg. [[prací]]
		modstem = rsub(stem, "(.)([íůáé])(" .. export.cons_c .. "*)$",
			function(pre, vowel, post)
				origvowel = vowel
				if vowel == "í" then
					if alt == "quant-ě" then
						if rfind(pre, "[" .. export.followable_by_e_hacek .. "]$") then
							return pre .. "ě" .. post
						else
							return pre .. "e" .. post
						end
					else
						return pre .. "i" .. post
					end
				elseif vowel == "ů" then
					return pre .. "o" .. post
				elseif vowel == "é" then
					return pre .. "e" .. post
				else
					return pre .. "a" .. post
				end
			end
		)
		-- [[houba]] "mushroom", gen pl. [[hub]]
		modstem = rsub(modstem, "ou(" .. export.cons_c .. "*)$", "u%1")
		if modstem == stem then
			error("Indicator '" .. alt .. "' can't be applied because stem '" .. stem .. "' doesn't have an í, ů, ou, á or é as its last vowel")
		end
	else
		return stem, nil
	end
	return modstem, origvowel
end


local function make_try(word)
	return function(from, to)
		local stem = rmatch(word, "^(.*)" .. from .. "$")
		if stem then
			return stem .. to
		end
		return nil
	end
end


function export.iotate(stem)
	-- FIXME! This is based off of page 14 of Janda and Townsend but needs reviewing with verbs.
	local try = make_try(word)
	return
		try("st", "št") or
		try("zd", "žd") or
		try("t", "c") or
		try("d", "z") or
		try("s", "š") or
		try("z", "ž") or
		try("r", "ř") or
		try("ch", "š") or
		try("[kc]", "č") or
		try("[hg]", "ž") or
		word
end


function export.apply_first_palatalization(word, is_adjective)
	-- -rr doesn't palatalize (e.g. [[torr]] voc_s 'torre') but otherwise -Cr normally does.
	if rfind(word, "rr$") then
		return word
	end
	local stem = rmatch(word, "^(.*" .. export.cons_c .. ")r$")
	if stem then
		return stem .. "ř"
	end
	local try = make_try(word)
	return
		try("ch", "š") or
		try("[hg]", "ž") or
		is_adjective and try("sk", "št") or
		is_adjective and try("ck", "čt") or
		try("[kc]", "č") or
		word
end


function export.apply_second_palatalization(word, is_adjective)
	local try = make_try(word)
	return
		try("ch", "š") or
		try("[hg]", "z") or
		try("rr", "ř") or
		try("r", "ř") or
		is_adjective and try("sk", "št") or
		is_adjective and try("ck", "čt") or
		try("k", "c") or
		word
end


function export.reduce(word)
	local pre, letter, vowel, post = rmatch(word, "^(.*)([" .. export.cons .. "y%-])([eě])(" .. export.cons_c .. "+)$")
	if not pre then
		return nil
	end
	if vowel == "ě" and rfind(letter, "[" .. export.paired_plain .. "]") then
		letter = export.paired_plain_to_palatal[letter]
	end
	return pre .. letter .. post
end


function export.dereduce(base, stem)
	local pre, letter, post = rmatch(stem, "^(.*)(" .. export.cons_c .. ")(" .. export.cons_c .. ")$")
	if not pre then
		return nil
	end
	local epvowel
	if rfind(letter, "[" .. export.paired_palatal .. "]") then
		letter = export.paired_palatal_to_plain[letter]
		epvowel = "ě"
	else
		epvowel = "e"
	end
	if base.c_as_k and post == "c" then
		-- [[ayahuasca]] dereduces to gen pl 'ayahuasek'
		post = "k"
	end
	return pre .. letter .. epvowel .. post
end


function export.convert_paired_plain_to_palatal(stem, ending)
	if ending and not rfind(ending, "^[ěií]") then
		return stem
	end
	local stembegin, lastchar = rmatch(stem, "^(.*)([" .. export.followable_by_e_hacek .. "])$")
	if lastchar then
		return stembegin .. export.paired_plain_to_palatal[lastchar]
	else
		return stem
	end
end


function export.convert_paired_palatal_to_plain(stem, ending)
	-- For stems that alternate between n/t/d and ň/ť/ď, we always maintain the stem in the latter format and convert
	-- to the corresponding plain as needed, with e -> ě. Likewise, stems ending in /bj/ /vj/ etc. use TEMP_SOFT_LABIAL.
	if ending and not rfind(ending, "^[Eeěií]") then
		stem = stem:gsub(export.TEMP_SOFT_LABIAL, "")
		return stem, ending
	end
	local stembegin, lastchar = rmatch(stem, "^(.*)([" .. export.paired_palatal .. export.TEMP_SOFT_LABIAL .. "])$")
	if lastchar then
		ending = ending and rsub(ending, "^e", "ě") or nil
		stem = stembegin .. export.paired_palatal_to_plain[lastchar]
	end
	-- 'E' has served its purpose of preventing the e -> ě conversion after a paired palatal (i.e. it depalatalizes
	-- paired palatals).
	ending = ending and rsub(ending, "^E", "e") or nil
	return stem, ending
end


function export.combine_stem_ending(base, slot, stem, ending)
	if stem == "?" then
		return "?"
	else
		-- There are occasional occurrences of soft-only consonants at the end of the stem in hard paradigms, e.g.
		-- [[banjo]] "banjo", [[gadžo]] "gadjo (non-Romani)", [[Miša]] "Misha, Mike", [[paša]] "pasha". These force a
		-- following y to turn into i. Things are tricky with -c; [[hec]] "joke" (hard masculine) has ins_pl 'hecy',
		-- but [[paňáca]] "jester, fop" has ins_pl 'paňáci'. We have to set a flag to indicate whether to allow y after
		-- c. This needs to proceed depalatalization of paired palatal consonants in the case of e.g. [[říďa]]
		-- "principal, headmaster", with instrumental plural 'řídi' (říďy -> říďi -> řídi).
		if rfind(ending, "^y") and (rfind(stem, export.inherently_soft_not_c_c .. "$") or
			not base.hard_c and rfind(stem, "[cC]$")) then
			ending = rsub(ending, "^y", "i")
		end
		-- Convert ňe and ňě -> ně. Convert nE and ňE -> ne. Convert ňi and ni -> ni.
		stem, ending = export.convert_paired_palatal_to_plain(stem, ending)
		-- We specify endings with -e/ě using ě, but some consonants cannot be followed by ě; convert to plain e.
		if rfind(ending, "^ě") and not rfind(stem, export.followable_by_e_hacek_c .. "$") then
			ending = rsub(ending, "^ě", "e")
		end
		if base.all_uppercase then
			stem = uupper(stem)
		end
		if base.collapse_ee and rfind(ending, "^e") and rfind(stem, "e$") then
			-- Two e's should maybe collapse to one; occurs in [[Sofokles]] stem 'Sofokle-' voc 'Sofokle' not '#Sofoklee'; also
			-- in terms like [[Pete]], [[Mike]], [[Gable]] with silent -e that's kept in the stem except before an ending in -e.
			-- But not in [[Prométheus]], with voc. 'Prométhee'.
			return stem:gsub("e$", "") .. ending
		else
			return stem .. ending
		end
	end
end


return export
