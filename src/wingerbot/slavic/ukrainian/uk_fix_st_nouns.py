#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

from wingerbot.slavic.ukrainian import uklib

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  notes = []

  pagemsg("Processing")
          
  parsed = blib.parse_text(text)

  head = None
  for t in parsed.filter_templates():
    origt = str(t)
    tn = tname(t)
    if tn == "uk-noun":
      gen = blib.fetch_param_chain(t, "3", "gen")
      if len(gen) == 1 and gen[0].endswith("і"):
        gen2 = gen[0][0:-1] + "и"
        t.add("gen2", gen2, before="4")
    elif tn in ["uk-decl-noun", "uk-decl-noun-unc", "uk-decl-noun-pl"]:
      gensparam = 3 if tn == "uk-decl-noun" else 2
      gens = getparam(t, str(gensparam))
      if "," not in gens and gens.endswith("і"):
        gens += ", " + gens[0:-1] + "и"
        t.add(str(gensparam), gens)
    if origt != str(t):
      notes.append("add alternative genitive singular to Ukrainian nouns ending in -сть")
      pagemsg("Replaced %s with %s" % (origt, str(t)))

  return str(parsed), notes

parser = blib.create_argparser("Add alternative genitive singular to Ukrainian nouns ending in -сть",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
