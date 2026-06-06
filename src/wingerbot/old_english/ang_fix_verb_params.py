#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "head" and getparam(t, "1") == "ang" and getparam(t, "2") in ["verb", "verbs"]:
            for param in t.params:
                pn = pname(param)
                if pn not in ["1", "2", "head"]:
                    p.msg("WARNING: head|ang|verb with extra params: %s" % str(t))
                    break
            else:
                # no break
                blib.set_template_name(t, "ang-verb")
                rmparam(t, "1")
                rmparam(t, "2")
                notes.append("convert {{head|ang|verb}} into {{ang-verb}}")
                head = getparam(t, "head")
                if head:
                    t.add("1", head)
                rmparam(t, "head")
        elif tn == "ang-verb":
            head = getparam(t, "head")
            head2 = getparam(t, "head2")
            head3 = getparam(t, "head3")
            rmparam(t, "head")
            rmparam(t, "head2")
            rmparam(t, "head3")
            if head:
                t.add("1", head)
            if head2:
                t.add("head2", head2)
            if head3:
                t.add("head3", head3)
            notes.append("move head= to 1= in {{ang-verb}}")
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))
    return str(parsed), notes


parser = blib.create_argparser(
    "Fix Old English verb headwords to new format"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Old English verbs"]
)
