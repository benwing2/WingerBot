#!/usr/bin/env python3

import re

from wingerbot import blib


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Japanese", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    newsecbody = re.sub("^====Compounds====$", "====Derived terms====", secbody, 0, re.M)
    if newsecbody != secbody:
        notes.append(
            "Compounds -> Derived terms in Japanese section (see [[Wiktionary:Grease pit/2019/September#Requesting bot help]])"
        )
        secbody = newsecbody

    while True:
        subsecs = blib.split_text_into_subsections(secbody, p.msg)
        subsections = subsecs.subsections
        for k, header in subsecs.header_list:
            if header == "Derived terms" and subsecs.levels[k] == 4:
                endk = k + 2
                while endk < len(subsections) and subsecs.headers[endk] in ["Synonyms", "Antonyms"] and subsecs.levels[endk] == 4:
                    endk += 2
                if endk > k + 2:
                    subsections = subsections[0 : k - 1] + subsections[k + 1 : endk - 1] + subsections[k - 1 : k + 1] + subsections[endk - 1 :]
                    notes.append("reorder Derived terms after Synonyms/Antonyms")
                    secbody = "".join(subsections)
                    break
        else: # no break
            break

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Compounds -> Derived terms in Japanese section and reorder after Synonyms/Antonyms",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
