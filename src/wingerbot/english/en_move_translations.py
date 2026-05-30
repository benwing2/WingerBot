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

    modsec = blib.find_modifiable_lang_section(text, "English", pagemsg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    headers = subsecs.headers
    for k in range(2, len(subsections) - 1, 2):
        if re.search(headers_to_swap_regex, headers[k]) and (
            headers[k + 2] == "Translations"
        ):
            notes.append("swap %s and %s sections" % (headers[k], headers[k + 2]))
            temp = subsections[k - 1]
            subsections[k - 1] = subsections[k + 1]
            subsections[k + 1] = temp
            temp = subsections[k]
            subsections[k] = subsections[k + 2]
            subsections[k + 2] = temp

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Swap misordered Translations sections", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
