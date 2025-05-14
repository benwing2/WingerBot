local export = {}

export.force_cat = false -- set to true for testing

local m_locations = require("Module:place/locations")
local m_links = require("Module:links")
local m_table = require("Module:table")
local m_strutils = require("Module:string utilities")
local debug_track_module = "Module:debug/track"
local en_utilities_module = "Module:en-utilities"

local dump = mw.dumpObject
local insert = table.insert
local concat = table.concat
local internal_error = m_locations.internal_error
export.internal_error = internal_error
local process_error = m_locations.process_error
export.process_error = process_error
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local ucfirst = m_strutils.ucfirst
local ulower = m_strutils.lower
local rmatch = m_strutils.match
local split = m_strutils.split

--[==[ intro:
This module contains placetype data used by [[Module:place]] and {{tl|place}}, along with a significant amount of code
to work with both placetypes and locations, as well as some placename-related info (FIXME: Consider moving it to
[[Module:place/locations]]). See also [[Module:place/locations]], which has definitions of all known locations. You must
currently load this module using {{cd|require()}}, not using {{cd|mw.loadData()}}.
]==]

------------------------------------------------------------------------------------------
--                                     Basic utilities                                  --
------------------------------------------------------------------------------------------


--[==[
Return true if `force_cat` is set either in this module or in [[Module:place/locations]].
]==]
function export.get_force_cat()
	return export.force_cat or m_locations.force_cat
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
Return the singular version of a maybe-plural placetype, or nil if not plural. This correctly handles placetypes with
irregular plurals such as `kibbutzim` plural of `kibbutz` by looking up in a table constructed from the `plural` values
specified in `placetype_data`. If a special plural value is not found, the regular singularization algorithm in
[[Module:en-utilities]] is invoked, which reverses the y -> ies change after vowels and the 'es' addition after sh/ch/x,
and otherwise just subtracts a final 's' (which will incorrectly generate 'passe' for plural 'passes'; FIXME: consider
changing this for words ending in '-sses'). If the generated singular is the same as the passed-in value, nil is
returned.
]==]
function export.maybe_singularize_placetype(placetype)
	if not placetype then
		return nil
	end
	if export.plural_placetype_to_singular[placetype] then
		return export.plural_placetype_to_singular[placetype]
	end
	local retval = require(en_utilities_module).singularize(placetype)
	if retval == placetype then
		return nil
	end
	return retval
end


-- Return the correct plural of a placetype, and (if `do_ucfirst` is given) make the first letter uppercase. We first
-- look up the plural in `placetype_data`, falling back to pluralize() in [[Module:en-utilities]], which is almost
-- always correct.
function export.pluralize_placetype(placetype, do_ucfirst)
	local ptdata = export.placetype_data[placetype]
	if ptdata and ptdata.plural then
		placetype = ptdata.plural
	else
		placetype = require(en_utilities_module).pluralize(placetype)
	end
	if do_ucfirst then
		return ucfirst(placetype)
	else
		return placetype
	end
end


--[==[
Get the data associated with a placetype, which may be in its singular or plural form. If `from_category` is specified,
we also look for category-only placetypes (generally plural) followed by `!`. Return three values: (a) the placetype
under which the data can be looked up (i.e. in its singular form if the passed-in `placetype` is plural and did not
match a category-only placetype followed by `!`); (b) the placetype data structure; (c) the type of `placetype` match
that occurred, one of `"direct"` if the canonical placetype is the same as the passed-in `placetype` and also the same
as the key under which `ptdata` was looked up, or `"direct-category"` if the `ptdata` was looked up under a key formed
from the passed-in `placetype` by adding `!`, or `"plural"` if the `ptdata` was looked up under the singularized version
of the plural passed-in `placetype`.
]==]
function export.get_placetype_data(placetype, from_category)
	local ptdata = export.placetype_data[placetype]
	if ptdata then
		return placetype, ptdata, "direct"
	end
	if from_category then
		ptdata = export.placetype_data[placetype .. "!"]
		if ptdata then
			return placetype .. "!", ptdata, "direct-category"
		end
	end
	local sg_placetype = export.maybe_singularize_placetype(placetype)
	if sg_placetype then
		ptdata = export.placetype_data[sg_placetype]
		if ptdata then
			return sg_placetype, ptdata, "plural"
		end
	end
	return nil
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
Return a property from `placetype_data` for a given placetype. If the placetype isn't found in `placetype_data`, or the
key isn't found in the placetype's entry in `placetype_data`, return nil.
]==]
function export.get_placetype_prop(placetype, key)
	if export.placetype_data[placetype] then
		return export.placetype_data[placetype][key]
	else
		return nil
	end
end

--[==[
Given a placetype, split the placetype into one or more potential ''splits'', each consisting of a three-element list
{ {``prev_qualifiers``, ``this_qualifier``, ``reduced_placetype``}}, i.e.
# the concatenation of zero or more previously-recognized qualifiers on the left, normally canonicalized (if there are
  zero such qualifiers, the value will be nil);
# a single recognized qualifier, normally canonicalized (if there is no qualifier, the value will be nil);
# the "reduced placetype" on the right.
Splitting between the qualifier in (2) and the reduced placetype in (3) happens at each space character, proceeding from
left to right, and stops if a qualifier isn't recognized. All placetypes are canonicalized by checking for aliases
in `placetype_aliases`, but no other checks are made as to whether the reduced placetype is recognized. Canonicalization
of qualifiers does not happen if `no_canon_qualifiers` is specified.

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
		local qualifier, reduced_placetype = placetype:match("^(.-) (.*)$")
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
			insert(splits, {prev_qualifier, new_qualifier, export.resolve_placetype_aliases(reduced_placetype)})
			prev_qualifier = prev_qualifier and prev_qualifier .. " " .. new_qualifier or new_qualifier
			placetype = reduced_placetype
		else
			break
		end
	end
	return splits
end

--[==[
Given a `placetype` (which may be pluralized), return an ordered list of equivalent placetypes to look under to find the
placetype's properties (such as the category or categories to be inserted). The return value is actually an ordered list
of objects of the form `{qualifier=``qualifier``, placetype=``equiv_placetype``}` where ``equiv_placetype`` is a
placetype whose properties to look up, derived from the passed-in placetype or from a contiguous subsequence of the
words in the passed-in placetype (always including the rightmost word in the placetype, i.e. we successively chop off
qualifier words from the left and use the remainder to find equivalent placetypes). ``qualifier`` is the remaining words
not part of the subsequence used to find ``equiv_placetype``; or nil if all words in the passed-in placetype were used
to find ``equiv_placetype``. (FIXME: This qualifier is not currently used anywhere.) Only placetypes for which there is
an entry in `placetype_data` are included. The placetype passed in is always checked first, and will form the first
entry if it exists in `placetype_data`.

For example, given the placetype `left tributary`, the following placetype/qualifier combinations are checked in turn:
```
  {qualifier = nil, placetype="left tributary"}
  {qualifier = "left", placetype="tributary"}
  {qualifier = "left", placetype="river"}
```
and the return value will be
{ {
  {qualifier = "left", placetype="tributary"},
  {qualifier = "left", placetype="river"},
}}

The algorithm first enters the placetype itself into the list, then checks for `left tributary` as a recognized
placetype in `placetype_data` and doesn't find it, so it doesn't enter it into the returned list (if it found it, it
would add it as well as any fallbacks directly after it). It then splits off the recognized qualifier `left` to form the
''reduced placetype'' `tributary`, which is entered into the list because it is found in `placetype_data`. Then, because
it has a fallback `river`, which exists in `placetype_data`, the fallback is entered next.

Another example is `small rural fraziones` (where a ''frazione'' is type of subdivision of a ''comune'' or municipality,
often specifically an outlying hamlet). the placetype/qualifier combinations checked are:
```
  {qualifier = nil, placetype="small rural fraziones"}
  {qualifier = nil, placetype="small rural frazione"}
  {qualifier = "small", placetype="rural fraziones"}
  {qualifier = "small", placetype="rural frazione"}
  {qualifier = "small [[rural]]", placetype="fraziones"}
  {qualifier = "small [[rural]]", placetype="frazione"}
  {qualifier = "small [[rural]]", placetype="hamlet"}
  {qualifier = "small [[rural]]", placetype="village"}
```
The return value ends up as
  {qualifier = "small [[rural]]", placetype="frazione"},
  {qualifier = "small [[rural]]", placetype="hamlet"},
  {qualifier = "small [[rural]]", placetype="village"},
}}

Here, because the result of singularizing `fraziones` returns a different value from the placetype itself, that
singularized value is checked after the original plural value. Also, in the process of splitting off qualifiers,
they are canonicalized if the entry in `placetype_qualifiers` says to do so; in this case, links are placed around
`rural`. Finally, `frazione` has `hamlet` as its fallback, which in turn has `village` as its fallback, so both
fallbacks end up being returned.

`no_fallback`, if set, disables returning equivalent placetypes based on the `fallback` setting for a placetype. This is
used in the first of two loops in find_placetype_cat_specs() in [[Module:place]] to prefer exact matches for placetypes
such as barangays with later holonyms to matches based on a fallback such as `neighborhood` with an earlier holonym.
See the comment in that function in [[Module:place]] for a more detailed explanation of why this is needed. Only the
placetype itself, and any reduced placetypes created by chopping off recognized qualifiers at the beginning, are
returned; but we do not return reduced placetypes if a containing placetype exists in `placetype_data`. (For example,
`"overseas territory"` has a fallback `"dependent territory"`, and `"overseas"` is also a recognized qualifier. When
`no_fallback` is in place, without the above proviso, we would return `"overseas territory"` followed by `"territory"`
with the incorrect effect of classifying an `"overseas territory"` of the United Kingdom such as `"Gibraltar"` under
[[:Category:Territories of the United Kingdom]] instead of [[:Category:Dependent territories of the United Kingdom]].)
As an exception, if `historical`, `ancient`, `former` or the like are found, they proceed ignoring `no_fallback`,
because it seems tricky to handle them correctly in the presence of `no_fallback`, and historical/former placetypes
rarely occur with exact match category specs anyway.

`no_split_qualifiers` prevents splitting off recognized qualifiers and returning the remainder of the placetype as an
equivalent placetype. Only the passed-in placetype, and any fallbacks, will be returned. This is used in
[[Module:category tree/topic cat/data/Places]] when looking up placetypes found in categories. Such placetypes won't
have qualifiers and so it doesn't make sense to try and look for them.

`from_category`, if set, causes category-only placetypes (those ending in `!`) to also be checked.

`no_check_for_inherently_former` is used internally to prevent an infinite loop when checking for `inherently_former`.

`register_former_as_non_former` is a major hack used in `get_bare_categories` to deal with the mismatch between e.g.
known location `Yugoslavia` declaring itself a `country` but definitions of it declaring it a `former country`. It
causes the non-former version of the specified placetype to be included in the returned equivalents along with the
former placetypes. FIXME: This should apply only to the entries in `former_countries` but it's tricky to do that now;
fix this in the known-location refactor.
]==]
function export.get_placetype_equivs(placetype, props)
	local no_fallback, no_split_qualifiers, no_check_for_inherently_former, from_category, register_former_as_non_former
	if props then
		no_fallback, no_split_qualifiers, no_check_for_inherently_former, from_category, register_former_as_non_former =
			props.no_fallback, props.no_split_qualifiers, props.no_check_for_inherently_former, props.from_category,
			props.register_former_as_non_former
	end
	local equivs = {}

	-- Insert `placetype` into `equivs`, along with any fallback placetypes listed in `placetype_data`. `qualifier`
	-- is the preceding qualifier to insert into `equivs` along with the placetype (see comment at top of function). If
	-- `from_category` is given, we also check for a category-specific entry consisting of the placetype followed by
	-- `!`, and in all cases we also check to see if `placetype` is plural, and if so, insert the singularized version
	-- along with its fallbacks (if any) in `placetype_data`.
	local function do_placetype(qualifier, placetype)
		local function insert_equiv(pt)
			insert(equivs, {qualifier=qualifier, placetype=pt})
		end

		-- Insert the placetype, along with any fallbacks.
		local canon_placetype, ptdata, ptmatch = export.get_placetype_data(placetype, from_category)
		if ptdata then
			insert_equiv(canon_placetype)
			if no_fallback then
				return
			end
			local first_placetype = #equivs + 1
			local prev_placetype = nil
			while true do
				local pt_value = export.placetype_data[canon_placetype]
				if not pt_value then
					internal_error("Fallback value %s specified for placetype %s but is not in `placetype_data`",
						canon_placetype, prev_placetype)
				end
				if pt_value.fallback then
					insert_equiv(pt_value.fallback)
					local last_placetype = #equivs
					if last_placetype - first_placetype >= 10 then
						local fallback_loop = {}
						for i = first_placetype, last_placetype do
							insert(fallback_loop, equivs[i].placetype)
						end
						internal_error("Apparent loop in fallback chain: %s", table.concat(fallback_loop, " -> "))
					end
					prev_placetype = canon_placetype
					canon_placetype = pt_value.fallback
				else
					break
				end
			end
		end
	end

	-- Successively split off recognized qualifiers and loop over successively greater sets of qualifiers from the left
	-- (unless `no_split_qualifiers` is specified, in which case we don't check for qualifiers).
	local splits
	if no_split_qualifiers then
		splits = {{nil, nil, export.resolve_placetype_aliases(placetype)}}
	else
		splits = export.split_qualifiers_from_placetype(placetype)
	end

	for _, split in ipairs(splits) do
		local prev_qualifier, this_qualifier, reduced_placetype = unpack(split, 1, 3)
		-- If a special "former" qualifier like `former` or `historical` isn't present, and
		-- `no_check_for_inherently_former` is not given (this flag is used to avoid infinite loops), check for
		-- "inherently former" placetypes like `satrapy` and `treaty port` that always refer to no-longer-existing
		-- placetypes, and handle accordingly.
		local former_qualifiers = this_qualifier and export.former_qualifiers[this_qualifier] or nil
		if not former_qualifiers and not no_check_for_inherently_former then
			former_qualifiers = export.get_equiv_placetype_prop(reduced_placetype,
				function(pt) return export.get_placetype_prop(pt, "inherently_former") end,
				{no_check_for_inherently_former = true})
		end

		-- If a special "former" qualifier like `former` or `historical` is present, map it to the appropriate internal
		-- qualifiers (`ANCIENT` and/or `FORMER`, which are written in all-caps to distinguish them from user-specified
		-- qualifiers), fetch the `former_type` property, and treat the placetype as if a concatenation of the mapped
		-- qualifier(s) and the value of `former_type`. For example, if `medieval village` is given, we map `medieval`
		-- to `ANCIENT` and `FORMER`, and `village` to its `former_type` of `settlement`, and enter the placetypes
		-- `ANCIENT settlement` and `FORMER settlement` (in that order) into `equivs`. If the placetype following the
		-- "former" qualifier is recognized in `placetype_data` but has no `former_type` and no fallback with a
		-- `former_type` specified, it is an internal error; but if the placetype isn't recognized (e.g. something like
		-- `former greenhouse` is specified and we don't have an entry for `greenhouse`), just track the occurrence and
		-- don't enter anything into `equivs`.
		if former_qualifiers then
			-- FIXME: Should we respect `no_fallback` here? My instinct says no.
			local reduced_placetype_equivs = export.get_placetype_equivs(reduced_placetype, {
				no_check_for_inherently_former = true
			})
			local former_type = export.get_equiv_placetype_prop_from_equivs(reduced_placetype_equivs,
				function(pt) return export.get_placetype_prop(pt, "former_type") or
					export.get_placetype_prop(pt, "class") end
			)
			if not former_type then
				local pt_data = export.get_equiv_placetype_prop_from_equivs(reduced_placetype_equivs,
					function(pt) return export.placetype_data[pt] end
				)
				if pt_data then
					internal_error("For placetype '%s', placetype data located but `former_type` missing; " ..
						"placetypes searched are %s", reduced_placetype, reduced_placetype_equivs)
				else
					-- Enable error when we've verified there aren't any examples.
					track("bad-former-placetype")
					track("bad-former-placetype/" .. reduced_placetype)
					--process_error("For placetype '%s', unrecognized placetype following 'former'-type qualifier; " ..
					--	"searched placetype(s) %s", reduced_placetype, dump(reduced_placetype_equivs))
				end
			elseif former_type ~= "!" then
				-- First check directly for `ANCIENT/FORMER` + the original following placetype. This makes it possible
				-- for (e.g.) former provinces of the Roman empire to be categorized specially.
				for _, former_qualifier in ipairs(former_qualifiers) do
					do_placetype(prev_qualifier, former_qualifier .. " " .. reduced_placetype)
				end
				for _, former_qualifier in ipairs(former_qualifiers) do
					do_placetype(prev_qualifier, former_qualifier .. " " .. former_type)
				end
				-- HACK! See explanation above for `register_former_as_non_former`.
				if register_former_as_non_former then
					do_placetype(prev_qualifier, reduced_placetype)
				end
				break
			end
		end

		-- Then see if the rightmost split-off qualifier is in qualifier_to_placetype_equivs
		-- (e.g. 'fictional *' -> 'fictional location'). If so, add the mapping.
		if this_qualifier and export.qualifier_to_placetype_equivs[this_qualifier] then
			insert(equivs, {qualifier=prev_qualifier, placetype=export.qualifier_to_placetype_equivs[this_qualifier]})
		end

		-- Finally, join the rightmost split-off qualifier to the previously split-off qualifiers to form a combined
		-- qualifier, and add it along with reduced_placetype and any mapping in placetype_data for reduced_placetype.
		-- NOTE: The first time through this loop, both `prev_qualifier` and `this_qualifier` are nil, and this inserts
		-- the full placetype into `equivs`.
		local qualifier = prev_qualifier and prev_qualifier .. " " .. this_qualifier or this_qualifier
		do_placetype(qualifier, reduced_placetype)

		-- If `no_fallback` and there's an entry in `placetype_data` for this placetype, don't include any reduced
		-- placetypes to avoid the "overseas territory treated as a territory" issue describe above.
		if no_fallback then
			local canon_placetype, ptdata, ptmatch = export.get_placetype_data(reduced_placetype, from_category)
			if canon_placetype then
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
function export.get_equiv_placetype_prop(placetype, fun, props)
	if not placetype then
		return fun(nil), nil
	end
	return export.get_equiv_placetype_prop_from_equivs(export.get_placetype_equivs(placetype, props), fun,
		props and props.continue_on_nil_only)
end


--[==[
Return the article that is used with an entry placetype. First we check the placetype or any equivalent placetype for
the `entry_placetype_use_the` property, indicating that `"the"` should be used. Otherwise we look to see if the
placetype itself (not any equivalents, even those involving deleting a qualifier from the beginning) has an entry in
`placetype_data` that specifies the indefinite article using `entry_placetype_use_the` (principally for use with
placetypes like `union territory`). Otherwise, we use [[Module:en-utilities]] to apply the standard algorithm to
generate `"an"` for words beginning with a vowel and `"a"` otherwise. If `ucfirst` is true, the first letter of the
article is made upper-case.
]==]
function export.get_placetype_article(placetype, ucfirst)
	local art

	local placetype_use_the = export.get_equiv_placetype_prop(placetype,
		function(pt) return export.get_placetype_prop(pt, "entry_placetype_use_the") end)
	if placetype_use_the then
		art = "the"
	else
		art = export.get_placetype_prop(placetype, "entry_placetype_indefinite_article")
		if not art then
			art = require(en_utilities_module).get_indefinite_article(placetype)
		end
	end

	if ucfirst then
		art = m_strutils.ucfirst(art)
	end

	return art
end


--[==[
Return the preposition that should be used after `placetype` when occurring as an entry placetype or in categories
(e.g. `city >in< France` but `country >of< South America`). The preposition defaults to `"in"` if not specified.
]==]
function export.get_placetype_entry_preposition(placetype)
	local pt_prep = export.get_equiv_placetype_prop(placetype,
		function(pt) return export.get_placetype_prop(pt, "preposition") end
	)
	return pt_prep or "in"
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

	-- Key in equivalent placetypes, so that e.g. `cities/San Francisco` gets keyed under `city`; but don't do
	-- fallbacks, as it doesn't seem correct for the "do other holonyms of the same placetype" algorithm to do holonyms
	-- of different types just because they have the same fallback.
	local equiv_placetypes = export.get_placetype_equivs(holonym.placetype, {no_fallback = true})
	local unlinked_placename = holonym.unlinked_placename
	for _, equiv in ipairs(equiv_placetypes) do
		local placetype = equiv.placetype
		if not place_desc.holonyms_by_placetype then
			place_desc.holonyms_by_placetype = {}
		end
		if not place_desc.holonyms_by_placetype[placetype] then
			place_desc.holonyms_by_placetype[placetype] = {unlinked_placename}
		else
			insert(place_desc.holonyms_by_placetype[placetype], unlinked_placename)
		end
	end
end

--[=[
Construct a formatted link from the raw link spec `link` given the canonical singular placetype `sg_placetype`. If the
placetype was originally plural, `orig_placetype` should contain this plural value; otherwise it should be nil. This
will construct the appropriate type of link that displays as `orig_placetype` (or otherwise `sg_placetype`) but links to
whatever the `link` spec specifies (which may be `sg_placetype`, a Wikipedia article, etc.).
]=]
local function make_placetype_link(link, sg_placetype, orig_placetype)
	if link == nil then
		internal_error("Placetype data present for placetype %s but no link= setting given", sg_placetype)
	elseif link == true then
		if orig_placetype then
			return ("[[%s|%s]]"):format(sg_placetype, orig_placetype)
		else
			return ("[[%s]]"):format(sg_placetype)
		end
	elseif link == false then
		process_error("Placetype %s is not meant to be specified directly, but is only for internal use", sg_placetype)
	elseif link == "w" then
		return ("[[w:%s|%s]]"):format(sg_placetype, orig_placetype or sg_placetype)
	elseif link == "separately" then
		if orig_placetype then
			local sg_words = split(sg_placetype, " ")
			local orig_words = split(orig_placetype, " ")
			if #sg_words ~= #orig_words then
				internal_error("Can't construct 'separately' link for plural placetype %s as original placetype %s " ..
					"has different number of words", orig_placetype, sg_placetype)
			else
				for i = 1, #sg_words do
					if sg_words[i] == orig_words[i] then
						sg_words[i] = ("[[%s]]"):format(sg_words[i])
					else
						sg_words[i] = ("[[%s|%s]]"):format(sg_words[i], orig_words[i])
					end
				end
				return concat(sg_words, " ")
			end
		else
			return (sg_placetype:gsub("([^ ]+)", "[[%1]]"))
		end
	elseif link:find("^%+") then
		link = link:sub(2) -- discard initial +
		return ("[[%s|%s]]"):format(link, orig_placetype or sg_placetype)
	elseif not orig_placetype then
		return link
	else
		return require(en_utilities_module).pluralize(link)
	end
end

--[==[
Get the display form of a placetype by looking it up in `placetype_data`. If the placetype is recognized, or is the
plural of a recognized placetype, the corresponding linked display form is returned (with plural placetypes displaying
as plural but linked to the singular form of the placetype). Otherwise, return nil. If we're generating the description
of a category, `category_type` should be set to one of `"top-level"` (for top-level categories like
[[:Category:Neighborhoods]]), `"noncity"` (for non-city categories like [[:Category:Neighhorhoods in Illinois, USA]]) or
`"city"` (for city categories like [[:Category:Neighbhorhoods of Chicago]]). Otherwise, we're generating the description
for use in formatting a {{tl|place}} call, and category-only placetypes ending in `!` will be ignored, along with
special `category_link*` settings.
]==]
function export.get_placetype_display_form(placetype, category_type)
	local canon_placetype, ptdata, ptmatch = export.get_placetype_data(placetype, not not category_type)
	if canon_placetype then
		local raw_link
		if category_type then
			-- Careful with `false` as possible value.
			if category_type == "top-level" then
				raw_link = ptdata.category_link_top_level
			elseif category_type == "noncity" then
				raw_link = ptdata.category_link_before_noncity
			elseif category_type == "city" then
				raw_link = ptdata.category_link_before_city
			end
			if raw_link ~= nil then
				return raw_link, ptdata
			end
			raw_link = ptdata.category_link
			if raw_link == false then
				return raw_link, ptdata
			end
			if type(raw_link) == "string" and raw_link:find("%[%[") then
				return raw_link, ptdata
			end
		end
		if ptmatch == "plural" then
			local raw_link = ptdata.plural_link
			if raw_link == false then
				process_error("Placetype %s cannot appear plural", placetype)
			end
			if type(raw_link) == "string" and raw_link:find("%[%[") then
				return raw_link, ptdata
			end
		end
		if raw_link == nil then
			raw_link = ptdata.link
		end
		return make_placetype_link(raw_link, canon_placetype, placetype ~= canon_placetype and placetype or nil), ptdata
	end

	return nil
end


local function resolve_unlinked_placename_display_aliases(placetype, placename)
	local equiv_placetypes = export.get_placetype_equivs(placetype)
	for i, equiv in ipairs(equiv_placetypes) do
		equiv_placetypes[i] = equiv.placetype
	end
	local all_display_aliases_found = {}
	local all_others_found = {}
	for group, key, spec in m_locations.iterate_matching_location {
		placetypes = equiv_placetypes,
		placename = placename,
		alias_resolution = "display",
	} do
		if spec.alias_of and spec.display then
			insert(all_display_aliases_found, {group, key, spec, spec.display_as_full})
		else
			insert(all_others_found, {group, key, spec})
		end
	end
	if not all_display_aliases_found[1] then
		return placename
	elseif all_display_aliases_found[2] then
		internal_error("Found multiple matching display aliases for placename %s, placetype %s: " ..
			"all_display_aliases_found=%s, all_others_found=%s", placename, placetype, all_display_aliases_found,
			all_others_found)
	elseif all_others_found[1] then
		internal_error("Found a display alias along with other possible meanings for placename %s, placetype %s: " ..
			"all_display_aliases_found=%s, all_others_found=%s", placename, placetype, all_display_aliases_found,
			all_others_found)
	else
		local group, key, spec, as_full = unpack(all_display_aliases_found[1])
		local full, elliptical = m_locations.key_to_placename(group, key)
		return as_full and full or elliptical
	end
end

--[==[
If `placename` of type `placetype` is a display alias, convert it to its canonical form; otherwise, return unchanged.
Display aliases transform certain placenames into canonical displayed forms. For example, if any of `country/US`,
`country/USA` or `country/United States of America` (or `c/US`, etc.) are given, the result will be displayed as
`United States`.

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
function export.resolve_placename_display_aliases(placetype, placename)
	-- If the placename is a link, apply the alias inside the link.
	-- This pattern matches both piped and unpiped links. If the link is not piped, the second capture (linktext) will
	-- be empty.
	local link, linktext = rmatch(placename, "^%[%[([^|%]]+)|?(.-)%]%]$")
	if link then
		if linktext ~= "" then
			local alias = resolve_unlinked_placename_display_aliases(placetype, linktext)
			return "[[" .. link .. "|" .. alias .. "]]"
		else
			local alias = resolve_unlinked_placename_display_aliases(placetype, link)
			return "[[" .. alias .. "]]"
		end
	else
		return resolve_unlinked_placename_display_aliases(placetype, placename)
	end
end

--[==[
Generate the "prefixed" version of a bare key, i.e. prefix it with `the` if correct for this key.
]==]
function export.get_prefixed_key(key, spec)
	if spec.the then
		return "the " .. key
	else
		return key
	end
end

-- Necessary for use by [[Module:place]]. FIXME: Reorganize the modules so this isn't necessary.
export.iterate_matching_location = m_locations.iterate_matching_location

--[=[
Iterator that iterates over holonyms in `place_desc`. If `first_holonym_index` is given, start iterating at the
specified holonym and stop either when there are no more holonyms or a holonym with modifier `:also` is found. If
`first_holonym_index` is nil or omitted, iterate over all holonyms regardless. If `include_raw_text_holonyms` is
specified, raw text holonyms (those not of the form `placetype/placename`) are returned as well; they can be identified
by the fact that the `placetype` field in the holonym structure is nil. Two values are returned at each iteration, the
holonym index and holonym structure, similar to `ipairs()`.
]=]
function export.get_holonyms_to_check(place_desc, first_holonym_index, include_raw_text_holonyms)
	local stop_at_also = not not first_holonym_index
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
	end, place_desc, first_holonym_index and first_holonym_index - 1 or 0
end

--[==[
If the holonym in `data` (in the format as passed to a category handler) refers to a known location, iterate over all
such known locations, returning for each location the corresponding key, spec and group as well as the trail of
ancestral containers. Unlike `iterate_matching_location()`, this specifically checks that there is no mismatch between
the location's containers at any level and any of the following holonyms in the {{tl|place}} spec. The fields in `data`
are:
* `holonym_placetype`: The placetype of the holonym. It can actually be a list of possible placetypes, as with
  `iterate_matching_location()`.
* `holonym_placename`: The placename of the holonym.
* `holonym_index`: The index of the holonym among the holonyms in `place_desc`, or nil if the holonym is not among the
  holonyms in `place_desc`. (If a holonym index is given, we check for container mismatches among the holonyms
  following the specified index, stopping either when encountering a holonym marked with modifier `:also` or, if none
  exist, when we run out of holonyms. If no holonym index is given, we check all holonyms for container mismatches.)
* `place_desc`: Description of the place; used for the holonyms, to check for container mismatches.

Returns four values: the location group, the canonical key by which the location is known, the spec object describing
the location and the trail of ancestral containers for the location. The first three values are the same as for
`iterate_matching_location`.
]==]
function export.iterate_matching_holonym_location(data)
	local holonym_placetype, holonym_placename, holonym_index, place_desc =
		data.holonym_placetype, data.holonym_placename, data.holonym_index, data.place_desc
	local matching_location_iterator = m_locations.iterate_matching_location {
		placetypes = holonym_placetype,
		placename = holonym_placename,
	}
	return function()
		while true do
			local group, key, spec = matching_location_iterator()
			if not group then
				return nil
			end
			local container_trail = {}
			-- For each level of container, check that there are no mismatches (i.e. other location of the same
			-- placetype) mentioned. We allow a mismatch at a given level if there's also a match with the container
			-- at that level. For example, in the case of Kansas City, defined in [[Module:place/locations]] as a city
			-- in Missouri, if we define it as {{tl|place|city|s/Missouri,Kansas}}, we ignore the mismatching state of
			-- Kansas because the correct state of Missouri was also mentioned. But imagine we are defining Newark,
			-- Delaware as {{tl|place|city|s/Delaware|c/US}} and (as is the case) we have an entry for Newark, New
			-- Jersey in [[Module:place/locations]]. Just because the containing location `US` matches isn't enough,
			-- because Newark, NJ also has New Jersey as a containing location and there's a mismatch at that level. If
			-- there are no mismatches at any level we assume we're dealing with the right known location.
			--
			-- If at a given level there are multiple containing locations, we count a match if any holonym matches any
			-- containing location, and a mismatch only if a holonym exists of the same placetype that doesn't match any
			-- containing location.
			local containers_mismatch = false
			for containers in m_locations.iterate_containers(group, key, spec) do
				insert(container_trail, containers)
				local match_at_level = false
				local mismatch_at_level = false
				for other_holonym_index, other_holonym in export.get_holonyms_to_check(place_desc,
					holonym_index and holonym_index + 1 or nil) do
					local other_source_holonym = other_holonym.augmented_from_holonym
					if other_source_holonym and other_source_holonym.placetype == holonym_placetype and
						other_source_holonym.unlinked_placename ~= holonym_placename then
							-- Ignore holonyms added during the augmentation process for other holonyms of the same
							-- placetype as the placetype of the holonym we're considering. See comment in
							-- augment_holonyms_with_container() for why we do this.
							-- continue; grrr, no 'continue' in Lua
					else
						local holonym_matches_at_level = false
						local holonym_exists_with_same_placetype = false
						for _, container in ipairs(containers) do
							if not container.spec.no_check_holonym_mismatch then
								local full_container_placename, elliptical_container_placename =
									m_locations.key_to_placename(container.group, container.key)
								local placetypes = container.spec.placetype
								if type(placetypes) ~= "table" then
									placetypes = {placetypes}
								end
								local placetype_equivs = {}
								for _, pt in ipairs(placetypes) do
									m_table.extend(placetype_equivs, export.get_placetype_equivs(pt))
								end
								local this_holonym_matches = export.get_equiv_placetype_prop_from_equivs(
									placetype_equivs, function(placetype)
										return other_holonym.placetype == placetype and
											(other_holonym.unlinked_placename == full_container_placename or
											other_holonym.unlinked_placename == elliptical_container_placename)
									end
								)
								if this_holonym_matches then
									holonym_matches_at_level = true
									break
								end
								local this_holonym_exists_with_same_placetype = export.get_equiv_placetype_prop_from_equivs(
									placetype_equivs, function(placetype)
										return other_holonym.placetype == placetype
									end
								)
								if this_holonym_exists_with_same_placetype then
									-- We seem to have a mismatch at this level. But before we decide conclusively that this
									-- is the case, check to see whether the putative mismatch is an alias and matches when
									-- we resolve the alias.
									for oh_group, oh_key, oh_spec, oh_container_trail in 
										export.iterate_matching_holonym_location {
											holonym_placetype = other_holonym.placetype,
											holonym_placename = other_holonym.unlinked_placename,
											holonym_index = other_holonym_index,
											place_desc = place_desc,
										} do
										local oh_full_placename, oh_elliptical_placename =
											m_locations.key_to_placename(oh_group, oh_key)
										if oh_full_placename == full_container_placename or
											oh_elliptical_placename == elliptical_container_placename then
											-- Alias matched when resolved.
											this_holonym_matches = true
											break
										end
									end
									if this_holonym_matches then
										-- Alias matched above when resolved.
										holonym_matches_at_level = true
										break
									else
										-- Not an alias, or doesn't match when resolved. We have a true mismatch.
										holonym_exists_with_same_placetype = true
									end
								end
							end
						end
						if holonym_matches_at_level then
							match_at_level = true
							break
						end
						if holonym_exists_with_same_placetype then
							mismatch_at_level = true
						end
					end
				end
				if not match_at_level and mismatch_at_level then
					containers_mismatch = true
					break
				end
			end
			if not containers_mismatch then
				return group, key, spec, container_trail
			end
		end
	end
end

--[==[
If the holonym in `data` (in the format as passed to a category handler) refers to a known location, find and return the
corresponding key, spec and group as well as the trail of ancestral containers. This is like
`iterate_matching_holonym_location()` but throws an error if more than one location matches. (An example where this
would happen is {{tl|place|en|neighborhood|city/Newcastle}}, because there are two known locations named Newcastle. To
fix this, specify additional following disambiguating holonyms, e.g.
{{tl|place|en|neighborhood|city/Newcastle|s/New South Wales}}.
]==]
function export.find_matching_holonym_location(data)
	local all_found = {}
	for group, key, spec, container_trail in export.iterate_matching_holonym_location(data) do
		insert(all_found, {group, key, spec, container_trail})
	end
	if not all_found[1] then
		return nil
	elseif all_found[2] then
		local holonym_placetype = data.holonym_placetype
		if type(holonym_placetype) == "table" then
			holonym_placetype = concat(holonym_placetype, ",")
		end
		local found_keys = {}
		for _, found in ipairs(all_found) do
			local _, key, _, _ = unpack(found)
			insert(found_keys, key)
		end
		error(("Found multiple matching locations for holonym '%s/%s'; specify disambiguating context in the " ..
			"containing holonyms: %s"):format(holonym_placetype, data.holonym_placename, dump(found_keys)))
	else
		return unpack(all_found[1])
	end
end


------------------------------------------------------------------------------------------
--                              Placename and placetype data                            --
------------------------------------------------------------------------------------------


--[==[ var:
This is a map from aliases to their canonical forms. Any placetypes appearing as keys here will be mapped to their
canonical forms in all respects, including the display form. Contrast entries in 'placetype_data' with a fallback, which
applies to categorization and other processes but not to display.

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
	["atu"] = "autonomous territorial unit",
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
	["department capital"] = "departmental capital",
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
	["metmun"] = "metropolitan municipality",
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
These qualifiers can be prepended onto any placetype and will be handled correctly. For example, the placetype
`large city` will be displayed as `large <nowiki>[[city]]</nowiki>` and categorized as if `city` were specified. If the
value in the following table is a string, the qualifier will display according to the string. If the value is `true`,
the qualifier will be linked to its corresponding Wiktionary entry. If the value is `false`, the qualifier will not be
linked but will appear as-is. Note that these qualifiers do not override placetypes with entries elsewhere that contain
those same qualifiers. For example, the entry for `inland sea` in `placetype_data` will apply in preference to treating
`inland sea` as equivalent to `sea`.
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
	["inland"] = true, -- note, we also have an entry in placetype_data for 'inland sea' to get a link to [[inland sea]]
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
In this table, the key qualifiers should be treated the same as the value qualifiers for categorization purposes. This
is overridden by `placetype_data` and `qualifier_to_placetype_equivs`.
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
In this table, any placetypes containing these qualifiers that do not occur in `placetype_data` should be mapped to the
specified placetypes for categorization purposes. Entries here are overridden by `placetype_data`.
]==]
export.qualifier_to_placetype_equivs = {
	["fictional"] = "fictional location",
	["mythical"] = "mythological location",
	["mythological"] = "mythological location",
	-- For e.g. Taiwan as a "claimed province" of China; parts of Belize as claimed by Guatemala; various islands
	-- claimed by various parties in East Asia. FIXME: We should conditionalize on what is being claimed since there are
	-- also claimed capitals, e.g. Israel and Palestine claim Jerusalem as their capital.
	["claimed"] = "claimed political division",
}

--[==[ var:
Mapping from placetypes to the corresponding plural category-only placetype for a capital of that placetype. The reverse
mapping also exists.
]==]
export.placetype_to_capital_cat = {
	["autonomous community"] = "autonomous community capitals",
	["canton"] = "cantonal capitals",
	["country"] = "national capitals",
	["department"] = "departmental capitals",
	["district"] = "district capitals",
	["division"] = "division capitals",
	["emirate"] = "emirate capitals",
	["prefecture"] = "prefectural capitals",
	["province"] = "provincial capitals",
	["region"] = "regional capitals",
	["republic"] = "republic capitals",
	["state"] = "state capitals",
	["territory"] = "territorial capitals",
	["voivodeship"] = "voivodeship capitals",
}

--[==[ var:
This contains placenames that should be preceded by an article (almost always "the"). '''NOTE''': There are multiple
ways that placenames can come to be preceded by "the":
# Listed here.
# Given in [[Module:place/locations]] with an initial "the". All such placenames are added to this map by the code
  just below the map.
# The placetype of the placename has `holonym_use_the = true` in its placetype_data.
# A regex in placename_the_re matches the placename.
Note that "the" is added only before the first holonym in a place description.
]==]
export.placename_article = {
	-- This should only contain info that can't be inferred from [[Module:place/locations]].
	["archipelago"] = {
		["Cyclades"] = "the",
		["Dodecanese"] = "the",
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
		["Northeast Europe"] = {"continent/Europe"},
		["Northeastern Europe"] = {"continent/Europe"},
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


local function city_type_cat_handler(data)
	local entry_placetype = data.entry_placetype
	local generic_before_non_cities = export.get_placetype_prop(entry_placetype, "generic_before_non_cities")
	if not generic_before_non_cities then
		internal_error("city_type_cat_handler called on placetype %s that doesn't have a `generic_before_non_cities`" ..
			" setting", entry_placetype)
	end
	local plural_entry_placetype = export.pluralize_placetype(entry_placetype)
	local group, key, spec, container_trail = export.find_matching_holonym_location(data)
	if group and not spec.is_former_place and not spec.is_city then
		-- Categorize both in key, and in the larger polity that the key is part of, e.g. [[Hirakata]] goes in both
		-- "Cities in Osaka Prefecture" and "Cities in Japan". (But don't do the latter if no_container_cat is set.)
		local cap_plural_entry_placetype = ucfirst(plural_entry_placetype)
		local retcats = {("%s %s %s"):format(cap_plural_entry_placetype, generic_before_non_cities,
			export.get_prefixed_key(key, spec))}
		if container_trail[1] and not spec.no_container_cat then
			for _, container in ipairs(container_trail[1]) do
				insert(retcats, ("%s %s %s"):format(cap_plural_entry_placetype, generic_before_non_cities,
					export.get_prefixed_key(container.key, container.spec)))
			end
		end
		return retcats
	end
end


local function capital_city_cat_handler(data, non_city)
	local holonym_placetype, holonym_placename, holonym_index, place_desc =
		data.holonym_placetype, data.holonym_placename, data.holonym_index, data.place_desc
	-- The first time we're called we want to return something; otherwise we will be called for later-mentioned
	-- holonyms, which can result in wrongly classifying into e.g. `National capitals`. Simulate the loop in
	-- find_placetype_cat_specs() over holonyms so we get the proper `Cities in ...` categories as well as the capital
	-- category/categories we add below.
	local retcats
	if not non_city and place_desc.holonyms then
		for h_index, holonym in export.get_holonyms_to_check(place_desc, holonym_index) do
			local h_placetype, h_placename = holonym.placetype, holonym.unlinked_placename
			retcats = city_type_cat_handler {
				entry_placetype = "city",
				holonym_placetype = h_placetype,
				holonym_placename = h_placename,
				holonym_index = h_index,
				place_desc = place_desc,
			}
			if retcats then
				break
			end
		end
	end
	if not retcats then
		retcats = {}
	end

	-- Now find the appropriate capital-type category for the placetype of the holonym, e.g. 'State capitals'. If we
	-- recognize the holonym among the known holonyms in [[Module:place/locations]], also add a category like 'State
	-- capitals of the United States'.  Truncate e.g. 'autonomous region' to 'region', 'union territory' to 'territory'
	-- when looking up the type of capital category, if we can't find an entry for the holonym placetype itself (there's
	-- an entry for 'autonomous community').
	local capital_cat = export.placetype_to_capital_cat[holonym_placetype]
	if not capital_cat then
		capital_cat = export.placetype_to_capital_cat[holonym_placetype:gsub("^.* ", "")]
	end
	if capital_cat then
		capital_cat = ucfirst(capital_cat)
		local inserted_specific_variant_cat = false
		local group, key, spec, container_trail = export.find_matching_holonym_location(data)
		if group and container_trail[1] and not spec.no_container_cat then
			for _, container in ipairs(container_trail[1]) do
				insert(retcats, ("%s of %s"):format(capital_cat, export.get_prefixed_key(container.key,
					container.spec)))
				inserted_specific_variant_cat = true
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
having the same name. For example, the code in [[Module:place/locations]] knows about the city of [[Columbus]],
[[Ohio]], which has containing polities `Ohio` (a state) and `the United States` (a country). If either containing
polity is mentioned, the handler proceeds to return the key `Columbus` (along with `Ohio, USA` and `the United States`).
Otherwise, if any other state or country is mentioned, the handler returns nothing, and otherwise it assumes the
mentioned city is the one we're considering and returns `Columbus` etc. This works correctly if the place only mentions
Ohio and a holonym for a Columbus in a different country is encountered, because of the function
`augment_holonyms_with_container`, which adds the US as a holonym when Ohio is encountered.

The single parameter `data` is as in category handlers. The return value is a list of categories (without the preceding
language code).
]=]
local function generic_place_cat_handler(data)
	local from_demonym = data.from_demonym

	local retcats = {}
	local function insert_retkey(key, spec)
		if from_demonym then
			insert(retcats, key)
		else
			insert(retcats, ("Places in %s"):format(export.get_prefixed_key(key, spec)))
		end
	end

	local group, key, spec, container_trail = export.find_matching_holonym_location(data)
	if group then
		if not spec.no_generic_place_cat then
			-- This applies to continents and continental regions.
			insert_retkey(key, spec)
		end
		-- Categorize both in key, and in the larger location(s) that the key is part of, e.g. [[Hirakata]] goes in
		-- both [[Category:Places in Osaka Prefecture, Japan]] and [[Category:Places in Japan]]. But not when
		-- no_container_cat is set (e.g. for 'United Kingdom').
		if not spec.no_container_cat then
			for _, container_set in ipairs(container_trail) do
				local stop_adding_containers = false
				for _, container in ipairs(container_set) do
					if not container.spec.no_generic_place_cat then
						insert_retkey(container.key, container.spec)
					end
					if container.spec.no_container_cat then
						stop_adding_containers = true
					end
				end
				if stop_adding_containers then
					break
				end
			end
		end
		return retcats
	end
end

--[==[
Special category handler run for all placetypes that checks for specified division placetypes of known locations and
categorizes appropriately.
]==]
function export.political_division_cat_handler(data)
	if data.from_demonym then
		return
	end
	local group, key, spec, container_trail = export.find_matching_holonym_location(data)
	if group then
		local divlists = {}
		if spec.divs then
			insert(divlists, spec.divs)
		end
		if spec.addl_divs then
			insert(divlists, spec.addl_divs)
		end
		for _, divlist in ipairs(divlists) do
			if type(divlist) ~= "table" then
				divlist = {divlist}
			end
			for _, div in ipairs(divlist) do
				if type(div) == "string" then
					div = {type = div}
				end
				local sgdiv = export.maybe_singularize_placetype(div.type) or div.type
				local prep = div.prep or "of"
				local cat_as = div.cat_as or div.type
				if type(cat_as) ~= "table" then
					cat_as = {cat_as}
				end
				if not export.placetype_data[sgdiv] then
					internal_error("Placetype %s associated with known location key %s and data %s not found in " ..
						"`placetype_data`", sgdiv, key, spec)
				end
				if sgdiv == data.entry_placetype then
					local retcats = {}
					for _, pt_cat in ipairs(cat_as) do
						if type(pt_cat) == "string" then
							pt_cat = {type = pt_cat}
						end
						local pt_prep = pt_cat.prep or prep
						insert(retcats, ucfirst(pt_cat.type) .. " " .. pt_prep .. " " ..
							export.get_prefixed_key(key, spec))
					end
					return retcats
				end
			end
		end
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
function export.get_bare_categories(args, overall_place_spec)
	local bare_cats = {}
	local place_descs = overall_place_spec.descs

	local possible_placetypes_by_place_desc = {}
	for i, place_desc in ipairs(place_descs) do
		possible_placetypes_by_place_desc[i] = {}
		for _, placetype in ipairs(place_desc.placetypes) do
			if not export.placetype_is_ignorable(placetype) then
				local equivs = export.get_placetype_equivs(placetype, {register_former_as_non_former = true})
				for _, equiv in ipairs(equivs) do
					insert(possible_placetypes_by_place_desc[i], equiv.placetype)
				end
			end
		end
	end

	local function check_term(term)
		-- Treat Wikipedia links like local ones.
		term = term:gsub("%[%[w:", "[["):gsub("%[%[wikipedia:", "[[")
		term = export.remove_links_and_html(term)
		term = term:gsub("^the ", "")
		for i, place_desc in ipairs(place_descs) do
			-- Iterate over all matching locations in case there are multiple, as with Delhi defined as
			-- {{place|en|megacity/and/union territory|c/India|containing the national capital [[New Delhi]]}}.
			for group, key, spec, container_trail in export.iterate_matching_holonym_location {
				holonym_placetype = possible_placetypes_by_place_desc[i],
				holonym_placename = term,
				place_desc = place_desc,
			} do
				insert(bare_cats, key)
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
	for _, directive in ipairs(overall_place_spec.directives) do
		for _, term in ipairs(directive.terms) do
			if term.alt or term.term then
				check_term(term.alt or term.term)
			end
		end
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
function export.augment_holonyms_with_container(place_descs)
	for _, place_desc in ipairs(place_descs) do
		if place_desc.holonyms then
			-- This ends up containing a copy of the original holonyms, with the augmented holonyms inserted in their
			-- appropriate position. We don't just put them at the end because some holonyms have use the `:also`
			-- modifier, which causes category processing to restart at that point after generating categories for a
			-- preceding holonym, and we don't want the preceding holonym's augmented holonyms interfering with
			-- categorization of a later holonym. We proceed from right to left, and each time we augment, we copy
			-- the holonyms with the augmented holonym(s) inserted appropriately and replace the place description's
			-- holonyms with the augmented ones before the next iteration. The reason for this is so that e.g.
			-- {{place|neighborhood|city/Birmingham|co/West Midlands|cc/England}} doesn't throw an error during the
			-- augmentation process due to 'Birmingham' referring to two known locations (in England and Alabama). If
			-- we go left to right, we will throw an ambiguity error on `city/Birmingham` because code to exclude
			-- Birmingham, Alabama needs `c/United Kingdom` present (to cause a mismatch with `c/United States`),
			-- which isn't yet present as the augmentation code hasn't gotten to `cc/England` yet. For similar
			-- reasons, we need to include the augmented holonyms in the holonyms considered in the next iteration
			-- rather than modifying the place description once at athe end.
			for i = #place_desc.holonyms, 1, -1 do
				local holonym = place_desc.holonyms[i]
				if holonym.placetype and not export.placetype_is_ignorable(holonym.placetype) then
					local group, key, spec, container_trail = export.find_matching_holonym_location {
						holonym_placetype = holonym.placetype,
						holonym_placename = holonym.unlinked_placename,
						holonym_index = i,
						place_desc = place_desc,
					}
					if group and container_trail[1] and not spec.no_auto_augment_container then
						local augmented_holonyms = {}
						for j = 1, i do
							insert(augmented_holonyms, place_desc.holonyms[j])
						end
						for _, containers in ipairs(container_trail) do
							local any_no_auto_augment_container = false
							for _, container in ipairs(containers) do
								any_no_auto_augment_container = any_no_auto_augment_container or
									container.spec.no_auto_augment_container
								local containing_type = container.spec.placetype
								if type(containing_type) == "table" then
									-- If the containing type is a list, use the first element as the canonical variant.
									containing_type = containing_type[1]
								end
								local full_container_placename, elliptical_container_placename =
									m_locations.key_to_placename(container.group, container.key)
								-- Don't side-effect holonyms while processing them.
								local new_holonym = {
									-- By the time we run, the display has already been generated so we don't need to
									-- set display_placename.
									placetype = containing_type,
									-- placename_to_key() for the group should correctly handle both full and elliptical
									-- placenames, but the full placename seems less likely to be ambiguous. FIXME: We
									-- should just store the key directly and use it when available to avoid having to
									-- convert key to placename and back to key.
									unlinked_placename = full_container_placename,
									-- Indicate that this is an augmented holonym, and was derived from the specified
									-- holonym. In iterate_matching_holonym_location(), we ignore augmented holonyms
									-- derived from holonyms that are different from the holonym we're searching for but
									-- of the same placetype. This is to correctly handle a situation like
									-- {{place|river|dept/Ardèche,Gard,Vaucluse,Bouches-du-Rhône|c/France}}. Here,
									-- `Ardèche` is in `r/Auvergne-Rhône-Alpes`, while `Gard` is in `r/Occitania` and
									-- the other two are in `r/Provence-Alpes-Côte d'Azur`. Augmenting proceeds from
									-- right to left, so after it adds `r/Provence-Alpes-Côte d'Azur` to
									-- `Bouches-du-Rhône`, Vaucluse gets augmented correctly but `Gard` fails to match
									-- in find_matching_holonym_location() because of the mismatch between augmented
									-- `r/Provence-Alpes-Côte d'Azur` and actual `r/Occitania`. Similarly, all later
									-- calls to find_matching_holonym_location() fail to match `Gard` (and likewise
									-- `Ardèche`) against any known location. To deal with this, we mark augmented
									-- holoynms as being augmented due to a source holonym, and when processing a given
									-- holonym, ignore augmented holonyms from other holonyms of the same placetype.
									-- The restriction to the same placetype is so that `Birmingham` still gets
									-- correctly disambiguated to Birmingham, England in the example given above near
									-- the top of this function, using the augmented holonym `c/United Kingdom` added by
									-- the specified `cc/England` (whose placetype `constituent country` differs from
									-- the placetype `city` of Birmingham).
									augmented_from_holonym = holonym,
								}
								insert(augmented_holonyms, new_holonym)
								-- But it is safe to modify other parts of the place_desc.
								export.key_holonym_into_place_desc(place_desc, new_holonym)
							end
							if any_no_auto_augment_container then
								break
							end
						end
						for j = i + 1, #place_desc.holonyms do
							insert(augmented_holonyms, place_desc.holonyms[j])
						end
						place_desc.holonyms = augmented_holonyms
					end
				end
			end
		end
	end
end


-- Cat handler for district, areas, neighborhoods and suburbs. Districts are tricky because they can either be political
-- divisions or city neighborhoods. Areas similarly can be political divisions (rarely; specifically, in Kuwait), city
-- neighborhoods or larger geographical areas/regions. We handle this as follows:
-- (1) `placetype_data` cat entries for specific countries or country divisions take precedence over cat_handlers, so if
--     the user says {{tl|place|district|s/Maharashtra|c/India}}, we won't even be called because there is an entry that
--     categorizes into [[:Category|Districts of Maharashtra, India]].
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
	local function get_plural_entry_placetype(location_spec, container_trail)
		if data.entry_placetype == "suburb" then
			return "Suburbs"
		else
			-- Check for `british_spelling` setting on the spec itself or any container.
			local uses_british_spelling = location_spec.british_spelling
			if uses_british_spelling == nil and container_trail then
				for _, container_set in ipairs(container_trail) do
					local must_outer_break = false
					for _, container in ipairs(container_set) do
						if container.spec.british_spelling ~= nil then
							uses_british_spelling = container.spec.british_spelling
							must_outer_break = true
							break
						end
					end
					if must_outer_break then
						break
					end
				end
			end

			return uses_british_spelling and "Neighbourhoods" or "Neighborhoods"
		end
	end

	-- First check the immediate holonym to see if it's a city or a city-like top-level entity (Hong Kong, Bonaire,
	-- etc.)
	local group, key, spec, container_trail = export.find_matching_holonym_location(data)
	if group and not spec.is_former_place and spec.is_city then
		return {get_plural_entry_placetype(spec, container_trail) .. " of " .. export.get_prefixed_key(key, spec)}
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
			return export.get_placetype_prop(pt, "has_neighborhoods")
		end, {continue_on_nil_only = true})
	end
	if has_neighborhoods then
		-- Loop up the holonyms, looking for city and city-like entities in case of e.g. [[Sepulveda]] written
		-- {{place|en|neighborhood|valley/San Fernando Valley|city/Los Angeles|s/California|c/USA}}
		-- but also look for a recognizable poldiv, and if so categorize as "Neighborhoods in POLDIV". We need
		-- to start with the current holonym, which is especially important for neighborhoods and suburbs that
		-- may have the first holonym be a recognizable province, etc. but can't hurt otherwise. (Previously
		-- we skipped the first/current holonym.)
		for other_holonym_index, other_holonym in export.get_holonyms_to_check(data.place_desc,
			data.holonym_index) do
			local other_holonym_data = {
				holonym_placetype = other_holonym.placetype,
				holonym_placename = other_holonym.unlinked_placename,
				holonym_index = other_holonym_index,
				place_desc = data.place_desc,
			}
			local group, key, spec, container_trail = export.find_matching_holonym_location(other_holonym_data)
			if group and not spec.is_former_place then
				return {get_plural_entry_placetype(spec, container_trail) .. (spec.is_city and " of " or " in ") ..
					export.get_prefixed_key(key, spec)}
			end
		end
	end
end


function export.check_already_seen_string(holonym_placename, already_seen_strings)
	local canon_placename = ulower(m_links.remove_links(holonym_placename))
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
	if export.check_already_seen_string(holonym_placename, already_seen_strings or ulower(prefix)) then
		return holonym_placename
	end
	if holonym_placename:find("%[%[") then
		return prefix .. " " .. holonym_placename
	end
	return prefix .. " [[" .. holonym_placename .. "]]"
end


-- Suffix display handler that adds a suffix such as " parish" to the display form of holonyms.
-- Works identically to prefix_display_handler but for suffixes instead of prefixes.
local function suffix_display_handler(suffix, holonym_placename, already_seen_strings, include_suffix_in_link)
	if export.check_already_seen_string(holonym_placename, already_seen_strings or ulower(suffix)) then
		return holonym_placename
	end
	if holonym_placename:find("%[%[") then
		return holonym_placename .. " " .. suffix
	end
	if include_suffix_in_link then
		return "[[" .. holonym_placename .. " " .. suffix .. "]]"
	else
		return "[[" .. holonym_placename .. "]] " .. suffix
	end
end

-- Display handler for boroughs. New York City boroughs are display as-is. Others are suffixed
-- with "borough".
local function borough_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_locations.new_york_boroughs[unlinked_placename] then
		-- Hack: don't display "borough" after the names of NYC boroughs
		return holonym_placename
	end
	return suffix_display_handler("borough", holonym_placename)
end

local function county_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	-- Display handler for Irish counties. Irish counties are displayed as e.g. "County [[Cork]]".
	if m_locations.ireland_counties["County " .. unlinked_placename .. ", Ireland"] or
		m_locations.northern_ireland_counties["County " .. unlinked_placename .. ", Northern Ireland"] then
		return prefix_display_handler("County", holonym_placename)
	end
	-- Display handler for Taiwanese counties. Taiwanese counties are displayed as e.g. "[[Chiayi]] County".
	if m_locations.taiwan_counties[unlinked_placename .. " County, Taiwan"] then
		return suffix_display_handler("County", holonym_placename)
	end
	-- Display handler for Romanian counties. Romanian counties are displayed as e.g. "[[Cluj]] County".
	if m_locations.romania_counties[unlinked_placename .. " County, Romania"] then
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
	local suffix = m_locations.japan_prefectures[unlinked_placename .. " Prefecture, Japan"] and "Prefecture" or "prefecture"
	return suffix_display_handler(suffix, holonym_placename)
end

-- Display handler for provinces of North and South Korea. Korean provinces are displayed as e.g.
-- "[[Gyeonggi]] Province". Others are displayed as-is.
local function province_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_locations.north_korea_provinces[unlinked_placename .. " Province, North Korea"] or
	   m_locations.south_korea_provinces[unlinked_placename .. " Province, South Korea"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Iranian provinces. Iranian provinces are displayed as e.g. "[[Hormozgan]] Province". Others
	-- are displayed as-is.
	if m_locations.iran_provinces[unlinked_placename .. " Province, Iran"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Laotian provinces. Laotian provinces are displayed as e.g. "[[Vientiane]] Province". Others
	-- are displayed as-is.
	if m_locations.laos_provinces[unlinked_placename .. " Province, Laos"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Thai provinces. Thai provinces are displayed as e.g. "[[Chachoengsao]] Province". Others are
	-- displayed as-is.
	if m_locations.thailand_provinces[unlinked_placename .. " Province, Thailand"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	-- Display handler for Turkish provinces. Thai provinces are displayed as e.g. "[[Antalya]] Province". Others are
	-- displayed as-is.
	if m_locations.turkey_provinces[unlinked_placename .. " Province, Turkey"] then
		return suffix_display_handler("Province", holonym_placename)
	end
	return holonym_placename
end

-- Display handler for Nigerian states. Nigerian states are display as "[[Kano]] State". Others are displayed as-is.
local function state_display_handler(holonym_placetype, holonym_placename)
	local unlinked_placename = m_links.remove_links(holonym_placename)
	if m_locations.nigeria_states[unlinked_placename .. " State, Nigeria"] then
		return suffix_display_handler("State", holonym_placename)
	end
	return holonym_placename
end

-- Display handler for voivodeships. Display as e.g. [[Subcarpathian Voivodeship]].
local function voivodesip_display_handler(holonym_placetype, holonym_placename)
	return suffix_display_handler("Voivodeship", holonym_placename, nil, "include_suffix_in_link")
end

------------------------------------------------------------------------------------------
--                                     Placetype data                                   --
------------------------------------------------------------------------------------------

--[==[ var:
Main placetype data structure. This specifies, for each canonicalized placetype, various properties. The keys are
placetypes (in the singular, except for category-only placetypes, which are plural and followed by `!`), and the value
is a table of properties.  The `"*"` key is special and is used for adding "generic" categories of the form
`Places in ``location`` `; it runs for all entry placetypes. Keys in the form of plural placetypes followed by `!` are
used only in [[Module:category tree/topic cat/data/Places]] for specifying the properties of categories containing the
specified placetype, esp. bare categories like [[:Category:States and territories]] (rather than qualified categories
like [[:Category:States and territories of Australia]]).

Keys under the value table for a given placetype of are two types: ''property keys'' (which specify the value of
specific properties) and ''categorization keys'' (which tell how to categorize certain sorts of holonyms if the
placetype in question occurs as an entry placetype). Categorization keys are either the special value `default` or are
wildcard strings with a slash in them, such as `"country/*"`. Note that only wildcard strings are currently allowed
directly in the placetype data; everything else is handled through category handlers, either per-placetype or special
(such as `political_division_cat_handler`). The algorithm for how category keys and handlers are used to generate
categories is described at the top of [[Module:place]].

There are several recognized property keys, of various types:

1. The following link-related property keys are recognized:
* `link`: '''Required''' except in category-only placetypes ending in `!`. Describes how to link and display the
  placetype in the formatted description when occurring as an entry placetype. Also used for formatting pluralized
  placetypes (which may occur in entry placetypes, esp. new-format ones, such as `two <<islands>>`) and may occur in
  categories). The possible values are:
*# `true`: Link to the same-named Wiktionary entry. This creates a raw link, e.g. `<nowiki>[[city]]</nowiki>`, which is
   converted to an English-specific link by JavaScript postprocessing. If the placetype is plural, this creates a
   two-part raw link e.g. `<nowiki>[[city|cities]]</nowiki>`.
*# `"w"`: Link to the same-named Wikipedia entry. This creates a two-part link, e.g.
   `<nowiki>[[w:census town|census town]]</nowiki>`, or `<nowiki>[[w:census town|census towns]]</nowiki>` if the
   placetype is given plural.
*# `"+..."`: Create a two-part link to the entry following the `+` sign. For example, if `cercle` specifies
   `"+w:cercles of Mali"`, a two-part link `<nowiki>[[w:cercles of Mali|cercle]]</nowiki>` will be generated, or
   `<nowiki>[[w:cercles of Mali|cercles]]</nowiki>` if plural `cercles` is specified.
*# `"separately"`: Link each word separately. For example, if `administrative territory` specifies `"separately"`, it
   will be linked as `<nowiki>[[administrative]] [[territory]]</nowiki>`, or as
   `<nowiki>[[administrative]] [[territory|territories]]</nowiki>` if plural `administrative territories` is given.
*# another string: Use that string directly. If the placetype is plural, `pluralize()` in [[Module:en-utilities]] is
   called on the string, which will correctly pluralize most strings, including those with links in them. (If there
   are multiple links, the display form of the last link is pluralized.)
*# `false`: This placetype is not allowed as an entry placetype. An error will be thrown if this placetype is given as
   an entry placetype. This is specified for internal-use placetypes, especially placetypes used in conjunction with
   the qualifiers `former`, `ancient`, `historical` and such.
* `plural_link`: If specified and the placetype is plural, use the value in place of generating a pluralized version of
  the link spec in `link`. Most commonly, this is either a string with links in it (which is used directly) or the
  value `false`, indicating that the placetype cannot occur plural. (This is used for example by `caplc`, which displays
  as `<nowiki>[[capital]] and [[large]]st [[city]]</nowiki>`, where a plural version doesn't make sense.) Generally if
  this is specified, `plural` also needs to be specified to give a special placetype plural; this situation occurs
  especially with multiword placetypes where something other than the last word is pluralized. An example is
  `town with bystatus`, whose plural is `towns with bystatus`, which needs to be explicitly given. This example uses
  `link = <nowiki>"[[town]] with [[bystatus#Norwegian Bokmål|bystatus]]"</nowiki>` ({{m|nb|bystatus}}) is a Norwegian
  Bokmål word, and template calls aren't currently permitted in link strings), along with
  `plural_link = <nowiki>"[[town]]s with [[bystatus#Norwegian Bokmål|bystatus]]"</nowiki>`.
* `category_link`: Spec indicating how to display the placetype when occurring in category descriptions. Defaults to
  the value of `link`, and in turn is overridden by more specific `category_link_*` keys; see below. Category-only
  placetypes (which are plural and end in `!`) usually use `category_link` in preference to `link`. The value of
  `category_link` can be any of the types of specs given above, but most commonly is a plural string with links in it,
  spelling out the description; in this case it is used directly. When both `category_link` and `link` are given, the
  value in `category_link` is typically longer and more descriptive. For example, `polity` uses `link = true`, which
  just generates a link `<nowiki>[[polity]]</nowiki>` or plural `<nowiki>[[polity|polities]]</nowiki>`, but specifies a
  separate `category_link = <nowiki>"[[independent]] or [[semi-]][[independent]] [[polity|polities]]"</nowiki>`, which
  clarifies in the category description what a polity is.
* `category_link_top_level`: Spec indicating how to display top-level (bare/unqualified) categories, i.e. categories
  where the placetype is not followed by `in ``location`` ` or `of ``location`` `. If given, this overrides
  `category_link` for this type of category.
* `category_link_before_noncity`: Spec indicating how to display qualified categories of the form
  ` ``placetypes`` in/of ``location`` ` where ``location`` does not refer to a city. If given, this overrides
  `category_link` for this type of category.
* `category_link_before_city`: Spec indicating how to display qualified categories of the form
  ` ``placetypes`` in/of ``location`` ` where ``location`` refer to a city. If given, this overrides `category_link` for
  this type of category. An example where this is given is `neighborhood`, which uses the following specs:<ol>
  <li>`link = true`</li>
  <li>`category_link = <nowiki>"[[neighborhood]]s, [[district]]s and other subportions of [[city|cities]]"</nowiki>`</li>
  <li>`category_link_before_city = <nowiki>"[[neighborhood]]s, [[district]]s and other subportions"</nowiki>`</li>
  </ol> This has the effect of making the entry placetype `neighborhood` display as just
  `<nowiki>[[neighborhood]]</nowiki>`, while e.g. a category like `Neighborhoods of Chicago` displays as
  `<nowiki>[[neighborhood]]s, [[district]]s and other subportions of [[Chicago]], ...</nowiki>` and a category like
  `Neighborhoods in Illinois, USA` displays as
  `<nowiki>[[neighborhood]]s, [[district]]s and other subportions of [[city|cities]] in [[Illinois]], ...</nowiki>`.

2. There is currently one fallback-related property key recognized:
* `fallback`: If specified, its value is a placetype which will be used for categorization purposes if no categories
  get added using the placetype itself. As an example, `branch` sets a fallback of `river` but also sets
  `preposition = "of"`, meaning that {{tl|place|en|branch|riv/Mississippi}} displays as `a branch of the Mississippi`
  (whereas `river` itself uses the preposition `in`), but otherwise categorizes the same as `river`. A more complex
  example is `area`, which sets a fallback of `geographic and cultural area` and also sets a category handler that
  checks for cities or city-like entities (e.g. boroughs) occurring as holonyms and categorizes the toponym under
  [[:Category:Neighborhoods of CITY]] (for recognized cities) or otherwise [[:Category:Neighborhoods of POLDIV]] (for
  the nearest containing recognized location). In addition, `area` is set as a political division of Kuwait, meaning if
  `c/Kuwait` occurs as holonym, the toponym is categorized under [[:Category:Areas of Kuwait]]. If none of these
  categories trigger, the fallback of `geographic and cultural area` will take effect, and the toponym will be
  categorized as e.g. [[:Category:Geographic and cultural areas of England]].

3. There is currently one property to control irregular plurals of placetypes:
* `plural`: If specified, its value is the plural of the placetype. Otherwise, the default pluralization algorithm in
  [[Module:en-utilities]] applies (which correctly pluralizes most words, including those ending in `-y`, `-ch`, `-sh`,
  `-x`, etc.). The value of `plural` is also used when converting a pluralized placetype into its singular equivalent;
  for example, since the placetype `kibbutz` has `plural = "kibbutzim"`, the placetype `kibbutzim` will be recognized
  as a plural and singularized to `kibbutz`. For this reason, it's occasionally necessary to specify a `plural` value
  even when the default pluralization algorithm works correctly, if the default singularization algorithm won't
  correctly reverse the pluralization (as with `pass` and other terms ending in `-ss`).

4. The following property keys relate to generating categories for entry placetypes and specifying the parents of those
   categories:
* `class`: The general class of placetype. This is used for various purposes: (a) to categorize placetypes preceded by
  a qualifier such as `former`, `ancient`, `medieval` or `historical` (note that these placetypes are not all treated
  alike); (b) to determine the parent category of bare placetype categories (e.g. [[:Category:Villages]] for placetype
  `village`); (c) to determine whether to add a parent category `political divisions of specific countries` to
  qualified placetype categories (e.g. [[:Category:Villages in Mali]]). The possible values are:
*# `polity`: a more-or-less sovereign/independent polity, such as a country, kingdom or empire.
*# `subpolity`: a non-sovereign division of a polity, above the level of an individual settlement.
*# `settlement`: a city or smaller equivalent, such as a village. This also includes administrative divisions of a
   settlement, such as wards and barangays.
*# `non-admin settlement`: similar to a settlement but without administrative or political significance, such as an
   unincorporated community, farm or neighborhood.
*# `capital`: a settlement that is a capital. A former capital is generally still in existence, just not the capital
   any more.
*# `natural feature`: any non-man-made feature, such as a lake, mountain, island, ocean, etc.
*# `man-made structure`: a man-made feature below the level of a neighborhood, such as a house, airport, university,
   metro station, park or the like.
*# `geographic region`: a geographic or cultural region or area that has no administrative significance. These may vary
   greatly in size but typically have some sort of cultural significance (possibly historical). The `former`, `ancient`,
   etc. qualifier has no effect on the category of these placetypes.
*# `generic place`: a place that isn't further qualified into any specific subtype.
* `former_type`: The class of placetype used for categorizing placetypes preceded by a qualifier such as `former`,
  `ancient`, `medieval` or `historical`. The possible values are the same as for `class` but with the addition of
  `dependent territory` (for colonies, protectorates and the like) and `!` (ignore the historical/former/ancient/etc.
  qualifier; used e.g. with `fictional location` and `mythological location`). If not specified, the value of `class`
  is used. When a qualifier such as `former`, `ancient`, `medieval` or `historical` is encountered (specifically, those
  in `former_qualifiers`), it is mapped using `former_qualifiers` to the appropriate internal qualifier or qualifiers
  (one or both of `ANCIENT` and/or `FORMER`, which are written in all-caps to distinguish them from user-specified
  qualifiers), which is prepended to the value of `former_type` or `class` to form a placetype whose properties are
  looked up to determine how to categorize the toponym in question. For example, if `medieval village` is given, we map
  `medieval` to `ANCIENT` and `FORMER`, and `village` to its `class` of `settlement`, and enter the placetypes
  `ANCIENT settlement` and `FORMER settlement` (in that order) into the list of equivalent placetypes returned by
  `get_placetype_equivs`. In this case, there is an entry in `placetype_data` for `ANCIENT settlement`, so its default
  category spec `Ancient settlements` is used as the category. If on the other hand `medieval kingdom` is given, where
  `kingdom` has a `class` value `polity`, we first look up `ANCIENT polity`, see there is no entry in `placetype_data`
  for it, and then look up `FORMER polity`, which exists and has a default category spec `Former polities`, which is
  used as the category. Note that if the placetype following the "former" qualifier is recognized in `placetype_data`
  but has no `former_type` or `class` and no fallback with a `former_type` or `class` specified, it is an internal
  error; but if the placetype isn't recognized (e.g. something like `former greenhouse` is specified and we don't have
  an entry for `greenhouse`), we just track the occurrence and end up not categorizing.
* `bare_category_parent`: This specifies the first parent category of a bare placetype category named according to the
  placetype in question (e.g. [[:Category:Atolls]] for placetype `atoll`, or [[:Category:Individual buildings]] for
  placetype `individual buildings!`). If not specified, the first parent category is determined by the value of `class`,
  using the mapping `class_to_bare_category_parent` in [[Module:category tree/topic cat/data/Places]].
* `addl_bare_category_parents`: Extra parent categories to add a bare placetype category to (see `bare_category_parent`
  just above).
* `inherently_former`: If specified and the given placetype is used as an entry placetype, act as if `former` or
  `ancient` (depending on the value of `inherently_former`) were prefixed to the placetype. This is for placetypes that
  always refer to no-longer-existing entities, such as `satrapy` and `treaty port`. The value of `inherently_former` is
  a list of internal qualifiers (one or more of `ANCIENT` and/or `FORMER`), just as for `former_qualifiers`, and the
  implementation is the same.
* `cat_handler`: Handler used to generate the categories to add a given toponym to, if its entry placetype is the
  placetype in question. Generally the `cat_handler` function checks the holonyms specified in order to determine which
  category or categories to generate. For example, `district_neighborhood_cat_handler` handles placetypes `district`,
  `neighborhood`, `subdivision`, `suburb` and the like, and either adds the toponym to a category like
  `Neighborhoods of ``city`` ` (if a recognized city is given as a holonym), or otherwise a category like
  `Neighborhoods in ``location`` ` (for the first recognized non-city location given as a holonym, if an unrecognized
  city or city-like entity is given before the recognized non-city). The algorithm that runs the category handlers
  iterates over holonyms from left to right, running the `cat_handler` function on each holonym in turn until one or
  more categories are returned; see below for more specifics. (Note that countries for which e.g. a `district` is a
  political division do not get the corresponding category added by the `district_neighborhood_cat_handler` function but
  by `political_division_cat_handler`.) `cat_handler` functions are called with one argument, `data`, describing the
  resolved entry placetype (i.e. after resolving placetype aliases and fallbacks) and the holonym being processed. The
  return value should be a list of category specs (categories minus the langcode prefix, with `+++` standing for the
  holonym key, or the value `true`, which stands for ` ``Placetypes`` in/of ``Holonym`` `, i.e. the pluralized placetype
  with the appropriate preposition as specified in `placetype_data`). `data` contains the following fields:
** `entry_placetype`: the resolved entry placetype for the entry placetype being processed (i.e. it will always have an
   entry in `placetype_data` but may not be the original placetype given by the user);
** `holonym_placetype` and `holonym_placename`: the holonym placetype and placename being processed;
** `holonym_index`: the index of the holonym being processed, or {nil} if we're handling an overriding holonym (FIXME:
   we will change the overriding holonym algorithm so there will be an index even when processing overriding holonyms);
** `place_desc`: a full description of the {{tl|place}} call, as specified at the top of [[Module:place]];
** `from_demonym`: If set, we are called from [[Module:demonym]], triggered by {{tl|demonym-adj}} or
   {{tl|demonym-noun}}, instead of being triggered by {{tl|place}}.
* `has_neighborhoods`: If `true`, the specified placetype is city-like. This is used in the
  `district_neighborhood_cat_handler` to determine whether to add a category such as `Neighborhoods in ``location`` `;
  see the section just above on `cat_handler`.

5. The following preposition-related property keys are recognized:
* `preposition`: The preposition used after this placetype when it occurs as an entry placetype. Defaults to `"in"`.
* `generic_before_non_cities`: If specified, the appropriate category description handler in
  [[Module:category tree/topic cat/data/Places]] will recognize categories of the form
  ` ``Placetype`` in/of ``location`` ` for the specified placetype and preposition, if ``location`` is a non-city. This
  is used to generate descriptions for categories added by category handlers and by explicit category specs in the
  placetype data. All placetypes that specify `generic_before_non_cities` or `generic_before_cities` *MUST* also specify
  a value for `class` so that the category tree code can determine whether it's a political or non-political division.
* `generic_before_cities`: Like `generic_before_non_cities` but for locations referring to cities.

6. The following property keys control the auto-addition of affixes when formatting holonyms of a particular placetype:
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
* `display_handler`: A function of two arguments, `holonym_placetype` and `holonym_placename` (specifying a holonym).
  Its return value is a string specifying the display form of the holonym.

7. The following property keys control the indefinite and definite articles used before entry placetypes and/or holonyms
   of the specified placetype.
* `entry_placetype_use_the`: Use `"the"` before this placetype when it occurs as an entry placetype.
* `entry_placetype_indefinite_article`: Indefinite article used before this placetype when it occurs as an entry
  placetype (usually `"a"`, specifically for placetypes beginning with u- that don't take the indefinite article
  `"an"`). Defaults to the appropriate indefinite article (`"a"` or `"an"` depending on whether the placetype begins
  with a vowel). Overridden by `entry_placetype_use_the`, and unlike for most properties, does not apply to equivalent
  placetypes (i.e. fallbacks or those formed by removing a qualifier from the beginning); only to the exact placetype
  specified.
* `holonym_use_the`: Use `"the"` before holonyms of this placetype.

'''NOTE:'''
# The `link` property must be specified on all placetypes, except those ending in `!` (category-only placetypes), which
  must have either `link` or `category_link` specified.
# Either the `class` or `former_type` property must be specified on all placetypes not ending in `!` that do not have a
  fallback (if a placetype has a fallback and omits the `class` and `former_type` properties, they are taken from the
  fallback). An internal error will result if a placetype has no `class` or `former_type` property derivable either
  directly or through a fallback, if an attempt is made to categorize a former/ancient/historical/etc. entity of this
  placetype.
# It is possible to have multiple levels of fallback (e.g. `frazione` falls back to `hamlet`, which falls back
  to `village`). Fallback loops will cause an internal error. All placetypes specified as fallbacks must exist in
  `placetype_data` or an internal error occurs.
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
		link = false,
		cat_handler = generic_place_cat_handler,
	},
	["administrative atoll"] = {
		-- Maldives
		link = "+w:administrative divisions of the Maldives",
		preposition = "of",
		class = "subpolity",
	},
	["administrative capital"] = {
		link = "w",
		fallback = "capital city",
	},
	["administrative center"] = {
		link = "w",
		fallback = "administrative centre",
	},
	["administrative centre"] = {
		link = "w",
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
	},
	["administrative county"] = {
		link = "w",
		fallback = "county",
	},
	["administrative district"] = {
		link = "w",
		fallback = "district",
	},
	["administrative headquarters"] = {
		link = "separately",
		fallback = "administrative centre",
	},
	["administrative region"] = {
		link = true,
		preposition = "of",
		suffix = "region", -- but prefix is still "administrative region (of)"
		fallback = "region",
		class = "subpolity",
	},
	["administrative seat"] = {
		link = "w",
		fallback = "administrative centre",
	},
	["administrative territory"] = {
		link = "separately",
		preposition = "of",
		suffix = "territory", -- but prefix is still "administrative territory (of)"
		fallback = "territory",
		class = "subpolity",
	},
	["administrative unit"] = {
		-- Grrr, it's difficult to generalize about "administrative units". In Albania, "administrative unit" is an
		-- official term for a city-level division of municipalities; Wikipedia renders it using the more practical term
		-- "commune". In Pakistan, "administrative unit" is a collective term used to refer to all the different types
		-- of first-level divisions (four provinces, one federal territory, and two "disputed territories", i.e. Azad
		-- Kashmir and Gilgit-Balistan, that are variously described). For this reason, we set no fallback, but we need
		-- to include this so that it can be used as a placetype for Albania, categorizing as communes.
		link = "w",
		class = "subpolity",
	},
	["administrative village"] = {
		link = "w",
		preposition = "of",
		has_neighborhoods = true,
		class = "settlement",
	},
	["airport"] = {
		link = true,
		class = "man-made structure",
		default = {true},
	},
	["alliance"] = {
		link = true,
		fallback = "confederation",
	},
	["ANCIENT capital"] = {
		link = false,
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
		-- FIXME: Consider removing 'ancient settlements' here. Ancient capitals, like former capitals, often still
		-- exist but just aren't the capital any more. Maybe we should have an 'Ancient capitals' category.
		default = {"Ancient settlements", "Former capitals"},
	},
	["ANCIENT non-admin settlement"] = {
		link = false,
		class = "non-admin settlement",
		fallback = "ANCIENT settlement",
	},
	["ANCIENT settlement"] = {
		link = false,
		has_neighborhoods = true,
		class = "settlement",
		default = {"Ancient settlements"},
	},
	["ancient settlements!"] = {
		category_link = "former [[city|cities]], [[town]]s and [[village]]s that existed in [[antiquity]]",
		bare_category_parent = "former settlements",
	},
	["archipelago"] = {
		link = true,
		fallback = "island",
	},
	["area"] = {
		link = true,
		preposition = "of",
		fallback = "geographic and cultural area",
		-- Areas can either be administrative divisions (specifically of Kuwait) or geographic areas. Assume the former
		-- when categorizing 'Areas' but the latter when handling e.g. 'historical area'.
		class = "subpolity",
		former_type = "geographic region",
		cat_handler = district_neighborhood_cat_handler,
	},
	["arm"] = {
		link = true,
		preposition = "of",
		class = "natural feature",
		default = {"Seas"},
	},
	["arrondissement"] = {
		link = true,
		preposition = "of",
		-- FIXME!!! Grrrrr!!! In some countries, arrondissements are divisions of cities; in others, they are divisions
		-- of departments or provinces. Need to conditionalize on the country for both of the following.
		class = "subpolity",
		has_neighborhoods = true,
	},
	["associated province"] = {
		link = "separately",
		fallback = "province",
	},
	["atoll"] = {
		-- FIXME! Atolls are administrative divisions of the Maldives but natural features elsewhere. Need to
		-- conditionalize former_type on the country. See also `administrative atoll`.
		link = true,
		class = "natural feature",
		bare_category_parent = "islands",
		default = {true},
	},
	["autonomous city"] = {
		link = "w",
		preposition = "of",
		fallback = "city",
		has_neighborhoods = true,
	},
	["autonomous community"] = {
		-- Spain; refers to regional entities, not village-like entities, as might be expected from "community"
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["autonomous island"] = {
		-- Comoros; seems like an administrative atoll of the Maldives.
		link = "+w:autonomous islands of Comoros",
		preposition = "of",
		class = "subpolity",
	},
	["autonomous oblast"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = "oblast",
		class = "subpolity",
	},
	["autonomous okrug"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = "okrug",
		class = "subpolity",
	},
	["autonomous prefecture"] = {
		link = true,
		fallback = "prefecture",
	},
	["autonomous province"] = {
		link = "w",
		fallback = "province",
	},
	["autonomous region"] = {
		link = "w",
		preposition = "of",
		fallback = "administrative region",
		-- "administrative region" sets an affix of "region" but we want to display as "Tibet Autonomous Region"
		-- if the user writes 'ar:Suf/Tibet'.
		affix = "autonomous region",
	},
	["autonomous republic"] = {
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["autonomous territorial unit"] = {
		-- Moldova; only two of them, one for Gagauzia and one for Transnistria.
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["autonomous territory"] = {
		link = "w",
		fallback = "dependent territory",
	},
	["bailiwick"] = {
		-- Jersey, etc.
		link = true,
		fallback = "polity",
	},
	["barangay"] = {
		-- Philippines
		link = true,
		class = "settlement",
		-- Barangays are formal administrative divisions of a city rather than informal neighborhoods, but can use
		-- some of the properties of a neighborhood.
		fallback = "neighborhood",
	},
	["barrio"] = {
		-- Spanish-speaking countries; Philippines
		link = true,
		-- FIXME: Not completely correct, in some countries barrios are formal administrative divisions of a city.
		-- `class` will need to conditionalize on the country to be completely correct.
		fallback = "neighborhood",
	},
	["basin"] = {
		link = true,
		fallback = "lake",
	},
	["bay"] = {
		link = true,
		preposition = "of",
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["beach"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"water"},
		default = {true},
	},
	["beach resort"] = {
		link = "w",
		fallback = "resort town",
	},
	["bishopric"] = {
		link = true,
		fallback = "polity",
	},
	["bodies of water!"] = {
		-- FIXME: This is maybe?) a type category not a name category. There should be an option for this. We need to
		-- straighten out the type vs. name vs. related-to issue.
		category_link = "[[body of water|bodies of water]]",
		class = "natural feature",
		addl_bare_category_parents = {"landforms", "ecosystems", "water"},
	},
	["borough"] = {
		link = true,
		preposition = "of",
		display_handler = borough_display_handler,
		has_neighborhoods = true,
		-- "former borough" could be a former settlement or a former part of a city but seems more likely to
		-- be a former subpolity, particularly in England. FIXME, we really need a handler to take care of this
		-- properly.
		class = "subpolity",
		-- Grr, some boroughs are city-like but some (e.g. in Britain) may be larger.
	},
	["borough seat"] = {
		link = true,
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
	},
	["branch"] = {
		link = true,
		preposition = "of",
		fallback = "river",
	},
	["building"] = {
		link = true,
		class = "man-made structure",
		default = {"Individual buildings"},
	},
	["built-up area"] = {
		link = "w",
		fallback = "area",
	},
	["burgh"] = {
		link = true,
		fallback = "borough",
	},
	["caliphate"] = {
		link = true,
		fallback = "polity",
	},
	["canton"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		class = "subpolity",
	},
	["cape"] = {
		link = true,
		fallback = "headland",
	},
	["capital"] = {
		link = true,
		fallback = "capital city",
	},
	["capital city"] = {
		link = true,
		category_link = "[[capital city|capital cities]]: the [[seat of government|seats of government]] for a country or [[political]] [[division]] of a country",
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
		bare_category_parent = "cities",
		cat_handler = capital_city_cat_handler,
		default = {true},
		-- The following is necessary so that e.g. [[Melbourne]] defined as {{place|en|capital city|s/Victoria|c/Australia}}
		-- gets categorized in the bare category [[Category:en:Melbourne]]; otherwise placetype 'capital city' wouldn't
		-- match against the placetype 'city' of Melbourne.
		fallback = "city",
	},
	["caplc"] = {
		link = "[[capital]] and [[large]]st [[city]]",
		plural_link = false,
		fallback = "capital city",
	},
	["caravan city"] = {
		link = "w",
		fallback = "city",
		class = "settlement",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["castle"] = {
		link = true,
		fallback = "building",
	},
	["cathedral city"] = {
		link = true,
		fallback = "city",
	},
	["cattle station"] = {
		-- Australia
		link = true,
		fallback = "farm",
	},
	["census area"] = {
		link = true,
		affix_type = "Suf",
		has_neighborhoods = true,
		class = "non-admin settlement",
	},
	["census-designated place"] = {
		-- United States
		link = true,
		class = "non-admin settlement",
	},
	["census division"] = {
		-- Canada
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["census town"] = {
		link = "w",
		fallback = "town",
	},
	["central business district"] = {
		link = true,
		fallback = "neighborhood",
	},
	["cercle"] = {
		-- Mali
		link = "+w:cercles of Mali",
		preposition = "of",
		class = "subpolity",
	},
	["ceremonial county"] = {
		link = true,
		fallback = "county",
	},
	["chain of islands"] = {
		link = "[[chain]] of [[island]]s",
		plural = "chains of islands",
		plural_link = "[[chain]]s of [[island]]s",
		fallback = "island",
	},
	["channel"] = {
		link = true,
		fallback = "strait",
	},
	["charter community"] = {
		-- Northwest Territories, Canada
		link = "w",
		fallback = "village",
	},
	["city"] = {
		link = true,
		generic_before_non_cities = "in",
		has_neighborhoods = true,
		class = "settlement",
		cat_handler = city_type_cat_handler,
		default = {true},
	},
	["city-state"] = {
		link = true,
		category_link = "[[sovereign]] [[microstate]]s consisting of a single [[city]] and [[w:dependent territory|dependent territories]]",
		has_neighborhoods = true,
		class = "settlement",
		["continent/*"] = {"City-states", "Cities in +++", "Countries in +++", "National capitals"},
		default = {"City-states", "Cities", "Countries", "National capitals"},
	},
	["civil parish"] = {
		-- Mostly England; similar to municipalities
		link = true,
		preposition = "of",
		affix_type = "suf",
		has_neighborhoods = true,
		class = "subpolity",
	},
	["claimed political division"] = {
		link = "[[claim]]ed [[political]] [[division]]",
		class = "subpolity",
		default = {true},
	},
	["co-capital"] = {
		link = "[[co-]][[capital]]",
		fallback = "capital city",
	},
	["coal city"] = {
		link = "+w:coal town",
		fallback = "city",
	},
	["coal town"] = {
		link = "w",
		fallback = "town",
	},
	["collectivity"] = {
		link = "w",
		preposition = "of",
		-- No default; these are weird one-off governmental divisions in France (esp. for overseas collectivities)
		class = "subpolity",
	},
	["colony"] = {
		link = true,
		fallback = "dependent territory",
	},
	["comarca"] = {
		-- per Wikipedia: traditional region or local administrative division found in Portugal, Spain, and some of
		-- their former colonies, like Brazil, Nicaragua, and Panama. In the Valencian Community, for example, it
		-- sits between municipalities and provinces, something like a county or district.
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["commandery"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["commonwealth"] = {
		link = true,
		preposition = "of",
		-- No default; applies specifically to Puerto Rico
		class = "subpolity",
	},
	["commune"] = {
		link = true,
		fallback = "municipality",
	},
	["community"] = {
		link = true,
		category_link = "[[community|communities]] of all sizes",
		fallback = "village",
	},
	["community development block"] = {
		-- in India; appears to be similar to a rural municipality; groups several villages, unclear if there will be
		-- neighborhoods so I'm not setting `has_neighborhoods` for now
		link = "w",
		affix_type = "suf",
		no_affix_strings = "block",
		class = "subpolity",
	},
	["comune"] = {
		-- Italy, Switzerland
		link = true,
		fallback = "municipality",
	},
	["condominium"] = {
		link = true,
		fallback = "polity",
	},
	["confederacy"] = {
		link = true,
		fallback = "confederation",
	},
	["confederation"] = {
		link = true,
		fallback = "polity",
	},
	["constituency"] = {
		-- currently we have them as political divisions of Namibia but many countries have them
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["constituent country"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["constituent part"] = {
		link = "separately",
		preposition = "of",
		class = "subpolity",
	},
	["constituent republic"] = {
		link = "w",
		fallback = "constituent country",
	},
	["counties and county-level cities!"] = {
		-- This is used when grouping counties and county-level cities under prefecture-level cities in China.
		category_link = "[[county|counties]] and [[county-level city|county-level cities]]",
		class = "subpolity",
	},
	["continent"] = {
		link = true,
		category_link = false, -- can't occur as a bare category
		class = "natural feature",
		default = {"Continents and continental regions"},
	},
	["continental region"] = {
		link = "separately",
		category_link = false, -- can't occur as a bare category
		class = "geographic region",
		fallback = "continent",
	},
	["continents and continental regions!"] = {
		category_link = "[[continent]]s and [[continent]]-[[level]] [[region]]s (e.g. [[Polynesia]])",
		class = "geographic region",
	},
	["council area"] = {
		link = true,
		-- in Scotland; similar to a county
		preposition = "of",
		affix_type = "suf",
		class = "subpolity",
	},
	["country"] = {
		link = true,
		class = "polity",
		["continent/*"] = {true, "Countries"},
		default = {true},
	},
	["country-like entities!"] = {
		category_link = "[[polity|polities]] not normally considered [[country|countries]] but treated similarly for categorization purposes; typically, [[unrecognized]] [[de-facto]] countries or [[w:dependent territory|dependent territories]]",
		class = "polity",
	},
	["county"] = {
		link = true,
		preposition = "of",
		display_handler = county_display_handler,
		class = "subpolity",
	},
	["county borough"] = {
		link = true,
		-- in Wales; similar to a county
		preposition = "of",
		affix_type = "suf",
		fallback = "borough",
		class = "subpolity",
	},
	["county seat"] = {
		link = true,
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
	},
	["county town"] = {
		link = true,
		entry_placetype_use_the = true,
		preposition = "of",
		fallback = "town",
		has_neighborhoods = true,
		class = "capital",
	},
	["county-administered city"] = {
		-- In Taiwan, per Wikipedia similar to a Taiwanese township or district, which is a small city.
		-- NOT anything like a "county-level city" in PR China, which is a county masquerading as a city.
		link = "w",
		fallback = "city",
		has_neighborhoods = true,
		class = "settlement",
	},
	["county-controlled city"] = {
		-- Taiwan
		link = "w",
		fallback = "county-administered city",
	},
	["county-level city"] = {
		-- PR China
		link = "w",
		fallback = "prefecture-level city",
	},
	["crater lake"] = {
		link = true,
		fallback = "lake",
	},
	["Crown colony"] = {
		link = "+crown colony",
		fallback = "crown colony",
	},
	["crown colony"] = {
		link = true,
		fallback = "colony",
	},
	["Crown dependency"] = {
		link = true,
		fallback = "dependent territory",
	},
	["crown dependency"] = {
		link = true,
		fallback = "dependent territory",
	},
	["cultural area"] = {
		link = "w",
		fallback = "geographic and cultural area",
	},
	["cultural region"] = {
		link = "w",
		fallback = "geographic and cultural area",
	},
	["delegation"] = {
		-- Tunisia
		link = "+w:delegations of Tunisia",
		preposition = "of",
		class = "subpolity",
	},
	["department"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		class = "subpolity",
	},
	["departmental capital"] = {
		link = "separately",
		fallback = "capital city",
	},
	["dependency"] = {
		link = true,
		fallback = "dependent territory",
	},
	["dependent territory"] = {
		link = "w",
		preposition = "of",
		former_type = "dependent territory",
		bare_category_parent = "political divisions",
		["country/*"] = {true},
		default = {true},
	},
	["desert"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"ecosystems"},
		default = {true},
	},
	["deserted mediaeval village"] = {
		link = "w",
		fallback = "deserted medieval village",
	},
	["deserted medieval village"] = {
		link = "w",
		fallback = "ANCIENT settlement",
	},
	["direct-administered municipality"] = {
		-- China
		link = "+w:direct-administered municipalities of China",
		fallback = "municipality",
	},
	["direct-controlled municipality"] = {
		-- several countries
		link = "w",
		fallback = "municipality",
	},
	["distributary"] = {
		link = true,
		preposition = "of",
		fallback = "river",
	},
	["district"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		-- Grrr! FIXME! Here is where we need handlers for former_type. Using similar logic to
		-- district_neighborhood_cat_handler, we need to check if we're below or above a city to determine if the former
		-- type is "settlement" or "subpolity".
		class = "subpolity",
		cat_handler = district_neighborhood_cat_handler,

		-- No default. Countries for which districts are political divisions will get entries.
	},
	["districts and autonomous regions!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case Portugal.
		category_link = "[[district]]s and [[autonomous region]]s",
		class = "subpolity",
	},
	["districts and autonomous territorial units!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case Moldova.
		category_link = "[[district]]s and [[w:autonomous territorial unit|autonomous territorial unit]]s",
		class = "subpolity",
	},
	["district capital"] = {
		link = "separately",
		fallback = "capital city",
	},
	["district headquarters"] = {
		link = "separately",
		fallback = "administrative centre",
	},
	["district municipality"] = {
		-- In Canada, a district municipality is equivalent to a rural municipality and won't have neighborhoods; in
		-- South Africa, district municipalities group local municipalities and hence won't have neighborhoods.
		link = "w",
		preposition = "of",
		affix_type = "suf",
		no_affix_strings = {"district", "municipality"},
		fallback = "municipality",
		class = "subpolity",
	},
	["division"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["division capital"] = {
		link = "separately",
		fallback = "capital city",
	},
	["dome"] = {
		link = true,
		fallback = "mountain",
	},
	["dormant volcano"] = {
		link = true,
		fallback = "volcano",
	},
	["duchy"] = {
		link = true,
		fallback = "polity",
	},
	["emirate"] = {
		link = true,
		preposition = "of",
		-- FIXME: Can be subpolities (of the United Arab Emirates).
		fallback = "polity",
	},
	["empire"] = {
		link = true,
		fallback = "polity",
	},
	["enclave"] = {
		link = true,
		preposition = "of",
		-- Enclaves can theoretically be any size but assume a subpolity.
		class = "subpolity",
	},
	["entity"] = {
		-- Bosnia and Herzegovina
		link = "+w:entities of Bosnia and Herzegovina",
		preposition = "of",
		class = "subpolity",
	},
	["escarpment"] = {
		link = true,
		fallback = "mountain",
	},
	["ethnographic region"] = {
		-- used in Lithuania
		link = "+w:ethnographic regions of Lithuania",
		fallback = "geographic and cultural area",
	},
	["exclave"] = {
		link = true,
		preposition = "of",
		-- exclaves can theoretically be any size but assume a subpolity.
		class = "subpolity",
	},
	["external territory"] = {
		link = "separately",
		fallback = "dependent territory",
	},
	["farm"] = {
		link = true,
		class = "non-admin settlement",
		default = {"Farms and ranches"},
	},
	["farms and ranches!"] = {
		category_link = "[[farm]]s and [[ranch]]es",
		class = "non-admin settlement",
	},
	["federal city"] = {
		link = "w",
		preposition = "of",
		fallback = "city",
	},
	["federal district"] = {
		link = true,
		preposition = "of",
		-- Might have neighborhoods as federal districts are often cities (e.g. Mexico City)
		has_neighborhoods = true,
		class = "settlement",
	},
	["federal subject"] = {
		-- In Russia; a generic term for first-level administrative divisions (republics, oblasts, okrugs, krais,
		-- autonomous okrugs and autonomous oblasts).
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["federal territory"] = {
		link = "w",
		fallback = "territory",
	},
	["fictional location"] = {
		link = "separately",
		former_type = "!",
		bare_category_parent = "places",
		default = {true},
	},
	["First Nations reserve"] = {
		-- Canada
		link = "[[First Nations]] [[w:Indian reserve|reserve]]",
		-- Wikipedia uses "Indian reserve"; presumably that is the legal term
		fallback = "Indian reserve",
		class = "subpolity",
	},
	["fjord"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["forest"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"ecosystems", "forestry"},
		default = {true},
	},
	["FORMER capital"] = {
		link = false,
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
		default = {"Former capitals"},
	},
	["former capitals!"] = {
		category_link = "former [[capital]] [[city|cities]] and [[town]]s",
		bare_category_parent = "settlements",
	},
	["former countries and country-like entities!"] = {
		category_link = "[[country|countries]] and similar [[polity|polities]] that no longer exist",
		bare_category_parent = "former polities",
	},
	["former dependent territories!"] = {
		category_link = "[[w:dependent territory|dependent territories]] (colonies, dependencies, protectorates, etc.) that no longer exist",
		bare_category_parent = "former political divisions",
	},
	["FORMER dependent territory"] = {
		link = false,
		preposition = "of",
		class = "subpolity",
		default = {"Former dependent territories"},
	},
	["FORMER geographic region"] = {
		link = false,
		fallback = "geographic and cultural area",
	},
	["FORMER man-made structure"] = {
		link = false,
		class = "man-made structure",
		default = {"Former man-made structures"},
	},
	["former man-made structures!"] = {
		category_link = "man-made structures such as [[airport]]s and [[park]]s that no longer exist",
		bare_category_parent = "former places",
	},
	["former municipalities!"] = {
		-- For categorizing former municipalities of the Netherlands
		category_link = "no-longer-existing [[municipality|municipalities]]",
		bare_category_parent = "former political divisions",
	},
	["FORMER municipality"] = {
		-- For categorizing former municipalities of the Netherlands
		link = false,
		fallback = "FORMER subpolity",
	},
	["FORMER natural feature"] = {
		link = false,
		class = "natural feature",
		default = {"Former natural features"},
	},
	["former natural features!"] = {
		category_link = "natural features such as [[lake]]s, [[river]]s and [[island]]s that no longer exist",
		bare_category_parent = "former places",
	},
	["FORMER non-admin settlement"] = {
		link = false,
		class = "non-admin settlement",
		fallback = "FORMER settlement",
	},
	["former places!"] = {
		category_link = "[[place]]s of all sorts that no longer exist",
		bare_category_parent = "places",
	},
	["former political divisions!"] = {
		category_link = "[[political]] [[division]]s (states, provinces, counties, etc.) that no longer exist",
		bare_category_parent = "former places",
	},
	["former polities!"] = {
		category_link = "[[polity|polities]] (countries, kingdoms, empires, etc.) that no longer exist",
		bare_category_parent = "former places",
	},
	["FORMER polity"] = {
		link = false,
		class = "polity",
		default = {"Former polities"},
	},
	["FORMER province"] = {
		-- For categorizing ancient/historical/former provinces of the Roman Empire
		link = false,
		fallback = "FORMER subpolity",
	},
	["former region"] = {
		-- A former region is considered a former political division, but not a 'historical/traditional/etc.' region.
		link = "separately",
		preposition = "of",
		inherently_former = {"FORMER"},
		class = "subpolity",
	},
	["FORMER settlement"] = {
		link = false,
		has_neighborhoods = true,
		class = "settlement",
		default = {"Former settlements"},
	},
	["former settlements!"] = {
		category_link = "[[city|cities]], [[town]]s and [[village]]s that no longer exist or have been merged or reclassified",
		bare_category_parent = "former political divisions",
	},
	["FORMER subpolity"] = {
		link = false,
		preposition = "of",
		class = "subpolity",
		default = {"Former political divisions"},
	},

	------------- Categories for former names

	["former names of capitals!"] = {
		category_link = "[[former]] [[name]]s of [[capital city|capital cities]] that generally still exist but under a different name",
		bare_category_breadcrumb = "capitals",
		bare_category_parent = "former names of settlements",
	},
	["former names of countries!"] = {
		category_link = "[[former]] [[name]]s of [[country|countries]] that generally still exist but under a different name",
		bare_category_breadcrumb = "countries",
		bare_category_parent = "former names of places",
	},
	["former names of places!"] = {
		category_link = "[[former]] [[name]]s of [[place]]s that generally still exist but under a different name",
		bare_category_breadcrumb = "former names",
		bare_category_parent = "places",
	},
	["former names of political divisions!"] = {
		category_link = "[[former]] [[name]]s of [[political]] [[division]]s (states, provinces, counties, etc.) that generally still exist but under a different name",
		bare_category_breadcrumb = "political divisions",
		bare_category_parent = "former names of places",
	},
	["former names of polities!"] = {
		category_link = "[[former]] [[name]]s of [[polity|polities]] (e.g. [[country|countries]]) that generally still exist but under a different name",
		bare_category_breadcrumb = "polities",
		bare_category_parent = "former names of places",
	},
	["former names of settlements!"] = {
		category_link = "[[former]] [[name]]s of [[city|cities]], [[town]]s, [[village]]s, etc. that generally still exist but under a different name",
		bare_category_breadcrumb = "settlements",
		bare_category_parent = "former names of political divisions",
	},
	["FORMER_NAME_OF capital"] = {
		link = false,
		default = {"Former names of capitals"},
	},
	["FORMER_NAME_OF country"] = {
		link = false,
		default = {"Former names of countries"},
	},
	["FORMER_NAME_OF place"] = {
		link = false,
		default = {"Former names of places"},
	},
	["FORMER_NAME_OF polity"] = {
		link = false,
		default = {"Former names of polities"},
	},
	["FORMER_NAME_OF region"] = {
		link = false,
		fallback = "FORMER_NAME_OF subpolity",
	},
	["FORMER_NAME_OF settlement"] = {
		link = false,
		default = {"Former names of settlements"},
	},
	["FORMER_NAME_OF subpolity"] = {
		link = false,
		default = {"Former names of political divisions"},
	},
	["fort"] = {
		link = true,
		fallback = "building",
	},
	["fortress"] = {
		link = true,
		-- The default plural algorithm gets this right but the singularization algorithm incorrectly converts
		-- fortresses -> fortresse, so put an entry here to ensure we singularize correctly.
		plural = "fortresses",
		fallback = "building",
	},
	["frazione"] = {
		link = "w",
		fallback = "hamlet",
	},
	["French prefecture"] = {
		link = "[[w:prefectures in France|prefecture]]",
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
	},
	["geographic and cultural area"] = {
		link = "+w:cultural area",
		-- `generic_before_non_cities` is used when generating the category description of categories of the format
		-- `Geographic and cultural areas of PLACE`. `preposition` is used when generating {{place}} description and
		-- categories for any placetype that falls back to `geographic and cultural area`.
		generic_before_non_cities = "of",
		preposition = "of",
		class = "geographic region",
		bare_category_parent = "places",
		["country/*"] = {true},
		["constituent country/*"] = {true},
		["continent/*"] = {true},
		default = {true},
	},
	["geographic area"] = {
		link = "+w:geographic region",
		fallback = "geographic and cultural area",
	},
	["geographic region"] = {
		link = "w",
		fallback = "geographic and cultural area",
	},
	["geographical area"] = {
		link = "w",
		fallback = "geographic and cultural area",
	},
	["geographical region"] = {
		link = "w",
		fallback = "geographic and cultural area",
	},
	["geopolitical zone"] = {
		-- Nigeria
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["gewog"] = {
		-- Bhutan
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["ghost town"] = {
		link = true,
		generic_before_non_cities = "in",
		class = "non-admin settlement",
		bare_category_parent = "former settlements",
		cat_handler = city_type_cat_handler,
		default = {true},
	},
	["glen"] = {
		link = true,
		fallback = "valley",
	},
	["governorate"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		class = "subpolity",
	},
	["greater administrative region"] = {
		-- China (former division)
		link = "w",
		preposition = "of",
		class = "subpolity",
		inherently_former = {"FORMER"},
	},
	["gromada"] = {
		-- Poland (former division)
		link = "w",
		preposition = "of",
		affix_type = "Pref",
		class = "subpolity",
		inherently_former = {"FORMER"},
	},
	["group of islands"] = {
		link = "[[group]] of [[island]]s",
		plural = "groups of islands",
		plural_link = "[[group]]s of [[island]]s",
		fallback = "island group",
	},
	["gulf"] = {
		link = true,
		preposition = "of",
		holonym_use_the = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["hamlet"] = {
		link = true,
		fallback = "village",
	},
	["harbor city"] = {
		link = "separately",
		fallback = "city",
	},
	["harbor town"] = {
		link = "separately",
		fallback = "town",
	},
	["harbour city"] = {
		link = "separately",
		fallback = "city",
	},
	["harbour town"] = {
		link = "separately",
		fallback = "town",
	},
	["headland"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
	},
	["headquarters"] = {
		link = "w",
		fallback = "administrative centre",
	},
	["heath"] = {
		link = true,
		fallback = "moor",
	},
	["hemisphere"] = {
		link = true,
		entry_placetype_use_the = true,
		fallback = "continental region",
	},
	["hill"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
	},
	["hill station"] = {
		link = "w",
		fallback = "town",
	},
	["hill town"] = {
		link = "w",
		fallback = "town",
	},
	["historic region"] = {
		-- provided only for the link
		link = "+w:historical region",
		fallback = "FORMER geographic region",
	},
	["historical county"] = {
		-- needed for historical counties of England/etc.
		link = "+w:historic county",
		fallback = "FORMER subpolity",
	},
	["historical region"] = {
		-- provided only for the link
		link = "w",
		fallback = "FORMER geographic region",
	},
	["home rule city"] = {
		link = "w",
		fallback = "city",
	},
	["home rule municipality"] = {
		link = "w",
		fallback = "municipality",
	},
	["hot spring"] = {
		link = true,
		fallback = "spring",
	},
	["house"] = {
		link = true,
		fallback = "building",
	},
	["housing estate"] = {
		-- not the same as a housing project (i.e. public housing)
		link = true,
		-- not exactly the case but approximately
		fallback = "neighborhood",
	},
	["hromada"] = {
		-- Ukraine
		link = "w",
		preposition = "of",
		affix_type = "Suf",
		class = "subpolity",
	},
	["inactive volcano"] = {
		link = "w",
		fallback = "dormant volcano",
	},
	["independent city"] = {
		link = true,
		fallback = "city",
	},
	["independent town"] = {
		link = "+independent city",
		fallback = "town",
	},
	["Indian reservation"] = {
		link = "w",
		-- In the US. Also known as "Native American reservation" or "domestic dependent nation", and the reservations
		-- themselves often use the term "nation" in their official name (e.g. the "Navajo Nation"). But Wikipedia puts
		-- the article at [[w:Indian reservation]] and uses that term when describing e.g. what the Navajo Nation is,
		-- so this must still be the legal term.
		preposition = "of",
		class = "subpolity",
		default = {true},
	},
	["Indian reserve"] = {
		link = "w",
		-- In Canada. "First Nations reserve" sounds more modern/PC but Wikipedia uses "Indian reserve"; presumably that
		-- is still the legal term.
		preposition = "of",
		class = "subpolity",
		default = {true},
	},
	["individual buildings!"] = {
		category_link = "[[house]]s, [[library|libraries]] and other notable [[building]]s",
		bare_category_parent = "man-made structures",
	},
	["inland sea"] = {
		-- note, we also have 'inland' as a qualifier
		link = true,
		fallback = "sea",
	},
	["inner city area"] = {
		link = "[[inner city]] [[area]]",
		fallback = "neighborhood",
	},
	["island"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
	},
	["island country"] = {
		-- FIXME: The following should map to both 'island' and 'country'.
		link = "w",
		fallback = "country",
	},
	["island group"] = {
		link = "separately",
		fallback = "island",
	},
	["island municipality"] = {
		link = "w",
		fallback = "municipality",
	},
	["islet"] = {
		link = "w",
		fallback = "island",
	},
	["Israeli settlement"] = {
		link = "w",
		class = "settlement",
		default = {true},
	},
	["judicial capital"] = {
		link = "w",
		fallback = "capital city",
	},
	["khanate"] = {
		link = true,
		fallback = "polity",
	},
	["kibbutz"] = {
		link = true,
		plural = "kibbutzim",
		class = "non-admin settlement",
		default = {true},
	},
	["kingdom"] = {
		link = true,
		fallback = "polity",
	},
	["krai"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		class = "subpolity",
	},
	["lake"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["landforms!"] = {
		category_link = "[[landform]]s",
		bare_category_parent = "places",
		addl_bare_category_parents = {"Earth"},
	},
	["largest city"] = {
		link = "[[large]]st [[city]]",
		entry_placetype_use_the = true,
		fallback = "city",
		has_neighborhoods = true,
	},
	["league"] = {
		link = true,
		fallback = "confederation",
	},
	["legislative capital"] = {
		link = "separately",
		fallback = "capital city",
	},
	["library"] = {
		link = true,
		fallback = "building",
	},
	["lieutenancy area"] = {
		-- used in the United Kingdom; per Wikipedia:
		-- In England, lieutenancy areas are colloquially known as the ceremonial counties, although this phrase does
		-- not appear in any legislation referring to them. The lieutenancy areas of Scotland are subdivisions of
		-- Scotland that are more or less based on the counties of Scotland, making use of the major cities as separate
		-- entities.[2] In Wales, the lieutenancy areas are known as the preserved counties of Wales and are based on
		-- those used for lieutenancy and local government between 1974 and 1996. The lieutenancy areas of Northern
		-- Ireland correspond to the six counties and two former county boroughs.[3]
		link = "w",
		fallback = "ceremonial county",
	},
	["local authority district"] = {
		link = "w",
		fallback = "local government district",
	},
	["local government area"] = {
		-- Australia
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["local council"] = {
		-- Malta; similar to municipalities
		link = "+w:local councils of Malta",
		preposition = "of",
		fallback = "municipality",
	},
	["local government district"] = {
		link = "w",
		preposition = "of",
		affix_type = "suf",
		affix = "district",
		class = "subpolity",
	},
	["local government district with borough status"] = {
		link = "[[w:local government district|local government district]] with [[w:borough status|borough status]]",
		plural = "local government districts with borough status",
		plural_link = "[[w:local government district|local government districts]] with [[w:borough status|borough status]]",
		preposition = "of",
		affix_type = "suf",
		affix = "district",
		class = "subpolity",
	},
	["local urban district"] = {
		link = "w",
		fallback = "unincorporated community",
	},
	["locality"] = {
		link = "+w:locality (settlement)",
		-- not necessarily true, but usually is the case
		fallback = "village",
	},
	["London borough"] = {
		link = "w",
		preposition = "of",
		affix_type = "pref",
		affix = "borough",
		fallback = "local government district with borough status",
		has_neighborhoods = true,
	},
	["macroregion"] = {
		link = true,
		fallback = "region",
	},
	["man-made structures!"] = {
		category_link = "[[w:geographical feature#Engineered constructs|man-made structures]] such as [[airport]]s, [[university|universities]] and [[metro station]]s",
		bare_category_parent = "places",
	},
	["marginal sea"] = {
		link = true,
		preposition = "of",
		fallback = "sea",
	},
	["market city"] = {
		link = "+market town",
		fallback = "city",
	},
	["market town"] = {
		link = true,
		fallback = "town",
	},
	["massif"] = {
		link = true,
		fallback = "mountain",
	},
	["megacity"] = {
		link = true,
		fallback = "city",
	},
	["metro station"] = {
		link = true,
		class = "man-made structure",
	},
	["metropolitan borough"] = {
		link = true,
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"borough", "city"},
		fallback = "local government district",
		has_neighborhoods = true,
	},
	["metropolitan city"] = {
		-- These exist e.g. in Italy and are more like municipalities or even provinces than cities.
		link = true,
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"metropolitan", "city"},
		class = "subpolity",
	},
	["metropolitan county"] = {
		link = true,
		fallback = "county",
	},
	["metropolitan municipality"] = {
		-- In South Africa, metropolitan municipalities group local municipalities and are like districts, between
		-- provinces and municipalities.
		-- In Turkey, metropolitan municipalities are provinces-level.
		link = "w",
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = {"metropolitan", "municipality"},
		fallback = "municipality",
		class = "subpolity",
	},
	["microdistrict"] = {
		-- residential complex in post-Soviet states
		link = true,
		fallback = "neighborhood",
	},
	["micronations!"] = {
		-- FIXME, merge with microstate
		category_link = "[[micronation]]s",
		bare_category_parent = "countries",
	},
	["microstate"] = {
		link = true,
		fallback = "country",
	},
	["military base"] = {
		link = "w",
		class = "settlement", -- or "man-made structure"?
		default = {true},
	},
	["minster town"] = {
		-- England
		link = "separately",
		fallback = "town",
	},
	["moor"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms", "ecosystems"},
		default = {true},
	},
	["moorland"] = {
		link = true,
		fallback = "moor",
	},
	["mountain"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
	},
	["mountain indigenous district"] = {
		-- Taiwan
		link = "+w:district (Taiwan)",
		fallback = "district",
	},
	["mountain indigenous township"] = {
		-- Taiwan
		link = "+w:township (Taiwan)",
		fallback = "township",
	},
	["mountain pass"] = {
		link = true,
		-- The default plural algorithm gets this right but the singularization algorithm incorrectly converts
		-- passes -> passe, so put an entry here to ensure we singularize correctly.
		plural = "mountain passes",
		class = "natural feature",
		addl_bare_category_parents = {"mountains"},
		default = {true},
	},
	["mountain range"] = {
		link = true,
		fallback = "mountain",
	},
	["mountainous region"] = {
		link = "separately",
		fallback = "region",
	},
	["mukim"] = {
		-- Malaysia, Brunei, Indonesia, Singapore
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["municipal district"] = {
		link = "w",
		-- meaning varies depending on the country; for now, assume no neighborhoods.
		-- FIXME: has_neighborhoods might have to be a function that looks at the containing holonyms.
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "district",
		fallback = "municipality",
	},
	["municipality"] = {
		link = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "subpolity",
	},
	["municipality with city status"] = {
		link = "[[municipality]] with [[w:city status|city status]]",
		plural = "municipalities with city status",
		plural_link = "[[municipality|municipalities]] with [[w:city status|city status]]",
		fallback = "municipality",
	},
	["mythological location"] = {
		link = "separately",
		former_type = "!",
		bare_category_parent = "places",
		default = {true},
	},
	["national capital"] = {
		link = "w",
		fallback = "capital city",
	},
	["national park"] = {
		link = true,
		fallback = "park",
	},
	["natural features!"] = {
		category_link = "[[w:geographical feature#Natural features|natural features]] such as [[lake]]s, [[mountain]]s, [[island]]s and [[ocean]]s",
		bare_category_parent = "places",
	},
	["neighborhood"] = {
		-- The majority of the properties here apply to both `neighborhoods` and `neighbourhoods`; the choice of which
		-- one to use is made by district_neighborhood_cat_handler() based on the value of `british_spelling` for the
		-- location (city, political division, etc.) of the holonym that follows the word "neighbo(u)hoods" in the
		-- category name. It does *NOT* depend on whether the {{place}} call uses "neighborhoods" or "neighbourhoods".
		-- (In general it can't, because other things like "urban areas", "districts", "subdivisions" and the like also
		-- categorize as neighbo(u)rhoods.)
		link = true,
		-- See below. These are used by category handlers in [[Module:category tree/topic cat/data/Places]].
		generic_before_non_cities = "in",
		generic_before_cities = "of",
		-- The following text is suitable for the top-level description of a neighborhood as well as categories of the
		-- form `Neighborhoods in POLDIV` e.g. `Neighborhoods in Illinois, USA` but not for categories of the form
		-- `Neighborhoods of Chicago`, where we'd get "... and other subportions of [[city|cities]] of [[Chicago]]".
		category_link = "[[neighborhood]]s, [[district]]s and other subportions of [[city|cities]]",
		category_link_before_city = "[[neighborhood]]s, [[district]]s and other subportions",
		-- NOTE: This setting is needed for administrative divisions like barangays that fall back to `neighborhood`,
		-- when set in [[Module:place/locations]] for a specific country (e.g. the Philippines). The above settings
		-- for `generic_before_non_cities` and `generic_before_cities` are used by category handlers in
		-- [[Module:category tree/topic cat/data/Places]] for `Neighborhoods in POLDIV` and `Neighborhoods of CITY`
		-- categories. In fact, district_neighborhood_cat_handler() does not currently pay attention to them, but
		-- generates "of" before cities and "in" before non-cities regardless. (FIXME: We should change that.)
		preposition = "of",
		class = "non-admin settlement",
		cat_handler = district_neighborhood_cat_handler,
	},
	["neighbourhood"] = {
		link = true,
		category_link = "[[neighbourhood]]s, [[district]]s and other subportions of [[city|cities]]",
		category_link_before_city = "[[neighbourhood]]s, [[district]]s and other subportions",
		fallback = "neighborhood",
	},
	["new area"] = {
		-- China (type of economic development zone, varying greatly in size)
		link = "w",
		preposition = "in",
		class = "subpolity", --?
	},
	["new town"] = {
		link = true,
		fallback = "town",
	},
	["non-city capital"] = {
		link = "[[capital]]",
		entry_placetype_use_the = true,
		preposition = "of",
		has_neighborhoods = true,
		class = "capital",
		cat_handler = function(data)
			return capital_city_cat_handler(data, "non-city")
		end,
		-- FIXME, do we need the following?
		default = {true},
	},
	["non-metropolitan county"] = {
		link = "w",
		fallback = "county",
	},
	["non-metropolitan district"] = {
		link = "w",
		fallback = "local government district",
	},
	["non-sovereign kingdom"] = {
		-- especially in Africa and Asia
		link = "+w:non-sovereign monarchy",
		generic_before_non_cities = "in",
		class = "subpolity",
		["country/*"] = {true},
		["continent/*"] = {true},
		default = {true},
	},
	["non-sovereign monarchy"] = {
		link = "w",
		fallback = "non-sovereign kingdom",
	},
	["oblast"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		class = "subpolity",
	},
	["ocean"] = {
		link = true,
		holonym_use_the = true,
		class = "natural feature",
		addl_bare_category_parents = {"seas", "bodies of water"},
		default = {true},
	},
	["okrug"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		class = "subpolity",
	},
	["overseas collectivity"] = {
		link = "w",
		fallback = "collectivity",
	},
	["overseas department"] = {
		link = "w",
		fallback = "department",
	},
	["overseas territory"] = {
		link = "w",
		fallback = "dependent territory",
	},
	["parish"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		class = "subpolity",
	},
	["parish municipality"] = {
		-- in Quebec, often similar to a rural village; the famous [[Saint-Louis-du-Ha! Ha!]] is one of them.
		link = "+w:parish municipality (Quebec)",
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true,
	},
	["parish seat"] = {
		link = true,
		entry_placetype_use_the = true,
		preposition = "of",
		class = "capital",
		has_neighborhoods = true,
	},
	["park"] = {
		link = true,
		class = "man-made structure",
		default = {true},
	},
	["pass"] = {
		link = "+mountain pass",
		-- The default plural algorithm gets this right but the singularization algorithm incorrectly converts
		-- passes -> passe, so put an entry here to ensure we singularize correctly.
		plural = "passes",
		fallback = "mountain pass",
	},
	["peak"] = {
		link = true,
		fallback = "mountain",
	},
	["peninsula"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
	},
	["periphery"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["places!"] = {
		generic_before_non_cities = "in",
		generic_before_cities = "in",
		class = "generic place",
		category_link = "[[place]]s of all sorts",
		-- `category_link_top_level` control the description used in the top-level [[Category:Places]] and
		-- language-specific variants such as [[Category:en:Places]]. The actual text for a language-spefic variant is
		-- "{{{langname}}} names of [[geographical]] [[place]]s of all sorts; [[toponym]]s." where the "names of"
		-- portion is automatically generated by the appropriate handler in
		-- [[Module:category tree/topic cat/data/Places]].
		category_link_top_level = "[[geographical]] [[place]]s of all sorts; [[toponym]]s",
		bare_category_parent = "names",
	},
	["planned community"] = {
		-- Include this so we don't categorize 'planned community' into villages, as 'community' does.
		link = true,
		class = "settlement",
		has_neighborhoods = true,
	},
	["plateau"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true},
		-- FIXME: Should generate both "Plateaus" and the appropriate 'geographic and cultural area' category
	},
	["Polish colony"] = {
		link = "+w:colony (Poland)",
		affix_type = "suf",
		affix = "colony",
		fallback = "village",
		has_neighborhoods = true,
	},
	["political divisions!"] = {
		category_link = "[[political]] [[division]]s and [[subdivision]]s, such as [[state]]s, [[province]]s, [[county|counties]] or [[district]]s",
		bare_category_parent = "places",
	},
	["polity"] = {
		link = true,
		category_link = "[[independent]] or [[semi-]][[independent]] [[polity|polities]]",
		class = "polity",
		bare_category_parent = "places",
		default = {true},
	},
	["populated place"] = {
		link = "+w:populated place",
		-- not necessarily true, but usually is the case
		fallback = "village",
	},
	["port"] = {
		link = true,
		class = "man-made structure",
		default = {true},
	},
	["port city"] = {
		-- FIXME: should categorize into "Ports" as well as "Cities"
		link = true,
		fallback = "city",
	},
	["port town"] = {
		-- FIXME: should categorize into "Ports" as well as "Towns"
		link = "w",
		fallback = "town",
	},
	["prefecture"] = {
		-- FIXME! `prefecture` is like a county in Japan and elsewhere but a department capital city in France.
		-- May need `has_neighborhoods` to be a function.
		link = true,
		preposition = "of",
		display_handler = prefecture_display_handler,
		class = "subpolity",
	},
	["prefecture-level city"] = {
		-- China; they are huge entities with a central city; not cities themselves.
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["promontory"] = {
		link = true,
		fallback = "headland",
	},
	["protectorate"] = {
		link = true,
		fallback = "dependent territory",
	},
	["province"] = {
		link = true,
		preposition = "of",
		display_handler = province_display_handler,
		class = "subpolity",
	},
	["provinces and autonomous regions!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case China.
		category_link = "[[province]]s and [[autonomous region]]s",
		class = "subpolity",
	},
	["provinces and territories!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case Canada and Pakistan.
		category_link = "[[province]]s and [[territory|territories]]",
		class = "subpolity",
	},
	["provincial capital"] = {
		link = true,
		fallback = "capital city",
	},
	["raion"] = {
		link = true,
		preposition = "of",
		affix_type = "Suf",
		class = "subpolity",
	},
	["ranch"] = {
		link = true,
		fallback = "farm",
	},
	["range"] = {
		-- FIXME: Where is this used? Is it a mountain range?
		link = true,
		holonym_use_the = true,
		class = "natural feature",
	},
	["regency"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["region"] = {
		link = true,
		preposition = "of",
		-- If 'region' isn't a specific administrative division, fall back to 'geographic and cultural area'
		fallback = "geographic and cultural area",
		-- "former region" is a subpolity but traditional/historic(al)/ancient/medieval/etc. is a geographic region
		class = "geographic region",
	},
	["regional capital"] = {
		link = "separately",
		fallback = "capital city",
	},
	["regional county municipality"] = {
		-- Quebec
		link = "w",
		preposition = "of",
		affix_type = "Suf",
		no_affix_strings = {"municipality", "county"},
		fallback = "municipality",
	},
	["regional district"] = {
		link = "w",
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "district",
		fallback = "district",
	},
	["regional municipality"] = {
		link = "w",
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "municipality",
		fallback = "municipality",
	},
	["regional unit"] = {
		link = "w",
		preposition = "of",
		class = "subpolity",
	},
	["registration county"] = {
		-- Used in Scotland for land registration purposes; formerly used in England, Wales and Ireland for statistical
		-- purposes (registration of births, deaths and marriages, and for the output of census information).
		link = "w",
		fallback = "county",
	},
	["republic"] = {
		-- Of Russia. "Republics" in general are sovereign but we use "country" in that case.
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["research base"] = {
		link = "+w:research station",
		fallback = "research station",
	},
	["research station"] = {
		link = "w",
		class = "non-admin settlement", -- or "man-made structure"?
		default = {true},
	},
	["reservoir"] = {
		link = true,
		fallback = "lake",
	},
	["residential area"] = {
		link = "separately",
		fallback = "neighborhood",
	},
	["resort city"] = {
		link = "w",
		fallback = "city",
	},
	["resort town"] = {
		link = "w",
		fallback = "town",
	},
	["river"] = {
		link = true,
		generic_before_non_cities = "in",
		holonym_use_the = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		cat_handler = city_type_cat_handler,
		["continent/*"] = {true},
		default = {true},
	},
	["Roman province"] = {
		-- FIXME! Eliminate this in favor of 'former province|emp/Roman Empire'
		link = "w",
		default = {"Provinces of the Roman Empire"},
		class = "subpolity",
	},
	["royal borough"] = {
		link = "w",
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = {"royal", "borough"},
		fallback = "local government district with borough status",
		has_neighborhoods = true,
	},
	["royal burgh"] = {
		link = true,
		fallback = "borough",
	},
	["royal capital"] = {
		link = "w",
		fallback = "capital city",
	},
	["rural committee"] = {
		-- Hong Kong; a group of villages
		link = "w",
		affix_type = "Suf",
		has_neighborhoods = true,
		class = "settlement",
	},
	["rural community"] = {
		-- New Brunswick
		link = "+w:list of municipalities in New_Brunswick#Rural communities",
		fallback = "municipality",
	},
	["rural municipality"] = {
		link = "w",
		preposition = "of",
		affix_type = "Pref",
		no_affix_strings = "municipality",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["rural township"] = {
		-- Taiwan
		link = "+w:rural township (Taiwan)",
		fallback = "township",
	},
	["sanctuary"] = {
		link = true,
		fallback = "temple",
	},
	["satrapy"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
		inherently_former = {"ANCIENT", "FORMER"},
	},
	["sea"] = {
		link = true,
		holonym_use_the = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["seaport"] = {
		link = true,
		fallback = "port",
	},
	["seat"] = {
		link = true,
		fallback = "administrative centre",
	},
	["self-administered area"] = {
		-- Myanmar (groups self-administered divisions and zones)
		link = "+w:self-administered zone",
		preposition = "of",
		class = "subpolity",
	},
	["self-administered division"] = {
		-- Myanmar (only one of them: Wa Self-Administered Division)
		link = "w",
		fallback = "self-administered area",
	},
	["self-administered zone"] = {
		-- Myanmar (five of them)
		link = "w",
		fallback = "self-administered area",
	},
	["separatist state"] = {
		link = "separately",
		fallback = "unrecognized country",
	},
	["settlement"] = {
		link = true,
		category_link = "[[settlement]]s such as [[city|cities]], [[village]]s and [[farm]]s",
		bare_category_parent = "places",
		-- not necessarily true, but usually is the case
		fallback = "village",
	},
	["sheading"] = {
		-- Isle of Man
		link = true,
		fallback = "district",
	},
	["sheep station"] = {
		-- Australia
		link = true,
		fallback = "farm",
	},
	["shire"] = {
		link = true,
		fallback = "county",
	},
	["shire county"] = {
		link = "w",
		fallback = "county",
	},
	["shire town"] = {
		link = true,
		fallback = "county seat",
	},
	["ski resort city"] = {
		link = "[[ski resort]] [[city]]",
		fallback = "city",
	},
	["ski resort town"] = {
		link = "[[ski resort]] [[town]]",
		fallback = "town",
	},
	["spa city"] = {
		link = "+w:spa town",
		fallback = "city",
	},
	["spa town"] = {
		link = "w",
		fallback = "town",
	},
	["space station"] = {
		link = true,
		fallback = "research station",
	},
	["special administrative region"] = {
		-- in China; in practice they are city-like (Hong Kong, Macau); also [[Oecusse]] in East Timor is formally a
		-- "special administrative region"; North Korea had one such region planned (Sinuiju) but abandoned; Indonesia
		-- has similar "special regions" of Jakarta, Yogyakarta and Aceh; and South Sudan has three "special
		-- administrative areas"
		link = "+w:special administrative regions of China",
		preposition = "of",
		class = "subpolity",
		has_neighborhoods = true, --?
		-- no suffix since places in Hong Kong or Macau are listed without China, except Hong Kong and Macau themselves
		-- they also contain regions (or areas), e.g. [[Kowloon]], so it would be confusing
		suffix = "",
	},
	["special collectivity"] = {
		link = "w",
		fallback = "collectivity",
	},
	["special municipality"] = {
		-- formerly linked to the Taiwan article but there are also special municipalities of the Netherlands
		link = "w",
		fallback = "municipality",
	},
	["special ward"] = {
		-- Tokyo
		link = true,
		fallback = "municipality",
	},
	["spit"] = {
		link = true,
		fallback = "peninsula",
	},
	["spring"] = {
		link = true,
		class = "natural feature",
		default = {true},
	},
	["star"] = {
		link = true,
		class = "natural feature",
		default = {true},
	},
	["state"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
		-- 'former/historical state' could refer either to a state of a country (a division) or a state = sovereign
		-- entity. The latter appears more common (e.g. in various "ancient states" of East Asia).
		former_type = "polity",
	},
	["states and territories!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case Australia.
		category_link = "[[state]]s and [[territory|territories]]",
		class = "subpolity",
	},
	["states and union territories!"] = {
		-- This and other similar "combined placetypes" are for use in the plural when grouping first-level
		-- administrative regions of certain countries, in this case India.
		category_link = "[[state]]s and [[union territory|union territories]]",
		class = "subpolity",
	},
	["state capital"] = {
		link = true,
		fallback = "capital city",
	},
	["state park"] = {
		link = true,
		fallback = "park",
	},
	["state-level new area"] = {
		-- China (type of economic development zone, varying greatly in size)
		link = "w",
		fallback = "new area",
	},
	["statutory city"] = {
		link = "w",
		fallback = "city",
	},
	["statutory town"] = {
		link = "w",
		fallback = "town",
	},
	["strait"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"bodies of water"},
		default = {true},
	},
	["stream"] = {
		link = true,
		fallback = "river",
	},
	["strip"] = {
		link = true,
		fallback = "geographic region",
	},
	["strip of land"] = {
		link = "[[strip]] of [[land]]",
		plural = "strips of land",
		plural_link = "[[strip]]s of [[land]]",
		fallback = "geographic region",
	},
	["sub-prefectural city"] = {
		link = "w",
		fallback = "subprovincial city",
	},
	["subdistrict"] = {
		link = true,
		preposition = "of",
		has_neighborhoods = true, --?
		-- FIXME: subdistricts can be neighborhood-like (of Jakarta) or larger (in China); need a handler
		class = "subpolity",
		default = {true},
	},
	["subdivision"] = {
		link = true,
		preposition = "of",
		affix_type = "suf",
		-- FIXME: subdivisions can be neighborhood-like or larger; need a handler
		class = "subpolity",
		cat_handler = district_neighborhood_cat_handler,
	},
	["submerged ghost town"] = {
		-- FIXME: Consider just having "submerged" as a qualifier.
		link = "[[submerged]] [[ghost town]]",
		fallback = "ghost town",
	},
	["subnational kingdom"] = {
		link = "+w:subnational monarchy",
		fallback = "non-sovereign kingdom",
	},
	["subnational monarchy"] = {
		link = "w",
		fallback = "non-sovereign kingdom",
	},
	["subprefecture"] = {
		link = true,
		affix_type = "suf",
		preposition = "of",
		class = "subpolity",
	},
	["subprovince"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["subprovincial city"] = {
		link = "w",
		-- China; special status given to certain prefecture-level cities
		fallback = "prefecture-level city",
	},
	["subprovincial district"] = {
		link = "w",
		-- China; special status given to Binhai New Area and Pudong New Area, which are county-level districts
		preposition = "of",
		class = "subpolity",
	},
	["subregion"] = {
		link = true,
		fallback = "geographic region",
	},
	["suburb"] = {
		link = true,
		-- The following text is suitable for the top-level description of a suburb as well as categories of the form
		-- 'Suburbs in POLDIV' e.g. 'Suburbs in Illinois, USA' but not for categories of the form 'Suburbs of Chicago',
		-- where we'd get "[[suburb]]s of [[city|cities]] of [[Chicago]]".
		category_link = "[[suburb]]s of [[city|cities]]",
		category_link_before_city = "[[suburb]]s",
		-- See comments under "neighborhood" for the following three settings. They are used by
		-- [[Module:category tree/topic cat/data/Places]] for generating the text of 'Suburbs in/of PLACE' categories
		-- but currently ignored by district_neighborhood_cat_handler (which actually generates the categories for a
		-- given page), which hardcodes "in" for non-cities and "of" for cities. (FIXME: Change this.)
		generic_before_non_cities = "in",
		generic_before_cities = "of",
		preposition = "of",
		has_neighborhoods = true, --?
		class = "non-admin settlement", --?
		cat_handler = district_neighborhood_cat_handler,
	},
	["suburban area"] = {
		link = "w",
		fallback = "suburb",
	},
	["subway station"] = {
		link = "w",
		fallback = "metro station",
	},
	["supercontinent"] = {
		link = true,
		fallback = "continent",
	},
	["tehsil"] = {
		link = true,
		affix_type = "suf",
		no_affix_strings = {"tehsil", "tahsil"},
		class = "subpolity",
	},
	["temple"] = {
		link = true,
		fallback = "building",
	},
	["territorial authority"] = {
		link = "w",
		fallback = "district",
	},
	["territory"] = {
		link = true,
		preposition = "of",
		class = "subpolity",
	},
	["theme"] = {
		link = "+w:theme (Byzantine district)",
		preposition = "of",
		class = "subpolity",
	},
	["town"] = {
		link = true,
		generic_before_non_cities = "in",
		has_neighborhoods = true,
		class = "settlement",
		cat_handler = city_type_cat_handler,
		default = {true},
	},
	["town with bystatus"] = {
		-- can't use templates in links currently
		link = "[[town]] with [[bystatus#Norwegian Bokmål|bystatus]]",
		plural = "towns with bystatus",
		plural_link = "[[town]]s with [[bystatus#Norwegian Bokmål|bystatus]]",
		fallback = "town",
	},
	["township"] = {
		link = true,
		has_neighborhoods = true,
		class = "settlement", --?
		default = {true},
	},
	["township municipality"] = {
		-- Quebec
		link = "+w:township municipality (Quebec)",
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["traditional county"] = {
		link = true,
		fallback = "county",
	},
	["traditional region"] = {
		-- FIXME: Verify this works. Same for 'historic(al) region'.
		-- provided only for the link
		link = "w",
		fallback = "FORMER geographic region",
	},
	["treaty port"] = {
		link = "w",
		fallback = "city",
		class = "settlement",
		inherently_former = {"FORMER"},
	},
	["tributary"] = {
		link = true,
		preposition = "of",
		fallback = "river",
	},
	["underground station"] = {
		link = "w",
		fallback = "metro station",
	},
	["unincorporated area"] = {
		link = "w",
		-- I don't know if this fallback makes sense everywhere.
		fallback = "unincorporated community",
	},
	["unincorporated community"] = {
		link = true,
		generic_before_non_cities = "in",
		class = "non-admin settlement",
	},
	["unincorporated territory"] = {
		link = "w",
		fallback = "territory",
	},
	["union territory"] = {
		-- India
		link = true,
		preposition = "of",
		entry_placetype_indefinite_article = "a",
		class = "subpolity",
	},
	["unitary authority"] = {
		-- UK, New Zealand
		link = true,
		entry_placetype_indefinite_article = "a",
		fallback = "local government district",
	},
	["unitary district"] = {
		link = "w",
		entry_placetype_indefinite_article = "a",
		fallback = "local government district",
	},
	["united township municipality"] = {
		-- Quebec
		link = "+w:united township municipality (Quebec)",
		entry_placetype_indefinite_article = "a",
		fallback = "township municipality",
		has_neighborhoods = true, --?
	},
	["university"] = {
		link = true,
		entry_placetype_indefinite_article = "a",
		class = "man-made structure",
		default = {true},
	},
	["unrecognised country"] = {
		link = "w",
		fallback = "unrecognized country",
	},
	["unrecognized and nearly unrecognized countries!"] = {
		category_link = "[[de facto]] [[independent]] [[state]]s with little or no {{w|international recognition}}",
		bare_category_parent = "country-like entities",
	},
	["unrecognized country"] = {
		link = "w",
		class = "polity",
		default = {"Unrecognized and nearly unrecognized countries"},
	},
	["unrecognised state"] = {
		link = "w",
		fallback = "unrecognized country",
	},
	["unrecognized state"] = {
		link = "w",
		fallback = "unrecognized country",
	},
	["urban area"] = {
		link = "separately",
		fallback = "neighborhood",
	},
	["urban township"] = {
		link = "w",
		fallback = "township",
	},
	["urban-type settlement"] = {
		-- appears to be a particular type of small urban settlement in post-Soviet states,
		-- had an administrative function.
		link = "w",
		fallback = "town",
	},
	["valley"] = {
		link = true,
		class = "natural feature",
		addl_bare_category_parents = {"landforms", "water"},
		default = {true},
	},
	["viceroyalty"] = {
		-- in essence, a type of colony
		link = true,
		fallback = "dependent territory",
	},
	["village"] = {
		link = true,
		generic_before_non_cities = "in",
		category_link = "[[village]]s, [[hamlet]]s, and other small [[community|communities]] and [[settlement]]s",
		class = "settlement",
		cat_handler = city_type_cat_handler,
		default = {true},
	},
	["village municipality"] = {
		-- Quebec
		link = "+w:village municipality (Quebec)",
		preposition = "of",
		fallback = "municipality",
		has_neighborhoods = true, --?
	},
	["voivodeship"] = {
		-- Poland
		link = true,
		display_handler = voivodeship_display_handler,
		preposition = "of",
		holonym_use_the = true,
		class = "subpolity",
	},
	["volcano"] = {
		link = true,
		plural = "volcanoes",
		class = "natural feature",
		addl_bare_category_parents = {"landforms"},
		default = {true, "Mountains"},
	},
	["ward"] = {
		link = true,
		class = "settlement",
		-- Wards are formal administrative divisions of a city but have some properties of neighborhoods.
		fallback = "neighborhood",
	},
	["watercourse"] = {
		link = true,
		fallback = "channel",
	},
	["Welsh community"] = {
		-- Wales
		link = "+w:community (Wales)",
		preposition = "of",
		affix_type = "suf",
		affix = "community",
		has_neighborhoods = true,
		class = "settlement",
	},
	["zone"] = {
		-- administrative division of Ethiopia, Qatar, Nepal, India
		link = "+w:zone#Place names",
		preposition = "of",
		class = "subpolity",
	},
}

export.plural_placetype_to_singular = {}
for sg_placetype, spec in pairs(export.placetype_data) do
	if spec.plural then
		export.plural_placetype_to_singular[spec.plural] = sg_placetype
	end
end


return export
