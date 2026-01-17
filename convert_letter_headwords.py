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

def convert_ordinal_to_cardinal(num):
  num = num.lower().replace(" ", "-")
  return ordinal_to_cardinal.get(num, None)

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def expand_text(tempcall):
    return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

  parsed = blib.parse_text(text)

  notes = []
  notes_replace_head_letter_langs = []

  for t in parsed.filter_templates():
    tn = tname(t)
    def getp(param):
      return getparam(t, param).strip()
    if tn in ["head", "head-lite"] and getp("2") in ["letter", "letters"]:
      lang = getp("1")
      def langpagemsg(txt):
        msg("Page %s %s, lang %s: %s" % (index, pagetitle, lang, txt))
      manual_translit = None
      Cyrillic_equivalent = None
      Devanagari_equivalent = None
      sort_key = None
      headparam = None
      infls = blib.fetch_param_chain(t, "3", holes="allow")
      inflgroups = []
      for i in range(len(infls)):
        if i % 2 == 0:
          key = (infls[i] or "").strip()
          if ", " in key:
            key1, key = key.split(", ", 1)
            inflgroups.append((key1, ""))
          if i + 1 < len(infls):
            value = (infls[i + 1] or "").strip()
          else:
            value = ""
          if value.startswith(":") and len(value) >= 2:
            value = value[1:]
          if key in ["Cyrillic", "Cyrillic spelling", "Cyrillic equivalent"]:
            if Cyrillic_equivalent is not None:
              langpagemsg("WARNING: Saw two Cyrillic equivalents %s and %s" % (Cyrillic_equivalent, value))
            else:
              Cyrillic_equivalent = value
              continue
          if key in ["Devanagari", "Devanagari spelling", "Devanagari equivalent"]:
            if Devanagari_equivalent is not None:
              langpagemsg("WARNING: Saw two Devanagari equivalents %s and %s" % (Devanagari_equivalent, value))
            else:
              Devanagari_equivalent = value
              continue
          if key:
            inflgroups.append((key, value))
          elif value:
            langpagemsg("WARNING: Saw value '%s' with blank key: %s" % (value, str(t)))
      for k, v in inflgroups:
        #langpagemsg("k=%s, v=%s" % (k, v))
        if len(pagetitle) == 1:
          if k in ["upper case", "uppercase", "upper", "capital"]:
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
          if k in ["upper case", "uppercase", "upper", "capital"]:
            if not v:
              if not firstchar.isupper():
                langpagemsg("WARNING: Page title (first char) supposed to be uppercase but is not (uppercase is %s)" % (
                  pagetitle.upper()))
                break
            else:
              shouldbe_upper = firstchar.upper() + pagetitle[1:]
              if v not in shouldbe_upper:
                langpagemsg("WARNING: Page title's uppercase equivalent is supposed to be %s but is %s" % (
                  v, shouldbe_upper))
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
          elif pn == "sort":
            if sort_key is not None:
              langpagemsg("WARNING: Saw two sort keys %s and %s" % (sort_key, pv))
              break
            sort_key = pv
          elif pn == "head":
            if headparam is not None:
              langpagemsg("WARNING: Saw two heads %s and %s" % (headparam, pv))
              break
            headparam = pv
          elif not re.search("^[0-9]+$", pn) and pn != "langname" and pn != "sc":
            langpagemsg("WARNING: Unrecognized param %s=%s" % (pn, pv))
            break
        else: # no break
          origt = str(t)
          notes_replace_head_letter_langs.append(lang)
          blib.set_template_name(t, "letter")
          del t.params[:]
          t.add("1", lang)
          if headparam:
            t.add("head", headparam)
          if manual_translit:
            t.add("tr", manual_translit)
          if sort_key:
            t.add("sort", sort_key)
          nextind = 2
          if Cyrillic_equivalent:
            t.add(str(nextind), "Cyrl:" + Cyrillic_equivalent)
            nextind += 1
          if Devanagari_equivalent:
            t.add(str(nextind), "Deva:" + Devanagari_equivalent)
            nextind += 1
          newt = str(t)
          langpagemsg("Replaced %s with %s" % (origt, newt))

  text = str(parsed)
  if notes_replace_head_letter_langs:
    notes.append("replace {{head|LANG|letter}} with {{letter|LANG}} for %s" %
                 ", ".join(notes_replace_head_letter_langs))
  notes_replace_ordinal_def = []
  sections, sections_by_lang, lang_sections = blib.split_text_into_sections(text, pagemsg)
  lang_sections = dict(lang_sections)
  for j in range(2, len(sections), 2):
    sectext = sections[j]
    seclang = lang_sections[j]
    if seclang not in blib.languages_byCanonicalName:
      pagemsg("WARNING: Unrecognized language '%s' in section %s" % (seclang, j))
      continue
    langcode = blib.languages_byCanonicalName[seclang]["code"]
    def replace_ordinal_def(m):
      label, ordinal, letter_group, rest = m.groups()
      cardinal = convert_ordinal_to_cardinal(ordinal)
      if cardinal is None:
        pagemsg("WARNING: Unrecognized ordinal '%s' in ordinal definition line for lang %s: %s" % (
          ordinal, seclang, m.group(0)))
        return m.group(0)
      m = re.search(r"of (?:the )?(.+?) \[*(alphabet|abjad|abugida)\]*(.*)$", rest)
      def alphrest_in_default_script(alphrest):
        return args.letter_def == "Arab-def" and alphrest.lower() in [
          "arabic script", "perso-arabic script", "shahmukhi script", "{{w|shahmukhi}} script"
        ] or args.letter_def == "letter def" and alphrest.lower() in [
          "devanagari", "devanagari script",
        ]
      if m:
        alphabet, alphtype, alphrest = m.groups()
      else:
        m = re.search(r"(?:of|in) (?:the )?\[\[([^\[\]\n]+?)\]\](.*)$", rest)
        if m:
          alphabet, alphrest = m.groups()
          alphtype = "alphabet"
      if m:
        alphrest = alphrest.replace("[", "").replace("]", "").strip()
        alphrest = re.sub("^, written ", "", alphrest)
        alphrest = re.sub("^in ", "", alphrest)
        alphrest = re.sub("^the ", "", alphrest)
        if not alphrest or alphrest_in_default_script(alphrest):
          alphabet = re.sub(r"[\[\]]", "", alphabet)
          notes_replace_ordinal_def.append("%s %s" % (ordinal, alphabet))
          #notes.append("replace ordinal definition for '%s' letter of '%s' alphabet with {{%s|...}}" % (
          #  ordinal, alphabet, args.letter_def))
          if alphabet != seclang:
            pagemsg("WARNING: Alphabet name '%s' not same as language '%s' in ordinal definition line: %s" % (
              alphabet, seclang, m.group(0)))
            return "# %s{{%s|%s|%s|%s|alphabet=the [[%s]] [[%s]]}}" % (
                label, args.letter_def, langcode, letter_group, cardinal, alphabet, alphtype)
          else:
            return "# %s{{%s|%s|%s|%s}}" % (label, args.letter_def, langcode, letter_group, cardinal)

      notes_replace_ordinal_def.append("%s %s" % (ordinal, seclang))
      #notes.append("partially replace ordinal definition for '%s' letter of '%s' alphabet with {{%s|...}}" % (
      #  ordinal, seclang, args.letter_def))
      return "# %s{{%s|%s|%s|%s}}FIXME: %s" % (label, args.letter_def, langcode, letter_group, cardinal, rest)

    sectext = re.sub(r"^# ((?:\{\{[^{}\n]*\}\} )?)(?:'*|\{\{(?:ng|n-g|non-gloss|n-g-lite)\|)?[Tt]he \[*([a-z -]*(?:st|nd|rd|th))\]* \[*(letter|consonant|vowel)\]* (.*?)['.}]*$",
                     replace_ordinal_def, sectext, 0, re.M)
    sections[j] = sectext

    parsed = blib.parse_text(sections[j])
    letter_def_template = None
    for t in parsed.filter_templates():
      tn = tname(t)
      if tn == args.letter_def:
        if letter_def_template:
          pagemsg("WARNING: Saw two {{%s}} templates for lang %s, %s and %s, skipping" % (
            args.letter_def, seclang, str(letter_def_template), str(t)))
          break
        letter_def_template = t
    else: # no break
      if letter_def_template:
        secjbody, secjtail = blib.force_two_newlines_in_secbody(sections[j])
        lines = secjbody.split("\n")
        prec = None
        foll = None
        newlines = []
        for line in lines:
          m = re.search(r"^\* Previous letter: *\{\{l\|%s\|([^|{}]*)(?:\|tr=([^{}|]*))?\}\} *$" % langcode, line)
          if m:
            newprec = m.group(1)
            if m.group(2):
              newprec += "<tr:%s>" % m.group(2)
            if prec:
              pagemsg("WARNING: For lang %s, saw two 'Previous letter' letters: %s and %s, skipping" % (
                seclang, prec, newprec))
              break
            prec = newprec
          else:
            m = re.search(r"^\* Next letter: *\{\{l\|%s\|([^|{}]*)(?:\|tr=([^{}|]*))?\}\} *$" % langcode, line)
            if m:
              newfoll = m.group(1)
              if m.group(2):
                newfoll += "<tr:%s>" % m.group(2)
              if foll:
                pagemsg("WARNING: For lang %s, saw two 'Next letter' letters: %s and %s, skipping" % (
                  seclang, foll, newfoll))
                break
              foll = newfoll
            else:
              newlines.append(line)
        else: # no break
          if prec or foll:
            new_letter_def_template = str(letter_def_template)
            precfollparam = (prec and "|prec=%s" % prec or "") + (foll and "|foll=%s" % foll or "")
            new_letter_def_template = new_letter_def_template[0:-2] + precfollparam + "}}"
            newsectext = "\n".join(newlines)
            newsectext, replaced = blib.replace_in_text(newsectext, str(letter_def_template), new_letter_def_template,
                                                        pagemsg)
            if replaced:
              notes.append("move %s into {{%s|%s}}" % (precfollparam, args.letter_def, langcode))
              secjbody = newsectext
              newsecjbody = re.sub(r"\n\n===*See also===*\n\n", "\n\n", secjbody)
              if secjbody != newsecjbody:
                notes.append("remove now-blank ==See also== section")
                secjbody = newsecjbody
              sections[j] = secjbody.rstrip("\n") + secjtail

  text = "".join(sections)
  if notes_replace_ordinal_def:
    notes.append("replace ordinal def for %s letter with {{%s|...}}" % (
      ", ".join(notes_replace_ordinal_def), args.letter_def))
  return text, notes

parser = blib.create_argparser("Convert {{head|LANG|letter}} to {{letter|LANG}} and letter definitions to {{letter def}}",
  include_pagefile=True, include_stdin=True)
parser.add_argument("--letter-def", default="letter def", help="Template to use in letter definitions")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
