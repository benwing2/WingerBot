#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import tname

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "Inflection":
            parsed = blib.parse_text(subsections[k])
            poses = set()
            for t in parsed.filter_templates():
                pos = lalib.la_infl_template_pos(t)
                if pos:
                    poses.add(pos)
            poses = sorted(list(poses))
            if len(poses) > 1:
                p.msg("WARNING: Saw inflection templates for multiple parts of speech: %s" % ",".join(poses))
            elif len(poses) == 0:
                p.msg("WARNING: Saw no inflection templates in ==Inflection== section")
            else:
                if poses[0] == "verb":
                    subsections[k - 1] = subsections[k - 1].replace("Inflection", "Conjugation")
                    notes.append("convert Latin ==Inflection== header to ==Conjugation==")
                else:
                    subsections[k - 1] = subsections[k - 1].replace("Inflection", "Declension")
                    notes.append("convert Latin ==Inflection== header to ==Declension==")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Convert Latin ==Inflection== headers to ==Conjugation== or ==Declension==",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
