#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import tname


def process_text_on_page(p):
    modsec = blib.find_modifiable_lang_section(p.text, "Icelandic", p.msg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, p.msg)
    subsections = subsecs.subsections

    defns = None
    headt = None
    for k, header in subsecs.header_list:
        if header in ["Noun", "Proper noun"]:
            parsed = blib.parse_text(subsections[k])
            for t in parsed.filter_templates():
                origt = str(t)
                tn = tname(t)
                if tn in ["is-noun/old", "is-proper noun/old"]:
                    if headt is not None:
                        p.msg("WARNING: Saw two headwords %s and %s" % (str(headt), str(t)))
                    headt = t
                    headt_genders = ",".join(blib.fetch_param_chain(headt, ["1", "g", "gen"], "g")) or "?"
                    headt_pls = blib.fetch_param_chain(headt, ["3", "pl"], "pl")
                    defns = blib.find_defns(subsections[k], "is")
                    if tn == "is-proper noun/old":
                        new_decl = "{{is-ndecl|%s}}" % headt_genders
                    elif p.title[0].isupper():
                        new_decl = "{{is-ndecl|%s.dem}}" % headt_genders
                    elif headt_pls == ["-"]:
                        new_decl = "{{is-ndecl|%s.sg}}" % headt_genders
                    else:
                        new_decl = "{{is-ndecl|%s}}" % headt_genders
                    p.msg("<begin> %s <end> <begin> %s <end> defn: %s" % (new_decl, origt, ";".join(defns)))


parser = blib.create_argparser(
    "Find Icelandic nouns needing declension and output headword, suggested declension and definition",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:is-noun/old", "Template:is-proper noun/old"],
)
