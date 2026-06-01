#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, addparam, rmparam, tname


def process_text_on_page(index, pagetitle, text):
    parsed = blib.parse_text(text)

    temps_changed = []
    for t in parsed.filter_templates():
        if tname(t) == "arz-noun":
            head = getparam(t, "head")
            rmparam(t, "head")
            tr = getparam(t, "tr")
            rmparam(t, "tr")
            sort = getparam(t, "sort")
            rmparam(t, "sort")
            g = getparam(t, "g")
            rmparam(t, "g")
            g2 = getparam(t, "g2")
            rmparam(t, "g2")
            pl = getparam(t, "2")
            rmparam(t, "2")
            pltr = getparam(t, "3")
            rmparam(t, "3")
            addparam(t, "1", head)
            addparam(t, "2", g)
            if g2:
                addparam(t, "g2", g2)
            if tr:
                addparam(t, "tr", tr)
            if pl:
                addparam(t, "pl", pl)
            if pltr:
                addparam(t, "pltr", pltr)
            if sort:
                addparam(t, "sort", sort)
            temps_changed.append("arz-noun")
        elif tname(t) == "arz-adj":
            head = getparam(t, "head")
            rmparam(t, "head")
            tr = getparam(t, "tr")
            rmparam(t, "tr")
            sort = getparam(t, "sort")
            rmparam(t, "sort")
            pl = getparam(t, "pwv") or getparam(t, "p")
            rmparam(t, "pwv")
            rmparam(t, "p")
            pltr = getparam(t, "ptr")
            rmparam(t, "ptr")
            f = getparam(t, "fwv") or getparam(t, "f")
            rmparam(t, "fwv")
            rmparam(t, "f")
            ftr = getparam(t, "ftr")
            rmparam(t, "ftr")
            addparam(t, "1", head)
            if tr:
                addparam(t, "tr", tr)
            if f:
                addparam(t, "f", f)
            if ftr:
                addparam(t, "ftr", ftr)
            if pl:
                addparam(t, "pl", pl)
            if pltr:
                addparam(t, "pltr", pltr)
            if sort:
                addparam(t, "sort", sort)
            temps_changed.append("arz-adj")
    return str(parsed), "rewrite %s to new style" % ", ".join(temps_changed)


parser = blib.create_argparser("Rewrite Egyptian Arabic headword templates", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
                           default_cats=["Egyptian Arabic adjectives", "Egyptian Arabic nouns"])
