#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, args.langname, p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(p.text, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "Anagrams" and k + 1 < len(subsections):
            subsections = subsections[0 : k - 1] + subsections[k + 1 : len(subsections)] + subsections[k - 1 : k + 1]
            notes.append("put Anagrams last in %s section" % args.langname)
            break

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("put Anagrams last", include_pagefile=True, include_stdin=True)
parser.add_argument("--langname", required=True, help="Language name.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
