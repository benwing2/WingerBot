#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    if not p.title.endswith("ся"):
        return

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-decl-adj", "ru-adj-old"] and getparam(t, "suffix") == "ся":
            lemma = getparam(t, "1")
            lemma = re.sub(",", "ся,", lemma)
            lemma = re.sub("$", "ся", lemma)
            t.add("1", lemma)
            rmparam(t, "suffix")
            notes.append("move suffix=ся to lemma")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Rewrite reflexive adjectival participle declensions involving suffix=ся to put suffix in the lemma",
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
    default_refs=["Template:ru-decl-adj", "Template:ru-adj-old"],
)
