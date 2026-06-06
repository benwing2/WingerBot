#!/usr/bin/env python3

# FIXME: Partly written, not working. No longer applies; {{deftempboiler}} was deleted in 2019.


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.form_of_templates import (
    language_specific_alt_form_of_templates,
    language_specific_form_of_templates,
    form_of_templates,
)


def process_text_on_page(p):
    p.msg("Processing")
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in deftempboiler_templates:
            cap = getparam(t, "cap")
            if cap:
                if cap == tn[0]:
                    t.add("nocap", "1")
                    notes.append("convert cap=%s to nocap=1 in {{%s}}" % (cap, tn))
                else:
                    notes.append("remove unnecessary cap=%s in {{%s}}" % (cap, tn))
                rmparam(t, "cap")
            if t.has("dot") and not getparam(t, "dot"):
                rmparam(t, "dot")
                t.add("nodot", "1")
                notes.append("convert empty dot= to nodot=1 in {{%s}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert cap= to nocap= and empty dot= to nodot= in templates based on {{deftempboiler}}",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
