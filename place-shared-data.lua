local export = {}
--[=[
This module contains data shared between [[Module:place/data]] and [[Module:category tree/topic cat/data/Places]].
You must load this module using require(), not using mw.loadData().
]=]

local m_table = require("Module:table")
local en_utilities_module = "Module:en-utilities"
local topic_cat_utilities_module = "Module:category tree/topic cat/utilities"

local dump = mw.dumpObject

--[==[ intro:

===Introduction===

This module contains lists of all the toponyms (continents, countries, country subdivisions such as states and
provinces, and cities) and their properties, along with some information about placetypes (the remainder is found in
[[Module:place/data]]). See [[Module:place]] for a general introduction to the terminology associated with places along
with a list of all the relevant modules, and the description below for more specific information on types of toponyms
and placetypes and how their categorization works.

The objects for which categories exist are as follows:
# Toponyms (named entities for specific regions of the earth). These consist of:
## Continents and continent-level regions. At the top-level below `Earth` is `America`, `Eurasia`, `Africa`, `Oceania`
   and `Antartica`, where `America` is further broken down into `North America` (in turn containing `Central America`)
   and `South America`; `Eurasia` is further broken down into `Europe` and `Asia`; and `Oceania` is further broken down
   into `Melanesia`, `Micronesia` and `Polynesia`, with `Australia` directly under `Oceania`. Under these divisions are
   countries. Some countries are placed in more than one continent or continent-level region, either because they
   actually span two continents etc. (e.g. Russia, Turkey, Kazakhstan, Egypt) or because they are politically considered
   to belong to a continent different from the one they are geographically in (Cyprus, Georgia, Armenia, etc.).
## Top-level polities. This includes:
### Countries, with a fairly liberal definition, notably including all UN-recognized countries plus some others that are
    commonly considered countries, even if not all other countries recognize them as such or consider them completely
	independent (notably, Kosovo, Palestine, Taiwan, Western Sahara, Niue and the Cook Islands).
### Pseudo-countries, which include areas calling themselves countries that are de-facto not under the control of the
    country that they are internationally considered part of (e.g. Abkhazia, South Ossetia, Transnistria);
	dependent/external/etc. territories of countries (e.g. American Samoa [US], Bermuda [UK], Christmas Island
	[Australia], Easter Island [Chile]); constituent countries, autonomous territories and the like (Aruba, Curaçao and
	Sint Maarten of the Netherlands; Greenland and the Faroe Islands of Denmark; etc.; but notably not including
	England, Scotland, Northern Ireland and Wales, which are treated as regular countries); and a grab bag of other
	entities that have a semi-independent existence, such as Hong Kong, Macau, Guadeloupe, Martinique and the like.
	Currently, the actual distinction in treatment between "countries" and "pseudo-countries" is minimal, but in the
	future we might restrict the sorts of subcategories of pseudo-countries more than non-pseudo-countries.
### Former countries, e.g. the Soviet Union, Yugoslavia, West Germany and the Roman Empire. These are much more limited
    in the sorts of subcategories allowed, because generally toponyms, especially cities, should be described from the
	perspective of where they are currently located ("an ancient Roman town in modern Lebanon, etc.") and categorized
	as such.
## Subpolities. Generally we only list top-level administrative divisions of countries, and even then we limit both the
   set of countries that get such lists and in some cases (e.g. England) the types of top-level administrative divisions
   that get listed.
## Cities. Only major cities get categories, with the definition of "major" varying by country but often including
   those where the city population itself (sometimes the metro area) is >= 1,000,000 people.
# Placetypes. This includes:
## Political subdivisions (states, provinces, counties, etc.).
## Non-political or "miscellaneous" subdivisions (such as divisions used for census purposes which are considered
   important enough to categorize).
## "Generic" placetypes that are likely to exist in every polity (cities, towns, villages, rivers, etc.).
## Meta-placetypes, specifically "place", which exists in every polity and is treated like a generic placetype.
# Types of toponyms, such as "polity" and "political subdivision".

There are two main types of categories:
# Categories for toponyms, divided into:
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
   categories, whose purpose is to contain toponyms of the specified type. "Immediate" here refers to the fact that
   the toponym in the category name is the immediately-containing polity. Usually these categories use the preposition
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

The parent categories of a given category depend on its type. Generally, toponym categories have placetype categories
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
  [[:Category:Political subdivisions of specific countries]]. (There is also a bare [[:Category:Political divisions]]
  that groups "bare placetype" categories.) Skip-polity placetype categories for second-level divisions of a country
  (e.g. [[:Category:Counties of the United States]]) work the same. Placetype categories for countries work likewise
  except they are missing the generic parent.


===Polity group and division tables===

The bulk of the data in this module (after some helper functions and placetype tables) describes the known polities,
subpolities and cities and their relationships. The main polity table is called `export.polities` and is a list of
''polity groups'', each of which describes a single polity or "pseudo-polity" and the top-level subdivisions of that
polity. The first few polity groups are devoted to countries themselves as well as ''country-like entities''
(unrecognized de-facto countries, dependent territories and other entities that we treat as top-level) and former
top-level polities. Each of these groups is considered to be collected under a "pseudo-polity" such as the
"countries" pseudo-polity for currently-existing countries.

FIXME: The following documentation is out of date.

====Polity group tables====

The following tables specify the known polities and their properties, where a polity is either a top-level political
division (e.g. a country) or a subpolity (political subdivision of a top-level polity). Polities are gathered into
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
   [[:Category:pt:Counties of Wales]], etc. These are for political subdivisions, and for historic/popular subdivisions
   that have no current political significance (e.g. [[:Category:nl:Provinces of Ireland]],
   [[:Category:zh:Regions of the United States]]). These are controlled by the `poldiv` (for political subdivisions) and
   `miscdiv` (for historic/popular subdivisions) keys in the data for a given item.

NOTE: Second-level political subdivisions (e.g. counties of states of the US) could be handled here but normally aren't.
Instead, there are special handlers below for US counties and Brazilian and Philippine municipalities, and
manually-created labels for certain other countries (e.g. Canadian counties). The reason for this is that all political
and historic/popular subdivisions handled here have a category like [[:Category:en:Political subdivisions]] as their
primary parent, whereas we often want a different primary parent for second-level political subdivisions, such as
[[:Category:en:Counties of the United States]] for US counties. FIXME: We should allow the parents to be specified for
political subdivisions. This will probably necessitate another type of group-specific handler, similar to
`value_transformer` and `bare_label_setter` (see below).

NOTE: Some of the above categories are added automatically to pages that use the {{tl|place}} template with the appropriate
values. Currently, whether or not such categories are added is controlled by [[Module:place/data]], which is independent
of the data here but in many ways duplicates it. FIXME: The two should be merged.

NOTE: There is also some duplication in [[Module:category tree/topic cat/data/Earth]], particularly for continents and
supranational regions (e.g. "the British Isles"). FIXME: Consolidate the data there into here.

Each group consists of a table with the following keys:

* `data`: This is a table listing the polities in the group. The keys are polities in the form that they appear in a
  category like [[:Category:de:Provinces of the Netherlands]] or [[:Category:fr:Cities in Alabama, USA]] (hence, they
  should include prefixes such as "the" and suffixes such as ", USA"). The value of a key is a property table. Its
  format is described above under "Placename Tables". Note that the property table is transformed using the group's
  `value_transformer` handler before being used.

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

* `value_transformer`: This function is used to transform the value of an item in `data` (an object containing
  properties of a place; see above) to the final form used by the handlers in
  [[Module:category tree/topic cat/data/Places]] that handle city-type and political-subdivision-type categories. It is
  passed three arguments (the group and the key and value of the data item). Its normal purpose is to add extra
  properties to the data item value, such as `containing_polity` (see above) and `keydesc` (the appropriate description
  of the place, which often includes the type of division and the country).  Some groups (in particular, the one for
  former polities, such as Persia and the Roman Empire) also add `is_former_place = true`. The reason these extra
  properties are added by a function like this instead of included directly is that they are typically the same or
  similar for all items in a group, and including them directly would be duplicative. Note that there is a
  preconstructed function subpolity_bare_label_setter() (for subpolities of top-level polities) to help.

* `bare_label_setter`: This function adds an entry in the `labels` table for
  [[Module:category tree/topic cat/data/Places]] for bare topical categories such as [[:Category:en:Netherlands]],
  [[:Category:fr:Alabama, USA]] or [[:Category:ru:Republic of Tatarstan]]. It is passed four arguments (the `labels`
  table, the group and the key and value of the data item). There are preconstructed functions to help here, such as
  simple_polity_bare_label_setter() (for top-level polities) and subpolity_bare_label_setter() (for subpolities of
  top-level polities). This function often makes use of the `parents` and/or `description` keys in the data item's
  value (see above).

* `place_cat_handler`: Used in conjunction with {{tl|place}} to properly categorize placenames. It is passed three
  arguments: GROUP, the spec for a given group; PLACETYPES, the placetype of a place or a list of such placetypes;
  and PLACENAME, the corresponding placename as found in a holonym, i.e. without any preceding "the". If a place
  matching PLACENAME is found in GROUP, and the place's placetype is compatible with PLACETYPE, return two arguments:
  the form of PLACENAME to be used in categories that include a preceding article (usually "the"), and the bare form
  of PLACENAME, without a preceding article. Otherwise, return nil. Here, "compatible" means that any of the
  placetypes in PLACETYPES is equal to any of the known placetypes of PLACENAME. (Most placenames in most groups have
  a single associated placetype, but some have more than one, e.g. Wales, which is associated with both
  "constituent country" and "country", and will be recognized for categorization purposes if either placetype is used.)
  For example, given the placename "Bashkortostan", placetype "republic", and group data associated with Russian
  federal subjects, the first return value will be "the Republic of Bashkortostan" and the second return value will be
  "Republic of Bashkortostan". Note that the first value is always equal to the key in `group.data` that describes the
  placename. (Both return values are needed because some categories contain the article, e.g. [[:Category:Places in the
  Republic of Bashkortostan]], and some don't, in particular the bare topical category
  [[:Category:Republic of Bashkortostan]].) If omitted, the function default_place_cat_handler() is used.

* `default_divtype`: The default entity type for entities in this group, if not overidden at the entity level. See
  `divtype` above under "Placename Tables".

====Polity subdivision tables====

Each of the following tables specifies a group of polities with common properties (e.g. the states of the US). Each
table is associated with a polity "group" (an entry in `export.polities`), which contains handlers specifying how to
process the data tables and also a pointer to the relevant table. The data is used as follows:

1. To generate the text of the bare topical categories directly associated with each polity, such as
   [[:Category:Netherlands]], [[:Category:Alabama, USA]] or [[:Category:Amazonas, Brazil]], and per-language
   variants such as [[:Category:de:Netherlands]], [[:Category:es:Alabama, USA]] or [[:Category:pt:Amazonas, Brazil]].
   These categories (and all placename categories) are found in the ''topic cat subsystem'' of the category system;
   see [[Module:category tree/topic cat/data]] for more information.
2. To generate the text of topical categories for cities/towns/rivers/etc. in a given polity, e.g.
   [[:Category:Cities in Alabama, USA]] for cities in Alabama, and per-language variants such as
   [[:Category:fr:Cities in Alabama, USA]] for French terms for cities in Alabama.
3. To generate the text of topical categories for political subdivisions of a given polity, e.g.
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
`bare_label_setter` and `value_transformer` keys (see `export.polities` below).
	 
The value of an item in each table is itself a table. This table contains properties describing the polity in question.
Note that before being used (e.g. to generate the contents of a category page like [[:Category:en:Cities in Ireland]]
or [[:Category:de:Provinces of the Netherlands]] of to specify how to add the relevant categories to a page with a call
to {{tl|place}}), the table is passed through the associated polity group's `value_transformer` function (see
`export.polities`). That function generally augments the property table with additional properties that are common to
the group or derivable from group-specific properties. The following are the properties most commonly specified
(additional properties are sometimes attached to entries in specific groups):

- `divtype`: String specifying the type of polity or subpolity (e.g. "country", "state", province"). This can also be a
  table of such types; in this case, the first listed type is the canonical type that will be used in descriptions, but
  the polity will be recognized (e.g. in {{tl|place}} arguments) when tagged with any of the specified types. This value
  overrides the group-level `default_divtype` value, and only needs to be specified if it disagrees with that value.

- `poldiv`: List of recognized political subdivisions; e.g. for the Netherlands, a specification of the form
  'poldiv = {"provinces", "municipalities"}' will allow categories such as [[:Category:de:Provinces of the Netherlands]]
  and [[:Category:pt:Municipalities of the Netherlands]] to be created. These categories have a primary parent
  [[:Category:LANGCODE:Political subdivisions]] (i.e. this is the parent that appears in the breadcrumbs at the top of
  the category page), and have the containing polity, if any (see `containing_polity` below) as an additional parent.
  Any political subdivision that appears here must also be listed in the `political_divisions` list, which tells how
  to convert the pluralized political subdivision into the equivalent linked description. (If not listed, an error
  occurs.)

- `miscdiv`: List of recognized historical/popular subdivisions; e.g. for Ireland, a specification of the form
  'miscdiv = {"provinces"}' will allow categories such as [[:Category:pl:Provinces of Ireland]] to be created. These
  categories differ from political subdivision categories in that their primary parent is the country name rather than
  [[:Category:LANGCODE:Political subdivisions]].

- `is_city`: If 'true', don't recognize or generate categories such as [[:Category:en:Cities in Monaco]] (specifically,
  for place types in `generic_placetypes` but not in `generic_placetypes_for_cities`).

- `is_former_place`: If 'true', don't recognize or generate categories such as
  [[:Category:fr:Rivers in the Soviet Union]] (specifically, for any place type in `generic_placetypes` other than
  "places"). NOTE: This key may be added automatically by the `value_transformer` function.
  
- `keydesc`: String directly specifying a description of the polity, for use in generating the contents of category
  pages related to the polity. descriptions. This property is only rarely present, and is normally generated
  automatically by the `value_transformer` function from the key and (for subpolities) the value of `divtype`.

- `parents`: List of parents of the bare topical category. For example, if 'parents = {"Europe", "Asia"}' is specified
  for "Turkey", bare topical categories such as [[:Category:en:Turkey]] will have parent categories
  [[:Category:en:Europe]] and [[:Category:en:Asia]]. The first listed category is used for the primary parent (i.e. this
  is the parent that appears in the breadcrumbs at the top of the category page). In this case, for example, "Europe"
  (not "Asia") is used as the breadcrumb. This property only needs to be specified for top-level polities (countries and
  such), not for subpolities (states, provinces, etc.), which use the value of `containing_polity` (see below) as the
  parent.

- `bare_category_desc`: String specifying the description used in the bare topical category. If not given, a default
  description is constructed by the `bare_label_setter` function.

- `containing_polity`: This property does not need to be specified explicitly. It is automatically added by the
  `value_transformer` function for subpolities, and left off for top-level polities. It specifies the larger polity in
  which the subpolity is contained, and is used to construct the primary parent of 'Cities in ...', 'Rivers in ...' and
  similar categories. For example, the subpolity Guangdong (a province of China) will have "China" as the
  `containing_polity`, so that a category of the form [[:Category:en:Cities in Guangdong]] will have its primary parent
  (i.e. the parent that appears in the breadcrumbs at the top of the category page) as [[:Category:en:Cities in China]].
  If `containing_polity` is omitted, as in top-level polities, the primary parent will simply be e.g.
  [[:Category:en:Cities]] (or "Towns", "Rivers", etc. as appropriate).

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
	for i, val in ipairs(args) do
		args[i] = dump(val)
	end
	return error(format(fmt, unpack(args)))
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

--[==[
Format a description that can have the special value of `true` or `nil` (use `link_label()` in
[[Module:category tree/topic cat]]) or `"w"` (use `link_label(..., "wikify"))`. Any other value is returned as-is.
]==]
function export.format_description(desc, label)
	-- FIXME: this function is the reason a bunch of place terms are linked by every category. link_label uses
	-- mw.title.new, which counts as a link. format_description is then called by
	-- [[Module:category tree/topic cat/data/Places]]. This is not ideal.
	if desc == nil then
		desc = true
	end
	if desc == true then
		desc = require(topic_cat_utilities_module).link_label(label)
	elseif desc == "w" then
		desc = require(topic_cat_utilities_module).link_label(label, nil, "wikify")
	end
	return desc
end

--[==[
Given a non-multipart key (where a multipart key is something like `"Tucson, Arizona"` or `"Atlanta, Georgia, USA"`),
possibly preceded by `the`, return two values, the ''bare'' and ''linked'' versions of the key. The bare version is
simply the passed-in `key` minus any preceding `the`. The linked version is the key converted into a raw bracketed link
(where any preceding `the` is included but is not part of the link). If `display_form` is given and is different from
the bare key, the resulting link will be a two-part link, linking to the non-`the` part of the key but displaying
`display_form` in place of the link.

For example, the call `construct_bare_and_linked_version("the United States")` will return `"United States"` and
`"the <nowiki>[[United States]]</nowiki>"`.
]==]
function export.construct_bare_and_linked_version(key, display_form)
	local bare_key = key:match("^the (.*)$")
	local linked_prefix
	if bare_key then
		linked_prefix = "the "
	else
		bare_key = key
		linked_prefix = ""
	end
	local linked_key = display_form and bare_key ~= display_form and ("[[%s|%s]]"):format(bare_key, display_form) or
		("[[%s]]"):format(bare_key)
	linked_key = linked_prefix .. linked_key
	return bare_key, linked_key
end

local function simple_polity_bare_label_setter(overriding_parents)
	return function(labels, group, key, value)
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		-- wp= defaults to true (Wikipedia article matches bare key = label)
		local wp = value.wp
		if wp == nil then
			wp = true
		end
		-- wpcat= defaults to wp= (if Wikipedia article has its own name, Wikipedia category and Commons category generally follow)
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
		labels[bare_key] = {
			type = "topic",
			description = value.bare_category_desc or "{{{langname}}} terms related to the people, culture, or territory of "
				.. (value.keydesc or linked_key) .. ".",
			parents = parents,
			wp = wp,
			wpcat = wpcat,
			commonscat = commonscat,
		}
	end
end

-- Construct the description of a subpolity key, for use in the description of a category.
local function subpolity_keydesc(group, key, value, containing_polity, default_divtype)
	local divtype = value.divtype or default_divtype
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
	local bare_containing_polity, linked_containing_polity = export.construct_bare_and_linked_version(containing_polity)
	return linked_placename .. ", " .. divtype .. " of " .. linked_containing_polity
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

-- Return whether `list_or_element` (a list of strings, or a single string) "contains" `item` (a string). If
-- `list_or_element` is a list, this returns true if `item` is in the list; otherwise it returns true if `item`
-- equals `list_or_element`.
local function list_or_element_contains(list_or_element, item)
	if type(list_or_element) == "table" then
		return m_table.contains(list_or_element, item) and true or false
	end
	return list_or_element == item
end

local function subpolity_bare_label_setter(containing_polity)
	return function(labels, group, key, value)
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		local bare_containing_polity, linked_containing_polity = export.construct_bare_and_linked_version(containing_polity)
		local div_parent_type = value.div_parent_type or group.default_div_parent_type
		if not div_parent_type then
			local divtype = value.divtype or group.default_divtype
			divtype = type(divtype) == "table" and divtype[1] or divtype
			if not divtype then
				internal_error("Ended up with nil divtype for key=%s, value=%s", key, value)
			end
			div_parent_type = require(en_utilities_module).pluralize(divtype)
		end
        labels[bare_key] = {
            type = "topic",
            description = function()
				if value.bare_category_desc then
					return value.bare_category_desc
				else
					local keydesc = subpolity_keydesc(group, key, value, containing_polity, group.default_divtype)
					return "{{{langname}}} terms related to the people, culture, or territory of " .. keydesc .. "."
				end
			end,
            parents = {div_parent_type .. " of " .. containing_polity},
        }
	end
end

local function subpolity_value_transformer(containing_polity)
	local containing_polity_type = "country"
	if type(containing_polity) == "table" then
		containing_polity_type, containing_polity = containing_polity[1], containing_polity[2]
	end
	return function(group, key, value)
		value.keydesc = value.keydesc or function() return subpolity_keydesc(group, key, value, containing_polity, group.default_divtype) end
		value.containing_polity = containing_polity
		value.containing_polity_type = containing_polity_type
		value.poldiv = value.poldiv or group.default_poldiv
		value.miscdiv = value.miscdiv or group.default_miscdiv
		value.british_spelling = value.british_spelling or group.british_spelling
		value.no_containing_polity_cat = value.no_containing_polity_cat or group.no_containing_polity_cat
		return value
	end
end

--[==[
See the documentation for `place_cat_handler` above the definition of `export.polities` below.
]==]
function export.default_place_cat_handler(group, placetypes, placename)
	if group.placename_to_key then
		placename = group.placename_to_key(placename)
	end
	local spec = group.data[placename]
	local article = ""
	local bare_placename = placename
	if not spec then
		placename = "the " .. placename
		spec = group.data[placename]
	end
	if not spec then
		return nil
	end
	local divtype = spec.divtype or group.default_divtype
	if type(divtype) == "table" then
		for _, dt in ipairs(divtype) do
			if list_or_element_contains(placetypes, dt) then
				return placename, bare_placename
			end
		end
		return nil
	elseif list_or_element_contains(placetypes, divtype) then
		return placename, bare_placename
	else
		return nil
	end
end


--[==[
Call the place cat handler for a given polity `group` for a holonym `placename` with possible holonym placetypes
`placetypes`. The purpose of this is to check if the holonym exists in the group, and if so, return two values:
the key as found in the polity tables (which is the form that the holonym would take in a category of the form
` ``Placetypes`` in/of ``holonym``` e.g. [[:Category:Districts of the West Midlands, England]]) and the ''bare key'',
which is the same as the key except it removes any occurrence of `the` at the beginning (and hence is suitable for bare
categories such as [[:Category:West Midlands, England]]). This is sort of a glorified `placename_to_key()` for
subpolities in the group, but also verifies the correct placetype(s).
]==]
function export.call_place_cat_handler(group, placetypes, placename)
	local handler = group.place_cat_handler or export.default_place_cat_handler
	return handler(group, placetypes, placename)
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
Return the normalized containing polities for a city, given the city's ''city group'' object and the particular
''city spec'' for the city (the value in the city group key-value data table corresponding to the city in question).
This joins the containing polities specified at the city spec level with any additional (outer) containing polities
specified at the group level. The return value is normalized to always be in a list format where each object contains
`name` and `divtype` fields, where `divtype` will always be present (defaulted if necessary from the city group level).
]==]
function export.get_city_containing_polities(city_group, city_spec)
	local skip_parents = normalize_city_parents(city_group.skip_parents)
	local this_parents, this_parents_copied =
		normalize_city_parents(city_spec.parents, city_group.default_parent_divtype)
	if not this_parents or not this_parents[1] then
		return skip_parents or {}
	end
	if not skip_parents or not skip_parents[1] then
		return this_parents or {}
	end
	if not this_parents_copied then
		this_parents = m_table.shallowCopy(this_parents)
	end
	m_table.extend(this_parents, skip_parents)
	return this_parents
end


--[==[
Given a containing polity of a city, possibly with preceding `the` removed, find the group and key in
`export.polities`. Return two values, the polity group and key in that group's data to fetch the polity spec.
`parent_spec` is as in the return value of `get_city_containing_polities`, i.e. it is a table with `name` and `divtype`
fields, which must both be present. The `divtype` is used to check that we have the right polity; otherwise, for
example, the city of [[Atlanta]] wrongly ends up in [[:Category:Cities in Georgia]] (the country) in lieu of the correct
[[:Category:Cities in Georgia, USA]].
]==]
function export.city_containing_polity_to_group_and_key(parent_spec)
	for _, polity_group in ipairs(export.polities) do
		local polity_key, polity_bare_key = export.call_place_cat_handler(polity_group, parent_spec.divtype,
			parent_spec.name)
		if polity_key then
			return polity_group, polity_key
		end
	end
	return nil
end

-----------------------------------------------------------------------------------
--                              Placetype Tables                                 --
-----------------------------------------------------------------------------------

--[==[ var:
Recognized political and misc. (sub)divisions. The key is the plural division and the value is the equivalent
description, with links. A value of true means to use the default linking algorithm in link_label() in
[[Module:category tree/topic cat]]. A value of "w" is similar but links to Wikipedia. NOTE: This currently used
only for category descriptions by [[Module:category tree/topic cat/data/Places]], and overlaps the information
in `placetype_links` in [[Module:place/data]]. FIXME: The two should be combined somehow.
]==]
export.political_divisions = {
	["administrative atolls"] = true,
	["administrative regions"] = true,
	["areas"] = true,
	["arrondissements"] = true,
	["atolls"] = true,
	["autonomous cities"] = "w",
	["autonomous communities"] = "w",
	["autonomous islands"] = true,
	["autonomous oblasts"] = true,
	["autonomous okrugs"] = true,
	["autonomous regions"] = true,
	["autonomous republics"] = "w",
	["barangays"] = true,
	["boroughs"] = true,
	["borough seats"] = true,
	["cantons"] = true,
	["census divisions"] = "w",
	["cercles"] = true,
	["civil parishes"] = true,
	["collectivities"] = true,
	["communes"] = true,
	["communities"] = true,
	["constituencies"] = true,
	["constituent countries"] = true,
	-- the following needed to support Jerusalem, whose first parent is Asia, a continent
	["continents"] = true,
	["council areas"] = true,
	["counties"] = true,
	["county boroughs"] = true,
	["county seats"] = true,
	["countries"] = true,
	["delegations"] = true,
	["departments"] = true,
	["dependent territories"] = "w",
	["districts"] = true,
	["districts and autonomous regions"] = "[[district]]s and [[autonomous region]]s",
	["divisions"] = true,
	["emirates"] = true,
	["entities"] = true,
	["ethnographic regions"] = true,
	["federal cities"] = true,
	["federal districts"] = true,
	["federal subjects"] = true,
	["federal territories"] = true,
	["gewogs"] = true,
	["governorates"] = true,
	["Indian reservations"] = "w",
	["Indian reserves"] = "w",
	["krais"] = true,
	["local councils"] = "w",
	["local government areas"] = "w",
	["metropolitan cities"] = true,
	["mukims"] = true,
	["municipal districts"] = "w",
	["municipalities"] = true,
	["neighborhoods"] = true,
	-- need at least the following for [[Category:Neighborhoods in Hong Kong]]
	["neighbourhoods"] = true,
	["oblasts"] = true,
	["parishes"] = true,
	["parish seats"] = true,
	["prefectures"] = true,
	["provinces"] = true,
	["provinces and autonomous regions"] = "[[province]]s and [[autonomous region]]s",
	["provinces and territories"] = "[[province]]s and [[territory|territories]]",
	["quarters"] = true,
	["raions"] = true,
	["regencies"] = true,
	["regional county municipalities"] = "w",
	["regional districts"] = "w",
	["regional municipalities"] = "w",
	["regions"] = true,
	["regional units"] = true,
	["republics"] = true,
	["rural municipalities"] = "w",
	["self-administered divisions"] = "w",
	["self-administered zones"] = "w",
	["special administrative regions"] = "[[w:Special administrative regions of China|special administrative regions]]",
	["special municipality"] = "[[w:Special municipality (Taiwan)|special municipality]]",
	["special wards"] = true,
	["states"] = true,
	["states and territories"] = "[[state]]s and [[territory|territories]]",
	["states and union territories"] = "[[state]]s and [[union territory|union territories]]",
	["subdistricts"] = true,
	["subprefectures"] = true,
	["subregions"] = true,
	["territorial authorities"] = "w",
	["territories"] = true,
	["townships"] = true,
	["traditional counties"] = "w",
	["traditional regions"] = "w",
	["unincorporated areas"] = "w",
	["union territories"] = true,
	["voivodeships"] = true,
	["zones"] = true,
}

--[==[ var:
Place types for which categories can be constructed for all the places listed below other than cities. The key should
be the plural place type and the value should be either a string (the description) or an object containing a field
`desc` (the description) and `prep` (the preposition following the place type as it occurs in categories, defaulting
to "in").
]==]
export.generic_placetypes = {
	["cities"] = "cities",
	["ghost towns"] = "[[ghost town]]s",
	["towns"] = "towns",
	["communes"] = "[[commune]]s",
	["villages"] = "villages, hamlets, and other small communities and settlements",
	["neighborhoods"] = "[[neighborhood]]s, [[district]]s and other subportions of cities",
	["neighbourhoods"] = "[[neighbourhood]]s, [[district]]s and other subportions of cities",
	["suburbs"] = "[[suburb]]s",
	["rivers"] = "rivers",
	["census-designated places"] = "[[census-designated place]]s",
	["unincorporated communities"] = "[[w:unincorporated community|unincorporated communities]]",
	["places"] = "places of all sorts",
	["geographic and cultural areas"] = {desc = "[[geographic]] and [[cultural]] [[area]]s", prep = "of"},
}

--[==[ var:
Place types for which categories can be constructed for cities listed below. The key should be the plural place type
and the value should be either a string (the description) or an object containing a field `desc` (the description)
and `prep` (the preposition following the place type as it occurs in categories, defaulting to "of").
]==]
export.generic_placetypes_for_cities = {
	["neighborhoods"] = "[[neighborhood]]s, [[district]]s and other subportions of cities",
	["neighbourhoods"] = "[[neighbourhood]]s, [[district]]s and other subportions of cities",
	["suburbs"] = "[[suburb]]s",
	["places"] = {desc = "places of all sorts", prep = "in"},
}

export.placetype_to_capital_cat = {
	["autonomous community"] = "autonomous community capitals",
	["canton"] = "cantonal capitals",
	["country"] = "national capitals",
	["department"] = "departmental capitals",
	["district"] = "district capitals",
	["division"] = "division capitals",
	["emirate"] = "emirate capitals",
	["prefecture"] = "prefectural capitals",
	["province"] = "provincial capitals",
	["region"] = "regional capitals",
	["republic"] = "republic capitals",
	["state"] = "state capitals",
	["territory"] = "territorial capitals",
	["voivodeship"] = "voivodeship capitals",
}

export.capital_cat_to_placetype = {}
for placetype, capital_cat in pairs(export.placetype_to_capital_cat) do
	export.capital_cat_to_placetype[capital_cat] = placetype
end

-----------------------------------------------------------------------------------
--                          Country and Country-Like Tables                      --
-----------------------------------------------------------------------------------

export.countries = {
	["Afghanistan"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}, miscdiv = {"regions"}},
	["Albania"] = {parents = {"Europe"}, poldiv = {"regions", "counties", "municipalities"}, british_spelling = true},
	["Algeria"] = {parents = {"Africa"}, poldiv = {"provinces", "communes", "districts", "municipalities"}},
	["Andorra"] = {parents = {"Europe"}, poldiv = {"parishes"}, british_spelling = true},
	["Angola"] = {parents = {"Africa"}, poldiv = {"provinces", "municipalities"}},
	["Antigua and Barbuda"] = {parents = {"North America"}, poldiv = {"provinces"}, british_spelling = true},
	["Argentina"] = {parents = {"South America"}, poldiv = {"provinces", "departments", "municipalities"}},
	["Armenia"] = {parents = {"Europe", "Asia"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	-- Both a country and continent
	["Australia"] = {parents = {"Oceania"}, poldiv = {"states", "territories", "local government areas"},
		addl_poldiv_for_categorization = {"states and territories"}, british_spelling = true},
	["Austria"] = {parents = {"Europe"}, poldiv = {"states", "districts", "municipalities"}, british_spelling = true},
	["Azerbaijan"] = {parents = {"Europe", "Asia"}, poldiv = {"districts", "municipalities"}, british_spelling = true},
	["the Bahamas"] = {parents = {"North America"}, poldiv = {"districts"}, british_spelling = true, wp = "The Bahamas"},
	["Bahrain"] = {parents = {"Asia"}, poldiv = {"governorates"}},
	["Bangladesh"] = {parents = {"Asia"}, poldiv = {"divisions", "districts", "municipalities"}, british_spelling = true},
	["Barbados"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["Belarus"] = {parents = {"Europe"}, poldiv = {"regions", "districts"}, british_spelling = true},
	["Belgium"] = {parents = {"Europe"}, poldiv = {"regions", "provinces", "municipalities"}, british_spelling = true},
	["Belize"] = {parents = {"Central America"}, poldiv = {"districts"}, british_spelling = true},
	["Benin"] = {parents = {"Africa"}, poldiv = {"departments", "communes"}},
	["Bhutan"] = {parents = {"Asia"}, poldiv = {"districts", "gewogs"}},
	["Bolivia"] = {parents = {"South America"}, poldiv = {"provinces", "departments", "municipalities"}},
	["Bosnia and Herzegovina"] = {parents = {"Europe"}, poldiv = {"entities", "cantons", "municipalities"}, british_spelling = true},
	["Botswana"] = {parents = {"Africa"}, poldiv = {"districts", "subdistricts"}, british_spelling = true},
	["Brazil"] = {parents = {"South America"}, poldiv = {"states", "municipalities"}, miscdiv = {"regions"}},
	["Brunei"] = {parents = {"Asia"}, poldiv = {"districts", "mukims"}, british_spelling = true},
	["Bulgaria"] = {parents = {"Europe"}, poldiv = {"provinces", "municipalities"}, british_spelling = true},
	["Burkina Faso"] = {parents = {"Africa"}, poldiv = {"regions", "departments", "provinces"}},
	["Burundi"] = {parents = {"Africa"}, poldiv = {"provinces", "communes"}},
	["Cambodia"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}},
	["Cameroon"] = {parents = {"Africa"}, poldiv = {"regions", "departments"}},
	["Canada"] = {parents = {"North America"}, poldiv = {
		"provinces", "territories", "counties", "districts", "municipalities", "regional municipalities", "rural municipalities",
		"Indian reserves"},
		miscdiv = {"regions", "census divisions", {type = "townships", prep = "in"}},
		addl_poldiv_for_categorization = {"provinces and territories"},
		british_spelling = true},
	["Cape Verde"] = {parents = {"Africa"}, poldiv = {"municipalities", "parishes"}},
	["the Central African Republic"] = {parents = {"Africa"}, poldiv = {"prefectures", "subprefectures"}},
	["Chad"] = {parents = {"Africa"}, poldiv = {"regions", "departments"}},
	["Chile"] = {parents = {"South America"}, poldiv = {"regions", "provinces", "communes"}},
	["China"] = {parents = {"Asia"}, poldiv = {"provinces", "autonomous regions",
		"special administrative regions", "prefectures", "counties", "districts", "municipalities"},
		miscdiv = {"regions"}, addl_poldiv_for_categorization = {"provinces and autonomous regions"}},
	["Colombia"] = {parents = {"South America"}, poldiv = {"departments", "municipalities"}},
	["the Comoros"] = {parents = {"Africa"}, poldiv = {"autonomous islands"}},
	["Costa Rica"] = {parents = {"Central America"}, poldiv = {"provinces", "cantons"}},
	["Croatia"] = {parents = {"Europe"}, poldiv = {"counties", "municipalities"}, british_spelling = true},
	["Cuba"] = {parents = {"North America"}, poldiv = {"provinces", "municipalities"}},
	["Cyprus"] = {parents = {"Europe", "Asia"}, poldiv = {"districts"}, british_spelling = true},
	["the Czech Republic"] = {parents = {"Europe"}, poldiv = {"regions", "districts", "municipalities"}, british_spelling = true},
	["the Democratic Republic of the Congo"] = {parents = {"Africa"}, poldiv = {"provinces", "territories"}},
	["Denmark"] = {parents = {"Europe"}, poldiv = {"regions", "municipalities", "dependent territories"}, british_spelling = true},
	["Djibouti"] = {parents = {"Africa"}, poldiv = {"regions", "districts"}},
	["Dominica"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["the Dominican Republic"] = {parents = {"North America"}, poldiv = {"provinces", "municipalities"},
		keydesc = "the [[Dominican Republic]], the country that shares the [[Caribbean]] island of [[Hispaniola]] with [[Haiti]]"},
	["East Timor"] = {parents = {"Asia"}, poldiv = {"municipalities"}},
	["Ecuador"] = {parents = {"South America"}, poldiv = {"provinces", "cantons"}},
	["Egypt"] = {parents = {"Africa"}, poldiv = {"governorates", "regions"}},
	["El Salvador"] = {parents = {"Central America"}, poldiv = {"departments", "municipalities"}},
	["Equatorial Guinea"] = {parents = {"Africa"}, poldiv = {"provinces"}},
	["Eritrea"] = {parents = {"Africa"}, poldiv = {"regions", "subregions"}},
	["Estonia"] = {parents = {"Europe"}, poldiv = {"counties", "municipalities"}, british_spelling = true},
	["Eswatini"] = {parents = {"Africa"}, british_spelling = true},
	["Ethiopia"] = {parents = {"Africa"}, poldiv = {"regions", "zones"}},
	["the Federated States of Micronesia"] = {parents = {"Micronesia"}, poldiv = {"states"}},
	["Fiji"] = {parents = {"Melanesia"}, poldiv = {"divisions", "provinces"}, british_spelling = true},
	["Finland"] = {parents = {"Europe"}, poldiv = {"regions", "municipalities"}, british_spelling = true},
	["France"] = {parents = {"Europe"}, poldiv = {"administrative regions", "cantons", "collectivities", "communes", "departments",
		"municipalities", "dependent territories", "territories",
		{type = "prefectures", cat_as = {"prefectures", "departmental capitals"}},
		{type = "French prefectures", cat_as = {"prefectures", "departmental capitals"}},
	}, miscdiv = {"provinces", "regions"}, british_spelling = true},
	["Gabon"] = {parents = {"Africa"}, poldiv = {"provinces", "departments"}},
	["the Gambia"] = {parents = {"Africa"}, poldiv = {"divisions", "districts"}, british_spelling = true, wp = "The Gambia"},
	["Georgia"] = {parents = {"Europe", "Asia"}, poldiv = {"regions", "districts"},
		keydesc = "the country of [[Georgia]], in [[Eurasia]]", british_spelling = true},
	["Germany"] = {parents = {"Europe"}, poldiv = {"states", "municipalities", "districts"}, british_spelling = true},
	["Ghana"] = {parents = {"Africa"}, poldiv = {"regions", "districts"}, british_spelling = true},
	["Greece"] = {parents = {"Europe"}, poldiv = {"regions", "regional units", "municipalities"}, british_spelling = true},
	["Grenada"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["Guatemala"] = {parents = {"Central America"}, poldiv = {"departments", "municipalities"}},
	["Guinea"] = {parents = {"Africa"}, poldiv = {"regions", "prefectures"}},
	["Guinea-Bissau"] = {parents = {"Africa"}, poldiv = {"regions"}},
	["Guyana"] = {parents = {"South America"}, poldiv = {"regions"}, british_spelling = true},
	["Haiti"] = {parents = {"North America"}, poldiv = {"departments", "arrondissements"}},
	["Honduras"] = {parents = {"Central America"}, poldiv = {"departments", "municipalities"}},
	["Hungary"] = {parents = {"Europe"}, poldiv = {"counties", "districts"}, british_spelling = true},
	["Iceland"] = {parents = {"Europe"}, poldiv = {"administrative regions", "municipalities", "counties"}, british_spelling = true},
	["India"] = {parents = {"Asia"}, poldiv = {"states", "union territories", "divisions", "districts", "municipalities"},
		 addl_poldiv_for_categorization = {"states and union territories"}, british_spelling = true},
	["Indonesia"] = {parents = {"Asia"}, poldiv = {"regencies", "provinces"}},
	["Iran"] = {parents = {"Asia"}, poldiv = {"provinces", "counties"}},
	["Iraq"] = {parents = {"Asia"}, poldiv = {"governorates", "districts"}},
	["Ireland"] = {parents = {"Europe", {name = "British Isles", bare = true}}, poldiv = {"counties", "districts"}, miscdiv = {"provinces"}, british_spelling = true},
	["Israel"] = {parents = {"Asia"}, poldiv = {"districts"}},
	["Italy"] = {parents = {"Europe"}, poldiv = {"administrative regions", "provinces", "metropolitan cities", "municipalities"},
		miscdiv = {"regions"}, british_spelling = true},
	["Ivory Coast"] = {parents = {"Africa"}, poldiv = {"districts", "regions"}},
	["Jamaica"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["Japan"] = {parents = {"Asia"}, poldiv = {"prefectures", "subprefectures", "municipalities"}},
	["Jordan"] = {parents = {"Asia"}, poldiv = {"governorates"}},
	["Kazakhstan"] = {parents = {"Asia", "Europe"}, poldiv = {"regions", "districts"}},
	["Kenya"] = {parents = {"Africa"}, poldiv = {"counties"}, british_spelling = true},
	["Kiribati"] = {parents = {"Micronesia"}, british_spelling = true},
	["Kosovo"] = {parents = {"Europe"}, british_spelling = true},
	["Kuwait"] = {parents = {"Asia"}, poldiv = {"governorates", "areas"}},
	["Kyrgyzstan"] = {parents = {"Asia"}, poldiv = {"regions", "districts"}},
	["Laos"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}},
	["Latvia"] = {parents = {"Europe"}, poldiv = {"municipalities"}, miscdiv = {"regions"}, british_spelling = true},
	["Lebanon"] = {parents = {"Asia"}, poldiv = {"governorates", "districts"}},
	["Lesotho"] = {parents = {"Africa"}, poldiv = {"districts"}, british_spelling = true},
	["Liberia"] = {parents = {"Africa"}, poldiv = {"counties", "districts"}},
	["Libya"] = {parents = {"Africa"}, poldiv = {"districts", "municipalities"}},
	["Liechtenstein"] = {parents = {"Europe"}, poldiv = {"municipalities"}, british_spelling = true},
	["Lithuania"] = {parents = {"Europe"}, poldiv = {"counties", "municipalities"},
		miscdiv = {"ethnographic regions"}, british_spelling = true},
	["Luxembourg"] = {parents = {"Europe"}, poldiv = {"cantons"}, miscdiv = {"districts"}, british_spelling = true},
	["Madagascar"] = {parents = {"Africa"}, poldiv = {"regions", "districts"}},
	["Malawi"] = {parents = {"Africa"}, poldiv = {"regions", "districts"}, british_spelling = true},
	["Malaysia"] = {parents = {"Asia"}, poldiv = {"states", "federal territories", "districts"}, british_spelling = true},
	["the Maldives"] = {parents = {"Asia"}, poldiv = {"provinces", "administrative atolls"}, british_spelling = true},
	["Mali"] = {parents = {"Africa"}, poldiv = {"regions", "cercles"}},
	["Malta"] = {parents = {"Europe"}, poldiv = {"regions", "local councils"}, british_spelling = true},
	["the Marshall Islands"] = {parents = {"Micronesia"}, poldiv = {"municipalities"}},
	["Mauritania"] = {parents = {"Africa"}, poldiv = {"regions", "departments"}},
	["Mauritius"] = {parents = {"Africa"}, poldiv = {"districts"}, british_spelling = true},
	["Mexico"] = {parents = {"North America", "Central America"}, poldiv = {"states", "municipalities"}},
	["Moldova"] = {parents = {"Europe"}, poldiv = {"districts", "municipalities"}, british_spelling = true},
	["Monaco"] = {divtype = {"city-state", "country"}, parents = {"Europe"}, is_city = true, british_spelling = true},
	["Mongolia"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}},
	["Montenegro"] = {parents = {"Europe"}, poldiv = {"municipalities"}},
	["Morocco"] = {parents = {"Africa"}, poldiv = {"regions", "prefectures", "provinces"}},
	["Mozambique"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}},
	["Myanmar"] = {parents = {"Asia"},
		poldiv = {"regions", "states", "union territories", "self-administered zones", "self-administered divisions", "districts"}},
	["Namibia"] = {parents = {"Africa"}, poldiv = {"regions", "constituencies"}, british_spelling = true},
	["Nauru"] = {parents = {"Micronesia"}, poldiv = {"districts"}, british_spelling = true},
	["Nepal"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}},
	["the Netherlands"] = {divtype = {"constituent country", "country"}, parents = {"Europe"},
		poldiv = {"provinces", "municipalities", "dependent territories", "constituent countries"}, british_spelling = true},
	["New Zealand"] = {parents = {"Polynesia"}, poldiv = {"regions", "dependent territories", "territorial authorities"},
		british_spelling = true},
	["Nicaragua"] = {parents = {"Central America"}, poldiv = {"departments", "municipalities"}},
	["Niger"] = {parents = {"Africa"}, poldiv = {"regions", "departments"}},
	["Nigeria"] = {parents = {"Africa"}, poldiv = {"states", "local government areas"}, british_spelling = true},
	["North Korea"] = {parents = {"Asia", {name = "Korea", bare = true}}, poldiv = {"provinces", "counties"}},
	["North Macedonia"] = {parents = {"Europe"}, poldiv = {"regions", "municipalities"}, british_spelling = true},
	["Norway"] = {parents = {"Europe"}, poldiv = {"counties", "municipalities", "dependent territories"},
		miscdiv = {"districts", "unincorporated areas"}, british_spelling = true},
	["Oman"] = {parents = {"Asia"}, poldiv = {"governorates", "provinces"}},
	["Pakistan"] = {parents = {"Asia"}, poldiv = {"provinces", "divisions", "districts",
		{type = "administrative territories", cat_as = "territories"},
		{type = "federal territories", cat_as = "territories"}},
		addl_poldiv_for_categorization = {"provinces and territories"}, british_spelling = true},
	["Palestine"] = {parents = {"Asia"}, poldiv = {"governorates"}},
	["Palau"] = {parents = {"Micronesia"}, poldiv = {"states"}},
	["Panama"] = {parents = {"Central America"}, poldiv = {"provinces", "districts"}},
	["Papua New Guinea"] = {parents = {"Melanesia"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["Paraguay"] = {parents = {"South America"}, poldiv = {"departments", "districts"}},
	["Peru"] = {parents = {"South America"}, poldiv = {"regions", "provinces", "districts"}},
	["the Philippines"] = {parents = {"Asia"}, poldiv = {"regions", "provinces", "districts", "municipalities", "barangays"}},
	["Poland"] = {poldiv = {"voivodeships", "counties"}, parents = {"Europe"}, british_spelling = true},
	["Portugal"] = {parents = {"Europe"}, poldiv = {"districts and autonomous regions", "provinces", "municipalities"}, british_spelling = true},
	["Qatar"] = {parents = {"Asia"}, poldiv = {"municipalities", "zones"}},
	["the Republic of the Congo"] = {parents = {"Africa"}, poldiv = {"departments", "districts"}},
	["Romania"] = {parents = {"Europe"}, poldiv = {"regions", "counties", "communes"}, british_spelling = true},
	["Russia"] = {parents = {"Europe", "Asia"}, poldiv = {
		"federal subjects", "republics", "autonomous oblasts", "autonomous okrugs", "oblasts", "krais", "federal cities",
		"districts", "federal districts"},
		british_spelling = true},
	["Rwanda"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}},
	["Saint Kitts and Nevis"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["Saint Lucia"] = {parents = {"North America"}, poldiv = {"quarters"}, british_spelling = true},
	["Saint Vincent and the Grenadines"] = {parents = {"North America"}, poldiv = {"parishes"}, british_spelling = true},
	["Samoa"] = {parents = {"Polynesia"}, poldiv = {"districts"}, british_spelling = true},
	["San Marino"] = {parents = {"Europe"}, poldiv = {"municipalities"}, british_spelling = true},
	["São Tomé and Príncipe"] = {parents = {"Africa"}, poldiv = {"districts"}},
	["Saudi Arabia"] = {parents = {"Asia"}, poldiv = {"provinces", "governorates"}},
	["Senegal"] = {parents = {"Africa"}, poldiv = {"regions", "departments"}},
	["Serbia"] = {parents = {"Europe"}, poldiv = {"districts", "municipalities"}}, 
	["Seychelles"] = {parents = {"Africa"}, poldiv = {"districts"}, british_spelling = true},
	["Sierra Leone"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["Singapore"] = {parents = {"Asia"}, poldiv = {"districts"}, british_spelling = true},
	["Slovakia"] = {parents = {"Europe"}, poldiv = {"regions", "districts"}, british_spelling = true},
	["Slovenia"] = {parents = {"Europe"}, poldiv = {"municipalities"}, miscdiv = {"traditional regions"}, british_spelling = true},
	-- Note: the official name does not include "the" at the beginning, but it sounds strange in
	-- English to leave it out and it's commonly included, so we include it.
	["the Solomon Islands"] = {parents = {"Melanesia"}, poldiv = {"provinces"}, british_spelling = true},
	["Somalia"] = {parents = {"Africa"}, poldiv = {"regions", "districts"}},
	["South Africa"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["South Korea"] = {parents = {"Asia", {name = "Korea", bare = true}}, poldiv = {"provinces", "counties", "districts"}},
	["South Sudan"] = {parents = {"Africa"}, poldiv = {"regions", "states", "counties"}, british_spelling = true},
	["Spain"] = {parents = {"Europe"}, poldiv = {"autonomous communities", "provinces", "municipalities", "autonomous cities"},
		british_spelling = true},
	["Sri Lanka"] = {parents = {"Asia"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["Sudan"] = {parents = {"Africa"}, poldiv = {"states", "districts"}, british_spelling = true},
	["Suriname"] = {parents = {"South America"}, poldiv = {"districts"}},
	["Sweden"] = {parents = {"Europe"}, poldiv = {"provinces", "counties", "municipalities"}, british_spelling = true},
	["Switzerland"] = {parents = {"Europe"}, poldiv = {"cantons", "municipalities", "districts"}, british_spelling = true},
	["Syria"] = {parents = {"Asia"}, poldiv = {"governorates", "districts"}},
	["Taiwan"] = {parents = {"Asia"}, poldiv = {"counties", "districts"}},
	["Tajikistan"] = {parents = {"Asia"}, poldiv = {"provinces"}, miscdiv = {"regions", "districts"}},
	["Tanzania"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["Thailand"] = {parents = {"Asia"}, poldiv = {"provinces", "districts", "subdistricts"}},
	["Togo"] = {parents = {"Africa"}, poldiv = {"provinces", "prefectures"}},
	["Tonga"] = {parents = {"Polynesia"}, poldiv = {"divisions"}, british_spelling = true},
	["Trinidad and Tobago"] = {parents = {"North America"}, poldiv = {"regions", "municipalities"}, british_spelling = true},
	["Tunisia"] = {parents = {"Africa"}, poldiv = {"governorates", "delegations"}},
	["Turkey"] = {parents = {"Europe", "Asia"}, poldiv = {"provinces", "districts"}},
	["Turkmenistan"] = {parents = {"Asia"}, poldiv = {"regions", "districts"}},
	["Tuvalu"] = {parents = {"Polynesia"}, poldiv = {"atolls"}, british_spelling = true},
	["Uganda"] = {parents = {"Africa"}, poldiv = {"districts", "counties"}, british_spelling = true},
	["Ukraine"] = {parents = {"Europe"}, poldiv = {"oblasts", "municipalities", "raions"}, british_spelling = true},
	["the United Arab Emirates"] = {parents = {"Asia"}, poldiv = {"emirates"}},
	["the United Kingdom"] = {parents = {"Europe", {name = "British Isles", bare = true}},
		poldiv = {"constituent countries", "counties", "districts", "boroughs", "territories", "dependent territories"},
		miscdiv = {"regions", "traditional counties"},
		keydesc = "the [[United Kingdom]] of Great Britain and Northern Ireland", british_spelling = true},
	["the United States"] = {parents = {"North America"},
		poldiv = {"counties", "county seats", "states", "territories", "dependent territories",
			{type = "boroughs", prep = "in"}, -- exist in Pennsylvania and New Jersey
			"municipalities", -- these exist politically at least in Colorado and Connecticut
			"Indian reservations",
		}, miscdiv = {"regions"}},
	["Uruguay"] = {parents = {"South America"}, poldiv = {"departments", "municipalities"}},
	["Uzbekistan"] = {parents = {"Asia"}, poldiv = {"regions", "districts"}},
	["Vanuatu"] = {parents = {"Melanesia"}, poldiv = {"provinces"}, british_spelling = true},
	["Vatican City"] = {divtype = {"city-state", "country"}, parents = {"Europe", {name = "Rome", bare = true}}, is_city = true, british_spelling = true},
	["Venezuela"] = {parents = {"South America"}, poldiv = {"states", "municipalities"}},
	["Vietnam"] = {parents = {"Asia"}, poldiv = {"provinces", "districts", "municipalities"}},
	["Western Sahara"] = {divtype = {"territory"}, parents = {"Africa"}},
	["Yemen"] = {parents = {"Asia"}, poldiv = {"governorates", "districts"}},
	["Zambia"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}, british_spelling = true},
	["Zimbabwe"] = {parents = {"Africa"}, poldiv = {"provinces", "districts"}, british_spelling = true},
}

export.pseudo_countries = {
	-- British Overseas Territory
	["Akrotiri and Dhekelia"] = {divtype = {"overseas territory", "territory"},
		parents = {"Cyprus", "Europe", "United Kingdom"}, british_spelling = true},
	-- unincorporated territory of the United States
	["American Samoa"] = {divtype = {"unincorporated territory", "overseas territory", "territory"},
		parents = {"Polynesia", "United States"}},
	["the United States Minor Outlying Islands"] = {
		divtype = {"unincorporated territory", "overseas territory", "territory"},
		parents = {"Islands", "Micronesia", "Polynesia", "United States"}
	},
	-- British Overseas Territory
	["Anguilla"] = {divtype = {"overseas territory", "territory"}, parents = {"North America", "United Kingdom"},
		british_spelling = true},
	-- de-facto independent state, internationally recognized as part of Georgia
	["Abkhazia"] = {divtype = {"unrecognized state", "country"}, parents = {"Georgia", "Europe", "Asia"},
		poldiv = {"districts"},
		keydesc = "the de-facto independent state of [[Abkhazia]], internationally recognized as part of the country of [[Georgia]]"},
	-- de-facto independent state of Armenian ethnicity, internationally recognized as part of Azerbaijan
	-- (also known as Nagorno-Karabakh)
	-- NOTE: Formerly listed Armenia as a parent; this seems politically non-neutral
	-- so I've taken it out.
	["Artsakh"] = {divtype = {"unrecognized state", "country"}, parents = {"Azerbaijan", "Europe", "Asia"},
		keydesc = "the former de-facto independent state of [[Artsakh]], internationally recognized as part of [[Azerbaijan]]",
		british_spelling = true},
	-- British Overseas Territory
	["Ascension Island"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true},
	-- constituent country of the Netherlands
	["Aruba"] = {divtype = {"constituent country", "country"}, parents = {"Netherlands", "North America"}},
	-- British Overseas Territory
	["Bermuda"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "North America"},
		british_spelling = true},
	-- British Overseas Territory
	["the British Indian Ocean Territory"] = {
		divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "North America"},
		british_spelling = true
	},
	-- British Overseas Territory
	["the British Virgin Islands"] = {
		divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "North America"},
		british_spelling = true
	},
	-- British Overseas Territory
	["the Cayman Islands"] = {
		divtype = {"overseas territory", "territory"},
		parents = {"United Kingdom", "North America"},
		british_spelling = true
	},
	-- Australian external territory
	["Christmas Island"] = {
		divtype = {"external territory", "territory"}, parents = {"Australia", "Asia"},
		british_spelling = true
	},
	-- Australian external territory; also called the Keeling Islands or (officially) the Cocos (Keeling) Islands
	["the Cocos Islands"] = {
		divtype = {"external territory", "territory"}, parents = {"Australia", "Asia"},
		british_spelling = true,
		wp = "Cocos (Keeling) Islands"
	},
	-- self-governing but in free association with New Zealand
	["the Cook Islands"] = {divtype = {"country"}, parents = {"Polynesia", "New Zealand"}, british_spelling = true},
	-- constituent country of the Netherlands
	["Curaçao"] = {divtype = {"constituent country", "country"}, parents = {"Netherlands", "North America"}},
	-- special territory of Chile
	["Easter Island"] = {divtype = {"special territory", "territory"}, parents = {"Chile", "Polynesia"}},
	-- British Overseas Territory
	["the Falkland Islands"] = {
		divtype = {"overseas territory", "territory"},
		parents = {"United Kingdom", "South America"},
		british_spelling = true
	},
	-- autonomous territory of Denmark
	["the Faroe Islands"] = {divtype = {"autonomous territory", "territory"}, parents = {"Denmark", "Europe"}},
	-- overseas department of France
	["French Guiana"] = {divtype = {"overseas department", "department", "administrative region", "region"},
		parents = {"France", "South America"}},
	-- overseas collectivity of France
	["French Polynesia"] = {divtype = {"overseas collectivity", "collectivity"}, parents = {"France", "Polynesia"}},
	-- British Overseas Territory
	["Gibraltar"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "North America"},
		british_spelling = true},
	-- autonomous territory of Denmark
	["Greenland"] = {divtype = {"autonomous territory", "territory"}, parents = {"Netherlands", "North America"},
		poldiv = {"municipalities"}},
	-- overseas department of France
	["Guadeloupe"] = {divtype = {"overseas department", "department", "administrative region", "region"},
		parents = {"France", "North America"}},
	-- unincorporated territory of the United States
	["Guam"] = {divtype = {"unincorporated territory", "overseas territory", "territory"},
		parents = {"United States", "Micronesia"}},
	-- self-governing British Crown dependency; technically called the Bailiwick of Guernsey
	["Guernsey"] = {divtype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		parents = {"British Isles", "Europe"}, british_spelling = true},
	-- special administrative region of China
	["Hong Kong"] = {
		divtype = {"special administrative region", "city"}, miscdiv = {{type = "area", cat_as = "neighbourhoods"}},
		parents = {"China"}, is_city = true, british_spelling = true
	},
	-- self-governing British Crown dependency
	["the Isle of Man"] = {divtype = {"crown dependency", "dependency", "dependent territory", "territory"},
		parents = {"British Isles", "Europe"}, british_spelling = true},
	-- self-governing British Crown dependency; technically called the Bailiwick of Jersey
	["Jersey"] = {divtype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		parents = {"British Isles", "Europe"}, british_spelling = true},
	-- special administrative region of China
	["Macau"] = {
		divtype = {"special administrative region", "city"}, miscdiv = {{type = "area", cat_as = "neighbourhoods"}},
		parents = {"China"}, is_city = true, british_spelling = true
	},
	-- overseas department of France
	["Martinique"] = {divtype = {"overseas department", "department", "administrative region", "region"},
		parents = {"France", "North America"}},
	-- overseas department of France
	["Mayotte"] = {divtype = {"overseas department", "department", "administrative region", "region"},
		parents = {"France", "Africa"}},
	-- British Overseas Territory
	["Montserrat"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "North America"},
		british_spelling = true},
	-- special collectivity of France
	["New Caledonia"] = {divtype = {"special collectivity", "collectivity"}, parents = {"France", "Melanesia"}},
	-- self-governing but in free association with New Zealand
	["Niue"] = {divtype = {"country"}, parents = {"Polynesia", "New Zealand"}, british_spelling = true},
	-- Australian external territory
	["Norfolk Island"] = {divtype = {"external territory", "territory"}, parents = {"Australia", "Polynesia"},
		british_spelling = true},
	-- commonwealth, unincorporated territory of the United States
	["the Northern Mariana Islands"] = {
		divtype = {"commonwealth", "unincorporated territory", "overseas territory", "territory"},
		parents = {"United States", "Micronesia"}
	},
	-- British Overseas Territory
	["the Pitcairn Islands"] = {
		divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "Polynesia"},
		british_spelling = true
	},
	-- commonwealth of the United States
	["Puerto Rico"] = {
		divtype = {"commonwealth", "overseas territory", "territory"},
		parents = {"United States", "North America"},
		poldiv = {"municipalities"}
	},
	-- overseas department of France
	["Réunion"] = {divtype = {"overseas department", "department", "administrative region", "region"},
		parents = {"France", "Africa"}},
	-- overseas collectivity of France
	["Saint Barthélemy"] = {divtype = {"overseas collectivity", "collectivity"}, parents = {"France", "North America"}},
	-- British Overseas Territory
	["Saint Helena"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true},
	-- overseas collectivity of France
	["Saint Martin"] = {divtype = {"overseas collectivity", "collectivity"}, parents = {"France", "North America"}},
	-- overseas collectivity of France
	["Saint Pierre and Miquelon"] = {
		divtype = {"overseas collectivity", "collectivity"},
		parents = {"France", "North America"}
	},
	-- de-facto independent state, internationally recognized as part of Georgia
	["South Ossetia"] = {divtype = {"unrecognized state", "country"}, parents = {"Georgia", "Europe", "Asia"},
		keydesc = "the de-facto independent state of [[South Ossetia]], internationally recognized as part of the country of [[Georgia]]",
		british_spelling = true},
	-- constituent country of the Netherlands
	["Sint Maarten"] = {divtype = {"constituent country", "country"}, parents = {"Netherlands", "North America"}},
	-- British Overseas Territory
	["South Georgia"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true},
	-- British Overseas Territory
	["the South Sandwich Islands"] = {
		divtype = {"overseas territory", "territory"},
		parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true,
		wp = true, wpcat = "South Georgia and the South Sandwich Islands"
	},
	-- dependent territory of New Zealnd
	["Tokelau"] = {divtype = {"dependent territory", "territory"}, parents = {"New Zealand", "Polynesia"},
		british_spelling = true},
	-- de-facto independent state, internationally recognized as part of Moldova
	["Transnistria"] = {divtype = {"unrecognized state", "country"}, parents = {"Moldova", "Europe"},
		keydesc = "the de-facto independent state of [[Transnistria]], internationally recognized as part of [[Moldova]]",
		british_spelling = true},
	-- British Overseas Territory
	["Tristan da Cunha"] = {divtype = {"overseas territory", "territory"}, parents = {"United Kingdom", "Atlantic Ocean"},
		british_spelling = true},
	-- British Overseas Territory
	["the Turks and Caicos Islands"] = {
		divtype = {"overseas territory", "territory"},
		parents = {"United Kingdom", "North America"},
		british_spelling = true
	},
	-- unincorporated territory of the United States
	["the United States Virgin Islands"] = {divtype = {"unincorporated territory", "overseas territory", "territory"},
		parents = {"United States", "North America"}},
	-- unincorporated territory of the United States
	["Wake Island"] = {divtype = {"unincorporated territory", "overseas territory", "territory"},
		parents = {"United States", "North America"}},
	-- overseas collectivity of France
	["Wallis and Futuna"] = {divtype = {"overseas collectivity", "collectivity"}, parents = {"France", "Polynesia"}},
}

export.former_countries = {
	["Czechoslovakia"] = {parents = {"Europe"}, british_spelling = true},
	["East Germany"] = {parents = {"Europe", "Germany"}, british_spelling = true},
	["North Vietnam"] = {parents = {"Asia", "Vietnam"}},
	["Persia"] = {divtype = {"empire", "country"}, parents = {"Asia"}, poldiv = {"provinces"}},
	["the Roman Empire"] = {divtype = {"empire", "country"}, parents = {"Europe", "Africa", "Asia", "Rome"}, poldiv = {"provinces"}},
	["South Vietnam"] = {parents = {"Asia", "Vietnam"}},
	["the Soviet Union"] = {parents = {"Europe", "Asia"}, poldiv = {"republics", "autonomous republics"}, british_spelling = true},
	["West Germany"] = {parents = {"Europe", "Germany"}, british_spelling = true},
	["Yugoslavia"] = {parents = {"Europe"}, poldiv = {"districts"},
		keydesc = "the former [[Kingdom of Yugoslavia]] (1918–1943) or the former [[Socialist Federal Republic of Yugoslavia]] (1943–1992)", british_spelling = true},
}

-- countries
export.country_group = {
	bare_label_setter = simple_polity_bare_label_setter(),
	value_transformer = function(group, key, value)
		value.british_spelling = value.british_spelling or group.british_spelling
		return value
	end,
	default_divtype = "country",
	data = export.countries,
}

-- pseudo-countries: typically overseas territories or de-facto independent countries, which in both cases
-- are not internationally recognized as sovereign nations but which we treat similarly to countries.
export.pseudo_country_group = {	
	bare_label_setter = simple_polity_bare_label_setter({"Country-like entities"}),
	value_transformer = function(group, key, value)
		value.british_spelling = value.british_spelling or group.british_spelling
		return value
	end,
	default_divtype = "country",
	data = export.pseudo_countries,
}

-- former countries and such; we don't create "Cities in ..." categories because they don't exist anymore
export.former_country_group = {
	bare_label_setter = simple_polity_bare_label_setter({"Former countries and country-like entities"}),
	value_transformer = function(group, key, value)
		value.british_spelling = value.british_spelling or group.british_spelling
		value.is_former_place = true
		return value
	end,
	default_divtype = "country",
	data = export.former_countries,
}

-----------------------------------------------------------------------------------
--                           First-Level Subpolity Tables                        --
-----------------------------------------------------------------------------------

export.australia_states_and_territories = {
	["the Australian Capital Territory, Australia"] = {divtype = "territory"},
	["New South Wales, Australia"] = {},
	["the Northern Territory, Australia"] = {divtype = "territory"},
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
	bare_label_setter = subpolity_bare_label_setter("Australia"),
	value_transformer = subpolity_value_transformer("Australia"),
	default_divtype = "state",
	default_div_parent_type = "states and territories",
	default_poldiv = {"local government areas"},
	default_miscdiv = {{type = "ghost towns", prep = "in"}},
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Austria"),
	value_transformer = subpolity_value_transformer("Austria"),
	default_divtype = "state",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Bangladesh"),
	value_transformer = subpolity_value_transformer("Bangladesh"),
	default_divtype = "division",
	british_spelling = true,
	default_poldiv = "districts",
	data = export.bangladesh_divisions,
}

export.brazil_states = {
	["Acre"] = {},
	["Alagoas"] = {},
	["Amapá"] = {},
	["Amazonas"] = {},
	["Bahia"] = {},
	["Ceará"] = {},
	["Distrito Federal"] = {},
	["Espírito Santo"] = {},
	["Goiás"] = {},
	["Maranhão"] = {},
	["Mato Grosso"] = {},
	["Mato Grosso do Sul"] = {},
	["Minas Gerais"] = {},
	["Pará"] = {},
	["Paraíba"] = {},
	["Paraná"] = {},
	["Pernambuco"] = {},
	["Piauí"] = {},
	["Rio de Janeiro"] = {},
	["Rio Grande do Norte"] = {},
	["Rio Grande do Sul"] = {},
	["Rondônia"] = {},
	["Roraima"] = {},
	["Santa Catarina"] = {},
	["São Paulo"] = {},
	["Sergipe"] = {},
	["Tocantins"] = {},
}

-- states of Brazil
export.brazil_group = {
	containing_polity = {name = "Brazil", divtype = "country"},
	key_to_placename = make_key_to_placename(", Brazil$"),
	placename_to_key = make_placename_to_key(", Brazil"),
	bare_label_setter = subpolity_bare_label_setter(),
	value_transformer = subpolity_value_transformer(),
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
	["New Brunswick, Canada"] = {poldiv = {"counties"}},
	["Newfoundland and Labrador, Canada"] = {},
	["the Northwest Territories, Canada"] = {divtype = "territory"},
	["Nova Scotia, Canada"] = {poldiv = {"counties", "regional municipalities"}},
	["Nunavut, Canada"] = {divtype = "territory"},
	["Ontario, Canada"] = {poldiv = {"counties", "regional municipalities", {type = "townships", prep = "in"}}},
	["Prince Edward Island, Canada"] = {poldiv = {"counties", "rural municipalities"}},
	["Saskatchewan, Canada"] = {poldiv = {"rural municipalities"}},
	["Quebec, Canada"] = {poldiv = {
		"counties",
		{type = "regional county municipalities", skip_polity_parent_type = "regional municipalities"},
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
	bare_label_setter = subpolity_bare_label_setter("Canada"),
	value_transformer = subpolity_value_transformer("Canada"),
	default_divtype = "province",
	default_div_parent_type = "provinces and territories",
	default_miscdiv = {{type = "ghost towns", prep = "in"}},
	british_spelling = true,
	data = export.canada_provinces_and_territories,
}

-- table of provinces and autonomous regions of China; interpolated into the main 'places' table, but also needed
-- separately
export.china_provinces_and_autonomous_regions = {
	["Anhui, China"] = {},
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
	["Shanxi, China"] = {},
	["Sichuan, China"] = {},
	["Tibet, China"] = {divtype = "autonomous region"},
	["Xinjiang, China"] = {divtype = "autonomous region"},
	["Yunnan, China"] = {},
	["Zhejiang, China"] = {},
}

-- provinces and autonomous regions of China
export.china_group = {
	key_to_placename = make_key_to_placename(", China$"),
	placename_to_key = make_placename_to_key(", China"),
	bare_label_setter = subpolity_bare_label_setter("China"),
	value_transformer = subpolity_value_transformer("China"),
	default_divtype = "province",
	default_div_parent_type = "provinces and autonomous regions",
	data = export.china_provinces_and_autonomous_regions,
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
	["the Åland Islands, Finland"] = {},
}

-- regions of Finland
export.finland_group = {
	key_to_placename = make_key_to_placename(", Finland$"),
	placename_to_key = make_placename_to_key(", Finland"),
	bare_label_setter = subpolity_bare_label_setter("Finland"),
	value_transformer = subpolity_value_transformer("Finland"),
	default_divtype = "region",
	default_poldiv = "municipalities",
	british_spelling = true,
	data = export.finland_regions,
}

export.france_administrative_regions = {
	["Auvergne-Rhône-Alpes, France"] = {},
	["Bourgogne-Franche-Comté, France"] = {},
	["Brittany, France"] = {},
	["Centre-Val de Loire, France"] = {},
	["Corsica, France"] = {},
	-- overseas departments are handled in `export.pseudo_countries`
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
	bare_label_setter = subpolity_bare_label_setter("France"),
	value_transformer = subpolity_value_transformer("France"),
	-- Canonically these are 'administrative regions' but also categorize if identified as a 'region'.
	default_divtype = {"administrative region", "region"},
	default_div_parent_type = "regions",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Germany"),
	value_transformer = subpolity_value_transformer("Germany"),
	default_divtype = "state",
	default_poldiv = "districts",
	british_spelling = true,
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
	["the Andaman and Nicobar Islands, India"] = {divtype = "union territory", poldiv = india_polity_without_divisions},
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
	bare_label_setter = subpolity_bare_label_setter("India"),
	value_transformer = subpolity_value_transformer("India"),
	default_divtype = "state",
	default_div_parent_type = "states and union territories",
	british_spelling = true,
	data = export.india_states_and_union_territories,
}

export.indonesia_provinces = {
	["Aceh, Indonesia"] = {},
	["Bali, Indonesia"] = {},
	["the Bangka Belitung Islands, Indonesia"] = {},
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
	["the Special Capital Region of Jakarta, Indonesia"] = {},
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
	["the Riau Islands, Indonesia"] = {},
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
	["the Special Region of Yogyakarta, Indonesia"] = {},
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
	bare_label_setter = subpolity_bare_label_setter("Indonesia"),
	value_transformer = subpolity_value_transformer("Indonesia"),
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
	bare_label_setter = subpolity_bare_label_setter("Ireland"),
	value_transformer = subpolity_value_transformer("Ireland"),
	default_divtype = "county",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Italy"),
	value_transformer = subpolity_value_transformer("Italy"),
	default_divtype = {"administrative region", "region"},
	default_div_parent_type = "regions",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Japan"),
	value_transformer = subpolity_value_transformer("Japan"),
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
	bare_label_setter = subpolity_bare_label_setter("North Korea"),
	value_transformer = subpolity_value_transformer("North Korea"),
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
	bare_label_setter = subpolity_bare_label_setter("South Korea"),
	value_transformer = subpolity_value_transformer("South Korea"),
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
	bare_label_setter = subpolity_bare_label_setter("Laos"),
	value_transformer = subpolity_value_transformer("Laos"),
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
	["North Governorate, Lebanon"] = {},
	["South Governorate, Lebanon"] = {},
}

-- governorates of Lebanon
export.lebanon_group = {
	key_to_placename = make_key_to_placename(", Lebanon$", " Governorate$"),
	placename_to_key = make_placename_to_key(", Lebanon", " Governorate"),
	bare_label_setter = subpolity_bare_label_setter("Lebanon"),
	value_transformer = subpolity_value_transformer("Lebanon"),
	default_divtype = "governorate",
	-- The governorates are too generic in name. For example, "North Governorate" exists elsewhere.
	no_containing_polity_cat = true,
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
	bare_label_setter = subpolity_bare_label_setter("Malaysia"),
	value_transformer = subpolity_value_transformer("Malaysia"),
	default_divtype = "state",
	british_spelling = true,
	data = export.malaysia_states,
}

export.malta_regions = {
	["Eastern Region, Malta"] = {},
	["Gozo Region, Malta"] = {},
	["Northern Region, Malta"] = {},
	["Port Region, Malta"] = {},
	["Southern Region, Malta"] = {},
	["Western Region, Malta"] = {},
}

-- regions of Malta
export.malta_group = {
	key_to_placename = make_key_to_placename(", Malta$", " Region"),
	placename_to_key = make_placename_to_key(", Malta", " Region"),
	bare_label_setter = subpolity_bare_label_setter("Malta"),
	value_transformer = subpolity_value_transformer("Malta"),
	default_divtype = "region",
	british_spelling = true,
	-- The regions are too generic in name. For example, "Central Region" exists elsewhere, e.g. in South Africa.
	no_containing_polity_cat = true,
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
	["the State of Mexico, Mexico"] = {},
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
	-- See description of `key_to_placename()`; passed-in placenames *will* have "the" prepended, and the returned
	-- placenames should also, except for the elliptical variants when they exist (as in the case of the State of
	-- Mexico, whose elliptial form is just "Mexico").
	key = key:gsub(", Mexico$", "")
	if key == "the State of Mexico" then
		return key, "Mexico"
	else
		return key, key
	end
end

local function mexico_placename_to_key(placename)
	-- See description of `placename_to_key()`; passed-in placenames will *not* have "the" prepended, and the returned
	-- keys should not, either.
	if placename == "Mexico" then
		placename = "State of Mexico"
	end
	return placename .. ", Mexico"
end

-- Mexican states
export.mexico_group = {
	key_to_placename = mexico_key_to_placename,
	placename_to_key = mexico_placename_to_key,
	bare_label_setter = subpolity_bare_label_setter("Mexico"),
	value_transformer = subpolity_value_transformer("Mexico"),
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
	bare_label_setter = subpolity_bare_label_setter("Morocco"),
	value_transformer = subpolity_value_transformer("Morocco"),
	default_divtype = "region",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("the Netherlands"),
	value_transformer = subpolity_value_transformer("the Netherlands"),
	default_divtype = "province",
	default_poldiv = "municipalities",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Nigeria"),
	value_transformer = subpolity_value_transformer("Nigeria"),
	default_divtype = "state",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Norway"),
	value_transformer = subpolity_value_transformer("Norway"),
	default_divtype = "county",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Pakistan"),
	value_transformer = subpolity_value_transformer("Pakistan"),
	default_divtype = "province",
	default_div_parent_type = "provinces and territories",
	default_poldiv = {"divisions"},
	british_spelling = true,
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
	["the Dinagat Islands, Philippines"] = {},
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
	bare_label_setter = subpolity_bare_label_setter("the Philippines"),
	value_transformer = subpolity_value_transformer("the Philippines"),
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
	bare_label_setter = subpolity_bare_label_setter("Romania"),
	value_transformer = subpolity_value_transformer("Romania"),
	default_divtype = "county",
	british_spelling = true,
	data = export.romania_counties,
}

local function make_russia_federal_subject_spec(spectype)
	return {divtype = spectype, div_parent_type = {"federal subjects", spectype .. "s"}}
end

local russia_autonomous_okrug =
	{divtype = {"autonomous okrug", "okrug"}, div_parent_type = {"federal subjects", "autonomous okrugs"}}
local russia_krai = make_russia_federal_subject_spec("krai")
local russia_oblast = make_russia_federal_subject_spec("oblast")
local russia_republic = make_russia_federal_subject_spec("republic")
export.russia_federal_subjects = {
	-- autonomous oblasts
	["the Jewish Autonomous Oblast"] =
		{divtype = {"autonomous oblast", "oblast"}, div_parent_type = {"federal subjects", "autonomous oblasts"}},
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
	["the Republic of Adygea"] = russia_republic,
	["the Republic of Bashkortostan"] = russia_republic,
	["the Republic of Buryatia"] = russia_republic,
	["the Republic of Dagestan"] = russia_republic,
	["the Republic of Ingushetia"] = russia_republic,
	["the Republic of Kalmykia"] = russia_republic,
	["the Republic of Karelia"] = russia_republic,
	["the Republic of Khakassia"] = russia_republic,
	["the Republic of Mordovia"] = russia_republic,
	["the Republic of North Ossetia-Alania"] = russia_republic,
	["the Republic of Tatarstan"] = russia_republic,
	["the Altai Republic"] = russia_republic,
	["the Chechen Republic"] = russia_republic,
	["the Chuvash Republic"] = russia_republic,
	["the Kabardino-Balkar Republic"] = russia_republic,
	["the Karachay-Cherkess Republic"] = russia_republic,
	["the Komi Republic"] = russia_republic,
	["the Mari El Republic"] = russia_republic,
	["the Sakha Republic"] = russia_republic,
	["the Tuva Republic"] = russia_republic,
	["the Udmurt Republic"] = russia_republic,
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

local function construct_russia_federal_subject_keydesc(linked_key, divtype)
	if divtype == "oblast" then
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
	bare_label_setter = function(labels, group, key, value)
		local divtype = value.divtype or group.default_divtype
		if type(divtype) == "table" then
			divtype = divtype[1]
		end
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		labels[bare_key] = {
			type = "topic",
			description = "{{{langname}}} terms related to " .. construct_russia_federal_subject_keydesc(linked_key, divtype) .. ".",
			parents = {"federal subjects of Russia", require(en_utilities_module).pluralize(divtype) .. " of Russia"},
		}
	end,
	value_transformer = function(group, key, value)
		value.containing_polity = "Russia"
		local divtype = value.divtype or group.default_divtype
		if type(divtype) == "table" then
			divtype = divtype[1]
		end
		local bare_key, linked_key = export.construct_bare_and_linked_version(key)
		value.keydesc = construct_russia_federal_subject_keydesc(linked_key, divtype)
		return value
	end,
	british_spelling = true,
	data = export.russia_federal_subjects,
}

export.saudi_arabia_provinces = {
	["Riyadh Province, Saudi Arabia"] = {},
	["Mecca Province, Saudi Arabia"] = {},
	["Eastern Province, Saudi Arabia"] = {},
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
	bare_label_setter = subpolity_bare_label_setter("Saudi Arabia"),
	value_transformer = subpolity_value_transformer("Saudi Arabia"),
	default_divtype = "province",
	-- The regions are too generic in name. For example, "Eastern Region" exists elsewhere.
	no_containing_polity_cat = true,
	data = export.saudi_arabia_provinces,
}

export.spain_autonomous_communities = {
	["Andalusia, Spain"] = {},
	["Aragon, Spain"] = {},
	["Asturias, Spain"] = {},
	["the Balearic Islands, Spain"] = {},
	["the Basque Country, Spain"] = {},
	["the Canary Islands, Spain"] = {},
	["Cantabria, Spain"] = {},
	["Castile and León, Spain"] = {},
	["Castilla-La Mancha, Spain"] = {},
	["Catalonia, Spain"] = {},
	["the Community of Madrid, Spain"] = {},
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
	bare_label_setter = subpolity_bare_label_setter("Spain"),
	value_transformer = subpolity_value_transformer("Spain"),
	default_divtype = "autonomous community",
	british_spelling = true,
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
	bare_label_setter = subpolity_bare_label_setter("Taiwan"),
	value_transformer = subpolity_value_transformer("Taiwan"),
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
	bare_label_setter = subpolity_bare_label_setter("Thailand"),
	value_transformer = subpolity_value_transformer("Thailand"),
	default_divtype = "province",
	default_poldiv = "districts",
	data = export.thailand_provinces,
}

export.uk_constituent_countries = {
	["England"] = {poldiv = {
		"counties",
		"districts",
		{type = "local government districts", cat_as = "districts"},
		{
			type = "local government districts with borough status",
			sgdiv = "local government district with borough status",
			cat_as = {"districts", "boroughs"},
		},
		{type = "boroughs", cat_as = {"districts", "boroughs"}},
		{type = "civil parishes", skip_polity_parent_type = false},
	}, miscdiv = {"regions", "traditional counties"}},
	["Northern Ireland"] = {
		divtype = {"province", "constituent country", "country"},
		div_parent_type = "constituent countries",
		poldiv = {"counties", "districts"},
	},
	["Scotland"] = {
		poldiv = {{type = "council areas", skip_polity_parent_type = false}},
		miscdiv = {"regions", "districts", "traditional counties"},
	},
	["Wales"] = {poldiv = {
		"counties",
		{type = "county boroughs", skip_polity_parent_type = false},
		{type = "communities", skip_polity_parent_type = false},
	}},
}

-- constituent countries and provinces of the United Kingdom
export.uk_group = {
	bare_label_setter = subpolity_bare_label_setter("the United Kingdom"),
	value_transformer = subpolity_value_transformer("the United Kingdom"),
	default_divtype = {"constituent country", "country"},
	british_spelling = true,
	-- Don't create categories like 'Category:en:Towns in the United Kingdom'
	-- or 'Category:en:Places in the United Kingdom'.
	no_containing_polity_cat = true,
	data = export.uk_constituent_countries,
}

-- table of US states; interpolated into the main 'places' table, but also needed separately
export.us_states = {
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
	["Hawaii, USA"] = {},
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
export.us_group = {
	key_to_placename = make_key_to_placename(", USA$"),
	placename_to_key = make_placename_to_key(", USA"),
	bare_label_setter = subpolity_bare_label_setter("the United States"),
	value_transformer = subpolity_value_transformer("the United States"),
	default_divtype = "state",
	default_poldiv = {
		"counties",
		"county seats",
	},
	default_miscdiv = {
		{type = "census-designated places", prep = "in"},
		{type = "ghost towns", prep = "in"},
	},
	data = export.us_states,
}

-----------------------------------------------------------------------------------
--                          Second-Level Subpolity Tables                        --
-----------------------------------------------------------------------------------

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
	-- ["the Isle of Ely, England"] = {}, -- no longer
	["the Isle of Wight, England"] = {},
	["Kent, England"] = {},
	["Lancashire, England"] = {},
	["Leicestershire, England"] = {},
	["Lincolnshire, England"] = {},
	-- ["the County of London, England"] = {}, -- no longer
	["Merseyside, England"] = {},
	-- ["Middlesex, England"] = {}, -- no longer
	["Norfolk, England"] = {},
	["Northamptonshire, England"] = {},
	["Northumberland, England"] = {},
	-- ["North Humberside, England"] = {}, -- no longer
	["North Yorkshire, England"] = {},
	["Nottinghamshire, England"] = {},
	["Oxfordshire, England"] = {},
	-- ["the Soke of Peterborough, England"] = {}, -- no longer
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
	["the West Midlands, England"] = {},
	-- ["Westmorland, England"] = {}, -- no longer
	-- ["West Suffolk, England"] = {}, -- no longer
	["West Sussex, England"] = {},
	["West Yorkshire, England"] = {},
	["Wiltshire, England"] = {},
	["Worcestershire, England"] = {},
	-- ["Yorkshire, England"] = {}, -- no longer
	["the East Riding of Yorkshire, England"] = {},
	-- ["the North Riding of Yorkshire, England"] = {}, -- no longer
	-- ["the West Riding of Yorkshire, England"] = {}, -- no longer
}

-- counties of England
export.england_group = {
	key_to_placename = make_key_to_placename(", England$"),
	placename_to_key = make_placename_to_key(", England"),
	bare_label_setter = subpolity_bare_label_setter("England"),
	value_transformer = subpolity_value_transformer({"constituent country", "England"}),
	default_divtype = "county",
	default_poldiv = {
		"districts",
		{type = "local government districts", cat_as = "districts"},
		{
			type = "local government districts with borough status",
			sgdiv = "local government district with borough status",
			cat_as = {"districts", "boroughs"},
		},
		{type = "boroughs", cat_as = {"districts", "boroughs"}},
		"civil parishes",
	},
	british_spelling = true,
	data = export.england_counties,
}

export.northern_ireland_counties = {
	["County Antrim, Northern Ireland"] = {},
	["County Armagh, Northern Ireland"] = {},
	["the City of Belfast, Northern Ireland"] = {is_city = true},
	["County Down, Northern Ireland"] = {},
	["County Fermanagh, Northern Ireland"] = {},
	["County Londonderry, Northern Ireland"] = {},
	["the City of Derry, Northern Ireland"] = {is_city = true},
	["County Tyrone, Northern Ireland"] = {},
}

-- counties of Northern Ireland
export.northern_ireland_group = {
	key_to_placename = make_irish_type_key_to_placename(", Northern Ireland$"),
	placename_to_key = make_irish_type_placename_to_key(", Northern Ireland"),
	bare_label_setter = subpolity_bare_label_setter("Northern Ireland"),
	value_transformer = subpolity_value_transformer({"constituent country", "Northern Ireland"}),
	default_divtype = "county",
	british_spelling = true,
	data = export.northern_ireland_counties,
}

export.scotland_council_areas = {
	["the City of Glasgow, Scotland"] = {},
	["the City of Edinburgh, Scotland"] = {},
	["Fife, Scotland"] = {},
	["North Lanarkshire, Scotland"] = {},
	["South Lanarkshire, Scotland"] = {},
	["Aberdeenshire, Scotland"] = {},
	["Highland, Scotland"] = {},
	["the City of Aberdeen, Scotland"] = {},
	["West Lothian, Scotland"] = {},
	["Renfrewshire, Scotland"] = {},
	["Falkirk, Scotland"] = {},
	["Perth and Kinross, Scotland"] = {},
	["Dumfries and Galloway, Scotland"] = {},
	["the City of Dundee, Scotland"] = {},
	["North Ayrshire, Scotland"] = {},
	["East Ayrshire, Scotland"] = {},
	["Angus, Scotland"] = {},
	["the Scottish Borders, Scotland"] = {},
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
	["the Shetland Islands, Scotland"] = {},
	["the Orkney Islands, Scotland"] = {},
}

-- council areas of Scotland
export.scotland_group = {
	key_to_placename = make_key_to_placename(", Scotland$"),
	placename_to_key = make_placename_to_key(", Scotland"),
	bare_label_setter = subpolity_bare_label_setter("Scotland"),
	value_transformer = subpolity_value_transformer({"constituent country", "Scotland"}),
	default_divtype = "council area",
	british_spelling = true,
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
	["the Isle of Anglesey, Wales"] = {divtype = "county"},
	["Merthyr Tydfil, Wales"] = {},
	["Monmouthshire, Wales"] = {divtype = "county"},
	["Neath Port Talbot, Wales"] = {},
	-- ["Newport, Wales"] = {divtype = "city"},
	["Pembrokeshire, Wales"] = {divtype = "county"},
	["Powys, Wales"] = {divtype = "county"},
	["Rhondda Cynon Taf, Wales"] = {},
	-- ["Swansea, Wales"] = {divtype = "city"},
	["Torfaen, Wales"] = {},
	["the Vale of Glamorgan, Wales"] = {},
	["Wrexham, Wales"] = {},
}

-- principal areas (cities, counties and county boroughs) of Wales
export.wales_group = {
	key_to_placename = make_key_to_placename(", Wales$"),
	placename_to_key = make_placename_to_key(", Wales"),
	bare_label_setter = subpolity_bare_label_setter("Wales"),
	value_transformer = subpolity_value_transformer({"constituent country", "Wales"}),
	default_divtype = "county borough",
	british_spelling = true,
	data = export.wales_principal_areas,
}

-----------------------------------------------------------------------------------
--                                     City Tables                               --
-----------------------------------------------------------------------------------

export.new_york_boroughs = {
	["Bronx"] = true,
	["Brooklyn"] = true,
	["Manhattan"] = true,
	["Queens"] = true,
	["Staten Island"] = true,
}

--[==[
City data.

Each entry in `export.cities` is a group of cities under a single overarching containing polity (typically a country).
Each group contains the following fields:

* `skip_parents`: A containing polity spec or list of such specs, giving the overarching containing polity or
  polities (normally top-level) that all cities in the group belong to. Containing polity specs are described below
  for the immediate containing polity (under the `data` field below). Generally the overarching `containing_polities`
  field of the group contains a single polity in the table format (so that the divtype can be given), but in some cases
  it is an empty list.
* `default_divtype`: The default divtype (in the singlar) of the immediate containing polity of the city (normally a
  political subdivision of the overarching containing polity in `containing_polities`).
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
export.cities = {
	{
		default_parent_divtype = "state",
		skip_parents = {name = "Australia", divtype = "country"},
		data = {
			["Adelaide"] = {parents = "South Australia"},
			["Brisbane"] = {parents = "Queensland"},
			["Canberra"] = {parents = {name = "the Australian Capital Territory", divtype = "territory"}},
			["Melbourne"] = {parents = "Victoria"},
			["Newcastle, New South Wales"] = {parents = "New South Wales"},
			["Newcastle"] = {alias_of = "Newcastle, New South Wales"},
			["Perth"] = {parents = "Western Australia"},
			["Sydney"] = {parents = "New South Wales"},
		},
	},
	{
		default_parent_divtype = "state",
		skip_parents = {name = "Brazil", divtype = "country"},
		data = {
			-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
			["São Paulo"] = {parents = "São Paulo"},
			["Rio de Janeiro"] = {parents = "Rio de Janeiro"},
			["Brasília"] = {parents = "Distrito Federal"},
			["Brasilia"] = {alias_of = "Brasília"},
			["Salvador"] = {parents = "Bahia", wp = "%c, %d", commonscat = "%c (%d)"},
			["Fortaleza"] = {parents = "Ceará"},
			["Belo Horizonte"] = {parents = "Minas Gerais"},
			["Manaus"] = {parents = "Amazonas"},
			["Curitiba"] = {parents = "Paraná"},
			["Recife"] = {parents = "Pernambuco"},
			["Goiânia"] = {parents = "Goiás"},
			["Goiania"] = {alias_of = "Goiânia"},
			["Belém"] = {parents = "Pará"},
			["Belem"] = {alias_of = "Belém"},
			["Porto Alegre"] = {parents = "Rio Grande do Sul"},
			["Guarulhos"] = {parents = "São Paulo"},
			["Campinas"] = {parents = "São Paulo"},
		},
	},
	{
		default_parent_divtype = "province",
		skip_parents = {name = "Canada", divtype = "country"},
		data = {
			["Toronto"] = {parents = "Ontario"},
			["Montreal"] = {parents = "Quebec"},
			["Vancouver"] = {parents = "British Columbia"},
			["Calgary"] = {parents = "Alberta"},
			["Edmonton"] = {parents = "Alberta"},
			["Ottawa"] = {parents = "Ontario"},
			["Winnipeg"] = {parents = "Manitoba"},
			["Quebec City"] = {parents = "Quebec"},
			["Hamilton"] = {parents = "Ontario", wp = "%c, %d"},
			["Kitchener"] = {parents = "Ontario", wp = "%c, %d"},
		},
	},
	{
		default_parent_divtype = "province",
		skip_parents = {name = "China", divtype = "country"},
		data = {
			-- This only lists the top 50. Per [[w:List of cities in China by population]], there
			-- are 102 cities over 1,000,000 inhabitants, not to mention metro areas. Our coverage
			-- of China is fairly sparse; when it increases, add to this list.
			["Shanghai"] = {},
			["Beijing"] = {},
			["Guangzhou"] = {parents = "Guangdong"},
			["Shenzhen"] = {parents = "Guangdong"},
			["Tianjin"] = {},
			["Wuhan"] = {parents = "Hubei"},
			["Dongguan"] = {parents = "Guangdong"},
			["Chengdu"] = {parents = "Sichuan"},
			["Foshan"] = {parents = "Guangdong"},
			["Chongqing"] = {},
			["Nanjing"] = {parents = "Jiangsu"},
			["Shenyang"] = {parents = "Liaoning"},
			["Hangzhou"] = {parents = "Zhejiang"},
			["Xi'an"] = {parents = "Shaanxi"},
			["Harbin"] = {parents = "Heilongjiang"},
			["Suzhou"] = {parents = "Jiangsu"},
			["Qingdao"] = {parents = "Shandong"},
			["Dalian"] = {parents = "Liaoning"},
			["Zhengzhou"] = {parents = "Henan"},
			["Shantou"] = {parents = "Guangdong"},
			["Jinan"] = {parents = "Shandong"},
			["Changchun"] = {parents = "Jilin"},
			["Kunming"] = {parents = "Yunnan"},
			["Changsha"] = {parents = "Hunan"},
			["Taiyuan"] = {parents = "Shanxi"},
			["Xiamen"] = {parents = "Fujian"},
			["Hefei"] = {parents = "Anhui"},
			["Shijiazhuang"] = {parents = "Hebei"},
			["Ürümqi"] = {parents = {name = "Xinjiang", divtype = "autonomous region"}},
			["Urumqi"] = {alias_of = "Ürümqi"},
			["Fuzhou"] = {parents = "Fujian"},
			["Wuxi"] = {parents = "Jiangsu"},
			["Zhongshan"] = {parents = "Guangdong"},
			["Wenzhou"] = {parents = "Zhejiang"},
			["Nanning"] = {parents = {name = "Guangxi", divtype = "autonomous region"}},
			["Nanchang"] = {parents = "Jiangxi"},
			["Ningbo"] = {parents = "Zhejiang"},
			["Guiyang"] = {parents = "Guizhou"},
			["Lanzhou"] = {parents = "Gansu"},
			["Zibo"] = {parents = "Shandong"},
			["Changzhou"] = {parents = "Jiangsu"},
			["Xuzhou"] = {parents = "Jiangsu"},
			["Tangshan"] = {parents = "Hebei"},
			["Baotou"] = {parents = {name = "Inner Mongolia", divtype = "autonomous region"}},
			["Huizhou"] = {parents = "Guangdong"},
			["Yantai"] = {parents = "Shandong"},
			["Shaoxing"] = {parents = "Zhejiang"},
			["Liuzhou"] = {parents = {name = "Guangxi", divtype = "autonomous region"}},
			["Nantong"] = {parents = "Jiangsu"},
			["Luoyang"] = {parents = "Henan"},
			["Yangzhou"] = {parents = "Jiangsu"},
		},
	},
	{
		default_parent_divtype = "administrative region",
		skip_parents = {name = "France", divtype = "country"},
		data = {
			["Paris"] = {parents = "Île-de-France"},
			["Lyon"] = {parents = "Auvergne-Rhône-Alpes"},
			["Lyons"] = {alias_of = "Lyon"},
			["Marseille"] = {parents = "Provence-Alpes-Côte d'Azur"},
			["Marseilles"] = {alias_of = "Marseille"},
			["Toulouse"] = {parents = "Occitania"},
			["Lille"] = {parents = "Hauts-de-France"},
			["Bordeaux"] = {parents = "Nouvelle-Aquitaine"},
			["Nice"] = {parents = "Provence-Alpes-Côte d'Azur"},
			["Nantes"] = {parents = "Pays de la Loire"},
			["Strasbourg"] = {parents = "Grand Est"},
			["Rennes"] = {parents = "Brittany"},
		},
	},
	{
		default_parent_divtype = "state",
		skip_parents = {name = "Germany", divtype = "country"},
		data = {
			["Berlin"] = {},
			["Dortmund"] = {parents = "North Rhine-Westphalia"},
			["Essen"] = {parents = "North Rhine-Westphalia"},
			["Duisberg"] = {parents = "North Rhine-Westphalia"},
			["Hamburg"] = {},
			["Munich"] = {parents = "Bavaria"},
			["Stuttgart"] = {parents = "Baden-Württemberg"},
			["Frankfurt"] = {parents = "Hesse"},
			["Cologne"] = {parents = "North Rhine-Westphalia"},
			["Düsseldorf"] = {parents = "North Rhine-Westphalia"},
			["Dusseldorf"] = {alias_of = "Düsseldorf"},
			["Nuremberg"] = {parents = "Bavaria"},
			["Bremen"] = {},
		},
	},
	{
		default_parent_divtype = "state",
		skip_parents = {name = "India", divtype = "country"},
		data = {
			-- This only lists the top 20. Per [[w:List of cities in India by population]], there
			-- are 46 cities over 1,000,000 inhabitants, not to mention metro areas. Our coverage
			-- of India is fairly sparse; when it increases, add to this list.
			["Mumbai"] = {parents = "Maharashtra"},
			["Delhi"] = {},
			["Bangalore"] = {parents = "Karnataka"},
			["Hyderabad"] = {parents = "Telangana"},
			["Ahmedabad"] = {parents = "Gujarat"},
			["Chennai"] = {parents = "Tamil Nadu"},
			["Kolkata"] = {parents = "West Bengal"},
			["Surat"] = {parents = "Gujarat"},
			["Pune"] = {parents = "Maharashtra"},
			["Jaipur"] = {parents = "Rajasthan"},
			["Lucknow"] = {parents = "Uttar Pradesh"},
			["Kanpur"] = {parents = "Uttar Pradesh"},
			["Nagpur"] = {parents = "Maharashtra"},
			["Indore"] = {parents = "Madhya Pradesh"},
			["Thane"] = {parents = "Maharashtra"},
			["Bhopal"] = {parents = "Madhya Pradesh"},
			["Visakhapatnam"] = {parents = "Andhra Pradesh"},
			["Pimpri-Chinchwad"] = {parents = "Maharashtra"},
			["Patna"] = {parents = "Bihar"},
			["Vadodara"] = {parents = "Gujarat"},

			-- After top 20
			["Jabalpur"] = {parents = "Madhya Pradesh"},
		},
	},
	{
		default_parent_divtype = "prefecture",
		skip_parents = {name = "Japan", divtype = "country"},
		data = {
			-- Population figures from [[w:List of cities in Japan]]. Metro areas from
			-- [[w:List of metropolitan areas in Japan]].
			["Tokyo"] = {}, -- no single figure given for Tokyo as a whole.
			["Yokohama"] = {parents = "Kanagawa"}, -- 3,697,894
			["Osaka"] = {parents = "Osaka"}, -- 2,668,586
			["Nagoya"] = {parents = "Aichi"}, -- 2,283,289
			-- FIXME, Hokkaido is handled specially.
			["Sapporo"] = {parents = "Hokkaido"}, -- 1,918,096
			["Fukuoka"] = {parents = "Fukuoka"}, -- 1,581,527
			["Kobe"] = {parents = "Hyōgo"}, -- 1,530,847
			["Kyoto"] = {parents = "Kyoto"}, -- 1,474,570
			["Kawasaki"] = {parents = "Kanagawa", wp = "%c, %d"}, -- 1,373,630
			["Saitama"] = {parents = "Saitama", wp = "%c (city)", commonscat = "%c, %d"}, -- 1,192,418
			["Hiroshima"] = {parents = "Hiroshima"}, -- 1,163,806
			["Sendai"] = {parents = "Miyagi"}, -- 1,029,552
			-- the remaining cities are considered "central cities" in a 1,000,000+ metro area
			-- (sometimes there is more than one central city in the area).
			["Kitakyushu"] = {parents = "Fukuoka"}, -- 986,998
			["Chiba"] = {parents = "Chiba", wp = "%c (city)", commonscat = "%c, %d"}, -- 938,695
			["Sakai"] = {parents = "Osaka"}, -- 835,333
			["Niigata"] = {parents = "Niigata", wp = "%c (city)", commonscat = "%c, %d"}, -- 813,053
			["Hamamatsu"] = {parents = "Shizuoka"}, -- 811,431
			["Shizuoka"] = {parents = "Shizuoka", wp = "%c (city)", commonscat = "%c, %d"}, -- 710,944
			["Sagamihara"] = {parents = "Kanagawa"}, -- 706,342
			["Okayama"] = {parents = "Okayama"}, -- 701,293
			["Kumamoto"] = {parents = "Kumamoto"}, -- 670,348
			["Kagoshima"] = {parents = "Kagoshima"}, -- 605,196
			-- skipped 6 cities (Funabashi, Hachiōji, Kawaguchi, Himeji, Matsuyama, Higashiōsaka)
			-- with population in the range 509k - 587k because not central cities in any
			-- 1,000,000+ metro area.
			["Utsunomiya"] = {parents = "Tochigi"}, -- 507,833
		},
	},
	{
		default_parent_divtype = "province",
		skip_parents = {name = "South Korea", divtype = "country"},
		data = { 
			-- all cities listed are not associated with any province.
			["Seoul"] = {},
			["Busan"] = {},
			["Incheon"] = {},
			["Daegu"] = {},
			["Daejeon"] = {},
			["Gwangju"] = {},
			["Ulsan"] = {},
		},
	},
	{
		default_parent_divtype = "state",
		skip_parents = {name = "Mexico", divtype = "country"},
		data = {
			["Mexico City"] = {}, -- its own state
			["Monterrey"] = {parents = "Nuevo León"},
			["Guadalajara"] = {parents = "Jalisco"},
			["Puebla"] = {parents = "Puebla"},
			["Toluca"] = {parents = "the State of Mexico"},
			["Tijuana"] = {parents = "Baja California"},
			["León"] = {parents = "Guanajuato"},
			["Leon"] = {alias_of = "Leon"},
			["Querétaro"] = {parents = "Querétaro"},
			["Queretaro"] = {alias_of = "Querétaro"},
			["Ciudad Juárez"] = {parents = "Chihuahua"},
			["Juárez"] = {alias_of = "Ciudad Juárez"},
			["Juarez"] = {alias_of = "Ciudad Juárez"},
			["Torreón"] = {parents = "Coahuila"},
			["Torreon"] = {alias_of = "Torreón"},
			["Mérida"] = {parents = "Yucatán"},
			["Merida"] = {alias_of = "Mérida"},
			["San Luis Potosí"] = {parents = "San Luis Potosí"},
			["San Luis Potosi"] = {alias_of = "San Luis Potosí"},
			["Aguascalientes"] = {parents = "Aguascalientes"},
			["Mexicali"] = {parents = "Baja California"},
		},
	},
	{
		default_parent_divtype = "province",
		skip_parents = {name = "the Philippines", divtype = "country"},
		data = { 
			 --some cities listed independent from any province. province listed is for geographical purposes only.
			 --skipped some cities in Metro Manila (Taguig, Pasig) which don't have districts.
			 --other cities outside Metro Manila skipped as not central city in their urban area.
			["Quezon City"] = {parents = {name = "Metro Manila", divtype = "region"}},
			["Manila"] = {parents = {name = "Metro Manila", divtype = "region"}},
			["Davao City"] = {parents = "Davao del Sur"},
			["Caloocan"] = {parents = {name = "Metro Manila", divtype = "region"}},
			["Zamboanga City"] = {parents = "Zamboanga del Sur"},
			["Cebu City"] = {parents = "Cebu"},
			["Antipolo"] = {parents = "Rizal"},
			["Cagayan de Oro"] = {parents = "Misamis Oriental"},
			["Dasmariñas"] = {parents = "Cavite"},
			["General Santos"] = {parents = "South Cotabato"},
			["San Jose del Monte"] = {parents = "Bulacan"},
			["Bacolod"] = {parents = "Negros Occidental"},
			["Calamba"] = {parents = "Laguna"},
			["Angeles"] = {parents = "Pampanga"},
			["Iloilo City"] = {parents = "Iloilo"},
		},
	},
	{
		default_parent_divtype = "oblast",
		skip_parents = {name = "Russia", divtype = "country"},
		data = {
			-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
			["Moscow"] = {},
			["Saint Petersburg"] = {},
			["Novosibirsk"] = {parents = "Novosibirsk Oblast"},
			["Yekaterinburg"] = {parents = "Sverdlovsk Oblast"},
			["Nizhny Novgorod"] = {parents = "Nizhny Novgorod Oblast"},
			["Kazan"] = {parents = {name = "the Republic of Tatarstan", divtype = "republic"}},
			["Chelyabinsk"] = {parents = "Chelyabinsk Oblast"},
			["Omsk"] = {parents = "Omsk Oblast"},
			["Samara"] = {parents = "Samara Oblast"},
			["Ufa"] = {parents = {name = "the Republic of Bashkortostan", divtype = "republic"}},
			["Rostov-on-Don"] = {parents = "Rostov Oblast"},
			["Rostov-na-Donu"] = {alias_of = "Rostov-on-Don"},
			["Krasnoyarsk"] = {parents = {name = "Krasnoyarsk Krai", divtype = "krai"}},
			["Voronezh"] = {parents = "Voronezh Oblast"},
			["Perm"] = {parents = {name = "Perm Krai", divtype = "krai"}, wp = "Perm, Russia"},
			["Volgograd"] = {parents = "Volgograd Oblast"},
			["Krasnodar"] = {parents = {name = "Krasnodar Krai", divtype = "krai"}},
		},
	},
	{
		default_parent_divtype = "autonomous community",
		skip_parents = {name = "Spain", divtype = "country"},
		data = {
			["Madrid"] = {parents = "the Community of Madrid"},
			["Barcelona"] = {parents = "Catalonia"},
			-- this causes recursion errors.
			-- ["Valencia"] = {parents = "Valencia"},
			["Seville"] = {parents = "Andalusia"},
			["Bilbao"] = {parents = "the Basque Country"},
		},
	},
	{
		default_parent_divtype = "county",
		skip_parents = {name = "Taiwan", divtype = "country"},
		data = { 
			["New Taipei"] = {},
			["Taichung"] = {},
			["Kaohsiung"] = {wp = "%c, Taiwan"},
			["Taipei"] = {},
			["Taoyuan"] = {},
			["Tainan"] = {},
			["Chiayi"] = {},
			["Hsinchu"] = {},
			["Keelung"] = {},
		},
	},
	{
		default_parent_divtype = "county",
		skip_parents = {name = "the United Kingdom", divtype = "country"},
		data = {
			["London"] = {parents = {"Greater London", {name = "England", divtype = "constituent country"}}},
			["Manchester"] = {parents = {"Greater Manchester", {name = "England", divtype = "constituent country"}}},
			["Birmingham"] = {parents = {"the West Midlands", {name = "England", divtype = "constituent country"}}},
			["Liverpool"] = {parents = {"Merseyside", {name = "England", divtype = "constituent country"}}},
			["Glasgow"] = {parents = {{name = "the City of Glasgow", divtype = "council area"}, {name = "Scotland", divtype = "constituent country"}}},
			["Leeds"] = {parents = {"West Yorkshire", {name = "England", divtype = "constituent country"}}},
			["Newcastle upon Tyne"] = {parents = {"Tyne and Wear", {name = "England", divtype = "constituent country"}}},
			["Newcastle"] = {alias_of = "Newcastle upon Tyne"},
			["Bristol"] = {parents = {name = "England", divtype = "constituent country"}},
			["Cardiff"] = {parents = {name = "Wales", divtype = "constituent country"}},
			["Portsmouth"] = {parents = {"Hampshire", {name = "England", divtype = "constituent country"}}},
			["Edinburgh"] = {parents = {{name = "the City of Edinburgh", divtype = "council area"}, {name = "Scotland", divtype = "constituent country"}}},
			-- under 1,000,000 people but principal areas of Wales; requested by [[User:Donnanz]]
			["Swansea"] = {parents = {name = "Wales", divtype = "constituent country"}},
			["Newport"] = {parents = {name = "Wales", divtype = "constituent country"}, wp = "Newport, Wales"},
		},
	},
	-- cities in the US
	{
		default_parent_divtype = "state",
		skip_parents = {name = "the United States", divtype = "country"},
		wp = "%c, %d",
		data = {
			-- top 50 CSA's by population, with the top and sometimes 2nd or 3rd city listed
			["New York City"] = {parents = "New York", wp = "%c"},
			["Newark"] = {parents = "New Jersey"},
			["Los Angeles"] = {parents = "California", wp = "%c"},
			["Long Beach"] = {parents = "California"},
			["Riverside"] = {parents = "California"},
			["Chicago"] = {parents = "Illinois", wp = "%c"},
			["Washington, D.C."] = {wp = "%c"},
			["Baltimore"] = {parents = "Maryland", wp = "%c"},
			["San Jose"] = {parents = "California"},
			["San Francisco"] = {parents = "California", wp = "%c"},
			["Oakland"] = {parents = "California"},
			["Boston"] = {parents = "Massachusetts", wp = "%c"},
			["Providence"] = {parents = "Rhode Island"},
			["Dallas"] = {parents = "Texas", wp = "%c", commonscat = "%c, %d"},
			["Fort Worth"] = {parents = "Texas"},
			["Philadelphia"] = {parents = "Pennsylvania", wp = "%c"},
			["Houston"] = {parents = "Texas", wp = "%c"},
			["Miami"] = {parents = "Florida", wp = "%c", commonscat = "%c, %d"},
			["Atlanta"] = {parents = "Georgia", wp = "%c"},
			["Detroit"] = {parents = "Michigan", wp = "%c"},
			["Phoenix"] = {parents = "Arizona", wp = "%c", commonscat = "%c, %d"},
			["Mesa"] = {parents = "Arizona"},
			["Seattle"] = {parents = "Washington", wp = "%c"},
			["Orlando"] = {parents = "Florida"},
			["Minneapolis"] = {parents = "Minnesota", wp = "%c"},
			["Cleveland"] = {parents = "Ohio", wp = "%c", commonscat = "%c, %d"},
			["Denver"] = {parents = "Colorado", wp = "%c", commonscat = "%c, %d"},
			["San Diego"] = {parents = "California", wp = "%c", commonscat = "%c, %d"},
			["Portland"] = {parents = "Oregon"},
			["Tampa"] = {parents = "Florida"},
			["St. Louis"] = {parents = "Missouri", wp = "%c", commonscat = "%c, %d"},
			["Charlotte"] = {parents = "North Carolina"},
			["Sacramento"] = {parents = "California"},
			["Pittsburgh"] = {parents = "Pennsylvania", wp = "%c"},
			["Salt Lake City"] = {parents = "Utah", wp = "%c"},
			["San Antonio"] = {parents = "Texas", wp = "%c", commonscat = "%c, %d"},
			["Columbus"] = {parents = "Ohio"},
			["Kansas City"] = {parents = "Missouri", wp = "%c metropolitan area", commonscat = "%c, %d"},
			["Indianapolis"] = {parents = "Indiana", wp = "%c"},
			["Las Vegas"] = {parents = "Nevada", wp = "%c"},
			["Cincinnati"] = {parents = "Ohio", wp = "%c", commonscat = "%c, %d"},
			["Austin"] = {parents = "Texas"},
			["Milwaukee"] = {parents = "Wisconsin", wp = "%c", commonscat = "%c, %d"},
			["Raleigh"] = {parents = "North Carolina"},
			["Nashville"] = {parents = "Tennessee"},
			["Virginia Beach"] = {parents = "Virginia"},
			["Norfolk"] = {parents = "Virginia"},
			["Greensboro"] = {parents = "North Carolina"},
			["Winston-Salem"] = {parents = "North Carolina"},
			["Jacksonville"] = {parents = "Florida"},
			["New Orleans"] = {parents = "Louisiana", wp = "%c"},
			["Louisville"] = {parents = "Kentucky"},
			["Greenville"] = {parents = "South Carolina"},
			["Hartford"] = {parents = "Connecticut"},
			["Oklahoma City"] = {parents = "Oklahoma", wp = "%c"},
			["Grand Rapids"] = {parents = "Michigan"},
			["Memphis"] = {parents = "Tennessee"},
			["Birmingham"] = {parents = "Alabama"},
			["Fresno"] = {parents = "California"},
			["Richmond"] = {parents = "Virginia"},
			["Harrisburg"] = {parents = "Pennsylvania"},
			-- any major city of top 50 MSA's that's missed by previous
			["Buffalo"] = {parents = "New York"},
			-- any of the top 50 city by city population that's missed by previous
			["El Paso"] = {parents = "Texas"},
			["Albuquerque"] = {parents = "New Mexico"},
			["Tucson"] = {parents = "Arizona"},
			["Colorado Springs"] = {parents = "Colorado"},
			["Omaha"] = {parents = "Nebraska"},
			["Tulsa"] = {parents = "Oklahoma"},
			-- skip Arlington, Texas; too obscure and likely to be interpreted as Arlington, Virginia
		}
	},
	{
		default_parent_divtype = "country",
		skip_parents = {},
		data = {
			["Yerevan"] = {parents = "Armenia"},
			["Vienna"] = {parents = "Austria"},
			["Minsk"] = {parents = "Belarus"},
			["Brussels"] = {parents = "Belgium"},
			["Antwerp"] = {parents = "Belgium"},
			["Sofia"] = {parents = "Bulgaria"},
			["Zagreb"] = {parents = "Croatia"},
			["Prague"] = {parents = "the Czech Republic"},
			["Olomouc"] = {parents = "the Czech Republic"},
			["Copenhagen"] = {parents = "Denmark"},
			["Helsinki"] = {parents = {{name = "Uusimaa", divtype = "region"}, "Finland"}},
			["Athens"] = {parents = "Greece"},
			["Thessaloniki"] = {parents = "Greece"},
			["Budapest"] = {parents = "Hungary"},
			["Jakarta"] = {parents = "Indonesia"},
			-- FIXME, per Wikipedia "County Dublin" is now the "Dublin Region"
			["Dublin"] = {parents = {{name = "Dublin", divtype = "county"}, "Ireland"}},
			-- Jerusalem is not recognized internationally as part of either Israel or Palestine, so put the first parent as "Asia"
			-- grrr; additional support needed to allow "Asia" as a parent
			-- ["Jerusalem"] = {parents = {name = "Asia", divtype = "continent"}, addl_parents = {"Israel", "Palestine"}},
			["Tel Aviv"] = {parents = "Israel"},
			["Venice"] = {parents = {{name = "Veneto", divtype = "administrative region"}, "Italy"}},
			["Rome"] = {parents = {{name = "Lazio", divtype = "administrative region"}, "Italy"}},
			["Milan"] = {parents = {{name = "Lombardy", divtype = "administrative region"}, "Italy"}},
			["Naples"] = {parents = {{name = "Campania", divtype = "administrative region"}, "Italy"}},
			["Turin"] = {parents = {{name = "Piedmont", divtype = "administrative region"}, "Italy"}},
			["Riga"] = {parents = "Latvia"},
			["Amsterdam"] = {parents = "the Netherlands"},
			["Rotterdam"] = {parents = "the Netherlands"},
			["The Hague"] = {parents = "the Netherlands"},
			["Oslo"] = {parents = "Norway"},
			["Warsaw"] = {parents = "Poland"},
			["Katowice"] = {parents = "Poland"},
			["Kraków"] = {parents = "Poland"},
			["Krakow"] = {alias_of = "Kraków"},
			["Gdańsk"] = {parents = "Poland"},
			["Gdansk"] = {alias_of = "Gdańsk"},
			["Poznań"] = {parents = "Poland"},
			["Poznan"] = {alias_of = "Poznań"},
			["Łódź"] = {parents = "Poland"},
			["Lodz"] = {alias_of = "Łódź"},
			["Lisbon"] = {parents = "Portugal"},
			["Porto"] = {parents = "Portugal"},
			["Bucharest"] = {parents = "Romania"},
			["Belgrade"] = {parents = "Serbia"},
			["Stockholm"] = {parents = "Sweden"},
			["Zürich"] = {parents = "Switzerland"},
			["Zurich"] = {alias_of = "Zürich"},
			["Istanbul"] = {parents = "Turkey"},
			["Kyiv"] = {parents = "Ukraine"},
			["Kiev"] = {alias_of = "Kyiv"},
			["Kharkiv"] = {parents = "Ukraine"},
			["Odessa"] = {parents = "Ukraine", wp = "Odesa"},
			["Odesa"] = {alias_of = "Odessa"},
		},
	},
}

-- List of all top-level polities and their subpolities. The first three groups list the properties of top-level
-- polities: countries, "pseudo-countries" (de-facto/unrecognized/etc. countries) and former countries. The remainder
-- list the first-level subpolities (administrative divisions) of several, mostly large, countries, and their
-- country-specific and subpolity-specific properties. Each group is broken out into its own variable so they can be
-- accessed individually by category handlers and such in [[Module:place/data]].
export.polities = {
	export.country_group,
	export.pseudo_country_group,
	export.former_country_group,
	export.australia_group,
	export.austria_group,
	export.bangladesh_group,
	export.brazil_group,
	export.canada_group,
	export.china_group,
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
	export.us_group,
	export.uk_group,
	export.england_group,
	export.northern_ireland_group,
	export.scotland_group,
	export.wales_group,
}

return export
