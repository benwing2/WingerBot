local export = {}

function export.ipa(frame)

	local args = frame:getParent().args
	local titleData = mw.title.getCurrentTitle()
	local input = args[1] or titleData.text
	local stress = args['stress']
	
	input = input:lower()
		-- replace hard-to-manipulate Unicode chars with ASCII substitutes
		:gsub("ā", "A"):gsub("ē", "E"):gsub("ī", "I"):gsub("ō", "O"):gsub("ū", "U")
		-- test for unknown inputs; `#` replaced at end
		:gsub("[^aeiouAEIOUhkmngprtw/%[%]ˈˌ.%-%s]", "#")
		-- replace hyphens
		:gsub("-", " ")
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

	-- [real]
	local real = input
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

		-- loop through syllables in [real] representation, adding stress markers
		local stressed_real = ""
		index = 0
		for syll in real:gmatch("[^.%s]+") do
			index = index + 1
			stressed_real = stressed_real .. (stresses[index] or ".") .. syll
		end
		real = stressed_real
	end

	-- test for unknown inputs
	local errorText = "[invalid input]"
	if titleData.namespace == 0 then
		errorText = errorText .. "[[Category:Maori terms with invalid IPA pronunciation]]"
	end
	phonemic = phonemic:gsub("#", errorText)
	real = real:gsub("#", errorText)
	
	-- clean up results
	phonemic = phonemic:gsub("^%.", ""):gsub("%.$", ""):gsub("%.%s", " ")
	real = real:gsub("^%.", ""):gsub("%.$", ""):gsub("%.%s", " ")

	-- create output
	local prefix = "[[Wiktionary:International Phonetic Alphabet|IPA]]<sup>([[w:Māori phonology|key]])</sup>: "
	local output = "<span class='IPA'>" .. "/" .. phonemic .. "/, [" .. real .. "]" .. "</span>"
	local category = titleData.namespace == 0 and "[[Category:Maori terms with IPA pronunciation]]" or ""
	return prefix .. output .. category

end

return export
