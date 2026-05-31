#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        param2 = getparam(t, "2")
        if tname(t) in ["ru-conj"] and re.search(r"^8[ab]", param2):
            if [x for x in t.params if str(x.value) == "or"]:
                pagemsg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                continue
            past_m = getparam(t, "past_m")
            if past_m:
                rmparam(t, "past_m")
                stem = getparam(t, "3")
                if stem == past_m:
                    pagemsg("Stem %s and past_m same" % stem)
                    notes.append("remove redundant past_m %s" % past_m)
                elif (
                    param2.startswith("8b")
                    and not param2.startswith("8b/")
                    and rulib.make_unstressed_ru(past_m) == stem
                ):
                    pagemsg(
                        "Class 8b/b and stem %s is unstressed version of past_m %s, replacing stem with past_m"
                        % (stem, past_m)
                    )
                    t.add("3", past_m)
                    notes.append("moving past_m %s to arg 3" % past_m)
                else:
                    pagemsg("Stem %s and past_m %s are different, putting past_m in param 5" % (stem, past_m))
                    t.add("5", past_m)
                    notes.append("moving past_m %s to arg 5" % past_m)
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Fix up class-8 arguments", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian class 8 verbs"]
)
