#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname, msg, errandmsg
from wingerbot.latin import lalib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    origtext = text

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Latin", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections
    saw_a_template = False
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        la_adj_template = None
        must_continue = False
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn == "la-adj":
                if la_adj_template:
                    pagemsg(
                        "WARNING: Saw multiple adjective headword templates in subsection, %s and %s, skipping"
                        % (str(la_adj_template), str(t))
                    )
                    must_continue = True
                    break
                la_adj_template = t
                saw_a_template = True
        if must_continue:
            continue
        if not la_adj_template:
            continue
        m = re.search(r"'*comparative'*: '*(.*?)'+,* *'*superlative'*: '*(.*?)'+", subsections[k])
        if m:
            comp, sup = m.groups()

            def parse_comp_sup(cs):
                m = re.search(r"^\{\{[lm]\|la\|(.*?)\}\}$", cs)
                if m:
                    return m.group(1)
                m = re.search(r"^\[\[.*?\|(.*?)\]\]$", cs)
                if m:
                    return m.group(1)
                m = re.search(r"^\[\[(.*?)\]\]$", cs)
                if m:
                    return m.group(1)
                pagemsg("WARNING: Can't parse comp/sup %s" % cs)
                return None

            comp = parse_comp_sup(comp)
            sup = parse_comp_sup(sup)
            if comp and sup:
                orig_la_adj_template = str(la_adj_template)
                la_adj_template.add("comp", comp)
                la_adj_template.add("sup", sup)
                pagemsg("Replaced %s with %s" % (orig_la_adj_template, str(la_adj_template)))
                notes.append("move comparative/superative to {{la-adj}} headword params")
                subsections[k] = str(parsed)
                subsections[k] = re.sub(
                    r"\n+\* *'*comparative'*: '*(.*?)'+,* *'*superlative'*: '*(.*?)'+\n+", "\n\n", subsections[k], 1
                )

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Move comparative/superlative to {{la-adj}} headword params", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Latin adjectives"], edit=True, stdin=True
)
