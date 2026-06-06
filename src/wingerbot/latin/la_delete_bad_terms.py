#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, tname

pages_to_delete = []


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    sections, j, secbody, sectail = modsec.props()

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    saw_head = False
    saw_bad_template = False
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in expected_head_templates:
                saw_head = True
            elif tn in ["inflection of", "rfdef", "la-IPA"]:
                pass
            else:
                p.msg(
                    "WARNING: Saw unrecognized template in subsection #%s %s: %s"
                    % (k // 2, subsections[k - 1].strip(), str(t))
                )
                saw_bad_template = True

    delete = False
    if saw_head:
        if saw_bad_template:
            p.msg("WARNING: Would delete but saw unrecognized template, not deleting")
        else:
            delete = True

    if not delete:
        return

    if "==Etymology" in sections[j]:
        p.msg("WARNING: Found Etymology subsection, don't know how to handle")
        return
    if "==Pronunciation " in sections[j]:
        p.msg("WARNING: Found Pronunciation N subsection, don't know how to handle")
        return

    #### Now, we can maybe delete the whole section or page

    if subsections[0].strip():
        p.msg(
            "WARNING: Whole Latin section deletable except that there's text above all subsections: <%s>"
            % subsections[0].strip()
        )
        return
    if "[[Category:" in sectail:
        p.msg(
            "WARNING: Whole Latin section deletable except that there's a category at the end: <%s>" % sectail.strip()
        )
        return
    if not modsec.has_non_lang:
        # Can delete the whole page, but check for non-blank section 0
        cleaned_sec0 = re.sub(r"^\{\{also\|.*?\}\}\n", "", sections[0])
        if cleaned_sec0.strip():
            p.msg(
                "WARNING: Whole page deletable except that there's text above all sections: <%s>" % cleaned_sec0.strip()
            )
            return
        p.msg("Page %s should be deleted" % p.title)
        pages_to_delete.append(p.title)
        return
    del sections[j]
    del sections[j - 1]
    notes.append("removed Latin section for bad term")
    if j > len(sections):
        # We deleted the last section; remove the final newlines.
        sections[-1] = sections[-1].rstrip("\n")
    text = "".join(sections)

    return text, notes


parser = blib.create_argparser("Delete bad Latin terms")
parser.add_argument("--headtemp", required=True, help="Name(s) of expected headword template(s).")
parser.add_argument("--output-pages-to-delete", help="File to write pages to delete.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

expected_head_templates = blib.split_arg(args.headtemp)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

msg("The following pages need to be deleted:")
for page in pages_to_delete:
    msg(page)
if args.output_pages_to_delete:
    with open(args.output_pages_to_delete, "w", encoding="utf-8") as fp:
        for page in pages_to_delete:
            print(page, file=fp)
