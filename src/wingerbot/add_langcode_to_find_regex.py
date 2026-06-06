#!/usr/bin/env python3

from collections import defaultdict
import re

from wingerbot import blib, lang_utils

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections

    for j, langname in secs.lang_list:
        if langname not in lang_data.languages_by_canonical_name:
            p.msg("WARNING: Can't find language %s" % langname)
            continue
        langcode = lang_data.languages_by_canonical_name[langname]["code"]
        newsectext = re.sub(r"\b%s\b" % args.langcode_var, langcode, sections[j])
        if newsectext != sections[j]:
            notes.append(args.comment or "replace %s with %s" % (args.langcode_var, langcode))
            sections[j] = newsectext

    newtext = "".join(sections)
    return newtext, notes


parser = blib.create_argparser(
    "Replace LANGCODE with appropriate language code"
)
parser.add_argument(
    "--langcode-var", help="Metasyntactic variable specifying the language code; default 'LANGCODE'", default="LANGCODE"
)
parser.add_argument("--comment", help="Changelog comment to use.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
