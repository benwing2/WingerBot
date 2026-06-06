#!/usr/bin/env python3

# Go through all the pages in 'Category:R:vep:UVVV with red link' looking
# for {{R:vep:UVVV}} templates, and check the pages in those templates to
# see if they exist.

import pywikibot

from wingerbot import blib
from wingerbot.blib import site, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        if tname(t) == "R:vep:UVVV":
            refpages = blib.fetch_param_chain(t, "1", "")
            for refpage in refpages:
                if not blib.safe_page_exists(pywikibot.Page(site, refpage), p.errandmsg):
                    p.msg("Page [[%s]] does not exist" % refpage)


parser = blib.create_argparser(
    "Find red links in pages in Category:R:vep:UVVV with red link"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["R:vep:UVVV with red link"]
)
