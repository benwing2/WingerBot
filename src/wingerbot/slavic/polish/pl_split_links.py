#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg

TEMPSEP = "\ufff0"


def process_text_on_page(p):
    notes = []

    def split_links(m):
        inside = m.group(1).strip()
        hacked_inside = re.sub(r"\]\] *, *\[\[", "]]%s[[" % TEMPSEP, inside)
        parts = hacked_inside.split(TEMPSEP)
        for i in range(len(parts)):
            mm = re.search(r"^\[\[([^\[\]]*)\]\]$", parts[i])
            if not mm:
                p.msg("WARNING: Saw unparsable part %s, not changing: %s" % (parts[i], m.group(0)))
                return m.group(0)
            if TEMPSEP in parts[i]:
                p.msg("WARNING: Internal error: Saw Unicode FFF0 in part %s, not changing: %s" % parts[i], m.group(0))
                return m.group(0)
            parts[i] = "{{l|pl|%s}}" % mm.group(1)
        notes.append("replace multipart {{l|pl|...}} with separate links")
        return ", ".join(parts)

    text = re.sub(r"\{\{l\|pl\|([^{}]*[\[\]][^{}]*)\}\}", split_links, p.text)
    return text, notes


parser = blib.create_argparser(
    "Split {{l|pl|...}} links containing multiple entries"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
