#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname

non_adjectival_names = ["Дарвин"]


def process_text_on_page(p):
    p.msg("Processing")

    if p.title in non_adjectival_names:
        p.msg("Skipping explicitly-specified non-adjectival name")
        return
    parsed = blib.parse_text(p.text)

    notes = []

    proper_noun_headword = None
    surname_template = None
    ru_adj11_template = None

    for t in parsed.filter_templates():
        def getp(param):
            return getparam(t, param)
        tn = tname(t)
        if tn == "ru-proper noun":
            p.msg("WARNING: Found old ru-proper noun: %s" % str(t))
        elif tn == "ru-proper noun+":
            name = getp("1")
            if not (not getp("2") or getp("2") == "+" and not getp("3")):
                p.msg("WARNING: Complex proper noun header, not sure how to handle: %s" % str(t))
            else:
                if re.search("([оеё]́?в|и́?н)$", name):
                    new_fem = name + "а"
                elif re.search("ый$", name):
                    new_fem = re.sub("ый$", "ая", name)
                elif re.search("о́й$", name):
                    new_fem = re.sub("о́й$", "а́я", name)
                elif re.search("[кгхчшжщ]ий$", name):
                    new_fem = re.sub("ий$", "ая", name)
                else:
                    new_fem = None
                    if re.search("ий$", name):
                        p.msg("WARNING: Name ending in non-velar/hushing consonant + -ий: %s" % str(t))
                if new_fem:
                    if getp("2") != "+":
                        p.msg("WARNING: Adjectival name not correctly conjugated in headword, fixing: %s" % str(t))
                        origt = str(t)
                        t.add("2", "+", before="a")
                        notes.append("add adjectival + to %s" % name)
                        p.msg("Replacing %s with %s" % (origt, str(t)))
                    existing_fem = getp("f")
                    if existing_fem:
                        if new_fem != existing_fem:
                            p.msg(
                                "WARNING: New feminine %s different from existing feminine %s, not changing: %s"
                                % (new_fem, existing_fem, str(t))
                            )
                    else:
                        origt = str(t)
                        t.add("f", new_fem)
                        notes.append("add feminine %s to %s" % (new_fem, name))
                        p.msg("Replacing %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Add feminines to Russian proper names", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian surnames"]
)
