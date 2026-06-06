#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg

header_to_headword_form_template = {
    "Noun": "la-noun-form",
    "Verb": "la-verb-form",
    "Adjective": "la-adj-form",
    "Pronoun": "la-pronoun-form",
    "Proper noun": "la-proper noun-form",
}


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    if len(subsections) < 3:
        p.msg("Something wrong, only one subsection")
        p.msg("------- begin text --------")
        msg(p.text.rstrip("\n"))
        msg("------- end text --------")
        return
    for k, header in subsecs.header_list:
        def replace_triple_quote_header(m):
            headword = m.group(1)
            if header not in header_to_headword_form_template:
                p.msg(
                    "WARNING: Can't replace triple-quote headword, header %s not recognized: %s" % (header, m.group(0))
                )
                return m.group(0)
            template = header_to_headword_form_template[header]
            notes.append("replace raw %s headword with {{%s}}" % (header, template))
            if m.group(2):
                return "{{%s|%s|g=%s}}" % (template, headword, m.group(2))
            else:
                return "{{%s|%s}}" % (template, headword)

        subsections[k] = re.sub(
            r"^'''(.*?)'''(?: \{\{g\|([^{}|\n]*?)\}\})?$", replace_triple_quote_header, subsections[k], 0, re.M
        )

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Fix raw Latin triple-quote headwords based on section header"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
