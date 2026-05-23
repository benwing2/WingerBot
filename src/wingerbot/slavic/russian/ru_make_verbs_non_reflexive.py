#!/usr/bin/env python3

import pywikibot, re, sys, argparse, copy

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []

  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    origt = str(t)
    if tname(t) in ["ru-conj", "ru-conj-old", "User:Benwing2/ru-conj",
        "User:Benwing2/ru-conj-old"]:
      t.add("1", getparam(t, "1").replace("-refl", ""))
    elif tname(t) == "temp" and getparam(t, "1") == "ru-conj":
      t.add("2", getparam(t, "2").replace("-refl", ""))
    newt = str(t)
    if origt != newt:
      notes.append("remove -refl from verb type")
      pagemsg("Replaced %s with %s" % (origt, newt))

  return parsed, notes

parser = blib.create_argparser(
  "Fix up verb conjugations to not specify -refl",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:ru-conj-old"],
  default_cats=["Russian verbs"],
  default_pages=["User:Benwing2/test-ru-verb", "User:Benwing2/test-ru-verb-2", "Module:ru-verb/documentation"],
)
