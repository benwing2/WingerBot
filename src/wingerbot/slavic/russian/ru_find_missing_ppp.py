#!/usr/bin/env python3

# Find Russian verbs with missing past passive participles. All such verbs should
# be imperfective transitive, since perfective transitive verbs lacking
# a past participle specification will cause an error. In particular, we
# look for unpaired verbs, since paired verbs generally don't have
# PPP's.

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    notes = []
    saw_paired_verb = False
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-verb":
            saw_paired_verb = False
            if getparam(t, "2") in ["impf", "both"]:
                verb = getparam(t, "1") or p.title
                pfs = blib.fetch_param_chain(t, "pf", "pf")
                impfs = blib.fetch_param_chain(t, "impf", "impf")
                for otheraspect in pfs + impfs:
                    if verb[0:2] == otheraspect[0:2]:
                        saw_paired_verb = True
        if tn in ["ru-conj", "ru-conj-old"] and getparam(t, "1") == "impf" and not saw_paired_verb:
            if getparam(t, "ppp") or getparam(t, "past_pasv_part"):
                pass
            elif [x for x in t.params if str(x.value) == "or"]:
                p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                pass
            elif re.search(r"\+p|\[?\([78]\)\]?", getparam(t, "2")):
                pass
            else:
                p.msg("Apparent unpaired transitive imperfective without PPP")
                if p.title in pagetitle_to_direcs:
                    direc = pagetitle_to_direcs[p.title]
                    assert direc in ["fixed", "paired", "intrans", "+p", "|ppp=-"]
                    origt = str(t)
                    if direc == "+p":
                        t.add("2", getparam(t, "2") + "+p")
                        notes.append("add missing past passive participle to transitive unpaired imperfective verb")
                        p.msg("Add missing PPP, replace %s with %s" % (origt, str(t)))
                    elif direc == "|ppp=-":
                        t.add("ppp", "-")
                        notes.append("note transitive unpaired imperfective verb as lacking past passive participle")
                        p.msg("Note no PPP, replace %s with %s" % (origt, str(t)))
                    elif direc == "paired":
                        p.msg("Verb actually is paired")
                    elif direc == "fixed":
                        p.msg("WARNING: Unfixed verb marked as fixed")
                    elif direc == "intrans":
                        p.msg("WARNING: Transitive verb marked as intrans")

    return str(parsed), notes


parser = blib.create_argparser(
    "Find verbs with missing past passive participles"
)
parser.add_argument("--fix-pagefile", help="File containing pages to fix.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_direcs = {}

if args.fix_pagefile:
    fixdireclines = [x.strip() for x in open(args.fix_pagefile, "r", encoding="utf-8")]
    for line in fixdireclines:
        verb, direc = re.split(" ", line)
        pagetitle_to_direcs[verb] = direc
    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, default_pages=list(pagetitle_to_direcs.keys())
    )
else:
    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, default_cats=["Russian verbs"]
    )
