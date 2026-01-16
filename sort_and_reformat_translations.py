#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse, unicodedata

import blib
from blib import getparam, rmparam, msg, errmsg, site, tname
from collections import defaultdict

#blib.init_fake_langdata()
blib.getData()

def boolean_function_matches(fun, lang):
  if callable(fun):
    return fun(lang)
  else:
    return lang in fun

def default_indentfun(group, lang):
  return lang.endswith(" " + group)

indonesian_malay_recognize = {"Carakan"}
indonesian_malay_rename_map = {
  "Arabic": "Jawi",
  "Roman": "Rumi",
  "Latin": "Rumi",
  "Brunei": "Brunei Malay",
  "Kelantan-Pattani Malay": "Pattani Malay",
  "Indonesia": "Indonesian",
  "Sarawakian": "Sarawak Malay",
  "Singkil": "Alas-Kluet Batak",
}
indonesian_malay_unindent = {
  "Acehnese", "Alas-Kluet Batak", "Ambonese Malay", "Baba Malay", "Balinese", "Banda", "Banjarese", "Buginese",
  "Brunei Malay", "Ende", "Indonesian", "Jambi Malay", "Javanese", "Madurese", "Makasar", "Minangkabau", "Nias",
  "Pattani Malay", "Sarawak Malay", "Sikule", "Simeulue", "Sundanese", "Terengganu Malay"
}

# Groups of languages handled under a single header, with properties. The key is the top-level header, which is usually
# a language name in its own right. The value is a dictionary of properties, with keys as follows:
# * "indent": Set of language names or a function of one argument, a language, that should return True if an unindented
#   lang of that name should be indented under this header. If unspecified, the default is to recognize any language
#   ending in the header's name.
# * "add_lang": Set of language names or a function of one argument, a language, that should return True if an indented
#   language of this name should have the header language appended to it. For example, under header "Arabic", if
#   `add_lang` contains "Algerian" or is a function that returns True when passed "Algenian", then a language named
#   "Algerian" that's already indented (or newly indented) under header "Arabic" will be converted to "Algerian Arabic".
#   Any occurrence of "Algerian" unindented or under a different header will not be affected.
# * "rename": A dictionary mapping languages to new names. A language with the key that is indented under the specified
#   header will be renamed to the value. Like "add_lang", this will not affected languages that are unindented or
#   indented under a different header.
# * "unindent": Set of language names or a function of one argument, a language, that should return True if the language
#   occurring indented under the header will be unindented (moved to top level).
# * "recognize": Set or language names or a function of one argument, a language, that should return True if a given
#   indented lang is recognized as belonging under this header. Any languages that return True when passed to `indent`,
#   as well as any languages on the right side of the `rename` dictionary or the right side of the virtual dictionary
#   specified by `add_lang` (i.e. any languages consisting of an element in `add_lang` plus the header name) will
#   automatically count, so this function only needs to return True for other languages. A warning will be emitted if
#   an indented language is seen that is not recognized, but no other action will be taken. (This is useful for finding
#   misspellings and non-canonical language names that need fixing up.) If `recognize` is omitted, it is equivalent to a
#   function returning False, i.e. any indented language not recognized by the other methods specified above will result
#   in a warning.
language_groups = {
  "Albanian": {
    "indent": lambda lang: lang.endswith(" Albanian") or lang in {"Arbëresh", "Arvanitika", "Tosk", "Gheg"},
  },
  "Apache": {
    "indent": lambda lang: lang.endswith(" Apache") or lang in {"Jicarilla", "Lipan", "Chiricahua"}, # not Navajo
    "rename": {
      "Chiricahua Apache": "Chiricahua",
      "Jicarilla Apache": "Jicarilla",
      "Lipan Apache": "Lipan",
      "Mescalero": "Chiricahua",
      "Western": "Western Apache",
    },
  },
  "Arabic": {
    "indent": lambda lang: lang.endswith(" Arabic") or lang in {"Hassaniya"}, # not Maltese or Nubi (creole)
    "add_lang": {"Algerian", "Andalusian", "Baharna", "Chadian", "Cypriot", "Dhofari", "Egyptian", "Gulf", "Hassaniya",
                 "Hijazi", "Iraqi", "Juba", "Levantine", "Libyan", "Mesopotamian", "Moroccan", "Najdi",
                 "North Levantine", "Omani", "South Levantine", "Sudanese", "Tunisian", "Yemeni"},
    "rename": {
      "Andalusi Arabic": "Andalusian Arabic",
      "Bahrani Arabic": "Baharna Arabic",
      "Hadrami Arabic": "Yemeni Arabic (Hadrami)",
      "Lebanese": "North Levantine Arabic (Lebanese)",
      "Lebanese Arabic": "North Levantine Arabic (Lebanese)",
      "Levantine, North": "North Levantine Arabic",
      "Levantine, South": "South Levantine Arabic",
      "Morocco": "Moroccan Arabic",
      "Palestine": "South Levantine Arabic (Palestinian)",
      "Palestinian": "South Levantine Arabic (Palestinian)",
      "Palestinian Arabic": "South Levantine Arabic (Palestinian)",
      "San'ani Arabic": "Yemeni Arabic (San'ani)",
      "San'ani Yemeni Arabic": "Yemeni Arabic (San'ani)",
      "Syrian": "North Levantine Arabic (Syrian)",
      "Syrian Arabic": "North Levantine Arabic (Syrian)",
      "Yemen": "Yemeni Arabic",
      "Standard": "Arabic",
    },
    "unindent": {"Arabic"},
  },
  "Aramaic": {
    "indent": lambda lang: lang.endswith(" Aramaic") or lang in {
      "Mlahsö", "Turoyo", "Classical Syriac", "Hulaulá", "Hértevin", "Koy Sanjaq Surat", "Lishana Deni",
      "Lishanid Noshan", "Lishán Didán", "Senaya", "Classical Mandaic", "Mandaic"},
    "rename": {
      "Assyrian Neo Aramaic": "Assyrian Neo-Aramaic",
      "Babylonian": "Jewish Babylonian Aramaic",
      "Jewish Babylonian": "Jewish Babylonian Aramaic",
      "Jewish Baylonian Aramaic": "Jewish Babylonian Aramaic",
      #"Palestinian": "Jewish Palestinian Aramaic",
      #"Palestinian Aramaic": "Jewish Palestinian Aramaic",
      "Syriac": "Classical Syriac",
      "Syriac, Classical": "Classical Syriac",
    },
  },
  "Armenian": {
    "add_lang": {"Classical", "Old"},
    "rename": {
      "Modern Armenian": "Armenian",
    },
    "unindent": {"Armenian", "Assyrian Neo-Aramaic", "Egyptian Arabic"},
    "recognize": {"Middle Armenian", "Western Armenian"},
  },
  "Azerbaijani": {
    "rename": {
      "Abjad": "Arabic",
      "Persic": "Arabic",
      "Perso-Arabic": "Arabic",
      "Roman": "Latin",
      "Northern": "North Azerbaijani",
      "Southern": "South Azerbaijani",
    },
    "recognize": {"Cyrillic"},
  },
  "Bai": {},
  "Cham": {}, # Note: Ai-Cham is unrelated
  "Chinese": {
    "indent": lambda lang: lang.endswith(" Chinese") or any(lang == x or lang.endswith(" " + x) for x in [
      "Cantonese", "Yue", "Dungan", "Gan", "Hakka", "Huizhou", "Jin", "Min", "Min Nan", "Wu",
      "Hangzhounese", "Ningbonese", "Shanghainese", "Suzhounese", "Wenzhounese", "Xiang",
      "Pinghua", "Waxiang", "Hokkien", "Hainanese", "Teochew", "Shaozhou Tuhua", "Sichuanese", "Taishanese",
      "Tangwang"]) or lang in {"Ci"}, # not Wutunhua, a Mandarin-Amdo-Bonan creole
    "rename": {
      "Madarin": "Mandarin",
      "Min Bei": "Northern Min",
      "Min Dong": "Eastern Min",
      # "Min Nan": "Hokkien", Min Nan handled specially because we rename the lang code as well
      "Min Zhong": "Central Min",
      "Puxian": "Puxian Min",
    }
  },
  "French": {
    # Note: By the time the 'indent' function is called, "Louisiana Creole French" will have been renamed to
    # "Louisiana Creole" due to the setting in top_level_rename so we don't have to worry about it getting indented.
    "add_lang": {"Canadian"},
    "rename": {
      "Canada": "Canadian French",
      "Modern": "French",
    },
    "unindent": {"French", "Louisiana Creole", "Louisiana Creole French"},
  },
  "Georgian": {},
  # FIXME: inconsistent nesting currently, issues with "Low German"
  "German": {
    # FIXME: Clean up
    "indent": lambda lang: (
      lang.endswith(" German") and not lang.endswith("Low German") and lang not in {"Pennsylvania German"} or
      lang in {"Kölsch"}
    ),
    "add_lang": {"Alemannic", "East Central"},
    "rename": {
      "Alemannic": "Alemannic German",
      "Alsace": "Alsatian Alemannic German",
      "Alsatian <small>(Low Alemannic German)</small>": "Alsatian Alemannic German",
      "Ancient": "Old High German",
      "Bavaria": "Bavarian",
      "Modern German": "German",
      "Silesian": "Silesian East Central German",
      "Silesian German": "Silesian East Central German",
    },
    "unindent": {"Luxembourgish", "German", "Plautdietsch", "Pennsylvania German", "Low German", "German Low German",
                 "Northern Kurdish"},
  },
  "Greek": {
    "indent": lambda lang: lang.endswith(" Greek") or lang in {
      "Kaliarda", "Katharevousa", "Yevanic", "Tsakonian", "Opuntian Locrian", "Ozolian Locrian"},
    "add_lang": {"Aeolic", "Ancient", "Arcadian", "Arcadocypriot", "Attic", "Boeotian", "Byzantine", "Cappadocian",
                 "Classical", "Cretan", "Cypriot", "Doric", "Epic", "Hellenistic", "Ionic", "Italiot", "Koine",
                 "Laconian", "Medieval", "Mycenaean", "Pamphylian", "Pontic", "Thessalian"},
    "rename": {
      "Mycenean Greek": "Mycenaean Greek",
      "Mycenean": "Mycenaean Greek",
      "Griko": "Italiot Greek",
      "Modern": "Greek",
      "Modern Greek": "Greek",
    },
    "unindent": {"Greek"},
  },
  "Indonesian": {
    "rename": indonesian_malay_rename_map,
    "recognize": indonesian_malay_recognize,
    "unindent": indonesian_malay_unindent,
  },
  "Irish": {
    "unindent": {"Central Kurdish"},
    "rename": {"Modern Irish": "Irish"},
    "unindent": {"Irish"},
    "recognize": {"Old Irish", "Middle Irish", "Primitive Irish"},
  },
  "Javanese": {
    "rename": indonesian_malay_rename_map,
    "recognize": lambda lang: (boolean_function_matches(indonesian_malay_recognize, lang) or
                               lang in {"Kaili", "Krama", "Ngoko"}),
    "unindent": indonesian_malay_unindent,
  },
  "Khanty": {},
  "Kurdish": {
    "indent": lambda lang: lang.endswith(" Kurdish") or lang in {"Laki", "Sorani", "Kurmanji"},
    "rename": {
      "Cnetral Kurdish": "Central Kurdish",
      "Laki Kurdish": "Laki",
      "Sorani": "Central Kurdish",
      "Kurmanji": "Northern Kurdish",
      "Norther Kurdish": "Northern Kurdish",
      "Northern": "Northern Kurdish",
    },
    "unindent": {"Gurani", "Zazaki"},
  },
  "Ladino": {
    "rename": {
      "Hebew": "Hebrew",
      "Hebrew alphabet": "Hebrew",
      "Hebrew script": "Hebrew",
      "Latin alphabet": "Latin",
      "Roman": "Latin",
    },
  },
  "Lawa": {},
  "Low German": {
    # FIXME: Make sure Middle Low German OK to indent; currrently only 14/47 indented.
    "indent": lambda lang: lang.endswith(" Low German") or lang in {"Dutch Low Saxon"},
    "add_lang": {"East Frisian"},
    "rename": {
      "Dutch Low German": "Dutch Low Saxon",
      "East Frisian Low Saxon": "East Frisian Low German",
      "German Low Saxon": "German Low German",
      "Mennonite Plautdietsch": "Plautdietsch",
      "Plauttdietsch": "Plautdietsch",
      "Plauttdietsch (Mennonite Low German)": "Plautdietsch",
    },
    "unindent": {"Plautdietsch"},
  },
  "Malay": {
    "indent": lambda lang: False,
    "rename": indonesian_malay_rename_map,
    "recognize": indonesian_malay_recognize,
    "unindent": indonesian_malay_unindent,
  },
  "Mari": {
    "indent": lambda lang: lang.endswith(" Mari") and lang not in {"Austronesian Mari", "Sepik Mari"},
    "add_lang": {"Eastern", "Western"},
    "unindent": {"Austronesian Mari", "Sepik Mari"},
  },
  "Mansi": {},
  "Mongolian": {
    "rename": {
      "Roman": "Latin",
      "Cyrilic": "Cyrillic",
      "Classic": "Classical Mongolian",
      "Classical": "Classical Mongolian",
      "Khamingan Mongolian": "Khamnigan Mongol",
    },
    "recognize": {"Mongolian"},
    "unindent": {"Khamnigan Mongol"},
  },
  "Nahuatl": {
    # FIXME: Make sure it's OK to move "Foo Nahuatl" under "Nahuatl"
    "add_lang": {"Central", "Central Huasteca", "Central Puebla", "Classical", "Coatepec", "Cosoleacaque",
                 "Eastern Durango", "Eastern Huasteca", "Guerrero", "Highland Puebla", "Huaxcaleca",# "Isthmus",
                 "Mecayapan", "Michoacán", "Morelos", "Northern Oaxaca", "Northern Puebla", "Ometepec", "Orizaba",
                 "Pajapan", "Santa María La Alta", "Sierrra Negra", "Southeastern Puebla", "Tabasco",
                 "Temascaltepec", "Tetelcingo", "Tlamacazapa", "Western Durango", "Western Huasteca",
                 "Zacatlán-Ahuacatlán-Tepetzintla"},
    "rename": {
      "Northern Peubla": "Northern Puebla Nahuatl",
    },
  },
  "Norwegian": {
    "indent": lambda lang: lang.startswith("Norwegian ") or lang in {"Bokmål", "Bokmal", "Nynorsk"},
    "rename": {
      "Norwegian Bokmål": "Bokmål",
      "Norwegian (Bokmål)": "Bokmål",
      "Norwegian (bokmål)": "Bokmål",
      "Norwegian Bokmal": "Bokmål",
      "Bokmal": "Bokmål",
      "Norwegian Nynorsk": "Nynorsk",
      "Norwegian (Nynorsk)": "Nynorsk",
      "Norwegian (nynorsk)": "Nynorsk",
      "Nynorak": "Nynorsk",
      "Nynorskl": "Nynorsk",
    },
    "unindent": {"Norwegian"},
  },
  "Ohlone": {},
  "Old Church Slavonic": {
    "rename": {
      "Cytillic": "Cyrillic",
      "Roman": "Latin",
    },
    "recognize": {"Glagolitic"},
  },
  "Persian": {
      # FIXME: Make sure Middle Persian/Old Persian OK to indent; currrently only 27/286 Middle Persian and 16/105
      # Old Persian indented.
    "indent": lambda lang: lang.endswith(" Persian") or lang in {"Dari", "Hazaragi"},
    "add_lang": {"Classical", "Iranian"},
    "rename": {
      "Dari Persian": "Dari",
      "Iranian Pesian": "Iranian Persian",
    },
    "unindent": {"Tajik"},
  },
  "Portuguese": {
    # FIXME: Make sure entries in this section are kosher
    "add_lang": {"Brazilian", "European"},
    "rename": {
      "Brazil": "Brazilian Portuguese",
      "European": "European Portuguese",
      "Portugal": "European Portuguese",
      "Iberian": "European Portuguese",
      "{{qualifier|Brazil}}": "Brazilian Portuguese",
      "{{qualifier|Portugal}}": "European Portuguese",
    },
  },
  "Punjabi": {
    # FIXME: Make sure it's OK to move "Foo Punjabi" under "Punjabi"; only 3/382 occurrences of Western Panjabi indented
    "indent": lambda lang: lang.endswith(" Punjabi") or lang.endswith(" Panjabi"),
    "add_lang": {"Eastern", "Western"},
    "rename": {
      "Eastern Panjabi": "Eastern Punjabi",
      "Western Panjabi": "Western Punjabi",
      "shahmukhi": "Shahmukhi",
      "Gurmikhi": "Gurmukhi",
    },
    "unindent": {"Kurmanji"},
  },
  "Roglai": {},
  "Romani": {},
  "Sama": {},
  "Sami": {
    "add_lang": {"Akkala", "Inari", "Kemi", "Kildin", "Lule", "Northern", "Pite", "Skolt", "Southern", "Ter", "Ume"},
    "rename": {
      "Kola": "Kildin Sami",
    },
    "unindent": {"Bokmål"},
  },
  "Serbo-Croatian": {
    "rename": {
      "Cyrilli": "Cyrillic",
      "Cyrillic script": "Cyrillic",
      "Cyrillic spelling": "Cyrillic",
      "Latin script": "Latin",
      "Latın": "Latin",
      "Roman": "Latin",
      "Roman script": "Latin",
      "Roman spelling": "Latin",
    }
  },
  "Sorbian": {
    "add_lang": {"Lower", "Upper"},
    "rename": {
      "High Sorbian": "Upper Sorbian",
      "Low Sorbian": "Lower Sorbian",
    },
  },
  "Spanish": {},
  "Sundanese": {
    "rename": indonesian_malay_rename_map,
    "recognize": indonesian_malay_recognize,
    "unindent": indonesian_malay_unindent,
  },
  "Tujia": {},
  "Uzbek": {
    "rename": {
      "Roman": "Latin",
    },
    "recognize": {"Arabic", "Cyrillic"},
  },
  "Welsh": {},
  "Yokuts": {},
}

top_level_rename = {
  "Louisiana Creole French": "Louisiana Creole",
}

new_language_groups = {}
for group, group_props in language_groups.items():
  rename = group_props.get("rename", {})
  group_props["rename_right_side"] = set(rename.values())
  new_language_groups[group] = group_props
language_groups = new_language_groups

# Keys are languages. The value for a key is a dictionary where keys are the language header the given language is
# indented under, or "" for a non-indented language.
lang_counts = defaultdict(lambda: defaultdict(int))
# Keys are languages. Values are total counts of appearances, indented or not.
total_lang_counts = defaultdict(int)
# Keys are non-indented languages ("headers"). The value for a key is a dictionary where keys are indented languages
# and values are counts.
header_counts = defaultdict(lambda: defaultdict(int))
# Keys are headers. Values are total counts of cases where there's at least one language indented.
total_header_counts = defaultdict(int)
# Keys are headers. The value for a key is a dictionary where keys are the unrecognized indented lang and values are
# counts.
unrecognized_indented_lang_counts = defaultdict(lambda: defaultdict(int))
# Keys are headers. Values are total counts of unrecognized indented languages.
header_with_unrecognized_lang_counts = defaultdict(int)

def process_text_on_page(index, pagename, text):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagename, txt))
  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagename, txt))

  notes = []

  origtext = text
  new_lines = []
  lines = text.split("\n")
  in_translation_section = False
  langgroup_header = None
  langgroup_header_lineind = None
  translation_lines = None

  def rename_indented_lang(indented_lang, prev_lang):
    group_props = language_groups[prev_lang]
    new_indented_lang = None
    add_lang = group_props.get("add_lang", set())
    rename_map = group_props.get("rename", {})
    if boolean_function_matches(add_lang, indented_lang):
      new_indented_lang = indented_lang + " " + prev_lang
    elif indented_lang in rename_map:
      new_indented_lang = rename_map[indented_lang]
    if new_indented_lang:
      indented_lang = new_indented_lang
    return indented_lang

  # Check if a top-level language needs to be renamed and/or indented. Returns two values: The group to indent under
  # (or None if the language should stay at top level) and the name to use for the language. This function takes care
  # of outputting a message, adding to notes[] and setting need_langgroup_header[] if necessary.
  def need_to_indent_lang(lang, lineind):
    # First check if we need to rename the top-level line (e.g. because it's using an outdated name).
    if lang in top_level_rename:
      new_lang = top_level_rename[lang]
      pagemsg("Renaming top-level variety %s to %s" % (lang, new_lang))
      notes.append("rename top-level variety %s to %s" % (lang, new_lang))
      lang = new_lang
    # Now check if we need to indent (and possibly rename) the language.
    for group, group_props in language_groups.items():
      indentfun = group_props.get("indent", lambda lang: default_indentfun(group, lang))
      if boolean_function_matches(indentfun, lang):
        new_indented_lang = rename_indented_lang(lang, group)
        if new_indented_lang != lang:
          pagemsg("Indenting %s variety %s and renaming to %s" % (group, lang, new_indented_lang))
          notes.append("indent %s variety %s and rename to %s" % (group, lang, new_indented_lang))
          lang = new_indented_lang
        else:
          pagemsg("Indenting %s variety %s" % (group, lang))
          notes.append("indent %s variety %s" % (group, lang))
        # We're indenting an unindented lang under a header. If the header doesn't already exist, it needs to be added.
        # We may not know whether to add the header till after we've processed the whole translation section; at that
        # point, if necessary, we add the header to the end. In all cases, we then sort, which puts the header in the
        # right location.
        if group not in langgroup_header:
          langgroup_header[group] = ""
          langgroup_header_lineind[group] = lineind
        return group, lang
    return None, lang

  def add_header_line(lang, after_lang, lineind):
    line = "* " + lang + after_lang
    if lang in language_groups:
      after_lang = after_lang[1:].strip() # remove initial colon and strip whitespace
      if after_lang:
        after_lang = " " + after_lang
      if lang in langgroup_header:
        if not after_lang:
          pagemsg("Already saw header for '%s' with remainder '%s', but new header remainder is empty; not adding" % (
            lang, langgroup_header[lang]))
        elif langgroup_header[lang]:
          pagemsg("WARNING: Already saw header for '%s' with non-empty remainder '%s', and new remainder '%s' is also non-empty; duplicate lines will result" % (
            lang, langgroup_header[lang], after_lang))
          translation_lines.append((lang, [], lineind, line, True))
        else:
          pagemsg("Already saw header for '%s' with empty remainder, and new header remainder '%s' is non-empty; replacing" % (
            lang, after_lang))
          langgroup_header[lang] = after_lang
          langgroup_header_lineind[lang] = lineind
      else:
        langgroup_header[lang] = after_lang
        langgroup_header_lineind[lang] = lineind
    else:
      translation_lines.append((lang, [], lineind, line, True))

  for lineind, line in enumerate(lines):
    origline = line
    if re.search(r"^\{\{(trans-top|checktrans-top|trans-top-see|trans-top-also)[|}]", line):
      if in_translation_section:
        pagemsg("WARNING: Nested translation sections, skipping page, nested opening line follows: %s" % line)
        return
      in_translation_section = True
      langgroup_header = {}
      langgroup_header_lineind = {}
      saw_opening_html_comment = False
      opening_trans_line = line
      opening_lineind = lineind
      prev_lang = ""
      prev_indented_langs = []
      # This is a list of a tuple of (top_level_lang, indented_langs, lineind, line, counts_for_sorting), serving as a
      # sort key, where
      # * `top_level_lang` is the top-level header under which an indented lang is found, or the lang itself if
      #   top-level;
      # * `indented_langs` is a list of nested langs, up to the lang of the line in question;
      # * `lineind` is the line index;
      # * `line` is the new line;
      # * `counts_for_sorting` is a boolean, whether to consider this line when checking to see whether sorting caused
      #   anything to move; this check is only to determine whether to add a changelog note indicating that we sorted
      #   out-of-order lines, not for the actual sort, which uses all lines.
      translation_lines = []
      orig_translation_lines = []
      new_lines.append(line)
      is_indented_under_header = False
    elif re.search(r"^\}* *\{\{trans-bottom", line): # allow for multitrans closing braces before {{trans-bottom}}
      if not in_translation_section:
        pagemsg("WARNING: Found {{trans-bottom}} not in a translation section")
      else:
        if saw_opening_html_comment:
          pagemsg("WARNING: Saw full-line HTML comment in section beginning %s, preserving unchanged" %
                  opening_trans_line)
          new_lines.extend(orig_translation_lines)
        else:
          for lang in langgroup_header:
            translation_lines.append((
              lang, [], langgroup_header_lineind[lang], "* %s:%s" % (lang, langgroup_header[lang]), False))
          # Because we add the headers at the end, and sort them back into place, the sorted lines will almost always
          # differ from the original lines. To get a better sense of whether we actually reordered any lines, sort
          # before adding the new headers and then sort for real after adding the headers.
          translation_lines_for_sorting = [
            (blib.langname_key(lang), [blib.langname_key(x) for x in indented_lang], lineind, line)
             for lang, indented_lang, lineind, line, counts_for_sorting in translation_lines
             if counts_for_sorting
          ]
          new_translation_lines_for_sorting = sorted(translation_lines_for_sorting)
          if translation_lines_for_sorting != new_translation_lines_for_sorting:
            notes.append("sort translation lines under %s" %
                         re.sub(r"\|.*?\}", "}", re.sub(r"\}\}.*", "}}", opening_trans_line)))
          translation_lines = [
            (blib.langname_key(lang), [blib.langname_key(x) for x in indented_lang], lineind, line)
            for lang, indented_lang, lineind, line, counts_for_sorting in translation_lines
          ]
          translation_lines = sorted(translation_lines)
          for lang, indented_lang, lineind, transline in translation_lines:
            new_lines.append(transline)
      new_lines.append(line)
      in_translation_section = False
    elif in_translation_section:
      orig_translation_lines.append(origline)
      if saw_opening_html_comment:
        pass # no further processing
      elif line.startswith("{{multitrans|"):
        translation_lines.append(("", [], lineind, line, True))
      elif line.startswith("}}") or line.startswith("<!-- close multitrans") or line.startswith("<!-- close {{multitrans"):
        translation_lines.append(("\U0010FFFF", [], lineind, line, True))
      else:
        newline = line.replace("\u00A0", " ")
        if newline != line:
          line = newline
          notes.append("replace NBSP with regular space in translation section")
        if not line.strip():
          notes.append("skip blank line in translation section")
          continue
        def replace_ttbc(m):
          langcode = m.group(1)
          if langcode in blib.languages_byCode:
            langname = blib.languages_byCode[langcode]["canonicalName"]
            notes.append("replace {{ttbc|%s}} with %s" % (langcode, langname))
            return langname
          pagemsg("WARNING: Unrecognized langcode %s in {{ttbc}}: %s" % (langcode, line))
          return m.group(0)
        line = re.sub(r"\{\{ttbc\|([^{}|=]*)\}\}", replace_ttbc, line)
        langname_regex = r"(?:'Are'are|\w[^:;{}]*?)"
        m = re.search(r"^([:*]+ *)(%s)(;?)((?: *\{\{.*)?)$" % langname_regex, line)
        if m:
          init, potential_lang, semicolon, rest = m.groups()
          if potential_lang in blib.languages_byCanonicalName or potential_lang in blib.etym_languages_byCanonicalName:
            if semicolon:
              pagemsg("Replace semicolon with colon after language %s: %s" % (potential_lang, line))
            else:
              pagemsg("Adding missing colon after language %s: %s" % (potential_lang, line))
            line = init + potential_lang + ":" + rest
            if semicolon:
              notes.append("replace semicolon with colon after language name '%s' in translation section" % (potential_lang))
            else:
              notes.append("add missing colon after language name '%s' in translation section" % (potential_lang))
        m = re.search(r"^([:*]\*)( *%s: *\{\{.*)$" % langname_regex, line)
        if m:
          init_star, rest = m.groups()
          line = "*:" + rest
          notes.append("replace %s with *: in translation section" % init_star)
        m = re.search(r"^(\* *:? *)(%s) *(:.*)$" % langname_regex, line)
        if m:
          init_star, lang, rest = m.groups()
          if ":" in init_star:
            init_star = "*: "
          else:
            init_star = "* "
          newline = init_star + lang + rest
          if newline != line:
            line = newline
            notes.append("remove extraneous spaces in translation section")
        m = re.search(r"^(\* *(:+) *)([^:]+)(:.*)$", line)
        if m:
          # We're processing an indented line.
          init_star, colons, indented_lang, rest = m.groups()
          potential_prev_indented_langs = prev_indented_langs[:]
          new_indent = len(colons)
          old_indent = len(potential_prev_indented_langs)
          if new_indent > old_indent:
            if new_indent - old_indent > 1:
              pagemsg("WARNING: Saw greater than one increase in nesting, from %s to %s: lineind %s, line: %s" % (
                old_indent, new_indent, lineind, line))
            while new_indent - old_indent:
              potential_prev_indented_langs.append("")
              old_indent += 1
          elif new_indent < old_indent:
            potential_prev_indented_langs = potential_prev_indented_langs[:new_indent]
          potential_prev_indented_langs[-1] = indented_lang
          lang_counts[indented_lang][prev_lang] += 1
          total_lang_counts[indented_lang] += 1
          header_counts[prev_lang][indented_lang] += 1
          if not is_indented_under_header:
            total_header_counts[prev_lang] += 1
            is_indented_under_header = True
          if prev_lang in language_groups:
            group_props = language_groups[prev_lang]
            add_lang = group_props.get("add_lang", set())
            rename_map = group_props.get("rename", {})
            new_indented_lang = rename_indented_lang(indented_lang, prev_lang)
            if new_indented_lang != indented_lang:
              pagemsg("Renaming %s variety %s to %s" % (prev_lang, indented_lang, new_indented_lang))
              notes.append("rename %s variety %s to %s" % (prev_lang, indented_lang, new_indented_lang))
              indented_lang = new_indented_lang
              line = "%s%s%s" % (init_star, indented_lang, rest)
            if boolean_function_matches(group_props.get("unindent", set()), indented_lang):
              pagemsg("Unindenting translation for %s under %s" % (indented_lang, prev_lang))
              notes.append("unindent translation for %s under %s" % (indented_lang, prev_lang))
              # don't set prev_indented_langs or prev_lang; we are moving an indented line to top level but if the
              # next line is unrecognized, it should stay where it is and not move to top level.
              #
              # We may need to unindent and then re-indent under a different header, possibly renaming the language in
              # the process (e.g. in the 2026-01-01 dump there are 6 occurrences of Kurmanji indented under Punjabi;
              # they need to be unindented, reindented under Kurdish and renamed to Northern Kurdish). The function
              # need_to_indent_lang() takes care of outputting a message and adding to notes[].
              indent_under_group, new_lang_name = need_to_indent_lang(indented_lang, lineind)
              indented_lang = new_lang_name
              if indent_under_group:
                line = "*: " + indented_lang + rest
                translation_lines.append((indent_under_group, [indented_lang], lineind, line, False))
              else:
                # We may be unindenting "Modern Greek", renamed to just "Greek"; it needs to become a header line,
                # and be handled as such.
                add_header_line(indented_lang, rest, lineind)
            else:
              if args.rename_min and prev_lang == "Chinese" and indented_lang == "Min Nan":
                pagemsg("Replacing 'Min Nan' translation with Hokkien and changing code nan -> nan-hbl")
                notes.append("replace 'Min Nan' translation with Hokkien and change code nan -> nan-hbl")
                indented_lang = "Hokkien"
                parsed = blib.parse_text(rest)
                changed = False
                for t in parsed.filter_templates():
                  tn = tname(t)
                  if tn in blib.translation_templates:
                    langcode = getparam(t, "1").strip()
                    if langcode == "nan":
                      t.add("1", "nan-hbl")
                      changed = True
                if changed:
                  rest = str(parsed)
                line = "%s%s%s" % (init_star, indented_lang, rest)
              else:
                indentfun = group_props.get("indent", lambda lang: default_indentfun(prev_lang, lang))
                recognizefun = group_props.get("recognize", set())
                recognized = (indented_lang in group_props["rename_right_side"] or
                              boolean_function_matches(indentfun, indented_lang) or
                              boolean_function_matches(recognizefun, indented_lang))
                if not recognized and indented_lang.endswith(" " + prev_lang):
                  recognized = boolean_function_matches(add_lang, indented_lang[:-len(prev_lang) - 1])
                if not recognized:
                  pagemsg("WARNING: Unrecognized indented lang %s under %s" % (indented_lang, prev_lang))
                  unrecognized_indented_lang_counts[prev_lang][indented_lang] += 1
                  header_with_unrecognized_lang_counts[prev_lang] += 1
              prev_indented_langs = potential_prev_indented_langs
              translation_lines.append((prev_lang, prev_indented_langs, lineind, line, True))
          else:
            prev_indented_langs = potential_prev_indented_langs
            translation_lines.append((prev_lang, prev_indented_langs, lineind, line, True))
        else:
          m = re.search(r"^\* *((%s)(:.*))$" % langname_regex, line)
          if not m:
            pagemsg("WARNING: Unrecognized line in translation section: %s" % line)
            if re.search(r"^\s*<!--", line) and lineind > opening_lineind + 1:
              saw_opening_html_comment = True
            translation_lines.append((prev_lang, prev_indented_langs, lineind, line, True))
          else:
            # We're processing an unindented (top-level) line.
            rest, lang, after_lang = m.groups()
            lang_counts[lang][""] += 1
            total_lang_counts[lang] += 1
            is_indented_under_header = False
            # First check if we need to rename the top-level line (e.g. because it's using an outdated name).
            if lang in top_level_rename:
              new_lang = top_level_rename[lang]
              pagemsg("Renaming top-level variety %s to %s" % (lang, new_lang))
              notes.append("rename top-level variety %s to %s" % (lang, new_lang))
              lang = new_lang
              line = "* " + lang + after_lang
            # Then check if we need to indent the language (using its new name if renamed).
            indent_under_group, new_lang_name = need_to_indent_lang(lang, lineind)
            if indent_under_group:
              lang = new_lang_name
              line = "*: " + lang + after_lang
              # Unrecognized lines directly a top-level line that we indent and move elsewhere should probably stay
              # where they are and not follow the moved line. So, don't change prev_lang/prev_indented_langs, so they
              # go after the preceding line.
              translation_lines.append((indent_under_group, [lang], lineind, line, False))
            else:
              if new_lang_name != lang:
                lang = new_lang_name
                line = "* " + lang + after_lang
              prev_lang = lang
              prev_indented_langs = []
              # We handle the header lines of known language groups differently, since we may be indenting lines under
              # a header that may not (yet?) exist, or moving an indented line like "Modern Greek" to be the header line
              # ("Greek"). Specifically, rather than adding the line as we encounter it, we keep track of the header
              # line "remainder" (everything after the colon, if anything) and corresponding line index, and add all the
              # lines at the end just before sorting.
              add_header_line(lang, after_lang, lineind)
    else:
      new_lines.append(line)

  if in_translation_section:
    pagemsg("WARNING: Page ended in a translation section, something wrong, skipping")
    return

  text = "\n".join(new_lines)

  if text != origtext and not notes:
    notes.append("sort translation lines")
    pagemsg("WARNING: Adding default changelog 'sort translation lines'")
  return text, notes

parser = blib.create_argparser(
  "Sort and reformat translations, correct misc translation table issues", include_pagefile=True, include_stdin=True)
parser.add_argument("--rename-min", action="store_true", help="Rename Min Nan to Hokkien and change nan to nan-hbl")
parser.add_argument("--analyze", action="store_true", help="Analyze existing indented and non-indented language use and output a table at the end.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

if args.analyze:
  def output_table(key):
    msg("%-40s %5s: %s" % ("Language", "Count", "Count-by-header"))
    msg("---------------------------------------------------------")
    for lang, count in sorted(list(total_lang_counts.items()), key=key):
      by_header = "; ".join("%s (%s)" % (header or "unindented", headercount)
                            for header, headercount in sorted(list(lang_counts[lang].items()), key=lambda x: -x[1]))
      msg("%-40s %5s: %s" % (lang, count, by_header))

  msg("Sorted by total count:")
  msg("----------------------")
  output_table(lambda x: -x[1])
  msg("")
  msg("Sorted by language, from the end:")
  msg("---------------------------------")
  output_table(lambda x: (x[0][::-1], -x[1]))
  msg("")
  msg("By header:")
  msg("----------")
  msg("%-50s %8s %s" % ("Header", "Indented", "Total"))
  msg("------------------------------------------------------------------")
  for header, indented_dict in sorted(list(header_counts.items()), key=lambda x: -total_header_counts[x[0]]):
    msg("%-50s %8s %5s" % (header, total_header_counts[header], total_lang_counts[header]))
    for lang, langcount in sorted(list(indented_dict.items()), key=lambda x: x[0]):
      msg("%-50s %8s %5s" % ("  * %s" % (lang), langcount, total_lang_counts[lang]))
  msg("")
  msg("Unrecognized indented languages:")
  msg("--------------------------------")
  msg("%-40s %-40s %5s" % ("Header", "Indented", "Total"))
  msg("-" * 87)
  for header, indented_dict in sorted(list(unrecognized_indented_lang_counts.items()),
                                      key=lambda x: -header_with_unrecognized_lang_counts[x[0]]):
    first = True
    for lang, langcount in sorted(list(indented_dict.items()), key=lambda x: x[0]):
      if first:
        msg("%-40s %-40s %5s" % (header, lang, langcount))
        first = False
      else:
        msg("%-40s %-40s %5s" % ("", lang, langcount))
