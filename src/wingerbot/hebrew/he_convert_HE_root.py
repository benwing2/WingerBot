#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "HE root":
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if not re.search("^[0-9]+$", pn) and not pn != "tr":
                    p.msg("WARNING: Unrecognized param %s=%s: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            # ignore tr=
            roots = blib.fetch_param_chain(t, "1")
            newroots = []
            for root in roots:
                m = re.search("^(.*?)(<!--.*-->)$", root)
                if m:
                    root, comment = m.groups()
                else:
                    comment = ""
                root = "־".join(root)
                root = root.replace("ש־ׂ", "שׂ").replace("ש־ׁ", "שׁ").replace("ה־ּ", "הּ")
                newroots.append(root + comment)
            del t.params[:]
            blib.set_template_name(t, "he-rootbox")
            blib.set_param_chain(t, newroots, "1")
            notes.append("convert {{%s}} to {{he-rootbox}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{HE root}} to {{he-rootbox}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:HE root"]
)
