#!/usr/bin/env python3

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, tname

borrowed_langs = {}

lang_data = lang_utils.get_lang_data()


def process_text_on_page(p):
    notes = []

    def hack_templates(parsed, langname, subsectitle, langnamecode=None, is_citation=False):
        if langname not in lang_data.languages_by_canonical_name:
            if not is_citation:
                langnamecode = None
        else:
            langnamecode = lang_data.languages_by_canonical_name[langname]["code"]

        for t in parsed.filter_templates():
            origt = str(t)
            tn = tname(t)
            if tn in ["citation", "citations"] and is_citation:
                langnamecode = getparam(t, "lang")
            elif tn in blib.quote_templates:
                if getparam(t, "lang"):
                    continue
                lang = getparam(t, "language")
                if lang:
                    notes.append("Convert language=%s to lang=%s in %s" % (lang, lang, tn))
                else:
                    if subsectitle.startswith("Etymology") or subsectitle.startswith("Pronunciation"):
                        p.msg(
                            "WARNING: Found template in %s section for language %s, might be different language, skipping: %s"
                            % (subsectitle, langname, origt)
                        )
                        continue
                    if not langnamecode:
                        p.msg("WARNING: Unrecognized language %s, unable to add language to %s" % (langname, tn))
                        continue
                    if langnamecode == "en" and (getparam(t, "translation") or getparam(t, "t")):
                        p.msg("WARNING: Translation section in putative English quote, skipping: %s" % origt)
                        continue
                    if langnamecode == "mul":
                        notes.append("infer lang=en for %s in Translingual section and add termlang=mul" % tn)
                    else:
                        notes.append("infer lang=%s for %s based on section it's in" % (langnamecode, tn))
                rmparam(t, "language")
                # Fetch all params.
                params = []
                for param in t.params:
                    pname = str(param.name)
                    params.append((pname, param.value, param.showkey))
                # Erase all params.
                del t.params[:]
                if langnamecode == "mul":
                    termlang = langnamecode
                    langnamecode = "en"
                else:
                    termlang = None
                # Put lang parameter.
                newline = "\n" if "\n" in str(t.name) else ""  # not tname() as we want to check for spaces
                t.add("lang", langnamecode + newline, preserve_spacing=False)
                if termlang:
                    t.add("termlang", termlang + newline, preserve_spacing=False)
                # Put remaining parameters in order.
                for name, value, showkey in params:
                    t.add(name, value, showkey=showkey, preserve_spacing=False)
                p.msg("Replaced <%s> with <%s>" % (origt, str(t)))

        return langnamecode

    p.msg("Processing")

    secs = blib.split_text_into_sections(p.text, p.msg)

    if not p.title.startswith("Citations"):
        for j, langname in secs.lang_list:
            subsecs = blib.split_text_into_subsections(secs.sections[j], p.msg)
            for k, header in subsecs.header_list:
                parsed = blib.parse_text(subsecs.subsections[k])
                hack_templates(parsed, langname, header)
                subsecs.subsections[k] = str(parsed)
            secs.sections[j] = "".join(subsecs.subsections)
    else:
        # Citation page
        langnamecode = None
        for j, langname in [(0, "Unknown")] + secs.lang_list:
            parsed = blib.parse_text(secs.sections[j])
            langnamecode = hack_templates(parsed, langname, "Unknown", langnamecode=langnamecode, is_citation=True)
            secs.sections[j] = str(parsed)

    newtext = "".join(secs.sections)
    return newtext, notes


parser = blib.create_argparser(
    "Add language to quote-* templates, based on the section it's within", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Undetermined terms with quotations", "Quotations with missing lang parameter"],
)
