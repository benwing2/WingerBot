#!/usr/bin/env python3

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import site


def process_text_on_page(p):
    seen_trans = [p.title]
    modsec = blib.find_modifiable_lang_section(p.text, "English", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    if "Translations" in subsecs.subsections_by_header:
        for k in subsecs.subsections_by_header["Translations"]:
            expanded = p.expand_text(subsecs.subsections[k])
            if expanded:
                for m in re.finditer(
                    r'<span class="[A-Z].*?" lang=".*?">\[\[([^\[\]\|]*)\|([^\[\]\|]*)\]\]</span>', expanded
                ):
                    trans = re.sub("^:", "", re.sub("#.*", "", m.group(1)))
                    if trans and trans not in seen_trans:
                        seen_trans.append(trans)

        def check_trans(trans):
            def pagemsg_with_trans(txt):
                p.msg("%s: %s" % (trans, txt))
            def errandpagemsg_with_trans(txt):
                p.errandmsg("%s: %s" % (trans, txt))

            trans_page = pywikibot.Page(site, trans)
            trans_text = blib.safe_page_text(trans_page, errandpagemsg_with_trans)
            if trans_text:
                m = re.search(r"\A#redirect\s*\[\[(.*?)\]\]", trans_text, re.I)
                if m:
                    redirect_target = m.group(1)
                    pagemsg_with_trans("Found existing translation (redirect) for %s" % p.title)
                    check_trans(redirect_target)
                else:
                    pagemsg_with_trans("Found existing translation for %s" % p.title)

        for trans in seen_trans:
            check_trans(trans)


parser = blib.create_argparser("Find page-existing translations for terms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
