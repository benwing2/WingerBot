#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, tname

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    notes = []

    def do_templatize(subsectext, langname, subsectitle):
        if not subsectitle.startswith("Etymology"):
            return subsectext
        if langname not in lang_data.languages_by_canonical_name:
            p.msg("WARNING: Unknown language %s" % langname)
            return subsectext
        else:
            langcode = lang_data.languages_by_canonical_name[langname]["code"]

        def replace_unknown_uncertain(m, template):
            newtemp = "{{%s|%s}}" % (template, langcode)
            notes.append("replace '%s' with %s" % (m.group(2), newtemp))
            return m.group(1) + newtemp

        def generate_regex_template(cap, lc):
            return (
                r"((?:\{\{.*\}\}\n)*)(%s +(etymology|origin)|%s|(Etymology|Origin) +%s|Of +%s +(etymology|origin))"
                % (cap, cap, lc, lc)
            )

        subsectext = re.sub(
            generate_regex_template("Unknown", "unknown"), lambda m: replace_unknown_uncertain(m, "unk"), subsectext
        )
        subsectext = re.sub(
            generate_regex_template("Uncertain", "uncertain"), lambda m: replace_unknown_uncertain(m, "unc"), subsectext
        )
        return subsectext

    p.msg("Processing")

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections

    for j, langname in secs.lang_list:
        subsecs = blib.split_text_into_subsections(sections[j], p.msg)
        subsections = subsecs.subsections
        for k, subsectitle in subsecs.header_list:
            subsections[k] = do_templatize(subsections[k], langname, subsectitle)
        sections[j] = "".join(subsections)

    newtext = "".join(sections)
    return newtext, notes


parser = blib.create_argparser(
    "Templatize 'unknown'/'uncertain' in Etymology sections, based on the section it's within",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
