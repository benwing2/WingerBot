#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "head" and getparam(t, "1") == "bnt-pro" and getparam(t, "2") == "verb":
            rmparam(t, "1")
            rmparam(t, "2")
            # Check for unrecognized params.
            params = []
            unrecognized = False
            for param in t.params:
                p.msg("Saw unrecognized param %s=%s in %s" % (str(param.name), str(param.value), origt))
                unrecognized = True
            if unrecognized:
                continue
            blib.set_template_name(t, "bnt-verb")
            notes.append("convert {{head|bnt-pro|verb}} to {{bnt-verb}}")
        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Templatize {{head|bnt-pro|verb}} to {{bnt-verb}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Proto-Bantu verbs"],
)
