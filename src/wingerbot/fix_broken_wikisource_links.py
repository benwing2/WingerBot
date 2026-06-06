#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    notes = []

    def frob(value, wherefrom):
        for refrom, reto in subs:
            newvalue = re.sub(refrom, reto, value)
            if newvalue != value:
                notes.append("replace '%s' -> '%s' in %s" % (refrom, reto, wherefrom))
                return newvalue
        return value

    def frobparam(t, param):
        value = getparam(t, param)
        if value:
            newvalue = frob(value, "{{%s|%s=}}" % (tname(t), param))
            if newvalue != value:
                t.add(param, newvalue)

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["R:wsource"]:
            frobparam(t, "2")
            frobparam(t, "dab")
        elif tn in ["wsource"]:
            frobparam(t, "1")
        elif tn in ["wikisource"]:
            frobparam(t, "1")
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    text = str(parsed)
    newtext = re.sub(
        r"url=(\[(s|wikisource):.*?\])", lambda m: "urls=[%s]" % m.group(1).replace("{{!}}", "|"), text
    )
    if newtext != text:
        notes.append("convert url=(hacked-up Wikisource link) to urls=(proper Wikisouce link)")
        text = newtext
    newtext = text
    newtext = re.sub(
        r"\[\[(s|wikisource):([^][|]*?)\]\]",
        lambda m: "[[%s:%s]]" % (m.group(1), frob(m.group(2).replace("_", " "), "[[%s:...]]" % m.group(1))),
        newtext,
    )
    newtext = re.sub(
        r"\[\[(s|wikisource):([^][|]*?)\|([^][|]*?)\]\]",
        lambda m: "[[%s:%s|%s]]"
        % (m.group(1), frob(m.group(2).replace("_", " "), "[[%s:...]]" % m.group(1)), m.group(3)),
        newtext,
    )
    if newtext != text and not notes:
        notes.append("convert _ to space in [[s:...]]/[[wikisource:...]]")
    text = newtext

    return text, notes


parser = blib.create_argparser("Fix broken Wikisource links")
parser.add_argument("--direcfile", help="File containing regex substitutions of the form 'FROM ||| TO'", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

subs = []
for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    refrom, reto = line.split(" ||| ")
    subs.append((refrom, reto))


blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
