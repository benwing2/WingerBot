#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        if tn in ["de-noun", "de-proper noun"]:
            auto_old = False
            for param in ["old", "2", "3", "4", "g1", "g2", "g3", "gen1", "gen2", "gen3", "pl1", "pl2", "pl3"]:
                if getp(param):
                    auto_old = True
                    break
            if not auto_old:
                t.add("old", "1")
                notes.append("add old=1 to {{%s}} because compatible with new signature" % tn)

    return str(parsed), notes


parser = blib.create_argparser(
    "Add old=1 to {{de-noun}}/{{de-proper noun}} if compatible with new signature",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:de-noun", "Template:de-proper noun"],
)
