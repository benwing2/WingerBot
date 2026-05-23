#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

from wingerbot import blib
from wingerbot.blib import msg
from wingerbot.canon_foreign import canon_links
from wingerbot.greek import grc_translit

parser = blib.create_argparser("Canonicalize Greek and translit")
parser.add_argument("--cattype", default="borrowed",
    help="""Categories to examine ('vocab', 'borrowed', 'translation',
'links', 'pagetext', 'pages' or comma-separated list)""")
parser.add_argument("--page-file",
    help="""File containing "pages" to process when --cattype pagetext,
or list of pages when --cattype pages""")

params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)
pages_to_do = []
if params.page_file:
  for line in open(params.page_file, "r", encoding="utf-8"):
    line = line.strip()
    if params.cattype == "pages":
      pages_to_do.append(line)
    else:
      m = re.match(r"^Page [0-9]+ (.*?): [^:]*: Processing (.*?)$", line)
      if not m:
        m = re.match(r"\* \[\[(.*?)]]: .*?<nowiki>(.*?)</nowiki>$", line)
      if not m:
        msg("WARNING: Unable to parse line: [%s]" % line)
      else:
        pages_to_do.append(m.groups())

canon_links(params.save, params.verbose, params.cattype, "grc", "Ancient Greek",
    ["polytonic", "Grek"], grc_translit, start, end,
    pages_to_do=pages_to_do)
