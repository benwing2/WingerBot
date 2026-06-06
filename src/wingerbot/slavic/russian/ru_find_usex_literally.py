#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg

parser = blib.create_argparser("Find usexes with 'literally' in them")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def process_text_on_page(p):
    lines = p.text.split("\n")
    for line in lines:
        if re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*[Ll]it(erally|\.)", line):
            p.msg("Found literally with usex: %s" % line)
        elif re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*\{\{(i|qualifier)\|", line):
            p.msg("Found qualifier with usex: %s" % line)
        elif re.search(r"\{\{(i|qualifier)\|.*\{\{(ru-ux|uxi?\|ru)\|", line):
            p.msg("Found qualifier with usex: %s" % line)
        elif re.search(r"\{\{(ru-ux|uxi?\|ru)\|.*\|ref=&#32;", line):
            p.msg("Found ref=space with usex: %s" % line)


blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
