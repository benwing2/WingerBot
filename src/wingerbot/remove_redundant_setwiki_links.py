#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        if tn in ["auto cat", "autocat"] and getp("setwiki"):
            origt = str(t)
            setwiki = getp("setwiki")
            hacked_t = list(blib.parse_text(origt).filter_templates())[0]
            rmparam(hacked_t, "setwiki")
            auto_cat_text = p.expand_text(str(hacked_t))
            m = re.search(r"'''English Wikipedia''' has an article on:.*?'''\[\[w:(.*?)\|", auto_cat_text, re.S)
            if m:
                default_wikipedia = m.group(1)
                p.msg("Found default Wikipedia article: %s" % default_wikipedia)
                if default_wikipedia == setwiki:
                    p.msg("Removing setwiki=%s, same as default Wikipedia article" % setwiki)
                    rmparam(t, "setwiki")
                    notes.append("remove redundant setwiki= from {{%s}}" % tn)
                else:
                    p.msg(
                        "WARNING: Not removing setwiki=%s, different from default Wikipedia article '%s'"
                        % (setwiki, default_wikipedia)
                    )
    text = str(parsed)
    return text, notes


parser = blib.create_argparser(
    "Remove redundant setwiki= links from {{auto cat}} language categories"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["All languages"]
)
