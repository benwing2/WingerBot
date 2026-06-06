#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

conjugations = {}


def process_text_on_page(p):
    notes = []

    if "it-verb" not in p.text:
        return

    parsed = blib.parse_text(p.text)

    it_verb_t = None
    it_conj_t = None
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        if tn in ["it-verb"]:
            # p.msg("Saw %s" % str(t))
            if p.title.endswith("re"):
                param1 = getp("1")
                if not param1:
                    # p.msg("Didn't see 1= in non-reflexive {{it-verb}}: %s" % str(t))
                    return
                refl_pagetitle = re.sub("rre$", "rsi", p.title)
                refl_pagetitle = re.sub("re$", "rsi", refl_pagetitle)
                param1 = re.sub(r"^(?:\[.*?\]|[^\[\]])*?([/\\])", lambda m: "\\" if m.group(1) == "\\" else "", param1)
                if re.search("[aei]rre$", p.title):
                    param1 += ".rre"
                if "/" in param1:
                    p.msg("WARNING: Something wrong, saw / after attempting to remove it: %s" % param1)
                    return
                if refl_pagetitle in conjugations:
                    existing_conj = conjugations[refl_pagetitle]
                    if existing_conj is None:
                        p.msg(
                            "WARNING: Already saw two or more conjugations and saw a third one <%s>, skipping" % param1
                        )
                        return
                    if existing_conj != param1:
                        p.msg("WARNING: Saw two conjugations <%s> and <%s>" % (existing_conj, param1))
                        conjugations[refl_pagetitle] = None
                        return
                conjugations[refl_pagetitle] = param1
            elif p.title.endswith("rsi"):
                if it_verb_t is not None:
                    p.msg("WARNING: Saw two {{it-verb}} templates, skipping: %s and %s" % (str(it_verb_t), str(t)))
                    return
                it_verb_t = t
                param1 = getp("1")
                if param1:
                    # p.msg("Already saw conjugation: %s" % param1)
                    return
                if p.title not in conjugations:
                    p.msg("WARNING: Didn't see conjugation")
                    return
                conj = conjugations[p.title]
                if conj is None:
                    p.msg("WARNING: Can't set conjugation because non-reflexive equivalent has multiple conjugations")
                    return
                t.add("1", conj)
                notes.append("copy non-reflexive conjugation to reflexive {{it-verb}}")
            elif " " not in p.title:
                p.msg("WARNING: Saw {{it-verb}} on page not ending in -re or -rsi: %s" % str(t))
        elif tn.startswith("it-conj-") and p.title.endswith("rsi"):
            # p.msg("Saw %s" % str(t))
            if it_conj_t is not None:
                p.msg("WARNING: Saw two {{it-conj-*}} templates, skipping: %s and %s" % (str(it_conj_t), str(t)))
                return
            it_conj_t = t
            if it_verb_t is None:
                p.msg(
                    "WARNING: Saw {{it-conj-*}} template without preceding {{it-verb}} template, skipping: %s" % str(t)
                )
                return
            if p.title not in conjugations:
                p.msg("WARNING: Didn't see conjugation")
                return
            conj = conjugations[p.title]
            if conj is None:
                p.msg("WARNING: Can't set conjugation because non-reflexive equivalent has multiple conjugations")
                return
            del t.params[:]
            t.add("1", conj)
            blib.set_template_name(t, "it-conj")
            notes.append("copy non-reflexive conjugation to reflexive {{it-conj}}")

        # if str(t) != origt:
        #  p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Copy non-reflexive {{it-verb}} conjugation to corresponding reflexive conjugation",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:it-verb"]
)
