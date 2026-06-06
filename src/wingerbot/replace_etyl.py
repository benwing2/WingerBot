#!/usr/bin/env python3

import re

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam

family_data = lang_utils.get_family_data()
etym_lang_data = lang_utils.get_etym_lang_data()

# Compile a map from etym language code to its first non-etym-language ancestor.
etym_language_to_parent = lang_utils.get_etym_language_to_parent()


def process_text_on_page(p):
    if not args.stdin:
        p.msg("Processing")

    notes = []

    subsecs = blib.split_text_into_subsections(p.text, p.msg)
    subsections = subsecs.subsections

    def m_und_uder(m):
        destcode, sourcecode, term_code = m.groups()
        origtext = m.group(0)
        if (
            destcode in family_data.families_by_code
            or etym_language_to_parent.get(destcode, "NONE") in family_data.families_by_code
        ):
            pass
        else:
            p.msg(
                "WARNING: Saw {{etyl|%s|%s}} {{m|und|...}} where destination is not a family, not changing"
                % (destcode, sourcecode)
            )
            return origtext
        newtext = "{{uder|%s|%s}}%s" % (sourcecode, destcode, term_code)
        notes.append(
            "replace {{etyl|...}} for destination family (+ {{m|und|...}}) with {{uder|%s|%s}}" % (sourcecode, destcode)
        )
        p.msg("Replacing <%s> with <%s> for destination family with 'und' term code" % (origtext, newtext))
        return newtext

    def replace_with_uder(m):
        etyltemp, m_langcode, vbar = m.groups()
        origtext = m.group(0)
        mm = re.search(r"^\{\{etyl\|(.*?)\|(.*?)\}\}$", etyltemp)
        if not mm:
            p.msg("WARNING: Something wrong, can't match template call %s" % etyltemp)
            return origtext
        etym_langcode, from_langcode = mm.groups()
        if etym_langcode != m_langcode:
            display_msg = False
            if (
                etym_langcode in etym_lang_data.etym_languages_by_code
                and m_langcode in etym_lang_data.etym_languages_by_code
                and etym_lang_data.etym_languages_by_code[etym_langcode]["canonicalName"]
                == etym_lang_data.etym_languages_by_code[m_langcode]["canonicalName"]
            ):
                p.msg(
                    "Saw etym lang %s in {{etyl}} and etym lang %s in {{m}}, which are aliases of each other"
                    % (etym_langcode, m_langcode)
                )
                display_msg = True
            elif m_langcode == from_langcode:
                p.msg(
                    "WARNING: Saw source language code %s as destination, assuming a mistake, using destination %s"
                    % (from_langcode, etym_langcode)
                )
            elif etym_language_to_parent.get(etym_langcode, "NONE") != m_langcode:
                p.msg(
                    "WARNING: Mismatched language codes, saw %s vs. %s in %s {{m|%s|...}}"
                    % (etym_langcode, m_langcode, etyltemp, m_langcode)
                )
                return origtext
            else:
                display_msg = True
            if display_msg:
                p.msg("Using etym language code %s in place of parent or alias %s" % (etym_langcode, m_langcode))
        newtext = "{{uder|%s|%s|" % (from_langcode, etym_langcode)
        notes.append("absorb {{etyl|...}} {{m|...}} into {{uder|%s|%s}}" % (from_langcode, etym_langcode))
        p.msg("Replacing <%s> with <%s>, absorbing {{m|..." % (origtext, newtext))
        return newtext

    def swap_etyl_uder(m):
        destcode, sourcecode = m.groups()
        origtext = m.group(0)
        newtext = "{{uder|%s|%s|-}}" % (sourcecode, destcode)
        notes.append("swap {{etyl|...}} into {{uder|%s|%s}}" % (sourcecode, destcode))
        p.msg("Replacing <%s> with <%s>, swapping langcodes" % (origtext, newtext))
        return newtext

    # Go through each section in turn, looking for Etymology sections
    for k, header in subsecs.header_list:
        if re.match("^Etymology( [0-9]+)?$", header):
            sectext = subsections[k]
            # First try for {{etyl|DESTFAMILY|SOURCE}} {{m|und|...
            sectext = blib.rsub_repeatedly(
                    r"\{\{etyl\|([A-Za-z0-9.-]+)\|([A-Za-z0-9.-]+)\}\}( +\{\{(?:m|mention)\|und\|)",
                    m_und_uder,
                    sectext,
                    0,
                    re.M,
                )
            # Then try for {{etyl|DEST|SOURCE}} {{m|SOURCE|...
            sectext = blib.rsub_repeatedly(
                    r"(\{\{etyl\|[A-Za-z0-9.-]+\|[A-Za-z0-9.-]+\}\})(?: +\{\{(?:m|mention)\|)([A-Za-z0-9.-]+)(\|)",
                    replace_with_uder,
                    sectext,
                    0,
                    re.M,
                )
            # Then do remaining {{etyl|DEST|SOURCE}} not followed by {{m|...
            sectext = blib.rsub_repeatedly(
                    r"\{\{etyl\|([A-Za-z0-9.-]+)\|([A-Za-z0-9.-]+)\}\}(?! +\{\{(?:m|mention)\|)",
                    swap_etyl_uder,
                    sectext,
                    0,
                    re.M,
                )

    return "".join(subsections), notes


if __name__ == "__main__":
    parser = blib.create_argparser("Replace {{etyl}} with {{uder}}")
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        default_refs=["Template:etyl"],
        ref_namespaces=[0],
    )
