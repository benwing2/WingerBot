#!/usr/bin/env python3

from wingerbot import blib


def process_text_on_page(p):
    result = p.expand_text("{{auto cat}}")
    if not result:
        return
    p.msg("Returned: <%s>" % result)


parser = blib.create_argparser("Test {{auto cat}}", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
