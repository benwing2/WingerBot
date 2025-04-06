local export = {}
local pos_functions = {}

local lang = require("Module:languages").getByCode("id")
local script = require('Module:scripts').getByCode("Latn")
local PAGENAME = mw.title.getCurrentTitle().text

function export.show(frame)
    -- FIXME: Use [[Module:parameters]].
    local args = frame:getParent().args
    local poscat = frame.args[1] or error("Part of speech has not been specified. Please pass parameter 1 to the module invocation.")

    local head = args["head"]; if head == "" then head = nil end

    local data = {
        lang = lang,
        sc = script,
        pos_category = poscat,
        categories = {}, -- Ensure initialized as an empty table
        heads = {head},
        translits = {"-"},
        inflections = {}
    }

    if pos_functions[poscat] then
        pos_functions[poscat](args, data)
    end

    return require("Module:headword").full_headword(data)
end

-- Function for nouns (common and proper)

-- Shortcuts for the plural markings
pos_functions["nouns"] = function(args, data)
    
    -- Auto-detect full reduplication
    local pagename = mw.title.getCurrentTitle().text -- Get the current page name
    if pagename:match("^([a-zA-Z]+)%-%1$") then
        local pl = {label = "plural"}
        table.insert(pl, mw.ustring.format("[[%s]]", PAGENAME))
        if args["pl2"] then table.insert(pl, args["pl2"]) end
        if args["pl3"] then table.insert(pl, args["pl3"]) end
        table.insert(data.inflections, pl)
        return -- Stop further processing
    end

    -- Initialize categories and inflections if nil (not specified)
    data.categories = data.categories or {}
    data.inflections = data.inflections or {}

    -- Main code for noun plurality
    
    -- Unknown or uncertain and requests
    if args[1] == "req" then
        table.insert(data.categories, "Requests for plural forms in Indonesian entries")
    elseif args[1] == "?" then
        table.insert(data.categories, "Indonesian nouns with unknown or uncertain plurals")
    
    -- Uncountable and semi-countable
    elseif args[1] == "-" then
        table.insert(data.categories, "Indonesian uncountable nouns")
        table.insert(data.inflections, {label = "[[Appendix:Glossary#uncountable|uncountable]]"})
    elseif args[1] == "0" then
    table.insert(data.categories, "Indonesian uncountable nouns")
    elseif args[1] == "u" then
        local pl_countable = {label = "usually [[Appendix:Glossary#uncountable|uncountable]]"}
        local pl_plural = {label = "plural"}
        table.insert(data.categories, "Indonesian countable nouns")
        table.insert(data.categories, "Indonesian uncountable nouns")
        local subwords = mw.text.split(PAGENAME, "%s")
        local firstword = subwords[1]
        local plural_form = mw.ustring.gsub("[[" .. firstword .. "]]-[[" .. firstword .. "]]", "([a-z]+%-)%1%1", "banyak %1")
        table.insert(pl_plural, plural_form)
        table.insert(data.inflections, pl_countable)
        table.insert(data.inflections, pl_plural)
    elseif args[1] == "~" then
        local pl_countable = {label = "[[Appendix:Glossary#countable|countable]] and [[Appendix:Glossary#uncountable|uncountable]]"}
        local pl_plural = {label = "plural"}
        table.insert(data.categories, "Indonesian countable nouns")
        table.insert(data.categories, "Indonesian uncountable nouns")
        local subwords = mw.text.split(PAGENAME, "%s")
        local firstword = subwords[1]
        local plural_form = mw.ustring.gsub("[[" .. firstword .. "]]-[[" .. firstword .. "]]", "([a-z]+%-)%1%1", "banyak %1")
       table.insert(pl_plural, plural_form)
       table.insert(data.inflections, pl_countable)
        table.insert(data.inflections, pl_plural)
    elseif args[1] == "pt" or args["pl"] == "p" then
        table.insert(data.categories, "Indonesian pluralia tantum")
        table.insert(data.inflections, {label = "[[Appendix:Glossary#plurale tantum|plurale tantum]]"})
    elseif args[1] == "st" or args["pl"] == "s" then
        table.insert(data.categories, "Indonesian singularia tantum")
        table.insert(data.inflections, {label = "[[Appendix:Glossary#singulare tantum|singulare tantum]]"})
    
    -- Countable
    else
        local pl = {label = "plural"}
        if not args[1] or args[1] == "+" then
            local subwords = mw.text.split(PAGENAME, "%s")
            local firstword = subwords[1]
            subwords[1] = mw.ustring.gsub("[[" .. firstword .. "]]-[[" .. firstword .. "]]", "([a-z]+%-)%1%1", "banyak %1")
            if args["pl2"] or args[2] then table.insert(pl, args["pl2"]) end
            if args["pl3"] or args[3] then table.insert(pl, args["pl3"]) end
            table.insert(pl, table.concat(subwords, " "))
        elseif args[1] == "a" then
        	local subwords = mw.text.split(PAGENAME, "%s")
            local firstword = subwords[1]
            local plural_form = "[[" .. firstword .. "]]-[[" .. firstword .. "]]"
            if #subwords > 1 then
            	for i = 2, #subwords do
            		plural_form = plural_form .. " " .. subwords[i]
            	end
            end
            table.insert(pl, plural_form)
            local para_form = "[[para]] " .. table.concat(subwords, " ")
            table.insert(pl, para_form)
            if args["pl2"] then table.insert(pl, args["pl2"]) end
            if args["pl3"] then table.insert(pl, args["pl3"]) end
        elseif args[1] == "*" then
            table.insert(pl, mw.ustring.format(PAGENAME))
            if args["pl2"] then table.insert(pl, args["pl2"]) end
            if args["pl3"] then table.insert(pl, args["pl3"]) end
            table.insert(data.inflections, pl)
            return -- Stop further processing
        end
        table.insert(data.inflections, pl)
    end
    
    -- Detect error and tracking
    if args["tr"] then
    error("The parameter |tr= is invalid. Please remove it.")
    end
    if args["nolinkhead"] then --Delete this if you have made this function
    error("The parameter |nolinkhead= does not work for now. Please remove it.")
    end
    if args["pl"] == "1" then
    error("The parameter |pl=1 is invalid. Please specify the plurality with an existing value.")
    end
    if args["pl"] == "duplication" then
    error("Please delete |pl=duplication. The template can create plurals with full reduplication without any parameter.")
    end
    if args["pl"] == "-" then
    error("Please replace |pl=- with |-. Please make sure that the noun is really UNCOUNTABLE not COUNTABLE.")
    end
    if args["pl"] then
    require("Module:debug/track")("id-noun/pl")
    end
    if args["pl"] == "0" then
    require("Module:debug/track")("id-noun/pl0")
    end
    if args[1] == "" then
    error("Please make sure that there is no empty value.")
    end
    if args["pl2"] then -- Only for tracking purpose
    require("Module:debug/track")("id-noun/pl2")
    end
    if args["pl3"] then -- Only for tracking purpose
    require("Module:debug/track")("id-noun/pl3")
    end
end

pos_functions["adjectives"] = function(args, data)
	
	-- Detect error
    if args["tr"] then
    error("The parameter |tr= is invalid. Please remove it.")
    end
    if args["nolinkhead"] then  --Delete this if you have made this function
    error("The parameter |nolinkhead= does not work for now. Please remove it.")
    end
    if args["pl"] then
    error("Indonesian adjectives don't have plurals. Please remove |pl=.")
    end
    if args[1] == "" then
    error("Please make sure that there is no empty value.")
    end
end
pos_functions["verbs"] = function(args, data)
	
	-- Detect error
    if args["tr"] then
    error("The parameter |tr= is invalid. Please remove it.")
    end
    if args["nolinkhead"] then  --Delete this if you have made this function
    error("The parameter |nolinkhead= does not work for now. Please remove it.")
    end
    if args["pl"] then
    error("Indonesian verbs don't have plurals. Please remove |pl=.")
    end
    if args[1] == "" then
    error("Please make sure that there is no empty value.")
    end
end
return export
