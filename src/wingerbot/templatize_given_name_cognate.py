#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, tname, pname, msg

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    origtext = p.text
    notes = []

    def templatize_cognate_line(m):
        origline = m.group(0)
        line_no_ng = re.sub(r"\{\{(?:n-g|non-gloss definition)\|((?:[^{}]|\{\{[^{}]*\}\})*)\}\}", r"\1", origline)
        m = re.search(
            r"^(.*)\{\{(given name\|[^{}\n]*?)\}\}[,;]? *(?:[Aa] |[Aa]n |[Tt]he )?((?:rather|less)? *(?:African-American|American|British|rare|common|uncommon|occasional|modern|19[0-9]0s) *)?((?:[A-Z][a-z]+ )+)?\[*(cognate|equivalent|variant|variant form|spelling variant|variant spelling)\]* (?:with|to|of) (?:the )?(?:English |Modern English |\{\{etyl\|en\|-\}\} )?(?:name )?(.*?)(\.?)$",
            line_no_ng,
        )
        if not m:
            p.msg("WARNING: Unable to parse line: <from> %s <to> %s <end>" % (origline, origline))
            return origline
        pre_text, template, usage, source_lang, cognate_term, cognate_text, period = m.groups()
        m = re.search(r"^given name\|(.*?)(\||$)", template)
        if not m:
            p.msg(
                "WARNING: Something weird, can't parse lang out of template %s: <from> %s <to> %s <end>"
                % (template, origline, origline)
            )
            return origline
        lang = m.group(1)
        if source_lang:
            source_lang = source_lang.strip()
            if source_lang not in lang_data.languages_by_canonical_name:
                p.msg(
                    "WARNING: Unrecognized source lang %s, can't parse: <from> %s <to> %s <end>"
                    % (source_lang, origline, origline)
                )
                return origline
            source_lang_code = lang_data.languages_by_canonical_name[source_lang]["code"]
            if source_lang_code != lang:
                p.msg(
                    "WARNING: Source lang code %s for %s != template lang code %s, can't parse: <from> %s <to> %s <end>"
                    % (source_lang_code, source_lang, lang, origline, origline)
                )
                return origline
        is_variant = "variant" in cognate_term
        split_cognates = re.split(r"(?: and | or |, *)", cognate_text)
        cognates = []
        for split_cognate in split_cognates:
            split_cognate = re.sub("^'*(.*?)'*$", r"\1", split_cognate)
            m = re.search(r"^\{\{(?:m|l|m\+|cog)\|([^|{}\n]+)\|([^|{}\n]*)\}\}$", split_cognate)
            if m:
                coglang, cognate = m.groups()
                if is_variant:
                    if coglang != lang:
                        p.msg(
                            "WARNING: Variant lang code %s != template lang code %s, can't parse: <from> %s <to> %s <end>"
                            % (coglang, lang, origline, origline)
                        )
                        return origline
                    cognates.append(cognate)
                else:
                    if coglang == "en":
                        cognates.append(cognate)
                    else:
                        cognates.append("%s:%s" % (coglang, cognate))
                continue
            m = re.search(r"^\[\[(?:[^|\[\]{}\n]*\|)?([^|\[\]{}\n]*)\]\]$", split_cognate)
            if m:
                cognates.append(m.group(1))
                continue
            m = re.search(r"^[A-Z][a-z]+$", split_cognate)
            if m:
                cognates.append(split_cognate)
                continue
            p.msg(
                "WARNING: Can't parse cognate/equivalent/variant text <%s> in line: <from> %s <to> %s <end>"
                % (split_cognate, origline, origline)
            )
            return origline
        eq_params = []
        if is_variant:
            baseparam = "var"
        else:
            baseparam = "eq"
        for index, cognate in enumerate(cognates):
            if index == 0:
                param = baseparam
            else:
                param = "%s%s" % (baseparam, index + 1)
            eq_params.append("|%s=%s" % (param, cognate))
        usagetext = usage and "|usage=%s" % usage.strip() or ""
        notes.append("templatize English equivalent name(s) %s into {{given name}}" % ",".join(cognates))
        retval = "%s{{%s%s%s}}%s" % (pre_text, template, usagetext, "".join(eq_params), period)
        p.msg("Replaced <%s> with <%s>" % (origline, retval))
        return retval

    text = re.sub(
        r"^.*\{\{given name\|.*?\}\}.*(cognate|equivalent|variant).*$", templatize_cognate_line, p.text, 0, re.M
    )
    return text, notes


parser = blib.create_argparser(
    "Templatize 'cognate/equivalent/variant to/of NAME' into {{given name}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
