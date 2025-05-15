local export = {}

local anchors_module = "Module:anchors"
local labels_module = "Module:labels"
local languages_module = "Module:languages"
local links_module = "Module:links"
local pages_module = "Module:pages"
local parameters_module = "Module:parameters"
local patterns_module = "Module:patterns"
local place_module = "Module:place"
local string_char_module = "Module:string/char"
local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"
local template_parser_module = "Module:template parser"

local concat = table.concat
local find = string.find
local insert = table.insert
local ipairs = ipairs
local lower = string.lower
local match = string.match
local pairs = pairs
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local function codepoint(...)
	codepoint = require(string_utilities_module).codepoint
	return codepoint(...)
end

local function contains(...)
	contains = require(table_module).contains
	return contains(...)
end

local function deep_copy(...)
	deep_copy = require(table_module).deepCopy
	return deep_copy(...)
end

local function find_templates(...)
	find_templates = require(template_parser_module).find_templates
	return find_templates(...)
end

local function full_link(...)
	full_link = require(links_module).full_link
	return full_link(...)
end

local function get_lang(...)
	get_lang = require(languages_module).getByCode
	return get_lang(...)
end

local function gsplit(...)
	gsplit = require(string_utilities_module).gsplit
	return gsplit(...)
end

local function is_preview(...)
	is_preview = require(pages_module).is_preview
	return is_preview(...)
end

local function pattern_escape(...)
	pattern_escape = require(patterns_module).pattern_escape
	return pattern_escape(...)
end

local function place_format(...)
	place_format = require(place_module).format
	return place_format(...)
end

local function process_params(...)
	process_params = require(parameters_module).process
	return process_params(...)
end

local function remove_comments(...)
	remove_comments = require(string_utilities_module).remove_comments
	return remove_comments(...)
end

local function replacement_escape(...)
	replacement_escape = require(patterns_module).replacement_escape
	return replacement_escape(...)
end

local function senseid(...)
	senseid = require(anchors_module).senseid
	return senseid(...)
end

local function show_labels(...)
	show_labels = require(labels_module).show_labels
	return show_labels(...)
end

local function split(...)
	split = require(string_utilities_module).split
	return split(...)
end

local function u(...)
	u = require(string_char_module)
	return u(...)
end

-- From [[Template:gloss]]
local gloss_left = '<span class="mention-gloss-paren">(</span><span class="mention-gloss">'
local gloss_right = '</span><span class="mention-gloss-paren">)</span>'

local place_extra_info = {
	["modern"] = true,
	["full"] = true,
	["short"] = true,
	["abbr"] = true,
	["official"] = true,
	["capital"] = true,
	["largest city"] = true,
	["caplc"] = false,
	["seat"] = true,
	["shire town"] = true,
	["headquarters"] = true,
}

-- Ensure that Wikicode (template calls, bracketed links, HTML, bold/italics, etc.) displays literally in error messages
-- by inserting a Unicode word-joiner symbol after all characters that may trigger Wikicode interpretation. Replacing
-- with equivalent HTML escapes doesn't work because they are displayed literally. I could not get this to work using
-- <nowiki>...</nowiki> (those tags display literally), using using {{#tag:nowiki|...}} (same thing) or using
-- mw.getCurrentFrame():extensionTag("nowiki", ...) (everything gets converted to a strip marker
-- `UNIQ--nowiki-00000000-QINU` or similar). FIXME: This is a massive hack; there must be a better way.
local function escape_wikicode(text)
	text = text:gsub("([%[<'{])", "%1" .. u(0x2060))
	return text
end

local function preprocess(frame, text)
	if text:find("{") or text:find("<math>") then
		return frame:preprocess(text)
	else
		return text
	end
end

local function ine(arg)
	return arg ~= "" and arg or nil
end

local function discard(offset, iter, obj, index)
	return iter, obj, index + offset
end

local function remove_templates_if(haystack, predicate)
	local remaining = {}
	local last_start = 1
	for template in find_templates(haystack) do
		local name = template:get_name()
		if name ~= nil and predicate(name, template:get_arguments(), next(remaining) == nil) then
			local index = template.index
			if last_start < index then
				local chunk = haystack:sub(last_start, index - 1)
				if chunk:find("%S") then
					insert(remaining, chunk)
				end
			end
			last_start = index + template.raw:len()
		end
	end
	if last_start == 1 then
		return haystack
	else
		insert(remaining, haystack:sub(last_start))
		return concat(remaining)
	end
end

local function copy_unnamed_args_maybe_except_code(to, from, deny_list, first_argument)
	first_argument = first_argument or 2
	for _, value in discard(first_argument - 1, ipairs(from)) do
		if not deny_list or not contains(deny_list, value) then
			insert(to, value)
		end
	end
end

local function handle_definition_template(name, args, transclude_args)
	if name == "place" then
		return {
			should_remove = true,
			must_be_first = true,
			generate = function(data)
				if data.formatted_to and data.formatted_to ~= "" then
					error("{{place}} cannot be used in conjunction with |to=")
				end
				local place_args = {}
				local langcode = data.lang:getCode()
				local include_place_extra_info = transclude_args.include_place_extra_info
				local drop_extra = include_place_extra_info == false or include_place_extra_info == nil and langcode ~= "en"
				local saw_tcl_t
				local saw_t
				-- Copy the arguments but drop translations, maybe the "extra info", and maybe the numbered args (if tcl= given)
				local tcl_arg = ine(args.tcl)
				for key, val in pairs(args) do
					local base = tostring(key):match("^(.-)([0-9]*)$")
					if base == "tcl_t" or base == "tcl_tid" then
						saw_tcl_t = true -- otherwise ignore
					elseif base == "tcl_nolb" then
						data.nolb = val -- otherwise ignore
					elseif base == "t" or base == "tid" then
						if transclude_args.t[1] then
							-- ignore it if the user specified t= in {{tcl}}, otherwise keep it unless tcl_t is given
						else
							saw_t = true
						end
					elseif drop_extra and place_extra_info[base] ~= nil then
						-- ignore it
					elseif not tcl_arg or base ~= "" then
						place_args[key] = val
					end
				end

				local function sub_plus(t)
					if t:find("+") then
						t = t:gsub("+", replacement_escape(data.source))
					end
					return t
				end
					
				place_args[1] = langcode
				place_args.pagename = data.source

				-- If tcl= given, copy its values into the numeric args.
				if tcl_arg then
					local argno = 2
					for tcl_val in gsplit(tcl_arg, ";;") do
						place_args[argno] = tcl_val
						argno = argno + 1
					end
					place_args.a = nil
				end
						
				if transclude_args.t[1] then
					local argno = 1
					for _, t in ipairs(transclude_args.t) do
						if t ~= "-" then
							place_args["t" .. (argno == 1 and "" or argno)] = sub_plus(t)
							argno = argno + 1
						end
					end
				elseif langcode ~= "en" then
					if saw_tcl_t then
						for key, val in pairs(args) do
							local base, num = tostring(key):match("^(.-)([0-9]*)$")
							if base == "tcl_t" then
								place_args["t" .. num] = sub_plus(val)
							elseif base == "tcl_tid" then
								place_args["tid" .. num] = val
							end
						end
					elseif saw_t then
						for key, val in pairs(args) do
							local base, num = tostring(key):match("^(.-)([0-9]*)$")
							if base == "t" or base == "tid" then
								place_args[key] = val
							end
						end
					else
						place_args["t"] = data.source
						place_args["tid"] = data.id
					end
				end
				place_args["sort"] = data.sort
				if data.nocat then
					place_args["nocat"] = "1"
				end
				if data.no_gloss then
					place_args["def"] = "-"
				else
					local gloss = data.gloss

					-- The whole purpose of place_* arguments is to be in the entry's language, not English,
					-- so add the appropriate langcode to make sure they're interpreted that way, but not if
					-- a langcode is already present.
					local function prefix_with_langcode(val)
						if val:find("^[a-zA-Z0-9-_]+:[^ ]") then
							return val
						end
						return langcode .. ":" .. val
					end
							
					for extra_info_arg, is_list in pairs(place_extra_info) do
						if is_list then
							for i, v in ipairs(transclude_args["place_" .. extra_info_arg]) do
								place_args[extra_info_arg .. (i == 1 and "" or i)] = prefix_with_langcode(v)
							end
						elseif transclude_args["place_" .. extra_info_arg] then
							place_args[extra_info_arg] = prefix_with_langcode(transclude_args["place_" .. extra_info_arg])
						end
					end
					
					if not args.tcl_noextratext and not tcl_arg and gloss ~= "" then
						-- Copy text after {{place}} into {{place}}, unless tcl= or tcl_noextratext= is given.
						local first_free = 2
						while place_args[first_free] ~= nil do first_free = first_free + 1 end
						if place_args[first_free - 1]:find("<<") then
							-- new-style argument; concatenate to end of argument
							if not gloss:find("^[,;.]") then
								gloss = " " .. gloss
							end
							place_args[first_free - 1] = args[first_free - 1] .. gloss
						else
							-- old-style argument; add as separate argument
							gloss = gloss:gsub("^[,;] *", "")
							place_args[first_free] = gloss
						end
					end
				end
				return place_format(place_args)
			end,
		}
	elseif name == "abbreviation of" or name == "abbr of" or name == "abbrev of"
		or name == "acronym of" or name == "ellipsis of"
		or name == "contraction of" or name == "contr of"
		or name == "initialism of" or name == "init of"
		or name == "short for" or name == "synonym of" then
		return {
			should_remove = true,
			must_be_first = true,
			generate = function(data)
				local formatted_gloss = ""
				if not data.no_gloss then
					local formatted_link = full_link{
						term = args[2], alt = args[3], lang = data.source_lang, id = args["id"]
					}
					local after_link = ""
					if data.gloss ~= "" then
						local separator = (args["nodot"] and "") or ((args["dot"] or ";") .. " ")
						after_link = separator .. data.gloss
					end
					formatted_gloss = " " .. gloss_left .. formatted_link .. after_link .. gloss_right
				end
				return data.formatted_to .. full_link{
					term = data.source, lang = data.source_lang, id = data.id
				} .. formatted_gloss
			end,
		}
	end
	return nil
end

function export.show(frame)
	local boolean = {type = "boolean"}
	local list = {list = true}
	local required = {required = true}
   	local params = {
		[1] = required, -- langcode of target language (the current entry's language)
		[2] = required, -- source English term to transclude from
		[3] = true, -- can have multiple comma-separated IDs
		["id"] = {alias_of = 3}, 
		["sort"] = true,
		["nogloss"] = {default = false, type = "boolean"},
		["no_truncate_gloss"] = boolean,
		-- Normally, we ignore extra info (capital, largest city, modern name, etc.) when transcluding {{place}}
		-- because the given terms are in English and will likely differ from language to language.
		["include_place_extra_info"] = boolean,
		["lb"] = true, -- can have multiple semicolon-separated labels
		["nolb"] = true, -- can have multiple semicolon-separated labels
		["nocat"] = boolean,
		["to"] = boolean,
		["t"] = list,
		["indent"] = true,
	}
	for k, is_list in pairs(place_extra_info) do
		params["place_" .. k] = not is_list and true or is_list == true and list or {list = is_list}
	end

   	local args = process_params(frame:getParent().args, params)

	local language_code = args[1]
	local language = get_lang(language_code)
	local source = args[2]
	local source_langcode = "en"
	local source_lang = get_lang(source_langcode)
	local source_langname = source_lang:getFullName()
	local ids = args[3] and split(args[3], ",") or {""}
	local sort = args["sort"]
	local source_is_current_page = mw.title.getCurrentTitle().text == source
	local copy_sortkey = (sort == nil) and source_is_current_page
	local no_gloss = args["nogloss"]
	local labels = args["lb"] and split(args["lb"], ";") or {}
	local nolb
	local to = args["to"]

	local function issue_error(msg)
		if source_is_current_page and is_preview() then
			msg = msg .. ". NOTE: You are in preview mode. If you're previewing only part of the page, try previewing the full page, as the error may go away."
		end
		error(msg)
	end

	local content = mw.title.new(source):getContent()
	if content == nil then
		issue_error("Couldn't find the entry [[" .. source .. "]]")
	end

	-- Remove HTML comments.
	content = remove_comments(content)
	-- Remove <ref></ref>.
	content = content:gsub("< *[rR][eE][fF][^%a>/]*[^>/]*>.-< */ *[rR][eE][fF] *>", "")
	-- Remove <ref/>.
	content = content:gsub("< *[rR][eE][fF][^%a>/]*[^>/]*/ *>", "")
	-- TODO: Handle <nowiki> (it's more complex than just cutting it out too).

	local retlines = {}

	for _, id in ipairs(ids) do
		local found_labels = {}
		local line_start, line
		if id == "" then
			id = nil
		end
		if id ~= nil then
			local senseid_start, senseid_end = content:find("{{ *senseid *| *" .. pattern_escape(source_langcode) .. " *| *" .. pattern_escape(id) .. " *}}")
			if senseid_start == nil then
				senseid_start, senseid_end = content:find("{{ *sid *| *" .. pattern_escape(source_langcode) .. " *| *" .. pattern_escape(id) .. " *}}")
			end
			if senseid_start == nil then
				local alternatives = nil
				for id in content:gmatch("{{ *senseid *| *" .. pattern_escape(source_langcode) .. " *| *([^}]*)}}") do
					alternatives = alternatives and alternatives .. ", " .. id or id
				end
				for id in content:gmatch("{{ *sid *| *" .. pattern_escape(source_langcode) .. " *| *([^}]*)}}") do
					alternatives = alternatives and alternatives .. ", " .. id or id
				end
				if alternatives then
					alternatives = ": Alternatives for |id= are: " .. alternatives
				else
					alternatives = ""
				end
				issue_error("Couldn't find the template {{[[Template:senseid|senseid]]|" .. source_langcode .. "|" .. id .. "}} within entry [[" .. source .. "]]" .. alternatives)
			end

			-- Do the following manually instead of using regex or iterators in hopes of saving memory.
			local newline, pound = 10, 35
			line_start = senseid_start
			while line_start > 0 and content:byte(line_start - 1) ~= newline do line_start = line_start - 1 end
			local def_start = line_start
			while content:byte(def_start) == pound do def_start = def_start + 1 end
			local line_end = senseid_end
			while line_end < content:len() and content:byte(line_end + 1) ~= newline do line_end = line_end + 1 end
			line = content:sub(def_start, senseid_start - 1) .. content:sub(senseid_end + 1, line_end)
		else -- id == nil
			local _, start_source = find(content, "==[ \t]*" .. pattern_escape(source_langname) .. "[ \t]*==")
			if not start_source then
				issue_error(("Couldn't find L2 header for source language '%s' on page [[%s]]"):format(source_langname,
					source))
			end
			-- Find index of start of next language; may be nil if no language follows.
			local _, start_next_lang = find(content, "\n==[^=\n]+==", start_source, false)
			content = content:sub(start_source, start_next_lang)
			while true do
				local next_line_start
				_, next_line_start = find(content, "\n#+[^:*]", line_start, false)
				if not next_line_start then
					break
				end
				if line_start then
					local first_line = match(content, "(.-)%f[\n%z]", line_start)
					local next_line = match(content, "(.-)%f[\n%z]", next_line_start + 1)
					issue_error(("No id specified and saw two definition lines '%s' and '%s' for source language '%s' on page [[%s]]"):format(
						escape_wikicode(first_line), escape_wikicode(next_line), source_langname, source))
				end
				line_start = next_line_start + 1
			end
			if not line_start then
				issue_error(("Couldn't find any definition lines for source language '%s' on page [[%s]]"):format(
					source_langname, source))
			end
			line = match(content, "(.-)%f[\n%z]", line_start)
		end

		if to == nil then
			local i = line_start
			while i > 1 do
				i = i - 1 -- i is now the index of the newline
				while i > 1 and content:byte(i - 1) ~= 0xA do i = i - 1 end
				local header = content:match("^===+([^=\n]+)===+ *\n", i)
				if header then
					to = (header:match("Verb") ~= nil)
					break
				end
			end
		end

		-- TODO: Remove this error once <nowiki> is handled correctly (see above TODO).
		if line:find("< *nowiki%W") or line:find("< */ *nowiki%W") then
			error("Cannot handle <nowiki>")
		end

		-- Quick'n'dirty templatization of manual cats so that the below code also works for them.
		for _, v in ipairs({{source_langcode .. ":", "c"}, {source_lang:getCanonicalName() .. " ", "cln"}, {"", "cat"}}) do
			line = line:gsub("%[%[ *Category *: *" .. v[1] .. "([^%]|]*)%]%]", "{{" .. v[2] .. "|" .. source_langcode .. "|%1}}")
			line = line:gsub("%[%[ *Category *%: *" .. v[1] .. "([^%]|]*)%|([^%]|]*)%]%]", "{{" .. v[2] .. "|" .. source_langcode .. "|%1|sort=%2}}")
		end

		-- Extract template information.
		local cats = {}
		local cats_cln = {}
		local cats_top = {}
		local encountered_label = false
		local generator = nil
		local sortkeys = {}
		local sortkey_most_frequent = nil
		local sortkey_most_frequent_n = 0
		local function process_template(name, tempargs, is_at_the_start)
			-- Expand any nested templates in template arguments.
			for k, v in pairs(tempargs) do
				tempargs[k] = preprocess(frame, v)
			end
			local supports_sortkey = false
			local should_remove = true -- If set, removes the template from the line after processing.
			local must_be_first = false -- If set, ensures that nothing (except for removed templates) preceeds this template.
			local definition_template_handler = handle_definition_template(name, tempargs, args)
			if definition_template_handler ~= nil then
				if generator ~= nil then
					error("Encountered {{[[Template:" .. name .. "|" .. name .. "]]}} even though a full definition template has already been processed")
				end
				should_remove = definition_template_handler.should_remove
				must_be_first = definition_template_handler.must_be_first
				generator = definition_template_handler.generate
			elseif name == "categorize" or name == "cat" then
				copy_unnamed_args_maybe_except_code(cats, tempargs)
				supports_sortkey = true
			elseif name == "catlangname" or name == "cln" then
				copy_unnamed_args_maybe_except_code(cats, tempargs)
				supports_sortkey = true
			elseif name == "catlangcode" or name == "topics" or name == "top" or name == "C" or name == "c" then
				copy_unnamed_args_maybe_except_code(cats_top, tempargs)
				supports_sortkey = true
			elseif name == "label" or name == "lbl" or name == "lb" then
				if encountered_label then
					error("Encountered multiple {{[[Template:label|label]]}} templates in the definition line")
				end
				encountered_label = true
				copy_unnamed_args_maybe_except_code(found_labels, tempargs)
				supports_sortkey = true
				must_be_first = true
			elseif name == "defdate" or name == "defdt" or name == "century" or name == "ref" or name == "refn" or name == "rfd-sense" or name == "rfv-sense" or name == "senseid" or name == "sid" then
				-- Remove and do nothing.
			else
				-- We are dealing with a template other than the above hard-coded ones.
				-- If it contains the language code, we cannot handle it.
				if tempargs[1] == source_langcode then
					error("Cannot handle template {{[[Template:" .. name .. "|" .. name .. "]]}}")
				end
				supports_sortkey = tempargs["sort"] or tempargs["sort1"] -- TODO: This doesn't handle the case where there is only sortn but not sort1/sort.
				should_remove = false -- Leave the template in and just copy it, e.g. [[Template:,]], [[Template:gloss]], [[Template:qualifier]], [[Template:w]] etc.
			end
			if supports_sortkey then
				if tempargs["sort1"] ~= nil then
					error("Cannot handle multiple sort keys")
				end
				local sortkey = tempargs["sort"]
				if sortkey ~= nil then
					if sortkeys[sortkey] == nil then
						sortkeys[sortkey] = 1
					else
						sortkeys[sortkey] = sortkeys[sortkey] + 1
					end
					if sortkeys[sortkey] > sortkey_most_frequent_n then
						sortkey_most_frequent = sortkey
						sortkey_most_frequent_n = sortkeys[sortkey]
					end
				end
			end
			if must_be_first and not is_at_the_start then
				error("The template {{[[Template:" .. name .. "|" .. name .. "]]}} should occur to the front of the definition line")
			end
			return should_remove
		end
		line = remove_templates_if(line, process_template)
		line = line:gsub("^%s+", ""):gsub("%s+$", "") -- Prune ends.

		-- Tidy up the remaining definition (to be used as a gloss).
		-- Truncate full sentences after a period, as they won't be formatted well as a gloss. Require a space after
		-- the period as a possible way of reducing false positives with abbreviations.
		local gloss = line
		if not args.no_truncate_gloss then
			-- Substitute a list of known abbreviations that shouldn't mark the end-point of the gloss, which will be reinserted after truncation.
			local abbrevs = {"A.D.", "B.C.", "B.C.E.", "c[af]?.", "C.E.", "e.g.", "fl.", "i.[ae].", "r.", "sc.", "scil.", "viz.", "vs?."}
			local substitutes, i = {}, 0
			
			local function insert_substitute(m)
				i = i + 1
				insert(substitutes, m)
				return u(0x80000 + i)
			end
			
			for j, abbrev in ipairs(abbrevs) do
				abbrev = abbrev:gsub("%.", "%%.")
					:gsub("%f[^.].", " *%0")
				abbrevs[j] = abbrev
				gloss = gloss:gsub("%f[%S]" .. abbrev .. "%f[%s]", insert_substitute)
			end
			
			gloss = gloss:gsub("%s*%. .*$", "")
				:gsub("\242[\128-\191]*", function(m)
					return substitutes[codepoint(m) - 0x80000]
				end)
		end
		gloss = gloss:gsub("^%u", lower):gsub("%.$", "")
		gloss = gloss:gsub("^{{1|([^}|]*)}}", "%1") -- Remove [[Template:1]]
		local _, link_end, link_dest_head, link_dest_tail, link_face_head, link_face_tail = gloss:find("^%[%[(.)([^|%]]*)|(.)([^%]]*)%]%]") -- Remove [[foo|Foo]]
		if link_end ~= nil and link_dest_tail == link_face_tail and link_face_head:lower() == link_dest_head then
			gloss = "[[" .. link_dest_head .. link_dest_tail .. gloss:sub(link_end - 1)
		end
		gloss = preprocess(frame, gloss)

		if copy_sortkey then
			sort = sortkey_most_frequent
		end

		local formatted_senseid = ""
		local formatted_senseid_close = ""
		if id ~= nil then
			formatted_senseid = senseid(language, id, "span")
			if formatted_senseid:find("<span") then
				formatted_senseid_close = "</span>"
			end
		end

		local formatted_categories = args.nocat and "" or (
			((next(cats    ) == nil) and "" or frame:expandTemplate({title = "cat", args = {language_code, unpack(cats    )}})) ..
			((next(cats_cln) == nil) and "" or frame:expandTemplate({title = "cln", args = {language_code, unpack(cats_cln)}})) ..
			((next(cats_top) == nil) and "" or frame:expandTemplate({title = "top", args = {language_code, unpack(cats_top)}}))
		)
		local formatted_to = to and "to " or ""
		local formatted_definition
		if generator ~= nil then
			local data = {
				frame = frame, lang = language, source = source, source_lang = source_lang, id = id,
				sort = sort, nocat = args.nocat, no_gloss = no_gloss, gloss = gloss, formatted_to = formatted_to,
			}
			formatted_definition = generator(data)
			nolb = data.nolb or nolb
		else
			local formatted_link = full_link{term = source, lang = source_lang, id = id}
			local formatted_gloss = no_gloss and "" or (" " .. gloss_left .. gloss .. gloss_right)
			formatted_definition = formatted_to .. formatted_link .. formatted_gloss
		end

		nolb = args["nolb"] or nolb
		local labels_to_ignore = nil
		local ignore_all_labels = false
		if nolb then
			if nolb == "+" or nolb == "1" or nolb == "*" then
				ignore_all_labels = true
			else
				labels_to_ignore = split(nolb, ";")
			end
		end
		local this_labels = deep_copy(labels)
		if not ignore_all_labels then
			copy_unnamed_args_maybe_except_code(this_labels, found_labels, labels_to_ignore, 1)
		end
		local formatted_labels = (next(this_labels) == nil) and "" or (show_labels{labels = this_labels, lang = language, sort = sort} .. " ")

		insert(retlines, formatted_senseid .. formatted_categories .. formatted_labels .. formatted_definition .. formatted_senseid_close)
	end

	return concat(retlines, "\n" .. (args.indent or "#") .. " ")
end

return export
