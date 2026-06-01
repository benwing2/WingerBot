#!/usr/bin/env python3

# Add accented forms to {{cardinalbox}} and {{ordinalbox}}.

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    adjval = None
    numval = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-adj":
            adjval = blib.remove_links(getparam(t, "1"))
        if tn == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "numeral":
            numval = blib.remove_links(getparam(t, "head"))
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "ordinalbox" and getparam(t, "1") == "ru":
            if not adjval:
                p.msg("WARNING: Can't find accented ordinal form")
            elif adjval != p.title:
                t.add("alt", adjval)
                notes.append("Add alt=%s to ordinalbox" % adjval)
        if tn == "cardinalbox" and getparam(t, "1") == "ru":
            if not numval:
                p.msg("WARNING: Can't find accented cardinal form")
            elif numval != p.title:
                t.add("alt", numval)
                notes.append("Add alt=%s to cardinalbox" % numval)
            if "[[Category:Russian cardinal numbers]]" not in str(parsed):
                p.msg("WARNING: Numeral not in [[Category:Russian cardinal numbers]]")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Add accented forms to {{cardinalbox}} and {{ordinalbox}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    new=True,
    default_cats=["Russian ordinal numbers", "Russian numerals"],
)
