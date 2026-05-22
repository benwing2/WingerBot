#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  parsed = blib.parse_text(text)

  found_headword_template = False
  for t in parsed.filter_templates():
    if str(t.name) in ["ru-adj"]:
      found_headword_template = True
  if not found_headword_template:
    notes = []
    for t in parsed.filter_templates():
      if str(t.name) in ["ru-noun", "ru-noun+", "ru-proper noun", "ru-proper noun+"]:
        notes.append("found noun header (%s)" % str(t.name))
      if str(t.name) == "head":
        notes.append("found head header (%s)" % getparam(t, "2"))
    pagemsg("Missing adj headword template%s" % (notes and "; " + ",".join(notes)))

parser = blib.create_argparser(
  "Find missing Russian adjective headwords", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:ru-decl-adj"])
