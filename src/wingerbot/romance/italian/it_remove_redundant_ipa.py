#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    def getpron(pron):
        return p.expand_text("{{#invoke:it-pronunciation|to_phonemic_bot|%s}}" % pron)

    notes = []

    if "it-IPA" not in p.text:
        return

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in ["it-IPA"]:
            p.msg("Saw %s" % str(t))
            default_pron_phonemic = None
            prons = []
            for i in range(1, 11):
                pron = getparam(t, str(i))
                if pron:
                    prons.append(pron)
            if not prons:
                prons == ["+"]
            defaulted_prons = []
            for pron in prons:

                def add(prn):
                    if prn not in defaulted_prons:
                        defaulted_prons.append(prn)

                if pron == "+" or pron == p.title:
                    add("+")
                elif len(pron) == 1:  # vowel only
                    add(pron)
                else:  # full pronun
                    pron_phonemic = None
                    if default_pron_phonemic is None:
                        default_pron_phonemic = getpron(p.title)
                    if default_pron_phonemic:
                        pron_phonemic = getpron(pron)
                        if not pron_phonemic:
                            add(pron)
                            continue
                        if default_pron_phonemic == pron_phonemic:
                            pron = "+"
                    if pron != "+":
                        if pron_phonemic is None:
                            pron_phonemic = getpron(pron)
                        if not pron_phonemic:
                            add(pron)
                            continue
                        single_vowel_spec = re.sub("[^àèéìòúù]", "", pron)
                        if len(single_vowel_spec) == 1:
                            single_vowel_pron_phonemic = getpron(single_vowel_spec)
                            if single_vowel_pron_phonemic == pron_phonemic:
                                pron = single_vowel_spec
                    add(pron)
            if defaulted_prons == ["+"]:
                blib.remove_param_chain(t, "1", "")
                if str(t) != origt:
                    notes.append("remove redundant respelling(s) from {{it-IPA}}")
            else:
                blib.set_param_chain(t, defaulted_prons, "1", "")
                if str(t) != origt:
                    notes.append("replace default respelling(s) with single-vowel spec or '+' in {{it-IPA}}")
            if str(t) != origt:
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Remove redundant respellings in {{it-IPA}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:it-IPA"]
)
