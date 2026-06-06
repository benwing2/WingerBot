#!/usr/bin/env python3

import re
from wingerbot import blib
from wingerbot.blib import msg
from wingerbot.slavic.russian import rulib

parser = blib.create_argparser(
    "Make bare and list versions of 10,000-word frequency list from the Internet.",
    no_include_pagefile=True, no_include_stdin=True,
)
parser.add_argument("--file", help="File containing original list.")
args = parser.parse_args()

for line in open(args.file, "r", encoding="utf-8"):
    line = line.strip()
    line = re.sub(" .*", "", line)
    line = rulib.remove_accents(line)
    if "/" in line:
        els = re.split("/", line)
        impf = els[0]
        msg(impf)
        for pf in els[1:]:
            if pf.endswith("-"):
                pf = re.sub("-$", impf, pf)
            msg(pf)
    else:
        msg(line)
