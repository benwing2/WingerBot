#!/usr/bin/env python3

import re
from collections import defaultdict

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname


def remove_comment_continuations(text):
    return text.replace("<!--\n-->", "").strip()


def process_text_on_page(p):
    p.msg("Processing")

    notes = []

    if blib.page_should_be_ignored(p.title):
        p.msg("WARNING: Page should be ignored")
        return

    parsed = blib.parse_text(p.text)

    templates_to_replace = []

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        if tn == "inflection of":

            params = []
            if getparam(t, "lang"):
                lang = getparam(t, "lang")
                term_param = 1
                notes.append("moved lang= in {{%s}} to 1=" % tn)
            else:
                lang = getparam(t, "1")
                term_param = 2
            tr = getparam(t, "tr")
            term = getparam(t, str(term_param))
            alt = getparam(t, "alt") or getparam(t, str(term_param + 1))
            tags = []
            for param in t.params:
                pname = str(param.name).strip()
                pval = str(param.value).strip()
                if re.search("^[0-9]+$", pname):
                    if int(pname) >= term_param + 2:
                        if pval:
                            tags.append(pval)
                        else:
                            notes.append("removed empty tags from {{%s}}" % tn)
                elif pname not in ["lang", "tr", "alt"]:
                    params.append((pname, pval, param.showkey))

            if lang == "pl":
                newtags = ["nv" if tag == "other" else tag for tag in tags]
                if tags != newtags:
                    notes.append("replaced 'other' with 'nv' in Polish {{%s}}" % tn)
                tags = newtags

            # Erase all params.
            del t.params[:]
            # Put back new params.
            # Strip comment continuations and line breaks. Such cases generally have linebreaks after semicolons
            # as well, but we remove those. (FIXME, consider preserving them.)
            t.add("1", remove_comment_continuations(lang))
            t.add("2", remove_comment_continuations(term))
            tr = remove_comment_continuations(tr)
            if tr:
                t.add("tr", tr)
            t.add("3", remove_comment_continuations(alt))
            next_tag_param = 4

            # Put back the tags into the template and note stats on bad tags
            for tag in tags:
                t.add(str(next_tag_param), tag)
                next_tag_param += 1
            for pname, pval, showkey in params:
                t.add(pname, pval, showkey=showkey, preserve_spacing=False)
            if origt != str(t):
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Replace 'other' with 'nv' in Polish {{inflection of}} templates"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
