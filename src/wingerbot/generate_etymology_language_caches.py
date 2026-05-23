#!/usr/bin/env python3

import pywikibot, re, sys, argparse, unicodedata

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

lang_utils.get_etym_language_data()

parser = blib.create_argparser("Create code-to-canonical-name and canonical-names tables for etymology languages")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

code_to_canonical_name = {}
canonical_name_to_code = {}

for etyl in lang_utils.etym_languages:
  code = etyl["code"]
  canonical_name = etyl["canonicalName"]
  is_alias = "mainCode" in etyl and etyl["mainCode"] != code
  if code in code_to_canonical_name:
    msg("WARNING: Saw code %s twice" % code)
  code_to_canonical_name[code] = canonical_name
  if not is_alias:
    if canonical_name in canonical_name_to_code:
      msg("WARNING: Saw canonical name %s twice" % canonical_name)
    canonical_name_to_code[canonical_name] = code
  else:
    msg("is_alias = %s" % etyl)

msg("--------------------- [[Module:etymology languages/code to canonical name]] -------------------")
def do_code_to_canonical_name(index, page):
  text = []
  def ins(txt):
    text.append(txt)
  ins("return {")
  for code, name in sorted(list(code_to_canonical_name.items())):
    ins('\t["%s"] = "%s",' % (code, name))
  end
  ins("}")
  return "\n".join(text), "update [[Module:etymology languages/code to canonical name]]"

blib.do_edit(1, pywikibot.Page(site, "Module:etymology languages/code to canonical name"), do_code_to_canonical_name,
             save=args.save, verbose=args.verbose, diff=args.diff)

msg("--------------------- [[Module:etymology languages/canonical names]] -------------------")
def do_canonical_names(index, page):
  text = []
  def ins(txt):
    text.append(txt)
  ins("return {")
  for name, code in sorted(list(canonical_name_to_code.items())):
    ins('\t["%s"] = "%s",' % (name, code))
  end
  ins("}")
  return "\n".join(text), "update [[Module:etymology languages/canonical names]]"

blib.do_edit(2, pywikibot.Page(site, "Module:etymology languages/canonical names"), do_canonical_names,
             save=args.save, verbose=args.verbose, diff=args.diff)
