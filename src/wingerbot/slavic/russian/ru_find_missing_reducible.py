#!/usr/bin/env python3

# Find places where a reducible * notation is likely missing in Russian nouns.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    notes = []

    if not re.search(r"(ник|ок|ка)([ -]|$)", p.title):
        return

    cons = "[бцдфгчйклмнпрствшхзжщ]"
    if (
        p.title.endswith("ство")
        or p.title.endswith("ёнок")
        or re.search("[шжчщ]онок$", p.title)
        or (
            not re.search(cons + "[кц][оаяеёыи]$", p.title)
            and not re.search(cons + cons + "[оаяеёыи]$", p.title)
            and
            # not re.search("[оеё]" + cons + "$", p.title) and # but too many false positives
            not re.search("[оеё][кц]$", p.title)
        )
    ):
        return
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-noun-table" and "*" not in str(t):
            p.msg("WARNING: Likely incorrectly-declined reducible: %s" % str(t))


parser = blib.create_argparser(
    "Find places where reduciible * notation is likely missing in Russian noun declensions",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian nouns"]
)
