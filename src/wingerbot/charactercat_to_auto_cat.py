#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname

lang_data = lang_utils.get_lang_data()


def one_char(t):
    # return len(t) == 1 or len(t) == 2 and 0xD800 <= ord(t[0]) <= 0xDBFF
    return len(t) == 1


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "autocat":
            blib.set_template_name(t, "auto cat")
            notes.append("{{autocat}} -> {{auto cat}}")
        elif tn == "charactercat":
            m = re.search("^Category:(.*) terms spelled with (.*)$", p.title)
            if not m:
                p.msg("WARNING: Can't parse page title")
                continue
            langname, char = m.groups()
            t_lang = getparam(t, "1")
            t_char = getparam(t, "2")
            t_alt = getparam(t, "alt")
            t_sort = getparam(t, "sort")
            t_context = getparam(t, "context")
            t_context2 = getparam(t, "context2")
            if langname not in lang_data.languages_by_canonical_name:
                p.msg("WARNING: Unrecognized language name: %s" % langname)
                continue
            if not t_lang:
                t_lang = lang_data.languages_by_canonical_name[langname]["code"]
            elif lang_data.languages_by_canonical_name[langname]["code"] != t_lang:
                p.msg(
                    "WARNING: Auto-determined code %s for language name %s != manually specified %s"
                    % (lang_data.languages_by_canonical_name[langname]["code"], langname, t_lang)
                )
                continue
            if t_char == char:
                t_char = None
            if langname in ["Japanese", "Okinawan"]:
                if not one_char(char):
                    p.msg(
                        "WARNING: Japanese/Okinawan category with multichar character (length %s), skipping: %s"
                        % (len(char), str(t))
                    )
                    continue
                if t_char:
                    p.msg(
                        "WARNING: Japanese/Okinawan category with manual char %s != automatic char: %s"
                        % (t_char, str(t))
                    )
                if not t_sort:
                    p.msg("WARNING: Japanese/Okinawan category without manual sort key: %s" % str(t))
                else:
                    autosort = p.expand_text("{{#invoke:zh-sortkey/templates|sortkey|%s|%s}}" % (t_char or char, t_lang))
                    if autosort == t_sort:
                        t_sort = None
                    else:
                        p.msg(
                            "WARNING: Japanese/Okinawan category with manual sort key %s != automatic %s: %s"
                            % (t_sort, autosort, str(t))
                        )
            elif t_sort:
                autosort = p.expand_text(
                    "{{#invoke:languages/templates|getByCode|%s|makeSortKey|%s}}" % (t_lang, t_char or char)
                )
                if autosort == t_sort:
                    t_sort = None
                else:
                    p.msg(
                        "%s category with manual sort key %s != automatic %s: %s" % (langname, t_sort, autosort, str(t))
                    )

            must_continue = False
            all_existing_params = ["1", "2", "alt", "sort", "context", "context2"]
            for param in t.params:
                pn = pname(param)
                if pn not in all_existing_params:
                    p.msg("WARNING: Unrecognized param %s=%s in charactercat: %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            for param in all_existing_params:
                rmparam(t, param)
            blib.set_template_name(t, "auto cat")
            if t_char:
                t.add("char", t_char)
            if t_alt:
                t.add("alt", t_alt)
            if t_sort:
                t.add("sort", t_sort)
            if t_context:
                t.add("context", t_context)
            if t_context2:
                t.add("context2", t_context2)
            notes.append("convert {{%s}} to {{auto cat}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser("Convert {{charactercat}} to {{auto cat}}", include_pagefile=True, include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
