#!/usr/bin/env python3

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, tname, msg, errandmsg, site

output_pages_to_delete = []


def remove_anagram_from_page(p, pagetitle_to_remove):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Italian", p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "Anagrams":
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                tn = tname(t)

                def getp(param):
                    return getparam(t, param)

                if tn == "anagrams":
                    if getp("1") != "it":
                        p.msg("WARNING: Wrong language in {{anagrams}}: %s" % str(t))
                        return
                    anagrams = blib.fetch_param_chain(t, "2")
                    anagrams = [x for x in anagrams if x != pagetitle_to_remove]
                    if anagrams:
                        blib.set_param_chain(t, anagrams, "2")
                        notes.append(
                            "remove anagram '%s', page deleted or renamed%s" % (pagetitle_to_remove, annotation)
                        )
                        subsections[k] = str(parsed)
                    else:
                        subsections[k - 1] = ""
                        subsections[k] = ""
                        notes.append(
                            "remove Anagrams section; only had '%s', which has been deleted or renamed%s"
                            % (pagetitle_to_remove, annotation)
                        )

    return modsec.rebuild(secbody="".join(subsections)), notes


def process_page_for_anagrams(p, modify_this_page=False):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Italian", p.msg, force_final_nls=True)
    if modsec is None:
        return

    anagrams = []

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "Anagrams":
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                tn = tname(t)

                def getp(param):
                    return getparam(t, param)

                if tn == "anagrams":
                    if getp("1") != "it":
                        p.msg("WARNING: Wrong language in {{anagrams}}: %s" % str(t))
                        return
                    for anagram in blib.fetch_param_chain(t, "2"):
                        if anagram not in anagrams:
                            anagrams.append(anagram)
                elif tn == "l":
                    if getp("1") != "it":
                        p.msg("WARNING: Wrong language in {{l}}: %s" % str(t))
                        return
                    anagram = getp("2")
                    if anagram not in anagrams:
                        anagrams.append(anagram)
            if modify_this_page:
                subsections[k - 1] = ""
                subsections[k] = ""
                notes.append("remove Anagrams section prior to renaming page%s" % annotation)

    text = modsec.rebuild(secbody="".join(subsections))

    for anagram_index, anagram in enumerate(anagrams, start=1):
        def do_process_page(pp):
            return remove_anagram_from_page(pp, p.title)
        blib.do_edit(args, "%s.%s" % (p.index, anagram_index), anagram, do_process_page,
                     msg_title="%s: %s" % (p.title, anagram))

    return text, notes


def process_page_for_deletion(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Italian", p.msg)
    if modsec is None:
        return

    sections, j, secbody, sectail = modsec.props()
    if not modsec.has_non_lang:
        # Can delete the whole page, but check for non-blank section 0
        cleaned_sec0 = re.sub(r"^\{\{also\|.*?\}\}\n", "", sections[0])
        if cleaned_sec0.strip():
            p.msg(
                "WARNING: Whole page deletable except that there's text above all sections: <%s>" % cleaned_sec0.strip()
            )
            return
        #this_comment = "delete bad Italian non-lemma form"
        #if args.save:
        #    p.page.delete('%s (content was "%s")' % (this_comment, p.text))
        #    p.errandmsg("Deleted (comment=%s)" % this_comment)
        #else:
        #    p.msg("Would delete (comment=%s)" % this_comment)
        p.msg("Page should be deleted")
        output_pages_to_delete.append(p.title)
        return

    del sections[j]
    del sections[j - 1]
    notes.append("remove Italian section for bad (nonexistent or misspelled) form%s" % annotation)
    if j > len(sections):
        # We deleted the last section; remove the final newlines.
        sections[-1] = sections[-1].rstrip("\n")
    text = "".join(sections)

    return text, notes


parser = blib.create_argparser("Delete/rename Italian forms, fixing up anagrams",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="File listing forms to delete/rename.", required=True)
parser.add_argument("--comment", help="Optional additional comment to use.")
parser.add_argument("--output-pages-to-delete", help="Output file containing forms to delete.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
annotation = " (%s)" % args.comment if args.comment else ""

input_pages_to_delete = []
output_pages_to_delete = []
pages_to_rename = []

# Separate pages to delete and rename. Do pages to delete first so we can run this in sysop mode
# (python login.py --sysop), and it will first delete the necessary pages, then ask for the non-sysop password and
# rename the remaining pages.
for lineindex, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search("^(.*) -> (.*)$", line)
    if m:
        frompagetitle, topagetitle = m.groups()
        pages_to_rename.append((lineindex, frompagetitle, topagetitle))
    else:
        m = re.search("^(.*): delete$", line)
        if m:
            badpagetitle = m.group(1)
            input_pages_to_delete.append((lineindex, badpagetitle))
        else:
            errandmsg("Line %s: Unrecognized line: %s" % (lineindex, line))

for badindex, badpagetitle in input_pages_to_delete:
    blib.do_edit(args, badindex, badpagetitle, process_page_for_anagrams, must_exist=True)
    blib.do_edit(args, badindex, badpagetitle, process_page_for_deletion, must_exist=True)

for rename_index, frompagetitle, topagetitle in pages_to_rename:
    def remove_anagrams_and_rename(p):
        def do_process_page(p):
            return process_page_for_anagrams(p, modify_this_page=True)

        blib.do_edit(args, p.index, p.page, do_process_page)
        topage = pywikibot.Page(site, topagetitle)
        if blib.safe_page_exists(topage, p.errandmsg):
            p.errandmsg("Destination page %s already exists, not moving" % topagetitle)
            continue
        this_comment = "rename bad Italian non-lemma form"
        if args.save:
            try:
                p.page.move(topagetitle, reason=this_comment, movetalk=True, noredirect=True)
                p.errandmsg("Renamed to %s" % topagetitle)
            except pywikibot.exceptions.PageRelatedError as error:
                p.errandmsg("Error moving to %s: %s" % (topagetitle, error))
        else:
            p.msg("Would rename to %s (comment=%s)" % (topagetitle, this_comment))
    blib.do_edit(args, rename_index, frompagetitle, remove_anagrams_and_rename, must_exist=True)

msg("The following pages need to be deleted:")
for page in output_pages_to_delete:
    msg(page)
if args.output_pages_to_delete:
    with open(args.output_pages_to_delete, "w", encoding="utf-8") as fp:
        for page in output_pages_to_delete:
            print(page, file=fp)
