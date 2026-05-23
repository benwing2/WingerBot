#!/usr/bin/env python3

# Convert ru-ux to ux|ru or uxi|ru (depending on whether inline= is present).
# In the process, convert sub= to subst=. Don't convert if one of the
# special-purpose params noadj=, noshto=, adj= or shto= is present (the
# latter two are obsolete).

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  parsed = blib.parse_text(text)

  notes = []
  for t in parsed.filter_templates():
    if str(t.name) == "ru-ux":
      origt = str(t)
      if t.has("noadj") or t.has("noshto"):
        pagemsg("WARNING: Can't convert %s, has noadj= or noshto=" % origt)
      elif t.has("adj") or t.has("shto"):
        pagemsg("WARNING: Can't convert %s, has adj= or shto=" % origt)
      else:
        tname = "ux"
        new_params = []
        for param in t.params:
          pname = str(param.name)
          pval = str(param.value)
          if pname == "inline":
            if pval and pval not in ["0", "n", "no", "false"]:
              tname = "uxi"
          elif re.search(r"^[0-9]+$", pname):
            # move numbered params up by one
            new_params.append((str(1 + int(pname)), param.value))
          elif pname == "sub":
            new_params.append(("subst", param.value))
          else:
            new_params.append((pname, param.value))
        del t.params[:]
        t.name = tname
        t.add("1", "ru")
        for pname, pval in new_params:
          t.add(pname, pval)
        notes.append("Replace {{ru-ux}} with {{%s|ru}}" % tname)
      newt = str(t)
      if origt != newt:
        pagemsg("Replaced %s with %s" % (origt, newt))

  return parsed, notes

parser = blib.create_argparser(
  "Convert {{ru-ux}} to {{ux|ru}} or {{uxi|ru}}",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:ru-ux"])
