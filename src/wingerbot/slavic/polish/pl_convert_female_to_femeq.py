#!/usr/bin/env python3

import pywikibot, re, sys, argparse, json, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, errandmsg, site


def split_line(line):
    line = re.sub(r"\.$", "", line)
    line = re.sub(r"\betc$", "etc.", line)
    m = re.search(r"^(#+\s*)(\{\{(?:lb|label)\|[^{}]*\}\}\s*)(.*)$", line)
    if m:
        beginning, labeltext, rest_with_gloss = m.groups()
    else:
        m = re.search(r"^(#+\s*)(.*)$", line)
        assert m
        beginning, rest_with_gloss = m.groups()
        labeltext = ""
    rest_with_gloss = re.sub(r"^[Aa]\s+", "", rest_with_gloss)
    m = re.search(r"^(.*?)\s*(\{\{(?:gl|gloss)\|.*\}\})$", rest_with_gloss)
    if m:
        rest, gloss = m.groups()
    else:
        rest = rest_with_gloss
        gloss = ""
    gloss = re.sub(r"\s*\{\{(?:gl|gloss)\|female( person)?\}\}\s*", "", gloss)
    return beginning, labeltext, rest, gloss, line


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(text, "Polish", pagemsg, force_final_nls=True)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        parsed = blib.parse_text(subsections[k])

        # First do 'female'
        ms = None
        headt = None
        headt_other_gender = None
        headt_head = None
        for t in parsed.filter_templates():
            tn = tname(t)
            origt = str(t)

            def getp(param):
                return getparam(t, param)

            if tn in ["pl-noun"] or tn == "head" and getp("1") == "pl" and getp("2") == "noun":
                other_head = headt or headt_other_gender or headt_head
                if other_head:
                    pagemsg(
                        "WARNING: Saw two head templates %s and %s in subsection %s" % (str(other_head), str(t), k // 2)
                    )
                    return
                if tn == "head":
                    headt_head = t
                elif getp("1") == "f" or getp("g") == "f":
                    headt = t
                    ms = blib.fetch_param_chain(t, "m")
                else:
                    headt_other_gender = t
        lines = subsections[k].split("\n")
        for i, line in enumerate(lines):
            line = line.strip()
            if re.search("^#[:*]", line):
                continue
            if args.warn_on_woman and "woman" in line:
                pagemsg("WARNING: Saw line with 'woman' in it: headt=%s, line=%s" % (str(headt), line))
                continue
            if (
                line.startswith("#")
                and re.search(r"\bfemale\b", line)
                and not re.search(r"\b(given name|surname|female equivalent|femeq)\b", line)
            ):
                if not headt:
                    if headt_other_gender:
                        pagemsg(
                            "WARNING: Saw female line with {{pl-noun}} with other gender: headt=%s, line=%s"
                            % (str(headt_other_gender), line)
                        )
                        continue
                    if headt_head:
                        pagemsg(
                            "WARNING: Saw female line with {{head|pl|noun}}: headt=%s, line=%s"
                            % (str(headt_head), line)
                        )
                        continue
                    pagemsg("WARNING: Saw female line without {{pl-noun}}: line=%s" % line)
                    continue
                if not ms:
                    pagemsg("WARNING: Saw female line without m=: headt=%s, line=%s" % (str(headt), line))
                    continue
                beginning, labeltext, rest, gloss, line = split_line(line)
                rest = re.sub(r"\[\[female\]\]\s+", "", rest)
                rest = re.sub(r"female\s+", "", rest)
                if "female" in rest:
                    pagemsg(
                        "WARNING: Saw rest '%s' with 'female' after attempting to remove it, won't change: headt=%s, line=%s"
                        % (rest, str(headt), line)
                    )
                    continue
                if "woman" in rest:
                    pagemsg(
                        "WARNING: Saw rest '%s' with 'woman' after removing 'female', won't change: headt=%s, line=%s"
                        % (rest, str(headt), line)
                    )
                    continue
                if "{{" in rest or "}}" in rest:
                    pagemsg(
                        "WARNING: Saw template call in rest '%s', won't change: headt=%s, line=%s"
                        % (rest, str(headt), line)
                    )
                    continue
                newrest_parts = []
                for m in ms[:-1]:
                    newrest_parts.append("{{femeq|pl|%s}}" % m)
                newrest_parts.append("{{femeq|pl|%s|t=%s}}" % (ms[-1], rest))
                newrest = ", ".join(newrest_parts)
                if gloss:
                    gloss = " " + gloss
                newline = "%s%s%s%s" % (beginning, labeltext, newrest, gloss)
                pagemsg("Replacing <%s> with <%s>" % (line, newline))
                lines[i] = newline
        newsubseck = "\n".join(lines)
        if newsubseck != subsections[k]:
            subsections[k] = newsubseck
            notes.append("replace Polish 'female' defns with {{femeq}} for masculine(s) %s" % (",".join(ms)))

        # Then 'male'
        fs = None
        headt = None
        headt_animate = None
        headt_other_gender = None
        headt_head = None
        for t in parsed.filter_templates():
            tn = tname(t)
            origt = str(t)

            def getp(param):
                return getparam(t, param)

            if tn in ["pl-noun"] or tn == "head" and getp("1") == "pl" and getp("2") == "noun":
                other_head = headt or headt_animate or headt_other_gender
                if other_head:
                    pagemsg(
                        "WARNING: Internal error: Saw two head templates %s and %s in subsection %s"
                        % (str(other_head), str(t), k // 2)
                    )
                    return
                if tn == "head":
                    headt_head = t
                elif getp("1") == "m-pr" or getp("g") == "m-pr":
                    headt = t
                    fs = blib.fetch_param_chain(t, "f")
                elif getp("1") == "m-an" or getp("g") == "m-an":
                    headt_animate = t
                else:
                    headt_other_gender = t
        lines = subsections[k].split("\n")
        for i, line in enumerate(lines):
            line = line.strip()
            if re.search("^#[:*]", line):
                continue
            if (
                line.startswith("#")
                and re.search(r"\bmale\b", line)
                and not re.search(r"\b(given name|surname)\b", line)
            ):
                if not headt:
                    if headt_animate:
                        pagemsg(
                            "WARNING: Saw male line with {{pl-noun|m-an}}: headt=%s, line=%s"
                            % (str(headt_animate), line)
                        )
                        continue
                    if headt_other_gender:
                        pagemsg(
                            "WARNING: Saw male line with {{pl-noun}} with other gender: headt=%s, line=%s"
                            % (str(headt_other_gender), line)
                        )
                        continue
                    if headt_head:
                        pagemsg(
                            "WARNING: Saw male line with {{head|pl|noun}}: headt=%s, line=%s" % (str(headt_head), line)
                        )
                        continue
                    pagemsg("WARNING: Saw male line without {{pl-noun}}: line=%s" % line)
                    continue
                if not fs:
                    pagemsg("WARNING: Saw male line without f= (will continue): headt=%s, line=%s" % (str(headt), line))
                beginning, labeltext, rest, gloss, line = split_line(line)
                rest = re.sub(r"\[\[male\]\]\s+", "", rest)
                rest = re.sub(r"male\s+", "", rest)
                if "male" in rest:
                    pagemsg(
                        "WARNING: Saw rest '%s' with 'male' after attempting to remove it, won't change: headt=%s, line=%s"
                        % (rest, str(headt), line)
                    )
                    continue
                if gloss:
                    gloss = " " + gloss
                newline = "%s%s%s%s" % (beginning, labeltext, rest, gloss)
                if newline != lines[i]:
                    pagemsg("Replacing <%s> with <%s>" % (line, newline))
                    lines[i] = newline
        newsubseck = "\n".join(lines)
        if newsubseck != subsections[k]:
            subsections[k] = newsubseck
            notes.append("remove 'male' from Polish defns%s" % (", feminine(s) %s" % ",".join(fs) if fs else ""))

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Convert raw Polish 'female' defns into {{femeq}} and remove 'male' from defns",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--warn-on-woman", action="store_true", help="Warn if 'woman' seen in line.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Polish lemmas"]
)
