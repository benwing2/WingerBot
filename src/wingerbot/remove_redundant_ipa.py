#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    notes = []

    if "es-IPA" not in p.text and "fr-IPA" not in p.text and "it-IPA" not in p.text:
        return

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in ["es-IPA", "fr-IPA", "it-IPA"]:
            must_continue = False
            for i in range(2, 11):
                if getparam(t, str(i)):
                    p.msg("Template has %s=, not touching: %s" % (i, origt))
                    must_continue = True
                    break
            if must_continue:
                continue
            par1 = getparam(t, "1")
            if par1 == p.title:
                rmparam(t, "1")
                notes.append("remove redundant 1=%s from {{%s}}" % (par1, tn))
            if str(t) != origt:
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Remove redundant 1= from Romance *-IPA")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:es-IPA", "Template:fr-IPA", "Template:it-IPA"],
)
