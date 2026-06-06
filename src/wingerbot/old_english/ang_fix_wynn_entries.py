#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    notes = []

    origtext = p.text
    parsed = blib.parse_text(p.text)
    head = None
    for t in parsed.filter_templates():
        tn = tname(t)
        newhead = None
        if (
            tn == "head"
            and getparam(t, "1") == "ang"
            or tn
            in [
                "ang-noun",
                "ang-noun-form",
                "ang-verb",
                "ang-verb-form",
                "ang-adj",
                "ang-adj-form",
                "ang-adv",
                "ang-con",
                "ang-prep",
                "ang-prefix",
                "ang-proper noun",
                "ang-suffix",
            ]
        ):
            newhead = getparam(t, "head") or p.title
        if newhead:
            if head:
                p.msg("WARNING: Saw head=%s and newhead=%s, skipping" % (head, newhead))
                return
            head = newhead
    if "ƿ" not in head:
        p.msg("WARNING: Something wrong, didn't see wynn in head: %s" % head)
    saw_altspell = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "alternative spelling of":
            if saw_altspell:
                p.msg(
                    "WARNING: Saw multiple {{alternative spelling of}}, skipping: %s and %s"
                    % (str(saw_altspell), str(t))
                )
                return
            saw_altspell = str(t)
            if getparam(t, "1") != "ang":
                p.msg("WARNING: {{alternative spelling of}} without language 'ang', skipping: %s" % str(t))
                return
            param2 = getparam(t, "2")
            should_param2 = blib.remove_links(head).replace("ƿ", "w")
            if param2 != should_param2:
                origt = str(t)
                t.add("2", should_param2)
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("fix 2= in {{alternative spelling of}} in wynn Old English entries")
    text = re.sub("\n\n+", "\n\n", str(parsed))
    if origtext != text and not notes:
        notes.append("condense 3+ newlines to 2")
    return text, notes


parser = blib.create_argparser(
    "Fix {{alternative spelling of}} in wynn Old English entries"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
