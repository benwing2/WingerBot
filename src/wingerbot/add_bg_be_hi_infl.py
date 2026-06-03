#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

pos_to_headword_template = {
    "noun": "%s-noun",
    "proper noun": "%s-proper noun",
    "verb": "%s-verb",
    "adjective": "%s-adj",
}

pos_to_new_style_infl_template = {
    "noun": "%s-ndecl",
    "proper noun": "%s-ndecl",
    "verb": "%s-conj",
    "adjective": "%s-adecl",
}

bg_pos_to_old_style_infl_template_prefix = {
    "noun": "bg-noun-",
    "proper noun": "bg-decl-noun",
    "verb": None,
    "adjective": None,
}

be_pos_to_old_style_infl_template_prefix = {
    "noun": "be-decl-noun",
    "proper noun": "be-decl-noun",
    "verb": None,
    "adjective": None,
}

hi_pos_to_old_style_infl_template_prefix = {
    "noun": None,
    "proper noun": None,
    "verb": None,
    "adjective": "hi-adj-auto",
}

lang_to_langname = {
    "be": "Belarusian",
    "bg": "Bulgarian",
    "hi": "Hindi",
}

# Hindi vowel diacritics; don't display nicely on their own
M = "\u0901"
N = "\u0902"
I = "\u093f"
AA = "\u093e"


def process_text_on_page(p, pos):
    cappos = pos.capitalize()
    notes = []

    p.msg("Processing")

    origtext = p.text

    modsec = blib.find_modifiable_lang_section(p.text, None, p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    k = 2
    last_pos = None
    while k < len(subsections):
        if subsecs.headers[k] == cappos:
            level = subsecs.levels[k]
            last_pos = cappos
            endk = k + 2
            while endk < len(subsections) and subsecs.levels[endk] > level:
                endk += 2
            pos_text = "".join(subsections[k - 1 : endk - 1])
            parsed = blib.parse_text(pos_text)
            head = None
            headt = None
            inflt = None
            found_bg_pre_reform = False
            found_hi_head_needing_manual = False
            hi_head_gender = None
            for t in parsed.filter_templates():
                tn = tname(t)
                newhead = None
                if tn == pos_to_headword_template[pos] % args.lang:
                    headt = t
                    if args.lang == "hi":
                        for i in range(1, 10):
                            trparam = "tr" if i == 1 else "tr%s" % i
                            if getparam(t, trparam):
                                found_hi_head_needing_manual = "Saw manual translit %s=%s" % (
                                    trparam,
                                    getparam(t, trparam),
                                )
                                break
                        if not found_hi_head_needing_manual:
                            for i in range(2, 10):
                                headparam = "head%s" % i
                                if getparam(t, headparam):
                                    found_hi_head_needing_manual = "Saw extra head %s=%s" % (
                                        headparam,
                                        getparam(t, headparam),
                                    )
                                    break
                                gparam = "g%s" % i
                                if getparam(t, gparam):
                                    found_hi_head_needing_manual = "Saw extra gender %s=%s" % (
                                        gparam,
                                        getparam(t, gparam),
                                    )
                                    break
                        newhead = getparam(t, "head").strip() or p.title
                        if not found_hi_head_needing_manual:
                            if " " in newhead:
                                found_hi_head_needing_manual = "Space in headword"
                            elif newhead != p.title:
                                found_hi_head_needing_manual = (
                                    "Explicit headword %s doesn't agree with pagetitle %s" % (newhead, p.title)
                                )
                        hi_head_gender = getparam(t, "g")
                        if not hi_head_gender:
                            found_hi_head_needing_manual = "No gender"
                        if not found_hi_head_needing_manual:
                            if hi_head_gender not in ["m", "f"]:
                                found_hi_head_needing_manual = (
                                    "Gender %s unrecognized or required manual evaluation" % hi_head_gender
                                )
                            elif hi_head_gender == "m" and re.search("[" + AA + "आ][" + M + N + "]?$", newhead):
                                found_hi_head_needing_manual = (
                                    "Masculine head %s ends in -ā or -ā̃, needs manual evaluation" % newhead
                                )
                            elif hi_head_gender == "f" and re.search(I + "या" + "[" + M + N + "]?$", newhead):
                                found_hi_head_needing_manual = (
                                    "Feminine head %s ends in -iyā or -iyā̃, needs manual evaluation" % newhead
                                )
                    else:
                        newhead = getparam(t, "1")
                elif tn == "head" and getparam(t, "1") == args.lang and getparam(t, "2") in [pos, "%ss" % pos]:
                    headt = t
                    newhead = getparam(t, "head").strip() or p.title
                    if args.lang == "hi":
                        found_hi_head_needing_manual = "Can't currently support raw 'head|hi|%s' template" % pos
                if newhead:
                    if head:
                        p.msg("WARNING: Found two heads under one POS section: %s and %s" % (head, newhead))
                    head = newhead
                if args.lang == "bg":
                    infl_template_prefix = bg_pos_to_old_style_infl_template_prefix
                elif args.lang == "be":
                    infl_template_prefix = be_pos_to_old_style_infl_template_prefix
                elif args.lang == "hi":
                    infl_template_prefix = be_pos_to_old_style_infl_template_prefix
                else:
                    assert False, "Unrecognized lang %s" % args.lang
                if tn == pos_to_new_style_infl_template[pos] % args.lang or (
                    infl_template_prefix[pos] and tn.startswith(infl_template_prefix[pos])
                ):
                    if inflt:
                        p.msg(
                            "WARNING: Found two inflection templates under one POS section: %s and %s"
                            % (str(inflt), str(t))
                        )
                    inflt = t
                    p.msg("Found %s inflection for headword %s: %s" % (pos, head or p.title, str(t)))
                if tn == "bg-pre-reform":
                    p.msg("Found bg-pre-reform, won't add inflection: %s" % (str(t)))
                    found_bg_pre_reform = True
            if headt and not inflt and not found_bg_pre_reform:
                p.msg("Didn't find %s inflection for headword %s" % (pos, head or p.title))
                if args.lang == "hi" and found_hi_head_needing_manual:
                    p.msg("WARNING: Won't add declension: %s: %s" % (found_hi_head_needing_manual, str(headt)))
                else:
                    if args.lang == "hi":
                        if hi_head_gender == "m":
                            infl = "{{hi-ndecl|<M>}}"
                        else:
                            assert hi_head_gender == "f", "Something wrong, unrecognized gender %s" % hi_head_gender
                            infl = "{{hi-ndecl|<F>}}"
                    else:
                        infl = "{{%s|%s<>}}" % (pos_to_new_style_infl_template[pos] % args.lang, head or p.title)
                    for l in range(k, endk, 2):
                        if re.search(r"^(Declension|Inflection|Conjugation)$", subsecs.headers[l]):
                            secparsed = blib.parse_text(subsections[l])
                            for t in secparsed.filter_templates():
                                tn = tname(t)
                                if tname(t) != "rfinfl":
                                    p.msg(
                                        "WARNING: Saw unknown template %s in existing inflection section, skipping"
                                        % (str(t))
                                    )
                                    break
                            else:  # no break
                                m = re.search(r"\A(.*?)(\n*)\Z", subsections[l], re.S)
                                assert m is not None  # should always match
                                sectext, final_newlines = m.groups()
                                subsections[l] = infl + final_newlines
                                p.msg("Replaced existing decl text <%s> with <%s>" % (sectext, infl))
                                notes.append(
                                    "replace %s decl text <%s> with <%s>"
                                    % (lang_to_langname[args.lang], sectext.strip(), infl)
                                )
                            break
                    else:  # no break
                        insert_k = k + 2
                        while insert_k < endk and subsecs.headers[insert_k] == "Usage notes":
                            insert_k += 2
                        if not subsections[insert_k - 2].endswith("\n\n"):
                            subsections[insert_k - 2] = re.sub("\n*$", "\n\n", subsections[insert_k - 2] + "\n\n")
                        subsections[insert_k - 1 : insert_k - 1] = [
                            "%s%s%s\n"
                            % ("=" * (level + 1), "Conjugation" if pos == "verb" else "Declension", "=" * (level + 1)),
                            infl + "\n\n",
                        ]
                        p.msg("Inserted level-%s inflection section with inflection <%s>" % (level + 1, infl))
                        notes.append(
                            "insert level-%s %s inflection <%s>" % (level + 1, lang_to_langname[args.lang], infl)
                        )
                        endk += 2  # for the two subsections we inserted

            k = endk
        else:
            m = re.search(
                r"^(Noun|Proper noun|Pronoun|Determiner|Verb|Adjective|Adverb|Interjection|Conjunction)$",
                subsecs.headers[k],
            )
            if m:
                last_pos = m.group(1)
            if re.search(r"^(Declension|Inflection|Conjugation)$", subsecs.headers[k]):
                if not last_pos:
                    p.msg(
                        "WARNING: Found inflection header before seeing any parts of speech: %s"
                        % (subsections[k - 1].strip())
                    )
                elif last_pos == cappos:
                    p.msg(
                        "WARNING: Found probably misindented inflection header after ==%s== header: %s"
                        % (cappos, subsections[k - 1].strip())
                    )
            k += 2

    text = modsec.rebuild(secbody="".join(subsections))
    text = re.sub("\n\n\n+", "\n\n", text)
    if origtext != text:
        notes.append("condense 3+ newlines into 2")
    return text, notes


parser = blib.create_argparser(
    "Add Bulgarian/Belarusian/Hindi noun/verb/adjective inflections", include_pagefile=True, include_stdin=True
)
parser.add_argument("--pos", required=True, help="Part of speech (noun, proper noun, verb, adjective)")
parser.add_argument("--lang", required=True, help="Language (bg, be, hi)")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.lang not in ["bg", "be", "hi"]:
    raise ValueError("Unrecognized language: %s" % args.lang)


def do_process_text_on_page(p):
    return process_text_on_page(p, args.pos)


blib.do_pagefile_cats_refs(args, start, end, do_process_text_on_page)
