#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, set_template_name, msg, errmsg, site, tname

arabic_charset = "؀-ۿݐ-ݿࢠ-ࣿﭐ-﷽ﹰ-ﻼ"

templates_seen = {}
templates_changed = {}


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    def process_param(obj):
        t = obj.template
        if type(obj.param) is list:
            p.msg("WARNING: Skipping param %s referencing page title: %s" % (obj.param, str(t)))
            return
        if args.find:
            p.msg("Found %s" % str(t))
            return
        if obj.notforeign:
            p.msg("WARNING: Skipping template with not-foreign text, needs manual review: %s" % str(t))
            return
        pval = getparam(t, obj.param)
        if not pval or pval == "-":
            p.msg("Leaving as ku: %s" % str(t))
            return
        origt = str(t)
        lpar = obj.langparam
        if re.search("[%s]" % arabic_charset, getparam(t, obj.param)):
            if getparam(t, lpar) != "ku":
                p.msg(
                    "WARNING: %s=%s not ku, don't know how to change language: %s" % (lpar, getparam(t, lpar), str(t))
                )
                return
            t.add(lpar, "ckb")
            p.msg("Replaced %s with %s" % (origt, str(t)))
            return ["convert {{%s|ku}} to lang ckb based on Arabic script in param" % tname(t)]
        if getparam(t, lpar) != "ku":
            p.msg("WARNING: %s=%s not ku, don't know how to change language: %s" % (lpar, getparam(t, lpar), str(t)))
            return
        t.add(lpar, "kmr")
        p.msg("Replaced %s with %s" % (origt, str(t)))
        return ["convert {{%s|ku}} to lang kmr based on Latin script in param" % tname(t)]

    return blib.process_one_page_links(
        p.index, p.title, p.text, ["ku"], process_param, templates_seen, templates_changed, include_notforeign=True
    )


parser = blib.create_argparser(
    "Find or correct usages of language code 'ku'", include_pagefile=True, include_stdin=True
)
parser.add_argument("--find", action="store_true", help="Find usages only")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
blib.output_process_links_template_counts(templates_seen, templates_changed)
