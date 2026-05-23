#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname

numeric_to_roman_form = {
  "1":"I", "2":"II", "3":"III", "4":"IV", "5":"V",
  "6":"VI", "7":"VII", "8":"VIII", "9":"IX", "10":"X",
  "11":"XI", "12":"XII", "13":"XIII", "14":"XIV", "15":"XV",
  "1q":"Iq", "2q":"IIq", "3q":"IIIq", "4q":"IVq"
}

# convert numeric form to roman-numeral form
def canonicalize_form(form):
  return numeric_to_roman_form.get(form, form)

# Clean the verb headword templates on a given page with the given text.
# Returns the changed text along with a changelog message.
def rewrite_one_page_verb_headword(index, page):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
  text = blib.safe_page_text(page, errandpagemsg)
  parsed = blib.parse_text(text)

  pagemsg("Processing")

  actions_taken = []

  for t in parsed.filter_templates():
    if tname(t) in ["ar-verb"]:
      origtemp = str(t)
      form = getparam(t, "form")
      if form:
        # In order to keep in the same order, just forcibly change the
        # param "names" (numbers)
        for pno in range(10, 0, -1):
          if t.has(str(pno)):
            t.get(str(pno)).name = str(pno + 1)
        # Make sure form= param is first ...
        t.remove("form")
        addparam(t, "form", canonicalize_form(form), before=t.params[0].name if len(t.params) > 0 else None)
        # ... then forcibly change its name to 1=
        t.get("form").name = "1"
        t.get("1").showkey = False
      newtemp = str(t)
      if origtemp != newtemp:
        msg("Replacing %s with %s" % (origtemp, newtemp))
      if re.match("^[1I](-|$)", form):
        actions_taken.append("form=%s (%s/%s)" % (form,
          getparam(t, "2"), getparam(t, "3")))
      else:
        actions_taken.append("form=%s" % form)
  changelog = "ar-verb: form= -> 1= and canonicalize to Roman numerals, move other params up: %s" % '; '.join(actions_taken)
  return str(parsed), changelog

def rewrite_verb_headword(save, start, end):
  for cat in ["Arabic verbs"]:
    for index, page in blib.cat_articles(cat, start, end):
      blib.do_edit(index, page, rewrite_one_page_verb_headword, save=save)

def canonicalize_verb_form(save, start, end, tempname, formarg):
  # Canonicalize the form in ar-conj.
  # Returns the changed text along with a changelog message.
  def canonicalize_one_page_verb_form(index, page):
    pagetitle = str(page.title())
    def pagemsg(txt):
      msg("Page %s %s: %s" % (index, pagetitle, txt))
    def errandpagemsg(txt):
      errandmsg("Page %s %s: %s" % (index, pagetitle, txt))
    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)

    pagemsg("Processing")
    actions_taken = []

    for t in parsed.filter_templates():
      if tname(t) == tempname:
        origtemp = str(t)
        form = getparam(t, formarg)
        if form:
          addparam(t, formarg, canonicalize_form(form))
        newtemp = str(t)
        if origtemp != newtemp:
          msg("Replacing %s with %s" % (origtemp, newtemp))
        if re.match("^[1I](-|$)", form):
          actions_taken.append("form=%s (%s/%s)" % (form,
            getparam(t, str(1+int(formarg))),
            getparam(t, str(2+int(formarg)))))
        else:
          actions_taken.append("form=%s" % form)
    changelog = "%s: canonicalize form (%s=) to Roman numerals: %s" % (
        tempname, formarg, '; '.join(actions_taken))
    return str(parsed), changelog

  for index, page in blib.references("Template:%s" % tempname, start, end):
    blib.do_edit(index, page, canonicalize_one_page_verb_form, save=save)

parser = blib.create_argparser("Rewrite form= to 1= in verb headword templates")
parser.add_argument("--headword", action='store_true',
    help="Rewrite form= to 1= in ar-verb and canonicalize")
parser.add_argument("--canonicalize", action='store_true',
    help="Canonicalize form in Arabic verb templates other than ar-verb")
params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)

if params.headword:
  rewrite_verb_headword(params.save, start, end)
if params.canonicalize:
  canonicalize_verb_form(params.save, start, end, "ar-conj", "1")
  canonicalize_verb_form(params.save, start, end, "ar-past3sm", "1")
  canonicalize_verb_form(params.save, start, end, "ar-verb-part", "2")
