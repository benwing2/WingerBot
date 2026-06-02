#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


def process_text_on_page(p):
    notes = []

    p.msg("Processing")
    modsec = blib.find_modifiable_lang_section(p.text, "Hungarian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    if "==Alternative forms==" in secbody:
        p.msg("WARNING: Skipping page with 'Alternative forms' section")
        return

    parsed = blib.parse_text(secbody)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["compound", "affix", "af"] and getparam(t, "1") == "hu" and not getparam(t, "pos"):
            t.add("pos", "noun")
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("add pos=noun to {{%s|hu}}" % tn)
    return modsec.rebuild(secbody=str(parsed)), notes


parser = blib.create_argparser("Add pos=noun to Hungarian compound words", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_cats=["Hungarian compound words"]
)
