#!/usr/bin/env python3

# Batch-find redlinks (non-existent pages).
# FIXME: Merge this with the more general batch_find_red_links.py.

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, site

parser = blib.create_argparser("Find Bulgarian red links", no_include_stdin=True)
parser.add_argument("--direcfile", help="File containing pages to check and frequencies")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lemmas = set()
msg("Reading Bulgarian lemmas")
for i, page in blib.cat_articles("Bulgarian lemmas", start, end):
    lemmas.add(page.title())

def check_page(p, freq: str | None = None):
    pagetitle = p.title

    def _msg_contents(txt):
        return "Page %s [[%s]]: %s%s" % (p.index, pagetitle, txt, " (freq %s)" % freq if freq is not None else "")

    def pagemsg(txt):
        msg(_msg_contents(txt))
    def errandpagemsg(txt):
        errandmsg(_msg_contents(txt))

    m = re.search("[^-Ѐ-џҊ-ԧꚀ-ꚗ]", pagetitle)
    if m:
        pagemsg("skipped due to non-Cyrillic characters")
    else:
        for pagenm, pagetype in [
            (pagetitle, ""),
            (pagetitle.capitalize(), " (capitalized)"),
            (pagetitle.upper(), " (uppercased)"),
        ]:
            if pagenm in lemmas:
                pagemsg("exists%s" % pagetype)
                break
            else:
                page = pywikibot.Page(site, pagenm)
                if page.exists():
                    text = blib.safe_page_text(page, errandpagemsg)
                    if re.search("#redirect", text, re.I):
                        pagemsg("exists%s as redirect" % pagetype)
                    elif re.search(r"\{\{superlative of\|bg\|", text):
                        pagemsg("exists%s as superlative" % pagetype)
                    elif "==Bulgarian==" in text:
                        pagemsg("exists%s as non-lemma" % pagetype)
                    else:
                        pagemsg("exists%s only in some other language" % pagetype)
                    break
        else:
            pagemsg("does not exist")

if args.direcfile:
    for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
        pagetitle, freq = line.split("\t")
        def do_check_page(p):
            return check_page(p, freq)
        blib.do_edit(args, lineno, pagetitle, check_page)
else:
    blib.do_pagefile_cats_refs(args, start, end, check_page)
