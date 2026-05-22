#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname

lang_utils.get_all_lang_data()

def process_page(page, index):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  seen_cats = set()
  parsed = blib.parse(page)
  for t in parsed.filter_templates():
    tn = tname(t)
    if tn in blib.translation_templates:
      lang = getparam(t, "1").strip()
      if lang in lang_utils.languages_by_code:
        langname = lang_utils.languages_by_code[lang]["canonicalName"]
      elif lang in lang_utils.etym_languages_by_code:
        langname = lang_utils.etym_languages_by_code[lang]["canonicalName"]
      else:
        pagemsg("WARNING: Unrecognized lang code %s" % lang)
        continue
      seen_cats.add("Category:Terms with %s translations" % langname)
  for cat in sorted(list(seen_cats)):
    msg(cat)

parser = blib.create_argparser("Generate 'Terms with LANG translations' categories", include_pagefile=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page)
