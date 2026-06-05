#!/usr/bin/env python3

from wingerbot import blib


def process_page(p):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if args.verbose:
        p.msg("Processing")
    if p.page.exists():
        p.errandmsg("Page already exists, not overwriting")
        return
    comment = 'Created page with "%s"' % args.contents
    if args.save:
        p.page.text = args.contents
        if blib.safe_page_save(p.page, comment, p.errandmsg):
            p.errandmsg("Created page, comment = %s" % comment)
    else:
        p.msg("Would create, comment = %s" % comment)


params = blib.create_argparser("Create pages", include_pagefile=True, no_include_stdin=True)
params.add_argument("--contents", help="Contents of pages", required=True)
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
