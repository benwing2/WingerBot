#!/usr/bin/env python3

# Use past_adv_part_short=- instead of past_adv_part_short=

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  parsed = blib.parse_text(text)
  found_inflection_of = False
  found_head_verb_form = False
  for t in parsed.filter_templates():
    if str(t.name) in ["inflection of"]:
      found_inflection_of = True
    if str(t.name) == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "verb form":
      found_head_verb_form = True

  if not found_head_verb_form or not found_inflection_of:
    # Find definition line
    foundrussian = False
    sections = re.split("(^==[^=]*==\n)", text, 0, re.M)

    for j in range(2, len(sections), 2):
      if sections[j-1] == "==Russian==\n":
        if foundrussian:
          pagemsg("WARNING: Found multiple Russian sections, skipping page")
          return
        foundrussian = True

        deflines = r"\n".join(re.findall(r"^(# .*)$", sections[j], re.M))

  if not found_head_verb_form:
    pagemsg("WARNING: No {{head|ru|verb form}}: %s" % deflines)
  if not found_inflection_of:
    pagemsg("WARNING: No 'inflection of': %s" % deflines)

parser = blib.create_argparser(
  "Find badly formatted Russian verb forms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_cats=["Russian verb forms"])
