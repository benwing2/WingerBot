#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    # FIXME: Script no longer applies and would need fixing up.

    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj-5c", "ru-conj-6b"]:
            past_f = getparam(t, "4")
            if past_f:
                t.add("past_f", past_f, before="4")
                rmparam(t, "4")
                notes.append("Replace 4= with past_f=")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Convert 4th param to past_f")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Pages with module errors"]
)
