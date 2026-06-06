#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    head_template_tr = None
    head_auto_tr = None
    noun_head_template = None
    saw_ndecl = False
    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        origt = str(t)
        if tn == "head":
            langcode = getp("1")
            form = getp("head") or p.title
        elif tn == "plural of":
            langcode = getp("1")
            form = getp("3") or getp("2")
        else:
            continue
        if not form:
            continue
        tr = getp("tr")
        if not tr:
            continue
        if tn == "head":
            tndesc = "{{%s|%s|%s}}" % (tn, langcode, getp("2"))
        else:
            tndesc = "{{%s|%s}}" % (tn, langcode)
        multi_trs = False
        for i in range(2, 10):
            if getparam(t, "tr%s" % i):
                multi_trs = True
                # We might have tr=some special translit and tr2=the default one, and in that case
                # we don't want to remove tr2= even though it appears redundant.
                p.msg("WARNING: Multiple translits, not changing: %s" % str(t))
                break
        if multi_trs:
            continue
        autotr = p.expand_text("{{xlit|%s|%s}}" % (langcode, form))
        if autotr is not None:
            if autotr == tr:
                p.msg("Removing redundant translit tr=%s for form %s" % (tr, form))
                rmparam(t, "tr")
                notes.append("remove redundant tr=%s from %s" % (tr, tndesc))
            else:
                p.msg("Page has non-redundant translit tr=%s vs. auto-tr=%s in %s" % (tr, autotr, tndesc))
        if str(t) != origt:
            p.msg("Replace %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove redundant translit from {{head}} and {{plural of}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
