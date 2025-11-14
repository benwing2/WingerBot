local export = {}

-- For testing
local force_cat = false

local debug_track_module = "Module:debug/track"
local languages_module = "Module:languages"
local links_module = "Module:links"
local pron_qualifier_module = "Module:pron qualifier"
local table_module = "Module:table"
local utilities_module = "Module:utilities"

local concat = table.concat
local insert = table.insert
local new_title = mw.title.new

local function debug_track(...)
	debug_track = require(debug_track_module)
	return debug_track(...)
end

local function format_categories(...)
	format_categories = require(utilities_module).format_categories
	return format_categories(...)
end

local function format_qualifiers(...)
	format_qualifiers = require(pron_qualifier_module).format_qualifiers
	return format_qualifiers(...)
end

local function full_link(...)
	full_link = require(links_module).full_link
	return full_link(...)
end

local function get_language_data_module_name(...)
	get_language_data_module_name = require(languages_module).getDataModuleName
	return get_language_data_module_name(...)
end

local function get_link_page(...)
	get_link_page = require(links_module).get_link_page
	return get_link_page(...)
end

local function language_link(...)
	language_link = require(links_module).language_link
	return language_link(...)
end

local function serial_comma_join(...)
	serial_comma_join = require(table_module).serialCommaJoin
	return serial_comma_join(...)
end

local function shallow_copy(...)
	shallow_copy = require(table_module).shallowCopy
	return shallow_copy(...)
end

local function track(page, code)
	local tracking_page = "etymology/" .. page
	debug_track(tracking_page)
	if code then
		debug_track(tracking_page .. "/" .. code)
	end
end

local function join_segs(segs, conj)
	if not segs[2] then
		return segs[1]
	elseif conj == "and" or conj == "or" then
		return serial_comma_join(segs, {conj = conj})
	end
	local sep
	if conj == "," or conj == ";" then
		sep = conj .. " "
	elseif conj == "/" then
		sep = "/"
	elseif conj == "~" then
		sep = " ~ "
	elseif conj then
		error(("Internal error: Unrecognized conjunction \"%s\""):format(conj))
	else
		error(("Internal error: No value supplied for conjunction"):format(conj))
	end
	return concat(segs, sep)
end

-- Returns true if `lang` is the same as `source`, or a variety of it.
local function lang_is_source(lang, source)
	return lang:getCode() == source:getCode() or lang:hasParent(source)
end

-- Format one or more links as specified in `termobjs`, a list of term objects of the format accepted by full_link() in
-- [[Module:links]], additionally with optional qualifiers, labels and references. `conj` is used to join multiple
-- terms and must be specified if there is more than one term. `template_name` is the template name used in debug
-- tracking and must be specified. The return value begins with a space if there is anything to display (which is always
-- the case unless there is a single term with the value "-").
function export.format_links(termobjs, conj, template_name)
	for i, termobj in ipairs(termobjs) do
		local term = termobj.term
		if termobj.lang:hasType("family") then
			if term and term ~= "-" then
				debug_track(template_name .. "/family-with-term")
			end
			term = "-"
			termobj.term = term
		end
		template_name = template_name or "derived"
		if term == "-" then
			--[=[
			[[Special:WhatLinksHere/Wiktionary:Tracking/cognate/no-term]]
			[[Special:WhatLinksHere/Wiktionary:Tracking/derived/no-term]]
			[[Special:WhatLinksHere/Wiktionary:Tracking/borrowed/no-term]]
			[[Special:WhatLinksHere/Wiktionary:Tracking/calque/no-term]]
			]=]
			debug_track(template_name .. "/no-term")
			termobjs[i] = ""
		else
			termobjs[i] = full_link(termobj, "term", nil, "show qualifiers")
		end
	end

	local retval = join_segs(termobjs, conj)
	if retval ~= "" then
		retval = " " .. retval
	end
	return retval
end

function export.get_display_and_cat_name(source, raw)
	local display, cat_name
	if source:getCode() == "und" then
		display = "undetermined"
		cat_name = "other languages"
	elseif source:getCode() == "mul" then
		display = raw and "translingual" or "[[w:Translingualism|translingual]]"
		cat_name = "Translingual"
	elseif source:getCode() == "mul-tax" then
		display = raw and "taxonomic name" or "[[w:Biological nomenclature|taxonomic name]]"
		cat_name = "taxonomic names"
	else
		display = raw and source:getCanonicalName() or source:makeWikipediaLink()
		cat_name = source:getDisplayForm()
	end
	return display, cat_name
end

function export.insert_source_cat_get_display(data)
	local categories, lang, source = data.categories, data.lang, data.source
	local display, cat_name = export.get_display_and_cat_name(source, data.raw)

	if lang and not data.nocat then
		-- Add the category, but only if there is a current language
		if not categories then
			categories = {}
		end

		local langname = lang:getFullName()
		-- If `lang` is an etym-only language, we need to check both it and its parent full language against `source`.
		-- Otherwise if e.g. `lang` is Medieval Latin and `source` is Latin, we'll end up wrongly constructing a
		-- category 'Latin terms derived from Latin'.
		insert(categories, langname .. (
			lang_is_source(lang, source) and " terms borrowed back into " .. cat_name or
			" " .. (data.borrowing_type or "terms derived") .. " from " .. cat_name
		))
	end

	return display, categories
end

function export.format_source(data)
	local lang, sort_key = data.lang, data.sort_key
	-- [[Special:WhatLinksHere/Wiktionary:Tracking/etymology/sortkey]]
	if sort_key then
		track("sortkey")
	end

	local display, categories = export.insert_source_cat_get_display(data)
	if lang and not data.nocat then
		-- Format categories, but only if there is a current language; {{cog}} currently gets no categories
		categories = format_categories(categories, lang, sort_key, nil, data.force_cat or force_cat)
	else
		categories = ""
	end
	
	return "<span class=\"etyl\">" .. display .. categories .. "</span>"
end

--[==[
Format sources for etymology templates such as {{tl|bor}}, {{tl|der}}, {{tl|inh}} and {{tl|cog}}. There may potentially
be more than one source language (except currently {{tl|inh}}, which doesn't support it because it doesn't really
make sense). In that case, all but the last source language is linked to the first term, but only if there is such a
term and this linking makes sense, i.e. either (1) the term page exists after stripping diacritics according to the
source language in question, or (2) the result of stripping diacritics according to the source language in question
results in a different page from the same process applied with the last source language. For example, {{m|ru|соля́нка}}
will link to [[солянка]] but {{m|en|соля́нка}} will link to [[соля́нка]] with an accent, and since they are different
pages, the use of English as a non-final source with term 'соля́нка' will link to [[соля́нка]] even though it doesn't
exist, on the assumption that it is merely a redlink that might exist. If none of the above criteria apply, a non-final
source language will be linked to the Wikipedia entry for the language, just as final source languages always are.

`data` contains the following fields:
* `lang`: The destination language object into which the terms were borrowed, inherited or otherwise derived. Used for
          categorization and can be nil, as with {{tl|cog}}.
* `sources`: List of source objects. Most commonly there is only one. If there are multiple, the non-final ones are
             handled specially; see above.
* `terms`: List of term objects. Most commonly there is only one. If there are multiple source objects as well as
           multiple term objects, the non-final source objects link to the first term object.
* `sort_key`: Sort key for categories. Usually nil.
* `categories`: Categories to add to the page. Additional categories may be added to `categories` based on the source
                languages ('''in which case `categories` is destructively modified'''). If `lang` is nil, no categories
				will be added.
* `nocat`: Don't add any categories to the page.
* `sourceconj`: Conjunction used to separate multiple source languages. Defaults to {"and"}.
* `borrowing_type`: Borrowing type used in categories, such as {"learned borrowings"}. Defaults to {"terms derived"}.
* `force_cat`: Force category generation on non-mainspace pages.
]==]
function export.format_sources(data)
	local lang, sources, terms, borrowing_type, sort_key, categories, nocat =
		data.lang, data.sources, data.terms, data.borrowing_type, data.sort_key, data.categories, data.nocat
	local term1, sources_n, source_segs, final_link_page = terms[1], #sources, {}
	local term1_term, term1_sc = term1.term, term1.sc
	if sources_n > 1 and term1_term and term1_term ~= "-" then
		final_link_page = get_link_page(term1_term, sources[sources_n], term1_sc)
	end
	for i, source in ipairs(sources) do
		local seg, display_term
		if i < sources_n and term1_term and term1_term ~= "-" then
			local link_page = get_link_page(term1_term, source, term1_sc)
			display_term = (link_page ~= final_link_page) or (link_page and new_title(link_page).exists)
		end
		-- TODO: if the display forms or transliterations are different, display the terms separately.
		if display_term then
			local display, this_cats = export.insert_source_cat_get_display{
				lang = lang,
				source = source,
				borrowing_type = borrowing_type,
				raw = true,
				categories = categories,
				nocat = nocat,
			}
			seg = language_link{
				lang = source,
				term = term1_term,
				alt = display,
				tr = "-",
			}
			if lang and not nocat then
				-- Format categories, but only if there is a current language; {{cog}} currently gets no categories
				this_cats = format_categories(this_cats, lang, sort_key, nil, data.force_cat or force_cat)
			else
				this_cats = ""
			end
			seg = "<span class=\"etyl\">" .. seg .. this_cats .. "</span>"
		else
			seg = export.format_source{
				lang = lang,
				source = source,
				borrowing_type = borrowing_type,
				sort_key = sort_key,
				categories = categories,
				nocat = nocat,
			}
		end
		insert(source_segs, seg)
	end
	return join_segs(source_segs, data.sourceconj or "and")
end

-- Internal implementation of {{cognate}}/{{cog}} template.
function export.format_cognate(data)
	return export.format_derived{
		sources = data.sources,
		terms = data.terms,
		sort_key = data.sort_key,
		sourceconj = data.sourceconj,
		conj = data.conj,
		template_name = "cognate",
		force_cat = data.force_cat,
	}
end

-- Internal implementation of {{derived}}/{{der}} template. This is called externally from [[Module:affix]],
-- [[Module:affixusex]] and [[Module:see]] and needs to support qualifiers, labels and references on the outside
-- of the sources for use by those modules.
function export.format_derived(data)
	local terms = data.terms
	local result = export.format_sources(data) .. export.format_links(terms, data.conj, data.template_name)
	local q, qq, l, ll, refs = data.q, data.qq, data.l, data.ll, data.refs
	if q and q[1] or qq and qq[1] or l and l[1] or ll and ll[1] or refs and refs[1] then
		result = format_qualifiers{
			lang = terms[1].lang,
			text = result,
			q = q,
			qq = qq,
			l = l,
			ll = ll,
			refs = refs,
		}
	end
	return result
end

function export.insert_borrowed_cat(categories, lang, source)
	if lang_is_source(lang, source) then
		return
	end
	-- If both are the same, we want e.g. [[:Category:English terms borrowed back into English]] not
	-- [[:Category:English terms borrowed from English]]; the former is inserted automatically by format_source().
	-- The second parameter here doesn't matter as it only affects `display`, which we don't use.
	insert(categories, lang:getFullName() .. " terms borrowed from " .. select(2, export.get_display_and_cat_name(source, "raw")))
end

-- Internal implementation of {{borrowed}}/{{bor}} template.
function export.format_borrowed(data)
	local categories = {}

	if not data.nocat then
		local lang = data.lang
		for _, source in ipairs(data.sources) do
			export.insert_borrowed_cat(categories, lang, source)
		end
	end

	data = shallow_copy(data)
	data.categories = categories

	return export.format_sources(data) .. export.format_links(data.terms, data.conj, "borrowed")
end

do
	-- Generate the non-ancestor error message.
	local function show_language(lang)
		local retval = ("%s (%s)"):format(lang:makeCategoryLink(), lang:getCode())
		if lang:hasType("etymology-only") then
			retval = retval .. (" (an etymology-only language whose regular parent is %s)"):format(
				show_language(lang:getParent()))
		end
		return retval
	end
	
	-- Check that `lang` has `otherlang` (which may be an etymology-only language) as an ancestor. Throw an error if
	-- not.
	function export.check_ancestor(lang, otherlang)
		-- FIXME: I don't know if this function works correctly with etym-only languages in `lang`. I have fixed up
		-- the module link code appropriately (June 2024) but the remaining logic is untouched.
		if lang:hasAncestor(otherlang) then
			-- [[Special:WhatLinksHere/Wiktionary:Tracking/etymology/variety]]
			-- Track inheritance from varieties of Latin that shouldn't have any descendants (everything except Old Latin, Classical Latin and Vulgar Latin).
			if otherlang:getFullCode() == "la" then
				otherlang = otherlang:getCode()
				if not (otherlang == "itc-ola" or otherlang == "la-cla" or otherlang == "la-vul") then
					track("bad ancestor", otherlang)
				end
			end
			return
		end
		local ancestors, postscript = lang:getAncestors()
		local etym_module_link = lang:hasType("etymology-only") and "[[Module:etymology languages/data]] or " or ""
		local module_link = "[[" .. get_language_data_module_name(lang:getFullCode()) .. "]]"
		if not ancestors[1] then
			postscript = show_language(lang) .. " has no ancestors."
		else
			local ancestor_list = {}
			for _, ancestor in ipairs(ancestors) do
				insert(ancestor_list, show_language(ancestor))
			end
			postscript = ("The ancestor%s of %s %s %s."):format(
				ancestors[2] and "s" or "", lang:getCanonicalName(),
				ancestors[2] and "are" or "is", concat(ancestor_list, " and "))
		end
		error(("%s is not set as an ancestor of %s in %s%s. %s")
			:format(show_language(otherlang), show_language(lang), etym_module_link, module_link, postscript))
	end
end

-- Internal implementation of {{inherited}}/{{inh}} template.
function export.format_inherited(data)
	local lang, terms, sort_key, nocat = data.lang, data.terms, data.sort_key, data.nocat
	local source = terms[1].lang
	
	local categories = {}
	if not nocat then
		insert(categories, lang:getFullName() .. " terms inherited from " .. source:getCanonicalName())
	end

	export.check_ancestor(lang, source)

	return export.format_source{
		lang = lang,
		source = source,
		sort_key = sort_key,
		categories = categories,
		nocat = nocat,
		force_cat = data.force_cat,
	} .. export.format_links(terms, data.conj, "inherited")
	
end

-- Internal implementation of "misc variant" templates such as {{abbrev}}, {{clipping}}, {{reduplication}} and the like.
function export.format_misc_variant(data)
	local lang, notext, terms, cats, parts = data.lang, data.notext, data.terms, data.cats, {}

	if not notext then
		insert(parts, data.text)
	end
	if terms[1] then
		if not notext then
			insert(parts, " " .. (data.oftext or "of") .. " ")
		end
		insert(parts, export.format_links(terms, data.conj, "misc_variant"))
	end

	local categories = {}
	if not data.nocat and cats then
		for _, cat in ipairs(cats) do
			insert(categories, lang:getFullName() .. " " .. cat)
		end
	end
	if #categories > 0 then
		insert(parts, format_categories(categories, lang, data.sort_key, nil, data.force_cat or force_cat))
	end

	return concat(parts)
end

-- Implementation of miscellaneous templates such as {{unknown}} and {{onomatopoeia}} that have no associated terms.
function export.format_misc_variant_no_term(data)
	local parts = {}
	if not data.notext then
		insert(parts, data.title)
	end
	if not data.nocat and data.cat then
		local lang, categories = data.lang, {}
		insert(categories, lang:getFullName() .. " " .. data.cat)
		insert(parts, format_categories(categories, lang, data.sort_key, nil, data.force_cat or force_cat))
	end

	return concat(parts)
end

return export
