#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, set_template_name, msg, errmsg, site, tname, pname

def process_text_on_page(index, pagename, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagename, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagename, txt))

  notes = []

  parsed = blib.parse_text(text)
  for t in parsed.filter_templates():
    origt = str(t)
    tn = tname(t)
    if tn in templates_to_do:
      for param in t.params:
        pn = pname(param)
        pv = str(param.value)
        if "{{{PAGENAME}}}" in pv or "{{{SUBPAGENAME}}}" in pv:
          pagemsg("WARNING: Saw triple-brace {{{PAGENAME}}} or {{{SUBPAGENAME}}}, not replacing: %s=%s" % (pn, pv))
        else:
          changed = False
          if "{{PAGENAME}}" in pv:
            pv = pv.replace("{{PAGENAME}}", "{{pagename}}")
            notes.append("replace {{PAGENAME}} with {{pagename}} in {{%s}}" % tn)
            changed = True
          if "{{SUBPAGENAME}}" in pv:
            pv = pv.replace("{{SUBPAGENAME}}", "{{pagename}}")
            notes.append("replace {{SUBPAGENAME}} with {{pagename}} in {{%s}}" % tn)
            changed = True
          if changed:
            param.value = pv

    if args.verbose and origt != str(t):
      pagemsg("Replaced %s with %s" % (origt.replace("\n", r"\n"), str(t).replace("\n", r"\n")))

  return str(parsed), notes

parser = blib.create_argparser("Replace {{PAGENAME}} and {{SUBPAGENAME}} with {{pagename}} in specified templates",
                               include_pagefile=True, include_stdin=True)
parser.add_argument("--templates", help="Comma-separated list of templates to process arguments of",
                    default="head,l,l-self,l,m-self,lang")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
templates_to_do = set(args.templates.split(","))
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
