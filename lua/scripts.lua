local export = {}

local combining_classes_module = "Module:Unicode data/combining classes"
local debug_track_module = "Module:debug/track"
local json_module = "Module:JSON"
local language_like_module = "Module:language-like"
local load_module = "Module:load"
local scripts_canonical_names_module = "Module:scripts/canonical names"
local scripts_chartoscript_module = "Module:scripts/charToScript"
local scripts_data_module = "Module:scripts/data"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local writing_systems_module = "Module:writing systems"
local writing_systems_data_module = "Module:writing systems/data"

local concat = table.concat
local get_by_code -- Defined below.
local gmatch = string.gmatch
local insert = table.insert
local make_object -- Defined below.
local match = string.match
local require = require
local select = select
local setmetatable = setmetatable
local toNFC = mw.ustring.toNFC
local toNFD = mw.ustring.toNFD
local toNFKC = mw.ustring.toNFKC
local toNFKD = mw.ustring.toNFKD
local type = type

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
	local function category_name_has_suffix(...)
		category_name_has_suffix = require(language_like_module).categoryNameHasSuffix
		return category_name_has_suffix(...)
	end

	local function category_name_to_code(...)
		category_name_to_code = require(language_like_module).categoryNameToCode
		return category_name_to_code(...)
	end

	local function debug_track(...)
		debug_track = require(debug_track_module)
		return debug_track(...)
	end

	local function deep_copy(...)
		deep_copy = require(table_module).deepCopy
		return deep_copy(...)
	end

	local function explode(...)
		explode = require(string_utilities_module).explode_utf8
		return explode(...)
	end

	local function get_writing_system(...)
		get_writing_system = require(writing_systems_module).getByCode
		return get_writing_system(...)
	end

	local function keys_to_list(...)
		keys_to_list = require(table_module).keysToList
		return keys_to_list(...)
	end

	local function load_data(...)
		load_data = require(load_module).load_data
		return load_data(...)
	end

	local function split(...)
		split = require(string_utilities_module).split
		return split(...)
	end

	local function to_json(...)
		to_json = require(json_module).toJSON
		return to_json(...)
	end

	local function track(page)
		debug_track("scripts/" .. page)
		return true
	end

	local function ugsub(...)
		ugsub = require(string_utilities_module).gsub
		return ugsub(...)
	end

	local function umatch(...)
		umatch = require(string_utilities_module).match
		return umatch(...)
	end

--[==[
Loaders for objects, which load data (or some other object) into some variable, which can then be accessed as "foo or get_foo()", where the function get_foo sets the object to "foo" and then returns it. This ensures they are only loaded when needed, and avoids the need to check for the existence of the object each time, since once "foo" has been set, "get_foo" will not be called again.]==]
	local scripts_canonical_names
	local function get_scripts_canonical_names()
		scripts_canonical_names, get_scripts_canonical_names = load_data(scripts_canonical_names_module), nil
		return scripts_canonical_names
	end

	local scripts_data
	local function get_scripts_data()
		scripts_data, get_scripts_data = load_data(scripts_data_module), nil
		return scripts_data
	end

	local scripts_suffixes
	local function get_scripts_suffixes()
		scripts_suffixes, get_scripts_suffixes = {
			"script",
			"code",
			"notation",
			"letters",
			"numerals",
			"semaphore",
		}, nil
		for _, v in pairs(load_data(writing_systems_data_module)) do
			insert(scripts_suffixes, v[1])
		end
		return scripts_suffixes
	end

local Script = {}
Script.__index = Script

--[==[Returns the script code of the script. Example: {{lua|"Cyrl"}} for Cyrillic.]==]
function Script:getCode()
	return self._code
end

--[==[Returns the canonical name of the script. This is the name used to represent that script on Wiktionary. Example: {{lua|"Cyrillic"}} for Cyrillic.]==]
function Script:getCanonicalName()
	return self._data[1]
end

--[==[Returns the display form of the script. For scripts, this is the same as the value returned by <code>:getCategoryName("nocap")</code>, i.e. it reads "NAME script" (e.g. {{lua|"Arabic script"}}). The displayed text used in <code>:makeCategoryLink</code> is always the same as the display form.]==]
function Script:getDisplayForm()
	return self:getCategoryName("nocap")
end

function Script:getAliases()
	Script.getAliases = require(language_like_module).getAliases
	return self:getAliases()
end

function Script:getVarieties(flatten)
	Script.getVarieties = require(language_like_module).getVarieties
	return self:getVarieties(flatten)
end

function Script:getOtherNames()
	Script.getOtherNames = require(language_like_module).getOtherNames
	return self:getOtherNames()
end

function Script:getAllNames()
	Script.getAllNames = require(language_like_module).getAllNames
	return self:getAllNames()
end

--[==[Returns the {{w|IETF language tag#Syntax of language tags|IETF subtag}} used for the script, which should always be a valid {{w|ISO 15924}} script code. This is used when constructing HTML {{code|html|lang{{=}}}} tags. The {{lua|ietf_subtag}} value from the script's data file is used, if present; otherwise, the script code is used. For script codes which contain a hyphen, only the part after the hyphen is used (e.g. {{lua|"fa-Arab"}} becomes {{lua|"Arab"}}).]==]
function Script:getIETFSubtag()
	local code = self._ietf_subtag
	if code == nil then
		code = self._data.ietf_subtag or match(self:getCode(), "[^%-]+$")
		self._ietf_subtag = code
	end
	return code
end

--[==[Returns a script object for the parent of the script, such as {"Arab"} for {"fa-Arab"}. It returns {nil} for scripts without a parent, like {"Latn"}, {"Grek"}, etc.]==]
function Script:getParent()
	local parent = self._parentObject
	if parent == nil then
		parent = self:getParentCode()
		-- If the value is nil, it's cached as false.
		parent = parent and get_by_code(parent) or false
		self._parentObject = parent
	end
	return parent or nil
end

--[==[Returns the script code of the parent of the script, such as {"Arab"} for {"fa-Arab"}. It returns {nil} for scripts without a parent, like {"Latn"}, {"Grek"}, etc.]==]
function Script:getParentCode()
	local parent = self._parentCode
	if parent == nil then
		-- If the value is nil, it's cached as false.
		parent = self._data.parent or false
		self._parentCode = parent
	end
	return parent or nil
end

function Script:getSystemCodes()
	if not self._systemCodes then
		local system_codes = self._data[3]
		if type(system_codes) == "table" then
			self._systemCodes = system_codes
		elseif type(system_codes) == "string" then
			self._systemCodes = split(system_codes, ",", true, true)
		else
			self._systemCodes = {}
		end
	end
	return self._systemCodes
end

function Script:getSystems()
	if not self._systemObjects then
		self._systemObjects = {}
		for _, system in ipairs(self:getSystemCodes()) do
			insert(self._systemObjects, get_writing_system(system))
		end
	end
	return self._systemObjects
end

--[==[Check whether the script is of type `system`, which can be a writing system code or object. If multiple systems are passed, return true if the script is any of the specified systems.]==]
function Script:isSystem(...)
	for _, system in ipairs{...} do
		if type(system) == "table" then
			system = system:getCode()
		end
		for _, s in ipairs(self:getSystemCodes()) do
			if system == s then
				return true
			end
		end
	end
	return false
end

--[==[Returns a table of types as a lookup table (with the types as keys).

Currently, the only possible type is {script}.]==]
function Script:getTypes()
	local types = self._types
	if types == nil then
		types = {script = true}
		local rawtypes = self._data.type
		if rawtypes then
			for t in gmatch(rawtypes, "[^,]+") do
				types[t] = true
			end
		end
		self._types = types
	end
	return types
end

--[==[Given a list of types as strings, returns true if the script has all of them.

Use {{lua|hasType("script")}} to determine if an object that may be a language, family or script is a script.]==]	
function Script:hasType(...)
	Script.hasType = require(language_like_module).hasType
	return self:hasType(...)
end

--[==[Returns the name of the main category of that script. Example: {{lua|"Cyrillic script"}} for Cyrillic, whose category is at [[:Category:Cyrillic script]].
Unless optional argument <code>nocap</code> is given, the script name at the beginning of the returned value will be capitalized. This capitalization is correct for category names, but not if the script name is lowercase and the returned value of this function is used in the middle of a sentence. (For example, the script with the code <code>Semap</code> has the name <code>"flag semaphore"</code>, which should remain lowercase when used as part of the category name [[:Category:Translingual letters in flag semaphore]] but should be capitalized in [[:Category:Flag semaphore templates]].) If you are considering using <code>getCategoryName("nocap")</code>, use <code>getDisplayForm()</code> instead.]==]
function Script:getCategoryName(nocap)
	local name = self:getCanonicalName()
	if category_name_has_suffix(name, scripts_suffixes or get_scripts_suffixes()) then
		name = name .. " script"
	end
	if not nocap then
		name = mw.getContentLanguage():ucfirst(name)
	end
	return name
end

function Script:makeCategoryLink()
	return "[[:Category:" .. self:getCategoryName() .. "|" .. self:getDisplayForm() .. "]]"
end

--[==[Returns the Wikidata item id for the script or <code>nil</code>. This corresponds to the the second field in the data modules.]==]
function Script:getWikidataItem()
	Script.getWikidataItem = require(language_like_module).getWikidataItem
	return self:getWikidataItem()
end

--[==[
Returns the name of the Wikipedia article for the script. `project` specifies the language and project to retrieve
the article from, defaulting to {"enwiki"} for the English Wikipedia. Normally if specified it should be the project
code for a specific-language Wikipedia e.g. "zhwiki" for the Chinese Wikipedia, but it can be any project, including
non-Wikipedia ones. If the project is the English Wikipedia and the property {wikipedia_article} is present in the data
module it will be used first. In all other cases, a sitelink will be generated from {:getWikidataItem} (if set). The
resulting value (or lack of value) is cached so that subsequent calls are fast. If no value could be determined, and
`noCategoryFallback` is {false}, {:getCategoryName} is used as fallback; otherwise, {nil} is returned. Note that if
`noCategoryFallback` is {nil} or omitted, it defaults to {false} if the project is the English Wikipedia, otherwise
to {true}. In other words, under normal circumstances, if the English Wikipedia article couldn't be retrieved, the
return value will fall back to a link to the script's category, but this won't normally happen for any other project.
]==]
function Script:getWikipediaArticle(noCategoryFallback, project)
	Script.getWikipediaArticle = require(language_like_module).getWikipediaArticle
	return self:getWikipediaArticle(noCategoryFallback, project)
end

--[==[Returns the name of the Wikimedia Commons category page for the script.]==]
function Script:getCommonsCategory()
	Script.getCommonsCategory = require(language_like_module).getCommonsCategory
	return self:getCommonsCategory()
end

--[==[Returns the charset defining the script's characters from the script's data file.
This can be used to search for words consisting only of this script, but see the warning above.]==]
function Script:getCharacters()
	return self.characters or nil
end

--[==[Returns the number of characters in the text that are part of this script.
'''Note:''' You should never assume that text consists entirely of the same script. Strings may contain spaces, punctuation and even wiki markup or HTML tags. HTML tags will skew the counts, as they contain Latin-script characters. So it's best to avoid them.]==]
function Script:countCharacters(text)
	local charset = self._data.characters
	if charset == nil then
		return 0
	end
	return select(2, ugsub(text, "[" .. charset .. "]", ""))
end

function Script:hasCapitalization()
	return not not self._data.capitalized
end

function Script:hasSpaces()
	return self._data.spaces ~= false
end

function Script:isTransliterated()
	return self._data.translit ~= false
end

--[==[Returns true if the script is (sometimes) sorted by scraping page content, meaning that it is sensitive to changes in capitalization during sorting.]==]
function Script:sortByScraping()
	return not not self._data.sort_by_scraping
end

--[==[Returns the text direction. Horizontal scripts return {{lua|"ltr"}} (left-to-right) or {{lua|"rtl"}} (right-to-left), while vertical scripts return {{lua|"vertical-ltr"}} (vertical left-to-right) or {{lua|"vertical-rtl"}} (vertical right-to-left).]==]
function Script:getDirection()
	return self._data.direction or "ltr"
end

function Script:getData()
	return self._data
end

--[==[Returns the name of the module containing the script's data. Currently, this is always [[Module:scripts/data]].]==]
function Script:getDataModuleName()
	return scripts_data_module
end

--[==[Returns {{lua|true}} if the script contains characters that require fixes to Unicode normalization under certain circumstances, {{lua|false}} if it doesn't.]==]
function Script:hasNormalizationFixes()
	return not not self._data.normalizationFixes
end

--[==[Corrects discouraged sequences of Unicode characters to the encouraged equivalents.]==]
function Script:fixDiscouragedSequences(text)
	if self:hasNormalizationFixes() then
		local norm_fixes = self._data.normalizationFixes
		local to = norm_fixes.to
		if to then
			for i, v in ipairs(norm_fixes.from) do
				text = ugsub(text, v, to[i] or "")
			end
		end
	end
	return text
end

do
	local combining_classes
	
	-- Obtain the list of default combining classes.
	local function get_combining_classes()
		combining_classes, get_combining_classes = load_data(combining_classes_module), nil
		return combining_classes
	end
	
	-- Implements a modified form of Unicode normalization for instances where there are identified deficiencies in the default Unicode combining classes.
	local function fixNormalization(text, self)
		if not self:hasNormalizationFixes() then
			return text
		end
		local norm_fixes = self._data.normalizationFixes
		local new_classes = norm_fixes.combiningClasses
		if not (new_classes and umatch(text, "[" .. norm_fixes.combiningClassCharacters .. "]")) then
			return text
		end
		text = explode(text)
		-- Manual sort based on new combining classes.
		-- We can't use table.sort, as it compares the first/last values in an array as a shortcut, which messes things up.
		for i = 2, #text do
			local char = text[i]
			local class = new_classes[char] or (combining_classes or get_combining_classes())[char]
			if class then
				repeat
					i = i - 1
					local prev = text[i]
					if (new_classes[prev] or (combining_classes or get_combining_classes())[prev] or 0) < class then
						break
					end
					text[i], text[i + 1] = char, prev
				until i == 1
			end
		end
		return concat(text)
	end
	
	function Script:toFixedNFC(text)
		return fixNormalization(toNFC(text), self)
	end
	
	function Script:toFixedNFD(text)
		return fixNormalization(toNFD(text), self)
	end
	
	function Script:toFixedNFKC(text)
		return fixNormalization(toNFKC(text), self)
	end
	
	function Script:toFixedNFKD(text)
		return fixNormalization(toNFKD(text), self)
	end
end

function Script:toJSON(opts)
	local ret = {
		canonicalName = self:getCanonicalName(),
		categoryName = self:getCategoryName("nocap"),
		code = self:getCode(),
		parent = self:getParentCode(),
		systems = self:getSystemCodes(),
		aliases = self:getAliases(),
		varieties = self:getVarieties(),
		otherNames = self:getOtherNames(),
		type = keys_to_list(self:getTypes()),
		direction = self:getDirection(),
		characters = self:getCharacters(),
		ietfSubtag = self:getIETFSubtag(),
		wikidataItem = self:getWikidataItem(),
		wikipediaArticle = self:getWikipediaArticle(true),
	}
	-- Use `deep_copy` when returning a table, so that there are no editing restrictions imposed by `mw.loadData`.
	return opts and opts.lua_table and deep_copy(ret) or to_json(ret, opts)
end

function export.makeObject(code, data)
	local data_type = type(data)
	if data_type ~= "table" then
		error(("bad argument #2 to 'makeObject' (table expected, got %s)"):format(data_type))
	end
	return setmetatable({_data = data, _code = code, characters = data.characters}, Script)
end
make_object = export.makeObject

local scripts_to_track = {
	["fa-Arab"] = true,
	["kk-Arab"] = true,
	["ks-Arab"] = true,
	["ku-Arab"] = true,
	["ms-Arab"] = true,
	["mzn-Arab"] = true,
	["ota-Arab"] = true,
	["pa-Arab"] = true,
	["ps-Arab"] = true,
	["sd-Arab"] = true,
	["tt-Arab"] = true,
	["ug-Arab"] = true,
	["ur-Arab"] = true,
}

--[==[
Finds the script whose code matches the one provided. If it exists, it returns a {Script} object representing the
script. Otherwise, it returns {nil}.]==]
function export.getByCode(code)
	if scripts_to_track[code] then
		track(code)
	end
	local data = (scripts_data or get_scripts_data())[code]
	return data ~= nil and make_object(code, data) or nil
end
get_by_code = export.getByCode

--[==[
Look for the script whose canonical name (the name used to represent that script on Wiktionary) matches the one
provided. If it exists, it returns a {Script} object representing the script. Otherwise, it returns {nil}. The
canonical name of scripts should always be unique (it is an error for two scripts on Wiktionary to share the same
canonical name), so this is guaranteed to give at most one result.]==]
function export.getByCanonicalName(name)
	if name == nil then
		return nil
	end
	local code = (scripts_canonical_names or get_scripts_canonical_names())[name]
	if code == nil then
		return nil
	end
	return get_by_code(code)
end

--[==[
Look for the script whose category name (the name used in categories for that script) matches the one provided.
If it exists, it returns a {Script} object representing the script. Otherwise, it returns {nil}. In almost all cases,
the category name for a script is its canonical name plus the word "script", e.g. "Cyrillic" has the category name
"Cyrillic script". Where a canonical name ends with "script", "code" or "semaphore", the category name is identical
to the canonical name.]==]
function export.getByCategoryName(name)
	if name == nil then
		return nil
	end
	local code = category_name_to_code(
		name,
		" script",
		scripts_canonical_names or get_scripts_canonical_names(),
		scripts_suffixes or get_scripts_suffixes()
	)
	if code == nil then
		return nil
	end
	return get_by_code(code)
end

--[==[
	Takes a codepoint or a character and finds the script code (if any) that is
	appropriate for it based on the codepoint, using the data module
	[[Module:scripts/recognition data]]. The data module was generated from the
	patterns in [[Module:scripts/data]] using [[Module:User:Erutuon/script recognition]].

	Converts the character to a codepoint. Returns a script code if the codepoint
	is in the list of individual characters, or if it is in one of the defined
	ranges in the 4096-character block that it belongs to, else returns "None".
]==]
function export.charToScript(char)
	export.charToScript = require(scripts_chartoscript_module).charToScript
	return export.charToScript(char)
end

--[==[
Returns the code for the script that has the greatest number of characters in `text`. Useful for script tagging text
that is unspecified for language. Uses [[Module:scripts/recognition data]] to determine a script code for a character
language-agnostically. Specifically, it works as follows:
	
Convert each character to a codepoint. Increment the counter for the script code if the codepoint is in the list
of individual characters, or if it is in one of the defined ranges in the 4096-character block that it belongs to.
	
Each script has a two-part counter, for primary and secondary matches. Primary matches are when the script is the
first one listed; otherwise, it's a secondary match. When comparing scripts, first the total of both are compared
(i.e. the overall number of matches). If these are the same, the number of primary and then secondary matches are
used as tiebreakers. For example, this is used to ensure that `Grek` takes priority over `Polyt` if no characters
which exclusively match `Polyt` are found, as `Grek` is a subset of `Polyt`.
	
If `none_is_last_resort_only` is specified, this will never return {"None"} if any characters in `text` belong to a
script. Otherwise, it will return {"None"} if there are more characters that don't belong to a script than belong to
any individual script. (FIXME: This behavior is probably wrong, and `none_is_last_resort_only` should probably
become the default.)
]==]
function export.findBestScriptWithoutLang(text, none_is_last_resort_only)
	export.findBestScriptWithoutLang = require(scripts_chartoscript_module).findBestScriptWithoutLang
	return export.findBestScriptWithoutLang(text, none_is_last_resort_only)
end

return export
