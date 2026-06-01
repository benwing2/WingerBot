#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    parsed = blib.parse_text(secbody)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-decl-3rd-I":
            stem = getparam(t, "1")
            if stem.endswith("polis"):
                blib.set_template_name(t, "la-decl-3rd-polis")
                t.add("1", stem[:-5])
                notes.append("Fix noun in -polis to use {{la-decl-3rd-polis}}")
            else:
                p.msg("WARNING: Found la-decl-3rd-I without stem in -polis: %s" % str(t))
        elif tn == "la-noun":
            blib.set_template_name(t, "la-proper noun")

    secbody = str(parsed).replace("==Noun==", "==Proper noun==")

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser("Fix Latin declensions of -polis nouns", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
