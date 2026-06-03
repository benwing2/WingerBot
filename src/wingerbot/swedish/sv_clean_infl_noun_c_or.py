#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, site, tname, pname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "sv-infl-noun-c-or":
            origt = str(t)
            if getparam(t, "1") + "a" == p.title:
                rmparam(t, "1")
                notes.append("remove redundant 1= from {{%s}}" % tn)
                p.msg("Replace %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove redundant 1= from {{sv-infl-noun-c-or}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Swedish nouns"],
)
