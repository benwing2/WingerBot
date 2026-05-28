#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

headers_to_swap = [
    "Further reading",
    "See also",
    "Statistics",
    "References",
    "Anagrams",
]

headers_to_swap_regex = "^(%s)$" % "|".join(headers_to_swap)


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(
        text, None if args.partial_page else "English", pagemsg, force_final_nls=True
    )
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    subsection_header_dict = subsecs.subsection_header_dict
    for k in range(1, len(subsections) - 2, 2):
        if re.search(headers_to_swap_regex, subsection_header_dict[k + 1]) and (
            subsection_header_dict[k + 3] == "Translations"
        ):
            notes.append("swap %s and %s sections" % (subsection_header_dict[k + 1], subsection_header_dict[k + 3]))
            temp = subsections[k]
            subsections[k] = subsections[k + 2]
            subsections[k + 2] = temp
            temp = subsections[k + 1]
            subsections[k + 1] = subsections[k + 3]
            subsections[k + 3] = temp

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Swap misordered Translations sections", include_pagefile=True, include_stdin=True)
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
