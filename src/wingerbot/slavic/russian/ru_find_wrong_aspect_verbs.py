#!/usr/bin/env python3

# Find places where ru-verb is missing or its aspect(s) don't agree with the
# aspect(s) in ru-conj-*. Maybe fix them by copying the aspect from ru-verb
# to ru-conj-*.

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    headword_aspects = set()
    found_multiple_headwords = False
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["ru-verb", "ru-verb-cform"]:
            if headword_aspects:
                found_multiple_headwords = True
            headword_aspects = set()
            aspect = getparam(t, "2")
            if aspect in ["pf", "impf"]:
                headword_aspects.add(aspect)
            elif aspect == "both":
                headword_aspects.add("pf")
                headword_aspects.add("impf")
            elif aspect == "?":
                p.msg("WARNING: Found aspect '?'")
            else:
                p.msg("WARNING: Found bad aspect value '%s' in ru-verb" % aspect)
        elif tn in ["ru-conj", "ru-conj-old"]:
            aspect = re.sub("-.*", "", getparam(t, "1"))
            if aspect not in ["pf", "impf"]:
                p.msg("WARNING: Found bad aspect value '%s' in ru-conj" % getparam(t, "1"))
            else:
                if not headword_aspects:
                    p.msg("WARNING: No ru-verb preceding ru-conj: %s" % str(t))
                elif aspect not in headword_aspects:
                    p.msg(
                        "WARNING: ru-conj aspect %s not in ru-verb aspect %s" % (aspect, ",".join(headword_aspects))
                    )
    if args.fix:
        if found_multiple_headwords:
            p.msg("WARNING: Multiple ru-verb headwords, not fixing")
        elif not headword_aspects:
            p.msg("WARNING: No ru-verb headwords, not fixing")
        elif len(headword_aspects) > 1:
            p.msg("WARNING: Multiple aspects in ru-verb, not fixing")
        else:
            for t in parsed.filter_templates():
                origt = str(t)
                tn = tname(t)
                if tn in ["ru-conj", "ru-conj-old"]:
                    param1 = getparam(t, "1")
                    param1 = re.sub("^(pf|impf)((-.*)?)$", r"%s\2" % list(headword_aspects)[0], param1)
                    t.add("1", param1)
                newt = str(t)
                if origt != newt:
                    p.msg("Replaced %s with %s" % (origt, newt))
                    notes.append("overrode conjugation aspect with %s" % list(headword_aspects)[0])

    return str(parsed), notes


parser = blib.create_argparser("Find incorrect Russian verb aspects")
parser.add_argument("--fix", action="store_true", help="Fix errors by copying aspect from headword to conjugation")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian verbs"]
)
