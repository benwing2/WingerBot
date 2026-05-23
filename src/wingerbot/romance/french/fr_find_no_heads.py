#!/usr/bin/env python3

# Go through all the French terms we can find looking for pages that are
# missing a headword declaration.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

default_poses=["nouns", "proper nouns", "pronouns", "determiners", "adjectives", "verbs",
               "participles", "adverbs", "prepositions", "conjunctions", "interjections",
               "idioms", "phrases", "abbreviations", "acronyms", "initialisms", "noun forms",
               "proper noun forms", "pronoun forms", "determiner forms", "verb forms",
               "adjective forms", "participle forms", "proverbs", "prefixes", "suffixes",
               "diacritical marks", "punctuation marks"]
fr_head_templates = ["fr-noun", "fr-proper noun", "fr-proper-noun",
  "fr-verb", "fr-adj", "fr-adv", "fr-phrase", "fr-adj form", "fr-adj-form",
  "fr-abbr", "fr-diacritical mark", "fr-intj", "fr-letter",
  "fr-past participle", "fr-prefix", "fr-prep", "fr-pron",
  "fr-punctuation mark", "fr-suffix", "fr-verb form", "fr-verb-form"]
fr_heads_to_warn_about = ["abbreviation", "acronym", "initialism", "idiom",
    "phrase", "adverb", "adjective", "adjective form", "verb", "noun",
    "proper noun", "prefix", "suffix", "interjection", "diacritical mark",
    "letter", "past participle", "preposition", "pronoun", "punctuation mark"]

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
    if tname in fr_head_templates:
      headname = tname
      found_this_head = True
    elif tname == "head" and getparam(t, "1") == "fr":
      headtype = getparam(t, "2")
      headname = "head|fr|%s" % headtype
      if headtype in fr_heads_to_warn_about:
        pagemsg("WARNING: Found %s" % str(t))
      found_this_head = True
    if found_this_head:
      overall_head_count[headname] = overall_head_count.get(headname, 0) + 1
      found_page_head = True
  if not found_page_head:
    pagemsg("WARNING: No head")
  if index % 100 == 0:
    output_heads_seen()

parser = blib.create_argparser("Find French terms without a proper headword line",
                               include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, stdin=True,
  default_cats=["French %s" % pos for pos in default_poses])
output_heads_seen()
