#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname


def process_text_on_page(p):
    notes = []

    if not re.search(r"\{\{ *(col[0-9]*|col-auto|der[0-9]|rel[0-9])(-u)? *\|", p.text):
        return

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if re.search("^(col[0-9]*|col-auto|der[0-9]|rel[0-9])(-u)?$", tn):
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if re.search(args.regex, pv):
                    p.msg("Found %s=%s: %s" % (pn, pv, str(t)))


parser = blib.create_argparser(
    "Find column templates with comma not followed by space, or other regex"
)
parser.add_argument("--regex", default=",[^ ]", help="Regex to search for.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
