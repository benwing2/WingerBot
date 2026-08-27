local export = {}

-- optimisation: local variable lookup is slightly faster than global lookup
local tab_concat, type, tostring, pairs, ipairs = table.concat, type, tostring, pairs, ipairs

local function export_str(s)
	-- rudimentary escaping, to save time
	return '"' .. tostring(s):gsub('["\\]', '\\%0') .. '"'
end

local function export_array(tab)
	local items = {}
	for key, value in ipairs(tab) do
		if type(value) == 'string' then
			items[#items + 1] = export_str(value)
		elseif type(value) == 'boolean' or type(value) == 'number' then
			items[#items + 1] = tostring(value)
		else
			error("serialisation failed: unsupported array element type '" .. type(value) .. "'")
		end
	end
	return "[" .. tab_concat(items, ",") .. "]"
end

-- the second argument is a rudimentary "schema" which specifies
-- whether a table value at a given key should be serialised
-- as an array or an object; Lua uses the same table type for both
local function export_object(tab, schema)
	local items = {}
	if tab == nil then
		return "null"	
	end
	
	for key, value in pairs(tab) do
		if type(value) == 'string' then
			items[#items + 1] = export_str(key) .. ':' .. export_str(value)
		elseif type(value) == 'boolean' or type(value) == 'number' then
			items[#items + 1] = export_str(key) .. ':' .. tostring(value)
		elseif type(value) == 'table' then
			if not schema then
				error("no schema given for array with table values, key '" .. key .. "'")
			end
			local ktype = {}
			if type(schema) == 'table' then
				ktype = schema[key]
			end
			-- false indicates array, true indicates un-schematised object
			if ktype == false then
				items[#items + 1] = export_str(key) .. ':' .. export_array(value)
			else
				items[#items + 1] = export_str(key) .. ':' .. export_object(value, ktype)
			end
		else
			error("serialisation failed: unsupported object value type '" .. type(value) .. "'")
		end	
	end
	return "{" .. tab_concat(items, ",") .. "}"
end

function export.export_languages(item_filter, key_filter, skip_nulls)
	if type(item_filter) == "table" then
		key_filter = {}
		local i = 2
		while item_filter.args[i] do
			if tonumber(item_filter.args[i]) ~= nil then
				key_filter[#key_filter + 1] = tonumber(item_filter.args[i])
			else
				key_filter[#key_filter + 1] = item_filter.args[i]
			end
			i = i + 1
		end
		if #key_filter == 0 then
			key_filter = nil
		end
		skip_nulls = require('Module:yesno')(item_filter.args.nulls)
		item_filter = item_filter.args[1]
	end

	item_filter = (item_filter ~= "") and item_filter or function() return true end
	if type(item_filter) == 'string' then
		if item_filter == "TWO_LETTER" then
			function item_filter(key, value)
				return #key == 2
			end
		elseif item_filter == "TWO_THREE_LETTER" then
			function item_filter(key, value)
				return #key <= 3
			end
		elseif item_filter == "TWO_THREE_LETTER_REGULAR" then
			function item_filter(key, value)
				return (#key <= 3) and value.type == 'regular'
			end
		elseif item_filter:sub(1, 1) == '=' then
			local list = {}
			for item in mw.text.gsplit(item_filter:sub(2), ',') do
				list[item] = true
			end
			function item_filter(key, value)
				return list[key]
			end
		else
			local t = item_filter
			function item_filter(key, value)
				return value.type == t
			end
		end
	end

	local data = mw.loadData("Module:languages/data/all")
	local items = {}

	-- false indicates array, true indicates un-schematised object (just dump raw)
	local schema = {
		canonicalName = false,
		type = false,
		scripts = false,
		family = false,
		otherNames = false,
		ancestors = false,
		wikimedia_codes = false,
		aliases = false,
		varieties = false,
		sort_key = true,
		entry_name = true
	}
	
	for key, value in pairs(data) do
		if item_filter(key, value) then
			if key_filter then
				if #key_filter == 1 then
					local item = value[key_filter[1]]
					local itsc = schema[key_filter[1]]
						
					if item == nil then
						if not skip_nulls then
							items[#items + 1] = export_str(key) .. ':null'
						end
					else 
						items[#items + 1] = export_str(key) .. ':' .. 
							((type(item) == "string" and export_str(item))
							or (itsc == false and export_array(item))
							or export_object(item, true))
					end
				else
					local langobj = {}
					for _, fkey in pairs(key_filter) do
						langobj[fkey] = value[fkey]
					end
					items[#items + 1] = export_str(key) .. ':' .. export_object(langobj, schema)
				end
			else
				items[#items + 1] = export_str(key) .. ':' .. export_object(value, schema)
			end			
		end
	end

	return "{" .. tab_concat(items, ",") .. "}"
end

function export.export_scripts()
	local data = mw.loadData("Module:scripts/data")
	
	local items = {}
	
	for key, value in pairs(data) do
		items[#items + 1] = export_str(key) .. ':' .. export_object(value, {
			canonicalName = false,
			characters = false,
			systems = false,
			otherNames = false,
			aliases = false,
			varieties = false,
		})
	end

	return "{" .. tab_concat(items, ",") .. "}"
end

function export.export_etymology_languages()
	local data = mw.loadData("Module:etymology languages/data")
	
	local items = {}
	
	for key, value in pairs(data) do
		items[#items + 1] = export_str(key) .. ':' .. export_object(value, {
			canonicalName = false,
			parent = false,
			wikipedia_article = false,
			otherNames = false,
			ancestors = false,
			aliases = false,
			entry_name = false,
			varieties = true,
			strip_diacritics = {  -- this is a bit of a hack...
				remove_exceptions = false,
			},
		})
	end

	return "{" .. tab_concat(items, ",") .. "}"
end

function export.export_families()
	local data = mw.loadData("Module:families/data")

	local items = {}
	
	for key, value in pairs(data) do
		items[#items + 1] = export_str(key) .. ':' .. export_object(value, {
			canonicalName = false,
			otherNames = false,
			family = false,
			aliases = false,
			varieties = false
		})
	end

	return "{" .. tab_concat(items, ",") .. "}"
end

function export.export_labels()
	local data = mw.loadData("Module:labels/data")

	local labels = {}
	
	for key, value in pairs(data.labels) do
		if type(value) == "string" then
			labels[#labels + 1] = export_str(key) .. ':' .. export_str(value)
		else
			labels[#labels + 1] = export_str(key) .. ':' .. export_object(value, {
				plain_categories = false,
				topical_categories = false,
				pos_categories = false,
				regional_categories = false
			})
		end
	end

	return "{" .. tab_concat(labels, ',') .. "}"
end

function export.export_wgs()
	local m_wgdata = mw.loadData('Module:workgroup ping/data')
	local items = {}

	for key, value in pairs(m_wgdata) do
		if type(value) == 'string' then
			items[#items + 1] = export_str(key) .. ':' .. export_str(value)
		else
			local item = { desc = value.desc; category = value.category; members = {} }
			
			for _, user in ipairs(value) do
				item.members[#item.members + 1] = user
			end
			
			items[#items + 1] = export_str(key) .. ':' .. export_object(item, {
				members = false
			})
		end
	end
	
	return "{" .. tab_concat(items, ",") .. "}"
end

-- replacement for using the [[mw:API]] to do [[Special:PrefixIndex/Template:langrev/]]
-- TODO: limits?
function export.complete_langname(frame)
	local m_langs = mw.loadData("Module:languages/data/all")
	local target = frame.args[1]

	local items = {}
	for code, data in pairs(m_langs) do
		for _, name in ipairs(data.names) do
			if name:sub(1, #target) == target then
				items[#items + 1] = export_str(name) .. ":" .. export_str(code)
			end
		end
	end
	
	return "{" .. tab_concat(items, ",") .. "}"
end

return export
