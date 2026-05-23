#!/usr/bin/env python3

# Remove adj= and shto= from ru-ux.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")
  parsed = blib.parse_text(text)

  notes = []
  for t in parsed.filter_templates():
    if str(t.name) == "ru-ux":
      origt = str(t)
      if t.has("adj"):
        pagemsg("Removing adj=")
        notes.append("remove adj= from ru-ux")
        rmparam(t, "adj")
      if t.has("shto"):
        pagemsg("Removing shto=")
        notes.append("remove shto= from ru-ux")
        rmparam(t, "shto")
      newt = str(t)
      if origt != newt:
        pagemsg("Replaced %s with %s" % (origt, newt))

  return str(parsed), notes

parser = blib.create_argparser("Remove adj= and shto= from ru-ux",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:ru-ux"])
