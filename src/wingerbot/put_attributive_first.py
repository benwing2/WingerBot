#!/usr/bin/env python3

import pywikibot, re, sys, argparse
from wingerbot import blib
from wingerbot.blib import site


def process_text_on_page(p):
    notes = []

    def put_attributive_first(m):
        labels = m.group(1).split("|")
        if "attributive" in labels:
            labels_wo_attributive = [label for label in labels if label != "attributive"]
            labels = ["attributive"] + labels_wo_attributive
        return "{{lb|ru|%s}}" % "|".join(labels)

    newtext = re.sub(r"\{\{lb\|ru\|(.*?)\}\}", put_attributive_first, p.text)

    if newtext != p.text:
        notes.append("put attributive label first")
    return newtext, notes


if __name__ == "__main__":
    parser = blib.create_argparser("Put attributive label first", include_pagefile=True, include_stdin=True)
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
