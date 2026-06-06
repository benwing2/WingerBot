#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

from wingerbot.latin import lalib


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    if "==Etymology 1==" in secbody:
        p.msg("Already saw multiple etym sections")
        return

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    if len(subsections) < 3:
        p.msg("WARNING: Something wrong, only one subsection")
        return

    def increase_indent(subsecs):
        new_subsecs = []
        for k in range(len(subsecs)):
            if k % 2 == 1:
                new_subsecs.append(re.sub("^(.*)\n$", r"=\1=\n", subsecs[k]))
            else:
                new_subsecs.append(subsecs[k])
        return new_subsecs

    etym_section = None
    if subsecs.headers[2] == "Etymology":
        etym_section = 1
    elif len(subsections) >= 4 and subsecs.headers[4] == "Etymology":
        etym_section = 3
    if etym_section:
        subsections = (
            subsections[0 : 1]
            + subsections[etym_section : etym_section + 2]
            + subsections[1 : etym_section]
            + subsections[etym_section + 2 :]
        )
        new_subsecs1 = re.sub(
            "^====Etymology====$", "===Etymology 1===", "".join(increase_indent(subsections)), 0, re.M
        )
        new_subsecs2 = re.sub(
            "^====Etymology====$", "===Etymology 2===", "".join(increase_indent(subsections)), 0, re.M
        )
        secbody = new_subsecs1.rstrip("\n") + "\n\n" + new_subsecs2.strip()
    else:
        new_subsecs1 = "".join(increase_indent(subsections))
        new_subsecs2 = "".join(increase_indent(subsections))
        secbody = "\n===Etymology 1===\n\n" + new_subsecs1.strip() + "\n\n===Etymology 2===\n\n" + new_subsecs2.strip()

    notes.append("double Latin etymology section")

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser("Double latin etym sections")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
