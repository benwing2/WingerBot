#!/usr/bin/env python3

import re

from wingerbot import blib, msg
from wingerbot.canon_foreign import canon_links
from wingerbot.slavic.russian import ru_translit

parser = blib.create_argparser("Canonicalize Russian and translit")
parser.add_argument(
    "--cattype",
    default="borrowed",
    help="""Categories to examine ('vocab', 'borrowed', 'translation',
'links', 'pagetext', 'pages', an arbitrary category or comma-separated list)""",
)
parser.add_argument(
    "--page-file",
    help="""File containing "pages" to process when --cattype pagetext,
or list of pages when --cattype pages""",
)

args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
pages_to_do = []
if args.page_file:
    for line in open(args.page_file, "r", encoding="utf-8"):
        line = line.strip()
        # FIXME: We don't yet support a cattype list containing 'pages'
        if args.cattype == "pages":
            pages_to_do.append(line)
        else:
            m = re.match(r"^Page [0-9]+ (.*?): [^:]*: Processing (.*?)$", line)
            if not m:
                msg("WARNING: Unable to parse line: [%s]" % line)
            else:
                pages_to_do.append(m.groups())

canon_links(
    args.save,
    args.verbose,
    args.cattype,
    "ru",
    "Russian",
    "Cyrl",
    ru_translit,
    start,
    end,
    pages_to_do=pages_to_do,
)
