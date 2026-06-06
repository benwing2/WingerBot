#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn in ["l", "m"] and getp("1") == "jbo":
            tval = getp("t").strip()
            if tval:
                newtval = re.sub(r"\{\{l\|en\|([^{}]*)\}\}", r"\1", tval)
                if newtval != tval:
                    notes.append("remove unnecessary English links in glosses")
                    tval = newtval
                t.add("t", tval, preserve_spacing=False)
            gloss = getp("gloss").strip()
            if gloss:
                newgloss = re.sub(r"\{\{l\|en\|([^{}]*)\}\}", r"\1", gloss)
                if newgloss != gloss:
                    notes.append("remove unnecessary English links in glosses")
                    gloss = newgloss
                t.add("t", gloss, before="gloss", preserve_spacing=False)
                notes.append("move gloss= to t=")
            if t.has("gloss") and not gloss:
                notes.append("remove empty gloss=")
            rmparam(t, "gloss")
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Clean Lojban lemmas")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Lojban lemmas"]
)
