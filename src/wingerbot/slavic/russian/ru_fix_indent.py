#!/usr/bin/env python3

import re

from wingerbot import blib


def process_text_on_page(p):
    p.msg("Processing")
    origtext = p.text

    notes = []

    def fix_indent(text, header, lto):
        lto_text = "=" * lto
        newtext = re.sub("^===+%s===+$" % header, "%s%s%s" % (lto_text, header, lto_text), text, 0, re.M)
        if newtext != text:
            notes.append("fix %s indentation" % header)
        return newtext

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    if "===Etymology 1===" in secbody:
        p.msg("WARNING: Skipping page because ===Etymology 1===")
        return

    secbody = fix_indent(secbody, "Pronunciation", 3)
    secbody = fix_indent(secbody, "Alternative forms", 3)
    secbody = fix_indent(secbody, "Declension", 4)
    secbody = fix_indent(secbody, "Conjugation", 4)

    text = modsec.rebuild(secbody=secbody)

    warn_on_no_change = not not args.pagefile
    if origtext != text:
        return text, notes
    elif warn_on_no_change:
        p.msg("WARNING: No changes")


parser = blib.create_argparser(
    "Fix indentation of Pronunciation, Declension, Conjugation, Alternative forms sections",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian lemmas", "Russian non-lemma forms"],
)
