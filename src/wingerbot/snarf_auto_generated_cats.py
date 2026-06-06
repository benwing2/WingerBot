#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)
    templates_to_expand = args.templates_to_expand.split(",") if args.templates_to_expand else []
    lang_templates_to_expand = args.lang_templates_to_expand.split(",") if args.lang_templates_to_expand else []
    if args.skip_langs:
        skip_lang_codes = args.skip_langs.split(",")
    else:
        skip_lang_codes = []
    if args.include_langs:
        include_lang_codes = args.include_langs.split(",")
    else:
        include_lang_codes = []
    for t in parsed.filter_templates():
        should_expand_template = False
        tn = tname(t)
        if tn in lang_templates_to_expand:
            should_expand_template = True
        elif tn in templates_to_expand:
            langcode = getparam(t, "1")
            if include_lang_codes and getparam(t, "1") not in include_lang_codes:
                pass
            elif skip_lang_codes and langcode in skip_lang_codes:
                pass
            else:
                should_expand_template = True
        if should_expand_template:
            expanded = p.expand_text(str(t))
            if not expanded:
                continue
            for cattext in re.findall(args.category_regex, expanded):
                p.msg("Found snarfed category: %s" % cattext[2:-2])


if __name__ == "__main__":
    parser = blib.create_argparser("Find categories to snarf")
    parser.add_argument(
        "--templates-to-expand", default="rhymes,rhyme", help="Templates to look for rhymes categories in"
    )
    parser.add_argument(
        "--lang-templates-to-expand",
        default=None,
        # Could be 'fi-pronunciation,fi-p' for example.
        help="Lang-specific templates to look for rhymes categories in",
    )
    parser.add_argument("--skip-langs", help="Skip these language codes.")
    parser.add_argument("--include-langs", help="Only include these language codes.")
    parser.add_argument(
        "--category-regex",
        help="Regex used to snarf out categories; should include double square brackets at both ends.",
        default=r"\[\[Category:Rhymes:.*?\]\]",
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
