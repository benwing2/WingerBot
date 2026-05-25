#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(
        text, None if args.partial_page else args.langname, pagemsg, force_final_nls=True
    )
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(text, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.subsection_headers:
        if header == "Anagrams" and k + 1 < len(subsections):
            subsections = subsections[0 : k - 1] + subsections[k + 1 : len(subsections)] + subsections[k - 1 : k + 1]
            notes.append("put Anagrams last in %s section" % args.langname)
            break

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("put Anagrams last", include_pagefile=True, include_stdin=True)
parser.add_argument("--langname", required=True, help="Language name.")
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
