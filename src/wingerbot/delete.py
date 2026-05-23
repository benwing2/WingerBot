#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
from wingerbot import blib
from wingerbot.blib import msg, errandmsg, site
import pywikibot

def process_page(index, page, args, comment):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
  if args.verbose:
    pagemsg("Processing")
  this_comment = comment or 'delete page'
  if blib.safe_page_exists(page, errandpagemsg):
    if args.save:
      existing_text = blib.safe_page_text(page, errandpagemsg, bad_value_ret=None)
      if existing_text is not None:
        page.delete('%s (content was "%s")' % (this_comment, existing_text))
        errandpagemsg("Deleted (comment=%s)" % this_comment)
    else:
      pagemsg("Would delete (comment=%s)" % this_comment)
  else:
    pagemsg("Skipping, page doesn't exist")

params = blib.create_argparser("Delete pages", include_pagefile=True)
params.add_argument("--comment", help="Specify the change comment to use")
params.add_argument("--direcfile", help="File containing pages to delete, optionally with comments after ' ||| '.")
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.direcfile:
  for index, line in blib.iter_items_from_file(args.direcfile, start, end):
    if " ||| " in line:
      pagetitle, page_comment = line.split(" ||| ")
    else:
      pagetitle = line
      page_comment = args.comment or 'delete file'
    page = pywikibot.Page(site, pagetitle)
    process_page(index, page, args, page_comment)
else:
  def do_process_page(index, page):
    return process_page(index, page, args, args.comment)
  blib.do_pagefile_cats_refs(args, start, end, do_process_page)
