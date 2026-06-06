#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "t-simple":
            interwiki = getparam(t, "interwiki")
            rmparam(t, "interwiki")
            rmparam(t, "langname")
            g = getparam(t, "g")
            rmparam(t, "g")
            if g:
                t.add("3", g)
            if t.has("3") and not getparam(t, "3"):
                rmparam(t, "3")
            lang = getparam(t, "1")
            link = getparam(t, "2")
            alt = getparam(t, "alt")
            trans = alt or link
            tr = getparam(t, "tr")
            if tr and lang and trans and not args.no_remove_redundant_translit:
                autotr = p.expand_text("{{xlit|%s|%s}}" % (lang, trans))
                if autotr and autotr == tr:
                    p.msg("Removing redundant translit %s of %s for lang %s" % (tr, trans, lang))
                    rmparam(t, "tr")
                    notes.append("remove redundant translit from {{t-simple}}")
            if alt and link:
                autolink = p.expand_text("{{#invoke:languages/templates|makeEntryName|%s|%s}}" % (lang, alt))
                if autolink and autolink == link:
                    p.msg("Removing redundant alt form %s of %s for lang %s" % (alt, link, lang))
                    t.add("2", alt)
                    rmparam(t, "alt")
                    notes.append("move redundant alt= to 2= in {{t-simple}}")
            if interwiki:
                tempname = "t+"
            else:
                tempname = "t"
            blib.set_template_name(t, tempname)
            notes.append("convert {{t-simple}} to {{%s}}" % tempname)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{t-simple}} to {{t}} or {{t+}}")
parser.add_argument(
    "--no-remove-redundant-translit", help="Don't remove redundant transliterations", action="store_true"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
