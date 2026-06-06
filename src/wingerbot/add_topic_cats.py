#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils, templatize_categories
from wingerbot.blib import getparam, rmparam, msg, tname

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p, cats_to_add, japanese_sort_keys):
    if p.title not in cats_to_add:
        return

    p.msg("Processing")

    notes = []

    sort_key = japanese_sort_keys.get(p.title, "")

    text = p.text
    for lang, cats in cats_to_add[p.title]:
        if lang not in lang_data.languages_by_code:
            p.msg("WARNING: Saw unrecognized language code '%s'" % lang)
            continue
        langname = lang_data.languages_by_code[lang]["canonicalName"]
        modsec = blib.find_modifiable_lang_section(text, langname, p.msg)
        if modsec is None:
            continue
        if lang == "zh":
            topics_temp = "zh-cat"
            topics_temp_lang = None
            topics_temp_cats = "1"
        else:
            topics_temp = "C"
            topics_temp_lang = "1"
            topics_temp_cats = "2"
        langtext, this_notes = templatize_categories.process_text_on_page(
            p.index, p.title, modsec.sections[modsec.j], lang, langname, topics_temp
        )
        notes.extend(this_notes)
        parsed = blib.parse_text(langtext)
        last_topics_temp = None
        existing_topics = None
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn == topics_temp:
                if topics_temp_lang:
                    topics_lang = getparam(t, topics_temp_lang)
                    if topics_lang != lang:
                        p.msg("WARNING: Saw wrong-language topics template: %s" % str(t))
                        continue
                last_topics_temp = t
                existing_topics = blib.fetch_param_chain(t, topics_temp_cats)
                for existing_topic in existing_topics:
                    existing_topic = existing_topic.strip()
                    if existing_topic in cats:
                        cats = [cat for cat in cats if cat != existing_topic]
        if cats:
            if last_topics_temp and (
                lang != "ja" or japanese_sort_keys and getparam(last_topics_temp, "sort") == sort_key
            ):
                origt = str(last_topics_temp)
                existing_topics.extend(cats)
                sort = getparam(last_topics_temp, "sort")
                rmparam(last_topics_temp, sort)
                blib.set_param_chain(last_topics_temp, existing_topics, topics_temp_cats)
                if sort:
                    last_topics_temp.add("sort", sort)
                notes.append(
                    "add categories %s to existing {{%s}}"
                    % (",".join("%s:%s" % (lang, cat) for cat in cats), topics_temp)
                )
                if str(t) != origt:
                    p.msg("Replaced %s with %s" % (origt, str(t)))
                modsec.sections[modsec.j] = str(parsed)
            else:
                secbody, sectail = blib.split_trailing_separator(langtext)
                if not secbody.endswith("\n"):
                    secbody += "\n"
                secbody_without_cats, sectail_with_cats = blib.split_trailing_categories(secbody, sectail)
                if sectail_with_cats == sectail:  # no categories
                    secbody += "\n"
                new_temp = "{{%s%s|%s%s}}" % (
                    topics_temp,
                    ("|" + lang if topics_temp_lang else ""),
                    "|".join(cats),
                    "|sort=%s" % sort_key if lang == "ja" and sort_key else "",
                )
                secbody += new_temp + "\n"
                notes.append(
                    "add categories %s in new {{%s}}" % (",".join("%s:%s" % (lang, cat) for cat in cats), topics_temp)
                )
                modsec.sections[modsec.j] = secbody + sectail
        text = "".join(modsec.sections)

    return text, notes


parser = blib.create_argparser("Add categories")
parser.add_argument(
    "--direcfile",
    help="File containing pages and topic categories to add, e.g. 'Rus ||| cs:Male people|Nationalities,sh:Male people|Nationalities'",
    required=True,
)
parser.add_argument("--japanese-sort-keys", help="File containing Japanese sort keys, e.g. '風俗嬢 ||| ふうぞくじょう'")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

cats_to_add = {}
pages_to_process = []

for index, line in blib.iter_items_from_file(args.direcfile):
    if " ||| " not in line:
        msg("Line %s: WARNING: Saw bad line in --direcfile: %s" % (index, line))
        continue
    pagetitle, catspecs = line.split(" ||| ")
    catspecs = re.split(r",(?! )", catspecs)
    cats_by_lang = []
    for catspec in catspecs:
        lang, cats = catspec.split(":")
        cats = cats.split("|")
        cats_by_lang.append((lang, cats))
    if pagetitle in cats_to_add:
        cats_to_add[pagetitle].extend(cats_by_lang)
    else:
        cats_to_add[pagetitle] = cats_by_lang
        pages_to_process.append(pagetitle)

deduped_cats_to_add = {}
for pagetitle, cats_by_lang_list in cats_to_add.items():
    cats_by_lang = {}
    for lang, cats in cats_by_lang_list:
        if lang not in cats_by_lang:
            cats_by_lang[lang] = []
        for cat in cats:
            if cat not in cats_by_lang[lang]:
                cats_by_lang[lang].append(cat)
    deduped_cats_to_add[pagetitle] = list(cats_by_lang.items())

japanese_sort_keys = {}
if args.japanese_sort_keys:
    for index, line in blib.iter_items_from_file(args.japanese_sort_keys):
        if " ||| " not in line:
            msg("Line %s: WARNING: Saw bad line in --japanese-sort-keys: %s" % (index, line))
            continue
        pagetitle, sort_key = line.split(" ||| ")
        japanese_sort_keys[pagetitle] = sort_key


def do_process_text_on_page(p):
    return process_text_on_page(p, deduped_cats_to_add, japanese_sort_keys)


blib.do_pagefile_cats_refs(
    args, start, end, do_process_text_on_page, default_pages=pages_to_process
)
