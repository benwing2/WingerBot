local raw_categories = {}
local raw_handlers = {}

local concat = table.concat
local insert = table.insert

local string_utilities_module = "Module:string utilities"


-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Wiktionary"] = {
	description = "High level category for material about Wiktionary and its operation.",
	parents = "Fundamental",
}

raw_categories["Wiktionary statistics"] = {
	description = "Categories and pages containing statistics about how Wiktionary is used.",
	parents = {"Wiktionary", sort = "Statistics"},
}

raw_categories["Wiktionary users"] = {
	description = "Pages listing Wiktionarians according to their user rights and categories listing Wiktionarians according to their linguistic and coding abilities.",
	breadcrumb = "Users",
	additional = "For an automatically generated list of all users, see [[Special:ListUsers]].",
	parents = {"Wiktionary", sort = "Users"},
}

raw_categories["Wikimedians banned by the WMF"] = {
	description = "Users who have received a [[m:Global bans|global ban]] imposed by the [[m:Wikimedia Foundation|Wikimedia Foundation]], in accordance with the [[m:WMF Global Ban Policy|WMF Global Ban Policy]].",
	breadcrumb = "Banned by the WMF",
	parents = "Wiktionary users",
}

raw_categories["User languages"] = {
	description = "Categories listing Wiktionarians according to their linguistic abilities.",
	parents = {
		"Wiktionary users",
		"Category:Wiktionary multilingual issues",
	},
}

raw_categories["User languages with invalid code"] = {
	description = "Categories listing Wiktionarians according to their linguistic abilities, where the language code is invalid for Wiktionary.",
	additional = "Most of these codes are valid ISO 639-3 codes but are invalid in Wiktionary for various reasons, " ..
	"typically due to different choices made regarding splitting and merging languages.",
	parents = {name = "User languages", sort = " "},
}

raw_categories["User scripts"] = {
	description = "Categories listing Wiktionarians according to their abilities to read a given script.",
	parents = {
		"Wiktionary users",
		"Category:Wiktionary multilingual issues",
	},
}

raw_categories["User coders"] = {
	description = "Categories listing Wiktionarians according to their coding abilities.",
	parents = "Wiktionary users",
}

raw_categories["User families"] = {
	description = "Categories listing Wiktionarians according to their knowledge about a given language family.",
	parents = "Wiktionary users"
}

raw_categories["Pages with entries"] = {
	description = "Pages which contain language entries.",
	additional = "The subcategories within this category are used to determine the total number of entries on the English Wiktionary.",
	parents = "Wiktionary",
	can_be_empty = true,
	hidden = true,
}

raw_categories["Redirects connected to a Wikidata item"] = {
	description = "Redirect pages which are connected to a [[d:|Wikidata]] item.",
	additional = "These are rarely needed, but are occasionally useful following a page merger, where other wikis may still separate the two.",
	parents = "Wiktionary statistics",
	can_be_empty = true,
	hidden = true,
}

raw_categories["Unsupported titles"] = {
	description = "Pages with titles that are not supported by the MediaWiki software.",
	additional = "For an explanation of the reasons why certain titles are not supported, see [[Appendix:Unsupported titles]].",
	parents = "Wiktionary",
	can_be_empty = true,
	hidden = true,
}

-- Tracked according to [[phab:T347324]].
for ext, data in pairs {
	["DynamicPageList"] = {"DynamicPageList (Wikimedia)", "T287380"},
	["EasyTimeline"] = {"EasyTimeline", "T137291"},
	["Graph"] = {"Graph", "T334940"},
	["Kartographer"] = {"Kartographer"},
	["Phonos"] = {"Phonos"},
	["Score"] = {"Score"},
	["WikiHiero"] = {"WikiHiero", "T344534"},
} do
	local link, phab = unpack(data)
	raw_categories["Pages using the " .. ext .. " extension"] = {
		description = ("Pages which make use of the [[mw:Extension:%s|%s]] extension."):format(link, ext),
		additional = phab and ("See [[phab:%s|%s]] on Phabricator for background information on why this extension is tracked."):format(phab, phab) or nil,
		breadcrumb = ("Using the %s extension"):format(ext),
		parents = "Wiktionary statistics",
		can_be_empty = true,
		hidden = true,
	}
end

-----------------------------------------------------------------------------
--                                                                         --
--                                RAW HANDLERS                             --
--                                                                         --
-----------------------------------------------------------------------------


local function get_level_params(data)
	local speak_verb = "speak"
	if data.typ == "lang" then
		local is_sign_language = data.obj and data.obj:getFamilyCode():find("^sgn") or data.lang:find("Sign Language$")
		speak_verb = data.args.verb or is_sign_language and "communicate in" or "speak"
	end
	return {
		["-"] = {
			leftcolor = "#99B3FF",
			rightcolor = "#E0E8FF",
			lang = "These users " .. speak_verb .. " LANGFAM.",
			script = "These users read SCRIPT.",
			coder = "These users know how to code in LANGFAM.",
			family = "These users know LANGFAM.",
		},
		["0"] = {
			leftcolor = "#FFB3B3",
			rightcolor = "#FFE0E8",
			lang = "These users do not understand LANGFAM (or understand it with considerable difficulty).",
			script = "These users '''cannot''' read SCRIPT.",
			coder = "These users know '''little''' about LANGFAM and just mimic existing usage.",
			family = "These users '''cannot''' contribute to LANGFAM."
		},
		["1"] = {
			leftcolor = "#C0C8FF",
			rightcolor = "#F0F8FF",
			lang = "These users " .. speak_verb .. " LANGFAM at a '''basic''' level.",
			script = "These users can read SCRIPT at a '''basic''' level.",
			coder = "These users know the '''basics''' of how to write LANGFAM code and make minor tweaks.",
			family = "These users know the '''basics''' of contributing to LANGFAM.",
		},
		["2"] = {
			leftcolor = "#77E0E8",
			rightcolor = "#D0F8FF",
			lang = "These users " .. speak_verb .. " LANGFAM at an '''intermediate''' level.",
			script = "These users can read SCRIPT at an '''intermediate''' level.",
			coder = "These users have a '''fair command''' of LANGFAM, and can understand some scripts written by others.",
			family = "These users are '''fairly familiar''' with LANGFAM.",
		},
		["3"] = {
			leftcolor = "#99B3FF",
			rightcolor = "#E0E8FF",
			lang = "These users " .. speak_verb .. " LANGFAM at an '''advanced''' level.",
			script = "These users can read SCRIPT at an '''advanced''' level.",
			coder = "These users can write '''more complex''' LANGFAM code, and can understand and modify most scripts written by others.",
			family = "These users '''regularly''' contribute to LANGFAM.",
		},
		["4"] = {
			leftcolor = "#CCCC00",
			rightcolor = "#FFFF99",
			lang = "These users " .. speak_verb .. " LANGFAM at a '''near-native''' level.",
			script = "These users can read SCRIPT at a '''near native''' level.",
			coder = "These users can write and understand '''very complex''' LANGFAM code.",
		},
		["5"] = {
			leftcolor = "#D6A6F0",
			rightcolor = "#F3E4FA",
			lang = "These users " .. speak_verb .. " LANGFAM at a '''professional''' level.",
			script = "These users can read SCRIPT at a '''professional''' level.",
			coder = "These users can write and understand LANGFAM code at a '''professional''' level.",
		},
		["N"] = {
			leftcolor = "#6EF7A7",
			rightcolor = "#C5FCDC",
			lang = "These users are '''native''' speakers of LANGFAM.",
			script = "These users' '''native''' script is SCRIPT.",
		},
	}
end


local coder_links = {
	Asm = "w:Assembly language",
	Bash = "w:Bash (Unix shell)",
	C = "w:C (programming language)",
	["C++"] = "w:C++",
	["C Sharp"] = {link = "w:C Sharp (programming language)", lang = "C&#035;"},
	CSS = "w:CSS",
	Go = "w:Go (programming language)",
	Haskell = "w:Haskell",
	HTML = "w:HTML",
	Java = "w:Java (programming language)",
	JavaScript = "w:JavaScript",
	Julia = "w:Julia (programming language)",
	Kotlin = "w:Kotlin (programming language)",
	Lisp = "w:Lisp (programming language)",
	Lua = "Wiktionary:Scripting",
	Perl = "w:Perl",
	PHP = "w:PHP",
	Python = "w:Python (programming language)",
	regex = {link = "w:Regular expression", name = "regular expressions"},
	Ruby = "w:Ruby (programming language)",
	Rust = "w:Rust (programming language)",
	Scala = "w:Scala (programming language)",
	Scheme = "w:Scheme (programming language)",
	SQL = "w:SQL",
	template = {link = "Wiktionary:Templates", name = "wiki templates"},
	Typescript = "w:Typescript",
	VBScript = "w:VBScript",
}


-- Generic implementation of competency handler for (natural) languages, scripts, and "coders" (= programming languages).
local function competency_handler(data)
	local category = data.category
	local langtext = data.langtext
	local typ = data.typ
	local args = data.args
	local code = data.code
	local langfam = data.langfam
	local langfamcat = data.langfamcat
	local script = data.script
	local scriptcat = data.scriptcat
	local level = data.level
	local parents = data.parents
	local addl_parents = data.addl_parents
	local topright = data.topright
	local data_addl = data.additional
	local inactive = data.inactive

	local parts = {}
	local function ins(txt)
		insert(parts, txt)
	end
	local level_params = get_level_params(data)

	local params = level_params[level or "-"]
	if not params then
		error(("Internal error: No params for for code '%s', level %s"):format(code, level or "-"))
	end
	local function insert_text()
		if langtext then
			ins(langtext)
			ins("<hr />")
		end
		if not params[typ] then
			error(("No English text for code '%s', type '%s', level %s"):format(code, typ, level or "-"))
		end
		local pattern, repl
		if typ == "script" then
			pattern = "SCRIPT"
			repl = ("'''" .. scriptcat .. "'''"):format(script)
		else
			pattern = "LANGFAM"
			repl = ("'''" .. langfamcat .. "'''"):format(langfam)
			if sc then
				repl = repl .. (" written in '''" .. scriptcat .. "'''"):format(script)
			end
		end
		ins(params[typ]:gsub(pattern, repl))
	end

	local additional = {}
	if level then
		insert(additional, ("To be included on this list, add {{tl|Babel|%s}} to your user page. Complete instructions are " ..
			"available at [[Wiktionary:Babel]]."):format(level == "N" and code or ("%s-%s"):format(code, level)))
	else
		insert(additional, "To be included on this list, use {{tl|Babel}} on your user page. Complete instructions are " ..
			"available at [[Wiktionary:Babel]].")
	end

	if inactive then
		insert(additional, "'''NOTE:''' Users in this category have not been active on the English Wiktionary for at " ..
			"least two years and have been moved into the 'inactive' state due to " ..
			"[[Wiktionary:Votes/pl-2017-04/Removing inactive editors from user-proficiency categories]].")
		parents = {{name = category, sort = " "}}
	end
	if addl_parents then
		for _, addl_parent in ipairs(addl_parents) do
			insert(parents, addl_parent)
		end
	end
	
	if data_addl then
		insert(additional, data_addl)
	end

	if level then
		ins(('<div style="float:left;border:solid %s 1px;margin:1px">'):format(params.leftcolor))
		ins(('<table cellspacing="0" style="width:238px;background:%s"><tr>'):format(params.rightcolor))
		ins(('<td style="width:45px;height:45px;background:%s;text-align:center;font-size:14pt">'):format(params.leftcolor))
		ins(("'''%s-%s'''</td>"):format(code, level))
		ins('<td style="font-size:8pt;padding:4pt;line-height:1.25em">')
		insert_text()
		ins('</td></tr></table></div><br clear="left">')

		return {
			description = concat(parts),
			additional = concat(additional, "\n\n"),
			breadcrumb = inactive and "Inactive" or "Level " .. level,
			parents = parents,
		}, not not args
	else
		ins(('<div style="float:left;border:solid %s 1px;margin:1px;">\n'):format(params.leftcolor))
		ins(('{| cellspacing="0" style="width:260px;background:%s;"\n'):format(params.rightcolor))
		ins(('| style="width:45px;height:45px;background:%s;text-align:center;font-size:14pt;" | '):format(params.leftcolor))
		ins(("'''%s'''\n"):format(code))
		ins('| style="font-size:8pt;padding:4pt;line-height:1.25em;text-align:center;" | ')
		insert_text()
		ins('\n|}</div><br clear="left">')

		return {
			topright = topright,
			description = concat(parts),
			additional = concat(additional, "\n\n"),
			breadcrumb = inactive and "Inactive" or lang,
			parents = parents,
		}, not not args
	end
end


local function handle_user_lang_maybe_script(data, category, inactive, code, sccode, level, args)
	local lang = require("Module:languages").getByCode(code, nil, "allow etym")
	local langname = args.langname
	local sc, scriptname
	if sccode then
		sc = require("Module:scripts").getByCode(sccode)
		scriptname = args.scriptname
	end
	local code_with_script = code .. (sccode and "-" .. sccode or "")

	if not lang or sccode and not sc then
		-- If unrecognized language and called from inside, we're handling the parents and breadcrumb for a
		-- higher-level category, so at least return something.
		if not level and data.called_from_inside then
			return {
				-- FIXME, scrape langname= category?
				breadcrumb = {name = code_with_script, nocap = true},
				parents = {name = lang and "User languages with invalid script code" or
					"User languages with invalid code", sort = code_with_script}
			}, true
		end
		
		if not langname then
			-- Check if the code matches a Wikimedia language (e.g. "ku" for Kurdish). If it does, treat
			-- its canonical name as though it had been given as langname=.
			local wm_lang = require("Module:wikimedia languages").getByCode(code)
			if not wm_lang then
				mw.log(("Skipping category '%s' because lang code '%s' is unrecognized and langname= not given"):
					format(data.category, code))
				return
			end
			langname = wm_lang:getCanonicalName()
		end
		if sccode and not sc and not scriptname then
			mw.log(("Skipping category '%s' because script code '%s' is unrecognized and scriptname= not given"):
				format(data.category, sccode))
			return
		end
	end

	if not langname then
		if not lang then
			error("Internal error: Something went wrong, undefined lang= should have been caught above")
		end
		langname = lang:getCanonicalName()
	end
	if not scriptname and sccode then
		if not sc then
			error("Internal error: Something went wrong, undefined sc= should have been caught above")
		end
		scriptname = sc:getCanonicalName()
	end

	-- Insert text, appropriately script-tagged, unless already script-tagged (we check for '<span'), in which case we
	-- insert it directly. Also handle <<...>> and <<<...>>> in text and convert to bolded link to parent category.
	local function wrap(txt)
		if not txt then
			return
		end
		if sccode then
			-- Substitute <<<...>>> (where ... is supposed to be the native rendering of the script) with a link to the
			-- top-level 'User SCRIPT' category (e.g. [[:Category:User Kore]] if we're in a sublevel category, or to the
			-- top-level script category (e.g. [[:Category:Korean script]]) if we're in a top-level 'User CODE-SCRIPT'
			-- category.
			txt = txt:gsub("<<<(.-)>>>", function(inside)
				if level then
					return ("'''[[:Category:User %s|%s]]'''"):format(sccode, inside)
				elseif sc then
					return ("'''[[:Category:%s|%s]]'''"):format(sc:getCategoryName(), inside)
				else
					return ("'''%s'''"):format(inside)
				end
			end)
		end
		-- Substitute <<...>> (where ... is supposed to be the native rendering of the language) with a link to the
		-- top-level 'User CODE' category (e.g. [[:Category:User fr]] or [[:Category:User fr-CA]]) if we're in a
		-- sublevel category, or to the top-level language category (e.g. [[:Category:French language]] or
		-- [[:Category:Canadian English]]) if we're in a top-level 'User CODE' category.
		txt = txt:gsub("<<(.-)>>", function(inside)
			if level then
				return ("'''[[:Category:User %s|%s]]'''"):format(code, inside)
			elseif lang then
				return ("'''[[:Category:%s|%s]]'''"):format(lang:getCategoryName(), inside)
			else
				return ("'''%s'''"):format(inside)
			end
		end)
		if txt:find("<span") or not lang then
			return txt
		else
			return require("Module:script utilities").tag_text(txt, lang, sc)
		end
	end

	local function get_request_cats()
		if args.text or code == "en" or code:find("^en%-") then
			return
		end
		local num_pages = mw.site.stats.pagesInCategory(data.category, "pages")
		local count_cat, count_sort
		if num_pages == 0 then
			count_cat = "Requests for translations in user-competency categories with 0 users"
			count_sort = "*" .. code_with_script
		elseif num_pages == 1 then
			count_cat = "Requests for translations in user-competency categories with 1 user"
			count_sort = "*" .. code_with_script
		else
			local lowernum, uppernum
			lowernum = 2
			while true do
				uppernum = lowernum * 2 - 1
				if num_pages <= uppernum then
					break
				end
				lowernum = lowernum * 2
			end
			count_cat = ("Requests for translations in user-competency categories with %s-%s users"):format(
				lowernum, uppernum)
			count_sort = "*" .. ("%0" .. #(tostring(uppernum)) .. "d"):format(num_pages)
		end

		local addl_parents = {}
		insert(addl_parents, {
			name = "Requests for translations in user-competency categories by language",
			sort = code_with_script,
		})
		insert(addl_parents, {
			name = count_cat,
			sort = count_sort,
		})
		return addl_parents
	end

	local invalid_lang_warning
	if not lang then
		invalid_lang_warning = "'''WARNING''': The specified language code is invalid on Wiktionary. Please migrate " ..
			"all competency ratings to the closest valid code."
	end

	local parents
	if level then
		parents = {("User %s"):format(code_with_script), sort = level}
	elseif sccode then
		parents = {}
		insert(parents, {name = ("User %s"):format(code), sort = sccode})
		insert(parents, {name = ("User %s"):format(sccode), sort = code})
	elseif lang then
		parents = {}
		if lang:hasType("etymology-only") then
			local full_code = lang:getFullCode()
			local sort_key = code:gsub(("^%s%%-"):format(require(string_utilities_module).pattern_escape(full_code)),
				"")
			insert(parents,	{name = ("User %s"):format(full_code), sort = sort_key})
		else
			insert(parents, {name = "User languages", sort = code})
		end
		insert(parents, {name = lang:getCategoryName(), sort = "user"})
	else
		parents = {"User languages with invalid code", sort = code}
	end
	local addl_parents = get_request_cats()

	local topright
	if args.commonscat then
		local commonscat = require("Module:yesno")(args.commonscat, "+")
		if commonscat == "+" or commonscat == true then
			commonscat = data.category
		end
		if commonscat then
			topright = ("{{commonscat|%s}}"):format(commonscat)
		end
	end

	local langcat
	if level then
		langcat = ("[[:Category:User %s|%%s]]"):format(code)
	elseif lang then
		langcat = ("[[:Category:%s|%%s]]"):format(lang:getCategoryName())
	else
		langcat = "[[%s]]"
	end

	local scriptcat
	if level then
		scriptcat = ("[[:Category:User %s|%%s]]"):format(sccode)
	elseif sc then
		scriptcat = ("[[:Category:%s|%%s]]"):format(sc:getCategoryName())
	else
		scriptcat = "[[%s]]"
	end

	return competency_handler {
		category = category,
		inactive = inactive,
		langtext = wrap(args.text),
		typ = "lang",
		args = args,
		obj = lang,
		code = code_with_script,
		langfam = langname,
		langfamcat = langcat,
		script = scriptname,
		scriptcat = scriptcat,
		level = level,
		parents = parents,
		addl_parents = addl_parents,
		topright = topright,
		additional = invalid_lang_warning,
	}
end

-- Hander for categories named [[Category:User LANG-SCRIPT]] or [[Category:User LANG-SCRIPT-#]] where # is a
-- competency level (0 through 5 or N), e.g. [[Category:zh-Hans]] or [[Category:yue-Hant-N]]. It's a bit tricky because
-- of the multitude of language formats, e.g. ko-KP is a language code (etym variety) but ko-Kore is a combination
-- lang + script code. We depend on the fact that all script codes are currently of the form Xxxx or Xxxxx, and check
-- for that first. We also need to run prior to the lang-only handler (next handler) so it doesn't try to interpret
-- the script code as an etym variant code.
--
-- Note that there are current categories named things like 'zh-Hant-TW' and 'zh-Hant-HK-3', which we don't support.
-- They should be renamed to some supported code, e.g. 'cmn-TW-Hant' and 'yue-HK-Hant-3'.
insert(raw_handlers, function(data)
	local category, inactive = data.category:match("^(.*) (%(inactive%))$")
	category = category or data.category
	local code, sccode, level = category:match("^User ([a-z][a-z][a-z]?)%-([A-Z][a-z][a-z][a-z][a-z]?)%-([0-5N])$")
	if not code then
		code, sccode, level =
			category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)%-([A-Z][a-z][a-z][a-z][a-z]?)%-([0-5N])$")
	end
	if not code then
		code, sccode = category:match("^User ([a-z][a-z][a-z]?)%-([A-Z][a-z][a-z][a-z][a-z]?)$")
	end
	if not code then
		code, sccode = category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)%-([A-Z][a-z][a-z][a-z][a-z]?)$")
	end
	if not code then
		return
	end

	local args = require("Module:parameters").process(data.args, {
		text = true,
		verb = true,
		langname = true,
		scriptname = true,
		scname = {alias_of = "scriptname"},
		commonscat = true,
	})
	
	return handle_user_lang_maybe_script(data, category, inactive, code, sccode, level, args)
end)

-- Hander for categories named [[Category:User LANG]] e.g. [[Category:User en]], [[Category:User en-US]],
-- [[Category:User ine-pro]] or [[Category:User LANG-#]] where # is a competency level (0 through 5 or N) e.g.
-- [[Category:User en-N]] or [[Category:User ndl-nl-1]].
insert(raw_handlers, function(data)
	local category, inactive = data.category:match("^(.*) (%(inactive%))$")
	category = category or data.category
	local code, level = category:match("^User ([a-z][a-z][a-z]?)%-([0-5N])$")
	if not code then
		code, level = category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)%-([0-5N])$")
	end
	if not code then
		code = category:match("^User ([a-z][a-z][a-z]?)$")
	end
	if not code then
		code = category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)$")
	end
	if not code then
		return
	end

	local args = require("Module:parameters").process(data.args, {
		text = true,
		verb = true,
		langname = true,
		commonscat = true,
	})

	return handle_user_lang_maybe_script(data, category, inactive, code, nil, level, args)
end)


insert(raw_handlers, function(data)
	local category, inactive = data.category:match("^(.*) (%(inactive%))$")
	category = category or data.category
	local code, level = category:match("^User ([A-Z][a-z][a-z][a-z][a-z]?)%-([0-5N])$")
	if not code then
		code = category:match("^User ([A-Z][a-z][a-z][a-z][a-z]?)$")
	end
	if not code then
		code, level = category:match("^User ([a-z][a-z][a-z]?%-[A-Z][a-z][a-z][a-z][a-z]?)%-([0-5N])$")
	end
	if not code then
		code = category:match("^User ([a-z][a-z][a-z]?%-[A-Z][a-z][a-z][a-z][a-z]?)$")
	end
	if not code then
		return
	end
	local sc = require("Module:scripts").getByCode(code)
	if not sc then
		return
	end

	local parents
	if level then
		parents = {("User %s"):format(code), sort = level}
	else
		parents = {
			{name = "User scripts", sort = code},
			{name = sc:getCategoryName(), sort = "user"},
		}
	end

	local scriptcat
	-- Better to display 'Foo script' than just 'Foo', as so many scripts are the same as language names.
	if level then
		scriptcat = ("[[:Category:User %s|%s]]"):format(code, sc:getCategoryName())
	else
		scriptcat = ("[[:Category:%s|%s]]"):format(sc:getCategoryName(), sc:getCategoryName())
	end

	return competency_handler {
		category = category,
		inactive = inactive,
		typ = "script",
		obj = sc,
		code = code,
		script = sc:getCanonicalName(),
		scriptcat = scriptcat,
		level = level,
		parents = parents,
	}
end)

insert(raw_handlers, function(data)
	local category, inactive = data.category:match("^(.*) (%(inactive%))$")
	category = category or data.category
	local code, level
	if not code then
		code, level = category:match("^User ([A-Za-z+-]+) coder%-([0-5N])$")
	end
	if not code then
		code = category:match("^User ([A-Za-z+-]+) coder$")
	end
	if not code or not coder_links[code] then
		return
	end

	local parents
	if level then
		parents = {("User %s coder"):format(code), sort = level}
	else
		parents = {"User coders", sort = code}
	end

	local langdata = coder_links[code]
	if type(langdata) == "string" then
		langdata = {link = langdata}
	end

	local langcat = ("[[%s|%%s]]"):format(langdata.link)

	return competency_handler {
		category = category,
		inactive = inactive,
		typ = "coder",
		code = code,
		langfam = langdata.lang or code,
		langfamcat = langcat,
		level = level,
		parents = parents,
	}
end)

insert(raw_handlers, function(data)
	local category, inactive = data.category:match("^(.*) (%(inactive%))$")
	category = category or data.category
	local code, level = category:match("^User ([a-z][a-z][a-z]?)%-([0-5N])$")
	if not code then
		code, level = category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)%-([0-5N])$")
	end
	if not code then
		code = category:match("^User ([a-z][a-z][a-z]?)$")
	end
	if not code then
		code = category:match("^User ([a-z][a-z][a-z]?%-[a-zA-Z-]+)$")
	end
	if not code then
		return
	end
	local fam = require("Module:families").getByCode(code)
	if not fam then
		return
	end

	local parents
	if level then
		parents = {("User %s"):format(code), sort = level}
	else
		parents = {
			{name = "User families", sort = code},
			{name = fam:getCategoryName(), sort = "user"},
		}
	end

	local famcat
	if level then
		famcat = ("[[:Category:User %s|%s]]"):format(code, fam:getCategoryName())
	else
		famcat = ("[[:Category:%s|%s]]"):format(fam:getCategoryName(), fam:getCategoryName())
	end

	return competency_handler {
		category = category,
		inactive = inactive,
		typ = "family",
		obj = fam,
		code = code,
		langfam = fam:getCanonicalName(),
		langfamcat = famcat,
		level = level,
		parents = parents,
	}
end)

insert(raw_handlers, function(data)
	local n, suffix = data.category:match("^Pages with (%d+) entr(.+)$")
	-- Only match if there are no leading zeroes and the suffix is correct.
	if not (n and not n:match("^0%d") and suffix == (n == "1" and "y" or "ies")) then
		return
	end
	return {
		breadcrumb = ("%d entr%s"):format(n, suffix),
		description = ("Pages which contain %s language entr%s."):format(n, suffix),
		additional = "This category, and others like it, are used to determine the total number of entries on the English Wiktionary",
		hidden = true,
		can_be_empty = true,
		parents = {
			{name = "Pages with entries", sort = require("Module:category tree").numeral_sortkey(n)},
			n == "0" and "Wiktionary maintenance" or nil, -- "Pages with 0 entries" only contains pages with something wrong.
		},
	}
end)


return {RAW_CATEGORIES = raw_categories, RAW_HANDLERS = raw_handlers}
