#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.latin import lalib
from wingerbot.latin.lalib import remove_macrons


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    parsed = blib.parse_text(secbody)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in lalib.la_headword_templates:
            for head in lalib.la_get_headword_from_template(t, p.title, p.msg):
                no_macrons_head = remove_macrons(blib.remove_links(head))
                if p.title.startswith("Reconstruction"):
                    unprefixed_title = "*" + re.sub(".*/", "", p.title)
                else:
                    unprefixed_title = p.title
                if no_macrons_head != unprefixed_title:
                    p.msg("WARNING: Bad Latin head: %s" % str(t))
    return


parser = blib.create_argparser("Check for bad Latin forms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Latin non-lemma forms"]
)
