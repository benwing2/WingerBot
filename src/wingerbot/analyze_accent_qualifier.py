#!/usr/bin/env python3

import pywikibot, re, sys, argparse, unicodedata

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, errmsg, site, tname
from collections import defaultdict
import json

accent_qualifier_data = {"aliases": {}, "labels": {}}
total_qualifiers = defaultdict(int)
qualifiers_by_lang = defaultdict(lambda: defaultdict(int))
pages_for_qualifiers_by_lang = defaultdict(lambda: defaultdict(set))
too_many_pages_for_qualifiers_by_lang = defaultdict(lambda: defaultdict(bool))
accent_labels_seen = defaultdict(int)
accent_aliases_seen = defaultdict(int)
labels_aliases = defaultdict(set)
labels_langs = defaultdict(set)

accent_templates_have_lang = False

qualifiers_to_enumerate = {
    ("RP", "Translingual"),  # [DONE]
    ("US", "Translingual"),  # [DONE]
    ("US", "Italian"),  # [DONE]
    ("US", "German"),  # [DONE]
    ("UK", "Italian"),  # switch lang to en [DONE]
    ("UK", "German"),  # switch lang to en [DONE]
    ("Canada", "French"),  # should be OK now that we've switched to labels
    ("New York", "English"),  # rename to NYC [DONE]
    ("ps-Kandahar", "Pashto"),  # rename to Kandahar [DONE]
    ("Baku", "Malay"),  # rename to Bahasa Baku? [DONE]
    ("horse-hoarse", "English"),
    ("wine/whine", "English"),
    ("wine-whine", "English"),
}

lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()


def process_text_on_page(p):
    text = p.text
    if not re.search(r"\{\{ *(IPA|a(ccent)?) *\|", text):
        return
    secs = blib.split_text_into_sections(text, p.msg)
    sections = secs.sections

    def record_qual_and_lang(qual, lang):
        total_qualifiers[qual] += 1
        qualifiers_by_lang[qual][lang] += 1
        if not too_many_pages_for_qualifiers_by_lang[qual][lang]:
            pageset = pages_for_qualifiers_by_lang[qual][lang]
            if p.title not in pageset:
                if len(pageset) < 10 or (qual, lang) in qualifiers_to_enumerate:
                    pageset.add(p.title)
                else:
                    too_many_pages_for_qualifiers_by_lang[qual][lang] = True

    for j, lang in secs.lang_list:
        sectext = sections[j]
        if not re.search(r"\{\{ *(IPA|a(ccent)?) *\|", sectext):
            continue
        parsed = blib.parse_text(sectext)
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in ["a", "accent"]:
                params = blib.fetch_param_chain(t, "2" if accent_templates_have_lang else "1")
                for paramind, param in enumerate(params):
                    assert param is not None  # all holes closed in fetch_param_chain
                    param = param.strip()
                    if paramind == 0:
                        pseudo_langname = None
                        pseudo_langtype = None
                        if param in lang_data.languages_by_code:
                            pseudo_langname = lang_data.languages_by_code[param]["canonicalName"]
                            pseudo_langtype = "full"
                        elif param in etym_lang_data.etym_languages_by_code:
                            pseudo_langname = etym_lang_data.etym_languages_by_code[param]["canonicalName"]
                            pseudo_langtype = "etym-only"
                        if pseudo_langtype:
                            pass
                            # if len(params) == 1:
                            #  p.msg("WARNING: Saw qualifier '%s' same as language code for %s language '%s' in lang section '%s' but only one qualifier: %s" % (
                            #    param, pseudo_langtype, pseudo_langname, lang, str(t)))
                            # else:
                            #  p.msg("WARNING: Saw qualifier '%s' same as language code for %s language '%s' in lang section '%s' and multiple qualifiers: %s" % (
                            #    param, pseudo_langtype, pseudo_langname, lang, str(t)))
                    record_qual_and_lang(param, lang)
            if tn == "IPA":
                pass


parser = blib.create_argparser(
    "Analyze usage of qualifiers in {{a}}/{{accent}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def read_aliases():
    global accent_qualifier_data
    # accent_qualifier_data = json.loads(expand_text("{{#invoke:accent qualifier|output_data_module}}"))


read_aliases()

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

msg("%-50s %5s: %s" % ("Qualifier", "Count", "Count-by-lang"))
msg("----------------------------------------------------")
for qualifier, count in sorted(list(total_qualifiers.items()), key=lambda x: -x[1]):
    qualifier_alias_label = None
    if qualifier in accent_qualifier_data["aliases"]:
        qualifier_alias_label = accent_qualifier_data["aliases"][qualifier]
        rec = "-> %s" % qualifier_alias_label
        accent_aliases_seen[qualifier] += 1
    elif qualifier in accent_qualifier_data["labels"]:
        rec = "label"
        accent_labels_seen[qualifier] += 1
    else:
        rec = "unknown"

    def get_langcount_and_pages(lang, langcount):
        labels_langs[qualifier_alias_label or qualifier].add(lang)
        if too_many_pages_for_qualifiers_by_lang[qualifier][lang]:
            return str(langcount)
        else:
            return "%s: %s" % (langcount, ",".join(sorted(list(pages_for_qualifiers_by_lang[qualifier][lang]))))

    by_lang = "; ".join(
        "%s (%s)" % (lang, get_langcount_and_pages(lang, langcount))
        for lang, langcount in sorted(list(qualifiers_by_lang[qualifier].items()), key=lambda x: -x[1])
    )

    msg("%-50s (%s) %5s: %s" % (qualifier, rec, count, by_lang))

for alias, label in accent_qualifier_data["aliases"].items():
    labels_aliases[label].add(alias)
    if label not in accent_qualifier_data["labels"]:
        msg("-- WARNING: Saw alias '%s' of nonexistent label '%s'" % (alias, label))

for label, labelobj in sorted(list(accent_qualifier_data["labels"].items()), key=lambda x: x[0].lower()):
    display = labelobj.get("display", None)
    link = labelobj.get("link", None)
    if link is None:
        actual_display = display
    else:
        actual_display = display or link
    if actual_display is None:
        msg("-- WARNING: Neither link= or display= specified")
    langs = labels_langs[label]
    langcodes = set()
    for lang in langs:
        if lang not in lang_data.languages_by_canonical_name:
            msg("-- WARNING: Can't convert language '%s' to language code" % lang)
        else:
            langcode = lang_data.languages_by_canonical_name[lang]["code"]
            langcodes.add(langcode)
    aliases = labels_aliases[label]
    msg('labels["%s"] = {' % label)
    if aliases:
        msg("\taliases = {%s}," % ", ".join('"%s"' % alias for alias in sorted(list(aliases))))
    msg("\tlangs = {%s}," % ", ".join('"%s"' % langcode for langcode in sorted(list(langcodes))))
    if link == label:
        msg("\tWikipedia = true,")
    elif link:
        msg('\tWikipedia = "%s",' % link)
    if actual_display is None:
        msg("\tdisplay = false,")
    elif actual_display != label:
        msg('\tdisplay = "%s",' % actual_display)
    msg("}")
    msg("")
