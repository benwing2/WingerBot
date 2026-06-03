#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, getparam, addparam, tname


def process_text_on_page(p):
    etym = False
    suffix = False
    if p.title.endswith("ية"):
        parsed = blib.parse_text(p.text)
        for t in parsed.filter_templates():
            if tname(t) in ["ar-etym-iyya", "ar-etym-nisba-a", "ar-etym-noun-nisba", "ar-etym-noun-nisba-linking"]:
                etym = True
            if tname(t) == "suffix":
                suffix = True
        if not etym:
            p.msg("Ends with -iyya, no appropriate etym template%s" % (" (has suffix template)" if suffix else ""))


parser = blib.create_argparser("Find Arabic -iyya nouns without etymology", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Arabic nouns"])
