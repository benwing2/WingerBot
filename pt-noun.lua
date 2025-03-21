-- FIXME: Needs to be converted to use the standard [[Module:headword]] module

local m_headword = require("Module:headword")
local m_gen = {
	codes = {
		["?"] = {type = "other", display = '<abbr title="gender incomplete">?</abbr>'},
		["m"] = {type = "gender", display = '<abbr title="masculine gender">m</abbr>'},
		["f"] = {type = "gender", display = '<abbr title="feminine gender">f</abbr>'},
		["p"] = {type = "number", display = '<abbr title="plural number">pl</abbr>'},
	}
}

function m_gen.format_list(list)
	local s = ""
	if not list then
		return s
	end
	list = mw.text.split(list[1], "-")
	
	for n, g in ipairs(list) do
		if (n > 1) then
			s = s .. " "
		end
		s = s .. m_gen.codes[g].display
		
	end
	s = "<span class=\"gender\">" .. s .. "</span>"
	return s
end
local m_plural = require("Module:pt-plural")
local lang = require("Module:languages").getByCode("pt")


local export = {}
local cats = {}
local PAGENAME



function export.show(frame)
    	local params = {
		[1] = {},
		[2] = {},
		
		["f"] = {},
		["f2"] = {},
		["fpl"] = {},
		["fpl2"] = {},
		["g2"] = {},
		["head"] = {},
		["meta"] = {type = "boolean"},
		["pl"] = {alias_of = 2},
		["pl2"] = {},
		["pl3"] = {},
		["qual_f"] = {},
		["qual_f2"] = {},
		["qual_g1"] = {},
		["qual_g2"] = {},
		["qual_pl"] = {},
		["qual_pl2"] = {},
		["qual_pl3"] = {},
		["unc"] = {type = "boolean"},
	}
	
    local args, unrecognized_args =
    	require("Module:parameters").process(frame:getParent().args, params, true)
    
    if next(unrecognized_args) then
    	require("Module:debug").track_unrecognized_args(unrecognized_args, "pt-noun")
    end
    
    PAGENAME = mw.title.getCurrentTitle().text

    -- for compatibility with old pt-noun
    if (args[2] == "s") then args[2] = PAGENAME .. "s"
    elseif (args[2] == "es") then args[2] = PAGENAME .. "es" end

    local is_plural = get_is_plural(args[1], args["g2"])
	
    local items = {}
    table.insert(items, get_countability(args, is_plural))
    table.insert(items, get_lemma_plurals(args, is_plural))
    table.insert(items, get_feminine(args["f"], args["qual_f"], is_plural))
    table.insert(items, get_feminine_plural(args["f"], args["fpl"], args["qual_fpl"], args[2] == "-", is_plural))
    table.insert(items, get_feminine(args["f2"], args["qual_f2"], is_plural))
    table.insert(items, get_feminine_plural(args["f2"], args["fpl2"], args["qual_fpl2"], args[2] == "-", is_plural))
    
    if args["meta"] then
    	table.insert(cats, "Portuguese nouns with metaphonic plurals")
    end
	
    return
        get_headword(args["head"]) ..
        get_genders(args[1], args["g2"], args["qual_g1"], args["qual_g2"]) ..
        get_inflection(items) ..
        get_categories()
end






-- Returns the headword. If the pagename contains spaces or hyphens, its
-- constituents are wikified.
function get_headword(head)
    if (head == nil) then
        head = PAGENAME
        local has_head_links = false

        if head:find(" ", nil, false) then
            head = mw.text.split(head, " ", true)
            head = table.concat(head, "]] [[")
            has_head_links = true
        end

        if (head:find("-", nil, false)) then
            head = mw.text.split(head, "-", true)
            head = table.concat(head, "]]-[[")
            has_head_links = true
        end

        if (has_head_links == true) then
            head = "[[" .. head .. "]]"
        end
    end
	return m_headword.full_headword({lang = lang, pos_category = "nouns", heads = {head}, categories = {}})
end




-- Returns the text containing the gender information.
-- If no gender is provided, or if the gender is '?', the entry is added to 
--     [[Category:Requests for gender in Portuguese entries]] and a request is returned.
-- If two genders are provided, the entry is added to [[Category:Portuguese
--     nouns with varying gender]].
-- If two genders are provided, but there are no qualifier for either, the
--     string (in variation) is added after the second, per [[WT:T:APT]].
function get_genders(g1, g2, g1q, g2q)

    if (g1 == "" or g1 == "?" or g1 == nil) then
        table.insert(cats, "Requests for gender in Portuguese entries")
        return " " .. please_add("gender")
    end
    
    if (g1 == "morf") then
        g1 = "m"
        g2 = "f"
    elseif (g1 == "mf") then
        g1 = "m-f"
    end

    if (g2 == "mf") then
        g2 = "m-f"
    end
	
	
	local text = " "
    if (g1 == "m-f") then
    	text = text .. m_gen.format_list({"m"}) .. ", " .. m_gen.format_list({"f"})
    else
    	text = text .. m_gen.format_list({g1})
    end
    
    text = text .. qualifier(g1q)
    if (g2 ~= "" and g2 ~= nil) then
        text = text .. " or " .. m_gen.format_list({g2}) .. qualifier(g2q)
        table.insert(cats, "Portuguese nouns with varying gender")
        if (g2q == nil and g1q == nil) then
            text = text .. qualifier("in variation")
        end
    end

    return text
end


-- Returns a boolean indicating whether the noun is plural only.
-- If true, it also adds the entry to [[Category:Portuguese pluralia tantum]].
function get_is_plural(g1, g2)
    g1 = g1 or ""
    g2 = g2 or ""
    if (mw.ustring.find(g1, "p") ~= nil or mw.ustring.find(g2, "p") ~= nil) then
        table.insert(cats, "Portuguese pluralia tantum")
        return true
    end
    return false
end


-- Returns text indicating a special status with regards to countability. These
-- are plural only, uncountable and usually uncountable.
function get_countability(args, is_plural)
    if (is_plural == true) then return "''plural only''" end
    if (args[2] == "-")  then return "''uncountable''" end
    if (args["unc"] ~= nil)  then return "''usually uncountable''" end
    return nil
end


-- Returns the text with the description, link and qualifier of a plural 
-- (i.e. "feminine plural of [[example]] (qualifier)"). If the plural is not
-- present as a parameter, [[Module:pt-plural]] is used to automatically figure
-- it out from the lemma. If that is impossible, a request is returned and the
-- entry is added to [[Category:Requests for inflections in Portuguese noun entries]].
function get_primary_plural(lemma, pl, description, class, qualifier)
	local category = ""
	local generated_plural = m_plural.get_plural(lemma)
	
	if (pl == "" or pl == nil) then
		pl = generated_plural
	elseif pl ~= generated_plural then
		category = require("Module:utilities").format_categories({lang:getCanonicalName() .. " irregular nouns"})
	end
	
	if (pl == "" or pl == nil) then
		table.insert(cats, "Requests for inflections in Portuguese noun entries")
		return please_add(description)
	end
	
	return merge(description, class, pl, qualifier) .. category
end


-- Returns the text with the desciption (always "or"), link and qualifier of an
-- alternative plural. If none is provided, nil is returned.
function get_secondary_plural(pl, class, qualifier)
    if (pl ~= nil and pl ~= "") then
        return merge(" or", class, pl, qualifier)
    end
    return ""
end

-- Puts together the text of the lemma's primary and two secondary plurals.
function get_lemma_plurals(args, is_plural)
    if (is_plural == true) then
        return nil
    end
    
    local class = {form = "p"}
    local pl = args[2];
   
    if (pl == nil or pl == "") then
        pl = args["pl"]
    end

    if (pl == "?") then
        table.insert(cats, "Requests for inflections in Portuguese noun entries")
        return please_add("plural")
    elseif (pl ~= "-") then
        local text = get_primary_plural(PAGENAME, pl, "plural", class, args["qual_pl"])
        text = text .. get_secondary_plural(args["pl2"], class, args["qual_pl2"])
        text = text .. get_secondary_plural(args["pl3"], class, args["qual_pl3"])
        return text
    end
    return nil
end


function get_feminine(f, qualifier, is_plural)
    if (f == "" or f == nil) then
        return nil
    end
    
    return merge("feminine", {form = "f"}, f, qualifier)
end


function get_feminine_plural(f, fpl, qualifier, is_unc, is_plural)
    if (is_plural == true or is_unc == true or f == nil or f == "") then
        return nil
    end
    return get_primary_plural(f, fpl, "feminine plural", {form = "p", lemma = f}, qualifier)
end


-- Returns the parenthetical part of the headword line (plurals and feminines).
function get_inflection(items)
    if (table.getn(items) == 0) then return "" end
    local text = " ("
    for c = 1, table.getn(items) do
        if (c > 1) then text = text .. ", " end
        text = text .. items[c]
    end
    return text .. ")"
end


-- Returns the text containing the categories that the entry will be added to.
function get_categories()
    return require("Module:utilities").format_categories(cats, lang)  
end







-- Nerges the form description (e.g. “plural”, “feminine”), word, its class
-- (e.g. “plural-form-of gender-mpl”) and qualifier if any.
-- FIXME: Needs better parameter names.
function merge(f, c, w, q)
    if (w == nil or w == "") then return "" end
    text = ""
    text = text .. "''" .. f .. "'' "
    text = text .. make_link(w, c)
    if (q ~= nil and q ~= "") then text = text .. qualifier(q) end
    return text
end




-- Returns a piece of text boldened and wikified (unless it is the same as the
-- pagename).
function make_link(text, accel)
	return require("Module:links").full_link({lang = lang, accel = accel, term = text}, "bold")
end


-- Returns a text with a request for lacking information.
function please_add(text)
    --table.insert(cats, "Requests for attention concerning Portuguese")
    return "<sup><small><span style='color:#AAAAAA;'>please add " .. text .. "</span></small></sup>"
end

function qualifier(text)
    if (text == nil or text == "") then return "" end
    return '&nbsp;<span class="ib-brac"><span class="qualifier-brac">(</span></span><span class="ib-content"><span class="qualifier-content">' .. text ..
'</span></span><span class="ib-brac"><span class="qualifier-brac">)</span></span>'
end



return export
