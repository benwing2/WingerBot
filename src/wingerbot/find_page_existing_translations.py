#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    seen_trans = [p.title]
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in blib.translation_templates:
            trans = blib.remove_links(getparam(t, "2"))
            if trans not in seen_trans:
                seen_trans.append(trans)
    for index, trans in enumerate(seen_trans, start=1):
        def process_trans(pp):
            pp.msg("Found existing translation for %s" % p.title)
        blib.do_edit(args, "%s.%s" % (p.index, index), trans, process_trans, must_exist=True)


parser = blib.create_argparser("Find page-existing translations for terms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
