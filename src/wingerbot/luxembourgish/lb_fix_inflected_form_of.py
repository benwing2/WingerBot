#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

positive_ending_tags = {
    "en": ["str//wk|nom//acc|m|s", "wk|dat|m//n|s", "str//wk|dat|p"],
    "em": ["str|dat|m//n|s"],
    "er": ["str//wk|dat|f|s"],
    "t": ["str//wk|nom//acc|n|s"],
}

rename_templates_with_lang = [
    "inflected form of",
]

rename_templates_without_lang = [
    "lb-inflected form of",
]

rename_templates = rename_templates_with_lang + rename_templates_without_lang


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    subsecs = blib.split_text_into_subsections(p.text, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if not re.search("^(Adjective|Numeral|Ordinal Numeral|Participle)$", header):
            continue
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in rename_templates_without_lang:
                lemma = getparam(t, "1")
                langparam = None
                lemmaparam = "1"
            elif tn in rename_templates_with_lang and t.has("lang") and getparam(t, "lang") == "lb":
                lemma = getparam(t, "1")
                langparam = "lang"
                lemmaparam = "1"
            elif tn in rename_templates_with_lang and not t.has("lang") and getparam(t, "1") == "lb":
                lemma = getparam(t, "2")
                langparam = "1"
                lemmaparam = "2"
            else:
                continue

            lemmas_to_try = [lemma]
            if lemma.endswith("e"):
                # lemma with a schwa
                lemmas_to_try.append(lemma[:-1])
            if lemma == "gutt":
                lemmas_to_try.append("gudd")

            ending_sets_to_try = [positive_ending_tags]

            endings_to_try = []
            for ending_sets in ending_sets_to_try:
                for ending, tag_sets in ending_sets.items():
                    if p.title.endswith(ending):
                        endings_to_try.append((ending, tag_sets))
            if len(endings_to_try) == 0:
                p.msg("WARNING: Can't identify ending of non-lemma form, skipping")
                continue
            found_combinations = []
            for ending_to_try, tag_sets in endings_to_try:
                for lemma_to_try in lemmas_to_try:
                    if lemma_to_try + ending_to_try == p.title:
                        found_combinations.append((lemma_to_try, ending_to_try, tag_sets))
            if len(found_combinations) == 0:
                p.msg(
                    "WARNING: Can't match lemma %s with page title (tried lemma variants %s and endings %s), skipping"
                    % (
                        lemma,
                        "/".join(lemmas_to_try),
                        "/".join(ending_to_try for ending_to_try, tag_sets in endings_to_try),
                    )
                )
                continue
            if len(found_combinations) > 1:
                p.msg(
                    "WARNING: Found multiple possible matching endings for lemma %s (found possibilities %s), skipping"
                    % (
                        lemma,
                        "/".join(
                            "%s+%s" % (lemmas_to_try, endings_to_try)
                            for lemma_to_try, ending_to_try, tag_sets in found_combinations
                        ),
                    )
                )
                continue
            lemma_to_try, ending_to_try, tag_sets = found_combinations[0]
            # Erase all params.
            if langparam:
                rmparam(t, langparam)
            elif getparam(t, "lang") == "lb":
                # Sometimes |lang=lb redundantly occurs; remove it if so
                rmparam(t, "lang")
            rmparam(t, lemmaparam)
            tr = getparam(t, "tr")
            rmparam(t, "tr")
            if len(t.params) > 0:
                p.msg("WARNING: Original template %s has extra params, skipping" % origt)
                return
            # Set new name
            blib.set_template_name(t, "inflection of")
            # Put back new params.
            t.add("1", "lb")
            t.add("2", lemma)
            if tr:
                t.add("tr", tr)
            t.add("3", "")
            nextparam = 4
            for tag in "|;|".join(tag_sets).split("|"):
                t.add(str(nextparam), tag)
                nextparam += 1
            notes.append("replace %s with %s" % (origt, str(t)))
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))
        subsections[k] = str(parsed)
    text = "".join(subsections)

    return text, notes


parser = blib.create_argparser(
    "Replace {{lb-inflected form of}} with proper call to {{inflection of}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    new=True,
    default_refs=["Template:%s" for template in rename_templates],
)
