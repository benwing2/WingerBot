#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, args.langname, p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    for k, header in subsecs.header_list:
        if header in poses:
            sectext = subsecs.subsections[k]
            defns = blib.find_defns(sectext, args.langcode)
            p.msg("%s: %s: %s" % (k, header, ";".join(defns)))


parser = blib.create_argparser(
    "Find definitions for specified POS and head templates", include_pagefile=True, include_stdin=True
)
parser.add_argument("--langname", help="Language name to check. If specified, only terms of the specified language will be done. Otherwise, the whole page (which may be a partial page without L2 headers) will be processed.")
parser.add_argument("--langcode", help="Language code of language to check.", required=True)
parser.add_argument("--pos", help="Comma-separated list of part of speec headers to check.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

poses = set(args.pos.split(","))
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
