#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    if "==Etymology 1==" in p.text or "==Pronunciation 1==" in p.text:
        p.msg("WARNING: Saw Etymology/Pronunciation 1, can't handle yet")
        return

    parsed = blib.parse_text(p.text)
    headword = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in (args.adj and ["bg-adj"] or ["bg-noun", "bg-proper noun"]):
            headword = getparam(t, "1")
        if tn == "bg-decl-adj" if args.adj else tn.startswith("bg-noun-"):
            origt = str(t)
            if not headword:
                p.msg("WARNING: Saw %s without {{%s}} headword" % (origt, "bg-adj" if args.adj else "bg-noun"))
                continue
            del t.params[:]
            t.add("1", "%s<>" % headword)
            blib.set_template_name(t, "bg-adecl" if args.adj else "bg-ndecl")
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("convert {{%s}} to {{%s}}" % (tn, tname(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Use {{bg-ndecl}}/{{bg-adecl}} for Bulgarian declensions", include_pagefile=True, include_stdin=True
)
parser.add_argument("--adj", help="Do adjectives instead of nouns", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
