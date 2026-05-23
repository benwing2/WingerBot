#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

langs_to_convert = {
  "yue": "zh",
  "cmn": "zh",
  "hak": "zh",
}

langs_to_remove_sort = {
  "zh", "vi",
}

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []
          
  parsed = blib.parse_text(text)

  for t in parsed.filter_templates():
    origt = str(t)
    tn = tname(t)
    if tn == "rfdef":
      if getparam(t, "lang"):
        pagemsg("WARNING: has lang=, skipping: %s" % str(t))
        continue
      lang = getparam(t, "1")
      if lang in langs_to_convert:
        newlang = langs_to_convert[lang]
        t.add("1", newlang)
        notes.append("convert {{rfdef|%s}} to {{rfdef|%s}}" % (lang, newlang))
        lang = newlang
      if lang in langs_to_remove_sort:
        if t.has("sort"):
          rmparam(t, "sort")
          notes.append("remove sort= from {{rfdef|%s}}, now auto-computed" % lang)
    if str(t) != origt:
      pagemsg("Replaced <%s> with <%s>" % (origt, str(t)))

  return str(parsed), notes

parser = blib.create_argparser("Remove sort= from Asian-language {{rfdef}} and unify Chinese varieties", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:rfdef"]
)
