#!/usr/bin/env python3

import re
from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

inflection_of_templates = ["inflection of", "noun form of", "verb form of", "adj form of", "participle of"]


def process_text_on_page(p):
    if all(x not in p.text for x in inflection_of_templates):
        return

    subsecs = blib.split_text_into_subsections(p.text, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        for template in inflection_of_templates:
            if re.search(r"^[#*]+ \{\{%s.*\n[#*]+ \{\{%s.*" % (template, template), subsections[k], re.M):
                p.msg("Found subsection with combinable %s:\n%s" % (template, subsections[k].strip()))


parser = blib.create_argparser(
    "Find occurrences of multiple 'inflection of' tags in a single subsection",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
