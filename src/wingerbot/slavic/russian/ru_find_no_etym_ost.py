#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname
from wingerbot.slavic.russian import rulib

nouns = []


def process_text_on_page(p):
    if not re.search("[иы]й$", p.title):
        p.msg("Skipping adjective not in -ый or -ий")
        return

    noun = re.sub("[иы]й$", "ость", p.title)
    if noun not in nouns:
        return

    if rulib.check_for_alt_yo_terms(p.text, p.msg):
        return

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-adj":
            heads = blib.fetch_param_chain(t, "1", "head", p.title)
            if len(heads) > 1:
                p.msg("Skipping adjective with multiple heads: %s" % ",".join(heads))
                continue
            pp = blib.create_process_page_params(
                args, p.index, noun, must_exist=True, msg_index="%s: %s" % (p.title, noun)
            )
            if pp is None:
                continue
            modsec = blib.find_modifiable_lang_section(pp.text, "Russian", pp.msg)
            if modsec is None:
                continue
            nounsection = modsec.secbody
            if "==Etymology" in nounsection:
                pp.msg("Noun %s already has etymology" % noun)
                continue
            tr = getparam(t, "tr")
            if tr:
                msg("%s %s+tr1=%s+-ость no-etym" % (noun, heads[0], tr))
            else:
                msg("%s %s+-ость no-etym" % (noun, heads[0]))


# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser(
    "Try to construct etymologies of nouns in -ость from adjectives",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for i, page in blib.cat_articles("Russian nouns"):
    nouns.append(page.title())

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Russian adjectives"],
    canonicalize_pagename=rulib.remove_accents,
)
