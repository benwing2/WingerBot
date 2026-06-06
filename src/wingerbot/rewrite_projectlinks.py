#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname
from collections import defaultdict

seen_projects = defaultdict(int)


def process_text_on_page(p):
    if blib.page_should_be_ignored(p.title):
        return

    if not args.stdin:
        p.msg("Processing")

    notes = []
    subs = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        textparts = []
        if tn == "projectlinks":
            sc = getp("sc").strip()
            for i in range(1, 10):
                project = getp(str(i)).strip()
                if project:
                    page = getp("page%s" % i).strip()
                    label = getp("label%s" % i).strip()
                    lang = getp("lang%s" % i).strip()
                    textparts.append(
                        "* {{projectlink|%s%s%s%s%s}}"
                        % (
                            project,
                            "|%s" % page if page or label else "",
                            "|%s" % label if label else "",
                            "|lang=%s" % lang if lang else "",
                            "|sc=%s" % sc if sc else "",
                        )
                    )
            subs.append((str(t), "\n".join(textparts)))
            notes.append("replace {{projectlinks}} with multiple calls to {{projectlink}}")

    text = p.text
    for subfrom, subto in subs:
        text, replaced = blib.replace_in_text(text, subfrom, subto, p.msg)
        if not replaced:
            return

    # If {{projectlinks}} preceded by *, we would get two of them, so remove one.
    text = re.sub(r"^\* *(\* \{\{projectlink)", r"\1", text, 0, re.M)

    return text, notes


parser = blib.create_argparser(
    "Rewrite {{projectlinks}} using {{projectlink}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:projectlinks"]
)
