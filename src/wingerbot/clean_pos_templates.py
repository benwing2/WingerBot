#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils
from wingerbot.blib import msg

lang_data = lang_utils.get_lang_data()

templates = ["pos a", "pos adj", "pos adv", "pos adverb", "pos n", "pos noun", "pos v", "pos verb"]

pos_to_pos = {"a": "a", "adj": "a", "adv": "adv", "adverb": "adv", "n": "n", "noun": "n", "v": "v", "verb": "v"}


def process_text_on_page(p):
    p.msg("Processing")
    notes = []

    text = p.text

    def replace_pos(m):
        return "%s|pos=%s}}" % (m.group(1), pos_to_pos[m.group(2)])

    newtext = re.sub(r"(\{\{l\|.*?)\}\} \{\{pos[ _](.*?)\}\}", replace_pos, text)
    if newtext != text:
        notes.append("move {{pos *}} inside of link")
        text = newtext

    secs = blib.split_text_into_sections(text, p.msg)

    for j, langname in secs.lang_list:
        if langname not in lang_data.languages_by_canonical_name:
            langnamecode = None
        else:
            langnamecode = lang_data.languages_by_canonical_name[langname]["code"]

        def replace_raw_pos(m):
            if not langnamecode:
                msg("WARNING: Unable to parse langname %s when trying to replace raw link %s" % (langname, m.group(0)))
                return m.group(0)
            return "\n* {{l|%s|%s|pos=%s}}" % (langnamecode, m.group(1), pos_to_pos[m.group(2)])

        newsec = re.sub(r"\n\* \[\[([^\[\]\n]*?)\]\] \{\{pos[ _](.*?)\}\}", replace_raw_pos, secs.sections[j])
        if newsec != secs.sections[j]:
            notes.append("move {{pos *}} inside of raw link")
            secs.sections[j] = newsec

    text = "".join(secs.sections)

    return text, notes


parser = blib.create_argparser("Move {{pos *}} declarations inside of links")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" for template in templates],
)
