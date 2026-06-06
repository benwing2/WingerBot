#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    genders = pagetitle_to_genders.get(p.title, None)
    if not genders:
        p.msg("WARNING: Can't locate genders for page")
        return

    parsed = blib.parse_text(p.text)

    headword_template = None

    for t in parsed.filter_templates():
        if tname(t) in ["ru-noun+", "ru-proper noun+"]:
            if headword_template:
                p.msg("WARNING: Multiple headword templates, skipping")
                return
            headword_template = t
    if not headword_template:
        p.msg("WARNING: No headword templates, skipping")
        return

    orig_template = str(headword_template)
    rmparam(headword_template, "g")
    rmparam(headword_template, "g2")
    rmparam(headword_template, "g3")
    rmparam(headword_template, "g4")
    rmparam(headword_template, "g5")
    for gnum, g in enumerate(genders):
        param = "g" if gnum == 0 else "g" + str(gnum + 1)
        headword_template.add(param, g)
    p.msg("Replacing %s with %s" % (orig_template, str(headword_template)))

    return str(parsed), "Fix headword gender, substituting new value %s" % ",".join(genders)


parser = blib.create_argparser(
    "Fix gender errors introduced by fix_ru_noun.py"
)
parser.add_argument("--direcfile", help="File containing pages and warnings to process", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_genders = {}

# * Page 3574 [[коала]]: WARNING: Gender mismatch, existing=m-an,f-an, new=f-an
for i, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search(r"^\* Page [0-9]+ \[\[(.*?)\]\]: WARNING: Gender mismatch, existing=(.*?), new=.*?$", line)
    if not m:
        msg("Line %s: WARNING: Can't process line: %s" % (i, line))
    else:
        page, genders = m.groups()
        msg("Page %s %s: Processing: %s" % (i, page, line))
        pagetitle_to_genders[page] = re.split(",", genders)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_pages=list(pagetitle_to_genders.keys())
)
