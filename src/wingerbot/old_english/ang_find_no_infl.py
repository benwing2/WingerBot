#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p, pos):
    notes = []

    parsed = blib.parse_text(p.text)

    found_infl = False
    for t in parsed.filter_templates():
        tn = tname(t)
        if pos == "verbs" and tn.startswith("ang-conj"):
            p.msg("Found verb conjugation: %s" % str(t))
            found_infl = True
        elif pos == "nouns" and tn.startswith("ang-decl-noun"):
            p.msg("Found noun conjugation: %s" % str(t))
            found_infl = True
        elif pos == "adjectives" and tn.startswith("ang-decl-adj"):
            p.msg("Found adjective conjugation: %s" % str(t))
            found_infl = True
    if not found_infl:
        p.msg("WARNING: Couldn't find inflection template")


parser = blib.create_argparser("Find Old English terms without inflection", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for pos in ["nouns", "verbs", "adjectives"]:
    def do_process_text_on_page(p):
        return process_text_on_page(p, pos)

    blib.do_pagefile_cats_refs(
        args, start, end, do_process_text_on_page, new=True, default_cats=["Old English %s" % pos]
    )
