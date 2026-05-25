#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(index, pagetitle, text):
    subpagetitle = re.sub(".*:", "", pagetitle)

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    genders = pagetitle_to_genders.get(pagetitle, None)
    if not genders:
        pagemsg("WARNING: Can't locate genders for page")
        return

    parsed = blib.parse_text(text)

    headword_template = None

    for t in parsed.filter_templates():
        if str(t.name) in ["ru-noun+", "ru-proper noun+"]:
            if headword_template:
                pagemsg("WARNING: Multiple headword templates, skipping")
                return
            headword_template = t
    if not headword_template:
        pagemsg("WARNING: No headword templates, skipping")
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
    pagemsg("Replacing %s with %s" % (orig_template, str(headword_template)))

    return str(parsed), "Fix headword gender, substituting new value %s" % ",".join(genders)


parser = blib.create_argparser(
    "Fix gender errors introduced by fix_ru_noun.py", include_pagefile=True, include_stdin=True
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
    args, start, end, process_text_on_page, edit=True, stdin=True, default_pages=list(pagetitle_to_genders.keys())
)
