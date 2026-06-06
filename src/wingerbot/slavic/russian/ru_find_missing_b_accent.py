#!/usr/bin/env python3

# Find places where accent b is likely missing in Russian noun declensions.

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    notes = []

    if not re.search(r"(ник|ок)([ -]|$)", p.title):
        return

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-noun-table":
            ut = str(t)
            if re.search(r"ни́к(\||$)", ut) and "|b" not in ut:
                p.msg("WARNING: Likely missing accent b: %s" % ut)
            if re.search(r"о́к(\||$)", ut) and "*" in ut and "|b" not in ut:
                p.msg("WARNING: Likely missing accent b: %s" % ut)


parser = blib.create_argparser(
    "Find places where accent b is likely missing in Russian noun declensions",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian nouns"]
)
