#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

reversed_finals = {
    "ך": "כ",
    "ם": "מ",
    "ן": "נ",
    "ף": "פֿ",
    "ץ": "צ",
}

positive_ending_tags = {
    "ן": ["acc//dat|m|s|", "def//postpositive|dat|n|s"],
    "ען": ["acc//dat|m|s|", "def//postpositive|dat|n|s"],
    "עם": ["acc//dat|m|s|", "def//postpositive|dat|n|s"],
    "ע": ["def|nom//acc|n|s", "nom//acc|f|s", "all-case|p"],
    "ער": ["nom|m|s", "dat|f|s"],
    "ס": ["postpositive|nom//acc|n|s"],
    "עס": ["postpositive|nom//acc|n|s"],
}

rename_templates_with_lang = [
    "inflected form of",
]

rename_templates_without_lang = [
    "yi-inflected form of",
]

rename_templates = rename_templates_with_lang + rename_templates_without_lang


def make_non_final(term):
    last_char = term[-1]
    return term[:-1] + reversed_finals.get(last_char, last_char)


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    subsections = re.split("(^==+[^=\n]+==+\n)", p.text, 0, re.M)
    for j in range(2, len(subsections), 2):
        if not re.search("==(Adjective|Numeral|Ordinal number|Participle)==", subsections[j - 1]):
            continue
        parsed = blib.parse_text(subsections[j])
        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in rename_templates_without_lang:
                lemma = getparam(t, "1")
                langparam = None
                lemmaparam = "1"
            elif tn in rename_templates_with_lang and t.has("lang") and getparam(t, "lang") == "yi":
                lemma = getparam(t, "1")
                langparam = "lang"
                lemmaparam = "1"
            elif tn in rename_templates_with_lang and not t.has("lang") and getparam(t, "1") == "yi":
                lemma = getparam(t, "2")
                langparam = "1"
                lemmaparam = "2"
            else:
                continue

            lemmas_to_try = [make_non_final(lemma)]
            if lemma.endswith("ן"):
                lemmas_to_try.append(lemma[:-1] + "ענ")
            if lemma.endswith("ע"):
                # lemma with a schwa
                lemmas_to_try.append(lemma[:-1])

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
            elif getparam(t, "lang") == "yi":
                # Sometimes |lang=yi redundantly occurs; remove it if so
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
            t.add("1", "yi")
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
        subsections[j] = str(parsed)
    text = "".join(subsections)

    return text, notes


parser = blib.create_argparser(
    "Replace {{yi-inflected form of}} with proper call to {{inflection of}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" for template in rename_templates],
)
