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
		augment_params = function(data)
			data.params.lon = true
		end,
		augment_headdata = function(data)
			local headdata = data.headdata
			local sc = headdata.sc
			if headdata.var == nil then
				headdata.var = sc:getCode() ~= "Latn"
			end
			local lons = headdata:parse_inflection("lon")
			if sc:getCode() == "Latn" then
				local tr_bugi = require("Module:mak-Latn-Bugi-translit").tr(headdata.pagename, "mak", sc:getCode())
				local tr_maka = require("Module:mak-Latn-Maka-translit").tr(headdata.pagename, "mak", sc:getCode())
				if lons[1] then
					for _, lon in ipairs(lons) do
						if lon.term == tr_bugi or lon.term == tr_maka then
							headdata:track("redundant-lon")
						else
							headdata:track("nonredundant-lon")
						end
					end
				else
					if tr_bugi then
						insert(lons, {term = tr_bugi})
					end
					if tr_maka then
						insert(lons, {term = tr_maka})
					end
				end
			end
			headdata:insert_inflection(lons, "Lontara spelling")
		end,
	}
end

pos_functions["verbs"] = {
	params = {
		st = true,
		pass = true,
	},
	func = function(data, args)
		data:parse_and_insert_inflection("st", "semi-transitive")
		local passobjs = data:parse_inflection("pass")
		if args.st and not passobjs[1] and data.sc:getCode() == "Latn" then
			-- If Latin and no passive (and also only if a semi-transitive exists; why do we do this?),
			-- add a default passive.
			passobjs[1] = {term = "+"}
		end
		passobjs = data:resolve_special(passobjs, function(termdata)
			return "ni" .. termdata.head
		end)
		data:insert_inflection(passobjs, "passive")
	end
}

pos_functions["nouns"] = {
	params = {
		def = true,
		poss = true,
	},
	func = function(data, _args)
		if data.sc:getCode() == "Latn" then
			local defobjs = data:parse_inflection("def")
			if not defobjs[1] then
				defobjs = {{term = "+"}}
			end
			defobjs = data:resolve_special(defobjs, function(termdata)
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
			end)
			data:insert_inflection(defobjs, "definite")

			local possobjs = data:parse_inflection("poss")
			if not possobjs[1] then
				possobjs = {{term = "+def"}}
			end
			possobjs = data:resolve_special(possobjs, function(termdata)
				local head = remove_accents(termdata.head)
				local last_char = usub(head, -1)
				local infl = termdata.infl.term
				if infl == "+nna" then
					return head .. "nna"
				elseif infl == "+na" then
					return head .. "na"
				elseif last_char:find("[aeiou]") then
					if infl == "+" then
						error(("Head %s ends in a vowel; no default available, specify either `+na`, `+nna` or `+nna,+na` for both"):format(termdata.head))
					else
						return nil
					end
				elseif head:find("ng$") then
					return usub(head, 1, -3) .. "nna"
				else
					return head .. "na"
				end
			end, {
				is_special = function(inflobj)
					local term = inflobj.term
					return term == "+nna" or term == "+na" or term == "+" or term == "+def"
				end,
			})
			data:insert_inflection(possobjs, "3rd person possessive")
		else
			data:parse_and_insert_inflection("def", "definite")
			data:parse_and_insert_inflection("poss", "3rd person possessive")
		end
	end
}

pos_functions["adjectives"] = {
	params = {
		ma = true,
	},
	func = function(data, _args)
		-- Manual input for stative/adjectival prefix ma- (e.g., |ma=mabajiʼ or simply |mabajiʼ as 1st parameter)
		data:parse_and_insert_inflection("ma", "stative")
	end
}

return export
