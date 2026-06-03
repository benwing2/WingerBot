#!/usr/bin/env python3

# FIXME: Unlikely to work, as it has never been tested.

import re

from wingerbot import blib
from wingerbot.blib import msg, getparam, remove_links
from wingerbot.arabic.arlib import (
    reorder_shadda,
    arabic_all_headword_templates,
    remove_diacritics,
)


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Arabic", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    etymologies = []
    etymsections = []
    sechead = subsections[0]
    if "\n===Etymology 1=" in secbody:
        etyms_were_separate = True
        for j in range(1, len(subsections), 2):
            if not re.match("^===Etymology [0-9]+=", subsections[j]):
                p.msg(
                    "WARNING: Non-etymology level-3 header when split etymologies: %s" % subsections[j][0:-1]
                )
        etymsections = [subsections[j] for j in range(2, len(subsections), 2)]
        # Reduce indent by one. We will increase it again when we split
        # etymologies.
        for j in range(len(etymsections)):
            etymsections[j] = re.sub("^==", "=", etymsections[j], 0, re.M)
    else:
        etyms_were_separate = False
        etymsections = "".join(subsections[1:])

    for etymsection in etymsections:
        subsections = re.split("(^===[^=\n]+=+\n)", etymsection, 0, re.M)
        if len(subsections) < 2:
            p.msg("WARNING: Section missing any entries")
        split_sections = []
        next_split_section = 0

        def append_section(k):
            while len(split_sections) <= next_split_section:
                split_sections.append("")
            split_sections[next_split_section] += subsections[k] + subsections[k + 1]

        last_lemma = None
        last_inflection_of_lemma = None
        for j in range(1, len(subsections), 2):
            if re.match("^===+(References|Related|See)", subsections[j]):
                p.msg("Found level-3 section that should maybe be at higher level: %s" % subsections[j][0:-1])
                append_section(j)
            elif re.match("^===+(Alternative|Etymology)", subsections[j]):
                append_section(j)
            else:
                parsed = blib.parse_text(subsections[j + 1])
                lemma = None
                inflection_of_lemma = None
                for t in parsed.filter_templates():
                    if t.name in arabic_all_headword_templates:
                        if lemma:
                            if t.name not in ["ar-nisba", "ar-noun-nisba", "ar-verb", "ar-verb-form"]:
                                p.msg(
                                    "Found multiple headword templates in section %s: %s"
                                    % (j, subsections[j][0:-1])
                                )
                        # Note: For verbs this is the form class, which we match on
                        lemma = reorder_shadda(remove_links(getparam(t, "1")))
                    if t.name == "inflection of":
                        if inflection_of_lemma:
                            p.msg(
                                "Found multiple 'inflection of' templates in section %s: %s"
                                % (j, subsections[j][0:-1])
                            )
                        inflection_of_lemma = remove_diacritics(remove_links(getparam(t, "1")))
                if not lemma:
                    p.msg("Warning: No headword template in section %s: %s" % (j, subsections[j][0:-1]))
                    append_section(j)
                else:
                    if lemma != last_lemma:
                        next_split_section += 1
                    elif (
                        inflection_of_lemma
                        and last_inflection_of_lemma
                        and inflection_of_lemma != last_inflection_of_lemma
                    ):
                        p.msg(
                            "Verb forms have different inflection-of lemmas %s and %s, splitting etym"
                            % (last_inflection_of_lemma, inflection_of_lemma)
                        )
                        next_split_section += 1
                    last_lemma = lemma
                    last_inflection_of_lemma = inflection_of_lemma
                    append_section(j)
        etymologies += split_sections

    # Combine adjacent etymologies with same verb form class I.
    # FIXME: We might not want to do this; the etymologies might be
    # legitimately split. Need to check each case.
    j = 0
    while j < len(etymologies) - 1:
        def get_form_class(k):
            formclass = None
            parsed = blib.parse_text(etymologies[j])
            for t in parsed.filter_templates():
                if t.name in ["ar-verb", "ar-verb-form"]:
                    newformclass = getparam(t, "1")
                    if formclass and newformclass and formclass != newformclass:
                        p.msg(
                            "WARNING: Something wrong: Two different verb form classes in same etymology: %s != %s"
                            % (formclass, newformclass)
                        )
                    formclass = newformclass
            return formclass

        formclassj = get_form_class(j)
        formclassj1 = get_form_class(j + 1)
        if formclassj == "I" and formclassj1 == "I":
            if not etymologies[j + 1].startswith("="):
                p.msg(
                    "WARNING: Can't combine etymologies with same verb form class because second has etymology text"
                )
            else:
                p.msg("Combining etymologies with same verb form class I")
                etymologies[j] = etymologies[j].rstrip() + "\n\n" + etymologies[j + 1]
                # Cancel out effect of incrementing j below since we combined
                # the following etymology into this one
                j -= 1
        j += 1

    if len(etymologies) > 1:
        for j in range(len(etymologies)):
            # Stuff like "===Alternative forms===" that goes before the
            # etymology section should be moved after.
            newetymj = re.sub(r"^(.*?\n)(===Etymology===\n(\n|[^=\n].*?\n)*)", r"\2\1", etymologies[j], 0, re.S)
            if newetymj != etymologies[j]:
                p.msg("Moved ===Alternative forms=== and such after Etymology")
                etymologies[j] = newetymj
            # Remove ===Etymology=== from beginning
            etymologies[j] = re.sub("^===Etymology===\n", "", etymologies[j])
            # Fix up newlines around etymology section
            etymologies[j] = etymologies[j].strip() + "\n\n"
            if etymologies[j].startswith("="):
                etymologies[j] = "\n" + etymologies[j]
        secbody = sechead + "".join(
            ["===Etymology %s===\n" % (j + 1) + etymologies[j] for j in range(len(etymologies))]
        )
    elif len(etymologies) == 1:
        if etyms_were_separate:
            # We might need to add an Etymology header at the beginning.
            p.msg("Combined formerly separate etymologies")
            if not re.match(r"^(=|\{\{wikipedia|\[\[File:)", etymologies[0].strip()):
                etymologies[0] = "===Etymology===\n" + etymologies[0]
                p.msg("Added Etymology header when previously separate etymologies combined")
            # Put Alternative forms section before Etymology.
            newetym0 = re.sub(
                r"^((?:\n|[^=\n].*?\n)*)(===Etymology===\n(?:\n|[^=\n].*?\n)*)(===(Alternative.*?)===\n(?:\n|[^=\n].*?\n)*)",
                r"\1\3\2",
                etymologies[0],
                0,
                re.S,
            )
            if newetym0 != etymologies[0]:
                p.msg("Moved ===Alternative forms=== and such before Etymology")
                etymologies[0] = newetym0

        secbody = sechead + etymologies[0]
    else:
        secbody = sechead

    return modsec.rebuild(secbody=secbody), "FIXME: Write this"


parser = blib.create_argparser("Split Arabic etymology sections", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
                           default_cats=["Arabic lemmas"])
