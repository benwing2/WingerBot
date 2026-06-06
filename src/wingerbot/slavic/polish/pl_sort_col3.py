#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Polish", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    col3_splits = re.split(r"^((?:\{\{col3\|pl\|[^{}\n]*\}\}\n)+)", secbody, 0, re.M)
    for k in range(1, len(col3_splits), 2):
        col3_split = col3_splits[k].rstrip("\n").split("\n")
        decorated_lines = []
        must_continue = False
        for line in col3_split:
            m = re.search(r"\|title=([^{}|\n]*)[|}]", line)
            if not m:
                p.msg("WARNING: Saw {{col3|pl}} line but couldn't extract part of speech from title=: %s" % line)
                must_continue = True
                break
            decorated_lines.append((m.group(1), line))
        if must_continue:
            continue
        new_col3_splits = "\n".join(line for _, line in sorted(decorated_lines)) + "\n"
        if new_col3_splits != col3_splits[k]:
            notes.append("sort {{col3|pl}} lines by title (part of speech)")

            def quote_nl(text):
                return p.text.replace("\n", r"\n")

            p.msg("Replaced <%s> with <%s>" % (quote_nl(col3_splits[k]), quote_nl(new_col3_splits)))
            col3_splits[k] = new_col3_splits

    return modsec.rebuild(secbody="".join(col3_splits)), notes


parser = blib.create_argparser(
    "Sort {{col3|pl}} lines by title (part of speech)"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Polish lemmas"]
)
