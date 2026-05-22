#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname

lang_utils.get_all_lang_data()

templates = [
  "pos a",
  "pos adj",
  "pos adv",
  "pos adverb",
  "pos n",
  "pos noun",
  "pos v",
  "pos verb"
]

pos_to_pos = {
  'a': 'a',
  'adj': 'a',
  'adv': 'adv',
  'adverb': 'adv',
  'n': 'n',
  'noun': 'n',
  'v': 'v',
  'verb': 'v'
}

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")
  notes = []

  def replace_pos(m):
    return "%s|pos=%s}}" % (m.group(1), pos_to_pos[m.group(2)])

  newtext = re.sub(r"(\{\{l\|.*?)\}\} \{\{pos[ _](.*?)\}\}", replace_pos,
      text)
  if newtext != text:
    notes.append("move {{pos *}} inside of link")
    text = newtext

  sections = re.split("(^==[^=]*==\n)", text, 0, re.M)

  for j in range(2, len(sections), 2):
    m = re.search("^==(.*)==\n$", sections[j - 1])
    assert m
    langname = m.group(1)
    if langname not in lang_utils.languages_by_canonical_name:
      langnamecode = None
    else:
      langnamecode = lang_utils.languages_by_canonical_name[langname]["code"]
    def replace_raw_pos(m):
      if not langnamecode:
        msg("WARNING: Unable to parse langname %s when trying to replace raw link %s" % (
          langname, m.group(0)))
        return m.group(0)
      return "\n* {{l|%s|%s|pos=%s}}" % (langnamecode, m.group(1), pos_to_pos[m.group(2)])
    newsec = re.sub(r"\n\* \[\[([^\[\]\n]*?)\]\] \{\{pos[ _](.*?)\}\}",
        replace_raw_pos, sections[j])
    if newsec != sections[j]:
      notes.append("move {{pos *}} inside of raw link")
      sections[j] = newsec

  text = "".join(sections)

  return text, notes

parser = blib.create_argparser(
  "Move {{pos *}} declarations inside of links", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:%s" for template in templates])
