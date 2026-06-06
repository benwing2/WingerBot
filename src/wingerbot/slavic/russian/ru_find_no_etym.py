#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    if "==Etymology" in secbody:
        return
    if rulib.check_for_alt_yo_terms(secbody, p.msg):
        return
    parsed = blib.parse_text(secbody)
    for t in parsed.filter_templates():
        if tname(t) in ["ru-participle of"]:
            p.msg("Skipping participle")
            return

    msg("%s no-etym" % p.title)


# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser(
    "Find Russian terms without etymology",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian lemmas"],
    canonicalize_pagename=rulib.remove_accents,
)
