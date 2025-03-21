#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, msg, site, tname

import rulib

def process_text_on_page(index, pagetitle, text):
  global args
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  notes = []

  section = blib.find_lang_section(pagetext, "Russian", pagemsg)
  if not section:
    return

  if "==Etymology" in section:
    return
  if rulib.check_for_alt_yo_terms(section, pagemsg):
    return
  parsed = blib.parse_text(section)
  for t in parsed.filter_templates():
    if tname(t) in ["ru-participle of"]:
      pagemsg("Skipping participle")
      return

  msg("%s no-etym" % pagetitle)

# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser("Find Russian terms without etymology",
    include_pagefile=True, include_stdin=True, canonicalize_pagename=rulib.remove_accents)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_cats=["Russian lemmas"])
