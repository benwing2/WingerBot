#!/usr/bin/env python3

# Remove unnecessary fr-adj parameters.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "fr-adj":
            g = getparam(t, "1")
            if g and g != "mf":
                p.msg("WARNING: Strange value 1=%s, removing: %s" % (g, str(t)))
                rmparam(t, "1")
                notes.append("remove bogus 1=%s" % g)
                g = None
            inv = getparam(t, "inv")
            if inv:
                if inv not in ["y", "yes", "1"]:
                    p.msg("WARNING: Strange value inv=%s: %s" % (inv, str(t)))
                if getparam(t, "1") or getparam(t, "f") or getparam(t, "mp") or getparam(t, "fp") or getparam(t, "p"):
                    p.msg("WARNING: Found extraneous params with inv=: %s" % str(t))
                continue
            if getparam(t, "f2") or getparam(t, "mp2") or getparam(t, "fp2") or getparam(t, "p2"):
                p.msg("Skipping multiple feminines or plurals: %s" % str(t))
                continue
            expected_mp = (
                p.title
                if re.search("[sx]$", p.title)
                else re.sub("al$", "aux", p.title) if p.title.endswith("al") else p.title + "s"
            )
            if getparam(t, "mp") == expected_mp:
                rmparam(t, "mp")
                notes.append("remove redundant mp=")
            expected_fem = (
                p.title
                if p.title.endswith("e")
                else (
                    p.title + "ne"
                    if p.title.endswith("en")
                    else (
                        re.sub("er$", "ère", p.title)
                        if p.title.endswith("er")
                        else (
                            p.title + "le"
                            if p.title.endswith("el")
                            else (
                                p.title + "ne"
                                if p.title.endswith("on")
                                else (
                                    p.title + "te"
                                    if p.title.endswith("et")
                                    else (
                                        p.title + "e"
                                        if p.title.endswith("ieur")
                                        else (
                                            re.sub("teur$", "trice", p.title)
                                            if p.title.endswith("teur")
                                            else (
                                                re.sub("eur$", "euse", p.title)
                                                if p.title.endswith("eur")
                                                else (
                                                    re.sub("eux$", "euse", p.title)
                                                    if p.title.endswith("eux")
                                                    else (
                                                        re.sub("if$", "ive", p.title)
                                                        if p.title.endswith("if")
                                                        else (
                                                            re.sub("c$", "que", p.title)
                                                            if p.title.endswith("c")
                                                            else p.title + "e"
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
            if re.search("(el|on|et|[^i]eur|eux|if|c)$", p.title) and not getparam(t, "f") and g != "mf":
                p.msg("WARNING: Found suffix -el/-on/-et/-[^i]eur/-eux/-if/-c and no f= or 1=mf: %s" % str(t))
            if getparam(t, "f") == expected_fem:
                rmparam(t, "f")
                notes.append("remove redundant f=")
            fem = getparam(t, "f") or expected_fem
            if not fem.endswith("e"):
                if not getparam(t, "fp"):
                    p.msg("WARNING: Found f=%s not ending with -e and no fp=: %s" % (fem, str(t)))
                continue
            expected_fp = fem + "s"
            if getparam(t, "fp") == expected_fp:
                rmparam(t, "fp")
                notes.append("remove redundant fp=")
            if getparam(t, "fp") and not getparam(t, "f"):
                p.msg("WARNING: Found fp=%s and no f=: %s" % (getparam(t, "fp"), str(t)))
                continue
            if getparam(t, "fp") == fem:
                p.msg("WARNING: Found fp=%s same as fem=%s: %s" % (getparam(t, "fp"), fem, str(t)))
                continue
            if p.title.endswith("e") and not getparam(t, "f") and not getparam(t, "fp"):
                if g == "mf":
                    rmparam(t, "1")
                    notes.append("remove redundant 1=mf")
                g = "mf"
            if g == "mf":
                f = getparam(t, "f")
                if f:
                    p.msg("WARNING: Found f=%s and 1=mf: %s" % (f, str(t)))
                mp = getparam(t, "mp")
                if mp:
                    p.msg("WARNING: Found mp=%s and 1=mf: %s" % (mp, str(t)))
                fp = getparam(t, "fp")
                if fp:
                    p.msg("WARNING: Found fp=%s and 1=mf: %s" % (fp, str(t)))
                if f or mp or fp:
                    continue
                expected_p = (
                    p.title
                    if re.search("[sx]$", p.title)
                    else re.sub("al$", "aux", p.title) if p.title.endswith("al") else p.title + "s"
                )
                if getparam(t, "p") == expected_p:
                    rmparam(t, "p")
                    notes.append("remove redundant p=")
            elif getparam(t, "p"):
                p.msg("WARNING: Found unexpected p=%s: %s" % (getparam(t, "p"), str(t)))
            if not re.search("[ -]", p.title) and (
                getparam(t, "f") or getparam(t, "mp") or getparam(t, "fp") or getparam(t, "p")
            ):
                p.msg("Found remaining explicit feminine or plural in single-word base form: %s" % str(t))
        newt = str(t)
        if origt != newt:
            p.msg("Replacing %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Remove extraneous params from {{fr-adj}}", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["French adjectives"]
)
