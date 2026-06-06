#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    found_audio = False
    for t in parsed.filter_templates():
        if tname(t) == "audio" and getparam(t, "lang") == "ru":
            found_audio = True
            break
    if found_audio:
        new_text = re.sub(r"\n*\[\[Category:Russian terms with audio links]]\n*", "\n\n", p.text)
        if new_text != p.text:
            return new_text, "Remove redundant [[:Category:Russian terms with audio links]]"


parser = blib.create_argparser("Remove redundant audio-link categories")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian terms with audio links"]
)
