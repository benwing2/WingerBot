#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Polish", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    # Add missing space between * and { in case of {{R:pl:WSJP}} or {{R:pl:PWN}} directly after * without space
    newsecbody = re.sub(r"^\*\{", "* {", secbody, 0, re.M)
    if newsecbody != secbody:
        notes.append("add missing space after bullet *")
        secbody = newsecbody

    # Remove trailing spaces to avoid issues with spaces after {{R:pl:WSJP}} or {{R:pl:PWN}}
    newsecbody = re.sub(" *\n", "\n", secbody)
    if newsecbody != secbody:
        notes.append("remove extraneous trailing spaces")
        secbody = newsecbody

    # See if there are definition lines that do not contain {{surname}}, {{given name}}, {{verbal noun of}},
    # {{inflection of}} and {{infl of}}.
    lines = secbody.split("\n")
    saw_good_defn_line = False
    bad_templates = ["surname", "given name", "verbal noun of", "inflection of", "infl of"]
    for line in lines:
        if line.startswith("#") and not re.search(r"\{\{(%s)\|pl[|}]" % "|".join(bad_templates), line):
            saw_good_defn_line = True
    if not saw_good_defn_line:
        saw_bad_templates = []
        for bad_template in bad_templates:
            if re.search(r"\{\{%s\|pl[|}]" % bad_template, secbody):
                saw_bad_templates.append(bad_template)
        if saw_bad_templates:
            p.msg(
                "Skipping page because saw no good definition lines, and saw %s"
                % (" and ".join("{{%s|pl}}" % bad_template for bad_template in saw_bad_templates))
            )
        else:
            p.msg(
                "WARNING: Skipping page because saw no good definition lines; didn't see any of %s"
                % (", ".join("{{%s|pl}}" % bad_template for bad_template in bad_templates))
            )
        return

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    # Check for templates in sections outside of 'Further reading'
    for k, header in subsecs.header_list:
        if header != "Further reading":
            if "{{R:pl:WSJP}}" in subsections[k] or "{{R:pl:PWN}}" in subsections[k]:
                if header == "References":
                    p.msg(
                        "WARNING: Saw {{R:pl:WSJP}} or {{R:pl:PWN}} in %s section, can't handle"
                        % header
                    )
                    return
                else:
                    p.msg(
                        "WARNING: Saw {{R:pl:WSJP}} or {{R:pl:PWN}} in %s section, need to review manually"
                        % header
                    )

    # Check for References or Further reading already present
    for k, header in subsecs.header_list:
        if header == "Further reading":
            if subsecs.levels[k] != 3:
                for l in range(k + 2, len(subsections), 2):
                    if subsecs.headers[l] != "Anagrams":
                        p.msg(
                            "WARNING: Saw level > 3 Further reading and a following non-Anagrams section %s, can't handle"
                            % subsecs.headers[l]
                        )
                        return
                newsubsecval = "===Further reading===\n"
                notes.append("replaced %s with level-3 %s" % (subsections[k - 1].strip(), newsubsecval.strip()))
                subsections[k - 1] = newsubsecval
            newsubsec = re.sub(
                r"^(\* \{\{R:pl:PWN\}\}\n)(.*)(\* \{\{R:pl:WSJP\}\}\n)", r"\3\1\2", subsections[k], 0, re.M | re.S
            )
            if newsubsec != subsections[k]:
                notes.append(
                    "standardize order of ===Further reading=== with {{R:pl:WSJP}} followed by {{R:pl:PWN}} followed by anything else"
                )
                subsections[k] = newsubsec
            else:
                has_wsjp = "{{R:pl:WSJP}}" in subsections[k]
                has_pwn = "{{R:pl:PWN}}" in subsections[k]
                if has_wsjp and not has_pwn:
                    newsubseck = subsections[k].replace("* {{R:pl:WSJP}}\n", "* {{R:pl:WSJP}}\n* {{R:pl:PWN}}\n")
                    if newsubseck == subsections[k]:
                        p.msg("WARNING: Unable to add {{R:pl:PWN}} after {{R:pl:WSJP}}")
                    else:
                        subsections[k] = newsubseck
                        notes.append("add {{R:pl:PWN}} to Polish lemma in ===Further reading===")
                elif has_pwn and not has_wsjp:
                    newsubseck = subsections[k].replace("* {{R:pl:PWN}}\n", "* {{R:pl:WSJP}}\n* {{R:pl:PWN}}\n")
                    if newsubseck == subsections[k]:
                        p.msg("WARNING: Unable to add {{R:pl:WSJP}} before {{R:pl:PWN}}")
                    else:
                        subsections[k] = newsubseck
                        notes.append("add {{R:pl:WSJP}} to Polish lemma in ===Further reading===")
                elif has_wsjp and has_pwn:
                    p.msg("Already has {{R:pl:WSJP}} and {{R:pl:PWN}}")
                else:
                    subsections[k] = "* {{R:pl:WSJP}}\n* {{R:pl:PWN}}\n" + subsections[k]
                    notes.append("add {{R:pl:WSJP}} and {{R:pl:PWN}} to Polish lemma in ===Further reading===")
            break
    else:  # no break
        k = len(subsections) - 1
        while k >= 2 and subsecs.headers[k] == "Anagrams":
            k -= 2
        if k < 2:
            p.msg("WARNING: No lemma or non-lemma section")
            return
        subsections[k + 1 : k + 1] = ["===Further reading===\n* {{R:pl:WSJP}}\n* {{R:pl:PWN}}\n\n"]
        notes.append("add new ===Further reading=== section to Polish lemma with {{R:pl:WSJP}} and {{R:pl:PWN}}")

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Add {{R:pl:WSJP}} and {{R:pl:PWN}} to Polish 'Further reading' sections", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Polish lemmas"]
)

blib.elapsed_time()
