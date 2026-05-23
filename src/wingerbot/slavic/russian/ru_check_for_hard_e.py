#!/usr/bin/env python3

# Given the file from ruwikt of words where е is pronounced hard, check
# the words in enwikt to see their pronunciations.

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, msg, errandmsg, site

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")

  props = pagetitle_to_props.get(pagetitle, None)
  if not props:
    pagemsg("WARNING: Can't find properties for page")
    return
  phon, softphon, variant = props
  if not text and not blib.safe_page_exists(pywikibot.Page(site, pagetitle), errandpagemsg):
    pagemsg("Page doesn't exist, should have pron phon=%s%s" % (phon,
      variant and " with variant %s" % variant or ""))
    return
  if "==Russian==" not in text:
    pagemsg("Page doesn't have Russian section, should have pron phon=%s%s" % (
      phon, variant and " with variant %s" % variant or ""))
    return
  if lemmas and pagetitle not in lemmas:
    pagemsg("Page doesn't have a lemma on it, should have pron phon=%s%s" % (
      phon, variant and " with variant %s" % variant or ""))
    return

  parsed = blib.parse_text(text)
  prons = []
  for t in parsed.filter_templates():
    tname = str(t.name)
    if tname in ["ru-IPA"]:
      tphon = getparam(t, "phon")
      if tphon:
        prons.append("phon=%s" % tphon)
      else:
        prons.append(getparam(t, "1") or pagetitle)
  altexpected = None
  phon = "phon=%s" % phon
  if not variant:
    expected = [phon]
  elif variant == "=":
    expected = [phon, softphon]
    altexpected = [softphon, phon]
  elif variant == "+е":
    expected = [softphon, phon]
  elif variant == "+э":
    expected = [phon, softphon]
  else:
    pagemsg("WARNING: Bad variant %s, skipping" % variant)
    return
  if altexpected:
    if prons == expected or prons == altexpected:
      pagemsg("Found pronunciation %s matching expected pronunciation %s or %s"
          % (",".join(prons), ",".join(expected), ",".join(altexpected)))
    else:
      pagemsg("WARNING: Mismatched pronunciation, found %s, expected %s or %s"
          % (",".join(prons), ",".join(expected), ",".join(altexpected)))
  else:
    if prons == expected:
      pagemsg("Found pronunciation %s matching expected pronunciation %s"
          % (",".join(prons), ",".join(expected)))
    else:
      pagemsg("WARNING: Mismatched pronunciation, found %s, expected %s"
          % (",".join(prons), ",".join(expected)))
    
parser = blib.create_argparser(
  "Check for words in enwikt that should have hard е",
  include_pagefile=True, include_stdin=True)
parser.add_argument('--direcfile', help="File containing words from ruwikt page Приложение:Русские_слова_с_твёрдым_парным_согласным_перед_Е specifying words that should have hard е",
                    required=True)
parser.add_argument('--lemmafile', help="File containing lemmas, needed to check for non-lemmas that look like lemmas")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if not args.lemmafile:
  lemmas = None
else:
  lemmas = set(blib.yield_items_from_file(args.lemmafile))

pagetitle_to_props = {}

for i, line in blib.iter_items_from_file(args.direcfile, start, end):
  if not line.startswith("*"):
    msg("Page %s ???: Ignoring line: %s" % (i, line))
  else:
    m = re.search(r"^\*\[\[([^\[\]|]*?)\|([^\[\]]*?)\]\]( \{(=|\+э|\+е)\}\??)?$", line)
    if not m:
      msg("Page %s ???: WARNING: Can't parse line: %s" % (i, line))
    else:
      phon = m.group(2)
      phon = re.sub(r"\{\{red\|е\}\}", "э", phon)
      phon = re.sub(r"\{\{red\|е́\}\}", "э́", phon)
      phon = re.sub(r"\{\{red\|ѐ\}\}", "э̀", phon)
      softphon = m.group(2)
      softphon = re.sub(r"\{\{red\|(.*?)\}\}", r"\1", softphon)
      pagetitle_to_props[m.group(1)] = (phon, softphon, m.group(4))

blib.do_pagefile_cats_refs(
  args, start, end, process_text_on_page, edit=True, stdin=True,
  default_pages=list(pagetitle_to_props.keys()))
