#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

request_templates = ["rfdatek", "rfquotek"]


def process_text_on_page(p):
    if blib.page_should_be_ignored(p.title):
        p.msg("Skipping ignored page")
        return

    def hack_templates(parsed, langname):
        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in request_templates:
                if getparam(t, "lang"):
                    continue
                if langname and langname != "English":
                    p.msg("WARNING: Would default to English but in %s section, skipping: %s" % (langname, origt))
                    continue
                notes.append("add lang=en for {{%s}} with missing lang code" % tn)
                rmparam(t, "lang")  # in case it's blank
                # Fetch all params.
                params = []
                for param in t.params:
                    pname = str(param.name)
                    params.append((pname, param.value, param.showkey))
                # Erase all params.
                del t.params[:]
                newline = "\n" if "\n" in str(t.name) else "" # not tname() as we want to check for spaces
                t.add("lang", "en" + newline, preserve_spacing=False)
                # Put remaining parameters in order.
                for name, value, showkey in params:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
                p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    p.msg("Processing")

    notes = []

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections
    for j, langname in [(0, "")] + secs.lang_list:
        parsed = blib.parse_text(sections[j])
        hack_templates(parsed, langname)
        sections[j] = str(parsed)

    newtext = "".join(sections)
    return newtext, notes


parser = blib.create_argparser(
    "Add |lang=en to request templates missing |lang", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Language code missing/%s" % template for template in request_templates],
)
