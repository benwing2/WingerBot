#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from collections import defaultdict
import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname

lang_utils.get_all_lang_data()

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []

  sections = re.split("(^==[^=]*==\n)", text, 0, re.M)

  for j in range(2, len(sections), 2):
    m = re.search("^== *(.*?) *==\n$", sections[j - 1])
    assert m
    langname = m.group(1)
    if langname not in lang_utils.languages_by_canonical_name:
      pagemsg("WARNING: Can't find language %s" % langname)
      continue
    langcode = lang_utils.languages_by_canonical_name[langname]["code"]
    newsectext = re.sub(r"\b%s\b" % args.langcode_var, langcode, sections[j])
    if newsectext != sections[j]:
      notes.append(args.comment or "replace %s with %s" % (args.langcode_var, langcode))
      sections[j] = newsectext

  newtext = "".join(sections)
  return newtext, notes

parser = blib.create_argparser("Replace LANGCODE with appropriate language code",
    include_pagefile=True, include_stdin=True)
parser.add_argument("--langcode-var", help="Metasyntactic variable specifying the language code; default 'LANGCODE'", default="LANGCODE")
parser.add_argument("--comment", help="Changelog comment to use.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
