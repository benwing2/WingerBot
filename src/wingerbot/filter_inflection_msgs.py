#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import errandmsg

parser = blib.create_argparser("Filter inflection messages to those which would have forms saved.",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="File containing inflection messages.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagenos = set()

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    if "Would save with comment" in line:
        m = re.search(
            r"^Page ([0-9]+) .*Would save with comment.* (?:of|dictionary form) (.*?)(,| after| before| \(add| \(modify| \(update|$)",
            line,
        )
        if not m:
            errandmsg("Line %s: WARNING: Unable to parse line: %s" % (lineno, line))
        else:
            pagenos.add(m.group(1))

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search("^Page ([0-9]+) ", line)
    if not m or m.group(1) in pagenos:
        print(line)
