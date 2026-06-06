#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, tname, pname


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Old Church Slavonic", p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    # Go through each section in turn, looking for Descendants sections
    for k, header in subsecs.header_list:
        if header == "Pronunciation":
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                def getp(param):
                    return getparam(t, param)

                origt = str(t)
                tn = tname(t)
                if tn != "cu-IPA":
                    p.msg(
                        "WARNING: Saw non-{{cu-IPA}} template in Old Church Slavonic pronunciation section: %s" % str(t)
                    )
                    break
            else:  # no break
                subsections[k - 1] = ""
                subsections[k] = ""
                notes.append("remove Pronunciation section with bad {{cu-IPA}} from Old Church Slavonic term")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Remove Pronunciation sections with {{cu-IPA}} from Old Church Slavonic terms",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:cu-IPA"],
    skip_ignorable_pages=True,
)
