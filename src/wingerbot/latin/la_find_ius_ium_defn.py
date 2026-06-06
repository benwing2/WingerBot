#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in ["la-noun", "la-proper noun"]:
                param1 = getparam(t, "1")
                has_no_short_gen = re.search(r"(\b|\.)-iu[sm]\b", param1)
                defns = blib.find_defns(subsections[k], "la")
                msg("|-")
                msg(
                    "| %s || %s || %s ||  ?  || %s"
                    % (p.title, param1, "yes" if has_no_short_gen else "no", ";".join(defns))
                )


parser = blib.create_argparser(
    "Find -ius/-ium nouns with/without short genitive, with corresponding defns",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

msg('{|class="wikitable"')
msg("! Lemma !! Declension !! Has Short Gen !! Wrong? !! Defn")
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Latin nouns"],
    filter_pages=lambda pagetitle: re.search("iu[sm]$", pagetitle),
)
msg("|}")
