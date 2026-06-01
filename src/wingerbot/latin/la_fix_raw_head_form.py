#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname

from wingerbot.latin import lalib

pos_to_template = {
    "noun form": "la-noun-form",
    "noun forms": "la-noun-form",
    "proper noun form": "la-proper noun-form",
    "proper noun forms": "la-proper noun-form",
    "pronoun form": "la-pronoun-form",
    "pronoun forms": "la-pronoun-form",
    "verb form": "la-verb-form",
    "verb forms": "la-verb-form",
    "adjective form": "la-adj-form",
    "adjective forms": "la-adj-form",
    "participle form": "la-part-form",
    "participle forms": "la-part-form",
    "numeral form": "la-numeral-form",
    "numeral forms": "la-numeral-form",
    "suffix form": "la-suffix-form",
    "suffix forms": "la-suffix-form",
}


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "head" and getparam(t, "1") == "la":
            pos = getparam(t, "2")
            if pos not in pos_to_template:
                p.msg("WARNING: Saw unrecognized part of speech %s: %s" % (pos, str(t)))
                continue
            if getparam(t, "3") or getparam(t, "head"):
                p.msg("WARNING: Saw 3= or head=: %s" % str(t))
                continue
            origt = str(t)
            t.add("1", p.title)
            blib.set_template_name(t, pos_to_template[pos])
            rmparam(t, "2")
            t.add("FIXME", "1")
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("replace {{head|la|%s}} with {{%s}}" % (pos, tname(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Fix Latin raw-form {{head|la|... form}} usages", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
