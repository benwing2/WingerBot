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
	breadcrumb = "''j''-present",
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
	breadcrumb = "''j''-present",
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
	breadcrumb = "''j''-present",
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
	breadcrumb = "''j''-present",
	parents = {{name = "class 7 strong verbs", sort = "j-present"}},
}

-- Add 'umbrella_parents' key if not already present.
for key, data in pairs(labels) do
	if not data.umbrella_parents then
		data.umbrella_parents = "Terms by grammatical category subcategories by language"
	end
end

return {LABELS = labels}
