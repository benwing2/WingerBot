#!/usr/bin/env python3

# Convert Japanese headwords from old-style to new-style. We look at
# ja-noun, ja-adj, ja-verb and ja-pos.
#
# 1. If the first parameter is one of 'r', 'h', 'ka', 'k', 's', 'ky' or 'kk',
#    remove it and move the other numbered parameters down one.
# 2. Convert hira= and kata= to numbered parameters -- make them the first
#    empty numbered param.
# 3. If rom= is present and the page isn't in
#    [[:Category:Japanese terms with romaji needing attention]], remove rom=.

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    notes = []
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["ja-noun", "ja-adj", "ja-verb", "ja-pos"]:
            origt = str(t)

            # Remove old script code
            p1 = getparam(t, "1")
            if p1 in ["r", "h", "ka", "k", "s", "ky", "kk"]:
                p.msg("Removing 1=%s: %s" % (p1, str(t)))
                notes.append("remove 1=%s from %s" % (p1, tn))
                rmparam(t, "1")
                for param in t.params:
                    pname = str(param.name)
                    if re.search(r"^[0-9]+$", pname):
                        param.name = str(int(pname) - 1)
                        param.showkey = False

            # Convert hira= and/or kata= to numbered param. The complexity is
            # from ensuring that the numbered params always go before the
            # non-numbered ones.
            if t.has("hira") or t.has("kata"):
                # Fetch the numbered and non-numbered params, skipping blank
                # numbered ones and converting hira and kata to numbered
                numbered_params = []
                non_numbered_params = []
                for param in t.params:
                    pname = str(param.name)
                    if re.search(r"^[0-9]+$", pname):
                        val = str(param.value)
                        if val:
                            numbered_params.append(val)
                    elif pname not in ["hira", "kata"]:
                        non_numbered_params.append((pname, param.value))
                hira = getparam(t, "hira")
                if hira:
                    numbered_params.append(hira)
                    p.msg("Moving hira=%s to %s=: %s" % (hira, len(numbered_params), str(t)))
                    notes.append("move hira= to %s= in %s" % (len(numbered_params), tn))
                kata = getparam(t, "kata")
                if kata:
                    numbered_params.append(kata)
                    p.msg("Moving kata=%s to %s=: %s" % (kata, len(numbered_params), str(t)))
                    notes.append("move kata= to %s= in %s" % (len(numbered_params), tn))
                del t.params[:]
                # Put back numbered params, then non-numbered params.
                for i, param in enumerate(numbered_params):
                    t.add(str(i + 1), param)
                for name, value in non_numbered_params:
                    t.add(name, value)

            # Remove rom= if not in list of pages to keep rom=
            if t.has("rom"):
                if p.title in romaji_to_keep:
                    p.msg("Keeping rom=%s because in romaji_to_keep: %s" % (getparam(t, "rom"), str(t)))
                else:
                    p.msg("Removing rom=%s: %s" % (getparam(t, "rom"), str(t)))
                    rmparam(t, "rom")
                    notes.append("remove rom= from %s" % tn)

            # Remove hidx=
            if t.has("hidx"):
                p.msg("Removing hidx=%s: %s" % (getparam(t, "hidx"), str(t)))
                rmparam(t, "hidx")
                notes.append("remove hidx= from %s" % tn)

            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert Japanese headwords from old-style to new-style", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

romaji_to_keep = set()
for i, page in blib.cat_articles("Japanese terms with romaji needing attention"):
    pagetitle = page.title()
    romaji_to_keep.add(pagetitle)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    new=True,
    default_refs=["Template:%s" % ref for ref in ["ja-noun", "ja-adj", "ja-verb", "ja-pos"]],
)
