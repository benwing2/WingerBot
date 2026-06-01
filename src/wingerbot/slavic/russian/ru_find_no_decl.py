#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    found_headword_template = False
    headword_templates = []
    found_invariant_headword_template = False
    found_decl_template = False
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["ru-noun", "ru-proper noun"]:
            found_headword_template = True
            if getparam(t, "3") == "-":
                found_invariant_headword_template = True
            else:
                headword_templates.append(str(t))
        if tn in ["ru-noun-table", "ru-decl-noun-see"]:
            found_decl_template = True
    if found_headword_template and not found_invariant_headword_template:
        if found_decl_template:
            p.msg("Found old-style headword template(s) %s with decl" % ", ".join(headword_templates))
        else:
            p.msg("Found old-style headword template(s) %s without decl" % ", ".join(headword_templates))


parser = blib.create_argparser("Find Russian nouns without declension", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    new=True,
    default_refs=["Template:ru-noun", "Template:ru-proper noun"],
    # default_refs=["Template:tracking/ru-headword/space-in-headword/%s" % pos for pos in ["nouns", "proper nouns"]],
)
