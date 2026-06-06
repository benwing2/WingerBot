#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, tname


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    # Go through each subsection in turn, looking for subsection
    # matching the POS with an appropriate headword template whose
    # head matches the inflected form
    for k, header in subsecs.header_list:
        if header.startswith("Etymology"):
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                tn = tname(t)
                if tn == "diminutive of":
                    p.msg("WARNING: Found diminutive-of in etymology: %s" % str(t))


parser = blib.create_argparser(
    "Find uses of {{diminutive of}} in Russian Etymology sections"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian diminutive nouns", "Russian diminutive adjectives"],
)
