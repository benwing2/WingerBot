local export = {}

local languages_module = "Module:languages"
local pron_utilities_module = "Module:pron utilities"
local string_utilities_module = "Module:string utilities"

local m_str_utils = require(string_utilities_module)

local ugsub = m_str_utils.gsub
local ulower = m_str_utils.lower

local insert = table.insert

local function rsub(text, from, to)
	return (ugsub(text, from, to)) -- Discard second return value
end

local function respelling_to_IPA(data)
	local input = data.respelling
	local stress = data.item.stress
	
	input = ulower(input)
		-- replace hard-to-manipulate Unicode chars with ASCII substitutes
		:gsub("ā", "A"):gsub("ē", "E"):gsub("ī", "I"):gsub("ō", "O"):gsub("ū", "U")
	-- test for unknown inputs; `#` replaced at end
	input = rsub(input, "[^aeiouAEIOUhkmngprtw/%[%]ˈˌ.%-%s]", "#")
	input = input
		-- replace hyphens
		:gsub("%-", " ")
		-- syllabify
		:gsub("([aeiouAEIOU])", "%1.")

	-- /phonemic/
	local phonemic = input
		:gsub("a", "a")
		:gsub("A", "aː")
		:gsub("e", "e")
		:gsub("E", "eː")
		:gsub("i", "i")
		:gsub("I", "iː")
		:gsub("o", "o")
		:gsub("O", "oː")
		:gsub("u", "u")
		:gsub("U", "uː")
		:gsub("r", "r")
		:gsub("wh", "ɸ")
		:gsub("ng", "ŋ")

	-- [phonetic]
	local phonetic = input
		:gsub("a", "ɐ")
		:gsub("A", "ɑː")
		:gsub("e", "ɛ")
		:gsub("E", "eː")
		:gsub("i", "i")
		:gsub("I", "iː")
		:gsub("o", "ɔ")
		:gsub("O", "oː")
		:gsub("u", "ʉ")
		:gsub("U", "uː")
		:gsub("r", "ɾ")
		:gsub("wh", "f")
		:gsub("ng", "ŋ")

	-- add stress marks if applicable
	if stress then
		local index = 0

		-- loop through `stress` param, creating an array
		local stresses = {}
		for char in stress:gmatch("[',.-]") do
			index = index + 1
			local norm_char = char:gsub("'", "ˈ"):gsub(",", "ˌ"):gsub("-", "")--:gsub(".", ".")
			table.insert(stresses, norm_char)
		end

		-- loop through syllables in /phonemic/ representation, adding stress markers
		local stressed_phonemic = ""
		index = 0
		for syll in phonemic:gmatch("[^.%s]+") do
			index = index + 1
			stressed_phonemic = stressed_phonemic .. (stresses[index] or ".") .. syll
		end
		phonemic = stressed_phonemic

		-- loop through syllables in [phonetic] representation, adding stress markers
		local stressed_phonetic = ""
		index = 0
		for syll in phonetic:gmatch("[^.%s]+") do
			index = index + 1
			stressed_phonetic = stressed_phonetic .. (stresses[index] or ".") .. syll
		end
		phonetic = stressed_phonetic
	end

	local categories = {}

	-- test for unknown inputs
	if phonemic:find("#") then
		phonemic = phonemic:gsub("#", "[invalid input]")
		insert(categories, "Maori terms with invalid IPA pronunciation")
	end
	if phonetic:find("#") then
		phonetic = phonetic:gsub("#", "[invalid input]")
		insert(categories, "Maori terms with invalid IPA pronunciation")
	end
	
	-- clean up results
	phonemic = phonemic:gsub("^%.", ""):gsub("%.$", ""):gsub("%.%s", " ")
	phonetic = phonetic:gsub("^%.", ""):gsub("%.$", ""):gsub("%.%s", " ")

	return ("/%s/ [%s]"):format(phonemic, phonetic), categories
end

function export.ipa(frame)
	local parent_args = frame:getParent().args

	local augment_param_mod_spec = {
		{param = "stress"},
	}

	return require(pron_utilities_module).format_prons {
		lang = require(languages_module).getByCode("mi"),
		respelling_to_IPA = respelling_to_IPA,
		raw_args = parent_args,
		augment_param_mod_spec = augment_param_mod_spec,
		track_module = "mi-IPA",
	}
end

return export
