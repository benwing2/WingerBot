#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "head" and getparam(t, "1") == "ang" and getparam(t, "2") in ["adjective", "adjectives"]:
            p.msg("WARNING: {{head}} for adjectives, should not occur: %s" % str(t))
        elif tn == "ang-adj":
            if getparam(t, "1"):
                p.msg("WARNING: 1= in ang-adj, should not occur: %s" % str(t))
            else:
                head = getparam(t, "head")
                rmparam(t, "head")
                if head:
                    t.add("1", head)
                notes.append("move head= to 1= in {{ang-adj}}")
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))
    return str(parsed), notes


parser = blib.create_argparser(
    "Fix Old English adjective headwords to new format part 2", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_cats=["Old English adjectives"]
)
