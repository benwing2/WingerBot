#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")
  notes = []

  parsed = blib.parse_text(text)

  for t in parsed.filter_templates():
    tn = tname(t)
    if tn == template:
      for i in range(2, 10):
        if getparam(t, str(i)):
          break
      else:
        pagemsg("Found %s template without parts: %s" % (template, str(t)))

parser = blib.create_argparser("Find templates without any parts", include_pagefile=True, include_stdin=True)
parser.add_argument("--templates",
    help="""Comma-separated list of names of template to check for.""")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, stdin=True,
  default_refs=["Template:%s" % template for template in args.templates.split(",")]
)
