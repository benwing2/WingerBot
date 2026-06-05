#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname
from wingerbot.latin import lalib


def correct_nom_sg_n_participle(p, participle, lemma):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    if "===Etymology 1===" in secbody:
        p.msg("WARNING: Multiple etymologies, don't know what to do")
        return

    notes = []

    l3subsecs = blib.split_text_into_subsections(secbody, p.msg, only_level=3)
    subsections = l3subsecs.subsections

    participle_text = """{{head|la|participle|[[indeclinable]]|head=%s}}

# {{inflection of|la|%s||perf|pasv|part}}\n\n""" % (
        participle,
        lemma,
    )
    saw_participle = False
    for k, header in l3subsecs.header_list:
        if header == "Participle":
            if saw_participle:
                p.msg("WARNING: Saw multiple participles, skipping")
                return
            saw_participle = True
            subsections[k] = participle_text
            notes.append("correct participle %s of %s to be impersonal" % (participle, lemma))
    secbody = "".join(subsections)
    if not saw_participle:
        for k, header in l3subsecs.header_list:
            insert_before = False
            if header == "References":
                p.msg("Inserting new participle subsection before references subsection")
                insert_before = True
            elif re.search(r"\{\{inflection of.*\|sup", subsections[k]):
                p.msg("Inserting new participle subsection before supine subsection")
                insert_before = True
            if insert_before:
                subsections[k - 1 : k - 1] = ["===Participle===\n" + participle_text]
                secbody = "".join(subsections)
                break
        else:
            # no break
            secbody += "===Participle===\n" + participle_text
        notes.append("add impersonal participle %s of %s" % (participle, lemma))

    return modsec.rebuild(secbody=secbody), notes


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        if tname(t) == "la-conj":
            inflargs = lalib.generate_verb_forms(str(t), p.errandmsg, p.expand_text)
            if inflargs is None:
                continue
            supforms = inflargs.get("sup_acc", "")
            if supforms:
                supforms = supforms.split(",")
                for supform in supforms:
                    non_impers_part = re.sub("um$", "us", supform)
                    p.msg("Line to delete: part %s allbutnomsgn {{la-adecl|%s}}" % (non_impers_part, non_impers_part))

                    def do_correct_nom_sg_n_participle(p):
                        assert inflargs is not None  # Grrr, Pylance not smart enough
                        return correct_nom_sg_n_participle(p, supform, inflargs["1s_pres_actv_indc"])

                    blib.do_edit(
                        args,
                        p.index,
                        lalib.remove_macrons(supform),
                        do_correct_nom_sg_n_participle,
                        msg_title="%s: sup=%s" % (p.title, supform),
                    )


parser = blib.create_argparser(
    "Fix Latin impersonal passive participles and output deletion lines for non-impersonal variants",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--ignore", help="Comma-separated pages to ignore.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

ignore_pages = []
if args.ignore:
    ignore_pages = args.ignore.split(",")

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Latin verbs with impersonal passive"],
    filter_pages=lambda pagetitle: pagetitle not in ignore_pages,
)
