#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg
from wingerbot.latin import lalib


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    adv = adj_to_adv.get(p.title)
    if not adv:
        p.msg("WARNING: Can't find adverb for adjective p.title")
        return

    parsed = blib.parse_text(p.text)
    adj_template = None
    part_template = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-adj":
            if adj_template:
                p.msg("WARNING: Saw multiple adjective templates: %s and %s" % (str(adj_template), str(t)))
            else:
                adj_template = t
        if tn == "la-part":
            if part_template:
                p.msg("WARNING: Saw multiple participle templates: %s and %s" % (str(part_template), str(t)))
            else:
                part_template = t
    if adj_template and part_template:
        p.msg("Saw both %s and %s, modifying adjective" % (str(adj_template), str(part_template)))
    if adj_template:
        template_to_fix = adj_template
    elif part_template:
        template_to_fix = part_template
    else:
        p.msg("WARNING: Didn't see adjective or participle template")
        return
    existing_advs = blib.fetch_param_chain(template_to_fix, "adv", "adv")
    changed = False
    for i in range(len(existing_advs)):
        if lalib.remove_macrons(existing_advs[i]) == lalib.remove_macrons(adv):
            if existing_advs[i] != adv:
                p.msg("Updating macrons of %s -> %s in %s" % (existing_advs[i], adv, str(template_to_fix)))
                existing_advs[i] = adv
                changed = True
                notes.append("update macrons of adv=, changing %s -> %s" % (existing_advs[i], adv))
            else:
                p.msg("Already saw %s: %s" % (adv, str(template_to_fix)))
            break
    else:
        # no break
        existing_advs.append(adv)
        changed = True
        notes.append("add adv %s to adjective" % adv)
    if changed:
        origt = str(template_to_fix)
        blib.set_param_chain(template_to_fix, existing_advs, "adv", "adv")
        p.msg("Replaced %s with %s" % (origt, str(template_to_fix)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Add Latin adverbs to adjectives based on the output of find_latin_adj_for_adv.py",
)
parser.add_argument("--direcfile", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

adj_to_adv = {}
for i, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search("^(.*?) /// (.*?) /// .*? /// .*?$", line)
    if not m:
        msg("Line %s: Unrecognized line: %s" % (i, line))
        continue
    adv, adj = m.groups()
    adj_to_adv[lalib.remove_macrons(adj)] = adv

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_pages=list(adj_to_adv.keys())
)
