#!/usr/bin/env python3

# Find pages containing "Of or related" in the Russian section, which is a common error for adjectives that should
# be marked as relational.
#
# FIXME: Trivially implementable using find_regex.py.:w


import re

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    if re.search("[Oo]f or related", modsec.secbody):
        p.msg("Found likely of-or-related")


parser = blib.create_argparser("Find pages with 'Of or related'", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian adjectives"]
)
