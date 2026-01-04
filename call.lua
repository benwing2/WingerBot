local export = {}

function export.call(frame)
	local frame_args = frame.args
	local parent_args = frame:getParent().args
	local args = {}
	local template = frame_args[1]
	for k, v in pairs(parent_args) do
		args[k] = v
	end
	for k, v in pairs(frame_args) do
		if k == 1 then
		elseif type(k) == "number" then
			args[k - 1] = v
		else
			args[k] = v
		end
	end
	return frame:expandTemplate{title = template, args = args}
end

return export

-- For Vim, so we get 4-space tabs
-- vim: set ts=4 sw=4 noet:
