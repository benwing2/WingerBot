#!/usr/bin/env python3

# Find Russian verbs with missing past passive participles. All such verbs should
# be imperfective transitive, since perfective transitive verbs lacking
# a past participle specification will cause an error. In particular, we
# look for unpaired verbs, since paired verbs generally don't have
# PPP's.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site
from wingerbot.slavic.russian import rulib

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  parsed = blib.parse_text(text)
  notes = []
  saw_paired_verb = False
  for t in parsed.filter_templates():
    if str(t.name) == "ru-verb":
      saw_paired_verb = False
      if getparam(t, "2") in ["impf", "both"]:
        verb = getparam(t, "1") or pagetitle
        pfs = blib.fetch_param_chain(t, "pf", "pf")
        impfs = blib.fetch_param_chain(t, "impf", "impf")
        for otheraspect in pfs + impfs:
          if verb[0:2] == otheraspect[0:2]:
            saw_paired_verb = True
    if (str(t.name) in ["ru-conj", "ru-conj-old"] and
        getparam(t, "1") == "impf" and not saw_paired_verb):
      if getparam(t, "ppp") or getparam(t, "past_pasv_part"):
        pass
      elif [x for x in t.params if str(x.value) == "or"]:
        pagemsg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
        pass
      elif re.search(r"\+p|\[?\([78]\)\]?", getparam(t, "2")):
        pass
      else:
        pagemsg("Apparent unpaired transitive imperfective without PPP")
        if pagetitle in pagetitle_to_direcs:
          direc = pagetitle_to_direcs[pagetitle]
          assert direc in ["fixed", "paired", "intrans", "+p", "|ppp=-"]
          origt = str(t)
          if direc == "+p":
            t.add("2", getparam(t, "2") + "+p")
            notes.append("add missing past passive participle to transitive unpaired imperfective verb")
            pagemsg("Add missing PPP, replace %s with %s" % (origt, str(t)))
          elif direc == "|ppp=-":
            t.add("ppp", "-")
            notes.append("note transitive unpaired imperfective verb as lacking past passive participle")
            pagemsg("Note no PPP, replace %s with %s" % (origt, str(t)))
          elif direc == "paired":
            pagemsg("Verb actually is paired")
          elif direc == "fixed":
            pagemsg("WARNING: Unfixed verb marked as fixed")
          elif direc == "intrans":
            pagemsg("WARNING: Transitive verb marked as intrans")

  return str(parsed), notes

parser = blib.create_argparser(
  "Find verbs with missing past passive participles",
  include_pagefile=True, include_stdin=True)
parser.add_argument('--fix-pagefile', help="File containing pages to fix.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_direcs = {}

if args.fix_pagefile:
  fixdireclines = [x.strip() for x in open(args.fix_pagefile, "r", encoding="utf-8")]
  for line in fixdireclines:
    verb, direc = re.split(" ", line)
    pagetitle_to_direcs[verb] = direc
  blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True,
    default_pages=list(pagetitle_to_direcs.keys()))
else:
  blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True,
    default_cats=["Russian verbs"])
