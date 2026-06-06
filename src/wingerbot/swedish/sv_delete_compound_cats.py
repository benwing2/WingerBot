#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam

parser = blib.create_argparser("Delete subcats of [[Category:Swedish compound words]]",
                               no_include_pagefile=True, no_include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for i, cat_page in blib.cat_subcats("Swedish compound words", start, end):
    cat_page.delete("Remove empty category after orphaning of {{sv-compound}}")
