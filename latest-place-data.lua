local export = {}

export.force_cat = false -- set to true for testing

local m_shared = require("Module:place/shared-data")
local m_links = require("Module:links")
local debug_track_module = "Module:debug/track"
local en_utilities_module = "Module:en-utilities"

local dump = mw.dumpObject
local insert = table.insert
local internal_error = m_shared.internal_error
export.internal_error = internal_error

local function ucfirst(label)
	return mw.getContentLanguage():ucfirst(label)
end

local function lc(label)
	return mw.getContentLanguage():lc(label)
end


------------------------------------------------------------------------------------------
--                                     Basic utilities                                  --
------------------------------------------------------------------------------------------


--[==[
Return true if `force_cat` is set either in this module or in [[Module:place/shared-data]].
]==]
function export.get_force_cat()
	return export.force_cat or m_shared.force_cat
end


-- Add the page to a tracking "category". To see the pages in the "category",
-- go to [[Wiktionary:Tracking/place/PAGE]] and click on "What links here".
local function track(page)
	require(debug_track_module)("place/" .. page)
	return true
end


function export.remove_links_and_html(text)
	text = m_links.remove_links(text)
	return text:gsub("<.->", "")
end


--[==[
Return the singular version of a maybe-plural placetype, or nil if not plural.
]==]
function export.maybe_singularize(placetype)
	if not placetype then
		return nil
	end
	local retval = require(en_utilities_module).singularize(placetype)
	if retval == placetype then
		return nil
	end
	return retval
end


--[==[
Check for special pseudo-placetypes that should be ignored for categorization purposes.
]==]
function export.placetype_is_ignorable(placetype)
	return placetype == "and" or placetype == "or" or placetype:find("^%(")
end


function export.resolve_placetype_aliases(placetype)
	return export.placetype_aliases[placetype] or placetype
end


--[==[
Look up and resolve any category aliases that need to be applied to a holonym. For example,
`"country/Republic of China"` maps to `"Taiwan"` for use in categories like `"Counties in Taiwan"`. This also removes
any links.
]==]
function export.resolve_placename_cat_aliases(holonym_placetype, holonym_placename)
	local retval
	local cat_aliases = export.get_equiv_placetype_prop(holonym_placetype, function(pt)
		return export.placename_cat_aliases[pt] end)
	holonym_placename = export.remove_links_and_html(holonym_placename)
	if cat_aliases then
		retval = cat_aliases[holonym_placename]
	end
	return retval or holonym_placename
end

--[==[
Given a placetype, split the placetype into one or more potential "splits", each consisting of
a three-element list { {PREV_QUALIFIERS, THIS_QUALIFIER, BARE_PLACETYPE}}, i.e.
# the concatenation of zero or more previously-recognized qualifiers on the left, normally canonicalized (if there are
  zero such qualifiers, the value will be nil);
# a single recognized qualifier, normally canonicalized (if there is no qualifier, the value will be nil);
# the "bare placetype" on the right.
Splitting between the qualifier in (2) and the bare placetype in (3) happens at each space character, proceeding from
left to right, and stops if a qualifier isn't recognized. All placetypes are canonicalized by checking for aliases
in `placetype_aliases`, but no other checks are made as to whether the bare placetype is recognized. Canonicalization
of qualifiers does not happen if NO_CANON_QUALIFIERS is specified.

For example, given the placetype `"small beachside unincorporated community"`, the return value will be
{ {
  {nil, nil, "small beachside unincorporated community"},
  {nil, "small", "beachside unincorporated community"},
  {"small", "[[beachfront]]", "unincorporated community"},
  {"small [[beachfront]]", "[[unincorporated]]", "community"},
}}
Here, `"beachside"` is canonicalized to `"[[beachfront]]"` and `"unincorporated"` is canonicalized to
`"[[unincorporated]]"`, in both cases according to the entry in `placetype_qualifiers`.

On the other hand, if given `"small former haunted community"`, the return value will be
{ {
  {nil, nil, "small former haunted community"},
  {nil, "small", "former haunted community"},
  {"small", "former", "haunted community"},
}}
because `"small"` and `"former"` but not `"haunted"` are recognized as qualifiers.

Finally, if given `"former adr"`, the return value will be
{ {
  {nil, nil, "former adr"},
  {nil, "former", "administrative region"},
}}
because `"adr"` is a recognized placetype alias for `"administrative region"`.
]==]
function export.split_qualifiers_from_placetype(placetype, no_canon_qualifiers)
	local splits = {{nil, nil, export.resolve_placetype_aliases(placetype)}}
	local prev_qualifier = nil
	while true do
		local qualifier, bare_placetype = placetype:match("^(.-) (.*)$")
		if qualifier then
			local canon = export.placetype_qualifiers[qualifier]
			if canon == nil then
				break
			end
			local new_qualifier = qualifier
			if not no_canon_qualifiers and canon ~= false then
				if canon == true then
					new_qualifier = "[[" .. qualifier .. "]]"
				else
					new_qualifier = canon
				end
			end
			insert(splits, {prev_qualifier, new_qualifier, export.resolve_placetype_aliases(bare_placetype)})
			prev_qualifier = prev_qualifier and prev_qualifier .. " " .. new_qualifier or new_qualifier
			placetype = bare_placetype
		else
			break
		end
	end
	return splits
end

--[==[
Given a placetype (which may be pluralized), return an ordered list of equivalent placetypes to look under to find the
placetype's properties (such as the category or categories to be inserted). The return value is actually an ordered list
of objects of the form `{qualifier=``qualifier``, placetype=``equiv_placetype``}` where ``equiv_placetype`` is a
placetype whose properties to look up, derived from the passed-in placetype or from a contiguous subsequence of the
words in the passed-in placetype (always including the rightmost word in the placetype, i.e. we successively chop off
qualifier words from the left and use the remainder to find equivalent placetypes). ``qualifier`` is the remaining words
not part of the subsequence used to find ``equiv_placetype``; or nil if all words in the passed-in placetype were used
to find ``equiv_placetype``. (FIXME: This qualifier is not currently used anywhere.) The placetype passed in always
forms the first entry.

`no_fallback`, if set, disables returning equivalent placetypes based on the `fallback` setting for a placetype. This is
used in the first of two loops in find_placetype_cat_specs() in [[Module:place]] to prefer exact matches for placetypes
such as barangays with later holonyms to matches based on a fallback such as 'neighborhood' with an earlier holonym.
See the comment in that function in [[Module:place]] for a more detailed explanation of why this is needed. Only the
placetype itself, and placetype subsets created by chopping off recognized qualifiers at the beginning, are returned;
but we do not return placetype subsets if a containing placetype exists in `placetype_data`. (For example,
"overseas territory" has a fallback "dependent territory", and "overseas" is also a recognized qualifier. When
`no_fallback` is in place, without the above proviso, we would return "overseas territory" followed by "territory"
with the incorrect effect of classifying an "overseas territory" of the United Kingdom such as "Gibraltar" under
[[:Category:Territories of the United Kingdom]] instead of [[:Category:Dependenet territories of the United Kingdom]].)
As an exception, if 'historical', 'ancient', 'former' or the like are found, they proceed ignoring `no_fallback`,
because it seems tricky to handle them correctly in the presence of `no_fallback`, and historical/former placetypes
rarely occur with exact match category specs anyway.

`no_check_for_inherently_former` is necessary to prevent an infinite loop when checking for `inherently_former`.
]==]
function export.get_placetype_equivs(placetype, no_fallback, no_check_for_inherently_former)
	local equivs = {}

	-- Look up the equivalent placetype for `placetype` in `placetype_equivs`. If `placetype` is plural, also look up
	-- the equivalent for the singularized version. Return any equivalent placetype(s) found.
	local function lookup_placetype_equiv(placetype)
		local retval = {}
		local function insert_placetype_equiv_or_fallback(placetype)
			local first_placetype = #retval + 1
			while true do
				local pt_value = export.placetype_data[placetype]
				if pt_value and pt_value.fallback then
					insert(retval, pt_value.fallback)
					local last_placetype = #retval
					if last_placetype - first_placetype >= 10 then
						internal_error("Apparent loop in fallback chain: %s",
							table.concat(retval, " -> ", first_placetype, last_placetype))
					end
					placetype = pt_value.fallback
				else
					break
				end
			end
		end
		insert_placetype_equiv_or_fallback(placetype)
		local sg_placetype = export.maybe_singularize(placetype)
		-- Check for a mapping in placetype_equivs for the singularized equivalent.
		if sg_placetype then
			insert_placetype_equiv_or_fallback(sg_placetype)
		end
		return retval
	end

	-- Insert `placetype` into `equivs`, along with any fallback placetypes listed in `placetype_data`. `qualifier`
	-- is the preceding qualifier to insert into `equivs` along with the placetype (see comment at top of function). We
	-- also check to see if `placetype` is plural, and if so, insert the singularized version along with its fallbacks
	-- (if any) in `placetype_data`.
	local function do_placetype(qualifier, placetype)
		-- FIXME! The qualifier (first arg) is inserted into the table, but isn't currently used anywhere.
		local function insert_equiv(pt)
			insert(equivs, {qualifier=qualifier, placetype=pt})
		end

		-- First do the placetype itself.
		insert_equiv(placetype)
		-- Then check for a singularized equivalent.
		local sg_placetype = export.maybe_singularize(placetype)
		if sg_placetype then
			insert_equiv(sg_placetype)
		end
		if not no_fallback then
			-- Then check for a mapping in placetype_equivs, and a mapping for the singularized equivalent; add if present.
			local placetype_equiv_list = lookup_placetype_equiv(placetype)
			for _, placetype_equiv in ipairs(placetype_equiv_list) do
				insert_equiv(placetype_equiv)
			end
		end
	end

	-- Successively split off recognized qualifiers and loop over successively greater sets of qualifiers from the left.
	local splits = export.split_qualifiers_from_placetype(placetype)

	for _, split in ipairs(splits) do
		local prev_qualifier, this_qualifier, bare_placetype = unpack(split, 1, 3)
		-- First see if the rightmost split-off qualifier is in qualifier_equivs (e.g. 'former' -> 'historical').
		-- If so, create a placetype from the qualifier mapping + the following bare_placetype; then, add
		-- that placetype, and any mapping for the placetype in placetype_equivs.
		local former_qualifiers = this_qualifier and export.former_qualifiers[this_qualifier] or nil
		if not former_qualifiers and not no_check_for_inherently_former then
			former_qualifiers = export.get_equiv_placetype_prop(bare_placetype,
				function(pt) return export.placetype_data[pt] and export.placetype_data[pt].inherently_former end,
				nil, nil, "no_check_for_inherently_former"
			)
		end
		if former_qualifiers then
			-- FIXME: Should we respect `no_fallback` here? My instinct says no.
			local bare_placetype_equivs = export.get_placetype_equivs(bare_placetype, nil,
				"no_check_for_inherently_former")
			local former_type = export.get_equiv_placetype_prop_from_equivs(bare_placetype_equivs,
				function(pt) return export.placetype_data[pt] and export.placetype_data[pt].former_type end
			)
			if not former_type then
				local pt_data = export.get_equiv_placetype_prop_from_equivs(bare_placetype_equivs,
					function(pt) return export.placetype_data[pt] end
				)
				if pt_data then
					internal_error("For placetype '%s', placetype data located but `former_type` missing; placetypes searched are %s",
						bare_placetype, bare_placetype_equivs)
				else
					-- Enable error when we've verified there aren't any examples.
					track("bad-former-placetype")
					track("bad-former-placetype/" .. bare_placetype)
					--error(("For placetype '%s', unrecognized placetype following 'former'-type qualifier; searched placetype(s) %s"):
					--	format(bare_placetype, dump(bare_placetype_equivs)))
				end
			elseif former_type ~= "!" then
				for _, former_qualifier in ipairs(former_qualifiers) do
					do_placetype(prev_qualifier, former_qualifier .. " " .. former_type)
				end
				break
			end
		end

		-- Then see if the rightmost split-off qualifier is in qualifier_to_placetype_equivs
		-- (e.g. 'fictional *' -> 'fictional location'). If so, add the mapping.
		if this_qualifier and export.qualifier_to_placetype_equivs[this_qualifier] then
			insert(equivs, {qualifier=prev_qualifier, placetype=export.qualifier_to_placetype_equivs[this_qualifier]})
		end

		-- Finally, join the rightmost split-off qualifier to the previously split-off qualifiers to form a
		-- combined qualifier, and add it along with bare_placetype and any mapping in placetype_equivs for
		-- bare_placetype. NOTE: The first time through this loop, both `prev_qualifier` and `this_qualifier`
		-- are nil, and this inserts the full placetype into `equivs`.
		local qualifier = prev_qualifier and prev_qualifier .. " " .. this_qualifier or this_qualifier
		do_placetype(qualifier, bare_placetype)

		-- If `no_fallback` and there's an entry in `placetype_data` for this placetype, don't include any placetype
		-- subsets to avoid the "overseas territory treated as a territory" issue describe above.
		if no_fallback then
			if export.placetype_data[bare_placetype] then
				break
			end
			local sg_bare_placetype = export.maybe_singularize(bare_placetype)
			if sg_bare_placetype and export.placetype_data[sg_bare_placetype] then
				break
			end
		end
	end
	return equivs
end


function export.get_equiv_placetype_prop_from_equivs(equivs, fun, continue_on_nil_only)
	for _, equiv in ipairs(equivs) do
		local retval = fun(equiv.placetype)
		if continue_on_nil_only and retval ~= nil or not continue_on_nil_only and retval then
			return retval, equiv
		end
	end
	return nil, nil
end


--[==[
Given a placetype `placetype` and a function `fun` of one argument, iteratively call the function on equivalent
placetypes fetched from `get_placetype_equivs` until the function returns a non-falsy value (i.e. not {nil} or {false});
but if `continue_on_nil_only` is specified, the iterations continue until the function returns non non-{nil} value.
FIXME: We should make `continue_on_nil_only` the default; but this requires changing some callers.) When `fun` returns a
non-falsy or non-{nil} value, `get_equiv_placetype_prop` returns two values: the value returned by `fun` and the
equivalent placetype that triggered the non-falsy (or non-{nil}) return value. If `fun` never returns a non-falsy (or
non-{nil}) value, `get_equiv_placetype_prop` returns {nil} for both return values. If `placetype` is passed in as {nil},
the return value is the result of calling `fun` on {nil} (whatever it is) with {nil} for the second return value.
]==]
function export.get_equiv_placetype_prop(placetype, fun, continue_on_nil_only, no_fallback,
	no_check_for_inherently_former)
	if not placetype then
		return fun(nil), nil
	end
	return export.get_equiv_placetype_prop_from_equivs(export.get_placetype_equivs(placetype, no_fallback,
		no_check_for_inherently_former), fun, continue_on_nil_only)
end


--[==[
Given a place desc (see top of file) and a holonym object (see top of file), add a key/value into the place desc's
`holonyms_by_placetype` field corresponding to the placetype and placename of the holonym. For example, corresponding
to the holonym "c/Italy", a key "country" with the list value {"Italy"} will be added to the place desc's
`holonyms_by_placetype` field. If there is already a key with that place type, the new placename will be added to the
end of the value's list.
]==]
function export.key_holonym_into_place_desc(place_desc, holonym)
	if not holonym.placetype then
		return
	end

	local equiv_placetypes = export.get_placetype_equivs(holonym.placetype)
	local cat_placename = holonym.cat_placename
	for _, equiv in ipairs(equiv_placetypes) do
		local placetype = equiv.placetype
		if not place_desc.holonyms_by_placetype then
			place_desc.holonyms_by_placetype = {}
		end
		if not place_desc.holonyms_by_placetype[placetype] then
			place_desc.holonyms_by_placetype[placetype] = {cat_placename}
		else
			insert(place_desc.holonyms_by_placetype[placetype], cat_placename)
		end
	end
end



------------------------------------------------------------------------------------------
--                              Placename and placetype data                            --
------------------------------------------------------------------------------------------


--[==[ var:
This is a map from aliases to their canonical forms. Any placetypes appearing as keys here will be mapped to their
canonical forms in all respects, including the display form. Contrast 'placetype_equivs', which apply to categorization
and other processes but not to display.

The most important aliases are for holonym placetypes, particularly those that occur often such as "country", "state",
"province" and the like. Particularly long placetypes that mostly occur as entry placetypes (e.g.
"census-designated place") can be given abbreviations, but it is generally preferred to spell out the entry placetype.
Note also that we purposely avoid certain abbreviations that would be ambiguous (e.g. "d", which could variously be
interpreted as "department", "district" or "division").
]==]
export.placetype_aliases = {
	["acomm"] = "autonomous community",
	["adr"] = "administrative region",
	["adterr"] = "administrative territory", -- Pakistan
	["aobl"] = "autonomous oblast",
	["aokr"] = "autonomous okrug",
	["ap"] = "autonomous province",
	["apref"] = "autonomous prefecture",
	["aprov"] = "autonomous province",
	["ar"] = "autonomous region",
	["arch"] = "archipelago",
	["arep"] = "autonomous republic",
	["aterr"] = "autonomous territory",
	["bor"] = "borough",
	["c"] = "country",
	["can"] = "canton",
	["carea"] = "council area",
	["cc"] = "constituent country",
	["cdblock"] = "community development block",
	["cdep"] = "Crown dependency",
	["CDP"] = "census-designated place",
	["cdp"] = "census-designated place",
	["clcity"] = "county-level city",
	["co"] = "county",
	["cobor"] = "county borough",
	["colcity"] = "county-level city",
	["coll"] = "collectivity",
	["comm"] = "community",
	["cont"] = "continent",
	["contr"] = "continental region",
	["contregion"] = "continental region",
	["cpar"] = "civil parish",
	["damun"] = "direct-administered municipality",
	["dep"] = "dependency",
	["departmental capital"] = "department capital",
	["dept"] = "department",
	["depterr"] = "dependent territory",
	["dist"] = "district",
	["distmun"] = "district municipality",
	["div"] = "division",
	["emp"] = "empire",
	["fpref"] = "French prefecture",
	["gov"] = "governorate",
	["govnat"] = "governorate",
	["home-rule city"] = "home rule city",
	["home-rule municipality"] = "home rule municipality",
	["inner-city area"] = "inner city area",
	["ires"] = "Indian reservation",
	["isl"] = "island",
	["lbor"] = "London borough",
	["lga"] = "local government area",
	["lgarea"] = "local government area",
	["lgd"] = "local government district",
	["lgdist"] = "local government district",
	["metbor"] = "metropolitan borough",
	["metcity"] = "metropolitan city",
	["mtn"] = "mountain",
	["mun"] = "municipality",
	["mundist"] = "municipal district",
	["nonmetropolitan county"] = "non-metropolitan county",
	["obl"] = "oblast",
	["okr"] = "okrug",
	["p"] = "province",
	["par"] = "parish",
	["parmun"] = "parish municipality",
	["pen"] = "peninsula",
	["plcity"] = "prefecture-level city",
	["plcolony"] = "Polish colony",
	["pref"] = "prefecture",
	["prefcity"] = "prefecture-level city",
	["preflcity"] = "prefecture-level city",
	["prov"] = "province",
	["r"] = "region",
	["range"] = "mountain range",
	["rcm"] = "regional county municipality",
	["rcomun"] = "regional county municipality",
	["rdist"] = "regional district",
	["rep"] = "republic",
	["riv"] = "river",
	["rmun"] = "regional municipality",
	["robor"] = "royal borough",
	["romp"] = "Roman province",
	["runit"] = "regional unit",
	["rurmun"] = "rural municipality",
	["s"] = "state",
	["sar"] = "special administrative region",
	["spref"] = "subprefecture",
	["sprefcity"] = "sub-prefectural city",
	["sprovcity"] = "subprovincial city",
	["sub-prefecture-level city"] = "sub-prefectural city",
	["sub-provincial city"] = "subprovincial city",
	["sub-provincial district"] = "subprovincial district",
	["terr"] = "territory",
	["terrauth"] = "territorial authority",
	["twp"] = "township",
	["twpmun"] = "township municipality",
	["uauth"] = "unitary authority",
	["ucomm"] = "unincorporated community",
	["udist"] = "unitary district",
	["uterr"] = "union territory",
	["utwpmun"] = "united township municipality",
	["val"] = "valley",
	["voi"] = "voivodeship",
	["wcomm"] = "Welsh community",
}

--[==[ var:
These qualifiers can be prepended onto any placetype and will be handled correctly. For example, the placetype "large
city" will be displayed as such but otherwise treated exactly as if "city" were specified. Links will be added to the
remainder of the placetype as appropriate, e.g. "small voivodeship" will display as "small [[voivoideship]]" because
"voivoideship" has an entry in placetype_links. If the value is a string, the qualifier will display according to the
string. If the value is `true`, the qualifier will be linked to its corresponding Wiktionary entry.  If the value is
`false`, the qualifier will not be linked but will appear as-is. Note that these qualifiers do not override placetypes
with entries elsewhere that contain those same qualifiers. For example, the entry for "former colony" in
placetype_equivs will apply in preference to treating "former colony" as equivalent to "colony". Also note that if an
entry like "former colony" appears in either placetype_equivs or placetype_data, the qualifier and non-qualifier portions
won't automatically be linked, so it needs to be specifically included in placetype_links if linking is desired.
]==]
export.placetype_qualifiers = {
	-- generic qualifiers
	["huge"] = false,
	["tiny"] = false,
	["large"] = false,
	["mid-size"] = false,
	["mid-sized"] = false,
	["small"] = false,
	["sizable"] = false,
	["important"] = false,
	["long"] = false,
	["short"] = false,
	["major"] = false,
	["minor"] = false,
	["high"] = false,
	["low"] = false,
	["left"] = false, -- left tributary
	["right"] = false, -- right tributary
	["modern"] = false, -- for use in opposition to "ancient" in another definition
	-- "former" qualifiers
	-- FIXME: None of these can be set to `true` so they link, because it currently interferes with categorization.
	-- FIXME!
	["abandoned"] = false,
	["ancient"] = false,
	["deserted"] = false,
	["extinct"] = false,
	["former"] = false,
	["historic"] = "historical",
	["historical"] = false,
	["medieval"] = false,
	["mediaeval"] = false,
	["traditional"] = false,
	-- sea qualifiers
	["coastal"] = true,
	["inland"] = true, -- note, we also have an entry in placetype_links for 'inland sea' to get a link to [[inland sea]]
	["maritime"] = true,
	["overseas"] = true,
	["seaside"] = "[[coastal]]",
	["beachfront"] = true,
	["beachside"] = "[[beachfront]]",
	["riverside"] = true,
	-- lake qualifiers
	["freshwater"] = true,
	["saltwater"] = true,
	["endorheic"] = true,
	["oxbow"] = true,
	["ox-bow"] = true,
	-- land qualifiers
	["hilly"] = true,
	["insular"] = true,
	["peninsular"] = true,
	["chalk"] = true,
	["karst"] = true,
	["limestone"] = true,
	["mountainous"] = true,
	-- political status qualifiers
	["autonomous"] = true,
	["incorporated"] = true,
	["special"] = true,
	["unincorporated"] = true,
	-- monetary status/etc. qualifiers
	["fashionable"] = true,
	["wealthy"] = true,
	["affluent"] = true,
	["declining"] = true,
	-- city vs. rural qualifiers
	["urban"] = true,
	["suburban"] = true,
	["outlying"] = true,
	["remote"] = true,
	["rural"] = true,
	["inner"] = false,
	["outer"] = false,
	-- land use qualifiers
	["residential"] = true,
	["agricultural"] = true,
	["business"] = true,
	["commercial"] = true,
	["industrial"] = true,
	-- business use qualifiers
	["railroad"] = true,
	["railway"] = true,
	["farming"] = true,
	["fishing"] = true,
	["mining"] = true,
	["logging"] = true,
	["cattle"] = true,
	-- religious qualifiers
	["holy"] = true,
	["sacred"] = true,
	["religious"] = true,
	["secular"] = true,
	-- qualifiers for nonexistent places
	-- FIXME: None of these can be set to `true` so they link, because it currently interferes with categorization.
	-- FIXME!
	["claimed"] = false,
	["fictional"] = false,
	["mythical"] = false,
	["mythological"] = false,
	-- directional qualifiers
	["northern"] = false,
	["southern"] = false,
	["eastern"] = false,
	["western"] = false,
	["north"] = false,
	["south"] = false,
	["east"] = false,
	["west"] = false,
	["northeastern"] = false,
	["southeastern"] = false,
	["northwestern"] = false,
	["southwestern"] = false,
	["northeast"] = false,
	["southeast"] = false,
	["northwest"] = false,
	["southwest"] = false,
	-- seasonal qualifiers
	["summer"] = true, -- e.g. for 'summer capital'
	["winter"] = true,
	-- misc. qualifiers
	["planned"] = true,
	["chartered"] = true,
	["landlocked"] = true,
	["uninhabited"] = true,

}

--[==[ var:
If there's an entry here, the corresponding placetype will use the text of the value, which should be used to add links.
If the value is true, a simple link will be added around the whole placetype. If the value is "w", a link to Wikipedia
will be added around the whole placetype.
]==]
export.placetype_links = {
	["administrative capital"] = "w",
	["administrative center"] = "w",
	["administrative centre"] = "w",
	["administrative county"] = "w",
	["administrative district"] = "w",
	["administrative headquarters"] = "[[administrative]] [[headquarters]]",
	["administrative region"] = true,
	["administrative seat"] = "w",
	["administrative territory"] = "[[administrative]] [[territory]]",
	["administrative village"] = "w",
	["alliance"] = true,
	["archipelago"] = true,
	["arm"] = true,
	["associated province"] = "[[associated]] [[province]]",
	["atoll"] = true,
	["autonomous city"] = "w",
	["autonomous community"] = true,
	["autonomous oblast"] = true,
	["autonomous okrug"] = true,
	["autonomous prefecture"] = true,
	["autonomous province"] = "w",
	["autonomous region"] = "w",
	["autonomous republic"] = "w",
	["autonomous territory"] = "w",
	["bailiwick"] = true,
	["barangay"] = true, -- Philippines
	["barrio"] = true, -- Spanish-speaking countries; Philippines
	["bay"] = true,
	["beach resort"] = "w",
	["bishopric"] = true,
	["borough"] = true,
	["borough seat"] = true,
	["branch"] = true,
	["burgh"] = true,
	["caliphate"] = true,
	["canton"] = true,
	["cape"] = true,
	["capital"] = true,
	["capital city"] = true,
	["caplc"] = "[[capital]] and largest city",
	["caravan city"] = "w",
	["cathedral city"] = true,
	["cattle station"] = true, -- Australia
	["census area"] = true,
	["census-designated place"] = true, -- United States
	["census town"] = "w",
	["central business district"] = true,
	["ceremonial county"] = true,
	["channel"] = true,
	["charter community"] = "w", -- Northwest Territories, Canada
	["city-state"] = true,
	["civil parish"] = true,
	["coal city"] = "[[w:coal town|coal city]]",
	["coal town"] = "w",
	["co-capital"] = "[[co-]][[capital]]",
	["collectivity"] = "w",
	["commandery"] = true,
	["commonwealth"] = true,
	["commune"] = true,
	["community"] = true,
	["community development block"] = "w", -- India
	["comune"] = true, -- Italy, Switzerland
	["confederacy"] = true,
	["confederation"] = true,
	["constituent country"] = true,
	["continental region"] = "[[continental]] [[region]]",
	["council area"] = true,
	["county-administered city"] = "w", -- Taiwan
	["county-controlled city"] = "w", -- Taiwan
	["county-level city"] = "w", -- China
	["county borough"] = true,
	["county seat"] = true,
	["county town"] = true,
	["crater lake"] = true,
	["crown dependency"] = true,
	["Crown dependency"] = true,
	["cultural area"] = "w",
	["cultural region"] = "w",
	["department"] = true,
	["department capital"] = "[[department]] [[capital]]",
	["dependency"] = true,
	["dependent territory"] = "w",
	["deserted mediaeval village"] = "w",
	["deserted medieval village"] = "w",
	["direct-administered municipality"] = "[[w:direct-administered municipalities of China|direct-administered municipality]]",
	["direct-controlled municipality"] = "w",
	["distributary"] = true,
	["district"] = true,
	["district capital"] = "[[district]] [[capital]]",
	["district headquarters"] = "[[district]] [[headquarters]]",
	["district municipality"] = "w",
	["division"] = true,
	["division capital"] = "[[division]] [[capital]]",
	["dome"] = true,
	["dormant volcano"] = true,
	["duchy"] = true,
	["emirate"] = true,
	["empire"] = true,
	["enclave"] = true,
	["escarpment"] = true,
	["ethnographic region"] = "[[w:cultural region|ethnographic region]]", -- used in Lithuania
	["exclave"] = true,
	["external territory"] = "[[external]] [[territory]]",
	["federal city"] = "w",
	["federal district"] = true,
	["federal subject"] = "w",
	["federal territory"] = "w",
	["First Nations reserve"] = "[[First Nations]] [[w:Indian reserve|reserve]]", -- Canada
	["fjord"] = true,
	["former autonomous territory"] = "former [[w:autonomous territory|autonomous territory]]",
	["former colony"] = "former [[colony]]",
	["former maritime republic"] = "former [[maritime republic]]",
	["former polity"] = "former [[polity]]",
	["former separatist state"] = "former [[separatist]] [[state]]",
	["frazione"] = "w", -- Italy
	["French prefecture"] = "[[w:Prefectures in France|prefecture]]",
	["geographic area"] = "[[geographic]] [[area]]",
	["geographical area"] = "[[geographical]] [[area]]",
	["geographic region"] = "w",
	["geographical region"] = "w",
	["geopolitical zone"] = true, -- Nigeria
	["ghost town"] = true,
	["glen"] = true,
	["governorate"] = true,
	["greater administrative region"] = "w", -- China (historical)
	["gromada"] = "w", -- Poland (historical)
	["gulf"] = true,
	["hamlet"] = true,
	["harbor city"] = "[[harbor]] [[city]]",
	["harbour city"] = "[[harbour]] [[city]]",
	["harbor town"] = "[[harbor]] [[town]]",
	["harbour town"] = "[[harbour]] [[town]]",
	["headland"] = true,
	["headquarters"] = "w",
	["heath"] = true,
	["hill station"] = "w",
	["hill town"] = "w",
	["historic region"] = "[[w:historical region|historical region]]",
	["historical region"] = "w",
	["home rule city"] = "w",
	["home rule municipality"] = "w",
	["hot spring"] = true,
	["housing estate"] = true,
	["hromada"] = "w", -- Ukraine
	["independent city"] = true,
	["independent town"] = "[[independent city|independent town]]",
	["Indian reservation"] = "w", -- United States
	["Indian reserve"] = "w", -- Canada
	["inactive volcano"] = "[[inactive]] [[volcano]]",
	["inland sea"] = true, -- note, we also have 'inland' as a qualifier
	["inner city area"] = "[[inner city]] area",
	["island country"] = "w",
	["island group"] = "[[island]] [[group]]",
	["island municipality"] = "w",
	["islet"] = "w",
	["Israeli settlement"] = "w",
	["judicial capital"] = "w",
	["khanate"] = true,
	["kibbutz"] = true,
	["kingdom"] = true,
	["krai"] = true,
	["league"] = true,
	["legislative capital"] = "[[legislative]] [[capital]]",
	["lieutenancy area"] = "w",
	["local authority district"] = "w",
	["local government area"] = "w",
	["local government district"] = "w",
	["local government district with borough status"] = "[[w:local government district|local government district]] with [[w:borough status|borough status]]",
	["local urban district"] = "w",
	["locality"] = "[[w:locality (settlement)|locality]]",
	["London borough"] = "w",
	["macroregion"] = true,
	["marginal sea"] = true,
	["market city"] = "[[market town|market city]]",
	["market town"] = true,
	["massif"] = true,
	["megacity"] = true,
	["metropolitan borough"] = true,
	["metropolitan city"] = true,
	["metropolitan county"] = true,
	["metro station"] = true,
	["microdistrict"] = true,
	["microstate"] = true,
	["minster town"] = "[[minster]] town", -- England
	["moor"] = true,
	["moorland"] = true,
	["mountain"] = true,
	["mountain indigenous district"] = "[[w:district (Taiwan)|mountain indigenous district]]", -- Taiwan
	["mountain indigenous township"] = "[[w:township (Taiwan)|mountain indigenous township]]", -- Taiwan
	["mountain pass"] = true,
	["mountain range"] = true,
	["mountainous region"] = "[[mountainous]] [[region]]",
	["municipal district"] = "w",
	["municipality"] = true,
	["municipality with city status"] = "[[municipality]] with [[w:city status|city status]]",
	["national capital"] = "w",
	["national park"] = true,
	["new town"] = true,
	["non-city capital"] = "[[capital]]",
	["non-sovereign kingdom"] = "[[w:non-sovereign monarchy|non-sovereign kingdom]]",
	["non-sovereign monarchy"] = "w",
	["non-metropolitan county"] = "w",
	["non-metropolitan district"] = "w",
	["oblast"] = true,
	["overseas collectivity"] = "w",
	["overseas department"] = "w",
	["overseas territory"] = "w",
	["parish"] = true,
	["parish municipality"] = "[[w:parish municipality (Quebec)|parish municipality]]",
	["parish seat"] = true,
	["pass"] = "[[mountain pass|pass]]",
	["peak"] = true,
	["periphery"] = true,
	["planned community"] = true,
	["plateau"] = true,
	["Polish colony"] = "[[w:Colony (Poland)|colony]]",
	["populated place"] = "[[w:populated place|locality]]",
	["port"] = true,
	["port city"] = true,
	["port town"] = "w",
	["prefecture"] = true,
	["prefecture-level city"] = "w",
	["promontory"] = true,
	["protectorate"] = true,
	["province"] = true,
	["provincial capital"] = true,
	["new area"] = "[[w:new areas|new area]]", -- China (type of economic development zone)
	["raion"] = true,
	["regency"] = true,
	["regional capital"] = "[[regional]] [[capital]]",
	["regional county municipality"] = "w",
	["regional district"] = "w",
	["regional municipality"] = "w",
	["regional unit"] = "w",
	["registration county"] = true,
	["research base"] = "[[research]] [[base]]",
	["reservoir"] = true,
	["residental area"] = "[[residential]] area",
	["resort city"] = "w",
	["resort town"] = "w",
	["Roman province"] = "w",
	["royal borough"] = "w",
	["royal burgh"] = true,
	["royal capital"] = "w",
	["rural committee"] = "w", -- Hong Kong
	["rural community"] = "w",
	["rural municipality"] = "w",
	["rural township"] = "[[w:rural township (Taiwan)|rural township]]", -- Taiwan
	["satrapy"] = true,
	["seaport"] = true,
	["settlement"] = true,
	["sheading"] = true, -- Isle of Man
	["sheep station"] = true, -- Australia
	["shire"] = true,
	["shire county"] = "w",
	["shire town"] = true,
	["ski resort city"] = "[[ski resort]] city",
	["ski resort town"] = "[[ski resort]] town",
	["spa city"] = "[[w:spa town|spa city]]",
	["spa town"] = "w",
	["special administrative region"] = "w", -- China; North Korea; Indonesia; East Timor
	["special collectivity"] = "w",
	["special municipality"] = "w", -- formerly referred to the Taiwan article but there are also special municipalities of the Netherlands
	["special ward"] = true,
	["spit"] = true,
	["spring"] = true,
	["state capital"] = true,
	["state-level new area"] = "w",
	["state park"] = true,
	["statutory city"] = "w",
	["statutory town"] = "w",
	["strait"] = true,
	["subdistrict"] = true,
	["subdivision"] = true,
	["submerged ghost town"] = "[[submerged]] [[ghost town]]",
	["subnational kingdom"] = "[[w:subnational monarchy|subnational kingdom]]",
	["subnational monarchy"] = "w",
	["subprefecture"] = true,
	["subprovince"] = true,
	["subprovincial city"] = "w",
	["subprovincial district"] = "w",
	["sub-prefectural city"] = "w",
	["subregion"] = true,
	["suburb"] = true,
	["subway station"] = "w",
	["supercontinent"] = true,
	["tehsil"] = true,
	["territorial authority"] = "w",
	["township"] = true,
	["township municipality"] = "[[w:township municipality (Quebec)|township municipality]]",
	-- can't use templates in this code
	["town with bystatus"] = "[[town]] with [[bystatus#Norwegian Bokmål|bystatus]]",
	["traditional county"] = true,
	["traditional region"] = "w",
	["treaty port"] = "w",
	["tributary"] = true,
	["underground station"] = "w",
	["unincorporated territory"] = "w",
	["unitary authority"] = true,
	["unitary district"] = "w",
	["united township municipality"] = "[[w:united township municipality (Quebec)|united township municipality]]",
	["unrecognised country"] = "w",
	["unrecognized country"] = "w",
	["urban area"] = "[[urban]] area",
	["urban township"] = "w",
	["urban-type settlement"] = "w",
	["village municipality"] = "[[w:village municipality (Quebec)|village municipality]]",
	["voivodeship"] = true, -- Poland
	["volcano"] = true,
	["ward"] = true,
	["watercourse"] = true,
	["Welsh community"] = "[[w:community (Wales)|community]]",
}


--[==[ var:
In this table, the key qualifiers should be treated the same as the value qualifiers for categorization purposes. This
is overridden by placetype_data, placetype_equivs and qualifier_to_placetype_equivs.
]==]
export.former_qualifiers = {
	["abandoned"] = {"FORMER"},
	["ancient"] = {"ANCIENT", "FORMER"},
	["former"] = {"FORMER"},
	["extinct"] = {"FORMER"},
	["historic"] = {"FORMER"},
	["historical"] = {"FORMER"},
	["medieval"] = {"ANCIENT", "FORMER"},
	["mediaeval"] = {"ANCIENT", "FORMER"},
	["traditional"] = {"FORMER"},
}

--[==[ var:
In this table, any placetypes containing these qualifiers that do not occur in placetype_equivs or placetype_data should be
mapped to the specified placetypes for categorization purposes. Entries here are overridden by placetype_data and
placetype_equivs.
]==]
export.qualifier_to_placetype_equivs = {
	["fictional"] = "fictional location",
	["mythical"] = "mythological location",
	["mythological"] = "mythological location",
	-- For e.g. Taiwan as a "claimed province" of China; parts of Belize as claimed by Guatemala; various islands
	-- claimed by various parties in East Asia. FIXME: We should conditionalize on what is being claimed
	-- since there are also claimed capitals, e.g. Israel and Palestine claim Jerusalem as their capital.
	["claimed"] = "claimed political subdivision",
}

--[==[ var:
These contain transformations applied to certain placenames to convert them into displayed form. For example, if any of
"country/US", "country/USA" or "country/United States of America" (or "c/US", etc.) are given, the result will be
displayed as "United States".

FIXME: Placename display and cat aliases should probably be placed in the (sub)polity definitions themselves, similarly
to how city aliases are handled, instead of being segregated here.

'''NOTE''': Display aliases change what is displayed from what the editor wrote in the Wikitext. As a result, they
should (a) be non-political in nature, and (b) not involve a change where the word `the` needs to be added or removed.
For example, normalizing `US` and `USA` to `United States` for display purposes is OK but normalizing `Burma` to
`Myanmar` is not (instead a cat alias should be used) because the terms `Burma` and `Myanmar` have clear political
connotations. Similarly, we have a display alias that maps the old name of `Macedonia` as a country (but not a region!)
to `North Macedonia`, but `Republic of Macedonia` is mapped to `North Macedonia` only as a cat alias because the two
terms differ in their use of `the`. (For example, if we had a display alias mapping `Republic of Macedonia` to
`North Macedonia`, the call {{tl|place|en|the <<capital city>> of the <<c/Republic of Macedonia>>}} would wrongly
display as `the [[capital city]] of the [[North Macedonia]]`.) Generally, display normalizations tend to involve
alternative forms (e.g. abbreviations, ellipses, foreign spellings) where the normalization improves clarity and
consistency.
]==]
export.placename_display_aliases = {
	["administrative region"] = {
		["Occitanie"] = "Occitania",
	},
	["administrative territory"] = {
		["Azad Jammu and Kashmir"] = "Azad Kashmir",
	},
	["city"] = {
		["New York"] = "New York City",
		["Washington, DC"] = "Washington, D.C.",
		["Washington D.C."] = "Washington, D.C.",
		["Washington DC"] = "Washington, D.C.",
	},
	["country"] = {
		["Bosnia and Hercegovina"] = "Bosnia and Herzegovina",
		["Côte d'Ivoire"] = "Ivory Coast",
		["Macedonia"] = "North Macedonia",
		["Türkiye"] = "Turkey",
		["UAE"] = "United Arab Emirates",
		["U.A.E."] = "United Arab Emirates",
		["UK"] = "United Kingdom",
		["U.K."] = "United Kingdom",
		["US"] = "United States",
		["U.S."] = "United States",
		["USA"] = "United States",
		["U.S.A."] = "United States",
		["United States of America"] = "United States",
	},
	["province"] = {
		["Noord-Brabant"] = "North Brabant",
		["Noord-Holland"] = "North Holland",
		["Zuid-Holland"] = "South Holland",
		["Fuchien"] = "Fujian",
	},
	["region"] = {
		["Northern Ostrobothnia"] = "North Ostrobothnia",
		["Southern Ostrobothnia"] = "South Ostrobothnia",
		["North Savo"] = "Northern Savonia",
		["South Savo"] = "Southern Savonia",
		["Päijät-Häme"] = "Päijänne Tavastia",
		["Kanta-Häme"] = "Tavastia Proper",
		["Occitanie"] = "Occitania",
	},
	["republic"] = {
		["Kabardino-Balkarian Republic"] = "Kabardino-Balkar Republic",
		["Tyva Republic"] = "Tuva Republic",
	},
	["state"] = {
		["Mecklenburg-Western Pomerania"] = "Mecklenburg-Vorpommern",
	},
	["territory"] = {
		["Azad Jammu and Kashmir"] = "Azad Kashmir",
		["U.S. Virgin Islands"] = "United States Virgin Islands",
		["US Virgin Islands"] = "United States Virgin Islands",
	},
}

--[==[ var:
These contain transformations applied to the displayed form of certain placenames to convert them into the form they
will appear in categories.  For example, either of "country/Myanmar" and "country/Burma" will be categorized into
categories with "Burma" in them (but the displayed form will respect the form as input). (NOTE, the choice of names here
should not be taken to imply any political position; it is just this way because it has always been this way.)
]==]
export.placename_cat_aliases = {
	["administrative territory"] = {
		["Islamabad"] = "Islamabad Capital Territory", -- differs in the
	},
	["autonomous community"] = {
		["Valencian Community"] = "Valencia", -- differs in "the"
	},
	["autonomous okrug"] = {
		["Nenetsia"] = "Nenets Autonomous Okrug",
		["Khantia-Mansia"] = "Khanty-Mansi Autonomous Okrug",
		["Yugra"] = "Khanty-Mansi Autonomous Okrug",
	},
	["council area"] = {
		["Glasgow"] = "City of Glasgow",
		["Edinburgh"] = "City of Edinburgh",
		["Aberdeen"] = "City of Aberdeen",
		["Dundee"] = "City of Dundee",
		["Western Isles"] = "Na h-Eileanan Siar",
	},
	["country"] = {
		-- Many of these differ in use of "the"; others have politicla connotations, etc.
		["Burma"] = "Myanmar",
		["Czechia"] = "Czech Republic",
		["Nagorno-Karabakh"] = "Artsakh",
		["People's Republic of China"] = "China",
		["Republic of Armenia"] = "Armenia",
		["Republic of China"] = "Taiwan",
		["Republic of Ireland"] = "Ireland",
		["Republic of North Macedonia"] = "North Macedonia",
		["Republic of Macedonia"] = "North Macedonia",
		["State of Palestine"] = "Palestine",
		["Bosnia"] = "Bosnia and Herzegovina",
		["Congo"] = "Democratic Republic of the Congo",
		["Congo Republic"] = "Republic of the Congo",
		["Swaziland"] = "Eswatini",
		["Vatican"] = "Vatican City",
	},
	["county"] = {
		["Anglesey"] = "Isle of Anglesey",
	},
	["federal territory"] = {
		["Islamabad"] = "Islamabad Capital Territory", -- differs in "the"
	},
	["republic"] = {
		-- Only needs to include cases that aren't just shortened versions of the
		-- full federal subject name (i.e. where words like "Republic" and "Oblast"
		-- are omitted but the name is not otherwise modified). Note that a couple
		-- of minor variants are recognized as display aliases, meaning that they
		-- will be canonicalized for display as well as categorization.
		["Bashkiria"] = "Republic of Bashkortostan",
		["Chechnya"] = "Chechen Republic",
		["Chuvashia"] = "Chuvash Republic",
		["Kabardino-Balkaria"] = "Kabardino-Balkar Republic",
		["Kabardino-Balkariya"] = "Kabardino-Balkar Republic",
		["Karachay-Cherkessia"] = "Karachay-Cherkess Republic",
		["North Ossetia"] = "Republic of North Ossetia-Alania",
		["Alania"] = "Republic of North Ossetia-Alania",
		["Yakutia"] = "Sakha Republic",
		["Yakutiya"] = "Sakha Republic",
		["Republic of Yakutia (Sakha)"] = "Sakha Republic",
		["Tyva"] = "Tuva Republic",
		["Udmurtia"] = "Udmurt Republic",
	},
	["region"] = {
		["Åland"] = "Åland Islands", -- differs in "the"
	},
	["state"] = {
		["Baja California Norte"] = "Baja California",
		["Mexico"] = "State of Mexico", -- differs in "the"
	},
	["territory"] = {
		["Islamabad"] = "Islamabad Capital Territory", -- differs in "the"
	},
}


--[==[ var:
This contains placenames that should be preceded by an article (almost always "the"). '''NOTE''': There are multiple
ways that placenames can come to be preceded by "the":
# Listed here.
# Given in [[Module:place/shared-data]] with an initial "the". All such placenames are added to this map by the code
  just below the map.
# The placetype of the placename has `holonym_use_the = true` in its placetype_data.
# A regex in placename_the_re matches the placename.
Note that "the" is added only before the first holonym in a place description.
]==]
export.placename_article = {
	-- This should only contain info that can't be inferred from [[Module:place/shared-data]].
	["archipelago"] = {
		["Cyclades"] = "the",
		["Dodecanese"] = "the",
	},
	["borough"] = {
		["Bronx"] = "the",
	},
	["country"] = {
		["Holy Roman Empire"] = "the",
	},
	["empire"] = {
		["Holy Roman Empire"] = "the",
	},
	["island"] = {
		["North Island"] = "the",
		["South Island"] = "the",
	},
	["region"] = {
		["Balkans"] = "the",
		["Russian Far East"] = "the",
		["Caribbean"] = "the",
		["Caucasus"] = "the",
		["Middle East"] = "the",
		["New Territories"] = "the",
		["North Caucasus"] = "the",
		["South Caucasus"] = "the",
		["West Bank"] = "the",
		["Gaza Strip"] = "the",
	},
	["valley"] = {
		["San Fernando Valley"] = "the",
	},
}

--[==[ var:
Regular expressions to apply to determine whether we need to put 'the' before a holonym. The key "*" applies to all
holonyms, otherwise only the regexes for the holonym's placetype apply.
]==]
export.placename_the_re = {
	-- We don't need entries for peninsulas, seas, oceans, gulfs or rivers
	-- because they have holonym_use_the = true.
	["*"] = {"^Isle of ", " Islands$", " Mountains$", " Empire$", " Country$", " Region$", " District$", "^City of "},
	["bay"] = {"^Bay of "},
	["lake"] = {"^Lake of "},
	["country"] = {"^Republic of ", " Republic$"},
	["republic"] = {"^Republic of ", " Republic$"},
	["region"] = {" [Rr]egion$"},
	["river"] = {" River$"},
	["local government area"] = {"^Shire of "},
	["county"] = {"^Shire of "},
	["Indian reservation"] = {" Reservation", " Nation"},
	["tribal jurisdictional area"] = {" Reservation", " Nation"},
}

-- Now extract from the shared place data all the other places that need "the"
-- prefixed.
for _, group in ipairs(m_shared.polities) do
	for key, value in pairs(group.data) do
		local orig_key = key
		key = key:gsub(", .*$", "") -- Chop off ", England" and such from the end
		local base = key:match("^the (.*)$")
		if base then
			local divtype = value.divtype or group.default_divtype
			if not divtype then
				internal_error("Group in [[Module:place/shared-data]] is missing a default_divtype key when " ..
					"processing key %s: %s", orig_key, group)
			end
			if type(divtype) ~= "table" then
				divtype = {divtype}
			end
			for _, dt in ipairs(divtype) do
				if not export.placename_article[dt] then
					export.placename_article[dt] = {}
				end
				export.placename_article[dt][base] = "the"
			end
		end
	end
end


--[==[ var:
If any of the following holonyms are present, the associated holonyms are automatically added to the end of the list of
holonyms for categorization (but not display) purposes.
]==]
export.cat_implications = {
	["region"] = {
		["Eastern Europe"] = {"continent/Europe"},
		["Central Europe"] = {"continent/Europe"},
		["Western Europe"] = {"continent/Europe"},
		["South Europe"] = {"continent/Europe"},
		["Southern Europe"] = {"continent/Europe"},
		["Northern Europe"] = {"continent/Europe"},
		["Southeast Europe"] = {"continent/Europe"},
		["Southeastern Europe"] = {"continent/Europe"},
		["North Caucasus"] = {"continent/Europe"},
		["South Caucasus"] = {"continent/Asia"},
		["South Asia"] = {"continent/Asia"},
		["Southern Asia"] = {"continent/Asia"},
		["East Asia"] = {"continent/Asia"},
		["Eastern Asia"] = {"continent/Asia"},
		["Central Asia"] = {"continent/Asia"},
		["West Asia"] = {"continent/Asia"},
		["Western Asia"] = {"continent/Asia"},
		["Southeast Asia"] = {"continent/Asia"},
		["North Asia"] = {"continent/Asia"},
		["Northern Asia"] = {"continent/Asia"},
		["Anatolia"] = {"continent/Asia"},
		["Asia Minor"] = {"continent/Asia"},
		["Mesopotamia"] = {"continent/Asia"},
		["North Africa"] = {"continent/Africa"},
		["Central Africa"] = {"continent/Africa"},
		["West Africa"] = {"continent/Africa"},
		["East Africa"] = {"continent/Africa"},
		["Southern Africa"] = {"continent/Africa"},
		["Central America"] = {"continent/Central America"},
		["Caribbean"] = {"continent/North America"},
		["Polynesia"] = {"continent/Oceania"},
		["Micronesia"] = {"continent/Oceania"},
		["Melanesia"] = {"continent/Oceania"},
		["Siberia"] = {"country/Russia", "continent/Asia"},
		["Russian Far East"] = {"country/Russia", "continent/Asia"},
		["South Wales"] = {"constituent country/Wales", "continent/Europe"},
		["Balkans"] = {"continent/Europe"},
		["West Bank"] = {"country/Palestine", "continent/Asia"},
		["Gaza"] = {"country/Palestine", "continent/Asia"},
		["Gaza Strip"] = {"country/Palestine", "continent/Asia"},
	}
}


------------------------------------------------------------------------------------------
--                              Category and display handlers                           --
------------------------------------------------------------------------------------------


--[=[
If the holonym in `data` refers to a known polity or political subdivision, find and return the corresponding polity
key, spec and group. FIXME: This should verify that there is no mismatch between the polity's containing polities
and any of the following holonyms in the {{tl|place}} spec, as find_city_spec() does.

Returns three values:
# The ''polity key'' (the key in the data in the polity group table; often has the name of the containing polity and
  somtimes the placetype affixed, and may have `the` prefixed);
# the ''polity spec'' (object describing the polity, the value corresponding to the polity key in the data in the polity
  group table; documented in [[Module:place/shared-data]] in the intro under `==Polity subdivision tables==`);
# the ''polity group'' (the table listing a group of polities with shared properties).
]=]
local function find_polity_spec(data)
	local holonym_placetype, holonym_placename, place_desc =
		data.holonym_placetype, data.holonym_placename, data.place_desc
	for _, polity_group in ipairs(m_shared.polities) do
		-- Find the appropriate key format for the holonym (e.g. "pref/Osaka" -> "Osaka Prefecture").
		local polity_key, _ = m_shared.call_place_cat_handler(polity_group, holonym_placetype, holonym_placename)
		if polity_key then
			local polity_value = polity_group.data[polity_key]
			if polity_value then
				-- Use the group's value_transformer to ensure that default values are copied into the polity spec
				-- (polity value structure).
				polity_value = polity_group.value_transformer(polity_group, polity_key, polity_value)
				return polity_key, polity_value, polity_group
			end
		end
	end
end


local function city_type_cat_handler(data, allow_if_holonym_is_city, no_containing_polity, extracats)
	local entry_placetype, holonym_placetype, holonym_placename =
		data.entry_placetype, data.holonym_placetype, data.holonym_placename
	local plural_entry_placetype = require(en_utilities_module).pluralize(entry_placetype)
	if m_shared.generic_placetypes[plural_entry_placetype] then
		for _, group in ipairs(m_shared.polities) do
			-- Find the appropriate key format for the holonym (e.g. "pref/Osaka" -> "Osaka Prefecture").
			local key, _ = m_shared.call_place_cat_handler(group, holonym_placetype, holonym_placename)
			if key then
				local value = group.data[key]
				if value then
					-- Use the group's value_transformer to ensure that 'is_city', 'containing_polity'
					-- and 'british_spelling' keys are present if they should be.
					value = group.value_transformer(group, key, value)
					if not value.is_former_place and (not value.is_city or allow_if_holonym_is_city) then
						-- Categorize both in key, and in the larger polity that the key is part of,
						-- e.g. [[Hirakata]] goes in both "Cities in Osaka Prefecture" and
						-- "Cities in Japan". (But don't do the latter if no_containing_polity_cat is set.)
						if plural_entry_placetype == "neighborhoods" and value.british_spelling then
							plural_entry_placetype = "neighbourhoods"
						end
						local retcats = {ucfirst(plural_entry_placetype) .. " in " .. key}
						if value.containing_polity and not value.no_containing_polity_cat and not no_containing_polity then
							insert(retcats, ucfirst(plural_entry_placetype) .. " in " .. value.containing_polity)
						end
						if extracats then
							for _, cat in ipairs(extracats) do
								insert(retcats, cat)
							end
						end
						return retcats
					end
				end
			end
		end
	end
end


local function capital_city_cat_handler(data, non_city)
	local holonym_placetype, holonym_placename, place_desc =
		data.holonym_placetype, data.holonym_placename, data.place_desc
	-- The first time we're called we want to return something; otherwise we will be called for later-mentioned
	-- holonyms, which can result in wrongly classifying into e.g. `National capitals`.
	-- Simulate the loop in find_cat_specs() over holonyms so we get the proper
	-- 'Cities in ...' categories as well as the capital category/categories we add below.
	local retcats
	if not non_city and place_desc.holonyms then
		-- FIXME, this should use get_holonyms_to_check()
		for _, holonym in ipairs(place_desc.holonyms) do
			local h_placetype, h_placename = holonym.placetype, holonym.cat_placename
			if h_placetype then -- skip raw text among holonyms
				retcats = export.get_equiv_placetype_prop(h_placetype,
					function(pt) return city_type_cat_handler {
						entry_placetype = "city",
						holonym_placetype = pt,
						holonym_placename = h_placename,
						place_desc = place_desc,
					} end)
				if retcats then
					break
				end
			end
		end
	end
	if not retcats then
		retcats = {}
	end
	-- Now find the appropriate capital-type category for the placetype of the holonym,
	-- e.g. 'State capitals'. If we recognize the holonym among the known holonyms in
	-- [[Module:place/shared-data]], also add a category like 'State capitals of the United States'.
	-- Truncate e.g. 'autonomous region' to 'region', 'union territory' to 'territory' when looking
	-- up the type of capital category, if we can't find an entry for the holonym placetype itself
	-- (there's an entry for 'autonomous community').
	local capital_cat = m_shared.placetype_to_capital_cat[holonym_placetype]
	if not capital_cat then
		capital_cat = m_shared.placetype_to_capital_cat[holonym_placetype:gsub("^.* ", "")]
	end
	if capital_cat then
		capital_cat = ucfirst(capital_cat)
		local inserted_specific_variant_cat = false
		for _, group in ipairs(m_shared.polities) do
			-- Find the appropriate key format for the holonym (e.g. "pref/Osaka" -> "Osaka Prefecture").
			local key, _ = m_shared.call_place_cat_handler(group, holonym_placetype, holonym_placename)
			if key then
				local value = group.data[key]
				if value then
					-- Use the group's value_transformer to ensure that 'containing_polity'
					-- is present if it should be.
					value = group.value_transformer(group, key, value)
					if value.containing_polity and not value.no_containing_polity_cat then
						insert(retcats, capital_cat .. " of " .. value.containing_polity)
						inserted_specific_variant_cat = true
						break
					end
				end
			end
		end
		if not inserted_specific_variant_cat then
			insert(retcats, capital_cat)
		end
	else
		-- We didn't recognize the holonym placetype; just put in 'Capital cities'.
		insert(retcats, "Capital cities")
	end
	return retcats
end

local function get_holonyms_to_check(place_desc, holonym_index, include_raw_text_holonyms)
	local stop_at_also = not not holonym_index
	return function(place_desc, index)
		while true do
			index = index + 1
			local this_holonym = place_desc.holonyms[index]
			if not this_holonym or stop_at_also and this_holonym.continue_cat_loop then
				return nil
			end
			-- If not placetype, we're processing raw text, which we normally want to skip.
			if include_raw_text_holonyms or this_holonym.placetype then
				return index, this_holonym
			end
		end
	end, place_desc, holonym_index and holonym_index - 1 or 0
end


--[=[
If the holonym in `data` (in the format as passed to a category handler) refers to a city, find and return the
corresponding city key, spec and group as well as a list of the containing polities. This verifies that there is no
mismatch between the city's containing polities and any of the following holonyms in the {{tl|place}} spec.

Returns four values:
# The ''city key'' (the key in the data in the city group table; usually the same as the holonym placename passed in,
  but may be different due to following an alias, and may in rare cases have `the` prefixed);
# the ''city spec'' (object describing the city, the value corresponding to the city key in the data in the city group
  table; documented in [[Module:place/shared-data]] under `export.cities`);
# the ''city group'' (the table listing a group of cities with shared properties);
# the list of containing polities, ordered from smallest/most immediate to largest/least immediate; each element is
  a table with `name` and `divtype` properties, the latter of which has been filled out using group-level defaults if
  necessary.
]=]
local function find_city_spec(data)
	local holonym_placetype, holonym_placename, holonym_index, place_desc =
		data.holonym_placetype, data.holonym_placename, data.holonym_index, data.place_desc
	-- Check for placetypes that are equivalent to city, e.g. {{place|zh|neighborhood|preflcity/Wuhan}} should work.
	local equiv_to_city = export.get_equiv_placetype_prop(holonym_placetype, function(equiv_placetype)
		return equiv_placetype == "city"
	end)
	if not equiv_to_city then
		return nil
	end
	for _, city_group in ipairs(m_shared.cities) do
		local city_key = holonym_placename
		local city_spec = city_group.data[city_key]
		if not city_spec then
			city_key = "the " .. city_key
			city_spec = city_group.data[city_key]
		end
		if city_spec and city_spec.alias_of then
			local new_city_spec = city_group.data[city_spec.alias_of]
			if not new_city_spec then
				internal_error("City %s has an entry with non-existent alias_of=%s", city_key, city_spec.alias_of)
			end
			city_key = city_spec.alias_of
			city_spec = new_city_spec
		end
		if city_spec then
			-- For each level of containing polity, check that there are no mismatches (i.e. other polity of the same
			-- sort) mentioned. We allow a mismatch at a given level if there's also a match with the containing polity
			-- at that level. For example, in the case of Kansas City, defined in [[Module:place/shared-data]] as a city
			-- in Missouri, if we define it as {{tl|place|city|s/Missouri,Kansas}}, we ignore the mismatching state of
			-- Kansas because the correct state of Missouri was also mentioned. But imagine we are defining Newark,
			-- Delware as {{tl|place|city|s/Delaware|c/US}} and (as is the case) we have an entry for Newark, New Jersey
			-- in [[Module:place/shared-data]]. Just because the containing polity US matches isn't enough, because
			-- Newark, NJ also has New Jersey as a containing polity and there's a mismatch at that level. If there are
			-- no mismatches at any level we assume we're dealing with the right city.
			local containing_polities = m_shared.get_city_containing_polities(city_group, city_spec)
			local containing_polities_mismatch = false
			for _, polity in ipairs(containing_polities) do
				local bare_polity, _ = m_shared.construct_bare_and_linked_version(polity.name)
				local divtype = polity.divtype
				local divtype_equivs = export.get_placetype_equivs(divtype)
				for other_holonym_index, other_holonym in get_holonyms_to_check(place_desc,
					holonym_index and holonym_index + 1 or nil) do
					local this_holonym_matches = export.get_equiv_placetype_prop_from_equivs(divtype_equivs,
						function(placetype)
							return other_holonym.placetype == placetype and other_holonym.cat_placename == bare_polity
						end
					)
					if this_holonym_matches then
						-- match
					else
						local this_holonym_mismatches = export.get_equiv_placetype_prop_from_equivs(
							divtype_equivs, function(placetype)
								return other_holonym.placetype == placetype
							end
						)
						if this_holonym_mismatches then
							containing_polities_mismatch = true
							break
						end
					end
				end
				if containing_polities_mismatch then
					break
				end
			end
			if not containing_polities_mismatch then
				return city_key, city_spec, city_group, containing_polities
			end
		end
	end
end


--[=[
This is invoked specially for all placetypes (see the `*` placetype key at the bottom of `placetype_data`). This is used
in two ways:
# To add pages to generic holonym categories like [[:Category:en:Places in Merseyside, England]] (and
  [[:Category:en:Places in England]]) for any pages that have `co/Merseyside` as their holonym.
# To categorize demonyms in bare placename categories like [[:Category:en:Merseyside, England]] if the demonym
  description mentions `co/Merseyside` and doesn't mention a more specific placename that also has a category. (In this
  case there are none, but we can have demonyms at multiple levels, e.g. in France for individual villages, departments,
  administrative regions, and for the entire country, and for example we only want to categorize a demonym into
  [[:Category:France]] if no more specific category applies.) Unlike when invoked from {{tl|place}}, a demonym
  invocation only adds the most specific holonym category and not the category of any containing polity (hence if we
  add [[:Category:en:Merseyside, England]] we won't also add [[:Category:England]]).

This code also handles cities; e.g. for the first use case above, it would be used to add a page that has `city/Boston`
as a holonym to [[:Category:en:Places in Boston]], along with [[:Category:en:Places in Massachusetts, USA]] and
[[:Category:en:Places in the United States]]. The city handler tries to deal with the possibility of multiple cities
having the same name. For example, the code in [[Module:place/shared-data]] knows about the city of [[Columbus]],
[[Ohio]], which has containing polities `Ohio` (a state) and `the United States` (a country). If either containing
polity is mentioned, the handler proceeds to return the key `Columbus` (along with `Ohio, USA` and `the United States`).
Otherwise, if any other state or country is mentinoned, the handler returns nothing, and otherwise it assumes the
mentioned city is the one we're considering and returns `Columbus` etc. (NOTE: I *think* this works correctly if the
place only mentions Ohio and a holonym for a Columbus in a different country is encountered, because of the function
`augment_holonyms_with_containing_polity`, which adds the US as a holonym when Ohio is encountered. However, this may
fail for the UK because I think there's a setting preventing adding the UK as a holonym when counties in England,
council areas in Scotland, etc. are encountered. FIXME: Investigate this further.)

FIXME: The checks we do for cities to make sure the wrong containing polity isn't mentioned ought to be done for other
subdivisions as well.

The single parameter `data` is as in category handlers. The return value is a list of categories (without the preceding
language code).
]=]
local function generic_cat_handler(data)
	local holonym_placetype, holonym_placename, place_desc, from_demonym =
		data.holonym_placetype, data.holonym_placename, data.place_desc, data.from_demonym

	local retcats = {}
	local function insert_retkey(key)
		if from_demonym then
			key = key:gsub("^the ", "")
			insert(retcats, key)
		else
			insert(retcats, "Places in " .. key)
		end
	end

	for _, group in ipairs(m_shared.polities) do
		-- Find the appropriate key format for the holonym (e.g. "pref/Osaka" -> "Osaka Prefecture").
		local key, _ = m_shared.call_place_cat_handler(group, holonym_placetype, holonym_placename)
		if key then
			local value = group.data[key]
			if value then
				-- Use the group's value_transformer to ensure that 'containing_polity' and 'no_containing_polity_cat'
				-- keys are present if they should be.
				value = group.value_transformer(group, key, value)
				-- Categorize both in key, and in the larger polity that the key is part of, e.g. [[Hirakata]] goes in
				-- both [[Category:Places in Osaka Prefecture, Japan]] and [[Category:Places in Japan]]. But not when
				-- from_demonym is given as we only want demonyms in the most specific category.
				insert_retkey(key)
				if not from_demonym and value.containing_polity and not value.no_containing_polity_cat then
					insert_retkey(value.containing_polity)
				end
				return retcats
			end
		end
	end
	-- Check for cities mentioned as holonyms.
	local city_key, city_spec, city_group, containing_polities = find_city_spec(data)
	if city_spec then
		-- Add categories for the city and its containing polities.
		insert_retkey(city_key)
		for _, polity in ipairs(containing_polities) do
			local drop_dead_now = false
			-- Find the group and key corresponding to the polity.
			local polity_key, polity_value, polity_group = m_shared.find_city_containing_polity(polity)
			insert_retkey(polity_key)
			if from_demonym or polity_value.no_containing_polity_cat then
				-- Stop adding containing polities if no_containing_polity_cat is found. (Used for
				-- 'United Kingdom'.) Also if we're called from from_demonym, only add the first (most immediate)
				-- containing polity.
				break
			end
		end
		return retcats
	end
end


--[==[
This is used to add pages to "bare" categories like [[:Category:en:Georgia, USA]] for `[[Georgia]]` and any
foreign-language terms that are translations of the state of Georgia. We look at the page title (or its overridden value
in {{para|pagename}}) as well as the glosses in {{para|t}}/{{para|t2}} etc. and the modern names in {{para|modern}}. We
need to pay attention to the entry placetypes specified so we don't overcategorize; e.g. the US state of Georgia is
`[[Джорджия]]` in Russian but the country of Georgia is `[[Грузия]]`, and if we just looked for matching names, we'd get
both Russian terms categorized into both [[:Category:ru:Georgia, USA]] and [[:Category:ru:Georgia]].
]==]
function export.get_bare_categories(args, place_descs)
	local bare_cats = {}

	local possible_placetypes = {}
	for _, place_desc in ipairs(place_descs) do
		for _, placetype in ipairs(place_desc.placetypes) do
			if not export.placetype_is_ignorable(placetype) then
				local equivs = export.get_placetype_equivs(placetype)
				for _, equiv in ipairs(equivs) do
					insert(possible_placetypes, equiv.placetype)
				end
			end
		end
	end

	local city_in_placetypes = false
	for _, placetype in ipairs(possible_placetypes) do
		-- Check to see whether any variant of 'city' is in placetypes, e.g. 'capital city', 'subprovincial city',
		-- 'metropolitan city', 'prefecture-level city', etc.
		if placetype == "city" or placetype:find(" city$") then
			city_in_placetypes = true
			break
		end
	end

	local function check_term(term)
		-- Treat Wikipedia links like local ones.
		term = term:gsub("%[%[w:", "[["):gsub("%[%[wikipedia:", "[[")
		term = export.remove_links_and_html(term)
		term = term:gsub("^the ", "")
		for _, group in ipairs(m_shared.polities) do
			-- Try to find the term among the known polities.
			local cat, bare_cat = m_shared.call_place_cat_handler(group, possible_placetypes, term)
			if bare_cat then
				insert(bare_cats, bare_cat)
			end
		end

		if city_in_placetypes then
			for _, city_group in ipairs(m_shared.cities) do
				local value = city_group.data[term]
				if value then
					insert(bare_cats, value.alias_of or term)
					-- No point in looking further as we don't (currently) have categories for two distinct cities with
					-- the same name.
					break
				end
			end
		end
	end

	-- FIXME: Should we only do the following if the language is English (requires that the lang is passed in)?
	check_term(args.pagename or mw.title.getCurrentTitle().subpageText)
	for _, t in ipairs(args.t) do
		check_term(t)
	end
	for _, modern in ipairs(args.modern) do
		check_term(modern)
	end
	for _, full in ipairs(args.full) do
		check_term(full)
	end
	for _, short in ipairs(args.short) do
		check_term(short)
	end
	
	return bare_cats
end


--[==[
This is used to augment the holonyms associated with a place description with the containing polities. For example,
given the following:

`# {{tl|place|en|subprefecture|pref/Hokkaido}}.`

We auto-add Japan as another holonym so that the term gets categorized into [[:Category:Subprefectures of Japan]].
To avoid over-categorizing we need to check to make sure no other countries are specified as holonyms.
]==]
function export.augment_holonyms_with_containing_polity(place_descs)
	for _, place_desc in ipairs(place_descs) do
		if place_desc.holonyms then
			-- This ends up containing a copy of the original holonyms, with the augmented holonyms inserted in their
			-- appropriate position. We don't just put them at the end because some holonyms have use the `:also`
			-- modifier, which causes category processing to restart at that point after generating categories for a
			-- preceding holonym, and we don't want the preceding holonym's augmented holonyms interfering with
			-- categorization of a later holonym.
			local augmented_holonyms = {}
			local inserted_holonyms = {}
			for _, holonym in ipairs(place_desc.holonyms) do
				insert(augmented_holonyms, holonym)
				if holonym.placetype and not export.placetype_is_ignorable(holonym.placetype) then
					local possible_placetypes = {}
					local equivs = export.get_placetype_equivs(holonym.placetype)
					for _, equiv in ipairs(equivs) do
						insert(possible_placetypes, equiv.placetype)
					end

					for _, group in ipairs(m_shared.polities) do
						-- Try to find the term among the known polities.
						local key, _ = m_shared.call_place_cat_handler(group, possible_placetypes,
							holonym.cat_placename)
						if key then
							local value = group.data[key]
							if value then
								value = group.value_transformer(group, key, value)
								if not value.no_containing_polity_cat and value.containing_polity and
										value.containing_polity_type then
									local existing_polities_of_type
									local containing_type = value.containing_polity_type
									local function get_existing_polities_of_type(placetype)
										return export.get_equiv_placetype_prop(placetype,
											function(pt) return place_desc.holonyms_by_placetype[pt] end
										)
									end
									-- Usually there's a single containing type but write as if more than one can be
									-- specified (e.g. {"administrative region", "region"}).
									if type(containing_type) == "string" then
										existing_polities_of_type = get_existing_polities_of_type(containing_type)
									else
										for _, containing_pt in ipairs(containing_type) do
											existing_polities_of_type = get_existing_polities_of_type(containing_pt)
											if existing_polities_of_type then
												break
											end
										end
									end
									if existing_polities_of_type then
										-- Don't augment. Either the containing polity is already specified as a
										-- holonym, or some other polity is, which we consider a conflict.
									else
										if type(containing_type) == "table" then
											-- If the containing type is a list, use the first element as the canonical
											-- variant.
											containing_type = containing_type[1]
										end
										-- Don't side-effect holonyms while processing them.
										-- The existing placenames, including those in `cat_placname`, will be bare,
										-- so we need to match that.
										local bare_containing_polity, _ = m_shared.construct_bare_and_linked_version(
											value.containing_polity)
										local new_holonym = {
											-- By the time we run, the display has already been generated so we don't
											-- need to set display_placename.
											placetype = containing_type,
											cat_placename = bare_containing_polity,
										}
										insert(augmented_holonyms, new_holonym)
										-- But it is safe to modify other parts of the place_desc.
										export.key_holonym_into_place_desc(place_desc, new_holonym)
									end
								end
							end
						end
					end
				end
			end
			place_desc.holonyms = augmented_holonyms
		end
	end

	-- FIXME, consider doing cities as well.
end


-- Cat handler for district, areas, neighborhoods and suburbs. Districts are tricky because they can either be political
-- subdivisions or city neighborhoods. Areas similarly can be political subdivisions (rarely; specifically, in Kuwait),
-- city neighborhoods or larger geographical areas/regions. We handle this as follows:
-- (1) `placetype_data` cat entries for specific countries or country subdivisions take precedence over cat_handlers,
--     so if the user says {{tl|place|district|s/Maharashtra|c/India}}, we won't even be called because there is an
--     entry that categorizes into [[:Category|Districts of Maharashtra, India]].
-- (2) If we're called, we check the holonym we're called on to see if it is a recognized city, e.g. if we're called
--     using {{tl|place|district|city/Mumbai|s/Maharashtra|c/India}}. If so, we categorize under e.g.
--     [[:Category:Neighbourhoods of Mumbai]]. (Choosing the spelling "neighbourhoods" because we're in India.)
-- (3) If we're called and the holonym is not a recognized city, we check if the placetype has has_neighborhoods set.
--     If so, it's "city-like" and we categorize under the first containing polity that we recognize. For example, if
--     we're called using {{tl|place|district|town/Northampton|co/Hampshire|s/Massachusetts|c/US}}, we should recognize
--     town as "city-like" and categorize under [[:Category:Neighborhoods in Massachusetts]]. (Note "in" not "of", and
--     note the spelling "neighborhoods" because we're in the US.)
-- (4) If the holonym is not city-like, we do nothing. If there's a city or city-like placetype farther up (e.g. we're
--     called as {{tl|place|district|ward/Foo|mun/Bar|...}}), we will handle the city-like entity according to (2) or
--     (3) when called on that holonym. Otherwise either the categorization in (1) takes place or there's no
--     categorization.
local function district_neighborhood_cat_handler(data)
	local function get_plural_entry_placetype(polity_spec)
		if data.entry_placetype == "suburb" then
			return "Suburbs"
		else
			return polity_spec.british_spelling and "Neighbourhoods" or "Neighborhoods"
		end
	end

	local function check_for_city_or_city_like_holonym(data)
		local city_key, city_spec, city_group, containing_polities = find_city_spec(data)
		
		if city_key then
			local polity_key, polity_spec, polity_group = m_shared.find_city_containing_polity(containing_polities[1])
			return {get_plural_entry_placetype(polity_spec) .. " of " .. city_key}
		end
	
		-- For city-states and special top-level city-like entities like Hong Kong and Bonaire
		local this_polity_key, this_polity_spec, this_polity_group = find_polity_spec(data)
		if this_polity_spec and this_polity_spec.is_city then
			return {get_plural_entry_placetype(this_polity_spec) .. " of " .. this_polity_key}
		end
	end

	-- First check the immediate holonym to see if it's a city or a city-like top-level entity (Hong Kong, Bonaire, etc.)
	local retval = check_for_city_or_city_like_holonym(data)
	if retval then
		return retval
	end

	-- If the entry placetype is neighbo(u)rhood, assume it is a neighborhood even if there isn't a city-like
	-- entity father up the chain. (E.g. due to a mistaken use of m/ instead of mun/ for municipality.)
	local has_neighborhoods
	local entry_placetype = data.entry_placetype
	if entry_placetype == "neighborhood" or entry_placetype == "neighbourhood" or entry_placetype == "suburb" then
		has_neighborhoods = true
	else
		-- Otherwise, make sure the current holonym is city-like.
		has_neighborhoods = export.get_equiv_placetype_prop(data.holonym_placetype, function(pt)
			if export.placetype_data[pt] then
				return export.placetype_data[pt].has_neighborhoods or false
			end
		end, "continue on nil only")
	end
	if has_neighborhoods then
		-- Loop up the holonyms, looking for city and city-like entities in case of e.g. [[Sepulveda]] written
		-- {{place|en|neighborhood|valley/San Fernando Valley|city/Los Angeles|s/California|c/USA}}
		-- but also look for a recognizable poldiv, and if so categorize as "Neighborhoods in POLDIV". We need
		-- to start with the current holonym, which is especially important for neighborhoods and suburbs that
		-- may have the first holonym be a recognizable province, etc. but can't hurt otherwise. (Previously
		-- we skipped the first/current holonym.)
		for other_holonym_index, other_holonym in get_holonyms_to_check(data.place_desc,
			data.holonym_index) do
			local other_holonym_data = {
				holonym_placetype = other_holonym.placetype,
				holonym_placename = other_holonym.cat_placename,
				holonym_index = other_holonym_index,
				place_desc = data.place_desc,
			}
			local retval = check_for_city_or_city_like_holonym(other_holonym_data)
			if retval then
				return retval
			end
			local polity_key, polity_spec, polity_group = find_polity_spec(other_holonym_data)
			if polity_key then
				return {get_plural_entry_placetype(polity_spec) .. " in " .. polity_key}
			end
		end
	end
end


function export.check_already_seen_string(holonym_placename, already_seen_strings)
	local canon_placename = lc(m_links.remove_links(holonym_placename))
	if type(already_seen_strings) ~= "table" then
		already_seen_strings = {already_seen_strings}
	end
	for _, already_seen_string in ipairs(already_seen_strings) do
		if canon_placename:find(already_seen_string) then
			return true
		end
	end
	return false
end


-- Prefix display handler that adds a prefix such as "Metropolitan Borough of " to the display
-- form of holonyms. We make sure the holonym doesn't contain the prefix or some variant already.
-- We do this by checking if any of the strings in ALREADY_SEEN_STRINGS, either a single string or
-- a list of strings, or the prefix if ALREADY_SEEN_STRINGS is omitted, are found in the holonym
-- placename, ignoring case and links. If the prefix isn't already present, we create a link that
-- uses the raw form as the link destination but the prefixed form as the display form, unless the
-- holonym already has a link in it, in which case we just add the prefix.
local function prefix_display_handler(prefix, holonym_placename, already_seen_strings)
	if export.check_already_seen_string(holonym_placename, already_seen_strings or lc(prefix)) then
		return holonym_placename
	end
	if holonym_placename:find("%[%[") then
		return prefix .. " " .. holonym_placename
	end
	return prefix .. " [[" .. holonym_placename .. "]]"
end


-- Suffix display handler that adds a suffix such as " parish" to the display form of holonyms.
-- Works identically to prefix_display_handler but for suffixes instead of prefixes.
local function suffix_display_handler(suffix, holonym_placename, already_seen_strings)
	if export.check_already_seen_string(holonym_placename, already_seen_strings or lc(suffix)) then
		return holonym_placename
	end
	if holonym_placename:find("%[%[") then
		return holonym_placename .. " " .. suffix
	end
	return "[[" .. holonym_placename .. "]] " .. suffix
end

-- Display handler for boroughs. New York City boroughs are display as-is. Others are suffixed
-- with "borough".
local function borough_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_shared.new_york_boroughs[unlinked_placename] then
		-- Hack: don't display "borough" after the names of NYC boroughs
		return holonym_placename
	end
	return suffix_display_handler("borough", holonym_placename)
end

local function county_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	-- Display handler for Irish counties. Irish counties are displayed as e.g. "County [[Cork]]".
	if m_shared.ireland_counties["County " .. unlinked_placename .. ", Ireland"] or
		m_shared.northern_ireland_counties["County " .. unlinked_placename .. ", Northern Ireland"] then
		return prefix_display_handler("County", holonym_placename)
	end
	-- Display handler for Taiwanese counties. Taiwanese counties are displayed as e.g. "[[Chiayi]] County".
	if m_shared.taiwan_counties[unlinked_placename .. " County, Taiwan"] then
		return suffix_display_handler("County", holonym_placename)
	end
	-- Display handler for Romanian counties. Romanian counties are displayed as e.g. "[[Cluj]] County".
	if m_shared.romania_counties[unlinked_placename .. " County, Romania"] then
		return suffix_display_handler("County", holonym_placename)
	end
	-- FIXME, we need the same for US counties but need to key off the country, not the specific county.
	-- Others are displayed as-is.
	return holonym_placename
end


-- Display handler for prefectures. Japanese prefectures are displayed as e.g. "[[Fukushima]] Prefecture".
-- Others are displayed as e.g. "[[Fthiotida]] prefecture".
local function prefecture_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	local suffix = m_shared.japan_prefectures[unlinked_placename .. " Prefecture"] and "Prefecture" or "prefecture"
	return suffix_display_handler(suffix, holonym_placename)
end

-- Display handler for provinces of North and South Korea. Korean provinces are displayed as e.g.
-- "[[Gyeonggi]] Province". Others are displayed as-is.
local function province_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_shared.north_korea_provinces[unlinked_placename .. " Province, North Korea"] or
	   m_shared.south_korea_provinces[unlinked_placename .. " Province, South Korea"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Laotian provinces. Laotian provinces are displayed as e.g. "[[Vientiane]] Province". Others
	-- are displayed as-is.
	if m_shared.laos_provinces[unlinked_placename .. " Province, Laos"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Thai provinces. Thai provinces are displayed as e.g. "[[Chachoengsao]] Province". Others are
	-- displayed as-is.
	if m_shared.thailand_provinces[unlinked_placename .. " Province, Thailand"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	return holonym_placename
end

-- Display handler for Nigerian states. Nigerian states are display as "[[Kano]] State". Others are displayed as-is.
local function state_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_shared.nigeria_states[unlinked_placename .. " State, Nigeria"] then
		return suffix_display_handler("State", holonym_placename)
	end
	return holonym_placename
end

------------------------------------------------------------------------------------------
--                                     Placetype data                                   --
------------------------------------------------------------------------------------------

--[==[ var:
Main placetype data structure. This specifies, for each canonicalized placetype, various properties. The keys are
placetypes (in the singular), and the value should normally be a table of properties. If the value is a string, it is
equivalent to having that string as the `fallback` property. The `"*"` key is special and is used for adding "generic"
categories of the form `Places in ``location`` `; it runs for all entry placetypes. Keys under the value table for a
given placetype of are two types: ''property keys'' (which specify the value of specific properties) and
''categorization keys'' (which tell how to categorize certain sorts of holonyms if the placetype in question occurs as
an entry placetype). Categorization keys are either the special value `default` or are strings with a slash in them,
such as `"city/New York City"` or `"country/*"`. Note that there are few categorization keys specified in this table
in the code itself, but the augmentation process (the code directly following the table) adds a lot more. The algorithm
for how category keys are used to generate categories is described at the top of [[Module:place]].

The following are the recognized property keys:
* `preposition`: The preposition used after this placetype when it occurs as an entry placetype. Defaults to `"in"`.
* `entry_placetype_use_the`: Use `"the"` before this placetype when it occurs as an entry placetype.
* `entry_placetype_indefinite_article`: Indefinite article used before this placetype when it occurs as an entry
  placetype (usually `"a"`, specifically for placetypes beginning with u- that don't take the indefinite article
  `"an"`). Defaults to the appropriate indefinite article (`"a"` or `"an"` depending on whether the placetype begins
  with a vowel). Overridden by `entry_placetype_use_the`, and unlike for most properties, does not apply to equivalent
  placetypes (i.e. fallbacks or those formed by removing a qualifier from the beginning); only to the exact placetype
  specified.
* `holonym_use_the`: Use `"the"` before holonyms of this placetype.
* `affix_type`: If specified, add the placetype as an affix before or after holonyms of this placetype. Possible values
  are:
*# `"pref"` (the holonym will display as `(the) placetype of Holonym`, where `the` appears when the holonym directly
   follows an entry placetype);
*# `"Pref"` (same as `"pref"` but the placetype is capitalized; each word is capitalized if there are multiple);
*# `"suf"` (the holonym will display as `Holonym placetype`);
*# `"Suf"` (the holonym will display as `Holonym Placetype`, i.e. same as `"suf"` but the placetype is capitalized).
* `suffix`: String to use in place of the placetype itself when the placetype is displayed as a suffix after a holonym.
  Note that `suffix` can be used independently of `affix_type` because the user can also request a suffix explicitly
  using a syntax like `adr:suf/Occitania`, which will display as `Occitania region` because the placetype
  `administrative region` specifies `suffix = "region"`.
* `prefix`: Like `suffix` but for use when the placetype is displayed as a prefix before the holonym.
* `affix`: Like `suffix` and `prefix` but for use when the placetype is displayed as an affix either before or after the
  holonym. If both `suffix` or `prefix` and `affix` are given for a single placetype, `suffix` or `prefix` take
  precedence.
* `no_affix_strings`: String or list of strings that, if they occur in the holonym, suppress the addition of any affix
  requested using `affix_type`. Defaults to the placetype itself. For example, `autonomous okrug` specifies
  `affix_type = "Suf"` so that `aokr/Nenets` displays as `Nenets Autonomous Okrug`, but also specifies
  `no_affix_strings = "okrug"` so that `aokr/Nenets Okrug` or `aokr/Nenets Autonomous Okrug` displays as specified,
  without a redundant `Autonomous Okrug` added. Matching is case-insensitive but whole-word.
* `fallback`: If specified, its value is a placetype which will be used for categorization purposes if no categories
  get added using the placetype itself. As an example, `branch` sets a fallback of `river` but also sets
  `preposition = "of"`, meaning that {{tl|place|en|branch|riv/Mississippi}} displays as `a branch of the Mississippi`
  (whereas `river` itself uses the preposition `in`), but otherwise categorizes the same as `river`. A more complex
  example is `area`, which sets a fallback of `geographic and cultural area` and also sets a category handler that
  checks for cities or city-like entities (e.g. boroughs) occurring as holonyms and categorizes the toponym under
  [[:Category:Neighborhoods of CITY]] (for recognized cities) or otherwise [[:Category:Neighborhoods of POLDIV]] (for
  the nearest containing recognized political subdivision or polity). In addition, `area` is set as a political
  subdivision of Kuwait, meaning if `c/Kuwait` occurs as holonym, the toponym is categorized under
  [[:Category:Areas of Kuwait]]. If none of these categories trigger, the fallback of `geographic and cultural area`
  will take effect, and the toponym will be categorized as e.g. [[:Category:Geographic and cultural areas of England]].
* `cat_handler`: A function of one argument, `data`, describing the resolved entry placetype and the holonym being
  processed. In general, the cat handler is called on successive holonyms starting with the most immediate one, until it
  returns non-nil. See below for more specifics. The return value should be a list of category specs (categories minus
  the langcode prefix, with `+++` standing for the holonym, or the value `true`, which stands for `Placetypes in/of
  Holonym`, i.e. the pluralized placetype with the appropriate preposition as specified in the `placetype_data`). `data`
  contains the following fields:
** `entry_placetype`: the resolved entry placetype for the entry placetype being processed (i.e. it will always have an
   entry in `placetype_data` but may not be the original placetype given by the user);
** `holonym_placetype` and `holonym_placename`: the holonym placetype and placename being processed;
** `holonym_index`: the index of the holonym being processed, or {nil} if we're handling an overriding holonym (FIXME:
   we will change the overriding holonym algorithm so there will be an index even when processing overriding holonyms);
** `place_desc`: a full description of the {{tl|place}} call, as specified at the top of [[Module:place]];
** `from_demonym`: If set, we are called from [[Module:demonym]], triggered by {{tl|demonym-adj}} or
   {{tl|demonym-noun}}, instead of being triggered by {{tl|place}}.
* `display_handler`: A function of two arguments, `holonym_placetype` and `holonym_placename` (specifying a holonym).
  Its return value is a string specifying the display form of the holonym.
* `former_type`: The type/class of this placetype, for use when categorizing placetypes preceded by a qualifier such as
  `former`, `ancient`, `medieval` or `historical`. (Note that these placetypes are not all treated alike.) The following
  are the possible values:
*# `polity`: a more-or-less sovereign/independent polity, such as a country, kingdom or empire.
*# `subpolity`: a non-sovereign subdivision of polity, above the level of an individual settlement.
*# `settlement`: a city or smaller equivalent, such as a village or unincorporated community. This also includes
   divisions of a settlement, such as neighborhoods, wards and barangays.
*# `capital`: a settlement that is a capital. A former capital is generally still in existence, just not the capital
   any more.
*# `natural feature`: any non-man-made feature, such as a lake, mountain, island, ocean, etc.
*# `man-made structure`: a man-made feature below the level of a neighborhood, such as a house, airport, university,
   metro station, park or the like.
*# `geographic region`: a geographic or cultural region or area that has no administrative significance. These may vary
   greatly in size but typically have some sort of cultural significance (possibly historical). The `former`, `ancient`,
   etc. qualifier has no effect on the category of these placetypes.
*# `!`: ignore the historical/former/ancient/etc. qualifier. Used e.g. with `fictional location` and
   `mythological location`.

'''NOTE:'''
# It is possible to have multiple levels of fallback (e.g. `frazione` falls back to `hamlet`, which falls back
  to `village`). Fallback loops will cause an internal error. All placetypes specified as fallbacks must exist in
  `placetype_data` or an internal error occurs; if necessary, use an empty placeholder table on the right side (but this
  is usually not a good idea because the `former_type` property should be specified).
# The `former_type` property should be specified on all placetypes that do not have a fallback (if a placetype has a
  fallback and omits the `former_type`, it is taken from the fallback). An internal error will result if a placetype
  has no `former_type` property and no fallback, and an attempt is made to categorize a former/ancient/historical/etc.
  entity of this placetype.
]==]
export.placetype_data = {

--[=[
If you need to sort the following, do this (using Vim):
1. Make sure all full-line comments are within the { ... } table, or are moved after and on the same line as single-line
   entries.
2. Make sure the table uses tabs everywhere for indent, and not spaces.
3. Mark the top of the table with `ma`, go to the bottom and execute the following two lines in sequence:
   :'a,.s/\n/\\n/g
   :s/\\n\(\t\[\)/\r\1/g
   The first command converts every newline to a literal `\n` sequence, so the whole thing becomes a single line, while
   the second command restores the newlines before the beginning of each entry. The effect is to convert all entries to
   a single line while not losing any information. (Potentially a negative lookahead could be used to do it all in one
   command.)
4. Execute the following to sort:
   :'a,.!perl -pe 's/^(\t\[")(.*?)(".*)$/$2 @@@ $1$2$3/' | sort -f | perl -pe 's/.*? @@@ //'
   Note that a simple `sort -f` (where `-f` means case-insensitive) would almost work, but it would sort "hill station"
   before "hill" and "county borough" before "county" because the space after e.g. "hill station" sorts before the
   quotation mark after e.g. "hill". The above command deals with this by extracting the key, prepending it followed by
   ` @@@ `, sorting, and then removing key (the classic decorate-sort-undecorate pattern). 
5. Put the table back to multi-line format by marking the top of the table with `ma`, going to the bottom and executing
   :'a,.s/\\n/\r/g
   Note that for some reason, in order to get a match a newline in the left side of a replacement, you must use \n, but
   to insert a newline in the right sode of a replacement you must use \r.
]=]

	["*"] = {
		cat_handler = generic_cat_handler,
	},
	["administrative capital"] = "capital city",
	["administrative center"] = "administrative centre",
	["administrative centre"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
	},
	["administrative headquarters"] = "administrative centre",
	["administrative region"] = {
		preposition = "of",
		suffix = "region", -- but prefix is still "administrative region (of)"
		fallback = "region",
		former_type = "subpolity",
	},
	["administrative seat"] = "administrative centre",
	["administrative territory"] = {
		preposition = "of",
		suffix = "territory", -- but prefix is still "administrative territory (of)"
		fallback = "territory",
		former_type = "subpolity",
	},
	["administrative village"] = {
		preposition = "of",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["airport"] = {
		former_type = "man-made structure",
		default = {true},
	},
	["alliance"] = "confederation",
	["ANCIENT capital"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
		default = {"Ancient settlements", "Historical capitals"},
	},
	["ANCIENT settlement"] = {
		has_neighborhoods = true,
		former_type = "settlement",
		default = {"Ancient settlements"},
	},
	["archipelago"] = "island",
	["area"] = {
		preposition = "of",
		fallback = "geographic and cultural area",
		former_type = "geographic region",
		cat_handler = district_neighborhood_cat_handler,
	},
	["arm"] = {
		preposition = "of",
		former_type = "natural feature",
		default = {"Seas"},
	},
	["associated province"] = "province",
	["atoll"] = {
		former_type = "natural feature",
		default = {true},
	},
	["autonomous city"] = {
		preposition = "of",
		fallback = "city",
		has_neighborhoods = true,
	},
	["autonomous community"] = {
		-- Spain; refers to regional entities, not village-like entities, as might be expected from "community"
		preposition = "of",
		former_type = "subpolity",
	},
	["autonomous oblast"] = {
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = "oblast",
		former_type = "subpolity",
	},
	["autonomous okrug"] = {
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = "okrug",
		former_type = "subpolity",
	},
	["autonomous region"] = {
		preposition = "of",
		fallback = "administrative region",
		-- "administrative region" sets an affix of "region" but we want to display as "Tibet Autonomous Region"
		-- if the user writes 'ar:Suf/Tibet'.
		affix = "autonomous region",
	},
	["autonomous republic"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["autonomous territory"] = "dependent territory",
	["bailiwick"] = "polity",
	["barangay"] = "neighborhood", -- not completely correct, barangays are formal administrative divisions of a city
	["barrio"] = "neighborhood", -- not completely correct, in some countries barrios are formal administrative divisions of a city
	["basin"] = "lake",
	["bay"] = {
		preposition = "of",
		former_type = "natural feature",
		default = {true},
	},
	["beach"] = {
		former_type = "natural feature",
		default = {true},
	},
	["bishopric"] = "polity",
	["borough"] = {
		preposition = "of",
		display_handler = borough_display_handler,
		has_neighborhoods = true,
		-- "former borough" could be a former settlement or a former part of a city but seems more likely to
		-- be a former subpolity, particularly in England. FIXME, we really need a handler to take care of this
		-- properly.
		former_type = "subpolity",
		["city/New York City"] = {"Boroughs of +++"},
		-- Grr, some boroughs are city-like but some (e.g. in Britain) may be larger.
	},
	["borough seat"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
	},
	["branch"] = {
		preposition = "of",
		fallback = "river",
	},
	["built-up area"] = "area",
	["burgh"] = "borough",
	["caliphate"] = "polity",
	["canton"] = {
		preposition = "of",
		affix_type = "suf",
		former_type = "subpolity",
	},
	["cape"] = "headland",
	["capital"] = "capital city",
	["capital city"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
		cat_handler = capital_city_cat_handler,
		default = {true},
	},
	["caplc"] = "capital city",
	["caravan city"] = {
		fallback = "city",
		former_type = "settlement",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["cathedral city"] = "city",
	["census area"] = {
		affix_type = "Suf",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["census-designated place"] = {
		-- United States
		former_type = "settlement",
	},
	["census town"] = "town",
	["central business district"] = "neighborhood",
	["ceremonial county"] = "county",
	["chain of islands"] = "island",
	["charter community"] = "village",
	["city"] = {
		has_neighborhoods = true,
		former_type = "settlement",
		cat_handler = city_type_cat_handler,
		["country/*"] = {true},
		default = {true},
	},
	["city-state"] = {
		has_neighborhoods = true,
		former_type = "settlement",
		["continent/*"] = {"City-states", "Cities", "Countries", "Countries in +++", "National capitals"},
		default = {"City-states", "Cities", "Countries", "National capitals"},
	},
	["civil parish"] = {
		-- Mostly England; similar to municipalities
		preposition = "of",
		affix_type = "suf",
		has_neighborhoods = true,
		former_type = "subpolity",
	},
	["claimed political subdivision"] = {
		former_type = "subpolity",
		default = {true},
	},
	["co-capital"] = "capital city",
	["coal city"] = "city",
	["coal town"] = "town",
	["collectivity"] = {
		preposition = "of",
		-- No default; these are weird one-off governmental divisions in France (esp. for overseas collectivities)
		former_type = "subpolity",
	},
	["colony"] = "dependent territory",
	["commandery"] = {
		preposition = "of",
		former_type = "subpolity",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["commonwealth"] = {
		preposition = "of",
		-- No default; applies specifically to Puerto Rico
		former_type = "subpolity",
	},
	["commune"] = "municipality",
	["community"] = "village",
	["community development block"] = {
		-- in India; appears to be similar to a rural municipality; groups several villages, unclear if there will be
		-- neighborhoods so I'm not setting `has_neighborhoods` for now
		affix_type = "suf",
		no_affix_strings = "block",
		former_type = "subpolity",
	},
	["comune"] = "municipality",
	["confederacy"] = "confederation",
	["confederation"] = "polity",
	["constituent country"] = {
		preposition = "of",
		fallback = "country",
		former_type = "subpolity",
	},
	["continent"] = {
		former_type = "geographic region",
		default = {true}, -- FIXME: Categorize as "Continents and continental regions"
	},
	["continental region"] = "continent",
	["council area"] = {
		-- in Scotland; similar to a county
		preposition = "of",
		affix_type = "suf",
		former_type = "subpolity",
	},
	["country"] = {
		former_type = "polity",
		["continent/*"] = {true, "Countries"},
		default = {true},
	},
	["county"] = {
		preposition = "of",
		display_handler = county_display_handler,
		former_type = "subpolity",
	},
	["county borough"] = {
		-- in Wales; similar to a county
		preposition = "of",
		affix_type = "suf",
		fallback = "borough",
		former_type = "subpolity",
	},
	["county seat"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
	},
	["county town"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		fallback = "town",
		has_neighborhoods = true,
		former_type = "capital",
	},
	["county-administered city"] = {
		-- In Taiwan, per Wikipedia similar to a Taiwanese township or district, which is a small city.
		-- NOT anything like a "county-level city" in PR China, which is a county masquerading as a city.
		fallback = "city",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["county-controlled city"] = "county-administered city",
	["county-level city"] = "prefecture-level city",
	["crater lake"] = "lake",
	["Crown dependency"] = "dependent territory",
	["crown dependency"] = "dependent territory",
	["cultural area"] = "geographic and cultural area",
	["cultural region"] = "geographic and cultural area",
	["department"] = {
		preposition = "of",
		affix_type = "suf",
		former_type = "subpolity",
	},
	["department capital"] = "capital city",
	["dependency"] = "dependent territory",
	["dependent territory"] = {
		preposition = "of",
		former_type = "dependent territory",
		["country/*"] = {true},
		default = {true},
	},
	["desert"] = {
		former_type = "natural feature",
		default = {true},
	},
	["deserted mediaeval village"] = "ANCIENT settlement",
	["deserted medieval village"] = "ANCIENT settlement",
	["direct-administered municipality"] = "municipality",
	["direct-controlled municipality"] = "municipality",
	["distributary"] = {
		preposition = "of",
		fallback = "river",
	},
	["district"] = {
		preposition = "of",
		affix_type = "suf",
		-- Grrr! FIXME! Here is where we need handlers for former_type. Using similar logic to
		-- district_neighborhood_cat_handler, we need to check if we're below or above a city to determine if the former
		-- type is "settlement" or "subpolity".
		former_type = "subpolity",
		cat_handler = district_neighborhood_cat_handler,

		-- No default. Countries for which districts are political subdivisions will get entries.
	},
	["district capital"] = "capital city",
	["district headquarters"] = "administrative centre",
	["district municipality"] = {
		-- In Canada, a district municipality is equivalent to a rural municipality and won't have neighborhoods; in
		-- South Africa, district municipalities group local municipalities and hence won't have neighborhoods.
		preposition = "of",
		affix_type = "suf",
		no_affix_strings = {"district", "municipality"},
		fallback = "municipality",
		former_type = "subpolity",
	},
	["division"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["division capital"] = "capital city",
	["dome"] = "mountain",
	["dormant volcano"] = "volcano",
	["duchy"] = "polity",
	["emirate"] = "polity",
	["empire"] = "polity",
	["enclave"] = {
		preposition = "of",
		-- enclaves can theoretically be any size but assume a subpolity.
		former_type = "subpolity",
	},
	["escarpment"] = "mountain",
	["ethnographic region"] = "geographic and cultural area", -- used in Lithuania
	["exclave"] = {
		preposition = "of",
		-- exclaves can theoretically be any size but assume a subpolity.
		former_type = "subpolity",
	},
	["external territory"] = "dependent territory",
	["federal city"] = {
		preposition = "of",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["federal district"] = {
		-- Might have neighborhoods as federal districts are often cities (e.g. Mexico City)
		preposition = "of",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["federal subject"] = {
		-- In Russia; a generic term for first-level administrative divisions (republics, oblasts, okrugs, krais,
		-- autonomous okrugs and autonomous oblasts).
		preposition = "of",
		former_type = "subpolity",
	},
	["federal territory"] = "territory",
	["fictional location"] = {
		former_type = "!",
		default = {true},
	},
	["First Nations reserve"] = {
		-- Wikipedia uses "Indian reserve"; presumably that is the legal term
		fallback = "Indian reserve",
		former_type = "subpolity",
	},
	["forest"] = {
		former_type = "natural feature",
		default = {true},
	},
	["FORMER capital"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
		-- FIXME: Here and below, we should use 'Former' in place of 'Historical'.
		default = {"Historical settlements", "Historical capitals"},
	},
	["FORMER dependent territory"] = {
		preposition = "of",
		former_type = "dependent territory",
		default = {"Historical dependent territories"},
	},
	["FORMER geographic region"] = "geographic and cultural area",
	["FORMER man-made structure"] = {
		former_type = "man-made structure",
		default = {"Former man-made structures"},
	},
	["FORMER natural feature"] = {
		former_type = "natural feature",
		default = {"Former natural features"},
	},
	["FORMER polity"] = {
		former_type = "polity",
		default = {"Historical polities"},
	},
	["FORMER settlement"] = {
		has_neighborhoods = true,
		former_type = "settlement",
		default = {"Historical settlements"},
	},
	["FORMER subpolity"] = {
		preposition = "of",
		former_type = "subpolity",
		default = {"Historical political subdivisions"},
	},
	-- a former region is considered a former political subdivision, but not a 'historical/traditional/etc.
	-- region.
	["former region"] = {
		preposition = "of",
		inherently_former = {"FORMER"},
		former_type = "subpolity",
	},
	["frazione"] = "hamlet",
	["French prefecture"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
	},
	["geographic and cultural area"] = {
		preposition = "of",
		former_type = "geographic region",
		["country/*"] = {true},
		["constituent country/*"] = {true},
		["continent/*"] = {true},
		default = {true},
	},
	["geographic area"] = "geographic and cultural area",
	["geographic region"] = "geographic and cultural area",
	["geographical area"] = "geographic and cultural area",
	["geographical region"] = "geographic and cultural area",
	["geopolitical zone"] = {
		-- Nigeria
		preposition = "of",
		former_type = "subpolity",
	},
	["ghost town"] = {
		former_type = "settlement",
	},
	["glen"] = "valley",
	["governorate"] = {
		preposition = "of",
		affix_type = "suf",
		former_type = "subpolity",
	},
	["greater administrative region"] = {
		-- China (historical subdivision)
		preposition = "of",
		former_type = "subpolity",
		inherently_former = {"FORMER"},
	},
	["gromada"] = {
		-- Poland (historical subdivision)
		preposition = "of",
		affix_type = "Pref",
		former_type = "subpolity",
		inherently_former = {"FORMER"},
	},
	["group of islands"] = "island",
	["gulf"] = {
		preposition = "of",
		holonym_use_the = true,
		former_type = "natural feature",
		default = {true},
	},
	["hamlet"] = "village",
	["harbor city"] = "city",
	["harbor town"] = "town",
	["harbour city"] = "city",
	["harbour town"] = "town",
	["headland"] = {
		former_type = "natural feature",
		default = {true},
	},
	["headquarters"] = "administrative centre",
	["heath"] = "moor",
	["hill"] = {
		former_type = "natural feature",
		default = {true},
	},
	["hill station"] = "town",
	["hill town"] = "town",
	["home rule city"] = "city",
	["home rule municipality"] = "municipality",
	["hot spring"] = "spring",
	["house"] = {
		former_type = "man-made structure",
		default = {"Individual buildings"},
	},
	["hromada"] = {
		preposition = "of",
		affix_type = "Suf",
		former_type = "subpolity",
	},
	["inactive volcano"] = "volcano",
	["independent city"] = "city",
	["independent town"] = "town",
	["Indian reservation"] = {
		-- In the US. Also known as "Native American reservation" or "domestic dependent nation", and the reservations
		-- themselves often use the term "nation" in their official name (e.g. the "Navajo Nation"). But Wikipedia puts
		-- the article at [[w:Indian reservation]] and uses that term when describing e.g. what the Navajo Nation is,
		-- so this must still be the legal term.
		preposition = "of",
		former_type = "subpolity",
		default = {true},
	},
	["Indian reserve"] = {
		-- In Canada. "First Nations reserve" sounds more modern/PC but Wikipedia uses "Indian reserve"; presumably that
		-- is still the legal term.
		preposition = "of",
		former_type = "subpolity",
		default = {true},
	},
	["inland sea"] = "sea",
	["inner city area"] = "neighborhood",
	["island"] = {
		former_type = "natural feature",
		default = {true},
	},
	["island country"] = "country", -- FIXME: The following should map to both 'island' and 'country'.
	["island group"] = "island",
	["island municipality"] = "municipality",
	["islet"] = "island",
	["judicial capital"] = "capital city",
	["khanate"] = "polity",
	["kibbutz"] = {
		plural = "kibbutzim",
		former_type = "settlement",
		default = {true},
	},
	["kingdom"] = "polity",
	["krai"] = {
		preposition = "of",
		affix_type = "Suf",
		former_type = "subpolity",
	},
	["lake"] = {
		former_type = "natural feature",
		default = {true},
	},
	["largest city"] = {
		entry_placetype_use_the = true,
		fallback = "city",
		has_neighborhoods = true,
	},
	["league"] = "confederation",
	["legislative capital"] = "capital city",
	["library"] = {
		former_type = "man-made structure",
		default = {"Individual buildings"},
	},
	["local authority district"] = "local government district",
	["local government area"] = {
		-- Australia
		preposition = "of",
		former_type = "subpolity",
	},
	["local government district"] = {
		preposition = "of",
		affix_type = "suf",
		affix = "district",
		former_type = "subpolity",
	},
	["local government district with borough status"] = {
		plural = "local government districts with borough status",
		preposition = "of",
		affix_type = "suf",
		affix = "district",
		former_type = "subpolity",
	},
	["local urban district"] = "unincorporated community",
	["locality"] = "village", -- not necessarily true, but usually is the case
	["London borough"] = {
		preposition = "of",
		affix_type = "pref",
		affix = "borough",
		fallback = "local government district with borough status",
		has_neighborhoods = true,
	},
	["macroregion"] = "region",
	["marginal sea"] = {
		preposition = "of",
		fallback = "sea",
	},
	["market city"] = "city",
	["market town"] = "town",
	["massif"] = "mountain",
	["megacity"] = "city",
	["metro station"] = {
		former_type = "man-made structure",
	},
	["metropolitan borough"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"borough", "city"},
		fallback = "local government district",
		has_neighborhoods = true,
	},
	["metropolitan city"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"metropolitan", "city"},
		fallback = "city",
		has_neighborhoods = true,
	},
	["metropolitan county"] = "county",
	["microdistrict"] = "neighborhood",
	["microstate"] = "country",
	["minster town"] = "town",
	["moor"] = {
		former_type = "natural feature",
		default = {true},
	},
	["moorland"] = "moor",
	["mountain"] = {
		former_type = "natural feature",
		default = {true},
	},
	["mountain indigenous district"] = "district",
	["mountain indigenous township"] = "township",
	["mountain pass"] = {
		former_type = "natural feature",
		default = {true},
	},
	["mountain range"] = "mountain",
	["mountainous region"] = "region",
	["municipal district"] = {
		-- meaning varies depending on the country; for now, assume no neighborhoods.
		-- FIXME: has_neighborhoods might have to be a function that looks at the containing holonyms.
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "district",
		fallback = "municipality",
	},
	["municipality"] = {
		preposition = "of",
		has_neighborhoods = true,
		former_type = "subpolity",
	},
	["municipality with city status"] = "municipality",
	["mythological location"] = {
		former_type = "!",
		default = {true},
	},
	["national capital"] = "capital city",
	["national park"] = "park",
	["neighborhood"] = {
		preposition = "of",
		former_type = "settlement",
		cat_handler = district_neighborhood_cat_handler,
		--cat_handler = function(data)
		--	return city_type_cat_handler(data, "allow if holonym is city", "no containing polity")
		--end,
	},
	["neighbourhood"] = "neighborhood",
	["new area"] = {
		-- China (type of economic development zone, varying greatly in size)
		preposition = "in",
		former_type = "subpolity", --?
	},
	["new town"] = "town",
	["non-city capital"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		former_type = "capital",
		cat_handler = function(data)
			return capital_city_cat_handler(data, "non-city")
		end,
		default = {true},
	},
	["non-metropolitan county"] = "county",
	["non-metropolitan district"] = "local government district",
	["non-sovereign kingdom"] = { -- especially in Africa and Asia
		former_type = "subpolity",
		["country/*"] = {true},
		["continent/*"] = {true},
	},
	["non-sovereign monarchy"] = "non-sovereign kingdom",
	["oblast"] = {
		preposition = "of",
		affix_type = "Suf",
		former_type = "subpolity",
	},
	["ocean"] = {
		holonym_use_the = true,
		former_type = "natural feature",
		default = {true},
	},
	["okrug"] = {
		preposition = "of",
		affix_type = "Suf",
		former_type = "subpolity",
	},
	["overseas collectivity"] = "collectivity",
	["overseas department"] = "department",
	["overseas territory"] = "dependent territory",
	["parish"] = {
		preposition = "of",
		affix_type = "suf",
		former_type = "subpolity",
	},
	["parish municipality"] = {
		-- in Quebec, often similar to a rural village; the famous [[Saint-Louis-du-Ha! Ha!]] is one of them.
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true,
	},
	["parish seat"] = {
		entry_placetype_use_the = true,
		preposition = "of",
		former_type = "capital",
		has_neighborhoods = true,
	},
	["park"] = {
		former_type = "man-made structure",
		default = {true},
	},
	["pass"] = "mountain pass",
	["peak"] = "mountain",
	["peninsula"] = {
		former_type = "natural feature",
		default = {true},
	},
	["periphery"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["planned community"] = {
		-- Include this empty so we don't categorize 'planned community' into
		-- villages, as 'community' does.
		former_type = "settlement",
		has_neighborhoods = true,
	},
	["plateau"] = "geographic and cultural area",
	["Polish colony"] = {
		affix_type = "suf",
		affix = "colony",
		fallback = "village",
		has_neighborhoods = true,
	},
	["polity"] = {
		former_type = "polity",
		default = {true},
	},
	["populated place"] = "village", -- not necessarily true, but usually is the case
	["port city"] = "city",
	["port town"] = "town",
	["prefecture"] = {
		-- FIXME! `prefecture` is like a county in Japan and elsewhere but a department capital city in France.
		-- May need `has_neighborhoods` to be a function.
		preposition = "of",
		display_handler = prefecture_display_handler,
		former_type = "subpolity",
	},
	["prefecture-level city"] = {
		-- China; they are huge entities with a central city; not cities themselves.
		preposition = "of",
		former_type = "subpolity",
	},
	["promontory"] = "headland",
	["protectorate"] = "dependent territory",
	["province"] = {
		preposition = "of",
		display_handler = province_display_handler,
		former_type = "subpolity",
	},
	["provincial capital"] = "capital city",
	["raion"] = {
		preposition = "of",
		affix_type = "Suf",
		former_type = "subpolity",
	},
	["range"] = {
		holonym_use_the = true,
		former_type = "natural feature",
	},
	["regency"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["region"] = {
		preposition = "of",
		-- If 'region' isn't a specific administrative division, fall back to 'geographic and cultural area'
		fallback = "geographic and cultural area",
		-- "former region" is a subpolity but traditional/historic(al)/ancient/medieval/etc. is a geographic region
		former_type = "geographic region",
	},
	["regional capital"] = "capital city",
	["regional county municipality"] = {
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = {"municipality", "county"},
		fallback = "municipality",
	},
	["regional district"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "district",
		fallback = "district",
	},
	["regional municipality"] = "municipality",
	["regional municipality"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "municipality",
		fallback = "municipality",
	},
	["regional unit"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["republic"] = {
		-- Of Russia. "Republics" in general are sovereign but we use "country" in that case.
		preposition = "of",
		former_type = "subpolity",
	},
	["reservoir"] = "lake",
	["resort city"] = "city",
	["resort town"] = "town",
	["river"] = {
		holonym_use_the = true,
		former_type = "natural feature",
		cat_handler = city_type_cat_handler,
		["continent/*"] = {true},
		default = {true},
	},
	["Roman province"] = {
		-- FIXME! Eliminate this in favor of 'former province|emp/Roman Empire'
		default = {"Provinces of the Roman Empire"},
		former_type = "subpolity",
	},
	["royal borough"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"royal", "borough"},
		fallback = "local government district with borough status",
		has_neighborhoods = true,
	},
	["royal burgh"] = "borough",
	["royal capital"] = "capital city",
	["rural committee"] = {
		-- Hong Kong; something like a village
		affix_type = "Suf",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["rural municipality"] = {
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "municipality",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["satrapy"] = {
		preposition = "of",
		former_type = "subpolity",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["sea"] = {
		holonym_use_the = true,
		former_type = "natural feature",
		default = {true},
	},
	["seat"] = "administrative centre",
	["separatist state"] = "unrecognized country",
	["settlement"] = "village", -- not necessarily true, but usually is the case
	["sheading"] = "district",
	["shire"] = "county",
	["shire county"] = "county",
	["shire town"] = "county seat",
	["ski resort city"] = "city",
	["ski resort town"] = "town",
	["spa city"] = "city",
	["spa town"] = "town",
	["special administrative region"] = {
		-- In China; in practice they are city-like (Hong Kong, Shenzhen)
		preposition = "of",
		former_type = "settlement",
		has_neighborhoods = true, --?
	},
	["special municipality"] = "municipality",
	["special ward"] = "municipality", -- of Tokyo
	["spit"] = "peninsula",
	["spring"] = {
		former_type = "natural feature",
		default = {true},
	},
	["star"] = {
		former_type = "natural feature",
		default = {true},
	},
	["state"] = {
		preposition = "of",
		-- 'former/historical state' could refer either to a state of a country (a subdivision) or a state = sovereign
		-- entity. The latter appears more common (e.g. in various "ancient states" of East Asia).
		former_type = "polity",
	},
	["state capital"] = "capital city",
	["state park"] = "park",
	["state-level new area"] = {
		-- China (type of economic development zone, varying greatly in size)
		preposition = "in",
		former_type = "subpolity", --?
	},
	["statutory city"] = "city",
	["statutory town"] = "town",
	["strait"] = {
		former_type = "natural feature",
		default = {true},
	},
	["stream"] = "river",
	["strip"] = "region",
	["strip of land"] = "region",
	["sub-prefectural city"] = "subprovincial city",
	["subdistrict"] = {
		preposition = "of",
		has_neighborhoods = true, --?
		-- FIXME: subdistricts can be neighborhood-like (of Jakarta) or larger (in China); need a handler
		former_type = "subpolity",
		--FIXME: doesn't work; need customizable poldivs of cities (here, subdistricts of Jakarta)
		--["country/Indonesia"] = {
		--	["municipality"] = {true},
		--},
		default = {true},
	},
	["subdivision"] = {
		preposition = "of",
		affix_type = "suf",
		-- FIXME: subdivisions can be neighborhood-like or larger; need a handler
		former_type = "subpolity",
		cat_handler = district_neighborhood_cat_handler,
	},
	["submerged ghost town"] = "ghost town",
	["subnational kingdom"] = "non-sovereign kingdom",
	["subnational monarchy"] = "non-sovereign kingdom",
	["subprefecture"] = {
		affix_type = "suf",
		preposition = "of",
		former_type = "subpolity",
	},
	["subprovince"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["subprovincial city"] = {
		-- China; special status given to certain prefecture-level cities
		fallback = "prefecture-level city",
	},
	["subprovincial district"] = {
		-- China; special status given to Binhai New Area and Pudong New Area, which are county-level districts
		preposition = "of",
		former_type = "subpolity",
	},
	["subregion"] = "region",
	["suburb"] = {
		preposition = "of",
		has_neighborhoods = true, --?
		former_type = "settlement", --?
		cat_handler = district_neighborhood_cat_handler,
		--cat_handler = function(data)
		--	return city_type_cat_handler(data, "allow if holonym is city", "no containing polity")
		--end,
	},
	["suburban area"] = "suburb",
	["subway station"] = "metro station",
	["supercontinent"] = "continent",
	["tehsil"] = {
		affix_type = "suf",
		no_affix_strings = {"tehsil", "tahsil"},
		former_type = "subpolity",
	},
	["territorial authority"] = "district",
	["territory"] = {
		preposition = "of",
		former_type = "subpolity",
	},
	["town"] = {
		has_neighborhoods = true,
		former_type = "settlement",
		cat_handler = city_type_cat_handler,
		["country/*"] = {true},
		default = {true},
	},
	["town with bystatus"] = "town",
	["township"] = {
		has_neighborhoods = true,
		former_type = "settlement", --?
		default = {true},
	},
	["township municipality"] = {
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["traditional county"] = "county",
	["treaty port"] = {
		fallback = "city",
		former_type = "settlement",
		inherently_former = {"FORMER"},
	},
	["tributary"] = {
		preposition = "of",
		fallback = "river",
	},
	["underground station"] = "metro station",
	["unincorporated community"] = {
		former_type = "settlement",
	},
	["unincorporated territory"] = "territory",
	["union territory"] = {
		preposition = "of",
		entry_placetype_indefinite_article = "a",
		former_type = "subpolity",
	},
	["unitary authority"] = {
		entry_placetype_indefinite_article = "a",
		fallback = "local government district",
	},
	["unitary district"] = {
		entry_placetype_indefinite_article = "a",
		fallback = "local government district",
	},
	["united township municipality"] = {
		entry_placetype_indefinite_article = "a",
		fallback = "township municipality",
		has_neighborhoods = true, --?
	},
	["university"] = {
		entry_placetype_indefinite_article = "a",
		former_type = "man-made structure",
		default = {true},
	},
	["unrecognised country"] = "unrecognized country",
	["unrecognized country"] = {
		former_type = "polity",
		default = {"Unrecognized and nearly unrecognized countries"},
	},
	["urban area"] = "neighborhood",
	["urban township"] = "township",
	["urban-type settlement"] = "town",
	["valley"] = {
		former_type = "natural feature",
		default = {true},
	},
	["village"] = {
		former_type = "settlement",
		cat_handler = city_type_cat_handler,
		["country/*"] = {true},
		default = {true},
	},
	["village municipality"] = {
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["voivodeship"] = {
		preposition = "of",
		holonym_use_the = true,
		former_type = "subpolity",
	},
	["volcano"] = {
		plural = "volcanoes",
		former_type = "natural feature",
		default = {true, "Mountains"},
	},
	["ward"] = "neighborhood", -- not completely correct, wards are formal administrative divisions of a city
	["Welsh community"] = {
		preposition = "of",
		affix_type = "suf",
		affix = "community",
		has_neighborhoods = true,
		former_type = "settlement",
	},
	["zone"] = {
		-- Ethiopia, Qatar
		preposition = "of",
		former_type = "subpolity",
	},
}


-- Finalize the placetype_data structure by converting values that are simple strings into fallback structures.
for placetype, value in pairs(export.placetype_data) do
	if type(value) == "string" then
		export.placetype_data[placetype] = {
			fallback = value
		}
	end
end

-- Now augment the category data with political subdivisions extracted from the shared data.
for _, group in ipairs(m_shared.polities) do
	for key, value in pairs(group.data) do
		value = group.value_transformer(group, key, value)
		local divlists = {}
		if value.poldiv then
			insert(divlists, value.poldiv)
		end
		if value.miscdiv then
			insert(divlists, value.miscdiv)
		end
		local divtype = value.divtype or group.default_divtype
		if type(divtype) ~= "table" then
			divtype = {divtype}
		end
		for _, divlist in ipairs(divlists) do
			if type(divlist) ~= "table" then
				divlist = {divlist}
			end
			for _, div in ipairs(divlist) do
				if type(div) == "string" then
					div = {type = div}
				end
				local sgdiv = div.sgdiv or require(en_utilities_module).singularize(div.type)
				local prep = div.prep or "of"
				local cat_as = div.cat_as or div.type
				if type(cat_as) ~= "table" then
					cat_as = {cat_as}
				end
				for _, dt in ipairs(divtype) do
					if not export.placetype_data[sgdiv] then
						export.placetype_data[sgdiv] = {
							preposition = prep,
						}
					end
					-- If there is a difference between full and elliptical placenames, make sure we recognize both
					-- forms in holonyms.
					local full_placename, elliptical_placename = m_shared.call_key_to_placename(group, key)
					local bare_full_placename, _ = m_shared.construct_bare_and_linked_version(full_placename)
					local bare_elliptical_placename, _ = m_shared.construct_bare_and_linked_version(
						elliptical_placename)
					local placenames = bare_full_placename == bare_elliptical_placename and {bare_full_placename} or
						{bare_full_placename, bare_elliptical_placename}
					for _, placename in ipairs(placenames) do
						local cat_specs = {}
						for _, pt_cat in ipairs(cat_as) do
							if type(pt_cat) == "string" then
								pt_cat = {type = pt_cat}
							end
							local pt_prep = pt_cat.prep or prep
							if placename == key and require(en_utilities_module).pluralize(sgdiv) == pt_cat.type then
								insert(cat_specs, true)
							else
								insert(cat_specs, ucfirst(pt_cat.type) .. " " .. pt_prep .. " " .. key)
							end
						end
						local cat_data_holonym = dt .. "/" .. placename
						if export.placetype_data[sgdiv][cat_data_holonym] then
							-- Make sure there isn't an existing setting in `placetype_data` for this placetype and
							-- holonym, which we would be overwriting. This clash occurs because there's a political or
							-- misc division listed in `countries` or one of the other entries in `polities` in
							-- [[Module:place/shared-data]], and we are trying to add categorization for toponyms that
							-- are located in that political or misc division in that country/etc., but there's already
							-- an entry in `placetype_data`. If this occurs, we throw an error rather than overwrite the
							-- existing entry or do nothing (either of which options may be wrong). Sometimes the
							-- existing entry is intentional as it does something special like rename the category, e.g.
							-- 'Counties and regions of England' instead of just 'Counties of England'); in that case
							-- set `no_error_on_poldiv_clash = true` in the entry in `placetype_data`; see existing
							-- examples.
							if not export.placetype_data[sgdiv][cat_data_holonym].no_error_on_poldiv_clash then
								internal_error("Would overwrite placetype_data[%s][%s] with %s; if this is " ..
									"intentional, set `no_error_on_poldiv_clash = true` (see comment in " ..
									"[[Module:place/data]])", sgdiv, cat_data_holonym, cat_specs)
							end
						else
							export.placetype_data[sgdiv][cat_data_holonym] = cat_specs
						end
					end
				end
			end
		end
	end
end

return export
