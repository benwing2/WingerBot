#!/usr/bin/env python3

import pywikibot

from wingerbot import blib
from wingerbot.blib import site


def process_page(p, comment):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if args.verbose:
        p.msg("Processing")
    this_comment = comment or "delete page"
    if blib.safe_page_exists(page, p.errandmsg):
        if args.save:
            existing_text = blib.safe_page_text_or_none(page, p.errandmsg)
            if existing_text is not None:
                page.delete('%s (content was "%s")' % (this_comment, existing_text))
                p.errandmsg("Deleted (comment=%s)" % this_comment)
        else:
            p.msg("Would delete (comment=%s)" % this_comment)
    else:
        p.msg("Skipping, page doesn't exist")


params = blib.create_argparser("Delete pages", include_pagefile=True, no_include_stdin=True)
params.add_argument("--comment", help="Specify the change comment to use")
params.add_argument("--direcfile", help="File containing pages to delete, optionally with comments after ' ||| '.")
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.direcfile:
    for index, line in blib.iter_items_from_file(args.direcfile, start, end):
        if " ||| " in line:
            pagetitle, page_comment = line.split(" ||| ")
        else:
            pagetitle = line
            page_comment = args.comment or "delete file"
        page = pywikibot.Page(site, pagetitle)
        process_page(blib.ProcessPageParams(args, index, pagetitle, "", page=page), page_comment)
else:

    def do_process_page(p):
        return process_page(p, args.comment)

    blib.do_pagefile_cats_refs(args, start, end, do_process_page, no_fetch_text=True)
