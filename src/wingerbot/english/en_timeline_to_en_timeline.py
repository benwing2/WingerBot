#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    head = None
    last_lang = None
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["citation", "citations"]:
            last_lang = getparam(t, "1")
        if tn == "timeline":
            if last_lang == "en":
                blib.set_template_name(t, "en-timeline")
                notes.append("'timeline' -> 'en-timeline'")
            else:
                p.msg(
                    "WARNING: Skipped due to not being on English citations page (last_lang=%s): %s"
                    % (last_lang, str(t))
                )

    return str(parsed), notes


parser = blib.create_argparser(
    "timeline -> en-timeline on English citation pages"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:timeline"],
)
