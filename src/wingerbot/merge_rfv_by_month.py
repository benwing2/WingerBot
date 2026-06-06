#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname
from collections import defaultdict


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    months = re.split("(^=[^=].*\n)", p.text, 0, re.M)

    extracted_parts = [months[0]]
    by_month_header = {}
    by_month = defaultdict(list)
    order = []

    for j in range(2, len(months), 2):
        month_header = months[j - 1].strip()
        m = re.match(r"^\A=+\s*(.*?)\s*=+\Z", month_header)
        if not m:
            p.msg("WARNING: Extraneous text after month header: %s" % month_header.replace("\n", r"\n"))
            extracted_parts.append(months[j - 1])
            extracted_parts.append(months[j])
        else:
            month = m.group(1)
            if month not in order:
                order.append(month)
                by_month_header[month] = months[j - 1]
            by_month[month].append(months[j])

    for month in order:
        extracted_parts.append(by_month_header[month])
        extracted_parts.extend(by_month[month])

    return "".join(extracted_parts), "merge months"


parser = blib.create_argparser("Merge months in [[WT:RFVN]] or similar")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
