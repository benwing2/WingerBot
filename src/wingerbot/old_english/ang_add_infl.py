#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname

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


def get_indentation_level(header):
    return len(re.sub("[^=].*", "", header, 0, re.S))


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pos = args.pos
    cappos = pos.capitalize()
    notes = []

    pagemsg("Processing")

    modsec = blib.find_modifiable_lang_section(text, "Old English", pagemsg)
    if modsec is None:
        return
    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    k = 2
    last_pos = None
    while k < len(subsections):
        if subsecs.subsection_header_dict[k] == cappos:
            level = subsecs.subsection_levels[k]
            last_pos = cappos
            endk = k + 2
            while endk < len(subsections) and subsecs.subsection_levels[endk] > level:
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
                    newhead = getparam(t, "head").strip() or pagetitle
                    if head:
                        pagemsg("WARNING: Found two heads under one POS section: %s and %s" % (head, newhead))
                    head = newhead
                if tn == pos_to_new_style_infl_template[pos] or (
                    pos_to_old_style_infl_template_prefix[pos]
                    and tn.startswith(pos_to_old_style_infl_template_prefix[pos])
                ):
                    if inflt:
                        pagemsg(
                            "WARNING: Found two inflection templates under one POS section: %s and %s"
                            % (str(inflt), str(t))
                        )
                    inflt = t
                    pagemsg(
                        "Found %s inflection for headword %s: <from> %s <to> {{%s|%s}} <end>"
                        % (
                            pos,
                            head or pagetitle,
                            str(t),
                            pos_to_new_style_infl_template[pos],
                            getparam(t, "1") if pos == "verb" else head or pagetitle,
                        )
                    )
            if not inflt:
                pagemsg(
                    "Didn't find %s inflection for headword %s: <new> {{%s|%s%s}} <end>"
                    % (
                        pos,
                        head or pagetitle,
                        pos_to_new_style_infl_template[pos],
                        head or pagetitle,
                        "" if pos == "noun" else "<>",
                    )
                )
                if pages_to_infls:
                    for l in range(k, endk, 2):
                        if subsecs.subsection_header_dict[l] in ["Declension", "Inflection", "Conjugation"]:
                            secparsed = blib.parse_text(subsections[l])
                            for t in secparsed.filter_templates():
                                tn = tname(t)
                                if tname(t) != "rfinfl":
                                    pagemsg(
                                        "WARNING: Saw unknown template %s in existing inflection section, skipping"
                                        % (str(t))
                                    )
                                    break
                            else:  # no break
                                if pagetitle not in pages_to_infls:
                                    pagemsg("WARNING: Couldn't find inflection for headword %s" % (head or pagetitle))
                                else:
                                    m = re.search(r"\A(.*?)(\n*)\Z", subsections[l], re.S)
                                    sectext, final_newlines = m.groups()
                                    subsections[l] = pages_to_infls[pagetitle] + final_newlines
                                    pagemsg(
                                        "Replaced existing decl text <%s> with <%s>"
                                        % (sectext, pages_to_infls[pagetitle])
                                    )
                                    notes.append(
                                        "replace decl text <%s> with <%s>" % (sectext, pages_to_infls[pagetitle])
                                    )
                            break
                    else:  # no break
                        if pagetitle not in pages_to_infls:
                            pagemsg("WARNING: Couldn't find inflection for headword %s" % (head or pagetitle))
                        else:
                            insert_k = k + 2
                            while insert_k < endk and subsecs.subsection_header_dict[insert_k] == "Usage notes":
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
                                pages_to_infls[pagetitle] + "\n\n",
                            ]
                            pagemsg(
                                "Inserted level-%s inflection section with inflection <%s>"
                                % (level + 1, pages_to_infls[pagetitle])
                            )
                            notes.append("add decl <%s>" % pages_to_infls[pagetitle])
                            endk += 2  # for the two subsections we inserted

            k = endk
        else:
            m = re.search(
                r"^(Noun|Proper noun|Pronoun|Determiner|Verb|Adjective|Adverb|Interjection|Conjunction)$",
                subsecs.subsection_header_dict[k],
            )
            if m:
                last_pos = m.group(1)
            if subsecs.subsection_header_dict[k] in ["Declension", "Inflection", "Conjugation"]:
                if not last_pos:
                    pagemsg(
                        "WARNING: Found inflection header before seeing any parts of speech: %s"
                        % subsecs.subsection_header_dict[k]
                    )
                elif last_pos == cappos:
                    pagemsg(
                        "WARNING: Found probably misindented inflection header after ==%s== header: %s"
                        % (cappos, subsecs.subsection_header_dict[k])
                    )
            k += 2

    text = modsec.rebuild(secbody="".join(subsections))
    text = re.sub("\n\n\n+", "\n\n", text)
    if not notes:
        notes.append("convert 3+ newlines to 2")
    return text, notes


parser = blib.create_argparser(
    "Find Old English noun/verb/adjective inflections or add new ones", include_pagefile=True, include_stdin=True
)
parser.add_argument("--pos", help="Part of speech (noun, proper noun, verb, adjective)")
parser.add_argument("--new-infls", help="File of new inflections")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pages_to_infls = {}
if args.new_infls:
    saw_multiple = set()
    for line in blib.yield_items_from_file(args.new_infls):
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
    edit=not not pages_to_infls,
    stdin=True,
    default_cats=["Old English %ss" % args.pos],
)
