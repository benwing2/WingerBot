local export = {}

local debug_track_module = "Module:debug/track"
local descendants_tree_module = "Module:descendants tree"
local etymology_style_css = "Module:etymology/style.css"
local labels_module = "Module:labels"
local languages_module = "Module:languages"
local links_module = "Module:links"
local parse_utilities_module = "Module:parse utilities"
local pron_qualifier_module = "Module:pron qualifier"
local qualifier_module = "Module:qualifier"
local references_module = "Module:references"
local scripts_module = "Module:scripts"
local table_module = "Module:table"
local template_styles_module = "Module:TemplateStyles"

local concat = table.concat
local insert = table.insert
local rsplit = mw.text.split

local error_on_no_descendants = false

local function split_labels_on_comma(...)
	split_labels_on_comma = require(labels_module).split_labels_on_comma
	return split_labels_on_comma(...)
end

local function track(page)
	return require(debug_track_module)("descendant/" .. page)
end

local function ine(arg)
	if arg == "" then
		return nil
	else
		return arg
	end
end

local function add_tooltip(text, tooltip)
	return '<span class="desc-arr" title="' .. tooltip .. '">' .. text .. '</span>'
end

-- Boolean params indicating whether a descendant term (or all terms) are particular sorts of borrowings.
local bortypes = {"inh", "bor", "lbor", "slb", "obor", "translit", "der", "clq", "pclq", "sml", "unc"}
-- Aliases of clq=.
local calque_aliases = {"cal", "calq", "calque"}
-- Aliases of pclq=.
local partial_calque_aliases = {"pcal", "pcalq", "pcalque"}

--- Return a function of one argument `field` (a param name), which fetches `args`[`field`].default if index == 0, else
--- `container`[`field`].
local function get_val(container, args, index)
	return function(field)
		if index == 0 then
			return args[field].default
		else
			return container[field]
		end
	end
end

local function get_arrow(container, args, index)
	local val = get_val(container, args, index)
	local arrow

	if val("bor") then
		arrow = add_tooltip("→", "borrowed")
	elseif val("lbor") then
		arrow = add_tooltip("→", "learned borrowing")
	elseif val("slb") then
		arrow = add_tooltip("→", "semi-learned borrowing")
	elseif val("obor") then
		arrow = add_tooltip("→", "orthographic borrowing")
	elseif val("translit") then
		arrow = add_tooltip("→", "transliteration")
	elseif val("clq") then
		arrow = add_tooltip("→", "calque")
	elseif val("pclq") then
		arrow = add_tooltip("→", "partial calque")
	elseif val("sml") then
		arrow = add_tooltip("→", "semantic loan")
	elseif val("inh") or (val("unc") and not val("der")) then
		arrow = add_tooltip(">", "inherited")
	else
		arrow = ""
	end
	-- allow der=1 in conjunction with bor=1 to indicate e.g. English "pars recta"
	-- derived and borrowed from Latin "pars".
	if val("der") then
		arrow = arrow .. add_tooltip("⇒", "reshaped by analogy or addition of morphemes")
	end

	if val("unc") then
		arrow = arrow .. add_tooltip("?", "uncertain")
	end

	if arrow ~= "" then
		arrow = arrow .. " "
	end

	return arrow
end

-- Return the pre-qualifier text for the `index`th term, or the overall pre-qualifier text if index == 0.
local function get_pre_qualifiers_labels(container, args, index)
	if index > 0 then
		-- per term labels and qualifiers are handled at the subitem level, by full_link().
		return nil, nil
	end
	local val = get_val(container, args, index)
	return val("l"), val("q")
end

-- Return the post-qualifier text for the `index`th term, or the overall post-qualifier text if index == 0.
local function get_post_qualifiers_labels(container, args, index, lang)
	local val = get_val(container, args, index)
	local boolean_labels = {}

	if val("inh") then
		insert(boolean_labels, "inherited")
	end
	if val("lbor") then
		insert(boolean_labels, "learned")
	end
	if val("slb") then
		insert(boolean_labels, "semi-learned")
	end
	if val("translit") then
		insert(boolean_labels, "transliteration")
	end
	if val("clq") then
		insert(boolean_labels, "calque")
	end
	if val("pclq") then
		insert(boolean_labels, "partial calque")
	end
	if val("sml") then
		insert(boolean_labels, "semantic loan")
	end
	if index > 0 then
		-- per term labels, qualifiers and references are handled at the subitem level, by full_link().
		return boolean_labels
	else
		local quals, refs, dash_labels
		quals = val("qq")
		if val("ll") then
			-- Convert a raw l=/ll= param (or nil) to a list of label info objects of the format described in
			-- get_label_info() in [[Module:labels]] and then format them into strings. Unrecognized labels will end up
			-- with an unchanged display form.
			local labels = require(labels_module).split_and_process_raw_labels {
				labels = val("ll"), lang = lang, nocat = true}
			labels = require(labels_module).format_processed_labels {
				labels = labels, lang = lang
			}
			if labels ~= "" then
				dash_labels = " &mdash; " .. labels
			end
		end
		return boolean_labels, quals, dash_labels
	end
end

local function desc_or_desc_tree(frame, desc_tree)
	local params
	local boolean = {type = "boolean"}
	if desc_tree then
		params = {
			[1] = {required = true, type = "language", family = true, default = "gem-pro"},
			[2] = {required = true, list = true, allow_holes = true, default = "*fuhsaz"},
			notext = boolean,
			noalts = boolean,
			noparent = boolean,
		}
	else
		params = {
			[1] = {required = true, type = "language", family = true, default = "en"},
			[2] = {list = true, allow_holes = true, template_default = "word"},
			alts = boolean,
		}
	end
	
	-- Add other single params.
	params.sclang = boolean
	params.sclb = {type = "boolean", alias_of = "sclang"}
	params.nolang = boolean
	params.nolb = {type = "boolean", alias_of = "nolang"}

	local parent_args
	if frame.args[1] then
		parent_args = frame.args
	else
		parent_args = frame:getParent().args
	end

	-- FIXME: Temporary error message.
	for arg, _ in pairs(parent_args) do
		if type(arg) == "string" and arg:find("^tag[0-9]*$") then
			local lbarg = arg:gsub("^tag", "lb")
			error(("Use %s= instead of %s="):format(lbarg, arg))
		end
	end

	-- Error to catch most uses of old-style parameters.
	if ine(parent_args[4]) and not ine(parent_args[3]) and not ine(parent_args.tr2) and not ine(parent_args.ts2)
		and not ine(parent_args.t2) and not ine(parent_args.gloss2) and not ine(parent_args.g2)
		and not ine(parent_args.alt2) then
		error("You specified a term in 4= and not one in 3=. You probably meant to use t= to specify a gloss instead. "
			.. "If you intended to specify two terms, put the second term in 3=.")
	end
	if not ine(parent_args[3]) and not ine(parent_args.alt2) and not ine(parent_args.tr2) and not ine(parent_args.ts2)
		and ine(parent_args.g2) then
		error("You specified a gender in g2= but no term in 3=. You were probably trying to specify two genders for "
			.. "a single term. To do that, put both genders in g=, comma-separated.")
	end

	local m_param_utils = require(parameter_utilities_module)

	local param_mods = m_param_utils.construct_param_mods {
		{group = "link", "ref", "l", "q"},
		{param = bortypes, type = "boolean", overall = true, separate_no_index = true},
		{param = calque_aliases, alias_of = "clq"},
		{param = partial_calque_aliases, alias_of = "pclq"},
	}

	local groups, args, globalprops = m_param_utils.parse_list_with_inline_modifiers_and_separate_params {
		params = params,
		param_mods = param_mods,
		raw_args = parent_args,
		termarg = 2,
		-- Need some work to support this.
		-- parse_lang_prefix = true,
		track_module = "descendant",
		-- Due to allowing families as langs and substituting 'und', it's easier to do this later.
		-- lang = function() ... end
		sc = "sc.default",
		splitchar = "[,~]",
		subitem_separator_map = {[","] = "/", ["~"] = " ~ "},
		pre_normalize_modifiers = function(data)
			local modtext = data.modtext
			modtext = modtext:match("^<(.*)>$")
			if not modtext then
				error(("Internal error: Passed-in modifier isn't surrounded by angle brackets: %s"):format(
					data.modtext))
			end
			if bortype_set[modtext] or calque_alias_set[modtext] or partial_calque_alias_set[modtext] then
				modtext = modtext .. ":1"
			end
			return "<" .. modtext .. ">"
		end,
	}

	local lang = args[1]
	
	local namespace = mw.title.getCurrentTitle().nsText

	if (namespace == "" or namespace == "Reconstruction") and (
		lang:hasType("appendix-constructed") and not lang:hasType("regular")) then
		error("Terms in appendix-only constructed languages may not be given as descendants.")
	end

	local fetch_alt_forms = desc_tree and not args.noalts or not desc_tree and args.alts

	local m_desctree
	if desc_tree or fetch_alt_forms then
		m_desctree = require(descendants_tree_module)
	end
	
	if lang:getCode() ~= lang:getFullCode() then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/descendant/etymological]]
		track("etymological")
		track("etymological/" .. lang:getCode())
	end

	local is_family = lang:hasType("family")
	local proxy_lang
	if is_family then
		-- [[Special:WhatLinksHere/Wiktionary:Tracking/descendant/family]]
		track("family")
		track("family/" .. lang:getCode())
		proxy_lang = require(languages_module).getByCode("und")
	else
		proxy_lang = lang
	end

	local langname
	if is_family then
		-- The display form for families includes the word "languages", which we probably don't want to
		-- display.
		langname = lang:getCanonicalName()
	else
		langname = lang:getDisplayForm()
	end
	local langtag
	
	if args.sclang then
		local first_termobj = groups[1] and groups[1].terms[1]
		if not first_termobj then
			error("sclang= given but no term exists to display the script name of")
		end
		local sc_to_use = first_termobj.sc
		if not sc_to_use then
		else
			local first_term = first_termobj.term or first_termobj.alt
			if not first_term then
				error("sclang= given but first specified item no term or display form to display the script name of")
			end
			if first_termobj.lang then
				sc_to_use = first_termobj.lang:findBestScript(first_term)
			elseif is_family then
				sc_to_use = require(scripts_module).findBestScriptWithoutLang(first_term, "none is last resort")
			else
				sc_to_use = lang:findBestScript(first_term)
			end
		end
		langtag = sc_to_use:getDisplayForm()
	else
		langtag = langname
	end
	
	local terms_for_descendant_trees = {}
	-- Keep track of descendants whose descendant tree we fetch. Don't fetch the same descendant tree twice (which
	-- can happen especially with Arabic-script terms with the same unvocalized spelling but differing vocalization).
	-- This happens e.g. with Ottoman Turkish [[پورتقال]], which has {{desctree|fa-cls|پُرْتُقَال|پُرْتِقَال|bor=1}}, with
	-- two terms that have the same unvocalized spelling.
	local terms_and_ids_fetched = {}
	local descendant_terms_seen = {}

	local parts = {}

	for i, group in ipairs(groups) do
		local number_of_items = 0
		local group_parts = {}
		local terms_for_alt_forms = {}

		for j, item in ipairs(group.terms) do
			local link = ""
			item.lang = item.lang or proxy_lang
			item.track_sc = true
			-- Construct a link out of `item`. Also add the term to the list of descendant trees and/or alternative
			-- forms to fetch, if the page+ID combination hasn't already been seen.
			if item.term ~= "-" then -- including term == nil
				item.show_qualifiers = true
				link = require(links_module).full_link(item, nil, true)
				if item.term and (desc_tree or fetch_alt_forms) then
					local entry_name = require(links_module).get_link_page(item.term, lang, sc)
					-- NOTE: We use the term and ID as the key, but not the language. This is OK currently because
					-- all terms have the same language; but if we ever add support for a term-specific language,
					-- we need to fix this.
					local term_and_id = item.id and entry_name .. "!!!" .. item.id or entry_name
					if not terms_and_ids_fetched[term_and_id] then
						terms_and_ids_fetched[term_and_id] = true
						local term_for_fetching = {
							lang = lang, entry_name = entry_name, id = item.id
						}
						if desc_tree then
							if is_family then
								error("No support currently (and probably ever) for fetching a descendant tree when a family code instead of language code is given")
							end
							if error_on_no_descendants then
								require(table_module).insertIfNot(descendant_terms_seen,
									{ term = item.term, id = item.id })
							end
							table.insert(terms_for_descendant_trees, term_for_fetching)
						end
						if fetch_alt_forms then
							if is_family then
								error("No support currently (and probably ever) for fetching alternative forms when a family code instead of language code is given")
							end
							-- [[Special:WhatLinksHere/Wiktionary:Tracking/descendant/alts]]
							track("alts")
							table.insert(terms_for_alt_forms, term_for_fetching)
						end
					end
				end
			elseif item.tr or item.ts or item.gloss or item.genders[1] then
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/descendant/no term]]
				track("no term")
				item.term = nil
				item.show_qualifiers = true
				link = require(links_module).full_link(item, nil, true)
				link = link
					:gsub("<small>%[Term%?%]</small> ", "")
					:gsub("<small>%[Term%?%]</small>&nbsp;", "")
					:gsub("%[%[Category:[^%[%]]+ term requests%]%]", "")
			else -- display no link at all
				-- [[Special:WhatLinksHere/Wiktionary:Tracking/descendant/no term or annotations]]
				track("no term or annotations")
			end
			if link ~= "" then
				if number_of_items > 0 then
					insert(group_parts, "/")
				end
				number_of_items = number_of_items + 1
				insert(group_parts, link)
			end
		end
		if number_of_items > 0 then
			for _, altterm in ipairs(terms_for_alt_forms) do
				local altform = m_desctree.get_alternative_forms(altterm.lang, altterm.entry_name, altterm.id,
					globalprops.use_semicolon and "; " or ", ")
				if altform ~= "" then
					insert(group_parts, globalprops.use_semicolon and "; " or ", ")
					insert(group_parts, altform)
				end
			end

			local group_link = concat(group_parts)
			insert(parts, group.separator)
			if not args.notext then
				insert(parts, get_arrow(group args, i))
			end
			-- no pre-qualifiers/labels and no post-qualifiers/dash-labels
			local post_boolean_labels = get_post_qualifiers_labels(group, args, i, proxy_lang)
			if post_boolean_labels and post_boolean_labels[1] then
				group_link = require(pron_qualifier_module).format_qualifiers {
					lang = proxy_lang,
					text = group_link,
					ll = post_boolean_labels,
				}
			end
			insert(parts, group_link)
		end
	end

	local descendant_trees = {}
	for _, descterm in ipairs(terms_for_descendant_trees) do
		-- When I ([[User:Benwing2]]) first implemented this in Nov 2020, I had `maxmaxindex > 1` as the last argument.
		-- Since then, [[User:Fytcha]] changed the last param to `true`.
		local descendant_tree = m_desctree.get_descendants(descterm.lang, descterm.entry_name, descterm.id, true)
		if descendant_tree and descendant_tree ~= "" then
			insert(descendant_trees, descendant_tree)
		end
	end

	if error_on_no_descendants and desc_tree and not descendant_trees[1] then
		local function format_term_seen(term_seen)
			if term_seen.id then
				return ("[[%s]] with ID '%s'"):format(term_seen.term, term_seen.id)
			else
				return ("[[%s]]"):format(term_seen.term)
			end
		end
		if #descendant_terms_seen == 0 then
			error("[[Template:desctree]] invoked but no terms to retrieve descendants from")
		elseif #descendant_terms_seen == 1 then
			error(("No Descendants section was found in the entry %s under the header for %s"):format(
				format_term_seen(descendant_terms_seen[1]), lang:getFullName()))
		else
			for i, term_seen in ipairs(descendant_terms_seen) do
				descendant_terms_seen[i] = format_term_seen(term_seen)
			end
			error(("No Descendants section was found in any of the entries %s under the header for %s"):format(
				concat(descendant_terms_seen, ", "), lang:getFullName()))
		end
	end

	local descendants = concat(descendant_trees)
	if args.noparent then
		return descendants
	end

	local initial_labels, initial_quals = get_pre_qualifiers_labels(nil, args, 0)
	local final_boolean_labels, final_quals, final_dash_labels = get_post_qualifiers_labels(nil, args, 0, proxy_lang)

	local all_linktext = concat(parts)
	if initial_labels and initial_labels[1] or initial_quals and initial_quals[1] or
			final_boolean_labels and final_boolean_labels[1] or final_quals and final_quals[1] or
			final_refs and final_refs[1] then
		all_linktext = require(pron_qualifier_module).format_qualifiers {
			lang = proxy_lang,
			text = all_linktext,
			l = initial_labels,
			q = initial_quals,
			ll = final_boolean_labels,
			qq = final_quals,
		}
	end
	if final_dash_labels then
		all_linktext = all_linktext .. final_dash_labels
	end
	all_linktext = all_linktext .. descendants

	if args.notext then
		return all_linktext
	end
	local initial_arrow = get_arrow(nil, args, 0)
	if args.nolang then
		return initial_arrow .. all_linktext
	else
		return concat { initial_arrow, langtag, ":", all_linktext ~= "" and " " or "", all_linktext }
	end
end

function export.descendant(frame)
	return desc_or_desc_tree(frame, false) .. require(template_styles_module)(etymology_style_css)
end

function export.descendants_tree(frame)
	return desc_or_desc_tree(frame, true)
end

return export
