#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname


def process_text_on_page(p):
    notes = []
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "head" and getparam(t, "1") == "be" and getparam(t, "2") == "verb":
            head = getparam(t, "head") or p.title
            tr = getparam(t, "tr")
            aspect = getparam(t, "3")
            if aspect == "imperfective":
                aspect = "impf"
            elif aspect == "perfective":
                aspect = "pf"
            else:
                p.msg("WARNING: Unrecognized aspect %s: %s" % (aspect, origt))
                continue
            if getparam(t, "4"):
                p.msg("WARNING: Unrecognized value in 4=: %s" % origt)
                continue
            p5 = getparam(t, "5")
            if p5 and p5 not in ["imperfective", "perfective"]:
                p.msg("WARNING: Unrecognized value in 5=: %s" % origt)
                continue
            other_aspect = None
            if p5 == "imperfective":
                other_aspect = "impf"
            elif p5 == "perfective":
                other_aspect = "pf"
            if p5:
                other_verb = getparam(t, "6")

            must_continue = False
            for param in t.params:
                pn = pname(param)
                if pn not in [
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "head",
                    "tr",
                    # params to ignore
                    "sc",
                ]:
                    p.msg("WARNING: Unrecognized param %s=%s, skipping: %s" % (pn, str(param.value), origt))
                    must_continue = True
                    break
            if must_continue:
                continue

            del t.params[:]
            blib.set_template_name(t, "be-verb")
            t.add("1", head)
            if tr:
                t.add("tr", tr)
            t.add("2", aspect)
            if other_aspect:
                t.add(other_aspect, other_verb)
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("convert {{head|be|verb}} to {{be-verb}}")
    return str(parsed), notes


parser = blib.create_argparser("Convert {{head|be|verb}} to {{be-verb}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Belarusian verbs"]
)
