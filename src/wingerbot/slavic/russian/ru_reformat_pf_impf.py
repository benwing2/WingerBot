#!/usr/bin/env python3

# Reformat corresponding (im)perfective specs using {{pf}} or {{impf}}

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import msg, errandmsg


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))
    def errpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    modsec = blib.find_modifiable_lang_section(text, "Russian", pagemsg)
    if modsec is None:
        return
    secbody = modsec.secbody
    # Try to convert multi-line usex using #:
    def generate_new_format_corverb(m):
        pfimpf = m.group(1)
        verbtext = m.group(2)
        verbs = re.split(" *(?:,|or) *", verbtext)
        newverbs = []
        for index, verb in enumerate(verbs):
            qual = ""
            if "only" in verb:
                verb = re.sub(" *only *", "", verb)
                qual = "only"
            if "also" in verb:
                verb = re.sub(" *also *", "", verb)
                qual = "also"
            if "{{i|low colloquial}} " in verb:
                verb = re.sub(r" *\{\{i\|low colloquial\}\} *", "", verb)
                qual = "low colloquial"
            if qual:
                qual = "|q%s=%s" % (index + 1, qual)
            m = re.search(r"^\[\[(.*)\]\]$", verb)
            if m:
                newverbs.append(m.group(1) + qual)
                continue
            m = re.search(r"^\{\{[ml]\|ru\|(.*)\}\}$", verb)
            if m:
                newverbs.append(m.group(1) + qual)
                continue
            pagemsg("WARNING: Unable to parse verb spec %s, treating as raw" % verb)
            newverbs.append(verb + qual)
        return "\n#: {{%s|ru|%s}}\n" % (pfimpf, "|".join(newverbs))

    secbody = re.sub(r", *\{\{g\|(pf|impf)\}\} *[-–—:] * (.*)\n", generate_new_format_corverb, secbody)
    # Repeatedly move {{pf}}/{{impf}} after usexes
    while True:
        replacement = re.sub(
            r"\n(#: \{\{(?:pf|impf)\|.*?\}\}.*\n)(#\*?: \{\{ux.*?\}\}.*\n)", r"\n\2\1", secbody
        )
        if replacement == secbody:
            break
        secbody = replacement
    if "{{g|pf}}" in secbody or "{{g|impf}}" in secbody:
        errpagemsg("WARNING: Found unconverted {{g|pf}} or {{g|impf}}")
    if " pf" in secbody or " impf" in secbody:
        errpagemsg("WARNING: Found unconverted pf or impf following a space")

    return modsec.rebuild(secbody=secbody), "Reformat Russian perfective/imperfective correspondences to use {{pf}}/{{impf}}"


parser = blib.create_argparser(
    "Reformat corresponding (im)perfective specs using {{pf}} or {{impf}}", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Russian verbs"]
)
