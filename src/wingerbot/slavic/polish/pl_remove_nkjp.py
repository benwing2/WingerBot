#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import pname


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Polish", p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "References":
            newsubsec = re.sub(r"^:?\*\s*\{\{R:pl:NKJP\}\}\n", "", subsections[k], 0, re.M)
            if newsubsec != subsections[k]:
                notes.append("remove {{R:pl:NKJP}} from Polish References section")
                subsections[k] = newsubsec
                if not subsections[k].strip():
                    subsections[k - 1] = ""
                    subsections[k] = ""
                    notes.append("remove now empty References section from Polish term")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Remove {{R:pl:NKJP}} from Polish terms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Polish lemmas"],
    skip_ignorable_pages=True,
)
