#!/usr/bin/env python3

from wingerbot import blib, lang_utils
from wingerbot.blib import msg

etym_lang_data = lang_utils.get_etym_lang_data()

parser = blib.create_argparser("Create code-to-canonical-name and canonical-names tables for etymology languages",
                               no_include_pagefile=True, no_include_stdin=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

code_to_canonical_name = {}
canonical_name_to_code = {}

for etyl in etym_lang_data.etym_languages:
    code = etyl["code"]
    canonical_name = etyl["canonicalName"]
    is_alias = "mainCode" in etyl and etyl["mainCode"] != code
    if code in code_to_canonical_name:
        msg("WARNING: Saw code %s twice" % code)
    code_to_canonical_name[code] = canonical_name
    if not is_alias:
        if canonical_name in canonical_name_to_code:
            msg("WARNING: Saw canonical name %s twice" % canonical_name)
        canonical_name_to_code[canonical_name] = code
    else:
        msg("is_alias = %s" % etyl)

msg("--------------------- [[Module:etymology languages/code to canonical name]] -------------------")


def do_code_to_canonical_name(p):
    text = []

    def ins(txt):
        text.append(txt)

    ins("return {")
    for code, name in sorted(list(code_to_canonical_name.items())):
        ins('\t["%s"] = "%s",' % (code, name))
    ins("}")
    return "\n".join(text), "update [[Module:etymology languages/code to canonical name]]"


blib.do_edit(
    args,
    1,
    "Module:etymology languages/code to canonical name",
    do_code_to_canonical_name,
)

msg("--------------------- [[Module:etymology languages/canonical names]] -------------------")


def do_canonical_names(p):
    text = []

    def ins(txt):
        text.append(txt)

    ins("return {")
    for name, code in sorted(list(canonical_name_to_code.items())):
        ins('\t["%s"] = "%s",' % (name, code))
    ins("}")
    return "\n".join(text), "update [[Module:etymology languages/canonical names]]"


blib.do_edit(
    args,
    2,
    "Module:etymology languages/canonical names",
    do_canonical_names,
)
