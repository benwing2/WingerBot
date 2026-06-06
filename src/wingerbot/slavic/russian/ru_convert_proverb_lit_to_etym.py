#!/usr/bin/env python3

# Convert "literally X" expressions in the definition of a proverb into etymologies.

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    m = re.search(
        r"\A(.*)^(# .*\]\])[^a-zA-Z0-9\[\]\n]*(?:gloss)?[^a-zA-Z0-9\[\]\n]*literally[^a-zA-Z0-9\[\]\n]*([a-zA-Z0-9\[\]][^\n]*[a-zA-Z0-9\[\]])[^a-zA-Z0-9\[\]\n]*$(.*)\Z",
        secbody,
        re.M | re.S,
    )
    if m:
        p.msg("Found defn '%s', literally '%s'" % (m.group(2), m.group(3)))
        if "\n===Etymology===\n" in secbody:
            p.msg("WARNING: Found Etymology section already, not doing anything")
        else:
            secbody = '\n===Etymology===\nLiterally, "%s".\n%s%s%s' % (
                m.group(3),
                m.group(1),
                m.group(2),
                m.group(4),
            )
            notes.append("Move literal meaning '%s' to etymology" % m.group(3))

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    'Convert "literally X" expressions in the definition of a proverb into etymologies',
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian proverbs"]
)
