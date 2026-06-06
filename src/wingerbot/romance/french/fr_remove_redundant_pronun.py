#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "fr-IPA":
            maxindex = 1
            for i in range(2, 11):
                if getparam(t, str(i)):
                    maxindex = i
            params = []
            redundant = []
            pos = getparam(t, "pos")
            pos_arg = "|pos=%s" % pos if pos else ""
            default_autopron = p.expand_text("{{#invoke:fr-pron|show|%s%s}}" % (p.title, pos_arg))
            if not default_autopron:
                continue
            origt = str(t)
            for i in range(1, maxindex + 1):
                pron = getparam(t, str(i))
                if pron:
                    autopron = p.expand_text("{{#invoke:fr-pron|show|%s%s}}" % (pron, pos_arg))
                    if not autopron:
                        continue
                    if autopron == default_autopron:
                        if maxindex == 1:
                            rmparam(t, "1")
                            notes.append("remove redundant respelling %s from {{fr-IPA}}" % pron)
                        else:
                            t.add(str(i), "+")
                            notes.append("set redundant respelling %s in {{fr-IPA}} to +" % pron)
            if str(t) != origt:
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove redundant French respelling from {{fr-IPA}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:tracking/fr-pron/redundant-pron"],
)
