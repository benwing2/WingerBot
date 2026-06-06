#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg

# Map from English pages to set of other languages.
english_pages = {}


def process_text_on_page_for_find_english_pages(p):
    secs = blib.split_text_into_sections(p.text, p.msg)
    saw_langs = set()
    saw_english = False
    for j, langname in secs.lang_list:
        if langname == "English":
            saw_english = True
        else:
            saw_langs.add(langname)
    if saw_english:
        english_pages[p.title] = saw_langs


def process_line(index, line):
    m = re.search("^Page [0-9]+ (.*?): Replacing (.*) with (.*) in .* section in (.*)$", line)
    if not m:
        return
    pagetitle, fromtext, totext, lang = m.groups()

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    for m in re.finditer(r"\{\{(?:m|l|term)\|.*?\|(.*?)\}\}", totext):
        linkpage = m.group(1)
        if linkpage in english_pages and lang not in english_pages[linkpage]:
            pagemsg("Possible false positive for [[%s]] in %s: %s" % (linkpage, lang, fromtext))


parser = blib.create_argparser("Check for likely false-positive links converted from raw links")
parser.add_argument("--direcfile", help="File of output from fix_links.py")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page_for_find_english_pages)

for index, line in blib.iter_items_from_file(args.direcfile, start, end):
    process_line(index, line)
