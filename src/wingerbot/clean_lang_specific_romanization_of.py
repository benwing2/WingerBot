#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

templates_to_generalize = {
    "ban-romanization of": "ban",
    "got-romanization of": "got",
    "jv-romanization of": "jv",
    "mad-romanization of": "mad",
    "map-bms-romanization of": "map-bms",
    "pal-romanization of": "pal",
    "pal-romanization of Mani": ["pal", "Mani"],
    "pal-romanization of Phli": ["pal", "Phli"],
    "pal-romanization of Phlp": ["pal", "Phlp"],
    "pal-romanization of Phlv": ["pal", "Phlv"],
    "pgl-romanization of": "pgl",
    "rej-romanization of": "rej",
    "sas-romanization of": "sas",
    "su-romanization of": "su",
    "xlp-romanization of": "xlp",
    "xpi-romanization of": "xpi",
}


def process_text_on_page(p):
    p.msg("Processing")
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in templates_to_generalize:
            lang_params = templates_to_generalize[tn]
            if type(lang_params) is list:
                lang, sc = lang_params
            else:
                lang = lang_params
                sc = None
            # Fetch all params.
            params = []
            for param in t.params:
                pname = str(param.name)
                if pname.strip() != "lang":
                    params.append((pname, param.value, param.showkey))
            # Erase all params.
            del t.params[:]
            t.add("1", lang)
            if sc:
                t.add("sc", sc)
            # Put remaining parameters in order.
            for name, value, showkey in params:
                if re.search("^[0-9]+$", name):
                    t.add(str(int(name) + 1), value, showkey=showkey, preserve_spacing=False)
                else:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
            blib.set_template_name(t, "romanization of")
            notes.append("rename {{%s}} to {{romanization of|%s%s}}" % (tn, lang, sc and "|sc=%s" % sc or ""))

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Rename {{FOO-romanization of}} to {{romanization of|FOO}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    edit=True,
    stdin=True,
    default_refs=["Template:%s" % template for template in sorted(templates_to_generalize.keys())],
)
