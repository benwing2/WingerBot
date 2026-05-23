#!/usr/bin/env python3

import re
from wingerbot import blib
from wingerbot.blib import msg

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  retval = blib.find_modifiable_lang_section(text, "Russian", pagemsg)
  if retval is None:
    return
  sections, j, secbody, sectail, has_non_lang = retval

  def attributive_to_relational(m):
    labels = ['relational' if x == 'attributive' else x for x in m.group(1).split('|')]
    return '{{lb|ru|%s}}' % '|'.join(labels)
  secbody = re.sub(r'\{\{lb\|ru\|(.*?)\}\}', attributive_to_relational, secbody)
  lines = secbody.split('\n')
  for line in lines:
    if '{{i|attributive}}' in line:
      pagemsg("Found {{i|attributive}}: %s" % line)
    elif 'attributive' in line:
      pagemsg("Found bare attributive: %s" % line)
  secbody = secbody.replace('{{i|attributive}}', '{{i|relational}}')

  sections[j] = secbody + sectail
  text = "".join(sections)
  return text, "attributive -> relational"

parser = blib.create_argparser("Convert attributive labels to relational",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
