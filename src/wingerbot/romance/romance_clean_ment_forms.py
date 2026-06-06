#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg
from wingerbot.blib import ParseException


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, args.langname, p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    saw_affix_template_with_ment = False

    def fix_up_section(secnum, secbody):
        def pagemsg(txt):
            p.msg(txt, index=p.index + ("." + secnum if secnum is not None else ""))
        nonlocal saw_affix_template_with_ment
        subsecs = blib.split_text_into_subsections(secbody, pagemsg)
        subsections = subsecs.subsections
        subsections_by_header = subsecs.subsections_by_header
        etymsec_text = " for Etymology %s" % secnum if secnum is not None else ""
        if "Noun" in subsections_by_header and "Adverb" in subsections_by_header:
            pagemsg("WARNING: Saw both noun and adverb sections%s, skipping" % etymsec_text)
            return secbody
        if "Noun" in subsections_by_header:
            id = "nominal"
            poses = ["noun", "nouns"]
            pagemsg("Inferred id=nominal%s based on existing Noun section" % etymsec_text)
        elif "Adverb" in subsections_by_header:
            id = "adverbial"
            poses = ["adverb", "adverbs"]
            pagemsg("Inferred id=adverbial%s based on existing Adverb section" % etymsec_text)
        else:
            pagemsg("WARNING: Didn't see either noun or adverb sections%s, skipping" % etymsec_text)
            return secbody

        if secnum is not None:
            subsec_index = 0
        elif "Etymology" in subsections_by_header:
            msg("subsections_by_header: " + repr(subsections_by_header["Etymology"]))
            if len(subsections_by_header["Etymology"]) > 1:
                pagemsg("WARNING: Saw multiple Etymology sections, skipping")
                return secbody
            else:
                subsec_index = subsections_by_header["Etymology"][0]
        else:
            return secbody

        parsed = blib.parse_text(subsections[subsec_index])
        for t in parsed.filter_templates():
            tn = tname(t)

            def getp(param):
                return getparam(t, param)

            if tn in ["af", "affix", "surf", "suf", "suffix", "con", "confix"]:
                is_suffix = tn in ["suf", "suffix"]
                is_confix = tn in ["con", "confix"]
                no_hyphen = is_suffix or is_confix
                numbered = blib.fetch_param_chain(t, "2")
                for affix_index, affix in enumerate(numbered):
                    if is_suffix and affix_index == 0:
                        continue
                    if is_confix and affix_index < len(numbered) - 1:
                        continue
                    if (
                        affix == "-ment"
                        or no_hyphen
                        and affix == "ment"
                        or affix.startswith("-ment<")
                        or no_hyphen
                        and affix.startswith("ment<")
                    ):
                        saw_affix_template_with_ment = True
                        id_param = "id%s" % ("" if affix_index == 0 else str(affix_index + 1))
                        existing_id = getp(id_param)
                        if existing_id:
                            if existing_id == id:
                                pagemsg(
                                    "Skipping %s with %s=%s%s already" % (str(t), id_param, existing_id, etymsec_text)
                                )
                            else:
                                pagemsg(
                                    "WARNING: Skipping %s with %s=%s%s, different from desired '%s'"
                                    % (str(t), id_param, existing_id, etymsec_text, id)
                                )
                            continue
                        existing_pos = getp("pos")
                        if existing_pos:
                            if existing_pos in poses:
                                pagemsg("Removing %s with pos=%s%s" % (str(t), existing_pos, etymsec_text))
                                rmparam(t, "pos")
                                notes.append(
                                    "remove pos=%s from {{%s|%s}}%s" % (existing_pos, tn, getp("1"), etymsec_text)
                                )
                            else:
                                pagemsg(
                                    "WARNING: Skipping %s with unexpected pos=%s%s"
                                    % (str(t), existing_id, etymsec_text)
                                )
                                continue

                    if affix == "-ment" or no_hyphen and affix == "ment":
                        new_affix = "%s<id:%s>" % (affix, id)
                        pagemsg(
                            "Replacing %s=%s with %s=%s in %s%s"
                            % (affix_index + 2, affix, affix_index + 2, new_affix, str(t), etymsec_text)
                        )
                        notes.append(
                            "replace %s=%s with %s=%s in {{%s|%s}}%s"
                            % (affix_index + 2, affix, affix_index + 2, new_affix, tn, getp("1"), etymsec_text)
                        )
                        t.add(str(affix_index + 2), new_affix)
                    elif affix.startswith("-ment<") or no_hyphen and affix.startswith("ment<"):
                        try:
                            inlinemod = blib.parse_inline_modifier(affix)
                        except ParseException as e:
                            pagemsg("WARNING: Unable to parse inline modifier spec %s: %s" % (affix, str(e)))
                            continue
                        affix_id = inlinemod.get_modifier("id")
                        if affix_id is not None:
                            if affix_id == id:
                                pagemsg("Skipping %s with <id:%s>%s already" % (str(t), affix_id, etymsec_text))
                            else:
                                pagemsg(
                                    "WARNING: Skipping %s with <id:%s>%s, different from desired '%s'"
                                    % (str(t), affix_id, etymsec_text, id)
                                )
                            continue
                        inlinemod.set_modifier("id", id)
                        new_affix = inlinemod.reconstruct_param()
                        pagemsg(
                            "Replacing %s=%s with %s=%s in %s%s"
                            % (affix_index + 2, affix, affix_index + 2, new_affix, str(t), etymsec_text)
                        )
                        notes.append(
                            "replace %s=%s with %s=%s in {{%s|%s}}%s"
                            % (affix_index + 2, affix, affix_index + 2, new_affix, tn, getp("1"), etymsec_text)
                        )
                        t.add(str(affix_index + 2), new_affix)
        subsections[subsec_index] = str(parsed)
        return "".join(subsections)

    secbody = blib.map_etym_sections(secbody, p.msg, fix_up_section)
    if not saw_affix_template_with_ment:
        p.msg(
            "WARNING: Didn't see {{af}}/{{affix}} or {{suf}}/{{suffix}} template with -ment, category might be specified some other way"
        )
    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Add <id:nominal> or <id:verbal> to {{af}} or {{affix}} etymology as appropriate for Gallo-Romance terms ending in -ment",
)
parser.add_argument(
    "--langname", help="Opional name of language whose section to fetch.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=args.langname and ["%s terms suffixed with -ment" % args.langname] or None,
)
