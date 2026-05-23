#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, errandmsg, site
from wingerbot.latin import lalib

def check_participle(form, pagemsg):
  orig_pagemsg = pagemsg
  def pagemsg(txt):
    orig_pagemsg("%s: %s" % (form, txt))
  if "[" in form or "|" in form:
    pagemsg("Skipping form with brackets or vertical bar")
    return
  page = pywikibot.Page(site, lalib.remove_macrons(form))
  if not blib.safe_page_exists(page, pagemsg):
    pagemsg("Skipping nonexistent page")
  parsed = blib.parse_text(str(page.text))
  for t in parsed.filter_templates():
    tn = tname(t)
    if tn == "la-part":
      actual_part = re.sub("/.*", "", getparam(t, "1"))
      if actual_part != form:
        pagemsg("WARNING: Found actual participle %s, expected %s" % (
          actual_part, form))

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
  def expand_text(tempcall):
    return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

  pagemsg("Processing")

  parsed = blib.parse_text(text)

  for t in parsed.filter_templates():
    tn = tname(t)
    if tn == "la-conj":
      vargs = lalib.generate_verb_forms(str(t), errandpagemsg,
        expand_text)
      for partslot in ["pres_actv_ptc", "perf_actv_ptc", "perf_pasv_ptc",
          "futr_actv_ptc", "futr_pasv_ptc"]:
        if partslot in vargs:
          forms = vargs[partslot].split(",")
          for form in forms:
            check_participle(form, pagemsg)

parser = blib.create_argparser("Check macrons of Latin verbs against participles",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True,
    default_cats=["Latin verbs"])
