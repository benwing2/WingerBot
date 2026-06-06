#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["diminutive of", "dim of"]:
            if t.has("pos"):
                pos = re.sub("s$", "", getparam(t, "pos"))
                t.add("POS", pos, before="pos")
                rmparam(t, "pos")
                notes.append("Convert plural pos= to singular POS= in {{%s}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert plural pos= to singular POS= in {{diminutive of}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
