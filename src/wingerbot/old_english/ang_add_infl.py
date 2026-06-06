#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

pos_to_headword_template = {
    "noun": "ang-noun",
    "proper noun": "ang-proper noun",
    "verb": "ang-verb",
    "adjective": "ang-adj",
}

pos_to_new_style_infl_template = {
    "noun": "ang-ndecl",
    "proper noun": "ang-ndecl",
    "verb": "ang-conj",
    "adjective": "ang-adj",
}

pos_to_old_style_infl_template_prefix = {
    "noun": "ang-decl-noun",
    "proper noun": "ang-decl-noun",
    "verb": None,
    "adjective": None,
}


def process_text_on_page(p):
    pos = args.pos
    cappos = pos.capitalize()
    notes = []

    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Old English", p.msg)
    if modsec is None:
        return
    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
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
            inflt = None
            for t in parsed.filter_templates():
                tn = tname(t)
                if tn == pos_to_headword_template[pos] or (
                    tn == "head" and getparam(t, "1") == "ang" and getparam(t, "2") in [pos, "%ss" % pos]
                ):
                    newhead = getparam(t, "head").strip() or p.title
                    if head:
                        p.msg("WARNING: Found two heads under one POS section: %s and %s" % (head, newhead))
                    head = newhead
                if tn == pos_to_new_style_infl_template[pos] or (
                    pos_to_old_style_infl_template_prefix[pos]
                    and tn.startswith(pos_to_old_style_infl_template_prefix[pos])
                ):
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
                if pages_to_infls:
                    for l in range(k, endk, 2):
                        if subsecs.headers[l] in ["Declension", "Inflection", "Conjugation"]:
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
                                if p.title not in pages_to_infls:
                                    p.msg("WARNING: Couldn't find inflection for headword %s" % (head or p.title))
                                else:
                                    m = re.search(r"\A(.*?)(\n*)\Z", subsections[l], re.S)
                                    sectext, final_newlines = m.groups()
                                    subsections[l] = pages_to_infls[p.title] + final_newlines
                                    p.msg(
                                        "Replaced existing decl text <%s> with <%s>"
                                        % (sectext, pages_to_infls[p.title])
                                    )
                                    notes.append(
                                        "replace decl text <%s> with <%s>" % (sectext, pages_to_infls[p.title])
                                    )
                            break
                    else:  # no break
                        if p.title not in pages_to_infls:
                            p.msg("WARNING: Couldn't find inflection for headword %s" % (head or p.title))
                        else:
                            insert_k = k + 2
                            while insert_k < endk and subsecs.headers[insert_k] == "Usage notes":
                                insert_k += 2
                            if not subsections[insert_k - 2].endswith("\n\n"):
                                subsections[insert_k - 2] = re.sub("\n*$", "\n\n", subsections[insert_k - 2] + "\n\n")
                            subsections[insert_k - 1 : insert_k - 1] = [
                                "%s%s%s\n"
                                % (
                                    "=" * (level + 1),
                                    "Conjugation" if pos == "verb" else "Declension",
                                    "=" * (level + 1),
                                ),
                                pages_to_infls[p.title] + "\n\n",
                            ]
                            p.msg(
                                "Inserted level-%s inflection section with inflection <%s>"
                                % (level + 1, pages_to_infls[p.title])
                            )
                            notes.append("add decl <%s>" % pages_to_infls[p.title])
                            endk += 2  # for the two subsections we inserted

            k = endk
        else:
            m = re.search(
                r"^(Noun|Proper noun|Pronoun|Determiner|Verb|Adjective|Adverb|Interjection|Conjunction)$",
                subsecs.headers[k],
            )
            if m:
                last_pos = m.group(1)
            if subsecs.headers[k] in ["Declension", "Inflection", "Conjugation"]:
                if not last_pos:
                    p.msg(
                        "WARNING: Found inflection header before seeing any parts of speech: %s"
                        % subsecs.headers[k]
                    )
                elif last_pos == cappos:
                    p.msg(
                        "WARNING: Found probably misindented inflection header after ==%s== header: %s"
                        % (cappos, subsecs.headers[k])
                    )
            k += 2

    text = modsec.rebuild(secbody="".join(subsections))
    text = re.sub("\n\n\n+", "\n\n", text)
    if not notes:
        notes.append("convert 3+ newlines to 2")
    return text, notes


parser = blib.create_argparser(
    "Find Old English noun/verb/adjective inflections or add new ones"
)
parser.add_argument("--pos", help="Part of speech (noun, proper noun, verb, adjective)")
parser.add_argument("--new-infls", help="File of new inflections")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pages_to_infls = {}
if args.new_infls:
    saw_multiple = set()
    for lineno, line in blib.iter_items_from_file(args.new_infls):
        m = re.search("^Page ([0-9]+) (.*?): .*<new> (.*?) <end>", line)
        if m:
            index, page, decl = m.groups()
            if page in pages_to_infls:
                msg(
                    "Page %s %s: WARNING: Saw multiple inflections %s and %s, skipping"
                    % (index, page, pages_to_infls[page], decl)
                )
                saw_multiple.add(page)
            pages_to_infls[page] = decl
    for page in saw_multiple:
        del pages_to_infls[page]

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Old English %ss" % args.pos],
)
