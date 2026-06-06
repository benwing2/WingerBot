#!/usr/bin/env python3

# This script modifies Proto-Slavic pages containing links to Slovene words
# to contain the tonal version of the word by looking it up in the entry.
import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

GRAVE = "\u0300"
ACUTE = "\u0301"
CIRC = "\u0302"
TILDE = "\u0303"
MACRON = "\u0304"
BREVE = "\u0306"
DOTOVER = "\u0307"
DIAER = "\u0308"
CARON = "\u030c"
DGRAVE = "\u030f"
INVBREVE = "\u0311"
DOTUNDER = "\u0323"
RINGBELOW = "\u0325"
CEDILLA = "\u0327"
OGONEK = "\u0328"

skip_pages = ["Reconstruction:Proto-Slavic/mělь", "Reconstruction:Proto-Slavic/pazъ"]


def remove_slovene_accents(lemma):
    lemma = re.sub("[ÁÀÂȂȀ]", "A", lemma)
    lemma = re.sub("[áàâȃȁ]", "a", lemma)
    lemma = re.sub("[ÉÈÊȆȄỆẸĘ]", "E", lemma)
    lemma = re.sub("[éèêȇȅệẹęə]", "e", lemma)
    lemma = re.sub("[ÍÌÎȊȈ]", "I", lemma)
    lemma = re.sub("[íìîȋȉ]", "i", lemma)
    lemma = re.sub("[ÓÒÔȎȌỘỌǪ]", "O", lemma)
    lemma = re.sub("[óòôȏȍộọǫ]", "o", lemma)
    lemma = re.sub("[ŔȒȐ]", "R", lemma)
    lemma = re.sub("[ŕȓȑ]", "r", lemma)
    lemma = re.sub("[ÚÙÛȖȔ]", "U", lemma)
    lemma = re.sub("[úùûȗȕ]", "u", lemma)
    lemma = re.sub("ł", "l", lemma)
    lemma = re.sub(GRAVE, "", lemma)
    lemma = re.sub(ACUTE, "", lemma)
    lemma = re.sub(DGRAVE, "", lemma)
    lemma = re.sub(INVBREVE, "", lemma)
    lemma = re.sub(CIRC, "", lemma)
    lemma = re.sub(DOTUNDER, "", lemma)
    lemma = re.sub(OGONEK, "", lemma)
    return lemma


def look_up_tonal_form(p, pagename):
    pp = blib.create_process_page_params(args, p.index, pagename, msg_title = "%s: %s" % (p.title, pagename))
    if pp is None:
        return None
    parsed = blib.parse_text(pp.text)
    tonal_forms = []
    for t in parsed.filter_templates():
        if tname(t) == "sl-tonal":
            if args.verbose:
                p.msg("look_up_tonal_form: Found tonal template %s" % str(t))
            if tonal_forms:
                p.msg("WARNING: Found multiple {{sl-tonal}} calls: new one is %s; can't handle" % str(t))
                return None
            tonal_forms.append(getparam(t, "1"))
            for param in ["2", "3", "4", "5", "6"]:
                if getparam(t, param):
                    tonal_forms.append(getparam(t, param))
    return tonal_forms


def process_text_on_page(p):
    if p.title in skip_pages:
        p.msg("Skipping because in skip list")
        return

    p.msg("Processing")

    notes = []
    parsed = blib.parse_text(p.text)
    saw_sl_tonal = False
    saw_sl_plain = 0
    for t in parsed.filter_templates():
        # In case we already substituted multiple tonal variants, the first
        # one will have {{l|sl|...}} and we'll try to replace it again unless
        # we have this check.
        tn = tname(t)
        if tn == "l/sl-tonal":
            p.msg("Already found %s, not replacing anything" % str(t))
            saw_sl_tonal = True
        if tn == "l" and getparam(t, "1") == "sl":
            saw_sl_plain += 1
    if saw_sl_plain and saw_sl_tonal:
        p.msg("WARNING: Saw both {{l|sl|...}} and {{l/sl-tonal|...}}, needs fixing")
    if saw_sl_plain > 1:
        p.msg("WARNING: Saw multiple {{l|sl|...}}, check if substitution is correct")
    if saw_sl_tonal:
        return

    # The repeating while loop was used previously for handling multiple
    # variants, where the template had to be replaced with multiple templates
    # by substituting into the raw page text, and then we had to restart
    # template processing so the substitution didn't disappear.
    repeat = True
    while repeat:
        parsed = blib.parse_text(p.text)
        for t in parsed.filter_templates():
            origt = str(t)
            if tname(t) in ["l"] and getparam(t, "1") == "sl":
                linkpage = getparam(t, "2")
                altlink = getparam(t, "3")
                defn = getparam(t, "4")
                gloss = getparam(t, "gloss")
                tgloss = getparam(t, "t")
                gender = getparam(t, "g")
                gender2 = getparam(t, "g2")
                if (defn and 1 or 0) + (gloss and 1 or 0) + (tgloss and 1 or 0) > 1:
                    p.msg(
                        "WARNING: Found more than one of defn=%s, gloss=%s, t=%s in %s, skipping"
                        % (defn, gloss, tgloss, str(t))
                    )
                    continue
                defn = defn or gloss or tgloss
                if altlink:
                    if remove_slovene_accents(linkpage) != remove_slovene_accents(altlink):
                        p.msg(
                            "WARNING: Template %s has both link and altlink and they don't point to the same page skipping"
                            % str(t)
                        )
                        continue
                    linkpage = altlink
                for param in t.params:
                    pname = str(param.name)
                    if pname not in ["1", "2", "3", "4", "gloss", "t", "g", "g2", "pos"]:
                        p.msg("WARNING: Found unexpected param %s in %s, skipping" % (pname, str(t)))
                        break
                else:
                    tonal_forms = look_up_tonal_form(p, remove_slovene_accents(linkpage))
                    if tonal_forms:
                        if False:  # len(tonal_forms) > 1:
                            pass
                            # This code was formerly used when {{l/sl-tonal}} didn't
                            # support multiple alternants, and used {{l|sl|...}} on all
                            # alternants but the final one.

                            # non_final_forms = tonal_forms[:-1]
                            # final_form = tonal_forms[-1]
                            # newsub = "%s, {{l/sl-tonal|%s%s%s%s}}" % (
                            #    ", ".join("{{l-REPLACEME|sl|%s}}" % x for x in non_final_forms),
                            #    final_form, "|gloss=%s" % defn if defn else "",
                            #    "|g=%s" % gender if gender else "",
                            #    "|g2=%s" % gender2 if gender2 else "")
                            # eventual_newsub = newsub.replace("{{l-REPLACEME|", "{{l|")
                            # fromsub = str(t)
                            # fromtext = str(parsed)
                            # newtext = fromtext.replace(fromsub, newsub)
                            # if newtext == fromtext:
                            #  p.msg("WARNING: Something wrong, can't locate template %s in p.text"
                            #      % fromsub)
                            # else:
                            #  p.msg("Replaced %s with %s (multiple tonal variants)" % (fromsub, eventual_newsub))
                            #  if len(newtext) - len(fromtext) != len(newsub) - len(fromsub):
                            #    p.msg("WARNING: Length mismatch when replacing multiple tonal variants, may have matched multiple templates: from=%s, to=%s" % (
                            #      fromsub, newsub))
                            #  notes.append("replaced Slovene %s with multi tonal variants %s" % (linkpage, ",".join(tonal_forms)))
                            #  text = newtext
                            #  break
                        else:
                            t.name = "l/sl-tonal"
                            rmparam(t, "2")
                            rmparam(t, "3")
                            rmparam(t, "4")
                            for i, form in enumerate(tonal_forms):
                                t.add(str(i + 1), form)
                            rmparam(t, "t")
                            if defn:
                                t.add("gloss", defn)
                            else:
                                rmparam(t, "gloss")
                            notes.append("replaced Slovene %s with tonal %s" % (linkpage, ", ".join(tonal_forms)))
            newt = str(t)
            if origt != newt:
                p.msg("Replaced %s with %s" % (origt, newt))
        else:
            repeat = False

    return str(parsed).replace("{{l-REPLACEME|", "{{l|"), notes


parser = blib.create_argparser(
    "Convert Slovene links in Proto-Slavic pages to tonal form"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Proto-Slavic lemmas"]
)
