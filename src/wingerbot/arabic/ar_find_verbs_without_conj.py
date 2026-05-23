#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if "{{ar-verb" not in text:
        pagemsg("Didn't find {{ar-verb}}")
    if "{{ar-conj" not in text:
        pagemsg("Didn't find {{ar-conj}}")


parser = blib.create_argparser("Find Arabic verbs without conjugation", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Arabic verbs"])
