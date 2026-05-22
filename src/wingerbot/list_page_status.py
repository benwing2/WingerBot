#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

# List whether pages exist and if so, are redirects and/or contain a specific language.

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  exists = not not text or blib.safe_page_exists(pywikibot.Page(site, pagetitle), pagemsg)
  if not exists:
    outtext = "does not exist"
  else:
    if re.search("#redirect", text, re.I):
      outtext = "exists as redirect"
    elif args.lang:
      if "==%s==" % args.lang in text:
        outtext = "exists in %s" % args.lang
      else:
        outtext = "exists but not in %s" % args.lang
    else:
      outtext = "exists"
  pagemsg(outtext)

parser = blib.create_argparser("List whether pages exist", include_pagefile=True, include_stdin=True)
parser.add_argument("--lang", help="Indicate whether the page contains an entry for the specified language")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True)
