#!/usr/bin/env python3

# Move text outside of {{RQ:Bacon The Advancement of Learning}} inside, with some renaming of templates and args. Specifically, we replace:
#
##* {{RQ:Bacon The Advancement of Learning}}
##*:'' '''Policying''' of cities.''
#
# with:
#
##* {{RQ:Bacon Learning|passage='''Policying''' of cities.}}

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errmsg


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    curtext = p.text + "\n"

    def replace_bacon_the_advancement_of_learning(m):
        template, text = m.groups()
        parsed = blib.parse_text(template)
        t = list(parsed.filter_templates())[0]
        text = re.sub(r"\s*<br */?>\s*", " / ", text)
        text = re.sub(r"^''(.*)''$", r"\1", text)
        t.add("passage", text)
        blib.set_template_name(t, "RQ:Bacon Learning")
        notes.append("reformat {{RQ:Bacon The Advancement of Learning}} into {{RQ:Bacon Learning}}")
        return str(t) + "\n"

    curtext = re.sub(
        r"(\{\{RQ:Bacon The Advancement of Learning\}\})\n#+\*:\s*(.*?)\n",
        replace_bacon_the_advancement_of_learning,
        curtext,
    )

    return curtext.rstrip("\n"), notes


parser = blib.create_argparser(
    "Reformat {{RQ:Bacon The Advancement of Learning}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:RQ:Bacon The Advancement of Learning"],
)
