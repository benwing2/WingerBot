local export = {}

local string_utilities_module = "Module:string utilities"
local table_module = "Module:table"

-- In a locally installed Docker container containing Wiktionary, Wikibase is typically not installed because it's
-- a real pain to get working properly. In such a case, `mw.wikibase` returns nil. We now have checks in the code
-- below so it does reasonable things in the absence of Wikibase.
local wikibase = mw.wikibase

local category_name_has_suffix -- defined as export.categoryNameHasSuffix below
local get_entity = wikibase and wikibase.getEntity or nil
local get_entity_id_for_title = wikibase and wikibase.getEntityIdForTitle or nil
local gsub = string.gsub
local ipairs = ipairs
local match = string.match
local select = select
local sitelink = wikibase and wikibase.sitelink or nil
local type = type
local umatch = mw.ustring.match

--[==[
Loaders for functions in other modules, which overwrite themselves with the target function when called. This ensures modules are only loaded when needed, retains the speed/convenience of locally-declared pre-loaded functions, and has no overhead after the first call, since the target functions are called directly in any subsequent calls.]==]
	local function case_insensitive_pattern(...)
		case_insensitive_pattern = require(string_utilities_module).case_insensitive_pattern
		return case_insensitive_pattern(...)
	end
	
	local function table_flatten(...)
		table_flatten = require(table_module).flatten
		return table_flatten(...)
	end
	
--[==[
Loaders for objects, which load data (or some other object) into some variable, which can then be accessed as "foo or get_foo()", where the function get_foo sets the object to "foo" and then returns it. This ensures they are only loaded when needed, and avoids the need to check for the existence of the object each time, since once "foo" has been set, "get_foo" will not be called again.]==]
	local content_lang
	local function get_content_lang()
		content_lang, get_content_lang = mw.getContentLanguage(), nil
		return content_lang
	end

-- Implementation of getAliases() for languages, etymology languages,
-- families, scripts and writing systems.
function export.getAliases(self)
	local aliases = self._aliases
	if aliases == nil then
		aliases = (self._data or self).aliases or {}
		self._aliases = aliases
	end
	return aliases
end

-- Implementation of getVarieties() for languages, etymology languages,
-- families, scripts and writing systems. If `flatten` is passed in,
-- flatten down to a list of strings; otherwise, keep the structure.
function export.getVarieties(self, flatten)
	local varieties = self._varieties
	if varieties == nil then
		varieties = (self._data or self).varieties or {}
		self._varieties = varieties
	end
	if not flatten then
		return varieties
	end
	local flattened_varieties = self._flattened_varieties
	if flattened_varieties == nil then
		flattened_varieties = table_flatten(varieties)
		self._flattened_varieties = flattened_varieties
	end
	return flattened_varieties
end

-- Implementation of getOtherNames() for languages, etymology languages,
-- families, scripts and writing systems.
function export.getOtherNames(self)
	local other_names = self._other_names
	if other_names == nil then
		other_names = (self._data or self).other_names or {}
		self._other_names = other_names
	end
	return other_names
end

-- Implementation of getAllNames() for languages, etymology languages,
-- families, scripts and writing systems. If `notCanonical` is set,
-- the canonical name will be excluded.
function export.getAllNames(self)
	local all_names = self._allNames
	if all_names == nil then
		all_names = table_flatten{
			self:getCanonicalName(),
			self:getAliases(),
			self:getVarieties(),
			self:getOtherNames(),
		}
		self._allNames = all_names
	end
	return all_names
end

function export.hasType(self, ...)
	local n = select("#", ...)
	if n == 0 then
		error("Must specify at least one type.")
	end
	local types = self:getTypes()
	if not types[...] then
		return false
	elseif n == 1 then
		return true
	end
	local args = {...}
	for i = 2, n do
		if not types[args[i]] then
			return false
		end
	end
	return true
end

-- Implementation of template-callable getByCode() function for languages,
-- etymology languages, families and scripts. `item` is the language,
-- family or script in question; `args` is the arguments passed in by the
-- module invocation; `extra_processing`, if specified, is a function of
-- one argument (the requested property) and should return the value to
-- be returned to the caller, or nil if the property isn't recognized.
-- `extra_processing` is called after special-cased properties are handled
-- and before general-purpose processing code that works for all string
-- properties.
function export.templateGetByCode(args, extra_processing)
	-- The item that the caller wanted to look up.
	local item, itemname, list = args[1], args[2]
	if itemname == "getAllNames" then
		list = item:getAllNames()
	elseif itemname == "getOtherNames" then
		list = item:getOtherNames()
	elseif itemname == "getAliases" then
		list = item:getAliases()
	elseif itemname == "getVarieties" then
		list = item:getVarieties(true)
	end
	if list then
		local index = args[3]; if index == "" then index = nil end
		index = tonumber(index or error("Numeric index of the desired item in the list (parameter 3) has not been specified."))
		return list[index] or ""
	end

	if itemname == "getFamily" and item.getFamily then
		return item:getFamily():getCode()
	end

	if extra_processing then
		local retval = extra_processing(itemname)
		if retval then
			return retval
		end
	end

	if item[itemname] then
		local ret = item[itemname](item)
		if type(ret) == "string" then
			return ret
		end
		error("The function \"" .. itemname .. "\" did not return a string value.")
	end

	error("Requested invalid item name \"" .. itemname .. "\".")
end

-- Implementation of getCommonsCategory() for languages, etymology languages,
-- families, scripts and writing systems.
function export.getWikidataItem(self)
	local item = self._WikidataItem
	if item == nil then
		item = (self._data or self)[2]
		-- If the value is nil, it's cached as false.
		item = item ~= nil and (type(item) == "number" and "Q" .. item or item) or false
		self._WikidataItem = item
	end
	return item or nil
end

do
	local function get_wiki_article(self, project)
		local article
		-- If the project is enwiki, check the language data.
		if project == "enwiki" then
			article = (self._data or self).wikipedia_article
			if article then
				return article
			end
		end
		-- Otherwise, check the Wikidata item for a sitelink.
		local item = self:getWikidataItem()
		article = item and sitelink and sitelink(item, project) or false
		if article then
			return article
		end
		-- If there's still no article, try the parent (if any).
		local get_parent = self.getParent
		if get_parent then
			local parent = get_parent(self)
			if parent then
				return get_wiki_article(parent, project)
			end
		end
		return false
	end

	-- Implementation of getWikipediaArticle() for languages, etymology languages,
	-- families, scripts and writing systems.
	function export.getWikipediaArticle(self, noCategoryFallback, project)
		if project == nil then
			project = "enwiki"
		end
		local article
		if project == "enwiki" then
			article = self._wikipedia_article
			if article == nil then
				article = get_wiki_article(self, project)
				self._wikipedia_article = article
			end
		else
			-- If the project isn't enwiki, default to no category fallback, but
			-- this can be overridden by specifying the value `false`.
			if noCategoryFallback == nil then
				noCategoryFallback = true
			end
			local non_en_wikipedia_articles = self._non_en_wikipedia_articles
			if non_en_wikipedia_articles == nil then
				non_en_wikipedia_articles = {}
				self._non_en_wikipedia_articles = non_en_wikipedia_articles
			else
				article = non_en_wikipedia_articles[project]
			end
			if article == nil then
				article = get_wiki_article(self, project)
				non_en_wikipedia_articles[project] = article
			end
		end
		if article or noCategoryFallback then
			return article or nil
		end
		return (gsub(self:getCategoryName(), "Creole language", "Creole"))
	end
end

do
	local function get_commons_cat_claim(item)
		if item then
			local entity = get_entity and get_entity(item) or nil
			if entity then
				-- P373 is the "Commons category" property.
				local claim = entity:getBestStatements("P373")[1]
				return claim and ("Category:" .. claim.mainsnak.datavalue.value) or nil
			end
		end
	end
	
	local function get_commons_cat_sitelink(item)
		if item then
			local commons_sitelink = sitelink and sitelink(item, "commonswiki") or nil
			-- Reject any sitelinks that aren't categories.
			return commons_sitelink and match(commons_sitelink, "^Category:") and commons_sitelink or nil
		end
	end
	
	local function get_commons_cat(self)
		-- Checks are in decreasing order of likelihood for a useful match.
		-- Get the Commons Category claim from the object's item.
		local lang_item = self:getWikidataItem()
		local category = get_commons_cat_claim(lang_item)
		if category then
			return category
		end
		-- Otherwise, try the object's category's item.
		local langcat_item = get_entity_id_for_title and get_entity_id_for_title("Category:" .. self:getCategoryName()) or nil
		category = get_commons_cat_claim(langcat_item)
		if category then
			return category
		end
		-- If there's no P373 claim, there might be a sitelink on the
		-- object's category's item.
		category = get_commons_cat_sitelink(langcat_item)
		if category then
			return category
		end
		-- Otherwise, try for a sitelink on the object's own item.
		category = get_commons_cat_sitelink(lang_item)
		if category then
			return category
		end
		-- If there's still no category, try the parent (if any).
		local get_parent = self.getParent
		if get_parent then
			local parent = get_parent(self)
			if parent then
				return get_commons_cat(parent)
			end
		end
		return false
	end
	
	-- Implementation of getCommonsCategory() for languages, etymology
	-- languages, families, scripts and writing systems.
	function export.getCommonsCategory(self)
		local category
		category = self._commons_category
		-- Nil values cached as false.
		if category ~= nil then
			return category or nil
		end
		category = get_commons_cat(self)
		self._commons_category = category
		return category or nil
	end
end

function export.categoryNameHasSuffix(name, suffixes)
	for _, suffix in ipairs(suffixes) do
		if umatch(name, "%f[%w]" .. case_insensitive_pattern(suffix, "^.") .. "$") then
			return false
		end
	end
	return true
end
category_name_has_suffix = export.categoryNameHasSuffix

function export.categoryNameToCode(name, suffix, data, suffixes)
	local truncated = match(name, "(.*)" .. suffix .. "$")
	if truncated and category_name_has_suffix(truncated, suffixes) then
		local code = data[truncated] or data[(content_lang or get_content_lang()):lcfirst(truncated)]
		if code ~= nil then
			return code
		end
	end
	if not category_name_has_suffix(name, suffixes) then
		return data[name] or data[(content_lang or get_content_lang()):lcfirst(name)]
	end
	return nil
end

return export
