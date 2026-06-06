#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname

translation_templates_with_sc = {
    "t": ["alt", "2"],
    "tt": ["alt", "2"],
    "t+": ["alt", "2"],
    "tt+": ["alt", "2"],
    "t-": ["alt", "2"],
    "tt+check": ["alt", "2"],
    "t+check": ["alt", "2"],
    "t-check": ["alt", "2"],
    "t-needed": ["alt", "2"],
}

link_templates_with_sc = {
    "l": ["3", "2"],
    "link": ["3", "2"],
    "l-self": ["3", "2"],
    "ll": ["3", "2"],
    "m": ["3", "2"],
    "mention": ["3", "2"],
    "m-self": ["3", "2"],
    "m+": ["3", "2"],
}

templates_with_sc = link_templates_with_sc
# templates_with_sc = translation_templates_with_sc
# templates_with_sc = translation_templates_with_sc | link_templates_with_sc


def check_script_agrees(value_to_check, lang, sc, pagemsg, expand_text, line_or_t, action_msg):
    def line_pagemsg(txt):
        if line_or_t:
            pagemsg("%s: %s" % (txt, line_or_t))
        else:
            pagemsg(txt)

    detected_sc = expand_text("{{#invoke:languages/templates|getByCode|%s|findBestScript|%s}}" % (lang, value_to_check))
    if not detected_sc:
        return False
    if detected_sc == "ms-Arab" and sc == "Arab" and lang == "ms":
        line_pagemsg(
            "Detected script ms-Arab for lang=ms, saw explicit sc=Arab, which is probably wrong, %s" % action_msg
        )
        return True
    if detected_sc in ["Hans", "Hant"] and sc == "Hani":
        line_pagemsg("Detected script %s, saw explicit sc=Hani which is a superset, %s" % (detected_sc, action_msg))
        return True
    if detected_sc != sc:
        if len(detected_sc) >= 4 and len(sc) >= 4 and detected_sc[-4:] == sc[-4:]:
            line_pagemsg(
                "For lang=%s, detected script %s, saw explicit sc=%s, both are variants of the same script, %s"
                % (lang, detected_sc, sc, action_msg)
            )
            return True
        if detected_sc == "None":
            line_pagemsg(
                "WARNING: For lang=%s, detected script %s but saw explicit sc=%s, which may be right"
                % (lang, detected_sc, sc)
            )
            return False
        force_detected_sc = expand_text(
            "{{#invoke:languages/templates|getByCode|%s|findBestScript|%s|true}}" % (lang, value_to_check)
        )
        if force_detected_sc == detected_sc:
            line_pagemsg(
                "WARNING: For lang=%s, force-detected script %s but saw explicit sc=%s, explicit sc= probably wrong"
                % (lang, detected_sc, sc)
            )
        else:
            line_pagemsg(
                "WARNING: For lang=%s, detected script %s but force-detected %s and saw explicit sc=%s, which may be right"
                % (lang, detected_sc, force_detected_sc, sc)
            )
        return False
    return True


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn in templates_with_sc:
            if not t.has("sc"):
                continue
            lang = getparam(t, "1")
            sc = getparam(t, "sc")
            if not sc:
                rmparam(t, "sc")
                notes.append("remove blank sc= from {{%s}}" % tn)
            else:
                params_to_check = templates_with_sc[tn]
                if type(params_to_check) is not list:
                    params_to_check = [params_to_check]
                for param in params_to_check:
                    value_to_check = getparam(t, param)
                    if value_to_check:
                        break
                if not value_to_check:
                    p.msg("WARNING: For lang=%s, no displayable value, not removing sc=%s: %s" % (lang, sc, str(t)))
                    continue
                agrees = check_script_agrees(value_to_check, lang, sc, p.msg, p.expand_text, str(t), "removing sc=")
                if not agrees:
                    continue
                rmparam(t, "sc")
                notes.append("remove redundant sc=%s from {{%s}}" % (sc, tn))
        if str(t) != origt:
            p.msg("Replaced %s with %s" % (origt, str(t)))
    notes = blib.group_notes(notes)
    remove_redundant_notes = []
    other_notes = []
    for note in notes:
        m = re.search("^remove redundant (.*)", note)
        if m:
            remove_redundant_notes.append(m.group(1))
        else:
            other_notes.append(note)
    if remove_redundant_notes:
        remove_redundant_notes = ["remove redundant " + ", ".join(remove_redundant_notes)]
    notes = remove_redundant_notes + other_notes
    return str(parsed), notes


if __name__ == "__main__":
    parser = blib.create_argparser("Remove redundant sc=")
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
