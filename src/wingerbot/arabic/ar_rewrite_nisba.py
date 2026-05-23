#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, addparam, msg, errandmsg


def rewrite_one_page_ar_nisba(index, page):
    pagetitle = str(page.title())

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)
    for template in parsed.filter_templates():
        if template.name == "ar-nisba":
            if template.has("head") and not template.has(1):
                head = str(template.get("head").value)
                template.remove("head")
                addparam(template, "1", head, before=template.params[0].name if len(template.params) > 0 else None)
            if template.has("plhead"):
                pagemsg("has plhead=")
    return str(parsed), "ar-nisba: head= -> 1="


def rewrite_ar_nisba(save, verbose, start, end):
    for index, page in blib.references("Template:ar-nisba", start, end):
        blib.do_edit(index, page, rewrite_one_page_ar_nisba, save=save, verbose=verbose)


parser = blib.create_argparser("Rewrite ar-nisba, changing head= to 1=")
params = parser.parse_args()
start, end = blib.parse_start_end(params.start, params.end)

rewrite_ar_nisba(params.save, params.verbose, start, end)
