#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        if tn == "%s-verb-old" % args.lang:
            origt = str(t)
            inf = getp("inf")
            if inf:
                t.add("head", inf, before="inf")
            rmparam(t, "inf")
            a = getp("a")
            if a == "p":
                a = "pf"
            elif a == "i":
                a = "impf"
            elif a in ["b", "p-i", "both"]:
                a = "both"
            else:
                p.msg("WARNING: Bad aspect a=%s" % a)
                continue
            if a:
                t.add("a", a)
            else:
                rmparam(t, "a")
            aa = blib.fetch_param_chain(t, "aa")
            if aa:
                if a == "pf":
                    blib.remove_param_chain(t, "aa")
                    blib.set_param_chain(t, aa, "impf")
                elif a == "impf":
                    blib.remove_param_chain(t, "aa")
                    blib.set_param_chain(t, aa, "pf")
                else:
                    p.msg("WARNING: No aspect when aa= given")
                    continue
            rmparam(t, "1")
            rmparam(t, "2")
            rmparam(t, "3")
            blib.set_template_name(t, "%s-verb" % args.lang)
            p.msg("Replaced %s with %s" % (origt, str(t)))
            notes.append("rename {{%s-verb-old}} to {{%s-verb}} and standardize params" % (args.lang, args.lang))

    text = str(parsed), notes


parser = blib.create_argparser(
    "Rename {{cs-verb-old}}/{{sk-verb-old}} to {{cs-verb}}/{{sk-verb}} and clean/standardize parameters",
)
parser.add_argument("--lang", choices=["cs", "sk"], help="Language of verbs (cs, sk).")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:%s-verb-old" % args.lang]
)
