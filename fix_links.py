#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This program replaces raw links of the form '[[foo]]' with templated links
# of the form '{{l|ru|foo}}', and raw two-part links of the form '[[foo|bar]]'
# with templated links of the form '{{l|ru|foo|bar}}', for various specified
# languages. When converting two-part links to templated links it is smart
# enough to recognize links of the form '[[foo#Russian|bar]]'', and smart
# enough to recognize cases where 'bar' is just the accented form of 'foo'
# and hence it can be converted to a one-part templated link. Links are only
# converted if they occur on a line beginning with '*', and will be converted
# to '{{m|ru|foo}}' rather than '{{l|ru|foo}}' in certain sections (e.g.
# Usage Notes sections).
#
# The program also looks for transliteration following the raw link, e.g. in
# the form '[[фоо]] (foo)'. It uses Levenshtein distance to check whether the
# thing in parens is actually a reasonable-looking transliteration, and
# ignores it if not. If so, it is converted to a |tr=foo param, or ignored
# entirely if the language ignores manual translit.
#
# The program handles one Latin-script language (French), and in that case
# is more careful to avoid converting raw links that are probably not to
# French vocabulary words (e.g. to numbers or symbols).

import pywikibot, re, sys, argparse

import blib
from blib import getparam, rmparam, msg, site, rsub_repeatedly
import lang_utils

thislangcodes = None
thislangnames = None

sections_to_always_include = {
  "Anagrams", "Related terms", "Synonyms", "Derived terms", "Alternative forms",
  "Antonyms", "Compounds", "Coordinate terms", "Hyponyms", "Hypernyms",
  "Abbreviations", "Meronyms", "Holonyms", "Troponyms", "Homophones"
}
# Always skip Etymology, Pronunciation, Descendants, References,
# Further reading, Quotations, etc.

def process_text_on_page(index, pagetitle, text):
  global args
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  if ":" in pagetitle and not pagetitle.startswith("Reconstruction:"):
    return

  def expand_text(tempcall):
    return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

  notes = []
  subbed_links = []

  # Split off templates, tables, in each case allowing one nested template;
  # also split off comments and stuff after dashes and between quotes.
  template_table_split_re = r'''(\{\{(?:[^{}]|\{\{[^{}]*\}\})*\}\}|\{\|(?:[^{}]|\{\{[^{}]*\}\})*\|\}|<!--.*-->| +(?:[-–—=]|&[mn]dash;) +[^\n]*|\(?(?<!')''[^'\n]*?''\)?|"[^"\n]*?"|“[^\n]*?”|‘[^\n]*?’)'''

  def do_section(sectext, thislangname):
    if thislangname in thislangnames:
      thislangcode, this_remove_accents, this_charset, this_ignore_translit = (
          lang_utils.language_names_to_properties[thislangname])

      subsections = re.split("(^==.*==\n)", sectext, 0, re.M)
      for k in range(2, len(subsections), 2):
        m = re.search("^===*([^=]*)=*==\n$", subsections[k-1])
        subsectitle = m.group(1).strip()
        if not (
          subsectitle in sections_to_always_include or
          this_ignore_translit != "latin" and subsectitle == "Usage notes" or
          (args.do_see_also or this_ignore_translit != "latin") and subsectitle == "See also"
        ):
          continue

        def linktext(cap=False):
          if cap:
            return "Link in '%s' in %s" % (subsectitle, thislangname)
          else:
            return "link in '%s' in %s" % (subsectitle, thislangname)
        def sub_link(orig, text, translit, origtemplate):
          if re.search("[\[\]]", text):
            pagemsg("WARNING: Stray brackets in %s, skipping: %s" %
              (linktext(), orig))
            return orig
          if this_ignore_translit == "latin":
            if not re.search("^[#|%s]+$" % this_charset, text):
              pagemsg("WARNING: %s contains characters not in proper charset, skipping: %s" %
                  (linktext(cap=True), orig))
              return orig
          else:
            if not re.search("[^ -~]", text):
              pagemsg("No non-Latin characters in %s, skipping: %s" %
                (linktext(), orig))
              return orig
            if not re.search("^[ -~%s]*$" % this_charset, text):
              pagemsg("WARNING: %s contains non-Latin characters not in proper charset, skipping: %s" %
                  (linktext(cap=True), orig))
              return orig
          parts = re.split(r"\|", text)
          if len(parts) > 2:
            pagemsg("WARNING: Too many parts in %s, skipping: %s" %
                (linktext(), orig))
            return orig
          template = origtemplate or subsectitle == "Usage notes" and "m" or "l"
          if not origtemplate and thislangcode == "grc" and subsectitle == "Descendants":
            pagemsg("Using langcode=el instead of grc in Descendants section")
            langcode = "el"
          else:
            langcode = thislangcode
          subbed_links.append((lang_utils.language_codes_to_properties[langcode][0], "[[%s]]" % text))
          page = None
          if len(parts) == 1:
            accented = text
          else:
            page, accented = parts
            page = re.sub("#%s$" % thislangname, "", page)
          if page and this_remove_accents(accented) == page:
            page = None
          if "#" in (page or accented):
            pagemsg("WARNING: Found special char # in %s, skipping: %s" % (linktext(), orig))
            return orig
          if page:
            pagemsg("WARNING: Page %s doesn't match accented %s in %s, converting to two-part link" %
                (page, accented, linktext()))
          translit_arg = ""
          post_translit_arg = ""
          if translit and this_ignore_translit == "notranslit":
            pagemsg("WARNING: Unable to determine whether putative explicit translit %s is translit of %s in %s" % (
              translit, accented, linktext()))
            post_translit_arg = " (%s)" % translit
          elif translit:
            orig_translit = translit
            translit = re.sub(r"^\[\[(.*)\]\]$", r"\1", translit)
            translit = re.sub(r"^''(.*)''$", r"\1", translit)
            accented_translit = expand_text("{{xlit|%s|%s}}" % (langcode,
                accented))
            if accented_translit == "":
              pagemsg("WARNING: Unable to transliterate %s (putative explicit transit %s in %s)" %
                  (accented, translit, linktext()))
            if not accented_translit:
              # Error occurred computing transliteration
              post_translit_arg = " (%s)" % orig_translit
            elif accented_translit == translit:
              pagemsg("No translit difference between explicit %s and auto %s (%s) in %s" %
                (translit, accented_translit, accented, linktext()))
              # Translit same as explicit translit, ignore
              pass
            else:
              levdist = blib.levenshtein(accented_translit, translit)
              tranlen = min(len(translit), len(accented_translit))
              if accented_translit[0].isupper() != translit[0].isupper():
                pagemsg("WARNING: Upper/lower mismatch between explicit %s and auto %s, not treating as translit (%s) in %s" %
                  (translit, accented_translit, accented, linktext()))
                post_translit_arg = " (%s)" % orig_translit
              elif thislangcode == "grc" and (translit.endswith("ic") or translit.endswith("an")):
                pagemsg("WARNING: Explicit translit %s ends with -ic or -an, not treating as translit vs. auto-translit %s (Levenshtein distance %s, %s in %s)" %
                  (translit, accented_translit, levdist, accented, linktext()))
                post_translit_arg = " (%s)" % orig_translit
              elif (levdist == 1 and tranlen >= 3 or levdist == 2 and tranlen >= 4
                  or levdist == 3 and tranlen >= 5 or levdist == 4 and tranlen >= 7
                  or levdist == 5 and tranlen >= 9):
                pagemsg("Levenshtein distance %s and length %s, accept translit difference between explicit %s and auto %s (%s) in %s" %
                  (levdist, tranlen, translit, accented_translit, accented, linktext()))
                if not this_ignore_translit:
                  translit_arg = "|tr=%s" % translit
              else:
                pagemsg("WARNING: Levenshtein distance %s too big for length %s, not treating %s as transliteration of %s (%s) in %s" %
                  (levdist, tranlen, translit, accented_translit, accented, linktext()))
                post_translit_arg = " (%s)" % orig_translit

          if page:
            return "{{%s|%s|%s|%s%s}}%s" % (template, langcode, page,
                accented, translit_arg, post_translit_arg)
          else:
            return "{{%s|%s|%s%s}}%s" % (template, langcode, accented,
                translit_arg, post_translit_arg)

        def obfuscate_brackets(text):
          return text.replace("[", lbracket_sub).replace("]", rbracket_sub)

        def unobfuscate_brackets(text):
          return text.replace(lbracket_sub, "[").replace(rbracket_sub, "]")

        def sub_raw_latin_link(m):
          if m.group(1).count('(') != m.group(1).count(')'):
            pagemsg("WARNING: Unbalanced parens preceding raw %s: %s" %
                (linktext(), unobfuscate_brackets(m.group(0))))
            retsub = m.group(2)
          else:
            retsub = sub_link(m.group(2), m.group(3), None, None)
          return m.group(1) + obfuscate_brackets(retsub)

        def sub_raw_link(m):
          return sub_link(m.group(0), m.group(1), m.group(2), None)

        def sub_template_link(m):
          return sub_link(m.group(0), m.group(2), m.group(3), m.group(1))

        # Split templates, then rejoin text involving templates that don't
        # have newlines in them
        split_templates = re.split(template_table_split_re, subsections[k], 0, re.S)
        must_continue = False
        for l in range(0, len(split_templates), 2):
          if "{" in split_templates[l] or "}" in split_templates[l]:
            pagemsg("WARNING: Stray brace in split_templates[%s] in '%s' in %s: Skipping section: <<%s>>" %
              (l, subsectitle, thislangname, split_templates[l].replace("\n", r"\n")))
            must_continue = True
            break
        if must_continue:
          continue
        # Add an extra newline to first item so we can consistently check
        # below for lines beginning with *, rather than * directly after
        # a template; will remove the newline later
        split_text = ["\n" + split_templates[0]]
        for l in range(1, len(split_templates), 2):
          if "\n" in split_templates[l]:
            split_text.append(split_templates[l])
            split_text.append(split_templates[l+1])
          else:
            split_text[-1] += split_templates[l] + split_templates[l+1]

        #if verbose:
        #  pagemsg("Processing split_text: %s" % split_text)
        # Split on newlines and look for lines beginning with *. Then
        # split on templates and look for links without Latin in them.
        for kk in range(0, len(split_text), 2):
          lines = re.split(r"(\n)", split_text[kk])
          for l in range(0, len(lines), 2):
            line = lines[l]
            #if verbose:
            #  pagemsg("Processing line: %s" % line)
            if line.startswith("*"):
              split_line = re.split(template_table_split_re, line, 0, re.S)
              for ll in range(0, len(split_line), 2):
                subline = split_line[ll]
                replaced = False
                # Ignore links with a colon (category links and such)
                if this_ignore_translit == "latin":
                  new_subline = unobfuscate_brackets(
                      rsub_repeatedly(r"^(.*?)(\[\[([^:]*?)\]\])", sub_raw_latin_link, subline))
                else:
                  new_subline = re.sub(r"\[\[([^:A-Za-z]*?)\]\](?: \(([^()|]*?)\))?", sub_raw_link, subline)
                if new_subline != subline:
                  pagemsg("Replacing %s with %s in %s section in %s" %
                    (subline, new_subline, subsectitle, thislangname))
                  subline = new_subline
                  replaced = True
                if this_ignore_translit != "latin":
                  # Only try subbing template links with what looks like a
                  # following translit
                  new_subline = re.sub(r"\{\{([lm])\|%s\|([^A-Za-z{}]*?)\}\}(?: \(([^()|]*?)\))" % thislangcode, sub_template_link, subline)
                  if new_subline != subline:
                    pagemsg("Replacing %s with %s in %s section in %s" % (subline, new_subline, subsectitle, thislangname))
                    subline = new_subline
                    replaced = True

                if replaced:
                  split_line[ll] = subline
                  lines[l] = "".join(split_line)
                  split_text[kk] = "".join(lines)
                  # Strip off the newline we added at the beginning
                  subsections[k] = "".join(split_text)
                  assert subsections[k][0] == "\n"
                  subsections[k] = subsections[k][1:]
                  sectext = "".join(subsections)

        # Check for gender placed after a link and incorporate into the link.
        seclines = subsections[k].split("\n")
        replaced = False
        for lineind, secline in enumerate(seclines):
          def incorporate_gender(m):
            main_template, gender = m.groups()
            maint = list(blib.parse_text(main_template).filter_templates())[0]
            if getparam(maint, "g"):
              pagemsg("WARNING: Found postposed gender template after link template already containing gender: %s"
                  % m.groups(0))
              return m.groups(0)
            notes.append("incorporate g=%s into %s" % (gender, str(maint)))
            maint.add("g", gender)
            return str(maint)
          new_secline = re.sub(r"(\{\{[lm]\|%s\|[^{}]*\}\}) \{\{g\|([^{}|=]*)\}\}" % thislangcode, incorporate_gender, secline)
          if new_secline != secline:
            pagemsg("Replacing %s with %s in %s section in %s" % (secline, new_secline, subsectitle, thislangname))
            seclines[lineind] = new_secline
            replaced = True
        if replaced:
          subsections[k] = "\n".join(seclines)
          sectext = "".join(subsections)

    return sectext

  if args.single_lang:
    newtext = do_section(text, args.single_lang)
  else:
    sections = re.split("(^==[^\n=]*==\n)", text, 0, re.M)
    for j in range(2, len(sections), 2):
      m = re.search("^==(.*?)==\n$", sections[j - 1])
      if not m:
        pagemsg("WARNING: Something wrong, can't parse section from %s" %
          sections[j - 1].strip())
        continue
      thislangname = m.group(1)
      sections[j] = do_section(sections[j], thislangname)
    newtext = "".join(sections)

  if subbed_links:
    seen_langs = {}
    for langname, subbed_link in subbed_links:
      if langname in seen_langs:
        seen_langs[langname].append(subbed_link)
      else:
        seen_langs[langname] = [subbed_link]
    subbed_links_notes = []
    for langname, lang_subbed_links in sorted(seen_langs.items()):
      subbed_links_notes.append("replace raw %s links with templated links: %s" % (langname, ",".join(lang_subbed_links)))
    notes[0:0] = subbed_links_notes
  return newtext, notes

if __name__ == "__main__":
  parser = blib.create_argparser("Replace raw links with templated links",
    include_pagefile=True, include_stdin=True)
  parser.add_argument('--langs', help="Language codes for languages to do, comma-separated")
  parser.add_argument('--single-lang', help="Text is of this language, without header")
  parser.add_argument('--do-see-also', action="store_true", help="Do ==See also== sections even in Latin-text langs")
  args = parser.parse_args()
  start, end = blib.parse_start_end(args.start, args.end)

  if not args.langs:
    raise ValueError("Language code(s) must be specified")

  if args.langs == "all":
    langs = sorted(list(lang_utils.language_codes_to_properties.keys()))
  else:
    langs = args.langs.split(",")
  default_cats = []
  thislangnames = set()
  for lang in langs:
    if lang not in lang_utils.language_codes_to_properties:
      raise ValueError("Unrecognized language code: %s" % lang)
    thislangname, this_remove_accents, this_charset, this_ignore_translit = (
      lang_utils.language_codes_to_properties[lang])
    default_cats.append("%s lemmas" % thislangname)
    default_cats.append("%s non-lemma forms" % thislangname)
    thislangnames.add(thislangname)

  thislangcodes = langs

  blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
    edit=True, stdin=True, default_cats=default_cats)
