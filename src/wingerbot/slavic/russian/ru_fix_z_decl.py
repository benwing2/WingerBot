#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname
from wingerbot.slavic.russian import runounlib


def process_text_on_page(p):
    p.msg("Processing")

    subpagetitle = re.sub(".*:", "", p.title)

    parsed = blib.parse_text(p.text)

    headword_templates = []
    for t in parsed.filter_templates():
        if tname(t) in ["ru-noun", "ru-proper noun"]:
            headword_templates.append(t)

    headword_template = None
    if len(headword_templates) > 1:
        p.msg("WARNING: Multiple old-style headword templates, not sure which one to use, using none")
        for ht in headword_templates:
            p.msg("Ignored headword template: %s" % str(ht))
    elif len(headword_templates) == 0:
        p.msg("WARNING: No old-style headword templates")
    else:
        headword_template = headword_templates[0]
        p.msg("Found headword template: %s" % str(headword_template))

    num_z_decl = 0
    for t in parsed.filter_templates():
        if tname(t) == "ru-decl-noun-z":
            num_z_decl += 1
            p.msg("Found z-decl template: %s" % str(t))
            ru_noun_table_template = runounlib.convert_zdecl_to_ru_noun_table(
                t, subpagetitle, p.msg, headword_template=headword_template
            )
            if not ru_noun_table_template:
                p.msg("WARNING: Unable to convert z-decl template: %s" % str(t))
                continue

            if headword_template:
                generate_template = re.sub(
                    r"^\{\{ru-noun-table", "{{ru-generate-noun-args", str(ru_noun_table_template)
                )
                if str(headword_template.name) == "ru-proper noun":
                    generate_template = re.sub(r"\}\}$", "|ndef=sg}}", generate_template)

                def pagemsg_with_proposed(text):
                    p.msg("Proposed ru-noun-table template: %s" % str(ru_noun_table_template))
                    p.msg(text)

                generate_result = p.expand_text(str(generate_template))
                if not generate_result:
                    pagemsg_with_proposed("WARNING: Error generating noun args, skipping")
                    continue
                inflargs = blib.split_generate_args(generate_result)

                # This will check number mismatch and animacy mismatch
                new_genders = runounlib.check_old_noun_headword_forms(
                    headword_template, inflargs, subpagetitle, pagemsg_with_proposed
                )
                if new_genders == None:
                    continue

            origt = str(t)
            t.name = "ru-noun-table"
            del t.params[:]
            for param in ru_noun_table_template.params:
                t.add(param.name, param.value)
            p.msg("Replacing z-decl %s with regular decl %s" % (origt, str(t)))

    if num_z_decl > 1:
        p.msg("WARNING: Found multiple z-decl templates (%s)" % num_z_decl)

    return str(parsed), "Replace ru-decl-noun-z with ru-noun-table"


parser = blib.create_argparser("Convert ru-decl-noun-z into ru-noun-table")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:ru-decl-noun-z"]
)
