#!/usr/bin/env python3

import json, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, getrmparam, tname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param)

        if tn == "head" and getp("1") == "rup" and getp("2") == "verb":
            params = blib.fetch_param_chain(t, "3")
            pres2s = []
            pres3s = []
            pres2p = []
            impf = []
            sperf = []
            pp = []
            lastlist = None
            to_append_list = None
            must_continue = False
            for i, item in enumerate(params):
                if i % 2 == 0:
                    if item == "or":
                        if lastlist is None:
                            p.msg("WARNING: Saw 'or' without preceding inflection: %s" % str(t))
                            must_continue = True
                            break
                        to_append_list = lastlist
                    elif item == "second-person singular present indicative":
                        lastlist = pres2s
                        to_append_list = lastlist
                    elif item in [
                        "third-person singular present indicative",
                        "third-person present indicative",
                        "third-person present singular indicative",
                        "third-person singular indicative",
                    ]:
                        lastlist = pres3s
                        to_append_list = lastlist
                    elif item == "second-person plural present indicative":
                        lastlist = pres2p
                        to_append_list = lastlist
                    elif item == "imperfect":
                        lastlist = impf
                        to_append_list = lastlist
                    elif item == "simple perfect":
                        lastlist = sperf
                        to_append_list = lastlist
                    elif item == "past participle":
                        lastlist = pp
                        to_append_list = lastlist
                    else:
                        p.msg("WARNING: Unrecognized inflection '%s': %s" % (item, str(t)))
                        must_continue = True
                        break
                else:
                    to_append_list.append(item)
            if must_continue:
                continue
            del t.params[:]
            blib.set_template_name(t, "rup-verb")
            if pres2s:
                blib.set_param_chain(t, pres2s, "pres2s")
            if pres3s:
                blib.set_param_chain(t, pres3s, "pres3s")
            if pres2p:
                blib.set_param_chain(t, pres2p, "pres2p")
            if impf:
                blib.set_param_chain(t, impf, "impf")
            if sperf:
                blib.set_param_chain(t, sperf, "sperf")
            if pp:
                blib.set_param_chain(t, pp, "pp")
            p.msg("Replace %s with %s" % (origt, str(t)))
            notes.append("convert {{head|rup|verb}} to {{rup-verb}}")

    return str(parsed), notes


parser = blib.create_argparser("Convert {{head|rup|verb}} to {{rup-verb}}")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats="Aromanian lemmas"
)
