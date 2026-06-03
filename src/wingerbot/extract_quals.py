#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import pname, msg
from collections import defaultdict

all_quals = defaultdict(int)


def process_text_on_page(p):
    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        for param in t.params:
            pn = pname(param)
            if "qual" in pn:
                pv = str(param.value).strip()
                quals = re.split(" *, *", pv)
                for qual in quals:
                    all_quals[qual] += 1


parser = blib.create_argparser(
    "Extract qualifiers from separate qualifier params", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

for qual, count in sorted(all_quals.items(), key=lambda x: -x[1]):
    msg("%40s: %s" % (qual, count))
