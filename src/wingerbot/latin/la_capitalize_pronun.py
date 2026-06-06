#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        if tname(t) == "la-IPA":
            param1 = getparam(t, "1")
            if param1:
                origt = str(t)
                newparam1 = param1[0].upper() + param1[1:]
                if newparam1 != param1:
                    t.add("1", newparam1)
                    p.msg("Replaced %s with %s" % (origt, str(t)))
                    notes.append("capitalize %s in {{la-IPA}} to match page title" % param1)

    return str(parsed), notes


parser = blib.create_argparser(
    "Capitalize {{la-IPA}} as appropriate for page title"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:la-IPA"],
    filter_pages=lambda pagetitle: pagetitle[0].isupper(),
)
