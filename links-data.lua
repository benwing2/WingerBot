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

-- "Mammoth pages" are pages whose entries cannot be housed on a single page because of MediaWiki limits
data.mammoth_pages = {
	["a"] = true,
	["mammoth page test"] = true   -- required for testing purposes - please leave here
}

-- Mammoth pages contain only Translingual and English entries, if present.
-- The remaining L2s are placed on subpages. The same subpage titles are used
-- across all mammoth pages for the convenience of bot and script operators.
-- Assuming that most mammoth pages will be Latin-script terms, the
-- subpage groupings are determined by dividing the list of Latin-script
-- languages known to Wiktionary into two (three, ...) roughly equal
-- alphabetic divisions. This is easily done by looking at Petscan's output:
-- https://petscan.wmcloud.org/?sortby=title&language=en&ns%5B14%5D=1&categories=Latin+script+languages&project=wiktionary&doit=
-- The property value is a Lua pattern applied to the L2 name, or "true" for
-- the final catch-all subpage.
data.mammoth_page_subpage_list = {
	{"languages A to L", "^[A-LÀÁÄ]"},
	{"languages M to Z", true},
}

data.mammoth_page_subpages = {}
for _, subpage_spec in ipairs(data.mammoth_page_subpage_list) do
	local subpage, subpage_pattern = unpack(subpage_spec)
	data.mammoth_page_subpages[subpage] = true
end

return data
