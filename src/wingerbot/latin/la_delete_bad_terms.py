#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, tname

pages_to_delete = []


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Latin", pagemsg)
    if modsec is None:
        return
    sections, j, secbody, sectail, has_non_lang = modsec.props()

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
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
                pagemsg(
                    "WARNING: Saw unrecognized template in subsection #%s %s: %s"
                    % (k // 2, subsections[k - 1].strip(), str(t))
                )
                saw_bad_template = True

    delete = False
    if saw_head:
        if saw_bad_template:
            pagemsg("WARNING: Would delete but saw unrecognized template, not deleting")
        else:
            delete = True

    if not delete:
        return

    if "==Etymology" in sections[j]:
        pagemsg("WARNING: Found Etymology subsection, don't know how to handle")
        return
    if "==Pronunciation " in sections[j]:
        pagemsg("WARNING: Found Pronunciation N subsection, don't know how to handle")
        return

    #### Now, we can maybe delete the whole section or page

    if subsections[0].strip():
        pagemsg(
            "WARNING: Whole Latin section deletable except that there's text above all subsections: <%s>"
            % subsections[0].strip()
        )
        return
    if "[[Category:" in sectail:
        pagemsg(
            "WARNING: Whole Latin section deletable except that there's a category at the end: <%s>" % sectail.strip()
        )
        return
    if not has_non_lang:
        # Can delete the whole page, but check for non-blank section 0
        cleaned_sec0 = re.sub(r"^\{\{also\|.*?\}\}\n", "", sections[0])
        if cleaned_sec0.strip():
            pagemsg(
                "WARNING: Whole page deletable except that there's text above all sections: <%s>" % cleaned_sec0.strip()
            )
            return
        pagemsg("Page %s should be deleted" % pagetitle)
        pages_to_delete.append(pagetitle)
        return
    del sections[j]
    del sections[j - 1]
    notes.append("removed Latin section for bad term")
    text = "".join(sections)

    return text, notes


parser = blib.create_argparser("Delete bad Latin terms", include_pagefile=True, include_stdin=True)
parser.add_argument("--headtemp", required=True, help="Name(s) of expected headword template(s).")
parser.add_argument("--output-pages-to-delete", help="File to write pages to delete.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

expected_head_templates = blib.split_arg(args.headtemp)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

msg("The following pages need to be deleted:")
for page in pages_to_delete:
    msg(page)
if args.output_pages_to_delete:
    with open(args.output_pages_to_delete, "w", encoding="utf-8") as fp:
        for page in pages_to_delete:
            print(page, file=fp)
