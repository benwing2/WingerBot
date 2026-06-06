#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    parsed = blib.parse_text(secbody)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["l", "m", "alternative form of", "alt form"]:
            if tn in ["l", "m"]:
                lang = getparam(t, "1")
                termparam = 2
            elif getparam(t, "lang"):
                lang = getparam(t, "lang")
                termparam = 1
            else:
                lang = getparam(t, "1")
                termparam = 2
            if lang != "la":
                # p.msg("WARNING: Wrong language in template: %s" % str(t))
                continue
            term = getparam(t, str(termparam))
            alt = getparam(t, str(termparam + 1))
            gloss = getparam(t, str(termparam + 2))
            if alt and lalib.remove_macrons(alt) == term:
                origt = str(t)
                t.add(str(termparam), alt)
                if gloss:
                    t.add(str(termparam + 1), "")
                else:
                    rmparam(t, str(termparam + 1))
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("move alt param to link param in %s" % tn)

    return modsec.rebuild(secbody=str(parsed)), notes


parser = blib.create_argparser(
    "Move alt param to term param in {{l}}, {{m}}, {{alternative form of}}, {{alt form}}",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
