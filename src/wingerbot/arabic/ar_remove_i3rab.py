#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname
from wingerbot.arabic.arlib import (
  ALIF, ALIF_WASLA, A, AN, UN, U, UUN, UUNA, I, reorder_shadda,
)

verbose = True

def remove_i3rab(index, pagetitle, entry, word, nowarn=False):
  def mymsg(text):
    if not nowarn:
      msg("Page %s %s: Entry %s: %s" % (index, pagetitle, entry, text))
  word = reorder_shadda(word)
  if word.endswith(UN):
    mymsg("Removing i3rab (UN) from %s" % word)
    return re.sub(UN + "$", "", word)
  if word.endswith(U):
    mymsg("Removing i3rab (U) from %s" % word)
    return re.sub(U + "$", "", word)
  if word.endswith(UUNA):
    mymsg("Removing i3rab (UUNA -> UUN) from %s" % word)
    return re.sub(UUNA + "$", UUN, word)
  if word and word[-1] in [A, I, U, AN]:
    mymsg("FIXME: Strange diacritic at end of %s" % word)
  if word and word[0] == ALIF_WASLA:
    mymsg("Changing alif wasla to plain alif for %s" % word)
    word = ALIF + word[1:]
  return word

def do_nouns(poses, headtempls, save, start, end):
  def do_one_page_noun(index, page):
    pagetitle = str(page.title())
    def pagemsg(txt):
      msg("Page %s %s: %s" % (index, pagetitle, txt))
    def errandpagemsg(txt):
      errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)
    nouncount = 0
    nounids = []
    for t in text.filter_templates():
      if tname(t) in headtempls:
        nouncount += 1
        params_done = []
        entry = getparam(t, "1")
        for param in t.params:
          value = param.value
          newvalue = remove_i3rab(index, pagetitle, entry, str(value))
          if newvalue != value:
            param.value = newvalue
            params_done.append(str(param.name))
        if params_done:
          nounids.append("#%s %s %s (%s)" %
              (nouncount, tname(t), entry, ", ".join(params_done)))
    return str(parsed), "Remove i3rab from params in %s" % (
          '; '.join(nounids))

  for pos in poses:
    for index, page in blib.cat_articles("Arabic %ss" % pos.lower(), start, end):
      blib.do_edit(index, page, do_one_page_noun, save=save, verbose=verbose)

def do_verbs(save, start, end):
  def do_one_page_verb(index, page):
    pagetitle = str(page.title())
    def pagemsg(txt):
      msg("Page %s %s: %s" % (index, pagetitle, txt))
    def errandpagemsg(txt):
      errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)

    verbcount = 0
    verbids = []
    for t in parsed.filter_templates():
      if tname(t) == "ar-conj":
        verbcount += 1
        vnvalue = getparam(t, "vn")
        uncertain = False
        if vnvalue.endswith("?"):
          vnvalue = vnvalue[:-1]
          pagemsg("Verbal noun(s) identified as uncertain")
          uncertain = True
        if not vnvalue:
          continue
        vns = re.split("[,،]", vnvalue)
        form = getparam(t, "1")
        verbid = "#%s form %s" % (verbcount, form)
        if re.match("^[1I](-|$)", form):
          verbid += " (%s,%s)" % (getparam(t, "2"), getparam(t, "3"))
        no_i3rab_vns = []
        for vn in vns:
          no_i3rab_vns.append(remove_i3rab(index, pagetitle, verbid, vn))
        newvn = ",".join(no_i3rab_vns)
        if uncertain:
          newvn += "?"
        if newvn != vnvalue:
          pagemsg("Verb %s, replacing %s with %s" % (
            verbid, vnvalue, newvn))
          addparam(t, "vn", newvn)
          verbids.append(verbid)
    return str(parsed), "Remove i3rab from verbal nouns for verb(s) %s" % (
          ', '.join(verbids))
  for index, page in blib.cat_articles("Arabic verbs", start, end):
    blib.do_edit(index, page, do_one_page_verb, save=save, verbose=verbose)
          
parser = blib.create_argparser("Remove i3rab")
parser.add_argument("--verb", action='store_true',
    help="Do verbal nouns in verbs")
parser.add_argument("--noun", action='store_true',
    help="Do arguments in nouns")

params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)

if params.noun:
  do_nouns(["noun", "adjective"],
    ["ar-noun", "ar-coll-noun", "ar-sing-noun", "ar-nisba", "ar-noun-nisba",
      "ar-adj", "ar-numeral"],
    params.save, start, end)
if params.verb:
  do_verbs(params.save, start, end)
