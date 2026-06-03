#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, getparam, addparam, tname
from wingerbot.arabic.arlib import (
    TAM,
    reorder_shadda,
    arabic_decl_templates,
)


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        head = reorder_shadda(getparam(t, "1"))
        tn = tname(t)
        if tn.startswith("ar-decl-"):
            param = "pl"
            pl = getparam(t, param)
            i = 2
            while pl:
                if pl == "smp":
                    if head.endswith(TAM):
                        p.msg(
                            "WARNING: Found %s=smp with feminine ending head %s in %s: not changing"
                            % (param, head, tn)
                        )
                    else:
                        p.msg("Changing %s=smp to %s=sp in %s" % (param, param, tn))
                        addparam(t, param, "sp")
                param = "pl%s" % i
                pl = getparam(t, param)
                i += 1
    changelog = "Change pl=smp to pl=sp"
    return str(parsed), changelog


parser = blib.create_argparser("Change |pl=smp to |pl=sp in declension templates", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
                           default_refs=["Template:%s" % template for template in arabic_decl_templates])
