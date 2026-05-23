#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

from wingerbot.slavic.russian import rulib

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")
  parsed = blib.parse_text(text)

  notes = []
  for t in parsed.filter_templates():
    origt = str(t)
    if str(t.name) == "wikipedia":
      val = getparam(t, "1")
      newval = rulib.remove_accents(val)
      if val != newval:
        pagemsg("Removing Russian accents from 1= in {{wikipedia|...}}")
        notes.append("remove Russian accents from 1= in {{wikipedia|...}}")
        t.add("1", newval)
    newt = str(t)
    if origt != newt:
      pagemsg("Replaced %s with %s" % (origt, newt))

  return str(parsed), notes

parser = blib.create_argparser("Remove Russian accents from 1= in {{wikipedia|...}}",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
