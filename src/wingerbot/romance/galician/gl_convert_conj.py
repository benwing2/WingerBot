#!/usr/bin/env python3

import json, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, getrmparam, tname, pname


def process_text_on_page(p):
    notes = []

    if "gl-verb-old" not in p.text:
        return

    parsed = blib.parse_text(p.text)

    headt = None
    saw_headt = False

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        if tn == "gl-verb-old":
            p.msg("Saw %s" % str(t))
            saw_headt = True
            if headt:
                p.msg("WARNING: Saw multiple head templates: %s and %s" % (str(headt), str(t)))
                return
            headt = t
        elif tn == "gl-conj":
            if not headt:
                p.msg("WARNING: Saw conjugation template without {{gl-verb-old}} head template: %s" % str(t))
                return
            orig_headt = str(headt)
            headtn = tname(headt)
            # Erase all params
            del headt.params[:]
            param1 = getp("1")
            if param1:
                headt.add("1", param1)
            blib.set_template_name(headt, "gl-verb")
            notes.append("convert {{%s|...}} to %s" % (headtn, str(headt)))
            headt = None

    if not saw_headt:
        p.msg("WARNING: Didn't see {{gl-verb-old}} head template")
        return

    return str(parsed), notes


parser = blib.create_argparser("Copy Galician verb conj to headword")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Galician verbs"]
)
