#!/usr/bin/env python3

# Convert head|fr|* templates to the appropriate template.

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "head" and getparam(t, "1") == "fr":
            headtype = getparam(t, "2")
            fixed_plural_warning = False
            if headtype == "noun":
                head = getparam(t, "head")
                g = getparam(t, "g")
                g2 = getparam(t, "g2")
                plural = ""
                if getparam(t, "3") == "plural":
                    plural = getparam(t, "4")
                unrecognized_params = False
                for param in t.params:
                    pname = str(param.name)
                    if pname in ["1", "2", "head", "g", "g2", "sort"] or plural and pname in ["3", "4"]:
                        pass
                    else:
                        unrecognized_params = True
                        break
                if unrecognized_params:
                    p.msg("WARNING: Unrecognized parameters in %s, skipping" % str(t))
                    continue
                if not g:
                    p.msg("WARNING: No gender given in %s, skipping" % str(t))
                    continue
                found_feminine_noun = False
                if g == "f" and not g2 and not plural:
                    for tt in parsed.filter_templates():
                        if str(tt.name) == "feminine noun of" and getparam(tt, "lang") == "fr":
                            found_feminine_noun = True
                if found_feminine_noun:
                    p.msg("Found 'feminine noun of', assuming countable")
                elif g not in ["m-p", "f-p"] and not plural:
                    if args.fix_missing_plurals:
                        p.msg("WARNING: No plural given in %s, assuming default plural, PLEASE REVIEW" % str(t))
                        fixed_plural_warning = True
                    else:
                        p.msg("WARNING: No plural given in %s, skipping" % str(t))
                        continue
                rmparam(t, "4")
                rmparam(t, "3")
                rmparam(t, "2")
                rmparam(t, "1")
                rmparam(t, "head")
                rmparam(t, "g")
                rmparam(t, "g2")
                rmparam(t, "sort")
                t.name = "fr-noun"
                if head:
                    t.add("head", head)
                t.add("1", g)
                if g2:
                    t.add("g2", g2)
                if plural:
                    t.add("2", plural)
            elif headtype in ["proper noun", "proper nouns"]:
                head = getparam(t, "head")
                g = getparam(t, "g")
                g2 = getparam(t, "g2")
                remove_3 = False
                if not g and getparam(t, "3") in ["m", "f", "m-p", "f-p"]:
                    g = getparam(t, "3")
                    remove_3 = True
                unrecognized_params = False
                for param in t.params:
                    pname = str(param.name)
                    if pname in ["1", "2", "head", "g", "g2", "sort"] or remove_3 and pname in ["3"]:
                        pass
                    else:
                        unrecognized_params = True
                        break
                if unrecognized_params:
                    p.msg("WARNING: Unrecognized parameters in %s, skipping" % str(t))
                    continue
                if not g:
                    p.msg("WARNING: No gender given in %s, skipping" % str(t))
                    continue
                rmparam(t, "3")
                rmparam(t, "2")
                rmparam(t, "1")
                rmparam(t, "head")
                rmparam(t, "g")
                rmparam(t, "g2")
                rmparam(t, "sort")
                t.name = "fr-proper noun"
                if head:
                    t.add("head", head)
                t.add("1", g)
                if g2:
                    t.add("g2", g2)
            elif headtype in ["adjective", "adjectives"]:
                if getparam(t, "3") in ["invariable", "invariant"]:
                    params = dict((str(p.name), str(p.value)) for p in t.params)
                    del params["1"]
                    del params["2"]
                    del params["3"]
                    if getparam(t, "g") == "m" and getparam(t, "g2") == "f":
                        del params["g"]
                        del params["g2"]
                    if not params:
                        rmparam(t, "g2")
                        rmparam(t, "g")
                        rmparam(t, "3")
                        rmparam(t, "2")
                        rmparam(t, "1")
                        t.name = "fr-adj"
                        t.add("inv", "y")
                    else:
                        p.msg("WARNING: Unrecognized parameters in %s, skipping" % str(t))
                else:
                    p.msg("WARNING: Unrecognized parameters in %s, skipping" % str(t))
            elif headtype in [
                "adjective form",
                "verb form",
                "verb forms",
                "interjection",
                "preposition",
                "prefix",
                "prefixes",
                "suffix",
                "suffixes",
            ]:
                headtype_supports_g = headtype in ["adjective form", "suffix", "suffixes"]
                head = getparam(t, "head")
                unrecognized_params = False
                for param in t.params:
                    pname = str(param.name)
                    if pname in ["1", "2", "head", "sort"] or headtype_supports_g and pname == "g":
                        pass
                    else:
                        unrecognized_params = True
                        break
                if unrecognized_params:
                    p.msg("WARNING: Unrecognized parameters in %s, skipping" % str(t))
                    continue
                rmparam(t, "sort")
                rmparam(t, "head")
                rmparam(t, "2")
                rmparam(t, "1")
                t.name = (
                    "fr-adj-form"
                    if headtype == "adjective form"
                    else (
                        "fr-verb-form"
                        if headtype in ["verb form", "verb forms"]
                        else (
                            "fr-intj"
                            if headtype == "interjection"
                            else (
                                "fr-prep"
                                if headtype == "preposition"
                                else "fr-prefix" if headtype in ["prefix", "prefixes"] else "fr-suffix"
                            )
                        )
                    )  # if headtype in ["suffix", "suffixes"]
                )
                if head:
                    t.add("head", head)

            newt = str(t)
            if origt != newt:
                p.msg("Replacing %s with %s" % (origt, newt))
                notes.append(
                    "replaced {{head|fr|%s}} with {{%s}}%s"
                    % (headtype, tname(t), " (NEEDS REVIEW)" if fixed_plural_warning else "")
                )

    return str(parsed), notes


parser = blib.create_argparser("Convert head|fr|* to fr-*", include_pagefile=True, include_stdin=True)
parser.add_argument(
    "--fix-missing-plurals",
    action="store_true",
    help="Fix cases with missing plurals by just assuming the default plural.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=[
        "French nouns",
        "French proper nouns",
        "French pronouns",
        "French determiners",
        "French adjectives",
        "French verbs",
        "French participles",
        "French adverbs",
        "French prepositions",
        "French conjunctions",
        "French interjections",
        "French idioms",
        "French phrases",
        "French abbreviations",
        "French acronyms",
        "French initialisms",
        "French noun forms",
        "French proper noun forms",
        "French pronoun forms",
        "French determiner forms",
        "French verb forms",
        "French adjective forms",
        "French participle forms",
        "French proverbs",
        "French prefixes",
        "French suffixes",
        "French diacritical marks",
        "French punctuation marks",
    ],
    # default_cats=["French adjective forms", "French participle forms", "French proverbs",
    #  "French prefixes", "French suffixes", "French diacritical marks", "French punctuation marks"]
)
