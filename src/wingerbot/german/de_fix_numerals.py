#!/usr/bin/env python3

import re

from wingerbot import blib


def process_page(p):
    p.msg("Processing")
    notes = []

    text = re.sub(
        r"\n(===+)Adjective(===+)\n\{\{head\|de\|adjective form\}\}",
        "\n" + r"\1Numeral\2" + "\n{{head|de|numeral form}}",
        p.text,
    )
    notes.append("change headword from adjective form to numeral form")
    return text, notes


parser = blib.create_argparser("Change German ordinal numeral form headwords from adjective to numeral")

args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

endings = ["en", "er", "em", "es"]

def do_ordinal_number_page(p):
    pagetitle = p.title
    if not pagetitle.endswith("e"):
        return
    for ending in endings:
        blib.do_edit(args, p.index, pagetitle[:-1] + ending, process_page, must_exist=True)

blib.do_pagefile_cats_refs(args, start, end, do_ordinal_number_page, default_cats=["German ordinal numbers"])