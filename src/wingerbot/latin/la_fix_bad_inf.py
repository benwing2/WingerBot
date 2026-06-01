#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname, msg


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections

    if len(subsections) != 3:
        p.msg(
            "WARNING: Not right # of sections (expected 1): %s"
            % ",".join(subsections[k].strip() for k in range(1, len(subsections), 2))
        )
        return

    if subsecs.headers[2] != "Verb":
        p.msg("WARNING: Expected ===Verb=== in subsections[1] but saw %s" % subsections[1].strip())
        return

    parsed = blib.parse_text(subsections[2])
    infl = None
    lemma = None
    infloft = None
    for t in parsed.filter_templates():
        if tname(t) == "la-verb-form":
            if infl:
                p.msg("WARNING: Saw more than one {{la-verb-form}} call: %s" % str(t))
                return
            infl = getparam(t, "1")
        elif tname(t) == "inflection of":
            if lemma:
                p.msg("WARNING: Saw more than one {{inflection of}} call: %s" % str(t))
                return
            if getparam(t, "lang"):
                lemma = getparam(t, "1")
            else:
                lemma = getparam(t, "2")
            infloft = t
        else:
            p.msg("WARNING: Saw unexpected template: %s" % str(t))
            return
    if not infl or not lemma:
        p.msg("WARNING: Didn't find both inflection %s and lemma %s" % (infl, lemma))
        return
    infl = re.sub(" (esse|īrī)$", "", infl)
    if infl.endswith("us"):
        if infl.endswith("ūrus"):
            partdesc = "Future active participle"
            head_template = "{{la-future participle|%s}}" % infl[:-2]
            infl_template = "{{la-decl-1&2|%s}}" % infl[:-2]
        else:
            if "perf|act" in str(infloft):
                partdesc = "Perfect active participle"
            else:
                partdesc = "Perfect passive participle"
            head_template = "{{la-perfect participle|%s}}" % infl[:-2]
            infl_template = "{{la-decl-1&2|%s}}" % infl[:-2]
        sectext = """
===Etymology===
%s of {{m|la|%s}}.

===Pronunciation===
* {{la-IPA|%s}}

===Participle===
%s

# {{rfdef|la}}

====Declension====
%s""" % (
            partdesc,
            lemma,
            infl,
            head_template,
            infl_template,
        )
        comment = "correct Latin form to participle"
    elif infl.endswith("um"):
        sectext = """
===Etymology===
From {{m|la|%s}}.

===Pronunciation===
* {{la-IPA|%s}}

===Gerund===
{{la-gerund|%s}}

# {{rfdef|la}}

====Declension====
{{la-decl-gerund|%s}}

===Participle===
{{la-part-form|%s}}

# {{inflection of|la|%s||acc|m|s|;|nom//acc//voc|n|s}}""" % (
            lemma,
            infl,
            infl[:-2],
            infl[:-2],
            infl,
            infl[:-2] + "us",
        )
        comment = "correct Latin form to gerund/participle form"
    else:
        p.msg("WARNING: Unrecognized ending for participle/gerund %s" % infl)
        return

    return modsec.rebuild(secbody=sectext), comment


parser = blib.create_argparser(
    "Fix Latin forms wrongly specified as infinitives that should be participles or gerunds",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
