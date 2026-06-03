#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname
from wingerbot.convert_col_top_topN_to_col import simplify_link, convert_one_line

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    list_helper_2_t = None
    dont_remove_list_helper = False
    hypernym = None
    saw_compass = False
    converted_compass = False

    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)

        def getp(param):
            return getparam(t, param).strip()

        if tn == "list helper 2":
            if list_helper_2_t:
                p.msg("WARNING: Saw {{list helper 2}} twice, can't handle")
                return
            list_helper_2_t = t
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if pn not in ["title", "list", "hypernym", "cat"]:
                    p.msg("WARNING: Unrecognized param %s=%s: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            title = getp("title")
            if blib.remove_links(title) != "compass points":
                p.msg("WARNING: Unrecognized title in {{list helper 2}}, can't handle: %s" % origt)
                dont_remove_list_helper = True
                continue
            if getp("list"):
                p.msg("WARNING: Non-empty list= in {{list helper 2}}, can't handle: %s" % origt)
                dont_remove_list_helper = True
                continue
            hypernym = getp("hypernym")

        if tn == "compass":
            if saw_compass:
                p.msg("WARNING: Saw {{compass}} twice, not removing {{list helper 2}} if present")
                dont_remove_list_helper = True
            saw_compass = True
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if not re.search("^(n|ne|nw|s|se|sw|w|e)[0-9]*(|alt|tr)$", pn) and pn != "lang" and pn != "1":
                    p.msg("WARNING: Unrecognized param %s=%s: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            lang = getp("lang") or getp("1")
            if not lang:
                p.msg("WARNING: Found {{compass}} without language code: %s" % origt)
                continue
            if lang not in lang_data.languages_by_code:
                p.msg("WARNING: Unknown language code %s in {{compass}}: %s" % (lang, origt))
                continue
            langname = lang_data.languages_by_code[lang]["canonicalName"]

            def process_direction(direc):
                terms = []
                for i in range(1, 20):
                    param = "%s%s" % (direc, "" if i == 1 else i)
                    term = getp(param)
                    alt = getp(param + "alt")
                    tr = getp(param + "tr")
                    tr = re.sub("^''(.*)''$", r"\1", tr)
                    tr = re.sub(r"^\[\[(.*)\]\]$", r"\1", tr)
                    if alt:
                        term = simplify_link(False, term, alt, None, lang, langname, p.msg, p.expand_text)
                        if tr:
                            term = "%s<tr:%s>" % (term, tr)
                    else:
                        els, this_notes = convert_one_line(term, False, lang, langname, p.msg, p.expand_text)
                        if type(els) is str:
                            p.msg("WARNING: %s" % els)
                        elif els is not None:
                            if tr and len(els) > 1:
                                p.msg(
                                    "WARNING: Multiple elements and translit in %s=, can't handle: %s" % (direc, origt)
                                )
                                return None, []
                            term = ",".join(els)
                        if tr:
                            if "<tr:" in term:
                                p.msg(
                                    "WARNING: Saw external %str= and internal translit as well, can't handle: %s"
                                    % (param, origt)
                                )
                                return None, []
                            term = "%s<tr:%s>" % (term, tr)
                    if term:
                        terms.append(term)
                return ",".join(terms), this_notes

            this_notes = []

            if hypernym:
                hypernym_els, this_this_notes = convert_one_line(hypernym, True, lang, langname, p.msg, p.expand_text)
                if type(hypernym_els) is str or hypernym_els is None:
                    p.msg("WARNING: %s: hypernym=%s" % (hypernym_els or "Can't parse hypernym", hypernym))
                    dont_remove_list_helper = True
                    hypernym = None
                else:
                    hypernym = ",".join(hypernym_els)

            directions = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
            direcparams = {}
            must_continue = False
            for direc in directions:
                val, this_this_notes = process_direction(direc)
                if val is None:
                    must_continue = True
                    break
                if val:
                    this_notes.extend(this_this_notes)
                    direcparams[direc] = val
            if must_continue:
                continue

            del t.params[:]
            t.name = "#invoke:topic list"  # not blib.set_template_name(), which preserves whitespace
            t.add("1", "compass\n")
            if hypernym:
                t.add("hypernym", hypernym + "\n", preserve_spacing=False)
            for direc in directions:
                if direc in direcparams:
                    t.add(direc, direcparams[direc] + "\n", preserve_spacing=False)
            notes.append("convert {{compass}} to [[Module:topic list]] compass invocation")
            notes.extend(this_notes)
            converted_compass = True

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    text = str(parsed)
    if list_helper_2_t and not dont_remove_list_helper and converted_compass:
        newtext, changed = blib.replace_in_text(
            text, re.escape(str(list_helper_2_t)) + "\n*", "", p.msg, abort_if_warning=True, is_re=True
        )
        if changed:
            text = newtext
            notes.append(
                "remove {{list helper 2}}, incorporating any hypernym into [[Module:topic list]] compass invocation"
            )

    return text, notes


parser = blib.create_argparser(
    "Convert old-style {{compass}} calls to use [[Module:topic list]]", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
