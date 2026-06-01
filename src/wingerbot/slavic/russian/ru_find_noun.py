#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    for t in parsed.filter_templates():
        if tname(t) in ["ru-noun", "ru-proper noun"]:
            param3 = getparam(t, "3")
            if param3 == "-":
                pagemsg("Found indeclinable noun")
            elif "[[Category:Russian indeclinable nouns]]" in text:
                pagemsg("WARNING: Indeclinable noun but not marked in template")
            else:
                for tt in parsed.filter_templates():
                    ttn = tname(tt)
                    if ttn == "ru-noun-alt-ё":
                        pagemsg("Found alternative ё spelling")
                        break
                    elif ttn == "misspelling of":
                        pagemsg("Found misspelling of")
                        break
                    elif ttn == "ru-pre-reform":
                        for ttt in parsed.filter_templates():
                            if tname(ttt) == "ru-noun-old":
                                pagemsg("Found pre-reform word with ru-noun-old declension")
                                break
                        else:
                            pagemsg("Found pre-reform word without ru-noun-old declension")
                        break
                else:
                    pagemsg("WARNING: Found declinable non-pre-reform noun")


parser = blib.create_argparser("Find cases of declined ru-noun uses")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    edit=True,
    stdin=True,
    default_refs=["Template:ru-noun", "Template:ru-proper noun"],
)
