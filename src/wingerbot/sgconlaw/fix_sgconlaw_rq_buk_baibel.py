#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errmsg, tname

book_map = {
    "Gen": "Jenesis",
    "Exod": "Kisim Bek",
    "Lev": "Wok Pris",
    "Num": "Namba",
    "Deut": "Lo",
}


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "RQ:Buk Baibel":
            param1 = getparam(t, "1")
            if param1 in book_map:
                t.add("1", book_map[param1])
                notes.append("convert '%s' to '%s' in 1= in {{%s}}" % (param1, book_map[param1], tn))
            param4 = getparam(t, "4")
            if param4:
                t.add("passage", param4, before="4")
                rmparam(t, "4")
                notes.append("4= -> passage= in {{%s}}" % tn)

        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Reformat {{RQ:Buk Baibel}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:RQ:Buk Baibel"]
)
