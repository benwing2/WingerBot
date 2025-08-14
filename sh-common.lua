local export = {}

local lang = require("Module:languages").getByCode("sh")
local m_links = require("Module:links")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")

local u = m_string_utilities.char
local rsplit = m_string_utilities.split
local rfind = m_string_utilities.find
local rmatch = m_string_utilities.match
local rsubn = m_string_utilities.gsub
local ulen = m_string_utilities.len
local uupper = m_string_utilities.upper
local ucfirst = m_string_utilities.ucfirst
local toNFD = mw.ustring.toNFD
local toNFC = mw.ustring.toNFC
local format = string.format

-- version of rsubn() that discards all but the first return value
local function rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end
export.rsub = rsub

-- version of rsubn() that returns a 2nd argument boolean indicating whether
-- a substitution was made.
local function rsubb(term, foo, bar)
	local retval, nsubs = rsubn(term, foo, bar)
	return retval, nsubs > 0
end
export.rsubb = rsubb

-- apply rsub() repeatedly until no change
local function rsub_repeatedly(term, foo, bar)
	while true do
		local new_term = rsub(term, foo, bar)
		if new_term == term then
			return term
		end
		term = new_term
	end
end
export.rsub_repeatedly = rsub_repeatedly

--[==[
Recompose acute, grave, etc. on letters (esp. Latin).
]==]
function export.recompose(text)
	-- Put this up here so it can be called by process_error().
	return toNFC(text)
end

local function process_error(fmt, default_dump, ...)
	local args = {...}
	for i, val in ipairs(args) do
		if type(val) == "table" and val.__no_dump_arg__ then
			args[i] = val.__no_dump_arg__
		elseif not default_dump then
			-- Any occurrence of 'nil' will terminate the unpack, so convert to a string.
			if args[i] == nil then
				args[i] = "nil"
			end
		else
			args[i] = dump(val)
		end
	end
	if type(fmt) == "table" then
		-- hacky signal that we're called from interr(), and not to omit stack frames
		return error(export.recompose(format(fmt[1], unpack(args))))
	end
	return error(export.recompose(format(fmt, unpack(args))), 1)
end

local function interr(fmt, ...)
	process_error({"Internal error: " .. fmt}, true, ...)
end
export.interr = interr

local function usererr(fmt, ...)
	process_error(fmt, false, ...)
end
export.usererr = usererr

local AC = u(0x0301) -- acute =  ́
export.AC = AC
local GR = u(0x0300) -- grave =  ̀
export.GR = GR
local CFLEX = u(0x0302) -- circumflex =  ̂
local DOUBLEAC = u(0x030B) -- double acute =  ̋
local DOUBLEGR = u(0x030F) -- double grave =  ̏
export.DOUBLEGR = DOUBLEGR
local MACRON = u(0x0304) -- macron =  ̄
export.MACRON = MACRON
local CARON = u(0x030C) -- caron  ̌
-- local BREVE = u(0x0306) -- breve  ̆
local INVBREVE = u(0x0311) -- invrese breve  ̑
export.INVBREVE = INVBREVE
-- local DIA = u(0x0308) -- diaeresis =  ̈
-- local OGONEK = u(0x0328) -- ogonek  ̨

-- We don't include CFLEX (occasional replacement or mistake for INVBREVE) or DOUBLEAC (occasional replacement or
-- mistake for DOUBLEGR) because they are normalized when decomposing.
local stress_accent = AC .. GR .. DOUBLEGR .. INVBREVE
export.stress_accent = stress_accent
local stress_accent_c = "[" .. stress_accent .. "]"
export.stress_accent_c = stress_accent_c
local vowel_accent = stress_accent .. MACRON
export.vowel_accent = vowel_accent
local vowel_accent_c = "[" .. vowel_accent .. "]"
export.vowel_accent_c = vowel_accent_c

local TEMP_DZH = u(0xFFF0) -- used to substitute dž temporarily
local TEMP_LJ = u(0xFFF1) -- used to substitute lj temporarily
local TEMP_NJ = u(0xFFF2) -- used to substitute nj temporarily
local TEMP_CAP_DZH = u(0xFFF3) -- used to substitute Dž temporarily
local TEMP_CAP_LJ = u(0xFFF4) -- used to substitute Lj temporarily
local TEMP_CAP_NJ = u(0xFFF5) -- used to substitute Nj temporarily
local SYLDIV = u(0xFFF6)
export.SYLDIV = SYLDIV
local WORD_BOUNDARY = u(0xFFF7)
export.WORD_BOUNDARY = WORD_BOUNDARY

local lc_vowel_lat = "aeiouěǒ" -- don't include y or r, which need to be handled specially
local lc_vowel_cyr = "аеиоу"
local uc_vowel_lat = uupper(lc_vowel_lat)
local uc_vowel_cyr = uupper(lc_vowel_cyr)
local vowel_lat = lc_vowel_lat .. uc_vowel_lat
local vowel_cyr = lc_vowel_cyr .. uc_vowel_cyr
local vowel = vowel_lat .. vowel_cyr
local vowel_c = "[" .. vowel .. "]"
local non_vowel_c = "[^" .. vowel .. vowel_accent .. SYLDIV .. "]"

local lc_syllabic_cons_lat = "ry"
local lc_syllabic_cons_cyr = "р"
local uc_syllabic_cons_lat = uupper(lc_syllabic_cons_lat)
local uc_syllabic_cons_cyr = uupper(lc_syllabic_cons_cyr)
local syllabic_cons_lat = lc_syllabic_cons_lat .. uc_syllabic_cons_lat
local syllabic_cons_cyr = lc_syllabic_cons_cyr .. uc_syllabic_cons_cyr
local syllabic_cons = syllabic_cons_lat .. syllabic_cons_cyr

-- Consonants that can never form a syllabic nucleus.
local lc_non_syllabic_cons_lat_without_temp = "bcdfghjkmnpqstvwxzčšžćđ"
local lc_non_syllabic_cons_lat = lc_non_syllabic_cons_lat_without_temp .. TEMP_DZH .. TEMP_LJ .. TEMP_NJ
local uc_non_syllabic_cons_lat_without_temp = uupper(lc_non_syllabic_cons_lat_without_temp)
local uc_non_syllabic_cons_lat = uc_non_syllabic_cons_lat_without_temp .. TEMP_CAP_DZH .. TEMP_CAP_LJ .. TEMP_CAP_NJ
local lc_non_syllabic_cons_cyr = "бцдфгхјкмнпствзчшжђћџљњ"
local uc_non_syllabic_cons_cyr = uupper(lc_non_syllabic_cons_cyr)
local non_syllabic_cons_lat = lc_non_syllabic_cons_lat .. uc_non_syllabic_cons_lat
local non_syllabic_cons_cyr = lc_non_syllabic_cons_cyr .. uc_non_syllabic_cons_cyr
local non_syllabic_cons = non_syllabic_cons_lat .. non_syllabic_cons_cyr

local cons_lat = non_syllabic_cons_lat .. syllabic_cons_lat
local cons_cyr = non_syllabic_cons_cyr .. syllabic_cons_cyr
local cons = cons_lat .. cons_cyr
export.cons = cons
local cons_c = "[" .. cons .. "]"
export.cons_c = cons_c
local lat_letter = vowel_lat .. cons_lat
local cyr_letter = vowel_cyr .. cons_cyr

local lc_voiced_to_unvoiced = {
	-- Latin
	["b"] = "p",
	["d"] = "t",
	[TEMP_DZH] = "č",
	["đ"] = "ć",
	["g"] = "k",
	["z"] = "s",
	["ž"] = "š",
	-- Cyrillic
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

local voiced_to_unvoiced = add_uppercase_mappings(lc_voiced_to_unvoiced)

local function reverse_mapping(mapping)
	local new_mapping = {}
	for from, to in pairs(mapping) do
		new_mapping[to] = from 
	end
	return new_mapping
end

local unvoiced_to_voiced = reverse_mapping(voiced_to_unvoiced)

local lc_triggers_voicing_lat_without_temp = "bdđgzž"
local lc_triggers_voicing_lat = lc_triggers_voicing_lat_without_temp .. TEMP_DZH
local uc_triggers_voicing_lat_without_temp = uupper(lc_triggers_voicing_lat_without_temp)
local uc_triggers_voicing_lat = uc_triggers_voicing_lat_without_temp .. TEMP_CAP_DZH
local lc_triggers_voicing_cyr = "бдџђгзж"
local uc_triggers_voicing_cyr = uupper(lc_triggers_voicing_cyr)
local triggers_voicing_lat = lc_triggers_voicing_lat .. uc_triggers_voicing_lat
local triggers_voicing_cyr = lc_triggers_voicing_cyr .. uc_triggers_voicing_cyr
local triggers_voicing = triggers_voicing_lat .. triggers_voicing_cyr

-- NOTE: v is not the voiced equivalent of f. v does not get devoiced before a devoicing obstruent (cf. [[lovac]] ->
-- gen. [[lovca]]), and v does not voice an unvoiced obstruent (cf. [[mrtav]] -> def. [[mrtvi]]). f seems to only
-- optionally become v before a voicing obstruent (cf. [[Afganistan]] or [[Avganistan]]). h and c have no equivalent
-- voiced consonants (you might expect c -> dz but there don't seem to be any examples).
local lc_triggers_devoicing_lat = "ptčćksšcfh"
local uc_triggers_devoicing_lat = uupper(lc_triggers_devoicing_lat)
local lc_triggers_devoicing_cyr = "птчћксшцфх"
local uc_triggers_devoicing_cyr = uupper(lc_triggers_devoicing_cyr)
local triggers_devoicing_lat = lc_triggers_devoicing_lat .. uc_triggers_devoicing_lat
local triggers_devoicing_cyr = lc_triggers_devoicing_cyr .. uc_triggers_devoicing_cyr
local triggers_devoicing = triggers_devoicing_lat .. triggers_devoicing_cyr

-- c is mostly hard (?), doesn't occur at the end of adjective stems except for indeclinable [[švarc]]/[[švorc]]; r is
-- hard in adjectives, hard or soft when originally soft as in [[car]].
local lc_inherently_soft_lat_without_temp = "đćžščj"
local lc_inherently_soft_lat = lc_inherently_soft_lat_without_temp .. TEMP_DZH .. TEMP_LJ .. TEMP_NJ
local uc_inherently_soft_lat_without_temp = uupper(lc_inherently_soft_lat_without_temp)
local uc_inherently_soft_lat = uc_inherently_soft_lat_without_temp .. TEMP_CAP_DZH .. TEMP_CAP_LJ .. TEMP_CAP_NJ
local lc_inherently_soft_cyr = "ђћжшџчјљњ"
local uc_inherently_soft_cyr = uupper(lc_inherently_soft_cyr)
local inherently_soft_lat = lc_inherently_soft_lat .. uc_inherently_soft_lat
local inherently_soft_cyr = lc_inherently_soft_cyr .. uc_inherently_soft_cyr
local inherently_soft = inherently_soft_lat .. inherently_soft_cyr
export.inherently_soft = inherently_soft


--[==[
Return true if text is Cyrillic. Currently we just check if there's at least one Cyrillic letter, on the assumption that
mixed Latin/Cyrillic is Cyrillic (compare Russian [[витамин B2]]).
]==]
function export.is_cyrillic(text)
	return rfind(text, "[" .. cyr_letter .. "]")
end

function export.is_stressed(word)
	return rfind(word, stress_accent_c)
end

local recomposer = {
	-- Cyrillic letters
	-- (none; we don't make use of ё, ӥ, ї, й or their capitalized equivalents, and ѐ and ѝ are the only other accented
	-- Cyrillic characters I know of that decompose, and we want them decomposed)
	-- Latin letters
	["c" .. AC] = "ć",
	["C" .. AC] = "Ć",
	-- Montenegrin
	["s" .. AC] = "ś",
	["S" .. AC] = "Ś",
	["z" .. AC] = "ź",
	["Z" .. AC] = "Ź",
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

local temp_sub_map = {
	["lj"] = TEMP_LJ,
	["Lj"] = TEMP_CAP_LJ,
	["nj"] = TEMP_NJ,
	["Nj"] = TEMP_CAP_NJ,
	["dž"] = TEMP_DZH,
	["Dž"] = TEMP_CAP_DZH,
}

local temp_unsub_map = reverse_mapping(temp_sub_map)

--[==[
Convert digraphs into single Unicode substituted characters.
]==]
function export.apply_temp_sub(text)
	return (text:gsub("[lLnN]j", temp_sub_map):gsub("[dD]ž", temp_sub_map))
end

--[==[
Undo conversion of digraphs into single Unicode substituted characters.
]==]
function export.unapply_temp_sub(text)
	return rsub(text, ".", temp_unsub_map)
end

--[==[
Split `word` into syllables consisting of consonant clusters (possibly containing no consonants) + possibly accented
vowels. Any final consonant cluster goes into a syllable by itself, which will be present and empty if there is no
trailing consonant cluster, meaning there will always be one more element in the returned list than the actual number of
syllables. Correctly handles syllabic r and y. `word` must already be decomposed!
]==]
function export.split_syllables(word)
	-- Put a syllable divider character after each vowel.
	word = rsub(word, "(" .. vowel_c .. vowel_accent_c .. "*)", "%1" .. SYLDIV)
	-- Temporarily add word boundary markers.
	word = WORD_BOUNDARY .. word .. WORD_BOUNDARY
	-- Any potentially syllabic consonant without a vowel next to it is syllabic. Repeat in case of two syllabic
	-- consonants in adjacent syllables.
	word = rsub_repeatedly(word, "(" .. non_vowel_c .. "[" .. syllabic_cons .. "]" .. vowel_accent_c .. "*)(" ..
		non_vowel_c .. ")", "%1" .. SYLDIV .. "%2")
	return rsplit(rsub(word, WORD_BOUNDARY, ""), SYLDIV)
end

--[==[
Remove any accent in `syl` (one of the syllables in the output of `split_syllables`) and add `new_accent`, which should
be a combining accent.
]==]
function export.replace_syllable_accent(syl, new_accent)
	-- This works because the syllables output by `split_syllables` end in a vowel.
	return rsub(syl, vowel_accent_c, "") .. new_accent
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

local sht_map = add_uppercase_mappings(lc_sht_map)
local iotate_map = add_uppercase_mappings(lc_iotate_map)

--[==[
Iotate `word` according to Serbo-Croatian iotatation rules. There are two possible outputs of [st], either [št] or [šć].
If `sht_output` is specified, [št] results, otherwise [šć].
]==]
function export.iotate(word, sht_output)
	if sht_output then
		-- First check the [st] or [ст]. If this occurs, we need to make the substitution and not then apply the regular
		-- iotation map because it will wrongly convert the resulting [t] into [ć].
		local changed
		word, changed = rsubb(word, "(..)$", sht_map)
		if changed then
			return word
		end
	end
	-- Try to iotate the last two letters, then the last letter. None of the outputs from iotating the last two letters 
	-- using the first rsub() will be affected by the second rsub().
	word = rsub(word, "(..)$", iotate_map)
	return rsub(word, "(.)$", iotate_map)
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
local first_palatalization_map = add_uppercase_mappings(lc_first_palatalization_map)

function export.apply_first_palatalization(word)
	-- Try to palatalize the last two letters, then the last letter. None of the outputs from the first rsub() will be
	-- affected by the second rsub().
	word = rsub(word, "(..)$", first_palatalization_map)
	return rsub(word, "(.)$", first_palatalization_map)
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
local second_palatalization_map = add_uppercase_mappings(lc_second_palatalization_map)

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
	word = rsub(word, "(..)$", second_palatalization_map)
	return rsub(word, "(.)$", second_palatalization_map)
end

--[==[
Determine whether the lemma is reducible. On input, the lemma should already be decomposed.
]==]
function export.determine_default_reducible(lemma)
	-- FIXME, we should handle lemmas ending in -CV (normally, feminine or neuter) and return whether the lemma can be
	-- dereduced (or have a separate function for that).
	-- Convert lj, nj, dž to a single char. Required to get reducible [[šupalj]] correct.
	lemma = export.apply_temp_sub(lemma)
	-- [oо] is Latin + Cyrillic; it's OK to always substitute Latin because of the way the algorithm below works.
	lemma = rsub(lemma, "(" .. vowel_c .. vowel_accent_c .. "*)[oо]$", "%1l")
	-- In a monosyllable, a short falling accent should not prevent reducibility; remove now.
	lemma = rsub(lemma, "^(" .. cons_c .. "*[aа])" .. DOUBLEGR .. "(" .. cons_c .. ")$", "%1%2")
	-- Lemma must end in -CaC with a single C, unstressed and without macron (except for a monosyllabic short falling
	-- accent as in zȁo, which we already removed and converted the -o to -l).
	if not rfind(lemma, cons_c .. "[aа]" .. cons_c .. "$") then
		return false
	end
	-- Lemmas in -av are normally non-reducible.
	if rfind(lemma, "[aа][vв]$") then
		return false
	end
	-- Lemmas in -CraC and -ClaC are non-reducible as the reduction would turn a non-syllabic l/r into a syllabic one,
	-- which can't happen.
	if rfind(lemma, cons_c .. "[rрlл][aа]" .. cons_c .. "$") then
		return false
	end
	return true
end


--[==[
Apply reduction (i.e. remove the fleeting a and apply any required adjustments) to `word`. Return nil if the word can't
be reduced; otherwise, return a list of outputs, as there may be more than one (as in lȅdac "crystal").
]==]
function export.reduce(word)
	-- FIXME: Handle monosyllabic words (after final o -> l) like zȁo.
	word = export.apply_temp_sub(word)
	-- WARNING: [aаAА] contains two Latin chars and two Cyrillic chars, even though the Latin and corresponding
	-- Cyrillic characters look alike. Similarly with oOоО.
	local pre, post = rmatch(word, "^(.*[" .. cons .. "%-])[aаAА]([" .. cons .. "oOоО])$")
	if not pre then
		return nil
	end
	-- Convert o to l before further processing.
	post = rsub(post, "[oOоО]", {
		["o"] = "l", -- Latin
		["O"] = "L", -- capitalized Latin
		["о"] = "л", -- Cyrillic
		["О"] = "Л", -- capitalized Cyrillic
	})
	-- Three-character clusters of sibilant + t/d + certain consonants simplify by removing the t/d.
	-- The following should theoretically apply to all sibilants (including ž and afficates), but there don't seem to
	-- be any cases involving any of them other than st, št and zd (the latter possibly only in [[grozdak]]; it ought
	-- to apply in [[zvezdan]]/[[zvjezdan]], but this word is nonreducible). It should also apply to most consonants
	-- after the fleeting a (but not r, cf [[bistar]] -> bistr-); nouns and adjectives with -av seem to be mostly
	-- (entirely?) nonreducible, cf. [[blistav]] "radiant, dazzling" -> def. [[blistavi]]. The consonants listed below
	-- come from section 93 of Silić and Pranković (which only list [clmnk]) with some logical additions. Some examples:
	-- [[jednolistac]] -> jednòlisca, [[rastao]] -> rásla, [[žalostan]] -> žȁlosna, [[hrastak]] -> hráska,
	-- [[bljuštac]] -> bljúšca, [[hruštak]] -> hrúška.
	if rfind(pre, "[sšzSŠZсшзСШЗ][tTdDтТдД]$") and rfind(post, "[cčćlmnkCČĆLMNKцчћлљмнњкЦЧЋЛЉМНЊК" .. TEMP_LJ ..
		TEMP_NJ .. TEMP_CAP_LJ .. TEMP_CAP_NJ .. "]") then
		pre = rsub(pre, ".$", "")
	end

	-- If t/d occurs before an affricate c/ć/č (not clear it occurs with voiced affricates), the t/d can either drop
	-- out or remain. If it remains, the d remains even before c, e.g. lȅdac "crystal" -> gen lȅca or lȅdca. This
	-- occurs more often when the second palatalization applies to reduced stems ending in -k, e.g. pògodak "goal, hit"
	-- reduces to genitive pògotka but has nominative plural pògoci or pògodci. (Similarly the genitive plural is
	-- pògodākā.)
	if rfind(pre, "[tTdDтТдД]$") and rfind(post, "[cčćCČĆцчћЦЧЋ]") then
		return { export.unapply_temp_sub(rsub(pre, ".$", "") .. post), export.unapply_temp_sub(pre .. post) }
	end

	-- Apply voicing/devoicing to the remaining cluster.
	if rfind(post, "[" .. triggers_voicing .. "]") then
		pre = rsub(pre, ".$", unvoiced_to_voiced)
	elseif rfind(post, "[" .. triggers_devoicing .. "]") then
		pre = rsub(pre, ".$", voiced_to_unvoiced)
	end

	return { export.unapply_temp_sub(pre .. post) }
end


function export.dereduce(base, stem)
	-- FIXME, not converted from Czech
	local pre, letter, post = rmatch(stem, "^(.*)(" .. cons_c .. ")(" .. cons_c .. ")$")
	if not pre then
		return nil
	end
	local epvowel
	if rfind(letter, "[" .. paired_palatal .. "]") then
		letter = paired_palatal_to_plain[letter]
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

return export
