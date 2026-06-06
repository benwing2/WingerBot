#!/usr/bin/env python3

# Rearrange {{was wotd}} to go after ==English==.

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg


def process_text_on_page(p):
    p.msg("Processing")

    text = re.sub(r"(\{\{was wotd\|.*?\}\}\n)(==English==\n)", r"\2\1", p.text)
    notes = ["put {{was wotd}} after ==English== per [[User:Smuconlaw]]"]

    return text, notes


parser = blib.create_argparser(
    "Rearrange {{was wotd}} to go after ==English=="
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:was wotd"]
)
