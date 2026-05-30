#!/usr/bin/env python3

# Remove gender from Russian adjective forms.

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    if ":" in pagetitle:
        pagemsg("WARNING: Colon in page title, skipping page")
        return

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Russian", pagemsg)
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
                pagemsg("Replaced %s with %s" % (origt, newt))
                notes.append("remove gender from adjective forms")
    return modsec.rebuild(secbody=str(parsed)), notes


parser = blib.create_argparser("Remove gender from Russian adjective forms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian adjective forms"]
)
