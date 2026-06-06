#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import msg
from collections import defaultdict

pages_by_num_ar_verb_forms = defaultdict(list)


def process_text_on_page(p):
    num_ar_verb_forms = len(p.text.split("{{ar-verb-form|")) - 1
    if num_ar_verb_forms > 0:
        pages_by_num_ar_verb_forms[num_ar_verb_forms].append(p.title)


parser = blib.create_argparser(
    "Count number of {{ar-verb-form}} occurrences on each page"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

for num_occur, pages in sorted(pages_by_num_ar_verb_forms.items(), reverse=True):
    msg("%2d = %s" % (num_occur, ",".join(pages)))
