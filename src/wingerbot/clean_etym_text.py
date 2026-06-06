#!/usr/bin/env python3

# FIXME: This should account for cases where the last thing displayed is a period, e.g.:
# From {{bor|en|es|Sra.}}

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg
from collections import defaultdict

lastcats_seen = defaultdict(int)


def process_text_on_page(p):
    origtext = p.text
    notes = []

    if blib.page_should_be_ignored(p.title):
        return

    text, texttail = blib.force_two_newlines_in_secbody(p.text, "")

    newtext = re.sub("\n\n\n+", "\n\n", text)
    if newtext != text:
        notes.append("replace 3+ newlines with 2")
        text = newtext
    newtext = re.sub("[ \t\u00a0]+\n", "\n", text)
    if newtext != text:
        notes.append("remove extraneous spaces at end of line")
        text = newtext

    def replace_after_from(m):
        fromtext = m.group(1)
        m = re.search("^(.*)&nbsp;$", fromtext)
        if m:
            fromtext = m.group(1).rstrip()
            notes.append("remove extraneous final NBSP")
        m = re.search(r"^(.*)(<br\s*/?>)$", fromtext)
        if m:
            fromtext = m.group(1).rstrip()
            removed_br = m.group(2)
            notes.append("remove extraneous final %s" % removed_br)
        if not re.search(
            r"([.?!:]|etc\.|</\s*[Rr]ef[a-z]*>|</\s*hiero>|-->|\[http[^\[\]]*\]|<[Rr]ef[^<>]*/>|<br\s*/?>|<br [^<>]*>|\{\{(cln|catlangname|C|c|top|topic|topics|catlangcode|rfv-etym|etystub|rfe|rfe-lite|rfref|root|dercat|defdate|etydate|C\.|hanja-[a-z]+|ja-rendaku2|rendaku2|ja-renj[oō]|renj[oō]|ja-from-kaminidan|ja-etym-renyokei|attn|attention|lena|Pigafetta|hu-langref|U:hu:postpositional-adjective|ru-cform-impfv-length|htetylz|ko-etym-[a-zA-Z-]*|tl-irregular-verb|sv-verb-form-pastpart|progreso|nonlemma|ref|pedia)(?:\|(?:[^{}]|\{\{[^{}]*\}\})*)?\}\}|\{\{ar-root[^{}]*\|notext=1[^{}]*\}\}|\[\[(?:Category|CAT):[^\[\]]*\]\]|\.["
            + '"'
            + r"’”'»„›)]+)$",
            fromtext,
        ):
            mm = re.search(r"\{\{([^{}|]*)(?:\|(?:[^{}]|\{\{[^{}]*\}\})*)?\}\}$", fromtext)
            if mm:
                lastcat = mm.group(1)
                lastcats_seen[lastcat] += 1
            fromtext = fromtext + "."
            fromtext = re.sub(r"[;,]\.$", ".", fromtext)
            notes.append("add missing final period (full stop) in 'From ...' line")
        return fromtext + "\n\n"

    text = re.sub(
        r"^((?:Inherited from |Borrowed from |From |\{\{(?:bor\+|inh\+)\|).*)\n\n", replace_after_from, text, 0, re.M
    )

    text = text.rstrip("\n") + texttail

    return text, notes


parser = blib.create_argparser(
    "Clean up etym-section text, adding missing periods, removing spaces at EOL and 3+ newlines",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

for template, count in sorted(lastcats_seen.items(), key=lambda x: -x[1]):
    msg("%-50s = %s" % (template, count))
