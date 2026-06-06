#!/usr/bin/env python3

# Fix up Russian usage examples:
#
# 1. Convert ux|ru|inline=y to uxi|ru.
# 2. Clean up links containing #Russian and/or two-part links that can be
#    simplified to one-part links because the two parts are identical
#    modulo accents.
# 3. Remove redundant transliteration.

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.slavic.russian import runounlib


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) == "ux" and getparam(t, "1") == "ru" and t.has("inline"):
            inline = getparam(t, "inline")
            if inline and inline not in ["0", "n", "no", "false"]:
                t.name = "uxi"
                notes.append("ux -> uxi and remove inline=")
            else:
                notes.append("remove unneeded inline=%s" % inline)
            rmparam(t, "inline")
        tn = tname(t)
        if tn in ["ux", "uxi"] and getparam(t, "1") == "ru":
            pval = getparam(t, "2")
            newpval = runounlib.fixup_link(pval)
            if pval != newpval:
                t.add("2", newpval)
                notes.append("canonicalize two-part links in %s|ru" % tn)
            pval = getparam(t, "tr")
            if pval:
                auto_translit = p.expand_text("{{xlit|ru|%s}}" % getparam(t, "2"))
                if auto_translit == pval:
                    rmparam(t, "tr")
                    notes.append("remove redundant translit in %s|ru" % tn)
                else:
                    p.msg("WARNING: Non-redundant translit in %s" % str(t))
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Remove inline=, converting ux|ru to uxi|ru as necessary, canonicalize two-part links and remove redundant translit",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian lemmas"]
)
