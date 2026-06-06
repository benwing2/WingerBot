#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) == "ru-adj":
            comps = blib.fetch_param_chain(t, "2", "comp")
            newcomps = []
            for comp in comps:
                if re.search("е́?й$", comp):
                    regcomp = re.sub("(е́?)й$", r"\1е", comp)
                    if regcomp in newcomps:
                        p.msg("Skipping informal form %s" % comp)
                        notes.append("remove informal comparative %s" % comp)
                    else:
                        p.msg("WARNING: Found informal form %s without corresponding regular form")
                        newcomps.append(comp)
                else:
                    newcomps.append(comp)
            if comps != newcomps:
                blib.set_param_chain(t, newcomps, "2", "comp")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove informal comparatives from adjectives when regular comparative present",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian adjectives"]
)
