#!/usr/bin/env python3

from collections import defaultdict
import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    newtext = re.sub("^(===Pronunciation===\n.*?\n)(===Etymology===\n.*?\n)==", r"\2\1==", p.text, 0, re.S | re.M)
    return newtext, "put Etymology before Pronunciation"


parser = blib.create_argparser("Put Etymology before Pronunciation")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
