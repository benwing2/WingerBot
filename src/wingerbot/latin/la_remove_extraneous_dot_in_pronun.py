#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        if tname(t) == "la-IPA":
            param1 = getparam(t, "1")
            newparam1 = re.sub(r"^(a[bd]|ob|sub)\.([lr])", r"\1\2", param1)
            if newparam1 != param1:
                origt = str(t)
                t.add("1", newparam1)
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("remove unnecessary period in %s in {{la-IPA}}" % param1)

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove extraneous dot in {{la-IPA}} pronunciation"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:la-IPA"],
    filter_pages=lambda pagetitle: re.search("^(a[bd]|ob|sub)[lr]", pagetitle),
)
