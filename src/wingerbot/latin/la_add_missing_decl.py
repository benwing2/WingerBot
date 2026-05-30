#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

from wingerbot.latin import lalib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    props = pagetitle_to_props.get(pagetitle, None)
    if props is None:
        pagemsg("WARNING: Can't locate headword and decl templates for page")
        return
    headword_template, decl_template = props
    origtext = text

    modsec = blib.find_modifiable_lang_section(text, "Latin", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    parsed = blib.parse_text(secbody)
    num_noun_headword_templates = 0
    num_ndecl_templates = 0
    num_adecl_templates = 0
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["la-noun", "la-proper noun"]:
            num_noun_headword_templates += 1
        if tn == "la-ndecl":
            num_ndecl_templates += 1
        if tn == "la-adecl":
            num_adecl_templates += 1
        # FIXME, also add something for manually-specified declensions (synaeresis?)
    if "\n===Declension===\n" in secbody:
        pagemsg("WARNING: Saw misindented Declension header")
    if num_adecl_templates >= 1:
        pagemsg("WARNING: Saw {{la-adecl}} in noun section")
    if num_ndecl_templates + num_adecl_templates >= num_noun_headword_templates:
        pagemsg(
            "WARNING: Already seen %s decl template(s) >= %s headword template(s), skipping"
            % (num_ndecl_templates + num_adecl_templates, num_noun_headword_templates)
        )
        return

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections
    num_declension_headers = 0
    for k, header in subsecs.header_list:
        if header in ["Declension", "Inflection"]:
            num_declension_headers += 1
    if num_declension_headers >= num_noun_headword_templates:
        pagemsg(
            "WARNING: Already seen %s Declension/Inflection header(s) >= %s headword template(s), skipping"
            % (num_declension_headers, num_noun_headword_templates)
        )
        return

    for k, header in subsecs.header_list:
        if headword_template in subsections[k]:
            pagemsg("Inserting declension section after subsection %s" % k)
            subsections[k] = subsections[k].rstrip("\n") + "\n\n"
            num_equal_signs = len(re.sub("^(=+).*", r"\1", subsections[k - 1].strip()))
            subsections[k + 1 : k + 1] = [
                "%sDeclension%s\n%s\n\n" % ("=" * (num_equal_signs + 1), "=" * (num_equal_signs + 1), decl_template)
            ]
            notes.append("add section for Latin declension %s" % decl_template)
            break
    else:
        pagemsg("WARNING: Couldn't locate headword template, skipping: %s" % headword_template)
        return
    text = modsec.rebuild(secbody="".join(subsections))
    text = re.sub("\n\n\n+", "\n\n", text)
    if not notes:
        notes.append("convert 3+ newlines to 2")
    return text, notes


parser = blib.create_argparser("Add missing declension to Latin terms", include_pagefile=True, include_stdin=True)
parser.add_argument("--direcfile", help="File of output directives from make_latin_missing_decl.py", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_props = {}

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search("^Page [0-9]+ (.*?): For noun (.*?), declension (.*?)$", line)
    if not m:
        msg("Line %s: Unrecognized line, skipping: %s" % (lineno, line))
    else:
        pagetitle, headword_template, decl_template = m.groups()
        pagetitle_to_props[pagetitle] = (headword_template, decl_template)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_pages=list(pagetitle_to_props.keys())
)
