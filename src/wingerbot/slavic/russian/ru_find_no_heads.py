#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Go through all the terms we can find looking for pages that are
# missing a headword declaration.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

poses = ["nouns", "proper nouns", "pronouns", "determiners", "adjectives", "verbs", "participles",
         "adverbs", "prepositions", "conjunctions", "interjections", "idioms", "phrases",
         "abbreviations", "acronyms", "initialisms", "noun forms", "proper noun forms",
         "pronoun forms", "determiner forms", "verb forms", "adjective forms", "participle forms"]
ru_normal_head_templates = ["ru-noun", "ru-proper noun", "ru-verb", "ru-adj",
  "ru-adv", "ru-phrase", "ru-noun form", "ru-diacritical mark"]
ru_special_head_templates = ["ru-noun+", "ru-proper noun+", "ru-noun-alt-ё",
  "ru-proper noun-alt-ё", "ru-adj-alt-ё", "ru-verb-alt-ё", "ru-pos-alt-ё"]
ru_head_templates = ru_normal_head_templates + ru_special_head_templates
ru_heads_to_warn_about = ["abbreviation", "acronym", "initialism", "idiom",
    "phrase", "adverb", "adjective", "verb", "noun", "proper noun"]

overall_head_count = {}

def output_heads_seen():
  dic = overall_head_count
  msg("Overall templates seen:")
  for head, count in sorted(dic.items(), key=lambda x:-x[1]):
    msg("  %s = %s" % (head, count))

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  parsed = blib.parse_text(text)
  found_page_head = False
  for t in parsed.filter_templates():
    found_this_head = False
    tname = str(t.name)
    if tname in ru_head_templates:
      headname = tname
      found_this_head = True
    elif tname == "head" and getparam(t, "1") == "ru":
      headtype = getparam(t, "2")
      headname = "head|ru|%s" % headtype
      if headtype in ru_heads_to_warn_about:
        pagemsg("WARNING: Found %s" % headname)
      found_this_head = True
    if found_this_head:
      overall_head_count[headname] = overall_head_count.get(headname, 0) + 1
      found_page_head = True
  if not found_page_head:
    pagemsg("WARNING: No head")
  if index % 100 == 0:
    output_heads_seen()

parser = blib.create_argparser("Find Russian terms without a proper headword line",
                               include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
  default_cats=["Russian %x" for x in poses], edit=True, stdin=True)
output_heads_seen()
