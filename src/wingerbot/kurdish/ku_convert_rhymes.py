#!/usr/bin/env python3

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, msg, errandmsg, tname

def process_page_for_rename(index, page):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  totitle = pagetitle.replace(":Kurdish", ":Northern Kurdish")
  comment = "Rename Rhymes:Kurdish/... -> Rhymes:Northern Kurdish/..."
  if args.save:
    try:
      page.move(totitle, reason=comment, movetalk=True, noredirect=True)
      errandpagemsg("Renamed to %s" % totitle)
    except pywikibot.PageRelatedError as error:
      errandpagemsg("Error moving to %s: %s" % (totitle, error))
      return
  else:
    errandpagemsg("Would move '%s' to '%s': comment=%s" % (pagetitle, totitle, comment))


def process_text_on_page_for_fix(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []

  newtext = re.sub(r"\[\[(.*?)\]\]", r"{{l|kmr|\1}}", text)
  if newtext != text:
    notes.append("convert raw links to {{l|kmr|...}}")
    text = newtext

  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    origt = str(t)
    tn = tname(t)
    if tn in ["l", "rhymes nav"] and getparam(t, "1") == "ku":
      t.add("1", "kmr")
      notes.append("convert {{%s|ku}} to {{%s|kmr}}" % (tn, tn))
    elif getparam(t, "1") == "ku":
      pagemsg("WARNING: Kurdish-language template of unrecognized name: %s" % str(t))
    if origt != str(t):
      pagemsg("Replaced %s with %s" % (origt, str(t)))
  text = str(parsed)

  return text, notes

parser = blib.create_argparser("Move 'Kurdish' rhymes page to Northern Kurdish",
                               include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page_for_rename, default_cats=["Kurdish rhymes"])
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page_for_fix,
                           edit=True, stdin=True, default_cats=["Kurdish rhymes"])
