#!/usr/bin/env python3

import pywikibot, re, sys, unicodedata

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, tname, pname, msg

lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()


def process_text_on_page(p):
    def convert_traditional_to_simplified(langcode, trad):
        trad_simp = p.expand_text("{{#invoke:User:Benwing2/languages/utilities|generateForms|%s|%s}}" % (langcode, trad))
        if not trad_simp:
            return trad_simp
        if "||" in trad_simp:
            trad, simp = trad_simp.split("||", 1)
            return simp
        else:
            return trad_simp

    notes = []

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        if tn in ["zh-der", "zh-der/fast", "zh-list", "zh-syn-list", "zh-ant-list"]:
            out_items = []
            hide_pron = getp("hide_pron")
            if hide_pron:
                p.msg("WARNING: Found hide_pron=%s, need to handle manually: %s" % (hide_pron, str(t)))
                continue
            fold = getp("fold")
            if fold:
                p.msg("WARNING: Ignoring fold=%s: %s" % (fold, str(t)))
            title = getp("title")
            if title:
                p.msg("WARNING: Found title=%s, need to handle manually: %s" % (hide_pron, str(t)))
                continue
            name = getp("name")
            if name:
                p.msg("WARNING: Ignoring name=%s (it doesn't seem to occur anyway): %s" % (fold, str(t)))
            terms = blib.fetch_param_chain(t, "1")
            must_continue = False
            for i, term in enumerate(terms):
                origterm = term
                note = None
                if term.startswith("*"):
                    p.msg("WARNING: Saw term beginning with asterisk in %s=%s: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if "<!--" in term or "-->" in term:
                    p.msg(
                        "WARNING: Saw term with comment, needs manual handling in %s=%s: %s" % (i + 1, origterm, str(t))
                    )
                    must_continue = True
                    break
                semicolon_parts = term.split(";")
                if len(semicolon_parts) > 2:
                    p.msg("WARNING: Saw more than one semicolon in %s=%s: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if len(semicolon_parts) > 1:
                    term, note = semicolon_parts
                    if not term:
                        p.msg(
                            "WARNING: Saw empty term in %s=%s after stripping off note: %s" % (i + 1, origterm, str(t))
                        )
                        must_continue = True
                        break
                after_colon = None
                colon_parts = term.split(":")
                if len(colon_parts) > 2:
                    p.msg("WARNING: Saw more than one colon in %s=%s: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if len(colon_parts) > 1:
                    term, after_colon = colon_parts
                    if not term:
                        p.msg(
                            "WARNING: Saw empty term in %s=%s after stripping off post-colon: %s"
                            % (i + 1, origterm, str(t))
                        )
                        must_continue = True
                        break
                trad = None
                simp = None
                tr = None
                gloss = None
                slash_parts = term.split("/")
                if len(slash_parts) > 2:
                    p.msg("WARNING: Saw more than one slash in %s=%s: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if len(slash_parts) > 1:
                    trad, simp = slash_parts
                else:
                    trad = slash_parts[0]
                if not trad:
                    p.msg("WARNING: Saw empty traditional in %s=%s: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if simp is not None and not simp:
                    p.msg("WARNING: Saw empty simplified in %s=%s after slash: %s" % (i + 1, origterm, str(t)))
                    must_continue = True
                    break
                if trad == p.title:
                    # This is what the current code does.
                    continue
                if after_colon:
                    if re.search("[一-龯㐀-䶵]", after_colon):
                        if simp:
                            p.msg(
                                "WARNING: Saw Chinese text after colon in %s=%s, but simplified already present: %s"
                                % (i + 1, origterm, str(t))
                            )
                            must_continue = True
                            break
                        p.msg(
                            "Saw Chinese text after colon in %s=%s, assuming simplified: %s" % (i + 1, origterm, str(t))
                        )
                        simp = after_colon
                        after_colon = None
                    elif re.search(
                        lang_utils.zh_combining_accent_re, unicodedata.normalize("NFD", after_colon)
                    ) or re.search("[bcdfghjklmnpqrstwz]h?y?[aeiou][aeiou]?[iumnptk]?g?[1-9]", after_colon):
                        tr = after_colon
                    else:
                        gloss = after_colon

                if simp:
                    trad_to_simp = convert_traditional_to_simplified("zh", trad)
                    if trad_to_simp == simp:
                        p.msg(
                            "For traditional %s, explicit simplified %s matches auto-conversion in %s=%s, not specifying explicitly: %s"
                            % (trad, simp, i + 1, origterm, str(t))
                        )
                        simp = None
                    else:
                        p.msg(
                            "WARNING: For traditional %s, explicit simplified %s doesn't match auto-conversion %s in %s=%s, specifying explicitly: %s"
                            % (trad, simp, trad_to_simp, i + 1, origterm, str(t))
                        )

                item = "%s//%s" % (trad, simp) if simp else trad
                if tr:
                    item += "<tr:%s>" % tr
                if gloss:
                    item += "<t:%s>" % gloss
                if note:
                    langcode = None
                    if note in lang_data.languages_by_canonical_name:
                        langcode = lang_data.languages_by_canonical_name[note]["code"]
                    elif note in etym_lang_data.etym_languages_by_canonical_name:
                        langcode = etym_lang_data.etym_languages_by_canonical_name[note]["code"]
                    if langcode:
                        item = "%s:%s" % (langcode, item)
                    else:
                        item += "<qq:%s>" % note

                out_items.append(item)

            if must_continue:
                continue

            del t.params[:]
            t.add("1", "zh")
            for i, item in enumerate(out_items):
                t.add(str(i + 2), item)
            blib.set_template_name(t, "col3")
            notes.append("convert {{%s}} to {{%s|zh}}" % (tn, tname(t)))

        elif tn in ["zh-syn-saurus", "zh-ant-saurus"]:
            source = getp("1")
            must_continue = False
            for param in t.params:
                pn = pname(param)
                if pn not in ["1", "name"]:
                    p.msg("WARNING: Unhandlable param %s=%s in {{%s}}: %s" % (pn, str(param.value), tn, str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            del t.params[:]
            t.add("1", "zh")
            if source:
                t.add("2", source)
            blib.set_template_name(t, tn[3:])  # chop off zh- prefix
            notes.append("convert {{%s}} to {{%s|zh}}" % (tn, tname(t)))

    text = str(parsed)
    return text, notes


parser = blib.create_argparser(
    "Convert {{zh-der}}, {{zh-list}} to {{col3|zh}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
