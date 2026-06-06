#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg


def process_text_on_page(p):
    p.msg("Processing")
    newtext = p.text

    newtext = re.sub(
        r"\{\{ru-noun form\|[^|=]*\|([^|=]*)\|tr=.*?\}\}\n\n# \{\{alternative (?:form|spelling) of\|(.*?)\|lang=ru\}\}\n\n\[\[Category:Russian spellings with е instead of ё\]\]",
        r"{{ru-pos-alt-ё|\2|noun form|g=\1}}",
        newtext,
    )
    newtext = re.sub(
        r"\{\{head\|ru\|([^|=]*)\|.*?g=(.*?)(?:\|.*?)?\}\}\n\n# \{\{alternative (?:form|spelling) of\|(.*?)\|lang=ru\}\}\n\n\[\[Category:Russian spellings with е instead of ё\]\]",
        r"{{ru-pos-alt-ё|\3|\1|g=\2}}",
        newtext,
    )

    if newtext == p.text and "[[Category:Russian spellings with е instead of ё]]" in p.text:
        p.msg("WARNING: Unable to match manual alt-ё form")

    return newtext, "Replaced manual alt-ё specification with {{ru-pos-alt-ё}}"


parser = blib.create_argparser(
    "Replace manual alt-ё specification with {{ru-pos-alt-ё}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian spellings with е instead of ё"],
)
