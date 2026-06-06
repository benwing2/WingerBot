#!/usr/bin/env python3

# Convert {{quote-Fanny Hill|part=2|[passage]}} → {{RQ:Cleland Fanny Hill|passage=[passage]}}.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        if tname(t) == "quote-Fanny Hill":
            origt = str(t)
            t.name = "RQ:Cleland Fanny Hill"
            rmparam(t, "part")
            if getparam(t, "1"):
                t.add("passage", getparam(t, "1"))
                rmparam(t, "1")
            notes.append("Replace {{quote-Fanny Hill}} with {{RQ:Cleland Fanny Hill}}")
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{quote-Fanny Hill}} to {{RQ:Cleland Fanny Hill}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:quote-Fanny Hill"]
)
