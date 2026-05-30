#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(index, pagetitle, pagetext):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if not args.stdin:
        pagemsg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(
        pagetext, None if args.partial_page else "Polish", pagemsg, force_final_nls=True
    )
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.subsection_headers:
        if header == "References":
            newsubsec = re.sub(r"^:?\*\s*\{\{R:pl:NKJP\}\}\n", "", subsections[k], 0, re.M)
            if newsubsec != subsections[k]:
                notes.append("remove {{R:pl:NKJP}} from Polish References section")
                subsections[k] = newsubsec
                if not subsections[k].strip():
                    subsections[k - 1] = ""
                    subsections[k] = ""
                    notes.append("remove now empty References section from Polish term")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Remove {{R:pl:NKJP}} from Polish terms", include_pagefile=True, include_stdin=True)
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
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
    default_cats=["Polish lemmas"],
    skip_ignorable_pages=True,
)
