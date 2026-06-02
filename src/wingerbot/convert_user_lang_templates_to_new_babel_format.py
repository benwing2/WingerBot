#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname
from collections import defaultdict

by_lang_and_level = defaultdict(dict)


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    did_parse = False
    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param).strip()

        m = re.search("^Template:User (.+)-([0-5N])$", p.title)
        if m:
            lang, level = m.groups()
        else:
            m = re.search("^Template:User ([a-zA-Z-]+)$", p.title)
            if m:
                lang, level = m.group(1), "-"
            else:
                lang, level = None, None
        m = re.search("^User lang-([0-5N])$", tn)
        if m:
            tn_level = m.group(1)
        elif tn == "User lang":
            tn_level = "-"
        else:
            tn_level = None
        if tn_level:
            tn_lang = getp("1")
            if lang and tn_lang != lang:
                p.msg("WARNING: Pagetitle language %s disagrees with template language %s" % (lang, tn_lang))
            if level and tn_level != level:
                p.msg("WARNING: Pagetitle level %s disagrees with template level %s" % (level, tn_level))
            text = getp("2")
            text = re.sub(r"\[\[:Category:User [a-zA-Z-]+-[0-5N]\|", "[[$1|", text)
            text = re.sub(r"\[\[:Category:User [a-zA-Z-]+\|", "[[$2|", text)
            text = re.sub(
                r"\{\{#switch:\{\{User gender\|\{\{\{g\|?\}\}\}\}\}\|f=([^|]*)\|([^=|]*)\}\}",
                r"{{GENDER:$4|\2|\1}}",
                text,
            )
            text = text.replace("'''", "")
            by_lang_and_level[lang or tn_lang][level or tn_level] = text
            did_parse = True
    if not did_parse:
        p.msg("WARNING: Couldn't find user language competency template")


parser = blib.create_argparser(
    "Convert {{User lang-N}} templates to the format needed for the new [[Module:Babel]]",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--comment", help="Comment about source of data.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

output = []


def ins(txt):
    output.append(txt)


ins("return {")
if args.comment:
    ins("\t-- %s" % args.comment)
for langcode, by_level in sorted(list(by_lang_and_level.items())):
    ins("")
    ins("\t-------------------------- %s --------------------------" % langcode)
    lines = []
    for level in ["0", "1", "2", "3", "4", "5", "N"]:
        if level in by_level:
            text = by_level[level]
            if "\n" in text:
                text = "[==[%s]==]" % text
            else:
                text = '"%s"' % text.replace('"', r"\"")
            lines.append('\t["%s-%s"] = %s,' % (langcode, level, text))
    output.extend(lines)
ins("}")

print("\n".join(output) + "\n")
