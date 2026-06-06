#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, args.langname, p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for desc_ind in subsecs.subsections_by_header.get("Descendants", []):
        lines = subsections[desc_ind].split("\n")
        prev_is_hindustani = False
        prev_hindustani_stars = ""
        prev_hindustani_bor = False
        prev_hindustani_der = False
        prev_hindustani_tr = None
        for lineind, line in enumerate(lines):

            def linemsg(txt):
                p.msg("Descendants line %s: %s" % (lineind + 1, txt))

            m = re.search(r"^([*:]*)", line)
            initial_stars = m.group(1)
            if prev_is_hindustani and len(initial_stars) <= len(prev_hindustani_stars):
                prev_is_hindustani = False
            m = re.search(r"^[*:]*\s*\{\{desc\|(hi|ur)\|", line)
            if m:
                if not prev_is_hindustani:
                    linemsg("WARNING: Saw Hindi/Urdu descendant not under Hindustani: %s" % line)
                else:
                    expected_initial_stars = prev_hindustani_stars + ":"
                    if expected_initial_stars != initial_stars:
                        p.msg(
                            "Convert initial stars for Hindi/Urdu descendant under Hindustani label from %s to %s"
                            % (initial_stars, expected_initial_stars)
                        )
                        notes.append("correct initial stars for Hindi/Urdu descendant under Hindustani label")
                        initial_stars = expected_initial_stars

            m = re.search(r"^([*:]*)\s*\{*([→⇒]?)\}*\s*Hindustani:*(.*)$", line)
            if m:
                initial_stars, arrow, after = m.groups()
                if arrow == "→":
                    bor_der = "|bor=1"
                elif arrow == "⇒":
                    bor_der = "|der=1"
                else:
                    bor_der = ""
                after = after.strip()
                if after:
                    after = " " + after
                newline = "%s {{desc|inc-hnd%s|-}}%s" % (initial_stars, bor_der, after)
                p.msg("Replace <%s> with <%s>" % (line, newline))
                notes.append("templatize 'Hindustani' in Descendants section")
                line = newline
            m = re.search(r"^([*:]*)\s*(\{\{desc\|ind-hnd\b[^{}]*\}\})(.*)$", line)
            if m:
                initial_stars, hindustani_template, after = m.groups()
                hindustani_t = list(blib.parse_text(hindustani_template).filter_templates())[0]
                assert tname(hindustani_t) == "desc"

                def getp(param):
                    return getparam(hindustani_t, param)

                if getp("1") != "inc-hnd":
                    linemsg(
                        "WARNING: Something likely wrong, saw Hindustani descendant template with wrong lang code: %s"
                        % line
                    )
                    continue
                prev_is_hindustani = True
                if getp("2") != "-":
                    p.msg("WARNING: Saw Hindustani descendant without - in 2=: %s" % str(hindustani_t))
                prev_hindustani_bor = getp("bor")
                prev_hindustani_der = getp("der")
                prev_hindustani_stars = initial_stars
                after = after.strip()
                if "{" in after:
                    p.msg("WARNING: Template follows Hindustani descendant template, not removing: %s" % line)
                    prev_hindustani_tr = ""
                    newline = "%s %s %s" % (initial_stars, str(hindustani_t), after)
                    if newline != line:
                        p.msg("Replace <%s> with <%s>" % (line, newline))
                        notes.append("clean Hindustani descendant template")
                    continue
                prev_hindustani_tr = after
                newline = "%s %s" % (initial_stars, str(hindustani_t))
                if newline != line:
                    p.msg("Replace <%s> with <%s>" % (line, newline))
                    if after:
                        notes.append("clean Hindustani descendant template, removing trailing translit")
                    else:
                        notes.append("clean Hindustani descendant template")
                continue

    text = modsec.rebuild(secbody="".join(subsections))
    newtext = re.sub(r"\n\n\n+", "\n\n", text)
    if text != newtext:
        notes.append("convert 3+ newlines to 2 newlines")
    text = newtext
    return text, notes


parser = blib.create_argparser(
    "Templatize 'Hindustani' in Descendants sections and fix indentation"
)
parser.add_argument("--langname", help="Only do this language name (optional).")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
