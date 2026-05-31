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


def process_text_on_page(index, pagename, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagename, txt))

    pagemsg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Latin", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody
    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections
    if len(subsections) < 3:
        pagemsg("Something wrong, only one subsection")
        pagemsg("------- begin text --------")
        msg(text.rstrip("\n"))
        msg("------- end text --------")
        return
    for k, header in subsecs.header_list:
        def replace_triple_quote_header(m):
            headword = m.group(1)
            if header not in header_to_headword_form_template:
                pagemsg(
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
    "Fix raw Latin triple-quote headwords based on section header", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
