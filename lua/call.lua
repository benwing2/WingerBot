local export = {}

local u = mw.ustring.char

local TEMP1 = u(0xFFF0)

-- Fancy version of ine() (if-not-empty). Converts empty string to nil, but also strips leading/trailing space.
local function ine(arg)
	if not arg then return nil end
	arg = mw.text.trim(arg)
	if arg == "" then return nil end
	return arg
end

function export.call(frame)
	local direct_args = frame.args
	local parent_args = frame:getParent().args
	local args = {}
	local template = direct_args[1]
	-- Processing parent args must come first so that direct args override parent args. Note that if a direct arg is
	-- specified but is blank, it will still override the parent arg (with nil).
	for k, v in pairs(parent_args) do
		args[k] = ine(v)
	end
	local ignores = ine(direct_args["@ignore"])
	if ignores then
		ignores = ignores:gsub(", ", TEMP1 .. " ")
		for ignore in mw.text.gsplit(ignores, ",", true) do
			ignore = ignore:gsub(TEMP1, ",")
			if ignore:match("^[0-9]+$") then
				ignore = tonumber(ignore)
			end
			args[ignore] = nil
		end
	end 

	-- Process @error_if. The value of `@error_if` is a comma-separated list of parameter names to throw an error if seen
	-- in parent_args (they are params we overwrite in the direct args).
	local error_ifs = ine(direct_args["@error_if"])
	if error_ifs then
		-- FIXME: This loop duplicates the loop for @ignore. We should create an iterator to abstract the functionality.
		error_ifs = error_ifs:gsub(", ", TEMP1 .. " ")
		for error_if in mw.text.gsplit(error_ifs, ",", true) do
			error_if = error_if:gsub(TEMP1, ",")
			if error_if:match("^[0-9]+$") then
				error_if = tonumber(error_if)
			end
			if ine(parent_args[error_if]) then
				error(
					("Cannot specify a value |%s=%s as it would be overwritten or ignored"):format(
						error_if,
						ine(parent_args[error_if])
					)
				)
			end
		end
	end

	for k, v in pairs(direct_args) do
		if k == 1 or k == "@ignore" or k == "@error_if" then
		elseif type(k) == "number" then
			-- Since we pass the template in 1=, we need to move all numbered args down by one.
			-- An alternative is to pass the template in e.g. @template.
			args[k - 1] = ine(v)
		else
			args[k] = ine(v)
		end
	end
	return frame:expandTemplate{title = template, args = args}
end

return export
