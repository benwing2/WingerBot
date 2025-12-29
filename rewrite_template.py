#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, msg, site, tname, pname
from rename import rename_page

templates_to_rename = set()
templates_to_delete = set()
template_couldnt_be_renamed = set()
template_to_new_name_dict = {}
template_alias_to_canonical_for_rename = {}

def rename_template_and_subpage(index, old_name, new_name, pagemsg, errandpagemsg):
  template_page = pywikibot.Page(site, "Template:%s" % old_name)
  rename_comment = args.comment
  if not rename_comment:
    rename_comment = "rename template preparatory to renaming all uses"
  rename_comment = blib.changelog_to_string(rename_comment, args.comment_tag)
  templates_to_rename.remove(old_name)
  if not rename_page(args, index, template_page, "Template:%s" % new_name, rename_comment, None, None):
    ignore_error = False
    if ignore_rename_errors is True:
      ignore_error = True # ignore all rename errors
    elif ignore_rename_errors and old_name in ignore_rename_errors:
      ignore_error = True # ignore rename error for this template
    else:
      template_couldnt_be_renamed.add(old_name)
    if ignore_error:
      pagemsg("WARNING: Ignoring rename error for Template:%s -> Template:%s" % (old_name, new_name))
  else:
    # Attempt to rename documentation and talk pages, if they exist; but don't abort if they can't be renamed,
    # as long as the template itself can be renamed.
    docpagename = "Template:%s/documentation" % old_name
    docpage = pywikibot.Page(site, docpagename)
    new_docpagename = "Template:%s/documentation" % new_name
    if blib.safe_page_exists(docpage, errandpagemsg):
      if not rename_page(args, index, docpage, new_docpagename, "%s (rename doc page)" % rename_comment, None,
                         None):
        pagemsg("WARNING: Ignoring rename error for doc page %s -> %s" % (old_name, docpagename, new_docpagename))
    talkpagename = "Template talk:%s" % old_name
    talkpage = pywikibot.Page(site, talkpagename)
    new_talkpagename = "Template talk:%s" % new_name
    if blib.safe_page_exists(talkpage, errandpagemsg):
      if not rename_page(args, index, talkpage, new_talkpagename, "%s (rename talk page)" % rename_comment, None,
                         None):
        pagemsg("WARNING: Ignoring rename error for talk page %s -> %s" % (old_name, talkpagename, new_talkpagename))

def process_text_on_page(
    index, pagetitle, text, templates, new_names, params_to_add, params_to_prepend, params_to_insert, params_to_remove,
    params_to_rename, from_to_regex, filters, recognized_params
):
  if not any(template in text for template in templates):
    return
  if not re.search(r"\{\{\s*(%s)" % "|".join(re.escape(t) for t in templates), text):
    return

  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  pagemsg("Processing")
  notes = []

  def append_note(note):
    notes.append(note)

  parsed = blib.parse_text(text)

  def substitute_in_value(value, is_regex=False):
    repl_pagetitle = pagetitle
    if is_regex:
      repl_pagetitle = re.escape(repl_pagetitle)
    value = value.replace("{{PAGENAME}}", repl_pagetitle)
    return value

  for t in parsed.filter_templates():
    origt = str(t)
    tn = tname(t)
    def getp(param):
      return getparam(t, param).strip()
    if tn in templates:
      must_continue = False
      for filt in filters:
        def filter_matches(paramspec, fn, negate_messages=False):
          filt_for_message = filt
          if negate_messages:
            filt_for_message = re.sub("^!", "", filt_for_message)
          matches = False
          if paramspec[0] == "~": # regex spec for param
            paramspec = paramspec[1:]
            for param in t.params:
              pn = pname(param)
              pv = str(param.value).strip()
              if re.search("^" + paramspec + "$", pn):
                if fn(pv):
                  if negate_messages:
                    pagemsg("Skipping because param %s=%s matches filter %s: %s" % (pn, pv, filt_for_message, origt))
                  elif args.verbose:
                    pagemsg("Param %s=%s matches filter %s: %s" % (pn, pv, filt_for_message, origt))
                  return True
          else:
            pn = paramspec
            pv = getp(pn)
            if fn(pv):
              if negate_messages:
                pagemsg("Skipping because param %s=%s matches filter %s: %s" % (pn, pv, filt_for_message, origt))
              elif args.verbose:
                pagemsg("Param %s=%s matches filter %s: %s" % (pn, pv, filt_for_message, origt))
              return True
          if negate_messages:
            if args.verbose:
              pagemsg("Processing because filter %s doesn't match: %s" % (filt_for_message, origt))
          else:
            pagemsg("Skipping because filter %s doesn't match: %s" % (filt_for_message, origt))
          return False

        m = re.search("^!(.+?)=(.*)$", filt)
        if m:
          if not filter_matches(m.group(1), lambda pv: pv == substitute_in_value(m.group(2)), negate_messages=True):
            continue
          must_continue = True
          break
        m = re.search("^!(.+?)~(.*)$", filt)
        if m:
          if not filter_matches(m.group(1), lambda pv: re.search(substitute_in_value(m.group(2), is_regex=True), pv),
                                negate_messages=True):
            continue
          must_continue = True
          break
        m = re.search("^(.+?)!=(.*)$", filt)
        if m:
          if filter_matches(m.group(1), lambda pv: pv != substitute_in_value(m.group(2))):
            continue
          must_continue = True
          break
        m = re.search("^(.+?)=(.*)$", filt)
        if m:
          if filter_matches(m.group(1), lambda pv: pv == substitute_in_value(m.group(2))):
            continue
          must_continue = True
          break
        m = re.search("^(.+?)!~(.*)$", filt)
        if m:
          if filter_matches(m.group(1), lambda pv: not re.search(substitute_in_value(m.group(2), is_regex=True), pv)):
            continue
          must_continue = True
          break
        # This must precede the next one so that a filter of the form !~REGEX (with parameter regex) doesn't get
        # interpreted as having a parameter named `!`.
        m = re.search("^!(.+)$", filt)
        if m:
          if not filter_matches(m.group(1), lambda pv: pv, negate_messages=True):
            continue
          must_continue = True
          break
        m = re.search("^(.+)~(.*)$", filt)
        if m:
          if filter_matches(m.group(1), lambda pv: re.search(substitute_in_value(m.group(2), is_regex=True), pv)):
            continue
          must_continue = True
          break
        if filter_matches(filt, lambda pv: pv):
          continue
        must_continue = True
        break
      if must_continue:
        continue

      must_continue = False
      if recognized_params:
        for param in t.params:
          pn = pname(param)
          recognized = None
          for recognized_param in recognized_params:
            if recognized_param == "-":
              recognized = False
              break
            elif re.search("^" + recognized_param + "$", pn):
              recognized = True
              break
            # else try next recognized param
          else: # no break
            recognized = False
          if not recognized:
            pagemsg("Skipping %s because of unrecognized param %s=%s" % (origt, pn, str(param.value)))
            must_continue = True
            break
      if must_continue:
        continue

      old_name = template_alias_to_canonical_for_rename.get(tn, tn)
      if old_name in templates_to_rename:
        new_name = template_to_new_name_dict[old_name]
        rename_template_and_subpage(index, old_name, new_name, pagemsg, errandpagemsg)
      if old_name in template_couldnt_be_renamed:
        pagemsg("Skipping %s because template couldn't be renamed" % old_name)
        continue

      if from_to_regex:
        for param in t.params:
          pn = pname(param)
          for old_param, new_param in params_to_rename:
            newpn = re.sub("^" + old_param + "$", new_param, pn)
            if newpn != pn:
              param.name = newpn
              append_note("rename %s= to %s= in {{%s}}" % (pn, newpn, tn))
              break
      else:
        for old_param, new_param in params_to_rename:
          can_overwrite = False
          if new_param.startswith("!"):
            can_overwrite = True
            new_param = new_param[1:]
          if t.has(old_param):
            will_overwrite = True
            if t.has(new_param):
              if can_overwrite:
                pagemsg("When renaming %s=%s to %s=, already has %s=%s, overwriting" % (
                  old_param, getp(old_param), new_param, new_param, getp(new_param)))
              else:
                pagemsg("WARNING: When renaming %s=%s to %s=, already has %s=%s" % (
                  old_param, getp(old_param), new_param, new_param, getp(new_param)))
                will_overwrite = False
            if will_overwrite:
              t.add(new_param, getparam(t, old_param), before=old_param, preserve_spacing=False)
              rmparam(t, old_param)
              append_note("rename %s= to %s= in {{%s}}" % (old_param, new_param, tn))
      for param in params_to_remove:
        if t.has(param):
          rmparam(t, param)
          append_note("remove %s= from {{%s}}" % (param, tn))
      for param, value in params_to_add:
        value = substitute_in_value(value)
        if getparam(t, param) != value:
          t.add(param, value)
          append_note("add %s=%s to {{%s}}" % (param, value, tn))
      for param, value in reversed(params_to_prepend):
        value = substitute_in_value(value)
        if getparam(t, param) != value:
          if t.has(param):
            t.add(param, value)
            append_note("add %s=%s to {{%s}}" % (param, value, tn))
          else:
            first_pn = None
            for paramobj in t.params:
              first_pn = pname(paramobj)
              break
            t.add(param, value, before=first_pn)
            append_note("prepend %s=%s to {{%s}}" % (param, value, tn))
      if params_to_insert:
        new_params = []
        params_to_insert = sorted(params_to_insert, key=lambda x: x[0])
        last_param_inserted = 0
        param_offset = 0
        max_existing_numeric_param = 0
        for param in t.params:
          pn = pname(param)
          if re.search("^[0-9]+$", pn):
            pnint = int(pn)
            max_existing_numeric_param = max(max_existing_numeric_param, pnint)
        def insert_remaining_numeric_params():
          local_last_param_inserted = last_param_inserted
          local_param_offset = param_offset
          # insert any new numeric params greater than those inserted so far
          for param_to_insert, values_to_insert in params_to_insert:
            if param_to_insert > local_last_param_inserted:
              # add blank params to avoid leading a gap between last param so far and new params
              for i in range(max(max_existing_numeric_param, local_last_param_inserted) + 1, param_to_insert):
                new_params.append((str(i + local_param_offset), ""))
              values_to_insert = [substitute_in_value(v) for v in values_to_insert]
              for i, value_to_insert in enumerate(values_to_insert):
                new_params.append((str(param_to_insert + local_param_offset + i), value_to_insert))
              append_note("insert %s=%s into {{%s}}" % (param_to_insert, "|".join(values_to_insert), tn))
              local_last_param_inserted = param_to_insert
              # subtract one because we're not inserting a param after the numeric params just inserted
              local_param_offset += len(values_to_insert) - 1
        if max_existing_numeric_param == 0:
          insert_remaining_numeric_params()
        for param in t.params:
          pn = pname(param)
          pv = str(param.value)
          if re.search("^[0-9]+$", pn):
            pnint = int(pn)
            for param_to_insert, values_to_insert in params_to_insert:
              values_to_insert = [substitute_in_value(v) for v in values_to_insert]
              if param_to_insert > last_param_inserted and param_to_insert <= pnint:
                for i, value_to_insert in enumerate(values_to_insert):
                  new_params.append((str(param_to_insert + param_offset + i), value_to_insert))
                append_note("insert %s=%s into {{%s}}" % (param_to_insert, "|".join(values_to_insert), tn))
                last_param_inserted = param_to_insert
                param_offset += len(values_to_insert)
            new_params.append((str(pnint + param_offset), pv))
            if pnint == max_existing_numeric_param:
              insert_remaining_numeric_params()
          else:
            new_params.append((pn, pv))
        del t.params[:]
        for pn, pv in new_params:
          t.add(pn, pv, preserve_spacing=False)

      if new_names:
        new_name = template_to_new_name_dict[tn]
        blib.set_template_name(t, new_name)
        append_note("rename {{%s}} to {{%s}}" % (tn, new_name))

    if str(t) != origt:
      pagemsg("Replaced <%s> with <%s>" % (origt, str(t)))

  comment = args.comment
  if not comment:
    comment = notes
  comment = blib.changelog_to_string(comment, args.comment_tag)
  return str(parsed), comment

pa = blib.create_argparser(
"""Rewrite template references, possibly renaming params or the template itself, or adding or removing params.

`-t` specifies the template(s) to operate on; separate multiple templates with a comma (with no space following).
By default, the pages operated on are those with references to the specified template(s). You can give rename the
references using `-n`, append parameters using `--add`, prepend parameters using `--prepend, insert numbered parameters
using `--insert`, rename parameters using `--from` and `--to`, etc.

When renaming template references, if there are multiple templates in `-t`, there should either be the same number in
`-n` (causing the two lists to be paired up) or only one template in `-n` (in which case all references to templates in
`-t` will be given the same name, specified in `-n`).

Alternatively, use `--direcfile` to specify pairs of templates to operate on and their new names, separated by ' ||| '.

If you specify `--rename-templates`, templates whose references are given new names will themselves be renamed prior to
renaming their references (they are renamed first so that the template with the new name will already be in place when
the references are renamed and the page saved). If an error occurs during renaming the template itself, its references
will not be changed unless the template is among those given in `--ignore-rename-errors` (use the value 'all' to ignore
all rename errors).""",
  include_pagefile=True, include_stdin=True)
pa.add_argument("-t", "--template", help="Name of template; separate with a comma for multiple templates.")
pa.add_argument("-n", "--new-name", help="New name of template; separate with a comma for multiple templates.")
pa.add_argument("--direcfile", help="File containing pairs of templates to rename, separated by ' ||| '.")
pa.add_argument("--rename-templates", help="Rename the templates whose references are being changed.",
                action="store_true")
pa.add_argument("--with-redirect", action="store_true",
                help="If specified, redirects are created from the old page to the new page when renaming.")
pa.add_argument("--ignore-rename-errors", help="Comma-separated list of templates to ignore rename errors for, or 'all' for all templates.")
pa.add_argument("-r", "--remove", help="Param to remove, can be specified multiple times",
    action="append")
pa.add_argument("--from", help="Old name of param, can be specified multiple times",
    metavar="FROM", dest="from_", action="append")
pa.add_argument("--to", help="New name of param, can be specified multiple times; if param preceded by an !, can overwrite existing param",
    action="append")
pa.add_argument("--from-to-regex", help="Interpret values in --from and --to as regexes.", action="store_true")
pa.add_argument("--prepend", help="PARAM=VALUE to add at the beginning, can be specified multiple times; VALUE can have {{PAGENAME}} in it to substitute the page title",
    action="append")
pa.add_argument("--add", help="PARAM=VALUE to add at the end, can be specified multiple times; VALUE can have {{PAGENAME}} in it to substitute the page title",
    action="append")
pa.add_argument("--insert", help="Insert numeric PARAM=VALUE|VALUE|..., moving greater numeric params to the right; can be specified multiple times, works from right to left; VALUE can have {{PAGENAME}} in it to substitute the page title",
    action="append")
pa.add_argument("--filter", help="Only take action on templates matching the filter, which should be either PARAM meaning the parameter must exist and be non-empty; !PARAM meaning the parameter must not exist or must be empty; PARAM=VALUE meaning the parameter must have the given value; PARAM!=VALUE meaning the parameter must not have the given value; PARAM~REGEX meaning the parameter's value must match the given regular expression (unanchored); PARAM!~REGEX meaning the parameter's value must not match the given regular expression (unanchored). In addition, if !PARAM=VALUE is specified, we will not take action if the parameter has the given value, and if !PARAM~REGEX is specified, we will not take action if the parameter's value matches the given regular expression (unanchored). (PARAM!=VALUE and PARAM!~REGEX differ from !PARAM=VALUE and !PARAM~REGEX if PARAM is a regular expression; see below.) Note that all parameter values have whitespace stripped from both ends before comparison. If PARAM begins with a ~, it is interpreted as a regex, anchored on both sides (i.e. the regex applies to the parameter's name rather than its value). VALUE and REGEX can have {{PAGENAME}} in them to substitute the page title; when substituting into a regular expression, the page title is properly escaped. --filter can be specified multiple times; if so, all filters must match.",
    action="append")
pa.add_argument("--recognized-params", help="Comma-separated list of regexps matching recognized params. Use - to indicate no recognized params. If the template contains any unrecognized params, a warning will be displayed and no action taken. Regexps are auto-anchored on both ends.")
pa.add_argument("-c", "--comment", help="Comment to use in place of auto-generated ones.")
pa.add_argument("--comment-tag", help="Comment tag to use along with auto-generated ones.")
pa.add_argument("--output-pages-to-delete", help="Output file containing templates to delete.")
args = pa.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

def handle_single_param(paramname, process=None):
  argval = getattr(args, paramname)
  if argval:
    if process:
      return process(argval)
    else:
      return argval
  else:
    return None

def handle_list_param(paramname, split_on_comma=False):
  argval = getattr(args, paramname)
  rawvals = list(argval) if argval else []
  if split_on_comma:
    return [splitval for arg in rawvals for splitval in blib.split_arg(arg)]
  else:
    return rawvals

def handle_params_to_add(paramname, process_parts=None):
  argval = getattr(args, paramname)
  params_to_add = []
  addspecs = list(argval) if argval else []
  for spec in addspecs:
    specparts = spec.split("=")
    if len(specparts) != 2:
      raise ValueError("Value %s to --%s must have the form PARAM=VALUE" % (spec, paramname))
    if process_parts:
      parts_to_add = process_parts(*specparts)
    else:
      parts_to_add = specparts
    params_to_add.append(parts_to_add)
  return params_to_add

output_pages_to_delete = []

if args.direcfile:
  templates = []
  new_names = []
  for index, line in blib.iter_items_from_file(args.direcfile):
    if " ||| " not in line:
      msg("Line %s: WARNING: Saw bad line in --direcfile: %s" % (index, line))
      continue
    lineparts = line.split(" ||| ")
    if len(lineparts) == 3:
      frompages, topage, directive = lineparts
    else:
      frompages, topage = lineparts
      directive = "rename"
    frompages = re.sub("(^|,)Template:", r"\1", frompages)
    frompages = blib.split_arg(frompages)
    topage = re.sub("^Template:", "", topage)
    first_from = None
    for frompage in frompages:
      templates.append(frompage)
      new_names.append(topage)
      if directive == "delete-all":
        templates_to_delete.add(frompage)
        output_pages_to_delete.append("Template:%s" % frompage)
      elif directive == "delete-butfirst":
        if first_from is None:
          first_from = frompage
          templates_to_rename.add(frompage)
        else:
          templates_to_delete.add(frompage)
          output_pages_to_delete.append("Template:%s" % frompage)
          template_alias_to_canonical_for_rename[frompage] = first_from
      elif directive == "rename":
        templates_to_rename.add(frompage)
      else:
        msg("Line %s: WARNING: Unrecognized directive in --direcfile: %s" % (index, line))
        break
else:
  templates = handle_single_param("template", blib.split_arg)
  new_names = handle_single_param("new_name", blib.split_arg)
  if new_names and len(new_names) != len(templates):
    if len(new_names) == 1:
      new_names = new_names * len(templates)
    else:
      raise ValueError("Saw %s template(s) '%s' but %s new name(s) '%s'; both must agree in number or there must be only one new name" %
        (len(templates), ",".join(templates), len(new_names), ",".join(new_names)))
  if args.rename_templates:
    templates_to_rename = set(templates)

if not templates:
  raise ValueError("No templates specified to process")
if new_names:
  template_to_new_name_dict = dict(zip(templates, new_names))
recognized_params = handle_single_param("recognized_params", blib.split_arg)

ignore_rename_errors = handle_single_param("ignore_rename_errors", blib.split_arg)
if ignore_rename_errors == ["all"]:
  ignore_rename_errors = True

from_ = handle_list_param("from_", split_on_comma=True)
to = handle_list_param("to", split_on_comma=True)

params_to_add = handle_params_to_add("add")
params_to_prepend = handle_params_to_add("prepend")
def process_insert_parts(param, value):
  if not re.search("^[0-9]+$", param):
    raise ValueError("Parameter %s to --insert must be numeric" % param)
  return (int(param), value.split("|"))
params_to_insert = handle_params_to_add("insert", process_insert_parts)
params_to_remove = handle_list_param("remove", split_on_comma=True)
filters = handle_list_param("filter")

if len(from_) != len(to):
  raise ValueError("Same number of --from and --to arguments must be specified")

params_to_rename = list(zip(from_, to))

def do_process_text_on_page(index, pagetitle, text):
  return process_text_on_page(index, pagetitle, text, templates, new_names, params_to_add, params_to_prepend,
    params_to_insert, params_to_remove, params_to_rename, args.from_to_regex, filters, recognized_params)

# We want to do template references first in case we rename a template that is included in other templates. For example,
# if we rename {{alt-decl-noun}} to {{alt-ndecl-base}} followed by {{alt-noun-c}} to {{alt-ndecl-c}}, and
# {{alt-ndecl-c}} is defined using {{alt-decl-noun}}, we want to rename the reference to {{alt-decl-noun}} in
# {{alt-ndecl-c}} before processing any other references to {{alt-decl-noun}} (which will include all pages that
# transclude {{alt-ndecl-c}}).
blib.do_pagefile_cats_refs(args, start, end, do_process_text_on_page, edit=True, stdin=True,
  default_refs=["Template:%s" % template for template in templates], templates_first=True)

if templates_to_rename:
  msg("WARNING: The following templates were not renamed due to not having any uses; consider deleting them:")
  sorted_templates_to_rename = sorted(list(templates_to_rename))
  for tn in sorted_templates_to_rename:
    msg("Template:%s" % tn)
  msg("Renaming templates without any uses ...")
  for index, old_name in enumerate(sorted_templates_to_rename):
    def pagemsg(txt):
      msg("Page %s Template:%s: %s" % (index + 1, old_name, txt))
    def errandpagemsg(txt):
      errandmsg("Page %s Template:%s: %s" % (index + 1, old_name, txt))
    new_name = template_to_new_name_dict[old_name]
    rename_template_and_subpage(index + 1, old_name, new_name, pagemsg, errandpagemsg)
  msg("Renaming templates without any uses ... Done.")

if output_pages_to_delete:
  if templates_to_rename:
    msg("")
  msg("The following pages need to be deleted:")
  for page in output_pages_to_delete:
    msg(page)
  if args.output_pages_to_delete:
    with open(args.output_pages_to_delete, "w", encoding="utf-8") as fp:
      for page in output_pages_to_delete:
        print(page, file=fp)
