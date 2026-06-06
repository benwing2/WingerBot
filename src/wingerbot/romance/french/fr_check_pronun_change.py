#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "fr-IPA":
            posval = getparam(t, "pos")
            pos_arg = "|pos=%s" % posval if posval else ""
            max_arg = 1
            for pronarg in range(2, 30):
                if getparam(t, str(pronarg)):
                    max_arg = pronarg
            for pronarg in range(1, max_arg + 1):
                pronval = getparam(t, str(pronarg)) or p.title
                pron = p.expand_text("{{#invoke:fr-pron|show|%s%s|check_new_module=1}}" % (pronval, pos_arg))
                if " || " in pron:
                    pronold, pronnew = pron.split(" || ")
                    p.msg(
                        "WARNING: {{fr-IPA|%s%s}} == %s in old but %s in new" % (pronval, pos_arg, pronold, pronnew)
                    )
                else:
                    p.msg("{{fr-IPA|%s%s}} == %s in both old and new" % (pronval, pos_arg, pron))


parser = blib.create_argparser("Check for change in {{fr-IPA}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_refs=["Template:fr-IPA"])
