#!/usr/bin/env python3

# Use past_adv_part_short=- instead of past_adv_part_short=

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    found_inflection_of = False
    found_head_verb_form = False
    for t in parsed.filter_templates():
        if tname(t) in ["inflection of"]:
            found_inflection_of = True
        if tname(t) == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "verb form":
            found_head_verb_form = True

    if not found_head_verb_form or not found_inflection_of:
        # Find definition line
        modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
        if modsec is None:
            return
        deflines = r"\n".join(re.findall(r"^(# .*)$", modsec.secbody, re.M))

    if not found_head_verb_form:
        p.msg("WARNING: No {{head|ru|verb form}}: %s" % deflines)
    if not found_inflection_of:
        p.msg("WARNING: No 'inflection of': %s" % deflines)


parser = blib.create_argparser("Find badly formatted Russian verb forms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian verb forms"]
)
