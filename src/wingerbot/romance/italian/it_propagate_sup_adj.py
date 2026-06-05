#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_lemma_page(p, form):
    p.msg("Processing")

    notes = []

    parsed = blib.parse_text(p.text)
    it_adj_template = None
    it_part_template = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "it-adj":
            if it_adj_template:
                p.msg(
                    "WARNING: Saw multiple adjective headword templates in subsection, %s and %s, skipping"
                    % (str(it_adj_template), str(t))
                )
                return
            it_adj_template = t
        if tn == "it-pp":
            if it_part_template:
                p.msg(
                    "WARNING: Saw multiple adjective headword templates in subsection, %s and %s, skipping"
                    % (str(it_part_template), str(t))
                )
                return
            it_part_template = t
    if not it_adj_template and not it_part_template:
        p.msg("WARNING: Didn't see adjective or participle lemma template")
        return
    if it_part_template:
        if it_adj_template:
            p.msg(
                "WARNING: Saw both %s and %s, choosing adjective template"
                % (str(it_adj_template), str(it_part_template))
            )
            template = it_adj_template
        else:
            template = it_part_template
    else:
        template = it_adj_template
    assert template is not None  # must be it_adj_template or it_part_template, one of which must exist or we returned
    if getparam(template, "sup"):
        p.msg("Already saw sup=: %s" % str(template))
    else:
        origt = str(template)
        template.add("sup", form)
        p.msg("Replaced %s with %s" % (origt, str(template)))
        notes.append("add sup=%s to {{%s}}" % (form, tname(template)))

    return str(parsed), notes


def process_text_on_non_lemma_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "superlative of" and getparam(t, "1") == "it":
            lemma = getparam(t, "2")

            def do_process(pp):
                return process_lemma_page(pp, p.title)

            blib.do_edit(args, p.index, lemma, do_process, must_exist=True)


parser = blib.create_argparser(
    "Add sup= to {{it-adj}} headword params based on superlative entries", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_non_lemma_page,
    default_cats=["Italian superlative adjectives"],
)
