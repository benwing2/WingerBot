local export = {}

local m_placetypes = require("Module:place/placetypes")
local m_locations = require("Module:place/locations")
local en_utilities_module = "Module:en-utilities"
local m_table = require("Module:table")
local ulower = require("Module:string utilities").lower

local insert = table.insert
local concat = table.concat

function export.placetype_table()
	-- We combine all placetype data into objects of the following form:
	-- {aliases={ALIASES}, categorizes=true, fallback=PLACETYPE_FALLBACK,
	--  display=DISPLAY_FORM, article=ARTICLE, preposition=FOLLOWING_PREPOSITION,
	--  former_type=FORMER_TYPE}
	local alldata = {}

	local function ensure_key(key)
		if not alldata[key] then
			alldata[key] = {}
		end
	end

	-- Does it categorize? Yes if there is a non-empty "default" key or key with slash in it.
	for key, value in pairs(m_placetypes.placetype_data) do
		ensure_key(key)
		for k, v in pairs(value) do
			if (k == "default" or k == "cat_handler" or k:find("/")) and (v and (type(v) ~= "table" or next(v))) then
				alldata[key].categorizes = true
				break
			end
		end
		if value.link == false then
			alldata[key].display = "''(internal use only)''"
		elseif key:find("!$") then
			local key_no_exclamation_point = key:sub(1, -2)
			alldata[key].display = m_placetypes.get_placetype_display_form(key_no_exclamation_point, "top-level")
		else
			alldata[key].display = m_placetypes.get_placetype_display_form(key)
		end
		alldata[key].fallback = value.fallback
		alldata[key].article = value.article
		alldata[key].preposition = value.preposition
		alldata[key].former_type = value.former_type or value.class
	end

	-- Handle aliases
	for key, value in pairs(m_placetypes.placetype_aliases) do
		ensure_key(value)
		if not alldata[value].aliases then
			alldata[value].aliases = {key}
		else
			insert(alldata[value].aliases, key)
		end
	end

	-- Convert to list and sort
	local alldata_list = {}
	for key, value in pairs(alldata) do
		insert(alldata_list, {key, value})
		if value.aliases then
			table.sort(value.aliases)
		end
	end
	table.sort(alldata_list, function(fs1, fs2) return ulower(fs1[1]) < ulower(fs2[1]) end)

	-- Convert to wikitable
	local parts = {}
	insert(parts, '{|class="wikitable"')
	insert(parts, "! Placetype !! Fallback !! Article !! Display form !! Following preposition !! Aliases !! 'former' type !! Categorizes?")
	for _, placetype_data in ipairs(alldata_list) do
		local placetype = placetype_data[1]
		local data = placetype_data[2]
		insert(parts, "|-")
		local sparts = {}
		insert(sparts, placetype)
		insert(sparts, data.fallback or "")
		insert(sparts, data.article or require(en_utilities_module).get_indefinite_article(placetype))
		insert(sparts, data.display or placetype)
		insert(sparts, data.preposition or "")
		insert(sparts, data.aliases and concat(data.aliases, ", ") or "")
		insert(sparts, data.former_type or "")
		insert(sparts, data.categorizes and "yes" or "")
		insert(parts, "| " .. concat(sparts, " || "))
	end
	insert(parts, "|}")
	return concat(parts, "\n")
end


-- FIXME: Copied from [[Module:category tree/topic cat/data/Places]]
local function normalize_cat_as(cat_as, div)
	if type(cat_as) ~= "table" then
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

function export.placename_table()
	local alldata = {}

	local function ensure_key(key)
		if not alldata[key] then
			alldata[key] = {}
		end
	end

	-- FIXME: If we display this, it needs to be a separate table.
	-- -- Handle places with article
	-- for placetype, names in pairs(m_placetypes.placename_article) do
	-- 	for name, alias in pairs(names) do
	-- 		local place = placetype .. "/" .. name
	-- 		ensure_key(place)
	-- 		alldata[place].article = alias
	-- 	end
	-- end

	for _, group in ipairs(m_locations.locations) do
		for key, spec in pairs(group.data) do
			if spec.alias_of then
				local resolved_key
				local dest_field
				if spec.display then
					resolved_key = spec.display == true and spec.alias_of or spec.display
					dest_field = "display_aliases"
				else
					resolved_key = spec.alias_of
					dest_field = "cat_aliases"
				end
				local full_alias_placename, elliptical_alias_placename = m_locations.key_to_placename(group, key)
				local full_canon_placename, elliptical_canon_placename =
					m_locations.key_to_placename(group, spec.alias_of)
				local full_display_placename, elliptical_display_placename
				if resolved_key ~= spec.alias_of then
					full_display_placename, elliptical_display_placename =
						m_locations.key_to_placename(group, resolved_key)
				end
				local function do_alias(alias_placename, canon_placename, display_placename)
					if not group.data[spec.alias_of] then
						m_locations.internal_error("Something wrong, can't follow alias: %s", spec.alias_of)
					end
					local placetype = spec.placetype or group.data[spec.alias_of].placetype or group.default_placetype
					if type(placetype) ~= "table" then
						placetype = {placetype}
					end
					for _, pt in ipairs(placetype) do
						local canon_place = pt .. "/" .. canon_placename
						ensure_key(canon_place)
						if not alldata[canon_place][dest_field] then
							alldata[canon_place][dest_field] = {}
						end
						local display_as = ""
						if display_placename then
							display_as = (" (display as ''%s'')"):format(display_placename)
						end
						m_table.insertIfNot(alldata[canon_place][dest_field], alias_placename .. display_as)
					end
				end
				do_alias(full_alias_placename, full_canon_placename, full_display_placename)
				if full_alias_placename ~= elliptical_alias_placename or
					full_canon_placename ~= elliptical_canon_placename or
					full_display_placename ~= elliptical_display_placename then
					do_alias(elliptical_alias_placename, elliptical_canon_placename, elliptical_display_placename)
				end
			else
				m_locations.initialize_spec(group, key, spec)
				local full_placename, elliptical_placename = m_locations.key_to_placename(group, key)
				local placenames = {}
				if full_placename ~= elliptical_placename then
					placenames = {full_placename, elliptical_placename}
				else
					placenames = {full_placename}
				end
				local placetype = spec.placetype
				if type(placetype) ~= "table" then
					placetype = {placetype}
				end
				for _, pt in ipairs(placetype) do
					for _, pn in ipairs(placenames) do
						local place = pt .. "/" .. pn
						ensure_key(place)
						local key_with_the = key
						if spec.the then
							key_with_the = "(the) " .. key_with_the
						end
						alldata[place].key = key_with_the
						if spec.containers then
							alldata[place].containers = {}
							for _, container in ipairs(spec.containers) do
								local container_group, container_key, container_spec =
									m_locations.get_matching_location {
										placetypes = container.placetype,
										key = container.key,
									}
								insert(alldata[place].containers, ("%s (%s)"):format(container.key,
									container.placetype))
							end
						end
						if spec.divs then
							alldata[place].divs = spec.divs
						end
						if spec.addl_divs then
							alldata[place].addl_divs = spec.addl_divs
						end
					end
				end
			end
		end
	end

	-- Convert to list and sort
	local alldata_list = {}
	for key, value in pairs(alldata) do
		insert(alldata_list, {key, value})
		if value.display_aliases then
			table.sort(value.display_aliases)
		end
		if value.cat_aliases then
			table.sort(value.cat_aliases)
		end
	end
	table.sort(alldata_list, function(fs1, fs2) return fs1[1] < fs2[1] end)

	-- Convert to wikitable
	local parts = {}
	insert(parts, '{|class="wikitable"')
	insert(parts, "! Placename !! Key !! Display+category aliases !! Category-only aliases !! Container !! Recognized subdivisions")
	for _, placename_data in ipairs(alldata_list) do
		local placename = placename_data[1]
		local data = placename_data[2]
		insert(parts, "|-")
		local sparts = {}
		insert(sparts, placename)
		insert(sparts, data.key)
		insert(sparts, data.display_aliases and concat(data.display_aliases, ", ") or "")
		insert(sparts, data.cat_aliases and concat(data.cat_aliases, ", ") or "")
		insert(sparts, data.containers and concat(data.containers, ", ") or "(none)")
		local divtypes = {}
		local function process_divs(divs)
			if divs then
				if type(divs) ~= "table" then
					divs = {divs}
				end
				for _, div in ipairs(divs) do
					if type(div) == "string" then
						div = {type = div}
					end
					local cat_as_note = ""
					if div.cat_as then
						local cat_as_specs = normalize_cat_as(div.cat_as, div)
						local formatted_cat_as = {}
						for _, ca in ipairs(cat_as_specs) do
							insert(formatted_cat_as, ("''%s''"):format(ca.type))
						end
						cat_as_note = " (categorize as " .. concat(formatted_cat_as, ", ") .. ")"
					end
					insert(divtypes, div.type .. cat_as_note)
				end
			end
		end
		process_divs(data.divs)
		process_divs(data.addl_divs)
		insert(sparts, concat(divtypes, "<br />"))
		insert(parts, "| " .. concat(sparts, " || "))
	end
	insert(parts, "|}")
	return concat(parts, "\n")
end


function export.qualifier_table()
	local alldata_list = {}

	-- Create list
	for qualifier, display in pairs(m_placetypes.placetype_qualifiers) do
		insert(alldata_list, {qualifier, display})
	end
	table.sort(alldata_list, function(fs1, fs2) return fs1[1] < fs2[1] end)

	-- Convert to wikitable
	local parts = {}
	insert(parts, '{|class="wikitable"')
	insert(parts, "! Qualifier !! Display as")
	for _, qualifier_data in ipairs(alldata_list) do
		local qualifier = qualifier_data[1]
		local display_as = qualifier_data[2]
		insert(parts, "|-")
		local sparts = {}
		insert(sparts, qualifier)
		if display_as == true then
			display_as = "[[" .. qualifier .. "]]"
		end
		insert(sparts, display_as == false and qualifier or "'''" .. display_as .. "'''")
		insert(parts, "| " .. concat(sparts, " || "))
	end
	insert(parts, "|}")
	return concat(parts, "\n")
end


return export
