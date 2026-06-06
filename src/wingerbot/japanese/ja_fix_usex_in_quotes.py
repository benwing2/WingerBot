#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname

quote_templates = [
    "quote-book",
    "quote-hansard",
    "quote-journal",
    "quote-news",
    "quote-newsgroup",
    "quote-song",
    "quote-us-patent",
    "quote-video",
    "quote-web",
    "quote-wikipedia",
]

quote_templates_text_param_6 = ["quote-book", "quote-newsgroup", "quote-song", "quote-us-patent", "quote-web"]
quote_templates_text_param_7 = ["quote-journal", "quote-news", "quote-video"]
quote_templates_text_param_8 = ["quote-hansard"]


def process_text_on_page(p):
    p.msg("Processing")
    newtext = p.text
    parsed = blib.parse_text(p.text)

    notes = []
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        # p.msg("tn=%s" % str(tn))
        if tn in quote_templates:
            text_param = None
            if tn in quote_templates_text_param_6:
                text_param = "6"
            elif tn in quote_templates_text_param_7:
                text_param = "7"
            elif tn in quote_templates_text_param_8:
                text_param = "8"
            textval = ""
            if text_param:
                textval = getparam(t, text_param)
            if not textval:
                text_param = "text"
                textval = getparam(t, text_param)
            if not textval:
                text_param = "passage"
                textval = getparam(t, text_param)
            # p.msg("%s=%s" % (text_param, textval))
            textval = textval.strip()
            if re.search(r"^\{\{ja-usex\|.*\}\}$", textval, re.S):
                rmparam(t, text_param)
                newnewtext = re.sub(r"(\n#+\*) *%s" % re.escape(origt), r"\1 %s\1: %s" % (str(t), textval), newtext)
                if newtext == newnewtext:
                    p.msg("WARNING: Can't find quote template in p.text: %s" % origt)
                else:
                    newtext = newnewtext
                    notes.append("move ja-usex call outside of %s call" % tn)
            elif "{{ja-usex|" in textval:
                p.msg("WARNING: Found {{ja-usex| embedded in quote text but not whole param: %s" % origt)

    return newtext, notes


parser = blib.create_argparser("Move ja-usex calls outside of quote-*")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:ja-usex"]
)
