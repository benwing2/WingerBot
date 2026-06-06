#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg

# Hindi vowel diacritics; don't display nicely on their own
M = "\u0901"
N = "\u0902"
AA = "\u093e"


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    noun_head_template = None
    noun_head_template_maybe_unmarked = False
    saw_ndecl = False
    saw_place = False
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "hi-noun":
            noun_head_template = None
            noun_head_template_maybe_unmarked = False
            saw_ndecl = False
            saw_place = False
        elif tn == "hi-proper noun":
            noun_head_template = t
            head = getparam(t, "head") or p.title
            if "m" in getparam(t, "g") and re.search("[" + AA + "आ][" + M + N + "]?$", head):
                noun_head_template_maybe_unmarked = True
            else:
                noun_head_template_maybe_unmarked = False
            saw_ndecl = False
            saw_place = False
        elif tn == "place":
            saw_place = True
            if not noun_head_template:
                p.msg("WARNING: Saw {{place}} without preceding {{hi-proper noun}}")
        elif tn == "hi-ndecl":
            saw_ndecl = True
            decl = getparam(t, "1")
            if "unmarked" not in decl and noun_head_template_maybe_unmarked:
                p.msg("WARNING: Saw proper noun ending in -ā or -ā̃, probably needing 'unmarked': %s" % str(t))
            if saw_place and "sg" not in decl:
                p.msg("WARNING: Saw proper noun with {{place}} but without 'sg' in declension template: %s" % str(t))


parser = blib.create_argparser(
    "Check for proper noun needing 'unmarked' in declension"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Hindi lemmas"])
