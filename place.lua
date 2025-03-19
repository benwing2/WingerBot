local export = {}

local force_cat = false -- set to true for testing

local m_data = require("Module:place/data")
local m_links = require("Module:links")
local m_strutils = require("Module:string utilities")
local m_table = require("Module:table")

local debug_track_module = "Module:debug/track"
local en_utilities_module = "Module:en-utilities"
local languages_module = "Module:languages"
local parse_interface_module = "Module:parse interface"
local parse_utilities_module = "Module:parse utilities"
local utilities_module = "Module:utilities"

local enlang = require(languages_module).getByCode("en")

local rmatch = mw.ustring.match
local rfind = mw.ustring.find
local ulen = mw.ustring.len
local split = m_strutils.split
local dump = mw.dumpObject
local insert = table.insert
local concat = table.concat
local pluralize = require(en_utilities_module).pluralize
local extend = m_table.extend

local placetype_data = m_data.placetype_data

--[==[ intro:

===Terminology===

* A ''place'' (or ''location'') is a geographic feature (either natural or geopolitical), either on the surface of the
  Earth or elsewhere. Examples of types of natural places are rivers, mountains, seas and moons; examples of types of
  geopolitical places are cities, countries, neighborhoods and roads. Specific places are identified by names (referred
  to as ''toponyms'' or ''placenames'', see below). A given place will often have multiple names, with each language
  that has an opportunity to refer to the place using its own name and some languages having multiple names for the
  same place.
* A ''toponym'' (or ''placename'') is a term that refers to a specific place, i.e. a name for that place. Examples are
  [[Tucson]] (a city in Arizona); [[New York]] (ambiguous; either a city or a state); [[Georgia]] (ambiguous; either a
  state of the US or an independent country in the Caucasus Mountains); [[Paris]] (ambiguous; either the capital of
  France or various small cities and towns in the US); [[Tethys]] (one of the moons of Saturn); [[Pão de Açucar]] (a
  mountain in Rio de Janeiro); [[Willamette]] (a river in Oregon); etc. Some placenames have display aliases; when
  encountered, the placenames are mapped to their canonical form before further processing. For example, `US`, `U.S.`,
  `USA`, `U.S.A.` and `United States of America` are all canonicalized to `United States` (if identified as a country),
  and display as `United States`. Similarly, the foreign forms `Occitanie` (as a region or administrative region) and
  `Noord-Brabant` (as a province) are mapped to `Occitania` and `North Brabant` for display purposes. There are also
  category aliases, so that if e.g. `Republic of Macedonia` is encountered, it will display as such but categorize as
  `North Macedonia`. (This is because, among other reasons, `Republic of Macedonia` is normally preceded by `"the"`
  while `North Macedonia` is not, so a call {{tl|place|en|a <<city>> in the <<c/Republic of Macedonia>>}} would look
  wrong if `Republic of Macedonia` were converted to `North Macedonia` during display, as the result would be
  `a city in the North Macedonia`.) All of these aliases are sensitive to the placetype specified. For example, `Mexico`
  as a state is categorized under `State of Mexico` but `Mexico` the country is categorized as just `Mexico`.
* A ''placetype'' is the (or a) type that a toponym belongs to (e.g. `city`, `state`, `river`, `administrative region`,
  `[[regional county municipality]]`, etc.). Some placetypes themselves are ambiguous; e.g. a [[prefecture]] in the
  context of Japan is similar to a province, but a [[prefecture]] in France is the capital of a [[department]] (which
  is similar to a county). This is generally handled by giving one of the senses a qualifier; e.g. to refer to a
  French prefecture, use the placetype `French prefecture` instead of just `prefecture`. Placetypes support aliases,
  like placenames, and the mapping to canonical form happens early on in the processing. For example, `state` can be
  abbreviated as `s`; `administrative region` as `adr`; `regional county municipality` as `rcomun`; etc. Some placetype
  aliases handle alternative spellings rather than abbreviations. For example, `departmental capital` maps to
  `department capital`, and `home-rule city` maps to `home rule city`.
* A ''placetype qualifier'' is an adjective prepended to the placetype to give additional information about the
  place being described. For example, a given place may be described as a `small city`; logically this is still a city,
  but the qualifier `small` gives additional information about the place. Multiple qualifiers can be stacked, e.g.
  `small affluent beachfront unincorporated community`, where `unincorporated community` is a recognized placetype and
  `small`, `affluent` and `beachfront` are qualifiers. (As shown here, it may not always be obvious where the qualifiers
  end and the placetype begins.) For the most part, placetype qualifiers do not affect categorization; a `small city`
  is still a city and an `affluent beachfront unincorporated community` is still an unincorporated community, and both
  should still be categorized as such. But some qualifiers do change the categorization. In particular, a `former
  province` is no longer a province and should not be categorized in e.g. [[:Category:Provinces of Italy]], but instead
  in a different set of categories, e.g. [[:Category:Historical political subdivisions]]. There are several terms
  treated as equivalent for this purpose: `abandoned` `ancient`, `extinct`, `historic(al)`, `medi(a)eval` and
  `traditional`. Another set of qualifiers that change categorization are `fictional` and `mythological`, which cause
  any term using the qualifier to be categorized respectively into [[:Category:Fictional locations]] and
  [[:Category:Mythological locations]].
* A ''holonym'' is a placename that refers to a larger-sized entity that contains the toponym being described. For
  example, `Arizona` and `United States` are holonyms of `Tucson`, and `United States` is a holonym of `Arizona`.
* A ''place description'' consists of the description of a place, including its placetype or types, any holonyms, and
  any additional raw text needed to properly explain the place in context. Some places have more than one place
  description. For example, [[Vatican City]] is defined both as a city-state in Southern Europe and as an enclave within
  the city of Rome. This is done as follows:
  : {{tl|place|en|city-state|r/Southern Europe|;,|an <<enclave>> within the city of <<city/Rome>>, <<c/Italy>>|cat=Cities in Italy|official=Vatican City State}}.
  The use of two place descriptions allows for proper categorization. Similar things need to be done for places like
  [[Crimea]] that are claimed by two different countries with different definitions and administrative structures.
* A ''full place description'' consists of all the information known about the place. It consists of one or more place
  descriptions, zero or more English glosses (for foreign-language toponyms) and any attached ''extra information''
  such as the capital, largest city, official name, modern name or full name.
* Inside a place description, there are two types of placetypes. The ''entry placetypes'' are the placetypes of the
  place being described, while the ''holonym placetypes'' are the placetypes of the holonyms that the place being
  described is located within. Currently, a given place can have multiple placetypes specified (e.g. [[Normandy]] is
  specified as being simultaneously an administrative region, a historic province and a medieval kingdom) while a given
  holonym can have only one placetype associated with it.

===Place descriptions===

A given place description is defined internally in a table of the following form:

```{
  placetypes = {"``placetype``", "``placetype``", ...},
  holonyms = {
	{ -- holonym object; see below
	  placetype = "``placetype``" or nil,
	  display_placename = "``placename``",
	  cat_placename = "``placename``",
	  langcode = "``langcode``" or nil,
	  no_display = BOOLEAN,
	  needs_article = BOOLEAN,
	  force_the = BOOLEAN,
	  affix_type = "``affix_type``" or nil,
	  pluralize_affix = BOOLEAN,
	  suppress_affix = BOOLEAN,
	  continue_cat_loop = BOOLEAN,
	},
	...
  },
  order = { ``order_item``, ``order_item``, ... }, -- (only for new-style place descriptions),
  joiner = "``joiner_string``" or nil,
  holonyms_by_placetype = {
	``holonym_placetype`` = {"``placename``", "``placename``", ...},
	``holonym_placetype`` = {"``placename``", "``placename``", ...},
	...
  },
}```

Holonym objects have the following fields:
* `placetype`: The canonicalized placetype if specified as e.g. `c/Australia`; nil if no slash is present (in which case
			   the placename in `display_placename` refers to raw text).
* `display_placename`: The placename or raw text, in the format to be displayed. Placename display aliases have already
					   been resolved. It is raw text if `placetype` is nil.
* `cat_placename`: The placename or raw text, with links and HTML removed and with placename category aliases applied.
* `langcode`: The language code prefix if specified as e.g. `c/fr:Australie`; otherwise nil.
* `no_display`: If true (holonym prefixed with !), don't display the holonym but use it for categorization.
* `needs_article`: If true, prepend an article if the placename needs one (e.g. `United States`).
* `force_the`: If true, always prepend the article `the`. Example use: holoynm 'city:pref:the/Gold Coast', which gets
			   formatted as `(the) city of the [[Gold Coast]]`.
* `affix_type`: Type of affix to prepend (values `pref` or `Pref`) or append (values `suf` or `Suf`). The actual affix
				added is the placetype (capitalized if values `Pref` or `Suf` are given), or its plural if
				`pluralize_affix` is given. Note that some placetypes (e.g. `district` and `department`) have inherent
				affixes displayed after (or sometimes before) them.
* `pluralize_affix`: Pluralize any displayed affix. Used for holonyms like `c:pref/Canada,US`, which displays as
					 `the countries of Canada and the United States`.
* `suppress_affix`: Don't display any affix even if the placetype has an inherent affix. Used for the non-last
					placenames when there are multiple and a suffix is present, and for the non-first placenames when
					there are multiple and a prefix is present.
* `continue_cat_loop`: If true (holonym used :also), continue producing categories starting with this holonym when
					   preceding holonyms generated categories.

Note that new-style place descs (those specified as a single argument using <<...>> to denote placetypes, placetype
qualifiers and holonyms) have an additional `order` field to properly capture the raw text surrounding the items
denoted in double angle brackets. The ``order_item`` items in the `order` field are objects of the following form:

```{
  type = "``order_type``",
  value = "STRING" or INDEX,
}```

Here, the ``order_type`` is one of `"raw"`, `"qualifier"`, `"placetype"` or `"holonym"`:
* `"raw"` is used for raw text surrounding `<<...>>` specs.
* `"qualifier"` is used for `<<...>>` specs without slashes in them that consist only of qualifiers (e.g. the spec
  `<<former>>` in `<<former>> French <<colony>>`).
* `"placetype"` is used for `<<...>>` `specs without slashes that do not consist only of qualifiers.
* `"holonym"` is used for holonyms, i.e. `<<...>>` specs with a slash in them.
For all types but `"holonym"`, the value is a string, specifying the text in question. For `"holonym"`, the value is a
numeric index into the `holonyms` field.

It should be noted that placetypes and placenames occurring inside the holonyms structure are canonicalized, but
placetypes inside the placetypes structure are as specified by the user. Stripping off of qualifiers and
canonicalization of qualifiers and bare placetypes happens later.

The information under `holonyms_by_placetype` is redundant to the information in holonyms but makes categorization
easier. The holonym placenames listed here already have category aliases applied.

For example, the call {{tl|place|en|city|s/Pennsylvania|c/US}} will result in the return value

```{
  placetypes = {"city"},
  holonyms = {
	{ placetype = "state", display_placename = "Pennsylvania", cat_placename = "Pennsylvania" },
	{ placetype = "country", display_placename = "United States", cat_placename = "United States" },
  },
  holonyms_by_placetype = {
	state = {"Pennsylvania"},
	country = {"United States"},
  },
}```

Here, the placetype aliases `s` and `c` have been expanded into `state` and `country` respectively, and the placename
display alias `US` has been expanded into `United States`. PLACETYPES is a list because there may be more than one. For
example, the call {{tl|place|en|city/and/municipality|c/Congo}} will result in the return value

```
{
  placetypes = {"city", "and", "municipality"},
  holonyms = {
	{ placetype = "country", display_placename = "Congo", cat_placename = "Democratic Republic of the Congo" },
  },
  holonyms_by_placetype = {
	country = {"Democratic Republic of the Congo"},
  },
}```

Here, category aliases have converted `Congo` to `Democratic Republic of the Congo` for categorization but not display
purposes.

The value in the key/value pairs is likewise a list; e.g. the call {{tl|place|en|city|s/Kansas|and|s/Missouri}} will
return

```
{
  placetypes = {"city"},
  holonyms = {
	{ placetype = "state", display_placename = "Kansas", cat_placename = "Kansas" },
	{ display_placename = "and", cat_placename = "and" },
	{ placetype = "state", display_placename = "Missouri", cat_placename = "Missouri" },
  },
  holonyms_by_placetype = {
	state = {"Kansas", "Missouri"},
  },
}
```

Note that in `get_cats()` (which runs after the display form has been generated0, further changes to the holonym
structure are made to aid in categorization. For example, after `handle_category_implications()` and
`augment_holonyms_with_containing_polity()` are called, the above structure will look more like

```
{
  placetypes = {"city"},
  holonyms = {
	{ placetype = "state", display_placename = "Kansas", cat_placename = "Kansas" },
	{ placetype = "country", cat_placename = "United States" },
	{ display_placename = "and", cat_placename = "and" },
	{ placetype = "state", display_placename = "Missouri", cat_placename = "Missouri" },
	{ placetype = "country", cat_placename = "United States" },
  },
  holonyms_by_placetype = {
	state = {"Kansas", "Missouri"},
	country = {"United States"}
  },
}
```

===Category determination===

The algorithm to find the categories to which a given place belongs works off of a place description (which specifies
the entry placetype(s) and holonym(s); see above). Iterating over each entry placetype, it proceeds as follows:
# Look up the placetype in the `placetype_data`, which comes from [[Module:place/data]]. Note that the entry in
  `placetype_data` that specifies the category or categories to add may not directly correspond to the entry placetype
  as specified in the place description. For example, if the entry placetype is `"small town"`, the placetype whose data
  is fetched will be `"town"` since `"small"` is a recognized qualifier and there is no entry in `placetype_data` for
  `"small town"`. As another example, if the entry placetype is `"administrative capital"`, the placetype whose data
  will be fetched will be `"capital city"` because there's no entry in `placetype_data` for `"administrative capital"`
  but there is an entry in `placetype_equivs` in [[Module:place/data]] that maps `"administrative capital"` to
  `"capital city"` for categorization purposes.
# The value in `placetype_data` is a two-level table. The outer table is indexed by the holonym itself (e.g.
  `"country/Brazil"`) or by `"default"`, and the inner indexed by the holonym's placetype (e.g. `"country"`) or by
  `"itself"`. Note that most frequently, if the outer table is indexed by a holonym, the inner table will be indexed
  only by `"itself"`, while if the outer table is indexed by `"default"`, the inner table will be indexed by one or more
  holonym placetypes, meaning to generate a category for all holonyms of this placetype. But this is not necessarily the
  case.
# Iterate through the holonyms, from left to right, finding the first holonym that matches (in both placetype and
  placename) a key in the outer table. If no holonym matches any key, then if a key `"default"` exists, use that;
  otherwise, if a key named `"fallback"` exists, specifying a placetype, use that placetype to fetch a new
  `placetype_data` entry, and start over with step (1); otherwise, don't categorize.
# Iterate again through the holonyms, from left to right, finding the first holonym whose placetype matches a key in the
  inner table. If no holonym matches any key, then if a key `"itself"` exists, use that; otherwise, check for a key
  named `"fallback"` at the top level of the `placetype_data` entry and, if found, proceed as in step (3); otherwise
  don't categorize.
# The resulting value found is a list of category specs. Each category spec specifies a category to be added. In order
  to understand how category specs are processed, you have to understand the concept of the ''triggering holonym''. This
  is the holonym that matched an inner key in step (4), if any; else, the holonym that matched an outer key in step (3),
  if any; else, there is no triggering holonym. (The only time this happens when there are category specs is when the
  outer key is `"default"` and the inner key is `"itself"`.)
# Iterate through the category specs and construct a category from each one. Each category spec is one of the following:
## A string, such as `"Seas"`, `"Districts of England"` or `"Cities in +++"`. If `"+++"` is contained in the string, it
   will be substituted with the placename of the triggering holonym. If there is no triggering holonym, an error is
   thrown. This is then prefixed with the language code specified in the first argument to the call to {{tl|place}}.
   For example, if the triggering holonym is `"country/Brazil"`, the category spec is `"Cities in +++"` and the template
   invocation was {{tl|place|en|...}}, the resulting category will be [[:Category:en:Cities in Brazil]].
## The value `true`. If there is a triggering holonym, the spec `"``Placetypes`` in +++"` or `"``Placetypes`` of +++"`
   is constructed. (Here, ``Placetypes`` is the capitalized plural of the entry placetype whose placetype_data is being
   used, which is not necessarily the same as the entry placetype specified by the user; see the discussion above. The
   choice of `"in"` or `"of"` is based on the value of the `"preposition"` key at the top level of the entry in
   `placetype_data`, defaulting to `"in"`.) This spec is then processed as above. If there is no triggering holonym, the
   simple spec `"``Placetypes``"` is constructed (where ``Placetypes`` is as above).

For example, consider the following entry in placetype_data:

```
	["municipality"] = {
		preposition = "of",

		...

		["country/Brazil"] = {
			["state"] = {"Municipalities of +++, Brazil", "Municipalities of Brazil"},
			["country"] = {true},
		},

		...
	}
```

If the user uses a template call {{tl|place|pt|municipality|s/Amazonas|c/Brazil}}, the categories
[[:Category:pt:Municipalities of Amazonas, Brazil]] and [[:Category:pt:Municipalities of Brazil]] will be generated.
This is because the outer key `"country/Brazil"` matches the second holonym `"c/Brazil"` (by this point, the alias `"c"`
has been expanded to `"country"`), and the inner key `"state" matches the first holonym `"s/Amazonas"`, which serves as
the triggering holonym and is used to replace the `+++` in the first category spec.

Now imagine the user uses the template call {{tl|place|en|small municipality|c/Brazil}}. There is no entry in
`placetype_data` for `"small municipality"`, but `"small"` is a recognized qualifier, and there is an entry in
`placetype_data` for `"municipality"`, so that entry's data is used. Now, the second holonym `"c/Brazil"` will match the
outer key `"country/Brazil"` as before, but in this case the second holonym will also match the inner key `"country"`
and will serve as the triggering holonym.  The cat spec `true` will be expanded to `"Municipalities of +++"`, using the
placetype `"municipality"` corresponding to the entry in `placetype_data` (not the user-specified placetype `"small
municipality"`), and the preposition `"of"`, as specified in the `placetype_data` entry. The `+++` will then be expanded
to `"Brazil"` based on the triggering holonym, the language code `"en"` will be prepended, and the final category will
be [[:Category:en:Municipalities of Brazil]].
]==]


--[=[
TODO:

1. Neighborhoods should categorize at the city level. Categories like [[:Category:Places in Los Angeles]] exist but
   not [[:Category:Neighborhoods in Los Angeles]]; we can refactor the code in generic_cat_handler() to support this
   use case.
2. Display handlers should be smarter. For example, 'co/Travis' as a holonym should display as 'Travis County' in the
   United States, but (I think) display handlers don't currently have the full context of holonyms passed in to allow
   this to happen.
3. Connected to this, we have various display handlers that add the name of the holonym after or (sometimes) before the
   placename if it's not already there. An example is the county_display_handler() in [[Module:place/data]], which adds
   "County" before Ireland and Northern Ireland counties and after Taiwan and Romania counties. This should be
   integrated into the polity group for these respective polities through a setting rather than requiring a separate
   handler that has special casing for various polities.
4. Placetypes for toponyms should also have display handlers rather than just fixed text. This should allow us to
   dispense with the need for special types for "fpref" = "French prefecture" (which displays as "prefecture" but links
   to the appropriate Wikipedia article on Frenc prefectures, which are completely different from the more general
   concept of prefecture). Similarly for "Polish colony" and "Welsh community". ("Israeli settlement" should probably
   stay as-is because it displays as "Israeli settlement" not just "settlement".)
5. Currently, categories for e.g. states and territories of Australia go into
   [[:Category:States and territories of Australia]] but terms for states and territories of Australia go into
   (respectively) [[:Category:States of Australia]] and [[:Category:Territories of Australia]]. We should fix this;
   maybe this is as easy as setting cat_as in the respective poldiv definitions.
6. Probably cat_as should support raw categories as well as category types; raw categories would be indicated by being
   prefixed with "Category:".
7. Update documentation.
8. Rename remaining political subdivision categories to include name of country in them. [ALMOST DONE; ONLY RUSSIA IS
   LEFT, WHICH IS TRICKY BECAUSE OF THE PLETHORA OF DIFFERENT TYPES OF FEDERAL SUBJECTS AND ALTERNATIVE NAMES]
9. Add Pakistan provinces and territories. [DONE]
10. Add a polity group for continents and continent-level regions instead of special-casing. This should make it
    possible e.g. to have Jerusalem as a city under "Asia".
11. Add better handling of cities that are their own states, like Mexico City.
12. Breadcrumb for e.g. [[Category:Aguascalientes, Mexico]] is "Aguascalientes, Mexico" instead of just
    "Aguascalientes".
13. Unify aliasing system; cities have a completely different mechanism (alias_of) vs. polities/subpolities (which use
    `placename_cat_aliases` and `placename_display_aliases` in [[Module:place/data]]).
14. More generally, cities should be unified into the polity grouping system to the extent possible; this would allow
    for poldivs of cities (see #17 below).
15. We have `no_containing_polity_cat` set for Lebanon, Malta and Saudi Arabia to prevent country-level implications 
    from being added due to generically-named divisions like "North Governorate", "Central Region" and
	"Eastern Province" but (a) this setting seems to do multiple things and should be split, (b) it should be possible
	to set this at the division level instead of the country level.
16. Split out the data from the handlers so we can use loadData() on the data because it's becoming very big.
17. Cities like Tokyo have special wards; "prefecture-level cities" like Wuhan (which aren't really cities but we treat
    them as such) have districts, subdistricts, etc. We need to support poldivs for cities and even named divisions of
    cities (such as we already have for boroughs of New York City).
18. It should be allowed to set 'true' to any qualifier (which links it) and have it work correctly; qualifier lookup
    in [[Module:place]] needs to remove links first.
19. Categories 'Historical polities' and 'Historical political subdivisions' should be renamed 'Former ...' since
    "historic(al)" is ambiguous (cf. "historic counties" in England which are not former, but still have a legal
	definition).
20. It should be possible to categorize former subpolities of certain polities; cf. [[:Category:ja:Provinces of Japan]],
    which contains former provinces.
21. In subpolity_keydesc(), we need to generate the correct indefinite article and have a huge hack to check
    specifically for "union territory", which is the only placetype that shows up in this function where the default
    indefinite article generating function fails. To fix this properly, we need to separate out the non-category
    placetype data from `cat_data` in [[Module:place/data]] and move it to [[Module:place/shared-data]], because we
    don't have access to the data in [[Module:place/data]], and that data indicates the correct article for placetypes
    like "union territory".
22. Simplify the specs in `cat_data`, eliminating the distinction between "inner" and "outer" matching. There should not
    be two levels, just one. For example, in "district", instead of
		["country/Portugal"] = {
			["itself"] = {"Districts and autonomous regions of +++"},
		}
	we should just have
		["country/Portugal"] = {"Districts and autonomous regions of +++"},
	And in "dependent territory", instead of
		["default"] = {
			["itself"] = {true},
			["country"] = {true},
		},
	we should just have
		["itself"] = {true},
		["country/*"] = {true},
	It appears the only remaining spec that can't be easily converted in this fashion is for "subdistrict":
		["country/Indonesia"] = {
			["municipality"] = {true},
		},
	This seems to be specifically for Jakarta and doesn't seem to work anyway, as the two entries in
	[[:Category:en:Subdistricts of Jakarta]] and the one entry in [[:Category:id:Subdistricts of Jakarta]] are manually
	categorized.
23. Consolidate the remaining stuff in [[Module:category tree/topic cat/data/Earth]] into
	[[Module:category tree/topic cat/data/Places]].
24. The `generic_cat_handler` that categorizes into `Places in FOO` is smart enough not to categorize cities that are
    in different polities from the specified containing polity/polities of the city, but doesn't do the same for
    larger-level subdivisions. Likewise for the `city_type_cat_handler`. There are some sufficiently generically-named
    subdivisions that this issue can occur; for example, [[Koforidua]], the capital city of Eastern Region, Ghana, is
    incorrectly categoried under[[:Category:en:Cities in Eastern Region, Malta]] and
    [[:Category:en:Places in Eastern Region, Malta]]. Note that the function `augment_holonyms_with_containing_polity`
    ''DOES'' do such checks, so we should be able to refactor the code out of that function and use it elsewhere.
25. The `generic_cat_handler` that categorizes into `Places in FOO` is smart enough not to categorize cities that are
    in different polities from the specified containing polity/polities of the city; but how smart is it? It will
    successfully avoid categorizing a neighborhood in e.g. [[Columbus]], [[Georgia]] that doesn't explicitly mention the
    US (only `s/Georgia`) into [[:Category:en:Places in Columbus]], which is for Columbus, Ohio, but will it do the same
    for a hypothetical neighborhood of Columbus in say Merseyside, England? This should be investigated. It will
    probably work for a hypothetical Columbus in [[Canada]] because `augment_holonyms_with_containing_polity` would
    auto-add Canada as an additional holonym once say `p/Ontario` is mentioned, but I think there's a setting preventing
    this augmentation from happening for the UK. (This relates to FIXME #15. `no_containing_polity_cat` is set on
    England, Scotland, etc. to prevent the toponyms from being added to [[:Category:en:Places in the United Kingdom]],
    but this same setting is used to prevent augmentation, which it should not be; there should be different settings.)
26. The `generic_cat_handler` (or more specifically `find_holonym_keys_for_categorization`) checks for city holonyms
    by looking specifically for holonym type `city`. But some cities (particularly those in China) can be specified
    using different holonym types, e.g. `prefecture-level city`, `subprovincial city`, etc. We should allow these when
    appropriate (which means the cities in China need to have a `divtype` set that indicates their regional-level
    status as well as just `city`). I'm not sure if cities support specifying a custom `divtype` at the moment; this
    relates to FIXME #14 above concerning unifying cities and political subdivisions internally.
27. The bare category handler (`get_bare_categories` in [[Module:place/data]]) is not smart enough to avoid
    overcategorizing cities or other subdivisions that are of the right placetype but in the wrong containing polity.
    For example, Asturian [[Llión]] "León (city in Spain)" gets put in [[:Category:ast:León]] even though the latter is
    supposed to refer to a city in Mexico. We can borrow the check-containing-polity code from `generic_cat_handler`.
28. Redo handling of singular and plural to respect overrides specified in placetype_data. Check more carefully for
    things that may not singularize correctly, e.g. 'passes' -> 'passe'? Definitely 'headquarters' and variants.
29. Combine placetype_equivs and other placetype data into `placetype_data`. Figure out if we need the distinction
    between `placetype_equivs` and `fallback`.
30. `has_neighborhoods` may need to be a function that can look at the containing holonyms to determine whether the
    entity in question is city-like.
]=]


----------- Wikicode utility functions


-- Return a wikilink link {{l|language|text}}
local function link(text, langcode, id)
	if not langcode then
		return text
	end

	return m_links.full_link(
		{term = text, lang = require(languages_module).getByCode(langcode, true, "allow etym"), id = id},
		nil, "allow self link"
	)
end


---------- Basic utility functions


-- Add the page to a tracking "category". To see the pages in the "category",
-- go to [[Wiktionary:Tracking/place/PAGE]] and click on "What links here".
local function track(page)
	require(debug_track_module)("place/" .. page)
	return true
end


local function ucfirst_all(text)
	if text:find(" ") then
		local parts = split(text, " ", true)
		for i, part in ipairs(parts) do
			parts[i] = m_strutils.ucfirst(part)
		end
		return concat(parts, " ")
	else
		return m_strutils.ucfirst(text)
	end
end


local function lc(text)
	return mw.getContentLanguage():lc(text)
end


-- Return the article that is used with a place type. It is fetched from the placetype_data table; if that doesn’t
-- exist, "an" is given for words beginning with a vowel and "a" otherwise. If `ucfirst` is true, the first letter of
-- the article is made upper-case.
local function get_placetype_article(placetype, ucfirst)
	local art

	local pt_data = m_data.get_equiv_placetype_prop(placetype, function(pt) return placetype_data[pt] end)
	if pt_data and pt_data.article then
		art = pt_data.article
	else
		art = require(en_utilities_module).get_indefinite_article(placetype)
	end

	if ucfirst then
		art = m_strutils.ucfirst(art)
	end

	return art
end


-- Return the correct plural of a placetype, and (if `ucfirst` is given) make the first letter uppercase. We first look
-- up the plural in [[Module:place/data]], falling back to pluralize() in [[Module:en-utilities]], which is almost
-- always correct.
local function get_placetype_plural(placetype, ucfirst)
	local pt_data, equiv_placetype_and_qualifier = m_data.get_equiv_placetype_prop(placetype,
		function(pt) return placetype_data[pt] end)
	if pt_data then
		placetype = pt_data.plural or pluralize(equiv_placetype_and_qualifier.placetype)
	else
		placetype = pluralize(placetype)
	end
	if ucfirst then
		return m_strutils.ucfirst(placetype)
	else
		return placetype
	end
end


---------- Argument parsing functions and utilities


-- Split an argument on comma, but not comma followed by whitespace.
local function split_on_comma(val)
	if val:find(",") then
		return require(parse_interface_module).split_on_comma(val)
	else
		return {val}
	end
end


-- Split an argument on slash, but not slash occurring inside of HTML tags like </span> or <br />.
local function split_on_slash(arg)
	if arg:find("<") then
		local m_parse_utilities = require(parse_utilities_module)
		-- We implement this by parsing balanced segment runs involving <...>, and splitting on slash in the remainder.
		-- The result is a list of lists, so we have to rejoin the inner lists by concatenating.
		local segments = m_parse_utilities.parse_balanced_segment_run(arg, "<", ">")
		local slash_separated_groups = m_parse_utilities.split_alternating_runs(segments, "/")
		for i, group in ipairs(slash_separated_groups) do
			slash_separated_groups[i] = concat(group)
		end
		return slash_separated_groups
	else
		return split(arg, "/", true)
	end
end


-- Implement "implications", i.e. where the presence of a given holonym causes additional holonym(s) to be added.
-- Implications apply only to categorization. There used to be support for "general implications" that applied to both
-- display and categorization, but there ended up not being any such implications, so we've removed the support. It is
-- a bad idea in any case to have such implications; the user might purposely leave out a higher-level polity to avoid
-- redundancy in several successive definitions, and we wouldn't want to override that. Note that in practice the
-- mechanism implemented by this function is used specifically for non-administrative geographic regions such as
-- Eastern Europe and the West Bank; there is a similar mechanism for administrative regions handled by
-- `augment_holonyms_with_containing_polity` in [[Module:place/data]].
--
-- `place_descriptions` is a list of place descriptions (see top of file, collectively describing the data passed to
-- {{place}}). `implication_data` is the data used to implement the implications, i.e. a table indexed by holonym
-- placetype, each value of which is a table indexed by holonym placename, each value of which is a list of
-- "PLACETYPE/PLACENAME" holonyms to be added to the end of the list of holonyms.
local function handle_category_implications(place_descriptions, implication_data)
	for i, desc in ipairs(place_descriptions) do
		if desc.holonyms then
			local new_holonyms = {}
			for _, holonym in ipairs(desc.holonyms) do
				insert(new_holonyms, holonym)
				local imp_data = m_data.get_equiv_placetype_prop(holonym.placetype, function(pt)
					local implication = implication_data[pt] and implication_data[pt][holonym.cat_placename]
					if implication then
						return implication
					end
				end)
				if imp_data then
					for _, holonym_to_add in ipairs(imp_data) do
						local split_holonym = split_on_slash(holonym_to_add)
						if #split_holonym ~= 2 then
							error("Internal error: Invalid holonym in implications: " .. holonym_to_add)
						end
						local holonym_placetype, holonym_placename = unpack(split_holonym, 1, 2)
						local new_holonym = {
							-- By the time we run, the display has already been generated so we don't need to set
							-- display_placename.
							placetype = holonym_placetype, cat_placename = holonym_placename
						}
						insert(new_holonyms, new_holonym)
						m_data.key_holonym_into_place_desc(desc, new_holonym)
					end
				end
			end
			desc.holonyms = new_holonyms
		end
	end
end


-- Look up a placename in an alias table, handling links appropriately. If the alias isn't found, return nil.
local function lookup_placename_in_alias_table(placename, aliases)
	-- If the placename is a link, apply the alias inside the link.
	-- This pattern matches both piped and unpiped links. If the link is not
	-- piped, the second capture (linktext) will be empty.
	local link, linktext = rmatch(placename, "^%[%[([^|%]]+)%|?(.-)%]%]$")
	if link then
		if linktext ~= "" then
			local alias = aliases[linktext]
			return alias and "[[" .. link .. "|" .. alias .. "]]" or nil
		else
			local alias = aliases[link]
			return alias and "[[" .. alias .. "]]" or nil
		end
	else
		return aliases[placename]
	end
end


-- If `placename` of type `placetype` is an alias, convert it to its canonical form; otherwise, return unchanged.
local function resolve_placename_display_aliases(placetype, placename)
	return m_data.get_equiv_placetype_prop(placetype,
		function(pt) return m_data.placename_display_aliases[pt] and lookup_placename_in_alias_table(
			placename, m_data.placename_display_aliases[pt]) end
	) or placename
end


-- Split a holonym placename on commas but don't split on comma+space. This way, we split on
-- "Poland,Belarus,Ukraine" but keep "Tucson, Arizona" together.
local function split_holonym_placename(placename)
	if placename:find(", ") then
		local placenames = split(placename, ",", true)
		local retval = {}
		for i, placename in ipairs(placenames) do
			if i > 1 and placename:find("^ ") then
				retval[#retval] = retval[#retval] .. "," .. placename
			else
				insert(retval, placename)
			end
		end
		return retval
	else
		return split(placename, ",", true)
	end
end


-- Split a holonym (e.g. "continent/Europe" or "country/en:Italy" or "in southern" or "r:suf/O'Higgins" or
-- "c/Austria,Germany,Czech Republic") into its components. Return a list of holonym objects (see top of file). Note
-- that if there isn't a slash in the holonym (e.g. "in southern"), the `placetype` field of the holonym will be nil.
-- Placetype aliases (e.g. "r" for "region") and placename aliases (e.g. "US" or "USA" for "United States") will be
-- expanded.
local function split_holonym(raw)
	local no_display, combined_holonym = raw:match("^(!)(.*)$")
	no_display = not not no_display
	combined_holonym = combined_holonym or raw
	local suppress_comma, combined_holonym_without_comma = combined_holonym:match("^(%*)(.*)$")
	suppress_comma = not not suppress_comma
	combined_holonym = combined_holonym_without_comma or combined_holonym
	local holonym_parts = split_on_slash(combined_holonym)
	if #holonym_parts == 1 then
		-- `cat_placename` should not be used.
		return {{display_placename = combined_holonym, no_display = no_display, suppress_comma = suppress_comma}}
	end

	-- Rejoin further slashes in case of slash in holonym placename, e.g. Admaston/Bromley.
	local placetype = holonym_parts[1]
	local placename = concat(holonym_parts, "/", 2)

	-- Check for modifiers after the holonym placetype.
	local split_holonym_placetype = split(placetype, ":", true)
	placetype = split_holonym_placetype[1]
	local affix_type
	local saw_also
	local saw_the
	for i = 2, #split_holonym_placetype do
		local modifier = split_holonym_placetype[i]
		if modifier == "also" then
			if saw_also then
				error(("Modifier ':also' occurs twice in holonym '%s'"):format(combined_holonym))
			end
			saw_also = true
		elseif modifier == "the" then
			if saw_the then
				error(("Modifier ':the' occurs twice in holonym '%s'"):format(combined_holonym))
			end
			saw_the = true
		elseif modifier == "pref" or modifier == "Pref" or modifier == "suf" or modifier == "Suf" or
			modifier == "noaff" then
			if affix_type then
				error(("Affix-type modifier ':%s' occurs twice in holonym '%s'"):format(modifier, combined_holonym))
			end
			affix_type = modifier
		else
			error(("Unrecognized holonym placetype modifier '%s', should be one of " ..
				"'pref', 'Pref', 'suf', 'Suf', 'noaff', 'also' or 'the'"):format(modifier))
		end
	end

	placetype = m_data.resolve_placetype_aliases(placetype)
	local holonyms = split_holonym_placename(placename)
	local pluralize_affix = #holonyms > 1
	local affix_holonym_index = (affix_type == "pref" or affix_type == "Pref") and 1 or affix_type == "noaff" and 0 or #holonyms
	for i, placename in ipairs(holonyms) do
		-- Check for langcode before the holonym placename, but don't get tripped up by Wikipedia links, which begin
		-- "[[w:...]]" or "[[wikipedia:]]".
		local langcode, placename_without_langcode = rmatch(placename, "^([^%[%]]-):(.*)$")
		if langcode then
			placename = placename_without_langcode
		end
		placename = resolve_placename_display_aliases(placetype, placename)
		holonyms[i] = {
			placetype = placetype,
			display_placename = placename,
			cat_placename = m_data.resolve_placename_cat_aliases(placetype, placename),
			langcode = langcode,
			affix_type = i == affix_holonym_index and affix_type or nil,
			pluralize_affix = i == affix_holonym_index and pluralize_affix,
			suppress_affix = i ~= affix_holonym_index,
			no_display = no_display,
			suppress_comma = suppress_comma,
			continue_cat_loop = saw_also,
			force_the = i == 1 and saw_the,
		}
	end

	return holonyms
end


-- Apply a function to the non-HTML (including <<...>> segments) and non-Wikilink parts of `text`. We need to do
-- this especially so that we correctly handle holonyms (e.g. 'c/Italy') without getting confused by </span> and
-- similar HTML tags. The Wikilink exclusion is a bit less important but may still occur e.g. in links to
-- [[Admaston/Bromley]]. This is based on munge_text() in [[Module:munge text]].
--
-- FIXME: I added this as part of correctly handling embedded HTML in holonyms and placetypes, but I ended up not
-- using this in favor of [[Module:parse utilities]]. Delete if we likely won't need it in the future.
local function process_excluding_html_and_links(text, fn)
	local has_html = text:find("<")
	local has_link = text:find("%[%[")
	if not has_html and not has_link then
		return fn(text)
	end

	local function do_munge(text, pattern, functor)
		local index = 1
		local length = ulen(text)
		local result = ""
		pattern = "(.-)(" .. pattern .. ")"
		while index <= length do
			local first, last, before, match = rfind(text, pattern, index)
			if not first then
				result = result .. functor(mw.ustring.sub(text, index))
				break
			end
			result = result .. functor(before) .. match
			index = last + 1
		end
		return result
	end

	local function munge_text_with_html(txt)
		return do_munge(txt, "<[^<>]->", fn)
	end

	if has_link then -- contains wikitext links
		return do_munge(text, "%[%[[^%[%]]-%]%]", has_html and munge_text_with_html or fn)
	else -- HTML tags only
		return munge_text_with_html(text)
	end
end


--[==[
Parse a "new-style" place description, with placetypes and holonyms surrounded by `<<...>>` amid otherwise raw text.
Return value is an object as documented at the top of the file. Exported for use by [[Module:demonyms]].
]==]
function export.parse_new_style_place_desc(text)
	local placetypes = {}
	local segments = split(text, "<<(.-)>>")
	local retval = {holonyms = {}, order = {}}
	for i, segment in ipairs(segments) do
		if i % 2 == 1 then
			insert(retval.order, {type = "raw", value = segment})
		elseif segment:find("/") then
			local holonyms = split_holonym(segment)
			for j, holonym in ipairs(holonyms) do
				if j > 1 then
					if not holonym.no_display then
						if j == #holonyms then
							insert(retval.order, {type = "raw", value = " and "})
						else
							insert(retval.order, {type = "raw", value = ", "})
						end
					end
					-- All but the first in a multi-holonym need an article. For the first one, the article is
					-- specified in the raw text if needed. (Currently, needs_article is only used when displaying the
					-- holonym, so it wouldn't matter when no_display is set, but we set it anyway in case we need it
					-- for something else.)
					holonym.needs_article = true
				end
				insert(retval.holonyms, holonym)
				if not holonym.no_display then
					insert(retval.order, {type = "holonym", value = #retval.holonyms})
				end
				m_data.key_holonym_into_place_desc(retval, holonym)
			end
		else
			local treat_as, display = segment:match("^(..-):(.+)$")
			if treat_as then
				segment = treat_as
			else
				display = segment
			end
			-- see if the placetype segment is just qualifiers
			local only_qualifiers = true
			local split_segments = split(segment, " ", true)
			for _, split_segment in ipairs(split_segments) do
				if not m_data.placetype_qualifiers[split_segment] then
					only_qualifiers = false
					break
				end
			end
			insert(placetypes, {placetype = segment, only_qualifiers = only_qualifiers})
			if only_qualifiers then
				insert(retval.order, {type = "qualifier", value = display})
			else
				insert(retval.order, {type = "placetype", value = display})
			end
		end
	end

	local final_placetypes = {}
	for i, placetype in ipairs(placetypes) do
		if i > 1 and placetypes[i - 1].only_qualifiers then
			final_placetypes[#final_placetypes] = final_placetypes[#final_placetypes] .. " " .. placetypes[i].placetype
		else
			insert(final_placetypes, placetypes[i].placetype)
		end
	end
	retval.placetypes = final_placetypes
	return retval
end

--[=[
Process numeric args (except for the language code in 1=). `numargs` is a list of the numeric arguments passed to
{{place}} starting from 2=. The return value is a list of one or more place description objects, as described in the
long comment at the top of the file.
]=]
local function parse_place_descriptions(numargs)
	local descs = {}
	local this_desc
	-- Index of separate (semicolon-separated) place descriptions within `descs`.
	local desc_index = 1
	-- Index of separate holonyms within a place description. 0 means we've seen no holonyms and have yet to process
	-- the placetypes that precede the holonyms. 1 means we've seen no holonyms but have already processed the
	-- placetypes.
	local holonym_index = 0
	local last_was_new_style = false

	for _, arg in ipairs(numargs) do
		if arg == ";" or arg:find("^;[^ ]") then
			if not this_desc then
				error("Saw semicolon joiner without preceding place description")
			end
			if arg == ";" then
				this_desc.joiner = "; "
				this_desc.include_following_article = true
			elseif arg == ";;" then
				this_desc.joiner = " "
			else
				local joiner = arg:sub(2)
				if rfind(joiner, "^%a") then
					this_desc.joiner = " " .. joiner .. " "
				else
					this_desc.joiner = joiner .. " "
				end
			end
			desc_index = desc_index + 1
			holonym_index = 0
			last_was_new_style = false
		else
			if arg:find("<<") then
				if holonym_index > 0 then
					desc_index = desc_index + 1
					holonym_index = 0
				end
				this_desc = export.parse_new_style_place_desc(arg)
				descs[desc_index] = this_desc
				last_was_new_style = true
				holonym_index = holonym_index + 1
			else
				if last_was_new_style then
					error("Old-style arguments cannot directly follow new-style place description")
				end
				last_was_new_style = false
				if holonym_index == 0 then
					local entry_placetypes = split_on_slash(arg)
					this_desc = {placetypes = entry_placetypes, holonyms = {}}
					descs[desc_index] = this_desc
					holonym_index = holonym_index + 1
				else
					local holonyms = split_holonym(arg)
					for j, holonym in ipairs(holonyms) do
						if j > 1 then
						-- All but the first in a multi-holonym need an article. Not for the first one because e.g.
						-- {{place|en|city|s/Arizona|c/United States}} should not display as "a city in Arizona, the
						-- United States". The first holonym given gets an article if needed regardless of our setting
						-- here.
							holonym.needs_article = true
							-- Insert "and" before the last holonym.
							if j == #holonyms then
								this_desc.holonyms[holonym_index] = {
									-- Use the no_display value from the first holonym; it should be the same for all
									-- holonyms. `cat_placename` should not be used.
									display_placename = "and", no_display = holonyms[1].no_display
								}
								holonym_index = holonym_index + 1
							end
						end
						this_desc.holonyms[holonym_index] = holonym
						m_data.key_holonym_into_place_desc(this_desc, this_desc.holonyms[holonym_index])
						holonym_index = holonym_index + 1
					end
				end
			end
		end
	end

	-- Tracking code. This does nothing but add tracking for seen placetypes and qualifiers. The place will be linked to
	-- [[Wiktionary:Tracking/place/entry-placetype/PLACETYPE]] for all entry placetypes seen; in addition, if PLACETYPE
	-- has qualifiers (e.g. 'small city'), there will be links for the bare placetype minus qualifiers and separately
	-- for the qualifiers themselves:
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-placetype/BARE_PLACETYPE]]
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-qualifier/QUALIFIER]]
	-- Note that if there are multiple qualifiers, there will be links for each possible split. For example, for
	-- 'small maritime city'), there will be the following links:
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-placetype/small maritime city]]
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-placetype/maritime city]]
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-placetype/city]]
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-qualifier/small]]
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/entry-qualifier/maritime]]
	-- Finally, there are also links for holonym placetypes, e.g. if the holonym 'c/Italy' occurs, there will be the
	-- following link:
	--   [[Special:WhatLinksHere/Wiktionary:Tracking/place/holonym-placetype/country]]
	for _, desc in ipairs(descs) do
		for _, entry_placetype in ipairs(desc.placetypes) do
			local splits = m_data.split_qualifiers_from_placetype(entry_placetype, "no canon qualifiers")
			for _, split in ipairs(splits) do
				local prev_qualifier, this_qualifier, bare_placetype = unpack(split, 1, 3)
				track("entry-placetype/" .. bare_placetype)
				if this_qualifier then
					track("entry-qualifier/" .. this_qualifier)
				end
			end
		end
		for _, holonym in ipairs(desc.holonyms) do
			if holonym.placetype then
				track("holonym-placetype/" .. holonym.placetype)
			end
		end
	end

	return descs
end



-------- Definition-generating functions



-- Return a string with the wikilinks to the English translations of the word.
local function get_translations(transl, ids)
	local ret = {}

	for i, t in ipairs(transl) do
		local arg_transls = split_on_comma(t)
		local arg_ids = ids[i]
		if arg_ids then
			arg_ids = split_on_comma(arg_ids)
			if #arg_transls ~= #arg_ids then
				error(("Saw %s translation%s in t%s=%s but %s ID%s in tid%s=%s"):format(
					#arg_transls, #arg_transls > 1 and "s" or "", i == 1 and "" or i, t, #arg_ids,
					#arg_ids > 1 and "'s" or "", i == 1 and "" or i, ids[i]))
			end
		end
		for j, arg_transl in ipairs(arg_transls) do
			insert(ret, link(arg_transl, "en", arg_ids and arg_ids[j] or nil))
		end
	end

	return concat(ret, ", ")
end


-- Prepend the appropriate article if needed to `linked_placename`, where `holonym` is the underlying holonym object
-- that generated `linked_placename`. If `display_form` is true, we are formatting the holonym for display and need to
-- use the `display_placename` in `holonym`. In this case, `linked_placename` is the linked version of the display
-- placename, possibly modified due to a display handler and possibly with a placetype suffixed to the placename.
-- Otherwise, we are formatting the holonym for use in a category and `linked_placename` will be the same as
-- `cat_placename` in `holonym`.
local function get_holonym_article(holonym, linked_placename, display_form)
	local placetype = holonym.placetype
	local placename = display_form and holonym.display_placename or holonym.cat_placename
	placename = m_data.remove_links_and_html(placename)
	local unlinked_placename = m_data.remove_links_and_html(linked_placename)
	if unlinked_placename:find("^the ") then
		return nil
	end
	local art = m_data.get_equiv_placetype_prop(placetype, function(pt)
		return m_data.placename_article[pt] and m_data.placename_article[pt][placename] end)
	if art then
		return art
	end
	if not holonym.affix_type then
		-- See if the placetype requests an article to be placed before the holonym. This occurs e.g. with 'department',
		-- which has the setting `affix_type = "suf"` placing the word "department" after the holonym, so that
		-- "dept/Gironde" correctly generates "the Gironde department". But if the user overrode the affix type and e.g.
		-- specified "dept:pref/Gironde", we'll wrongly get "the department of the Gironde", so in that case we need to
		-- ignore the holonym article specified along with the placetype. (NOTE: We have since turned off the
		-- holonym_article on 'department'.)
		art = m_data.get_equiv_placetype_prop(placetype,
			function(pt) return placetype_data[pt] and placetype_data[pt].holonym_article end)
		if art then
			return art
		end
	end
	local universal_res = m_data.placename_the_re["*"]
	for _, re in ipairs(universal_res) do
		if unlinked_placename:find(re) then
			return "the"
		end
	end
	local matched = m_data.get_equiv_placetype_prop(placetype, function(pt)
		local res = m_data.placename_the_re[pt]
		if not res then
			return nil
		end
		for _, re in ipairs(res) do
			if unlinked_placename:find(re) then
				return true
			end
		end
		return nil
	end)
	if matched then
		return "the"
	end
	return nil
end


-- Convert a holonym into display or category format. If `display_form` is true, add wikilinks to holonyms and pass them
-- through any display handlers, which may (e.g.) add the placetype to the holonym. `display_form` is false if we're
-- formatting a holonym for use in a category name. If `needs_article` is true, prepend the article `"the"` if the
-- holonym requires it (e.g. if the holonym is `United States`). `needs_article` is set to true we are processing the
-- first specified holonym in an old-style place description (i.e. the holonym directly following the entry placetype,
-- with no raw-text holonym in between) or if we're generating a category with the formatted holonym following a
-- preposition `of` or `in`.
--
-- Examples:
-- ({placetype = "country", display_placename = "United States", cat_placename = "United States"}, true, true) returns
-- the template-expanded equivalent of "the {{l|en|United States}}".
-- ({placetype = "region", display_placename = "O'Higgins", cat_placename = "O'Higgins", affix_type = "suf"}, false,
--   true) returns the template-expanded equivalent of "{{l|en|O'Higgins}} region".
-- ({display_placename = "in the southern"}, false, true) returns "in the southern" (without wikilinking because
--   .placetype and .langcode are both nil).
local function format_holonym(holonym, needs_article, display_form)
	if display_form and holonym.no_display then
		return ""
	end

	local orig_needs_article = needs_article
	needs_article = needs_article or holonym.needs_article or holonym.force_the

	local output = display_form and holonym.display_placename or holonym.cat_placename
	local placetype = holonym.placetype
	local affix_type_pt_data, affix_type, affix_is_prefix, affix, prefix, suffix, no_affix_strings
	local pt_equiv_for_affix_type, already_seen_affix, need_affix

	if display_form then
		-- Implement display handlers.
		local display_handler = m_data.get_equiv_placetype_prop(placetype,
			function(pt) return placetype_data[pt] and placetype_data[pt].display_handler end)
		if display_handler then
			output = display_handler(placetype, output)
		end
		if not holonym.suppress_affix then
			-- Implement adding an affix (prefix or suffix) based on the holonym's placetype. The affix will be
			-- added either if the placetype's placetype_data spec says so (by setting 'affix_type'), or if the
			-- user explicitly called for this (e.g. by using 'r:suf/O'Higgins'). Before adding the affix,
			-- however, we check to see if the affix is already present (e.g. the placetype is "district"
			-- and the placename is "Mission District"). The placetype can override the affix to add (by setting
			-- `prefix`, `suffix` or `affix`) and/or override the strings used for checking if the affix is already
			-- present (by setting 'no_affix_strings', which defaults to the affix explicitly given through `prefix`,
			-- `suffix` or `affix` if any are given). `prefix` and `suffix` take precedence over `affix` if both are
			-- set, but only when the appropriate type of affix is requested.

			-- Search through equivalent placetypes for a setting of `affix_type`, `affix`, `prefix` or `suffix`. If we
			-- find any, use them. If `affix_type` is given, it is overridden by the user's explicitly specified affix
			-- type. If either an `affix_type` is found or the user explicitly specified an affix type, the affix is
			-- displayed according to the following:
			-- 1. If `prefix`, `suffix` or `affix` is given by the placetype or equivalent placetypes, use it (e.g.
			--    placetype `administrative region` requests suffix "region" but doesn't set affix type; if the user
			--    explicitly specifies `administrative region` as the placetype for a holonym and specifies a suffixal
			--    affix type, use "region"). In this search, we stop looking if we find an explicit `affix_type`
			--    setting; if this is found without an associated affix setting, the assumption is the associated
			--    placetype was intended as the affix, not some explicit affix setting associated with a fallback
			--    placetype.
			-- 2. Otherwise, if the user explicitly requested an affix type, use the actual placetype (principle of
			--    least surprise).
			-- 3. Finally, fall back to the placetype associated with an explicit `affix_type` setting (which will
			--    always exist if we get this far).
			affix_type_pt_data, pt_equiv_for_affix_type = m_data.get_equiv_placetype_prop(placetype,
				function(pt)
					local cdpt = placetype_data[pt]
					return cdpt and cdpt.affix_type and cdpt or nil
				end
			)
			affix_pt_data, pt_equiv_for_affix = m_data.get_equiv_placetype_prop(placetype,
				function(pt)
					local cdpt = placetype_data[pt]
					return cdpt and (cdpt.affix_type or cdpt.affix or cdpt.prefix or cdpt.suffix) and cdpt or nil
				end
			)
			if affix_type_pt_data then
				affix_type = affix_type_pt_data.affix_type
				need_affix = true
			end
			if affix_pt_data then
				prefix = affix_pt_data.prefix or affix_pt_data.affix
				suffix = affix_pt_data.suffix or affix_pt_data.affix
				need_affix = true
			end
			no_affix_strings = affix_pt_data and affix_pt_data.no_affix_strings or
				affix_type_pt_data and affix_type_pt_data.no_affix_strings
			if holonym.affix_type and placetype then
				affix_type = holonym.affix_type
				prefix = prefix or placetype
				suffix = suffix or placetype
				need_affix = true
			end
			if need_affix then
				-- At this point the affix_type has been determined and can't change any more, so we can figure out
				-- whether we need the calculated prefix or suffix.
				affix_is_prefix = affix_type == "pref" or affix_type == "Pref"
				if affix_is_prefix then
					affix = prefix
				else
					affix = suffix
				end
				if not affix then
					if not pt_equiv_for_affix_type then
						error("Internal error: Something wrong, `pt_equiv_for_affix_type` not set")
					end
					affix = pt_equiv_for_affix_type.placetype
					if not affix then
						error(("Internal error: Something wrong, no affix could be located in `pt_equiv_for_affix_type`: %s"):
								format(dump(pt_equiv_for_affix_type)))
					end
				end
				no_affix_strings = no_affix_strings or lc(affix)
				if holonym.pluralize_affix then
					affix = get_placetype_plural(affix)
				end
				already_seen_affix = m_data.check_already_seen_string(output, no_affix_strings)
			end
		end
		output = link(output, holonym.langcode or placetype and "en" or nil)
		if need_affix and not affix_is_prefix and not already_seen_affix then
			output = output .. " " .. (affix_type == "Suf" and ucfirst_all(affix) or affix)
		end
	end

	if needs_article then
		local article = holonym.force_the and "the" or get_holonym_article(holonym, output, display_form)
		if article then
			output = article .. " " .. output
		end
	end

	if display_form then
		if affix_is_prefix and not already_seen_affix then
			output = (affix_type == "Pref" and ucfirst_all(affix) or affix) .. " of " .. output
			if orig_needs_article then
				-- Put the article before the added affix if we're the first holonym in the place description. This is
				-- distinct from the article added above for the holonym itself; cf. "c:pref/United States,Canada" ->
				-- "the countries of the United States and Canada". We need to use the value of `needs_article` passed
				-- in from the function, which indicates whether we're processing the first holonym.
				output = "the " .. output
			end
		end
	end
	return output
end


-- Return the preposition that should be used after `placetype` (e.g. "city >in< France." but
-- "country >of< South America"). The preposition is fetched from the data module, defaulting to "in".
local function get_in_or_of(placetype)
	local preposition = "in"

	local pt_data = m_data.get_equiv_placetype_prop(placetype, function(pt) return placetype_data[pt] end)
	if pt_data and pt_data.preposition then
		preposition = pt_data.preposition
	end

	return preposition
end


-- Format a holonym for display, taking into account the entry's placetype (specifically, the last placetype if there
-- are more than one, excluding conjunctions and parenthetical items); the holonym preceding it in the template's
-- parameters (`prev_holonym`), and whether it is the first holonym (`first`). This may involve putting a preposition
-- ("in" or "of") before the formatted holonym, particularly if it is the first one, and may involve prepending a
-- comma.
local function format_holonym_in_context(entry_placetype, prev_holonym, holonym, first)
	local desc = ""

	-- If holonym.placetype is nil, the holonym is just raw text, e.g. 'in southern'.

	if not holonym.no_display then
		-- First compute the initial delimiter.
		if first then
			if holonym.placetype then
				desc = desc .. " " .. get_in_or_of(entry_placetype) .. " "
			elseif not holonym.display_placename:find("^,") then
				desc = desc .. " "
			end
		else
			if prev_holonym.placetype and holonym.display_placename ~= "and" and holonym.display_placename ~= "in" and
				not holonym.suppress_comma then
				desc = desc .. ","
			end

			if holonym.placetype or not holonym.display_placename:find("^,") then
				desc = desc .. " "
			end
		end
	end

	return desc .. format_holonym(holonym, first, true)
end


-- Get the display form of a placetype by looking it up in `placetype_links` in [[Module:place/data]]. If the placetype
-- is recognized, or is the plural if a recognized placetype, the corresponding linked display form is returned (with
-- plural placetypes displaying as plural but linked to the singular form of the placetype). Otherwise, return nil.
local function get_placetype_display_form(placetype)
	local linked_version = m_data.placetype_links[placetype]
	if linked_version then
		if linked_version == true then
			return "[[" .. placetype .. "]]"
		elseif linked_version == "w" then
			return "[[w:" .. placetype .. "|" .. placetype .. "]]"
		else
			return linked_version
		end
	end
	local sg_placetype = m_data.maybe_singularize(placetype)
	if sg_placetype then
		local linked_version = m_data.placetype_links[sg_placetype]
		if linked_version then
			if linked_version == true then
				return "[[" .. sg_placetype .. "|" .. placetype .. "]]"
			elseif linked_version == "w" then
				return "[[w:" .. sg_placetype .. "|" .. placetype .. "]]"
			else
				-- An explicit display form was specified. It will be singular, so we need to pluralize it to match
				-- the pluralization of the passed-in placetype.
				return pluralize(linked_version)
			end
		end
	end

	return nil
end


-- Return the linked description of a placetype. This splits off any qualifiers and displays them separately.
local function get_placetype_description(placetype)
	local splits = m_data.split_qualifiers_from_placetype(placetype)
	local prefix = ""
	for _, split in ipairs(splits) do
		local prev_qualifier, this_qualifier, bare_placetype = unpack(split, 1, 3)
		if this_qualifier then
			prefix = (prev_qualifier and prev_qualifier .. " " .. this_qualifier or this_qualifier) .. " "
		else
			prefix = ""
		end
		local display_form = get_placetype_display_form(bare_placetype)
		if display_form then
			return prefix .. display_form
		end
		placetype = bare_placetype
	end
	return prefix .. placetype
end


-- Return the linked description of a qualifier (which may be multiple words).
local function get_qualifier_description(qualifier)
	local splits = m_data.split_qualifiers_from_placetype(qualifier .. " foo")
	local split = splits[#splits]
	local prev_qualifier, this_qualifier, bare_placetype = unpack(split, 1, 3)
	return prev_qualifier and prev_qualifier .. " " .. this_qualifier or this_qualifier
end


local term_param_mods = {
	tr = {},
	ts = {},
	g = {
		-- We need to store the <g:...> inline modifier into the "genders" key of the parsed part, because that is what
		-- [[Module:links]] expects.
		item_dest = "genders",
		convert = function(arg, parse_err)
			return split(arg, ",", true)
		end,
	},
	id = {},
	alt = {},
	q = {},
	qq = {},
	sc = {
		convert = function(arg, parse_err)
			return arg and require("Module:scripts").getByCode(arg, parse_err) or nil
		end,
	}
}

-- Return a string with extra information that is sometimes added to a definition. This consists of the tag, a
-- whitespace and the value (wikilinked if it language contains a language code; if ucfirst == true, ". " is added
-- before the string and the first character is made upper case).
local function get_extra_info(args, paramname, tag, ucfirst, auto_plural, with_colon)
	local values = args[paramname]
	if not values then
		return ""
	end
	if type(values) ~= "table" then
		values = {values}
	end
	if #values == 0 then
		return ""
	end

	if auto_plural and #values > 1 then
		tag = pluralize(tag)
	end

	if with_colon then
		tag = tag .. ":"
	end

	local linked_values = {}

	for _, val in ipairs(values) do
		local function generate_obj(term, parse_err)
			local obj = {}
			if term:find(":") then
				local actual_term, termlang = require(parse_utilities_module).parse_term_with_lang {
					term = term,
					parse_err = parse_err
				}
				obj.term = actual_term
				obj.lang = termlang
			else
				obj.term = term
			end
			obj.lang = obj.lang or enlang
			return obj
		end

		local terms
		-- Check for inline modifier, e.g. מרים<tr:Miryem>. But exclude HTML entry with <span ...>, <i ...>, <br/> or
		-- similar in it, caused by wrapping an argument in {{l|...}}, {{af|...}} or similar. Basically, all tags of
		-- the sort we parse here should consist of a less-than sign, plus letters, plus a colon, e.g. <tr:...>, so if
		-- we see a tag on the outer level that isn't in this format, we don't try to parse it. The restriction to the
		-- outer level is to allow generated HTML inside of e.g. qualifier tags, such as foo<q:similar to {{m|fr|bar}}>.
		if val:find("<") and not val:find("^[^<]*<[a-z]*[^a-z:]") then
			terms = require(parse_utilities_module).parse_inline_modifiers(val, {
				paramname = paramname,
				param_mods = term_param_mods,
				generate_obj = generate_obj,
				splitchar = ",",
			})
		else
			if val:find(",<") then
				-- this happens when there's an embedded {{,}} template; easiest not to try and parse the extra info
				-- spec as multiple terms
				terms = {val}
			else
				terms = split_on_comma(val)
			end
			for i, split in ipairs(terms) do
				terms[i] = generate_obj(split)
			end
		end

		for _, term in ipairs(terms) do
			insert(linked_values, m_links.full_link(term, nil, "allow self link", "show qualifiers"))
		end
	end

	local s = ""

	if ucfirst then
		s = s .. ". " .. m_strutils.ucfirst(tag)
	else
		s = s .. "; " .. tag
	end

	return s .. " " .. m_table.serialCommaJoin(linked_values)
end


-- Format an old-style place description (with separate arguments for the placetype and each holonym) for display and
-- return the resulting string.
local function format_old_style_place_desc_for_display(args, place_desc, desc_index, with_article, ucfirst)
	-- The placetype used to determine whether "in" or "of" follows is the last placetype if there are
	-- multiple slash-separated placetypes, but ignoring "and", "or" and parenthesized notes
	-- such as "(one of 254)".
	local placetype_for_in_or_of = nil
	local placetypes = place_desc.placetypes
	local function is_and_or(item)
		return item == "and" or item == "or"
	end
	local parts = {}
	local function ins(txt)
		insert(parts, txt)
	end
	local function ins_space()
		if #parts > 0 then
			ins(" ")
		end
	end

	local and_or_pos
	for i, placetype in ipairs(placetypes) do
		if is_and_or(placetype) then
			and_or_pos = i
			-- no break here; we want the last in case of more than one
		end
	end

	local remaining_placetype_index
	if and_or_pos then
		track("multiple-placetypes-with-and")
		if and_or_pos == #placetypes then
			error("Conjunctions 'and' and 'or' cannot occur last in a set of slash-separated placetypes: " ..
				concat(placetypes, "/"))
		end
		local items = {}
		for i = 1, and_or_pos + 1 do
			local pt = placetypes[i]
			if is_and_or(pt) then
				-- skip
			elseif i > 1 and pt:find("^%(") then
				-- append placetypes beginning with a paren to previous item
				items[#items] = items[#items] .. " " .. pt
			else
				placetype_for_in_or_of = pt
				insert(items, get_placetype_description(pt))
			end
		end
		ins(m_table.serialCommaJoin(items, {conj = placetypes[and_or_pos]}))
		remaining_placetype_index = and_or_pos + 2
	else
		remaining_placetype_index = 1
	end

	for i = remaining_placetype_index, #placetypes do
		local pt = placetypes[i]
		-- Check for and, or and placetypes beginning with a paren (so that things like
		-- "{{place|en|county/(one of 254)|s/Texas}}" work).
		if m_data.placetype_is_ignorable(pt) then
			ins_space()
			ins(pt)
		else
			placetype_for_in_or_of = pt
			-- Join multiple placetypes with comma unless placetypes are already
			-- joined with "and". We allow "the" to precede the second placetype
			-- if they're not joined with "and" (so we get "city and county seat of ..."
			-- but "city, the county seat of ...").
			if i > 1 then
				ins(", ")
				local article = get_placetype_article(pt)
				if article ~= "the" and i > remaining_placetype_index then
					-- Track cases where we are comma-separating multiple placetypes without the second one starting
					-- with "the", as they may be mistakes. The occurrence of "the" is usually intentional, e.g.
					-- {{place|zh|municipality/state capital|s/Rio de Janeiro|c/Brazil|t1=Rio de Janeiro}}
					-- for the city of [[Rio de Janeiro]], which displays as "a municipality, the state capital of ...".
					track("multiple-placetypes-without-and-or-the")
				end
				ins(article)
				ins(" ")
			end

			ins(get_placetype_description(pt))
		end
	end

	if args.also then
		ins_space()
		ins("and ")
		ins(args.also)
	end

	if place_desc.holonyms then
		for i, holonym in ipairs(place_desc.holonyms) do
			local first = i == 1
			local prev_desc = first and {} or place_desc.holonyms[i - 1]
			ins(format_holonym_in_context(placetype_for_in_or_of, prev_desc, place_desc.holonyms[i], first))
		end
	end

	local gloss = concat(parts)

	if with_article then
		local article
		if desc_index == 1 then
			article = args.a
		else
			if not place_desc.holonyms then
				-- there isn't a following holonym; the place type given might be raw text as well, so don't add
				-- an article.
				with_article = false
			else
				local saw_placetype_holonym = false
				for _, holonym in ipairs(place_desc.holonyms) do
					if holonym.placetype then
						saw_placetype_holonym = true
						break
					end
				end
				if not saw_placetype_holonym then
					-- following holonym(s)s is/are just raw text; the place type given might be raw text as well,
					-- so don't add an article.
					with_article = false
				end
			end
			if with_article then
				track("second-or-higher-description-with-added-article")
			else
				track("second-or-higher-description-suppressed-article")
			end
		end
		if with_article then
			article = article or get_placetype_article(place_desc.placetypes[1], ucfirst)
			gloss = article .. " " .. gloss
		end
	end

	return gloss
end


--[==[
Get the full gloss (English description) of a new-style place description. New-style place descriptions are
specified with a single string containing raw text interspersed with placetypes and holonyms surrounded by `<<...>>`.
Exported for use by [[Module:demonyms]].
]==]
function export.format_new_style_place_desc_for_display(args, place_desc, with_article)
	local parts = {}

	if with_article and args.a then
		insert(parts, args.a .. " ")
	end

	for _, order in ipairs(place_desc.order) do
		local segment_type, segment = order.type, order.value
		if segment_type == "raw" then
			insert(parts, segment)
		elseif segment_type == "placetype" then
			insert(parts, get_placetype_description(segment))
		elseif segment_type == "qualifier" then
			insert(parts, get_qualifier_description(segment))
		elseif segment_type == "holonym" then
			insert(parts, format_holonym(place_desc.holonyms[segment], false, true))
		else
			error("Internal error: Unrecognized segment type '" .. segment_type .. "'")
		end
	end

	return concat(parts)
end


-- Return a string with the gloss (the description of the place itself, as opposed to translations). If `ucfirst` is
-- given, the gloss's first letter is made upper case and a period is added to the end. If `drop_extra_info` is given,
-- we don't include "extra info" (modern name, capital, largest city, etc.); this is used when transcluding into
-- another language using {{transclude sense}}.
local function get_diplay_form(args, descs, ucfirst, drop_extra_info)
	if args.def == "-" then
		return ""
	elseif args.def then
		if args.def:find("<<") then
			local def_desc = export.parse_new_style_place_desc(args.def)
			return export.format_new_style_place_desc_for_display({}, def_desc, false)
		else
			return args.def
		end
	end

	local glosses = {}
	local include_article = true
	local gloss_ucfirst = ucfirst
	for n, desc in ipairs(descs) do
		if desc.order then
			insert(glosses, export.format_new_style_place_desc_for_display(args, desc, n == 1))
		else
			insert(glosses, format_old_style_place_desc_for_display(args, desc, n, include_article, gloss_ucfirst))
		end
		if desc.joiner then
			insert(glosses, desc.joiner)
		end
		include_article = desc.include_following_article
		gloss_ucfirst = false
	end

	local ret = {concat(glosses)}

	if not drop_extra_info then
		insert(ret, get_extra_info(args, "modern", "modern", false, false, false))
		insert(ret, get_extra_info(args, "full", "in full,", false, false, false))
		insert(ret, get_extra_info(args, "short", "short form", false, false, false))
		insert(ret, get_extra_info(args, "official", "official name", ucfirst, "auto plural", "with colon"))
		insert(ret, get_extra_info(args, "capital", "capital", ucfirst, "auto plural", "with colon"))
		insert(ret, get_extra_info(args, "largest city", "largest city", ucfirst, "auto plural", "with colon"))
		insert(ret, get_extra_info(args, "caplc", "capital and largest city", ucfirst, false, "with colon"))
		local placetype = descs[1].placetypes[1]
		if placetype == "county" or placetype == "counties" then
			placetype = "county seat"
		elseif placetype == "parish" or placetype == "parishes" then
			placetype = "parish seat"
		elseif placetype == "borough" or placetype == "boroughs" then
			placetype = "borough seat"
		else
			placetype = "seat"
		end
		insert(ret, get_extra_info(args, "seat", placetype, ucfirst, "auto plural", "with colon"))
		insert(ret, get_extra_info(args, "shire town", "shire town", ucfirst, "auto plural", "with colon"))
		insert(ret, get_extra_info(args, "headquarters", "headquarters", ucfirst, false, "with colon"))
	end

	return concat(ret)
end

-- Old entry point. OBSOLETE ME!
export.get_new_style_gloss = export.format_new_style_place_desc_for_display

-- Return the definition line.
local function get_def(args, specs, drop_extra_info)
	if #args.t > 0 then
		local gloss = get_diplay_form(args, specs, false, drop_extra_info)
		return get_translations(args.t, args.tid) .. (gloss == "" and "" or " (" .. gloss .. ")")
	else
		return get_diplay_form(args, specs, true, drop_extra_info)
	end
end



---------- Functions for the category wikicode

-- The code in this section finds the categories to which a given place belongs. See comment at top of file.

--[=[
Find the appropriate category specs for a given place description and placetype; e.g. for the call
{{tl|place|en|city/and/county|s/Pennsylvania|c/US}} which results in the place description

```
{
	placetypes = {"city", "and", "county"},
	holonyms = {
		{placetype = "state", display_placename = "Pennsylvania", cat_placename = "Pennsylvania"},
		{placetype = "country", display_placename = "United States", cat_placename = "United States"},
	},
	holonyms_by_placetype = {
		state = {"Pennsylvania"},
		country = {"United States"},
	},
}
```

the call

```
find_placetype_cat_specs {
	entry_placetype = "city",
	place_desc = {
		placetypes = {"city", "and", "county"},
		holonyms = {
			{placetype = "state", display_placename = "Pennsylvania", cat_placename = "Pennsylvania"},
			{placetype = "country", display_placename = "United States", cat_placename = "United States"},
		},
		holonyms_by_placetype = {
			state = {"Pennsylvania"},
			country = {"United States"},
		},
	},
}
```

the return value might be

```
{
	entry_placetype = "city",
	cat_specs = {"Cities in +++, USA"},
	triggering_holonym = {placetype = "state", display_placename = "Pennsylvania", cat_placename = "Pennsylvania"},
	triggering_holonym_index = 1,
}
```

See the comment at the top of the section for a description of category specs and the overall algorithm.

On entry, `data` is an object with the following fields:
* `entry_placetype`: the entry placetype (or equivalent) used to look up the category data in placetype_data,
  which must have already been resolved to a placetype with an entry in `placetype_data`;
* `place_desc`: the full place description as documented at the top of the file (used only for its holonyms);
* `first_holonym_index`: the index of the first holonym to consider when iterating through the holonyms (used to
  implement the `:also` holonym placetype modifier);
* `overriding_holonym`: an optional overriding holonym to use, in place of iterating through the holonyms (used to
  implement categorizing other holonyms of the same type as the triggering holonym, so that e.g.
  {{place|en|river|s/Kansas,Nebraska}}, or equivalently {{place|en|river|s/Kansas|and|s/Nebraska}}, works);
* `ignore_cat_handler`: a flag to indicate whether to ignore category handlers (used by district_cat_handler);
* `from_demonym`: we are called from {{tl|demonym-noun}} or {{tl|demonym-adj}} instead of {{tl|place}}, and should
  generate categories appropriate to those templates.

The return value is an object with the following fields:
* `entry_placetype`: the placetype that should be used to construct categories when `true` is one of the returned
  category specs (normally the same as the `entry_placetype` passed in, but will be different when a "fallback" key
  exists and is used);
* `cat_specs`: list of category specs as described above, or nil if no specs could be located;
* `triggering_holonym`: the triggering holonym (see the comment at the top of the section), or nil if there was no
  triggering holonym;
* `triggering_holonym_index`: the index of the triggering holonym in the list of holonyms in `place_desc`, or nil if
  an overriding holonym was passed in or there was no triggering holonym;
]=]
local function find_placetype_cat_specs(data)
	local entry_placetype, place_desc, first_holonym_index, overriding_holonym =
		data.entry_placetype, data.place_desc, data.first_holonym_index, data.overriding_holonym
	local ignore_cat_handler, from_demonym = data.ignore_cat_handler, data.from_demonym
	local entry_placetype_data = placetype_data[entry_placetype]
	if not entry_placetype_data then
		error(("Internal error: Received entry placetype '%s' without any entry in placetype_data"):format(
			entry_placetype))
	end

	local function fetch_cat_specs(holonym_to_match, index)
		local holonym_placetype = holonym_to_match.placetype
		local holonym_placename = holonym_to_match.cat_placename
		local cat_specs = m_data.get_equiv_placetype_prop(holonym_placetype,
			function(pt) return entry_placetype_data[(pt or "") .. "/" .. holonym_placename] end)
		if cat_specs then
			return cat_specs
		end
		if not ignore_cat_handler and entry_placetype_data.cat_handler then
			local cat_specs = m_data.get_equiv_placetype_prop(holonym_placetype,
				function(pt) return entry_placetype_data.cat_handler {
					entry_placetype = entry_placetype,
					holonym_placetype = pt,
					holonym_placename = holonym_placename,
					holonym_index = index,
					place_desc = place_desc,
					from_demonym = from_demonym
				} end)
			if cat_specs then
				return cat_specs
			end
		end
		local cat_specs = m_data.get_equiv_placetype_prop(holonym_placetype,
			function(pt) return entry_placetype_data[(pt or "") .. "/*"] end)
		if cat_specs then
			return cat_specs
		end
		return nil
	end

	if overriding_holonym then
		-- FIXME, change the algorithm to eliminate overriding_holonym
		local cat_specs = fetch_cat_specs(overriding_holonym, nil)
		if cat_specs then
			return {
				entry_placetype = entry_placetype,
				cat_specs = cat_specs,
				triggering_holonym = overriding_holonym,
				-- no triggering_holonym_index
			}
		end
	else
		for i, holonym in ipairs(place_desc.holonyms) do
			if first_holonym_index and i < first_holonym_index then
				-- continue
			else
				cat_specs = fetch_cat_specs(holonym, i)
				if cat_specs then
					return {
						entry_placetype = entry_placetype,
						cat_specs = cat_specs,
						triggering_holonym = holonym,
						triggering_holonym_index = i,
					}
				end
			end
		end
	end

	local cat_specs = entry_placetype_data.default
	if cat_specs then
		return {
			entry_placetype = entry_placetype,
			cat_specs = cat_specs,
			-- no triggering holonym
		}
	end

	-- If we didn't find a matching spec, and there's a fallback, look it up. This is used, for example, with "rural
	-- municipality", which has special cases for some provinces of Canada and otherwise behaves like "municipality".
	if not cat_specs and entry_placetype_data.fallback then
		return find_placetype_cat_specs {
			entry_placetype = entry_placetype_data.fallback,
			place_desc = place_desc,
			first_holonym_index = first_holonym_index,
			overriding_holonym = overriding_holonym,
			-- This is what was here before; it seems a good idea to not ignore cat handlers on fallback as it's a
			-- different placetype.
			ignore_cat_handler = false,
			from_demonym = from_demonym,
		}
	end

	return {
		entry_placetype = entry_placetype,
		-- no cat_specs, no triggering_holonym
	}
--[=[ I don't think this is applicable anymore. When we're sure of this, delete it.

	-- HACK! `district_cat_handler()` needs to handle the fact that "district" can have two meanings, a "local" one
	-- that's equivalent to a neighborhood and a "non-local" one that's a type of political subdivision (the
	-- specifics depend on the country). In particular we need to handle both of the following cases:
	-- {{place|te|t=Kadapa|district|city/Visakhapatnam|s/Andhra Pradesh|c/India}}
	-- {{place|te|t=Kadapa|district|s/Andhra Pradesh|c/India}}
	-- The first case needs to categorize into e.g. [[:Category:te:Neighborhoods in Andhra Pradesh]] while the second
	-- categorizes into e.g. [[:Category:te:Districts of India]]. The categorization into "Districts of India" is
	-- handled courtesy of the fact that "district" listed in [[Module:place/shared-data]] as a political subdivision
	-- of India, which happens independently of district_cat_handler() (which is there to take care of the neighborhood
	-- meaning of "district"). This is taken care of by having `district_cat_handler()` return a spec that handles the
	-- various types of city-like entities (e.g. boroughs) as well as specifying `restart_ignoring_cat_handler`. If no
	-- holonym is found matching the city-like entities, the following clause restarts skipping
	-- `district_cat_handler()`, which eventually categorizes based on the holonym "India".
	if inner_data.restart_ignoring_cat_handler then
		return find_placetype_cat_specs {
			entry_placetype = entry_placetype,
			place_desc = place_desc,
			first_holonym_index = first_holonym_index,
			overriding_holonym = overriding_holonym,
			ignore_cat_handler = true,
			from_demonym = from_demonym,
		}
	end
]=]
end


-- Turn a list of category specs (see comment at section top) into the corresponding categories (minus the language
-- code prefix). The function is given the following arguments:
-- (1) the category specs retrieved using find_placetype_cat_specs();
-- (2) the entry placetype used to fetch the entry in `placetype_data`
-- (3) the triggering holonym (a holonym object; see comment at top of file) used to fetch the category specs
--     (see top-of-section comment); or nil if no triggering holonym.
-- The return value is constructed as described in the top-of-section comment.
local function cat_specs_to_categories(cat_specs, entry_placetype, holonym)
	local all_cats = {}

	if holonym then
		local holonym_placetype, holonym_placename = holonym.placetype, holonym.cat_placename
		for _, cat_spec in ipairs(cat_specs) do
			local cat
			if cat_spec == true then
				cat = get_placetype_plural(entry_placetype, "ucfirst") .. " " .. get_in_or_of(entry_placetype)
					.. " +++"
			else
				cat = cat_spec
			end

			if cat:find("%+%+%+") then
				local equiv_holonym = m_table.shallowCopy(holonym)
				equiv_holonym.placetype = holonym_placetype
				cat = cat:gsub("%+%+%+", format_holonym(equiv_holonym, true, false))
			end
			insert(all_cats, cat)
		end
	else
		for _, cat_spec in ipairs(cat_specs) do
			local cat
			if cat_spec == true then
				cat = get_placetype_plural(entry_placetype, "ucfirst")
			else
				cat = cat_spec
				if cat:find("%+%+%+") then
					error("Category '" .. cat .. "' contains +++ but there is no holonym to substitute")
				end
			end
			insert(all_cats, cat)
		end
	end

	return all_cats
end


-- Return the categories (without initial lang code) that should be added to the entry, given the place description
-- (which specifies the entry placetype(s) and holonym(s); see top of file) and a particular entry placetype (e.g.
-- "city"). Note that only the holonyms from the place description are looked at, not the entry placetypes in the place
-- description.
local function get_placetype_cats(place_desc, entry_placetype, from_demonym)
	local entry_pt_data, equiv_entry_placetype_and_qualifier =
		m_data.get_equiv_placetype_prop(entry_placetype, function(pt) return placetype_data[pt] end)

	-- Check for unrecognized placetype.
	if not entry_pt_data then
		return {}
	end

	local cats = {}

	local equiv_entry_placetype = equiv_entry_placetype_and_qualifier.placetype

	local first_holonym_index = 1
	while first_holonym_index <= #place_desc.holonyms do
		-- Find the category specs (see top-of-file comment) corresponding to the holonym(s) in the place description.
		local cat_data = find_placetype_cat_specs {
			entry_placetype = equiv_entry_placetype,
			place_desc = place_desc,
			first_holonym_index = first_holonym_index,
			from_demonym = from_demonym,
		}

		-- Check if no category spec could be found. This happens if the innermost table in the category data
		-- doesn't match any holonym's placetype and doesn't have an "itself" entry.
		if not cat_data.cat_specs then
			return {}
		end

		local triggering_holonym = cat_data.triggering_holonym
		-- Generate categories for the category specs found.
		extend(cats, cat_specs_to_categories(cat_data.cat_specs, cat_data.entry_placetype, triggering_holonym))

		if not triggering_holonym then
			return cats
		end

		-- If there's a triggering holonym (see top-of-file comment), also generate categories for other holonyms
		-- of the same placetype, so that e.g. {{place|en|city|s/Kansas|and|s/Missouri|c/USA}} generates both
		-- [[:Category:en:Cities in Kansas, USA]] and [[:Category:en:Cities in Missouri, USA]].
		first_holonym_index = cat_data.triggering_holonym_index
		for _, other_placename_of_same_type in ipairs(place_desc.holonyms_by_placetype[triggering_holonym.placetype]) do
			if other_placename_of_same_type ~= triggering_holonym.cat_placename then
				local overriding_holonym = {
					placetype = triggering_holonym.placetype, placename = other_placename_of_same_type
				}
				local other_cat_data = find_placetype_cat_specs {
						entry_placetype = equiv_entry_placetype,
						place_desc = place_desc,
						overriding_holonym = overriding_holonym,
						from_demonym = from_demonym,
					}
				if other_cat_data.cat_specs then
					extend(cats, cat_specs_to_categories(other_cat_data.cat_specs, other_cat_data.entry_placetype,
						other_cat_data.triggering_holonym))
				end
			end
		end

		-- If there are any later-specified holonyms that had the modifier :also, try to produce categories for them
		-- as well.
		first_holonym_index = first_holonym_index + 1
		while first_holonym_index <= #place_desc.holonyms do
			if place_desc.holonyms[first_holonym_index].continue_cat_loop then
				break
			end
			first_holonym_index = first_holonym_index + 1
		end
	end

	return cats
end


--[==[
Iterate through each type of place given `place_descriptions` (a list of place descriptions, as documented at the
top of the file) and return a list of the categories that need to be added to the entry. The returned categories need to
be prefixed with the langcode to get the actual Wiktionary categories, and passed to `format_categories` in
[[Module:utilities]] to format the categories into strings. `args` is the table of user-specified arguments, used
primarily to add "bare categories" corresponding to toponyms for known cities and political subdivisions.
`from_demonym` is true if we're being called from {{tl|demonym-noun}} or {{tl|demonym-adj}}. In this case, we only want
certain categories added, specifically bare categories corresponding to the most specific specified holonym(s).
]==]
function export.get_cats(args, place_descriptions, from_demonym)
	local cats = {}

	handle_category_implications(place_descriptions, m_data.cat_implications)
	m_data.augment_holonyms_with_containing_polity(place_descriptions)

	if not from_demonym then
		local bare_categories = m_data.get_bare_categories(args, place_descriptions)
		extend(cats, bare_categories)
	end

	for _, place_desc in ipairs(place_descriptions) do
		if not from_demonym then
			for _, placetype in ipairs(place_desc.placetypes) do
				if not m_data.placetype_is_ignorable(placetype) then
					extend(cats, get_placetype_cats(place_desc, placetype))
				end
			end
		end
		-- Also add base categories for the holonyms listed (e.g. a category like
		-- [[Category:Places in Merseyside, England]]). This is handled through the special placetype "*".
		extend(cats, get_placetype_cats(place_desc, "*", from_demonym))
	end

	if args.cat then -- not necessarily when called from [[Module:demonym]]
		extend(cats, args.cat)
	end

	return cats
end


-- Return the category link for a category, given the language code and the name of the category.
local function format_cats(lang, cats, sort_key)
	local full_cats = {}
	local langcode = lang:getFullCode()
	for _, cat in ipairs(cats) do
		-- FIXME: Why are we calling remove_links_and_html() here? Why can there be links in the categories?
		insert(full_cats, langcode .. ":" .. m_data.remove_links_and_html(cat))
	end
	return require(utilities_module).format_categories(full_cats, lang, sort_key, nil, force_cat or m_data.force_cat)
end



----------- Main entry point


--[==[
Implementation of {{tl|place}}. Meant to be callable from another module (specifically, [[Module:transclude/sense]]).
`drop_extra_info` means to not include "extra info" (modern name, capital, largest city, etc.); this is used when
transcluding into another language using {{tl|transclude sense}}.
]==]
function export.format(template_args, drop_extra_info)
	local list_param = {list = true}
	local params = {
		[1] = {required = true, type = "language", default = "und"},
		[2] = {required = true, list = true},
		["t"] = list_param,
		["tid"] = {list = true, allow_holes = true},
		["cat"] = list_param,
		["nocat"] = {type = "boolean"},
		["sort"] = true,
		["pagename"] = true, -- for testing or documentation purposes

		["a"] = true,
		["also"] = true,
		["def"] = true,

		-- params that are only used when transcluding using {{tcl}}/{{transclude}}
		["tcl"] = true,
		["tcl_t"] = list_param,
		["tcl_tid"] = list_param,
		["tcl_nolb"] = true,

		-- "extra info" that can be included
		["modern"] = list_param,
		["full"] = list_param,
		["short"] = list_param,
		["official"] = list_param,
		["capital"] = list_param,
		["largest city"] = list_param,
		["caplc"] = true,
		["seat"] = list_param,
		["shire town"] = list_param,
		["headquarters"] = list_param,
	}

	-- FIXME, once we've flushed out any uses, delete the following clause. That will cause def= to be ignored.
	if template_args.def == "" then
		error("Cannot currently pass def= as an empty parameter; use def=- if you want to suppress the definition display")
	end
	local args = require("Module:parameters").process(template_args, params)
	local place_descriptions = parse_place_descriptions(args[2])

	return get_def(args, place_descriptions, drop_extra_info) .. (
		args.nocat and "" or format_cats(args[1], export.get_cats(args, place_descriptions), args.sort))
end


--[==[
Actual entry point of {{tl|place}}.
]==]
function export.show(frame)
	return export.format(frame:getParent().args)
end


return export
