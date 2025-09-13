local export = {}

local labels_module = "Module:labels"

--[[	this function is only to be used in
		{{alternative spelling of}},
		{{eye dialect of}}
		and similar templates					]]
function export.show_from(frame)
	local froms = {}
	local categories = {}

	local iparams = {
		["lang"] = {type = "language"},
		["default"] = {},
	}
	
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local parent_args = frame:getParent().args
	local compat = iargs["lang"] or parent_args["lang"]

	local params = {
		[compat and "lang" or 1] = {required = not iargs["lang"], type = "language"},
		["from"] = {list = true},
		["nocat"] = {type = "boolean"},
	}

	-- This is called by various form-of templates. They accept several params,
	-- and some templates accept additional params. To avoid having to list all
	-- of them, we just ignore unrecognized params. The main processing for the
	-- form-of template will catch true unrecognized params.
	local args = require("Module:parameters").process(parent_args, params, "allow unrecognized params")
	local lang = args[compat and "lang" or 1] or iargs["lang"] or require("Module:languages").getByCode("und")
	local nocat = args["nocat"]

	for _, k in ipairs(args["from"]) do
		local ret = require(labels_module).get_label_info { label = k, lang = lang, mode = "form-of", }
		if ret.label ~= "" then
			table.insert(froms, ret.label)
		end
		if not nocat and ret.formatted_categories and ret.formatted_categories ~= "" then
			table.insert(categories, ret.formatted_categories)
		end
	end
	
	if #froms == 0 then
		return iargs.default
	end

	return require("Module:table").serialCommaJoin(froms) .. table.concat(categories)
end

return export
