#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname, pname


def process_text_on_page(p):
    # Greatly speed things up when --stdin by ignoring non-Latin pages
    if "==Latin==" not in p.text:
        return

    if not re.search("la-(noun|proper noun|pronoun|verb|adj|num|suffix)-form", p.text):
        return

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    parsed = blib.parse_text(secbody)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in [
            "la-noun-form",
            "la-proper noun-form",
            "la-pronoun-form",
            "la-verb-form",
            "la-adj-form",
            "la-num-form",
            "la-suffix-form",
        ]:
            if not getparam(t, "1"):
                p.msg("WARNING: Missing 1=: %s" % str(t))
            for param in t.params:
                pn = pname(param)
                if pn not in ["1", "g", "g2", "g3", "g4"]:
                    p.msg("WARNING: Extraneous param %s=: %s" % (pn, str(t)))


parser = blib.create_argparser(
    "Check for Latin non-lemma forms with bad params"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Latin non-lemma forms"]
)
