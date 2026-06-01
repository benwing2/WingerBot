#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, getparam, addparam, tname

numeric_to_roman_form = {
    "1": "I",
    "2": "II",
    "3": "III",
    "4": "IV",
    "5": "V",
    "6": "VI",
    "7": "VII",
    "8": "VIII",
    "9": "IX",
    "10": "X",
    "11": "XI",
    "12": "XII",
    "13": "XIII",
    "14": "XIV",
    "15": "XV",
    "1q": "Iq",
    "2q": "IIq",
    "3q": "IIIq",
    "4q": "IVq",
}

verb_form_templates_to_args = {
    "ar-conj": "1",
    "ar-past3sm": "1",
    "ar-verb-part": "2",
}

# convert numeric form to roman-numeral form
def canonicalize_form(form: str) -> str:
    return numeric_to_roman_form.get(form, form)


# Clean the verb headword templates on a given page with the given text.
# Returns the changed text along with a changelog message.
def rewrite_one_page_verb_headword(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    parsed = blib.parse_text(text)

    pagemsg("Processing")

    actions_taken = []

    for t in parsed.filter_templates():
        if tname(t) in ["ar-verb"]:
            origtemp = str(t)
            form = getparam(t, "form")
            if form:
                # In order to keep in the same order, just forcibly change the
                # param "names" (numbers)
                for pno in range(10, 0, -1):
                    if t.has(str(pno)):
                        t.get(str(pno)).name = str(pno + 1)
                # Make sure form= param is first ...
                t.remove("form")
                addparam(t, "form", canonicalize_form(form), before=str(t.params[0].name) if len(t.params) > 0 else None)
                # ... then forcibly change its name to 1=
                t.get("form").name = "1"
                t.get("1").showkey = False
            newtemp = str(t)
            if origtemp != newtemp:
                msg("Replacing %s with %s" % (origtemp, newtemp))
            if re.match("^[1I](-|$)", form):
                actions_taken.append("form=%s (%s/%s)" % (form, getparam(t, "2"), getparam(t, "3")))
            else:
                actions_taken.append("form=%s" % form)
    changelog = "ar-verb: form= -> 1= and canonicalize to Roman numerals, move other params up: %s" % "; ".join(
        actions_taken
    )
    return str(parsed), changelog


# Canonicalize the form in ar-conj.
# Returns the changed text along with a changelog message.
def canonicalize_one_page_verb_form(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    parsed = blib.parse_text(text)

    pagemsg("Processing")

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in verb_form_templates_to_args:
            formarg = verb_form_templates_to_args[tn]
            origtemp = str(t)
            form = getparam(t, formarg)
            if form:
                addparam(t, formarg, canonicalize_form(form))
            newtemp = str(t)
            if origtemp != newtemp:
                msg("Replacing %s with %s" % (origtemp, newtemp))
            if re.match("^[1I](-|$)", form):
                notes.append(
                    "canonicalize form=%s in {{%s}} to Roman numerals (%s/%s)"
                    % (form, tn, getparam(t, str(1 + int(formarg))), getparam(t, str(2 + int(formarg))))
                )
            else:
                notes.append("canonicalize form=%s in {{%s}} to Roman numerals" % (form, tn))
    return str(parsed), notes


parser = blib.create_argparser("Rewrite form= to 1= in verb headword templates", include_pagefile=True, include_stdin=True)
parser.add_argument("--headword", action="store_true", help="Rewrite form= to 1= in ar-verb and canonicalize")
parser.add_argument(
    "--canonicalize", action="store_true", help="Canonicalize form in Arabic verb templates other than ar-verb"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.headword:
    blib.do_pagefile_cats_refs(args, start, end, rewrite_one_page_verb_headword, edit=True, stdin=True,
                            default_cats=["Arabic verbs"])
if args.canonicalize:
    blib.do_pagefile_cats_refs(args, start, end, canonicalize_one_page_verb_form, edit=True, stdin=True,
                            default_refs=["Template:%s" % template for template in verb_form_templates_to_args])