#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    notes = []

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections
    sections_by_lang = secs.sections_by_lang
    pl_sec = sections_by_lang.get("Polish", None)
    opl_sec = sections_by_lang.get("Old Polish", None)
    if pl_sec is None or opl_sec is None:
        p.msg("Skipping because didn't find both Polish and Old Polish")
        return

    if "{{etydate|" not in sections[pl_sec]:
        p.msg("Skipping because no {{etydate}} in Polish section")
        return

    pl_secbody, pl_sectail = blib.split_trailing_separator_and_categories(sections[pl_sec])
    pl_secbody, pl_sectail = blib.force_two_newlines_in_secbody(pl_secbody, pl_sectail)

    opl_secbody, opl_sectail = blib.split_trailing_separator_and_categories(sections[opl_sec])
    opl_secbody, opl_sectail = blib.force_two_newlines_in_secbody(opl_secbody, opl_sectail)

    pl_subsecs = blib.split_text_into_subsections(pl_secbody, p.msg)
    pl_subsections = pl_subsecs.subsections
    pl_subsections_by_header = pl_subsecs.subsections_by_header
    opl_subsecs = blib.split_text_into_subsections(opl_secbody, p.msg)

    if "Etymology 1" in pl_subsections_by_header:
        p.msg("WARNING: Skipping Polish section with {{etydate}} and ==Etymology 1==, can't handle yet")
        return

    if "Etymology" not in pl_subsections_by_header:
        p.msg("WARNING: Something strange, saw {{etydate}} without ==Etymology==")
        return

    if len(pl_subsections_by_header["Etymology"]) > 1:
        p.msg("WARNING: Something strange, saw multiple ==Etymology== sections")
        return

    pl_etym_sec = pl_subsections[pl_subsections_by_header["Etymology"][0]]
    if "{{etydate|" not in pl_etym_sec:
        p.msg("WARNING: Something strange, {{etydate}} not found ==Etymology== but found outside")
        return

    subsecs = blib.split_text_into_subsections(pl_secbody, p.msg)
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

    pl_secbody = "".join(subsections)
    # Strip extra newlines added to secbody
    sections[pl_sec] = pl_secbody.rstrip("\n") + pl_sectail
    return "".join(sections), notes


parser = blib.create_argparser(
    "Remove {{etydate}} from Polish etymologies when inherited from Old Polish",
)
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
