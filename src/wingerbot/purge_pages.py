#!/usr/bin/env python3

from wingerbot import blib

parser = blib.create_argparser("Purge (null-save) pages in category or references", include_pagefile=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def process_page(p):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if not blib.safe_page_exists(p.page, p.errandmsg):
        p.msg("WARNING: Page doesn't exist, null-saving it would create it")
        return
    if args.verbose:
        p.msg("Null-saving")
    blib.safe_page_save(p.page, "null save", p.errandmsg)


blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
