#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname

from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    # FIXME: Script no longer applies and would need fixing up

    p.msg("Processing")

    direc = pagetitle_to_direc.get(p.title, None)
    if not direc:
        p.msg("WARNING: Can't locate directive for page")
        return

    parsed = blib.parse_text(p.text)
    notes = []
    direc = direc.replace("3oa", "3°a")
    for t in parsed.filter_templates():
        origt = str(t)
        if tname(t) in ["ru-conj"]:
            conjtype = getparam(t, "1")
            if not conjtype.startswith("3olda"):
                continue
            if conjtype.startswith("3olda") and conjtype != "3olda":
                p.msg("WARNING: Found 3a-old with variant, can't process: %s" % str(t))
                continue
            tempcall = re.sub(r"\{\{ru-conj", "{{ru-generate-verb-forms", str(t))
            result = p.expand_text(tempcall)
            if not result:
                p.msg("WARNING: Error generating forms, skipping")
                continue
            oldargs = blib.split_generate_args(result)
            rmparam(t, "6")
            rmparam(t, "5")
            rmparam(t, "4")
            t.add("1", direc)
            tempcall = re.sub(r"\{\{ru-conj", "{{ru-generate-verb-forms", str(t))
            result = p.expand_text(tempcall)
            if not result:
                p.msg("WARNING: Error generating forms, skipping")
                continue
            if args.delete_bad:
                newargs = blib.split_generate_args(result)
                for form in [
                    "past_m",
                    "past_f",
                    "past_n",
                    "past_pl",
                    "past_m_short",
                    "past_f_short",
                    "past_n_short",
                    "past_pl_short",
                ]:
                    oldforms = re.split(",", oldargs[form]) if form in oldargs else []
                    newforms = re.split(",", newargs[form]) if form in newargs else []
                    for oldform in oldforms:
                        if oldform not in newforms:
                            formpagename = rulib.remove_accents(oldform)
                            pp = blib.create_process_page_params(
                                args, p.index, formpagename, must_exist="WARNING: Form page doesn't exist, skipping",
                                msg_title="%s: %s" % (p.title, oldform))
                            if pp is None:
                                continue
                            assert pp.page is not None  # guaranteed by create_process_page_params
                            if formpagename == p.title:
                                pp.msg("WARNING: Attempt to delete dictionary form, skipping")
                                continue
                            secs = blib.split_text_into_sections(pp.text, pp.msg)
                            langs_seen = set(lang for _, lang in secs.lang_list)
                            if "Russian" not in langs_seen:
                                pp.msg("WARNING: Didn't see Russian section, skipping form")
                                continue
                            if len(langs_seen) > 1:
                                non_russian_langs = langs_seen - {"Russian"}
                                pp.msg("WARNING: Found entry for non-Russian language(s) %s, skipping form" % ",".join(non_russian_langs))
                                continue
                            if "Etymology 1" in pp.text:
                                pp.msg("WARNING: Found 'Etymology 1', skipping form")
                                continue
                            numinfls = len(re.findall(r"\{\{inflection of\|", pp.text))
                            if numinfls < 1:
                                pp.msg(
                                    "WARNING: Something wrong, no 'inflection of' templates on page for form %s"
                                    % formpagename
                                )
                            elif numinfls > 1:
                                pp.msg(
                                    "WARNING: Multiple 'inflection of' templates on page for form %s, skipping"
                                    % formpagename
                                )
                            else:
                                comment = "Delete erroneously created long form of %s" % p.title
                                pp.msg("Existing text for form %s: [[%s]]" % (formpagename, pp.text))
                                if args.save:
                                    pp.page.delete(comment)
                                else:
                                    pp.msg("Would delete page %s with comment=%s" % (formpagename, comment))

            notes.append("fix 3olda -> %s" % direc)
        newt = str(t)
        if origt != newt:
            p.msg("Replaced %s with %s" % (origt, newt))

    return str(parsed), notes


parser = blib.create_argparser("Fix up class 3a")
parser.add_argument("--direcfile", help="File containing pages to fix and directives.", required=True)
parser.add_argument("--delete-bad", action="store_true", help="Delete bad forms.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_direc = {}
for i, line in blib.iter_items_from_file(args.direcfile, start, end):
    page, direc = re.split(" ", line)
    pagetitle_to_direc[page] = direc

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_pages=list(pagetitle_to_direc.keys())
)
