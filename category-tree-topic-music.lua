local labels = {}

------------------------------------ music base labels ------------------------------------

labels["music"] = {
	type = "related-to",
	description = "default",
	parents = {"art", "sound"},
}

labels["singing"] = {
	type = "related-to",
	description = "default",
	parents = {"music", "talking"},
}

------------------------------------ music theory ------------------------------------

labels["musical voices and registers"] = {
	type = "type",
	description = "default",
	parents = {"music", "singing"},
}

labels["musical meters"] = {
	type = "type",
	description = "default",
	parents = {"music"},
}

labels["musical notes"] = {
	type = "type",
	description = "default",
	parents = {"music"},
}

------------------------------------ musicians ------------------------------------

labels["musicians"] = {
	type = "type",
	description = "default",
	parents = {"occupations", "music"},
}

labels["Justin Bieber"] = {
	type = "related-to",
	description = "=Canadian singer {{w|Justin Bieber}}",
	parents = {"individuals", "music"},
}

labels["Taylor Swift"] = {
	type = "related-to",
	description = "=American singer-songwriter {{w|Taylor Swift}}",
	parents = {"individuals", "music"},
}

------------------------------------ musical genres ------------------------------------

labels["musical genres"] = {
	type = "type",
	description = "default",
	parents = {"music", "genres"},
}

labels["blues music"] = {
	type = "related-to",
	wikidata = 9759,
	description = "default",
	parents = {"musical genres"},
}

labels["jazz"] = {
	type = "related-to",
	description = "default",
	parents = {"musical genres"},
}

labels["opera"] = {
	type = "related-to",
	description = "default",
	parents = {"theater", "musical genres"},
}

------------------------------------ musical instruments ------------------------------------

labels["musical instruments"] = {
	type = "set",
	description = "default",
	parents = {"tools", "music"},
}

labels["organ instruments"] = {
	type = "type",
	description = "default",
	parents = {"wind instruments"},
}

labels["percussion instruments"] = {
	type = "set",
	description = "default",
	parents = {"musical instruments"},
}

labels["gongs"] = {
	type = "related-to",
	description = "default",
	parents = {"percussion instruments"},
}

labels["string instruments"] = {
	type = "set",
	description = "{{{langname}}} names of [[string instrument]]s.",
	parents = {"musical instruments"},
}

labels["singing voice synthesis"] = {
	type = "related-to",
	description = "default",
	parents = {"musical instruments", "singing"},
}

labels["wind instruments"] = {
	type = "type",
	description = "default",
	parents = {"musical instruments"},
}

labels["woodwind instruments"] = {
	type = "type",
	description = "default",
	parents = {"wind instruments"},
}

------------------------------------ music misc ------------------------------------

labels["lutherie"] = {
	type = "related-to",
	description = "default",
	parents = {"music", "crafts"},
}

labels["music industry"] = {
	type = "related-to",
	description = "default with the",
	parents = {"industries", "music"},
}

labels["national anthems"] = {
	type = "name",
	description = "default",
	parents = {"artistic works", "music"},
}


return labels
