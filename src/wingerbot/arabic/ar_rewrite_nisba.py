#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import addparam, msg


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)
    for template in parsed.filter_templates():
        if template.name == "ar-nisba":
            if template.has("head") and not template.has(1):
                head = str(template.get("head").value)
                template.remove("head")
                addparam(template, "1", head, before=str(template.params[0].name) if len(template.params) > 0 else None)
            if template.has("plhead"):
                p.msg("has plhead=")
    return str(parsed), "ar-nisba: head= -> 1="


parser = blib.create_argparser("Rewrite ar-nisba, changing head= to 1=", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True,
                           default_refs=["Template:ar-nisba"])
