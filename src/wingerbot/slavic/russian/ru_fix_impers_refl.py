#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj", "ru-conj-old"]:
            verbtype = getparam(t, "1")
            if verbtype == "pf-impers-refl":
                t.add("1", "pf-refl-impers")
                notes.append("pf-impers-refl -> pf-refl-impers")
            if verbtype == "impf-impers-refl":
                t.add("1", "impf-refl-impers")
                notes.append("impf-impers-refl -> impf-refl-impers")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Change verb type *-impers-refl to *-refl-impers"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian verbs"]
)
