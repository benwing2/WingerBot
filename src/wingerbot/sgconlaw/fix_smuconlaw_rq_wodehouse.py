#!/usr/bin/env python3

# Move text outside of certain RQ: templates inside the templates.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) == "RQ:Wodehouse Offing":
            chapter = getparam(t, "1")
            passage = getparam(t, "2")
            if chapter or passage:
                rmparam(t, "1")
                rmparam(t, "2")
                if chapter:
                    t.add("chapter", chapter)
                if passage:
                    t.add("passage", passage)
                notes.append("Fix params in RQ:Wodehouse Offing")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Fix params in RQ:Wodehouse Offing templates", include_pagefile=True, include_stdin=True
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        edit=True,
        stdin=True,
        default_refs=["Template:RQ:Wodehouse Offing"],
        # FIXME: formerly had includelinks=True on call to blib.references();
        # doesn't exist any more
    )
