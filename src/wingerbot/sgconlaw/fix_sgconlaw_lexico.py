#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        if tname(t) == "R:Lexico":
            origt = str(t)
            rmparam(t, "lang")
            entry_uk = getparam(t, "entry_uk")
            if entry_uk:
                t.add("entry", entry_uk, before="entry_uk")
            rmparam(t, "entry_uk")
            url_uk = getparam(t, "url_uk")
            if url_uk:
                t.add("url", url_uk, before="url_uk")
            rmparam(t, "url_uk")
            p4 = getparam(t, "4")
            if p4:
                t.add("text", p4, before="4")
            rmparam(t, "4")
            newt = str(t)
            if origt != newt:
                notes.append("Remove/rearrange params in {{R:Lexico}}")
                p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Remove/rearrange params in {{R:Lexico}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:R:Lexico"]
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
