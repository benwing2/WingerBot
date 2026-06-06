#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname
from wingerbot.latin import lalib


def check_participle(p, formval):
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-part":
            actual_part = re.sub("/.*", "", getparam(t, "1"))
            if actual_part != formval:
                p.msg("WARNING: Found actual participle %s, expected %s" % (actual_part, formval))


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-conj":
            vargs = lalib.generate_verb_forms(str(t), p.errandmsg, p.expand_text)
            if vargs is None:
                continue
            single_forms_to_process = lalib.flatten_slot_formvals(
                p.index, p.title, vargs, slots_to_do=[
                    "pres_actv_ptc", "perf_actv_ptc", "perf_pasv_ptc", "futr_actv_ptc", "futr_pasv_ptc"
                ]
            )
            for slotformind, slotformtitle, slot, formval in single_forms_to_process:
                if "[" in formval or "|" in formval:
                    p.msg("Skipping form with brackets or vertical bar: %s" % formval)
                    continue
                def do_check_participle(p):
                    return check_participle(p, formval)
                blib.do_edit(args, slotformind, lalib.remove_macrons(formval), do_check_participle, must_exist=True,
                             msg_title=slotformtitle)


parser = blib.create_argparser(
    "Check macrons of Latin verbs against participles"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Latin verbs"])
