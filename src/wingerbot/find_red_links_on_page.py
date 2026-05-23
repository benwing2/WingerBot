#!/usr/bin/env python3

# Find redlinks (non-existent pages) and yellow links (non-existent language section)
# on a set of pages.

import unicodedata
import pywikibot, re, sys

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, msg, site, tname


punc_chars = "".join("\\" + chr(i) for i in range(sys.maxunicode) if unicodedata.category(chr(i)).startswith("P"))


# WARNING: May not work any more.
def fast_remove_diacritics(text, langcode):
    if langcode not in lang_utils.languages_by_code:
        return text
    if "entryNamePatterns" in lang_utils.languages_by_code[langcode]:
        for entry in lang_utils.languages_by_code[langcode]["entryNamePatterns"]:
            from_ = entry["from"]
            from_ = from_.replace("%p", "[" + punc_chars + "]")
            to_ = entry["to"]
            to_ = re.sub("%([0-9]+)", r"\\\1", to_)
            text = re.sub(from_, to_, text)
    if "entryNameRemoveDiacritics" in lang_utils.languages_by_code[langcode]:
        diacritics_to_remove = lang_utils.languages_by_code[langcode]["entryNameRemoveDiacritics"]
        text = unicodedata.normalize(
            "NFC", re.sub("[" + diacritics_to_remove + "]", "", unicodedata.normalize("NFD", text))
        )
    return text


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def expand_text(tempcall):
        return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

    def remove_diacritics(text, langcode):
        return expand_text("{{#invoke:languages/templates|getByCode|%s|stripDiacritics|%s}}" % (langcode, text))

    def check_one_link(langname, pagenm, term=None):
        if not pagenm:
            outtext = "null link specified"
        else:
            if pagenm.startswith("*"):
                pagenm = "Reconstruction:%s/%s" % (langname, pagenm[1:])
            page = pywikibot.Page(site, pagenm)
            if blib.safe_page_exists(page, pagemsg):
                text = str(page.text)
                if re.search("#redirect", text, re.I):
                    outtext = "exists as redirect"
                else:
                    sections, sections_by_lang, section_langs = blib.split_text_into_sections(text, pagemsg)
                    if langname in sections_by_lang:
                        outtext = "exists in %s" % langname
                    else:
                        existing_langs = [lang for secno, lang in section_langs]
                        outtext = "exists in other languages %s" % ", ".join(existing_langs)
            else:
                outtext = "does not exist"
        term = term or pagenm
        if term == pagenm:
            pagemsg("%s [[%s]] %s" % (langname, pagenm, outtext))
        else:
            pagemsg("%s [[%s|%s]] %s" % (langname, pagenm, term, outtext))

    def check_text(text):
        if args.check_raw_links:
            for m in re.finditer(r"\[\[(.*?)\]\]", text):
                pagenm = m.group(1)
                check_one_link(args.langname, pagenm)
        if templates:
            parsed = blib.parse_text(text)
            for t in parsed.filter_templates():
                if tname(t) in templates:
                    lang = getparam(t, "1")
                    if lang not in lang_utils.languages_by_code:
                        pagemsg("WARNING: Unrecognized language code %s" % lang)
                        continue
                    langname = lang_utils.languages_by_code[lang]["canonicalName"]
                    term = getparam(t, "2")
                    pagenm = remove_diacritics(term, lang)
                    if not pagenm:
                        continue
                    check_one_link(langname, pagenm, term)

    if args.check_only_defns:
        lines = text.split("\n")
        for line in lines:
            if re.search("^#+[^*:]", line):
                check_text(line)
    else:
        check_text(text)


parser = blib.create_argparser("Find red/yellow links", include_pagefile=True, include_stdin=True)
parser.add_argument("--templates", help="Comma-separated list of templates to check")
parser.add_argument("--check-raw-links", help="If true, check raw links", action="store_true")
parser.add_argument("--check-only-defns", help="If true, check only defn lines", action="store_true")
parser.add_argument("--langname", help="Language name for raw links")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.check_raw_links and not args.langname:
    raise ValueError("--langname must be specified if --check-raw-links specified")
if args.templates:
    templates = args.templates.split(",")
    lang_utils.get_all_lang_data()
else:
    templates = []

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True)
