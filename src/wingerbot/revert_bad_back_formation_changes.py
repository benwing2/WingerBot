#!/usr/bin/env python3

from wingerbot import blib

# clean_etym_templates.py had a bug in it that it wasn't idempotent w.r.t. adding a
# period after back-formation templates without nodot=, leading it to add extraneous
# periods in some cases. This script undoes the damage.


def process_page(p):
    if p.page is None:
        raise ValueError("Cannot run on text from stdin")
    revisions = list(p.page.revisions(total=1))
    for rev in revisions:
        if rev["user"] != "WingerBot" or (
            not rev["comment"].startswith("add period to back-formation template without nodot=")
        ):
            p.errandpagemsg("WARNING: Can't revert page, another change happened since then")
        else:
            oldrevid = rev["_parent_id"]
            if oldrevid:
                oldtext = p.page.getOldVersion(oldrevid)
                return oldtext, "Undo faulty addition of period after back-formation template"


parser = blib.create_argparser("Undo extraneously-added periods after back-formation templates", include_pagefile=True, no_include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_page, no_fetch_text=True)
