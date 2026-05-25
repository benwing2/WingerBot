#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    modsec = blib.find_modifiable_lang_section(
        text, None if args.partial_page else args.langname, pagemsg, force_final_nls=True
    )
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    for k, header in subsecs.subsection_headers:
        if header in poses:
            sectext = subsecs.subsections[k]
            defns = blib.find_defns(sectext, args.langcode)
            pagemsg("%s: %s: %s" % (k, header, ";".join(defns)))


parser = blib.create_argparser(
    "Find definitions for specified POS and head templates", include_pagefile=True, include_stdin=True
)
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
)
parser.add_argument("--langname", help="Language name to check.")
parser.add_argument("--langcode", help="Language code of language to check.", required=True)
parser.add_argument("--pos", help="Comma-separated list of part of speec headers to check.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

poses = set(args.pos.split(","))
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
