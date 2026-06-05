#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

parser = blib.create_argparser("Clean up bad Polish inflection tags",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="Pages and inflections to process.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

with open(args.direcfile, "r", encoding="utf-8") as fp:
    text = fp.read()
    pages = text.split("\001")
for index, page in blib.iter_items(pages, start, end):
    if not page:  # e.g. first entry
        continue
    split_vals = re.split("\n", page, 1)
    if len(split_vals) < 2:
        msg("Page %s: Skipping bad text: %s" % (index, page))
        continue
    pagetitle, pagetext = split_vals
    parsed = blib.parse_text(pagetext)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "inflection of":
            lang = getparam(t, "lang")
            if not lang:
                lang = getparam(t, "1")
            if lang == "pl":
                for param in t.params:
                    pname = str(param.name).strip()
                    pval = str(param.value).strip()
                    if re.search("^[0-9]+$", pname) and pval == "other":
                        msg(pagetitle)
