#!/usr/bin/env python3

# Find redlinks (non-existent pages).

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import msg, errandmsg, site

parser = blib.create_argparser("Find red links")
parser.add_argument("--pagefile", help="File containing pages to check")
parser.add_argument("--lang", help="Language of terms")
parser.add_argument("--field", help="Field containing terms", type=int, default=1)
parser.add_argument("--output-orig", help="Output original lines", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lemmas = set()
msg("Reading %s lemmas" % args.lang)
for index, page in blib.cat_articles("%s lemmas" % args.lang, start, end):
    lemmas.add(page.title())

words_freq = {}

for index, line in blib.iter_items_from_file(args.pagefile, start, end):
    pagename = re.split(r"\s", line)[args.field - 1]
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagename, txt))
    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagename, txt))
    m = re.search("[^-'Ѐ-џҊ-ԧꚀ-ꚗ]", pagename)
    if m:
        outtext = "skipped due to non-Cyrillic characters"
    else:
        for pagenm, pagetype in [
            (pagename, ""),
            (pagename.capitalize(), " (capitalized)"),
            (pagename.upper(), " (uppercased)"),
        ]:
            if pagenm in lemmas:
                outtext = "exists%s" % pagetype
                break
            else:
                page = pywikibot.Page(site, pagenm)
                if page.exists():
                    text = blib.safe_page_text(page, errandpagemsg)
                    if re.search("#redirect", text, re.I):
                        outtext = "exists%s as redirect" % pagetype
                    elif re.search(r"\{\{superlative of", text):
                        outtext = "exists%s as superlative" % pagetype
                    elif "==%s==" % args.lang in text:
                        outtext = "exists%s as non-lemma" % pagetype
                    else:
                        outtext = "exists%s only in some other language" % pagetype
                    break
        else:
            outtext = "does not exist"
    if args.output_orig:
        msg("| %s || %s || %s" % (index, " || ".join(line), outtext))
        msg("|-")
    else:
        msg("Page %s [[%s]]: %s" % (index, pagename, outtext))
