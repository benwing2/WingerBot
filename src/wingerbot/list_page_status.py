#!/usr/bin/env python3

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import site

# List whether pages exist and if so, are redirects and/or contain a specific language.


def process_text_on_page(p):
    exists = not not p.text or blib.safe_page_exists(pywikibot.Page(site, p.title), p.errandmsg)
    if not exists:
        outtext = "does not exist"
    else:
        if re.search("#redirect", p.text, re.I):
            outtext = "exists as redirect"
        elif args.lang:
            secs = blib.split_text_into_sections(p.text, p.msg)
            if args.lang in secs.sections_by_lang:
                outtext = "exists in %s" % args.lang
            else:
                outtext = "exists but not in %s" % args.lang
        else:
            outtext = "exists"
    p.msg(outtext)


parser = blib.create_argparser("List whether pages exist")
parser.add_argument("--lang", help="Indicate whether the page contains an entry for the specified language")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
