#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    notes = []

    if " " in p.title:
        p.msg("WARNING: Space in page title, skipping")
        return
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    num_ndecl_templates = 0
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "la-ndecl":
            num_ndecl_templates += 1
            lemmaspec = getparam(t, "1")
            m = re.search("^(.*)<(.*)>$", lemmaspec)
            if not m:
                p.msg("WARNING: Unable to parse lemma+spec %s, skipping: %s" % (lemmaspec, origt))
                continue
            lemma, spec = m.groups()
            if ".loc" in spec:
                p.msg("Already has .loc in spec: %s" % origt)
            elif lemma.endswith("polis"):
                p.msg("Ends with -polis, don't need to add .loc: %s" % origt)
            else:
                spec += ".loc"
                t.add("1", "%s<%s>" % (lemma, spec))
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("add .loc to declension of Latin city")
    if num_ndecl_templates > 1:
        p.msg("WARNING: Saw multiple {{la-ndecl}} templates, some may not be cities")
        return
    if num_ndecl_templates == 0:
        p.msg("WARNING: Didn't see any {{la-ndecl}} templates")

    return str(parsed), notes


parser = blib.create_argparser("Add missing .loc to Latin cities")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=[
        "la:Cities",
        "la:Towns",
        "la:Capital cities",
        "la:Cities in France",
        "la:Cities in Italy",
        "la:Cities in Spain",
        "la:Cities in Sweden",
        "la:Cities in the United Kingdom",
        "la:Cities in England",
    ],
)
