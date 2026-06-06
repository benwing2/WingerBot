#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    if "it-pp" not in p.text:
        return

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn == "it-pp":
            origt = str(t)
            if getp("2") == "-":
                rmparam(t, "2")
                t.add("inv", "1")
            rmparam(t, "1")
            notes.append("convert {{it-pp}} to new form")
            if origt != str(t):
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{it-pp}} templates to new format")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:it-pp"]
)
