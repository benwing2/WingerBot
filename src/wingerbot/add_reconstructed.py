#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  if blib.page_should_be_ignored(pagetitle):
    pagemsg("Skipping ignored page")
    return

  notes = []
  if not re.search(r"\{\{reconstruct(ed|ion)\}\}", text):
    text = "{{reconstructed}}\n" + text
    notes.append("add missing {{reconstructed}} to Reconstruction: pages")
  elif re.search(r"\A\{\{reconstruct(ed|ion)\}\}\n", text):
    pass
  elif re.search(r"\A\{\{also\|.*?\}\}\n\{\{reconstruct(ed|ion)\}\}\n", text):
    pass
  elif re.search(r"\A\{\{reconstruct(ed|ion)\}\}", text):
    pagemsg("WARNING: Missing newline after initial {{reconstructed}}/{{reconstruction}}")
  else:
    pagemsg("WARNING: Page has {{reconstructed}}/{{reconstruction}} not at beginning: <%s>" % text)
  return text, notes

parser = blib.create_argparser("Add {{reconstructed}} to Reconstruction: pages where missing",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
