#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    notes = []

    subsecs = blib.split_text_into_subsections(p.text, p.msg)
    if "Antonyms" in subsecs.subsections_by_header:
        for secno in subsecs.subsections_by_header["Antonyms"]:
            parsed = blib.parse_text(subsecs.subsections[secno])
            changed = False
            for t in parsed.filter_templates():
                origt = str(t)
                tn = tname(t)
                if tn == "sense":
                    blib.set_template_name(t, "antsense")
                    p.msg("Replaced %s with %s" % (origt, str(t)))
                    notes.append("{{sense}} -> {{antsense}} in Antonyms section")
                    changed = True
                if tn == "s":
                    blib.set_template_name(t, "as")
                    p.msg("Replaced %s with %s" % (origt, str(t)))
                    notes.append("{{s}} -> {{as}} in Antonyms section")
                    changed = True
            if changed:
                subsecs.subsections[secno] = str(parsed)
    text = "".join(subsecs.subsections)
    return text, notes


parser = blib.create_argparser(
    "Convert {{sense}}/{{s}} to {{antsense}}/{{as}} in =Antonyms= sections", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
