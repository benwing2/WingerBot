#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import tname

# FIXME: Trivially implementable now using rewrite_template.py.

def process_text_on_page(p):
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        if tname(t) == "ar-plural":
            t.name = "ar-noun-pl"
    return str(parsed), "rename {{temp|ar-plural}} to {{temp|ar-noun-pl}}"


parser = blib.create_argparser("Rewrite ar-plural to ar-noun-pl templates", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True,
                           default_cats=["Arabic plurals"])
