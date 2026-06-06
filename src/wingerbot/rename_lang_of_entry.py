#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils
from wingerbot.blib import msg


def process_text_on_page(p):
    origtext = p.text
    p.msg("Processing")
    notes = []

    # Split into sections
    text, orig_secfinalnl = blib.force_two_newlines_in_secbody(p.text)
    secs = blib.split_text_into_sections(text, p.msg)
    sections = secs.sections
    sections_by_lang = secs.sections_by_lang
    lang_list = secs.lang_list
    pagehead = sections[0]

    # Make sure new language section not already present.
    if args.tolang in sections_by_lang:
        p.msg("WARNING: Already saw %s section, skipping" % args.tolang)
        return

    if args.fromlang not in sections_by_lang:
        p.msg("Didn't see %s section for existing language, skipping" % args.fromlang)
        return

    # Change language name. In case the old name appears twice, we iterate over lang_list.
    new_headers = []
    for j, lang in lang_list:
        if lang == args.fromlang:
            new_headers.append((j, args.tolang))
        else:
            new_headers.append((j, lang))
    # Reorder sections by new language name, to make sure the new language section is in the right place.
    lang_list = sorted(new_headers, key=lambda x: lang_utils.langname_key(x[1]))

    text = pagehead + "".join(secheader + sections[j - 1 : j + 1] for j, secheader in lang_list)

    text = text.rstrip("\n") + orig_secfinalnl

    if text != origtext:
        notes.append(
            "move %s section to %s%s"
            % (args.fromlang, args.tolang, " (%s)" % args.comment_tag if args.comment_tag else "")
        )
    return text, notes


parser = blib.create_argparser("Move entries from one language to another")
parser.add_argument("--fromlang", required=True, help="Existing language to rename.")
parser.add_argument("--tolang", required=True, help="New name of language.")
parser.add_argument("--comment-tag", help="Tag to add to changelog message indicating reason for renaming.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
