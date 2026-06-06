#!/usr/bin/env python3

# Find pages among a list of pages (e.g. most frequent words).

from wingerbot import blib
from wingerbot.blib import msg

parser = blib.create_argparser("Find pages among a list of pages")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lines = set(blib.fetch_items_from_file(args.pagefile))
def check_one_page(p):
    pagetitle = p.title
    if pagetitle in lines:
        msg("* Page %s [[%s]]" % (p.index, pagetitle))

blib.do_pagefile_cats_refs(args, start, end, check_one_page, no_fetch_text=True,
                           default_cats=["Russian entries needing definition"])
