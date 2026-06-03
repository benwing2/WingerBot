#!/usr/bin/env python3

from wingerbot import blib

parser = blib.create_argparser("List pages, lemmas and/or non-lemmas", include_pagefile=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def process_page(p):
    p.msg("Processing")


blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
