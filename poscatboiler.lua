local lang_independent_data = require("Module:category tree/data")
local lang_specific_module = "Module:category tree/lang"
local lang_specific_module_prefix = lang_specific_module .. "/"
local family_specific_module = "Module:category tree/fam"
local family_specific_module_prefix = family_specific_module .. "/"
local labels_utilities_module = "Module:labels/utilities"
local template_parser_module = "Module:template parser"

local concat = table.concat
local dump = mw.dumpObject
local expand_template = require("Module:frame").expandTemplate
local insert = table.insert
local is_callable = require("Module:fun").is_callable
local lcfirst = require("Module:string utilities").lcfirst
local list_to_set = require("Module:table").listToSet
local make_title = mw.title.makeTitle
local new_title = mw.title.new
local parse = require(template_parser_module).parse
local sparse_concat = require("Module:table").sparseConcat
local tostring = tostring
local type = type
local ucfirst = require("Module:string utilities").ucfirst
local uupper = require("Module:string utilities").upper

local function internal_error(msg)
	error("Internal error: " .. msg)
end

local function get_lang(...)
	local _get_lang = require("Module:languages").getByCode
	function get_lang(...)
		return _get_lang(...) or require("Module:languages/errorGetBy").code(...)
	end
	return get_lang(...)
end

local function get_script(...)
	local _get_script = require("Module:scripts").getByCode
	function get_script(code)
		return _get_script(code) or require("Module:languages/error")(code, true, "script code")
	end
	return get_script(...)
end

-- Category object

local Category = {}
Category.__index = Category


function Category:get_originating_info()
	local originating_info = ""
	if self._info.originating_label then
		originating_info = " (originating from label \"" .. self._info.originating_label .. "\" in module [[" .. self._info.originating_module .. "]])"
	end
	return originating_info
end

local valid_keys = list_to_set{"code", "label", "sc", "raw", "args", "also", "called_from_inside", "originating_label", "originating_module"}

function Category.new(info)
	for key in pairs(info) do
		if not valid_keys[key] then
			internal_error("The parameter \"" .. key .. "\" was not recognized.")
		end
	end

	local self = setmetatable({}, Category)
	self._info = info

	if not self._info.label then
		internal_error("No label was specified.")
	end

	self:initCommon()

	if not self._data then
		internal_error("The " .. (self._info.raw and "raw " or "") .. "label \"" .. self._info.label .. "\" does not exist" .. self:get_originating_info() .. ".")
	end

	return self
end


function Category:initCommon()
	local function patch_args(args)
		-- This fixes the issue with Scribunto automatically converting keys
		-- in a table as numbers to strings, which in turn causes a circular
		-- error for having argument parameter names as numbers as strings.
		
		if type(args) ~= "table" then
			return args
		end
		
		local new_args = {}
		for k, v in pairs(args) do
			if type(k) == "string" and string.len(k) < 10 and not string.match(k, "^0") and string.match(k, "^%d+$") then
				new_args[tonumber(k)] = patch_args(v)
			else
				new_args[k] = patch_args(v)
			end
		end
		return new_args
	end
	
	
	local args_handled = false
	if self._info.raw then
		-- Check if the category exists
		local raw_categories = lang_independent_data["RAW_CATEGORIES"]
		self._data = raw_categories[self._info.label]

		if self._data then
			if self._data.lang then
				self._lang = get_lang(self._data.lang)
				self._info.code = self._lang:getCode()
			end
			if self._data.sc then
				self._sc = get_script(self._data.sc)
				self._info.sc = self._sc:getCode()
			end
		else
			-- Go through raw handlers
			local data = {
				category = self._info.label,
				args = patch_args(self._info.args) or {},
				called_from_inside = self._info.called_from_inside,
			}
			for _, handler in ipairs(lang_independent_data["RAW_HANDLERS"]) do
				self._data, args_handled = handler.handler(data)
				if self._data then
					self._data.module = self._data.module or handler.module
					break
				end
			end
			if self._data then
				-- Update the label if the handler specified a canonical name for it.
				if self._data.canonical_name then
					self._info.canonical_name = self._data.canonical_name
				end
				if self._data.lang then
					if type(self._data.lang) ~= "string" then
						internal_error("Received non-string value " .. dump(self._data.lang) .. " for self._data.lang, label \"" .. self._info.label .. "\"" .. self:get_originating_info() .. ".")
					end
					self._lang = get_lang(self._data.lang)
					self._info.code = self._lang:getCode()
				end
				if self._data.sc then
					if type(self._data.sc) ~= "string" then
						internal_error("Received non-string value " .. dump(self._data.sc) .. " for self._data.sc, label \"" .. self._info.label .. "\"" .. self:get_originating_info() .. ".")
					end
					self._sc = get_script(self._data.sc)
					self._info.sc = self._sc:getCode()
				end
			end
		end
	else
		-- Already parsed into language + label
		if self._info.code then
			self._lang = get_lang(self._info.code)
		else
			self._lang = nil
		end

		if self._info.sc then
			self._sc = get_script(self._info.sc)
		else
			self._sc = nil
		end

		self._info.orig_label = self._info.label
		if not self._lang then
			-- Umbrella categories without a preceding language always begin with a capital letter, but the actual label may be
			-- lowercase (cf. [[:Category:Nouns by language]] with label 'nouns' with per-language [[:Category:English nouns]];
			-- but [[:Category:Reddit slang by language]] with label 'Reddit slang' with per-language
			-- [[:Category:English Reddit slang]]). Since the label is almost always lowercase, we lowercase it for umbrella
			-- categories, storing the original into `orig_label`, and correct it later if needed.
			self._info.label = lcfirst(self._info.label)
		end
		
		-- First, check lang-specific labels and handlers if this is not an umbrella category.
		if self._lang then
			local objects_with_modules = require(lang_specific_module)
			local obj, seen = self._lang, {}
			local object_specific_module_prefix = lang_specific_module_prefix
			local is_family = false
			repeat
				if objects_with_modules[obj:getCode()] then
					local module = object_specific_module_prefix .. obj:getCode()
					local labels_and_handlers = require(module)
					if labels_and_handlers.LABELS then
						self._data = labels_and_handlers.LABELS[self._info.label]
						if self._data then
							if not is_family and self._data.umbrella == nil and self._data.umbrella_parents == nil then
								self._data.umbrella = false
							end
							self._data.module = self._data.module or module
						end
					end
					if not self._data and labels_and_handlers.HANDLERS then
						for _, handler in ipairs(labels_and_handlers.HANDLERS) do
							local data = {
								label = self._info.label,
								lang = self._lang,
								sc = self._sc,
								args = patch_args(self._info.args) or {},
								called_from_inside = self._info.called_from_inside,
							}
							self._data, args_handled = handler(data)
							if self._data then
								if not is_family and self._data.umbrella == nil and
									self._data.umbrella_parents == nil then
									self._data.umbrella = false
								end
								self._data.module = self._data.module or module
								break
							end
						end
					end
					if self._data then
						break
					end
				end
				seen[obj:getCode()] = true
				obj = obj:getFamily()
				if not is_family then
					is_family = true
					object_specific_module_prefix = family_specific_module_prefix
					objects_with_modules = require(family_specific_module)
				end
			until not obj or seen[obj:getCode()]
		end

		-- Then check lang-independent labels.
		if not self._data then
			local labels = lang_independent_data["LABELS"]
			self._data = labels[self._info.label]
			-- See comment above about uppercase- vs. lowercase-initial labels, which are indistinguishable
			-- in umbrella categories.
			if not self._data then
				self._data = labels[self._info.orig_label]
				if self._data then
					self._info.label = self._info.orig_label
				end
			end
			if not self._data and not self._lang then
				-- Check family-specific labels for umbrella label.
				local families_with_modules = require(family_specific_module)
				for famcode, _ in pairs(families_with_modules) do
					local module = family_specific_module_prefix .. famcode
					local labels_and_handlers = require(module)
					if labels_and_handlers.LABELS then
						self._data = labels_and_handlers.LABELS[self._info.label]
						if self._data then
							self._data.module = self._data.module or module
							break
						end
					end
				end
			end
		end

		-- Then check lang-independent handlers.
		if not self._data then
			local data = {
				label = self._info.label,
				lang = self._lang,
				sc = self._sc,
				args = patch_args(self._info.args) or {},
				called_from_inside = self._info.called_from_inside,
			}
			for _, handler in ipairs(lang_independent_data["HANDLERS"]) do
				self._data, args_handled = handler.handler(data)
				if self._data then
					self._data.module = self._data.module or handler.module
					break
				end
			end
			if not self._data and not self._lang then
				-- Check family-specific labels for umbrella handler.
				local families_with_modules = require(family_specific_module)
				for famcode, _ in pairs(families_with_modules) do
					local module = family_specific_module_prefix .. famcode
					local labels_and_handlers = require(module)
					if labels_and_handlers.HANDLERS then
						for _, handler in ipairs(labels_and_handlers.HANDLERS) do
							local data = {
								label = self._info.label,
								sc = self._sc,
								args = patch_args(self._info.args) or {},
								called_from_inside = self._info.called_from_inside,
							}
							self._data, args_handled = handler(data)
							if self._data then
								self._data.module = self._data.module or module
								break
							end
						end
					end
					if self._data then
						break
					end
				end
			end
		end
	end

	if not args_handled and self._data and self._info.args and next(self._info.args) then
		local module_text = " (handled in [[" .. (self._data.module or "UNKNOWN").. "]])"
		local args_text = {}
		for k, v in pairs(self._info.args) do
			insert(args_text, k .. "=" .. ((type(v) == "string" or type(v) == "number") and v or dump(v)))
		end
		error("poscatboiler label '" .. self._info.label .. "' " .. module_text .. " doesn't accept extra args " ..
			concat(args_text, ", "))
	end

	if self._sc and not self._lang then
		internal_error("Umbrella categories cannot have a script specified.")
	end
end


function Category:convert_spec_to_string(desc)
	if not desc then
		return desc
	end
	local desc_type = type(desc)
	if desc_type == "string" then
		return desc
	elseif desc_type == "number" then
		return tostring(desc)
	elseif not is_callable(desc) then
		internal_error("`desc` must be a string, number, function, callable table or nil; received " .. dump(desc))
	end
	desc = desc {
		lang = self._lang,
		sc = self._sc,
		label = self._info.label,
		raw = self._info.raw,
	}
	if not desc then
		return desc
	end
	desc_type = type(desc)
	if desc_type == "string" then
		return desc
	end
	internal_error("The value returned by `desc` must be a string or nil; received " .. dump(desc))
end

local function add_obj_args(args, obj, obj_type)
	if obj then
		args[obj_type .. "code"] = obj:getCode()
		args[obj_type .. "name"] = obj:getCanonicalName()
		args[obj_type .. "disp"] = obj:getDisplayForm()
		args[obj_type .. "cat"] = obj:getCategoryName()
		args[obj_type .. "link"] = obj:makeCategoryLink()
	end
end

-- Expands `desc` like a template, passing values for specs like {{{langname}}}.
function Category:substitute_template_specs(desc)
	-- This may end up happening twice but that's OK as the function is (usually) idempotent.
		-- FIXME: Not idempotent if a preprocessed template returns wikicode.
	desc = self:convert_spec_to_string(desc)
	if not desc then
		return nil
	end
	
	-- Populate the substitution arguments.
	local args = {}

	args.umbrella_msg = "This is an umbrella category. It contains no dictionary entries, but only other, language-specific categories, which in turn contain relevant terms in a given language."

	args.umbrella_meta_msg = "This is an umbrella metacategory, covering a general area such as \"lemmas\", \"names\" or \"terms by etymology\". It contains no dictionary entries, but holds only umbrella (\"by language\") categories covering specific subtopics, which in turn contain language-specific categories holding terms in a given language for that same topic."

	add_obj_args(args, self._lang, "lang")
	add_obj_args(args, self._sc, "sc")

	return parse(desc, true):expand(args)
end

function Category:substitute_template_specs_in_args(args)
	if not args then
		return args
	end
	local pinfo = {}
	for k, v in pairs(args) do
		pinfo[self:substitute_template_specs(k)] = self:substitute_template_specs(v)
	end
	return pinfo
end


function Category:make_new(info)
	info.originating_label = self._info.label
	info.originating_module = self._data.module
	info.called_from_inside = true
	return Category.new(info)
end


function Category:getBreadcrumbName()
	local ret

	if self._lang or self._info.raw then
		ret = self._data.breadcrumb or self._data.breadcrumb_and_first_sort_base
	else
		ret = self._data.umbrella and (self._data.umbrella.breadcrumb or self._data.umbrella.breadcrumb_and_first_sort_base)
	end
	if not ret then
		ret = self._info.label
	end

	if type(ret) ~= "table" then
		ret = {name = ret}
	end

	local name = self:substitute_template_specs(ret.name)
	local nocap = ret.nocap

	if self._sc then
		name = name .. " in " .. self._sc:getDisplayForm()
	end

	return name, nocap
end


local function expand_toc_template_if(template)
	local template_obj = new_title(template, 10)
	if template_obj.exists then
		return expand_template{title = template_obj.text}
	end
	return nil
end


-- Return the textual expansion of the first existing template among the given templates, first performing
-- substitutions on the template name such as replacing {{{langcode}}} with the current language's code (if any).
-- If no templates exist after expansion, or if nil is passed in, return nil. If a single string is passed in,
-- treat it like a one-element list consisting of that string.
function Category:get_template_text(templates)
	if templates == nil then
		return nil
	elseif type(templates) ~= "table" then
		templates = {templates}
	end
	for _, template in ipairs(templates) do
		if template == false then
			return false
		end
		template = self:substitute_template_specs(template)
		return expand_toc_template_if(template)
	end
	return nil
end


function Category:getTOC(toc_type)
	-- Type "none" means everything fits on a single page; in that case, display nothing.
	if toc_type == "none" then
		return nil
	end

	local templates, fallback_templates

	-- If TOC type is "full" (more than 2500 entries), do the following, in order:
	-- 1. look up and expand the `toc_template_full` templates (normal or umbrella, depending on whether there is
	--    a current language);
	-- 2. look up and expand the `toc_template` templates (normal or umbrella, as above);
	-- 3. do the default behavior, which is as follows:
	-- 3a. look up a language-specific "full" template according to the current language (using English if there
	--     is no current language);
	-- 3b. look up a script-specific "full" template according to the first script of current language (using English
	--     if there is no current language);
	-- 3c. look up a language-specific "normal" template according to the current language (using English if there
	--     is no current language);
	-- 3d. look up a script-specific "normal" template according to the first script of the current language (using
	--     English if there is no current language);
	-- 3e. display nothing.
	--
	-- If TOC type is "normal" (between 200 and 2500 entries), do the following, in order:
	-- 1. look up and expand the `toc_template` templates (normal or umbrella, depending on whether there is
	--    a current language);
	-- 2. do the default behavior, which is as follows:
	-- 2a. look up a language-specific "normal" template according to the current language (using English if there
	--     is no current language);
	-- 2b. look up a script-specific "normal" template according to the first script of the current language (using
	--     English if there is no current language);
	-- 2c. display nothing.

	local data_source
	if self._lang or self._info.raw then
		data_source = self._data
	else
		data_source = self._data.umbrella
	end

	if data_source then
		if toc_type == "full" then
			templates = data_source.toc_template_full
			fallback_templates = data_source.toc_template
		else
			templates = data_source.toc_template
		end
	end

	local text = self:get_template_text(templates)
	if text then
		return text
	elseif text == false then
		return nil
	end
	text = self:get_template_text(fallback_templates)
	if text then
		return text
	elseif text == false then
		return nil
	end
	local default_toc_templates_to_check = {}

	local lang, sc = self:getCatfixInfo()
	local langcode = lang and lang:getCode() or "en"
	local sccode = sc and sc:getCode() or lang and lang:getScriptCodes()[1] or "Latn"
	-- FIXME: What is toctemplateprefix used for?
	local tocname = (self._data.toctemplateprefix or "") .. "categoryTOC"
	if toc_type == "full" then
		insert(default_toc_templates_to_check, ("%s-%s/full"):format(langcode, tocname))
		insert(default_toc_templates_to_check, ("%s-%s/full"):format(sccode, tocname))
	end
	insert(default_toc_templates_to_check, ("%s-%s"):format(langcode, tocname))
	insert(default_toc_templates_to_check, ("%s-%s"):format(sccode, tocname))

	for _, toc_template in ipairs(default_toc_templates_to_check) do
		local toc_template_text = expand_toc_template_if(toc_template)
		if toc_template_text then
			return toc_template_text
		end
	end
	return nil
end


function Category:getInfo()
	return self._info
end


function Category:getDataModule()
	return self._data.module
end


function Category:canBeEmpty()
	if self._lang or self._info.raw then
		return self._data.can_be_empty
	end
	return self._data.umbrella and self._data.umbrella.can_be_empty
end


function Category:isHidden()
	if self._lang or self._info.raw then
		return self._data.hidden
	end
	return self._data.umbrella and self._data.umbrella.hidden
end


function Category:getCategoryName()
	if self._info.raw then
		return self._info.canonical_name or self._info.label
	elseif self._lang then
		local ret = self._lang:getCanonicalName() .. " " .. self._info.label
		if self._sc then
			ret = ret .. " in " .. self._sc:getDisplayForm()
		end
		return ucfirst(ret)
	end
	local ret = ucfirst(self._info.label)
	if not (self._data.no_by_language or self._data.umbrella and self._data.umbrella.no_by_language) then
		ret = ret .. " by language"
	end
	return ret
end


function Category:getTopright()
	if self._lang or self._info.raw then
		return self:substitute_template_specs(self._data.topright)
	end
	return self._data.umbrella and self:substitute_template_specs(self._data.umbrella.topright)
end


function Category:display_title(displaytitle, lang)
	if type(displaytitle) == "string" then
		displaytitle = self:substitute_template_specs(displaytitle)
	else
		displaytitle = displaytitle(self:getCategoryName(), lang)
	end
	mw.getCurrentFrame():callParserFunction("DISPLAYTITLE", "Category:" .. displaytitle)
end


function Category:get_labels_categorizing()
	local m_labels_utilities = require(labels_utilities_module)
	local pos_cat_labels, sense_cat_labels, use_tlb
	pos_cat_labels = m_labels_utilities.find_labels_for_category(self._info.label, "pos", self._lang)
	local sense_label = self._info.label:match("^(.*) terms$")
	if sense_label then
		use_tlb = true
	else
		sense_label = self._info.label:match("^terms with (.*) senses$")
	end
	if not sense_label then
		return nil
	end
	sense_cat_labels = m_labels_utilities.find_labels_for_category(sense_label, "sense", self._lang)
	if use_tlb then
		return m_labels_utilities.format_labels_categorizing(pos_cat_labels, sense_cat_labels, self._lang)
	end
	local all_labels = pos_cat_labels
	for k, v in pairs(sense_cat_labels) do
		all_labels[k] = v
	end
	return m_labels_utilities.format_labels_categorizing(all_labels, nil, self._lang)
end

-- FIXME: this is clunky.
local function remove_lang_params(desc)
	-- Simply remove a language name/code/category from the beginning of the string, but replace the language name
	-- in the middle of the string with either "specific languages" or "specific-language" depending on whether the
	-- language name appears to be an attributive qualifier of another noun or to stand by itself. This may be wrong,
	-- in which case the category in question should supply its own umbrella description.
	desc = desc:gsub("^{{{langname}}} ", "")
		:gsub("{{{langname}}} %(", "specific languages (")
		:gsub("{{{langname}}}([.,])", "specific languages%1")
		:gsub("{{{langname}}} ", "specific-language ")
		:gsub("{{{langdisp}}}", "specific languages")
		:gsub("{{{langlink}}}", "specific languages")
	return desc
end


function Category:getDescription(isChild)
	-- Allows different text in the list of a category's children
	local isChild = isChild == "child"

	if self._lang or self._info.raw then
		if not isChild and self._data.displaytitle then
			self:display_title(self._data.displaytitle, self._lang)
		end
		if self._sc then
			return self:getCategoryName() .. "."
		end
		local desc = self:substitute_template_specs(self._data.description)
		if not desc then
			return nil
		elseif isChild then
			return desc
		end
		return sparse_concat({
			self:substitute_template_specs(self._data.preceding),
			desc,
			self:substitute_template_specs(self._data.additional),
			self:substitute_template_specs(self:get_labels_categorizing()),
		}, "\n\n")
	end
	
	local umbrella = self._data.umbrella
	if not isChild and umbrella and umbrella.displaytitle then
		self:display_title(umbrella.displaytitle)
	end

	local desc = self:substitute_template_specs(umbrella and umbrella.description)
	local has_umbrella_desc = not not desc
	if not desc then
		desc = self:convert_spec_to_string(self._data.description)
		if desc then
			desc = remove_lang_params(desc)
			desc = lcfirst(desc)
			desc = desc:gsub("%.$", "")
			desc = "Categories with " .. desc .. "."
		else
			desc = "Categories with " .. self._info.label .. " in various specific languages."
		end
		desc = self:substitute_template_specs(desc)
	end
	if isChild then
		return desc
	end
	return sparse_concat({
		self:substitute_template_specs(umbrella and umbrella.preceding or not has_umbrella_desc and self._data.preceding),
		desc,
		self:substitute_template_specs(umbrella and umbrella.additional or not has_umbrella_desc and self._data.additional),
		self:substitute_template_specs("{{{umbrella_msg}}}"),
		self:substitute_template_specs(self:get_labels_categorizing()),
	}, "\n\n")
end

function Category:new_sortkey(sortkey)
	local sortkey_type = type(sortkey)
	if sortkey_type == "string" then
		sortkey = uupper(sortkey)
	elseif sortkey_type == "table" then
		function sortkey:makeSortKey()
			local sort_func = self.sort_func
			if sort_func ~= nil then
				return sort_func(self.sort_base)
			end
			local lang = self.lang
			if lang == nil then
				return self.sort_base
			end
			lang = get_lang(lang, nil, true)
			if lang == nil then
				return self.sort_base
			end
			local sc = self.sc
			if sc ~= nil then
				sc = get_script(sc)
			end
			return lang:makeSortKey(self.sort_base, sc)
		end
	end
	
	return sortkey
end

function Category:inherit_spec(spec, parent_spec, substitute_result)
	if spec == false then
		return nil
	end
	local retval = spec or parent_spec
	if substitute_result then
		retval = self:substitute_template_specs(retval)
	end
	return retval
end

function Category:canonicalize_parents_children(cats, is_children, fallback_sort_base)
	if not cats then
		return nil
	elseif type(cats) == "table" then
		if cats.name or cats.module then
			cats = {cats}
		elseif #cats == 0 then
			return nil
		end
	else
		cats = {cats}
	end

	local ret = {}

	for _, cat in ipairs(cats) do
		if type(cat) ~= "table" or not cat.name and not cat.module then
			cat = {name = cat}
		end
		insert(ret, cat)
	end

	local is_umbrella = not self._lang and not self._info.raw
	local table_type = is_children and "extra_children" or "parents"

	for i, cat in ipairs(ret) do
		local raw
		if self._info.raw or is_umbrella then
			raw = not cat.is_label
		else
			raw = cat.raw
		end
		
		local lang = self:inherit_spec(cat.lang, not raw and self._info.code or nil, "substitute")
		local sc = self:inherit_spec(cat.sc, not raw and self._info.sc or nil, "substitute")
		
		-- Get the sortkey.
		local sortkey = self:inherit_spec(cat.sort, i == 1 and fallback_sort_base and {sort_base = fallback_sort_base} or nil)
		if type(sortkey) == "table" then
			sortkey.sort_base = self:substitute_template_specs(sortkey.sort_base) or
				internal_error("Missing .sort_base in '" .. table_type .. "' .sort table for '" ..
					self._info.label .. "' category entry in module '" .. (self._data.module or "unknown") .. "'")
			if sortkey.sort_func then
				-- Not allowed to give a lang and/or script if sort_func is given.
				local bad_spec = sortkey.lang and "lang" or sortkey.sc and "sc" or nil
				if bad_spec then
					internal_error("Cannot specify both ." .. bad_spec .. " and .sort_func in '" .. table_type ..
						"' .sort table for '" .. self._info.label .. "' category entry in module '" ..
						(self._data.module or "unknown") .. "'")
				end
			else
				sortkey.lang = self:inherit_spec(sortkey.lang, lang, "substitute")
				sortkey.sc = self:inherit_spec(sortkey.sc, sc, "substitute")
			end
		else
			sortkey = self:substitute_template_specs(sortkey)
		end
		
		local name
		if cat.module then
			-- A reference to a category using another category tree module.
			if not cat.args then
				internal_error("Missing .args in '" .. table_type .. "' table with module=\"" .. cat.module .. "\" for '" ..
					self._info.label .. "' category entry in module '" .. (self._data.module or "unknown") .. "'")
			end
			name = require("Module:category tree/" .. cat.module).new(self:substitute_template_specs_in_args(cat.args))
		else
			name = cat.name
			if not name then
				internal_error("Missing .name in " .. (is_umbrella and "umbrella " or "") .. "'" .. table_type .. "' table for '" ..
					self._info.label .. "' category entry in module '" .. (self._data.module or "unknown") .. "'")
			elseif type(name) == "string" then -- otherwise, assume it's a category object and use it directly
				name = self:substitute_template_specs(name)
				if name:find("^Category:") then
					-- It's a non-poscatboiler category name.
					sortkey = sortkey or is_children and name:gsub("^Category:", "") or self:getCategoryName()
				else
					-- It's a label.
					sortkey = sortkey or is_children and name or self._info.label
					name = self:make_new{
						label = name, code = lang, sc = sc,
						raw = raw, args = self:substitute_template_specs_in_args(cat.args)
					}
				end
			end
		end
		
		sortkey = sortkey or is_children and " " or self._info.label
		
		ret[i] = {
			name = name,
			description = is_children and self:substitute_template_specs(cat.description) or nil,
			sort = self:new_sortkey(sortkey)
		}
	end

	return ret
end


function Category:getParents()
	local is_umbrella, ret = not self._lang and not self._info.raw
	if self._sc then
		local parent1 = self:make_new{code = self._info.code, label = "terms in " .. self._sc:getCanonicalName() .. " script"}
		local parent2 = self:make_new{code = self._info.code, label = self._info.label, raw = self._info.raw, args = self._info.args}

		ret = {
			{name = parent1, sort = self._sc:getCanonicalName()},
			{name = parent2, sort = self._sc:getCanonicalName()},
		}
	else
		local parents, fallback_sort_base
		if is_umbrella then
			parents = self._data.umbrella and self._data.umbrella.parents or self._data.umbrella_parents
			fallback_sort_base = self._data.umbrella and self._data.umbrella.breadcrumb_and_first_sort_base or nil
		else
			parents = self._data.parents
			fallback_sort_base = self._data.breadcrumb_and_first_sort_base
		end

		ret = self:canonicalize_parents_children(parents, nil, fallback_sort_base)
		if not ret then
			return nil
		end
	end

	local self_cat = self:getCategoryName()
	for _, parent in ipairs(ret) do
		local parent_cat = parent.name.getCategoryName and parent.name:getCategoryName()
		if self_cat == parent_cat then
			internal_error(("Infinite loop would occur, as parent category '%s' is the same as the child category"):format(self_cat))
		end
	end

	return ret
end


function Category:getChildren()
	local is_umbrella = not self._lang and not self._info.raw
	local children = self._data.children

	local ret = {}

	if not is_umbrella and children then
		for _, child in ipairs(children) do
			child = mw.clone(child)

			if type(child) ~= "table" then
				child = {name = child}
			end

			if not child.sort then
				child.sort = child.name
			end

			-- FIXME, is preserving the script correct?
			child.name = self:make_new{code = self._info.code, label = child.name, raw = child.raw, sc = self._info.sc}

			insert(ret, child)
		end
	end

	local extra_children
	if is_umbrella then
		extra_children = self._data.umbrella and self._data.umbrella.extra_children
	else
		extra_children = self._data.extra_children
	end

	extra_children = self:canonicalize_parents_children(extra_children, "children")
	if extra_children then
		for _, child in ipairs(extra_children) do
			insert(ret, child)
		end
	end

	return #ret > 0 and ret or nil
end


function Category:getUmbrella()
	local umbrella = self._data.umbrella
	if umbrella == false or self._info.raw or not self._lang or self._sc then
		return nil
	end
	-- If `umbrella` is a string, use that; otherwise, use the label.
	return self:make_new({label = type(umbrella) == "string" and umbrella or self._info.label})
end


function Category:getAppendix()
	-- FIXME, this should be customizable.
	local lang, label = self._lang, self._info.label
	if self._info.raw or not (lang and label) then
		return nil
	end
	local appendix = make_title(100, lang:getCanonicalName() .. " " .. label)
	return appendix.exists and appendix.fullText or nil
end


function Category:getCatfixInfo()
	if self._lang or self._sc or self._info.raw then
		local langcode, sccode, lang, sc = self._data.catfix, self._data.catfix_sc
		if langcode then
			langcode = self:substitute_template_specs(langcode)
			lang = get_lang(langcode)
		elseif langcode == nil then -- not false
			lang = self._lang
		end
		if sccode then
			sccode = self:substitute_template_specs(sccode)
			sc = get_script(sccode)
		elseif sccode == nil then -- not false
			sc = self._sc
		end
		return lang, sc
	elseif not self._data.umbrella then
		return
	end
	-- umbrella
	local langcode, sccode, lang, sc = self._data.umbrella.catfix, self._data.umbrella.catfix_sc
	if langcode then
		langcode = self:substitute_template_specs(langcode)
		lang = get_lang(langcode)
	end
	if sccode then
		sccode = self:substitute_template_specs(sccode)
		sc = get_script(sccode)
	end
	return lang, sc
end


function Category:getTOCTemplateName()
	-- This should only be invoked if getTOC() returns true, meaning to do the default algorithm, but getTOC()
	-- implements its own default algorithm.
	internal_error("This should never get called")
end


local export = {}

function export.main(info)
	local self = setmetatable({_info = info}, Category)
	
	self:initCommon()
	
	return self._data and self or nil
end

export.new = Category.new

return export
