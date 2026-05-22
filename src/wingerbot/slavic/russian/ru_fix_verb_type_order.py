#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []

  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    origt = str(t)
    if str(t.name) in ["ru-conj", "ru-conj-old"]:
      verbtype = getparam(t, "2")
      if verbtype in ["pf", "pf-intr", "pf-refl",
          "pf-impers", "pf-intr-impers", "pf-refl-impers",
          "impf", "impf-intr", "impf-refl",
          "impf-impers", "impf-intr-impers", "impf-refl-impers"]:
        conjtype = getparam(t, "1")
        t.add("2", conjtype)
        t.add("1", verbtype)
        notes.append("move verb type from arg 2 to arg 1")
    newt = str(t)
    if origt != newt:
      pagemsg("Replaced %s with %s" % (origt, newt))

  return str(parsed), notes

parser = blib.create_argparser("Move verb type from arg 2 to arg 1",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_cats=["Russian verbs"])
