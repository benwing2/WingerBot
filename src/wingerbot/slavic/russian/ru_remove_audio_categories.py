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

  found_audio = False
  for t in parsed.filter_templates():
    if str(t.name) == "audio" and getparam(t, "lang") == "ru":
      found_audio = True
      break
  if found_audio:
    new_text = re.sub(r"\n*\[\[Category:Russian terms with audio links]]\n*", "\n\n", text)
    if new_text != text:
      return new_text, "Remove redundant [[:Category:Russian terms with audio links]]"

parser = blib.create_argparser("Remove redundant audio-link categories",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_cats=["Russian terms with audio links"])
