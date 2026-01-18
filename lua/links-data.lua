local data = {}

local unpack = unpack or table.unpack -- Lua 5.2 compatibility
local u = require("Module:string utilities").char

data.phonetic_extraction = {
	["th"] = "Module:th",
	["km"] = "Module:km",
}

data.ignored_prefixes = {
	["cat"] = true,
	["category"] = true,
	["file"] = true,
	["image"] = true
}

-- Scheme for using unsupported characters in titles.
data.unsupported_characters = {
	["#"] = "`num`",
	["%"] = "`percnt`", -- only escaped in percent encoding
	["&"] = "`amp`", -- only escaped in HTML entities
	["."] = "`period`", -- only escaped in dot-slash notation
	["<"] = "`lt`",
	[">"] = "`gt`",
	["["] = "`lsqb`",
	["]"] = "`rsqb`",
	["_"] = "`lowbar`",
	["`"] = "`grave`", -- used to enclose unsupported characters in the scheme, so a raw use in an unsupported title must be escaped to prevent interference
	["{"] = "`lcub`",
	["|"] = "`vert`",
	["}"] = "`rcub`",
	["~"] = "`tilde`", -- only escaped when 3 or more are consecutive
	["\239\191\189"] = "`repl`" -- replacement character U+FFFD, which can't be typed directly here due to an abuse filter
}

-- Manually specified unsupported titles. Only put titles here if there is a different reason why they are unsupported, and not just because they contain one of the unsupported characters above.
data.unsupported_titles = {
	[" "] = "Space",
	["&amp;"] = "`amp`amp;",
	["λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων"] = "Ancient Greek dish",
	["กรุงเทพมหานคร อมรรัตนโกสินทร์ มหินทรายุธยา มหาดิลกภพ นพรัตนราชธานีบูรีรมย์ อุดมราชนิเวศน์มหาสถาน อมรพิมานอวตารสถิต สักกะทัตติยวิษณุกรรมประสิทธิ์"] = "Thai name of Bangkok",
	[u(0x1680)] = "Ogham space",
	[u(0x3000)] = "Ideographic space"
}

-- Mammoth pages contain only Translingual and English entries, if present. The remaining L2s are placed on subpages.
-- The same subpage titles are used across all mammoth pages for the convenience of bot and script operators.
-- Assuming that most mammoth pages will be Latin-script terms, the subpage groupings are determined by dividing the
-- list of Latin-script languages known to Wiktionary into two (three, ...) roughly equal alphabetic divisions. This is
-- easily done by looking at Petscan's output:
-- https://petscan.wmcloud.org/?sortby=title&language=en&ns%5B14%5D=1&categories=Latin+script+languages&project=wiktionary&doit=
-- This data structure contains types of splits, each of which is a list of names of splits and Lua patterns applied to
-- the decomposed L2 name (with apostrophes and double quotes removed and certain other transformations applied; see
-- get_L2_sort_key() in [[Module:headword/page]]), or "true" for the final catch-all subpage (which includes anything
-- not beginning with a Latin letter after the transformations are applied; this includes e.g. ǃKung but not 'Are'are,
-- which sorts with A, and not Àhàn, which likewise sorts with A). The patterns must be suitable for use with plain
-- string functions, not their mw.ustring equivalents.
data.mammoth_page_subpage_types = {
	twos = {
		{"languages A to L", "^[A-L]"},
		{"languages M to Z", true},
	},
	threes = {
		{"languages A to I", "^[A-I]"},
		{"languages J to Q", "^[J-Q]"},
		{"languages R to Z", true},
	},
	CJK = {
		{"languages A to C", "^[A-C]"}, -- Translingual and Chinese on one page
		{"languages D to Z", true}, -- all the remainder (mostly Japanese, Korean, Vietnamese) on the other
	},
}

-- "Mammoth pages" are pages whose entries cannot be housed on a single page because of MediaWiki limits. The key is
-- the page and the value is the subpage type, as defined above in `mammoth_page_subpage_types`.
data.mammoth_pages = {
	["a"] = "twos", -- FIXME: change to threes
	["mammoth page test"] = "twos",   -- required for testing purposes - please leave here
}

return data
