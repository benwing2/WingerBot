#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, getparam, addparam, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    etym = False
    suffix = False
    if pagetitle.endswith("ية"):
        parsed = blib.parse_text(text)
        for t in parsed.filter_templates():
            if tname(t) in ["ar-etym-iyya", "ar-etym-nisba-a", "ar-etym-noun-nisba", "ar-etym-noun-nisba-linking"]:
                etym = True
            if tname(t) == "suffix":
                suffix = True
        if not etym:
            pagemsg("Ends with -iyya, no appropriate etym template%s" % (" (has suffix template)" if suffix else ""))


parser = blib.create_argparser("Find Arabic -iyya nouns without etymology", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Arabic nouns"])
