#!/usr/bin/env python3

# Convert ru-ux to ux|ru or uxi|ru (depending on whether inline= is present).
# In the process, convert sub= to subst=. Don't convert if one of the
# special-purpose params noadj=, noshto=, adj= or shto= is present (the
# latter two are obsolete).

import re

from wingerbot import blib
from wingerbot.blib import msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        if tname(t) == "ru-ux":
            origt = str(t)
            if t.has("noadj") or t.has("noshto"):
                p.msg("WARNING: Can't convert %s, has noadj= or noshto=" % origt)
            elif t.has("adj") or t.has("shto"):
                p.msg("WARNING: Can't convert %s, has adj= or shto=" % origt)
            else:
                tn = "ux"
                new_params = []
                for param in t.params:
                    pname = str(param.name)
                    pval = str(param.value)
                    if pname == "inline":
                        if pval and pval not in ["0", "n", "no", "false"]:
                            tn = "uxi"
                    elif re.search(r"^[0-9]+$", pname):
                        # move numbered params up by one
                        new_params.append((str(1 + int(pname)), param.value))
                    elif pname == "sub":
                        new_params.append(("subst", param.value))
                    else:
                        new_params.append((pname, param.value))
                del t.params[:]
                t.name = tn
                t.add("1", "ru")
                for pname, pval in new_params:
                    t.add(pname, pval)
                notes.append("Replace {{ru-ux}} with {{%s|ru}}" % tn)
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{ru-ux}} to {{ux|ru}} or {{uxi|ru}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:ru-ux"]
)
