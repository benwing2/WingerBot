#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

from wingerbot import find_regex


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    non_wgem = False
    wgem = []
    for t in parsed.filter_templates():
        if tname(t) in ["desc", "desctree"]:
            if getparam(t, "bor"):
                continue
            desc = getparam(t, "1")
            if desc in [
                "got",
                "gme-cgo",
                "non",
                "non-ogt",
                "non-own",
                "non-oen",
                "is",
                "fo",
                "nrn",
                "no",
                "nb",
                "nn",
                "sv",
                "da",
                "gmq-osw",
                "gwq-oda",
                "gmq-bot",
                "gmq-jmk",
                "gmq-scy",
                "gmq-gut",
                "ovd",
            ]:
                p.msg("Saw non-West-Germanic descendant %s" % str(t))
                non_wgem = True
            else:
                wgem.append(desc)
    if not non_wgem:
        p.msg(
            "Saw no non-West-Germanic descendants but saw West-Germanic or non-Germanic descendants %s" % ",".join(wgem)
        )


parser = blib.create_argparser(
    "Find West-Germanic-only Proto-Germanic terms"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Proto-Germanic lemmas"])
