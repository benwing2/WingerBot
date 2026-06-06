#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, addparam, tname, pname
from wingerbot.arabic.arlib import (
    ALIF,
    ALIF_WASLA,
    A,
    AN,
    UN,
    U,
    UUN,
    UUNA,
    I,
    reorder_shadda,
)


def remove_i3rab(p, entry, word):
    def pagemsg(txt):
        p.msg("Entry %s: %s" % (entry, txt))

    word = reorder_shadda(word)
    if word.endswith(UN):
        pagemsg("Removing i3rab (UN) from %s" % word)
        return re.sub(UN + "$", "", word)
    if word.endswith(U):
        pagemsg("Removing i3rab (U) from %s" % word)
        return re.sub(U + "$", "", word)
    if word.endswith(UUNA):
        pagemsg("Removing i3rab (UUNA -> UUN) from %s" % word)
        return re.sub(UUNA + "$", UUN, word)
    if word and word[-1] in [A, I, U, AN]:
        pagemsg("FIXME: Strange diacritic at end of %s" % word)
    if word and word[0] == ALIF_WASLA:
        pagemsg("Changing alif wasla to plain alif for %s" % word)
        word = ALIF + word[1:]
    return word


def process_text_on_page_for_noun(p):
    parsed = blib.parse_text(p.text)

    nouncount = 0
    nounids = []
    for t in parsed.filter_templates():
        if tname(t) in ["ar-noun", "ar-coll-noun", "ar-sing-noun", "ar-nisba", "ar-noun-nisba", "ar-adj", "ar-numeral"]:
            nouncount += 1
            params_done = []
            entry = getparam(t, "1")
            for param in t.params:
                value = str(param.value)
                newvalue = remove_i3rab(p, entry, value)
                if newvalue != value:
                    param.value = newvalue
                    params_done.append(pname(param))
            if params_done:
                nounids.append("#%s %s %s (%s)" % (nouncount, tname(t), entry, ", ".join(params_done)))
    return str(parsed), "remove i3rab from params in %s" % ("; ".join(nounids))


def process_text_on_page_for_verb(p):
    parsed = blib.parse_text(p.text)

    verbcount = 0
    verbids = []
    for t in parsed.filter_templates():
        if tname(t) == "ar-conj":
            verbcount += 1
            vnvalue = getparam(t, "vn")
            uncertain = False
            if vnvalue.endswith("?"):
                vnvalue = vnvalue[:-1]
                p.msg("Verbal noun(s) identified as uncertain")
                uncertain = True
            if not vnvalue:
                continue
            vns = re.split("[,،]", vnvalue)
            form = getparam(t, "1")
            verbid = "#%s form %s" % (verbcount, form)
            if re.match("^[1I](-|$)", form):
                verbid += " (%s,%s)" % (getparam(t, "2"), getparam(t, "3"))
            no_i3rab_vns = []
            for vn in vns:
                no_i3rab_vns.append(remove_i3rab(p, verbid, vn))
            newvn = ",".join(no_i3rab_vns)
            if uncertain:
                newvn += "?"
            if newvn != vnvalue:
                p.msg("Verb %s, replacing %s with %s" % (verbid, vnvalue, newvn))
                addparam(t, "vn", newvn)
                verbids.append(verbid)
    return str(parsed), "remove i3rab from verbal nouns for verb(s) %s" % (", ".join(verbids))


parser = blib.create_argparser("Remove i3rab")
parser.add_argument("--verb", action="store_true", help="Do verbal nouns in verbs")
parser.add_argument("--noun", action="store_true", help="Do arguments in nouns")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.noun:
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page_for_noun,
                               default_cats=["Arabic nouns", "Arabic adjectives"])
if args.verb:
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page_for_verb,
                               default_cats=["Arabic verbs"])