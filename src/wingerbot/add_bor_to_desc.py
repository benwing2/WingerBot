#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from collections import defaultdict
import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname

lang_utils.get_all_lang_data()

language_to_ancestors = lang_utils.get_language_to_ancestors_map()
etym_language_to_parent = lang_utils.get_etym_language_to_parent_map()

def lang_desc(lang, main_lang):
  if lang == main_lang:
    return lang
  else:
    return "%s (main language %s)" % (lang, main_lang)

bor_pairs = defaultdict(int)
already_bor_would_bor_pairs = defaultdict(int)

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  notes = []
  lines = re.split("\n", text)
  newlines = []
  langs_at_levels = {}
  for line in lines:
    thisline_lang = None
    m = re.search("^([*]+:*)", line)
    if not m:
      langs_at_levels = {}
    else:
      thisline_indent = len(m.group(1))
      if "{{desc|" in line or "{{desctree|" in line:
        parsed = blib.parse_text(line)
        did_mod = False
        for t in parsed.filter_templates():
          tn = tname(t)
          if tn in ["desc", "desctree"]:
            thisline_lang = getparam(t, "1")
            pagemsg("Saw descendant template %s with lang %s" % (str(t), thisline_lang))
            prevline_lang = langs_at_levels.get(thisline_indent - 1, None)
            if thisline_lang and prevline_lang:
              thisline_main_lang = etym_language_to_parent.get(thisline_lang, thisline_lang)
              prevline_main_lang = etym_language_to_parent.get(prevline_lang, prevline_lang)
              if prevline_lang == thisline_lang:
                pagemsg("Something strange, saw same language %s indented under itself" % prevline_lang)
              elif prevline_lang == thisline_main_lang:
                pagemsg("Saw etym language %s indented under its parent %s" % (thisline_lang, prevline_lang))
              elif prevline_main_lang == thisline_lang:
                pagemsg("Saw language %s indented under its etym language %s" % (thisline_lang, prevline_lang))
              elif prevline_main_lang == thisline_main_lang:
                pagemsg("Saw etym language %s indented under etym language %s, both with the same parent %s" % (
                  thisline_lang, prevline_lang, prevline_main_lang))
              elif thisline_main_lang not in language_to_ancestors:
                pagemsg("WARNING: Something strange, saw unrecognized main lang %s for lang %s" % (
                  thisline_main_lang, thisline_lang))
              elif prevline_main_lang in language_to_ancestors[thisline_main_lang]:
                if prevline_main_lang == prevline_lang:
                  pagemsg("Saw language %s indented under parent %s" % (
                    lang_desc(thisline_lang, thisline_main_lang), lang_desc(prevline_lang, prevline_main_lang)))
              elif getparam(t, "bor").lower() in ["1", "y", "yes", "true"]:
                pagemsg("Saw language %s indented under non-parent %s, would add |bor=1 but |bor=%s already present" % (
                  lang_desc(thisline_lang, thisline_main_lang), lang_desc(prevline_lang, prevline_main_lang),
                  getparam(t, "bor")))
                already_bor_would_bor_pairs[(thisline_lang, prevline_lang)] += 1
              else:
                pagemsg("Saw language %s indented under non-parent %s, adding |bor=1" % (
                  lang_desc(thisline_lang, thisline_main_lang), lang_desc(prevline_lang, prevline_main_lang)))
                t.add("bor", "1")
                bor_pairs[(thisline_lang, prevline_lang)] += 1
                did_mod = True
                notes.append("add bor=1 to {{%s|%s}} indented under non-parent %s" % (
                  tn, thisline_lang, lang_desc(prevline_lang, prevline_main_lang)))
            langs_at_levels[thisline_indent] = thisline_lang
        if did_mod:
          line = str(parsed)
      else:
        langs_at_levels[thisline_indent] = None
    newlines.append(line)
  newtext = "\n".join(newlines)
  return newtext, notes

parser = blib.create_argparser("Add |bor=1 to {{desc}} where appropriate",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

msg("Pairs of langs (PARENT -> CHILD) with |bor=1 added:")
for (thislang, prevlang), count in sorted(bor_pairs.items(), key=lambda x:-x[1]):
  msg("%s -> %s\t%s\t(already %s)" % (prevlang, thislang, count, already_bor_would_bor_pairs[(thislang, prevlang)]))
msg("Pairs of langs (PARENT -> CHILD) with |bor=1 already added and would add:")
for (thislang, prevlang), count in sorted(already_bor_would_bor_pairs.items(), key=lambda x:-x[1]):
  msg("%s -> %s\t%s" % (prevlang, thislang, count))
