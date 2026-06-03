#!/usr/bin/env python3

import re
from wingerbot import blib


def blacklist(category):
    return False
    # Formerly blacklisted because sort= should be given.
    # if " terms spelled with " in category and not re.search("^(Japanese|Okinawan) ", category):
    #  return True
    # return False


def process_page(p):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if args.verbose:
        p.msg("Processing")
    if p.page.exists():
        p.errandmsg("Page already exists, not overwriting")
        return
    if not p.title.startswith("Category:"):
        p.msg("Page not a category, skipping")
        return
    catname = re.sub("^Category:", "", p.title)
    if blacklist(catname):
        p.msg("Category is blacklisted, skipping")
        return
    if not args.allow_empty:
        has_article_or_subcats = False
        for art in blib.cat_articles(catname):
            has_article_or_subcats = True
            break
        if not has_article_or_subcats:
            for art in blib.cat_subcats(catname):
                has_article_or_subcats = True
        if not has_article_or_subcats:
            p.msg("Skipping empty category")
            return
    contents = "{{auto cat}}"
    result = p.expand_text(contents)
    if not result:
        return
    if (
        "Category:Categories that are not defined in the category tree" in result
        or "Category:Categories with incorrect name" in result
        or "The automatically-generated contents of this category has errors" in result
        or "Lua error in" in result
    ):
        p.msg("Won't create page, would lead to errors: <%s>" % result)
    else:
        p.msg("Creating page, output is <%s>" % result)
        comment = args.comment or 'Created page with "%s"' % contents
        if args.save:
            p.page.text = contents
            if blib.safe_page_save(p.page, comment, p.errandmsg):
                p.errandmsg("Created page, comment = %s" % comment)
        else:
            p.msg("Would create, comment = %s" % comment)


params = blib.create_argparser("Create wanted categories with {{auto cat}}", include_pagefile=True)
params.add_argument("--allow-empty", help="Proceed even when category is empty.", action="store_true")
params.add_argument("--overwrite", help="Overwrite existing text.", action="store_true")
params.add_argument("--comment", help="Comment in place of 'Created page with \"{{auto cat}}\"'.")
args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
