#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import msg

from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    if rulib.check_for_alt_yo_terms(secbody, p.msg):
        return

    defns = blib.find_defns(secbody, "ru")
    if not defns:
        p.msg("Couldn't find definitions for %s" % p.title)
        return

    msg("%s %s" % (p.title, ";".join(defns)))


# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser(
    "Fetch definitions of specified Russian terms",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian lemmas"],
    canonicalize_pagename=rulib.remove_accents,
)
