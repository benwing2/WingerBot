#!/usr/bin/env python3

# Fix up short adjective forms when possible, canonicalizing existing
# 'inflection of' and converting raw inflection to 'inflection of'

# FIXME:
#
# 1. When swapping participles with nouns/adjectives, don't do it for
#    adverbial participles

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text, nowarn=False):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    notes = []

    found_participle = False

    modsec = blib.find_modifiable_lang_section(text, "Russian", pagemsg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        found_subsec_participle = False
        # Try to canonicalize existing 'inflection of'
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            gloss3 = True
            tn = tname(t)
            canon_params = None
            if tn == "ru-participle of":
                found_participle = True
                found_subsec_participle = True
            elif tn == "present active participle of" and getparam(t, "lang") == "ru":
                canon_params = ["pres", "act"]
            elif tn == "past active participle of" and getparam(t, "lang") == "ru":
                canon_params = ["past", "act"]
            elif tn == "present passive participle of" and getparam(t, "lang") == "ru":
                canon_params = ["pres", "pass"]
            elif tn == "past passive participle of" and getparam(t, "lang") == "ru":
                canon_params = ["past", "pass"]
            elif tn == "inflection of" and getparam(t, "lang") == "ru":
                gloss3 = False
                # Fetch the numbered params starting with 3
                numbered_params = []
                for i in range(3, 20):
                    numbered_params.append(getparam(t, str(i)))
                while len(numbered_params) > 0 and not numbered_params[-1]:
                    del numbered_params[-1]
                # Now canonicalize
                numparamstr = "/".join(numbered_params)
                canon_params = []
                while True:
                    m = re.search(
                        r"^(pres|past)(?:/(perfective|imperfective|pfv|impfv))?/(act|actv|pass|pasv|adverbial|adv)/(?:part|ptcp)$",
                        numparamstr,
                    )
                    if m:
                        canon_params = [m.group(1)]
                        if m.group(2):
                            canon_params.append(
                                {"perfective": "pfv", "imperfective": "impfv", "pfv": "pfv", "impfv": "impfv"}[
                                    m.group(2)
                                ]
                            )
                        canon_params.append(
                            {
                                "act": "act",
                                "actv": "act",
                                "pass": "pass",
                                "pasv": "pass",
                                "adverbial": "adv",
                                "adv": "adv",
                            }[m.group(3)]
                        )
                        break
                    break
            if canon_params:
                found_participle = True
                found_subsec_participle = True
                origt = str(t)
                origtn = tname(t)
                t.name = "ru-participle of"
                # Fetch param 1 and param 2, and non-numbered params except lang=
                # and nocat=.
                param1 = getparam(t, "1")
                param2 = getparam(t, "2")
                non_numbered_params = []
                for param in t.params:
                    pname = str(param.name)
                    if not re.search(r"^[0-9]+$", pname) and pname not in ["lang", "nocat"]:
                        non_numbered_params.append((pname, param.value))
                # Convert 3rd parameter to gloss= if called for
                if gloss3:
                    gloss = getparam(t, "3")
                    if gloss:
                        non_numbered_params.append(("gloss", gloss))
                # Erase all params.
                del t.params[:]
                # Put back param 1 and param 2, then the replacements for the
                # higher params, then the non-numbered params.
                t.add("1", param1)
                t.add("2", param2)
                for i, param in enumerate(canon_params):
                    t.add(str(i + 3), param)
                for name, value in non_numbered_params:
                    t.add(name, value)
                newt = str(t)
                pagemsg("Replaced %s with %s" % (origt, newt))
                notes.append("replaced '%s' with 'ru-participle of/%s'" % (origtn, "/".join(canon_params)))
        if found_subsec_participle:
            if header == "Verb":
                origsubsec = subsections[k - 1]
                subsections[k - 1] = re.sub("Verb", "Participle", subsections[k - 1])
                pagemsg(
                    "Replaced %s with %s" % (origsubsec.replace("\n", r"\n"), subsections[k - 1].replace("\n", r"\n"))
                )
                notes.append("set section header to Participle")
            for t in parsed.filter_templates():
                if tname(t) == "head" and getparam(t, "1") == "ru":
                    origt = str(t)
                    t.add("2", "participle")
                    newt = str(t)
                    if origt != newt:
                        pagemsg("Replaced %s with %s" % (origt, newt))
                        notes.append("set headword part of speech to 'participle'")
        subsections[k] = str(parsed)
    secbody = "".join(subsections)

    # Rearrange Participle and Noun/Adjective sections; repeat until no change, in case we have
    # both Noun and Adjective sections before the Participle.
    while True:
        rearranged = False
        l3secs = blib.split_text_into_subsections(secbody, pagemsg, only_level=3)
        l3sections = l3secs.subsections
        l3section_headers = l3secs.header_list
        for k, header in l3section_headers:
            if (
                header in ["Noun", "Adjective"]
                and k + 1 < len(l3sections)
                and l3secs.headers[k + 1] == "Participle"
            ):
                tmp = l3sections[k - 1]
                l3sections[k - 1] = l3sections[k + 1]
                l3sections[k + 1] = tmp
                tmp = l3sections[k]
                l3sections[k] = l3sections[k + 2]
                l3sections[k + 2] = tmp
                rearranged = True
                pagemsg(
                    "Swapped %s with %s"
                    % (l3sections[k + 1].replace("\n", r"\n"), l3sections[k - 1].replace("\n", r"\n"))
                )
                notes.append("swap Participle section with Noun/Adjective")
        secbody = "".join(l3sections)
        if not rearranged:
            break
    new_text = modsec.rebuild(secbody=secbody)

    if "Etymology 1" in new_text:
        pagemsg("WARNING: Multiple etymology sections, might need to manually fix up")

    new_new_text = re.sub(r"\[\[Category:Russian [a-z ]*participles]]", "", new_text)
    if new_text != new_new_text:
        pagemsg("Removed manual participle categories")
        notes.append("remove manual participle categories")
        new_text = new_new_text

    if not notes and not found_participle and not nowarn:
        pagemsg("WARNING: No participles found")

    new_new_text = re.sub(r"\n\n\n+", "\n\n", new_text)
    if new_new_text != new_text:
        notes.append("convert 3+ newlines to 2 newlines")
        new_text = new_new_text

    return new_text, notes


parser = blib.create_argparser(
    "Canonicalize various participle definition lines and fix headword and section header",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

# FIXME! Won't quite work with --pagefile or --pages; will do them twice.
blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    edit=True,
    stdin=True,
    default_cats=[
        "Russian participles",
        "Russian present active participles",
        "Russian present passive participles",
        "Russian past active participles",
        "Russian past passive participles",
    ],
)


def process_text_on_page_nowarn(index, pagetitle, text):
    return process_text_on_page(index, pagetitle, text, nowarn=True)


blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page_nowarn, edit=True, stdin=True, default_cats=["Russian non-lemma forms"]
)
