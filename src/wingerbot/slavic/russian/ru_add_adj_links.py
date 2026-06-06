#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    p.msg("Processing")

    if "-" not in p.title:
        p.msg("Skipping, no dash in title")
        return
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)

        tn = tname(t)
        if tn in ["ru-IPA"]:
            pron = getparam(t, "1") or getparam(t, "phon")
            if not re.search("[̀ѐЀѝЍ]", pron):
                p.msg("WARNING: No secondary accent in pron %s" % pron)

        if tn in ["ru-adj"]:
            head = getparam(t, "1")
            if head and "[[" not in head:

                def add_links(m):
                    prefix = m.group(1)
                    if re.search("[гкх]о$", prefix):
                        first = prefix[:-1] + "ий"
                    else:
                        first = prefix[:-1] + "ый"
                    return "[[%s|%s]]-[[%s]]" % (rulib.remove_accents(first), prefix, m.group(2))

                t.add("1", re.sub("^(.*?о)-([^-]*)$", add_links, head))
            notes.append("add links to two-part adjective")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Add links to two-part adjectives")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian adjectives"]
)
