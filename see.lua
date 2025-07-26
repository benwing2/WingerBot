local export = {}

local etymology_module = "Module:etymology"
local links_module = "Module:links"
local parameter_utilities_module = "Module:parameter utilities"
local parse_utilities_module = "Module:parse utilities"
local table_module = "Module:table"


local function term_already_linked(term)
	-- optimization to avoid unnecessarily loading [[Module:parse utilities]]
	return term:find("[<{]") and require(parse_utilities_module).term_already_linked(term)
end


function export.see(frame)
	local parent_args = frame:getParent().args

	local boolean = {type = "boolean"}
	local params = {
		[1] = {required = true, type = "language", default = "und"},
		[2] = {list = true, allow_holes = true},
		["noast"] = boolean,
		["and"] = boolean,
		["compare"] = boolean,
		["notes"] = true,
	}

    local m_param_utils = require(parameter_utilities_module)

	local param_mods = m_param_utils.construct_param_mods {
		{group = {"link", "ref", "l"}},
		-- For compatibility, we don't distinguish q= from q1= and qq= from q1=. FIXME: Maybe we should change this.
		{group = "q", separate_no_index = false},
	}
	
	local items, args = m_param_utils.parse_list_with_inline_modifiers_and_separate_params {
		params = params,
		param_mods = param_mods,
		raw_args = parent_args,
		termarg = 2,
		parse_lang_prefix = true,
		track_module = "see",
		sc = "sc.default",
	}

	local lang = args[1]
	local langcode = lang:getCode()

	if not next(items) and mw.title.getCurrentTitle().nsText == "Template" then
		items = { {term = "term"} }
	end

	local textparts = {}
	local function ins(text)
		table.insert(textparts, text)
	end
	if not args.noast then
		ins("* ")
	end
	ins("''")
	if args["and"] then
		ins("and ")
	end
	if args.compare then
		ins("compare with: ")
	else
		ins("see: ")
	end
	ins("''")

	local termparts = {}
	-- Make links out of all the parts
	for _, item in ipairs(items) do
		local result
		if item.lang then
			-- format_derived() processes per-item qualifiers, labels and references, but they end up on the wrong side
			-- of the source (at least on the left), so we need to move them up.
			local q = item.q
			local qq = item.qq
			local l = item.l
			local ll = item.ll
			local refs = item.refs
			item.q = nil
			item.qq = nil
			item.l = nil
			item.ll = nil
			item.refs = nil
			result = require(etymology_module).format_derived {
				terms = {item},
				sources = {item.lang},
				nocat = true,
				template_name = "see",
				q = q,
				qq = qq,
				l = l,
				ll = ll,
				refs = refs,
			}
		else
			local raw_term = item.alt or item.term
			if raw_term and term_already_linked(raw_term) then
				result = raw_term
			else
				item.lang = lang
				result = require(links_module).full_link(item, nil, false, "show qualifiers")
			end
		end

		table.insert(termparts, result)
	end

	if #termparts == 1 then
		ins(termparts[1])
	else
		ins(require(table_module).serialCommaJoin(termparts, {conj = "''and''"}))
	end

	if args.notes then
		ins(" ''")
		ins(args.notes)
		ins("''")
	end

	return table.concat(textparts)
end


return export
