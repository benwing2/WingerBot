#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "col":

            def getp(param):
                return getparam(t, param)

            n = getp("n")
            if n:
                continue
            params = []
            for param in t.params:
                pname = str(param.name)
                params.append((pname, param.value, param.showkey))
            # Erase all params.
            del t.params[:]
            # Put remaining parameters in order.
            for name, value, showkey in params:
                sname = name.strip()
                if sname == "2":
                    t.add("n", value, preserve_spacing=False)
                elif re.search("^[0-9]+$", sname) and int(sname) > 2:
                    t.add(str(int(sname) - 1), value, showkey=showkey, preserve_spacing=False)
                else:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
            notes.append("move 2= to n= in {{%s}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Move 2= to n= in {{col}}", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True, default_refs=["Template:col"])
