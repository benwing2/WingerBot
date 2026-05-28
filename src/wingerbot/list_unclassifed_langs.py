#!/usr/bin/env python3

import re
from wingerbot import blib, lang_utils
from wingerbot.blib import msg
from collections import defaultdict

# blib.init_fake_langdata()
lang_data = lang_utils.get_lang_data()

languages = []


def process_text_on_page(index, pagename, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagename, txt))

    notes = []

    m = re.search("^Category:(.*) language$", pagename)
    if not m:
        pagemsg("WARNING: Page is not a language category")
    else:
        langname = m.group(1)
        if langname not in lang_data.languages_by_canonical_name:
            pagemsg("WARNING: Unrecognized language name '%s'" % langname)
        else:
            languages.append((lang_data.languages_by_canonical_name[langname]["code"], langname))


if __name__ == "__main__":
    parser = blib.create_argparser("Convert language categories to codes", include_pagefile=True, include_stdin=True)
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Unclassified languages"]
    )

    for code, name in sorted(languages, key=lambda x: x[0]):
        msg("%10s = %s" % (code, name))
