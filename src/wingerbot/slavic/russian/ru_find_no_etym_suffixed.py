#!/usr/bin/env python3

# Try to construct etymologies of adjectives and nouns with various suffixes
# from nouns and verbs.

import re

from wingerbot import blib
from wingerbot.blib import msg, tname

from wingerbot.slavic.russian import rulib


def first_palatalization(term):
    conversion = [
        ("ск", "щ"),
        ("к", "ч"),
        ("г", "ж"),
        ("х", "ш"),
        ("ц", "ч"),
    ]
    for ending, converted in conversion:
        if term.endswith(ending):
            return re.sub(ending + "$", converted, term)
    return term


def add_if_not(lst, item):
    if item not in lst:
        lst.append(item)


def find_noun_lemmas(parsed, pagetitle, errandpagemsg, expand_text):
    noun_lemmas = []
    for t in parsed.filter_templates():
        if tname(t) in ["ru-noun+", "ru-proper noun+"]:
            lemmaarg = rulib.fetch_noun_lemma(t, expand_text)
            if lemmaarg is None:
                errandpagemsg("WARNING: Error generating noun forms: %s" % str(t))
                return
            else:
                for lemma in re.split(",", lemmaarg):
                    add_if_not(noun_lemmas, lemma)
        elif tname(t) in ["ru-noun", "ru-proper noun"]:
            for lemma in blib.fetch_param_chain(t, "1", "head", pagetitle):
                add_if_not(noun_lemmas, lemma)
    return noun_lemmas


def process_text_on_page(p):
    notes = []

    # ending and whether final consonant is palatal
    endings = [
        ("ывать", False),
        ("ивать", False),
        ("ать", False),
        ("ять", True),
        ("еть", True),
        ("ить", True),
        ("нуть", False),
        ("ия", True),
        ("ие", True),
        ("я", True),
        ("е", True),
        ("ь", True),
        ("и", True),
        ("а", False),
        ("о", False),
        ("ы", False),
        ("ый", False),
        ("ий", True),
        ("ой", False),
    ]
    stems = []
    for ending, is_palatal in endings:
        if p.title.endswith(ending):
            stem = re.sub(ending + "$", "", p.title)
            stems.append((stem, is_palatal))
    if not stems:
        stems.append((p.title, False))
    possible = []

    def append_possible(stem_to_try, suffix):
        possible.append((stem_to_try.lower() + suffix, suffix))

    # Try -ный/-ной, -ка, -ко
    for stem, palatal in stems:
        stems_to_try = []

        def frob(stem):
            stem = first_palatalization(stem)
            if stem.endswith("л"):
                stem += "ь"
            if re.search("[" + rulib.vowel + "]$", stem):
                stem += "й"
            return stem

        to_try_1 = frob(stem)
        to_try_2 = rulib.dereduce_stem(stem, False)
        if to_try_2:
            to_try_2 = frob(rulib.remove_accents(to_try_2))
        to_try_3 = rulib.dereduce_stem(stem, True)
        if to_try_3:
            to_try_3 = frob(rulib.remove_accents(to_try_3))
        stems_to_try.append(to_try_1)
        if to_try_2:
            stems_to_try.append(to_try_2)
        if to_try_3 and to_try_3 != to_try_2:
            stems_to_try.append(to_try_3)
        for stem_to_try in stems_to_try:
            append_possible(stem_to_try, "ный")
            append_possible(stem_to_try, "ной")
            append_possible(stem_to_try, "ский")
            append_possible(stem_to_try, "ской")
            append_possible(stem_to_try, "ник")
            append_possible(stem_to_try, "чик")
            append_possible(stem_to_try, "щик")
            append_possible(stem_to_try, "ка")
            append_possible(stem_to_try, "ко")
            append_possible(stem_to_try, "ство")
    # Try -овый/-евый/-ёвый/-овой/-евой, -ик, -ок/-ек/-ёк
    for stem, palatal in stems:
        stems_to_try = []
        stems_to_try.append(stem)
        reduced = rulib.reduce_stem(stem)
        if reduced:
            stems_to_try.append(reduced)
        for stem_to_try in stems_to_try:
            if stem_to_try.endswith("й"):
                stem_to_try = stem_to_try[:-1]
            append_possible(stem_to_try, "овый")
            append_possible(stem_to_try, "евый")
            append_possible(stem_to_try, "ёвый")
            append_possible(stem_to_try, "овой")
            append_possible(stem_to_try, "евой")
            stem_to_try = first_palatalization(stem_to_try)
            append_possible(stem_to_try, "еский")
            append_possible(stem_to_try, "ический")
            append_possible(stem_to_try, "ество")
            append_possible(stem_to_try, "ик")
            append_possible(stem_to_try, "ок")
            append_possible(stem_to_try, "ек")
            append_possible(stem_to_try, "ёк")
            append_possible(stem_to_try, "ец")
    # If derived adverbs, try -о, -е, -и
    if args.adverbs:
        for stem, palatal in stems:
            stems_to_try = []
            stems_to_try.append(stem)
        for stem_to_try in stems_to_try:
            append_possible(stem_to_try, "о")
            append_possible(stem_to_try, "е")
            append_possible(stem_to_try, "и")

    would_output = False
    for possible_derived, suffix in possible:
        if possible_derived in derived_lemmas:
            would_output = True
    if not would_output:
        return

    if rulib.check_for_alt_yo_terms(p.text, p.msg):
        return

    base_lemmas = []

    for possible_derived, suffix in possible:
        if possible_derived in derived_lemmas:
            possible_derived_text = blib.find_page_text(possible_derived, p.msg, p.errandmsg)
            if possible_derived_text is None:
                continue
            modsec = blib.find_modifiable_lang_section(possible_derived_text, "Russian", p.msg)
            if modsec is None:
                continue
            derived_section = modsec.secbody
            if "==Etymology" in derived_section:
                p.msg("Skipping derived term %s because it already has an etymology" % possible_derived)
                continue
            derived_defns = blib.find_defns(derived_section, "ru")
            if not derived_defns:
                p.errandmsg("WARNING: Couldn't find definitions for derived term %s" % possible_derived)
                continue

            derived_parsed = blib.parse_text(derived_section)
            page_derived_lemmas = find_noun_lemmas(
                derived_parsed,
                possible_derived,
                p.errandmsg,
                lambda tempcall: blib.expand_text(tempcall, possible_derived, p.msg, args.verbose),
            )
            for t in derived_parsed.filter_templates():
                if tname(t) in ["ru-adj", "ru-adv"]:
                    lemmas = blib.fetch_param_chain(t, "1", "head", possible_derived)
                    trs = blib.fetch_param_chain(t, "tr", "tr")
                    if trs:
                        lemmas = ["%s//%s" % (lemma, tr) for lemma, tr in zip(lemmas, trs)]
                    for lemma in lemmas:
                        add_if_not(derived_lemmas, lemma)

            if not page_derived_lemmas:
                p.errandmsg("WARNING: No derived term lemmas for %s" % possible_derived)
                return

            if not base_lemmas:
                base_parsed = blib.parse_text(p.text)
                base_lemmas = find_noun_lemmas(base_parsed, p.title, p.errandmsg, p.expand_text)

                for t in base_parsed.filter_templates():
                    if tname(t) in ["ru-verb", "ru-adj"]:
                        lemmas = blib.fetch_param_chain(t, "1", "head", p.title)
                        trs = blib.fetch_param_chain(t, "tr", "tr")
                        if trs:
                            lemmas = ["%s//%s" % (lemma, tr) for lemma, tr in zip(lemmas, trs)]
                        for lemma in lemmas:
                            add_if_not(base_lemmas, lemma)

                if not base_lemmas:
                    p.errandmsg("WARNING: No base lemmas")
                    return

                base_lemmas = [rulib.remove_monosyllabic_accents(x) for x in base_lemmas]

                warnings = []
                if len(base_lemmas) > 1:
                    warnings.append("multiple-lemmas")
                if any("//" in lemma for lemma in base_lemmas):
                    warnings.append("translit-in-lemma")

                modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
                if modsec is None:
                    return
                base_section = modsec.secbody
                base_defns = blib.find_defns(base_section, "ru")
                if not base_defns:
                    p.errandmsg("WARNING: Couldn't find definitions for base")
                    return

            def concat_defns(defns):
                return ";".join(defns).replace("_", r"\u").replace(" ", "_")

            suffixes_with_stress = []
            for suf in [suffix, rulib.make_beginning_stressed_ru(suffix), rulib.make_ending_stressed_ru(suffix)]:
                for derived_lemma in page_derived_lemmas:
                    if derived_lemma.endswith(suf):
                        add_if_not(suffixes_with_stress, suf)
            msg(
                "%s %s+-%s%s no-etym possible-suffixed %s //// %s"
                % (
                    ",".join(page_derived_lemmas),
                    ",".join(base_lemmas),
                    ",".join(suffixes_with_stress),
                    " WARNING:%s" % ",".join(warnings) if warnings else "",
                    concat_defns(base_defns),
                    concat_defns(derived_defns),
                )
            )


# Pages specified using --pages or --pagefile may have accents, which will be stripped.
parser = blib.create_argparser(
    "Find etymologies for adjectives and nouns with common suffixes",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--nouns", action="store_true", help="Do derived nouns instead of adjectives")
parser.add_argument("--adverbs", action="store_true", help="Do derived adverbs")
parser.add_argument("--derived-lemmafile", help="File containing derived lemmas")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

derived_lemmas = []
if args.derived_lemmafile:
    derived_lemmas = list(blib.fetch_items_from_file(args.derived_lemmafile, canonicalize=rulib.remove_accents))
else:
    for i, page in blib.cat_articles(
        "Russian adverbs" if args.adverbs else "Russian nouns" if args.nouns else "Russian adjectives"
    ):
        derived_lemmas.append(page.title())

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian adjectives"] if args.adverbs else ["Russian proper nouns", "Russian nouns", "Russian verbs"],
    canonicalize_pagename=rulib.remove_accents,
)
