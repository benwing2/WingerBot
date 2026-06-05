#!/usr/bin/env python3

# FIXME: No longer needed. Use find_regex.py.

from wingerbot import blib

parser = blib.create_argparser("Find verbs with impersonal conjugations",
                               include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

def process_text_on_page(p):
    if "-impers|" in p.text:
        p.msg("Found impersonal conjugation")
    else:
        p.msg("No impersonal conjugation")

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Russian verbs"])