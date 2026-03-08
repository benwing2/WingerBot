local export = {}

local table_module = "Module:table"
local en_utilities_module = "Module:en-utilities"
local string_pattern_escape_module = "Module:string/patternEscape"
local languages_module = "Module:languages"
local links_module = "Module:links"

local function pattern_escape(...)
	pattern_escape = require(string_pattern_escape_module)
	return pattern_escape(...)
end

local insert = table.insert
local concat = table.concat
local unpack = unpack or table.unpack -- Lua 5.2 compatibility

local function get_by_code(code)
	return require(languages_module).getByCode(code, true, true)
end

-- Return the value of a property of `data`. If the property is a function, we pass it `handdata`, the data object
-- passed into the handler that is handling this category label. If `handdata` is nil, we are called by
-- `add_inflection_labels` rather than through a handler, and there should be no properties whose values are
-- functions; it is an internal error if so.
local function get_data_prop(data, handdata, prop)
	local val = data[prop]
	if type(val) == "function" then
		if not handdata then
			error(("Internal error: Data property `%s` is a function but we're not being invoked through a handler, but directly from `add_inflection_labels`, which doesn't allow for properties whose values are functions"):format(
			prop))
		end
		return val(handdata)
	else
		return val
	end
end

local mark_up_spec, make_spec_bare

function export.default_mark_up_spec(data, handdata, spec, nolink)
	local function make_category(lang, catlink, catdisp)
		local langname = lang:getFullName()
		catlink = make_spec_bare(data, handdata, catlink)
		catdisp = mark_up_spec(data, catdisp, nolink)
		return ("[[:Category:%s %s|%s %s]]"):format(langname, catlink, langname, catdisp)
	end
	local function parse_and_make_category(lang, cat)
		local catlink, catdisp = cat:match("^(.-)|(.+)")
		if not catlink then
			catlink = cat
			catdisp = cat
		end
		return make_category(lang, catlink, catdisp)
	end
	spec = spec:gsub("<<c:([a-z-]+):([^ ].-)>>", function(langcode, cat)
		local langcode_lang = get_by_code(langcode)
		return parse_and_make_category(langcode_lang, cat)
	end)
	spec = spec:gsub("<<c:([^ ].-)>>", function(cat)
		if not lang then
			error("Internal error: Saw category link to current language but no language supplied in `data.lang``")
		end
		return parse_and_make_category(lang, cat)
	end)
	spec = spec:gsub("<<([a-z-]+)(%+?):([^ ].-)>>", "{{m%2|%1|%3}}")
	spec = spec:gsub("<<([^ ].-)>>", function(link)
		if not lang then
			error("Internal error: Saw category link to current language but no language supplied in `data.lang``")
		end
		local langcode = lang:getCode()
		return ("{{m|%s|%s}}"):format(langcode, link)
	end)
	spec = spec:gsub("<(.-)>", "''%1''")
	if nolink then
		spec = require(links_module).remove_links(spec)
	end
	return spec
end

function export.default_make_spec_bare(data, handdata, spec)
	return (spec:gsub("<(.-)>", "%1"))
end

local function mark_up_spec(data, handdata, spec, nolink)
	return (get_data_prop(data, handdata, "mark_up_spec") or export.default_mark_up_spec)(data, handdata, spec, nolink)
end

local function make_spec_bare(data, handdata, spec)
	return (get_data_prop(data, handdata, "make_spec_bare") or export.default_make_spec_bare)(data, handdata, spec)
end

-- Create the label object for the category being described. `data` is the data object passed to the calling function
-- (either `add_inflection_labels` or `add_inflection_handler`. `handdata` is the data passed into the handler, if we're
-- being invoked from a handler, otherwise {nil}. `raw_infl` is the raw inflection label exactly as specified by the
-- user (which may have `GENDER` in it for a gender-subsuming category), and `subbed_infl` is the corresponding label
-- with `GENDER` replaced by the gender being processed (or removed when processing the gender-subsuming category).
-- `plpos` is the plural part of speech, `spec` is the label spec as given by the user, and `subgender` is the subgender
-- if we're processing a gender-specific child inflection, otherwise {nil}.
local function create_response(data, handdata, subbed_infl, raw_infl, plpos, spec, subgender)
	-- Return the value of a property of `data`. If the property is a function, we pass it `handdata`, the data object
	-- passed into the handler that is handling this category label. If `handdata` is nil, we are called by
	-- `add_inflection_labels` rather than through a handler, and there should be no properties whose values are
	-- functions; it is an internal error if so.
	local function get_prop(prop)
		return get_data_prop(data, handdata, prop)
	end

	local function do_mark_up_spec(spec, nolink)
		return mark_up_spec(data, handdata, spec, nolink)
	end

	local function do_make_spec_bare(spec)
		return make_spec_bare(data, handdata, spec)
	end

	-- Generate the additional text, including typical gender description, principal part descriptions, examples, and
	-- any footer. We conditionalize on `subgender` to determine if we're processing a subgender, i.e. a gender-specific
	-- child inflection, or a gender-subsuming parent inflection.
	local function create_addl()
		local addl_parts = {}
		local function ins(txt)
			insert(addl_parts, txt)
		end
		local subgender_prefix = subgender and subgender .. "_" or ""

		-- Compute the gender description and insert text about it.
		local gender_spec
		if subgender then
			gender_spec = subgender
		elseif spec.gender then
			gender_spec = spec.gender
		elseif spec.possible_genders then
			gender_spec = require(table_module).serialCommaJoin(spec.possible_genders, {conj = "or"})
		end
		if gender_spec then
			local most_commonly, gender = gender_spec:match("^(~)(.*)$")
			most_commonly = most_commonly and "most commonly " or ""
			gender = gender or gender_spec
			ins(("These %s are %s%s, typically with the following endings:\n"):format(plpos, most_commonly, gender))
		else
			ins(("These %s typically have the following endings:\n"):format(plpos))
		end

		-- Insert information about each principal part.
		local principal_parts = get_prop("principal_parts")
		for i, ppart_spec in ipairs(principal_parts) do
			local ppart_field, ppart_desc = unpack(ppart_spec)
			local ending_spec
			if subgender then
				ending_spec = spec[subgender_prefix .. ppart_field] or spec[ppart_field]
			elseif spec[ppart_field] then
				ending_spec = spec[ppart_field]
			elseif not spec.possible_genders then
				error(("Internal error: for inflection '%s', field '%s' for principal part '%s' is missing and `possible_genders` isn't specified, so there's no way to compute the field from the gender-specific values"):format(
					raw_infl, ppart_field, ppart_desc))
			else
				local ppart_parts = {}
				for _, possible_gender in ipairs(spec.possible_genders) do
					local gender_ppart_desc = spec[("%s_%s"):format(possible_gender, ppart_field)]
					if not gender_ppart_desc then
						error(("Internal error: for inflection '%s', field '%s_%s' for principal part '%s', gender '%s' is missing"):format(
							raw_infl, possible_gender, ppart_field, ppart_desc, possible_gender))
					end
					insert(ppart_parts, ("when %s, %s"):format(possible_genders, gender_ppart_desc))
				end
				ending_spec = concat(ppart_parts, "; ")
			end
			ins(("* in the %s: %s%s"):format(ppart_desc, ending_spec, i == #principal_parts and "." or ";\n"))
		end

		-- Insert information about examples.
		local examples_spec, need_examples_prefix
		if subgender then
			examples_spec = spec[subgender_prefix .. "examples"]
			-- `false` for subgender examples means no examples and don't fall back
			if examples_spec == nil then
				examples_spec = spec.examples
			end
			need_examples_prefix = true
		elseif spec.examples then
			examples_spec = spec.examples
			need_examples_prefix = true
		else
			local examples_parts = {}
			local saw_newline = false
			for _, possible_gender in ipairs(spec.possible_genders) do
				local subgender_examples = spec[possible_gender .. "_examples"]
				if subgender_examples and subgender_examples:find("\n") then
					saw_newline = true
					break
				end
			end
			for i, possible_gender in ipairs(spec.possible_genders) do
				local subgender_examples = spec[possible_gender .. "_examples"]
				if subgender_examples then
					if saw_newline then
						insert(examples_parts, ("* When %s:\n"):format(possible_gender))
						subgender_examples = subgender_examples:gsub("^([#*])", "*%1")
						subgender_examples = subgender_examples:gsub("\n([#*])", "\n*%1")
						insert(examples_parts, subgender_examples)
					else
						insert(examples_parts, ("* When %s: %s%s"):format(possible_gender, subgender_examples,
							i == #spec.possible_genders and ".\n" or ";\n"))
					end
				end
			end
			examples_spec = concat(examples_parts)
			if examples_spec == "" then
				examples_spec = nil
			end
		end
		if examples_spec then
			if need_examples_prefix then
				if examples_spec:find("\n") then
					examples_spec = "Examples:\n" .. examples_spec
				else
					examples_spec = ("Examples: %s.\n"):format(examples_spec)
				end
			end
			ins(examples_spec)
		end

		-- Insert additional (footer) information.
		local footer_spec, need_footer_newline
		if subgender then
			footer_spec = spec[subgender_prefix .. "addl"]
			-- `false` for subgender addl means no addl and don't fall back
			if footer_spec == nil then
				footer_spec = spec.addl
			end
			need_footer_newline = true
		elseif spec.addl then
			footer_spec = spec.addl
			need_footer_newline = true
		else
			local footer_parts = {}
			for i, possible_gender in ipairs(spec.possible_genders) do
				local subgender_footer = spec[possible_gender .. "_addl"]
				if subgender_footer then
					insert(footer_parts, subgender_footer)
					if not subgender_footer:find("\n$") then
						insert("\n")
					end
					if i < #spec.possible_genders then
						insert("\n")
					end
				end
			end
			footer_spec = concat(footer_parts)
			if footer_spec == "" then
				footer_spec = nil
			end
		end
		if footer_spec then
			ins("\n")
			ins(footer_spec)
			if need_footer_newline and not footer_spec:find("\n$") then
				ins("\n")
			end
		end
		local retval = do_mark_up_spec(concat(addl_parts))
		-- Remove a final newline, which just results in extra blank space.
		retval = retval:gsub("\n$", "")
		return retval
	end

	if subgender then
		local gender_infl = raw_infl:gsub("GENDER", subgender)
		return {
				description = "{{{langname}}} " .. do_mark_up_spec(gender_infl) .. " " .. plpos .. ".",
				displaytitle = "{{{langname}}} " .. do_mark_up_spec(gender_infl, "nolink") .. " " .. plpos,
				additional = create_addl(),
				breadcrumb = subgender,
				parents = {{
					name = do_make_spec_bare(subbed_infl) .. " " .. plpos,
					sort = subgender,
				}},
			}
	else
		-- Get the breadcrumb.
		local breadcrumb = spec.breadcrumb or spec.sortkey or "+"
		if breadcrumb == "+" then
			breadcrumb = subbed_infl
		end

		-- Generate the parents.
		local parents = {}
		local spec_parents = spec.parent
		if type(spec_parents) == "string" then
			spec_parents = {spec_parents}
		end
		local parent_sort = do_make_spec_bare(spec.sortkey or subbed_infl)
		if spec_parents then
			for _, parent in ipairs(spec_parents) do
				insert(parents, {name = do_make_spec_bare(parent) .. " " .. plpos, sort = parent_sort})
			end
		else
			insert(parents, {name = plpos .. " by inflection type", sort = parent_sort})
		end

		return {
			description = "{{{langname}}} " .. do_mark_up_spec(subbed_infl) .. " " .. plpos .. ".",
			displaytitle = "{{{langname}}} " .. do_mark_up_spec(subbed_infl, "nolink") .. " " .. plpos,
			additional = create_addl(),
			breadcrumb = do_mark_up_spec(breadcrumb, "nolink"),
			parents = parents,
		}
	end
end


--[==[
Generate labels for inflection classes. `data` is a table with the following fields:
* `labels`: The table into which the labels are written.
* `lang`: The language object for the language being described; used for expanding terms enclosed in `<<...>>`. Can be
  omitted if no such terms are present.
* `pos`: The singular part of speech, e.g. {"noun"}.
* `stem_classes`: Table of possible stem classes and associated properties. See below.
* `principal_parts`: List of the principal part fields and descriptions. Each list element is a two-element list
  consisting of { {"``field``", "``description``"}} where ``field`` is the field in the element in `stem_classes` (e.g.
  {"nom_sg"}, {"gen_sg"}, {"pl"}, {"sup"}) containing the detailed description of what this principal part looks like,
  and ``description`` is the corresponding English description of the principal part (e.g. "nominative singular").
* `mark_up_spec`: Optional function to add markup to a spec. Takes two arguments, the spec and a flag `nolink`; if the
  flag is true, links should not be present in the resulting markup. The default just converts literal text enclosed
  in `<...>` into italics.
* `make_spec_bare`: Optional function to make a spec (stem class or sortkey) free of markup. The default just converts
  literal text enclosed in `<...>` into bare text.
* `addl`: Optional additional text to be displayed in the footer of each category page.

`stem_classes` is a table describing the various stem classes and how to format the category description of each. It is
a table with keys specifying the stem classes and values consisting of an object containing properties of the stem
class. If the stem class contains the word `GENDER` in it (in all caps), it expands into labels both for a parent
category that subsumes several genders (obtained by removing the word `GENDER` and following whitespace) as well as
gender-specific children categories (obtained by replacing the word `GENDER` with the genders specified in the
`possible_genders` field). The stem class can contain literal text (e.g. suffixes) enclosed in `<...>`, which will be
marked up appropriately (e.g. italicized) in breadcrumbs and titles. The fields of the property object for a given stem
class consist of principal part ending descriptions, examples of the stem class, etc. All values that are strings can
contain the following types of markup:
* Literal text enclosed in `<...>` (e.g. suffixes), which by default is italicized.
* Terms (e.g. for use in examples), enclosed in `<<...>>`. The text inside of the double angle brackets is directly
  wrapped in {{tl|m|``lang``|...}} where ``lang`` is the language specified using the `lang` field in the
  `data` object passed into the function; this means that vertical bars and parameter specs can be given and will be
  interpreted appropriately as for {{tl|m}}. To override the language used, put the language code directly after the
  opening double angle bracket, followed by a colon, e.g. `<<es:niña>>` to create a link to the Spanish term
  {{m|es|niña}} when describing another language.
* References to other fields, specified using `[:``field``:]`, i.e. square brackets followed by a colon followed by the
  field name and another colon. This could be used, for example, to reference the description for one principal part in
  another. Such references will be expanded recursively (i.e. it works correctly if a field references another field,
  which in turn references a third field), but there is a limit of 10 in the recursion depth to catch circular
  references.

The following fields are recognized:
* `gender`: The description of the gender(s) of the stem class. If preceded by `~`, the description is preceded by
  `most commonly`. This appears in the `additional` field of the label properties. It is not used in gender-specific
  children categories; instead the gender of that category is used. If omitted, it is constructed from
  `possible_genders` if provided.
* `possible_genders`: The possible genders this class occurs in. If this is specified, the word `GENDER` in all caps
  must occur in the stem class, and gender-specific variants of the stem class (with `GENDER` replaced by the possible
  genders) are handled along with a parent category subsuming all genders. 
* ``principal_part``: The description of the ending for the specified principal part. There will be one field for each
  principal part listed in the `principal_parts` table described above. If omitted and ``gender_principal_part`` values
  are supplied, it will be constructed from them. For example, if `possible_genders` specifies `{"masculine", "neuter"}`
  and the principal part is `nom_sg` but the description is omitted, the value will be the result of expanding
  `when masculine, [:masculine_nom_sg:]; when neuter, [:neuter_nom_sg:]`.
* ``gender_principal_part``: The ending for the `GENDER` variant of the specified principal part. If not specified, the
  value of ``principal_part`` is used.
* `breadcrumb`: The breadcrumb for the category, appearing in the trail of breadcrumbs at the top of the page. If this
  stem has gender-specific variants, the breadcrumb specified here is used only for the parent category, while the
  gender-specific child categories use the gender as the breadcrumb. If not specified, it defaults to `sortkey`. If that
  is also not specified, or if the breadcrumb has the value {"+"}, the stem class (without the word `GENDER`) is used.
  (Use {"+"} when a sortkey is specified but the stem class should be used as the breadcrumb.)
* `parent`: The parent category or categories. If specified, the actual category label is formed by appending the part
  of speech (e.g. "nouns"). Defaults to `"``pos`` by inflection type"` where ``pos`` is the part of speech. Note that
  gender-specific child categories do not use this, but always have the gender-subsuming parent stem class category as
  their parent.
* `sortkey`: The sort key used for sorting this category among its parent's children. Defaults to the stem class
  (without the word `GENDER`). Note that gender-specific child categories do nto use this, but always use the gender
  as the sort key.
* `addl`: Optional additional text to be displayed in the footer of the category page.
* ```gender``_addl`: Optional additional text to be displayed in the footer of a gender-specific category page,
  defaulting to `addl`. Use the value `false` to cancel out a non-gender-specific value.
* `examples`: Text describing examples of this stem class. If omitted, and ```gender`_examples` values are supplied,
  it will be constructed from them by pasting them together (with a newline if newlines occur in the text of any of the
  gender-specific examples, otherwise with a semicolon plus space).
* ```gender``_examples`: Text describing examples of this gender-specific stem class, defaulting to `examples`. Gender
  params in examples enclosed in double angle brackets are removed if they occur at the end of an example; this is for
  use in constructing the gender-subsuming `examples` value, which does not remove such params. To specify a gender
  param that is not to be removed in this fashion, put it elsewhere than at the end of the example (e.g. write
  `<<g=f|niña>>` instead of `<<niña|g=f>>`).
]==]
function export.add_inflection_labels(data)
	for _, reqfield_spec in ipairs {
		{"labels", "table of labels"},
		{"pos", "singular part of speech"},
		{"stem_classes", "table of possible stem classes and associated properties"},
		{"principal_parts", "list of principal part fields and descriptions"},
	} do
		local reqfield, gloss = unpack(reqfield_spec)
		if not data[reqfield] then
			error(("Internal error: Missing field '%s', which should containing the %s"):format(reqfield, gloss))
		end
	end

	local plpos = require(en_utilities_module).pluralize(data.pos)
	for raw_infl, spec in pairs(data.stem_classes) do
		local subgenders = spec.possible_genders

		-- Get the stem type.
		local subbed_infl
		if subgenders then
			if not raw_infl:find("GENDER") then
				error(("Internal error: Declension spec '%s' needs to have the word 'GENDER' in it, in all caps"):format(raw_infl))
			end
			subbed_infl = raw_infl:gsub("GENDER ", "")
		else
			subbed_infl = raw_infl
		end

		data.labels[make_spec_bare(data, nil, subbed_infl) .. " " .. plpos] =
			create_response(data, nil, subbed_infl, raw_infl, plpos, spec, nil)
		if subgenders then
			for _, subgender in ipairs(subgenders) do
				local gender_infl = raw_infl:gsub("GENDER", subgender)
				data.labels[make_spec_bare(data, nil, gender_infl) .. " " .. plpos] =
					create_response(data, nil, subbed_infl, raw_infl, plpos, spec, subgender)
			end
		end
	end
end


--[==[
Add a handler that handles inflection class categories. This is a more flexible version of `add_inflection_labels` that
can be used when properties like `stem_classes` need to vary depending on the language or other property of the
category whose contents are being generated. `data` is a table with the following fields:
* `handlers`: The table into which the handler is added.
* `poses`: The list of possible singular parts of speech that are recognized, or a function to retrieve this given the
  `data` structure passed to handlers.
* `stem_classes`: Table of possible stem classes and associated properties, or a function to retrieve this given the
  `data` structure passed to handlers. See `add_inflection_labels` for a description of the format of this table.
* `principal_parts`: List of the principal part fields and descriptions, or a function to retrieve this given the `data`
  structure passed to handlers; same format as for `add_inflection_labels`.
* `mark_up_spec`: Optional function to add markup to a spec, or a function to retrieve this given the `data` structure
  passed to handlers. Same as for `add_inflection_labels`.
* `make_spec_bare`: Optional function to make a spec (stem class or sortkey) free of markup, or a function to retrieve
  this given the `data` structure passed to handlers. Same as for `add_inflection_labels`.
* `addl`: Optional additional text to be displayed in the footer of each category page, or a function to retrieve this
  given the `data` structure passed to handlers.
]==]
function export.add_inflection_handler(data)
	for _, reqfield_spec in ipairs {
		{"handlers", "table of handlers"},
		{"poses", "list of possible singular parts of speech, or function to retrieve this given the `data` structure passed to handlers"},
		{"stem_classes", "table of possible stem classes and associated properties, or function to retrieve this given the `data` structure passed to handlers"},
		{"principal_parts", "list of principal part fields and descriptions, or function to retrieve this given the `data` structure passed to handlers"},
	} do
		local reqfield, gloss = unpack(reqfield_spec)
		if not data[reqfield] then
			error(("Internal error: Missing field '%s', which should containing the %s"):format(reqfield, gloss))
		end
	end

	local function handler(handdata)
		local function mark_up_spec(spec, nolink)
			return (get_prop("mark_up_spec") or default_mark_up_spec)(spec, nolink)
		end
		local function make_spec_bare(spec)
			return (get_prop("make_spec_bare") or default_make_spec_bare)(spec)
		end

		local stem_classes = get_prop("stem_classes")
		if not stem_classes then
			return
		end

		local plpos = {}
		for _, pos in ipairs(get_prop("poses")) do
			insert(plpos, require(en_utilities_module).pluralize(pos))
		end
		local plpos_set = require(table_module).listToSet(plpos)
		
		for raw_infl, spec in pairs(stem_classes) do
			local subgenders = spec.possible_genders
	
			-- Get the stem type.
			local subbed_infl
			if subgenders then
				if not raw_infl:find("GENDER") then
					error(("Internal error: Declension spec '%s' needs to have the word 'GENDER' in it, in all caps"):format(raw_infl))
				end
				subbed_infl = raw_infl:gsub("GENDER ", "")
			else
				subbed_infl = raw_infl
			end
			local found_pos = data.label:match("^" .. pattern_escape(make_spec_bare(subbed_infl)) .. " ([%w ])$")
			if found_pos then
				return create_response(data, handdata, subbed_infl, raw_infl, found_pos, spec, nil)
			end
			if subgenders then
				for _, subgender in ipairs(subgenders) do
					local gender_infl = raw_infl:gsub("GENDER", subgender)
					found_pos = data.label:match("^" .. pattern_escape(make_spec_bare(gender_infl)) .. " ([%w ])$")
					if found_pos then
						return create_response(data, handdata, subbed_infl, raw_infl, found_pos, spec, subgender)
					end
				end
			end
		end
	end

	insert(data.handlers, handler)
end

return export
