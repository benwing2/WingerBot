#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

parser = blib.create_argparser(
  "Find usexes with 'literally' in them",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  lines = text.split("\n")
  for line in lines:
    if re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*[Ll]it(erally|\.)", line):
      pagemsg("Found literally with usex: %s" % line)
    elif re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*\{\{(i|qualifier)\|", line):
      pagemsg("Found qualifier with usex: %s" % line)
    elif re.search(r"\{\{(i|qualifier)\|.*\{\{(ru-ux|uxi?\|ru)\|", line):
      pagemsg("Found qualifier with usex: %s" % line)
    elif re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*\|ref=&#32;", line):
      pagemsg("Found ref=space with usex: %s" % line)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True)
