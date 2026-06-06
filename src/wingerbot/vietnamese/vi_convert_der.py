#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname, pname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "vi-der":
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if not re.search("^[0-9]+$", pn) and pn != "lang":
                    p.msg("WARNING: Unrecognized param %s=%s: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            # ignore lang=vi
            terms = blib.fetch_param_chain(t, "1")
            newterms = []
            for term in terms:
                m = re.search("^(.*?)(<!--.*-->)$", term)
                if m:
                    term, comment = m.groups()
                else:
                    comment = ""
                if term.endswith(":tl"):
                    term = term[:-3]
                    label = "<ll:tulay>"
                else:
                    label = ""
                m = re.search("^(.*?):(.*)$", term)
                if m:
                    term, gloss = m.groups()
                    gloss = "<t:%s>" % gloss
                else:
                    gloss = ""
                newterms.append(term + gloss + label + comment)
            del t.params[:]
            blib.set_template_name(t, "col")
            t.add("1", "vi")
            blib.set_param_chain(t, newterms, "2")
            notes.append("convert {{%s}} to {{col}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{vi-der}} to {{col|vi}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:vi-der"]
)
