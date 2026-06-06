#!/usr/bin/env python3

# Remove gender from Russian adjective forms.

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return

    # Remove gender from adjective forms
    parsed = blib.parse_text(modsec.secbody)
    for t in parsed.filter_templates():
        if tname(t) == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "adjective form":
            origt = str(t)
            rmparam(t, "g")
            rmparam(t, "g2")
            rmparam(t, "g3")
            rmparam(t, "g4")
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))
                notes.append("remove gender from adjective forms")
    return modsec.rebuild(secbody=str(parsed)), notes


parser = blib.create_argparser("Remove gender from Russian adjective forms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian adjective forms"]
)
