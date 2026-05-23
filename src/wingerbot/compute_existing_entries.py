#!/usr/bin/env python3

# Copyright 2019 Ben Wing.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#   
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
    
# Go through a dump finding all entries by language.

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, errmsg, site

lang_utils.get_language_data()

appendix_constructed_langnames = set()

for code, lang in lang_utils.languages_by_code.items():
  if lang.get("type", "") == "appendix-constructed":
    appendix_constructed_langnames.add(lang["canonicalName"])

def process_text_on_page(index, pagetitle, pagetext):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  # We only check mainspace articles, Reconstruction articles, and
  # Appendix articles for appendix-only constructed languages.
  m = re.search("^(.*?):", pagetitle)
  if m:
    namespace = m.group(1)
    if namespace == "Reconstruction":
      pass
    elif namespace == "Appendix":
      m = re.search("^Appendix:(.*?)/", pagetitle)
      if m and m.group(1) in appendix_constructed_langnames:
        pass
      else:
        return
    else:
      return

  # Split into sections
  splitsections = re.split("(^==[^=\n]+==\n)", pagetext, 0, re.M)
  langs = []
  for k in range(1, len(splitsections), 2):
    m = re.search(r"^==\s*(.*?)\s*==\n", splitsections[k])
    if not m:
      pagemsg("WARNING: Can't parse language header?: %s" % splitsections[k].strip())
    else:
      langname = m.group(1)
      if langname not in lang_utils.languages_by_canonical_name:
        pagemsg("WARNING: Unrecognized language: %s" % langname)
      else:
        langs.append(lang_utils.languages_by_canonical_name[langname]["code"])
  pagemsg("Langs=%s" % ",".join(langs))

parser = blib.create_argparser("Find red links", include_pagefile=True,
  include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True)
