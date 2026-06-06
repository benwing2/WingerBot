#!/usr/bin/env python3

from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

coiner_count = defaultdict(set)


def count_coiners(p):
    if "coin" not in p.text:
        return

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["coin", "coinage"]:
            lang = getparam(t, "1")
            coiner = getparam(t, "2")
            coiner_count[(lang, coiner)].add(p.title)
            p.msg("Count for (%s, %s) is now %s" % (lang, coiner, len(coiner_count[(lang, coiner)])))


def add_remove_nobycat(p):
    if "coin" not in p.text:
        return

    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in ["coin", "coinage"]:
            lang = getparam(t, "1")
            coiner = getparam(t, "2")
            if len(coiner_count[(lang, coiner)]) == 1:
                if not getparam(t, "nobycat") and not getparam(t, "nocat"):
                    t.add("nobycat", "1")
                    notes.append("add nobycat=1 to {{coinage|%s|%s}}" % (lang, coiner))
            elif len(coiner_count[(lang, coiner)]) > 1:
                if getparam(t, "nocat"):
                    p.msg(
                        "WARNING: Lang %s, coiner %s has %s total words coined but has nocat=1: %s"
                        % (lang, coiner, len(coiner_count[(lang, coiner)]), str(t))
                    )
                elif getparam(t, "nobycat"):
                    rmparam(t, "nobycat")
                    notes.append("remove nobycat= from {{coinage|%s|%s}}" % (lang, coiner))
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Add or remove nobycat= as necessary to/from {{coinage}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, count_coiners)
blib.do_pagefile_cats_refs(args, start, end, add_remove_nobycat)
