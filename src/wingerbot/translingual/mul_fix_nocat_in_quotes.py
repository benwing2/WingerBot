#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if blib.page_should_be_ignored(pagetitle):
        pagemsg("Skipping ignored page")
        return

    def hack_templates(parsed, subsectitle):
        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in blib.quote_templates:
                if not getparam(t, "nocat"):
                    continue
                if getparam(t, "lang").strip() != "en":
                    continue
                notes.append("convert nocat=1 in lang=en Translingual section to termlang=mul")
                # Fetch all params.
                params = []
                for param in t.params:
                    pname = str(param.name)
                    if pname.strip() != "nocat":
                        params.append((pname, param.value, param.showkey))
                # Erase all params.
                del t.params[:]
                # Put lang and termlang parameters.
                newline = "\n" if "\n" in str(t.name) else ""  # not tname() as we want to check for spaces
                t.add("lang", "en" + newline, preserve_spacing=False)
                t.add("termlang", "mul" + newline, preserve_spacing=False)
                # Put remaining parameters in order.
                for name, value, showkey in params:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
                pagemsg("Replaced <%s> with <%s>" % (origt, str(t)))

    pagemsg("Processing")

    notes = []

    secs = blib.split_text_into_sections(text, pagemsg)
    sections = secs.sections
    for j, langname in secs.lang_list:
        if langname != "Translingual":
            continue
        subsecs = blib.split_text_into_subsections(sections[j], pagemsg)
        subsections = subsecs.subsections
        for k, subsectitle in subsecs.header_list:
            parsed = blib.parse_text(subsections[k])
            hack_templates(parsed, subsectitle)
            subsections[k] = str(parsed)
        sections[j] = "".join(subsections)

    newtext = "".join(sections)
    return newtext, notes


parser = blib.create_argparser(
    "Convert nocat=1 in Translingual quote-* templates to termlang=en", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, edit=True, stdin=True, default_cats=["Quotations using nocat parameter"]
)
