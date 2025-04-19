local labels = {}
local handlers = {}

local en_utilities_module = "Module:en-utilities"
local table_module = "Module:table"

local m_shared = require("Module:place/shared-data")
local m_data = require("Module:place/data")
local placetype_data = m_data.placetype_data
local internal_error = m_shared.internal_error

local dump = mw.dumpObject
local is_callable = require("Module:fun").is_callable

--[==[ intro:
This module contains specifications that are used to create labels that allow {{tl|auto cat}} and to create the
appropriate definitions for topic categories for places (e.g. [[Category:de:Hokkaido]], [[Category:es:Cities in
France]], [[Category:pt:Municipalities of Tocantins, Brazil]], etc.).  Note that this module doesn't actually create the
categories; that must be done separately, with the text "{{tl|auto cat}}" as the definition of the category. (This process
should automatically happen periodically for non-empty categories, because they will appear in
[[Special:WantedCategories]] and a bot will periodically examine that list and create any needed category.)

There are two ways that such labels are created: (1) by manually adding an entry to the `labels` table, keyed by the
label (minus the language code) with a value consisting of a Lua table specifying the description text and the
category's parents; (2) through handlers (pieces of Lua code) added to the `handlers` list, which recognize labels of a
specific type (e.g. `Cities in France`) and generate the appropriate specification for that label on-the-fly.

See [[Module:place]] for a general introduction to the terminology associated with places along with a list of all the
relevant modules, and [[Module:place/shared-data]] for more specific information on types of toponyms and placetypes and
how their categorization works.
]==]

local function lcfirst(label)
	return mw.getContentLanguage():lcfirst(label)
end

local function fetch_value(obj, key)
	local val = obj[key]
	if is_callable(val) then
		val = val()
		obj[key] = val
	end
	return val
end

local class_to_bare_category_parent = {
	["polity"] = "polities",
	["subpolity"] = "political divisions",
	["settlement"] = "settlements",
	["non-admin settlement"] = "settlements",
	["capital"] = "capital cities",
	["natural feature"] = "natural features",
	["man-made structure"] = "man-made structures",
	["geographic region"] = "geographic and cultural areas",
}

local class_is_political_division = {
	["polity"] = true, -- strictly false but there are placetypes ambiguous between polity and subpolity
	["subpolity"] = true,
	["settlement"] = true,
	["non-admin settlement"] = false,
	["capital"] = true,
	["natural feature"] = false,
	["man-made structure"] = false,
	["geographic region"] = false,
	["generic place"] = false,
}

local capital_cat_to_placetype = {}
for placetype, capital_cat in pairs(m_data.placetype_to_capital_cat) do
	capital_cat_to_placetype[capital_cat] = placetype
end

-- Handler for bare categories for all types of capitals. This needs to precede the handler for bare placetype
-- categories as some of the types of capitals exist as placetypes as well.
table.insert(handlers, function(label)
	label = lcfirst(label)
	local capital_placetype = capital_cat_to_placetype[label]
	if capital_placetype then
		local pl_placetype = m_data.pluralize_placetype(capital_placetype)
		local linkdesc = m_data.get_placetype_display_form(pl_placetype, "top-level")
		if not linkdesc then
			internal_error("Unrecognized placetype %s when processing label %s", capital_placetype, label)
		end
		return {
			type = "name",
			topic = label,
			description = "{{{langname}}} names of [[capital]]s of " .. linkdesc .. ".",
			parents = {"capital cities"},
		}
	end
end)

-- Handler for bare placetype categories. FIXME: Add wpcat= and commonscat= info. Previously we had it for various
-- so-called "generic" placetypes, but sometimes the categories were wrong.
table.insert(handlers, function(label)
	for _, canon_label in ipairs { lcfirst(label), label } do
		local ptdesc, ptdata = m_data.get_placetype_display_form(canon_label, "top-level")
		if ptdesc then
			local bare_category_parent = m_data.get_equiv_placetype_prop(canon_label, function(pt)
				local bare_category_parent = m_data.get_placetype_prop(pt, "bare_category_parent")
				if bare_category_parent then
					return bare_category_parent
				end
				local class = m_data.get_placetype_prop(pt, "class")
				if class then
					if class_to_bare_category_parent[class] == nil then
						internal_error("Saw unknown category class %s derived from placetype %s",
							class, canon_label)
					end
					return class_to_bare_category_parent[class]
				end
			end, {
				from_category = true,
				no_split_qualifiers = true,
			})
			if not bare_category_parent then
				internal_error("Saw placetype %s without a `class` or `bare_category_parent` setting, either " ..
					"directly or through a fallback", canon_label)
			end
			local addl_bare_category_parents = m_data.get_equiv_placetype_prop(canon_label, function(pt)
				return m_data.get_placetype_prop(pt, "addl_bare_category_parents")
			end, {
				from_category = true,
				no_split_qualifiers = true,
			})
			local parents = {bare_category_parent}
			if addl_bare_category_parents then
				require(table_module).extend(parents, addl_bare_category_parents)
			end
			return {
				type = "name",
				topic = canon_label,
				description = "{{{langname}}} names of " .. ptdesc .. ".",
				parents = parents,
			}
		end
	end
end)

labels["city nicknames"] = {
	type = "name",
	-- special-cased description
	description = "{{{langname}}} informal alternative names for [[city|cities]] (e.g., [[Big Apple]] for [[New York City]]).",
	parents = {"cities", "nicknames"},
}

labels["exonyms"] = {
	type = "name",
	-- special-cased description
	description = "{{{langname}}} [[exonym]]s.",
	parents = {"places"},
}

-- Handler for bare placename categories for known locations in `locations` in [[Module:place/shared-data]].
table.insert(handlers, function(label)
	for _, canon_label in ipairs { label, lcfirst(label) } do
		local group, spec = m_shared.find_canonical_key(canon_label)
		if group then
			return m_shared.make_bare_placename_cat_spec(group, canon_label, spec, m_data)
		end
	end
end)

-- Handler for bare placename categories for known cities in `cities` in [[Module:place/shared-data]].
table.insert(handlers, function(label)
	for _, canon_label in ipairs { label, lcfirst(label) } do
		for _, city_group in ipairs(m_shared.cities) do
			local city_key
			if city_group.data[canon_label] then
				city_key = canon_label
			elseif city_group.data["the " .. canon_label] then
				city_key = "the " .. canon_label
			end
			if city_key then
				local city_spec = city_group.data[city_key]
				if not city_spec.alias_of then
					local desc, label_parent = city_description(city_group, city_key, city_spec)
					desc = "{{{langname}}} terms related to " .. desc .. "."
					local city_containing_polities = m_shared.get_city_containing_polities(city_group, city_spec)
					if not city_containing_polities or not city_containing_polities[1] then
						internal_error("When creating city bare label for %s, at least one containing polity must " ..
							"be specified or an explicit parent must be given", city_key)
					end
					local key_parents = {}
					for _, parent in ipairs(city_containing_polities) do
						local polity_key, _, _ = m_shared.find_city_containing_polity(parent)
						table.insert(key_parents, "cities in " .. polity_key)
					end

					-- wp= defaults to group-level wp=, then to true (Wikipedia article matches bare city_key = label)
					local wp = city_spec.wp
					if wp == nil then
						wp = city_group.wp or true
					end
					-- wpcat= defaults to wp= (if Wikipedia article has its own name, Wikipedia category and Commons
					-- category generally follow)
					local wpcat = city_spec.wpcat
					if wpcat == nil then
						wpcat = wp
					end
					-- commonscat= defaults to wpcat= (if Wikipedia category has its own name, Commons category
					-- generally follows)
					local commonscat = city_spec.commonscat
					if commonscat == nil then
						commonscat = wpcat
					end

					local function format_boxval(val)
						if type(val) == "string" then
							val = val:gsub("%%c", city_key):gsub("%%d", label_parent)
						end
						return val
					end

					return {
						type = "related-to",
						description = desc,
						parents = key_parents,
						wp = format_boxval(wp),
						wpcat = format_boxval(wpcat),
						commonscat = format_boxval(commonscat),
					}
				end
			end
		end
	end
end)

-- Handler for generic placetypes (those whose categories are added through category generation handlers or through
-- explicit category specs in the placetype data) for locations listed in `export.polities` in
-- [[Module:place/shared-data]]. All such placetypes have either a `generic_before_non_cities` setting (meaning they
-- can occur before non-city locations) or `generic_before_cities` setting (meaning they can occur before cities), or
-- both. We need to check both types because there are cities mixed into the `export.polities` data. Examples of such
-- categories are "cities in the Bahamas" or "rivers in Western Australia, Australia", or (for city locations)
-- "neighbourhoods of Hong Kong".
table.insert(handlers, function(label)
	for _, canon_label in ipairs { lcfirst(label), label } do
		local placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		if not placetype then
			placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		end
		if placetype then
			local normalized_placetype = placetype == "neighbourhoods" and "neighborhoods" or placetype
			local canon_placetype, ptdata, ptmatch = m_data.get_placetype_data(normalized_placetype, "from category")
			if canon_placetype and (ptdata.generic_before_non_cities or ptdata.generic_before_cities) then
				for _, group in ipairs(m_shared.polities) do
					local group_is_top_level = group.default_divtype == "country"
					local placedata = group.data[place]
					if placedata then
						placedata = group.value_transformer(group, place, placedata)
						local allow_cat = true
						if placetype == "neighborhoods" and placedata.british_spelling or
							placetype == "neighbourhoods" and not placedata.british_spelling then
							mw.log(("Mismatch in spelling of placetype '%s' in category '%s', should be '%s'"):format(
								placetype, canon_label, placedata.british_spelling and "neighbourhoods" or "neighborhoods"))
							allow_cat = false
						end
						if placedata.is_former_place and placetype ~= "places" then
							allow_cat = false
						end
						local expected_prep
						if placedata.is_city then
							expected_prep = ptdata.generic_before_cities
						else
							expected_prep = ptdata.generic_before_non_cities
						end
						if not expected_prep then
							allow_cat = false
						end
						if allow_cat then
							if expected_prep ~= in_of then
								mw.log(("Mismatch in category name '%s', has '%s' when it should have '%s'"):format(
									canon_label, in_of, expected_prep))
								return nil
							end
							local bare_place, linked_place = m_shared.construct_bare_and_linked_version(place)
							local keydesc = fetch_value(placedata, "keydesc") or linked_place
							local parents = {}
							table.insert(parents, bare_place)
							if placedata.containing_polity then
								table.insert(parents, {
									name = placetype .. " " .. in_of .. " " .. placedata.containing_polity,
									sort = bare_place
								})
							else -- top-level country
								table.insert(parents, {
									name = normalized_placetype,
									sort = bare_place
								})
								local category_class = m_data.get_equiv_placetype_prop(normalized_placetype,
									function(pt) return m_data.get_placetype_prop(pt, "class") end, {
										from_category = true,
										no_split_qualifiers = true,
									})
								if not category_class then
									internal_error("Saw placetype %s that is either unknown or has no `class` " ..
										"setting in `placetype_data`", normalized_placetype)
								end
								if class_is_political_division[category_class] == nil then
									internal_error("Saw unknown category class %s derived from placetype %s",
										category_class, normalized_placetype)
								end
								if class_is_political_division[category_class] then
									table.insert(parents, "political divisions of specific countries")
								end
							end
							local ptdesc = m_data.get_placetype_display_form(placetype,
								placedata.is_city and "city" or "noncity")
							if not ptdesc then
								internal_error("Unrecognized placetype %s, even though we recognized it before",
									placetype)
							end
							return {
								type = "name",
								topic = canon_label,
								description = "{{{langname}}} names of " .. ptdesc .. " " .. in_of .. " " .. keydesc ..
									".",
								breadcrumb = placetype,
								parents = parents,
							}
						end
					end
				end
			end
		end
	end
end)

-- Handler for generic placetypes (those whose categories are added through category generation handlers or through
-- explicit category specs in the placetype data) for locations listed in `export.cities` in
-- [[Module:place/shared-data]]. All such placetypes have either a `generic_before_cities` setting (meaning they can
-- occur before cities) Examples of such categories are "places in Paris" and "neighbourhoods of Chicago".
table.insert(handlers, function(label)
	for _, canon_label in ipairs { lcfirst(label), label } do
		local placetype, in_of, city_key = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		if not placetype then
			placetype, in_of, city_key = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		end
		if placetype then
			local normalized_placetype = placetype == "neighbourhoods" and "neighborhoods" or placetype
			local canon_placetype, ptdata, ptmatch = m_data.get_placetype_data(normalized_placetype, "from category")
			if canon_placetype and ptdata.generic_before_cities then
				local should_in_of = ptdata.generic_before_cities
				if should_in_of ~= in_of then
					mw.log(("Mismatch in category name '%s', has '%s' when it should have '%s'"):format(
						canon_label, in_of, should_in_of))
					return nil
				end
				for _, city_group in ipairs(m_shared.cities) do
					local city_spec = city_group.data[city_key]
					if city_spec then
						local spelling_matches = true
						if placetype == "neighborhoods" or placetype == "neighbourhoods" then
							local containing_polities = m_shared.get_city_containing_polities(city_group, city_spec)
							local _, polity_spec, _ = m_shared.find_city_containing_polity(containing_polities[1])
							if placetype == "neighborhoods" and polity_spec.british_spelling or
								placetype == "neighbourhoods" and not polity_spec.british_spelling then
								spelling_matches = false
							end
						end
						if spelling_matches then
							local parents
							if placetype == "places" or placetype == "suburbs" then
								parents = {city_key}
							else
								parents = {city_key, "places in " .. city_key}
							end
							local ptdesc = m_data.get_placetype_display_form(placetype, "city")
							if not ptdesc then
								internal_error("Unrecognized placetype %s, even though we recognized it before",
									placetype)
							end
							local citydesc = city_description(city_group, city_key, city_spec)
							return {
								type = "name",
								topic = canon_label,
								description = "{{{langname}}} names of " .. ptdesc .. " " .. in_of .. " " .. citydesc ..
									".",
								breadcrumb = placetype,
								parents = parents,
							}
						end
					end
				end
			end
		end
	end
end)

-- Handler for "state capitals of the United States", "provincial capitals of Canada", etc. This must precede the next
-- handler for specific political and misc (non-political) divisions of polities and subpolities, such as
-- "provinces of the Philippines", because "departmental capitals" is listed in cat_as for French prefectures and so
-- will trigger an error if that handler runs before this one.
table.insert(handlers, function(label)
	label = lcfirst(label)
	local capital_cat, place = label:match("^([a-z%- ]- capitals) of (.*)$")
	-- Make sure we recognize the type of capital.
	if place and capital_cat_to_placetype[capital_cat] then
		local placetype = capital_cat_to_placetype[capital_cat]
		local pl_placetype = m_data.pluralize_placetype(placetype)
		-- Locate the containing polity, fetch its known political divisions, and make sure
		-- the placetype corresponding to the type of capital is among the list.
		for _, group in ipairs(m_shared.polities) do
			local placedata = group.data[place]
			if placedata then
				placedata = group.value_transformer(group, place, placedata)
				if placedata.poldiv then
					local saw_match = false
					local variant_matches = {}
					for _, div in ipairs(placedata.poldiv) do
						if type(div) == "string" then
							div = {type = div}
						end
						-- HACK. Currently if we don't find a match for the placetype, we map e.g. 'autonomous region'
						-- -> 'regional capitals' and 'union territory' -> 'territorial capitals'. When encountering a
						-- political division like 'autonomous region' or 'union territory', chop off everything up
						-- through a space to make things match. To make this clearer, we record all such
						-- "variant match" cases, and down below we insert a note into the category text indicating that
						-- such "variant matches" are included among the category.
						if pl_placetype == div.type or pl_placetype == div.type:gsub("^.* ", "") then
							saw_match = true
							if pl_placetype ~= div.type then
								table.insert(variant_matches, div.type)
							end
						end
					end
					if saw_match then
						-- Everything checks out, construct the category description.
						local placetype_desc = m_data.get_placetype_display_form(pl_placetype,
							placetype.is_city and "city" or "noncity")
						if not placetype_desc then
							internal_error("Unrecognized plural placetype %s, generated as the plural of %s, which " ..
								"was found as the placetype of capital placetype %s in label %s", pl_placetype,
								placetype, capital_cat, label)
						end
						local bare_place, linked_place = m_shared.construct_bare_and_linked_version(place)
						local keydesc = fetch_value(placedata, "keydesc") or linked_place
						local variant_match_text = ""
						if #variant_matches > 0 then
							for i, variant_match in ipairs(variant_matches) do
								local variant_match_desc = m_data.get_placetype_display_form(variant_match,
									placetype.is_city and "city" or "noncity")
								if not variant_match_desc then
									internal_error("Unrecognized variant match plural placetype %s, coming from " ..
										"place key %s, data %s in label %s", variant_match, place, placedata, label)
								end
								variant_matches[i] = variant_match_desc
							end
							variant_match_text = " (including " ..
								require(table_module).serialCommaJoin(variant_matches) .. ")"
						end
						local desc = "{{{langname}}} names of [[capital]]s of " .. placetype_desc ..
							variant_match_text .. " of " .. keydesc .. "."
						return {
							type = "name",
							topic = label,
							description = desc,
							breadcrumb = bare_place,
							parents = {{name = capital_cat, sort = bare_place}, bare_place},
						}
					end
				end
			end
		end
	end
end)

local overriding_descriptions = {
	["autonomous cities of Spain"] = "{{{langname}}} names of the [[w:Autonomous communities of Spain#Autonomous_cities|autonomous cities of Spain]].",
	["regions of Albania"] = "{{{langname}}} names of the regions ([[periphery|peripheries]]) of [[Albania]].",
	["regions of Greece"] = "{{{langname}}} names of the regions ([[periphery|peripheries]]) of [[Greece]].",
	["regions of North Macedonia"] = "{{{langname}}} names of the regions ([[periphery|peripheries]]) of [[North Macedonia]].",
	["subprefectures of Japan"] = "{{{langname}}} names of [[subprefecture]]s of [[Japan]]ese [[prefecture]]s.",
}

-- Handler for specific political and misc (non-political) divisions of polities and subpolities, such as
-- "provinces of the Philippines", "counties of Wales", "municipalities of Tocantins, Brazil", etc.
-- This does not handle categories for generic placetypes (cities, rivers, etc.) of polities, subpolities or cities,
-- which are handled by different handlers above.
table.insert(handlers, function(label)
	-- The label comes with an initial capitalization but we have to check both lowercase-initial and capital-initial
	-- versions of the placetype to handle e.g. [[:Category:en:Indian reserves of Canada]].
	for _, canon_label in ipairs { lcfirst(label), label } do
		local placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		if not placetype then
			placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		end
		if place then
			for _, group in ipairs(m_shared.polities) do
				local placedata = group.data[place]
				if placedata then
					placedata = group.value_transformer(group, place, placedata)
					local divcat = nil
					local function find_placetype(divs)
						if divs then
							if type(divs) ~= "table" then
								divs = {divs}
							end
							for _, div in ipairs(divs) do
								if type(div) == "string" then
									div = {type = div}
								end
								local cat_as = div.cat_as or div.type
								if type(cat_as) ~= "table" then
									cat_as = {cat_as}
								end
								for _, pt_cat_as in ipairs(cat_as) do
									if type(pt_cat_as) == "string" then
										pt_cat_as = {type = pt_cat_as}
									end
									if placetype == pt_cat_as.type then
										local div_parent = pt_cat_as.skip_polity_parent_type
										if div_parent == nil then -- allow false
											div_parent = div.skip_polity_parent_type
										end
										if div_parent == nil then
											div_parent = placetype
										end
										return div_parent, pt_cat_as.prep or div.prep or "of"
									end
								end
							end
						end
	
						return nil
					end
					local div_parent, div_prep = find_placetype(placedata.poldiv)
					if div_parent == nil then -- allow false
						div_parent, div_prep = find_placetype(placedata.miscdiv)
					end
					if div_parent == nil then -- allow false
						div_parent, div_prep = find_placetype(placedata.addl_poldiv_for_categorization)
					end
					if div_parent ~= nil then
						if div_prep ~= in_of then
							mw.log(("Mismatch in category name '%s', has '%s' when it should have '%s'"):format(
								canon_label, in_of, div_prep))
							return nil
						end
						local linkdesc = m_data.get_placetype_display_form(placetype,
							placedata.is_city and "city" or "noncity")
						if not linkdesc then
							internal_error("Unrecognized placetype %s when processing key %s, data %s, label %s",
								placetype, place, placedata, canon_label)
						end
						local bare_place, linked_place = m_shared.construct_bare_and_linked_version(place)
						local desc = overriding_descriptions[canon_label]
						if not desc then
							local keydesc = fetch_value(placedata, "keydesc") or linked_place
							desc = "{{{langname}}} names of " .. linkdesc .. " " .. div_prep .. " " .. keydesc .. "."
						end
						local parents = {}
						table.insert(parents, bare_place)
						if placedata.containing_polity and div_parent then
							table.insert(parents, {
								name = div_parent .. " " .. div_prep .. " " .. placedata.containing_polity,
								sort = bare_place
							})
						else -- top-level country
							table.insert(parents, {name = placetype, sort = bare_place})
							table.insert(parents, "political divisions of specific countries")
						end
						return {
							type = "name",
							topic = canon_label,
							description = desc,
							breadcrumb = placetype,
							parents = parents,
						}
					end
				end
			end
		end
	end
end)

labels["political divisions of specific countries"] = {
	type = "grouping",
	description = "{{{langname}}} categories for political divisions of specific countries.",
	parents = {"places"},
}

-- FIXME, delete the next two.
labels["regions in the world"] = { -- for multinational regions which do not fit neatly within one continent
	type = "name",
	description = "{{{langname}}} names of [[region]]s in the world (which do not fit neatly within one country or continent).",
	parents = {"places"},
}

labels["regions in the Americas"] = {
	type = "name",
	description = "{{{langname}}} names of [[region]]s in the Americas.",
	breadcrumb = "regions",
	parents = {"America"},
}

-- Label descriptions for countries, rivers and geographic/cultural areas in/of continents and continental regions.
-- FIXME: Incorporate these continents and continental regions as known locations and remove the special-case code here.
for _, continent in ipairs({"Africa", "Asia", "Central America", "Europe", "North America", "Oceania", "Melanesia",
	"Micronesia", "Polynesia", "South America", "Antarctica"}) do
	labels["countries in " .. continent] = {
		type = "name",
		description = "{{{langname}}} names of [[country|countries]] in [[" .. continent .. "]].",
		breadcrumb = continent,
		parents = {{name = "countries", sort = " "}, continent},
	}
	labels["rivers in " .. continent] = {
		type = "name",
		description = "{{{langname}}} names of [[river]]s in [[" .. continent .. "]].",
		breadcrumb = continent,
		parents = {{name = "rivers", sort = " "}, continent},
	}
	labels["geographic and cultural areas of " .. continent] = {
		type = "name",
		description = "{{{langname}}} names of [[geographic]] and [[cultural]] [[area]]s or [[region]]s of [[" .. continent .. "]].",
		breadcrumb = continent,
		parents = {{name = "geographic and cultural areas", sort = " "}, continent},
	}
end

-- Misc. FIXME: Remove the need for this.
labels["boroughs of New York City"] = {
	type = "name",
	description = "{{{langname}}} names of boroughs of [[New York City]].",
	breadcrumb = "boroughs",
	parents = {"New York City", {name = "boroughs in the United States", sort = "New York City"}},
}

labels["nomes of Ancient Egypt"] = {
	type = "name",
	-- special-cased description
	description = "{{{langname}}} names of the [[nome]]s of [[Ancient Egypt]].",
	breadcrumb = "nomes",
	parents = {"Ancient Egypt"},
}

labels["subdistricts of Jakarta"] = {
	type = "name",
	description = "{{{langname}}} names of the [[subdistrict]]s of [[Jakarta]].",
	-- not listed in the normal place because no categories like "cities in Jakarta"
	breadcrumb = "subdistricts",
	parents = {"Jakarta"},
}

return {LABELS = labels, HANDLERS = handlers}
