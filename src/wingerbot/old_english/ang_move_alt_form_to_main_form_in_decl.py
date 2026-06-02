#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn.startswith("ang-decl-"):
            origt = str(t)
            alt1 = getparam(t, "alt1")
            if alt1:
                t.add("1", alt1, before="alt1")
                rmparam(t, "alt1")
            alt2 = getparam(t, "alt2")
            if alt2:
                t.add("2", alt2, before="alt2")
                rmparam(t, "alt2")
            altnomsg = getparam(t, "altnomsg")
            if altnomsg:
                t.add("nomsg", altnomsg, before="altnomsg")
                rmparam(t, "altnomsg")
            if str(t) != origt:
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("move alt param to main param in {{ang-decl-*}}")

    return str(parsed), notes


parser = blib.create_argparser(
    "Move alt form to main form in {{ang-decl-*}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
