#!/usr/bin/env python3

# FIXME: Out of date. Use push_find_regex_changes.py.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site
from wingerbot.latin import lalib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    newsectext = pagetitle_to_text.get(pagetitle, None)
    if newsectext is None:
        pagemsg("WARNING: Can't find new text")
        return
    retval = lalib.find_latin_section(text, pagemsg)
    if retval is None:
        return

    newsectext = re.sub(r"^==Latin==\n", "", newsectext) + "\n\n"
    sections, j, secbody, sectail, has_non_lang = retval

    notes = []

    sections[j] = newsectext
    notes.append(args.comment)
    return "".join(sections).rstrip("\n"), notes


parser = blib.create_argparser(
    "Push manual changes for Latin sections to Wiktionary.", include_pagefile=True, include_stdin=True
)
parser.add_argument(
    "--textfile",
    help="File with page titles and section text, with at least four newlines on each side of the title.",
    required=True,
)
parser.add_argument("--comment", help="Comment to use when saving pages.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

fulltext = open(args.textfile, "r", encoding="utf-8").read()

titles_and_text = re.split(r"\n\n\n\n+", fulltext)

assert len(titles_and_text) % 2 == 0

title_and_text_pairs = []
for i in range(0, len(titles_and_text), 2):
    title_and_text_pairs.append((titles_and_text[i], titles_and_text[i + 1]))

pagetitle_to_text = {}

for i, (pagetitle, pagetext) in blib.iter_items(title_and_text_pairs, start, end, get_name=lambda x: x[0]):
    pagetitle_to_text[pagetitle] = pagetext

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_pages=list(pagetitle_to_text.keys())
)
