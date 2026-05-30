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

    modsec = blib.find_modifiable_lang_section(text, "Russian", pagemsg)
    if modsec is None:
        return
    if re.search("[Oo]f or related", modsec.secbody):
        pagemsg("Found likely of-or-related")


parser = blib.create_argparser("Find pages with 'Of or related'", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian adjectives"]
)
