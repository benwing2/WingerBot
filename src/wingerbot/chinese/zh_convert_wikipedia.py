#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)

    notes = []

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param).strip()

        if tn in ["zh-wikipedia", "zh-wp"]:
            links = blib.fetch_param_chain(t, "1") or ["zh"]
            newlinks = []
            prevlang = "en"
            for link in links:
                if ":" in link:
                    lang, linkval = link.split(":", 1)
                else:
                    lang = link
                    linkval = ""
                if lang == prevlang:
                    lang = ""
                if lang:
                    prevlang = lang
                    newlink = "%s:%s" % (lang, linkval)
                elif linkval:
                    newlink = linkval
                else:
                    newlink = "+"
                newlinks.append(newlink)

            origt = str(t)
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if not re.search("^[0-9]+$", pn):
                    p.msg("WARNING: Unrecognized param %s=%s" % (pn, str(param.value)))
                    must_continue = True
                    break
            if must_continue:
                continue

            del t.params[:]
            if newlinks:
                t.add("1", ",".join(newlinks))
            blib.set_template_name(t, "wp")
            notes.append("convert {{%s}} to {{wp}}" % tn)

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{zh-wikipedia}}/{{zh-wp}} to {{wp}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
