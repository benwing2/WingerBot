#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

pronun_templates = ["IPA", "szy-IPA"]


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Sakizaya", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections

    parsed = blib.parse_text(secbody)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in pronun_templates:
            p.msg("Already saw pronunciation template: %s" % str(t))
            return

    def construct_new_pron_template():
        return "{{szy-IPA}}", ""

    def insert_new_l3_pron_section(k):
        new_pron_template, pron_prefix = construct_new_pron_template()
        subsections[k:k] = ["===Pronunciation===\n", pron_prefix + new_pron_template + "\n\n"]
        notes.append("add top-level Sakizaya pron %s" % new_pron_template)

    k = 2
    while k < len(subsections) and subsecs.headers[k] in ["Alternative forms", "Etymology"]:
        k += 2
    if k - 1 >= len(subsections):
        p.msg("WARNING: No lemma or non-lemma section at top level")
        return
    insert_new_l3_pron_section(k - 1)

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Add Sakizaya pronunciations")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Sakizaya lemmas"]
)

blib.elapsed_time()
