#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, site, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(text, None if args.partial_page else "Portuguese", pagemsg)
    if modsec is None:
        return

    subsecs = blib.split_text_into_subsections(modsec.secbody, pagemsg)
    subsections = subsecs.subsections
    for k, header in subsecs.subsection_headers:
        if header not in ["Verb", "Participle"]:
            continue
        parsed = blib.parse_text(subsections[k])
        must_continue = False
        headt = None
        form_of_t = None
        for t in parsed.filter_templates():
            def getp(param):
                return getparam(t, param)

            origt = str(t)
            tn = tname(t)
            if tn == "head":
                if getp("1") != "pt":
                    pagemsg("WARNING: Wrong language in {{head}}: %s" % origt)
                    must_continue = True
                    break
                if headt:
                    pagemsg("WARNING: Saw two head templates in section: %s and %s" % (str(headt), origt))
                    must_continue = True
                    break
                headt = t
            elif tn == "pt-verb form of":
                if form_of_t:
                    pagemsg(
                        "WARNING: Saw two {{pt-verb form of}} templates in section: %s and %s" % (str(form_of_t), origt)
                    )
                    must_continue = True
                    break
                form_of_t = t
                if headt is None:
                    pagemsg("WARNING: Saw {{pt-verb form of}} template without {{head|pt|...}} in section: %s" % origt)
                    must_continue = True
                    break

                lemma = re.sub("<.*?>$", "", getp("1"))
                if lemma.endswith("ar"):
                    stem = lemma[:-1] + "d"
                elif re.search("[eií]r$", lemma):
                    stem = lemma[:-2]
                    if re.search("[aeiou]$", stem) and not re.search("[gq]u$", stem):
                        stem += "íd"
                    else:
                        stem += "id"
                elif re.search("[oô]r$", lemma):
                    stem = lemma[:-2] + "ost"
                else:
                    pagemsg("WARNING: Unrecognized lemma: %s" % lemma)
                    must_continue = True
                    break
                pp = stem + "o"
                if pagetitle == pp:
                    del headt.params[:]
                    blib.set_template_name(headt, "pt-pp")
                    del t.params[:]
                    blib.set_template_name(t, "past participle of")
                    t.add("1", "pt")
                    t.add("2", lemma)
                    subsections[k - 1] = subsections[k - 1].replace("Verb", "Participle")
                    notes.append("convert verb form for Portuguese lemma '%s' to past participle" % lemma)
                elif re.search("(a|os|as)$", pagetitle):
                    pp_lemma = re.sub("[ao]s?$", "", pagetitle) + "o"
                    if pp_lemma != pp:
                        pagemsg(
                            "WARNING: For verb infinitive %s, expected past participle lemma %s but saw %s, not same; skipping"
                            % (lemma, pp, pp_lemma)
                        )
                        continue
                    newtn, newg = (
                        ("feminine singular of", "f-s")
                        if pagetitle.endswith("a")
                        else (
                            ("masculine plural of", "m-p")
                            if pagetitle.endswith("os")
                            else ("feminine plural of", "f-p") if pagetitle.endswith("as") else (None, None)
                        )
                    )
                    if newtn is None:
                        raise RuntimeError(
                            "Internal error: Something wrong, can't identify gender/number of page title '%s'"
                            % pagetitle
                        )
                    del t.params[:]
                    blib.set_template_name(t, newtn)
                    t.add("1", "pt")
                    t.add("2", pp_lemma)
                    headt.add("2", "past participle form")
                    headt.add("g", newg)
                    subsections[k - 1] = subsections[k - 1].replace("Verb", "Participle")
                    notes.append(
                        "convert verb form for Portuguese lemma '%s' to past participle form for past participle '%s'"
                        % (lemma, pp_lemma)
                    )
                else:
                    pagemsg("WARNING: Can't identify non-lemma form as past participle (form) of lemma '%s'" % lemma)
            elif tn not in [
                "pt-pp",
                "past participle of",
                "feminine singular of",
                "masculine plural of",
                "feminine plural of",
                "C",
                "top",
                "topic",
                "topics",
                "c",
                "catlangcode",
                "cln",
                "catlangname",
            ]:
                pagemsg("WARNING: Unrecognized template %s, skipping" % origt)
                must_continue = True
        if must_continue:
            continue
        subsections[k] = str(parsed)

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Fix Portuguese verb form headers that should be past participle forms", include_pagefile=True, include_stdin=True
)
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Portuguese verb forms"]
)
