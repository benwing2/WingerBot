local export = {}

local m_math = require("Module:math")
local m_str_utils = require("Module:string utilities")
local m_table = require("Module:table")

local codepoint = m_str_utils.codepoint
local concat = table.concat
local converter -- forward declaration
local find = string.find
local format = string.format
local gsub = string.gsub
local insert = table.insert
local ipairs = ipairs
local is_array = m_table.isArray
local is_finite_real_number = m_math.is_finite_real_number
local is_integer = m_math.is_integer
local is_utf8 = mw.ustring.isutf8
local match = string.match
local toNFC = mw.ustring.toNFC
local tonumber = tonumber
local pairs = pairs
local sorted_pairs = m_table.sortedPairs
local trycall = require("Module:fun/trycall")
local type = type

local function json_fromBoolean(b)
	return b and "true" or "false"
end

-- Given a finite real number x, returns a string containing its JSON
-- representation, with enough precision that it should round-trip correctly
-- (depending on the well-behavedness of the system on the other end).
local function json_fromNumber(x, level)
	if not is_finite_real_number(x) then
		error(format("Cannot encode non-finite real number %g", x), level)
	end
	-- Give integers within the range RFC 7159 considers interoperable.
	if is_integer(x) and x < 0x1p53 and x > -0x1p53 then
		return format("%d", x)
	end
	-- Otherwise, give a (double) float with the %g specifier, which handles any
	-- leading/trailing 0s etc. Double floats have precision ranging from 15 to
	-- 17 digits, meaning rounding artefacts can appear when precision is set to
	-- 16 or 17 (e.g. 1.1 is converted to 1.1000000000000001). Avoid this by
	-- trying each in turn, returning the first one which converts back into the
	-- original number, which avoids implying that it has higher precision than
	-- it really does.
	for prec = 15, 17 do
		local poss = format(format("%%.%dg", prec), x)
		if prec == 17 or tonumber(poss) == x then
			x = poss
			break
		end
	end
	-- If there's an exponent, remove any + sign and leading 0s from it.
	if find(x, "e", nil, true) then
		return (gsub(x, "(e%-?)%+?0*", "%1"))
	end
	-- If it resembles an integer, convert it to scientific notation to avoid
	-- the other end interpreting it as one.
	local d, f = match(x, "^(%d)(%d-)0*$")
	return d and format("%s%s%se%d", d, f == "" and "" or ".", f, #x - 1) or x
end

local function escape_codepoint(cp)
	if cp < 0x10000 then
		return format("\\u%04X", cp)
	end
	cp = cp - 0x10000
	return format("\\u%04X\\u%04X", 0xD800 + (cp / 1024), 0xDC00 + (cp % 1024))
end

local escapes
local function get_escapes()
	escapes, get_escapes = {
		[0x8] = [[\b]], [0x9] = [[\t]], [0xA] = [[\n]], [0xC] = [[\f]],
		[0xD] = [[\r]], [0x22] = [[\"]], [0x2F] = [[\/]], [0x5C] = [[\\]],
		
	}, nil
	
	local function _add(cp)
		if escapes[cp] == nil then
			escapes[cp] = escape_codepoint(cp)
		end
	end
	
	local function add(cp1, cp2)
		if cp2 == nil then
			return _add(cp1)
		end
		for cp = cp1, cp2 do
			_add(cp)
		end
	end
	
	add(0x0000, 0x001F)
	add(0x007F, 0x00A0)
	add(0x00AD)
	add(0x034F)
	add(0x0600, 0x0605)
	add(0x061C)
	add(0x06DD)
	add(0x070F)
	add(0x0890, 0x0891)
	add(0x08E2)
	add(0x115F, 0x1160)
	add(0x1680)
	add(0x17B4, 0x17B5)
	add(0x180B, 0x180F)
	add(0x2000, 0x200F)
	add(0x2028, 0x202F)
	add(0x205F, 0x206F)
	add(0x3000)
	add(0x3164)
	add(0xFDD0, 0xFDEF)
	add(0xFE00, 0xFE0F)
	add(0xFEFF)
	add(0xFFA0)
	add(0xFFF0, 0xFFFF)
	add(0x110BD)
	add(0x110CD)
	add(0x1107F)
	add(0x13430, 0x1343F)
	add(0x16FE4)
	add(0x1BC9D)
	add(0x1BCA0, 0x1BCA3)
	add(0x1D173, 0x1D17A)

	for i = 0x2, 0x11 do
		i = i * 0x10000
		add(i - 2, i - 1)
	end

	return escapes
end

local function escape_char(ch)
	local cp = codepoint(ch)
	return (escapes or get_escapes())[cp] or escape_codepoint(cp)
end

local function maybe_escape_char(ch)
	local cp = codepoint(ch)
	if cp >= 0xE0000 and cp <= 0xE0FFF then
		return escape_char(ch)
	end
	return (escapes or get_escapes())[cp] or ch
end

-- Given a string, escapes any illegal characters and wraps it in double-quotes.
-- Raises an error if the string is not valid UTF-8.
local function json_fromString(s, ascii, level)
	if not is_utf8(s) then
		error(format("Cannot encode non-UTF-8 string '%s'", s), level)
	end
	local pattern = '[%c"/\\\128-\255][\128-\191]*'
	if not ascii then
		local escaped = gsub(s, pattern, maybe_escape_char)
		if escaped == toNFC(escaped) then
			return '"' .. escaped .. '"'
		end
	end
	return '"' .. gsub(s, pattern, escape_char) .. '"'
end

local function json_fromTable(t, opts, current, level)
	local ret, open, close = {}
	if is_array(t) then
		for key, value in ipairs(t) do
			ret[key] = converter(value, opts, current, level + 1) or "null"
		end
		open, close = "[", "]"
	else
		-- `seen_keys` memoizes keys already seen, to prevent collisions (e.g. 1
		-- and "1").
		local seen_keys, colon, ascii = {}, opts.compress and ":" or " : ", opts.ascii
		for key, value in (opts.sort_keys and sorted_pairs or pairs)(t) do
			local key_type = type(key)
			if key_type == "boolean" then
				key = json_fromBoolean(key)
			elseif key_type == "number" then
				key = json_fromNumber(key, level + 1)
			elseif key_type ~= "string" then
				error(format("Cannot use type '%s' as a table key", key_type), level)
			end
			key = json_fromString(key, ascii, level + 1)
			if seen_keys[key] then
				error(format("Collision for JSON key %s", key), level)
			end
			seen_keys[key] = true
			insert(ret, key .. colon .. (converter(value, opts, current, level + 1) or "null"))
		end
		open, close = "{", "}"
	end
	ret = open .. (
		opts.compress and concat(ret, ",") .. close or
		" " .. concat(ret, ", ") .. (
			#ret == 0 and "" or " "
		) .. close
	)
	current[t] = nil
	return ret
end

function converter(this, opts, current, level) -- local declared above
	local val_type = type(this)
	if val_type == "nil" then
		return "null"
	elseif val_type == "boolean" then
		return json_fromBoolean(this)
	elseif val_type == "number" then
		return json_fromNumber(this, level + 1)
	elseif val_type == "string" then
		return json_fromString(this, opts.ascii, level + 1)
	elseif val_type ~= "table" then
		error(format("Cannot encode type '%s'", val_type), level)
	elseif current[this] then
		error("Cannot use recursive tables", level)
	end
	-- Memoize the table to enable recursion checking.
	current[this] = true
	if opts.ignore_toJSON then
		return json_fromTable(this, opts, current, level + 1)
	end
	-- Check if a toJSON method can be used. Use the lua_table flag to get a Lua
	-- table, as any options need to be applied to the output.
	local to_json = this.toJSON
	if to_json == nil then
		return json_fromTable(this, opts, current, level + 1)
	end
	-- Try to call it.
	local success, new = trycall(to_json, this, {lua_table = true})
	if success then
		-- If successful, use the returned value.
		local ret = converter(new, opts, current, level + 1)
		current[this] = nil
		return ret
	end
	-- Otherwise, treat as a conventional value.
	return json_fromTable(this, opts, current, level + 1)
end

-- This function makes an effort to convert an arbitrary Lua value to a string
-- containing a JSON representation of it.
function export.toJSON(this, opts)
	return converter(this, opts == nil and {} or opts, {}, 3)
end

return export
