#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site

parser = blib.create_argparser("List pages, lemmas and/or non-lemmas", include_pagefile=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

def process_page(index, page):
  msg("Page %s %s: Processing" % (index, str(page.title())))
blib.do_pagefile_cats_refs(args, start, end, process_page)
