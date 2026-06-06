#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj", "ru-conj-old"]:
            conjtype = getparam(t, "2")
            if conjtype.startswith("3a"):
                if [x for x in t.params if str(x.value) == "or"]:
                    p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                    continue
                t.add("2", conjtype.replace("3a", "3olda"))
                notes.append("rename conj type 3a -> 3olda")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Rename class 3a to 3olda")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:tracking/ru-verb/conj-3a"]
)
