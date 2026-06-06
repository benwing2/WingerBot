#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Italian", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    parsed = blib.parse_text(secbody)
    needs_refs = False

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn in ["it-verb", "it-verb-rfc", "it-conj", "it-conj-rfc"]:
            conj = getp("1")
            if "[r:" in conj or "[ref:" in conj:
                p.msg("Found conjugation template with reference: %s" % str(t))
                needs_refs = True
        elif tn in ["it-IPA", "it-pr"]:
            respelling = getp("1")
            if "<r:" in respelling or "<ref:" in respelling:
                p.msg("Found pronunciation template with reference: %s" % str(t))
                needs_refs = True

    if needs_refs:
        if re.search(r"(<references\s*/?\s*>|\{\{reflist)", secbody):
            p.msg("Already saw <references /> or {{reflist}}")
            return

        subsecs = blib.split_text_into_subsections(secbody, p.msg)
        subsections = subsecs.subsections

        saw_references_sec = False
        for k, header in subsecs.header_list:
            if header == "References":
                if saw_references_sec:
                    p.msg("WARNING: Saw two ===References=== sections")
                else:
                    subsections[k] = subsections[k].rstrip("\n") + "\n<references />\n\n"
                    notes.append("add omitted <references /> to existing Italian ===References=== section")
                    saw_references_sec = True

        if not saw_references_sec:
            k = len(subsections) - 1
            while k >= 2 and subsecs.headers[k] in ["Anagrams", "Further reading"]:
                k -= 2
            if k < 2:
                p.msg("WARNING: No lemma or non-lemma section")
                return
            subsections[k + 1 : k + 1] = ["===References===\n", "<references />\n\n"]
            notes.append("add omitted ===References=== section for Italian term")

        secbody = "".join(subsections)

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Add missing ===References=== sections in Italian lemmas"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
