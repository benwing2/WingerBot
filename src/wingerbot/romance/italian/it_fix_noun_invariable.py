#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if (
            tn == "head"
            and getparam(t, "1") == "it"
            and getparam(t, "2") in ["noun", "nouns"]
            and getparam(t, "3") == "invariable"
        ):
            must_continue = False
            g = None
            g2 = None
            head = None
            for param in t.params:
                pname = str(param.name).strip()
                pval = str(param.value).strip()
                showkey = param.showkey
                if pname in ["1", "2", "3"]:
                    pass
                elif pname == "g":
                    g = pval
                elif pname == "g2":
                    g2 = pval
                elif pname == "head":
                    head = pval
                else:
                    p.msg("WARNING: Saw unrecognized param %s: %s" % (pname, str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            if not g:
                p.msg("WARNING: Didn't see gender: %s" % str(t))
                continue
            origt = str(t)
            del t.params[:]
            blib.set_template_name(t, "it-noun")
            if head:
                t.add("head", head)
            t.add("1", g)
            if g2:
                t.add("g2", g2)
            t.add("2", "-")
            notes.append("replace {{head|it|noun|...|invariable}} with {{it-noun|...|-}}")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Replace {{head|it|noun|...|invariable}} with {{it-noun|...|-}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
