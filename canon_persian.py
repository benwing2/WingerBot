#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, addparam, tname, pname, msg, site
import fa_translit
from canon_foreign import canon_one_page_links, show_failure

parser = blib.create_argparser("Clean up Persian transliterations", include_pagefile=True, include_stdin=True)
parser.add_argument("--direcfile", help="File containing output from find_regex.py, to process")
parser.add_argument("--test", help="Test fa_translit.py", action="store_true")
parser.add_argument("--convert-g-breve", help="Convert ğ and ǧ to ġ", action="store_true")
parser.add_argument("--overall-comment", help="Overall comment to add to final changelog msg")
parser.add_argument("--no-vocalize", help="Disable vocalization of Persian script", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

templates_seen = {}
templates_changed = {}
printed_succeeded_failed = False

def process_text_on_page(index, pagetitle, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  if args.convert_g_breve:
    def do_convert_g_breve(latin):
      latin = latin.replace("ğ", "ġ").replace("ǧ", "ġ")
      latin = latin.replace("Ğ", "Ġ").replace("Ǧ", "Ġ")
      return latin
    def process_param(obj):
      notes = []
      def getp(param):
        return getparam(obj.t, param)
      foreign = None
      latin = None
      if obj.param[0] == "separate":
        _, foreign, latin = obj.param
        foreign = getp(foreign)
        latin = getp(latin)
      elif obj.param[0] == "separate-pagetitle":
        _, foreign_dest, latin = obj.param
        foreign = pagetitle
        latin = getp(latin)
      elif obj.param[0] == "inline":
        _, foreign_param, foreign_mod, latin_mod, inline_mod = obj.param
        foreign = inline_mod.mainval if foreign_mod is None else inline_mod.get_modifier(foreign_mod)
        latin = inline_mod.get_modifier(latin_mod)
      else:
        assert False, "Unrecognized value for obj.param[0]=%s" % obj.param[0]
      if not foreign or not latin or latin in ["-", "?"]:
        pagemsg("Skipped: foreign=%s, latin=%s in %s" % (foreign, latin, str(obj.t)))
      else:
        newlatin = do_convert_g_breve(latin)
        if latin == newlatin:
          pagemsg("Skipped: foreign=%s, latin=%s in %s" % (foreign, latin, str(obj.t)))
        else:
          def make_orig_template(foreignparam, foreign):
            if obj.langparam == "1":
              return "{{%s|%s|...|%s=%s}}" % (tname(obj.t), obj.tlang, foreignparam, foreign)
            else:
              return "{{%s|...|%s|...|%s=%s}}" % (tname(obj.t), obj.tlang, foreignparam, foreign)
          if obj.param[0] in ["separate", "separate-pagetitle"]:
            _, foreignparam, latinparam = obj.param
            origtemp = make_orig_template(foreignparam, foreign)
            pagemsg("In %s, replacing %s=%s with %s" % (origtemp, latinparam, latin, newlatin))
            notes.append("replace %s=%s with %s in %s" % (latinparam, latin, newlatin, origtemp))
            addparam(obj.t, latinparam, newlatin)
          elif obj.param[0] == "inline":
            _, foreign_param, foreign_mod, latin_mod, inline_mod = obj.param
            origtemp = make_orig_template(foreign_param, getp(foreign_param))
            pagemsg("In %s, replacing <%s:%s> with %s" % (origtemp, latin_mod, latin, newlatin))
            notes.append("replace <%s:%s> with %s in %s" % (latin_mod, latin, newlatin, origtemp))
            inline_mod.set_modifier(latin_mod, newlatin)
            addparam(obj.t, foreign_param, inline_mod.reconstruct_param())
          return notes
      return False

    newtext, actions = blib.process_one_page_links(
      index, pagetitle, text, ["fa", "fa-cls", "fa-ira", "prs"], process_param, templates_seen, templates_changed
    )
    if args.overall_comment:
      overall_comment = "%s: %s" % (args.overall_comment, "; ".join(blib.group_notes(actions)))
      return newtext, overall_comment
    else:
      return newtext, actions
  elif args.test:
    def process_param(obj):
      def getp(param):
        return getparam(obj.t, param)
      def test(obj, foreign, latin):
        global printed_succeeded_failed
        if int(index) % 100 == 0:
          if not printed_succeeded_failed:
            printed_succeeded_failed = True
            show_failure(pagemsg, fa_translit.num_succeeded, fa_translit.num_failed)
        else:
          printed_succeeded_failed = False
        pagemsg("Processing %s" % str(obj.t))
        return fa_translit.test_with_obj(obj, latin, foreign, "matched")
      foreign = None
      latin = None
      if obj.param[0] == "separate":
        _, foreign, latin = obj.param
        foreign = getp(foreign)
        latin = getp(latin)
      elif obj.param[0] == "separate-pagetitle":
        _, foreign_dest, latin = obj.param
        foreign = pagetitle
        latin = getp(latin)
      elif obj.param[0] == "inline":
        _, foreign_param, foreign_mod, latin_mod, inline_mod = obj.param
        foreign = inline_mod.mainval if foreign_mod is None else inline_mod.get_modifier(foreign_mod)
        latin = inline_mod.get_modifier(latin_mod)
      obj.addl_params["no_vocalize"] = args.no_vocalize
      if not foreign or not latin or latin in ["-", "?"]:
        pagemsg("Skipped: foreign=%s, latin=%s" % (foreign, latin))
      else:
        latins = fa_translit.split_multiple_translits(latin, foreign)
        if latins is not None:
          # Since there are different vocalizations associated with different translits.
          obj.addl_params["no_vocalize"] = True
          for this_latin in latins:
            test(obj, foreign, this_latin)
        else:
          test(obj, foreign, latin)
    return blib.process_one_page_links(index, pagetitle, text, ["fa"], process_param,
        templates_seen, templates_changed)
  else:
    return canon_one_page_links(pagetitle, index, text, "fa", "Persian", "fa-Arab", fa_translit,
        templates_seen, templates_changed, {"no_vocalize": args.no_vocalize})

if args.direcfile:
  for lineindex, line in blib.iter_items_from_file(args.direcfile, start, end):
    lineno = lineindex + 1
    def linemsg(text):
      msg("Line %s: %s" % (lineno, text))
    m = re.search("^Page ([0-9]+) (.*?): (.*)$", line)
    if not m:
      linemsg("WARNING: Unrecognized line: %s" % line)
    else:
      index, pagetitle, text = m.groups()
      process_text_on_page(index, pagetitle, text)
else:
  blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
      skip_ignorable_pages=True)
# If in --test mode, we need to use the num_succeeded/num_failed from fa_translit as the ones in canon_foreign aren't
# set.
if args.test:
  show_failure(msg, fa_translit.num_succeeded, fa_translit.num_failed)
else:
  show_failure(msg)
blib.output_process_links_template_counts(templates_seen, templates_changed)
