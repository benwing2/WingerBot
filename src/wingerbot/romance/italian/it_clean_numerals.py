#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    text = p.text

    if len(re.findall("^#", text, re.M)) >= 3:
        p.msg("WARNING: Page has 3 or more definition lines, skipping")
        return
    if "===Adjective===" in p.text and "===Etymology===" not in p.text:
        cento_split = re.split("(cento)", p.title)
        if len(cento_split) != 3:
            p.msg("WARNING: Can't split %s on -cento-" % p.title)
            return
        text = text.replace(
            "===Adjective===", "===Etymology===\n{{affix|it|%s%s|%s}}\n\n===Adjective===" % tuple(cento_split)
        )
    text = re.sub(r"(\[\[[a-z -]*hundred)\|.*?\]\]", r"\1]]", text)
    text = re.sub(r"^(#.*)\.$", r"\1", text, 0, re.M)
    text = re.sub(r"===Noun===\n\{\{it-noun\|m\|-\}\}", "===Numeral===\n{{head|it|numeral}}", text)
    notes.append("clean up Italian numerals")
    return text, notes


parser = blib.create_argparser(
    "Clean up Italian numerals to use {{head|it|numeral}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
