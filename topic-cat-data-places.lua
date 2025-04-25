local labels = {}
local handlers = {}

local m_table = require("Module:table")
local en_utilities_module = "Module:en-utilities"
local string_utilities_module = "Module:string utilities"

local m_locations = require("Module:place/locations")
local m_placetypes = require("Module:place/placetypes")
local placetype_data = m_placetypes.placetype_data
local internal_error = m_locations.internal_error

local dump = mw.dumpObject
local insert = table.insert
local concat = table.concat
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

See [[Module:place]] for an introduction to the terminology associated with places along with a list of all the relevant
modules, along with for more specific information on types of toponyms and placetypes and how their categorization
works.
]==]

local function lcfirst(label)
	return mw.getContentLanguage():lcfirst(label)
end

local function fetch_keydesc(group, key, spec)
	local val = spec.keydesc
	if is_callable(val) then
		val = val(group, key, spec)
		spec.keydesc = val
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
for placetype, capital_cat in pairs(m_placetypes.placetype_to_capital_cat) do
	capital_cat_to_placetype[capital_cat] = placetype
end

-- Handler for bare categories for all types of capitals. This needs to precede the handler for bare placetype
-- categories as some of the types of capitals exist as placetypes as well.
insert(handlers, function(label)
	label = lcfirst(label)
	local capital_placetype = capital_cat_to_placetype[label]
	if capital_placetype then
		local pl_placetype = m_placetypes.pluralize_placetype(capital_placetype)
		local linkdesc = m_placetypes.get_placetype_display_form(pl_placetype, "top-level")
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
insert(handlers, function(label)
	for _, canon_label in ipairs { lcfirst(label), label } do
		local ptdesc, ptdata = m_placetypes.get_placetype_display_form(canon_label, "top-level")
		if ptdesc then
			local bare_category_parent = m_placetypes.get_equiv_placetype_prop(canon_label, function(pt)
				local bare_category_parent = m_placetypes.get_placetype_prop(pt, "bare_category_parent")
				if bare_category_parent then
					return bare_category_parent
				end
				local class = m_placetypes.get_placetype_prop(pt, "class")
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
			local addl_bare_category_parents = m_placetypes.get_equiv_placetype_prop(canon_label, function(pt)
				return m_placetypes.get_placetype_prop(pt, "addl_bare_category_parents")
			end, {
				from_category = true,
				no_split_qualifiers = true,
			})
			local parents = {bare_category_parent}
			if addl_bare_category_parents then
				m_table.extend(parents, addl_bare_category_parents)
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

local function fetch_primary_placetype(key, spec)
	local placetype = spec.placetype
	if type(placetype) == "table" then
		placetype = placetype[1]
	end
	if not placetype then
		internal_error("No placetype specified or defaulted for key %s, spec %s", key, spec)
	end
	return placetype
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
local function construct_linked_location(group, key, spec)
	local full_placename, elliptical_placename = m_locations.key_to_placename(group, key)
	local linked_placename
	if elliptical_placename ~= full_placename then
		local full_placename_title = mw.title.new(full_placename)
		if full_placename_title and full_placename_title.exists then
			linked_placename = m_locations.construct_linked_placename(spec, full_placename)
		else
			local elliptical_placename_title = mw.title.new(elliptical_placename)
			if elliptical_placename_title and elliptical_placename_title.exists then
				linked_placename = m_locations.construct_linked_placename(spec, elliptical_placename, full_placename)
			end
		end
	end
	return linked_placename or m_locations.construct_linked_placename(spec, full_placename)
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
local function construct_location_description(group, key, spec)
	local parts = {}
	local function ins(txt)
		insert(parts, txt)
	end
	ins(construct_linked_location(group, key, spec))
	local iteration = 0
	local need_closing_paren = false
	local containers = {{group = group, key = key, spec = spec}}
	local container_iterator = m_locations.iterate_containers(group, key, spec)
	while true do
		iteration = iteration + 1
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
		local next_containers = container_iterator()
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
			local placetypes = {}
			local prepositions = {}
			for _, container in ipairs(containers) do
				local container_type = fetch_primary_placetype(container.key, container.spec)
				m_table.insertIfNot(placetypes, m_placetypes.pluralize_placetype(container_type))
				m_table.insertIfNot(prepositions, m_placetypes.get_placetype_entry_preposition(container_type))
			end
			if iteration == 1 then
				ins(", ")
			elseif iteration == 2 then
				ins(" (which are ")
				need_closing_paren = true
			else
				ins(", which are ")
			end
			if is_former then
				ins("former ")
			end
			ins(m_table.serialCommaJoin(placetypes))
			ins(" ")
			ins(concat(prepositions, "/"))
		else
			if iteration == 1 then
				ins(", ")
			elseif iteration == 2 then
				ins(" (which is ")
				need_closing_paren = true
			else
				ins(", which is ")
			end
			local container_type = fetch_primary_placetype(containers[1].key, containers[1].spec)
			if is_former then
				ins("a former ")
			else
				ins(m_placetypes.get_placetype_article(container_type))
				ins(" ")
			end
			ins(container_type)
			ins(" ")
			ins(m_placetypes.get_placetype_entry_preposition(container_type))
		end
		ins(" ")
		first_container = false
		containers = next_containers
		local container_locations = {}
		for _, container in ipairs(containers) do
			insert(container_locations, construct_linked_location(container.group, container.key,
				container.spec))
		end
		ins(m_table.serialCommaJoin(container_locations))
	end
	if need_closing_paren then
		ins(")")
	end

	return concat(parts)
end

local function normalize_cat_as(cat_as, div)
	if type(cat_as) ~= "table" or cat_as.type then
		cat_as = {cat_as}
	end
	local ret_cat_as = {}
	for _, pt_cat_as in ipairs(cat_as) do
		if type(pt_cat_as) == "string" then
			pt_cat_as = {type = pt_cat_as}
		end
		insert(ret_cat_as, {type = pt_cat_as.type, prep = pt_cat_as.prep or div.prep or "of"})
	end
	return ret_cat_as
end

-- Find the specified plural placetype among the divs for a given known location. Return a list of cat_as specs, where
-- each spec is of the form {type = "PLURAL_PLACETYPE", prep = "PREP"} indicating the plural placetype to use when
-- categorizing and the preposition to follow.
local function find_placetype_cat_as(divs, pl_placetype)
	if divs then
		if type(divs) ~= "table" then
			divs = {divs}
		end
		for _, div in ipairs(divs) do
			if type(div) == "string" then
				div = {type = div}
			end
			if div.type == pl_placetype then
				local cat_as = div.cat_as or div.type
				return normalize_cat_as(cat_as, div)
			end
		end
	end

	return nil
end

-- Handler for bare placename categories for known locations in `locations` in [[Module:place/locations]].
insert(handlers, function(label)
	for _, canon_label in ipairs { label, lcfirst(label) } do
		local group, spec = m_locations.find_canonical_key(canon_label)
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
			local container_iterator = m_locations.iterate_containers(group, canon_label, spec)
			local containers = container_iterator()
			if not bare_label_parents then
				bare_label_parents = {"+++"}
			end
			local full_location_placename, elliptical_location_placename = m_locations.key_to_placename(group, canon_label)
			local full_container_placename
			if containers then
				full_container_placename, _ = m_locations.key_to_placename(containers[1].group, containers[1].key)
			end
			local inserted_containers = false
			for _, parent in ipairs(bare_label_parents) do
				if parent == "+++" then
					parent = "PL_PLACETYPE PREP CONTAINER"
				end
				if parent:find("CONTAINER") then
					if not containers then
						internal_error("Parent category %s needs the container of %s but no containers specified: %s",
							parent, canon_label, spec)
					end
					local location_type = fetch_primary_placetype(canon_label, spec)
					local pl_location_type = m_placetypes.pluralize_placetype(location_type)
					for _, container in ipairs(containers) do
						local per_container_parent = parent
						local cat_as_list
						if per_container_parent:find("PL_PLACETYPE") then
							if spec.bare_category_parent_type then
								cat_as_list = normalize_cat_as(spec.bare_category_parent_type, spec)
							else
								cat_as_list = find_placetype_cat_as(container.spec.divs, pl_location_type) or
									find_placetype_cat_as(container.spec.addl_divs, pl_location_type)
							end
						end
						if not cat_as_list then
							local canon_placetype, ptdata, ptmatch = m_placetypes.get_placetype_data(location_type, "from category")
							if not canon_placetype or not (ptdata.generic_before_non_cities or ptdata.generic_before_cities) then
								internal_error("Unable to locate plural location type %s among the divs or addl_divs " ..
									"for container key %s spec %s, and the location type is either not in placetype_data or " ..
									"not identified as a generic placetype", pl_location_type, container.key, container.spec)
							end
							cat_as_list = {{type = pl_location_type, prep =
								m_placetypes.get_placetype_entry_preposition(location_type)}}
						end
						local prefixed_key = m_placetypes.get_prefixed_key(container.key, container.spec)
						per_container_parent = per_container_parent:gsub("CONTAINER",
							require(string_utilities_module).replacement_escape(prefixed_key))
						for _, cat_as in ipairs(cat_as_list) do
							local per_container_per_placetype_parent = per_container_parent
							per_container_per_placetype_parent = per_container_per_placetype_parent:gsub("PL_PLACETYPE",
								require(string_utilities_module).replacement_escape(cat_as.type))
							per_container_per_placetype_parent = per_container_per_placetype_parent:gsub("PREP",
								require(string_utilities_module).replacement_escape(cat_as.prep))
							m_table.insertIfNot(parents, per_container_per_placetype_parent)
						end
					end
					inserted_containers = true
				else
					m_table.insertIfNot(parents, parent)
				end
			end
			if not inserted_containers and containers then
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
								"containers: %s", specname, val, canon_label, spec)
						end
						val = val:gsub("%%c", full_container_placename)
					end
				end
				return val
			end

			local description = spec.fulldesc or (
				"{{{langname}}} terms related to the people, culture, or territory of " ..
				(fetch_keydesc(group, canon_label, spec) or construct_location_description(
					group, canon_label, spec)) .. ".")
			local full_placename, _ = m_locations.key_to_placename(group, canon_label)
			return {
				type = "topic",
				description = description,
				breadcrumb = full_placename,
				parents = parents,
				wp = format_boxval(wp, "wp"),
				wpcat = format_boxval(wpcat, "wpcat"),
				commonscat = format_boxval(commonscat, "commonscat"),
			}
		end
	end
end)

local function find_canonical_key_from_place(place, canon_label)
	local has_the = false
	local key
	if place:find("^the ") then
		key = place:gsub("^the ", "")
		has_the = true
	else
		key = place
	end
	local group, spec = m_locations.find_canonical_key(key)
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
		return group, key, spec
	end
	return nil
end


-- Handler for generic placetypes (those whose categories are added through category generation handlers or through
-- explicit category specs in the placetype data) for known locations in [[Module:place/locations]]. All such
-- placetypes have either a `generic_before_non_cities` setting (meaning they can occur before non-city locations) or
-- `generic_before_cities` setting (meaning they can occur before cities), or both. Examples of such categories are
-- "cities in the Bahamas" or "rivers in Western Australia, Australia", or (for city locations)
-- "neighbourhoods of Hong Kong" or "places in Melbourne".
insert(handlers, function(label)
	for _, canon_label in ipairs { lcfirst(label), label } do
		local placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		if not placetype then
			placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		end
		if placetype then
			local normalized_placetype = placetype == "neighbourhoods" and "neighborhoods" or placetype
			local canon_placetype, ptdata, ptmatch = m_placetypes.get_placetype_data(normalized_placetype, "from category")
			if canon_placetype and (ptdata.generic_before_non_cities or ptdata.generic_before_cities) then
				local group, key, spec = find_canonical_key_from_place(place, canon_label)
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
						local linkdesc = m_placetypes.get_placetype_display_form(placetype,
							spec.is_city and "city" or "noncity")
						if not linkdesc then
							internal_error("Unrecognized placetype %s when processing key %s, data %s, label %s",
								placetype, key, spec, canon_label)
						end
						local keydesc = fetch_keydesc(group, key, spec) or
							construct_location_description(group, key, spec)
						desc = linkdesc .. " " .. in_of .. " " .. keydesc
						desc = "{{{langname}}} names of " .. desc .. "."
						local parents = {}
						insert(parents, key)
						if spec.placetype == "country" or m_table.contains(spec.placetype, "country") then
							-- top-level country, constituent country or the like
							insert(parents, {name = normalized_placetype, sort = key})
							local category_class = m_placetypes.get_equiv_placetype_prop(normalized_placetype,
								function(pt) return m_placetypes.get_placetype_prop(pt, "class") end, {
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
								insert(parents, "political divisions of specific countries")
							end
						else
							local container_iterator = m_locations.iterate_containers(group, key, spec)
							local next_containers = container_iterator()
							if next_containers then
								for _, container in ipairs(next_containers) do
									local container_prep
									if container.spec.is_city then
										container_prep = ptdata.generic_before_cities
									else
										container_prep = ptdata.generic_before_non_cities
									end
									if not container_prep then
										internal_error("For container key %s spec %s defines is_city = %s but " ..
											"there is no corresponding `generic_before_*` setting in the " ..
											"placedata for placetype %s", container.key, container.spec,
											container.spec.is_city, placetype)
									end
									insert(parents, {
										name = placetype .. " " .. container_prep .. " " .. m_placetypes.get_prefixed_key(
											container.key, container.spec),
										sort = key
									})
								end
							else
								-- unrecognized countries or the like
								insert(parents, {name = normalized_placetype, sort = key})
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
	end
end)

-- Handler for "state capitals of the United States", "provincial capitals of Canada", etc. This must precede the next
-- handler for specific political and misc (non-political) divisions of polities and subpolities, such as
-- "provinces of the Philippines", because "departmental capitals" is listed in cat_as for French prefectures and so
-- will trigger an error if that handler runs before this one.
insert(handlers, function(label)
	label = lcfirst(label)
	local capital_cat, place = label:match("^([a-z%- ]- capitals) of (.*)$")
	-- Make sure we recognize the type of capital.
	if place and capital_cat_to_placetype[capital_cat] then
		local placetype = capital_cat_to_placetype[capital_cat]
		local pl_placetype = m_placetypes.pluralize_placetype(placetype)
		-- Locate the container, fetch its known political divisions, and make sure the placetype corresponding to the
		-- type of capital is among the list.
		local group, key, spec = find_canonical_key_from_place(place, canon_label)
		if group and (spec.divs or spec.addl_divs) then
			local saw_match = false
			local variant_matches = {}
			local divlists = {}
			if spec.divs then
				insert(divlists, spec.divs)
			end
			if spec.addl_divs then
				insert(divlists, spec.addl_divs)
			end
			for _, divlist in ipairs(divlists) do
				for _, div in ipairs(divlist) do
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
							insert(variant_matches, div.type)
						end
					end
				end
			end
			if saw_match then
				-- Everything checks out, construct the category description.
				local placetype_desc = m_placetypes.get_placetype_display_form(pl_placetype,
					placetype.is_city and "city" or "noncity")
				if not placetype_desc then
					internal_error("Unrecognized plural placetype %s, generated as the plural of %s, which " ..
						"was found as the placetype of capital placetype %s in label %s", pl_placetype,
						placetype, capital_cat, label)
				end
				local keydesc = fetch_keydesc(group, key, spec) or construct_location_description(group, key, spec)
				local variant_match_text = ""
				if #variant_matches > 0 then
					for i, variant_match in ipairs(variant_matches) do
						local variant_match_desc = m_placetypes.get_placetype_display_form(variant_match,
							placetype.is_city and "city" or "noncity")
						if not variant_match_desc then
							internal_error("Unrecognized variant match plural placetype %s, coming from " ..
								"place key %s, data %s in label %s", variant_match, key, spec, label)
						end
						variant_matches[i] = variant_match_desc
					end
					variant_match_text = " (including " .. m_table.serialCommaJoin(variant_matches) .. ")"
				end
				local desc = "{{{langname}}} names of [[capital]]s of " .. placetype_desc .. variant_match_text ..
					" of " .. keydesc .. "."
				local full_placename, _ = m_locations.key_to_placename(group, key)
				return {
					type = "name",
					topic = label,
					description = desc,
					breadcrumb = full_placename,
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
insert(handlers, function(label)
	-- The label comes with an initial capitalization but we have to check both lowercase-initial and capital-initial
	-- versions of the placetype to handle e.g. [[:Category:en:Indian reserves of Canada]].
	for _, canon_label in ipairs { label, lcfirst(label) } do
		local placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (of) (.*)$")
		if not placetype then
			placetype, in_of, place = canon_label:match("^([A-Za-z%- ]-) (in) (.*)$")
		end
		if placetype then
			local group, key, spec = find_canonical_key_from_place(place, canon_label)
			if group then
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
				local div_parent, div_prep = find_placetype(spec.divs)
				if div_parent == nil then -- allow false
					div_parent, div_prep = find_placetype(spec.addl_divs)
				end
				if div_parent == nil then -- allow false
					div_parent, div_prep = find_placetype(spec.addl_divs_for_categorization)
				end
				if div_parent ~= nil then
					if div_prep ~= in_of then
						mw.log(("Mismatch in category name '%s', has '%s' when it should have '%s'"):format(
							canon_label, in_of, div_prep))
						return nil
					end
					local linkdesc = m_placetypes.get_placetype_display_form(placetype, spec.is_city and "city" or "noncity")
					if not linkdesc then
						internal_error("Unrecognized placetype %s when processing key %s, data %s, label %s",
							placetype, key, spec, canon_label)
					end
					local desc = overriding_category_descriptions[canon_label]
					if not desc then
						local keydesc = fetch_keydesc(group, key, spec) or construct_location_description(group, key, spec)
						desc = linkdesc .. " " .. in_of .. " " .. keydesc
					end
					desc = "{{{langname}}} names of " .. desc .. "."
					local parents = {}
					insert(parents, key)
					if div_parent then -- div_parent may be `false`
						if spec.placetype == "country" or m_table.contains(spec.placetype, "country") then
							-- top-level country, constituent country or the like
							insert(parents, {name = placetype, sort = key})
							insert(parents, "political divisions of specific countries")
						else
							local container_iterator = m_locations.iterate_containers(group, key, spec)
							local next_containers = container_iterator()
							if next_containers then
								for _, container in ipairs(next_containers) do
									insert(parents, {
										name = div_parent .. " " .. in_of .. " " .. m_placetypes.get_prefixed_key(
											container.key, container.spec),
										sort = key
									})
								end
							else
								-- unrecognized countries or the like
								insert(parents, {name = placetype, sort = key})
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

-- FIXME: Everything here has been moved from [[Module:category tree/topic cat/data/Earth]]. Most should be removed.

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

labels["Middle East"] = {
	type = "related-to",
	description = "default with the",
	parents = {"Africa", "Asia"},
}

labels["Netherlands Antilles"] = {
	type = "related-to",
	description = "=the people, culture, or territory of the [[Netherlands Antilles]]",
	parents = {"Netherlands", "North America"},
}

-- FIXME: Redundant to 'Occitania, France'.
labels["Occitania"] = {
	type = "related-to",
	description = "default",
	parents = {"Europe", "France"},
}

labels["Provence"] = {
	type = "related-to",
	description = "default",
	parents = {"Provence-Alpes-Côte d'Azur, France"},
}

labels["South Asia"] = {
	type = "related-to",
	description = "default",
	parents = {"Eurasia", "Asia"},
}

return {LABELS = labels, HANDLERS = handlers}
