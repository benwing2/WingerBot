#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

import blib, pywikibot
from blib import msg, getparam, addparam
from arabiclib import arabic_decl_templates

def rewrite_one_page_idafa(page, index, text):
  pagetitle = str(page.title())
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  num_new_style = 0
  num_modhead_changed = 0
  num_state_ind_to_ind_def = 0
  num_basestate_ind_def = 0
  idafa_added = []
  has_proper_noun = False
  for t in text.filter_templates():
    if t.name == "ar-proper noun":
      has_proper_noun = True
  for t in text.filter_templates():
    if t.name.startswith("ar-decl-"):
      changed = False

      # Change state=ind for proper noun to state=ind-def
      oldt = str(t)
      if getparam(t, "state") == "ind" and has_proper_noun:
        addparam(t, "state", "ind-def")
        pagemsg("Converting state=ind to state=ind-def for proper noun")
        pagemsg("Replacing %s with %s" % (oldt, str(t)))
        num_state_ind_to_ind_def += 1
      elif getparam(t, "state") == "def" and getparam(t, "basestate") == "ind":
        t.remove("basestate")
        addparam(t, "state", "ind-def")
        pagemsg("Converting state=def|basestate=ind to state=ind-def")
        pagemsg("Replacing %s with %s" % (oldt, str(t)))
        num_basestate_ind_def += 1

      # Change old-style ʾidāfa (state=con) to new-style (basestate=con)
      #oldt = str(t)
      #if (getparam(t, "state") == "con" and getparam(t, "modcase") and
      #    not getparam(t, "basestate")):
      #  modstate = getparam(t, "modstate")
      #  addparam(t, "basestate", "con")
      #  addparam(t, "modidafa", "yes")
      #  if not modstate:
      #    t.remove("state")
      #  else:
      #    addparam(t, "state", modstate)
      #  pagemsg("Replacing %s with %s" % (oldt, str(t)))
      #  changed = True

      # Remove manual ʾidāfa params when possible and substitute idafa=
      #oldt = str(t)
      #if getparam(t, "basestate") == "con" and getparam(t, "modcase") == "gen":
      #  idafa = ""
      #  modnumber = getparam(t, "modnumber")
      #  if not modnumber:
      #    pagemsg("WARNING: Missing modnumber= in idafa template, substituting sg: %s" %
      #        str(t))
      #    modnumber = "sg"
      #    addparam(t, "modnumber", "sg")
      #  modstate = getparam(t, "modstate")
      #  state = getparam(t, "state")
      #  if not modstate:
      #    if state:
      #      pagemsg("WARNING: Extraneous state= in idafa template: %s" %
      #          str(t))
      #    idafa = modnumber
      #  elif state != modstate:
      #    pagemsg("WARNING: modstate= in idafa template but state= doesn't match: %s"
      #        % str(t))
      #  else:
      #    idafa = "%s-%s" % (modstate, modnumber)
      #    t.remove("state")
      #    t.remove("modstate")
      #  if idafa:
      #    t.remove("basestate")
      #    t.remove("modcase")
      #    t.remove("modnumber")
      #    t.remove("modidafa")
      #    m = re.match("^ind-(.*)$", idafa)
      #    if m:
      #      if has_proper_noun:
      #        pagemsg("Not replacing idafa state 'ind' because proper noun: %s"
      #            % str(t))
      #      elif pagetitle in ["أقدم مهنة", "غير طبيعي"]:
      #        pagemsg("Not replacing idafa state 'ind' because it's special-cased: %s" % str(t))
      #      else:
      #        pagemsg("NOTE: Replacing idafa state 'ind' with no state restriction: %s"
      #            % str(t))
      #        idafa = m.group(1)
      #    m = re.match("^(.*?)-sg$", idafa)
      #    if m:
      #      idafa = m.group(1)
      #    if idafa == "sg":
      #      idafa = "yes"
      #    addparam(t, "idafa", idafa)
      #    pagemsg("Replacing %s with %s" % (oldt, str(t)))
      #    idafa_added.append(idafa)
      #  elif changed:
      #    num_new_style += 1

      if (getparam(t, "basestate") or getparam(t, "modcase") or
          getparam(t, "modstate") or getparam(t, "modnumber") or
          getparam(t, "modidafa")):
        pagemsg("WARNING: idafa params remain after processing: %s" %
            str(t))

      ## Change modN into modheadN
      #oldt = str(t)
      #changed = False
      #for i in range(2, 20):
      #  modn = getparam(t, "mod" + str(i))
      #  if modn:
      #    t.remove("mod" + str(i))
      #    addparam(t, "modhead" + str(i), modn)
      #    changed = True
      #if changed:
      #  pagemsg("Replacing %s with %s" % (oldt, str(t)))
      #  num_modhead_changed += 1

      if getparam(t, "omitarticle"):
        pagemsg("WARNING: omitarticle present: %s" % str(t))
      if getparam(t, "state") == "ind":
        pagemsg("WARNING: state=ind still present: %s" % str(t))

  actions = []
  if idafa_added:
    actions.append("Replaced ʾidāfa params with idafa= param: %s" % (
        ", ".join(idafa_added)))
  if num_new_style:
    actions.append("Corrected %s old-style ʾidāfa param(s) to new-style"
        % num_new_style)
  if num_modhead_changed:
    actions.append("Changed modN to modheadN")
  if num_state_ind_to_ind_def:
    actions.append("Converted state=ind to state=ind-def for proper noun")
  if num_basestate_ind_def:
    actions.append("Converted state=def|basestate=ind to state=ind-def")
  if actions:
    changelog = "; ".join(actions)
    pagemsg("Changelog = %s" % changelog)
    return text, changelog
  return text, ""

parser = blib.create_argparser("Rewrite ʾidāfa params with idafa= param, and related changes",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:%s" % template for template in arabic_decl_templates])
