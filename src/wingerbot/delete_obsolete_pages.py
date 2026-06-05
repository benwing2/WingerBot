#!/usr/bin/env python3

import pywikibot, re
from pywikibot.exceptions import APIError

from wingerbot import blib
from wingerbot.blib import site

parser = blib.create_argparser("Delete obsolete pages",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--pagefile", help="Pages to delete", required=True)
parser.add_argument("--delete-docs", help="Delete documentation pages of templates", action="store_true")
parser.add_argument("--comment", help="Comment to use when deleting")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pages_to_delete = list(blib.fetch_items_from_file(args.pagefile))

comment = args.comment or "Delete obsolete page"
doc_comment = "Delete documentation page of " + re.sub("^([Dd]elete|[Rr]emove) ", "", comment)


def delete_page(page, comment, errandpagemsg):
    for i in range(11):
        try:
            page.delete(comment)
            return
        except APIError as e:
            if i == 10:
                raise e
            errandpagemsg("APIError, try #%s: %s" % (i + 1, e))

for index, pagetitle in blib.iter_items(pages_to_delete, start, end):
    def handle_page(p):
        if blib.safe_page_exists(p.page, p.errandmsg):
            p.msg("Deleting %s (comment=%s)" % (p.title, comment))
            delete_page(p.page, '%s (content was "%s")' % (comment, p.text), p.errandmsg)
            p.errandmsg("Page [[%s]] deleted" % p.title)
        if args.delete_docs:
            doc_page = pywikibot.Page(site, "%s/documentation" % pagetitle)
            if blib.safe_page_exists(doc_page, p.errandmsg):
                p.msg("Deleting %s (comment=%s)" % (doc_page.title(), doc_comment))
                delete_page(doc_page, '%s (content was "%s")' % (doc_comment, blib.safe_page_text(doc_page, p.errandmsg)), p.errandmsg)
                p.errandmsg("Page [[%s]] deleted" % doc_page.title())

    blib.do_edit(args, index, pagetitle, handle_page)
