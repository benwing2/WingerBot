#!/usr/bin/env python3

import pywikibot

from wingerbot import blib
from wingerbot.blib import getparam, msg, site, tname


def process_text_on_page(p):
    seen_trans = [p.title]
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in blib.translation_templates:
            trans = blib.remove_links(getparam(t, "2"))
            if trans not in seen_trans:
                seen_trans.append(trans)
    for trans in seen_trans:
        def pagemsg_with_trans(txt):
            p.msg("%s: %s" % (trans, txt))

        if blib.safe_page_exists(pywikibot.Page(site, trans), pagemsg_with_trans):
            msg("Page %s %s: Found existing translation for %s" % (p.index, trans, p.title))


parser = blib.create_argparser("Find page-existing translations for terms", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
