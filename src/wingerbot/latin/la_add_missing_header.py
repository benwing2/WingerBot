#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

from wingerbot.latin import lalib

tempname_to_header = {
    "la-noun-form": "Noun",
    "la-verb-form": "Verb",
    "la-adj-form": "Adjective",
    "la-proper noun-form": "Proper noun",
    "la-proper-noun-form": "Proper noun",
    "la-part-form": "Participle",
    "la-pronoun-form": "Pronoun",
}


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    notes = []
    modsec = blib.find_modifiable_lang_section(text, "Latin", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        newtext = re.sub(r"^\n*(\{\{la-.*?-form)", r"\1", subsections[k])
        if newtext != subsections[k]:
            notes.append("remove extraneous newlines before Latin non-lemma headword")
        indent = subsecs.levels[k]

        def add_header(m):
            lastchar, tempname = m.groups()
            if tempname in tempname_to_header:
                header_pos = tempname_to_header[tempname]
            else:
                pagemsg("WARNING: Unrecognized template name: %s" % tempname)
                return m.group(0)
            header = "=" * indent + header_pos + "=" * indent
            preceding_newline = "\n" if lastchar != "\n" else ""
            return lastchar + "\n" + preceding_newline + header + "\n{{" + tempname

        newnewtext = re.sub(r"([^=])\n\{\{(la-[a-z -]*?-form)", add_header, newtext)
        if newnewtext != newtext:
            notes.append("add missing header before Latin non-lemma form")
        subsections[k] = newnewtext
    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Add missing header to Latin non-lemma terms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
