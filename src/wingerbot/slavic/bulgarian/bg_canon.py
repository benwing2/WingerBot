#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.canon_foreign import canon_one_page_links
from wingerbot.slavic.bulgarian import bg_translit

parser = blib.create_argparser("Change grave to acute in Bulgarian headwords",
    include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

templates_seen = {}
templates_changed = {}
def process_text_on_page(index, pagetitle, text):
  return canon_one_page_links(pagetitle, index, text, "bg", "Cyrl", bg_translit,
      templates_seen, templates_changed)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
blib.output_process_links_template_counts(templates_seen, templates_changed)
