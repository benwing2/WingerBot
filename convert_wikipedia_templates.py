#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, tname, pname, msg, site

lang_category_namespaces = {
  "es": "Categoría",
  "et": "Kategooria",
  "cs": "Kategorie",
  "sv": "Kategori",
  "ht": "Kategori",
  "no": "Kategori",
  "nn": "Kategori",
  "hu": "Kategória",
  "pl": "Kategoria",
  "lv": "Kategorija",
}

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  parsed = blib.parse_text(text)

  notes = []

  for t in parsed.filter_templates():
    tn = tname(t)
    def getp(param):
      return getparam(t, param).strip()
    if tn in ["wikipedia", "wp", "slim-wikipedia", "swp"]:
      lang = getp("lang")
      if lang == "en":
        lang = ""
      lang = lang and lang + ":" or ""
      link = getp("1")
      link_label = getp("2")
      link_fragment = getp("section")
      link2 = getp("mul")
      link2_label = getp("mullabel")
      cat = getp("cat") or getp("category")
      cat2 = getp("mulcat")
      cat2_label = getp("mulcatlabel")
      portal = getp("portal")
      sc = getp("sc")

      # Attempt to convert category formatted as an article to a proper category spec, e.g. {{wikipedia|lang=cs|Kategorie:Slitiny}}
      if not (cat or cat2) and ":" in link:
        linkpref, rest = link.split(":", 1)
        if linkpref == "Category" or lang and linkpref.lower() == lang_category_namespaces.get(lang[:-1], "Category").lower():
          cat = rest
          link = link_label
          link_label = None

      def make_link(link, label, fragment=None):
        origlink = link
        def canonicalize_part(part, match_case_to_pagetitle=False):
          part = part.replace("_", " ").replace("{{PAGENAME}}", pagetitle)
          if match_case_to_pagetitle and pagetitle not in part:
            if pagetitle in blib.ucfirst(part):
              part = blib.ucfirst(part)
            elif pagetitle in blib.lcfirst(part):
              part = blib.lcfirst(part)
          if len(pagetitle) >= 3:
            return part.replace(pagetitle, "\1").replace("+", r"\+").replace("\1", "+")
          else:
            return part.replace("+", r"\+")
          return part
        link = canonicalize_part(link, match_case_to_pagetitle=True)
        if label:
          label = canonicalize_part(label, match_case_to_pagetitle=True)
        if fragment:
          fragment = canonicalize_part(fragment, match_case_to_pagetitle=False)
        if label == link:
          label = None
        if label and blib.lcfirst(link) == label:
          link = blib.lcfirst(link)
          label = None
        if label and blib.ucfirst(link) == label:
          link = blib.ucfirst(link)
          label = None
        if "#" in link and fragment:
          pagemsg("WARNING: Saw both # in link '%s' and section=%s, ignoring section: %s" % (link, fragment, str(t)))
          fragment = None
        if label and not fragment and (label + " (disambiguation)" == link or label + " (disambiguation)" == origlink):
          return "<dab>" if label == "+" else "%s<dab>" % label
        if not label and not fragment and link.endswith(" (disambiguation)"):
          val = "%s<dab!>" % (link[:-len(" (disambiguation)")])
          if val == "+<dab!>":
            val = "<dab!>"
          return val
        dab = ""
        if link.endswith(" (disambiguation)"):
          link = link[:-len(" (disambiguation)")]
          if label.endswith(" (disambiguation)"):
            label = label[:-len(" (disambiguation)")]
            dab = "<dab!>"
          else:
            dab = "<dab>"
        if label:
          if ":" in label:
            pagemsg("WARNING: Colon in label '%s', needs manual review: %s" % (label, str(t)))
          # Check for pipe trick reductions
          if label != "+" and (re.search("^" + re.escape(label) + r" \(.*\)$", link) or (
            "," not in label and re.search("^" + re.escape(label) + ",.*$", link)
          )):
            pagemsg("NOTE: Applying pipe trick to link '%s', label '%s': %s" % (link, label, str(t)))
            label = ""
          return "[[%s%s|%s]]%s" % (link, "#" + fragment if fragment else "", label, dab)
        if fragment:
          link = "%s#%s" % (link, fragment)
        if re.search(",[^ ]", link):
          return "[[%s]]%s" % (link, dab)
        if ":" in link:
          pagemsg("WARNING: Colon in link '%s', needs manual review: %s" % (link, str(t)))
          if re.search("^[a-z][a-z-]+:[^ ]", link):
            pagemsg("WARNING: Link '%s' looks to have Wikimedia lang prefix, needs manual review: %s" % (link, str(t)))
            return "[[%s]]%s" % (link, dab)
        if link == "+":
          link = ""
        return link + dab

      if (cat or cat2) and link2:
        pagemsg("WARNING: Both category and article specified, can't handle: %s" % str(t))
        continue
      if portal and link2:
        pagemsg("WARNING: Both portal and article specified, can't handle: %s" % str(t))
        continue

      catparam = None
      portalparam = None
      linkparam = None
      if (cat or cat2):
        formatted_cat = make_link(cat, link or cat)
        formatted_cat2 = make_link(cat2, cat2_label or cat2)
        catparam = []
        if formatted_cat:
          catparam.append(formatted_cat)
        if formatted_cat2:
          catparam.append(formatted_cat2)
        catparam = lang + ",".join(catparam)
      elif portal:
        portalparam = lang + make_link(portal, link or portal)
      else:
        formatted_link = make_link(link, link_label, link_fragment)
        formatted_link2 = make_link(link2, link2_label)
        linkparam = [formatted_link]
        if formatted_link2:
          linkparam.append(formatted_link2)
        linkparam = lang + ",".join(linkparam)

      origt = str(t)
      must_continue = False
      for param in t.params:
        pn = pname(param)
        if pn not in ["1", "2", "cat", "category", "i", "lang", "mul", "mullabel", "mulcat", "mulcatlabel", "portal",
                      "sc", "section"]:
          pagemsg("WARNING: Unrecognized param %s=%s" % (pn, str(param.value)))
          must_continue = True
          break
      if must_continue:
        continue

      del t.params[:]
      if catparam is not None:
        t.add("cat", catparam or "+")
      elif portalparam is not None:
        t.add("portal", portalparam or "+")
      elif linkparam:
        t.add("1", linkparam)
      if sc:
        t.add("sc", sc)
      notes.append("convert {{%s}} to new syntax" % tn)

      if tn == "wikipedia":
        blib.set_template_name(t, "wp")
        notes.append("convert {{wikipedia}} to {{wp}}")
      elif tn == "slim-wikipedia":
        blib.set_template_name(t, "swp")
        notes.append("convert {{slim-wikipedia}} to {{swp}}")

  return str(parsed), notes

parser = blib.create_argparser("Convert Wikipedia templates to new syntax",
  include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
