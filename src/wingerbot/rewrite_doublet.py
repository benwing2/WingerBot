#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import tname

# WARNING: Not idempotent.


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    if blib.page_should_be_ignored(p.title):
        p.msg("WARNING: Page should be ignored")
        return

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        if tn == "doublet":
            params = []
            for param in t.params:
                pname = str(param.name).strip()
                pval = str(param.value).strip()
                showkey = param.showkey
                if not pval:
                    continue
                if pname == "3":
                    pname = "alt1"
                    showkey = True
                elif pname == "4":
                    pname = "t1"
                    showkey = True
                elif pname in ["t", "gloss", "tr", "ts", "pos", "lit", "alt", "sc", "id", "g"]:
                    pname = pname + "1"
                elif pname in ["1", "2", "notext", "nocap", "nocat"]:
                    pass
                else:
                    p.msg("WARNING: Unrecognized param %s=%s in %s, skipping" % (pname, pval, origt))
                    break
                params.append((pname, pval, showkey))
            else:  # No break
                # Erase all params.
                del t.params[:]
                # Put back new params.
                for pname, pval, showkey in params:
                    t.add(pname, pval, showkey=showkey, preserve_spacing=False)
                if origt != str(t):
                    p.msg("Replaced %s with %s" % (origt, str(t)))
                    notes.append("restructure {{doublet}} for new syntax")

    return str(parsed), notes


parser = blib.create_argparser(
    "Rewrite 'doublet' to use multiple-term syntax"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:doublet"]
)
