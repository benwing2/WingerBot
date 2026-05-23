#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
from wingerbot import blib
from wingerbot.blib import msg, errandmsg, site
import pywikibot

def process_page(index, page):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
  if args.verbose:
    pagemsg("Processing")
  if page.exists():
    errandpagemsg("Page already exists, not overwriting")
    return
  comment = 'Created page with "%s"' % args.contents
  if args.save:
    page.text = args.contents
    if blib.safe_page_save(page, comment, errandpagemsg):
      errandpagemsg("Created page, comment = %s" % comment)
  else:
    pagemsg("Would create, comment = %s" % comment)

params = blib.create_argparser("Create pages", include_pagefile=True)
params.add_argument("--contents", help="Contents of pages", required=True)
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page)
