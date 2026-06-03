#!/usr/bin/env python3

import re

from wingerbot import blib


def process_text_on_page_maybe_do_proper_noun(p, do_proper_noun):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    cat = do_proper_noun and "proper nouns" or "nouns"
    new_text = re.sub(r"\n\n\n*\[\[Category:Russian %s]]\n\n\n*" % cat, "\n\n", p.text)
    new_text = re.sub(r"\[\[Category:Russian %s]]\n" % cat, "", new_text)
    return new_text, "Remove redundant [[:Category:Russian %s]]"


parser = blib.create_argparser(
    "Remove redundant 'Russian nouns' or 'Russian proper nouns' category", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def process_text_on_page_noun(p):
    return process_text_on_page_maybe_do_proper_noun(p, False)


def process_text_on_page_proper_noun(p):
    return process_text_on_page_maybe_do_proper_noun(p, True)


# FIXME! Won't work properly with --pagefile.
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page_noun,
    default_refs=["Template:ru-noun", "Template:ru-noun+"],
)
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page_proper_noun,
    default_refs=["Template:ru-proper noun", "Template:ru-proper noun+"],
)
