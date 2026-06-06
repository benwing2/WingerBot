#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    p.title = p.title[0].lower() + p.title[1:]

    p.msg("Processing")

    notes = []

    if "==Etymology 1==" in p.text:
        p.msg("WARNING: Saw Etymology 1, can't handle yet")
        return

    parsed = blib.parse_text(p.text)
    orig_headword = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["la-IPA", "la-adj", "la-adecl"]:
            param1 = getparam(t, "1")
            if param1:
                if tn == "la-adj":
                    orig_headword = param1
                param1 = param1[0].lower() + param1[1:]
                origt = str(t)
                t.add("1", param1)
                p.msg("Replaced %s with %s" % (origt, str(t)))
    text = str(parsed)

    subsecs = blib.split_text_into_subsections(text, p.msg)
    subsections = subsecs.subsections
    if len(subsections) < 3:
        p.msg("Something wrong, only one subsection")
        return
    notes.append("lowercase Latin adjective")
    if orig_headword:
        alter_line = "* {{alter|la|%s||alternative case form}}" % orig_headword
        if subsecs.headers[2] ==  "Alternative forms":
            subsections[2] = subsections[2].rstrip("\n") + "\n%s\n\n" % alter_line
        else:
            subsections[1:1] = ["===Alternative forms===\n", alter_line + "\n\n"]
        notes.append("add uppercase equivalent as alternative case form")
    text = "".join(subsections)

    return text, notes


parser = blib.create_argparser(
    "Lowercase Latin adjectives; use with find_regex.py"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
