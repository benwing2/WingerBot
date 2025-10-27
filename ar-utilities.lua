local export = {}

local m_utilities = require("Module:utilities")
local lang = require("Module:languages").getByCode("ar")
local sc = require("Module:scripts").getByCode("Arab")

local rfind = mw.ustring.find
local rsubn = mw.ustring.gsub
local u = require("Module:string/char")

local consonants = "[بتثجحخدذرزسشصضطظعغقفلكمنهويء]"

-- version of rsubn() that discards all but the first return value
function export.rsub(term, foo, bar)
	local retval = rsubn(term, foo, bar)
	return retval
end
local rsub = export.rsub

-- synthesize a frame so that exported functions meant to be called from
-- templates can be called from the debug console.
function export.debug_frame(parargs, args)
	return { args = args, getParent = function() return { args = parargs } end }
end

function export.catfix()
	return m_utilities.catfix(lang, sc)
end

--------------------------- diacritics, letters and combinations ------------------------------

-- hamza variants
local HAMZA                = u(0x0621) -- hamza on the line (stand-alone hamza) = ء
local HAMZA_ON_ALIF        = u(0x0623)
local HAMZA_ON_WAW         = u(0x0624)
local HAMZA_UNDER_ALIF     = u(0x0625)
local HAMZA_ON_YA          = u(0x0626)
local HAMZA_PH             = u(0xFFF0) -- hamza placeholder

export.HAMZA = HAMZA
export.HAMZA_ON_ALIF = HAMZA_ON_ALIF
export.HAMZA_ON_WAW = HAMZA_ON_WAW
export.HAMZA_UNDER_ALIF = HAMZA_UNDER_ALIF
export.HAMZA_ON_YA = HAMZA_ON_YA
export.HAMZA_PH = HAMZA_PH

-- diacritics
local A                    = u(0x064E) -- fatḥa
local AN                   = u(0x064B) -- fatḥatān (fatḥa tanwīn)
local U                    = u(0x064F) -- ḍamma
local UN                   = u(0x064C) -- ḍammatān (ḍamma tanwīn)
local I                    = u(0x0650) -- kasra
local IN                   = u(0x064D) -- kasratān (kasra tanwīn)
local SK                   = u(0x0652) -- sukūn = no vowel
local SH                   = u(0x0651) -- šadda = gemination of consonants
local DAGGER_ALIF          = u(0x0670)
-- Pattern matching any diacritics that may be on a consonant other than shadda
local DIACRITIC_ANY_BUT_SH = "[" .. A .. I .. U .. AN .. IN .. UN .. SK .. DAGGER_ALIF .. "]"
-- Pattern matching short vowels
local AIU                  = "[" .. A .. I .. U .. "]"
-- Pattern matching any diacritics that may be on a consonant
local DIACRITIC            = SH .. "?" .. DIACRITIC_ANY_BUT_SH

export.A = A
export.AN = AN
export.U = U
export.UN = UN
export.I = I
export.IN = IN
export.SK = SK
export.SH = SH
export.DAGGER_ALIF = DAGGER_ALIF
-- Pattern matching any diacritics that may be on a consonant other than shadda
export.DIACRITIC_ANY_BUT_SH = DIACRITIC_ANY_BUT_SH
-- Pattern matching short vowels
export.AIU = AIU
-- Pattern matching any diacritics that may be on a consonant
export.DIACRITIC = DIACRITIC

-- various letters and signs
local ALIF                 = u(0x0627) -- ʾalif = ا
local ALIF_WASLA           = u(0x0671) -- ʾalif waṣla = hamzatu l-waṣl = ٱ
local AMAQ                 = u(0x0649) -- ʾalif maqṣūra = ى
local AMAD                 = u(0x0622) -- ʾalif madda = آ
local TAM                  = u(0x0629) -- tāʾ marbūṭa = ة
local WAW                  = u(0x0648) -- wāw = و
local W                    = WAW
local YA                   = u(0x064A) -- yā = ي
local Y                    = YA
local T                    = u(0x062A) -- tāʾ = ت 
local HYPHEN               = u(0x0640)
local N                    = u(0x0646) -- nūn = ن
local LRM                  = u(0x200E) -- left-to-right mark

export.ALIF = ALIF
export.ALIF_WASLA = ALIF_WASLA
export.AMAQ = AMAQ
export.AMAD = AMAD
export.TAM = TAM
export.WAW = WAW
export.W = W
export.YA = YA
export.Y = Y
export.T = T
export.HYPHEN = HYPHEN
export.N = N
export.LRM = LRM

-- common combinations
local AW = A .. W       -- diphthong, construct state of some final-weak nouns, 3sm past of some final-weak verbs, etc.
local AY = A .. Y       -- diphthong, construct state of most final-weak nouns, 3sm past of most final-weak verbs, etc.
local IY = I .. Y       -- equivalent to long ī
local UW = U .. W       -- equivalent to long ū
local AA = A .. ALIF    -- long ā
local AAMAQ = A .. AMAQ -- vocalized ʾalif maqṣūra
local II = IY           -- long ī
local IIN = IY .. N     -- short strong masculine oblique plural ending
local IINA = IIN .. A   -- full strong msaculine oblique plural ending
local UU = UW           -- long ū
local UUN = UU .. N     -- short strong masculine nominative plural ending
local UUNA = UUN .. A   -- full strong masculine nominative plural ending
local AWN = AW .. SK .. N -- short verbal ending of some final-weak verbs
local AWNA = AWN .. A   -- full verbal ending of some final-weak verbs
local AYN = AY .. SK .. N -- short oblique dual ending, verbal ending of some final-weak verbs
local AYNI = AYN .. I   -- full oblique dual ending
local AYNA = AYN .. A   -- full verbal ending of some final-weak verbs
local AAN = AA .. N     -- short nominative dual ending
local AANI = AAN .. I   -- full nominative dual ending
local UNU = "[" .. UN .. U .. "]" -- matches nominative singular of strong masculine triptotes and diptotes
local UNUOPT = UNU .. "?" -- optional equivalent of UNU, for short forms
local AH = A .. TAM     -- feminine ending
local AAH = AA .. TAM   -- final-weak feminine ending
local AAT = AA .. T     -- short strong feminine plural ending
local AATUN = AAT .. UN -- full strong nominative feminine plural ending
local IYAH = I .. Y .. AH -- ending of some final-weak feminines
local AYAAT = AY .. AAT -- final-weak plural ending
local AYAAN = AY .. AAN -- final-weak dual ending
local IYAAT = IY .. AAT -- final-weak plural ending
local IYAAN = IY .. AAN -- final-weak dual ending
local IYY = IY .. SH    -- masculine nisba ending
local IYYAH = IY .. SH .. AH -- feminine nisba ending
local ATAAN = A .. T .. AAN -- feminine dual ending
local AATAAN = AAT .. AAN -- final-weak feminine dual ending

-- other possibilities (currently found in verb module):
-- AT, AYSK, AWSK, N, NA, NI, M, MA, MU, TA, TU, _I = ALIF .. I, _U = ALIF .. U

export.AW = AW
export.AY = AY
export.IY = IY
export.UW = UW
export.AA = AA
export.AAMAQ = AAMAQ
export.II = II
export.IIN = IIN
export.IINA = IINA
export.UU = UU
export.UUN = UUN
export.UUNA = UUNA
export.AWN = AWN
export.AWNA = AWNA
export.AYN = AYN
export.AYNI = AYNI
export.AYNA = AYNA
export.AAN = AAN
export.AANI = AANI
export.UNU = UNU
export.UNUOPT = UNUOPT
export.AH = AH
export.AAH = AAH
export.AAT = AAT
export.AATUN = AATUN
export.IYAH = IYAH
export.AYAAT = AYAAT
export.AYAAN = AYAAN
export.IYAAT = IYAAT
export.IYAAN = IYAAN
export.IYY = IYY
export.IYYAH = IYYAH
export.ATAAN = ATAAN
export.AATAAN = AATAAN

function export.reorder_shadda(text)
	-- shadda+short-vowel (including tanwīn vowels, i.e. -an -in -un) gets
	-- replaced with short-vowel+shadda during NFC normalisation, which
	-- MediaWiki does for all Unicode strings; however, it makes the
	-- detection process inconvenient, so undo it. (For example, the code in
	-- remove_in would fail to detect the -in in مُتَرَبٍّ because the shadda
	-- would come after the -in.)
	text = rsub(text, "(" .. DIACRITIC_ANY_BUT_SH .. ")" .. SH, SH .. "%1")
	return text
end

function export.undo_reorder_shadda(text)
	return mw.ustring.toNFC(text)
end

--------------------------- hamza processing ------------------------------

local hamza_subs = {
	--------------------------- handle initial hamza --------------------------
	-- put initial hamza on a seat according to following vowel.
	{ "^" .. HAMZA_PH .. "([" .. I .. YA .. "])", HAMZA_UNDER_ALIF .. "%1" },
	{ " " .. HAMZA_PH .. "([" .. I .. YA .. "])", " " .. HAMZA_UNDER_ALIF .. "%1" },
	{ "^" .. HAMZA_PH,                            HAMZA_ON_ALIF }, -- if no vowel, assume a
	{ " " .. HAMZA_PH,                            " " .. HAMZA_ON_ALIF }, -- if no vowel, assume a

	----------------------------- handle final hamza --------------------------
	-- "final" hamza may be followed by a short vowel or tanwīn sequence
	-- use a previous short vowel to get the seat
	{ "(" .. AIU .. ")(" .. HAMZA_PH .. ")(" .. DIACRITIC .. "?)$",
		function(v, ham, diacrit)
			ham = v == I and HAMZA_ON_YA or v == U and HAMZA_ON_WAW or HAMZA_ON_ALIF
			return v .. ham .. diacrit
		end
	},
	{ "(" .. AIU .. ")(" .. HAMZA_PH .. ")(" .. DIACRITIC .. "? )",
		function(v, ham, diacrit)
			ham = v == I and HAMZA_ON_YA or v == U and HAMZA_ON_WAW or HAMZA_ON_ALIF
			return v .. ham .. diacrit
		end
	},
	-- else hamza is on the line
	{ HAMZA_PH .. "(" .. DIACRITIC .. "?)$", HAMZA .. "%1" },

	---------------------------- handle medial hamza --------------------------
	-- if long vowel or diphthong precedes, we need to ignore it.
	{ "([" .. AMAD .. ALIF .. WAW .. YA .. "]" .. SK .. "?)(" .. HAMZA_PH .. ")(" .. SH .. "?)([^ ])",
		function(prec, ham, shad, v2)
			ham = (v2 == I or v2 == YA) and HAMZA_ON_YA or
				(v2 == U or v2 == WAW) and HAMZA_ON_WAW or
				rfind(prec, YA) and HAMZA_ON_YA or
				HAMZA
			return prec .. ham .. shad .. v2
		end
	},
	-- otherwise, seat of medial hamza relates to vowels on one or both sides.
	{ "([^ ])(" .. HAMZA_PH .. ")(" .. SH .. "?)(" .. AN .. "?[^ ])",
		function(v1, ham, shad, v2)
			ham = (v1 == I or v2 == I or v2 == YA) and HAMZA_ON_YA or
				(v1 == U or v2 == U or v2 == WAW) and HAMZA_ON_WAW or
				-- special exception for the accusative ending, in words like
				-- جُزْءًا (juzʾan). By the rules of Thackston pp. 281-282 a
				-- hamza-on-alif should appear, but that would result in
				-- two alifs in a row, which is generally forbidden.
				-- According to Haywood/Nahmad pp. 114-115, after sukūn before
				-- the accusative ending (including when a pronominal suffix
				-- follows) hamza is written on yāʾ if the previous letter
				-- is connecting, else on the line. The only examples they
				-- give involve preceding non-connecting z (جُزْءًا juzʾan and
				-- (جُزْءَهُ juzʾahu) and preceding diphthongs, with the only
				-- connecting letter being yāʾ, where we have hamza-on-yāʾ
				-- anyway by the preceding regexp. Haywood/Nahmad's rule seems
				-- too complicated, and since it conflicts with Thackston,
				-- we only implement the case where otherwise two alifs would
				-- appear with the indefinite accusative ending.
				v2 == AN .. ALIF and HAMZA or
				HAMZA_ON_ALIF
			return v1 .. ham .. shad .. v2
		end
	},

	--------------------------- handle alif madda -----------------------------
	{ HAMZA_ON_ALIF .. A .. "?" .. ALIF,     AMAD },

	----------------------- catch any remaining hamzas ------------------------
	{ HAMZA_PH,                              HAMZA }
}

function export.process_hamza(term)
	-- convert HAMZA_PH into appropriate hamza seat
	for _, sub in ipairs(hamza_subs) do
		term = rsub(term, sub[1], sub[2])
	end

	-- sequence of hamza-on-wāw + wāw is problematic and leads to a preferred
	-- alternative with some other type of hamza, as well as the original
	-- sequence; sequence of wāw + hamza-on-wāw + wāw is especially problematic
	-- and leads to two different alternatives with the original sequence not
	-- one of them
	if rfind(term, WAW .. "ؤُو") then
		return { rsub(term, WAW .. "ؤُو", WAW .. "ئُو"), rsub(term, WAW .. "ؤُو", WAW .. "ءُو") }
	elseif rfind(term, YA .. "ؤُو") then
		return { rsub(term, YA .. "ؤُو", YA .. "ئُو"), term }
	elseif rfind(term, ALIF .. "ؤُو") then
		-- Here John Mace "Arabic Verbs" is inconsistent. In past-tense parts,
		-- the preferred alternative has hamza on the line, whereas in
		-- non-past parts the preferred alternative has hamza-on-yāʾ even
		-- though the sequence of vowels is identical. It's too complicated to
		-- propagate information about tense through to here so pick one.
		return { rsub(term, ALIF .. "ؤُو", ALIF .. "ئُو"), term }
		-- no alternative spelling in sequence of U/A + hamza-on-wāw + U + wāw;
		-- sequence of I + hamza-on-wāw + U + wāw does not occur (has
		-- hamza-on-yāʾ instead)
	else
		return { term }
	end
end

----------------------------------- misc junk ---------------------------------

-- Used in {{ar-adj-in}} so that we can specify a full lemma rather than
-- requiring the user to truncate the -in ending. FIXME: Move ar-adj-in
-- into Lua.
function export.remove_in(frame)
	local lemma = frame.args[1] or error("Lemma required.")
	return rsub(export.reorder_shadda(lemma), IN .. "$", "")
end

-- Used in {{ar-adj-an}} so that we can specify a full lemma rather than
-- requiring the user to truncate the -an ending. FIXME: Move ar-adj-an
-- into Lua.
function export.remove_an(frame)
	local lemma = frame.args[1] or error("Lemma required.")
	return rsub(export.reorder_shadda(lemma), AN .. AMAQ .. "$", "")
end

-- Compare two words and find the alternation pattern (vowel changes, prefixes, suffixes etc.)
-- Still a WIP, doesn't work correctly yet.
function export.find_pattern(word1, word2)
	return nil
end

function export.etymology(frame)
	local text, categories = {}, {}
	local linkText
	local frame_params = {
		[1] = { required = true },
	}
	local frame_args = require("Module:parameters").process(frame.args, frame_params)

	local anchor = frame_args[1]

	local data = {
		["color adjective"] = {
			anchor = "Color or defect adjectives",
			text = "color adjective",
			categories = { "color/defect adjectives" },
		},
		["defect adjective"] = {
			anchor = "Color or defect adjectives",
			text = "defect adjective",
			categories = { "color/defect adjectives" },
		},
	}

	local params = {
		[1] = {},
		["nocat"] = { type = "boolean", default = false },
		["lc"] = { type = "boolean", default = false },
		["nocap"] = { alias_of = "lc" },
		["notext"] = { type = "boolean", default = false },
	}

	local args = require("Module:parameters").process(frame:getParent().args, params)

	if anchor and data[anchor] then
		local data = data[anchor]
		anchor = data.anchor or error('The data table does not include an anchor for "' .. anchor .. '".')
		linkText = data.text or error('The data table does not include link text for "' .. anchor .. '".')
		if not args.lc then
			linkText = rsubn(linkText, "^%a", function(a) return mw.ustring.upper(a) end)
		end

		if not args.notext then
			table.insert(text, "[[Appendix:Arabic nominals#" .. anchor .. "|" .. linkText .. "]]")
		end

		if not args.nocat then
			table.insert(categories, m_utilities.format_categories(data.categories, lang))
		end
	else
		error('The anchor "' .. tostring(anchor) .. '" is not found in the list of anchors.')
	end

	return table.concat(text) .. table.concat(categories)
end

return export
