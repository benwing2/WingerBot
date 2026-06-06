#!/usr/bin/env python3

import re, sys, unicodedata

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, tname, pname, msg

lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        if tn in ["zh-syn", "zh-ant", "zh-hyper", "zh-hypo", "zh-cot"]:
            out_items = []
            terms = blib.fetch_param_chain(t, "1")
            must_continue = False
            for i, term in enumerate(terms):
                termind = i + 1
                origterm = term
                note = None
                if term.startswith("*") or term.endswith("*"):
                    p.msg(
                        "WARNING: Saw term beginning or ending with asterisk in %s=%s: %s" % (termind, origterm, str(t))
                    )
                    must_continue = True
                    break
                if "<!--" in term or "-->" in term:
                    p.msg(
                        "WARNING: Saw term with comment, needs manual handling in %s=%s: %s"
                        % (termind, origterm, str(t))
                    )
                    must_continue = True
                    break
                if "/" in term:
                    p.msg(
                        "WARNING: Saw term with slash, needs manual handling in %s=%s: %s" % (termind, origterm, str(t))
                    )
                    must_continue = True
                    break
                if "^" in term:
                    p.msg(
                        "WARNING: Saw term with circumflex, needs manual handling in %s=%s: %s"
                        % (termind, origterm, str(t))
                    )
                    must_continue = True
                    break

                def get_mod(pref):
                    if termind == 1:
                        return getp(pref) or getp(pref + "1")
                    else:
                        return getp("%s%s" % (pref, termind))

                tr = get_mod("tr")
                gloss = get_mod("t")
                qual = get_mod("q")
                if tr:
                    term += "<tr:%s>" % tr
                if gloss:
                    term += "<t:%s>" % gloss
                if qual:
                    langcode = None
                    if qual in lang_data.languages_by_canonical_name:
                        langcode = lang_data.languages_by_canonical_name[qual]["code"]
                    elif qual in etym_lang_data.etym_languages_by_canonical_name:
                        langcode = etym_lang_data.etym_languages_by_canonical_name[qual]["code"]
                    elif qual in lang_data.languages_by_alias:
                        alias_langs = lang_data.languages_by_alias[qual]
                        if len(alias_langs) > 1:
                            p.msg(
                                "WARNING: For apparent language alias '%s', saw multiple possible language codes %s: %s"
                                % (qual, ",".join(lang["code"] for lang in alias_langs), str(t))
                            )
                        else:
                            langcode = alias_langs[0]["code"]
                    elif qual in etym_lang_data.etym_languages_by_alias:
                        alias_langs = etym_lang_data.etym_languages_by_alias[qual]
                        if len(alias_langs) > 1:
                            p.msg(
                                "WARNING: For apparent etymology language alias '%s', saw multiple possible language codes %s: %s"
                                % (qual, ",".join(lang["code"] for lang in alias_langs), str(t))
                            )
                        else:
                            langcode = alias_langs[0]["code"]
                    if langcode:
                        term = "%s:%s" % (langcode, term)
                    else:
                        term += "<qq:%s>" % qual

                out_items.append(term)

            if must_continue:
                continue

            must_continue = False
            for param in t.params:
                ok = False
                pn = pname(param)
                if re.search("^[0-9]+$", pn):
                    ok = True
                else:
                    m = re.search("^(tr|t|q)([0-9]*)$", pn)
                    if m:
                        ind = m.group(2)
                        if ind == "" or (int(ind) >= 1 and int(ind) <= len(terms)):
                            ok = True
                if not ok:
                    p.msg("WARNING: Saw unrecognized param %s=%s in %s" % (pn, str(param.value), str(t)))
                    must_continue = True
                    break

            if must_continue:
                continue

            del t.params[:]
            t.add("1", "zh")
            for i, item in enumerate(out_items):
                t.add(str(i + 2), item)
            blib.set_template_name(t, tn[3:])  # chop off zh- prefix
            notes.append("convert {{%s}} to {{%s|zh}}" % (tn, tname(t)))

    text = str(parsed)
    return text, notes


parser = blib.create_argparser(
    "Convert {{zh-syn}}, {{zh-ant}} etc. to {{syn|zh}}, {{ant|zh}}, etc."
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
