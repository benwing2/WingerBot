#!/usr/bin/env python3

import pywikibot, re, sys, argparse
from wingerbot import blib
from wingerbot.blib import site, msg, errandmsg

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  notes = []

  def put_attributive_first(m):
    labels = m.group(1).split('|')
    if 'attributive' in labels:
      labels_wo_attributive = [label for label in labels if label != 'attributive']
      labels = ['attributive'] + labels_wo_attributive
    return '{{lb|ru|%s}}' % '|'.join(labels)
  newtext = re.sub(r'\{\{lb\|ru\|(.*?)\}\}', put_attributive_first, text)

  if newtext != text:
    notes.append("put attributive label first")
  return newtext, notes

if __name__ == "__main__":
  parser = blib.create_argparser("Put attributive label first",
    include_pagefile=True, include_stdin=True)
  args = parser.parse_args()
  start, end = blib.parse_start_end(args.start, args.end)

  blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
