local export = {}

local etymology_module = "Module:etymology"
local links_module = "Module:links"
local pron_qualifier_module = "Module:pron qualifier"

-- main function

--[==[
Format the affix usexes in `data`. We more or less simply call full_link() on each item, along with the
associated params, to format the link, but need some special-casing for affixes. On input, the `data`
object contains the following fields:
* `lang` ('''required'''): Overall language object; default for items not specifying their own language.
* `sc`: Overall script object; default for items not specifying their own script.
* `items`: List of items. Each is an object with the following fields:
** `term`: The term (affix or resulting term).
** `gloss`, `tr`, `ts`, `genders`, `alt`, `id`, `lit`, `pos`, `ng`: The same as for `full_links()` in [[Module:links]].
** `lang`: Language of the term. Should only be set when the term has its own language, and will cause the
   language to be displayed before the term. Defaults to the overall `lang`.
** `sc`: Script of the term. Defaults to the overall `sc`.
** `fulljoiner`: Text of the separator appearing before the item, including spaces. Takes precedence over `joiner`
   and `arrow`.
** `joiner`: Text of the separator appearing before the item, not including spaces. Takes precedence over `arrow`.
** `arrow`: If specified, the separator is a right arrow. If none of `fulljoiner`, `joiner` and `arrow` are given,
   the separator is a right arrow if it's the last item, otherwise a plus sign if it's not the first item, otherwise
   there's no displayed separator.
** `l`: Left labels for the term.
** `ll`: Right labels for the term.
** `q`: Left regular qualifier(s) for the term.
** `qq`: Right regular qualifier(s) for the term.
** `refs`: References for the term, in the structure expected by [[Module:references]].
* `lit`: Overall literal meaning.
* `l`: Overall left labels.
* `ll`: Overall right labels.
* `q`: Overall left regular qualifier(s).
* `qq`: Overall right regular qualifier(s).

'''WARNING:''' This destructively modifies the `items` objects (specifically by adding default values for `lang` and
`sc`).
]==]
function export.format_affixusex(data)
	local result = {}

	-- Loop over all terms. We simply call 
	for index, item in ipairs(data.items) do
		local term = item.term
		local alt = item.alt

		if item.fulljoiner then
			table.insert(result, item.fulljoiner)
		elseif item.joiner then
			table.insert(result, " " .. item.joiner .. " ")
		elseif index == #data.items or item.arrow then
			table.insert(result, " → ")
		elseif index > 1 then
			table.insert(result, " + ")
		end
		table.insert(result, "&lrm;")

		local text
		local item_lang_specific = item.lang
		item.lang = item.lang or data.lang
		item.sc = item.sc or data.sc
		if item_lang_specific then
			text = require(etymology_module).format_derived {
				sources = {item.lang},
				terms = {item},
				-- Don't need to specify `nocat = true` because we don't pass in `lang`.
				template_name = "affixusex",
				qualifiers_labels_on_outside = true,
			}
		else
			text = require(links_module).full_link(item, "term", nil, "show qualifiers")
		end
		table.insert(result, text)
	end

	result = table.concat(result) .. (data.lit and ", literally " ..
		require(links_module).mark(data.lit, "gloss") or "")

	if data.q and data.q[1] or data.qq and data.qq[1] or data.l and data.l[1] or data.ll and data.ll[1] then
		result = require(pron_qualifier_module).format_qualifiers {
			lang = data.lang,
			text = result,
			q = data.q,
			qq = data.qq,
			l = data.l,
			ll = data.ll,
		}
	end

	return result
end

return export
