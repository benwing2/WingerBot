#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, getparam, addparam, tname
from wingerbot.arabic.arlib import (
    TAM,
    reorder_shadda,
    arabic_decl_templates,
)


def fix_smp(save, verbose, start, end):
    for template in arabic_decl_templates:
        # Fix the template refs. If cap= is present, remove it; else, add lc=.
        def fix_one_page_smp(index, page):
            pagetitle = page.title()
            def pagemsg(txt):
                msg("Page %s %s: %s" % (index, pagetitle, txt))
            def errandpagemsg(txt):
                errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

            text = blib.safe_page_text(page, errandpagemsg)
            parsed = blib.parse_text(text)
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
                                pagemsg(
                                    "WARNING: Found %s=smp with feminine ending head %s in %s: not changing"
                                    % (param, head, tn)
                                )
                            else:
                                pagemsg("Changing %s=smp to %s=sp in %s" % (param, param, tn))
                                addparam(t, param, "sp")
                        param = "pl%s" % i
                        pl = getparam(t, param)
                        i += 1
            changelog = "Change pl=smp to pl=sp"
            return str(parsed), changelog

        for index, page in blib.references("Template:" + template, start, end):
            blib.do_edit(index, page, fix_one_page_smp, save=save, verbose=verbose)


parser = blib.create_argparser("Change |pl=smp to |pl=sp in declension templates")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

fix_smp(args.save, args.verbose, start, end)
