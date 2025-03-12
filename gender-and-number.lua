local export = {}

local debug_track_module = "Module:debug/track"
local pron_qualifier_module = "Module:pron qualifier"
local parameters_module = "Module:parameters"
local utilities_module = "Module:utilities"

local concat = table.concat
local insert = table.insert

local data = mw.loadData("Module:gender and number/data")

local function debug_track(...)
	debug_track = require(debug_track_module)
	return debug_track(...)
end

local function format_categories(...)
	format_categories = require(utilities_module).format_categories
	return format_categories(...)
end

local function format_pron_qualifiers(...)
	format_pron_qualifiers = require(pron_qualifier_module).format_qualifiers
	return format_pron_qualifiers(...)
end

local function process_params(...)
	process_params = require(parameters_module).process
	return process_params(...)
end

--[==[ intro:
This module creates standardised displays for gender and number. It converts a gender specification into Wiki/HTML format.

A gender/number specification consists of one or more gender/number elements, separated by hyphens. Examples are:
{"n"} (neuter gender), {"f-p"} (feminine plural), {"m-an-p"} (masculine animate plural),
{"pf"} (perfective aspect). Each gender/number element has the following properties:
# A code, as used in the spec, e.g. {"f"} for feminine, {"p"} for plural.
# A type, e.g. `gender`, `number` or `animacy`. Each element in a given spec must be of a different type.
# A display form, which in turn consists of a display code and a tooltip gloss. The display code
  may not be the same as the spec code, e.g. the spec code {"an"} has display code {"anim"} and tooltip
  gloss ''animate''.
# A category into which lemmas of the right part of speech are placed if they have a gender/number
  spec containing the given element. For example, a noun with gender/number spec {"m-an-p"} is placed
  into the categories `<var>lang</var> masculine nouns`, `<var>lang</var> animate nouns` and `<var>lang</var> pluralia tantum`.
]==]

--[==[
Version of format_list that can be invoked from a template.
]==]
function export.show_list(frame)
	local params = {
		[1] = {list = true},
		["lang"] = {type = "language"},
	}
	local iargs = process_params(frame.args, params)
	return export.format_list(iargs[1], iargs.lang)
end


--[==[
Older entry point; equivalent to format_genders() except that it formats the
categories and returns them appended to the formatted gender text rather than
returning the formatted text and categories separately.
]==]
function export.format_list(specs, lang, pos_for_cat, sort_key)
	debug_track("gender and number/old-format-list")
	local text, cats = export.format_genders(specs, lang, pos_for_cat)
	if not cats then
		return text
	end
	return text .. format_categories(cats, lang, sort_key)
end


local function autoadd_abbr(display)
	if not display then
		error("Internal error: '.display' for gender/number code is missing")
	end
	if display:find("<abbr") then
		return display
	else
		return ('%s'):format(display, display)
	end
end


-- Add qualifiers, labels and references to a formatted gender/number spec. `spec` is the object describing the
-- gender/number spec, which should optionally contain:
-- * left qualifiers in `q` or (for compatibility) `qualifiers`, an array of strings;
-- * right qualifiers in `qq`, an array of strings;
-- * left labels in `l`, an array of strings;
-- * right labels in `ll`, an array of strings;
-- * references in `refs`, an array either of strings (formatted reference text) or objects containing fields `text`
--   (formatted reference text) and optionally `name` and/or `group`;
-- `formatted` is the formatted version of the term itself, and `lang` is the optional language object passed into
-- format_genders().
local function add_qualifiers_and_refs(formatted, spec, lang)
	local function field_non_empty(field)
		local list = spec[field]
		if not list then
			return nil
		end
		if type(list) ~= "table" then
			error(("Internal error: Wrong type for `spec.%s`=%s, should be \"table\""):format(
				field, mw.dumpObject(list)))
		end
		return list[1]
	end

	if field_non_empty("q") or field_non_empty("qq") or field_non_empty("l") or field_non_empty("ll") or
		field_non_empty("qualifiers") or field_non_empty("refs") then
		formatted = format_pron_qualifiers {
			lang = lang,
			text = formatted,
			q = spec.q,
			qq = spec.qq,
			qualifiers = spec.qualifiers,
			l = spec.l,
			ll = spec.ll,
			refs = spec.refs,
		}
	end

	return formatted
end


--[==[
Format one or more gender/number specifications. Each spec is either a string, e.g. {"f-p"}, or a table of the form
{ {spec = "SPEC", qualifiers = {"QUALIFIER", "QUALIFIER", ...}}} where `.spec` is a gender/number spec such as {"f-p"}
and `.qualifiers` is a list of qualifiers to display before the formatted gender/number spec. `.spec` must be present
but `.qualifiers` may be omitted.

The function returns two values:
# the formatted text;
# a list of the categories to add.

If `lang` (which should be a language object) and `pos_for_cat` (which should be a plural part of speech) are given,
gender categories such as `German masculine nouns` or `Russian imperfective verbs` are added to the categories, and
request categories such as `Requests for gender in <var>lang</var> entries` or
`Requests for animacy in <var>lang</var> entries` may also be added. Otherwise, if only `lang` is given, only request
categories may be returned. If both are omitted, the returned list is empty.
]==]
function export.format_genders(specs, lang, pos_for_cat)
	local formatted_specs, categories, seen_types = {}
	local all_is_nounclass = nil
	local full_langname = lang and lang:getFullName() or nil

	local function do_gender_spec(spec, parts)
		local types = {}
		local codes = data.codes

		for key, code in ipairs(parts) do
			-- Is this code valid?
			if not codes[code] then
				error('The tag "' .. code .. '" in the gender specification "' .. spec.spec .. '" is not valid. See [[Module:gender and number]] for a list of valid tags.')
			end
			
			-- Check for multiple genders/numbers/animacies in a single spec.
			local typ = codes[code].type
			if typ ~= "other" and types[typ] then
				error('The gender specification "' .. spec.spec .. '" contains multiple tags of type "' .. typ .. '".')
			end
			types[typ] = true
				
			parts[key] = autoadd_abbr(codes[code].display)
		
			-- Generate categories if called for.
			if lang and pos_for_cat then
				local cat = codes[code].cat
				if cat then
					if not categories then
						categories = {}
					end
					insert(categories, full_langname .. " " .. cat)
				end
				if not seen_types then
					seen_types = {}
				elseif seen_types[typ] and seen_types[typ] ~= code then
					cat = data.multicode_cats[typ]
					if cat then
						if not categories then
							categories = {}
						end
						insert(categories, full_langname .. " " .. cat)
					end
				end
				seen_types[typ] = code
			end
			if lang and codes[code].req then
				local type_for_req = typ
				if code == "?" then
					-- Keep in mind `pos_for_cat` may be nil here.
					type_for_req = pos_for_cat == "verbs" and "aspect" or "gender"
				end
				if not categories then
					categories = {}
				end
				insert(categories, "Requests for " .. type_for_req .. " in " .. full_langname .. " entries")
			end
		end

		-- Add the processed codes together with non-breaking spaces
		if not parts[2] and parts[1] then
			return parts[1]
		else
			return concat(parts, "&nbsp;")
		end
	end

	for _, spec in ipairs(specs) do
		if type(spec) ~= "table" then
			spec = {spec = spec}
		end
		local is_nounclass
		-- If the specification starts with cX, then it is a noun class specification.
		if spec.spec:find("^[1-9]") or spec.spec:find("^c[^-]") then
			is_nounclass = true
			local code = spec.spec:gsub("^c", "")
			
			local text
			if code == "?" then
				text = '<abbr class="noun-class" title="noun class missing">?</abbr>'
				if lang then
					if not categories then
						categories = {}
					end
					insert(categories, "Requests for noun class in " .. full_langname .. " entries")
				end
			else
				text = '<abbr class="noun-class" title="noun class ' .. code .. '">' .. code .. "</abbr>"
				if lang and pos_for_cat then
					if not categories then
						categories = {}
					end
					insert(categories, full_langname .. " class " .. code .. " POS")
				end
			end
			local text_with_qual = add_qualifiers_and_refs(text, spec, lang)
			insert(formatted_specs, text_with_qual)
		else
			-- Split the parts and iterate over each part, converting it into its display form
			local parts = mw.text.split(spec.spec, "%-")
			local combined_codes = data.combinations

			if lang then
				-- Check if the specification is valid
				--elseif langinfo.genders then
				--	local valid_genders = {}
				--	for _, g in ipairs(langinfo.genders) do valid_genders[g] = true end
				--	
				--	if not valid_genders[spec.spec] then
				--		local valid_string = {}
				--		for i, g in ipairs(langinfo.genders) do valid_string[i] = g end
				--		error('The gender specification "' .. spec.spec .. '" is not valid for ' .. langinfo.names[1] .. ". Valid are: " .. concat(valid_string, ", "))
				--	end
				--end
			end

			local has_combined = false
			for _, code in ipairs(parts) do
				if combined_codes[code] then
					has_combined = true
					break
				end
			end

			if not has_combined then
				if #formatted_specs > 0 then
					insert(formatted_specs, "or")
				end
				insert(formatted_specs, add_qualifiers_and_refs(do_gender_spec(spec, parts), spec, lang))
			else
				-- This logic is to handle combined gender specs like 'mf' and 'mfbysense'.
				local all_parts = {{}}
				local extra_displays
				local this_formatted_specs = {}

				for _, code in ipairs(parts) do
					if combined_codes[code] then
						local new_all_parts = {}
						for _, one_parts in ipairs(all_parts) do
							for _, one_code in ipairs(combined_codes[code].codes) do
								local new_combined_parts = mw.clone(one_parts)
								insert(new_combined_parts, one_code)
								insert(new_all_parts, new_combined_parts)
							end
						end
						all_parts = new_all_parts
						if lang and pos_for_cat then
							local extra_cat = combined_codes[code].cat
							if extra_cat then
								if not categories then
									categories = {}
								end
								insert(categories, full_langname .. " " .. extra_cat)
							end
						end
						local extra_display = combined_codes[code].display
						if extra_display then
							if not extra_displays then
								extra_displays = {}
							end
							insert(extra_displays, autoadd_abbr(extra_display))
						end
					else
						for _, one_parts in ipairs(all_parts) do
							insert(one_parts, code)
						end
					end
				end

				for _, parts in ipairs(all_parts) do
					if #formatted_specs > 0 then
						insert(formatted_specs, "or")
					end
					insert(this_formatted_specs, do_gender_spec(spec, parts))
				end

				if extra_displays then
					for _, display in ipairs(extra_displays) do
						insert(this_formatted_specs, display)
					end
				end

				insert(this_formatted_specs, add_qualifiers_and_refs(
					concat(this_formatted_specs, " "), spec, lang))
			end

			is_nounclass = false
		end

		-- Ensure that the specifications are either all noun classes, or none are.
		if all_is_nounclass == nil then
			all_is_nounclass = is_nounclass
		elseif all_is_nounclass ~= is_nounclass then
			error("Noun classes and genders cannot be mixed. Please use either one or the other.")
		end
	end

	if categories and lang and pos_for_cat then
		for i, cat in ipairs(categories) do
			categories[i] = cat:gsub("POS", pos_for_cat)
		end
	end

	if all_is_nounclass then
		-- Add the processed codes together with slashes
		return '<span class="gender">class ' .. concat(formatted_specs, "/") .. "</span>", categories
	else
		-- Add the processed codes together with spaces
		return '<span class="gender">' .. concat(formatted_specs, " ") .. "</span>", categories
	end
end

return export
