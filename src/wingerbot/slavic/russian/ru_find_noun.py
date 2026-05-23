#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

def process_text_on_page(index, pagetitle, text):
  subpagetitle = re.sub(".*:", "", pagetitle)
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  if ":" in pagetitle:
    pagemsg("WARNING: Colon in page title, skipping")
    return

  notes = []

  parsed = blib.parse_text(text)

  for t in parsed.filter_templates():
    if str(t.name) in ["ru-noun", "ru-proper noun"]:
      param3 = getparam(t, "3")
      if param3 == "-":
        pagemsg("Found indeclinable noun")
      elif "[[Category:Russian indeclinable nouns]]" in text:
        pagemsg("WARNING: Indeclinable noun but not marked in template")
      else:
        for tt in parsed.filter_templates():
          ttname = str(tt.name)
          if ttname == "ru-noun-alt-ё":
            pagemsg("Found alternative ё spelling")
            break
          elif ttname == "misspelling of":
            pagemsg("Found misspelling of")
            break
          elif ttname == "ru-pre-reform":
            for ttt in parsed.filter_templates():
              if str(ttt.name) == "ru-noun-old":
                pagemsg("Found pre-reform word with ru-noun-old declension")
                break
            else:
              pagemsg("Found pre-reform word without ru-noun-old declension")
            break
        else:
          pagemsg("WARNING: Found declinable non-pre-reform noun")

parser = blib.create_argparser("Find cases of declined ru-noun uses")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:ru-noun", "Template:ru-proper noun"])
