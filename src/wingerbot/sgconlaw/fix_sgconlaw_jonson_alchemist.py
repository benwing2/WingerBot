#!/usr/bin/env python3

# Reduce page number by one for {{RQ:Jonson Alchemist}}.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, errmsg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "RQ:Jonson Alchemist":
            page = getparam(t, "page")
            if page:
                if re.search("^[0-9]+$", page):
                    newpage = int(page) - 1
                    t.add("page", str(newpage))
                    notes.append("reduce page by one in {{RQ:Jonson Alchemist}}")
                else:
                    p.msg("WARNING: Bad value page=%s: %s" % (page, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Reduce page by one for {{RQ:Jonson Alchemist}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:RQ:Jonson Alchemist"]
)
