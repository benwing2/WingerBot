#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

templates = ["RQ:Schuster Hepaticae", "RQ:Harry Potter"]


def rsub_repeatedly(fr, to, text):
    while True:
        newtext = re.sub(fr, to, text)
        if newtext == text:
            return text
        text = newtext


def process_text_on_page(p):
    p.msg("Processing")
    notes = []

    newtext = rsub_repeatedly(
        r"\n(:?#+)\* \{\{RQ:Schuster Hepaticae V\|(.*)\}\}:?\n\1\*: (.*)(\n|$)",
        r"\n\1* {{RQ:Schuster Hepaticae|volume=V|page=\2|text=\3}}\4",
        p.text,
    )
    if newtext != p.text:
        notes.append("rename {{RQ:Schuster Hepaticae V}} to {{RQ:Schuster Hepaticae|volume=V}}")
        text = newtext

    newtext = rsub_repeatedly(
        r"\n(:?#+)\* \{\{RQ:Harry Potter\|([^|\n}]*)\|([^|\n}]*)((?:\|.*?)?)\}\}:?\n\1\*: (.*)\n\1\*:: (.*)(\n|$)",
        r"\n\1* {{RQ:mul:Rowling Harry Potter|\3|\2\4|text=\5|t=\6}}\7",
        text,
    )
    if newtext != text:
        notes.append("rename {{RQ:Harry Potter}} to {{RQ:mul:Rowling Harry Potter}}")
        text = newtext

    newtext = rsub_repeatedly(
        r"\n(:?#+)\* \{\{RQ:Harry Potter\|([^|\n}]*)\|([^|\n}]*)((?:\|.*?)?)\}\}:?\n\1\*: \{\{(?:ux|quote)\|.*?\|(.*?)\|(?:t=)?(.*?)\}\}(\n|$)",
        r"\n\1* {{RQ:mul:Rowling Harry Potter|\3|\2\4|text=\5|t=\6}}\7",
        text,
    )
    if newtext != text:
        notes.append("rename {{RQ:Harry Potter}} to {{RQ:mul:Rowling Harry Potter}}")
        text = newtext

    return text, notes


parser = blib.create_argparser(
    "Rename {{RQ:Schuster Hepaticae V}} and {{RQ:Harry Potter}} templates"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" % template for template in templates],
)
