local labels = {}
local handlers = {}

local category_tree_utilities_module = "Module:category tree/utilities"

------- GERMANIC VERB CLASSES -------

labels["strong verbs"] = {
	description = "{{{langname}}} verbs that do not use a dental suffix to mark the past tense and past participle, instead using vowel change ([[ablaut]]) and often a suffix ''-(e)n'' in the past participle.",
	breadcrumb = "strong",
	parents = {"verbs by inflection type"},
}

labels["weak verbs"] = {
	description = "{{{langname}}} verbs that display dental suffixes in their past tense conjugated forms.",
	breadcrumb = "weak",
	parents = {"verbs by inflection type"},
}

labels["preterite-present verbs"] = {
	description = "{{{langname}}} verbs that inflect in the present tense like the past tense of strong verbs.",
	breadcrumb = "preterite-present",
	parents = {"verbs by inflection type"},
}

labels["class 1 strong verbs"] = {
	description = "{{{langname}}} class 1 strong verbs, where the [[ablaut]] vowel was followed by ''-y-'' in Proto-Indo-European.",
	breadcrumb = "class 1",
	parents = {{name = "strong verbs", sort = "1"}},
}

labels["class 1 weak verbs"] = {
	description = "{{{langname}}} class 1 weak verbs, where the stem was followed by {{ic|/i/~/j/}} in Proto-Germanic (or {{ic|/ij/}} after a heavy stem, due to {{w|Sievers' Law}}).",
	additional = "This triggered [[umlaut]] in most daughter languages, as well as gemination of the final consonant in light stems in West Germanic.",
	breadcrumb = "class 1",
	parents = {{name = "weak verbs", sort = "1"}},
}

labels["class 1 weak j-present verbs"] = {
	description = "{{{langname}}} class 1 weak verbs with {{ic|/i/~/j/~/ij/}} in Proto-Germanic only in the present tense, but not elsewhere.",
	additional = "Most class 1 weak verbs had {{ic|/i/}} in the past tense and past participle, leading to " ..
		"[[umlaut]] throughout the verb in daughter languages with umlaut. A few archaic verbs, however, lacked " ..
		"this [[interfix]], with the [[dental]] consonant of the ending attached directly to the stem. Original " ..
		"instances of this are the reflexes of English [[seek]], [[think]], [[buy]] and [[work]], with apparently " ..
		"irregular pasts ''sought'', ''thought'', ''bought'' and archaic ''wrought'', and it was often extended " ..
		"to other verbs in various daughter languages (e.g. the [[Old English]] reflexes of [[sell]], [[tell]], " ..
		"[[teach]] and formerly [[reach]], with apparently irregular pasts ''sold'', ''told'', ''taught'' and " ..
		"now-obsolete ''raught''). The apparent reversal of umlaut in the past tense is sometimes called " ..
		"{{m|de|Rückumlaut|lit=backwards umlaut}} in Germanic studies.",
	breadcrumb = {"''j''-present", nocap = true},
	parents = {{name = "class 1 weak verbs", sort = "j-present"}},
}

labels["class 1 weak heavy-stem verbs"] = {
	description = "{{{langname}}} class 1 weak verbs with a heavy stem in Proto-Germanic, i.e. a stem containing a long vowel or ending in two consonants.",
	additional = "Such verbs had the {{w|Sievers' Law}} variant interfix {{ic|/ij/}} between the stem and endings " ..
		"in the present tense, which evolved differently from light-stem verbs in most daughter languages, which " ..
		"had an interfix {{ic|/i/~/j/}} in the present tense. Note that some verbs with multisyllabic stems were " ..
		"treated as heavy-stem and some as light-stem, depending on the analysis of the metrical feet of the stem.",
	breadcrumb_and_first_sort_key = "heavy-stem",
	parents = "class 1 weak verbs",
}

labels["class 1 weak light-stem verbs"] = {
	description = "{{{langname}}} class 1 weak verbs with a light stem in Proto-Germanic, i.e. a stem containing a short vowel and ending in only one consonant.",
	additional = "Such verbs had the {{w|Sievers' Law}} variant interfix {{ic|/i/~/j/}} between the stem and " ..
		"endings in the present tense, which evolved differently from heavy-stem verbs in most daughter languages, " ..
		"which had an interfix {{ic|/ij/}} in the present tense. Note that some verbs with multisyllabic stems were " ..
		"treated as heavy-stem and some as light-stem, depending on the analysis of the metrical feet of the stem.",
	breadcrumb_and_first_sort_key = "light-stem",
	parents = "class 1 weak verbs",
}

labels["class 2 strong verbs"] = {
	description = "{{{langname}}} class 2 strong verbs, where the [[ablaut]] vowel was followed by ''-w-'' in Proto-Indo-European.",
	breadcrumb = "class 2",
	parents = {{name = "strong verbs", sort = "2"}},
}

labels["class 2a strong verbs"] = {
	description = "{{{langname}}} class 2 strong verbs where the [[ablaut]] vowel was ''*eu'' in Proto-Germanic.",
	breadcrumb = "class 2a",
	parents = {{name = "class 2 strong verbs", sort = "1"}},
}

labels["class 2b strong verbs"] = {
	description = "{{{langname}}} class 2 strong verbs where the [[ablaut]] vowel was ''*ū'' in Proto-Germanic.",
	breadcrumb = "class 2b",
	parents = {{name = "class 2 strong verbs", sort = "2"}},
}

labels["class 2 weak verbs"] = {
	description = "{{{langname}}} class 2 weak verbs, where the stem was followed by ''*ō'' in Proto-Germanic.",
	breadcrumb = "class 2",
	parents = {{name = "weak verbs", sort = "2"}},
}

labels["class 3 weak verbs"] = {
	description = "{{{langname}}} class 3 weak verbs, where the stem was followed by ''*ai''~''*ā'' in Proto-Germanic, which was generalized to ''*ē'' in West Germanic.",
	breadcrumb = "class 3",
	parents = {{name = "weak verbs", sort = "3"}},
}

labels["class 3 strong verbs"] = {
	description = "{{{langname}}} class 3 strong verbs, where the [[ablaut]] vowel was followed by a [[consonant cluster]] in Proto-Indo-European.",
	breadcrumb = "class 3",
	parents = {{name = "strong verbs", sort = "3"}},
}

labels["class 3a strong verbs"] = {
	description = "{{{langname}}} class 3 strong verbs where the [[consonant cluster]] following the [[ablaut]] vowel begins with a nasal consonant.",
	breadcrumb = "class 3a",
	parents = {{name = "class 3 strong verbs", sort = "1"}},
}

labels["class 3b strong verbs"] = {
	description = "{{{langname}}} class 3 strong verbs where the [[consonant cluster]] following the [[ablaut]] vowel begins with a lateral consonant or velar fricative.",
	breadcrumb = "class 3b",
	parents = {{name = "class 3 strong verbs", sort = "2"}},
}

labels["class 3c strong verbs"] = {
	description = "{{{langname}}} class 3 strong verbs where the [[consonant cluster]] following the [[ablaut]] vowel begins with a rhotic consonant.",
	breadcrumb = "class 3c",
	parents = {{name = "class 3 strong verbs", sort = "3"}},
}

labels["class 4 strong verbs"] = {
	description = "{{{langname}}} class 4 strong verbs, where the [[ablaut]] vowel was followed by a [[sonorant]] (''m'', ''n'', ''l'', ''r'') but no other consonant in Proto-Indo-European.",
	breadcrumb = "class 4",
	parents = {{name = "strong verbs", sort = "4"}},
}

labels["class 4 weak verbs"] = {
	description = "{{{langname}}} class 4 weak verbs, where the stem was followed by ''*n'' in Proto-Germanic.",
	breadcrumb = "class 4",
	parents = {{name = "weak verbs", sort = "4"}},
}

labels["class 5 strong verbs"] = {
	description = "{{{langname}}} class 5 strong verbs, where the [[ablaut]] vowel was followed by [[consonant]] other than a [[sonorant]] in Proto-Indo-European.",
	breadcrumb = "class 5",
	parents = {{name = "strong verbs", sort = "5"}},
}

labels["class 5 strong j-present verbs"] = {
	description = "{{{langname}}} class 5 strong verbs with a {{IPAchar|/j/}} suffix in the present tense in Proto-Germanic.",
	additional = "This [[umlaut]]ed the root vowel to {{ic|/i/}}, and caused gemination of the stem-final consonant in the West Germanic languages. The {{ic|/j/}} was maintained in Gothic, Old Norse (and modern Icelandic) and Old Saxon, but otherwise dropped.",
	breadcrumb = {"''j''-present", nocap = true},
	parents = {{name = "class 5 strong verbs", sort = "j-present"}},
}

labels["class 6 strong verbs"] = {
	description = "{{{langname}}} class 6 strong verbs, with the stem vowel ''-a-'' (and usually a single stem-final consonant), except those where it is followed by a sonorant and another consonant (this combination was considered a diphthong in PIE and therefore belonged to class 7).",
	additional = "The Proto-Indo-European origin of this class is not securely known.",
	breadcrumb = "class 6",
	parents = {{name = "strong verbs", sort = "6"}},
}

labels["class 6 strong j-present verbs"] = {
	description = "{{{langname}}} class 6 strong verbs with a {{IPAchar|/j/}} suffix in the present tense in Proto-Germanic.",
	additional = "This caused gemination of the stem-final consonant in the West Germanic languages, and [[umlaut]] of the root vowel in most languages. The {{ic|/j/}} was maintained in Gothic, Old Norse (and modern Icelandic) and Old Saxon, but otherwise dropped.",
	breadcrumb = {"''j''-present", nocap = true},
	parents = {{name = "class 6 strong verbs", sort = "j-present"}},
}

labels["class 7 strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs, which retained their reduplication in the past tense in Proto-Germanic.",
	breadcrumb = "class 7",
	parents = {{name = "strong verbs", sort = "7"}},
}

labels["class 7a strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs where the root vowel was ''*ai'' in Proto-Germanic, analogous to class 1.",
	breadcrumb = "class 7a",
	parents = {{name = "class 7 strong verbs", sort = "a"}},
}

labels["class 7b strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs where the root vowel was ''*au'' in Proto-Germanic, analogous to class 2.",
	breadcrumb = "class 7b",
	parents = {{name = "class 7 strong verbs", sort = "b"}},
}

labels["class 7c strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs where the root vowel was ''*a'' followed by a [[consonant cluster]] in Proto-Germanic, analogous to class 3.",
	breadcrumb = "class 7c",
	parents = {{name = "class 7 strong verbs", sort = "c"}},
}

labels["class 7d strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs where the root vowel was ''*ē'' in Proto-Germanic.",
	breadcrumb = "class 7d",
	parents = {{name = "class 7 strong verbs", sort = "d"}},
}

labels["class 7e strong verbs"] = {
	description = "{{{langname}}} class 7 strong verbs where the root vowel was ''*ō'' in Proto-Germanic.",
	breadcrumb = "class 7e",
	parents = {{name = "class 7 strong verbs", sort = "e"}},
}

labels["class 7 strong j-present verbs"] = {
	description = "{{{langname}}} class 7 strong verbs with a {{IPAchar|/j/}} suffix in the present tense in Proto-Germanic.",
	additional = "This caused [[umlaut]] of the root vowel in most languages. The {{ic|/j/}} was maintained in Gothic, Old Norse (and modern Icelandic) and Old Saxon, but otherwise dropped.",
	breadcrumb = {"''j''-present", nocap = true},
	parents = {{name = "class 7 strong verbs", sort = "j-present"}},
}

------- GERMANIC NOUN CLASSES -------

local ine_pro_prec_footer = {
	["<a>-stem"] = "{PIE} thematic nouns in <*-os> (masculine), <*-om> (neuter), with genitive <*-osyo> and nominative plural <*-oes> (masculine), <*-eh₂> (neuter).",
	["<i>-stem"] = "{PIE} athematic proterokinetic nouns in <*-is>, with genitive <*-eys> and nominative plural <*-eyes>.",
	["<u>-stem"] = "{PIE} athematic proterokinetic nouns in <*-us> (masculine or feminine), <*-u> (neuter), with genitive <*-ews> and nominative plural <*-ewes> (masculine or feminine), <*-uh₂> (neuter), although the {PG} genitive continues a post-PIE form <*-ows>."

local all_lang_props = {
	i_umlaut_throughout = "These nouns have {i_umlaut} throughout the paradigm in most daughter languages.",
	["<ijō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>> with a {PG} stem suffix <*-ij->, which triggered {i_umlaut}.",
		footer = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with heavy stems ({heavy_stem_expl}), due to {sievers}; the corresponding light-stem nouns had a stem suffix <*-j->. See also the related <<c:<ī>/<jō>-stem nouns|<ī>/<jō>-stem>> class of nouns.",
	},
	["<ī>/<jō>-stem"] = {
		daughter_desc = "<<c:<ī>/<jō>-stem nouns>>, ending in {PG} <*-ī> in the nominative/vocative singular but otherwise having <ō>-stem endings with a {PG} stem suffix <*-ij->.",
		footer = "These nouns have {i_umlaut} in the ",
	},
	["<wō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>> with a {PG} stem suffix <*-w->.",
		footer = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes.",
	},
	["<i>-stem"] = {
		daughter_desc = "<<c:<i>-stem nouns>>, ending in {PG} <*-iz> (masculine or feminine), <*-i> (neuter).",
		footer = "<i>-stem neuters were rare in {PG} and disappeared in most daughter languages).",
	},
	["<u>-stem"] = {
		daughter_desc = "<<c:<u>-stem nouns>>, ending in {PG} <*-uz> (masculine or feminine), <*-u> (neuter).",
		footer = "<u>-stem neuters were rare in {PG} but survived in many daughter languages, particularly reflexes of {{m+|gem-pro|*fehu||livestock, cattle, property, wealth}}).",
	},
	["<an>-stem"] = {
		daughter_desc = "<<c:<an>-stem nouns>>, which were masculine or neuter in {PG} and ended in overlong <*-ô>, with an <*-n-> formant throughout the oblique and plural forms.",
		footer = "This class, along with the corresponding feminine <ōn>-stem nouns, was continued in all daughter languages, where it is the origin of so-called \"weak\" nouns. The <*-n-> format disappears in North Germanic due to loss of word-final <*-n>, but is maintained in most West Germanic languages.",
	},
	["<ōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>>, which were feminine in {PG} and ended in <*-ǭ>, with an <*-ōn-> formant throughout the oblique and plural forms.",
		footer = "This class, along with the corresponding masculine and neuter <ōn>-stem nouns, was continued in all daughter languages, where it is the origin of so-called \"weak\" nouns. The <*-n-> format disappears in North Germanic due to loss of word-final <*-n>, but is maintained in most West Germanic languages.",
	},
	["<jōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>> with a {PG} stem suffix <*-j->.",
		footer = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with light stems (, due to {sievers}; the corresponding heavy-stem nouns had a stem suffix <*-ij->.",
	},
	["<ijōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>> with a {PG} stem suffix <*-ij->.",
		footer = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with heavy stems ({heavy_stem_expl}), due to {sievers}; the corresponding light-stem nouns had a stem suffix <*-j->.",
	},
	["<īn>-stem"] = {
		daughter_desc = "<<c:<īn>-stem nouns>>, a class of feminine abstract nouns ending in <*-į̄> in {PG}, with an <*-īn> formant throughout the oblique and plural forms.",
		footer = "In most daughter languages, the oblique forms all merged to have the same ending, in many cases borrowing the ending of the nominative and in the process becoming indeclinable. {OE} replaced the original <-i> ending with the <-u> ending of <ō>-stems, but the original ending left its mark in {i_umlaut} in all forms.",
	},
	["<z>-stem"] = {
		daughter_desc = "<<c:<z>-stem nouns>>, neuter in {PG} and ending in <*-az> with genitive <*-iziz> and nominative/accusative plural <*-izō>.",
		footer = "This class was numerous in {PG} but become rare in daughter languages due to the effects of {i_umlaut}, which operated in cases with the <*-iz-> formant, i.e. the oblique singular and throughout the plural but not in the nominative or accusative singular. Usually, either the umlauted or non-umlauted stem was generalized throughout the paradigm and the noun moved to another declension, although which stem was generalized, which declension the noun ended up in, and whether the <*-z-> formant (which developed into an {{ic|/r/}} in North and West Germanic) was incorporated into the stem varied from language to language, often resulting in doublets within a single language. This class survived as a relic class in the West Germanic languages (ironically becoming productive again in modern German as a common way of forming neuter plurals). This class should not be confused with <<c:<r>-stem nouns|<r>-stem nouns>>, which are masculine or feminine and predominantly kinship terms.",
	},
	["<r>-stem"] = {
		daughter_desc = "<<c:<r>-stem nouns>>, ending in <*-ēr>.",
		footer = "This was a small class of common kinship nouns in {PG} and was continued in most daughter languages, but the nouns often developed irregularities which differed from noun to noun. This class should not be confused with neuter <<c:<z>-stem nouns|<z>-stem nouns>>, which also contained an {{ic|/r/}} stem formant in North and West Germanic and was also a relic class.",
	},
}


--[=[
Noun declension specifications. The keys are language codes and the values are tables where each key is an inflection
class label and the values are in the format described in [[Module:category tree/utilities]].
]=]
local noun_decls = {
	vars = {
		----------------- settings across stems -----------------

		-- Wikipedia links --
		PIE = "{{w|Proto-Indo-European}}",
		PG = "{{w|Proto-Germanic}}",
		PWG = "{{w|Proto-West Germanic}}",
		OHG = "{{w|Old High German}}",
		OE = "{{w|Old English}}",
		ON = "{{w|Old Norse}}",
		OS = "{{w|Old Saxon}}",
		OD = "{{w|Old Dutch}}",
		OF = "{{w|Old Frisian}}",
		WGG = "{{w|West Germanic gemination}}",
		PAL = "{{w|Phonological_history_of_Old_English#Palatalization|palatalization}}",
		sievers = "{{w|Sievers' law}}",
		verner = "{{w|Verner's law}}",

		-- misc --
		depending = "(depending on the reconstruction, the particular word and/or the dialect)",
		originates_from = "This class originates from {from}. It evolves as follows:",
		light_stem_expl = "containing a short vowel followed by a single consonant",
		heavy_stem_expl = "containing a long vowel or diphthong, or a short vowel followed by a two or more consonants",
		y_stem_suffix = "a stem suffix <*-y-> or <*-ey->",
		iy_stem_suffix = "a stem suffix <*-i(y)-> or <*-ey->",
		see_ija_stem_xref = " (see <<c:<ija>-stem nouns>>)",
		see_ja_stem_xref = " (see <<c:<ja>-stem nouns>>)",
		see_ijo_stem_xref = " (see <<c:<ijō>-stem nouns>>)",
		see_jo_stem_xref = " (see <<c:<jō>-stem nouns>>)",
		-- j_stem_sievers_law = "Due to {sievers}, <*-j-> only occurs after light stems ({light_stem_expl}); otherwise the stem suffix appears as <*-ij->",
		j_stem_sievers_law = "Since all nouns in this class originally had a light stem ({light_stem_expl}), {PIE} <*-y-> and <*-ey-> were continued as {PG} <*-j-> due to {sievers}; heavy-stem nouns would have <*-ij-> instead",
		-- ij_stem_sievers_law = "Due to {sievers}, <*-ij-> only occurs after heavy stems ({heavy_stem_expl}); otherwise the stem suffix appears as <*-j->",
		ij_stem_sievers_law = "Since all nouns in this class originally had a heavy stem ({heavy_stem_expl}), {PIE} <*-(i)y-> and <*-ey-> were continued as {PG} <*-ij-> due to {sievers}; light-stem nouns would have <*-j-> instead",
		ja_ija_stem_divergence = "In {PG}, the endings were nearly the same as for plain <a>-stem nouns, but the two classes diverged in most daughter languages.",

		----------------- a-stem settings -----------------

		-- PIE a-stem endings --
		base_pie_a_stem = "{PIE} {stem_weight}thematic nouns in <*-os> (masculine), <*-om> (neuter){genitive_cont}{stem_suffix}",
		masculine_base_pie_a_stem = "{PIE} {stem_weight}masculine thematic nouns in <*-os>{genitive_cont}{stem_suffix}",
		neuter_base_pie_a_stem = "{PIE} {stem_weight}neuter thematic nouns in <*-om>{genitive_cont}{stem_suffix}",
		pie_a_stem_genitive_cont = "genitive <*-osyo> and nominative plural <*-oes> (masculine), <*-eh₂> (neuter; later <*-ā>)",
		masculine_pie_a_stem_genitive_cont = "genitive <*-osyo> and nominative plural <*-oes>",
		neuter_pie_a_stem_genitive_cont = "genitive <*-osyo> and nominative/accusative plural <*-eh₂> (later <*-ā>)",
		pie_a_stem = "{GENDER_base_pie_a_stem<genitive_cont:, with {GENDER_pie_a_stem_genitive_cont}>}",
		pie_plain_a_stem = "{pie_a_stem<stem_weight:><stem_suffix:>}>}",
		pie_ja_stem = "{pie_a_stem<stem_weight:light-stem ><stem_suffix:, with {y_stem_suffix}>}",
		pie_ija_stem = "{pie_a_stem<stem_weight:heavy-stem ><stem_suffix:, with {iy_stem_suffix}>}",
		pie_wa_stem = "{pie_a_stem<stem_weight:><stem_suffix:, with a stem ending in <*-w->>}",

		-- PIE a-stem to Proto-Germanic --
		pie_gen_a_stem_to_gem = "Genitive <*-osyo> becomes <*-as> (North and West Germanic), <*-is> (East Germanic) in a way not fully explained.",
		pie_masc_pl_a_stem_to_gem = "Masculine nominative plural <*-oes> regularly becomes overlong <*-ôs> or <*-ôz> (with variation due to {verner}).",
		pie_neut_pl_a_stem_to_gem = "Neuter nominative/accusative plural <*-ā> regularly becomes <*-ō>.",
		pie_a_stem_to_gem = "{PIE} nominative masculine <*-os>, neuter <*-om> regularly becomes {PG} <*-az> and <*-ą>. {pie_gen_a_stem_to_gem} {pie_masc_pl_a_stem_to_gem} {pie_neut_pl_a_stem_to_gem}",
		masculine_pie_a_stem_to_gem = "{PIE} nominative masculine <*-os> regularly becomes {PG} <*-az>. {pie_gen_a_stem_to_gem} {pie_masc_pl_a_stem_to_gem}",
		neuter_pie_a_stem_to_gem = "{PIE} nominative/accusative neuter <*-om> regularly becomes {PG} <*-ą>. {pie_gen_a_stem_to_gem} {pie_neut_pl_a_stem_to_gem}",

		-- Proto-Germanic a-stem to Proto-West Germanic --
		gem_masc_pl_a_stem_to_gmw = "Overlong masculine plural <*-ôs> or <*-ôz> became West Germanic <*-ōs> or <*-ōz>, with both alternants persisting.",
		gem_neut_pl_a_stem_to_gmw = "Neuter plural <*-ō> was raised and shortened to <*-u>. (This is common to North and West Germanic and is also observed in the nominative singular of <ō>-stems.)",
		gem_a_stem_to_gmw = "{PG} final <*-z> was lost in West Germanic (except in monosyllables in {OHG}), followed by loss of final <*-a> and <*-ą>. {gem_masc_pl_a_stem_to_gmw} {gem_neut_pl_a_stem_to_gmw}",
		masculine_gem_a_stem_to_gmw = "{PG} final <*-z> was lost in West Germanic (except in monosyllables in {OHG}), followed by loss of final <*-a>. {gem_masc_pl_a_stem_to_gmw}",
		neuter_gem_a_stem_to_gmw = "{PG} final <*-ą> was lost in the nominative/accusative singular. {gem_neut_pl_a_stem_to_gmw}",

		----------------- ō-stem settings -----------------

		-- PIE ō-stem endings --
		pie_o_stem = "{PIE} {stem_weight}thematic feminine nouns in <*-eh₂> (later <*-ā>){stem_suffix}",
		pie_plain_o_stem = "{pie_o_stem<stem_weight:><stem_suffix:>}>}",
		pie_jo_stem = "{pie_o_stem<stem_weight:light-stem ><stem_suffix:, with {y_stem_suffix}>}",
		pie_ijo_stem = "{pie_o_stem<stem_weight:heavy-stem ><stem_suffix:, with {iy_stem_suffix}>}",
		pie_wo_stem = "{pie_o_stem<stem_weight:><stem_suffix:, with a stem ending in <*-w->>}",

		-- PIE ō-stem to Proto-Germanic --
		pie_o_stem_to_gem = "Late {PIE} nominative <*-ā> regularly becomes {PG} <*-ō>. {PIE} genitive <*-eh₂s> (later <*-ās>) regularly becomes <*-ōz>. Nominative plural <*-eh₂es> regularly becomes overlong <*-ôz>.",

		-- Proto-Germanic ō-stem to Proto-West Germanic --
		gem_o_stem_to_gmw = "{PG} nominative <*-ō> was raised and shortened to {PWG} <*-u> (the same development happened in the neuter plural of <a>-stems). Subsequently, final <*-z> was lost in West Germanic, with newly final <*-ō> in the genitive lowering to <*-ā> and overlong <*-ô> in the nominative plural shortened to <*-ō>.",

		----------------- ī/jō-stem settings -----------------

		pie_i_jo_stem = "{PIE} feminine nouns in ablauting <*-ih₂>/<*-yéh₂-> (later <*-ī>/<*-yā́->)",
		pie_i_jo_stem_to_gem = "Late {PIE} nominative <*-ī> remains as {PG} <*-ī>. {PIE} genitive <*-yéh₂s> (later <*-yā́s>) regularly becomes light-stem <*-jōz>, heavy-stem <*-ijōz> due to {sievers}. Nominative plural <*-ih₂es> was replaced analogically with the <(i)jō>-stem ending, becoming overlong light-stem <*-jôz>, heavy-stem <*-ijôz>.",
		gem_i_jo_stem_to_gmw = "{PG} nominative <*-ī> regularly shortens to <*-i>. Final <*-z> was lost in West Germanic, with newly final <*-(i)jō> in the genitive lowering to <*-(i)jā> and overlong <*-(i)jô> in the nominative plural shortened to <*-(i)jō>. {sievers} distinctions remain as-is except that {WGG} applies to light stems.",

		----------------- i-stem, u-stem settings -----------------
		pie_i_stem = "{PIE} athematic nouns in <*-is>",
		pie_i_stem_to_gem = "{PIE} nominative <*-is> is continued as {PG} <*-iz>. {PIE} genitive <*-éys> is continued as {PG} <*-īz> (with expected <*-s> replaced analogically by <*-z>, which is more common in endings), although Gothic and {ON} subsequently replaced this with <*-aiz>. (An alternative view has this occurring already in {PG}, with West Germanic genitives that apparently continue <*-īz> being secondary developments.) {PIE} nominative plural <*-eyes> is regularly continued as <*-īz>.",
		gothic_on_i_stem_gen_replacement = "Gothic and {ON} subsequently replaced the inherited {PG} genitive <*-eiz> with <*-aiz>, by analogy with <u>-stem genitive <*-auz>. An alternative view has this occurring already in {PG}, with West Germanic genitives that apparently continue <*-īz> being secondary developments.",
		gem_i_stem_to_gmw = "{PG} nominative <*-iz>, genitive <*-īz> and nominative plural <*-īz> were all directly continued as {PWG} <*-i>, <*-ī> and <*-ī>, with regular loss of final <*-z>.",
		pie_u_stem = "{PIE} athematic nouns in <*-us>",
		pie_u_stem_to_gem_gen = "{PIE} genitive <*-éws> was replaced with <*-óws>, which is continued as {PG} <*-auz> (with expected <*-s> replaced analogically by <*-z>, which is more common in endings).",
		pie_u_stem_to_gem = "{PIE} nominative <*-us> is continued as {PG} <*-uz>. {pie_u_stem_to_gem_gen} {PIE} nominative plural <*-ewes> is regularly continued as <*-iwiz>.",
		gem_u_stem_to_gmw = "{PG} nominative <*-uz> was regularly continued as {PWG} <*-u>, with regular loss of final <*-z>. Genitive <*-auz> similarly lost <*-z>, and unstressed <*-au-> was monophthongized to {PWG} <*-ō>. The outcome of {PG} nominative plural <*-iwiz> is less clear, since {OHG}, {OS} and {OD} have <i>-stem endings in the plural of inherited <u>-stem nouns while {OE} and {OF} have <-a>, which cannot be derived from <*-iwiz>. Ringe and Taylor (2014) suggest that <*-iwiz> was replaced by <*-awiz> (and dative <*-iwi> by <*-awi>) in early northern {PWG} by analogy with the genitive singular <*-auz>, which at this stage could be analyzed as <*-aw-z>. This <*-awiz> would then develop to northern {PWG} <*-ō>, while southern {PWG} kept inherited <*-iwi>.",
	},
	["default"] = {
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			desc = "ending in {PG} <*-az> (masculine), <*-ą> (neuter)",
			masculine_desc = "ending in {PG} <*-az>",
			neuter_desc = "ending in {PG} <*-ą>",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			desc = "ending in {PG} <*-jaz> (masculine), <*-ją> (neuter)",
			masculine_desc = "ending in {PG} <*-jaz>",
			neuter_desc = "ending in {PG} <*-ją>",
			parent = "<a>-stem",
		},
		["GENDER <ija>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			desc = "ending in {PG} <*-ijaz> (masculine), <*-iją> (neuter)",
			masculine_desc = "ending in {PG} <*-ijaz>",
			neuter_desc = "ending in {PG} <*-iją>",
			parent = "<a>-stem",
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			desc = "ending in {PG} <*-waz> (masculine), <*-wą> (neuter)",
			masculine_desc = "ending in {PG} <*-waz>",
			neuter_desc = "ending in {PG} <*-wą>",
			parent = "<a>-stem",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			desc = "ending in {PG} <*-ō> and always feminine",
		},
		["<jō>-stem"] = {
			gender = "feminine",
			desc = "ending in {PG} <*-jō> and always feminine",
			parent = "<o>-stem",
		},
		["<ijō>-stem"] = {
			gender = "feminine",
			desc = "ending in {PG} <*-ijō> and always feminine",
			parent = "<o>-stem",
		},
		["<ī>/<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ī>",
			gen_sg = "<*-ijōz>",
			nom_pl = "<*-ijôz>",
			parent = "<ō>-stem",
		},
		["GENDER <i>-stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_nom_sg"] = "<*-iz>",
			neuter_nom_sg = "<*-i>",
			gen_sg = "<*-īz>",
			["masculine or feminine_nom_pl"] = "<*-īz>",
			neuter_nom_pl = "<*-ī>",
		},
		["GENDER <u>-stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_nom_sg"] = "<*-uz>",
			neuter_nom_sg = "<*-u>",
			gen_sg = "<*-auz>",
			["masculine or feminine_nom_pl"] = "<*-iwiz>",
			neuter_nom_pl = "<*-ū>",
		},
		["GENDER <an>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<*-ô>",
			gen_sg = "<*-iniz>",
			masculine_nom_pl = "<*-aniz>",
			neuter_nom_pl = "<*-ōnō>",
			parent = "n-stem",
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-į̄>",
			gen_sg = "<*-īniz>",
			nom_pl = "<*-īniz>",
			parent = "n-stem",
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ǭ>",
			gen_sg = "<*-ōniz>",
			nom_pl = "<*-ōniz>",
			parent = "n-stem",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<*-ēr>",
			gen_sg = "<*-urz>",
			nom_pl = "<*-riz>",
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "<*-az>",
			gen_sg = "<*-iziz>",
			nom_pl = "<*-izō>",
		},
		["consonant stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_nom_sg"] = "<*-z> (after a voiced consonant) or <*-s> (after a voiceless consonant)",
			neuter_nom_sg = "no ending (with loss of <*-þ>)",
			["masculine or feminine_nom_pl"] = "<*-iz>",
			neuter_nom_pl = "no ending",
		},
	},
	["gem-pro"] = {
		vars = {
			masc_pl_gem_a_stem_cont = "\n# One or the other masculine nominative plural ending was generalized in daughter languages. The <*-ôs> form prevailed in {OE}, becoming <-as> (similarly in other northern West Germanic languages), but the <*-ôz> form prevailed in {OHG} (becoming <-ā>) and {ON} (becoming <-ar>). The Gothic ending <-ōs> could derive from either.",
			neuter_masc_pl_gem_a_stem_cont = "",
			-- masculine_masc_pl_gem_a_stem_cont inherits from masc_pl_gem_a_stem_cont

			neut_pl_gem_a_stem_cont_init = "\n# The neuter plural ending <*-ō> was shortened and raised to <*-u> in North Germanic and West Germanic, but shortened and lowered to <-a> in Gothic.",
			neut_pl_gem_a_stem_cont = "{neut_pl_gem_a_stem_cont_init} North Germanic <*-u> triggered {u_umlaut} before being lost, while in West Germanic, <*-u> survived in light stems ({light_stem_expl}) in {OE}, {OS} and {OF} (surfacing as <-u> in the former two and <-e> in the latter), but was otherwise lost.",
			masculine_neut_pl_gem_a_stem_cont = "",
			-- neuter_neut_pl_gem_a_stem_cont inherits from neut_pl_gem_a_stem_cont
			neut_pl_gem_ja_stem_cont = "{neut_pl_gem_a_stem_cont_init} North Germanic <*-u> would normally trigger {u_umlaut} before being lost, but this was blocked by the preceding <*-j->. In West Germanic, <*-u> sometimes survived, sometimes not, depending on various factors e.g. the individual language and the weight of the preceding syllable.",
			masculine_neut_pl_gem_ja_stem_cont = "",
			-- neuter_neut_pl_gem_ja_stem_cont inherits from neut_pl_gem_ja_stem_cont
		},
		["GENDER <a>-stem"] = {
			desc = "",
			header = [==[
{originates_from<from:{pie_plain_a_stem}>}
# {GENDER_pie_a_stem_to_gem}{GENDER_masc_pl_gem_a_stem_cont}{GENDER_neut_pl_gem_a_stem_cont}
]==],
			masculine_nom_sg = "<*-az>",
			neuter_nom_sg = "<*-ą>",
			gen_sg = "<*-as> or <*-is> {depending}",
			masculine_nom_pl = "<*-ôz> or <*-ôs> {depending}",
			neuter_nom_pl = "<*-ō>",
			masculine_examples = [==[
# <<*kuningaz||king>>
# <<*dagaz||day>>
# <<*haimaz||home>>
# <<*wulfaz||wolf>>
# <<*hringaz||ring; curve>>
# <<*aiwaz||eternity; law>> (a <wa>-stem)
# <<*ansaz||beam>> (per Ringe, has {verner} alternant <<|*ansôz>> in plural)
]==],
			neuter_examples = [==[
# <<*rūmą||room, space>>
# <<*deuzą||wild animal, beast>>
# <<*blōþą||blood>> (plural has {verner} alternant <<|*blōdō>>)
# <<*tahrą||tear (of the eye)>> (plural has {verner} alternant <<|*tagrō>>)
# <<*glasą||glass>> (plural has {verner} alternant <<|*glazō>>)
# <<*hwehwlą||wheel>> (plural has {verner} alternant <<|*hweulō>>; reconstructed as masculine by Ringe)
]==],
		},
		["GENDER <ja>-stem"] = {
			desc = "",
			header = [==[
{originates_from<from:{pie_ja_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {j_stem_sievers_law} {see_ija_stem_xref}. {ja_ija_stem_divergence}{GENDER_masc_pl_gem_ja_stem_cont}{GENDER_neut_pl_gem_ja_stem_cont}
# The stem suffix <*-j-> triggered {i_umlaut} in North and West Germanic; {WGG} in West Germanic; and {PAL} of preceding velars in {OE} and {OF}.
]==],
			masculine_nom_sg = "<*-jaz>",
			neuter_nom_sg = "<*-ją>",
			gen_sg = "<*-jas> or <*-is> {depending}",
			masculine_nom_pl = "<*-jôz> or <*-jôs> {depending}",
			neuter_nom_pl = "<*-jō>",
			masculine_examples = [==[
# <<*harjaz||army>>
# <<*sagjaz||retainer; warrior>>
# <<*niþjaz||relative, kinsman>>
]==],
			neuter_examples = [==[
# <<*kunją||kin>>
# <<*fergunją||mountain>>
# <<*ajją||egg>>
# <<*badją||bed>>
]==],
		},
		["GENDER <ija>-stem"] = {
			header = [==[
{originates_from<from:{pie_ija_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {ij_stem_sievers_law} {see_ja_stem_xref}. {ja_ija_stem_divergence}{GENDER_masc_pl_gem_ja_stem_cont}{GENDER_neut_pl_gem_ja_stem_cont}
# The stem suffix <*-ij-> triggered {i_umlaut} in North and West Germanic, and {PAL} of preceding velars in {OE} and {OF}.
]==],
			masculine_nom_sg = "<*-ijaz>",
			neuter_nom_sg = "<*-iją>",
			gen_sg = "<*-ijas> or <*-īs> {depending}",
			masculine_nom_pl = "<*-ijôz> or <*-ijôs> {depending}",
			neuter_nom_pl = "<*-ijō>",
			masculine_examples = [==[
# <<*andijaz||end>>
# <<*hwaitijaz||wheat>>
# <<*mēkijaz||sword>>
# <<*hirdijaz||herder, herdsman>>
# <<*lēkijaz||doctor>>
]==],
			neuter_examples = [==[
# <<*rīkiją||government; kingdom>>
# <<*ambahtiją||service; message>>
# <<*haftiją||handle>>
# <<*þiubiją||theft>>
# <<*andawurdiją||answer>>
]==],
		},
		["<ō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# The nominative singular <*-ō> ending was shortened and raised to <*-u> in North Germanic and West Germanic, but shortened and lowered to <-a> in Gothic. The <*-u> in North Germanic triggered {u_umlaut} (unless blocked by a preceding <*-j->), and was then lost. In West Germanic, <*-u> survived in some words in {OE} (generally if following a light syllable, i.e. {light_stem_expl}), but in other languages was analogically replaced by the accusative singular.
]==],
			nom_sg = "<*-ō>",
			gen_sg = "<*-ōz>",
			nom_pl = "<*-ôz>",
			examples = [==[
# <<*gebō||gift>>
# <<*þeudō||people, tribe>>
# <<*erþō||earth>>
# <<*saiwalō||soul>>
# <<*sibjō||kinship; friendship>> (a <jō>-stem)
# <<*agjō||edge>> (a <jō>-stem)
# <<*badwō||battle>> (a <wō>-stem)
# <<*arhwō||arrow>> (a <wō>-stem)
# <<*nēþlō||needle>> (part of the inflection had a {verner} alternant form <<|*nēdl->>, but it's not clear which part)
]==],
		},
		["<ī>/<jō>-stem"] = {
			header = [==[
{originates_from<from:{pie_i_jo_stem}>}
# {pie_i_jo_stem_to_gem}
# The class survived into West Germanic, mostly later merging with <*(i)jō>-stems but with remnants still distinguishable in the literary languages, particularly for those nouns ending in <*-inī>. In North Germanic, the class merged into <ijō>-stems, whose nominative (unusually for feminines) ends in <-r>.
]==],
			gender = "feminine",
			nom_sg = "<*-ī>",
			gen_sg = "<*-ijōz>",
			nom_pl = "<*-ijôz>",
			parent = "<ō>-stem",
			examples = [==[
# <<*haiþī||heath>>
# <<*gudinī||goddess>>
# <<*akwisī||axe>> (with root ablaut, e.g. genitive <<|*akuzijōz>>) 
# <<*þiwī||handmaid, female servant>>
]==],
		},
		["GENDER <i>-stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_header"] = [==[
{originates_from<from:{pie_i_stem}>}
# {pie_i_stem_to_gem}
# {gothic_on_i_stem_gen_replacement}
]==],
			neuter_header = [==[
This class originates from {PIE} athematic neuter <i>-stems in <*-i>. There were very few such nouns in {PG} and none survived as neuters in any daughter, so the {PG} reconstruction is speculative. It evolves as follows:
# Nominative/accusative {PIE} singular <*-i> is continued unchanged.
# Genitive <*-éys> is assumed to have been regularly inherited as <*-īz>. As with masculines and feminines, {gothic_on_i_stem_gen_replacement}
# No distinct neuter nominative/accusative plural <i>-stem forms are attested in any daughter, so putative <*-ī>, the regularly expected outcome of {PIE} <*-ih₂>, is purely a guess.
]==],
			["masculine or feminine_nom_sg"] = "<*-iz>",
			neuter_nom_sg = "<*-i>",
			gen_sg = "<*-īz>",
			["masculine or feminine_nom_pl"] = "<*-īz>",
			neuter_nom_pl = "<*-ī>",
			["masculine or feminine_examples"] = [==[
# <<*gastiz||stranger, guest|g=m>>
# <<*kuniz||family, kin; descendant|g=m>>
# <<*saliz||dwelling; hall|g=m>>
# <<*winiz||friend, loved one|g=m>>
# <<*slagiz||blow, strike|g=m>>
# <<*saiwiz||sea|g=m>>
# <<*kwēniz||wife|g=f>>
# <<*awiz||ewe; sheep|g=f>>
# <<*gunþiz||battle|g=f>>
# <<*gaburþiz||birth|g=f>> (oblique has {verner} alternant stem, e.g. genitive <<|*gaburdīz>>)
]==],
			neuter_examples = [==[
# <<*mari||sea>> (the only securely reconstructible example)
]==],
		},
		["GENDER <u>-stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_header"] = [==[
{originates_from<from:{pie_u_stem}>}
# {pie_u_stem_to_gem}
# {PG} Nominative plural <*-iwiz> is replaced with something like <*-awiz> in the pre-history of {OE} and {OF}, leading to attested <-a> in both languages, possibly (per Ringe and Taylor 2014) by analogy with the genitive singular. The same replacement occurs in the dative singular.
]==],
			neuter_header = [==[
This class originates from {PIE} athematic neuter <u>-stems in <*-u>. There were very few such nouns in {PG}, so the {PG} reconstruction is somewhat speculative. It evolves as follows:
# Nominative/accusative {PIE} singular <*-u> is continued unchanged.
# {pie_u_stem_to_gem_gen}
# No distinct neuter nominative/accusative plural <u>-stem forms are attested in any daughter, so putative <*-ū>, the regularly expected outcome of {PIE} <*-uh₂>, is purely a guess.
]==],
			["masculine or feminine_nom_sg"] = "<*-uz>",
			neuter_nom_sg = "<*-u>",
			gen_sg = "<*-auz>",
			["masculine or feminine_nom_pl"] = "<*-iwiz>",
			neuter_nom_pl = "<*-ū>",
			["masculine or feminine_examples"] = [==[
# <<*sunuz||son|g=m>>
# <<*dauþuz||death|g=m>>
# <<*maguz||boy|g=m>>
# <<*skaduz||shadow|g=m>>
# <<*handuz||hand|g=f>>
# <<*kinnuz||cheek; chin|g=f>>
]==],
			neuter_examples = [==[
# <<*fehu||cattle, property>> (the only completely securely reconstructible example)
# <<*līþu||cider; liquor>> (likely; neuter but not <u>-stem in North Germanic and West Germanic, <u>-stem but of unclear gender in Gothic)
# <<*medu||mead>> (possibly; masculine in North Germanic and West Germanic, unattested in Gothic, but a neuter <u>-stem in Greek and Sanskrit)
]==],
		},
		["GENDER <an>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<*-ô>",
			gen_sg = "<*-iniz>",
			masculine_nom_pl = "<*-aniz>",
			neuter_nom_pl = "<*-ōnō>",
			parent = "n-stem",
			masculine_examples = [==[
# <<*gumô||man>>
# <<*mēnô||moon>>
# <<*hanô||rooster>>
# <<*bugô||bow (weapon)>>
# <<*blōmô||flower>>
# <<*angô||hook; spear; arrow>>
# <<*frawjô||lord>> (a <jan>-stem)
# <<*arbijô||heir>> (an <ijan>-stem)
# <<*sparwô||sparrow>> (a <wan>-stem)
# <<*uhsô||ox>> (with zero-grade <<|*uhsn->> in the oblique singular and throughout the plural)
# <<*hasô||hare, rabbit>> (part of the inflection had a {verner} alternant form <<|*haz->>, but it's not clear which part)
]==],
			neuter_examples = [==[
# <<*augô||eye>>
# <<*hertô||heart>>
# <<*wangô||cheek>>
# <<*ausô||ear>> (part of the inflection had a {verner} alternant form <<|*auz->>, but it's not clear which part)
# <<*namô||name>> (with zero-grade <<|*namn->> in the oblique singular and throughout the plural)
# <<*sēmô||seed>> (with zero-grade <<|*sēmn->> in the oblique singular and throughout the plural)
]==],
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-į̄>",
			gen_sg = "<*-īniz>",
			nom_pl = "<*-īniz>",
			parent = "n-stem",
			examples = [==[
# <<*langį̄||length>>
# <<*hauhį̄||height>>
# <<*burþį̄||burden>>
# <<*managį̄||multitude, variety>>
# <<*aiþį̄||mother>>
]==],
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ǭ>",
			gen_sg = "<*-ōniz>",
			nom_pl = "<*-ōniz>",
			parent = "n-stem",
			examples = [==[
# <<*augô||eye>>
# <<*hertô||heart>>
# <<*wangô||cheek>>
# <<*ausô||ear>> (part of the inflection had a {verner} alternant form <<|*auz->>, but it's not clear which part)
# <<*namô||name>> (with zero-grade <<|*namn->> in the oblique singular and throughout the plural)
# <<*sēmô||seed>> (with zero-grade <<|*sēmn->> in the oblique singular and throughout the plural)
]==],
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<*-ēr>",
			gen_sg = "<*-urz>",
			nom_pl = "<*-riz>",
			examples = [==[
# <<*fadēr||father|g=m>>
# <<*brōþēr||brother|g=m>>
# <<*þeuhtēr||grandson, descendant|g=m>> (only survives in {OHG})
# <<*mōdēr||mother|g=f>>
# <<*swestēr||sister|g=f>>
# <<*duhtēr||daughter|g=f>>
]==],
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "<*-az>",
			gen_sg = "<*-iziz>",
			nom_pl = "<*-izō>",
			examples = [==[
# <<*agaz||fear>>
# <<*ahaz||ear (of grain)>>
# <<*aiz||bronze>>
# <<*lambaz||lamb>>
# <<*rekwaz||darkness>>
# <<*segaz||victory>>
]==],
		},
		["consonant stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_nom_sg"] = "<*-z> (after a voiced consonant) or <*-s> (after a voiceless consonant)",
			neuter_nom_sg = "no ending (with loss of <*-þ>)",
			["masculine or feminine_nom_pl"] = "<*-iz>",
			neuter_nom_pl = "no ending",
			["masculine or feminine_examples"] = [==[
# <<*fōts||foot|g=m>>
# <<*frijōndz||friend|g=m>>
# <<*tanþs||tooth|g=m>> (with both root ablaut and {verner} variation in genitive/dative/instrumental stem <<|*tund->>)
# <<*ēbanþs||evening|g=m>> (with both root ablaut and {verner} variation in genitive/dative/instrumental stem <<|*ēbund->>)
# <<*mann-||man|g=m>> (nominative singular unclear)
# <<*arô||eagle|g=m>> (stem <<|*arn->> outside the nominative and vocative singular)
# <<*gaits||goat|g=f>>
# <<*mūs||mouse|g=f>>
# <<*nahts||night|g=f>>
# <<*burgz||fortification; city|g=f>>
# <<*meluks||milk|g=f>>
# <<*sūz||sow|g=f>> (with variant <<|*suw->> before high vowels, <<|*sū->> before mid vowels)
# <<*kōz||sow|g=f>> (with variant <<|*kū->> in the genitive, dative and instrumental)
# <<*wrōts||root|g=f>> (with root ablaut variant <<|*wurt->> in the genitive, dative and instrumental)
# <<*alu||ale|g=n>> (variant <<|*aluþ->> in the oblique singular and throughout the plural)
# <<*mili||honey|g=n>> (variant <<|*milid->> in the oblique; no plural)
]==],
		},
	},
	["gmw-pro"] = {
		vars = {
			----------------- settings across stems -----------------
			i_umlaut_palatalization = "{i_umlaut} (to varying degrees) in all daughter languages, and {PAL} in Old English and Old Frisian",

			----------------- <a>-stem settings -----------------
			gmw_post_proto_a_loss_neuter_denasal = "Final neuter <-ą> merged into <-a> before disappearing entirely.",
			gmw_post_proto_a_loss_areal = "There is evidence that loss of final <-a> was an areal change that happened post-{PWG}; hence the two reconstructions in the nominative singular.",
			gmw_post_proto_a_loss = "{gmw_post_proto_a_loss_neuter_denasal} {gmw_post_proto_a_loss_areal}",
			masculine_gmw_post_proto_a_loss = "{gmw_post_proto_a_loss_areal}",
			-- neuter_gmw_post_proto_a_loss inherits from gmw_post_proto_a_loss
		},
		["GENDER <a>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_a_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw}
# {GENDER_gmw_post_proto_a_loss}
]==],
			nom_sg = "<*-a>, becoming a null ending",
			gen_sg = "<*-as>",
			masculine_nom_pl = "<*-ō> or <*-ōs> {depending}",
			neuter_nom_pl = "<*-u>",
		},
		["GENDER <ja>-stem"] = {
			header = [==[
{originates_from<from:{pie_ja_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw}
# {GENDER_gmw_post_proto_a_loss}
# {j_stem_sievers_law}{see_ija_stem_xref}. {ja_ija_stem_divergence}
# The <*-j-> stem suffix triggered {WGG}, as well as {i_umlaut_palatalization}.
# After loss of final-syllable <*-a>, the newly final <*-j> was vocalized to <*-i>.
]==],
			nom_sg = "<*-ja>, becoming <*-i>",
			gen_sg = "<*-jas> with {WGG}",
			masculine_nom_pl = "<*-jō> or <*-jōs> with {WGG} {depending}",
			neuter_nom_pl = "<*-ju> with {WGG}",
		},
		["GENDER <ija>-stem"] = {
			header = [==[
{originates_from<from:{pie_ija_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw}
# {GENDER_gmw_post_proto_a_loss}
# {ij_stem_sievers_law}{see_ja_stem_xref}. {ja_ija_stem_divergence}
# The <*-ij-> stem suffix triggered {i_umlaut_palatalization}.
# After loss of final-syllable <*-a>, the newly final <*-ij> was vocalized to <*-ī>.
]==],
			nom_sg = "<*-ija>, becoming <*-ī>",
			gen_sg = "<*-ijas>",
			masculine_nom_pl = "<*-ijō> or <*-ijōs> {depending}",
			neuter_nom_pl = "<*-iju>",
		},
		["GENDER <wa>-stem"] = {
			gmw_wa_stem_w_lost_before_u = "<*-w-> was lost before <*u>, as in the dative plural <*-um> and neuter nominative/accusative plural <*-u>.",
			masculine_gmw_wa_stem_w_lost_before_u = "<*-w-> was lost before <*u>, as in the dative plural <*-um>.",
			-- neuter_gmw_wa_stem_w_lost_before_u inherits from gmw_wa_stem_w_lost_before_u
			header = [==[
{originates_from<from:{pie_wa_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw}
# {GENDER_gmw_post_proto_a_loss}
# After loss of final-syllable <*-a>, the newly final <*-w> was vocalized to <*-u>. {GENDER_gmw_wa_stem_w_lost_before_u}
]==],
			nom_sg = "<*-wa>, becoming <*-u>",
			gen_sg = "<*-was>",
			masculine_nom_pl = "<*-wō> or <*-wōs> {depending}",
			neuter_nom_pl = "<*-u>",
		},
		["<ō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_gmw}
]==],
			nom_sg = "<*-u>",
			gen_sg = "<*-ā>",
			nom_pl = "<*-ō>",
		},
		["<ī>/<jō>-stem"] = {
			header = [==[
{originates_from<from:{pie_i_jo_stem}>}
# {pie_i_jo_stem_to_gem}
# {gem_i_jo_stem_to_gmw}
]==],
			nom_sg = "<*-ī>",
			gen_sg = "<*-ijā> after a heavy stem, <*-jā> with {WGG} after a light stem",
			nom_pl = "<*-ijō> after a heavy stem, <*-jō> with {WGG} after a light stem",
		},
		["<wō>-stem"] = {
			header = [==[
{originates_from<from:{pie_wo_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_gmw} <*-w-> was lost before <*u>, as in the nominative singular <*-u> and dative plural <*-um>.",
]==],
			nom_sg = "<*-u>",
			gen_sg = "<*-wā>",
			nom_pl = "<*-wō>",
		},
		["<i>-stem"] = {
			gender = "masculine, feminine or neuter",
			header = "In {PG}, the masculine and feminine <i>-stems differed from the neuter <i>-stems in the nominative and accusative, but later sound changes caused the two classes to converge.",
			possible_genders = false,
			nom_sg = "<*-i>",
			gen_sg = "<*-ī>",
			nom_pl = "<*-ī>",
		},
		["GENDER <an>-stem"] = {
			gender = "masculine or rarely neuter",
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<*-ō>",
			neuter_nom_sg = "<*-ā>",
			gen_sg = "<*-ini> or <*-an>",
			masculine_nom_pl = "<*-an>",
			neuter_nom_pl = "<*-ōn>",
			parent = "n-stem",
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ī>",
			gen_sg = "<*-īn>",
			nom_pl = "unattested",
			parent = "n-stem",
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ā>",
			gen_sg = "<*-ōn>",
			nom_pl = "<*-ōn>",
			parent = "n-stem",
		},
		["<u>-stem"] = {
			gender = "masculine, feminine or rarely neuter",
			nom_sg = "<*-u>",
			gen_sg = "<*-ō>",
			nom_pl = "<*-iwi> or <*-ō> when masculine or feminine, unattested when neuter",
		},
		["consonant stem"] = {
			gender = "masculine, feminine or rarely neuter",
			nom_sg = "a null ending",
			gen_sg = "<*-i> (with {i_umlaut} of roots in <*-e->)",
			nom_pl = "{gen_sg}",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<*-er>",
			gen_sg = "?",
			nom_pl = "?",
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "a null ending",
			gen_sg = "<*-iʀi> (with {i_umlaut} of roots in <*-e->)",
			nom_pl = "<*-iʀu> (with {i_umlaut} of roots in <*-e->)",
		},
	},
	got = {
		vars = {
			----------------- <a>-stem settings -----------------

			gem_a_stem_to_got_init = "{PG} <*z> regularly developed to <s> in Gothic. Short vowels other than <u> were lost in final unstressed syllables before <*z> or when absolutely final, leading to",

			-- plain <a>-stem settings
			gem_gen_a_stem_to_got = "The {PG} genitive variant <*-is> was generalized.",
			gem_masc_pl_a_stem_to_got = "Masculine plural {verner} variants <*-ôz> and <*-ôs> merged as Gothic <-ōs>.",
			gem_neut_pl_a_stem_to_got = "Neuter plural <*-ō> was lowered and shortened to <-a> (unlike in North and West Germanic, where the outcome was <*-u>); the same outcome is observed in feminine <ō>-stems.",
			gem_a_stem_to_got = "{gem_a_stem_to_got_init} non-syllabic nominative masculine <-s> and endingless nominative/accusative neuter. {gem_gen_a_stem_to_got} {gem_masc_pl_a_stem_to_got} {gem_neut_pl_a_stem_to_got}",
			masculine_gem_a_stem_to_got = "{gem_a_stem_to_got_init} non-syllabic nominative masculine <-s>. {gem_gen_a_stem_to_got} {gem_masc_pl_a_stem_to_got}",
			neuter_gem_a_stem_to_got = "Short vowels other than <u> were lost in final unstressed syllables before <*z> or when absolutely final, leading to an endingless nominative/accusative neuter. {gem_gen_a_stem_to_got} {gem_neut_pl_a_stem_to_got}",

			-- <ja>-stem settings
			gem_ja_stem_to_got_init = "{gem_a_stem_to_got_init} the preceding <*-j-> vocalizing to <-i->.",
			gem_ja_stem_to_got_survival_of_j = "{gem_a_stem_to_got_init} the preceding <*-j-> vocalizing to <-i->.",
			gem_ja_stem_to_got = "{gem_ja_stem_to_got_init} This leads directly to neuter nominative/accusative <-i>, but the expected masculine outcome <*-is> was analogically modified to <-jis> by comparison to other cases, where <*-j-> was preserved. The same modification happened to genitive <*-is> (before which the stem suffix <*-j-> had disappeared in {PG}), which also became <-jis>. {gem_masc_pl_a_stem_to_got} {gem_neut_pl_a_stem_to_got} {gem_ja_stem_to_got_survival_of_j}",
			masculine_gem_ja_stem_to_got = "{gem_ja_stem_to_got_init} The expected masculine outcome <*-is> was analogically modified to <-jis> by comparison to other cases, where <*-j-> was preserved. The same modification happened to genitive <*-is> (before which the stem suffix <*-j-> had disappeared in {PG}), which also became <-jis>. {gem_masc_pl_a_stem_to_got} {gem_ja_stem_to_got_survival_of_j}",
			neuter_gem_ja_stem_to_got = "{gem_ja_stem_to_got_init} This leads directly to neuter nominative/accusative <-i>. Genitive <*-is> (before which the stem suffix <*-j-> had disappeared in {PG}) was analogically replaced with <-jis> by comparison to other cases, where <*-j-> was preserved. {gem_neut_pl_a_stem_to_got} {gem_ja_stem_to_got_survival_of_j}",

			-- <ija>-stem settings
			gem_ija_stem_to_got_init = "{gem_a_stem_to_got_init} the preceding <*-ij-> vocalizing to {{ic|/iː/}}, written <-ei->.",
			gem_ija_stem_to_got = "{gem_ija_stem_to_got_init} This leads directly to masculine nominative <-eis>, but neuter <ija>-stems had their endings replaced with <ja>-stem endings, resulting in neuter nominative/accusative <-i>. The same thing happened in the genitive, with expected <-eis> surviving in the masculine but replaced by <ja>-stem <-jis> in most neuter words. All surviving <*-ij-> were then reduced to <-j->, causing the dative singular and all plural forms to merge with <ja>-stems in both masculine and neuter. See <<c:<ja>-stems>> for more information.",
			masculine_gem_ija_stem_to_got = "{gem_ija_stem_to_got_init} This leads directly to masculine nominative <-eis>. In the genitive singular, {PG} <*-īs> survives unchanged, written <-eis>. All surviving <*-ij-> were then reduced to <-j->, causing the dative singular and all plural forms to merge with <ja>-stems. See <<c:<ja>-stems>> for more information.",
			neuter_gem_ija_stem_to_got = "{gem_ija_stem_to_got_init} This expected <*-ei> was analogically replaced by <ja>-stem neuter <-i>; likewise in the genitive, where expected <*-eis> was replaced by <ja>-stem <-jis> in most neuter words. All surviving <*-ij-> were then reduced to <-j->, causing a wholesale merger of neuter <ija>-stems and <ja>-stems. See <<c:<ja>-stems>> for more information, and note that masculine <ija>-stems remained distinct.",

			----------------- <ō>-stem settings -----------------

			gem_o_stem_to_got = "{PG} nominative singular <*-ō> was lowered and shortened to <-a> (also observed in the neuter plural of <a>-stems). Final <*-z> devoiced to <-s>, leading to genitive <-ōs>, and overlong <*-ô-> in the nominative plural was reduced to normal long <ō>, causing the nominative and accusative plural to merge as <-ōs>.",
		},
		["GENDER <a>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_a_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_got}
]==],
			masculine_nom_sg = "<-s>",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-is>",
			masculine_nom_pl = "<-ōs>",
			neuter_nom_pl = "<-a>",
		},
		["GENDER <ja>-stem"] = {
			header = [==[
{originates_from<from:{pie_ja_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_ja_stem_to_got}
# {j_stem_sievers_law}{see_ija_stem_xref}.
]==],
			masculine_nom_sg = "<-jis>",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-jis>",
			masculine_nom_pl = "<-jōs>",
			neuter_nom_pl = "<-ja>",
		},
		["GENDER <ija>-stem"] = {
			header = [==[
{originates_from<from:{pie_ija_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_ija_stem_to_got}
# {ij_stem_sievers_law}{see_ja_stem_xref}.
]==],
			masculine_nom_sg = "<-eis>",
			neuter_nom_sg = "<-i>",
			masculine_gen_sg = "<-eis>",
			neuter_gen_sg = "<-jis>",
			masculine_nom_pl = "<-jōs>",
			neuter_nom_pl = "<-ja>",
		},
		["<ō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_got}
# See also the related <<c:<ī>/<jō>-stem nouns|<ī>/<jō>-stem>> class of nouns.
]==],
			nom_sg = "<-a>",
			gen_sg = "<-ōs>",
			nom_pl = "<-ōs>",
		},
		["<ī>/<jō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_got}
# Not to be confused with <<c:<i>/<ō>-stem nouns>>, all of which have a suffix element <-ein-> followed by a mixture of <i>-stem and <ō>-stem endings.",
]==],
			nom_sg = "<-i>",
			gen_sg = "<-jōs>",
			nom_pl = "<-jōs>",
		},
		["<i>/<ō>-stem"] = {
			header = "This is a special, highly productive class of abstract nouns that was innovated in Gothic and had a mixture of <i>-stem and <ō>-stem endings after a suffix element <-ein->. Not to be confused with <<c:<ī>/<jō>-stem nouns>>, which decline like feminine <jō> stems (i.e. <ō> stems with a preceding <j>) except in the nominative and vocative singular. Also not to be confused with <<c:<īn>-stem nouns>>, which are also feminine abstract nouns with an <-ein-> formant in most cases, but which take <n>-stem endings.",
			gender = "feminine",
			nom_sg = "<-eins>",
			gen_sg = "<-einais>",
			nom_pl = "<-einōs>",
			parent = {"feminine i-stem", "ō-stem"},
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			nom_sg = "<-s>",
			masculine_gen_sg = "<-is>",
			feminine_gen_sg = "<-ais>",
			nom_pl = "<-eis>",
			footer = "In Gothic, masculine <i>-stems have been restructured in the singular on the basis of <a>-stems while feminine <i>-stems preserve the original endings (although feminine genitive singular <-ais> is formed analogically to <-aus> in <u>-stems; <#-eis> would be expected); compare a similar development in {OHG}. Both genders preserve the original endings in the plural. No neuter <i>-stems survive; the few that existed in {PG} were moved to other declensions.",
		},
		["GENDER <u>-stem"] = {
			gender = "masculine/feminine or neuter",
			possible_genders = {"masculine or feminine", "neuter"},
			["masculine or feminine_nom_sg"] = "<-us>",
			neuter_nom_sg = "<-u>",
			gen_sg = "<-aus>",
			["masculine or feminine_nom_pl"] = "<-jus>",
			neuter_nom_pl = "unattested",
		},
		["GENDER <an>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-a>",
			neuter_nom_sg = "<-ō>",
			gen_sg = "<-ins>",
			masculine_nom_pl = "<-ans>",
			neuter_nom_pl = "<-ōna>",
			parent = "n-stem",
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ei>",
			gen_sg = "<-eins>",
			nom_pl = "<-eins>",
			parent = "n-stem",
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ō>",
			gen_sg = "<-ōns>",
			nom_pl = "<-ōns>",
			parent = "n-stem",
		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-nds>",
			gen_sg = "<-ndis>",
			nom_pl = "<-nds>",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-ar>",
			gen_sg = "<-rs>",
			nom_pl = "<-rjus>",
		},
		["consonant stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-s>",
			gen_sg = "<-s>",
			nom_pl = "<-s>",
		},
	},
	non = {
		vars = {
			----------------- settings across stems -----------------

			non_j_stem_i_umlaut = "The <*-j-> normally triggered {i_umlaut} throughout the stem as well as gemination of a preceding velar. In the literary period, the <-j-> was maintained only before back vowels (as in genitive plural <-ja>); hence it is missing in front-vowel endings such as <-i>, <-ir> and <-is> and consonantal endings like <-r> and <-s>.",
			non_ij_stem_i_umlaut = "The <*-ij-> normally triggered {i_umlaut} throughout the stem, and was then lost except after velars, where it was reduced to <*-j->. In the literary period, this <-j-> was maintained only before back vowels (as in genitive plural <-ja>); hence it is missing in front-vowel endings such as <-i>, <-ir> and <-is> and consonantal endings like <-r> and <-s>.",
			non_w_stem_u_umlaut = "The <*-w-> normally triggered {u_umlaut} throughout the stem, and was then lost except after velars, vowels and light stems ({light_stem_expl}), where it was converted to <*-v->. In the literary period, this <-v-> was maintained before vowels other than <u>, and otherwise lost.",

			----------------- <a>-stem settings -----------------

			gem_a_stem_to_non_init = "{PG} <*z> regularly developed to <*ʀ> (probably a rhotic fricative) in North Germanic, and eventually merged with <*r>. All short vowels in final unstressed syllables were ultimately lost, leading to",

			-- plain <a>-stem and <ja>-stem settings
			gem_masc_pl_a_stem_to_non = "Masculine plural {verner} variant <*-ôz> was generalized in North Germanic and shortened to <-ar>.",
			gem_neut_pl_a_stem_to_non = "Neuter plural <*-ō> was raised and shortened to <*-u>. (This is common to North and West Germanic and is also observed in the nominative singular of <ō>-stems.)",
			gem_a_stem_to_non = "{gem_a_stem_to_non_init} non-syllabic nominative masculine <-r> and genitive <-s> endings and endingless nominative/accusative neuter. {gem_masc_pl_a_stem_to_non} {gem_neut_pl_a_stem_to_non}",
			masculine_gem_a_stem_to_non = "{gem_a_stem_to_non_init} non-syllabic nominative masculine <-r> and genitive <-s> endings. {gem_masc_pl_a_stem_to_non}",
			neuter_gem_a_stem_to_non = "All short vowels in final unstressed syllables were ultimately lost in North Gerrmanic, leading to non-syllabic genitive <-s> and endingless nominative/accusative neuter. {gem_neut_pl_a_stem_to_non}",

			-- <ija>-stem settings
			gem_masc_pl_ija_stem_to_non = "Masculine plural {verner} variant <*-ôz> was generalized in North Germanic and shortened to <-ar>, with stem suffix <*-ij-> lost before a surviving vowel.",
			gem_neut_pl_ija_stem_to_non = "Neuter plural <*-ō> was raised and shortened to <*-u>. (This is common to North and West Germanic and is also observed in the nominative singular of <ō>-stems.) This final <*-u> was regularly lost, leading to the survival of <*-ij-> as final <-i>. Although final <*-u> would normally trigger {u_umlaut}, this was blocked by the preceding <*-j->.",
			gem_ija_stem_to_non = "{gem_a_stem_to_non_init} nominative masculine <-ir>, neuter <-i> along with genitive <-is> endings, with syllabic <*-ij-> surviving as <-i->. {gem_masc_pl_ija_stem_to_non} {gem_neut_pl_ija_stem_to_non}",
			masculine_gem_ija_stem_to_non = "{gem_a_stem_to_non_init} nominative masculine <-ir> and genitive <-is> endings, with syllabic <*-ij-> surviving as <-i->. {gem_masc_pl_ija_stem_to_non}",
			neuter_gem_ija_stem_to_non = "All short vowels in final unstressed syllables were ultimately lost in North Gerrmanic, leading to nominative neuter <-i>, genitive <-is>, with syllabic <*-ij-> surviving as <-i->. {gem_neut_pl_ija_stem_to_non}",

			-- extra note for <a>-stems, <ja>-stems and <ija>-stems
			non_a_stem_genitive_ar_origin = "Genitive singular ending <-ar> is borrowed from <i>-stems or <u>-stems.",

			----------------- <ō>-stem settings -----------------

			gem_o_stem_to_non = "{PG} nominative singular <*-ō> was raised and shortened to <*-u> (a development common to North and West Germanic and also observed in the neuter plural of <a>-stems). Final <*-z> developed to <*-ʀ> (probably a rhotic fricative), and eventually merged with <*-r>. Unstressed <*ō> and overlong <*ô> both ultimately shortened and lowered to <a>.",
			non_jo_stem_final_u = "Final <*-u> is regularly lost. It would normally trigger {u_umlaut}, but this was blocked by the preceding <*-j->.",

			-- extra note for <ō>-stems, <jō>-stems and <ijō>-stems
			non_o_stem_plural_ir_origin = "Nominative/accusative plural <-ir> in some nouns is borrowed from <i>-stems.",
		},
		["GENDER <a>-stem"] = {
			non_a_stem_final_u = "\n# Final <*-u> in the neuter nominative/accusative plural triggered {u_umlaut} and then was lost.",
			masculine_non_a_stem_final_u = "",
			-- neuter_non_a_stem_final_u inherits from non_a_stem_final_u
			header = [==[
{originates_from<from:{pie_plain_a_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_non}{GENDER_non_a_stem_final_u}
# {non_a_stem_genitive_ar_origin}
]==],
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-s> or sometimes <-ar>",
			masculine_nom_pl = "<-ar>",
			neuter_nom_pl = "a null ending with {u_umlaut}",
			masculine_after_pp = false,
			masculine_examples = [==[
# <<hestr||horse>>
# <<hǫfundr||chieftain>> (genitive <<hǫfundar>>)
# <<hauss||skull>> (with <-r> assimilated to <-s>; accusative <<haus>>)
# <<hals||neck>> (with <-r> dropped after preceding consonant + <s>; accusative <<hals>>)
# <<heiðr||honor, worth>> (with <-r> part of the stem; accusative <<heiðr>>)
# <<fleinn||arrow>> (with <-r> assimilated to <-n>; accusative <<flein>>)
# <<hamarr||hammer>> (dative <<hamri>>, with contraction)
]==],
			neuter_examples = [==[
# <<orð||word>>
# <<barn||child>> (nominative/accusative plural <<bǫrn>>, with {u_umlaut})
# <<hǫfuð||head>> (with contraction; dative <<hǫfði>>)
]==],
		},
		["GENDER <ja>-stem"] = {
			non_ja_stem_final_u = "\n# Final <*-u> in the neuter nominative/accusative plural is regularly lost. It would normally trigger {u_umlaut}, but this was blocked by the preceding <*-j->.",
			masculine_non_ja_stem_final_u = "",
			-- neuter_non_ja_stem_final_u inherits from non_ja_stem_final_u
			header = [==[
{originates_from<from:{pie_ja_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_non}
# {j_stem_sievers_law}{see_ija_stem_xref}. {non_j_stem_i_umlaut}{GENDER_non_ja_stem_final_u}
# {non_a_stem_genitive_ar_origin}
]==],
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>), or <-ir> in proper names",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-s> or sometimes <-jar>, or <-is> in proper names",
			masculine_nom_pl = "<-jar>, or <-ir> in proper names",
			neuter_nom_pl = "a null ending",
			masculine_examples = [==[
# <<niðr||kinsman, relative>> (nominative plural <<niðjar>>)
# <<herr||army>>, from <<gem-pro+:*harjaz>> (nominative plural <<herjar>>)
# <<Mjǫllnir|ng=name of a Norse god>>, from <<gem-pro+:*Meldunjaz>>
]==],
			neuter_examples = [==[
# <<kyn||kind, type; kin>>, from <<gem-pro+:*kunją>> (genitive plural <<kynja>>)
# <<egg||egg>>, from <<gem-pro+:*ajją>>, with <-gg(j)-> due to {{w|Holtzmann's law}} (genitive plural <<eggja>>)
]==],
		},
		["GENDER <ija>-stem"] = {
			non_ija_stem_velar_example = "Thus, nominative singular <<fylkir||chief, king>> and <<ríki||realm>> are missing the <-j-> infix, but it reappears in genitive plural <<fylkja>>, <<ríkja>>.",
			masculine_non_ija_stem_velar_example = "Thus, nominative singular <<fylkir||chief, king>> is missing the <-j-> infix, but it reappears in genitive plural <<fylkja>>.",
			neuter_non_ija_stem_velar_example = "Thus, nominative singular <<ríki||realm>> is missing the <-j-> infix, but it reappears in genitive plural <<ríkja>>.",
			header = [==[
{originates_from<from:{pie_ija_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_non}
# {ij_stem_sievers_law}{see_ja_stem_xref}. {non_ij_stem_i_umlaut} {GENDER_non_ija_stem_velar_example}{GENDER_non_ja_stem_final_u}
# {non_a_stem_genitive_ar_origin}
]==],
			masculine_nom_sg = "<-ir>",
			neuter_nom_sg = "<-i>",
			gen_sg = "<-is> or sometimes <-ar> (usually <-jar> after velars)",
			masculine_nom_pl = "<-ar> (usually <-jar> after velars)",
			neuter_nom_pl = "<-i>",
			masculine_examples = [==[
# <<endir||end>>, from <<gem-pro+:*andijaz>> (nominative plural <<endar>>)
# <<fylkir||chief, king>> (nominative plural <<fylkjar>>)
# <<eyrir||ounce; money>> (irregular nominative plural <<aurar>>)
]==],
			neuter_examples = [==[
# <<leyfi||permission, leave>> (genitive plural <<leyfa>>)
# <<ríki||realm>> (genitive plural <<ríkja>>)
# <<erendi||errand>> (genitive plural <<erenda>>)
]==],
		},
		["GENDER <wa>-stem"] = {
			non_wa_stem_final_u = "\n# Final <*-u> in the neuter nominative/accusative plural is regularly lost. It would normally trigger {u_umlaut}, but its effect is not visible because <*-w-> also caused {u_umlaut}.",
			masculine_non_wa_stem_final_u = "",
			-- neuter_non_wa_stem_final_u inherits from non_wa_stem_final_u
			header = [==[
{originates_from<from:{pie_wa_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_non}
# {non_w_stem_u_umlaut} Hence it is present in genitive plural <-va> and dative singular <-vi>, but missing in dative plural <-um> and genitive singular <-s>.{GENDER_non_wa_stem_final_u}
# {non_a_stem_genitive_ar_origin}
]==],
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-s> or sometimes <-var>",
			masculine_nom_pl = "<-var>",
			neuter_nom_pl = "a null ending",
			masculine_examples = [==[
# <<sǫngr||song>> (nominative plural <<sǫngvar>>)
# <<snjór||snow>> (nominative plural <<snjóvar>>)
]==],
			neuter_examples = [==[
# <<mjǫl||flour>> (genitive plural <<mjǫlva>>)
# <<hǫgg||blow, strike>> (genitive plural <<hǫggva>>)
# <<hræ||corpse>> (genitive plural <<hræva>>)
]==],
		},
		["<ō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_non}
# Final <*-u> triggered {u_umlaut} and then was lost.
# {non_o_stem_plural_ir_origin}
]==],
			nom_sg = "a null ending with {u_umlaut}",
			gen_sg = "<-ar> without {u_umlaut}",
			nom_pl = "<-ar> without {u_umlaut}; often also <-ir> is allowed",
			examples = [==[
# <<gjǫf||gift>> (genitive <<gjafar>>, nominative/accusative plural <<gjafar>>/<<gjafir>>)
# <<fjǫðr||feather>> (genitive <<fjaðrar>>)
# <<dróttning||queen; mistress>> (dative <<dróttningu>>)
# <<brá||eyelash>> (genitive <<brár>>)
]==],
		},
		["<jō>-stem"] = {
			header = [==[
{originates_from<from:{pie_jo_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_non}
# {j_stem_sievers_law}{see_ijo_stem_xref}. {non_j_stem_i_umlaut}
# {non_jo_stem_final_u}
# {non_o_stem_plural_ir_origin}
]==],
			nom_sg = "a null ending",
			gen_sg = "<-jar>",
			nom_pl = "<-jar>",
			examples = [==[
# <<ben||wound>> (genitive <<benjar>>)
# <<egg||edge>> (genitive <<eggjar>>, dative <<egg>> or <<eggju>>)
# <<þý||female slave>> (genitive <<þýjar>>, dative <<þýju>>)
]==],
		},
		["<ijō>-stem"] = {
			header = [==[
{originates_from<from:{pie_ijo_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_non}
# {ij_stem_sievers_law}{see_jo_stem_xref}. In {ON}, the <*-ij-> would normally trigger {i_umlaut} throughout the stem, but there are a large number of exceptions, which are only partly explained. The <*-ij-> was ultimately lost except after velars, where it was reduced to <*-j->. In the literary period, this <-j-> was maintained only before back vowels (as in genitive plural <-ja>); hence it is missing in front-vowel endings such as <-i>, <-ir> and <-is> and consonantal endings like <-r> and <-s>.
# {non_jo_stem_final_u}
# {non_o_stem_plural_ir_origin}
]==],
			nom_sg = "<-r>",
			gen_sg = "<-ar> (usually <-jar> after velars)",
			nom_pl = "<-ar> (usually <-jar> after velars) or sometimes <-ir>",
			examples = [==[
# <<mýrr||moor>>, from <<gem-pro+:*miuzijō>> (nominative/accusative plural <<mýrar>>)
# <<ylgr||she-wolf>>, from <<gem-pro+:*wulgī>> (nominative/accusative plural <<ylgjar>>)
# <<gunnr|gunnr, guðr|battle, war>>, from <<gem-pro+:*gunþiz>> (nominative/accusative plural <<gunnar>>)
# <<hildr||battle>>, from <<gem-pro+:*hildiz>> (nominative/accusative plural <<hildir>>)
]==],
		},
		["<wō>-stem"] = {
			header = [==[
{originates_from<from:{pie_wo_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_non}
# {non_w_stem_u_umlaut} Hence it is present in genitive plural <-va> and genitive singular <-var>, but missing in dative plural <-um>, dative singular <-u>, and nominative/accusative/dative singular with a null ending.
# Final <*-u> is regularly lost. It would normally trigger {u_umlaut}, but its effect is not visible because <*-w-> also caused {u_umlaut}.
]==],
			nom_sg = "a null ending",
			gen_sg = "<-var>",
			nom_pl = "<-var>",
			examples = [==[
# <<ǫr||arrow>> (genitive <<ǫrvar>>)
# <<dǫgg||drizzle; fog; dew>> (genitive <<dǫggvar>>)
]==],
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			feminine_nom_sg = "a null ending with {u_umlaut}",
			masculine_gen_sg = "<-ar> (<-jar> after vowels, velars or sometimes other consonants) or <-s>",
			feminine_gen_sg = "<-ar>",
			nom_pl = "<-ir>",
			feminine_header = [==[
{originates_from<from:{pie_i_stem}>}
# {pie_i_stem_to_gem}
# In {ON}, feminine <i>-stem nouns completely merged with <ō>-stem nouns in the singular, with the result that {i_umlaut}, which should theoretically be present throughout the paradigm, is often missing, and conversely {u_umlaut}, which should not be present, is normally found in the nominative and accusative singular. The genitive <-ar> is likewise borrowed from the <ō>-stems.
# The only thing distinguishing feminine <i>-stem nouns is the nominative/accusative plural <-ir> (regularly derived from {PG} <*-īz>), whereas feminine <ō>-stem nouns use <-ar> (but often allow <-ir> as well, due to analogy with the <i>-stems).
# As a result of this convergence, many {ON} <i>-stem feminines derive from original <ō>-stem nouns, and vice-versa.
]==],
			masculine_header = [==[
{originates_from<from:{pie_i_stem}>}
# {pie_i_stem_to_gem}
# In {ON}, masculine <i>-stems are closer to the original {PG} paradigm than feminine <i>-stems. The following differences from <a>-stems should be noted:
# {I_umlaut} is often present throughout the paradigm (although it tends to be missing in light stems, i.e. {light_stem_expl}, due to early elision of the <*-i->).
# The genitive is more commonly in <-ar> than <-s>, opposite to the tendency in <a>-stems, and maintains the stem infix <-j-> in some words. (Theoretically, <a>-stems should always have their genitive in <-s> and <i>-stems in <-ar>, but contamination in both directions has occurred.)
# The dative ending is usually null, whereas in <a>-stems it is usually <-i> (but exceptions occur in both directions, even more so in modern Icelandic).
# The nominative and accusative plurals are clearly distinct, with <i>-stems having <-i-> and <a>-stems having <-a->.
]==],
			masculine_examples = [==[
# <<gestr||guest>> (genitive <<gests>>)
# <<staðr||place>> (genitive <<staðar>>)
# <<drykkr||drink, beverage>> (genitive <<drykkjar>>)
# <<hár||thole>> (genitive <<hás>>)
# <<gríss||boar; piglet>> (genitive <<gríss>>, nominative plural <<grísir>>),
]==],
			feminine_examples = [==[
# <<kván||wife>>, from <<gem-pro+:*kwēniz>>, without {i_umlaut}
# <<ætt||direction; family; generation>> and <<átt||family, race; direction>>, both from <<gem-pro+:*aihtiz>>, with and without {i_umlaut}
# <<sýn||sight; appearance>> and <<sjón|ng=same>>, both from <<gem-pro+:*siuniz>>, with and without {i_umlaut}
# <<ǫld||time, age; cycle>>, from <<gem-pro+:*aldiz>> (dative <<ǫldu>>, <<ǫld>>)
# <<ǫsp||aspen>>, from <<gem-pro+:*aspō>>
# <<sorg||sorrow; grief>>, from <<gem-pro+:*surgō>>
]==],
		},
		["GENDER <an>-stem"] = {
			gender = "masculine or rarely neuter",
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-i>",
			neuter_nom_sg = "<-a>",
			gen_sg = "<-a>",
			masculine_nom_pl = "<-ar>",
			neuter_nom_pl = "<-u> with {u_umlaut}",
			parent = "n-stem",
			masculine_examples = [==[
# <<bogi||bow>>
# <<hreifi||wrist>>
# <<dōmari||judge>> (genitive plural <<dómurum>>)
# <<gumi||man>> (nominative plural <<gumar>> or <<gumnar>>)
# <<oxi||ox>> (nominative plural <<oxar>> or <<øxn>>, with consonant-stem endings)
# <<lé||scythe>> (genitive <<ljá>> < <<|*léa>>, nominative plural <<ljár>>)
]==],
			neuter_examples = [==[
# <<auga||eye>> (genitive plural <<augna>>)
# <<eyra||ear>>, from <<gem-pro+:*ausô>> (which is assumed to have maintained Verner alternation in the stem, where the <*-z-> alternant was generalized in Northwest Germanic and caused {i_umlaut} due to {ON} <z>-mutation; genitive plural <<eyrna>>)
# <<hjarta||heart>> (nominative/accusative plural <<hjǫrtu>>, genitive plural <<hjartna>>)
]==],
		},
		["<jan>-stem"] = {
			gender = "masculine",
			nom_sg = "<-i>",
			gen_sg = "<-ja>",
			nom_pl = "<-jar>",
			parent = "masculine <an>-stem",
			examples = [==[
# <<bryti||steward>> (genitive <<brytja>>)
# <<steði||anvil>> (genitive <<steðja>>)
# <<erfingi||heir>> (genitive <<erfingja>>)
]==],
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-i>",
			gen_sg = "<-i>",
			nom_pl = "<-ar>",
			parent = "n-stem",
			footer = "The stem has {i_umlaut} throughout.",
			examples = [==[
# <<deyfi||deafness>>
# <<elli||old age>>, from <<gem-pro+:*alþį̄>>
# <<lygi||lie>> (nominative/accusative plural <<lygar>>)
]==],
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-u> with {u_umlaut}",
			nom_pl = "<-ur> with {u_umlaut}",
			parent = "n-stem",
			examples = [==[
# <<saga||story>> (accusative <<sǫgu>>, genitive plural <<sagna>>)
# <<hvíla||bed>> (genitive plural <<hvílna>>)
# <<hǿna||hen>>, from <<gem-pro+:*hōnijǭ>> (genitive plural <<hǿnna>>)
# <<blaðra||bladder>> (accusative <<blǫðru>>, genitive plural <<blaðra>>)
]==],
		},
		["<jōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ja>",
			gen_sg = "<-ju>",
			nom_pl = "<-jur>",
			parent = "<ōn>-stem",
			footer = "This class derives from {PG} <ōn>-stems ending in <j> after a light root, a vowel or a velar. As a result, the stem has {i_umlaut} throughout.",
			examples = [==[
# <<smiðja||smithy>> (genitive plural <<smiðja>>)
# <<hyggja||thought, opinion>> (genitive plural <<hyggna>>)
# <<brynja||coat of mail>> (genitive plural <<brynja>>)
# <<eimyrja||ember>>, from <<gem-pro+:*aimuzjǭ>> (genitive plural <<eimyrja>>)
]==],
		},
		["<wōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-va>",
			gen_sg = "<-u>",
			nom_pl = "<-ur>",
			parent = "<ōn>-stem",
			footer = "This class derives from {PG} <ōn>-stems ending in <w>. As a result, the stem has {u_umlaut} throughout.",
			examples = [==[
# <<vǫlva||prophetess, witch>>
# <<vǫkva||moisture, humidity>>
# <<kvikva||quick (living tissue under nails or hooves); running fluid>>
]==],
		},
		["<u>-stem"] = {
			gender = "masculine",
			nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>) with {u_umlaut}",
			gen_sg = "<-ar> without {u_umlaut}",
			nom_pl = "<-ir> with {i_umlaut}",
			footer = "This class preserves most characteristics of {PG} <u>-stems, including {u_umlaut} in the nominative and accusative singular and the accusative and dative plural, and {i_umlaut} in the dative singular (< {PG} <*-iwi>) and nominative plural (< {PG} <*-iwiz>). The accusative plural is marked by a unique ending <-u>. The only remnant of <u>-stem neuters is <<fé>>, which has no obvious characteristics of <u>-stems any more and is best treated as simply irregular.",
			examples = [==[
# <<fjǫrðr||fjord>>, from <<gem-pro+:*ferðuz>> (dative <<firði>>, genitive <<fjarðar>>)
# <<lǫgr||sea, lake>>, from <<gem-pro+:*laguz>> (dative <<legi>>, genitive <<lagar>>)
# <<spánn|spánn, spónn|chip of wood; spoon>>, from <<gem-pro+:*spēnuz>> (with <-r> assimilated to <-n>, and <ó> from earlier <ǫ́> before <n>; dative <<spæni>>)
# <<fǫgnuðr||happiness, joy; greetings>> (dative <<fagnaði>>, genitive <<fagnaðar>>, nominative plural <<fagnaðir>>; nouns with the abstract ending <-(n)uðr>/<-(n)aðr> are not subject to {i_umlaut})
]==]
		},
		["GENDER consonant stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			feminine_nom_sg = "usually a null ending with {u_umlaut}",
			masculine_gen_sg = "<-ar> or <-s>",
			feminine_gen_sg = "<-ar> or <-r>, the latter often with {i_umlaut}",
			nom_pl = "<-r> (which assimilates to a preceding <l>, <n> or <s>) with {i_umlaut}",
			feminine_footer = "Feminine consonant stems with {u_umlaut} were usually originally <u>-stem or <ō>-stem nouns, or analogical to them.",
			masculine_examples = [==[
# <<fótr||foot; leg>> (genitive <<fótar>>, dative <<fǿti>>, nominative/accusative plural <<fǿtr>>)
# <<vetr||winter; year>> (with <-r> lost after stem ending in consonant + <-r>; genitive <<vetrar>>, nominative/accusative plural <<vetr>>)
]==],
			feminine_examples = [==[
# <<bók||book; beech>> (genitive <<bókar>> or <<bǿkr>>, nominative/accusative plural <<bǿkr>>)
# <<gás||goose>> (genitive <<gásar>>, nominative/accusative plural <<gæss>> with <-r> assimilated to <-s>)
# <<hǫnd||hand>>, from <<gem-pro+:*handuz>> (genitive <<handar>>, dative <<hendi>>, nominative/accusative plural <<hendr>>)
# <<strǫnd||border; shore>>, from <<gem-pro+:*strandō>> (genitive <<strandar>>, dative <<strǫnd>> or <<strǫndu>>, nominative/accusative plural <<strendr>>)
# <<tǫnn||tooth>>, from <<gem-pro+:*tanþs>>, with analogical {u_umlaut} (genitive <<tannar>>, nominative/accusative plural <<tenn>>/<<tennr>>/<<teðr>>, with the last variant the original and phonologically expected form)
# <<mjǫlk||milk>>, from <<gem-pro+:*meluks>>, with {u_umlaut} from the lost medial vowel (genitive <<mjǫlkr>>, singular-only)
# <<fló||flea>>, from <<gem-pro+:*flauhaz>>, with declension and gender change (genitive <<flóar>>, nominative/accusative plural <<flœr>>)
]==],
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-ir>",
			gen_sg = "<-ur> with {u_umlaut}",
			nom_pl = "<-r> with {i_umlaut}",
			parent = "consonant stem",
			examples = [==[
# <<faðir||father|g=m>> (accusative <<fǫður>>, dative <<fǫður>> or <<feðr>>, genitive <<fǫður>> or <<fǫðurs>>, nominative/accusative plural <<feðr>>)
# <<bróðir||brother|g=m>> (accusative <<bróður>>, dative <<bróður>> or <<brǿðr>>, genitive <<brǫður>>, nominative/accusative plural <<brǿðr>>)
# <<móðir||mother|g=f>> (accusative/dative/genitive <<móður>>, nominative/accusative plural <<mœðr>>)
# <<dóttir||daughter|g=f>> (accusative/genitive <<dóttur>>, dative <<dóttur>> or <<dǿtr>>, nominative/accusative plural <<dǿtr>>)
# <<systir||sister|g=f>> (accusative/dative/genitive <<systur>>, nominative/accusative plural <<systr>>)
]==],

		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-i>",
			gen_sg = "<-a>",
			nom_pl = "<-r> with {i_umlaut}",
			parent = "consonant stem",
			examples = [==[
# <<bóndi||farmer, husband>> (nominative/accusative plural <<bǿndr>>)
# <<seljandi||seller, vendor>> (nominative/accusative plural <<seljendr>>, dative plural <<seljǫndum>>)
# <<farandi||traveler>> (nominative/accusative plural <<farendr>>, dative plural <<fǫrundum>>)
# <<fjándi||enemy; devil>> (nominative/accusative plural <<fjándr>>)
# <<frændi||friend; male relative>> (nominative/accusative plural <<frændr>>)
]==],
		},
	},
	ang = {
		vars = {
			gmw_gen_a_stem_to_ang = "West Germanic genitive <*-as> become early {OE} <-æs>, later <-es>.",
			gmw_masc_pl_a_stem_to_ang = "Masculine plural {verner} variant <*-ōs> was generalized in {OE} and shortened to <-as>.",
			gmw_neut_pl_a_stem_to_ang = "Neuter plural <-u> persisted after light stems ({light_stem_expl}) but was lost after heavy stems.",

			gmw_nom_o_stem_to_ang = "West Germanic nominative singular <-u> persisted after light stems ({light_stem_expl}) but was lost after heavy stems, as with the neuter plural of <a>-stems.",
			gmw_gen_o_stem_to_ang = "West Germanic genitive singular <*-ā> was shortened and fronted to become early {OE} <-æ>, later <-e>.",
			gmw_pl_o_stem_to_ang = "West Germanic nominative plural <*-ō> was shortened and lowered to become {OE} <-a>. Meanwhile, accusative plural <*-ā> was shortened and fronted to become early {OE} <-æ>, later <-e>, as in the accusative and genitive singular. Eventually, the two forms were confused, with the result that both <-a> and <-e> can occur as either nominative or accusative plural.",
		},
		["GENDER <a>-stem"] = {
			gmw_a_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_masc_pl_a_stem_to_ang} {gmw_neut_pl_a_stem_to_ang}",
			masculine_gmw_a_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_masc_pl_a_stem_to_ang}",
			neuter_gmw_a_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_neut_pl_a_stem_to_ang}",
			header = [==[
{originates_from<from:{pie_plain_a_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw}
# {GENDER_gmw_a_stem_to_ang}
]==],
			nom_sg = "a null ending",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-as>",
			neuter_nom_pl = "<-u> after light stems, no ending after heavy stems",
			masculine_examples = [==[
# <<stān||stone>>
# <<dæġ||day>> (nominative/accusative plural <<dagas>>, cf. {{w|Anglo-Frisian brightening}})
# <<enġel||angel>>, from <<gmw-pro+|*angil>> (nominative/accusative plural <<englas>>, cf. {{w|Phonological history of Old English#Medial syncopation}})
# <<wealh||Celt; Welsh person; foreigner>> (genitive <<wēales>>, nominative/accusative plural <<wēalās>>, cf. {{w|Phonological history of Old English#H-loss}})
]==],
			neuter_examples = [==[
# <<sċip||ship>> (nominative/accusative plural <<sċipu>>)
# <<word||word>> (nominative/accusative plural <<word>>)
# <<fæt||vat>> (nominative/accusative plural <<fatu>>, cf. {{w|Anglo-Frisian brightening}})
# <<hēafod||head>> (nominative/accusative plural <<hēafdu>>, cf. {{w|Phonological history of Old English#Medial syncopation}})
]==]
		},
		["GENDER <ja>-stem"] = {
			desc = "ending in {PG} <*-(i)jaz> (masculine), <*-(i)ją> (neuter)",
			masculine_desc = "ending in {PG} <*-(i)jaz>",
			neuter_desc = "ending in {PG} <*-(i)ją>",
			gmw_neut_pl_ja_stem_to_ang = "Neuter plural <-u> normally persisted after light stems ({light_stem_expl}) but was lost after heavy stems; in this case, however, <*-ju> after a light stem caused the stem to become heavy, leading to loss of <*-u>, while conversely in <*-iju> after a heavy stem, the <*-ij-> was considered a light syllable and caused the <*-u> to remain.",
			gmw_ja_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_masc_pl_a_stem_to_ang} {gmw_neut_pl_ja_stem_to_ang}",
			masculine_gmw_ja_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_masc_pl_a_stem_to_ang}",
			neuter_gmw_ja_stem_to_ang = "{gmw_gen_a_stem_to_ang} {gmw_neut_pl_ja_stem_to_ang}",
			neut_pl_u = ";\nneuter nominative/accusative plural <-u> after (originally) heavy stems, but no ending after (originally) light stems, which is the reverse of the pattern for plain <a>-stems.",
			masculine_neut_pl_u = ".",
			-- neuter_neut_pl_u inherits from neut_pl_u
			header = [==[
This class represents the merger of the {PG} <ja>-stem and <ija>-stem classes. In {PG}, <ja>-stem nouns were essentially just <a>-stem nouns with a <*-j-> stem suffix; likewise, <ija>-stem nouns were <a>-stem nouns with an <*-ij-> stem suffix. The two suffixes were allophonic variants of each other, determined by {sievers} law and conditioned by the weight of the preceding stem, with <*-j-> occurring after light stems ({light_stem_expl}) and <*-ij-> after heavy stems.

{PG} {GENDER} <a>-stems originate from {pie_plain_a_stem}. They evolve as follows:
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw} The light-stem suffix <*-j-> triggered {WGG} of the stem-final consonant (other than <*-r->, which was not geminated).
# {GENDER_gmw_ja_stem_to_ang}
# The <*-(i)j-> suffix triggered {i_umlaut} throughout the paradigm and {PAL} of a final velar stop. <*-j-> was then lost except after <*-r->, while <*-ij-> was lost except word finally, where it persists as <-e>.

As a result, {OE} <ja>-stems largely merged with <a>-stems, but are distinguishable by:
# <-e> in the nominative/accusative singular after originally heavy stems, and {WGG} of the stem-final consonant after originally light stems;
# the presence of {i_umlaut} throughout the paradigm;
# {PAL} of a final velar stop{GENDER_neut_pl_u}
]==],
			nom_sg = "<-e> after (originally) heavy stems, no ending after (originally) light stems",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-as>",
			neuter_nom_pl = "<-u> after (originally) heavy stems, no ending after (originally) light stems",
			masculine_examples = [==[
# <<hryċġ||back, spine>> (with {i_umlaut} of original <*-u->, {WGG} after a light stem, and {PAL})
# <<ende||end>> (with {i_umlaut} of original <*-a->, and nominative ''-e'' after a heavy stem)
# <<lǣċe||doctor>> (with nominative ''-e'' after a heavy stem, and {PAL})
# <<hryre||fall; ruin>> (no {WGG} after <r>, leading to preservation of original <*-i> from {PG} <*-jaz>)
# <<here||army>> (genitive <<herġes>>; this word preserves <*-j-> after <r>)
]==],
			neuter_examples = [==[
# <<bedd||bed>> (nominative plural <<bedd>>; with {i_umlaut} of original <*-a->, and {WGG} after a light stem)
# <<rīċe||kingdom>> (nominative plural <<rīċu>>; with nominative ''-e'' and nominative plural ''-u'' after a heavy stem, and {PAL})
]==],
		},
		["GENDER <wa>-stem"] = {
			header = [==[
{originates_from<from:{pie_wa_stem}>}
# {GENDER_pie_a_stem_to_gem}
# {GENDER_gem_a_stem_to_gmw} After loss of the nominative singular ending, the word-final <*-w> becomes <*-u> after a consonant, which is retained after light stems ({light_stem_expl}, which includes most words in this class) and dropped otherwise.
# {GENDER_gmw_a_stem_to_ang}
# <*-w-> occurring syllable-finally after a vowel combines with the vowel to form a long diphthong, e.g. <<gmw-pro+:*trew||tree>> becomes <<trēo>>. Before a <*-w-> between vowels, a <*-u-> normally appears, leading to the same long diphthong, hence e.g. {PWG} genitive <<gmw-pro:|*trewas>> becomes <*treuwas> and ultimately <<trēowes>>. Within the literary period, the nominative sometimes acquires the <-w> of the oblique forms, hence both <<trēo>> and <<trēow>> are found, with modern <<en+:tree>> inherited from the former.
]==],
			nom_sg = "<-u> after consonants, no ending or <-w> after diphthongs",
			gen_sg = "<-wes>",
			masculine_nom_pl = "<-was>",
			neuter_nom_pl = "<-u> after consonants, no ending or <-w> after diphthongs",
			masculine_examples = [==[
# <<bearu||grove, wood>> (genitive <<bearwes>>, nominative plural <<bearwas>>)
]==],
			neuter_examples = [==[
# <<searu||machine, device>> (genitive <<searwes>>, nominative plural <<searu>>)
# <<trēo|trēo(w)|tree>> (genitive <<trēowes>>, nominative plural <<trēo|trēo(w)>>)
]==],
		},
		["<ō>-stem"] = {
			header = [==[
{originates_from<from:{pie_plain_o_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_gmw}
# {gmw_nom_o_stem_to_ang} {gmw_gen_o_stem_to_ang}
# {gmw_pl_o_stem_to_ang}
# Original <jō>-stems and <ijō>-stems are indistinguishable from <ō>-stems other than by the presence of {i_umlaut} throughout the paradigm, {PAL} of final velars and with {WGG} after original light stems.
]==],
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-e>",
			nom_pl = "<-e>, <-a>",
			examples = [==[
# <<ġiefu||gift>> (genitive <<ġiefe>>, light stem)
# <<þēod||people, nation; language>> (genitive <<þēode>>, heavy stem)
# <<bryċġ||bridge>>, from <<gem-pro+:*brugjō>> (original <jō>-stem, with {i_umlaut}, {WGG} and {PAL})
# <<ġierd||rod>>, from <<gem-pro+:*gardijō>> (original <ijō>-stem, with {i_umlaut})
]==],
		},
		["<wō>-stem"] = {
			header = [==[
{originates_from<from:{pie_wo_stem}>}
# {pie_o_stem_to_gem}
# {gem_o_stem_to_gmw}
# {gmw_nom_o_stem_to_ang} (Stem suffix <*-w-> was lost before <*-u> in {PWG}.) {gmw_gen_o_stem_to_ang}
# {gmw_pl_o_stem_to_ang}
]==],
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-we>",
			nom_pl = "<-we>, <-wa>",
			examples = [==[
# <<sinu||sinew, nerve>> (genitive <<sinwe>>)
# <<beadu||battle, war>> (genitive <<beadwe>>)
# <<lǣs||pasture>> (genitive <<lǣswe>>)
# <<clēa||claw, nail>> (genitive <<clawe>>)
]==],
		},
		["GENDER <i>-stem"] = {
			gender = "masculine or feminine (rarely neuter)",
			possible_genders = {"masculine", "feminine", "neuter"},
			masculine_nom_sg = "<-e> after light stems, no ending after heavy stems",
			feminine_nom_sg = "a null ending after heavy stems (light-stem feminine <i>-stems have merged with <jō>-stems)",
			neuter_nom_sg = "<-e> after light stems (heavy-stem neuter <i>-stems have merged with <ja>-stems)",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "<-e>",
			neuter_gen_sg = "<-es>",
			masculine_nom_pl = "<-as> (<-e> in some demonyms such as <<Engle||Angles, English>> and a few other words such as <<wine||friend>>)",
			feminine_nom_pl = "<-e> or <-a>",
			neuter_nom_pl = "<-u>",
			footer = [==[
In {OE}, <i>-stems have largely merged with <ja>/<jō>-stems, but are distinguishable by
# in the masculine and neuter, <-e> in the nominative/accusative singular after originally light stems, without {WGG}, as in <<sleġe||a strike, a blow, a hit>> < {{m+|gem-pro|*slagiz}} vs. <<seċġ||man, hero>> < {{m+|gem-pro|*sagjaz}};
# contrastingly, no <-e> in the nominative/accusative singular after originally heavy stems, as in <<ende||end>> < {{m+|gem-pro|*andijaz}} vs. <<bend||bond; ribbon>> < {{m+|gem-pro|*bandiz}};
# in the feminine, optional accusative singular with a null ending, as opposed to the normal ending in <-e>;
# some masculine plural-only demonyms, and a few other nouns, form their nominative/accusative plural in <-e>, the original <i>-stem ending.
]==],
			masculine_examples = [==[
# <<stede||place>> (light stem)
# <<cyre||choice>> (light stem)
# <<eġe||fear>> (light stem)
# <<wine||friend>> (light stem, plural <<wine>>)
# <<ġiest||guest>> (heavy stem)
# <<wyrm||worm>> (heavy stem)
# <<fenġ||grasp>> (heavy stem)
# <<swēġ||sound, noise>> (heavy stem)
# <<ielde||men>> (plural only)
# <<ielfe||elves>> (plural only)
# <<lēode||people>> (plural only)
# <<Engle||Angles, English>> (plural-only)
# <<Mierċe||Mercians>> (plural only)
]==],
			feminine_examples = [==[
# <<cwēn||queen>> (accusative <<cwēn>> or <<cwēne>>)
# <<brȳd||bride>> (likewise)
# <<benċ||bench>> (likewise)
# <<fierd||army>> (likewise)
]==],
			neuter_examples = [==[
# <<spere||spear>>
# <<orleġe||fate>>
# <<sife||sieve>>
]==], 
		},
		["<u>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-a>",
			nom_pl = "<-a>",
			footer = "The only remnants of a neuter <u>-stem are Northumbrian <<feolu||much>> and West Saxon plural <<fela|fela, feola|many>>. Original {{m+|gem-pro|*fehu}} become <a>-stem <<feoh>> in prehistoric {OE}.",
			examples = [==[
# <<sunu||son|g=m>>
# <<feld||field|g=m>>
# <<duru||door|g=f>>
# <<hand||hand|g=f>>
]==], 
		},
		["GENDER <n>-stem"] = {
			possible_genders = {"masculine", "feminine", "neuter"},
			masculine_nom_sg = "<-a>",
			feminine_nom_sg = "<-e>",
			neuter_nom_sg = "<-e>",
			gen_sg = "<-an>",
			nom_pl = "<-an>",
			footer = "This represents the merger of masculine and neuter <an>-stems and feminine <ōn>-stems, with the only difference remaining in the nominative singular (and neuter accusative singular). There were also <jan>/<ijan>-stems and <jōn>/<ijōn>-stems (indistinguishable from plain <n>-stems except by the presence of {i_umlaut}, {WGG} after light stems and {PAL} after velars) and <wan>-stems and <wōn>-stems (indistinguishable from plain <n>-stems except sometimes by the presence of <-w-> in the stem).",
			masculine_examples = [==[
# <<nama||name>>
# <<frēa||lord>>, from {{m+|gmw-pro|frawō}} (a <wan>-stem), from {{m+|gem-pro|*frawjô}} (a <jan>-stem)
# <<dēma||judge>> (<ijan>-stem, with {i_umlaut})
# <<wreċċa||exiled person>> (<jan>-stem with {i_umlaut}, {WGG} and {PAL})
# <spearwa||sparrow>> (<wan>-stem)
]==],
			feminine_examples = [==[
# <<tunge||tongue>>
# <<bēo||bee>>, from {{m+|gem-pro|*bijō}} (<jōn>-stem)
# <<bēċe||beech tree>> (<ijōn-stem>, with {i_umlaut} and {PAL})
# <<wiċċe||witch>> (<jōn>-stem, with {i_umlaut}, {WGG} and {PAL})
# <<swealwe||swallow>> (<wōn>-stem)
]==],
			neuter_examples = [==[
# <<ēage||eye>>
# <<ēare||ear>>
# <<wange||cheek>>
]==],
		},
		["consonant stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "a null ending",
			feminine_nom_sg = "<-u> after light stems, no ending after heavy stems",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "either a null ending with {i_umlaut} or <-e> without {i_umlaut} after heavy stems, but only <-e> without {i_umlaut} after light stems",
			masculine_nom_pl = "a null ending with {i_umlaut}",
			feminine_nom_pl = "a null ending with {i_umlaut} after heavy stems, <-e> with {i_umlaut} after light stems",
			footer = "The dative singular also had {i_umlaut}, and was identical to the nominative/accusative plural.",
			masculine_examples = [==[
# <<fōt||foot>> (dative singular, nominative/accusative plural <<fēt>>)
# <<tōþ||tooth>> (dative singular, nominative/accusative plural <<tēþ>>)
# <<mann||man>> (dative singular, nominative/accusative plural <<menn>>)
]==],
			feminine_examples = [==[
# <<bōc||book>> (genitive singular <<bēċ>> or <<bōce>>; dative singular, nominative/accusative plural <<bēċ>> with {PAL})
# <<gāt||goat>> (genitive singular <<gǣt>> or <<gāte>>; dative singular, nominative/accusative plural <<gǣt>>)
# <<burg||city>> (genitive singular <<byrġ>>, <<byriġ>> or <<burge>>; dative singular, nominative/accusative plural <<byrġ>>, <<byriġ>> with {PAL})
# <<hnutu||nut>> (genitive singular <<hnute>>; dative singular, nominative/accusative plural <<hnyte>>)
# <<furh||furrow>> (genitive singular <<fūre>> or <<fyrh>>; dative singular, nominative/accusative plural <<fyrh>>; genitive plural <<fūra>>, dative plural <<fūrum>>, cf. {{w|Phonological history of Old English#H-loss}})
]==],
		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-nd>",
			gen_sg = "<-ndes>",
			nom_pl = "<-nd> with or without {i_umlaut}, <-nde> or <-ndas>",
			parent = "consonant stem",
			footer = "There were two variants, largely monosyllabic nouns with optional {i_umlaut} in the dative singular and nominative/accusative plural, such as <<frēond||friend>>, and polysyllabic agent nouns in <-end>, without {i_umlaut} or in some cases with {i_umlaut} throughout the paradigm, when derived from a verb with {i_umlaut} in its stem.",
			examples = [==[
# <<frēond||friend>> (dative singular <<frīend>> or <<frēonde>>; nominative/accusative plural <<frīend>>, <<frēond>> or <<frēondas>>)
# <<fēond||enemy>> (like <<frēond>>)
# <<tēond||accuser>> (like <<frēond>>)
# <<gōddōnd||benefactor>> (nominative/accusative plural <<gōddōnd>> or <<gōddēnd>>)
# <<wīgend||warrior>> (without {i_umlaut})
# <<āgend||owner>> (wihtout {i_umlaut})
# <<hǣlend||savior>> (with original infix <*-ij-> causing {i_umlaut} of the stem)
# <<hettend||enemy>> (with original infix <*-j-> causing {i_umlaut} of the stem and {WGG})
]==],
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-or> or <-er>",
			gen_sg = "same as nominative singular, sometimes with {i_umlaut}",
			nom_pl = "<-ra>, <-ru>; <-as> for <<fæder>>",
			parent = "consonant stem",
			footer = "There were only seven words in this declension class (five regular kinship terms and two collective kinship terms), and each declined differently.",
			examples = [==[
# <<fæder||father|g=m>>
# <<brōþor||brother|g=m>>
# <<mōdor||mother|g=f>>
# <<dohtor||daughter|g=f>>
# <<sweostor||sister|g=f>>
# <<ġebrōþor|ġebrōþor, ġebrōþru|brothers|g=m-p>>
# <<ġesweostor|ġesweostor, ġesweostru, ġesweostra|sisters|g=f-p>>
]==],
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "a null ending",
			gen_sg = "<-es>",
			nom_pl = "<-ru>",
			parent = "consonant stem",
			footer = "This was a relic class in {OE}. The vast majority of nouns in this class in {PWG} were transferred to another class in prehistoric {OE}, sometimes changing gender in the process. Doublets were frequent, e.g. <<gāst>> and <<gǣst||spirit, breath>>; <<sigor>> and <<sige||victory>>; <<dōgor>> and Northumbrian <<dœ̄ġ||day>>; <<hālor>> and <<hǣl||health, salvation>>; <<salor>> and <<sæl||hall>>; <<hlǣw>> and <<hlāw||mound, hill>>. Note that {i_umlaut} is expected in the genitive/dative singular and throughout the plural (and in fact is present in the plural in {OHG}), but was eliminated in {OE} by analogy.",
			examples = [==[
# <<lamb||lamb>>
# <<ċealf||calf>>
# <<ǣġ||egg>>
# <<ċild||child>> (nominative/accusative plural <<ċild>> or <<ċildru>>)
]==],
		},
	},
	goh = {
		vars = {
			gmw_gen_a_stem_to_goh = "West Germanic genitive <*-as> was replaced by <-es>, which is thought by Ringe to have been borrowed from adjectives, which in turn took the ending from <<des|þes, des|of this/that>>, whose ending is analogical after <<gem-pro+:*es||of him/it>> and <<gem-pro:*hwes||of whom>>.",
			gmw_masc_pl_a_stem_to_goh = "Masculine plural {verner} variant <*-ō> (from {PG} <*-ôz>) was generalized in {OHG} and lowered to <-ā>.",
			gmw_neut_pl_a_stem_to_goh = "Unlike in {OE}, neuter plural <-u> was dropped in all words, both light-stem ({light_stem_expl}) and heavy-stem.",

			gmw_nom_o_stem_to_goh = "West Germanic accusative singular <*-ā> shortened to <-a> and was extended to the nominative singular, where {PWG} <*-u> had been lost (compare neuter plurals, with the same {PWG} ending).",
			gmw_gen_o_stem_to_goh = "West Germanic genitive singular <*-ā> shortened to <-a>, as in the accusative singular.",
			gmw_pl_o_stem_to_goh = "West Germanic nominative plural <*-ō> was lowered to <-ā>, similarly to the nominative plural of <a>-stems.",
		},
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "a null ending",
			masculine_nom_sg = "a null ending",
			neuter_nom_sg = "a null ending",
			gen_sg = "<-es>; later <-as>",
			masculine_nom_pl = "<-ā> (later <-a>)",
			neuter_nom_pl = "a null ending",
			masculine_examples = [==[
# <<tag||day>>
# <<kuning||king>>
# <<ackar||acre, field>> (genitive <<ackres>>)
]==],
			neuter_examples = [==[
# <<wort||word>>
# <<barn||child>>
# <<zwīfal||doubt>> (genitive <<zwīfles>>)
]==],
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-i>",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-e> (later <-ā>, becoming <-a>)",
			neuter_nom_pl = "<-i>",
			parent = "GENDER <a>-stem",
			footer = "{OHG} <ja>-stems have {i_umlaut} throughout the paradigm, although it is not represented in spelling except when the Proto-West Germanic root vowel was <*a>, becoming {OHG} <e>, e.g. <<betti||bed>> from {{m+|gmw-pro|*badi}}~{{m|gmw-pro|*baddja}} with {WGG}. Early 9th century <ja>-stems still included the {{ic|/j/}} glide in many inflections, e.g. dative singular <-ie>, instrumental singular <-iu>, genitive plural <-eo> or <-io>, but it was soon dropped, with the inflections merging with plain <a>-stems except in the nominative/accusative singular (compare a similar development in {OE}).",
			masculine_examples = [==[
# <<hirti||herdsman>>
# <<lērāri||teacher>>
# <<rucki||back>> (with {WGG})
]==],
			neuter_examples = [==[
# <<enti||end>> (with visible {i_umlaut})
# <<kunni||race, kind>> (with {WGG})
# <<heri||army>> (genitive <<heries>>, with no {WGG} and preserved {{ic|/j/}} after {{ic|/r/}})
]==],
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-o>; sometimes dropped when directly following long vowel and forming a diphthong after a short vowel",
			gen_sg = "<-wes>; after a consonant, <-awes> or sometimes <-ewes>, with an [[epenthetic]] vowel",
			masculine_nom_pl = "<-ā> (later <-a>)",
			neuter_nom_pl = "{nom_sg}",
			parent = "GENDER <a>-stem",
			masculine_examples = [==[
# <<snēo|snēo, snē|snow>> (genitive <<snēwes>>)
# <<scato||shadow>> (genitive <<scatawes>>)
# <<bū||dwelling>> (genitive <<būwes>>)
]==],
			neuter_examples = [==[
# <<kneo||knee>> (genitive <<knëwes>>)
# <<trëso||treasure>> (genitive <<trësawes>>)
# <<rēo|rēo, rē|corpse>> (genitive <<rēwes>>)
]==],
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-a> (sometimes <-u> or <-o>)",
			nom_pl = "<-ā>",
			footer = "The {OHG} nominative ending <-a> was taken from the accusative; the expected nominative would be <#-u> or no ending.",
			examples = [==[
# <<gëba||gift>>
# <<ërda||earth>>
# <<triuwa||fidelity>>
]==],
		},
		["<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-e>, <-ea>, <-ia> (early); <-a> (later)",
			gen_sg = "{nom_sg}",
			nom_pl = "<-e>, <-eā>, <-iā> (early); <-ā> (later)",
			parent = "<ō>-stem",
			footer = "{OHG} <jō>-stems have {i_umlaut} throughout the paradigm, although it is not represented in spelling except when the {PWG} root vowel was <*a>, becoming {OHG} <e>, e.g. <<hella|hella, helle, hellea|hell>> from {{m+|gmw-pro|*hallju}} with {WGG}. Early 9th century <jō>-stems still included the {{ic|/j/}} glide in many inflections, e.g. dative singular <-iu>, genitive plural <-eōno>, but it was soon dropped, with the inflections merging with plain <ō>-stems. Feminines in <-in> such as <<kuningin||queen>>, <<friuntin||female friend>> preserve the {PWG} and {PG} <<c:gmw-pro:<ī>/<jō>-stem nouns|<ī>/jō> noun>> declension, with original nominative in <*-ī> dropped and remaining forms reflecting {WGG}. (Later {OHG} variants of these nouns ended in <-inna>, showing merger with <ō>-stems.)",
			examples = [==[
# <<sunta|sunta, sunte, suntea|sin>>
# <<hella|hella, helle, hellea|hell>> (with visible {i_umlaut} and {WGG})
# <<kuningin||queen>> (genitive <<kuninginna>>)
]==],
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			nom_sg = "no ending, without {i_umlaut}; occasionally <-i> after light stems ({light_stem_expl}), with {i_umlaut}",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "<-i> with {i_umlaut}",
			nom_pl = "<-i> with {i_umlaut}",
			footer = [==[
In {OHG}, masculine <i>-stems were restructured in the singular to take <a>-stem endings, prior to {i_umlaut}, but kept <i>-stem endings in the plural. (There were two exceptions: (1) the instrumental singular preserved the ending <-iu> through the early 9th century and accordingly sometimes had {i_umlaut}, as in instrumental singular <<gastiu>> or <<gestiu>> of <<gast||guest>>; and (2) the nominative/accusative singular of a few nouns with light stems preserved the original <-i> ending, such as <<wini||friend>>, <<quiti||saying>>; but compare <<slag||blow, strike, hit>> without the <-i> ending or {i_umlaut}, and contrast the cognate <<ang:sleġe>> with {ang:I-UMLAUT} and a reflex of {PWG} <-i>.) Feminine nouns mostly dropped the original <-i> in the nominative and accusative prior to {i_umlaut} (which seems to have been a regular development in heavy stems that was analogically carried over to some light stems), but otherwise kept the <i>-stem endings. The result was a paradigm with {i_umlaut} throughout the plural, but not in the singular except in the feminine genitive and dative singular. (Exceptionally, feminine <<turi||door>> and <<kuri||choice>> maintained original <-i> in the nominative/accusative singular, leading to {i_umlaut} throughout the paradigm; cf. modern {{m+|de|Tür||door|g=f}}, {{m|de|Kür||choice|g=f|ll=poetic}}. This did not apply to most light-stem feminines, cf. <<stat||place>> without {i_umlaut} and contrast cognate <<ang:stede>> with {ang:I-UMLAUT} and a reflex of {PWG} <-i>.)

The development of {i_umlaut} in the plural of this paradigm, combined with similar inherited behavior in consonant stems, <z>-stems and <r>-stems, led to {i_umlaut} becoming a mark of the plural. This subsequently spread to many <a>-stem nouns, such as modern {{m+|de|Nagel||nail}} and {{m|de|Hammer||hammer}}, with non-original umlauted plurals ''Nägel'' and ''Hämmer''.
]==],
			masculine_examples = [==[
# <<gast||guest>> (nominative plural <<gesti>>)
# <<wurm||worm>>
# <<aphul||apple>> (nominative plural <<ephili>>)
# <<slag||blow, strike, hit>> (nominative plural <<slegi>>)
# <<wini||friend>>
]==],
			feminine_examples = [==[
# <<anst||favor>> (genitive singular, nominative plural <<ensti>>)
# <<jugund||youth>>
# <<gift||gift>>
# <<turi||door>>
]==],
		},
		["GENDER <an>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-o>",
			neuter_nom_sg = "<-a>",
			gen_sg = "<-en>, <-in>",
			masculine_nom_pl = "<-on>, <-un>",
			neuter_nom_pl = "<-un>, <-on>",
			parent = "n-stem",
			masculine_examples = [==[
# <<namo||name>>
# <<wahsmo||fruit>>
# <<stërno||star>>
# <<gomo||man>>
]==],
			neuter_examples = [==[
# <<hërza||heart>>
# <<ouga||eye>>
# <<ōra||ear>>
]==],
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-ūn>",
			nom_pl = "<-ūn>",
			parent = "n-stem",
			examples = [==[
# <<zunga||tongue>>
# <<quëna||woman>>
# <<sunna||sun>>
]==],
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ī>",
			gen_sg = "<-ī>",
			nom_pl = "<-ī>",
			parent = "n-stem",
			footer = "{OHG} <īn>-stems have {i_umlaut} throughout the paradigm (cf. {{m+|de|Höhe||height}} < {OHG} <<hōhī>>, {{m+|de|Süße||sweetness}} < {OHG} <<suoȥȥī>>), although it is usually represented in spelling. This paradigm is indeclinable except for genitive plural <-īno>, dative plural <-īm> (later <-īn>).",
			examples = [==[
# <<hōhī||height>>
# <<snëllī||quickness>>
# <<tiufī||depth>>
# <<menigī|menigī, managī|multitude>>
# <<toufī||dipping, baptism>>
# <<welī||choice>> (with visible {i_umlaut})
]==],
		},
		["<u>-stem"] = {
			gender = "masculine or or rarely neuter",
			nom_sg = "<-u> after light stems; no examples with heavy stems",
			gen_sg = "<-es>",
			nom_pl = "<-i> with {i_umlaut} when masculine; unattested when neuter",
			footer = "<u>-stems are a relic class in {OHG}. Only 6 masculine nouns, all light-stem, maintain original <-u> in the nominative/accusative singular, otherwise behaving as <i>-stems: <<situ||custom>>, <<fridu||peace>>, <<hugu||understanding>>, <<sigu||victory>>, <<witu||wood>> and <<sunu||son>> (also found as <<sun>>). All remaining <u>-stems inherited from {PWG} have been moved completely to become <i>-stems or sometimes <a>-stems. Only one neuter <u>-stem remains, <<fihu||cattle>>, which behaves as an <a>-stem in the oblique singular and is unattested in the plural. No feminine <u>-stems remain, but the <i>-stem noun <<hant||hand>> maintains a vestige of its original <u>-stem declension in the dative plural <<hantum>> (later <<hantun>>, <<hanton>>), in place of expected #<<hantim>>.",
		},
		["consonant stem"] = {
			gender = "masculine or feminine",
			nom_sg = "a null ending",
			gen_sg = "<-es> when masculine; a null ending when feminine",
			nom_pl = "a null ending",
			footer = "This is a relic class in {OHG}. Most consonant stems have been converted to <i>-stems. The remaining nouns are distinguished by a null ending in the dative singular and nominative/accusative plural, without the expected {i_umlaut} (all such nouns are heavy-stem and as a result the original <-i> ending was regularly dropped prior {i_umlaut} taking place; compare the same development in the nominative/accusative singular of <i>-stems).",
			examples = [==[
# <<man||man|g=m>> (genitive <<mannes>>)
# <<naht||night|g=f>>
# <<buoch||book>> (neuter in the singular with genitive <<buoches>>, feminine in the plural)
# <<burg||city|g=f>> (which could be either a consonant stem or <i>-stem)
# <<brust||breast|g=f>> (like <<burg>>)
# <<fuoȥ||foot|g=f>> (moved to the <i>-stems but maintained consonant-stem dative plural <<fuoȥum>>, later <<fuoȥun>>, <<fuoȥon>>)
]==],
		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-nt>",
			gen_sg = "<-ntes>",
			nom_pl = "<-nt>, or <-ntā> (later <-nta>)",
			parent = "consonant stem",
			footer = "This contained present participles used as nouns as well as <<friunt||friend>>. This class had nearly merged with <a>-stems, the only difference being the nominative/accusative plural, which could have a null ending.",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-er>",
			gen_sg = "<-er>; also <-eres> for <<fater>>",
			nom_pl = "<-er>; <-erā>/<-era> for <<fater>>",
			parent = "consonant stem",
			footer = "There were only five words in this declension class.",
			examples = [==[
# <<bruoder||brother>>
# <<muoter||mother>>
# <<tohter||daughter>>
# <<swëster||sister>>
# <<fater||father>> (with <a>-stem endings in the plural and alternatively in the singular as well)
]==],
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "a null ending",
			gen_sg = "<-es>",
			nom_pl = "<-ir> with {i_umlaut}",
			parent = "consonant stem",
			footer = "This was a relic class in {OHG} that later expanded considerably. The singular had assimilated to <a>-stem endings (originally the genitive and dative singular had the <-ir-> infix as well) but the plural maintained the <-ir> infix, which triggered {i_umlaut}.",
			examples = [==[
# <<lamb||lamb>>
# <<kalb||calf>>
# <<blat||leaf>>
# <<grab||grave>>
]==],
		},
	},
}

require(category_tree_utilities_module).add_inflection_handler {
	handlers = handlers,
	poses = {"noun"},
	stem_classes = function(handdata)
		return noun_decls[handdata.lang:getCode()]
	end,
	principal_parts = {
		{"nom_sg", "nominative singular"},
		{"gen_sg", "genitive singular"},
		{"nom_pl", "nominative plural"},
	},
	mark_up_spec = function(data, handdata, spec, nolink)
		-- umlauts
		spec = spec:gsub("{([Uu])%-umlaut}", "{{w|Old Norse#U-umlaut|%1-umlaut}}")
		spec = spec:gsub("{([Ii])%-umlaut}", function(i)
			local wikilink
			local langcode = handdata.lang:getFullCode()
			if langcode == "non" then
				wikilink = "Old Norse#Umlaut"
			elseif langcode == "ang" then
				wikilink = "Germanic umlaut#I-mutation in Old English"
			elseif langcode == "goh" then
				wikilink = "Germanic umlaut#I-mutation in High German"
			elseif langcode == "osx" then
				wikilink = "Germanic umlaut#I-mutation in Old Saxon"
			elseif langcode == "odt" then
				wikilink = "Germanic umlaut#I-mutation in Dutch"
			else
				wikilink = "Germanic umlaut"
			end
			return ("{{w|%s|%s-umlaut}}"):format(wikilink, i)
		end)
		return require(category_tree_utilities_module).default_mark_up_spec(data, handdata, spec, nolink)
	end,
	footer = "The stem classes are named from the perspective of [[:Category:Proto-Germanic language|Proto-Germanic]] and may not still be visible in {{{langname}}} inflections.",
}

for _, pos in ipairs({"nouns"}) do
	local sgpos = pos:gsub("s$", "")
	for _, decl in ipairs { "a", "i", "īn", "n", "nd", "ō", "u", "z" } do
		labels[decl .. "-stem " .. pos] = {
			displaytitle = "{{{langname}}} ''" .. decl .. "''-stem " .. pos,
			description = "{{{langname}}} ''" .. decl .. "''-stem " .. pos .. ".",
			additional = function(data) if data.lang:getCode() ~= "gem-pro" then
				return "Note that the stem class is named from the perspective of Proto-Germanic, and the stem suffix may no longer be visible synchronically."
			end end,
			breadcrumb = {name = "''" .. decl .. "''-stem", nocap = true},
			parents = {{
				name = pos .. " by inflection type",
				sort = decl,
			}},
		}
	end
end

for _, decl in ipairs({"n"}) do
	for _, gender in ipairs { "masculine", "feminine", "neuter" } do
		labels[gender .. " " .. decl .. "-stem nouns"] = {
			displaytitle = "{{{langname}}} " .. gender .. " ''" .. decl .. "''-stem nouns",
			description = "{{{langname}}} " .. gender .. " ''" .. decl .. "''-stem nouns.",
			breadcrumb = {name = gender},
			parents = {{
				name = decl .. "-stem nouns",
				sort = gender,
			}},
		}
	end
end



-- Add 'umbrella_parents' key if not already present.
for key, data in pairs(labels) do
	if not data.umbrella_parents then
		data.umbrella_parents = "Terms by grammatical category subcategories by language"
	end
end

return {LABELS = labels, HANDLERS = handlers}
