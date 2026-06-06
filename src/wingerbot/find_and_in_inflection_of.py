#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    # p.msg("Processing")

    if blib.page_should_be_ignored(p.title):
        # p.msg("WARNING: Page should be ignored")
        return

    if "inflection of" not in p.text:
        return

    parsed = blib.parse_text(p.text)

    templates_to_replace = []

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        if tn in ["inflection of"]:
            if getparam(t, "lang"):
                term_param = 1
            else:
                term_param = 2
            for param in t.params:
                pname = str(param.name).strip()
                pval = str(param.value).strip()
                if re.search("^[0-9]+$", pname):
                    if int(pname) >= term_param + 2:
                        if pval in ["and", "or", ";", ";<!--\n-->"] or "/" in pval or "," in pval:
                            p.msg("Found template: %s" % origt)
                            break

    return


parser = blib.create_argparser("Find 'inflection of' tags with |and|, |or|, |;|, comma or slash in them")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
