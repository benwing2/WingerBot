#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    if blib.page_should_be_ignored(p.title):
        p.msg("Skipping ignored page")
        return

    notes = []
    text = p.text
    if not re.search(r"\{\{reconstruct(ed|ion)\}\}", text):
        text = "{{reconstructed}}\n" + text
        notes.append("add missing {{reconstructed}} to Reconstruction: pages")
    elif re.search(r"\A\{\{reconstruct(ed|ion)\}\}\n", text):
        pass
    elif re.search(r"\A\{\{also\|.*?\}\}\n\{\{reconstruct(ed|ion)\}\}\n", text):
        pass
    elif re.search(r"\A\{\{reconstruct(ed|ion)\}\}", text):
        p.msg("WARNING: Missing newline after initial {{reconstructed}}/{{reconstruction}}")
    else:
        p.msg("WARNING: Page has {{reconstructed}}/{{reconstruction}} not at beginning: <%s>" % text)
    return text, notes


parser = blib.create_argparser(
    "Add {{reconstructed}} to Reconstruction: pages where missing"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
