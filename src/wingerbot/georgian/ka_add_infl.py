#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

pos_to_headword_template = {
    "noun": "ka-noun",
    "proper noun": "ka-proper noun",
    "verb": "ka-verb",
    "adjective": "ka-adj",
}

pos_to_new_style_infl_template = {
    "noun": None,
    "proper noun": None,
    "verb": None,
    "adjective": "ka-decl-adj",
}


def adj_indeclinable(pagetitle):
    return pagetitle[-1] in "აეოუ" or pagetitle[-2] in "აეიოუ"


def escape_newlines(txt):
    return txt.replace("\n", r"\n")


def process_text_on_page(p, pos):
    cappos = pos.capitalize()
    notes = []

    p.msg("Processing")

    if pos == "adjective" and adj_indeclinable(p.title):
        p.msg("Skipping indeclinable adjective")
        return

    modsec = blib.find_modifiable_lang_section(p.text, "Georgian", p.msg)
    if modsec is None:
        p.msg("WARNING: Couldn't find Georgian section")
        return
    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    headers = subsecs.headers
    levels = subsecs.levels
    # Go through each section in turn, looking for the appropriate part of speech
    k = 2
    last_pos = None
    while k < len(subsections):
        if headers[k] == cappos:
            level = levels[k]
            last_pos = cappos
            endk = k + 2
            while endk < len(subsections) and levels[endk] > level:
                endk += 2
            pos_text = "".join(subsections[k - 1 : endk - 1])
            parsed = blib.parse_text(pos_text)
            head = None
            inflt = None
            found_rfinfl = False
            for t in parsed.filter_templates():
                tn = tname(t)
                if tn == pos_to_headword_template[pos] or (
                    tn == "head" and getparam(t, "1") == "ka" and getparam(t, "2") in [pos, "%ss" % pos]
                ):
                    newhead = getparam(t, "head").strip() or p.title
                    if head:
                        p.msg("WARNING: Found two heads under one POS section: %s and %s" % (head, newhead))
                    head = newhead
                if tn == pos_to_new_style_infl_template[pos]:
                    if inflt:
                        p.msg(
                            "WARNING: Found two inflection templates under one POS section: %s and %s"
                            % (str(inflt), str(t))
                        )
                    inflt = t
                    p.msg(
                        "Found %s inflection for headword %s: <from> %s <to> {{%s|%s}} <end>"
                        % (
                            pos,
                            head or p.title,
                            str(t),
                            pos_to_new_style_infl_template[pos],
                            getparam(t, "1") if pos == "verb" else head or p.title,
                        )
                    )
            if not inflt:
                p.msg(
                    "Didn't find %s inflection for headword %s: <new> {{%s|%s%s}} <end>"
                    % (
                        pos,
                        head or p.title,
                        pos_to_new_style_infl_template[pos],
                        head or p.title,
                        "" if pos == "noun" else "<>",
                    )
                )
                new_infl = "{{%s}}" % pos_to_new_style_infl_template[pos]
                for l in range(k, endk, 2):
                    if re.search(r"^(Declension|Inflection|Conjugation)$", headers[l]):
                        secparsed = blib.parse_text(subsections[l])
                        for t in secparsed.filter_templates():
                            tn = tname(t)
                            if tname(t) not in ["rfinfl", "ka-infl-noun"]:
                                p.msg(
                                    "WARNING: Saw unknown template %s in existing inflection section, skipping"
                                    % (str(t))
                                )
                                break
                        else:  # no break
                            m = re.search(r"\A(.*?)(\n*)\Z", subsections[l], re.S)
                            sectext, final_newlines = m.groups()
                            newsectext = sectext
                            if "{{rfinfl|" in sectext:
                                newsectext = new_infl
                            else:
                                newsectext = new_infl + "\n" + sectext
                            subsections[l] = newsectext + final_newlines
                            p.msg(
                                "Replaced existing decl text <%s> with <%s>"
                                % (escape_newlines(sectext), escape_newlines(newsectext))
                            )
                            notes.append(
                                "replace decl text <%s> with <%s>"
                                % (escape_newlines(sectext), escape_newlines(newsectext))
                            )
                        break
                else:  # no break
                    insert_k = k + 2
                    while insert_k < endk and headers[insert_k] == "Usage notes":
                        insert_k += 2
                    if not subsections[insert_k - 2].endswith("\n\n"):
                        subsections[insert_k - 2] = re.sub("\n*$", "\n\n", subsections[insert_k - 2] + "\n\n")
                    subsections[insert_k - 1 : insert_k - 1] = [
                        "%s%s%s\n"
                        % ("=" * (level + 1), "Conjugation" if pos == "verb" else "Declension", "=" * (level + 1)),
                        new_infl + "\n\n",
                    ]
                    p.msg("Inserted level-%s inflection section with inflection <%s>" % (level + 1, new_infl))
                    notes.append("add decl <%s>" % new_infl)
                    endk += 2  # for the two subsections we inserted

            k = endk
        else:
            m = re.search(
                r"^(Noun|Proper noun|Pronoun|Determiner|Verb|Adjective|Adverb|Interjection|Conjunction)$",
                headers[k],
            )
            if m:
                last_pos = m.group(1)
            if re.search(r"^(Declension|Inflection|Conjugation)$", headers[k]):
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

    newtext = modsec.rebuild(secbody="".join(subsections))
    newtext = re.sub("\n\n\n+", "\n\n", newtext)
    if not notes:
        notes.append("convert 3+ newlines to 2")
    return newtext, notes


parser = blib.create_argparser(
    "Add Georgian noun/verb/adjective inflections", include_pagefile=True, include_stdin=True
)
parser.add_argument("--pos", help="Part of speech (noun, proper noun, verb, adjective)", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def do_process_text_on_page(p):
    return process_text_on_page(p, args.pos)


blib.do_pagefile_cats_refs(
    args, start, end, do_process_text_on_page, edit=True, stdin=True, default_cats=["Georgian %ss" % args.pos]
)
