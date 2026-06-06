#!/usr/bin/env python3

import pywikibot, re, sys, copy

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg


def process_text_on_page(p):
    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj", "ru-conj-old"]:
            if [x for x in t.params if str(x.value) == "or"]:
                p.msg("WARNING: Skipping multi-arg conjugation: %s" % str(t))
                continue
            param2 = getparam(t, "2")
            if "*" in param2:
                continue
            param3 = getparam(t, "3")
            param4 = getparam(t, "4")
            if not param4:
                continue
            if getparam(t, "5"):
                t.add("4", "")
            else:
                rmparam(t, "4")
            if re.search("^(во|взо|изо|обо|ото|подо|разо|со)", param4):
                param2 = re.sub("^([0-9]+)", r"\1*", param2)
                t.add("2", param2)
                notes.append("Replaced manual pres/futr stem with * variant")
            else:
                notes.append("Removed unnecessary manual pres/futr stem")
            if tname(t) == "ru-conj":
                new_tempcall = re.sub(r"^\{\{ru-conj", "{{ru-generate-verb-forms", str(t))
            else:
                new_tempcall = re.sub(r"^\{\{ru-conj-old", "{{ru-generate-verb-forms|old=1", str(t))
            result = p.expand_text(new_tempcall)
            if not result:
                return
            new_forms = blib.split_generate_args(result)
            if tname(t) == "ru-conj":
                orig_tempcall = re.sub(r"^\{\{ru-conj", "{{ru-generate-verb-forms", origt)
            else:
                orig_tempcall = re.sub(r"^\{\{ru-conj-old", "{{ru-generate-verb-forms|old=1", origt)
            result = p.expand_text(orig_tempcall)
            if not result:
                return
            orig_forms = blib.split_generate_args(result)

            # Compare each form and accumulate a list of mismatches.

            all_keys = set(orig_forms.keys()) | set(new_forms.keys())

            def sort_numbers_first(key):
                if re.search("^[0-9]+$", key):
                    return "%05d" % int(key)
                return key

            all_keys = sorted(list(all_keys), key=sort_numbers_first)
            mismatches = []
            for key in all_keys:
                origval = orig_forms.get(key, "<<missing>>")
                newval = new_forms.get(key, "<<missing>>")
                if origval != newval:
                    mismatches.append("%s: old=%s new=%s" % (key, origval, newval))

            # If mismatches, output them and don't change anything.

            if mismatches:
                p.msg(
                    "WARNING: Mismatch comparing old %s to new %s: %s"
                    % (orig_tempcall, new_tempcall, " || ".join(mismatches))
                )
                return

        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Add * to 9b and 11b verbs as needed")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian class 9b verbs", "Russian class 11b verbs"],
)
