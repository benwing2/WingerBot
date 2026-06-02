#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def one_char(t):
    return len(t) == 1 or len(t) == 2 and 0xD800 <= ord(t[0]) <= 0xDBFF


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "vi-hantu":
            if not one_char(p.title):
                p.msg("WARNING: Length of page title is %s > 1, skipping" % len(p.title))
                continue
            if getparam(t, "pos"):
                p.msg("WARNING: Saw pos=, skipping: %s" % str(t))
                continue
            chu = getparam(t, "chu")
            if chu and chu != "Nom":
                p.msg("WARNING: Saw chu=%s not 'Nom', skipping: %s" % (chu, str(t)))
                continue
            if chu == "Nom":
                newparam = "nom"
            else:
                newparam = "reading"
            reading = blib.remove_links(getparam(t, "1"))
            if not reading:
                p.msg("WARNING: Empty reading, skipping: %s" % str(t))
                continue
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if pn not in ["1", "rs", "chu"]:
                    p.msg("WARNING: Unrecognized parameter %s=%s, skipping: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            t.add(newparam, reading, before="1")
            rmparam(t, "1")
            blib.set_template_name(t, "vi-readings")
            notes.append("{{vi-hantu}} -> {{vi-readings}}")

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{vi-hantu}} to {{vi-readings}}", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_refs=["Template:vi-hantu"]
)
