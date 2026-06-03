#!/usr/bin/env python3

import pywikibot, re, sys, argparse
from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

form_of_forms = defaultdict(int)


def process_text_on_page(p):
    p.msg("Processing")

    if blib.page_should_be_ignored(p.title):
        p.msg("WARNING: Page should be ignored")
        return

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "form of":
            lang = getparam(t, "lang")
            if lang:
                form = getparam(t, "1")
            else:
                form = getparam(t, "2")
            form_of_forms[form] += 1


parser = blib.create_argparser("Clean up bad inflection tags")
parser.add_argument("--textfile", help="File containing inflection templates to process.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.textfile:
    with open(args.textfile, "r", encoding="utf-8") as fp:
        text = fp.read()
    pages = re.split("\nPage [0-9]+ ", text)
    title_text_split = ": Found match for regex: "
    for index, page in blib.iter_items(pages, start, end):
        if not page:  # e.g. first entry
            continue
        split_vals = re.split(title_text_split, page, 1)
        if len(split_vals) < 2:
            msg("Page %s: Skipping bad text: %s" % (index, page))
            continue
        pagetitle, pagetext = split_vals
        process_text_on_page(blib.ProcessPageParams(args, index, pagetitle, pagetext))

    for form, count in sorted(list(form_of_forms.items()), key=lambda x: -x[1]):
        msg("%-50s = %s" % (form, count))
