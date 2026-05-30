#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(
        text, None if args.partial_page else "German", pagemsg, force_final_nls=True
    )
    if modsec is None:
        return

    secbody = modsec.secbody
    if "Etymology 1" in secbody:
        pagemsg("WARNING: Can't handle Etymology 1")
        return

    while True:
        did_move = False
        subsecs = blib.split_text_into_subsections(secbody, pagemsg)
        subsections = subsecs.subsections
        # Look for a participle and move it up.
        for k, header in subsecs.subsection_headers:
            if header == "Participle":
                l = k
                while l > 2 and (
                    subsecs.subsection_header_dict[l - 2] in ["Adjective", "Adverb"]
                    or subsecs.subsection_header_dict[l - 2] == "Verb"
                    and re.search(r"\{\{head\|de\|verb form", subsections[l - 2])
                ):
                    l -= 2
                if l < k:
                    participle_text = subsections[k - 1 : k + 1]
                    subsections[k - 1 : k + 1] = subsections[l - 1 : k - 1]
                    subsections[l - 1 : k - 1] = participle_text
                    notes.append("move Participle section above Adjective/Adverb/Verb form sections")
                    did_move = True
                    break
        secbody = "".join(subsections)

        subsecs = blib.split_text_into_subsections(secbody, pagemsg)
        subsections = subsecs.subsections
        # Look for a verb form and move it down.
        for k, header in subsecs.subsection_headers:
            if header == "Verb" and re.search(r"\{\{head\|de\|verb form", subsections[k]):
                l = k
                while l < len(subsections) - 2 and subsecs.subsection_header_dict[l + 2] in ["Adjective", "Adverb", "Participle"]:
                    l += 2
                if l > k:
                    non_verb_form_text = subsections[k + 1 : l + 1]
                    subsections[k + 1 : l + 1] = subsections[k - 1 : k + 1]
                    subsections[k - 1 : k + 1] = non_verb_form_text
                    notes.append("move Verb form section below Adjective/Adverb/Participle sections")
                    did_move = True
                    break
        secbody = "".join(subsections)

        if not did_move:
            break

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Reorder German participles to be before adjectives/adverbs/verb forms, and verb forms to be after adjectives/adverbs/participles",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang German' and has no ==German== header.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
