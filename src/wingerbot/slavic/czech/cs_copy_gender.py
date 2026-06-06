#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, tname


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    headword_template = None
    decl_template = None
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["cs-ndecl"]:
            if decl_template:
                p.msg(
                    "WARNING: Multiple cs-ndecl templates %s and %s without intervening headword template, skipping"
                    % (str(decl_template), str(t))
                )
                return
            decl_template = t
            arg1 = getparam(t, "1")
            if arg1.startswith("m.an"):
                gender = "m-an"
            elif arg1.startswith("m"):
                if ".an" in arg1:
                    p.msg("WARNING: Misplaced animacy spec: %s" % str(t))
                    return
                gender = "m-in"
            elif arg1.startswith("f"):
                gender = "f"
            elif arg1.startswith("n"):
                gender = "n"
            else:
                p.msg("WARNING: Unable to extract gender from noun declension, skipping: %s" % str(t))
                return
            if ".pl" in arg1:
                gender += "-p"
            if headword_template is None:
                p.msg("WARNING: Saw declension template %s without preceding headword template: %s" % str(t))
                return
            headword_genders = blib.fetch_param_chain(headword_template, "1", "g")
            check_gender = True
            if gender in ["m-an", "m-in"]:
                if headword_genders == ["m"]:
                    headword_template.add("1", gender)
                    notes.append("copy Czech declension gender %s to headword" % gender)
                    check_gender = False
            if check_gender:
                if headword_genders != [gender]:
                    p.msg(
                        "WARNING: Headword gender(s) %s disagree with declension gender %s, skipping: %s"
                        % (",".join(headword_genders), gender, str(t))
                    )
                    return
            headword_template = None
        if tn in ["cs-noun", "cs-proper noun"]:
            if headword_template:
                p.msg("WARNING: Multiple cs-noun or cs-proper noun templates, skipping")
                return
            headword_template = t
            decl_template = None

    return str(parsed), notes


parser = blib.create_argparser(
    "Copy masculine genders from Czech declension template to headword template",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
