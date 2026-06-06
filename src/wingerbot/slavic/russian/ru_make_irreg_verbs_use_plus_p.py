#!/usr/bin/env python3

import re, copy

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj", "ru-conj-old"]:
            if [x for x in t.params if str(x.value) == "or"]:
                p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                continue
            param2 = getparam(t, "2")
            if "+p" in param2:
                continue
            ppp = getparam(t, "ppp") or getparam(t, "past_pasv_part")
            if not ppp or ppp == "-":
                continue
            ppp2 = getparam(t, "ppp2") or getparam(t, "past_pasv_part2")
            rmparam(t, "ppp")
            rmparam(t, "past_pasv_part")
            rmparam(t, "ppp2")
            rmparam(t, "past_pasv_part2")
            t.add("2", param2 + "+p")
            if tname(t) == "ru-conj":
                tempcall = re.sub(r"^\{\{ru-conj", "{{ru-generate-verb-forms", str(t))
            else:
                tempcall = re.sub(r"^\{\{ru-conj-old", "{{ru-generate-verb-forms|old=1", str(t))
            result = p.expand_text(tempcall)
            if not result:
                continue
            forms = blib.split_generate_args(result)
            pppform = forms.get("past_pasv_part", "")
            if "," in pppform:
                auto_ppp, auto_ppp2 = pppform.split(",")
                wrong = False
                if ppp != auto_ppp:
                    p.msg("WARNING: ppp %s != auto_ppp %s" % (ppp, auto_ppp))
                    wrong = True
                if ppp2 != auto_ppp2:
                    p.msg("WARNING: ppp2 %s != auto_ppp2 %s" % (ppp2, auto_ppp2))
                    wrong = True
                if wrong:
                    continue
            else:
                if ppp != pppform:
                    p.msg("WARNING: ppp %s != auto_ppp %s" % (ppp, pppform))
                    continue
        newt = str(t)
        if origt != newt:
            notes.append("Replaced manual ppp= with irreg verb with +p")
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Make irregular verbs use +p instead of manual ppp="
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian irregular verbs"]
)
