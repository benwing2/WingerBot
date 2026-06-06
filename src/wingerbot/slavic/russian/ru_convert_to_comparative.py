#!/usr/bin/env python3

# Convert ru-adv to ru-compararative for comparatives.

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])
        found_adj_comp = False
        found_adv_comp = False
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn == "comparative of" and getparam(t, "lang") == "ru":
                if getparam(t, "POS") == "adjective":
                    found_adj_comp = True
                elif getparam(t, "POS") == "adverb":
                    found_adv_comp = True

        if not found_adj_comp and not found_adv_comp:
            continue

        if found_adj_comp and not found_adv_comp:
            p.msg("WARNING: Found adjective but not adverb 'comparative of'")
        if found_adv_comp and not found_adj_comp:
            p.msg("WARNING: Found adverb but not adjective 'comparative of'")

        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            template_fixed = False
            if tn == "ru-adv":
                t.name = "ru-comparative"
                template_fixed = True
            elif (
                tn == "head" and getparam(t, "1") == "ru" and (getparam(t, "2") == "adverb comparative form")
            ):
                head = getparam(t, "head")
                rmparam(t, "head")
                rmparam(t, "2")
                rmparam(t, "1")
                t.name = "ru-comparative"
                t.add("1", head)
                template_fixed = True
            if template_fixed:
                if found_adj_comp and not found_adv_comp:
                    t.add("noadv", "1")
                if found_adv_comp and not found_adj_comp:
                    t.add("noadj", "1")
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))
                notes.append("convert headword to ru-comparative")
        subsections[k] = str(parsed)
    secbody = "".join(subsections)

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Convert ru-adv to ru-compararative for comparatives"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian comparative adjectives", "Russian comparative adverbs"],
)
