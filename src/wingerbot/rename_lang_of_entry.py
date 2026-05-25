#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if ":" in pagetitle and not re.search("^(Appendix|Reconstruction|Citations):", pagetitle):
        return

    origtext = text
    pagemsg("Processing")
    notes = []

    # Split into sections
    text, orig_secfinalnl = blib.force_two_newlines_in_secbody(text)
    secs = blib.split_text_into_sections(text, pagemsg)
    sections = secs.sections
    sections_by_lang = secs.sections_by_lang
    section_langs = secs.section_langs
    pagehead = sections[0]

    # Make sure new language section not already present.
    if args.tolang in sections_by_lang:
        pagemsg("WARNING: Already saw %s section, skipping" % args.tolang)
        return

    if args.fromlang not in sections_by_lang:
        pagemsg("Didn't see %s section for existing language, skipping" % args.fromlang)
        return

    # Change language name. In case the old name appears twice, we iterate over section_langs.
    new_headers = []
    for j, lang in section_langs:
        if lang == args.fromlang:
            new_headers.append((j, args.tolang))
        else:
            new_headers.append((j, lang))
    # Reorder sections by new language name, to make sure the new language section is in the right place.
    section_langs = sorted(new_headers, key=lambda x: lang_utils.langname_key(x[1]))

    text = pagehead + "".join(
        secheader + sections[j - 1: j + 1] for j, secheader in section_langs
    )

    text = text.rstrip("\n") + orig_secfinalnl

    if text != origtext:
        notes.append(
            "move %s section to %s%s"
            % (args.fromlang, args.tolang, " (%s)" % args.comment_tag if args.comment_tag else "")
        )
    return text, notes


parser = blib.create_argparser("Move entries from one language to another", include_pagefile=True, include_stdin=True)
parser.add_argument("--fromlang", required=True, help="Existing language to rename.")
parser.add_argument("--tolang", required=True, help="New name of language.")
parser.add_argument("--comment-tag", help="Tag to add to changelog message indicating reason for renaming.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
