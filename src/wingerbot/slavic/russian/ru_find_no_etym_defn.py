#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

from wingerbot.slavic.russian import rulib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    modsec = blib.find_modifiable_lang_section(text, "Russian", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody

    if rulib.check_for_alt_yo_terms(secbody, pagemsg):
        return

    defns = blib.find_defns(secbody, "ru")
    if not defns:
        pagemsg("Couldn't find definitions for %s" % pagetitle)
        return

    msg("%s %s" % (pagetitle, ";".join(defns)))


# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser(
    "Fetch definitions of specified Russian terms",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian lemmas"],
    canonicalize_pagename=rulib.remove_accents,
)
