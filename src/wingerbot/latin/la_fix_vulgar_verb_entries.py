#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, errandmsg, site
from wingerbot.latin import lalib

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  template = pagetitle_to_template.get(pagetitle, None)
  if not template:
    pagemsg("WARNING: No template for page")
    return

  notes = []

  if "{{la-verb|" in text:
    newtext = re.sub(r"\{\{la-verb\|.*?\}\}", template, text, 1)
    if newtext != text:
      notes.append("convert Vulgar Latin {{la-verb}} to new-style")
      return newtext, notes

parser = blib.create_argparser(
  "Fix Vulgar Latin verb entries to use new-style {{la-verb}}",
  include_pagefile=True, include_stdin=True)
parser.add_argument("--direcfile", help="List of directives to process.",
    required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_template = {}
for i, line in blib.iter_items_from_file(args.direcfile, start, end):
  m = re.search("^Page [0-9]+ (Reconstruction:.*): WARNING: Saw verb headword template but no conjugation template: ({{la-verb.*}})$", line)
  if m:
    page, template = m.groups()
    pagetitle_to_template[page] = template

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_pages=list(pagetitle_to_template.keys()))
