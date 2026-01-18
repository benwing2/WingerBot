local export = {}

local labels_module = "Module:labels"
local table_module = "Module:table"
local insert = table.insert
local concat = table.concat

--[[	this function is only to be used in
		{{alternative spelling of}},
		{{eye dialect of}}
		and similar templates					]]
function export.show_from(frame)
	local formatted_labels = {}
	local formatted_categories = {}

	local iparams = {
		["lang"] = {type = "language"},
		["default"] = {},
	}
	
	local iargs = require("Module:parameters").process(frame.args, iparams)
	local parent_args = frame:getParent().args
	local compat = iargs.lang or parent_args.lang

	local params = {
		[compat and "lang" or 1] = {required = not iargs.lang, type = "language"},
		["from"] = {list = true},
		["nocat"] = {type = "boolean"},
	}

	-- This is called by various form-of templates. They accept several params,
	-- and some templates accept additional params. To avoid having to list all
	-- of them, we just ignore unrecognized params. The main processing for the
	-- form-of template will catch true unrecognized params.
	local args = require("Module:parameters").process(parent_args, params, "allow unrecognized params")
	local lang = args[compat and "lang" or 1] or iargs.lang or require("Module:languages").getByCode("und")
	local nocat = args.nocat

	local already_seen = {}
	for _, from_label in ipairs(args.from) do
		local processed_labels = require(labels_module).split_and_process_raw_labels {
			labels = from_label,
			lang = lang,
			mode = "form-of",
			nocat = nocat,
			already_seen = already_seen,
			ok_to_destructively_modify = true,
		}
		local this_formatted_labels, this_formatted_categories = require(labels_module).format_processed_labels {
			labels = processed_labels,
			lang = lang,
			mode = "form-of",
			open = false,
			close = false,
			no_ib_content = true,
			ok_to_destructively_modify = true,
			split_output = true,
		}
		if this_formatted_labels ~= "" then
			insert(formatted_labels, this_formatted_labels)
		end
		insert(formatted_categories, this_formatted_categories)
	end

	local joined_formatted_labels =
		#formatted_labels == 0 and iargs.default or require(table_module).serialCommaJoin(formatted_labels)

	return joined_formatted_labels .. concat(formatted_categories)
end

return export
