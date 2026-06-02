#!/usr/bin/env python3

# Move text outside of {{RQ:RJfrs AmtrPqr}} inside, with some renaming of
# templates and args. Specifically, we replace:
#
# #* {{RQ:RJfrs AmtrPqr|II|071}}
# #*: Orion hit a rabbit once; [...]
#
# with:
#
# #* {{RQ:Jefferies Amateur Poacher|chapter=II|passage=Orion hit a rabbit once; [...]}}

import pywikibot, re, sys, argparse
import mwparserfromhell as mw

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, set_template_name, msg, errmsg, site


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    newtext = p.text
    curtext = newtext

    newtext = re.sub(
        r"\{\{RQ:RJfrs AmtrPqr\|([^|]*?)(?:\|[^|]*?)?\}\}\n#+\*: (.*?)\n",
        r"{{RQ:Jefferies Amateur Poacher|chapter=\1|passage=\2}}\n",
        curtext,
    )
    if curtext != newtext:
        notes.append("reformat {{RQ:RJfrs AmtrPqr}}")
        curtext = newtext

    return curtext, notes


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Reformat {{RQ:Brmnghm Gsmr}} and {{RQ:Fielding Tom Jones}}", include_pagefile=True, include_stdin=True
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, new=True, default_refs=["Template:RQ:RJfrs AmtrPqr"]
    )
