#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

from wingerbot.slavic.belarusian import belib


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    head = None
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "be-decl-noun":
            t.name = "be-decl-noun\n"
            for i in [2, 4, 6, 8, 10, 12]:
                val = getparam(t, str(i)).strip()
                if val:
                    t.add(str(i), val + "\n", preserve_spacing=False)
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("format {{be-decl-noun}} using newlines")

    return str(parsed), notes


parser = blib.create_argparser("Format be-decl-noun using newlines", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_refs=["Template:be-decl-noun"]
)
