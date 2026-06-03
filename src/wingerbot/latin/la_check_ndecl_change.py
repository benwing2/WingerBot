#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site
from wingerbot.latin import lalib


def compare_new_and_old_templates(t, pagetitle, pagemsg, errandpagemsg):
    def expand_text(tempcall):
        return blib.expand_text(tempcall, pagetitle, pagemsg, args.verbose)

    def generate_old_forms():
        old_generate_template = re.sub(r"^\{\{la-ndecl\|", "{{la-generate-noun-forms|", t)
        old_generate_template = re.sub(r"^\{\{la-adecl\|", "{{la-generate-adj-forms|", old_generate_template)
        old_result = expand_text(old_generate_template)
        if not old_result:
            return None
        return old_result

    def generate_new_forms():
        new_generate_template = re.sub(r"^\{\{la-ndecl\|", "{{User:Benwing2/la-new-generate-noun-forms|", t)
        new_generate_template = re.sub(
            r"^\{\{la-adecl\|", "{{User:Benwing2/la-new-generate-adj-forms|", new_generate_template
        )
        new_result = expand_text(new_generate_template)
        if not new_result:
            return None
        return new_result

    return blib.compare_new_and_old_template_forms(t, t, generate_old_forms, generate_new_forms, pagemsg, errandpagemsg)


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-ndecl" or tn == "la-adecl":
            compare_new_and_old_templates(str(t), p.title, p.msg, p.errandmsg)


parser = blib.create_argparser(
    "Check potential changes to {{la-ndecl}} or {{la-adecl}} implementation", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:la-ndecl", "Template:la-adecl"]
)
