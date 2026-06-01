#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        if tn == "pl-decl-adj-ki":
            param1 = getp("1")
            param2 = getp("2")
            blib.set_template_name(t, "pl-decl-adj-auto")
            rmparam(t, "2")
            rmparam(t, "1")
            if ":" in p.title and p.title != param1 + "ki":
                p.msg("WARNING: Param 1=%s doesn't agree with p.title: %s" % (param1, origt))
                t.add("1", param1 + "ki")
            if param2:
                t.add("olddat", param2)
            notes.append("Convert {{pl-decl-adj-ki}} to {{pl-decl-adj-auto}}")
        elif tn in ["pl-decl-adj-y", "pl-adj-y"]:
            if getp("head"):
                p.msg("WARNING: Saw head=, not changing: %s" % origt)
            else:
                param1 = getp("1")
                blib.set_template_name(t, "pl-decl-adj-auto")
                rmparam(t, "2")
                rmparam(t, "1")
                if ":" in p.title and p.title != param1 + "y":
                    p.msg("WARNING: Param 1=%s doesn't agree with p.title: %s" % (param1, origt))
                    t.add("1", param1 + "y")
                notes.append("Convert {{%s}} to {{pl-decl-adj-auto}}" % tn)
        elif tn == "pl-decl-adj-i":
            param1 = getp("1")
            param2 = getp("2")
            blib.set_template_name(t, "pl-decl-adj-auto")
            rmparam(t, "2")
            rmparam(t, "1")
            if param1:
                if param2 in ["g", "gi"]:
                    should_pagetitle = param1 + "gi"
                elif param2 in ["l", "li"]:
                    should_pagetitle = param1 + "li"
                else:
                    should_pagetitle = param1 + "i"
                if ":" in p.title and p.title != should_pagetitle:
                    p.msg(
                        "WARNING: Param 1=%s doesn't agree with p.title (p.title should be %s): %s"
                        % (param1, should_pagetitle, origt)
                    )
                    t.add("1", should_pagetitle)
            notes.append("Convert {{pl-decl-adj-i}} to {{pl-decl-adj-auto}}")
        elif tn == "pl-decl-adj-owy":
            param1 = getp("1")
            blib.set_template_name(t, "pl-decl-adj-auto")
            rmparam(t, "2")
            rmparam(t, "1")
            if ":" in p.title and p.title != param1 + "owy":
                p.msg("WARNING: Param 1=%s doesn't agree with p.title: %s" % (param1, origt))
                t.add("1", param1 + "owy")
            notes.append("Convert {{pl-decl-adj-owy}} to {{pl-decl-adj-auto}}")

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{pl-decl-adj-*}} to {{pl-decl-adj-auto}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    new=True,
    default_refs=[
        "Template:pl-decl-adj-ki",
        "Template:pl-decl-adj-y",
        "Template:pl-decl-adj-i",
        "Template:pl-decl-adj-owy",
    ],
)
