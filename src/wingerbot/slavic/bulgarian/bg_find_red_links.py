#!/usr/bin/env python3

# Find redlinks (non-existent pages).

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, site

parser = blib.create_argparser("Find Bulgarian red links")
parser.add_argument("--pagefile", help="File containing pages to check")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lemmas = set()
msg("Reading Bulgarian lemmas")
for i, page in blib.cat_articles("Bulgarian lemmas", start, end):
    lemmas.add(page.title())

for i, line in blib.iter_items_from_file(args.pagefile, start, end):
    pagename, freq = line.split("\t")
    m = re.search("[^-Ѐ-џҊ-ԧꚀ-ꚗ]", pagename)

    def pagemsg(txt):
        msg("Page %s [[%s]]: %s (freq %s)" % (i, pagename, txt, freq))
    def errandpagemsg(txt):
        errandmsg("Page %s [[%s]]: %s (freq %s)" % (i, pagename, txt, freq))

    if m:
        pagemsg("skipped due to non-Cyrillic characters")
    else:
        for pagenm, pagetype in [
            (pagename, ""),
            (pagename.capitalize(), " (capitalized)"),
            (pagename.upper(), " (uppercased)"),
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
