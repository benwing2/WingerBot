#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg

from wingerbot.latin import lalib


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    def process_etym_section(secnum, sectext):
        if "==Pronunciation 1==" not in sectext:
            p.msg("No ==Pronunciation 1== in %s" % ("etym section" if secnum is not None else "text"))
            return sectext

        if secnum is not None:
            equalsigns = "===="
        else:
            equalsigns = "==="
        subsecs = blib.split_text_into_subsections(sectext, p.msg)
        subsections = subsecs.subsections

        if len(subsections) > 2 and subsections[1] == "===Etymology===\n":
            # Allow for an Etymology section at the beginning (many examples have one,
            # saying e.g. "Inflected form of {{m|la|pulchellus||beautiful little}}.".
            offset = 2
        else:
            offset = 0
        if not (
            len(subsections) == 9 + offset
            or (len(subsections) == 11 + offset and subsections[9 + offset] == "===References===\n")
        ):
            p.msg(
                "WARNING: Not right # of sections (normally four, potentially five or six with ===Etymology=== and/or ===References===): %s"
                % (",".join(subsections[k].strip() for k in range(1, len(subsections), 2)))
            )
            return sectext
        if subsections[1 + offset] != "%sPronunciation 1%s\n" % (equalsigns, equalsigns) or subsections[
            5 + offset
        ] != "%sPronunciation 2%s\n" % (equalsigns, equalsigns):
            p.msg(
                "WARNING: Expected %sPronunciation N%s headers but saw %s and %s"
                % (equalsigns, equalsigns, subsections[1 + offset].strip(), subsections[5 + offset].strip())
            )
            return sectext
        if subsections[3 + offset] != subsections[7 + offset]:
            if secnum is not None:
                p.msg(
                    "WARNING: Already in etym section and saw different POS headers %s and %s, can't convert to etym sections"
                    % (subsections[3 + offset].strip(), subsections[7 + offset].strip())
                )
                return sectext
            elif offset > 0:
                p.msg(
                    "WARNING: Already have ===Etymology=== section and saw different POS headers %s and %s, can't convert to etym sections"
                    % (subsections[3 + offset].strip(), subsections[7 + offset].strip())
                )
                return sectext
            else:
                p.msg(
                    "Saw different POS headers %s and %s"
                    % (subsections[3 + offset].strip(), subsections[7 + offset].strip())
                )
                subsections[1 + offset] = "===Etymology 1===\n\n====Pronunciation====\n"
                subsections[2 + offset] = re.sub(r"^\{\{rfc-pron-n\|.*?\}\}\n", "", subsections[2 + offset], 0, re.M)
                subsections[5 + offset] = "===Etymology 2===\n\n====Pronunciation====\n"
                notes.append(
                    "Combined ===Pronunciation 1=== and ===Pronunciation 2=== to ===Etymology 1=== and ===Etymology 2=== because different parts of speech/lemmas"
                )
                return "".join(subsections)

        else:

            def find_lemmas(text):
                lemmas = set()
                parsed = blib.parse_text(text)
                for t in parsed.filter_templates():
                    if tname(t) == "inflection of":
                        if getparam(t, "lang"):
                            lemmas.add(getparam(t, "1"))
                        else:
                            lemmas.add(getparam(t, "2"))
                return lemmas

            first_lemmas = find_lemmas(subsections[4 + offset])
            second_lemmas = find_lemmas(subsections[8 + offset])
            if first_lemmas != second_lemmas:
                p.msg(
                    "WARNING: Different lemmas in two POS sections: %s and %s"
                    % (",".join(first_lemmas), ",".join(second_lemmas))
                )
                return sectext

            # For verbs with the infinitive in the second section, swap the
            # sections to put the infinitive first.
            if re.search(r"\|inf[|}]", subsections[8 + offset]):
                temptext = subsections[4 + offset]
                subsections[4 + offset] = subsections[8 + offset]
                subsections[8 + offset] = temptext
                temptext = subsections[2 + offset]
                subsections[2 + offset] = subsections[6 + offset]
                subsections[6 + offset] = temptext
                notes.append("swap non-lemma sections to put infinitive first")

            subsections[1 + offset] = "%sPronunciation%s\n" % (equalsigns, equalsigns)
            subsections[3 + offset] = re.sub(
                "^=+", equalsigns, re.sub("=+\n$", equalsigns + "\n", subsections[3 + offset])
            )
            subsections[7 + offset] = re.sub(
                "^=+", equalsigns, re.sub("=+\n$", equalsigns + "\n", subsections[7 + offset])
            )
            subsections[2 + offset] = subsections[2 + offset].strip() + "\n" + subsections[6 + offset].strip() + "\n\n"
            parsed = blib.parse_text(subsections[2 + offset])
            for t in parsed.filter_templates():
                if tname(t) == "la-IPA":
                    t.add("ann", "1")
            subsections[2 + offset] = str(parsed)
            subsections[2 + offset] = re.sub(r"^\{\{rfc-pron-n\|.*?\}\}\n", "", subsections[2 + offset], 0, re.M)
            del subsections[6 + offset]
            del subsections[5 + offset]
            notes.append(
                "combine %sPronunciation 1%s and %sPronunciation 2%s" % (equalsigns, equalsigns, equalsigns, equalsigns)
            )
            return "".join(subsections)

    secbody = blib.map_etym_sections(secbody, p.msg, process_etym_section)
    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Convert ==Pronunciation 1=== and ===Pronunciation 2=== pages of certain recognizable formats to more standard format",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
