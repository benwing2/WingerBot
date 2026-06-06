#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname, msg
from wingerbot.latin import lalib


def investigate_possible_adj(p, adv, adv_defns):
    p.msg("Trying for adverb %s" % adv)
    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in ["la-adj", "la-part"]:
                adj = lalib.la_get_headword_from_template(t, p.title, p.msg)[0]
                adj_defns = blib.find_defns(subsections[k], "la")
                msg("%s /// %s /// %s /// %s" % (adv, adj, ";".join(adv_defns), ";".join(adj_defns)))


def process_text_on_page(p):
    if " " in p.title:
        p.msg("WARNING: Space in page title, skipping")
        return
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn == "la-adv":
                adv = blib.remove_links(getparam(t, "1")) or p.title
                macron_stem, is_stem = lalib.infer_adv_stem(adv)
                if not is_stem:
                    p.msg("WARNING: Couldn't infer stem from adverb %s, not standard: %s" % (adv, origt))
                    continue
                adv_defns = blib.find_defns(subsections[k], "la")
                possible_adjs = []
                stem = lalib.remove_macrons(macron_stem)
                possible_adjs.append(stem + "us")
                possible_adjs.append(stem + "is")
                if stem.endswith("nt"):
                    possible_adjs.append(stem[:-2] + "ns")
                if stem.endswith("plic"):
                    possible_adjs.append(stem[:-2] + "ex")
                if stem.endswith("c"):
                    possible_adjs.append(stem[:-1] + "x")
                if re.search("[aeiou]r$", stem):
                    possible_adjs.append(stem)
                elif stem.endswith("r"):
                    possible_adjs.append(stem[:-1] + "er")
                if adv.endswith("iē"):
                    possible_adjs.append(stem + "ius")
                for possible_adj in possible_adjs:
                    def do_investigate_possible_adj(p):
                        return investigate_possible_adj(p, adv, adv_defns)
                    blib.do_edit(args, p.index, possible_adj, do_investigate_possible_adj, must_exist=True)


parser = blib.create_argparser(
    "Find corresponding adjectives for Latin adverbs"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Latin adverbs"])
