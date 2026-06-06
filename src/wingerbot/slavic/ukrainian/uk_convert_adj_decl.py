#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

from wingerbot.slavic.ukrainian import uklib


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    head = None
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "uk-adj":
            head = getparam(t, "1")
            if getparam(t, "head2"):
                p.msg("WARNING: Can't handle head2= yet in {{rfinfl}}")
                head = None
        elif tn == "rfinfl" and getparam(t, "1") == "uk" and getparam(t, "2") == "adjective":
            if not head:
                p.msg("WARNING: Found {{rfinfl}} and don't have head: %s" % origt)
            elif " " in head:
                p.msg("Found {{rfinfl}} but head %s has space in it, skipping" % head)
            else:
                rmparam(t, "2")
                t.add("1", head)
                blib.set_template_name(t, "uk-adecl")
                notes.append("add Ukrainian adjective declension for %s" % head)
        elif tn == "uk-decl-adj":
            word = getparam(t, "1") + getparam(t, "2")
            if uklib.needs_accents(word):
                p.msg("WARNING: Word %s needs accent: %s" % (word, origt))
                continue
            t.add("1", word)
            rmparam(t, "2")
            blib.set_template_name(t, "uk-adecl")
            notes.append("convert {{uk-decl-adj}} to {{uk-adecl}}")
        elif tn == "uk-adj-table":
            notesval = getparam(t, "notes")
            if notesval:
                notesval = re.sub("^: ", "", notesval)
                if not re.search(r"\.\s*$", notesval):
                    notesval = re.sub(r"(\s*)$", r".\1", notesval)
                t.add("footnote", notesval, before="notes", preserve_spacing=False)
                rmparam(t, "notes")
            blib.set_template_name(t, "uk-adecl-manual")
            notes.append("convert {{uk-adj-table}} to {{uk-adecl-manual}}")
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert old Ukrainian adjective declension templates to new ones"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Ukrainian adjectives", "Ukrainian pronouns", "Ukrainian determiners"],
)
