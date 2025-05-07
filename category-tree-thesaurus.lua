local export = {}

-- Short-circuit some unnecessarily long category trees by
-- replacing certain parent categories, when encountered, with other ones
local parent_substitutions = {}
parent_substitutions['thesaurus-only categories'] = 'all topics'
parent_substitutions['architecture'] = 'all topics'
parent_substitutions['atmosphere'] = 'nature'
parent_substitutions['businesses'] = 'food and drink'  -- for Restaurants
parent_substitutions['divination'] = 'occult'
parent_substitutions['drinking'] = 'food and drink'
parent_substitutions['earth sciences'] = 'all topics'  -- for Geography
parent_substitutions['eating'] = 'food and drink'
parent_substitutions['employment'] = 'economics'
parent_substitutions['formal sciences'] = 'sciences'
parent_substitutions['geometry'] = 'mathematics'
parent_substitutions['human activity'] = 'human behaviour'
parent_substitutions['justice'] = 'society'
parent_substitutions['language'] = 'communication'
parent_substitutions['medical signs and symptoms'] = 'health'
parent_substitutions['politics'] = 'society'
parent_substitutions['senses'] = 'perception'
parent_substitutions['social sciences'] = 'all topics'

export.parent_substitutions = parent_substitutions

return export

-- Makes a "thesaurus" object out of a "topic" object.
local function convert_topic_to_thesaurus(result)
	-- substituted category names are not allowed
	if parent_substitutions[result._info.label] ~= nil then
		error(('This category is not allowed as a Thesaurus category. "%s" (see the list of parent substitutions at [[Module:category tree/thesaurus]])'):format(result:getCategoryName()))
	end

	-- keep a copy of the topic object's metatable so we can call its functions from our overrides
	local metatable = getmetatable(result)

	-- override certain functions on the topic object with thesaurus-specific functions

	function result:getCategoryName()
		return 'Thesaurus:' .. metatable.getCategoryName(result)
	end

	function result:getDescription(isChild)
		local desc = metatable.getDescription(result)
		desc = mw.ustring.gsub(desc, ' terms([ .,])', ' thesaurus entries%1')
		desc = mw.ustring.gsub(desc, 'Category:', 'Category:Thesaurus:')
		desc = mw.ustring.gsub(desc, "'''NOTE.+$", '')
		return desc
	end

	function result:getParents()
		local parents = metatable.getParents(result)

		for key, parent in pairs(parents) do
			-- Process parent categories as follows:
			-- 1. skip non-topic cats and meta-categories that start with "List of"
			-- 2. map "en:All topics" to "English thesaurus entries" (and same for other languages), but map "All topics" itself to the root "Thesaurus" category
			-- 3. check if this parent is to be substituted, if so, substitute it
			-- 4. prepend "Thesaurus:" to all other category names
			if parent.name._info == nil or parent.name._info.raw ~= nil or string.sub(parent.name._info.label, 1, 8) == 'list of ' then
				table.remove(parents, key)
			elseif parent.name._info.label == 'all topics' or parent_substitutions[parent.name._info.label] == 'all topics' then
				if parent.name._lang == nil then
					parent.name = 'Category:Thesaurus'   -- TODO this cat needs to be Lua-ised
					parent.sort = string.lower(result._info.label)
				else
					parent.name = poscatboiler_subsystem.new({ code = parent.name._info.code, label = 'thesaurus entries' })
				end
			elseif parent_substitutions[parent.name._info.label] ~= nil then
				parent.name = convert_topic_to_thesaurus(topic_subsystem.new({
					code = parent.name._info.code,
					label = parent_substitutions[parent.name._info.label]
				}))
			else
				parent.name = convert_topic_to_thesaurus(parent.name)
			end
		end

		-- add the non-thesaurus version of this category as a parent, unless it is a thesaurus-only category
		if result._data.thesaurusonly == nil then
			table.insert(parents, { name = topic_subsystem.new(result._info), sort = ' ' })
		end
		return parents
	end

	return result
end

return export
