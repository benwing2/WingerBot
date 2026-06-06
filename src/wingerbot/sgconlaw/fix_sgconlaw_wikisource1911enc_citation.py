#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn == "Wikisource1911Enc Citation":
            origt = str(t)
            param1 = getp("1")
            t.add("1", "1911")
            t.add("2", param1)
            blib.set_template_name(t, "projectlink")
            if origt != str(t):
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("convert {{Wikisource1911Enc Citation}} to {{projectlink|1911}}")

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{Wikisource1911Enc Citation}} to {{projectlink|1911}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:Wikisource1911Enc Citation"]
)
