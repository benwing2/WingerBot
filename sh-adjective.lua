local export = {}


--[=[

Authorship: Ben Wing <benwing2>

]=]

--[=[

TERMINOLOGY:

-- "slot" = A particular combination of case/gender/number.
	 Example slot names for adjectives are "gen_f" (genitive feminine singular) and
	 "nom_mp_an" (animate nominative masculine plural). Each slot is filled with zero or more forms.

-- "form" = The declined Serbo-Croatian form representing the value of a given slot.

-- "lemma" = The dictionary form of a given Serbo-Croatian term. Generally the nominative
     masculine singular, but may occasionally be another form if the nominative
	 masculine singular is missing.
]=]

local lang = require("Module:languages").getByCode("sh")
local m_links = require("Module:links")
local m_table = require("Module:table")
local m_string_utilities = require("Module:string utilities")
local iut = require("Module:inflection utilities")
local com = require("Module:sh-common")

local current_title = mw.title.getCurrentTitle()
local NAMESPACE = current_title.nsText
local PAGENAME = current_title.text

local u = m_string_utilities.char
local rsplit = m_string_utilities.split
local rfind = m_string_utilities.find
local rmatch = m_string_utilities.match
local rgmatch = m_string_utilities.gmatch
local rsubn = m_string_utilities.gsub
local ulen = m_string_utilities.len
local uupper = m_string_utilities.upper

local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack -- Lua 5.2 compatibility


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


-- Construct the "reduced" version of a stem. This removes an е or ъ followed by a word-final
-- consonant, stresses the final syllable of the result if necessary, and converts бое́ц into бо́йц- and бо́як into бо́йк-.
-- An error is thrown if the stem can't be reduced.
local function reduce_stem(stem)
	local vowel_ending_stem, final_cons = rmatch(stem, "^(.*" .. com.vowel_c .. AC .. "?)[ея]́?(" .. com.cons_c .. ")$")
	if vowel_ending_stem then
		-- бое́ц etc.
		return com.maybe_stress_final_syllable(vowel_ending_stem .. "й" .. final_cons)
	end
	local initial_stem, final_cons = rmatch(stem, "^(.*)[еъ]́?(" .. com.cons_c .. ")$")
	if initial_stem then
		return com.maybe_stress_final_syllable(initial_stem .. final_cons)
	end
	error("Unable to reduce stem: '" .. stem .. "'")
end


--[=[
-- All slots that are used by any of the different tables. The key is the slot and the value is a list of the tables
-- that use the slot. "" = regular, "plonly" = special=plonly in {{sh-adecl-manual}}, "dva" = special=dva in
-- {{sh-adecl-manual}}.
local input_adjective_slots = {
	nom_m = {""},
	nom_f = {""},
	nom_n = {""},
	nom_mp_an = {"", "plonly"},
	nom_fp = {"", "plonly"},
	nom_np = {"", "plonly"},
	nom_mp = {"dva"},
	nom_fnp = {"dva"},
	gen_mn = {""},
	gen_f = {""},
	gen_p = {"", "plonly", "dva"},
	dat_mn = {""},
	dat_f = {""},
	dat_p = {"", "plonly", "dva"},
	acc_m_an = {""},
	acc_m_in = {""},
	acc_f = {""},
	acc_n = {""},
	acc_mfp = {"", "plonly"},
	acc_np = {"", "plonly"},
	acc_mp = {"dva"},
	acc_fnp = {"dva"},
	ins_mn = {""},
	ins_f = {""},
	ins_p = {"", "plonly", "dva"},
	loc_mn = {""},
	loc_f = {""},
	loc_p = {"", "plonly", "dva"},
}
]=]


local input_adjective_slots = {
	{"nom_m", "nom|m|s"},
	{"nom_m_linked", "nom|m|s"}, -- used in [[Module:sh-noun]]?
	{"nom_f", "nom|f|s"},
	{"nom_n", "nom|n|s"},
	{"nom_mp", "nom|m|p"},
	{"nom_fp", "nom|f|p"},
	{"nom_np", "nom|n|p"},
	{"gen_m", "gen|m|s"},
	{"gen_f", "gen|f|s"},
	{"gen_n", "gen|n|s"},
	{"gen_p", "gen|p"},
	{"dat_m", "dat|m|s"},
	{"dat_f", "dat|f|s"},
	{"dat_n", "dat|n|s"},
	{"dat_p", "dat|p"},
	{"acc_m_an", "an|acc|m|s"},
	{"acc_m_in", "in|acc|m|s"},
	{"acc_f", "acc|f|s"},
	{"acc_n", "acc|n|s"},
	{"acc_mp", "acc|m|p"},
	{"acc_fp", "acc|f|p"},
	{"acc_np", "acc|n|p"},
	{"voc_m", "voc|m|s"},
	{"voc_f", "voc|f|s"},
	{"voc_n", "voc|n|s"},
	{"voc_mp", "voc|m|p"},
	{"voc_fp", "voc|f|p"},
	{"voc_np", "voc|n|p"},
	{"ins_m", "ins|m|s"},
	{"ins_f", "ins|f|s"},
	{"ins_n", "ins|n|s"},
	{"ins_p", "ins|p"},
	{"loc_m", "loc|m|s"},
	{"loc_f", "loc|f|s"},
	{"loc_n", "loc|n|s"},
	{"loc_p", "loc|p"},
}

local adjective_slots = {}
for _, def in ipairs {"indef", "def"} do
	for _, slot_accel in ipairs(input_adjective_slots) do
		local slot_accel = unpack(slot, accel)
		if def == "def" or not slot:find("^voc_") then
			insert(adjective_slots, {def .. "_" .. slot, def .. "|" .. accel})
		end
	end
end


local function combine_stem_ending(stem, ending)
	if stem == "?" then
		return "?"
	else
		return stem .. ending
	end
end


-- Basic function to combine stem(s) and other properties with ending(s) and insert the result into the appropriate
-- slot. `base` is the object describing all the properties of the word being inflected for a single alternant (in case
-- there are multiple alternants specified using `((...))`). `slot` is the slot to add the form(s) to, without the
-- degree prefix ("", "comp_" or "sup_"). (The degree prefix is separated out because the code below sometimes needs to
-- conditionalize on the value of `slot` and should not have to worry about the degree variants.) `degree` is an object
-- describing the particular degree (positive, comparative or superlative) and associated base lemma. `props` is an
-- object containing computed stems and other information (FIXME, what?). The information found in `props` cannot be
-- stored in `degree` because there may be more than one set of such properties per `degree` (e.g. FIXME what?; in such
-- a case, the caller will iterate over all possible combinations, and ultimately invoke add() multiple times, one per
-- combination). `endings` is the ending or endings added to the appropriate stem to get the form(s) to add to the slot.
-- Its value can be a single string, a list of strings, or a list of form objects (i.e. in general list form).
local function add(base, slot, degree, props, endings)
	if not endings then
		return
	end
	-- Call skip_slot() based on the declined number and state.
	if skip_slot(degree.number, degree.state, slot) then
		return
	end
	if type(endings) == "string" then
		endings = {endings}
	end
	local slot_prefix = degree.slot_prefix
	-- Loop over each ending.
	for _, endingobj in ipairs(endings) do
		local ending, ending_footnotes
		if type(endingobj) == "string" then
			ending = endingobj
		else
			ending = endingobj.form
			ending_footnotes = endingobj.footnotes
		end
		-- Ending of "-" means the user used - to indicate there should be no form here.
		if ending == "-" then
			return
		end
		local function interr(msg)
			error(("Internal error: For lemma '%s', slot '%s%s', ending '%s', %s: %s"):format(degree.lemma, slot_prefix,
				slot, ending, msg, dump(base)))
		end

		-- Compute whether i-mutation or u-mutation is in effect, and compute the "mutation footnotes", which are
		-- footnotes attached to a mutation-related indicator and which may need to be added even if no mutation is
		-- in effect (specifically when dealing with an ending that would trigger a mutation if in effect). AFAIK
		-- you cannot have both mutations in effect at once, and i-mutation overrides u-mutation if both would be in
		-- effect.

		-- Double ^^ at the beginning indicates that the u-mutated version should apply. (Single ^ would indicate that
		-- i-mutation should apply, but it doesn't seem relevant to adjectives.)
		local explicit_umut
		ending, explicit_umut = rsubb(ending, "^%^%^", "")
		local is_vowel_ending = rfind(ending, "^" .. com.vowel_c)
		local mut_in_effect, mut_not_in_effect, mut_footnotes
		local ending_in_i = not not ending:find("^i")
		local ending_in_u = not not ending:find("^u")
		if explicit_umut then
			mut_in_effect = "u"
		else
			if ending_in_u and not mut_in_effect then
				mut_in_effect = "u"
				-- umut and uUmut footnotes are incorporated into the appropriate umut_* stems
			end
		end

		local ending_was_asterisk = ending == "*"

		-- Now compute the appropriate stem to which the ending is added.
		local stem_in_effect

		-- Careful with the following logic; it is written carefully and should not be changed without a thorough
		-- understanding of its functioning.
		local has_umut = mut_in_effect == "u"
		-- If the stem is still unset, then use the vowel or non-vowel stem if available. When u-mutation is active, we
		-- first check for the u-mutated version of the vowel or non-vowel stem before falling back to the regular vowel
		-- or non-vowel stem. Note that an expression like `has_umut and props.umut_vstem or props.vstem` here is NOT
		-- equivalent to an if-else or ternary operator expression because if `has_umut` is true and `umut_vstem` is
		-- missing, it will still fall back to `vstem` (which is what we want).
		if not stem_in_effect then
			if is_vowel_ending then
				stem_in_effect = has_umut and props.umut_vstem or props.vstem
			else
				stem_in_effect = has_umut and props.umut_nonvstem or props.nonvstem
			end
		end
		-- Finally, fall back to the basic stem, which is always defined.
		stem_in_effect = stem_in_effect or props.stem

		-- If the ending is "*", it means to use the lemma as the form directly rather than try to construct the form
		-- from a stem and ending. We need to do this for the lemma slot and especially for the nominative singular,
		-- because we don't have the nominative singular ending available and it may vary (e.g. it may be -ur, -l, -n,
		-- etc. especially in the masculine). Not trying to construct the form from stem + ending also avoids
		-- complications from the nominative singular in -ur, which exceptionally does not trigger u-mutation.

		-- Finally, if there is a footnote associated with the computed stem in effect, we need to preserve it.
		if ending == "*" then
			local stem_in_effect_footnotes
			if type(stem_in_effect) == "table" then
				stem_in_effect_footnotes = stem_in_effect.footnotes
			end
			stem_in_effect = iut.combine_form_and_footnotes(degree.actual_lemma, stem_in_effect_footnotes)
			ending = ""
		end

		local infix, infix_footnotes
		-- Compute the infix (j, v or nothing) that goes between the stem and ending.
		if is_vowel_ending then
			if props.vinfix and props.jinfix then
				interr("Can't have specifications for both '.vinfix' and '.jinfix'; should have been caught above")
			end
			if props.vinfix then
				infix = props.vinfix
				infix_footnotes = props.vinfix_footnotes
			elseif props.jinfix and not ending_in_i then
				infix = props.jinfix
				infix_footnotes = props.jinfix_footnotes
			end
		end

		-- If base-level footnotes or degree-level footnotes specified, they go before any stem footnotes, so we
		-- need to extract any footnotes from the stem in effect and insert the base-level footnotes before. In
		-- general, we want the footnotes to be in the order [base.footnotes, degree.footnotes, stem.footnotes,
		-- mut_footnotes, infix_footnotes, ending.footnotes].
		if base.footnotes or degree.footnotes then
			local stem_in_effect_footnotes
			if type(stem_in_effect) == "table" then
				stem_in_effect_footnotes = stem_in_effect.footnotes
				stem_in_effect = stem_in_effect.form
			end
			stem_in_effect = iut.combine_form_and_footnotes(stem_in_effect,
				iut.combine_footnotes(base.footnotes, iut.combine_footnotes(degree.footnotes,
					stem_in_effect_footnotes)))
		end

		local ending_is_full
		ending, ending_is_full = rsubb(ending, "^!", "")

		local function combine_stem_ending(stem, ending)
			if stem == "?" then
				return "?"
			end
			local stem_with_infix = ending_is_full and "" or stem .. (infix or "")
			-- An initial s- of the ending drops after a cluster of cons + s (including written <x>).
			if ending:find("^s") and (stem_with_infix:find("x$") or rfind(stem_with_infix, com.cons_c .. "s$")) then
				ending = ending:sub(2)
			elseif ending:find("^r") then
				if degree.assimilate_r then
					local stem_butlast, stem_last = stem_with_infix:match("^(.*)([ln])$")
					if stem_last then
						ending = stem_last .. ending:sub(2)
					end
				elseif degree.double_r_and_t then
					ending = "r" .. ending
				elseif rfind(stem_with_infix, com.cons_c .. "r$") then
					ending = ending:sub(2)
				end
			elseif ending == "t" then
				if degree.double_r_and_t then
					ending = "tt"
				elseif stem_with_infix:find("dd$") then
					stem_with_infix = stem_with_infix:gsub("dd$", "t")
				else
					local stem_butlast, stem_last = rmatch(stem_with_infix, "^(.*" .. com.cons_c .. ")([dðt])$")
					if stem_butlast then
						stem_with_infix = stem_butlast
					else
						stem_butlast = stem_with_infix:match("^(.*)ð$")
						if stem_butlast then
							if props.pp then
								stem_with_infix = stem_butlast
								ending = "ð"
							else
								stem_with_infix = stem_butlast .. "t"
							end
						elseif degree.inn then
							stem_butlast = stem_with_infix:match("^(.*)n$")
							if stem_butlast then
								stem_with_infix = stem_butlast
								ending = "ð"
							end
						end
					end
				end
			end
			return stem_with_infix .. ending
		end

		local combined_footnotes = iut.combine_footnotes(iut.combine_footnotes(mut_footnotes, infix_footnotes),
			ending_footnotes)
		local ending_with_notes = iut.combine_form_and_footnotes(ending, combined_footnotes)
		if not stem_in_effect then
			interr("stem_in_effect is nil")
		end
		iut.add_forms(base.forms, slot_prefix .. slot, stem_in_effect, ending_with_notes, combine_stem_ending)
	end
end


local function add(base, slot, stems, endings, footnote)
	if stems then
		stems = iut.combine_form_and_footnotes(stems, footnote)
	end
	iut.add_forms(base.forms, slot, stems, endings, combine_stem_ending)
end


--[=[
Comments about axes of variation:
1. Some adjectives are definite-only. This seems to apply to all adjectives in -skī, -čkī and the like, but it also
   applies to some other adjectives. Even in otherwise indefinite contexts, the vocative is definite; some authorities
   consider the indefinite vocative missing, while others copy the definite vocative forms (always the same as the
   nominative) to the indefinite.
2. Some adjectives are reducible, meaning that there is a fleeting ''a'' in the indefinite nominative masculine singular
   that isn't in any other forms. Accompanying the deletion of ''a'' is sometimes consonant cluster simplification, such
   as kȍrīstan "useful", which becomes definite kȍrīsnī. There is also occasionally compensatory lengthening of the
   stressed vowel, as in gròzdak "?" -> gróskī, but I don't know how frequent or regular it is; we might just want to
   handle it manually. Note that not all adjectives in -an are reducible, e.g. lȁgan "light (in weight)" is not.
3. Some compound adjectives have more than one stress, e.g. rȁnobrònčanodȍbnī "hand-to-hand combat (relational)".
4. There are hard and soft adjectives. Soft adjectives end in a palatal consonant (FIXME: what are they, and are there
   "both-ways" consonants, maybe like 'r', that can occur either hard or soft?). Soft adjectives have an -e- instead of
   an -o- in the masculine and neuter singular endings (but notably not in the feminine singular endings, which still
   have dat/loc -ōj and ins -ōm); no plural endings have an -o- in them to begin with.
5. Even outside of reducibility, adjectives can have up to three stem variants. An example with all three is gȏl
   "naked" (which appears in the lemma form as gȏ in Bosnia and Serbia, but maintains the -l- in all other forms).
   This adjective has long-falling gȏl in the indefinite lemma form but short-rising gòl- elsewhere in the indefinite,
   and short-falling gȍl- throughout the definite. The comparative is gòlijī. Note also this means that in general, no
   definite forms can be merged with any indefinite forms. The following multi-stem variants exist:
   a. Vukušić's type 18 (sec 509, page 135): e.g. žȗt "yellow": long falling in lemma, indef nom fem sg žúta, indef nom
      neut sg žúto or less commonly žȗto, etc. elsewhere in the indefinite žút-, definite žȗtī etc. Other examples:
	  bijȇl "white" (which appears to be bȅo in Serbia, otherwise with the same accents but with -e- replacing -ije-),
	  blȃg "soft", blijȇd "pale", bȓz "fast", cijȇl "whole" (also cȉo in the lemma form, with other forms the same; cȅo
	  in Serbia, similarly to bȅo), cȓn "black", čȇst "frequent", čvȓst "fixed; strong", drȃg "dear", fȋn "fine",
	  glȗh "deaf" (glȗv in Serbia), glȗp "stupid", gnjȉo "rotten" (gnjil- in other forms), gȓd "ugly (regional)",
	  grȗb "rough; rude", gȗst "dense", hȗd "angry; bad; evil (rare, archaic, regional)", jȃk "strong", krȋv
	  "guilty; wrong; curved", kȓnj "truncated; incomplete; damaged" (soft declension), krȗt "stiff; strict",
	  kȗs "too short; incomplete (rare)", lijȇn "lazy" (lȇnj in Serbia, soft declension), lijȇp "nice, pretty" (lȇp in
	  Serbia), lȗd "crazy", ljȗt "angry; fierce; spicy", mlȃd "young", mlȃk "tepid; irresolute", nȃg "naked",
	  nijȇm "mute; silent (of a film)" (nȇm in Serbia), plȃh "cowardly", plȃv "blue; blonde",
	  prijȇk "urgent; (when definite) direct, shortened (of a road, etc.)" (presumably prȇk in Serbia),
	  pȗst "empty; futile", rȋđ "reddish, red" (soft declension), rȗd "curly; reddish-brown" (two different etymologies
	  but they appear to have merged completely in inflection), sijȇd "gray" (sȇd in Serbia), sȋv "gray",
	  skȗp "expensive", slȃn "salty", slijȇp "blind" (slȇp in Serbia), strȃn "foreign; strange", sȗh "dry; thin" (sȗv in
	  Serbia), sȗr "ash-gray; gloomy (expressive, literary)", svȇt "holy", štȗr "withered; barren",
	  tȗđ "someone else's; foreign" (soft declension), tȗp "blunt; dull; stupid", tȗst "fat", tvȓd "hard, firm",
	  vrȃn "black, raven-colored (expressive)", vrȗć "hot; cordial" (soft declension), žȋv "alive".
   b. Vukušić's type 19 (sec 510, page 136): e.g. zdrȁv "healthy", bȉstar "clear; clean; clever" (stem bistr-).
      Similarly to type 18, the falling changes to rising elsewhere in the indefinite (optionally in the neuter):
	  zdràva, zdràvo or zdrȁvo, genitive zdràva, etc.; definite zdrȁvī etc. Likewise bìstra, bìstro or bȉstro, genitive
	  bìstra etc.; definite bȉstrī etc. Other examples: blȉzak (stem blisk-) "near", bȍdar (stem bodr-)
	  "alert; vigorous", brȉdak (stem britk-) "sharp; prickly", čȉl/čȉo (stem čil-) "strong, vigorous", čȉst
	  "clean; pure", čȉtak (stem čitk-) "legible", dȍbar (stem dobr-) "good", drȍban (stem drobn-) "small, tiny",
	  dȑzak (stem drsk-) "insolent; arrogant", dȕg "long", gȉbak (stem gipk-) "flexible", glȁdak (stem glatk-) "smooth",
	  grȅz "rough; crude", grȉzak (stem grisk-?) "? (obsolete)", gȑk "bitter (expressive, literary)", hȉtar (stem hitr-)
	  "fast, speedy", hrȍm "lame, limping", jȅdak (stem jetk-) "acrid; scathing", kljȁst "lame (in the arm)",
	  krȅpak (stem krepk-) "strong", kȑhak (stem krhk-) "brittle, fragile", krȍtak (stem krotk-) "tame, gentle",
	  kȑt "brittle", lȁk "easy, light", lȍš "bad, wicked; inferior" (soft declension), lȍvak (stem lovk-?)
	  "? (obsolete)", ljȕbak (stem ljupk-) "cute, charming", mȅdan (stem medn-) "honey-sweet", mȅk "soft",
	  mȉo (stem mil-) "dear; kind", mȍćan (stem moćn-) "powerful; influential", mȍdar (stem modr-) "dark blue",
	  mȍkar (stem mokr-) "wet", mȑčan < mȑk (stem mrčn-?) "? (obsolete), mȑk "brown; grim, gloomy (of a person)",
	  mȑkao (stem mrkl-?) "? (obsolete)", mȑzak (stem mrsk-) "hateful", mȑzao/mȑzal (stem mrzl-)
	  "cold (expressive, literary)", nȉzak (stem nisk-) "low; common, vile", nȍv "new; modern", ȍbal/ȍbao (stem obl-)
	  "round, oval", ȍštar (stem oštr-) "sharp; strict", pȉtak (stem pitk-) "potable", pjȁn
	  "drunk (regional, rhetorical [?])", plȍdan (stem plodn-) "fertile; prolific", pȍstan (stem posn-) "lean", pȍtan
	  (stem potn-?) "? (obsolete)", prȁv "straight; right", pȑhak (stem prhk-) "crumbly", prȍst
	  "common; simple; vulgar", pȕn "full", pȕtak (stem putk-?) "? (obsolete)", rȁd "willing" (maybe no definite
	  forms?), rȅzak (stem resk-) "cutting", rȍdan (stem rodn-) "fruitful, fertile", rȍsan (stem rosn-)
	  "dewy; dew (relational)", sȉt "sated, full", sȉtan (stem sitn-) "tiny; trivial", sklȉzak (stem sklisk-)
	  "slippery", slȁb "weak", slȁdak (stem slatk-) "sweet", spȍr "slow, sluggish", stȁr (definite stȃrī) "old",
	  stȑm "steep", strȍg "severe; harsh", svjȅž "fresh" (svȅž in Serbia), šȕt "hornless (of a young animal)",
	  tȁnak (stem tank-) "thin; slender", tmȁst "dark, fuscous", tmȕo (stem tmul-)
	  "dark, gloomy; muffled, hoarse (of a voice)", tȍpao/tȍpal (stem topl-) "warm", trȍm "sluggish, slow",
	  trȕo (stem trul-) "rotten, putrid", ȕzak (stem usk-) "narrow; tight", vȅdar (stem vedr-)
	  "clear (of the sky); cheerful", vȉtak (stem vitk-) "slim, slender", vjȅšt "able, skillful" (vȅšt in Serbia),
	  vlȁžan (stem vlažn-) "humid", vȍzak (stem vosk-?) "? (obsolete)", vrȅo (stem vrel-) "hot, boiling",
	  zrȅo (stem zrel-) "ripe; mature", žȉdak (stem žitk-) "somewhat thin (in consistency); flexible (figurative)",
	  žȕk "bitter (regional), žȕstar (stem žustr-) "frenetic, energetic".
   c. Vukušić's type 20 (sec 511, page 138): e.g. žédan (stem žedn-) "thirsty". Long rising throughout the indefinite,
      long falling throughout the definite: žédan, žédna, žédno, def. žȇdnī. All of these adjectives are disyllabic
	  (or "trisyllabic" in the case of some adjectives with -ije-) with fleeting ''a''. According to Vukušić (sec 512,
	  page 139), many of these, including žédan, have a variant žȇdan in the lemma form and žȇdno in the neuter, but
	  žédn- elsewhere in the indefinite, and žȇdn- in the definite. Galloglach21 says he's never heard this variant, so
	  it must be rare. Other examples: bijésan (stem bijesn-) "furious" (bésan in Serbia), búdan (stem budn-)
	  "awake", dijélan (stem dijeln-?) "? (obsolete)", drijéman (stem drijemn-?) "? (obsolete; from drijȇm "slumber"),
	  dúžan (stem dužn-) "owing, in debt", gládan (stem gladn-) "hungry", górak (stem gork-) "bitter",
	  gŕdan (stem grdn-) "ugly (colloquial); bad, terrible; many, much", háran (stem harn-)
	  "(archaic) virtuous; modest; (expressive) grateful", hládan (stem hladn-) "cold", hrábar (stem hrabr-)
	  "bold, brave", húdan (stem hudn-?) "? (obsolete)", húlan (stem huln-?) "? (obsolete)", jédar (stem jedr-)
	  "strong, big", kádar "capable, able" (claimed indeclinable by HJP and Školski Rječnik), krátak (stem kratk-)
	  "short", krúpan (stem krupn-) "sturdy, bulky; big", kváran (stem kvarn-) "defective, damaged",
	  lástan (stem lasn-?) "capable, able ('sposoban') (obsolete)", máman (stem mamn-?) "? (obsolete)",
	  mástan (stem masn-) "fatty, greasy; boldface", mázan (stem mazn-) "cuddly", míran (stem mirn-)
	  "calm; quiet; still", mláčan (stem mlačn-) "tepid, lukewarm", mráčan (stem mračn-) "dark, gloomy",
	  mísan (stem misn-) "? (obsolete)", mŕtav (stem mrtv-) "dead; lifeless", múdar (stem mudr-) "wise",
	  mútan (stem mutn-) "unclear; blurry; murky", nágao (stem nagl-) "hasty; sudden; fierce", njéžan (stem nježn-)
	  "tender, soft" (néžan in Serbia), óran (stem orn-) "(colloquial) ready; brave", plítak (stem plitk-) "shallow",
	  prášan (stem prašn-) "powdery, dusty", prázan (stem prazn-) "empty; blank; frivolous", prijésan (stem prijesn-)
	  "raw (of food)" (présan in Seria), rávan (stem ravn-) "straight, right; level", rijédak (stem rijetk-)
	  "rare; sparse; watery (of soup)" (rédak in Serbia), rúžan (stem ružn-) "ugly; unpleasant; dishonest; obscene",
	  sjájan (stem sjajn-) "radiant; great, awesome", slástan (stem slasn-) "delicious, tasty", smijéšan (stem smiješn-)
	  "funny" (sméšan in Serbia), snážan (stem snažn-) "strong, powerful", stálan (stem staln-)
	  "permanent; continuous; stable", stídan (stem stidn-) "shy", strášan (stem strašn-) "dire; terrible",
	  svijétao (stem svijetl-) "bright; light (in color)" (svétao in Serbia), šúpalj (stem šuplj-) "hollow"
	  (soft declension), táman (stem tamn-) "dark, dim", téžak (stem tešk-) "heavy; difficult; unpleasant",
	  tijésan (stem tijesn-) "tight; close, intimate; narrow" (tésan in Serbia), trijézan (stem trijezn-) "sober"
	  (trézan in Serbia), túžan (stem tužn-) "sad", vjéran (stem vjern-) "faithful, loyal" (véran in Serbia),
	  vlástan (stem vlasn-) "powerful, with authority", vrijédan (stem vrijedn-) "precious; diligent; worthy" (vrédan in
	  Serbia), zlátan (stem zlatn-) "golden", znójan (stem znojn-) "sweaty", zráčan (stem zračn-)
	  "airy; air (relational)", zvúčan (sten zvučn-)
	  "resonant, loud; well-known; voiced (of a sound); sound (relational)". Only the following have the žȇdan-type
	  variation: bȗdan, dijȇlan, drijȇman, glȃdan, gȏrak, gȓdan, hȃran, hlȃdan, hrȃbar, hȗdan, hȗlan, krȃtak, krȗpan,
	  kvȃran, mȃstan, mlȃčan, mrȃčan, mȓsan, mȗtan, plȋtak, prȃšan, prȃzan, rȃvan, rijȇdak, rȗžan, sjȃjan, slȃstan,
	  snȃžan, stȋdan, strȃšan, tȃman, težak, tijȇsan, tȗžan, zlȃtan, znȏjan, zrȃčan, zvȗčan.
   d. Sec 411 page 103 says that some adjectives can change a short or long falling accent in the definite into a short
      rising accent. Example is krátak, which per (c) would normally have definite krȃtkī but can also have kràtkī. Per
	  Galloglach21 this is regional, maybe characteristic of the Western areas, e.g. Lika, Dalmatia. Such adjectives
	  include brȏjnī -> bròjnī, cvjȅtnī -> cvjètnī, čȇstī -> čèstī, dȕgi -> dùgī, krȃtki -> kràtki, krȗpnī -> krùpnī,
	  lȏvnī -> lòvnī, lȋsnī -> lìsnī, mȅki -> mèkī, mijȇšnī -> mjèšnī (< mijȇh), mȍkrī -> mòkrī, mȑki -> mr̀ki,
	  mȓsnī -> mr̀snī, nȍćnī -> nòćnī, ȍblī -> òblī, ȍčnī -> òčnī, pȇtnī -> pètnī, plȋtkī -> plìtkī, pȍsnī -> pòsnī,
	  rijȇtkī -> rjètkī, rijȇčnī (prema rijéka) -> rjèčnī (prema rijȇč), rȕčnī -> rùčnī, rȗdnī -> rùdnī, svȇtī -> svètī,
	  strȃšnī -> stràšnī, strȏjnī -> stròjnī, tȇškī -> tèškī, tȏvnī -> tòvnī, vȉtkī -> vìtkī, vjȅčnī -> vjèčnī,
	  zvȗčnī -> zvùčnī, žȉtkī -> žìtkī, žȕčnī -> žùčnī; as well as a similar list of non-reducible adjectives:
	  brȁšnenī -> brašnènī, cr̀kvenī -> crkvènī, đȁvoljī -> đavòljī, ìglenī -> iglènī, jȁnjećī -> janjèćī,
	  kàvenī -> kavènī, kòštanī -> koštànī, làđenī -> lađènī, lȅdenī -> ledènī, nòvčanī -> novčànī,
	  ȍdrenī -> odrènī < ȍdar, pàklenī -> paklènī, pȉlećī -> pilèćī, pùščanī -> puščànī, sr̀čanī -> srčànī,
	  svjètovnī -> svjetòvnī, sùnčanī -> sunčànī, ùljanī -> uljànī, vòdenī -> vodènī, zèmljani -> zemljànī,
	  zòbenī -> zobènī, zvjèzdanī -> zvjezdànī, ždrèbećī -> ždrebèćī.
   e. Vukušić's type 21 (sec 513, page 139): three different accent variants; only two examples, gȏl "naked" (gȏ in
      Bosnia and Serbia) and bȏs "barefoot". In the indefinite, these have gȏl, fem gòla neut gòlo or gȍlo, gòl-
	  throughout the rest of the indefinite paradigm, and gȍlī in the definite.
   f. Vukušić's type 22 (sec 514, page 141): zèlen "green; unripe", fem zelèna, neut zelèno, zelèn- throughout the rest
      of the indefinite paradigm, zèlenī in the definite. Other examples are cr̀ven "red; ruddy", dàlek "far, distant",
	  dèbeo (stem debel-) "fat, thick", dùbok "deep", màlen "small", pòšten "honest, sincere", rùmen "rosy, reddish",
	  stùden "cold; frigid", svìlen "silk (relational); silky", šàren "multicolored; diverse", šìrok "wide", vìsok
	  "high, tall", žèstok "severe; pungent".

]=]
local function add_normal_decl(base, stems,
	def_nom_m, indef_nom_f, def_nom_f, indef_nom_n, def_nom_n,
	indef_nom_mp, def_nom_mp, indef_nom_fp, def_nom_fp, indef_nom_np, def_nom_np,
	indef_gen_mn, def_gen_mn, gen_f, gen_p,
	indef_dat_mn, def_dat_mn, dat_f, dat_p,
	indef_acc_f, def_acc_f, indef_acc_mp, def_acc_mp,
	ins_mn, ins_f,
	indef_loc_mn, def_loc_mn, loc_f,
	footnote)
	if stems then
		stems = iut.combine_form_and_footnotes(stems, footnote)
	end
	add(base, "indef_nom_m", stems, "*")
	add(base, "def_nom_m", stems, def_nom_m)
	add(base, "indef_nom_f", stems, indef_nom_f)
	add(base, "def_nom_f", stems, def_nom_f)
	add(base, "indef_nom_n", stems, indef_nom_n)
	add(base, "def_nom_n", stems, def_nom_n)
	add(base, "indef_nom_mp", stems, indef_nom_mp)
	add(base, "def_nom_mp", stems, def_nom_mp)
	add(base, "indef_nom_fp", stems, indef_nom_fp)
	add(base, "def_nom_fp", stems, def_nom_fp)
	add(base, "indef_nom_np", stems, indef_nom_np)
	add(base, "def_nom_np", stems, def_nom_np)
	add(base, "indef_gen_m", stems, indef_gen_mn)
	add(base, "def_gen_m", stems, def_gen_mn)
	add(base, "indef_gen_f", stems, gen_f)
	add(base, "def_gen_f", stems, gen_f)
	add(base, "indef_gen_n", stems, indef_gen_mn)
	add(base, "def_gen_n", stems, def_gen_mn)
	add(base, "indef_gen_p", stems, gen_p)
	add(base, "def_gen_p", stems, gen_p)
	add(base, "indef_dat_m", stems, indef_dat_mn)
	add(base, "def_dat_m", stems, def_dat_mn)
	add(base, "indef_dat_f", stems, dat_f)
	add(base, "def_dat_f", stems, dat_f)
	add(base, "indef_dat_n", stems, indef_dat_mn)
	add(base, "def_dat_n", stems, def_dat_mn)
	add(base, "indef_dat_p", stems, dat_p)
	add(base, "def_dat_p", stems, dat_p)
	add(base, "indef_acc_m_in", stems, "*")
	add(base, "indef_acc_m_an", stems, indef_gen_mn)
	add(base, "def_acc_m_in", stems, def_nom_m)
	add(base, "def_acc_m_an", stems, def_gen_mn)
	add(base, "indef_acc_f", stems, indef_acc_f)
	add(base, "def_acc_f", stems, def_acc_f)
	add(base, "indef_acc_n", stems, indef_nom_n)
	add(base, "def_acc_n", stems, def_nom_n)
	add(base, "indef_acc_mp", stems, indef_acc_mp)
	add(base, "def_acc_mp", stems, def_acc_mp)
	add(base, "indef_acc_fp", stems, indef_nom_fp)
	add(base, "def_acc_fp", stems, def_nom_fp)
	add(base, "indef_acc_np", stems, indef_nom_np)
	add(base, "def_acc_np", stems, def_nom_np)
	add(base, "voc_nom_m", stems, def_nom_m)
	add(base, "voc_nom_f", stems, def_nom_f)
	add(base, "voc_nom_n", stems, def_nom_n)
	add(base, "voc_nom_mp", stems, def_nom_mp)
	add(base, "voc_nom_fp", stems, def_nom_fp)
	add(base, "voc_nom_np", stems, def_nom_np)
	add(base, "indef_ins_m", stems, ins_mn)
	add(base, "def_ins_m", stems, ins_mn)
	add(base, "indef_ins_f", stems, ins_f)
	add(base, "def_ins_f", stems, ins_f)
	add(base, "indef_ins_n", stems, ins_mn)
	add(base, "def_ins_n", stems, ins_mn)
	add(base, "indef_ins_p", stems, dat_p)
	add(base, "def_ins_p", stems, datt_p)
	add(base, "indef_loc_m", stems, indef_loc_mn)
	add(base, "def_loc_m", stems, def_loc_mn)
	add(base, "indef_loc_f", stems, loc_f)
	add(base, "def_loc_f", stems, loc_f)
	add(base, "indef_loc_n", stems, indef_loc_mn)
	add(base, "def_loc_n", stems, def_loc_mn)
	add(base, "indef_loc_p", stems, dat_p)
	add(base, "def_loc_p", stems, dat_p)
end

decls["normal-Latn"] = function(base, props)
	local soft = props.soft
	add_normal_decl(base, props,
		-- nom sg
		     "ī", "a", "ā", soft and "e" or "o", soft and "ē" or "ō",
		-- nom pl
		"i", "ī", "e", "ē", "a", "ā",
		-- gen
		"a", soft and {"ēg", "ēga"} or {"ōg", "ōga"}, "ē", "īh",
		-- dat
		"u", soft and {"ēm", "ēmu"} or {"ōm", "ōmu", {form = "ōme", footnotes = "not usually in Croatia"}}, "ōj", {"īm", "īma"},
		-- acc
		"u", "ū",
		-- ins
		"īm", "ōm",
		-- loc
		"u", {"ōm", "ōmu"}, "ōj",
	)
end

decls["normal-Cyrl"] = function(base, props)
	local soft = props.soft
	add_normal_decl(base, props,
		-- nom sg
		     "ӣ", "а", "а̄", soft and "е" or "о", soft and "е̄" or "о̄",
		-- nom pl
		"и", "ӣ", "е", "е̄", "а", "а̄",
		-- gen
		"а", soft and {"е̄г", "е̄га"} or {"о̄г", "о̄га"}, "е̄", "ӣх",
		-- dat
		"у", soft and {"е̄м", "е̄му"} or {"о̄м", "о̄му", {form = "о̄ме", footnotes = "not usually in Croatia"}}, "о̄ј", {"ӣм", "ӣма"},
		-- acc
		"у", "ӯ",
		-- ins
		"ӣм", "о̄м",
		-- loc
		"у", {"о̄м", "о̄му"}, "о̄ј",
	)
end

}}
{{sh-decl-adj-1
|title=comparative forms
|nsm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}и | {{{3}}}i}}
|nsf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}а | {{{3}}}a}}
|nsn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|gsm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|gsn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|gsf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}е | {{{3}}}e}}
|dsm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м(у{{#ifeq: {{{4}}}|о|/е|}}) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m(u{{#ifeq:{{{4}}}|o|/e|}})}}
|dsn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м(у{{#ifeq:{{{4}}}|о|/е|}}) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m(u{{ #ifeq:{{{4}}}|o|/e|}})}}
|dsf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}ој | {{{3}}}oj}}
|asm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}и<br>{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | {{{3}}}i<br>{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|asn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|asf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}у | {{{3}}}u}}
|vsm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}и | {{{3}}}i}}
|vsf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}а | {{{3}}}a}}
|vsn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|lsm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м({{#ifeq:{{{4}}}|о|е/|}}у) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m({{#ifeq:{{{4}}}|o|e/|}}u)}}
|lsn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м({{#ifeq:{{{4}}}|о|е/|}}у) | {{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m({{ #ifeq: {{{4}}} | o | e/ | }}u)}}
|lsf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}ој | {{{3}}}oj}}
|ism={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им | {{{3}}}im}}
|isn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им | {{{3}}}im}}
|isf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}ом | {{{3}}}om}}
|npm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}и | {{{3}}}i}}
|npf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}е | {{{3}}}e}}
|npn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}а | {{{3}}}a}}
|gpm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}их | {{{3}}}ih}}
|gpf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}их | {{{3}}}ih}}
|gpn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}их | {{{3}}}ih}}
|dpm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|dpf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|dpn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|apm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}е | {{{3}}}e}}
|apf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}е | {{{3}}}e}}
|apn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}а | {{{3}}}a}}
|vpm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}и | {{{3}}}i}}
|vpf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}е | {{{3}}}e}}
|vpn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}а | {{{3}}}a}}
|lpm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|lpf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|lpn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|ipm={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|ipf={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|ipn={{ #ifeq: {{{sc}}} | Cyrl | {{{3}}}им(а) | {{{3}}}im(a)}}
|sc={{{sc|Latn}}}
}}
{{sh-decl-adj-1
|title=superlative forms
|nsm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}и | naj{{{3}}}i}}
|nsf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}а | naj{{{3}}}a}}
|nsn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|gsm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|gsn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|gsf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}е | naj{{{3}}}e}}
|dsm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м(у{{#ifeq: {{{4}}}|о|/е|}}) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m(u{{#ifeq:{{{4}}}|o|/e|}})}}
|dsn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м(у{{#ifeq:{{{4}}}|о|/е|}}) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m(u{{ #ifeq:{{{4}}}|o|/e|}})}}
|dsf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}ој | naj{{{3}}}oj}}
|asm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}и<br>нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}г(а) | naj{{{3}}}i<br>naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}g(a)}}
|asn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|asf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}у | naj{{{3}}}u}}
|vsm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}и | naj{{{3}}}i}}
|vsf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}а | naj{{{3}}}a}}
|vsn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}} | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}}}
|lsm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м({{#ifeq:{{{4}}}|о|е/|}}у) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m({{#ifeq:{{{4}}}|o|e/|}}u)}}
|lsn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}{{#ifeq: {{{4|о}}}|о|о|е}}м({{#ifeq:{{{4}}}|о|е/|}}у) | naj{{{3}}}{{#ifeq: {{{4|o}}}|o|o|e}}m({{ #ifeq: {{{4}}} | o | e/ | }}u)}}
|lsf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}ој | naj{{{3}}}oj}}
|ism={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им | naj{{{3}}}im}}
|isn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им | naj{{{3}}}im}}
|isf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}ом | naj{{{3}}}om}}
|npm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}и | naj{{{3}}}i}}
|npf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}е | naj{{{3}}}e}}
|npn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}а | naj{{{3}}}a}}
|gpm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}их | naj{{{3}}}ih}}
|gpf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}их | naj{{{3}}}ih}}
|gpn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}их | naj{{{3}}}ih}}
|dpm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|dpf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|dpn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|apm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}е | naj{{{3}}}e}}
|apf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}е | naj{{{3}}}e}}
|apn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}а | naj{{{3}}}a}}
|vpm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}и | naj{{{3}}}i}}
|vpf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}е | naj{{{3}}}e}}
|vpn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}а | naj{{{3}}}a}}
|lpm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|lpf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|lpn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|ipm={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|ipf={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|ipn={{ #ifeq: {{{sc}}} | Cyrl | нај{{{3}}}им(а) | naj{{{3}}}im(a)}}
|sc={{{sc|Latn}}}
}}<noinclude>
[[Category:Serbo-Croatian adjective inflection-table templates|adj]]</noinclude>

decls["normal"] = function(base)
	local stem, suffix

	stem, suffix = rmatch(base.lemma, "^(.*)(ý)$")
	if stem then
		add_normal_decl(base, stem,
			"ý", "á", "é", {}, "é", "á",
			"ého", "é", "ých",
			"ému", "é", "ým",
			"ou",
			"ém", "é", "ých",
			"ým", "ou", "ými"
		)
		-- Do the nominative masculine animate plural separately since it may have a different stem (with the second
		-- palatalization applied).
		add_normal_decl(base, com.apply_second_palatalization(stem, "is adj"), nil, nil, nil, "í")
		if base.short then
			-- Examples of short adjectives:
			-- bledý "pale" -> bled
			-- bosý "barefoot" -> bos
			-- pilný "hardworking, diligent" -> pilen (reducible)
			-- veselý "funny, jolly" -> vesel
			-- jistý "certain, sure" -> jist
			-- vinný "guilty" -> vinen (reducible)
			-- živý "alive, living" -> živ
			-- tichý "quiet" -> tich; mp_an = tiši
			-- vědomý "conscious, aware" -> vědom
			-- rád "glad" (short only)
			-- chudý "poor" -> chud
			-- nevinný "innocent" -> nevinen (reducible)
			-- silný "strong" -> silen (reducible)
			-- známý "known" -> znám
			-- mladý "young" -> mlád (note length); other forms have mlád- or mlad-
			-- starý "old" -> stár (note length); other forms have stár- or star-; mp_an = stáři, staři
			-- slabý "weak" -> sláb (note length); other forms only have sláb- (FIXME: check against a grammar)
			-- zdravý "healthy" -> zdráv (note length); other forms only have zdráv- (FIXME: check against a grammar)
			-- nemocný "ill" -> nemocen (reducible)
			-- plný "full" -> pln
			-- schopný "able, capable" -> schopen (reducible)
			-- vděčný "grateful" -> vděčen (reducible)
			-- věrný "faithful" -> věren (reducible)
			-- šťastný "happy" -> šťasten (reducible)
			-- křepký "strong" -> křepek (reducible); mp_an = křepci
			-- hotový "ready, finished" -> hotov
			-- němý "mute" -> něma
			-- smutný "sad" -> smuten (reducible)
			-- samotný "lonely" -> samoten (reducible)
			-- bohatý "rich" -> bohat
			-- chladný "cold" -> chladen (reducible)
			-- dlužný "necessary?" -> dlužen (reducible)
			-- povinný "mandatory" -> povinen (reducible)
			-- zodpovědný "responsible" -> zodpověden (reducible)
			-- udatný "brave" -> udaten (reducible)
			-- náchylný "susceptible" -> náchylen (reducible)
			for _, short_stem_obj in ipairs(base.short) do
				add_short_decl(base, short_stem_obj.base, "")
				add_short_decl(base, short_stem_obj.stem, nil, "a", "o", nil, "y", "a")
				add_short_decl(base, com.apply_second_palatalization(short_stem_obj.stem.form, "is adj"), nil, nil, nil, "i",
					short_stem_obj.stem.footnotes)
			end
		end
		return
	end

	-- soft in -í
	stem, suffix = rmatch(base.lemma, "^(.*)(í)$")
	if stem then
		add_normal_decl(base, stem,
			"í", "í", "í", "í", "í", "í",
			"ího", "í", "ích",
			"ímu", "í", "ím",
			"í",
			"ím", "í", "ích",
			"ím", "í", "ími"
		)
		return
	end

	-- possessive in -ův
	stem, suffix = rmatch(base.lemma, "^(.*)(ův)$")
	if stem then
		add_normal_decl(base, stem,
			"ův", "ova", "ovo", "ovi", "ovy", "ova",
			"ova", "ovy", "ových",
			"ovu", "ově", "ovým",
			"ovu",
			{"ově", "ovu"}, "ově", "ových",
			"ovým", "ovou", "ovými"
		)
		return
	end

	-- possessive in -in
	stem, suffix = rmatch(base.lemma, "^(.*)(in)$")
	if stem then
		add_normal_decl(base, stem,
			"in", "ina", "ino", "ini", "iny", "ina",
			"ina", "iny", "iných",
			"inu", "ině", "iným",
			"inu",
			{"ině", "inu"}, "ině", "iných",
			"iným", "inou", "inými"
		)
		return
	end

	error("Unrecognized adjective lemma, should end in '-ý', '-í', '-ův' or '-in': '" .. base.lemma .. "'")
end


decls["irreg"] = function(base)
	local stem, suffix

	-- determiner like můj
	stem, suffix = rmatch(base.lemma, "^(.*)(ůj)$")
	if stem then
		add_normal_decl(base, stem,
			"ůj", {"á", "oje"}, {"é", "oje"}, {"í", "oji"}, {"é", "oje"}, {"á", "oje"},
			"ého", {"é", "ojí"}, "ých",
			"ému", {"é", "ojí"}, "ým",
			{"ou", "oji"},
			"ém", {"é", "ojí"}, "ých",
			"ým", {"ou", "ojí"}, "ými"
		)
		return
	end

	if base.lemma == "všechen" then
		add_normal_decl(base, "",
			"všechen", "všechna", {"všechno", "vše"}, "všichni", "všechny", "všechna",
			"všeho", "vší", "všech",
			"všemu", "vší", "všem",
			{"všechnu", "vši"},
			"všem", "vší", "všech",
			"vším", "vší", "všemi"
		)
		return
	end

	if base.lemma == "všecek" then
		add_normal_decl(base, "",
			"všecek", "všecka", {"všecko", "vše"}, "všicci", "všecky", "všecka",
			"všeho", "vší", "všech",
			"všemu", "vší", "všem",
			{"všecku", "vši"},
			"všem", "vší", "všech",
			"vším", "vší", "všemi"
		)
		return
	end

	if base.lemma == "všecken" then
		add_normal_decl(base, "",
			"všecken", "všeckna", {"všeckno", "vše"}, "všickni", "všeckny", "všeckna",
			"všeho", "vší", "všech",
			"všemu", "vší", "všem",
			{"všecknu", "vši"},
			"všem", "vší", "všech",
			"vším", "vší", "všemi"
		)
		return
	end

	-- determiner like [[ten]], [[tamten]], [[tamhleten]], [[tuten]], [[jeden]], [[onen]]
	-- [[tento]] uses 'ten<irreg>to'
	-- [[tenhle]] uses 'ten<irreg>hle'
	-- [[tenhleten]] uses 'ten<irreg>hleten<irreg>'
	stem, suffix = rmatch(base.lemma, "^(.*)(en)$")
	if stem then
		local nom_stem = stem .. suffix
		if nom_stem == "jeden" then
			stem = "jedn"
		end
		add_normal_decl(base, nom_stem, "")
		add_normal_decl(base, stem,
			nil, "a", "o", "i", "y", "a",
			"oho", "é", "ěch",
			"omu", "é", "ěm",
			"u",
			"om", "é", "ěch",
			"ím", "ou", "ěmi"
		)
		return
	end

	-- [[náš]], [[váš]]
	stem, suffix = rmatch(base.lemma, "^(.*)(áš)$")
	if stem then
		local nom_stem = stem .. suffix
		stem = stem .. "aš"
		add_normal_decl(base, nom_stem, "")
		add_normal_decl(base, stem,
			nil, "e", "e", "i", "e", "e",
			"eho", "í", "ich",
			"emu", "í", "im",
			"i",
			"em", "í", "ich",
			"ím", "í", "imi"
		)
		return
	end

	if base.lemma == "jenž" then
		local preposition_footnote = "the leading letter ''j-'' is changed to ''n-'' when the pronoun is preceded by a preposition, e.g. {{m|sh|[[s]] [[nímž]]}}, {{m|sh|[[k]] [[němuž]]}}, {{m|sh|[[bez]] [[níž]]}}"
		preposition_footnote = "[" .. mw.getCurrentFrame():preprocess(preposition_footnote) .. "]"
		-- Add the non-prepositional forms.
		add_normal_decl(base, "",
			"jenž", "jež", "jež", "již", "jež", "jež",
			{"jehož", "jejž"}, "jíž", "jichž",
			"jemuž", "jíž", "jimž",
			"již",
			nil, nil, nil,
			"jímž", "jíž", "jimiž"
		)
		-- Add the prepositional forms. (FIXME: Maybe should go in a separate column in a special table.)
		add_normal_decl(base, "",
			nil, nil, nil, nil, nil, nil,
			{"něhož", "nějž"}, "níž", "nichž",
			"němuž", "níž", "nimž",
			"niž",
			"němž", "níž", "nichž",
			"nímž", "níž", "nimiž",
			preposition_footnote
		)
		-- Unusually, the accusative masculine animate singular is not the same as the genitive masculine singular,
		-- and the accusative masculine inanimate singular is not the same as the nominative masculine singular.
		add(base, "acc_m_an", "", {"jejž", "jehož"})
		add(base, "acc_m_an", "", {"nějž", "něhož"}, preposition_footnote)
		add(base, "acc_m_in", "", "jejž")
		add(base, "acc_m_in", "", "nějž", preposition_footnote)
		return
	end

	if base.lemma == "tentýž" then
		add_normal_decl(base, "",
			"tentýž", "tatáž", "totéž", "titíž", "tytéž", "tatáž",
			"téhož", "téže", "týchž",
			{"témuž", "tomutéž"}, "téže", "týmž",
			"tutéž",
			"tomtéž", "téže", "týchž",
			"tímtéž", "toutéž", "týmiž"
		)
		return
	end

	if base.lemma == "týž" then
		add_normal_decl(base, "",
			"týž", "táž", nil, "tíž", nil, "tatáž",
			"téhož", "téže", "týchž",
			"témuž", "téže", "týmž",
			"touž",
			"témž", "téže", "týchž",
			"týmž", "touž", "týmiž"
		)
		return
	end

	if base.lemma == "sám" then
		-- This mixes long and short endings.
		add_normal_decl(base, "sám", "")
		add_normal_decl(base, "sam",
			nil, "a", "o", "i", "y", "a",
			"ého", "é", "ých",
			"ému", "é", "ým",
			"u",
			"ém", "é", "ých",
			"ým", "ou", "ými"
		)
		-- Unusually, the accusative masculine animate singular is not the same as the genitive masculine singular.
		add(base, "acc_m_an", "sam", {"a", "ého"})
		return
	end

	if base.lemma == "jejíž" then
		add_normal_decl(base, "jej",
			"íž", "íž", "íž", "íž", "íž", "íž",
			"íhož", "íž", "íchž",
			"ímuz", "íž", "ímž",
			"íž",
			"ímž", "íž", "íchž",
			"ímž", "íž", "ímiž"
		)
		return
	end

	error("Unrecognized irregular lemma '" .. base.lemma .. "'")
end


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


local function parse_indicator_spec(angle_bracket_spec)
	local inside = rmatch(angle_bracket_spec, "^<(.*)>$")
	assert(inside)
	local base = {forms = {}}
	if inside ~= "" then
		local parts = rsplit(inside, ".", true)
		for _, part in ipairs(parts) do
			if part == "irreg" then
				base.irreg = true
			elseif part == "short" then
				base.short = {{
					base = {
						form = "+",
					},
					stem = {
						form = "+",
					}
				}}
			elseif rfind(part, "^short:") then
				part = rsub(part, "^short:%s*", "")
				base.short = {}
				local segments = iut.parse_balanced_segment_run(part, "[", "]")
				local comma_separated_groups = iut.split_alternating_runs(segments, "%s*,%s*")
				for _, comma_separated_group in ipairs(comma_separated_groups) do
					if comma_separated_group[1] == "*" then
						-- reducible
						table.insert(base.short, {
							base = {
								form = "*",
								footnotes = fetch_footnotes(comma_separated_group),
							},
							stem = {
								form = "*",
								footnotes = fetch_footnotes(comma_separated_group),
							}
						})
					else
						local slash_separated_groups = iut.split_alternating_runs(comma_separated_group, "%s*/%s*")
						if #slash_separated_groups > 2 then
							error("Too many slash-separated stems: '" .. inside .. "'")
						end
						local short_base = slash_separated_groups[1]
						local short_stem = slash_separated_groups[2]
						local short_base_obj = {
							form = short_base[1],
							footnotes = fetch_footnotes(short_base),
						}
						local short_stem_obj
						if short_stem then
							short_stem_obj = {
								form = short_stem[1],
								footnotes = fetch_footnotes(short_stem),
							}
						end
						table.insert(base.short, {
							base = short_base_obj,
							stem = short_stem_obj,
						})
					end
					iut.insert_form(forms, slot, formobj)
				end
			else
				error("Unrecognized indicator '" .. part .. "': '" .. inside .. "'")
			end
		end
	end
	return base
end


local function normalize_all_lemmas(alternant_multiword_spec, pagename)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		if base.lemma == "" then
			base.lemma = pagename
		end
		base.orig_lemma = base.lemma
		base.orig_lemma_no_links = m_links.remove_links(base.lemma)
		base.lemma = base.orig_lemma_no_links
	end)
end


local function detect_indicator_spec(base)
	if base.short then
		if not base.lemma:find("ý$") then
			error("Short forms can only be specified for lemmas ending in -ý, but saw '" .. base.lemma .. "'")
		end
		local stem = rmatch(base.lemma, "^(.*)ý$")
		for _, short_spec in ipairs(base.short) do
			if short_spec.base.form == "+" then
				short_spec.base.form = stem
			elseif short_spec.base.form == "*" then
				short_spec.base.form = com.dereduce(base, stem)
				if not short_spec.base.form then
					error("Unable to construct non-reduced variant of stem '" .. stem .. "'")
				end
			end
			if not short_spec.stem then
				short_spec.stem = {
					form = short_spec.base.form,
					footnotes = short_spec.base.footnotes
				}
			end
			if short_spec.stem.form == "+" or short_spec.stem.form == "*" then
				short_spec.stem.form = stem
			end
		end
	end

	if base.irreg then
		base.decl = "irreg"
	else
		base.decl = "normal"
	end
end


local function detect_all_indicator_specs(alternant_multiword_spec)
	iut.map_word_specs(alternant_multiword_spec, function(base)
		detect_indicator_spec(base)
	end)
end


local function decline_adjective(base)
	if not decls[base.decl] then
		error("Internal error: Unrecognized declension type '" .. base.decl .. "'")
	end
	decls[base.decl](base)
	-- handle_derived_slots_and_overrides(base)
end


-- Process override for the arguments in `args`, storing the results into `forms`. If `do_acc`, only do accusative
-- slots; otherwise, don't do accusative slots.
local function process_overrides(forms, args, do_acc)
	for slot, _ in pairs(input_adjective_slots) do
		if args[slot] and not not do_acc == not not slot:find("^acc") then
			forms[slot] = nil
			if args[slot] ~= "-" and args[slot] ~= "—" then
				local segments = iut.parse_balanced_segment_run(args[slot], "[", "]")
				local comma_separated_groups = iut.split_alternating_runs(segments, "%s*,%s*")
				for _, comma_separated_group in ipairs(comma_separated_groups) do
					local formobj = {
						form = comma_separated_group[1],
						footnotes = fetch_footnotes(comma_separated_group),
					}
					iut.insert_form(forms, slot, formobj)
				end
			end
		end
	end
end


local function check_allowed_overrides(alternant_multiword_spec, args)
	local special = alternant_multiword_spec.special or alternant_multiword_spec.surname and "surname" or ""
	for slot, types in pairs(input_adjective_slots) do
		if args[slot] then
			local allowed = false
			for _, typ in ipairs(types) do
				if typ == special then
					allowed = true
					break
				end
			end
			if not allowed then
				error(("Override %s= not allowed for %s"):format(slot, special == "" and "regular declension" or
					"special=" .. special))
			end
		end
	end
end


local function set_accusative(alternant_multiword_spec)
	local forms = alternant_multiword_spec.forms
	local function copy_if(from_slot, to_slot)
		if not forms[to_slot] then
			iut.insert_forms(forms, to_slot, forms[from_slot])
		end
	end

	copy_if("nom_n", "acc_n")
	copy_if("gen_mn", "acc_m_an")
	copy_if("nom_m", "acc_m_in")
	copy_if("nom_fp", "acc_mfp")
	copy_if("nom_np", "acc_np")
end


local function add_categories(alternant_multiword_spec)
	local cats = {}
	local plpos = m_string_utilities.pluralize(alternant_multiword_spec.pos or "adjective")
	local function insert(cattype)
		m_table.insertIfNot(cats, "Serbo-Croatian " .. cattype .. " " .. plpos)
	end
	if not alternant_multiword_spec.manual then
		iut.map_word_specs(alternant_multiword_spec, function(base)
			if base.decl == "irreg" then
				insert("irregular")
			elseif rfind(base.lemma, "ý$") then
				insert("hard")
			elseif rfind(base.lemma, "í$") then
				insert("soft")
			else
				insert("possessive")
			end
			if base.short then
				table.insert(cats, "Serbo-Croatian " .. plpos .. " with short forms")
			end
		end)
	end
	alternant_multiword_spec.categories = cats
end


local function show_forms(alternant_multiword_spec)
	local lemmas = {}
	local lemmaform = alternant_multiword_spec.forms.nom_m or alternant_multiword_spec.forms.nom_mp or
		alternant_multiword_spec.forms.nom_mp_an
	if lemmaform then
		for _, form in ipairs(lemmaform) do
			table.insert(lemmas, form.form)
		end
	end
	local props = {
		lemmas = lemmas,
		slot_table = get_output_adjective_slots(alternant_multiword_spec),
		lang = lang,
	}
	iut.show_forms(alternant_multiword_spec.forms, props)
end


local function make_table(alternant_multiword_spec)
	local forms = alternant_multiword_spec.forms

	local function template_prelude(min_width)
		return rsub([===[
<div>
<div class="NavFrame" style="display: inline-block; min-width: MINWIDTHem">
<div class="NavHead" style="background:#eff7ff">{title}{annotation}</div>
<div class="NavContent">
{\op}| border="1px solid #000000" style="border-collapse:collapse;background:#F9F9F9;text-align:center; min-width:MINWIDTHem" class="inflection-table"
|-
]===], "MINWIDTH", min_width)
	end

	local function template_postlude()
		return [=[
|{\cl}{notes_clause}</div></div></div>]=]
	end

	local table_spec_sg = [=[
! style="background:#d9ebff" colspan=5 | singular
|-
! style="background:#d9ebff" |
! style="background:#d9ebff" | masculine animate
! style="background:#d9ebff" | masculine inanimate
! style="background:#d9ebff" | feminine
! style="background:#d9ebff" | neuter
|-
! style="background:#eff7ff" | nominative
| colspan=2 | {nom_m}
| {nom_f}
| {nom_n}
|-
! style="background:#eff7ff" | genitive
| colspan=2 | {gen_mn}
| {gen_f}
| {gen_mn}
|-
! style="background:#eff7ff" | dative
| colspan=2 | {dat_mn}
| {dat_f}
| {dat_mn}
|-
! style="background:#eff7ff" | accusative
| {acc_m_an}
| {acc_m_in}
| {acc_f}
| {acc_n}
|-
! style="background:#eff7ff" | locative
| colspan=2 | {loc_mn}
| {loc_f}
| {loc_mn}
|-
! style="background:#eff7ff" | instrumental
| colspan=2 | {ins_mn}
| {ins_f}
| {ins_mn}{short_sg_clause}
]=]

	local table_spec_pl = [=[
! style="background:#d9ebff" colspan=5 | plural
|-
! style="background:#d9ebff" | 
! style="background:#d9ebff" | masculine animate
! style="background:#d9ebff" | masculine inanimate
! style="background:#d9ebff" | feminine
! style="background:#d9ebff" | neuter
|-
! style="background:#eff7ff" | nominative
| {nom_mp_an}
| colspan=2 | {nom_fp}
| {nom_np}
|-
! style="background:#eff7ff" | genitive
| colspan=4 | {gen_p}
|-
! style="background:#eff7ff" | dative
| colspan=4 | {dat_p}
|-
! style="background:#eff7ff" | accusative
| colspan=3 | {acc_mfp}
| {acc_np}
|-
! style="background:#eff7ff" | locative
| colspan=4 | {loc_p}
|-
! style="background:#eff7ff" | instrumental
| colspan=4 | {ins_p}{short_pl_clause}
]=]

	local table_spec = template_prelude("55") .. table_spec_sg .. "|-\n" .. table_spec_pl .. template_postlude()

	local table_spec_plonly = template_prelude("55") .. table_spec_pl .. template_postlude()

	local table_spec_dva = template_prelude("40") .. [=[
! style="width:40%;background:#d9ebff" colspan="2" | 
! style="background:#d9ebff" colspan="2" | plural
|-
! style="width:40%;background:#d9ebff" colspan="2" | 
! style="background:#d9ebff" | masculine
! style="background:#d9ebff" | feminine/neuter
|-
! style="background:#eff7ff" colspan="2" | nominative
| {nom_mp}
| {nom_fnp}
|-
! style="background:#eff7ff" colspan="2" | genitive
| colspan="2" | {gen_p} 
|-
! style="background:#eff7ff" colspan="2" | dative
| colspan="2" | {dat_p} 
|-
! style="background:#eff7ff" colspan="2" | accusative
| {acc_mp}
| {acc_fnp}
|-
! style="background:#eff7ff" colspan="2" | locative
| colspan="2" | {loc_p} 
|-
! style="background:#eff7ff" colspan="2" | instrumental
| colspan="2" | {ins_p} 
]=] .. template_postlude()

	local short_sg_template = [=[

|-
! style="background:#eff7ff" | short
| colspan=2 | {short_m}
| {short_f}
| {short_n}
]=]

	local short_pl_template = [=[

|-
! style="background:#eff7ff" | short
| {short_mp_an}
| colspan=2 | {short_fp}
| {short_np}]=]

	local notes_template = [===[
<div style="width:100%;text-align:left;background:#d9ebff">
<div style="display:inline-block;text-align:left;padding-left:1em;padding-right:1em">
{footnote}
</div></div>
]===]

	if alternant_multiword_spec.title then
		forms.title = alternant_multiword_spec.title
	else
		forms.title = 'Declension of <i lang="sh">' .. forms.lemma .. '</i>'
	end

	if alternant_multiword_spec.manual then
		forms.annotation = ""
	else
		local ann_parts = {}
		local decls = {}
		iut.map_word_specs(alternant_multiword_spec, function(base)
			if base.decl == "irreg" then
				m_table.insertIfNot(decls, "irregular")
			elseif rfind(base.lemma, "ý$") then
				m_table.insertIfNot(decls, "hard")
			elseif rfind(base.lemma, "í$") then
				m_table.insertIfNot(decls, "soft")
			else
				m_table.insertIfNot(decls, "possessive")
			end
		end)
		table.insert(ann_parts, table.concat(decls, " // "))
		forms.annotation = " (" .. table.concat(ann_parts, ", ") .. ")"
	end

	forms.notes_clause = forms.footnote ~= "" and
		m_string_utilities.format(notes_template, forms) or ""
	forms.short_sg_clause = forms.short_m and forms.short_m ~= "—" and
		m_string_utilities.format(short_sg_template, forms) or ""
	forms.short_pl_clause = forms.short_mp_an and forms.short_mp_an ~= "—" and
		m_string_utilities.format(short_pl_template, forms) or ""
	return m_string_utilities.format(
		alternant_multiword_spec.special == "plonly" and table_spec_plonly or
		alternant_multiword_spec.special == "dva" and table_spec_dva or
		table_spec, forms
	)
end

-- Externally callable function to parse and decline an adjective given
-- user-specified arguments. Return value is WORD_SPEC, an object where the
-- declined forms are in `WORD_SPEC.forms` for each slot. If there are no values
-- for a slot, the slot key will be missing. The value for a given slot is a
-- list of objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms(parent_args, pos, from_headword, def)
	local params = {
		[1] = {},
		pos = {},
		json = {type = "boolean"}, -- for use with bots
		title = {},
		pagename = {},
	}
	for slot, _ in pairs(input_adjective_slots) do
		params[slot] = {}
	end

	-- Only default param 1 when displaying the template.
	local args = require("Module:parameters").process(parent_args, params)
	local SUBPAGE = mw.title.getCurrentTitle().subpageText
	local pagename = args.pagename or SUBPAGE
	if not args[1] then
		if SUBPAGE == "sh-adecl" then
			args[1] = "křepký<short:*>"
		else
			args[1] = pagename
		end
	end		
	local parse_props = {
		parse_indicator_spec = parse_indicator_spec,
		allow_default_indicator = true,
		allow_blank_lemma = true,
	}
	local alternant_multiword_spec = iut.parse_inflected_text(args[1], parse_props)
	alternant_multiword_spec.pos = args.pos
	alternant_multiword_spec.title = args.title
	alternant_multiword_spec.forms = {}
	normalize_all_lemmas(alternant_multiword_spec, pagename)
	detect_all_indicator_specs(alternant_multiword_spec)
	check_allowed_overrides(alternant_multiword_spec, args)
	local inflect_props = {
		slot_table = get_output_adjective_slots(alternant_multiword_spec),
		inflect_word_spec = decline_adjective,
	}
	iut.inflect_multiword_or_alternant_multiword_spec(alternant_multiword_spec, inflect_props)
	-- Do non-accusative overrides so they get copied to the accusative forms appropriately.
	process_overrides(alternant_multiword_spec.forms, args)
	set_accusative(alternant_multiword_spec)
	-- Do accusative overrides after copying the accusative forms.
	process_overrides(alternant_multiword_spec.forms, args, "do acc")
	add_categories(alternant_multiword_spec)
	if args.json and not from_headword then
		return require("Module:JSON").toJSON(alternant_multiword_spec)
	end
	return alternant_multiword_spec
end


-- Externally callable function to parse and decline an adjective where all
-- forms are given manually. Return value is WORD_SPEC, an object where the
-- declined forms are in `WORD_SPEC.forms` for each slot. If there are no values
-- for a slot, the slot key will be missing. The value for a given slot is a
-- list of objects {form=FORM, footnotes=FOOTNOTES}.
function export.do_generate_forms_manual(parent_args, pos, from_headword, def)
	local params = {
		pos = {},
		special = {},
		json = {type = "boolean"}, -- for use with bots
		title = {},
	}
	for slot, _ in pairs(input_adjective_slots) do
		params[slot] = {}
	end

	local args = require("Module:parameters").process(parent_args, params)
	local alternant_multiword_spec = {
		pos = args.pos,
		special = args.special,
		title = args.title, 
		forms = {},
		manual = true,
	}
	check_allowed_overrides(alternant_multiword_spec, args)
	-- Do non-accusative overrides so they get copied to the accusative forms appropriately.
	process_overrides(alternant_multiword_spec.forms, args)
	set_accusative(alternant_multiword_spec)
	-- Do accusative overrides after copying the accusative forms.
	process_overrides(alternant_multiword_spec.forms, args, "do acc")
	add_categories(alternant_multiword_spec)
	if args.json and not from_headword then
		return require("Module:JSON").toJSON(alternant_multiword_spec)
	end
	return alternant_multiword_spec
end


-- Entry point for {{sh-adecl}}. Template-callable function to parse and decline 
-- an adjective given user-specified arguments and generate a displayable table
-- of the declined forms.
function export.show(frame)
	local parent_args = frame:getParent().args
	local alternant_multiword_spec = export.do_generate_forms(parent_args)
	show_forms(alternant_multiword_spec)
	return make_table(alternant_multiword_spec) .. require("Module:utilities").format_categories(alternant_multiword_spec.categories, lang)
end


-- Entry point for {{sh-adecl-manual}}. Template-callable function to parse and
-- decline an adjective given manually-specified inflections and generate a
-- displayable table of the declined forms.
function export.show_manual(frame)
	local parent_args = frame:getParent().args
	local alternant_multiword_spec = export.do_generate_forms_manual(parent_args)
	show_forms(alternant_multiword_spec)
	return make_table(alternant_multiword_spec) .. require("Module:utilities").format_categories(alternant_multiword_spec.categories, lang)
end


return export
