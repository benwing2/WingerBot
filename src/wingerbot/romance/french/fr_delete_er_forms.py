#!/usr/bin/env python3

# Delete erroneously created forms given the declensions that led to those
# forms being created.

import re

from wingerbot import blib

suffixes = [
    "e",
    "es",
    "ent",
    "erai",
    "eras",
    "era",
    "erons",
    "erez",
    "eront",
    "erais",
    "erait",
    "erions",
    "eriez",
    "eraient",
]
all_suffixes = [
    "e",
    "es",
    "ons",
    "ez",
    "ent",
    "ais",
    "ait",
    "ions",
    "iez",
    "aient",
    "erai",
    "eras",
    "era",
    "erons",
    "erez",
    "eront",
    "erais",
    "erait",
    "erions",
    "eriez",
    "eraient",
    "ai",
    "as",
    "a",
    "âmes",
    "âtes",
    "èrent",
    "asse",
    "asses",
    "ât",
    "assions",
    "assiez",
    "assent",
    "ant",
    "é",
]


def process_er_verb_form(p, lemma):
    form = p.title
    if form == lemma:
        p.msg("WARNING: Attempt to delete dictionary form, skipping")
        return

    secs = blib.split_text_into_sections(p.text, p.msg)
    langs_seen = set(lang for _, lang in secs.lang_list)
    if "French" not in langs_seen:
        p.msg("WARNING: Didn't see French section, skipping")
        return

    if len(langs_seen) > 1:
        non_french_langs = langs_seen - {"French"}
        p.msg("WARNING: Found entry for non-French language(s) %s, skipping form" % ",".join(non_french_langs))
        return

    if "Etymology 1" in p.text:
        p.msg("WARNING: Found 'Etymology 1', skipping form")
        return

    for m in re.finditer(r"\{\{also\|.*\}\}", p.text, re.M):
        p.msg("WARNING: Found %s in page to delete" % m.group(0))
    comment = "Delete erroneously created form of %s" % lemma
    if args.save:
        p.msg(
            "Page text for form follows:\n=============================\n%s\n============================="
            % p.text
        )
        p.page.delete(comment)
    else:
        p.msg("Would delete page with comment=%s" % comment)

def process_er_verb(p):
    p.msg("Processing")

    if not p.title.endswith("er"):
        p.msg("WARNING: Page %s doesn't end in -er, skipping")
        return

    stem = re.sub("er$", "", p.title)
    for sufind, suffix in enumerate(all_suffixes if args.all_suffixes else suffixes, start=1):
        form = stem + suffix

        def do_process_er_verb_form(pp):
            return process_er_verb_form(p, p.title)
        blib.do_edit(args, "%s.%s" % (p.index, sufind), form, do_process_er_verb_form, must_exist=True,
                     msg_title="%s: %s" % (p.title, form))


parser = blib.create_argparser("Delete erroneously created French -er verb forms")
parser.add_argument(
    "--all-suffixes",
    action="store_true",
    help="If specifies, do all conjugational suffixes rather than just those using the stressed or future stem.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_er_verb, no_fetch_text=True)
