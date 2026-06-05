#!/usr/bin/env python3

# Batch-find redlinks (non-existent pages) among the lemmas of a language. This speeds up checking by first reading
# all the lemmas in a langauge and checking against them.

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import msg, site

parser = blib.create_argparser("Batch-find red links in a particular language", include_pagefile=True, no_include_stdin=True)
parser.add_argument("--column-file", help="Column-oriented file containing pages to check, separated by tabs or spaces")
parser.add_argument("--langname", help="Language of terms", required=True)
parser.add_argument("--field", help="Field containing terms from --column-file, one-based", type=int, default=1)
parser.add_argument("--output-orig", help="Output original lines from --column-file, separated by || ", action="store_true")
parser.add_argument("--skip-if-non-cyrillic", help="Skip entries containing non-Cyrillic characters", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lemmas = set()
msg("Reading %s lemmas" % args.langname)
for pageindex, page in blib.cat_articles("%s lemmas" % args.langname, start, end):
    lemmas.add(page.title())

def check_page(p, splitline: list[str] | None = None):
    outtext = None
    if args.skip_if_non_cyrillic:
        m = re.search("[^-'Ѐ-џҊ-ԧꚀ-ꚗ]", p.title)
        if m:
            outtext = "skipped due to non-Cyrillic characters"
    if outtext is None:
        for pagenm, pagetype in [
            (p.title, ""),
            (p.title.capitalize(), " (capitalized)"),
            (p.title.upper(), " (uppercased)"),
        ]:
            if pagenm in lemmas:
                outtext = "exists%s" % pagetype
                break
            else:
                page = pywikibot.Page(site, pagenm)
                if blib.safe_page_exists(page, p.errandmsg):
                    text = blib.safe_page_text(page, p.errandmsg)
                    if re.search("#redirect", text, re.I):
                        outtext = "exists%s as redirect" % pagetype
                    elif re.search(r"\{\{superlative of", text):
                        outtext = "exists%s as superlative" % pagetype
                    elif re.search(r"==[ \t]*%s[ \]*==" % re.escape(args.langname), text):
                        outtext = "exists%s as non-lemma" % pagetype
                    else:
                        outtext = "exists%s only in some other language" % pagetype
                    break
        else:
            outtext = "does not exist"
    if args.output_orig:
        assert splitline is not None  # should not be possible to specify --output-orig without --column-file
        msg("| %s || %s || %s" % (p.index, " || ".join(splitline), outtext))
        msg("|-")
    else:
        msg("Page %s [[%s]]: %s" % (p.index, p.title, outtext))

if args.column_file:
    for lineno, line in blib.iter_items_from_file(args.pagefile, start, end):
        splitline = re.split(r"\s", line)
        pagetitle = splitline[args.field - 1]
        def do_check_page(p):
            return check_page(p, splitline)
        blib.do_edit(args, lineno, pagetitle, check_page)
elif args.output_orig:
    raise ValueError("Cannot specify --output-orig unless --column-file is given")
else:
    blib.do_pagefile_cats_refs(args, start, end, check_page)
