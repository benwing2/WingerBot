#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        def convert_g(g):
            if g == "c":
                g = "mf"
            return g

        if tn == "el-see":
            named_params = []
            term = getp("1")
            g = convert_g(getp("g"))
            g2 = convert_g(getp("g2"))
            g3 = convert_g(getp("g3"))
            andval = getp("and")
            compare = getp("compare")
            noast = getp("noast")
            genders = ",".join(x for x in [g, g2, g3] if x)
            must_continue = False
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if pn in ["1", "g", "g2", "g3", "and", "compare", "noast"]:
                    continue
                if re.search("^[0-9]+$", pn):
                    p.msg("WARNING: Saw unrecognized numbered param %s=%s, skipping: %s" % (pn, pv, str(t)))
                    must_continue = True
                    break
                named_params.append((pn, pv))
            if must_continue:
                continue
            rmparam(t, "1")
            rmparam(t, "g")
            rmparam(t, "g2")
            rmparam(t, "g3")
            rmparam(t, "and")
            rmparam(t, "compare")
            rmparam(t, "noast")
            del t.params[:]
            t.add("1", "el")
            if noast:
                t.add("noast", noast)
            if andval:
                t.add("and", andval)
            if compare:
                t.add("compare", compare)
            if term:
                t.add("2", term)
            if genders:
                t.add("g", genders)
            for pn, pv in named_params:
                t.add(pn, pv, preserve_spacing=False)
            blib.set_template_name(t, "see")
            notes.append("replace {{el-see}} with {{see|el}}")
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{el-see}} to {{see|el}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:el-see"]
)
