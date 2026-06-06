#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, tname
from wingerbot.lang_utils import AC, GR
from wingerbot.slavic.bulgarian import bglib


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        param = None
        if tn in [
            "bg-noun",
            "bg-proper noun",
            "bg-verb",
            "bg-adj",
            "bg-adv",
            "bg-part",
            "bg-part form",
            "bg-verbal noun",
            "bg-verbal noun form",
            "bg-phrase",
        ]:
            param = "1"
        elif tn == "head" and getparam(t, "1") == "bg":
            param = "head"
        if param:
            val = getparam(t, param)
            val = bglib.decompose(val)
            if GR in val:
                val = val.replace(GR, AC)
                t.add(param, val)
                notes.append("convert grave to acute in {{%s}}" % tn)
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))
    return str(parsed), notes


parser = blib.create_argparser(
    "Change grave to acute in Bulgarian headwords"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Bulgarian lemmas", "Bulgarian non-lemma forms"],
)
