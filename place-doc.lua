local export = {}

local m_data = require("Module:place/data")
local m_shared = require("Module:place/shared-data")
local en_utilities_module = "Module:en-utilities"
local ulower = require("Module:string utilities").lower

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
	for key, value in pairs(m_data.placetype_data) do
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
			alldata[key].display = m_data.get_placetype_display_form(key_no_exclamation_point, "top-level")
		else
			alldata[key].display = m_data.get_placetype_display_form(key)
		end
		alldata[key].fallback = value.fallback
		alldata[key].article = value.article
		alldata[key].preposition = value.preposition
		alldata[key].former_type = value.former_type or value.class
	end

	-- Handle aliases
	for key, value in pairs(m_data.placetype_aliases) do
		ensure_key(value)
		if not alldata[value].aliases then
			alldata[value].aliases = {key}
		else
			table.insert(alldata[value].aliases, key)
		end
	end

	-- Convert to list and sort
	local alldata_list = {}
	for key, value in pairs(alldata) do
		table.insert(alldata_list, {key, value})
		if value.aliases then
			table.sort(value.aliases)
		end
	end
	table.sort(alldata_list, function(fs1, fs2) return ulower(fs1[1]) < ulower(fs2[1]) end)

	-- Convert to wikitable
	local parts = {}
	table.insert(parts, '{|class="wikitable"')
	table.insert(parts, "! Placetype !! Fallback !! Article !! Display form !! Following preposition !! Aliases !! 'former' type !! Categorizes?")
	for _, placetype_data in ipairs(alldata_list) do
		local placetype = placetype_data[1]
		local data = placetype_data[2]
		table.insert(parts, "|-")
		local sparts = {}
		table.insert(sparts, placetype)
		table.insert(sparts, data.fallback or "")
		table.insert(sparts, data.article or require(en_utilities_module).get_indefinite_article(placetype))
		table.insert(sparts, data.display or placetype)
		table.insert(sparts, data.preposition or "")
		table.insert(sparts, data.aliases and table.concat(data.aliases, ", ") or "")
		table.insert(sparts, data.former_type or "")
		table.insert(sparts, data.categorizes and "yes" or "")
		table.insert(parts, "| " .. table.concat(sparts, " || "))
	end
	table.insert(parts, "|}")
	return table.concat(parts, "\n")
end


function export.placename_table()
	-- We combine all placetype data into objects of the following form:
	-- {display=DISPLAY_AS, cat=CATEGORIZE_AS, article=ARTICLE}
	local alldata = {}

	local function ensure_key(key)
		if not alldata[key] then
			alldata[key] = {}
		end
	end

	-- Handle display aliases
	for placetype, names in pairs(m_data.placename_display_aliases) do
		for name, alias in pairs(names) do
			local place = placetype .. "/" .. name
			ensure_key(place)
			alldata[place].display = placetype .. "/" .. alias
		end
	end

	-- Handle category aliases
	for placetype, names in pairs(m_data.placename_cat_aliases) do
		for name, alias in pairs(names) do
			local place = placetype .. "/" .. name
			ensure_key(place)
			alldata[place].cat = placetype .. "/" .. alias
		end
	end

	-- Handle places with article
	for placetype, names in pairs(m_data.placename_article) do
		for name, alias in pairs(names) do
			local place = placetype .. "/" .. name
			ensure_key(place)
			alldata[place].article = alias
		end
	end

	-- Handle categorization for cities/etc.
	for _, group in ipairs(m_shared.polities) do
		for key, value in pairs(group.data) do
			-- Use the group's value_transformer to ensure that 'nocities' and 'containing_polity'
			-- keys are present if they should be.
			value = group.value_transformer(group, key, value)
			local placename = key:gsub("^the ", "")
			placename = group.key_to_placename and group.key_to_placename(placename) or placename
			-- We categorize both in key, and in the larger polity that the key is part of,
			-- e.g. [[Hirakata]] goes in both "Cities in Osaka Prefecture" and
			-- "Cities in Japan".
			local divtype = value.divtype or group.default_divtype
			if type(divtype) ~= "table" then
				divtype = {divtype}
			end
			if type(placename) ~= "table" then
				placename = {placename}
			end
			for _, dt in ipairs(divtype) do
				for _, pn in ipairs(placename) do
					local place = dt .. "/" .. pn
					ensure_key(place)
					if not value.nocities then
						local retcats = {"Cities in " .. key}
						if value.containing_polity then
							table.insert(retcats, "Cities in " .. value.containing_polity)
						end
						alldata[place].city_cats = retcats
					end
					if value.poldiv then
						alldata[place].poldiv = value.poldiv
					end
					if value.miscdiv then
						alldata[place].miscdiv = value.miscdiv
					end
				end
			end
		end
	end

	-- Convert to list and sort
	local alldata_list = {}
	for key, value in pairs(alldata) do
		table.insert(alldata_list, {key, value})
		if value.aliases then
			table.sort(value.aliases)
		end
	end
	table.sort(alldata_list, function(fs1, fs2) return fs1[1] < fs2[1] end)

	-- Convert to wikitable
	local parts = {}
	table.insert(parts, '{|class="wikitable"')
	table.insert(parts, "! Placename !! Article !! Display as !! Categorize as !! City categories !! Recognized political subdivisions !! Recognized traditional subdivisions")
	for _, placename_data in ipairs(alldata_list) do
		local placename = placename_data[1]
		local data = placename_data[2]
		table.insert(parts, "|-")
		local sparts = {}
		table.insert(sparts, placename)
		table.insert(sparts, data.article or "")
		table.insert(sparts, data.display and data.display or "(same)")
		table.insert(sparts, data.cat and data.cat or "(same)")
		table.insert(sparts, data.city_cats and table.concat(data.city_cats, "; ") or "")
		local function process_divs(divs)
			local divtypes = {}
			if divs then
				if type(divs) ~= "table" then
					divs = {divs}
				end
				for _, div in ipairs(divs) do
					if type(div) == "string" then
						div = {type = div}
					end
					table.insert(divtypes, div.type)
				end
			end
			table.insert(sparts, table.concat(divtypes, ", "))
		end
		process_divs(data.poldiv)
		process_divs(data.miscdiv)
		table.insert(parts, "| " .. table.concat(sparts, " || "))
	end
	table.insert(parts, "|}")
	return table.concat(parts, "\n")
end


function export.qualifier_table()
	local alldata_list = {}

	-- Create list
	for qualifier, display in pairs(m_data.placetype_qualifiers) do
		table.insert(alldata_list, {qualifier, display})
	end
	table.sort(alldata_list, function(fs1, fs2) return fs1[1] < fs2[1] end)

	-- Convert to wikitable
	local parts = {}
	table.insert(parts, '{|class="wikitable"')
	table.insert(parts, "! Qualifier !! Display as")
	for _, qualifier_data in ipairs(alldata_list) do
		local qualifier = qualifier_data[1]
		local display_as = qualifier_data[2]
		table.insert(parts, "|-")
		local sparts = {}
		table.insert(sparts, qualifier)
		if display_as == true then
			display_as = "[[" .. qualifier .. "]]"
		end
		table.insert(sparts, display_as == false and qualifier or "'''" .. display_as .. "'''")
		table.insert(parts, "| " .. table.concat(sparts, " || "))
	end
	table.insert(parts, "|}")
	return table.concat(parts, "\n")
end


return export
