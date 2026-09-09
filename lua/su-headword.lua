local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"

local lang = require(languages_module).getByCode("su")

local usub = mw.ustring.sub

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
			data.params.sun = true
		end,
		augment_headdata = function(data)
			local headdata = data.headdata
			local sc = headdata.sc
			if headdata.var == nil then
				headdata.var = sc:getCode() ~= "Latn"
			end
			local suns = headdata:parse_inflection("sun")
			if sc:getCode() == "Latn" then
				local tr_sund = require("Module:su-Latn-Sund-translit").tr(headdata.pagename)
				if suns[1] then
					for _, sun in ipairs(suns[1]) do
						if sun.term == tr_sund then
							headdata:track("redundant-sun")
						else
							headdata:track("nonredundant-sun")
						end
					end
				elseif tr_sund then
					suns[1] = {term = tr_sund}
				end
			end
			headdata:insert_inflection(suns, "Sundanese spelling")
		end,
	}
end

pos_functions["verbs"] = {
	params = {
		act = true,
		pass = true,
	},
	func = function(data, args)
		local activeobjs = data:parse_inflection("act")
		activeobjs = data:resolve_special(activeobjs, function(termdata)
			local head = termdata.head
			local active_form

			-- Count vowels
			local vowel_count = #head:gsub("[^aeiou]", "")
			if vowel_count == 1 then
				active_form = "nge" .. head
			else
				local first_two = usub(head, 1, 2)
				local first = usub(head, 1, 1)

				if first_two == "sy" then
					-- FIXME, are we sure this hyphen is correct?
					active_form = "nga-" .. head
				elseif first_two == "pl" then
					active_form = "nga" .. head
				elseif first_two == "pr" then
					active_form = "nga" .. head
				elseif first_two == "tr" then
					active_form = "nga" .. head
				elseif first_two == "kl" then
					active_form = "nga" .. head
				elseif first_two == "kr" then
					active_form = "nga" .. head
				elseif first_two == "kh" then
					active_form = "nga" .. head
				elseif first == "k" then
					active_form = "ng" .. usub(head, 2)
				elseif first == "t" then
					active_form = "n" .. usub(head, 2)
				elseif first == "s" then
					active_form = "ny" .. usub(head, 2)
				elseif first == "c" then
					active_form = "ny" .. usub(head, 2)
				elseif first == "p" then
					active_form = "m" .. usub(head, 2)
				elseif first:match("[aiueo]") then
					active_form = "ng" .. head
				else
					active_form = "nga" .. head
				end
			end

			return active_form
		end)
		data:insert_inflection(activeobjs, "active")

		local passiveobjs = data:parse_inflection("pass")
		if args.act and not passiveobjs[1] then
			passiveobjs[1] = {term = "+"}
		end
		passiveobjs = data:resolve_special(passiveobjs, function(termdata)
			return "di" .. termdata.head
		end)
		data:insert_inflection(passiveobjs, "passive")
	end,
}

pos_functions["nouns"] = {
	params = {
		def = true,
	},
	func = function(data, _args)
		data:parse_and_insert_inflection("def", "definite")
	end
}

pos_functions["proper nouns"] = pos_functions["nouns"]

return export
