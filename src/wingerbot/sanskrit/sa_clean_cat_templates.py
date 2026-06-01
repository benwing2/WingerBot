#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

templates = [
    "sa-ima1s",
    "sa-ima3p",
    "sa-ima3s",
    "sa-imp3s",
    "sa-poa3s",
    "sa-pra1d",
    "sa-pra1p",
    "sa-pra1s",
    "sa-pra2s",
]


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    notes = []

    for t in templates:
        newtext = re.sub(r"\n*\{\{%s\}\}" % t, "", text)
        if newtext != text:
            notes.append("remove unneeded category template {{%s}}" % t)
            text = newtext

    newtext = re.sub(r"\n*\[\[Category:Sanskrit(.*?)[_ ]verb[_ ](.*?)forms([_ ].*?)?\]\]", "", text)
    if newtext != text:
        notes.append("remove unneeded manual category spec(s)")
        text = newtext

    return text, notes


parser = blib.create_argparser(
    "Remove unnecessary {{sa-*}} category templates", include_pagefile=True, include_stdin=True
)
parser.add_argument("--delete-templates", action="store_true")
parser.add_argument("--remove-manual-cats", action="store_true")
parser.add_argument("--delete-verb-subcats", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.remove_manual_cats:
    cats_to_do = []
    for i, catpage in blib.cat_subcats("Sanskrit verb forms", recurse=True):
        cat = catpage.title()
        if cat not in cats_to_do:
            cats_to_do.append(cat)
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=cats_to_do)
elif args.delete_verb_subcats:
    for i, catpage in blib.cat_subcats("Sanskrit verb forms", recurse=True):
        msg("In category %s:" % catpage.title())
        if catpage.isEmptyCategory():
            msg("Category %s is empty, deleting" % catpage.title())
            if args.save:
                catpage.delete("Remove empty, unnecessary verb-form category")
elif args.delete_templates:
    for template in templates:
        msg("Deleting Template:%s" % template)
        if args.save:
            page = pywikibot.Page(site, "Template:%s" % template)
            page.delete("Remove unnecessary {{sa-*}} category templates")
else:
    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        edit=True,
        stdin=True,
        default_refs=["Template:%s" for template in templates],
    )
