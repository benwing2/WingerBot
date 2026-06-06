#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_masc_page(p, fem):
    notes = []
    orig_fem = fem

    p.msg_title = "%s: %s" % (orig_fem, p.title)

    prev_fr_noun = False
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn in ["fr-noun"]:
            if prev_fr_noun:
                p.msg("WARNING: Saw two {{fr-noun}} templates, not changing: %s and %s" % (prev_fr_noun, str(t)))
                return
            prev_fr_noun = str(t)
            default_fem = p.expand_text("{{#invoke:fr-headword|make_feminine|%s}}" % p.title)
            if not default_fem:
                return
            if fem == default_fem:
                p.msg("Substituting '+' for default feminine %s: %s" % (fem, str(t)))
                fem = "+"
            else:
                p.msg(
                    "Feminine %s not equal to default feminine %s, not substituting: %s" % (fem, default_fem, str(t))
                )
            fems = blib.fetch_param_chain(t, "f")
            if fem in fems:
                p.msg("Feminine %s already in feminine(s) %s: %s" % (fem, ",".join(fems), str(t)))
            elif orig_fem in fems:
                p.msg("Replacing default feminine %s with + in %s: %s" % (orig_fem, ",".join(fems), str(t)))
                fems = [fem if f == orig_fem else f for f in fems]
                blib.set_param_chain(t, fems, "f")
                notes.append("replace default feminine %s with + in {{fr-noun}}" % orig_fem)
            else:
                fems.append(fem)
                blib.set_param_chain(t, fems, "f")
                notes.append(
                    "add female equivalent %s%s to {{fr-noun}}" % (fem, "" if fem == orig_fem else " (%s)" % orig_fem)
                )

        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


def process_text_on_page(p):
    if "female equivalent of" not in p.text and "femeq" not in p.text:
        return

    # p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["female equivalent of", "femeq"]:
            lang = getparam(t, "1")
            if lang != "fr":
                p.msg("WARNING: Can't handle lang %s: %s" % (lang, str(t)))
                continue
            masc = getparam(t, "2")

            def do_process(pp):
                return process_masc_page(pp, p.title)

            blib.do_edit(args, p.index, masc, do_process, must_exist=True)


parser = blib.create_argparser(
    "Copy {{female equivalent of}} nouns to the f= of the corresponding masculine",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["French female equivalent nouns"]
)
