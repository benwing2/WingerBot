#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname

templates = ["ar-tool noun", "ar-noun of place", "ar-instance noun"]


# Fix the template refs. If cap= is present, remove it; else, add lc=.
def fix_one_page_tool_place_noun(p):
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in templates:
            if getparam(t, "cap"):
                p.msg("Template %s: Remove cap=" % tn)
                t.remove("cap")
            else:
                p.msg("Template %s: Add lc=1" % tn)
                addparam(t, "lc", "1")
    changelog = "%s: If cap= is present, remove it, else add lc=" % t
    return str(parsed), changelog


parser = blib.create_argparser("Fix lc vs. cap in tool/place noun etym templates",
                               include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    fix_one_page_tool_place_noun,
    default_refs=["Template:%s" % tn for tn in templates],
)
