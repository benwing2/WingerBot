#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg

from wingerbot.latin import lalib


def process_text_on_page(p):
    notes = []

    if " " in p.title:
        p.msg("WARNING: Space in page title, skipping")
        return
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "la-ndecl":
            lemmaspec = getparam(t, "1")
            m = re.search("^(.*)<(.*)>$", lemmaspec)
            if not m:
                p.msg("WARNING: Unable to parse lemma+spec %s, skipping: %s" % (lemmaspec, origt))
                continue
            lemma, spec = m.groups()
            if "/" in lemma:
                base, stem2 = lemma.split("/")
                if stem2 == re.sub("gō$", "gin", base):
                    stem2 = ""
            else:
                base = lemma
                stem2 = base + "n"
            if not base.endswith("gō"):
                p.msg("WARNING: Base %s doesn't end in -gō, skipping: %s" % (base, origt))
                continue
            if stem2:
                newlemma = "%s/%s" % (base, stem2)
            else:
                newlemma = base
            t.add("1", "%s<%s>" % (newlemma, spec))
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("convert 3rd-declension -gō term according to new default stem -gin in {{la-ndecl}}")

    return str(parsed), notes


parser = blib.create_argparser(
    "Fix Latin 3rd-decl -gō nouns to default to stem in -gin"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
