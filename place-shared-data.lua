local export = {}
--[=[
This module contains data shared between [[Module:place/data]] and [[Module:category tree/topic cat/data/Places]].
You must load this module using require(), not using mw.loadData().
]=]

export.force_cat = false -- set to true to force category generation even on non-mainspace pages

local m_table = require("Module:table")
local en_utilities_module = "Module:en-utilities"
local topic_cat_utilities_module = "Module:category tree/topic cat/utilities"

local dump = mw.dumpObject

--[==[ intro:

===Introduction===

This module contains lists of all the locations (continents, countries, country divisions such as states and provinces,
and cities) and their properties, along with some information about placetypes (the remainder is found in
[[Module:place/data]]). See [[Module:place]] for a general introduction to the terminology associated with places along
with a list of all the relevant modules, and the description below for more specific information on types of locations
and placetypes and how their categorization works.

The basic terminology used in this and associated {{tl|place}} modules is:
# A ''location'' (or equivalently, a ''place'') is any geographic feature of the Earth (or more generally the universe,
  since we are able to describe planets, moons, stars, asteroids and other geographic features outside of the Earth),
  which can include:
## ''Natural features'' such as lakes, mountains, mountain ranges, islands, archipelagoes, etc.
## ''Continents'', ''supercontinents'' (groupings of continents where it makes sense, such as `America` and `Eurasia`)
   and ''continent-level regions'' (grouping of countries in a given continent, such as `Central America` and
   `Polynesia`).
## ''Political entities'', which are generally classified as either ''polities'' (top-level entities such as countries),
   ''subpolities'' (non-sovereign divisions, generally ''administrative divisions'', of a polity), or ''cities''.
## ''Geographic regions'', which refer to recognized areas of the Earth (either with a natural geographic, political or
   cultural significance, often of a historical nature). Such regions can be of greatly varying size, may exist either
   within a single country or spanning multiple countries or (more often) parts of multiple countries, and may not have
   well-defined boundaries. They should be distinguished from ''administrative regions'', which exist within a single
   country and have well-defined boundaries and a political or administrative function. Geographic regions are
   categorized using the generic term ''geographic and cultural areas'' to emphasize that (a) they have no
   administrative significance; (b) they may vary greatly in size; and (c) their cohesion is due either to natural
   geographic boundaries, such as rivers or mountain ranges, or to sharing some cultural characteristics.
# A ''known location'' is a location whose properties are specifically defined in this module. Generally each such
  location has an associated category, and known locations exist in a containment hierarchy, where the immediately
  containing known location is known as the ''container'' of the location. Generally the location's container
  corresponds to the first parent of its category. The following types of known locations are defined in this module:
## Continents, supercontinents and continent-level regions, into which countries are grouped. Specifically:
### At the top level below `Earth` are the supercontinents `America` and `Eurasia` and the continents `Africa`,
	`Oceania` and `Antartica`.
### `America` is further broken down into the continents `North America` (in turn containing the continental regions
	`Central America` and `Caribbean`, with the United States, Canada and Mexico directly under North America) and
	`South America`.
### `Eurasia` is further broken down into the continents `Europe` and `Asia`.
### `Oceania` is further broken down into the continental regions `Melanesia`, `Micronesia` and `Polynesia`, with
	Australia` directly under `Oceania.
### Under the above-specified divisions are countries. Some countries are placed in more than one continent or
	continent-level region, either because they actually span two continents (e.g. Russia, Turkey, Kazakhstan, Egypt) or
	because they are politically considered to belong to a continent different from the one they are geographically in
	(Cyprus, Georgia, Armenia, etc.).
## Political entities, including:
### Top-level political entities, which includes:
#### Countries, with a fairly liberal definition, notably including all UN-recognized countries plus some others that
	 are commonly considered countries, even if not all other countries recognize them as such or consider them
	 completely independent (notably, Kosovo, Palestine, Taiwan, Western Sahara, Niue and the Cook Islands).
#### Pseudo-countries, which include areas calling themselves countries that are de-facto not under the control of the
	 country that they are internationally considered part of (e.g. Abkhazia, South Ossetia, Transnistria);
	 dependent/external/etc. territories of countries (e.g. American Samoa [US], Bermuda [UK], Christmas Island
	 [Australia], Easter Island [Chile]); constituent countries, autonomous territories and the like (Aruba, Curaçao and
	 Sint Maarten of the Netherlands; Greenland and the Faroe Islands of Denmark; etc.; but notably not including
	 England, Scotland, Northern Ireland and Wales, which are treated as regular countries); and a grab bag of other
	 entities that have a semi-independent existence, such as Hong Kong, Macau, Guadeloupe, Martinique and the like.
	 Currently, the actual distinction in treatment between "countries" and "country-like entities" is minimal, but in
	 the future we might restrict the sorts of subcategories of country-like entities more than regular countries.
#### Former countries, e.g. the Soviet Union, Yugoslavia, West Germany and the Roman Empire. These are much more limited
	 in the sorts of subcategories allowed, because generally locations, especially cities, should be described from the
	 perspective of which political entity they are currently located in (e.g. "an ancient Roman town in modern Syria")
	 and categorized as such.
### Subpolities. Generally we only list top-level administrative divisions of countries (and only fairly major countries
	are usually included), but sometimes we list second-level administrative divisions, as in the case of the
	United Kingdom (where the top-level administrative divisions of the four constituent countries are listed) and China
	(where major prefecture-level cities are listed, and are considered administrative divisions rather than cities).
### Cities. Only major cities get categories, with the definition of "major" varying by country but often including
	those where the city population itself (sometimes the metro area) is >= 1,000,000 people.
# A ''placetype'' is the type of any location, generally corresponding to how Wikipedia describes the location. It is
  common for locations to be described using multiple placetypes, and even sometimes known locations have multiple
  placetypes that they may be identified by (e.g. American Samoa can be identified either as an "unincorporated
  territory", an "overseas territory" or just a "territory"). Placetypes can be categorized as:
## Political divisions (states, provinces, counties, etc.).
## Non-political or "miscellaneous" divisions (such as divisions used for census purposes which are considered important
   enough to categorize).
## "Generic" placetypes that are likely to exist in every polity or subpolity (cities, towns, villages, rivers, etc.).
## Meta-placetypes, specifically `place`, which exists in every known location and is treated like a generic placetype.
# A ''toponym'' is a name by which a location may be known. Locations are often known by more than one toponym (such as
  `United States`, `United States of America`, `the United States`, `USA`, etc.). Cities and subpolities may or may not
  include the containing location in their name (e.g. `Arizona` or `Arizona, USA`). Toponyms may be:
## ''simple'' (not including any containing location in its name, such as `Tucson`) or ''multipart'' (including one or
   more containing locations, such as `Tucson, Arizona` or `Tucson, USA` or even `Tucson, Arizona, USA`);
## ''bare'' (not including the word `the` if the location normally requires this article when following a preposition,
   such as `United States`, `Gambia` or 'Community of Madrid') or ''prefixed'' (including the word `the` as needed, such
   as `the United States`, `the Gambia` or `the Community of Madrid`);
## ''elliptical'' (just the placename without any disambiguating placetype, such as `Durham`, `New York` or `Mexico`) or
   ''full'' (containing a disambiguating placetype or similar identifier if one is commonly included, such as
   the city of `Durham` (in England) vs. its containing county `County Durham`; the US city `New York City` vs. its
   containing state `New York`; or the three-way distinction between `Mexico` (the country), `Mexico City` (the capital
   of this country) and `(the) State of Mexico` (one of the states of the country Mexico, mostly surrounding but not
   including Mexico City)).
# The ''place description'' containined in an invocation of {{tl|place}} consists, generally, of one or more
  ''entry placetypes'' (the placetype(s) of the location itself; see the definition of ''placetype'' above); zero or
  more ''holonyms'' (locations in which the place in question is contained, of the form ` ``placetype``/``placename`` `,
  e.g. `c/Mexico` for the country of Mexico; they consist of an often-abbreviated placetype and a placename that is
  usually in the same format as the canonical Wiktionary article describing the location; see below); and
  ''surrounding text'', which is displayed as-is.
# The ''canonical Wiktionary article'' is the main article on Wiktionary where a location is described. Canonical
  articles, per the above terminology, are generally ''simple'' and ''bare'', but may be either ''full'' or
  ''elliptical''. The fact that a given article is canonical is often identifiable by the fact that translations are
  housed there an not somewhere else. For example, most counties of the US and Canada include the word `County` in their
  canonical article name, but most counties elsewhere do not. `Washington, D.C.` is one of the few cases where a
  non-simple toponym is used as the canonical article; this is based on common usage, especially by residents of the
  city in question (who commonly refer to it as "D.C." but rarely just as "Washington").
# A distinction should be made in the {{tl|place}} modules between ''keys'' and ''placenames''. Placenames are as the
  location appears in a holonym, and are generally in the same format as the canonical Wiktionary article describing the
  location so that when formatted as a link, the link goes to the right article; i.e. they are simple and bare, and may
  be full or elliptical according to Wiktionary conventions. The ''canonical key'' of a location is how the location's
  category is named, and always uniquely identifies the location from among the known locations in this module (but
  not necessarily among all possible locations). In particular, subpolities usually have multipart keys that include the
  containing location, such as `Anhui, China` (not just `Anhui`); `Arizona, USA` (not just `Arizona`, and also not
  `Arizona, United States`); and `Herefordshire, England` (not just `Herefordshire`, and also in this case not
  `Herefordshire, UK` or `Herefordshire, England, UK` or any other possible variation). Cities are normally simple, but
  some cities are multipart for disambiguation purposes (e.g. `Newcastle, New South Wales` for the city in Australia vs.
  `Newcastle upon Tyne` for the identically-named city in England). Canonical keys may have ''key aliases'', other
  ways of referring to the location that are not necessarily unique (e.g. `Newcastle` is a key alias for both of the
  above-mentioned cities), and city keys with diacritics generally have diacriticless aliases, such as canonical key
  `Düsseldorf` vs. key alias `Dusseldorf`, or canonical key `Łódź` vs. key alias `Lodz`.
# Known locations are gathered into ''groups'' with similar properties, such as all the states of the United States;
  all the (ceremonial) counties of England (see below); and all the "sufficiently major" prefecture-level cities in
  China (where a prefecture-level city is a prefecture surrounding a major city with a unified government and is more
  like a prefecture, i.e. a major administrative division just underneath a province, than like a city, and where
  "sufficiently major" is defined according to the population of either the total prefecture or the urban area of the
  city). Note that there are multiple types of counties in England, with overlapping but non-identical names and
  boundaries; there are, in particular, ''ceremonial counties'', ''local government counties'' and ''historic
  counties''; ''ceremonial counties'' have only ceremonial administrative functionality but unlike local government
  counties (a) don't frequently change their boundaries or nature, (b) correspond more closely to historic county
  boundaries and names, and (c) are what Englanders usually identify themselves with, and so they are used as top-level
  divisions rather than local government counties.

There are two main types of categories:
# Categories for known locations, divided into:
## Top-level polity categories (e.g. [[:Category:United States]], [[:Category:Taiwan]], [[:Category:South Ossetia]],
  [[:Category:Bermuda]], [[:Category:Soviet Union]], [[:Category:West Germany]]).
## Subpolity categories ([[:Category:Arizona, USA]], [[:Category:Hunan]], [[:Category:Kagoshima Prefecture]],
  [[:Category:Cluj County, Romania]]). For historical reasons, different formats are used for the subpolities of
  different polities. Increasingly, we are moving towards always including the polity name in the subpolity category,
  but whether the subpolity type is included and where it is included (cf. [[:Category:Cluj County, Romania]] vs.
  [[:Category:County Cork, Ireland]] is still inconsistent and will probably remain that way, based on how the
  subpolity is normally referred to.
## City categories ([[:Category:Tokyo]], [[:Category:New York City]], [[:Category:Jaipur]]). Normally these do not
   include the containing subpolity, but may do so in order to disambiguate.
# Categories for placetypes, divided into:
## "Immediate" political and miscellaneous division categories ([[:Category:States of the United States]],
   [[:Category:Municipalities of Tocantins, Brazil]], [[:Category:Ghost towns in Arizona, USA]]). These are name
   categories, whose purpose is to contain locations of the specified type. "Immediate" here refers to the fact that
   the location in the category name is the immediately-containing polity. Usually these categories use the preposition
   "of", but sometimes "in". (Specifically, "of" typically implies that the placetype in question has an official or
   semi-official status, whereas "in" implies there is no such official status, but common usage may override this.)
   The form of the toponym appearing in these categories is always the same as that of the corresponding toponym
   category except that the word "the" may appear (e.g. [[:Category:States of the United States]]), whereas it doesn't
   appear in the toponym category itself ([[:Category:United States]], no "the").
## "Skip-polity" categories for second-level political and miscellaneous divisions of a country or other top-level
   polity (e.g. [[:Category:Counties of the United States]], [[:Category:Municipalities of Brazil]] and
   [[:Category:Subprefectures of Japan]]). These have several purposes:
   * They group the immediate division categories mentioned previously.
   * They categorize "straggler" topoynms that (often improperly) fail to mention the subpolity they belong to, but
     only the top-level polity.
   * If categories do not exist for the first-level divisions of a country (and sometimes even when they do), they group
     all toponyms of the specified type for the specified country. For example, Lithuania is divided into first-level
	 counties and second-level municipalities, but since we don't currently have categories for Lithuanian counties,
	 all municipalities go under [[:Category:Municipalities of Lithuania]] rather than under a category for a specific
	 county. In addition, even though we do have categories for Japanese prefectures (a first-level division), all
	 subprefectures (a second-level division) go under [[:Category:Subprefectures of Japan]] because there aren't very
	 many of them (see below).
## "Generic placetype" categories, both of the immediate and skip-polity type (immediate
   [[:Category:Cities in California, USA]] and [[:Category:Neighborhoods of the Bronx]]; skip-polity
   [[:Category:Villages in Ivory Coast]], [[:Category:Geographic and cultural areas of England]],
   [[:Category:Rivers in Egypt]] and [[:Category:Places in the Philippines]]). As mentioned above, "generic" placetypes
   occur in every polity (although the set of generic placetypes allowed for cities is a subset of those allowed for
   top-level polities and subpolities). Usually these categories use the preposition "in", but sometimes "of". As above,
   skip-polity categories group immediate categories, and in addition there are various reasons a toponym entry is
   categorized into a skip-polity category. (For example, as a general rule, geographic and cultural areas only
   categorize at the country level, not the subpolity level, both because there often aren't very many in a given
   country and because they often span multiple subpolities.)

The parent categories of a given category depend on its type. Generally, location categories have placetype categories
as their first parent, and vice-versa. Specifically:
# Top-level country categories have as their parent e.g. [[:Category:Countries in Europe]],
  [[:Category:Countries in Central America]] or [[:Category:Countries in Polynesia]], using the most specific
  continental-level region the country is contained in.
# Pseudo-countries are under [[:Category:Country-like entities]] as a neutral designation. There aren't enough of them
  to subcategorize under continent-level regions.
# Former countries are under [[:Category:Former countries and country-like entities]].
# Subpolity categories are usually under a placetype category whose placetype is the canonical (first-listed) divtype of
  the subpolity and whose toponym is the immediately containing polity, but there are exceptions. Specifically,
  sometimes if a polity has multiple types of subpolities, they are combined (e.g. [[:Category:States and territories of
  Australia]], [[:Category:Federal subjects of Russia]]). In addition, sometimes a less specific but more identifiable
  divtype is used instead of the canonical one (e.g. [[:Category:Regions of France]] when the canonical divtype is
  "administrative region"). The same rules and exceptions generally apply when categorizing subpolities themselves; e.g.
  both the Australian state of Queensland and territory of Northern Territory go under
  [[:Category:en:States and territories of Australia]] rather than separately under [[:Category:en:States of Australia]]
  and [[:Category:en:Territories of Australia]]. In addition, sometimes subpolities may "skip a level" if there aren't
  very many. For example, there are only 26 subprefectures of Japan (14 under Hokkaido and 12 more scattered under five
  other prefectures). Rather than have e.g. [[:Category:en:Subprefectures of Kagoshima Prefecture]] containing at most
  two entries and [[:Category:en:Subprefectures of Miyazaki Prefecture]] containing at most one, they are all grouped
  under the so-called "skip-subpolity category" [[:Category:en:Subprefectures of Japan]].
# City categories are always under e.g. [[:Category:Cities in the United States]] (e.g. [[:Category:New York City]] is
  so-placed, even though [[:Category:Cities in New York, USA]] exists). However, they may have a second, more-specific
  parent (e.g. [[:Category:Cities in New York, USA]] in the case of New York City). The city entries themselves will
  go under the more specific parent if it exists.
# Immediate placetype categories for second-level divisions of a country generally have, respectively, a
  "toponym parent" that is the toponym mentioned in the category and a "skip-polity parent" that groups all subpolity
  placetype categories of a specific type and containing polity. For example, [[:Category:Counties of Arizona, USA]] has
  toponym parent [[:Category:en:Arizona, USA]] and skip-polity parent [[:Category:en:Counties of the United States]].
  Sometimes the default skip-polity parent is overridden or disabled entirely. For example, in the US, most states are
  divided into counties but Louisiana is divided into parishes and Alaska into boroughs. It would make no sense to put
  [[:Category:Parishes of Louisiana, USA]] under [[:Category:Parishes of the United States]] (which would only have one
  subcategory), so we include them under [[:Category:Counties of the United States]]. An alternative would be to name
  the skip-polity category to explicitly include parishes and boroughs; this would get awkward here but is done in some
  cases. Similarly, [[:Category:Regional county municipalities of Quebec]] is placed under
  [[:Category:Regional municipalities of Canada]] since that name is used in other provinces. Meanwhile,
  [[:Category:Regional districts of British Columbia]] disables its skip-polity category since no other province or
  territory of Canada has regional districts or comparable subpolities under a different name (an alternative would be
  to place them under [[:Category:Counties of Canada]], since they are sort of comparable to counties).
# Placetype categories for first-level divisions of a country similarly (e.g. [[:Category:States of the United States]])
  have a toponym parent (in this case [[:Category:United States]]), but in place of the skip-polity parent they have two
  other parents: a "bare placetype" parent (in this case [[:Category:States]]) and the "generic" parent
  [[:Category:Political divisions of specific countries]]. (There is also a bare [[:Category:Political divisions]]
  that groups "bare placetype" categories.) Skip-polity placetype categories for second-level divisions of a country
  (e.g. [[:Category:Counties of the United States]]) work the same. Placetype categories for countries work likewise
  except they are missing the generic parent.

===Location group tables===

The bulk of the data in this module (after some helper functions and placetype tables) describes the known locations
and their relationships. The main location table is called `export.locations` and is a list of ''location groups'', each
of which describes a set of related known locations, as described above.

====OUT OF DATE DOCUMENTATION (polity group tables)====

The following tables specify the known polities and their properties, where a polity is either a top-level political
division (e.g. a country) or a subpolity (political division of a top-level polity). Polities are gathered into
''groups'', each of which contains several items (places) that are handled similarly. Each group contains a list of all
the places contained in that group along with their properties, as well as group-specific handlers that specify common
properties of all items in the group. These items are used to construct the category description objects (i.e. the
objects that describe how to format the display of a category page, as documented in
[[Module:category tree/topic cat/data/documentation]]) for the following types of categories:

1. A bare topical category, e.g. [[:Category:en:Netherlands]]. Category description objects for these are created by the
   `bare_label_setter` handler of a given group. (The term "label" is used here because the category system internally
   refers to the category name, without any language prefix, as a "label", and the corresponding per-label category
   description objects are stored in the `labels` table in a `topic cat` submodule, notably
   [[Module:category tree/topic cat/data/Places]].)
2. Normally, several categories of the form [[:Category:fr:Cities in the Netherlands]],
   [[:Category:es:Rivers in New Mexico, USA]], etc., for the place types listed above in `generic_placetypes`.
   There is a top-level handler that will automatically create category description objects for such categories. It can
   be disabled for all place types in `generic_placetypes` that aren't in `generic_placetypes_for_cities` by
   specifying `is_city = true` in the data for a given item. (This is used for city-states such as Monaco and
   Vatican City.) It can also be disabled for all place types in `generic_placetypes` other than "places" by specifying
   `is_former_place = true` in the data for a given item. (The group below for former countries and empires has a
   handler that specifies `is_former_place = true` for all items in the group. The reason for this is that former states
   such as Persia, East Germany, the Soviet Union and the Roman Empire should have their cities, towns, rivers and such
   listed under the current entities occupying the same area.)
3. Optionally, one or more categories of the form [[:Category:de:Provinces of the Netherlands]],
   [[:Category:pt:Counties of Wales]], etc. These are for political divisions, and for historic/popular divisions that
   have no current political significance (e.g. [[:Category:nl:Provinces of Ireland]],
   [[:Category:zh:Regions of the United States]]). These are controlled by the `poldiv` (for political divisions) and
   `miscdiv` (for historic/popular divisions) keys in the data for a given item.

NOTE: Second-level political divisions (e.g. counties of states of the US) could be handled here but normally aren't.
Instead, there are special handlers below for US counties and Brazilian and Philippine municipalities, and
manually-created labels for certain other countries (e.g. Canadian counties). The reason for this is that all political
and historic/popular divisions handled here have a category like [[:Category:en:Political divisions]] as their
primary parent, whereas we often want a different primary parent for second-level political divisions, such as
[[:Category:en:Counties of the United States]] for US counties. FIXME: We should allow the parents to be specified for
political divisions. This will probably necessitate another type of group-specific handler, similar to
`bare_label_setter` (see below).

NOTE: Some of the above categories are added automatically to pages that use the {{tl|place}} template with the appropriate
values. Currently, whether or not such categories are added is controlled by [[Module:place/data]], which is independent
of the data here but in many ways duplicates it. FIXME: The two should be merged.

NOTE: There is also some duplication in [[Module:category tree/topic cat/data/Earth]], particularly for continents and
supranational regions (e.g. "the British Isles"). FIXME: Consolidate the data there into here.

Each group consists of a table with the following keys:

* `data`: This is a table listing the polities in the group. The keys are polities in the form that they appear in a
  category like [[:Category:de:Provinces of the Netherlands]] or [[:Category:fr:Cities in Alabama, USA]] (hence, they
  should include prefixes such as "the" and suffixes such as ", USA"). The value of a key is a property table. Its
  format is described above under "Placename Tables".

* `key_to_placename`: A function to transform a key (as it appears in categories, e.g. "Phuket Province, Thailand" or
  "the Riau Islands, Indonesia") to the placename as it appears in category descriptions and (modulo a preceding "the")
  in holonym and Wiktionary entries (e.g. "Phuket", which appears in category descriptions as "[[Phuket]]", in holonyms
  as "p/Phuket" and as an entry under [[Phuket]], and "the Riau Islands", which appears in category descriptions as
  "the [[Riau Islands]]", in holonyms as "p/Riau Islands" and as an entry under [[Riau Islands]]). Most commonly, this
  uses the `chop` function to chop off some portion of the key. The return value is either a string (the placename) or a
  two-item list consisting of (respectively) the "full" placename and "elliptical" placename. The distinction between
  full and elliptical placenames is only used for certain sorts of polities such as counties in Ireland and Northern
  Ireland, which traditionally have the word "County" before them (e.g. "County Durham") and appear as entries in
  Wiktionary in this form. When there is both a full form and an elliptical form, the full form will be used in the
  category description, while both types of forms will be recognized in holonyms for categorization purposes. If the
  key contains the word "the" at the beginning, it will be passed as such to `key_to_placename`, and the full (or only)
  placename should include "the" in it, as the value is used in category descriptions. If there is an elliptical
  placename, it currently doesn't matter whether it is preceded by "the" as any occurrence will be removed before
  constructing the entry in `cat_data` against which a holonym is compared; but it is probably best not to include it.
  For example, the Indonesian province key "the Special Region of Yogyakarta, Indonesia" returns a full placename of
  "the Special Region of Yogyakarta" and an elliptical placename of "Yogyakarta"; the effect is that categories
  referencing this province will contain the text "the [[Special Region of Yogyakarta]]" while both holonyms
  "p/Special Region of Yogyakarta" and "p/Yogyakarta" will be recognized for categorization purposes.

* `placename_to_key`: This is the opposite of `key_to_placename`, converting placenames to keys (see the description
  above for `key_to_placename` for what the difference is). If a placename comes in both full and elliptical versions
  (e.g. full "County Durham" and elliptical "Durham"), both should be recognized and appropriately converted to the
  corresponding key. It should be noted that `key_to_placename` and `placename_to_key` are non-parallel in their
  handling of keys and placenames beginning with "the". The placenames passed into `placename_to_key` will not include
  "the" in them, and the returned keys should likewise not include "the". Calling code will check for actual keys that
  are either identical to the returned keys or match once "the" is prepended.

* `bare_label_setter`: This function adds an entry in the `labels` table for
  [[Module:category tree/topic cat/data/Places]] for bare topical categories such as [[:Category:en:Netherlands]],
  [[:Category:fr:Alabama, USA]] or [[:Category:ru:Republic of Tatarstan]]. It is passed four arguments (the `labels`
  table, the group and the key and value of the data item). There are preconstructed functions to help here, such as
  simple_polity_bare_label_setter() (for top-level polities) and subpolity_bare_label_setter() (for subpolities of
  top-level polities). This function often makes use of the `parents` and/or `description` keys in the data item's
  value (see above).

* `default_divtype`: The default location type for locations in this group, if not overidden at the location level. See
  `divtype` above under "Placename Tables".

====OUT OF DATE DOCUMENTATION (polity division tables)====

Each of the following tables specifies a group of polities with common properties (e.g. the states of the US). Each
table is associated with a polity "group" (an entry in `export.locations`), which contains handlers specifying how to
process the data tables and also a pointer to the relevant table. The data is used as follows:

1. To generate the text of the bare topical categories directly associated with each polity, such as
   [[:Category:Netherlands]], [[:Category:Alabama, USA]] or [[:Category:Amazonas, Brazil]], and per-language
   variants such as [[:Category:de:Netherlands]], [[:Category:es:Alabama, USA]] or [[:Category:pt:Amazonas, Brazil]].
   These categories (and all placename categories) are found in the ''topic cat subsystem'' of the category system;
   see [[Module:category tree/topic cat/data]] for more information.
2. To generate the text of topical categories for cities/towns/rivers/etc. in a given polity, e.g.
   [[:Category:Cities in Alabama, USA]] for cities in Alabama, and per-language variants such as
   [[:Category:fr:Cities in Alabama, USA]] for French terms for cities in Alabama.
3. To generate the text of topical categories for political divisions of a given polity, e.g.
   [[:Category:Provinces of the Netherlands]], [[:Category:Counties of Alabama]] or
   [[:Category:Municipalities of Amazonas, Brazil]], along with per-language variants such as
   [[:Category:de:Provinces of the Netherlands]], [[:Category:es:Counties of Alabama]] or
   [[:Category:pt:Municipalities of Amazonas, Brazil]].
4. To add pages to all the above types of categories when a call to {{tl|place}} on that page
   references the polity, such as by a template call {{tl|place|en|city|state/Alabama}} (which will
   add the page to [[:Category:en:Cities in Alabama, USA]]).

Uses #1, #2 and #3 are controlled by [[Module:category tree/topic cat/data/Places]].
Use #4 is controlled by [[Module:place/data]].

The keys of each table are the polity names in the form they will appear in a category like
[[:Category:de:Provinces of the Netherlands]] or [[:Category:fr:Cities in Alabama, USA]] (hence, they should include
prefixes such as "the" and suffixes such as ", USA"). Transforming these keys to the form that appears in the bare
topical category (e.g. [[:Category:de:Netherlands]]), in category parents and/or in descriptions can be done using the
`bare_label_setter` key (see `export.locations` below).
	 
The value of an item in each table is itself a table. This table contains properties describing the polity in question.
Note that before being used (e.g. to generate the contents of a category page like [[:Category:en:Cities in Ireland]]
or [[:Category:de:Provinces of the Netherlands]] of to specify how to add the relevant categories to a page with a call
to {{tl|place}}), the table is passed through `set_spec_defaults`. That function augments the property table with 
additional properties that are common to the group or derivable from group-specific properties. The following are the
properties most commonly specified (additional properties are sometimes attached to entries in specific groups):

- `divtype`: String specifying the type of polity or subpolity (e.g. "country", "state", province"). This can also be a
  table of such types; in this case, the first listed type is the canonical type that will be used in descriptions, but
  the polity will be recognized (e.g. in {{tl|place}} arguments) when tagged with any of the specified types. This value
  overrides the group-level `default_divtype` value, and only needs to be specified if it disagrees with that value.

- `poldiv`: List of recognized political divisions; e.g. for the Netherlands, a specification of the form
  'poldiv = {"provinces", "municipalities"}' will allow categories such as [[:Category:de:Provinces of the Netherlands]]
  and [[:Category:pt:Municipalities of the Netherlands]] to be created. These categories have a primary parent
  [[:Category:LANGCODE:Political divisions]] (i.e. this is the parent that appears in the breadcrumbs at the top of the
  category page), and have the containing polity, if any (see `container` below) as an additional parent. Any political
  division that appears here must also be listed in the `political_divisions` list, which tells how to convert the
  pluralized political division into the equivalent linked description. (If not listed, an error occurs.)

- `miscdiv`: List of recognized historical/popular divisions; e.g. for Ireland, a specification of the form
  'miscdiv = {"provinces"}' will allow categories such as [[:Category:pl:Provinces of Ireland]] to be created. These
  categories differ from political division categories in that their primary parent is the country name rather than
  [[:Category:LANGCODE:Political divisions]].

- `is_city`: If 'true', don't recognize or generate categories such as [[:Category:en:Cities in Monaco]] (specifically,
  for place types in `generic_placetypes` but not in `generic_placetypes_for_cities`).

- `is_former_place`: If 'true', don't recognize or generate categories such as
  [[:Category:fr:Rivers in the Soviet Union]] (specifically, for any place type in `generic_placetypes` other than
  "places").
  
- `keydesc`: String directly specifying a description of the polity, for use in generating the contents of category
  pages related to the polity. descriptions.

- `parents`: List of parents of the bare topical category. For example, if 'parents = {"Europe", "Asia"}' is specified
  for "Turkey", bare topical categories such as [[:Category:en:Turkey]] will have parent categories
  [[:Category:en:Europe]] and [[:Category:en:Asia]]. The first listed category is used for the primary parent (i.e. this
  is the parent that appears in the breadcrumbs at the top of the category page). In this case, for example, "Europe"
  (not "Asia") is used as the breadcrumb. This property only needs to be specified for top-level polities (countries and
  such), not for subpolities (states, provinces, etc.), which use the value of `container` (see below) as the
  parent.

- `bare_category_desc`: String specifying the description used in the bare topical category. If not given, a default
  description is constructed by the `bare_label_setter` function.

- `container`: This specifies the larger polity in which the subpolity is contained, and is used to construct the
  primary parent of 'Cities in ...', 'Rivers in ...' and similar categories. For example, the subpolity Guangdong (a
  province of China) will have "China" as the `container`, so that a category of the form
  [[:Category:en:Cities in Guangdong]] will have its primary parent (i.e. the parent that appears in the breadcrumbs at
  the top of the category page) as [[:Category:en:Cities in China]]. If `container` is omitted, as in top-level
  polities, the primary parent will simply be e.g. [[:Category:en:Cities]] (or "Towns", "Rivers", etc. as appropriate).

]==]

-----------------------------------------------------------------------------------
--                              Helper functions                                 --
-----------------------------------------------------------------------------------

--[==[
Throw an error. `fmt` is a format string and the remaining arguments are passed through `mw.dumpObject` and then used to
format the format string as if `fmt:format(...)` were called. In general, callers should use `internal_error` unless the
error was due to bad user input rather than a logic error (which usually isn't the case in deep back-end code like
this).
]==]
function export.process_error(fmt, ...)
	local args = {...}
	for i = 1, select("#", ...) do
		args[i] = dump(args[i])
	end
	return error(string.format(fmt, unpack(args)))
end

--[==[
Throw an internal error (a logic error that should never happen unless there is a bug in the code, as opposed to a user
error triggered by bad input or a system error due to something like running out of memory or hitting a time limit).
`fmt` is a format string and the remaining arguments are passed through `mw.dumpObject` and then used to format the
format string as if `fmt:format(...)` were called.
]==]
function export.internal_error(fmt, ...)
	export.process_error("Internal error: " .. fmt, ...)
end

local internal_error = export.internal_error

-- Return whether `list_or_element` (a list of strings, or a single string) "contains" `item` (a string). If
-- `list_or_element` is a list, this returns true if `item` is in the list; otherwise it returns true if `item`
-- equals `list_or_element`.
local function list_or_element_contains(list_or_element, item)
	if type(list_or_element) == "table" then
		return m_table.contains(list_or_element, item) and true or false
	end
	return list_or_element == item
end

--[==[
Generate the "prefixed" version of a bare key, i.e. prefix it with `the` if correct for this key.
]==]
function export.get_prefixed_key(key, spec)
	if spec.the then
		return "the " .. key
	else
		return key
	end
end

--[==[
Given a location group, key and possible placetypes that the placename must match, check if the key exists in the group
with at least one of the group's key's placetypes matching one of the passed-in placetypes. If so, return two values:
the group key (which potentially could differ from the passed-in key due to aliases) and the corresponding value
structure.
]==]
function export.find_matching_key_in_group(group, placetypes, key)
	-- FIXME: This should handle aliases.
	local spec = group.data[key]
	if not spec then
		return nil
	end
	local divtype = spec.divtype or group.default_divtype
	if type(divtype) == "table" then
		for _, dt in ipairs(divtype) do
			if list_or_element_contains(placetypes, dt) then
				return key, spec
			end
		end
		return nil
	elseif list_or_element_contains(placetypes, divtype) then
		return key, spec
	else
		return nil
	end
end


--[==[
Given a location group, placename and possible placetypes that the placename must match, check if the placename exists
in the group with at least one of the placetypes of the key in the group that corresponds to the placename matching one
of the passed-in placetypes. If so, return two values: the key corrsponding to the passed-in placename and the
corresponding value structure.
]==]
function export.find_matching_placename_in_group(group, placetypes, placename)
	local key
	if group.placename_to_key then
		key = group.placename_to_key(placename)
	else
		key = placename
	end
	return export.find_matching_key_in_group(group, placetypes, key)
end


--[==[
Iterator that returns all locations matching a given description, where the description consists of either a placename
or a key along with a list of posssible placetypes. Usually there will be at most one such location. The iterator
returns three values at each iteration: the location group, canonical key by which the location is known and the spec
object describing the location. The value transformer is run on each spec prior to it being returned.
]==]
function export.iterate_matching_location(data)
	local i = 0
	local n = #export.locations
	return function()
		while true do
			i = i + 1
			if i > n then
				break
			end
			local group = export.locations[i]
			local key, spec
			if data.placename then
				key, spec = export.find_matching_placename_in_group(group, data.placetypes, data.placename)
			else
				if not data.key then
					internal_error("'.placename' or '.key' must be defined: %s", data)
				end
				key, spec = export.find_matching_placename_in_group(group, data.placetypes, data.key)
			end
			if key, spec then
				set_spec_defaults(group, key, spec)
				return group, key, spec
			end
		end
	end
end


--[=[
If the holonym in `data` (in the format as passed to a category handler) refers to a city, find and return the
corresponding city key, spec and group as well as a list of the containing polities. This verifies that there is no
mismatch between the city's containing polities and any of the following holonyms in the {{tl|place}} spec.

Returns four values:
# The ''city key'' (the key in the data in the city group table; usually the same as the holonym placename passed in,
  but may be different due to following an alias, and may in rare cases have `the` prefixed);
# the ''city spec'' (object describing the city, the value corresponding to the city key in the data in the city group
  table; documented in [[Module:place/shared-data]] under `export.cities`);
# the ''city group'' (the table listing a group of cities with shared properties);
# the list of containing polities, ordered from smallest/most immediate to largest/least immediate; each element is
  a table with `name` and `divtype` properties, the latter of which has been filled out using group-level defaults if
  necessary.
]=]
local function iterate_matching_holonym_location(data)
	local holonym_placetype, holonym_placename, holonym_index, place_desc =
		data.holonym_placetype, data.holonym_placename, data.holonym_index, data.place_desc
	-- local equiv_to_city = export.get_equiv_placetype_prop(holonym_placetype, function(equiv_placetype)
	-- 	return equiv_placetype == "city"
	-- end)
	-- if not equiv_to_city then
	-- 	return nil
	-- end
	local matching_location_iterator = export.iterate_matching_location {
		placetypes = holonym_placetype,
		placename = holonym_placename,
	}
	return function()
		while true do
			local group, key, spec = next(matching_location_iterator)
			if not group then
				return nil
			end
			-- For each level of containing polity, check that there are no mismatches (i.e. other polity of the same
			-- sort) mentioned. We allow a mismatch at a given level if there's also a match with the containing polity
			-- at that level. For example, in the case of Kansas City, defined in [[Module:place/shared-data]] as a city
			-- in Missouri, if we define it as {{tl|place|city|s/Missouri,Kansas}}, we ignore the mismatching state of
			-- Kansas because the correct state of Missouri was also mentioned. But imagine we are defining Newark,
			-- Delware as {{tl|place|city|s/Delaware|c/US}} and (as is the case) we have an entry for Newark, New Jersey
			-- in [[Module:place/shared-data]]. Just because the containing polity US matches isn't enough, because
			-- Newark, NJ also has New Jersey as a containing polity and there's a mismatch at that level. If there are
			-- no mismatches at any level we assume we're dealing with the right city.
			local containing_polities = export.get_city_containing_polities(group, spec)
			local containing_polities_mismatch = false
			for _, polity in ipairs(containing_polities) do
				local bare_polity, _ = m_shared.construct_bare_and_linked_version(polity.name)
				local divtype = polity.divtype
				local divtype_equivs = export.get_placetype_equivs(divtype)
				for other_holonym_index, other_holonym in get_holonyms_to_check(place_desc,
					holonym_index and holonym_index + 1 or nil) do
					local this_holonym_matches = export.get_equiv_placetype_prop_from_equivs(divtype_equivs,
						function(placetype)
							return other_holonym.placetype == placetype and other_holonym.cat_placename == bare_polity
						end
					)
					if this_holonym_matches then
						-- match
					else
						local this_holonym_mismatches = export.get_equiv_placetype_prop_from_equivs(
							divtype_equivs, function(placetype)
								return other_holonym.placetype == placetype
							end
						)
						if this_holonym_mismatches then
							containing_polities_mismatch = true
							break
						end
					end
				end
				if containing_polities_mismatch then
					break
				end
			end
			if not containing_polities_mismatch then
				return city_key, city_spec, city_group, containing_polities
			end
		end
	end
end


function export.get_matching_location(data)
	local all_found = {}
	for group, key, spec in export.iterate_matching_location(data) do
		table.insert(all_found, {group, key, spec})
	end
	if not all_found[1] then
		internal_error("Couldn't find matching location for data %s", data)
	elseif all_found[2] then
		internal_error("Found multiple matching locations for data %s: %s", data, all_found)
	else
		return unpack(all_found[1])
	end
end

--[==[
If the holonym in `data` refers to a known location (i.e. polity or political division), find and return the
corresponding key, spec and group. FIXME: This should verify that there is no mismatch between the location's containers
and any of the following holonyms in the {{tl|place}} spec, as find_city_spec() does.

Returns three values:
# The ''location key'' (the key in the data in the location group table; often has the name of the container and
  sometimes the placetype affixed, and may have `the` prefixed);
# the ''location spec'' (object describing the location, the value corresponding to the location key in the data in the
  location group table; documented in [[Module:place/shared-data]] in the intro under `==Location tables==`);
# the ''location group'' (the table listing a group of locations with shared properties).
]==]
function export.find_location_spec(data)
	local holonym_placetype, holonym_placename, place_desc =
		data.holonym_placetype, data.holonym_placename, data.place_desc
	for _, location_group in ipairs(m_shared.locations) do
		-- Find the appropriate key format for the holonym (e.g. "pref/Osaka" -> "Osaka Prefecture").
		local location_key, _ = m_shared.call_place_cat_handler(location_group, holonym_placetype, holonym_placename)
		if location_key then
			local location_value = location_group.data[location_key]
			if location_value then
				-- Use the group's value_transformer to ensure that default values are copied into the location spec
				-- (location value structure).
				location_value = location_group.value_transformer(location_group, location_key, location_value)
				return location_key, location_value, location_group
			end
		end
	end
end


--[==[
>>>>>>> d9656d33 (place-data,place-shared-data: latest work (NOT WORKING OR DONE))
Given a non-multipart key (where a multipart key is something like `"Tucson, Arizona"` or `"Atlanta, Georgia, USA"`),
possibly preceded by `the`, return two values, the ''bare'' and ''linked'' versions of the key. The bare version is
simply the passed-in `key` minus any preceding `the`. The linked version is the key converted into a raw bracketed link
(where any preceding `the` is included but is not part of the link). If `display_form` is given and is different from
the bare key, the resulting link will be a two-part link, linking to the non-`the` part of the key but displaying
`display_form` in place of the link.

For example, the call `construct_bare_and_linked_version("the United States")` will return `"United States"` and
`"the <nowiki>[[United States]]</nowiki>"`.
]==]
function export.construct_linked_key(key, spec, display_form)
	local linked_key = display_form and key ~= display_form and ("[[%s|%s]]"):format(key, display_form) or
		("[[%s]]"):format(key)
	if spec.the then
		linked_key = "the " .. linked_key
	end
	return linked_key
end

local function simple_polity_bare_label_setter(overriding_parents)
	return function(group, key, value)
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		-- wp= defaults to true (Wikipedia article matches bare key = label)
		local wp = value.wp
		if wp == nil then
			wp = true
		end
		-- wpcat= defaults to wp= (if Wikipedia article has its own name, Wikipedia category and Commons category
		-- generally follow)
		local wpcat = value.wpcat
		if wpcat == nil then
			wpcat = wp
		end
		-- commonscat= defaults to wpcat= (if Wikipedia category has its own name, Commons category generally follows)
		local commonscat = value.commonscat
		if commonscat == nil then
			commonscat = wpcat
		end
		local parents = overriding_parents
		if not parents then
			parents = {}
			local value_parents = value.parents
			if not value_parents then
				internal_error("Key %s must have `parents` set", key)
			end
			if type(value_parents) ~= "table" then
				value_parents = {value_parents}
			end
			for _, parent in ipairs(value_parents) do
				if type(parent) ~= "table" then
					parent = {name = parent}
				end
				if parent.bare then
					table.insert(parents, parent.name)
				else
					table.insert(parents, "countries in " .. parent.name)
				end
			end
			table.insert(parents, "countries")
		end
		return {
			type = "topic",
			description = value.bare_category_desc or "{{{langname}}} terms related to the people, culture, or " ..
				"territory of " .. (value.keydesc or linked_key) .. ".",
			parents = parents,
			wp = wp,
			wpcat = wpcat,
			commonscat = commonscat,
		}
	end
end

-- Construct the description of a subpolity key, for use in the description of a category.
local function fallback_keydesc(group, key, spec)
	local divtype = spec.divtype or default_divtype
	divtype = type(divtype) == "table" and divtype[1] or divtype
	-- FIXME: This is a huge hack. To fix this properly, we need to separate out the non-category placetype data from
	-- `cat_data` in [[Module:place/data]] and move it here, because we don't have access to the data in
	-- [[Module:place/data]], and that data indicates the correct article for placetypes like "union territory".
	if divtype == "union territory" then
		divtype = "a " .. divtype
	else
		divtype = require(en_utilities_module).add_indefinite_article(divtype)
	end

	-- Fetch the full and elliptical_placenames. If they are the same, just link to the placename directly. Otherwise,
	-- check if the full placename exists (minus any preceding "the"); if so link to it. Otherwise, if the elliptical
	-- placename exists, link to it but display it as the full placename. Finally, if neither full placename nor
	-- elliptical placename exists, fall back to linking to the full placename. That way, we prefer full placenames to
	-- elliptical placenames if both or neither exist as Wiktionary entries, but if only one exists, we link to that one
	-- rather than have a red link.
	local full_placename, elliptical_placename = export.call_key_to_placename(group, key)
	local bare_full_placename, linked_full_placename = export.construct_bare_and_linked_version(full_placename)
	local linked_placename
	if elliptical_placename ~= full_placename then
		local full_placename_title = mw.title.new(bare_full_placename)
		if full_placename_title and full_placename_title.exists then
			linked_placename = linked_full_placename
		else
			local bare_elliptical_placename, linked_elliptical_placename =
				export.construct_bare_and_linked_version(elliptical_placename, bare_full_placename)
			local elliptical_placename_title = mw.title.new(bare_elliptical_placename)
			if elliptical_placename_title and elliptical_placename_title.exists then
				linked_placename = linked_elliptical_placename
			end
		end
	end
	linked_placename = linked_placename or linked_full_placename
	local bare_container, linked_container = export.construct_bare_and_linked_version(container)
	return linked_placename .. ", " .. divtype .. " of " .. linked_container
end

--[==[
Call the polity group's `key_to_placename` function if it exists (see the description of the `key_to_placename`
function in the long comment just below the heading `"Polities"`). If there is no such function (i.e. for this group,
keys and placenames are the same), the key is returned unchanged as both the full and elliptical placename. Otherwise
two values are returned, the full and elliptical placenames (e.g. full `"County Durham"` vs. elliptical `"Durham"`).
]==]
function export.call_key_to_placename(group, key)
	if group.key_to_placename then
		local full_placename, elliptical_placename = group.key_to_placename(key)
		if type(full_placename) ~= "string" then
			internal_error("Key %s returned a non-string full placename: %s", key, full_placename)
		end
		if type(elliptical_placename) ~= "string" then
			internal_error("Key %s returned a non-string elliptical placename: %s", key, elliptical_placename)
		end
		return full_placename, elliptical_placename
	end
	return key, key
end

local function subpolity_bare_label_setter(container)
	return function(group, key, value, m_data)
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		local bare_container, linked_container = export.construct_bare_and_linked_version(container)
		local div_parent_type = value.div_parent_type or group.default_div_parent_type
		if not div_parent_type then
			local divtype = value.divtype or group.default_divtype
			divtype = type(divtype) == "table" and divtype[1] or divtype
			if not divtype then
				internal_error("Ended up with nil divtype for key=%s, value=%s", key, value)
			end
			div_parent_type = m_data.pluralize_placetype(divtype)
		end
        return {
            type = "topic",
            description = function()
				if value.bare_category_desc then
					return value.bare_category_desc
				else
					local keydesc = subpolity_keydesc(group, key, value, container, group.default_divtype)
					return "{{{langname}}} terms related to the people, culture, or territory of " .. keydesc .. "."
				end
			end,
            parents = {div_parent_type .. " of " .. container},
        }
	end
end

local function set_spec_defaults(group, key, spec)
	if type(spec.container) == "string" and group.canonicalize_key_container then
		spec.container = group.canonicalize_key_container(spec.container)
	end
	if not spec.container then
		spec.container = group.default_container
	end
	if type(spec.container) == "string" then
		spec.container = {name = spec.container, divtype = "country"}
	end
	spec.containers = spec.container
	spec.container = nil
	if spec.containers and not spec.containers[1] then
		spec.containers = {spec.containers}
	end
	spec.keydesc = spec.keydesc or group.default_keydesc or fallback_keydesc
	spec.poldiv = spec.poldiv or group.default_poldiv
	spec.miscdiv = spec.miscdiv or group.default_miscdiv
	local function boolean_with_default(val, default_val)
		if val == nil then
			return default_val
		else
			return val
		end
	end
	spec.british_spelling = boolean_with_default(spec.british_spelling, group.default_british_spelling)
	spec.no_container_cat = boolean_with_default(spec.no_container_cat, group.default_no_container_cat)
	spec.no_auto_augment_container = boolean_with_default(spec.no_auto_augment_container,
		group.default_no_auto_augment_container)
	spec.is_city = boolean_with_default(spec.is_city, group.default_is_city)
	spec.is_city = boolean_with_default(spec.is_city, group.default_divtype == "city")
	spec.is_former_place = boolean_with_default(spec.is_former_place, group.default_is_former_place)
end

--[=[
This is typically used to define `key_to_placename`. It generates a function that chops off parts of a string,
typically at the end, in order to get the full and elliptical versions of a placename. (See the documentation above
for `key_to_placename` under "Polity group tables" for the difference between full and elliptical placenames.)
`polity_patterns` is Lua pattern or a list of possible patterns matching the polity at the end of the key, which
will be used to remove the polity. If multiple patterns are specified, each one is tried until one matches. If
`polity_patterns` is omitted, this part of the process is skipped. The reulting string becomes the full placename.
If `poldiv_patterns` is specified, it is likewise either a Lua pattern or list of possible patterns to match and
remove the political division affixed onto the end (or possibly the beginning) of the key in the keys of certain
countries (such as South Korean and North Korean counties, which include the word "County" in the key). The resulting
chopped string becomes the elliptical placename. If `poldiv_patterns` is omitted, this part of the process is skipped
and the full adn elliptical placenames are the same.

Typical usage is as follows:

```
key_to_placename = make_key_to_placename(", England$"),
```

or (when the poldiv is part of the key)

```
key_to_placename = make_key_to_placename(", South Korea$", " County$")
```
]=]
local function make_key_to_placename(polity_patterns, poldiv_patterns)
	if type(polity_patterns) == "string" then
		polity_patterns = {polity_patterns}
	end
	if type(poldiv_patterns) == "string" then
		poldiv_patterns = {poldiv_patterns}
	end
	return function(key)
		local full_placename = key
		if polity_patterns then
			for _, polity_pattern in ipairs(polity_patterns) do
				local nsubs
				full_placename, nsubs = full_placename:gsub(polity_pattern, "")
				if nsubs > 0 then
					break
				end
			end
		end
		local elliptical_placename = full_placename
		if poldiv_patterns then
			for _, poldiv_pattern in ipairs(poldiv_patterns) do
				local nsubs
				elliptical_placename, nsubs = elliptical_placename:gsub(poldiv_pattern, "")
				if nsubs > 0 then
					break
				end
			end
		end
		return full_placename, elliptical_placename
	end
end


--[=[
This is typically used to define `placename_to_key`. It generates a function that appends a string to the end of a given
placename to get the key (see the definition of `placename_to_key` above in the documentation under "Polity group
tables"). Optional `poldiv_suffix` is a raw string (which should not contain hyphens or other characters that have
special meaning in Lua patterns) to be appended first to the placename; if already present at the end, it is not
appended. `polity_suffix` is then added in the same fashion if given. Typical usage is like this:

```
placename_to_key = make_placename_to_key(", England")
```

(which will convert e.g. `"Hampshire"` into `"Hampshire, England"`)

or

```
placename_to_key = make_placename_to_key(", South Korea", " County")
```

(which will convert e.g. `"Gangwon"` or `"Gangwon County"` into `"Gangwon County, South Korea"`).
]=]
local function make_placename_to_key(polity_suffix, poldiv_suffix)
	return function(placename)
		local key = placename
		if poldiv_suffix then
			if not key:find(poldiv_suffix .. "$") then
				key = key .. poldiv_suffix
			end
		end
		if polity_suffix then
			key = key .. polity_suffix
		end
		return key
	end
end


local function make_canonicalize_key_container(suffix, divtype)
	return function(container)
		if type(container) == "string" then
			return {name = container .. suffix, divtype = divtype}
		else
			return container
		end
	end
end


--[=[
Normalize the list of city "parents" (containing polities) to standard/full form, which is a list of objects, each with
`name` and `divtype` fields. `default_divtype` supplies the default if the divtype of a given containing polity is
unspecified (i.e. it's a string or an object with a `name` but no `divtype` field). An error is thrown if a containing
polity is missing its divtype and `default_divtype` is omitted. Returns two values, the normalized parents list and a
boolean which is true if the returned list (but not necessarily the tables inside) were generated afresh, meaning you
can safely append more items to the end without needing to copy the list.
]=]
local function normalize_city_parents(parents, default_divtype)
	if not parents then
		return nil
	end
	local outer_copied = false
	if type(parents) == "string" or parents.name then
		parents = {parents}
		outer_copied = true
	end
	local need_normalization = false
	for _, parent in ipairs(parents) do
		if type(parent) == "string" or not parent.divtype then
			if not default_divtype then
				internal_error("Encountered parent %s without divtype, and `default_divtype` is passed in as nil",
					parent)
			end
			need_normalization = true
			break
		end
	end
	if need_normalization then
		if not outer_copied then
			parents = m_table.shallowCopy(parents)
			outer_copied = true
		end
		for i, parent in ipairs(parents) do
			if type(parent) == "string" then
				parents[i] = {name = parent, divtype = default_divtype}
			elseif not parent.divtype then
				parent = m_table.shallowCopy(parent)
				parent.divtype = default_divtype
				parents[i] = parent
			end
		end
	end
	return parents, outer_copied
end

--[==[
Successively iterate over a location's containers, and then the containers of those containers, etc. Keep in mind that
locations may have multiple containers (e.g. Russia has both Europe and Asia as containers, and both Europe and Asia
have Eurasia as their container). A given container will never be returned twice (e.g. in the case where a specific
location A has locations B and C as containers, and B has C as its container, C will not be returned twice). An
internal error happens if a container loop is detected. The return value is a list of location objects, each of which
contains `group`, `key` and `spec` fields.
]==]
function export.iterate_containers(group, key, spec)
	local keys_seen = {}
	keys_seen[key] = true
	local iterations = 0
	local last_iteration_containers = {{group = group, key = key, spec = spec}}
	return function()
		iterations = iterations + 1
		if iterations > 10 then
			internal_error("Probable loop in containers when processing key %s", key)
		end
		local next_iteration_containers = {}
		for _, location in ipairs(last_iteration_containers) do
			local containers = location.spec.containers
			if containers then
				for _, container in ipairs(containers) do
					local container_group, container_key, container_spec = get_matching_location {
						placetypes = container.divtype,
						placename = container.name,
					}
					if not keys_seen[container_key] then
						table.insert(next_iteration_containers, {
							group = container_group, key = container_key, spec = container_spec
						})
						keys_seen[container_key] = true
					end
				end
			end
		end
		if not next_iteration_containers[1] then
			return nil
		end
		last_iteration_containers = next_iteration_containers
		return next_iteration_containers
	end
end


-----------------------------------------------------------------------------------
--                               Top-level tables                                --
-----------------------------------------------------------------------------------

export.continents = {
	["Earth"] = {the = true, divtype = "planet"},
		["Africa"] = {divtype = "continent", container = {name = "Earth", divtype = "planet"}},
		["America"] = {divtype = "supercontinent", container = {name = "Earth", divtype = "planet"}},
			["North America"] = {divtype = "continent", container = {name = "America", divtype = "supercontinent"}},
				["Caribbean"] = {the = true, divtype = "continental region", container = {name = "North America", divtype = "continent"}},
				["Central America"] = {divtype = "continental region", container = {name = "North America", divtype = "continent"}},
			["South America"] = {divtype = "continent", container = {name = "America", divtype = "supercontinent"}},
		["Antartica"] = {divtype = "continent", container = {name = "Earth", divtype = "planet"}},
		["Eurasia"] = {divtype = "supercontinent", container = {name = "Earth", divtype = "planet"}},
			["Asia"] = {divtype = "continent", container = {name = "Eurasia", divtype = "supercontinent"}},
			["Europe"] = {divtype = "continent", container = {name = "Eurasia", divtype = "supercontinent"}},
		["Oceania"] = {divtype = "continent", container = {name = "Earth", divtype = "planet"}},
			["Melanesia"] = {divtype = "continental region", container = {name = "Oceania", divtype = "continent"}},
			["Micronesia"] = {divtype = "continental region", container = {name = "Oceania", divtype = "continent"}},
			["Polynesia"] = {divtype = "continental region", container = {name = "Oceania", divtype = "continent"}},
}

export.continents_group = {
	bare_label_setter = simple_polity_bare_label_setter(),
	data = export.continents,
}


-- Countries: including those with partial recognition that are normally considered countries (e.g. Kosovo, Taiwan).
export.countries = {
	["Afghanistan"] = {container = "Asia", poldiv = {"provinces", "districts"}},
	["Albania"] = {container = "Europe", poldiv = {"regions", "counties", "municipalities"}, british_spelling = true},
	["Algeria"] = {container = "Africa", poldiv = {"provinces", "communes", "districts", "municipalities"}},
	["Andorra"] = {container = "Europe", poldiv = {"parishes"}, british_spelling = true},
	["Angola"] = {container = "Africa", poldiv = {"provinces", "municipalities"}},
	["Antigua and Barbuda"] = {container = "North America", poldiv = {"provinces"}, british_spelling = true},
	["Argentina"] = {container = "South America", poldiv = {"provinces", "departments", "municipalities"}},
	["Armenia"] = {container = {"Europe", "Asia"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	-- Both a country and continent
	["Australia"] = {container = "Oceania", poldiv = {"states", "territories", "local government areas"},
		addl_poldiv_for_categorization = {"states and territories"}, british_spelling = true},
	["Austria"] = {container = "Europe", poldiv = {"states", "districts", "municipalities"}, british_spelling = true},
	["Azerbaijan"] = {container = {"Europe", "Asia"}, poldiv = {"districts", "municipalities"}, british_spelling = true},
	["Bahamas"] = {the = true, container = "North America", poldiv = {"districts"}, british_spelling = true, wp = "The Bahamas"},
	["Bahrain"] = {container = "Asia", poldiv = {"governorates"}},
	["Bangladesh"] = {container = "Asia", poldiv = {"divisions", "districts", "municipalities"}, british_spelling = true},
	["Barbados"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Belarus"] = {container = "Europe", poldiv = {"regions", "districts"}, british_spelling = true},
	["Belgium"] = {container = "Europe", poldiv = {"regions", "provinces", "municipalities"}, british_spelling = true},
	["Belize"] = {container = "Central America", poldiv = {"districts"}, british_spelling = true},
	["Benin"] = {container = "Africa", poldiv = {"departments", "communes"}},
	["Bhutan"] = {container = "Asia", poldiv = {"districts", "gewogs"}},
	["Bolivia"] = {container = "South America", poldiv = {"provinces", "departments", "municipalities"}},
	["Bosnia and Herzegovina"] = {container = "Europe", poldiv = {"entities", "cantons", "municipalities"}, british_spelling = true},
	["Botswana"] = {container = "Africa", poldiv = {"districts", "subdistricts"}, british_spelling = true},
	["Brazil"] = {container = "South America", poldiv = {"states", "municipalities"}, miscdiv = {"macroregions"}},
	["Brunei"] = {container = "Asia", poldiv = {"districts", "mukims"}, british_spelling = true},
	["Bulgaria"] = {container = "Europe", poldiv = {"provinces", "municipalities"}, british_spelling = true},
	["Burkina Faso"] = {container = "Africa", poldiv = {"regions", "departments", "provinces"}},
	["Burundi"] = {container = "Africa", poldiv = {"provinces", "communes"}},
	["Cambodia"] = {container = "Asia", poldiv = {"provinces", "districts"}},
	["Cameroon"] = {container = "Africa", poldiv = {"regions", "departments"}},
	["Canada"] = {container = "North America", poldiv = {
		"provinces", "territories", "counties", "districts", "municipalities", "regional municipalities", "rural municipalities",
		"Indian reserves", "parishes"},
		miscdiv = {"census divisions", {type = "townships", prep = "in"}},
		addl_poldiv_for_categorization = {"provinces and territories"},
		british_spelling = true},
	["Cape Verde"] = {container = "Africa", poldiv = {"municipalities", "parishes"}},
	["Central African Republic"] = {the = true, container = "Africa", poldiv = {"prefectures", "subprefectures"}},
	["Chad"] = {container = "Africa", poldiv = {"regions", "departments"}},
	["Chile"] = {container = "South America", poldiv = {"regions", "provinces", "communes"}},
	["China"] = {container = "Asia", poldiv = {"provinces", "autonomous regions",
		"special administrative regions", "prefectures", "prefecture-level cities", "counties", "county-level cities",
		"districts", "municipalities"},
		addl_poldiv_for_categorization = {"provinces and autonomous regions"}},
	["Colombia"] = {container = "South America", poldiv = {"departments", "municipalities"}},
	["Comoros"] = {the = true, container = "Africa", poldiv = {"autonomous islands"}},
	["Costa Rica"] = {container = "Central America", poldiv = {"provinces", "cantons"}},
	["Croatia"] = {container = "Europe", poldiv = {"counties", "municipalities"}, british_spelling = true},
	["Cuba"] = {container = "North America", poldiv = {"provinces", "municipalities"}},
	["Cyprus"] = {container = {"Europe", "Asia"}, poldiv = {"districts"}, british_spelling = true},
	["Czech Republic"] = {the = true, container = "Europe", poldiv = {"regions", "districts", "municipalities"}, british_spelling = true},
	["Democratic Republic of the Congo"] = {the = true, container = "Africa", poldiv = {"provinces", "territories"}},
	["Denmark"] = {container = "Europe", poldiv = {"regions", "municipalities", "dependent territories"}, british_spelling = true},
	["Djibouti"] = {container = "Africa", poldiv = {"regions", "districts"}},
	["Dominica"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Dominican Republic"] = {the = true, container = "North America", poldiv = {"provinces", "municipalities"},
		keydesc = "the [[Dominican Republic]], the country that shares the [[Caribbean]] island of [[Hispaniola]] with [[Haiti]]"},
	["East Timor"] = {container = "Asia", poldiv = {"municipalities"}},
	["Ecuador"] = {container = "South America", poldiv = {"provinces", "cantons"}},
	["Egypt"] = {container = "Africa", poldiv = {"governorates", "regions"}},
	["El Salvador"] = {container = "Central America", poldiv = {"departments", "municipalities"}},
	["Equatorial Guinea"] = {container = "Africa", poldiv = {"provinces"}},
	["Eritrea"] = {container = "Africa", poldiv = {"regions", "subregions"}},
	["Estonia"] = {container = "Europe", poldiv = {"counties", "municipalities"}, british_spelling = true},
	["Eswatini"] = {container = "Africa", british_spelling = true},
	["Ethiopia"] = {container = "Africa", poldiv = {"regions", "zones"}},
	["Federated States of Micronesia"] = {the = true, container = "Micronesia", poldiv = {"states"}},
	["Fiji"] = {container = "Melanesia", poldiv = {"divisions", "provinces"}, british_spelling = true},
	["Finland"] = {container = "Europe", poldiv = {"regions", "municipalities"}, british_spelling = true},
	["France"] = {container = "Europe", poldiv = {"regions", "cantons", "collectivities", "communes", "departments",
		"municipalities", "dependent territories", "territories",
		{type = "prefectures", cat_as = {"prefectures", "departmental capitals"}},
		{type = "French prefectures", cat_as = {"prefectures", "departmental capitals"}},
	}, miscdiv = {"provinces"}, british_spelling = true},
	["Gabon"] = {container = "Africa", poldiv = {"provinces", "departments"}},
	["Gambia"] = {the = true, container = "Africa", poldiv = {"divisions", "districts"}, british_spelling = true, wp = "The Gambia"},
	["Georgia"] = {container = {"Europe", "Asia"}, poldiv = {"regions", "districts"},
		keydesc = "the country of [[Georgia]], in [[Eurasia]]", british_spelling = true},
	["Germany"] = {container = "Europe", poldiv = {"states", "municipalities", "districts"}, british_spelling = true},
	["Ghana"] = {container = "Africa", poldiv = {"regions", "districts"}, british_spelling = true},
	["Greece"] = {container = "Europe", poldiv = {"regions", "regional units", "municipalities",
		{type = "peripheries", cat_as = {"regions"}},
	}, british_spelling = true},
	["Grenada"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Guatemala"] = {container = "Central America", poldiv = {"departments", "municipalities"}},
	["Guinea"] = {container = "Africa", poldiv = {"regions", "prefectures"}},
	["Guinea-Bissau"] = {container = "Africa", poldiv = {"regions"}},
	["Guyana"] = {container = "South America", poldiv = {"regions"}, british_spelling = true},
	["Haiti"] = {container = "North America", poldiv = {"departments", "arrondissements"}},
	["Honduras"] = {container = "Central America", poldiv = {"departments", "municipalities"}},
	["Hungary"] = {container = "Europe", poldiv = {"counties", "districts"}, british_spelling = true},
	["Iceland"] = {container = "Europe", poldiv = {"regions", "municipalities", "counties"}, british_spelling = true},
	["India"] = {container = "Asia", poldiv = {"states", "union territories", "divisions", "districts", "municipalities"},
		 addl_poldiv_for_categorization = {"states and union territories"}, british_spelling = true},
	["Indonesia"] = {container = "Asia", poldiv = {"regencies", "provinces"}},
	["Iran"] = {container = "Asia", poldiv = {"provinces", "counties"}},
	["Iraq"] = {container = "Asia", poldiv = {"governorates", "districts"}},
	["Ireland"] = {container = "Europe", addl_parents = {"British Isles"}, poldiv = {"counties", "districts"}, miscdiv = {"provinces"}, british_spelling = true},
	["Israel"] = {container = "Asia", poldiv = {"districts"}},
	["Italy"] = {container = "Europe", poldiv = {"regions", "provinces", "metropolitan cities", "municipalities"},
		british_spelling = true},
	["Ivory Coast"] = {container = "Africa", poldiv = {"districts", "regions"}},
	["Jamaica"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Japan"] = {container = "Asia", poldiv = {"prefectures", "subprefectures", "municipalities"}},
	["Jordan"] = {container = "Asia", poldiv = {"governorates"}},
	["Kazakhstan"] = {container = {"Asia", "Europe"}, poldiv = {"regions", "districts"}},
	["Kenya"] = {container = "Africa", poldiv = {"counties"}, british_spelling = true},
	["Kiribati"] = {container = "Micronesia", british_spelling = true},
	["Kosovo"] = {container = "Europe", british_spelling = true},
	["Kuwait"] = {container = "Asia", poldiv = {"governorates", "areas"}},
	["Kyrgyzstan"] = {container = "Asia", poldiv = {"regions", "districts"}},
	["Laos"] = {container = "Asia", poldiv = {"provinces", "districts"}},
	["Latvia"] = {container = "Europe", poldiv = {"municipalities"}, british_spelling = true},
	["Lebanon"] = {container = "Asia", poldiv = {"governorates", "districts"}},
	["Lesotho"] = {container = "Africa", poldiv = {"districts"}, british_spelling = true},
	["Liberia"] = {container = "Africa", poldiv = {"counties", "districts"}},
	["Libya"] = {container = "Africa", poldiv = {"districts", "municipalities"}},
	["Liechtenstein"] = {container = "Europe", poldiv = {"municipalities"}, british_spelling = true},
	["Lithuania"] = {container = "Europe", poldiv = {"counties", "municipalities"}, british_spelling = true},
	["Luxembourg"] = {container = "Europe", poldiv = {"cantons"}, miscdiv = {"districts"}, british_spelling = true},
	["Madagascar"] = {container = "Africa", poldiv = {"regions", "districts"}},
	["Malawi"] = {container = "Africa", poldiv = {"regions", "districts"}, british_spelling = true},
	["Malaysia"] = {container = "Asia", poldiv = {"states", "federal territories", "districts"}, british_spelling = true},
	["Maldives"] = {the = true, container = "Asia", poldiv = {"provinces", "administrative atolls"}, british_spelling = true},
	["Mali"] = {container = "Africa", poldiv = {"regions", "cercles"}},
	["Malta"] = {container = "Europe", poldiv = {"regions", "local councils"}, british_spelling = true},
	["Marshall Islands"] = {the = true, container = "Micronesia", poldiv = {"municipalities"}},
	["Mauritania"] = {container = "Africa", poldiv = {"regions", "departments"}},
	["Mauritius"] = {container = "Africa", poldiv = {"districts"}, british_spelling = true},
	["Mexico"] = {container = "North America", addl_parents = {"Central America"}, poldiv = {"states", "municipalities"}},
	["Moldova"] = {container = "Europe", poldiv = {"districts", "municipalities", "autonomous territorial units"},
		british_spelling = true},
	["Monaco"] = {divtype = {"city-state", "country"}, container = "Europe", is_city = true, british_spelling = true},
	["Mongolia"] = {container = "Asia", poldiv = {"provinces", "districts"}},
	["Montenegro"] = {container = "Europe", poldiv = {"municipalities"}},
	["Morocco"] = {container = "Africa", poldiv = {"regions", "prefectures", "provinces"}},
	["Mozambique"] = {container = "Africa", poldiv = {"provinces", "districts"}},
	["Myanmar"] = {container = "Asia",
		poldiv = {"regions", "states", "union territories",
		{type = "self-administered zones", cat_as = "self-administered areas"},
		{type = "self-administered divisions", cat_as = "self-administered areas"},
		"districts"}},
	["Namibia"] = {container = "Africa", poldiv = {"regions", "constituencies"}, british_spelling = true},
	["Nauru"] = {container = "Micronesia", poldiv = {"districts"}, british_spelling = true},
	["Nepal"] = {container = "Asia", poldiv = {"provinces", "districts"}},
	["Netherlands"] = {the = true, divtype = {"constituent country", "country"}, container = "Europe",
		poldiv = {"provinces", "municipalities",
			{type = "FORMER municipalities", cat_as = "former municipalities"},
			"dependent territories", "constituent countries"}, british_spelling = true},
	["New Zealand"] = {container = "Polynesia", poldiv = {"regions", "dependent territories", "territorial authorities"},
		british_spelling = true},
	["Nicaragua"] = {container = "Central America", poldiv = {"departments", "municipalities"}},
	["Niger"] = {container = "Africa", poldiv = {"regions", "departments"}},
	["Nigeria"] = {container = "Africa", poldiv = {"states", "local government areas"}, british_spelling = true},
	["North Korea"] = {container = "Asia", addl_parents = {"Korea"}, poldiv = {"provinces", "counties"}},
	["North Macedonia"] = {container = "Europe", poldiv = {"regions", "municipalities"}, british_spelling = true},
	["Norway"] = {container = "Europe", poldiv = {"counties", "municipalities", "dependent territories"},
		miscdiv = {"districts"}, british_spelling = true},
	["Oman"] = {container = "Asia", poldiv = {"governorates", "provinces"}},
	["Pakistan"] = {container = "Asia", poldiv = {"provinces", "divisions", "districts",
		{type = "administrative territories", cat_as = "territories"},
		{type = "federal territories", cat_as = "territories"}},
		addl_poldiv_for_categorization = {"provinces and territories"}, british_spelling = true},
	["Palestine"] = {container = "Asia", poldiv = {"governorates"}},
	["Palau"] = {container = "Micronesia", poldiv = {"states"}},
	["Panama"] = {container = "Central America", poldiv = {"provinces", "districts"}},
	["Papua New Guinea"] = {container = "Melanesia", poldiv = {"provinces", "districts"}, british_spelling = true},
	["Paraguay"] = {container = "South America", poldiv = {"departments", "districts"}},
	["Peru"] = {container = "South America", poldiv = {"regions", "provinces", "districts"}},
	["Philippines"] = {the = true, container = "Asia", poldiv = {"regions", "provinces", "districts", "municipalities", "barangays"}},
	["Poland"] = {poldiv = {"voivodeships", "counties",
		{type = "Polish colonies", cat_as = {{type = "villages", prep = "in"}}},
	}, container = "Europe", british_spelling = true},
	["Portugal"] = {container = "Europe", poldiv = {
		{type = "autonomous regions", cat_as = "districts and autonomous regions"},
		{type = "districts", cat_as = "districts and autonomous regions"},
		"provinces", "municipalities"}, british_spelling = true},
	["Qatar"] = {container = "Asia", poldiv = {"municipalities", "zones"}},
	["Republic of the Congo"] = {the = true, container = "Africa", poldiv = {"departments", "districts"}},
	["Romania"] = {container = "Europe", poldiv = {"regions", "counties", "communes"}, british_spelling = true},
	["Russia"] = {container = {"Europe", "Asia"}, poldiv = {
		"federal subjects", "republics", "autonomous oblasts", "autonomous okrugs", "oblasts", "krais", "federal cities",
		"districts", "federal districts"},
		british_spelling = true},
	["Rwanda"] = {container = "Africa", poldiv = {"provinces", "districts"}},
	["Saint Kitts and Nevis"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Saint Lucia"] = {container = "North America", poldiv = {"districts"}, british_spelling = true},
	["Saint Vincent and the Grenadines"] = {container = "North America", poldiv = {"parishes"}, british_spelling = true},
	["Samoa"] = {container = "Polynesia", poldiv = {"districts"}, british_spelling = true},
	["San Marino"] = {container = "Europe", poldiv = {"municipalities"}, british_spelling = true},
	["São Tomé and Príncipe"] = {container = "Africa", poldiv = {"districts"}},
	["Saudi Arabia"] = {container = "Asia", poldiv = {"provinces", "governorates"}},
	["Senegal"] = {container = "Africa", poldiv = {"regions", "departments"}},
	["Serbia"] = {container = "Europe", poldiv = {"districts", "municipalities"}}, 
	["Seychelles"] = {container = "Africa", poldiv = {"districts"}, british_spelling = true},
	["Sierra Leone"] = {container = "Africa", poldiv = {"provinces", "districts"}, british_spelling = true},
	["Singapore"] = {container = "Asia", poldiv = {"districts"}, british_spelling = true},
	["Slovakia"] = {container = "Europe", poldiv = {"regions", "districts"}, british_spelling = true},
	["Slovenia"] = {container = "Europe", poldiv = {"municipalities"}, british_spelling = true},
	-- Note: the official name does not include "the" at the beginning, but it sounds strange in
	-- English to leave it out and it's commonly included, so we include it.
	["Solomon Islands"] = {the = true, container = "Melanesia", poldiv = {"provinces"}, british_spelling = true},
	["Somalia"] = {container = "Africa", poldiv = {"regions", "districts"}},
	["South Africa"] = {container = "Africa", poldiv = {"provinces", "districts"}, british_spelling = true},
	["South Korea"] = {container = "Asia", addl_parents = {"Korea"}, poldiv = {"provinces", "counties", "districts"}},
	["South Sudan"] = {container = "Africa", poldiv = {"regions", "states", "counties"}, british_spelling = true},
	["Spain"] = {container = "Europe", poldiv = {"autonomous communities", "provinces", "municipalities", "autonomous cities"},
		british_spelling = true},
	["Sri Lanka"] = {container = "Asia", poldiv = {"provinces", "districts"}, british_spelling = true},
	["Sudan"] = {container = "Africa", poldiv = {"states", "districts"}, british_spelling = true},
	["Suriname"] = {container = "South America", poldiv = {"districts"}},
	["Sweden"] = {container = "Europe", poldiv = {"provinces", "counties", "municipalities"}, british_spelling = true},
	["Switzerland"] = {container = "Europe", poldiv = {"cantons", "municipalities", "districts"}, british_spelling = true},
	["Syria"] = {container = "Asia", poldiv = {"governorates", "districts"}},
	["Taiwan"] = {container = "Asia", poldiv = {"counties", "districts"}},
	["Tajikistan"] = {container = "Asia", poldiv = {"regions", "districts"}},
	["Tanzania"] = {container = "Africa", poldiv = {"provinces", "districts"}, british_spelling = true},
	["Thailand"] = {container = "Asia", poldiv = {"provinces", "districts", "subdistricts"}},
	["Togo"] = {container = "Africa", poldiv = {"provinces", "prefectures"}},
	["Tonga"] = {container = "Polynesia", poldiv = {"divisions"}, british_spelling = true},
	["Trinidad and Tobago"] = {container = "North America", poldiv = {"regions", "municipalities"}, british_spelling = true},
	["Tunisia"] = {container = "Africa", poldiv = {"governorates", "delegations"}},
	["Turkey"] = {container = {"Europe", "Asia"}, poldiv = {"provinces", "districts"}},
	["Turkmenistan"] = {container = "Asia", poldiv = {"regions", "districts"}},
	["Tuvalu"] = {container = "Polynesia", poldiv = {"atolls"}, british_spelling = true},
	["Uganda"] = {container = "Africa", poldiv = {"districts", "counties"}, british_spelling = true},
	["Ukraine"] = {container = "Europe", poldiv = {"oblasts", "municipalities", "raions"}, british_spelling = true},
	["United Arab Emirates"] = {the = true, container = "Asia", poldiv = {"emirates"}},
	["United Kingdom"] = {the = true, container = "Europe", addl_parents = {"British Isles"},
		poldiv = {"constituent countries", "counties", "districts", "boroughs", "territories", "dependent territories"},
		miscdiv = {"traditional counties"},
		keydesc = "the [[United Kingdom]] of Great Britain and Northern Ireland", british_spelling = true},
	["United States"] = {the = true, container = "North America",
		poldiv = {"counties", "county seats", "states", "territories", "dependent territories",
			{type = "boroughs", prep = "in"}, -- exist in Pennsylvania and New Jersey
			"municipalities", -- these exist politically at least in Colorado and Connecticut
			{type = "census-designated places", prep = "in"},
			"Indian reservations",
		}},
	["Uruguay"] = {container = "South America", poldiv = {"departments", "municipalities"}},
	["Uzbekistan"] = {container = "Asia", poldiv = {"regions", "districts"}},
	["Vanuatu"] = {container = "Melanesia", poldiv = {"provinces"}, british_spelling = true},
	["Vatican City"] = {divtype = {"city-state", "country"}, container = "Europe", addl_parents = {"Rome"},
		is_city = true, british_spelling = true},
	["Venezuela"] = {container = "South America", poldiv = {"states", "municipalities"}},
	["Vietnam"] = {container = "Asia", poldiv = {"provinces", "districts", "municipalities"}},
	["Western Sahara"] = {divtype = {"territory", "country"}, container = "Africa"},
	["Yemen"] = {container = "Asia", poldiv = {"governorates", "districts"}},
	["Zambia"] = {container = "Africa", poldiv = {"provinces", "districts"}, british_spelling = true},
	["Zimbabwe"] = {container = "Africa", poldiv = {"provinces", "districts"}, british_spelling = true},
}

local function canonicalize_continent_container(key)
	if type(key) ~= "string" then
		return key
	end
	if export.continents[key] then
		return {name = key, divtype = export.continents[key].divtype}
	end
	internal_error("Unrecognized key %s in `canonicalize_continent_like`", key)
end

export.countries_group = {
	bare_label_setter = simple_polity_bare_label_setter(),
	canonicalize_key_container = canonicalize_continent_container,
	default_divtype = "country",
	data = export.countries,
}


-- Country-like entities: typically overseas territories or de-facto independent countries, which in both cases
-- are not internationally recognized as sovereign nations but which we treat similarly to countries.
export.country_like_entities = {
	-- British Overseas Territory
	["Akrotiri and Dhekelia"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Cyprus", "Europe", "United Kingdom"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["American Samoa"] = {
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Polynesia", "United States"},
	},
	["United States Minor Outlying Islands"] = {
		the = true,
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Islands", "Micronesia", "Polynesia", "United States"},
	},
	-- British Overseas Territory
	["Anguilla"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America", "United Kingdom"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Georgia
	["Abkhazia"] = {
		divtype = {"unrecognized state", "country"},
		addl_parents = {"Georgia", "Europe", "Asia"},
		poldiv = {"districts"},
		keydesc = "the de-facto independent state of [[Abkhazia]], internationally recognized as part of the country of [[Georgia]]",
		british_spelling = true,
	},
	-- de-facto independent state of Armenian ethnicity, internationally recognized as part of Azerbaijan
	-- (also known as Nagorno-Karabakh)
	-- NOTE: Formerly listed Armenia as a parent; this seems politically non-neutral so I've taken it out.
	["Artsakh"] = {
		divtype = {"unrecognized state", "country"},
		addl_parents = {"Azerbaijan", "Europe", "Asia"},
		keydesc = "the former de-facto independent state of [[Artsakh]], internationally recognized as part of [[Azerbaijan]]",
		british_spelling = true,
	},
	-- British Overseas Territory
	["Ascension Island"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Aruba"] = {
		divtype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Bonaire"] = {
		divtype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		is_city = true,
		british_spelling = true,
	},
	-- British Overseas Territory
	["Bermuda"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["British Indian Ocean Territory"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["British Virgin Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Cayman Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- Australian external territory
	["Christmas Island"] = {
		divtype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Australia", "Asia"},
		british_spelling = true,
	},
	-- Australian external territory; also called the Keeling Islands or (officially) the Cocos (Keeling) Islands
	["Cocos Islands"] = {
		the = true,
		divtype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Australia", "Asia"},
		wp = "Cocos (Keeling) Islands",
		british_spelling = true,
	},
	-- self-governing but in free association with New Zealand
	["Cook Islands"] = {
		the = true,
		divtype = {"country"},
		container = "New Zealand",
		addl_parents = {"Polynesia", "New Zealand"},
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Curaçao"] = {
		divtype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		british_spelling = true,
	},
	-- special territory of Chile
	["Easter Island"] = {
		divtype = {"special territory", "territory"},
		container = "Chile",
		addl_parents = {"Chile", "Polynesia"},
	},
	-- British Overseas Territory
	["Falkland Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "South America"},
		british_spelling = true,
	},
	-- autonomous territory of Denmark
	["Faroe Islands"] = {
		the = true,
		divtype = {"autonomous territory", "territory"},
		container = "Denmark",
		addl_parents = {"Denmark", "Europe"},
		british_spelling = true,
	},
	-- overseas department of France
	["French Guiana"] = {
		divtype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"France", "South America"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["French Polynesia"] = {
		divtype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "Polynesia"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Gibraltar"] = {
		divtype = {"overseas territory", "territory"},
		addl_parents = {"United Kingdom", "North America"},
		container = "United Kingdom",
		is_city = true,
		british_spelling = true,
	},
	-- autonomous territory of Denmark
	["Greenland"] = {
		divtype = {"autonomous territory", "territory"},
		addl_parents = {"Denmark", "North America"},
		container = "Denmark",
		poldiv = {"municipalities"},
		british_spelling = true,
	},
	-- overseas department of France
	["Guadeloupe"] = {
		divtype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"France", "North America"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["Guam"] = {
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"United States", "Micronesia"},
	},
	-- self-governing British Crown dependency; technically called the Bailiwick of Guernsey
	["Guernsey"] = {
		divtype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- special administrative region of China
	["Hong Kong"] = {
		divtype = {"special administrative region", "city"},
		container = "China",
		addl_parents = {"China"},
		is_city = true,
		british_spelling = true,
	},
	-- self-governing British Crown dependency
	["Isle of Man"] = {
		the = true,
		divtype = {"crown dependency", "dependency", "dependent territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- self-governing British Crown dependency; technically called the Bailiwick of Jersey
	["Jersey"] = {
		divtype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- special administrative region of China
	["Macau"] = {
		divtype = {"special administrative region", "city"},
		container = "China",
		addl_parents = {"China"},
		is_city = true,
		british_spelling = true,
	},
	-- overseas department of France
	["Martinique"] = {
		divtype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"France", "North America"},
		british_spelling = true,
	},
	-- overseas department of France
	["Mayotte"] = {
		divtype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"France", "Africa"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Montserrat"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- special collectivity of France
	["New Caledonia"] = {
		divtype = {"special collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "Melanesia"},
		british_spelling = true,
	},
	-- self-governing but in free association with New Zealand
	["Niue"] = {
		divtype = {"country"},
		container = "New Zealand",
		addl_parents = {"Polynesia", "New Zealand"},
		british_spelling = true,
	},
	-- Australian external territory
	["Norfolk Island"] = {
		divtype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Australia", "Polynesia"},
		british_spelling = true,
	},
	-- commonwealth, unincorporated territory of the United States
	["Northern Mariana Islands"] = {
		the = true,
		divtype = {"commonwealth", "unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"United States", "Micronesia"},
	},
	-- British Overseas Territory
	["Pitcairn Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Polynesia"},
		british_spelling = true,
	},
	-- commonwealth of the United States
	["Puerto Rico"] = {
		divtype = {"commonwealth", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"United States", "North America"},
		poldiv = {"municipalities"},
	},
	-- overseas department of France
	["Réunion"] = {
		divtype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"France", "Africa"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Saba"] = {
		divtype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		is_city = true,
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Barthélemy"] = {
		divtype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Saint Helena"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Martin"] = {
		divtype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "North America"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Pierre and Miquelon"] = {
		divtype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "North America"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Sint Eustatius"] = {
		divtype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		is_city = true,
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Sint Maarten"] = {
		divtype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"Netherlands", "North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["South Georgia"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Georgia
	["South Ossetia"] = {
		divtype = {"unrecognized state", "country"},
		addl_parents = {"Georgia", "Europe", "Asia"},
		keydesc = "the de-facto independent state of [[South Ossetia]], internationally recognized as part of the country of [[Georgia]]",
		british_spelling = true,
	},
	-- British Overseas Territory
	["South Sandwich Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Atlantic Ocean"},
		wp = true,
		wpcat = "South Georgia and the South Sandwich Islands",
		british_spelling = true,
	},
	-- dependent territory of New Zealnd
	["Tokelau"] = {
		divtype = {"dependent territory", "territory"},
		container = "New Zealand",
		addl_parents = {"New Zealand", "Polynesia"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Moldova
	["Transnistria"] = {
		divtype = {"unrecognized state", "country"},
		addl_parents = {"Moldova", "Europe"},
		keydesc = "the de-facto independent state of [[Transnistria]], internationally recognized as part of [[Moldova]]",
		british_spelling = true,
	},
	-- British Overseas Territory
	["Tristan da Cunha"] = {
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Turks and Caicos Islands"] = {
		the = true,
		divtype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"United Kingdom", "North America"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["United States Virgin Islands"] = {
		the = true,
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"United States", "North America"},
	},
	-- unincorporated territory of the United States
	["Wake Island"] = {
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"United States", "North America"},
	},
	-- overseas collectivity of France
	["Wallis and Futuna"] = {
		divtype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"France", "Polynesia"},
		british_spelling = true,
	},
}

export.country_like_entities_group = {	
	bare_label_setter = simple_polity_bare_label_setter({"Country-like entities"}),
	canonicalize_key_container = make_canonicalize_key_container(nil, "country"),
	-- These entities often aren't really part of their container; a village in Wallis and Futuna (an overseas
	-- collectivity of France in Polynesia), for example, shouldn't be treated as a village in France, nor as a village
	-- in Europe.
	default_no_auto_augment_container = true,
	data = export.country_like_entities,
}


-- Former countries and such; we don't create "Cities in ..." categories because they don't exist anymore
export.former_countries = {
	["Czechoslovakia"] = {container = "Europe", british_spelling = true},
	["East Germany"] = {container = "Europe", addl_parents = {"Germany"}, british_spelling = true},
	["North Vietnam"] = {container = "Asia", addl_parents = {"Vietnam"}},
	["Persia"] = {divtype = {"empire", "country"}, container = "Asia", poldiv = {"provinces"}},
	["Roman Empire"] = {
		the = true, divtype = {"empire", "country"}, container = {"Europe", "Africa", "Asia"}, addl_parents = {"Rome"},
		poldiv = {
			"provinces",
			{type = "FORMER provinces", cat_as = "provinces"},
		}},
	["South Vietnam"] = {container = "Asia", addl_parents = {"Vietnam"}},
	["Soviet Union"] = {
		the = true, container = {"Europe", "Asia"}, poldiv = {"republics", "autonomous republics"},
		british_spelling = true},
	["West Germany"] = {container = "Europe", addl_parents = {"Germany"}, british_spelling = true},
	["Yugoslavia"] = {container = "Europe", poldiv = {"districts"},
		keydesc = "the former [[Kingdom of Yugoslavia]] (1918–1943) or the former [[Socialist Federal Republic of Yugoslavia]] (1943–1992)", british_spelling = true},
}

export.former_countries_group = {
	bare_label_setter = simple_polity_bare_label_setter({"Former countries and country-like entities"}),
	default_is_former_place = true,
	default_divtype = "country",
	data = export.former_countries,
}

-----------------------------------------------------------------------------------
--                                  Subpolity tables                             --
-----------------------------------------------------------------------------------

export.australia_states_and_territories = {
	["Australian Capital Territory, Australia"] = {the = true, divtype = "territory"},
	["New South Wales, Australia"] = {},
	["Northern Territory, Australia"] = {the = true, divtype = "territory"},
	["Queensland, Australia"] = {},
	["South Australia, Australia"] = {},
	["Tasmania, Australia"] = {},
	["Victoria, Australia"] = {},
	["Western Australia, Australia"] = {},
}

-- states and territories of Australia
export.australia_group = {
	key_to_placename = make_key_to_placename(", Australia$"),
	placename_to_key = make_placename_to_key(", Australia"),
	default_container = "Australia",
	default_divtype = "state",
	default_div_parent_type = "states and territories",
	default_poldiv = {"local government areas"},
	default_british_spelling = true,
	data = export.australia_states_and_territories,
}

export.austria_states = {
	["Vienna, Austria"] = {},
	["Lower Austria, Austria"] = {},
	["Upper Austria, Austria"] = {},
	["Styria, Austria"] = {},
	["Tyrol, Austria"] = {},
	["Carinthia, Austria"] = {},
	["Salzburg, Austria"] = {},
	["Vorarlberg, Austria"] = {},
	["Burgenland, Austria"] = {},
}

-- states of Austria
export.austria_group = {
	key_to_placename = make_key_to_placename(", Austria$"),
	placename_to_key = make_placename_to_key(", Austria"),
	default_container = "Austria",
	default_divtype = "state",
	default_british_spelling = true,
	default_poldiv = "municipalities",
	data = export.austria_states,
}

export.bangladesh_divisions = {
	["Barisal Division, Bangladesh"] = {},
	["Chittagong Division, Bangladesh"] = {},
	["Dhaka Division, Bangladesh"] = {},
	["Khulna Division, Bangladesh"] = {},
	["Mymensingh Division, Bangladesh"] = {},
	["Rajshahi Division, Bangladesh"] = {},
	["Rangpur Division, Bangladesh"] = {},
	["Sylhet Division, Bangladesh"] = {},
}

-- divisions of Bangladesh
export.bangladesh_group = {
	key_to_placename = make_key_to_placename(", Bangladesh$", " Division$"),
	placename_to_key = make_placename_to_key(", Bangladesh", " Division"),
	default_container = "Bangladesh",
	default_divtype = "division",
	default_british_spelling = true,
	default_poldiv = "districts",
	data = export.bangladesh_divisions,
}

export.brazil_states = {
	["Acre, Brazil"] = {},
	["Alagoas, Brazil"] = {},
	["Amapá, Brazil"] = {},
	["Amazonas, Brazil"] = {},
	["Bahia, Brazil"] = {},
	["Ceará, Brazil"] = {},
	["Distrito Federal, Brazil"] = {},
	["Espírito Santo, Brazil"] = {},
	["Goiás, Brazil"] = {},
	["Maranhão, Brazil"] = {},
	["Mato Grosso, Brazil"] = {},
	["Mato Grosso do Sul, Brazil"] = {},
	["Minas Gerais, Brazil"] = {},
	["Pará, Brazil"] = {},
	["Paraíba, Brazil"] = {},
	["Paraná, Brazil"] = {},
	["Pernambuco, Brazil"] = {},
	["Piauí, Brazil"] = {},
	["Rio de Janeiro, Brazil"] = {},
	["Rio Grande do Norte, Brazil"] = {},
	["Rio Grande do Sul, Brazil"] = {},
	["Rondônia, Brazil"] = {},
	["Roraima, Brazil"] = {},
	["Santa Catarina, Brazil"] = {},
	["São Paulo, Brazil"] = {},
	["Sergipe, Brazil"] = {},
	["Tocantins, Brazil"] = {},
}

-- states of Brazil
export.brazil_group = {
	key_to_placename = make_key_to_placename(", Brazil$"),
	placename_to_key = make_placename_to_key(", Brazil"),
	default_container = "Brazil",
	default_divtype = "state",
	default_poldiv = "municipalities",
	data = export.brazil_states,
}

export.canada_provinces_and_territories = {
	["Alberta, Canada"] = {poldiv = {
		{type = "municipal districts", skip_polity_parent_type = "rural municipalities"},
	}},
	["British Columbia, Canada"] = {poldiv =
		{type = "regional districts", skip_polity_parent_type = false},
		"regional municipalities",
	},
	["Manitoba, Canada"] = {poldiv = {"rural municipalities"}},
	["New Brunswick, Canada"] = {poldiv = {"counties", "parishes", {type = "civil parishes", cat_as = "parishes"}}},
	["Newfoundland and Labrador, Canada"] = {},
	["Northwest Territories, Canada"] = {the = true, divtype = "territory"},
	["Nova Scotia, Canada"] = {poldiv = {"counties", "regional municipalities"}},
	["Nunavut, Canada"] = {divtype = "territory"},
	["Ontario, Canada"] = {poldiv = {"counties", "regional municipalities", {type = "townships", prep = "in"}}},
	["Prince Edward Island, Canada"] = {poldiv = {"counties", "parishes", "rural municipalities"}},
	["Saskatchewan, Canada"] = {poldiv = {"rural municipalities"}},
	["Quebec, Canada"] = {poldiv = {
		"counties",
		{type = "regional county municipalities", skip_polity_parent_type = "regional municipalities"},
		-- administrative regions have an official (but non-governmental) function but there don't appear to be any
		-- equivalent regions elsewhere in Canada, so disable the [[Category:Regions of Canada]] grouping
		{type = "regions", skip_polity_parent_type = false},
		{type = "townships", prep = "in"},
		{type = "parish municipalities", cat_as = {{type = "parishes", skip_polity_parent_type = "counties"}, "municipalities"}},
		{type = "township municipalities", cat_as = {{type = "townships", prep = "in"}, "municipalities"}},
		{type = "village municipalities", cat_as = {{type = "villages", prep = "in"}, "municipalities"}},
	}},
	["Yukon, Canada"] = {divtype = "territory"},
}

-- provinces and territories of Canada
export.canada_group = {
	key_to_placename = make_key_to_placename(", Canada$"),
	placename_to_key = make_placename_to_key(", Canada"),
	default_container = "Canada",
	default_divtype = "province",
	default_div_parent_type = "provinces and territories",
	default_british_spelling = true,
	data = export.canada_provinces_and_territories,
}

export.china_provinces_and_autonomous_regions = {
	["Anhui, China"] = {},
	["Beijing, China"] = {divtype = {"direct-administered municipality", "municipality"}},
	["Chongqing, China"] = {divtype = {"direct-administered municipality", "municipality"}},
	["Fujian, China"] = {},
	["Gansu, China"] = {},
	["Guangdong, China"] = {},
	["Guangxi, China"] = {divtype = "autonomous region"},
	["Guizhou, China"] = {},
	["Hainan, China"] = {},
	["Hebei, China"] = {},
	["Heilongjiang, China"] = {},
	["Henan, China"] = {},
	["Hubei, China"] = {},
	["Hunan, China"] = {},
	["Inner Mongolia, China"] = {divtype = "autonomous region"},
	["Jiangsu, China"] = {},
	["Jiangxi, China"] = {},
	["Jilin, China"] = {},
	["Liaoning, China"] = {},
	["Ningxia, China"] = {divtype = "autonomous region"},
	["Qinghai, China"] = {},
	["Shaanxi, China"] = {},
	["Shandong, China"] = {},
	["Shanghai, China"] = {divtype = {"direct-administered municipality", "municipality"}},
	["Shanxi, China"] = {},
	["Sichuan, China"] = {},
	["Tianjin, China"] = {divtype = {"direct-administered municipality", "municipality"}},
	["Tibet, China"] = {divtype = "autonomous region"},
	["Xinjiang, China"] = {divtype = "autonomous region"},
	["Yunnan, China"] = {},
	["Zhejiang, China"] = {},
}

-- provinces and autonomous regions of China
export.china_group = {
	key_to_placename = make_key_to_placename(", China$"),
	placename_to_key = make_placename_to_key(", China"),
	default_container = "China",
	default_divtype = "province",
	default_poldiv = {"prefecture-level cities", "county-level cities", "districts"},
	default_div_parent_type = "provinces and autonomous regions",
	data = export.china_provinces_and_autonomous_regions,
}

export.china_prefecture_level_cities = {
	-- In China, a "prefecture-level city" is not a city in any real sense. It is rather a prefecture, which is an
	-- administrative unit smaller than a province but bigger than a county, which is administratively controlled by
	-- the chief city of the prefecture (which bears the same name as the prefecture), in a unified government. Prior
	-- to the mid-1980's, in fact, prefecture-level cities *were* prefectures, and a few of them (especially in the
	-- western portion of China) have not yet been converted. Generally a given province is entirely tiled by
	-- prefecture-level cities, another indication that they should be treated as prefectures and not cities per se.
	-- Yet another indication is that prefecture-level cities can contain counties and county-level cities (which, much
	-- like prefecture-level cities, are effectively counties surrounding a chief city of the county, again which bears
	-- the same name as the county-level city).
	--
	-- For this reason, we treat prefecture-level cities as non-city political divisions, and separately enumerate the
	-- most populous so we can separately categorize districts and counties under them instead of lumping them at the
	-- province level. I chose all prefecture/province-level cities with a total prefecture/province-level population of
	-- at least 6,000,000 per the 2020 census with data taken from https://www.citypopulation.de/en/china/admin/ (a
	-- total of 67, including the four direct-administered municipalities), and also chose all prefecture/province-level
	-- cities whose "urban population" was at least 2,000,000 per the 2020 census with data taken from Wikipedia
	-- [[w:List of cities in China by population#Cities and towns by population]] (a total of 61 cities; if we cut off
	-- at 1.5 million we'd have 84 cities, and if we cut off at 1 million we'd have 105 cities). Merging them produces
	-- 87 cities. Note that this leaves off a few well-known cities (Guilin, Qiqihar, Kashgar, Lhasa, ...) but includes
	-- a lot of obscure cities.
	--
	-- Note also that China separately distinguishes "urban area" from "metro area". Sometimes the two figures are
	-- identical but sometimes the metro area is larger (and very occasionally smaller, which I assume is an error). I'm
	-- guessing that the "urban area" is the contiguous urban area over a certain density while the metro area includes
	-- all urban areas above a certain density; when the latter is greater, it's because of satellite cities in the
	-- metro area separated by suburban/exurban or rural land. Possibly we should use the metro area in preference to
	-- the urban area, but I don't have a readily accessible list sorted by metro population (although the figures are
	-- listed for each city in its respective Wikipedia article).
	["Chongqing"] = {divtype = {"direct-administered municipality", "municipality"}}, -- 32.1 prefectural, 16.9 urban
	["Shanghai"] = {divtype = {"direct-administered municipality", "municipality"}}, -- 24.9 prefectural, 29.9 urban
	["Beijing"] = {divtype = {"direct-administered municipality", "municipality"}}, -- 21.9 prefectural, 21.9 urban
	["Chengdu"] = {container = "Sichuan"}, -- 20.9 prefectural, 16.9 urban; sub-provincial city
	["Guangzhou"] = {container = "Guangdong"}, -- 18.7 prefectural, 18.8 urban; sub-provincial city
	["Shenzhen"] = {container = "Guangdong"}, -- 17.5 prefectural, 14.7 urban; sub-provincial city
	["Tianjin"] = {divtype = {"direct-administered municipality", "municipality"}}, -- 13.9 prefectural, 13.9 urban
	-- NOTE: There is also a prefecture-level city Suzhou in Anhui with 5.3 million prefectural inhabitants
	["Suzhou"] = {container = "Jiangsu"}, -- 12.8 prefectural, 4.3 urban
	["Zhengzhou"] = {container = "Henan"}, -- 12.6 prefectural, 6.7 urban
	["Wuhan"] = {container = "Hubei"}, -- 12.4 prefectural, 12.3 urban; sub-provincial city
	["Xi'an"] = {container = "Shaanxi"}, -- 12.1 prefectural, 11.9 urban; sub-provincial city
	["Hangzhou"] = {container = "Zhejiang"}, -- 11.9 prefectural, 10.7 urban; sub-provincial city
	-- includes Dìngzhōu city and Xióngān Xīnqū
	["Baoding"] = {container = "Hebei"}, -- 11.5 prefectural, 2.0 urban
	-- includes Xīnjí city
	["Shijiazhuang"] = {container = "Hebei"}, -- 11.2 prefectural, 4.1 urban
	["Linyi"] = {container = "Shandong"}, -- 11.0 prefectural, 2.3 urban
	["Dongguan"] = {container = "Guangdong"}, -- 10.5 prefectural, 10.5 urban
	["Qingdao"] = {container = "Shandong"}, -- 10.1 prefectural, 7.1 urban; sub-provincial city
	["Changsha"] = {container = "Hunan"}, -- 10.0 prefectural, 6.0 urban
	["Harbin"] = {container = "Heilongjiang"}, -- 10.0 prefectural, 7.0 urban; sub-provincial city
	["Nanyang"] = {container = "Henan"}, -- 9.7 prefectural, 2.1 urban/metro
	["Wenzhou"] = {container = "Zhejiang"}, -- 9.6 prefectural, 3.6 urban
	["Foshan"] = {container = "Guangdong"}, -- 9.5 prefectural, 9.5 urban
	["Handan"] = {container = "Hebei"}, -- 9.4 prefectural, 2.8 urban
	["Ningbo"] = {container = "Zhejiang"}, -- 9.4 prefectural, 5.1 urban; sub-provincial city
	["Weifang"] = {container = "Shandong"}, -- 9.4 prefectural, 2.7 urban
	["Hefei"] = {container = "Anhui"}, -- 9.4 prefectural, 4.2 urban
	["Nanjing"] = {container = "Jiangsu"}, -- 9.3 prefectural, 9.3 urban; sub-provincial city
	-- includes Láiwú city
	["Jinan"] = {container = "Shandong"}, -- 9.2 prefectural, 8.4 urban; sub-provincial city
	["Xuzhou"] = {container = "Jiangsu"}, -- 9.1 prefectural, 2.6 urban
	["Shenyang"] = {container = "Liaoning"}, -- 9.1 prefectural, 7.9 urban; sub-provincial city
	["Changchun"] = {container = "Jilin"}, -- 9.1 prefectural, 5.7 urban; sub-provincial city
	["Zhoukou"] = {container = "Henan"}, -- 9.0 prefectural, 721,000 urban (1.6 metro)
	["Ganzhou"] = {container = "Jiangxi"}, -- 9.0 prefectural, 1.6 urban
	["Heze"] = {container = "Shandong"}, -- 8.8 prefectural, 1.3 urban
	["Quanzhou"] = {container = "Fujian"}, -- 8.8 prefectural, 1.7 urban (6.7 metro)
	["Nanning"] = {container = {name = "Guangxi", divtype = "autonomous region"}}, -- 8.7 prefectural, 3.8 urban
	["Kunming"] = {container = "Yunnan"}, -- 8.5 prefectural, 6.0 urban
	["Jining"] = {container = "Shandong"}, -- 8.4 prefectural, 1.5 urban
	["Fuzhou"] = {container = "Fujian"}, -- 8.3 prefectural, 4.1 urban
	["Fuyang"] = {container = "Anhui"}, -- 8.2 prefectural, 2.1 urban
	["Shangqiu"] = {container = "Henan"}, -- 7.8 prefectural, 1.9 urban (2.8 metro)
	["Nantong"] = {container = "Jiangsu"}, -- 7.7 prefectural, 2.3 urban
	["Tangshan"] = {container = "Hebei"}, -- 7.7 prefectural, 3.4 urban
	["Wuxi"] = {container = "Jiangsu"}, -- 7.5 prefectural, 3.3 urban
	["Dalian"] = {container = "Liaoning"}, -- 7.5 prefectural, 5.7 urban; sub-provincial city
	-- NOTE: Not to be confused with Changzhou in Jiangsu
	["Cangzhou"] = {container = "Hebei"}, -- 7.3 prefectural, 621,000 urban
	["Xingtai"] = {container = "Hebei"}, -- 7.1 prefectural, 971,000 urban
	["Yantai"] = {container = "Shandong"}, -- 7.1 prefectural, 2.5 urban
	["Luoyang"] = {container = "Henan"}, -- 7.1 prefectural, 2.4 urban
	["Jinhua"] = {container = "Zhejiang"}, -- 7.1 prefectural, 1.5 urban
	["Zhumadian"] = {container = "Henan"}, -- 7.0 prefectural, 722,000 urban
	["Zhanjiang"] = {container = "Guangdong"}, -- 7.0 prefectural, 1.9 urban
	["Bijie"] = {container = "Guizhou"}, -- 6.9 prefectural, ? urban, ? metro (not listed in Wikipedia)
	["Yancheng"] = {container = "Jiangsu"}, -- 6.7 prefectural, 1.6 urban
	["Hengyang"] = {container = "Hunan"}, -- 6.6 prefectural, 1.5 urban
	["Taizhou"] = {container = "Zhejiang"}, -- 6.6 prefectural, 1.6 urban
	["Zunyi"] = {container = "Guizhou"}, -- 6.6 prefectural, 2.4 urban/metro
	["Shaoyang"] = {container = "Hunan"}, -- 6.6 prefectural, 802,000 urban, 1.4 metro
	["Shangrao"] = {container = "Jiangxi"}, -- 6.5 prefectural, 2.1 urban, 1.3 metro [sic]
	["Nanchang"] = {container = "Jiangxi"}, -- 6.3 prefectural, 3.6 (3.9?) urban, 5.3 metro
	["Xinxiang"] = {container = "Henan"}, -- 6.3 prefectural, 1.2 urban, 2.7 metro
	["Xinyang"] = {container = "Henan"}, -- 6.2 prefectural, 1.4 urban/metro
	["Maoming"] = {container = "Guangdong"}, -- 6.2 prefectural, 2.5 urban
	["Huizhou"] = {container = "Guangdong"}, -- 6.0 prefectural, 2.5 urban
	-- cut off at 6,000,000 prefectural per 2020 census
	-- Cities below here have at least 2 million in the urban area
	["Guiyang"] = {container = "Guizhou"}, -- 5.987 prefectural, 3.5 urban
	["Shantou"] = {container = "Guangdong"}, -- 5.502 prefectural, 4.3 urban
	["Taiyuan"] = {container = "Shanxi"}, -- 5.304 prefectural, 4.5 urban
	["Changzhou"] = {container = "Jiangsu"}, -- 5.278 prefectural, 3.6 urban
	["Shaoxing"] = {container = "Zhejiang"}, -- 5.270 prefectural, 2.5 urban
	["Xiamen"] = {container = "Fujian"}, -- 5.163 prefectural, 5.2 urban; sub-provincial city
	["Jiangmen"] = {container = "Guangdong"}, -- 4.798 prefectural, 2.7 urban
	["Zibo"] = {container = "Shandong"}, -- 4.704 prefectural, 2.6 urban
	["Lianyungang"] = {container = "Jiangsu"}, -- 4.599 prefectural, 2.0 urban
	["Huai'an"] = {container = "Jiangsu"}, -- 4.556 prefectural, 2.6 urban
	["Zhongshan"] = {container = "Guangdong"}, -- 4.418 prefectural, 4.4 urban
	["Lanzhou"] = {container = "Gansu"}, -- 4.359 prefectural, 3.1 urban
	["Liuzhou"] = {container = {name = "Guangxi", divtype = "autonomous region"}}, -- 4.157 prefectural, 2.2 urban
	["Ürümqi"] = {container = {name = "Xinjiang", divtype = "autonomous region"}}, -- 4.054 prefectural, 4.3 urban
	["Urumqi"] = {alias_of = "Ürümqi"},
	["Hohhot"] = {container = {name = "Inner Mongolia", divtype = "autonomous region"}}, -- 3.446 prefectural, 2.7 urban
	["Putian"] = {container = "Fujian"}, -- 3.210 prefectural, 2.0 urban
	["Datong"] = {container = "Shanxi"}, -- 3.105 prefectural, 2.0 urban
	["Haikou"] = {container = "Hainan"}, -- 2.873 prefectural, 2.3 urban
	["Baotou"] = {container = {name = "Inner Mongolia", divtype = "autonomous region"}}, -- 2.709 prefectural, 2.2 urban
	["Zhuhai"] = {container = "Guangdong"}, -- 2.439 prefectural, 2.4 urban
}

export.china_prefecture_level_cities_group = {
	default_container = "China",
	canonicalize_key_container = make_canonicalize_key_container(", China", "province"),
	default_divtype = "prefecture-level city",
	default_poldiv = {
		"districts",
		"counties",
		{type = "county-level cities", cat_as = "counties and county-level cities"},
	},
	data = export.china_prefecture_level_cities,
}

export.finland_regions = {
	["Lapland, Finland"] = {},
	["North Ostrobothnia, Finland"] = {},
	["Kainuu, Finland"] = {},
	["North Karelia, Finland"] = {},
	["Northern Savonia, Finland"] = {},
	["Southern Savonia, Finland"] = {},
	["South Karelia, Finland"] = {},
	["Central Finland, Finland"] = {},
	["South Ostrobothnia, Finland"] = {},
	["Ostrobothnia, Finland"] = {},
	["Central Ostrobothnia, Finland"] = {},
	["Pirkanmaa, Finland"] = {},
	["Satakunta, Finland"] = {},
	["Päijänne Tavastia, Finland"] = {},
	["Tavastia Proper, Finland"] = {},
	["Kymenlaakso, Finland"] = {},
	["Uusimaa, Finland"] = {},
	["Southwest Finland, Finland"] = {},
	["Åland Islands, Finland"] = {the = true},
}

-- regions of Finland
export.finland_group = {
	key_to_placename = make_key_to_placename(", Finland$"),
	placename_to_key = make_placename_to_key(", Finland"),
	default_container = "Finland",
	default_divtype = "region",
	default_poldiv = "municipalities",
	default_british_spelling = true,
	data = export.finland_regions,
}

export.france_administrative_regions = {
	["Auvergne-Rhône-Alpes, France"] = {},
	["Bourgogne-Franche-Comté, France"] = {},
	["Brittany, France"] = {},
	["Centre-Val de Loire, France"] = {},
	["Corsica, France"] = {},
	-- overseas departments are handled in `export.country_like_entities`
	-- ["French Guiana"] = {},
	["Grand Est, France"] = {},
	-- ["Guadeloupe"] = {},
	["Hauts-de-France, France"] = {},
	["Île-de-France, France"] = {},
	-- ["Martinique"] = {},
	-- ["Mayotte"] = {},
	["Normandy, France"] = {},
	["Nouvelle-Aquitaine, France"] = {},
	["Occitania, France"] = {},
	["Pays de la Loire, France"] = {},
	["Provence-Alpes-Côte d'Azur, France"] = {},
	-- ["Réunion"] = {},
}

-- administrative regions of France
export.france_group = {
	key_to_placename = make_key_to_placename(", France$"),
	placename_to_key = make_placename_to_key(", France"),
	default_container = "France",
	-- Canonically these are 'administrative regions' but also categorize if identified as a 'region'.
	default_divtype = {"administrative region", "region"},
	default_div_parent_type = "regions",
	default_british_spelling = true,
	data = export.france_administrative_regions,
}

export.germany_states = {
	["Baden-Württemberg, Germany"] = {},
	["Bavaria, Germany"] = {},
	-- Berlin, Bremen and Hamburg are effectively city-states and don't have districts ([[Kreise]]), so override
	-- the default_poldiv setting. Better not to include them at all since they're included as cities down below.
	-- ["Berlin"] = {poldiv = {}},
	["Brandenburg, Germany"] = {},
	-- ["Bremen"] = {poldiv = {}},
	-- ["Hamburg"] = {poldiv = {}},
	["Hesse, Germany"] = {},
	["Lower Saxony, Germany"] = {},
	["Mecklenburg-Vorpommern, Germany"] = {},
	["North Rhine-Westphalia, Germany"] = {},
	["Rhineland-Palatinate, Germany"] = {},
	["Saarland, Germany"] = {},
	["Saxony, Germany"] = {},
	["Saxony-Anhalt, Germany"] = {},
	["Schleswig-Holstein, Germany"] = {},
	["Thuringia, Germany"] = {},
}

-- states of Germany
export.germany_group = {
	key_to_placename = make_key_to_placename(", Germany$"),
	placename_to_key = make_placename_to_key(", Germany"),
	default_container = "Germany",
	default_divtype = "state",
	default_poldiv = "districts",
	default_british_spelling = true,
	data = export.germany_states,
}

local function india_placename_to_key(placename)
	if placename == "Delhi" then
		return placename
	end
	return placename .. ", India"
end

local india_polity_with_divisions = {"divisions", "districts"}
local india_polity_without_divisions = {"districts"}

-- States and union territories of India. Only some of them are divided into divisions.
export.india_states_and_union_territories = {
	["Andaman and Nicobar Islands, India"] =
		{the = true, divtype = "union territory", poldiv = india_polity_without_divisions},
	["Andhra Pradesh, India"] = {poldiv = india_polity_without_divisions},
	["Arunachal Pradesh, India"] = {poldiv = india_polity_with_divisions},
	["Assam, India"] = {poldiv = india_polity_with_divisions},
	["Bihar, India"] = {poldiv = india_polity_with_divisions},
	["Chandigarh, India"] = {divtype = "union territory", poldiv = india_polity_without_divisions},
	["Chhattisgarh, India"] = {poldiv = india_polity_with_divisions},
	["Dadra and Nagar Haveli and Daman and Diu, India"] = {divtype = "union territory", poldiv = india_polity_without_divisions},
	["Delhi"] = {divtype = "union territory", poldiv = india_polity_with_divisions},
	["Goa, India"] = {poldiv = india_polity_without_divisions},
	["Gujarat, India"] = {poldiv = india_polity_without_divisions},
	["Haryana, India"] = {poldiv = india_polity_with_divisions},
	["Himachal Pradesh, India"] = {poldiv = india_polity_with_divisions},
	["Jammu and Kashmir, India"] = {divtype = "union territory", poldiv = india_polity_with_divisions},
	["Jharkhand, India"] = {poldiv = india_polity_with_divisions},
	["Karnataka, India"] = {poldiv = india_polity_with_divisions},
	["Kerala, India"] = {poldiv = india_polity_without_divisions},
	["Ladakh, India"] = {divtype = "union territory", poldiv = india_polity_with_divisions},
	["Lakshadweep, India"] = {divtype = "union territory", poldiv = india_polity_without_divisions},
	["Madhya Pradesh, India"] = {poldiv = india_polity_with_divisions},
	["Maharashtra, India"] = {poldiv = india_polity_with_divisions},
	["Manipur, India"] = {poldiv = india_polity_without_divisions},
	["Meghalaya, India"] = {poldiv = india_polity_with_divisions},
	["Mizoram, India"] = {poldiv = india_polity_without_divisions},
	["Nagaland, India"] = {poldiv = india_polity_with_divisions},
	["Odisha, India"] = {poldiv = india_polity_with_divisions},
	["Puducherry, India"] = {divtype = "union territory", poldiv = india_polity_without_divisions},
	["Punjab, India"] = {poldiv = india_polity_with_divisions},
	["Rajasthan, India"] = {poldiv = india_polity_with_divisions},
	["Sikkim, India"] = {poldiv = india_polity_without_divisions},
	["Tamil Nadu, India"] = {poldiv = india_polity_without_divisions},
	["Telangana, India"] = {poldiv = india_polity_without_divisions},
	["Tripura, India"] = {poldiv = india_polity_without_divisions},
	["Uttar Pradesh, India"] = {poldiv = india_polity_with_divisions},
	["Uttarakhand, India"] = {poldiv = india_polity_with_divisions},
	["West Bengal, India"] = {poldiv = india_polity_with_divisions},
}

-- states and union territories of India
export.india_group = {
	key_to_placename = make_key_to_placename(", India$"),
	placename_to_key = india_placename_to_key,
	default_container = "India",
	default_divtype = "state",
	default_div_parent_type = "states and union territories",
	default_british_spelling = true,
	data = export.india_states_and_union_territories,
}

export.indonesia_provinces = {
	["Aceh, Indonesia"] = {},
	["Bali, Indonesia"] = {},
	["Bangka Belitung Islands, Indonesia"] = {the = true},
	["Banten, Indonesia"] = {},
	["Bengkulu, Indonesia"] = {},
	["Central Java, Indonesia"] = {},
	["Central Kalimantan, Indonesia"] = {},
	["Central Papua, Indonesia"] = {},
	["Central Sulawesi, Indonesia"] = {},
	["East Java, Indonesia"] = {},
	["East Kalimantan, Indonesia"] = {},
	["East Nusa Tenggara, Indonesia"] = {},
	["Gorontalo, Indonesia"] = {},
	["Highland Papua, Indonesia"] = {},
	["Special Capital Region of Jakarta, Indonesia"] = {the = true},
	["Jambi, Indonesia"] = {},
	["Lampung, Indonesia"] = {},
	["Maluku, Indonesia"] = {},
	["North Kalimantan, Indonesia"] = {},
	["North Maluku, Indonesia"] = {},
	["North Sulawesi, Indonesia"] = {},
	["North Papua, Indonesia"] = {},
	["North Sumatra, Indonesia"] = {},
	["Papua, Indonesia"] = {},
	["Riau, Indonesia"] = {},
	["Riau Islands, Indonesia"] = {the = true},
	["Southeast Sulawesi, Indonesia"] = {},
	["South Kalimantan, Indonesia"] = {},
	["South Papua, Indonesia"] = {},
	["South Sulawesi, Indonesia"] = {},
	["South Sumatra, Indonesia"] = {},
	["Southwest Papua, Indonesia"] = {},
	["West Java, Indonesia"] = {},
	["West Kalimantan, Indonesia"] = {},
	["West Nusa Tenggara, Indonesia"] = {},
	["West Papua, Indonesia"] = {},
	["West Sulawesi, Indonesia"] = {},
	["West Sumatra, Indonesia"] = {},
	["Special Region of Yogyakarta, Indonesia"] = {the = true},
}

local function indonesia_key_to_placename(key)
	-- See description of `key_to_placename()`; passed-in placenames *will* have "the" prepended, and the returned
	-- placenames should also, except for the elliptical variants when they exist (as in the case of Jakarta and
	-- Yogyakarta).
	key = key:gsub(", Indonesia$", "")
	local special_region_city = key:match("^the Special.* of (.*)$")
	if special_region_city then
		return key, special_region_city
	else
		return key, key
	end
end

local function indonesia_placename_to_key(placename)
	-- See description of `placename_to_key()`; passed-in placenames will *not* have "the" prepended, and the returned
	-- keys should not, either.
	if placename == "Yogyakarta" then
		placename = "Special Region of Yogyakarta"
	elseif placename == "Jakarta" then
		placename = "Special Capital Region of Jakarta"
	end
	return placename .. ", Indonesia"
end

-- provinces of Indonesia
export.indonesia_group = {
	key_to_placename = indonesia_key_to_placename,
	placename_to_key = indonesia_placename_to_key,
	default_container = "Indonesia",
	default_divtype = "province",
	-- per https://www.quora.com/Does-Indonesia-use-British-or-American-English, Indonesia tends to use American
	-- spellings.
	data = export.indonesia_provinces,
}

export.ireland_counties = {
	["County Carlow, Ireland"] = {},
	["County Cavan, Ireland"] = {},
	["County Clare, Ireland"] = {},
	["County Cork, Ireland"] = {},
	["County Donegal, Ireland"] = {},
	["County Dublin, Ireland"] = {},
	["County Galway, Ireland"] = {},
	["County Kerry, Ireland"] = {},
	["County Kildare, Ireland"] = {},
	["County Kilkenny, Ireland"] = {},
	["County Laois, Ireland"] = {},
	["County Leitrim, Ireland"] = {},
	["County Limerick, Ireland"] = {},
	["County Longford, Ireland"] = {},
	["County Louth, Ireland"] = {},
	["County Mayo, Ireland"] = {},
	["County Meath, Ireland"] = {},
	["County Monaghan, Ireland"] = {},
	["County Offaly, Ireland"] = {},
	["County Roscommon, Ireland"] = {},
	["County Sligo, Ireland"] = {},
	["County Tipperary, Ireland"] = {},
	["County Waterford, Ireland"] = {},
	["County Westmeath, Ireland"] = {},
	["County Wexford, Ireland"] = {},
	["County Wicklow, Ireland"] = {},
}

local function make_irish_type_key_to_placename(polity_pattern)
	return function(key)
		key = key:gsub(polity_pattern, "")
		local elliptical_key = key:gsub("^County ", "")
		return key, elliptical_key
	end
end

local function make_irish_type_placename_to_key(polity_suffix)
	return function(placename)
		if not placename:find("^County ") and not placename:find("^City ") then
			placename = "County " .. placename
		end
		return placename .. polity_suffix
	end
end

-- counties of Ireland
export.ireland_group = {
	key_to_placename = make_irish_type_key_to_placename(", Ireland$"),
	placename_to_key = make_irish_type_placename_to_key(", Ireland"),
	default_container = "Ireland",
	default_divtype = "county",
	default_british_spelling = true,
	data = export.ireland_counties,
}

export.italy_administrative_regions = {
	["Abruzzo, Italy"] = {},
	["Aosta Valley, Italy"] = {divtype = {"autonomous region", "administrative region", "region"}},
	["Apulia, Italy"] = {},
	["Basilicata, Italy"] = {},
	["Calabria, Italy"] = {},
	["Campania, Italy"] = {},
	["Emilia-Romagna, Italy"] = {},
	["Friuli-Venezia Giulia, Italy"] = {divtype = {"autonomous region", "administrative region", "region"}},
	["Lazio, Italy"] = {},
	["Liguria, Italy"] = {},
	["Lombardy, Italy"] = {},
	["Marche, Italy"] = {},
	["Molise, Italy"] = {},
	["Piedmont, Italy"] = {},
	["Sardinia, Italy"] = {divtype = {"autonomous region", "administrative region", "region"}},
	["Sicily, Italy"] = {divtype = {"autonomous region", "administrative region", "region"}},
	["Trentino-Alto Adige, Italy"] = {divtype = {"autonomous region", "administrative region", "region"}},
	["Tuscany, Italy"] = {},
	["Umbria, Italy"] = {},
	["Veneto, Italy"] = {},
}

-- administrative regions of Italy
export.italy_group = {
	key_to_placename = make_key_to_placename(", Italy$"),
	placename_to_key = make_placename_to_key(", Italy"),
	default_container = "Italy",
	default_divtype = {"administrative region", "region"},
	default_div_parent_type = "regions",
	default_british_spelling = true,
	data = export.italy_administrative_regions,
}

-- table of Japanese prefectures; interpolated into the main 'places' table, but also needed separately
export.japan_prefectures = {
	["Aichi Prefecture, Japan"] = {},
	["Akita Prefecture, Japan"] = {},
	["Aomori Prefecture, Japan"] = {},
	["Chiba Prefecture, Japan"] = {},
	["Ehime Prefecture, Japan"] = {},
	["Fukui Prefecture, Japan"] = {},
	["Fukuoka Prefecture, Japan"] = {},
	["Fukushima Prefecture, Japan"] = {},
	["Gifu Prefecture, Japan"] = {},
	["Gunma Prefecture, Japan"] = {},
	["Hiroshima Prefecture, Japan"] = {},
	["Hokkaido Prefecture, Japan"] = {poldiv = "subprefectures"},
	["Hyōgo Prefecture, Japan"] = {},
	["Ibaraki Prefecture, Japan"] = {},
	["Ishikawa Prefecture, Japan"] = {},
	["Iwate Prefecture, Japan"] = {},
	["Kagawa Prefecture, Japan"] = {},
	["Kagoshima Prefecture, Japan"] = {},
	["Kanagawa Prefecture, Japan"] = {},
	["Kōchi Prefecture, Japan"] = {},
	["Kumamoto Prefecture, Japan"] = {},
	["Kyoto Prefecture, Japan"] = {},
	["Mie Prefecture, Japan"] = {},
	["Miyagi Prefecture, Japan"] = {},
	["Miyazaki Prefecture, Japan"] = {},
	["Nagano Prefecture, Japan"] = {},
	["Nagasaki Prefecture, Japan"] = {},
	["Nara Prefecture, Japan"] = {},
	["Niigata Prefecture, Japan"] = {},
	["Ōita Prefecture, Japan"] = {},
	["Okayama Prefecture, Japan"] = {},
	["Okinawa Prefecture, Japan"] = {},
	["Osaka Prefecture, Japan"] = {},
	["Saga Prefecture, Japan"] = {},
	["Saitama Prefecture, Japan"] = {},
	["Shiga Prefecture, Japan"] = {},
	["Shimane Prefecture, Japan"] = {},
	["Shizuoka Prefecture, Japan"] = {},
	["Tochigi Prefecture, Japan"] = {},
	["Tokushima Prefecture, Japan"] = {},
	-- FIXME: We also have Tokyo listed below as a city. Probably we only want the listing under cities, but we need
	-- to support things like special wards of cities.
	--
	-- Don't list subprefectures here so they don't get categorized into [[Category:Subprefectures of Tokyo]] (but
	-- rather [[Category:Subprefectures of Japan]]) since there are only 4 of them.
	["Tokyo"] = {keydesc = "[[Tokyo]] Metropolis", poldiv = {{type = "special wards", skip_polity_parent_type = false}}},
	["Tottori Prefecture, Japan"] = {},
	["Toyama Prefecture, Japan"] = {},
	["Wakayama Prefecture, Japan"] = {},
	["Yamagata Prefecture, Japan"] = {},
	["Yamaguchi Prefecture, Japan"] = {},
	["Yamanashi Prefecture, Japan"] = {},
}

local function japan_placename_to_key(placename)
	if placename == "Tokyo" then
		return placename
	end
	if not placename:find(" Prefecture$") then
		placename = placename .. " Prefecture"
	end
	return placename .. ", Japan"
end

-- prefectures of Japan
export.japan_group = {
	key_to_placename = make_key_to_placename(", Japan$", " Prefecture$"),
	placename_to_key = japan_placename_to_key,
	default_container = "Japan",
	default_divtype = "prefecture",
	data = export.japan_prefectures,
}

export.north_korea_provinces = {
	["Chagang Province, North Korea"] = {},
	["North Hamgyong Province, North Korea"] = {},
	["South Hamgyong Province, North Korea"] = {},
	["North Hwanghae Province, North Korea"] = {},
	["South Hwanghae Province, North Korea"] = {},
	["Kangwon Province, North Korea"] = {},
	["North Pyongan Province, North Korea"] = {},
	["South Pyongan Province, North Korea"] = {},
	["Ryanggang Province, North Korea"] = {},
}

-- provinces of North Korea
export.north_korea_group = {
	key_to_placename = make_key_to_placename(", North Korea$", " Province$"),
	placename_to_key = make_placename_to_key(", North Korea", " Province"),
	default_container = "North Korea",
	default_divtype = "province",
	data = export.north_korea_provinces,
}

export.south_korea_provinces = {
	["North Chungcheong Province, South Korea"] = {},
	["South Chungcheong Province, South Korea"] = {},
	["Gangwon Province, South Korea"] = {},
	["Gyeonggi Province, South Korea"] = {},
	["North Gyeongsang Province, South Korea"] = {},
	["South Gyeongsang Province, South Korea"] = {},
	["North Jeolla Province, South Korea"] = {},
	["South Jeolla Province, South Korea"] = {},
	["Jeju Province, South Korea"] = {},
}

-- provinces of South Korea
export.south_korea_group = {
	key_to_placename = make_key_to_placename(", South Korea$", " Province$"),
	placename_to_key = make_placename_to_key(", South Korea", " Province"),
	default_container = "South Korea",
	default_divtype = "province",
	data = export.south_korea_provinces,
}

export.laos_provinces = {
	["Attapeu Province, Laos"] = {},
	["Bokeo Province, Laos"] = {},
	["Bolikhamxai Province, Laos"] = {},
	["Champasak Province, Laos"] = {},
	["Houaphanh Province, Laos"] = {},
	["Khammouane Province, Laos"] = {},
	["Luang Namtha Province, Laos"] = {},
	["Luang Prabang Province, Laos"] = {},
	["Oudomxay Province, Laos"] = {},
	["Phongsaly Province, Laos"] = {},
	["Salavan Province, Laos"] = {},
	["Savannakhet Province, Laos"] = {},
	["Vientiane Province, Laos"] = {},
	["Vientiane Prefecture, Laos"] = {divtype = "prefecture"},
	["Sainyabuli Province, Laos"] = {},
	["Sekong Province, Laos"] = {},
	["Xaisomboun Province, Laos"] = {},
	["Xiangkhouang Province, Laos"] = {},
}

local function laos_placename_to_key(placename)
	if placename == "Vientiane Prefecture" then
		return placename .. ", Laos"
	end
	if placename:find(" Province$") then
		return placename .. ", Laos"
	end
	return placename .. " Province, Laos"
end

-- provinces of Laos
export.laos_group = {
	key_to_placename = make_key_to_placename(", Laos$", {" Province$", " Prefecture$"}),
	placename_to_key = laos_placename_to_key,
	default_container = "Laos",
	default_divtype = "province",
	data = export.laos_provinces,
}

export.lebanon_governorates = {
	["Akkar Governorate, Lebanon"] = {},
	["Baalbek-Hermel Governorate, Lebanon"] = {},
	["Beirut Governorate, Lebanon"] = {},
	["Beqaa Governorate, Lebanon"] = {},
	["Keserwan-Jbeil Governorate, Lebanon"] = {},
	["Mount Lebanon Governorate, Lebanon"] = {},
	["Nabatieh Governorate, Lebanon"] = {},
	-- These two are generic enough that we don't want to automatically augment a use of `gov/North Governorate` or
	-- `gov/South Governorate` with `c/Lebanon`.
	["North Governorate, Lebanon"] = {no_auto_augment_container = true},
	["South Governorate, Lebanon"] = {no_auto_augment_container = true},
}

-- governorates of Lebanon
export.lebanon_group = {
	key_to_placename = make_key_to_placename(", Lebanon$", " Governorate$"),
	placename_to_key = make_placename_to_key(", Lebanon", " Governorate"),
	default_container = "Lebanon",
	default_divtype = "governorate",
	data = export.lebanon_governorates,
}

export.malaysia_states = {
	["Johor, Malaysia"] = {},
	["Kedah, Malaysia"] = {},
	["Kelantan, Malaysia"] = {},
	["Malacca, Malaysia"] = {},
	["Negeri Sembilan, Malaysia"] = {},
	["Pahang, Malaysia"] = {},
	["Penang, Malaysia"] = {},
	["Perak, Malaysia"] = {},
	["Perlis, Malaysia"] = {},
	["Sabah, Malaysia"] = {},
	["Sarawak, Malaysia"] = {},
	["Selangor, Malaysia"] = {},
	["Terengganu, Malaysia"] = {},
}

-- states of Malaysia
export.malaysia_group = {
	key_to_placename = make_key_to_placename(", Malaysia$"),
	placename_to_key = make_placename_to_key(", Malaysia"),
	default_container = "Malaysia",
	default_divtype = "state",
	default_british_spelling = true,
	data = export.malaysia_states,
}

export.malta_regions = {
	-- Some of the regions are generic enough that we don't want to automatically augment a use of e.g.
	-- `r/Northern Region` with `c/Malta`. In particular;
	-- * "Eastern Region" also occurs at least in Ghana, Uganda, Iceland, Nigeria, Venezuela, North Macedonia and
	--   El Salvador;
	-- * "Northern Region" also occurs at least in Ghana, Uganda, Malawi, Nigeria, Canada and South Africa;
	-- * "Western Region" also occurs at least in Abu Dhabi, Bahrain, South Africa, Ghana, Iceland, Nepal, Nigeria,
	--   Serbia and Uganda;
	-- * "Southern Region" also occurs at least in Nigeria, Eritrea, Iceland, Ireland, Malawi and Serbia.
	["Eastern Region, Malta"] = {no_auto_augment_container = true},
	["Gozo Region, Malta"] = {},
	["Northern Region, Malta"] = {no_auto_augment_container = true},
	["Port Region, Malta"] = {},
	["Southern Region, Malta"] = {no_auto_augment_container = true},
	["Western Region, Malta"] = {no_auto_augment_container = true},
}

-- regions of Malta
export.malta_group = {
	key_to_placename = make_key_to_placename(", Malta$", " Region"),
	placename_to_key = make_placename_to_key(", Malta", " Region"),
	default_container = "Malta",
	default_divtype = "region",
	default_british_spelling = true,
	data = export.malta_regions,
}

export.mexico_states = {
	["Aguascalientes, Mexico"] = {},
	["Baja California, Mexico"] = {},
	["Baja California Sur, Mexico"] = {},
	["Campeche, Mexico"] = {},
	["Chiapas, Mexico"] = {},
	-- ["Mexico City, Mexico"] = {}, doesn't belong here because it's a city
	["Chihuahua, Mexico"] = {},
	["Coahuila, Mexico"] = {},
	["Colima, Mexico"] = {},
	["Durango, Mexico"] = {},
	["Guanajuato, Mexico"] = {},
	["Guerrero, Mexico"] = {},
	["Hidalgo, Mexico"] = {},
	["Jalisco, Mexico"] = {},
	["State of Mexico, Mexico"] = {the = true},
	["Michoacán, Mexico"] = {},
	["Morelos, Mexico"] = {},
	["Nayarit, Mexico"] = {},
	["Nuevo León, Mexico"] = {},
	["Oaxaca, Mexico"] = {},
	["Puebla, Mexico"] = {},
	["Querétaro, Mexico"] = {},
	["Quintana Roo, Mexico"] = {},
	["San Luis Potosí, Mexico"] = {},
	["Sinaloa, Mexico"] = {},
	["Sonora, Mexico"] = {},
	["Tabasco, Mexico"] = {},
	["Tamaulipas, Mexico"] = {},
	["Tlaxcala, Mexico"] = {},
	["Veracruz, Mexico"] = {},
	["Yucatán, Mexico"] = {},
	["Zacatecas, Mexico"] = {},
}

-- Special handling for the State of Mexico, which we allow the be specified as s/Mexico or s/State of Mexico.
local function mexico_key_to_placename(key)
	key = key:gsub(", Mexico$", "")
	if key == "State of Mexico" then
		return key, "Mexico"
	else
		return key, key
	end
end

local function mexico_placename_to_key(placename)
	if placename == "Mexico" then
		placename = "State of Mexico"
	end
	return placename .. ", Mexico"
end

-- Mexican states
export.mexico_group = {
	key_to_placename = mexico_key_to_placename,
	placename_to_key = mexico_placename_to_key,
	default_container = "Mexico",
	default_divtype = "state",
	data = export.mexico_states,
}

export.morocco_regions = {
	["Tangier-Tetouan-Al Hoceima, Morocco"] = {},
	["Oriental, Morocco"] = {},
	["Fez-Meknes, Morocco"] = {},
	["Rabat-Sale-Kenitra, Morocco"] = {},
	["Beni Mellal-Khenifra, Morocco"] = {},
	["Casablanca-Settat, Morocco"] = {},
	["Marrakesh-Safi, Morocco"] = {},
	["Draa-Tafilalet, Morocco"] = {},
	["Souss-Massa, Morocco"] = {},
	["Guelmim-Oued Noun, Morocco"] = {},
	["Laayoune-Sakia El Hamra, Morocco"] = {},
	["Dakhla-Oued Ed-Dahab, Morocco"] = {},
}

-- regions of Morocco
export.morocco_group = {
	key_to_placename = make_key_to_placename(", Morocco$"),
	placename_to_key = make_placename_to_key(", Morocco"),
	default_container = "Morocco",
	default_divtype = "region",
	default_british_spelling = true,
	data = export.morocco_regions,
}

export.netherlands_provinces = {
	["Drenthe, Netherlands"] = {},
	["Flevoland, Netherlands"] = {},
	["Friesland, Netherlands"] = {},
	["Gelderland, Netherlands"] = {},
	["Groningen, Netherlands"] = {},
	["Limburg, Netherlands"] = {},
	["North Brabant, Netherlands"] = {},
	["North Holland, Netherlands"] = {},
	["Overijssel, Netherlands"] = {},
	["South Holland, Netherlands"] = {},
	["Utrecht, Netherlands"] = {},
	["Zeeland, Netherlands"] = {},
}

-- provinces of the Netherlands
export.netherlands_group = {
	key_to_placename = make_key_to_placename(", Netherlands$"),
	placename_to_key = make_placename_to_key(", Netherlands"),
	default_container = "Netherlands",
	default_divtype = "province",
	default_poldiv = "municipalities",
	default_british_spelling = true,
	data = export.netherlands_provinces,
}

export.nigeria_states = {
	["Abia State, Nigeria"] = {},
	["Adamawa State, Nigeria"] = {},
	["Akwa Ibom State, Nigeria"] = {},
	["Anambra State, Nigeria"] = {},
	["Bauchi State, Nigeria"] = {},
	["Bayelsa State, Nigeria"] = {},
	["Benue State, Nigeria"] = {},
	["Borno State, Nigeria"] = {},
	["Cross River State, Nigeria"] = {},
	["Delta State, Nigeria"] = {},
	["Ebonyi State, Nigeria"] = {},
	["Edo State, Nigeria"] = {},
	["Ekiti State, Nigeria"] = {},
	["Enugu State, Nigeria"] = {},
	["Gombe State, Nigeria"] = {},
	["Imo State, Nigeria"] = {},
	["Jigawa State, Nigeria"] = {},
	["Kaduna State, Nigeria"] = {},
	["Kano State, Nigeria"] = {},
	["Katsina State, Nigeria"] = {},
	["Kebbi State, Nigeria"] = {},
	["Kogi State, Nigeria"] = {},
	["Kwara State, Nigeria"] = {},
	["Lagos State, Nigeria"] = {},
	["Nasarawa State, Nigeria"] = {},
	["Niger State, Nigeria"] = {},
	["Ogun State, Nigeria"] = {},
	["Ondo State, Nigeria"] = {},
	["Osun State, Nigeria"] = {},
	["Oyo State, Nigeria"] = {},
	["Plateau State, Nigeria"] = {},
	["Rivers State, Nigeria"] = {},
	["Sokoto State, Nigeria"] = {},
	["Taraba State, Nigeria"] = {},
	["Yobe State, Nigeria"] = {},
	["Zamfara State, Nigeria"] = {},
}

-- states of Nigeria
export.nigeria_group = {
	key_to_placename = make_key_to_placename(", Nigeria$", " State$"),
	placename_to_key = make_placename_to_key(", Nigeria", " State"),
	default_container = "Nigeria",
	default_divtype = "state",
	default_british_spelling = true,
	data = export.nigeria_states,
}

export.norwegian_counties = {
	["Oslo, Norway"] = {},
	["Rogaland, Norway"] = {},
	["Møre og Romsdal, Norway"] = {},
	["Nordland, Norway"] = {},
	["Østfold, Norway"] = {},
	["Akershus, Norway"] = {},
	["Buskerud, Norway"] = {},
	-- the following two were merged into Innlandet
	-- ["Hedmark, Norway"] = {},
	-- ["Oppland, Norway"] = {},
	["Innlandet, Norway"] = {},
	["Vestfold, Norway"] = {},
	["Telemark, Norway"] = {},
	-- the following two were merged into Agder
	-- ["Aust-Agder, Norway"] = {},
	-- ["Vest-Agder, Norway"] = {},
	["Agder, Norway"] = {},
	-- the following two were merged into Vestland
	-- ["Hordaland, Norway"] = {},
	-- ["Sogn og Fjordane, Norway"] = {},
	["Vestland, Norway"] = {},
	["Trøndelag, Norway"] = {},
	["Troms, Norway"] = {},
	["Finnmark, Norway"] = {},
}

-- counties of Norway
export.norway_group = {
	key_to_placename = make_key_to_placename(", Norway$"),
	placename_to_key = make_placename_to_key(", Norway"),
	default_container = "Norway",
	default_divtype = "county",
	default_british_spelling = true,
	data = export.norwegian_counties,
}

export.pakistan_provinces_and_territories = {
	["Azad Kashmir, Pakistan"] = { -- Azad Jammu and Kashmir is an accepted alias
		divtype = {"administrative territory", "territory"},
	},
	["Balochistan, Pakistan"] = {},
	["Gilgit-Baltistan, Pakistan"] = {
		divtype = {"administrative territory", "territory"},
	},
	["Islamabad Capital Territory, Pakistan"] = { -- Islamabad is an accepted alias given the divtypes below
		poldiv = {}, -- no divisions
		divtype = {"federal territory", "administrative territory", "territory"},
	},
	["Khyber Pakhtunkhwa, Pakistan"] = {},
	["Punjab, Pakistan"] = {},
	["Sindh, Pakistan"] = {},
}

-- provinces and territories of Pakistan
export.pakistan_group = {
	key_to_placename = make_key_to_placename(", Pakistan$"),
	placename_to_key = make_placename_to_key(", Pakistan"),
	default_container = "Pakistan",
	default_divtype = "province",
	default_div_parent_type = "provinces and territories",
	default_poldiv = {"divisions"},
	default_british_spelling = true,
	data = export.pakistan_provinces_and_territories,
}

export.philippines_provinces = {
	["Abra, Philippines"] = {},
	["Agusan del Norte, Philippines"] = {},
	["Agusan del Sur, Philippines"] = {},
	["Aklan, Philippines"] = {},
	["Albay, Philippines"] = {},
	["Antique, Philippines"] = {},
	["Apayao, Philippines"] = {},
	["Aurora, Philippines"] = {},
	["Basilan, Philippines"] = {},
	["Bataan, Philippines"] = {},
	["Batanes, Philippines"] = {},
	["Batangas, Philippines"] = {},
	["Benguet, Philippines"] = {},
	["Biliran, Philippines"] = {},
	["Bohol, Philippines"] = {},
	["Bukidnon, Philippines"] = {},
	["Bulacan, Philippines"] = {},
	["Cagayan, Philippines"] = {},
	["Camarines Norte, Philippines"] = {},
	["Camarines Sur, Philippines"] = {},
	["Camiguin, Philippines"] = {},
	["Capiz, Philippines"] = {},
	["Catanduanes, Philippines"] = {},
	["Cavite, Philippines"] = {},
	["Cebu, Philippines"] = {},
	["Cotabato, Philippines"] = {},
	["Davao de Oro, Philippines"] = {},
	["Davao del Norte, Philippines"] = {},
	["Davao del Sur, Philippines"] = {},
	["Davao Occidental, Philippines"] = {},
	["Davao Oriental, Philippines"] = {},
	["Dinagat Islands, Philippines"] = {the = true},
	["Eastern Samar, Philippines"] = {},
	["Guimaras, Philippines"] = {},
	["Ifugao, Philippines"] = {},
	["Ilocos Norte, Philippines"] = {},
	["Ilocos Sur, Philippines"] = {},
	["Iloilo, Philippines"] = {},
	["Isabela, Philippines"] = {},
	["Kalinga, Philippines"] = {},
	["La Union, Philippines"] = {},
	["Laguna, Philippines"] = {},
	["Lanao del Norte, Philippines"] = {},
	["Lanao del Sur, Philippines"] = {},
	["Leyte, Philippines"] = {},
	["Maguindanao del Norte, Philippines"] = {},
	["Maguindanao del Sur, Philippines"] = {},
	["Marinduque, Philippines"] = {},
	["Masbate, Philippines"] = {},
	["Misamis Occidental, Philippines"] = {},
	["Misamis Oriental, Philippines"] = {},
	["Mountain Province, Philippines"] = {},
	["Negros Occidental, Philippines"] = {},
	["Negros Oriental, Philippines"] = {},
	["Northern Samar, Philippines"] = {},
	["Nueva Ecija, Philippines"] = {},
	["Nueva Vizcaya, Philippines"] = {},
	["Occidental Mindoro, Philippines"] = {},
	["Oriental Mindoro, Philippines"] = {},
	["Palawan, Philippines"] = {},
	["Pampanga, Philippines"] = {},
	["Pangasinan, Philippines"] = {},
	["Quezon, Philippines"] = {},
	["Quirino, Philippines"] = {},
	["Rizal, Philippines"] = {},
	["Romblon, Philippines"] = {},
	["Samar, Philippines"] = {},
	["Sarangani, Philippines"] = {},
	["Siquijor, Philippines"] = {},
	["Sorsogon, Philippines"] = {},
	["South Cotabato, Philippines"] = {},
	["Southern Leyte, Philippines"] = {},
	["Sultan Kudarat, Philippines"] = {},
	["Sulu, Philippines"] = {},
	["Surigao del Norte, Philippines"] = {},
	["Surigao del Sur, Philippines"] = {},
	["Tarlac, Philippines"] = {},
	["Tawi-Tawi, Philippines"] = {},
	["Zambales, Philippines"] = {},
	["Zamboanga del Norte, Philippines"] = {},
	["Zamboanga del Sur, Philippines"] = {},
	["Zamboanga Sibugay, Philippines"] = {},
	--not a province but treated as one
	["Metro Manila, Philippines"] = {divtype = "region"},
}

-- provinces of the Philippines
export.philippines_group = {
	key_to_placename = make_key_to_placename(", Philippines$"),
	placename_to_key = make_placename_to_key(", Philippines"),
	default_container = "Philippines",
	default_divtype = "province",
	default_poldiv = {"municipalities", "barangays"},
	data = export.philippines_provinces,
}

export.romania_counties = {
	["Alba County, Romania"] = {},
	["Arad County, Romania"] = {},
	["Argeș County, Romania"] = {},
	["Bacău County, Romania"] = {},
	["Bihor County, Romania"] = {},
	["Bistrița-Năsăud County, Romania"] = {},
	["Botoșani County, Romania"] = {},
	["Brașov County, Romania"] = {},
	["Brăila County, Romania"] = {},
	["Buzău County, Romania"] = {},
	["Caraș-Severin County, Romania"] = {},
	["Cluj County, Romania"] = {},
	["Constanța County, Romania"] = {},
	["Covasna County, Romania"] = {},
	["Călărași County, Romania"] = {},
	["Dolj County, Romania"] = {},
	["Dâmbovița County, Romania"] = {},
	["Galați County, Romania"] = {},
	["Giurgiu County, Romania"] = {},
	["Gorj County, Romania"] = {},
	["Harghita County, Romania"] = {},
	["Hunedoara County, Romania"] = {},
	["Ialomița County, Romania"] = {},
	["Iași County, Romania"] = {},
	["Ilfov County, Romania"] = {},
	["Maramureș County, Romania"] = {},
	["Mehedinți County, Romania"] = {},
	["Mureș County, Romania"] = {},
	["Neamț County, Romania"] = {},
	["Olt County, Romania"] = {},
	["Prahova County, Romania"] = {},
	["Satu Mare County, Romania"] = {},
	["Sibiu County, Romania"] = {},
	["Suceava County, Romania"] = {},
	["Sălaj County, Romania"] = {},
	["Teleorman County, Romania"] = {},
	["Timiș County, Romania"] = {},
	["Tulcea County, Romania"] = {},
	["Vaslui County, Romania"] = {},
	["Vrancea County, Romania"] = {},
	["Vâlcea County, Romania"] = {},
}

-- counties of Romania
export.romania_group = {
	key_to_placename = make_key_to_placename(", Romania$", " County$"),
	placename_to_key = make_placename_to_key(", Romania", " County"),
	default_container = "Romania",
	default_divtype = "county",
	default_british_spelling = true,
	data = export.romania_counties,
}

local function make_russia_federal_subject_spec(spectype, use_the)
	return {the = not not use_the, divtype = spectype, div_parent_type = {"federal subjects", spectype .. "s"}}
end

local russia_autonomous_okrug =
	{divtype = {"autonomous okrug", "okrug"}, div_parent_type = {"federal subjects", "autonomous okrugs"}}
local russia_krai = make_russia_federal_subject_spec("krai")
local russia_oblast = make_russia_federal_subject_spec("oblast")
local russia_republic = make_russia_federal_subject_spec("republic", "the")
export.russia_federal_subjects = {
	-- autonomous oblasts
	["Jewish Autonomous Oblast"] =
		{the = true, divtype = {"autonomous oblast", "oblast"},
		 div_parent_type = {"federal subjects", "autonomous oblasts"}},
	-- autonomous okrugs
	["Chukotka Autonomous Okrug"] = russia_autonomous_okrug,
	["Khanty-Mansi Autonomous Okrug"] = russia_autonomous_okrug,
	["Nenets Autonomous Okrug"] = russia_autonomous_okrug,
	["Yamalo-Nenets Autonomous Okrug"] = russia_autonomous_okrug,
	-- krais
	["Altai Krai"] = russia_krai,
	["Kamchatka Krai"] = russia_krai,
	["Khabarovsk Krai"] = russia_krai,
	["Krasnodar Krai"] = russia_krai,
	["Krasnoyarsk Krai"] = russia_krai,
	["Perm Krai"] = russia_krai,
	["Primorsky Krai"] = russia_krai,
	["Stavropol Krai"] = russia_krai,
	["Zabaykalsky Krai"] = russia_krai,
	-- oblasts
	["Amur Oblast"] = russia_oblast,
	["Arkhangelsk Oblast"] = russia_oblast,
	["Astrakhan Oblast"] = russia_oblast,
	["Belgorod Oblast"] = russia_oblast,
	["Bryansk Oblast"] = russia_oblast,
	["Chelyabinsk Oblast"] = russia_oblast,
	["Irkutsk Oblast"] = russia_oblast,
	["Ivanovo Oblast"] = russia_oblast,
	["Kaliningrad Oblast"] = russia_oblast,
	["Kaluga Oblast"] = russia_oblast,
	["Kemerovo Oblast"] = russia_oblast,
	["Kirov Oblast"] = russia_oblast,
	["Kostroma Oblast"] = russia_oblast,
	["Kurgan Oblast"] = russia_oblast,
	["Kursk Oblast"] = russia_oblast,
	["Leningrad Oblast"] = russia_oblast,
	["Lipetsk Oblast"] = russia_oblast,
	["Magadan Oblast"] = russia_oblast,
	["Moscow Oblast"] = russia_oblast,
	["Murmansk Oblast"] = russia_oblast,
	["Nizhny Novgorod Oblast"] = russia_oblast,
	["Novgorod Oblast"] = russia_oblast,
	["Novosibirsk Oblast"] = russia_oblast,
	["Omsk Oblast"] = russia_oblast,
	["Orenburg Oblast"] = russia_oblast,
	["Oryol Oblast"] = russia_oblast,
	["Penza Oblast"] = russia_oblast,
	["Pskov Oblast"] = russia_oblast,
	["Rostov Oblast"] = russia_oblast,
	["Ryazan Oblast"] = russia_oblast,
	["Sakhalin Oblast"] = russia_oblast,
	["Samara Oblast"] = russia_oblast,
	["Saratov Oblast"] = russia_oblast,
	["Smolensk Oblast"] = russia_oblast,
	["Sverdlovsk Oblast"] = russia_oblast,
	["Tambov Oblast"] = russia_oblast,
	["Tomsk Oblast"] = russia_oblast,
	["Tula Oblast"] = russia_oblast,
	["Tver Oblast"] = russia_oblast,
	["Tyumen Oblast"] = russia_oblast,
	["Ulyanovsk Oblast"] = russia_oblast,
	["Vladimir Oblast"] = russia_oblast,
	["Volgograd Oblast"] = russia_oblast,
	["Vologda Oblast"] = russia_oblast,
	["Voronezh Oblast"] = russia_oblast,
	["Yaroslavl Oblast"] = russia_oblast,
	-- republics
	["Republic of Adygea"] = russia_republic,
	["Republic of Bashkortostan"] = russia_republic,
	["Republic of Buryatia"] = russia_republic,
	["Republic of Dagestan"] = russia_republic,
	["Republic of Ingushetia"] = russia_republic,
	["Republic of Kalmykia"] = russia_republic,
	["Republic of Karelia"] = russia_republic,
	["Republic of Khakassia"] = russia_republic,
	["Republic of Mordovia"] = russia_republic,
	["Republic of North Ossetia-Alania"] = russia_republic,
	["Republic of Tatarstan"] = russia_republic,
	["Altai Republic"] = russia_republic,
	["Chechen Republic"] = russia_republic,
	["Chuvash Republic"] = russia_republic,
	["Kabardino-Balkar Republic"] = russia_republic,
	["Karachay-Cherkess Republic"] = russia_republic,
	["Komi Republic"] = russia_republic,
	["Mari El Republic"] = russia_republic,
	["Sakha Republic"] = russia_republic,
	["Tuva Republic"] = russia_republic,
	["Udmurt Republic"] = russia_republic,
	-- Not sure what to do about this one from a neutrality perspective
	-- ["the Republic of Crimea"] = russia_republic,
	-- There are also federal cities (not included because they're cities):
	-- Moscow, Saint Petersburg, Sevastopol (not sure what to do about the
	-- last one if we were to include federal cities, see "Republic of Crimea"
	-- above)
}

local function russia_placename_to_key(placename)
	-- We allow the user to say e.g. "obl/Samara" and "rep/Tatarstan" in place of
	-- "obl/Samara Oblast" and "rep/Republic of Tatarstan".
	if export.russia_federal_subjects[placename] or export.russia_federal_subjects["the " .. placename] then
		return placename
	end
	for _, suffix in ipairs({"Autonomous Okrug", "Krai", "Oblast"}) do
		local suffixed_placename = placename .. " " .. suffix
		if export.russia_federal_subjects[suffixed_placename] then
			return suffixed_placename
		end
	end
	local republic_placename = "Republic of " .. placename
	if export.russia_federal_subjects["the " .. republic_placename] then
		return republic_placename
	end
	local republic_placename = placename .. " Republic"
	if export.russia_federal_subjects["the " .. republic_placename] then
		return republic_placename
	end
	return placename
end

local function construct_russia_federal_subject_keydesc(group, key, spec)
	local linked_key = export.construct_linked_key(key, spec)
	if spec.divtype == "oblast" then
		-- Hack: Oblasts generally don't have entries under "Foo Oblast"
		-- but just under "Foo", so fix the linked key appropriately;
		-- doesn't apply to the Jewish Autonomous Oblast
		linked_key = linked_key:gsub(" Oblast%]%]", "%]%] Oblast")
	end
	return linked_key .. ", a federal subject ([[" .. divtype .. "]]) of [[Russia]]"
end

-- federal subjects of Russia
export.russia_group = {
	-- No current need for key_to_placename because it's only used in subpolity_bare_label_setter and
	-- subpolity_value_transformer, and we override both handlers. (FIXME: No longer true; we also use
	-- key_to_placename in the category augmentation code at the bottom of [[Module:place/data]], so we should
	-- define a key_to_placename appropriately.)
	placename_to_key = russia_placename_to_key,
	default_container = "Russia",
	default_keydesc = construct_russia_federal_subject_keydesc,
	bare_label_setter = function(group, key, value, m_data)
		local divtype = value.divtype or group.default_divtype
		if type(divtype) == "table" then
			divtype = divtype[1]
		end
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		return {
			type = "topic",
			description = "{{{langname}}} terms related to " ..
				construct_russia_federal_subject_keydesc(linked_key, divtype) .. ".",
			parents = {"federal subjects of Russia", m_data.pluralize_placetype(divtype) .. " of Russia"},
		}
	end,
	default_british_spelling = true,
	data = export.russia_federal_subjects,
}

export.saudi_arabia_provinces = {
	["Riyadh Province, Saudi Arabia"] = {},
	["Mecca Province, Saudi Arabia"] = {},
	-- Name is too generic to assume it's in Saudi Arabia if not specified.
	["Eastern Province, Saudi Arabia"] = {no_auto_augment_container = true},
	["Medina Province, Saudi Arabia"] = {},
	["Aseer Province, Saudi Arabia"] = {},
	["Jazan Province, Saudi Arabia"] = {},
	["Qassim Province, Saudi Arabia"] = {},
	["Tabuk Province, Saudi Arabia"] = {},
	["Hail Province, Saudi Arabia"] = {},
	["Al-Jouf Province, Saudi Arabia"] = {},
	["Najran Province, Saudi Arabia"] = {},
	["Northern Borders Province, Saudi Arabia"] = {},
	["Al-Bahah Province, Saudi Arabia"] = {},
}

-- provinces of Saudi Arabia
export.saudi_arabia_group = {
	key_to_placename = make_key_to_placename(", Saudi Arabia$", " Province$"),
	placename_to_key = make_placename_to_key(", Saudi Arabia", " Province"),
	default_container = "Saudi Arabia",
	default_divtype = "province",
	data = export.saudi_arabia_provinces,
}

export.spain_autonomous_communities = {
	["Andalusia, Spain"] = {},
	["Aragon, Spain"] = {},
	["Asturias, Spain"] = {},
	["Balearic Islands, Spain"] = {the = true},
	["Basque Country, Spain"] = {the = true},
	["Canary Islands, Spain"] = {the = true},
	["Cantabria, Spain"] = {},
	["Castile and León, Spain"] = {},
	["Castilla-La Mancha, Spain"] = {},
	["Catalonia, Spain"] = {},
	["Community of Madrid, Spain"] = {the = true},
	["Extremadura, Spain"] = {},
	["Galicia, Spain"] = {},
	["La Rioja, Spain"] = {},
	["Murcia, Spain"] = {},
	["Navarre, Spain"] = {},
	["Valencia, Spain"] = {},
}

-- autonomous communities of Spain
export.spain_group = {
	key_to_placename = make_key_to_placename(", Spain$"),
	placename_to_key = make_placename_to_key(", Spain"),
	default_container = "Spain",
	default_divtype = "autonomous community",
	default_british_spelling = true,
	data = export.spain_autonomous_communities,
}

export.taiwan_counties = {
	["Changhua County, Taiwan"] = {},
	["Chiayi County, Taiwan"] = {},
	["Hsinchu County, Taiwan"] = {},
	["Hualien County, Taiwan"] = {},
	["Kinmen County, Taiwan"] = {},
	["Lienchiang County, Taiwan"] = {},
	["Miaoli County, Taiwan"] = {},
	["Nantou County, Taiwan"] = {},
	["Penghu County, Taiwan"] = {},
	["Pingtung County, Taiwan"] = {},
	["Taitung County, Taiwan"] = {},
	["Yilan County, Taiwan"] = {},
	["Yunlin County, Taiwan"] = {},
}

-- counties of Taiwan
export.taiwan_group = {
	key_to_placename = make_key_to_placename(", Taiwan$", " County$"),
	placename_to_key = make_placename_to_key(", Taiwan", " County"),
	default_container = "Taiwan",
	default_divtype = "county",
	data = export.taiwan_counties,
}

export.thailand_provinces = {
	["Amnat Charoen Province, Thailand"] = {},
	["Ang Thong Province, Thailand"] = {},
	["Bueng Kan Province, Thailand"] = {},
	["Buriram Province, Thailand"] = {},
	["Chachoengsao Province, Thailand"] = {},
	["Chai Nat Province, Thailand"] = {},
	["Chaiyaphum Province, Thailand"] = {},
	["Chanthaburi Province, Thailand"] = {},
	["Chiang Mai Province, Thailand"] = {},
	["Chiang Rai Province, Thailand"] = {},
	["Chonburi Province, Thailand"] = {},
	["Chumphon Province, Thailand"] = {},
	["Kalasin Province, Thailand"] = {},
	["Kamphaeng Phet Province, Thailand"] = {},
	["Kanchanaburi Province, Thailand"] = {},
	["Khon Kaen Province, Thailand"] = {},
	["Krabi Province, Thailand"] = {},
	["Lampang Province, Thailand"] = {},
	["Lamphun Province, Thailand"] = {},
	["Loei Province, Thailand"] = {},
	["Lopburi Province, Thailand"] = {},
	["Mae Hong Son Province, Thailand"] = {},
	["Maha Sarakham Province, Thailand"] = {},
	["Mukdahan Province, Thailand"] = {},
	["Nakhon Nayok Province, Thailand"] = {},
	["Nakhon Pathom Province, Thailand"] = {},
	["Nakhon Phanom Province, Thailand"] = {},
	["Nakhon Ratchasima Province, Thailand"] = {},
	["Nakhon Sawon Province, Thailand"] = {},
	["Nakhon Si Thammarat Province, Thailand"] = {},
	["Nan Province, Thailand"] = {},
	["Narathiwat Province, Thailand"] = {},
	["Nong Bua Lamphu Province, Thailand"] = {},
	["Nong Khai Province, Thailand"] = {},
	["Nonthaburi Province, Thailand"] = {},
	["Pathum Thani Province, Thailand"] = {},
	["Pattani Province, Thailand"] = {},
	["Phang Nga Province, Thailand"] = {},
	["Phatthalung Province, Thailand"] = {},
	["Phayao Province, Thailand"] = {},
	["Phetchabun Province, Thailand"] = {},
	["Phetchaburi Province, Thailand"] = {},
	["Phichit Province, Thailand"] = {},
	["Phitsanulok Province, Thailand"] = {},
	["Phra Nakhon Si Ayutthaya Province, Thailand"] = {},
	["Phrae Province, Thailand"] = {},
	["Phuket Province, Thailand"] = {},
	["Prachinburi Province, Thailand"] = {},
	["Prachuap Khiri Khan Province, Thailand"] = {},
	["Ranong Province, Thailand"] = {},
	["Ratchaburi Province, Thailand"] = {},
	["Rayong Province, Thailand"] = {},
	["Roi Et Province, Thailand"] = {},
	["Sa Kaeo Province, Thailand"] = {},
	["Sakon Nakhon Province, Thailand"] = {},
	["Samut Prakan Province, Thailand"] = {},
	["Samut Sakhon Province, Thailand"] = {},
	["Samut Songkhram Province, Thailand"] = {},
	["Saraburi Province, Thailand"] = {},
	["Satun Province, Thailand"] = {},
	["Sing Buri Province, Thailand"] = {},
	["Sisaket Province, Thailand"] = {},
	["Songkhla Province, Thailand"] = {},
	["Sukhothai Province, Thailand"] = {},
	["Suphan Buri Province, Thailand"] = {},
	["Surat Thani Province, Thailand"] = {},
	["Surin Province, Thailand"] = {},
	["Tak Province, Thailand"] = {},
	["Trang Province, Thailand"] = {},
	["Trat Province, Thailand"] = {},
	["Ubon Ratchathani Province, Thailand"] = {},
	["Udon Thani Province, Thailand"] = {},
	["Uthai Thani Province, Thailand"] = {},
	["Uttaradit Province, Thailand"] = {},
	["Yala Province, Thailand"] = {},
	["Yasothon Province, Thailand"] = {},
}

-- provinces of Thailand
export.thailand_group = {
	key_to_placename = make_key_to_placename(", Thailand$", " Province$"),
	placename_to_key = make_placename_to_key(", Thailand", " Province"),
	default_container = "Thailand",
	default_divtype = "province",
	default_poldiv = "districts",
	data = export.thailand_provinces,
}

export.united_kingdom_constituent_countries = {
	["England"] = {poldiv = {
		"counties",
		"districts",
		{type = "local government districts", cat_as = "districts"},
		{
			type = "local government districts with borough status",
			cat_as = {"districts", "boroughs"},
		},
		{type = "boroughs", cat_as = {"districts", "boroughs"}},
		{type = "civil parishes", skip_polity_parent_type = false},
	}},
	["Northern Ireland"] = {
		divtype = {"province", "constituent country", "country"},
		div_parent_type = "constituent countries",
		poldiv = {"counties", "districts"},
	},
	["Scotland"] = {
		poldiv = {{type = "council areas", skip_polity_parent_type = false}},
		miscdiv = {
			"districts",
			"traditional counties",
			{type = "historical counties", cat_as = "traditional counties"},
		}},
	["Wales"] = {poldiv = {
		"counties",
		{type = "county boroughs", skip_polity_parent_type = false},
		{type = "communities", skip_polity_parent_type = false},
		{type = "Welsh communities", cat_as = {{type = "communities", skip_polity_parent_type = false}}},
	}},
}

-- constituent countries and provinces of the United Kingdom
export.united_kingdom_group = {
	default_container = "United Kingdom",
	default_divtype = {"constituent country", "country"},
	default_miscdiv = {
		"traditional counties",
		{type = "historical counties", cat_as = "traditional counties"},
	},
	default_british_spelling = true,
	-- Don't create categories like 'Category:en:Towns in the United Kingdom'
	-- or 'Category:en:Places in the United Kingdom'.
	default_no_container_cat = true,
	data = export.united_kingdom_constituent_countries,
}

export.england_counties = {
	-- ["Avon, England"] = {}, -- no longer
	["Bedfordshire, England"] = {},
	["Berkshire, England"] = {},
	-- ["Brighton and Hove, England"] = {}, -- city
	-- ["Bristol, England"] = {}, -- city
	["Buckinghamshire, England"] = {},
	["Cambridgeshire, England"] = {},
	-- ["Cambridgeshire and Isle of Ely, England"] = {}, -- no longer
	["Cheshire, England"] = {},
	-- ["Cleveland, England"] = {}, -- no longer
	["Cornwall, England"] = {},
	-- ["Cumberland, England"] = {}, -- no longer
	["Cumbria, England"] = {},
	["Derbyshire, England"] = {},
	["Devon, England"] = {},
	["Dorset, England"] = {},
	["County Durham, England"] = {},
	-- ["East Suffolk, England"] = {}, -- no longer
	["East Sussex, England"] = {},
	["Essex, England"] = {},
	["Gloucestershire, England"] = {},
	["Greater London, England"] = {},
	["Greater Manchester, England"] = {},
	["Hampshire, England"] = {},
	-- ["Hereford and Worcester, England"] = {}, -- no longer
	["Herefordshire, England"] = {}, 
	["Hertfordshire, England"] = {},
	-- ["Humberside, England"] = {}, -- no longer
	-- ["Huntingdon and Peterborough, England"] = {}, -- no longer
	-- ["Huntingdonshire, England"] = {}, -- no longer
	-- ["Isle of Ely, England"] = {the = true}, -- no longer
	["Isle of Wight, England"] = {the = true},
	["Kent, England"] = {},
	["Lancashire, England"] = {},
	["Leicestershire, England"] = {},
	["Lincolnshire, England"] = {},
	-- ["County of London, England"] = {the = true}, -- no longer
	["Merseyside, England"] = {},
	-- ["Middlesex, England"] = {}, -- no longer
	["Norfolk, England"] = {},
	["Northamptonshire, England"] = {},
	["Northumberland, England"] = {},
	-- ["North Humberside, England"] = {}, -- no longer
	["North Yorkshire, England"] = {},
	["Nottinghamshire, England"] = {},
	["Oxfordshire, England"] = {},
	-- ["Soke of Peterborough, England"] = {the = true}, -- no longer
	["Rutland, England"] = {},
	["Shropshire, England"] = {},
	["Somerset, England"] = {},
	["South Humberside, England"] = {},
	["South Yorkshire, England"] = {},
	["Staffordshire, England"] = {},
	["Suffolk, England"] = {},
	["Surrey, England"] = {},
	-- ["Sussex, England"] = {}, -- no longer
	["Tyne and Wear, England"] = {},
	["Warwickshire, England"] = {},
	["West Midlands, England"] = {the = true},
	-- ["Westmorland, England"] = {}, -- no longer
	-- ["West Suffolk, England"] = {}, -- no longer
	["West Sussex, England"] = {},
	["West Yorkshire, England"] = {},
	["Wiltshire, England"] = {},
	["Worcestershire, England"] = {},
	-- ["Yorkshire, England"] = {}, -- no longer
	["East Riding of Yorkshire, England"] = {the = true},
	-- ["North Riding of Yorkshire, England"] = {the = true}, -- no longer
	-- ["West Riding of Yorkshire, England"] = {the = true}, -- no longer
}

-- counties of England
export.england_group = {
	key_to_placename = make_key_to_placename(", England$"),
	placename_to_key = make_placename_to_key(", England"),
	default_container = {name = "England", divtype = "constituent country"},
	default_divtype = "county",
	default_poldiv = {
		"districts",
		{type = "local government districts", cat_as = "districts"},
		{
			type = "local government districts with borough status",
			cat_as = {"districts", "boroughs"},
		},
		{type = "boroughs", cat_as = {"districts", "boroughs"}},
		"civil parishes",
	},
	default_british_spelling = true,
	data = export.england_counties,
}

export.northern_ireland_counties = {
	["County Antrim, Northern Ireland"] = {},
	["County Armagh, Northern Ireland"] = {},
	["City of Belfast, Northern Ireland"] = {the = true, is_city = true},
	["County Down, Northern Ireland"] = {},
	["County Fermanagh, Northern Ireland"] = {},
	["County Londonderry, Northern Ireland"] = {},
	["City of Derry, Northern Ireland"] = {the = true, is_city = true},
	["County Tyrone, Northern Ireland"] = {},
}

-- counties of Northern Ireland
export.northern_ireland_group = {
	key_to_placename = make_irish_type_key_to_placename(", Northern Ireland$"),
	placename_to_key = make_irish_type_placename_to_key(", Northern Ireland"),
	default_container = {name = "Northern Ireland", divtype = "constituent country"},
	default_divtype = "county",
	default_british_spelling = true,
	data = export.northern_ireland_counties,
}

export.scotland_council_areas = {
	["City of Glasgow, Scotland"] = {the = true},
	["City of Edinburgh, Scotland"] = {the = true},
	["Fife, Scotland"] = {},
	["North Lanarkshire, Scotland"] = {},
	["South Lanarkshire, Scotland"] = {},
	["Aberdeenshire, Scotland"] = {},
	["Highland, Scotland"] = {},
	["City of Aberdeen, Scotland"] = {the = true},
	["West Lothian, Scotland"] = {},
	["Renfrewshire, Scotland"] = {},
	["Falkirk, Scotland"] = {},
	["Perth and Kinross, Scotland"] = {},
	["Dumfries and Galloway, Scotland"] = {},
	["City of Dundee, Scotland"] = {the = true},
	["North Ayrshire, Scotland"] = {},
	["East Ayrshire, Scotland"] = {},
	["Angus, Scotland"] = {},
	["Scottish Borders, Scotland"] = {the = true},
	["South Ayrshire, Scotland"] = {},
	["East Dunbartonshire, Scotland"] = {},
	["East Lothian, Scotland"] = {},
	["Moray, Scotland"] = {},
	["East Renfrewshire, Scotland"] = {},
	["Stirling, Scotland"] = {},
	["Midlothian, Scotland"] = {},
	["West Dunbartonshire, Scotland"] = {},
	["Argyll and Bute, Scotland"] = {},
	["Inverclyde, Scotland"] = {},
	["Clackmannanshire, Scotland"] = {},
	["Na h-Eileanan Siar, Scotland"] = {},
	["Shetland Islands, Scotland"] = {the = true},
	["Orkney Islands, Scotland"] = {the = true},
}

-- council areas of Scotland
export.scotland_group = {
	key_to_placename = make_key_to_placename(", Scotland$"),
	placename_to_key = make_placename_to_key(", Scotland"),
	default_container = {name = "Scotland", divtype = "constituent country"},
	default_divtype = "council area",
	default_british_spelling = true,
	data = export.scotland_council_areas,
}

export.wales_principal_areas = {
	["Blaenau Gwent, Wales"] = {},
	["Bridgend, Wales"] = {},
	["Caerphilly, Wales"] = {},
	-- ["Cardiff, Wales"] = {divtype = "city"},
	["Carmarthenshire, Wales"] = {divtype = "county"},
	["Ceredigion, Wales"] = {divtype = "county"},
	["Conwy, Wales"] = {},
	["Denbighshire, Wales"] = {divtype = "county"},
	["Flintshire, Wales"] = {divtype = "county"},
	["Gwynedd, Wales"] = {divtype = "county"},
	["Isle of Anglesey, Wales"] = {the = true, divtype = "county"},
	["Merthyr Tydfil, Wales"] = {},
	["Monmouthshire, Wales"] = {divtype = "county"},
	["Neath Port Talbot, Wales"] = {},
	-- ["Newport, Wales"] = {divtype = "city"},
	["Pembrokeshire, Wales"] = {divtype = "county"},
	["Powys, Wales"] = {divtype = "county"},
	["Rhondda Cynon Taf, Wales"] = {},
	-- ["Swansea, Wales"] = {divtype = "city"},
	["Torfaen, Wales"] = {},
	["Vale of Glamorgan, Wales"] = {the = true},
	["Wrexham, Wales"] = {},
}

-- principal areas (cities, counties and county boroughs) of Wales
export.wales_group = {
	key_to_placename = make_key_to_placename(", Wales$"),
	placename_to_key = make_placename_to_key(", Wales"),
	default_container = {name = "Wales", divtype = "constituent country"},
	default_divtype = "county borough",
	default_british_spelling = true,
	data = export.wales_principal_areas,
}

export.united_states_states = {
	["Alabama, USA"] = {},
	["Alaska, USA"] = {poldiv = {
		{type = "boroughs", skip_polity_parent_type = "counties"},
		{type = "borough seats", skip_polity_parent_type = "county seats"},
	}},
	["Arizona, USA"] = {},
	["Arkansas, USA"] = {},
	["California, USA"] = {},
	["Colorado, USA"] = {poldiv = {"counties", "county seats", "municipalities"}},
	["Connecticut, USA"] = {poldiv = {"counties", "county seats", "municipalities"}},
	["Delaware, USA"] = {},
	["Florida, USA"] = {},
	["Georgia, USA"] = {},
	["Hawaii, USA"] = {addl_parents = "Polynesia"},
	["Idaho, USA"] = {},
	["Illinois, USA"] = {},
	["Indiana, USA"] = {},
	["Iowa, USA"] = {},
	["Kansas, USA"] = {},
	["Kentucky, USA"] = {},
	["Louisiana, USA"] = {poldiv = {
		{type = "parishes", skip_polity_parent_type = "counties"},
		{type = "parish seats", skip_polity_parent_type = "county seats"},
	}},
	["Maine, USA"] = {},
	["Maryland, USA"] = {},
	["Massachusetts, USA"] = {},
	["Michigan, USA"] = {},
	["Minnesota, USA"] = {},
	["Mississippi, USA"] = {},
	["Missouri, USA"] = {},
	["Montana, USA"] = {},
	["Nebraska, USA"] = {},
	["Nevada, USA"] = {},
	["New Hampshire, USA"] = {},
	["New Jersey, USA"] = {poldiv = {
		"counties", "county seats",
		{type = "boroughs", prep = "in"},
	}},
	["New Mexico, USA"] = {},
	["New York, USA"] = {},
	["North Carolina, USA"] = {},
	["North Dakota, USA"] = {},
	["Ohio, USA"] = {},
	["Oklahoma, USA"] = {},
	["Oregon, USA"] = {},
	["Pennsylvania, USA"] = {poldiv = {
		"counties", "county seats",
		{type = "boroughs", prep = "in"},
	}},
	["Rhode Island, USA"] = {},
	["South Carolina, USA"] = {},
	["South Dakota, USA"] = {},
	["Tennessee, USA"] = {},
	["Texas, USA"] = {},
	["Utah, USA"] = {},
	["Vermont, USA"] = {},
	["Virginia, USA"] = {},
	["Washington, USA"] = {},
	["West Virginia, USA"] = {},
	["Wisconsin, USA"] = {},
	["Wyoming, USA"] = {},
}

-- states of the United States
export.united_states_group = {
	key_to_placename = make_key_to_placename(", USA$"),
	placename_to_key = make_placename_to_key(", USA"),
	default_container = "United States",
	default_divtype = "state",
	default_poldiv = {
		"counties",
		"county seats",
	},
	default_miscdiv = {
		{type = "census-designated places", prep = "in"},
		{type = "unincorporated communities", prep = "in"},
	},
	data = export.united_states_states,
}

-----------------------------------------------------------------------------------
--                                     City tables                               --
-----------------------------------------------------------------------------------

--[==[
City data.

Each entry in `export.cities` is a group of cities under a single overarching containing polity (typically a country).
Each group contains the following fields:

* `default_container`: A containing polity spec or list of such specs, giving the overarching containing polity or
  polities (normally top-level) that all cities in the group belong to. Containing polity specs are described below
  for the immediate containing polity (under the `data` field below). Generally the overarching `containers`
  field of the group contains a single polity in the table format (so that the divtype can be given), but in some cases
  it is an empty list.
* `default_divtype`: The default divtype (in the singlar) of the immediate containing polity of the city (normally a
  political division of the overarching containing polity in `containers`).
* `wp`: The default value of the Wikipedia spec describing how to construct the Wikipedia article for the city. Each
  spec is either `true` (use the city key directly) or a string containing formatting directives, indicating how to
  construct the article name. The allowed formatting directives are `%c` (the city key) and `%d` (the immediate
  containing polity). For example, the value of `wp` for the group of United States cities is {"%c, %d"} since the
  city articles tend to be named e.g. `Austin, Texas` (but with many exceptions, specified using `wp` fields at the
  city level). The default is `true`.
* `data`: A tabel specifying the actual cities. This is a key-value table, in which the keys are ''city keys'' as they
  appear in categories (possibly including the preceding word {"the"} in the same circumstances as when a containing
  polity like {"the United States"} has it, but there appear to be no such cities; there are a few, such as `The Hague`,
  but in this case the word {"The"} is capitalized because it is an inherent part of the city name and can never be
  omitted; a true example is the Gold Coast, Australia). The value is a ''city spec'' describing the city, with the
  following fields:
** `parents`: 
  . in  containing polity spec or list of such specs, where each spec
  is either a string naming a containing polity or a containing polity table spec. The latter is a table of the format
  `{"CONTAINING-POLITY", divtype = "DIVTYPE", wp = "WP-SPEC", wpcat = "WP-SPEC", commonscat = "WP-SPEC"}`. In this
  table, `divtype` is the type of the containing polity (in the singular), defaulting to `default_divtype` at the
  group level; see above. `wp` is a spec describing how to construct the Wikipedia article for the city in the format
  described above for the `wp` field at the group level, which supplies its default. `wpcat` similarly describes how to
  construct the Wikipedia category article. It has the same format but rarely needs to be given because it defaults to
  the computed `wp` value, which is almost always correct. `commonscat` similarly describes how to construct the Commons
  category article, in the same format. It defaults to the computed `wpcat` value, which is usually but not always
  correct.
]==]
export.australia_cities = {
	["Adelaide"] = {container = "South Australia"},
	["Brisbane"] = {container = "Queensland"},
	["Canberra"] = {container = {name = "Australian Capital Territory, Australia", divtype = "territory"}},
	["Melbourne"] = {container = "Victoria"},
	["Newcastle, New South Wales"] = {container = "New South Wales"},
	["Newcastle"] = {alias_of = "Newcastle, New South Wales"},
	["Perth"] = {container = "Western Australia"},
	["Sydney"] = {container = "New South Wales"},
}

export.australia_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Australia", "state"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.australia_cities,
}

export.brazil_cities = {
	-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
	["São Paulo"] = {container = "São Paulo"},
	["Rio de Janeiro"] = {container = "Rio de Janeiro"},
	["Brasília"] = {container = "Distrito Federal"},
	["Brasilia"] = {alias_of = "Brasília"},
	["Salvador"] = {container = "Bahia", wp = "%c, %d", commonscat = "%c (%d)"},
	["Fortaleza"] = {container = "Ceará"},
	["Belo Horizonte"] = {container = "Minas Gerais"},
	["Manaus"] = {container = "Amazonas"},
	["Curitiba"] = {container = "Paraná"},
	["Recife"] = {container = "Pernambuco"},
	["Goiânia"] = {container = "Goiás"},
	["Goiania"] = {alias_of = "Goiânia"},
	["Belém"] = {container = "Pará"},
	["Belem"] = {alias_of = "Belém"},
	["Porto Alegre"] = {container = "Rio Grande do Sul"},
}

export.brazil_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Brazil", "state"),
	default_divtype = "city",
	data = export.brazil_cities,
}

export.canada_cities = {
	["Toronto"] = {container = "Ontario"},
	["Montreal"] = {container = "Quebec"},
	["Vancouver"] = {container = "British Columbia"},
	["Calgary"] = {container = "Alberta"},
	["Edmonton"] = {container = "Alberta"},
	["Ottawa"] = {container = "Ontario"},
	["Winnipeg"] = {container = "Manitoba"},
	["Quebec City"] = {container = "Quebec"},
	["Hamilton"] = {container = "Ontario", wp = "%c, %d"},
	["Kitchener"] = {container = "Ontario", wp = "%c, %d"},
}

export.canada_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Canada", "province"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.canada_cities,
}

export.france_cities = {
	["Paris"] = {container = "Île-de-France"},
	["Lyon"] = {container = "Auvergne-Rhône-Alpes"},
	["Lyons"] = {alias_of = "Lyon"},
	["Marseille"] = {container = "Provence-Alpes-Côte d'Azur"},
	["Marseilles"] = {alias_of = "Marseille"},
	["Toulouse"] = {container = "Occitania"},
	["Lille"] = {container = "Hauts-de-France"},
	["Bordeaux"] = {container = "Nouvelle-Aquitaine"},
	["Nice"] = {container = "Provence-Alpes-Côte d'Azur"},
	["Nantes"] = {container = "Pays de la Loire"},
	["Strasbourg"] = {container = "Grand Est"},
	["Rennes"] = {container = "Brittany"},
},

export.france_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", France", "administrative region"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.france_cities,
}

export.germany_cities = {
	["Berlin"] = {},
	["Dortmund"] = {container = "North Rhine-Westphalia"},
	["Essen"] = {container = "North Rhine-Westphalia"},
	["Duisberg"] = {container = "North Rhine-Westphalia"},
	["Hamburg"] = {},
	["Munich"] = {container = "Bavaria"},
	["Stuttgart"] = {container = "Baden-Württemberg"},
	["Frankfurt"] = {container = "Hesse"},
	["Cologne"] = {container = "North Rhine-Westphalia"},
	["Düsseldorf"] = {container = "North Rhine-Westphalia"},
	["Dusseldorf"] = {alias_of = "Düsseldorf"},
	["Nuremberg"] = {container = "Bavaria"},
	["Bremen"] = {},
}

export.germany_cities_group = {
	default_container = "Germany",
	canonicalize_key_container = make_canonicalize_key_container(", Germany", "state"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.germany_cities,
}

export.india_cities = {
	-- This lists the 65 metro areas per Demographia's 2023 estimates, as found in
	-- [[w:List_of_million-plus_urban_agglomerations_in_India]]. The last census in India (as of April 2025) was
	-- conducted in 2011, and the results are not accurate any more.
	["Delhi"] = {container = {name = "Delhi", divtype = "union territory"}}, -- 31,190,000
	["Mumbai"] = {container = "Maharashtra"}, -- 25,189,000
	["Kolkata"] = {container = "West Bengal"}, -- 21,747,000
	["Bangalore"] = {container = "Karnataka"}, -- 15,257,000
	["Bengaluru"] = {alias_of = "Bangalore"},
	["Chennai"] = {container = "Tamil Nadu"}, -- 11,570,000
	["Hyderabad"] = {container = "Telangana"}, -- 9,797,000
	["Ahmedabad"] = {container = "Gujarat"}, -- 8,006,000
	["Pune"] = {container = "Maharashtra"}, -- 6,819,000
	["Surat"] = {container = "Gujarat"}, -- 6,601,000
	["Lucknow"] = {container = "Uttar Pradesh"}, -- 4,661,000
	["Jaipur"] = {container = "Rajasthan"}, -- 4,360,000
	["Kanpur"] = {container = "Uttar Pradesh"}, -- 4,350,000
	["Indore"] = {container = "Madhya Pradesh"}, -- 3,765,000
	["Nagpur"] = {container = "Maharashtra"}, -- 3,493,000
	["Patna"] = {container = "Bihar"}, -- 3,331,000
	["Varanasi"] = {container = "Uttar Pradesh"}, -- 3,229,000
	["Kozhikode"] = {container = "Kerala"}, -- 3,049,000
	["Thiruvananthapuram"] = {container = "Kerala"}, -- 2,851,000
	["Agra"] = {container = "Uttar Pradesh"}, -- 2,737,000
	["Bhopal"] = {container = "Madhya Pradesh"}, -- 2,562,000
	["Coimbatore"] = {container = "Tamil Nadu"}, -- 2,551,000
	["Allahabad"] = {container = "Uttar Pradesh"}, -- 2,438,000
	["Prayagraj"] = {alias_of = "Allahabad"},
	["Kochi"] = {container = "Kerala"}, -- 2,381,000
	["Ludhiana"] = {container = "Punjab"}, -- 2,205,000
	["Vadodara"] = {container = "Gujarat"}, -- 2,182,000
	["Chandigarh"] = {container = {name = "Chandigarh", divtype = "union territory"}}, -- 2,168,000
	["Madurai"] = {container = "Tamil Nadu"}, -- 2,048,000
	["Meerut"] = {container = "Uttar Pradesh"}, -- 2,011,000
	["Visakhapatnam"] = {container = "Andhra Pradesh"}, -- 2,005,000
	["Jamshedpur"] = {container = "Jharkhand"}, -- 1,925,000
	["Malappuram"] = {container = "Kerala"}, -- 1,868,000
	["Nashik"] = {container = "Maharashtra"}, -- 1,810,000
	["Asansol"] = {container = "West Bengal"}, -- 1,720,000
	["Aligarh"] = {container = "Uttar Pradesh"}, -- 1,660,000
	["Ranchi"] = {container = "Jharkhand"}, -- 1,638,000
	["Thrissur"] = {container = "Kerala"}, -- 1,578,000
	["Kollam"] = {container = "Kerala"}, -- 1,576,000
	["Jabalpur"] = {container = "Madhya Pradesh"}, -- 1,533,000
	["Dhanbad"] = {container = "Jharkhand"}, -- 1,503,000
	["Jodhpur"] = {container = "Rajasthan"}, -- 1,497,000
	["Aurangabad"] = {container = "Maharashtra"}, -- 1,490,000
	["Chhatrapati Sambhajinagar"] = {alias_of = "Aurangabad"},
	["Rajkot"] = {container = "Gujarat"}, -- 1,487,000
	["Gwalior"] = {container = "Madhya Pradesh"}, -- 1,477,000
	["Raipur"] = {container = "Chhattisgarh"}, -- 1,429,000
	["Gorakhpur"] = {container = "Uttar Pradesh"}, -- 1,410,000
	["Kannur"] = {container = "Kerala"}, -- 1,360,000
	["Bareilly"] = {container = "Uttar Pradesh"}, -- 1,355,000
	["Guwahati"] = {container = "Assam"}, -- 1,355,000
	["Moradabad"] = {container = "Uttar Pradesh"}, -- 1,345,000
	["Amritsar"] = {container = "Punjab"}, -- 1,313,000
	["Mysore"] = {container = "Karnataka"}, -- 1,296,000
	["Bhilai"] = {container = "Chhattisgarh"}, -- 1,293,000
	["Durg-Bhilainagar"] = {alias_of = "Bhilai"},
	["Durg-Bhilai"] = {alias_of = "Bhilai"},
	["Durg"] = {alias_of = "Bhilai"},
	["Bhilainagar"] = {alias_of = "Bhilai"},
	["Vijayawada"] = {container = "Andhra Pradesh"}, -- 1,232,000
	["Srinagar"] = {container = {name = "Jammu and Kashmir", divtype = "union territory"}}, -- 1,212,000
	["Salem"] = {container = "Tamil Nadu"}, -- 1,189,000
	["Kota"] = {container = "Rajasthan"}, -- 1,172,000
	["Jalandhar"] = {container = "Punjab"}, -- 1,165,000
	["Saharanpur"] = {container = "Uttar Pradesh"}, -- 1,152,000
	["Dehradun"] = {container = "Uttarakhand"}, -- 1,136,000
	["Tiruchirappalli"] = {container = "Tamil Nadu"}, -- 1,131,000
	["Bhubaneswar"] = {container = "Odisha"}, -- 1,112,000
	["Jammu"] = {container = {name = "Jammu and Kashmir", divtype = "union territory"}}, -- 1,103,000
	["Solapur"] = {container = "Maharashtra"}, -- 1,082,000
	["Hubli-Dharwad"] = {container = "Karnataka"}, -- 1,062,000
	["Hubli"] = {alias-of = "Hubli-Dharwad"},
	["Dharwad"] = {alias-of = "Hubli-Dharwad"},
	["Puducherry"] = {container = {name = "Puducherry", divtype = "union territory"}}, -- 1,024,000
}

export.india_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", India", "state"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.india_cities,
}

export.indonesia_cities = {
	-- cities where the city proper has more than 1,000,000 people as of mid-2023 estimate
	["Jakarta"] = {container = "Special Capital Region of Jakarta"},
	["Surabaya"] = {container = "East Java"},
	["Bekasi"] = {container = "West Java"}, -- part of Jakarta metro area
	["Bandung"] = {container = "West Java"},
	["Medan"] = {container = "North Sumatra"},
	["Depok"] = {container = "West Java"}, -- part of Jakarta metro area
	["Tangerang"] = {container = "Banten"}, -- part of Jakarta metro area
	["Palembang"] = {container = "South Sumatra"},
	["Semarang"] = {container = "Central Java"},
	["Makassar"] = {container = "South Sulawesi"},
	["South Tangerang"] = {container = "Banten"}, -- part of Jakarta metro area
	["Batam"] = {container = "Riau Islands"},
	["Bogor"] = {container = "West Java"}, -- part of Jakarta metro area
	["Pekanbaru"] = {container = "Riau"},
	["Bandar Lampung"] = {container = "Lampung"},
	["Pekanbaru"] = {container = "Riau"},
	-- other metro areas over 1,000,000 people
	["Padang"] = {container = "West Sumatra"},
	["Samarinda"] = {container = "East Kalimantan"},
	["Malang"] = {container = "East Java"},
	["Yogyakarta"] = {container = "Special Region of Yogyakarta"},
	["Denpasar"] = {container = "Bali"},
	["Cirebon"] = {container = "West Java"},
	["Surakarta"] = {container = "Central Java"},
	["Banjarmasin"] = {container = "South Kalimantan"},
	["Tasikmalaya"] = {parent = "West Java"},
}

export.indonesia_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Indonesia", "province"),
	default_divtype = "city",
	data = export.indonesia_cities,
}

export.japan_cities = {
	-- Population figures from [[w:List of cities in Japan]]. Metro areas from
	-- [[w:List of metropolitan areas in Japan]].
	["Tokyo"] = {}, -- no single figure given for Tokyo as a whole.
	["Yokohama"] = {container = "Kanagawa"}, -- 3,697,894
	["Osaka"] = {container = "Osaka"}, -- 2,668,586
	["Nagoya"] = {container = "Aichi"}, -- 2,283,289
	-- FIXME, Hokkaido is handled specially.
	["Sapporo"] = {container = "Hokkaido"}, -- 1,918,096
	["Fukuoka"] = {container = "Fukuoka"}, -- 1,581,527
	["Kobe"] = {container = "Hyōgo"}, -- 1,530,847
	["Kyoto"] = {container = "Kyoto"}, -- 1,474,570
	["Kawasaki"] = {container = "Kanagawa", wp = "%c, %d"}, -- 1,373,630
	["Saitama"] = {container = "Saitama", wp = "%c (city)", commonscat = "%c, %d"}, -- 1,192,418
	["Hiroshima"] = {container = "Hiroshima"}, -- 1,163,806
	["Sendai"] = {container = "Miyagi"}, -- 1,029,552
	-- the remaining cities are considered "central cities" in a 1,000,000+ metro area
	-- (sometimes there is more than one central city in the area).
	["Kitakyushu"] = {container = "Fukuoka"}, -- 986,998
	["Chiba"] = {container = "Chiba", wp = "%c (city)", commonscat = "%c, %d"}, -- 938,695
	["Sakai"] = {container = "Osaka"}, -- 835,333
	["Niigata"] = {container = "Niigata", wp = "%c (city)", commonscat = "%c, %d"}, -- 813,053
	["Hamamatsu"] = {container = "Shizuoka"}, -- 811,431
	["Shizuoka"] = {container = "Shizuoka", wp = "%c (city)", commonscat = "%c, %d"}, -- 710,944
	["Sagamihara"] = {container = "Kanagawa"}, -- 706,342
	["Okayama"] = {container = "Okayama"}, -- 701,293
	["Kumamoto"] = {container = "Kumamoto"}, -- 670,348
	["Kagoshima"] = {container = "Kagoshima"}, -- 605,196
	-- skipped 6 cities (Funabashi, Hachiōji, Kawaguchi, Himeji, Matsuyama, Higashiōsaka)
	-- with population in the range 509k - 587k because not central cities in any
	-- 1,000,000+ metro area.
	["Utsunomiya"] = {container = "Tochigi"}, -- 507,833
}

export.japan_cities_group = {
	default_container = "Japan",
	canonicalize_key_container = make_canonicalize_key_container(", Japan", "prefecture"),
	default_divtype = "city",
	data = export.japan_cities,
}

export.south_korea_cities = {
	-- All cities listed are not associated with any province.
	["Seoul"] = {},
	["Busan"] = {},
	["Incheon"] = {},
	["Daegu"] = {},
	["Daejeon"] = {},
	["Gwangju"] = {},
	["Ulsan"] = {},
}

export.south_korea_cities_group = {
	default_container = "South Korea",
	canonicalize_key_container = make_canonicalize_key_container(", South Korea", "province"),
	default_divtype = "city",
	data = export.south_korea_cities,
}

export.mexico_cities = {
	["Mexico City"] = {}, -- its own state
	["Monterrey"] = {container = "Nuevo León"},
	["Guadalajara"] = {container = "Jalisco"},
	["Puebla"] = {container = "Puebla"},
	["Toluca"] = {container = "State of Mexico"},
	["Tijuana"] = {container = "Baja California"},
	-- Include the state in the category for León due to possible confusion with León, Spain.
	["León, Guanajuato"] = {container = "Guanajuato"},
	["León"] = {alias_of = "León, Guanajuato"},
	["Leon"] = {alias_of = "León, Guanajuato"},
	["Querétaro"] = {container = "Querétaro"},
	["Queretaro"] = {alias_of = "Querétaro"},
	["Ciudad Juárez"] = {container = "Chihuahua"},
	["Juárez"] = {alias_of = "Ciudad Juárez"},
	["Juarez"] = {alias_of = "Ciudad Juárez"},
	["Torreón"] = {container = "Coahuila"},
	["Torreon"] = {alias_of = "Torreón"},
	["Mérida"] = {container = "Yucatán"},
	["Merida"] = {alias_of = "Mérida"},
	["San Luis Potosí"] = {container = "San Luis Potosí"},
	["San Luis Potosi"] = {alias_of = "San Luis Potosí"},
	["Aguascalientes"] = {container = "Aguascalientes"},
	["Mexicali"] = {container = "Baja California"},
}

export.mexico_cities_group = {
	default_container = "Mexico",
	canonicalize_key_container = make_canonicalize_key_container(", Mexico", "state"),
	default_divtype = "city",
	data = export.mexico_cities,
}

export.philippines_cities = {
	 -- Some cities listed independent from any province. province listed is for geographical purposes only.
	 -- Skipped some cities in Metro Manila (Taguig, Pasig) which don't have districts.
	 -- Other cities outside Metro Manila skipped as not central city in their urban area.
	["Quezon City"] = {container = {name = "Metro Manila", divtype = "region"}},
	["Quezon"] = {alias_of = "Quezon City"},
	["Manila"] = {container = {name = "Metro Manila", divtype = "region"}},
	["Davao City"] = {container = "Davao del Sur"},
	["Davao"] = {alias_of = "Davao City"},
	["Caloocan"] = {container = {name = "Metro Manila", divtype = "region"}},
	["Zamboanga City"] = {container = "Zamboanga del Sur"},
	["Zamboanga"] = {alias_of = "Zamboanga City"},
	["Cebu City"] = {container = "Cebu"},
	["Cebu"] = {alias_of = "Cebu City"},
	["Antipolo"] = {container = "Rizal"},
	["Cagayan de Oro"] = {container = "Misamis Oriental"},
	["Dasmariñas"] = {container = "Cavite"},
	["Dasmarinas"] = {alias_of = "Dasmariñas"},
	["General Santos"] = {container = "South Cotabato"},
	["San Jose del Monte"] = {container = "Bulacan"},
	["Bacolod"] = {container = "Negros Occidental"},
	["Calamba"] = {container = "Laguna"},
	["Angeles"] = {container = "Pampanga"},
	["Iloilo City"] = {container = "Iloilo"},
	["Iloilo"] = {alias_of = "Iloilo City"},
}

export.philippines_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Philippines", "province"),
	default_divtype = "city",
	data = export.philippines_cities,
}

export.russia_cities = {
	-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
	["Moscow"] = {},
	["Saint Petersburg"] = {},
	["Novosibirsk"] = {container = "Novosibirsk Oblast"},
	["Yekaterinburg"] = {container = "Sverdlovsk Oblast"},
	["Nizhny Novgorod"] = {container = "Nizhny Novgorod Oblast"},
	["Kazan"] = {container = {name = "Republic of Tatarstan", divtype = "republic"}},
	["Chelyabinsk"] = {container = "Chelyabinsk Oblast"},
	["Omsk"] = {container = "Omsk Oblast"},
	["Samara"] = {container = "Samara Oblast"},
	["Ufa"] = {container = {name = "Republic of Bashkortostan", divtype = "republic"}},
	["Rostov-on-Don"] = {container = "Rostov Oblast"},
	["Rostov-na-Donu"] = {alias_of = "Rostov-on-Don"},
	["Krasnoyarsk"] = {container = {name = "Krasnoyarsk Krai", divtype = "krai"}},
	["Voronezh"] = {container = "Voronezh Oblast"},
	["Perm"] = {container = {name = "Perm Krai", divtype = "krai"}, wp = "Perm, Russia"},
	["Volgograd"] = {container = "Volgograd Oblast"},
	["Krasnodar"] = {container = {name = "Krasnodar Krai", divtype = "krai"}},
}

export.russia_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(nil, "oblast"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.russia_cities,
}

export.italy_cities = {
	-- Data per [[w:List_of_metropolitan_areas_of_Italy]]. There are several lists given; the most recent one, used
	-- here, only gives estimates as of Jan 1, 2014.
	["Milan"] = {container = "Lombardy"}, -- 6,623,798
	["Naples"] = {container = "Campania"}, -- 5,294,546
	["Rome"] = {container = "Lazio"}, -- 4,447,881
	["Turin"] = {container = "Piedmont"}, -- 1,865,284
	["Venice"] = {container = "Veneto"}, -- 1,645,900
	["Florence"] = {container = "Tuscany"}, -- 1,485,030
	["Bari"] = {container = "Apulia"}, -- 1,257,459
	["Palermo"] = {container = "Sicily"}, -- 1,183,084
	-- include a few just below 1,000,000 metro area that may be above it by now (depending on the definition).
	["Catania"] = {container = "Sicily"}, -- 988,240
	["Brescia"] = {container = "Lombardy"}, -- 924,090
	["Genoa"] = {container = "Liguria"}, -- 861,318
}

export.italy_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Italy", "administrative region"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.italy_cities,
}

export.spain_cities = {
	["Madrid"] = {container = "Community of Madrid"},
	["Barcelona"] = {container = "Catalonia"},
	["Valencia"] = {container = "Valencia"},
	["Seville"] = {container = "Andalusia"},
	["Bilbao"] = {container = "Basque Country"},
}

export.spain_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Spain", "autonomous community"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.spain_cities,
}

export.taiwan_cities = {
	["New Taipei"] = {},
	["Taichung"] = {},
	["Kaohsiung"] = {wp = "%c, Taiwan"},
	["Taipei"] = {},
	["Taoyuan"] = {},
	["Tainan"] = {},
	["Chiayi"] = {},
	["Hsinchu"] = {},
	["Keelung"] = {},
}

export.taiwan_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Taiwan", "county"),
	default_divtype = "city",
	data = export.taiwan_cities,
}

-- NOTE: It's OK to mix cities from different constituent countries; as long as the immediate container is correct,
-- everything else will be figured out.
export.united_kingdom_cities = {
	["London"] = {container = "Greater London"},
	["Manchester"] = {container = "Greater Manchester"},
	["Birmingham"] = {container = "West Midlands"},
	["Liverpool"] = {container = "Merseyside"},
	["Glasgow"] = {container = {name = "City of Glasgow, Scotland", divtype = "council area"}},
	["Leeds"] = {container = "West Yorkshire"},
	["Newcastle upon Tyne"] = {container = "Tyne and Wear"},
	["Newcastle"] = {alias_of = "Newcastle upon Tyne"},
	["Bristol"] = {container = {name = "England", divtype = "constituent country"}},
	["Cardiff"] = {container = {name = "Wales", divtype = "constituent country"}},
	["Portsmouth"] = {container = "Hampshire"},
	["Edinburgh"] = {container = {name = "City of Edinburgh, Scotland", divtype = "council area"}},
	-- under 1,000,000 people but principal areas of Wales; requested by [[User:Donnanz]]
	["Swansea"] = {container = {name = "Wales", divtype = "constituent country"}},
	["Newport"] = {container = {name = "Wales", divtype = "constituent country"}, wp = "Newport, Wales"},
}

export.united_kingdom_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", England", "county"),
	default_divtype = "city",
	default_british_spelling = true,
	data = export.united_kingdom_cities,
}

export.united_states_cities = {
	-- top 50 CSA's by population, with the top and sometimes 2nd or 3rd city listed
	["New York City"] = {container = "New York", wp = "%c"},
	["New York"] = {alias_of = "New York City"},
	["Newark"] = {container = "New Jersey"},
	["Los Angeles"] = {container = "California", wp = "%c"},
	["Long Beach"] = {container = "California"},
	["Riverside"] = {container = "California"},
	["Chicago"] = {container = "Illinois", wp = "%c"},
	["Washington, D.C."] = {wp = "%c"},
	["Washington"] = {alias_of = "Washington, D.C."},
	["Baltimore"] = {container = "Maryland", wp = "%c"},
	["San Jose"] = {container = "California"},
	["San Francisco"] = {container = "California", wp = "%c"},
	["Oakland"] = {container = "California"},
	["Boston"] = {container = "Massachusetts", wp = "%c"},
	["Providence"] = {container = "Rhode Island"},
	["Dallas"] = {container = "Texas", wp = "%c", commonscat = "%c, %d"},
	["Fort Worth"] = {container = "Texas"},
	["Philadelphia"] = {container = "Pennsylvania", wp = "%c"},
	["Houston"] = {container = "Texas", wp = "%c"},
	["Miami"] = {container = "Florida", wp = "%c", commonscat = "%c, %d"},
	["Atlanta"] = {container = "Georgia", wp = "%c"},
	["Detroit"] = {container = "Michigan", wp = "%c"},
	["Phoenix"] = {container = "Arizona", wp = "%c", commonscat = "%c, %d"},
	["Mesa"] = {container = "Arizona"},
	["Seattle"] = {container = "Washington", wp = "%c"},
	["Orlando"] = {container = "Florida"},
	["Minneapolis"] = {container = "Minnesota", wp = "%c"},
	["Cleveland"] = {container = "Ohio", wp = "%c", commonscat = "%c, %d"},
	["Denver"] = {container = "Colorado", wp = "%c", commonscat = "%c, %d"},
	["San Diego"] = {container = "California", wp = "%c", commonscat = "%c, %d"},
	["Portland"] = {container = "Oregon"},
	["Tampa"] = {container = "Florida"},
	["St. Louis"] = {container = "Missouri", wp = "%c", commonscat = "%c, %d"},
	["Charlotte"] = {container = "North Carolina"},
	["Sacramento"] = {container = "California"},
	["Pittsburgh"] = {container = "Pennsylvania", wp = "%c"},
	["Salt Lake City"] = {container = "Utah", wp = "%c"},
	["San Antonio"] = {container = "Texas", wp = "%c", commonscat = "%c, %d"},
	["Columbus"] = {container = "Ohio"},
	["Kansas City"] = {container = "Missouri", wp = "%c metropolitan area", commonscat = "%c, %d"},
	["Indianapolis"] = {container = "Indiana", wp = "%c"},
	["Las Vegas"] = {container = "Nevada", wp = "%c"},
	["Cincinnati"] = {container = "Ohio", wp = "%c", commonscat = "%c, %d"},
	["Austin"] = {container = "Texas"},
	["Milwaukee"] = {container = "Wisconsin", wp = "%c", commonscat = "%c, %d"},
	["Raleigh"] = {container = "North Carolina"},
	["Nashville"] = {container = "Tennessee"},
	["Virginia Beach"] = {container = "Virginia"},
	["Norfolk"] = {container = "Virginia"},
	["Greensboro"] = {container = "North Carolina"},
	["Winston-Salem"] = {container = "North Carolina"},
	["Jacksonville"] = {container = "Florida"},
	["New Orleans"] = {container = "Louisiana", wp = "%c"},
	["Louisville"] = {container = "Kentucky"},
	["Greenville"] = {container = "South Carolina"},
	["Hartford"] = {container = "Connecticut"},
	["Oklahoma City"] = {container = "Oklahoma", wp = "%c"},
	["Grand Rapids"] = {container = "Michigan"},
	["Memphis"] = {container = "Tennessee"},
	["Birmingham"] = {container = "Alabama"},
	["Fresno"] = {container = "California"},
	["Richmond"] = {container = "Virginia"},
	["Harrisburg"] = {container = "Pennsylvania"},
	-- any major city of top 50 MSA's that's missed by previous
	["Buffalo"] = {container = "New York"},
	-- any of the top 50 city by city population that's missed by previous
	["El Paso"] = {container = "Texas"},
	["Albuquerque"] = {container = "New Mexico"},
	["Tucson"] = {container = "Arizona"},
	["Colorado Springs"] = {container = "Colorado"},
	["Omaha"] = {container = "Nebraska"},
	["Tulsa"] = {container = "Oklahoma"},
	-- skip Arlington, Texas; too obscure and likely to be interpreted as Arlington, Virginia
}

export.united_states_cities_group = {
	default_container = "United States",
	canonicalize_key_container = make_canonicalize_key_container(", USA", "state"),
	default_divtype = "city",
	default_wp = "%c, %d",
	data = export.united_states_cities,
}

export.new_york_boroughs = {
	["Bronx"] = {the = true, wp = "The Bronx"},
	["Brooklyn"] = {},
	["Manhattan"] = {},
	["Queens"] = {},
	["Staten Island"] = {},
}

export.new_york_boroughs_group = {
	default_container = {name = "New York City", divtype = "city"},
	default_divtype = "borough",
	data = export.new_york_boroughs,
}

export.misc_cities = {
	["Yerevan"] = {container = "Armenia"},
	["Vienna"] = {container = "Austria"},
	["Minsk"] = {container = "Belarus"},
	["Brussels"] = {container = "Belgium"},
	["Antwerp"] = {container = "Belgium"},
	["Sofia"] = {container = "Bulgaria"},
	["Zagreb"] = {container = "Croatia"},
	["Prague"] = {container = "Czech Republic"},
	["Olomouc"] = {container = "Czech Republic"},
	["Copenhagen"] = {container = "Denmark"},
	["Helsinki"] = {container = {name = "Uusimaa, Finland", divtype = "region"}},
	["Athens"] = {container = "Greece"},
	["Thessaloniki"] = {container = "Greece"},
	["Budapest"] = {container = "Hungary"},
	-- FIXME, per Wikipedia "County Dublin" is now the "Dublin Region"
	["Dublin"] = {container = {name = "County Dublin, Ireland", divtype = "county"}},
	-- Jerusalem is not recognized internationally as part of either Israel or Palestine, but as a
	-- [[w:corpus separatum]], so put the container as "Asia" and list Israel and Palestine as additional parents for
	-- categorization purposes.
	["Jerusalem"] = {container = {name = "Asia", divtype = "continent"}, addl_parents = {"Israel", "Palestine"}},
	["Tel Aviv"] = {container = "Israel"},
	["Riga"] = {container = "Latvia"},
	["Amsterdam"] = {container = {name = "North Holland, Netherlands", divtype = "province"}},
	["Rotterdam"] = {container = {name = "South Holland, Netherlands", divtype = "province"}},
	["The Hague"] = {container = {name = "South Holland, Netherlands", divtype = "province"}},
	["Auckland"] = {container = "New Zealand"},
	["Oslo"] = {container = {name = "Oslo, Norway", divtype = "county"}},
	["Warsaw"] = {container = "Poland"},
	["Katowice"] = {container = "Poland"},
	["Kraków"] = {container = "Poland"},
	["Krakow"] = {alias_of = "Kraków"},
	["Gdańsk"] = {container = "Poland"},
	["Gdansk"] = {alias_of = "Gdańsk"},
	["Poznań"] = {container = "Poland"},
	["Poznan"] = {alias_of = "Poznań"},
	["Łódź"] = {container = "Poland"},
	["Lodz"] = {alias_of = "Łódź"},
	["Lisbon"] = {container = "Portugal"},
	["Porto"] = {container = "Portugal"},
	["Bucharest"] = {container = "Romania"},
	["Belgrade"] = {container = "Serbia"},
	["Stockholm"] = {container = "Sweden"},
	["Zürich"] = {container = "Switzerland"},
	["Zurich"] = {alias_of = "Zürich"},
	["Istanbul"] = {container = "Turkey"},
	["Kyiv"] = {container = "Ukraine"},
	["Kiev"] = {alias_of = "Kyiv"},
	["Kharkiv"] = {container = "Ukraine"},
	["Odessa"] = {container = "Ukraine", wp = "Odesa"},
	["Odesa"] = {alias_of = "Odessa"},
}

export.misc_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(nil, "country"),
	default_divtype = "city",
	data = export.misc_cities,
}

-- List of all known locations. The first three groups list the properties of top-level polities: countries,
-- "country-like entities" (de-facto/unrecognized/etc. countries) and former countries. Most of the remainder list the
-- first-level subpolities (administrative divisions) of several, mostly large, countries, and their country-specific
-- and subpolity-specific properties. After that come groups of cities. China and the United Kingdom include
-- second-level subpolities (in the case of China, only the largest ones).
export.locations = {
	export.continents_group,
	export.countries_group,
	export.country_like_entities_group,
	export.former_countries_group,
	export.australia_group,
	export.austria_group,
	export.bangladesh_group,
	export.brazil_group,
	export.canada_group,
	export.china_group,
	export.china_prefecture_level_cities_group,
	export.finland_group,
	export.france_group,
	export.germany_group,
	export.india_group,
	export.indonesia_group,
	export.ireland_group,
	export.italy_group,
	export.japan_group,
	export.north_korea_group,
	export.south_korea_group,
	export.laos_group,
	export.lebanon_group,
	export.malaysia_group,
	export.malta_group,
	export.mexico_group,
	export.morocco_group,
	export.netherlands_group,
	export.nigeria_group,
	export.norway_group,
	export.pakistan_group,
	export.philippines_group,
	export.romania_group,
	export.russia_group,
	export.saudi_arabia_group,
	export.spain_group,
	export.taiwan_group,
	export.thailand_group,
	export.united_kingdom_group,
	export.united_states_group,
	export.england_group,
	export.northern_ireland_group,
	export.scotland_group,
	export.wales_group,
	export.australia_cities_group,
	export.brazil_cities_group,
	export.canada_cities_group,
	export.france_cities_group,
	export.germany_cities_group,
	export.india_cities_group,
	export.indonesia_cities_group,
	export.italy_cities_group,
	export.japan_cities_group,
	export.south_korea_cities_group,
	export.mexico_cities_group,
	export.philippines_cities_group,
	export.russia_cities_group,
	export.spain_cities_group,
	export.taiwan_cities_group,
	export.united_kingdom_cities_group,
	export.united_states_cities_group,
	export.new_york_boroughs_group,
	export.misc_cities_group,
}

return export
