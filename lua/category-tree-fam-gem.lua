local labels = {}

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

local ine_pro_prec_addl = {
	["<a>-stem"] = "{PIE} thematic nouns in <*-os> (masculine), <*-om> (neuter), with genitive <*-osyo> and nominative plural <*-oes> (masculine), <*-eh₂> (neuter).",
	["<i>-stem"] = "{PIE} athematic proterokinetic nouns in <*-is>, with genitive <*-eys> and nominative plural <*-eyes>.",
	["<u>-stem"] = "{PIE} athematic proterokinetic nouns in <*-us> (masculine or feminine), <*-u> (neuter), with genitive <*-ews> and nominative plural <*-ewes> (masculine or feminine), <*-uh₂> (neuter), although the {PG} genitive continues a post-PIE form <*-ows>."

local gem_pro_props = {
	["<a>-stem"] = {
		daughter_desc = "<<c:<a>-stem nouns>>, ending in <*-az> (masculine), <*-ą> (neuter).",
	},
	["<ja>-stem"] = {
		daughter_desc = "<<c:<ja>-stem nouns>>, ending in <*-jaz> (masculine), <*-ją> (neuter), which are effectively <a>-stem nouns with a stem suffix <*-j->.",
		addl_intro = "Due to {{w|Sievers' Law}}, these nouns only occur with light stems (those with a short root vowel followed by a single consonant); otherwise the stem suffix appears as <*-ij-> (see <<c:<ija>-stem nouns>>). In {PG}, the endings were nearly the same as for plain <a>-stem nouns, but the two classes diverged in most daughter languages.",
		umlaut = {"i"},
	},
	["<ija>-stem"] = {
		daughter_desc = "<<c:<ija>-stem nouns>>, ending in <*-ijaz> (masculine), <*-iją> (neuter), which are effectively <a>-stem nouns with a stem suffix <*-ij->.",
		addl = "Due to {{w|Sievers' Law}}, these only occur after heavy stems (those with a long root vowel or diphthong, or a short vowel followed by a two or more consonants); otherwise the stem suffix appears as <*-j-> (see <<c:<ja>-stem nouns>>). In {PG}, the endings were nearly the same as for plain <a>-stem nouns, but the two classes diverged in most daughter languages.",
		umlaut = {"i"},
	},
	["<wa>-stem"] = {
		daughter_desc = "<<c:<a>-stem nouns>> with a stem suffix <*-w->.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes.",
		umlaut = {"u"},
	},
	["<ō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>>, ending in <*-ō> and always feminine.",
		addl = "The ending was raised to {{ic|/u/}} in North Germanic and West Germanic, which triggered {U-UMLAUT} in Old Norse.",
	},
	["<jō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>> with a stem suffix <*-j->, which triggered {I-UMLAUT}.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with light stems (those with a short root vowel followed by a single consonant), due to {{w|Sievers' Law}}; the corresponding heavy-stem nouns had a stem suffix <*-ij->. See also the related <<c:<ī>/<jō>-stem nouns|<ī>/<jō>-stem>> class of nouns.",
	},
	["<ijō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>> with a stem suffix <*-ij->, which triggered {I-UMLAUT}.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with heavy stems (those with a long root vowel or diphthong, or a short vowel followed by a two or more consonants), due to {{w|Sievers' Law}}; the corresponding light-stem nouns had a stem suffix <*-j->. See also the related <<c:<ī>/<jō>-stem nouns|<ī>/<jō>-stem>> class of nouns.",
	},
	["<ī>/<jō>-stem"] = {
		daughter_desc = "<<c:<ī>/<jō>-stem nouns>>, ending in <*-ī> in the nominative/vocative singular but otherwise having <ō>-stem endings with a stem suffix <*-ij->.",
		addl = "These nouns have {I-UMLAUT} in the ",
	},
	["<wō>-stem"] = {
		daughter_desc = "<<c:<ō>-stem nouns>> with a stem suffix <*-w->.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes.",
	},
	["<i>-stem"] = {
		daughter_desc = "<<c:<i>-stem nouns>>, ending in <*-iz> (masculine or feminine), <*-i> (neuter).",
		addl = "<i>-stem neuters were rare in {PG} and disappeared in most daughter languages).",
	},
	["<u>-stem"] = {
		daughter_desc = "<<c:<u>-stem nouns>>, ending in <*-uz> (masculine or feminine), <*-u> (neuter).",
		addl = "<u>-stem neuters were rare in {PG} but survived in many daughter languages, particularly reflexes of {{m+|gem-pro|*fehu||livestock, cattle, property, wealth}}).",
	},
	["<an>-stem"] = {
		daughter_desc = "<<c:<an>-stem nouns>>, which were masculine or neuter in {PG} and ended in overlong <*-ô>, with an <*-n-> formant throughout the oblique and plural forms.",
		addl = "This class, along with the corresponding feminine <ōn>-stem nouns, was continued in all daughter languages, where it is the origin of so-called \"weak\" nouns. The <*-n-> format disappears in North Germanic due to loss of word-final <*-n>, but is maintained in most West Germanic languages.",
	},
	["<ōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>>, which were feminine in {PG} and ended in <*-ǭ>, with an <*-ōn-> formant throughout the oblique and plural forms.",
		addl = "This class, along with the corresponding masculine and neuter <ōn>-stem nouns, was continued in all daughter languages, where it is the origin of so-called \"weak\" nouns. The <*-n-> format disappears in North Germanic due to loss of word-final <*-n>, but is maintained in most West Germanic languages.",
	},
	["<jōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>> with a stem suffix <*-j->.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with light stems (those with a short root vowel followed by a single consonant), due to {{w|Sievers' Law}}; the corresponding heavy-stem nouns had a stem suffix <*-ij->.",
	},
	["<ijōn>-stem"] = {
		daughter_desc = "<<c:<ōn>-stem nouns>> with a stem suffix <*-ij->.",
		addl = "This was not a distinct class in {PG}, but developed into one in many daughter languages due to sound changes. In {PG}, these nouns only occurred with heavy stems (those with a long root vowel or diphthong, or a short vowel followed by a two or more consonants), due to {{w|Sievers' Law}}; the corresponding light-stem nouns had a stem suffix <*-j->.",
	},
	["<īn>-stem"] = {
		daughter_desc = "<<c:<īn>-stem nouns>>, a class of feminine abstract nouns ending in <*-į̄> in {PG}, with an <*-īn> formant throughout the oblique and plural forms.",
		addl = "In most daughter languages, the oblique forms all merged to have the same ending, in many cases borrowing the ending of the nominative and in the process becoming indeclinable. {OE} replaced the original <-i> ending with the <-u> ending of <ō>-stems, but the original ending left its mark in {I-UMLAUT} in all forms.",
	},
	["<z>-stem"] = {
		daughter_desc = "<<c:<z>-stem nouns>>, neuter in {PG} and ending in <*-az> with genitive <*-iziz> and nominative/accusative plural <*-izō>.",
		addl = "This class was numerous in {PG} but become rare in daughter languages due to the effects of {I-UMLAUT}, which operated in cases with the <*-iz-> formant, i.e. the oblique singular and throughout the plural but not in the nominative or accusative singular. Usually, either the umlauted or non-umlauted stem was generalized throughout the paradigm and the noun moved to another declension, although which stem was generalized, which declension the noun ended up in, and whether the <*-z-> formant (which developed into an {{ic|/r/}} in North and West Germanic) was incorporated into the stem varied from language to language, often resulting in doublets within a single language. This class survived as a relic class in the West Germanic languages (ironically becoming productive again in modern German as a common way of forming neuter plurals). This class should not be confused with <<c:<r>-stem nouns|<r>-stem nouns>>, which are masculine or feminine and predominantly kinship terms.",
	},
	["<r>-stem"] = {
		daughter_desc = "<<c:<r>-stem nouns>>, ending in <*-ēr>.",
		addl = "This was a small class of common kinship nouns in {PG} and was continued in most daughter languages, but the nouns often developed irregularities which differed from noun to noun. This class should not be confused with neuter <<c:<z>-stem nouns|<z>-stem nouns>>, which also contained an {{ic|/r/}} stem formant in North and West Germanic and was also a relic class.",
	},
}


--[=[
Noun declension specifications. The top-level key is the stem class, and the value is an object containing properties of
the stem class. If the stem class contains the word 'GENDER' in it, it expands into labels both for a parent category
that subsumes several genders (obtained by removing the word 'GENDER' and following whitespace) as well as
gender-specific children categories (obtained by replacing the word 'GENDER' with the genders specified in the
`possible_genders` field). The stem class can contain literal Latin-script text (e.g. suffixes), which will be
italicized in breadcrumbs and titles. The fields of the property object for a given stem class are as follows:
* `gender`: The description of the gender(s) of the stem class. If preceded by ~, the description is preceded by
  "most commonly". This appears in the `additional` field of the label properties. It is not used in gender-specific
  children categories; instead the gender of that category is used.
* `possible_genders`: The possible genders this class occurs in. If this is specified, the word 'GENDER' must occur in
  the stem class, and gender-specific variants of the stem class (with GENDER replaced by the possible genders) are
  handled along with a parent category subsuming all genders. 
* `nom_sg`: The nominative singular ending. Use <...> to enclose literal Latin-script text (e.g. suffixes), which will
  be italicized.
* `GENDER_nom_sg`: The nominative singular ending for the GENDER variant of this stem class. If not specified, the
  value of `nom_sg` is used.
* `gen_sg`: The genitive singular ending. Conventions are the same as for `nom_sg`.
* `GENDER_gen_sg`: The genitive singular ending for the GENDER variant of this stem class. If not specified, the value
  of `gen_sg` is used.
* `nom_pl`: The nominative plural ending. Conventions are the same as for `nom_sg`.
* `GENDER_nom_pl`: The nominative plural ending for the GENDER variant of this stem class. If not specified, the value
  of `nom_pl` is used.
* `breadcrumb`: The breadcrumb for the category, appearing in the trail of breadcrumbs at the top of the page. If this
  stem has gender-specific variants, the breadcrumb specified here is used only for the parent category, while the
  gender-specific child categories use the gender as the breadcrumb. If not specified, it defaults to `sortkey`. If that
  is also not specified, or if the breadcrumb has the value "+", the stem class (without the word 'GENDER') is used.
  (Use "+" when a sortkey is specified but the stem class should be used as the breadcrumb.)
* `parent`: The parent category or categories. If specified, the actual category label is formed by appending the part
  of speech (e.g. "nouns"). Defaults to "POS by inflection type" where POS is the part of speech. Note that
  gender-specific child categories do not use this, but always have the gender-subsuming parent stem class category as
  their parent.
* `sortkey`: The sort key used for sorting this category among its parent's children. Defaults to the stem class
  (without the word 'GENDER'). Note that gender-specific child categories do nto use this, but always use the gender
  as the sort key.
]=]
local noun_decls = {
	["gem-pro"] = {
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<*-az>",
			neuter_nom_sg = "<*-ą>",
			gen_sg = "<*-as> or <*-is> (depending on the reconstruction, the particular word and/or the dialect)",
			masculine_nom_pl = "<*-ōz> or <*-ōs> (depending on the reconstruction, the particular word and/or the dialect)",
			neuter_nom_pl = "<*-ō>",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<*-jaz>",
			neuter_nom_sg = "<*-ją>",
			gen_sg = "<*-jas> or <*-is> (depending on the reconstruction, the particular word and/or the dialect)",
			masculine_nom_pl = "<*-jōz> or <*-jōs> (depending on the reconstruction, the particular word and/or the dialect)",
			neuter_nom_pl = "<*-jō>",
			parent = "<a>-stem",
		},
		["GENDER <ija>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<*-ijaz>",
			neuter_nom_sg = "<*-iją>",
			gen_sg = "<*-ijas> or <*-īs> (depending on the reconstruction, the particular word and/or the dialect)",
			masculine_nom_pl = "<*-ijōz> or <*-ijōs> (depending on the reconstruction, the particular word and/or the dialect)",
			neuter_nom_pl = "<*-ijō>",
			parent = "<a>-stem",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ō>",
			gen_sg = "<*-ōz>",
			nom_pl = "<*-ôz>",
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
	["gmw-pro"] = {
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "the bare stem",
			gen_sg = "<*-as>",
			masculine_nom_pl = "<*-ō> or <*-ōs>",
			neuter_nom_pl = "<*-u>",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<*-i>",
			gen_sg = "<*-jas> with {WGG}",
			masculine_nom_pl = "<*-jō> or <*-jōs> with {WGG}",
			neuter_nom_pl = "<*-ju> with {WGG}",
			parent = "<a>-stem",
		},
		["GENDER <ija>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<*-ī>",
			gen_sg = "<*-ijas>",
			masculine_nom_pl = "<*-ijō> or <*-ijōs> after a heavy root, <*-jō> or <*-jōs> with {WGG} after a light root",
			neuter_nom_pl = "<*-iju> after a heavy root, <*-ju> with {WGG} after a light root",
			parent = "<a>-stem",
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<*-u>",
			gen_sg = "<*-was>",
			masculine_nom_pl = "<*-wō> or <*-wōs>",
			neuter_nom_pl = "<*-u>",
			parent = "<a>-stem",
		},
		["<i>-stem"] = {
			gender = "masculine, feminine or neuter",
			nom_sg = "<*-i>",
			gen_sg = "<*-ī>",
			nom_pl = "<*-ī>",
			addl = "In {PG}, the masculine and feminine <i>-stems differed from the neuter <i>-stems in the " ..
			"nominative and accusative, but later sound changes caused the two classes to converge.",
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
			nom_sg = "the bare stem",
			gen_sg = "<*-i> (with {I-UMLAUT} of roots in <*-e->)",
			nom_pl = "[:gen_sg:]",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<*-er>",
			gen_sg = "?",
			nom_pl = "?",
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "the bare stem",
			gen_sg = "<*-iʀi> (with {I-UMLAUT} of roots in <*-e->)",
			nom_pl = "<*-iʀu> (with {I-UMLAUT} of roots in <*-e->)",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-u>",
			gen_sg = "<*-ā>",
			nom_pl = "<*-ō>",
		},
		["<ī>/<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-ī>",
			gen_sg = "<*-ijā> after a heavy stem, <*-jā> with {WGG} after a light stem",
			nom_pl = "<*-ijō> after a heavy stem, <*-jō> with {WGG} after a light stem",
			parent = "<ō>-stem",
		},
		["<wō>-stem"] = {
			gender = "feminine",
			nom_sg = "<*-u>",
			gen_sg = "<*-wā>",
			nom_pl = "<*-wō>",
			parent = "<ō>-stem",
		},
	},
	got = {
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-s>",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-is>",
			masculine_nom_pl = "<-ōs>",
			neuter_nom_pl = "<-a>",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-jis>",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-jis>",
			masculine_nom_pl = "<-jōs>",
			neuter_nom_pl = "<-ja>",
		},
		["GENDER <ija>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-eis>",
			neuter_nom_sg = "<-i>",
			masculine_gen_sg = "<-eis>",
			neuter_gen_sg = "<-jis>",
			masculine_nom_pl = "<-jōs>",
			neuter_nom_pl = "<-ja>",
			addl = "In Gothic, neuter <ija>-stems have merged with <ja>-stems but masculine <ija>-stems remain distinct, hence the difference in the genitive singular.",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-ōs>",
			nom_pl = "<-ōs>",
		},
		["<ī>/<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-i>",
			gen_sg = "<-jōs>",
			nom_pl = "<-jōs>",
			parent = "ō-stem",
			addl = "Not to be confused with [[:Category:Gothic i/ō-stem nouns|<i>/<ō>-stems]], all of which have a suffix element <-ein-> followed by a mixture of <i>-stem and <ō>-stem endings.",
		},
		["<i>/<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-eins>",
			gen_sg = "<-einais>",
			nom_pl = "<-einōs>",
			parent = {"feminine i-stem", "ō-stem"},
			addl = "This is a special, highly productive class of abstract nouns that was innovated in Gothic and had a mixture of <i>-stem and <ō>-stem endings after a suffix element <-ein->. Not to be confused with [[:Category:Gothic ī/jō-stem nouns|<ī>/<jō>-stems]], which decline like feminine <jō> stems (i.e. <ō> stems with a preceding <j>) except in the nominative and vocative singular. Also not to be confused with [[:Category:Gothic īn-stem nouns|<īn>-stems]], which are also feminine abstract nouns with an <-ein-> formant in most cases, but which take <n>-stem endings.",
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			nom_sg = "<-s>",
			masculine_gen_sg = "<-is>",
			feminine_gen_sg = "<-ais>",
			nom_pl = "<-eis>",
			addl = "In Gothic, masculine <i>-stems have been restructured in the singular on the basis of <a>-stems while feminine <i>-stems preserve the original endings (although feminine genitive singular <-ais> is formed analogically to <-aus> in <u>-stems; <#-eis> would be expected); compare a similar development in {OHG}. Both genders preserve the original endings in the plural. No neuter <i>-stems survive; the few that existed in {PG} were moved to other declensions.",
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
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-s> or sometimes <-ar>",
			masculine_nom_pl = "<-ar>",
			neuter_nom_pl = "the bare stem with {U-UMLAUT}",
			masculine_examples = [==[

# <<hestr||horse|g=m>>
# <<hǫfundr||chieftain|g=m>> (genitive <<hǫfundar>>)
# <<hauss||skull|g=m>> (with <-r> assimilated to <-s>; accusative <<haus>>)
# <<hals||neck|g=m>> (with <-r> dropped after preceding consonant + <s>; accusative <<hals>>)
# <<heiðr||honor, worth|g=m>> (with <-r> part of the stem; accusative <<heiðr>>)
# <<fleinn||arrow|g=m>> (with <-r> assimilated to <-n>; accusative <<flein>>)
# <<hamarr||hammer|g=m>> (dative <<hamri>>, with contraction)
]==],
			neuter_examples = [==[

# <<orð||word|g=n>>
# <<barn||child|g=n>> (nominative/accusative plural <<bǫrn>>, with {U-UMLAUT})
# <<hǫfuð||head|g=n>> (with contraction; dative <<hǫfði>>)
]==],
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>), or <-ir> in proper names",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-s> or sometimes <-jar>, or <-is> in proper names",
			masculine_nom_pl = "<-jar>, or <-ir> in proper names",
			neuter_nom_pl = "the bare stem",
			parent = "<a>-stem",
			addl = "This class derives from {PG} <a>-stems ending in <j> after a light root, a vowel or a velar. As a result, the stem usually has {I-UMLAUT} throughout.",
			masculine_examples = [==[

# <<niðr||kinsman, relative|g=m>> (nominative plural <<niðjar>>)
# <<herr||army|g=m>>, from {PG} <<gem-pro:*harjaz>> (nominative plural <<herjar>>)
# <<Mjǫllnir|ng=name of a Norse god|g=m>>, from {PG} <<gem-pro:*Meldunjaz>>
]==],
			neuter_examples = [==[

# <<kyn||kind, type; kin>> (genitive plural <<kynja>>)
# <<egg||egg>> (genitive plural <<eggja>>)
]==],
		},
		["GENDER <ija>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-ir>",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-is> or sometimes <-ar>",
			masculine_nom_pl = "<-ar>",
			neuter_nom_pl = "<-i>",
			parent = "<a>-stem",
			addl = "This class derives from {PG} <a>-stems ending in <ij> after a heavy root. As a result, the stem normally has {I-UMLAUT} throughout.",
			masculine_examples = [==[

# <<endir||end>>, from {PG} <<gem-pro:*andijaz>> (nominative plural <<endar>>)
# <<fylkir||chief, king>> (nominative plural <<fylkjar>>)
# <<eyrir||ounce; money>> (irregular nominative plural <<aurar>>)
]==],
			neuter_examples = [==[

# <<leyfi||permission, leave>> (genitive plural <<leyfa>>)
# <<rīki||realm>> (genitive plural <<rīkja>>)
# <<erendi||errand>> (genitive plural <<erenda>>)
]==],
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-s> or sometimes <-var>",
			masculine_nom_pl = "<-var>",
			neuter_nom_pl = "the bare stem",
			parent = "<a>-stem",
			addl = "This class derives from {PG} <a>-stems ending in <w>. As a result, the stem has {U-UMLAUT} hroughout.",
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
			gender = "feminine",
			nom_sg = "the bare stem with {U-UMLAUT}",
			gen_sg = "<-ar> without {U-UMLAUT}",
			nom_pl = "<-ar> without {U-UMLAUT}; often also <-ir> is allowed",
			examples = [==[

# <<gjǫf||gift>> (genitive <<gjafar>>, nominative/accusative plural <<gjafar>>/<<gjafir>>)
# <<fjǫðr||feather>> (genitive <<fjaðrar>>)
# <<dróttning||queen; mistress>> (dative <<dróttningu>>)
# <<brá||eyelash>> (genitive <<brár>>)
]==],
		},
		["<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "the bare stem",
			gen_sg = "<-jar>",
			nom_pl = "<-jar>",
			parent = "<ō>-stem",
			addl = "This class derives from {PG} <ō>-stems ending in <j> after a light root, a vowel or a velar. As a result, the stem has {I-UMLAUT} throughout.",
			examples = [==[

# <<ben||wound>> (genitive <<benjar>>)
# <<egg||edge>> (genitive <<eggjar>>, dative <<egg>> or <<eggju>>)
# <<þý||female slave>> (genitive <<þýjar>>, dative <<þýju>>)
]==],
		},
		["<ijō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-r>",
			gen_sg = "<-ar> (usually <-jar> after velars)",
			nom_pl = "<-ar> (usually <-jar> after velars) or sometimes <-ir>",
			parent = "<ō>-stem",
			addl = "The stem usually has {I-UMLAUT} throughout, but there are many exceptions.",
			examples = [==[

# <<mýrr||moor>>, from {PG} <<gem-pro:*miuzijō>> (nominative/accusative plural <<mýrar>>)
# <<ylgr||she-wolf>>, from {PG} <<gem-pro:*wulgī>> (nominative/accusative plural <<ylgjar>>)
# <<gunnr|gunnr, guðr|battle, war>>, from {PG} <<gem-pro:*gunþiz>> (nominative/accusative plural <<gunnar>>)
# <<hildr||battle>>, from {PG} <<gem-pro:*hildiz>> (nominative/accusative plural <<hildir>>)
]==],
		},
		["<wō>-stem"] = {
			gender = "feminine",
			nom_sg = "the bare stem",
			gen_sg = "<-var>",
			nom_pl = "<-var>",
			parent = "<ō>-stem",
			addl = "The stem has {U-UMLAUT} throughout.",
			examples = "<<ǫr||arrow>> (genitive <<ǫrvar>>); <<dǫgg||drizzle; fog; dew>> (genitive <<dǫggvar>>)",
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			feminine_nom_sg = "the bare stem with {U-UMLAUT}",
			masculine_gen_sg = "<-ar> (<-jar> after vowels, velars or sometimes other consonants) or <-s>",
			feminine_gen_sg = "<-ar>",
			nom_pl = "<-ir>",
			feminine_addl = "Feminine <i>-stem nouns have completely merged with <ō>-stem nouns in the singular, with the result that {I-UMLAUT}, which should theoretically be present throughout the paradigm, is often missing, and conversely {U-UMLAUT}, which should not be present, is normally found in the nominative and accusative singular. The genitive <-ar> is likewise borrowed from the <ō>-stems. The only thing distinguishing feminine <i>-stem nouns is the nominative/accusative plural <-ir>, whereas feminine <ō>-stem nouns use <-ar> (but often allow <-ir> as well, due to analogy with the <i>-stems). As a result of this convergence, many Old Norse <i>-stem feminines derive from original <ō>-stem nouns, and vice-versa.",
			masculine_addl = [==[

Masculine <i>-stems are closer to the original Proto-Germanic paradigm than feminine <i>-stems. The following differences from <a>-stems should be noted:
# {I-UMLAUT} is often present throughout the paradigm (although it tends to be missing in light stems, i.e. those with a short vowel followed by a single consonant, due to early elision of the <*-i->).
# The genitive is more commonly in <-ar> than <-s>, opposite to the tendency in <a>-stems, and maintains the stem infix <-j-> in some words. (Theoretically, <a>-stems should always have their genitive in <-s> and <i>-stems in <-ar>, but contamination in both directions has occurred.)
# The dative ending is usually null, whereas in <a>-stems it is usually <-i> (but exceptions occur in both directions, even more so in modern Icelandic).
# The nominative and accusative plurals are clearly distinct, with <i>-stems having <-i-> and <a>-stems having <-a->.
]==],
			masculine_examples = [==[

# <<gestr||guest|g=m>> (genitive <<gests>>)
# <<staðr||place|g=m>> (genitive <<staðar>>)
# <<drykkr||drink, beverage|g=m>> (genitive <<drykkjar>>)
# <<hár||thole|g=m>> (genitive <<hás>>)
# <<gríss||boar; piglet|g=m>> (genitive <<gríss>>, nominative plural <<grísir>>),
]==],
			feminine_examples = [==[

# <<kván||wife|g=f>>, from {PG} <<gem-pro:*kwēniz>>, without {I-UMLAUT}
# <<ætt||direction; family; generation>> and <<átt||family, race; direction>>, both from {PG} <<gem-pro:*aihtiz>>, with and without {I-UMLAUT}
# <<sýn||sight; appearance|g=f>> and <<sjón|ng=same|g=f>>, both from {PG} <<gem-pro:*siuniz>>, with and without {I-UMLAUT}
# <<ǫld||time, age; cycle|g=f>>, from {PG} <<gem-pro:*aldiz>> (dative <<ǫldu>>, <<ǫld>>)
# <<ǫsp||aspen|g=f>>, from {PG} <<gem-pro:*aspō>>
# <<sorg||sorrow; grief|g=f>>, from {PG} <<gem-pro:*surgō>>
]==],
		},
		["GENDER <an>-stem"] = {
			gender = "masculine or rarely neuter",
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-i>",
			neuter_nom_sg = "<-a>",
			gen_sg = "<-a>",
			masculine_nom_pl = "<-ar>",
			neuter_nom_pl = "<-u> with {U-UMLAUT}",
			parent = "n-stem",
			masculine_examples = [==[

# <<bogi||bow|g=m>>
# <<hreifi||wrist|g=m>>
# <<dōmari||judge|g=m>> (genitive plural <<dómurum>>)
# <<gumi||man|g=m>> (nominative plural <<gumar>> or <<gumnar>>)
# <<oxi||ox|g=m>> (nominative plural <<oxar>> or <<øxn>>, with consonant-stem endings)
# <<lé||scythe|g=m>> (genitive <<ljá>> < <<|*léa>>, nominative plural <<ljár>>)
]==],
			neuter_examples = [==[

# <<auga||eye|g=n>> (genitive plural <<augna>>)
# <<eyra||ear|g=n>>, from {PG} {{gem-pro:*ausô}} (which is assumed to have maintained Verner alternation in the stem, where the <*-z-> alternant was generalized in Northwest Germanic and caused {I-UMLAUT} due to Old Norse <z>-mutation; genitive plural <<eyrna>>)
# <<hjarta||heart|g=n>> (nominative/accusative plural <<hjǫrtu>>, genitive plural <<hjartna>>)
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
			addl = "The stem has {I-UMLAUT} throughout.",
			examples = [==[

# <<deyfi||deafness>>
# <<elli||old age>>, from {PG} {{gem-pro:*alþį̄}}
# <<lygi||lie>> (nominative/accusative plural <<lygar>>)
]==],
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-u> with {U-UMLAUT}",
			nom_pl = "<-ur> with {U-UMLAUT}",
			parent = "n-stem",
			examples = [==[

# <<saga||story>> (accusative <<sǫgu>>, genitive plural <<sagna>>)
# <<hvíla||bed>> (genitive plural <<hvílna>>)
# <<hǿna||hen>>, from {PG} {{gem-pro:*hōnijǭ}} (genitive plural <<hǿnna>>)
# <<blaðra||bladder>> (accusative <<blǫðru>>, genitive plural <<blaðra>>)
]==],
		},
		["<jōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ja>",
			gen_sg = "<-ju>",
			nom_pl = "<-jur>",
			parent = "<ōn>-stem",
			addl = "This class derives from {PG} <ōn>-stems ending in <j> after a light root, a vowel or a velar. As a result, the stem has {I-UMLAUT} throughout.",
			examples = [==[

# <<smiðja||smithy>> (genitive plural <<smiðja>>)
# <<hyggja||thought, opinion>> (genitive plural <<hyggna>>)
# <<brynja||coat of mail>> (genitive plural <<brynja>>)
# <<eimyrja||ember>>, from {PG} {{gem-pro:*aimuzjǭ}} (genitive plural <<eimyrja>>)
]==],
		},
		["<wōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-va>",
			gen_sg = "<-u>",
			nom_pl = "<-ur>",
			parent = "<ōn>-stem",
			addl = "This class derives from {PG} <ōn>-stems ending in <w>. As a result, the stem has {U-UMLAUT} throughout.",
			examples = [==[

# <<vǫlva||prophetess, witch>>
# <<vǫkva||moisture, humidity>>
# <<kvikva||quick (living tissue under nails or hooves); running fluid>>
]==],
		},
		["<u>-stem"] = {
			gender = "masculine",
			nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>) with {U-UMLAUT}",
			gen_sg = "<-ar> without {U-UMLAUT}",
			nom_pl = "<-ir> with {I-UMLAUT}",
			addl = "This class preserves most characteristics of {PG} <u>-stems, including {U-UMLAUT} in the nominative and accusative singular and the accusative and dative plural, and {I-UMLAUT} in the dative singular (< {PG} <*-iwi>) and nominative plural (< {PG} <*-iwiz>). The accusative plural is marked by a unique ending <-u>. The only remnant of <u>-stem neuters is <<fé>>, which has no obvious characteristics of <u>-stems any more and is best treated as simply irregular.",
			examples = [==[

# <<fjǫrðr||fjord>>, from {PG} <<gem-pro:*ferðuz>> (dative <<firði>>, genitive <<fjarðar>>)
# <<lǫgr||sea, lake>>, from {PG} <<gem-pro:*laguz>> (dative <<legi>>, genitive <<lagar>>)
# <<spánn|spánn, spónn|chip of wood; spoon>>, from {PG} <<gem-pro:*spēnuz>> (with <-r> assimilated to <-n>, and <ó> from earlier <ǫ́> before <n>; dative <<spæni>>)
# <<fǫgnuðr||happiness, joy; greetings>> (dative <<fagnaði>>, genitive <<fagnaðar>>, nominative plural <<fagnaðir>>; nousn with the abstract ending <-(n)uðr>/<-(n)aðr> are not subject to {I-UMLAUT})
]==]
		},
		["GENDER consonant stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "<-r> (which assimilates to a preceding <l>, <n> or <s>)",
			feminine_nom_sg = "usually the bare stem with {U-UMLAUT}",
			masculine_gen_sg = "<-ar> or <-s>",
			feminine_gen_sg = "<-ar> or <-r>, the latter often with {I-UMLAUT}",
			nom_pl = "<-r> (which assimilates to a preceding <l>, <n> or <s>) with {I-UMLAUT}",
			feminine_addl = "Feminine consonant stems with {U-UMLAUT} were usually originally <u>-stem or <ō>-stem nouns, or analogical to them.",
			masculine_examples = [==[

# <<fótr||foot; leg|g=m>> (genitive <<fótar>>, dative <<fǿti>>, nominative/accusative plural <<fǿtr>>)
# <<vetr||winter; year|g=m>> (with <-r> lost after stem ending in consonant + <-r>; genitive <<vetrar>>, nominative/accusative plural <<vetr>>)
]==],
			feminine_examples = [==[

# <<bók||book; beech|g=f>> (genitive <<bókar>> or <<bǿkr>>, nominative/accusative plural <<bǿkr>>)
# <<gás||goose|g=f>> (genitive <<gásar>>, nominative/accusative plural <<gæss>> with <-r> assimilated to <-s>)
# <<hǫnd||hand|g=f>>, from {PG} <<gem-pro:*handuz>> (genitive <<handar>>, dative <<hendi>>, nominative/accusative plural <<hendr>>)
# <<strǫnd||border; shore|g=f>>, from {PG} <<gem-pro:*strandō>> (genitive <<strandar>>, dative <<strǫnd>> or <<strǫndu>>, nominative/accusative plural <<strendr>>)
# <<tǫnn||tooth|g=f>>, from {PG} <<gem-pro:*tanþs>>, with analogical {U-UMLAUT} (genitive <<tannar>>, nominative/accusative plural <<tenn>>/<<tennr>>/<<teðr>>, with the last variant the original and phonologically expected form)
# <<mjǫlk||milk|g=f>>, from {PG} <<gem-pro:*meluks>>, with {U-UMLAUT} from the lost medial vowel (genitive <<mjǫlkr>>, singular-only)
# <<fló||flea|g=f>>, from {PG} <<gem-pro:*flauhaz>>, with declension and gender change (genitive <<flóar>>, nominative/accusative plural <<flœr>>)
]==],
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-ir>",
			gen_sg = "<-ur> with {U-UMLAUT}",
			nom_pl = "<-r> with {I-UMLAUT}",
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
			nom_pl = "<-r> with {I-UMLAUT}",
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
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "the bare stem",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-ās>",
			neuter_nom_pl = "<-u> after light stems, no ending after heavy stems",
			masculine_examples = "<<stān||stone|g=m>>; <<dæġ||day|g=m>> (nominative plural <<dagas>>, cf. {{w|Anglo-Frisian brightening}}); <<wealh||Celt; Welsh person|g=m>> (genitive <<wēales>>, cf. {{w|Phonological history of Old English#H-loss}})",
			neuter_examples = "<<sċip||ship|g=n>> (nominative plural <<sċipu>>); <<word||word|g=n>> (nominative plural <<word>>)",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-e> after (originally) heavy stems, no ending after (originally) light stems",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-as>",
			neuter_nom_pl = "<-u> after (originally) heavy stems, no ending after (originally) light stems",
			addl = [==[
In {OE}, <ja>-stems have largely merged with <a>-stems, but are distinguishable by
# ''-e'' in the nominative/accusative singular after originally heavy stems, and {WGG} of the stem-final consonant after originally light stems;
# the presence of {I-UMLAUT} throughout the paradigm;
# [[palatalization]] of a final velar stop;
# in the neuter, nominative plural <-u> after (originally) heavy stems, but no ending after (originally) light stems, which is the reverse of the pattern for plain <a>-stems.
]==],
			masculine_examples = [==[

# <<hryċġ||back, spine|g=m>> (with {I-UMLAUT} of original <*-u->, {WGG} after a light stem, and palatalization)
# <<ende||end|g=m>> (with {I-UMLAUT} of original <*-a->, and nominative ''-e'' after a heavy stem)
# <<lǣċe||doctor|g=m>> (with nominative ''-e'' after a heavy stem, and palatalization)
# <<hryre||fall; ruin|g=m>> (no {WGG} after <r>, leading to preservation of original <*-i> from {PG} <*-jaz>)
# <<here||army|g=m>> (genitive <<herġes>>; this word preserves <*-j-> after <r>)
]==],
			neuter_examples = [==[

# <<bedd||bed|g=n>> (nominative plural <<bedd>>; with {I-UMLAUT} of original <*-a->, and {WGG} after a light stem)
# <<rīċe||kingdom|g=n>> (nominative plural <<rīċu>>; with nominative ''-e'' and nominative plural ''-u'' after a heavy stem, and palatalization)
]==],
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-u> after consonants, no ending or <-w> after diphthongs",
			gen_sg = "<-wes>",
			masculine_nom_pl = "<-was>",
			neuter_nom_pl = "<-u> after consonants, no ending or <-w> after diphthongs",
			masculine_examples = "<<bearu||grove, wood|g=m>> (genitive <<bearwes>>, nominative plural <<bearwas>>)",
			neuter_examples = "<<searu||machine, device|g=n>> (genitive <<searwes>>, nominative plural <<searu>>); <<trēo|trēo(w)|tree|g=n>> (genitive <<trēowes>>, nominative plural <<trēo|trēo(w)>>)",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-e>",
			nom_pl = "<-e>, <-a>",
			addl = "Original <jō>-stems and <ijō>-stems are indistinguishable from <ō>-stems other than by the presence of {I-UMLAUT} throughout the paradigm, palatalization of final velars and with {WGG} after original light stems.",
			examples = "<<ġiefu||gift>> (genitive <<ġiefe>>, light stem); <<þēod||people, nation; language>> (genitive <<þēode>>, heavy stem); <<bryċġ||bridge>> (original <jō>-stem, with {I-UMLAUT}, {WGG} and palatalization); <<ġierd||rod>> (original <ijō>-stem, with {I-UMLAUT})",
		},
		["<wō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-we>",
			nom_pl = "<-we>, <-wa>",
			examples = "<<sinu||sinew, nerve>> (genitive <<sinwe>>); <<beadu||battle, war>> (genitive <<beadwe>>); <<lǣs||pasture>> (genitive <<lǣswe>>); <<clēa||claw, nail>> (genitive <<clawe>>)",
		},
		["GENDER <i>-stem"] = {
			gender = "masculine or feminine (rarely neuter)",
			possible_genders = {"masculine", "feminine", "neuter"},
			masculine_nom_sg = "<-e> after light stems, no ending after heavy stems",
			feminine_nom_sg = "the bare stem after heavy stems (light-stem feminine <i>-stems have merged with <jō>-stems)",
			neuter_nom_sg = "<-e> after light stems (heavy-stem neuter <i>-stems have merged with <ja>-stems)",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "<-e>",
			neuter_gen_sg = "<-es>",
			masculine_nom_pl = "<-as> (<-e> in some demonyms such as <<Engle||Angles, English>> and a few other words such as <<wine||friend>>)",
			feminine_nom_pl = "<-e> or <-a>",
			neuter_nom_pl = "<-u>",
			addl = [==[
In {OE}, <i>-stems have largely merged with <ja>/<jō>-stems, but are distinguishable by
# in the masculine and neuter, <-e> in the nominative/accusative singular after originally light stems, without {WGG}, as in <<sleġe||a strike, a blow, a hit>> < {{m+|gem-pro|*slagiz}} vs. <<seċġ||man, hero>> < {{m+|gem-pro|*sagjaz}};
# contrastingly, no <-e> in the nominative/accusative singular after originally heavy stems, as in <<ende||end>> < {{m+|gem-pro|*andijaz}} vs. <<bend||bond; ribbon>> < {{m+|gem-pro|*bandiz}};
# in the feminine, optional accusative singular with a null ending, as opposed to the normal ending in <-e>;
# some masculine plural-only demonyms, e.g. <<Engle||Angles, English>>, <<Mierċe||Mercians>>, and a few other nouns, e.g. <<wine||friend(s)>>, <<ielde||men>>, <<ielfe||elves>>, <<lēode||people>>, form their nominative/accusative plural in <-e>, the original <i>-stem ending.
]==],
			masculine_examples = "<<stede||place|g=m>>, <<cyre||choice|g=m>>, <<eġe||fear|g=m>> (all light stems); <<ġiest||guest|g=m>>, <<wyrm||worm|g=m>>, <<fenġ||grasp|g=m>>, <<swēġ||sound, noise|g=m>> (all heavy stems)",
			feminine_examples = "<<cwēn||queen|g=f>>, <<brȳd||bride|g=f>>, <<benċ||bench|g=f>>, <<fierd||army|=f>>",
			neuter_examples = "<<spere||spear|g=n>>, <<orleġe||fate|g=n>>>, <<sife||sieve|g=n>>", 
		},
		["<u>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-u> after light stems, no ending after heavy stems",
			gen_sg = "<-a>",
			nom_pl = "<-a>",
			addl = "The only remnants of a neuter <u>-stem are Northumbrian <<feolu||much>> and West Saxon plural <<fela|fela, feola|many>>. Original {{m+|gem-pro|*fehu}} become <a>-stem <<feoh>> in prehistoric {OE}.",
			examples = "<<sunu||son|g=m>>; <<feld||field|g=m>>; <<duru||door|g=f>>; <<hand||hand|g=f>>", 
		},
		["GENDER <n>-stem"] = {
			possible_genders = {"masculine", "feminine", "neuter"},
			masculine_nom_sg = "<-a>",
			feminine_nom_sg = "<-e>",
			neuter_nom_sg = "<-e>",
			gen_sg = "<-an>",
			nom_pl = "<-an>",
			addl = "This represents the merger of masculine and neuter <-an> stems and feminine <-ōn> stems, with the only difference remaining in the nominative singular (and neuter accusative singular). There were also <-jan> and <-jōn> stems (indistinguishable from plain <-n> stems except by the presence of {I-UMLAUT}) and <-wan> and <-wōn> stems (indistinguishable from plain <-n> stems).",
			masculine_examples = "<<nama||name|g=m>>; <<frēa||lord|g=m>>; <<dēma||judge|g=m>> (<ijan>-stem, with {I-UMLAUT}); <<wreċċa||exiled person|g=m>> (<jan>-stem with {I-UMLAUT}, {WGG} and palatalization); <spearwa||sparrow|g=m>> (<wan>-stem)",
			feminine_examples = "<<tunge||tongue|g=f>>; <<bēo||bee|g=f>>; <<bēċe||beech tree|g=f>> (<ijōn-stem>, with {I-UMLAUT} and palatalization); <<wiċċe||witch|g=f>> (<jōn>-stem, with {I-UMLAUT}, {WGG} and palatalization); <<swealwe||swallow|g=f>> (<wōn>-stem)",
			neuter_examples = "<<ēage||eye|g=n>>; <<ēare||ear|g=n>>; <<wange||cheek|g=n>>",
		},
		["consonant stem"] = {
			possible_genders = {"masculine", "feminine"},
			masculine_nom_sg = "the bare stem",
			feminine_nom_sg = "<-u> after light stems, no ending after heavy stems",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "either the bare stem with {I-UMLAUT} or <-e> without {I-UMLAUT} after heavy stems, but only <-e> without {I-UMLAUT} after light stems",
			masculine_nom_pl = "the bare stem with {I-UMLAUT}",
			feminine_nom_pl = "the bare stem with {I-UMLAUT} after heavy stems, <-e> with {I-UMLAUT} after light stems",
			addl = "The dative singular also had {I-UMLAUT}, and was identical the nominative/accusative plural.",
			masculine_examples = "<<fōt||foot|g=m>>, <<tōþ||tooth|g=m>>, <<mann||man|g=m>>",
			feminine_examples = "<<bōc||book|g=f>>, <<gāt||goat|g=f>>, <<meoluc|meoluc, meolc|milk|g=f>>, <<burg||city|g=f>> (forms with {I-UMLAUT} may appear as <<byriġ>>), <<hnutu||nut|g=f>>",
		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-nd>",
			gen_sg = "<-ndes>",
			nom_pl = "<-nd> with or without {I-UMLAUT}, <-nde> or <-ndas>",
			parent = "consonant stem",
			addl = "There were two variants, largely monosyllabic nouns with optional {I-UMLAUT} in the dative singular and nominative/accusative plural, such as <<frēond||friend>>, and polysyllabic agent nouns in <-end>, without {I-UMLAUT} or in some cases with {I-UMLAUT} throughout the paradigm, when derived from a verb with {I-UMLAUT} in its stem.",
			examples = "With optional {I-UMLAUT}: <<frēond||friend>>, <<fēond||enemy>>, <<tēond||accuser>>, <<gōddōnd||benefactor>>; without {I-UMLAUT}: <<wīgend||warrior>>, <<āgend||owner>>, <<hǣlend||savior>> (with original infix <*-ij-> causing {I-UMLAUT} of the stem), <<hettend||enemy>> (with original infix <*-j-> causing {I-UMLAUT} of the stem and {WGG})",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-or> or <-er>",
			gen_sg = "same as nominative singular, sometimes with {I-UMLAUT}",
			nom_pl = "<-ra>, <-ru>; <-as> for <<fæder>>",
			parent = "consonant stem",
			addl = "There were only seven words in this declension class (five regular kinship terms and two collective kinship terms), and each declined differently.",
			examples = "<<fæder||father|g=m>>; <<brōþor||brother|g=m>>; <<mōdor||mother|g=f>>; <<dohtor||daughter|g=f>>; <<sweostor||sister|g=f>>; <<ġebrōþor|ġebrōþor, ġebrōþru|brothers|g=m-p>>; <<ġesweostor|ġesweostor, ġesweostru, ġesweostra|sisters|g=f-p>>",
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "the bare stem",
			gen_sg = "<-es>",
			nom_pl = "<-ru>",
			parent = "consonant stem",
			addl = "This was a relic class in {OE}. The vast majority of nouns in this class in {PWG} were transferred to another class in prehistoric {OE}, sometimes changing gender in the process. Doublets were frequent, e.g. <<gāst>> and <<gǣst||spirit, breath>>; <<sigor>> and <<sige||victory>>; <<dōgor>> and Northumbrian <<dœ̄ġ||day>>; <<hālor>> and <<hǣl||health, salvation>>; <<salor>> and <<sæl||hall>>; <<hlǣw>> and <<hlāw||mound, hill>>.",
			examples = "<<lamb||lamb>>; <<ċealf||calf>>; <<ǣġ||egg>>; <<ċild||child>> (nominative/accusative plural <<ċild>> or <<ċildru>>)",
		},
	},
	goh = {
		["GENDER <a>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "the bare stem",
			masculine_nom_sg = "the bare stem",
			neuter_nom_sg = "the bare stem",
			gen_sg = "<-es>; later <-as>",
			masculine_nom_pl = "<-ā> (later <-a>)",
			neuter_nom_pl = "the bare stem",
			masculine_examples = "<<tag||day|g=m>>; <<kuning||king|g=m>>; <<ackar||acre, field|g=m>> (genitive <<ackres>>)",
			neuter_examples = "<<wort||word|g=n>>; <<barn||child|g=n>>; <<zwīfal||doubt|g=n>> (genitive <<zwīfles>>)",
		},
		["GENDER <ja>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-i>",
			gen_sg = "<-es>",
			masculine_nom_pl = "<-e> (later <-ā>, becoming <-a>)",
			neuter_nom_pl = "<-i>",
			parent = "GENDER <a>-stem",
			addl = "{OHG} <ja>-stems have {I-UMLAUT} throughout the paradigm, although it is not represented in spelling except when the Proto-West Germanic root vowel was <*a>, becoming {OHG} <e>, e.g. <<betti||bed>> from {{m+|gmw-pro|*badi}}~{{m|gmw-pro|*baddja}} with {WGG}. Early 9th century <ja>-stems still included the {{ic|/j/}} glide in many inflections, e.g. dative singular <-ie>, instrumental singular <-iu>, genitive plural <-eo> or <-io>, but it was soon dropped, with the inflections merging with plain <a>-stems except in the nominative/accusative singular (compare a similar development in {OE}).",
			masculine_examples = "<<hirti||herdsman|g=m>>; <<lērāri||teacher|g=m>>; <<rucki||back>> (with {WGG})",
			neuter_examples = "<<enti||end|g=n>> (with visible {I-UMLAUT}); <<kunni||race, kind|g=n>> (with {WGG}); <<heri||army|g=n>> (genitive <<heries>>, with no {WGG} and preserved {{ic|/j/}} after {{ic|/r/}})",
		},
		["GENDER <wa>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			nom_sg = "<-o>; sometimes dropped when directly following long vowel and forming a diphthong after a short vowel",
			gen_sg = "<-wes>; after a consonant, <-awes> or sometimes <-ewes>, with an [[epenthetic]] vowel",
			masculine_nom_pl = "<-ā> (later <-a>)",
			neuter_nom_pl = "[:nom_sg:]",
			parent = "GENDER <a>-stem",
			masculine_examples = "<<snēo|snēo, snē|snow|g=m>> (genitive <<snēwes>>); <<scato||shadow|g=m>> (genitive <<scatawes>>); <<bū||dwelling|g=m>> (genitive <<būwes>>)",
			neuter_examples = "<<kneo||knee|g=n>> (genitive <<knëwes>>); <<trëso||treasure|g=n>> (genitive <<trësawes>>); <<rēo|rēo, rē|corpse|g=n>> (genitive <<rēwes>>)",
		},
		["<ō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-a> (sometimes <-u> or <-o>)",
			nom_pl = "<-ā>",
			addl = "The {OHG} nominative ending <-a> was taken from the accusative; the expected nominative would be <#-u> or no ending.",
			examples = "<<gëba||gift>>, <<ërda||earth>>, <<triuwa||fidelity>>",
		},
		["<jō>-stem"] = {
			gender = "feminine",
			nom_sg = "<-e>, <-ea>, <-ia> (early); <-a> (later)",
			gen_sg = "[:nom_sg:]",
			nom_pl = "<-e>, <-eā>, <-iā> (early); <-ā> (later)",
			parent = "<ō>-stem",
			addl = "{OHG} <jō>-stems have {I-UMLAUT} throughout the paradigm, although it is not represented in spelling except when the {PWG} root vowel was <*a>, becoming {OHG} <e>, e.g. <<hella|hella, helle, hellea|hell>> from {{m+|gmw-pro|*hallju}} with {WGG}. Early 9th century <jō>-stems still included the {{ic|/j/}} glide in many inflections, e.g. dative singular <-iu>, genitive plural <-eōno>, but it was soon dropped, with the inflections merging with plain <ō>-stems. Feminines in <-in> such as <<kuningin||queen>>, <<friuntin||female friend>> preserve the {PWG} and {PG} <<c:gmw-pro:<ī>/<jō>-stem nouns|<ī>/jō> noun>> declension, with original nominative in <*-ī> dropped and remaining forms reflecting {WGG}. (Later {OHG} variants of these nouns ended in <-inna>, showing merger with <ō>-stems.)",
			examples = "<<sunta|sunta, sunte, suntea|sin>>; <<hella|hella, helle, hellea|hell>> (with visible {I-UMLAUT} and {WGG}); <<kuningin||queen>> (genitive <<kuninginna>>)",
		},
		["GENDER <i>-stem"] = {
			possible_genders = {"masculine", "feminine"},
			nom_sg = "no ending, without {I-UMLAUT}; occasionally <-i> after light stems (those with a short vowel followed by a single consonant), with {I-UMLAUT}",
			masculine_gen_sg = "<-es>",
			feminine_gen_sg = "<-i> with {I-UMLAUT}",
			nom_pl = "<-i> with {I-UMLAUT}",
			addl = [==[
In {OHG}, masculine <i>-stems were restructured in the singular to take <a>-stem endings, prior to {I-UMLAUT}, but kept <i>-stem endings in the plural. (There were two exceptions: (1) the instrumental singular preserved the ending <-iu> through the early 9th century and accordingly sometimes had {I-UMLAUT}, as in instrumental singular <<gastiu>> or <<gestiu>> of <<gast||guest>>; and (2) the nominative/accusative singular of a few nouns with light stems preserved the original <-i> ending, such as <<wini||friend>>, <<quiti||saying>>; but compare <<slag||blow, strike, hit>> without the <-i> ending or {I-UMLAUT}, and contrast the cognate <<ang:sleġe>> with {ang:I-UMLAUT} and a reflex of {PWG} <-i>.) Feminine nouns mostly dropped the original <-i> in the nominative and accusative prior to {I-UMLAUT} (which seems to have been a regular development in heavy stems that was analogically carried over to some light stems), but otherwise kept the <i>-stem endings. The result was a paradigm with {I-UMLAUT} throughout the plural, but not in the singular except in the feminine genitive and dative singular. (Exceptionally, feminine <<turi||door>> and <<kuri||choice>> maintained original <-i> in the nominative/accusative singular, leading to {I-UMLAUT} throughout the paradigm; cf. modern {{m+|de|Tür||door|g=f}}, {{m|de|Kür||choice|g=f|ll=poetic}}. This did not apply to most light-stem feminines, cf. <<stat||place>> without {I-UMLAUT} and contrast cognate <<ang:stede>> with {ang:I-UMLAUT} and a reflex of {PWG} <-i>.)

The development of {I-UMLAUT} in the plural of this paradigm, combined with similar inherited behavior in consonant stems, <z>-stems and <r>-stems, led to {I-UMLAUT} becoming a mark of the plural. This subsequently spread to many <a>-stem nouns, such as modern {{m+|de|Nagel||nail}} and {{m|de|Hammer||hammer}}, with non-original umlauted plurals ''Nägel'' and ''Hämmer''.
]==],
			masculine_examples = "<<gast||guest|g=m>> (nominative plural <<gesti>>); <<wurm||worm|g=m>>; <<aphul||apple|g=m>> (nominative plural <<ephili>>); <<slag||blow, strike, hit|g=m>> (nominative plural <<slegi>>); <<wini||friend|g=m>>",
			feminine_examples = "<<anst||favor|g=f>> (genitive singular, nominative plural <<ensti>>); <<jugund||youth|g=f>>; <<gift||gift|g=f>>; <<turi||door|g=f>>",
		},
		["GENDER <an>-stem"] = {
			possible_genders = {"masculine", "neuter"},
			masculine_nom_sg = "<-o>",
			neuter_nom_sg = "<-a>",
			gen_sg = "<-en>, <-in>",
			masculine_nom_pl = "<-on>, <-un>",
			neuter_nom_pl = "<-un>, <-on>",
			parent = "n-stem",
			masculine_examples = "<<namo||name|g=m>>; <<wahsmo||fruit|g=m>>; <<stërno||star|g=m>>; <<gomo||man|g=m>>",
			neuter_examples = "<<hërza||heart|g=n>>; <<ouga||eye|g=n>>; <<ōra||ear|g=n>>",
		},
		["<ōn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-a>",
			gen_sg = "<-ūn>",
			nom_pl = "<-ūn>",
			parent = "n-stem",
			examples = "<<zunga||tongue>>; <<quëna||woman>>; <<sunna||sun>>",
		},
		["<īn>-stem"] = {
			gender = "feminine",
			nom_sg = "<-ī>",
			gen_sg = "<-ī>",
			nom_pl = "<-ī>",
			parent = "n-stem",
			addl = "{OHG} <īn>-stems have {I-UMLAUT} throughout the paradigm (cf. {{m+|de|Höhe||height}} < {OHG} <<hōhī>>, {{m+|de|Süße||sweetness}} < {OHG} <<suoȥȥī>>), although it is usually represented in spelling. This paradigm is indeclinable except for genitive plural <-īno>, dative plural <-īm> (later <-īn>).",
			examples = "<<hōhī||height>>; <<snëllī||quickness>>; <<tiufī||depth>>; <<menigī|menigī, managī|multitude>>; <<toufī||dipping, baptism>>; <<welī||choice>> (with visible {I-UMLAUT})",
		},
		["<u>-stem"] = {
			gender = "masculine or or rarely neuter",
			nom_sg = "<-u> after light stems; no examples with heavy stems",
			gen_sg = "<-es>",
			nom_pl = "<-i> with {I-UMLAUT} when masculine; unattested when neuter",
			addl = "<u>-stems are a relic class in {OHG}. Only 6 masculine nouns, all light-stem, maintain original <-u> in the nominative/accusative singular, otherwise behaving as <i>-stems: <<situ||custom>>, <<fridu||peace>>, <<hugu||understanding>>, <<sigu||victory>>, <<witu||wood>> and <<sunu||son>> (also found as <<sun>>). All remaining <u>-stems inherited from {PWG} have been moved completely to become <i>-stems or sometimes <a>-stems. Only one neuter <u>-stem remains, <<fihu||cattle>>, which behaves as an <a>-stem in the oblique singular and is unattested in the plural. No feminine <u>-stems remain, but the <i>-stem noun <<hant||hand>> maintains a vestige of its original <u>-stem declension in the dative plural <<hantum>> (later <<hantun>>, <<hanton>>), in place of expected #<<hantim>>.",
		},
		["consonant stem"] = {
			gender = "masculine or feminine",
			nom_sg = "the bare stem",
			gen_sg = "<-es> when masculine; the bare stem when feminine",
			nom_pl = "the bare stem",
			addl = "This is a relic class in {OHG}. Most consonant stems have been converted to <i>-stems. The remaining nouns are distinguished by a null ending in the dative singular and nominative/accusative plural, without the expected {I-UMLAUT} (all such nouns are heavy-stem and as a result the original <-i> ending was regularly dropped prior {I-UMLAUT} taking place; compare the same development in the nominative/accusative singular of <i>-stems).",
			examples = "<<man||man|g=m>> (genitive <<mannes>>); <<naht||night|g=f>>; <<buoch||book>> (neuter in the singular with genitive <<buoches>>, feminine in the plural); <<burg||city>>, <<brust||breast>> could follow either consonant stems or <i>-stems; <<fuoȥ||foot>> moved to the <i>-stems but maintained consonant-stem dative plural <<fuoȥum>> (later <<fuoȥun>>, <<fuoȥon>>)",
		},
		["<nd>-stem"] = {
			gender = "masculine",
			nom_sg = "<-nt>",
			gen_sg = "<-ntes>",
			nom_pl = "<-nt>, or <-ntā> (later <-nta>)",
			parent = "consonant stem",
			addl = "This contained present participles used as nouns as well as <<friunt||friend>>. This class had nearly merged with <a>-stems, the only difference being the nominative/accusative plural, which could have a null ending.",
		},
		["<r>-stem"] = {
			gender = "masculine or feminine",
			nom_sg = "<-er>",
			gen_sg = "<-er>; also <-eres> for <<fater>>",
			nom_pl = "<-er>; <-erā>/<-era> for <<fater>>",
			parent = "consonant stem",
			addl = "There were only five words in this declension class: <<fater||father>>, <<bruoder||brother>>, <<muoter||mother>>, <<tohter||daughter>> and <<swëster||sister>>. <<fater>> had <a>-stem endings in the plural and alternatively in the singular as well.",
		},
		["<z>-stem"] = {
			gender = "neuter",
			nom_sg = "the bare stem",
			gen_sg = "<-es>",
			nom_pl = "<-ir> with {I-UMLAUT}",
			parent = "consonant stem",
			addl = "This was a relic class in {OHG} that later expanded considerably. The singular had assimilated to <a>-stem endings (originally the genitive and dative singular had the <-ir-> infix as well) but the plural maintained the <-ir> infix, which triggered {I-UMLAUT}.",
			examples = "<<lamb||lamb>>; <<kalb||calf>>; <<blat||leaf>>; <<grab||grave>>",
		},
}

require("Module:category tree/utilities").add_inflection_labels {
	labels = labels,
	pos = "noun",
	stem_classes = noun_decls,
	principal_parts = {
		{"nom_sg", "nominative singular"},
		{"gen_sg", "genitive singular"},
		{"nom_pl", "nominative plural"},
	},
	mark_up_spec = function(spec, nolink)
		-- umlauts
		spec = spec:gsub("I%-UMLAUT", "{{w|Old Norse#Umlaut|i-umlaut}}")
		spec = spec:gsub("U%-UMLAUT", "{{w|Old Norse#U-umlaut|u-umlaut}}")
		spec = spec:gsub("{I-UMLAUT}", "{{w|Germanic umlaut}}")
		spec = spec:gsub("{WGG}", "{{w|West Germanic gemination}}")
		if nolink then
			spec = require("Module:links").remove_links(spec)
		end
		return (spec:gsub("<(.-)>", "''%1''"))
	end,
	addl = "The stem classes are named from the perspective of [[:Category:Proto-Germanic language|Proto-Germanic]] " ..
	"and may not still be visible in {{{langname}}} inflections.",
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

labels["masculine a-stem nouns"] = {
	displaytitle = "{{{langname}}} masculine ''a''-stem nouns",
	description = "{{{langname}}} masculine ''a''-stem nouns. These nouns have a genitive singular in ''-es'' and a nominative plural in ''-as''.",
	parents = {{name = "a-stem nouns", sort = "masculine"}},
	breadcrumb = "masculine",
}

labels["neuter a-stem nouns"] = {
	displaytitle = "{{{langname}}} neuter ''a''-stem nouns",
	description = "{{{langname}}} neuter ''a''-stem nouns. These nouns have a genitive singular in ''-es'' and a nominative plural that is either endingless (if the stem is heavy) or ending in ''-u'' (if the stem is light).",
	parents = {{name = "a-stem nouns", sort = "neuter"}},
	breadcrumb = "neuter",
}

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

return {LABELS = labels}
