#!/usr/bin/env python3

# Go through all the French terms we can find and remove sort=.

from wingerbot import blib
from wingerbot.blib import rmparam, tname

fr_head_templates = [
    "fr-noun",
    "fr-proper noun",
    "fr-proper-noun",
    "fr-verb",
    "fr-adj",
    "fr-adv",
    "fr-phrase",
    "fr-adj form",
    "fr-adj-form",
    "fr-abbr",
    "fr-diacritical mark",
    "fr-intj",
    "fr-letter",
    "fr-past participle",
    "fr-prefix",
    "fr-prep",
    "fr-pron",
    "fr-punctuation mark",
    "fr-suffix",
    "fr-verb form",
    "fr-verb-form",
]


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in fr_head_templates:
            rmparam(t, "sort")
        newt = str(t)
        if origt != newt:
            p.msg("Replacing %s with %s" % (origt, newt))
            notes.append("remove sort= from {{%s}}" % tn)

    return str(parsed), notes


parser = blib.create_argparser("Remove sort= from French terms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["French lemmas", "French non-lemma forms"],
)
