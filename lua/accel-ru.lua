--[[
Author: Benwing2

This module holds Russian-specific accelerator code.
]]

local com = require("Module:ru-common")
local m_links = require("Module:links")

local rfind = mw.ustring.find
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local function make_noun_decl(term, translit, form)
	local term_and_tr = com.combine_russian_tr(term, translit)
	if rfind(term, "[" .. com.cons .. "]ка$") then
		return term_and_tr .. "|*"
	elseif rfind(term, "[оё]́?к$") then
		return "b|" .. term_and_tr .. "|*"
	elseif rfind(term, "ость$") then
		return term_and_tr .. "|f"
	elseif rfind(term, "тель$") then
		return term_and_tr .. "|m"
	elseif rfind(term, "[ая]́?я$") and form == "f" then -- female equivalent
		return term_and_tr .. "|+"
	else
		-- FIXME, should we special-case diminutives in -ко? (often have plural in -ки)
		return term_and_tr
	end
end

return {generate = function (params, entry)
	local anntext = #params.seen_targets.array > 1 and "|ann=y" or ""
	local pronun_parts = {}
	local targets = {}
	for _, target in ipairs(params.targets) do
		local ru, tr = target.term, target.translit
		tr = tr and com.decompose(tr) or nil
		table.insert(targets, {ru, tr})
	end
	targets = com.split_translit_of_duplicate_forms(targets)
	for _, target in ipairs(targets) do
		-- FIXME, add |pos= if ends in -е
		local ru, tr, pron = unpack(target)
		ru = m_links.remove_links(ru)
		if tr then
			-- FIXME, if translit specified need to reverse-translit
			pron = "* {{ru-IPA|phon=" .. ru .. anntext .. "|FIXMETRANSLIT=" .. tr .. "}}"
		elseif ru == params.target_pagename then
			pron = "* {{ru-IPA" .. anntext .. "}}"
		else
			pron = "* {{ru-IPA|" .. ru .. anntext .. "}}"
		end
		table.insert(pronun_parts, pron)
	end
	entry.pronunc = table.concat(pronun_parts, "\n")

	if params.form == "comparative" then
		entry.pos_header = "Adverb"
		-- FIXME, support multiple targets in {{ru-comparative}}
		entry.head = "{{ru-comparative|" .. targets[1][1] .. (targets[1][2] and "|" .. targets[1][2] or "") .. "}}"
		entry.def = entry.make_def("comparative of", "|POS=" .. params.pos)
	elseif params.form == "superlative" and params.pos == "adjective" then
		local decl_parts = {}
		for _, target in ipairs(targets) do
			table.insert(decl_parts, com.combine_russian_tr(target))
		end
		entry.declension = "{{ru-decl-adj|" .. table.concat(decl_parts, ",") .. "|-}}"
	elseif params.pos == "noun" and (params.form == "f" or params.form == "diminutive" or params.form == "augmentative"
		or params.form == "pejorative" or params.form == "abstract noun" or params.form == "verbal noun") then
		-- A noun, not a noun form (inflection).
		local decl_parts = {}
		for _, target in ipairs(targets) do
			local ru, tr = unpack(target)
			table.insert(decl_parts, make_noun_decl(ru, tr, params.form))
		end
		local decl = table.concat(decl_parts, "|or|")
		local head_infls = ""
		-- FIXME, diminutives and augmentatives should propagate the lemma's animacy
		if params.form == "f" then
			decl = decl .. "|a=an"
			-- add original masculine as |m= param in {{ru-noun+}} for female equivalents
			local masc_parts = {}
			for i, origin in ipairs(params.origins) do
				local ru, tr = origin.term, origin.translit
				tr = tr and com.decompose(tr) or nil
				table.insert(masc_parts, "|m" .. (i == 1 and "" or i) .. "=" .. com.combine_russian_tr(ru, tr))
			end
			head_infls = table.concat(masc_parts)
		end
		entry.def = entry.def .. ": FIXME_DEFINITION"
		local fixme = "|FIXME=1"
		entry.head = "{{ru-noun+|" .. decl .. head_infls .. fixme .. "}}"
		entry.declension = "{{ru-noun-table|" .. decl .. fixme .. "}}"
	end
end}
