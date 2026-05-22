#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname

from wingerbot.slavic.bulgarian import bglib
from wingerbot.slavic.bulgarian.bglib import AC, GR

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []
  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    tn = tname(t)
    origt = str(t)
    param = None
    if tn in ["bg-noun", "bg-proper noun", "bg-verb", "bg-adj", "bg-adv",
        "bg-part", "bg-part form", "bg-verbal noun", "bg-verbal noun form",
        "bg-phrase"]:
      param = "1"
    elif tn == "head" and getparam(t, "1") == "bg":
      param = "head"
    if param:
      val = getparam(t, param)
      val = bglib.decompose(val)
      if GR in val:
        val = val.replace(GR, AC)
        t.add(param, val)
        notes.append("convert grave to acute in {{%s}}" % tn)
    if str(t) != origt:
      pagemsg("Replaced %s with %s" % (origt, str(t)))
  return str(parsed), notes

parser = blib.create_argparser("Change grave to acute in Bulgarian headwords",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
    default_cats=["Bulgarian lemmas", "Bulgarian non-lemma forms"], edit=1)
