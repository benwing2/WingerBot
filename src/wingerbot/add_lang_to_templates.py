#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, msg, tname, pname

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    if blib.page_should_be_ignored(p.title):
        p.msg("Skipping ignored page")
        return

    notes = []

    def hack_templates(parsed, langname, langnamecode=None, is_citation=False):
        if langname not in lang_data.languages_by_canonical_name:
            if not is_citation:
                langnamecode = None
        else:
            langnamecode = lang_data.languages_by_canonical_name[langname]["code"]

        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in templates_to_process:
                existing_lang = getparam(t, "lang")
                if existing_lang:
                    notes.append("move lang= to 1= in {{%s}}" % tn)
                    new_lang = existing_lang
                elif langnamecode is None:
                    p.msg("WARNING: Unable to add infer language from section for template: %s" % origt)
                    continue
                else:
                    notes.append("infer 1=%s for {{%s}} based on section it's in" % (langnamecode, tn))
                    new_lang = langnamecode
                newline = "\n" if "\n" in str(t.name) else ""  # not tname() as we want to check for spaces
                # Fetch all params.
                params = []
                for param in t.params:
                    pn = pname(param)
                    pv = str(param.value)
                    if re.search("^[0-9]+$", pn):
                        pn = str(int(pn) + 1)
                    params.append((pn, pv, param.showkey))
                # Erase all params.
                del t.params[:]
                t.add("1", new_lang + newline, preserve_spacing=False)
                # Put remaining parameters in order.
                for name, value, showkey in params:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
                if tn != templates_to_process[tn]:
                    blib.set_template_name(t, templates_to_process[tn])
                    notes.append("rename {{%s}} to {{%s}}" % (tn, templates_to_process[tn]))
            newt = str(t)
            if newt != origt:
                p.msg("Replaced <%s> with <%s>" % (origt, newt))

        return langnamecode

    p.msg("Processing")

    secs = blib.split_text_into_sections(p.text, p.msg)
    sections = secs.sections

    if not p.title.startswith("Citations"):
        for j, langname in secs.lang_list:
            parsed = blib.parse_text(sections[j])
            hack_templates(parsed, langname)
            sections[j] = str(parsed)
    else:
        # Citation section?
        langnamecode = None
        for j, langname in [(0, "Unknown")] + secs.lang_list:
            parsed = blib.parse_text(sections[j])
            langnamecode = hack_templates(parsed, langname, langnamecode=langnamecode, is_citation=True)
            sections[j] = str(parsed)

    newtext = "".join(sections)
    return newtext, notes


parser = blib.create_argparser(
    "Add language to templates, based on the section they're within"
)
parser.add_argument(
    "--from",
    help="Old name of template; multiple comma-separated templates can be given",
    metavar="FROM",
    dest="from_",
    required=True,
)
parser.add_argument("--to", help="New name of template; multiple comma-separated templates can be given", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

from_templates = args.from_.split(",")
to_templates = args.to.split(",")

if len(from_templates) != len(to_templates):
    raise ValueError(
        "Saw %s template(s) '%s' but %s new name(s) '%s'; both must agree in number"
        % ((len(from_templates), ",".join(from_templates), len(to_templates), ",".join(to_templates)))
    )
templates_to_process_list = list(zip(from_templates, to_templates))
templates_to_process = dict(templates_to_process_list)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" % template for template, new_name in templates_to_process_list],
)
