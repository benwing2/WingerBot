#!/usr/bin/env python3

import re
from wingerbot import blib
from wingerbot.blib import msg, site
import pywikibot
import pywikibot.exceptions


def rename_page(p, totitle, comment, refrom, reto):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if refrom and reto:
        zipped_fromto = list(zip(refrom, reto))
    else:
        zipped_fromto = []

    def replace_text(text):
        for fromval, toval in zipped_fromto:
            text = re.sub(fromval, toval, text)
        return text

    this_comment = (
        comment
        or zipped_fromto
        and "rename based on regex %s" % (", ".join("%s -> %s" % (f, t) for f, t in zipped_fromto))
        or "rename page"
    )
    if not blib.safe_page_exists(p.page, p.errandmsg):
        p.msg("Skipping because page doesn't exist")
        return
    if args.verbose:
        p.msg("Processing")
    if not totitle:
        totitle = replace_text(p.title)
    if totitle == p.title:
        p.msg("WARNING: Regex doesn't match, not renaming to same name")
    else:
        new_page = pywikibot.Page(site, totitle)
        if blib.safe_page_exists(new_page, p.errandmsg):
            p.errandmsg("Destination page %s already exists, not moving" % totitle)
            return
        elif args.save:
            try:
                p.page.move(totitle, reason=this_comment, movetalk=True, noredirect=not args.with_redirect)
                p.errandmsg("Renamed to %s" % totitle)
            except pywikibot.exceptions.PageRelatedError as error:
                p.errandmsg("Error moving to %s: %s" % (totitle, error))
                return
        else:
            p.msg("Would rename to %s (comment=%s)" % (totitle, this_comment))


def delete_page(p, comment):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    if args.verbose:
        p.msg("Processing")
    this_comment = comment or "delete page"
    if blib.safe_page_exists(p.page, p.errandmsg):
        if args.save:
            existing_text = blib.safe_page_text_or_none(p.page, p.errandmsg)
            if existing_text is not None:
                p.page.delete('%s (content was "%s")' % (this_comment, existing_text))
                p.errandmsg("Deleted (comment=%s)" % this_comment)
        else:
            p.msg("Would delete (comment=%s)" % this_comment)
    else:
        p.msg("Skipping, page doesn't exist")


if __name__ == "__main__":
    params = blib.create_argparser("Rename pages", include_pagefile=True)
    params.add_argument(
        "-f",
        "--from",
        help="From regex, can be specified multiple times",
        metavar="FROM",
        dest="from_",
        action="append",
    )
    params.add_argument("-t", "--to", help="To regex, can be specified multiple times", action="append")
    params.add_argument("--rename-comment", "--comment", help="Specify the change comment to use when renaming")
    params.add_argument("--delete-comment", help="Specify the change comment to use when deleting")
    params.add_argument(
        "--delete-from-direcfile",
        action="store_true",
        help="If only a single page given in --direcfile on a line, delete it.",
    )
    params.add_argument(
        "--with-redirect",
        action="store_true",
        help="If specified, redirects are created from the old page to the new page.",
    )
    params.add_argument("--direcfile", help="File containing pairs of from/to pages to rename, separated by ' ||| '.")
    args = params.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    from_ = list(args.from_) if args.from_ else []
    to = list(args.to) if args.to else []

    if len(from_) != len(to):
        raise ValueError("Same number of --from and --to arguments must be specified")

    if args.delete_from_direcfile:
        pages_to_delete = []
        pages_to_rename = []
        for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
            if " ||| " not in line:
                pages_to_delete.append((lineno, line))
            else:
                frompage, topage = line.split(" ||| ")
                pages_to_rename.append((lineno, frompage, topage))
        for index, pagetitle in pages_to_delete:
            delete_page(blib.ProcessPageParams(args, index, pagetitle, "", page=pywikibot.Page(site, pagetitle)),
                        args.delete_comment)
        for index, frompage, topage in pages_to_rename:
            rename_page(blib.ProcessPageParams(args, index, frompage, "", page=pywikibot.Page(site, frompage)),
                        topage, args.rename_comment, from_, to)
    elif args.direcfile:
        for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
            if " ||| " not in line:
                msg("Line %s: WARNING: Saw bad line in --from-to-pagefile: %s" % (lineno, line))
                continue
            frompage, topage = line.split(" ||| ")
            rename_page(blib.ProcessPageParams(args, lineno, frompage, "", page=pywikibot.Page(site, frompage)),
                        topage, args.rename_comment, from_, to)
    else:

        def do_process_page(p):
            return rename_page(p, None, args.rename_comment, from_, to)

        blib.do_pagefile_cats_refs(args, start, end, do_process_page, no_fetch_text=True)
