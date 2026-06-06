#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import tname, msg

all_pronuns = []


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)

    pronuns = []
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "IPA":
            pronuns.extend(blib.fetch_param_chain(t, "2"))
    if pronuns:
        text = "Page %s %s: %s" % (p.index, p.title, " ".join(pronuns))
        if args.sort_by == "index":
            key = p.index
        elif args.sort_by == "rtl":
            key = (p.title[::-1], p.index)
        else:
            key = (-len(p.title), p.index)
        all_pronuns.append((key, text))


parser = blib.create_argparser(
    "Find manual pronunciations using {{IPA|LANG}}"
)
parser.add_argument(
    "--sort-by",
    choices=["index", "length", "rtl"],
    default="index",
    help="How to sort pronunciations; 'index' = by original index (preserve order), 'length' = by word length, 'rtl' = right to left",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
all_pronuns = sorted(all_pronuns)
for key, text in all_pronuns:
    msg(text)
