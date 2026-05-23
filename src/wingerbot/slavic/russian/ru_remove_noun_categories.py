#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page_maybe_do_proper_noun(index, pagetitle, text, do_proper_noun):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    cat = do_proper_noun and "proper nouns" or "nouns"
    new_text = re.sub(r"\n\n\n*\[\[Category:Russian %s]]\n\n\n*" % cat, "\n\n", text)
    new_text = re.sub(r"\[\[Category:Russian %s]]\n" % cat, "", new_text)
    return new_text, "Remove redundant [[:Category:Russian %s]]"


parser = blib.create_argparser(
    "Remove redundant 'Russian nouns' or 'Russian proper nouns' category", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def process_text_on_page_noun(index, pagetitle, text):
    return process_text_on_page_maybe_do_proper_noun(index, pagetitle, text, False)


def process_text_on_page_proper_noun(index, pagetitle, text):
    return process_text_on_page_maybe_do_proper_noun(index, pagetitle, text, True)


# FIXME! Won't work properly with --pagefile.
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page_noun,
    edit=True,
    stdin=True,
    default_refs=["Template:ru-noun", "Template:ru-noun+"],
)
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page_proper_noun,
    edit=True,
    stdin=True,
    default_refs=["Template:ru-proper noun", "Template:ru-proper noun+"],
)
