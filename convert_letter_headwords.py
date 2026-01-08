#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, tname, pname, msg, site
blib.getLanguageData()

ordinal_to_cardinal = {}
ordinals = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
            "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth",
            "nineteenth"]
for card, ordinal in enumerate(ordinals, start=1):
  ordinal_to_cardinal[ordinal] = card
for tencard, tens in enumerate(["twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"], start=2):
  ordinal_to_cardinal[tens[:-1] + "ieth"] = 10 * tencard
  for onecard, ones in enumerate(ordinals[0:9], start=1):
    ordinal_to_cardinal["%s-%s" % (tens, ones)] = 10 * tencard + onecard

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def expand_text(tempcall):
    return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

  parsed = blib.parse_text(text)

  notes = []

  for t in parsed.filter_templates():
    tn = tname(t)
    def getp(param):
      return getparam(t, param).strip()
    if tn in ["head", "head-lite"] and getp("2") in ["letter", "letters"]:
      lang = getp("1")
      def langpagemsg(txt):
        msg("Page %s %s, lang %s: %s" % (index, pagetitle, lang, txt))
      manual_translit = None
      infls = blib.fetch_param_chain(t, "3", holes="allow")
      inflgroups = []
      for i in range(len(infls)):
        if i % 2 == 0:
          key = (infls[i] or "").strip()
          if i + 1 < len(infls):
            value = (infls[i + 1] or "").strip()
          else:
            value = ""
          if key:
            inflgroups.append((key, value))
          elif value:
            langpagemsg("WARNING: Saw value '%s' with blank key: %s" % (value, str(t)))
      for k, v in inflgroups:
        #langpagemsg("k=%s, v=%s" % (k, v))
        if len(pagetitle) == 1:
          if k in ["upper case", "uppercase", "upper"]:
            if not v:
              if not pagetitle.isupper():
                langpagemsg("WARNING: Page title supposed to be uppercase but is not (uppercase is %s)" % (
                  pagetitle.upper()))
                break
            elif v != pagetitle.upper():
              langpagemsg("WARNING: Page title's uppercase equivalent is supposed to be %s but is %s" % (
                v, pagetitle.upper()))
              break
          elif k in ["lower case", "lowercase", "lower"]:
            if not v:
              if not pagetitle.islower():
                langpagemsg("WARNING: Page title supposed to be lowercase but is not (lowercase is %s)" % (
                  pagetitle.lower()))
                break
            elif v != pagetitle.lower():
              langpagemsg("WARNING: Page title's lowercase equivalent is supposed to be %s but is %s" % (
                v, pagetitle.lower()))
              break
          else:
            langpagemsg("WARNING: Unrecognized key-value pair '%s=%s'" % (k, v))
            break
        else:
          firstchar = pagetitle[0]
          if k in ["upper case", "uppercase", "upper"]:
            if not v:
              if not firstchar.isupper():
                langpagemsg("WARNING: Page title (first char) supposed to be uppercase but is not (uppercase is %s)" % (
                  pagetitle.upper()))
                break
            else:
              shouldbe_allcaps = pagetitle.upper()
              shouldbe_upper = firstchar.upper() + pagetitle[1:]
              if shouldbe_allcaps == shouldbe_upper:
                shouldbe = [shouldbe_allcaps]
              else:
                shouldbe = [shouldbe_upper, shouldbe_allcaps]
              if v not in shouldbe:
                langpagemsg("WARNING: Page title's uppercase equivalent is supposed to be %s but is %s" % (
                  v, " or ".join(shouldbe)))
                break
          elif k in ["lower case", "lowercase", "lower"]:
            if not v:
              if not firstchar.islower():
                langpagemsg("WARNING: Page title supposed to be lowercase but is not (lowercase is %s)" % (
                  pagetitle.lower()))
                break
            elif v != pagetitle.lower():
              langpagemsg("WARNING: Page title's lowercase equivalent is supposed to be %s but is %s" % (
                v, pagetitle.lower()))
              break
          else:
            langpagemsg("WARNING: Unrecognized key-value pair '%s=%s'" % (k, v))
            break
      else: # no break
        for param in t.params:
          pn = pname(param)
          pv = str(param.value).strip()
          if pn in ["tr", "tr1"]:
            translit = expand_text("{{xlit|%s|%s}}" % (lang, pagetitle))
            if translit != pv:
              langpagemsg("WARNING: Automatic translit '%s' doesn't match specified manual translit '%s'" % (
                translit, pv))
              manual_translit = pv
          elif not re.search("^[0-9]+$", pn) and pn != "langname" and pn != "sc":
            langpagemsg("WARNING: Unrecognized param %s=%s" % (pn, pv))
            break
        else: # no break
          origt = str(t)
          notes.append("replace {{head|%s|%s}} with {{letter|%s}}" % (lang, getp("2"), lang))
          blib.set_template_name(t, "letter")
          del t.params[:]
          t.add("1", lang)
          if manual_translit:
            t.add("tr", manual_translit)
          newt = str(t)
          langpagemsg("Replaced %s with %s" % (origt, newt))

  text = str(parsed)
  sections, sections_by_lang, lang_sections = blib.split_text_into_sections(text, pagemsg)
  lang_sections = dict(lang_sections)
  for j in range(2, len(sections), 2):
    sectext = sections[j]
    seclang = lang_sections[j]
    def replace_ordinal_def(m):
      ordinal, alphabet, alphtype = m.groups()
      if ordinal not in ordinal_to_cardinal:
        pagemsg("WARNING: Unrecognized ordinal '%s' in ordinal definition line for lang %s: %s" % (
          ordinal, seclang, m.group(0)))
        return m.group(0)
      cardinal = ordinal_to_cardinal[ordinal]
      if seclang not in blib.languages_byCanonicalName:
        pagemsg("WARNING: Unrecognized language '%s' in section %s for ordinal definition line: %s" % (
          seclang, j, m.group(0)))
        return m.group(0)
      langcode = blib.languages_byCanonicalName[seclang]["code"]
      alphabet = re.sub(r"[\[\]]", "", alphabet)
      notes.append("replace ordinal definition for '%s' letter of '%s' alphabet with {{%s|...}}" % (
        ordinal, alphabet, args.letter_def))
      if alphabet != seclang:
        pagemsg("WARNING: Alphabet name '%s' not same as language '%s' in ordinal definition line: %s" % (
          alphabet, seclang, m.group(0)))
        return "# {{%s|%s|letter|%s|alphabet=the [[%s]] [[%s]]}}" % (
            args.letter_def, langcode, cardinal, alphabet, alphtype)
      else:
        return "# {{%s|%s|letter|%s}}" % (args.letter_def, langcode, cardinal)

    newsectext = re.sub("^# '*The ([a-z-]*(?:st|nd|rd|th)) letter of the (.*?) (alphabet|abjad|abugida)['.]*$", replace_ordinal_def,
                        sectext, 0, re.M)
    sections[j] = newsectext
  text = "".join(sections)
  return text, notes

parser = blib.create_argparser("Convert {{head|LANG|letter}} to {{letter|LANG}}",
  include_pagefile=True, include_stdin=True)
parser.add_argument("--letter-def", default="Latn-def", help="Template to use in letter definitions")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
