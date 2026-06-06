#!/usr/bin/env python3

# FIXME: Completely obsolete, should be deleted. Use create_wanted_categories.py to create categories with
# {{auto cat}} as the text.

from wingerbot import blib

cats = [
    "आना",
    "उगलना",
    "उठाना",
    "उतरना",
    "उतारना",
    "कटना",
    "कमाना",
    "करना",
    "कराना",
    "खाना",
    "खींचना",
    "गाना",
    "चढ़ाना",
    "चबवाना",
    "चलना",
    "चलाना",
    "चोदना",
    "जाना",
    "जोड़ना",
    "डालना",
    "तोड़ना",
    "दबाना",
    "दिलाना",
    "देखना",
    "देना",
    "निकालना",
    "निभाना",
    "पड़ना",
    "पढ़ना",
    "पहनना",
    "पहनाना",
    "पहुँचाना",
    "पाना",
    "पीना",
    "फूलना",
    "बजाना",
    "बनना",
    "बनाना",
    "बरसना",
    "बाटना",
    "बैठना",
    "बोलना",
    "भीगना",
    "माँगना",
    "मारना",
    "मिलाना",
    "रखना",
    "रहना",
    "लगना",
    "लगाना",
    "लेना",
    "सकना",
    "समझना",
    "सुनाना",
    "सूखना",
    "हिलाना",
    "होना",
]

parser = blib.create_argparser("Create Hindi phrasal verb categories",
                               no_include_pagefile=True, no_include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for catno, cat in enumerate(cats, start=1):
    def save_cat(p):
        if p.page.exists():
            p.msg("Page already exists, not overwriting")
            return
        text = "[[Category:Hindi phrasal verbs|%s]]" % cat
        return text, "Create '%s' with text '%s'" % (p.title, text)
    blib.do_edit(args, catno, "Category:Hindi phrasal verbs with particle (%s)" % cat, save_cat)
