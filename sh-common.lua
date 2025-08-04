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

export.TEMP_DZH = u(0xFFF0) -- used to substitute dž temporarily
export.TEMP_LJ = u(0xFFF1) -- used to substitute lj temporarily
export.TEMP_NJ = u(0xFFF2) -- used to substitute nj temporarily
export.TEMP_CAP_DZH = u(0xFFF3) -- used to substitute Dž temporarily
export.TEMP_CAP_LJ = u(0xFFF4) -- used to substitute Lj temporarily
export.TEMP_CAP_NJ = u(0xFFF5) -- used to substitute Nj temporarily

local lc_vowel_lat = "aeiouy"
local lc_vowel_cyr = "аеиоу"
local uc_vowel_lat = uupper(lc_vowel_lat)
local uc_vowel_cyr = uupper(lc_vowel_cyr)
export.vowel = lc_vowel .. uc_vowel
export.vowel_c = "[" .. export.vowel .. "]"
export.non_vowel_c = "[^" .. export.vowel .. "]"
-- Consonants that can never form a syllabic nucleus.
local lc_non_syllabic_cons_lat_without_temp = "bcdfghjkmnpqstvwxzčšžćđ"
local lc_non_syllabic_cons_lat = lc_non_syllabic_cons_lat_without_temp .. export.TEMP_DZH .. export.TEMP_LJ ..
	export.TEMP_NJ
local uc_non_syllabic_cons_lat_without_temp = uupper(lc_non_syllabic_cons_lat_without_temp)
local uc_non_syllabic_cons_lat = uc_non_syllabic_cons_lat_without_temp .. export.TEMP_CAP_DZH .. export.TEMP_CAP_LJ ..
	export.TEMP_CAP_NJ
local lc_non_syllabic_cons_cyr = "бцдфгхјкмнпствзчшжђћџљњ"
local uc_non_syllabic_cons_cyr = uupper(lc_non_syllabic_cons_cyr)
export.non_syllabic_cons_lat = lc_non_syllabic_cons_lat .. uc_non_syllabic_cons_lat
export.non_syllabic_cons_cyr = lc_non_syllabic_cons_cyr .. uc_non_syllabic_cons_cyr
export.non_syllabic_cons = export.non_syllabic_cons_lat .. export.non_syllabic_cons_cyr
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
	[TEMP_DZH] = "č",
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

local function ucfirst_with_temp(str)
	if str == TEMP_DZH then
		return TEMP_CAP_DZH
	elseif str == TEMP_LJ then
		return TEMP_CAP_LJ
	elseif str == TEMP_NJ then
		return TEMP_CAP_NJ
	else
		return ucfirst(str)
	end
end

local function add_uppercase_mappings(mapping)
	local new_mapping = {}
	for from, to in pairs(mapping) do
		new_mapping[from] = to
		new_mapping[ucfirst_with_temp(from)] = ucfirst_with_temp(to)
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


local function make_try(word)
	return function(from, to)
		local stem = rmatch(word, "^(.*)" .. from .. "$")
		if stem then
			if to:find("%%") then
				return rsub(stem, from .. "$", to)
			else
				return stem .. to
			end
		end
		return nil
	end
end

local lc_sht_map = {
	-- [st]: see examples below at the top of lc_iotate_map
	["st"] = "št",
	["ст"] = "шт",
}

local lc_iotate_map = {
	-- [st]: becomes either [št] or [šć]: ukr̀stiti -> ukŕštati, ukrštávati, ukršćívati; upropástiti -> upropaštávati,
	-- upropašćívati; premòstiti -> premošćívati; ìskati -> ȉštēm/ȉšćēm; čȉstiti -> čȉšćāh; čȇst -> čȅšćī
	["st"] = "šć",
	["ст"] = "шћ",
	-- [sk]: ?? (need examples)
	["sk"] = "šč",
	["ск"] = "шч",
	-- [sl]: ìzmisliti -> izmíšljati; zapòsliti -> zapošljávati, zapošljívati; mȉsliti -> mȉšljāh
	["sl"] = "šlj",
	["сл"] = "шљ",
	-- [sn]: zakàsniti -> zakašnjávati; razbjèsniti -> razbješnjívati; zgȕsnuti -> zgušnjávati; kàsniti -> kȁšnjāh;
	-- kȉsnuti -> kȉšnjāh; bijésan -> bjȅšnjī
	["sn"] = "šnj",
	["сн"] = "шњ",
	-- [zd]: ubrázditi -> ubražđívati; FIXME: are there cases where the output is [žd], parallel to [st] -> [št]?
	["zd"] = "žđ",
	["зд"] = "жђ",
	-- [zg]: ?? (need examples); the output ždž is a guess, based on the fact that [[mozak]] "brain" with stem mozg-
	-- has vocative [[moždže]]; this is the first palatalization rather than iotation but they should produce the same
	-- outputs with velar inputs.
	["zg"] = "ždž",
	["зг"] = "жџ",
	-- [zl]: ?? (need examples)
	["zl"] = "žlj",
	["зл"] = "зљ",
	-- [zn]: prázniti -> prȃžnjāh; čȅznuti -> čȅznjāh
	["zn"] = "žnj",
	["зн"] = "жњ",
	-- [t]: pamet -> pȁmećū; zàpamtiti -> zàpāmćen, zapamćívati; obrátiti se -> òbraćati se;
	-- razgòlititi se -> razgolićávati se; mȅtati -> mȅćēm; mlátiti -> mlȃćāh; šútjeti -> šúćāh; krȗt -> krȕćī
	["t"] = "ć",
	["т"] = "ћ",
	-- [d]: prèdvidjeti -> predvíđati; prilagòditi se -> prolagođávati se; ugráditi -> ugrađívati; glòdati -> glȍđēm;
	-- slijéditi -> slijȇđāh; žúdjeti -> žúđāh; lȗd -> lȕđī
	["d"] = "đ",
	["д"] = "ђ",
	-- [h]: máhati -> mȃšēm; sȗh -> sȕšī
	["h"] = "š",
	["х"] = "ш",
	-- [s]: pokositi -> pòkošen; oglásiti -> oglašávati, oglašívati; písati -> pȋšēm; nòsiti -> nȍšāh
	["s"] = "š",
	["с"] = "ш",
	-- [k]: skákati -> skȃčēm; vȗkti -> vúčāh; jȃk -> jȁčī; prijȇk -> prȅčī
	["k"] = "č",
	["к"] = "ч",
	-- [c]: mȉcati -> mȉčēm; novac -> novčànīk; zec -> zèčārnīk
	["c"] = "č",
	["ц"] = "ч",
	-- [g]: pomagati -> pòmāžēm; vágati -> vȃžēm; drȃg -> drȁžī
	["g"] = "ž",
	["г"] = "ж",
	-- [z]: razmaziti -> ràzmāžen; òpaziti -> opážati; súziti -> sužávati; zaráziti se -> zaražívati se;
	-- kázati -> kȃžēm; vòziti -> vȍžāh; bȓz -> bȑžī
	["z"] = "ž",
	["з"] = "ж",
	-- [l]: ostàkliti -> òstakljen; pomòliti se -> pomáljati se; isèliti -> iseljávati; hváliti -> hvȃljāh;
	-- bijȇl -> bjȅljī
	["l"] = "lj",
	["л"] = "љ",
	-- [n]: raniti -> rȁnjen; začìniti -> začínjati; usìtniti -> usitnjávati; zastrániti -> zastranjívati;
	-- zàbrinuti -> zabrinjávati; ròniti -> rȍnjāh; lijȇn -> ljȅnjī
	["n"] = "nj",
	["н"] = "њ",
	-- [b]: rabiti -> rȃbljen; prispodòbiti -> prispodábljati; sukòbiti -> sukobljávati;
	-- udúbiti se -> udubljívati se; zòbati -> zȍbljēm; trúbiti -> trúbljāh; grúbjeti -> grúbljāh; grȗb -> grȕbljī
	["b"] = "blj",
	["б"] = "бљ",
	-- [p]: poklopiti -> pòklopljen; skȕpiti -> skúpljati; začèpiti -> začepljávati; ishlápiti -> ishlapljívati;
	-- sȉpati -> sȉpljēm; krijépiti -> krijȇpljāh; tŕpjeti -> tŕpljāh; glȗp -> glȕpljī
	["p"] = "plj",
	["п"] = "пљ",
	-- [m]: namámiti -> nàmāmljen, namamljívati; pripitòmiti -> pripitomljávati; hrámati -> hrȃmljēm;
	-- lòmiti -> lȍmljāh; gŕmjeti -> gŕmljāh; nijȇm -> njȅmljī
	["m"] = "mlj",
	["м"] = "мљ",
	-- [v]: obnoviti -> òbnovljen; pòzdraviti -> pòzdravljati; iskríviti -> iskrivljávati; ugláviti -> uglavljívati;
	-- pozívati -> pòzīvljēm; lòviti -> lȍvljāh; žívjeti -> žívljāh; žȋv -> žȉvljī
	["v"] = "vlj",
	["в"] = "вљ",
	-- [f]: zašaráfiti -> zašàrāflen, zašarafljívati; šaráfiti -> šàrāfljāh
	["f"] = "flj",
	["ф"] = "фљ",
}

export.sht_map = add_uppercase_mappings(lc_sht_map)
export.iotate_map = add_uppercase_mappings(lc_iotate_map)

--[==[
Iotate `word` according to Serbo-Croatian iotatation rules. There are two possible outputs of [st], either [št] or [šć].
If `sht_output` is specified, [št] results, otherwise [šć].
]==]
function export.iotate(word, sht_output)
	if sht_output then
		-- First check the [st] or [ст]. If this occurs, we need to make the substitution and not then apply the regular
		-- iotation map because it will wrongly convert the resulting [t] into [ć].
		local changed
		word, changed = rsubb(word, "(..)$", export.sht_map)
		if changed then
			return word
		end
	end
	-- Try to iotate the last two letters, then the last letter. None of the outputs from iotating the last two letters 
	-- using the first rsub() will be affected by the second rsub().
	word = rsub(word, "(..)$", export.iotate_map)
	return rsub(word, "(.)$", export.iotate_map)
end


local lc_first_palatalization_map = {
	-- [sk]: ?? (need examples)
	["sk"] = "šč",
	["ск"] = "шч",
	-- [zg]: mozak "brain", stem mozg- -> vocative moždže
	["zg"] = "ždž",
	["зг"] = "жџ",
	-- [h]: ?? (need examples)
	["h"] = "š",
	["х"] = "ш",
	-- [k]: ?? (need examples)
	["k"] = "č",
	["к"] = "ч",
	-- [c]: ?? (need examples)
	["c"] = "č",
	["ц"] = "ч",
	-- [g]: ?? (need examples)
	["g"] = "ž",
	["г"] = "ж",
}
export.first_palatalization_map = add_uppercase_mappings(lc_first_palatalization_map)

function export.apply_first_palatalization(word)
	-- Try to palatalize the last two letters, then the last letter. None of the outputs from the first rsub() will be
	-- affected by the second rsub().
	word = rsub(word, "(..)$", export.first_palatalization_map)
	return rsub(word, "(.)$", export.first_palatalization_map)
end


local lc_second_palatalization_map = {
	-- [h]: zloduh -> nom pl (and voc pl?) zlòdusi, dat/loc/ins pl zlòdusima; ovrha -> dat/loc sg ȍvrsi
	["h"] = "š",
	["х"] = "ш",
	-- [k]: junak -> nom pl junáci, voc pl jȕnāci, dat/loc/ins pl junácima; majka -> dat/loc sg mȃjci
	["k"] = "č",
	["к"] = "ч",
	-- [g]: strateg -> nom pl (and voc pl?) stràtezi, dat/loc/ins pl stràtezima; jaruga -> dat/loc sg jàruzi
	["g"] = "ž",
	["г"] = "ж",
}
export.second_palatalization_map = add_uppercase_mappings(lc_second_palatalization_map)

function export.apply_second_palatalization(word)
	-- Try to palatalize the last two letters, then the last letter. None of the outputs from the first rsub() will be
	-- affected by the second rsub().
	--
	-- FIXME: With certain clusters, unpalatalized outputs are possible or required:
	-- čk -> čc or čk: mačka -> mȁčci or mȁčki
	-- sk -> sc or sk: guska -> gȕsci or gȕski
	-- šk -> šc or šk: puška -> pȕšci or pȕški
	-- tk -> c or tc or tk: krletka -> kr̀lēci (kr̀lētci is also allowed) or kr̀lētki
	-- ck -> ck only: kocka -> kȍcki
	-- zg -> zg only: mazga -> màzgi
	-- sh -> sh only: pasha -> pȁshi
	-- We need to figure out where to handle this.
	word = rsub(word, "(..)$", export.second_palatalization_map)
	return rsub(word, "(.)$", export.second_palatalization_map)
end


function export.reduce(word, script)
	local pre, letter, vowel, post = rmatch(word, "^(.*)([" .. export.cons .. "y%-])a(" .. export.cons_c .. "+)$")
	if not pre then
		return nil
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
