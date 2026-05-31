#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")
    parsed = blib.parse_text(text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj", "ru-conj-old"]:
            assert not getparam(t, "4")
            inf = getparam(t, "3")
            inf = rulib.make_unstressed_ru(inf)
            inf = re.sub("нуть((ся)?)$", r"ну́ть\1", inf)
            t.add("3", inf)
            notes.append("Remove stray accent from 3c infinitive")
        newt = str(t)
        if origt != newt:
            pagemsg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Remove double accents from class 3c verbs", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian class 3c verbs"]
)
