#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname

AC = "\u0301"
GR = "\u0300"
SUB = "\ufffd"


def decompose_bulgarian(text):
    # need to decompose grave-accented еЕиИ
    text = text.replace("ѝ", "и" + GR)
    text = text.replace("Ѝ", "И" + GR)
    text = text.replace("ѐ", "е" + GR)
    text = text.replace("Ѐ", "Е" + GR)
    return text


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "bg-IPA":
            if not getparam(t, "old"):
                continue
            pron = getparam(t, "1")
            if pron:
                pron = decompose_bulgarian(pron)
                pron = pron.replace(AC, SUB)
                pron = pron.replace(GR, AC)
                pron = pron.replace(SUB, GR)
                t.add("1", pron)
            rmparam(t, "old")
            notes.append("convert {{bg-IPA}} pronunciation to new style (flip acute and grave) and remove old=1")
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))
    return str(parsed), notes


parser = blib.create_argparser("Fix {{bg-IPA}} to new format")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_refs=["Template:bg-IPA"])
