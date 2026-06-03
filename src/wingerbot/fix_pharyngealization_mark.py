#!/usr/bin/env python3

# Correct use of U+02C1 pharyngealization mark to U+02E4.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    def frob(t, param):
        val = getparam(t, param)
        if val:
            newval = val.replace("\u02c1", "\u02e4")
            if newval != val:
                t.add(param, newval)

    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) == "IPAchar":
            frob(t, "1")
        elif tname(t) == "IPA":
            if getparam(t, "lang"):
                firstparam = 1
            else:
                firstparam = 2
            for i in range(firstparam, 20):
                frob(t, str(i))
        newt = str(t)
        if origt != newt:
            notes.append("Correct use of U+02C1 pharyngealization mark to U+02E4")
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Correct use of U+02C1 pharyngealization mark to U+02E4", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
