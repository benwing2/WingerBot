#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errandmsg, site


def process_text_on_page(index, pagetitle, text):
    subpagetitle = re.sub(".*:", "", pagetitle)

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    direc = pagetitle_to_direc.get(pagetitle, None)
    if not direc:
        pagemsg("WARNING: Can't find directive for page")
        return

    notes = []
    parsed = blib.parse_text(text)

    def frob_gender_param(t, param):
        val = getparam(t, param)
        if val == "n":
            t.add(param, "n-in")
        elif val == "n-p":
            t.add(param, "n-in-p")

    for t in parsed.filter_templates():
        if str(t.name) in ["ru-noun+", "ru-noun-table"]:
            origt = str(t)
            for param in t.params:
                if str(param.name) != "1":
                    pagemsg("WARNING: Found other than a single param in template, skipping: %s" % str(t))
                    return
            FIXME
            if origt != str(t):
                param3 = getparam(t, "3")
                if param3 != "-":
                    if fix_indeclinable:
                        if param3:
                            pagemsg("WARNING: Can't make indeclinable, has genitive singular given: %s" % origt)
                            return
                        else:
                            t.add("3", "-")
                            notes.append("make indeclinable")
                            pagemsg("Making indeclinable: %s" % str(t))
                    else:
                        pagemsg("WARNING: Would add inanimacy to neuter, but isn't marked as indeclinable: %s" % origt)
                        return
                pagemsg("Replacing %s with %s" % (origt, str(t)))

    if notes:
        comment = "Add inanimacy to neuters (%s)" % "; ".join(notes)
    else:
        comment = "Add inanimacy to neuters"

    return str(parsed), notes


parser = blib.create_argparser("Fix hard-е nouns according to directives", include_pagefile=True, include_stdin=True)
parser.add_argument("--direcfile", help="File listing directives to apply to nouns", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_direc = {}

for i, line in blib.iter_items_from_file(args.direcfile, start, end):
    if "!!!" in line:
        page, direc = re.split("!!!", line)
    else:
        page, direc = re.split(" ", line)
        pagetitle_to_direc[page] = direc

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_pages=list(pagetitle_to_direc.keys())
)
