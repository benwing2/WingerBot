#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname
from wingerbot.latin import lalib


def process_form(p, pos):
    notes = []

    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    if pos == "pn":
        from_header = "==Noun=="
        to_header = "==Proper noun=="
        from_headword_template = "la-noun-form"
        to_headword_template = "la-proper noun-form"
        from_pos = "noun form"
        to_pos = "proper noun form"
        from_lemma_pos = "noun"
        to_lemma_pos = "proper noun"
    elif pos == "part":
        from_header = "==Adjective=="
        to_header = "==Participle=="
        from_headword_template = "la-adj-form"
        to_headword_template = "la-part-form"
        from_pos = "adjective form"
        to_pos = "participle form"
        from_lemma_pos = "adjective"
        to_lemma_pos = "participle"
    else:
        raise ValueError("Unrecognized POS %s" % pos)

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if re.search(r"\{\{%s([|}])" % from_headword_template, subsections[k]) or re.search(
            r"\{\{head\|la\|%s([|}])" % from_pos, subsections[k]
        ):
            newsubsec = subsections[k]
            newsubsec = re.sub(r"\{\{%s([|}])" % from_headword_template, r"{{%s\1" % to_headword_template, newsubsec)
            newsubsec = re.sub(r"\{\{head\|la\|%s([|}])" % from_pos, r"{{head|la|%s\1" % to_pos, newsubsec)
            newheadersubsec = subsections[k - 1]
            newheadersubsec = newheadersubsec.replace(from_header, to_header)
            if newsubsec != subsections[k] or newheadersubsec != subsections[k - 1]:
                notes.append("non-lemma %s -> %s in header and headword" % (from_lemma_pos, to_lemma_pos))
            subsections[k] = newsubsec
            subsections[k - 1] = newheadersubsec

    return modsec.rebuild(secbody="".join(subsections)), notes


def process_text_on_page(p):
    heads_and_defns = lalib.find_heads_and_defns(p.text, p.msg)
    if heads_and_defns is None:
        return
    headwords = heads_and_defns.headwords

    part_headwords = []
    adj_headwords = []
    pn_headwords = []
    noun_headwords = []

    for headword in headwords:
        ht = headword.head_template
        tn = tname(ht)
        if (
            tn == "la-part"
            or tn == "head"
            and getparam(ht, "1") == "la"
            and getparam(ht, "2") in ["participle", "participles"]
        ):
            part_headwords.append(headword)
        elif (
            tn == "la-adj"
            or tn == "head"
            and getparam(ht, "1") == "la"
            and getparam(ht, "2") in ["adjective", "adjectives"]
        ):
            adj_headwords.append(headword)
        elif (
            tn == "la-proper noun"
            or tn == "head"
            and getparam(ht, "1") == "la"
            and getparam(ht, "2") in ["proper noun", "proper nouns"]
        ):
            pn_headwords.append(headword)
        elif tn == "la-noun" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") in ["noun", "nouns"]:
            noun_headwords.append(headword)
    headwords_to_do = None
    if part_headwords and not adj_headwords:
        pos = "part"
        headwords_to_do = part_headwords
        expected_inflt = "la-adecl"
    elif pn_headwords and not noun_headwords:
        pos = "pn"
        headwords_to_do = pn_headwords
        expected_inflt = "la-ndecl"

    if not headwords_to_do:
        return

    for headword in headwords_to_do:
        for inflt in headword.infl_templates:
            infltn = tname(inflt)
            if infltn != expected_inflt:
                p.msg(
                    "WARNING: Saw bad declension template for %s, expected {{%s}}: %s"
                    % (pos, expected_inflt, str(inflt))
                )
                continue
            inflargs = lalib.generate_infl_forms(pos, str(inflt), p.errandmsg, p.expand_text)
            if inflargs is None:
                continue
            formvals_seen = set()
            slots_and_forms_to_process = []
            for slotformind, slotformtitle, slot, formval in lalib.flatten_slot_formvals(p.index, p.title, inflargs):
                if "[" in formval or "|" in formval:
                    continue
                formval_no_macrons = lalib.remove_macrons(formval)
                if formval_no_macrons == p.title:
                    continue
                if formval_no_macrons in formvals_seen:
                    continue
                formvals_seen.add(formval_no_macrons)
                slots_and_forms_to_process.append((slotformind, slotformtitle, slot, formval))
            for _, (slotformind, slotformtitle, slot, formval) in blib.iter_items(
                slots_and_forms_to_process, get_name=lambda x: x[3]):

                def handler(p):
                    return process_form(p, pos)

                blib.do_edit(
                    args,
                    slotformind,
                    lalib.remove_macrons(formval),
                    handler,
                    must_exist=True,
                    msg_title=slotformtitle,
                )


parser = blib.create_argparser(
    "Correct headers/headwords of non-lemma forms with the wrong part of speech",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Latin participles", "Latin proper nouns"]
)
