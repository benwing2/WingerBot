#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("WARNING: Script no longer applies and would need fixing up")
    return

    pagemsg("Processing")
    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if str(t.name) in ["ru-conj-5c", "ru-conj-6b"]:
            past_f = getparam(t, "4")
            if past_f:
                t.add("past_f", past_f, before="4")
                rmparam(t, "4")
                notes.append("Replace 4= with past_f=")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Convert 4th param to past_f", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Pages with module errors"]
)
