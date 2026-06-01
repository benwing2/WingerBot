#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Italian", pagemsg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    def process_etym_section(etymsec, sectext):
        references_sec = None
        further_reading_sec = None
        subsecs = blib.split_text_into_subsections(sectext, pagemsg)
        subsections = subsecs.subsections
        for k, header in subsecs.header_list:
            if header == "References":
                if references_sec:
                    pagemsg("WARNING: Saw two ===References=== sections in a single etym section")
                    return sectext
                references_sec = k
            if header == "Further reading":
                if further_reading_sec:
                    pagemsg("WARNING: Saw two ===Further reading=== sections in a single etym section")
                    return sectext
                further_reading_sec = k

        if not references_sec:
            return sectext
        lines = subsections[references_sec].split("\n")
        should_be_references = []
        should_be_further_reading = []
        for line in lines:
            if re.search(r"(<references\s*/?\s*>|\{\{reflist)", line):
                should_be_references.append(line)
            elif line:
                should_be_further_reading.append(line)
        if should_be_further_reading:
            if further_reading_sec:
                spl = "s" if len(should_be_further_reading) > 1 else ""
                pagemsg(
                    "Moving %s line%s from ===References=== to existing ===Further reading=== section"
                    % (len(should_be_further_reading), spl)
                )
                notes.append(
                    "move %s line%s from Italian ===References=== to existing ===Further reading=== section"
                    % (len(should_be_further_reading), spl)
                )
                subsections[further_reading_sec] = (
                    subsections[further_reading_sec].rstrip("\n") + "\n" + "\n".join(should_be_further_reading) + "\n\n"
                )
            else:
                spl = "s" if len(should_be_further_reading) > 1 else ""
                pagemsg(
                    "Moving %s line%s from ===References=== to new ===Further reading=== section"
                    % (len(should_be_further_reading), spl)
                )
                notes.append(
                    "move %s line%s from Italian ===References=== to new ===Further reading=== section"
                    % (len(should_be_further_reading), spl)
                )
                further_reading_header = subsections[references_sec - 1].replace("References", "Further reading")
                further_reading_text = "\n".join(should_be_further_reading) + "\n\n"
                subsections[references_sec + 1 : references_sec + 1] = [further_reading_header, further_reading_text]
        if should_be_references:
            spl = "s" if len(should_be_references) > 1 else ""
            pagemsg("Retaining %s line%s in ===References=== section" % (len(should_be_references), spl))
            notes.append("retain %s line%s in Italian ===References=== section" % (len(should_be_references), spl))
            subsections[references_sec] = "\n".join(should_be_references) + "\n\n"
        else:
            pagemsg("Removing now-blank ===References=== section")
            notes.append("remove now-blank Italian ===References=== section")
            subsections[references_sec - 1] = ""
            subsections[references_sec] = ""
        return "".join(subsections)

    secbody = blib.map_etym_sections(secbody, pagemsg, process_etym_section)
    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Move non-references in Italian ===References=== sections to ===Further reading===",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
