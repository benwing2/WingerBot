#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "head" and getparam(t, "1") == "ny" and getparam(t, "2") == "noun plural form":
            head = getparam(t, "head") or p.title
            rmparam(t, "head")
            g = getparam(t, "g")
            g = re.sub("^c", "", g)
            rmparam(t, "g")
            rmparam(t, "1")
            rmparam(t, "2")
            # Fetch all params.
            params = []
            unrecognized = False
            for param in t.params:
                p.msg("Saw unrecognized param %s=%s in %s" % (str(param.name), str(param.value), origt))
                unrecognized = True
            if unrecognized:
                continue
            # Erase all params.
            del t.params[:]
            t.add("1", head)
            if g:
                t.add("2", g)
            blib.set_template_name(t, "ny-plural noun")
            notes.append("convert {{head|ny|noun plural form}} to {{ny-plural noun}}")
        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Templatize {{head|ny|noun plural form}} to {{ny-plural noun}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Chichewa noun plural forms"],
)
