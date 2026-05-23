#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in templates:
            for i in range(2, 10):
                if getparam(t, str(i)):
                    break
            else:
                pagemsg("Found %s template without parts: %s" % (tn, str(t)))


parser = blib.create_argparser("Find templates without any parts", include_pagefile=True, include_stdin=True)
parser.add_argument("--templates", help="""Comma-separated list of names of template to check for.""")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

templates = args.templates.split(",")
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    stdin=True,
    default_refs=["Template:%s" % template for template in templates],
)
