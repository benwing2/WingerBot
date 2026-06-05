#!/usr/bin/env python3

# FIXME: Rewrite following list_pages.py.

from wingerbot import blib
from wingerbot.blib import msg

parser = blib.create_argparser("List pages in category or references in Zaliznyak order",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--cat", help="Category to list")
parser.add_argument("--ref", help="References to list")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pages = []
if args.cat:
    pages_to_list = blib.cat_articles(args.cat, start, end)
else:
    pages_to_list = blib.references(args.ref, start, end)
for i, page in pages_to_list:
    pages.append(page.title())
for page in sorted(pages, key=lambda x: x[::-1]):
    msg(page)
