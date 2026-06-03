#!/usr/bin/env python3

import pywikibot, re, sys, argparse, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, site

templates_to_tags = {
    "sv-verb-form-imp": ["imp"],
    "sv-verb-form-past": ["past"],
    "sv-verb-form-past-pass": ["past", "pass"],
    "sv-verb-form-pre": ["pres"],
}


def process_text_on_page(p):
    notes = []

    replacements = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        repl = None
        if tn in templates_to_tags:
            tags = templates_to_tags[tn]
        else:
            continue
        plural_of = getp("plural of")
        term = getp("1")
        must_continue = False
        for param in t.params:
            ok = False
            pn = pname(param)
            if pn not in ["1", "plural of"]:
                p.msg("WARNING: Saw unrecognized param %s=%s in %s" % (pn, str(param.value), str(t)))
                must_continue = True
                break
        if must_continue:
            continue
        origt = str(t)
        repl = "{{infl of|sv|%s||%s}}" % (term, "|".join(tags))
        if plural_of:
            repl = "{{sv-obs verb pl|%s}}, %s" % (plural_of, repl)
        repltuple = (origt, repl)
        if repltuple not in replacements:
            replacements.append(repltuple)
        if plural_of:
            notes.append("convert {{%s|plural of=...}} to {{sv-obs verb pl|...}}, {{infl of|sv|...}}")
        else:
            notes.append("convert {{%s}} to {{infl of|sv|...}}")

    text = p.text
    for origt, replt in replacements:
        text, did_replace = blib.replace_in_text(text, origt, replt, p.msg)
        if not did_replace:
            return

    return text, notes


parser = blib.create_argparser(
    "Convert {{sv-verb-form-*}} optionally with |plural of= param to generic equivalents",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" % temp for temp in templates_to_tags],
)
