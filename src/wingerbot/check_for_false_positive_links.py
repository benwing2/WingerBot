#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

# Map from English pages to set of other languages.
english_pages = {}


def find_english_pages(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    secs = blib.split_text_into_sections(text, pagemsg)
    saw_langs = set()
    saw_english = False
    for j, langname in secs.section_langs:
        if langname == "English":
            saw_english = True
        else:
            saw_langs.add(langname)
    if saw_english:
        english_pages[pagetitle] = saw_langs


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

blib.parse_dump(sys.stdin, find_english_pages)

for index, line in blib.iter_items_from_file(args.direcfile, start, end):
    process_line(index, line)
