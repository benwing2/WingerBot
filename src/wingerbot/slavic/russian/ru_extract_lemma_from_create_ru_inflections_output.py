#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import errmsg
from wingerbot.slavic.russian import rulib

parser = blib.create_argparser("Find lemmas which would have forms saved by create_ru_inflections.py.",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="File containing output from create_ru_inflections.py.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lemmas = set()

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    if "Would save with comment" in line:
        m = re.search(
            r"Would save with comment.* (?:of|dictionary form) (.*?)(,| after| before| \(add| \(modify| \(update|$)",
            line,
        )
        if not m:
            errmsg("Line %s: WARNING: Unable to parse line: %s" % (lineno, line))
        else:
            lemmas.add(rulib.remove_accents(m.group(1)))
for lemma in sorted(lemmas):
    print(lemma)
