#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname

templates = ["ar-tool noun", "ar-noun of place", "ar-instance noun"]


# Fix the template refs. If cap= is present, remove it; else, add lc=.
def fix_one_page_tool_place_noun(index, page):
    pagetitle = str(page.title())

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in templates:
            if getparam(t, "cap"):
                pagemsg("Template %s: Remove cap=" % tn)
                t.remove("cap")
            else:
                pagemsg("Template %s: Add lc=1" % tn)
                addparam(t, "lc", "1")
    changelog = "%s: If cap= is present, remove it, else add lc=" % t
    return str(parsed), changelog


parser = blib.create_argparser("Fix lc vs. cap in tool/place noun etym templates")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    fix_one_page_tool_place_noun,
    edit=True,
    stdin=True,
    default_refs=["Template:%s" % tn for tn in templates],
)
