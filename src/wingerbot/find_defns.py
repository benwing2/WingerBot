#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  retval = blib.find_modifiable_lang_section(text, None if args.partial_page else args.langname, pagemsg,
    force_final_nls=True)
  if retval is None:
    return
  sections, j, secbody, sectail, has_non_lang = retval

  subsections, subsections_by_header, subsection_headers, subsection_levels = blib.split_text_into_subsections(
    secbody, pagemsg)
  for k in range(2, len(subsections), 2):
    header = subsection_headers[k]
    if header in poses:
      sectext = subsections[k]
      defns = blib.find_defns(sectext, args.langcode)
      pagemsg("%s: %s: %s" % (k, header, ";".join(defns)))

parser = blib.create_argparser("Find definitions for specified POS and head templates", include_pagefile=True, include_stdin=True)
parser.add_argument("--partial-page", action="store_true", help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.")
parser.add_argument("--langname", help="Language name to check.")
parser.add_argument("--langcode", help="Language code of language to check.", required=True)
parser.add_argument("--pos", help="Comma-separated list of part of speec headers to check.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

poses = set(args.pos.split(","))
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
