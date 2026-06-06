#!/usr/bin/env python3

import pywikibot

from wingerbot import blib
from wingerbot.blib import msg, site

parser = blib.create_argparser("Move erroneously-created German non-lemma noun forms",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfilefile", help="File of ///-separated pairs of base declensions to move", required=True)
parser.add_argument("--comment", help="Comment to use when deleting")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

comment = args.comment or "Move erroneously-created non-lemma form"

endings = ["e", "en", "er", "em", "es"]

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    frombase, tobase = line.split("///")
    for ending in endings:
        page = pywikibot.Page(site, frombase + ending)

        def pagemsg(txt):
            msg("Page %s %s: %s" % (lineno, page.title(), txt))

        topagename = tobase + ending
        if page.exists():
            if pywikibot.Page(site, topagename).exists():
                pagemsg("WARNING: Destination page %s already exists, not moving" % topagename)
            else:
                pagemsg("Moving to %s (comment=%s)" % (topagename, comment))
                if args.save:
                    try:
                        page.move(topagename, reason=comment, movetalk=True, noredirect=True)
                    except pywikibot.exceptions.PageRelatedError as error:
                        pagemsg("Error moving: %s" % error)
