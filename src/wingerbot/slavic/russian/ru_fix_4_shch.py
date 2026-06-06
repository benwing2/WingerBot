#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    # FIXME: Script no longer applies and would need fixing up.

    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj-4a"]:
            shch = getparam(t, "4")
            if shch == "щ":
                t.add("3", getparam(t, "3") + shch)
                rmparam(t, "4")
                notes.append("move param 4 (щ) to param 3")
            elif shch:
                p.msg("WARNING: Strange value %s for param 4" % shch)
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Convert class-4a 4th param щ to 3rd param")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:tracking/ru-verb/conj-4a"]
)
