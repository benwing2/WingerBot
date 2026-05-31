#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if (
            tname(t)
            in [
                "quote-book",
                "quote-hansard",
                "quote-journal",
                "quote-newsgroup",
                "quote-song",
                "quote-us-patent",
                "quote-video",
                "quote-web",
                "quote-wikipedia",
            ]
            and getparam(t, "lang") == "ru"
        ):
            passage = getparam(t, "passage")
            m = re.search(r"^\{\{lang\|ru\|(.*)\}\}$", passage)
            if m:
                t.add("passage", m.group(1))
                notes.append("remove {{lang|ru|...}} from passage= in quote-*")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove {{lang|ru|...}} from passage= in quote-*", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian terms with quotations"]
)
