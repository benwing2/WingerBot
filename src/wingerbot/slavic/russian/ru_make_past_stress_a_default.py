#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        param2 = getparam(t, "2")
        param3 = getparam(t, "3")
        tn = tname(t)
        if tn in ["ru-conj", "ru-conj-old"] and param2.startswith("8b"):
            if [x for x in t.params if str(x.value) == "or"]:
                p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                continue
            if param2 in ["8b", "8b+p"]:
                t.add("2", getparam(t, "2").replace("8b", "8b/b"))
                notes.append("make past stress /b explicit in class 8b")
            elif param2 in ["8b/a", "8b/a+p"]:
                t.add("2", getparam(t, "2").replace("/a", ""))
                notes.append("make past stress /a default in class 8b")
            elif param2 not in ["8b/b", "8b/b+p"]:
                p.msg("WARNING: Unable to parse param2 %s" % param2)
        if tn in ["ru-conj", "ru-conj-old"] and param2.startswith("irreg"):
            if re.search("(да́?ть|бы́?ть|кля́?сть)(ся)?$", param3):
                if param2 == "irreg":
                    if param3.startswith("вы́"):
                        t.add("2", "irreg/a(1)")
                        notes.append("make past stress /a(1) explicit in irreg verb")
                    elif param3.endswith("ся"):
                        t.add("2", "irreg/c''")
                        notes.append("make past stress /c'' explicit in irreg verb")
                    elif param3.endswith("дать") or param3.endswith("да́ть"):
                        t.add("2", "irreg/c'")
                        notes.append("make past stress /c' explicit in irreg verb")
                    else:
                        t.add("2", "irreg/c")
                        notes.append("make past stress /c explicit in irreg verb")
                elif param2 == "irreg/a":
                    t.add("2", "irreg")
                    notes.append("make past stress /a default in irreg verb")
                elif not param2.startswith("irreg/"):
                    p.msg("WARNING: Unable to parse param2 %s" % param2)

        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Fix up class-8 and irregular arguments to have class a as default past stress",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian class 8b verbs", "Russian irregular verbs"],
)
