#!/usr/bin/env python3

# Find Russian perfective verbs with explicit past passive participles

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def expand_text(tempcall):
        return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

    pagemsg("Processing")

    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["ru-conj", "ru-conj-old"] and getparam(t, "1").startswith("pf"):
            if tn == "ru-conj":
                tempcall = re.sub(r"\{\{ru-conj", "{{ru-generate-verb-forms", str(t))
            else:
                tempcall = re.sub(r"\{\{ru-conj-old", "{{ru-generate-verb-forms|old=y", str(t))
            result = expand_text(tempcall)
            if not result:
                pagemsg("WARNING: Error generating forms, skipping")
                continue
            args = blib.split_generate_args(result)
            for base in ["past_pasv_part", "ppp"]:
                for i in ["", "2", "3", "4", "5", "6", "7", "8", "9"]:
                    val = getparam(t, base + i)
                    if val and val != "-":
                        val = re.sub("//.*", "", val)
                        pagemsg("Found perfective past passive participle: %s" % val)


parser = blib.create_argparser(
    "Find Russian perfective verbs with explicit past passive participles", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian verbs"]
)
