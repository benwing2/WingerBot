#!/usr/bin/env python3

# Remove adj= and shto= from ru-ux.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg


def process_text_on_page(p):
    p.msg("WARNING: Script no longer applies and would need fixing up")
    return

    p.msg("Processing")
    return "#REDIRECT [[Module:ru-verb/documentation]]", "redirect to [[Module:ru-verb/documentation]]"


parser = blib.create_argparser("Redirect ru-conj-* documentation pages")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

types = [
    "7a",
    "7b",
    "8a",
    "8b",
    "9a",
    "9b",
    "10a",
    "10c",
    "11a",
    "11b",
    "12a",
    "12b",
    "13b",
    "14a",
    "14b",
    "14c",
    "15a",
    "16a",
    "16b",
    "irreg-бежать",
    "irreg-спать",
    "irreg-хотеть",
    "irreg-дать",
    "irreg-есть",
    "irreg-сыпать",
    "irreg-лгать",
    "irreg-мочь",
    "irreg-слать",
    "irreg-идти",
    "irreg-ехать",
    "irreg-минуть",
    "irreg-живописать-миновать",
    "irreg-лечь",
    "irreg-зиждиться",
    "irreg-клясть",
    "irreg-слыхать-видать",
    "irreg-стелить-стлать",
    "irreg-быть",
    "irreg-ссать-сцать",
    "irreg-чтить",
    "irreg-ошибиться",
    "irreg-плескать",
    "irreg-внимать",
    "irreg-обязывать",
]

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_pages=["Template:ru-conj-%s/documentation" % ty for i, ty in blib.iter_items(types, start, end)],
)
