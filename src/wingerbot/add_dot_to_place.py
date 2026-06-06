#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    if p.title.startswith("Module:"):
        return

    p.msg("Processing")

    notes = []
    text = p.text

    # WARNING: Not idempotent.

    to_add_period = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "place" and not t.has("t") and not t.has("t1") and not t.has("t2") and not t.has("t3"):
            to_add_period.append(str(t))

    for curr_template in to_add_period:
        repl_template = curr_template + "."
        newtext, did_replace = blib.replace_in_text(text, curr_template, repl_template, p.msg)
        if did_replace:
            newtext = re.sub(re.escape(curr_template) + r"\.([.,])", curr_template + r"\1", newtext)
            if newtext != text:
                notes.append("add period to {{place}} template (formerly automatically added)")
                text = newtext

    return text, notes


parser = blib.create_argparser(
    "Add period to {{place}} templates where it was formerly automatically added",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:place"]
)
