#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    found_headword_template = False
    parsed = blib.parse_text(secbody)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-adj" or (tn == "head" and getparam(t, "1") == "ru" and getparam(t, "2") == "adjective form"):
            found_headword_template = True
    if not found_headword_template and "===Adjective===" in secbody:
        p.msg("WARNING: Missing adj headword template")


parser = blib.create_argparser("Find missing Russian adjective headwords")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian adjectives", "Russian adjective forms", "Russian lemmas", "Russian non-lemma forms"],
)
