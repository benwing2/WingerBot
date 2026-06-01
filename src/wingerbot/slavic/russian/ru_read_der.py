#!/usr/bin/env python3

import pywikibot, re, sys, argparse, json

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, site, tname, pname


def process_text_on_page(p):
    notes = []

    def process_line(line, aspect, output):
        if not line.startswith("* "):
            p.msg("WARNING: Unrecognized term line, doesn't start with '* ': %s" % line)
            return False
        line = line[2:]
        if line == "(no equivalent)":
            output.append("-")
            return True
        if line == "(various)":
            p.msg("WARNING: Saw '(various)', treating like '(no equivalent)': %s" % line)
            output.append("-")
            return True
        terms = re.split(", *", line)
        processed_terms = []
        for term in terms:
            if " " in term:
                words = term.split(" ")
                if re.search(r"\{\{l(-self)?\|", words[0]):
                    term = words[0]
                    notes = " ".join(words[1:])
                elif re.search(r"\{\{l(-self)?\|", words[-1]):
                    term = words[-1]
                    notes = " ".join(words[:-1])
                else:
                    p.msg("WARNING: Can't find {{l|...}} template: %s" % term)
                    return False
            else:
                notes = ""
            if notes:
                m = re.search(r"^\{\{[qi]\|(.*)\}\}$", notes)
                if not m:
                    p.msg("WARNING: Unrecognized format for notes: %s" % notes)
                    return False
                notes = "<q:%s>" % m.group(1)
            brackets = False
            m = re.search(r"^\[(.*)\]$", term)
            if m:
                brackets = True
                term = m.group(1)
            if not re.search(r"^\{\{l(-self)?\|.*\}\}$", term):
                p.msg("WARNING: Term isn't just {{l|...}}: %s" % term)
                return False
            wordts = list(blib.parse_text(term).filter_templates())
            if len(wordts) != 1:
                p.msg("WARNING: Not exactly one template in term: %s" % term)
                return False
            wordt = wordts[0]
            if tname(wordt) not in ["l", "l-self"]:
                p.msg("WARNING: Unrecognized template: %s" % term)
                return False
            for param in wordt.params:
                pn = pname(param)
                if pn not in ["1", "2", "g", "g2"]:
                    p.msg("WARNING: Unrecognized param %s=%s in template: %s" % (pn, str(param.value), term))
                    return False
            if getparam(wordt, "1") != "ru":
                p.msg("WARNING: Wrong language for term template: %s" % term)
                return False
            genders = blib.fetch_param_chain(wordt, "g")
            if genders and genders != [aspect]:
                notes += "<g:%s>" % ",".join(genders)
            term = getparam(wordt, "2")
            processed_term = term
            if brackets:
                processed_term = "[%s]" % processed_term
            processed_term += notes
            processed_terms.append(processed_term)
        output.append(",".join(processed_terms))
        return True

    lines = p.text.split("\n")
    aspect = None
    pfs = []
    impfs = []
    saw_error = False
    preceding = False
    header = None
    for line in lines:
        m = re.search("^==+(.*?)==+$", line)
        if m:
            header = m.group(1)
            continue
        if line == "''imperfective''":
            if header == "Conjugation":
                continue
            if header != "Derived terms":
                p.msg("WARNING: Apparent derived-terms table in header '%s' rather than 'Derived terms'" % header)
            aspect = "impf"
            continue
        elif line == "''perfective''":
            if header == "Conjugation":
                continue
            if header != "Derived terms":
                p.msg("WARNING: Apparent derived-terms table in header '%s' rather than 'Derived terms'" % header)
            aspect = "pf"
            continue
        elif aspect and line in ["{{mid2}}", "{{der-mid}}"]:
            aspect = None
        elif aspect and line in ["{{bottom2}}", "{{bottom}}", "{{der-bottom}}"]:
            aspect = None
            if not saw_error:
                if len(pfs) != len(impfs):
                    p.msg("WARNING: Saw %s imperfective(s) but %s perfective(s)" % (len(impfs), len(pfs)))
                else:
                    if preceding:
                        p.msg("----")
                    else:
                        p.msg("--------- begin text -----------")
                    for pf, impf in zip(pfs, impfs):
                        p.msg("%s %s" % (pf.replace(" ", "_"), impf.replace(" ", "_")))
                    preceding = True
            pfs = []
            impfs = []
        if aspect:
            ok = process_line(line, aspect, pfs if aspect == "pf" else impfs)
            if not ok:
                saw_error = True
    if preceding:
        p.msg("--------- end text -----------")
    else:
        if not p.title.startswith("-"):
            hyphen_pagetitle = "-" + p.title
            hyphen_page = pywikibot.Page(site, hyphen_pagetitle)
            hyphen_text = blib.safe_page_text(hyphen_page, p.errandmsg)
            if hyphen_text:
                process_text_on_page(blib.ProcessPageParams(args, p.index, hyphen_pagetitle, hyphen_text, None))
            else:
                p.msg("WARNING: Couldn't find derived terms on page")


parser = blib.create_argparser(
    "Read derived terms from Russian term and convert to input format for infer_ru_derverb_prefixes.py",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, new=True)
