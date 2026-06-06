#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    def fix_up_section(etymsec, sectext):
        indentlevel = 3 if etymsec is None else 4
        indent = "=" * indentlevel
        subsecs = blib.split_text_into_subsections(sectext, p.msg, only_level=indentlevel)
        subsections = subsecs.subsections
        saw_adecl = False
        for k, header in subsecs.header_list:
            parsed = blib.parse_text(subsections[k])
            la_adecl_template = None
            for t in parsed.filter_templates():
                tn = tname(t)
                if tn == "la-adecl":
                    if la_adecl_template:
                        p.msg("WARNING: Saw multiple {{la-adecl}} templates: %s and %s" % (la_adecl_template, t))
                    else:
                        la_adecl_template = t
                        saw_adecl = True
            if not la_adecl_template:
                continue
            split_subsec = re.split("(^# .*substantive.*\n)", subsections[k], 0, re.M)
            remaining_parts = []
            defn_parts = []
            if len(split_subsec) == 1:
                p.msg("WARNING: Didn't see substantive defn, skipping")
                continue
            for i in range(len(split_subsec)):
                if i % 2 == 0:
                    remaining_parts.append(split_subsec[i])
                else:
                    defn_parts.append(split_subsec[i])
            param1 = getparam(la_adecl_template, "1")
            if param1.endswith("us"):
                param1 += "<2>"
                gspec = ""
            elif param1.endswith("is"):
                param1 += "<3>"
                gspec = "|g=m"
            else:
                p.msg("WARNING: Unrecognized ending on param1: %s" % param1)
                gspec = ""
            subsections[k] = "".join(remaining_parts).rstrip(
                "\n"
            ) + "\n\n%sNoun%s\n{{la-noun|%s%s}}\n\n%s\n%s=Declension=%s\n{{la-ndecl|%s}}\n\n" % (
                indent,
                indent,
                param1,
                gspec,
                "".join(defn_parts),
                indent,
                indent,
                param1,
            )
            notes.append("add noun section with {{la-noun|%s|%s}} to substantivized Latin adjective" % (param1, gspec))
        if not saw_adecl:
            p.msg("WARNING: Saw no {{la-adecl}} in section")
        return "".join(subsections)

    secbody = blib.map_etym_sections(secbody, p.msg, fix_up_section)
    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser("Add noun to substantivized Latin adjectives")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
