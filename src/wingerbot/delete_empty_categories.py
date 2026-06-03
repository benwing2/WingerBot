#!/usr/bin/env python3

import re
from wingerbot import blib

from pywikibot.exceptions import APIError


def process_page(p):
    def delete_page(page, comment):
        for i in range(11):
            try:
                page.delete(comment)
                return
            except APIError as e:
                if "missingtitle" in str(e):
                    p.errandmsg("WARNING: APIError due to page no longer existing, skipping: %s" % e)
                    return
                if i == 10:
                    raise e
                p.errandmsg("WARNING: APIError, try #%s: %s" % (i + 1, e))

    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if args.verbose:
        p.msg("Processing")
    if not p.title.startswith("Category:"):
        p.errandmsg("WARNING: Attempt to delete non-category, skipping")
        return
    catname = re.sub("^Category:", "", p.title)
    num_pages = len(list(blib.cat_articles(catname)))
    num_subcats = len(list(blib.cat_subcats(catname)))
    if num_pages > 0 or num_subcats > 0:
        p.errandmsg("Skipping (not empty): num_pages=%s, num_subcats=%s" % (num_pages, num_subcats))
        return
    this_comment = args.comment or "delete empty category"
    if p.page.exists():
        if args.save:
            delete_page(p.page, '%s (content was "%s")' % (this_comment, blib.safe_page_text(p.page, p.errandmsg)))
            p.errandmsg("Deleted (comment=%s)" % this_comment)
        else:
            p.msg("Would delete (comment=%s)" % this_comment)
    else:
        p.msg("Skipping, page doesn't exist")


params = blib.create_argparser("Delete empty category pages", include_pagefile=True)
params.add_argument("--comment", help="Specify the change comment to use")
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
