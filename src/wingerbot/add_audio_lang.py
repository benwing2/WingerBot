#!/usr/bin/env python3

# Fix up raw verb forms when possible, canonicalize existing 'conjugation of'
# to 'inflection of'

from wingerbot import blib
from wingerbot.blib import getparam, tname

langs_to_codes = {}


def process_text_on_page(p):
    p.msg("Processing")

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections

    for j, lang in secs.lang_list:
        parsed = blib.parse_text(sections[j])
        for t in parsed.filter_templates():
            if tname(t) == "audio" and not getparam(t, "lang"):
                origt = str(t)
                if lang in langs_to_codes:
                    langcode = langs_to_codes[lang]
                else:
                    langcode = p.expand_text("{{#invoke:languages/templates|getByCanonicalName|%s|getCode}}" % lang)
                    if not langcode:
                        p.msg("WARNING: Unable to find code for lang %s" % lang)
                        continue
                    langs_to_codes[lang] = langcode
                t.add("lang", langcode)
                newt = str(t)
                if origt != newt:
                    p.msg("Replaced %s with %s" % (origt, newt))
        sections[j] = str(parsed)

    return "".join(sections), "add lang code to audio templates"


parser = blib.create_argparser("Add lang code to audio templates")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Language code missing/audio"],
)
