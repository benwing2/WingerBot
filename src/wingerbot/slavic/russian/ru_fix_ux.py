#!/usr/bin/env python3

# Remove adj= and shto= from ru-ux.

from wingerbot import blib
from wingerbot.blib import rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        if tname(t) == "ru-ux":
            origt = str(t)
            if t.has("adj"):
                p.msg("Removing adj=")
                notes.append("remove adj= from ru-ux")
                rmparam(t, "adj")
            if t.has("shto"):
                p.msg("Removing shto=")
                notes.append("remove shto= from ru-ux")
                rmparam(t, "shto")
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Remove adj= and shto= from ru-ux", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_refs=["Template:ru-ux"]
)
