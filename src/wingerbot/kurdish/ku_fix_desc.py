#!/usr/bin/env python3

from collections import defaultdict
import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    lines = re.split("\n", p.text)
    newlines = []
    langs_at_levels = {}
    kurdish_indent = None
    kurdish_borrowing = None
    for line in lines:
        thisline_lang = None
        m = re.search("^([*]+:*)", line)
        if m:
            thisline_indent = len(m.group(1))
            if kurdish_indent and thisline_indent <= kurdish_indent:
                kurdish_indent = None
            if "{{desc|" in line or "{{desctree|" in line:
                parsed = blib.parse_text(line)
                for t in parsed.filter_templates():
                    tn = tname(t)
                    if tn in ["desc", "desctree"]:
                        thisline_lang = getparam(t, "1")
                        if thisline_lang == "ku":
                            if getparam(t, "2") != "-":
                                p.msg(
                                    "WARNING: Saw real 'Kurdish' descendant rather than anchoring line: %s" % str(t)
                                )
                                continue
                            kurdish_indent = thisline_indent
                            kurdish_borrowing = getparam(t, "bor")
                            line, did_replace = blib.replace_in_text(line, str(t), "Kurdish:", p.msg)
                            notes.append("replace {{desc|ku}} with raw 'Kurdish:'")
                        elif kurdish_indent and thisline_indent > kurdish_indent and kurdish_borrowing:
                            t.add("bor", "1")
                            line = str(parsed)
                            notes.append("add bor=1 to Kurdish-language (%s) descendant" % thisline_lang)
        else:
            kurdish_indent = None
        newlines.append(line)
    newtext = "\n".join(newlines)
    return newtext, notes


parser = blib.create_argparser(
    "Convert 'ku' to 'Kurdish:' in {{desc}} and propagate |bor=1 to children"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
