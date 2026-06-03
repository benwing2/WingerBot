#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, errandmsg, site


def process_text_on_page(p):
    props = pagetitle_to_props.get(p.title, None)
    if not props:
        p.msg("WARNING: Can't find properties for p.title")
        return
    respelling, orig_template, repl_template = props
    if respelling == "-":
        p.msg("Skipping line with respelling '-': %s" % line)
        return
    if respelling == "":
        p.msg("WARNING: Skipping blank respelling: %s" % line)
        return

    notes = []

    if orig_template not in p.text:
        p.msg("WARNING: Can't find original template %s in p.text" % orig_template)
        return

    m = re.search("^.*?%s.*$" % re.escape(orig_template), p.text, re.M)
    if not m:
        p.msg("WARNING: Couldn't find template %s in page text" % orig_template)
        textline = "(unknown)"
    else:
        textline = m.group(0)

    m = re.search(r"(\|pos=[a-z]+)", repl_template)
    if m:
        posarg = m.group(1)
    else:
        posarg = ""
    if respelling == "y":
        respellingarg = ""
    else:
        respellingarg = "|" + "|".join(respelling.split(","))
    real_repl = "{{fr-IPA%s%s}}" % (respellingarg, posarg)

    if "{{a|" in textline:
        p.msg("WARNING: Replacing %s with %s and saw accent spec on line: %s" % (orig_template, real_repl, textline))

    newtext, did_replace = blib.replace_in_text(p.text, orig_template, real_repl, p.msg)
    text = newtext
    if did_replace:
        notes.append("semi-manually replace %s with %s" % (orig_template, real_repl))
    if respelling != "y":
        parsed = blib.parse_text(text)
        saw_fr_conj_auto = False
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn == "fr-conj-auto":
                if saw_fr_conj_auto:
                    p.msg("WARNING: Saw {{fr-conj-auto}} twice, first=%s, second=%s" % (saw_fr_conj_auto, str(t)))
                saw_fr_conj_auto = str(t)
                if getparam(t, "pron"):
                    p.msg("WARNING: Already saw pron= param: %s" % str(t))
                    continue
                pronarg = ",".join(pron or p.title for pron in respelling.split(","))
                origt = str(t)
                t.add("pron", pronarg)
                p.msg("Replaced %s with %s" % (origt, str(t)))
                notes.append("add pron=%s to {{fr-conj-auto}}" % pronarg)
        text = str(parsed)

    return text, notes


parser = blib.create_argparser(
    "Push manual {{fr-IPA}} replacements for {{IPA|fr}}", include_pagefile=True, include_stdin=True
)
parser.add_argument("--direcfile", help="File of directives", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

pagetitle_to_props = {}

for index, line in blib.iter_items_from_file(args.direcfile, start, end):
    m = re.search(
        r"^(.*?)\|Page [0-9]+ (.*?): WARNING: Can't replace (\{\{IPA\|fr\|.*?\}\}) with (\{\{.*?\}\}) because auto-generated pron .*$",
        line,
    )
    if not m:
        errandmsg("Line %s: Unrecognized line: %s" % (index, line))
        continue
    respelling, page, orig_template, repl_template = m.groups()
    pagetitle_to_props[page] = (respelling, orig_template, repl_template)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_pages=list(pagetitle_to_props.keys())
)
