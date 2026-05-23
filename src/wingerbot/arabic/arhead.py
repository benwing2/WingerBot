#!/usr/bin/env python3

import pywikibot, re, string, sys

from wingerbot import blib
from wingerbot.blib import addparam, tname
from wingerbot.arabic import arlib

raise RuntimeError("Extremely old and outdated")


def process_text_on_page(index, pagetitle, text):
    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in arlib.arabic_all_headword_templates:
            if (
                t.has("head")
                and not t.has(1)
                and not t.has(2)
                and not t.has(3)
                and not t.has(4)
                and not t.has(5)
                and not t.has(6)
                and not t.has(7)
                and not t.has(8)
            ):
                head = str(t.get("head").value)
                t.remove("head")
                addparam(t, "head", head, before=t.params[0].name if len(t.params) > 0 else None)

                if t.params[0].name == "head":
                    t.get("head").showkey = False

    return str(parsed), "ar headword: head= > 1="


parser = blib.create_argparser("Convert head= to 1= in Arabic headwords", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:tracking/ar-head/head"], edit=True, stdin=True
)
