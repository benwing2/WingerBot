#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

import pywikibot

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname

def fix_tool_place_noun(save, verbose, start, end):
  for tn in ["ar-tool noun", "ar-noun of place", "ar-instance noun"]:
    # Fix the template refs. If cap= is present, remove it; else, add lc=.
    def fix_one_page_tool_place_noun(index, page):
      pagetitle = str(page.title())
      def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))
      def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
      text = blib.safe_page_text(page, errandpagemsg)
      parsed = blib.parse_text(text)
      for t in parsed.filter_templates():
        if tname(t) == tn:
          if getparam(t, "cap"):
            pagemsg("Template %s: Remove cap=" % tn)
            t.remove("cap")
          else:
            pagemsg("Template %s: Add lc=1" % tn)
            addparam(t, "lc", "1")
      changelog = "%s: If cap= is present, remove it, else add lc=" % template
      return str(parsed), changelog

    for index, page in blib.references("Template:" + template, start, end):
      blib.do_edit(index, page, fix_one_page_tool_place_noun, save=save,
          verbose=verbose)

parser = blib.create_argparser("Fix lc vs. cap in tool/place noun etym templates")
params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)

fix_tool_place_noun(params.save, params.verbose, start, end)
