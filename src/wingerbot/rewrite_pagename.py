#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, tname, pname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in templates_to_do:
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if "{{{PAGENAME}}}" in pv or "{{{SUBPAGENAME}}}" in pv:
                    p.msg(
                        "WARNING: Saw triple-brace {{{PAGENAME}}} or {{{SUBPAGENAME}}}, not replacing: %s=%s" % (pn, pv)
                    )
                else:
                    changed = False
                    if "{{PAGENAME}}" in pv:
                        pv = pv.replace("{{PAGENAME}}", "{{p.title}}")
                        notes.append("replace {{PAGENAME}} with {{p.title}} in {{%s}}" % tn)
                        changed = True
                    if "{{SUBPAGENAME}}" in pv:
                        pv = pv.replace("{{SUBPAGENAME}}", "{{p.title}}")
                        notes.append("replace {{SUBPAGENAME}} with {{p.title}} in {{%s}}" % tn)
                        changed = True
                    if changed:
                        param.value = pv

        if args.verbose and origt != str(t):
            p.msg("Replaced %s with %s" % (origt.replace("\n", r"\n"), str(t).replace("\n", r"\n")))

    return str(parsed), notes


parser = blib.create_argparser(
    "Replace {{PAGENAME}} and {{SUBPAGENAME}} with {{pagename}} in specified templates",
)
parser.add_argument(
    "--templates",
    help="Comma-separated list of templates to process arguments of",
    default="head,l,l-self,l,m-self,lang",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
templates_to_do = set(args.templates.split(","))
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
