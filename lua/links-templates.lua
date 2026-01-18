-- Prevent substitution.
if mw.isSubsting() then
	return require("Module:unsubst")
end

local export = {}

local links_module = "Module:links"
local process_params = require("Module:parameters").process
local remove = table.remove
local upper = require("Module:string utilities").upper

--[=[
	Modules used:
	[[Module:links]]
	[[Module:languages]]
	[[Module:scripts]]
	[[Module:parameters]]
	[[Module:debug]]
]=]

do
	local function get_args(frame)
		-- `compat` is a compatibility mode for {{term}}.
		-- If given a nonempty value, the function uses lang= to specify the
		-- language, and all the positional parameters shift one number lower.
		local iargs = frame.args
		iargs.compat = iargs.compat and iargs.compat ~= ""
		iargs.langname = iargs.langname and iargs.langname ~= ""
		iargs.notself = iargs.notself and iargs.notself ~= ""
		local alias_of_4 = {alias_of = 4}
		local boolean = {type = "boolean"}
		local params = {
			[1] = {required = true, type = "language", default = "und"},
			[2] = true,
			[3] = true,
			[4] = true,
			g = {list = true, type = "genders", flatten = true},
			gloss = alias_of_4,
			id = true,
			lit = true,
			ng = true,
			pos = true,
			sc = {type = "script"},
			t = alias_of_4,
			tr = true,
			ts = true,
			q = {type = "qualifier"},
			qq = {type = "qualifier"},
			l = {type = "labels"},
			ll = {type = "labels"},
			ref = {type = "references"},
			["accel-form"] = true,
			["accel-translit"] = true,
			["accel-lemma"] = true,
			["accel-lemma-translit"] = true,
			["accel-gender"] = true,
			["accel-nostore"] = boolean,
		}
		if iargs.compat then
			params.lang = {type = "language", default = "und"}
			remove(params, 1)
			alias_of_4.alias_of = 3
		end
		if iargs.langname then
			params.w = boolean
		end
		return process_params(frame:getParent().args, params), iargs
	end
	
	-- Used in [[Template:l]] and [[Template:m]].
	function export.l_term_t(frame)
		local args, iargs = get_args(frame)
		local compat = iargs.compat
		local lang = args[compat and "lang" or 1]
		
		-- Tracking for und.
		if not compat and lang:getCode() == "und" then
			require("Module:debug").track("link/und")
		end
		
		local term = args[(compat and 1 or 2)]
		local alt = args[(compat and 2 or 3)]
		term = term ~= "" and term or nil
		
		if not term and not alt and iargs.demo then
			term = iargs.demo
		end
		
		local langname = iargs.langname and (
			args.w and lang:makeWikipediaLink() or
			lang:getCanonicalName()
		) or nil
		
		if langname and term == "-" then
			return langname
		end
		-- Forward the information to full_link
		return (langname and langname .. " " or "") .. require(links_module).full_link(
			{
				lang = lang,
				sc = args.sc,
				track_sc = true,
				term = term,
				alt = alt,
				gloss = args[4],
				id = args.id,
				tr = args.tr,
				ts = args.ts,
				genders = args.g,
				pos = args.pos,
				ng = args.ng,
				lit = args.lit,
				q = args.q,
				qq = args.qq,
				l = args.l,
				ll = args.ll,
				refs = args.ref,
				show_qualifiers = true,
				accel = args["accel-form"] and {
					form = args["accel-form"],
					translit = args["accel-translit"],
					lemma = args["accel-lemma"],
					lemma_translit = args["accel-lemma-translit"],
					gender = args["accel-gender"],
					nostore = args["accel-nostore"],
				} or nil
			},
			iargs.face,
			not iargs.notself
		)
	end
	
	-- Used in [[Template:link-annotations]].
	function export.l_annotations_t(frame)
		local args, iargs = get_args(frame)
		
		-- Forward the information to format_link_annotations
		return require(links_module).format_link_annotations(
			{
				lang = args[1],
				tr = { args.tr },
				ts = { args.ts },
				genders = args.g,
				pos = args.pos,
				ng = args.ng,
				lit = args.lit
			},
			iargs.face
		)
	end
end

-- Used in [[Template:ll]].
do
	local function get_args(frame)
		return process_params(frame:getParent().args, {
			[1] = {required = true, type = "language", default = "und"},
			[2] = {allow_empty = true},
			[3] = true,
			id = true,
			sc = {type = "script"},
		})
	end
	
	function export.ll(frame)
		local args = get_args(frame)
		local lang = args[1]
		local sc = args.sc
		local term = args[2]
		term = term ~= "" and term or nil
		
		return require(links_module).language_link{
			lang = lang,
			sc = sc,
			term = term,
			alt = args[3],
			id = args.id
		} or "<small>[Term?]</small>" ..
			require("Module:utilities").format_categories(
				{lang:getFullName() .. " term requests"},
				lang, "-", nil, nil, sc
			)
	end
end

function export.def_t(frame)
	local args = process_params(frame:getParent().args, {
		[1] = {required = true, default = ""},
	})

	local face = frame.args.face

	local ret = require("Module:script utilities").tag_definition(require(links_module).embedded_language_links{
		term = args[1],
		lang = require("Module:languages").getByCode("en"),
		sc = require("Module:scripts").getByCode("Latn")
	}, face)

	if face == "non-gloss" then
		return ret
	end
	return '<span class="mention-gloss-paren">(</span>' .. ret .. '<span class="mention-gloss-paren">)</span>'
end


function export.linkify_t(frame)
	local args = process_params(frame:getParent().args, {
		[1] = {required = true, default = ""},
	})
	
	args[1] = mw.text.trim(args[1])
	
	if args[1] == "" or args[1]:find("[[", nil, true) then
		return args[1]
	end
	return "[[" .. args[1] .. "]]"
end

function export.cap_t(frame)
	local args = process_params(frame:getParent().args, {
		[1] = {required = true},
		[2] = true,
		lang = {type = "language", default = "en"},
	})
	
	local term = args[1]
	
	return require(links_module).full_link{
		lang = args.lang,
		term = term,
		alt = term:gsub("^.[\128-\191]*", upper) .. (args[2] or "")
	}
end

function export.section_link_t(frame)
	local args = process_params(frame:getParent().args, {
		[1] = {},
	})
	
	return require(links_module).section_link(args[1])
end

return export
