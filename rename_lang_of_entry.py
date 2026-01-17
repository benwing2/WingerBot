#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, msg, site, tname

def process_text_on_page(index, pagetitle, text):
  global args
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  if ":" in pagetitle and not re.search("^(Appendix|Reconstruction|Citations):", pagetitle):
    return

  origtext = text
  pagemsg("Processing")
  notes = []

  # Split into sections
  text, orig_secfinalnl = blib.force_two_newlines_in_secbody(text)
  sections, sections_by_lang, section_langs = blib.split_text_into_sections(text, pagemsg)
  pagehead = sections[0]

  # Convert to a list of three items: language name, section header, section text minus separator.
  keyed_sections = []
  for i in range(2, len(sections), 2):
    _, langname = section_langs[i // 2 - 1]
    secheader = sections[i - 1]
    sectext = sections[i]
    keyed_sections.append([langname, secheader, sectext])

  # Make sure new language section not already present.
  for i in range(len(keyed_sections)):
    if keyed_sections[i][0] == args.tolang:
      pagemsg("WARNING: Already saw %s section, skipping" % args.tolang)
      return

  # Change language name.
  for i in range(len(keyed_sections)):
    if keyed_sections[i][0] == args.fromlang:
      keyed_sections[i][0] = args.tolang
      keyed_sections[i][1] = "==%s==\n" % args.tolang

  text = pagehead + "".join(
    secheader + sectext for langname, secheader, sectext in sorted(keyed_sections, key=lambda sec: blib.langname_key(sec[0]))
  )

  text = text.rstrip("\n") + orig_secfinalnl

  if text != origtext:
    notes.append("move %s section to %s%s" % (args.fromlang, args.tolang, " (%s)" % args.comment_tag if args.comment_tag else ""))
  return text, notes

parser = blib.create_argparser("Move entries from one language to another", include_pagefile=True, include_stdin=True)
parser.add_argument("--fromlang", required=True, help="Existing language to rename.")
parser.add_argument("--tolang", required=True, help="New name of language.")
parser.add_argument("--comment-tag", help="Tag to add to changelog message indicating reason for renaming.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
