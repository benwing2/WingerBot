local labels = {}
local handlers = {}

local en_utilities_module = "Module:en-utilities"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

local m_shared = require("Module:place/shared-data")
local m_data = require("Module:place/data")
local placetype_data = m_data.placetype_data
local internal_error = m_shared.internal_error

local dump = mw.dumpObject
local is_callable = require("Module:fun").is_callable

--[==[ intro:
This module is part of the category tree code and contains code to generate the descriptions of place-related categories
such as [[Category:de:Hokkaido Prefecture, Japan]], [[Category:es:Cities in France]],
[[Category:pt:Municipalities of Tocantins, Brazil]], etc.). Note that this module doesn't actually create the
categories; that must be done separately, with the text "{{tl|auto cat}}" as the definition of the category. (This
process should automatically happen periodically for non-empty categories, because they will appear in
[[Special:WantedCategories]] and a bot will periodically examine that list and create any needed category.)

There are two ways that category descriptions are specified: (1) by manually adding an entry to the `labels` table,
keyed by the label (the category minus the language code) with a value consisting of a Lua table specifying the
description text and the category's parents; (2) through handlers (pieces of Lua code) added to the `handlers` list,
which recognize labels of a specific type (e.g. `Cities in France`) and generate the appropriate specification for that
label on-the-fly.

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

local function fetch_primary_divtype(key, spec)
	local divtype = spec.divtype
	if type(divtype) == "table" then
		divtype = divtype[1]
	end
	if not divtype then
		internal_error("No divtype specified or defaulted for key %s, spec %s", key, spec)
	end
	return divtype
end

--[==[
Construct an appropriately linked location based on the full or elliptical placename, preceded by `"the "`` if
appropriate. Specifically:

Fetch the full and elliptical_placenames. If they are the same, just link to the placename directly. Otherwise, check if
the full placename exists; if so link to it. Otherwise, if the elliptical placename exists, link to it but display it as
the full placename. Finally, if neither full placename nor elliptical placename exists, fall back to linking to the full
placename. That way, we prefer full placenames to elliptical placenames if both or neither exist as Wiktionary entries,
but if only one exists, we link to that one rather than have a red link.
]==]
function export.construct_linked_location(group, key, spec)
	local full_placename, elliptical_placename = m_shared.key_to_placename(group, key)
	local linked_placename
	if elliptical_placename ~= full_placename then
		local full_placename_title = mw.title.new(full_placename)
		if full_placename_title and full_placename_title.exists then
			linked_placename = m_shared.construct_linked_placename(spec, full_placename)
		else
			local elliptical_placename_title = mw.title.new(elliptical_placename)
			if elliptical_placename_title and elliptical_placename_title.exists then
				linked_placename = m_shared.construct_linked_placename(spec, elliptical_placename, full_placename)
			end
		end
	end
	return linked_placename or m_shared.construct_linked_placename(spec, full_placename)
end

--[==[
Construct the description of a location, including its container trail either to the end or until we encounter a
`no_include_container_in_desc` setting. For example, for the city of [[Birmingham]], the description will read
`"[[Birmingham]], a [[city]] in the [[West Midlands]] (which is a [[county]] of [[England]], which is a
[[constituent country]] of the [[United Kingdom]], which is a [[country]] in [[Europe]])"`. FIXME: Possibly we should
adopt the way city descriptions used to read, which was similar to `"the city of [[Birmingham]], in the county of the
[[West Midlands]], in the [[constituent country]] of [[England]], in the [[country]] of the [[United Kingdom]], in
[[Europe]]"`.
]==]
function export.construct_location_description(group, key, spec, m_data)
	local parts = {}
	local function ins(txt)
		insert(parts, txt)
	end
	ins(export.construct_linked_location(group, key, spec))
	local first_container = true
	local need_closing_paren = false
	local containers = {{group = group, key = key, spec = spec}}
	local container_iterator = m_shared.iterate_containers(group, key, spec)
	while true do
		local include_container_in_desc = false
		for _, container in ipairs(containers) do
			if not container.spec.no_include_container_in_desc then
				include_container_in_desc = true
				break
			end
		end
		if not include_container_in_desc then
			break
		end
		local next_containers = next(container_iterator)
		if not next_containers then
			break
		end
		local is_former = nil
		for _, container in ipairs(containers) do
			local this_is_former = container.spec.is_former_place
			if is_former == nil then
				is_former = this_is_former
			elseif is_former ~= this_is_former then
				internal_error("When processing container trail of key %s, found a mixture of former and non-former " ..
					"containers: %s", key, containers)
			end
		end

		if #containers > 1 then
			local divtypes = {}
			local prepositions = {}
			for _, container in ipairs(containers) do
				local container_type = fetch_primary_divtype(container.key, container.spec)
				m_table.insertIfNot(divtypes, m_data.pluralize_placetype(container_type))
				m_table.insertIfNot(divtypes, m_data.get_placetype_entry_preposition(container_type))
			end
			if first_container then
				ins(", ")
			else
				ins(" (which are ")
				need_closing_paren = true
			end
			if is_former then
				ins("former ")
			end
			ins(m_table.serialCommaJoin(divtypes))
			ins(" ")
			ins(concat(prepositions, "/"))
		else
			if first_container then
				ins(", ")
			else
				ins(" (which is ")
				need_closing_paren = true
			end
			local container_type = fetch_primary_divtype(containers[1].key, containers[1].spec)
			if is_former then
				ins("a former ")
			else
				ins(m_data.get_placetype_article(container_type))
				ins(" ")
			end
			ins(container_type)
			ins(" ")
			ins(m_data.get_placetype_entry_preposition(container_type))
		end
		first_container = false
		containers = next_containers
		local container_locations = {}
		for _, container in ipairs(containers) do
			insert(container_locations, export.construct_linked_location(container.group, container.key,
				container.spec))
		end
		ins(m_table.serialCommaJoin(container_locations))
	end
	if need_closing_paren then
		ins(")")
	end

	return concat(parts)
end

-- Handler for bare placename categories for known locations in `locations` in [[Module:place/shared-data]].
table.insert(handlers, function(label)
	for _, canon_label in ipairs { label, lcfirst(label) } do
		local group, spec = m_shared.find_canonical_key(canon_label)
		if group then
			-- wp= defaults to true (Wikipedia article matches location's full placename)
			local wp = spec.wp
			if wp == nil then
				wp = true
			end
			-- wpcat= defaults to wp= (if Wikipedia article has its own name, Wikipedia category and Commons category
			-- generally follow)
			local wpcat = spec.wpcat
			if wpcat == nil then
				wpcat = wp
			end
			-- commonscat= defaults to wpcat= (if Wikipedia category has its own name, Commons category generally
			-- follows)
			local commonscat = spec.commonscat
			if commonscat == nil then
				commonscat = wpcat
			end
			local parents = {}
			local bare_label_parents = spec.overriding_bare_label_parents
			local container_iterator = m_shared.iterate_containers(group, key, spec)
			local containers = next(container_iterator)
			if not bare_label_parents then
				bare_label_parents = {"+++"}
			end
			local full_location_placename, elliptical_location_placename = m_shared.key_to_placename(group, key)
			local full_container_placename
			if containers then
				full_container_placename, _ = m_shared.key_to_placename(containers[1].group, containers[1].key)
			end
			local inserted_containers = false
			for _, parent in ipairs(bare_label_parents) do
				if parent = "+++" then
					local location_type = fetch_primary_divtype(key, spec)
					div_parent_type = m_data.pluralize_placetype(divtype)
					parent = ("%s %s CONTAINER"):format(m_data.pluralize_placetype(location_type),
						m_data.get_placetype_entry_preposition(location_type))
				end
				if parent:find("CONTAINER") then
					if not containers then
						internal_error("Parent category %s needs the container of %s but no containers specified: %s",
							parent, key, spec)
					end
					for _, container in ipairs(containers) do
						local prefixed_key = m_shared.get_prefixed_key(container.key, container.spec)
						m_table.insertIfNot(parents, parent:gsub("CONTAINER",
							require(string_utilities_module).replacement_escape(prefixed_key)))
					end
					inserted_containers = true
				else
					m_table.insertIfNot(parents, parent)
				end
			end
			if not inserted_containers and container then
				-- If we didn't insert the containers above in some form, insert them now as bare categories. Note that
				-- this may be different categories from the container categories inserted above.
				for _, container in ipairs(containers) do
					m_table.insertIfNot(parents, container.key)
				end
			end
			if spec.addl_parents then
				for _, parent in ipairs(spec.addl_parents) do
					m_table.insertIfNot(parents, parent)
				end
			end
			local function format_boxval(val, specname)
				if val == true then
					val = "%l"
				end
				if type(val) == "string" then
					val = val:gsub("%%l", require(string_utilities_module).replacement_escape(full_location_placename))
					val = val:gsub("%%e", require(string_utilities_module).replacement_escape(
						elliptical_location_placename))
					if val:find("%%c") then
						if not full_container_placename then
							internal_error("Wikipedia/Commons spec %s = %s has %%c in it but key %s has no " ..
								"containers: %s", specname, val, key, spec)
						end
						val = val:gsub("%%c", full_container_placename)
					end
				end
				return val
			end

			local description = "{{{langname}}} terms related to the people, culture, or territory of " ..
				(spec.keydesc or export.construct_location_description(group, key, spec, m_data)) .. "."
			return {
				type = "topic",
				description = description,
				parents = parents,
				wp = format_boxval(wp, "wp"),
				wpcat = format_boxval(wpcat, "wpcat"),
				commonscat = format_boxval(commonscat, "commonscat"),
			}
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

local function find_canonical_key_from_place(place, canon_label)
	local has_the = false
	local key
	if place:find("^the ") then
		key = place:gub("^the ", "")
		has_the = true
	else
		key = place
	end
	local group, spec = m_shared.find_canonical_key(key)
	if group then
		local requires_the = spec.the or false
		if has_the ~= requires_the then
			if has_the then
				mw.log(("Mismatch in category name '%s', has 'the' in the category when it should not"):format(
					canon_label))
			else
				mw.log(("Mismatch in category name '%s', should have 'the' in the category but does not"):
					format(canon_label))
			end
			return nil
		end
		return group, spec
	end
	return nil
end


-- Handler for generic placetypes (those whose categories are added through category generation handlers or through
-- explicit category specs in the placetype data) for known locations in [[Module:place/shared-data]]. All such
-- placetypes have either a `generic_before_non_cities` setting (meaning they can occur before non-city locations) or
-- `generic_before_cities` setting (meaning they can occur before cities), or both. Examples of such categories are
-- "cities in the Bahamas" or "rivers in Western Australia, Australia", or (for city locations)
-- "neighbourhoods of Hong Kong" or "places in Melbourne".
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
				local group, spec = find_canonical_key_from_place(place, canon_label)
				if group then
					local allow_cat = true
					if placetype == "neighborhoods" and spec.british_spelling or
						placetype == "neighbourhoods" and not spec.british_spelling then
						mw.log(("Mismatch in spelling of placetype '%s' in category '%s', should be '%s'"):format(
							placetype, canon_label, spec.british_spelling and "neighbourhoods" or "neighborhoods"))
						allow_cat = false
					end
					if spec.is_former_place and placetype ~= "places" then
						allow_cat = false
					end
					local expected_prep
					if spec.is_city then
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
						local linkdesc = m_data.get_placetype_display_form(placetype,
							spec.is_city and "city" or "noncity")
						if not linkdesc then
							internal_error("Unrecognized placetype %s when processing key %s, data %s, label %s",
								placetype, key, spec, canon_label)
						end
						local keydesc = fetch_value(spec, "keydesc") or m_shared.construct_location_description(
							group, key, spec, m_data)
						desc = linkdesc .. " " .. in_of .. " " .. keydesc
						desc = "{{{langname}}} names of " .. desc .. "."
						local parents = {}
						table.insert(parents, key)
						if require(table_module).contains(spec.divtype, "country") then
							-- top-level country, constituent country or the like
							table.insert(parents, {name = normalized_placetype, sort = key})
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
						else
							local container_iterator = m_shared.iterate_containers(group, key, spec)
							local next_containers = next(container_iterator)
							if next_containers then
								for _, container in ipairs(next_containers) do
									table.insert(parents, {
										name = placetype .. " " .. in_of .. " " .. m_shared.get_prefixed_key(
											container.key, container.spec),
										sort = key
									})
								end
							else
								-- unrecognized countries or the like
								table.insert(parents, {name = normalized_placetype, sort = key})
							end
						end
						return {
							type = "name",
							topic = canon_label,
							description = desc,
							breadcrumb = key,
							parents = parents,
						}
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
		-- Locate the container, fetch its known political divisions, and make sure the placetype corresponding to the
		-- type of capital is among the list.
		local group, spec = find_canonical_key_from_place(place, canon_label)
		if group and spec.poldiv then
			local saw_match = false
			local variant_matches = {}
			for _, div in ipairs(spec.poldiv) do
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
				local keydesc = fetch_value(spec, "keydesc") or m_shared.construct_location_description(
					group, key, spec, m_data)
				local variant_match_text = ""
				if #variant_matches > 0 then
					for i, variant_match in ipairs(variant_matches) do
						local variant_match_desc = m_data.get_placetype_display_form(variant_match,
							placetype.is_city and "city" or "noncity")
						if not variant_match_desc then
							internal_error("Unrecognized variant match plural placetype %s, coming from " ..
								"place key %s, data %s in label %s", variant_match, key, spec, label)
						end
						variant_matches[i] = variant_match_desc
					end
					variant_match_text = " (including " .. require(table_module).serialCommaJoin(variant_matches) .. ")"
				end
				local desc = "{{{langname}}} names of [[capital]]s of " .. placetype_desc .. variant_match_text ..
					" of " .. keydesc .. "."
				return {
					type = "name",
					topic = label,
					description = desc,
					breadcrumb = key,
					parents = {{name = capital_cat, sort = key}, key},
				}
			end
		end
	end
end)

local overriding_category_descriptions = {
	["autonomous cities of Spain"] = "the [[w:Autonomous communities of Spain#Autonomous_cities|autonomous cities of Spain]]",
	["regions of Albania"] = "the regions ([[periphery|peripheries]]) of [[Albania]]",
	["regions of Greece"] = "the regions ([[periphery|peripheries]]) of [[Greece]]",
	["regions of North Macedonia"] = "the regions ([[periphery|peripheries]]) of [[North Macedonia]]",
	["subprefectures of Japan"] = "[[subprefecture]]s of [[Japan]]ese [[prefecture]]s",
}

-- Handler for specific political and misc (non-political) divisions of locations (polities, subpolities, cities, etc.),
-- such as "provinces of the Philippines", "counties of Wales", "municipalities of Tocantins, Brazil",
-- "boroughs of New York City", etc. This does not handle categories for generic placetypes (cities, rivers, etc.) of
-- locations, which are handled by different handlers above.
table.insert(handlers, function(label)
	-- The label comes with an initial capitalization but we have to check both lowercase-initial and capital-initial
	-- versions of the placetype to handle e.g. [[:Category:en:Indian reserves of Canada]].
	for _, canon_label in ipairs { label, lcfirst(label) } do
		local placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		if not placetype then
			placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		end
		if placetype then
			local group, spec = find_canonical_key_from_place(place, canon_label)
			if group then
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
				local div_parent, div_prep = find_placetype(spec.poldiv)
				if div_parent == nil then -- allow false
					div_parent, div_prep = find_placetype(spec.miscdiv)
				end
				if div_parent == nil then -- allow false
					div_parent, div_prep = find_placetype(spec.addl_poldiv_for_categorization)
				end
				if div_parent ~= nil then
					if div_prep ~= in_of then
						mw.log(("Mismatch in category name '%s', has '%s' when it should have '%s'"):format(
							canon_label, in_of, div_prep))
						return nil
					end
					local linkdesc = m_data.get_placetype_display_form(placetype, spec.is_city and "city" or "noncity")
					if not linkdesc then
						internal_error("Unrecognized placetype %s when processing key %s, data %s, label %s",
							placetype, key, spec, canon_label)
					end
					local desc = overriding_category_descriptions[canon_label]
					if not desc then
						local keydesc = fetch_value(spec, "keydesc") or m_shared.construct_location_description(
							group, key, spec, m_data)
						desc = linkdesc .. " " .. in_of .. " " .. keydesc
					end
					desc = "{{{langname}}} names of " .. desc .. "."
					local parents = {}
					table.insert(parents, key)
					if div_parent then -- div_parent may be `false`
						if require(table_module).contains(spec.divtype, "country") then
							-- top-level country, constituent country or the like
							table.insert(parents, {name = placetype, sort = key})
							table.insert(parents, "political divisions of specific countries")
						else
							local container_iterator = m_shared.iterate_containers(group, key, spec)
							local next_containers = next(container_iterator)
							if next_containers then
								for _, container in ipairs(next_containers) do
									table.insert(parents, {
										name = div_parent .. " " .. in_of .. " " .. m_shared.get_prefixed_key(
											container.key, container.spec),
										sort = key
									})
								end
							else
								-- unrecognized countries or the like
								table.insert(parents, {name = placetype, sort = key})
							end
						end
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

labels["political divisions of specific countries"] = {
	type = "grouping",
	description = "{{{langname}}} categories for political divisions of specific countries.",
	parents = {"places"},
}

-- Misc. FIXME: Remove the need for this.
labels["nomes of Ancient Egypt"] = {
	type = "name",
	-- special-cased description
	description = "{{{langname}}} names of the [[nome]]s of [[Ancient Egypt]].",
	breadcrumb = "nomes",
	parents = {"Ancient Egypt"},
}

return {LABELS = labels, HANDLERS = handlers}
