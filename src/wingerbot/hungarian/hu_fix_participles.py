#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Hungarian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if (
            header == "Verb"
            and "{{head|hu|verb form" in subsections[k]
            and "{{participle of|hu|" in subsections[k]
        ):
            if args.split_participle:
                newsubsec = re.sub(
                    r"^(#.*\{\{participle of\|hu\|.*)\n(#.*\{\{inflection of\|hu\|.*)\n\n",
                    r"\2\n\1\n\n",
                    subsections[k],
                    0,
                    re.M,
                )
                if newsubsec != subsections[k]:
                    notes.append("reorder {{inflection of|hu|...}} before {{participle of|hu|...}}")
                    subsections[k] = newsubsec
                elif re.search(r"\{\{participle of\|hu\|.*\{\{inflection of\|hu\|", subsections[k], re.S):
                    p.msg(
                        "WARNING: Saw {{participle of|hu|...}} before {{inflection of|hu|...}} with likely usage examples"
                    )
                    continue
            if args.split_participle and "{{inflection of|hu|" in subsections[k]:
                subsections[k] = re.sub(
                    r"^(#.*\{\{participle of\|hu\|)",
                    r"\n===Participle===\n{{head|hu|participle}}\n\n\1",
                    subsections[k],
                    0,
                    re.M,
                )
                notes.append("split Hungarian verb form from participle")
            else:
                subsections[k - 1] = subsections[k].replace("Verb", "Participle")
                subsections[k] = re.sub(r"\{\{head\|hu\|verb form", "{{head|hu|participle", subsections[k])
                notes.append("Hungarian verb form -> participle in section with {{participle of}}")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Replace Hungarian 'verb form' with 'participle' in participle sections and maybe split verb forms from participles",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--split-participle", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Hungarian present participles"], edit=True, stdin=True
)
