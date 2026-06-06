#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg
from wingerbot.arabic.arlib import reorder_shadda


def process_text_on_page(p):
    if args.verbose:
        msg("Processing %s" % p.title)
    # blib.msg("From: [[%s]], To: [[%s]]" % (args.refrom, args.reto))
    text = p.text
    origtext = text
    if args.reorder_shadda:
        text = reorder_shadda(text)
    zipped_fromto = list(zip(args.refrom, args.reto))

    def replace_text(text):
        for fromval, toval in zipped_fromto:
            if args.title:
                fromval = fromval.replace(args.title, re.escape(p.title))
                toval = toval.replace(args.title, p.title)
            text = re.sub(fromval, toval, text, 0, re.M)
        return text

    if not args.lang_only:
        text = replace_text(text)
    else:
        sec_to_replace = None
        foundlang = False
        secs = blib.split_text_into_sections(text, p.msg)

        for j, header in secs.lang_list:
            if header == args.lang_only:
                if foundlang:
                    p.msg("WARNING: Found multiple %s sections, skipping page" % args.lang_only)
                    if args.warn_on_no_replacement:
                        p.msg("WARNING: No replacements made")
                    return
                foundlang = True
                sec_to_replace = j
                break

        if sec_to_replace is None:
            if args.warn_on_no_replacement:
                p.msg("WARNING: No replacements made")
            return
        secs.sections[sec_to_replace] = replace_text(secs.sections[sec_to_replace])
        text = "".join(secs.sections)
    if args.warn_on_no_replacement and text == origtext:
        p.msg("WARNING: No replacements made")
    return text, args.comment or "replace %s" % (", ".join("%s -> %s" % (f, t) for f, t in zipped_fromto))


parser = blib.create_argparser("Search and replace on pages")
parser.add_argument(
    "-f",
    "--from",
    help="From regex, can be specified multiple times",
    metavar="FROM",
    dest="from_",
    required=True,
    action="append",
)
parser.add_argument("-t", "--to", help="To regex, can be specified multiple times", required=True, action="append")
parser.add_argument("--comment", help="Specify the change comment to use")
parser.add_argument("--pagetitle", help="Value to substitute page title with")
parser.add_argument("--lang-only", help="Only replace in the specified language section")
parser.add_argument("--reorder-shadda", help="Reorder shadda + short vowel to fix Unicode bug")
parser.add_argument("--warn-on-no-replacement", action="store_true", help="Warn if no replacements made")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

refrom = list(args.from_)
reto = list(args.to)

if len(refrom) != len(reto):
    raise ValueError("Same number of --from and --to arguments must be specified")


blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
