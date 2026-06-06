#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        decl = None
        if tn in [
            "hi-noun-c-m",
            "hi-noun-c-c",
            "hi-noun-a-m",
            "hi-noun-a-a",
            "hi-noun-ā-m",
            "hi-noun-ā-e",
            "hi-noun-i-m",
            "hi-noun-i-i",
            "hi-noun-ī-m",
            "hi-noun-ī-ī",
            "hi-noun-o-m",
            "hi-noun-u-m",
            "hi-noun-u-u",
            "hi-noun-ū-m",
            "hi-noun-ū-ū",
        ]:
            decl = "<M>"
        elif tn in [
            "hi-noun-ā-ā-m",
            "hi-noun-ā-ā",
        ]:
            decl = "<M.unmarked>"
        elif tn in [
            "hi-noun-c-f",
            "hi-noun-c-ẽ",
            "hi-noun-ā-f",
            "hi-noun-ā-āẽ",
            "hi-noun-i-f",
            "hi-noun-i-iyā̃",
            "hi-noun-ī-f",
            "hi-noun-ī-iyā̃",
            "hi-noun-u-f",
            "hi-noun-u-uẽ",
            "hi-noun-ū-f",
            "hi-noun-ū-ūẽ",
        ]:
            decl = "<F>"
        elif tn in [
            "hi-noun-iyā-f",
            "hi-noun-iyā-iyā̃",
        ]:
            decl = "<F.iyā>"
        if decl:
            t.add("1", decl)
            rmparam(t, "2")
            blib.set_template_name(t, "hi-ndecl")
            notes.append("convert {{%s}} to {{hi-ndecl}}" % tn)
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert old Hindi noun declension templates to new ones"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Hindi nouns", "Hindi numerals", "Hindi pronouns", "Hindi determiners"],
)
