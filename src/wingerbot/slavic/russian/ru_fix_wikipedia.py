#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) == "wikipedia":
            val = getparam(t, "1")
            newval = rulib.remove_accents(val)
            if val != newval:
                p.msg("Removing Russian accents from 1= in {{wikipedia|...}}")
                notes.append("remove Russian accents from 1= in {{wikipedia|...}}")
                t.add("1", newval)
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove Russian accents from 1= in {{wikipedia|...}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
