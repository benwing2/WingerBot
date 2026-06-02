#!/usr/bin/env python3

# Rearrange {{was wotd}} to go after ==English==.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(p):
    p.msg("Processing")

    text = re.sub(r"(\{\{was wotd\|.*?\}\}\n)(==English==\n)", r"\2\1", p.text)
    notes = ["put {{was wotd}} after ==English== per [[User:Smuconlaw]]"]

    return text, notes


parser = blib.create_argparser(
    "Rearrange {{was wotd}} to go after ==English==", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_refs=["Template:was wotd"]
)
