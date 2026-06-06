#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

french_head_templates = [
    "fr-abbr",
    "fr-adj",
    "fr-adv",
    "fr-diacritical mark",
    "fr-intj",
    "fr-noun",
    "fr-phrase",
    "fr-prefix",
    "fr-prep",
    "fr-prep phrase",
    "fr-pron",
    "fr-proper noun",
    "fr-punctuation mark",
    "fr-verb",
]

french_head_templates_1_not_head = [
    "fr-adj",
    "fr-noun",
    "fr-proper noun",
]


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in french_head_templates:
            if getparam(t, "head"):
                rmparam(t, "head")
                notes.append("remove redundant head= from {{%s}}" % tn)
            if tn not in french_head_templates_1_not_head and getparam(t, "1"):
                rmparam(t, "1")
                notes.append("remove redundant 1= from {{%s}}" % tn)
            if str(t) != origt:
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove redundant head params from French headwords"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:tracking/fr-headword/redundant-head"],
)
