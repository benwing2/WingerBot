#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname


def process_text_on_page(p):
    notes = []

    p.msg("Processing")

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "autocat":
            blib.set_template_name(t, "auto cat")
            notes.append("{{autocat}} -> {{auto cat}}")
        elif tn in ["ja-readingcat", "ryu-readingcat"]:
            m = re.search("^Category:(Japanese|Okinawan) terms spelled with (.*?) read as (.*)$", p.title)
            if not m:
                p.msg("WARNING: Can't parse page title")
                continue
            langname, kanji, reading = m.groups()
            if langname == "Japanese":
                auto_lang = "ja"
            else:
                auto_lang = "ryu"
            t_lang = re.sub("-.*", "", tn)
            if t_lang != auto_lang:
                p.msg(
                    "WARNING: Auto-determined lang code %s for language name %s != template specified %s: %s"
                    % (auto_lang, langname, t_lang, str(t))
                )
                continue
            t_kanji = getparam(t, "1").strip()
            t_reading = getparam(t, "2").strip()
            if t_kanji != kanji:
                p.msg("WARNING: Auto-determined kanji %s != template specified %s: %s" % (kanji, t_kanji, str(t)))
                continue
            if t_reading != reading:
                p.msg(
                    "WARNING: Auto-determined reading %s != template specified %s: %s" % (reading, t_reading, str(t))
                )
                continue
            numbered_params = []
            must_continue = False
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if pn in ["1", "2"]:
                    pass
                elif re.search("^[0-9]+$", pn):
                    numbered_params.append(pv)
                else:
                    p.msg("WARNING: Saw unknown non-numeric param %s=%s, skipping: %s" % (pn, pv, str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            if len(numbered_params) == 0:
                p.msg("WARNING: No reading types given, skipping: %s" % str(t))
                continue
            blib.set_template_name(t, "auto cat")
            del t.params[:]
            for index, numbered_param in enumerate(numbered_params):
                t.add(str(index + 1), numbered_param, preserve_spacing=False)
            notes.append("convert {{%s}} to {{auto cat}}" % tn)

        if str(t) != origt:
            p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{ja-readingcat}}/{{ryu-readingcat}} to {{auto cat}}"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:ja-readingcat", "Template:ryu-readingcat"],
)
