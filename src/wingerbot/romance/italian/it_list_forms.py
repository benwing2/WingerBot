#!/usr/bin/env python3

import re, json, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg

AC = "\u0301"
GR = "\u0300"


def list_forms(template, errandpagemsg, expand_text):
    template = re.sub(r"\}\}$", "|json=1}}", template)
    forms = expand_text(template)
    if not forms:
        errandpagemsg("WARNING: Error generating forms, skipping: %s" % template)
        return None
    forms = json.loads(forms)["forms"]
    infinitive = forms["inf"][0]["form"]
    infinitive = unicodedata.normalize("NFD", blib.remove_links(infinitive))
    # Remove non-final accents
    infinitive = re.sub("[" + AC + GR + "](.)", r"\1", infinitive)
    infinitive = unicodedata.normalize("NFC", infinitive)
    for key, values in forms.items():
        for v in values:
            linktext = []
            displaytext = []
            parts = re.split(r"(\[\[.*?\]\])", v["form"])
            for i, part in enumerate(parts):
                if i % 2 == 0:
                    linktext.append(part)
                    displaytext.append(part)
                elif "|" in part:
                    link, display = part[2:-2].split("|")
                    linktext.append(link)
                    displaytext.append(display)
                else:
                    link = part[2:-2]
                    linktext.append(link)
                    displaytext.append(link)
            msg("%s\t%s\t%s\t%s" % (infinitive, key, "".join(linktext), "".join(displaytext)))


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "it-conj":
            pagename = getparam(t, "pagename") or p.title

            def expand_text(tempcall):
                return blib.expand_text(tempcall, pagename, p.msg, args.verbose)

            list_forms(getparam(t, "1"), p.errandmsg, expand_text)


parser = blib.create_argparser("List all forms of a verb")
parser.add_argument("--direcfile", help="File listing conjugations.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.direcfile:
    for lineno, line in blib.iter_items_from_file(args.direcfile):
        t = list(blib.parse_text(line).filter_templates())[0]
        def process_line(p):
            list_forms(line, p.errandmsg, p.expand_text)
        blib.do_edit(args, lineno, getparam(t, "pagename") or "NONE", process_line)
else:
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
