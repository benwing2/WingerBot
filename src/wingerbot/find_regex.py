#!/usr/bin/env python3

# Find pages that need definitions among a set list (e.g. most frequent words).

import re, sys
import pywikibot

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site


def process_text_on_page(p):
    if args.verbose:
        p.msg("Processing")

    if not args.lang:
        text_to_search = p.text
    else:
        text_to_search_parts = []
        langs = set(re.split(",(?!= )", args.lang))
        secs = blib.split_text_into_sections(p.text, p.msg)
        sections = secs.sections
        for secind, seclang in secs.lang_list:
            if seclang in langs:
                text_to_search_parts.append(sections[secind - 1] + sections[secind])
        text_to_search = "".join(text_to_search_parts)

    def encode(txt):
        if not args.no_encode_embedded_newlines:
            return txt.replace("\n", r"\n")
        else:
            return txt

    def output_match(m):
        if args.output_from_to:
            p.msg("Found match for regex: <from> %s <to> %s <end>" % (encode(m.group(0)), encode(m.group(0))))
        elif args.output_begin_end:
            p.msg("Found match for regex: <begin> %s <end>" % encode(m.group(0)))
        else:
            p.msg("Found match for regex: %s" % encode(m.group(0)))

    if text_to_search:
        found_match = False
        if args.regex is None:
            found_match = True
        elif not args.not_ and not args.only_first_match:
            for m in re.finditer(args.regex, text_to_search, re.M):
                found_match = True
                output_match(m)
        else:
            m = re.search(args.regex, text_to_search, re.M)
            if m:
                found_match = True
                if not args.not_:
                    output_match(m)
        if not found_match and args.not_:
            p.msg("Didn't find match for regex: %s" % args.regex)
        if args.text:
            if not text_to_search.endswith("\n"):
                text_to_search += "\n"
            if found_match == (not args.not_):
                if p.prev_comment:
                    p.msg("Skipped, no changes; previous comment = %s" % p.prev_comment)
                p.msg("-------- begin text --------\n%s-------- end text --------" % text_to_search)


def search_pages(start, end):

    if args.input_from_diff:
        lines = open(args.input_from_diff, "r", encoding="utf-8")
        index_pagename_and_text = blib.yield_text_from_diff(lines, args.verbose)
        for _, (index, pagename, text) in blib.iter_items(
            index_pagename_and_text, start, end, get_name=lambda x: x[1], get_index=lambda x: x[0]
        ):
            process_text_on_page(blib.ProcessPageParams(args, index, pagename, text, None))
        return

    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True, include_comment=True)


if __name__ == "__main__":
    parser = blib.create_argparser("Search on pages", include_pagefile=True, include_stdin=True)
    parser.add_argument("-e", "--regex", help="Regular expression to search for.")
    parser.add_argument(
        "--not",
        dest="not_",
        help="Only output if regex not found in file. This implies --only-first-match.",
        action="store_true",
    )
    parser.add_argument(
        "--input-from-diff", help="Use the specified file as input, a previous output of a job run with --diff."
    )
    parser.add_argument(
        "--only-first-match", help="Only include the first match, instead of all matches.", action="store_true"
    )
    parser.add_argument(
        "--output-from-to",
        help="Output in from-to format (single file for original and changes), for ease in pushing changes.",
        action="store_true",
    )
    parser.add_argument(
        "--output-begin-end",
        help="Output in split begin-end format (separate files for original and changes), for ease in pushing changes.",
        action="store_true",
    )
    parser.add_argument(
        "--no-encode-embedded-newlines",
        help="Don't convert embedded newlines to '\\n' (normally done to keep everything on one line).",
        action="store_true",
    )
    parser.add_argument("--text", help="Include full text of page or language section.", action="store_true")
    parser.add_argument("--lang", help="Only search the specified language section(s) (comma-separated).")
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    if not args.regex and not args.text:
        raise ValueError("-e (--regex) must be given unless --text is given")
    search_pages(start, end)
