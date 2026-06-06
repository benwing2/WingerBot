#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "inflection of":
            lang = getparam(t, "lang")
            if lang:
                term_param = 1
            else:
                lang = getparam(t, "1")
                term_param = 2
            if lang != "la":
                continue
            term = getparam(t, str(term_param))
            alt = getparam(t, str(term_param + 1))
            if alt:
                if lalib.remove_macrons(alt) != lalib.remove_macrons(term):
                    p.msg("WARNING: alt not same as term modulo macrons: %s" % str(t))
                    continue
                origt = str(t)
                t.add(str(term_param), alt)
                t.add(str(term_param + 1), "")
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("move alt param to term param in Latin {{inflection of}}")

    return str(parsed), notes


parser = blib.create_argparser(
    "Move alt form to main form in Latin {{inflection of}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
