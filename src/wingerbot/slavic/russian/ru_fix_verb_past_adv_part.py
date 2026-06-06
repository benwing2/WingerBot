#!/usr/bin/env python3

# Use past_adv_part_short=- instead of past_adv_part_short=

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        if tname(t) in ["ru-conj", "ru-conj-old"] and getparam(t, "2") in ["7a", "7b"]:
            if [x for x in t.params if str(x.value) == "or"]:
                p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                continue
            if t.has("past_adv_part_short") and getparam(t, "past_adv_part_short") == "":
                notes.append("set past_adv_part_short=-")
                origt = str(t)
                t.add("past_adv_part_short", "-")
                p.msg("Replacing %s with %s" % (origt, str(t)))
            if t.has("past_actv_part") and getparam(t, "past_actv_part") == "":
                notes.append("set past_actv_part=-")
                origt = str(t)
                t.add("past_actv_part", "-")
                p.msg("Replacing %s with %s" % (origt, str(t)))

    newtext = str(parsed)
    if newtext != p.text:
        return newtext, notes

    if not notes:
        p.msg("WARNING: No changes")


parser = blib.create_argparser(
    "Fix past_adv_part_short to use dash instead of blank"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:tracking/ru-verb/different-conj"],
)
