#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "de-conj":
            generate_template = re.sub(r"^\{\{de-conj(?=[|}])", "{{User:Benwing2/de-generate-verb-props", str(t))
            result = p.expand_text(generate_template)
            if not result:
                continue
            forms = blib.split_generate_args(result)
            p.msg("For %s, class=%s" % (str(t), forms["class"]))

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert German verb headwords to use new {{de-verb}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_refs=["Template:de-conj"]
)
