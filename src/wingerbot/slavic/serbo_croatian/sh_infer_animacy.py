#!/usr/bin/env python3

from collections import defaultdict
import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname

from wingerbot.lang_utils import sh_remove_accents


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    notes = []

    def is_masc(g):
        g = g.split(",")
        return any(x == "m" for x in g)

    parsed = blib.parse_text(text)
    headt = None
    declt = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["sh-noun", "sh-propn", "sh-proper noun"]:
            if headt:
                either_masc = is_masc(getparam(headt, "2")) or is_masc(getparam(t, "2"))
                pagemsg(
                    "WARNING: Saw two headword templates: %s and %s%s; not taking action"
                    % (str(headt), str(t), " (but neither is masculine)" if not either_masc else "")
                )
                return
            headt = t
        if tn in [
            "sh-decl-noun",
            "sh-decl-noun-unc",
            "sh-decl-noun-plural",
            "sh-decl-noun-fem-a",
            "sh-decl-noun-m",
            "sh-decl-noun-n-o",
            "sh-decl-noun-n-e",
        ]:
            if declt:
                pagemsg(
                    "WARNING: Saw two declension templates: {{%s}} and {{%s}}; not taking action" % (tname(declt), tn)
                )
                return
            declt = t
    if headt and declt:

        def hgetp(param):
            return getparam(headt, param).strip()

        def dgetp(param):
            return getparam(declt, param).strip()

        g = hgetp("2")
        if g == "m":
            if tname(declt) in ["sh-decl-noun", "sh-decl-noun-unc"]:
                nom_s = dgetp("1")
                gen_s = dgetp("3") if tname(declt) == "sh-decl-noun" else dgetp("2")
                acc_s = dgetp("7") if tname(declt) == "sh-decl-noun" else dgetp("4")
                if sh_remove_accents(acc_s) == sh_remove_accents(nom_s):
                    pagemsg(
                        "Accusative singular %s same as nominative singular %s, inferring inanimate" % (acc_s, nom_s)
                    )
                    headt.add("2", "m-in")
                    notes.append(
                        "infer gender m-in in {{%s}} from declension template {{%s}}, acc == nom"
                        % (tname(headt), tname(declt))
                    )
                elif sh_remove_accents(acc_s) == sh_remove_accents(gen_s):
                    pagemsg("Accusative singular %s same as genitive singular %s, inferring animate" % (acc_s, gen_s))
                    headt.add("2", "m-an")
                    notes.append(
                        "infer gender m-an in {{%s}} from declension template {{%s}}, acc == gen"
                        % (tname(headt), tname(declt))
                    )
                else:
                    pagemsg(
                        "WARNING: Accusative singular %s different from both nominative singular %s and genitive singular %s, can't infer gender: %s"
                        % (acc_s, nom_s, gen_s, str(headt))
                    )
            elif tname(declt) in ["sh-decl-noun-m"]:
                headt.add("2", "m-in")
                notes.append(
                    "infer gender m-in in {{%s}} from declension template {{%s}}" % (tname(headt), tname(declt))
                )
            else:
                pagemsg(
                    "WARNING: Can't infer animacy for masculine noun, wrong declension template {{%s}}" % tname(declt)
                )

    return str(parsed), notes


parser = blib.create_argparser(
    "Infer animacy for masculine Serbo-Croatian noun based on declension", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
