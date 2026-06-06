#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        if tname(t) == "la-gerund":
            stem = getparam(t, "1")
            if stem and not stem.endswith("um"):
                origt = str(t)
                t.add("1", stem + "um")
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("modify {{la-gerund}} param 1 from %s to %sum" % (stem, stem))
    return str(parsed), notes


parser = blib.create_argparser(
    "Fix calls to {{la-gerund}} to include final -um"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:la-gerund"],
)
