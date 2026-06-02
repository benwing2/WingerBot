#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(p):
    notes = []

    secbody, sectail = blib.force_two_newlines_in_secbody(p.text, "")

    while True:
        subsecs = blib.split_text_into_subsections(secbody, p.msg)
        subsections = subsecs.subsections
        # Look for a Related terms section and move it up.
        for k, header in subsecs.header_list:
            if header == "Descendants":
                desc_indent = subsecs.levels[k]
                if (
                    k + 2 < len(subsections)
                    and subsecs.header_list[k + 2] == "Related terms"
                    and subsecs.levels[k + 2] == desc_indent
                ):
                    desc_text = subsections[k - 1 : k + 1]
                    subsections[k - 1 : k + 1] = subsections[k + 1 : k + 3]
                    subsections[k + 1 : k + 3] = desc_text
                    notes.append("reorder ==Descendants== and ==Related terms== so ==Descendants== goes below")
                    break

        else:  # no break
            break

    secbody = "".join(subsections)
    # Strip extra newlines added to secbody
    text = secbody.rstrip("\n") + sectail

    return text, notes


parser = blib.create_argparser(
    "Reorder ==Descendants== after ==Related terms==", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
