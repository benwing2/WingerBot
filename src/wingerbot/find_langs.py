#!/usr/bin/env python3

from wingerbot import blib


def process_text_on_page(p):
    secs = blib.split_text_into_sections(p.text, p.msg)
    langs = []
    for j, langname in secs.lang_list:
        langs.append(langname)
    p.msg("Languages = %s" % ",".join(langs))


parser = blib.create_argparser("Find languages on pages")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
