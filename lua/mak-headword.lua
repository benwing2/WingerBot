local export = {}
local pos_functions = {}

local force_cat = false -- for testing; if true, categories appear in non-mainspace pages

local headword_utilities_module = "Module:headword utilities"
local languages_module = "Module:languages"

local lang = require(languages_module).getByCode("mak")

local insert = table.insert
local ugsub = mw.ustring.gsub
local ufind = mw.ustring.find
local usub = mw.ustring.sub

-- Function to remove stress accents since suffixation regularizes stress
local function remove_accents(text)
	text = ugsub(text, "[áàâä]", "a")
	text = ugsub(text, "[éèêë]", "e")
	text = ugsub(text, "[íìîï]", "i")
	text = ugsub(text, "[óòôö]", "o")
	text = ugsub(text, "[úùûü]", "u")
	return text
end

--[==[
Main entry point. Takes these params:
; {{para|1}}
: The part of speech, pluralized; omit for {{tl|mak-head}}.
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
		infls = {
			{"lon", label = "Lontara spelling",
				resolve_special = function(termdata)
					if termdata.sc:getCode() == "Latn" then
						local tr_bugi = require("Module:mak-Latn-Bugi-translit").tr(termdata.head, "mak", "Latn")
						local tr_maka = require("Module:mak-Latn-Maka-translit").tr(termdata.head, "mak", "Latn")
						local lons = {}
						if tr_bugi then
							insert(lons, tr_bugi)
						end
						if tr_maka then
							insert(lons, tr_maka)
						end
						return lons
					else
						error(("Unable to form default Lontara spelling for non-Latin head '%s'"):format(termdata.head))
					end
				end,
				default = function(data)
					if data.sc:getCode() == "Latn" then
						return "+"
					end
				end,
				process_after_parse = function(data, vals)
					if data.sc:getCode() == "Latn" then
						local tr_bugi, tr_maka
						for _, val in ipairs(vals) do
							if val.origin ~= "default" and val.origin ~= "resolve_special" then
								if tr_bugi == nil then
									tr_bugi	= require("Module:mak-Latn-Bugi-translit").tr(data.pagename, "mak", "Latn") or false
									tr_maka = require("Module:mak-Latn-Maka-translit").tr(data.pagename, "mak", "Latn") or false
								end
								if val.term == tr_bugi or val.term == tr_maka then
									data:track("redundant-lon")
								else
									data:track("nonredundant-lon")
								end
							end
						end
					end
					return vals
				end,
			},
		},
		augment_headdata = function(data)
			if data.var == nil then
				data.var = data.sc:getCode() ~= "Latn"
			end
		end,
	}
end

pos_functions["verbs"] = {
	infls = {
		{"st", label = "semi-transitive"},
		{"pass", label = "passive",
			default = function(data)
				-- If Latin and no passive (and also only if a semi-transitive exists; why do we do this?),
				-- add a default passive.
				if data.sc:getCode() == "Latn" then
					local st_insert_spec = data.process_props.insert_specs.st
					if st_insert_spec and st_insert_spec ~= "no" then
						return "+"
					end
				end
			end,
			resolve_special = function(termdata)
				return "ni" .. termdata.head
			end,
		}
	}
}

pos_functions["nouns"] = {
	infls = {
		{"def", label = "definite",
			default = function(data)
				if data.sc:getCode() == "Latn" then
					return "+"
				end
			end,
			resolve_special = function(termdata)
				local head = remove_accents(termdata.head)
				local last_char = usub(head, -1)
				local def_form
				if last_char == "a" then
					def_form = head .. "ya"
				elseif last_char:find("[eiou]") then
					def_form = head .. "a"
				elseif ufind(last_char, "[ʼ'’]") then
					def_form = usub(head, 1, -2) .. "ka"
				else
					def_form = head .. "a"
				end
				return def_form
			end,
		},
		{"pass", label = "3rd person possessive",
			default = function(data)
				if data.sc:getCode() == "Latn" then
					return "+"
				end
			end,
			resolve_special = function(termdata)
				local head = remove_accents(termdata.head)
				local last_char = usub(head, -1)
				local infl = termdata.infl.term
				if infl == "+nna" then
					return head .. "nna"
				elseif infl == "+na" then
					return head .. "na"
				elseif last_char:find("[aeiou]") then
					if infl == "+" and termdata.infl.origin ~= "default" then
						error(("Head %s ends in a vowel; no default available, specify either `+na`, `+nna` or `+nna,+na` for both"):format(termdata.head))
					else
						return nil
					end
				elseif head:find("ng$") then
					return usub(head, 1, -3) .. "nna"
				else
					return head .. "na"
				end
			end,
			is_special = function(data, infl)
				local term = infl.term
				return term == "+" or term == "+nna" or term == "+na"
			end,
		},
	}
}

pos_functions["adjectives"] = {
	infls = {
		-- Manual input for stative/adjectival prefix ma- (e.g., |ma=mabajiʼ or simply |mabajiʼ as 1st parameter)
		{"ma", label = "stative"},
	},
}

return export
