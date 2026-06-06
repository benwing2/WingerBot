#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, tname


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)

    found_inflection_of = False
    for t in parsed.filter_templates():
        if tname(t) in ["inflection of"]:
            found_inflection_of = True
    if not found_inflection_of:
        p.msg("WARNING: No 'inflection of'")


parser = blib.create_argparser("Find badly formatted Russian noun forms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian noun forms"]
)
