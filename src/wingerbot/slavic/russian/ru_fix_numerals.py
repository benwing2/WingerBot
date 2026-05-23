#!/usr/bin/env python3

# Add accented forms to {{cardinalbox}} and {{ordinalbox}}.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    notes = []
    adjval = None
    numval = None
    for t in parsed.filter_templates():
        if str(t.name) == "ru-adj":
            adjval = blib.remove_links(getparam(t, "1"))
        if str(t.name) == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "numeral":
            numval = blib.remove_links(getparam(t, "head"))
    for t in parsed.filter_templates():
        origt = str(t)
        if str(t.name) == "ordinalbox" and getparam(t, "1") == "ru":
            if not adjval:
                pagemsg("WARNING: Can't find accented ordinal form")
            elif adjval != pagetitle:
                t.add("alt", adjval)
                notes.append("Add alt=%s to ordinalbox" % adjval)
        if str(t.name) == "cardinalbox" and getparam(t, "1") == "ru":
            if not numval:
                pagemsg("WARNING: Can't find accented cardinal form")
            elif numval != pagetitle:
                t.add("alt", numval)
                notes.append("Add alt=%s to cardinalbox" % numval)
            if "[[Category:Russian cardinal numbers]]" not in str(parsed):
                pagemsg("WARNING: Numeral not in [[Category:Russian cardinal numbers]]")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return parsed, notes


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
    edit=True,
    stdin=True,
    default_cats=["Russian ordinal numbers", "Russian numerals"],
)
