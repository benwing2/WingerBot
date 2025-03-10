local labels = {}

-- FIXME: Almost everything formerly here has been moved into [[Module:category tree/topic cat/data/Places]].
-- The remainder should be consolidated.

labels["Earth"] = {
	type = "related-to",
	description = "=the planet [[Earth]] and the features found on it",
	parents = {"nature"},
}

labels["Africa"] = {
	type = "related-to",
	description = "default",
	parents = {"Earth"},
}

labels["America"] = {
	type = "related-to",
	description = "=[[America]], in the sense of [[North America]] and [[South America]] combined",
	parents = {"Earth"},
}

labels["Antarctica"] = {
	type = "related-to",
	description = "=the territory of [[Antarctica]]",
	parents = {"Earth"},
}

labels["Asia"] = {
	type = "related-to",
	description = "default",
	parents = {"Earth", "Eurasia"},
}

labels["Atlantic Ocean"] = {
	type = "related-to",
	description = "default with the",
	parents = {"Earth"},

}

labels["British Isles"] = {
	type = "related-to",
	description = "=the people, culture, or territory of [[Great Britain]], [[Ireland]], and other nearby islands",
	parents = {"Europe", "islands"},
}

labels["Central America"] = {
	type = "related-to",
	description = "default",
	parents = {"Earth", "America"},
}

labels["Punjab, Pakistan"] = {
	type = "related-to",
	description = "{{{langname}}} names of places in {{w|Punjab, Pakistan}}.",
	parents = {"Pakistan"},
}

labels["Eurasia"] = {
	type = "related-to",
	description = "=[[Eurasia]], that is, [[Europe]] and [[Asia]] together",
	parents = {"Earth"},
}

labels["Europe"] = {
	type = "related-to",
	description = "default",
	parents = {"Earth", "Eurasia"},
}

labels["European Union"] = {
	type = "related-to",
	description = "default with the",
	parents = {"Europe"},
}

labels["Gascony"] = {
	type = "related-to",
	description = "default",
	parents = {"Occitania, France"},
}

labels["Indian subcontinent"] = {
	type = "related-to",
	description = "default with the",
	parents = {"South Asia"},
}

labels["Bengal"] = {
	type = "related-to",
	description = "{{{langname}}} terms related to the people, culture, or territory of [[Bengal]].",
	parents = {"Indian subcontinent"},
}

labels["Kashmir"] = {
	type = "related-to",
	description = "{{{langname}}} terms related to the people, culture, or territory of [[Kashmir]].",
	parents = {"Indian subcontinent"},
}

labels["Azad Kashmir"] = {
	type = "related-to",
	description = "{{{langname}}} terms related to the people, culture, or territory of [[Azad Kashmir]].",
	parents = {"Pakistan", "Kashmir"},
}

labels["Gilgit-Baltistan"] = {
	type = "related-to",
	description = "{{{langname}}} terms related to the people, culture, or territory of [[Gilgit-Baltistan]].",
	parents = {"Pakistan", "Kashmir"},
}

labels["Kashmir, India"] = {
	type = "related-to",
	description = "{{{langname}}} names of places in {{w|Kashmir, India}}.",
	parents = {"India", "Kashmir"},
}

labels["Korea"] = {
	type = "related-to",
	description = "=the people, culture, or territory of [[Korea]]",
	parents = {"Asia"},
}

labels["Languedoc"] = {
	type = "related-to",
	description = "default",
	parents = {"Occitania, France"},
}

labels["Lapland"] = {
	type = "related-to",
	description = "=[[Lapland]], a region in northernmost Europe",
	parents = {"Europe", "Finland", "Norway", "Russia", "Sweden"},
}

labels["Melanesia"] = {
	type = "related-to",
	description = "=the people, culture, or territory of [[Melanesia]]",
	parents = {"Oceania"},
}

labels["Micronesia"] = {
	type = "related-to",
	description = "=the people, culture, or territory of [[Micronesia]]",
	parents = {"Oceania"},
}

labels["Middle East"] = {
	type = "related-to",
	description = "default with the",
	parents = {"regions of Africa", "regions of Asia"},
}

labels["Netherlands Antilles"] = {
	type = "related-to",
	description = "=the people, culture, or territory of the [[Netherlands Antilles]]",
	parents = {"Netherlands", "North America"},
}

labels["North America"] = {
	type = "related-to",
	description = "default",
	parents = {"America"},
}

labels["Oceania"] = {
	type = "related-to",
	description = "default",
	parents = {"Earth"},
}

labels["Occitania"] = {
	type = "related-to",
	description = "default",
	parents = {"Europe", "France"},
}

labels["Polynesia"] = {
	type = "related-to",
	description = "=the people, culture, or territory of [[Polynesia]]",
	parents = {"Oceania"},
}

labels["Provence"] = {
	type = "related-to",
	description = "default",
	parents = {"Provence-Alpes-Côte d'Azur, France"},
}

labels["South America"] = {
	type = "related-to",
	description = "default",
	parents = {"America"},
}

labels["South Asia"] = {
	type = "related-to",
	description = "default",
	parents = {"Eurasia", "Asia"},
}

return labels
