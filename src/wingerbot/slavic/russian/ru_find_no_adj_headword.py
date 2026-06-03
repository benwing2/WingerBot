#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    found_headword_template = False
    for t in parsed.filter_templates():
        if tname(t) in ["ru-adj"]:
            found_headword_template = True
    if not found_headword_template:
        notes = []
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in ["ru-noun", "ru-noun+", "ru-proper noun", "ru-proper noun+"]:
                notes.append("found noun header (%s)" % tn)
            if tn == "head":
                notes.append("found head header (%s)" % getparam(t, "2"))
        p.msg("Missing adj headword template%s" % (notes and "; " + ",".join(notes)))


parser = blib.create_argparser("Find missing Russian adjective headwords", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:ru-decl-adj"]
)
