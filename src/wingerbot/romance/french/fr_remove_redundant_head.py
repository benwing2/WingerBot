#!/usr/bin/env python3

# Go through all the French terms we can find and remove redundant head=.

import re, sys
import unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg

fr_head_or_1_templates = ["fr-verb", "fr-adv", "fr-phrase", "fr-intj", "fr-prep"]

fr_head_only_templates = [
    "fr-noun",
    "fr-proper noun",
    "fr-proper-noun",
    "fr-adj",
    "fr-adj-form",
    "fr-abbr",
    "fr-diacritical mark",
    "fr-past participle",
    "fr-prefix",
    "fr-pron",
    "fr-punctuation mark",
    "fr-suffix",
    "fr-verb form",
    "fr-verb-form",
]

fr_head_templates = fr_head_or_1_templates + fr_head_only_templates

exclude_punc_chars = "-־׳״'.·*[]"
punc_chars = "".join(
    "\\" + chr(i)
    for i in range(sys.maxunicode)
    if unicodedata.category(chr(i)).startswith("P") and chr(i) not in exclude_punc_chars
)


def link_text(text):
    words = re.split("([" + punc_chars + r"\s]+)", text)
    linked_words = [
        ("[[" + word + "]]" if (i % 2) == 0 and word and "[" not in word and "]" not in word else word)
        for i, word in enumerate(words)
    ]
    return "".join(linked_words)


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    if ":" in pagetitle:
        pagemsg("WARNING: Colon in page title, skipping")
        return

    def check_bad_head(text, arg):
        canontext = re.sub("[׳’]", "'", blib.remove_links(text))
        canonpagetitle = re.sub("[׳’]", "'", pagetitle)
        if canontext != canonpagetitle:
            pagemsg(
                "WARNING: Canonicalized %s=%s not same as canonicalized page title %s (orig %s=%s)"
                % (arg, canontext, canonpagetitle, arg, text)
            )

    notes = []
    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        origt = str(t)
        name = str(t.name)
        if name in fr_head_templates:
            head = getparam(t, "head")
            if head:
                linked_pagetitle = link_text(pagetitle)
                linked_head = link_text(head)
                if linked_pagetitle == linked_head:
                    pagemsg("Removing redundant head=%s" % head)
                    rmparam(t, "head")
                    notes.append("remove redundant head= from {{%s}}" % name)
                else:
                    pagemsg("Not removing non-redundant head=%s" % head)
                    check_bad_head(head, "head")
        if name in fr_head_or_1_templates:
            head = getparam(t, "1")
            if head:
                linked_pagetitle = link_text(pagetitle)
                linked_head = link_text(head)
                if linked_pagetitle == linked_head:
                    pagemsg("Removing redundant 1=%s" % head)
                    rmparam(t, "1")
                    notes.append("remove redundant 1= from {{%s}}" % name)
                else:
                    pagemsg("Not removing non-redundant 1=%s" % head)
                    check_bad_head(head, "1")

        newt = str(t)
        if origt != newt:
            pagemsg("Replacing %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Remove redundant head= from French terms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    edit=True,
    stdin=True,
    default_cats=["French lemmas"],
    # default_cats=["French lemmas", "French non-lemma forms"],
)
