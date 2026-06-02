#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname

lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()


def process_text_on_page(p):
    seen_cats = set()
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in blib.translation_templates:
            lang = getparam(t, "1").strip()
            if lang in lang_data.languages_by_code:
                langname = lang_data.languages_by_code[lang]["canonicalName"]
            elif lang in etym_lang_data.etym_languages_by_code:
                langname = etym_lang_data.etym_languages_by_code[lang]["canonicalName"]
            else:
                p.msg("WARNING: Unrecognized lang code %s" % lang)
                continue
            seen_cats.add("Category:Terms with %s translations" % langname)
    for cat in sorted(list(seen_cats)):
        msg(cat)


parser = blib.create_argparser(
    "Generate 'Terms with LANG translations' categories", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
