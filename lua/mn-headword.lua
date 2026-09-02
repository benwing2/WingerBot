local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"
local mn = require("Module:mn-common")

local lang = require(languages_module).getByCode("mn")

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|mn-head}}.
; {{para|def}}
: Optional default value for the template page.
]==]
function export.show(frame)
	return require(headword_utilities_module).process_headword {
		lang = lang,
		frame = frame,
		pos_functions = pos_functions,
		include_tr = true,
		include_sc = true,
		force_cat = force_cat,
		augment_params = function(data)
			local other_script_index = data.pos_in_1 and 2 or 1
			data.params[other_script_index] = true
		end,
		augment_headdata = function(data)
			local headdata = data.headdata
			local other_script_index = data.pos_in_1 and 2 or 1
			local other_scripts = headdata:parse_inflection(other_script_index)
			if other_scripts[1] then
				local heading
				for i, other_script in ipairs(other_scripts) do
					local other_sc = lang:findBestScript(other_script.term)
					local this_name = other_sc:getCanonicalName(lang)
					if i == 1 then
						heading = this_name .. " spelling"
					end
					if headdata.sc:getCode() == other_sc:getCode() then
						error(("The headword and alternative spelling %s are both in %s but should be in different scripts"):format(
							other_script.term, this_name
						))
					end
					headdata:insert_inflection(other_scripts, heading, {
						enable_auto_translit = true,
					})
				end
			end
			if not headdata.pagename:find("^%-") and not headdata.pagename:find(" ") and headdata.sc:getCode() == "Cyrl" then
				-- FIXME, should be done by {{mn-IPA}}
				headdata:insert_category(#mn.syllables(headdata.pagename) .. "-syllable words")
			end
		end,
	}
end

pos_functions["nouns"] = {
	params = {
		pl = true,
		dec = {set = {"r", "n", "g", "m"}},
	},
	func = function(data, args)
		data:parse_and_insert_inflection("pl", "definite plural")
		if args.dec then
			local declension
			if args.dec == "r" then
				declension = "regular declension"
			elseif args.dec == "n" then
				declension = "hidden-n declension"
			elseif args.dec == "g" then
				declension = "hidden-g declension"
			elseif args.dec == "m" then
				declension = "mixed declension"
			else
				error(("Internal error: Unrecognized declension value: dec=%s"):format(args.dec))
			end
			data:insert_category(declension .. " PLPOS")
			data:insert_fixed_inflection(declension)
		end
	end,
}
pos_functions["proper nouns"] = pos_functions["nouns"]

pos_functions["verbs"] = {
	params = {
		caus = true,
		pass = true,
	},
	func = function(data, args)
		data:parse_and_insert_inflection("caus", "causative")
		data:parse_and_insert_inflection("pass", "passive")
	end
}

return export
