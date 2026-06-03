#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, errmsg


def process_subpage(origindex, origpagetitle, index, page):
    pagetitle = page.title()
    def pagemsg(txt):
        msg("Page %s %s: %s %s: %s" % (origindex, origpagetitle, index, pagetitle, txt))

    # if pagetitle.startswith("Template:"):
    if args.redirects_only:
        pagemsg("Found redirect")
    else:
        pagemsg("Found reference")


def process_text_on_page(p):
    def errpagemsg(txt):
        errmsg("Page %s %s: %s" % (p.index, p.title, txt))

    errpagemsg("Processing references")
    if not args.table_of_uses:
        p.msg("Processing references")
    aliases = []
    for i, subpage in blib.references(
        p.title, namespaces=[10], only_template_inclusion=False, filter_redirects=args.redirects_only
    ):
        aliases.append(subpage.title())
        if not args.table_of_uses:
            process_subpage(p.index, p.title, i, subpage)
    if args.table_of_uses:
        msg(
            "%s%s"
            % (
                p.title.replace("Template:", ""),
                aliases and "," + ",".join(x.replace("Template:", "") for x in aliases) or "",
            )
        )


parser = blib.create_argparser("Find templates transcluding a given page", include_pagefile=True, include_stdin=True)
parser.add_argument("--redirects-only", help="""Only output redirects.""", action="store_true")
parser.add_argument("--table-of-uses", action="store_true", help="""Output in table_of_uses.py input format.""")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
