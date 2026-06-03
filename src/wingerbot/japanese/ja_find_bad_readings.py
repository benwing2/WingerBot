#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg


def process_page(p):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")

    for catindex, catpage in blib.cat_subcats(p.page, recurse=True):
        cat = catpage.title()

        def pagemsg(txt):
            msg("Page %s,%s %s: %s" % (p.index, catindex, cat, txt))

        if (
            not re.search("with.* reading ", cat)
            or re.search("(ancient|historical) ", cat)
            or re.search("read as", cat)
        ):
            continue
        reading = re.sub(".*with.* reading ", "", cat)
        reading = re.sub("-.*", "", reading)
        reason = None
        if len(reading) >= 5:
            reason = ">=5 chars"
        elif reading.endswith("さま"):
            reason = "ends with さま"
        elif re.search("[をゑゐ]|[かがはばぱさざただなまやら]う", reading):
            reason = "contains archaic chars or inappropriate combinations"
        if reason:
            kanjis = []
            for j, kanjipage in blib.cat_articles(catpage):
                kanji = kanjipage.title()
                kanjis.append(kanji)
            pagemsg("Bad category because %s: contents=%s" % (reason, ",".join(kanjis)))


parser = blib.create_argparser("Find bad Japanese reading categories", include_pagefile=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
