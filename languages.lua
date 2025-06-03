--[=[
This module implements fetching of language-specific information and processing text in a given language.

There are two types of languages: full languages and etymology-only languages. The essential difference is that only
full languages appear in L2 headings in vocabulary entries, and hence categories like [[:Category:French nouns]] exist
only for full languages. Etymology-only languages have either a full language or another etymology-only language as
their parent (in the parent-child inheritance sense), and for etymology-only languages with another etymology-only
language as their parent, a full language can always be derived by following the parent links upwards. For example,
"Canadian French", code 'fr-CA', is an etymology-only language whose parent is the full language "French", code 'fr'.
An example of an etymology-only language with another etymology-only parent is "Northumbrian Old English", code
'ang-nor', which has "Anglian Old English", code 'ang-ang' as its parent; this is an etymology-only language whose
parent is "Old English", code "ang", which is a full language. (This is because Northumbrian Old English is considered
a variety of Anglian Old English.) Sometimes the parent is the "Undetermined" language, code 'und'; this is the case,
for example, for "substrate" languages such as "Pre-Greek", code 'qsb-grc', and "the BMAC substrate", code 'qsb-bma'.

It is important to distinguish language ''parents'' from language ''ancestors''. The parent-child relationship is one
of containment, i.e. if X is a child of Y, X is considered a variety of Y. On the other hand, the ancestor-descendant
relationship is one of descent in time. For example, "Classical Latin", code 'la-cla', and "Late Latin", code 'la-lat',
are both etymology-only languages with "Latin", code 'la', as their parents, because both of the former are varieties
of Latin. However, Late Latin does *NOT* have Classical Latin as its parent because Late Latin is *not* a variety of
Classical Latin; rather, it is a descendant. There is in fact a separate 'ancestors' field that is used to express the
ancestor-descendant relationship, and Late Latin's ancestor is given as Classical Latin. It is also important to note
that sometimes an etymology-only language is actually the conceptual ancestor of its parent language. This happens,
for example, with "Old Italian" (code 'roa-oit'), which is an etymology-only variant of full language "Italian" (code
'it'), and with "Old Latin" (code 'itc-ola'), which is an etymology-only variant of Latin. In both cases, the full
language has the etymology-only variant listed as an ancestor. This allows a Latin term to inherit from Old Latin
using the {{tl|inh}} template (where in this template, "inheritance" refers to ancestral inheritance, i.e. inheritance
in time, rather than in the parent-child sense); likewise for Italian and Old Italian.

Full languages come in three subtypes:
* {regular}: This indicates a full language that is attested according to [[WT:CFI]] and therefore permitted in the
			main namespace. There may also be reconstructed terms for the language, which are placed in the
			{Reconstruction} namespace and must be prefixed with * to indicate a reconstruction. Most full languages
			are natural (not constructed) languages, but a few constructed languages (e.g. Esperanto and Volapük,
			among others) are also allowed in the mainspace and considered regular languages.
* {reconstructed}: This language is not attested according to [[WT:CFI]], and therefore is allowed only in the
				{Reconstruction} namespace. All terms in this language are reconstructed, and must be prefixed with
				*. Languages such as Proto-Indo-European and Proto-Germanic are in this category.
* {appendix-constructed}: This language is attested but does not meet the additional requirements set out for
						constructed languages ([[WT:CFI#Constructed languages]]). Its entries must therefore be in
						the Appendix namespace, but they are not reconstructed and therefore should not have *
						prefixed in links. Most constructed languages are of this subtype.

Both full languages and etymology-only languages have a {Language} object associated with them, which is fetched using
the {getByCode} function in [[Module:languages]] to convert a language code to a {Language} object. Depending on the
options supplied to this function, etymology-only languages may or may not be accepted, and family codes may be
accepted (returning a {Family} object as described in [[Module:families]]). There are also separate {getByCanonicalName}
functions in [[Module:languages]] and [[Module:etymology languages]] to convert a language's canonical name to a
{Language} object (depending on whether the canonical name refers to a full or etymology-only language).

Textual strings belonging to a given language come in several different ''text variants'':
# The ''input text'' is what the user supplies in wikitext, in the parameters to {{tl|m}}, {{tl|l}}, {{tl|ux}},
{{tl|t}}, {{tl|lang}} and the like.
# The ''display text'' is the text in the form as it will be displayed to the user. This can include accent marks that
are stripped to form the entry text (see below), as well as embedded bracketed links that are variously processed
further. The display text is generated from the input text by applying language-specific transformations; for most
languages, there will be no such transformations. Examples of transformations are bad-character replacements for
certain languages (e.g. replacing 'l' or '1' to [[palochka]] in certain languages in Cyrillic); and for Thai and
Khmer, converting space-separated words to bracketed words and resolving respelling substitutions such as [กรีน/กฺรีน],
which indicate how to transliterate given words.
# The ''entry text'' is the text in the form used to generate a link to a Wiktionary entry. This is usually generated
from the display text by stripping certain sorts of diacritics on a per-language basis, and sometimes doing other
transformations. The concept of ''entry text'' only really makes sense for text that does not contain embedded links,
meaning that display text containing embedded links will need to have the links individually processed to get
per-link entry text in order to generate the resolved display text (see below).
# The ''resolved display text'' is the result of resolving embedded links in the display text (e.g. converting them to
two-part links where the first part has entry-text transformations applied, and adding appropriate language-specific
fragments) and adding appropriate language and script tagging. This text can be passed directly to MediaWiki for
display.
# The ''source translit text'' is the text as supplied to the language-specific {transliterate()} method. The form of
the source translit text may need to be language-specific, e.g Thai and Khmer will need the full unprocessed input
text, whereas other languages may need to work off the display text. [FIXME: It's still unclear to me how embedded
bracketed links are handled in the existing code.] In general, embedded links need to be removed (i.e. converted to
their "bare display" form by taking the right part of two-part links and removing double brackets), but when this
happens is unclear to me [FIXME]. Some languages have a chop-up-and-paste-together scheme that sends parts of the
text through the transliterate mechanism, and for others (those listed with "cont" in {substition} in
[[Module:languages/data]]) they receive the full input text, but preprocessed in certain ways. (The wisdom of this is
still unclear to me.)
# The ''transliterated text'' (or ''transliteration'') is the result of transliterating the source translit text.
Unlike for all the other text variants except the transcribed text, it is always in the Latin script.
# The ''transcribed text'' (or ''transcription'') is the result of transcribing the source translit text, where
"transcription" here means a close approximation to the phonetic form of the language in languages (e.g. Akkadian,
Sumerian, Ancient Egyptian, maybe Tibetan) that have a wide difference between the written letters and spoken form.
Unlike for all the other text variants other than the transliterated text, it is always in the Latin script.
Currently, the transcribed text is always supplied manually be the user; there is no such thing as a
{lua|transcribe()} method on language objects.
# The ''sort key'' is the text used in sort keys for determining the placing of pages in categories they belong to. The
sort key is generated from the pagename or a specified ''sort base'' by lowercasing, doing language-specific
transformations and then uppercasing the result. If the sort base is supplied and is generated from input text, it
needs to be converted to display text, have embedded links removed (i.e. resolving them to their right side if they
are two-part links) and have entry text transformations applied.
# There are other text variants that occur in usexes (specifically, there are normalized variants of several of the
above text variants), but we can skip them for now.

The following methods exist on {Language} objects to convert between different text variants:
# {makeDisplayText}: This converts input text to display text.
# {lua|makeEntryName}: This converts input or display text to entry text. [FIXME: This needs some rethinking. In
particular, {lua|makeEntryName} is sometimes called on display text (in some paths inside of [[Module:links]]) and
sometimes called on input text (in other paths inside of [[Module:links]], and usually from other modules). We need
to make sure we don't try to convert input text to display text twice, but at the same time we need to support
calling it directly on input text since so many modules do this. This means we need to add a parameter indicating
whether the passed-in text is input or display text; if that former, we call {lua|makeDisplayText} ourselves.]
# {lua|transliterate}: This appears to convert input text with embedded brackets removed into a transliteration.
[FIXME: This needs some rethinking. In particular, it calls {lua|processDisplayText} on its input, which won't work
for Thai and Khmer, so we may need language-specific flags indicating whether to pass the input text directly to the
language transliterate method. In addition, I'm not sure how embedded links are handled in the existing translit code;
a lot of callers remove the links themselves before calling {lua|transliterate()}, which I assume is wrong.]
# {lua|makeSortKey}: This converts entry text (?) to a sort key. [FIXME: Clarify this.]
]=]
local export = {}

local debug_track_module = "Module:debug/track"
local etymology_languages_data_module = "Module:etymology languages/data"
local families_module = "Module:families"
local json_module = "Module:JSON"
local language_like_module = "Module:language-like"
local languages_data_module = "Module:languages/data"
local languages_data_patterns_module = "Module:languages/data/patterns"
local links_data_module = "Module:links/data"
local load_module = "Module:load"
local scripts_module = "Module:scripts"
local scripts_data_module = "Module:scripts/data"
local string_encode_entities_module = "Module:string/encode entities"
local string_pattern_escape_module = "Module:string/patternEscape"
local string_replacement_escape_module = "Module:string/replacementEscape"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local utilities_module = "Module:utilities"
local wikimedia_languages_module = "Module:wikimedia languages"

local mw = mw
local string = string
local table = table

local char = string.char
local concat = table.concat
local find = string.find
local floor = math.floor
local get_by_code -- Defined below.
local get_data_module_name -- Defined below.
local get_extra_data_module_name -- Defined below.
local getmetatable = getmetatable
local gmatch = string.gmatch
local gsub = string.gsub
local insert = table.insert
local ipairs = ipairs
local is_known_language_tag = mw.language.isKnownLanguageTag
local make_object -- Defined below.
local match = string.match
local next = next
local pairs = pairs
local remove = table.remove
local require = require
local select = select
local setmetatable = setmetatable
local sub = string.sub
local type = type
local unstrip = mw.text.unstrip

-- Loaded as needed by findBestScript.
local Hans_chars
local Hant_chars

local function check_object(...)
	check_object = require(utilities_module).check_object
	return check_object(...)
end

local function debug_track(...)
	debug_track = require(debug_track_module)
	return debug_track(...)
end

local function decode_entities(...)
	decode_entities = require(string_utilities_module).decode_entities
	return decode_entities(...)
end

local function decode_uri(...)
	decode_uri = require(string_utilities_module).decode_uri
	return decode_uri(...)
end

local function deep_copy(...)
	deep_copy = require(table_module).deepCopy
	return deep_copy(...)
end

local function encode_entities(...)
	encode_entities = require(string_encode_entities_module)
	return encode_entities(...)
end

local function get_script(...)
	get_script = require(scripts_module).getByCode
	return get_script(...)
end

local function find_best_script_without_lang(...)
	find_best_script_without_lang = require(scripts_module).findBestScriptWithoutLang
	return find_best_script_without_lang(...)
end

local function get_family(...)
	get_family = require(families_module).getByCode
	return get_family(...)
end

local function get_plaintext(...)
	get_plaintext = require(utilities_module).get_plaintext
	return get_plaintext(...)
end

local function get_wikimedia_lang(...)
	get_wikimedia_lang = require(wikimedia_languages_module).getByCode
	return get_wikimedia_lang(...)
end

local function keys_to_list(...)
	keys_to_list = require(table_module).keysToList
	return keys_to_list(...)
end

local function list_to_set(...)
	list_to_set = require(table_module).listToSet
	return list_to_set(...)
end

local function load_data(...)
	load_data = require(load_module).load_data
	return load_data(...)
end

local function make_family_object(...)
	make_family_object = require(families_module).makeObject
	return make_family_object(...)
end

local function pattern_escape(...)
	pattern_escape = require(string_pattern_escape_module)
	return pattern_escape(...)
end

local function remove_duplicates(...)
	remove_duplicates = require(table_module).removeDuplicates
	return remove_duplicates(...)
end

local function replacement_escape(...)
	replacement_escape = require(string_replacement_escape_module)
	return replacement_escape(...)
end

local function safe_require(...)
	safe_require = require(load_module).safe_require
	return safe_require(...)
end

local function shallow_copy(...)
	shallow_copy = require(table_module).shallowCopy
	return shallow_copy(...)
end

local function split(...)
	split = require(string_utilities_module).split
	return split(...)
end

local function to_json(...)
	to_json = require(json_module).toJSON
	return to_json(...)
end

local function u(...)
	u = require(string_utilities_module).char
	return u(...)
end

local function ugsub(...)
	ugsub = require(string_utilities_module).gsub
	return ugsub(...)
end

local function ulen(...)
	ulen = require(string_utilities_module).len
	return ulen(...)
end

local function ulower(...)
	ulower = require(string_utilities_module).lower
	return ulower(...)
end

local function umatch(...)
	umatch = require(string_utilities_module).match
	return umatch(...)
end

local function uupper(...)
	uupper = require(string_utilities_module).upper
	return uupper(...)
end

local function track(page)
	debug_track("languages/" .. page)
	return true
end

local function normalize_code(code)
	return load_data(languages_data_module).aliases[code] or code
end

local function check_inputs(self, check, default, ...)
	local n = select("#", ...)
	if n == 0 then
		return false
	end
	local ret = check(self, (...))
	if ret ~= nil then
		return ret
	elseif n > 1 then
		local inputs = {...}
		for i = 2, n do
			ret = check(self, inputs[i])
			if ret ~= nil then
				return ret
			end
		end
	end
	return default
end

local function make_link(self, target, display)
	local prefix, main
	if self:getFamilyCode() == "qfa-sub" then
		prefix, main = display:match("^(the )(.*)")
		if not prefix then
			prefix, main = display:match("^(a )(.*)")
		end
	end
	return (prefix or "") .. "[[" .. target .. "|" .. (main or display) .. "]]"
end

-- Convert risky characters to HTML entities, which minimizes interference once returned (e.g. for "sms:a", "<!-- -->" etc.).
local function escape_risky_characters(text)
	-- Spacing characters in isolation generally need to be escaped in order to be properly processed by the MediaWiki software.
	if umatch(text, "^%s*$") then
		return encode_entities(text, text)
	end
	return encode_entities(text, "!#%&*+/:;<=>?@[\\]_{|}")
end

-- Temporarily convert various formatting characters to PUA to prevent them from being disrupted by the substitution process.
local function doTempSubstitutions(text, subbedChars, keepCarets, noTrim)
	-- Clone so that we don't insert any extra patterns into the table in package.loaded. For some reason, using require seems to keep memory use down; probably because the table is always cloned.
	local patterns = shallow_copy(require(languages_data_patterns_module))
	if keepCarets then
		insert(patterns, "((\\+)%^)")
		insert(patterns, "((%^))")
	end
	-- Ensure any whitespace at the beginning and end is temp substituted, to prevent it from being accidentally trimmed. We only want to trim any final spaces added during the substitution process (e.g. by a module), which means we only do this during the first round of temp substitutions.
	if not noTrim then
		insert(patterns, "^([\128-\191\244]*(%s+))")
		insert(patterns, "((%s+)[\128-\191\244]*)$")
	end
	-- Pre-substitution, of "[[" and "]]", which makes pattern matching more accurate.
	text = gsub(text, "%f[%[]%[%[", "\1")
		:gsub("%f[%]]%]%]", "\2")
	local i = #subbedChars
	for _, pattern in ipairs(patterns) do
		-- Patterns ending in \0 stand are for things like "[[" or "]]"), so the inserted PUA are treated as breaks between terms by modules that scrape info from pages.
		local term_divider
		pattern = gsub(pattern, "%z$", function(divider)
			term_divider = divider == "\0"
			return ""
		end)
		text = gsub(text, pattern, function(...)
			local m = {...}
			local m1New = m[1]
			for k = 2, #m do
				local n = i + k - 1
				subbedChars[n] = m[k]
				local byte2 = floor(n / 4096) % 64 + (term_divider and 128 or 136)
				local byte3 = floor(n / 64) % 64 + 128
				local byte4 = n % 64 + 128
				m1New = gsub(m1New, pattern_escape(m[k]), "\244" .. char(byte2) .. char(byte3) .. char(byte4), 1)
			end
			i = i + #m - 1
			return m1New
		end)
	end
	text = gsub(text, "\1", "%[%[")
		:gsub("\2", "%]%]")
	return text, subbedChars
end

-- Reinsert any formatting that was temporarily substituted.
local function undoTempSubstitutions(text, subbedChars)
	for i = 1, #subbedChars do
		local byte2 = floor(i / 4096) % 64 + 128
		local byte3 = floor(i / 64) % 64 + 128
		local byte4 = i % 64 + 128
		text = gsub(text, "\244[" .. char(byte2) .. char(byte2+8) .. "]" .. char(byte3) .. char(byte4), replacement_escape(subbedChars[i]))
	end
	text = gsub(text, "\1", "%[%[")
		:gsub("\2", "%]%]")
	return text
end

-- Check if the raw text is an unsupported title, and if so return that. Otherwise, remove HTML entities. We do the pre-conversion to avoid loading the unsupported title list unnecessarily.
local function checkNoEntities(self, text)
	local textNoEnc = decode_entities(text)
	if textNoEnc ~= text and load_data(links_data_module).unsupported_titles[text] then
		return text
	else
		return textNoEnc
	end
end

-- If no script object is provided (or if it's invalid or None), get one.
local function checkScript(text, self, sc)
	if not check_object("script", true, sc) or sc:getCode() == "None" then
		return self:findBestScript(text)
	end
	return sc
end

local function normalize(text, sc)
	text = sc:fixDiscouragedSequences(text)
	return sc:toFixedNFD(text)
end

local function doSubstitutions(self, text, sc, substitution_data, function_name, recursed)
	local fail, cats = nil, {}
	-- If there are language-specific substitutes given in the data module, use those.
	if type(substitution_data) == "table" then
		-- If a script is specified, run this function with the script-specific data before continuing.
		local sc_code = sc:getCode()
		if substitution_data[sc_code] then
			text, fail, cats = doSubstitutions(self, text, sc, substitution_data[sc_code], function_name, true)
		-- Hant, Hans and Hani are usually treated the same, so add a special case to avoid having to specify each one separately.
		elseif sc_code:match("^Han") and substitution_data.Hani then
			text, fail, cats = doSubstitutions(self, text, sc, substitution_data.Hani, function_name, true)
		-- Substitution data with key 1 in the outer table may be given as a fallback.
		elseif substitution_data[1] then
			text, fail, cats = doSubstitutions(self, text, sc, substitution_data[1], function_name, true)
		end
		-- Iterate over all strings in the "from" subtable, and gsub with the corresponding string in "to". We work with the NFD decomposed forms, as this simplifies many substitutions.
		if substitution_data.from then
			for i, from in ipairs(substitution_data.from) do
				-- Normalize each loop, to ensure multi-stage substitutions work correctly.
				text = sc:toFixedNFD(text)
				text = ugsub(text, sc:toFixedNFD(from), substitution_data.to[i] or "")
			end
		end

		if substitution_data.remove_diacritics then
			text = sc:toFixedNFD(text)
			-- Convert exceptions to PUA.
			local remove_exceptions, substitutes = substitution_data.remove_exceptions
			if remove_exceptions then
				substitutes = {}
				local i = 0
				for _, exception in ipairs(remove_exceptions) do
					exception = sc:toFixedNFD(exception)
					text = ugsub(text, exception, function(m)
						i = i + 1
						local subst = u(0x80000 + i)
						substitutes[subst] = m
						return subst
					end)
				end
			end
			-- Strip diacritics.
			text = ugsub(text, "[" .. substitution_data.remove_diacritics .. "]", "")
			-- Convert exceptions back.
			if remove_exceptions then
				text = text:gsub("\242[\128-\191]*", substitutes)
			end
		end
	elseif type(substitution_data) == "string" then
		-- If there is a dedicated function module, use that.
		local module = safe_require("Module:" .. substitution_data)
		if module then
			-- TODO: translit functions should take objects, not codes.
			-- TODO: translit functions should be called with form NFD.
			if function_name == "tr" then
				text, fail, cats = module[function_name](text, self._code, sc:getCode())
			else
				text, fail, cats = module[function_name](sc:toFixedNFD(text), self, sc)
			end
			-- TODO: get rid of the `fail` and `cats` return values.
			if fail ~= nil then
				track("fail")
				track("fail/" .. self._code)
			end
			if cats ~= nil then
				track("cats")
				track("cats/" .. self._code)
			end
		else
			error("Substitution data '" .. substitution_data .. "' does not match an existing module.")
		end
	end

	-- Don't normalize to NFC if this is the inner loop or if a module returned nil.
	if recursed or not text then
		return text, fail, cats
	end
	-- Fix any discouraged sequences created during the substitution process, and normalize into the final form.
	return sc:toFixedNFC(sc:fixDiscouragedSequences(text)), fail, cats
end

-- Split the text into sections, based on the presence of temporarily substituted formatting characters, then iterate over each one to apply substitutions. This avoids putting PUA characters through language-specific modules, which may be unequipped for them.
local function iterateSectionSubstitutions(self, text, sc, subbedChars, keepCarets, substitution_data, function_name)
	local fail, cats, sections = nil, {}
	-- See [[Module:languages/data]].
	if not find(text, "\244") or (load_data(languages_data_module).substitution[self._code] == "cont") then
		sections = {text}
	else
		sections = split(text, "\244[\128-\143][\128-\191]*", true)
	end
	for _, section in ipairs(sections) do
		-- Don't bother processing empty strings or whitespace (which may also not be handled well by dedicated modules).
		if gsub(section, "%s+", "") ~= "" then
			local sub, sub_fail, sub_cats = doSubstitutions(self, section, sc, substitution_data, function_name)
			-- Second round of temporary substitutions, in case any formatting was added by the main substitution process. However, don't do this if the section contains formatting already (as it would have had to have been escaped to reach this stage, and therefore should be given as raw text).
			if sub and subbedChars then
				local noSub
				for _, pattern in ipairs(require(languages_data_patterns_module)) do
					if match(section, pattern .. "%z?") then
						noSub = true
					end
				end
				if not noSub then
					sub, subbedChars = doTempSubstitutions(sub, subbedChars, keepCarets, true)
				end
			end
			if (not sub) or sub_fail then
				text = sub
				fail = sub_fail
				cats = sub_cats or {}
				break
			end
			text = sub and gsub(text, pattern_escape(section), replacement_escape(sub), 1) or text
			if type(sub_cats) == "table" then
				for _, cat in ipairs(sub_cats) do
					insert(cats, cat)
				end
			end
		end
	end

	-- Trim, unless there are only spacing characters, while ignoring any final formatting characters.
	text = text and text:gsub("^([\128-\191\244]*)%s+(%S)", "%1%2")
		:gsub("(%S)%s+([\128-\191\244]*)$", "%1%2")

	-- Remove duplicate categories.
	if #cats > 1 then
		cats = remove_duplicates(cats)
	end

	return text, fail, cats, subbedChars
end

-- Process carets (and any escapes). Default to simple removal, if no pattern/replacement is given.
local function processCarets(text, pattern, repl)
	local rep
	repeat
		text, rep = gsub(text, "\\\\(\\*^)", "\3%1")
	until rep == 0
	return text:gsub("\\^", "\4")
		:gsub(pattern or "%^", repl or "")
		:gsub("\3", "\\")
		:gsub("\4", "^")
end

-- Remove carets if they are used to capitalize parts of transliterations (unless they have been escaped).
local function removeCarets(text, sc)
	if not sc:hasCapitalization() and sc:isTransliterated() and text:find("^", 1, true) then
		return processCarets(text)
	else
		return text
	end
end

local Language = {}

--[==[Returns the language code of the language. Example: {{code|lua|"fr"}} for French.]==]
function Language:getCode()
	return self._code
end

--[==[Returns the canonical name of the language. This is the name used to represent that language on Wiktionary, and is guaranteed to be unique to that language alone. Example: {{code|lua|"French"}} for French.]==]
function Language:getCanonicalName()
	local name = self._name
	if name == nil then
		name = self._data[1]
		self._name = name
	end
	return name
end

--[==[
Return the display form of the language. The display form of a language, family or script is the form it takes when
appearing as the <code><var>source</var></code> in categories such as <code>English terms derived from
<var>source</var></code> or <code>English given names from <var>source</var></code>, and is also the displayed text
in {makeCategoryLink()} links. For full and etymology-only languages, this is the same as the canonical name, but
for families, it reads <code>"<var>name</var> languages"</code> (e.g. {"Indo-Iranian languages"}), and for scripts,
it reads <code>"<var>name</var> script"</code> (e.g. {"Arabic script"}).
]==]
function Language:getDisplayForm()
	local form = self._displayForm
	if form == nil then
		form = self:getCanonicalName()
		-- Add article and " substrate" to substrates that lack them.
		if self:getFamilyCode() == "qfa-sub" then
			if not (sub(form, 1, 4) == "the " or sub(form, 1, 2) == "a ") then
				form = "a " .. form
			end
			if not match(form, " [Ss]ubstrate") then
				form = form .. " substrate"
			end
		end
		self._displayForm = form
	end
	return form
end

--[==[Returns the value which should be used in the HTML lang= attribute for tagged text in the language.]==]
function Language:getHTMLAttribute(sc, region)
	local code = self._code
	if not find(code, "-", 1, true) then
		return code .. "-" .. sc:getCode() .. (region and "-" .. region or "")
	end
	local parent = self:getParent()
	region = region or match(code, "%f[%u][%u-]+%f[%U]")
	if parent then
		return parent:getHTMLAttribute(sc, region)
	end
	-- TODO: ISO family codes can also be used.
	return "mis-" .. sc:getCode() .. (region and "-" .. region or "")
end

--[==[Returns a table of the aliases that the language is known by, excluding the canonical name. Aliases are synonyms for the language in question. The names are not guaranteed to be unique, in that sometimes more than one language is known by the same name. Example: {{code|lua|{"High German", "New High German", "Deutsch"} }} for [[:Category:German language|German]].]==]
function Language:getAliases()
	self:loadInExtraData()
	return require(language_like_module).getAliases(self)
end

--[==[
Return a table of the known subvarieties of a given language, excluding subvarieties that have been given
explicit etymology-only language codes. The names are not guaranteed to be unique, in that sometimes a given name
refers to a subvariety of more than one language. Example: {{code|lua|{"Southern Aymara", "Central Aymara"} }} for
[[:Category:Aymara language|Aymara]]. Note that the returned value can have nested tables in it, when a subvariety
goes by more than one name. Example: {{code|lua|{"North Azerbaijani", "South Azerbaijani", {"Afshar", "Afshari",
"Afshar Azerbaijani", "Afchar"}, {"Qashqa'i", "Qashqai", "Kashkay"}, "Sonqor"} }} for
[[:Category:Azerbaijani language|Azerbaijani]]. Here, for example, Afshar, Afshari, Afshar Azerbaijani and Afchar
all refer to the same subvariety, whose preferred name is Afshar (the one listed first). To avoid a return value
with nested tables in it, specify a non-{{code|lua|nil}} value for the <code>flatten</code> parameter; in that case,
the return value would be {{code|lua|{"North Azerbaijani", "South Azerbaijani", "Afshar", "Afshari",
"Afshar Azerbaijani", "Afchar", "Qashqa'i", "Qashqai", "Kashkay", "Sonqor"} }}.
]==]
function Language:getVarieties(flatten)
	self:loadInExtraData()
	return require(language_like_module).getVarieties(self, flatten)
end

--[==[Returns a table of the "other names" that the language is known by, which are listed in the <code>otherNames</code> field. It should be noted that the <code>otherNames</code> field itself is deprecated, and entries listed there should eventually be moved to either <code>aliases</code> or <code>varieties</code>.]==]
function Language:getOtherNames() -- To be eventually removed, once there are no more uses of the `otherNames` field.
	self:loadInExtraData()
	return require(language_like_module).getOtherNames(self)
end

--[==[
Return a combined table of the canonical name, aliases, varieties and other names of a given language.]==]
function Language:getAllNames()
	self:loadInExtraData()
	return require(language_like_module).getAllNames(self)
end

--[==[Returns a table of types as a lookup table (with the types as keys).

The possible types are
* {language}: This is a language, either full or etymology-only.
* {full}: This is a "full" (not etymology-only) language, i.e. the union of {regular}, {reconstructed} and
		{appendix-constructed}. Note that the types {full} and {etymology-only} also exist for families, so if you
		want to check specifically for a full language and you have an object that might be a family, you should
		use {{lua|hasType("language", "full")}} and not simply {{lua|hasType("full")}}.
* {etymology-only}: This is an etymology-only (not full) language, whose parent is another etymology-only
					language or a full language. Note that the types {full} and {etymology-only} also exist for
					families, so if you want to check specifically for an etymology-only language and you have an
					object that might be a family, you should use {{lua|hasType("language", "etymology-only")}}
					and not simply {{lua|hasType("etymology-only")}}.
* {regular}: This indicates a full language that is attested according to [[WT:CFI]] and therefore permitted
			in the main namespace. There may also be reconstructed terms for the language, which are placed in
			the {Reconstruction} namespace and must be prefixed with * to indicate a reconstruction. Most full
			languages are natural (not constructed) languages, but a few constructed languages (e.g. Esperanto
			and Volapük, among others) are also allowed in the mainspace and considered regular languages.
* {reconstructed}: This language is not attested according to [[WT:CFI]], and therefore is allowed only in the
				{Reconstruction} namespace. All terms in this language are reconstructed, and must be prefixed
				with *. Languages such as Proto-Indo-European and Proto-Germanic are in this category.
* {appendix-constructed}: This language is attested but does not meet the additional requirements set out for
						constructed languages ([[WT:CFI#Constructed languages]]). Its entries must therefore
						be in the Appendix namespace, but they are not reconstructed and therefore should
						not have * prefixed in links.
]==]
function Language:getTypes()
	local types = self._types
	if types == nil then
		types = {language = true}
		if self:getFullCode() == self._code then
			types.full = true
		else
			types["etymology-only"] = true
		end
		for t in gmatch(self._data.type, "[^,]+") do
			types[t] = true
		end
		self._types = types
	end
	return types
end

--[==[Given a list of types as strings, returns true if the language has all of them.]==]
function Language:hasType(...)
	Language.hasType = require(language_like_module).hasType
	return self:hasType(...)
end

--[==[Returns a table containing <code>WikimediaLanguage</code> objects (see [[Module:wikimedia languages]]), which represent languages and their codes as they are used in Wikimedia projects for interwiki linking and such. More than one object may be returned, as a single Wiktionary language may correspond to multiple Wikimedia languages. For example, Wiktionary's single code <code>sh</code> (Serbo-Croatian) maps to four Wikimedia codes: <code>sh</code> (Serbo-Croatian), <code>bs</code> (Bosnian), <code>hr</code> (Croatian) and <code>sr</code> (Serbian).
The code for the Wikimedia language is retrieved from the <code>wikimedia_codes</code> property in the data modules. If that property is not present, the code of the current language is used. If none of the available codes is actually a valid Wikimedia code, an empty table is returned.]==]
function Language:getWikimediaLanguages()
	local wm_langs = self._wikimediaLanguageObjects
	if wm_langs == nil then
		local codes = self:getWikimediaLanguageCodes()
		wm_langs = {}
		for i = 1, #codes do
			wm_langs[i] = get_wikimedia_lang(codes[i])
		end
		self._wikimediaLanguageObjects = wm_langs
	end
	return wm_langs
end

function Language:getWikimediaLanguageCodes()
	local wm_langs = self._wikimediaLanguageCodes
	if wm_langs == nil then
		wm_langs = self._data.wikimedia_codes
		if wm_langs then
			wm_langs = split(wm_langs, ",", true, true)
		else
			local code = self._code
			if is_known_language_tag(code) then
				wm_langs = {code}
			else
				-- Inherit, but only if no codes are specified in the data *and*
				-- the language code isn't a valid Wikimedia language code.
				local parent = self:getParent()
				wm_langs = parent and parent:getWikimediaLanguageCodes() or {}
			end
		end
		self._wikimediaLanguageCodes = wm_langs
	end
	return wm_langs
end

--[==[
Returns the name of the Wikipedia article for the language. `project` specifies the language and project to retrieve
the article from, defaulting to {"enwiki"} for the English Wikipedia. Normally if specified it should be the project
code for a specific-language Wikipedia e.g. "zhwiki" for the Chinese Wikipedia, but it can be any project, including
non-Wikipedia ones. If the project is the English Wikipedia and the property {wikipedia_article} is present in the data
module it will be used first. In all other cases, a sitelink will be generated from {:getWikidataItem} (if set). The
resulting value (or lack of value) is cached so that subsequent calls are fast. If no value could be determined, and
`noCategoryFallback` is {false}, {:getCategoryName} is used as fallback; otherwise, {nil} is returned. Note that if
`noCategoryFallback` is {nil} or omitted, it defaults to {false} if the project is the English Wikipedia, otherwise
to {true}. In other words, under normal circumstances, if the English Wikipedia article couldn't be retrieved, the
return value will fall back to a link to the language's category, but this won't normally happen for any other project.
]==]
function Language:getWikipediaArticle(noCategoryFallback, project)
	Language.getWikipediaArticle = require(language_like_module).getWikipediaArticle
	return self:getWikipediaArticle(noCategoryFallback, project)
end

function Language:makeWikipediaLink()
	return make_link(self, "w:" .. self:getWikipediaArticle(), self:getCanonicalName())
end

--[==[Returns the name of the Wikimedia Commons category page for the language.]==]
function Language:getCommonsCategory()
	Language.getCommonsCategory = require(language_like_module).getCommonsCategory
	return self:getCommonsCategory()
end

--[==[Returns the Wikidata item id for the language or <code>nil</code>. This corresponds to the the second field in the data modules.]==]
function Language:getWikidataItem()
	Language.getWikidataItem = require(language_like_module).getWikidataItem
	return self:getWikidataItem()
end

--[==[Returns a table of <code>Script</code> objects for all scripts that the language is written in. See [[Module:scripts]].]==]
function Language:getScripts()
	local scripts = self._scriptObjects
	if scripts == nil then
		local codes = self:getScriptCodes()
		if codes[1] == "All" then
			scripts = load_data(scripts_data_module)
		else
			scripts = {}
			for i = 1, #codes do
				scripts[i] = get_script(codes[i])
			end
		end
		self._scriptObjects = scripts
	end
	return scripts
end

--[==[Returns the table of script codes in the language's data file.]==]
function Language:getScriptCodes()
	local scripts = self._scriptCodes
	if scripts == nil then
		scripts = self._data[4]
		if scripts then
			local codes, n = {}, 0
			for code in gmatch(scripts, "[^,]+") do
				n = n + 1
				-- Special handling of "Hants", which represents "Hani", "Hant" and "Hans" collectively.
				if code == "Hants" then
					codes[n] = "Hani"
					codes[n + 1] = "Hant"
					codes[n + 2] = "Hans"
					n = n + 2
				else
					codes[n] = code
				end
			end
			scripts = codes
		else
			scripts = {"None"}
		end
		self._scriptCodes = scripts
	end
	return scripts
end

--[==[Given some text, this function iterates through the scripts of a given language and tries to find the script that best matches the text. It returns a {{code|lua|Script}} object representing the script. If no match is found at all, it returns the {{code|lua|None}} script object.]==]
function Language:findBestScript(text, forceDetect)
	if not text or text == "" or text == "-" then
		return get_script("None")
	end

	-- Differs from table returned by getScriptCodes, as Hants is not normalized into its constituents.
	local codes = self._bestScriptCodes
	if codes == nil then
		codes = self._data[4]
		codes = codes and split(codes, ",", true, true) or {"None"}
		self._bestScriptCodes = codes
	end

	local first_sc = codes[1]

	if first_sc == "All" then
		return find_best_script_without_lang(text)
	end

	local codes_len = #codes

	if not (forceDetect or first_sc == "Hants" or codes_len > 1) then
		first_sc = get_script(first_sc)
		local charset = first_sc.characters
		return charset and umatch(text, "[" .. charset .. "]") and first_sc or get_script("None")
	end

	-- Remove all formatting characters.
	text = get_plaintext(text)

	-- Remove all spaces and any ASCII punctuation. Some non-ASCII punctuation is script-specific, so can't be removed.
	text = ugsub(text, "[%s!\"#%%&'()*,%-./:;?@[\\%]_{}]+", "")
	if #text == 0 then
		return get_script("None")
	end

	-- Try to match every script against the text,
	-- and return the one with the most matching characters.
	local bestcount, bestscript, length = 0
	for i = 1, codes_len do
		local sc = codes[i]
		-- Special case for "Hants", which is a special code that represents whichever of "Hant" or "Hans" best matches, or "Hani" if they match equally. This avoids having to list all three. In addition, "Hants" will be treated as the best match if there is at least one matching character, under the assumption that a Han script is desirable in terms that contain a mix of Han and other scripts (not counting those which use Jpan or Kore).
		if sc == "Hants" then
			local Hani = get_script("Hani")
			if not Hant_chars then
				Hant_chars = load_data("Module:zh/data/ts")
				Hans_chars = load_data("Module:zh/data/st")
			end
			local t, s, found = 0, 0
			-- This is faster than using mw.ustring.gmatch directly.
			for ch in gmatch(ugsub(text, "[" .. Hani.characters .. "]", "\255%0"), "\255(.[\128-\191]*)") do
				found = true
				if Hant_chars[ch] then
					t = t + 1
					if Hans_chars[ch] then
						s = s + 1
					end
				elseif Hans_chars[ch] then
					s = s + 1
				else
					t, s = t + 1, s + 1
				end
			end

			if found then
				if t == s then
					return Hani
				end
				return get_script(t > s and "Hant" or "Hans")
			end
		else
			sc = get_script(sc)

			if not length then
				length = ulen(text)
			end

			-- Count characters by removing everything in the script's charset and comparing to the original length.
			local charset = sc.characters
			local count = charset and length - ulen(ugsub(text, "[" .. charset .. "]+", "")) or 0

			if count >= length then
				return sc
			elseif count > bestcount then
				bestcount = count
				bestscript = sc
			end
		end
	end

	-- Return best matching script, or otherwise None.
	return bestscript or get_script("None")
end

--[==[Returns a <code>Family</code> object for the language family that the language belongs to. See [[Module:families]].]==]
function Language:getFamily()
	local family = self._familyObject
	if family == nil then
		family = self:getFamilyCode()
		-- If the value is nil, it's cached as false.
		family = family and get_family(family) or false
		self._familyObject = family
	end
	return family or nil
end

--[==[Returns the family code in the language's data file.]==]
function Language:getFamilyCode()
	local family = self._familyCode
	if family == nil then
		-- If the value is nil, it's cached as false.
		family = self._data[3] or false
		self._familyCode = family
	end
	return family or nil
end

function Language:getFamilyName()
	local family = self._familyName
	if family == nil then
		family = self:getFamily()
		-- If the value is nil, it's cached as false.
		family = family and family:getCanonicalName() or false
		self._familyName = family
	end
	return family or nil
end

do
	local function check_family(self, family)
		if type(family) == "table" then
			family = family:getCode()
		end
		if self:getFamilyCode() == family then
			return true
		end
		local self_family = self:getFamily()
		if self_family:inFamily(family) then
			return true
		-- If the family isn't a real family (e.g. creoles) check any ancestors.
		elseif self_family:inFamily("qfa-not") then
			local ancestors = self:getAncestors()
			for _, ancestor in ipairs(ancestors) do
				if ancestor:inFamily(family) then
					return true
				end
			end
		end
	end

	--[==[Check whether the language belongs to `family` (which can be a family code or object). A list of objects can be given in place of `family`; in that case, return true if the language belongs to any of the specified families. Note that some languages (in particular, certain creoles) can have multiple immediate ancestors potentially belonging to different families; in that case, return true if the language belongs to any of the specified families.]==]
	function Language:inFamily(...)
		if self:getFamilyCode() == nil then
			return false
		end
		return check_inputs(self, check_family, false, ...)
	end
end

function Language:getParent()
	local parent = self._parentObject
	if parent == nil then
		parent = self:getParentCode()
		-- If the value is nil, it's cached as false.
		parent = parent and get_by_code(parent, nil, true, true) or false
		self._parentObject = parent
	end
	return parent or nil
end

function Language:getParentCode()
	local parent = self._parentCode
	if parent == nil then
		-- If the value is nil, it's cached as false.
		parent = self._data.parent or false
		self._parentCode = parent
	end
	return parent or nil
end

function Language:getParentName()
	local parent = self._parentName
	if parent == nil then
		parent = self:getParent()
		-- If the value is nil, it's cached as false.
		parent = parent and parent:getCanonicalName() or false
		self._parentName = parent
	end
	return parent or nil
end

function Language:getParentChain()
	local chain = self._parentChain
	if chain == nil then
		chain = {}
		local parent, n = self:getParent(), 0
		while parent do
			n = n + 1
			chain[n] = parent
			parent = parent:getParent()
		end
		self._parentChain = chain
	end
	return chain
end

do
	local function check_lang(self, lang)
		for _, parent in ipairs(self:getParentChain()) do
			if (type(lang) == "string" and lang or lang:getCode()) == parent:getCode() then
				return true
			end
		end
	end

	function Language:hasParent(...)
		return check_inputs(self, check_lang, false, ...)
	end
end

--[==[
If the language is etymology-only, this iterates through parents until a full language or family is found, and the
corresponding object is returned. If the language is a full language, then it simply returns itself.
]==]
function Language:getFull()
	local full = self._fullObject
	if full == nil then
		full = self:getFullCode()
		full = full == self._code and self or get_by_code(full)
		self._fullObject = full
	end
	return full
end

--[==[
If the language is an etymology-only language, this iterates through parents until a full language or family is
found, and the corresponding code is returned. If the language is a full language, then it simply returns the
language code.
]==]
function Language:getFullCode()
	return self._fullCode or self._code
end

--[==[
If the language is an etymology-only language, this iterates through parents until a full language or family is
found, and the corresponding canonical name is returned. If the language is a full language, then it simply returns
the canonical name of the language.
]==]
function Language:getFullName()
	local full = self._fullName
	if full == nil then
		full = self:getFull():getCanonicalName()
		self._fullName = full
	end
	return full
end

--[==[Returns a table of <code class="nf">Language</code> objects for all languages that this language is directly descended from. Generally this is only a single language, but creoles, pidgins and mixed languages can have multiple ancestors.]==]
function Language:getAncestors()
	local ancestors = self._ancestorObjects
	if ancestors == nil then
		ancestors = {}
		local ancestor_codes = self:getAncestorCodes()
		if #ancestor_codes > 0 then
			for _, ancestor in ipairs(ancestor_codes) do
				insert(ancestors, get_by_code(ancestor, nil, true))
			end
		else
			local fam = self:getFamily()
			local protoLang = fam and fam:getProtoLanguage() or nil
			-- For the cases where the current language is the proto-language
			-- of its family, or an etymology-only language that is ancestral to that
			-- proto-language, we need to step up a level higher right from the
			-- start.
			if protoLang and (
				protoLang:getCode() == self._code or
				(self:hasType("etymology-only") and protoLang:hasAncestor(self))
			) then
				fam = fam:getFamily()
				protoLang = fam and fam:getProtoLanguage() or nil
			end
			while not protoLang and not (not fam or fam:getCode() == "qfa-not") do
				fam = fam:getFamily()
				protoLang = fam and fam:getProtoLanguage() or nil
			end
			insert(ancestors, protoLang)
		end
		self._ancestorObjects = ancestors
	end
	return ancestors
end

do
	-- Avoid a language being its own ancestor via class inheritance. We only need to check for this if the language has inherited an ancestor table from its parent, because we never want to drop ancestors that have been explicitly set in the data.
	-- Recursively iterate over ancestors until we either find self or run out. If self is found, return true.
	local function check_ancestor(self, lang)
		local codes = lang:getAncestorCodes()
		if not codes then
			return nil
		end
		for i = 1, #codes do
			local code = codes[i]
			if code == self._code then
				return true
			end
			local anc = get_by_code(code, nil, true)
			if check_ancestor(self, anc) then
				return true
			end
		end
	end

	--[==[Returns a table of <code class="nf">Language</code> codes for all languages that this language is directly descended from. Generally this is only a single language, but creoles, pidgins and mixed languages can have multiple ancestors.]==]
	function Language:getAncestorCodes()
		if self._ancestorCodes then
			return self._ancestorCodes
		end
		local data = self._data
		local codes = data.ancestors
		if codes == nil then
			codes = {}
			self._ancestorCodes = codes
			return codes
		end
		codes = split(codes, ",", true, true)
		self._ancestorCodes = codes
		-- If there are no codes or the ancestors weren't inherited data, there's nothing left to check.
		if #codes == 0 or self:getData(false, "raw").ancestors ~= nil then
			return codes
		end
		local i, code = 1
		while i <= #codes do
			code = codes[i]
			if check_ancestor(self, self) then
				remove(codes, i)
			else
				i = i + 1
			end
		end
		return codes
	end
end

--[==[Given a list of language objects or codes, returns true if at least one of them is an ancestor. This includes any etymology-only children of that ancestor. If the language's ancestor(s) are etymology-only languages, it will also return true for those language parent(s) (e.g. if Vulgar Latin is the ancestor, it will also return true for its parent, Latin). However, a parent is excluded from this if the ancestor is also ancestral to that parent (e.g. if Classical Persian is the ancestor, Persian would return false, because Classical Persian is also ancestral to Persian).]==]
function Language:hasAncestor(...)
	local function iterateOverAncestorTree(node, func, parent_check)
		local ancestors = node:getAncestors()
		local ancestorsParents = {}
		for _, ancestor in ipairs(ancestors) do
			-- When checking the parents of the other language, and the ancestor is also a parent, skip to the next ancestor, so that we exclude any etymology-only children of that parent that are not directly related (see below).
			local ret = (parent_check or not node:hasParent(ancestor)) and
				func(ancestor) or iterateOverAncestorTree(ancestor, func, parent_check)
			if ret then
				return ret
			end
		end
		-- Check the parents of any ancestors. We don't do this if checking the parents of the other language, so that we exclude any etymology-only children of those parents that are not directly related (e.g. if the ancestor is Vulgar Latin and we are checking New Latin, we want it to return false because they are on different ancestral branches. As such, if we're already checking the parent of New Latin (Latin) we don't want to compare it to the parent of the ancestor (Latin), as this would be a false positive; it should be one or the other).
		if not parent_check then
			return nil
		end
		for _, ancestor in ipairs(ancestors) do
			local ancestorParents = ancestor:getParentChain()
			for _, ancestorParent in ipairs(ancestorParents) do
				if ancestorParent:getCode() == self._code or ancestorParent:hasAncestor(ancestor) then
					break
				else
					insert(ancestorsParents, ancestorParent)
				end
			end
		end
		for _, ancestorParent in ipairs(ancestorsParents) do
			local ret = func(ancestorParent)
			if ret then
				return ret
			end
		end
	end

	local function do_iteration(otherlang, parent_check)
		-- otherlang can't be self
		if (type(otherlang) == "string" and otherlang or otherlang:getCode()) == self._code then
			return false
		end
		repeat
			if iterateOverAncestorTree(
				self,
				function(ancestor)
					return ancestor:getCode() == (type(otherlang) == "string" and otherlang or otherlang:getCode())
				end,
				parent_check
			) then
				return true
			elseif type(otherlang) == "string" then
				otherlang = get_by_code(otherlang, nil, true)
			end
			otherlang = otherlang:getParent()
			parent_check = false
		until not otherlang
	end

	local parent_check = true
	for _, otherlang in ipairs{...} do
		local ret = do_iteration(otherlang, parent_check)
		if ret then
			return true
		end
	end
	return false
end

do
	local function construct_node(lang, memo)
		local branch, ancestors = {lang = lang:getCode()}
		memo[lang:getCode()] = branch
		for _, ancestor in ipairs(lang:getAncestors()) do
			if ancestors == nil then
				ancestors = {}
			end
			insert(ancestors, memo[ancestor:getCode()] or construct_node(ancestor, memo))
		end
		branch.ancestors = ancestors
		return branch
	end

	function Language:getAncestorChain()
		local chain = self._ancestorChain
		if chain == nil then
			chain = construct_node(self, {})
			self._ancestorChain = chain
		end
		return chain
	end
end

function Language:getAncestorChainOld()
	local chain = self._ancestorChain
	if chain == nil then
		chain = {}
		local step = self
		while true do
			local ancestors = step:getAncestors()
			step = #ancestors == 1 and ancestors[1] or nil
			if not step then
				break
			end
			insert(chain, step)
		end
		self._ancestorChain = chain
	end
	return chain
end

local function fetch_descendants(self, fmt)
	local descendants, family = {}, self:getFamily()
	-- Iterate over all three datasets.
	for _, data in ipairs{
		require("Module:languages/code to canonical name"),
		require("Module:etymology languages/code to canonical name"),
		require("Module:families/code to canonical name"),
	} do
		for code in pairs(data) do
			local lang = get_by_code(code, nil, true, true)
			-- Test for a descendant. Earlier tests weed out most candidates, while the more intensive tests are only used sparingly.
			if (
				code ~= self._code and -- Not self.
				lang:inFamily(family) and -- In the same family.
				(
					family:getProtoLanguageCode() == self._code or -- Self is the protolanguage.
					self:hasDescendant(lang) or -- Full hasDescendant check.
					(lang:getFullCode() == self._code and not self:hasAncestor(lang)) -- Etymology-only child which isn't an ancestor.
				)
			) then
				if fmt == "object" then
					insert(descendants, lang)
				elseif fmt == "code" then
					insert(descendants, code)
				elseif fmt == "name" then
					insert(descendants, lang:getCanonicalName())
				end
			end
		end
	end
	return descendants
end

function Language:getDescendants()
	local descendants = self._descendantObjects
	if descendants == nil then
		descendants = fetch_descendants(self, "object")
		self._descendantObjects = descendants
	end
	return descendants
end

function Language:getDescendantCodes()
	local descendants = self._descendantCodes
	if descendants == nil then
		descendants = fetch_descendants(self, "code")
		self._descendantCodes = descendants
	end
	return descendants
end

function Language:getDescendantNames()
	local descendants = self._descendantNames
	if descendants == nil then
		descendants = fetch_descendants(self, "name")
		self._descendantNames = descendants
	end
	return descendants
end

do
	local function check_lang(self, lang)
		if type(lang) == "string" then
			lang = get_by_code(lang, nil, true)
		end
		if lang:hasAncestor(self) then
			return true
		end
	end

	function Language:hasDescendant(...)
		return check_inputs(self, check_lang, false, ...)
	end
end

local function fetch_children(self, fmt)
	local m_etym_data = require(etymology_languages_data_module)
	local self_code, children = self._code, {}
	for code, lang in pairs(m_etym_data) do
		local _lang = lang
		repeat
			local parent = _lang.parent
			if parent == self_code then
				if fmt == "object" then
					insert(children, get_by_code(code, nil, true))
				elseif fmt == "code" then
					insert(children, code)
				elseif fmt == "name" then
					insert(children, lang[1])
				end
				break
			end
			_lang = m_etym_data[parent]
		until not _lang
	end
	return children
end

function Language:getChildren()
	local children = self._childObjects
	if children == nil then
		children = fetch_children(self, "object")
		self._childObjects = children
	end
	return children
end

function Language:getChildrenCodes()
	local children = self._childCodes
	if children == nil then
		children = fetch_children(self, "code")
		self._childCodes = children
	end
	return children
end

function Language:getChildrenNames()
	local children = self._childNames
	if children == nil then
		children = fetch_children(self, "name")
		self._childNames = children
	end
	return children
end

function Language:hasChild(...)
	local lang = ...
	if not lang then
		return false
	elseif type(lang) == "string" then
		lang = get_by_code(lang, nil, true)
	end
	if lang:hasParent(self) then
		return true
	end
	return self:hasChild(select(2, ...))
end

--[==[Returns the name of the main category of that language. Example: {{code|lua|"French language"}} for French, whose category is at [[:Category:French language]]. Unless optional argument <code>nocap</code> is given, the language name at the beginning of the returned value will be capitalized. This capitalization is correct for category names, but not if the language name is lowercase and the returned value of this function is used in the middle of a sentence.]==]
function Language:getCategoryName(nocap)
	local name = self._categoryName
	if name == nil then
		name = self:getCanonicalName()
		-- If a substrate, omit any leading article.
		if self:getFamilyCode() == "qfa-sub" then
			name = name:gsub("^the ", ""):gsub("^a ", "")
		end
		-- Only add " language" if a full language.
		if self:hasType("full") then
			-- Unless the canonical name already ends with "language", "lect" or their derivatives, add " language".
			if not (match(name, "[Ll]anguage$") or match(name, "[Ll]ect$")) then
				name = name .. " language"
			end
		end
		self._categoryName = name
	end
	if nocap then
		return name
	end
	return mw.getContentLanguage():ucfirst(name)
end

--[==[Creates a link to the category; the link text is the canonical name.]==]
function Language:makeCategoryLink()
	return make_link(self, ":Category:" .. self:getCategoryName(), self:getDisplayForm())
end

function Language:getStandardCharacters(sc)
	local standard_chars = self._data.standardChars
	if type(standard_chars) ~= "table" then
		return standard_chars
	elseif sc and type(sc) ~= "string" then
		check_object("script", nil, sc)
		sc = sc:getCode()
	end
	if (not sc) or sc == "None" then
		local scripts = {}
		for _, script in pairs(standard_chars) do
			insert(scripts, script)
		end
		return concat(scripts)
	end
	if standard_chars[sc] then
		return standard_chars[sc] .. (standard_chars[1] or "")
	end
end

--[==[Make the entry name (i.e. the correct page name).]==]
function Language:makeEntryName(text, sc)
	if (not text) or text == "" then
		return text, nil, {}
	end

	-- Set `unsupported` as true if certain conditions are met.
	local unsupported
	-- Check if there's an unsupported character. \239\191\189 is the replacement character U+FFFD, which can't be typed directly here due to an abuse filter. Unix-style dot-slash notation is also unsupported, as it is used for relative paths in links, as are 3 or more consecutive tildes.
	-- Note: match is faster with magic characters/charsets; find is faster with plaintext.
	if (
		match(text, "[#<>%[%]_{|}]") or
		find(text, "\239\191\189") or
		match(text, "%f[^%z/]%.%.?%f[%z/]") or
		find(text, "~~~")
	) then
		unsupported = true
	-- If it looks like an interwiki link.
	elseif find(text, ":") then
		local prefix = gsub(text, "^:*(.-):.*", ulower)
		if (
			load_data("Module:data/namespaces")[prefix] or
			load_data("Module:data/interwikis")[prefix]
		) then
			unsupported = true
		end
	end

	-- Check if the text is a listed unsupported title.
	local unsupportedTitles = load_data(links_data_module).unsupported_titles
	if unsupportedTitles[text] then
		return "Unsupported titles/" .. unsupportedTitles[text], nil, {}
	end

	sc = checkScript(text, self, sc)

	local fail, cats
	text = normalize(text, sc)
	text, fail, cats = iterateSectionSubstitutions(self, text, sc, nil, nil, self._data.entry_name, "makeEntryName")

	text = umatch(text, "^[¿¡]?(.-[^%s%p].-)%s*[؟?!;՛՜ ՞ ՟？！︖︕।॥။၊་།]?$") or text


	-- Escape unsupported characters so they can be used in titles. ` is used as a delimiter for this, so a raw use of it in an unsupported title is also escaped here to prevent interference; this is only done with unsupported titles, though, so inclusion won't in itself mean a title is treated as unsupported (which is why it's excluded from the earlier test).
	if unsupported then
		local unsupported_characters = load_data(links_data_module).unsupported_characters
		text = text:gsub("[#<>%[%]_`{|}\239]\191?\189?", unsupported_characters)
			:gsub("%f[^%z/]%.%.?%f[%z/]", function(m)
				return gsub(m, "%.", "`period`")
			end)
			:gsub("~~~+", function(m)
				return gsub(m, "~", "`tilde`")
			end)
		text = "Unsupported titles/" .. text
	end

	return text, fail, cats
end

--[==[Generates alternative forms using a specified method, and returns them as a table. If no method is specified, returns a table containing only the input term.]==]
function Language:generateForms(text, sc)
	local generate_forms = self._data.generate_forms
	if generate_forms == nil then
		return {text}
	end
	sc = checkScript(text, self, sc)
	return require("Module:" .. self._data.generate_forms).generateForms(text, self, sc)
end

--[==[Creates a sort key for the given entry name, following the rules appropriate for the language. This removes diacritical marks from the entry name if they are not considered significant for sorting, and may perform some other changes. Any initial hyphen is also removed, and anything parentheses is removed as well.
The <code>sort_key</code> setting for each language in the data modules defines the replacements made by this function, or it gives the name of the module that takes the entry name and returns a sortkey.]==]
function Language:makeSortKey(text, sc)
	if (not text) or text == "" then
		return text, nil, {}
	end
	if match(text, "<[^<>]+>") then
		track("track HTML tag")
	end
	-- Remove directional characters, soft hyphens, strip markers and HTML tags.
	text = ugsub(text, "[\194\173\226\128\170-\226\128\174\226\129\166-\226\129\169]", "")
	text = gsub(unstrip(text), "<[^<>]+>", "")

	text = decode_uri(text, "PATH")
	text = checkNoEntities(self, text)

	-- Remove initial hyphens and * unless the term only consists of spacing + punctuation characters.
	text = ugsub(text, "^([􀀀-􏿽]*)[-־ـ᠊*]+([􀀀-􏿽]*)(.*[^%s%p].*)", "%1%2%3")

	sc = checkScript(text, self, sc)

	text = normalize(text, sc)
	text = removeCarets(text, sc)

	-- For languages with dotted dotless i, ensure that "İ" is sorted as "i", and "I" is sorted as "ı".
	if self:hasDottedDotlessI() then
		text = gsub(text, "I\204\135", "i") -- decomposed "İ"
			:gsub("I", "ı")
		text = sc:toFixedNFD(text)
	end
	-- Convert to lowercase, make the sortkey, then convert to uppercase. Where the language has dotted dotless i, it is usually not necessary to convert "i" to "İ" and "ı" to "I" first, because "I" will always be interpreted as conventional "I" (not dotless "İ") by any sorting algorithms, which will have been taken into account by the sortkey substitutions themselves. However, if no sortkey substitutions have been specified, then conversion is necessary so as to prevent "i" and "ı" both being sorted as "I".
	-- An exception is made for scripts that (sometimes) sort by scraping page content, as that means they are sensitive to changes in capitalization (as it changes the target page).
	local fail, cats
	if not sc:sortByScraping() then
		text = ulower(text)
	end

	local sort_key = self._data.sort_key
	text, fail, cats = iterateSectionSubstitutions(self, text, sc, nil, nil, sort_key, "makeSortKey")

	if not sc:sortByScraping() then
		if self:hasDottedDotlessI() and not sort_key then
			text = gsub(gsub(text, "ı", "I"), "i", "İ")
			text = sc:toFixedNFC(text)
		end
		text = uupper(text)
	end

	-- Remove parentheses, as long as they are either preceded or followed by something.
	text = gsub(text, "(.)[()]+", "%1")
		:gsub("[()]+(.)", "%1")

	text = escape_risky_characters(text)
	return text, fail, cats
end

--[==[Create the form used as as a basis for display text and transliteration.]==]
local function processDisplayText(text, self, sc, keepCarets, keepPrefixes)
	local subbedChars = {}
	text, subbedChars = doTempSubstitutions(text, subbedChars, keepCarets)

	text = decode_uri(text, "PATH")
	text = checkNoEntities(self, text)

	sc = checkScript(text, self, sc)
	local fail, cats
	text = normalize(text, sc)
	text, fail, cats, subbedChars = iterateSectionSubstitutions(self, text, sc, subbedChars, keepCarets, self._data.display_text, "makeDisplayText")

	text = removeCarets(text, sc)

	-- Remove any interwiki link prefixes (unless they have been escaped or this has been disabled).
	if find(text, ":") and not keepPrefixes then
		local rep
		repeat
			text, rep = gsub(text, "\\\\(\\*:)", "\3%1")
		until rep == 0
		text = gsub(text, "\\:", "\4")
		while true do
			local prefix = gsub(text, "^(.-):.+", function(m1)
				return gsub(m1, "\244[\128-\191]*", "")
			end)
			-- Check if the prefix is an interwiki, though ignore capitalised Wiktionary:, which is a namespace.
			if not prefix or prefix == text or prefix == "Wiktionary"
				or not (load_data("Module:data/interwikis")[ulower(prefix)] or prefix == "") then
				break
			end
			text = gsub(text, "^(.-):(.*)", function(m1, m2)
				local ret = {}
				for subbedChar in gmatch(m1, "\244[\128-\191]*") do
					insert(ret, subbedChar)
				end
				return concat(ret) .. m2
			end)
		end
		text = gsub(text, "\3", "\\")
			:gsub("\4", ":")
	end

	return text, fail, cats, subbedChars
end

--[==[Make the display text (i.e. what is displayed on the page).]==]
function Language:makeDisplayText(text, sc, keepPrefixes)
	if (not text) or text == "" then
		return text, nil, {}
	end

	local fail, cats, subbedChars
	text, fail, cats, subbedChars = processDisplayText(text, self, sc, nil, keepPrefixes)

	text = escape_risky_characters(text)
	return undoTempSubstitutions(text, subbedChars), fail, cats
end

--[==[Transliterates the text from the given script into the Latin script (see [[Wiktionary:Transliteration and romanization]]). The language must have the <code>translit</code> property for this to work; if it is not present, {{code|lua|nil}} is returned.
Returns three values:
# The transliteration.
# A boolean which indicates whether the transliteration failed for an unexpected reason. If {{code|lua|false}}, then the transliteration either succeeded, or the module is returning nothing in a controlled way (e.g. the input was {{code|lua|"-"}}). Generally, this means that no maintenance action is required. If {{code|lua|true}}, then the transliteration is {{code|lua|nil}} because either the input or output was defective in some way (e.g. [[Module:ar-translit]] will not transliterate non-vocalised inputs, and this module will fail partially-completed transliterations in all languages). Note that this value can be manually set by the transliteration module, so make sure to cross-check to ensure it is accurate.
# A table of categories selected by the transliteration module, which should be in the format expected by {{code|lua|format_categories}} in [[Module:utilities]].
The <code>sc</code> parameter is handled by the transliteration module, and how it is handled is specific to that module. Some transliteration modules may tolerate {{code|lua|nil}} as the script, others require it to be one of the possible scripts that the module can transliterate, and will show an error if it's not one of them. For this reason, the <code>sc</code> parameter should always be provided when writing non-language-specific code.
The <code>module_override</code> parameter is used to override the default module that is used to provide the transliteration. This is useful in cases where you need to demonstrate a particular module in use, but there is no default module yet, or you want to demonstrate an alternative version of a transliteration module before making it official. It should not be used in real modules or templates, only for testing. All uses of this parameter are tracked by [[Wiktionary:Tracking/languages/module_override]].
'''Known bugs''':
* This function assumes {tr(s1) .. tr(s2) == tr(s1 .. s2)}. When this assertion fails, wikitext markups like <nowiki>'''</nowiki> can cause wrong transliterations.
* HTML entities like <code>&amp;apos;</code>, often used to escape wikitext markups, do not work.]==]
function Language:transliterate(text, sc, module_override)
	-- If there is no text, or the language doesn't have transliteration data and there's no override, return nil.
	if not (self._data.translit or module_override) then
		return nil, false, {}
	elseif (not text) or text == "" or text == "-" then
		return text, false, {}
	end
	-- If the script is not transliteratable (and no override is given), return nil.
	sc = checkScript(text, self, sc)
	if not (sc:isTransliterated() or module_override) then
		-- temporary tracking to see if/when this gets triggered
		track("non-transliterable")
		track("non-transliterable/" .. self._code)
		track("non-transliterable/" .. sc:getCode())
		track("non-transliterable/" .. sc:getCode() .. "/" .. self._code)
		return nil, true, {}
	end

	-- Remove any strip markers.
	text = unstrip(text)

	-- Do not process the formatting into PUA characters for certain languages.
	local processed = load_data(languages_data_module).substitution[self._code] ~= "none"

	-- Get the display text with the keepCarets flag set.
	local fail, cats, subbedChars
	if processed then
		text, fail, cats, subbedChars = processDisplayText(text, self, sc, true)
	end

	-- Transliterate (using the module override if applicable).
	text, fail, cats, subbedChars = iterateSectionSubstitutions(self, text, sc, subbedChars, true, module_override or self._data.translit, "tr")

	if not text then
		return nil, true, cats
	end

	-- Incomplete transliterations return nil.
	local charset = sc.characters
	if charset and umatch(text, "[" .. charset .. "]") then
		-- Remove any characters in Latin, which includes Latin characters also included in other scripts (as these are false positives), as well as any PUA substitutions. Anything remaining should only be script code "None" (e.g. numerals).
		local check_text = ugsub(text, "[" .. get_script("Latn").characters .. "􀀀-􏿽]+", "")
		-- Set none_is_last_resort_only flag, so that any non-None chars will cause a script other than "None" to be returned.
		if find_best_script_without_lang(check_text, true):getCode() ~= "None" then
			return nil, true, cats
		end
	end

	if processed then
		text = escape_risky_characters(text)
		text = undoTempSubstitutions(text, subbedChars)
	end

	-- If the script does not use capitalization, then capitalize any letters of the transliteration which are immediately preceded by a caret (and remove the caret).
	if text and not sc:hasCapitalization() and text:find("^", 1, true) then
		text = processCarets(text, "%^([\128-\191\244]*%*?)([^\128-\191\244][\128-\191]*)", function(m1, m2)
			return m1 .. uupper(m2)
		end)
	end

	-- Track module overrides.
	if module_override ~= nil then
		track("module_override")
	end

	fail = text == nil and (not not fail) or false

	return text, fail, cats
end

do
	local function handle_language_spec(self, spec, sc)
		local ret = self["_" .. spec]
		if ret == nil then
			ret = self._data[spec]
			if type(ret) == "string" then
				ret = list_to_set(split(ret, ",", true, true))
			end
			self["_" .. spec] = ret
		end
		if type(ret) == "table" then
			ret = ret[sc:getCode()]
		end
		return not not ret
	end

	function Language:overrideManualTranslit(sc)
		return handle_language_spec(self, "override_translit", sc)
	end

	function Language:link_tr(sc)
		return handle_language_spec(self, "link_tr", sc)
	end
end

--[==[Returns {{code|lua|true}} if the language has a transliteration module, or {{code|lua|false}} if it doesn't.]==]
function Language:hasTranslit()
	return not not self._data.translit
end

--[==[Returns {{code|lua|true}} if the language uses the letters I/ı and İ/i, or {{code|lua|false}} if it doesn't.]==]
function Language:hasDottedDotlessI()
	return not not self._data.dotted_dotless_i
end

function Language:toJSON(opts)
	local entry_name, entry_name_patterns, entry_name_remove_diacritics = self._data.entry_name
	if entry_name then
		if entry_name.from then
			entry_name_patterns = {}
			for i, from in ipairs(entry_name.from) do
				insert(entry_name_patterns, {from = from, to = entry_name.to[i] or ""})
			end
		end
		entry_name_remove_diacritics = entry_name.remove_diacritics
	end
	-- mainCode should only end up non-nil if dontCanonicalizeAliases is passed to make_object().
	-- props should either contain zero-argument functions to compute the value, or the value itself.
	local props = {
		ancestors = function() return self:getAncestorCodes() end,
		canonicalName = function() return self:getCanonicalName() end,
		categoryName = function() return self:getCategoryName("nocap") end,
		code = self._code,
		mainCode = self._mainCode,
		parent = function() return self:getParentCode() end,
		full = function() return self:getFullCode() end,
		entryNamePatterns = entry_name_patterns,
		entryNameRemoveDiacritics = entry_name_remove_diacritics,
		family = function() return self:getFamilyCode() end,
		aliases = function() return self:getAliases() end,
		varieties = function() return self:getVarieties() end,
		otherNames = function() return self:getOtherNames() end,
		scripts = function() return self:getScriptCodes() end,
		type = function() return keys_to_list(self:getTypes()) end,
		wikimediaLanguages = function() return self:getWikimediaLanguageCodes() end,
		wikidataItem = function() return self:getWikidataItem() end,
		wikipediaArticle = function() return self:getWikipediaArticle(true) end,
	}
	local ret = {}
	for prop, val in pairs(props) do
		if not opts.skip_fields or not opts.skip_fields[prop] then
			if type(val) == "function" then
				ret[prop] = val()
			else
				ret[prop] = val
			end
		end
	end

	-- Use `deep_copy` when returning a table, so that there are no editing restrictions imposed by `mw.loadData`.
	return opts and opts.lua_table and deep_copy(ret) or to_json(ret, opts)
end

function export.getDataModuleName(code)
	local letter = match(code, "^(%l)%l%l?$")
	return "Module:" .. (
		letter == nil and "languages/data/exceptional" or
		#code == 2 and "languages/data/2" or
		"languages/data/3/" .. letter
	)
end
get_data_module_name = export.getDataModuleName

function export.getExtraDataModuleName(code)
	return get_data_module_name(code) .. "/extra"
end
get_extra_data_module_name = export.getExtraDataModuleName

do
	local function make_stack(data)
		local key_types = {
			[2] = "unique",
			aliases = "unique",
			otherNames = "unique",
			type = "append",
			varieties = "unique",
			wikipedia_article = "unique",
			wikimedia_codes = "unique"
		}

		local function __index(self, k)
			local stack, key_type = getmetatable(self), key_types[k]
			-- Data that isn't inherited from the parent.
			if key_type == "unique" then
				local v = stack[stack[make_stack]][k]
				if v == nil then
					local layer = stack[0]
					if layer then -- Could be false if there's no extra data.
						v = layer[k]
					end
				end
				return v
			-- Data that is appended by each generation.
			elseif key_type == "append" then
				local parts, offset, n = {}, 0, stack[make_stack]
				for i = 1, n do
					local part = stack[i][k]
					if part == nil then
						offset = offset + 1
					else
						parts[i - offset] = part
					end
				end
				return offset ~= n and concat(parts, ",") or nil
			end
			local n = stack[make_stack]
			while true do
				local layer = stack[n]
				if not layer then -- Could be false if there's no extra data.
					return nil
				end
				local v = layer[k]
				if v ~= nil then
					return v
				end
				n = n - 1
			end
		end

		local function __newindex()
			error("table is read-only")
		end

		local function __pairs(self)
			-- Iterate down the stack, caching keys to avoid duplicate returns.
			local stack, seen = getmetatable(self), {}
			local n = stack[make_stack]
			local iter, state, k, v = pairs(stack[n])
			return function()
				repeat
					repeat
						k = iter(state, k)
						if k == nil then
							n = n - 1
							local layer = stack[n]
							if not layer then -- Could be false if there's no extra data.
								return nil
							end
							iter, state, k = pairs(layer)
						end
					until not (k == nil or seen[k])
					-- Get the value via a lookup, as the one returned by the
					-- iterator will be the raw value from the current layer,
					-- which may not be the one __index will return for that
					-- key. Also memoize the key in `seen` (even if the lookup
					-- returns nil) so that it doesn't get looked up again.
					-- TODO: store values in `self`, avoiding the need to create
					-- the `seen` table. The iterator will need to iterate over
					-- `self` with `next` first to find these on future loops.
					v, seen[k] = self[k], true
				until v ~= nil
				return k, v
			end
		end

		local __ipairs = require(table_module).indexIpairs

		function make_stack(data)
			local stack = {
				data,
				[make_stack] = 1, -- stores the length and acts as a sentinel to confirm a given metatable is a stack.
				__index = __index,
				__newindex = __newindex,
				__pairs = __pairs,
				__ipairs = __ipairs,
			}
			stack.__metatable = stack
			return setmetatable({}, stack), stack
		end

		return make_stack(data)
	end

	local function get_stack(data)
		local stack = getmetatable(data)
		return stack and type(stack) == "table" and stack[make_stack] and stack or nil
	end

	--[==[
	<span style="color: #BA0000">This function is not for use in entries or other content pages.</span>
	Returns a blob of data about the language. The format of this blob is undocumented, and perhaps unstable; it's intended for things like the module's own unit-tests, which are "close friends" with the module and will be kept up-to-date as the format changes. If `extra` is set, any extra data in the relevant `/extra` module will be included. (Note that it will be included anyway if it has already been loaded into the language object.) If `raw` is set, then the returned data will not contain any data inherited from parent objects.
	-- Do NOT use these methods!
	-- All uses should be pre-approved on the talk page!
	]==]
	function Language:getData(extra, raw)
		if extra then
			self:loadInExtraData()
		end
		local data = self._data
		-- If raw is not set, just return the data.
		if not raw then
			return data
		end
		local stack = get_stack(data)
		-- If there isn't a stack or its length is 1, return the data. Extra data (if any) will be included, as it's stored at key 0 and doesn't affect the reported length.
		if stack == nil then
			return data
		end
		local n = stack[make_stack]
		if n == 1 then
			return data
		end
		local extra = stack[0]
		-- If there isn't any extra data, return the top layer of the stack.
		if extra == nil then
			return stack[n]
		end
		-- If there is, return a new stack which has the top layer at key 1 and the extra data at key 0.
		data, stack = make_stack(stack[n])
		stack[0] = extra
		return data
	end

	function Language:loadInExtraData()
		-- Only full languages have extra data.
		if not self:hasType("language", "full") then
			return
		end
		local data = self._data
		-- If there's no stack, create one.
		local stack = get_stack(self._data)
		if stack == nil then
			data, stack = make_stack(data)
		-- If already loaded, return.
		elseif stack[0] ~= nil then
			return
		end
		self._data = data
		-- Load extra data from the relevant module and add it to the stack at key 0, so that the __index and __pairs metamethods will pick it up, since they iterate down the stack until they run out of layers.
		local code = self._code
		local modulename = get_extra_data_module_name(code)
		-- No data cached as false.
		stack[0] = modulename and load_data(modulename)[code] or false
	end

	--[==[Returns the name of the module containing the language's data. Currently, this is always [[Module:scripts/data]].]==]
	function Language:getDataModuleName()
		local name = self._dataModuleName
		if name == nil then
			name = self:hasType("etymology-only") and etymology_languages_data_module or
				get_data_module_name(self._mainCode or self._code)
			self._dataModuleName = name
		end
		return name
	end

	--[==[Returns the name of the module containing the language's data. Currently, this is always [[Module:scripts/data]].]==]
	function Language:getExtraDataModuleName()
		local name = self._extraDataModuleName
		if name == nil then
			name = not self:hasType("etymology-only") and get_extra_data_module_name(self._mainCode or self._code) or false
			self._extraDataModuleName = name
		end
		return name or nil
	end

	function export.makeObject(code, data, dontCanonicalizeAliases)
		local data_type = type(data)
		if data_type ~= "table" then
			error(("bad argument #2 to 'makeObject' (table expected, got %s)"):format(data_type))
		end

		-- Convert any aliases.
		local input_code = code
		code = normalize_code(code)
		input_code = dontCanonicalizeAliases and input_code or code

		local parent
		if data.parent then
			parent = get_by_code(data.parent, nil, true, true)
		else
			parent = Language
		end
		parent.__index = parent

		local lang = {_code = input_code}
		-- This can only happen if dontCanonicalizeAliases is passed to make_object().
		if code ~= input_code then
			lang._mainCode = code
		end

		local parent_data = parent._data
		if parent_data == nil then
			-- Full code is the same as the code.
			lang._fullCode = parent._code or code
		else
			-- Copy full code.
			lang._fullCode = parent._fullCode
			local stack = get_stack(parent_data)
			if stack == nil then
				parent_data, stack = make_stack(parent_data)
			end
			-- Insert the input data as the new top layer of the stack.
			local n = stack[make_stack] + 1
			data, stack[n], stack[make_stack] = parent_data, data, n
		end
		lang._data = data

		return setmetatable(lang, parent)
	end
	make_object = export.makeObject
end

--[==[Finds the language whose code matches the one provided. If it exists, it returns a <code class="nf">Language</code> object representing the language. Otherwise, it returns {{code|lua|nil}}, unless <code class="n">paramForError</code> is given, in which case an error is generated. If <code class="n">paramForError</code> is {{code|lua|true}}, a generic error message mentioning the bad code is generated; otherwise <code class="n">paramForError</code> should be a string or number specifying the parameter that the code came from, and this parameter will be mentioned in the error message along with the bad code. If <code class="n">allowEtymLang</code> is specified, etymology-only language codes are allowed and looked up along with normal language codes. If <code class="n">allowFamily</code> is specified, language family codes are allowed and looked up along with normal language codes.]==]
function export.getByCode(code, paramForError, allowEtymLang, allowFamily)
	-- Track uses of paramForError, ultimately so it can be removed, as error-handling should be done by [[Module:parameters]], not here.
	if paramForError ~= nil then
		track("paramForError")
	end
	if type(code) ~= "string" then
		local typ
		if not code then
			typ = "nil"
		elseif check_object("language", true, code) then
			typ = "a language object"
		elseif check_object("family", true, code) then
			typ = "a family object"
		else
			typ = "a " .. type(code)
		end
		error("The function getByCode expects a string as its first argument, but received " .. typ .. ".")
	end

	local m_data = load_data(languages_data_module)
	if m_data.aliases[code] or m_data.track[code] then
		track(code)
	end

	local norm_code = normalize_code(code)

	-- Get the data, checking for etymology-only languages if allowEtymLang is set.
	local data = load_data(get_data_module_name(norm_code))[norm_code] or
		allowEtymLang and load_data(etymology_languages_data_module)[norm_code]

	-- If no data was found and allowFamily is set, check the family data. If the main family data was found, make the object with [[Module:families]] instead, as family objects have different methods. However, if it's an etymology-only family, use make_object in this module (which handles object inheritance), and the family-specific methods will be inherited from the parent object.
	if data == nil and allowFamily then
		data = load_data("Module:families/data")[norm_code]
		if data ~= nil then
			if data.parent == nil then
				return make_family_object(norm_code, data)
			elseif not allowEtymLang then
				data = nil
			end
		end
	end

	local retval = code and data and make_object(code, data)

	if not retval and paramForError then
		require("Module:languages/errorGetBy").code(code, paramForError, allowEtymLang, allowFamily)
	end

	return retval
end
get_by_code = export.getByCode

--[==[Finds the language whose canonical name (the name used to represent that language on Wiktionary) or other name matches the one provided. If it exists, it returns a <code class="nf">Language</code> object representing the language. Otherwise, it returns {{code|lua|nil}}, unless <code class="n">paramForError</code> is given, in which case an error is generated. If <code class="n">allowEtymLang</code> is specified, etymology-only language codes are allowed and looked up along with normal language codes. If <code class="n">allowFamily</code> is specified, language family codes are allowed and looked up along with normal language codes.
The canonical name of languages should always be unique (it is an error for two languages on Wiktionary to share the same canonical name), so this is guaranteed to give at most one result.
This function is powered by [[Module:languages/canonical names]], which contains a pre-generated mapping of full-language canonical names to codes. It is generated by going through the [[:Category:Language data modules]] for full languages. When <code class="n">allowEtymLang</code> is specified for the above function, [[Module:etymology languages/canonical names]] may also be used, and when <code class="n">allowFamily</code> is specified for the above function, [[Module:families/canonical names]] may also be used.]==]
function export.getByCanonicalName(name, errorIfInvalid, allowEtymLang, allowFamily)
	local byName = load_data("Module:languages/canonical names")
	local code = byName and byName[name]

	if not code and allowEtymLang then
		byName = load_data("Module:etymology languages/canonical names")
		code = byName and byName[name] or
			byName[gsub(name, " [Ss]ubstrate$", "")] or
			byName[gsub(name, "^a ", "")] or
			byName[gsub(name, "^a ", ""):gsub(" [Ss]ubstrate$", "")] or
			-- For etymology families like "ira-pro".
			-- FIXME: This is not ideal, as it allows " languages" to be appended to any etymology-only language, too.
			byName[match(name, "^(.*) languages$")]
	end

	if not code and allowFamily then
		byName = load_data("Module:families/canonical names")
		code = byName[name] or byName[match(name, "^(.*) languages$")]
	end

	local retval = code and get_by_code(code, errorIfInvalid, allowEtymLang, allowFamily)

	if not retval and errorIfInvalid then
		require("Module:languages/errorGetBy").canonicalName(name, allowEtymLang, allowFamily)
	end

	return retval
end

--[==[Used by [[Module:languages/data/2]] (et al.) and [[Module:etymology languages/data]], [[Module:families/data]], [[Module:scripts/data]] and [[Module:writing systems/data]] to finalize the data into the format that is actually returned.]==]
function export.finalizeData(data, main_type, variety)
	local fields = {"type"}
	if main_type == "language" then
		insert(fields, 4) -- script codes
		insert(fields, "ancestors")
		insert(fields, "link_tr")
		insert(fields, "override_translit")
		insert(fields, "wikimedia_codes")
	elseif main_type == "script" then
		insert(fields, 3) -- writing system codes
	end -- Families and writing systems have no extra fields to process.
	local fields_len = #fields
	for _, entity in next, data do
		if variety then
			-- Move parent from 3 to "parent" and family from "family" to 3. These are different for the sake of convenience, since very few varieties have the family specified, whereas all of them have a parent.
			entity.parent, entity[3], entity.family = entity[3], entity.family
		-- Give the type "regular" iff not a variety and no other types are assigned.
		elseif not (entity.type or entity.parent) then
			entity.type = "regular"
		end
		for i = 1, fields_len do
			local key = fields[i]
			local field = entity[key]
			if field and type(field) == "string" then
				entity[key] = gsub(field, "%s*,%s*", ",")
			end
		end
	end
	return data
end

--[==[For backwards compatibility only; modules should require the error themselves.]==]
function export.err(lang_code, param, code_desc, template_tag, not_real_lang)
	return require("Module:languages/error")(lang_code, param, code_desc, template_tag, not_real_lang)
end

return export
