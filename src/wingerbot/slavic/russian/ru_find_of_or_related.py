#!/usr/bin/env python3

# Find pages that need definitions among a set list (e.g. most frequent words).

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(index, pagetitle, text):
    subpagetitle = re.sub("^.*:", "", pagetitle)

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    if ":" in pagetitle:
        pagemsg("WARNING: Colon in page title, skipping page")
        return

    notes = []

    foundrussian = False
    sections = re.split("(^==[^=]*==\n)", text, 0, re.M)

    for j in range(2, len(sections), 2):
        if sections[j - 1] == "==Russian==\n":
            if foundrussian:
                pagemsg("WARNING: Found multiple Russian sections, skipping page")
                return
            foundrussian = True

            if re.search("[Oo]f or related", sections[j]):
                pagemsg("Found likely of-or-related")


parser = blib.create_argparser("Find pages that need definitions", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian adjectives"]
)
