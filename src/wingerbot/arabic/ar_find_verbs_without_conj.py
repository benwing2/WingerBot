#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(p):
    if "{{ar-verb" not in p.text:
        p.msg("Didn't find {{ar-verb}}")
    if "{{ar-conj" not in p.text:
        p.msg("Didn't find {{ar-conj}}")


parser = blib.create_argparser("Find Arabic verbs without conjugation")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Arabic verbs"])
