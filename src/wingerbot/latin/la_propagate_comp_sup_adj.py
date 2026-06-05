#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname
from wingerbot.latin import lalib


def process_lemma_page(p, is_comp, form):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    la_adj_template = None
    la_part_template = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-adj":
            if la_adj_template:
                p.msg(
                    "WARNING: Saw multiple adjective headword templates in subsection, %s and %s, skipping"
                    % (str(la_adj_template), str(t))
                )
                return
            la_adj_template = t
        if tn == "la-part":
            if la_part_template:
                p.msg(
                    "WARNING: Saw multiple adjective headword templates in subsection, %s and %s, skipping"
                    % (str(la_part_template), str(t))
                )
                return
            la_part_template = t
    if not la_adj_template and not la_part_template:
        p.msg("WARNING: Didn't see adjective or participle lemma template")
        return
    if is_comp:
        param = "comp"
    else:
        param = "sup"
    if la_part_template:
        if la_adj_template:
            p.msg(
                "WARNING: Saw both %s and %s, choosing adjective template"
                % (str(la_adj_template), str(la_part_template))
            )
            template = la_adj_template
        else:
            template = la_part_template
    else:
        template = la_adj_template
    assert template is not None  # we returned if both la_adj_template and la_part_template are None
    if getparam(template, param):
        p.msg("Already saw %s=: %s" % (param, str(template)))
    else:
        orig_template = str(template)
        if param == "comp":
            template.add(param, form, before="sup")
        else:
            template.add(param, form)
        p.msg("Replaced %s with %s" % (orig_template, str(template)))
        notes.append("add %s=%s to {{la-adj}}" % (param, form))

    return str(parsed), notes


def process_text_on_page(p):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["la-adj-comp", "la-adj-sup"]:
            lemma = getparam(t, "1") or p.title
            pos = getparam(t, "pos")
            if pos:

                def do_process(p):
                    return process_lemma_page(p, tn == "la-adj-comp", lemma)

                blib.do_edit(
                    args,
                    p.index,
                    lalib.remove_macrons(pos),
                    do_process,
                    msg_title=pos,
                )
            else:
                p.msg("WARNING: Didn't see positive degree: %s" % str(t))


parser = blib.create_argparser(
    "Add comp/sup to {{la-adj}} headword params based on comparative/superlative entries",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Latin comparative adjectives", "Latin superlative adjectives"],
)
