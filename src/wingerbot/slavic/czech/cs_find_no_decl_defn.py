#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Czech", p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections

    genders = None
    defns = None
    headt = None
    for k, header in subsecs.header_list:
        if header in ["Noun", "Proper noun"]:
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                origt = str(t)
                tn = tname(t)
                if tn in ["cs-noun", "cs-proper noun"]:
                    if headt is not None:
                        p.msg("WARNING: Saw two headwords %s and %s" % (str(headt), str(t)))
                    headt = t
                    genders = blib.fetch_param_chain(t, "1", "g")
                    defns = blib.find_defns(subsections[k], "la")
        elif header == "Declension" and "{{rfinfl|cs|" in subsections[k]:
            if genders is None or defns is None:
                p.msg("WARNING: Saw ==Declension== section without preceding headword")
                continue
            m = re.search(r"\{\{rfinfl\|cs\|[^{}]*\}\}", subsections[k])
            assert m
            rfinfl = m.group(0)
            p.msg(
                "<from> %s <to> %s <end> <from> %s <to> %s <end> gender: %s; defn: %s"
                % (rfinfl, rfinfl, str(headt), str(headt), ",".join(genders), ";".join(defns))
            )


parser = blib.create_argparser(
    "Find Czech nouns needing declension and output corresponding gender and definition",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Requests for inflections in Czech noun entries"],
)
