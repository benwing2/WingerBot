#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from wingerbot import blib
from wingerbot.blib import getparam, addparam, errandmsg, tname

def rewrite_one_page_ar_plural(index, page):
  pagetitle = str(page.title())
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
  text = blib.safe_page_text(page, errandpagemsg)
  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    if tname(t) == "ar-plural":
      t.name = "ar-noun-pl"

  return str(parsed), "rename {{temp|ar-plural}} to {{temp|ar-noun-pl}}"

def rewrite_ar_plural(save, verbose, start, end):
  for cat in ["Arabic plurals"]:
    for index, page in blib.cat_articles(cat, start, end):
      blib.do_edit(index, page, rewrite_one_page_ar_plural, save=save, verbose=verbose)

parser = blib.create_argparser("Rewrite ar-plural to ar-noun-pl templates")
params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)

rewrite_ar_plural(params.save, params.verbose, start, end)
