#!/usr/bin/env python3

# Replace title= with entry= in a couple of reference templates, and strip
# final periods from entry= in the same templates.

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

replace_templates = ["R:MED Online", "R:Reference-meta"]


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in replace_templates:
            changed = False
            title = getparam(t, "title")
            if title:
                t.get("title").name = "entry"
                notes.append("title -> entry in {{%s}}" % tn)
                changed = True
            entry = getparam(t, "entry")
            if changed:
                p.msg(("Replacing %s with %s" % (origt, str(t))).replace("\n", r"\n"))
    newtext = str(parsed)
    for tn in replace_templates:
        curtext = newtext
        newtext = re.sub(r"(\{\{%s\|[^{}]*\}\})\." % tn, r"\1", curtext)
        if curtext != newtext:
            notes.append("remove final period after {{%s}}" % tn)
            p.msg(("Replacing %s with %s" % (curtext, newtext)).replace("\n", r"\n"))
    return newtext, notes


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Fix title and entry in a couple of reference templates", include_pagefile=True, include_stdin=True
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        new=True,
        default_refs=["Template:%s" % template for template in replace_templates],
        # FIXME: formerly had includelinks=True on call to blib.references();
        # doesn't exist any more
    )
