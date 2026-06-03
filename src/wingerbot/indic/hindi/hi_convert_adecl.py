#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import rmparam, tname, msg

AA = "\u093e"
M = "\u0901"
IND_AA = "आ"


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["hi-adj-1"]:
            rmparam(t, "1")
            rmparam(t, "2")
            blib.set_template_name(t, "hi-adecl")
            notes.append("convert {{%s}} to {{hi-ndecl}}" % tn)
        if tn in ["hi-adj-auto"]:
            if " " not in p.title and "-" not in p.title and (p.title.endswith(AA) or p.title.endswith(IND_AA)):
                blib.set_template_name(t, "hi-adecl")
                notes.append("convert {{%s}} to {{hi-ndecl}}" % tn)
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert old Hindi adjective declension templates to new ones", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:hi-adj-1", "Template:hi-adj-auto"],
)
