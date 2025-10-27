#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from collections import defaultdict
import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, msg, site, tname, pname

sh_headwords = {
  "sh-adjective", "sh-adj",
  "sh-adverb", "sh-adv",
  "sh-conjunction", "sh-con",
  "sh-contraction", "sh-cont",
  "sh-idiom",
  "sh-interfix",
  "sh-interjection",
  "sh-letter",
  "sh-noun",
  "sh-noun form", "sh-noun-form",
  "sh-numeral",
  "sh-participle",
  "sh-particle",
  "sh-phrase",
  "sh-prefix",
  "sh-preposition",
  "sh-pronoun", "sh-pron",
  "sh-pronoun-form", "sh-pronoun form",
  "sh-proper noun",
  "sh-proper-noun-form",
  "sh-proverb",
  "sh-suffix",
  "sh-verb",
  "sh-verb-form",
}

rename_sh_headwords = {
  "sh-adjective": "sh-adj",
  "sh-adverb": "sh-adv",
  "sh-conjunction": "sh-con",
  "sh-cont": "sh-contr",
  "sh-contraction": "sh-contr",
  "sh-noun-form": "sh-noun form",
  "sh-numeral": "sh-num",
  "sh-participle": "sh-part",
  "sh-particle": "sh-pcl",
  "sh-preposition": "sh-prep",
  "sh-pronoun": "sh-pron",
  "sh-pronoun-form": "sh-pron form",
  "sh-pronoun form": "sh-pron form",
  "sh-proper noun": "sh-propn",
  "sh-proper-noun-form": "sh-propn form",
  "sh-verb-form": "sh-verb form",
}


def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []

  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    tn = tname(t)
    if tn in sh_headwords:
      head = None
      g = []
      remaining_params = []
      params_moved = []
      for param in t.params:
        pn = pname(param)
        pv = str(param.value)
        if pn in ["head", "head1"]:
          if not pv:
            notes.append("remove blank %s= in {{%s}}" % (pn, tn))
          elif pv == pagetitle and " " not in pagetitle:
            notes.append("remove %s= same as pagename in {{%s}}" % (pn, tn))
          else:
            head = pv
            params_moved.append("%s->1" % pn)
        elif pn in ["g", "g2", "a"]:
          if not pv:
            notes.append("remove blank %s= in {{%s}}" % (pn, tn))
          else:
            if pv in ["pf-impf", "impf-pf", "dual", "ip"]:
              pv = "biasp"
            g.append(pv)
            params_moved.append("%s->2" % pn)
        elif re.search("^head[0-9]+$", pn):
          remaining_params.append((pn, pv))
          if not head:
            pagemsg("WARNING: Saw %s=%s without head=" % (pn, pv))
        else:
          remaining_params.append((pn, pv))
      del t.params[:]
      if head:
        t.add("1", head)
      if g:
        if not head:
          t.add("1", "")
        t.add("2", ",".join(g))
      for pn, pv in remaining_params:
        t.add(pn, pv, preserve_spacing=False)
      if params_moved:
        notes.append("move %s in {{%s}}" % (", ".join(params_moved), tn))
    if tn in rename_sh_headwords:
      blib.set_template_name(t, rename_sh_headwords[tn])
      notes.append("rename {{%s}} to {{%s}} for consistency" % (tn, rename_sh_headwords[tn]))

  return str(parsed), notes

parser = blib.create_argparser("Move head= to 1= and g= to 2= in Serbo-Croatian headwords and rename headwords",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
