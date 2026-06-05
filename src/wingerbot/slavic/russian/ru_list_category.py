#!/usr/bin/env python3

# FIXME: Obsolete. Use list_pages.py.

import re

from wingerbot import blib
from wingerbot.blib import msg

parser = blib.create_argparser("List pages, lemmas and/or non-lemmas",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--cats", default="Russian lemmas", help="Categories to do (can be comma-separated list)")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def list_category(cat):
    for i, page in blib.cat_articles(cat, start, end):
        msg("Page %s %s: Processing page" % (i, page.title()))
    for i, page in blib.cat_subcats(cat, start, end):
        msg("Page %s %s: Processing subcategory" % (i, page.title()))
        list_category(re.sub("^Category:", "", page.title()))


for cat in re.split(",", args.cats):
    msg("Processing category: %s" % cat)
    list_category(cat)
