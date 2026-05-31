#!/usr/bin/env python3

# Move text outside of certain RQ: templates inside the templates.

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, set_template_name, msg, errmsg, site

replace_templates = ["RQ:RBrtn AntmyMlncly", "RQ:Flr Mntgn Essays"]


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    pagemsg("Processing")

    if ":" in pagetitle and not re.search("^(Citations|Appendix|Reconstruction|Transwiki|Wiktionary):", pagetitle):
        pagemsg("WARNING: Colon in page title and not a recognized namespace to include, skipping page")
        return

    notes = []

    newtext = text
    tn = "RQ:RBrtn AntmyMlncly"
    newtn = "RQ:Burton Melancholy"
    curtext = newtext

    def replace_rq_rbrtn(m):
        pagegroup = m.group(1)
        mm = re.search(r"^([IVXLCDM]+)\.([0-9]+)\.([0-9]+)\.([ivxlcdm]+)$", pagegroup)
        if mm:
            replace = "{{%s|part=%s|section=%s|member=%s|subsection=%s|passage=%s}}\n" % (
                newtn,
                mm.group(1),
                mm.group(2),
                mm.group(3),
                mm.group(4),
                m.group(2),
            )
            pagemsg(("Replacing %s with %s" % (m.group(0), replace)).replace("\n", r"\n"))
            return replace
        else:
            mm = re.search(r"^([IVXLCDM]+)\.([0-9]+)\.([0-9]+)$", pagegroup)
            if mm:
                replace = "{{%s|part=%s|section=%s|member=%s|passage=%s}}\n" % (
                    newtn,
                    mm.group(1),
                    mm.group(2),
                    mm.group(3),
                    m.group(2),
                )
                pagemsg(("Replacing %s with %s" % (m.group(0), replace)).replace("\n", r"\n"))
                return replace
            else:
                pagemsg("Unable to parse page group %s in\n<pre>\n%s</pre>" % (pagegroup, m.group(0)))
                return m.group(0)

    newtext = re.sub(r"\{\{%s\}\}, (.*?):\n#\*: (.*?)\n" % tn, replace_rq_rbrtn, curtext)
    if curtext != newtext:
        notes.append("reformat {{%s}}" % tn)
    tn = "RQ:Flr Mntgn Essays"
    newtn = "RQ:Florio Montaigne Essayes"
    curtext = newtext

    def replace_rq_flr(m):
        pagegroup = m.group(1)
        mm = re.search(r"^([IVXLCDM]+)\.([0-9]+)$", pagegroup)
        if mm:
            replace = "{{%s|chapter=%s|book=%s|passage=%s}}\n" % (newtn, mm.group(2), mm.group(1), m.group(2))
            pagemsg(("Replacing %s with %s" % (m.group(0), replace)).replace("\n", r"\n"))
            return replace
        else:
            pagemsg("Unable to parse page group %s in\n<pre>\n%s</pre>" % (pagegroup, m.group(0)))
            return m.group(0)

    newtext = re.sub(r"\{\{%s\}\}, (.*?):\n#\*: (.*?)\n" % tn, replace_rq_flr, curtext)
    if curtext != newtext:
        notes.append("reformat {{%s}}" % tn)
        pagemsg(("Replacing %s with %s" % (curtext, newtext)).replace("\n", r"\n"))
    return newtext, notes


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Fix title and entry in a couple reference templates", include_pagefile=True, include_stdin=True
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        edit=True,
        stdin=True,
        default_refs=["Template:%s" % template for template in replace_templates],
        # FIXME: formerly had includelinks=True on call to blib.references();
        # doesn't exist any more
    )
