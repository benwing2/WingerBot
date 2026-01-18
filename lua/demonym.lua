local export = {}

local force_cat = false -- set to true for testing

local form_of_module = "Module:form of"
local place_module = "Module:place"
local pron_qualifier_module = "Module:pron qualifier"
local qualifier_module = "Module:qualifier"
local utilities_module = "Module:utilities"
local table_module = "Module:table"

local m_links = require("Module:links")
local m_languages = require("Module:languages")
local lang_en = m_languages.getByCode("en")

local dump = mw.dumpObject
local insert = table.insert


-- Add qualifiers, labels and references to a formatted part. `part` is the object describing the unformatte part, which
-- should optionally contain:
-- * left qualifiers in `q`, an array of strings;
-- * right qualifiers in `qq`, an array of strings;
-- * left labels in `l`, an array of strings;
-- * right labels in `ll`, an array of strings;
-- * references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
--   (formatted reference text) and optionally `name` and/or `group`;
-- `formatted` is the formatted version of the term itself, and `lang` is the optional language object passed into
-- format_genders().
local function add_qualifiers_and_refs(formatted, part)
	local function field_non_empty(field)
		local list = part[field]
		if not list then
			return nil
		end
		if type(list) ~= "table" then
			error(("Internal error: Wrong type for `spec.%s`=%s, should be \"table\""):format(
				field, mw.dumpObject(list)))
		end
		return list[1]
	end

	if field_non_empty("q") or field_non_empty("qq") or field_non_empty("l") or field_non_empty("ll") or
		field_non_empty("refs") then
		formatted = require(pron_qualifier_module).format_qualifiers {
			lang = part.lang,
			text = formatted,
			q = part.q,
			qq = part.qq,
			l = part.l,
			ll = part.ll,
			refs = part.refs,
		}
	end

	return formatted
end

local function link_with_qualifiers(part, face, pretext)
	local retval = m_links.full_link(part, face, "allow self link")
	if pretext then
		retval = pretext .. retval
	end
	return add_qualifiers_and_refs(retval, part)
end


local function format_glosses(data, gloss_pretext)
	local has_gloss = data.gloss and data.gloss[1]

	if data.lang:getCode() == "en" then
		if has_gloss then
			local glosstext
			if not data.gloss[2] then
				glosstext = ("an English gloss '%s'"):format(data.gloss[1].term)
			else
				for i, term in ipairs(data.gloss) do
					data.gloss[i] = "'" .. term.term .. "'"
				end
				glosstext = ("English glosses %s"):format(table.concat(data.gloss, ", "))
			end
			error(("Can't specify %s for the term when the language is already English"):format(glosstext))
		end
		return ""
	elseif has_gloss then
		if data.notext then
			error("Can't specify gloss along with notext=")
		end
		for i, gloss in ipairs(data.gloss) do
			gloss.lang = gloss.lang or lang_en
			data.gloss[i] = link_with_qualifiers(gloss, nil, gloss_pretext)
		end
		return table.concat(data.gloss, ", ")
	else
		return ""
	end
end


local function format_parts(data)
	local comma_in_part = false
	local cats = {}
	local full_langcode = data.lang:getFullCode()

	for i, part in ipairs(data.parts) do
		part.lang = part.lang or lang_en
		local display = part.alt or part.term
		if display then
			display = m_links.remove_links(display)
			if display:find(",") then
				comma_in_part = true
			end
		end
		if part.gloss then
			-- move gloss to 'pos' so it doesn't have quotes around it
			if part.pos then
				part.pos = part.gloss .. ", " .. part.pos
			else
				part.pos = part.gloss
			end
			part.gloss = nil
		end
		local function has_comma_or_multiple(field)
			return part[field] and (part[field][2] or part[field][1] and part[field][1]:find(","))
		end
		comma_in_part = comma_in_part or (part.pos and part.pos:find(",")) or
			has_comma_or_multiple("q") or has_comma_or_multiple("qq") or
			has_comma_or_multiple("l") or has_comma_or_multiple("ll")
		local formatted_desc
		if part.term and part.term:find("<<") then
			local m_place = require(place_module)
			local place_desc = m_place.parse_new_style_place_desc(part.term)
			formatted_desc = m_place.format_new_style_place_desc_for_display({}, place_desc, false)
			if not data.nocat then
				local this_cats = m_place.get_cats({}, {lang = data.lang, descs = place_desc}, "from demonym")
				for _, cat in ipairs(this_cats) do
					insert(cats, full_langcode .. ":" .. cat)
				end
			end
			formatted_desc = add_qualifiers_and_refs(formatted_desc, part)
		else
			formatted_desc = link_with_qualifiers(part)
		end
		data.parts[i] = formatted_desc
	end

	local nparts = #data.parts
	local rettext
	-- FIXME: There should be a generalization of serialCommaJoin in [[Module:table]] for this use case.
	if nparts == 1 then
		rettext = data.parts[1]
	elseif nparts == 2 then
		rettext = data.parts[1] .. " or " .. data.parts[2]
	elseif comma_in_part then
		rettext = table.concat(data.parts, "; ", 1, nparts - 1) .. "; or " .. data.parts[nparts]
	else
		rettext = require(table_module).serialCommaJoin(data.parts, {conj = "or"})
	end
	return rettext, cats
end


-- WARNING: This overwrites objects in `data`.
function export.format_demonym_adj(data)
	local result = {}
	local cats = {}

	local function ins(text)
		insert(result, text)
	end

	local full_langcode = data.lang:getFullCode()
	local lang_is_en = full_langcode == "en"

	if not data.nocat then
		insert(cats, full_langcode .. ":Demonyms")
	end

	local glosstext = format_glosses(data)
	ins(glosstext)
	if glosstext ~= "" then
		ins(" (")
	end

	if not data.notext then
		if glosstext == "" and lang_is_en and not data.nocap then
			ins("Of")
		else
			ins("of")
		end
		ins(", from or relating to ")
	end

	local parttext, partcats = format_parts(data)
	ins(parttext)
	if partcats[1] then
		require(table_module).extend(cats, partcats)
	end

	if glosstext ~= "" then
		ins(")")
	end

	if lang_is_en and not data.nodot and not data.notext then
		ins(".")
	end

	if not data.nocat then
		ins(require(utilities_module).format_categories(cats, data.lang, data.sort, nil, force_cat))
	end

	return table.concat(result)
end


-- WARNING: This overwrites objects in `data`.
function export.format_demonym_noun(data)
	local result = {}
	local cats = {}

	local function ins(text)
		insert(result, text)
	end

	local full_langcode = data.lang:getFullCode()
	local lang_is_en = full_langcode == "en"

	local has_femeq = data.m and data.m[1]
	data.g = data.g or has_femeq and "f" or nil

	if not data.nocat then
		insert(cats, full_langcode .. ":Demonyms")
		if data.derogatory then
			insert(cats, full_langcode .. ":Derogatory demonyms")
		end
		if data.g == "m" then
			insert(cats, full_langcode .. ":Male people")
		elseif data.g == "f" then
			insert(cats, full_langcode .. ":Female people")
		end
		if has_femeq then
			insert(cats, data.lang:getFullName() .. " female equivalent nouns")
		end
	end

	if has_femeq then
		if data.notext then
			error("Can't specify m= along with notext=")
		end
		for i, m in ipairs(data.m) do
			data.m[i].lang = data.m[i].lang or data.lang
		end
		local femeq_data = {
			text = (lang_is_en and not data.nocap and "Female" or "female") .. " equivalent of",
			lemmas = data.m,
			lemma_face = "term",
		}
		ins(require(form_of_module).format_form_of(femeq_data))
		ins("; ")
	end

	local glosstext = format_glosses(data, data.g == "f" and not data.gloss_is_gendered and "[[female]] " or nil)
	ins(glosstext)
	if lang_is_en and not data.notext then
		if not has_femeq and not data.nocap then
			ins("A ")
		else
			ins("a ")
		end
	elseif glosstext ~= "" then
		ins(" (")
	end

	if not data.notext then
		if data.g == "f" then
			ins("[[female]] ")
		end

		ins("[[native]] or [[inhabitant]] of ")
	end

	local parttext, partcats = format_parts(data)
	ins(parttext)
	if partcats[1] then
		require(table_module).extend(cats, partcats)
	end

	if glosstext ~= "" then
		ins(")")
	end

	if data.g == "m" and not data.notext then
		ins(" ")
		ins(require(qualifier_module).format_qualifier("usually male"))
	end

	if lang_is_en and not data.nodot and not data.notext then
		ins(".")
	end

	if not data.nocat then
		ins(require(utilities_module).format_categories(cats, data.lang, data.sort, nil, force_cat))
	end

	return table.concat(result)
end

return export
