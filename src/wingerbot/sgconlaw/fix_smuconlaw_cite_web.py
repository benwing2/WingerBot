#!/usr/bin/env python3

# Replace title= with work= in cite-web, if work= doesn't already exist.

import re

from wingerbot import blib
from wingerbot.blib import msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    notes = []

    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "cite-web":
            changed = False
            if t.has("title") and not t.has("work"):
                t.get("title").name = "work"
                changed = True
                notes.append("title -> work in {{%s}}" % tn)
            if t.has("trans_work") and not t.has("trans-work"):
                t.get("trans_work").name = "trans-work"
                changed = True
            if t.has("trans_title") and not t.has("trans-work"):
                t.get("trans_title").name = "trans-work"
                changed = True
                notes.append("trans_title -> trans-work in {{%s}}" % tn)
            if t.has("trans-title") and not t.has("trans-work"):
                t.get("trans-title").name = "trans-work"
                changed = True
                notes.append("trans-title -> trans-work in {{%s}}" % tn)
            if changed:
                pagemsg(("Replacing %s with %s" % (origt, str(t))).replace("\n", r"\n"))
    return str(parsed), notes


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Fix title and entry in a couple reference templates", include_pagefile=True, include_stdin=True
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
        default_refs=["Template:cite-web"],
        # FIXME: formerly had includelinks=True on call to blib.references();
        # doesn't exist any more
    )
