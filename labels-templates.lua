local export = {}

local labels_module = "Module:labels"

-- Add tracking category for PAGE. The tracking category linked to is [[Wiktionary:Tracking/labels/PAGE]].
local function track(page)
	require("Module:debug/track")("labels/" .. page)
end

function export.show(frame)
	local parent_args = frame:getParent().args
	local compat = (frame.args["compat"] or "") ~= "" and parent_args["lang"]
	local term_mode = (frame.args["term"] or "") ~= ""
	
	local params = {
		[1] = {required = true, type = "language", default = "und"},
		[2] = {required = true, list = true, default = "example"},
		["nocat"] = {type = "boolean"},
		["sort"] = {},
	}
	
	if compat then
		params["lang"] = params[1]
		params[1] = params[2]
		params[2] = nil
	end
	
	local args = require("Module:parameters").process(parent_args, params)
	
	-- Gather parameters
	local lang = args[compat and "lang" or 1]
	local labels = args[compat and 1 or 2]

	-- Temporary tracking for the weird arguments.
	if (args.sort) then
		track("sort")
	end
	return require(labels_module).show_labels {
		lang = lang,
		labels = labels,
		sort = args.sort,
		nocat = args.nocat,
		mode = term_mode and "term-label" or nil,
		ok_to_destructively_modify = true,
	}
end

return export
