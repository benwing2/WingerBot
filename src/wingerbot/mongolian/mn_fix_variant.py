#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn == "mn-variant":
            origt = str(t)
            m = getp("m")
            if m:
                t.add("1", m, before="m")
                t.add("2", m, before="m")
            c = getp("c")
            if c:
                t.add("3", c, before="c")
            rmparam(t, "m")
            rmparam(t, "c")
            if origt != str(t):
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("Convert m=/c= in {{mn-variant}} to numbered params")

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert m=/c= in {{mn-variant}} to numbered params"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:mn-variant"]
)
