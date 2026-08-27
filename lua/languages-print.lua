local export = {}

local byte = string.byte
local concat = table.concat
local escape = require("Module:debug/escape")
local format = string.format
local highlight = require("Module:debug").highlight
local insert = table.insert
local pairs = pairs
local require = require
local sorted_pairs = require("Module:table").sortedPairs
local toJSON = require("Module:JSON").toJSON

local function iterate_data(func, module_name)
	for code, data in pairs(require(module_name)) do
		func(code, data)
	end
end

local function for_code_and_data(func, module_type)
	if module_type == "language" then
		iterate_data(func, "Module:languages/data/2")
		for b = byte("a"), byte("z") do
			iterate_data(func, format("Module:languages/data/3/%c", b))
		end
		iterate_data(func, "Module:languages/data/exceptional")
	elseif module_type == "etymology" then
		iterate_data(func, "Module:etymology languages/data")
	elseif module_type == "family" then
		iterate_data(func, "Module:families/data")
	elseif module_type == "script" then
		iterate_data(func, "Module:scripts/data")
	end
end

local function dump_string(s)
	return format('"%s"', escape(s, "double"))
end

local function dump_table(data)
	local output, i = {"return {"}, 1

	for k, v in sorted_pairs(data) do
		i = i + 1
		output[i] = format("\t[%s] = %s,", dump_string(k), dump_string(v))
	end

	insert(output, "}")

	return concat(output, "\n")
end

local function print_data(t, output)
	if output == "plain" then
		return dump_table(t)
	elseif output == "json" then
		return toJSON(t, {compress = true, sort_keys = true})
	end
	return highlight(dump_table(t))
end

function export.code_to_name(frame)
	local args, result = frame.args, {}
	for_code_and_data(function(code, data)
		result[code] = data[1]
	end, args[2])
	return print_data(result, args[1])
end

function export.name_to_code(frame)
	local args, result = frame.args, {}
	local langtype, get_obj = args[2]

	if langtype == "script" then
		get_obj = require("Module:scripts").getByCode
	else
		local get_lang = require("Module:languages").getByCode
		function get_obj(code)
			return get_lang(code, nil, true, true)
		end
	end

	for_code_and_data(function(code, data)
		local name = data[1]
		local current = result[name]
		if not current then
			result[name] = code
			return
		end
		-- Sometimes, multiple scripts have the same name; less so now than before, but we still (at the
		-- moment) have pjt-Latn called "Latin". Prefer the senior code.
		local check = get_obj(current)
		while check do
			if check:getCode() == code then
				result[name] = code
				break
			end
			check = check:getParent()
		end
	end, langtype)
	return print_data(result, args[1])
end

function export.appendix_constructed_canonical_names()
	local names = {}
	for_code_and_data(function(_, data)
		if data.type == "appendix-constructed" then
			insert(names, data[1])
		end
	end, "language")
	require("Module:collation").sort(names)
	return toJSON(names, {compress = true})
end

-- Compare a language data module with its /extra submodule.
local function get_extra_data_diff(suffix)
	local data_module = require("Module:languages/data/" .. suffix)
	local extra_module = require("Module:languages/data/" .. suffix .. "/extra")
	local missing, extraneous = {}, {}

	for code in pairs(data_module) do
		if extra_module[code] == nil then
			insert(missing, code)
		end
	end

	for code in pairs(extra_module) do
		if data_module[code] == nil then
			insert(extraneous, code)
		end
	end

	require("Module:collation").sort(missing)
	require("Module:collation").sort(extraneous)

	return missing, extraneous
end

function export.extra_data_diff(frame)
	local missing, extraneous = get_extra_data_diff(frame.args[2])

	if frame.args[1] == "json" then
		return toJSON({ missing = missing, extraneous = extraneous }, { compress = true })
	end

	return format("missing: %s\nextraneous: %s", concat(missing, ", "), concat(extraneous, ", "))
end

-- Language codes defined in a data module but missing from its /extra submodule.
function export.missing_extra_codes(frame)
	local missing, _ = get_extra_data_diff(frame.args[2])

	if frame.args[1] == "json" then
		return toJSON(missing, { compress = true })
	end

	return concat(missing, "\n")
end

return export
