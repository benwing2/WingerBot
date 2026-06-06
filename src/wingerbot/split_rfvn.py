#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

cjk_chars = "[\u1100-\u11ff\u2e80-\ua4ff\uac00-\ud7ff\uff00-\uffef]|[\ud840-\ud8bf]."
cjk_regex = "(%s|-notice-(zh|ja|ko)-)" % cjk_chars


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    months = re.split("(^=[^=].*\n)", p.text, 0, re.M)

    extracted_parts = [months[0]]

    regex = args.regex
    if regex == "CJK":
        regex = cjk_regex
    for j in range(2, len(months), 2):
        month = re.sub(r"^\s*=+\s*(.*?)\s*=+\s*$", r"\1", months[j - 1])
        extracted_in_month = []
        level2_secs = re.split("(^==[^=].*\n)", months[j], 0, re.M)
        for k in range(2, len(level2_secs), 2):
            to_extract = re.search(regex, level2_secs[k - 1])
            if not args.invert and to_extract or args.invert and not to_extract:
                this_header = re.sub(r"^\s*=+\s*(.*?)\s*=+\s*$", r"\1", level2_secs[k - 1])
                p.msg("Extracting %s: %s" % (month, this_header))
                extracted_in_month.append(level2_secs[k - 1] + level2_secs[k])
        if extracted_in_month:
            extracted_parts.append(months[j - 1])
            extracted_parts.append(level2_secs[0])
            extracted_parts.extend(extracted_in_month)

    return "".join(extracted_parts), args.invert and "extract entries to keep" or "extract entries to remove"


parser = blib.create_argparser(
    "Extract specified entries or their converse from [[WT:RFVN]]"
)
parser.add_argument("--regex", help="Regex used to match headers.", required=True)
parser.add_argument(
    "--invert", action="store_true", help="Invert the extraction, i.e. extract entries not matching the regex."
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
