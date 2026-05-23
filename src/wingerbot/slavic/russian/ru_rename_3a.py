#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if str(t.name) in ["ru-conj", "ru-conj-old"]:
            conjtype = getparam(t, "2")
            if conjtype.startswith("3a"):
                if [x for x in t.params if str(x.value) == "or"]:
                    pagemsg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                    continue
                t.add("2", conjtype.replace("3a", "3olda"))
                notes.append("rename conj type 3a -> 3olda")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Rename class 3a to 3olda", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_refs=["Template:tracking/ru-verb/conj-3a"]
)
