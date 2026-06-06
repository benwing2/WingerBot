#!/usr/bin/env python3

import re
from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg

label_params_by_count = defaultdict(int)
label_params_with_underscores_by_count = defaultdict(int)


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Chinese", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    if re.search(r"\{\{(%s)\|" % "|".join(blib.label_templates), secbody):
        parsed = blib.parse_text(secbody)

        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in blib.label_templates and getparam(t, "1") == "zh":
                label_params = blib.fetch_param_chain(t, "2")
                for param in label_params:
                    label_params_by_count[param] += 1
                for i in range(0, len(label_params) - 2):
                    if label_params[i + 1] == "_" and re.search("^[A-Z]", label_params[i + 2]):
                        param_set = (label_params[i], label_params[i + 1], label_params[i + 2])
                        label_params_with_underscores_by_count[param_set] += 1


parser = blib.create_argparser(
    "Find Chinese labels with underscores between them"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

msg("%-50s %5s" % ("Label combination", "Count"))
msg("-" * 56)
for k, v in sorted(label_params_with_underscores_by_count.items(), key=lambda x: -x[1]):
    msg("%-50s %5s" % ("|".join(k), v))

msg("")
msg("%-50s %5s" % ("Label", "Count"))
msg("-" * 56)
for k, v in sorted(label_params_by_count.items(), key=lambda x: -x[1]):
    msg("%-50s %5s" % (k, v))
