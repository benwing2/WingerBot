#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse, json
from collections import defaultdict

import blib
from blib import getparam, rmparam, msg, site, tname, pname
from remove_redundant_sc import check_script_agrees

#blib.init_fake_langdata()
#blib.getData()
blib.loadData("langdata.json")

seen_quals = defaultdict(int)

char_to_escape_seq = {
  "%": "%25",
  "|": "%7C",
  "{": "%7B",
  "}": "%7D",
  "=": "%3D",
  "&": "%26",
}

def bot_url_encode(val):
  return re.sub("[%|{}=&]", lambda m: char_to_escape_seq[m.group(0)], val)

def escape_inline_val(val):
  # If < or > in the value, check if they are balanced. If not, escape them all (safest thing to do).
  if "<" in val or ">" in val:
    try:
      segments = blib.parse_balanced_segment_run(val, "<", ">")
    except blib.ParseException:
      return val.replace("<", "&lt;").replace(">", "&gt;")
  return val

def escape_template_delimiters(val, pagemsg):
  # Escape = and | occurring in raw text that will become a template parameter. This should exclude:
  # (1) Raw links, where [[foo=bar|baz=bat]] in a param doesn't cause issues.
  # (2) Template calls, where {{foo=bar|baz=bat}} in a param doesn't cause issues.
  # (3) <ref>...</ref>, where = and | occurring either in parameters inside the tags or in the text between the tags
  #     doesn't cause issues.
  # (4) <ref .../>, where = and | occurring inside the tag doesn't cause issues.
  # Note that = and | inside of other HTML tags such as <span> *does* cause issues; e.g.
  # {{col|de|<span class="foo">bar</span>}} causes an error as '<span class' tries to get interpreted as a parameter
  # name. This is a bit strange because {{col|de|{{l|de|bar}}}} doesn't cause problems even though {{l|de|bar}}
  # generates HTML of the form '<span class="Latn" lang="de">[[:bar#German|bar]]</span>'.
  try:
    run = blib.parse_multi_delimiter_balanced_segment_run(val, [(r"\[\[", r"\]\]"), (r"\{\{", r"\}\}"), ("(?:<ref>|<ref [^<>]*[^/]>)", "</ref>"), ("<ref ", "/>")])
  except blib.ParseException:
    # FIXME: Do something better in this case. Ideally we should make parse_multi_delimiter_balanced_segment_run()
    # have an `ignore_mismatch` flag.
    if "=" in val or "|" in val:
      pagemsg("WARNING: Mismatched delimiters and found = or | in raw line to be templated, may lead to error: %s" %
              val)
    return val
  for j, segment in enumerate(run):
    if j % 2 == 0:
      run[j] = segment.replace("=", "{{=}}").replace("|", "{{!}}")
  return "".join(run)

def make_inline_modifier(key, val, pagemsg):
  return "<%s:%s>" % (key, escape_inline_val(escape_template_delimiters(val, pagemsg)))

def lookup_langname(langname, prefer="lang"):
  if langname.endswith(" script"):
    langname = re.sub(" script$", "", langname)
    if langname in blib.scripts_byCanonicalName:
      return blib.scripts_byCanonicalName[langname]["code"], "script"
    return None, None
  if prefer == "script" and langname in blib.scripts_byCanonicalName:
    return blib.scripts_byCanonicalName[langname]["code"], "script"
  if prefer == "family" and langname in blib.families_byCanonicalName:
    return blib.families_byCanonicalName[langname]["code"], "family"
  if langname in blib.languages_byCanonicalName:
    return blib.languages_byCanonicalName[langname]["code"], "lang"
  elif langname in blib.etym_languages_byCanonicalName:
    return blib.etym_languages_byCanonicalName[langname]["code"], "etymlang"
  elif langname in blib.families_byCanonicalName:
    return blib.families_byCanonicalName[langname]["code"], "family"
  elif langname in blib.scripts_byCanonicalName:
    return blib.scripts_byCanonicalName[langname]["code"], "script"
  else:
    return None, None

# Convert a line/row from {{col*}} or from in between {{col-top}}/{{col-bottom}} etc. `line_non_templated` is True if
# the row came from between {{col-top}}/{{col-bottom}}, False if it came from an argument to {{col*}}. Return two
# values, a list of the links and any notes to add to the changelog message. If an error occurred during parsing, the
# first value is a string to display in place of a list. If the line doesn't begin with a raw or templated link, None
# is returned in place of the elements, indicating that the row should be left as-is.
#
# `langcode` is the langcode of the outer template being processed (e.g. {{col*}}), or the langcode of the section we're
# in, and `langname` is the corresponding language name. `pagemsg` is a function of one argument to display a warning or
# other message.
def convert_one_line(init_star, langname, rest, pagemsg, expand_text):
  def make_inline_mod(key, val):
    return make_inline_modifier(key, val, pagemsg)
  this_notes = []
  line = init_star + langname + rest
  if rest == ":":
    rest = ""
  else:
    rest = rest[1:].strip()
  if rest:
    langname_code, langname_type = lookup_langname(langname, prefer="script" if init_star.startswith("*:") else "lang")
    if not langname_code:
      pagemsg("WARNING: Unrecognized langname %s: %s" % (langname, line))
    try:
      segments = blib.parse_multi_delimiter_balanced_segment_run(rest, [(r"\(''", r"''\)"), (r"\{\{", r"\}\}"), ("(?:<ref>|<ref [^<>]*[^/]>)", "</ref>"), ("<ref ", "/>")])
    except blib.ParseException:
      # FIXME: Do something better in this case. Ideally we should make parse_multi_delimiter_balanced_segment_run()
      # have an `ignore_mismatch` flag.
      return line
    alternating_runs = blib.split_alternating_runs(segments, r"(\s*[,;/]\s*)")
    line_langcode = None
    line_langcode_suffix = ""
    line_tempname = "t-new"
    entries = []
    for i in range(0, len(alternating_runs), 2):
      left_qualifiers = []
      right_qualifiers = []
      left_labels = []
      right_labels = []
      entry_references = []
      entry = None
      entry_parts = []
      alternating_run = alternating_runs[i]
      seen_translation = False
      for j, segment in enumerate(alternating_run):
        if j % 2 == 0:
          if segment.strip():
            pagemsg("WARNING: Saw raw text '%s' between translations at position i=%s, j=%s, not sure how to handle: %s"
                    % (segment, i, j, line))
            return line
        elif re.search(r"^\(", segment):
          pagemsg("Converting raw parenthesized expression %s at position i=%s, j=%s into qualifier: %s" % (
            segment, i, j, line))
          segment = segment[1:-1]
          if segment.startswith("''") and segment.endswith("''"):
            segment = segment[2:-2]
          if seen_translation:
            right_qualifiers.append(segment)
          else:
            left_qualifiers.append(segment)
        elif re.search("^<ref", segment):
          pagemsg("WARNING: Reference, can't handle yet: %s" % segment)
          # FIXME
        elif re.search(r"\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.qualifier_templates), segment):
          qt = list(blib.parse_text(segment).filter_templates())[0]
          quals = blib.fetch_param_chain(qt, "1")
          if seen_translation:
            right_qualifiers.extend(quals)
          else:
            left_qualifiers.extend(quals)
        elif re.search(r"\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.translation_templates), segment):
          if seen_translation:
            pagemsg("WARNING: Saw two translation templates not delimiter-separated, not sure how to handle: %s" %
                    line)
            return line
          seen_translation = True
          tt = list(blib.parse_text(segment).filter_templates())[0]
          tn = tname(tt)
          def getp(param):
            return getparam(tt, param)
          langcode = getp("1")
          if line_langcode and line_langcode != langcode:
            pagemsg("WARNING: Saw two different langcodes %s and %s in translation line: %s" % (
              line_langcode, langcode, line))
            return line
          if not line_langcode:
            line_langcode = langcode
            if langcode in blib.languages_byCode:
              should_langname = blib.languages_byCode[langcode]["canonicalName"]
              is_ety = False
            elif langcode in blib.etym_languages_byCode:
              should_langname = blib.etym_languages_byCode[langcode]["canonicalName"]
              is_ety = True
            else:
              pagemsg("WARNING: Unrecognized language code %s: %s" % (langcode, line))
              return line
            if should_langname != langname:
              if langname_type == "script":
                val_to_check = getp("alt") or getp("2")
                if not val_to_check:
                  pagemsg("WARNING: Saw script code %s in place of language for lang code %s and no value in translation template to check script of: %s" % (
                    langname_code, langcode, line))
                  return line
                agrees = check_script_agrees(val_to_check, langcode, langname_code, pagemsg, expand_text, line,
                                             "converting explcit langname to :sc")
                if agrees:
                  line_langcode_suffix = ":sc"
                else:
                  return line
              elif langname_type:
                pagemsg("WARNING: Mismatch between language code %s (language name %s) and explicit language name %s (%s code %s): %s" % (
                  langcode, should_langname, langname, langname_type, langname_code, line))
                return line
              else:
                line_langcode_suffix = "/" + langname
          entry = "?" if tn == "t-needed" else getp("2")
          genders = blib.fetch_param_chain(tt, "3")
          entry_parts = []
          if tn in ["t+", "tt+", "t+check", "tt+check"]:
            entry += "<+>"
          if tn in ["t-check", "t+check", "tt-check", "tt+check"]:
            entry += "<check>"
          if tn.startswith("tt"):
            line_tempname = "tt-new"
          if genders:
            entry_parts.append(("g", ",".join(genders)))
          for param in ["alt", "id", "sc", "tr", "ts", "lit"]:
            val = getp(param)
            if val:
              entry_parts.append((param, val))
          val = getp("l")
          if val:
            left_labels.append(val)
          val = getp("ll")
          if val:
            right_labels.append(val)
          val = getp("q")
          if val:
            left_qualifiers.append(val)
          val = getp("qq")
          if val:
            right_qualifiers.append(val)
          val = getp("ref")
          if val:
            entry_references.append(val)
        else:
          pagemsg("WARNING: Unrecognized template, can't handle yet: %s" % segment)
          return line
      if not seen_translation:
        pagemsg("WARNING: Didn't see translation template between delimiters: %s" % line)
        return line
      if left_labels:
        entry_parts.append(("l", ",".join(left_labels)))
      if right_labels:
        entry_parts.append(("ll", ",".join(right_labels)))
      if left_qualifiers:
        entry_parts.append(("q", ", ".join(left_qualifiers)))
      if right_qualifiers:
        entry_parts.append(("qq", ", ".join(right_qualifiers)))
      if entry_references:
        entry_parts.append(("ref", " !!! ".join(right_qualifiers)))
      entry += "".join("<%s:%s>" % (mod, escape_inline_val(val)) for mod, val in entry_parts)
      entries.append(entry)
    rest = "{{%s|%s%s|%s}}" % (line_tempname, line_langcode, line_langcode_suffix, "|".join(entries))
    return "%s%s" % (init_star, rest)
  else:
    if langname in blib.languages_byCanonicalName:
      langcode = blib.languages_byCanonicalName[langname]["code"]
    elif langname in blib.etym_languages_byCanonicalName:
      langcode = blib.etym_languages_byCanonicalName[langname]["code"]
    elif langname in blib.families_byCanonicalName:
      langcode = blib.families_byCanonicalName[langname]["code"]
    else:
      pagemsg("WARNING: Unrecognized language name %s: %s" % (langname, line))
      return line
    rest = "{{t-new|%s|-}}" % langcode
    return "%s%s" % (init_star, rest)

#    this_qual = ["".join(x) for x in alternating_runs]
#  if re.search(r"^%s|\[\[" % match_link_template_re, line):
#    template_or_raw_link_split_re = (
#      r"""(%s(?:[^{}]|\{\{[^{}]*\}\})*\}\}|\[\[[^\[\]]+\]\])""" % match_link_template_re
#    )
#    line_parts = re.split(template_or_raw_link_split_re, line)
#    for i in range(0, len(line_parts), 2):
#      # The delimiter must either be a comma, slash or the word "or", or an empty string at the beginning or end of
#      # the line; otherwise, don't do any conversion.
#      if not (re.search(r"^\s*([,/]|or)\s*$", line_parts[i]) or (i == 0 or i == len(line_parts) - 1) and
#              not line_parts[i].strip()):
#        return "Unrecognized separator <%s> in line" % line_parts[i], []
#    else: # no break
#      els = []
#      has_pos = False
#      for i in range(1, len(line_parts), 2):
#        if line_parts[i].startswith("[["):
#          els.append(simplify_link(line_non_templated, line_parts[i], None, None, langcode, langname, pagemsg,
#                                   expand_text))
#          continue
#        linkt = list(blib.parse_text(line_parts[i]).filter_templates())[0]
#        def getp(param):
#          return getparam(linkt, param).strip()
#        parts = []
#        def app(val):
#          parts.append(val)
#        link_langcode = getp("1")
#        link = getp("2")
#        display = getp("3")
#        alt = getp("alt")
#        if display and alt:
#          pagemsg("WARNING: Found both 3=%s and alt=%s; this should be triggering a Lua error: %s" % (
#            display, alt, str(linkt)))
#        alt = alt or display
#        link = simplify_link(False, link, alt, link_langcode, langcode, langname, pagemsg, expand_text)
#        app(link)
#        def append_if(param):
#          val = getp(param)
#          if val:
#            if param == "tr" and val == "-" and link_langcode == "el":
#              this_notes.append("remove tr=- from Modern Greek link")
#            else:
#              app(make_inline_mod(param, val))
#        append_if("tr")
#        append_if("ts")
#        gloss = getp("t") or getp("gloss") or getp("4")
#        if gloss:
#          app(make_inline_mod("t", gloss))
#        append_if("sc")
#        append_if("pos")
#        append_if("lit")
#        append_if("id")
#        genders = blib.fetch_param_chain(linkt, "g")
#        if genders:
#          app(make_inline_mod("g", ",".join(genders)))
#        els.append("".join(parts))
#      return els, this_notes
#  else:
#    return None, []

def process_text_on_page(index, pagename, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagename, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagename, txt))
  def expand_text(tempcall):
    return blib.expand_text(tempcall, pagename, pagemsg, args.verbose)

  notes = []

  origtext = text
  new_lines = []
  lines = text.split("\n")
  in_translation_section = False
  langgroup_header = None
  langgroup_header_lineind = None
  translation_lines = None

  for lineind, line in enumerate(lines):
    origline = line
    if re.search(r"^\{\{(trans-top|checktrans-top|trans-top-see|trans-top-also)[|}]", line):
      if in_translation_section:
        pagemsg("WARNING: Nested translation sections, skipping page, nested opening line follows: %s" % line)
        return
      in_translation_section = True
      new_lines.append(line)
    elif re.search(r"^\}* *\{\{trans-bottom", line): # allow for multitrans closing braces before {{trans-bottom}}
      if not in_translation_section:
        pagemsg("WARNING: Found {{trans-bottom}} not in a translation section")
      in_translation_section = False
      new_lines.append(line)
    elif in_translation_section:
      m = re.search(r"^(\* *:* *)([^:]+)(:.*)$", line)
      if m:
        init_star, langname, rest = m.groups()
        newline = convert_one_line(init_star, langname, rest, pagemsg, expand_text)
        if newline != line:
          notes.append("convert translation line to {{t-new}}")
          line = newline
      new_lines.append(line)
    else:
      new_lines.append(line)

  if in_translation_section:
    pagemsg("WARNING: Page ended in a translation section, something wrong, skipping")
    return

  return "\n".join(new_lines), notes

#def process_text_on_page(index, pagetitle, text):
#  def pagemsg(txt):
#    msg("Page %s %s: %s" % (index, pagetitle, txt))
#  def expand_text(tempcall):
#    return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)
#  def make_inline_mod(key, val):
#    return make_inline_modifier(key, val, pagemsg)
#
#  def extract_left_and_right_qualifiers_and_genders(line):
#    left_qual = []
#    right_qual = []
#    right_gloss = []
#    exterior_genders = []
#    line_comment = ""
#
#    m = re.search("^(.*)(<!--.*?-->)$", line)
#    if m:
#      line, line_comment = m.groups()
#      line = line.strip()
#    def extract_left_or_right_qualifier_or_gender(line, on_left=True):
#      this_qual = None
#      this_gender = None
#      this_gloss = None
#      # check for left qualifiers specified using a qualifier template
#      if on_left:
#        left_re = ""
#        right_re = " *(.*?)"
#      else:
#        left_re = "(.*?) *"
#        right_re = ""
#      m = None
#      if not m and not on_left:
#        m = re.search(r"^%s\{\{(?:g|g2)\|([^{}=]*)\}\}%s$" % (left_re, right_re), line)
#        if m:
#          line, this_gender = m.groups()
#          this_gender = this_gender.replace("|", ",")
#      if not m and not on_left:
#        m = re.search(r"^%s\{\{(?:gloss|gl)\|([^{}=]*)\}\}%s$" % (left_re, right_re), line)
#        if m:
#          line, this_gloss = m.groups()
#          this_gloss = this_gloss.replace("|", "; ")
#      if not m:
#        m = re.search(r"^%s\{\{(?:qualifier|qual|q|qf|i)\|([^{}=]*)\}\}%s$" % (left_re, right_re), line)
#        if m:
#          this_qual, line = m.groups()
#      if not m:
#        # check for qualifier-like ''(...)''
#        m = re.search(r"^%s''\(([^'{}]*)\)''%s$" % (left_re, right_re), line)
#        if m:
#          this_qual, line = m.groups()
#      if not m:
#        # check for qualifier-like (''...'')
#        m = re.search(r"^%s\(''([^'{}]*)''\)%s$" % (left_re, right_re), line)
#        if m:
#          this_qual, line = m.groups()
#      if not m:
#        # check for somewhat qualifier-like ''...''
#        m = re.search(r"^%s''([^'{}]*)''%s$" % (left_re, right_re), line)
#        if m:
#          this_qual, line = m.groups()
#      if not m and not on_left:
#        # check for parenthesized parts of speech on the right
#        m = re.search(r"^%s\((noun|verb|adjective|adverb)\)%s$" % (left_re, right_re), line)
#        if m:
#          this_qual, line = m.groups()
#      if this_qual is not None and not on_left:
#        this_qual, line = line, this_qual
#      if this_qual is not None:
#        # Split on comma+space and on | (separate params), but not | or comma+space inside of links.
#        # Don't split if the qualifier text begins "literally".
#        if re.search("^'*literally", this_qual):
#          this_qual = [this_qual]
#        else:
#          segments = blib.parse_balanced_segment_run(this_qual, "[", "]")
#          alternating_runs = blib.split_alternating_runs(segments, "(?:\||,\s+)")
#          this_qual = ["".join(x) for x in alternating_runs]
#      return this_qual, this_gender, this_gloss, line
#
#    while True:
#      this_left_quals, this_left_gender, this_left_gloss, line = extract_left_or_right_qualifier_or_gender(
#        line, on_left=True)
#      if this_left_quals is None:
#        break
#      left_qual.extend(this_left_quals)
#
#    while True:
#      this_right_quals, this_right_gender, this_right_gloss, line = extract_left_or_right_qualifier_or_gender(
#        line, on_left=False)
#      if this_right_quals is None and this_right_gender is None and this_right_gloss is None:
#        break
#      if this_right_quals:
#        right_qual.extend(this_right_quals)
#      if this_right_gender:
#        exterior_genders.append(this_right_gender)
#      if this_right_gloss:
#        right_gloss.append(this_right_gloss)
#
#    return line, left_qual, right_qual, exterior_genders, right_gloss, line_comment
#
#  def construct_line_with_quals(vals, left_qual, right_qual, exterior_genders, right_gloss, line_comment):
#    def convert_quals(quals, is_left, has_pos, has_g):
#      qualparts = []
#      non_converted_quals = []
#      labels = []
#      def convert_qual(qual):
#        nonlocal has_pos, has_g
#        gender_map = {
#          "m": "m",
#          "m.": "m",
#          "masc": "m",
#          "masc.": "m",
#          "masculine": "m",
#          "f": "f",
#          "f.": "f",
#          "fem": "f",
#          "fem.": "f",
#          "feminine": "f",
#          #"n": "n", existing uses seem to be "noun" not "neuter"
#          #"n.": "n", existing uses seem to be "noun" not "neuter"
#          "neut": "n",
#          "neut.": "n",
#          "neuter": "n",
#          "mp": "m-p",
#          "m.p.": "m-p",
#          "m.pl.": "m-p",
#          "m-p": "m-p",
#          "m p": "m-p",
#          "m pl": "m-p",
#          "m. p.": "m-p",
#          "m. pl.": "m-p",
#          "masc pl": "m-p",
#          "masc. pl.": "m-p",
#          "masculine plural": "m-p",
#          "fp": "f-p",
#          "f.p.": "f-p",
#          "f.pl.": "f-p",
#          "f-p": "f-p",
#          "f p": "f-p",
#          "f pl": "f-p",
#          "f. p.": "f-p",
#          "f. pl.": "f-p",
#          "fem pl": "f-p",
#          "fem. pl.": "f-p",
#          "feminine plural": "f-p",
#          "np": "n-p",
#          "n.p.": "n-p",
#          "n.pl.": "n-p",
#          "n-p": "n-p",
#          "n p": "n-p",
#          "n pl": "n-p",
#          "n. p.": "n-p",
#          "n. pl.": "n-p",
#          "neut pl": "n-p",
#          "neut. pl.": "n-p",
#          "neuter plural": "f-p",
#          "pl": "p",
#          "pl.": "p",
#          "plural": "p",
#        }
#        label_map = {
#          "archaic or obsolete": "archaic,or,obsolete",
#          "Sanskritized, rare": "Sanskritized,rare",
#          "Sanskritized, Rare": "Sanskritized,rare",
#          "Sanskritized, literary": "Sanskritized,literary",
#          "Sanskritized, formal or literary": "Sanskritized,formal,or,literary",
#          "Persianized, rare": "Persianized,rare",
#          "chiefly Islam": "chiefly,Islam",
#          "chiefly Hinduism": "chiefly,Hinduism",
#          "Mediaeval Latin": "Medieval Latin",
#          "Med. Lat.": "Medieval Latin",
#          "Mediaeval": "Medieval",
#          "BrE": "UK",
#          "obsolete, rare": "obsolete,rare",
#          "zoölogy": "zoology",
#          "South African English": "South Africa",
#          "place name": "toponym",
#          "placename": "toponym",
#          "place": "toponym",
#          "Colloquial": "colloquial",
#          "Rare": "rare",
#          "patronym": "patronymic",
#          "Diminutives:": "diminutive",
#          "Endearing forms:": "endearing",
#          "Pejorative forms:": "pejorative",
#          "Patronymics:": "patronymic",
#          "Surnames:": "surname",
#          "New vocatives:": "new vocative",
#          "New vocative:": "new vocative",
#          "factative": "factitive",
#        }
#        pos_map = {
#          "adj.": "adj",
#          "adjective and noun": "adjective, noun",
#          "n.": "n",
#          "intransitive": "vi",
#          "transitive": "vt",
#        }
#        m = re.search("^'*literally[:;'\" ]+(.*?)['\"]?$", qual)
#        if m:
#          qualparts.append(make_inline_mod("lit", m.group(1)))
#        elif qual in label_map:
#          labels.append(label_map[qual])
#        elif qual in [
#          "rare", "uncommon", "colloquial", "informal", "nonstandard", "non-standard", "offensive",
#          "figurative", "figuratively", "formal", "learned", "impersonal", "slang", "vulgar", "literary", "historical",
#          "humble speech", "jocular", "euphemistic", "derogatory", "expressive", "vernacular", "childish",
#          "abbreviation", "initialism", "back-formation", "clipping", "blend", "proverb",
#          "active", "passive", "reflexive", "mediopassive", "iterative", "causative", "causative-iterative",
#          "collective",
#          "dialectal", "regional", "poetic", "uncertain", "honorific", "nickname", "pejorative", "humorous",
#          "toponym", "surname", "patronymic", "female patronymic", "male patronymic", "former name",
#          "obsolete", "archaic", "dated", "deprecated", "diminutive", "augmentative", "endearing", "semelfactive",
#          "US", "American", "North America", "Canada", "Canadian", "UK", "British", "Britain", "British English",
#          "Australia", "Australian", "Ireland", "Irish", "New Zealand", "Indian English", "AU", "NZ",
#          "Anglo-Norman", "Standard Malay", "Indonesian",
#          "Spain", "Argentina", "Venezuela", "Dominican Republic", "Costa Rica", "Mexico", "Puerto Rico", "Paraguay",
#          "Uruguay", "Chile", "Bolivia", "Colombia", "Costa Rica", "Cuba", "Panama", "Nicaragua", "Ecuador",
#          "El Salvador", "Honduras", "Peru", "Guatemala", "Brazil", "Portugal", "Belize",
#          "Puter", "Sursilvan", "Sutsilvan", "Surmiran", "Vallader", "Rumantsch Grischun",
#          "sports", "medicine", "law", "logic", "shipping", "theology", "phonology", "music", "grammar", "religion",
#          "linguistics", "geology", "botany", "ornithology", "sociology", "psychiatry", "zoology", "anatomy",
#          "chemistry", "architecture", "phonetics", "biology", "astronomy",
#          "Sanskritized", "Sanskritised", "Persianized", "Persianised", "Netherlands",
#          "Late Latin", "Classical", "Byzantine", "Vulgar Latin", "Medieval Latin", "New Latin", "Katharevousa",
#          "Gheg", "Standard", "Tosk", "Arbërisht", "Arvanitic",
#          "East Slavic", "North Korea", "South Korea", "Münsterländisch", "Kamviri", "Altmärkisch", "North Germanic",
#          "Pulaar", "Pular", # two different languages!
#          "Maasina", "Adamawa", "Kuril Ainu", "Northern Finnic", "Ecclesiastical", "Quebec", "Austria", "Algherese",
#        ]:
#          labels.append(qual)
#        elif not has_pos and qual in pos_map:
#          qualparts.append(make_inline_mod("pos", pos_map[qual]))
#          has_pos = True
#        elif not has_pos and qual in [
#          "noun", "n", "proper noun", "adjective", "adj", "verb", "v", "vb", "adverb", "adv", "preposition", "prep",
#          "conjunction", "conj", "verbal noun", "[[vi]]", "[[vt]]", "participle", "adjective, noun", "agent nouns",
#          "agent noun", "[[na]]", "[[ni]]", "[[vai]]", "[[vii]]", "[[vti]]", "[[vta]]", "na", "ni", "vai", "vii", "vti",
#          "vta", "instrumental nouns", "instrumental noun", "action noun", "gerund",
#        ]:
#          qualparts.append(make_inline_mod("pos", qual.replace("[[", "").replace("]]", "")))
#          has_pos = True
#        elif not has_g and qual in gender_map:
#          if is_left:
#            qualparts.append(make_inline_mod("g", gender_map[qual]))
#            has_g = True
#          else:
#            exterior_genders.append(gender_map[qual])
#        else:
#          seen_quals[qual] += 1
#          non_converted_quals.append(qual)
#      for qual in quals:
#        convert_qual(qual)
#      if labels:
#        qualparts.append(make_inline_mod("l" if is_left else "ll", ",".join(labels)))
#      if non_converted_quals:
#        qualparts.append(make_inline_mod("q" if is_left else "qq", ", ".join(non_converted_quals)))
#      return "".join(qualparts)
#
#    if left_qual:
#      vals[0] += convert_quals(left_qual, True, "<pos:" in vals[0], "<g:" in vals[0])
#    if right_qual:
#      vals[-1] += convert_quals(right_qual, False, "<pos:" in vals[-1], "<g:" in vals[-1])
#    if exterior_genders:
#      if "<g:" in vals[-1]:
#        pagemsg("WARNING: Saw both interior and exterior genders, trying to combine")
#        vals[-1] = re.sub("(<g:.*?)>", r"\1,%s>" % escape_inline_val(",".join(exterior_genders)), vals[-1])
#      else:
#        vals[-1] += make_inline_mod("g", ",".join(exterior_genders))
#    if right_gloss:
#      if "<t:" in vals[-1]:
#        pagemsg("WARNING: Saw both interior and exterior glosses, trying to combine")
#        vals[-1] = re.sub("(<t:.*?)>", r"\1; %s>" % escape_inline_val("; ".join(right_gloss)), vals[-1])
#      else:
#        vals[-1] += make_inline_mod("t", "; ".join(right_gloss))
#    return ",".join(vals) + line_comment
#
#  notes = []
#
#  sections, sections_by_lang, section_langs = blib.split_text_into_sections(text, pagemsg)
#  section_langs = dict(section_langs)
#  for j in range(2, len(sections), 2):
#    langname = section_langs[j]
#    if langname not in blib.languages_byCanonicalName:
#      pagemsg("WARNING: Unknown language name %s, skipping section %s" % (langname, j // 2))
#      continue
#    langcode = blib.languages_byCanonicalName[langname]["code"]
#    subsections, subsections_by_header, subsection_headers, subsection_levels = (
#      blib.split_text_into_subsections(sections[j], pagemsg)
#    )
#    for k in range(2, len(subsections), 2):
#      header = subsection_headers[k]
#
#      if args.do_col and re.search(r"\{\{ *col[0-9]* *\|", subsections[k]):
#        parsed = blib.parse_text(subsections[k])
#        for t in parsed.filter_templates():
#          tn = tname(t)
#          if tn in ["col", "col1", "col2", "col3", "col4", "col5", "col6"]:
#            newparams = []
#            numrows = 0
#            numchangedrows = 0
#            origt = str(t)
#            tlang = getparam(t, "1").strip()
#            for param in t.params:
#              pn = pname(param)
#              pv = str(param.value)
#              if pn != "1" and re.search("^[0-9]+$", pn):
#                numrows += 1
#                m = re.search(r"(\s*)(.*?)(\s*)$", pv, re.S)
#                beginspace, maintext, endspace = m.groups()
#                newmaintext, left_qual, right_qual, exterior_genders, right_gloss, line_comment = (
#                  extract_left_and_right_qualifiers_and_genders(maintext))
#                newparts, new_notes = convert_one_line(newmaintext, False, langcode, langname, pagemsg, expand_text)
#                if type(newparts) is str:
#                  pagemsg("WARNING: %s, not changing: %s" % (newparts, pv.strip()))
#                elif newparts is not None:
#                  newmaintext = construct_line_with_quals(
#                    newparts, left_qual, right_qual, exterior_genders, right_gloss, line_comment)
#                  newpv = beginspace + newmaintext + endspace
#                  numchangedrows += 1
#                  pagemsg("Replaced %s=<%s> with <%s> in {{%s|%s}} in ==%s==" % (
#                    pn, pv.strip(), newpv.strip(), tn, tlang, header.strip()))
#                  pv = newpv
#                  notes.extend(new_notes)
#              newparams.append((pn, pv, param.showkey))
#            del t.params[:]
#            for pn, pv, showkey in newparams:
#              t.add(pn, pv, showkey=showkey, preserve_spacing=False)
#            if origt != str(t):
#              notes.append("optimize %s of %s row%s in {{%s|%s}} in ==%s==" % (
#                numchangedrows, numrows, "s" if numrows != 1 else "", tn, tlang, header.strip()))
#        subsections[k] = str(parsed)
#
#      expected_abbrev = header_to_col_top_abbrev.get(header, None)
#      lines = subsections[k].split("\n")
#      newlines = []
#      raw_col_lines = None
#      col_elements = None
#      if args.do_derived_related:
#        if header.strip() in ["Derived terms", "Related terms"]:
#          in_col_top = True
#          lines.append("\uFFF0") # sentinel line
#          raw_col_lines = []
#          for line in lines:
#            if line.startswith("*"):
#              raw_col_lines.append(line)
#            else:
#              break
#          total_processable_lines = len(raw_col_lines)
#          if total_processable_lines < args.min_derived_related_lines:
#            pagemsg("Saw only %s element%s in ==%s==, can't convert to {{col}}" % (
#              total_processable_lines, "" if total_processable_lines == 1 else "s", header.strip()))
#            in_col_top = False
#          raw_col_lines = []
#          col_elements = []
#        else:
#          in_col_top = False
#      else:
#        in_col_top = False
#      col_top_tn = None
#      new_notes = []
#      cant_convert = False
#      col_top_header = None
#      for line in lines:
#        if in_col_top:
#          raw_col_lines.append(line)
#          if args.do_derived_related and not line.startswith("*"):
#            if len(col_elements) < args.min_derived_related_lines:
#              pagemsg("Processed %s element%s out of %s in ==%s== before getting to an unconvertible element" % (
#                len(col_elements), "" if len(col_elements) == 1 else "s", total_processable_lines, header.strip()))
#              cant_convert = True
#              newlines.extend(raw_col_lines)
#              in_col_top = False
#              continue
#            elif cant_convert:
#              newlines.extend(raw_col_lines)
#              in_col_top = False
#              continue
#            else:
#              no_sort_param = ""
#              if pagetitle in no_sort_lists:
#                for no_sort_lang, no_sort_firstel in no_sort_lists[pagetitle]:
#                  if no_sort_lang == langcode:
#                    if no_sort_firstel == col_elements[0][1:]:
#                      no_sort_param = "|sort=0"
#                    else:
#                      pagemsg("WARNING: Found no-sort directive matching langcode '%s' but specified first element '%s' didn't match actual first element '%s'" % (
#                        langcode, no_sort_firstel, col_elements[0][1:]))
#              newlines.append("{{col|%s%s" % (langcode, no_sort_param))
#              newlines.extend(col_elements)
#              newlines.append("}}")
#              newlines.append(line)
#              notes.extend(new_notes)
#              notes.append("convert %s raw elements under ==%s== to {{col|%s%s|%s|%s|...}}" % (
#                len(col_elements), header.strip(), langcode, no_sort_param, col_elements[0][1:], col_elements[1][1:]))
#              in_col_top = False
#              continue
#          m = re.search("^\{\{ *((?:col-)?bottom) *\|", line.strip())
#          if m:
#            if not cant_convert:
#              pagemsg("WARNING: Saw {{%s}} with params, can't convert to {{col}}: %s" % (m.group(1), origline))
#            newlines.extend(raw_col_lines)
#            in_col_top = False
#            continue
#          m = re.search("^\{\{ *((?:col-)?bottom) *\}\}$", line.strip())
#          if m:
#            if cant_convert:
#              newlines.extend(raw_col_lines)
#              in_col_top = False
#              continue
#            if col_top_header and col_top_header != expected_abbrev:
#              col_top_header = shortcut_to_expansion.get(col_top_header, col_top_header)
#            else:
#              col_top_header = ""
#            col_bottom_tn = m.group(1)
#            newlines.append("{{col|%s%s" % (
#              langcode, "|title=%s" % col_top_header if col_top_header else ""
#            ))
#            newlines.extend(col_elements)
#            newlines.append("}}")
#            notes.extend(new_notes)
#            notes.append("convert {{%s}}/{{%s}} to {{col|%s|...}} with %s line%s in ==%s==" % (
#              col_top_tn, col_bottom_tn, langcode, len(col_elements), "" if len(col_elements) == 1 else "s",
#              header.strip()))
#            in_col_top = False
#            continue
#          if cant_convert:
#            continue
#          if not line.startswith("*"):
#            pagemsg("WARNING: Non-bulleted line, can't convert to {{col}} (yet?): %s" % line)
#            cant_convert = True
#            continue
#          if re.search(r"\{\{ *desc *\|", line):
#            pagemsg("WARNING: Line with {{desc}}, can't convert to {{col}}: %s" % line)
#            cant_convert = True
#            continue
#          if re.search(r"\{\{ *desctree *\|", line):
#            pagemsg("WARNING: Line with {{desctree}}, can't convert to {{col}}: %s" % line)
#            cant_convert = True
#            continue
#          m = re.search(r"^(\*+)(.*)$", line)
#          if not m:
#            pagemsg("WARNING: Internal error: Line doesn't have a term after a single bullet: %s" % line)
#            cant_convert = True
#            continue
#          origline = line
#          number_of_bullets, line = m.groups()
#          if re.search("^[:#]", line):
#            pagemsg("WARNING: Saw *: or *# at beginning of line, can't convert to {{col}}: %s" % origline)
#            cant_convert = True
#            continue
#          if len(number_of_bullets) == 1:
#            bullet_prefix = ""
#          else:
#            bullet_prefix = number_of_bullets[1:] + " "
#          line = line.strip()
#          bulleted_line = escape_template_delimiters(bullet_prefix + line, pagemsg)
#          if re.search(r"\{\{ *(ja-l|ja-r|ja-r/args|ryu-l|ryu-r|ryu-r/args|ko-l|zh-l|vi-l|he-l) *\|", line):
#            pagemsg("WARNING: Unable to convert specialized Asian linking template to {{col}} format, inserting raw: %s" % origline)
#            col_elements.append("|%s" % bulleted_line)
#            continue
#          if re.search(r"\{\{ *(vern|taxfmt|taxlink) *\|", line):
#            pagemsg("WARNING: Unable to convert specialized taxonomy linking template to {{col}} format, inserting raw: %s" % origline)
#            col_elements.append("|%s" % bulleted_line)
#            continue
#
#          def handle_parse_error(reason):
#            nonlocal cant_convert
#            if re.search(match_link_template_re, line):
#              pagemsg("WARNING: %s and line has templated link, inserting raw: %s" % (reason, origline))
#              col_elements.append("|%s" % bulleted_line)
#            else:
#              pagemsg("WARNING: %s and no templated link present, can't convert to {{col}}: %s" % (reason, origline))
#              cant_convert = True
#
#          line, left_qual, right_qual, exterior_genders, right_gloss, line_comment = (
#            extract_left_and_right_qualifiers_and_genders(line))
#          els, this_new_notes = convert_one_line(line, True, langcode, langname, pagemsg, expand_text)
#          if type(els) is str:
#            handle_parse_error(els)
#          elif els is None:
#            handle_parse_error("Can't parse links")
#          else:
#            newline = "|%s%s" % (bullet_prefix, construct_line_with_quals(
#              els, left_qual, right_qual, exterior_genders, right_gloss, line_comment))
#            col_elements.append(newline)
#            new_notes.extend(this_new_notes)
#
#        else:
#          m = None
#          if not m and args.do_col_top:
#            m = re.search(r"^\{\{(col-top)\|[0-9]+\|([^|=]*)\}\}$", line)
#            if m:
#              col_top_tn, col_top_header = m.groups()
#          if not m and args.do_top:
#            m = re.search(r"^\{\{(top[0-9])\}\}$", line)
#            if m:
#              col_top_tn = m.group(1)
#              col_top_header = ""
#          if not m and args.do_top:
#            m = re.search(r"^\{\{(top[0-9])\|([^{}]*)\}\}$", line)
#            if m:
#              col_top_tn, col_top_header = m.groups()
#              if col_top_header == langcode:
#                col_top_header = ""
#              if col_top_header.startswith("title="):
#                col_top_header = col_top_header[6:]
#          if m:
#            in_col_top = True
#            col_elements = []
#            new_notes = []
#            cant_convert = False
#            raw_col_lines = [line]
#          else:
#            newlines.append(line)
#      if in_col_top:
#        pagemsg("WARNING: Saw {{col-top}} without closing {{col-bottom}}")
#        newlines.extend(raw_col_lines)
#      subsections[k] = "\n".join(x for x in newlines if x != "\uFFF0") # exclude sentinel
#    sections[j] = "".join(subsections)
#
#  return "".join(sections), notes

if __name__ == "__main__":
  parser = blib.create_argparser("Convert translation lines to {{t-new}}",
                                 include_pagefile=True, include_stdin=True)
  args = parser.parse_args()
  start, end = blib.parse_start_end(args.start, args.end)

  blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True)

  msg("")
  msg("%-50s | %s" % ("Qualifier", "Count"))
  msg("-" * 58)
  for qual, count in sorted(seen_quals.items(), key=lambda x: -x[1]):
    msg("%-50s = %s" % (qual, count))
