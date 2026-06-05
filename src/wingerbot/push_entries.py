#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


def process_page(p, contents, comment):
    if args.verbose:
        p.msg("For [[%s]]:" % pagename)
        p.msg("------- begin text --------")
        msg(contents.rstrip("\n"))
        msg("------- end text --------")
    if not blib.safe_page_exists(p.page, p.errandmsg):
        return contents, comment
    else:
        insert_before = 0
        curtext = p.text
        secs = blib.split_text_into_sections(curtext, p.msg)
        sections = secs.sections
        for j, langname in secs.lang_list:
            if langname == args.lang:
                p.errandmsg("WARNING: Already found %s section" % args.lang)
                return
            if langname > args.lang:
                insert_before = j - 1
                break
        if insert_before == 0:
            # Add to the end
            newtext = curtext.rstrip("\n") + "\n\n----\n\n" + contents
            return newtext, comment
        sections[insert_before:insert_before] = contents.rstrip("\n") + "\n\n----\n\n"
        return "".join(sections), comment


if __name__ == "__main__":
    parser = blib.create_argparser("Push new entries from generate_entries.py")
    parser.add_argument("--direcfile", help="File containing entries.", required=True)
    parser.add_argument("--comment", help="Comment to use.", required=True)
    parser.add_argument("--lang", help="Language of entries.", required=True)
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    lines = open(args.direcfile, "r", encoding="utf-8")

    index_pagename_text_comment = blib.yield_text_from_find_regex(lines, args.verbose)
    for _, (index, pagename, text, comment) in blib.iter_items(
        index_pagename_text_comment, start, end, get_name=lambda x: x[1], get_index=lambda x: x[0]
    ):
        if comment:
            comment = "%s; %s" % (comment, args.comment)
        else:
            comment = args.comment

        def do_process_page(p):
            return process_page(p, text, comment)

        blib.do_edit(args, index, pagename, do_process_page)
