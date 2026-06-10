local UnitTester = {}

local require = require
local concat = table.concat
local deep_equals = require("Module:table/deepEquals")
local error = error
local explode_utf8 = require("Module:string utilities").explode_utf8
local find = string.find
local full_url = mw.uri.fullUrl
local gsub = string.gsub
local html = mw.html
local insert = table.insert
local ipairs = ipairs
local is_callable = require("Module:fun/isCallable")
local is_combining = require("Module:Unicode data").is_combining
local match = string.match
local nowiki = require("Module:string/nowiki")
local pairs = pairs
local shallow_copy = require("Module:table/shallowCopy")
local sort = table.sort
local sorted_pairs = require("Module:table/sortedPairs")
local sub = string.sub
local tostring = tostring
local traceback = debug.traceback
local type = type
local umatch = mw.ustring.find
local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local usub = mw.ustring.sub
local xpcall = require("Module:fun/xpcall")

-- DO NOT replace with mw.loadData("Module:headword/data").pagename as we need the root portion
local current_title = mw.title.getCurrentTitle()

local tick, cross =
	'[[File:Yes check.svg|20px|alt=Passed|link=|Test passed]]',
	'[[File:X mark.svg|20px|alt=Failed|link=|Test failed]]'

local function first_difference(s1, s2)
	if not (type(s1) == "string" and type(s2) == "string") then
		return "N/A"
	elseif s1 == s2 then
		return ""
	end
	
	s1 = explode_utf8(s1)
	s2 = explode_utf8(s2)
	
	local i = 0
	repeat
		i = i + 1
	until s1[i] ~= s2[i]
	
	return i
end

local function highlight(str)
	if umatch(str, "%s") then
		return '<span style="background-color: var(--wikt-palette-red-4,pink);">' ..
			gsub(str, " ", "&nbsp;") .. '</span>'
	else
		return '<span style="color: var(--wikt-palette-red-9, red);">' ..
			str .. '</span>'
	end
end

local function find_noncombining(str, i, incr)
	while true do
		local ch = usub(str, i, i)
		if ch == "" or not is_combining(ch) then
			return i
		end
		i = i + incr
	end
end

-- Highlight character where a difference was found. Start highlight at first
-- non-combining character before the position. End it after the first non-
-- combining characters after the position. Can specify a custom highlighing
-- function.
local function highlight_difference(actual, expected, differs_at, func)
	if type(differs_at) ~= "number" or not (actual and expected) then
		return actual
	end
	differs_at = find_noncombining(expected, differs_at, -1)
	local i = find_noncombining(actual, differs_at, -1)
	local j = find_noncombining(actual, differs_at + 1, 1)
	j = j - 1
	return usub(actual, 1, i - 1) ..
		(is_callable(func) and func or highlight)(usub(actual, i, j)) ..
		usub(actual, j + 1, -1)
end

local function val_to_str(v)
	if type(v) == "string" then
		v = gsub(v, '\n', '\\n')
		if find(gsub(v, '[^\'"]', ''), '^"+$') then
			return "'" .. v .. "'"
		end
		return '"' .. gsub(v, '"', '\\"' ) .. '"'
	elseif type(v) == 'table' then
		local result, done = {}, {}
		for k, val in ipairs(v) do
			insert(result, val_to_str(val))
			done[k] = true
		end
		for k, val in sorted_pairs(v) do
			if not done[k] then
				if (type(k) ~= "string") or not find(k, '^[_%a][_%a%d]*$') then
					k = '[' .. val_to_str(k) .. ']'
				end
				insert(result, k .. '=' .. val_to_str(val))
			end
		end
		return "{" .. concat(result, ", ") .. "}"
	else
		return tostring(v)
	end
end

local function insert_differences(keys, t1, t2)
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		if v2 == nil or not deep_equals(v1, v2, true) then
			insert(keys, k)
		end
	end
end

local function get_differing_keys(t1, t2)
	local ty1 = type(t1)
	if not (ty1 == type(t2) and ty1 == "table") then
		return nil
	end
	
	local keys = {}
	insert_differences(keys, t1, t2)
	insert_differences(keys, t2, t1)

	return keys
end

local function extract_keys(t, keys)
	if not keys then
		return t
	end
	local new_t = {}
	for _, key in ipairs(keys) do
		new_t[key] = t[key]
	end
	return new_t
end

-- Return the header for the result table along with the number of columns in the table.
function UnitTester:new_result_table()
	local header_row = html.create("tr")
		:tag("th")
			:attr("class", "unit-tests-img-corner")
			:css("cursor", "pointer")
			:attr("title", "Only failed tests")
			:done()
	
	local columns = shallow_copy(self.name_columns)
	insert(columns, "Expected")
	insert(columns, "Actual")
	
	if self.differs_at then
		insert(columns, "Differs at")
	end
	
	if self.comments then
		insert(columns, "Comments")
	end
	
	for _, cell in ipairs(columns) do
		header_row = header_row:tag("th")
			:wikitext(cell)
			:done()
	end
	
	self.columns = #columns + 1
	
	return html.create("table")
		:attr("class", "unit-tests wikitable")
		:node(header_row)
end

function UnitTester:get_result(key)
	return self[key](self)
end

function UnitTester:display_difference(success, name, actual, expected, options)
	local differs_at = self.differs_at and first_difference(expected, actual)
	local comment = self.comments and (options and options.comment or "")
	
	expected = expected == nil and "(nil)" or tostring(expected)
	actual   = actual == nil and "(nil)" or tostring(actual)
	
	if self.nowiki or options and options.nowiki then
		expected = nowiki(expected)
		actual = nowiki(actual)
	end
	
	if options and is_callable(options.display) then
		expected = options.display(expected)
		actual = options.display(actual)
	end
	
	local cells
	if type(name) == "table" then
		cells = shallow_copy(name)
		insert(cells, expected)
		insert(cells, actual)
		insert(cells, differs_at)
	else
		cells = {
			name,
			expected,
			actual,
			differs_at
		}
	end
	insert(cells, comment) -- In case differs_at is nil.
	
	local row = html.create("tr")
	
	if success then
		row = row:attr("class", "unit-test-pass")
		insert(cells, 1, tick)
	else
		row = row:attr("class", "unit-test-fail")
		insert(cells, 1, cross)
		self.num_failures = self.num_failures + 1
	end
	
	for _, cell in ipairs(cells) do
		row = row:tag("td")
			:wikitext(cell)
			:done()
	end
	
	self.result_table = self.result_table:node(row)
	
	self.total_tests = self.total_tests + 1
end

function UnitTester:equals(name, actual, expected, options)
	local success = actual == expected
	if options and options.show_difference then
		local difference = first_difference(expected, actual)
		if type(difference) == "number" then
			actual = highlight_difference(actual, expected, difference,
				is_callable(options.show_difference) and options.show_difference)
		end
	end
	self:display_difference(success, name, actual, expected, options)
end

function UnitTester:preprocess_equals(text, expected, options)
	local actual = self.frame:preprocess(text)
	self:equals(nowiki(text), actual, expected, options)
end

function UnitTester:preprocess_equals_many(prefix, suffix, cases, options)
	for _, case in ipairs(cases) do
		self:preprocess_equals(prefix .. case[1] .. suffix, case[2], options)
	end
end

function UnitTester:preprocess_equals_preprocess(text1, text2, options)
	local expected = self.frame:preprocess(text2)
	self:preprocess_equals(text1, expected, options)
end

function UnitTester:preprocess_equals_preprocess_many(prefix1, suffix1, prefix2, suffix2, cases, options)
	for _, case in ipairs(cases) do
		self:preprocess_equals_preprocess(prefix1 .. case[1] .. suffix1, prefix2 .. (case[2] and case[2] or case[1]) .. suffix2, options)
	end
end

function UnitTester:equals_deep(name, actual, expected, options)
	local actual_str, expected_str
	local success = deep_equals(actual, expected, true)
	if success then
		if options and options.show_table_difference then
			actual_str = ''
			expected_str = ''
		end
	else
		if options and options.show_table_difference then
			local keys = get_differing_keys(actual, expected)
			actual_str = val_to_str(extract_keys(actual, keys))
			expected_str = val_to_str(extract_keys(expected, keys))
		end
	end
	if (not options) or not options.show_table_difference then
		actual_str = val_to_str(actual)
		expected_str = val_to_str(expected)
	end

	self:display_difference(success, name, actual_str, expected_str, options)
end

function UnitTester:iterate(examples, func)
	require 'libraryUtil'.checkType('iterate', 1, examples, 'table')
	if type(func) == "string" then
		func = self[func]
	elseif not is_callable(func) then
		error(("bad argument #2 to 'iterate' (expected function, callable table or string; got %s)")
			:format(type(func)), 2)
	end
	
	for i, example in ipairs(examples) do
		if type(example) == 'table' then
			func(self, unpack(example))
		elseif type(example) == 'string' then
			self:header(example)
		else
			error(('bad example #%d (expected table or string, got %s)')
				:format(i, type(example)), 2)
		end
	end
end

function UnitTester:header(text)
	local prefix, maintext = match(text, '^#(h[0-9]+):(.*)$')
	if not prefix then
		maintext = text
	end
	
	local header = html.create("th")
		:attr("colspan", self.columns)
	
	if prefix == "h1" then
		header = header:css("text-align", "center")
			:css("font-size", "150%")
	else
		header = header:css("text-align", "left")
	end
	
	header = header:wikitext(maintext)
	
	self.result_table = self.result_table:tag("tr")
		:node(header)
		:done()
end

local function err_handler(mesg)
	return {mesg = mesg, traceback = traceback("", 2)}
end

function UnitTester:run(frame)
	self.num_failures = 0
	
	local output = {}

	local boolean = {type = "boolean"}
	local iargs = require("Module:parameters").process(frame.args, {
		["nowiki"] = boolean,
		["differs_at"] = boolean,
		["comments"] = boolean,
		["summarize"] = boolean,
		["name_column"] = {list = true, default = "Text"},
	})

	self.frame = frame
	self.nowiki = iargs.nowiki
	self.differs_at = iargs.differs_at
	self.comments = iargs.comments
	self.summarize = iargs.summarize
	self.name_columns = iargs.name_column
	self.total_tests = 0

	-- Sort results into alphabetical order.
	local self_sorted = {}
	for key in pairs(self) do
		if sub(key, 1, 4) == "test" then
			insert(self_sorted, key)
		end
	end
	sort(self_sorted)
	
	-- Add results to the results table.
	for _, key in ipairs(self_sorted) do
		self.result_table = self:new_result_table()
			:tag("caption")
				:css("text-align", "left")
				:css("font-weight", "bold")
				:wikitext(key .. ":")
				:done()
		local success, err = xpcall(UnitTester.get_result, err_handler, self, key)
		if not success then
			self.result_table = self.result_table:tag("tr")
				:tag("td")
					:attr("colspan", self.columns)
					:css("text-align", "left")
					:tag("strong")
						:attr("class", "error")
						:wikitext("Script error during testing: " .. nowiki(err.mesg))
						:done()
					:wikitext(frame:extensionTag("pre", err.traceback or "(no traceback)"))
					:allDone()
			self.num_failures = self.num_failures + 1
		end
		insert(output, tostring(self.result_table))
	end

	local refresh_link = tostring(full_url(current_title.fullText, 'action=purge&forcelinkupdate=1'))

	local failure_cat = '[[Category:Failing testcase modules]]'
	if sub(current_title.text, -14) == "/documentation" then
		failure_cat = ''
	end
	
	local num_successes = self.total_tests - self.num_failures
	
	if self.summarize then
		if self.num_failures == 0 then
			return '<strong class="success">' .. self.total_tests .. '/' .. self.total_tests .. ' tests passed</strong>'
		else
			return '<strong class="error">' .. num_successes .. '/' .. self.total_tests .. ' tests passed</strong>'
		end
	else
		return (self.num_failures == 0 and '<strong class="success">All tests passed.</strong>' or 
				'<strong class="error">' .. self.num_failures .. ' of ' .. self.total_tests .. ' test' .. (self.total_tests == 1 and '' or 's' ) .. ' failed.</strong>' .. failure_cat) ..
			" <span class='plainlinks unit-tests-refresh'>[" .. refresh_link .. " (refresh)]</span>\n\n" ..
			concat(output, "\n\n")
	end
end

function UnitTester:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

local unit_tester = UnitTester:new()

function unit_tester.run_tests(frame)
	return unit_tester:run(frame)
end

return unit_tester
