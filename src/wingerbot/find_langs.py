#!/usr/bin/env python3

import pywikibot, re, sys, argparse
from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errandmsg, site, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    secs = blib.split_text_into_sections(text, pagemsg)
    sections = secs.sections
    langs = []
    for j, langname in secs.lang_list:
        langs.append(langname)
    pagemsg("Languages = %s" % ",".join(langs))


parser = blib.create_argparser("Find languages on pages")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.parse_dump(sys.stdin, process_text_on_page, startprefix=start, endprefix=end)
