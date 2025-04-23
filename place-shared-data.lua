local export = {}
--[=[
This module contains data shared between [[Module:place/data]] and [[Module:category tree/topic cat/data/Places]].
You must load this module using require(), not using mw.loadData().
]=]

export.force_cat = true -- set to true to force category generation even on non-mainspace pages

local m_table = require("Module:table")
local string_utilities_module = "Module:string utilities"
local en_utilities_module = "Module:en-utilities"

local insert = table.insert
local concat = table.concat
local dump = mw.dumpObject

--[==[ intro:

===Location group tables===

The bulk of the data in this module (after some helper functions and placetype tables) describes the known locations
and their relationships. The main location table is called `export.locations` and is a list of ''location groups'', each
of which describes a set of related known locations, as described above.

====OUT OF DATE DOCUMENTATION (location group tables)====

The following tables specify the known locations and their properties, where a location is either a top-level polity
(e.g. a country) or a subpolity (political division of a top-level location). Locations are gathered into
''groups'', each of which contains several items (places) that are handled similarly. Each group contains a list of all
the places contained in that group along with their properties, as well as group-specific handlers that specify common
properties of all items in the group. These items are used to construct the category description objects (i.e. the
objects that describe how to format the display of a category page, as documented in
[[Module:category tree/topic cat/data/documentation]]) for the following types of categories:

1. A bare topical category, e.g. [[:Category:en:Netherlands]]. Category description objects for these are created by the
   `make_bare_label` handler of a given group. (The term "label" is used here because the category system internally
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
   [[:Category:zh:Regions of the United States]]). These are controlled by the `divs` key in the data for a given item.

NOTE: There is also some duplication in [[Module:category tree/topic cat/data/Earth]], particularly for continents and
supranational regions (e.g. "the British Isles"). FIXME: Consolidate the data there into here.

Each group consists of a table with the following keys:

* `data`: This is a table listing the locations in the group. The keys are locations in the form that they appear in a
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
  full and elliptical placenames is only used for certain sorts of locations such as counties in Ireland and Northern
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

* `default_placetype`: The default placetype for locations in this group, if not overidden at the location level. See
  `placetype` above under "Placename Tables".

====OUT OF DATE DOCUMENTATION (location division tables)====

Each of the following tables specifies a group of locations with common properties (e.g. the states of the US). Each
table is associated with a location "group" (an entry in `export.locations`), which contains handlers specifying how to
process the data tables and also a pointer to the relevant table. The data is used as follows:

1. To generate the text of the bare topical categories directly associated with each location, such as
   [[:Category:Netherlands]], [[:Category:Alabama, USA]] or [[:Category:Amazonas, Brazil]], and per-language
   variants such as [[:Category:de:Netherlands]], [[:Category:es:Alabama, USA]] or [[:Category:pt:Amazonas, Brazil]].
   These categories (and all placename categories) are found in the ''topic cat subsystem'' of the category system;
   see [[Module:category tree/topic cat/data]] for more information.
2. To generate the text of topical categories for cities/towns/rivers/etc. in a given location, e.g.
   [[:Category:Cities in Alabama, USA]] for cities in Alabama, and per-language variants such as
   [[:Category:fr:Cities in Alabama, USA]] for French terms for cities in Alabama.
3. To generate the text of topical categories for political divisions of a given location, e.g.
   [[:Category:Provinces of the Netherlands]], [[:Category:Counties of Alabama]] or
   [[:Category:Municipalities of Amazonas, Brazil]], along with per-language variants such as
   [[:Category:de:Provinces of the Netherlands]], [[:Category:es:Counties of Alabama]] or
   [[:Category:pt:Municipalities of Amazonas, Brazil]].
4. To add pages to all the above types of categories when a call to {{tl|place}} on that page
   references the location, such as by a template call {{tl|place|en|city|state/Alabama}} (which will
   add the page to [[:Category:en:Cities in Alabama, USA]]).

Uses #1, #2 and #3 are controlled by [[Module:category tree/topic cat/data/Places]].
Use #4 is controlled by [[Module:place/data]].

The keys of each table are the location names in the form they will appear in bare categories, such as
[[:Category:de:Netherlands]] or [[:Category:fr:Alabama, USA]]. Hence they should include suffixes such as `, USA`.
However, they should not include the word `the` beforehand, which appears before some some locations when preceded by a
placename, but not other locations (e.g. [[:Category:de:Provinces of the Netherlands]] but
[[:Category:fr:Cities in Alabama, USA]]); this is controlled by the setting `the = true` in the location data.

The value of an item in each table is itself a table. This table contains properties describing the location in
question. Note that before being used (e.g. to generate the contents of a category page like
[[:Category:en:Cities in Ireland]] or [[:Category:de:Provinces of the Netherlands]] of to specify how to add the
relevant categories to a page with a call to {{tl|place}}), the table is passed through `initialize_spec`. That function
augments the property table with additional properties that are common to the group or derivable from group-specific
properties. The following are the recognized properties:

* `placetype`: String specifying the placetype the location (e.g. "country", "state", province"). This can also be a
  table of such types; in this case, the first listed type is the canonical type that will be used in descriptions, but
  the location will be recognized (e.g. in {{tl|place}} arguments) when tagged with any of the specified types. This
  value overrides the group-level `default_placetype` value, and only needs to be specified if it disagrees with that
  value.
* `divs`: List of recognized political or historical/popular divisions; e.g. for the Netherlands, a specification of the
  form `divs = {"provinces", "municipalities"}` will allow categories such as
  [[:Category:de:Provinces of the Netherlands]] and [[:Category:pt:Municipalities of the Netherlands]] to be created.
  Any division that appears here must also be found in `placetype_data`, or an error occurs.
* `is_city`: If 'true', don't recognize or generate categories such as [[:Category:en:Cities in Monaco]] (specifically,
  for place types in `generic_placetypes` but not in `generic_placetypes_for_cities`).
* `is_former_place`: If 'true', don't recognize or generate categories such as
  [[:Category:fr:Rivers in the Soviet Union]] (specifically, for any place type in `generic_placetypes` other than
  "places").
* `keydesc`: String directly specifying a description of the location, for use in generating the contents of category
  pages related to the location. descriptions.
* `parents`: List of parents of the bare topical category. For example, if 'parents = {"Europe", "Asia"}' is specified
  for "Turkey", bare topical categories such as [[:Category:en:Turkey]] will have parent categories
  [[:Category:en:Europe]] and [[:Category:en:Asia]]. The first listed category is used for the primary parent (i.e. this
  is the parent that appears in the breadcrumbs at the top of the category page). In this case, for example, "Europe"
  (not "Asia") is used as the breadcrumb. This property only needs to be specified for top-level locations (countries and
  such), not for subpolities (states, provinces, etc.), which use the value of `container` (see below) as the
  parent.
* `container`: This specifies the larger location in which the subpolity is contained, and is used to construct the
  primary parent of 'Cities in ...', 'Rivers in ...' and similar categories. For example, the subpolity Guangdong (a
  province of China) will have "China" as the `container`, so that a category of the form
  [[:Category:en:Cities in Guangdong]] will have its primary parent (i.e. the parent that appears in the breadcrumbs at
  the top of the category page) as [[:Category:en:Cities in China]]. If `container` is omitted, as in top-level
  locations, the primary parent will simply be e.g. [[:Category:en:Cities]] (or "Towns", "Rivers", etc. as appropriate).
* `wp`: Spec describing how to construct the Wikipedia article for the city. Each spec is either `true` (equivalent to
  `"%l"`, i.e. use the full location placename directly) or a string containing formatting directives, indicating how to
  construct the article name. The allowed formatting directives are `%l` (the full location placename), `%e` (the
  elliptical location placename) and `%c` (the full placename of the first immediate container). For example, the value
  of `wp` for the group of United States cities is `"%l, %c"` since the city articles tend to be named e.g.
  `Austin, Texas` (but with many exceptions, specified using `wp` fields at the city level). The default is `true`.
* `wpcat`: Spec describing how to construct the Wikipedia category page for the city (i.e. the page listing articles and
  categories relevant to the city). The format is the same as with `wp`, and it defaults to the value of `wp`. It rarely
  needs to be specified because the category page and the article page almost always follow the same format.
* `commonscat`: Spec describing how to construct the Commons category page for the city (i.e. the page on the MediaWiki
  Commons site listing articles and categories relevant to the city). It has the same format as `wp` and `wpcat` and
  defaults to `wpcat`, which is usually (but not always) correct.
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
Call the location group's `key_to_placename` function if it exists (see the comment at the top of [[Module:place]] for
the distinction between keys and placenames). Two values are returned, the full and elliptical placenames (e.g. full
`"County Durham"` vs. elliptical `"Durham"`). If the group does not define `key_to_placename`, both full and elliptical
placenames are computed by chopping off anything starting with a comma.
]==]
function export.key_to_placename(group, key)
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
	key = key:gsub(",.*", "")
	return key, key
end

--[==[
Call the location group's `placename_to_key` function if it exists (see the comment at the top of [[Module:place]] for
the distinction between keys and placenames) and return the result. If `placename_to_key` exists with the value `false`,
return the placename unchanged. If the group does not define `placename_to_key`, and it defines a `default_container`
whose placetype is either `country` or `constituent country`, the container name is appended to the placename after a
comma and a space. Otherwise the placename is returned unchanged.
]==]
function export.placename_to_key(group, placename)
	if group.placename_to_key == false then
		return placename
	elseif group.placename_to_key then
		local key = group.placename_to_key(placename)
		if type(key) ~= "string" then
			internal_error("Placename %s returned a non-string key: %s", placename, key)
		end
		return key
	else
		local defcon = group.default_container
		if not defcon then
			return placename
		elseif type(defcon) == "string" then
			return placename .. ", " .. defcon
		elseif type(defcon) == "table" and (defcon.placetype == "country" or
				defcon.placetype == "constituent country") then
			return placename .. ", " .. defcon.key
		else
			return placename
		end
	end
end

--[==[
Initialize the location spec `spec`, augmenting it with default values taken from `group` if the spec itself doesn't
specify values for the properties. This sets `containers` to a canonicalized list of objects, each with `key` and
`placetype` keys, describing the immediate containers of the location, and erases (sets to nil) the original
non-canonicalized `container` field. (Most locations have only one immediate container but some, e.g. Russia, have more
than one. Containers should be carefully distinguished from category parents. Generally the container is the first
category parent, or the first ``n`` parents if there are ``n`` containers, but there may be additional category parents,
which indicate some sort of relation between the category parent and the location but not necessarily one of
containment.)

This function is idempotent in that nothing happens if called more than once on the same spec.

FIXME: Consider reimplementing this in a more standardly object-oriented way using metatables.
]==]
function export.initialize_spec(group, key, spec)
	if spec.initialized then
		return
	end
	local container = spec.container
	local containers
	if not container then
		container = group.default_container
	end
	if container then
		if type(container) == "string" or container.key then
			container = {container}
		end
		containers = {}
		for _, cont in ipairs(container) do
			if type(cont) == "string" then
				if group.canonicalize_key_container then
					cont = group.canonicalize_key_container(cont)
				else
					cont = {key = cont, placetype = "country"}
				end
			end
			insert(containers, cont)
		end
	end
	spec.containers = containers
	spec.container = nil
	spec.placetype = spec.placetype or group.default_placetype
	if not spec.placetype then
		internal_error("No placetype found in key %s for spec %s or in group `default_placetype`", key, spec)
	end
	spec.divs = spec.divs or group.default_divs
	spec.addl_divs = group.addl_divs
	spec.keydesc = spec.keydesc or group.default_keydesc
	spec.overriding_bare_label_parents =
		spec.overriding_bare_label_parents or group.default_overriding_bare_label_parents
	spec.wp = spec.wp or group.default_wp
	spec.wpcat = spec.wpcat or group.default_wpcat
	spec.commonscat = spec.commonscat or group.default_commonscat
	local function boolean_with_default(val, default_val)
		if val == nil then
			return default_val
		else
			return val
		end
	end
	spec.british_spelling = boolean_with_default(spec.british_spelling, group.default_british_spelling)
	spec.the = boolean_with_default(spec.the, group.default_the)
	spec.no_container_cat = boolean_with_default(spec.no_container_cat, group.default_no_container_cat)
	spec.no_generic_place_cat = boolean_with_default(spec.no_generic_place_cat, group.default_no_generic_place_cat)
	spec.no_check_holonym_mismatch = boolean_with_default(spec.no_check_holonym_mismatch,
		group.default_no_check_holonym_mismatch)
	spec.no_auto_augment_container = boolean_with_default(spec.no_auto_augment_container,
		group.default_no_auto_augment_container)
	spec.is_city = boolean_with_default(spec.is_city, group.default_is_city)
	spec.is_city = boolean_with_default(spec.is_city, group.default_placetype == "city")
	spec.is_former_place = boolean_with_default(spec.is_former_place, group.default_is_former_place)
	spec.no_include_container_in_desc = boolean_with_default(spec.no_include_container_in_desc,
		group.default_no_include_container_in_desc)
	spec.initialized = true
end

--[=[
Given a location group, key and possible placetypes that the placename must match, check if the key exists in the group
with at least one of the group's key's placetypes matching one of the passed-in placetypes. If so, return two values:
the group key (which potentially could differ from the passed-in key due to aliases) and the corresponding spec object,
which (as with all functions that return spec objects) has been initialized using `initialize_spec()` (i.e. default
property values have been copied from the group into the spec, if the spec doesn't itself specify a value for the
property in question).

`alias_resolution` controls how aliases are resolved. Normally, both display and category aliases are followed, and
the returned key will reflect the canonical location key. However, if `alias_resolution` is {"none"}, no alias following
happens. In that case, if the key specifies an alias, the spec for the alias rather than the spec for the canonical
location is returned, and importantly, it is returned uninitialized, meaning that properties from the group are not
copied into the spec. (If the key specifies a canonical location, its spec is returned initialized, as in the normal
case where `alias_resolution` is unspecified.) The caller needs to check whether the returned spec is an alias by
looking for an `alias_of` property. If `alias_resolution` is {"display"}, the behavior is the same as for {"none"}
except that if the alias contains a setting `display = true`, the returned key will reflect the canonical location key,
and if the alias contains a setting `display = ``string`` `, the returned key will reflect that string.

This is a low-level function meant for internal use; external callers should generally use `get_matching_location` (for
internally-derived locations), `find_matching_holonym_location` (for externally-derived locations) or
`find_canonical_key` (for known-canonical locations where the placetype isn't known).
]=]
local function find_matching_key_in_group(group, placetypes, key, alias_resolution)
	if alias_resolution ~= nil and alias_resolution ~= "none" and alias_resolution ~= "display" and
		alias_resolution ~= "all" then
		internal_error("Bad value for 'alias_resolution': %s", alias_resolution)
	end
	local spec = group.data[key]
	if not spec then
		return nil
	end

	local function check_correct_placetype(placetype)
		if type(placetype) == "table" then
			for _, pt in ipairs(placetype) do
				if list_or_element_contains(placetypes, pt) then
					return true
				end
			end
			return false
		else
			return list_or_element_contains(placetypes, placetype)
		end
	end

	if spec.alias_of then
		local resolved_key = spec.alias_of
		local resolved_spec = group.data[resolved_key]
		if not resolved_spec then
			internal_error("Key %s is an alias of %s, which doesn't exist", key, resolved_key)
		elseif resolved_spec.alias_of then
			internal_error("Key %s is an alias of %s, which is itself an alias; indirect aliasing not allowed",
				key, resolved_key)
		end
		if alias_resolution == "none" or alias_resolution == "display" then
			-- We could be working with non-initialized/defaulted spec, since we're pulling it directly from the group.
			local placetype = spec.placetype or resolved_spec.placetype or group.default_placetype
			if not placetype then
				internal_error("No placetype found for key %s in any of spec %s, alias-resolved spec %s or in group " ..
					"`default_placetype`", key, spec, resolved_spec)
			end
			if not check_correct_placetype(placetype) then
				return nil
			end
			if alias_resolution == "display" then
				if spec.display == true then
					key = resolved_key
				elseif spec.display then
					key = spec.display
				end
			end
			return key, spec
		end
		key = resolved_key
		spec = resolved_spec
	end

	-- We could be working with non-initialized/defaulted spec, since we're pulling it directly from the group.
	local placetype = spec.placetype or group.default_placetype
	if not placetype then
		internal_error("No placetype found for key %s in spec %s or group `default_placetype`", key, spec)
	end
	if not check_correct_placetype(placetype) then
		return nil
	end
	export.initialize_spec(group, key, spec)
	return key, spec
end

--[=[
Given a location group, placename and possible placetypes that the placename must match, check if the placename exists
in the group with at least one of the placetypes of the key in the group that corresponds to the placename matching one
of the passed-in placetypes. If so, return two values: the key corrsponding to the passed-in placename and the
corresponding spec object. This is similar to `find_matching_key_in_group()` but works with placenames rather than keys.
`alias_resolution` is as in `find_matching_key_in_group()`.

This is a low-level function meant for internal use; external callers should generally use `get_matching_location` (for
internally-derived locations), `find_matching_holonym_location` (for externally-derived locations) or
`find_canonical_key` (for known-canonical locations where the placetype isn't known).
]=]
local function find_matching_placename_in_group(group, placetypes, placename, alias_resolution)
	local key = export.placename_to_key(group, placename)
	return find_matching_key_in_group(group, placetypes, key, alias_resolution)
end

--[==[
If `key` is a canonical known location key (i.e. not an alias), return the corresponding group and initialized spec.
If no such key exists, return {nil}. This throws an internal error if two locations with the same key are found.
]==]
function export.find_canonical_key(key)
	local found_locations = {}
	for _, group in ipairs(export.locations) do
		local spec = group.data[key]
		if not spec then
			-- do nothing
		elseif spec.alias_of then
			mw.log(("Skipping alias '%s' of canonical '%s'"):format(key, spec.alias_of))
		else
			insert(found_locations, {group, spec})
		end
	end
	if not found_locations[1] then
		return nil
	elseif found_locations[2] then
		internal_error("Found multiple matching locations for canonical key %s: %s", key, found_locations)
	else
		local group, spec = unpack(found_locations[1])
		export.initialize_spec(group, key, spec)
		return group, spec
	end
end

--[==[
Iterator that returns all locations matching a given description, where the description consists of either a placename
or a key along with a list of possible placetypes. Usually there will be at most one such location. The iterator
returns three values at each iteration: the location group, canonical key by which the location is known and the spec
object describing the location. `data` contains the following possible fields:
* `placetypes`: A list of possible placetypes, one of which must match one of the location's placetypes; or a string
  specifying a placetype, which must match one of the location's placetypes. This must be specified.
* `placename`: The placename of the location. Either this or `key` must be specified.
* `key`: The key of the location. Either this or `placename` must be specified.
* `alias_resolution`: If specified, it behaves the same as for `find_matching_key_in_group`.
The spec is normally initialized using `initialize_spec()` prior to it being returned (but may not be if
`alias_resolution` is given and the specified key or placename is an alias; see the documentation for
`find_matching_key_in_group`).
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
				key, spec = find_matching_placename_in_group(group, data.placetypes, data.placename,
					data.alias_resolution)
			else
				if not data.key then
					internal_error("'.placename' or '.key' must be defined: %s", data)
				end
				key, spec = find_matching_key_in_group(group, data.placetypes, data.key, data.alias_resolution)
			end
			if key then
				return group, key, spec
			end
		end
	end
end

--[==[
Return the location matching a given description, where the description consists of either a placename or a key along
with a list of possible placetypes. This is similar to `iterate_matching_location()` but throws an internal error if
there is not exactly one location found; as such, it is for use with internally specified locations (such as the
containers of known locations) rather than externally specified locations, which may not match a known location and in
some cases may match multiple known locations. For finding an externally specified location, consider using
`find_matching_holonym_location`, which returns {nil} rather than throwing an error if the location isn't found, but
also (more importantly) checks to make sure there are no conflicting holonyms among the user-specified holonyms (e.g.
{{tl|place|city|s/Delaware|c/USA|t=Newark}} will not match the known location `Newark` (in New Jersey, not Delaware).
]==]
function export.get_matching_location(data)
	local all_found = {}
	for group, key, spec in export.iterate_matching_location(data) do
		insert(all_found, {group, key, spec})
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
					local container_group, container_key, container_spec = export.get_matching_location {
						placetypes = container.placetype,
						key = container.key,
					}
					if not keys_seen[container_key] then
						insert(next_iteration_containers, {
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

--[==[
Given a placename, convert it into a link (two-part if `display_form` is given and differs from `placename`) and add
`"the "` to the beginning if called for in `spec`.
]==]
function export.construct_linked_placename(spec, placename, display_form)
	local linked_placename = display_form and placename ~= display_form and ("[[%s|%s]]"):format(placename,
		display_form) or ("[[%s]]"):format(placename)
	if spec.the then
		linked_placename = "the " .. linked_placename
	end
	return linked_placename
end

--[=[
This is typically used to define `key_to_placename`. It generates a function that chops off parts of a string (a
location key), typically at the end, in order to get the full and elliptical versions of a placename. (See the
documentation above for `key_to_placename` under "Location group tables" for the difference between full and elliptical
placenames.) `container_patterns` is a Lua pattern or a list of possible patterns matching the container at the end of
the key, which will be used to remove that container. If multiple patterns are specified, each one is tried until one
matches. If `container_patterns` is omitted, this part of the process is skipped. The reulting string becomes the full
placename. If `divtype_patterns` is specified, it is likewise either a Lua pattern or list of possible patterns to match
and remove the political division affixed onto the end (or possibly the beginning) of the key in the keys of certain
countries (such as South Korean and North Korean counties, which include the word "County" in the key). The resulting
chopped string becomes the elliptical placename. If `divtype_patterns` is omitted, this part of the process is skipped
and the full and elliptical placenames are the same.

Typical usage is as follows:

```
key_to_placename = make_key_to_placename(", England$"),
```

or (when the political division is part of the key)

```
key_to_placename = make_key_to_placename(", South Korea$", " County$")
```
]=]
local function make_key_to_placename(container_patterns, divtype_patterns)
	if type(container_patterns) == "string" then
		container_patterns = {container_patterns}
	end
	if type(divtype_patterns) == "string" then
		divtype_patterns = {divtype_patterns}
	end
	return function(key)
		local full_placename = key
		if container_patterns then
			for _, container_pattern in ipairs(container_patterns) do
				local nsubs
				full_placename, nsubs = full_placename:gsub(container_pattern, "")
				if nsubs > 0 then
					break
				end
			end
		end
		local elliptical_placename = full_placename
		if divtype_patterns then
			for _, divtype_pattern in ipairs(divtype_patterns) do
				local nsubs
				elliptical_placename, nsubs = elliptical_placename:gsub(divtype_pattern, "")
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
placename to get the key (see the definition of `placename_to_key` above in the documentation under "Location group
tables"). Optional `divtype_suffix` is a raw string (which should not contain hyphens or other characters that have
special meaning in Lua patterns) to be appended first to the placename; if already present at the end, it is not
appended. `container_suffix` is then added in the same fashion if given. Typical usage is like this:

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
local function make_placename_to_key(container_suffix, divtype_suffix)
	return function(placename)
		local key = placename
		if divtype_suffix then
			if not key:find(divtype_suffix .. "$") then
				key = key .. divtype_suffix
			end
		end
		if container_suffix then
			key = key .. container_suffix
		end
		return key
	end
end

--[=[
This is typically used to define `canonicalize_key_container`, which converts a container as specified in the location
data into the canonical form containing both the full container key and its placetype. It generates a function to do
the canonicalization of a given container. If the container is a string, `suffix` is appended onto the string (use {nil}
or {""} if there is no suffix to append), and the placetype is set to `placetype`. Otherwise the container is left
as-is. Typical usage is like this:

```
canonicalize_key_container = make_canonicalize_key_container(", Canada", "province")
```

which will convert e.g. `"Ontario"` into `{key = "Ontario, Canada", placetype = "province"}`.
]=]
local function make_canonicalize_key_container(suffix, placetype)
	return function(container)
		if type(container) == "string" then
			return {key = container .. (suffix or ""), placetype = placetype}
		else
			return container
		end
	end
end

-----------------------------------------------------------------------------------
--                               Top-level tables                                --
-----------------------------------------------------------------------------------

export.continents = {
	["Earth"] = {the = true, placetype = "planet"},
		["Africa"] = {placetype = "continent", container = {key = "Earth", placetype = "planet"}},
		["America"] = {placetype = "supercontinent", container = {key = "Earth", placetype = "planet"}},
			["North America"] = {placetype = "continent", container = {key = "America", placetype = "supercontinent"}},
				["Caribbean"] = {the = true, placetype = "continental region", container = {key = "North America", placetype = "continent"}},
				["Central America"] = {placetype = "continental region", container = {key = "North America", placetype = "continent"}},
			["South America"] = {placetype = "continent", container = {key = "America", placetype = "supercontinent"}},
		["Antartica"] = {placetype = "continent", container = {key = "Earth", placetype = "planet"}},
		["Eurasia"] = {placetype = "supercontinent", container = {key = "Earth", placetype = "planet"}},
			["Asia"] = {placetype = "continent", container = {key = "Eurasia", placetype = "supercontinent"}},
			["Europe"] = {placetype = "continent", container = {key = "Eurasia", placetype = "supercontinent"}},
		["Oceania"] = {placetype = "continent", container = {key = "Earth", placetype = "planet"}},
			["Melanesia"] = {placetype = "continental region", container = {key = "Oceania", placetype = "continent"}},
			["Micronesia"] = {placetype = "continental region", container = {key = "Oceania", placetype = "continent"}},
			["Polynesia"] = {placetype = "continental region", container = {key = "Oceania", placetype = "continent"}},
}

export.continents_group = {
	default_overriding_bare_label_parents = {"continents and continental regions"},
	default_divs = {{type = "countries", prep = "in"}},
	-- It's enough to mention the first-level continent or continent group. It seems excessive to write e.g.
	-- "El Salvador, a country in Central America, a continental region in North America, a continent in America, ...".
	default_no_include_container_in_desc = true,
	default_no_container_cat = true,
	default_no_generic_place_cat = true,
	-- French Guyana is in France but not in Europe, which should not be an issue, so don't check holonym mismatches at
	-- this level. We also run into problems with supercontinents, which have "continent" as the fallback and cause
	-- mismatches.
	default_no_check_holonym_mismatch = true,
	data = export.continents,
}

-- Countries: including those with partial recognition that are normally considered countries (e.g. Kosovo, Taiwan).
export.countries = {
	["Afghanistan"] = {container = "Asia", divs = {"provinces", "districts"}},
	["Albania"] = {container = "Europe", divs = {"regions", "counties", "municipalities"}, british_spelling = true},
	["Algeria"] = {container = "Africa", divs = {"provinces", "communes", "districts", "municipalities"}},
	["Andorra"] = {container = "Europe", divs = {"parishes"}, british_spelling = true},
	["Angola"] = {container = "Africa", divs = {"provinces", "municipalities"}},
	["Antigua and Barbuda"] = {container = "North America", divs = {"provinces"}, british_spelling = true},
	["Argentina"] = {container = "South America", divs = {"provinces", "departments", "municipalities"}},
	["Armenia"] = {container = {"Europe", "Asia"}, divs = {"provinces", "districts"}, british_spelling = true},
	["Republic of Armenia"] = {alias_of = "Armenia", the = true}, -- differs in "the"
	-- Both a country and continent
	["Australia"] = {container = "Oceania", divs = {"states", "territories", "local government areas"},
		addl_divs_for_categorization = {"states and territories"}, british_spelling = true},
	["Austria"] = {container = "Europe", divs = {"states", "districts", "municipalities"}, british_spelling = true},
	["Azerbaijan"] = {container = {"Europe", "Asia"}, divs = {"districts", "municipalities"}, british_spelling = true},
	["Bahamas"] = {the = true, container = "North America", divs = {"districts"}, british_spelling = true, wp = "The Bahamas"},
	["Bahrain"] = {container = "Asia", divs = {"governorates"}},
	["Bangladesh"] = {container = "Asia", divs = {"divisions", "districts", "municipalities"}, british_spelling = true},
	["Barbados"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Belarus"] = {container = "Europe", divs = {"regions", "districts"}, british_spelling = true},
	["Belgium"] = {container = "Europe", divs = {"regions", "provinces", "municipalities"}, british_spelling = true},
	["Belize"] = {container = "Central America", divs = {"districts"}, british_spelling = true},
	["Benin"] = {container = "Africa", divs = {"departments", "communes"}},
	["Bhutan"] = {container = "Asia", divs = {"districts", "gewogs"}},
	["Bolivia"] = {container = "South America", divs = {"provinces", "departments", "municipalities"}},
	["Bosnia and Herzegovina"] = {container = "Europe", divs = {"entities", "cantons", "municipalities"}, british_spelling = true},
	["Bosnia and Hercegovina"] = {alias_of = "Bosnia and Herzegovina", display = true},
	["Bosnia"] = {alias_of = "Bosnia and Herzegovina", display = true},
	["Botswana"] = {container = "Africa", divs = {"districts", "subdistricts"}, british_spelling = true},
	["Brazil"] = {container = "South America", divs = {"states", "municipalities", "macroregions"}},
	["Brunei"] = {container = "Asia", divs = {"districts", "mukims"}, british_spelling = true},
	["Bulgaria"] = {container = "Europe", divs = {"provinces", "municipalities"}, british_spelling = true},
	["Burkina Faso"] = {container = "Africa", divs = {"regions", "departments", "provinces"}},
	["Burundi"] = {container = "Africa", divs = {"provinces", "communes"}},
	["Cambodia"] = {container = "Asia", divs = {"provinces", "districts"}},
	["Cameroon"] = {container = "Africa", divs = {"regions", "departments"}},
	["Canada"] = {container = "North America", divs = {
		{type = "provinces", cat_as = "provinces and territories"},
		{type = "territories", cat_as = "provinces and territories"},
		"counties", "districts", "municipalities", "regional municipalities",
		"rural municipalities", "parishes",
		-- Don't change the following to something more politically correct (e.g. "First Nations reserves") until/unless
		-- the Canadian government makes a similar switch (and note that as of Apr 18 2025, the Wikipedia article is
		-- still at [[w:Indian reserves]]).
		"Indian reserves",
		"census divisions",
		{type = "townships", prep = "in"},
	},
		british_spelling = true},
	["Cape Verde"] = {container = "Africa", divs = {"municipalities", "parishes"}},
	["Central African Republic"] = {the = true, container = "Africa", divs = {"prefectures", "subprefectures"}},
	["Chad"] = {container = "Africa", divs = {"regions", "departments"}},
	["Chile"] = {container = "South America", divs = {"regions", "provinces", "communes"}},
	["China"] = {container = "Asia", divs = {"provinces", "autonomous regions",
		"special administrative regions", "prefectures", "prefecture-level cities", "counties", "county-level cities",
		"districts", "municipalities"},
		addl_divs_for_categorization = {"provinces and autonomous regions"}},
	["People's Republic of China"] = {alias_of = "China", the = true}, -- differs in "the"
	["Colombia"] = {container = "South America", divs = {"departments", "municipalities"}},
	["Comoros"] = {the = true, container = "Africa", divs = {"autonomous islands"}},
	["Costa Rica"] = {container = "Central America", divs = {"provinces", "cantons"}},
	["Croatia"] = {container = "Europe", divs = {"counties", "municipalities"}, british_spelling = true},
	["Cuba"] = {container = "North America", divs = {"provinces", "municipalities"}},
	["Cyprus"] = {container = {"Europe", "Asia"}, divs = {"districts"}, british_spelling = true},
	["Czech Republic"] = {the = true, container = "Europe", divs = {"regions", "districts", "municipalities"}, british_spelling = true},
	["Czechia"] = {alias_of = "Czech Republic"}, -- differs in "the"
	["Democratic Republic of the Congo"] = {the = true, container = "Africa", divs = {"provinces", "territories"}},
	["Congo"] = {alias_of = "Democratic Republic of the Congo", display = true, the = true},
	["Denmark"] = {container = "Europe", divs = {"regions", "municipalities", "dependent territories"}, british_spelling = true},
	["Djibouti"] = {container = "Africa", divs = {"regions", "districts"}},
	["Dominica"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Dominican Republic"] = {the = true, container = "North America", divs = {"provinces", "municipalities"},
		keydesc = "the [[Dominican Republic]], the country that shares the [[Caribbean]] island of [[Hispaniola]] with [[Haiti]]"},
	["East Timor"] = {container = "Asia", divs = {"municipalities"}},
	["Ecuador"] = {container = "South America", divs = {"provinces", "cantons"}},
	["Egypt"] = {container = "Africa", divs = {"governorates", "regions"}},
	["El Salvador"] = {container = "Central America", divs = {"departments", "municipalities"}},
	["Equatorial Guinea"] = {container = "Africa", divs = {"provinces"}},
	["Eritrea"] = {container = "Africa", divs = {"regions", "subregions"}},
	["Estonia"] = {container = "Europe", divs = {"counties", "municipalities"}, british_spelling = true},
	["Eswatini"] = {container = "Africa", british_spelling = true},
	["Swaziland"] = {alias_of = "Eswatini", display = true},
	["Ethiopia"] = {container = "Africa", divs = {"regions", "zones"}},
	["Federated States of Micronesia"] = {the = true, container = "Micronesia", divs = {"states"}},
	["Fiji"] = {container = "Melanesia", divs = {"divisions", "provinces"}, british_spelling = true},
	["Finland"] = {container = "Europe", divs = {"regions", "municipalities"}, british_spelling = true},
	["France"] = {container = "Europe", divs = {"regions", "cantons", "collectivities", "communes", "departments",
		"municipalities", "dependent territories", "territories",
		{type = "prefectures", cat_as = {"prefectures", "departmental capitals"}},
		{type = "French prefectures", cat_as = {"prefectures", "departmental capitals"}},
		"provinces",
	}, british_spelling = true},
	["Gabon"] = {container = "Africa", divs = {"provinces", "departments"}},
	["Gambia"] = {the = true, container = "Africa", divs = {"divisions", "districts"}, british_spelling = true, wp = "The Gambia"},
	["Georgia"] = {container = {"Europe", "Asia"}, divs = {"regions", "districts"},
		keydesc = "the country of [[Georgia]], in [[Eurasia]]", british_spelling = true},
	["Germany"] = {container = "Europe", divs = {"states", "municipalities", "districts"}, british_spelling = true},
	["Ghana"] = {container = "Africa", divs = {"regions", "districts"}, british_spelling = true},
	["Greece"] = {container = "Europe", divs = {"regions", "regional units", "municipalities",
		{type = "peripheries", cat_as = {"regions"}},
	}, british_spelling = true},
	["Grenada"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Guatemala"] = {container = "Central America", divs = {"departments", "municipalities"}},
	["Guinea"] = {container = "Africa", divs = {"regions", "prefectures"}},
	["Guinea-Bissau"] = {container = "Africa", divs = {"regions"}},
	["Guyana"] = {container = "South America", divs = {"regions"}, british_spelling = true},
	["Haiti"] = {container = "North America", divs = {"departments", "arrondissements"}},
	["Honduras"] = {container = "Central America", divs = {"departments", "municipalities"}},
	["Hungary"] = {container = "Europe", divs = {"counties", "districts"}, british_spelling = true},
	["Iceland"] = {container = "Europe", divs = {"regions", "municipalities", "counties"}, british_spelling = true},
	["India"] = {container = "Asia", divs = {"states", "union territories", "divisions", "districts", "municipalities"},
		 addl_divs_for_categorization = {"states and union territories"}, british_spelling = true},
	["Indonesia"] = {container = "Asia", divs = {"regencies", "provinces"}},
	["Iran"] = {container = "Asia", divs = {"provinces", "counties"}},
	["Iraq"] = {container = "Asia", divs = {"governorates", "districts"}},
	["Ireland"] = {container = "Europe", addl_parents = {"British Isles"}, divs = {"counties", "districts", "provinces"}, british_spelling = true},
	["Republic of Ireland"] = {alias_of = "Ireland", the = true}, -- differs in "the"
	["Israel"] = {container = "Asia", divs = {"districts"}},
	["Italy"] = {container = "Europe", divs = {"regions", "provinces", "metropolitan cities", "municipalities"},
		british_spelling = true},
	["Ivory Coast"] = {container = "Africa", divs = {"districts", "regions"}},
	-- We should really be using Ivory Coast (common name) but there are political ramifications to the use of
	-- Côte d'Ivoire so don't make it a display alias.
	["Côte d'Ivoire"] = {alias_of = "Ivory Coast"},
	["Jamaica"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Japan"] = {container = "Asia", divs = {"prefectures", "subprefectures", "municipalities"}},
	["Jordan"] = {container = "Asia", divs = {"governorates"}},
	["Kazakhstan"] = {container = {"Asia", "Europe"}, divs = {"regions", "districts"}},
	["Kenya"] = {container = "Africa", divs = {"counties"}, british_spelling = true},
	["Kiribati"] = {container = "Micronesia", british_spelling = true},
	["Kosovo"] = {container = "Europe", british_spelling = true},
	["Kuwait"] = {container = "Asia", divs = {"governorates", "areas"}},
	["Kyrgyzstan"] = {container = "Asia", divs = {"regions", "districts"}},
	["Laos"] = {container = "Asia", divs = {"provinces", "districts"}},
	["Latvia"] = {container = "Europe", divs = {"municipalities"}, british_spelling = true},
	["Lebanon"] = {container = "Asia", divs = {"governorates", "districts"}},
	["Lesotho"] = {container = "Africa", divs = {"districts"}, british_spelling = true},
	["Liberia"] = {container = "Africa", divs = {"counties", "districts"}},
	["Libya"] = {container = "Africa", divs = {"districts", "municipalities"}},
	["Liechtenstein"] = {container = "Europe", divs = {"municipalities"}, british_spelling = true},
	["Lithuania"] = {container = "Europe", divs = {"counties", "municipalities"}, british_spelling = true},
	["Luxembourg"] = {container = "Europe", divs = {"cantons", "districts"}, british_spelling = true},
	["Madagascar"] = {container = "Africa", divs = {"regions", "districts"}},
	["Malawi"] = {container = "Africa", divs = {"regions", "districts"}, british_spelling = true},
	["Malaysia"] = {container = "Asia", divs = {"states", "federal territories", "districts"}, british_spelling = true},
	["Maldives"] = {the = true, container = "Asia", divs = {"provinces", "administrative atolls"}, british_spelling = true},
	["Mali"] = {container = "Africa", divs = {"regions", "cercles"}},
	["Malta"] = {container = "Europe", divs = {"regions", "local councils"}, british_spelling = true},
	["Marshall Islands"] = {the = true, container = "Micronesia", divs = {"municipalities"}},
	["Mauritania"] = {container = "Africa", divs = {"regions", "departments"}},
	["Mauritius"] = {container = "Africa", divs = {"districts"}, british_spelling = true},
	["Mexico"] = {container = "North America", addl_parents = {"Central America"}, divs = {"states", "municipalities"}},
	["Moldova"] = {container = "Europe", divs = {"districts", "municipalities", "autonomous territorial units"},
		british_spelling = true},
	["Monaco"] = {placetype = {"city-state", "country"}, container = "Europe", is_city = true, british_spelling = true},
	["Mongolia"] = {container = "Asia", divs = {"provinces", "districts"}},
	["Montenegro"] = {container = "Europe", divs = {"municipalities"}},
	["Morocco"] = {container = "Africa", divs = {"regions", "prefectures", "provinces"}},
	["Mozambique"] = {container = "Africa", divs = {"provinces", "districts"}},
	["Myanmar"] = {container = "Asia",
		divs = {"regions", "states", "union territories",
		{type = "self-administered zones", cat_as = "self-administered areas"},
		{type = "self-administered divisions", cat_as = "self-administered areas"},
		"districts"}},
	["Burma"] = {alias_of = "Myanmar"}, -- not display-canonicalizing; has political connotations
	["Namibia"] = {container = "Africa", divs = {"regions", "constituencies"}, british_spelling = true},
	["Nauru"] = {container = "Micronesia", divs = {"districts"}, british_spelling = true},
	["Nepal"] = {container = "Asia", divs = {"provinces", "districts"}},
	["Netherlands"] = {the = true, placetype = {"constituent country", "country"}, container = "Europe",
		divs = {"provinces", "municipalities",
			{type = "FORMER municipalities", cat_as = "former municipalities"},
			"dependent territories", "constituent countries"}, british_spelling = true},
	["New Zealand"] = {container = "Polynesia", divs = {"regions", "dependent territories", "territorial authorities"},
		british_spelling = true},
	["Nicaragua"] = {container = "Central America", divs = {"departments", "municipalities"}},
	["Niger"] = {container = "Africa", divs = {"regions", "departments"}},
	["Nigeria"] = {container = "Africa", divs = {"states", "local government areas"}, british_spelling = true},
	["North Korea"] = {container = "Asia", addl_parents = {"Korea"}, divs = {"provinces", "counties"}},
	["North Macedonia"] = {container = "Europe", divs = {"regions", "municipalities"}, british_spelling = true},
	["Macedonia"] = {alias_of = "North Macedonia", display = true},
	["Republic of North Macedonia"] = {alias_of = "North Macedonia", the = true}, -- differs in "the"
	["Republic of Macedonia"] = {alias_of = "North Macedonia", the = true}, -- differs in "the"
	["Norway"] = {container = "Europe", divs = {"counties", "municipalities", "dependent territories", "districts"},
		british_spelling = true},
	["Oman"] = {container = "Asia", divs = {"governorates", "provinces"}},
	["Pakistan"] = {container = "Asia", divs = {"provinces", "divisions", "districts",
		{type = "administrative territories", cat_as = "territories"},
		{type = "federal territories", cat_as = "territories"}},
		addl_divs_for_categorization = {"provinces and territories"}, british_spelling = true},
	["Palestine"] = {container = "Asia", divs = {"governorates"}},
	["State of Palestine"] = {alias_of = "Palestine", the = true}, -- differs in "the"
	["Palau"] = {container = "Micronesia", divs = {"states"}},
	["Panama"] = {container = "Central America", divs = {"provinces", "districts"}},
	["Papua New Guinea"] = {container = "Melanesia", divs = {"provinces", "districts"}, british_spelling = true},
	["Paraguay"] = {container = "South America", divs = {"departments", "districts"}},
	["Peru"] = {container = "South America", divs = {"regions", "provinces", "districts"}},
	["Philippines"] = {the = true, container = "Asia", divs = {"regions", "provinces", "districts", "municipalities", "barangays"}},
	["Poland"] = {divs = {"voivodeships", "counties",
		{type = "Polish colonies", cat_as = {{type = "villages", prep = "in"}}},
	}, container = "Europe", british_spelling = true},
	["Portugal"] = {container = "Europe", divs = {
		{type = "autonomous regions", cat_as = "districts and autonomous regions"},
		{type = "districts", cat_as = "districts and autonomous regions"},
		"provinces", "municipalities"}, british_spelling = true},
	["Qatar"] = {container = "Asia", divs = {"municipalities", "zones"}},
	["Republic of the Congo"] = {the = true, container = "Africa", divs = {"departments", "districts"}},
	["Congo Republic"] = {alias_of = "Republic of the Congo", display = true, the = true},
	["Romania"] = {container = "Europe", divs = {"regions", "counties", "communes"}, british_spelling = true},
	["Russia"] = {container = {"Europe", "Asia"}, divs = {
		"federal subjects", "republics", "autonomous oblasts", "autonomous okrugs", "oblasts", "krais", "federal cities",
		"districts", "federal districts"},
		british_spelling = true},
	["Rwanda"] = {container = "Africa", divs = {"provinces", "districts"}},
	["Saint Kitts and Nevis"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Saint Lucia"] = {container = "North America", divs = {"districts"}, british_spelling = true},
	["Saint Vincent and the Grenadines"] = {container = "North America", divs = {"parishes"}, british_spelling = true},
	["Samoa"] = {container = "Polynesia", divs = {"districts"}, british_spelling = true},
	["San Marino"] = {container = "Europe", divs = {"municipalities"}, british_spelling = true},
	["São Tomé and Príncipe"] = {container = "Africa", divs = {"districts"}},
	["Saudi Arabia"] = {container = "Asia", divs = {"provinces", "governorates"}},
	["Senegal"] = {container = "Africa", divs = {"regions", "departments"}},
	["Serbia"] = {container = "Europe", divs = {"districts", "municipalities"}}, 
	["Seychelles"] = {container = "Africa", divs = {"districts"}, british_spelling = true},
	["Sierra Leone"] = {container = "Africa", divs = {"provinces", "districts"}, british_spelling = true},
	["Singapore"] = {container = "Asia", divs = {"districts"}, british_spelling = true},
	["Slovakia"] = {container = "Europe", divs = {"regions", "districts"}, british_spelling = true},
	["Slovenia"] = {container = "Europe", divs = {"municipalities"}, british_spelling = true},
	-- Note: the official name does not include "the" at the beginning, but it sounds strange in
	-- English to leave it out and it's commonly included, so we include it.
	["Solomon Islands"] = {the = true, container = "Melanesia", divs = {"provinces"}, british_spelling = true},
	["Somalia"] = {container = "Africa", divs = {"regions", "districts"}},
	["South Africa"] = {container = "Africa", divs = {"provinces", "districts"}, british_spelling = true},
	["South Korea"] = {container = "Asia", addl_parents = {"Korea"}, divs = {"provinces", "counties", "districts"}},
	["South Sudan"] = {container = "Africa", divs = {"regions", "states", "counties"}, british_spelling = true},
	["Spain"] = {container = "Europe", divs = {"autonomous communities", "provinces", "municipalities", "autonomous cities"},
		british_spelling = true},
	["Sri Lanka"] = {container = "Asia", divs = {"provinces", "districts"}, british_spelling = true},
	["Sudan"] = {container = "Africa", divs = {"states", "districts"}, british_spelling = true},
	["Suriname"] = {container = "South America", divs = {"districts"}},
	["Sweden"] = {container = "Europe", divs = {"provinces", "counties", "municipalities"}, british_spelling = true},
	["Switzerland"] = {container = "Europe", divs = {"cantons", "municipalities", "districts"}, british_spelling = true},
	["Syria"] = {container = "Asia", divs = {"governorates", "districts"}},
	["Taiwan"] = {container = "Asia", divs = {"counties", "districts"}},
	["Republic of China"] = {alias_of = "Taiwan", the = true}, -- differs in "the", different political connotations
	["Tajikistan"] = {container = "Asia", divs = {"regions", "districts"}},
	["Tanzania"] = {container = "Africa", divs = {"provinces", "districts"}, british_spelling = true},
	["Thailand"] = {container = "Asia", divs = {"provinces", "districts", "subdistricts"}},
	["Togo"] = {container = "Africa", divs = {"provinces", "prefectures"}},
	["Tonga"] = {container = "Polynesia", divs = {"divisions"}, british_spelling = true},
	["Trinidad and Tobago"] = {container = "North America", divs = {"regions", "municipalities"}, british_spelling = true},
	["Tunisia"] = {container = "Africa", divs = {"governorates", "delegations"}},
	["Turkey"] = {container = {"Europe", "Asia"}, divs = {"provinces", "districts"}},
	-- Foreign names generally get display-canonicalized.
	["Türkiye"] = {alias_of = "Turkey", display = true},
	["Turkmenistan"] = {container = "Asia", divs = {"regions", "districts"}},
	["Tuvalu"] = {container = "Polynesia", divs = {"atolls"}, british_spelling = true},
	["Uganda"] = {container = "Africa", divs = {"districts", "counties"}, british_spelling = true},
	["Ukraine"] = {container = "Europe", divs = {"oblasts", "municipalities", "raions"}, british_spelling = true},
	["United Arab Emirates"] = {the = true, container = "Asia", divs = {"emirates"}},
	-- Abbreviations get display-canonicalized.
	["UAE"] = {alias_of = "United Arab Emirates", display = true, the = true},
	["U.A.E."] = {alias_of = "United Arab Emirates", display = true, the = true},
	["United Kingdom"] = {the = true, container = "Europe", addl_parents = {"British Isles"},
		divs = {"constituent countries", "counties", "districts", "boroughs", "territories", "dependent territories",
			"traditional counties"},
		keydesc = "the [[United Kingdom]] of Great Britain and Northern Ireland", british_spelling = true},
	-- Abbreviations get display-canonicalized.
	["UK"] = {alias_of = "United Kingdom", display = true, the = true},
	["U.K."] = {alias_of = "United Kingdom", display = true, the = true},
	["United States"] = {the = true, container = "North America",
		divs = {"counties", "county seats", "states", "territories", "dependent territories",
			{type = "boroughs", prep = "in"}, -- exist in Pennsylvania and New Jersey
			"municipalities", -- these exist politically at least in Colorado and Connecticut
			{type = "census-designated places", prep = "in"},
			-- Don't change the following to something more politically correct until/unless the US government makes a
			-- similar switch (and note that as of Apr 18 2025, the Wikipedia article is still at
			-- [[w:Indian reservations]]).
			"Indian reservations",
		}},
	-- Abbreviations and long forms (when possible) get display-canonicalized.
	["US"] = {alias_of = "United States", display = true, the = true},
	["U.S."] = {alias_of = "United States", display = true, the = true},
	["USA"] = {alias_of = "United States", display = true, the = true},
	["U.S.A."] = {alias_of = "United States", display = true, the = true},
	["United States of America"] = {alias_of = "United States", display = true, the = true},
	["Uruguay"] = {container = "South America", divs = {"departments", "municipalities"}},
	["Uzbekistan"] = {container = "Asia", divs = {"regions", "districts"}},
	["Vanuatu"] = {container = "Melanesia", divs = {"provinces"}, british_spelling = true},
	["Vatican City"] = {placetype = {"city-state", "country"}, container = "Europe", addl_parents = {"Rome"},
		is_city = true, british_spelling = true},
	["Vatican"] = {alias_of = "Vatican City", the = true}, -- differs in "the"
	["Venezuela"] = {container = "South America", divs = {"states", "municipalities"}},
	["Vietnam"] = {container = "Asia", divs = {"provinces", "districts", "municipalities"}},
	["Western Sahara"] = {placetype = {"territory", "country"}, container = "Africa"},
	["Yemen"] = {container = "Asia", divs = {"governorates", "districts"}},
	["Zambia"] = {container = "Africa", divs = {"provinces", "districts"}, british_spelling = true},
	["Zimbabwe"] = {container = "Africa", divs = {"provinces", "districts"}, british_spelling = true},
}

local function canonicalize_continent_container(key)
	if type(key) ~= "string" then
		return key
	end
	if export.continents[key] then
		return {key = key, placetype = export.continents[key].placetype}
	end
	internal_error("Unrecognized key %s in `canonicalize_continent_like`", key)
end

export.countries_group = {
	canonicalize_key_container = canonicalize_continent_container,
	default_overriding_bare_label_parents = {"countries", "+++"},
	default_placetype = "country",
	default_no_container_cat = true,
	data = export.countries,
}

-- Country-like entities: typically overseas territories or de-facto independent countries, which in both cases
-- are not internationally recognized as sovereign nations but which we treat similarly to countries.
export.country_like_entities = {
	-- British Overseas Territory
	["Akrotiri and Dhekelia"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Cyprus", "Europe"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["American Samoa"] = {
		placetype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Polynesia"},
	},
	["United States Minor Outlying Islands"] = {
		the = true,
		placetype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Islands", "Micronesia", "Polynesia"},
	},
	-- British Overseas Territory
	["Anguilla"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Georgia
	["Abkhazia"] = {
		placetype = {"unrecognized state", "country"},
		addl_parents = {"Georgia", "Europe", "Asia"},
		divs = {"districts"},
		keydesc = "the de-facto independent state of [[Abkhazia]], internationally recognized as part of the country of [[Georgia]]",
		british_spelling = true,
	},
	-- de-facto independent state of Armenian ethnicity, internationally recognized as part of Azerbaijan
	-- (also known as Nagorno-Karabakh)
	-- NOTE: Formerly listed Armenia as a parent; this seems politically non-neutral so I've taken it out.
	["Artsakh"] = {
		placetype = {"unrecognized state", "country"},
		addl_parents = {"Azerbaijan", "Europe", "Asia"},
		keydesc = "the former de-facto independent state of [[Artsakh]], internationally recognized as part of [[Azerbaijan]]",
		british_spelling = true,
	},
	["Nagorno-Karabakh"] = {alias_of = "Artsakh"},
	-- British Overseas Territory
	["Ascension Island"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Atlantic Ocean"},
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Aruba"] = {
		placetype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Bonaire"] = {
		placetype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"North America"},
		is_city = true,
		british_spelling = true,
	},
	-- British Overseas Territory
	["Bermuda"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["British Indian Ocean Territory"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["British Virgin Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Cayman Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- Australian external territory
	["Christmas Island"] = {
		placetype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Asia"},
		british_spelling = true,
	},
	-- Australian external territory; also called the Keeling Islands or (officially) the Cocos (Keeling) Islands
	["Cocos Islands"] = {
		the = true,
		placetype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Asia"},
		wp = "Cocos (Keeling) Islands",
		british_spelling = true,
	},
	-- self-governing but in free association with New Zealand
	["Cook Islands"] = {
		the = true,
		placetype = {"country"},
		container = "New Zealand",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Curaçao"] = {
		placetype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- special territory of Chile
	["Easter Island"] = {
		placetype = {"special territory", "territory"},
		container = "Chile",
		addl_parents = {"Polynesia"},
	},
	-- British Overseas Territory
	["Falkland Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"South America"},
		british_spelling = true,
	},
	-- autonomous territory of Denmark
	["Faroe Islands"] = {
		the = true,
		placetype = {"autonomous territory", "territory"},
		container = "Denmark",
		addl_parents = {"Europe"},
		british_spelling = true,
	},
	-- overseas department of France
	["French Guiana"] = {
		placetype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"South America"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["French Polynesia"] = {
		placetype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Gibraltar"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Europe"},
		is_city = true,
		british_spelling = true,
	},
	-- autonomous territory of Denmark
	["Greenland"] = {
		placetype = {"autonomous territory", "territory"},
		container = "Denmark",
		addl_parents = {"North America"},
		divs = {"municipalities"},
		british_spelling = true,
	},
	-- overseas department of France
	["Guadeloupe"] = {
		placetype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["Guam"] = {
		placetype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Micronesia"},
	},
	-- self-governing British Crown dependency; technically called the Bailiwick of Guernsey
	["Guernsey"] = {
		placetype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- special administrative region of China
	["Hong Kong"] = {
		placetype = {"special administrative region", "city"},
		container = "China",
		is_city = true,
		british_spelling = true,
	},
	-- self-governing British Crown dependency
	["Isle of Man"] = {
		the = true,
		placetype = {"crown dependency", "dependency", "dependent territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- self-governing British Crown dependency; technically called the Bailiwick of Jersey
	["Jersey"] = {
		placetype = {"crown dependency", "dependency", "dependent territory", "bailiwick", "territory"},
		container = "United Kingdom",
		addl_parents = {"British Isles", "Europe"},
		british_spelling = true,
	},
	-- special administrative region of China
	["Macau"] = {
		placetype = {"special administrative region", "city"},
		container = "China",
		is_city = true,
		british_spelling = true,
	},
	-- overseas department of France
	["Martinique"] = {
		placetype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- overseas department of France
	["Mayotte"] = {
		placetype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"Africa"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Montserrat"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- special collectivity of France
	["New Caledonia"] = {
		placetype = {"special collectivity", "collectivity"},
		container = "France",
		addl_parents = {"Melanesia"},
		british_spelling = true,
	},
	-- self-governing but in free association with New Zealand
	["Niue"] = {
		placetype = {"country"},
		container = "New Zealand",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- Australian external territory
	["Norfolk Island"] = {
		placetype = {"external territory", "territory"},
		container = "Australia",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- commonwealth, unincorporated territory of the United States
	["Northern Mariana Islands"] = {
		the = true,
		placetype = {"commonwealth", "unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"Micronesia"},
	},
	-- British Overseas Territory
	["Pitcairn Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- commonwealth of the United States
	["Puerto Rico"] = {
		placetype = {"commonwealth", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"North America"},
		divs = {"municipalities"},
	},
	-- overseas department of France
	["Réunion"] = {
		placetype = {"overseas department", "department", "administrative region", "region"},
		container = "France",
		addl_parents = {"Africa"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Saba"] = {
		placetype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"North America"},
		is_city = true,
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Barthélemy"] = {
		placetype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Saint Helena"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Atlantic Ocean"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Martin"] = {
		placetype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- overseas collectivity of France
	["Saint Pierre and Miquelon"] = {
		placetype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- special municipality of the Netherlands
	["Sint Eustatius"] = {
		placetype = {"special municipality", "municipality", "overseas territory", "territory"},
		container = "Netherlands",
		addl_parents = {"North America"},
		is_city = true,
		british_spelling = true,
	},
	-- constituent country of the Netherlands
	["Sint Maarten"] = {
		placetype = {"constituent country", "country"},
		container = "Netherlands",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["South Georgia"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Atlantic Ocean"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Georgia
	["South Ossetia"] = {
		placetype = {"unrecognized state", "country"},
		addl_parents = {"Georgia", "Europe", "Asia"},
		keydesc = "the de-facto independent state of [[South Ossetia]], internationally recognized as part of the country of [[Georgia]]",
		british_spelling = true,
	},
	-- British Overseas Territory
	["South Sandwich Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Atlantic Ocean"},
		wp = true,
		wpcat = "South Georgia and the South Sandwich Islands",
		british_spelling = true,
	},
	-- dependent territory of New Zealnd
	["Tokelau"] = {
		placetype = {"dependent territory", "territory"},
		container = "New Zealand",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
	-- de-facto independent state, internationally recognized as part of Moldova
	["Transnistria"] = {
		placetype = {"unrecognized state", "country"},
		addl_parents = {"Moldova", "Europe"},
		keydesc = "the de-facto independent state of [[Transnistria]], internationally recognized as part of [[Moldova]]",
		british_spelling = true,
	},
	-- British Overseas Territory
	["Tristan da Cunha"] = {
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"Atlantic Ocean"},
		british_spelling = true,
	},
	-- British Overseas Territory
	["Turks and Caicos Islands"] = {
		the = true,
		placetype = {"overseas territory", "territory"},
		container = "United Kingdom",
		addl_parents = {"North America"},
		british_spelling = true,
	},
	-- unincorporated territory of the United States
	["United States Virgin Islands"] = {
		the = true,
		placetype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"North America"},
	},
	["U.S. Virgin Islands"] = {alias_of = "United States Virgin Islands", display = true, the = true},
	["US Virgin Islands"] = {alias_of = "United States Virgin Islands", display = true, the = true},
	-- unincorporated territory of the United States
	["Wake Island"] = {
		placetype = {"unincorporated territory", "overseas territory", "territory"},
		container = "United States",
		addl_parents = {"North America"},
	},
	-- overseas collectivity of France
	["Wallis and Futuna"] = {
		placetype = {"overseas collectivity", "collectivity"},
		container = "France",
		addl_parents = {"Polynesia"},
		british_spelling = true,
	},
}

export.country_like_entities_group = {
	canonicalize_key_container = make_canonicalize_key_container(nil, "country"),
	default_overriding_bare_label_parents = {"country-like entities"},
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
	["Persia"] = {placetype = {"empire", "country"}, container = "Asia", divs = {"provinces"}},
	["Roman Empire"] = {
		the = true, placetype = {"empire", "country"}, container = {"Europe", "Africa", "Asia"}, addl_parents = {"Rome"},
		divs = {
			"provinces",
			{type = "FORMER provinces", cat_as = "provinces"},
		}},
	["South Vietnam"] = {container = "Asia", addl_parents = {"Vietnam"}},
	["Soviet Union"] = {
		the = true, container = {"Europe", "Asia"}, divs = {"republics", "autonomous republics"},
		british_spelling = true},
	["West Germany"] = {container = "Europe", addl_parents = {"Germany"}, british_spelling = true},
	["Yugoslavia"] = {container = "Europe", divs = {"districts"},
		keydesc = "the former [[Kingdom of Yugoslavia]] (1918–1943) or the former [[Socialist Federal Republic of Yugoslavia]] (1943–1992)", british_spelling = true},
}

export.former_countries_group = {
	default_overriding_bare_label_parents = {"former countries and country-like entities"},
	default_is_former_place = true,
	default_placetype = "country",
	data = export.former_countries,
}

-----------------------------------------------------------------------------------
--                                  Subpolity tables                             --
-----------------------------------------------------------------------------------

export.australia_states_and_territories = {
	["Australian Capital Territory, Australia"] = {the = true, placetype = "territory"},
	["New South Wales, Australia"] = {},
	["Northern Territory, Australia"] = {the = true, placetype = "territory"},
	["Queensland, Australia"] = {},
	["South Australia, Australia"] = {},
	["Tasmania, Australia"] = {},
	["Victoria, Australia"] = {},
	["Western Australia, Australia"] = {},
}

-- states and territories of Australia
export.australia_group = {
	default_container = "Australia",
	default_placetype = "state",
	default_div_parent_type = "states and territories",
	default_divs = {"local government areas"},
	default_british_spelling = true,
	data = export.australia_states_and_territories,
}

export.austria_states = {
	["Vienna, Austria"] = {},
	["Lower Austria, Austria"] = {},
	["Upper Austria, Austria"] = {},
	["Styria, Austria"] = {},
	["Tyrol, Austria"] = {wp = "Tyrol (state)"},
	["Carinthia, Austria"] = {},
	["Salzburg, Austria"] = {wp = "Salzburg (state)"},
	["Vorarlberg, Austria"] = {},
	["Burgenland, Austria"] = {},
}

-- states of Austria
export.austria_group = {
	default_container = "Austria",
	default_placetype = "state",
	default_british_spelling = true,
	default_divs = "municipalities",
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
	default_placetype = "division",
	default_british_spelling = true,
	default_divs = "districts",
	data = export.bangladesh_divisions,
}

export.brazil_states = {
	["Acre, Brazil"] = {wp = "%l (state)"},
	["Alagoas, Brazil"] = {},
	["Amapá, Brazil"] = {},
	["Amazonas, Brazil"] = {wp = "%l (Brazilian state)"},
	["Bahia, Brazil"] = {},
	["Ceará, Brazil"] = {},
	["Distrito Federal, Brazil"] = {wp = "Federal District (Brazil)"},
	["Espírito Santo, Brazil"] = {},
	["Goiás, Brazil"] = {},
	["Maranhão, Brazil"] = {},
	["Mato Grosso, Brazil"] = {},
	["Mato Grosso do Sul, Brazil"] = {},
	["Minas Gerais, Brazil"] = {},
	["Pará, Brazil"] = {},
	["Paraíba, Brazil"] = {},
	["Paraná, Brazil"] = {wp = "%l (state)"},
	["Pernambuco, Brazil"] = {},
	["Piauí, Brazil"] = {},
	["Rio de Janeiro, Brazil"] = {wp = "%l (state)"},
	["Rio Grande do Norte, Brazil"] = {},
	["Rio Grande do Sul, Brazil"] = {},
	["Rondônia, Brazil"] = {},
	["Roraima, Brazil"] = {},
	["Santa Catarina, Brazil"] = {wp = "%l (state)"},
	["São Paulo, Brazil"] = {wp = "%l (state)"},
	["Sergipe, Brazil"] = {},
	["Tocantins, Brazil"] = {},
}

-- states of Brazil
export.brazil_group = {
	default_container = "Brazil",
	default_placetype = "state",
	default_divs = "municipalities",
	data = export.brazil_states,
}

export.canada_provinces_and_territories = {
	["Alberta, Canada"] = {divs = {
		{type = "municipal districts", skip_polity_parent_type = "rural municipalities"},
	}},
	["British Columbia, Canada"] = {divs =
		{type = "regional districts", skip_polity_parent_type = false},
		"regional municipalities",
	},
	["Manitoba, Canada"] = {divs = {"rural municipalities"}},
	["New Brunswick, Canada"] = {divs = {"counties", "parishes", {type = "civil parishes", cat_as = "parishes"}}},
	["Newfoundland and Labrador, Canada"] = {},
	["Northwest Territories, Canada"] = {the = true, placetype = "territory"},
	["Nova Scotia, Canada"] = {divs = {"counties", "regional municipalities"}},
	["Nunavut, Canada"] = {placetype = "territory"},
	["Ontario, Canada"] = {divs = {"counties", "regional municipalities", {type = "townships", prep = "in"}}},
	["Prince Edward Island, Canada"] = {divs = {"counties", "parishes", "rural municipalities"}},
	["Saskatchewan, Canada"] = {divs = {"rural municipalities"}},
	["Quebec, Canada"] = {divs = {
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
	["Yukon, Canada"] = {placetype = "territory"},
}

-- provinces and territories of Canada
export.canada_group = {
	default_container = "Canada",
	default_placetype = "province",
	default_british_spelling = true,
	data = export.canada_provinces_and_territories,
}

export.china_provinces_and_autonomous_regions = {
	["Anhui, China"] = {},
	["Beijing, China"] = {placetype = {"direct-administered municipality", "municipality"}},
	["Chongqing, China"] = {placetype = {"direct-administered municipality", "municipality"}},
	["Fujian, China"] = {},
	["Fuchien, China"] = {alias_of = "Fujian, China", display = true},
	["Gansu, China"] = {},
	["Guangdong, China"] = {},
	["Guangxi, China"] = {placetype = "autonomous region"},
	["Guizhou, China"] = {},
	["Hainan, China"] = {},
	["Hebei, China"] = {},
	["Heilongjiang, China"] = {},
	["Henan, China"] = {},
	["Hubei, China"] = {},
	["Hunan, China"] = {},
	["Inner Mongolia, China"] = {placetype = "autonomous region"},
	["Jiangsu, China"] = {},
	["Jiangxi, China"] = {},
	["Jilin, China"] = {},
	["Liaoning, China"] = {},
	["Ningxia, China"] = {placetype = "autonomous region"},
	["Qinghai, China"] = {},
	["Shaanxi, China"] = {},
	["Shandong, China"] = {},
	["Shanghai, China"] = {placetype = {"direct-administered municipality", "municipality"}},
	["Shanxi, China"] = {},
	["Sichuan, China"] = {},
	["Tianjin, China"] = {placetype = {"direct-administered municipality", "municipality"}},
	["Tibet, China"] = {placetype = "autonomous region", wp = "Tibet Autonomous Region"},
	["Xinjiang, China"] = {placetype = "autonomous region"},
	["Yunnan, China"] = {},
	["Zhejiang, China"] = {},
}

-- provinces and autonomous regions of China
export.china_group = {
	default_container = "China",
	default_placetype = "province",
	default_divs = {"prefecture-level cities", "county-level cities", "districts"},
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
	["Chongqing"] = {placetype = {"direct-administered municipality", "municipality"}}, -- 32.1 prefectural, 16.9 urban
	["Shanghai"] = {placetype = {"direct-administered municipality", "municipality"}}, -- 24.9 prefectural, 29.9 urban
	["Beijing"] = {placetype = {"direct-administered municipality", "municipality"}}, -- 21.9 prefectural, 21.9 urban
	["Chengdu"] = {container = "Sichuan"}, -- 20.9 prefectural, 16.9 urban; sub-provincial city
	["Guangzhou"] = {container = "Guangdong"}, -- 18.7 prefectural, 18.8 urban; sub-provincial city
	["Shenzhen"] = {container = "Guangdong"}, -- 17.5 prefectural, 14.7 urban; sub-provincial city
	["Tianjin"] = {placetype = {"direct-administered municipality", "municipality"}}, -- 13.9 prefectural, 13.9 urban
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
	["Nanyang"] = {container = "Henan", wp = "%l, %c"}, -- 9.7 prefectural, 2.1 urban/metro
	["Wenzhou"] = {container = "Zhejiang"}, -- 9.6 prefectural, 3.6 urban
	["Foshan"] = {container = "Guangdong"}, -- 9.5 prefectural, 9.5 urban
	["Handan"] = {container = "Hebei"}, -- 9.4 prefectural, 2.8 urban
	["Ningbo"] = {container = "Zhejiang"}, -- 9.4 prefectural, 5.1 urban; sub-provincial city
	["Weifang"] = {container = "Shandong"}, -- 9.4 prefectural, 2.7 urban
	["Hefei"] = {container = "Anhui"}, -- 9.4 prefectural, 4.2 urban
	["Nanjing"] = {container = "Jiangsu"}, -- 9.3 prefectural, 9.3 urban; sub-provincial city
	-- includes Láiwú city
	["Jinan"] = {container = "Shandong", wp = "%l, %c"}, -- 9.2 prefectural, 8.4 urban; sub-provincial city
	["Xuzhou"] = {container = "Jiangsu"}, -- 9.1 prefectural, 2.6 urban
	["Shenyang"] = {container = "Liaoning"}, -- 9.1 prefectural, 7.9 urban; sub-provincial city
	["Changchun"] = {container = "Jilin"}, -- 9.1 prefectural, 5.7 urban; sub-provincial city
	["Zhoukou"] = {container = "Henan"}, -- 9.0 prefectural, 721,000 urban (1.6 metro)
	["Ganzhou"] = {container = "Jiangxi"}, -- 9.0 prefectural, 1.6 urban
	["Heze"] = {container = "Shandong"}, -- 8.8 prefectural, 1.3 urban
	["Quanzhou"] = {container = "Fujian"}, -- 8.8 prefectural, 1.7 urban (6.7 metro)
	["Nanning"] = {container = {key = "Guangxi, China", placetype = "autonomous region"}}, -- 8.7 prefectural, 3.8 urban
	["Kunming"] = {container = "Yunnan"}, -- 8.5 prefectural, 6.0 urban
	["Jining"] = {container = "Shandong"}, -- 8.4 prefectural, 1.5 urban
	["Fuzhou"] = {container = "Fujian"}, -- 8.3 prefectural, 4.1 urban
	["Fuyang"] = {container = "Anhui", wp = "%l, %c"}, -- 8.2 prefectural, 2.1 urban
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
	["Taizhou"] = {container = "Zhejiang", wp = "%l, %c"}, -- 6.6 prefectural, 1.6 urban
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
	["Liuzhou"] = {container = {key = "Guangxi, China", placetype = "autonomous region"}}, -- 4.157 prefectural, 2.2 urban
	["Ürümqi"] = {container = {key = "Xinjiang, China", placetype = "autonomous region"}}, -- 4.054 prefectural, 4.3 urban
	["Urumqi"] = {alias_of = "Ürümqi", display = true},
	["Hohhot"] = {container = {key = "Inner Mongolia, China", placetype = "autonomous region"}}, -- 3.446 prefectural, 2.7 urban
	["Putian"] = {container = "Fujian"}, -- 3.210 prefectural, 2.0 urban
	["Datong"] = {container = "Shanxi"}, -- 3.105 prefectural, 2.0 urban
	["Haikou"] = {container = "Hainan"}, -- 2.873 prefectural, 2.3 urban
	["Baotou"] = {container = {key = "Inner Mongolia, China", placetype = "autonomous region"}}, -- 2.709 prefectural, 2.2 urban
	["Zhuhai"] = {container = "Guangdong"}, -- 2.439 prefectural, 2.4 urban
}

export.china_prefecture_level_cities_group = {
	default_container = "China",
	canonicalize_key_container = make_canonicalize_key_container(", China", "province"),
	default_placetype = "prefecture-level city",
	default_divs = {
		"districts",
		"counties",
		{type = "county-level cities", cat_as = "counties and county-level cities"},
	},
	data = export.china_prefecture_level_cities,
}

export.finland_regions = {
	["Lapland, Finland"] = {wp = "%l (%c)"},
	["North Ostrobothnia, Finland"] = {},
	["Northern Ostrobothnia, Finland"] = {alias_of = "North Ostrobothnia, Finland", display = true},
	["Kainuu, Finland"] = {},
	["North Karelia, Finland"] = {},
	["Northern Savonia, Finland"] = {},
	["North Savo, Finland"] = {alias_of = "Northern Savonia, Finland", display = true},
	["Southern Savonia, Finland"] = {},
	["South Savo, Finland"] = {alias_of = "Southern Savonia, Finland", display = true},
	["South Karelia, Finland"] = {},
	["Central Finland, Finland"] = {},
	["South Ostrobothnia, Finland"] = {},
	["Southern Ostrobothnia, Finland"] = {alias_of = "South Ostrobothnia, Finland", display = true},
	["Ostrobothnia, Finland"] = {wp = "%l (region)"},
	["Central Ostrobothnia, Finland"] = {},
	["Pirkanmaa, Finland"] = {},
	["Satakunta, Finland"] = {},
	["Päijänne Tavastia, Finland"] = {},
	["Päijät-Häme, Finland"] = {alias_of = "Päijänne Tavastia, Finland", display = true},
	["Tavastia Proper, Finland"] = {},
	["Kanta-Häme, Finland"] = {alias_of = "Tavastia Proper, Finland", display = true},
	["Kymenlaakso, Finland"] = {},
	["Uusimaa, Finland"] = {},
	["Southwest Finland, Finland"] = {},
	["Åland Islands, Finland"] = {the = true},
	["Åland, Finland"] = {alias_of = "Åland Islands"}, -- differs in "the"
}

-- regions of Finland
export.finland_group = {
	default_container = "Finland",
	default_placetype = "region",
	default_divs = "municipalities",
	default_british_spelling = true,
	data = export.finland_regions,
}

export.france_administrative_regions = {
	["Auvergne-Rhône-Alpes, France"] = {},
	["Bourgogne-Franche-Comté, France"] = {},
	["Brittany, France"] = {wp = "%l (administrative region)"},
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
	["Normandy, France"] = {wp = "%l (administrative region)"},
	["Nouvelle-Aquitaine, France"] = {},
	["Occitania, France"] = {wp = "%l (administrative region)"},
	["Occitanie, France"] = {alias_of = "Occitania, France", display = true},
	["Pays de la Loire, France"] = {},
	["Provence-Alpes-Côte d'Azur, France"] = {},
	-- ["Réunion"] = {},
}

-- administrative regions of France
export.france_group = {
	default_container = "France",
	-- Canonically these are 'administrative regions' but also categorize if identified as a 'region'.
	default_placetype = {"administrative region", "region"},
	default_div_parent_type = "regions",
	default_british_spelling = true,
	data = export.france_administrative_regions,
}

export.germany_states = {
	["Baden-Württemberg, Germany"] = {},
	["Bavaria, Germany"] = {},
	-- Berlin, Bremen and Hamburg are effectively city-states and don't have districts ([[Kreise]]), so override
	-- the default_divs setting. Better not to include them at all since they're included as cities down below.
	-- ["Berlin"] = {divs = {}},
	["Brandenburg, Germany"] = {},
	-- ["Bremen"] = {divs = {}},
	-- ["Hamburg"] = {divs = {}},
	["Hesse, Germany"] = {},
	["Lower Saxony, Germany"] = {},
	["Mecklenburg-Vorpommern, Germany"] = {},
	["Mecklenburg-Western Pomerania, Germany"] = {alias_of = "Mecklenburg-Vorpommern, Germany", display = true},
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
	default_container = "Germany",
	default_placetype = "state",
	default_divs = "districts",
	default_british_spelling = true,
	data = export.germany_states,
}

local india_polity_with_divisions = {"divisions", "districts"}
local india_polity_without_divisions = {"districts"}

-- States and union territories of India. Only some of them are divided into divisions.
export.india_states_and_union_territories = {
	["Andaman and Nicobar Islands, India"] =
		{the = true, placetype = "union territory", divs = india_polity_without_divisions},
	["Andhra Pradesh, India"] = {divs = india_polity_without_divisions},
	["Arunachal Pradesh, India"] = {divs = india_polity_with_divisions},
	["Assam, India"] = {divs = india_polity_with_divisions},
	["Bihar, India"] = {divs = india_polity_with_divisions},
	["Chandigarh, India"] = {placetype = "union territory", divs = india_polity_without_divisions},
	["Chhattisgarh, India"] = {divs = india_polity_with_divisions},
	["Dadra and Nagar Haveli and Daman and Diu, India"] = {placetype = "union territory", divs = india_polity_without_divisions},
	["Delhi, India"] = {placetype = "union territory", divs = india_polity_with_divisions},
	["Goa, India"] = {divs = india_polity_without_divisions},
	["Gujarat, India"] = {divs = india_polity_without_divisions},
	["Haryana, India"] = {divs = india_polity_with_divisions},
	["Himachal Pradesh, India"] = {divs = india_polity_with_divisions},
	["Jammu and Kashmir, India"] = {placetype = "union territory", divs = india_polity_with_divisions,
		wp = "%l (union territory)"},
	["Jharkhand, India"] = {divs = india_polity_with_divisions},
	["Karnataka, India"] = {divs = india_polity_with_divisions},
	["Kerala, India"] = {divs = india_polity_without_divisions},
	["Ladakh, India"] = {placetype = "union territory", divs = india_polity_with_divisions},
	["Lakshadweep, India"] = {placetype = "union territory", divs = india_polity_without_divisions},
	["Madhya Pradesh, India"] = {divs = india_polity_with_divisions},
	["Maharashtra, India"] = {divs = india_polity_with_divisions},
	["Manipur, India"] = {divs = india_polity_without_divisions},
	["Meghalaya, India"] = {divs = india_polity_with_divisions},
	["Mizoram, India"] = {divs = india_polity_without_divisions},
	["Nagaland, India"] = {divs = india_polity_with_divisions},
	["Odisha, India"] = {divs = india_polity_with_divisions},
	["Puducherry, India"] = {placetype = "union territory", divs = india_polity_without_divisions,
		wp = "%l (union territory)"},
	["Punjab, India"] = {divs = india_polity_with_divisions, wp = "%l, %c"},
	["Rajasthan, India"] = {divs = india_polity_with_divisions},
	["Sikkim, India"] = {divs = india_polity_without_divisions},
	["Tamil Nadu, India"] = {divs = india_polity_without_divisions},
	["Telangana, India"] = {divs = india_polity_without_divisions},
	["Tripura, India"] = {divs = india_polity_without_divisions},
	["Uttar Pradesh, India"] = {divs = india_polity_with_divisions},
	["Uttarakhand, India"] = {divs = india_polity_with_divisions},
	["West Bengal, India"] = {divs = india_polity_with_divisions},
}

-- states and union territories of India
export.india_group = {
	default_container = "India",
	default_placetype = "state",
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
	["Highland Papua, Indonesia"] = {wp = "%l (province)"},
	["Special Capital Region of Jakarta, Indonesia"] = {the = true, wp = "Jakarta"},
	["Jambi, Indonesia"] = {},
	["Lampung, Indonesia"] = {},
	["Maluku, Indonesia"] = {},
	["North Kalimantan, Indonesia"] = {},
	["North Maluku, Indonesia"] = {},
	["North Sulawesi, Indonesia"] = {},
	["North Papua, Indonesia"] = {},
	["North Sumatra, Indonesia"] = {},
	["Papua, Indonesia"] = {wp = "%l (province)"},
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
	["West Papua, Indonesia"] = {wp = "%l (province)"},
	["West Sulawesi, Indonesia"] = {},
	["West Sumatra, Indonesia"] = {},
	["Special Region of Yogyakarta, Indonesia"] = {the = true},
}

local function indonesia_key_to_placename(key)
	key = key:gsub(", Indonesia$", "")
	local special_region_city = key:match("^Special.* of (.*)$")
	if special_region_city then
		return key, special_region_city
	else
		return key, key
	end
end

local function indonesia_placename_to_key(placename)
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
	default_placetype = "province",
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

local function make_irish_type_key_to_placename(container_pattern)
	return function(key)
		key = key:gsub(container_pattern, "")
		local elliptical_key = key:gsub("^County ", "")
		return key, elliptical_key
	end
end

local function make_irish_type_placename_to_key(container_suffix)
	return function(placename)
		if not placename:find("^County ") and not placename:find("^City ") then
			placename = "County " .. placename
		end
		return placename .. container_suffix
	end
end

-- counties of Ireland
export.ireland_group = {
	key_to_placename = make_irish_type_key_to_placename(", Ireland$"),
	placename_to_key = make_irish_type_placename_to_key(", Ireland"),
	default_container = "Ireland",
	default_placetype = "county",
	default_british_spelling = true,
	data = export.ireland_counties,
}

export.italy_administrative_regions = {
	["Abruzzo, Italy"] = {},
	["Aosta Valley, Italy"] = {placetype = {"autonomous region", "administrative region", "region"}},
	["Apulia, Italy"] = {},
	["Basilicata, Italy"] = {},
	["Calabria, Italy"] = {},
	["Campania, Italy"] = {},
	["Emilia-Romagna, Italy"] = {},
	["Friuli-Venezia Giulia, Italy"] = {placetype = {"autonomous region", "administrative region", "region"}},
	["Lazio, Italy"] = {},
	["Liguria, Italy"] = {},
	["Lombardy, Italy"] = {},
	["Marche, Italy"] = {},
	["Molise, Italy"] = {},
	["Piedmont, Italy"] = {},
	["Sardinia, Italy"] = {placetype = {"autonomous region", "administrative region", "region"}},
	["Sicily, Italy"] = {placetype = {"autonomous region", "administrative region", "region"}},
	["Trentino-Alto Adige, Italy"] = {placetype = {"autonomous region", "administrative region", "region"}},
	["Tuscany, Italy"] = {},
	["Umbria, Italy"] = {},
	["Veneto, Italy"] = {},
}

-- administrative regions of Italy
export.italy_group = {
	default_container = "Italy",
	default_placetype = {"administrative region", "region"},
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
	["Hokkaido Prefecture, Japan"] = {divs = "subprefectures", wp = "Hokkaido"},
	["Hyōgo Prefecture, Japan"] = {},
	["Hyogo Prefecture, Japan"] = {alias_of = "Hyōgo Prefecture, Japan", display = true},
	["Ibaraki Prefecture, Japan"] = {},
	["Ishikawa Prefecture, Japan"] = {},
	["Iwate Prefecture, Japan"] = {},
	["Kagawa Prefecture, Japan"] = {},
	["Kagoshima Prefecture, Japan"] = {},
	["Kanagawa Prefecture, Japan"] = {},
	["Kōchi Prefecture, Japan"] = {},
	["Kochi Prefecture, Japan"] = {alias_of = "Kochi Prefecture, Japan", display = true},
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
	["Oita Prefecture, Japan"] = {alias_of = "Ōita Prefecture, Japan", display = true},
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
	["Tokyo"] = {keydesc = "[[Tokyo]] Metropolis",
		divs = {{type = "special wards", skip_polity_parent_type = false}},
		is_city = true,
	},
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
	default_placetype = "prefecture",
	data = export.japan_prefectures,
}

export.north_korea_provinces = {
	["Chagang Province, North Korea"] = {},
	["North Hamgyong Province, North Korea"] = {},
	["South Hamgyong Province, North Korea"] = {},
	["North Hwanghae Province, North Korea"] = {},
	["South Hwanghae Province, North Korea"] = {},
	["Kangwon Province, North Korea"] = {wp = "%l (%c)"},
	["North Pyongan Province, North Korea"] = {},
	["South Pyongan Province, North Korea"] = {},
	["Ryanggang Province, North Korea"] = {},
}

-- provinces of North Korea
export.north_korea_group = {
	key_to_placename = make_key_to_placename(", North Korea$", " Province$"),
	placename_to_key = make_placename_to_key(", North Korea", " Province"),
	default_container = "North Korea",
	default_placetype = "province",
	data = export.north_korea_provinces,
}

export.south_korea_provinces = {
	["North Chungcheong Province, South Korea"] = {},
	["South Chungcheong Province, South Korea"] = {},
	["Gangwon Province, South Korea"] = {wp = "%l, %c"},
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
	default_placetype = "province",
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
	["Vientiane Prefecture, Laos"] = {placetype = "prefecture", wp = "%l"},
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
	default_placetype = "province",
	-- For obscure reasons, provinces of Laos and Thailand use lowercase 'province'
	default_wp = "%e province",
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
	default_placetype = "governorate",
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
	default_container = "Malaysia",
	default_placetype = "state",
	default_british_spelling = true,
	default_wp = "%l, %c",
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
	["Gozo Region, Malta"] = {wp = "%l"},
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
	default_placetype = "region",
	default_british_spelling = true,
	default_the = true,
	data = export.malta_regions,
}

export.mexico_states = {
	["Aguascalientes, Mexico"] = {},
	["Baja California, Mexico"] = {},
	-- not display-canonicalizing because the "Norte" could be for emphasis
	["Baja California Norte, Mexico"] = {alias_of = "Baja California, Mexico"},
	["Baja California Sur, Mexico"] = {},
	["Campeche, Mexico"] = {},
	["Chiapas, Mexico"] = {},
	["Chihuahua, Mexico"] = {wp = "%l (state)"},
	["Coahuila, Mexico"] = {},
	["Colima, Mexico"] = {},
	["Durango, Mexico"] = {},
	["Guanajuato, Mexico"] = {},
	["Guerrero, Mexico"] = {},
	["Hidalgo, Mexico"] = {wp = "%l (state)"},
	["Jalisco, Mexico"] = {},
	["State of Mexico, Mexico"] = {the = true},
	["Mexico, Mexico"] = {alias_of = "State of Mexico, Mexico"}, -- differs in "the"
	-- ["Mexico City, Mexico"] = {}, doesn't belong here because it's a city
	["Michoacán, Mexico"] = {},
	["Michoacan, Mexico"] = {alias_of = "Michoacán, Mexico", display = true},
	["Morelos, Mexico"] = {},
	["Nayarit, Mexico"] = {},
	["Nuevo León, Mexico"] = {},
	["Nuevo Leon, Mexico"] = {alias_of = "Nuevo León, Mexico", display = true},
	["Oaxaca, Mexico"] = {},
	["Puebla, Mexico"] = {},
	["Querétaro, Mexico"] = {},
	["Queretaro, Mexico"] = {alias_of = "Querétaro, Mexico", display = true},
	["Quintana Roo, Mexico"] = {},
	["San Luis Potosí, Mexico"] = {},
	["San Luis Potosi, Mexico"] = {alias_of = "San Luis Potosí, Mexico", display = true},
	["Sinaloa, Mexico"] = {},
	["Sonora, Mexico"] = {},
	["Tabasco, Mexico"] = {},
	["Tamaulipas, Mexico"] = {},
	["Tlaxcala, Mexico"] = {},
	["Veracruz, Mexico"] = {},
	["Yucatán, Mexico"] = {},
	["Yucatan, Mexico"] = {alias_of = "Yucatán, Mexico", display = true},
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
	default_placetype = "state",
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
	default_container = "Morocco",
	default_placetype = "region",
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
	-- Foreign forms get display-canonicalized.
	["Noord-Brabant, Netherlands"] = {alias_of = "North Brabant, Netherlands", display = true},
	["North Holland, Netherlands"] = {},
	["Noord-Holland, Netherlands"] = {alias_of = "North Holland, Netherlands", display = true},
	["Overijssel, Netherlands"] = {},
	["South Holland, Netherlands"] = {},
	["Zuid-Holland, Netherlands"] = {alias_of = "South Holland, Netherlands", display = true},
	["Utrecht, Netherlands"] = {},
	["Zeeland, Netherlands"] = {},
}

-- provinces of the Netherlands
export.netherlands_group = {
	default_container = "Netherlands",
	default_placetype = "province",
	default_divs = "municipalities",
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
	default_placetype = "state",
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
	default_container = "Norway",
	default_placetype = "county",
	default_british_spelling = true,
	data = export.norwegian_counties,
}

export.pakistan_provinces_and_territories = {
	["Azad Kashmir, Pakistan"] = {
		placetype = {"administrative territory", "territory"},
	},
	["Azad Jammu and Kashmir, Pakistan"] = {alias_of = "Azad Kashmir, Pakistan", display = true},
	["Balochistan, Pakistan"] = {},
	["Gilgit-Baltistan, Pakistan"] = {
		placetype = {"administrative territory", "territory"},
	},
	["Islamabad Capital Territory, Pakistan"] = {
		the = true,
		divs = {}, -- no divisions
		placetype = {"federal territory", "administrative territory", "territory"},
	},
	-- Islamabad is an accepted alias for Islamabad Capital Territory given the above placetypes
	["Islamabad, Pakistan"] = {alias_of = "Islamabad Capital Territory, Pakistan"},
	["Khyber Pakhtunkhwa, Pakistan"] = {},
	["Punjab, Pakistan"] = {},
	["Sindh, Pakistan"] = {},
}

-- provinces and territories of Pakistan
export.pakistan_group = {
	default_container = "Pakistan",
	default_placetype = "province",
	default_div_parent_type = "provinces and territories",
	default_divs = {"divisions"},
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
	["Metro Manila, Philippines"] = {placetype = "region"},
}

-- provinces of the Philippines
export.philippines_group = {
	default_container = "Philippines",
	default_placetype = "province",
	default_divs = {"municipalities", "barangays"},
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
	default_placetype = "county",
	default_british_spelling = true,
	data = export.romania_counties,
}

local function make_russia_federal_subject_spec(spectype, use_the)
	return {the = not not use_the, placetype = spectype, div_parent_type = {"federal subjects", spectype .. "s"}}
end

local russia_autonomous_okrug =
	{placetype = {"autonomous okrug", "okrug"}, div_parent_type = {"federal subjects", "autonomous okrugs"}}
local russia_krai = make_russia_federal_subject_spec("krai")
local russia_oblast = make_russia_federal_subject_spec("oblast")
local russia_republic = make_russia_federal_subject_spec("republic", "use the")
export.russia_federal_subjects = {
	-- autonomous oblasts
	["Jewish Autonomous Oblast"] =
		{the = true, placetype = {"autonomous oblast", "oblast"},
		 div_parent_type = {"federal subjects", "autonomous oblasts"}},
	-- autonomous okrugs
	["Chukotka Autonomous Okrug"] = russia_autonomous_okrug,
	["Khanty-Mansi Autonomous Okrug"] = russia_autonomous_okrug,
	["Khantia-Mansia"] = {alias_of = "Khanty-Mansi Autonomous Okrug"},
	["Yugra"] = {alias_of = "Khanty-Mansi Autonomous Okrug"},
	["Nenets Autonomous Okrug"] = russia_autonomous_okrug,
	["Nenetsia"] = {alias_of = "Nenets Autonomous Okrug"},
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
	--
	-- We only need to include cases that aren't just shortened versions of the full federal subject name (i.e. where
	-- words like "Republic" and "Oblast" are omitted but the name is not otherwise modified; these are handled by
	-- key_to_placename). Non-display-canonicalizing aliases are generally due to differences in the presence or absence
	-- of "the".
	["Republic of Adygea"] = russia_republic,
	["Republic of Bashkortostan"] = russia_republic,
	["Bashkiria"] = {alias_of = "Republic of Bashkortostan"},
	["Republic of Buryatia"] = russia_republic,
	["Republic of Dagestan"] = russia_republic,
	["Republic of Ingushetia"] = russia_republic,
	["Republic of Kalmykia"] = russia_republic,
	["Republic of Karelia"] = russia_republic,
	["Republic of Khakassia"] = russia_republic,
	["Republic of Mordovia"] = russia_republic,
	["Republic of North Ossetia-Alania"] = russia_republic,
	["North Ossetia"] = {alias_of = "Republic of North Ossetia-Alania"},
	["Alania"] = {alias_of = "Republic of North Ossetia-Alania"},
	["Republic of Tatarstan"] = russia_republic,
	["Altai Republic"] = russia_republic,
	["Chechen Republic"] = russia_republic,
	["Chechnya"] = {alias_of = "Chechen Republic"},
	["Chuvash Republic"] = russia_republic,
	["Chuvashia"] = {alias_of = "Chuvash Republic"},
	["Kabardino-Balkar Republic"] = russia_republic,
	["Kabardino-Balkarian Republic"] = {alias_of = "Kabardino-Balkar Republic", display = true, the = true},
	["Kabardino-Balkaria"] = {alias_of = "Kabardino-Balkar Republic"},
	["Kabardino-Balkariya"] = {alias_of = "Kabardino-Balkar Republic"},
	["Karachay-Cherkess Republic"] = russia_republic,
	["Karachay-Cherkessia"] = {alias_of = "Karachay-Cherkess Republic"},
	["Komi Republic"] = russia_republic,
	["Mari El Republic"] = russia_republic,
	["Sakha Republic"] = russia_republic,
	["Yakutia"] = {alias_of = "Sakha Republic"},
	["Yakutiya"] = {alias_of = "Sakha Republic"},
	["Republic of Yakutia (Sakha)"] = {alias_of = "Sakha Republic", the = true},
	["Tuva Republic"] = russia_republic,
	["Tyva Republic"] = {alias_of = "Tuva Republic", display = true, the = true},
	["Tyva"] = {alias_of = "Tuva Republic"},
	["Udmurt Republic"] = russia_republic,
	["Udmurtia"] = {alias_of = "Udmurt Republic"},
	-- Not sure what to do about this one from a neutrality perspective:
	-- ["Republic of Crimea"] = russia_republic,
	-- There are also federal cities (not included because they're cities):
	-- Moscow, Saint Petersburg, Sevastopol (not sure what to do about the last one if we were to include federal
	-- cities, see "Republic of Crimea" above)
}

local elliptical_republic_placenames = {
	["Chechen Republic"] = "Chechnya",
	["Chuvash Republic"] = "Chuvashia",
	["Kabardino-Balkar Republic"] = "Kabardino-Balkaria",
	["Karachay-Cherkess Republic"] = "Karachay-Cherkessia",
	["Sakha Republic"] = "Yakutia",
	["Udmurt Republic"] = "Udmurtia",
}

local function russia_key_to_placename(key)
	-- FIXME: We probably want to allow more than two variants for placenames to handle the various aliases esp. of
	-- republics.
	local full_placename = key
	local elliptical_placename
	for _, suffix in ipairs({"Autonomous Okrug", "Krai", "Oblast"}) do
		elliptical_placename = key:match("^(.*) " .. suffix .. "$")
		if elliptical_placename then
			return elliptical_placename, full_placename
		end
	end
	elliptical_placename = key:match("^Republic of (.*)$")
	if elliptical_placename then
		return elliptical_placename, full_placename
	end
	elliptical_placename = elliptical_republic_placenames[key]
	if elliptical_placename then
		return elliptical_placename, full_placename
	end
	elliptical_placename = key:match("^(.*) Republic$")
	if elliptical_placename then
		return elliptical_placename, full_placename
	end
	return full_placename, full_placename
end

local function russia_placename_to_key(placename)
	-- We allow the user to say e.g. "obl/Samara" and "rep/Tatarstan" in place of "obl/Samara Oblast" and
	-- "rep/Republic of Tatarstan".
	if export.russia_federal_subjects[placename] then
		return placename
	end
	for _, suffix in ipairs({"Autonomous Okrug", "Krai", "Oblast"}) do
		local suffixed_placename = placename .. " " .. suffix
		if export.russia_federal_subjects[suffixed_placename] then
			return suffixed_placename
		end
	end
	local republic_placename = "Republic of " .. placename
	if export.russia_federal_subjects[republic_placename] then
		return republic_placename
	end
	local republic_placename = placename .. " Republic"
	if export.russia_federal_subjects[republic_placename] then
		return republic_placename
	end
	return placename
end

local function construct_russia_federal_subject_keydesc(group, key, spec)
	local linked_key = export.construct_linked_placename(spec, key)
	if spec.placetype == "oblast" then
		-- Hack: Oblasts generally don't have entries under "Foo Oblast"
		-- but just under "Foo", so fix the linked key appropriately;
		-- doesn't apply to the Jewish Autonomous Oblast
		linked_key = linked_key:gsub(" Oblast%]%]", "%]%] Oblast")
	end
	return linked_key .. ", a [[federal subject]] ([[" .. placetype .. "]]) of [[Russia]]"
end

-- federal subjects of Russia
export.russia_group = {
	key_to_placename = russia_key_to_placename,
	placename_to_key = russia_placename_to_key,
	default_container = "Russia",
	default_keydesc = construct_russia_federal_subject_keydesc,
	default_overriding_bare_label_parents = {"federal subjects of Russia", "+++"},
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
	default_placetype = "province",
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
	["Valencian Community, Spain"] = {alias_of = "Valencia, Spain"}, -- differs in "the"
}

-- autonomous communities of Spain
export.spain_group = {
	default_container = "Spain",
	default_placetype = "autonomous community",
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
	default_placetype = "county",
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
	default_placetype = "province",
	default_divs = "districts",
	data = export.thailand_provinces,
}

export.united_kingdom_constituent_countries = {
	["England"] = {divs = {
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
		placetype = {"province", "constituent country", "country"},
		div_parent_type = "constituent countries",
		divs = {"counties", "districts"},
	},
	["Scotland"] = {divs = {
		{type = "council areas", skip_polity_parent_type = false},
		"districts",
	}},
	["Wales"] = {divs = {
		"counties",
		{type = "county boroughs", skip_polity_parent_type = false},
		{type = "communities", skip_polity_parent_type = false},
		{type = "Welsh communities", cat_as = {{type = "communities", skip_polity_parent_type = false}}},
	}},
}

-- constituent countries and provinces of the United Kingdom
export.united_kingdom_group = {
	placename_to_key = false,
	default_container = "United Kingdom",
	default_placetype = {"constituent country", "country"},
	addl_divs = {
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
	default_container = {key = "England", placetype = "constituent country"},
	default_placetype = "county",
	default_divs = {
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
	default_container = {key = "Northern Ireland", placetype = "constituent country"},
	default_placetype = "county",
	default_british_spelling = true,
	data = export.northern_ireland_counties,
}

export.scotland_council_areas = {
	["City of Glasgow, Scotland"] = {the = true},
	["Glasgow"] = {alias_of = "City of Glasgow"},
	["City of Edinburgh, Scotland"] = {the = true},
	["Edinburgh"] = {alias_of = "City of Edinburgh"},
	["Fife, Scotland"] = {},
	["North Lanarkshire, Scotland"] = {},
	["South Lanarkshire, Scotland"] = {},
	["Aberdeenshire, Scotland"] = {},
	["Highland, Scotland"] = {},
	["City of Aberdeen, Scotland"] = {the = true},
	["Aberdeen"] = {alias_of = "City of Aberdeen"},
	["West Lothian, Scotland"] = {},
	["Renfrewshire, Scotland"] = {},
	["Falkirk, Scotland"] = {},
	["Perth and Kinross, Scotland"] = {},
	["Dumfries and Galloway, Scotland"] = {},
	["City of Dundee, Scotland"] = {the = true},
	["Dundee"] = {alias_of = "City of Dundee"},
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
	["Western Isles"] = {alias_of = "Na h-Eileanan Siar", the = true},
	["Shetland Islands, Scotland"] = {the = true},
	["Orkney Islands, Scotland"] = {the = true},
}

-- council areas of Scotland
export.scotland_group = {
	default_container = {key = "Scotland", placetype = "constituent country"},
	default_placetype = "council area",
	default_british_spelling = true,
	data = export.scotland_council_areas,
}

export.wales_principal_areas = {
	["Blaenau Gwent, Wales"] = {},
	["Bridgend, Wales"] = {},
	["Caerphilly, Wales"] = {},
	-- ["Cardiff, Wales"] = {placetype = "city"},
	["Carmarthenshire, Wales"] = {placetype = "county"},
	["Ceredigion, Wales"] = {placetype = "county"},
	["Conwy, Wales"] = {},
	["Denbighshire, Wales"] = {placetype = "county"},
	["Flintshire, Wales"] = {placetype = "county"},
	["Gwynedd, Wales"] = {placetype = "county"},
	["Isle of Anglesey, Wales"] = {the = true, placetype = "county"},
	["Anglesey, Wales"] = {alias_of = "Isle of Anglesey, Wales"}, -- differs in "the"
	["Merthyr Tydfil, Wales"] = {},
	["Monmouthshire, Wales"] = {placetype = "county"},
	["Neath Port Talbot, Wales"] = {},
	-- ["Newport, Wales"] = {placetype = "city"},
	["Pembrokeshire, Wales"] = {placetype = "county"},
	["Powys, Wales"] = {placetype = "county"},
	["Rhondda Cynon Taf, Wales"] = {},
	-- ["Swansea, Wales"] = {placetype = "city"},
	["Torfaen, Wales"] = {},
	["Vale of Glamorgan, Wales"] = {the = true},
	["Wrexham, Wales"] = {},
}

-- principal areas (cities, counties and county boroughs) of Wales
export.wales_group = {
	default_container = {key = "Wales", placetype = "constituent country"},
	default_placetype = "county borough",
	default_british_spelling = true,
	data = export.wales_principal_areas,
}

export.united_states_states = {
	["Alabama, USA"] = {},
	["Alaska, USA"] = {divs = {
		{type = "boroughs", skip_polity_parent_type = "counties"},
		{type = "borough seats", skip_polity_parent_type = "county seats"},
	}},
	["Arizona, USA"] = {},
	["Arkansas, USA"] = {},
	["California, USA"] = {},
	["Colorado, USA"] = {divs = {"counties", "county seats", "municipalities"}},
	["Connecticut, USA"] = {divs = {"counties", "county seats", "municipalities"}},
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
	["Louisiana, USA"] = {divs = {
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
	["New Jersey, USA"] = {divs = {
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
	["Pennsylvania, USA"] = {divs = {
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
	placename_to_key = make_placename_to_key(", USA"),
	default_container = "United States",
	default_placetype = "state",
	default_divs = {
		"counties",
		"county seats",
	},
	addl_divs = {
		{type = "census-designated places", prep = "in"},
		{type = "unincorporated communities", prep = "in"},
	},
	data = export.united_states_states,
}

-----------------------------------------------------------------------------------
--                                      City data                                --
-----------------------------------------------------------------------------------

export.australia_cities = {
	["Adelaide"] = {container = "South Australia"},
	["Brisbane"] = {container = "Queensland"},
	["Canberra"] = {container = {key = "Australian Capital Territory, Australia", placetype = "territory"}},
	["Melbourne"] = {container = "Victoria"},
	["Newcastle, New South Wales"] = {container = "New South Wales"},
	["Newcastle"] = {alias_of = "Newcastle, New South Wales"},
	["Perth"] = {container = "Western Australia"},
	["Sydney"] = {container = "New South Wales"},
}

local function australia_cities_placename_to_key(placename)
	if placename == "Newcastle" then
		return "Newcastle, New South Wales"
	end
	return placename
end

export.australia_cities_group = {
	placename_to_key = australia_cities_placename_to_key,
	canonicalize_key_container = make_canonicalize_key_container(", Australia", "state"),
	default_placetype = "city",
	default_british_spelling = true,
	data = export.australia_cities,
}

export.brazil_cities = {
	-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
	["São Paulo"] = {container = "São Paulo"},
	["Rio de Janeiro"] = {container = "Rio de Janeiro"},
	["Brasília"] = {container = "Distrito Federal"},
	["Brasilia"] = {alias_of = "Brasília", display = true},
	["Salvador"] = {container = "Bahia", wp = "%l, %c", commonscat = "%l (%c)"},
	["Fortaleza"] = {container = "Ceará"},
	["Belo Horizonte"] = {container = "Minas Gerais"},
	["Manaus"] = {container = "Amazonas"},
	["Curitiba"] = {container = "Paraná"},
	["Recife"] = {container = "Pernambuco"},
	["Goiânia"] = {container = "Goiás"},
	["Goiania"] = {alias_of = "Goiânia", display = true},
	["Belém"] = {container = "Pará"},
	["Belem"] = {alias_of = "Belém", display = true},
	["Porto Alegre"] = {container = "Rio Grande do Sul"},
}

export.brazil_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Brazil", "state"),
	default_placetype = "city",
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
	["Hamilton"] = {container = "Ontario", wp = "%l, %c"},
	["Kitchener"] = {container = "Ontario", wp = "%l, %c"},
}

export.canada_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Canada", "province"),
	default_placetype = "city",
	default_british_spelling = true,
	data = export.canada_cities,
}

export.france_cities = {
	["Paris"] = {container = "Île-de-France"},
	["Lyon"] = {container = "Auvergne-Rhône-Alpes"},
	["Lyons"] = {alias_of = "Lyon", display = true},
	["Marseille"] = {container = "Provence-Alpes-Côte d'Azur"},
	["Marseilles"] = {alias_of = "Marseille", display = true},
	["Toulouse"] = {container = "Occitania"},
	["Lille"] = {container = "Hauts-de-France"},
	["Bordeaux"] = {container = "Nouvelle-Aquitaine"},
	["Nice"] = {container = "Provence-Alpes-Côte d'Azur"},
	["Nantes"] = {container = "Pays de la Loire"},
	["Strasbourg"] = {container = "Grand Est"},
	["Rennes"] = {container = "Brittany"},
}

export.france_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", France", "administrative region"),
	default_placetype = "city",
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
	["Dusseldorf"] = {alias_of = "Düsseldorf", display = true},
	["Nuremberg"] = {container = "Bavaria"},
	["Bremen"] = {},
}

export.germany_cities_group = {
	default_container = "Germany",
	canonicalize_key_container = make_canonicalize_key_container(", Germany", "state"),
	default_placetype = "city",
	default_british_spelling = true,
	data = export.germany_cities,
}

export.india_cities = {
	-- This lists the 65 metro areas per Demographia's 2023 estimates, as found in
	-- [[w:List_of_million-plus_urban_agglomerations_in_India]]. The last census in India (as of April 2025) was
	-- conducted in 2011, and the results are not accurate any more.
	["Delhi"] = {container = {key = "Delhi, India", placetype = "union territory"}}, -- 31,190,000
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
	["Chandigarh"] = {container = {key = "Chandigarh, India", placetype = "union territory"}}, -- 2,168,000
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
	["Srinagar"] = {container = {key = "Jammu and Kashmir, India", placetype = "union territory"}}, -- 1,212,000
	["Salem"] = {container = "Tamil Nadu"}, -- 1,189,000
	["Kota"] = {container = "Rajasthan"}, -- 1,172,000
	["Jalandhar"] = {container = "Punjab"}, -- 1,165,000
	["Saharanpur"] = {container = "Uttar Pradesh"}, -- 1,152,000
	["Dehradun"] = {container = "Uttarakhand"}, -- 1,136,000
	["Tiruchirappalli"] = {container = "Tamil Nadu"}, -- 1,131,000
	["Bhubaneswar"] = {container = "Odisha"}, -- 1,112,000
	["Jammu"] = {container = {key = "Jammu and Kashmir, India", placetype = "union territory"}}, -- 1,103,000
	["Solapur"] = {container = "Maharashtra"}, -- 1,082,000
	["Hubli-Dharwad"] = {container = "Karnataka"}, -- 1,062,000
	["Hubli"] = {alias_of = "Hubli-Dharwad"},
	["Dharwad"] = {alias_of = "Hubli-Dharwad"},
	["Puducherry"] = {container = {key = "Puducherry, India", placetype = "union territory"}}, -- 1,024,000
}

export.india_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", India", "state"),
	default_placetype = "city",
	default_british_spelling = true,
	data = export.india_cities,
}

export.indonesia_cities = {
	-- cities where the city proper has more than 1,000,000 people as of mid-2023 estimate
	["Jakarta"] = {container = "Special Capital Region of Jakarta", divs = {
		{type = "subdistricts", skip_polity_parent_type = false},
	}},
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
	default_placetype = "city",
	data = export.indonesia_cities,
}

export.japan_cities = {
	-- Population figures from [[w:List of cities in Japan]]. Metro areas from
	-- [[w:List of metropolitan areas in Japan]].
	-- Tokyo is treated directly under prefectures of Japan.
	-- ["Tokyo"] = {}, -- no single figure given for Tokyo as a whole.
	["Yokohama"] = {container = "Kanagawa"}, -- 3,697,894
	["Osaka"] = {container = "Osaka"}, -- 2,668,586
	["Nagoya"] = {container = "Aichi"}, -- 2,283,289
	-- FIXME, Hokkaido is handled specially.
	["Sapporo"] = {container = "Hokkaido"}, -- 1,918,096
	["Fukuoka"] = {container = "Fukuoka"}, -- 1,581,527
	["Kobe"] = {container = "Hyōgo"}, -- 1,530,847
	["Kyoto"] = {container = "Kyoto"}, -- 1,474,570
	["Kawasaki"] = {container = "Kanagawa", wp = "%l, %c"}, -- 1,373,630
	["Saitama"] = {container = "Saitama", wp = "%l (city)", commonscat = "%l, %c"}, -- 1,192,418
	["Hiroshima"] = {container = "Hiroshima"}, -- 1,163,806
	["Sendai"] = {container = "Miyagi"}, -- 1,029,552
	-- the remaining cities are considered "central cities" in a 1,000,000+ metro area
	-- (sometimes there is more than one central city in the area).
	["Kitakyushu"] = {container = "Fukuoka"}, -- 986,998
	["Chiba"] = {container = "Chiba", wp = "%l (city)", commonscat = "%l, %c"}, -- 938,695
	["Sakai"] = {container = "Osaka"}, -- 835,333
	["Niigata"] = {container = "Niigata", wp = "%l (city)", commonscat = "%l, %c"}, -- 813,053
	["Hamamatsu"] = {container = "Shizuoka"}, -- 811,431
	["Shizuoka"] = {container = "Shizuoka", wp = "%l (city)", commonscat = "%l, %c"}, -- 710,944
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
	canonicalize_key_container = make_canonicalize_key_container(" Prefecture, Japan", "prefecture"),
	default_placetype = "city",
	data = export.japan_cities,
}

export.south_korea_cities = {
	-- All cities listed are not associated with any county.
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
	canonicalize_key_container = make_canonicalize_key_container(" County, South Korea", "province"),
	default_placetype = "city",
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
	["Leon"] = {alias_of = "León, Guanajuato", display = true},
	["Querétaro"] = {container = "Querétaro"},
	["Queretaro"] = {alias_of = "Querétaro", display = true},
	["Ciudad Juárez"] = {container = "Chihuahua"},
	["Juárez"] = {alias_of = "Ciudad Juárez"},
	["Juarez"] = {alias_of = "Ciudad Juárez", display = "Juárez"},
	["Torreón"] = {container = "Coahuila"},
	["Torreon"] = {alias_of = "Torreón", display = true},
	["Mérida"] = {container = "Yucatán"},
	["Merida"] = {alias_of = "Mérida", display = true},
	["San Luis Potosí"] = {container = "San Luis Potosí"},
	["San Luis Potosi"] = {alias_of = "San Luis Potosí", display = true},
	["Aguascalientes"] = {container = "Aguascalientes"},
	["Mexicali"] = {container = "Baja California"},
}

export.mexico_cities_group = {
	default_container = "Mexico",
	canonicalize_key_container = make_canonicalize_key_container(", Mexico", "state"),
	default_placetype = "city",
	data = export.mexico_cities,
}

export.philippines_cities = {
	 -- Some cities listed independent from any province. province listed is for geographical purposes only.
	 -- Skipped some cities in Metro Manila (Taguig, Pasig) which don't have districts.
	 -- Other cities outside Metro Manila skipped as not central city in their urban area.
	["Quezon City"] = {container = {key = "Metro Manila, Philippines", placetype = "region"}},
	-- Don't display-canonicalize Foo to Foo City as it may make the display weird.
	["Quezon"] = {alias_of = "Quezon City"},
	["Manila"] = {container = {key = "Metro Manila, Philippines", placetype = "region"}},
	["Davao City"] = {container = "Davao del Sur"},
	["Davao"] = {alias_of = "Davao City"},
	["Caloocan"] = {container = {key = "Metro Manila, Philippines", placetype = "region"}},
	["Zamboanga City"] = {container = "Zamboanga del Sur"},
	["Zamboanga"] = {alias_of = "Zamboanga City"},
	["Cebu City"] = {container = "Cebu"},
	["Cebu"] = {alias_of = "Cebu City"},
	["Antipolo"] = {container = "Rizal"},
	["Cagayan de Oro"] = {container = "Misamis Oriental"},
	["Dasmariñas"] = {container = "Cavite"},
	["Dasmarinas"] = {alias_of = "Dasmariñas", display = true},
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
	default_placetype = "city",
	data = export.philippines_cities,
}

export.russia_cities = {
	-- This only lists cities, not metro areas, over 1,000,000 inhabitants.
	["Moscow"] = {},
	["Saint Petersburg"] = {},
	["Novosibirsk"] = {container = "Novosibirsk Oblast"},
	["Yekaterinburg"] = {container = "Sverdlovsk Oblast"},
	["Nizhny Novgorod"] = {container = "Nizhny Novgorod Oblast"},
	["Kazan"] = {container = {key = "Republic of Tatarstan", placetype = "republic"}},
	["Chelyabinsk"] = {container = "Chelyabinsk Oblast"},
	["Omsk"] = {container = "Omsk Oblast"},
	["Samara"] = {container = "Samara Oblast"},
	["Ufa"] = {container = {key = "Republic of Bashkortostan", placetype = "republic"}},
	["Rostov-on-Don"] = {container = "Rostov Oblast"},
	["Rostov-na-Donu"] = {alias_of = "Rostov-on-Don", display = true},
	["Krasnoyarsk"] = {container = {key = "Krasnoyarsk Krai", placetype = "krai"}},
	["Voronezh"] = {container = "Voronezh Oblast"},
	["Perm"] = {container = {key = "Perm Krai", placetype = "krai"}, wp = "%l, Russia"},
	["Volgograd"] = {container = "Volgograd Oblast"},
	["Krasnodar"] = {container = {key = "Krasnodar Krai", placetype = "krai"}},
}

export.russia_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(nil, "oblast"),
	default_placetype = "city",
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
	default_placetype = "city",
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
	default_placetype = "city",
	default_british_spelling = true,
	data = export.spain_cities,
}

export.taiwan_cities = {
	["New Taipei"] = {},
	["Taichung"] = {},
	["Kaohsiung"] = {wp = "%l, Taiwan"},
	["Taipei"] = {},
	["Taoyuan"] = {},
	["Tainan"] = {},
	["Chiayi"] = {},
	["Hsinchu"] = {},
	["Keelung"] = {},
}

export.taiwan_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", Taiwan", "county"),
	default_placetype = "city",
	data = export.taiwan_cities,
}

-- NOTE: It's OK to mix cities from different constituent countries; as long as the immediate container is correct,
-- everything else will be figured out.
export.united_kingdom_cities = {
	["London"] = {container = "Greater London"},
	["Manchester"] = {container = "Greater Manchester"},
	["Birmingham"] = {container = "West Midlands"},
	["Liverpool"] = {container = "Merseyside"},
	["Glasgow"] = {container = {key = "City of Glasgow, Scotland", placetype = "council area"}},
	["Leeds"] = {container = "West Yorkshire"},
	["Newcastle upon Tyne"] = {container = "Tyne and Wear"},
	["Newcastle"] = {alias_of = "Newcastle upon Tyne"},
	["Bristol"] = {container = {key = "England", placetype = "constituent country"}},
	["Cardiff"] = {container = {key = "Wales", placetype = "constituent country"}},
	["Portsmouth"] = {container = "Hampshire"},
	["Edinburgh"] = {container = {key = "City of Edinburgh, Scotland", placetype = "council area"}},
	-- under 1,000,000 people but principal areas of Wales; requested by [[User:Donnanz]]
	["Swansea"] = {container = {key = "Wales", placetype = "constituent country"}},
	["Newport"] = {container = {key = "Wales", placetype = "constituent country"}, wp = "Newport, Wales"},
}

export.united_kingdom_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(", England", "county"),
	default_placetype = "city",
	default_british_spelling = true,
	data = export.united_kingdom_cities,
}

export.united_states_cities = {
	-- top 50 CSA's by population, with the top and sometimes 2nd or 3rd city listed
	["New York City"] = {container = "New York", wp = "%l", divs = {
		{type = "boroughs", prep = "in", skip_polity_parent_type = false},
	}},
	-- Don't display-canonicalize as it may make the display weird (e.g. in the context New York, New York).
	["New York"] = {alias_of = "New York City"},
	["Newark"] = {container = "New Jersey"},
	["Los Angeles"] = {container = "California", wp = "%l"},
	["Long Beach"] = {container = "California"},
	["Riverside"] = {container = "California"},
	["Chicago"] = {container = "Illinois", wp = "%l"},
	["Washington, D.C."] = {wp = "%l"},
	["Washington, DC"] = {alias_of = "Washington, D.C.", display = true},
	["Washington D.C."] = {alias_of = "Washington, D.C.", display = true},
	["Washington DC"] = {alias_of = "Washington, D.C.", display = true},
	-- Don't display-canonicalize as it may make the display weird (e.g. if the holonym is followed by a District of
	-- Columbia holonym).
	["Washington"] = {alias_of = "Washington, D.C."},
	["Baltimore"] = {container = "Maryland", wp = "%l"},
	["San Jose"] = {container = "California"},
	["San Francisco"] = {container = "California", wp = "%l"},
	["Oakland"] = {container = "California"},
	["Boston"] = {container = "Massachusetts", wp = "%l"},
	["Providence"] = {container = "Rhode Island"},
	["Dallas"] = {container = "Texas", wp = "%l", commonscat = "%l, %c"},
	["Fort Worth"] = {container = "Texas"},
	["Philadelphia"] = {container = "Pennsylvania", wp = "%l"},
	["Houston"] = {container = "Texas", wp = "%l"},
	["Miami"] = {container = "Florida", wp = "%l", commonscat = "%l, %c"},
	["Atlanta"] = {container = "Georgia", wp = "%l"},
	["Detroit"] = {container = "Michigan", wp = "%l"},
	["Phoenix"] = {container = "Arizona", wp = "%l", commonscat = "%l, %c"},
	["Mesa"] = {container = "Arizona"},
	["Seattle"] = {container = "Washington", wp = "%l"},
	["Orlando"] = {container = "Florida"},
	["Minneapolis"] = {container = "Minnesota", wp = "%l"},
	["Cleveland"] = {container = "Ohio", wp = "%l", commonscat = "%l, %c"},
	["Denver"] = {container = "Colorado", wp = "%l", commonscat = "%l, %c"},
	["San Diego"] = {container = "California", wp = "%l", commonscat = "%l, %c"},
	["Portland"] = {container = "Oregon"},
	["Tampa"] = {container = "Florida"},
	["St. Louis"] = {container = "Missouri", wp = "%l", commonscat = "%l, %c"},
	["Charlotte"] = {container = "North Carolina"},
	["Sacramento"] = {container = "California"},
	["Pittsburgh"] = {container = "Pennsylvania", wp = "%l"},
	["Salt Lake City"] = {container = "Utah", wp = "%l"},
	["San Antonio"] = {container = "Texas", wp = "%l", commonscat = "%l, %c"},
	["Columbus"] = {container = "Ohio"},
	["Kansas City"] = {container = "Missouri", wp = "%l metropolitan area", commonscat = "%l, %c"},
	["Indianapolis"] = {container = "Indiana", wp = "%l"},
	["Las Vegas"] = {container = "Nevada", wp = "%l"},
	["Cincinnati"] = {container = "Ohio", wp = "%l", commonscat = "%l, %c"},
	["Austin"] = {container = "Texas"},
	["Milwaukee"] = {container = "Wisconsin", wp = "%l", commonscat = "%l, %c"},
	["Raleigh"] = {container = "North Carolina"},
	["Nashville"] = {container = "Tennessee"},
	["Virginia Beach"] = {container = "Virginia"},
	["Norfolk"] = {container = "Virginia"},
	["Greensboro"] = {container = "North Carolina"},
	["Winston-Salem"] = {container = "North Carolina"},
	["Jacksonville"] = {container = "Florida"},
	["New Orleans"] = {container = "Louisiana", wp = "%l"},
	["Louisville"] = {container = "Kentucky"},
	["Greenville"] = {container = "South Carolina"},
	["Hartford"] = {container = "Connecticut"},
	["Oklahoma City"] = {container = "Oklahoma", wp = "%l"},
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
	default_placetype = "city",
	default_wp = "%l, %c",
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
	default_container = {key = "New York City", placetype = "city"},
	default_placetype = "borough",
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
	["Helsinki"] = {container = {key = "Uusimaa, Finland", placetype = "region"}},
	["Athens"] = {container = "Greece"},
	["Thessaloniki"] = {container = "Greece"},
	["Budapest"] = {container = "Hungary"},
	-- FIXME, per Wikipedia "County Dublin" is now the "Dublin Region"
	["Dublin"] = {container = {key = "County Dublin, Ireland", placetype = "county"}},
	-- Jerusalem is not recognized internationally as part of either Israel or Palestine, but as a
	-- [[w:corpus separatum]], so put the container as "Asia" and list Israel and Palestine as additional parents for
	-- categorization purposes.
	["Jerusalem"] = {container = {key = "Asia", placetype = "continent"}, addl_parents = {"Israel", "Palestine"}},
	["Tel Aviv"] = {container = "Israel"},
	["Riga"] = {container = "Latvia"},
	["Amsterdam"] = {container = {key = "North Holland, Netherlands", placetype = "province"}},
	["Rotterdam"] = {container = {key = "South Holland, Netherlands", placetype = "province"}},
	["The Hague"] = {container = {key = "South Holland, Netherlands", placetype = "province"}},
	["Auckland"] = {container = "New Zealand"},
	["Oslo"] = {container = {key = "Oslo, Norway", placetype = "county"}},
	["Warsaw"] = {container = "Poland"},
	["Katowice"] = {container = "Poland"},
	--- Ngrams (up through 2022) and Google Scholar (>= 2024) confirms the common form "Krakow" without accent.
	["Krakow"] = {container = "Poland"},
	["Kraków"] = {alias_of = "Krakow", display = true},
	["Cracow"] = {alias_of = "Krakow", display = true},
	--- Ngrams (up through 2022) and Google Scholar (>= 2024) confirm "Gdańsk" and "Poznań" with accent.
	["Gdańsk"] = {container = "Poland"},
	["Gdansk"] = {alias_of = "Gdańsk", display = true},
	["Poznań"] = {container = "Poland"},
	["Poznan"] = {alias_of = "Poznań", display = true},
	--- Ngrams (up through 2022) and Google Scholar (>= 2024) confirms the common form "Lodz" without accents.
	["Lodz"] = {container = "Poland"},
	["Łódź"] = {alias_of = "Lodz", display = true},
	["Lisbon"] = {container = "Portugal"},
	["Porto"] = {container = "Portugal"},
	["Bucharest"] = {container = "Romania"},
	["Belgrade"] = {container = "Serbia"},
	["Stockholm"] = {container = "Sweden"},
	["Zurich"] = {container = "Switzerland"},
	--- Ngrams (up through 2022) and Google Scholar (>= 2024) confirms the common form "Zurich" without umlaut.
	["Zürich"] = {alias_of = "Zürich", display = true},
	-- metro area population stats from https://www.statista.com/statistics/255483/biggest-cities-in-turkey/ as of 2021
	["Istanbul"] = {container = "Turkey"}, -- 15.2 million
	["İstanbul"] = {alias_of = "Istanbul", display = true},
	["Ankara"] = {container = "Turkey"}, -- 5.15 million
	["Izmir"] = {container = "Turkey"}, -- 2.95 million
	["İzmir"] = {alias_of = "Izmir", display = true},
	["Bursa"] = {container = "Turkey"}, -- 2.02 million
	["Adana"] = {container = "Turkey"}, -- 1.77 million
	["Gaziantep"] = {container = "Turkey"}, -- 1.71 million
	["Konya"] = {container = "Turkey"}, -- 1.35 million
	["Antalya"] = {container = "Turkey"}, -- 1.3 million
	["Diyarbakır"] = {container = "Turkey"}, -- 1.07 million
	-- Diyarbakır is more common per Ngrams and Google Scholar, but Diyarbakir is the Kurdish form, so we should not
	-- display-canonicalize to the Turkish form Diyarbakır.
	["Diyarbakir"] = {alias_of = "Diyarbakır"},
	["Mersin"] = {container = "Turkey"}, -- 1.03 million
	["Kyiv"] = {container = "Ukraine"},
	-- Don't display-canonicalize Kiev -> Kyiv because in ancient contexts, Kiev is still more common.
	["Kiev"] = {alias_of = "Kyiv"},
	["Kharkiv"] = {container = "Ukraine"},
	["Odessa"] = {container = "Ukraine", wp = "Odesa"},
	-- Don't display-canonicalize Odesa -> Odessa because it may be interpreted as a political statement.
	["Odesa"] = {alias_of = "Odessa"},
}

export.misc_cities_group = {
	canonicalize_key_container = make_canonicalize_key_container(nil, "country"),
	default_placetype = "city",
	data = export.misc_cities,
}

--[==[ var:
List of all known locations, in groups. The first group lists continents and continental regions, followed by three
groups listing top-level locations: countries, "country-like entities" (de-facto/unrecognized/etc. countries and
dependent territories) and former polities (countries, empires, etc.). After that come first-level subpolities
(administrative divisions) of several, mostly large, countries, followed by groups of cities. China and the United
Kingdom include second-level subpolities (in the case of China, only the largest ones as the full list runs in the
hundreds).
]==]
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
