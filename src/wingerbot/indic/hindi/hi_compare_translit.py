#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site

hindi_head_templates = [
    "hi-adj",
    "hi-adj form",
    "hi-adv",
    "hi-con",
    "hi-det",
    "hi-diacritical mark",
    "hi-interj",
    "hi-noun",
    "hi-noun form",
    "hi-num",
    "hi-num-card",
    "hi-particle",
    "hi-perfect participle",
    "hi-phrase",
    "hi-post",
    "hi-prefix",
    "hi-prep",
    "hi-pron",
    "hi-pron form",
    "hi-proper noun",
    "hi-proverb",
    "hi-suffix",
    "hi-verb",
    "hi-verb form",
]


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in hindi_head_templates:
            maxtr = 1
            for i in range(1, 10):
                if getparam(t, "tr" if i == 1 else "tr%s" % i):
                    maxtr = i
            for i in range(1, maxtr + 1):
                trparam = "tr" if i == 1 else "tr%s" % i
                tr = getparam(t, trparam)
                if tr:
                    p.msg("Manual translit tr=%s in %s, not checking" % (tr, str(t)))
                else:
                    headparam = "head" if i == 1 else "head%s" % i
                    head = getparam(t, headparam)
                    if head:
                        head = blib.remove_links(head)
                    else:
                        head = p.title
                    newtr = p.expand_text("{{xlit|hi|%s}}" % head)
                    oldtr = p.expand_text("{{#invoke:User:Benwing2/hi-translit|tr|%s}}" % head)
                    if newtr and oldtr:
                        if newtr == oldtr:
                            p.msg("Auto translit %s same in new and old: %s" % (newtr, str(t)))
                        else:
                            p.msg("WARNING: Different translit, new=%s, old=%s: %s" % (newtr, oldtr, str(t)))


parser = blib.create_argparser("Check for redundant Hindi manual translit", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True, default_cats=["Hindi lemmas"])
